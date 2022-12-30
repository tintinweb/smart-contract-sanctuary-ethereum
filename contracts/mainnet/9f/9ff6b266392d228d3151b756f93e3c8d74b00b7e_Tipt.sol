/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.13;

contract Tipt{

    mapping(address => uint256) public balances;

    function tip(address _tipped) external payable {
        require(_tipped != address(0), "The 0x0 address can't be tipped");
        balances[_tipped] += msg.value;
    }
    
    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficent tips balance");

        balances[msg.sender] -= _amount;
        (bool sent,) = msg.sender.call{value: _amount}("Sent");
        require(sent, "failed to send ETH");
    }

}