let CustomToken = artifacts.require('CustomToken');

const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

contract('CustomToken', (accounts) => {
  it ('deploys the smart contract', async () => {
    let tokenInstance = await CustomToken.deployed();
    assert.ok(tokenInstance.address, 'the smart contract has an address');
  });

  it ('initializes the contract', async () => {
    let tokenInstance = await CustomToken.deployed();

    // We initialize the token
    let sender = accounts[0];
    let minTotalSupply = 10 * Math.pow(10, 18);
    let maxTotalSupply = 100 * Math.pow(10, 18);
    let stakeMinAge = 1;  // 1 second
    let stakeMaxAge = 60; // 60 seconds
    let stakePrecision = 10;
    tokenInstance.initialize(sender, minTotalSupply.toString(), maxTotalSupply.toString(), stakeMinAge, stakeMaxAge, stakePrecision);

    let totalSupply = await tokenInstance.totalSupply();
    assert.equal(totalSupply, minTotalSupply, 'has a total supply equal to initialSupply');

  });

  it ('transfer to another account', async () => {
    let tokenInstance = await CustomToken.deployed();
    let balanceAmmount = Math.pow(10, 18).toString();

    // We transfer 10 tokens to account[1]
    await tokenInstance.transfer(accounts[1], balanceAmmount, { from: accounts[0] });

    let balance = await tokenInstance.balanceOf(accounts[1]);
    assert.equal(balance, balanceAmmount, 'the second account has a balance of 10**18');
  });

  it ('stake the balance', async () => {
    let tokenInstance = await CustomToken.deployed();
    let balanceAmmount = Math.pow(10, 18).toString();

    // account[1] stakes his balance
    await tokenInstance.stakeAll({ from: accounts[1] });

    let balance = await tokenInstance.balanceOf(accounts[1]);
    let staked = await tokenInstance.stakeOf(accounts[1]);
    assert.equal(balance, 0, 'the second account has a balance of 0');
    assert.equal(staked, balanceAmmount, 'the second account has a stake of 10**18');
  });

  it ('unstake the balance', async () => {
    let tokenInstance = await CustomToken.deployed();
    let balanceAmmount = Math.pow(10, 18).toString();

    // account[1] unstake
    await tokenInstance.unstakeAll({ from: accounts[1] });

    let balance = await tokenInstance.balanceOf(accounts[1]);
    let staked = await tokenInstance.stakeOf(accounts[1]);
    assert.equal(balance, balanceAmmount, 'the second account has a balance of 10**18');
    assert.equal(staked, 0, 'the second account has a stake of 0');
  });

  it ('reward', async () => {
    let tokenInstance = await CustomToken.deployed();
    let balanceAmmount = Math.pow(10, 18).toString();

    // account[1] stakes his balance
    await tokenInstance.stakeAll({ from: accounts[1] });
    // We wait 5 seconds
    await delay(5000);
    // account[1] reward
    await tokenInstance.reward({ from: accounts[1] });

    let balance = await tokenInstance.balanceOf(accounts[1]);
    console.log(`Balance ${balance.toString()}`);
    let staked = await tokenInstance.stakeOf(accounts[1]);
    assert.notEqual(balance, 0, 'the second account has a balance differet of 0 (the reward)');
    assert.equal(staked, balanceAmmount, 'the second account has a stake of 10**18');
  });
})
