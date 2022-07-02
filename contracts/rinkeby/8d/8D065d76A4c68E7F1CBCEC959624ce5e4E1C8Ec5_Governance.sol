// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IGovernance.sol";
import "./interfaces/IVotingWeightSource.sol";
import "./Transactor.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./libraries/Math.sol";

/**
 * @title Kapital DAO Governance
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice Governance contract for proposal creation, voting, and execution.
 */
contract Governance is IGovernance, Transactor {
    // Gas savings: one slot
    /// @dev Tracks the most recent proposal
    uint96 public latestProposalID;
    /// @dev Min duration required between proposals for each address, inactive at 0 and can be activated with DAO vote
    uint24 public proposeCooldown;
    /// @dev Min voting weight to propose
    uint96 public threshold;
    /// @dev For interacting with Uniswap
    bool public immutable kapIsToken0;

    /// @dev Stores all proposals
    mapping(uint256 => Proposal) public proposals;
    /// @dev Track each address' latest proposal timestamp
    mapping(address => uint256) public latestPropose;

    // Gas savings: one slot
    /// @dev Duration between proposition and start of voting
    uint24 public waitToStartVote;
    /// @dev Duration between proposition and end of voting
    uint24 public waitToEndVote;
    /// @dev Total votes required to pass
    uint96 public quorum;
    /// @dev Duration between proposition and start of execution
    uint24 public waitToExecute;
    /// @dev Execution window, Duration between proposition and expiration
    uint24 public waitToExpire;

    IUniswapV2Pair public immutable pair;

    /// @dev Team multisig can veto malicious proposals
    address immutable public teamMultisig;
    /**
     * @dev Allow team multisig to renounce vetoer role. Contract too big to
     * deploy with OpenZeppelin AccessControl.
     */
    bool public teamMultisigIsVetoer = true;

    /// @dev Holds the contract addresses that can contribute to KAP voting weight
    address[] public weightSourcesKAP;
    /// @dev Holds the contract addresses that can contribute to LP voting weight
    address[] public weightSourcesLP;

    constructor(
        uint96 _quorum,
        uint96 _threshold,
        WaitTo memory _waitTo,
        PoolParams memory _poolParams,
        address _teamMultisig,
        address[] memory _weightSourcesKAP,
        address[] memory _weightSourcesLP
    ) {
        require(_quorum > 0, "Invalid parameter");
        require(_threshold > 0, "Invalid parameter");
        require(_waitTo.startVote > 0, "Invalid parameter");
        require(_waitTo.endVote > _waitTo.startVote, "Invalid parameter");
        require(_waitTo.execute > _waitTo.endVote, "Invalid parameter");
        require(_waitTo.expire > _waitTo.execute, "Invalid parameter");
        require(_poolParams.kapToken != address(0), "Zero address");
        require(_poolParams.otherToken != address(0), "Zero address");
        require(_poolParams.poolAddress != address(0), "Zero address");
        require(_teamMultisig != address(0), "Zero address");
        require(_weightSourcesKAP.length > 0, "No KAP sources");
        require(_weightSourcesLP.length > 0, "No LP sources");

        // implicitly set propseCooldown to be the voting period
        proposeCooldown = _waitTo.endVote - _waitTo.startVote;
        quorum = _quorum;
        threshold = _threshold;
        waitToStartVote = _waitTo.startVote;
        waitToEndVote = _waitTo.endVote;
        waitToExecute = _waitTo.execute;
        waitToExpire = _waitTo.expire;

        pair = IUniswapV2Pair(_poolParams.poolAddress);

        teamMultisig = _teamMultisig;

        weightSourcesKAP = _weightSourcesKAP;
        weightSourcesLP = _weightSourcesLP;

        // Compare KAP address with other token address to determine Uniswap token ordering
        kapIsToken0 = _poolParams.kapToken < _poolParams.otherToken;
    }

    /**
     * @notice Calculates the total KAP and LP voting weights of msg.sender
     * @param weightSources a struct that holds the voting weight sources selections
     * @return weightKAP and weightLP are the voting weights in KAP and LP tokens respectively
     */
    function getWeights(WeightSources memory weightSources)
        public
        view
        returns (uint256 weightKAP, uint256 weightLP)
    {
        // Calc KAP voting weight
        uint256 kapLength = weightSources.kapSourceIDs.length;
        for (uint256 i = 0; i < kapLength; ++i) {
            weightKAP += IKAPSource(weightSourcesKAP[weightSources.kapSourceIDs[i]]).weightKAP(
                msg.sender
            );
        }
        // Calc LP voting weight
        uint256 lpLength = weightSources.lpSourceIDs.length;
        for (uint256 i = 0; i < lpLength; ++i) {
            weightLP += ILPSource(weightSourcesLP[weightSources.lpSourceIDs[i]]).weightLP(msg.sender);
        }
    }

    /**
     * @dev Save hashed transaction parameters for gas efficiency
     * @param targets addresses to call
     * @param values values of the associated function calls
     * @param data calldata to pass into function calls
     * @return keccak256 hash of transaction parameters
     */
    function getTransactParamsHash(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encode(targets, values, data))
            );
    }

    /**
     * @notice Verifies msg.sender and creates a proposal
     * @param targets addresses to call
     * @param values values of the associated function calls
     * @param data calldata to pass into function calls
     * @param description string that describes the proposal for event purposes
     * @param weightSources a struct that holds the voting weight sources selections
     * @return proposalID
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data,
        string memory description,
        WeightSources memory weightSources
    ) external returns (uint256) {
        // Ensure msg.sender has enough voting weight
        (uint256 weightKAP, uint256 weightLP) = getWeights(weightSources);
        require(
            weightKAP + convertLP(weightLP) >= threshold,
            "Governance: Insufficient weight"
        );
        // Make sure haven't already created a proposal within cooldown period, Propose CoolDown
        uint256 timestamp = block.timestamp;
        require(
            timestamp >= latestPropose[msg.sender] + proposeCooldown,
            "Governance: Propose Cooldown"
        );
        // Logic check on proposal data
        uint256 targetsLength = targets.length;
        require(targetsLength > 0, "Governance: Invalid data");
        require(targetsLength == values.length, "Governance: Invalid data");
        require(targetsLength == data.length, "Governance: Invalid data");
        require(!(bytes(description).length == 0), "Governance: No description");

        // Add new proposal
        latestProposalID++;
        Proposal storage proposal = proposals[latestProposalID];
        proposal.transactParamsHash = getTransactParamsHash(
            targets,
            values,
            data
        );
        proposal.proposeTime = SafeCast.toUint64(timestamp);
        proposal.priceCumulativeLast = _cumulative();

        // Update msg.sender's latestProposal
        latestPropose[msg.sender] = timestamp;

        emit ProposalCreated(
            msg.sender, 
            latestProposalID, 
            timestamp,
            targets,
            values,
            data,
            description);
        return latestProposalID;
    }

    /**
     * @notice Checks to see if the current timestamp is within the proposal's voting window
     * @param proposal the proposal to check the voting window
     * @return true: within voting window, false outside of voting window
     */
    function _checkVoteWindow(Proposal storage proposal)
        internal
        view
        returns (bool)
    {
        uint256 timeElapsed = block.timestamp - proposal.proposeTime;
        return waitToStartVote < timeElapsed && timeElapsed < waitToEndVote;
    }

    /**
     * @notice Cast vote on specified proposal for provided addresses
     * @param proposalID index of the proposal to vote on
     * @param yay true if voting yay, false if voting nay
     * @param weightSources a struct that holds the voting weight sources selections
     */
    function vote(
        uint256 proposalID,
        bool yay,
        WeightSources memory weightSources
    ) external {
        require(proposalID <= latestProposalID, "Invalid proposal");

        Proposal storage proposal = proposals[proposalID];

        // Make sure the proposal has not been vetoed
        require(
            !proposal.vetoed,
            "Governance: Vetoed"
        );

        // Enforce voting window, Voting Window
        require(_checkVoteWindow(proposal), "Governance: Voting window");

        // Mark msg.sender as having voted, Already Voted
        require(!proposal.hasVoted[msg.sender], "Governance: Already voted");
        proposal.hasVoted[msg.sender] = true;

        (uint256 weightKAP, uint256 weightLP) = getWeights(weightSources);

        require(weightKAP > 0 || weightLP > 0, "Governance: Zero weight");

        // Add to vote counts
        require(weightLP <= type(uint112).max, "Governance: uint112(weightLP)");
        if (yay) {
            proposal.yaysKAP += SafeCast.toUint96(weightKAP);
            proposal.yaysLP += uint112(weightLP);
        } else {
            proposal.naysKAP += SafeCast.toUint96(weightKAP);
            proposal.naysLP += uint112(weightLP);
        }

        emit Voted(msg.sender, proposalID, yay, weightKAP, weightLP);
    }

    /**
     * @notice Checks to see if the current timestamp is within the proposal's execute window
     * @param proposal the proposal to check the execution window
     * @return true: within execute window, false outside of execute window
     */
    function _checkExecuteWindow(Proposal storage proposal)
        internal
        view
        returns (bool)
    {
        uint256 timeElapsed = block.timestamp - proposal.proposeTime;
        return waitToExecute < timeElapsed && timeElapsed < waitToExpire;
    }

    /**
     * @notice Compares the total votes for the specified proposal to the quorum
     * @param proposal the proposal to count
     * @return true: yays + nays >= quorum, false: nays + yays < quorum
     */
    function _checkQuorum(
        Proposal storage proposal,
        uint256 yaysLPConverted,
        uint256 naysLPConverted
    ) internal view returns (bool) {
        return
            proposal.yaysKAP +
                yaysLPConverted +
                proposal.naysKAP +
                naysLPConverted >=
            quorum;
    }

    /**
     * @notice Counts the total votes for the specified proposal
     * @param proposal the proposal to count
     * @return true: yays > nays, false: nays > yays
     */
    function _checkVoteCount(
        Proposal storage proposal,
        uint256 yaysLPConverted,
        uint256 naysLPConverted
    ) internal view returns (bool) {
        return
            proposal.yaysKAP + yaysLPConverted >
            proposal.naysKAP + naysLPConverted;
    }

    /**
     * @notice Checks requirements and if all are met, executes proposal
     * @param proposalID index of the proposal to execute
     */
    function execute(
        uint256 proposalID,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data
    ) external payable {
        require(proposalID <= latestProposalID, "Invalid proposal");

        Proposal storage proposal = proposals[proposalID];
        (
            uint256 yaysLPConverted,
            uint256 naysLPConverted
        ) = _convertLPCumulative(proposal);
        uint256 transactParamsHash = getTransactParamsHash(
            targets,
            values,
            data
        );
        // Make sure the proposal has not been vetoed
        require(
            !proposal.vetoed,
            "Governance: Vetoed"
        );
        // Make sure the specified transact params match the proposal
        require(
            transactParamsHash == proposal.transactParamsHash,
            "Governance: Transact params"
        );
        // Make sure execute window is active, Execute Window
        require(_checkExecuteWindow(proposal), "Governance: Execution window");
        // Make sure quorum is met, Quorum Not Met
        require(
            _checkQuorum(proposal, yaysLPConverted, naysLPConverted),
            "Governance: Quorum"
        );
        // Make sure votes are enough, Vote Count Failed
        require(
            _checkVoteCount(proposal, yaysLPConverted, naysLPConverted),
            "Governance: Vote count"
        );
        // Make sure proposal hasn't already been executed, Already Executed
        require(!proposal.executed, "Governance: Already executed");

        proposal.executed = true;

        // This contract is a {Transactor}
        _transact(targets, values, data);

        emit ProposalExecuted(msg.sender, proposalID, block.timestamp);
    }

    /**
     * @notice Coverts LP token count into KAP by referencing Uniswap state
     * @param weightLP LP token count to convert to KAP
     * @return weightKAP the converted KAP token amount
     */
    function convertLP(uint256 weightLP) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        uint112 reserveKAP = kapIsToken0 ? reserve0 : reserve1;
        return (weightLP * reserveKAP) / pair.totalSupply();
    }

    /**
     * @notice Coverts LP token count into KAP by referencing Uniswap state and TWAP
     * @param proposal proposal to reference for TWAP
     * @return yaysLPConverted and naysLPConverted the converted KAP token amounts
     */
    function _convertLPCumulative(Proposal storage proposal)
        internal
        view
        returns (uint256 yaysLPConverted, uint256 naysLPConverted)
    {
        uint256 totalLP = pair.totalSupply();
        uint256 k = pair.kLast(); // Retrieve latest k value
        uint256 priceETHCumulative = (_cumulative() - proposal.priceCumulativeLast);
        uint256 reserveKAP = Math.sqrt(
            k * priceETHCumulative / (block.timestamp - proposal.proposeTime)
        );

        return (
            (proposal.yaysLP * reserveKAP) / totalLP,
            (proposal.naysLP * reserveKAP) / totalLP
        );
    }

    /**
     * @notice Calculates priceCumulative for current blockTimestamp
     * @return priceCumulative the calculated UniswapV2 cumulative price for current block.timestamp
     */
    function _cumulative() internal view returns (uint256 priceCumulative) {
        // Convert to uint32
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        priceCumulative = kapIsToken0
            ? pair.price1CumulativeLast()
            : pair.price0CumulativeLast();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed;
            unchecked {
                timeElapsed = blockTimestamp - blockTimestampLast;
            }
            // addition overflow is desired, counterfactual
            unchecked {
                priceCumulative += kapIsToken0
                    ? (reserve0 * timeElapsed) / reserve1
                    : (reserve1 * timeElapsed) / reserve0;
            }
        }
    }

    /**
     * @dev Used by team multisig to veto malicious proposals.
     * There is no option to un-veto.
     * @param proposalID Key of relevant proposal in {proposals}
     */
    function veto(uint256 proposalID) external {
        require(
            (msg.sender == teamMultisig) && teamMultisigIsVetoer,
            "Access denied"
        );
        Proposal storage proposal = proposals[proposalID];
        require(!proposal.vetoed, "Already vetoed");
        require(proposalID <= latestProposalID, "Invalid proposal");
        require(!proposal.executed, "Proposal already executed");
        proposal.vetoed = true;

        emit Veto(proposalID);
    }

    /**
     * @dev Used by team multisig to renounce its vetoer role, once the
     * governance turns over from the team to the community. The decision
     * to renounce veto power is final, and cannot be reversed.
     */
    function renounceTeamMultisigVetoerRole() external {
        require(
            msg.sender == teamMultisig,
            "Access denied"
        );
        require(
            teamMultisigIsVetoer,
            "Already renounced"
        );
        teamMultisigIsVetoer = false;
    }

    /**
     * @dev Used by staking contracts when reporting voting weight
     * @return the governance voting period
     */
    function votingPeriod() external view returns (uint256) {
        return waitToEndVote - waitToStartVote;
    }

    /**
     * @notice Below are getters used by the front-end
     */

    /// @notice Calls the internal function
    function convertLPCumulative(uint256 proposalID)
        external
        view
        returns (uint256 yaysLPConverted, uint256 naysLPConverted)
    {
        return _convertLPCumulative(proposals[proposalID]);
    }

    /// @notice Calls the internal function
    function checkVoteWindow(uint256 proposalID) external view returns (bool) {
        return _checkVoteWindow(proposals[proposalID]);
    }

    /// @notice Calls the internal function
    function checkExecuteWindow(uint256 proposalID)
        external
        view
        returns (bool)
    {
        return _checkExecuteWindow(proposals[proposalID]);
    }

    /// @notice Calls the internal function
    function checkQuorum(uint256 proposalID) external view returns (bool) {
        Proposal storage proposal = proposals[proposalID];
        (
            uint256 yaysLPConverted,
            uint256 naysLPConverted
        ) = _convertLPCumulative(proposal);
        return _checkQuorum(proposal, yaysLPConverted, naysLPConverted);
    }

    /// @notice Calls the internal function
    function checkVoteCount(uint256 proposalID) external view returns (bool) {
        Proposal storage proposal = proposals[proposalID];
        (
            uint256 yaysLPConverted,
            uint256 naysLPConverted
        ) = _convertLPCumulative(proposal);
        return _checkVoteCount(proposal, yaysLPConverted, naysLPConverted);
    }

    /// @notice Returns whether or not the voter has already voted for the specified proposal
    function checkHasVoted(uint256 proposalID, address voter)
        external
        view
        returns (bool)
    {
        return proposals[proposalID].hasVoted[voter];
    }

    /// @dev Can only be called by itself to update {proposeCooldown} value.
    function setProposeCooldown(uint24 newProposeCooldown) external onlySelf {
        require(newProposeCooldown > 0 && proposeCooldown != newProposeCooldown, "Governance: Invalid cooldown");
        proposeCooldown = newProposeCooldown;
    }

    /// @dev Can only be called by itself to update {threshold} value.
    function setThreshold(uint96 newThreshold) external onlySelf {
        require(newThreshold > 0 && threshold != newThreshold, "Governance: Invalid threshold");
        threshold = newThreshold;
    }

    /// @dev Can only be called by itself to update {quorum} value.
    function setQuorum(uint96 newQuorum) external onlySelf {
        require(newQuorum > 0 && quorum != newQuorum, "Governance: Invalid quorum");
        quorum = newQuorum;
    }

    /// @dev Can only be called by itself to update {waitToStartVote} value.
    function setWaitToStartVote(uint24 newWaitToStartVote) external onlySelf {
        require(newWaitToStartVote > 0 && newWaitToStartVote < waitToEndVote && newWaitToStartVote != waitToStartVote, "Governance: Invalid voting wnd");
        waitToStartVote = newWaitToStartVote;
    }

    /// @dev Can only be called by itself to update {waitToEndVote} value.
    function setWaitToEndVote(uint24 newWaitToEndVote) external onlySelf {
        require(newWaitToEndVote > waitToStartVote && newWaitToEndVote < waitToExecute && newWaitToEndVote != waitToEndVote, "Governance: Invalid voting wnd");

        waitToEndVote = newWaitToEndVote;
    }

    /// @dev Can only be called by itself to update {waitToExecute} value.
    function setWaitToExecute(uint24 newWaitToExecute) external onlySelf {
        require(newWaitToExecute > waitToEndVote && newWaitToExecute < waitToExpire && newWaitToExecute != waitToExecute, "Governance: Invalid execute wnd");

        waitToExecute = newWaitToExecute;
    }

    /// @dev Can only be called by itself to update {waitToExpire} value.
    function setWaitToExpire(uint24 newWaitToExpire) external onlySelf {
        require(newWaitToExpire > waitToExecute && newWaitToExpire != waitToExpire, "Governance: Invalid execute wnd");

        waitToExpire = newWaitToExpire;
    }

    /// @dev Can only be called by itself to update {weightSourcesKAP} value.
    function setWeightSourcesKAP(address[] memory newWeightSourcesKAP) external onlySelf {
        require(newWeightSourcesKAP.length > 0, "Governance: Invalid KAP sources");
        weightSourcesKAP = newWeightSourcesKAP;
    }

    /// @dev Can only be called by itself to update {weightSourcesLP} value.
    /// @notice {weightSourcesLP} can be zero length when LP voting is disabled.
    function setWeightSourcesLP(address[] memory newWeightSourcesLP) external onlySelf {
        weightSourcesLP = newWeightSourcesLP;
    }

    /**
     *  @dev Used in the setter functions, to restrict that being called only from the Governance itself.
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "Governance: Only itself");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for Governance
 * @author Playground Labs
 */
