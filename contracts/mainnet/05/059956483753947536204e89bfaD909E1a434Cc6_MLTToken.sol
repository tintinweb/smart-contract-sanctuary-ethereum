// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract MLTToken is ERC20 {
	/********
	* INDEX *
	*********/
	// 1. Type declarations.
	// 2. Constants and variables.
	// 3. Mappings.
	// 4. Modifiers.
	// 5. Events.
	// 6. Functions.

	/***********************
	* 1. TYPE DECLARATIONS *
	************************/
	struct VestingData {
		address beneficiary;
		uint256 amount;
		uint256 cliff;
		bytes32[] proof;
	}

	struct Allocation {
		uint256 unlocking;
		uint256[] monthly;
		uint256[] months;
		uint256 cliff;
	}

	/*****************************
	* 2. CONSTANTS AND VARIABLES *
	******************************/
	uint256 public VESTING_START_TIMESTAMP;

	/// @dev of URIs for all the Merkle trees added to the contract.
	string[] public rootURIs;

	/**************
	* 3. MAPPINGS *
	***************/
	/**
	 * Mapping of URIs to IPFS storing the data of a vestingTree.
	 * root => URI (IPFS)
	**/
	mapping(bytes32 => string) public mapRootURIs;

	/**
	 * @dev Record of user withdrawals by cliff.
	 * leaf = keccak256(abi.encodePacked(beneficiary, amount, cliff))
	 * leaf => claimed
	**/
	mapping(bytes32 => bool) public vestingClaimed;

	/**
	 * @dev Total balance of vesting tree by root hash
	 * Root hash => balance
	**/
	mapping(bytes32 => uint256) public balanceByRootHash;

	/**
	 * @dev Root hash record of valid vesting trees
	 * Root hash => valid
	**/
	mapping(bytes32 => bool) public rootWhitelist;

	/**
	 * @dev Treasurer mapping. A treasurer is an address which has the possibility of generating
	 * new TGE with the tokens that are assigned to it at the time of contract deployment.
	 * address => isTreasurer
	**/
	mapping(address => bool) private _treasurers;

	/***************
	* 4. MODIFIERS *
	****************/
	/**
	 * @dev Throws if root no valid
	**/
	modifier validRoot(bytes32 _root) {
		require(rootWhitelist[_root], "Root no valid");
		_;
	}

	/************
	* 5. EVENTS *
	*************/
	event AddedRoot(bytes32 indexed root);
	event VestedTokenGrant(bytes32 indexed leafHash);

	/***************
	* 6. FUNCTIONS *
	****************/
	/**
	 * @param name_ Name of ERC20 token
	 * @param symbol_ Symbol of ERC20 token
	 * @param supply_ Supply of ERC20 token
	 * @param uriIPFS_ IPFS URI for the initial vesting tree data.
	 * @param vestingTreeRoot_ Vesting tree root hash
	 * @param vestingStartTimestamp_ Timestamp of vesting start as seconds since the Unix epoch
	 * @param proofBalance_ Proof of total balance
	 * @param treasurers_ Addresses of authorized treasurers
	 **/
	constructor(
		string memory name_,
		string memory symbol_,
		uint256 supply_,
		string memory uriIPFS_,
		bytes32 vestingTreeRoot_,
		uint256 vestingStartTimestamp_,
		bytes32[] memory proofBalance_,
		address[] memory treasurers_
	) ERC20(name_, symbol_) {
		uint256 supply = supply_ * uint256(10)**decimals();

		/**
		 * @dev
		 * A validation of the supply registered in the merkle tree is made to verify that it
		 * matches the supply that the contract will have and to ensure that sufficient funds
		 * are available to comply with all the TGE assignments.
		**/
		require(
			MerkleProof.verify(proofBalance_, vestingTreeRoot_, keccak256(abi.encodePacked(supply))),
			'The total supply of the contract does not match that of the merketree'
		);

		for(uint256 i = 0; i < treasurers_.length; i++) _treasurers[treasurers_[i]] = true;

		rootWhitelist[vestingTreeRoot_] = true;
		balanceByRootHash[vestingTreeRoot_] = supply;
		VESTING_START_TIMESTAMP = vestingStartTimestamp_;

		emit AddedRoot(vestingTreeRoot_);

		rootURIs.push(uriIPFS_);
		mapRootURIs[vestingTreeRoot_] = uriIPFS_;

		_mint(address(this), supply);
	}

	/**
	 * @dev Verify if an address is a treasury address.
	 * @param t_ Address of treasurer.
	**/
	function isTreasurer(address t_) view public returns(bool) {
		return _treasurers[t_];
	}

	/**
	 * @dev Verify the validity of merkle proof associated with an address.
	 * @param beneficiary_ Address of beneficiary.
	 * @param amount_ Amount vested tokens to be released.
	 * @param cliff_ Lock delay for release.
	 * @param root_ Merkle tree root.
	 * @param proof_ Merkle proof.
	**/
	function verifyProof(
		address beneficiary_,
		uint256 amount_,
		uint256 cliff_,
		bytes32 root_,
		bytes32[] calldata proof_
	) external view returns(bool) {
		if(!rootWhitelist[root_]) return false;
		bytes32 _leaf = keccak256(abi.encodePacked(beneficiary_, amount_, cliff_));
		return MerkleProof.verify(proof_, root_, _leaf);
	}

	/**
	 * @dev Add a new merkle tree hash. Only addresses registered in the initial Merkle tree as
	 * treasurers have the possibility of adding new Merkle trees, and they are only allowed to
	 * add batches of users that belong to the same group (pool) and with the same allocation date.
	 * @param root_ Merkle tree root of treasurer.
	 * @param newRoot_ New merkle tree root.
	 * @param amount_ Balance that is assigned to new merkle tree.
	 * @param uriIPFS_ IPFS URI for the initial vesting tree data.
	 * @param allocation_ treasurer allocation
	 * @param balanceProof_ Merkle proof of balance.
	 * @param initialAllocationProof_ Merkle proof initial allocation.
	 * @param newAllocationProof_ Merkle proof new allocation.
	 * @param allocationQuantityProof_ Merkle proof allocation quantity.
	 * @param vestingSchedules_ Array of vestingData.
	**/
	function addRoot(
		bytes32 root_,
		bytes32 newRoot_,
		uint256 amount_,
		string memory uriIPFS_,
		Allocation memory allocation_,
		bytes32[] memory balanceProof_,
		bytes32[] memory initialAllocationProof_,
		bytes32[] memory newAllocationProof_,
		bytes32[] memory allocationQuantityProof_,
		VestingData[] calldata vestingSchedules_
	) external validRoot(root_) {
		require(isTreasurer(msg.sender), 'Caller is not a treasurer');

		require(MerkleProof.verify(
			allocationQuantityProof_,
			newRoot_,
			keccak256(abi.encodePacked('ALLOCATION_QUANTITY', uint256(1)))
		), 'The quantity of the allocation of the new Merkle tree is invalid');

		/// @dev the allocation dates of the treasurer who is adding a new merkle tree must match
		// the one assigned in the original merkle tree
		require(
			MerkleProof.verify(
				initialAllocationProof_,
				root_,
				keccak256(abi.encodePacked(
					msg.sender,
					allocation_.unlocking,
					allocation_.monthly,
					allocation_.months,
					allocation_.cliff
				))
			)
			&&
			MerkleProof.verify(
				newAllocationProof_,
				newRoot_,
				keccak256(abi.encodePacked(
					msg.sender,
					allocation_.unlocking,
					allocation_.monthly,
					allocation_.months,
					allocation_.cliff
				))
			),
			'Allocation type of the new Merkle tree is invalid'
		);

		require(
			MerkleProof.verify(balanceProof_, newRoot_, keccak256(abi.encodePacked(amount_))),
			'The supply sent does not match that of the merketree'
		);

		bytes32 r = root_;
		uint256 balance = 0;

		for(uint256 i = 0; i < vestingSchedules_.length; i++) {
			(
				address beneficiary,
				uint256 amount,
				uint256 cliff,
				bytes32[] calldata proof
			) = _splitVestingSchedule(vestingSchedules_[i]);

			require(beneficiary == msg.sender, 'You cannot claim tokens from another user');

			bytes32 leaf = keccak256(abi.encodePacked(beneficiary, amount, cliff));

			if(!vestingClaimed[leaf]) {
				require(
					MerkleProof.verify(proof, r, leaf), 'Invalid merkle proof'
				);

				require(balanceByRootHash[r] >= amount, 'Supply is not enough to claim allocation');

				vestingClaimed[leaf] = true;
				balanceByRootHash[r] -= amount;
				balance += amount;

				emit VestedTokenGrant(leaf);
			}
		}

		require(!rootWhitelist[newRoot_], 'Root hash already exists');
		require(amount_ == balance, 'Amount is different from balance');

		rootWhitelist[newRoot_] = true;
		balanceByRootHash[newRoot_] = amount_;

		rootURIs.push(uriIPFS_);
		mapRootURIs[newRoot_] = uriIPFS_;

		emit AddedRoot(newRoot_);
	}

	/**
	 * @dev Release vesting in batches
	 * @param vestingSchedules_ Array of vesting schedule
	 * @param root_ Merkle tree root
	**/
	function batchReleaseVested(VestingData[] calldata vestingSchedules_, bytes32 root_) external {
		for(uint256 i = 0; i < vestingSchedules_.length; i++) {
			(
				address beneficiary,
				uint256 amount,
				uint256 cliff,
				bytes32[] calldata proof
			) = _splitVestingSchedule(vestingSchedules_[i]);

			bytes32 _leaf = keccak256(abi.encodePacked(beneficiary, amount, cliff));
			if(!vestingClaimed[_leaf]) _releaseVested(beneficiary, amount, cliff, root_, proof);
		}
	}

	/**
	 * @dev Release vesting associated with an address
	 * @param _beneficiary Address of beneficiary
	 * @param _amount Amount vested tokens to be released
	 * @param _cliff Lock delay for release
	 * @param _root Merkle tree root
	 * @param _proof Merkle proof
	**/
	function releaseVested(
		address _beneficiary,
		uint256 _amount,
		uint256 _cliff,
		bytes32 _root,
		bytes32[] calldata _proof
	) external {
		_releaseVested(_beneficiary, _amount, _cliff, _root, _proof);
	}

	/**
	 * @dev Release vesting associated with an address
	 * @param beneficiary_ Address of beneficiary
	 * @param amount_ Amount vested tokens to be released
	 * @param cliff_ Lock delay for release
	 * @param root_ Merkle tree root
	 * @param proof_ Merkle proof
	**/
	function _releaseVested(
		address beneficiary_,
		uint256 amount_,
		uint256 cliff_,
		bytes32 root_,
		bytes32[] calldata proof_
	) internal validRoot(root_) {
		bytes32 leaf = keccak256(abi.encodePacked(beneficiary_, amount_, cliff_));

		require(
			MerkleProof.verify(proof_, root_, leaf), 'Invalid merkle proof'
		);

		require(!vestingClaimed[leaf], 'Tokens already claimed');
		require(balanceByRootHash[root_] >= amount_, 'Supply is not enough to claim allocation');
		require(
			block.timestamp >= VESTING_START_TIMESTAMP + cliff_,
			"The release date has not yet arrived"
		);

		require(!isTreasurer(beneficiary_), "Treasury addresses cannot claim tokens");

		vestingClaimed[leaf] = true;
		balanceByRootHash[root_] -= amount_;
		_transfer(address(this), beneficiary_, amount_);

		emit VestedTokenGrant(leaf);
	}

	function _splitVestingSchedule(VestingData calldata _user) internal pure returns(
		address beneficiary,
		uint256 amount,
		uint256 cliff,
		bytes32[] calldata proof
	) {
		return (_user.beneficiary, _user.amount, _user.cliff, _user.proof);
	}
}