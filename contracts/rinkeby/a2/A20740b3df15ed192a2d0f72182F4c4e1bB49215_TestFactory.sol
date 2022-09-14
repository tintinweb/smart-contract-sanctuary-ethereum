// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {Owned} from '../utils/Owned.sol';

import {ForumGroup, Multicall} from '../Forum/ForumGroup.sol';

/// @notice TEST FACTORY
/// @dev This contract is used to TEST the ForumGroup contract - it does not include other extensions used in production
contract TestFactory is Multicall, Owned {
	/// ----------------------------------------------------------------------------------------
	/// Errors and Events
	/// ----------------------------------------------------------------------------------------

	event GroupDeployed(
		ForumGroup indexed forumGroup,
		string name,
		string symbol,
		address[] voters,
		uint32[4] govSettings
	);

	error NullDeploy();

	error MintingClosed();

	error MemberLimitExceeded();

	/// ----------------------------------------------------------------------------------------
	/// Factory Storage
	/// ----------------------------------------------------------------------------------------

	address payable public forumMaster;
	address payable public executionManager;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(
		address deployer,
		address payable forumMaster_,
		address payable _executionManager
	) Owned(deployer) {
		forumMaster = forumMaster_;
		executionManager = _executionManager;
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	function setForumMaster(address payable forumMaster_) external onlyOwner {
		forumMaster = forumMaster_;
	}

	function setExecutionManager(address payable executionManager_) external onlyOwner {
		executionManager = executionManager_;
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	function deployGroup(
		string memory name_,
		string memory symbol_,
		address[] calldata voters_,
		uint32[4] memory govSettings_
	) public payable virtual returns (ForumGroup forumGroup) {
		if (voters_.length > 12) revert MemberLimitExceeded();

		forumGroup = ForumGroup(_cloneAsMinimalProxy(forumMaster, name_));

		address[3] memory initialExtensions = [address(0), executionManager, address(0)];

		forumGroup.init{value: msg.value}(name_, symbol_, voters_, initialExtensions, govSettings_);

		emit GroupDeployed(forumGroup, name_, symbol_, voters_, govSettings_);
	}

	/// @dev modified from Aelin (https://github.com/AelinXYZ/aelin/blob/main/contracts/MinimalProxyFactory.sol)
	function _cloneAsMinimalProxy(address payable base, string memory name_)
		internal
		virtual
		returns (address payable clone)
	{
		bytes memory createData = abi.encodePacked(
			// constructor
			bytes10(0x3d602d80600a3d3981f3),
			// proxy code
			bytes10(0x363d3d373d3d3d363d73),
			base,
			bytes15(0x5af43d82803e903d91602b57fd5bf3)
		);

		bytes32 salt = keccak256(bytes(name_));

		assembly {
			clone := create2(
				0, // no value
				add(createData, 0x20), // data
				mload(createData),
				salt
			)
		}
		// if CREATE2 fails for some reason, address(0) is returned
		if (clone == address(0)) revert NullDeploy();
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

	event OwnerUpdated(address indexed user, address indexed newOwner);

	/*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

	address public owner;

	modifier onlyOwner() virtual {
		require(msg.sender == owner, 'UNAUTHORIZED');

		_;
	}

	/*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(address _owner) {
		owner = _owner;

		emit OwnerUpdated(address(0), _owner);
	}

	/*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

	function setOwner(address newOwner) public virtual onlyOwner {
		owner = newOwner;

		emit OwnerUpdated(msg.sender, newOwner);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {ForumGovernance} from './ForumGovernance.sol';

import {Multicall} from '../utils/Multicall.sol';
import {NFTreceiver} from '../utils/NFTreceiver.sol';
import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';

import {IForumGroupTypes} from '../interfaces/IForumGroupTypes.sol';
import {IForumGroupExtension} from '../interfaces/IForumGroupExtension.sol';
import {IPfpStaker} from '../interfaces/IPfpStaker.sol';
import {IERC1271} from '../interfaces/IERC1271.sol';
import {IExecutionManager} from '../interfaces/IExecutionManager.sol';

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/**
 * @title ForumGroup
 * @notice Forum investment group multisig wallet
 * @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)
 */
contract ForumGroup is
	IForumGroupTypes,
	ForumGovernance,
	ReentrancyGuard,
	Multicall,
	NFTreceiver,
	IERC1271
{
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event NewProposal(
		address indexed proposer,
		uint256 indexed proposal,
		ProposalType indexed proposalType,
		address[] accounts,
		uint256[] amounts,
		bytes[] payloads
	);

	event ProposalProcessed(
		ProposalType indexed proposalType,
		uint256 indexed proposal,
		bool indexed didProposalPass
	);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error Initialized();

	error MemberLimitExceeded();

	error PeriodBounds();

	error VoteThresholdBounds();

	error TypeBounds();

	error NoArrayParity();

	error NotCurrentProposal();

	error VotingNotEnded();

	error NotExtension();

	error PFPFailed();

	error SignatureError();

	error CallError();

	/// ----------------------------------------------------------------------------------------
	///							DAO STORAGE
	/// ----------------------------------------------------------------------------------------

	address private pfpExtension;
	address private executionManager;

	uint256 public proposalCount;
	uint32 public votingPeriod;
	uint32 public gracePeriod;
	uint32 public tokenVoteThreshold; // 1-100
	uint32 public memberVoteThreshold; // 1-100

	string public docs;

	bytes32 public constant PROPOSAL_HASH = keccak256('SignProposal(uint256 proposal)');

	/**
	 * 'contractSignatureAllowance' provides the contract with the ability to 'sign' as an EOA would
	 * 	It enables signature based transactions on marketplaces accommodating the EIP-1271 standard.
	 *  Address is the account which makes the call to check the verified signature (ie. the martketplace).
	 * 	Bytes32 is the hash of the calldata which the group approves. This data is dependant
	 * 	on the marketplace / dex where the group are approving the transaction.
	 */
	mapping(address => mapping(bytes32 => uint256)) private contractSignatureAllowance;
	mapping(address => bool) public extensions;
	mapping(uint256 => Proposal) public proposals;
	mapping(ProposalType => VoteType) public proposalVoteTypes;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice init the group settings and mint membership for founders
	 * @param name_ name of the group
	 * @param symbol_ for the group token
	 * @param members_ initial members
	 * @param extensions_ initial extensions enabled
	 * @param govSettings_ settings for voting and proposals
	 */
	function init(
		string memory name_,
		string memory symbol_,
		address[] memory members_,
		address[3] memory extensions_,
		uint32[4] memory govSettings_
	) public payable virtual nonReentrant {
		if (votingPeriod != 0) revert Initialized();

		if (govSettings_[0] == 0 || govSettings_[0] > 365 days) revert PeriodBounds();

		if (govSettings_[1] > 1 days) revert PeriodBounds();

		if (govSettings_[2] < 1 || govSettings_[2] > 100) revert VoteThresholdBounds();

		if (govSettings_[3] < 1 || govSettings_[3] > 100) revert VoteThresholdBounds();

		ForumGovernance._init(name_, symbol_, members_);

		// Set the pfpSetter - determines uri of group token
		pfpExtension = extensions_[0];

		// Set the executionManager - handles routing of calls and commission
		executionManager = extensions_[1];

		// Set the fundraise extension to true - allows it to mint shares
		extensions[extensions_[2]] = true;

		memberCount = members_.length;

		votingPeriod = govSettings_[0];

		gracePeriod = govSettings_[1];

		memberVoteThreshold = govSettings_[2];

		tokenVoteThreshold = govSettings_[3];

		/// ALL PROPOSAL TYPES DEFAULT TO MEMBER VOTES ///
	}

	/// ----------------------------------------------------------------------------------------
	///							PROPOSAL LOGIC
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Get the proposal details for a given proposal
	 * @param proposal Index of the proposal
	 */
	function getProposalArrays(uint256 proposal)
		public
		view
		virtual
		returns (
			address[] memory accounts,
			uint256[] memory amounts,
			bytes[] memory payloads
		)
	{
		Proposal storage prop = proposals[proposal];

		(accounts, amounts, payloads) = (prop.accounts, prop.amounts, prop.payloads);
	}

	/**
	 * @notice Make a proposal to the group
	 * @param proposalType type of proposal
	 * @param accounts target accounts
	 * @param amounts to be sent
	 * @param payloads for target accounts
	 * @return proposal index of the created proposal
	 */
	function propose(
		ProposalType proposalType,
		address[] calldata accounts,
		uint256[] calldata amounts,
		bytes[] calldata payloads
	) public virtual nonReentrant returns (uint256 proposal) {
		if (accounts.length != amounts.length || amounts.length != payloads.length)
			revert NoArrayParity();

		if (proposalType == ProposalType.VPERIOD)
			if (amounts[0] == 0 || amounts[0] > 365 days) revert PeriodBounds();

		if (proposalType == ProposalType.GPERIOD)
			if (amounts[0] > 1 days) revert PeriodBounds();

		if (
			proposalType == ProposalType.MEMBER_THRESHOLD || proposalType == ProposalType.TOKEN_THRESHOLD
		)
			if (amounts[0] == 0 || amounts[0] > 100) revert VoteThresholdBounds();

		if (proposalType == ProposalType.TYPE)
			if (amounts[0] > 13 || amounts[1] > 2 || amounts.length != 2) revert TypeBounds();

		if (proposalType == ProposalType.MINT)
			if ((memberCount + accounts.length) > 12) revert MemberLimitExceeded();

		// Cannot realistically overflow on human timescales
		unchecked {
			++proposalCount;
		}

		proposal = proposalCount;

		proposals[proposal] = Proposal({
			proposalType: proposalType,
			accounts: accounts,
			amounts: amounts,
			payloads: payloads,
			creationTime: _safeCastTo32(block.timestamp)
		});

		emit NewProposal(msg.sender, proposal, proposalType, accounts, amounts, payloads);
	}

	/**
	 * @notice Process a proposal
	 * @param proposal index of proposal
	 * @param signatures array of sigs of members who have voted for the proposal
	 * @return didProposalPass check if proposal passed
	 * @return results from any calls
	 * @dev signatures must be in ascending order
	 */
	function processProposal(uint256 proposal, Signature[] calldata signatures)
		public
		virtual
		nonReentrant
		returns (bool didProposalPass, bytes[] memory results)
	{
		Proposal storage prop = proposals[proposal];

		VoteType voteType = proposalVoteTypes[prop.proposalType];

		if (prop.creationTime == 0) revert NotCurrentProposal();

		// This is safe from overflow because `votingPeriod` and `gracePeriod` are capped
		// so they will not combine with unix time to exceed the max uint256 value.
		unchecked {
			// If gracePeriod is set to 0 we do not wait, instead proposal is processed when ready
			// allowing for faster execution.
			if (gracePeriod != 0 && block.timestamp < prop.creationTime + votingPeriod + gracePeriod)
				revert VotingNotEnded();
		}

		uint256 votes;

		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PROPOSAL_HASH, proposal))
			)
		);

		// We keep track of the previous signer in the array to ensure there are no duplicates
		address prevSigner;

		// For each sig we check the recovered signer is a valid member and count thier vote
		for (uint256 i; i < signatures.length; ) {
			// Recover the signer
			address recoveredSigner = ecrecover(
				digest,
				signatures[i].v,
				signatures[i].r,
				signatures[i].s
			);

			// If not a member, or the signer is out of order (used to prevent duplicates), revert
			if (balanceOf[recoveredSigner][MEMBERSHIP] == 0 || prevSigner >= recoveredSigner)
				revert InvalidSignature();

			// If member vote we increment by 1 (for the signer) + the number of members who have delegated to the signer
			if (voteType == VoteType.MEMBER)
				votes += 1 + EnumerableSet.length(memberDelegators[recoveredSigner]);
				// Else we calculate the number of votes based on share of the treasury
			else {
				uint256 len = EnumerableSet.length(memberDelegators[recoveredSigner]);
				// Add the number of votes the signer holds
				votes += balanceOf[recoveredSigner][TOKEN];
				// If the signer has been delegated too,check the balances of anyone who has delegated to the current signer
				if (len != 0)
					for (uint256 j; j < len; ) {
						votes += balanceOf[EnumerableSet.at(memberDelegators[recoveredSigner], j)][TOKEN];
						++j;
					}
			}
			++i;
			prevSigner = recoveredSigner;
		}

		didProposalPass = _countVotes(voteType, votes);

		if (didProposalPass) {
			// Cannot realistically overflow on human timescales
			unchecked {
				if (prop.proposalType == ProposalType.MINT)
					for (uint256 i; i < prop.accounts.length; ) {
						_mint(prop.accounts[i], MEMBERSHIP, 1, '');
						_mint(prop.accounts[i], TOKEN, prop.amounts[i], '');
						++i;
					}

				if (prop.proposalType == ProposalType.BURN)
					for (uint256 i; i < prop.accounts.length; ) {
						_burn(prop.accounts[i], MEMBERSHIP, 1);
						_burn(prop.accounts[i], TOKEN, prop.amounts[i]);
						++i;
					}

				if (prop.proposalType == ProposalType.CALL) {
					uint256 value;

					for (uint256 i; i < prop.accounts.length; i++) {
						results = new bytes[](prop.accounts.length);

						value += IExecutionManager(executionManager).manageExecution(
							prop.accounts[i],
							prop.amounts[i],
							prop.payloads[i]
						);

						(, bytes memory result) = prop.accounts[i].call{value: prop.amounts[i]}(
							prop.payloads[i]
						);

						results[i] = result;
					}
					// Send the commission calculated in the executionManger
					(bool success, ) = executionManager.call{value: value}('');
					if (!success) revert CallError();
				}

				// Governance settings
				if (prop.proposalType == ProposalType.VPERIOD) votingPeriod = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.GPERIOD) gracePeriod = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.MEMBER_THRESHOLD)
					memberVoteThreshold = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.TOKEN_THRESHOLD)
					tokenVoteThreshold = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.TYPE)
					proposalVoteTypes[ProposalType(prop.amounts[0])] = VoteType(prop.amounts[1]);

				if (prop.proposalType == ProposalType.PAUSE) _flipPause();

				if (prop.proposalType == ProposalType.EXTENSION)
					for (uint256 i; i < prop.accounts.length; i++) {
						if (prop.amounts[i] != 0) extensions[prop.accounts[i]] = !extensions[prop.accounts[i]];

						if (prop.payloads[i].length > 3) {
							IForumGroupExtension(prop.accounts[i]).setExtension(prop.payloads[i]);
						}
					}

				if (prop.proposalType == ProposalType.ESCAPE) delete proposals[prop.amounts[0]];

				if (prop.proposalType == ProposalType.DOCS) docs = string(prop.payloads[0]);

				if (prop.proposalType == ProposalType.PFP) {
					// Call the NFTContract to approve the PfpStaker to transfer the token
					(bool success, ) = prop.accounts[0].call(prop.payloads[0]);
					if (!success) revert PFPFailed();

					IPfpStaker(pfpExtension).stakeNFT(address(this), prop.accounts[0], prop.amounts[0]);
				}

				if (prop.proposalType == ProposalType.ALLOW_CONTRACT_SIG) {
					// This sets the allowance for EIP-1271 contract signature transactions on marketplaces
					for (uint256 i; i < prop.accounts.length; i++) {
						contractSignatureAllowance[prop.accounts[i]][bytes32(prop.payloads[i])] = 1;
					}
				}
				// Delete proposal now that it has been processed
				delete proposals[proposal];

				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);
			}
		} else {
			// Only delete and update the proposal settings if there are not enough votes AND the time limit has passed
			// This prevents deleting proposals unfairly
			if (block.timestamp > prop.creationTime + votingPeriod + gracePeriod) {
				delete proposals[proposal];

				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);
			}
		}
	}

	/**
	 * @notice Count votes on a proposal
	 * @param voteType voteType to count
	 * @param yesVotes number of votes for the proposal
	 * @return bool true if the proposal passed, false otherwise
	 */
	function _countVotes(VoteType voteType, uint256 yesVotes) internal view virtual returns (bool) {
		if (voteType == VoteType.MEMBER)
			if ((yesVotes * 100) / memberCount >= memberVoteThreshold) return true;

		if (voteType == VoteType.SIMPLE_MAJORITY)
			if (yesVotes > ((totalSupply * 50) / 100)) return true;

		if (voteType == VoteType.TOKEN_MAJORITY)
			if (yesVotes >= (totalSupply * tokenVoteThreshold) / 100) return true;

		return false;
	}

	/// ----------------------------------------------------------------------------------------
	///							EXTENSIONS
	/// ----------------------------------------------------------------------------------------

	modifier onlyExtension() {
		if (!extensions[msg.sender]) revert NotExtension();

		_;
	}

	/**
	 * @notice Interface to call an extension set by the group
	 * @param extension address of extension
	 * @param amount for extension
	 * @param extensionData data sent to extension to be decoded or used
	 * @return mint true if tokens are to be minted, false if to be burnt
	 * @return amountOut amount of token to mint/burn
	 */
	function callExtension(
		address extension,
		uint256 amount,
		bytes calldata extensionData
	) public payable virtual nonReentrant returns (bool mint, uint256 amountOut) {
		if (!extensions[extension]) revert NotExtension();

		(mint, amountOut) = IForumGroupExtension(extension).callExtension{value: msg.value}(
			msg.sender,
			amount,
			extensionData
		);

		if (mint) {
			if (amountOut != 0) _mint(msg.sender, TOKEN, amountOut, '');
		} else {
			if (amountOut != 0) _burn(msg.sender, TOKEN, amount);
		}
	}

	function mintShares(
		address to,
		uint256 id,
		uint256 amount
	) public virtual onlyExtension {
		_mint(to, id, amount, '');
	}

	function burnShares(
		address from,
		uint256 id,
		uint256 amount
	) public virtual onlyExtension {
		_burn(from, id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///							UTILITIES
	/// ----------------------------------------------------------------------------------------

	// 'id' not used but included to keep function signature of ERC1155
	function uri(uint256) public view override returns (string memory) {
		return IPfpStaker(pfpExtension).getURI(address(this));
	}

	function isValidSignature(bytes32 hash, bytes memory signature)
		public
		view
		override
		returns (bytes4)
	{
		// Decode signture
		if (signature.length != 65) revert SignatureError();

		uint8 v;
		bytes32 r;
		bytes32 s;

		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := and(mload(add(signature, 65)), 255)
		}

		if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
			revert SignatureError();

		if (!(v == 27 || v == 28)) revert SignatureError();

		// If the signature is valid (and not malleable), return the signer address
		address signer = ecrecover(hash, v, r, s);

		/**
		 * The group must pass a proposal to allow the contract to be used to sign transactions
		 * Once passed contractSignatureAllowance will be set to 1 for the exact transaction hash
		 * Signer must also be a member
		 */
		//
		if (balanceOf[signer][MEMBERSHIP] != 0 && contractSignatureAllowance[msg.sender][hash] != 0) {
			return 0x1626ba7e;
		} else {
			return 0xffffffff;
		}
	}

	receive() external payable virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

/// @notice Minimalist and gas efficient ERC1155 based DAO implementation with governance.
/// @author Modified from KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/KaliDAOtoken.sol)
abstract contract ForumGovernance {
	using EnumerableSet for EnumerableSet.AddressSet;

	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 amount
	);

	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] amounts
	);

	event ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved);

	event URI(string value, uint256 indexed id);

	event PauseFlipped(bool indexed paused);

	event Delegation(
		address indexed delegator,
		address indexed currentDelegatee,
		address indexed delegatee
	);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error Paused();

	error SignatureExpired();

	error InvalidDelegate();

	error InvalidSignature();

	error Uint32max();

	error Uint96max();

	error InvalidNonce();

	/// ----------------------------------------------------------------------------------------
	///							METADATA STORAGE
	/// ----------------------------------------------------------------------------------------

	string public name;

	string public symbol;

	uint8 public constant decimals = 18;

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 STORAGE
	/// ----------------------------------------------------------------------------------------

	uint256 public totalSupply;

	mapping(address => mapping(uint256 => uint256)) public balanceOf;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/// ----------------------------------------------------------------------------------------
	///							EIP-712 STORAGE
	/// ----------------------------------------------------------------------------------------

	bytes32 internal INITIAL_DOMAIN_SEPARATOR;

	uint256 internal INITIAL_CHAIN_ID;

	mapping(address => uint256) public nonces;

	/// ----------------------------------------------------------------------------------------
	///							GROUP STORAGE
	/// ----------------------------------------------------------------------------------------

	bool public paused;

	bytes32 public constant DELEGATION_TYPEHASH =
		keccak256('Delegation(address delegatee,uint256 nonce,uint256 deadline)');

	// Membership NFT
	uint256 internal constant MEMBERSHIP = 0;
	// DAO token representing voting share of treasury
	uint256 internal constant TOKEN = 1;

	uint256 public memberCount;

	// All delegators for a member -> default case is an empty array
	mapping(address => EnumerableSet.AddressSet) memberDelegators;
	// The current delegate of a member -> default is no delegation, ie address(0)
	mapping(address => address) public memberDelegatee;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	function _init(
		string memory name_,
		string memory symbol_,
		address[] memory members_
	) internal virtual {
		name = name_;

		symbol = symbol_;

		paused = true;

		INITIAL_CHAIN_ID = block.chainid;

		INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();

		// Voters limited to 12 by a check in the factory
		unchecked {
			uint256 votersLen = members_.length;

			// Mint membership for initial members
			for (uint256 i; i < votersLen; ) {
				_mint(members_[i], MEMBERSHIP, 1, '');
				++i;
			}
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							METADATA LOGIC
	/// ----------------------------------------------------------------------------------------

	function uri(uint256 id) public view virtual returns (string memory);

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 LOGIC
	/// ----------------------------------------------------------------------------------------

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual notPaused {
		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		balanceOf[from][id] -= amount;
		balanceOf[to][id] += amount;

		// Cannot transfer membership while delegating / being delegated to
		if (id == MEMBERSHIP)
			if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
				revert InvalidDelegate();

		emit TransferSingle(msg.sender, from, to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual notPaused {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		for (uint256 i = 0; i < idsLength; ) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			balanceOf[from][id] -= amount;
			balanceOf[to][id] += amount;

			// Cannot transfer membership while delegating / being delegated to
			if (ids[i] == MEMBERSHIP)
				if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
					revert InvalidDelegate();

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, from, to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
					ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function balanceOfBatch(address[] memory owners, uint256[] memory ids)
		public
		view
		virtual
		returns (uint256[] memory balances)
	{
		uint256 ownersLength = owners.length; // Saves MLOADs.

		require(ownersLength == ids.length, 'LENGTH_MISMATCH');

		balances = new uint256[](owners.length);

		// Unchecked because the only math done is incrementing
		// the array index counter which cannot possibly overflow.
		unchecked {
			for (uint256 i = 0; i < ownersLength; i++) {
				balances[i] = balanceOf[owners[i]][ids[i]];
			}
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							EIP-2612 LOGIC
	/// ----------------------------------------------------------------------------------------

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
	}

	function _computeDomainSeparator() internal view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256(
						'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
					),
					keccak256(bytes(name)),
					keccak256('1'),
					block.chainid,
					address(this)
				)
			);
	}

	/// ----------------------------------------------------------------------------------------
	///							GROUP LOGIC
	/// ----------------------------------------------------------------------------------------

	modifier notPaused() {
		if (paused) revert Paused();
		_;
	}

	function delegators(address delegatee) public view virtual returns (address[] memory) {
		return EnumerableSet.values(memberDelegators[delegatee]);
	}

	function delegate(address delegatee) public payable virtual {
		_delegate(msg.sender, delegatee);
	}

	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public payable virtual {
		if (block.timestamp > deadline) revert SignatureExpired();

		bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, deadline));

		bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), structHash));

		address signatory = ecrecover(digest, v, r, s);

		if (balanceOf[signatory][MEMBERSHIP] == 0) revert InvalidDelegate();

		// cannot realistically overflow on human timescales
		unchecked {
			if (nonce != nonces[signatory]++) revert InvalidNonce();
		}

		_delegate(signatory, delegatee);
	}

	function removeDelegator(address delegator) public virtual {
		// Verify msg.sender is being delegated to by the delegator
		if (memberDelegatee[delegator] != msg.sender) revert InvalidDelegate();
		_delegate(delegator, msg.sender);
	}

	function _delegate(address delegator, address delegatee) internal {
		// Can only delegate from/to existing members
		if (balanceOf[msg.sender][MEMBERSHIP] == 0 || balanceOf[delegatee][MEMBERSHIP] == 0)
			revert InvalidDelegate();

		address currentDelegatee = memberDelegatee[delegator];

		// Can not delegate to others if delegated to
		if (memberDelegators[delegator].length() > 0) revert InvalidDelegate();

		// If delegator is currently delegating
		if (currentDelegatee != address(0)) {
			// 1) remove delegator from the memberDelegators list of their delegatee
			memberDelegators[currentDelegatee].remove(delegator);

			// 2) reset delegator memberDelegatee to address(0)
			memberDelegatee[delegator] = address(0);

			emit Delegation(delegator, currentDelegatee, address(0));

			// If delegator is not currently delegating
		} else {
			// 1) add the delegator to the memberDelegators list of their new delegatee
			memberDelegators[delegatee].add(delegator);

			// 2) set the memberDelegatee of the delegator to the new delegatee
			memberDelegatee[delegator] = delegatee;

			emit Delegation(delegator, currentDelegatee, delegatee);
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							ERC-165 LOGIC
	/// ----------------------------------------------------------------------------------------

	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
			interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
	}

	/// ----------------------------------------------------------------------------------------
	///						INTERNAL MINT/BURN  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal {
		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value
		unchecked {
			balanceOf[to][id] += amount;
		}

		// If membership token is being updated, update member count
		if (id == MEMBERSHIP) {
			++memberCount;
		}

		// If non membership token is being updated, update total supply
		if (id == TOKEN) {
			totalSupply += amount;
		}

		emit TransferSingle(msg.sender, address(0), to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchMint(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[to][ids[i]] += amounts[i];

			// If membership token is being updated, update member count
			if (ids[i] == MEMBERSHIP) {
				++memberCount;
			}

			// If non membership token is being updated, update total supply
			if (ids[i] == TOKEN) {
				totalSupply += amounts[i];
			}

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, address(0), to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
					msg.sender,
					address(0),
					ids,
					amounts,
					data
				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchBurn(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[from][ids[i]] -= amounts[i];

			// If membership token is being updated, update member count
			if (ids[i] == MEMBERSHIP) {
				// Member can not leave while delegating / being delegated to
				if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
					revert InvalidDelegate();

				--memberCount;
			}

			// If non membership token is being updated, update total supply
			if (ids[i] == TOKEN) {
				totalSupply -= amounts[i];
			}

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				i++;
			}
		}

		emit TransferBatch(msg.sender, from, address(0), ids, amounts);
	}

	function _burn(
		address from,
		uint256 id,
		uint256 amount
	) internal {
		balanceOf[from][id] -= amount;

		// If membership token is being updated, update member count
		if (id == MEMBERSHIP) {
			// Member can not leave while delegating / being delegated to
			if (memberDelegatee[from] != address(0) || EnumerableSet.length(memberDelegators[from]) > 0)
				revert InvalidDelegate();

			--memberCount;
		}

		// If non membership token is being updated, update total supply
		if (id == TOKEN) {
			totalSupply -= amount;
		}

		emit TransferSingle(msg.sender, from, address(0), id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///						PAUSE  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _flipPause() internal virtual {
		paused = !paused;

		emit PauseFlipped(paused);
	}

	/// ----------------------------------------------------------------------------------------
	///						SAFECAST  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
		if (x > type(uint32).max) revert Uint32max();

		return uint32(x);
	}

	function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
		if (x > type(uint96).max) revert Uint96max();

		return uint96(x);
	}
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external returns (bytes4);

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice Helper utility that enables calling multiple local methods in a single call.
/// @author Modified from Uniswap (https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol)
abstract contract Multicall {
	function multicall(bytes[] calldata data) public virtual returns (bytes[] memory results) {
		results = new bytes[](data.length);

		// cannot realistically overflow on human timescales
		unchecked {
			for (uint256 i = 0; i < data.length; i++) {
				(bool success, bytes memory result) = address(this).delegatecall(data[i]);

				if (!success) {
					if (result.length < 68) revert();

					assembly {
						result := add(result, 0x04)
					}

					revert(abi.decode(result, (string)));
				}
				results[i] = result;
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Receiver hook utility for NFT 'safe' transfers
/// @author Author KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/utils/NFTreceiver.sol)
abstract contract NFTreceiver {
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0x150b7a02;
	}

	function onERC1155Received(
		address,
		address,
		uint256,
		uint256,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xf23a6e61;
	}

	function onERC1155BatchReceived(
		address,
		address,
		uint256[] calldata,
		uint256[] calldata,
		bytes calldata
	) external pure returns (bytes4) {
		return 0xbc197c81;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity ^0.8.13;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from KaliDAO (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
	error Reentrancy();

	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		//require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
		if (_status == _ENTERED) revert Reentrancy();

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice ForumGroup interface for sharing types
interface IForumGroupTypes {
	enum ProposalType {
		MINT, // add membership
		BURN, // revoke membership
		CALL, // call contracts
		VPERIOD, // set `votingPeriod`
		GPERIOD, // set `gracePeriod`
		MEMBER_THRESHOLD, // set `memberVoteThreshold`
		TOKEN_THRESHOLD, // set `tokenVoteThreshold`
		TYPE, // set `VoteType` to `ProposalType`
		PAUSE, // flip membership transferability
		EXTENSION, // flip `extensions` whitelisting
		ESCAPE, // delete pending proposal in case of revert
		DOCS, // amend org docs
		PFP, // change the group pfp
		ALLOW_CONTRACT_SIG // enable the contract to sign as an EOA
	}

	enum VoteType {
		MEMBER, // % of members required to pass
		SIMPLE_MAJORITY, // over 50% total votes required to pass
		TOKEN_MAJORITY // user set % of total votes required to pass
	}

	struct Proposal {
		ProposalType proposalType;
		address[] accounts; // member(s) being added/kicked; account(s) receiving payload
		uint256[] amounts; // value(s) to be minted/burned/spent; gov setting [0]
		bytes[] payloads; // data for CALL proposals
		uint32 creationTime; // timestamp of proposal creation
	}

	struct Signature {
		uint8 v;
		bytes32 r;
		bytes32 s;
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice ForumGroup membership extension interface.
/// @author modified from KaliDAO.
interface IForumGroupExtension {
	function setExtension(bytes calldata extensionData) external;

	function callExtension(
		address account,
		uint256 amount,
		bytes calldata extensionData
	) external payable returns (bool mint, uint256 amountOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp - defaults to shield
interface IPfpStaker {
	struct StakedPFP {
		address NFTcontract;
		uint256 tokenId;
	}

	function stakeInitialShield(address, uint256) external;

	function stakeNFT(
		address,
		address,
		uint256
	) external;

	function getURI(address) external view returns (string memory nftURI);

	function getStakedNFT() external view returns (address NFTContract, uint256 tokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 * @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.1/contracts/interfaces/IERC1271.sol)
 * _Available since v4.1._
 */
interface IERC1271 {
	/**
	 * @dev Should return whether the signature provided is valid for the provided data
	 * @param hash      Hash of the data to be signed
	 * @param signature Signature byte array associated with _data
	 */
	function isValidSignature(bytes32 hash, bytes memory signature)
		external
		view
		returns (bytes4 magicValue);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @notice Execution Manager interface.
/// @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)

interface IExecutionManager {
	function addProposalHandler(address newHandledAddress, address handlerAddress) external;

	function updateProposalHandler(address proposalHandler, address newProposalHandler) external;

	function manageExecution(
		address target,
		uint256 value,
		bytes memory payload
	) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}