/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

contract voting {

    struct Voter {
        bool hasVoted;
        bool exists;
    }

    struct Option {
        uint voteCount;
        bool exists;
    }

    mapping(string => Option) public options;
    mapping(address => Voter) public voters;

    constructor() {
        options["nft"]      = Option(0, true);
        options["token"]	= Option(0, true);
        options["dao"]	    = Option(0, true);
        voters[0x511D365E3e0D01F29E092706664c6559A8328123] = Voter(false, true);
        voters[0x9A0e3A6Dfc8E3C9Ba53d59C120898883d0Cee732] = Voter(false, true); 
        voters[0x2B591447e758B02a291a91deAA08341f1b6d4E92] = Voter(false, true); 
        voters[0x3995A4372e0e2F217786f0c3f125891a32DEe889] = Voter(false, true); 
        voters[0xba472F1b9473ed6D7bD62993992bD215B77b9380] = Voter(false, true);
        voters[0xd760dE41EfD1DC2EbfF26C55419181B4Ff8F2d64] = Voter(false, true);
        voters[0x546B7CfdD4ffDbD736790B0eeA1c991001A4f5A9] = Voter(false, true);
    }

    function vote(string memory _option) public {
        require(voters[msg.sender].exists = true);
        require(voters[msg.sender].hasVoted = false);
        require(options[_option].exists = true);
        options[_option].voteCount = options[_option].voteCount + 1;
        voters[msg.sender].hasVoted = true;
    }

    function getVoteCount(string memory _option) private view returns (uint) {
        return options[_option].voteCount;
    }

    function determineWinner() public view returns (string memory){
        if (getVoteCount("nft") > getVoteCount("token") && getVoteCount("nft") > getVoteCount("dao")) {
            return "nft";
        } else if (getVoteCount("token") > getVoteCount("nft") && getVoteCount("token") > getVoteCount("dao")) {
            return "token";
        } else if (getVoteCount("dao") > getVoteCount("nft") && getVoteCount("dao") > getVoteCount("token")) {
            return "dao";
        } 
        else return "manual tiebreaker required";
    }
}