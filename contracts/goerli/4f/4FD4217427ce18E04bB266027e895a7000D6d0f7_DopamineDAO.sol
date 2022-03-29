// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// This file is under the copyright license: Copyright 2020 Compound Labs, Inc.
/// 
/// DopamineDAO.sol is a modification of Nouns DAO's NounsDAOLogicV1.sol:
/// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/governance/NounsDAOLogicV1.sol
///
/// Copyright licensing is under the BSD-3-Clause license, as the above contract
/// is a rework of Compound Lab's GovernorBravoDelegate.sol (of same license).
/// 
/// The following major changes were made from the original Nouns DAO contract:
/// - Proxy was changed from a modified Governor Bravo Delegator to a UUPS Proxy
/// - Only 1 proposal may be operated at a time (as opposed to 1 per proposer)
/// - Proposal thresholds use fixed number floors (n NFTs), BPS-based ceilings
/// - Voter receipts were removed in favor of event-based off-chain storage
/// - Most `Proposal` struct fields were changed to uint32 for tighter packing
/// - Global proposal id uses a uint32 instead of a uint256
/// - Bakes in EIP-712 data structures as immutables for more efficient caching
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../errors.sol";
import {IDopamineDAOToken} from "../interfaces/IDopamineDAOToken.sol";
import {ITimelock} from "../interfaces/ITimelock.sol";
import {IDopamineDAO} from "../interfaces/IDopamineDAO.sol";
import {DopamineDAOStorage} from "./DopamineDAOStorage.sol";

