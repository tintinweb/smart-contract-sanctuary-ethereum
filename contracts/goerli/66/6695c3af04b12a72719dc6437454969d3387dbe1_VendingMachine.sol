/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract VendingMachine {
    uint public numSodas;
    address public owner;

    constructor(uint _numSodas) {
        numSodas = _numSodas;
        owner = msg.sender;
    }

    function purchaseSoda() public payable {
        require(msg.value > 1000 wei);
        numSodas--;
    }

    function withdrawProfits() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    function changeOwner(address _newOwner) public {
        require(msg.sender == owner);
        owner = _newOwner;
    }
}