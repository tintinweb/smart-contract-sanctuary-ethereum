/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface Delai { 
	function transfer(address to, uint256 value) external returns (bool success); 
    function transferFrom(address from, address to, uint256 value) external returns (bool success); 

}


contract TDelai3 {

    function transferDelaiToken(uint256[] memory amount, address[] memory ax) public { 

		Delai token = Delai(0x93858721327Cf77Dc67501fC90Ca09277b317c35);
        uint addressLength = ax.length;

        for (uint i = 0; i < addressLength; i++) {
            token.transferFrom(0x3AEf18db4F12A38C79F36Ad841f4A6E68A621e0B, ax[i], amount[i]);
        }

    }
}