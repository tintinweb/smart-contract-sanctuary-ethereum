/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract Owner{
    address public owner;
    constructor(){
        owner=msg.sender;
    }
    event NewOwner(
        address newOwner
    );
    function setOwner(address _owner) public {
           require(msg.sender==owner);
           require(_owner!=owner);
           owner=_owner;
           emit NewOwner(_owner);
    }
}