/// @title Dopamine DAO Implementation Contract
/// @notice The DopamineDAO contract is a Governor Bravo variant originally 
///  forked from Nouns DAO, constrained to support only one proposal at a time,
///  and modified to be integrated with UUPS proxies for easier upgrades. Like 
///  Governor Bravo, governance token holders may make proposals and vote for 
///  them based on their delegated voting weights. In the Dopamine DAO model,
///  governance tokens are ERC-721s  with a capped supply (Dopamine passes).
/// @dev It is intended for the admin to be configured as the  Timelock, and the
///  vetoer to initially be configured as the team multi-sig (revoked later).
contract DopamineDAO is UUPSUpgradeable, DopamineDAOStorage, IDopamineDAO {

    /// @notice The lowest settable threshold for proposals, in number of NFTs.
	uint256 public constant MIN_PROPOSAL_THRESHOLD = 1;

    /// @notice The max settable threshold for proposals, in supply % (bips).
	uint256 public constant MAX_PROPOSAL_THRESHOLD_BPS = 1_000; // 10%

    /// @notice The minimum settable time in blocks proposals can be voted on.
	uint256 public constant MIN_VOTING_PERIOD = 6400; // ~1 day

    /// @notice The maximum settable time in blocks proposals can be voted on.
	uint256 public constant MAX_VOTING_PERIOD = 134000; // ~3 Weeks

    /// @notice The minimum settable wait time in blocks for starting proposals.
	uint256 public constant MIN_VOTING_DELAY = 1; // Next block

    /// @notice The maximum settable wait time in blocks for starting proposals.
	uint256 public constant MAX_VOTING_DELAY = 45000; // ~1 Week

    /// @notice The minimum quorum threshold in bips settable for proposals.
	uint256 public constant MIN_QUORUM_THRESHOLD_BPS = 200; // 2%

    /// @notice The maximum quorum threshold in bips settable for proposals.
	uint256 public constant MAX_QUORUM_THRESHOLD_BPS = 2_000; // 20%

    /// @notice The maximum number of allowed executions for a single proposal.
	uint256 public constant PROPOSAL_MAX_OPERATIONS = 10;
	
    /// @notice The typehash used for EIP-712 voting (see `castVoteBySig`).
	bytes32 public constant VOTE_TYPEHASH = keccak256("Vote(address voter,uint256 proposalId,uint8 support)");

    // EIP-712 immutables for signing messages.
    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    // EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _RARITY_SOCIETY_DAO_INTERFACE_ID = 0x8a5da15c;

    /// @notice This modifier restrict calls to only the admin.
	modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
		_;
	}

    /// @notice Instantiates the Dopamine DAO implementation contract.
    /// @param proxy Address of the proxy to be linked to the contract via UUPS.
    /// @dev The reason a constructor is used here despite this needing to be
    ///  initialized via a UUPS proxy is so that EIP-712 signing can be built 
    ///  off of proxy immutables (the proxy domain separator and chain ID).
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

    /// @inheritdoc IDopamineDAO
    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        if (
            token.priorVotes(msg.sender, block.number - 1) < proposalThreshold) 
        {
            revert VotingPowerInsufficient();
        }

        if (
            targets.length != values.length     || 
            targets.length != signatures.length || 
            targets.length != calldatas.length
        ) {
            revert ArityMismatch();
        }

        if (targets.length == 0 || targets.length > PROPOSAL_MAX_OPERATIONS) {
            revert ProposalActionCountInvalid();
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
            revert ProposalUnsettled();
        }

        proposalId += 1;

        proposal.eta = 0;
        proposal.proposer = msg.sender;
        proposal.quorumThreshold = uint32(
            max(1, bps2Uint(quorumThresholdBPS, token.totalSupply()))
        );
        proposal.startBlock = uint32(block.number) + uint32(votingDelay);
        proposal.endBlock = proposal.startBlock + uint32(votingPeriod);
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
            proposalId,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            proposal.startBlock,
            proposal.endBlock,
            description
        );

        return proposalId;
    }

    /// @inheritdoc IDopamineDAO
    function queue(uint256 id) public {
        if (id != proposalId) {
            revert ProposalInactive();
        }
        if (state() != ProposalState.Succeeded) {
            revert ProposalUnpassed();
        }
        uint256 eta = block.timestamp + timelock.timelockDelay();
        uint256 numTargets = proposal.targets.length;
        for (uint256 i = 0; i < numTargets; i++) {
            queueOrRevertInternal(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        proposal.eta = eta;
        emit ProposalQueued(id, proposal.eta);
    }

    /// @inheritdoc IDopamineDAO
    function execute(uint256 id) public {
        if (id != proposalId) {
            revert ProposalInactive();
        }
        if (state() != ProposalState.Queued) {
            revert ProposalNotYetQueued();
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
        emit ProposalExecuted(id);
    }

    /// @inheritdoc IDopamineDAO
    function cancel(uint256 id) public {
        if (id != proposalId) {
            revert ProposalInactive();
        }
        if (proposal.executed) {
            revert ProposalAlreadySettled();
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
        emit ProposalCanceled(id);
    }


    /// @inheritdoc IDopamineDAO
    function veto() external {
        if (vetoer == address(0)) {
            revert VetoPowerRevoked();
        }
        if (proposal.executed) {
            revert ProposalAlreadySettled();
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
        emit ProposalVetoed(proposalId);
    }

    /// @inheritdoc IDopamineDAO
	function castVote(uint256 id, uint8 support) external {
		 emit VoteCast(
             msg.sender,
             id,
             support,
             _castVote(id, msg.sender, support),
             ""
         );
	}

    /// @inheritdoc IDopamineDAO
	function castVoteWithReason(
        uint256 id,
        uint8 support,
        string calldata reason
    ) 
    external 
    {
		 emit VoteCast(
             msg.sender,
             id,
             support,
             _castVote(id, msg.sender, support),
             reason
         );
	}

    /// @inheritdoc IDopamineDAO
	function castVoteBySig(
        uint256 id,
        address voter,
		uint8 support,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public override {
		address signatory = ecrecover(
			_hashTypedData(
                keccak256(abi.encode(VOTE_TYPEHASH, voter, id, support))
            ),
			v,
			r,
			s
		);
        if (signatory == address(0) || signatory != voter) {
            revert SignatureInvalid();
        }
		emit VoteCast(
            signatory,
            id,
            support,
            _castVote(id, signatory, support),
            ""
        );
	}

    /// @notice Initializes the Dopamine DAO governance contract.
    /// @dev This function may only be called via a proxy contract (e.g. UUPS).
    /// @param timelock_ Timelock address, which controls proposal execution.
    /// @param token_ Governance token, from which voting weights are derived.
    /// @param vetoer_ Address with temporary veto power (revoked later on).
    /// @param votingPeriod_ Time a proposal is up for voting, in blocks.
    /// @param votingDelay_ Time before opening proposal for voting, in blocks.
    /// @param proposalThreshold_ Number of NFTs required to submit a proposal.
    /// @param quorumThresholdBPS_ Supply % (bips) needed to pass a proposal.
	function initialize(
		address timelock_,
		address token_,
		address vetoer_,
		uint256 votingPeriod_,
		uint256 votingDelay_,
		uint256 proposalThreshold_,
        uint256 quorumThresholdBPS_
    ) onlyProxy public {
        if (address(token) != address(0)) {
            revert ContractAlreadyInitialized();
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

    /// @inheritdoc IDopamineDAO
	function maxProposalThreshold() public view returns (uint256) {
		return max(
            MIN_PROPOSAL_THRESHOLD,
            bps2Uint(MAX_PROPOSAL_THRESHOLD_BPS, token.totalSupply())
        );
	}

    /// @inheritdoc IDopamineDAO
    /// @dev Until the first proposal creation, this will return "Defeated".
	function state() public view override returns (ProposalState) {
		if (proposal.vetoed) {
			return ProposalState.Vetoed;
		} else if (proposal.canceled) {
			return ProposalState.Canceled;
		} else if (block.number < proposal.startBlock) {
			return ProposalState.Pending;
		} else if (block.number <= proposal.endBlock) {
			return ProposalState.Active;
		} else if (
            proposal.forVotes <= proposal.againstVotes || 
            proposal.forVotes < proposal.quorumThreshold
        ) {
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

    /// @inheritdoc IDopamineDAO
    function actions() external view returns (
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

    /// @inheritdoc IDopamineDAO
	function setVotingDelay(uint256 newVotingDelay) public override onlyAdmin {
        if (
            newVotingDelay < MIN_VOTING_DELAY || 
            newVotingDelay > MAX_VOTING_DELAY
        ) 
        {
            revert ProposalVotingDelayInvalid();
        }
		votingDelay = newVotingDelay;
		emit VotingDelaySet(votingDelay);
	}

    /// @inheritdoc IDopamineDAO
	function setVotingPeriod(uint256 newVotingPeriod)
        public 
        override 
        onlyAdmin 
    {
        if (
            newVotingPeriod < MIN_VOTING_PERIOD || 
            newVotingPeriod > MAX_VOTING_PERIOD
        ) 
        {
            revert ProposalVotingPeriodInvalid();
        }
		votingPeriod = newVotingPeriod;
		emit VotingPeriodSet(votingPeriod);
	}


    /// @inheritdoc IDopamineDAO
	function setProposalThreshold(uint256 newProposalThreshold) 
        public 
        override 
        onlyAdmin 
    {
        if (
            newProposalThreshold < MIN_PROPOSAL_THRESHOLD || 
            newProposalThreshold > maxProposalThreshold()
        ) 
        {
            revert ProposalThresholdInvalid();
        }
		proposalThreshold = newProposalThreshold;
		emit ProposalThresholdSet(proposalThreshold);
	}

    /// @inheritdoc IDopamineDAO
	function setQuorumThresholdBPS(uint256 newQuorumThresholdBPS) 
        public 
        override 
        onlyAdmin 
    {
        if (
            newQuorumThresholdBPS < MIN_QUORUM_THRESHOLD_BPS ||
            newQuorumThresholdBPS > MAX_QUORUM_THRESHOLD_BPS
        ) 
        {
            revert ProposalQuorumThresholdInvalid();
        }
		quorumThresholdBPS = newQuorumThresholdBPS;
		emit QuorumThresholdBPSSet(quorumThresholdBPS);
	}

    /// @inheritdoc IDopamineDAO
    function setVetoer(address newVetoer) public {
        if (msg.sender != vetoer) {
            revert VetoerOnly();
        }
        emit VetoerChanged(vetoer, newVetoer);
        vetoer = newVetoer;
    }

    /// @inheritdoc IDopamineDAO
	function setPendingAdmin(address newPendingAdmin) 
        public 
        override 
        onlyAdmin 
    {
		pendingAdmin = newPendingAdmin;
		emit PendingAdminSet(pendingAdmin);
	}

    /// @inheritdoc IDopamineDAO
	function acceptAdmin() public override {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

		emit AdminChanged(admin, pendingAdmin);
		admin = pendingAdmin;
        pendingAdmin = address(0);
	}

    /// @notice Queues a current proposal's execution call through the Timelock.
    /// @param target Target address for which the call will be executed.
    /// @param value Eth value in wei  to send with the call.
    /// @param signature Function signature associated with the call.
    /// @param data Function calldata associated with the call.
    /// @param eta Timestamp in seconds after which the call may be executed.
    function queueOrRevertInternal(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        if (
            timelock.queuedTransactions(
                keccak256(abi.encode(target, value, signature, data, eta))
            )
        ) 
        {
            revert TransactionAlreadyQueued();
        }
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /// @notice Casts a `support` vote as `voter` for the current proposal.
    /// @param id The current proposal id (for Governor Bravo compatibility).
    /// @param voter The address of the voter whose vote is being cast.
    /// @param support The vote type: 0 = against, 1 = for, 2 = abstain
    /// @return The number of votes (total number of NFTs delegated to voter).
	function _castVote(
        uint256 id,
		address voter,
		uint8 support
	) internal returns (uint256) {
        if (id != proposalId || state() != ProposalState.Active) {
            revert ProposalInactive();
        }
        if (support > 2) {
            revert VoteInvalid();
        }

        if (_lastVotedProposal[voter] == id) {
            revert VoteAlreadyCast();
        }

		uint32 votes = token.priorVotes(
            voter,
            proposal.startBlock - votingDelay
        );
		if (support == 0) {
			proposal.againstVotes = proposal.againstVotes + votes;
		} else if (support == 1) {
			proposal.forVotes = proposal.forVotes + votes;
		} else {
			proposal.abstainVotes = proposal.abstainVotes + votes;
		}

        _lastVotedProposal[voter] = id;

		return uint256(votes);
	}

    /// @notice Performs an authorization check for UUPS upgrades.
    /// @dev This function ensures only the admin & vetoer can upgrade the DAO.
    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != admin && msg.sender != vetoer) {
            revert UpgradeUnauthorized();
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
    function _hashTypedData(bytes32 structHash) 
        internal 
        view 
        returns (bytes32) 
    {
        return keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
    }

    /// @notice Returns the domain separator tied to the contract.
    /// @dev Recreated if chain id changes, otherwise a cached value is used.
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
	function bps2Uint(uint256 bps, uint256 number) 
        private 
        pure 
        returns (uint256) 
    {
		return (number * bps) / 10000;
	}

    /// @notice Returns the max between uints `a` and `b`.
	function max(uint256 a, uint256 b) private pure returns (uint256) {
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

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

// This file is a shared repository of all errors used in Dopamine's contracts.

////////////////////////////////////////////////////////////////////////////////
///                               DopamintPass                               /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Configured drop delay is invalid.
error DropDelayInvalid();

/// @notice DopamintPass drop hit allocated capacity.
error DropMaxCapacity();

/// @notice No such drop exists.
error DropNonExistent();

/// @notice Action cannot be completed as a current drop is ongoing.
error DropOngoing();

/// @notice Configured drop size is invalid.
error DropSizeInvalid();

/// @notice Insufficient time passed since last drop was created.
error DropTooEarly();

/// @notice Configured whitelist size is too large.
error DropWhitelistOverCapacity();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error AuctionAlreadySettled();

/// @notice The NFT specified in the auction bid is invalid.
error AuctionBidInvalid();

/// @notice Bid placed was too low (see `reservePrice` and `MIN_BID_DIFF`).
error AuctionBidTooLow();

/// @notice Auction duration set is invalid.
error AuctionDurationInvalid();

/// @notice The auction has expired.
error AuctionExpired();

/// @notice Operation cannot be performed as auction is not suspended.
error AuctionNotSuspended();

/// @notice Operation cannot be performed as auction is already suspended.
error AuctionAlreadySuspended();

/// @notice Auction has yet to complete.
error AuctionOngoing();

/// @notice Reserve price set is invalid.
error AuctionReservePriceInvalid();

/// @notice Time buffer set is invalid.
error AuctionTimeBufferInvalid();

/// @notice Treasury split is invalid, must be in range [0, 100].
error AuctionTreasurySplitInvalid();

//////////////////////////////////////////////////////////////////////////////// 
///                              Miscellaneous                               ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Mismatch between input arrays.
error ArityMismatch();

/// @notice Block number being queried is invalid.
error BlockInvalid();

/// @notice Reentrancy vulnerability.
error FunctionReentrant();

/// @notice Number does not fit in 32 bytes.
error Uint32ConversionInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 Upgrades                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Contract already initialized.
error ContractAlreadyInitialized();

/// @notice Upgrade requires either admin or vetoer privileges.
error UpgradeUnauthorized();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-712                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Signature has expired and is no longer valid.
error SignatureExpired();

/// @notice Signature invalid.
error SignatureInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-721                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Originating address does not own the NFT.
error OwnerInvalid();

/// @notice Receiving address cannot be the zero address.
error ReceiverInvalid();

/// @notice Receiving contract does not implement the ERC721 wallet interface.
error SafeTransferUnsupported();

/// @notice Sender is not NFT owner, approved address, or owner operator.
error SenderUnauthorized();

/// @notice NFT collection has hit maximum supply capacity.
error SupplyMaxCapacity();

/// @notice Token has already minted.
error TokenAlreadyMinted();

/// @notice NFT does not exist.
error TokenNonExistent();

////////////////////////////////////////////////////////////////////////////////
///                              Administrative                              ///
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
///                                Governance                                ///
//////////////////////////////////////////////////////////////////////////////// 

/// @notice Invalid number of actions proposed.
error ProposalActionCountInvalid();

/// @notice Proposal has already been settled.
error ProposalAlreadySettled();

/// @notice Inactive proposals may not be voted for.
error ProposalInactive();

/// @notice Proposal has failed to or has yet to be queued.
error ProposalNotYetQueued();

/// @notice Quorum threshold is invalid.
error ProposalQuorumThresholdInvalid();

/// @notice Proposal threshold is invalid.
error ProposalThresholdInvalid();

/// @notice Proposal has failed to or has yet to be successful.
error ProposalUnpassed();

/// @notice A proposal is currently running and must be settled first.
error ProposalUnsettled();

/// @notice Voting delay set is invalid.
error ProposalVotingDelayInvalid();

/// @notice Voting period set is invalid.
error ProposalVotingPeriodInvalid();

/// @notice Only the proposer may invoke this action.
error ProposerOnly();

/// @notice Function callable only by the vetoer.
error VetoerOnly();

/// @notice Veto power has been revoked.
error VetoPowerRevoked();

/// @notice Proposal already voted for.
error VoteAlreadyCast();

/// @notice Vote type is not valid.
error VoteInvalid();

/// @notice Voting power insufficient.
error VotingPowerInsufficient();

////////////////////////////////////////////////////////////////////////////////
///                                 Timelock                                 /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Invalid set timelock delay.
error TimelockDelayInvalid();

/// @notice Function callable only by the timelock itself.
error TimelockOnly();

/// @notice Duplicate transaction queued.
error TransactionAlreadyQueued();

/// @notice Transaction is not yet queued.
error TransactionNotYetQueued();

/// @notice Transaction executed prematurely.
error TransactionPremature();

/// @notice Transaction execution was reverted.
error TransactionReverted();

/// @notice Transaction is stale.
error TransactionStale();

////////////////////////////////////////////////////////////////////////////////
///                             Merkle Whitelist                             /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Proof for claim is invalid.
error ProofInvalid();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
  
/// @title Dopamine DAO Governance Token
/// @notice Although Dopamine DAO is intended to be integrated with the Dopamine
///  ERC-721 pass (see DopamintPass.sol), any governance contract supporting the
///  following interface definitions can be used. In the future, it is possible 
///  that Dopamine DAO will upgrade to support another second-tier governance 
///  If this happens, the token must support the IDopamineDAOToken interface.
/// @dev The total voting weight can be no larger than `type(uint32).max`.
interface IDopamineDAOToken {

    /// @notice Get number of votes for `voter` at block number `blockNumber`.
    /// @param voter       Address of the voter being queried.
    /// @param blockNumber Block number to tally votes from.
    /// @return The total tallied votes of `voter` at `blockNumber`.
    function priorVotes(address voter, uint blockNumber) 
        external view returns (uint32);

    /// @notice Retrieves the token supply for the contract.
    /// @return The total circulating supply of the gov token as a uint256.
    function totalSupply() external view returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
 
import "./ITimelockEvents.sol";

/// @title Timelock Interface
interface ITimelock is ITimelockEvents {

    /// @notice Queues a call for future execution.
    /// @dev This function is only callable by admin, and throws if `eta` is not 
    ///  a timestamp past the current block time plus the timelock delay.
    /// @param target    The address that this call will be targeted to.
    /// @param value     The eth value in wei to send along with the call.
    /// @param signature The signature of the execution call.
    /// @param data      The calldata to be passed with the call.
    /// @param eta       The timestamp at which call is eligible for execution.
    /// @return A bytes32 keccak-256 hash of the abi-encoded parameters.
    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    /// @notice Cancels an execution call.
    /// @param target    The address that this call was intended for.
    /// @param value     The eth value in wei that was to be sent with the call.
    /// @param signature The signature of the execution call.
    /// @param data      The calldata originally included with the call.
    /// @param eta       The timestamp at which call was eligible for execution.
    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    /// @notice Executes a queued execution call.
    /// @dev The calldata `data` will be verified by ensuring that the passed in
    ///  signature `signaure` matches the function selector included in `data`.
    /// @param target    The address that this call was intended for.
    /// @param value     The eth value in wei that was to be sent with the call.
    /// @param signature The signature of the execution call.
    /// @param data      The calldata originally included with the call.
    /// @param eta       The timestamp at which call was eligible for execution.
    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes memory);

    /// @notice Returns the grace period, in seconds, representing the time
    ///  added to the timelock delay before a transaction call becomes stale.
    function GRACE_PERIOD() external view returns (uint256);

    /// @notice Returns the timelock delay, in seconds, representing how long
    ///  call must be queued for before being eligible for execution.
    function timelockDelay() external view returns (uint256);

    /// @notice Retrieves a boolean indicating whether a transaction was queued.
    /// @param txHash Bytes32 keccak-256 hash of Abi-encoded call parameters.
    /// @return True if the transaction has been queued, false otherwise.
    function queuedTransactions(bytes32 txHash) external view returns (bool);

    /// @notice Sets the timelock delay to `newTimelockDelay`.
    /// @dev This function is only callable by the admin, and throws if the 
    ///  timelock delay is too low or too high.
    /// @param newTimelockDelay The new timelock delay to set, in seconds.
    function setTimelockDelay(uint256 newTimelockDelay) external;

    /// @notice Sets the pending admin address to  `newPendingAdmin`.
    /// @param newPendingAdmin The address of the new pending admin.
    function setPendingAdmin(address newPendingAdmin) external;

    /// @notice Assigns the `pendingAdmin` address to the `admin` address.
    /// @dev This function is only callable by the pending admin.
    function acceptAdmin() external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
 
import {IDopamineDAOEvents} from "./IDopamineDAOEvents.sol";

/// @title Dopamine DAO Implementation Interface
interface IDopamineDAO is IDopamineDAOEvents {

    /// @notice ProposalState represents the current proposal's lifecycle state.
    enum ProposalState {

        /// @notice On creation, proposals are Pending till voting delay passes.
        Pending,

        /// @notice Active proposals can be voted on, until voting period ends.
        Active,

        /// @notice Once a proposer cancels their proposal it becomes Canceled.
        Canceled,

        /// @notice Defeated means votes didn't hit quorum / are mainly Against.
        Defeated,

        /// @notice Succeeded proposals have majority For votes at voting end.
        Succeeded,

        /// @notice Queued represents a Succeeded proposal that was queued.
        Queued,
        
        /// @notice Expired means failure to execute by ETA + grace period time.
        Expired,

        /// @notice A Queued proposal which is successfully executed at its ETA.
        Executed,

        /// @notice Once a vetoer vetoes a proposal, it becomes vetoed.
        Vetoed
    }

    /// @notice Proposal is an encapsulation of the ongoing proposal.
    struct Proposal {

        /// @notice Block timestamp at which point proposal ready for execution.
        uint256 eta;

        /// @notice The address that created the proposal.
        address proposer;

        /// @notice The number of votes required for proposal success.
        uint32 quorumThreshold;

        /// @notice The block at which point the proposal is considered active.
        uint32 startBlock;

        /// @notice The last block at which votes may be cast for the proposal.
        uint32 endBlock;

        /// @notice The tally of the number of against votes (vote type = 0).
        uint32 againstVotes;

        /// @notice The tally of the number of for votes (vote type = 1).
        uint32 forVotes;

        /// @notice The tally of the number of abstain votes (vote type = 2).
        uint32 abstainVotes;

        /// @notice Boolean indicating whether the proposal was vetoed.
        bool vetoed;

        /// @notice Boolean indicating whether the proposal was canceled.
        bool canceled;

        /// @notice Boolean indicating whether the proposal was executed.
        bool executed;

        /// @notice List of target addresses for the proposal execution calls.
        address[] targets;

        /// @notice Amounts (in wei) to send for proposal execution calls.
        uint256[] values;

        /// @notice The function signatures of the proposal execution calls.
        string[] signatures;

        /// @notice Calldata passed with the proposal execution calls.
        bytes[] calldatas;
    }

    /// @notice Creates a new proposal.
    /// @dev This reverts if the existing proposal has yet to be settled.
    /// @param targets     Target addresses for the calls being executed.
    /// @param values      Amounts (in wei) to send for the execution calls.
    /// @param signatures  The function signatures of the execution calls.
    /// @param calldatas   Calldata to be passed with each execution call.
    /// @param description A string description of the overall proposal.
    /// @return The proposal identifier associated with the created proposal.
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    /// @notice Queues the current proposal if successfully passed.
    /// @dev Reverts if wrong proposal id is specified or if it's yet to pass.
    /// @param id The current proposal id (for Governor Bravo compatibility).
    function queue(uint256 id) external;

    /// @notice Executes the current proposal if successfully queued.
    /// @dev Reverts if wrong id given, proposal yet to pass, or timelock fails.
    /// @param id The current proposal id (for Governor Bravo compatibility).
    function execute(uint256 id) external;

    /// @notice Cancel the current proposal if not yet settled.
    /// @dev Reverts if wrong id given, proposal executed, or proposer invalid.
    /// @param id The current proposal id (for Governor Bravo compatibility).
    function cancel(uint256 id) external;

    /// @notice Veto the proposal if not yet settled, only if sender is vetoer.
    /// @dev Reverts if proposal executed, vetoer invalid, or veto power voided.
    function veto() external;

    /// @notice Cast vote of type `support` for the current proposal.
    /// @dev Reverts if wrong id or vote type  given, proposal inactive, or vote
    ///  already cast. Voting weight is sourced from proposal creation block.
    /// @param id The current proposal id (for Governor Bravo compatibility).
    /// @param support The vote type: 0 = against, 1 = for, 2 = abstain
    function castVote(uint256 id, uint8 support) external;

    /// @notice Same as `castVote`, with an added`reason` message provided.
    /// @param id The current proposal id (for Governor Bravo compatibility).
    /// @param support The vote type: 0 = against, 1 = for, 2 = abstain
    /// @param reason A string message explaining the choice of vote selection.
    function castVoteWithReason(
        uint256 id,
        uint8 support,
        string calldata reason
    ) external;

    /// @notice Cast vote of type `support` for current proposal via signature.
    /// @dev See `castVote` details. In addition, reverts if signature invalid.
    /// @param id The current proposal id (for Governor Bravo compatibility).
    /// @param support The vote type: 0 = against, 1 = for, 2 = abstain
    /// @param v Transaction signature recovery identifier.
    /// @param r Transaction signature output component #1.
    /// @param s Transaction signature output component #2.
    function castVoteBySig(
        uint256 id,
		address voter,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Retrieves the maximum allowed proposal threshold in NFT units.
    /// @dev This function ensures proposal threshold is non-zero in the case
    ///  when the proposal bips value multiplied by NFT supply is equal to 0.
    /// @return The maximum allowed proposal threshold, in number of NFTs.
    function maxProposalThreshold() external view returns (uint256);

    /// @notice Retrieves the current proposal's state.
    /// @return The current proposal's state, as a `ProposalState` struct.
    function state() external view returns (ProposalState);

    /// @notice Retrieve the actions of the current proposal.
    /// @return targets     Target addresses for the calls being executed.
    /// @return values      Amounts (in wei) to be sent for the execution calls.
    /// @return signatures  The function signatures of theexecution calls.
    /// @return calldatas   Calldata to be passed with each execution call.
    function actions() 
        external 
        view 
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );

    /// @notice Sets the proposal voting delay to `newVotingDelay`.
    /// @dev This function is only callable by the admin, and throws if the 
    ///  voting delay is too low or too high.
    /// @param newVotingDelay The new voting delay to set, in blocks.
    function setVotingDelay(uint256 newVotingDelay) external;

    /// @notice Sets the proposal voting period to `newVotingPeriod`.
    /// @dev This function is only callable by the admin, and throws if the 
    ///  voting period is too low or too high.
    /// @param newVotingPeriod The new voting period to set, in blocks.
    function setVotingPeriod(uint256 newVotingPeriod) external;

    /// @notice Sets the proposal threshold to `newProposalThreshold`.
    /// @dev This function is only callable by the admin, and throws if the
    ///  proposal threshold is too low or above `maxProposalThreshold()`.
    /// @param newProposalThreshold The new NFT proposal threshold to set.
    function setProposalThreshold(uint256 newProposalThreshold) external;

    /// @notice Sets the quorum threshold (in bips) to `newQuoruMThresholdBPS`.
    /// @dev This function is only callable by the admin, and throws if the
    ///  quorum threshold bips value is too low or too high.
    /// @param newQuorumThresholdBPS The new quorum voting threshold, in bips.
    function setQuorumThresholdBPS(uint256 newQuorumThresholdBPS) external;

    /// @notice Sets the vetoer address to `newVetoer`.
    /// @dev Veto power should be revoked after sufficient NFT distribution, at
    ///  which point this function will throw (e.g. when vetoer = `address(0)`).
    /// @param newVetoer The new vetoer address.
    function setVetoer(address newVetoer) external;

    /// @notice Sets the pending admin address to  `newPendingAdmin`.
    /// @param newPendingAdmin The address of the new pending admin.
    function setPendingAdmin(address newPendingAdmin) external;

    /// @notice Assigns the `pendingAdmin` address to the `admin` address.
    /// @dev This function is only callable by the pending admin.
    function acceptAdmin() external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import { ITimelock } from "../interfaces/ITimelock.sol";
import { IDopamineDAOToken } from "../interfaces/IDopamineDAOToken.sol";
import { IDopamineDAO } from "../interfaces/IDopamineDAO.sol";

/// @title Dopamine DAO Storage Contract
/// @dev Upgrades involving new storage variables should utilize a new contract
///  inheriting the prior storage contract. This would look like the following:
///  `contract DopamineDAOStorageV1 is DopamineDAOStorage { ... }`   (upgrade 1)
///  `contract DopamineDAOStorageV2 is DopamineDAOStorageV1 { ... }` (upgrade 2)
contract DopamineDAOStorage {

    /// @notice The id of the ongoing  proposal.
    uint32 public proposalId;

    /// @notice The address administering proposal lifecycles and DAO settings.
    address public admin;

    /// @notice Address of temporary admin that will become admin once accepted.
    address public pendingAdmin;

    /// @notice Address with ability to veto proposals (intended to be revoked).
    address public vetoer;

    /// @notice The time in blocks a proposal is eligible to be voted on.
    uint256 public votingPeriod;

    /// @notice The time in blocks to wait until a proposal opens up for voting.
    uint256 public votingDelay;

    /// @notice The number of voting units needed for a proposal to be created.
    uint256 public proposalThreshold;

    /// @notice The quorum threshold, in bips, a proposal requires to pass.
    uint256 public quorumThresholdBPS;

    /// @notice The timelock, responsible for coordinating proposal execution.
    ITimelock public timelock;

    /// @notice The Dopamine DAO governance token (the ERC-721 Dopamine pass).
    IDopamineDAOToken public token;

    /// @notice The ongoing proposal.
    IDopamineDAO.Proposal public proposal;

    /// @dev A map of voters to their last voted upon proposal ids.
    mapping(address => uint256) internal _lastVotedProposal;

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
 
/// @title Timelock Events Interface
interface ITimelockEvents {

    /// @notice Emits when a new transaction execution call is queued.
    /// @param txHash    Sha-256 hash of abi-encoded execution call parameters.
    /// @param target    Target addresses of the call to be queued.
    /// @param value     Amount (in wei) to send with the queued transaction.
    /// @param signature The function signature of the queued transaction.
    /// @param data      Calldata to be passed with the queued transaction call.
    /// @param eta       Timestamp at which call is eligible for execution. 
	event TransactionQueued(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

    /// @notice Emits when a new transaction execution call is canceled.
    /// @param txHash    Sha-256 hash of abi-encoded execution call parameters.
    /// @param target    Target addresses of the canceled call.
    /// @param value     Amount (in wei) that was supposed to be sent with call.
    /// @param signature The function signature of the canceled transaction.
    /// @param data      Calldata that was supposed to be sent with the call.
    /// @param eta       Timestamp at which call was eligible for execution. 
	event TransactionCanceled(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

    /// @notice Emits when a new transaction execution call is executed.
    /// @param txHash    Sha-256 hash of abi-encoded execution call parameters.
    /// @param target    Target addresses of the executed call.
    /// @param value     Amount (in wei) that was sent with the transaction.
    /// @param signature The function signature of the executed transaction.
    /// @param data      Calldata that was passed to the executed transaction.
    /// @param eta       Timestamp at which call became eligible for execution. 
	event TransactionExecuted(
		bytes32 indexed txHash,
		address indexed target,
		uint256 value,
		string signature,
		bytes data,
		uint256 eta
	);

    /// @notice Emits when admin is changed from `oldAdmin` to `newAdmin`.
    /// @param oldAdmin The address of the previous admin.
    /// @param newAdmin The address of the new admin.
    event AdminChanged(address oldAdmin, address newAdmin);

    /// @notice Emits when a new pending admin `pendingAdmin` is set.
    /// @param pendingAdmin The address of the pending admin set.
    event PendingAdminSet(address pendingAdmin);

    /// @notice Emits when a new timelock delay `timelockDelay` is set.
    /// @param timelockDelay The new timelock delay to set, in blocks.
	event TimelockDelaySet(uint256 timelockDelay);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
 
/// @title Dopamine DAO Events Interface
interface IDopamineDAOEvents {

    /// @notice Emits when a new proposal is created.
    /// @param  id         The id of the newly created proposal.
    /// @param proposer    The address which created the new proposal.
    /// @param targets     Target addresses for the calls to be executed.
    /// @param values      Amounts (in wei) to send for the execution calls.
    /// @param signatures  The function signatures of the execution calls.
    /// @param calldatas   Calldata to be passed with each execution call.
    /// @param startBlock  The block at which voting opens for the proposal.
    /// @param endBlock    The block at which voting ends for the proposal.
    /// @param description A string description of the overall proposal.
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint32 startBlock,
        uint32 endBlock,
        string description
    );

    /// @notice Emits when a proposal is queued for execution.
    /// @param id The id of the queued proposal.
    /// @param eta Timestamp in seconds at which the proposal may be executed.
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice Emits when a proposal is canceled by its proposer.
    /// @param id The id of the canceled proposal.
    event ProposalCanceled(uint256 id);

    /// @notice Emits when a proposal is successfully executed.
    /// @param id The id of the executed proposal.
    event ProposalExecuted(uint256 id);

    /// @notice Emits when a proposal is vetoed by the vetoer.
    /// @param id The id of the vetoed proposal.
    event ProposalVetoed(uint256 id);

    /// @notice Emits when voter `voter` casts `votes` votes of type `support`.
    /// @param voter   The address of the voter whose vote was cast.
    /// @param id      The id of the voted upon proposal.
    /// @param support The vote type: 0 = against, 1 = for, 2 = abstain
    /// @param votes   The total number of NFTs assigned to the vote's weight.
    /// @param reason  A string message explaining the choice of vote selection.
    event VoteCast(
        address indexed voter,
        uint256 id,
        uint8 support,
        uint256 votes,
        string reason
    );

    /// @notice Emits when a new voting delay `votingDelay` is set.
    /// @param votingDelay The new voting delay set, in blocks.
    event VotingDelaySet(uint256 votingDelay);

    /// @notice Emits when a new voting period `votingPeriod` is set.
    /// @param votingPeriod The new voting period set, in blocks.
    event VotingPeriodSet(uint256 votingPeriod);

    /// @notice Emits when a new proposal threshold `proposalThreshold` is set.
    /// @param proposalThreshold The proposal threshold set, in NFT units.
    event ProposalThresholdSet(uint256 proposalThreshold);

    /// @notice Emits when a new quorum threshold `quorumThresholdBPS` is set.
    /// @param quorumThresholdBPS The new quorum threshold set, in bips.
    event QuorumThresholdBPSSet(uint256 quorumThresholdBPS);

    /// @notice Emits when a new pending admin `pendingAdmin` is set.
    /// @param pendingAdmin The new address of the pending admin that was set.
    event PendingAdminSet(address pendingAdmin);

    /// @notice Emits when vetoer is changed from `oldVetoer` to `newVetoe+`.
    /// @param oldVetoer The address of the previous vetoer.
    /// @param newVetoer The address of the new vetoer.
    event VetoerChanged(address oldVetoer, address newVetoer);

}