/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

/** 
 * 각 은행은(은행 contract) 예치, 인출의 기능을 가지고 있고 국세청은(정부 contract) 모든 국민의 재산정보를 파악하고 있다. 
 * 각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 
 * 이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 
 * 특정 안건에 대해서 투표하는 기능도 구현하고 각 안건은 번호, 제안자 이름, 제목, 내용, 찬-반 비율, 상태로 구성되어 있다. 
 * 안건이 등록되면 등록, 투표중이면 투표, 5분 동안 투표를 진행하는데 찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다. 
 * 안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있고, 안건을 등록할 때마다 0.25 이더씩 깎인다. 세금 납부는 갖고 있는 총 금액의 2%를 실시한다.
 * (예: 100이더 보유 -> 2이더 납부 -> 안건 2개 등록 -> 1.5 납부로 취급) 
 */

contract BankContr {

    /* ---------------------------------------------------------------- */
    /* --------------------------- CITIZENS --------------------------- */
    /* ---------------------------------------------------------------- */

    /* Citizens DB */
    mapping(address => CitizenStruct) citizensMap; // address => CitizenStruct relationship
    struct CitizenStruct {
        // Citizen info
        address addr;
        string citizenName;     
        // Bank balance, tax amount, voting rights
        uint bankBal;
        uint taxAmt;
        uint votingRights; // 1 vote per 1 citizen when taxAmt is equally paid
        // Proposals
        uint[] proposalsArr; // proposalNum
        mapping(uint => ProposalStruct) proposalsMap; // num => ProposalStruct relationship
    }

    /* Proposal data type, status */
    struct ProposalStruct {
        uint proposalNum;
        // string citizenName;
        string content;
        uint upvotesCount;
        uint upvotesRatio;
        EnumStatus status;
    }
    enum EnumStatus {
        ProposalRegistered,
        VotingInProgress,
        IsPassed
    }
    uint proposalNum;

    /* Voting rights, tax amount DB */
    uint totalVotingRights;
    uint totalTaxAmt;

    /* Read totalTaxAmt */
    function getTotalTaxAmt() public view returns(uint) {
        return totalTaxAmt;
    }

    /* Create citizen */
    function setCitizen(string memory _citizenName) public {
        // Add a citizen to the map
        citizensMap[msg.sender].addr = msg.sender;
        citizensMap[msg.sender].citizenName = _citizenName;
        // Bank balance, tax amount, voting rights
        citizensMap[msg.sender].bankBal = msg.sender.balance;
        citizensMap[msg.sender].taxAmt; // function to be added
        citizensMap[msg.sender].votingRights; // function to be added
        // Proposals
        citizensMap[msg.sender].proposalsArr = new uint[](0);
    }

    /* Update citizen - bankBal, taxAmt, votingRights */
    function payTaxAmt(address _addr) public {
        // require(...) to be added for taxAuthority access only
        uint bankBal = citizensMap[_addr].bankBal;
        uint taxAmt = bankBal * 2 / 100; // 2% taxes paid (One-off tax payment assumed)
        citizensMap[_addr].bankBal -= taxAmt; // Updated bankBal
        // Update tax amt
        citizensMap[_addr].taxAmt = taxAmt; // Updated taxAmt
        totalTaxAmt += taxAmt; // Updated total taxAmt
        // Update voting rights
        citizensMap[_addr].votingRights = taxAmt / totalTaxAmt; // Updated voting rights
        totalVotingRights += citizensMap[_addr].votingRights; // Updated total voting rights
    }

    /* Read citizen */
    function getCitizen(address _addr) public view returns(
        // Citizen info
        address, 
        string memory, 
        // Bank balance, tax amount, voting rights
        uint, 
        uint, 
        uint, 
        // Proposals
        uint[] memory
    ) {
        return(
            // Citizen info
            citizensMap[_addr].addr, 
            citizensMap[_addr].citizenName, 
            // Bank balance, tax amount, voting rights
            citizensMap[_addr].bankBal, 
            citizensMap[_addr].taxAmt, 
            citizensMap[_addr].votingRights, 
            // Proposals
            citizensMap[_addr].proposalsArr
        );
    }

    /* ---------------------------------------------------------------- */
    /* -------------------------- PROPOSALS --------------------------- */
    /* ---------------------------------------------------------------- */

    /* Update citizen - Set proposal */
    function setProposal(string memory _content) public {        
        // Requirements
        require(citizensMap[msg.sender].taxAmt >= 1 * 10 ** 18, "At least 1 ETH tax payment required");
        // Update proposalNum
        proposalNum++;
        // Update citizen
        citizensMap[msg.sender].proposalsArr.push(proposalNum);
        citizensMap[msg.sender].bankBal -= 0.25 * 10 ** 18;
        // Update proposal
        citizensMap[msg.sender].proposalsMap[proposalNum].proposalNum = proposalNum;
        citizensMap[msg.sender].proposalsMap[proposalNum].content = _content;
        citizensMap[msg.sender].proposalsMap[proposalNum].upvotesCount;
        citizensMap[msg.sender].proposalsMap[proposalNum].upvotesRatio;
        citizensMap[msg.sender].proposalsMap[proposalNum].status = EnumStatus.ProposalRegistered;
        // Initiate proposalTime
        setTime();
    }

    /* Update proposal - Time lock */
    uint proposalTime;
    function setTime() private {
        proposalTime = block.timestamp;
    }
    function timeLock() private view returns(bool) {
        require(block.timestamp < proposalTime + 60 * 5, "5 minutes passed");
        return true;
    }

    /* Update citizen - Vote */
    function upvoteToProposal(address _addr, uint _proposalNum) public {
        // Time lock requirements
        require(timeLock());
        // Update proposal upvotesCount
        citizensMap[_addr].proposalsMap[_proposalNum].upvotesCount++;
        // Update citizen votingRights
        citizensMap[msg.sender].votingRights--;
    }

    /* Update proposal - Get upvotes ratio */
    function getProposalUpvotesRatio(address _addr, uint _proposalNum) public returns(uint) {
        uint upvotesCount = citizensMap[_addr].proposalsMap[_proposalNum].upvotesCount;
        citizensMap[_addr].proposalsMap[_proposalNum].upvotesRatio = upvotesCount / totalVotingRights * 100;
        uint upvotesRatio = citizensMap[_addr].proposalsMap[_proposalNum].upvotesRatio;
        return upvotesRatio;
    }

    /* Update proposal - Determine if passed */
    function determineProposalResults(address _addr, uint _proposalNum) public view returns(string memory) {
        uint upvotesRatio = citizensMap[_addr].proposalsMap[_proposalNum].upvotesRatio;
        if (upvotesRatio > 60) {
            return "Passed";
        } else {
            return "Did not pass";
        }
    }

}