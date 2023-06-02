// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { Module } from "@gnosis.pm/zodiac/contracts/core/Module.sol";
import { IBaseStrategy } from "./interfaces/IBaseStrategy.sol";
import { IAzorius, Enum } from "./interfaces/IAzorius.sol";

/**
 * A Safe module which allows for composable governance.
 * Azorius conforms to the [Zodiac pattern](https://github.com/gnosis/zodiac) for Safe modules.
 *
 * The Azorius contract acts as a central manager of DAO Proposals, maintaining the specifications
 * of the transactions that comprise a Proposal, but notably not the state of voting.
 *
 * All voting details are delegated to [BaseStrategy](./BaseStrategy.md) implementations, of which an Azorius DAO can
 * have any number.
 */
contract Azorius is Module, IAzorius {

    /**
     * The sentinel node of the linked list of enabled [BaseStrategies](./BaseStrategy.md).
     *
     * See https://en.wikipedia.org/wiki/Sentinel_node.
     */
    address internal constant SENTINEL_STRATEGY = address(0x1);

    /**
     * ```
     * keccak256(
     *      "EIP712Domain(uint256 chainId,address verifyingContract)"
     * );
     * ```
     *
     * A unique hash intended to prevent signature collisions.
     *
     * See https://eips.ethereum.org/EIPS/eip-712.
     */
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    /**
     * ```
     * keccak256(
     *      "Transaction(address to,uint256 value,bytes data,uint8 operation,uint256 nonce)"
     * );
     * ```
     *
     * See https://eips.ethereum.org/EIPS/eip-712.
     */
    bytes32 public constant TRANSACTION_TYPEHASH =
        0x72e9670a7ee00f5fbf1049b8c38e3f22fab7e9b85029e85cf9412f17fdd5c2ad;

    /** Total number of submitted Proposals. */
    uint32 public totalProposalCount;

    /** Delay (in blocks) between when a Proposal is passed and when it can be executed. */
    uint32 public timelockPeriod;

    /** Time (in blocks) between when timelock ends and the Proposal expires. */
    uint32 public executionPeriod;

    /** Proposals by `proposalId`. */
    mapping(uint256 => Proposal) internal proposals;

    /** A linked list of enabled [BaseStrategies](./BaseStrategy.md). */
    mapping(address => address) internal strategies;

    event AzoriusSetUp(
        address indexed creator,
        address indexed owner,
        address indexed avatar,
        address target
    );
    event ProposalCreated(
        address strategy,
        uint256 proposalId,
        address proposer,
        Transaction[] transactions,
        string metadata
    );
    event ProposalExecuted(uint32 proposalId, bytes32[] txHashes);
    event EnabledStrategy(address strategy);
    event DisabledStrategy(address strategy);
    event TimelockPeriodUpdated(uint32 timelockPeriod);
    event ExecutionPeriodUpdated(uint32 executionPeriod);

    error InvalidStrategy();
    error StrategyEnabled();
    error StrategyDisabled();
    error InvalidProposal();
    error InvalidProposer();
    error ProposalNotExecutable();
    error InvalidTxHash();
    error TxFailed();
    error InvalidTxs();
    error InvalidArrayLengths();

    constructor() {
      _disableInitializers();
    }

    /**
     * Initial setup of the Azorius instance.
     *
     * @param initializeParams encoded initialization parameters: `address _owner`, 
     * `address _avatar`, `address _target`, `address[] memory _strategies`,
     * `uint256 _timelockPeriod`, `uint256 _executionPeriod`
     */
    function setUp(bytes memory initializeParams) public override initializer {
        (
            address _owner,
            address _avatar,
            address _target,                
            address[] memory _strategies,   // enabled BaseStrategies
            uint32 _timelockPeriod,        // initial timelockPeriod
            uint32 _executionPeriod        // initial executionPeriod
        ) = abi.decode(
                initializeParams,
                (address, address, address, address[], uint32, uint32)
            );
        __Ownable_init();
        avatar = _avatar;
        target = _target;
        _setUpStrategies(_strategies);
        transferOwnership(_owner);
        _updateTimelockPeriod(_timelockPeriod);
        _updateExecutionPeriod(_executionPeriod);

        emit AzoriusSetUp(msg.sender, _owner, _avatar, _target);
    }

    /** @inheritdoc IAzorius*/
    function updateTimelockPeriod(uint32 _timelockPeriod) external onlyOwner {
        _updateTimelockPeriod(_timelockPeriod);
    }

    /** @inheritdoc IAzorius*/
    function updateExecutionPeriod(uint32 _executionPeriod) external onlyOwner {
        _updateExecutionPeriod(_executionPeriod);
    }

    /** @inheritdoc IAzorius*/
    function submitProposal(
        address _strategy,
        bytes memory _data,
        Transaction[] calldata _transactions,
        string calldata _metadata
    ) external {
        if (!isStrategyEnabled(_strategy)) revert StrategyDisabled();
        if (!IBaseStrategy(_strategy).isProposer(msg.sender))
            revert InvalidProposer();

        bytes32[] memory txHashes = new bytes32[](_transactions.length);
        uint256 transactionsLength = _transactions.length;
        for (uint256 i; i < transactionsLength; ) {
            txHashes[i] = getTxHash(
                _transactions[i].to,
                _transactions[i].value,
                _transactions[i].data,
                _transactions[i].operation
            );
            unchecked {
                ++i;
            }
        }

        proposals[totalProposalCount].strategy = _strategy;
        proposals[totalProposalCount].txHashes = txHashes;
        proposals[totalProposalCount].timelockPeriod = timelockPeriod;
        proposals[totalProposalCount].executionPeriod = executionPeriod;

        // not all strategy contracts will necessarily use the txHashes and _data values
        // they are encoded to support any strategy contracts that may need them
        IBaseStrategy(_strategy).initializeProposal(
            abi.encode(totalProposalCount, txHashes, _data)
        );

        emit ProposalCreated(
            _strategy,
            totalProposalCount,
            msg.sender,
            _transactions,
            _metadata
        );

        totalProposalCount++;
    }

    /** @inheritdoc IAzorius*/
    function executeProposal(
        uint32 _proposalId,
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _data,
        Enum.Operation[] memory _operations
    ) external {
        if (_targets.length == 0) revert InvalidTxs();
        if (
            _targets.length != _values.length ||
            _targets.length != _data.length ||
            _targets.length != _operations.length
        ) revert InvalidArrayLengths();
        if (
            proposals[_proposalId].executionCounter + _targets.length >
            proposals[_proposalId].txHashes.length
        ) revert InvalidTxs();
        uint256 targetsLength = _targets.length;
        bytes32[] memory txHashes = new bytes32[](targetsLength);
        for (uint256 i; i < targetsLength; ) {
            txHashes[i] = _executeProposalTx(
                _proposalId,
                _targets[i],
                _values[i],
                _data[i],
                _operations[i]
            );
            unchecked {
                ++i;
            }
        }
        emit ProposalExecuted(_proposalId, txHashes);
    }

    /** @inheritdoc IAzorius*/
    function getStrategies(
        address _startAddress,
        uint256 _count
    ) external view returns (address[] memory _strategies, address _next) {
        // init array with max page size
        _strategies = new address[](_count);

        // populate return array
        uint256 strategyCount = 0;
        address currentStrategy = strategies[_startAddress];
        while (
            currentStrategy != address(0x0) &&
            currentStrategy != SENTINEL_STRATEGY &&
            strategyCount < _count
        ) {
            _strategies[strategyCount] = currentStrategy;
            currentStrategy = strategies[currentStrategy];
            strategyCount++;
        }
        _next = currentStrategy;
        // set correct size of returned array
        assembly {
            mstore(_strategies, strategyCount)
        }
    }

    /** @inheritdoc IAzorius*/
    function getProposalTxHash(uint32 _proposalId, uint32 _txIndex) external view returns (bytes32) {
        return proposals[_proposalId].txHashes[_txIndex];
    }

    /** @inheritdoc IAzorius*/
    function getProposalTxHashes(uint32 _proposalId) external view returns (bytes32[] memory) {
        return proposals[_proposalId].txHashes;
    }

    /** @inheritdoc IAzorius*/
    function getProposal(uint32 _proposalId) external view
        returns (
            address _strategy,
            bytes32[] memory _txHashes,
            uint32 _timelockPeriod,
            uint32 _executionPeriod,
            uint32 _executionCounter
        )
    {
        _strategy = proposals[_proposalId].strategy;
        _txHashes = proposals[_proposalId].txHashes;
        _timelockPeriod = proposals[_proposalId].timelockPeriod;
        _executionPeriod = proposals[_proposalId].executionPeriod;
        _executionCounter = proposals[_proposalId].executionCounter;
    }

    /** @inheritdoc IAzorius*/
    function enableStrategy(address _strategy) public override onlyOwner {
        if (_strategy == address(0) || _strategy == SENTINEL_STRATEGY)
            revert InvalidStrategy();
        if (strategies[_strategy] != address(0)) revert StrategyEnabled();

        strategies[_strategy] = strategies[SENTINEL_STRATEGY];
        strategies[SENTINEL_STRATEGY] = _strategy;

        emit EnabledStrategy(_strategy);
    }

    /** @inheritdoc IAzorius*/
    function disableStrategy(address _prevStrategy, address _strategy) public onlyOwner {
        if (_strategy == address(0) || _strategy == SENTINEL_STRATEGY)
            revert InvalidStrategy();
        if (strategies[_prevStrategy] != _strategy) revert StrategyDisabled();

        strategies[_prevStrategy] = strategies[_strategy];
        strategies[_strategy] = address(0);

        emit DisabledStrategy(_strategy);
    }

    /** @inheritdoc IAzorius*/
    function isStrategyEnabled(address _strategy) public view returns (bool) {
        return
            SENTINEL_STRATEGY != _strategy &&
            strategies[_strategy] != address(0);
    }

    /** @inheritdoc IAzorius*/
    function proposalState(uint32 _proposalId) public view returns (ProposalState) {
        Proposal memory _proposal = proposals[_proposalId];

        if (_proposal.strategy == address(0)) revert InvalidProposal();

        IBaseStrategy _strategy = IBaseStrategy(_proposal.strategy);

        uint256 votingEndBlock = _strategy.votingEndBlock(_proposalId);

        if (block.number <= votingEndBlock) {
            return ProposalState.ACTIVE;
        } else if (!_strategy.isPassed(_proposalId)) {
            return ProposalState.FAILED;
        } else if (_proposal.executionCounter == _proposal.txHashes.length) {
            // a Proposal with 0 transactions goes straight to EXECUTED
            // this allows for the potential for on-chain voting for 
            // "off-chain" executed decisions
            return ProposalState.EXECUTED;
        } else if (block.number <= votingEndBlock + _proposal.timelockPeriod) {
            return ProposalState.TIMELOCKED;
        } else if (
            block.number <=
            votingEndBlock +
                _proposal.timelockPeriod +
                _proposal.executionPeriod
        ) {
            return ProposalState.EXECUTABLE;
        } else {
            return ProposalState.EXPIRED;
        }
    }

    /** @inheritdoc IAzorius*/
    function generateTxHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) public view returns (bytes memory) {
        uint256 chainId = block.chainid;
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_SEPARATOR_TYPEHASH, chainId, this)
        );
        bytes32 transactionHash = keccak256(
            abi.encode(
                TRANSACTION_TYPEHASH,
                _to,
                _value,
                keccak256(_data),
                _operation,
                _nonce
            )
        );
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator,
                transactionHash
            );
    }

    /** @inheritdoc IAzorius*/
    function getTxHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) public view returns (bytes32) {
        return keccak256(generateTxHashData(_to, _value, _data, _operation, 0));
    }

    /**
     * Executes the specified transaction in a Proposal, by index.
     * Transactions in a Proposal must be called in order.
     *
     * @param _proposalId identifier of the proposal
     * @param _target contract to be called by the avatar
     * @param _value ETH value to pass with the call
     * @param _data data to be executed from the call
     * @param _operation Call or Delegatecall
     */
    function _executeProposalTx(
        uint32 _proposalId,
        address _target,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) internal returns (bytes32 txHash) {
        if (proposalState(_proposalId) != ProposalState.EXECUTABLE)
            revert ProposalNotExecutable();
        txHash = getTxHash(_target, _value, _data, _operation);
        if (
            proposals[_proposalId].txHashes[
                proposals[_proposalId].executionCounter
            ] != txHash
        ) revert InvalidTxHash();

        proposals[_proposalId].executionCounter++;
        
        if (!exec(_target, _value, _data, _operation)) revert TxFailed();
    }

    /**
     * Enables the specified array of [BaseStrategy](./BaseStrategy.md) contract addresses.
     *
     * @param _strategies array of `BaseStrategy` contract addresses to enable
     */
    function _setUpStrategies(address[] memory _strategies) internal {
        strategies[SENTINEL_STRATEGY] = SENTINEL_STRATEGY;
        uint256 strategiesLength = _strategies.length;
        for (uint256 i; i < strategiesLength; ) {
            enableStrategy(_strategies[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Updates the `timelockPeriod` for future Proposals.
     *
     * @param _timelockPeriod new timelock period (in blocks)
     */
    function _updateTimelockPeriod(uint32 _timelockPeriod) internal {
        timelockPeriod = _timelockPeriod;
        emit TimelockPeriodUpdated(_timelockPeriod);
    }

    /**
     * Updates the `executionPeriod` for future Proposals.
     *
     * @param _executionPeriod new execution period (in blocks)
     */
    function _updateExecutionPeriod(uint32 _executionPeriod) internal {
        executionPeriod = _executionPeriod;
        emit ExecutionPeriodUpdated(_executionPeriod);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Module Interface - A contract that can pass messages to a Module Manager contract if enabled by that contract.
pragma solidity >=0.7.0 <0.9.0;

import "../interfaces/IAvatar.sol";
import "../factory/FactoryFriendly.sol";
import "../guard/Guardable.sol";

abstract contract Module is FactoryFriendly, Guardable {
    /// @dev Address that will ultimately execute function calls.
    address public avatar;
    /// @dev Address that this module will pass transactions to.
    address public target;

    /// @dev Emitted each time the avatar is set.
    event AvatarSet(address indexed previousAvatar, address indexed newAvatar);
    /// @dev Emitted each time the Target is set.
    event TargetSet(address indexed previousTarget, address indexed newTarget);

    /// @dev Sets the avatar to a new avatar (`newAvatar`).
    /// @notice Can only be called by the current owner.
    function setAvatar(address _avatar) public onlyOwner {
        address previousAvatar = avatar;
        avatar = _avatar;
        emit AvatarSet(previousAvatar, _avatar);
    }

    /// @dev Sets the target to a new target (`newTarget`).
    /// @notice Can only be called by the current owner.
    function setTarget(address _target) public onlyOwner {
        address previousTarget = target;
        target = _target;
        emit TargetSet(previousTarget, _target);
    }

    /// @dev Passes a transaction to be executed by the avatar.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function exec(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success) {
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
        }
        success = IAvatar(target).execTransactionFromModule(
            to,
            value,
            data,
            operation
        );
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return success;
    }

    /// @dev Passes a transaction to be executed by the target and returns data.
    /// @notice Can only be called by this contract.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execAndReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool success, bytes memory returnData) {
        /// Check if a transactioon guard is enabled.
        if (guard != address(0)) {
            IGuard(guard).checkTransaction(
                /// Transaction info used by module transactions.
                to,
                value,
                data,
                operation,
                /// Zero out the redundant transaction information only used for Safe multisig transctions.
                0,
                0,
                0,
                address(0),
                payable(0),
                bytes("0x"),
                msg.sender
            );
        }
        (success, returnData) = IAvatar(target)
            .execTransactionFromModuleReturnData(to, value, data, operation);
        if (guard != address(0)) {
            IGuard(guard).checkAfterExecution(bytes32("0x"), success);
        }
        return (success, returnData);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

/**
 * The specification for a voting strategy in Azorius.
 *
 * Each IBaseStrategy implementation need only implement the given functions here,
 * which allows for highly composable but simple or complex voting strategies.
 *
 * It should be noted that while many voting strategies make use of parameters such as
 * voting period or quorum, that is a detail of the individual strategy itself, and not
 * a requirement for the Azorius protocol.
 */
interface IBaseStrategy {

    /**
     * Sets the address of the [Azorius](../Azorius.md) contract this 
     * [BaseStrategy](../BaseStrategy.md) is being used on.
     *
     * @param _azoriusModule address of the Azorius Safe module
     */
    function setAzorius(address _azoriusModule) external;

    /**
     * Called by the [Azorius](../Azorius.md) module. This notifies this 
     * [BaseStrategy](../BaseStrategy.md) that a new Proposal has been created.
     *
     * @param _data arbitrary data to pass to this BaseStrategy
     */
    function initializeProposal(bytes memory _data) external;

    /**
     * Returns whether a Proposal has been passed.
     *
     * @param _proposalId proposalId to check
     * @return bool true if the proposal has passed, otherwise false
     */
    function isPassed(uint32 _proposalId) external view returns (bool);

    /**
     * Returns whether the specified address can submit a Proposal with
     * this [BaseStrategy](../BaseStrategy.md).
     *
     * This allows a BaseStrategy to place any limits it would like on
     * who can create new Proposals, such as requiring a minimum token
     * delegation.
     *
     * @param _address address to check
     * @return bool true if the address can submit a Proposal, otherwise false
     */
    function isProposer(address _address) external view returns (bool);

    /**
     * Returns the block number voting ends on a given Proposal.
     *
     * @param _proposalId proposalId to check
     * @return uint32 block number when voting ends on the Proposal
     */
    function votingEndBlock(uint32 _proposalId) external view returns (uint32);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * The base interface for the Azorius governance Safe module.
 * Azorius conforms to the Zodiac pattern for Safe modules: https://github.com/gnosis/zodiac
 *
 * Azorius manages the state of Proposals submitted to a DAO, along with the associated strategies
 * ([BaseStrategy](../BaseStrategy.md)) for voting that are enabled on the DAO.
 *
 * Any given DAO can support multiple voting BaseStrategies, and these strategies are intended to be
 * as customizable as possible.
 *
 * Proposals begin in the `ACTIVE` state and will ultimately end in either
 * the `EXECUTED`, `EXPIRED`, or `FAILED` state.
 *
 * `ACTIVE` - a new proposal begins in this state, and stays in this state
 *          for the duration of its voting period.
 *
 * `TIMELOCKED` - A proposal that passes enters the `TIMELOCKED` state, during which
 *          it cannot yet be executed.  This is to allow time for token holders
 *          to potentially exit their position, as well as parent DAOs time to
 *          initiate a freeze, if they choose to do so. A proposal stays timelocked
 *          for the duration of its `timelockPeriod`.
 *
 * `EXECUTABLE` - Following the `TIMELOCKED` state, a passed proposal becomes `EXECUTABLE`,
 *          and can then finally be executed on chain by anyone.
 *
 * `EXECUTED` - the final state for a passed proposal.  The proposal has been executed
 *          on the blockchain.
 *
 * `EXPIRED` - a passed proposal which is not executed before its `executionPeriod` has
 *          elapsed will be `EXPIRED`, and can no longer be executed.
 *
 * `FAILED` - a failed proposal (as defined by its [BaseStrategy](../BaseStrategy.md) 
 *          `isPassed` function). For a basic strategy, this would mean it received more 
 *          NO votes than YES or did not achieve quorum. 
 */
interface IAzorius {

    /** Represents a transaction to perform on the blockchain. */
    struct Transaction {
        address to; // destination address of the transaction
        uint256 value; // amount of ETH to transfer with the transaction
        bytes data; // encoded function call data of the transaction
        Enum.Operation operation; // Operation type, Call or DelegateCall
    }

    /** Holds details pertaining to a single proposal. */
    struct Proposal {
        uint32 executionCounter; // count of transactions that have been executed within the proposal
        uint32 timelockPeriod; // time (in blocks) this proposal will be timelocked for if it passes
        uint32 executionPeriod; // time (in blocks) this proposal has to be executed after timelock ends before it is expired
        address strategy; // BaseStrategy contract this proposal was created on
        bytes32[] txHashes; // hashes of the transactions that are being proposed
    }

    /** The list of states in which a Proposal can be in at any given time. */
    enum ProposalState {
        ACTIVE,
        TIMELOCKED,
        EXECUTABLE,
        EXECUTED,
        EXPIRED,
        FAILED
    }

    /**
     * Enables a [BaseStrategy](../BaseStrategy.md) implementation for newly created Proposals.
     *
     * Multiple strategies can be enabled, and new Proposals will be able to be
     * created using any of the currently enabled strategies.
     *
     * @param _strategy contract address of the BaseStrategy to be enabled
     */
    function enableStrategy(address _strategy) external;

    /**
     * Disables a previously enabled [BaseStrategy](../BaseStrategy.md) implementation for new proposals.
     * This has no effect on existing Proposals, either `ACTIVE` or completed.
     *
     * @param _prevStrategy BaseStrategy address that pointed in the linked list to the strategy to be removed
     * @param _strategy address of the BaseStrategy to be removed
     */
    function disableStrategy(address _prevStrategy, address _strategy) external;

    /**
     * Updates the `timelockPeriod` for newly created Proposals.
     * This has no effect on existing Proposals, either `ACTIVE` or completed.
     *
     * @param _timelockPeriod timelockPeriod (in blocks) to be used for new Proposals
     */
    function updateTimelockPeriod(uint32 _timelockPeriod) external;

    /**
     * Updates the execution period for future Proposals.
     *
     * @param _executionPeriod new execution period (in blocks)
     */
    function updateExecutionPeriod(uint32 _executionPeriod) external;

    /**
     * Submits a new Proposal, using one of the enabled [BaseStrategies](../BaseStrategy.md).
     * New Proposals begin immediately in the `ACTIVE` state.
     *
     * @param _strategy address of the BaseStrategy implementation which the Proposal will use
     * @param _data arbitrary data passed to the BaseStrategy implementation. This may not be used by all strategies, 
     * but is included in case future strategy contracts have a need for it
     * @param _transactions array of transactions to propose
     * @param _metadata additional data such as a title/description to submit with the proposal
     */
    function submitProposal(
        address _strategy,
        bytes memory _data,
        Transaction[] calldata _transactions,
        string calldata _metadata
    ) external;

    /**
     * Executes all transactions within a Proposal.
     * This will only be able to be called if the Proposal passed.
     *
     * @param _proposalId identifier of the Proposal
     * @param _targets target contracts for each transaction
     * @param _values ETH values to be sent with each transaction
     * @param _data transaction data to be executed
     * @param _operations Calls or Delegatecalls
     */
    function executeProposal(
        uint32 _proposalId,
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _data,
        Enum.Operation[] memory _operations
    ) external;

    /**
     * Returns whether a [BaseStrategy](../BaseStrategy.md) implementation is enabled.
     *
     * @param _strategy contract address of the BaseStrategy to check
     * @return bool True if the strategy is enabled, otherwise False
     */
    function isStrategyEnabled(address _strategy) external view returns (bool);

    /**
     * Returns an array of enabled [BaseStrategy](../BaseStrategy.md) contract addresses.
     * Because the list of BaseStrategies is technically unbounded, this
     * requires the address of the first strategy you would like, along
     * with the total count of strategies to return, rather than
     * returning the whole list at once.
     *
     * @param _startAddress contract address of the BaseStrategy to start with
     * @param _count maximum number of BaseStrategies that should be returned
     * @return _strategies array of BaseStrategies
     * @return _next next BaseStrategy contract address in the linked list
     */
    function getStrategies(
        address _startAddress,
        uint256 _count
    ) external view returns (address[] memory _strategies, address _next);

    /**
     * Gets the state of a Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @return ProposalState uint256 ProposalState enum value representing the
     *         current state of the proposal
     */
    function proposalState(uint32 _proposalId) external view returns (ProposalState);

    /**
     * Generates the data for the module transaction hash (required for signing).
     *
     * @param _to target address of the transaction
     * @param _value ETH value to send with the transaction
     * @param _data encoded function call data of the transaction
     * @param _operation Enum.Operation to use for the transaction
     * @param _nonce Safe nonce of the transaction
     * @return bytes hashed transaction data
     */
    function generateTxHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) external view returns (bytes memory);

    /**
     * Returns the `keccak256` hash of the specified transaction.
     *
     * @param _to target address of the transaction
     * @param _value ETH value to send with the transaction
     * @param _data encoded function call data of the transaction
     * @param _operation Enum.Operation to use for the transaction
     * @return bytes32 transaction hash
     */
    function getTxHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) external view returns (bytes32);

    /**
     * Returns the hash of a transaction in a Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @param _txIndex index of the transaction within the Proposal
     * @return bytes32 hash of the specified transaction
     */
    function getProposalTxHash(uint32 _proposalId, uint32 _txIndex) external view returns (bytes32);

    /**
     * Returns the transaction hashes associated with a given `proposalId`.
     *
     * @param _proposalId identifier of the Proposal to get transaction hashes for
     * @return bytes32[] array of transaction hashes
     */
    function getProposalTxHashes(uint32 _proposalId) external view returns (bytes32[] memory);

    /**
     * Returns details about the specified Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @return _strategy address of the BaseStrategy contract the Proposal is on
     * @return _txHashes hashes of the transactions the Proposal contains
     * @return _timelockPeriod time (in blocks) the Proposal is timelocked for
     * @return _executionPeriod time (in blocks) the Proposal must be executed within, after timelock ends
     * @return _executionCounter counter of how many of the Proposals transactions have been executed
     */
    function getProposal(uint32 _proposalId) external view
        returns (
            address _strategy,
            bytes32[] memory _txHashes,
            uint32 _timelockPeriod,
            uint32 _executionPeriod,
            uint32 _executionCounter
        );
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IAvatar {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./BaseGuard.sol";

/// @title Guardable - A contract that manages fallback calls made to this contract
contract Guardable is OwnableUpgradeable {
    address public guard;

    event ChangedGuard(address guard);

    /// `guard_` does not implement IERC165.
    error NotIERC165Compliant(address guard_);

    /// @dev Set a guard that checks transactions before execution.
    /// @param _guard The address of the guard to be used or the 0 address to disable the guard.
    function setGuard(address _guard) external onlyOwner {
        if (_guard != address(0)) {
            if (!BaseGuard(_guard).supportsInterface(type(IGuard).interfaceId))
                revert NotIERC165Compliant(_guard);
        }
        guard = _guard;
        emit ChangedGuard(guard);
    }

    function getGuard() external view returns (address _guard) {
        return guard;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../interfaces/IGuard.sol";

abstract contract BaseGuard is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IGuard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }

    /// @dev Module transactions only use the first four parameters: to, value, data, and operation.
    /// Module.sol hardcodes the remaining parameters as 0 since they are not used for module transactions.
    /// @notice This interface is used to maintain compatibilty with Gnosis Safe transaction guards.
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external virtual;

    function checkAfterExecution(bytes32 txHash, bool success) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IGuard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}