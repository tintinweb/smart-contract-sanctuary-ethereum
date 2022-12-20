/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT
error TransactionCapExceeded();
error ExcessiveOwnedMints();
error MintZeroQuantity();
error InvalidPayment();
error CapExceeded();
error ValueCannotBeZero();
error CannotBeNullAddress();
error InvalidTeamChange();
error InvalidInputValue();
error NoStateChange();

error PublicMintingClosed();
error AllowlistMintClosed();

error AddressNotAllowlisted();

error OnlyERC20MintingEnabled();
error ERC20TokenNotApproved();
error ERC20InsufficientBalance();
error ERC20InsufficientAllowance();
error ERC20TransferFailed();
error ERC20CappedInvalidValue();

pragma solidity ^0.8.0;

/**
* @dev These functions deal with verification of Merkle Trees proofs.
*
* The proofs can be generated using the JavaScript library
* https://github.com/miguelmota/merkletreejs[merkletreejs].
* Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
*
*
* WARNING: You should avoid using leaf values that are 64 bytes long prior to
* hashing, or use a hash function other than keccak256 for hashing leaves.
* This is because the concatenation of a sorted pair of internal nodes in
* the merkle tree could be reinterpreted as a leaf value.
*/
library MerkleProof {
    /**
    * @dev Returns true if a 'leaf' can be proved to be a part of a Merkle tree
    * defined by 'root'. For this, a 'proof' must be provided, containing
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
    * from 'leaf' using 'proof'. A 'proof' is valid if and only if the rebuilt
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if(currentAllowance < subtractedValue) revert ERC20InsufficientBalance();
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if(from == address(0)) revert CannotBeNullAddress();
        if(to == address(0)) revert CannotBeNullAddress();

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        if(fromBalance < amount) revert ERC20InsufficientBalance();
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        if(account == address(0)) revert CannotBeNullAddress();

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
        if(account == address(0)) revert CannotBeNullAddress();

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        if(accountBalance < amount) revert ERC20InsufficientBalance();
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
        if(owner == address(0)) revert CannotBeNullAddress();
        if(spender == address(0)) revert CannotBeNullAddress();

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if(currentAllowance < amount) revert ERC20InsufficientBalance();
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// File: contracts/erc20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        if(newOwner == address(0)) revert CannotBeNullAddress();
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

// Rampp Contracts v2.1 (Teams.sol)

pragma solidity ^0.8.0;

/**
* Teams is a contract implementation to extend upon Ownable that allows multiple controllers
* of a single contract to modify specific mint settings but not have overall ownership of the contract.
* This will easily allow cross-collaboration via Mintplex.xyz.
**/
abstract contract Teams is Ownable{
  mapping (address => bool) internal team;

  /**
  * @dev Adds an address to the team. Allows them to execute protected functions
  * @param _address the ETH address to add, cannot be 0x and cannot be in team already
  **/
  function addToTeam(address _address) public onlyOwner {
    if(_address == address(0)) revert CannotBeNullAddress();
    if(inTeam(_address)) revert InvalidTeamChange();
  
    team[_address] = true;
  }

  /**
  * @dev Removes an address to the team.
  * @param _address the ETH address to remove, cannot be 0x and must be in team
  **/
  function removeFromTeam(address _address) public onlyOwner {
    if(_address == address(0)) revert CannotBeNullAddress();
    if(!inTeam(_address)) revert InvalidTeamChange();
  
    team[_address] = false;
  }

  /**
  * @dev Check if an address is valid and active in the team
  * @param _address ETH address to check for truthiness
  **/
  function inTeam(address _address)
    public
    view
    returns (bool)
  {
    if(_address == address(0)) revert CannotBeNullAddress();
    return team[_address] == true;
  }

  /**
  * @dev Throws if called by any account other than the owner or team member.
  */
  function _onlyTeamOrOwner() private view {
    bool _isOwner = owner() == _msgSender();
    bool _isTeam = inTeam(_msgSender());
    require(_isOwner || _isTeam, "Team: caller is not the owner or in Team.");
  }

  modifier onlyTeamOrOwner() {
    _onlyTeamOrOwner();
    _;
  }
}

// @dev Allows the contract to have an enforceable supply cap.
// @notice This is toggleable by the team, so supply can be unlimited/limited at will.
abstract contract ERC20Capped is ERC20, Teams {
    bool public _capEnabled;
    uint256 internal _cap; // Supply Cap of entire token contract

    function setCapStatus(bool _capStatus) public onlyTeamOrOwner {
        _capEnabled = _capStatus;
    }

    function canMintAmount(uint256 _amount) public view returns (bool) {
        if(!_capEnabled){ return true; }
        return ERC20.totalSupply() + _amount <= supplyCap();
    }

    // @dev Update the total possible supply to a new value.
    // @notice _newCap must be greater than or equal to the currently minted supply
    // @param _newCap is the new amount of tokens available in wei
    function setSupplyCap(uint256 _newCap) public onlyTeamOrOwner {
        if(_newCap < ERC20.totalSupply()) revert ERC20CappedInvalidValue();
        _cap = _newCap;
    }

    function supplyCap() public view virtual returns (uint256) {
        if(!_capEnabled){ return ERC20.totalSupply(); }
        return _cap;
    }
}

abstract contract Feeable is Teams {
  uint256 public PRICE = 0 ether;

  function setPrice(uint256 _feeInWei) public onlyTeamOrOwner {
    PRICE = _feeInWei;
  }

  // @dev quickly calculate the fee that will be required for a given qty to mint
  // @notice _count is the value in wei, not in human readable count
  // @param _count is representation of quantity in wei. it will be converted to eth to arrive at proper value
  function getPrice(uint256 _count) public view returns (uint256) {
    if(_count < 1 ether) revert InvalidInputValue();
    uint256 countHuman = _count / 1 ether;
    return PRICE * countHuman;
  }
}

// File: Allowlist.sol

pragma solidity ^0.8.0;

abstract contract Allowlist is Teams {
    bytes32 public merkleRoot;
    bool public onlyAllowlistMode = false;

    /**
        * @dev Update merkle root to reflect changes in Allowlist
        * @param _newMerkleRoot new merkle root to reflect most recent Allowlist
        */
    function updateMerkleRoot(bytes32 _newMerkleRoot) public onlyTeamOrOwner {
        if(_newMerkleRoot == merkleRoot) revert NoStateChange();
        merkleRoot = _newMerkleRoot;
    }

    /**
        * @dev Check the proof of an address if valid for merkle root
        * @param _to address to check for proof
        * @param _merkleProof Proof of the address to validate against root and leaf
        */
    function isAllowlisted(address _to, bytes32[] calldata _merkleProof) public view returns(bool) {
        if(merkleRoot == 0) revert ValueCannotBeZero();
        bytes32 leaf = keccak256(abi.encodePacked(_to));

        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }


    function enableAllowlistOnlyMode() public onlyTeamOrOwner {
        onlyAllowlistMode = true;
    }

    function disableAllowlistOnlyMode() public onlyTeamOrOwner {
        onlyAllowlistMode = false;
    }
}

// File: WithdrawableV2
// This abstract allows the contract to be able to mint and ingest ERC-20 payments for mints.
// ERC-20 Payouts are limited to a single payout address.
abstract contract WithdrawableV2 is Teams {
  struct acceptedERC20 {
    bool isActive;
    uint256 chargeAmount;
  }
  mapping(address => acceptedERC20) private allowedTokenContracts;
  address[] public payableAddresses;
  address public erc20Payable;
  uint256[] public payableFees;
  uint256 public payableAddressCount;
  bool public onlyERC20MintingMode;

  function withdrawAll() public onlyTeamOrOwner {
      if(address(this).balance == 0) revert ValueCannotBeZero();
      _withdrawAll(address(this).balance);
  }

  function _withdrawAll(uint256 balance) private {
      for(uint i=0; i < payableAddressCount; i++ ) {
          _widthdraw(
              payableAddresses[i],
              (balance * payableFees[i]) / 100
          );
      }
  }
  
  function _widthdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  /**
  * @dev Allow contract owner to withdraw ERC-20 balance from contract
  * in the event ERC-20 tokens are paid to the contract for mints.
  * @param _tokenContract contract of ERC-20 token to withdraw
  * @param _amountToWithdraw balance to withdraw according to balanceOf of ERC-20 token in wei
  */
  function withdrawERC20(address _tokenContract, uint256 _amountToWithdraw) public onlyTeamOrOwner {
    if(_amountToWithdraw == 0) revert ValueCannotBeZero();
    IERC20 tokenContract = IERC20(_tokenContract);
    if(tokenContract.balanceOf(address(this)) < _amountToWithdraw) revert ERC20InsufficientBalance();
    tokenContract.transfer(erc20Payable, _amountToWithdraw); // Payout ERC-20 tokens to recipient
  }

  /**
  * @dev check if an ERC-20 contract is a valid payable contract for executing a mint.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function isApprovedForERC20Payments(address _erc20TokenContract) public view returns(bool) {
    return allowedTokenContracts[_erc20TokenContract].isActive == true;
  }

  /**
  * @dev get the value of tokens to transfer for user of an ERC-20
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function chargeAmountForERC20(address _erc20TokenContract) public view returns(uint256) {
    if(!isApprovedForERC20Payments(_erc20TokenContract)) revert ERC20TokenNotApproved();
    return allowedTokenContracts[_erc20TokenContract].chargeAmount;
  }

  /**
  * @dev Explicity sets and ERC-20 contract as an allowed payment method for minting
  * @param _erc20TokenContract address of ERC-20 contract in question
  * @param _isActive default status of if contract should be allowed to accept payments
  * @param _chargeAmountInTokens fee (in tokens) to charge for mints for this specific ERC-20 token
  */
  function addOrUpdateERC20ContractAsPayment(address _erc20TokenContract, bool _isActive, uint256 _chargeAmountInTokens) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = _isActive;
    allowedTokenContracts[_erc20TokenContract].chargeAmount = _chargeAmountInTokens;
  }

  /**
  * @dev Add an ERC-20 contract as being a valid payment method. If passed a contract which has not been added
  * it will assume the default value of zero. This should not be used to create new payment tokens.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function enableERC20ContractAsPayment(address _erc20TokenContract) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = true;
  }

  /**
  * @dev Disable an ERC-20 contract as being a valid payment method. If passed a contract which has not been added
  * it will assume the default value of zero. This should not be used to create new payment tokens.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function disableERC20ContractAsPayment(address _erc20TokenContract) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = false;
  }

  /**
  * @dev Enable only ERC-20 payments for minting on this contract
  */
  function enableERC20OnlyMinting() public onlyTeamOrOwner {
    onlyERC20MintingMode = true;
  }

  /**
  * @dev Disable only ERC-20 payments for minting on this contract
  */
  function disableERC20OnlyMinting() public onlyTeamOrOwner {
    onlyERC20MintingMode = false;
  }

  /**
  * @dev Set the payout of the ERC-20 token payout to a specific address
  * @param _newErc20Payable new payout addresses of ERC-20 tokens
  */
  function setERC20PayableAddress(address _newErc20Payable) public onlyTeamOrOwner {
    if(_newErc20Payable == address(0)) revert CannotBeNullAddress();
    if(_newErc20Payable == erc20Payable) revert NoStateChange();
    erc20Payable = _newErc20Payable;
  }

  function definePayables(address[] memory _newPayables, uint256[] memory _newFees) public onlyTeamOrOwner {
      delete payableAddresses;
      delete payableFees;
      payableAddresses = _newPayables;
      payableFees = _newFees;
      payableAddressCount = _newPayables.length;
  }
}

