/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;



contract Sentences {

    

    struct Phrases {
        string  p;
        uint    n;
    }
    mapping(uint => Phrases) public Phrase;

    uint public total_Sentences;



    function Phrasing(string memory _input) public {
        bytes memory inputB = bytes(_input);
        total_Sentences++;
        Phrases storage phrase = Phrase[total_Sentences];
        phrase.n = total_Sentences;

        for(uint i=0; i<=inputB.length-1; i++) {
            string memory word;

            while (inputB[i]!=bytes1(" ")) {
                word = string.concat(word, string(abi.encodePacked(inputB[i])));
            }

            phrase.p = word;
        }
    }



}