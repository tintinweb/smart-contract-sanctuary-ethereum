/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Candidate{
    string name; //ชื่อผู้สมัคร
    uint voteCount;//จำนวนคนเลือก
}

struct Voter{
    bool isRegister;
    bool isVoted;
    uint voteIndex;
    string idCardNumber;
}

contract ElectionBKK{
    address public manager;//เจ้าหน้าที่จัดการเลือกตั้ง
    Candidate [] public candidates;
    mapping(address => Voter) public voter;
    constructor(){
        manager = msg.sender;
        addCandidate("Wiroj Lakkhanaadisorn");
        addCandidate("Thita Rangsitpol Manitkul");
        addCandidate("Sakoltee Phattiyakul");
        addCandidate("Suchatvee Suwansawat");
        addCandidate("Weerachai Laoruangwattana");
        addCandidate("Aswin Kwanmuang");
        addCandidate("Rosana Tositrakul");
        addCandidate("Chadchart Sittipunt");
        addCandidate("Watcharee Wannasri");
        addCandidate("Supachai Tantikom");
        addCandidate("Sita Divari");
        addCandidate("Prayoon Krongyoth");
        addCandidate("Paisal Kittiyaowaman");
        addCandidate("Thanet Wongsa");
        addCandidate("Tootpreecha Loetsantatwati");
        addCandidate("Sasikarn Waddhanachan");
        addCandidate("Uthen Chatphinyo");
        addCandidate("Sumana Phanphairoj");
        addCandidate("Kraidech Bunnak");
        addCandidate("Amonpan Oonsuwan");
        addCandidate("Niphanphon Suwanchana");
        addCandidate("Warunchai Chokchana");
        addCandidate("Chalermpol Utarat");
        addCandidate("Kosit Suwinitchit");
        addCandidate("Praphat Banjongsiricharoen");
        addCandidate("Mongkol Nguenwatthana");
        addCandidate("Poompat Atsawapumpin");
        addCandidate("Sarawut Benchakul");
        addCandidate("Kritchai Phayomyaem");
        addCandidate("Phongsa Chunaem");
        addCandidate("Whitthaya Jangkobpatthana");
    }
    modifier onlyManager{
        require(msg.sender == manager, "You Can,t Manager");
        _;
    }
    modifier onlyRegister{
        require(voter[msg.sender].isRegister, "You Can't Register");
        _;
    }

    function addCandidate(string memory name) onlyManager public{
        candidates.push(Candidate(name, 0));
    }
    function register(address person, string memory _idCardNumber) onlyManager public{
        voter[person].isRegister = true;
        voter[person].idCardNumber = _idCardNumber;
    }
    function vote(uint index, bool show) onlyRegister public{
        require(!voter[msg.sender].isVoted, "You Can't Elected");
        if(show){
            voter[msg.sender].voteIndex = index;
        }
        else{
            voter[msg.sender].voteIndex = 9999;
        }
        voter[msg.sender].isVoted = true;
        candidates[index].voteCount += 1;
    }
    function winningProposal() public view returns (uint winningProposal_){
        uint winningVoteCount = 0;
        for (uint p = 0; p < candidates.length; p++) {
            if (candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = candidates[p].voteCount;
                winningProposal_ = p;
            }
        }
    }
}