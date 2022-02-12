/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract multiCall {
    function call(uint256 times) public {
        for(uint i=0;i<times;++i){
            new claimer();
        }
    }
}
contract claimer{
    constructor(){
        bool success;
        (success,) = 0x1c7E83f8C581a967940DBfa7984744646AE46b29.call(abi.encodeWithSignature("claim()"));
        (success,) = 0x1c7E83f8C581a967940DBfa7984744646AE46b29.call(abi.encodeWithSignature("transfer(address,uint256)",0x1f2479ee1b4aFE789e19D257D2D50810ac90fa59, 151200000000000000000000000));
        selfdestruct(payable(address(msg.sender)));
    }
}