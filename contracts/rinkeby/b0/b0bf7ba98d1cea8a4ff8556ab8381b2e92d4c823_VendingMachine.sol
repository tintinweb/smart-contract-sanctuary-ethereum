/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract VendingMachine {
    uint public numSodas; // default to 0, will hold _numSodas (passed in the constructor)
    address payable public owner; // holds whoever deployed this contract
    address public engineer; // is assigned by addEngineer();
    uint public revolutionRequests;

    mapping(address => uint) public sodasOwned;

    constructor(uint _numSodas, address payable _owner) {
        numSodas = _numSodas;
        owner = _owner;
    }

    function deposit() external payable {}

    function purchase() payable public {
        require(msg.value >= 200, "Must send more than 200 wei!");
        require(numSodas > 0, "Sodas must be non-zero!");
        numSodas-=1;
        sodasOwned[msg.sender] = sodasOwned[msg.sender]+1;
    }

    function withdraw() external payable {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function refillSodas(uint _toRefill) public {
        require(msg.sender == owner || msg.sender == engineer);
        numSodas += _toRefill; //changes state
    }

    function addEngineer(address _engineer) public {
        require(msg.sender == owner);
        engineer = _engineer;
    }

    function revolution() external {
        revolutionRequests++;
        if(revolutionRequests > 5) {
            owner = payable(msg.sender);
            revolutionRequests = 0;
        } 
    }

    function changeOwner(address payable _newOwner) public payable {
        require(msg.sender == owner);
        owner = _newOwner;
    }
}