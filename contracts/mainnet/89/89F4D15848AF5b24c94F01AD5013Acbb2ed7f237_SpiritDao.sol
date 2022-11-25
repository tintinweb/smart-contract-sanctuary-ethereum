/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: SpiritDAO.sol



pragma solidity ^0.8.7;


interface IdaoContract {
    function balanceOf(address account) external view returns (uint256);
}

contract SpiritDao is ReentrancyGuard {
    address public owner;
    uint256 public nextProposal;
    uint256 public nextVote;
    address[] public validTokens;
    IdaoContract daoContract;

    constructor () {
        owner = msg.sender;
        nextProposal = 1;
        nextVote = 1;
        daoContract = IdaoContract(0xe12E0FC381454cC4C4Be2D2147E44bf65b073723); // Spirit Address 
        validTokens = [0xe12E0FC381454cC4C4Be2D2147E44bf65b073723]; // Spirit Address
    }

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    struct vote {
        uint256 id;
        bool exists;
        uint256 votesUp;
        uint256 votesDown;
        address voter1;
        uint256 proposal;
        bool votedFor;
    }

    mapping(uint256 => proposal) public Proposals;
    mapping(uint256 => vote) public Votes;

    event proposalCreated(
        uint256 id,
        string description,
        address proposer
    );

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal, 
        bool votedFor
    );

    event proposalCount(
        uint256 id,
        bool passed
    );

    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for (uint i = 0; i < validTokens.length; i ++) {
            if(daoContract.balanceOf(_proposalist) >= 500000000000000000) {
                return true;
            }
        }
        return false;
    }

    function createProposal(string memory _description) public {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 500,000,000 $SPIRIT to put forth proposals.');

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 50000;

        emit proposalCreated(nextProposal, _description, msg.sender);
        nextProposal++;
    }

    function getUserVoteValue(address user) public view returns (uint) {
        uint256 tokenBalance = daoContract.balanceOf(user);
        uint256 minimumBalanceForOneVote = 500000000000000000;

        uint256 userVoteValue = tokenBalance / minimumBalanceForOneVote;

        return userVoteValue;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 500,000,000 $SPIRIT to put forth proposals.');
        require(Proposals[_id].exists, "This proposal doesn't exist.");
        require(!Proposals[_id].voteStatus[msg.sender], 'You have already voted on this proposal.');
        require(block.number <= Proposals[_id].deadline, 'The deadline has passed for this proposal.');
        require(!Proposals[_id].countConducted, 'Count already conducted.');

        uint256 tokenBalance = daoContract.balanceOf(msg.sender);
        uint256 minimumBalanceForOneVote = 500000000000000000;

        uint256 userVoteValue = tokenBalance / minimumBalanceForOneVote;

        proposal storage p = Proposals[_id];

        if(_vote) {
            p.votesUp = p.votesUp + userVoteValue;
        } else {
            p.votesDown = p.votesDown + userVoteValue;
        }

        p.voteStatus[msg.sender] = true; 

        vote storage newVote1 = Votes[nextVote];
        newVote1.id = nextVote;
        newVote1.exists = true;
        newVote1.votesUp = p.votesUp;
        newVote1.votesDown = p.votesDown;
        newVote1.voter1 = msg.sender;
        newVote1.proposal = _id;
        newVote1.votedFor = _vote;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
        nextVote++;
    }

    function countVotes(uint256 _id) public {
        require(msg.sender == owner, 'Only the owner can count votes.');
        require(Proposals[_id].exists, 'This proposal does not exist.');
        require(!Proposals[_id].countConducted, 'Count already conducted.');

        proposal storage p = Proposals[_id];

        if(Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }
}