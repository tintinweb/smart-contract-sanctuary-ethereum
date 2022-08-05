/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract VendingMachineNYU {
    uint public numSodas; //amt of sodas in machine
    address public owner;

    mapping(address => uint) public numSodasPerAddress;

    constructor(uint _numSodas, address _owner) {
        numSodas = _numSodas;
        owner = _owner;
    }

    function purchaseSoda() public payable {
        require(msg.value > 1000 wei);
        require(numSodas > 0, "There are no sodas left!");
        numSodas--;
        numSodasPerAddress[msg.sender]++;
    }

    function changeOwner(address _newOwner) public {
        require(msg.sender == owner, "You must be the owner to call this!");
        owner = _newOwner;
    }
    
    function refillSodas(uint _numSodas) public {
        require(msg.sender == owner);
        numSodas += _numSodas;
    }

    function withdrawProfits() public {
        require(msg.sender == owner, "Only owner can get money!");
        payable(owner).transfer(address(this).balance);
    }

    function destroy() public {
        require(msg.sender == owner, "Only owner can destroy this vm!");
        selfdestruct(payable(owner));
    }
}