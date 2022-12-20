/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

contract DummyContract {
    
    address public owner = msg.sender;

    modifier OnlyOwner {
		require(msg.sender == owner);
		_;
	}

    uint256 public contractBalance = 0;

    uint256 public value = 0;

    function setValue(uint256 _value) public payable {
        value = _value;
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    event GotCredits(uint256 amount);

    function paySomeCredits() public payable returns (bool) {
        contractBalance += msg.value;
        emit GotCredits(msg.value);
        return true;
    }

    function withdrawAll(address payable _to) public OnlyOwner {
        _to.transfer(contractBalance);
    }

}