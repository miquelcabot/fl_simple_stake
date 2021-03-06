pragma solidity ^0.5.16;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

/**
 * @dev Extension of {ERC20} that adds staking mechanism.
 */
contract CustomToken is ERC20, Ownable {
    using SafeMath for uint64;

    uint256 internal _minTotalSupply;
    uint256 internal _maxTotalSupply;
    uint256 internal _stakeStartTime;
    uint256 internal _stakeMinAge;
    uint256 internal _stakeMaxAge;
    uint256 internal _maxInterestRate;
    uint256 internal _stakeMinAmount;
    uint256 internal _stakePrecision;

    struct stakeStruct {
        uint256 amount;
        uint256 time;
    }

    mapping(address => stakeStruct[]) internal _stakes;

    function initialize(
        address sender, uint256 minTotalSupply, uint256 maxTotalSupply, uint64 stakeMinAge, uint64 stakeMaxAge,
        uint8 stakePrecision
    ) public initializer
    {
        Ownable.initialize(sender);

        _minTotalSupply = minTotalSupply;
        _maxTotalSupply = maxTotalSupply;
        _mint(sender, minTotalSupply);
        _stakePrecision = uint256(stakePrecision);

        _stakeStartTime = now;
        _stakeMinAge = uint256(stakeMinAge);
        _stakeMaxAge = uint256(stakeMaxAge);

        _maxInterestRate = uint256(10**17); // 10% annual interest
        _stakeMinAmount = uint256(10**18);  // min stake of 1 token
    }

    function stakeOf(address account) public view returns (uint256) {
        if (_stakes[account].length <= 0) return 0;
        uint256 stake = 0;

        for (uint i = 0; i < _stakes[account].length; i++) {
            stake = stake.add(uint256(_stakes[account][i].amount));
        }
        return stake;
    }

    function stakeAll() public returns (bool) {
        _stake(_msgSender(), balanceOf(_msgSender()));
        return true;
    }

    function unstakeAll() public returns (bool) {
        _unstake(_msgSender());
        return true;
    }

    function reward() public returns (bool) {
        _reward(_msgSender());
        return true;
    }

    // This method should allow adding on to user's stake.
    // Any required constrains and checks should be coded as well.
    function _stake(address sender, uint256 amount) internal {
        require(sender != address(0), "Stake from the zero address");
        require(balanceOf(sender) >= amount, "Sufficient balance for the stake");
        require(amount >= _stakeMinAmount, "Minimum stake of 1 token");

        // We add the stake
        stakeStruct memory stake = stakeStruct(amount, now);
        _stakes[sender].push(stake);

        // Decrease the amount staked to the balance
        _decreaseBalance(sender, amount);
    }

    // This method should allow withdrawing staked funds
    // Any required constrains and checks should be coded as well.
    function _unstake(address sender) internal {
        require(sender != address(0), "Unstake from the zero address");
        
        // Increase all the amount staked to the balance
        _increaseBalance(sender, stakeOf(sender));
        // Deletes all stakes
        delete _stakes[sender];
    }

    // This method should allow withdrawing cumulated reward for all staked funds of the user's.
    // Any required constrains and checks should be coded as well.
    // Important! Withdrawing reward should not decrease the stake, stake should be rolled over for the future automatically.
    function _reward(address _address) internal {
      require(_address != address(0), "Reward from the zero address");

      // We increase the balance with the cumulated reward for all staked funds
      _increaseBalance(_address, _getProofOfStakeReward(_address));
      // We roll over the stake for the future
      for (uint i = 0; i < _stakes[_address].length; i++) {
          _stakes[_address][i].time = now;
      }
    }

    function _getProofOfStakeReward(address _address) internal view returns (uint256) {
        require((now >= _stakeStartTime) && (_stakeStartTime > 0));

        uint256 _now = now;
        uint256 _coinAge = _getCoinAge(_address, _now);
        if (_coinAge <= 0) return 0;

        uint256 interest = _getAnnualInterest();
        uint256 rewarded = (_coinAge * interest).div(365 * 10**_stakePrecision);

        return rewarded;
    }

    function _getCoinAge(address _address, uint256 _now) internal view returns (uint256) {
        if (_stakes[_address].length <= 0) return 0;
        uint256 _coinAge = 0;

        for (uint i = 0; i < _stakes[_address].length; i++) {
            if (_now < uint256(_stakes[_address][i].time).add(_stakeMinAge)) continue;

            uint256 nCoinSeconds = _now.sub(uint256(_stakes[_address][i].time));
            if (nCoinSeconds > _stakeMaxAge) nCoinSeconds = _stakeMaxAge;

            _coinAge = _coinAge.add(uint256(_stakes[_address][i].amount) * nCoinSeconds.div(1 days));
            // To test waiting only for n seconds:
            // _coinAge = _coinAge.add(uint256(_stakes[_address][i].amount) * nCoinSeconds);
        }

        return _coinAge;
    }

    function _getAnnualInterest() internal view returns(uint256) {
        return _maxInterestRate;
    }

    function _increaseBalance(address account, uint256 amount) internal {
        require(account != address(0), "Balance increase from the zero address");
        // _balances[account] = _balances[account].add(amount);
        _mint(account, amount);
    }

    function _decreaseBalance(address account, uint256 amount) internal {
        require(account != address(0), "Balance decrease from the zero address");
         // _balances[account] = _balances[account].sub(amount, "Balance decrease amount exceeds balance");
         _burn(account, amount);
    }
}