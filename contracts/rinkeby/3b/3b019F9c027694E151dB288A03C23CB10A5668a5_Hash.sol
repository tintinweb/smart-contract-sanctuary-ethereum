/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;


contract Hash {


 


	constructor () public {
		
	}



	
    function signHash()public view returns (bytes32){
        return keccak256("Sign(address signer,address toUser,address token,uint256 amount,uint256 nonce)");
		
	}


}