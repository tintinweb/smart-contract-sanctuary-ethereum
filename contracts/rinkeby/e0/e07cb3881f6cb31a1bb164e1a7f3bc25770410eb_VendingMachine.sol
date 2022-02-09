/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract VendingMachine {
    uint public numSodas; // default 0
    address payable public owner; // owner == contract deployer
    address public engineer; // assigned by addEngineer()
    uint public revolutionRequests;

    mapping(address => uint) public sodasOwned;
    mapping(address => bool) public hasVoted;

    constructor(uint _numSodas, address payable _owner) {
        numSodas = _numSodas;
        owner = _owner; // set owner to whoever called this tx
    }

    function deposit() external payable {}

    function purchase() public payable {
        require(msg.value > 200, "Must send more than 200 wei!"); // if you didn't send > 1 ether, revert tx
        require(numSodas > 0, "Sodas must be non-zero!");
        numSodas -= 1;
        sodasOwned[msg.sender] = sodasOwned[msg.sender] + 1;
        
        //payable(address(this)).transfer(msg.value); // address(this) == smart contract; transfer value in the message to the VendingMachine address
    }

    function withdraw() external payable {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function refillSodas(uint _toRefill) public {
        require(msg.sender == owner || msg.sender == engineer);
        numSodas += _toRefill;
    }

    function addEngineer(address _engineer) public  {
        require(msg.sender == owner);
        engineer = _engineer;
    }

    function changeOwner(address payable _newOwner) public payable {
        require(msg.sender == owner);
        owner = _newOwner;
    }

    function revolution() external {
        require(sodasOwned[msg.sender] > 0); // require soda ownership
        require(hasVoted[msg.sender] == false);
        hasVoted[msg.sender] = true;
        revolutionRequests++;
        if(revolutionRequests > 5) {
            owner = payable(msg.sender);
            revolutionRequests = 0;
        }
    }
}