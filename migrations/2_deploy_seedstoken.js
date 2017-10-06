var SeedsToken = artifacts.require("./SeedsToken.sol");

module.exports = function(deployer) {
  deployer.deploy(SeedsToken);
};
