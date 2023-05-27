/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;	
	contract contrat {
	    uint private vaaar;
	
	    function getVar() public view returns (uint) {
	        return vaaar;
	    }
	
	    function setVar(uint Nval) public {
	        vaaar= Nval;
	    }
	}