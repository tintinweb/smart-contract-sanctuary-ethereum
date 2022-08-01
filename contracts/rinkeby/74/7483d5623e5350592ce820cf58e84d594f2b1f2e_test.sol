/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

/// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract test{
    uint256 fee = 100000000;
    address taker = 0xe3f7CAD5c871b1aF011b11776BbCc12B20FB2A73;
    constructor() payable{
        
    }
    function pay() payable external{
        payable(taker).transfer(fee);
    }
    


/*
    function transfer(address recipient, uint256 amount)
        public
        //override
        returns (bool)
    {
        //_transfer(_msgSender(), recipient, amount);
        return true;
    }
    */

}