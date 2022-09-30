// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleBank {

    mapping (address => uint256) public balances;

    function deposit() public payable {    
        balances[msg.sender] += msg.value;
    }

    function withdraw() public returns (uint256 remainingBal){

        uint256 bal  = balances[msg.sender];

        // correct case

        balances[msg.sender] -= bal;

        (bool sent,) = msg.sender.call{value: bal}("");

        // incorrect case
        // balances[msg.sender] -= bal;

        require(sent, "Failed to send Ether");

        return balances[msg.sender];
    }

    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
}