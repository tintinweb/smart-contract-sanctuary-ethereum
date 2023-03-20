// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Reputation.sol";
import "../Interfaces.sol";

/**
 * @title GReputation extends Reputation with delegation and cross blockchain merkle states
 * @dev NOTICE: this breaks DAOStack nativeReputation usage, since it is not possiible to upgrade
 * the original nativeReputation token. it means you can no longer rely on avatar.nativeReputation() or controller.nativeReputation()
 * to return the current reputation token.
 * The DAO avatar will be the owner of this reputation token and not the Controller.
 * Minting by the DAO will be done using controller.genericCall and not via controller.mintReputation
 *
 * V2 fixes merkle tree bug
 */
contract GReputation is Reputation {
	bytes32 public constant ROOT_STATE = keccak256("rootState");

	/// @notice The EIP-712 typehash for the contract's domain
	bytes32 public constant DOMAIN_TYPEHASH =
		keccak256(
			"EIP712Domain(string name,uint256 chainId,address verifyingContract)"
		);

	/// @notice The EIP-712 typehash for the delegation struct used by the contract
	bytes32 public constant DELEGATION_TYPEHASH =
		keccak256("Delegation(address delegate,uint256 nonce,uint256 expiry)");

	/// @notice describe a single blockchain states
	/// @param stateHash the hash with the reputation state
	/// @param hashType the type of hash. currently just 0 = merkle tree root hash
	/// @param totalSupply the totalSupply at the blockchain
	/// @param blockNumber the effective blocknumber
	struct BlockchainState {
		bytes32 stateHash;
		uint256 hashType;
		uint256 totalSupply;
		uint256 blockNumber;
		uint256[5] __reserevedSpace;
	}

	/// @notice A record of states for signing / validating signatures
	mapping(address => uint256) public nonces;

	/// @notice mapping from blockchain id hash to list of states
	mapping(bytes32 => BlockchainState[]) public blockchainStates;

	/// @notice mapping from stateHash to the user balance can be >0 only after supplying state proof
	mapping(bytes32 => mapping(address => uint256)) public stateHashBalances;

	/// @notice list of blockchains having a statehash for easy iteration
	bytes32[] public activeBlockchains;

	/// @notice keep map of user -> delegate
	mapping(address => address) public delegates;

	/// @notice map of user non delegated + delegated votes to user. this is used for actual voting
	mapping(address => uint256[]) public activeVotes;

	/// @notice keep map of address -> reputation recipient, an address can set that its earned rep will go to another address
	mapping(address => address) public reputationRecipients;

	/// @notice An event thats emitted when a delegate account's vote balance changes
	event DelegateVotesChanged(
		address indexed delegate,
		address indexed delegator,
		uint256 previousBalance,
		uint256 newBalance
	);

	event StateHash(string blockchain, bytes32 merkleRoot, uint256 totalSupply);

	event StateHashProof(
		string blockchain,
		address indexed user,
		uint256 repBalance
	);

	/**
	 * @dev initialize
	 */
	function initialize(
		INameService _ns,
		string calldata _stateId,
		bytes32 _stateHash,
		uint256 _totalSupply
	) external initializer {
		__Reputation_init(_ns);
		if (_totalSupply > 0)
			_setBlockchainStateHash(_stateId, _stateHash, _totalSupply);
	}

	function updateDAO(INameService _ns) public {
		if (address(nameService) == address(0)) {
			setDAO(_ns);
			_setupRole(DEFAULT_ADMIN_ROLE, address(avatar));
			_setupRole(MINTER_ROLE, address(avatar));
		}
	}

	function _canMint() internal view override {
		require(
			hasRole(MINTER_ROLE, _msgSender()) ||
				(address(nameService) != address(0) &&
					(_msgSender() == nameService.getAddress("GDAO_CLAIMERS") ||
						_msgSender() == nameService.getAddress("GDAO_STAKING") ||
						_msgSender() == nameService.getAddress("GDAO_STAKERS"))),
			"GReputation: need minter role or be GDAO contract"
		);
	}

	function _mint(address _user, uint256 _amount)
		internal
		override
		returns (uint256)
	{
		return _mint(_user, _amount, false);
	}

	/// @notice internal function that overrides Reputation.sol with consideration to delegation
	/// @param _user the address to mint for
	/// @param _amount the amount of rep to mint
	/// @return the actual amount minted
	function _mint(
		address _user,
		uint256 _amount,
		bool ignoreRepTarget
	) internal returns (uint256) {
		address repTarget = reputationRecipients[_user];
		repTarget = ignoreRepTarget == false && repTarget != address(0)
			? repTarget
			: _user;

		super._mint(repTarget, _amount);

		//set self as initial delegator
		address delegator = delegates[repTarget];
		if (delegator == address(0)) {
			delegates[repTarget] = repTarget;
			delegator = repTarget;
		}
		uint256 previousVotes = getVotesAt(delegator, false, block.number);

		_updateDelegateVotes(
			delegator,
			repTarget,
			previousVotes,
			previousVotes + _amount
		);
		return _amount;
	}

	/// @notice internal function that overrides Reputation.sol with consideration to delegation
	/// @param _user the address to burn from
	/// @param _amount the amount of rep to mint
	/// @return the actual amount burned
	function _burn(address _user, uint256 _amount)
		internal
		override
		returns (uint256)
	{
		uint256 amountBurned = super._burn(_user, _amount);
		address delegator = delegates[_user];
		delegator = delegator != address(0) ? delegator : _user;
		delegates[_user] = delegator;

		uint256 previousVotes = getVotesAt(delegator, false, block.number);

		_updateDelegateVotes(
			delegator,
			_user,
			previousVotes,
			previousVotes - amountBurned
		);

		return amountBurned;
	}

	/// @notice sets the state hash of a blockchain, can only be called by owner
	/// @param _id the string name of the blockchain (will be hashed to produce byte32 id)
	/// @param _hash the state hash
	/// @param _totalSupply total supply of reputation on the specific blockchain
	function setBlockchainStateHash(
		string memory _id,
		bytes32 _hash,
		uint256 _totalSupply
	) public {
		_onlyAvatar();
		_setBlockchainStateHash(_id, _hash, _totalSupply);
	}

	/// @notice sets the state hash of a blockchain, can only be called by owner
	/// @param _id the string name of the blockchain (will be hashed to produce byte32 id)
	/// @param _hash the state hash
	/// @param _totalSupply total supply of reputation on the specific blockchain
	function _setBlockchainStateHash(
		string memory _id,
		bytes32 _hash,
		uint256 _totalSupply
	) internal {
		bytes32 idHash = keccak256(bytes(_id));

		//dont consider rootState as blockchain,  it is a special state hash
		bool isRootState = idHash == ROOT_STATE;
		require(
			!isRootState || totalSupplyLocalAt(block.number) == 0,
			"rootState already created"
		);
		if (isRootState) {
			updateValueAtNow(totalSupplyHistory, _totalSupply);
		}
		uint256 i = 0;
		for (; !isRootState && i < activeBlockchains.length; i++) {
			if (activeBlockchains[i] == idHash) break;
		}

		//if new blockchain
		if (!isRootState && i == activeBlockchains.length) {
			activeBlockchains.push(idHash);
		}

		BlockchainState memory state;
		state.stateHash = _hash;
		state.totalSupply = _totalSupply;
		state.blockNumber = block.number;
		blockchainStates[idHash].push(state);

		emit StateHash(_id, _hash, _totalSupply);
	}

	/// @notice get the number of active votes a user holds after delegation (vs the basic balance of reputation he holds)
	/// @param _user the user to get active votes for
	/// @param _global wether to include reputation from other blockchains
	/// @param _blockNumber get votes state at specific block
	/// @return the number of votes
	function getVotesAt(
		address _user,
		bool _global,
		uint256 _blockNumber
	) public view returns (uint256) {
		uint256 startingBalance = getValueAt(activeVotes[_user], _blockNumber);

		if (_global) {
			for (uint256 i = 0; i < activeBlockchains.length; i++) {
				startingBalance += getVotesAtBlockchain(
					activeBlockchains[i],
					_user,
					_blockNumber
				);
			}
		}

		return startingBalance;
	}

	/**
	 * @notice returns aggregated active votes in all blockchains and delegated
	 * @param _user the user to get active votes for
	 * @return the number of votes
	 */
	function getVotes(address _user) public view returns (uint256) {
		return getVotesAt(_user, true, block.number);
	}

	/**
	 * @notice same as getVotes, be compatible with metamask
	 */
	function balanceOf(address _user) public view returns (uint256 balance) {
		return getVotesAt(_user, block.number);
	}

	/**
	 same as getVotes be compatible with compound 
	 */
	function getCurrentVotes(address _user) public view returns (uint256) {
		return getVotesAt(_user, true, block.number);
	}

	function getPriorVotes(address _user, uint256 _block)
		public
		view
		returns (uint256)
	{
		return getVotesAt(_user, true, _block);
	}

	/**
	 * @notice returns aggregated active votes in all blockchains and delegated at specific block
	 * @param _user user to get active votes for
	 * @param _blockNumber get votes state at specific block
	 * @return the number of votes
	 */
	function getVotesAt(address _user, uint256 _blockNumber)
		public
		view
		returns (uint256)
	{
		return getVotesAt(_user, true, _blockNumber);
	}

	/**
	 * @notice returns total supply in current blockchain
	 * @param _blockNumber get total supply at specific block
	 * @return the totaly supply
	 */
	function totalSupplyLocal(uint256 _blockNumber)
		public
		view
		returns (uint256)
	{
		return totalSupplyLocalAt(_blockNumber);
	}

	/**
	 * @notice returns total supply in all blockchain aggregated
	 * @param _blockNumber get total supply at specific block
	 * @return the totaly supply
	 */
	function totalSupplyAt(uint256 _blockNumber) public view returns (uint256) {
		uint256 startingSupply = totalSupplyLocalAt(_blockNumber);
		for (uint256 i = 0; i < activeBlockchains.length; i++) {
			startingSupply += totalSupplyAtBlockchain(
				activeBlockchains[i],
				_blockNumber
			);
		}
		return startingSupply;
	}

	/// @dev This function makes it easy to get the total number of reputation
	/// @return The total number of reputation
	function totalSupply() public view returns (uint256) {
		return totalSupplyAt(block.number);
	}

	/// @notice get the number of active votes a user holds after delegation in specific blockchain
	/// @param _id the keccak hash of the blockchain string id
	/// @param _user the user to get active votes for
	/// @param _blockNumber get votes state at specific block
	/// @return the number of votes
	function getVotesAtBlockchain(
		bytes32 _id,
		address _user,
		uint256 _blockNumber
	) public view returns (uint256) {
		BlockchainState[] storage states = blockchainStates[_id];
		int256 i = int256(states.length);

		if (i == 0) return 0;
		BlockchainState storage state = states[uint256(i - 1)];
		for (i = i - 1; i >= 0; i--) {
			if (state.blockNumber <= _blockNumber) break;
			state = states[uint256(i - 1)];
		}
		if (i < 0) return 0;

		return stateHashBalances[state.stateHash][_user];
	}

	/**
	 * @notice returns total supply in a specific blockchain
	 * @param _blockNumber get total supply at specific block
	 * @return the totaly supply
	 */
	function totalSupplyAtBlockchain(bytes32 _id, uint256 _blockNumber)
		public
		view
		returns (uint256)
	{
		BlockchainState[] storage states = blockchainStates[_id];
		int256 i;
		if (states.length == 0) return 0;
		for (i = int256(states.length - 1); i >= 0; i--) {
			if (states[uint256(i)].blockNumber <= _blockNumber) break;
		}
		if (i < 0) return 0;

		BlockchainState storage state = states[uint256(i)];
		return state.totalSupply;
	}

	/**
	 * @notice prove user balance in a specific blockchain state hash, uses new sorted pairs trees and double hash for preimage attack mitigation
	 * @dev "rootState" is a special state that can be supplied once, and actually mints reputation on the current blockchain
	 * we use non sorted merkle tree, as sorting while preparing merkle tree is heavy
	 * @param _id the string id of the blockchain we supply proof for
	 * @param _user the user to prove his balance
	 * @param _balance the balance we are prooving
	 * @param _proof array of byte32 with proof data (currently merkle tree path)
	 * @return true if proof is valid
	 */
	function proveBalanceOfAtBlockchain(
		string memory _id,
		address _user,
		uint256 _balance,
		bytes32[] memory _proof
	) public returns (bool) {
		return
			_proveBalanceOfAtBlockchain(
				_id,
				_user,
				_balance,
				_proof,
				new bool[](0),
				0,
				false
			);
	}

	/**
	 * DEPRECATED: future state hashes will be with sorted pairs and with double hash leaf values
	 * @notice prove user balance in a specific blockchain state hash
	 * @dev "rootState" is a special state that can be supplied once, and actually mints reputation on the current blockchain
	 * we use non sorted merkle tree, as sorting while preparing merkle tree is heavy
	 * @param _id the string id of the blockchain we supply proof for
	 * @param _user the user to prove his balance
	 * @param _balance the balance we are prooving
	 * @param _proof array of byte32 with proof data (currently merkle tree path)
	 * @param _isRightNode array of bool with indication if should be hashed on right or left
	 * @param _nodeIndex index of node in the tree (for unsorted merkle tree proof)
	 * @return true if proof is valid
	 */
	function proveBalanceOfAtBlockchainLegacy(
		string memory _id,
		address _user,
		uint256 _balance,
		bytes32[] memory _proof,
		bool[] memory _isRightNode,
		uint256 _nodeIndex
	) public returns (bool) {
		return
			_proveBalanceOfAtBlockchain(
				_id,
				_user,
				_balance,
				_proof,
				_isRightNode,
				_nodeIndex,
				true
			);
	}

	function _proveBalanceOfAtBlockchain(
		string memory _id,
		address _user,
		uint256 _balance,
		bytes32[] memory _proof,
		bool[] memory _isRightNode,
		uint256 _nodeIndex,
		bool legacy
	) internal returns (bool) {
		bytes32 idHash = keccak256(bytes(_id));
		require(
			blockchainStates[idHash].length > 0,
			"no state found for given _id"
		);
		bytes32 stateHash = blockchainStates[idHash][
			blockchainStates[idHash].length - 1
		].stateHash;

		//this is specifically important for rootState that should update real balance only once
		require(
			stateHashBalances[stateHash][_user] == 0,
			"stateHash already proved"
		);

		bytes32 leafHash = keccak256(abi.encode(_user, _balance));
		//v2 double hash fix to prevent preimage attack
		if (legacy == false) {
			leafHash = keccak256(abi.encode(leafHash));
		}
		bool isProofValid = checkProofOrdered(
			_proof,
			_isRightNode,
			stateHash,
			leafHash,
			_nodeIndex,
			legacy == false
		);

		require(isProofValid, "invalid merkle proof");

		//if initiial state then set real balance
		if (idHash == ROOT_STATE) {
			uint256 curTotalSupply = totalSupplyLocalAt(block.number);
			// on proof for ROOT_HASH we force to ignore the repTarget, so it is the same wallet address receiving the reputation (prevent double voting power on snapshot)
			// also it should behave the same as blockchain sync proof which also doesnt use repTarget, but updates the same address as in the proof
			_mint(_user, _balance, true);

			updateValueAtNow(totalSupplyHistory, curTotalSupply); // we undo the totalsupply, as we alredy set the totalsupply of the airdrop
		}

		//if proof is valid then set balances
		stateHashBalances[stateHash][_user] = _balance;

		emit StateHashProof(_id, _user, _balance);
		return true;
	}

	/// @notice returns current delegate of _user
	/// @param _user the delegatee
	/// @return the address of the delegate (can be _user  if no delegate or 0x0 if _user doesnt exists)
	function delegateOf(address _user) public view returns (address) {
		return delegates[_user];
	}

	/// @notice delegate votes to another user
	/// @param _delegate the recipient of votes
	function delegateTo(address _delegate) public {
		return _delegateTo(_msgSender(), _delegate);
	}

	/// @notice cancel user delegation
	/// @dev makes user his own delegate
	function undelegate() public {
		return _delegateTo(_msgSender(), _msgSender());
	}

	/**
	 * @notice Delegates votes from signatory to `delegate`
	 * @param _delegate The address to delegate votes to
	 * @param _nonce The contract state required to match the signature
	 * @param _expiry The time at which to expire the signature
	 * @param _v The recovery byte of the signature
	 * @param _r Half of the ECDSA signature pair
	 * @param _s Half of the ECDSA signature pair
	 */
	function delegateBySig(
		address _delegate,
		uint256 _nonce,
		uint256 _expiry,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public {
		bytes32 domainSeparator = keccak256(
			abi.encode(
				DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				getChainId(),
				address(this)
			)
		);
		bytes32 structHash = keccak256(
			abi.encode(DELEGATION_TYPEHASH, _delegate, _nonce, _expiry)
		);
		bytes32 digest = keccak256(
			abi.encodePacked("\x19\x01", domainSeparator, structHash)
		);
		address signatory = ecrecover(digest, _v, _r, _s);
		require(
			signatory != address(0),
			"GReputation::delegateBySig: invalid signature"
		);
		require(
			_nonce == nonces[signatory]++,
			"GReputation::delegateBySig: invalid nonce"
		);
		require(
			block.timestamp <= _expiry,
			"GReputation::delegateBySig: signature expired"
		);
		return _delegateTo(signatory, _delegate);
	}

	/// @notice internal function to delegate votes to another user
	/// @param _user the source of votes (delegator)
	/// @param _delegate the recipient of votes
	function _delegateTo(address _user, address _delegate) internal {
		require(
			_delegate != address(0),
			"GReputation::delegate can't delegate to null address"
		);

		address curDelegator = delegates[_user];
		require(curDelegator != _delegate, "already delegating to delegator");

		delegates[_user] = _delegate;

		// remove votes from current delegator
		uint256 coreBalance = balanceOfLocalAt(_user, block.number);
		//redundant check - should not be possible to have address 0 as delegator
		if (curDelegator != address(0)) {
			uint256 removeVotes = getVotesAt(curDelegator, false, block.number);
			_updateDelegateVotes(
				curDelegator,
				_user,
				removeVotes,
				removeVotes - coreBalance
			);
		}

		//move votes to new delegator
		uint256 addVotes = getVotesAt(_delegate, false, block.number);
		_updateDelegateVotes(_delegate, _user, addVotes, addVotes + coreBalance);
	}

	/// @notice internal function to update delegated votes, emits event with changes
	/// @param _delegate the delegate whose record we are updating
	/// @param _delegator the delegator
	/// @param _oldVotes the delegate previous votes
	/// @param _newVotes the delegate votes after the change
	function _updateDelegateVotes(
		address _delegate,
		address _delegator,
		uint256 _oldVotes,
		uint256 _newVotes
	) internal {
		updateValueAtNow(activeVotes[_delegate], _newVotes);
		emit DelegateVotesChanged(_delegate, _delegator, _oldVotes, _newVotes);
	}

	// from StorJ -- https://github.com/nginnever/storj-audit-verifier/blob/master/contracts/MerkleVerifyv3.sol
	/**
	 * @dev non sorted merkle tree proof check
	 */
	function checkProofOrdered(
		bytes32[] memory _proof,
		bool[] memory _isRightNode,
		bytes32 _root,
		bytes32 _hash,
		uint256 _index,
		bool sorted
	) public pure returns (bool) {
		// use the index to determine the node ordering
		// index ranges 1 to n

		bytes32 proofElement;
		bytes32 computedHash = _hash;
		uint256 remaining;

		for (uint256 j = 0; j < _proof.length; j++) {
			proofElement = _proof[j];

			// for new sorted format
			if (sorted) {
				computedHash = proofElement < computedHash
					? keccak256(abi.encodePacked(proofElement, computedHash))
					: keccak256(abi.encodePacked(computedHash, proofElement));
				continue;
			}

			// start of legacy format for the first GOOD airdrop

			// calculate remaining elements in proof
			remaining = _proof.length - j;

			// we don't assume that the tree is padded to a power of 2
			// if the index is odd then the proof will start with a hash at a higher
			// layer, so we have to adjust the index to be the index at that layer
			while (remaining > 0 && _index % 2 == 1 && _index > 2**remaining) {
				_index = _index / 2 + 1;
			}

			if (
				(_isRightNode.length > 0 && _isRightNode[j] == false) ||
				(_isRightNode.length == 0 && _index % 2 == 0)
			) {
				computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
				_index = _index / 2;
			} else {
				computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
				_index = _index / 2 + 1;
			}
		}

		return computedHash == _root;
	}

	/// @notice helper function to get current chain id
	/// @return chain id
	function getChainId() internal view returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}

	function setReputationRecipient(address _target) public {
		reputationRecipients[msg.sender] = _target;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library DataTypes {
	// refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
	struct ReserveData {
		//stores the reserve configuration
		ReserveConfigurationMap configuration;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable borrow index. Expressed in ray
		uint128 variableBorrowIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable borrow rate. Expressed in ray
		uint128 currentVariableBorrowRate;
		//the current stable borrow rate. Expressed in ray
		uint128 currentStableBorrowRate;
		uint40 lastUpdateTimestamp;
		//tokens addresses
		address aTokenAddress;
		address stableDebtTokenAddress;
		address variableDebtTokenAddress;
		//address of the interest rate strategy
		address interestRateStrategyAddress;
		//the id of the reserve. Represents the position in the list of the active reserves
		uint8 id;
	}

	struct ReserveConfigurationMap {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: Reserve is active
		//bit 57: reserve is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}
	enum InterestRateMode { NONE, STABLE, VARIABLE }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./DAOContract.sol";

/**
@title Simple contract that adds upgradability to DAOContract
*/

contract DAOUpgradeableContract is Initializable, UUPSUpgradeable, DAOContract {
	function _authorizeUpgrade(address) internal virtual override {
		_onlyAvatar();
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../DAOStackInterfaces.sol";
import "../Interfaces.sol";

/**
@title Simple contract that keeps DAO contracts registery
*/

contract DAOContract {
	Controller public dao;

	address public avatar;

	INameService public nameService;

	function _onlyAvatar() internal view {
		require(
			address(dao.avatar()) == msg.sender,
			"only avatar can call this method"
		);
	}

	function setDAO(INameService _ns) internal {
		nameService = _ns;
		updateAvatar();
	}

	function updateAvatar() public {
		dao = Controller(nameService.getAddress("CONTROLLER"));
		avatar = dao.avatar();
	}

	function nativeToken() public view returns (IGoodDollar) {
		return IGoodDollar(nameService.getAddress("GOODDOLLAR"));
	}

	uint256[50] private gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../utils/DAOUpgradeableContract.sol";

/**
 * based on https://github.com/daostack/infra/blob/60a79a1be02942174e21156c3c9655a7f0695dbd/contracts/Reputation.sol
 * @title Reputation system
 * @dev A DAO has Reputation System which allows peers to rate other peers in order to build trust .
 * A reputation is used to assign influence measure to a DAO'S peers.
 * Reputation is similar to regular tokens but with one crucial difference: It is non-transferable.
 * The Reputation contract maintain a map of address to reputation value.
 * It provides an only minter role functions to mint and burn reputation _to (or _from) a specific address.
 */
contract Reputation is DAOUpgradeableContract, AccessControlUpgradeable {
	bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

	string public name;
	string public symbol;

	uint8 public decimals; //Number of decimals of the smallest unit
	// Event indicating minting of reputation to an address.
	event Mint(address indexed _to, uint256 _amount);
	// Event indicating burning of reputation for an address.
	event Burn(address indexed _from, uint256 _amount);
	uint256 private constant ZERO_HALF_256 = 0xffffffffffffffffffffffffffffffff;

	/// @dev `Checkpoint` is the structure that attaches a block number to a
	///  given value, the block number attached is the one that last changed the
	///  value
	//Checkpoint is uint256 :
	// bits 0-127 `fromBlock` is the block number that the value was generated from
	// bits 128-255 `value` is the amount of reputation at a specific block number

	// `balances` is the map that tracks the balance of each address, in this
	//  contract when the balance changes the block number that the change
	//  occurred is also included in the map
	mapping(address => uint256[]) public balances;

	// Tracks the history of the `totalSupply` of the reputation
	uint256[] public totalSupplyHistory;

	/**
	 * @dev initialize
	 */
	function initialize(INameService _ns) public initializer {
		__Reputation_init(_ns);
	}

	function __Reputation_init(INameService _ns) internal {
		decimals = 18;
		name = "GoodDAO";
		symbol = "GOOD";
		__Context_init_unchained();
		__ERC165_init_unchained();
		__AccessControl_init_unchained();

		if (address(_ns) != address(0)) {
			setDAO(_ns);
			_setupRole(DEFAULT_ADMIN_ROLE, address(avatar));
			_setupRole(MINTER_ROLE, address(avatar));
		}
	}

	function _canMint() internal view virtual {
		require(hasRole(MINTER_ROLE, _msgSender()), "Reputation: need minter role");
	}

	/// @notice Generates `_amount` reputation that are assigned to `_owner`
	/// @param _user The address that will be assigned the new reputation
	/// @param _amount The quantity of reputation generated
	/// @return True if the reputation are generated correctly
	function mint(address _user, uint256 _amount) public returns (bool) {
		_canMint();
		_mint(_user, _amount);
		return true;
	}

	function _mint(address _user, uint256 _amount)
		internal
		virtual
		returns (uint256)
	{
		uint256 curTotalSupply = totalSupplyLocalAt(block.number);
		uint256 previousBalanceTo = balanceOfLocalAt(_user, block.number);

		updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
		updateValueAtNow(balances[_user], previousBalanceTo + _amount);
		emit Mint(_user, _amount);
		return _amount;
	}

	/// @notice Burns `_amount` reputation from `_owner`
	/// @param _user The address that will lose the reputation
	/// @param _amount The quantity of reputation to burn
	/// @return True if the reputation are burned correctly
	function burn(address _user, uint256 _amount) public returns (bool) {
		//user can burn his own rep other wise we check _canMint
		if (_user != _msgSender()) _canMint();
		_burn(_user, _amount);
		return true;
	}

	function _burn(address _user, uint256 _amount)
		internal
		virtual
		returns (uint256)
	{
		uint256 curTotalSupply = totalSupplyLocalAt(block.number);
		uint256 amountBurned = _amount;
		uint256 previousBalanceFrom = balanceOfLocalAt(_user, block.number);
		if (previousBalanceFrom < amountBurned) {
			amountBurned = previousBalanceFrom;
		}
		updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
		updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
		emit Burn(_user, amountBurned);
		return amountBurned;
	}

	function balanceOfLocal(address _owner) public view returns (uint256) {
		return balanceOfLocalAt(_owner, block.number);
	}

	/// @dev Queries the balance of `_owner` at a specific `_blockNumber`
	/// @param _owner The address from which the balance will be retrieved
	/// @param _blockNumber The block number when the balance is queried
	/// @return The balance at `_blockNumber`
	function balanceOfLocalAt(address _owner, uint256 _blockNumber)
		public
		view
		virtual
		returns (uint256)
	{
		if (
			(balances[_owner].length == 0) ||
			(uint128(balances[_owner][0]) > _blockNumber)
		) {
			return 0;
			// This will return the expected balance during normal situations
		} else {
			return getValueAt(balances[_owner], _blockNumber);
		}
	}

	function totalSupplyLocal() public view virtual returns (uint256) {
		return totalSupplyLocalAt(block.number);
	}

	/// @notice Total amount of reputation at a specific `_blockNumber`.
	/// @param _blockNumber The block number when the totalSupply is queried
	/// @return The total amount of reputation at `_blockNumber`
	function totalSupplyLocalAt(uint256 _blockNumber)
		public
		view
		virtual
		returns (uint256)
	{
		if (
			(totalSupplyHistory.length == 0) ||
			(uint128(totalSupplyHistory[0]) > _blockNumber)
		) {
			return 0;
			// This will return the expected totalSupply during normal situations
		} else {
			return getValueAt(totalSupplyHistory, _blockNumber);
		}
	}

	////////////////
	// Internal helper functions to query and set a value in a snapshot array
	////////////////
	/// @dev `getValueAt` retrieves the number of reputation at a given block number
	/// @param checkpoints The history of values being queried
	/// @param _block The block number to retrieve the value at
	/// @return The number of reputation being queried
	function getValueAt(uint256[] storage checkpoints, uint256 _block)
		internal
		view
		returns (uint256)
	{
		uint256 len = checkpoints.length;
		if (len == 0) {
			return 0;
		}
		// Shortcut for the actual value
		uint256 cur = checkpoints[len - 1];
		if (_block >= uint128(cur)) {
			return cur >> 128;
		}

		if (_block < uint128(checkpoints[0])) {
			return 0;
		}

		// Binary search of the value in the array
		uint256 min = 0;
		uint256 max = len - 1;
		while (max > min) {
			uint256 mid = (max + min + 1) / 2;
			if (uint128(checkpoints[mid]) <= _block) {
				min = mid;
			} else {
				max = mid - 1;
			}
		}
		return checkpoints[min] >> 128;
	}

	/// @dev `updateValueAtNow` used to update the `balances` map and the
	///  `totalSupplyHistory`
	/// @param checkpoints The history of data being updated
	/// @param _value The new number of reputation
	function updateValueAtNow(uint256[] storage checkpoints, uint256 _value)
		internal
	{
		require(uint128(_value) == _value, "reputation overflow"); //check value is in the 128 bits bounderies
		if (
			(checkpoints.length == 0) ||
			(uint128(checkpoints[checkpoints.length - 1]) < block.number)
		) {
			checkpoints.push(uint256(uint128(block.number)) | (_value << 128));
		} else {
			checkpoints[checkpoints.length - 1] = uint256(
				(checkpoints[checkpoints.length - 1] & uint256(ZERO_HALF_256)) |
					(_value << 128)
			);
		}
	}
}

// SPDX-License-Identifier: MIT
import { DataTypes } from "./utils/DataTypes.sol";
pragma solidity >=0.8.0;

pragma experimental ABIEncoderV2;

interface ERC20 {
	function balanceOf(address addr) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);

	function decimals() external view returns (uint8);

	function mint(address to, uint256 mintAmount) external returns (uint256);

	function burn(uint256 amount) external;

	function totalSupply() external view returns (uint256);

	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes data
	);
}

interface cERC20 is ERC20 {
	function mint(uint256 mintAmount) external returns (uint256);

	function redeemUnderlying(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 mintAmount) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external view returns (uint256);

	function underlying() external returns (address);
}

interface IGoodDollar is ERC20 {
	// view functions
	function feeRecipient() external view returns (address);

	function getFees(
		uint256 value,
		address sender,
		address recipient
	) external view returns (uint256 fee, bool senderPays);

	function cap() external view returns (uint256);

	function isPauser(address _pauser) external view returns (bool);

	function getFees(uint256 value) external view returns (uint256, bool);

	function isMinter(address minter) external view returns (bool);

	function formula() external view returns (address);

	function identity() external view returns (address);

	function owner() external view returns (address);

	// state changing functions
	function setFeeRecipient(address _feeRecipient) external;

	function setFormula(address _formula) external;

	function transferOwnership(address _owner) external;

	function addPauser(address _pauser) external;

	function pause() external;

	function unpause() external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function renounceMinter() external;

	function addMinter(address minter) external;

	function transferAndCall(
		address to,
		uint256 value,
		bytes calldata data
	) external returns (bool);

	function setIdentity(address identity) external;
}

interface IERC2917 is ERC20 {
	/// @dev This emit when interests amount per block is changed by the owner of the contract.
	/// It emits with the old interests amount and the new interests amount.
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityIncreased(address indexed user, uint256 value);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityDecreased(address indexed user, uint256 value);

	/// @dev Return the current contract's interests rate per block.
	/// @return The amount of interests currently producing per each block.
	function interestsPerBlock() external view returns (uint256);

	/// @notice Change the current contract's interests rate.
	/// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
	/// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
	function changeInterestRatePerBlock(uint256 value) external returns (bool);

	/// @notice It will get the productivity of given user.
	/// @dev it will return 0 if user has no productivity proved in the contract.
	/// @return user's productivity and overall productivity.
	function getProductivity(address user)
		external
		view
		returns (uint256, uint256);

	/// @notice increase a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity added success.
	function increaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice decrease a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity removed success.
	function decreaseProductivity(address user, uint256 value)
		external
		returns (bool);

	/// @notice take() will return the interests that callee will get at current block height.
	/// @dev it will always calculated by block.number, so it will change when block height changes.
	/// @return amount of the interests that user are able to mint() at current block height.
	function take() external view returns (uint256);

	/// @notice similar to take(), but with the block height joined to calculate return.
	/// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
	/// @return amount of interests and the block height.
	function takeWithBlock() external view returns (uint256, uint256);

	/// @notice mint the avaiable interests to callee.
	/// @dev once it mint, the amount of interests will transfer to callee's address.
	/// @return the amount of interests minted.
	function mint() external returns (uint256);
}

interface Staking {
	struct Staker {
		// The staked DAI amount
		uint256 stakedDAI;
		// The latest block number which the
		// staker has staked tokens
		uint256 lastStake;
	}

	function stakeDAI(uint256 amount) external;

	function withdrawStake() external;

	function stakers(address staker) external view returns (Staker memory);
}

interface Uniswap {
	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function WETH() external pure returns (address);

	function factory() external pure returns (address);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountOut(
		uint256 amountI,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountsOut(uint256 amountIn, address[] memory path)
		external
		pure
		returns (uint256[] memory amounts);
}

interface UniswapFactory {
	function getPair(address tokenA, address tokenB)
		external
		view
		returns (address);
}

interface UniswapPair {
	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function kLast() external view returns (uint256);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);
}

interface Reserve {
	function buy(
		address _buyWith,
		uint256 _tokenAmount,
		uint256 _minReturn
	) external returns (uint256);
}

interface IIdentity {
	function isWhitelisted(address user) external view returns (bool);

	function addWhitelistedWithDID(address account, string memory did) external;

	function removeWhitelisted(address account) external;

	function addBlacklisted(address account) external;

	function removeBlacklisted(address account) external;

	function isBlacklisted(address user) external view returns (bool);

	function addIdentityAdmin(address account) external returns (bool);

	function setAvatar(address _avatar) external;

	function isIdentityAdmin(address account) external view returns (bool);

	function owner() external view returns (address);

	function removeContract(address account) external;

	function isDAOContract(address account) external view returns (bool);

	function addrToDID(address account) external view returns (string memory);

	function didHashToAddress(bytes32 hash) external view returns (address);

	function lastAuthenticated(address account) external view returns (uint256);

	event WhitelistedAdded(address user);
}

interface IIdentityV2 is IIdentity {
	function addWhitelistedWithDIDAndChain(
		address account,
		string memory did,
		uint256 orgChainId,
		uint256 dateAuthenticated
	) external;

	function getWhitelistedRoot(address account)
		external
		view
		returns (address root);
}

interface IUBIScheme {
	function currentDay() external view returns (uint256);

	function periodStart() external view returns (uint256);

	function hasClaimed(address claimer) external view returns (bool);
}

interface IFirstClaimPool {
	function awardUser(address user) external returns (uint256);

	function claimAmount() external view returns (uint256);
}

interface ProxyAdmin {
	function getProxyImplementation(address proxy)
		external
		view
		returns (address);

	function getProxyAdmin(address proxy) external view returns (address);

	function upgrade(address proxy, address implementation) external;

	function owner() external view returns (address);

	function transferOwnership(address newOwner) external;

	function upgradeAndCall(
		address proxy,
		address implementation,
		bytes memory data
	) external;
}

/**
 * @dev Interface for chainlink oracles to obtain price datas
 */
interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(uint80 _roundId)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestAnswer() external view returns (int256);
}

/**
	@dev interface for AAVE lending Pool
 */
interface ILendingPool {
	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(address asset)
		external
		view
		returns (DataTypes.ReserveData memory);
}

interface IDonationStaking {
	function stakeDonations() external payable;
}

interface INameService {
	function getAddress(string memory _name) external view returns (address);
}

interface IAaveIncentivesController {
	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(
		address[] calldata assets,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(address[] calldata assets, address user)
		external
		view
		returns (uint256);
}

interface IGoodStaking {
	function collectUBIInterest(address recipient)
		external
		returns (
			uint256,
			uint256,
			uint256
		);

	function iToken() external view returns (address);

	function currentGains(
		bool _returnTokenBalanceInUSD,
		bool _returnTokenGainsInUSD
	)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		);

	function getRewardEarned(address user) external view returns (uint256);

	function getGasCostForInterestTransfer() external view returns (uint256);

	function rewardsMinted(
		address user,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) external returns (uint256);
}

interface IHasRouter {
	function getRouter() external view returns (Uniswap);
}

interface IAdminWallet {
	function addAdmins(address payable[] memory _admins) external;

	function removeAdmins(address[] memory _admins) external;

	function owner() external view returns (address);

	function transferOwnership(address _owner) external;
}

interface IMultichainRouter {
	// Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to`
	function anySwapOut(
		address token,
		address to,
		uint256 amount,
		uint256 toChainID
	) external;

	// Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to`
	function anySwapOutUnderlying(
		address token,
		address to,
		uint256 amount,
		uint256 toChainID
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface Avatar {
	function nativeToken() external view returns (address);

	function nativeReputation() external view returns (address);

	function owner() external view returns (address);
}

interface Controller {
	event RegisterScheme(address indexed _sender, address indexed _scheme);
	event UnregisterScheme(address indexed _sender, address indexed _scheme);

	function genericCall(
		address _contract,
		bytes calldata _data,
		address _avatar,
		uint256 _value
	) external returns (bool, bytes memory);

	function avatar() external view returns (address);

	function unregisterScheme(address _scheme, address _avatar)
		external
		returns (bool);

	function unregisterSelf(address _avatar) external returns (bool);

	function registerScheme(
		address _scheme,
		bytes32 _paramsHash,
		bytes4 _permissions,
		address _avatar
	) external returns (bool);

	function isSchemeRegistered(address _scheme, address _avatar)
		external
		view
		returns (bool);

	function getSchemePermissions(address _scheme, address _avatar)
		external
		view
		returns (bytes4);

	function addGlobalConstraint(
		address _constraint,
		bytes32 _paramHash,
		address _avatar
	) external returns (bool);

	function mintTokens(
		uint256 _amount,
		address _beneficiary,
		address _avatar
	) external returns (bool);

	function externalTokenTransfer(
		address _token,
		address _recipient,
		uint256 _amount,
		address _avatar
	) external returns (bool);

	function sendEther(
		uint256 _amountInWei,
		address payable _to,
		address _avatar
	) external returns (bool);
}

interface GlobalConstraintInterface {
	enum CallPhase {
		Pre,
		Post,
		PreAndPost
	}

	function pre(
		address _scheme,
		bytes32 _params,
		bytes32 _method
	) external returns (bool);

	/**
	 * @dev when return if this globalConstraints is pre, post or both.
	 * @return CallPhase enum indication  Pre, Post or PreAndPost.
	 */
	function when() external returns (CallPhase);
}

interface ReputationInterface {
	function balanceOf(address _user) external view returns (uint256);

	function balanceOfAt(address _user, uint256 _blockNumber)
		external
		view
		returns (uint256);

	function getVotes(address _user) external view returns (uint256);

	function getVotesAt(
		address _user,
		bool _global,
		uint256 _blockNumber
	) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function totalSupplyAt(uint256 _blockNumber)
		external
		view
		returns (uint256);

	function delegateOf(address _user) external returns (address);
}

interface SchemeRegistrar {
	function proposeScheme(
		Avatar _avatar,
		address _scheme,
		bytes32 _parametersHash,
		bytes4 _permissions,
		string memory _descriptionHash
	) external returns (bytes32);

	event NewSchemeProposal(
		address indexed _avatar,
		bytes32 indexed _proposalId,
		address indexed _intVoteInterface,
		address _scheme,
		bytes32 _parametersHash,
		bytes4 _permissions,
		string _descriptionHash
	);
}

interface IntVoteInterface {
	event NewProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		uint256 _numOfChoices,
		address _proposer,
		bytes32 _paramsHash
	);

	event ExecuteProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		uint256 _decision,
		uint256 _totalReputation
	);

	event VoteProposal(
		bytes32 indexed _proposalId,
		address indexed _organization,
		address indexed _voter,
		uint256 _vote,
		uint256 _reputation
	);

	event CancelProposal(
		bytes32 indexed _proposalId,
		address indexed _organization
	);
	event CancelVoting(
		bytes32 indexed _proposalId,
		address indexed _organization,
		address indexed _voter
	);

	/**
	 * @dev register a new proposal with the given parameters. Every proposal has a unique ID which is being
	 * generated by calculating keccak256 of a incremented counter.
	 * @param _numOfChoices number of voting choices
	 * @param _proposalParameters defines the parameters of the voting machine used for this proposal
	 * @param _proposer address
	 * @param _organization address - if this address is zero the msg.sender will be used as the organization address.
	 * @return proposal's id.
	 */
	function propose(
		uint256 _numOfChoices,
		bytes32 _proposalParameters,
		address _proposer,
		address _organization
	) external returns (bytes32);

	function vote(
		bytes32 _proposalId,
		uint256 _vote,
		uint256 _rep,
		address _voter
	) external returns (bool);

	function cancelVote(bytes32 _proposalId) external;

	function getNumberOfChoices(bytes32 _proposalId)
		external
		view
		returns (uint256);

	function isVotable(bytes32 _proposalId) external view returns (bool);

	/**
	 * @dev voteStatus returns the reputation voted for a proposal for a specific voting choice.
	 * @param _proposalId the ID of the proposal
	 * @param _choice the index in the
	 * @return voted reputation for the given choice
	 */
	function voteStatus(bytes32 _proposalId, uint256 _choice)
		external
		view
		returns (uint256);

	/**
	 * @dev isAbstainAllow returns if the voting machine allow abstain (0)
	 * @return bool true or false
	 */
	function isAbstainAllow() external pure returns (bool);

	/**
     * @dev getAllowedRangeOfChoices returns the allowed range of choices for a voting machine.
     * @return min - minimum number of choices
               max - maximum number of choices
     */
	function getAllowedRangeOfChoices()
		external
		pure
		returns (uint256 min, uint256 max);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}