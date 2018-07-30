pragma solidity ^0.4.24;


contract Lottery{ 
	mapping (address => LotteryStruct) allLotteries;

	struct LotteryStruct {
		uint256 pool;
		address[] entrances;
		address winner;
	}

	//CONSTRUCTOR
	//run lottery upon creation 
	constructor () public {
	}


	//Run lottery
	function runLottery(address _advertiser, uint256 _pool, address[] _entrances, uint _nonce) public {
		//set new lottey struct
		allLotteries[_advertiser] = LotteryStruct(_pool, _entrances, 0x0);
		//random number
		//uint luckyNumber = uint(keccak256(abi.encodePacked(_nonce)))%(allLotteries[_advertiser].entrances.length - 1);
		uint luckyNumber = getRandomNumber(_advertiser, _nonce);
		//set winner
		allLotteries[_advertiser].winner = allLotteries[_advertiser].entrances[luckyNumber];

	}

	function getRandomNumber(address _advertiser, _nonce) public returns(uint) {
		uint ceiling = allLotteries[_advertiser].entrances.length;
		uint rand = uint(block.blockhash(block.number)) * _nonce;
		uint luckyNumber = (block.timestamp + rand) % ceiling;
		return luckyNumber;

	}


	//getterfunctions

	function getLotteryWinner(address _advertiser) public view returns(address) {
		return allLotteries[_advertiser].winner;
	}
	function getLotteryPool(address _advertiser) public view returns(uint256) {
		return allLotteries[_advertiser].pool;
	}



}
