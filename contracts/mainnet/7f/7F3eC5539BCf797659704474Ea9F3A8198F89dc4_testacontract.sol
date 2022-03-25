/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

pragma solidity ^0.7.0;

contract testacontract {

    function gimmeastring(uint256 a) public pure returns (string memory) {
        if(a == 1) {
            return "baabaablacksheep";
        } else {
            return "marry had a wittle lamb";
        }
    }

}