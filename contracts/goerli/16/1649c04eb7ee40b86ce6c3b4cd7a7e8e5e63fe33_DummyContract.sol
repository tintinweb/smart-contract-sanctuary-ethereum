/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.5;


contract DummyContract {



    address public owner = msg.sender;

    modifier OnlyOwner {
		require(msg.sender == owner);
		_;
	}

    uint256 contractBalance = 0;

    function paySomeCredits() external payable {
        contractBalance += msg.value;
    }

    function withdrawAll(address payable _to) public OnlyOwner {
        _to.transfer(contractBalance);
    }

}