// @dev Allows us to add per wallet and per transaction caps to the minting aspect of this ERC20
abstract contract ERC20MintCaps is Teams {
    mapping(address => uint256) private _minted;
    bool internal _mintCapEnabled; // per wallet mint cap
    bool internal _batchSizeEnabled; // txn batch size limit
    uint256 internal mintCap; // in wei
    uint256 internal maxBatchSize; // in wei

    function setMintCap(uint256 _newMintCap) public onlyTeamOrOwner {
        mintCap = _newMintCap;
    }

    function setMintCapStatus(bool _newStatus) public onlyTeamOrOwner {
        _mintCapEnabled = _newStatus;
    }

    function setMaxBatchSize(uint256 _maxBatchSize) public onlyTeamOrOwner {
        maxBatchSize = _maxBatchSize;
    }

    function setMaxBatchSizeStatus(bool _newStatus) public onlyTeamOrOwner {
        _batchSizeEnabled = _newStatus;
    }

    // @dev Check if amount of tokens is possible to be minted
    // @param _amount is the amount of tokens in wei
    function canMintBatch(uint256 _amount) public view returns (bool) {
        if(!_batchSizeEnabled){ return true; }
        return _amount <= maxBatchSize;
    }

    // @dev returns if current mint caps are enabled (mints per wallet)
    // @return bool if mint caps per wallet are enforced
    function mintCapEnabled() public view returns (bool) {
        return _mintCapEnabled;
    }

    // @dev the current mintCap in decimals value
    // @return uint256 of mint caps per wallet. mintCapEnabled can be disabled and this value be non-zero.
    function maxWalletMints() public view returns(uint256) {
        return mintCap;
    }

    // @dev returns if current batch size caps are enabled (mints per txn)
    // @return bool if mint caps per transaction are enforced
    function mintBatchSizeEnabled() public view returns (bool) {
        return _batchSizeEnabled;
    }

    // @dev the current cap for a single txn in decimals value
    // @return uint256 the current cap for a single txn in decimals value
    function maxMintsPerTxn() public view returns (uint256) {
        return maxBatchSize;
    }

    // @dev checks if the mint count of an account is within the proper range
    // @notice if maxWalletMints is false it will always return true
    // @param _account is address to check
    // @param _amount is the amount of tokens in wei to be added to current minted supply
    function canAccountMintAmount(address _account, uint256 _amount) public view returns (bool) {
        if(!_mintCapEnabled){ return true; }
        return mintedAmount(_account) + _amount <= mintCap;
    }

    // @dev gets currently minted amount for an account
    // @return uint256 of tokens owned in base decimal value (wei)
    function mintedAmount(address _account) public view returns (uint256) {
        return _minted[_account];
    }

    // @dev helper function that increased the mint amount for an account
    // @notice this is not the same as _balances, as that can vary as trades occur.
    // @param _account is address to add to
    // @param _amount is the amount of tokens in wei to be added to current minted amount
    function addMintsToAccount(address _account, uint256 _amount) internal {
        unchecked {
            _minted[_account] += _amount;
        }
    }
}

