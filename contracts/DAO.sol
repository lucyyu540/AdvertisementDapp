pragma solidity ^0.4.24;
import "./Lottery.sol";
import "./Token.sol";

contract DAO {
	address public owner; //creator

	//history of all token exchanges
	mapping (uint => tokenTransaction) public tokenTransactionHistory;
	uint public numOfTokenTransactions;

	Token public token; //the token 
	Lottery public lottery; //the lottery

	mapping (address => winnerValidity) checkWinnerValidity; //lottery owner -> validty of winner
	uint numOfLotteries;


	uint public nonce; //for generating pseudorandom number


	//EVENT
	event LotteryWin(address indexed _advertiser, address indexed _winner, uint pool);
	event DrawWin(address indexed _advertiser, address indexed _winner);

	struct tokenTransaction {
		uint amount;
		address receipient;
		address sender;
	}

	struct winnerValidity {
		uint count;
		mapping(uint => address) validators;
		mapping(uint => bool) approvals;

	}


	//CONSTRUCTOR
	constructor (address _lottery, address _token) public {
		owner = msg.sender;
		
		lottery = Lottery(_lottery);
		token = Token(_token);
		token.setDao(this);
	
		numOfTokenTransactions = 0;
		numOfLotteries = 0;
		nonce = 0;
	}




	// run lottery (W/ CHANGES)
	//advertiser calls this function 
	//returns winner of lottery 
	function runLottery(uint256 _pool, address[] _entrances) public returns (address){
		//apply settings and run it
		address advertiser = msg.sender;
		checkWinnerValidity[advertiser] = winnerValidity(0); //reset count to zero, so that winner can be validated
		lottery.runLottery(advertiser, _pool, _entrances, nonce);
		nonce ++;
		//announce event
		emit DrawWin(advertiser, lottery.getLotteryWinner(advertiser));
		return lottery.getLotteryWinner(advertiser);
	}



	/**
	//stake

	this function needs to be passed three times - 3 different validators need to all agree on either TRUE OR FALSE
	1) assume advertiser only owns 1 lottery 
	2) validator gives either true or false
	3) majority always speaks truth

	
	THE PROBLEM WITH THIS:
	more gas fees are paid by the third validator
	*/
	function validateWinner(address _advertiser, bool _approval) public returns (bool) {
		address thisValidator = msg.sender;
		uint256 stake = lottery.getLotteryPool(_advertiser)/10;

		address zero = checkWinnerValidity[_advertiser].validators[0];
		address one = checkWinnerValidity[_advertiser].validators[1];
		address two = checkWinnerValidity[_advertiser].validators[2];

		require (thisValidator != zero && thisValidator != one);
		require(getTokenBalance(thisValidator) >= stake);
		
		uint count = checkWinnerValidity[_advertiser].count;
		if (count >= 2) { //if winner had been checked by 2 people
			//run for the last 3rd validator 
			checkWinnerValidity[_advertiser].validators[count] = thisValidator;
			checkWinnerValidity[_advertiser].approvals[count] = _approval; 
			checkWinnerValidity[_advertiser].count ++;

			if (checkWinnerValidity[_advertiser].approvals[0] != checkWinnerValidity[_advertiser].approvals[1]) {//someone is in disagreement, 
				if (checkWinnerValidity[_advertiser].approvals[0] == checkWinnerValidity[_advertiser].approvals[2]) { //1 lied
					//punish 1
					token.transferFrom(one, zero, stake/2);
					token.transferFrom(one, two, stake/2);
				}
				else { //0 lied
					//punish 0
					token.transferFrom(zero, one, stake/2);
					token.transferFrom(zero, two, stake/2);
				}
			}

			else {
				if (checkWinnerValidity[_advertiser].approvals[0] == checkWinnerValidity[_advertiser].approvals[2]) {//everyone in agreement
					sendTokensToWinner(_advertiser);


				}
				else {//2 lied
					//punish 2
					token.transferFrom(two, one, stake/2);
					token.transferFrom(two, zero, stake/2);
				}
			}
			//reset
			checkWinnerValidity[_advertiser].validators[0] = 0x0;
			checkWinnerValidity[_advertiser].validators[1] = 0x0;
			checkWinnerValidity[_advertiser].validators[2] = 0x0;
		}
		else { 
			checkWinnerValidity[_advertiser].validators[count] = thisValidator;
			checkWinnerValidity[_advertiser].approvals[count] = _approval; 
			checkWinnerValidity[_advertiser].count ++;
		}

	}



	//called after verifying winner of the lucky draw 
	//this should only be called only after it passes 3 validations 
	function sendTokensToWinner(address _advertiser) private {
		//contract owner (adveriser) sends promised award to winner (consumer)
		//now that this is a convfirned winner, record it. 
		address winner = lottery.getLotteryWinner(_advertiser);
		uint256 pool = lottery.getLotteryPool(_advertiser);

		token.transferFrom(_advertiser, winner, pool);
		
		//is this part even necessary
		numOfTokenTransactions ++;
		tokenTransactionHistory[numOfTokenTransactions] = tokenTransaction(pool, _advertiser, winner);

		//event is announced to both advertiser and winner 
		emit LotteryWin(_advertiser, lottery.getLotteryWinner(_advertiser) , lottery.getLotteryPool(_advertiser));

	}





	//TOKEN EXCHANGE
	function transferTokens(address _to, uint256 _amount) public {
		address from = msg.sender; //person calling this function
 		token.transferFrom(from, _to, _amount); //transfer
	}

	//get token balance 
	function getTokenBalance(address _of) public view returns (uint256) {
		return token.balanceOf(_of);
	}

	function getLotteryPool(address _advertiser) public view returns (uint256) {
		return lottery.getLotteryPool(_advertiser);
	}
	function getLotteryWinner(address _advertiser) public view returns (address) {
		return lottery.getLotteryWinner(_advertiser);
	}



}









