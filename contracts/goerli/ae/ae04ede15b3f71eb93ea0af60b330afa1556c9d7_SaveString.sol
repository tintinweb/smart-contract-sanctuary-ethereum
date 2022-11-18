/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

pragma solidity ^0.8.3;

contract SaveString {
    string ipfsHash;
    
    
    event SendHash(address indexed hitter,string indexed _x);

    function sendHash(string memory x) public {
        ipfsHash = x;
        emit SendHash(msg.sender, x);
    }
    
    function getString() public view returns (string memory) {
        return ipfsHash;
    }
}