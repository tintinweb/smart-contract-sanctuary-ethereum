/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

pragma solidity ^0.8.18;

contract ipfsContract{
    address public owner;
    string public ipfsHash;

constructor(){
    ipfsHash = "NoHashStoredYet";
    owner = msg.sender;
}

function changeHash(string memory newHash) public{
    require(msg.sender == owner, "Not Owner of Contract");
    ipfsHash = newHash;
}
    function fetchHash() public view returns (string memory){
        return (ipfsHash);
    }
}