/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

pragma solidity ^0.8.14;
// SPDX-License-Identifier: MIT

contract FeeCollector{
    address public party_A;
    string public contractString;


    constructor() {
        party_A = msg.sender;
        contractString = "Empty Contract";
    }

    function setContract(string memory contractStringInput) public {
        require(msg.sender == party_A);
        contractString = contractStringInput;
    }

    function getContract() public view returns (string memory) {
        return contractString;
    }

    function setParty_A(address party_A_Input) public {
        require(msg.sender == party_A);
        party_A = party_A_Input;
    }

    function getParty_A() public view returns (address) {
        return party_A;
    }
}