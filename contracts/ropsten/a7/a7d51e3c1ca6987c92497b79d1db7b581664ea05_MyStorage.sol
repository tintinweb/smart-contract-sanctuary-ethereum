/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

contract MyStorage{
    uint256 data;
    uint256 count;
    
    constructor(){
        data=0;
    }

    function setData(uint256 x)public{
        data= x;
        count = count+1;
    }

    function getData() public view returns(uint256){
        return data;
    }
}