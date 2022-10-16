/**
 *Submitted for verification at Etherscan.io on 2022-10-16
*/

/** 
 *  SourceUnit: /home/adebara/Celo-Hackathon/build-with-celo-hackathon/Succour DAO- Contract/contracts/Succour.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 {

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);


}




/** 
 *  SourceUnit: /home/adebara/Celo-Hackathon/build-with-celo-hackathon/Succour DAO- Contract/contracts/Succour.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.4;

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
}

/** 
 *  SourceUnit: /home/adebara/Celo-Hackathon/build-with-celo-hackathon/Succour DAO- Contract/contracts/Succour.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.4;

////import "./Proxiable.sol";
////import "./ISuccour.sol";

contract Succour is Proxiable{


//0x9b7Fb05121f7AAC62a324e109c10F138eCd5C342
    
    address public owner;

    struct DAOMembers {
        string name;
        uint memberId;
        address memberAddress;
        uint balance;
        uint percentageOfDAO;
        uint votingPower;
        uint withDrawTime;
        bool withdrawStatus;
    }

    struct Proposals {
        uint ID;
        uint amountProposed;
        uint amountGotten;
        string Title;
        string Description;
        uint NumberOfVotes;
        bool approved;
        address[] voters;
        address proposer;
        uint approveWithdraw;
    } 

    mapping (uint => Proposals) public proposals;
    mapping (address => DAOMembers) public members;

    uint public minimumRequirement;
    uint public maximumRequirement;
    IERC20 public celoTokenAddress;
    uint public totalVotingPower;
    uint public totalDAOBalance;
    uint proposalID = 1;
    uint memberID = 1;

    address[] EligibleVoters;
    DAOMembers[] public membersData;
    Proposals[] allProposals;
    Proposals[] approvedProposals;

      modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to perform this action");
        _;
    }



    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }


    function encode(uint _minimumRequirement, uint _maximumRequirement, address _celoTokenAddress) external pure returns (bytes memory) {
        return abi.encodeWithSignature("initializer(uint256,uint256,address)", _minimumRequirement, _maximumRequirement, _celoTokenAddress);
    }

     function initializer(uint _minimumRequirement, uint _maximumRequirement, address _celoTokenAddress) public {
        require(owner == address(0), "Already initalized");
        owner = msg.sender;
        minimumRequirement = _minimumRequirement;
        maximumRequirement = _maximumRequirement;
        celoTokenAddress = IERC20(_celoTokenAddress);
    }


    function setMinAndMaxRequirement (uint _minimumRequirement, uint _maximumRequirement) external onlyOwner {
        minimumRequirement = _minimumRequirement;
        maximumRequirement = _maximumRequirement;
    }

    function depositMember (uint amount) internal {
        require(amount >= minimumRequirement, "You can't join DAO");
        require(amount <= maximumRequirement, "Reduce amount to join DAO");
        depositIntoDAO(amount);
    } 

    function joinDAO (string memory _name, uint amount) public {
         memberID++;
         depositMember(amount);
         DAOMembers storage DM = members[msg.sender];
         DM.name = _name;
         DM.memberId = memberID;
         DM.memberAddress = msg.sender;
         DM.balance += amount;
         totalDAOBalance += amount;
         EligibleVoters.push(msg.sender);
         uint percent = memberPercentage(amount);
         uint power = votePower(amount) / 1e6;
         totalVotingPower += power;
         DM.percentageOfDAO = percent;
         DM.votingPower = power;
         membersData.push(DM);
    }

    function memberPercentage(uint bal) public view returns(uint DAOPercentage){
        DAOPercentage = (bal * 100) / totalDAOBalance;
    }

    function votePower (uint bal) public view returns (uint power) {
        power = (bal * 1e6)/minimumRequirement;
    }

    function checkDAOEligibility (address addr) public view returns (bool status) {
        for (uint i; i < EligibleVoters.length; i++) {
            if (EligibleVoters[i] == addr) {
                status = true;
            }
        }
    }

    function checkIfVoted (address addr, uint id) public view returns (bool status) {
        address[] memory proposalVotees = proposals[id].voters;
        for (uint i; i < proposalVotees.length; i++) {
            if (proposalVotees[i] == addr) {
                status = true;
            }
        }
    }
 
    function proposeProject (string memory _title, string memory _description, uint _amountProposed) external  {
        proposalID++;
        bool check = checkDAOEligibility(msg.sender);
        require(check == true, "You can't propose a project");
        Proposals storage propose = proposals[proposalID];
        propose.ID = proposalID;
        propose.amountProposed = _amountProposed;
        propose.Title = _title;
        propose.Description = _description;
        propose.voters.push(msg.sender);
        allProposals.push(propose);
    }


    function memberVote (uint IDofProposal) external {
        bool check1 = checkDAOEligibility(msg.sender);
        require(check1 == true, "You can't vote");
        Proposals storage propose = proposals[IDofProposal];
        uint position = propose.ID;
        bool check2 = checkIfVoted(msg.sender, position); 
        require(check2 != true, "You can't vote twice");
        uint votepower = members[msg.sender].votingPower;
        uint currentVotes = propose.NumberOfVotes;
        propose.NumberOfVotes += votepower;
        allProposals[position-1].NumberOfVotes += votepower;
        uint projectVotes = (currentVotes/totalVotingPower) * 100;
        uint requiredVote =  projectRequiredPercentage();
        propose.voters.push(msg.sender);
        allProposals[position-1].voters.push(msg.sender);
        if (projectVotes >= requiredVote) {
            approvedProposals.push(propose);
            propose.approved = true;
            uint DAOdonation = donationFromDAO(position);
            propose.amountGotten += DAOdonation;
            approvedProposals[position-1].amountGotten += DAOdonation;
        }
    }

    function donationFromDAO (uint id) private returns(uint DAOtotalPay){
        DAOMembers storage DM = members[msg.sender];
        uint proposedAmount = proposals[id].amountProposed;
        DAOtotalPay = (60 * proposedAmount) / 100 ;
        uint IDofMember = DM.memberId;
        uint DAOmembers = EligibleVoters.length;
        uint memberPayment = DAOtotalPay / DAOmembers;
        DM.balance -= memberPayment;
        membersData[IDofMember - 1].balance -= memberPayment;
        depositIntoDAO(memberPayment);
    }


     function donateToProject (uint amount, uint projectPosition) public {
        depositIntoDAO(amount);
        proposals[projectPosition].amountGotten += amount;
        approvedProposals[projectPosition-1].amountGotten += amount;
    }


    function depositIntoDAO (uint amount) public {
        IERC20(celoTokenAddress).transferFrom(msg.sender, address(this), amount);
    }

    function projectRequiredPercentage () public view returns(uint result) {
        result = (70 * totalVotingPower) / 100;
    }


    function requestToWithdrawDAO () public  {
        bool eligibility = checkDAOEligibility(msg.sender);
        require(eligibility == true, "You aren't part of DAO");
        DAOMembers storage DM = members[msg.sender];
        uint timeRequired = block.timestamp + 14 days;
        DM.withDrawTime += timeRequired;
        DM.withdrawStatus = true;
    }


   function WithDrawFromDao (uint amount) public {
       DAOMembers storage DM = members[msg.sender];
       bool status = DM.withdrawStatus;
       uint time = DM.withDrawTime;
       require(status == true, "You haven't requested for withdrawal");
       require(block.timestamp >= time, "Time of withdrawal not reached");
       require(amount <= DM.balance, "You cant send more than you have");
       uint IDofMember = DM.memberId;
       DM.balance -= amount;
       membersData[IDofMember - 1].balance -= amount;
       IERC20(celoTokenAddress).transferFrom(address(this), msg.sender, amount);
       DM.withdrawStatus = false;
       DM.withDrawTime = 0;
   }

   function approveWithdrawProposalFund (uint IDofProposal) public {
        bool eligibility = checkDAOEligibility(msg.sender);
        require(eligibility == true, "You aren't part of DAO");
        uint votepower = members[msg.sender].votingPower;
        Proposals storage propose = proposals[IDofProposal];
        propose.approveWithdraw += votepower;
   }


   function withdrawProposalFund (address addr, uint IDofProposal) public  onlyOwner {
       require(addr != address(0), "Can't withdraw to this Address");
       Proposals storage propose = proposals[IDofProposal];
       uint proposedAmount = propose.amountProposed;
       uint IdofProposal = propose.ID;
       uint proposedAmountGotten = propose.amountGotten;
       require(proposedAmountGotten >= proposedAmount, "Proposed amount not gotten");
       uint approvalPower = projectRequiredPercentage();
       uint gottenVote = (propose.approveWithdraw / totalVotingPower) * 100;
       require(gottenVote >= approvalPower, "You can't withdraw yet");
       propose.amountGotten = 0;
       approvedProposals[IdofProposal -1].amountGotten = 0;
       IERC20(celoTokenAddress).transferFrom(address(this), addr, proposedAmountGotten);
   }


   function viewMembers () public view returns(DAOMembers[] memory) {
        return membersData;
    }


   function viewAllProposals () public view returns(Proposals[] memory) {
        return allProposals;
    }

    function viewElidgibleMembers () public view returns(address[] memory) {
        return EligibleVoters;
    }


   function viewAllApprovedProposals () public view returns(Proposals[] memory) {
        return approvedProposals;
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

                            /////// Gooooo FUNDMEEEEEEEE ////////////////////


        struct individualFundMe {
            uint goFundID;
            string name;
            string reasonForFund;
            uint amountNeeded;
            uint amountGotten;
            bool status;
        } 
        uint GOFUNDId = 1;
        mapping (address => individualFundMe) GoFunds;
        individualFundMe[] public goFunds;
        individualFundMe[] public sucessfulGoFunds;


        function createGofund (string memory _name, string memory _reasonForFund, uint _amountNeeded ) public {
            GOFUNDId++;
            individualFundMe storage GOFUND = GoFunds[msg.sender];
            GOFUND.name = _name;
            GOFUND.reasonForFund = _reasonForFund;
            GOFUND.amountNeeded = _amountNeeded;
            GOFUND.goFundID = GOFUNDId;
            goFunds.push(GOFUND);
        }


        function fundGoFund (uint amount, address addr)public {
            individualFundMe storage GOFUND = GoFunds[addr];
            depositIntoDAO(amount);
            uint idOfGoFund = GOFUND.goFundID;
            GOFUND.amountGotten += amount;
            goFunds[idOfGoFund - 1].amountGotten += amount;
        }

        function withdrawFromGoFund (address addr)public {
            individualFundMe storage GOFUND = GoFunds[msg.sender];
            require (addr != address(0), "Can't withdraw to this address");
            uint fundsGotten = GoFunds[msg.sender].amountGotten;
            uint neededFund = GoFunds[msg.sender].amountNeeded;
            require(fundsGotten >= neededFund, "You can't withDraw until fund is complete");
            uint idOfGoFund = GoFunds[msg.sender].goFundID;
            goFunds[idOfGoFund - 1].amountGotten = 0;
            GoFunds[msg.sender].amountGotten = 0;
            goFunds[idOfGoFund - 1].status = true;
            GoFunds[msg.sender].status = true;
            IERC20(celoTokenAddress).transferFrom(address(this), addr, fundsGotten);
            sucessfulGoFunds.push(GOFUND);
        }
        function returnAllGoFunds () public view returns(individualFundMe[] memory) {
            return goFunds;
        }

        function returnAllSuccessFulGoFunds () public view returns(individualFundMe[] memory) {
            return sucessfulGoFunds;
        }


    
}