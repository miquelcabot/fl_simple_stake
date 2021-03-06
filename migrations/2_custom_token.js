const CustomToken = artifacts.require("CustomToken");

module.exports = function (deployer) {
  deployer.deploy(CustomToken);
};
