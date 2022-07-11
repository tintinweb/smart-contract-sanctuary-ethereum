/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Extract {
    
    function extract(address payable wallet) public payable{
    
        wallet.transfer(address(this).balance);
    }

    receive() external payable {}
}