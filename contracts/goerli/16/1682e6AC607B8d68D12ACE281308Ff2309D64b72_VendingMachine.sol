/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract VendingMachine {
    address payable public owner;
    uint256 public numSodas;
    uint256 public votesForAnarchy;

    mapping(address => uint256) public sodasOwned;

    constructor(uint256 _numSodas) {
        owner = payable(msg.sender);
        numSodas = _numSodas;
    }

    function purchase() public payable {
        require(msg.value >= 1000 wei, "Minimum deposit is 1000 wei!");
        require(numSodas > 0, "No more sodas available!");
        numSodas--;
        sodasOwned[msg.sender] += 1;
    }

    function withdrawEarnings() public {
        require(msg.sender == owner, "Only the owner can withdraw!");
        owner.transfer(address(this).balance);
    }

    function changeOwner(address payable _newOwner) public {
        require(msg.sender == owner, "Only current owner can change owner!");
        owner = _newOwner;
    }

    function destroyVendingMachine() public {
        require(msg.sender == owner, "Only the owner can destroy!");
        selfdestruct(payable(msg.sender));
    }

    function anarchy() public payable {
        require(msg.value == 1000 wei);
        votesForAnarchy++;
        if (votesForAnarchy >= 10) {
            owner = payable(msg.sender);
            votesForAnarchy = 0;
        }
    }

    function pureExample(uint _x, uint _y) external pure returns (uint) {
        return _x + _y;
    }
}