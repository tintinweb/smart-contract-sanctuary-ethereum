/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract voterRegistry {

    struct Voter{
        string name;
        string biomatric;
    }
    address[] votersArray;
    uint public voterCount;
    address owner;
    mapping(address => bool) private alreadyVoter;
    mapping(address => Voter) public voters;
    
    constructor() {
        owner = msg.sender;
    }

    function registerVoter(address voterAddress,string memory name,string memory uniqueBiomatric) public {
        voterCount++;
        require(!alreadyVoter[voterAddress],"Already registered!!"); 
        voters[voterAddress] = Voter(name,uniqueBiomatric);
        votersArray.push(voterAddress);
        alreadyVoter[voterAddress] = true;
    }

    function getVoter(address _key) public view returns(Voter memory){
            return voters[_key];
    }

    function getAllRegisterVoterAddress() public view returns(address[] memory){
        return votersArray;
    }

}