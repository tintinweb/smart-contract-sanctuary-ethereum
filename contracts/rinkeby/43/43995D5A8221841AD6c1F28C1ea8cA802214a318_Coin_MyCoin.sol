/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : ERC20 Minting
*/

// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view returns (uint256);

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transfer(address recipient, uint256 amount) external returns (bool);

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
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

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
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */



/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
	/**
	 * @dev Returns the name of the token.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the symbol of the token.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Returns the decimals places of the token.
	 */
	function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
	mapping(address => uint256) private _balances;

	mapping(address => mapping(address => uint256)) private _allowances;

	uint256 private _totalSupply;

	string private _name;
	string private _symbol;

	/**
	 * @dev Sets the values for {name} and {symbol}.
	 *
	 * The default value of {decimals} is 18. To select a different value for
	 * {decimals} you should overload it.
	 *
	 * All two of these values are immutable: they can only be set once during
	 * construction.
	 */
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	/**
	 * @dev Returns the name of the token.
	 */
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	/**
	 * @dev Returns the symbol of the token, usually a shorter version of the
	 * name.
	 */
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev Returns the number of decimals used to get its user representation.
	 * For example, if `decimals` equals `2`, a balance of `505` tokens should
	 * be displayed to a user as `5.05` (`505 / 10 ** 2`).
	 *
	 * Tokens usually opt for a value of 18, imitating the relationship between
	 * Ether and Wei. This is the value {ERC20} uses, unless this function is
	 * overridden;
	 *
	 * NOTE: This information is only used for _display_ purposes: it in
	 * no way affects any of the arithmetic of the contract, including
	 * {IERC20-balanceOf} and {IERC20-transfer}.
	 */
	function decimals() public view virtual override returns (uint8) {
		return 18;
	}

	/**
	 * @dev See {IERC20-totalSupply}.
	 */
	function totalSupply() public view virtual override returns (uint256) {
		return _totalSupply;
	}

	/**
	 * @dev See {IERC20-balanceOf}.
	 */
	function balanceOf(address account) public view virtual override returns (uint256) {
		return _balances[account];
	}

	/**
	 * @dev See {IERC20-transfer}.
	 *
	 * Requirements:
	 *
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.
	 */
	function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-allowance}.
	 */
	function allowance(address owner, address spender) public view virtual override returns (uint256) {
		return _allowances[owner][spender];
	}

	/**
	 * @dev See {IERC20-approve}.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function approve(address spender, uint256 amount) public virtual override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	/**
	 * @dev See {IERC20-transferFrom}.
	 *
	 * Emits an {Approval} event indicating the updated allowance. This is not
	 * required by the EIP. See the note at the beginning of {ERC20}.
	 *
	 * Requirements:
	 *
	 * - `sender` and `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 * - the caller must have allowance for ``sender``'s tokens of at least
	 * `amount`.
	 */
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public virtual override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = _allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}

		return true;
	}

	/**
	 * @dev Atomically increases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 */
	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	/**
	 * @dev Atomically decreases the allowance granted to `spender` by the caller.
	 *
	 * This is an alternative to {approve} that can be used as a mitigation for
	 * problems described in {IERC20-approve}.
	 *
	 * Emits an {Approval} event indicating the updated allowance.
	 *
	 * Requirements:
	 *
	 * - `spender` cannot be the zero address.
	 * - `spender` must have allowance for the caller of at least
	 * `subtractedValue`.
	 */
	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		uint256 currentAllowance = _allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	/**
	 * @dev Moves `amount` of tokens from `sender` to `recipient`.
	 *
	 * This internal function is equivalent to {transfer}, and can be used to
	 * e.g. implement automatic token fees, slashing mechanisms, etc.
	 *
	 * Emits a {Transfer} event.
	 *
	 * Requirements:
	 *
	 * - `sender` cannot be the zero address.
	 * - `recipient` cannot be the zero address.
	 * - `sender` must have a balance of at least `amount`.
	 */
	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual {
		require(sender != address(0), "ERC20: transfer from the zero address");
		require(recipient != address(0), "ERC20: transfer to the zero address");

		_beforeTokenTransfer(sender, recipient, amount);

		uint256 senderBalance = _balances[sender];
		require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
		unchecked {
			_balances[sender] = senderBalance - amount;
		}
		_balances[recipient] += amount;

		emit Transfer(sender, recipient, amount);

		_afterTokenTransfer(sender, recipient, amount);
	}

	/** @dev Creates `amount` tokens and assigns them to `account`, increasing
	 * the total supply.
	 *
	 * Emits a {Transfer} event with `from` set to the zero address.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 */
	function _mint(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: mint to the zero address");

		_beforeTokenTransfer(address(0), account, amount);

		_totalSupply += amount;
		_balances[account] += amount;
		emit Transfer(address(0), account, amount);

		_afterTokenTransfer(address(0), account, amount);
	}

	/**
	 * @dev Destroys `amount` tokens from `account`, reducing the
	 * total supply.
	 *
	 * Emits a {Transfer} event with `to` set to the zero address.
	 *
	 * Requirements:
	 *
	 * - `account` cannot be the zero address.
	 * - `account` must have at least `amount` tokens.
	 */
	function _burn(address account, uint256 amount) internal virtual {
		require(account != address(0), "ERC20: burn from the zero address");

		_beforeTokenTransfer(account, address(0), amount);

		uint256 accountBalance = _balances[account];
		require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
		unchecked {
			_balances[account] = accountBalance - amount;
		}
		_totalSupply -= amount;

		emit Transfer(account, address(0), amount);

		_afterTokenTransfer(account, address(0), amount);
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
	 *
	 * This internal function is equivalent to `approve`, and can be used to
	 * e.g. set automatic allowances for certain subsystems, etc.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
	 * - `spender` cannot be the zero address.
	 */
	function _approve(
		address owner,
		address spender,
		uint256 amount
	) internal virtual {
		require(owner != address(0), "ERC20: approve from the zero address");
		require(spender != address(0), "ERC20: approve to the zero address");

		_allowances[owner][spender] = amount;
		emit Approval(owner, spender, amount);
	}

	/**
	 * @dev Hook that is called before any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * will be transferred to `to`.
	 * - when `from` is zero, `amount` tokens will be minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}

	/**
	 * @dev Hook that is called after any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
	 * has been transferred to `to`.
	 * - when `from` is zero, `amount` tokens have been minted for `to`.
	 * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual {}
}
/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract Coin_MyCoin is ERC20 {

	address owner;
	event Burn (address account);
	bool public _paused = false;
	event Paused (address account);
	event Unpaused (address account);
	event Mint (address mintBy);
	event MintPhase (uint256 mintPhase);
	uint256 public whichMintPhase = 1;
	bool public mintPriceOverride1_Native = false;
	uint256 public newMintPrice1_Native = 0;
	event MintPriceOverride1_Native (bool isOverride, uint256 newPrice);
	mapping(address => uint256) public mintClaims1;
	bytes32 public merkleRoot1 = 0xd5ca9797dad784d3073ffa876ef3e8831d9383d7bf7d644f10edbd04130675f3;
	bool public mintPriceOverride2_Native = false;
	uint256 public newMintPrice2_Native = 0;
	event MintPriceOverride2_Native (bool isOverride, uint256 newPrice);

	constructor() ERC20("MCT", "MyCoin") {
		owner = msg.sender;
		super._mint(msg.sender, 123000000000000000000);
		super._mint(address(0x82137f52C632043410Fcc95C17254CDaE1E93824), 321000000000000000000);
	}

	//This function allows the owner to specify an address that will take over ownership rights instead. Please double check the address provided as once the function is executed, only the new owner will be able to change the address back.
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	//This function allows the owner to change the value of whichMintPhase.
	function changeValueOf_whichMintPhase (uint256 _whichMintPhase) external onlyOwner {
		 whichMintPhase = _whichMintPhase;
	}

	//This function allows the owner to change the value of merkleRoot1.
	function changeValueOf_merkleRoot1 (bytes32 _merkleRoot1) external onlyOwner {
		 merkleRoot1 = _merkleRoot1;
	}

/**
 * Function burn
 * The function takes in 1 variable, zero or a positive integer _amount. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that not _paused
 * calls super._burn with variable account as the address that called this function, variable amount as _amount
 * emits event Burn with inputs the address that called this function
*/
	function burn(uint256 _amount) public {
		require(!(_paused), "Pausable: paused");
		super._burn(msg.sender, _amount);
		emit Burn(msg.sender);
	}

/**
 * Function transfer
 * The function takes in 2 variables, an address receipient, and zero or a positive integer _amount. It can be called by functions both inside and outside of this contract. It does the following :
 * calls super.transfer with variable receipient as receipient, variable amount as _amount * (100 - 2)/100
 * calls super._burn with variable account as the address that called this function, variable amount as _amount * 2/100
 * returns true as output
 * This function overrides the original transfer.
*/
	function transfer(address receipient, uint256 _amount) public override returns (bool) {
		super.transfer(receipient, _amount * (100 - 2)/100);
		super._burn(msg.sender, _amount * 2/100);
		return true;
	}

/**
 * Function ownerMint
 * The function takes in 1 variable, zero or a positive integer _amount. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls super._mint with variable account as the address that called this function, variable amount as _amount
*/
	function ownerMint(uint256 _amount) public onlyOwner {
		super._mint(msg.sender, _amount);
	}

/**
 * Function changeMintPhase
 * The function takes in 1 variable, zero or a positive integer _whichMintPhase. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * updates whichMintPhase as _whichMintPhase
 * emits event MintPhase with inputs _whichMintPhase
*/
	function changeMintPhase(uint256 _whichMintPhase) public onlyOwner {
		whichMintPhase  = _whichMintPhase;
		emit MintPhase(_whichMintPhase);
	}

/**
 * Function mint1
 * The function takes in 2 variables, an address _mintFor, and a merkle proof _merkleProof. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called before Date 1659196800
 * checks that not _paused
 * checks that whichMintPhase is equals to 1
 * checks that ((totalSupply) + (2000000000000000000)) is less than or equals to 8000000000000000000000
 * checks that ((balanceOf with variable account as (the address that called this function)) + (2000000000000000000)) is less than or equals to 1999000000000000000000
 * checks that (amount of native currency sent to contract) is equals to ((2000000000000000000) * ((if mintPriceOverride1_Native then newMintPrice1_Native else 100000000000000) / (10 raised to the power of 18)))
 * checks that ((mintClaims1 with element the address that called this function) + (1)) is less than or equals to 5999
 * checks that merkle proof with proof _merkleProof, root merkleRoot1 for address (the address that called this function)
 * calls super._mint with variable account as _mintFor, variable amount as 2000000000000000000
 * updates mintClaims1 (Element the address that called this function) as (mintClaims1 with element the address that called this function) + (1)
 * emits event Mint with inputs the address that called this function
*/
	function mint1(address _mintFor, bytes32[] memory _merkleProof) public payable {
		require(block.timestamp < 1659196800, "Sorry, sales is over.");
		require(!(_paused), "Pausable: paused");
		require((whichMintPhase == 1), "Wrong Mint Phase");
		require(((totalSupply() + 2000000000000000000) <= 8000000000000000000000), "Exceeded Total Supply");
		require(((balanceOf(msg.sender) + 2000000000000000000) <= 1999000000000000000000), "Exceeded Individual Supply Constraints");
		require((msg.value == (2000000000000000000 * ((mintPriceOverride1_Native ? newMintPrice1_Native : 100000000000000) / (10 ** 18)))), "Wrong Fee");
		require(((mintClaims1[msg.sender] + 1) <= 5999), "Exceed number of claims for this phase");
		require(MerkleProof.verify(_merkleProof, merkleRoot1, keccak256(abi.encodePacked(msg.sender))), "Invalid Proof");
		super._mint(_mintFor, 2000000000000000000);
		mintClaims1[msg.sender]  = (mintClaims1[msg.sender] + 1);
		emit Mint(msg.sender);
	}

/**
 * Function mint2
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that not _paused
 * checks that whichMintPhase is equals to 2
 * checks that ((totalSupply) + (_amt)) is less than or equals to 8000000000000000000000
 * checks that ((balanceOf with variable account as (the address that called this function)) + (_amt)) is less than or equals to 1999000000000000000000
 * checks that (amount of native currency sent to contract) is equals to ((_amt) * ((if mintPriceOverride2_Native then newMintPrice2_Native else 3000000000000000) / (10 raised to the power of 18)))
 * calls super._mint with variable account as the address that called this function, variable amount as _amt
 * emits event Mint with inputs the address that called this function
*/
	function mint2(uint256 _amt) public payable {
		require(!(_paused), "Pausable: paused");
		require((whichMintPhase == 2), "Wrong Mint Phase");
		require(((totalSupply() + _amt) <= 8000000000000000000000), "Exceeded Total Supply");
		require(((balanceOf(msg.sender) + _amt) <= 1999000000000000000000), "Exceeded Individual Supply Constraints");
		require((msg.value == (_amt * ((mintPriceOverride2_Native ? newMintPrice2_Native : 3000000000000000) / (10 ** 18)))), "Wrong Fee");
		super._mint(msg.sender, _amt);
		emit Mint(msg.sender);
	}

/**
 * Function pause
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * updates _paused as true
 * emits event Unpaused with inputs the address that called this function
*/
	function pause() public onlyOwner {
		_paused  = true;
		emit Unpaused(msg.sender);
	}

/**
 * Function unpause
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * updates _paused as false
 * emits event Paused with inputs the address that called this function
*/
	function unpause() public onlyOwner {
		_paused  = false;
		emit Paused(msg.sender);
	}

/**
 * Function withdrawNativeCurrency
 * The function takes in 1 variable, zero or a positive integer _amount. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * transfers _amount of the native currency to the owner of this contract
*/
	function withdrawNativeCurrency(uint256 _amount) public onlyOwner {
		payable(owner).transfer(_amount);
	}
}