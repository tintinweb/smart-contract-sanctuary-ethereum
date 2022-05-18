/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract Calculate{
    string public name;
    uint public commitment;
    // uint public depositor;
    // uint public timeOfCommit;
    // uint public colleteral;
    // uint public penaltyFee;

    function getCalculation () external view returns(string memory, uint){
        return (name, commitment);
    }

    function setCalculate (string memory _name, uint _commitment) public {
        name = _name;
        commitment = _commitment;
    }
}