interface IGovernance {
    function votingPeriod() external view returns (uint256);

    struct Proposal {
        // hash of data required for the _transact function
        uint256 transactParamsHash;
        uint64 proposeTime;
        // Counters for the for/against votes. These votes will be used to determine if proposal passes.
        uint96 yaysKAP;
        uint96 naysKAP;
        uint112 yaysLP;
        uint112 naysLP;
        // Record if proposal has been executed
        bool executed;
        // Team multisig can veto malicious proposals
        bool vetoed;
        // Record values for TWAP
        uint256 priceCumulativeLast;
        // Mapping to keep track of who's voted
        mapping(address => bool) hasVoted;
    }

    struct WaitTo {
        uint24 startVote;
        uint24 endVote;
        uint24 execute;
        uint24 expire;
    }

    struct PoolParams {
        address kapToken;
        address otherToken;
        address poolAddress;
    }

    struct WeightSources {
        // indices of weightSourcesKAP for pulling voting weight
        uint256[] kapSourceIDs;
        // indices of weightSourcesLP for pulling voting weight
        uint256[] lpSourceIDs;
    }

    event Veto(
        uint256 indexed proposalId
    );
    event ProposalCreated(
        address indexed sender,
        uint256 indexed proposalID,
        uint256 proposeTime,
        address[] targets,
        uint256[] values,
        bytes[] data,
        string description
    );
    event Voted(
        address indexed voter,
        uint256 indexed proposalID,
        bool yay,
        uint256 weightKAP,
        uint256 weightLP
    );
    event ProposalExecuted(
        address indexed sender,
        uint256 indexed proposalID,
        uint256 time
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interfaces for reporting Voting Weights
 * @author Playground Labs
 */

/// @notice Reports the KAP voting weight of the voter
interface IKAPSource {
    function weightKAP(address voter) external view returns (uint256);
}

/// @notice Reports the LP voting weight of the voter
interface ILPSource {
    function weightLP(address voter) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Kapital DAO Transactor
 * @author Playground Labs
 * @custom:security-contact [email protected]
 * @notice A base contract for storing and performing arbitrary actions with
 * funds owned by either the Kapital DAO governance or the Kaptial DAO core
 * team multisig. {_transact} is used by creating an external `transact` in
 * implementation contracts, together with appropriate access control.
 */
contract Transactor {
    /**
     * @dev Used to perform arbitrary actions with funds held by the contract
     * @param targets addresses to call
     * @param values values of the associated function calls
     * @param data calldata to pass into function calls
     */
    function _transact(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data
    ) internal {
        uint256 targetsLength = targets.length;
        require(targetsLength > 0, "Invalid array length");
        require(targetsLength == values.length, "Array length mismatch");
        require(targetsLength == data.length, "Array length mismatch");

        for (uint256 i = 0; i < targetsLength; ++i) {
            if (data[i].length != 0) {
                Address.functionCallWithValue(targets[i], data[i], values[i]);
            } else {
                /// @dev Can be used to send ETH to EOA
                Address.sendValue(payable(targets[i]), values[i]);
            }
        }
    }

    /**
     * @dev allow the contract to receive ether (as one of the many possible
     * types of tokens which can be held by the contract)
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Math {
    /**
     * @dev from @uniswap/v2-core/contracts/libraries/Math.sol.
     * Copied here to avoid solidity-compiler version errors.
     * babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     * 
     * Copied from OpenZeppelin Math.sol
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Because {SafeCast} does not support {uint112}
     * @param value Value to be safely converted to {uint112}
     * @return {uint112} representation of `value`, if `value` is small enough
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: Overflow 112 bits");
        return uint112(value);
    }
}