abstract contract SingleStateMintable is Teams {
    bool internal publicMintOpen = false;
    bool internal allowlistMintOpen = false;

    function inPublicMint() public view returns (bool){
        return publicMintOpen && !allowlistMintOpen;
    }

    function inAllowlistMint() public view returns (bool){
        return allowlistMintOpen && !publicMintOpen;
    }

    function openPublicMint() public onlyTeamOrOwner {
        publicMintOpen = true;
        allowlistMintOpen = false;
    }

    function openAllowlistMint() public onlyTeamOrOwner {
        allowlistMintOpen = true;
        publicMintOpen = false;
    }

    // @notice This will set close all minting to public regardless of previous state
    function closeMinting() public onlyTeamOrOwner {
        allowlistMintOpen = false;
        publicMintOpen = false;
    }
}


// File: contracts/ERC20Plus.sol
pragma solidity ^0.8.0;

contract ERC20Plus is 
    Ownable,
    ERC20Burnable,
    ERC20Capped,
    ERC20MintCaps,
    Feeable,
    Allowlist,
    WithdrawableV2,
    SingleStateMintable
    {
    uint8 immutable CONTRACT_VERSION = 1;
    constructor(
        string memory name,
        string memory symbol,
        address[] memory _payableAddresses,
        address _erc20Payable,
        uint256[] memory _payableFees,
        bool[3] memory mintSettings, // hasMaxSupply, mintCapEnabled, maxBatchEnabled
        uint256[3] memory mintValues, // initMaxSupply, initMintCap, initBatchSize
        uint256 initPrice
    ) ERC20(name, symbol) {
        // Payable settings
        payableAddresses = _payableAddresses;
        erc20Payable = _erc20Payable;
        payableFees = _payableFees;
        payableAddressCount = _payableAddresses.length;

        // Set inital Supply cap settings
        _capEnabled = mintSettings[0];
        _cap = mintValues[0];
        
        // Per wallet minting settings
        _mintCapEnabled = mintSettings[1];
        mintCap = mintValues[1];

        // Per txn minting settings
        _batchSizeEnabled = mintSettings[2];
        maxBatchSize = mintValues[2];

        // setup price
        PRICE = initPrice;
    }

    /////////////// Admin Mint Functions
    /**
    * @dev Mints tokens to an address.
    * This is owner only and allows a fee-free drop
    * @param _to address of the future owner of the token
    * @param _qty amount of tokens to drop the owner in decimal value (wei typically 1e18)
    */
    function adminMint(address _to, uint256 _qty) public onlyTeamOrOwner{
        if(_qty < 1 ether) revert MintZeroQuantity();
        if(!canMintAmount(_qty)) revert CapExceeded();
        _mint(_to, _qty);
    }

    function adminMintBulk(address[] memory _tos, uint256 _qty) public onlyTeamOrOwner{
        if(_qty < 1 ether) revert MintZeroQuantity();
        for(uint i=0; i < _tos.length; i++ ) {
            _mint(_tos[i], _qty);
        }
    }

    /////////////// GENERIC MINT FUNCTIONS
    /**
    * @dev Mints tokens to an address in batch.
    * fee may or may not be required*
    * @param _to address of the future owner of the token
    * @param _amount number of tokens to mint in wei
    */
    function mintMany(address _to, uint256 _amount) public payable {
        if(onlyERC20MintingMode) revert PublicMintingClosed();
        if(_amount < 1 ether) revert MintZeroQuantity();
        if(!inPublicMint()) revert PublicMintingClosed();
        if(!canMintBatch(_amount)) revert TransactionCapExceeded();
        if(!canMintAmount(_amount)) revert CapExceeded();
        if(!canAccountMintAmount(_to, _amount)) revert ExcessiveOwnedMints();
        if(msg.value != getPrice(_amount)) revert InvalidPayment();

        addMintsToAccount(_to, _amount);
        _mint(_to, _amount);
    }

    /**
     * @dev Mints tokens to an address in batch using an ERC-20 token for payment
     * fee may or may not be required*
     * @param _to address of the future owner of the token
     * @param _amount number of tokens to mint in wei
     * @param _erc20TokenContract erc-20 token contract to mint with
     */
    function mintManyERC20(address _to, uint256 _amount, address _erc20TokenContract) public payable {
        if(_amount < 1 ether) revert MintZeroQuantity();
        if(!canMintAmount(_amount)) revert CapExceeded();
        if(!inPublicMint()) revert PublicMintingClosed();
        if(!canMintBatch(_amount)) revert TransactionCapExceeded();
        if(!canAccountMintAmount(_to, _amount)) revert ExcessiveOwnedMints();

        // ERC-20 Specific pre-flight checks
        if(!isApprovedForERC20Payments(_erc20TokenContract)) revert ERC20TokenNotApproved();
        uint256 tokensQtyToTransfer = chargeAmountForERC20(_erc20TokenContract) * _amount;
        IERC20 payableToken = IERC20(_erc20TokenContract);

        if(payableToken.balanceOf(_to) < tokensQtyToTransfer) revert ERC20InsufficientBalance();
        if(payableToken.allowance(_to, address(this)) < tokensQtyToTransfer) revert ERC20InsufficientAllowance();
        bool transferComplete = payableToken.transferFrom(_to, address(this), tokensQtyToTransfer);
        if(!transferComplete) revert ERC20TransferFailed();
        
        addMintsToAccount(_to, _amount);
        _mint(_to, _amount);
    }

    /**
    * @dev Mints tokens to an address using an allowlist.
    * fee may or may not be required*
    * @param _to address of the future owner of the token
    * @param _amount number of tokens to mint in wei
    * @param _merkleProof merkle proof array
    */
    function mintManyAL(address _to, uint256 _amount, bytes32[] calldata _merkleProof) public payable {
        if(onlyERC20MintingMode) revert AllowlistMintClosed();
        if(_amount < 1 ether) revert MintZeroQuantity();
        if(!inAllowlistMint()) revert AllowlistMintClosed();
        if(!isAllowlisted(_to, _merkleProof)) revert AddressNotAllowlisted();
        if(!canMintBatch(_amount)) revert TransactionCapExceeded();
        if(!canAccountMintAmount(_to, _amount)) revert ExcessiveOwnedMints();
        if(!canMintAmount(_amount)) revert CapExceeded();
        if(msg.value != getPrice(_amount)) revert InvalidPayment();

        addMintsToAccount(_to, _amount);
        _mint(_to, _amount);
    }

    /**
    * @dev Mints tokens to an address using an allowlist.
    * fee may or may not be required*
    * @param _to address of the future owner of the token
    * @param _amount number of tokens to mint in wei
    * @param _merkleProof merkle proof array
    * @param _erc20TokenContract erc-20 token contract to mint with
    */
    function mintManyERC20AL(address _to, uint256 _amount, bytes32[] calldata _merkleProof, address _erc20TokenContract) public payable {
        if(!inAllowlistMint()) revert AllowlistMintClosed();
        if(_amount < 1 ether) revert MintZeroQuantity();
        if(!isAllowlisted(_to, _merkleProof)) revert AddressNotAllowlisted();
        if(!canMintBatch(_amount)) revert TransactionCapExceeded();
        if(!canAccountMintAmount(_to, _amount)) revert ExcessiveOwnedMints();
        if(!canMintAmount(_amount)) revert CapExceeded();
        
        // ERC-20 Specific pre-flight checks
        if(!isApprovedForERC20Payments(_erc20TokenContract)) revert ERC20TokenNotApproved();
        uint256 tokensQtyToTransfer = chargeAmountForERC20(_erc20TokenContract) * _amount;
        IERC20 payableToken = IERC20(_erc20TokenContract);
        
        if(payableToken.balanceOf(_to) < tokensQtyToTransfer) revert ERC20InsufficientBalance();
        if(payableToken.allowance(_to, address(this)) < tokensQtyToTransfer) revert ERC20InsufficientAllowance();
        
        bool transferComplete = payableToken.transferFrom(_to, address(this), tokensQtyToTransfer);
        if(!transferComplete) revert ERC20TransferFailed();

        addMintsToAccount(_to, _amount);
        _mint(_to, _amount);
    }
}