/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Create2 {
    event Depoly(address pair);
    address[] public  AllPairs;
    function createPair() public returns(address){
        bytes32 salt = keccak256(abi.encode(msg.sender));
        Pair p = new Pair{salt:salt }();
        p.init("hello");
        AllPairs.push(address(p));
        emit Depoly(address(p));
        return address(p);
    }
}
contract Pair{
    string public name;
    function init(string calldata _name) public  {
        name = _name;
    }
    function getName()public view returns(string memory) {
        return name;
    }
}