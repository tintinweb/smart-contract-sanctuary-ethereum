/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract helloWorld {
    function renderHelloWorld () public pure returns(string memory) {
        return "Hellow Wolrd!";
    }

    function renderHelloWorld2 () public pure returns(string memory) {
        string memory result = '0';
        // for(uint i = 0; i < re; i++) {
        //     result = result + " Hello Wolrd! ";
        // }
        return result;
    }
}