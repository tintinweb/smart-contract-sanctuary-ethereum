/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File contracts/interface/IStaking.sol


pragma solidity ^0.8.0;

interface IStaking {

    /**
     * @notice Transfers the `amount` of tokens from `msg.sender` address to the Staking contract address
     * @param amount the amount of tokens to stake
     */
    function stake(uint256 amount) external;

    /**
     * @notice Transfers the reward tokens if any to the `msg.sender` address
     */
    function claim() external;

    /**
     * @notice Transfers staked tokens if any to the `msg.sender` address
     */
    function unstake() external;

    /**
     * @notice Sets the reward percentage
     * @param _rewardPercentage is the reward percentage to be set
     */
    function setRewardPercentage(uint256 _rewardPercentage) external;

    /**
     * @notice Sets the reward period
     * @param _rewardPeriod is the reward period to be set
     */
    function setRewardPeriod(uint256 _rewardPeriod) external;

    /**
     * @notice Sets the stake withdrawal timeout
     * @param _stakeWithdrawalTimeout is the stake withdrawal timeout to be set
     */
    function setStakeWithdrawalTimeout(uint256 _stakeWithdrawalTimeout) external;

    /**
     * @notice The reward percentage
     */
    function rewardPercentage() external view returns (uint256);

    /**
     * @notice The reward period in seconds
     */
    function rewardPeriod() external view returns (uint256);

    /**
     * @notice The stake withdrawal timeout in seconds
     */
    function stakeWithdrawalTimeout() external view returns (uint256);

    /**
     * @notice Total value locked
     */
    function totalStake() external view returns (uint256);

    /**
     * @notice Returns the total amount of staked tokens for the `stakeholder`
     * @param stakeholder is the address of the stakeholder
     * @return the total amount of staked tokens for the `stakeholder`
     */
    function getStake(address stakeholder) external view returns (uint256);

    /**
     * @dev The reward token which is used to pay stakeholders
     */
    function rewardToken() external view returns (address);

    /**
     * @dev The staking token which is used by stakeholders to participate
     */
    function stakingToken() external view returns (address);

    /**
     * @dev The DAO which uses this contract to perform voting
     */
    function dao() external view returns (address);
}


// File contracts/interface/IDAO.sol


pragma solidity ^0.8.0;
interface IDAO {

    /**
     * @notice creates a new proposal
     */
    function addProposal(bytes memory data, address recipient, string memory _description) external;

    /**
     * @notice registers `msg.sender` vote
     */
    function vote(uint256 proposalId, bool votesFor) external;

    /**
     * @notice finishes the proposal with id `proposalId`
     */
    function finishProposal(uint256 proposalId) external;

    /**
     * @notice Transfers chairman grants to a `_chairman`
     */
    function changeChairman(address _chairman) external;

    /**
     * @notice Sets the minimum quorum
     */
    function setMinimumQuorum(uint256 _minimumQuorum) external;

    /**
     * @notice Sets the debating period duration
     */
    function setDebatingPeriodDuration(uint256 _debatingPeriodDuration) external;

    /**
     * @return A description of a proposal with the id `proposalId`
     */
    function description(uint256 proposalId) external view returns (string memory);

    /**
     * @return Whether a given EOA is participating in proposals
     */
    function isParticipant(address stakeholder) external view returns (bool);

    /**
     * @notice EOA responsible for proposals creation
     */
    function chairman() external view returns (address);

    /**
     * @notice The minimum amount of votes needed to consider a proposal to be successful. Quorum = (votes / staking total supply) * 100.
     */
    function minimumQuorum() external view returns (uint256);

    /**
     * @notice EOA responsible for proposals creation
     */
    function debatingPeriodDuration() external view returns (uint256);

    /**
     * @notice Staking contract
     */
    function staking() external view returns (IStaking);

