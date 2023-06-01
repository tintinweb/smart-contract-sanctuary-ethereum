/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
// EtherBets Contract 1 v10

pragma solidity ^0.8.20;

contract EtherBetsCon2 {
	address public owner;
	uint256 public o1;
	uint256 public o2;
	uint256 public min_bet;
	bool public paused;
	bool public paidOut;
	address[] public betsaddr1;
	address[] public betsaddr2;
	uint256[] public bets1;
	uint256[] public bets2;

	constructor() {
		owner = msg.sender;
		paused = true;
		min_bet = 1 ether / 40;
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "Only for owner");
		_;
	}

	function reset() public onlyOwner {
		delete betsaddr1;
		delete betsaddr2;
		delete bets1;
		delete bets2;
		o1 = 0;
		o2 = 0;
		paused = false;
		paidOut = false;
	}

	function setPaused(bool _paused) external onlyOwner {
		paused = _paused;
	}

	function setMinBet(uint256 _min_bet) external onlyOwner {
		min_bet = _min_bet;
	}

	modifier whenNotPaused() {
		require(!paused, "Bets paused");
		_;
	}

	function bet(uint256 outcome) payable external whenNotPaused {
		require(msg.value >= min_bet, "Too low bet");
		require(outcome == 1 || outcome == 2, "Wrong outcome");

		if (outcome == 1) {
			o1 += msg.value;
			betsaddr1.push( msg.sender );
			bets1.push( msg.value );
		} else {
			o2 += msg.value;
			betsaddr2.push( msg.sender );
			bets2.push( msg.value );
		}
	}

	function setOutcome(uint256 outcome) external onlyOwner {
		require(outcome == 1 || outcome == 2 || outcome == 3, "Wrong outcome"); // outcome==3 is draw
		paused = true;

		if (outcome == 1) {
			for (uint256 i = 0; i < bets1.length; i++) {
				payable( betsaddr1[i] ).transfer( bets1[i] + (o2 * 9 * bets1[i]) / (10 * o1) );
			}
		} else if (outcome == 2) {
			for (uint256 i = 0; i < bets2.length; i++) {
				payable( betsaddr2[i] ).transfer( bets2[i] + (o1 * 9 * bets2[i]) / (10 * o2) );
			}
		}
		paidOut = true;
	}

	function withdraw(uint256 _amount) external onlyOwner {
		payable(msg.sender).transfer( _amount );
	}

	function betsCount(uint256 outcome) view external onlyOwner returns (uint256) {
		if (outcome == 1) {
			return bets1.length;
		} else {
			return bets2.length;
		}
	}
}