var DAO = artifacts.require("./DAO.sol");
var Lottery = artifacts.require("./Lottery.sol");
var Token = artifacts.require("./Token.sol");


//artifacts = contract abstraction specific to truffle
//will give an DAO artificat that represents the smart contract
//truffle will expose this so that we can interact with it

module.exports = function(deployer) {
  deployer.deploy([ 
    Lottery,
    [Token, 1000]]).then(function() {
      return deployer.deploy(DAO,Lottery.address, Token.address);
    });
};


/**
module.exports = function(deployer) {
  deployer.deploy([
  	Lottery,
  	[Token, 100, 'Kiwi', 0, 'KW']
  	]).then(function(){
  		return deployer.deploy(DAO, Lottery.address, Token.address);
  	});
};
*/


/**
module.exports = function(deployer) {
  deployer.deploy(DAO);
};
*/