    /**
     * @return true if DAO had been initialized
     */
    function isInitialized() external view returns(bool);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File contracts/DAO.sol


pragma solidity ^0.8.0;
contract DAO is IDAO, Ownable {
    using Counters for Counters.Counter;

    /**
     * @dev Represents a proposal
     */
    struct Proposal {
        bytes data;
        address recipient;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        address[] voters;
    }

    address public override chairman;

    uint256 public override minimumQuorum;

    uint256 public override debatingPeriodDuration;

    bool public override isInitialized;

    IStaking public override staking;

    /**
     * @dev Used to generate proposal ids
     */
    Counters.Counter private proposalIdGenerator;

    /**
     * @dev A mapping "proposalId => Proposal"
     */
    mapping(uint256 => Proposal) private proposals;

    /**
     * @dev That counter is used to determine whether a stakeholder is currently participating in proposals
     */
    mapping(address => uint256) private proposalCounters;

    /**
     * @dev Maps proposalId to proposal's voters
     */
    mapping(uint256 => mapping(address => bool)) private proposalsToVoters; //since the compiler does not allow us to assign structs with nested mappings :(

    /**
     * @dev Emitted when a proposal was successfully finished
     */
    event ProposalFinished(uint256 indexed proposalId, string description, bool approved);

    /**
     * @dev Emitted when a proposal was failed
     */
    event ProposalFailed(uint256 indexed proposalId, string description, string reason);

    /**
     * @dev Emitted when a proposal was created
     */
    event ProposalCreated(uint256 proposalId);

    modifier onlyChairman() {
        require(msg.sender == chairman, "Not a chairman");
        _;
    }

    modifier initialized() {
        require(isInitialized, "Not initialized");
        _;
    }

    constructor(address _chairman, uint256 _minimumQuorum, uint256 _debatingPeriodDuration) public {
        require(_minimumQuorum <= 100, "Minimum quorum can not be > 100");
        chairman = _chairman;
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    function init(address _staking) external onlyOwner {
        require(!isInitialized, "Already initialized");
        require(address(0) != _staking, "Address is zero");
        staking = IStaking(_staking);
        isInitialized = true;
    }

    function addProposal(bytes memory data, address recipient, string memory _description) public override onlyChairman initialized {
        uint32 codeSize;
        assembly {
            codeSize := extcodesize(recipient)
        }
        require(codeSize > 0, "Recipient is not a contract");

        uint256 nextProposalId = proposalIdGenerator.current();
        proposalIdGenerator.increment();

        Proposal storage newProposal = proposals[nextProposalId];
        newProposal.data = data;
        newProposal.recipient = recipient;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + debatingPeriodDuration;
        proposals[nextProposalId] = newProposal;
        proposalCounters[msg.sender] += 1;

        emit ProposalCreated(nextProposalId);
    }

    function vote(uint256 proposalId, bool votesFor) public override initialized {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.deadline != 0, "Proposal not found");
        require(proposal.deadline > block.timestamp, "Proposal is finished");
        require(!proposalsToVoters[proposalId][msg.sender], "Already voted");

        uint256 balance = staking.getStake(msg.sender);
        require(balance > 0, "Not a stakeholder");

        proposalsToVoters[proposalId][msg.sender] = true;
        proposalCounters[msg.sender] += 1;
        proposal.voters.push(msg.sender);

        if (votesFor) {
            proposal.votesFor += balance;
        } else {
            proposal.votesAgainst += balance;
        }
    }

    function finishProposal(uint256 proposalId) public override initialized {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.deadline != 0, "Proposal not found");
        require(block.timestamp >= proposal.deadline, "Proposal is still in progress");

        if (proposal.votesFor == 0 && proposal.votesAgainst == 0) {
            emit ProposalFailed(proposalId, proposal.description, "No votes for proposal");
        } else if ((proposal.votesFor + proposal.votesAgainst) * 100 / staking.totalStake() >= minimumQuorum) {
            if (proposal.votesFor > proposal.votesAgainst) {
                (bool success,) = proposal.recipient.call{value : 0}(proposal.data);

                if (success) {
                    emit ProposalFinished(proposalId, proposal.description, true);
                } else {
                    emit ProposalFailed(proposalId, proposal.description, "Function call failed");
                }
            } else {
                emit ProposalFinished(proposalId, proposal.description, false);
            }
        } else {
            emit ProposalFailed(proposalId, proposal.description, "Minimum quorum is not reached");
        }

        for (uint256 i = 0; i < proposal.voters.length; i++) {
            delete proposalsToVoters[proposalId][proposal.voters[i]];
            proposalCounters[proposal.voters[i]] -= 1;
        }
        delete proposals[proposalId];
    }

    function changeChairman(address _chairman) public override onlyChairman initialized {
        require(_chairman != address(0), "Should not be zero address");
        chairman = _chairman;
    }

    function setMinimumQuorum(uint256 _minimumQuorum) public override onlyOwner initialized {
        require(_minimumQuorum <= 100, "Minimum quorum can not be > 100");
        minimumQuorum = _minimumQuorum;
    }

    function setDebatingPeriodDuration(uint256 _debatingPeriodDuration) public override onlyOwner initialized {
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    function description(uint256 proposalId) public override view initialized returns (string memory) {
        require(proposals[proposalId].recipient != address(0), "Proposal not found");
        return proposals[proposalId].description;
    }

    function isParticipant(address stakeholder) public override view initialized returns (bool) {
        return proposalCounters[stakeholder] > 0;
    }
}