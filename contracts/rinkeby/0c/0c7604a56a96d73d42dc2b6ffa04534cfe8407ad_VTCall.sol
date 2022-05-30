/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// File: contracts/5_.VTCall.sol


pragma solidity ^0.8.10;

interface VToken { 
	function transfer(address to, uint256 value) external returns (bool success);
}

contract VTCall {
    VToken vtc;

    constructor(address addr) {
        vtc = VToken(addr);
    }

    function transferVToken(address receiver, uint amount) external returns (bool) {
        require(vtc.transfer(receiver, amount));
        return true;
    }
}