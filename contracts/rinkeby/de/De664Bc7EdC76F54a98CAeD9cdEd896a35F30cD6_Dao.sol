//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
interface Itoken {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 retue);

    event Approve(
        address indexed owner,
        address indexed spender,
        uint256 retue
    );
}
contract Dao {
    // variables
    struct Member {
        address publicAddress;
        uint256 score;
        bool active;
    }

    struct CandidancyProposal {
        address candidate;
        uint256 forVotes;
        uint256 againstVotes;
        address[] sponsors;
        address[] voters;
        mapping(address => bool) voted;
    }

    Member[] public allMembers;
    Itoken public GovernanceToken;
    uint256 SCORE_AFTER_VOTE = 1;
    address public OWNER;
    address public treasureWallet;

    mapping(address => Member) public members;
    mapping(address => uint256) public _balances;

    mapping(address => CandidancyProposal) public candidancyProposals;

    mapping(address => bool) public blacklisted;

    uint256 public proposalsCreated = 0;

    constructor() {
        address _owner =msg.sender;
        GovernanceToken = Itoken(0x01BE23585060835E02B77ef475b0Cc51aA1e0709);
        members[_owner].publicAddress = _owner;
        members[_owner].score = 1;
        members[_owner].active = true;
        OWNER = _owner;
        allMembers.push(members[_owner]);
        treasureWallet = msg.sender;
    }

    function signAsSponsor(address user) public {
        require(members[msg.sender].active,"not a member");
        candidancyProposals[user].sponsors.push(msg.sender);
        airdrop(msg.sender);
    }

    function getSponsorsOfProposal(address user)
        public
        view
        returns (address[] memory)
    {
        return candidancyProposals[user].sponsors;
    }
    function airdrop(address user) internal {
        if(_balances[user]<members[user].score){
            uint256 amount = members[user].score-_balances[user];
        GovernanceToken.transferFrom(treasureWallet,user,amount*(10**(GovernanceToken.decimals())));
        _balances[user] = members[user].score;                                                                  
        }
    }
    function getairdrop() external {
        airdrop(msg.sender);
    }
    function calculateResult(address user) public returns (bool) {
        require(msg.sender == OWNER,"only the owner can call this function");
        uint256 forVotes = candidancyProposals[user].forVotes;
        uint256 againstVotes = candidancyProposals[user].againstVotes;
        if (forVotes > againstVotes) {
            
            members[candidancyProposals[user].candidate].publicAddress = candidancyProposals[user].candidate;
            members[candidancyProposals[user].candidate].score = 0;
            members[candidancyProposals[user].candidate].active = true;
            // add scores for sponsor
            for (uint256 i;i < candidancyProposals[user].sponsors.length;i++) {
                members[candidancyProposals[user].sponsors[i]].score += SCORE_AFTER_VOTE;
            }
            airdrop(user);
            return true;
        } else {
            blacklisted[candidancyProposals[user].candidate] = true;
            // substract scores for sponsor
            for (uint256 i;i < candidancyProposals[user].sponsors.length;i++) {
                members[candidancyProposals[user].sponsors[i]].score -= SCORE_AFTER_VOTE;
            }
            return false;
        }
    }

    function voteToCandidancyProposal(bool vote, address user) public {
        // give vote
        require(members[msg.sender].active,"not a member");
        require(!blacklisted[user],"user is blacklisted");
        require(!members[user].active,"user is already a member");
        require(candidancyProposals[user].candidate != msg.sender,"you can't vote for yourself");
        require(!candidancyProposals[user].voted[msg.sender],"you have already voted");

        if (vote) {
            candidancyProposals[user].forVotes += members[msg.sender].score;
        } else {
            candidancyProposals[user].againstVotes += members[msg.sender].score;
        }

        candidancyProposals[user].voters.push(msg.sender);
        candidancyProposals[user].voted[msg.sender] = true;
    }

    function saveCandidancyProposal() public {
        require(!blacklisted[msg.sender],"user is blacklisted");

        candidancyProposals[msg.sender].candidate = msg.sender;
        candidancyProposals[msg.sender].forVotes = 0;
        candidancyProposals[msg.sender].againstVotes = 0;

        proposalsCreated++;
    }

    function trasferOwnership(address user) public {
        require(msg.sender == OWNER,"only the owner can call this function");
        require(user != address(0),"user is not valid");
        OWNER = user;
        members[OWNER].publicAddress = OWNER;
        members[OWNER].score = 0;
        members[OWNER].active = true;
        allMembers.push(members[OWNER]);
    }

    function setScore(uint256 score) public {
        require(msg.sender == OWNER,"only the owner can call this function");
        SCORE_AFTER_VOTE = score;
    }

    function withdrawlostfunds(Itoken token) external {
        require(msg.sender == OWNER,"only the owner can call this function");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function cliamable(address user) public view returns(uint256 amount){
        if(_balances[user] < members[user].score){
            return  members[user].score-_balances[user];
        }
    return 0;

    }

}