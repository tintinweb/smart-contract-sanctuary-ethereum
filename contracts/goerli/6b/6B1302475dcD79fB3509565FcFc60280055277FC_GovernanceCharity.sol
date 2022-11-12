// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IGovernanceCharity.sol";
import "./interfaces/IGovernanceVoting.sol";
import "./interfaces/IGovernanceRegistry.sol";

contract GovernanceCharity is IGovernanceCharity, Ownable {
    //----------------------------------------------------- storage

    uint256 public override requestCounter;

    address public immutable override registry;

    mapping(address => Status) private _status;

    mapping(uint256 => Request) private _requests;

    //----------------------------------------------------- modifiers

    modifier onlyVerified(address operator) {
        require(_status[operator] == Status.Verified, "Not verified");
        _;
    }

    //----------------------------------------------------- misc functions

    constructor(address _registry) Ownable() {
        registry = _registry;
    }

    function register(bytes calldata proof) external override {
        require(_status[msg.sender] == Status.None, "Already registered");

        _status[msg.sender] = Status.Registered;

        emit Registered(msg.sender, proof);
    }

    function verify(address charity) external override onlyOwner {
        require(_status[charity] == Status.Registered, "Not registered");

        _status[charity] = Status.Verified;
        emit Verified(charity);
    }

    function requestFunding(uint256 amount)
        external
        override
        onlyVerified(msg.sender)
        returns (uint256 epoch)
    {
        // Check we have non-zero amount
        require(amount > 0, "Must request non-zero amounts");

        // Make a call to GovernanceVoting to try add the charity to the current proposal
        epoch = IGovernanceVoting(IGovernanceRegistry(registry).governanceVoter()).addCharity(msg.sender, amount);
    }

    function cancelRequest() 
        external
        override
        onlyVerified(msg.sender) 
    {
        // Wipe out charity entry from a pending proposal
        IGovernanceVoting(IGovernanceRegistry(registry).governanceVoter()).removeCharity(msg.sender);
    }

    //----------------------------------------------------- accessors

    function notFunded(uint256 requestId) external view override returns (bool) {
        Request memory request = _requests[requestId];
        return request.charity != address(0) && !request.funded;
    }

    function statusOf(address charity) external view override returns (Status) {
        return _status[charity];
    }

    function getFundingRequest(uint256 requestId) external view override returns (Request memory) {
        return _requests[requestId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/** @dev This contract is the main interface for charities
        and allows charities to register and be verified
 */
interface IGovernanceCharity {
    //----------------------------------------------------- types

    enum Status {
        None,
        Registered,
        Verified
    }

    struct Request {
        address charity;
        bool funded;
        uint256 amount;
    }

    //----------------------------------------------------- events

    /// @notice Emitted when a charity is registered to be verified.
    event Registered(address charity, bytes proof);

    /// @notice Emitted when a charity is verified.
    event Verified(address charity);

    //----------------------------------------------------- external functions

    function register(bytes calldata proof) external;

    function verify(address charity) external;

    function requestFunding(uint256 amount) external returns (uint256 epoch);

    function cancelRequest() external;

    //----------------------------------------------------- accessor functions

    function notFunded(uint256 requestId) external view returns (bool);

    function requestCounter() external view returns (uint256);

    function registry() external view returns (address);

    function statusOf(address charity) external view returns (Status);

    function getFundingRequest(uint256 requestId) external view returns (Request memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (governance/IGovernor.sol)
// Modified Governor contract for chainlink hackathon

pragma solidity ^0.8.9;

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernanceVoting {
    enum ProposalState {
        None,
        Pending,
        Active,
        Queued,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 epoch,
        address proposer,
        uint256 startTimestamp,
        uint256 endTimestamp,
        string description
    );

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, address charity, uint256 votes, string description);


    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        uint256 epoch
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, or delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);
    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);
    /**
     * @notice module:voting
     * @dev Returns whether `account` has cast a vote on `proposalId`.
     */
    function numVotes(uint256 proposalId, address account) external view virtual returns (uint256);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        uint256 proposalId
    ) public virtual returns (uint256);

    /**
     * @dev Add a charity to the queued proposal or to the next one if we register too late

       Ensure only GovernanceCharity can call this function
     */
    function addCharity(address charity, uint256 amount) external virtual returns (uint256 epoch);

    function removeCharity(address charity) external virtual;

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, address charity) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        address charity,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
    */
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IGovernanceRegistry {
    function governanceToken() external view returns (address token);

    function setGovernanceToken(address token) external;

    function governanceCharity() external view returns (address charity);

    function setGovernanceCharity(address charity) external;

    function governanceVoter() external view returns (address voting);

    function setGovernanceVoter(address voting) external;

    function governanceTreasury() external view returns (address treasury);

    function setGovernanceTreasury(address treasury) external;

    function tokenRegistry() external view returns (address);

    function setTokenRegistry(address registry) external;
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