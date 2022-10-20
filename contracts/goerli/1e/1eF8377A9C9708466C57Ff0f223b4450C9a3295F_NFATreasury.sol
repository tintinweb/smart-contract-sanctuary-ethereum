/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: NFATreasury.sol



pragma solidity ^0.8.0;



interface IdaoContract {
    function balanceOf(address account) external view returns (uint256);
}

contract NFATreasury is ReentrancyGuard {

    address public owner;
    uint256 public nextProposal;
    uint256 public nextVote;
    address[] public validTokens;
    IdaoContract daoContract;

    constructor () {
        owner = msg.sender;
        nextProposal = 1;
        nextVote = 1;
        daoContract = IdaoContract(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60); //Goerli Dai
        validTokens = [0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60]; //Goerli Dai
    }

   struct option {
        uint256 id;
        bool exists;
        string option;
        uint256 totalvotes;
    }
   
   struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint deadline;
        bool countConducted;
        bool open;
        mapping(address => bool) voteStatus;
        uint256 numberOfOptions;
        mapping(uint256 => option) options;
        uint256 totalVotes;
    }

    struct vote {
        uint256 id;
        bool exists;
        address voter1;
        uint256 proposal;
        uint256 votedFor;
    }

    mapping(uint256 => proposal) public Proposals;

    mapping(uint256 => vote) public Votes;

    modifier onlyOwner {
     require (owner == msg.sender, "Only owner may call this function");
     _;
    }

    function checkProposalEligibility(address _proposalist) private view returns (
        bool
    ){
        for (uint i = 0; i < validTokens.length; i ++) {
            if(daoContract.balanceOf(_proposalist) >= 1) {
                return true;
            }
        }
        return false;
    }

    function createProposal (string memory _description, string memory _token1, string memory _token2, string memory _token3, string memory _token4, string memory _token5) external onlyOwner {

        proposal storage newProposal = Proposals[nextProposal];
        newProposal.id = nextProposal;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.number + 86400;
        newProposal.countConducted = false;
        newProposal.open = true;
        newProposal.numberOfOptions = 5;
        newProposal.totalVotes = 0;

        option storage newOption1 = newProposal.options[1];
        newOption1.id = 1;
        newOption1.exists = true;
        newOption1.option = _token1;
        newOption1.totalvotes = 0;

        option storage newOption2 = newProposal.options[2];
        newOption2.id = 2;
        newOption2.exists = true;
        newOption2.option = _token2;
        newOption2.totalvotes = 0;

        option storage newOption3 = newProposal.options[3];
        newOption3.id = 3;
        newOption3.exists = true;
        newOption3.option = _token3;
        newOption3.totalvotes = 0;

        option storage newOption4 = newProposal.options[4];
        newOption4.id = 4;
        newOption4.exists = true;
        newOption4.option = _token4;
        newOption4.totalvotes = 0;

        option storage newOption5 = newProposal.options[5];
        newOption5.id = 5;
        newOption5.exists = true;
        newOption5.option = _token5;
        newOption5.totalvotes = 0;

        nextProposal++;
    }

    function AddOption(uint256 _proposalId, string memory _tokenSymbol) external {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 100,000,000 $MUSHI to put forth proposals.');
        require(Proposals[_proposalId].exists, "This proposal doesn't exist.");
        proposal storage p = Proposals[_proposalId];

        option storage newOption = p.options[p.numberOfOptions + 1];
        newOption.id = p.numberOfOptions + 1;
        newOption.exists = true;
        newOption.option = _tokenSymbol;
        newOption.totalvotes = 0;

        p.numberOfOptions++;
    }

    function VoteOnProposal(uint256 _proposalId, uint256 _optionId) external {
        require(checkProposalEligibility(msg.sender), 'You need to hold at least 100,000,000 $MUSHI to put forth proposals.');
        require(Proposals[_proposalId].exists, "This proposal doesn't exist.");
        require(Proposals[_proposalId].options[_optionId].exists, "This option doesn't exist.");
        require(!Proposals[_proposalId].voteStatus[msg.sender], 'You have already voted on this proposal.');
        require(block.number <= Proposals[_proposalId].deadline, 'The deadline has passed for this proposal.');

        proposal storage p = Proposals[_proposalId];
        option storage o = p.options[_optionId];

        o.totalvotes++;
        p.totalVotes++;
        p.voteStatus[msg.sender] = true;

        vote storage newVote1 = Votes[nextVote];
        newVote1.id = nextVote;
        newVote1.exists = true;
        newVote1.voter1 = msg.sender;
        newVote1.proposal = _proposalId;
        newVote1.votedFor = _optionId;

        nextVote++;
    }

    function countVotes(uint256 _proposalId) external onlyOwner {
        require(Proposals[_proposalId].exists, 'This proposal does not exist.');
        require(block.number > Proposals[_proposalId].deadline, 'Voting has not concluted.');
        require(!Proposals[_proposalId].countConducted, 'Count already conducted.');

        proposal storage p = Proposals[_proposalId];

        p.countConducted = true;
    }

    function getOption(uint256 _proposalId, uint256 _optionId) public view returns(uint256, bool, string memory, uint256) {
        proposal storage p = Proposals[_proposalId];
        option storage o = p.options[_optionId];

        return (o.id, o.exists, o.option, o.totalvotes);
    }
}