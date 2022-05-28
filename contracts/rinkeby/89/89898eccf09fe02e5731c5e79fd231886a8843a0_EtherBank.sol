/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EtherBank {
	// uint public etherReceived;

    struct Account {
        uint totalBalance;
        uint numPayments;
        uint lastTxTime;
    }

    mapping (address => Account) public etherBalance;
	
	function sendMoney() public payable {
		etherBalance[msg.sender].totalBalance += msg.value;
        etherBalance[msg.sender].numPayments += 1;
        etherBalance[msg.sender].lastTxTime = block.timestamp;
    }

    function timeStamp() public view returns (uint) {
        return etherBalance[msg.sender].lastTxTime;
    }

    function getOwnNumPayments() public view returns (uint) {
        return etherBalance[msg.sender].numPayments;
    }

	function getOwnBalance() public view returns(uint) {
		return etherBalance[msg.sender].totalBalance;
	}

    function getTotalBalance() public view returns(uint) {
        return address(this).balance;
    }

	function withdrawMoneyTo(address payable _to) public {
        require(msg.sender == _to, "caller is not owner");
		_to.transfer(getOwnBalance());
        etherBalance[msg.sender].totalBalance -= getOwnBalance();
	}

    function withdrawTotalMoney() public {
        require(msg.sender == 0x617F2E2fD72FD9D5503197092aC168c91465E7f2, "you do not own this contract.");
		address payable to = payable(msg.sender);
		to.transfer(address(this).balance);
        etherBalance[msg.sender].totalBalance = 0;
	}
}