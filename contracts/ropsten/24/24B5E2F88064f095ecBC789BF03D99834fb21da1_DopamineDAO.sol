// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import '../interfaces/IDopamineDAO.sol';
import '../errors.sol';
import './DopamineDAOStorage.sol';

////////////////////////////////////////////////////////////////////////////////
///                              Custom Errors                               ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine DAO Implementation Contract
/// @notice Compound Governor Bravo fork built for DθPΛM1NΞ NFTs.
contract DopamineDAO is UUPSUpgradeable, DopamineDAOStorageV1, IDopamineDAO {

	////////////////////////////////////////////////////////////////////////////
	///						  Governance Constants                           ///
	////////////////////////////////////////////////////////////////////////////

    /// @notice Min number & max % of NFTs required for making a proposal.
	uint32 public constant MIN_PROPOSAL_THRESHOLD = 1; // 1 NFT
	uint32 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 10%

    /// @notice Min & max time for which proposal votes are valid, in blocks.
	uint32 public constant MIN_VOTING_PERIOD = 6400; // ~1 day
	uint32 public constant MAX_VOTING_PERIOD = 134000; // ~3 Weeks

    /// @notice Min & max wait time before proposal voting opens, in blocks.
	uint32 public constant MIN_VOTING_DELAY = 1; // Next block
	uint32 public constant MAX_VOTING_DELAY = 45000; // ~1 Week

    /// @notice Min & max quorum thresholds, in bips.
	uint32 public constant MIN_QUORUM_THRESHOLD_BPS = 200; // 2%
	uint32 public constant MAX_QUORUM_THRESHOLD_BPS = 2_000; // 20%

    /// @notice Max # of allowed operations for a single proposal.
	uint256 public constant PROPOSAL_MAX_OPERATIONS = 10;
	
	////////////////////////////////////////////////////////////////////////////
    ///                       Miscellaneous Constants                        ///
	////////////////////////////////////////////////////////////////////////////

	bytes32 public constant VOTE_TYPEHASH = keccak256("Vote(address voter,uint256 proposalId,uint8 support)");

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _RARITY_SOCIETY_DAO_INTERFACE_ID = 0x8a5da15c;

    /// @notice EIP-712 immutables for signing messages.
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /// @notice Modifier to restrict calls to admin only.
	modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
		_;
	}

    /// @notice Creates the DAO contract without any storage slots filled.
    /// @param proxy Address of the proxy, for EIP-712 signing verification.
    /// @dev Chain ID and domain separator are assigned here as immutables.
    constructor(
        address proxy
    ) {
        // Prevent implementation re-initialization.
        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
				keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
				keccak256(bytes("Dopamine DAO")),
                keccak256(bytes("1")),
                block.chainid,
                proxy
            )
        );
    }

    /// @notice Initializes the Dopamine DAO governance contract.
    /// @param timelock_ Timelock address, which controls proposal execution.
    /// @param token_ Governance token, from which voting weights are derived.
    /// @param vetoer_ Address with temporary veto power (revoked later on).
    /// @param votingPeriod_ Time a proposal is up for voting, in blocks.
    /// @param votingDelay_ Time before opening proposal for voting, in blocks.
    /// @param proposalThreshold_ Number of NFTs required to submit a proposal.
    /// @param quorumThresholdBPS_ Threshold required for proposal to pass, in bips.
	function initialize(
		address timelock_,
		address token_,
		address vetoer_,
		uint32 votingPeriod_,
		uint32 votingDelay_,
		uint32 proposalThreshold_,
        uint32 quorumThresholdBPS_
    ) onlyProxy public {
        if (address(token) != address(0)) {
            revert AlreadyInitialized();
        }

        admin = msg.sender;
		vetoer = vetoer_;
        token = IDopamineDAOToken(token_);
		timelock = ITimelock(timelock_);

        setVotingPeriod(votingPeriod_);
		setVotingDelay(votingDelay_);
		setQuorumThresholdBPS(quorumThresholdBPS_);
		setProposalThreshold(proposalThreshold_);
	}

    /// @notice Create a new proposal.
    /// @dev Proposer voting weight determined by delegated and held gov tokens.
    /// @param targets Target addresses for calls being executed.
    /// @param values Eth values to send for the execution calls.
    /// @param signatures Function signatures for each call.
    /// @param calldatas Calldata that is passed with each execution call.
    /// @param description Description of the overall proposal.
    /// @return Proposal identifier of the created proposal.
    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint32) {
        if (token.getPriorVotes(msg.sender, block.number - 1) < proposalThreshold) {
            revert InsufficientVotingPower();
        }

        if (targets.length  != values.length || targets.length != signatures.length || targets.length != calldatas.length) {
            revert ArityMismatch();
        }

        if (targets.length == 0 || targets.length > PROPOSAL_MAX_OPERATIONS) {
            revert InvalidActionCount();
        }

        ProposalState proposalState = state();
        if (
            proposal.startBlock != 0 && 
                (
                    proposalState == ProposalState.Pending ||
                    proposalState == ProposalState.Active ||
                    proposalState == ProposalState.Succeeded ||
                    proposalState == ProposalState.Queued
                )
        ) {
            revert UnsettledProposal();
        }

        uint32 quorumThreshold = uint32(max(
            1, bps2Uint(quorumThresholdBPS, token.totalSupply())
        ));

        proposal.eta = 0;
        proposal.proposer = msg.sender;
        proposal.id = ++proposalId;
        proposal.quorumThreshold = quorumThreshold;
        proposal.startBlock = uint32(block.number) + votingDelay;
        proposal.endBlock = proposal.startBlock + votingPeriod;
        proposal.forVotes = 0;
        proposal.againstVotes = 0;
        proposal.abstainVotes = 0;
        proposal.vetoed = false;
        proposal.canceled = false;
        proposal.executed = false;
        proposal.targets = targets;
        proposal.values = values;
        proposal.signatures = signatures;
        proposal.calldatas = calldatas;

        emit ProposalCreated(
            proposal.id,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            proposal.startBlock,
            proposal.endBlock,
            proposal.quorumThreshold,
            description
        );

        return proposal.id;
    }

    /// @notice Queues the current proposal if successfully passed.
    function queue() public {
        if (state() != ProposalState.Succeeded) {
            revert UnpassedProposal();
        }
        uint256 eta = block.timestamp + timelock.delay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    /// @notice Queues a proposal's execution call through the Timelock.
    /// @param target Target address for which the call will be executed.
    /// @param value Eth value to send with the call.
    /// @param signature Function signature associated with the call.
    /// @param data Function calldata associated with the call.
    /// @param eta Timestamp after which the call may be executed.
    function queueOrRevertInternal(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        if (timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta)))) {
            revert DuplicateTransaction();
        }
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /// @notice Executes the current proposal if queued and past timelock delay.
    function execute() public {
        if (state() != ProposalState.Queued) {
            revert UnqueuedProposal();
        }
        proposal.executed = true;
        unchecked {
            for (uint256 i = 0; i < proposal.targets.length; i++) {
                timelock.executeTransaction(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                );
            }
        }
        emit ProposalExecuted(proposal.id);
    }

    /// @notice Cancel the current proposal if not yet settled.
    function cancel() public {
        if (proposal.executed) {
            revert AlreadySettled();
        }
        if (msg.sender != proposal.proposer) {
            revert ProposerOnly();
        }
        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalCanceled(proposal.id);
    }

    /// @notice Veto the proposal if not yet settled.
    /// @dev Veto power meant to be revoked once gov tokens evenly distributed.
    function veto() public {
        if (vetoer == address(0)) {
            revert VetoPowerRevoked();
        }
        if (proposal.executed) {
            revert AlreadySettled();
        }
        if (msg.sender != vetoer) {
            revert VetoerOnly();
        }
        proposal.vetoed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalVetoed(proposal.id);
    }

    /// @notice Get the actions of the current proposal.
    function getActions() public view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        return (
            proposal.targets,
            proposal.values,
            proposal.signatures,
            proposal.calldatas
        );
    }

    /// @notice Get the current proposal's state.
    /// @dev Until the first proposal is created, erroneously returns Defeated.
    /// @return The current proposal's state.
	function state() public view override returns (ProposalState) {
		if (proposal.vetoed) {
			return ProposalState.Vetoed;
		} else if (proposal.canceled) {
			return ProposalState.Canceled;
		} else if (block.number < proposal.startBlock) {
			return ProposalState.Pending;
		} else if (block.number <= proposal.endBlock) {
			return ProposalState.Active;
		} else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < proposal.quorumThreshold) {
			return ProposalState.Defeated;
		} else if (proposal.eta == 0) {
			return ProposalState.Succeeded;
		} else if (proposal.executed) {
			return ProposalState.Executed;
		} else if (block.timestamp > proposal.eta + timelock.GRACE_PERIOD()) {
			return ProposalState.Expired;
		} else {
			return ProposalState.Queued;
		}
	}

    /// @notice Cast vote of type `support` for the current proposal.
    /// @param support The vote type: 0 = against, 1 = support, 2 = abstain
	function castVote(uint8 support) public override {
         _castVote(msg.sender, support);
	}

    /// @notice Cast EIP-712 vote by sig of `voter` for the current proposal.
    /// @dev nonces are not used as voting functions prevent replays already.
    /// @param voter The address of the voter whose signature is being used.
    /// @param support The vote type: 0 = against, 1 = support, 2 = abstain
    /// @param v Transaction signature recovery identifier.
    /// @param r Transaction signature output component #1.
    /// @param s Transaction signature output component #2.
	function castVoteBySig(
        address voter,
		uint8 support,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		address signatory = ecrecover(
			_hashTypedData(keccak256(abi.encode(VOTE_TYPEHASH, voter, proposalId, support))),
			v,
			r,
			s
		);
        if (signatory == address(0) || signatory != voter) {
            revert InvalidSignature();
        }
        _castVote(signatory, support);
	}

    /// @notice Sets a new proposal voting timeframe, `newVotingPeriod`.
    /// @param newVotingPeriod The new voting period to set, in blocks.
	function setVotingPeriod(uint32 newVotingPeriod) public override onlyAdmin {
        if (newVotingPeriod < MIN_VOTING_PERIOD || newVotingPeriod > MAX_VOTING_PERIOD) {
            revert InvalidVotingPeriod();
        }
		votingPeriod = newVotingPeriod;
		emit VotingPeriodSet(votingPeriod);
	}

    /// @notice Sets a new proposal voting delay, `newVotingDelay`.
    /// @dev `votingDelay` is how long to wait before proposal voting opens.
    /// @param newVotingDelay The new voting delay to set, in blocks.
	function setVotingDelay(uint32 newVotingDelay) public override onlyAdmin {
        if (newVotingDelay < MIN_VOTING_DELAY || newVotingDelay > MAX_VOTING_DELAY) {
            revert InvalidVotingDelay();
        }
		votingDelay = newVotingDelay;
		emit VotingDelaySet(votingDelay);
	}

    /// @notice Sets a new gov token proposal threshold, `newProposalThreshold`.
    /// @param newProposalThreshold The new proposal threshold to be set.
	function setProposalThreshold(uint32 newProposalThreshold) public override onlyAdmin {
        if (newProposalThreshold < MIN_PROPOSAL_THRESHOLD || newProposalThreshold > MAX_PROPOSAL_THRESHOLD()) {
            revert InvalidProposalThreshold();
        }
		proposalThreshold = newProposalThreshold;
		emit ProposalThresholdSet(proposalThreshold);
	}


    /// @notice Sets a new quorum voting threshold.
    /// @param newQuorumThresholdBPS The new quorum voting threshold, in bips.
	function setQuorumThresholdBPS(uint32 newQuorumThresholdBPS) public override onlyAdmin {
        if (newQuorumThresholdBPS < MIN_QUORUM_THRESHOLD_BPS || newQuorumThresholdBPS > MAX_QUORUM_THRESHOLD_BPS) {
            revert InvalidQuorumThreshold();
        }
		quorumThresholdBPS = newQuorumThresholdBPS;
		emit QuorumThresholdBPSSet(quorumThresholdBPS);
	}


    /// @notice Sets a new pending admin `newPendingAdmin`.
    /// @param newPendingAdmin The address of the new pending admin.
	function setPendingAdmin(address newPendingAdmin) public override onlyAdmin {
		pendingAdmin = newPendingAdmin;
		emit NewPendingAdmin(pendingAdmin);
	}

    /// @notice Sets a new vetoer `newVetoer`, which can cancel proposals.
    /// @dev Veto power will be revoked upon sufficient gov token distribution.
    /// @param newVetoer The new vetoer address.
    function setVetoer(address newVetoer) public {
        if (msg.sender != vetoer) {
            revert VetoerOnly();
        }
        vetoer = newVetoer;
        emit NewVetoer(vetoer);
    }

    /// @notice Convert the current `pendingAdmin` to the new `admin`.
	function acceptAdmin() public override {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

		emit NewAdmin(admin, pendingAdmin);
		admin = pendingAdmin;
        pendingAdmin = address(0);
	}

    /// @notice Return the maxproposal threshold, based on gov token supply.
    /// @return The maximum allowed proposal threshold, in number of gov tokens.
	function MAX_PROPOSAL_THRESHOLD() public view returns (uint32) {
		return uint32(max(MIN_PROPOSAL_THRESHOLD, bps2Uint(MAX_PROPOSAL_THRESHOLD_BPS, token.totalSupply())));
	}

    /// @notice Checks if interface of identifier `interfaceId` is supported.
    /// @param interfaceId Interface's ERC-165 identifier
    /// @return `true` if `interfaceId` is supported, `false` otherwise.
	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return 
            interfaceId == _ERC165_INTERFACE_ID ||
            interfaceId == _RARITY_SOCIETY_DAO_INTERFACE_ID;
	}

    /// @notice Casts a `support` vote as `voter` for the current proposal.
    /// @param voter The address of the voter whose vote is being cast.
    /// @param support The vote type: 0 = against, 1 = support, 2 = abstain
    /// @return The number of votes (gov tokens delegated to / held by voter).
	function _castVote(
		address voter,
		uint8 support
	) internal returns (uint32) {
        if (state() != ProposalState.Active) {
            revert InactiveProposal();
        }
        if (support > 2) {
            revert InvalidVote();
        }

		Receipt storage receipt = receipts[voter];
        if (receipt.id == proposal.id) {
            revert AlreadyVoted();
        }

		uint32 votes = token.getPriorVotes(voter, proposal.startBlock - votingDelay);
		if (support == 0) {
			proposal.againstVotes = proposal.againstVotes + votes;
		} else if (support == 1) {
			proposal.forVotes = proposal.forVotes + votes;
		} else {
			proposal.abstainVotes = proposal.abstainVotes + votes;
		}

		receipt.id = proposalId;
		receipt.support = support;
		receipt.votes = votes;

		emit VoteCast(voter, proposal.id, support, votes);
		return votes;
	}

    /// @notice Performs authorization check for UUPS upgrades.
    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != admin && msg.sender != vetoer) {
            revert UnauthorizedUpgrade();
        }
    }

	/// @notice Generates an EIP-712 Dopamine DAO domain separator.
    /// @dev See https://eips.ethereum.org/EIPS/eip-712 for details.
    /// @return A 256-bit domain separator.
    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
				keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
				keccak256(bytes("Dopamine DAO")),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

	/// @notice Returns an EIP-712 encoding of structured data `structHash`.
    /// @param structHash The structured data to be encoded and signed.
    /// @return A bytestring suitable for signing in accordance to EIP-712.
    function _hashTypedData(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), structHash));
    }

    /// @notice Returns the domain separator tied to the contract.
    /// @dev Recreated if chain id changes, otherwise cached value is used.
    /// @return 256-bit domain separator tied to this contract.
    function _domainSeparator() internal view returns (bytes32) {
        if (block.chainid == _CHAIN_ID) {
            return _DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

    /// @notice Converts bips `bps` and number `number` to an integer.
    /// @param bps Number of basis points (1 BPS = 0.01%).
    /// @param number Decimal number being converted.
	function bps2Uint(uint256 bps, uint256 number) internal pure returns (uint256) {
		return (number * bps) / 10000;
	}

    /// @notice Returns the max between `a` and `b`.
	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a >= b ? a : b;
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IDopamineDAOEvents.sol";

interface IDopamineDAO is IDopamineDAOEvents {

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint32);

    function queue() external;

    function execute() external;

    function cancel() external;

    function veto() external;

    function castVote(uint8 support) external;

    function castVoteBySig(
		address voter,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function getActions() external view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    );

    function state() external view returns (ProposalState);

    function setVotingDelay(uint32 newVotingDelay) external;

    function setVotingPeriod(uint32 newVotingPeriod) external;

    function setProposalThreshold(uint32 newProposalThreshol) external;

    function setQuorumThresholdBPS(uint32 newQuorumThresholdBPS) external;

    function setVetoer(address newVetoer) external;

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;

	function MAX_PROPOSAL_THRESHOLD() external view returns (uint32);

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }

    struct Proposal {
        uint256 eta;

        address proposer;
        uint32 id;
        uint32 quorumThreshold;
        uint32 proposalThreshold;

        uint32 startBlock;
        uint32 endBlock;
        uint32 forVotes;
        uint32 againstVotes;
        uint32 abstainVotes;
        bool vetoed;
        bool canceled;
        bool executed;

        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
    }

    struct Receipt {
        uint32 id;
        uint8 support;
        uint32 votes;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///                               DOPAMINTPASS                               /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice DopamintPass drop hit allocated capacity.
error DropMaxCapacity();

/// @notice Insufficient time passed since last drop was created.
error InsufficientTimePassed();

/// @notice Configured drop delay is invalid.
error InvalidDropDelay();

/// @notice Configured whitelist size is invalid.
error InvalidWhitelistSize();

/// @notice Configured drop size is invalid.
error InvalidDropSize();

/// @notice IPFS hash for the specified drop has already been set.
error IPFSHashAlreadySet();

/// @notice Action cannot be completed as a current drop is ongoing.
error OngoingDrop();

/// @notice No such drop exists.
error NonExistentDrop();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error SettledAuction();

/// @notice Bid placed was too low (see `reservePrice` and `MIN_BID_DIFF`).
error BidTooLow();

/// @notice The auction has expired.
error ExpiredAuction();

/// @notice Auction has yet to complete.
error IncompleteAuction();

/// @notice Auction duration set is invalid.
error InvalidDuration();

/// @notice Reserve price set is invalid.
error InvalidReservePrice();

/// @notice Time buffer set is invalid.
error InvalidTimeBuffer();

/// @notice Treasury split is invalid, must be in range [0, 100].
error InvalidTreasurySplit();

/// @notice The NFT specified is not up for auction.
error NotUpForAuction();

/// @notice Operation cannot be performed as auction is paused.
error PausedAuction();

/// @notice Auction has not yet started.
error UncommencedAuction();

/// @notice Operation cannot be performed as auction is unpaused.
error UnpausedAuction();

//////////////////////////////////////////////////////////////////////////////// 
///                                   MISC                                   ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Number does not fit in 32 bytes.
error InvalidUint32();

/// @notice Block number being queried is invalid.
error InvalidBlock();

/// @notice Mismatch between input arrays.
error ArityMismatch();

/// @notice Reentrancy vulnerability.
error Reentrant();


////////////////////////////////////////////////////////////////////////////////
///                                 UPGRADES                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Contract already initialized.
error AlreadyInitialized();

/// @notice Upgrade requires either admin or vetoer privileges.
error UnauthorizedUpgrade();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-712                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Signature has expired and is no longer valid.
error ExpiredSignature();

/// @notice Signature invalid.
error InvalidSignature();

////////////////////////////////////////////////////////////////////////////////
///                                 ERC-721                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Token has already minted.
error DuplicateMint();

/// @notice Originating address does not own the NFT.
error InvalidOwner();

/// @notice Receiving contract does not implement the ERC721 wallet interface.
error InvalidReceiver();

/// @notice Receiving address cannot be the zero address.
error ZeroAddressReceiver();

/// @notice NFT does not exist.
error NonExistentNFT();

/// @notice NFT collection has hit maximum supply capacity.
error SupplyMaxCapacity();

/// @notice Sender is not NFT owner, approved address, or owner operator.
error UnauthorizedSender();

////////////////////////////////////////////////////////////////////////////////
///                              ADMINISTRATIVE                              ///
////////////////////////////////////////////////////////////////////////////////
 
/// @notice Function callable only by the admin.
error AdminOnly();

/// @notice Function callable only by the minter.
error MinterOnly();

/// @notice Function callable only by the owner.
error OwnerOnly();

/// @notice Function callable only by the pending owner.
error PendingAdminOnly();

////////////////////////////////////////////////////////////////////////////////
///                                GOVERNANCE                                ///
//////////////////////////////////////////////////////////////////////////////// 

/// @notice Proposal has already been settled.
error AlreadySettled();

/// @notice Proposal already voted for.
error AlreadyVoted();

/// @notice Duplicate transaction queued.
error DuplicateTransaction();

/// @notice Voting power insufficient.
error InsufficientVotingPower();

/// @notice Invalid number of actions proposed.
error InvalidActionCount();

/// @notice Invalid set timelock delay.
error InvalidDelay();

/// @notice Proposal threshold is invalid.
error InvalidProposalThreshold();

/// @notice Quorum threshold is invalid.
error InvalidQuorumThreshold();

/// @notice Vote type is not valid.
error InvalidVote();

/// @notice Voting delay set is invalid.
error InvalidVotingDelay();

/// @notice Voting period set is invalid.
error InvalidVotingPeriod();

/// @notice Only the proposer may invoke this action.
error ProposerOnly();

/// @notice Transaction executed prematurely.
error PrematureTx();

/// @notice Transaction execution was reverted.
error RevertedTx();

/// @notice Transaction is stale.
error StaleTx();

/// @notice Inactive proposals may not be voted for.
error InactiveProposal();

/// @notice Function callable only by the timelock itself.
error TimelockOnly();

/// @notice Proposal has failed to or has yet to be successful.
error UnpassedProposal();

/// @notice Proposal has failed to or has yet to be queued.
error UnqueuedProposal();

/// @notice Transaction is not yet queued.
error UnqueuedTx();

/// @notice A proposal is currently running and must be settled first.
error UnsettledProposal();

/// @notice Function callable only by the vetoer.
error VetoerOnly();

/// @notice Veto power has been revoked.
error VetoPowerRevoked();

////////////////////////////////////////////////////////////////////////////////
///                             Merkle Whitelist                             /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Whitelisted NFT already claimed.
error AlreadyClaimed();

/// @notice Proof for claim is invalid.
error InvalidProof();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../interfaces/ITimelock.sol';
import '../interfaces/IDopamineDAOToken.sol';
import '../interfaces/IDopamineDAO.sol';

contract DopamineDAOStorageV1 {

    uint32 public votingPeriod;

    uint32 public votingDelay;

    uint32 public quorumThresholdBPS;

    ITimelock public timelock;

    uint32 public proposalThreshold;

    uint32 public proposalId;

    address public vetoer;

    IDopamineDAOToken public token;

    address public admin;

    address public pendingAdmin;

    IDopamineDAO.Proposal public proposal;

    mapping(address => IDopamineDAO.Receipt) public receipts;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

pragma solidity ^0.8.9;

interface IDopamineDAOEvents {

    event ProposalCreated(
        uint32 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint32 startBlock,
        uint32 endBlock,
        uint32 quorumThreshold,
        string description
    );

    event VoteCast(address indexed voter, uint32 proposalId, uint8 support, uint32 votes);

    event ProposalCanceled(uint32 id);

    event ProposalQueued(uint32 id, uint256 eta);

    event ProposalExecuted(uint32 id);

    event ProposalVetoed(uint32 id);

    event VotingDelaySet(uint32 votingDelay);

    event VotingPeriodSet(uint32 votingPeriod);

    event ProposalThresholdSet(uint32 proposalThreshold);

    event QuorumThresholdBPSSet(uint256 quorumThresholdBPS);

    event NewPendingAdmin(address pendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    event NewVetoer(address vetoer);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./ITimelockEvents.sol";

interface ITimelock is ITimelockEvents {

    function setPendingAdmin(address pendingAdmin) external;

    function setDelay(uint256 delay) external;

    function delay() external view returns (uint256);

    function acceptAdmin() external;

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes memory);

    function queuedTransactions(bytes32 hash) external view returns (bool);
	function GRACE_PERIOD() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IDopamineDAOToken {

    function getPriorVotes(address account, uint blockNumber) external view returns (uint32);

    function totalSupply() external view returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ITimelockEvents {

    event NewAdmin(address oldAdmin, address newAdmin);

    event NewPendingAdmin(address pendingAdmin);

	event DelaySet(uint256 delay);

	event CancelTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

	event ExecuteTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

	event QueueTransaction(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

}