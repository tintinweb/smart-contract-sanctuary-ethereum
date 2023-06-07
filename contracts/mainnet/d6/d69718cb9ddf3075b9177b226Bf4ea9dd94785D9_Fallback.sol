/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Fallback {

address _owner;

function owner() public returns(address)  { 
    return _owner;
}

function transferOwnership(address varg0) public { 
    ownerCheck();
    _owner = varg0;
}

function ownerCheck() private { 
    require(_owner == msg.sender);
    return ;
}

constructor(){
    _owner = address(tx.origin);
    }


 fallback() external payable {
     address v1 = owner();
    require(address(tx.origin) == address(v1));
}

}