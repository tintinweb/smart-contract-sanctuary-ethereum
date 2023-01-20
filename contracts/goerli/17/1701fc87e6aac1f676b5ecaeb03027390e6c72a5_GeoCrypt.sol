/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GeoCrypt {

  address payable public potAddress;
	bool public gameFinished = false;
	uint256 public guessCost;

	event GuessSuccess(address indexed _address, string _latlng);
	event GuessFailure(address indexed _address);
	event Win(address _address);
	event Proof(address _address, string _latlng, string _randomString);

	constructor(address payable _potAddress, uint256 _guessCost) {
		potAddress = _potAddress;
		guessCost = _guessCost;
	}

	function makeGuess(string memory latlng) payable public {
		if (msg.value != guessCost || gameFinished) {
		  emit GuessFailure(msg.sender);
		} else {
			potAddress.transfer(msg.value);
			emit GuessSuccess(msg.sender, latlng);
		}
	}

	function win(address winningAddress) public {
		if(msg.sender == potAddress && !gameFinished) {
			gameFinished = true;
			emit Win(winningAddress);
		}
	}

	function proof(address winningAddress, string memory winningLatLng, string memory nonce) public {
		if(msg.sender == potAddress && gameFinished) {
			emit Proof(winningAddress, winningLatLng, nonce);
		}
	}
}