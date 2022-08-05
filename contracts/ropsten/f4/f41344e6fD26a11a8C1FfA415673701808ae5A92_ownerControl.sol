/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <0.9.0;
contract ownerControl{
    address internal owner;
    constructor(){
        msg.sender==owner;
    }
    modifier onlyOwner{
        require(msg.sender==owner,"not the owner");
        _;
    }
     
    string test;
    function setTest (string memory _test) public onlyOwner {

        test = _test;
    }
    }