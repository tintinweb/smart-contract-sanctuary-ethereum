/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity ^0.6.6;

contract NFTContract {
    string public hashNumber = "";
    string public cidNumber = "";

    
    function setHash(string memory _hashNumber, string memory _cidNumber) public {
        hashNumber = _hashNumber;
        cidNumber = _cidNumber;
    }
}