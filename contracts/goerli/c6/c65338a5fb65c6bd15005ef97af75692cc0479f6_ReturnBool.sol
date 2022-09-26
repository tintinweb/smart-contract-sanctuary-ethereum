/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// File: ReturnBool.sol



pragma solidity ^0.8.0;



contract ReturnBool {

    function returnBoolean() public pure returns(bool) {

        return 1 & 1 == 2;

    }

}