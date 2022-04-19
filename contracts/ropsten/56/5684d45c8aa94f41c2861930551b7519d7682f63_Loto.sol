/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Loto {

    mapping(address => uint) public promene;
    uint8 private tajniBroj;

    constructor(){
        tajniBroj=1;
    }

    function guess (uint8 guessNumber) public {
        require(guessNumber >= 1 && guessNumber <= 10,"Broj nije u opsegu 1-10");
        require(guessNumber == tajniBroj,"Niste uneli tacan broj");


        tajniBroj=guessNumber;
        return;
    }


}