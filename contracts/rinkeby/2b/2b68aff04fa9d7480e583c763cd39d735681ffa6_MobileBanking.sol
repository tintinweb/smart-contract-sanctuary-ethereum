/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.7.8;

contract MobileBanking {
    event SendEvent(address _msgSender, uint256 _currentValue);
    event MyCurrentValue(address _msgSender, uint256 _value);
    event CurrentValueOfSomeone(address _msgSender, address _to, uint256 _value);

    function sendEther(address payable _to) public payable {
        require(msg.sender.balance>=msg.value, "Your balance is not enough");
        _to.transfer(msg.value);
        emit SendEvent(msg.sender, msg.sender.balance);
    }

    function contractAddress() public view returns (address) {
        return address(this);
    }
}