// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum Option {
    A,
    B
}

// Checkpoint 3: Add an uint256 called minimumVotes as a parameter
// Checkpoint 4: Add:
// - two address optionA and optionB
// - two string names (nameForOptionA and nameForOptionB) for those options
// Checkpoint 5: Add a bool (executed) to check if proposal has been executed
struct Proposal {
    string title;
    uint256 proposalDeadline;
    uint256 votesForOptionA;
    uint256 votesForOptionB;
    uint256 minimumVotes;
    address optionA;
    address optionB;
    string nameForOptionA;
    string nameForOptionB;
    bool executed;
}

// Checkpoint 5: Create a struct Winner with:
// - an uint256 for proposalId
// - a string winnerName
// - an address for winnerAddress
struct Winner {
    uint256 proposalId;
    string winnerName;
    address winnerAddress;
}

contract Khazum is Ownable {
    // Checkpoint 3: In ProposalCreated, include minimumVotes as a parameter of the same type as in the Proposal struct
    // Checkpoint 4: In ProposalCreated, include newly added Proposal struct values
    event ProposalCreated(
        uint256 proposalId,
        string title,
        uint256 proposalDeadline,
        uint256 minimumVotes,
        address optionA,
        address optionB,
        string nameForOptionA,
        string nameForOptionB
    );
    event VoteCasted(uint256 proposalId, address voter, Option selectedOption);

    mapping(uint256 => Proposal) public proposals;
    // Checkpoint 5: Create a mapping (winners) from uint256 (proposal id) to Winner struct
    mapping(uint256 => Winner) public winners;
    mapping(address => mapping(uint256 => bool)) public hasVoted;
    mapping(address => mapping(uint256 => Option)) public voterOption;

    uint256 public proposalCounter;
    IERC20 private khaToken;

    constructor(address _khaTokenAddress) {
        khaToken = IERC20(_khaTokenAddress);
    }

    // Checkpoint 3: Edit createProposal to:
    // - Take _minimumVotes as a parameter
    // - Require _minimumVotes to be greater than 0
    // - Add _minimumVotes as an atribute for the proposal (as newProposal.title does for title)
    // - Add _minimumVotes as an arguments to emit ProposalCreated
    // Checkpoint 4: Edit createProposal to:
    // - Include new values from Proposal to createProposal
    function createProposal(
        string memory _title,
        uint256 _proposalDurationInMinutes,
        uint256 _minimumVotes,
        address _optionA,
        address _optionB,
        string memory _nameForOptionA,
        string memory _nameForOptionB
    ) public {
        require(_proposalDurationInMinutes > 0, "Proposal duration must be greater than zero");
        require(_minimumVotes > 0, "Minimum votes must be greater than zero");

        Proposal memory newProposal;
        newProposal.title = _title;
        newProposal.proposalDeadline = block.timestamp + (_proposalDurationInMinutes * 1 minutes);
        newProposal.minimumVotes = _minimumVotes;
        newProposal.optionA = _optionA;
        newProposal.optionB = _optionB;
        newProposal.nameForOptionA = _nameForOptionA;
        newProposal.nameForOptionB = _nameForOptionB;

        uint256 proposalId = proposalCounter;
        proposals[proposalCounter] = newProposal;
        proposalCounter++;

        emit ProposalCreated(
            proposalId,
            _title,
            newProposal.proposalDeadline,
            _minimumVotes,
            _optionA,
            _optionB,
            _nameForOptionA,
            _nameForOptionB
        );
    }

    function vote(uint256 _proposalId, Option _selectedOption) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.proposalDeadline, "Proposal has expired");
        require(!hasVoted[msg.sender][_proposalId], "Already voted");
        require(_selectedOption == Option.A || _selectedOption == Option.B, "Invalid option");

        uint256 votingPower = khaToken.balanceOf(msg.sender);
        require(votingPower > 0, "Voter has no voting power");

        if (_selectedOption == Option.A) {
            proposal.votesForOptionA += votingPower;
        } else {
            proposal.votesForOptionB += votingPower;
        }

        hasVoted[msg.sender][_proposalId] = true;

        emit VoteCasted(_proposalId, msg.sender, _selectedOption);
    }

    // Checkpoint 5: Uncomment this function

    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.proposalDeadline, "Proposal deadline not yet reached");
        require(!proposal.executed, "Proposal already executed");

        Winner memory winner;
        if (proposal.votesForOptionA > proposal.votesForOptionB) {
            winner.proposalId = _proposalId;
            winner.winnerName = proposal.nameForOptionA;
            winner.winnerAddress = proposal.optionA;
        } else if (proposal.votesForOptionB > proposal.votesForOptionA) {
            winner.proposalId = _proposalId;
            winner.winnerName = proposal.nameForOptionB;
            winner.winnerAddress = proposal.optionB;
        } else {
            // Handle tie case, if desired
            revert("Tie not allowed");
        }

        winners[_proposalId] = winner;
        proposal.executed = true;
    }

    // Checkpoint 3: Edit getProposal to:
    // - return minimumVotes from the proposal
    // Hint: remember to add it to returns in the function header and also like proposal.title
    // Checkpoint 4: Return all the new values in Proposal struct from getProposal
    // Checkpoint 5: Return the bool executed from getProposal
    function getProposal(uint256 _proposalId)
        public
        view
        returns (
            string memory title,
            uint256 proposalDeadline,
            uint256 votesForOptionA,
            uint256 votesForOptionB,
            uint256 minimumVotes,
            address optionA,
            address optionB,
            string memory nameForOptionA,
            string memory nameForOptionB,
            bool executed
        )
    {
        Proposal storage proposal = proposals[_proposalId];

        title = proposal.title;
        proposalDeadline = proposal.proposalDeadline;
        votesForOptionA = proposal.votesForOptionA;
        votesForOptionB = proposal.votesForOptionB;
        minimumVotes = proposal.minimumVotes;
        optionA = proposal.optionA;
        optionB = proposal.optionB;
        nameForOptionA = proposal.nameForOptionA;
        nameForOptionB = proposal.nameForOptionB;
        executed = proposal.executed;
    }

    // Checkpoint 5: Add a getWinner function similar to getProposal
    // - takes a _proposalId as parameter
    // - reads Winner struct from storage (check getProposal for guidance)
    // - returns winnerName and winnerAddress
    function getWinner(uint256 _proposalId) public view returns (string memory winnerName, address winnerAddress) {
        Winner storage winner = winners[_proposalId];

        winnerName = winner.winnerName;
        winnerAddress = winner.winnerAddress;
    }

    function viewHasVoted(uint256 _proposalId, address _voter) public view returns (bool) {
        require(_proposalId < proposalCounter, "Invalid proposal ID");
        return hasVoted[_voter][_proposalId];
    }

    function getProposalCount() public view returns (uint256) {
        return proposalCounter;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}