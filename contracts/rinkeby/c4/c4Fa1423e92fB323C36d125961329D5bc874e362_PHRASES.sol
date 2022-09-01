/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract WORDS {
    


    function isGranted(string memory _input) public pure returns(bool) {
        bytes memory inputB = bytes(_input);
        bool granted        = false;

        for(uint i=0; i<=inputB.length-1; i++) {

            if(
                inputB[i]==bytes1("A") ||
                inputB[i]==bytes1("B") ||
                inputB[i]==bytes1("C") ||
                inputB[i]==bytes1("D") ||
                inputB[i]==bytes1("E") ||
                inputB[i]==bytes1("F") ||
                inputB[i]==bytes1("G") ||
                inputB[i]==bytes1("H") ||
                inputB[i]==bytes1("I") ||
                inputB[i]==bytes1("J") ||
                inputB[i]==bytes1("K") ||
                inputB[i]==bytes1("L") ||
                inputB[i]==bytes1("M") ||
                inputB[i]==bytes1("N") ||
                inputB[i]==bytes1("O") ||
                inputB[i]==bytes1("P") ||
                inputB[i]==bytes1("Q") ||
                inputB[i]==bytes1("R") ||
                inputB[i]==bytes1("S") ||
                inputB[i]==bytes1("T") ||
                inputB[i]==bytes1("U") ||
                inputB[i]==bytes1("V") ||
                inputB[i]==bytes1("W") ||
                inputB[i]==bytes1("X") ||
                inputB[i]==bytes1("Y") ||
                inputB[i]==bytes1("Z") ||
                inputB[i]==bytes1("a") ||
                inputB[i]==bytes1("b") ||
                inputB[i]==bytes1("c") ||
                inputB[i]==bytes1("d") ||
                inputB[i]==bytes1("e") ||
                inputB[i]==bytes1("f") ||
                inputB[i]==bytes1("g") ||
                inputB[i]==bytes1("h") ||
                inputB[i]==bytes1("i") ||
                inputB[i]==bytes1("j") ||
                inputB[i]==bytes1("k") ||
                inputB[i]==bytes1("l") ||
                inputB[i]==bytes1("m") ||
                inputB[i]==bytes1("n") ||
                inputB[i]==bytes1("o") ||
                inputB[i]==bytes1("p") ||
                inputB[i]==bytes1("q") ||
                inputB[i]==bytes1("r") ||
                inputB[i]==bytes1("s") ||
                inputB[i]==bytes1("t") ||
                inputB[i]==bytes1("u") ||
                inputB[i]==bytes1("v") ||
                inputB[i]==bytes1("w") ||
                inputB[i]==bytes1("x") ||
                inputB[i]==bytes1("y") ||
                inputB[i]==bytes1("z") ||
                inputB[i]==bytes1(" ") ||
                inputB[i]==bytes1("1") ||
                inputB[i]==bytes1("2") ||
                inputB[i]==bytes1("3") ||
                inputB[i]==bytes1("4") ||
                inputB[i]==bytes1("5") ||
                inputB[i]==bytes1("6") ||
                inputB[i]==bytes1("7") ||
                inputB[i]==bytes1("8") ||
                inputB[i]==bytes1("9") ||
                inputB[i]==bytes1("0") ||
                inputB[i]==bytes1(",") ||
                inputB[i]==bytes1(".") ||
                inputB[i]==bytes1("?") ||
                inputB[i]==bytes1("!") ||
                inputB[i]==bytes1("+") ||
                inputB[i]==bytes1("-") ||
                inputB[i]==bytes1("*") ||
                inputB[i]==bytes1("/") ||
                inputB[i]==bytes1("'")
            ) {
                granted = true;
            } else {
                granted = false;
                revert("only letters, numbers, space and these symbols are allowed: ,.?!+-*/'.");
            }
        }

        return granted;
    }
}


contract PHRASES is WORDS {

    struct Phrases {
        string[]    s;
        uint        p;
    }
    mapping(uint => Phrases) public Phrase;

    uint public total_Sentences;



    function Phrasing(string memory _input) public returns(string memory response) {
    }



}