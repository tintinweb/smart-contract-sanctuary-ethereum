/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

// ----------------------------------------------------------------------------
// 'TELE' token governance smart contract
//
// Symbol      : TELE
// Name        : Telefy
// Max Total Circulating supply: 1000000000
// Decimals    : 18
//
//
//
// (c) by Telefy Technologies Private Limited.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
contract SafeMath {
	function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		require(c >= a, "SafeMath: addition overflow");
	}

	function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b <= a, "SafeMath: subtraction overflow");
		c = a - b;
	}

	function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		if (a == 0) {
			c = 0;
		} else {
			c = a * b;
		}
		require((a == 0 || c / a == b), "SafeMath: multiplication overflow");
	}

	function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b > 0, "SafeMath: division by zero");
		c = a / b;
	}

	function safeMod(uint256 a, uint256 b) internal pure returns (uint256 c) {
		require(b != 0, "SafeMath: modulo by zero");
		c = a % b;
	}
}

// ----------------------------------------------------------------------------
// Information of context: Sender and Data
// ----------------------------------------------------------------------------
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this; // Warning: silence state mutability without generating bytecode
		return msg.data;
	}
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
	function totalSupply() public view virtual returns (uint256);

	function balanceOf(address tokenOwner) public view virtual returns (uint256 balance);

	function allowance(address tokenOwner, address spender)
		public
		view
		virtual
		returns (uint256 remaining);

	function transfer(address to, uint256 tokens) external virtual returns (bool success);

	function approve(address spender, uint256 tokens) public virtual returns (bool success);

	function transferFrom(
		address from,
		address to,
		uint256 tokens
	) external virtual returns (bool success);

	event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
abstract contract ApproveAndCallFallBack {
	function receiveApproval(
		address from,
		uint256 tokens,
		address token,
		bytes memory data
	) public virtual;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed _from, address indexed _to);

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address _newOwner) external onlyOwner {
		newOwner = _newOwner;
	}

	function acceptOwnership() external {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}

