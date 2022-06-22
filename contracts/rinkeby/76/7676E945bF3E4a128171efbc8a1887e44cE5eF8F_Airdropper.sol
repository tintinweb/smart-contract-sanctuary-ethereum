/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Airdropper {
    bytes public data;

    function batch(address tokenAddr, address[] calldata toAddr, uint256 [] calldata value) public returns (bool){
        
        require(toAddr.length == value.length && toAddr.length >= 1);
        
        for(uint256 i = 0 ; i < toAddr.length; i++){
    
            (bool success, bytes memory _data) = tokenAddr.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)",  msg.sender, toAddr[i], value[i])
            );
            require(success, "call falled");
            data = _data;
        }
        return true;
    }
}