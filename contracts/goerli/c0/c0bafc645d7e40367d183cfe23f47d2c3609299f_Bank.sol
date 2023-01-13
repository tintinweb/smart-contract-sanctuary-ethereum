/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint256) public balanceOf;
    uint public someValue;

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 depositedAmount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(depositedAmount);
    }

    function getBalance(address _address) public view returns(uint) {
        return(balanceOf[_address]);
    }

    function setSomeValue(uint _someValue) public {
        someValue = _someValue;
    }

    receive () external payable {
        deposit();
    }
}