// ----------------------------------------------------------------------------
// @dev Collection of functions related to the address type
// @openzeppelin/contracts/utils/Address.sol
// ----------------------------------------------------------------------------
library Address {
	// ----------------------------------------------------------------------------
	// @dev Returns true if `account` is a contract.
	//
	// [IMPORTANT]
	// It is unsafe to assume that an address for which this function returns
	// false is an externally-owned account (EOA) and not a contract.
	//
	// Among others, `isContract` will return false for the following
	// types of addresses:
	//
	//  - an externally-owned account
	//  - a contract in construction
	//  - an address where a contract will be created
	//  - an address where a contract lived, but was destroyed
	// ----------------------------------------------------------------------------
	function isContract(address account) internal view returns (bool) {
		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		// solhint-disable-next-line no-inline-assembly
		assembly {
			codehash := extcodehash(account)
		}
		return (codehash != accountHash && codehash != 0x0);
	}

	// ----------------------------------------------------------------------------
	// @dev Replacement for Solidity's `transfer`: sends `amount` wei to
	// `recipient`, forwarding all available gas and reverting on errors.
	//
	// https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
	// of certain opcodes, possibly making contracts go over the 2300 gas limit
	// imposed by `transfer`, making them unable to receive funds via
	// `transfer`. {sendValue} removes this limitation.
	//
	// https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
	//
	// IMPORTANT: because control is transferred to `recipient`, TELEe must be
	// taken to not create reentrancy vulnerabilities. Consider using
	// {ReentrancyGuard} or the
	// https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
	// ----------------------------------------------------------------------------
	function sendValue(address payable recipient, uint256 amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");

		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	// ----------------------------------------------------------------------------
	// @dev Performs a Solidity function call using a low level `call`. A
	// plain`call` is an unsafe replacement for a function call: use this
	// function instead.
	//
	// If `target` reverts with a revert reason, it is bubbled up by this
	// function (like regular Solidity function calls).
	//
	// Returns the raw returned data. To convert to the expected return value,
	// use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
	// _Available since v3.1._
	// ----------------------------------------------------------------------------
	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionCall(target, data, "Address: low-level call failed");
	}

	// ----------------------------------------------------------------------------
	// @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	// `errorMessage` as a fallback revert reason when `target` reverts.
	// _Available since v3.1._
	// ----------------------------------------------------------------------------
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return _functionCallWithValue(target, data, 0, errorMessage);
	}

	// ----------------------------------------------------------------------------
	// @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	// but also transferring `value` wei to `target`.
	// _Available since v3.1._
	// ----------------------------------------------------------------------------
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
			functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	// ----------------------------------------------------------------------------
	// @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	// with `errorMessage` as a fallback revert reason when `target` reverts.
	// _Available since v3.1._
	// ----------------------------------------------------------------------------
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		return _functionCallWithValue(target, data, value, errorMessage);
	}

	function _functionCallWithValue(
		address target,
		bytes memory data,
		uint256 weiValue,
		string memory errorMessage
	) private returns (bytes memory) {
		require(isContract(target), "Address: call to non-contract");

		// solhint-disable-next-line avoid-low-level-calls
		(bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				// solhint-disable-next-line no-inline-assembly
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

// ----------------------------------------------------------------------------
// TELE Token, with the addition of symbol, name and decimals and assisted
// token transfers
// TELE is Governance token for TELEFY
// ----------------------------------------------------------------------------
contract TELEToken is ERC20Interface, Owned, SafeMath, Context {
	using Address for address;

	string public symbol;
	string public name;
	uint8 public decimals;
	uint256 private _totalSupply;
	address private _minter;

	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) allowed;

	/// @notice The timestamp after which minting may occur
	uint256 public mintingAllowedAfter;

	/// @notice Minimum time between mints
	uint32 public constant minimumTimeBetweenMints = 1 days * 7;

	/// @notice Cap on the percentage of totalSupply that can be minted at each mint
	/// We are going to divide this by 1000. so below is 0.2 percent of totalSupply
	uint8 public constant mintCap = 2;

	/// @notice A record of each accounts delegate
	mapping(address => address) internal _delegates;

	/// @notice A checkpoint for marking number of votes from a given block
	struct Checkpoint {
		uint32 fromBlock;
		uint256 votes;
	}

	/// @notice A record of votes checkpoints for each account, by index
	mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

	/// @notice The number of checkpoints for each account
	mapping(address => uint32) public numCheckpoints;

	/// @notice The EIP-712 typehash for the contract's domain
	bytes32 public constant DOMAIN_TYPEHASH =
		keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

	/// @notice The EIP-712 typehash for the delegation struct used by the contract
	bytes32 public constant DELEGATION_TYPEHASH =
		keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

	/// @notice The EIP-712 typehash for the permit struct used by the contract
	bytes32 public constant PERMIT_TYPEHASH =
		keccak256(
			"Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
		);

	/// @notice A record of states for signing / validating signatures
	mapping(address => uint256) public nonces;

	// @notice An event thats emitted when multiple transactions made
	event TransferMultiple(address indexed from, address[] indexed to, uint256[] tokens);

	/// @notice An event thats emitted when an account changes its delegate
	event DelegateChanged(
		address indexed delegator,
		address indexed fromDelegate,
		address indexed toDelegate
	);

	/// @notice An event thats emitted when a delegate account's vote balance changes
	event DelegateVotesChanged(
		address indexed delegate,
		uint256 previousBalance,
		uint256 newBalance
	);

	// @notice An event thats emitted when the minter address is changed
	event MinterChanged(address minter, address newMinter);

	// ------------------------------------------------------------------------
	// Constructor
	///**
     //* @notice Construct a new TELE token
     //* @param account The initial account to grant all the tokens
     //* @param minter_ The account with minting ability
     //* @param mintingAllowedAfter_ The timestamp after which minting may occur
     //*
	// ------------------------------------------------------------------------
	constructor() {
		symbol = "TELE";
		name = "Telefy";
		decimals = 18;
		_totalSupply = 600_000_000e18;
		balances[owner] = _totalSupply;
		emit Transfer(address(0), owner, _totalSupply);
		_minter = 0xa270dA3c3175ED9992c9Ad3B6Bb679Bf81c35BA8;
		mintingAllowedAfter = safeAdd(block.timestamp, minimumTimeBetweenMints);
	}

	// ------------------------------------------------------------------------
	// Total supply
	// ------------------------------------------------------------------------
	function totalSupply() public view override returns (uint256) {
		return safeSub(_totalSupply, balances[address(0)]);
	}

	// ------------------------------------------------------------------------
	// Get the token balance for account tokenOwner
	// ------------------------------------------------------------------------
	function balanceOf(address tokenOwner) public view override returns (uint256 balance) {
		return balances[tokenOwner];
	}

	// ------------------------------------------------------------------------
	// Transfer the balance from token owner's account to to account
	// - Owner's account must have sufficient balance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transfer(address to, uint256 tokens) external override returns (bool success) {
		require(to != address(0), "TELE: transfer to the zero address");
		_transferTokens(to, tokens);
		emit Transfer(_msgSender(), to, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Transfer the balance from token owner's account to to multiple accounts
	// - Owner's account must have sufficient balance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transferMultiple(address[] memory to, uint256[] memory tokens)
		external
		returns (bool success)
	{
		require(
			to.length == tokens.length,
			"TELE: number of receiver addresses and number of amounts should be equal"
		);
		for (uint256 i = 0; i < to.length; i++) {
			if (to[i] != address(0)) {
				_transferTokens(to[i], tokens[i]);
			}
		}
		emit TransferMultiple(_msgSender(), to, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Token owner can approve for spender to transferFrom(...) tokens
	// from the token owner's account
	//
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
	// recommends that there are no checks for the approval double-spend attack
	// as this should be implemented in user interfaces
	// ------------------------------------------------------------------------
	function approve(address spender, uint256 tokens) public override returns (bool success) {
		require(spender != address(0), "TELE: transfer to the zero address");
		allowed[_msgSender()][spender] = tokens;
		emit Approval(_msgSender(), spender, tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// @notice Triggers an approval from owner to spends
	// @param owner The address to approve from
	// @param spender The address to be approved
	// @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
	// @param deadline The time at which to expire the signature
	// @param v The recovery byte of the signature
	// @param r Half of the ECDSA signature pair
	// @param s Half of the ECDSA signature pair
	// ------------------------------------------------------------------------
	function permit(
		address owner,
		address spender,
		uint256 rawAmount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		bytes32 domainSeparator = keccak256(
			abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
		);
		bytes32 structHash = keccak256(
			abi.encode(PERMIT_TYPEHASH, owner, spender, rawAmount, nonces[owner]++, deadline)
		);
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
		address signatory = ecrecover(digest, v, r, s);
		require(signatory != address(0), "TELE::permit: invalid signature");
		require(signatory == owner, "TELE::permit: unauthorized");
		require(block.timestamp <= deadline, "TELE::permit: signature expired");

		allowed[owner][spender] = rawAmount;

		emit Approval(owner, spender, rawAmount);
	}

	// ------------------------------------------------------------------------
	// Transfer tokens from the from account to the to account
	//
	// The calling account must already have sufficient tokens approve(...)-d
	// for spending from the from account and
	// - From account must have sufficient balance to transfer
	// - Spender must have sufficient allowance to transfer
	// - 0 value transfers are allowed
	// ------------------------------------------------------------------------
	function transferFrom(
		address from,
		address to,
		uint256 tokens
	) external override returns (bool success) {
		balances[from] = safeSub(balances[from], tokens);
		allowed[from][_msgSender()] = safeSub(allowed[from][_msgSender()], tokens);
		emit Approval(from, to, tokens);
		balances[to] = safeAdd(balances[to], tokens);
		emit Transfer(from, to, tokens);
		_moveDelegates(_delegates[from], _delegates[to], tokens);
		return true;
	}

	// ------------------------------------------------------------------------
	// Returns the amount of tokens approved by the owner that can be
	// transferred to the spender's account
	// ------------------------------------------------------------------------
	function allowance(address tokenOwner, address spender)
		public
		view
		override
		returns (uint256 remaining)
	{
		return allowed[tokenOwner][spender];
	}

	// ------------------------------------------------------------------------
	// @dev Atomically increases the allowance granted to `spender` by the caller.
	// This is an alternative to {approve} that can be used as a mitigation for
	// problems described in {IERC20-approve}.
	// Emits an {Approval} event indicating the updated allowance.
	// ------------------------------------------------------------------------
	function increaseAllowance(address spender, uint256 addedValue)
		external
		virtual
		returns (bool)
	{
		approve(spender, safeAdd(allowed[_msgSender()][spender], addedValue));
		return true;
	}

	// ------------------------------------------------------------------------
	// @dev Atomically decreases the allowance granted to `spender` by the caller.
	// This is an alternative to {approve} that can be used as a mitigation for
	// problems described in {IERC20-approve}.
	// Emits an {Approval} event indicating the updated allowance.
	// ------------------------------------------------------------------------
	function decreaseAllowance(address spender, uint256 subtractedValue)
		external
		virtual
		returns (bool)
	{
		approve(spender, safeSub(allowed[_msgSender()][spender], subtractedValue));
		return true;
	}

	// ------------------------------------------------------------------------
	// Token owner can approve for spender to transferFrom(...) tokens
	// from the token owner's account. The spender contract function
	// receiveApproval(...) is then executed
	// ------------------------------------------------------------------------
	function approveAndCall(
		address spender,
		uint256 tokens,
		bytes memory data
	) external returns (bool success) {
		allowed[_msgSender()][spender] = tokens;
		emit Approval(_msgSender(), spender, tokens);
		ApproveAndCallFallBack(spender).receiveApproval(_msgSender(), tokens, address(this), data);
		return true;
	}

	// ------------------------------------------------------------------------
	// Owner can transfer out any accidentally sent ERC20 tokens
	// ------------------------------------------------------------------------
	function transferAnyERC20Token(address tokenAddress, uint256 tokens)
		external
		onlyOwner
		returns (bool success)
	{
		return ERC20Interface(tokenAddress).transfer(owner, tokens);
	}

	// ------------------------------------------------------------------------
	// @dev Destroys `amount` tokens from `account`'s allowance, reducing the
	// total supply which requires approval from user before this action can be performed.
	// Emits a {Transfer} event with `to` set to the zero address.
	// ------------------------------------------------------------------------
	function burn(address account, uint256 amount) external {
		require(_msgSender() == _minter, "TELE::burn: only the minter can mint");
		require(account != address(0), "TELE: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		balances[account] = safeSub(balances[account], amount);

		// Sets `amount` as the allowance of `spender`
		allowed[account][_msgSender()] = safeSub(allowed[account][_msgSender()], amount);
		emit Approval(account, _msgSender(), amount);

		_totalSupply = safeSub(_totalSupply, amount);
		emit Transfer(account, address(0), amount);
		_moveDelegates(address(0), _delegates[account], amount);
	}

	// ------------------------------------------------------------------------
	// @dev Creates `amount` tokens and assigns them to `account`, increasing
	// the total supply.
	// Emits a {Transfer} event with `from` set to the zero address.
	// ------------------------------------------------------------------------
	function mint(address account, uint256 amount) external {
		require(_msgSender() == _minter, "TELE::mint: only the minter can mint");
		require(block.timestamp >= mintingAllowedAfter, "TELE::mint: minting not allowed yet");
		require(account != address(0), "TELE: mint to the zero address");

		// record the mint
		mintingAllowedAfter = safeAdd(block.timestamp, minimumTimeBetweenMints);

		_beforeTokenTransfer(address(0), account, amount);

		// mint amount should not exceed mint cap
		require(amount <= safeDiv(safeMul(_totalSupply, mintCap), 1000));
		_totalSupply = safeAdd(_totalSupply, amount);
		balances[account] = safeAdd(balances[account], amount);
		emit Transfer(address(0), account, amount);
		_moveDelegates(address(0), _delegates[account], amount);
	}

	// ------------------------------------------------------------------------
	// @notice Change the minter address
	// @param minter_ The address of the new minter
	// ------------------------------------------------------------------------
	function setMinter(address minter_) external {
		require(
			_msgSender() == _minter,
			"TELE::setMinter: only the minter can change the minter address"
		);
		emit MinterChanged(_minter, minter_);
		_minter = minter_;
	}

	// ------------------------------------------------------------------------
	// @notice Delegate votes from `msg.sender` to `delegatee`
	// @param delegator The address to get delegatee for
	// ------------------------------------------------------------------------
	function delegates(address delegator) external view returns (address) {
		return _delegates[delegator];
	}

	// ------------------------------------------------------------------------
	// @notice Delegate votes from `msg.sender` to `delegatee`
	// @param delegatee The address to delegate votes to
	// ------------------------------------------------------------------------
	function delegate(address delegatee) external {
		return _delegate(_msgSender(), delegatee);
	}

	// ------------------------------------------------------------------------
	// @notice Delegates votes from signatory to `delegatee`
	// @param delegatee The address to delegate votes to
	// @param nonce The contract state required to match the signature
	// @param expiry The time at which to expire the signature
	// @param v The recovery byte of the signature
	// @param r Half of the ECDSA signature pair
	// @param s Half of the ECDSA signature pair
	// ------------------------------------------------------------------------
	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external {
		bytes32 domainSeparator = keccak256(
			abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
		);

		bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));

		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

		address signatory = ecrecover(digest, v, r, s);
		require(signatory != address(0), "TELE::delegateBySig: invalid signature");
		require(nonce == nonces[signatory]++, "TELE::delegateBySig: invalid nonce");
		require(block.timestamp <= expiry, "TELE::delegateBySig: signature expired");
		return _delegate(signatory, delegatee);
	}

	// ------------------------------------------------------------------------
	// @notice Gets the current votes balance for `account`
	// @param account The address to get votes balance
	// @return The number of current votes for `account`
	// ------------------------------------------------------------------------
	function getCurrentVotes(address account) external view returns (uint256) {
		uint32 nCheckpoints = numCheckpoints[account];
		return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
	}

	// ------------------------------------------------------------------------
	// @notice Determine the prior number of votes for an account as of a block number
	// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
	// @param account The address of the account to check
	// @param blockNumber The block number to get the vote balance at
	// @return The number of votes the account had as of the given block
	// ------------------------------------------------------------------------
	function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256) {
		require(blockNumber < block.number, "TELE::getPriorVotes: not yet determined");

		uint32 nCheckpoints = numCheckpoints[account];
		if (nCheckpoints == 0) {
			return 0;
		}

		// First check most recent balance
		if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
			return checkpoints[account][nCheckpoints - 1].votes;
		}

		// Next check implicit zero balance
		if (checkpoints[account][0].fromBlock > blockNumber) {
			return 0;
		}

		uint32 lower = 0;
		uint32 upper = nCheckpoints - 1;
		while (upper > lower) {
			uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
			Checkpoint memory cp = checkpoints[account][center];
			if (cp.fromBlock == blockNumber) {
				return cp.votes;
			} else if (cp.fromBlock < blockNumber) {
				lower = center;
			} else {
				upper = center - 1;
			}
		}
		return checkpoints[account][lower].votes;
	}

	function _transferTokens(address to, uint256 tokens) internal {
		balances[_msgSender()] = safeSub(balances[_msgSender()], tokens);
		balances[to] = safeAdd(balances[to], tokens);
		_moveDelegates(_delegates[_msgSender()], _delegates[to], tokens);
	}

	function _delegate(address delegator, address delegatee) internal {
		address currentDelegate = _delegates[delegator];
		uint256 delegatorBalance = balanceOf(delegator); // balance of underlying TELEs (not scaled);
		_delegates[delegator] = delegatee;

		emit DelegateChanged(delegator, currentDelegate, delegatee);

		_moveDelegates(currentDelegate, delegatee, delegatorBalance);
	}

	function _moveDelegates(
		address srcRep,
		address dstRep,
		uint256 amount
	) internal {
		if (srcRep != dstRep && amount > 0) {
			if (srcRep != address(0)) {
				// decrease old representative
				uint32 srcRepNum = numCheckpoints[srcRep];
				uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
				uint256 srcRepNew = safeSub(srcRepOld, amount);
				_writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
			}

			if (dstRep != address(0)) {
				// increase new representative
				uint32 dstRepNum = numCheckpoints[dstRep];
				uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
				uint256 dstRepNew = safeAdd(dstRepOld, amount);
				_writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
			}
		}
	}

	function _writeCheckpoint(
		address delegatee,
		uint32 nCheckpoints,
		uint256 oldVotes,
		uint256 newVotes
	) internal {
		uint32 blockNumber = safe32(
			block.number,
			"TELE::_writeCheckpoint: block number exceeds 32 bits"
		);

		if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
			checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
		} else {
			checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
			numCheckpoints[delegatee] = nCheckpoints + 1;
		}

		emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
	}

	function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
		require(n < 2**32, errorMessage);
		return uint32(n);
	}

	function getChainId() internal view returns (uint256) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		return chainId;
	}

	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}