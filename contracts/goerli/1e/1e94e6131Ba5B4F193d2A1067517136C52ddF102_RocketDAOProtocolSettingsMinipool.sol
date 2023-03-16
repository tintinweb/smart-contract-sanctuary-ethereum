// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    using SafeMath for uint256;

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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


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
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
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
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
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
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
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
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
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
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
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
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
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
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/auction/RocketAuctionManagerInterface.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/network/RocketNetworkPricesInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsAuctionInterface.sol";
import "../../interface/RocketVaultInterface.sol";

// Facilitates RPL liquidation auctions

contract RocketAuctionManager is RocketBase, RocketAuctionManagerInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event LotCreated(uint256 indexed lotIndex, address indexed by, uint256 rplAmount, uint256 time);
    event BidPlaced(uint256 indexed lotIndex, address indexed by, uint256 bidAmount, uint256 time);
    event BidClaimed(uint256 indexed lotIndex, address indexed by, uint256 bidAmount, uint256 rplAmount, uint256 time);
    event RPLRecovered(uint256 indexed lotIndex, address indexed by, uint256 rplAmount, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Get the total RPL balance of the contract
    function getTotalRPLBalance() override public view returns (uint256) {
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        return rocketVault.balanceOfToken("rocketAuctionManager", IERC20(getContractAddress("rocketTokenRPL")));
    }

    // Get/set the allotted RPL balance of the contract
    function getAllottedRPLBalance() override public view returns (uint256) {
        return getUint(keccak256("auction.rpl.allotted"));
    }
    function increaseAllottedRPLBalance(uint256 _amount) private {
        addUint(keccak256(abi.encodePacked("auction.rpl.allotted")), _amount);
    }
    function decreaseAllottedRPLBalance(uint256 _amount) private {
        subUint(keccak256(abi.encodePacked("auction.rpl.allotted")), _amount);
    }

    // Get the remaining (unallotted) RPL balance of the contract
    function getRemainingRPLBalance() override public view returns (uint256) {
        return getTotalRPLBalance().sub(getAllottedRPLBalance());
    }

    // Get/set the number of lots for auction
    function getLotCount() override public view returns (uint256) {
        return getUint(keccak256("auction.lots.count"));
    }
    function setLotCount(uint256 _amount) private {
        setUint(keccak256("auction.lots.count"), _amount);
    }

    // Get lot details
    function getLotExists(uint256 _index) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("auction.lot.exists", _index)));
    }
    function getLotStartBlock(uint256 _index) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("auction.lot.block.start", _index)));
    }
    function getLotEndBlock(uint256 _index) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("auction.lot.block.end", _index)));
    }
    function getLotStartPrice(uint256 _index) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("auction.lot.price.start", _index)));
    }
    function getLotReservePrice(uint256 _index) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("auction.lot.price.reserve", _index)));
    }
    function getLotTotalRPLAmount(uint256 _index) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("auction.lot.rpl.total", _index)));
    }

    // Get/set the total ETH amount bid on a lot
    function getLotTotalBidAmount(uint256 _index) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("auction.lot.bid.total", _index)));
    }
    function increaseLotTotalBidAmount(uint256 _index, uint256 _amount) private {
        addUint(keccak256(abi.encodePacked("auction.lot.bid.total", _index)), _amount);
    }

    // Get/set the ETH amount bid on a lot by an address
    function getLotAddressBidAmount(uint256 _index, address _bidder) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("auction.lot.bid.address", _index, _bidder)));
    }
    function setLotAddressBidAmount(uint256 _index, address _bidder, uint256 _amount) private {
        setUint(keccak256(abi.encodePacked("auction.lot.bid.address", _index, _bidder)), _amount);
    }
    function increaseLotAddressBidAmount(uint256 _index, address _bidder, uint256 _amount) private {
        addUint(keccak256(abi.encodePacked("auction.lot.bid.address", _index, _bidder)), _amount);
    }

    // Get/set the lot's RPL recovered status
    function getLotRPLRecovered(uint256 _index) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("auction.lot.rpl.recovered", _index)));
    }
    function setLotRPLRecovered(uint256 _index, bool _recovered) private {
        setBool(keccak256(abi.encodePacked("auction.lot.rpl.recovered", _index)), _recovered);
    }

    // Get the RPL price for a lot at a block
    function getLotPriceAtBlock(uint256 _index, uint256 _block) override public view returns (uint256) {
        // Get lot parameters
        uint256 startBlock = getLotStartBlock(_index);
        uint256 endBlock = getLotEndBlock(_index);
        uint256 startPrice = getLotStartPrice(_index);
        uint256 endPrice = getLotReservePrice(_index);
        // Calculate & return
        if (_block <= startBlock) { return startPrice; }
        if (_block >= endBlock) { return endPrice; }
        uint256 tn = _block.sub(startBlock);
        uint256 td = endBlock.sub(startBlock);
        return startPrice.sub(startPrice.sub(endPrice).mul(tn).mul(tn).div(td).div(td));
    }

    // Get the RPL price for a lot at the current block
    function getLotPriceAtCurrentBlock(uint256 _index) override public view returns (uint256) {
        return getLotPriceAtBlock(_index, block.number);
    }

    // Get the RPL price for a lot based on total ETH amount bid
    function getLotPriceByTotalBids(uint256 _index) override public view returns (uint256) {
        return calcBase.mul(getLotTotalBidAmount(_index)).div(getLotTotalRPLAmount(_index));
    }

    // Get the current RPL price for a lot
    // Returns the clearing price if cleared, or the price at the current block otherwise
    function getLotCurrentPrice(uint256 _index) override public view returns (uint256) {
        uint256 blockPrice = getLotPriceAtCurrentBlock(_index);
        uint256 bidPrice = getLotPriceByTotalBids(_index);
        if (bidPrice > blockPrice) { return bidPrice; }
        else { return blockPrice; }
    }

    // Get the amount of claimed RPL in a lot
    function getLotClaimedRPLAmount(uint256 _index) override public view returns (uint256) {
        uint256 claimed = calcBase.mul(getLotTotalBidAmount(_index)).div(getLotCurrentPrice(_index));
        uint256 total = getLotTotalRPLAmount(_index);
        // Due to integer arithmetic, the calculated claimed amount may be slightly greater than the total
        if (claimed > total) {
            return total;
        }
        return claimed;
    }

    // Get the amount of remaining RPL in a lot
    function getLotRemainingRPLAmount(uint256 _index) override public view returns (uint256) {
        return getLotTotalRPLAmount(_index).sub(getLotClaimedRPLAmount(_index));
    }

    // Check whether a lot has cleared
    function getLotIsCleared(uint256 _index) override external view returns (bool) {
        if (block.number >= getLotEndBlock(_index)) { return true; }
        if (getLotPriceByTotalBids(_index) >= getLotPriceAtCurrentBlock(_index)) { return true; }
        return false;
    }

    // Create a new lot for auction
    function createLot() override external onlyLatestContract("rocketAuctionManager", address(this)) {
        // Load contracts
        RocketDAOProtocolSettingsAuctionInterface rocketAuctionSettings = RocketDAOProtocolSettingsAuctionInterface(getContractAddress("rocketDAOProtocolSettingsAuction"));
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        // Get remaining RPL balance & RPL price
        uint256 remainingRplBalance = getRemainingRPLBalance();
        uint256 rplPrice = rocketNetworkPrices.getRPLPrice();
        // Check lot can be created
        require(rocketAuctionSettings.getCreateLotEnabled(), "Creating lots is currently disabled");
        require(remainingRplBalance >= calcBase.mul(rocketAuctionSettings.getLotMinimumEthValue()).div(rplPrice), "Insufficient RPL balance to create new lot");
        // Calculate lot RPL amount
        uint256 lotRplAmount = remainingRplBalance;
        uint256 maximumLotRplAmount = calcBase.mul(rocketAuctionSettings.getLotMaximumEthValue()).div(rplPrice);
        if (lotRplAmount > maximumLotRplAmount) { lotRplAmount = maximumLotRplAmount; }
        // Create lot
        uint256 lotIndex = getLotCount();
        setBool(keccak256(abi.encodePacked("auction.lot.exists", lotIndex)), true);
        setUint(keccak256(abi.encodePacked("auction.lot.block.start", lotIndex)), block.number);
        setUint(keccak256(abi.encodePacked("auction.lot.block.end", lotIndex)), block.number.add(rocketAuctionSettings.getLotDuration()));
        setUint(keccak256(abi.encodePacked("auction.lot.price.start", lotIndex)), rplPrice.mul(rocketAuctionSettings.getStartingPriceRatio()).div(calcBase));
        setUint(keccak256(abi.encodePacked("auction.lot.price.reserve", lotIndex)), rplPrice.mul(rocketAuctionSettings.getReservePriceRatio()).div(calcBase));
        setUint(keccak256(abi.encodePacked("auction.lot.rpl.total", lotIndex)), lotRplAmount);
        // Increment lot count & increase allotted RPL balance
        setLotCount(lotIndex.add(1));
        increaseAllottedRPLBalance(lotRplAmount);
        // Emit lot created event
        emit LotCreated(lotIndex, msg.sender, lotRplAmount, block.timestamp);
    }

    // Bid on a lot
    function placeBid(uint256 _lotIndex) override external payable onlyLatestContract("rocketAuctionManager", address(this)) {
        // Load contracts
        RocketDAOProtocolSettingsAuctionInterface rocketAuctionSettings = RocketDAOProtocolSettingsAuctionInterface(getContractAddress("rocketDAOProtocolSettingsAuction"));
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        // Check bid amount
        require(msg.value > 0, "Invalid bid amount");
        // Check lot exists
        require(getLotExists(_lotIndex), "Lot does not exist");
        // Check lot can be bid on
        require(rocketAuctionSettings.getBidOnLotEnabled(), "Bidding on lots is currently disabled");
        require(block.number < getLotEndBlock(_lotIndex), "Lot bidding period has concluded");
        // Check lot has RPL remaining
        uint256 remainingRplAmount = getLotRemainingRPLAmount(_lotIndex);
        require(remainingRplAmount > 0, "Lot RPL allocation has been exhausted");
        // Calculate the bid amount
        uint256 bidAmount = msg.value;
        uint256 maximumBidAmount = remainingRplAmount.mul(getLotPriceAtCurrentBlock(_lotIndex)).div(calcBase);
        if (bidAmount > maximumBidAmount) { bidAmount = maximumBidAmount; }
        // Increase lot bid amounts
        increaseLotTotalBidAmount(_lotIndex, bidAmount);
        increaseLotAddressBidAmount(_lotIndex, msg.sender, bidAmount);
        // Transfer bid amount to deposit pool
        rocketDepositPool.recycleLiquidatedStake{value: bidAmount}();
        // Refund excess ETH to sender
        if (msg.value > bidAmount) { msg.sender.transfer(msg.value.sub(bidAmount)); }
        // Emit bid placed event
        emit BidPlaced(_lotIndex, msg.sender, bidAmount, block.timestamp);
    }

    // Claim RPL from a lot
    function claimBid(uint256 _lotIndex) override external onlyLatestContract("rocketAuctionManager", address(this)) {
        // Check lot exists
        require(getLotExists(_lotIndex), "Lot does not exist");
        // Get lot price info
        uint256 blockPrice = getLotPriceAtCurrentBlock(_lotIndex);
        uint256 bidPrice = getLotPriceByTotalBids(_lotIndex);
        // Check lot can be claimed from
        require(block.number >= getLotEndBlock(_lotIndex) || bidPrice >= blockPrice, "Lot has not cleared yet");
        // Get & check address bid amount
        uint256 bidAmount = getLotAddressBidAmount(_lotIndex, msg.sender);
        require(bidAmount > 0, "Address has no RPL to claim");
        // Calculate current lot price
        uint256 currentPrice;
        if (bidPrice > blockPrice) { currentPrice = bidPrice; }
        else { currentPrice = blockPrice; }
        // Calculate RPL claim amount
        uint256 rplAmount = calcBase.mul(bidAmount).div(currentPrice);
        // Due to integer arithmetic, there may be a tiny bit less than calculated
        uint256 allottedAmount = getAllottedRPLBalance();
        if (rplAmount > allottedAmount) {
            rplAmount = allottedAmount;
        }
        // Transfer RPL to bidder
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        rocketVault.withdrawToken(msg.sender, IERC20(getContractAddress("rocketTokenRPL")), rplAmount);
        // Decrease allotted RPL balance & update address bid amount
        decreaseAllottedRPLBalance(rplAmount);
        setLotAddressBidAmount(_lotIndex, msg.sender, 0);
        // Emit bid claimed event
        emit BidClaimed(_lotIndex, msg.sender, bidAmount, rplAmount, block.timestamp);
    }

    // Recover unclaimed RPL from a lot
    function recoverUnclaimedRPL(uint256 _lotIndex) override external onlyLatestContract("rocketAuctionManager", address(this)) {
        // Check lot exists and has not already had RPL recovered
        require(getLotExists(_lotIndex), "Lot does not exist");
        require(!getLotRPLRecovered(_lotIndex), "Unclaimed RPL has already been recovered from the lot");
        // Check RPL can be reclaimed from lot
        require(block.number >= getLotEndBlock(_lotIndex), "Lot bidding period has not concluded yet");
        // Get & check remaining RPL amount
        uint256 remainingRplAmount = getLotRemainingRPLAmount(_lotIndex);
        require(remainingRplAmount > 0, "No unclaimed RPL is available to recover");
        // Decrease allotted RPL balance & set RPL recovered status
        decreaseAllottedRPLBalance(remainingRplAmount);
        setLotRPLRecovered(_lotIndex, true);
        // Emit RPL recovered event
        emit RPLRecovered(_lotIndex, msg.sender, remainingRplAmount, block.timestamp);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../RocketBase.sol";
import "../../../interface/RocketVaultInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedProposalsInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedActionsInterface.sol";
import "../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMembersInterface.sol";
import "../../../interface/dao/RocketDAOProposalInterface.sol";
import "../../../interface/util/AddressSetStorageInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


// The Trusted Node DAO 
contract RocketDAONodeTrusted is RocketBase, RocketDAONodeTrustedInterface {

    using SafeMath for uint;

    // The namespace for any data stored in the trusted node DAO (do not change)
    string constant daoNameSpace = "dao.trustednodes.";

    // Min amount of trusted node members required in the DAO
    uint256 constant daoMemberMinCount = 3;


    // Only allow bootstrapping when enabled
    modifier onlyBootstrapMode() {
        require(getBootstrapModeDisabled() == false, "Bootstrap mode not engaged");
        _;
    }

    // Only when the DAO needs new members due to being below the required min
    modifier onlyLowMemberMode() {
        require(getMemberCount() < daoMemberMinCount, "Low member mode not engaged");
        _;
    }
    

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }



    /**** DAO Properties **************/

    // Returns true if bootstrap mode is disabled
    function getBootstrapModeDisabled() override public view returns (bool) { 
        return getBool(keccak256(abi.encodePacked(daoNameSpace, "bootstrapmode.disabled"))); 
    }
    

    /*** Proposals ****************/

    
    // Return the amount of member votes need for a proposal to pass
    function getMemberQuorumVotesRequired() override external view returns (uint256) {
        // Load contracts
        RocketDAONodeTrustedSettingsMembersInterface rocketDAONodeTrustedSettingsMembers = RocketDAONodeTrustedSettingsMembersInterface(getContractAddress("rocketDAONodeTrustedSettingsMembers"));
        // Calculate and return votes required
        return getMemberCount().mul(rocketDAONodeTrustedSettingsMembers.getQuorum());
    }


    /*** Members ******************/

    // Return true if the node addressed passed is a member of the trusted node DAO
    function getMemberIsValid(address _nodeAddress) override external view returns (bool) {
        return getBool(keccak256(abi.encodePacked(daoNameSpace, "member", _nodeAddress))); 
    }
    
    // Get a trusted node member address by index
    function getMemberAt(uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked(daoNameSpace, "member.index")), _index);
    }

    // Total number of members in the current trusted node DAO
    function getMemberCount() override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked(daoNameSpace, "member.index")));
    }

    // Min required member count for the DAO 
    function getMemberMinRequired() override external pure returns (uint256) {
        return daoMemberMinCount;
    }

    // Get the last time this user made a proposal
    function getMemberLastProposalTime(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoNameSpace, "member.proposal.lasttime", _nodeAddress)));
    }

    // Get the ID of a trusted node member
    function getMemberID(address _nodeAddress) override external view returns (string memory) {
        return getString(keccak256(abi.encodePacked(daoNameSpace, "member.id", _nodeAddress))); 
    }

    // Get the URL of a trusted node member
    function getMemberUrl(address _nodeAddress) override external view returns (string memory) {
        return getString(keccak256(abi.encodePacked(daoNameSpace, "member.url", _nodeAddress))); 
    }

    // Get the block the member joined at
    function getMemberJoinedTime(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoNameSpace, "member.joined.time", _nodeAddress)));
    } 

    // Get data that was recorded about a proposal that was executed
    function getMemberProposalExecutedTime(string memory _proposalType, address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoNameSpace, "member.executed.time", _proposalType, _nodeAddress)));
    }

    // Get the RPL bond amount the user deposited to join
    function getMemberRPLBondAmount(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoNameSpace, "member.bond.rpl", _nodeAddress))); 
    }

    // Is this member currently being 'challenged' to see if their node is responding
    function getMemberIsChallenged(address _nodeAddress) override external view returns (bool) {
        // Has this member been challenged recently and still within the challenge window to respond? If there is a challenge block recorded against them, they are actively being challenged.
        return getUint(keccak256(abi.encodePacked(daoNameSpace, "member.challenged.time", _nodeAddress))) > 0 ? true : false;
    }

    // How many unbonded validators this member has
    function getMemberUnbondedValidatorCount(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoNameSpace, "member.validator.unbonded.count", _nodeAddress)));
    }

    // Increment/decrement a member's unbonded validator count
    // Only accepts calls from the RocketMinipoolManager contract
    function incrementMemberUnbondedValidatorCount(address _nodeAddress) override external onlyLatestContract("rocketDAONodeTrusted", address(this)) onlyLatestContract("rocketMinipoolManager", msg.sender) {
        addUint(keccak256(abi.encodePacked(daoNameSpace, "member.validator.unbonded.count", _nodeAddress)), 1);
    }
    function decrementMemberUnbondedValidatorCount(address _nodeAddress) override external onlyLatestContract("rocketDAONodeTrusted", address(this)) onlyRegisteredMinipool(msg.sender) {
        subUint(keccak256(abi.encodePacked(daoNameSpace, "member.validator.unbonded.count", _nodeAddress)), 1);
    }


    /**** Bootstrapping ***************/

    
    // Bootstrap mode - In bootstrap mode, guardian can add members at will
    function bootstrapMember(string memory _id, string memory _url, address _nodeAddress) override external onlyGuardian onlyBootstrapMode onlyRegisteredNode(_nodeAddress) onlyLatestContract("rocketDAONodeTrusted", address(this)) {
        // Ok good to go, lets add them
        RocketDAONodeTrustedProposalsInterface(getContractAddress("rocketDAONodeTrustedProposals")).proposalInvite(_id, _url, _nodeAddress);
    }


    // Bootstrap mode - Uint Setting
    function bootstrapSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAONodeTrusted", address(this)) {
        // Ok good to go, lets update the settings 
        RocketDAONodeTrustedProposalsInterface(getContractAddress("rocketDAONodeTrustedProposals")).proposalSettingUint(_settingContractName, _settingPath, _value);
    }

    // Bootstrap mode - Bool Setting
    function bootstrapSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAONodeTrusted", address(this)) {
        // Ok good to go, lets update the settings 
        RocketDAONodeTrustedProposalsInterface(getContractAddress("rocketDAONodeTrustedProposals")).proposalSettingBool(_settingContractName, _settingPath, _value);
    }


    // Bootstrap mode - Upgrade contracts or their ABI
    function bootstrapUpgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAONodeTrusted", address(this)) {
        // Ok good to go, lets update the settings 
        RocketDAONodeTrustedProposalsInterface(getContractAddress("rocketDAONodeTrustedProposals")).proposalUpgrade(_type, _name, _contractAbi, _contractAddress);
    }

    // Bootstrap mode - Disable RP Access (only RP can call this to hand over full control to the DAO)
    function bootstrapDisable(bool _confirmDisableBootstrapMode) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAONodeTrusted", address(this)) {
        require(_confirmDisableBootstrapMode == true, "You must confirm disabling bootstrap mode, it can only be done once!");
        setBool(keccak256(abi.encodePacked(daoNameSpace, "bootstrapmode.disabled")), true); 
    }

 
    /**** Recovery ***************/
        
    // In an explicable black swan scenario where the DAO loses more than the min membership required (3), this method can be used by a regular node operator to join the DAO
    // Must have their ID, URL, current RPL bond amount available and must be called by their current registered node account
    function memberJoinRequired(string memory _id, string memory _url) override external onlyLowMemberMode onlyRegisteredNode(msg.sender) onlyLatestContract("rocketDAONodeTrusted", address(this)) {
        // Ok good to go, lets update the settings 
        RocketDAONodeTrustedProposalsInterface(getContractAddress("rocketDAONodeTrustedProposals")).proposalInvite(_id, _url, msg.sender);
        // Get the to automatically join as a member (by a regular proposal, they would have to manually accept, but this is no ordinary situation)
        RocketDAONodeTrustedActionsInterface(getContractAddress("rocketDAONodeTrustedActions")).actionJoinRequired(msg.sender);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../RocketBase.sol";
import "../../../interface/RocketVaultInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedActionsInterface.sol";
import "../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMembersInterface.sol";
import "../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsProposalsInterface.sol";
import "../../../interface/rewards/claims/RocketClaimTrustedNodeInterface.sol";
import "../../../interface/util/AddressSetStorageInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";


// The Trusted Node DAO Actions
contract RocketDAONodeTrustedActions is RocketBase, RocketDAONodeTrustedActionsInterface {

    using SafeMath for uint;

    // Events
    event ActionJoined(address indexed nodeAddress, uint256 rplBondAmount, uint256 time);
    event ActionLeave(address indexed nodeAddress, uint256 rplBondAmount, uint256 time);
    event ActionKick(address indexed nodeAddress, uint256 rplBondAmount, uint256 time);
    event ActionChallengeMade(address indexed nodeChallengedAddress, address indexed nodeChallengerAddress, uint256 time);
    event ActionChallengeDecided(address indexed nodeChallengedAddress, address indexed nodeChallengeDeciderAddress, bool success, uint256 time);


    // The namespace for any data stored in the trusted node DAO (do not change)
    string constant private daoNameSpace = "dao.trustednodes.";


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 2;
    }

    /*** Internal Methods **********************/

    // Add a new member to the DAO
    function _memberAdd(address _nodeAddress, uint256 _rplBondAmountPaid) private onlyRegisteredNode(_nodeAddress) {
        // Load contracts
        RocketDAONodeTrustedInterface rocketDAONode = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Check current node status
        require(rocketDAONode.getMemberIsValid(_nodeAddress) != true, "This node is already part of the trusted node DAO");
        // Flag them as a member now that they have accepted the invitation and record the size of the bond they paid
        setBool(keccak256(abi.encodePacked(daoNameSpace, "member", _nodeAddress)), true);
        // Add the bond amount they have paid
        if(_rplBondAmountPaid > 0) setUint(keccak256(abi.encodePacked(daoNameSpace, "member.bond.rpl", _nodeAddress)), _rplBondAmountPaid);
        // Record the block number they joined at
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.joined.time", _nodeAddress)), block.timestamp);
         // Add to member index now
        addressSetStorage.addItem(keccak256(abi.encodePacked(daoNameSpace, "member.index")), _nodeAddress); 
    }

    // Remove a member from the DAO
    function _memberRemove(address _nodeAddress) private onlyTrustedNode(_nodeAddress) {
        // Load contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Remove their membership now
        deleteBool(keccak256(abi.encodePacked(daoNameSpace, "member", _nodeAddress)));
        deleteAddress(keccak256(abi.encodePacked(daoNameSpace, "member.address", _nodeAddress)));
        deleteString(keccak256(abi.encodePacked(daoNameSpace, "member.id", _nodeAddress)));
        deleteString(keccak256(abi.encodePacked(daoNameSpace, "member.url", _nodeAddress)));
        deleteUint(keccak256(abi.encodePacked(daoNameSpace, "member.bond.rpl", _nodeAddress)));
        deleteUint(keccak256(abi.encodePacked(daoNameSpace, "member.joined.time", _nodeAddress)));
        deleteUint(keccak256(abi.encodePacked(daoNameSpace, "member.challenged.time", _nodeAddress)));
        // Clean up the invited/leave proposals
        deleteUint(keccak256(abi.encodePacked(daoNameSpace, "member.executed.time", "invited", _nodeAddress)));
        deleteUint(keccak256(abi.encodePacked(daoNameSpace, "member.executed.time", "leave", _nodeAddress)));
         // Remove from member index now
        addressSetStorage.removeItem(keccak256(abi.encodePacked(daoNameSpace, "member.index")), _nodeAddress); 
    }

    // A member official joins the DAO with their bond ready, if successful they are added as a member
    function _memberJoin(address _nodeAddress) private {
        // Set some intiial contract address
        address rocketVaultAddress = getContractAddress("rocketVault");
        address rocketTokenRPLAddress = getContractAddress("rocketTokenRPL");
        // Load contracts
        IERC20 rplInflationContract = IERC20(rocketTokenRPLAddress);
        RocketVaultInterface rocketVault = RocketVaultInterface(rocketVaultAddress);
        RocketDAONodeTrustedInterface rocketDAONode = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        RocketDAONodeTrustedSettingsMembersInterface rocketDAONodeTrustedSettingsMembers = RocketDAONodeTrustedSettingsMembersInterface(getContractAddress("rocketDAONodeTrustedSettingsMembers"));
        RocketDAONodeTrustedSettingsProposalsInterface rocketDAONodeTrustedSettingsProposals = RocketDAONodeTrustedSettingsProposalsInterface(getContractAddress("rocketDAONodeTrustedSettingsProposals"));
        // The time that the member was successfully invited to join the DAO
        uint256 memberInvitedTime = rocketDAONode.getMemberProposalExecutedTime("invited", _nodeAddress);
        // Have they been invited?
        require(memberInvitedTime > 0, "This node has not been invited to join");
        // The current member bond amount in RPL that's required
        uint256 rplBondAmount = rocketDAONodeTrustedSettingsMembers.getRPLBond();
        // Has their invite expired?
        require(memberInvitedTime.add(rocketDAONodeTrustedSettingsProposals.getActionTime()) > block.timestamp, "This node's invitation to join has expired, please apply again");
        // Verify they have allowed this contract to spend their RPL for the bond
        require(rplInflationContract.allowance(_nodeAddress, address(this)) >= rplBondAmount, "Not enough allowance given to RocketDAONodeTrusted contract for transfer of RPL bond tokens");
        // Transfer the tokens to this contract now
        require(rplInflationContract.transferFrom(_nodeAddress, address(this), rplBondAmount), "Token transfer to RocketDAONodeTrusted contract was not successful");
        // Allow RocketVault to transfer these tokens to itself now
        require(rplInflationContract.approve(rocketVaultAddress, rplBondAmount), "Approval for RocketVault to spend RocketDAONodeTrusted RPL bond tokens was not successful");
        // Let vault know it can move these tokens to itself now and credit the balance to this contract
        rocketVault.depositToken(getContractName(address(this)), IERC20(rocketTokenRPLAddress), rplBondAmount);
        // Add them as a member now that they have accepted the invitation and record the size of the bond they paid
        _memberAdd(_nodeAddress, rplBondAmount);
        // Log it
        emit ActionJoined(_nodeAddress, rplBondAmount, block.timestamp);
    }
  
    /*** Action Methods ************************/

    // When a new member has been successfully invited to join, they must call this method to join officially
    // They will be required to have the RPL bond amount in their account
    // This method allows us to only allow them to join if they have a working node account and have been officially invited
    function actionJoin() override external onlyRegisteredNode(msg.sender) onlyLatestContract("rocketDAONodeTrustedActions", address(this)) {
        _memberJoin(msg.sender);
    }

    // When the DAO has suffered a loss of members due to unforseen blackswan issue and has < the min required amount (3), a regular bonded node can directly join as a member and recover the DAO
    // They will be required to have the RPL bond amount in their account. This is called directly from RocketDAONodeTrusted.
    function actionJoinRequired(address _nodeAddress) override external onlyRegisteredNode(_nodeAddress) onlyLatestContract("rocketDAONodeTrusted", msg.sender) {
        _memberJoin(_nodeAddress);
    }
    
    // When a new member has successfully requested to leave with a proposal, they must call this method to leave officially and receive their RPL bond
    function actionLeave(address _rplBondRefundAddress) override external onlyTrustedNode(msg.sender) onlyLatestContract("rocketDAONodeTrustedActions", address(this)) {
        // Load contracts
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        RocketDAONodeTrustedInterface rocketDAONode = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        RocketDAONodeTrustedSettingsProposalsInterface rocketDAONodeTrustedSettingsProposals = RocketDAONodeTrustedSettingsProposalsInterface(getContractAddress("rocketDAONodeTrustedSettingsProposals"));
        // Check this wouldn't dip below the min required trusted nodes
        require(rocketDAONode.getMemberCount() > rocketDAONode.getMemberMinRequired(), "Member count will fall below min required");
        // Get the time that they were approved to leave at
        uint256 leaveAcceptedTime = rocketDAONode.getMemberProposalExecutedTime("leave", msg.sender);
        // Has their leave request expired?
        require(leaveAcceptedTime.add(rocketDAONodeTrustedSettingsProposals.getActionTime()) > block.timestamp, "This member has not been approved to leave or request has expired, please apply to leave again");
        // They were successful, lets refund their RPL Bond
        uint256 rplBondRefundAmount = rocketDAONode.getMemberRPLBondAmount(msg.sender);
        // Refund
        if(rplBondRefundAmount > 0) {
            // Valid withdrawal address
            require(_rplBondRefundAddress != address(0x0), "Member has not supplied a valid address for their RPL bond refund");
            // Send tokens now
            rocketVault.withdrawToken(_rplBondRefundAddress, IERC20(getContractAddress("rocketTokenRPL")), rplBondRefundAmount);
        }
        // Remove them now
        _memberRemove(msg.sender);
        // Log it
        emit ActionLeave(msg.sender, rplBondRefundAmount, block.timestamp);
    }


    // A member can be evicted from the DAO by proposal, send their remaining RPL balance to them and remove from the DAO
    // Is run via the main DAO contract when the proposal passes and is executed
    function actionKick(address _nodeAddress, uint256 _rplFine) override external onlyTrustedNode(_nodeAddress) onlyLatestContract("rocketDAONodeTrustedProposals", msg.sender) {
        // Load contracts
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        RocketDAONodeTrustedInterface rocketDAONode = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        IERC20 rplToken = IERC20(getContractAddress("rocketTokenRPL"));
        // Get the
        uint256 rplBondRefundAmount = rocketDAONode.getMemberRPLBondAmount(_nodeAddress);
        // Refund
        if (rplBondRefundAmount > 0) {
            // Send tokens now if the vault can cover it
            if(rplToken.balanceOf(address(rocketVault)) >= rplBondRefundAmount) rocketVault.withdrawToken(_nodeAddress, IERC20(getContractAddress("rocketTokenRPL")), rplBondRefundAmount);
        }
        // Burn the fine
        if (_rplFine > 0) {
            rocketVault.burnToken(ERC20Burnable(getContractAddress("rocketTokenRPL")), _rplFine);
        }
        // Remove the member now
        _memberRemove(_nodeAddress);
        // Log it
        emit ActionKick(_nodeAddress, rplBondRefundAmount, block.timestamp);   
    }


    // In the event that the majority/all of members go offline permanently and no more proposals could be passed, a current member or a regular node can 'challenge' a DAO members node to respond
    // If it does not respond in the given window, it can be removed as a member. The one who removes the member after the challenge isn't met, must be another node other than the proposer to provide some oversight
    // This should only be used in an emergency situation to recover the DAO. Members that need removing when consensus is still viable, should be done via the 'kick' method.
    function actionChallengeMake(address _nodeAddress) override external onlyTrustedNode(_nodeAddress) onlyRegisteredNode(msg.sender) onlyLatestContract("rocketDAONodeTrustedActions", address(this)) payable {
        // Load contracts
        RocketDAONodeTrustedInterface rocketDAONode = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        RocketDAONodeTrustedSettingsMembersInterface rocketDAONodeTrustedSettingsMembers = RocketDAONodeTrustedSettingsMembersInterface(getContractAddress("rocketDAONodeTrustedSettingsMembers"));
        // Members can challenge other members for free, but for a regular bonded node to challenge a DAO member, requires non-refundable payment to prevent spamming
        if(rocketDAONode.getMemberIsValid(msg.sender) != true) require(msg.value == rocketDAONodeTrustedSettingsMembers.getChallengeCost(), "Non DAO members must pay ETH to challenge a members node");
        // Can't challenge yourself duh
        require(msg.sender != _nodeAddress, "You cannot challenge yourself");
        // Is this member already being challenged?
        require(!rocketDAONode.getMemberIsChallenged(_nodeAddress), "Member is already being challenged");
        // Has this node recently made another challenge and not waited for the cooldown to pass?
        require(getUint(keccak256(abi.encodePacked(daoNameSpace, "node.challenge.created.time", msg.sender))).add(rocketDAONodeTrustedSettingsMembers.getChallengeCooldown()) < block.timestamp, "You must wait for the challenge cooldown to pass before issuing another challenge");
        // Ok challenge accepted
        // Record the last time this member challenged
        setUint(keccak256(abi.encodePacked(daoNameSpace, "node.challenge.created.time", msg.sender)), block.timestamp);
        // Record the challenge block now
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.challenged.time", _nodeAddress)), block.timestamp);
        // Record who made the challenge
        setAddress(keccak256(abi.encodePacked(daoNameSpace, "member.challenged.by", _nodeAddress)), msg.sender);
        // Log it
        emit ActionChallengeMade(_nodeAddress, msg.sender, block.timestamp);
    }

    
    // Decides the success of a challenge. If called by the challenged node within the challenge window, the challenge is defeated and the member stays as they have indicated their node is still alive.
    // If called after the challenge window has passed by anyone except the original challenge initiator, then the challenge has succeeded and the member is removed
    function actionChallengeDecide(address _nodeAddress) override external onlyTrustedNode(_nodeAddress) onlyRegisteredNode(msg.sender) onlyLatestContract("rocketDAONodeTrustedActions", address(this)) {
        // Load contracts
        RocketDAONodeTrustedSettingsMembersInterface rocketDAONodeTrustedSettingsMembers = RocketDAONodeTrustedSettingsMembersInterface(getContractAddress("rocketDAONodeTrustedSettingsMembers"));
        // Was the challenge successful?
        bool challengeSuccess = false;
        // Get the block the challenge was initiated at
        bytes32 challengeTimeKey = keccak256(abi.encodePacked(daoNameSpace, "member.challenged.time", _nodeAddress));
        uint256 challengeTime = getUint(challengeTimeKey);
        // If challenge time is 0, the member hasn't been challenged or they have successfully responded to the challenge previously
        require(challengeTime > 0, "Member hasn't been challenged or they have successfully responded to the challenge already");
        // Allow the challenged member to refute the challenge at anytime. If the window has passed and the challenge node does not run this method, any member can decide the challenge and eject the absent member
        // Is it the node being challenged?
        if(_nodeAddress == msg.sender) {
            // Challenge is defeated, node has responded
            deleteUint(challengeTimeKey);
        }else{
            // The challenge refute window has passed, the member can be ejected now
            require(challengeTime.add(rocketDAONodeTrustedSettingsMembers.getChallengeWindow()) < block.timestamp, "Refute window has not yet passed");
            // Node has been challenged and failed to respond in the given window, remove them as a member and their bond is burned
            _memberRemove(_nodeAddress);
            // Challenge was successful
            challengeSuccess = true;
        }
        // Log it
        emit ActionChallengeDecided(_nodeAddress, msg.sender, challengeSuccess, block.timestamp);
    }


}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../RocketBase.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedProposalsInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedActionsInterface.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedUpgradeInterface.sol";
import "../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsInterface.sol";
import "../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsProposalsInterface.sol";
import "../../../interface/dao/RocketDAOProposalInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


// The Trusted Node DAO Proposals 
contract RocketDAONodeTrustedProposals is RocketBase, RocketDAONodeTrustedProposalsInterface {  

    using SafeMath for uint;

    // The namespace for any data stored in the trusted node DAO (do not change)
    string constant daoNameSpace = "dao.trustednodes.";

    // Only allow certain contracts to execute methods
    modifier onlyExecutingContracts() {
        // Methods are either executed by bootstrapping methods in rocketDAONodeTrusted or by people executing passed proposals in rocketDAOProposal
        require(msg.sender == getContractAddress("rocketDAONodeTrusted") || msg.sender == getContractAddress("rocketDAOProposal"), "Sender is not permitted to access executing methods");
        _;
    }

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }

        
    /*** Proposals **********************/

    // Create a DAO proposal with calldata, if successful will be added to a queue where it can be executed
    // A general message can be passed by the proposer along with the calldata payload that can be executed if the proposal passes
    function propose(string memory _proposalMessage, bytes memory _payload) override external onlyTrustedNode(msg.sender) onlyLatestContract("rocketDAONodeTrustedProposals", address(this)) returns (uint256) {
        // Load contracts
        RocketDAOProposalInterface daoProposal = RocketDAOProposalInterface(getContractAddress("rocketDAOProposal"));
        RocketDAONodeTrustedInterface daoNodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        RocketDAONodeTrustedSettingsProposalsInterface rocketDAONodeTrustedSettingsProposals = RocketDAONodeTrustedSettingsProposalsInterface(getContractAddress("rocketDAONodeTrustedSettingsProposals"));
        // Check this user can make a proposal now
        require(daoNodeTrusted.getMemberLastProposalTime(msg.sender).add(rocketDAONodeTrustedSettingsProposals.getCooldownTime()) <= block.timestamp, "Member has not waited long enough to make another proposal");
        // Require the min amount of members are in to make a proposal
        require(daoNodeTrusted.getMemberCount() >= daoNodeTrusted.getMemberMinRequired(), "Min member count not met to allow proposals to be added");
        // Record the last time this user made a proposal
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.proposal.lasttime", msg.sender)), block.timestamp);
        // Create the proposal
        return daoProposal.add(msg.sender, "rocketDAONodeTrustedProposals", _proposalMessage, block.timestamp.add(rocketDAONodeTrustedSettingsProposals.getVoteDelayTime()), rocketDAONodeTrustedSettingsProposals.getVoteTime(), rocketDAONodeTrustedSettingsProposals.getExecuteTime(), daoNodeTrusted.getMemberQuorumVotesRequired(), _payload);
    }

    // Vote on a proposal
    function vote(uint256 _proposalID, bool _support) override external onlyTrustedNode(msg.sender) onlyLatestContract("rocketDAONodeTrustedProposals", address(this)) {
        // Load contracts
        RocketDAOProposalInterface daoProposal = RocketDAOProposalInterface(getContractAddress("rocketDAOProposal"));
        RocketDAONodeTrustedInterface daoNodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        // Did they join after this proposal was created? If so, they can't vote or it'll throw off the set proposalVotesRequired 
        require(daoNodeTrusted.getMemberJoinedTime(msg.sender) < daoProposal.getCreated(_proposalID), "Member cannot vote on proposal created before they became a member");
        // Vote now, one vote per trusted node member
        daoProposal.vote(msg.sender, 1 ether, _proposalID, _support);
    }
    
    // Cancel a proposal 
    function cancel(uint256 _proposalID) override external onlyTrustedNode(msg.sender) onlyLatestContract("rocketDAONodeTrustedProposals", address(this)) {
        // Load contracts
        RocketDAOProposalInterface daoProposal = RocketDAOProposalInterface(getContractAddress("rocketDAOProposal"));
        // Cancel now, will succeed if it is the original proposer
        daoProposal.cancel(msg.sender, _proposalID);
    }

    // Execute a proposal 
    function execute(uint256 _proposalID) override external onlyLatestContract("rocketDAONodeTrustedProposals", address(this)) {
        // Load contracts
        RocketDAOProposalInterface daoProposal = RocketDAOProposalInterface(getContractAddress("rocketDAOProposal"));
        // Execute now
        daoProposal.execute(_proposalID);
    }



    /*** Proposal - Members **********************/

    // A new DAO member being invited, can only be done via a proposal or in bootstrap mode
    // Provide an ID that indicates who is running the trusted node and the address of the registered node that they wish to propose joining the dao
    function proposalInvite(string memory _id, string memory _url, address _nodeAddress) override external onlyExecutingContracts onlyRegisteredNode(_nodeAddress) {
        // Their proposal executed, record the block
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.executed.time", "invited", _nodeAddress)), block.timestamp);
        // Ok all good, lets get their invitation and member data setup
        // They are initially only invited to join, so their membership isn't set as true until they accept it in RocketDAONodeTrustedActions
        _memberInit(_id, _url, _nodeAddress);
    }


    // A current member proposes leaving the trusted node DAO, when successful they will be allowed to collect their RPL bond
    function proposalLeave(address _nodeAddress) override external onlyExecutingContracts onlyTrustedNode(_nodeAddress) {
        // Load contracts
        RocketDAONodeTrustedInterface daoNodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        // Check this wouldn't dip below the min required trusted nodes (also checked when the node has a successful proposal and attempts to exit)
        require(daoNodeTrusted.getMemberCount() > daoNodeTrusted.getMemberMinRequired(), "Member count will fall below min required");
        // Their proposal to leave has been accepted, record the block
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.executed.time", "leave", _nodeAddress)), block.timestamp);
    }


    // Propose to kick a current member from the DAO with an optional RPL bond fine
    function proposalKick(address _nodeAddress, uint256 _rplFine) override external onlyExecutingContracts onlyTrustedNode(_nodeAddress) {
        // Load contracts
        RocketDAONodeTrustedInterface daoNodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        RocketDAONodeTrustedActionsInterface daoActionsContract = RocketDAONodeTrustedActionsInterface(getContractAddress("rocketDAONodeTrustedActions"));
        // How much is their RPL bond?
        uint256 rplBondAmount = daoNodeTrusted.getMemberRPLBondAmount(_nodeAddress);
        // Check fine amount can be covered
        require(_rplFine <= rplBondAmount, "RPL Fine must be lower or equal to the RPL bond amount of the node being kicked");
        // Set their bond amount minus the fine
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.bond.rpl", _nodeAddress)), rplBondAmount.sub(_rplFine));
        // Kick them now
        daoActionsContract.actionKick(_nodeAddress, _rplFine);
    }


    /*** Proposal - Settings ***************/

    // Change one of the current uint256 settings of the DAO
    function proposalSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) override external onlyExecutingContracts() {
        // Load contracts
        RocketDAONodeTrustedSettingsInterface rocketDAONodeTrustedSettings = RocketDAONodeTrustedSettingsInterface(getContractAddress(_settingContractName));
        // Lets update
        rocketDAONodeTrustedSettings.setSettingUint(_settingPath, _value);
    }

    // Change one of the current bool settings of the DAO
    function proposalSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) override external onlyExecutingContracts() {
        // Load contracts
        RocketDAONodeTrustedSettingsInterface rocketDAONodeTrustedSettings = RocketDAONodeTrustedSettingsInterface(getContractAddress(_settingContractName));
        // Lets update
        rocketDAONodeTrustedSettings.setSettingBool(_settingPath, _value);
    }


    /*** Proposal - Upgrades ***************/

    // Upgrade contracts or ABI's if the DAO agrees
    function proposalUpgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) override external onlyExecutingContracts() {
        // Load contracts
        RocketDAONodeTrustedUpgradeInterface rocketDAONodeTrustedUpgradeInterface = RocketDAONodeTrustedUpgradeInterface(getContractAddress("rocketDAONodeTrustedUpgrade"));
        // Lets update
        rocketDAONodeTrustedUpgradeInterface.upgrade(_type, _name, _contractAbi, _contractAddress);
    }


    /*** Internal ***************/

    // Add a new potential members data, they are not official members yet, just propsective
    function _memberInit(string memory _id, string memory _url, address _nodeAddress) private onlyRegisteredNode(_nodeAddress) {
        // Load contracts
        RocketDAONodeTrustedInterface daoNodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        // Check current node status
        require(!daoNodeTrusted.getMemberIsValid(_nodeAddress), "This node is already part of the trusted node DAO");
        // Verify the ID is min 3 chars
        require(bytes(_id).length >= 3, "The ID for this new member must be at least 3 characters");
        // Check URL length
        require(bytes(_url).length >= 6, "The URL for this new member must be at least 6 characters");
        // Member initial data, not official until the bool is flagged as true
        setBool(keccak256(abi.encodePacked(daoNameSpace, "member", _nodeAddress)), false);
        setAddress(keccak256(abi.encodePacked(daoNameSpace, "member.address", _nodeAddress)), _nodeAddress);
        setString(keccak256(abi.encodePacked(daoNameSpace, "member.id", _nodeAddress)), _id);
        setString(keccak256(abi.encodePacked(daoNameSpace, "member.url", _nodeAddress)), _url);
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.bond.rpl", _nodeAddress)), 0);
        setUint(keccak256(abi.encodePacked(daoNameSpace, "member.joined.time", _nodeAddress)), 0);
    }
        

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../RocketBase.sol";
import "../../../interface/dao/node/RocketDAONodeTrustedUpgradeInterface.sol";

// Handles network contract upgrades

contract RocketDAONodeTrustedUpgrade is RocketBase, RocketDAONodeTrustedUpgradeInterface {

    // Events
    event ContractUpgraded(bytes32 indexed name, address indexed oldAddress, address indexed newAddress, uint256 time);
    event ContractAdded(bytes32 indexed name, address indexed newAddress, uint256 time);
    event ABIUpgraded(bytes32 indexed name, uint256 time);
    event ABIAdded(bytes32 indexed name, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Main accessor for performing an upgrade, be it a contract or abi for a contract
    // Will require > 50% of trusted DAO members to run when bootstrap mode is disabled
    function upgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) override external onlyLatestContract("rocketDAONodeTrustedProposals", msg.sender) {
        // What action are we performing?
        bytes32 typeHash = keccak256(abi.encodePacked(_type));
        // Lets do it!
        if(typeHash == keccak256(abi.encodePacked("upgradeContract"))) _upgradeContract(_name, _contractAddress, _contractAbi);
        if(typeHash == keccak256(abi.encodePacked("addContract"))) _addContract(_name, _contractAddress, _contractAbi);
        if(typeHash == keccak256(abi.encodePacked("upgradeABI"))) _upgradeABI(_name, _contractAbi);
        if(typeHash == keccak256(abi.encodePacked("addABI"))) _addABI(_name, _contractAbi);
    }


    /*** Internal Upgrade Methods for the Trusted Node DAO ****************/

    // Upgrade a network contract
    function _upgradeContract(string memory _name, address _contractAddress, string memory _contractAbi) internal {
        // Check contract being upgraded
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(nameHash != keccak256(abi.encodePacked("rocketVault")),               "Cannot upgrade the vault");
        require(nameHash != keccak256(abi.encodePacked("rocketTokenRETH")),           "Cannot upgrade token contracts");
        require(nameHash != keccak256(abi.encodePacked("rocketTokenRPL")),            "Cannot upgrade token contracts");
        require(nameHash != keccak256(abi.encodePacked("rocketTokenRPLFixedSupply")), "Cannot upgrade token contracts");
        require(nameHash != keccak256(abi.encodePacked("casperDeposit")),             "Cannot upgrade the casper deposit contract");
        require(nameHash != keccak256(abi.encodePacked("rocketMinipoolPenalty")),      "Cannot upgrade minipool penalty contract");
        // Get old contract address & check contract exists
        address oldContractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _name)));
        require(oldContractAddress != address(0x0), "Contract does not exist");
        // Check new contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(_contractAddress != oldContractAddress, "The contract address cannot be set to its current address");
        require(!getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))), "Contract address is already in use");
        // Check ABI isn't empty
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Register new contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
        setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
        // Deregister old contract
        deleteString(keccak256(abi.encodePacked("contract.name", oldContractAddress)));
        deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
        // Emit contract upgraded event
        emit ContractUpgraded(nameHash, oldContractAddress, _contractAddress, block.timestamp);
    }

    // Add a new network contract
    function _addContract(string memory _name, address _contractAddress, string memory _contractAbi) internal {
        // Check contract name
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(bytes(_name).length > 0, "Invalid contract name");
        // Cannot add contract if it already exists (use upgradeContract instead)
        require(getAddress(keccak256(abi.encodePacked("contract.address", _name))) == address(0x0), "Contract name is already in use");
        // Cannot add contract if already in use as ABI only
        string memory existingAbi = getString(keccak256(abi.encodePacked("contract.abi", _name)));
        require(bytes(existingAbi).length == 0, "Contract name is already in use");
        // Check contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(!getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))), "Contract address is already in use");
        // Check ABI isn't empty
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Register contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
        setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
        // Emit contract added event
        emit ContractAdded(nameHash, _contractAddress, block.timestamp);
    }

    // Upgrade a network contract ABI
    function _upgradeABI(string memory _name, string memory _contractAbi) internal {
        // Check ABI exists
        string memory existingAbi = getString(keccak256(abi.encodePacked("contract.abi", _name)));
        require(bytes(existingAbi).length > 0, "ABI does not exist");
        // Sanity checks
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        require(keccak256(bytes(existingAbi)) != keccak256(bytes(_contractAbi)), "ABIs are identical");
        // Set ABI
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
        // Emit ABI upgraded event
        emit ABIUpgraded(keccak256(abi.encodePacked(_name)), block.timestamp);
    }

    // Add a new network contract ABI
    function _addABI(string memory _name, string memory _contractAbi) internal {
        // Check ABI name
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(bytes(_name).length > 0, "Invalid ABI name");
        // Sanity check
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Cannot add ABI if name is already used for an existing network contract
        require(getAddress(keccak256(abi.encodePacked("contract.address", _name))) == address(0x0), "ABI name is already in use");
        // Cannot add ABI if ABI already exists for this name (use upgradeABI instead)
        string memory existingAbi = getString(keccak256(abi.encodePacked("contract.abi", _name)));
        require(bytes(existingAbi).length == 0, "ABI name is already in use");
        // Set ABI
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
        // Emit ABI added event
        emit ABIAdded(nameHash, block.timestamp);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../../RocketBase.sol";
import "../../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsInterface.sol";

// Settings in RP which the DAO will have full control over
// This settings contract enables storage using setting paths with namespaces, rather than explicit set methods
abstract contract RocketDAONodeTrustedSettings is RocketBase, RocketDAONodeTrustedSettingsInterface {


    // The namespace for a particular group of settings
    bytes32 settingNameSpace;


    // Only allow updating from the DAO proposals contract
    modifier onlyDAONodeTrustedProposal() {
        // If this contract has been initialised, only allow access from the proposals contract
        if(getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) require(getContractAddress("rocketDAONodeTrustedProposals") == msg.sender, "Only DAO Node Trusted Proposals contract can update a setting");
        _;
    }


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress, string memory _settingNameSpace) RocketBase(_rocketStorageAddress) {
        // Apply the setting namespace
        settingNameSpace = keccak256(abi.encodePacked("dao.trustednodes.setting.", _settingNameSpace));
    }


    /*** Uints  ****************/

    // A general method to return any setting given the setting path is correct, only accepts uints
    function getSettingUint(string memory _settingPath) public view override returns (uint256) {
        return getUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)));
    } 

    // Update a Uint setting, can only be executed by the DAO contract when a majority on a setting proposal has passed and been executed
    function setSettingUint(string memory _settingPath, uint256 _value) virtual public override onlyDAONodeTrustedProposal {
        // Update setting now
        setUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    } 
   

    /*** Bools  ****************/

    // A general method to return any setting given the setting path is correct, only accepts bools
    function getSettingBool(string memory _settingPath) public view override returns (bool) {
        return getBool(keccak256(abi.encodePacked(settingNameSpace, _settingPath)));
    } 

    // Update a setting, can only be executed by the DAO contract when a majority on a setting proposal has passed and been executed
    function setSettingBool(string memory _settingPath, bool _value) virtual public override onlyDAONodeTrustedProposal {
        // Update setting now
        setBool(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAONodeTrustedSettings.sol";
import "../../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMembersInterface.sol";


// The Trusted Node DAO Members 
contract RocketDAONodeTrustedSettingsMembers is RocketDAONodeTrustedSettings, RocketDAONodeTrustedSettingsMembersInterface { 

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAONodeTrustedSettings(_rocketStorageAddress, "members") {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Init settings
            setSettingUint("members.quorum", 0.51 ether);                    // Member quorum threshold that must be met for proposals to pass (51%)
            setSettingUint("members.rplbond", 1750 ether);                   // Bond amount required for a new member to join (in RPL)
            setSettingUint("members.minipool.unbonded.max", 30);             // The amount of unbonded minipool validators members can make (these validators are only used if no regular bonded validators are available)
            setSettingUint("members.minipool.unbonded.min.fee", 0.8 ether);  // Node fee must be over this percentage of the maximum fee before validator members are allowed to make unbonded pools (80%)
            setSettingUint("members.challenge.cooldown", 7 days);            // How long a member must wait before performing another challenge in seconds
            setSettingUint("members.challenge.window", 7 days);              // How long a member has to respond to a challenge in seconds
            setSettingUint("members.challenge.cost", 1 ether);               // How much it costs a non-member to challenge a members node. It's free for current members to challenge other members.
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }


    /*** Set Uint *****************************************/

    // Update a setting, overrides inherited setting method with extra checks for this contract
    function setSettingUint(string memory _settingPath, uint256 _value) override public onlyDAONodeTrustedProposal {
        // Some safety guards for certain settings
        if(keccak256(abi.encodePacked(_settingPath)) == keccak256(abi.encodePacked("members.quorum"))) require(_value > 0 ether && _value <= 0.9 ether, "Quorum setting must be > 0 & <= 90%");
        // Update setting now
        setUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    } 
  
    // Getters

    // The member proposal quorum threshold for this DAO
    function getQuorum() override external view returns (uint256) {
        return getSettingUint("members.quorum");
    }

    // Amount of RPL needed for a new member
    function getRPLBond() override external view returns (uint256) {
        return getSettingUint("members.rplbond");
    }

    // The amount of unbonded minipool validators members can make (these validators are only used if no regular bonded validators are available)
    function getMinipoolUnbondedMax() override external view returns (uint256) {
        return getSettingUint("members.minipool.unbonded.max");
    }

    // Node fee must be over this percentage of the maximum fee before validator members are allowed to make unbonded pools
    function getMinipoolUnbondedMinFee() override external view returns (uint256) {
        return getSettingUint('members.minipool.unbonded.min.fee');
    }

    // How long a member must wait before making consecutive challenges in seconds
    function getChallengeCooldown() override external view returns (uint256) {
        return getSettingUint("members.challenge.cooldown");
    }

    // The window available to meet any node challenges in seconds
    function getChallengeWindow() override external view returns (uint256) {
        return getSettingUint("members.challenge.window");
    }

    // How much it costs a non-member to challenge a members node. It's free for current members to challenge other members.
    function getChallengeCost() override external view returns (uint256) {
        return getSettingUint("members.challenge.cost");
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./RocketDAONodeTrustedSettings.sol";
import "../../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMinipoolInterface.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";


/// @notice The Trusted Node DAO Minipool settings
contract RocketDAONodeTrustedSettingsMinipool is RocketDAONodeTrustedSettings, RocketDAONodeTrustedSettingsMinipoolInterface {

    using SafeMath for uint;

    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAONodeTrustedSettings(_rocketStorageAddress, "minipool") {
        // Set version
        version = 2;

        // If deployed during initial deployment, initialise now (otherwise must be called after upgrade)
        if (!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Init settings
            setSettingUint("minipool.scrub.period", 12 hours);
            setSettingUint("minipool.promotion.scrub.period", 3 days);
            setSettingUint("minipool.scrub.quorum", 0.51 ether);
            setSettingBool("minipool.scrub.penalty.enabled", false);
            setSettingUint("minipool.bond.reduction.window.start", 2 days);
            setSettingUint("minipool.bond.reduction.window.length", 2 days);
            setSettingUint("minipool.cancel.bond.reduction.quorum", 0.51 ether);
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

    /// @notice Update a setting, overrides inherited setting method with extra checks for this contract
    /// @param _settingPath The path of the setting within this contract's namespace
    /// @param _value The value to set it to
    function setSettingUint(string memory _settingPath, uint256 _value) override public onlyDAONodeTrustedProposal {
        // Some safety guards for certain settings
        if(getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            if(keccak256(abi.encodePacked(_settingPath)) == keccak256(abi.encodePacked("minipool.scrub.period"))) {
                RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
                require(_value <= (rocketDAOProtocolSettingsMinipool.getLaunchTimeout().sub(1 hours)), "Scrub period must be less than launch timeout");
            }
        }
        // Update setting now
        setUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }

    // Getters

    /// @notice How long minipools must wait before moving to staking status (can be scrubbed by ODAO before then)
    function getScrubPeriod() override external view returns (uint256) {
        return getSettingUint("minipool.scrub.period");
    }

    /// @notice How long minipools must wait before promoting a vacant minipool to staking status (can be scrubbed by ODAO before then)
    function getPromotionScrubPeriod() override external view returns (uint256) {
        return getSettingUint("minipool.promotion.scrub.period");
    }

    /// @notice Returns the required number of trusted nodes to vote to scrub a minipool
    function getScrubQuorum() override external view returns (uint256) {
        return getSettingUint("minipool.scrub.quorum");
    }

    /// @notice Returns the required number of trusted nodes to vote to cancel a bond reduction
    function getCancelBondReductionQuorum() override external view returns (uint256) {
        return getSettingUint("minipool.cancel.bond.reduction.quorum");
    }

    /// @notice Returns true if scrubbing results in an RPL penalty for the node operator
    function getScrubPenaltyEnabled() override external view returns (bool) {
        return getSettingBool("minipool.scrub.penalty.enabled");
    }

    /// @notice Returns true if the given time is within the bond reduction window
    function isWithinBondReductionWindow(uint256 _time) override external view returns (bool) {
        uint256 start = getBondReductionWindowStart();
        uint256 length = getBondReductionWindowLength();
        return (_time >= start && _time < (start.add(length)));
    }

    /// @notice Returns the start of the bond reduction window
    function getBondReductionWindowStart() override public view returns (uint256) {
        return getSettingUint("minipool.bond.reduction.window.start");
    }

    /// @notice Returns the length of the bond reduction window
    function getBondReductionWindowLength() override public view returns (uint256) {
        return getSettingUint("minipool.bond.reduction.window.length");
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAONodeTrustedSettings.sol";
import "../../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsProposalsInterface.sol";


// The Trusted Node DAO Members 
contract RocketDAONodeTrustedSettingsProposals is RocketDAONodeTrustedSettings, RocketDAONodeTrustedSettingsProposalsInterface { 

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAONodeTrustedSettings(_rocketStorageAddress, "proposals") {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Init settings
            setSettingUint("proposal.cooldown.time", 2 days);               // How long before a member can make sequential proposals
            setSettingUint("proposal.vote.time", 2 weeks);                  // How long a proposal can be voted on
            setSettingUint("proposal.vote.delay.time", 1 weeks);            // How long before a proposal can be voted on after it is created
            setSettingUint("proposal.execute.time", 4 weeks);               // How long a proposal can be executed after its voting period is finished
            setSettingUint("proposal.action.time", 4 weeks);                // Certain proposals require a secondary action to be run after the proposal is successful (joining, leaving etc). This is how long until that action expires
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

  
    // Getters

    // How long before a member can make sequential proposals
    function getCooldownTime() override external view returns (uint256) {
        return getSettingUint("proposal.cooldown.time");
    }

    // How long a proposal can be voted on
    function getVoteTime() override external view returns (uint256) {
        return getSettingUint("proposal.vote.time");
    }

    // How long before a proposal can be voted on after it is created
    function getVoteDelayTime() override external view returns (uint256) {
        return getSettingUint("proposal.vote.delay.time");
    }

    // How long a proposal can be executed after its voting period is finished
    function getExecuteTime() override external view returns (uint256) {
        return getSettingUint("proposal.execute.time");
    }

    // Certain proposals require a secondary action to be run after the proposal is successful (joining, leaving etc). This is how long until that action expires
    function getActionTime() override external view returns (uint256) {
        return getSettingUint("proposal.action.time");
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./RocketDAONodeTrustedSettings.sol";
import "../../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsRewardsInterface.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";


// The Trusted Node DAO Rewards settings

contract RocketDAONodeTrustedSettingsRewards is RocketDAONodeTrustedSettings, RocketDAONodeTrustedSettingsRewardsInterface {

    using SafeMath for uint;

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAONodeTrustedSettings(_rocketStorageAddress, "rewards") {
        // Set version
        version = 2;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Init settings
            setSettingBool("rewards.network.enabled", true);
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

    // Update a setting, overrides inherited setting method with extra checks for this contract
    function setSettingBool(string memory _settingPath, bool _value) override public onlyDAONodeTrustedProposal {
        // Some safety guards for certain settings
        if(getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // oDAO should never disable main net rewards
            if(keccak256(abi.encodePacked(_settingPath)) == keccak256(abi.encodePacked("rewards.network.enabled", uint256(0)))) {
                revert("Cannot disable network 0");
            }
        }
        // Update setting now
        setBool(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }


    // Getters

    function getNetworkEnabled(uint256 _network) override external view returns (bool) {
        return getBool(keccak256(abi.encodePacked(settingNameSpace, "rewards.network.enabled", _network)));
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../../RocketBase.sol";
import "../../../interface/dao/protocol/RocketDAOProtocolInterface.sol";
import "../../../interface/dao/protocol/RocketDAOProtocolProposalsInterface.sol";
import "../../../types/SettingType.sol";


// The Rocket Pool Network DAO - This is a placeholder for the network DAO to come
contract RocketDAOProtocol is RocketBase, RocketDAOProtocolInterface {

    // The namespace for any data stored in the network DAO (do not change)
    string constant daoNameSpace = "dao.protocol.";

    // Only allow bootstrapping when enabled
    modifier onlyBootstrapMode() {
        require(getBootstrapModeDisabled() == false, "Bootstrap mode not engaged");
        _;
    }

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }


    /**** DAO Properties **************/

    // Returns true if bootstrap mode is disabled
    function getBootstrapModeDisabled() override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked(daoNameSpace, "bootstrapmode.disabled")));
    }


    /**** Bootstrapping ***************/
    // While bootstrap mode is engaged, RP can change settings alongside the DAO (when its implemented). When disabled, only DAO will be able to control settings

    // Bootstrap mode - multi Setting
    function bootstrapSettingMulti(string[] memory _settingContractNames, string[] memory _settingPaths, SettingType[] memory _types, bytes[] memory _values) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAOProtocol", address(this)) {
      // Ok good to go, lets update the settings
      RocketDAOProtocolProposalsInterface(getContractAddress("rocketDAOProtocolProposals")).proposalSettingMulti(_settingContractNames, _settingPaths, _types, _values);
    }

    // Bootstrap mode - Uint Setting
    function bootstrapSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAOProtocol", address(this)) {
        // Ok good to go, lets update the settings
        RocketDAOProtocolProposalsInterface(getContractAddress("rocketDAOProtocolProposals")).proposalSettingUint(_settingContractName, _settingPath, _value);
    }

    // Bootstrap mode - Bool Setting
    function bootstrapSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAOProtocol", address(this)) {
        // Ok good to go, lets update the settings 
        RocketDAOProtocolProposalsInterface(getContractAddress("rocketDAOProtocolProposals")).proposalSettingBool(_settingContractName, _settingPath, _value);
    }

    // Bootstrap mode - Address Setting
    function bootstrapSettingAddress(string memory _settingContractName, string memory _settingPath, address _value) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAOProtocol", address(this)) {
        // Ok good to go, lets update the settings 
        RocketDAOProtocolProposalsInterface(getContractAddress("rocketDAOProtocolProposals")).proposalSettingAddress(_settingContractName, _settingPath, _value);
    }

    // Bootstrap mode - Set a claiming contract to receive a % of RPL inflation rewards
    function bootstrapSettingClaimer(string memory _contractName, uint256 _perc) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAOProtocol", address(this)) {
        // Ok good to go, lets update the rewards claiming contract amount 
        RocketDAOProtocolProposalsInterface(getContractAddress("rocketDAOProtocolProposals")).proposalSettingRewardsClaimer(_contractName, _perc);
    }

    // Bootstrap mode -Spend DAO treasury
    function bootstrapSpendTreasury(string memory _invoiceID, address _recipientAddress, uint256 _amount) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAOProtocol", address(this)) {
        RocketDAOProtocolProposalsInterface(getContractAddress("rocketDAOProtocolProposals")).proposalSpendTreasury(_invoiceID, _recipientAddress, _amount);
    }

    // Bootstrap mode - Disable RP Access (only RP can call this to hand over full control to the DAO)
    function bootstrapDisable(bool _confirmDisableBootstrapMode) override external onlyGuardian onlyBootstrapMode onlyLatestContract("rocketDAOProtocol", address(this)) {
        require(_confirmDisableBootstrapMode == true, "You must confirm disabling bootstrap mode, it can only be done once!");
        setBool(keccak256(abi.encodePacked(daoNameSpace, "bootstrapmode.disabled")), true);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../RocketBase.sol";
import "../../../interface/RocketVaultInterface.sol";
import "../../../interface/dao/protocol/RocketDAOProtocolActionsInterface.sol";


import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// The Rocket Pool Network DAO Actions - This is a placeholder for the network DAO to come
contract RocketDAOProtocolActions is RocketBase, RocketDAOProtocolActionsInterface { 

    using SafeMath for uint;

    // The namespace for any data stored in the network DAO (do not change)
    string constant daoNameSpace = "dao.protocol.";


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }


    /*** Action Methods ************************/

   
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../../RocketBase.sol";
import "../../../interface/dao/protocol/RocketDAOProtocolInterface.sol";
import "../../../interface/dao/protocol/RocketDAOProtocolProposalsInterface.sol";
import "../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsInterface.sol";
import "../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";
import "../../../interface/rewards/claims/RocketClaimDAOInterface.sol";
import "../../../interface/dao/RocketDAOProposalInterface.sol";
import "../../../types/SettingType.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


// The protocol DAO Proposals - Placeholder contracts until DAO is implemented
contract RocketDAOProtocolProposals is RocketBase, RocketDAOProtocolProposalsInterface {

    using SafeMath for uint;

    // The namespace for any data stored in the trusted node DAO (do not change)
    string constant daoNameSpace = "dao.protocol.";

    // Only allow certain contracts to execute methods
    modifier onlyExecutingContracts() {
        // Methods are either executed by bootstrapping methods in rocketDAONodeTrusted or by people executing passed proposals in rocketDAOProposal
        require(msg.sender == getContractAddress("rocketDAOProtocol") || msg.sender == getContractAddress("rocketDAOProposal"), "Sender is not permitted to access executing methods");
        _;
    }

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }


    /*** Proposals **********************/

    // Set multiple settings in one proposal
    function proposalSettingMulti(string[] memory _settingContractNames, string[] memory _settingPaths, SettingType[] memory _types, bytes[] memory _data) override external onlyExecutingContracts() {
      // Check lengths of all arguments are the same
      require(_settingContractNames.length == _settingPaths.length && _settingPaths.length == _types.length && _types.length == _data.length, "Invalid parameters supplied");
      // Loop through settings
      for (uint256 i = 0; i < _settingContractNames.length; i++) {
        if (_types[i] == SettingType.UINT256) {
          uint256 value = abi.decode(_data[i], (uint256));
          proposalSettingUint(_settingContractNames[i], _settingPaths[i], value);
        } else if (_types[i] == SettingType.BOOL) {
          bool value = abi.decode(_data[i], (bool));
          proposalSettingBool(_settingContractNames[i], _settingPaths[i], value);
        } else if (_types[i] == SettingType.ADDRESS) {
          address value = abi.decode(_data[i], (address));
          proposalSettingAddress(_settingContractNames[i], _settingPaths[i], value);
        } else {
          revert("Invalid setting type");
        }
      }
    }

    // Change one of the current uint256 settings of the protocol DAO
    function proposalSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) override public onlyExecutingContracts() {
        // Load contracts
        RocketDAOProtocolSettingsInterface rocketDAOProtocolSettings = RocketDAOProtocolSettingsInterface(getContractAddress(_settingContractName));
        // Lets update
        rocketDAOProtocolSettings.setSettingUint(_settingPath, _value);
    }

    // Change one of the current bool settings of the protocol DAO
    function proposalSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) override public onlyExecutingContracts() {
        // Load contracts
        RocketDAOProtocolSettingsInterface rocketDAOProtocolSettings = RocketDAOProtocolSettingsInterface(getContractAddress(_settingContractName));
        // Lets update
        rocketDAOProtocolSettings.setSettingBool(_settingPath, _value);
    }

    // Change one of the current address settings of the protocol DAO
    function proposalSettingAddress(string memory _settingContractName, string memory _settingPath, address _value) override public onlyExecutingContracts() {
        // Load contracts
        RocketDAOProtocolSettingsInterface rocketDAOProtocolSettings = RocketDAOProtocolSettingsInterface(getContractAddress(_settingContractName));
        // Lets update
        rocketDAOProtocolSettings.setSettingAddress(_settingPath, _value);
    }

    // Update a claimer for the rpl rewards, must specify a unique contract name that will be claiming from and a percentage of the rewards
    function proposalSettingRewardsClaimer(string memory _contractName, uint256 _perc) override external onlyExecutingContracts() {
        // Load contracts
        RocketDAOProtocolSettingsRewardsInterface rocketDAOProtocolSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        // Update now
        rocketDAOProtocolSettingsRewards.setSettingRewardsClaimer(_contractName, _perc);
    }

    // Spend RPL from the DAO's treasury
    function proposalSpendTreasury(string memory _invoiceID, address _recipientAddress, uint256 _amount) override external onlyExecutingContracts() {
        // Load contracts
        RocketClaimDAOInterface rocketDAOTreasury = RocketClaimDAOInterface(getContractAddress("rocketClaimDAO"));
        // Update now
        rocketDAOTreasury.spend(_invoiceID, _recipientAddress, _amount);
    }


}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../../RocketBase.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsInterface.sol";

// Settings in RP which the DAO will have full control over
// This settings contract enables storage using setting paths with namespaces, rather than explicit set methods
abstract contract RocketDAOProtocolSettings is RocketBase, RocketDAOProtocolSettingsInterface {


    // The namespace for a particular group of settings
    bytes32 settingNameSpace;


    // Only allow updating from the DAO proposals contract
    modifier onlyDAOProtocolProposal() {
        // If this contract has been initialised, only allow access from the proposals contract
        if(getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) require(getContractAddress("rocketDAOProtocolProposals") == msg.sender, "Only DAO Protocol Proposals contract can update a setting");
        _;
    }


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress, string memory _settingNameSpace) RocketBase(_rocketStorageAddress) {
        // Apply the setting namespace
        settingNameSpace = keccak256(abi.encodePacked("dao.protocol.setting.", _settingNameSpace));
    }


    /*** Uints  ****************/

    // A general method to return any setting given the setting path is correct, only accepts uints
    function getSettingUint(string memory _settingPath) public view override returns (uint256) {
        return getUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)));
    } 

    // Update a Uint setting, can only be executed by the DAO contract when a majority on a setting proposal has passed and been executed
    function setSettingUint(string memory _settingPath, uint256 _value) virtual public override onlyDAOProtocolProposal {
        // Update setting now
        setUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    } 
   

    /*** Bools  ****************/

    // A general method to return any setting given the setting path is correct, only accepts bools
    function getSettingBool(string memory _settingPath) public view override returns (bool) {
        return getBool(keccak256(abi.encodePacked(settingNameSpace, _settingPath)));
    } 

    // Update a setting, can only be executed by the DAO contract when a majority on a setting proposal has passed and been executed
    function setSettingBool(string memory _settingPath, bool _value) virtual public override onlyDAOProtocolProposal {
        // Update setting now
        setBool(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }

    
    /*** Addresses  ****************/

    // A general method to return any setting given the setting path is correct, only accepts addresses
    function getSettingAddress(string memory _settingPath) external view override returns (address) {
        return getAddress(keccak256(abi.encodePacked(settingNameSpace, _settingPath)));
    } 

    // Update a setting, can only be executed by the DAO contract when a majority on a setting proposal has passed and been executed
    function setSettingAddress(string memory _settingPath, address _value) virtual external override onlyDAOProtocolProposal {
        // Update setting now
        setAddress(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAOProtocolSettings.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsAuctionInterface.sol";

// Network auction settings

contract RocketDAOProtocolSettingsAuction is RocketDAOProtocolSettings, RocketDAOProtocolSettingsAuctionInterface {

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "auction") {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Apply settings
            setSettingBool("auction.lot.create.enabled", true);      
            setSettingBool("auction.lot.bidding.enabled", true);
            setSettingUint("auction.lot.value.minimum", 1 ether);   
            setSettingUint("auction.lot.value.maximum", 10 ether);
            setSettingUint("auction.lot.duration", 40320);          // 7 days
            setSettingUint("auction.price.start", 1 ether);         // 100%
            setSettingUint("auction.price.reserve", 0.5 ether);     // 50%
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }


    // Lot creation currently enabled
    function getCreateLotEnabled() override external view returns (bool) {
        return getSettingBool("auction.lot.create.enabled");
    }

    // Bidding on lots currently enabled
    function getBidOnLotEnabled() override external view returns (bool) {
        return getSettingBool("auction.lot.bidding.enabled");
    }

    // The minimum lot size relative to ETH value
    function getLotMinimumEthValue() override external view returns (uint256) {
        return getSettingUint("auction.lot.value.minimum");
    }

    // The maximum lot size relative to ETH value
    function getLotMaximumEthValue() override external view returns (uint256) {
        return getSettingUint("auction.lot.value.maximum");
    }

    // The maximum auction duration in blocks
    function getLotDuration() override external view returns (uint256) {
        return getSettingUint("auction.lot.duration");
    }

    // The starting price relative to current RPL price, as a fraction of 1 ether
    function getStartingPriceRatio() override external view returns (uint256) {
        return getSettingUint("auction.price.start");
    }

    // The reserve price relative to current RPL price, as a fraction of 1 ether
    function getReservePriceRatio() override external view returns (uint256) {
        return getSettingUint("auction.price.reserve");
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "./RocketDAOProtocolSettings.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsDepositInterface.sol";
 
/// @notice Network deposit settings
contract RocketDAOProtocolSettingsDeposit is RocketDAOProtocolSettings, RocketDAOProtocolSettingsDepositInterface {

    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "deposit") {
        // Set version
        version = 3;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Apply settings
            setSettingBool("deposit.enabled", false);
            setSettingBool("deposit.assign.enabled", true);
            setSettingUint("deposit.minimum", 0.01 ether);
            setSettingUint("deposit.pool.maximum", 160 ether);
            setSettingUint("deposit.assign.maximum", 90);
            setSettingUint("deposit.assign.socialised.maximum", 2);
            setSettingUint("deposit.fee", 0.0005 ether);    // Set to approx. 1 day of rewards at 18.25% APR
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

    /// @notice Returns true if deposits are currently enabled
    function getDepositEnabled() override external view returns (bool) {
        return getSettingBool("deposit.enabled");
    }

    /// @notice Returns true if deposit assignments are currently enabled
    function getAssignDepositsEnabled() override external view returns (bool) {
        return getSettingBool("deposit.assign.enabled");
    }

    /// @notice Returns the minimum deposit size
    function getMinimumDeposit() override external view returns (uint256) {
        return getSettingUint("deposit.minimum");
    }

    /// @notice Returns the maximum size of the deposit pool
    function getMaximumDepositPoolSize() override external view returns (uint256) {
        return getSettingUint("deposit.pool.maximum");
    }

    /// @notice Returns the maximum number of deposit assignments to perform at once
    function getMaximumDepositAssignments() override external view returns (uint256) {
        return getSettingUint("deposit.assign.maximum");
    }

    /// @notice Returns the maximum number of socialised (ie, not related to deposit size) assignments to perform
    function getMaximumDepositSocialisedAssignments() override external view returns (uint256) {
        return getSettingUint("deposit.assign.socialised.maximum");
    }

    /// @notice Returns the current fee paid on user deposits
    function getDepositFee() override external view returns (uint256) {
        return getSettingUint("deposit.fee");
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAOProtocolSettings.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsInflationInterface.sol";
import "../../../../interface/token/RocketTokenRPLInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

// RPL Inflation settings in RP which the DAO will have full control over
contract RocketDAOProtocolSettingsInflation is RocketDAOProtocolSettings, RocketDAOProtocolSettingsInflationInterface {

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "inflation") {
        // Set version 
        version = 1;
         // Set some initial settings on first deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // RPL Inflation settings
            setSettingUint("rpl.inflation.interval.rate", 1000133680617113500);                                 // 5% annual calculated on a daily interval - Calculate in js example: let dailyInflation = web3.utils.toBN((1 + 0.05) ** (1 / (365)) * 1e18);
            setSettingUint("rpl.inflation.interval.start", block.timestamp + 1 days);                           // Set the default start date for inflation to begin as 1 day after deployment
            // Deployment check
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);                           // Flag that this contract has been deployed, so default settings don't get reapplied on a contract upgrade
        }
    }
    
    

    /*** Set Uint *****************************************/

    // Update a setting, overrides inherited setting method with extra checks for this contract
    function setSettingUint(string memory _settingPath, uint256 _value) override public onlyDAOProtocolProposal {
        // Some safety guards for certain settings
        // The start time for inflation must be in the future and cannot be set again once started
        bytes32 settingKey = keccak256(bytes(_settingPath));
        if(settingKey == keccak256(bytes("rpl.inflation.interval.start"))) {
            // Must be a future timestamp
            require(_value > block.timestamp, "Inflation interval start time must be in the future");
            // If it's already set and started, a new start block cannot be set
            if(getInflationIntervalStartTime() > 0) {
                require(getInflationIntervalStartTime() > block.timestamp, "Inflation has already started");
            }
        } else if(settingKey == keccak256(bytes("rpl.inflation.interval.rate"))) {
            // RPL contract address
            address rplContractAddress = getContractAddressUnsafe("rocketTokenRPL");
            if(rplContractAddress != address(0x0)) {
                // Force inflation at old rate before updating inflation rate
                RocketTokenRPLInterface rplContract = RocketTokenRPLInterface(rplContractAddress);
                // Mint any new tokens from the RPL inflation
                rplContract.inflationMintTokens();
            }
        }
        // Update setting now
        setUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }

    /*** RPL Contract Settings *****************************************/

    // RPL yearly inflation rate per interval (daily by default)
    function getInflationIntervalRate() override external view returns (uint256) {
        return getSettingUint("rpl.inflation.interval.rate");
    }
    
    // The block to start inflation at
    function getInflationIntervalStartTime() override public view returns (uint256) {
        return getSettingUint("rpl.inflation.interval.start"); 
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./RocketDAOProtocolSettings.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMinipoolInterface.sol";
import "../../../../types/MinipoolDeposit.sol";

/// @notice Network minipool settings
contract RocketDAOProtocolSettingsMinipool is RocketDAOProtocolSettings, RocketDAOProtocolSettingsMinipoolInterface {

    // Libs
    using SafeMath for uint;

    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "minipool") {
        // Set version
        version = 2;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Apply settings
            setSettingBool("minipool.submit.withdrawable.enabled", false);
            setSettingBool("minipool.bond.reduction.enabled", false);
            setSettingUint("minipool.launch.timeout", 72 hours);
            setSettingUint("minipool.maximum.count", 14);
            setSettingUint("minipool.user.distribute.window.start", 14 days);
            setSettingUint("minipool.user.distribute.window.length", 2 days);
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

    /// @notice Update a setting, overrides inherited setting method with extra checks for this contract
    /// @param _settingPath The path of the setting within this contract's namespace
    /// @param _value The value to set it to
    function setSettingUint(string memory _settingPath, uint256 _value) override public onlyDAOProtocolProposal {
        // Some safety guards for certain settings
        if(getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            if(keccak256(abi.encodePacked(_settingPath)) == keccak256(abi.encodePacked("minipool.launch.timeout"))) {
                RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
                require(_value >= (rocketDAONodeTrustedSettingsMinipool.getScrubPeriod().add(1 hours)), "Launch timeout must be greater than scrub period");
            }
        }
        // Update setting now
        setUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }

    /// @notice Returns the balance required to launch minipool
    function getLaunchBalance() override public pure returns (uint256) {
        return 32 ether;
    }

    /// @notice Returns the value required to pre-launch a minipool
    function getPreLaunchValue() override public pure returns (uint256) {
        return 1 ether;
    }

    /// @notice Returns the deposit amount for a given deposit type (only used for legacy minipool types)
    function getDepositUserAmount(MinipoolDeposit _depositType) override external pure returns (uint256) {
        if (_depositType == MinipoolDeposit.Full) { return getFullDepositUserAmount(); }
        if (_depositType == MinipoolDeposit.Half) { return getHalfDepositUserAmount(); }
        return 0;
    }

    /// @notice Returns the user amount for a "Full" deposit minipool
    function getFullDepositUserAmount() override public pure returns (uint256) {
        return getLaunchBalance().div(2);
    }

    /// @notice Returns the user amount for a "Half" deposit minipool
    function getHalfDepositUserAmount() override public pure returns (uint256) {
        return getLaunchBalance().div(2);
    }

    /// @notice Returns the amount a "Variable" minipool requires to move to staking status
    function getVariableDepositAmount() override public pure returns (uint256) {
        return getLaunchBalance().sub(getPreLaunchValue());
    }

    /// @notice Submit minipool withdrawable events currently enabled (trusted nodes only)
    function getSubmitWithdrawableEnabled() override external view returns (bool) {
        return getSettingBool("minipool.submit.withdrawable.enabled");
    }

    /// @notice Returns true if bond reductions are currentl enabled
    function getBondReductionEnabled() override external view returns (bool) {
        return getSettingBool("minipool.bond.reduction.enabled");
    }

    /// @notice Returns the timeout period in seconds for prelaunch minipools to launch
    function getLaunchTimeout() override external view returns (uint256) {
        return getSettingUint("minipool.launch.timeout");
    }

    /// @notice Returns the maximum number of minipools allowed at one time
    function getMaximumCount() override external view returns (uint256) {
      return getSettingUint("minipool.maximum.count");
    }

    /// @notice Returns true if the given time is within the user distribute window
    function isWithinUserDistributeWindow(uint256 _time) override external view returns (bool) {
        uint256 start = getUserDistributeWindowStart();
        uint256 length = getUserDistributeWindowLength();
        return (_time >= start && _time < (start.add(length)));
    }

    /// @notice Returns true if the given time has passed the distribute window
    function hasUserDistributeWindowPassed(uint256 _time) override external view returns (bool) {
        uint256 start = getUserDistributeWindowStart();
        uint256 length = getUserDistributeWindowLength();
        return _time >= start.add(length);
    }

    /// @notice Returns the start of the user distribute window
    function getUserDistributeWindowStart() override public view returns (uint256) {
        return getSettingUint("minipool.user.distribute.window.start");
    }

    /// @notice Returns the length of the user distribute window
    function getUserDistributeWindowLength() override public view returns (uint256) {
        return getSettingUint("minipool.user.distribute.window.length");
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAOProtocolSettings.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";

// Network auction settings

contract RocketDAOProtocolSettingsNetwork is RocketDAOProtocolSettings, RocketDAOProtocolSettingsNetworkInterface {
    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "network") {
        // Set version
        version = 2;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Apply settings
            setSettingUint("network.consensus.threshold", 0.51 ether);      // 51%
            setSettingBool("network.submit.balances.enabled", true);
            setSettingUint("network.submit.balances.frequency", 5760);      // ~24 hours
            setSettingBool("network.submit.prices.enabled", true);
            setSettingUint("network.submit.prices.frequency", 5760);        // ~24 hours
            setSettingUint("network.node.fee.minimum", 0.15 ether);         // 15%
            setSettingUint("network.node.fee.target", 0.15 ether);          // 15%
            setSettingUint("network.node.fee.maximum", 0.15 ether);         // 15%
            setSettingUint("network.node.fee.demand.range", 160 ether);
            setSettingUint("network.reth.collateral.target", 0.1 ether);
            setSettingUint("network.penalty.threshold", 0.51 ether);       // Consensus for penalties requires 51% vote
            setSettingUint("network.penalty.per.rate", 0.1 ether);         // 10% per penalty
            setSettingBool("network.submit.rewards.enabled", true);        // Enable reward submission
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

    // Update a setting, overrides inherited setting method with extra checks for this contract
    function setSettingUint(string memory _settingPath, uint256 _value) override public onlyDAOProtocolProposal {
        // Some safety guards for certain settings
        // Prevent DAO from setting the withdraw delay greater than ~24 hours
        if(keccak256(bytes(_settingPath)) == keccak256(bytes("network.reth.deposit.delay"))) {
            // Must be a future timestamp
            require(_value <= 5760, "rETH deposit delay cannot exceed 5760 blocks");
        }
        // Update setting now
        setUint(keccak256(abi.encodePacked(settingNameSpace, _settingPath)), _value);
    }

    // The threshold of trusted nodes that must reach consensus on oracle data to commit it
    function getNodeConsensusThreshold() override external view returns (uint256) {
        return getSettingUint("network.consensus.threshold");
    }

    // The threshold of trusted nodes that must reach consensus on a penalty
    function getNodePenaltyThreshold() override external view returns (uint256) {
        return getSettingUint("network.penalty.threshold");
    }

    // The amount to penalise a minipool for each feeDistributor infraction
    function getPerPenaltyRate() override external view returns (uint256) {
        return getSettingUint("network.penalty.per.rate");
    }

// Submit balances currently enabled (trusted nodes only)
    function getSubmitBalancesEnabled() override external view returns (bool) {
        return getSettingBool("network.submit.balances.enabled");
    }

    // The frequency in blocks at which network balances should be submitted by trusted nodes
    function getSubmitBalancesFrequency() override external view returns (uint256) {
        return getSettingUint("network.submit.balances.frequency");
    }

    // Submit prices currently enabled (trusted nodes only)
    function getSubmitPricesEnabled() override external view returns (bool) {
        return getSettingBool("network.submit.prices.enabled");
    }

    // The frequency in blocks at which network prices should be submitted by trusted nodes
    function getSubmitPricesFrequency() override external view returns (uint256) {
        return getSettingUint("network.submit.prices.frequency");
    }

    // The minimum node commission rate as a fraction of 1 ether
    function getMinimumNodeFee() override external view returns (uint256) {
        return getSettingUint("network.node.fee.minimum");
    }

    // The target node commission rate as a fraction of 1 ether
    function getTargetNodeFee() override external view returns (uint256) {
        return getSettingUint("network.node.fee.target");
    }

    // The maximum node commission rate as a fraction of 1 ether
    function getMaximumNodeFee() override external view returns (uint256) {
        return getSettingUint("network.node.fee.maximum");
    }

    // The range of node demand values to base fee calculations on (from negative to positive value)
    function getNodeFeeDemandRange() override external view returns (uint256) {
        return getSettingUint("network.node.fee.demand.range");
    }

    // Target rETH collateralization rate as a fraction of 1 ether
    function getTargetRethCollateralRate() override external view returns (uint256) {
        return getSettingUint("network.reth.collateral.target");
    }

    // rETH withdraw delay in blocks
    function getRethDepositDelay() override external view returns (uint256) {
        return getSettingUint("network.reth.deposit.delay");
    }

    // Submit reward snapshots currently enabled (trusted nodes only)
    function getSubmitRewardsEnabled() override external view returns (bool) {
        return getSettingBool("network.submit.rewards.enabled");
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAOProtocolSettings.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";

// Network auction settings

contract RocketDAOProtocolSettingsNode is RocketDAOProtocolSettings, RocketDAOProtocolSettingsNodeInterface {

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "node") {
        // Set version
        version = 3;
        // Initialize settings on deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Apply settings
            setSettingBool("node.registration.enabled", false);
            setSettingBool("node.smoothing.pool.registration.enabled", true);
            setSettingBool("node.deposit.enabled", false);
            setSettingBool("node.vacant.minipools.enabled", false);
            setSettingUint("node.per.minipool.stake.minimum", 0.1 ether);      // 10% of user ETH value (matched ETH)
            setSettingUint("node.per.minipool.stake.maximum", 1.5 ether);      // 150% of node ETH value (provided ETH)
            // Settings initialised
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);
        }
    }

    // Node registrations currently enabled
    function getRegistrationEnabled() override external view returns (bool) {
        return getSettingBool("node.registration.enabled");
    }

    // Node smoothing pool registrations currently enabled
    function getSmoothingPoolRegistrationEnabled() override external view returns (bool) {
        return getSettingBool("node.smoothing.pool.registration.enabled");
    }

    // Node deposits currently enabled
    function getDepositEnabled() override external view returns (bool) {
        return getSettingBool("node.deposit.enabled");
    }

    // Vacant minipools currently enabled
    function getVacantMinipoolsEnabled() override external view returns (bool) {
        return getSettingBool("node.vacant.minipools.enabled");
    }

    // Minimum RPL stake per minipool as a fraction of assigned user ETH value
    function getMinimumPerMinipoolStake() override external view returns (uint256) {
        return getSettingUint("node.per.minipool.stake.minimum");
    }

    // Maximum RPL stake per minipool as a fraction of assigned user ETH value
    function getMaximumPerMinipoolStake() override external view returns (uint256) {
        return getSettingUint("node.per.minipool.stake.maximum");
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketDAOProtocolSettings.sol";
import "../../../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

// Settings in RP which the DAO will have full control over
contract RocketDAOProtocolSettingsRewards is RocketDAOProtocolSettings, RocketDAOProtocolSettingsRewardsInterface {

    using SafeMath for uint;

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketDAOProtocolSettings(_rocketStorageAddress, "rewards") {
        // Set version 
        version = 1;
         // Set some initial settings on first deployment
        if(!getBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")))) {
            // Each of the initial RPL reward claiming contracts
            setSettingRewardsClaimer('rocketClaimDAO', 0.1 ether);                                              // DAO Rewards claim % amount - Percentage given of 1 ether
            setSettingRewardsClaimer('rocketClaimNode', 0.70 ether);                                            // Bonded Node Rewards claim % amount - Percentage given of 1 ether
            setSettingRewardsClaimer('rocketClaimTrustedNode', 0.2 ether);                                      // Trusted Node Rewards claim % amount - Percentage given of 1 ether
            // RPL Claims settings
            setSettingUint("rpl.rewards.claim.period.time", 28 days);                                           // The time in which a claim period will span in seconds - 28 days by default
            // Deployment check
            setBool(keccak256(abi.encodePacked(settingNameSpace, "deployed")), true);                           // Flag that this contract has been deployed, so default settings don't get reapplied on a contract upgrade
        }
    }


    /*** Settings ****************/

    // Set a new claimer for the rpl rewards, must specify a unique contract name that will be claiming from and a percentage of the rewards
    function setSettingRewardsClaimer(string memory _contractName, uint256 _perc) override public onlyDAOProtocolProposal {
        // Get the total perc set, can't be more than 100
        uint256 percTotal = getRewardsClaimersPercTotal();
        // If this group already exists, it will update the perc
        uint256 percTotalUpdate = percTotal.add(_perc).sub(getRewardsClaimerPerc(_contractName));
        // Can't be more than a total claim amount of 100%
        require(percTotalUpdate <= 1 ether, "Claimers cannot total more than 100%");
        // Update the total
        setUint(keccak256(abi.encodePacked(settingNameSpace,"rewards.claims", "group.totalPerc")), percTotalUpdate);
        // Update/Add the claimer amount
        setUint(keccak256(abi.encodePacked(settingNameSpace, "rewards.claims", "group.amount", _contractName)), _perc);
        // Set the time it was updated at
        setUint(keccak256(abi.encodePacked(settingNameSpace, "rewards.claims", "group.amount.updated.time", _contractName)), block.timestamp);
    }



    /*** RPL Claims ***********************************************/


    // RPL Rewards Claimers (own namespace to prevent DAO setting voting to overwrite them)

    // Get the perc amount that this rewards contract get claim
    function getRewardsClaimerPerc(string memory _contractName) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(settingNameSpace, "rewards.claims", "group.amount", _contractName)));
    } 

    // Get the time of when the claim perc was last updated
    function getRewardsClaimerPercTimeUpdated(string memory _contractName) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(settingNameSpace, "rewards.claims", "group.amount.updated.time", _contractName)));
    } 

    // Get the perc amount total for all claimers (remaining goes to DAO)
    function getRewardsClaimersPercTotal() override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(settingNameSpace, "rewards.claims", "group.totalPerc")));
    }


    // RPL Rewards General Settings

    // The period over which claims can be made
    function getRewardsClaimIntervalTime() override external view returns (uint256) {
        return getSettingUint("rpl.rewards.claim.period.time");
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/dao/RocketDAOProposalInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";


// A DAO proposal
contract RocketDAOProposal is RocketBase, RocketDAOProposalInterface {

    using SafeMath for uint;

    // Events
    event ProposalAdded(address indexed proposer, string indexed proposalDAO, uint256 indexed proposalID, bytes payload, uint256 time);  
    event ProposalVoted(uint256 indexed proposalID, address indexed voter, bool indexed supported, uint256 time);  
    event ProposalExecuted(uint256 indexed proposalID, address indexed executer, uint256 time);
    event ProposalCancelled(uint256 indexed proposalID, address indexed canceller, uint256 time);    

    // The namespace for any data stored in the trusted node DAO (do not change)
    string constant private daoProposalNameSpace = "dao.proposal.";

    
    // Only allow the DAO contract to access
    modifier onlyDAOContract(string memory _daoName) {
        // Load contracts
        require(keccak256(abi.encodePacked(getContractName(msg.sender))) == keccak256(abi.encodePacked(_daoName)), "Sender is not the required DAO contract");
        _;
    }


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }


    /*** Proposals ****************/
  
    // Get the current total proposals
    function getTotal() override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "total"))); 
    }

    // Get the DAO that this proposal belongs too
    function getDAO(uint256 _proposalID) override public view returns (string memory) {
        return getString(keccak256(abi.encodePacked(daoProposalNameSpace, "dao", _proposalID))); 
    }

    // Get the member who proposed
    function getProposer(uint256 _proposalID) override public view returns (address) {
        return getAddress(keccak256(abi.encodePacked(daoProposalNameSpace, "proposer", _proposalID))); 
    }

    // Get the proposal message
    function getMessage(uint256 _proposalID) override external view returns (string memory) {
        return getString(keccak256(abi.encodePacked(daoProposalNameSpace, "message", _proposalID))); 
    }

    // Get the start block of this proposal
    function getStart(uint256 _proposalID) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "start", _proposalID))); 
    } 

    // Get the end block of this proposal
    function getEnd(uint256 _proposalID) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "end", _proposalID))); 
    }

    // The block where the proposal expires and can no longer be executed if it is successful
    function getExpires(uint256 _proposalID) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "expires", _proposalID))); 
    }

    // Get the created status of this proposal
    function getCreated(uint256 _proposalID) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "created", _proposalID))); 
    }

    // Get the votes for count of this proposal
    function getVotesFor(uint256 _proposalID) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.for", _proposalID))); 
    }

    // Get the votes against count of this proposal
    function getVotesAgainst(uint256 _proposalID) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.against", _proposalID))); 
    }

    // How many votes required for the proposal to succeed 
    function getVotesRequired(uint256 _proposalID) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.required", _proposalID))); 
    }

    // Get the cancelled status of this proposal
    function getCancelled(uint256 _proposalID) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked(daoProposalNameSpace, "cancelled", _proposalID))); 
    }

    // Get the executed status of this proposal
    function getExecuted(uint256 _proposalID) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked(daoProposalNameSpace, "executed", _proposalID))); 
    }

    // Get the votes against count of this proposal
    function getPayload(uint256 _proposalID) override public view returns (bytes memory) {
        return getBytes(keccak256(abi.encodePacked(daoProposalNameSpace, "payload", _proposalID))); 
    }

    // Returns true if this proposal has already been voted on by a member
    function getReceiptHasVoted(uint256 _proposalID, address _nodeAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked(daoProposalNameSpace, "receipt.hasVoted", _proposalID, _nodeAddress))); 
    }

    // Returns true if this proposal was supported by this member
    function getReceiptSupported(uint256 _proposalID, address _nodeAddress) override external view returns (bool) {
        return getBool(keccak256(abi.encodePacked(daoProposalNameSpace, "receipt.supported", _proposalID, _nodeAddress))); 
    }
    

    // Return the state of the specified proposal
    // A successful proposal can be executed immediately
    function getState(uint256 _proposalID) override public view returns (ProposalState) {
        // Check the proposal ID is legit
        require(getTotal() >= _proposalID && _proposalID > 0, "Invalid proposal ID");
        // Get the amount of votes for and against
        uint256 votesFor = getVotesFor(_proposalID);
        uint256 votesAgainst = getVotesAgainst(_proposalID);
        // Now return the state of the current proposal
        if (getCancelled(_proposalID)) {
            // Cancelled by the proposer?
            return ProposalState.Cancelled;
            // Has it been executed?
        } else if (getExecuted(_proposalID)) {
            return ProposalState.Executed;
            // Is the proposal pending? Eg. waiting to be voted on
        } else if (block.timestamp < getStart(_proposalID)) {
            return ProposalState.Pending;
            // Vote was successful, is now awaiting execution
        } else if (votesFor >= getVotesRequired(_proposalID) && block.timestamp < getExpires(_proposalID)) {
            return ProposalState.Succeeded;
            // The proposal is active and can be voted on
        } else if (block.timestamp < getEnd(_proposalID)) {
            return ProposalState.Active;
            // Check the votes, was it defeated?
        } else if (votesFor <= votesAgainst || votesFor < getVotesRequired(_proposalID)) {
            return ProposalState.Defeated;
        } else {
            // Was it successful, but has now expired? and cannot be executed anymore?
            return ProposalState.Expired;
        }
    }


    // Add a proposal to the an RP DAO, immeditately becomes active
    // Calldata is passed as the payload to execute upon passing the proposal
    function add(address _member, string memory _dao, string memory _message, uint256 _startTime, uint256 _duration, uint256 _expires, uint256 _votesRequired, bytes memory _payload) override external onlyDAOContract(_dao) returns (uint256) {
        // Basic checks
        require(_startTime > block.timestamp, "Proposal start time must be in the future");
        require(_duration > 0, "Proposal cannot have a duration of 0");
        require(_expires > 0, "Proposal cannot have a execution expiration of 0");
        require(_votesRequired > 0, "Proposal cannot have a 0 votes required to be successful");
        // Set the end block
        uint256 endTime = _startTime.add(_duration);
        // Set the expires block
        uint256 expires = endTime.add(_expires);
        // Get the proposal ID
        uint256 proposalID = getTotal().add(1);
        // The data structure for a proposal
        setAddress(keccak256(abi.encodePacked(daoProposalNameSpace, "proposer", proposalID)), _member);                     // Which member is making the proposal
        setString(keccak256(abi.encodePacked(daoProposalNameSpace, "dao", proposalID)), _dao);                              // The DAO the proposal relates too
        setString(keccak256(abi.encodePacked(daoProposalNameSpace, "message", proposalID)), _message);                      // A general message that can be included with the proposal
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "start", proposalID)), _startTime);                        // The time the proposal becomes active for voting on
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "end", proposalID)), endTime);                             // The time the proposal where voting ends
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "expires", proposalID)), expires);                         // The time when the proposal expires and can no longer be executed if it is successful
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "created", proposalID)), block.timestamp);                 // The time the proposal was created at
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.for", proposalID)), 0);                             // Votes for this proposal
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.against", proposalID)), 0);                         // Votes against this proposal
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.required", proposalID)), _votesRequired);           // How many votes are required for the proposal to pass
        setBool(keccak256(abi.encodePacked(daoProposalNameSpace, "cancelled", proposalID)), false);                         // The proposer can cancel this proposal, but only before it passes
        setBool(keccak256(abi.encodePacked(daoProposalNameSpace, "executed", proposalID)), false);                          // Has this proposals calldata been executed?
        setBytes(keccak256(abi.encodePacked(daoProposalNameSpace, "payload", proposalID)), _payload);                       // A calldata payload to execute after it is successful
        // Update the total proposals
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "total")), proposalID);
        // Log it
        emit ProposalAdded(_member, _dao, proposalID, _payload, block.timestamp);
        // Done
        return proposalID;
    }


    // Voting for or against a proposal
    function vote(address _member, uint256 _votes, uint256 _proposalID, bool _support) override external onlyDAOContract(getDAO(_proposalID)) {
        // Successful proposals can be executed immediately, add this as a check for people who are still trying to vote after it has passed
        require(getState(_proposalID) != ProposalState.Succeeded, "Proposal has passed, voting is complete and the proposal can now be executed");
        // Check the proposal is in a state that can be voted on
        require(getState(_proposalID) == ProposalState.Active, "Voting is not active for this proposal");
        // Has this member already voted on this proposal?
        require(!getReceiptHasVoted(_proposalID, _member), "Member has already voted on proposal");
        // Add votes to proposal
        if(_support) {
            addUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.for", _proposalID)), _votes);
        }else{
            addUint(keccak256(abi.encodePacked(daoProposalNameSpace, "votes.against", _proposalID)), _votes);
        }
        // Record the vote receipt now
        setUint(keccak256(abi.encodePacked(daoProposalNameSpace, "receipt.votes", _proposalID, _member)), _votes);
        setBool(keccak256(abi.encodePacked(daoProposalNameSpace, "receipt.hasVoted", _proposalID, _member)), true);
        setBool(keccak256(abi.encodePacked(daoProposalNameSpace, "receipt.supported", _proposalID, _member)), _support);
        // Log it
        emit ProposalVoted(_proposalID, _member, _support, block.timestamp);
    }
    

    // Execute a proposal if it has passed
    function execute(uint256 _proposalID) override external {
        // Firstly make sure this proposal has passed
        require(getState(_proposalID) == ProposalState.Succeeded, "Proposal has not succeeded, has expired or has already been executed");
        // Set as executed now before running payload
        setBool(keccak256(abi.encodePacked(daoProposalNameSpace, "executed", _proposalID)), true);
        // Ok all good, lets run the payload on the dao contract that the proposal relates too, it should execute one of the methods on this contract
        (bool success, bytes memory response) = getContractAddress(getDAO(_proposalID)).call(getPayload(_proposalID));
        // Was there an error?
        require(success, getRevertMsg(response));
        // Log it
        emit ProposalExecuted(_proposalID, tx.origin, block.timestamp);
    }

    // Cancel a proposal, can be cancelled by the original proposer only if it hasn't been executed yet
    function cancel(address _member, uint256 _proposalID) override external onlyDAOContract(getDAO(_proposalID)) {
        // Firstly make sure this proposal can be cancelled
        require(getState(_proposalID) == ProposalState.Pending || getState(_proposalID) == ProposalState.Active, "Proposal can only be cancelled if pending or active");
        // Only allow the proposer to cancel
        require(getProposer(_proposalID) == _member, "Proposal can only be cancelled by the proposer");
        // Set as cancelled now
        setBool(keccak256(abi.encodePacked(daoProposalNameSpace, "cancelled", _proposalID)), true);
        // Log it
        emit ProposalCancelled(_proposalID, _member, block.timestamp);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

import "../RocketBase.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/RocketVaultWithdrawerInterface.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsDepositInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";
import "../../interface/token/RocketTokenRETHInterface.sol";
import "../../types/MinipoolDeposit.sol";

/// @notice Accepts user deposits and mints rETH; handles assignment of deposited ETH to minipools
contract RocketDepositPool is RocketBase, RocketDepositPoolInterface, RocketVaultWithdrawerInterface {

    // Libs
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;

    // Immutables
    RocketVaultInterface immutable rocketVault;
    RocketTokenRETHInterface immutable rocketTokenRETH;

    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);
    event DepositRecycled(address indexed from, uint256 amount, uint256 time);
    event DepositAssigned(address indexed minipool, uint256 amount, uint256 time);
    event ExcessWithdrawn(address indexed to, uint256 amount, uint256 time);

    // Structs
    struct MinipoolAssignment {
        address minipoolAddress;
        uint256 etherAssigned;
    }

    // Modifiers
    modifier onlyThisLatestContract() {
        // Compiler can optimise out this keccak at compile time
        require(address(this) == getAddress(keccak256("contract.addressrocketDepositPool")), "Invalid or outdated contract");
        _;
    }

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 3;

        // Pre-retrieve non-upgradable contract addresses to save gas
        rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        rocketTokenRETH = RocketTokenRETHInterface(getContractAddress("rocketTokenRETH"));
    }

    /// @notice Returns the current deposit pool balance
    function getBalance() override public view returns (uint256) {
        return rocketVault.balanceOf("rocketDepositPool");
    }

    /// @notice Returns the amount of ETH contributed to the deposit pool by node operators waiting in the queue
    function getNodeBalance() override public view returns (uint256) {
        return getUint("deposit.pool.node.balance");
    }

    /// @notice Returns the user owned portion of the deposit pool (negative indicates more ETH has been "lent" to the
    ///         deposit pool by node operators in the queue than is available from user deposits)
    function getUserBalance() override public view returns (int256) {
        return getBalance().toInt256().sub(getNodeBalance().toInt256());
    }

    /// @notice Excess deposit pool balance (in excess of minipool queue capacity)
    function getExcessBalance() override public view returns (uint256) {
        // Get minipool queue capacity
        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        uint256 minipoolCapacity = rocketMinipoolQueue.getEffectiveCapacity();
        uint256 balance = getBalance();
        // Calculate and return
        if (minipoolCapacity >= balance) { return 0; }
        else { return balance.sub(minipoolCapacity); }
    }

    /// @dev Callback required to receive ETH withdrawal from the vault
    function receiveVaultWithdrawalETH() override external payable onlyThisLatestContract onlyLatestContract("rocketVault", msg.sender) {}

    /// @notice Deposits ETH into Rocket Pool and mints the corresponding amount of rETH to the caller
    function deposit() override external payable onlyThisLatestContract {
        // Check deposit settings
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        require(rocketDAOProtocolSettingsDeposit.getDepositEnabled(), "Deposits into Rocket Pool are currently disabled");
        require(msg.value >= rocketDAOProtocolSettingsDeposit.getMinimumDeposit(), "The deposited amount is less than the minimum deposit size");
        /*
            Check if deposit exceeds limit based on current deposit size and minipool queue capacity.

            The deposit pool can, at most, accept a deposit that, after assignments, matches ETH to every minipool in
            the queue and leaves the deposit pool with maximumDepositPoolSize ETH.

            capacityNeeded = depositPoolBalance + msg.value
            maxCapacity = maximumDepositPoolSize + queueEffectiveCapacity
            assert(capacityNeeded <= maxCapacity)
        */
        uint256 capacityNeeded = getBalance().add(msg.value);
        uint256 maxDepositPoolSize = rocketDAOProtocolSettingsDeposit.getMaximumDepositPoolSize();
        if (capacityNeeded > maxDepositPoolSize) {
            // Doing a conditional require() instead of a single one optimises for the common
            // case where capacityNeeded fits in the deposit pool without looking at the queue
            if (rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled()) {
                RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
                require(capacityNeeded <= maxDepositPoolSize.add(rocketMinipoolQueue.getEffectiveCapacity()),
                    "The deposit pool size after depositing (and matching with minipools) exceeds the maximum size");
            } else {
                revert("The deposit pool size after depositing exceeds the maximum size");
            }
        }
        // Calculate deposit fee
        uint256 depositFee = msg.value.mul(rocketDAOProtocolSettingsDeposit.getDepositFee()).div(calcBase);
        uint256 depositNet = msg.value.sub(depositFee);
        // Mint rETH to user account
        rocketTokenRETH.mint(depositNet, msg.sender);
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
        // Process deposit
        processDeposit(rocketDAOProtocolSettingsDeposit);
    }

    /// @notice Returns the maximum amount that can be accepted into the deposit pool at this time in wei
    function getMaximumDepositAmount() override external view returns (uint256) {
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        // If deposits are enabled max deposit is 0
        if (!rocketDAOProtocolSettingsDeposit.getDepositEnabled()) {
            return 0;
        }
        uint256 depositPoolBalance = getBalance();
        uint256 maxCapacity = rocketDAOProtocolSettingsDeposit.getMaximumDepositPoolSize();
        // When assignments are enabled, we can accept the max amount plus whatever space is available in the minipool queue
        if (rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled()) {
            RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
            maxCapacity = maxCapacity.add(rocketMinipoolQueue.getEffectiveCapacity());
        }
        // Check we aren't already over
        if (depositPoolBalance >= maxCapacity) {
            return 0;
        }
        return maxCapacity.sub(depositPoolBalance);
    }

    /// @dev Accepts ETH deposit from the node deposit contract (does not mint rETH)
    /// @param _totalAmount The total node deposit amount including any credit balance used
    function nodeDeposit(uint256 _totalAmount) override external payable onlyThisLatestContract onlyLatestContract("rocketNodeDeposit", msg.sender) {
        // Deposit ETH into the vault
        if (msg.value > 0) {
            rocketVault.depositEther{value: msg.value}();
        }
        // Increase recorded node balance
        addUint("deposit.pool.node.balance", _totalAmount);
    }

    /// @dev Withdraws ETH from the deposit pool to RocketNodeDeposit contract to be used for a new minipool
    /// @param _amount The amount of ETH to withdraw
    function nodeCreditWithdrawal(uint256 _amount) override external onlyThisLatestContract onlyLatestContract("rocketNodeDeposit", msg.sender) {
        // Withdraw ETH from the vault
        rocketVault.withdrawEther(_amount);
        // Send it to msg.sender (function modifier verifies msg.sender is RocketNodeDeposit)
        (bool success, ) = address(msg.sender).call{value: _amount}("");
        require(success, "Failed to send ETH");
    }

    /// @dev Recycle a deposit from a dissolved minipool
    function recycleDissolvedDeposit() override external payable onlyThisLatestContract onlyRegisteredMinipool(msg.sender) {
        // Load contracts
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        // Recycle ETH
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        processDeposit(rocketDAOProtocolSettingsDeposit);
    }

    /// @dev Recycle excess ETH from the rETH token contract
    function recycleExcessCollateral() override external payable onlyThisLatestContract onlyLatestContract("rocketTokenRETH", msg.sender) {
        // Load contracts
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        // Recycle ETH
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        processDeposit(rocketDAOProtocolSettingsDeposit);
    }

    /// @dev Recycle a liquidated RPL stake from a slashed minipool
    function recycleLiquidatedStake() override external payable onlyThisLatestContract onlyLatestContract("rocketAuctionManager", msg.sender) {
        // Load contracts
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        // Recycle ETH
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        processDeposit(rocketDAOProtocolSettingsDeposit);
    }

    /// @dev Process a deposit
    function processDeposit(RocketDAOProtocolSettingsDepositInterface _rocketDAOProtocolSettingsDeposit) private {
        // Transfer ETH to vault
        rocketVault.depositEther{value: msg.value}();
        // Assign deposits if enabled
        _assignDeposits(_rocketDAOProtocolSettingsDeposit);
    }

    /// @notice Assign deposits to available minipools. Reverts if assigning deposits is disabled.
    function assignDeposits() override external onlyThisLatestContract {
        // Load contracts
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        // Revert if assigning is disabled
        require(_assignDeposits(rocketDAOProtocolSettingsDeposit), "Deposit assignments are currently disabled");
    }

    /// @dev Assign deposits to available minipools. Does nothing if assigning deposits is disabled.
    function maybeAssignDeposits() override external onlyThisLatestContract returns (bool) {
        // Load contracts
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        // Revert if assigning is disabled
        return _assignDeposits(rocketDAOProtocolSettingsDeposit);
    }

    /// @dev Assigns deposits to available minipools, returns false if assignment is currently disabled
    function _assignDeposits(RocketDAOProtocolSettingsDepositInterface _rocketDAOProtocolSettingsDeposit) private returns (bool) {
        // Check if assigning deposits is enabled
        if (!_rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled()) {
            return false;
        }
        // Load contracts
        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        // Decide which queue processing implementation to use based on queue contents
        if (rocketMinipoolQueue.getContainsLegacy()) {
            return _assignDepositsLegacy(rocketMinipoolQueue, _rocketDAOProtocolSettingsDeposit);
        } else {
            return _assignDepositsNew(rocketMinipoolQueue, _rocketDAOProtocolSettingsDeposit);
        }
    }

    /// @dev Assigns deposits using the new minipool queue
    function _assignDepositsNew(RocketMinipoolQueueInterface _rocketMinipoolQueue, RocketDAOProtocolSettingsDepositInterface _rocketDAOProtocolSettingsDeposit) private returns (bool) {
        // Load contracts
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Calculate the number of minipools to assign
        uint256 maxAssignments = _rocketDAOProtocolSettingsDeposit.getMaximumDepositAssignments();
        uint256 variableDepositAmount = rocketDAOProtocolSettingsMinipool.getVariableDepositAmount();
        uint256 scalingCount = msg.value.div(variableDepositAmount);
        uint256 totalEthCount = getBalance().div(variableDepositAmount);
        uint256 assignments = _rocketDAOProtocolSettingsDeposit.getMaximumDepositSocialisedAssignments().add(scalingCount);
        if (assignments > totalEthCount) {
            assignments = totalEthCount;
        }
        if (assignments > maxAssignments) {
            assignments = maxAssignments;
        }
        address[] memory minipools = _rocketMinipoolQueue.dequeueMinipools(assignments);
        if (minipools.length > 0){
            // Withdraw ETH from vault
            uint256 totalEther = minipools.length.mul(variableDepositAmount);
            rocketVault.withdrawEther(totalEther);
            uint256 nodeBalanceUsed = 0;
            // Loop over minipools and deposit the amount required to reach launch balance
            for (uint256 i = 0; i < minipools.length; i++) {
                RocketMinipoolInterface minipool = RocketMinipoolInterface(minipools[i]);
                // Assign deposit to minipool
                minipool.deposit{value: variableDepositAmount}();
                nodeBalanceUsed = nodeBalanceUsed.add(minipool.getNodeTopUpValue());
                // Emit deposit assigned event
                emit DepositAssigned(minipools[i], variableDepositAmount, block.timestamp);
            }
            // Decrease node balance
            subUint("deposit.pool.node.balance", nodeBalanceUsed);
        }
        return true;
    }

    /// @dev Assigns deposits using the legacy minipool queue
    function _assignDepositsLegacy(RocketMinipoolQueueInterface _rocketMinipoolQueue, RocketDAOProtocolSettingsDepositInterface _rocketDAOProtocolSettingsDeposit) private returns (bool) {
        // Load contracts
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Setup initial variable values
        uint256 balance = getBalance();
        uint256 totalEther = 0;
        // Calculate minipool assignments
        uint256 maxAssignments = _rocketDAOProtocolSettingsDeposit.getMaximumDepositAssignments();
        MinipoolAssignment[] memory assignments = new MinipoolAssignment[](maxAssignments);
        MinipoolDeposit depositType = MinipoolDeposit.None;
        uint256 count = 0;
        uint256 minipoolCapacity = 0;
        for (uint256 i = 0; i < maxAssignments; ++i) {
            // Optimised for multiple of the same deposit type
            if (count == 0) {
                (depositType, count) = _rocketMinipoolQueue.getNextDepositLegacy();
                if (depositType == MinipoolDeposit.None) { break; }
                minipoolCapacity = rocketDAOProtocolSettingsMinipool.getDepositUserAmount(depositType);
            }
            count--;
            if (minipoolCapacity == 0 || balance.sub(totalEther) < minipoolCapacity) { break; }
            // Dequeue the minipool
            address minipoolAddress = _rocketMinipoolQueue.dequeueMinipoolByDepositLegacy(depositType);
            // Update running total
            totalEther = totalEther.add(minipoolCapacity);
            // Add assignment
            assignments[i].etherAssigned = minipoolCapacity;
            assignments[i].minipoolAddress = minipoolAddress;
        }
        if (totalEther > 0) {
            // Withdraw ETH from vault
            rocketVault.withdrawEther(totalEther);
            // Perform assignments
            for (uint256 i = 0; i < maxAssignments; ++i) {
                if (assignments[i].etherAssigned == 0) { break; }
                RocketMinipoolInterface minipool = RocketMinipoolInterface(assignments[i].minipoolAddress);
                // Assign deposit to minipool
                minipool.userDeposit{value: assignments[i].etherAssigned}();
                // Emit deposit assigned event
                emit DepositAssigned(assignments[i].minipoolAddress, assignments[i].etherAssigned, block.timestamp);
            }
        }
        return true;
    }

    /// @dev Withdraw excess deposit pool balance for rETH collateral
    /// @param _amount The amount of excess ETH to withdraw
    function withdrawExcessBalance(uint256 _amount) override external onlyThisLatestContract onlyLatestContract("rocketTokenRETH", msg.sender) {
        // Check amount
        require(_amount <= getExcessBalance(), "Insufficient excess balance for withdrawal");
        // Withdraw ETH from vault
        rocketVault.withdrawEther(_amount);
        // Transfer to rETH contract
        rocketTokenRETH.depositExcess{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/minipool/RocketMinipoolPenaltyInterface.sol";

// THIS CONTRACT IS NOT DEPLOYED TO MAINNET

// Helper contract used in unit tests that can set the penalty rate on a minipool (a feature that will be implemented at a later time)
contract PenaltyTest is RocketBase {
    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
    }

    // Sets the penalty rate for the given minipool
    function setPenaltyRate(address _minipoolAddress, uint256 _rate) external {
        RocketMinipoolPenaltyInterface rocketMinipoolPenalty = RocketMinipoolPenaltyInterface(getContractAddress("rocketMinipoolPenalty"));
        rocketMinipoolPenalty.setPenaltyRate(_minipoolAddress, _rate);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/network/RocketNetworkFeesInterface.sol";
import "../../interface/node/RocketNodeDepositInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsDepositInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMembersInterface.sol";
import "../../types/MinipoolDeposit.sol";
import "../../interface/node/RocketNodeManagerInterface.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";

/// @dev NOT USED IN PRODUCTION - This contract only exists to test future functionality that may or may not be included
/// in a future Rocket Pool release
contract RocketNodeDepositLEB4 is RocketBase, RocketNodeDepositInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 4;
    }

    /// @dev Accept incoming ETH from the deposit pool
    receive() external payable onlyLatestContract("rocketDepositPool", msg.sender) {}

    /// @notice Returns a node operator's credit balance in wei
    function getNodeDepositCredit(address _nodeOperator) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("node.deposit.credit.balance", _nodeOperator)));
    }

    /// @dev Increases a node operators deposit credit balance
    function increaseDepositCreditBalance(address _nodeOperator, uint256 _amount) override external onlyLatestContract("rocketNodeDeposit", address(this)) {
        // Accept calls from network contracts or registered minipools
        require(getBool(keccak256(abi.encodePacked("minipool.exists", msg.sender))) ||
            getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))),
            "Invalid or outdated network contract");
        // Increase credit balance
        addUint(keccak256(abi.encodePacked("node.deposit.credit.balance", _nodeOperator)), _amount);
    }

    /// @notice Accept a node deposit and create a new minipool under the node. Only accepts calls from registered nodes
    /// @param _bondAmount The amount of capital the node operator wants to put up as his bond
    /// @param _minimumNodeFee Transaction will revert if network commission rate drops below this amount
    /// @param _validatorPubkey Pubkey of the validator the node operator wishes to migrate
    /// @param _validatorSignature Signature from the validator over the deposit data
    /// @param _depositDataRoot The hash tree root of the deposit data (passed onto the deposit contract on pre stake)
    /// @param _salt Salt used to deterministically construct the minipool's address
    /// @param _expectedMinipoolAddress The expected deterministic minipool address. Will revert if it doesn't match
    function deposit(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) override external payable onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Check amount
        require(msg.value == _bondAmount, "Invalid value");
        // Process the deposit
        _deposit(_bondAmount, _minimumNodeFee, _validatorPubkey, _validatorSignature, _depositDataRoot, _salt, _expectedMinipoolAddress);
    }

    /// @notice Accept a node deposit and create a new minipool under the node. Only accepts calls from registered nodes
    /// @param _bondAmount The amount of capital the node operator wants to put up as his bond
    /// @param _minimumNodeFee Transaction will revert if network commission rate drops below this amount
    /// @param _validatorPubkey Pubkey of the validator the node operator wishes to migrate
    /// @param _validatorSignature Signature from the validator over the deposit data
    /// @param _depositDataRoot The hash tree root of the deposit data (passed onto the deposit contract on pre stake)
    /// @param _salt Salt used to deterministically construct the minipool's address
    /// @param _expectedMinipoolAddress The expected deterministic minipool address. Will revert if it doesn't match
    function depositWithCredit(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) override external payable onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Query node's deposit credit
        uint256 credit = getNodeDepositCredit(msg.sender);
        // Credit balance accounting
        if (credit < _bondAmount) {
            uint256 shortFall = _bondAmount.sub(credit);
            require(msg.value == shortFall, "Invalid value");
            setUint(keccak256(abi.encodePacked("node.deposit.credit.balance", msg.sender)), 0);
        } else {
            require(msg.value == 0, "Invalid value");
            subUint(keccak256(abi.encodePacked("node.deposit.credit.balance", msg.sender)), _bondAmount);
        }
        // Process the deposit
        _deposit(_bondAmount, _minimumNodeFee, _validatorPubkey, _validatorSignature, _depositDataRoot, _salt, _expectedMinipoolAddress);
    }

    /// @notice Returns true if the given amount is a valid deposit amount
    function isValidDepositAmount(uint256 _amount) override public pure returns (bool) {
        return _amount == 16 ether || _amount == 8 ether || _amount == 4 ether;
    }

    /// @notice Returns an array of valid deposit amounts
    function getDepositAmounts() override external pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 16 ether;
        amounts[1] = 8 ether;
        amounts[2] = 4 ether;
        return amounts;
    }

    /// @dev Internal logic to process a deposit
    function _deposit(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) private {
        // Check pre-conditions
        checkDepositsEnabled();
        checkDistributorInitialised();
        checkNodeFee(_minimumNodeFee);
        require(isValidDepositAmount(_bondAmount), "Invalid deposit amount");
        // Get launch constants
        uint256 launchAmount;
        uint256 preLaunchValue;
        {
            RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
            launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
            preLaunchValue = rocketDAOProtocolSettingsMinipool.getPreLaunchValue();
        }
        // Check that pre deposit won't fail
        if (msg.value < preLaunchValue) {
            RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
            require(preLaunchValue.sub(msg.value) <= rocketDepositPool.getBalance(), "Deposit pool balance is insufficient for pre deposit");
        }
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
        // Increase ETH matched (used to calculate RPL collateral requirements)
        _increaseEthMatched(msg.sender, launchAmount.sub(_bondAmount));
        // Create the minipool
        RocketMinipoolInterface minipool = createMinipool(_salt, _expectedMinipoolAddress);
        // Process node deposit
        _processNodeDeposit(preLaunchValue, _bondAmount);
        // Perform the pre deposit
        minipool.preDeposit{value: preLaunchValue}(_bondAmount, _validatorPubkey, _validatorSignature, _depositDataRoot);
        // Enqueue the minipool
        enqueueMinipool(address(minipool));
        // Assign deposits if enabled
        assignDeposits();
    }

    /// @dev Processes a node deposit with the deposit pool
    /// @param _preLaunchValue The prelaunch value (result of call to `RocketDAOProtocolSettingsMinipool.getPreLaunchValue()`
    /// @param _bondAmount The bond amount for this deposit
    function _processNodeDeposit(uint256 _preLaunchValue, uint256 _bondAmount) private {
        // Get contracts
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        // Retrieve ETH from deposit pool if required
        uint256 shortFall = 0;
        if (msg.value < _preLaunchValue) {
            shortFall = _preLaunchValue.sub(msg.value);
            rocketDepositPool.nodeCreditWithdrawal(shortFall);
        }
        uint256 remaining = msg.value.add(shortFall).sub(_preLaunchValue);
        // Deposit the left over value into the deposit pool
        rocketDepositPool.nodeDeposit{value: remaining}(_bondAmount.sub(_preLaunchValue));
    }

    /// @notice Creates a "vacant" minipool which a node operator can use to migrate a validator with a BLS withdrawal credential
    /// @param _bondAmount The amount of capital the node operator wants to put up as his bond
    /// @param _minimumNodeFee Transaction will revert if network commission rate drops below this amount
    /// @param _validatorPubkey Pubkey of the validator the node operator wishes to migrate
    /// @param _salt Salt used to deterministically construct the minipool's address
    /// @param _expectedMinipoolAddress The expected deterministic minipool address. Will revert if it doesn't match
    /// @param _currentBalance The current balance of the validator on the beaconchain (will be checked by oDAO and scrubbed if not correct)
    function createVacantMinipool(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, uint256 _salt, address _expectedMinipoolAddress, uint256 _currentBalance) override external onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Check pre-conditions
        checkVacantMinipoolsEnabled();
        checkDistributorInitialised();
        checkNodeFee(_minimumNodeFee);
        require(isValidDepositAmount(_bondAmount), "Invalid deposit amount");
        // Increase ETH matched (used to calculate RPL collateral requirements)
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
        _increaseEthMatched(msg.sender, launchAmount.sub(_bondAmount));
        // Create the minipool
        _createVacantMinipool(_salt, _validatorPubkey, _bondAmount, _expectedMinipoolAddress, _currentBalance);
    }

    /// @notice Called by minipools during bond reduction to increase the amount of ETH the node operator has
    /// @param _nodeAddress The node operator's address to increase the ETH matched for
    /// @param _amount The amount to increase the ETH matched
    /// @dev Will revert if the new ETH matched amount exceeds the node operators limit
    function increaseEthMatched(address _nodeAddress, uint256 _amount) override external onlyLatestContract("rocketNodeDeposit", address(this)) onlyLatestNetworkContract() {
        _increaseEthMatched(_nodeAddress, _amount);
    }

    /// @dev Increases the amount of ETH that has been matched against a node operators bond. Reverts if it exceeds the
    ///      collateralisation requirements of the network
    function _increaseEthMatched(address _nodeAddress, uint256 _amount) private {
        // Check amount doesn't exceed limits
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
        uint256 ethMatched = rocketNodeStaking.getNodeETHMatched(_nodeAddress).add(_amount);
        require(
            ethMatched <= rocketNodeStaking.getNodeETHMatchedLimit(_nodeAddress),
            "ETH matched after deposit exceeds limit based on node RPL stake"
        );
        setUint(keccak256(abi.encodePacked("eth.matched.node.amount", _nodeAddress)), ethMatched);
    }

    /// @dev Adds a minipool to the queue
    function enqueueMinipool(address _minipoolAddress) private {
        // Add minipool to queue
        RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue")).enqueueMinipool(_minipoolAddress);
    }

    /// @dev Reverts if node operator has not initialised their fee distributor
    function checkDistributorInitialised() private view {
        // Check node has initialised their fee distributor
        RocketNodeManagerInterface rocketNodeManager = RocketNodeManagerInterface(getContractAddress("rocketNodeManager"));
        require(rocketNodeManager.getFeeDistributorInitialised(msg.sender), "Fee distributor not initialised");
    }

    /// @dev Creates a minipool and returns an instance of it
    /// @param _salt The salt used to determine the minipools address
    /// @param _expectedMinipoolAddress The expected minipool address. Reverts if not correct
    function createMinipool(uint256 _salt, address _expectedMinipoolAddress) private returns (RocketMinipoolInterface) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Check minipool doesn't exist or previously exist
        require(!rocketMinipoolManager.getMinipoolExists(_expectedMinipoolAddress) && !rocketMinipoolManager.getMinipoolDestroyed(_expectedMinipoolAddress), "Minipool already exists or was previously destroyed");
        // Create minipool
        RocketMinipoolInterface minipool = rocketMinipoolManager.createMinipool(msg.sender, _salt);
        // Ensure minipool address matches expected
        require(address(minipool) == _expectedMinipoolAddress, "Unexpected minipool address");
        // Return
        return minipool;
    }

    /// @dev Creates a vacant minipool and returns an instance of it
    /// @param _salt The salt used to determine the minipools address
    /// @param _validatorPubkey Pubkey of the validator owning this minipool
    /// @param _bondAmount ETH value the node operator is putting up as capital for this minipool
    /// @param _expectedMinipoolAddress The expected minipool address. Reverts if not correct
    /// @param _currentBalance The current balance of the validator on the beaconchain (will be checked by oDAO and scrubbed if not correct)
    function _createVacantMinipool(uint256 _salt, bytes calldata _validatorPubkey, uint256 _bondAmount, address _expectedMinipoolAddress, uint256 _currentBalance) private returns (RocketMinipoolInterface) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Check minipool doesn't exist or previously exist
        require(!rocketMinipoolManager.getMinipoolExists(_expectedMinipoolAddress) && !rocketMinipoolManager.getMinipoolDestroyed(_expectedMinipoolAddress), "Minipool already exists or was previously destroyed");
        // Create minipool
        RocketMinipoolInterface minipool = rocketMinipoolManager.createVacantMinipool(msg.sender, _salt, _validatorPubkey, _bondAmount, _currentBalance);
        // Ensure minipool address matches expected
        require(address(minipool) == _expectedMinipoolAddress, "Unexpected minipool address");
        // Return
        return minipool;
    }

    /// @dev Reverts if network node fee is below a minimum
    /// @param _minimumNodeFee The minimum node fee required to not revert
    function checkNodeFee(uint256 _minimumNodeFee) private view {
        // Load contracts
        RocketNetworkFeesInterface rocketNetworkFees = RocketNetworkFeesInterface(getContractAddress("rocketNetworkFees"));
        // Check current node fee
        uint256 nodeFee = rocketNetworkFees.getNodeFee();
        require(nodeFee >= _minimumNodeFee, "Minimum node fee exceeds current network node fee");
    }

    /// @dev Reverts if deposits are not enabled
    function checkDepositsEnabled() private view {
        // Get contracts
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Check node settings
        require(rocketDAOProtocolSettingsNode.getDepositEnabled(), "Node deposits are currently disabled");
    }

    /// @dev Reverts if vacant minipools are not enabled
    function checkVacantMinipoolsEnabled() private view {
        // Get contracts
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Check node settings
        require(rocketDAOProtocolSettingsNode.getVacantMinipoolsEnabled(), "Vacant minipools are currently disabled");
    }

    /// @dev Executes an assignDeposits call on the deposit pool
    function assignDeposits() private {
        RocketDAOProtocolSettingsDepositInterface rocketDAOProtocolSettingsDeposit = RocketDAOProtocolSettingsDepositInterface(getContractAddress("rocketDAOProtocolSettingsDeposit"));
        if (rocketDAOProtocolSettingsDeposit.getAssignDepositsEnabled()) {
            RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
            rocketDepositPool.assignDeposits();
        }
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "./RocketMinipoolStorageLayout.sol";
import "../../interface/RocketStorageInterface.sol";
import "../../interface/minipool/RocketMinipoolBaseInterface.sol";

/// @notice Contains the initialisation and delegate upgrade logic for minipools
contract RocketMinipoolBase is RocketMinipoolBaseInterface, RocketMinipoolStorageLayout {

    // Events
    event EtherReceived(address indexed from, uint256 amount, uint256 time);
    event DelegateUpgraded(address oldDelegate, address newDelegate, uint256 time);
    event DelegateRolledBack(address oldDelegate, address newDelegate, uint256 time);

    // Store a reference to the address of RocketMinipoolBase itself to prevent direct calls to this contract
    address immutable self;

    constructor () {
        self = address(this);
    }

    /// @dev Prevent direct calls to this contract
    modifier notSelf() {
        require(address(this) != self);
        _;
    }

    /// @dev Only allow access from the owning node address
    modifier onlyMinipoolOwner() {
        // Only the node operator can upgrade
        address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(nodeAddress);
        require(msg.sender == nodeAddress || msg.sender == withdrawalAddress, "Only the node operator can access this method");
        _;
    }

    /// @notice Sets up starting delegate contract and then delegates initialisation to it
    function initialise(address _rocketStorage, address _nodeAddress) external override notSelf {
        // Check input
        require(_nodeAddress != address(0), "Invalid node address");
        require(storageState == StorageState.Undefined, "Already initialised");
        // Set storage state to uninitialised
        storageState = StorageState.Uninitialised;
        // Set rocketStorage
        rocketStorage = RocketStorageInterface(_rocketStorage);
        // Set the current delegate
        address delegateAddress = getContractAddress("rocketMinipoolDelegate");
        rocketMinipoolDelegate = delegateAddress;
        // Check for contract existence
        require(contractExists(delegateAddress), "Delegate contract does not exist");
        // Call initialise on delegate
        (bool success, bytes memory data) = delegateAddress.delegatecall(abi.encodeWithSignature('initialise(address)', _nodeAddress));
        if (!success) { revert(getRevertMessage(data)); }
    }

    /// @notice Receive an ETH deposit
    receive() external payable notSelf {
        // Emit ether received event
        emit EtherReceived(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Upgrade this minipool to the latest network delegate contract
    function delegateUpgrade() external override onlyMinipoolOwner notSelf {
        // Set previous address
        rocketMinipoolDelegatePrev = rocketMinipoolDelegate;
        // Set new delegate
        rocketMinipoolDelegate = getContractAddress("rocketMinipoolDelegate");
        // Verify
        require(rocketMinipoolDelegate != rocketMinipoolDelegatePrev, "New delegate is the same as the existing one");
        // Log event
        emit DelegateUpgraded(rocketMinipoolDelegatePrev, rocketMinipoolDelegate, block.timestamp);
    }

    /// @notice Rollback to previous delegate contract
    function delegateRollback() external override onlyMinipoolOwner notSelf {
        // Make sure they have upgraded before
        require(rocketMinipoolDelegatePrev != address(0x0), "Previous delegate contract is not set");
        // Store original
        address originalDelegate = rocketMinipoolDelegate;
        // Update delegate to previous and zero out previous
        rocketMinipoolDelegate = rocketMinipoolDelegatePrev;
        rocketMinipoolDelegatePrev = address(0x0);
        // Log event
        emit DelegateRolledBack(originalDelegate, rocketMinipoolDelegate, block.timestamp);
    }

    /// @notice Sets the flag to automatically use the latest delegate contract or not
    /// @param _setting If true, will always use the latest delegate contract
    function setUseLatestDelegate(bool _setting) external override onlyMinipoolOwner notSelf {
        useLatestDelegate = _setting;
    }

    /// @notice Returns true if this minipool always uses the latest delegate contract
    function getUseLatestDelegate() external override view returns (bool) {
        return useLatestDelegate;
    }

    /// @notice Returns the address of the minipool's stored delegate
    function getDelegate() external override view returns (address) {
        return rocketMinipoolDelegate;
    }

    /// @notice Returns the address of the minipool's previous delegate (or address(0) if not set)
    function getPreviousDelegate() external override view returns (address) {
        return rocketMinipoolDelegatePrev;
    }

    /// @notice Returns the delegate which will be used when calling this minipool taking into account useLatestDelegate setting
    function getEffectiveDelegate() external override view returns (address) {
        return useLatestDelegate ? getContractAddress("rocketMinipoolDelegate") : rocketMinipoolDelegate;
    }

    /// @notice Delegates all calls to minipool delegate contract (or latest if flag is set)
    fallback(bytes calldata _input) external payable notSelf returns (bytes memory) {
        // If useLatestDelegate is set, use the latest delegate contract
        address delegateContract = useLatestDelegate ? getContractAddress("rocketMinipoolDelegate") : rocketMinipoolDelegate;
        // Check for contract existence
        require(contractExists(delegateContract), "Delegate contract does not exist");
        // Execute delegatecall
        (bool success, bytes memory data) = delegateContract.delegatecall(_input);
        if (!success) { revert(getRevertMessage(data)); }
        return data;
    }

    /// @dev Get the address of a Rocket Pool network contract
    function getContractAddress(string memory _contractName) private view returns (address) {
        address contractAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        require(contractAddress != address(0x0), "Contract not found");
        return contractAddress;
    }

    /// @dev Get a revert message from delegatecall return data
    function getRevertMessage(bytes memory _returnData) private pure returns (string memory) {
        if (_returnData.length < 68) { return "Transaction reverted silently"; }
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }

    /// @dev Returns true if contract exists at _contractAddress (if called during that contract's construction it will return a false negative)
    function contractExists(address _contractAddress) private view returns (bool) {
        uint32 codeSize;
        assembly {
            codeSize := extcodesize(_contractAddress)
        }
        return codeSize > 0;
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolBondReducerInterface.sol";
import "../../interface/node/RocketNodeDepositInterface.sol";
import "../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMinipoolInterface.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";

/// @notice Handles bond reduction window and trusted node cancellation
contract RocketMinipoolBondReducer is RocketBase, RocketMinipoolBondReducerInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event BeginBondReduction(address indexed minipool, uint256 newBondAmount, uint256 time);
    event CancelReductionVoted(address indexed minipool, address indexed member, uint256 time);
    event ReductionCancelled(address indexed minipool, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    /// @notice Flags a minipool as wanting to reduce collateral, owner can then call `reduceBondAmount` once waiting
    ///         period has elapsed
    /// @param _minipoolAddress Address of the minipool
    /// @param _newBondAmount The new bond amount
    function beginReduceBondAmount(address _minipoolAddress, uint256 _newBondAmount) override external onlyLatestContract("rocketMinipoolBondReducer", address(this)) {
        // Only minipool owner can call
        RocketMinipoolInterface minipool = RocketMinipoolInterface(_minipoolAddress);
        require(msg.sender == minipool.getNodeAddress(), "Only minipool owner");
        // Get contracts
        RocketNodeDepositInterface rocketNodeDeposit = RocketNodeDepositInterface(getContractAddress("rocketNodeDeposit"));
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        RocketDAOProtocolSettingsMinipoolInterface daoSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Check if enabled
        require(daoSettingsMinipool.getBondReductionEnabled(), "Bond reduction currently disabled");
        // Check if has been previously cancelled
        bool reductionCancelled = getBool(keccak256(abi.encodePacked("minipool.bond.reduction.cancelled", address(minipool))));
        require(!reductionCancelled, "This minipool is not allowed to reduce bond");
        require(minipool.getStatus() == MinipoolStatus.Staking, "Minipool must be staking");
        // Check if new bond amount is valid
        require(rocketNodeDeposit.isValidDepositAmount(_newBondAmount), "Invalid bond amount");
        uint256 existing = minipool.getNodeDepositBalance();
        require(_newBondAmount < existing, "Bond must be lower than current amount");
        // Check if enough time has elapsed since last reduction
        uint256 lastReduction = getUint(keccak256(abi.encodePacked("minipool.last.bond.reduction.time", _minipoolAddress)));
        uint256 rewardInterval = daoSettingsRewards.getRewardsClaimIntervalTime();
        require(block.timestamp >= lastReduction.add(rewardInterval), "Not enough time has passed since last bond reduction");
        // Store time and new bond amount
        setUint(keccak256(abi.encodePacked("minipool.bond.reduction.time", _minipoolAddress)), block.timestamp);
        setUint(keccak256(abi.encodePacked("minipool.bond.reduction.value", _minipoolAddress)), _newBondAmount);
        emit BeginBondReduction(_minipoolAddress, _newBondAmount, block.timestamp);
    }

    /// @notice Returns the timestamp of when a given minipool began their bond reduction waiting period
    /// @param _minipoolAddress Address of the minipool to query
    function getReduceBondTime(address _minipoolAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("minipool.bond.reduction.time", _minipoolAddress)));
    }

    /// @notice Returns the new bond that a given minipool has indicated they are reducing to
    /// @param _minipoolAddress Address of the minipool to query
    function getReduceBondValue(address _minipoolAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("minipool.bond.reduction.value", _minipoolAddress)));
    }

    /// @notice Returns true if the given minipool has had it's bond reduction cancelled by the oDAO
    /// @param _minipoolAddress Address of the minipool to query
    function getReduceBondCancelled(address _minipoolAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("minipool.bond.reduction.cancelled", address(_minipoolAddress))));
    }

    /// @notice Returns whether owner of given minipool can reduce bond amount given the waiting period constraint
    /// @param _minipoolAddress Address of the minipool
    function canReduceBondAmount(address _minipoolAddress) override public view returns (bool) {
        RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
        uint256 reduceBondTime = getUint(keccak256(abi.encodePacked("minipool.bond.reduction.time", _minipoolAddress)));
        return rocketDAONodeTrustedSettingsMinipool.isWithinBondReductionWindow(block.timestamp.sub(reduceBondTime));
    }

    /// @notice Can be called by trusted nodes to cancel a reduction in bond if the validator has too low of a balance
    /// @param _minipoolAddress Address of the minipool
    function voteCancelReduction(address _minipoolAddress) override external onlyTrustedNode(msg.sender) onlyLatestContract("rocketMinipoolBondReducer", address(this)) {
        // Prevent calling if consensus has already been reached
        require(!getReduceBondCancelled(_minipoolAddress), "Already cancelled");
        // Get contracts
        RocketDAONodeTrustedInterface rocketDAONode = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        // Check for multiple votes
        bytes32 memberVotedKey = keccak256(abi.encodePacked("minipool.bond.reduction.member.voted", _minipoolAddress, msg.sender));
        bool memberVoted = getBool(memberVotedKey);
        require(!memberVoted, "Member has already voted to cancel");
        setBool(memberVotedKey, true);
        // Emit event
        emit CancelReductionVoted(_minipoolAddress, msg.sender, block.timestamp);
        // Check if required quorum has voted
        RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
        uint256 quorum = rocketDAONode.getMemberCount().mul(rocketDAONodeTrustedSettingsMinipool.getCancelBondReductionQuorum()).div(calcBase);
        bytes32 totalCancelVotesKey = keccak256(abi.encodePacked("minipool.bond.reduction.vote.count", _minipoolAddress));
        uint256 totalCancelVotes = getUint(totalCancelVotesKey).add(1);
        if (totalCancelVotes > quorum) {
            // Emit event
            emit ReductionCancelled(_minipoolAddress, block.timestamp);
            setBool(keccak256(abi.encodePacked("minipool.bond.reduction.cancelled", _minipoolAddress)), true);
            deleteUint(keccak256(abi.encodePacked("minipool.bond.reduction.time", _minipoolAddress)));
            deleteUint(keccak256(abi.encodePacked("minipool.bond.reduction.value", msg.sender)));
        } else {
            // Increment total
            setUint(totalCancelVotesKey, totalCancelVotes);
        }
    }

    /// @notice Called by minipools when they are reducing bond to handle state changes outside the minipool
    function reduceBondAmount() override external onlyRegisteredMinipool(msg.sender) onlyLatestContract("rocketMinipoolBondReducer", address(this)) returns (uint256) {
        // Get contracts
        RocketNodeDepositInterface rocketNodeDeposit = RocketNodeDepositInterface(getContractAddress("rocketNodeDeposit"));
        RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
        RocketDAOProtocolSettingsMinipoolInterface daoSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Check if enabled
        require(daoSettingsMinipool.getBondReductionEnabled(), "Bond reduction currently disabled");
        // Check if has been cancelled
        bool reductionCancelled = getBool(keccak256(abi.encodePacked("minipool.bond.reduction.cancelled", address(msg.sender))));
        require(!reductionCancelled, "This minipool is not allowed to reduce bond");
        // Check wait period is satisfied
        require(canReduceBondAmount(msg.sender), "Wait period not satisfied");
        // Get desired to amount
        uint256 newBondAmount = getUint(keccak256(abi.encodePacked("minipool.bond.reduction.value", msg.sender)));
        require(rocketNodeDeposit.isValidDepositAmount(newBondAmount), "Invalid bond amount");
        // Calculate difference
        uint256 existingBondAmount = minipool.getNodeDepositBalance();
        uint256 existingNodeFee = minipool.getNodeFee();
        uint256 delta = existingBondAmount.sub(newBondAmount);
        // Get node address
        address nodeAddress = minipool.getNodeAddress();
        // Increase ETH matched or revert if exceeds limit based on current RPL stake
        rocketNodeDeposit.increaseEthMatched(nodeAddress, delta);
        // Increase node operator's deposit credit
        rocketNodeDeposit.increaseDepositCreditBalance(nodeAddress, delta);
        // Clean up state
        deleteUint(keccak256(abi.encodePacked("minipool.bond.reduction.time", msg.sender)));
        deleteUint(keccak256(abi.encodePacked("minipool.bond.reduction.value", msg.sender)));
        // Store last bond reduction time and previous bond amount
        setUint(keccak256(abi.encodePacked("minipool.last.bond.reduction.time", msg.sender)), block.timestamp);
        setUint(keccak256(abi.encodePacked("minipool.last.bond.reduction.prev.value", msg.sender)), existingBondAmount);
        setUint(keccak256(abi.encodePacked("minipool.last.bond.reduction.prev.fee", msg.sender)), existingNodeFee);
        // Return
        return newBondAmount;
    }

    /// @notice Returns a timestamp of when the given minipool last performed a bond reduction
    /// @param _minipoolAddress The address of the minipool to query
    /// @return Unix timestamp of last bond reduction (or 0 if never reduced)
    function getLastBondReductionTime(address _minipoolAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("minipool.last.bond.reduction.time", _minipoolAddress)));
    }

    /// @notice Returns the previous bond value of the given minipool on their last bond reduction
    /// @param _minipoolAddress The address of the minipool to query
    /// @return Previous bond value in wei (or 0 if never reduced)
    function getLastBondReductionPrevValue(address _minipoolAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("minipool.last.bond.reduction.prev.value", _minipoolAddress)));
    }

    /// @notice Returns the previous node fee of the given minipool on their last bond reduction
    /// @param _minipoolAddress The address of the minipool to query
    /// @return Previous node fee
    function getLastBondReductionPrevNodeFee(address _minipoolAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("minipool.last.bond.reduction.prev.fee", _minipoolAddress)));
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./RocketMinipoolStorageLayout.sol";
import "../../interface/casper/DepositInterface.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/minipool/RocketMinipoolPenaltyInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/network/RocketNetworkFeesInterface.sol";
import "../../interface/token/RocketTokenRETHInterface.sol";
import "../../types/MinipoolDeposit.sol";
import "../../types/MinipoolStatus.sol";
import "../../interface/node/RocketNodeDepositInterface.sol";
import "../../interface/minipool/RocketMinipoolBondReducerInterface.sol";

/// @notice Provides the logic for each individual minipool in the Rocket Pool network
/// @dev Minipools exclusively DELEGATECALL into this contract it is never called directly
contract RocketMinipoolDelegate is RocketMinipoolStorageLayout, RocketMinipoolInterface {

    // Constants
    uint8 public constant override version = 3;                   // Used to identify which delegate contract each minipool is using
    uint256 constant calcBase = 1 ether;                          // Fixed point arithmetic uses this for value for precision
    uint256 constant legacyPrelaunchAmount = 16 ether;            // The amount of ETH initially deposited when minipool is created (for legacy minipools)

    // Libs
    using SafeMath for uint;

    // Events
    event StatusUpdated(uint8 indexed status, uint256 time);
    event ScrubVoted(address indexed member, uint256 time);
    event BondReduced(uint256 previousBondAmount, uint256 newBondAmount, uint256 time);
    event MinipoolScrubbed(uint256 time);
    event MinipoolPrestaked(bytes validatorPubkey, bytes validatorSignature, bytes32 depositDataRoot, uint256 amount, bytes withdrawalCredentials, uint256 time);
    event MinipoolPromoted(uint256 time);
    event MinipoolVacancyPrepared(uint256 bondAmount, uint256 currentBalance, uint256 time);
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event EtherWithdrawn(address indexed to, uint256 amount, uint256 time);
    event EtherWithdrawalProcessed(address indexed executed, uint256 nodeAmount, uint256 userAmount, uint256 totalBalance, uint256 time);

    // Status getters
    function getStatus() override external view returns (MinipoolStatus) { return status; }
    function getFinalised() override external view returns (bool) { return finalised; }
    function getStatusBlock() override external view returns (uint256) { return statusBlock; }
    function getStatusTime() override external view returns (uint256) { return statusTime; }
    function getScrubVoted(address _member) override external view returns (bool) { return memberScrubVotes[_member]; }

    // Deposit type getter
    function getDepositType() override external view returns (MinipoolDeposit) { return depositType; }

    // Node detail getters
    function getNodeAddress() override external view returns (address) { return nodeAddress; }
    function getNodeFee() override external view returns (uint256) { return nodeFee; }
    function getNodeDepositBalance() override external view returns (uint256) { return nodeDepositBalance; }
    function getNodeRefundBalance() override external view returns (uint256) { return nodeRefundBalance; }
    function getNodeDepositAssigned() override external view returns (bool) { return userDepositAssignedTime != 0; }
    function getPreLaunchValue() override external view returns (uint256) { return preLaunchValue; }
    function getNodeTopUpValue() override external view returns (uint256) { return nodeDepositBalance.sub(preLaunchValue); }
    function getVacant() override external view returns (bool) { return vacant; }
    function getPreMigrationBalance() override external view returns (uint256) { return preMigrationBalance; }
    function getUserDistributed() override external view returns (bool) { return userDistributed; }

    // User deposit detail getters
    function getUserDepositBalance() override public view returns (uint256) {
        if (depositType == MinipoolDeposit.Variable) {
            return userDepositBalance;
        } else {
            return userDepositBalanceLegacy;
        }
    }
    function getUserDepositAssigned() override external view returns (bool) { return userDepositAssignedTime != 0; }
    function getUserDepositAssignedTime() override external view returns (uint256) { return userDepositAssignedTime; }
    function getTotalScrubVotes() override external view returns (uint256) { return totalScrubVotes; }

    /// @dev Prevent direct calls to this contract
    modifier onlyInitialised() {
        require(storageState == StorageState.Initialised, "Storage state not initialised");
        _;
    }

    /// @dev Prevent multiple calls to initialise
    modifier onlyUninitialised() {
        require(storageState == StorageState.Uninitialised, "Storage state already initialised");
        _;
    }

    /// @dev Only allow access from the owning node address
    modifier onlyMinipoolOwner(address _nodeAddress) {
        require(_nodeAddress == nodeAddress, "Invalid minipool owner");
        _;
    }

    /// @dev Only allow access from the owning node address or their withdrawal address
    modifier onlyMinipoolOwnerOrWithdrawalAddress(address _nodeAddress) {
        require(_nodeAddress == nodeAddress || _nodeAddress == rocketStorage.getNodeWithdrawalAddress(nodeAddress), "Invalid minipool owner");
        _;
    }

    /// @dev Only allow access from the latest version of the specified Rocket Pool contract
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getContractAddress(_contractName), "Invalid or outdated contract");
        _;
    }

    /// @dev Get the address of a Rocket Pool network contract
    /// @param _contractName The internal name of the contract to retrieve the address for
    function getContractAddress(string memory _contractName) private view returns (address) {
        address contractAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        require(contractAddress != address(0x0), "Contract not found");
        return contractAddress;
    }

    /// @dev Called once on creation to initialise starting state
    /// @param _nodeAddress The address of the node operator who will own this minipool
    function initialise(address _nodeAddress) override external onlyUninitialised {
        // Check parameters
        require(_nodeAddress != address(0x0), "Invalid node address");
        // Load contracts
        RocketNetworkFeesInterface rocketNetworkFees = RocketNetworkFeesInterface(getContractAddress("rocketNetworkFees"));
        // Set initial status
        status = MinipoolStatus.Initialised;
        statusBlock = block.number;
        statusTime = block.timestamp;
        // Set details
        depositType = MinipoolDeposit.Variable;
        nodeAddress = _nodeAddress;
        nodeFee = rocketNetworkFees.getNodeFee();
        // Set the rETH address
        rocketTokenRETH = getContractAddress("rocketTokenRETH");
        // Set local copy of penalty contract
        rocketMinipoolPenalty = getContractAddress("rocketMinipoolPenalty");
        // Intialise storage state
        storageState = StorageState.Initialised;
    }

    /// @notice Performs the initial pre-stake on the beacon chain to set the withdrawal credentials
    /// @param _bondValue The amount of the stake which will be provided by the node operator
    /// @param _validatorPubkey The public key of the validator
    /// @param _validatorSignature A signature over the deposit message object
    /// @param _depositDataRoot The hash tree root of the deposit data object
    function preDeposit(uint256 _bondValue, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) override external payable onlyLatestContract("rocketNodeDeposit", msg.sender) onlyInitialised {
        // Check current status & node deposit status
        require(status == MinipoolStatus.Initialised, "The pre-deposit can only be made while initialised");
        require(preLaunchValue == 0, "Pre-deposit already performed");
        // Update node deposit details
        nodeDepositBalance = _bondValue;
        preLaunchValue = msg.value;
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, preLaunchValue, block.timestamp);
        // Perform the pre-stake to lock in withdrawal credentials on beacon chain
        preStake(_validatorPubkey, _validatorSignature, _depositDataRoot);
    }

    /// @notice Performs the second deposit which provides the validator with the remaining balance to become active
    function deposit() override external payable onlyLatestContract("rocketDepositPool", msg.sender) onlyInitialised {
        // Check current status & node deposit status
        require(status == MinipoolStatus.Initialised, "The node deposit can only be assigned while initialised");
        require(userDepositAssignedTime == 0, "The user deposit has already been assigned");
        // Set the minipool status to prelaunch (ready for node to call `stake()`)
        setStatus(MinipoolStatus.Prelaunch);
        // Update deposit details
        userDepositBalance = msg.value.add(preLaunchValue).sub(nodeDepositBalance);
        userDepositAssignedTime = block.timestamp;
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Assign user deposited ETH to the minipool and mark it as prelaunch
    /// @dev No longer used in "Variable" type minipools (only retained for legacy minipools still in queue)
    function userDeposit() override external payable onlyLatestContract("rocketDepositPool", msg.sender) onlyInitialised {
        // Check current status & user deposit status
        require(status >= MinipoolStatus.Initialised && status <= MinipoolStatus.Staking, "The user deposit can only be assigned while initialised, in prelaunch, or staking");
        require(userDepositAssignedTime == 0, "The user deposit has already been assigned");
        // Progress initialised minipool to prelaunch
        if (status == MinipoolStatus.Initialised) { setStatus(MinipoolStatus.Prelaunch); }
        // Update user deposit details
        userDepositBalance = msg.value;
        userDepositAssignedTime = block.timestamp;
        // Refinance full minipool
        if (depositType == MinipoolDeposit.Full) {
            // Update node balances
            nodeDepositBalance = nodeDepositBalance.sub(msg.value);
            nodeRefundBalance = nodeRefundBalance.add(msg.value);
        }
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    /// @notice Refund node ETH refinanced from user deposited ETH
    function refund() override external onlyMinipoolOwnerOrWithdrawalAddress(msg.sender) onlyInitialised {
        // Check refund balance
        require(nodeRefundBalance > 0, "No amount of the node deposit is available for refund");
        // If this minipool was distributed by a user, force finalisation on the node operator
        if (!finalised && userDistributed) {
            // Note: _refund is called inside _finalise
            _finalise();
        } else {
            // Refund node
            _refund();
        }
    }

    /// @notice Called to slash node operator's RPL balance if withdrawal balance was less than user deposit
    function slash() external override onlyInitialised {
        // Check there is a slash balance
        require(nodeSlashBalance > 0, "No balance to slash");
        // Perform slash
        _slash();
    }

    /// @notice Returns true when `stake()` can be called by node operator taking into consideration the scrub period
    function canStake() override external view onlyInitialised returns (bool) {
        // Check status
        if (status != MinipoolStatus.Prelaunch) {
            return false;
        }
        // Get contracts
        RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
        // Get scrub period
        uint256 scrubPeriod = rocketDAONodeTrustedSettingsMinipool.getScrubPeriod();
        // Check if we have been in prelaunch status for long enough
        return block.timestamp > statusTime + scrubPeriod;
    }

    /// @notice Returns true when `promote()` can be called by node operator taking into consideration the scrub period
    function canPromote() override external view onlyInitialised returns (bool) {
        // Check status
        if (status != MinipoolStatus.Prelaunch) {
            return false;
        }
        // Get contracts
        RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
        // Get scrub period
        uint256 scrubPeriod = rocketDAONodeTrustedSettingsMinipool.getPromotionScrubPeriod();
        // Check if we have been in prelaunch status for long enough
        return block.timestamp > statusTime + scrubPeriod;
    }

    /// @notice Progress the minipool to staking, sending its ETH deposit to the deposit contract. Only accepts calls from the minipool owner (node) while in prelaunch and once scrub period has ended
    /// @param _validatorSignature A signature over the deposit message object
    /// @param _depositDataRoot The hash tree root of the deposit data object
    function stake(bytes calldata _validatorSignature, bytes32 _depositDataRoot) override external onlyMinipoolOwner(msg.sender) onlyInitialised {
        // Get contracts
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        {
            // Get scrub period
            RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
            uint256 scrubPeriod = rocketDAONodeTrustedSettingsMinipool.getScrubPeriod();
            // Check current status
            require(status == MinipoolStatus.Prelaunch, "The minipool can only begin staking while in prelaunch");
            require(block.timestamp > statusTime + scrubPeriod, "Not enough time has passed to stake");
            require(!vacant, "Cannot stake a vacant minipool");
        }
        // Progress to staking
        setStatus(MinipoolStatus.Staking);
        // Load contracts
        DepositInterface casperDeposit = DepositInterface(getContractAddress("casperDeposit"));
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Get launch amount
        uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
        uint256 depositAmount;
        // Legacy minipools had a prestake equal to the bond amount
        if (depositType == MinipoolDeposit.Variable) {
            depositAmount = launchAmount.sub(preLaunchValue);
        } else {
            depositAmount = launchAmount.sub(legacyPrelaunchAmount);
        }
        // Check minipool balance
        require(address(this).balance >= depositAmount, "Insufficient balance to begin staking");
        // Retrieve validator pubkey from storage
        bytes memory validatorPubkey = rocketMinipoolManager.getMinipoolPubkey(address(this));
        // Send staking deposit to casper
        casperDeposit.deposit{value : depositAmount}(validatorPubkey, rocketMinipoolManager.getMinipoolWithdrawalCredentials(address(this)), _validatorSignature, _depositDataRoot);
        // Increment node's number of staking minipools
        rocketMinipoolManager.incrementNodeStakingMinipoolCount(nodeAddress);
    }

    /// @dev Sets the bond value and vacancy flag on this minipool
    /// @param _bondAmount The bond amount selected by the node operator
    /// @param _currentBalance The current balance of the validator on the beaconchain (will be checked by oDAO and scrubbed if not correct)
    function prepareVacancy(uint256 _bondAmount, uint256 _currentBalance) override external onlyLatestContract("rocketMinipoolManager", msg.sender) onlyInitialised {
        // Check status
        require(status == MinipoolStatus.Initialised, "Must be in initialised status");
        // Sanity check that refund balance is zero
        require(nodeRefundBalance == 0, "Refund balance not zero");
        // Check balance
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
        require(_currentBalance >= launchAmount, "Balance is too low");
        // Store bond amount
        nodeDepositBalance = _bondAmount;
        // Calculate user amount from launch amount
        userDepositBalance = launchAmount.sub(nodeDepositBalance);
        // Flag as vacant
        vacant = true;
        preMigrationBalance = _currentBalance;
        // Refund the node whatever rewards they have accrued prior to becoming a RP validator
        nodeRefundBalance = _currentBalance.sub(launchAmount);
        // Set status to preLaunch
        setStatus(MinipoolStatus.Prelaunch);
        // Emit event
        emit MinipoolVacancyPrepared(_bondAmount, _currentBalance, block.timestamp);
    }

    /// @dev Promotes this minipool to a complete minipool
    function promote() override external onlyMinipoolOwner(msg.sender) onlyInitialised {
        // Check status
        require(status == MinipoolStatus.Prelaunch, "The minipool can only promote while in prelaunch");
        require(vacant, "Cannot promote a non-vacant minipool");
        // Get contracts
        RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
        // Clear vacant flag
        vacant = false;
        // Check scrub period
        uint256 scrubPeriod = rocketDAONodeTrustedSettingsMinipool.getPromotionScrubPeriod();
        require(block.timestamp > statusTime + scrubPeriod, "Not enough time has passed to promote");
        // Progress to staking
        setStatus(MinipoolStatus.Staking);
        // Increment node's number of staking minipools
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        rocketMinipoolManager.incrementNodeStakingMinipoolCount(nodeAddress);
        // Set deposit assigned time
        userDepositAssignedTime = block.timestamp;
        // Increase node operator's deposit credit
        RocketNodeDepositInterface rocketNodeDepositInterface = RocketNodeDepositInterface(getContractAddress("rocketNodeDeposit"));
        rocketNodeDepositInterface.increaseDepositCreditBalance(nodeAddress, userDepositBalance);
        // Remove from vacant set
        rocketMinipoolManager.removeVacantMinipool();
        // Emit event
        emit MinipoolPromoted(block.timestamp);
    }

    /// @dev Stakes the balance of this minipool into the deposit contract to set withdrawal credentials to this contract
    /// @param _validatorSignature A signature over the deposit message object
    /// @param _depositDataRoot The hash tree root of the deposit data object
    function preStake(bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) internal {
        // Load contracts
        DepositInterface casperDeposit = DepositInterface(getContractAddress("casperDeposit"));
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Set minipool pubkey
        rocketMinipoolManager.setMinipoolPubkey(_validatorPubkey);
        // Get withdrawal credentials
        bytes memory withdrawalCredentials = rocketMinipoolManager.getMinipoolWithdrawalCredentials(address(this));
        // Send staking deposit to casper
        casperDeposit.deposit{value : preLaunchValue}(_validatorPubkey, withdrawalCredentials, _validatorSignature, _depositDataRoot);
        // Emit event
        emit MinipoolPrestaked(_validatorPubkey, _validatorSignature, _depositDataRoot, preLaunchValue, withdrawalCredentials, block.timestamp);
    }

    /// @notice Distributes the contract's balance.
    ///         If balance is greater or equal to 8 ETH, the NO can call to distribute capital and finalise the minipool.
    ///         If balance is greater or equal to 8 ETH, users who have called `beginUserDistribute` and waited the required
    ///         amount of time can call to distribute capital.
    ///         If balance is lower than 8 ETH, can be called by anyone and is considered a partial withdrawal and funds are
    ///         split as rewards.
    function distributeBalance() override external onlyInitialised {
        // Get node withdrawal address
        address nodeWithdrawalAddress = rocketStorage.getNodeWithdrawalAddress(nodeAddress);
        bool ownerCalling = msg.sender == nodeAddress || msg.sender == nodeWithdrawalAddress;
        // If dissolved, distribute everything to the owner
        if (status == MinipoolStatus.Dissolved) {
            require(ownerCalling, "Only owner can distribute dissolved minipool");
            distributeToOwner();
            return;
        }
        // Can only be called while in staking status
        require(status == MinipoolStatus.Staking, "Minipool must be staking");
        // Get withdrawal amount, we must also account for a possible node refund balance on the contract
        uint256 totalBalance = address(this).balance.sub(nodeRefundBalance);
        if (totalBalance >= 8 ether) {
            // Consider this a full withdrawal
            _distributeBalance(totalBalance);
            if (ownerCalling) {
                // Finalise the minipool if the owner is calling
                _finalise();
            } else {
                // Require user wait period to pass before allowing user to distribute
                require(userDistributeAllowed(), "Only owner can distribute right now");
                // Mark this minipool as having been distributed by a user
                userDistributed = true;
            }
        } else {
            // Just a partial withdraw
            distributeSkimmedRewards();
            // If node operator is calling, save a tx by calling refund immediately
            if (ownerCalling && nodeRefundBalance > 0) {
                _refund();
            }
        }
        // Reset distribute waiting period
        userDistributeTime = 0;
    }

    /// @dev Distribute the entire balance to the minipool owner
    function distributeToOwner() internal {
        // Get balance
        uint256 balance = address(this).balance;
        // Get node withdrawal address
        address nodeWithdrawalAddress = rocketStorage.getNodeWithdrawalAddress(nodeAddress);
        // Transfer balance
        (bool success,) = nodeWithdrawalAddress.call{value : balance}("");
        require(success, "Node ETH balance was not successfully transferred to node operator");
        // Emit ether withdrawn event
        emit EtherWithdrawn(nodeWithdrawalAddress, balance, block.timestamp);
    }

    /// @notice Allows a user (other than the owner of this minipool) to signal they want to call distribute.
    ///         After waiting the required period, anyone may then call `distributeBalance()`.
    function beginUserDistribute() override external onlyInitialised {
        require(status == MinipoolStatus.Staking, "Minipool must be staking");
        uint256 totalBalance = address(this).balance.sub(nodeRefundBalance);
        require (totalBalance >= 8 ether, "Balance too low");
        // Prevent calls resetting distribute time before window has passed
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        uint256 timeElapsed = block.timestamp.sub(userDistributeTime);
        require(rocketDAOProtocolSettingsMinipool.hasUserDistributeWindowPassed(timeElapsed), "User distribution already pending");
        // Store current time
        userDistributeTime = block.timestamp;
    }

    /// @notice Returns true if enough time has passed for a user to distribute
    function userDistributeAllowed() override public view returns (bool) {
        // Get contracts
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Calculate if time elapsed since call to `beginUserDistribute` is within the allowed window
        uint256 timeElapsed = block.timestamp.sub(userDistributeTime);
        return(rocketDAOProtocolSettingsMinipool.isWithinUserDistributeWindow(timeElapsed));
    }

    /// @notice Allows the owner of this minipool to finalise it after a user has manually distributed the balance
    function finalise() override external onlyMinipoolOwnerOrWithdrawalAddress(msg.sender) onlyInitialised {
        require(userDistributed, "Can only manually finalise after user distribution");
        _finalise();
    }

    /// @dev Perform any slashings, refunds, and unlock NO's stake
    function _finalise() private {
        // Get contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Can only finalise the pool once
        require(!finalised, "Minipool has already been finalised");
        // Set finalised flag
        finalised = true;
        // If slash is required then perform it
        if (nodeSlashBalance > 0) {
            _slash();
        }
        // Refund node operator if required
        if (nodeRefundBalance > 0) {
            _refund();
        }
        // Send any left over ETH to rETH contract
        if (address(this).balance > 0) {
            // Send user amount to rETH contract
            payable(rocketTokenRETH).transfer(address(this).balance);
        }
        // Trigger a deposit of excess collateral from rETH contract to deposit pool
        RocketTokenRETHInterface(rocketTokenRETH).depositExcessCollateral();
        // Unlock node operator's RPL
        rocketMinipoolManager.incrementNodeFinalisedMinipoolCount(nodeAddress);
        rocketMinipoolManager.decrementNodeStakingMinipoolCount(nodeAddress);
    }

    /// @dev Distributes balance to user and node operator
    /// @param _balance The amount to distribute
    function _distributeBalance(uint256 _balance) private {
        // Deposit amounts
        uint256 nodeAmount = 0;
        uint256 userCapital = getUserDepositBalance();
        // Check if node operator was slashed
        if (_balance < userCapital) {
            // Only slash on first call to distribute
            if (withdrawalBlock == 0) {
                // Record shortfall for slashing
                nodeSlashBalance = userCapital.sub(_balance);
            }
        } else {
            // Calculate node's share of the balance
            nodeAmount = _calculateNodeShare(_balance);
        }
        // User amount is what's left over from node's share
        uint256 userAmount = _balance.sub(nodeAmount);
        // Pay node operator via refund
        nodeRefundBalance = nodeRefundBalance.add(nodeAmount);
        // Pay user amount to rETH contract
        if (userAmount > 0) {
            // Send user amount to rETH contract
            payable(rocketTokenRETH).transfer(userAmount);
        }
        // Save block to prevent multiple withdrawals within a few blocks
        withdrawalBlock = block.number;
        // Log it
        emit EtherWithdrawalProcessed(msg.sender, nodeAmount, userAmount, _balance, block.timestamp);
    }

    /// @notice Given a balance, this function returns what portion of it belongs to the node taking into
    /// consideration the 8 ether reward threshold, the minipool's commission rate and any penalties it may have
    /// attracted. Another way of describing this function is that if this contract's balance was
    /// `_balance + nodeRefundBalance` this function would return how much of that balance would be paid to the node
    /// operator if a distribution occurred
    /// @param _balance The balance to calculate the node share of. Should exclude nodeRefundBalance
    function calculateNodeShare(uint256 _balance) override public view returns (uint256) {
        // Sub 8 ether balance is treated as rewards
        if (_balance < 8 ether) {
            return calculateNodeRewards(nodeDepositBalance, getUserDepositBalance(), _balance);
        } else {
            return _calculateNodeShare(_balance);
        }
    }

    /// @notice Performs the same calculation as `calculateNodeShare` but on the user side
    /// @param _balance The balance to calculate the node share of. Should exclude nodeRefundBalance
    function calculateUserShare(uint256 _balance) override external view returns (uint256) {
        // User's share is just the balance minus node refund minus node's share
        return _balance.sub(calculateNodeShare(_balance));
    }

    /// @dev Given a balance, this function returns what portion of it belongs to the node taking into
    /// consideration the minipool's commission rate and any penalties it may have attracted
    /// @param _balance The balance to calculate the node share of (with nodeRefundBalance already subtracted)
    function _calculateNodeShare(uint256 _balance) internal view returns (uint256) {
        uint256 userCapital = getUserDepositBalance();
        uint256 nodeCapital = nodeDepositBalance;
        uint256 nodeShare = 0;
        // Calculate the total capital (node + user)
        uint256 capital = userCapital.add(nodeCapital);
        if (_balance > capital) {
            // Total rewards to share
            uint256 rewards = _balance.sub(capital);
            nodeShare = nodeCapital.add(calculateNodeRewards(nodeCapital, userCapital, rewards));
        } else if (_balance > userCapital) {
            nodeShare = _balance.sub(userCapital);
        }
        // Check if node has an ETH penalty
        uint256 penaltyRate = RocketMinipoolPenaltyInterface(rocketMinipoolPenalty).getPenaltyRate(address(this));
        if (penaltyRate > 0) {
            uint256 penaltyAmount = nodeShare.mul(penaltyRate).div(calcBase);
            if (penaltyAmount > nodeShare) {
                penaltyAmount = nodeShare;
            }
            nodeShare = nodeShare.sub(penaltyAmount);
        }
        return nodeShare;
    }

    /// @dev Calculates what portion of rewards should be paid to the node operator given a capital ratio
    /// @param _nodeCapital The node supplied portion of the capital
    /// @param _userCapital The user supplied portion of the capital
    /// @param _rewards The amount of rewards to split
    function calculateNodeRewards(uint256 _nodeCapital, uint256 _userCapital, uint256 _rewards) internal view returns (uint256) {
        // Calculate node and user portion based on proportions of capital provided
        uint256 nodePortion = _rewards.mul(_nodeCapital).div(_userCapital.add(_nodeCapital));
        uint256 userPortion = _rewards.sub(nodePortion);
        // Calculate final node amount as combination of node capital, node share and commission on user share
        return nodePortion.add(userPortion.mul(nodeFee).div(calcBase));
    }

    /// @notice Dissolve the minipool, returning user deposited ETH to the deposit pool.
    function dissolve() override external onlyInitialised {
        // Check current status
        require(status == MinipoolStatus.Prelaunch, "The minipool can only be dissolved while in prelaunch");
        // Load contracts
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Check if minipool is timed out
        require(block.timestamp.sub(statusTime) >= rocketDAOProtocolSettingsMinipool.getLaunchTimeout(), "The minipool can only be dissolved once it has timed out");
        // Perform the dissolution
        _dissolve();
    }

    /// @notice Withdraw node balances from the minipool and close it. Only accepts calls from the owner
    function close() override external onlyMinipoolOwner(msg.sender) onlyInitialised {
        // Check current status
        require(status == MinipoolStatus.Dissolved, "The minipool can only be closed while dissolved");
        // Distribute funds to owner
        distributeToOwner();
        // Destroy minipool
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        require(rocketMinipoolManager.getMinipoolExists(address(this)), "Minipool already closed");
        rocketMinipoolManager.destroyMinipool();
        // Clear state
        nodeDepositBalance = 0;
        nodeRefundBalance = 0;
        userDepositBalance = 0;
        userDepositBalanceLegacy = 0;
        userDepositAssignedTime = 0;
    }

    /// @notice Can be called by trusted nodes to scrub this minipool if its withdrawal credentials are not set correctly
    function voteScrub() override external onlyInitialised {
        // Check current status
        require(status == MinipoolStatus.Prelaunch, "The minipool can only be scrubbed while in prelaunch");
        // Get contracts
        RocketDAONodeTrustedInterface rocketDAONode = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        RocketDAONodeTrustedSettingsMinipoolInterface rocketDAONodeTrustedSettingsMinipool = RocketDAONodeTrustedSettingsMinipoolInterface(getContractAddress("rocketDAONodeTrustedSettingsMinipool"));
        // Must be a trusted member
        require(rocketDAONode.getMemberIsValid(msg.sender), "Not a trusted member");
        // Can only vote once
        require(!memberScrubVotes[msg.sender], "Member has already voted to scrub");
        memberScrubVotes[msg.sender] = true;
        // Emit event
        emit ScrubVoted(msg.sender, block.timestamp);
        // Check if required quorum has voted
        uint256 quorum = rocketDAONode.getMemberCount().mul(rocketDAONodeTrustedSettingsMinipool.getScrubQuorum()).div(calcBase);
        if (totalScrubVotes.add(1) > quorum) {
            // Slash RPL equal to minimum stake amount (if enabled)
            if (!vacant && rocketDAONodeTrustedSettingsMinipool.getScrubPenaltyEnabled()){
                RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
                RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
                RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
                uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
                // Slash amount is minRplStake * userCapital
                // In prelaunch userDepositBalance hasn't been set so we calculate it as 32 ETH - bond amount
                rocketNodeStaking.slashRPL(
                    nodeAddress,
                        launchAmount.sub(nodeDepositBalance)
                        .mul(rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake())
                        .div(calcBase)
                );
            }
            // Dissolve this minipool, recycling ETH back to deposit pool
            _dissolve();
            // Emit event
            emit MinipoolScrubbed(block.timestamp);
        } else {
            // Increment total
            totalScrubVotes = totalScrubVotes.add(1);
        }
    }

    /// @notice Reduces the ETH bond amount and credits the owner the difference
    function reduceBondAmount() override external onlyMinipoolOwner(msg.sender) onlyInitialised {
        require(status == MinipoolStatus.Staking, "Minipool must be staking");
        // If balance is greater than 8 ether, it is assumed to be capital not skimmed rewards. So prevent reduction
        uint256 totalBalance = address(this).balance.sub(nodeRefundBalance);
        require(totalBalance < 8 ether, "Cannot reduce bond with balance of 8 ether or more");
        // Distribute any skimmed rewards
        distributeSkimmedRewards();
        // Approve reduction and handle external state changes
        RocketMinipoolBondReducerInterface rocketBondReducer = RocketMinipoolBondReducerInterface(getContractAddress("rocketMinipoolBondReducer"));
        uint256 previousBond = nodeDepositBalance;
        uint256 newBond = rocketBondReducer.reduceBondAmount();
        // Update user/node balances
        userDepositBalance = getUserDepositBalance().add(previousBond.sub(newBond));
        nodeDepositBalance = newBond;
        // Reset node fee to current network rate
        RocketNetworkFeesInterface rocketNetworkFees = RocketNetworkFeesInterface(getContractAddress("rocketNetworkFees"));
        uint256 prevFee = nodeFee;
        uint256 newFee = rocketNetworkFees.getNodeFee();
        nodeFee = newFee;
        // Update staking minipool counts and fee numerator
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        rocketMinipoolManager.updateNodeStakingMinipoolCount(previousBond, newBond, prevFee, newFee);
        // Break state to prevent rollback exploit
        if (depositType != MinipoolDeposit.Variable) {
            userDepositBalanceLegacy = 2 ** 256 - 1;
            depositType = MinipoolDeposit.Variable;
        }
        // Emit event
        emit BondReduced(previousBond, newBond, block.timestamp);
    }

    /// @dev Distributes the current contract balance based on capital ratio and node fee
    function distributeSkimmedRewards() internal {
        uint256 rewards = address(this).balance.sub(nodeRefundBalance);
        uint256 nodeShare = calculateNodeRewards(nodeDepositBalance, getUserDepositBalance(), rewards);
        // Pay node operator via refund mechanism
        nodeRefundBalance = nodeRefundBalance.add(nodeShare);
        // Deposit user share into rETH contract
        payable(rocketTokenRETH).transfer(rewards.sub(nodeShare));
    }

    /// @dev Set the minipool's current status
    /// @param _status The new status
    function setStatus(MinipoolStatus _status) private {
        // Update status
        status = _status;
        statusBlock = block.number;
        statusTime = block.timestamp;
        // Emit status updated event
        emit StatusUpdated(uint8(_status), block.timestamp);
    }

    /// @dev Transfer refunded ETH balance to the node operator
    function _refund() private {
        // Prevent vacant minipools from calling
        require(vacant == false, "Vacant minipool cannot refund");
        // Update refund balance
        uint256 refundAmount = nodeRefundBalance;
        nodeRefundBalance = 0;
        // Get node withdrawal address
        address nodeWithdrawalAddress = rocketStorage.getNodeWithdrawalAddress(nodeAddress);
        // Transfer refund amount
        (bool success,) = nodeWithdrawalAddress.call{value : refundAmount}("");
        require(success, "ETH refund amount was not successfully transferred to node operator");
        // Emit ether withdrawn event
        emit EtherWithdrawn(nodeWithdrawalAddress, refundAmount, block.timestamp);
    }

    /// @dev Slash node operator's RPL balance based on nodeSlashBalance
    function _slash() private {
        // Get contracts
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
        // Slash required amount and reset storage value
        uint256 slashAmount = nodeSlashBalance;
        nodeSlashBalance = 0;
        rocketNodeStaking.slashRPL(nodeAddress, slashAmount);
    }

    /// @dev Dissolve this minipool
    function _dissolve() private {
        // Get contracts
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        // Progress to dissolved
        setStatus(MinipoolStatus.Dissolved);
        if (vacant) {
            // Vacant minipools waiting to be promoted need to be removed from the set maintained by the minipool manager
            RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
            rocketMinipoolManager.removeVacantMinipool();
        } else {
            if (depositType == MinipoolDeposit.Full) {
                // Handle legacy Full type minipool
                rocketMinipoolQueue.removeMinipool(MinipoolDeposit.Full);
            } else {
                // Transfer user balance to deposit pool
                uint256 userCapital = getUserDepositBalance();
                rocketDepositPool.recycleDissolvedDeposit{value : userCapital}();
                // Emit ether withdrawn event
                emit EtherWithdrawn(address(rocketDepositPool), userCapital, block.timestamp);
            }
        }
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "../RocketBase.sol";
import "../../interface/minipool/RocketMinipoolBaseInterface.sol";
import "../../interface/minipool/RocketMinipoolFactoryInterface.sol";

/// @notice Performs CREATE2 deployment of minipool contracts
contract RocketMinipoolFactory is RocketBase, RocketMinipoolFactoryInterface {

    // Libs
    using SafeMath for uint;
    using Clones for address;

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 2;
    }

    /// @notice Returns the expected minipool address for a node operator given a user-defined salt
    /// @param _salt The salt used in minipool creation
    function getExpectedAddress(address _nodeOperator, uint256 _salt) external override view returns (address) {
        // Ensure rocketMinipoolBase is setAddress
        address rocketMinipoolBase = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketMinipoolBase")));
        // Calculate node specific salt value
        bytes32 salt = keccak256(abi.encodePacked(_nodeOperator, _salt));
        // Return expected address
        return rocketMinipoolBase.predictDeterministicAddress(salt, address(this));
    }

    /// @notice Performs a CREATE2 deployment of a minipool contract with given salt
    /// @param _nodeAddress Owning node operator's address
    /// @param _salt A salt used in determining minipool address
    function deployContract(address _nodeAddress, uint256 _salt) override external onlyLatestContract("rocketMinipoolFactory", address(this)) onlyLatestContract("rocketMinipoolManager", msg.sender) returns (address) {
        // Ensure rocketMinipoolBase is setAddress
        address rocketMinipoolBase = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketMinipoolBase")));
        require(rocketMinipoolBase != address(0));
        // Construct final salt
        bytes32 salt = keccak256(abi.encodePacked(_nodeAddress, _salt));
        // Deploy the minipool
        address proxy = rocketMinipoolBase.cloneDeterministic(salt);
        // Initialise the minipool storage
        RocketMinipoolBaseInterface(proxy).initialise(address(rocketStorage), _nodeAddress);
        // Return address
        return proxy;
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "./RocketMinipoolBase.sol";
import "../../types/MinipoolStatus.sol";
import "../../types/MinipoolDeposit.sol";
import "../../types/MinipoolDetails.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";
import "../../interface/util/AddressSetStorageInterface.sol";
import "../../interface/node/RocketNodeManagerInterface.sol";
import "../../interface/network/RocketNetworkPricesInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/minipool/RocketMinipoolFactoryInterface.sol";
import "../../interface/node/RocketNodeDistributorFactoryInterface.sol";
import "../../interface/node/RocketNodeDistributorInterface.sol";
import "../../interface/network/RocketNetworkPenaltiesInterface.sol";
import "../../interface/minipool/RocketMinipoolPenaltyInterface.sol";
import "../../interface/node/RocketNodeDepositInterface.sol";
import "./RocketMinipoolDelegate.sol";

/// @notice Minipool creation, removal and management
contract RocketMinipoolManager is RocketBase, RocketMinipoolManagerInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event MinipoolCreated(address indexed minipool, address indexed node, uint256 time);
    event MinipoolDestroyed(address indexed minipool, address indexed node, uint256 time);
    event BeginBondReduction(address indexed minipool, uint256 time);
    event CancelReductionVoted(address indexed minipool, address indexed member, uint256 time);
    event ReductionCancelled(address indexed minipool, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 3;
    }

    /// @notice Get the number of minipools in the network
    function getMinipoolCount() override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(bytes("minipools.index")));
    }

    /// @notice Get the number of minipools in the network in the Staking state
    function getStakingMinipoolCount() override public view returns (uint256) {
        return getUint(keccak256(bytes("minipools.staking.count")));
    }

    /// @notice Get the number of finalised minipools in the network
    function getFinalisedMinipoolCount() override external view returns (uint256) {
        return getUint(keccak256(bytes("minipools.finalised.count")));
    }

    /// @notice Get the number of active minipools in the network
    function getActiveMinipoolCount() override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        uint256 total = addressSetStorage.getCount(keccak256(bytes("minipools.index")));
        uint256 finalised = getUint(keccak256(bytes("minipools.finalised.count")));
        return total.sub(finalised);
    }

    /// @notice Returns true if a minipool has had an RPL slashing
    function getMinipoolRPLSlashed(address _minipoolAddress) override external view returns (bool) {
        return getBool(keccak256(abi.encodePacked("minipool.rpl.slashed", _minipoolAddress)));
    }

    /// @notice Get the number of minipools in each status.
    ///         Returns the counts for Initialised, Prelaunch, Staking, Withdrawable, and Dissolved in that order.
    /// @param _offset The offset into the minipool set to start
    /// @param _limit The maximum number of minipools to iterate
    function getMinipoolCountPerStatus(uint256 _offset, uint256 _limit) override external view
    returns (uint256 initialisedCount, uint256 prelaunchCount, uint256 stakingCount, uint256 withdrawableCount, uint256 dissolvedCount) {
        // Get contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Precompute minipool key
        bytes32 minipoolKey = keccak256(abi.encodePacked("minipools.index"));
        // Iterate over the requested minipool range
        uint256 totalMinipools = getMinipoolCount();
        uint256 max = _offset.add(_limit);
        if (max > totalMinipools || _limit == 0) { max = totalMinipools; }
        for (uint256 i = _offset; i < max; i++) {
            // Get the minipool at index i
            RocketMinipoolInterface minipool = RocketMinipoolInterface(addressSetStorage.getItem(minipoolKey, i));
            // Get the minipool's status, and update the appropriate counter
            MinipoolStatus status = minipool.getStatus();
            if (status == MinipoolStatus.Initialised) {
                initialisedCount++;
            }
            else if (status == MinipoolStatus.Prelaunch) {
                prelaunchCount++;
            }
            else if (status == MinipoolStatus.Staking) {
                stakingCount++;
            }
            else if (status == MinipoolStatus.Withdrawable) {
                withdrawableCount++;
            }
            else if (status == MinipoolStatus.Dissolved) {
                dissolvedCount++;
            }
        }
    }

    /// @notice Returns an array of all minipools in the prelaunch state
    /// @param _offset The offset into the minipool set to start iterating
    /// @param _limit The maximum number of minipools to iterate over
    function getPrelaunchMinipools(uint256 _offset, uint256 _limit) override external view
    returns (address[] memory) {
        // Get contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Precompute minipool key
        bytes32 minipoolKey = keccak256(abi.encodePacked("minipools.index"));
        // Iterate over the requested minipool range
        uint256 totalMinipools = getMinipoolCount();
        uint256 max = _offset.add(_limit);
        if (max > totalMinipools || _limit == 0) { max = totalMinipools; }
        // Create array big enough for every minipool
        address[] memory minipools = new address[](max.sub(_offset));
        uint256 total = 0;
        for (uint256 i = _offset; i < max; i++) {
            // Get the minipool at index i
            RocketMinipoolInterface minipool = RocketMinipoolInterface(addressSetStorage.getItem(minipoolKey, i));
            // Get the minipool's status, and to array if it's in prelaunch
            MinipoolStatus status = minipool.getStatus();
            if (status == MinipoolStatus.Prelaunch) {
                minipools[total] = address(minipool);
                total++;
            }
        }
        // Dirty hack to cut unused elements off end of return value
        assembly {
            mstore(minipools, total)
        }
        return minipools;
    }

    /// @notice Get a network minipool address by index
    /// @param _index Index into the minipool set to return
    function getMinipoolAt(uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("minipools.index")), _index);
    }

    /// @notice Get the number of minipools owned by a node
    /// @param _nodeAddress The node operator to query the count of minipools of
    function getNodeMinipoolCount(address _nodeAddress) override external view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)));
    }

    /// @notice Get the number of minipools owned by a node that are not finalised
    /// @param _nodeAddress The node operator to query the count of active minipools of
    function getNodeActiveMinipoolCount(address _nodeAddress) override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        uint256 finalised = getUint(keccak256(abi.encodePacked("node.minipools.finalised.count", _nodeAddress)));
        uint256 total = addressSetStorage.getCount(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)));
        return total.sub(finalised);
    }

    /// @notice Get the number of minipools owned by a node that are finalised
    /// @param _nodeAddress The node operator to query the count of finalised minipools of
    function getNodeFinalisedMinipoolCount(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("node.minipools.finalised.count", _nodeAddress)));
    }

    /// @notice Get the number of minipools owned by a node that are in staking status
    /// @param _nodeAddress The node operator to query the count of staking minipools of
    function getNodeStakingMinipoolCount(address _nodeAddress) override public view returns (uint256) {
        RocketNodeDepositInterface rocketNodeDeposit = RocketNodeDepositInterface(getContractAddress("rocketNodeDeposit"));
        // Get valid deposit amounts
        uint256[] memory depositSizes = rocketNodeDeposit.getDepositAmounts();
        uint256 total;
        for (uint256 i = 0; i < depositSizes.length; i++){
            total = total.add(getNodeStakingMinipoolCountBySize(_nodeAddress, depositSizes[i]));
        }
        return total;
    }

    /// @notice Get the number of minipools owned by a node that are in staking status
    /// @param _nodeAddress The node operator to query the count of minipools by desposit size of
    /// @param _depositSize The deposit size to filter result by
    function getNodeStakingMinipoolCountBySize(address _nodeAddress, uint256 _depositSize) override public view returns (uint256) {
        bytes32 nodeKey;
        if (_depositSize == 16 ether){
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress));
        } else {
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress, _depositSize));
        }
        return getUint(nodeKey);
    }

    /// @notice Get a node minipool address by index
    /// @param _nodeAddress The node operator to query the minipool of
    /// @param _index Index into the node operator's set of minipools
    function getNodeMinipoolAt(address _nodeAddress, uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)), _index);
    }

    /// @notice Get the number of validating minipools owned by a node
    /// @param _nodeAddress The node operator to query the count of validating minipools of
    function getNodeValidatingMinipoolCount(address _nodeAddress) override external view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("node.minipools.validating.index", _nodeAddress)));
    }

    /// @notice Get a validating node minipool address by index
    /// @param _nodeAddress The node operator to query the validating minipool of
    /// @param _index Index into the node operator's set of validating minipools
    function getNodeValidatingMinipoolAt(address _nodeAddress, uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("node.minipools.validating.index", _nodeAddress)), _index);
    }

    /// @notice Get a minipool address by validator pubkey
    /// @param _pubkey The pubkey to query
    function getMinipoolByPubkey(bytes memory _pubkey) override public view returns (address) {
        return getAddress(keccak256(abi.encodePacked("validator.minipool", _pubkey)));
    }

    /// @notice Returns true if a minipool exists
    /// @param _minipoolAddress The address of the minipool to check the existence of
    function getMinipoolExists(address _minipoolAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("minipool.exists", _minipoolAddress)));
    }

    /// @notice Returns true if a minipool previously existed at the given address
    /// @param _minipoolAddress The address to check the previous existence of a minipool at
    function getMinipoolDestroyed(address _minipoolAddress) override external view returns (bool) {
        return getBool(keccak256(abi.encodePacked("minipool.destroyed", _minipoolAddress)));
    }

    /// @notice Returns a minipool's validator pubkey
    /// @param _minipoolAddress The minipool to query the pubkey of
    function getMinipoolPubkey(address _minipoolAddress) override public view returns (bytes memory) {
        return getBytes(keccak256(abi.encodePacked("minipool.pubkey", _minipoolAddress)));
    }

    /// @notice Calculates what the withdrawal credentials of a minipool should be set to
    /// @param _minipoolAddress The minipool to calculate the withdrawal credentials for
    function getMinipoolWithdrawalCredentials(address _minipoolAddress) override public pure returns (bytes memory) {
        return abi.encodePacked(byte(0x01), bytes11(0x0), address(_minipoolAddress));
    }

    /// @notice Decrements a node operator's number of staking minipools based on the minipools prior bond amount and
    ///         increments it based on their new bond amount.
    /// @param _previousBond The minipool's previous bond value
    /// @param _newBond The minipool's new bond value
    /// @param _previousFee The fee of the minipool prior to the bond change
    /// @param _newFee The fee of the minipool after the bond change
    function updateNodeStakingMinipoolCount(uint256 _previousBond, uint256 _newBond, uint256 _previousFee, uint256 _newFee) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {
        bytes32 nodeKey;
        bytes32 numeratorKey;
        // Get contracts
        RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
        address nodeAddress = minipool.getNodeAddress();
        // Try to distribute current fees at previous average commission rate
        _tryDistribute(nodeAddress);
        // Decrement previous bond count
        if (_previousBond == 16 ether){
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", nodeAddress));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", nodeAddress));
        } else {
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", nodeAddress, _previousBond));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", nodeAddress, _previousBond));
        }
        subUint(nodeKey, 1);
        subUint(numeratorKey, _previousFee);
        // Increment new bond count
        if (_newBond == 16 ether){
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", nodeAddress));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", nodeAddress));
        } else {
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", nodeAddress, _newBond));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", nodeAddress, _newBond));
        }
        addUint(nodeKey, 1);
        addUint(numeratorKey, _newFee);
    }

    /// @dev Increments a node operator's number of staking minipools and calculates updated average node fee.
    ///      Must be called from the minipool itself as msg.sender is used to query the minipool's node fee
    /// @param _nodeAddress The node address to increment the number of staking minipools of
    function incrementNodeStakingMinipoolCount(address _nodeAddress) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {
        // Get contracts
        RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
        // Try to distribute current fees at previous average commission rate
        _tryDistribute(_nodeAddress);
        // Update the node specific count
        uint256 depositSize = minipool.getNodeDepositBalance();
        bytes32 nodeKey;
        bytes32 numeratorKey;
        if (depositSize == 16 ether){
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", _nodeAddress));
        } else {
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress, depositSize));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", _nodeAddress, depositSize));
        }
        uint256 nodeValue = getUint(nodeKey);
        setUint(nodeKey, nodeValue.add(1));
        // Update the total count
        bytes32 totalKey = keccak256(abi.encodePacked("minipools.staking.count"));
        uint256 totalValue = getUint(totalKey);
        setUint(totalKey, totalValue.add(1));
        // Update node fee average
        addUint(numeratorKey, minipool.getNodeFee());
    }

    /// @dev Decrements a node operator's number of minipools in staking status and calculates updated average node fee.
    ///      Must be called from the minipool itself as msg.sender is used to query the minipool's node fee
    /// @param _nodeAddress The node address to decrement the number of staking minipools of
    function decrementNodeStakingMinipoolCount(address _nodeAddress) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {
        // Get contracts
        RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
        // Try to distribute current fees at previous average commission rate
        _tryDistribute(_nodeAddress);
        // Update the node specific count
        uint256 depositSize = minipool.getNodeDepositBalance();
        bytes32 nodeKey;
        bytes32 numeratorKey;
        if (depositSize == 16 ether){
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", _nodeAddress));
        } else {
            nodeKey = keccak256(abi.encodePacked("node.minipools.staking.count", _nodeAddress, depositSize));
            numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", _nodeAddress, depositSize));
        }
        uint256 nodeValue = getUint(nodeKey);
        setUint(nodeKey, nodeValue.sub(1));
        // Update the total count
        bytes32 totalKey = keccak256(abi.encodePacked("minipools.staking.count"));
        uint256 totalValue = getUint(totalKey);
        setUint(totalKey, totalValue.sub(1));
        // Update node fee average
        subUint(numeratorKey, minipool.getNodeFee());
    }

    /// @dev Calls distribute on the given node's distributor if it has a balance and has been initialised
    /// @param _nodeAddress The node operator to try distribute rewards for
    function _tryDistribute(address _nodeAddress) internal {
        // Get contracts
        RocketNodeDistributorFactoryInterface rocketNodeDistributorFactory = RocketNodeDistributorFactoryInterface(getContractAddress("rocketNodeDistributorFactory"));
        address distributorAddress = rocketNodeDistributorFactory.getProxyAddress(_nodeAddress);
        // If there are funds to distribute than call distribute
        if (distributorAddress.balance > 0) {
            // Get contracts
            RocketNodeManagerInterface rocketNodeManager = RocketNodeManagerInterface(getContractAddress("rocketNodeManager"));
            // Ensure distributor has been initialised
            require(rocketNodeManager.getFeeDistributorInitialised(_nodeAddress), "Distributor not initialised");
            RocketNodeDistributorInterface distributor = RocketNodeDistributorInterface(distributorAddress);
            distributor.distribute();
        }
    }

    /// @dev Increments a node operator's number of minipools that have been finalised
    /// @param _nodeAddress The node operator to increment finalised minipool count for
    function incrementNodeFinalisedMinipoolCount(address _nodeAddress) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {
        // Update the node specific count
        addUint(keccak256(abi.encodePacked("node.minipools.finalised.count", _nodeAddress)), 1);
        // Update the total count
        addUint(keccak256(bytes("minipools.finalised.count")), 1);
        // Update ETH matched
        uint256 ethMatched = getUint(keccak256(abi.encodePacked("eth.matched.node.amount", _nodeAddress)));
        if (ethMatched == 0) {
            ethMatched = getNodeActiveMinipoolCount(_nodeAddress).mul(16 ether);
        } else {
            RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
            ethMatched = ethMatched.sub(minipool.getUserDepositBalance());
        }
        setUint(keccak256(abi.encodePacked("eth.matched.node.amount", _nodeAddress)), ethMatched);
    }

    /// @dev Create a minipool. Only accepts calls from the RocketNodeDeposit contract
    /// @param _nodeAddress The owning node operator's address
    /// @param _salt A salt used in determining the minipool's address
    function createMinipool(address _nodeAddress, uint256 _salt) override public onlyLatestContract("rocketMinipoolManager", address(this)) onlyLatestContract("rocketNodeDeposit", msg.sender) returns (RocketMinipoolInterface) {
        // Load contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Check node minipool limit based on RPL stake
        { // Local scope to prevent stack too deep error
          RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
          // Check global minipool limit
          uint256 totalMinipoolCount = getActiveMinipoolCount();
          require(totalMinipoolCount.add(1) <= rocketDAOProtocolSettingsMinipool.getMaximumCount(), "Global minipool limit reached");
        }
        // Create minipool contract
        address contractAddress = deployContract(_nodeAddress, _salt);
        // Initialise minipool data
        setBool(keccak256(abi.encodePacked("minipool.exists", contractAddress)), true);
        // Add minipool to indexes
        addressSetStorage.addItem(keccak256(abi.encodePacked("minipools.index")), contractAddress);
        addressSetStorage.addItem(keccak256(abi.encodePacked("node.minipools.index", _nodeAddress)), contractAddress);
        // Emit minipool created event
        emit MinipoolCreated(contractAddress, _nodeAddress, block.timestamp);
        // Return created minipool address
        return RocketMinipoolInterface(contractAddress);
    }

    /// @notice Creates a vacant minipool that can be promoted by changing the given validator's withdrawal credentials
    /// @param _nodeAddress Address of the owning node operator
    /// @param _salt A salt used in determining the minipool's address
    /// @param _validatorPubkey A validator pubkey that the node operator intends to migrate the withdrawal credentials of
    /// @param _bondAmount The bond amount selected by the node operator
    /// @param _currentBalance The current balance of the validator on the beaconchain (will be checked by oDAO and scrubbed if not correct)
    function createVacantMinipool(address _nodeAddress, uint256 _salt, bytes calldata _validatorPubkey, uint256 _bondAmount, uint256 _currentBalance) override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyLatestContract("rocketNodeDeposit", msg.sender) returns (RocketMinipoolInterface) {
        // Get contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Create the minipool
        RocketMinipoolInterface minipool = createMinipool(_nodeAddress, _salt);
        // Prepare the minipool
        minipool.prepareVacancy(_bondAmount, _currentBalance);
        // Set the minipool's validator pubkey
        _setMinipoolPubkey(address(minipool), _validatorPubkey);
        // Add minipool to the vacant set
        addressSetStorage.addItem(keccak256(abi.encodePacked("minipools.vacant.index")), address(minipool));
        // Return
        return minipool;
    }

    /// @dev Called by minipool to remove from vacant set on promotion or dissolution
    function removeVacantMinipool() override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {
        // Remove from vacant set
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        addressSetStorage.removeItem(keccak256(abi.encodePacked("minipools.vacant.index")), msg.sender);
        // Remove mapping of pubkey to minipool to allow NO to try again in future
        bytes memory pubkey = getMinipoolPubkey(msg.sender);
        deleteAddress(keccak256(abi.encodePacked("validator.minipool", pubkey)));
    }

    /// @notice Returns the number of minipools in the vacant minipool set
    function getVacantMinipoolCount() override external view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("minipools.vacant.index")));
    }

    /// @notice Returns the vacant minipool at a given index
    /// @param _index The index into the vacant minipool set to retrieve
    function getVacantMinipoolAt(uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("minipools.vacant.index")), _index);
    }

    /// @dev Destroy a minipool cleaning up all relevant state. Only accepts calls from registered minipools
    function destroyMinipool() override external onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {
        // Load contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Initialize minipool & get properties
        RocketMinipoolInterface minipool = RocketMinipoolInterface(msg.sender);
        address nodeAddress = minipool.getNodeAddress();
        // Update ETH matched
        uint256 ethMatched = getUint(keccak256(abi.encodePacked("eth.matched.node.amount", nodeAddress)));
        if (ethMatched == 0) {
            ethMatched = getNodeActiveMinipoolCount(nodeAddress).mul(16 ether);
        }
        // Handle legacy minipools
        if (minipool.getDepositType() == MinipoolDeposit.Variable) {
            ethMatched = ethMatched.sub(minipool.getUserDepositBalance());
        } else {
            ethMatched = ethMatched.sub(16 ether);
        }
        setUint(keccak256(abi.encodePacked("eth.matched.node.amount", nodeAddress)), ethMatched);
        // Update minipool data
        setBool(keccak256(abi.encodePacked("minipool.exists", msg.sender)), false);
        // Record minipool as destroyed to prevent recreation at same address
        setBool(keccak256(abi.encodePacked("minipool.destroyed", msg.sender)), true);
        // Remove minipool from indexes
        addressSetStorage.removeItem(keccak256(abi.encodePacked("minipools.index")), msg.sender);
        addressSetStorage.removeItem(keccak256(abi.encodePacked("node.minipools.index", nodeAddress)), msg.sender);
        // Clean up pubkey state
        bytes memory pubkey = getMinipoolPubkey(msg.sender);
        deleteBytes(keccak256(abi.encodePacked("minipool.pubkey", msg.sender)));
        deleteAddress(keccak256(abi.encodePacked("validator.minipool", pubkey)));
        // Emit minipool destroyed event
        emit MinipoolDestroyed(msg.sender, nodeAddress, block.timestamp);
    }

    /// @dev Set a minipool's validator pubkey. Only accepts calls from registered minipools
    /// @param _pubkey The pubkey to set for the calling minipool
    function setMinipoolPubkey(bytes calldata _pubkey) override public onlyLatestContract("rocketMinipoolManager", address(this)) onlyRegisteredMinipool(msg.sender) {
        _setMinipoolPubkey(msg.sender, _pubkey);
    }

    /// @dev Internal logic to set a minipool's pubkey, reverts if pubkey already set
    /// @param _pubkey The pubkey to set for the calling minipool
    function _setMinipoolPubkey(address _minipool, bytes calldata _pubkey) private {
        // Check validator pubkey is not in use
        require(getMinipoolByPubkey(_pubkey) == address(0x0), "Validator pubkey is in use");
        // Load contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Initialise minipool & get properties
        RocketMinipoolInterface minipool = RocketMinipoolInterface(_minipool);
        address nodeAddress = minipool.getNodeAddress();
        // Set minipool validator pubkey & validator minipool address
        setBytes(keccak256(abi.encodePacked("minipool.pubkey", _minipool)), _pubkey);
        setAddress(keccak256(abi.encodePacked("validator.minipool", _pubkey)), _minipool);
        // Add minipool to node validating minipools index
        addressSetStorage.addItem(keccak256(abi.encodePacked("node.minipools.validating.index", nodeAddress)), _minipool);
    }

    /// @notice Retrieves all on-chain information about a given minipool in a single convenience view function
    /// @param _minipoolAddress The address of the minipool to query details about
    function getMinipoolDetails(address _minipoolAddress) override public view returns (MinipoolDetails memory) {
        // Get contracts
        RocketMinipoolInterface minipoolInterface = RocketMinipoolInterface(_minipoolAddress);
        RocketMinipoolBase minipool = RocketMinipoolBase(payable(_minipoolAddress));
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketNetworkPenaltiesInterface rocketNetworkPenalties = RocketNetworkPenaltiesInterface(getContractAddress("rocketNetworkPenalties"));
        RocketMinipoolPenaltyInterface rocketMinipoolPenalty = RocketMinipoolPenaltyInterface(getContractAddress("rocketMinipoolPenalty"));
        // Minipool details
        MinipoolDetails memory details;
        details.nodeAddress = minipoolInterface.getNodeAddress();
        details.exists = rocketMinipoolManager.getMinipoolExists(_minipoolAddress);
        details.minipoolAddress = _minipoolAddress;
        details.pubkey = rocketMinipoolManager.getMinipoolPubkey(_minipoolAddress);
        details.status = minipoolInterface.getStatus();
        details.statusBlock = minipoolInterface.getStatusBlock();
        details.statusTime = minipoolInterface.getStatusTime();
        details.finalised = minipoolInterface.getFinalised();
        details.depositType = minipoolInterface.getDepositType();
        details.nodeFee = minipoolInterface.getNodeFee();
        details.nodeDepositBalance = minipoolInterface.getNodeDepositBalance();
        details.nodeDepositAssigned = minipoolInterface.getNodeDepositAssigned();
        details.userDepositBalance = minipoolInterface.getUserDepositBalance();
        details.userDepositAssigned = minipoolInterface.getUserDepositAssigned();
        details.userDepositAssignedTime = minipoolInterface.getUserDepositAssignedTime();
        // Delegate details
        details.useLatestDelegate = minipool.getUseLatestDelegate();
        details.delegate = minipool.getDelegate();
        details.previousDelegate = minipool.getPreviousDelegate();
        details.effectiveDelegate = minipool.getEffectiveDelegate();
        // Penalty details
        details.penaltyCount = rocketNetworkPenalties.getPenaltyCount(_minipoolAddress);
        details.penaltyRate = rocketMinipoolPenalty.getPenaltyRate(_minipoolAddress);
        return details;
    }

    /// @dev Wrapper around minipool getDepositType which handles backwards compatibility with v1 and v2 delegates
    /// @param _minipoolAddress Minipool address to get the deposit type of
    function getMinipoolDepositType(address _minipoolAddress) external override view returns (MinipoolDeposit) {
        RocketMinipoolInterface minipoolInterface = RocketMinipoolInterface(_minipoolAddress);
        uint8 version = minipoolInterface.version();

        if (version == 1 || version == 2) {
            try minipoolInterface.getDepositType{gas: 30000}() returns (MinipoolDeposit depositType) {
                return depositType;
            } catch (bytes memory /*lowLevelData*/) {
                return MinipoolDeposit.Variable;
            }
        }
        return minipoolInterface.getDepositType();
    }

    /// @dev Performs a CREATE2 deployment of a minipool contract with given salt
    /// @param _nodeAddress The owning node operator's address
    /// @param _salt A salt used in determining the minipool's address
    function deployContract(address _nodeAddress, uint256 _salt) private returns (address) {
        RocketMinipoolFactoryInterface rocketMinipoolFactory = RocketMinipoolFactoryInterface(getContractAddress("rocketMinipoolFactory"));
        return rocketMinipoolFactory.deployContract(_nodeAddress, _salt);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/minipool/RocketMinipoolPenaltyInterface.sol";

// Non-upgradable contract which gives guardian control over maximum penalty rates

contract RocketMinipoolPenalty is RocketBase, RocketMinipoolPenaltyInterface {

    // Events
    event MaxPenaltyRateUpdated(uint256 rate, uint256 time);

    // Libs
    using SafeMath for uint;

    // Storage (purposefully does not use RocketStorage to prevent oDAO from having power over this feature)
    uint256 maxPenaltyRate = 0 ether;                     // The most the oDAO is allowed to penalty a minipool (as a percentage)

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
    }

    // Get/set the current max penalty rate
    function setMaxPenaltyRate(uint256 _rate) external override onlyGuardian {
        // Update rate
        maxPenaltyRate = _rate;
        // Emit event
        emit MaxPenaltyRateUpdated(_rate, block.timestamp);
    }
    function getMaxPenaltyRate() external override view returns (uint256) {
        return maxPenaltyRate;
    }

    // Retrieves the amount to penalty a minipool
    function getPenaltyRate(address _minipoolAddress) external override view returns(uint256) {
        // Quick out which avoids a call to RocketStorage
        if (maxPenaltyRate == 0) {
             return 0;
        }
        // Retrieve penalty rate for this minipool
        uint256 penaltyRate = getUint(keccak256(abi.encodePacked("minipool.penalty.rate", _minipoolAddress)));
        // min(maxPenaltyRate, penaltyRate)
        if (penaltyRate > maxPenaltyRate) {
            return maxPenaltyRate;
        }
        return penaltyRate;
    }

    // Sets the penalty rate for the given minipool
    function setPenaltyRate(address _minipoolAddress, uint256 _rate) external override onlyLatestNetworkContract {
        setUint(keccak256(abi.encodePacked("minipool.penalty.rate", _minipoolAddress)), _rate);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

import "../RocketBase.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/util/AddressQueueStorageInterface.sol";
import "../../types/MinipoolDeposit.sol";

/// @notice Minipool queueing for deposit assignment
contract RocketMinipoolQueue is RocketBase, RocketMinipoolQueueInterface {

    // Libs
    using SafeMath for uint;
    using SignedSafeMath for int;

    // Constants
    bytes32 private constant queueKeyFull = keccak256("minipools.available.full");
    bytes32 private constant queueKeyHalf = keccak256("minipools.available.half");
    bytes32 private constant queueKeyVariable = keccak256("minipools.available.variable");

    // Events
    event MinipoolEnqueued(address indexed minipool, bytes32 indexed queueId, uint256 time);
    event MinipoolDequeued(address indexed minipool, bytes32 indexed queueId, uint256 time);
    event MinipoolRemoved(address indexed minipool, bytes32 indexed queueId, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 2;
    }

    /// @notice Get the total combined length of the queues
    function getTotalLength() override external view returns (uint256) {
        return (
            getLengthLegacy(queueKeyFull)
        ).add(
            getLengthLegacy(queueKeyHalf)
        ).add(
            getLength()
        );
    }

    /// @notice Returns true if there are any legacy minipools in the queue
    function getContainsLegacy() override external view returns (bool) {
        return getLengthLegacy(queueKeyFull).add(getLengthLegacy(queueKeyHalf)) > 0;
    }

    /// @notice Get the length of a given queue. Returns 0 for invalid queues
    /// @param _depositType Which queue to query the length of
    function getLengthLegacy(MinipoolDeposit _depositType) override external view returns (uint256) {
        if (_depositType == MinipoolDeposit.Full) { return getLengthLegacy(queueKeyFull); }
        if (_depositType == MinipoolDeposit.Half) { return getLengthLegacy(queueKeyHalf); }
        return 0;
    }

    /// @dev Returns a queue length by internal key representation
    /// @param _key The internal key representation of the queue to query the length of
    function getLengthLegacy(bytes32 _key) private view returns (uint256) {
        AddressQueueStorageInterface addressQueueStorage = AddressQueueStorageInterface(getContractAddress("addressQueueStorage"));
        return addressQueueStorage.getLength(_key);
    }

    /// @notice Gets the length of the variable (global) queue
    function getLength() override public view returns (uint256) {
        AddressQueueStorageInterface addressQueueStorage = AddressQueueStorageInterface(getContractAddress("addressQueueStorage"));
        return addressQueueStorage.getLength(queueKeyVariable);
    }

    /// @notice Get the total combined capacity of the queues
    function getTotalCapacity() override external view returns (uint256) {
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        return (
            getLengthLegacy(queueKeyFull).mul(rocketDAOProtocolSettingsMinipool.getFullDepositUserAmount())
        ).add(
            getLengthLegacy(queueKeyHalf).mul(rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount())
        ).add(
            getVariableCapacity()
        );
    }

    /// @notice Get the total effective capacity of the queues (used in node demand calculation)
    function getEffectiveCapacity() override external view returns (uint256) {
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        return (
            getLengthLegacy(queueKeyFull).mul(rocketDAOProtocolSettingsMinipool.getFullDepositUserAmount())
        ).add(
            getLengthLegacy(queueKeyHalf).mul(rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount())
        ).add(
            getVariableCapacity()
        );
    }

    /// @dev Get the ETH capacity of the variable queue
    function getVariableCapacity() internal view returns (uint256) {
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        return getLength().mul(rocketDAOProtocolSettingsMinipool.getVariableDepositAmount());
    }

    /// @notice Get the capacity of the next available minipool. Returns 0 if no minipools are available
    function getNextCapacityLegacy() override external view returns (uint256) {
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        if (getLengthLegacy(queueKeyHalf) > 0) { return rocketDAOProtocolSettingsMinipool.getHalfDepositUserAmount(); }
        if (getLengthLegacy(queueKeyFull) > 0) { return rocketDAOProtocolSettingsMinipool.getFullDepositUserAmount(); }
        return 0;
    }

    /// @notice Get the deposit type of the next available minipool and the number of deposits in that queue.
    ///         Returns None if no minipools are available
    function getNextDepositLegacy() override external view returns (MinipoolDeposit, uint256) {
        uint256 length = getLengthLegacy(queueKeyHalf);
        if (length > 0) { return (MinipoolDeposit.Half, length); }
        length = getLengthLegacy(queueKeyFull);
        if (length > 0) { return (MinipoolDeposit.Full, length); }
        return (MinipoolDeposit.None, 0);
    }

    /// @dev Add a minipool to the end of the appropriate queue. Only accepts calls from the RocketMinipoolManager contract
    /// @param _minipool Address of the minipool to add to the queue
    function enqueueMinipool(address _minipool) override external onlyLatestContract("rocketMinipoolQueue", address(this)) onlyLatestContract("rocketNodeDeposit", msg.sender) {
        // Enqueue
        AddressQueueStorageInterface addressQueueStorage = AddressQueueStorageInterface(getContractAddress("addressQueueStorage"));
        addressQueueStorage.enqueueItem(queueKeyVariable, _minipool);
        // Emit enqueued event
        emit MinipoolEnqueued(_minipool, queueKeyVariable, block.timestamp);
    }

    /// @dev Dequeues a minipool from a legacy queue
    /// @param _depositType The queue to dequeue a minipool from
    function dequeueMinipoolByDepositLegacy(MinipoolDeposit _depositType) override external onlyLatestContract("rocketMinipoolQueue", address(this)) onlyLatestContract("rocketDepositPool", msg.sender) returns (address minipoolAddress) {
        if (_depositType == MinipoolDeposit.Half) { return dequeueMinipool(queueKeyHalf); }
        if (_depositType == MinipoolDeposit.Full) { return dequeueMinipool(queueKeyFull); }
        require(false, "No minipools are available");
    }

    /// @dev Dequeues multiple minipools from the variable queue and returns them all
    /// @param _maxToDequeue The maximum number of items to dequeue
    function dequeueMinipools(uint256 _maxToDequeue) override external onlyLatestContract("rocketMinipoolQueue", address(this)) onlyLatestContract("rocketDepositPool", msg.sender) returns (address[] memory minipoolAddress) {
        uint256 queueLength = getLength();
        uint256 count = _maxToDequeue;
        if (count > queueLength) {
            count = queueLength;
        }
        address[] memory minipoolAddresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            RocketMinipoolInterface minipool = RocketMinipoolInterface(dequeueMinipool(queueKeyVariable));
            minipoolAddresses[i] = address(minipool);
        }
        return minipoolAddresses;
    }

    /// @dev Dequeues a minipool from a queue given an internal key
    /// @param _key The internal key representation of the queue from which to dequeue a minipool from
    function dequeueMinipool(bytes32 _key) private returns (address) {
        // Dequeue
        AddressQueueStorageInterface addressQueueStorage = AddressQueueStorageInterface(getContractAddress("addressQueueStorage"));
        address minipool = addressQueueStorage.dequeueItem(_key);
        // Emit dequeued event
        emit MinipoolDequeued(minipool, _key, block.timestamp);
        // Return
        return minipool;
    }

    /// @dev Remove a minipool from a queue. Only accepts calls from registered minipools
    function removeMinipool(MinipoolDeposit _depositType) override external onlyLatestContract("rocketMinipoolQueue", address(this)) onlyRegisteredMinipool(msg.sender) {
        // Remove minipool from queue
        if (_depositType == MinipoolDeposit.Half) { return removeMinipool(queueKeyHalf, msg.sender); }
        if (_depositType == MinipoolDeposit.Full) { return removeMinipool(queueKeyFull, msg.sender); }
        if (_depositType == MinipoolDeposit.Variable) { return removeMinipool(queueKeyVariable, msg.sender); }
        require(false, "Invalid minipool deposit type");
    }

    /// @dev Removes a minipool from a queue given an internal key
    /// @param _key The internal key representation of the queue from which to remove a minipool from
    /// @param _minipool The address of a minipool to remove from the specified queue
    function removeMinipool(bytes32 _key, address _minipool) private {
        // Remove
        AddressQueueStorageInterface addressQueueStorage = AddressQueueStorageInterface(getContractAddress("addressQueueStorage"));
        addressQueueStorage.removeItem(_key, _minipool);
        // Emit removed event
        emit MinipoolRemoved(_minipool, _key, block.timestamp);
    }

    /// @notice Returns the minipool address of the minipool in the global queue at a given index
    /// @param _index The index into the queue to retrieve
    function getMinipoolAt(uint256 _index) override external view returns(address) {
        AddressQueueStorageInterface addressQueueStorage = AddressQueueStorageInterface(getContractAddress("addressQueueStorage"));

        // Check if index is in the half queue
        uint256 halfLength = addressQueueStorage.getLength(queueKeyHalf);
        if (_index < halfLength) {
            return addressQueueStorage.getItem(queueKeyHalf, _index);
        }
        _index = _index.sub(halfLength);

        // Check if index is in the full queue
        uint256 fullLength = addressQueueStorage.getLength(queueKeyFull);
        if (_index < fullLength) {
            return addressQueueStorage.getItem(queueKeyFull, _index);
        }
        _index = _index.sub(fullLength);

        // Check if index is in the full queue
        uint256 variableLength = addressQueueStorage.getLength(queueKeyVariable);
        if (_index < variableLength) {
            return addressQueueStorage.getItem(queueKeyVariable, _index);
        }

        // Index is out of bounds
        return address(0);
    }

    /// @notice Returns the position a given minipool is in the queue
    /// @param _minipool The minipool to query the position of
    function getMinipoolPosition(address _minipool) override external view returns (int256) {
        AddressQueueStorageInterface addressQueueStorage = AddressQueueStorageInterface(getContractAddress("addressQueueStorage"));
        int256 position;

        // Check in half queue
        position = addressQueueStorage.getIndexOf(queueKeyHalf, _minipool);
        if (position != -1) {
            return position;
        }
        int256 offset = SafeCast.toInt256(addressQueueStorage.getLength(queueKeyHalf));

        // Check in full queue
        position = addressQueueStorage.getIndexOf(queueKeyFull, _minipool);
        if (position != -1) {
            return offset.add(position);
        }
        offset = offset.add(SafeCast.toInt256(addressQueueStorage.getLength(queueKeyFull)));

        // Check in variable queue
        position = addressQueueStorage.getIndexOf(queueKeyVariable, _minipool);
        if (position != -1) {
            return offset.add(position);
        }

        // Isn't in the queue
        return -1;
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../../interface/RocketStorageInterface.sol";
import "../../types/MinipoolDeposit.sol";
import "../../types/MinipoolStatus.sol";

// The RocketMinipool contract storage layout, shared by RocketMinipoolDelegate

// ******************************************************
// Note: This contract MUST NOT BE UPDATED after launch.
// All deployed minipool contracts must maintain a
// Consistent storage layout with RocketMinipoolDelegate.
// ******************************************************

abstract contract RocketMinipoolStorageLayout {
    // Storage state enum
    enum StorageState {
        Undefined,
        Uninitialised,
        Initialised
    }

	// Main Rocket Pool storage contract
    RocketStorageInterface internal rocketStorage = RocketStorageInterface(0);

    // Status
    MinipoolStatus internal status;
    uint256 internal statusBlock;
    uint256 internal statusTime;
    uint256 internal withdrawalBlock;

    // Deposit type
    MinipoolDeposit internal depositType;

    // Node details
    address internal nodeAddress;
    uint256 internal nodeFee;
    uint256 internal nodeDepositBalance;
    bool internal nodeDepositAssigned;          // NO LONGER IN USE
    uint256 internal nodeRefundBalance;
    uint256 internal nodeSlashBalance;

    // User deposit details
    uint256 internal userDepositBalanceLegacy;
    uint256 internal userDepositAssignedTime;

    // Upgrade options
    bool internal useLatestDelegate = false;
    address internal rocketMinipoolDelegate;
    address internal rocketMinipoolDelegatePrev;

    // Local copy of RETH address
    address internal rocketTokenRETH;

    // Local copy of penalty contract
    address internal rocketMinipoolPenalty;

    // Used to prevent direct access to delegate and prevent calling initialise more than once
    StorageState internal storageState = StorageState.Undefined;

    // Whether node operator has finalised the pool
    bool internal finalised;

    // Trusted member scrub votes
    mapping(address => bool) internal memberScrubVotes;
    uint256 internal totalScrubVotes;

    // Variable minipool
    uint256 internal preLaunchValue;
    uint256 internal userDepositBalance;

    // Vacant minipool
    bool internal vacant;
    uint256 internal preMigrationBalance;

    // User distribution
    bool internal userDistributed;
    uint256 internal userDistributeTime;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/network/RocketNetworkBalancesInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";

// Network balances

contract RocketNetworkBalances is RocketBase, RocketNetworkBalancesInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event BalancesSubmitted(address indexed from, uint256 block, uint256 totalEth, uint256 stakingEth, uint256 rethSupply, uint256 time);
    event BalancesUpdated(uint256 block, uint256 totalEth, uint256 stakingEth, uint256 rethSupply, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 2;
    }

    // The block number which balances are current for
    function getBalancesBlock() override public view returns (uint256) {
        return getUint(keccak256("network.balances.updated.block"));
    }
    function setBalancesBlock(uint256 _value) private {
        setUint(keccak256("network.balances.updated.block"), _value);
    }

    // The current RP network total ETH balance
    function getTotalETHBalance() override public view returns (uint256) {
        return getUint(keccak256("network.balance.total"));
    }
    function setTotalETHBalance(uint256 _value) private {
        setUint(keccak256("network.balance.total"), _value);
    }

    // The current RP network staking ETH balance
    function getStakingETHBalance() override public view returns (uint256) {
        return getUint(keccak256("network.balance.staking"));
    }
    function setStakingETHBalance(uint256 _value) private {
        setUint(keccak256("network.balance.staking"), _value);
    }

    // The current RP network total rETH supply
    function getTotalRETHSupply() override external view returns (uint256) {
        return getUint(keccak256("network.balance.reth.supply"));
    }
    function setTotalRETHSupply(uint256 _value) private {
        setUint(keccak256("network.balance.reth.supply"), _value);
    }

    // Get the current RP network ETH utilization rate as a fraction of 1 ETH
    // Represents what % of the network's balance is actively earning rewards
    function getETHUtilizationRate() override external view returns (uint256) {
        uint256 totalEthBalance = getTotalETHBalance();
        uint256 stakingEthBalance = getStakingETHBalance();
        if (totalEthBalance == 0) { return calcBase; }
        return calcBase.mul(stakingEthBalance).div(totalEthBalance);
    }

    // Submit network balances for a block
    // Only accepts calls from trusted (oracle) nodes
    function submitBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _rethSupply) override external onlyLatestContract("rocketNetworkBalances", address(this)) onlyTrustedNode(msg.sender) {
        // Check settings
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        require(rocketDAOProtocolSettingsNetwork.getSubmitBalancesEnabled(), "Submitting balances is currently disabled");
        // Check block
        require(_block < block.number, "Balances can not be submitted for a future block");
        require(_block > getBalancesBlock(), "Network balances for an equal or higher block are set");
        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(abi.encodePacked("network.balances.submitted.node", msg.sender, _block, _totalEth, _stakingEth, _rethSupply));
        bytes32 submissionCountKey = keccak256(abi.encodePacked("network.balances.submitted.count", _block, _totalEth, _stakingEth, _rethSupply));
        // Check & update node submission status
        require(!getBool(nodeSubmissionKey), "Duplicate submission from node");
        setBool(nodeSubmissionKey, true);
        setBool(keccak256(abi.encodePacked("network.balances.submitted.node", msg.sender, _block)), true);
        // Increment submission count
        uint256 submissionCount = getUint(submissionCountKey).add(1);
        setUint(submissionCountKey, submissionCount);
        // Emit balances submitted event
        emit BalancesSubmitted(msg.sender, _block, _totalEth, _stakingEth, _rethSupply, block.timestamp);
        // Check submission count & update network balances
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        if (calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodeConsensusThreshold()) {
            updateBalances(_block, _totalEth, _stakingEth, _rethSupply);
        }
    }

    // Executes updateBalances if consensus threshold is reached
    function executeUpdateBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _rethSupply) override external onlyLatestContract("rocketNetworkBalances", address(this)) {
        // Check settings
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        require(rocketDAOProtocolSettingsNetwork.getSubmitBalancesEnabled(), "Submitting balances is currently disabled");
        // Check block
        require(_block < block.number, "Balances can not be submitted for a future block");
        require(_block > getBalancesBlock(), "Network balances for an equal or higher block are set");
        // Check balances
        require(_stakingEth <= _totalEth, "Invalid network balances");
        // Get submission keys
        bytes32 submissionCountKey = keccak256(abi.encodePacked("network.balances.submitted.count", _block, _totalEth, _stakingEth, _rethSupply));
        // Get submission count
        uint256 submissionCount = getUint(submissionCountKey);
        // Check submission count & update network balances
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        require(calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodeConsensusThreshold(), "Consensus has not been reached");
        updateBalances(_block, _totalEth, _stakingEth, _rethSupply);
    }

    // Update network balances
    function updateBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _rethSupply) private {
        // Update balances
        setBalancesBlock(_block);
        setTotalETHBalance(_totalEth);
        setStakingETHBalance(_stakingEth);
        setTotalRETHSupply(_rethSupply);
        // Emit balances updated event
        emit BalancesUpdated(_block, _totalEth, _stakingEth, _rethSupply, block.timestamp);
    }

    // Returns the latest block number that oracles should be reporting balances for
    function getLatestReportableBlock() override external view returns (uint256) {
        // Load contracts
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        // Get the block balances were lasted updated and the update frequency
        uint256 updateFrequency = rocketDAOProtocolSettingsNetwork.getSubmitBalancesFrequency();
        // Calculate the last reportable block based on update frequency
        return block.number.div(updateFrequency).mul(updateFrequency);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

import "../RocketBase.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/network/RocketNetworkFeesInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";

/// @notice Network node demand and commission rate
contract RocketNetworkFees is RocketBase, RocketNetworkFeesInterface {

    // Libs
    using SafeMath for uint;
    using SafeCast for uint;

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 2;
    }

    /// @notice Returns the current RP network node demand in ETH
    ///         Node demand is equal to deposit pool balance minus available minipool capacity
    function getNodeDemand() override public view returns (int256) {
        // Load contracts
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        RocketMinipoolQueueInterface rocketMinipoolQueue = RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue"));
        // Calculate & return
        int256 depositPoolBalance = rocketDepositPool.getBalance().toInt256();
        int256 minipoolCapacity = rocketMinipoolQueue.getEffectiveCapacity().toInt256();
        int256 demand = depositPoolBalance - minipoolCapacity;
        require(demand <= depositPoolBalance);
        return demand;
    }

    /// @notice Returns the current RP network node fee as a fraction of 1 ETH
    function getNodeFee() override external view returns (uint256) {
        return getNodeFeeByDemand(getNodeDemand());
    }

    /// @notice Returns the network node fee for a given node demand value
    /// @param _nodeDemand The node demand to calculate the fee for
    function getNodeFeeByDemand(int256 _nodeDemand) override public view returns (uint256) {
        // Calculation base values
        uint256 demandDivisor = 1000000000000;
        // Get settings
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        uint256 minFee = rocketDAOProtocolSettingsNetwork.getMinimumNodeFee();
        uint256 targetFee = rocketDAOProtocolSettingsNetwork.getTargetNodeFee();
        uint256 maxFee = rocketDAOProtocolSettingsNetwork.getMaximumNodeFee();
        uint256 demandRange = rocketDAOProtocolSettingsNetwork.getNodeFeeDemandRange();
        // Normalize node demand
        uint256 nNodeDemand;
        bool nNodeDemandSign;
        if (_nodeDemand < 0) {
            nNodeDemand = uint256(-_nodeDemand);
            nNodeDemandSign = false;
        } else {
            nNodeDemand = uint256(_nodeDemand);
            nNodeDemandSign = true;
        }
        nNodeDemand = nNodeDemand.mul(calcBase).div(demandRange);
        // Check range bounds
        if (nNodeDemand == 0) { return targetFee; }
        if (nNodeDemand >= calcBase) {
            if (nNodeDemandSign) { return maxFee; }
            return minFee;
        }
        // Get fee interpolation factor
        uint256 t = nNodeDemand.div(demandDivisor) ** 3;
        // Interpolate between min / target / max fee
        if (nNodeDemandSign) { return targetFee.add(maxFee.sub(targetFee).mul(t).div(calcBase)); }
        return minFee.add(targetFee.sub(minFee).mul(calcBase.sub(t)).div(calcBase));
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/network/RocketNetworkPenaltiesInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";
import "../../interface/minipool/RocketMinipoolPenaltyInterface.sol";

// Minipool penalties

contract RocketNetworkPenalties is RocketBase, RocketNetworkPenaltiesInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event PenaltySubmitted(address indexed from, address minipoolAddress, uint256 block, uint256 time);
    event PenaltyUpdated(address indexed minipoolAddress, uint256 penalty, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Submit penalty for node operator non-compliance
    function submitPenalty(address _minipoolAddress, uint256 _block) override external onlyLatestContract("rocketNetworkPenalties", address(this)) onlyTrustedNode(msg.sender) onlyRegisteredMinipool(_minipoolAddress) {
        // Get contracts
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(abi.encodePacked("network.penalties.submitted.node", msg.sender, _minipoolAddress, _block));
        bytes32 submissionCountKey = keccak256(abi.encodePacked("network.penalties.submitted.count", _minipoolAddress, _block));
        bytes32 executedKey = keccak256(abi.encodePacked("network.penalties.executed", _minipoolAddress, _block));
        // Check & update node submission status
        require(!getBool(nodeSubmissionKey), "Duplicate submission from node");
        require(!getBool(executedKey), "Penalty already applied for this block");
        setBool(nodeSubmissionKey, true);
        // Increment submission count
        uint256 submissionCount = getUint(submissionCountKey).add(1);
        setUint(submissionCountKey, submissionCount);
        // Emit balances submitted event
        emit PenaltySubmitted(msg.sender, _minipoolAddress, _block, block.timestamp);
        // Check submission count & update network balances
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        if (calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodePenaltyThreshold()) {
            setBool(executedKey, true);
            incrementMinipoolPenaltyCount(_minipoolAddress);
        }
    }

    // Executes incrementMinipoolPenaltyCount if consensus threshold is reached
    function executeUpdatePenalty(address _minipoolAddress, uint256 _block) override external onlyLatestContract("rocketNetworkPenalties", address(this)) {
        // Get contracts
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        // Get submission keys
        bytes32 submissionCountKey = keccak256(abi.encodePacked("network.penalties.submitted.count", _minipoolAddress, _block));
        bytes32 executedKey = keccak256(abi.encodePacked("network.penalties.executed", _minipoolAddress, _block));
        // Check whether it's been executed yet
        require(!getBool(executedKey), "Penalty already applied for this block");
        // Get submission count
        uint256 submissionCount = getUint(submissionCountKey);
        // Check submission count & update network balances
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        require(calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodePenaltyThreshold(), "Consensus has not been reached");
        setBool(executedKey, true);
        incrementMinipoolPenaltyCount(_minipoolAddress);
    }

    // Returns the number of penalties for a given minipool
    function getPenaltyCount(address _minipoolAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("network.penalties.penalty", _minipoolAddress)));
    }

    // Increments the number of penalties against given minipool and updates penalty rate appropriately
    function incrementMinipoolPenaltyCount(address _minipoolAddress) private {
        // Get contracts
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        // Calculate penalty count key
        bytes32 key = keccak256(abi.encodePacked("network.penalties.penalty", _minipoolAddress));
        // Get the current penalty count
        uint256 newPenaltyCount = getUint(key).add(1);
        // Update the penalty count
        setUint(key, newPenaltyCount);
        // First two penalties do not increase penalty rate
        if (newPenaltyCount < 3) {
            return;
        }
        newPenaltyCount = newPenaltyCount.sub(2);
        // Calculate the new penalty rate
        uint256 penaltyRate = newPenaltyCount.mul(rocketDAOProtocolSettingsNetwork.getPerPenaltyRate());
        // Set the penalty rate
        RocketMinipoolPenaltyInterface rocketMinipoolPenalty = RocketMinipoolPenaltyInterface(getContractAddress("rocketMinipoolPenalty"));
        rocketMinipoolPenalty.setPenaltyRate(_minipoolAddress, penaltyRate);
        // Emit penalty updated event
        emit PenaltyUpdated(_minipoolAddress, penaltyRate, block.timestamp);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/network/RocketNetworkPricesInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";

/// @notice Oracle contract for network token price data
contract RocketNetworkPrices is RocketBase, RocketNetworkPricesInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event PricesSubmitted(address indexed from, uint256 block, uint256 rplPrice, uint256 time);
    event PricesUpdated(uint256 block, uint256 rplPrice, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Set contract version
        version = 2;

        // On initial deploy, preset RPL price to 0.01
        if (getRPLPrice() == 0) {
            setRPLPrice(0.01 ether);
        }
    }

    /// @notice Returns the block number which prices are current for
    function getPricesBlock() override public view returns (uint256) {
        return getUint(keccak256("network.prices.updated.block"));
    }

    /// @dev Sets the block number which prices are current for
    function setPricesBlock(uint256 _value) private {
        setUint(keccak256("network.prices.updated.block"), _value);
    }

    /// @notice Returns the current network RPL price in ETH
    function getRPLPrice() override public view returns (uint256) {
        return getUint(keccak256("network.prices.rpl"));
    }

    /// @dev Sets the current network RPL price in ETH
    function setRPLPrice(uint256 _value) private {
        setUint(keccak256("network.prices.rpl"), _value);
    }

    /// @notice Submit network price data for a block
    ///         Only accepts calls from trusted (oracle) nodes
    /// @param _block The block this price submission is for
    /// @param _rplPrice The price of RPL at the given block
    function submitPrices(uint256 _block, uint256 _rplPrice) override external onlyLatestContract("rocketNetworkPrices", address(this)) onlyTrustedNode(msg.sender) {
        // Check settings
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        require(rocketDAOProtocolSettingsNetwork.getSubmitPricesEnabled(), "Submitting prices is currently disabled");
        // Check block
        require(_block < block.number, "Prices can not be submitted for a future block");
        require(_block > getPricesBlock(), "Network prices for an equal or higher block are set");
        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(abi.encodePacked("network.prices.submitted.node.key", msg.sender, _block, _rplPrice));
        bytes32 submissionCountKey = keccak256(abi.encodePacked("network.prices.submitted.count", _block, _rplPrice));
        // Check & update node submission status
        require(!getBool(nodeSubmissionKey), "Duplicate submission from node");
        setBool(nodeSubmissionKey, true);
        setBool(keccak256(abi.encodePacked("network.prices.submitted.node", msg.sender, _block)), true);
        // Increment submission count
        uint256 submissionCount = getUint(submissionCountKey).add(1);
        setUint(submissionCountKey, submissionCount);
        // Emit prices submitted event
        emit PricesSubmitted(msg.sender, _block, _rplPrice, block.timestamp);
        // Check submission count & update network prices
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        if (calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodeConsensusThreshold()) {
            // Update the price
            updatePrices(_block, _rplPrice);
        }
    }

    /// @notice Executes updatePrices if consensus threshold is reached
    /// @param _block The block to execute price update for
    /// @param _rplPrice The price of RPL at the given block
    function executeUpdatePrices(uint256 _block, uint256 _rplPrice) override external onlyLatestContract("rocketNetworkPrices", address(this)) {
        // Check settings
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        require(rocketDAOProtocolSettingsNetwork.getSubmitPricesEnabled(), "Submitting prices is currently disabled");
        // Check block
        require(_block < block.number, "Prices can not be submitted for a future block");
        require(_block > getPricesBlock(), "Network prices for an equal or higher block are set");
        // Get submission keys
        bytes32 submissionCountKey = keccak256(abi.encodePacked("network.prices.submitted.count", _block, _rplPrice));
        // Get submission count
        uint256 submissionCount = getUint(submissionCountKey);
        // Check submission count & update network prices
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        require(calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodeConsensusThreshold(), "Consensus has not been reached");
        // Update the price
        updatePrices(_block, _rplPrice);
    }

    /// @dev Update network price data
    /// @param _block The block to update price for
    /// @param _rplPrice The price of RPL at the given block
    function updatePrices(uint256 _block, uint256 _rplPrice) private {
        // Update price
        setRPLPrice(_rplPrice);
        setPricesBlock(_block);
        // Emit prices updated event
        emit PricesUpdated(_block, _rplPrice, block.timestamp);
    }

    /// @notice Returns the latest block number that oracles should be reporting prices for
    function getLatestReportableBlock() override external view returns (uint256) {
        // Load contracts
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        // Get the block prices were lasted updated and the update frequency
        uint256 updateFrequency = rocketDAOProtocolSettingsNetwork.getSubmitPricesFrequency();
        // Calculate the last reportable block based on update frequency
        return block.number.div(updateFrequency).mul(updateFrequency);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/minipool/RocketMinipoolInterface.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/minipool/RocketMinipoolQueueInterface.sol";
import "../../interface/network/RocketNetworkFeesInterface.sol";
import "../../interface/node/RocketNodeDepositInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsDepositInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/dao/node/settings/RocketDAONodeTrustedSettingsMembersInterface.sol";
import "../../types/MinipoolDeposit.sol";
import "../../interface/node/RocketNodeManagerInterface.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";

/// @notice Handles node deposits and minipool creation
contract RocketNodeDeposit is RocketBase, RocketNodeDepositInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 3;
    }

    /// @dev Accept incoming ETH from the deposit pool
    receive() external payable onlyLatestContract("rocketDepositPool", msg.sender) {}

    /// @notice Returns a node operator's credit balance in wei
    function getNodeDepositCredit(address _nodeOperator) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("node.deposit.credit.balance", _nodeOperator)));
    }

    /// @dev Increases a node operators deposit credit balance
    function increaseDepositCreditBalance(address _nodeOperator, uint256 _amount) override external onlyLatestContract("rocketNodeDeposit", address(this)) {
        // Accept calls from network contracts or registered minipools
        require(getBool(keccak256(abi.encodePacked("minipool.exists", msg.sender))) ||
            getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))),
            "Invalid or outdated network contract");
        // Increase credit balance
        addUint(keccak256(abi.encodePacked("node.deposit.credit.balance", _nodeOperator)), _amount);
    }

    /// @notice Accept a node deposit and create a new minipool under the node. Only accepts calls from registered nodes
    /// @param _bondAmount The amount of capital the node operator wants to put up as his bond
    /// @param _minimumNodeFee Transaction will revert if network commission rate drops below this amount
    /// @param _validatorPubkey Pubkey of the validator the node operator wishes to migrate
    /// @param _validatorSignature Signature from the validator over the deposit data
    /// @param _depositDataRoot The hash tree root of the deposit data (passed onto the deposit contract on pre stake)
    /// @param _salt Salt used to deterministically construct the minipool's address
    /// @param _expectedMinipoolAddress The expected deterministic minipool address. Will revert if it doesn't match
    function deposit(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) override external payable onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Check amount
        require(msg.value == _bondAmount, "Invalid value");
        // Process the deposit
        _deposit(_bondAmount, _minimumNodeFee, _validatorPubkey, _validatorSignature, _depositDataRoot, _salt, _expectedMinipoolAddress);
    }

    /// @notice Accept a node deposit and create a new minipool under the node. Only accepts calls from registered nodes
    /// @param _bondAmount The amount of capital the node operator wants to put up as his bond
    /// @param _minimumNodeFee Transaction will revert if network commission rate drops below this amount
    /// @param _validatorPubkey Pubkey of the validator the node operator wishes to migrate
    /// @param _validatorSignature Signature from the validator over the deposit data
    /// @param _depositDataRoot The hash tree root of the deposit data (passed onto the deposit contract on pre stake)
    /// @param _salt Salt used to deterministically construct the minipool's address
    /// @param _expectedMinipoolAddress The expected deterministic minipool address. Will revert if it doesn't match
    function depositWithCredit(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) override external payable onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Query node's deposit credit
        uint256 credit = getNodeDepositCredit(msg.sender);
        // Credit balance accounting
        if (credit < _bondAmount) {
            uint256 shortFall = _bondAmount.sub(credit);
            require(msg.value == shortFall, "Invalid value");
            setUint(keccak256(abi.encodePacked("node.deposit.credit.balance", msg.sender)), 0);
        } else {
            require(msg.value == 0, "Invalid value");
            subUint(keccak256(abi.encodePacked("node.deposit.credit.balance", msg.sender)), _bondAmount);
        }
        // Process the deposit
        _deposit(_bondAmount, _minimumNodeFee, _validatorPubkey, _validatorSignature, _depositDataRoot, _salt, _expectedMinipoolAddress);
    }

    /// @notice Returns true if the given amount is a valid deposit amount
    function isValidDepositAmount(uint256 _amount) override public pure returns (bool) {
        return _amount == 16 ether || _amount == 8 ether;
    }

    /// @notice Returns an array of valid deposit amounts
    function getDepositAmounts() override external pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 16 ether;
        amounts[1] = 8 ether;
        return amounts;
    }

    /// @dev Internal logic to process a deposit
    function _deposit(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) private {
        // Check pre-conditions
        checkDepositsEnabled();
        checkDistributorInitialised();
        checkNodeFee(_minimumNodeFee);
        require(isValidDepositAmount(_bondAmount), "Invalid deposit amount");
        // Get launch constants
        uint256 launchAmount;
        uint256 preLaunchValue;
        {
            RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
            launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
            preLaunchValue = rocketDAOProtocolSettingsMinipool.getPreLaunchValue();
        }
        // Check that pre deposit won't fail
        if (msg.value < preLaunchValue) {
            RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
            require(preLaunchValue.sub(msg.value) <= rocketDepositPool.getBalance(), "Deposit pool balance is insufficient for pre deposit");          
        }
        // Emit deposit received event
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
        // Increase ETH matched (used to calculate RPL collateral requirements)
        _increaseEthMatched(msg.sender, launchAmount.sub(_bondAmount));
        // Create the minipool
        RocketMinipoolInterface minipool = createMinipool(_salt, _expectedMinipoolAddress);
        // Process node deposit
        _processNodeDeposit(preLaunchValue, _bondAmount);
        // Perform the pre deposit
        minipool.preDeposit{value: preLaunchValue}(_bondAmount, _validatorPubkey, _validatorSignature, _depositDataRoot);
        // Enqueue the minipool
        enqueueMinipool(address(minipool));
        // Assign deposits if enabled
        assignDeposits();
    }

    /// @dev Processes a node deposit with the deposit pool
    /// @param _preLaunchValue The prelaunch value (result of call to `RocketDAOProtocolSettingsMinipool.getPreLaunchValue()`
    /// @param _bondAmount The bond amount for this deposit
    function _processNodeDeposit(uint256 _preLaunchValue, uint256 _bondAmount) private {
        // Get contracts
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        // Retrieve ETH from deposit pool if required
        uint256 shortFall = 0;
        if (msg.value < _preLaunchValue) {
            shortFall = _preLaunchValue.sub(msg.value);
            rocketDepositPool.nodeCreditWithdrawal(shortFall);
        }
        uint256 remaining = msg.value.add(shortFall).sub(_preLaunchValue);
        // Deposit the left over value into the deposit pool
        rocketDepositPool.nodeDeposit{value: remaining}(_bondAmount.sub(_preLaunchValue));
    }

    /// @notice Creates a "vacant" minipool which a node operator can use to migrate a validator with a BLS withdrawal credential
    /// @param _bondAmount The amount of capital the node operator wants to put up as his bond
    /// @param _minimumNodeFee Transaction will revert if network commission rate drops below this amount
    /// @param _validatorPubkey Pubkey of the validator the node operator wishes to migrate
    /// @param _salt Salt used to deterministically construct the minipool's address
    /// @param _expectedMinipoolAddress The expected deterministic minipool address. Will revert if it doesn't match
    /// @param _currentBalance The current balance of the validator on the beaconchain (will be checked by oDAO and scrubbed if not correct)
    function createVacantMinipool(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, uint256 _salt, address _expectedMinipoolAddress, uint256 _currentBalance) override external onlyLatestContract("rocketNodeDeposit", address(this)) onlyRegisteredNode(msg.sender) {
        // Check pre-conditions
        checkVacantMinipoolsEnabled();
        checkDistributorInitialised();
        checkNodeFee(_minimumNodeFee);
        require(isValidDepositAmount(_bondAmount), "Invalid deposit amount");
        // Increase ETH matched (used to calculate RPL collateral requirements)
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
        _increaseEthMatched(msg.sender, launchAmount.sub(_bondAmount));
        // Create the minipool
        _createVacantMinipool(_salt, _validatorPubkey, _bondAmount, _expectedMinipoolAddress, _currentBalance);
    }

    /// @notice Called by minipools during bond reduction to increase the amount of ETH the node operator has
    /// @param _nodeAddress The node operator's address to increase the ETH matched for
    /// @param _amount The amount to increase the ETH matched
    /// @dev Will revert if the new ETH matched amount exceeds the node operators limit
    function increaseEthMatched(address _nodeAddress, uint256 _amount) override external onlyLatestContract("rocketNodeDeposit", address(this)) onlyLatestNetworkContract() {
        _increaseEthMatched(_nodeAddress, _amount);
    }

    /// @dev Increases the amount of ETH that has been matched against a node operators bond. Reverts if it exceeds the
    ///      collateralisation requirements of the network
    function _increaseEthMatched(address _nodeAddress, uint256 _amount) private {
        // Check amount doesn't exceed limits
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
        uint256 ethMatched = rocketNodeStaking.getNodeETHMatched(_nodeAddress).add(_amount);
        require(
            ethMatched <= rocketNodeStaking.getNodeETHMatchedLimit(_nodeAddress),
            "ETH matched after deposit exceeds limit based on node RPL stake"
        );
        setUint(keccak256(abi.encodePacked("eth.matched.node.amount", _nodeAddress)), ethMatched);
    }

    /// @dev Adds a minipool to the queue
    function enqueueMinipool(address _minipoolAddress) private {
        // Add minipool to queue
        RocketMinipoolQueueInterface(getContractAddress("rocketMinipoolQueue")).enqueueMinipool(_minipoolAddress);
    }

    /// @dev Reverts if node operator has not initialised their fee distributor
    function checkDistributorInitialised() private view {
        // Check node has initialised their fee distributor
        RocketNodeManagerInterface rocketNodeManager = RocketNodeManagerInterface(getContractAddress("rocketNodeManager"));
        require(rocketNodeManager.getFeeDistributorInitialised(msg.sender), "Fee distributor not initialised");
    }

    /// @dev Creates a minipool and returns an instance of it
    /// @param _salt The salt used to determine the minipools address
    /// @param _expectedMinipoolAddress The expected minipool address. Reverts if not correct
    function createMinipool(uint256 _salt, address _expectedMinipoolAddress) private returns (RocketMinipoolInterface) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Check minipool doesn't exist or previously exist
        require(!rocketMinipoolManager.getMinipoolExists(_expectedMinipoolAddress) && !rocketMinipoolManager.getMinipoolDestroyed(_expectedMinipoolAddress), "Minipool already exists or was previously destroyed");
        // Create minipool
        RocketMinipoolInterface minipool = rocketMinipoolManager.createMinipool(msg.sender, _salt);
        // Ensure minipool address matches expected
        require(address(minipool) == _expectedMinipoolAddress, "Unexpected minipool address");
        // Return
        return minipool;
    }

    /// @dev Creates a vacant minipool and returns an instance of it
    /// @param _salt The salt used to determine the minipools address
    /// @param _validatorPubkey Pubkey of the validator owning this minipool
    /// @param _bondAmount ETH value the node operator is putting up as capital for this minipool
    /// @param _expectedMinipoolAddress The expected minipool address. Reverts if not correct
    /// @param _currentBalance The current balance of the validator on the beaconchain (will be checked by oDAO and scrubbed if not correct)
    function _createVacantMinipool(uint256 _salt, bytes calldata _validatorPubkey, uint256 _bondAmount, address _expectedMinipoolAddress, uint256 _currentBalance) private returns (RocketMinipoolInterface) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Check minipool doesn't exist or previously exist
        require(!rocketMinipoolManager.getMinipoolExists(_expectedMinipoolAddress) && !rocketMinipoolManager.getMinipoolDestroyed(_expectedMinipoolAddress), "Minipool already exists or was previously destroyed");
        // Create minipool
        RocketMinipoolInterface minipool = rocketMinipoolManager.createVacantMinipool(msg.sender, _salt, _validatorPubkey, _bondAmount, _currentBalance);
        // Ensure minipool address matches expected
        require(address(minipool) == _expectedMinipoolAddress, "Unexpected minipool address");
        // Return
        return minipool;
    }

    /// @dev Reverts if network node fee is below a minimum
    /// @param _minimumNodeFee The minimum node fee required to not revert
    function checkNodeFee(uint256 _minimumNodeFee) private view {
        // Load contracts
        RocketNetworkFeesInterface rocketNetworkFees = RocketNetworkFeesInterface(getContractAddress("rocketNetworkFees"));
        // Check current node fee
        uint256 nodeFee = rocketNetworkFees.getNodeFee();
        require(nodeFee >= _minimumNodeFee, "Minimum node fee exceeds current network node fee");
    }

    /// @dev Reverts if deposits are not enabled
    function checkDepositsEnabled() private view {
        // Get contracts
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Check node settings
        require(rocketDAOProtocolSettingsNode.getDepositEnabled(), "Node deposits are currently disabled");
    }

    /// @dev Reverts if vacant minipools are not enabled
    function checkVacantMinipoolsEnabled() private view {
        // Get contracts
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Check node settings
        require(rocketDAOProtocolSettingsNode.getVacantMinipoolsEnabled(), "Vacant minipools are currently disabled");
    }

    /// @dev Executes an assignDeposits call on the deposit pool
    function assignDeposits() private {
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        rocketDepositPool.maybeAssignDeposits();
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "./RocketNodeDistributorStorageLayout.sol";

contract RocketNodeDistributor is RocketNodeDistributorStorageLayout {
    bytes32 immutable distributorStorageKey;

    constructor(address _nodeAddress, address _rocketStorage) {
        rocketStorage = RocketStorageInterface(_rocketStorage);
        nodeAddress = _nodeAddress;

        // Precompute storage key for rocketNodeDistributorDelegate
        distributorStorageKey = keccak256(abi.encodePacked("contract.address", "rocketNodeDistributorDelegate"));
    }

    // Allow contract to receive ETH without making a delegated call
    receive() external payable {}

    // Delegates all transactions to the target supplied during creation
    fallback() external payable {
        address _target = rocketStorage.getAddress(distributorStorageKey);
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _target, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, returndatasize())} default {return (0, returndatasize())}
        }
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "./RocketNodeDistributorStorageLayout.sol";
import "../../interface/RocketStorageInterface.sol";
import "../../interface/node/RocketNodeManagerInterface.sol";
import "../../interface/node/RocketNodeDistributorInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";

/// @dev Contains the logic for RocketNodeDistributors
contract RocketNodeDistributorDelegate is RocketNodeDistributorStorageLayout, RocketNodeDistributorInterface {
    // Import libraries
    using SafeMath for uint256;

    // Events
    event FeesDistributed(address _nodeAddress, uint256 _userAmount, uint256 _nodeAmount, uint256 _time);

    // Constants
    uint8 public constant version = 2;
    uint256 constant calcBase = 1 ether;

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    // Precomputed constants
    bytes32 immutable rocketNodeManagerKey;
    bytes32 immutable rocketNodeStakingKey;
    bytes32 immutable rocketTokenRETHKey;

    modifier nonReentrant() {
        require(lock != ENTERED, "Reentrant call");
        lock = ENTERED;
        _;
        lock = NOT_ENTERED;
    }

    constructor() {
        // Precompute storage keys
        rocketNodeManagerKey = keccak256(abi.encodePacked("contract.address", "rocketNodeManager"));
        rocketNodeStakingKey = keccak256(abi.encodePacked("contract.address", "rocketNodeStaking"));
        rocketTokenRETHKey = keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"));
        // These values must be set by proxy contract as this contract should only be delegatecalled
        rocketStorage = RocketStorageInterface(address(0));
        nodeAddress = address(0);
        lock = NOT_ENTERED;
    }

    /// @notice Returns the portion of the contract's balance that belongs to the node operator
    function getNodeShare() override public view returns (uint256) {
        // Get contracts
        RocketNodeManagerInterface rocketNodeManager = RocketNodeManagerInterface(rocketStorage.getAddress(rocketNodeManagerKey));
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(rocketStorage.getAddress(rocketNodeStakingKey));
        // Get withdrawal address and the node's average node fee
        uint256 averageNodeFee = rocketNodeManager.getAverageNodeFee(nodeAddress);
        // Get node ETH collateral ratio
        uint256 collateralRatio = rocketNodeStaking.getNodeETHCollateralisationRatio(nodeAddress);
        // Calculate reward split
        uint256 nodeBalance = address(this).balance.mul(calcBase).div(collateralRatio);
        uint256 userBalance = address(this).balance.sub(nodeBalance);
        return nodeBalance.add(userBalance.mul(averageNodeFee).div(calcBase));
    }

    /// @notice Returns the portion of the contract's balance that belongs to the users
    function getUserShare() override external view returns (uint256) {
        return address(this).balance.sub(getNodeShare());
    }

    /// @notice Distributes the balance of this contract to its owners
    function distribute() override external nonReentrant {
        // Calculate node share
        uint256 nodeShare = getNodeShare();
        // Transfer node share
        address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(nodeAddress);
        (bool success,) = withdrawalAddress.call{value : nodeShare}("");
        require(success);
        // Transfer user share
        uint256 userShare = address(this).balance;
        address rocketTokenRETH = rocketStorage.getAddress(rocketTokenRETHKey);
        payable(rocketTokenRETH).transfer(userShare);
        // Emit event
        emit FeesDistributed(nodeAddress, userShare, nodeShare, block.timestamp);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "./RocketNodeDistributor.sol";
import "./RocketNodeDistributorStorageLayout.sol";
import "../../interface/node/RocketNodeDistributorFactoryInterface.sol";

contract RocketNodeDistributorFactory is RocketBase, RocketNodeDistributorFactoryInterface {
    // Events
    event ProxyCreated(address _address);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    function getProxyBytecode() override public pure returns (bytes memory) {
        return type(RocketNodeDistributor).creationCode;
    }

    // Calculates the predetermined distributor contract address from given node address
    function getProxyAddress(address _nodeAddress) override external view returns(address) {
        bytes memory contractCode = getProxyBytecode();
        bytes memory initCode = abi.encodePacked(contractCode, abi.encode(_nodeAddress, rocketStorage));

        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), uint256(0), keccak256(initCode)));

        return address(uint160(uint(hash)));
    }

    // Uses CREATE2 to deploy a RocketNodeDistributor at predetermined address
    function createProxy(address _nodeAddress) override external onlyLatestContract("rocketNodeManager", msg.sender) {
        // Salt is not required as the initCode is already unique per node address (node address is constructor argument)
        RocketNodeDistributor dist = new RocketNodeDistributor{salt: ''}(_nodeAddress, address(rocketStorage));
        emit ProxyCreated(address(dist));
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

import "../../interface/RocketStorageInterface.sol";

// SPDX-License-Identifier: GPL-3.0-only

abstract contract RocketNodeDistributorStorageLayout {
    RocketStorageInterface rocketStorage;
    address nodeAddress;
    uint256 lock;   // Reentrancy guard
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../RocketBase.sol";
import "../../types/MinipoolStatus.sol";
import "../../types/NodeDetails.sol";
import "../../interface/node/RocketNodeManagerInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/util/AddressSetStorageInterface.sol";
import "../../interface/node/RocketNodeDistributorFactoryInterface.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/node/RocketNodeDistributorInterface.sol";
import "../../interface/dao/node/settings/RocketDAONodeTrustedSettingsRewardsInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";
import "../../interface/node/RocketNodeDepositInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";


// Node registration and management 
contract RocketNodeManager is RocketBase, RocketNodeManagerInterface {

    // Libraries
    using SafeMath for uint256;

    // Events
    event NodeRegistered(address indexed node, uint256 time);
    event NodeTimezoneLocationSet(address indexed node, uint256 time);
    event NodeRewardNetworkChanged(address indexed node, uint256 network);
    event NodeSmoothingPoolStateChanged(address indexed node, bool state);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 3;
    }

    // Get the number of nodes in the network
    function getNodeCount() override public view returns (uint256) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getCount(keccak256(abi.encodePacked("nodes.index")));
    }

    // Get a breakdown of the number of nodes per timezone
    function getNodeCountPerTimezone(uint256 _offset, uint256 _limit) override external view returns (TimezoneCount[] memory) {
        // Get contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Precompute node key
        bytes32 nodeKey = keccak256(abi.encodePacked("nodes.index"));
        // Calculate range
        uint256 totalNodes = addressSetStorage.getCount(nodeKey);
        uint256 max = _offset.add(_limit);
        if (max > totalNodes || _limit == 0) { max = totalNodes; }
        // Create an array with as many elements as there are potential values to return
        TimezoneCount[] memory counts = new TimezoneCount[](max.sub(_offset));
        uint256 uniqueTimezoneCount = 0;
        // Iterate the minipool range
        for (uint256 i = _offset; i < max; i++) {
            address nodeAddress = addressSetStorage.getItem(nodeKey, i);
            string memory timezone = getString(keccak256(abi.encodePacked("node.timezone.location", nodeAddress)));
            // Find existing entry in our array
            bool existing = false;
            for (uint256 j = 0; j < uniqueTimezoneCount; j++) {
                if (keccak256(bytes(counts[j].timezone)) == keccak256(bytes(timezone))) {
                    existing = true;
                    // Increment the counter
                    counts[j].count++;
                    break;
                }
            }
            // Entry was not found, so create a new one
            if (!existing) {
                counts[uniqueTimezoneCount].timezone = timezone;
                counts[uniqueTimezoneCount].count = 1;
                uniqueTimezoneCount++;
            }
        }
        // Dirty hack to cut unused elements off end of return value
        assembly {
            mstore(counts, uniqueTimezoneCount)
        }
        return counts;
    }

    // Get a node address by index
    function getNodeAt(uint256 _index) override external view returns (address) {
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        return addressSetStorage.getItem(keccak256(abi.encodePacked("nodes.index")), _index);
    }

    // Check whether a node exists
    function getNodeExists(address _nodeAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress)));
    }

    // Get a node's current withdrawal address
    function getNodeWithdrawalAddress(address _nodeAddress) override public view returns (address) {
        return rocketStorage.getNodeWithdrawalAddress(_nodeAddress);
    }

    // Get a node's pending withdrawal address
    function getNodePendingWithdrawalAddress(address _nodeAddress) override public view returns (address) {
        return rocketStorage.getNodePendingWithdrawalAddress(_nodeAddress);
    }

    // Get a node's timezone location
    function getNodeTimezoneLocation(address _nodeAddress) override public view returns (string memory) {
        return getString(keccak256(abi.encodePacked("node.timezone.location", _nodeAddress)));
    }

    // Register a new node with Rocket Pool
    function registerNode(string calldata _timezoneLocation) override external onlyLatestContract("rocketNodeManager", address(this)) {
        // Load contracts
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Check node settings
        require(rocketDAOProtocolSettingsNode.getRegistrationEnabled(), "Rocket Pool node registrations are currently disabled");
        // Check timezone location
        require(bytes(_timezoneLocation).length >= 4, "The timezone location is invalid");
        // Initialise node data
        setBool(keccak256(abi.encodePacked("node.exists", msg.sender)), true);
        setString(keccak256(abi.encodePacked("node.timezone.location", msg.sender)), _timezoneLocation);
        // Add node to index
        addressSetStorage.addItem(keccak256(abi.encodePacked("nodes.index")), msg.sender);
        // Initialise fee distributor for this node
        _initialiseFeeDistributor(msg.sender);
        // Set node registration time (uses old storage key name for backwards compatibility)
        setUint(keccak256(abi.encodePacked("rewards.pool.claim.contract.registered.time", "rocketClaimNode", msg.sender)), block.timestamp);
        // Emit node registered event
        emit NodeRegistered(msg.sender, block.timestamp);
    }

    // Get's the timestamp of when a node was registered
    function getNodeRegistrationTime(address _nodeAddress) onlyRegisteredNode(_nodeAddress) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("rewards.pool.claim.contract.registered.time", "rocketClaimNode", _nodeAddress)));
    }

    // Set a node's timezone location
    // Only accepts calls from registered nodes
    function setTimezoneLocation(string calldata _timezoneLocation) override external onlyLatestContract("rocketNodeManager", address(this)) onlyRegisteredNode(msg.sender) {
        // Check timezone location
        require(bytes(_timezoneLocation).length >= 4, "The timezone location is invalid");
        // Set timezone location
        setString(keccak256(abi.encodePacked("node.timezone.location", msg.sender)), _timezoneLocation);
        // Emit node timezone location set event
        emit NodeTimezoneLocationSet(msg.sender, block.timestamp);
    }

    // Returns true if node has initialised their fee distributor contract
    function getFeeDistributorInitialised(address _nodeAddress) override public view returns (bool) {
        // Load contracts
        RocketNodeDistributorFactoryInterface rocketNodeDistributorFactory = RocketNodeDistributorFactoryInterface(getContractAddress("rocketNodeDistributorFactory"));
        // Get distributor address
        address contractAddress = rocketNodeDistributorFactory.getProxyAddress(_nodeAddress);
        // Check if contract exists at that address
        uint32 codeSize;
        assembly {
            codeSize := extcodesize(contractAddress)
        }
        return codeSize > 0;
    }

    // Node operators created before the distributor was implemented must call this to setup their distributor contract
    function initialiseFeeDistributor() override external onlyLatestContract("rocketNodeManager", address(this)) onlyRegisteredNode(msg.sender) {
        // Prevent multiple calls
        require(!getFeeDistributorInitialised(msg.sender), "Already initialised");
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        // Calculate and set current average fee numerator
        uint256 count = rocketMinipoolManager.getNodeMinipoolCount(msg.sender);
        if (count > 0){
            uint256 numerator = 0;
            // Note: this loop is safe as long as all current node operators at the time of upgrade have few enough minipools
            for (uint256 i = 0; i < count; i++) {
                RocketMinipoolInterface minipool = RocketMinipoolInterface(rocketMinipoolManager.getNodeMinipoolAt(msg.sender, i));
                if (minipool.getStatus() == MinipoolStatus.Staking){
                    numerator = numerator.add(minipool.getNodeFee());
                }
            }
            setUint(keccak256(abi.encodePacked("node.average.fee.numerator", msg.sender)), numerator);
        }
        // Create the distributor contract
        _initialiseFeeDistributor(msg.sender);
    }

    // Deploys the fee distributor contract for a given node
    function _initialiseFeeDistributor(address _nodeAddress) internal {
        // Load contracts
        RocketNodeDistributorFactoryInterface rocketNodeDistributorFactory = RocketNodeDistributorFactoryInterface(getContractAddress("rocketNodeDistributorFactory"));
        // Create the distributor proxy
        rocketNodeDistributorFactory.createProxy(_nodeAddress);
    }

    // Calculates a nodes average node fee
    function getAverageNodeFee(address _nodeAddress) override external view returns (uint256) {
        // Load contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        RocketNodeDepositInterface rocketNodeDeposit = RocketNodeDepositInterface(getContractAddress("rocketNodeDeposit"));
        RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
        // Get valid deposit amounts
        uint256[] memory depositSizes = rocketNodeDeposit.getDepositAmounts();
        // Setup memory for calculations
        uint256[] memory depositWeights = new uint256[](depositSizes.length);
        uint256[] memory depositCounts = new uint256[](depositSizes.length);
        uint256 depositWeightTotal;
        uint256 totalCount;
        uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
        // Retrieve the number of staking minipools per deposit size
        for (uint256 i = 0; i < depositSizes.length; i++) {
            depositCounts[i] = rocketMinipoolManager.getNodeStakingMinipoolCountBySize(_nodeAddress, depositSizes[i]);
            totalCount = totalCount.add(depositCounts[i]);
        }
        if (totalCount == 0) {
            return 0;
        }
        // Calculate the weights of each deposit size
        for (uint256 i = 0; i < depositSizes.length; i++) {
            depositWeights[i] = launchAmount.sub(depositSizes[i]).mul(depositCounts[i]);
            depositWeightTotal = depositWeightTotal.add(depositWeights[i]);
        }
        for (uint256 i = 0; i < depositSizes.length; i++) {
            depositWeights[i] = depositWeights[i].mul(calcBase).div(depositWeightTotal);
        }
        // Calculate the weighted average
        uint256 weightedAverage = 0;
        for (uint256 i = 0; i < depositSizes.length; i++) {
            if (depositCounts[i] > 0) {
                bytes32 numeratorKey;
                if (depositSizes[i] == 16 ether) {
                    numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", _nodeAddress));
                } else {
                    numeratorKey = keccak256(abi.encodePacked("node.average.fee.numerator", _nodeAddress, depositSizes[i]));
                }
                uint256 numerator = getUint(numeratorKey);
                weightedAverage = weightedAverage.add(numerator.mul(depositWeights[i]).div(depositCounts[i]));
            }
        }
        return weightedAverage.div(calcBase);
    }

    // Designates which network a node would like their rewards relayed to
    function setRewardNetwork(address _nodeAddress, uint256 _network) override external onlyLatestContract("rocketNodeManager", address(this)) {
        // Confirm the transaction is from the node's current withdrawal address
        address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(_nodeAddress);
        require(withdrawalAddress == msg.sender, "Only a tx from a node's withdrawal address can change reward network");
        // Check network is enabled
        RocketDAONodeTrustedSettingsRewardsInterface rocketDAONodeTrustedSettingsRewards = RocketDAONodeTrustedSettingsRewardsInterface(getContractAddress("rocketDAONodeTrustedSettingsRewards"));
        require(rocketDAONodeTrustedSettingsRewards.getNetworkEnabled(_network), "Network is not enabled");
        // Set the network
        setUint(keccak256(abi.encodePacked("node.reward.network", _nodeAddress)), _network);
        // Emit event
        emit NodeRewardNetworkChanged(_nodeAddress, _network);
    }

    // Returns which network a node has designated as their desired reward network
    function getRewardNetwork(address _nodeAddress) override public view onlyLatestContract("rocketNodeManager", address(this)) returns (uint256) {
        return getUint(keccak256(abi.encodePacked("node.reward.network", _nodeAddress)));
    }

    // Allows a node to register or deregister from the smoothing pool
    function setSmoothingPoolRegistrationState(bool _state) override external onlyLatestContract("rocketNodeManager", address(this)) onlyRegisteredNode(msg.sender) {
        // Ensure registration is enabled
        RocketDAOProtocolSettingsNodeInterface daoSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        require(daoSettingsNode.getSmoothingPoolRegistrationEnabled(), "Smoothing pool registrations are not active");
        // Precompute storage keys
        bytes32 changeKey = keccak256(abi.encodePacked("node.smoothing.pool.changed.time", msg.sender));
        bytes32 stateKey = keccak256(abi.encodePacked("node.smoothing.pool.state", msg.sender));
        // Get from the DAO settings
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        uint256 rewardInterval = daoSettingsRewards.getRewardsClaimIntervalTime();
        // Ensure node operator has waited the required time
        uint256 lastChange = getUint(changeKey);
        require(block.timestamp >= lastChange.add(rewardInterval), "Not enough time has passed since changing state");
        // Ensure state is actually changing
        require(getBool(stateKey) != _state, "Invalid state change");
        // Update registration state
        setUint(changeKey, block.timestamp);
        setBool(stateKey, _state);
        // Emit state change event
        emit NodeSmoothingPoolStateChanged(msg.sender, _state);
    }

    // Returns whether a node is registered or not from the smoothing pool
    function getSmoothingPoolRegistrationState(address _nodeAddress) override public view returns (bool) {
        return getBool(keccak256(abi.encodePacked("node.smoothing.pool.state", _nodeAddress)));
    }

    // Returns the timestamp of when the node last changed their smoothing pool registration state
    function getSmoothingPoolRegistrationChanged(address _nodeAddress) override external view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("node.smoothing.pool.changed.time", _nodeAddress)));
    }

    // Returns the sum of nodes that are registered for the smoothing pool between _offset and (_offset + _limit)
    function getSmoothingPoolRegisteredNodeCount(uint256 _offset, uint256 _limit) override external view returns (uint256) {
        // Get contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Precompute node key
        bytes32 nodeKey = keccak256(abi.encodePacked("nodes.index"));
        // Iterate over the requested minipool range
        uint256 totalNodes = getNodeCount();
        uint256 max = _offset.add(_limit);
        if (max > totalNodes || _limit == 0) { max = totalNodes; }
        uint256 count = 0;
        for (uint256 i = _offset; i < max; i++) {
            address nodeAddress = addressSetStorage.getItem(nodeKey, i);
            if (getSmoothingPoolRegistrationState(nodeAddress)) {
                count++;
            }
        }
        return count;
    }

    /// @notice Convenience function to return all on-chain details about a given node
    /// @param _nodeAddress Address of the node to query details for
    function getNodeDetails(address _nodeAddress) override public view returns (NodeDetails memory nodeDetails) {
        // Get contracts
        RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
        RocketNodeDepositInterface rocketNodeDeposit = RocketNodeDepositInterface(getContractAddress("rocketNodeDeposit"));
        RocketNodeDistributorFactoryInterface rocketNodeDistributorFactory = RocketNodeDistributorFactoryInterface(getContractAddress("rocketNodeDistributorFactory"));
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        IERC20 rocketTokenRETH = IERC20(getContractAddress("rocketTokenRETH"));
        IERC20 rocketTokenRPL = IERC20(getContractAddress("rocketTokenRPL"));
        IERC20 rocketTokenRPLFixedSupply = IERC20(getContractAddress("rocketTokenRPLFixedSupply"));
        // Node details
        nodeDetails.nodeAddress = _nodeAddress;
        nodeDetails.withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(_nodeAddress);
        nodeDetails.pendingWithdrawalAddress = rocketStorage.getNodePendingWithdrawalAddress(_nodeAddress);
        nodeDetails.exists = getNodeExists(_nodeAddress);
        nodeDetails.registrationTime = getNodeRegistrationTime(_nodeAddress);
        nodeDetails.timezoneLocation = getNodeTimezoneLocation(_nodeAddress);
        nodeDetails.feeDistributorInitialised = getFeeDistributorInitialised(_nodeAddress);
        nodeDetails.rewardNetwork = getRewardNetwork(_nodeAddress);
        // Staking details
        nodeDetails.rplStake = rocketNodeStaking.getNodeRPLStake(_nodeAddress);
        nodeDetails.effectiveRPLStake = rocketNodeStaking.getNodeEffectiveRPLStake(_nodeAddress);
        nodeDetails.minimumRPLStake = rocketNodeStaking.getNodeMinimumRPLStake(_nodeAddress);
        nodeDetails.maximumRPLStake = rocketNodeStaking.getNodeMaximumRPLStake(_nodeAddress);
        nodeDetails.ethMatched = rocketNodeStaking.getNodeETHMatched(_nodeAddress);
        nodeDetails.ethMatchedLimit = rocketNodeStaking.getNodeETHMatchedLimit(_nodeAddress);
        // Distributor details
        nodeDetails.feeDistributorAddress = rocketNodeDistributorFactory.getProxyAddress(_nodeAddress);
        uint256 distributorBalance = nodeDetails.feeDistributorAddress.balance;
        RocketNodeDistributorInterface distributor = RocketNodeDistributorInterface(nodeDetails.feeDistributorAddress);
        nodeDetails.distributorBalanceNodeETH = distributor.getNodeShare();
        nodeDetails.distributorBalanceUserETH = distributorBalance.sub(nodeDetails.distributorBalanceNodeETH);
        // Minipool details
        nodeDetails.minipoolCount = rocketMinipoolManager.getNodeMinipoolCount(_nodeAddress);
        // Balance details
        nodeDetails.balanceETH = _nodeAddress.balance;
        nodeDetails.balanceRETH = rocketTokenRETH.balanceOf(_nodeAddress);
        nodeDetails.balanceRPL = rocketTokenRPL.balanceOf(_nodeAddress);
        nodeDetails.balanceOldRPL = rocketTokenRPLFixedSupply.balanceOf(_nodeAddress);
        nodeDetails.depositCreditBalance = rocketNodeDeposit.getNodeDepositCredit(_nodeAddress);
        // Return
        return nodeDetails;
    }

    /// @notice Returns a slice of the node operator address set
    /// @param _offset The starting point into the slice
    /// @param _limit The maximum number of results to return
    function getNodeAddresses(uint256 _offset, uint256 _limit) override external view returns (address[] memory) {
        // Get contracts
        AddressSetStorageInterface addressSetStorage = AddressSetStorageInterface(getContractAddress("addressSetStorage"));
        // Precompute node key
        bytes32 nodeKey = keccak256(abi.encodePacked("nodes.index"));
        // Iterate over the requested minipool range
        uint256 totalNodes = getNodeCount();
        uint256 max = _offset.add(_limit);
        if (max > totalNodes || _limit == 0) { max = totalNodes; }
        // Create array big enough for every minipool
        address[] memory nodes = new address[](max.sub(_offset));
        uint256 total = 0;
        for (uint256 i = _offset; i < max; i++) {
            nodes[total] = addressSetStorage.getItem(nodeKey, i);
            total++;
        }
        // Dirty hack to cut unused elements off end of return value
        assembly {
            mstore(nodes, total)
        }
        return nodes;
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../RocketBase.sol";
import "../../interface/minipool/RocketMinipoolManagerInterface.sol";
import "../../interface/network/RocketNetworkPricesInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsMinipoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNodeInterface.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/util/AddressSetStorageInterface.sol";

/// @notice Handles node deposits and minipool creation
contract RocketNodeStaking is RocketBase, RocketNodeStakingInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event RPLStaked(address indexed from, uint256 amount, uint256 time);
    event RPLWithdrawn(address indexed to, uint256 amount, uint256 time);
    event RPLSlashed(address indexed node, uint256 amount, uint256 ethValue, uint256 time);
    event StakeRPLForAllowed(address indexed node, address indexed caller, bool allowed, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 4;
    }

    /// @notice Returns the total quantity of RPL staked on the network
    function getTotalRPLStake() override external view returns (uint256) {
        return getUint(keccak256("rpl.staked.total.amount"));
    }

    /// @dev Increases the total network RPL stake
    /// @param _amount How much to increase by
    function increaseTotalRPLStake(uint256 _amount) private {
        addUint(keccak256("rpl.staked.total.amount"), _amount);
    }

    /// @dev Decrease the total network RPL stake
    /// @param _amount How much to decrease by
    function decreaseTotalRPLStake(uint256 _amount) private {
        subUint(keccak256("rpl.staked.total.amount"), _amount);
    }

    /// @notice Returns the amount a given node operator has staked
    /// @param _nodeAddress The address of the node operator to query
    function getNodeRPLStake(address _nodeAddress) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("rpl.staked.node.amount", _nodeAddress)));
    }

    /// @dev Increases a node operator's RPL stake
    /// @param _amount How much to increase by
    function increaseNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        addUint(keccak256(abi.encodePacked("rpl.staked.node.amount", _nodeAddress)), _amount);
    }

    /// @dev Decrease a node operator's RPL stake
    /// @param _amount How much to decrease by
    function decreaseNodeRPLStake(address _nodeAddress, uint256 _amount) private {
        subUint(keccak256(abi.encodePacked("rpl.staked.node.amount", _nodeAddress)), _amount);
    }

    /// @notice Returns a node's matched ETH amount (amount taken from protocol to stake)
    /// @param _nodeAddress The address of the node operator to query
    function getNodeETHMatched(address _nodeAddress) override public view returns (uint256) {
        uint256 ethMatched = getUint(keccak256(abi.encodePacked("eth.matched.node.amount", _nodeAddress)));

        if (ethMatched > 0) {
            return ethMatched;
        } else {
            // Fallback for backwards compatibility before ETH matched was recorded (all minipools matched 16 ETH from protocol)
            RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
            return rocketMinipoolManager.getNodeActiveMinipoolCount(_nodeAddress).mul(16 ether);
        }
    }

    /// @notice Returns a node's provided ETH amount (amount supplied to create minipools)
    /// @param _nodeAddress The address of the node operator to query
    function getNodeETHProvided(address _nodeAddress) override public view returns (uint256) {
        // Get contracts
        RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
        uint256 activeMinipoolCount = rocketMinipoolManager.getNodeActiveMinipoolCount(_nodeAddress);
        // Retrieve stored ETH matched value
        uint256 ethMatched = getUint(keccak256(abi.encodePacked("eth.matched.node.amount", _nodeAddress)));
        if (ethMatched > 0) {
            RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
            uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
            // ETH provided is number of staking minipools * 32 - eth matched
            uint256 totalEthStaked = activeMinipoolCount.mul(launchAmount);
            return totalEthStaked.sub(ethMatched);
        } else {
            // Fallback for legacy minipools is number of staking minipools * 16
            return activeMinipoolCount.mul(16 ether);
        }
    }

    /// @notice Returns the ratio between capital taken from users and provided by a node operator.
    ///         The value is a 1e18 precision fixed point integer value of (node capital + user capital) / node capital.
    /// @param _nodeAddress The address of the node operator to query
    function getNodeETHCollateralisationRatio(address _nodeAddress) override public view returns (uint256) {
        uint256 ethMatched = getUint(keccak256(abi.encodePacked("eth.matched.node.amount", _nodeAddress)));
        if (ethMatched == 0) {
            // Node operator only has legacy minipools and all legacy minipools had a 1:1 ratio
            return calcBase.mul(2);
        } else {
            RocketDAOProtocolSettingsMinipoolInterface rocketDAOProtocolSettingsMinipool = RocketDAOProtocolSettingsMinipoolInterface(getContractAddress("rocketDAOProtocolSettingsMinipool"));
            uint256 launchAmount = rocketDAOProtocolSettingsMinipool.getLaunchBalance();
            RocketMinipoolManagerInterface rocketMinipoolManager = RocketMinipoolManagerInterface(getContractAddress("rocketMinipoolManager"));
            uint256 totalEthStaked = rocketMinipoolManager.getNodeActiveMinipoolCount(_nodeAddress).mul(launchAmount);
            return totalEthStaked.mul(calcBase).div(totalEthStaked.sub(ethMatched));
        }
    }

    /// @notice Returns the timestamp at which a node last staked RPL
    function getNodeRPLStakedTime(address _nodeAddress) override public view returns (uint256) {
        return getUint(keccak256(abi.encodePacked("rpl.staked.node.time", _nodeAddress)));
    }

    /// @dev Sets the timestamp at which a node last staked RPL
    /// @param _nodeAddress The address of the node operator to set the value for
    /// @param _time The timestamp to set
    function setNodeRPLStakedTime(address _nodeAddress, uint256 _time) private {
        setUint(keccak256(abi.encodePacked("rpl.staked.node.time", _nodeAddress)), _time);
    }

    /// @notice Calculate and return a node's effective RPL stake amount
    /// @param _nodeAddress The address of the node operator to calculate for
    function getNodeEffectiveRPLStake(address _nodeAddress) override external view returns (uint256) {
        // Load contracts
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Get node's current RPL stake
        uint256 rplStake = getNodeRPLStake(_nodeAddress);
        // Retrieve variables for calculations
        uint256 matchedETH = getNodeETHMatched(_nodeAddress);
        uint256 providedETH = getNodeETHProvided(_nodeAddress);
        uint256 rplPrice = rocketNetworkPrices.getRPLPrice();
        // RPL stake cannot exceed maximum
        uint256 maximumStakePercent = rocketDAOProtocolSettingsNode.getMaximumPerMinipoolStake();
        uint256 maximumStake = providedETH.mul(maximumStakePercent).div(rplPrice);
        if (rplStake > maximumStake) {
            return maximumStake;
        }
        // If RPL stake is lower than minimum, node has no effective stake
        uint256 minimumStakePercent = rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake();
        uint256 minimumStake = matchedETH.mul(minimumStakePercent).div(rplPrice);
        if (rplStake < minimumStake) {
            return 0;
        }
        // Otherwise, return the actual stake
        return rplStake;
    }

    /// @notice Calculate and return a node's minimum RPL stake to collateralize their minipools
    /// @param _nodeAddress The address of the node operator to calculate for
    function getNodeMinimumRPLStake(address _nodeAddress) override external view returns (uint256) {
        // Load contracts
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Retrieve variables
        uint256 minimumStakePercent = rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake();
        uint256 matchedETH = getNodeETHMatched(_nodeAddress);
        return matchedETH
            .mul(minimumStakePercent)
            .div(rocketNetworkPrices.getRPLPrice());
    }

    /// @notice Calculate and return a node's maximum RPL stake to fully collateralise their minipools
    /// @param _nodeAddress The address of the node operator to calculate for
    function getNodeMaximumRPLStake(address _nodeAddress) override public view returns (uint256) {
        // Load contracts
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Retrieve variables
        uint256 maximumStakePercent = rocketDAOProtocolSettingsNode.getMaximumPerMinipoolStake();
        uint256 providedETH = getNodeETHProvided(_nodeAddress);
        return providedETH
            .mul(maximumStakePercent)
            .div(rocketNetworkPrices.getRPLPrice());
    }

    /// @notice Calculate and return a node's limit of how much user ETH they can use based on RPL stake
    /// @param _nodeAddress The address of the node operator to calculate for
    function getNodeETHMatchedLimit(address _nodeAddress) override external view returns (uint256) {
        // Load contracts
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketDAOProtocolSettingsNodeInterface rocketDAOProtocolSettingsNode = RocketDAOProtocolSettingsNodeInterface(getContractAddress("rocketDAOProtocolSettingsNode"));
        // Calculate & return limit
        uint256 minimumStakePercent = rocketDAOProtocolSettingsNode.getMinimumPerMinipoolStake();
        return getNodeRPLStake(_nodeAddress)
            .mul(rocketNetworkPrices.getRPLPrice())
            .div(minimumStakePercent);
    }

    /// @notice Accept an RPL stake
    ///         Only accepts calls from registered nodes
    ///         Requires call to have approved this contract to spend RPL
    /// @param _amount The amount of RPL to stake
    function stakeRPL(uint256 _amount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(msg.sender) {
        _stakeRPL(msg.sender, _amount);
    }

    /// @notice Accept an RPL stake from any address for a specified node
    ///         Requires caller to have approved this contract to spend RPL
    ///         Requires caller to be on the node operator's allow list (see `setStakeForAllowed`)
    /// @param _nodeAddress The address of the node operator to stake on behalf of
    /// @param _amount The amount of RPL to stake
    function stakeRPLFor(address _nodeAddress, uint256 _amount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(_nodeAddress) {
       // Must be node's withdrawal address, allow listed address or rocketMerkleDistributorMainnet
       if (msg.sender != getAddress(keccak256(abi.encodePacked("contract.address", "rocketMerkleDistributorMainnet")))) {
           address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(_nodeAddress);
           if (msg.sender != withdrawalAddress) {
               require(getBool(keccak256(abi.encodePacked("node.stake.for.allowed", _nodeAddress, msg.sender))), "Not allowed to stake for");
           }
       }
       _stakeRPL(_nodeAddress, _amount);
    }

    /// @notice Explicitly allow or remove allowance of an address to be able to stake on behalf of a node
    /// @param _caller The address you wish to allow
    /// @param _allowed Whether the address is allowed or denied
    function setStakeRPLForAllowed(address _caller, bool _allowed) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(msg.sender) {
        setBool(keccak256(abi.encodePacked("node.stake.for.allowed", msg.sender, _caller)), _allowed);
        emit StakeRPLForAllowed(msg.sender, _caller, _allowed, block.timestamp);
    }

    /// @dev Internal logic for staking RPL
    /// @param _nodeAddress The address to increase the RPL stake of
    /// @param _amount The amount of RPL to stake
    function _stakeRPL(address _nodeAddress, uint256 _amount) internal {
        // Load contracts
        address rplTokenAddress = getContractAddress("rocketTokenRPL");
        address rocketVaultAddress = getContractAddress("rocketVault");
        IERC20 rplToken = IERC20(rplTokenAddress);
        RocketVaultInterface rocketVault = RocketVaultInterface(rocketVaultAddress);
        // Transfer RPL tokens
        require(rplToken.transferFrom(msg.sender, address(this), _amount), "Could not transfer RPL to staking contract");
        // Deposit RPL tokens to vault
        require(rplToken.approve(rocketVaultAddress, _amount), "Could not approve vault RPL deposit");
        rocketVault.depositToken("rocketNodeStaking", rplToken, _amount);
        // Update RPL stake amounts & node RPL staked block
        increaseTotalRPLStake(_amount);
        increaseNodeRPLStake(_nodeAddress, _amount);
        setNodeRPLStakedTime(_nodeAddress, block.timestamp);
        // Emit RPL staked event
        emit RPLStaked(_nodeAddress, _amount, block.timestamp);
    }

    /// @notice Withdraw staked RPL back to the node account
    ///         Only accepts calls from registered nodes
    ///         Withdraws to withdrawal address if set, otherwise defaults to node address
    /// @param _amount The amount of RPL to withdraw
    function withdrawRPL(uint256 _amount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredNode(msg.sender) {
        // Load contracts
        RocketDAOProtocolSettingsRewardsInterface rocketDAOProtocolSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Check cooldown period (one claim period) has passed since RPL last staked
        require(block.timestamp.sub(getNodeRPLStakedTime(msg.sender)) >= rocketDAOProtocolSettingsRewards.getRewardsClaimIntervalTime(), "The withdrawal cooldown period has not passed");
        // Get & check node's current RPL stake
        uint256 rplStake = getNodeRPLStake(msg.sender);
        require(rplStake >= _amount, "Withdrawal amount exceeds node's staked RPL balance");
        // Check withdrawal would not undercollateralize node
        require(rplStake.sub(_amount) >= getNodeMaximumRPLStake(msg.sender), "Node's staked RPL balance after withdrawal is less than required balance");
        // Update RPL stake amounts
        decreaseTotalRPLStake(_amount);
        decreaseNodeRPLStake(msg.sender, _amount);
        // Transfer RPL tokens to node address
        rocketVault.withdrawToken(rocketStorage.getNodeWithdrawalAddress(msg.sender), IERC20(getContractAddress("rocketTokenRPL")), _amount);
        // Emit RPL withdrawn event
        emit RPLWithdrawn(msg.sender, _amount, block.timestamp);
    }

    /// @notice Slash a node's RPL by an ETH amount
    ///         Only accepts calls from registered minipools
    /// @param _nodeAddress The address to slash RPL from
    /// @param _ethSlashAmount The amount of RPL to slash denominated in ETH value
    function slashRPL(address _nodeAddress, uint256 _ethSlashAmount) override external onlyLatestContract("rocketNodeStaking", address(this)) onlyRegisteredMinipool(msg.sender) {
        // Load contracts
        RocketNetworkPricesInterface rocketNetworkPrices = RocketNetworkPricesInterface(getContractAddress("rocketNetworkPrices"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Calculate RPL amount to slash
        uint256 rplSlashAmount = calcBase.mul(_ethSlashAmount).div(rocketNetworkPrices.getRPLPrice());
        // Cap slashed amount to node's RPL stake
        uint256 rplStake = getNodeRPLStake(_nodeAddress);
        if (rplSlashAmount > rplStake) { rplSlashAmount = rplStake; }
        // Transfer slashed amount to auction contract
        if(rplSlashAmount > 0) rocketVault.transferToken("rocketAuctionManager", IERC20(getContractAddress("rocketTokenRPL")), rplSlashAmount);
        // Update RPL stake amounts
        decreaseTotalRPLStake(rplSlashAmount);
        decreaseNodeRPLStake(_nodeAddress, rplSlashAmount);
        // Mark minipool as slashed
        setBool(keccak256(abi.encodePacked("minipool.rpl.slashed", msg.sender)), true);
        // Emit RPL slashed event
        emit RPLSlashed(_nodeAddress, rplSlashAmount, _ethSlashAmount, block.timestamp);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/rewards/RocketRewardsPoolInterface.sol";
import "../../interface/rewards/claims/RocketClaimDAOInterface.sol";


// RPL Rewards claiming by the DAO
contract RocketClaimDAO is RocketBase, RocketClaimDAOInterface {

    // Events
    event RPLTokensSentByDAOProtocol(string invoiceID, address indexed from, address indexed to, uint256 amount, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 2;
    }

    // Spend the network DAOs RPL rewards
    function spend(string memory _invoiceID, address _recipientAddress, uint256 _amount) override external onlyLatestContract("rocketDAOProtocolProposals", msg.sender) {
        // Load contracts
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Addresses
        IERC20 rplToken = IERC20(getContractAddress("rocketTokenRPL"));
        // Some initial checks
        require(_amount > 0 && _amount <= rocketVault.balanceOfToken("rocketClaimDAO", rplToken), "You cannot send 0 RPL or more than the DAO has in its account");
        // Send now
        rocketVault.withdrawToken(_recipientAddress, rplToken, _amount);
        // Log it
        emit RPLTokensSentByDAOProtocol(_invoiceID, address(this), _recipientAddress, _amount, block.timestamp);
    }
  

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/token/RocketTokenRPLInterface.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/node/RocketNodeStakingInterface.sol";
import "../../interface/rewards/RocketRewardsRelayInterface.sol";
import "../../interface/rewards/RocketSmoothingPoolInterface.sol";
import "../../interface/RocketVaultWithdrawerInterface.sol";

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

/*
* On mainnet, the relay and the distributor are the same contract as there is no need for an intermediate contract to
* handle cross-chain messaging.
*/

contract RocketMerkleDistributorMainnet is RocketBase, RocketRewardsRelayInterface, RocketVaultWithdrawerInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event RewardsClaimed(address indexed claimer, uint256[] rewardIndex, uint256[] amountRPL, uint256[] amountETH);

    // Constants
    uint256 constant network = 0;

    // Immutables
    bytes32 immutable rocketVaultKey;
    bytes32 immutable rocketTokenRPLKey;

    // Allow receiving ETH
    receive() payable external {}

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
        // Precompute keys
        rocketVaultKey = keccak256(abi.encodePacked("contract.address", "rocketVault"));
        rocketTokenRPLKey = keccak256(abi.encodePacked("contract.address", "rocketTokenRPL"));
        // Set this contract as the relay for network 0
        setAddress(keccak256(abi.encodePacked("rewards.relay.address", uint256(0))), address(this));
    }

    // Called by RocketRewardsPool to include a snapshot into this distributor
    function relayRewards(uint256 _rewardIndex, bytes32 _root, uint256 _rewardsRPL, uint256 _rewardsETH) external override onlyLatestContract("rocketMerkleDistributorMainnet", address(this)) onlyLatestContract("rocketRewardsPool", msg.sender) {
        bytes32 key = keccak256(abi.encodePacked('rewards.merkle.root', _rewardIndex));
        require(getBytes32(key) == bytes32(0));
        setBytes32(key, _root);
        // Send the ETH and RPL to the vault
        RocketVaultInterface rocketVault = RocketVaultInterface(getAddress(rocketVaultKey));
        if (_rewardsETH > 0) {
            rocketVault.depositEther{value: _rewardsETH}();
        }
        if (_rewardsRPL > 0) {
            IERC20 rocketTokenRPL = IERC20(getAddress(rocketTokenRPLKey));
            rocketTokenRPL.approve(address(rocketVault), _rewardsRPL);
            rocketVault.depositToken("rocketMerkleDistributorMainnet", rocketTokenRPL, _rewardsRPL);
        }
    }

    // Reward recipients can call this method with a merkle proof to claim rewards for one or more reward intervals
    function claim(address _nodeAddress, uint256[] calldata _rewardIndex, uint256[] calldata _amountRPL, uint256[] calldata _amountETH, bytes32[][] calldata _merkleProof) external override {
        claimAndStake(_nodeAddress, _rewardIndex, _amountRPL, _amountETH, _merkleProof, 0);
    }

    // Node operators can call this method to claim rewards for one or more reward intervals and specify an amount of RPL to stake at the same time
    function claimAndStake(address _nodeAddress, uint256[] calldata _rewardIndex, uint256[] calldata _amountRPL, uint256[] calldata _amountETH, bytes32[][] calldata _merkleProof, uint256 _stakeAmount) public override {
        // Get contracts
        RocketVaultInterface rocketVault = RocketVaultInterface(getAddress(rocketVaultKey));
        address rocketTokenRPLAddress = getAddress(rocketTokenRPLKey);
        // Verify claims
        _claim(_rewardIndex, _nodeAddress, _amountRPL, _amountETH, _merkleProof);
        {
            // Get withdrawal address
            address withdrawalAddress = rocketStorage.getNodeWithdrawalAddress(_nodeAddress);
            require(msg.sender == _nodeAddress || msg.sender == withdrawalAddress, "Can only claim from node or withdrawal address");
            // Calculate totals
            uint256 totalAmountRPL = 0;
            uint256 totalAmountETH = 0;
            for (uint256 i = 0; i < _rewardIndex.length; i++) {
                totalAmountRPL = totalAmountRPL.add(_amountRPL[i]);
                totalAmountETH = totalAmountETH.add(_amountETH[i]);
            }
            // Validate input
            require(_stakeAmount <= totalAmountRPL, "Invalid stake amount");
            // Distribute any remaining tokens to the node's withdrawal address
            uint256 remaining = totalAmountRPL.sub(_stakeAmount);
            if (remaining > 0) {
                rocketVault.withdrawToken(withdrawalAddress, IERC20(rocketTokenRPLAddress), remaining);
            }
            // Distribute ETH
            if (totalAmountETH > 0) {
                rocketVault.withdrawEther(totalAmountETH);
                (bool result,) = withdrawalAddress.call{value: totalAmountETH}("");
                require(result, "Failed to claim ETH");
            }
        }
        // Restake requested amount
        if (_stakeAmount > 0) {
            RocketTokenRPLInterface rocketTokenRPL = RocketTokenRPLInterface(rocketTokenRPLAddress);
            RocketNodeStakingInterface rocketNodeStaking = RocketNodeStakingInterface(getContractAddress("rocketNodeStaking"));
            rocketVault.withdrawToken(address(this), IERC20(rocketTokenRPLAddress), _stakeAmount);
            rocketTokenRPL.approve(address(rocketNodeStaking), _stakeAmount);
            rocketNodeStaking.stakeRPLFor(_nodeAddress, _stakeAmount);
        }
        // Emit event
        emit RewardsClaimed(_nodeAddress, _rewardIndex, _amountRPL, _amountETH);
    }

    // Verifies the given data exists as a leaf nodes for the specified reward interval and marks them as claimed if they are valid
    // Note: this function is optimised for gas when _rewardIndex is ordered numerically
    function _claim(uint256[] calldata _rewardIndex, address _nodeAddress, uint256[] calldata _amountRPL, uint256[] calldata _amountETH, bytes32[][] calldata _merkleProof) internal {
        // Set initial parameters to the first reward index in the array
        uint256 indexWordIndex = _rewardIndex[0] / 256;
        bytes32 claimedWordKey = keccak256(abi.encodePacked('rewards.interval.claimed', _nodeAddress, indexWordIndex));
        uint256 claimedWord = getUint(claimedWordKey);
        // Loop over every entry
        for (uint256 i = 0; i < _rewardIndex.length; i++) {
            // Prevent accidental claim of 0
            require(_amountRPL[i] > 0 || _amountETH[i] > 0, "Invalid amount");
            // Check if this entry has a different word index than the previous
            if (indexWordIndex != _rewardIndex[i] / 256) {
                // Store the previous word
                setUint(claimedWordKey, claimedWord);
                // Load the word for this entry
                indexWordIndex = _rewardIndex[i] / 256;
                claimedWordKey = keccak256(abi.encodePacked('rewards.interval.claimed', _nodeAddress, indexWordIndex));
                claimedWord = getUint(claimedWordKey);
            }
            // Calculate the bit index for this entry
            uint256 indexBitIndex = _rewardIndex[i] % 256;
            // Ensure the bit is not yet set on this word
            uint256 mask = (1 << indexBitIndex);
            require(claimedWord & mask != mask, "Already claimed");
            // Verify the merkle proof
            require(_verifyProof(_rewardIndex[i], _nodeAddress, _amountRPL[i], _amountETH[i], _merkleProof[i]), "Invalid proof");
            // Set the bit for the current reward index
            claimedWord = claimedWord | (1 << indexBitIndex);
        }
        // Store the word
        setUint(claimedWordKey, claimedWord);
    }

    // Verifies that the
    function _verifyProof(uint256 _rewardIndex, address _nodeAddress, uint256 _amountRPL, uint256 _amountETH, bytes32[] calldata _merkleProof) internal view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_nodeAddress, network, _amountRPL, _amountETH));
        bytes32 key = keccak256(abi.encodePacked('rewards.merkle.root', _rewardIndex));
        bytes32 merkleRoot = getBytes32(key);
        return MerkleProof.verify(_merkleProof, merkleRoot, node);
    }

    // Returns true if the given claimer has claimed for the given reward interval
    function isClaimed(uint256 _rewardIndex, address _claimer) public override view returns (bool) {
        uint256 indexWordIndex = _rewardIndex / 256;
        uint256 indexBitIndex = _rewardIndex % 256;
        uint256 claimedWord = getUint(keccak256(abi.encodePacked('rewards.interval.claimed', _claimer, indexWordIndex)));
        uint256 mask = (1 << indexBitIndex);
        return claimedWord & mask == mask;
    }

    // Allow receiving ETH from RocketVault, no action required
    function receiveVaultWithdrawalETH() external override payable {}
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/token/RocketTokenRPLInterface.sol";
import "../../interface/rewards/RocketRewardsPoolInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";
import "../../interface/dao/node/RocketDAONodeTrustedInterface.sol";
import "../../interface/network/RocketNetworkBalancesInterface.sol";
import "../../interface/RocketVaultInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsRewardsInterface.sol";
import "../../interface/rewards/RocketRewardsRelayInterface.sol";
import "../../interface/rewards/RocketSmoothingPoolInterface.sol";
import "../../types/RewardSubmission.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


// Holds RPL generated by the network for claiming from stakers (node operators etc)

contract RocketRewardsPool is RocketBase, RocketRewardsPoolInterface {

    // Libs
    using SafeMath for uint256;

    // Events
    event RewardSnapshotSubmitted(address indexed from, uint256 indexed rewardIndex, RewardSubmission submission, uint256 time);
    event RewardSnapshot(uint256 indexed rewardIndex, RewardSubmission submission, uint256 intervalStartTime, uint256 intervalEndTime, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 2;
    }

    function getRewardIndex() override public view returns(uint256) {
        return getUint(keccak256("rewards.snapshot.index"));
    }
    function incrementRewardIndex() private {
        addUint(keccak256("rewards.snapshot.index"), 1);
    }

    /**
    * Get how much RPL the Rewards Pool contract currently has assigned to it as a whole
    * @return uint256 Returns rpl balance of rocket rewards contract
    */
    function getRPLBalance() override public view returns(uint256) {
        // Get the vault contract instance
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Check contract RPL balance
        return rocketVault.balanceOfToken("rocketRewardsPool", IERC20(getContractAddress("rocketTokenRPL")));
    }

    // Returns the total amount of RPL that needs to be distributed to claimers at the current block
    function getPendingRPLRewards() override public view returns (uint256) {
        RocketTokenRPLInterface rplContract = RocketTokenRPLInterface(getContractAddress("rocketTokenRPL"));
        uint256 pendingInflation = rplContract.inflationCalculate();
        // Any inflation that has accrued so far plus any amount that would be minted if we called it now
        return getRPLBalance().add(pendingInflation);
    }

    // Returns the total amount of ETH in the smoothing pool ready to be distributed
    function getPendingETHRewards() override public view returns (uint256) {
        address rocketSmoothingPoolAddress = getContractAddress("rocketSmoothingPool");
        return rocketSmoothingPoolAddress.balance;
    }

    /**
    * Get the last set interval start time
    * @return uint256 Last set start timestamp for a claim interval
    */
    function getClaimIntervalTimeStart() override public view returns(uint256) {
        return getUint(keccak256("rewards.pool.claim.interval.time.start"));
    }

    /**
    * Get how many seconds in a claim interval
    * @return uint256 Number of seconds in a claim interval
    */
    function getClaimIntervalTime() override public view returns(uint256) {
        // Get from the DAO settings
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        return daoSettingsRewards.getRewardsClaimIntervalTime();
    }

    /**
    * Compute intervals since last claim period
    * @return uint256 Time intervals since last update
    */
    function getClaimIntervalsPassed() override public view returns(uint256) {
        return block.timestamp.sub(getClaimIntervalTimeStart()).div(getClaimIntervalTime());
    }

    /// @notice Returns the block number that the given claim interval was executed at
    /// @param _interval The interval for which to grab the execution block of
    function getClaimIntervalExecutionBlock(uint256 _interval) override external view returns(uint256) {
        return getUint(keccak256(abi.encodePacked("rewards.pool.interval.execution.block", _interval)));
    }

    /**
    * Get the percentage this contract can claim in this interval
    * @return uint256 Rewards percentage this contract can claim in this interval
    */
    function getClaimingContractPerc(string memory _claimingContract) override public view returns (uint256) {
        // Load contract
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        // Get the % amount allocated to this claim contract
        return daoSettingsRewards.getRewardsClaimerPerc(_claimingContract);
    }

    /**
    * Get an array of percentages that the given contracts can claim in this interval
    * @return uint256[] Array of percentages in the order of the supplied contract names
    */
    function getClaimingContractsPerc(string[] memory _claimingContracts) override external view returns (uint256[] memory) {
        // Load contract
        RocketDAOProtocolSettingsRewardsInterface daoSettingsRewards = RocketDAOProtocolSettingsRewardsInterface(getContractAddress("rocketDAOProtocolSettingsRewards"));
        // Get the % amount allocated to this claim contract
        uint256[] memory percentages = new uint256[](_claimingContracts.length);
        for (uint256 i = 0; i < _claimingContracts.length; i++){
            percentages[i] = daoSettingsRewards.getRewardsClaimerPerc(_claimingContracts[i]);
        }
        return percentages;
    }

    // Returns whether a trusted node has submitted for a given reward index
    function getTrustedNodeSubmitted(address _trustedNodeAddress, uint256 _rewardIndex) override external view returns (bool) {
        return getBool(keccak256(abi.encode("rewards.snapshot.submitted.node", _trustedNodeAddress, _rewardIndex)));
    }

    // Returns the number of trusted nodes who have agreed to the given submission
    function getSubmissionCount(RewardSubmission calldata _submission) override external view returns (uint256) {
        return getUint(keccak256(abi.encode("rewards.snapshot.submitted.count", _submission)));
    }

    // Submit a reward snapshot
    // Only accepts calls from trusted (oracle) nodes
    function submitRewardSnapshot(RewardSubmission calldata _submission) override external onlyLatestContract("rocketRewardsPool", address(this)) onlyTrustedNode(msg.sender) {
        // Get contracts
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        // Check submission is currently enabled
        require(rocketDAOProtocolSettingsNetwork.getSubmitRewardsEnabled(), "Submitting rewards is currently disabled");
        // Validate inputs
        require(_submission.rewardIndex == getRewardIndex(), "Can only submit snapshot for next period");
        require(_submission.intervalsPassed > 0, "Invalid number of intervals passed");
        require(_submission.nodeRPL.length == _submission.trustedNodeRPL.length && _submission.trustedNodeRPL.length == _submission.nodeETH.length, "Invalid array length");
        // Calculate RPL reward total and validate
        { // Scope to prevent stake too deep
            uint256 totalRewardsRPL = _submission.treasuryRPL;
            for (uint256 i = 0; i < _submission.nodeRPL.length; i++){
                totalRewardsRPL = totalRewardsRPL.add(_submission.nodeRPL[i]);
            }
            for (uint256 i = 0; i < _submission.trustedNodeRPL.length; i++){
                totalRewardsRPL = totalRewardsRPL.add(_submission.trustedNodeRPL[i]);
            }
            require(totalRewardsRPL <= getPendingRPLRewards(), "Invalid RPL rewards");
        }
        // Calculate ETH reward total and validate
        { // Scope to prevent stack too deep
            uint256 totalRewardsETH = 0;
            for (uint256 i = 0; i < _submission.nodeETH.length; i++){
                totalRewardsETH = totalRewardsETH.add(_submission.nodeETH[i]);
            }
            require(totalRewardsETH <= getPendingETHRewards(), "Invalid ETH rewards");
        }
        // Store and increment vote
        uint256 submissionCount;
        { // Scope to prevent stack too deep
            // Check & update node submission status
            bytes32 nodeSubmissionKey = keccak256(abi.encode("rewards.snapshot.submitted.node.key", msg.sender, _submission));
            require(!getBool(nodeSubmissionKey), "Duplicate submission from node");
            setBool(nodeSubmissionKey, true);
            setBool(keccak256(abi.encode("rewards.snapshot.submitted.node", msg.sender, _submission.rewardIndex)), true);
        }
        { // Scope to prevent stack too deep
            // Increment submission count
            bytes32 submissionCountKey = keccak256(abi.encode("rewards.snapshot.submitted.count", _submission));
            submissionCount = getUint(submissionCountKey).add(1);
            setUint(submissionCountKey, submissionCount);
        }
        // Emit snapshot submitted event
        emit RewardSnapshotSubmitted(msg.sender, _submission.rewardIndex, _submission, block.timestamp);
        // If consensus is reached, execute the snapshot
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        if (calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodeConsensusThreshold()) {
            _executeRewardSnapshot(_submission);
        }
    }

    // Executes reward snapshot if consensus threshold is reached
    function executeRewardSnapshot(RewardSubmission calldata _submission) override external onlyLatestContract("rocketRewardsPool", address(this)) {
        // Validate reward index of submission
        require(_submission.rewardIndex == getRewardIndex(), "Can only execute snapshot for next period");
        // Get submission count
        bytes32 submissionCountKey = keccak256(abi.encode("rewards.snapshot.submitted.count", _submission));
        uint256 submissionCount = getUint(submissionCountKey);
        // Confirm consensus and execute
        RocketDAONodeTrustedInterface rocketDAONodeTrusted = RocketDAONodeTrustedInterface(getContractAddress("rocketDAONodeTrusted"));
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        require(calcBase.mul(submissionCount).div(rocketDAONodeTrusted.getMemberCount()) >= rocketDAOProtocolSettingsNetwork.getNodeConsensusThreshold(), "Consensus has not been reached");
        _executeRewardSnapshot(_submission);
    }

    // Executes reward snapshot and sends assets to the relays for distribution to reward recipients
    function _executeRewardSnapshot(RewardSubmission calldata _submission) private {
        // Get contract
        RocketTokenRPLInterface rplContract = RocketTokenRPLInterface(getContractAddress("rocketTokenRPL"));
        RocketVaultInterface rocketVault = RocketVaultInterface(getContractAddress("rocketVault"));
        // Execute inflation if required
        rplContract.inflationMintTokens();
        // Increment the reward index and update the claim interval timestamp
        incrementRewardIndex();
        uint256 claimIntervalTimeStart = getClaimIntervalTimeStart();
        uint256 claimIntervalTimeEnd = claimIntervalTimeStart.add(getClaimIntervalTime().mul(_submission.intervalsPassed));
        // Emit reward snapshot event
        emit RewardSnapshot(_submission.rewardIndex, _submission, claimIntervalTimeStart, claimIntervalTimeEnd, block.timestamp);
        setUint(keccak256(abi.encodePacked("rewards.pool.interval.execution.block", _submission.rewardIndex)), block.number);
        setUint(keccak256("rewards.pool.claim.interval.time.start"), claimIntervalTimeEnd);
        // Send out the treasury rewards
        if (_submission.treasuryRPL > 0) {
            rocketVault.transferToken("rocketClaimDAO", rplContract, _submission.treasuryRPL);
        }
        // Get the smoothing pool instance
        RocketSmoothingPoolInterface rocketSmoothingPool = RocketSmoothingPoolInterface(getContractAddress("rocketSmoothingPool"));
        // Send deposit pool user's ETH
        if (_submission.userETH > 0) {
            address rocketTokenRETHAddress = getContractAddress("rocketTokenRETH");
            rocketSmoothingPool.withdrawEther(rocketTokenRETHAddress, _submission.userETH);
        }
        // Loop over each network and distribute rewards
        for (uint i = 0; i < _submission.nodeRPL.length; i++) {
            // Quick out if no rewards for this network
            uint256 rewardsRPL = _submission.nodeRPL[i].add(_submission.trustedNodeRPL[i]);
            uint256 rewardsETH = _submission.nodeETH[i];
            if (rewardsRPL == 0 && rewardsETH == 0) {
                continue;
            }
            // Grab the relay address
            RocketRewardsRelayInterface relay;
            { // Scope to prevent stack too deep
                address networkRelayAddress;
                bytes32 networkRelayKey = keccak256(abi.encodePacked("rewards.relay.address", i));
                networkRelayAddress = getAddress(networkRelayKey);
                // Validate network is valid
                require (networkRelayAddress != address(0), "Snapshot contains rewards for invalid network");
                relay = RocketRewardsRelayInterface(networkRelayAddress);
            }
            // Transfer rewards
            if (rewardsRPL > 0) {
                // RPL rewards are withdrawn from the vault
                rocketVault.withdrawToken(address(relay), rplContract, rewardsRPL);
            }
            if (rewardsETH > 0) {
                // ETH rewards are withdrawn from the smoothing pool
                rocketSmoothingPool.withdrawEther(address(relay), rewardsETH);
            }
            // Call into relay contract to handle distribution of rewards
            relay.relayRewards(_submission.rewardIndex, _submission.merkleRoot, rewardsRPL, rewardsETH);
        }
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/rewards/RocketSmoothingPoolInterface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/*
Receives priority fees and MEV via fee_recipient

NOTE: This contract intentionally does not use RocketVault to store ETH because there is no way to account for ETH being
added to this contract via fee_recipient. This also means if this contract is upgraded, the ETH must be manually
transferred from this contract to the upgraded one.
*/

contract RocketSmoothingPool is RocketBase, RocketSmoothingPoolInterface {

    // Libs
    using SafeMath for uint256;

    // Events
    event EtherWithdrawn(string indexed by, address indexed to, uint256 amount, uint256 time);

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
    }

    // Allow receiving ETH
    receive() payable external {}

    // Withdraws ETH to given address
    // Only accepts calls from Rocket Pool network contracts
    function withdrawEther(address _to, uint256 _amount) override external onlyLatestNetworkContract {
        // Valid amount?
        require(_amount > 0, "No valid amount of ETH given to withdraw");
        // Get contract name
        string memory contractName = getContractName(msg.sender);
        // Send the ETH
        (bool result,) = _to.call{value: _amount}("");
        require(result, "Failed to withdraw ETH");
        // Emit ether withdrawn event
        emit EtherWithdrawn(contractName, _to, _amount, block.timestamp);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../interface/RocketStorageInterface.sol";

/// @title Base settings / modifiers for each contract in Rocket Pool
/// @author David Rugendyke

abstract contract RocketBase {

    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    RocketStorageInterface rocketStorage = RocketStorageInterface(0);


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Rocket Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered minipool
    */
    modifier onlyRegisteredMinipool(address _minipoolAddress) {
        require(getBool(keccak256(abi.encodePacked("minipool.exists", _minipoolAddress))), "Invalid minipool");
        _;
    }
    

    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == rocketStorage.getGuardian(), "Account is not a temporary guardian");
        _;
    }




    /*** Methods **********************************************************/

    /// @dev Set the main Rocket Storage address
    constructor(RocketStorageInterface _rocketStorageAddress) {
        // Update the contract address
        rocketStorage = RocketStorageInterface(_rocketStorageAddress);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the address of a network contract by name (returns address(0x0) instead of reverting if contract does not exist)
    function getContractAddressUnsafe(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Rocket Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return rocketStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return rocketStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return rocketStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return rocketStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return rocketStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return rocketStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return rocketStorage.getBytes32(_key); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { rocketStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { rocketStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { rocketStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { rocketStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { rocketStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { rocketStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { rocketStorage.setBytes32(_key, _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { rocketStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { rocketStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { rocketStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { rocketStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { rocketStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { rocketStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { rocketStorage.deleteBytes32(_key); }

    /// @dev Storage arithmetic methods
    function addUint(bytes32 _key, uint256 _amount) internal { rocketStorage.addUint(_key, _amount); }
    function subUint(bytes32 _key, uint256 _amount) internal { rocketStorage.subUint(_key, _amount); }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../interface/RocketStorageInterface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title The primary persistent storage for Rocket Pool
/// @author David Rugendyke

contract RocketStorage is RocketStorageInterface {

    // Events
    event NodeWithdrawalAddressSet(address indexed node, address indexed withdrawalAddress, uint256 time);
    event GuardianChanged(address oldGuardian, address newGuardian);

    // Libraries
    using SafeMath for uint256;

    // Storage maps
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => uint256)    private uintStorage;
    mapping(bytes32 => int256)     private intStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bool)       private booleanStorage;
    mapping(bytes32 => bytes32)    private bytes32Storage;

    // Protected storage (not accessible by network contracts)
    mapping(address => address)    private withdrawalAddresses;
    mapping(address => address)    private pendingWithdrawalAddresses;

    // Guardian address
    address guardian;
    address newGuardian;

    // Flag storage has been initialised
    bool storageInit = false;

    /// @dev Only allow access from the latest version of a contract in the Rocket Pool network after deployment
    modifier onlyLatestRocketNetworkContract() {
        if (storageInit == true) {
            // Make sure the access is permitted to only contracts in our Dapp
            require(booleanStorage[keccak256(abi.encodePacked("contract.exists", msg.sender))], "Invalid or outdated network contract");
        } else {
            // Only Dapp and the guardian account are allowed access during initialisation.
            // tx.origin is only safe to use in this case for deployment since no external contracts are interacted with
            require((
                booleanStorage[keccak256(abi.encodePacked("contract.exists", msg.sender))] || tx.origin == guardian
            ), "Invalid or outdated network contract attempting access during deployment");
        }
        _;
    }


    /// @dev Construct RocketStorage
    constructor() {
        // Set the guardian upon deployment
        guardian = msg.sender;
    }

    // Get guardian address
    function getGuardian() external override view returns (address) {
        return guardian;
    }

    // Transfers guardianship to a new address
    function setGuardian(address _newAddress) external override {
        // Check tx comes from current guardian
        require(msg.sender == guardian, "Is not guardian account");
        // Store new address awaiting confirmation
        newGuardian = _newAddress;
    }

    // Confirms change of guardian
    function confirmGuardian() external override {
        // Check tx came from new guardian address
        require(msg.sender == newGuardian, "Confirmation must come from new guardian address");
        // Store old guardian for event
        address oldGuardian = guardian;
        // Update guardian and clear storage
        guardian = newGuardian;
        delete newGuardian;
        // Emit event
        emit GuardianChanged(oldGuardian, guardian);
    }

    // Set this as being deployed now
    function getDeployedStatus() external override view returns (bool) {
        return storageInit;
    }

    // Set this as being deployed now
    function setDeployedStatus() external {
        // Only guardian can lock this down
        require(msg.sender == guardian, "Is not guardian account");
        // Set it now
        storageInit = true;
    }

    // Protected storage

    // Get a node's withdrawal address
    function getNodeWithdrawalAddress(address _nodeAddress) public override view returns (address) {
        // If no withdrawal address has been set, return the nodes address
        address withdrawalAddress = withdrawalAddresses[_nodeAddress];
        if (withdrawalAddress == address(0)) {
            return _nodeAddress;
        }
        return withdrawalAddress;
    }

    // Get a node's pending withdrawal address
    function getNodePendingWithdrawalAddress(address _nodeAddress) external override view returns (address) {
        return pendingWithdrawalAddresses[_nodeAddress];
    }

    // Set a node's withdrawal address
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external override {
        // Check new withdrawal address
        require(_newWithdrawalAddress != address(0x0), "Invalid withdrawal address");
        // Confirm the transaction is from the node's current withdrawal address
        address withdrawalAddress = getNodeWithdrawalAddress(_nodeAddress);
        require(withdrawalAddress == msg.sender, "Only a tx from a node's withdrawal address can update it");
        // Update immediately if confirmed
        if (_confirm) {
            updateWithdrawalAddress(_nodeAddress, _newWithdrawalAddress);
        }
        // Set pending withdrawal address if not confirmed
        else {
            pendingWithdrawalAddresses[_nodeAddress] = _newWithdrawalAddress;
        }
    }

    // Confirm a node's new withdrawal address
    function confirmWithdrawalAddress(address _nodeAddress) external override {
        // Get node by pending withdrawal address
        require(pendingWithdrawalAddresses[_nodeAddress] == msg.sender, "Confirmation must come from the pending withdrawal address");
        delete pendingWithdrawalAddresses[_nodeAddress];
        // Update withdrawal address
        updateWithdrawalAddress(_nodeAddress, msg.sender);
    }

    // Update a node's withdrawal address
    function updateWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress) private {
        // Set new withdrawal address
        withdrawalAddresses[_nodeAddress] = _newWithdrawalAddress;
        // Emit withdrawal address set event
        emit NodeWithdrawalAddressSet(_nodeAddress, _newWithdrawalAddress, block.timestamp);
    }

    /// @param _key The key for the record
    function getAddress(bytes32 _key) override external view returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) override external view returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) override external view returns (string memory) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) override external view returns (bytes memory) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) override external view returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) override external view returns (int r) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key) override external view returns (bytes32 r) {
        return bytes32Storage[_key];
    }


    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyLatestRocketNetworkContract override external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint _value) onlyLatestRocketNetworkContract override external {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value) onlyLatestRocketNetworkContract override external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value) onlyLatestRocketNetworkContract override external {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyLatestRocketNetworkContract override external {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int _value) onlyLatestRocketNetworkContract override external {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value) onlyLatestRocketNetworkContract override external {
        bytes32Storage[_key] = _value;
    }


    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete intStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key) onlyLatestRocketNetworkContract override external {
        delete bytes32Storage[_key];
    }


    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value
    function addUint(bytes32 _key, uint256 _amount) onlyLatestRocketNetworkContract override external {
        uintStorage[_key] = uintStorage[_key].add(_amount);
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value
    function subUint(bytes32 _key, uint256 _amount) onlyLatestRocketNetworkContract override external {
        uintStorage[_key] = uintStorage[_key].sub(_amount);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./RocketBase.sol";
import "../interface/RocketVaultInterface.sol";
import "../interface/RocketVaultWithdrawerInterface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

// ETH and rETH are stored here to prevent contract upgrades from affecting balances
// The RocketVault contract must not be upgraded

contract RocketVault is RocketBase, RocketVaultInterface {

    // Libs
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    // Network contract balances
    mapping(string => uint256) etherBalances;
    mapping(bytes32 => uint256) tokenBalances;

    // Events
    event EtherDeposited(string indexed by, uint256 amount, uint256 time);
    event EtherWithdrawn(string indexed by, uint256 amount, uint256 time);
    event TokenDeposited(bytes32 indexed by, address indexed tokenAddress, uint256 amount, uint256 time);
    event TokenWithdrawn(bytes32 indexed by, address indexed tokenAddress, uint256 amount, uint256 time);
    event TokenBurned(bytes32 indexed by, address indexed tokenAddress, uint256 amount, uint256 time);
    event TokenTransfer(bytes32 indexed by, bytes32 indexed to, address indexed tokenAddress, uint256 amount, uint256 time);

	// Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // Get a contract's ETH balance by address
    function balanceOf(string memory _networkContractName) override external view returns (uint256) {
        // Return balance
        return etherBalances[_networkContractName];
    }

    // Get the balance of a token held by a network contract
    function balanceOfToken(string memory _networkContractName, IERC20 _tokenAddress) override external view returns (uint256) {
        // Return balance
        return tokenBalances[keccak256(abi.encodePacked(_networkContractName, _tokenAddress))];
    }

    // Accept an ETH deposit from a network contract
    // Only accepts calls from Rocket Pool network contracts
    function depositEther() override external payable onlyLatestNetworkContract {
        // Valid amount?
        require(msg.value > 0, "No valid amount of ETH given to deposit");
        // Get contract key
        string memory contractName = getContractName(msg.sender);
        // Update contract balance
        etherBalances[contractName] = etherBalances[contractName].add(msg.value);
        // Emit ether deposited event
        emit EtherDeposited(contractName, msg.value, block.timestamp);
    }

    // Withdraw an amount of ETH to a network contract
    // Only accepts calls from Rocket Pool network contracts
    function withdrawEther(uint256 _amount) override external onlyLatestNetworkContract {
        // Valid amount?
        require(_amount > 0, "No valid amount of ETH given to withdraw");
        // Get contract key
        string memory contractName = getContractName(msg.sender);
        // Check and update contract balance
        require(etherBalances[contractName] >= _amount, "Insufficient contract ETH balance");
        etherBalances[contractName] = etherBalances[contractName].sub(_amount);
        // Withdraw
        RocketVaultWithdrawerInterface withdrawer = RocketVaultWithdrawerInterface(msg.sender);
        withdrawer.receiveVaultWithdrawalETH{value: _amount}();
        // Emit ether withdrawn event
        emit EtherWithdrawn(contractName, _amount, block.timestamp);
    }

    // Accept an token deposit and assign its balance to a network contract (saves a large amount of gas this way through not needing a double token transfer via a network contract first)
    function depositToken(string memory _networkContractName, IERC20 _tokenContract, uint256 _amount) override external {
         // Valid amount?
        require(_amount > 0, "No valid amount of tokens given to deposit");
        // Make sure the network contract is valid (will throw if not)
        require(getContractAddress(_networkContractName) != address(0x0), "Not a valid network contract");
        // Get contract key
        bytes32 contractKey = keccak256(abi.encodePacked(_networkContractName, address(_tokenContract)));
        // Send the tokens to this contract now
        require(_tokenContract.transferFrom(msg.sender, address(this), _amount), "Token transfer was not successful");
        // Update contract balance
        tokenBalances[contractKey] = tokenBalances[contractKey].add(_amount);
        // Emit token transfer
        emit TokenDeposited(contractKey, address(_tokenContract), _amount, block.timestamp);
    }

    // Withdraw an amount of a ERC20 token to an address
    // Only accepts calls from Rocket Pool network contracts
    function withdrawToken(address _withdrawalAddress, IERC20 _tokenAddress, uint256 _amount) override external onlyLatestNetworkContract {
        // Valid amount?
        require(_amount > 0, "No valid amount of tokens given to withdraw");
        // Get contract key
        bytes32 contractKey = keccak256(abi.encodePacked(getContractName(msg.sender), _tokenAddress));
        // Update balances
        tokenBalances[contractKey] = tokenBalances[contractKey].sub(_amount);
        // Get the token ERC20 instance
        IERC20 tokenContract = IERC20(_tokenAddress);
        // Withdraw to the desired address
        require(tokenContract.transfer(_withdrawalAddress, _amount), "Rocket Vault token withdrawal unsuccessful");
        // Emit token withdrawn event
        emit TokenWithdrawn(contractKey, address(_tokenAddress), _amount, block.timestamp);
    }

    // Transfer token from one contract to another
    // Only accepts calls from Rocket Pool network contracts
    function transferToken(string memory _networkContractName, IERC20 _tokenAddress, uint256 _amount) override external onlyLatestNetworkContract {
        // Valid amount?
        require(_amount > 0, "No valid amount of tokens given to transfer");
        // Make sure the network contract is valid (will throw if not)
        require(getContractAddress(_networkContractName) != address(0x0), "Not a valid network contract");
        // Get contract keys
        bytes32 contractKeyFrom = keccak256(abi.encodePacked(getContractName(msg.sender), _tokenAddress));
        bytes32 contractKeyTo = keccak256(abi.encodePacked(_networkContractName, _tokenAddress));
        // Update balances
        tokenBalances[contractKeyFrom] = tokenBalances[contractKeyFrom].sub(_amount);
        tokenBalances[contractKeyTo] = tokenBalances[contractKeyTo].add(_amount);
        // Emit token withdrawn event
        emit TokenTransfer(contractKeyFrom, contractKeyTo, address(_tokenAddress), _amount, block.timestamp);
    }

    // Burns an amount of a token that implements a burn(uint256) method
    // Only accepts calls from Rocket Pool network contracts
    function burnToken(ERC20Burnable _tokenAddress, uint256 _amount) override external onlyLatestNetworkContract {
        // Get contract key
        bytes32 contractKey = keccak256(abi.encodePacked(getContractName(msg.sender), _tokenAddress));
        // Update balances
        tokenBalances[contractKey] = tokenBalances[contractKey].sub(_amount);
        // Get the token ERC20 instance
        ERC20Burnable tokenContract = ERC20Burnable(_tokenAddress);
        // Burn the tokens
        tokenContract.burn(_amount);
        // Emit token burn event
        emit TokenBurned(contractKey, address(_tokenAddress), _amount, block.timestamp);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../RocketBase.sol";
import "../../interface/deposit/RocketDepositPoolInterface.sol";
import "../../interface/network/RocketNetworkBalancesInterface.sol";
import "../../interface/token/RocketTokenRETHInterface.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";

// rETH is a tokenised stake in the Rocket Pool network
// rETH is backed by ETH (subject to liquidity) at a variable exchange rate

contract RocketTokenRETH is RocketBase, ERC20, RocketTokenRETHInterface {

    // Libs
    using SafeMath for uint;

    // Events
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 ethAmount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 ethAmount, uint256 time);

    // Construct with our token details
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) ERC20("Rocket Pool ETH", "rETH") {
        // Version
        version = 1;
    }

    // Receive an ETH deposit from a minipool or generous individual
    receive() external payable {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Calculate the amount of ETH backing an amount of rETH
    function getEthValue(uint256 _rethAmount) override public view returns (uint256) {
        // Get network balances
        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(getContractAddress("rocketNetworkBalances"));
        uint256 totalEthBalance = rocketNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = rocketNetworkBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) { return _rethAmount; }
        // Calculate and return
        return _rethAmount.mul(totalEthBalance).div(rethSupply);
    }

    // Calculate the amount of rETH backed by an amount of ETH
    function getRethValue(uint256 _ethAmount) override public view returns (uint256) {
        // Get network balances
        RocketNetworkBalancesInterface rocketNetworkBalances = RocketNetworkBalancesInterface(getContractAddress("rocketNetworkBalances"));
        uint256 totalEthBalance = rocketNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = rocketNetworkBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) { return _ethAmount; }
        // Check network ETH balance
        require(totalEthBalance > 0, "Cannot calculate rETH token amount while total network balance is zero");
        // Calculate and return
        return _ethAmount.mul(rethSupply).div(totalEthBalance);
    }

    // Get the current ETH : rETH exchange rate
    // Returns the amount of ETH backing 1 rETH
    function getExchangeRate() override external view returns (uint256) {
        return getEthValue(1 ether);
    }

    // Get the total amount of collateral available
    // Includes rETH contract balance & excess deposit pool balance
    function getTotalCollateral() override public view returns (uint256) {
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        return rocketDepositPool.getExcessBalance().add(address(this).balance);
    }

    // Get the current ETH collateral rate
    // Returns the portion of rETH backed by ETH in the contract as a fraction of 1 ether
    function getCollateralRate() override public view returns (uint256) {
        uint256 totalEthValue = getEthValue(totalSupply());
        if (totalEthValue == 0) { return calcBase; }
        return calcBase.mul(address(this).balance).div(totalEthValue);
    }

    // Deposit excess ETH from deposit pool
    // Only accepts calls from the RocketDepositPool contract
    function depositExcess() override external payable onlyLatestContract("rocketDepositPool", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Mint rETH
    // Only accepts calls from the RocketDepositPool contract
    function mint(uint256 _ethAmount, address _to) override external onlyLatestContract("rocketDepositPool", msg.sender) {
        // Get rETH amount
        uint256 rethAmount = getRethValue(_ethAmount);
        // Check rETH amount
        require(rethAmount > 0, "Invalid token mint amount");
        // Update balance & supply
        _mint(_to, rethAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, rethAmount, _ethAmount, block.timestamp);
    }

    // Burn rETH for ETH
    function burn(uint256 _rethAmount) override external {
        // Check rETH amount
        require(_rethAmount > 0, "Invalid token burn amount");
        require(balanceOf(msg.sender) >= _rethAmount, "Insufficient rETH balance");
        // Get ETH amount
        uint256 ethAmount = getEthValue(_rethAmount);
        // Get & check ETH balance
        uint256 ethBalance = getTotalCollateral();
        require(ethBalance >= ethAmount, "Insufficient ETH balance for exchange");
        // Update balance & supply
        _burn(msg.sender, _rethAmount);
        // Withdraw ETH from deposit pool if required
        withdrawDepositCollateral(ethAmount);
        // Transfer ETH to sender
        msg.sender.transfer(ethAmount);
        // Emit tokens burned event
        emit TokensBurned(msg.sender, _rethAmount, ethAmount, block.timestamp);
    }

    // Withdraw ETH from the deposit pool for collateral if required
    function withdrawDepositCollateral(uint256 _ethRequired) private {
        // Check rETH contract balance
        uint256 ethBalance = address(this).balance;
        if (ethBalance >= _ethRequired) { return; }
        // Withdraw
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        rocketDepositPool.withdrawExcessBalance(_ethRequired.sub(ethBalance));
    }

    // Sends any excess ETH from this contract to the deposit pool (as determined by target collateral rate)
    function depositExcessCollateral() external override {
        // Load contracts
        RocketDAOProtocolSettingsNetworkInterface rocketDAOProtocolSettingsNetwork = RocketDAOProtocolSettingsNetworkInterface(getContractAddress("rocketDAOProtocolSettingsNetwork"));
        RocketDepositPoolInterface rocketDepositPool = RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        // Get collateral and target collateral rate
        uint256 collateralRate = getCollateralRate();
        uint256 targetCollateralRate = rocketDAOProtocolSettingsNetwork.getTargetRethCollateralRate();
        // Check if we are in excess
        if (collateralRate > targetCollateralRate) {
            // Calculate our target collateral in ETH
            uint256 targetCollateral = address(this).balance.mul(targetCollateralRate).div(collateralRate);
            // If we have excess
            if (address(this).balance > targetCollateral) {
                // Send that excess to deposit pool
                uint256 excessCollateral = address(this).balance.sub(targetCollateral);
                rocketDepositPool.recycleExcessCollateral{value: excessCollateral}();
            }
        }
    }

    // This is called by the base ERC20 contract before all transfer, mint, and burns
    function _beforeTokenTransfer(address from, address, uint256) internal override {
        // Don't run check if this is a mint transaction
        if (from != address(0)) {
            // Check which block the user's last deposit was
            bytes32 key = keccak256(abi.encodePacked("user.deposit.block", from));
            uint256 lastDepositBlock = getUint(key);
            if (lastDepositBlock > 0) {
                // Ensure enough blocks have passed
                uint256 depositDelay = getUint(keccak256(abi.encodePacked(keccak256("dao.protocol.setting.network"), "network.reth.deposit.delay")));
                uint256 blocksPassed = block.number.sub(lastDepositBlock);
                require(blocksPassed > depositDelay, "Not enough time has passed since deposit");
                // Clear the state as it's no longer necessary to check this until another deposit is made
                deleteUint(key);
            }
        }
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../RocketBase.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsInflationInterface.sol";
import "../../interface/token/RocketTokenRPLInterface.sol";
import "../../interface/RocketVaultInterface.sol";

// RPL Governance and utility token
// Inlfationary with rate determined by DAO

contract RocketTokenRPL is RocketBase, ERC20Burnable, RocketTokenRPLInterface {

    // Libs
    using SafeMath for uint;

    /**** Properties ***********/

    // How many RPL tokens minted to date (18m from fixed supply)
    uint256 constant totalInitialSupply = 18000000000000000000000000;
    // The RPL inflation interval
    uint256 constant inflationInterval = 1 days;
    // How many RPL tokens have been swapped for new ones
    uint256 public totalSwappedRPL = 0;

    // Timestamp of last block inflation was calculated at
    uint256 private inflationCalcTime = 0;


    /**** Contracts ************/

    // The address of our fixed supply RPL ERC20 token contract
    IERC20 rplFixedSupplyContract = IERC20(address(0));


    /**** Events ***********/

    event RPLInflationLog(address sender, uint256 value, uint256 inflationCalcTime);
    event RPLFixedSupplyBurn(address indexed from, uint256 amount, uint256 time);


    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress, IERC20 _rocketTokenRPLFixedSupplyAddress) RocketBase(_rocketStorageAddress) ERC20("Rocket Pool Protocol", "RPL") {
        // Version
        version = 1;
        // Set the mainnet RPL fixed supply token address
        rplFixedSupplyContract = IERC20(_rocketTokenRPLFixedSupplyAddress);
        // Mint the 18m tokens that currently exist and allow them to be sent to people burning existing fixed supply RPL
        _mint(address(this), totalInitialSupply);
    }

    /**
    * Get the last time that inflation was calculated at
    * @return uint256 Last timestamp since inflation was calculated
    */
    function getInflationCalcTime() override public view returns(uint256) {
        // Get the last time inflation was calculated if it has even started
        uint256 inflationStartTime = getInflationIntervalStartTime();
        // If inflation has just begun but not been calculated previously, use the start block as the last calculated point if it has passed
        return inflationCalcTime == 0 && inflationStartTime < block.timestamp ? inflationStartTime : inflationCalcTime;
    }

    /**
    * How many seconds to calculate inflation at
    * @return uint256 how many seconds to calculate inflation at
    */
    function getInflationIntervalTime() override external pure returns(uint256) {
        return inflationInterval;
    }

    /**
    * The current inflation rate per interval (eg 1000133680617113500 = 5% annual)
    * @return uint256 The current inflation rate per interval
    */
    function getInflationIntervalRate() override public view returns(uint256) {
        // Inflation rate controlled by the DAO
        RocketDAOProtocolSettingsInflationInterface daoSettingsInflation = RocketDAOProtocolSettingsInflationInterface(getContractAddress("rocketDAOProtocolSettingsInflation"));
        return daoSettingsInflation.getInflationIntervalRate();
    }

    /**
    * The current block to begin inflation at
    * @return uint256 The current block to begin inflation at
    */
    function getInflationIntervalStartTime() override public view returns(uint256) {
        // Inflation rate start time controlled by the DAO
        RocketDAOProtocolSettingsInflationInterface daoSettingsInflation = RocketDAOProtocolSettingsInflationInterface(getContractAddress("rocketDAOProtocolSettingsInflation"));
        return daoSettingsInflation.getInflationIntervalStartTime();
    }

    /**
    * The current rewards pool address that receives the inflation
    * @return address The rewards pool contract address
    */
    function getInflationRewardsContractAddress() override external view returns(address) {
        // Inflation rate start block controlled by the DAO
        return getContractAddress("rocketRewardsPool");
    }


    /**
    * Compute interval since last inflation update (on call)
    * @return uint256 Time intervals since last update
    */
    function getInflationIntervalsPassed() override public view returns(uint256) {
        // The time that inflation was last calculated at
        uint256 inflationLastCalculatedTime = getInflationCalcTime();
        return _getInflationIntervalsPassed(inflationLastCalculatedTime);
    }

    function _getInflationIntervalsPassed(uint256 _inflationLastCalcTime) private view returns(uint256) {
        // Calculate now if inflation has begun
        if(_inflationLastCalcTime > 0) {
            return (block.timestamp).sub(_inflationLastCalcTime).div(inflationInterval);
        }else{
            return 0;
        }
    }


    /**
    * @dev Function to compute how many tokens should be minted
    * @return A uint256 specifying number of new tokens to mint
    */
    function inflationCalculate() override external view returns (uint256) {
        uint256 intervalsSinceLastMint = getInflationIntervalsPassed();
        return _inflationCalculate(intervalsSinceLastMint);
    }

    function _inflationCalculate(uint256 _intervalsSinceLastMint) private view returns (uint256) {
        // The inflation amount
        uint256 inflationTokenAmount = 0;
        // Only update  if last interval has passed and inflation rate is > 0
        if(_intervalsSinceLastMint > 0) {
            // Optimisation
            uint256 inflationRate = getInflationIntervalRate();
            if(inflationRate > 0) {
                // Get the total supply now
                uint256 totalSupplyCurrent = totalSupply();
                uint256 newTotalSupply = totalSupplyCurrent;
                // Compute inflation for total inflation intervals elapsed
                for (uint256 i = 0; i < _intervalsSinceLastMint; i++) {
                    newTotalSupply = newTotalSupply.mul(inflationRate).div(10**18);
                }
                // Return inflation amount
                inflationTokenAmount = newTotalSupply.sub(totalSupplyCurrent);
            }
        }
        // Done
        return inflationTokenAmount;
    }


    /**
    * @dev Mint new tokens if enough time has elapsed since last mint
    * @return A uint256 specifying number of new tokens that were minted
    */
    function inflationMintTokens() override external returns (uint256) {
        // Only run inflation process if at least 1 interval has passed (function returns 0 otherwise)
        uint256 inflationLastCalcTime = getInflationCalcTime();
        uint256 intervalsSinceLastMint = _getInflationIntervalsPassed(inflationLastCalcTime);
        if (intervalsSinceLastMint == 0) {
            return 0;
        }
        // Address of the vault where to send tokens
        address rocketVaultAddress = getContractAddress("rocketVault");
        require(rocketVaultAddress != address(0x0), "rocketVault address not set");
        // Only mint if we have new tokens to mint since last interval and an address is set to receive them
        RocketVaultInterface rocketVaultContract = RocketVaultInterface(rocketVaultAddress);
        // Calculate the amount of tokens now based on inflation rate
        uint256 newTokens = _inflationCalculate(intervalsSinceLastMint);
        // Update last inflation calculation timestamp even if inflation rate is 0
        inflationCalcTime = inflationLastCalcTime.add(inflationInterval.mul(intervalsSinceLastMint));
        // Check if actually need to mint tokens (e.g. inflation rate > 0)
        if (newTokens > 0) {
            // Mint to itself, then allocate tokens for transfer to rewards contract, this will update balance & supply
            _mint(address(this), newTokens);
            // Initialise itself and allow from it's own balance (cant just do an allow as it could be any user calling this so they are msg.sender)
            IERC20 rplInflationContract = IERC20(address(this));
            // Get the current allowance for Rocket Vault
            uint256 vaultAllowance = rplFixedSupplyContract.allowance(rocketVaultAddress, address(this));
            // Now allow Rocket Vault to move those tokens, we also need to account of any other allowances for this token from other contracts in the same block
            require(rplInflationContract.approve(rocketVaultAddress, vaultAllowance.add(newTokens)), "Allowance for Rocket Vault could not be approved");
            // Let vault know it can move these tokens to itself now and credit the balance to the RPL rewards pool contract
            rocketVaultContract.depositToken("rocketRewardsPool", IERC20(address(this)), newTokens);
        }
        // Log it
        emit RPLInflationLog(msg.sender, newTokens, inflationCalcTime);
        // return number minted
        return newTokens;
    }   

   /**
   * @dev Swap current RPL fixed supply tokens for new RPL 1:1 to the same address from the user calling it
   * @param _amount The amount of RPL fixed supply tokens to swap
   */
    function swapTokens(uint256 _amount) override external {
        // Valid amount?
        require(_amount > 0, "Please enter valid amount of RPL to swap");
        // Send the tokens to this contract now and mint new ones for them
        require(rplFixedSupplyContract.transferFrom(msg.sender, address(this), _amount), "Token transfer from existing RPL contract was not successful");
        // Transfer from the contracts RPL balance to the user
        require(this.transfer(msg.sender, _amount), "Token transfer from RPL inflation contract was not successful");
        // Update the total swapped
        totalSwappedRPL = totalSwappedRPL.add(_amount);
        // Log it
        emit RPLFixedSupplyBurn(msg.sender, _amount, block.timestamp);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Dummy Rocket Pool Token (RPL) contract (do not deploy to mainnet)
/// @author Jake Pospischil <[email protected]>

contract RocketTokenDummyRPL is ERC20, Ownable {


    /**** Properties ***********/

    uint8 constant decimalPlaces = 18;
    uint256 constant public exponent = 10**uint256(decimalPlaces);
    uint256 constant public totalSupplyCap = 18.5 * (10**6) * exponent;    // 18 Million tokens


    /**** Libs *****************/
    
    using SafeMath for uint;


    /*** Events ****************/

    event MintToken(address _minter, address _address, uint256 _value);


    /**** Methods ***********/

    // Construct with our token details
    constructor(address _rocketStorageAddress) ERC20("Rocket Pool Dummy RPL", "DRPL") {}


    // @dev Mint the Rocket Pool Tokens (RPL)
    // @param _to The address that will receive the minted tokens.
    // @param _amount The amount of tokens to mint.
    // @return A boolean that indicates if the operation was successful.
    function mint(address _to, uint _amount) external onlyOwner returns (bool) {
        // Check token amount is positive
        require(_amount > 0);
        // Check we don't exceed the supply cap
        require(totalSupply().add(_amount) <= totalSupplyCap);
        // Mint tokens at address
        _mint(_to, _amount);
        // Fire mint token event
        emit MintToken(msg.sender, _to, _amount);
        // Return success flag
        return true;
    }


    /// @dev Returns the amount of tokens that can still be minted
    function getRemainingTokens() external view returns(uint256) {
        return totalSupplyCap.sub(totalSupply());
    }


}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "../RocketBase.sol";

import "../minipool/RocketMinipoolManager.sol";
import "../node/RocketNodeManager.sol";
import "../node/RocketNodeDistributorFactory.sol";
import "../node/RocketNodeDistributorDelegate.sol";
import "../../interface/dao/protocol/settings/RocketDAOProtocolSettingsNetworkInterface.sol";

/// @notice Transient contract to upgrade Rocket Pool with the Atlas set of contract upgrades
contract RocketUpgradeOneDotTwo is RocketBase {

    struct ClaimInterval {
        uint256 interval;
        uint256 block;
    }

    // Whether the upgrade has been performed or not
    bool public executed;

    // Whether the contract is locked to further changes
    bool public locked;

    // Upgrade contracts
    address public newRocketNodeDeposit;
    address public newRocketMinipoolDelegate;
    address public newRocketDAOProtocolSettingsMinipool;
    address public newRocketMinipoolQueue;
    address public newRocketDepositPool;
    address public newRocketDAOProtocolSettingsDeposit;
    address public newRocketMinipoolManager;
    address public newRocketNodeStaking;
    address public newRocketNodeDistributorDelegate;
    address public newRocketMinipoolFactory;
    address public newRocketNetworkFees;
    address public newRocketNetworkPrices;
    address public newRocketDAONodeTrustedSettingsMinipool;
    address public newRocketNodeManager;
    address public newRocketDAOProtocolSettingsNode;
    address public newRocketNetworkBalances;
    address public rocketMinipoolBase;
    address public rocketMinipoolBondReducer;

    // Upgrade ABIs
    string public newRocketNodeDepositAbi;
    string public newRocketMinipoolDelegateAbi;
    string public newRocketDAOProtocolSettingsMinipoolAbi;
    string public newRocketMinipoolQueueAbi;
    string public newRocketDepositPoolAbi;
    string public newRocketDAOProtocolSettingsDepositAbi;
    string public newRocketMinipoolManagerAbi;
    string public newRocketNodeStakingAbi;
    string public newRocketNodeDistributorDelegateAbi;
    string public newRocketMinipoolFactoryAbi;
    string public newRocketNetworkFeesAbi;
    string public newRocketNetworkPricesAbi;
    string public newRocketDAONodeTrustedSettingsMinipoolAbi;
    string public newRocketNodeManagerAbi;
    string public newRocketDAOProtocolSettingsNodeAbi;
    string public newRocketNetworkBalancesAbi;
    string public rocketMinipoolBaseAbi;
    string public rocketMinipoolBondReducerAbi;
    string public rocketNetworkBalancesAbi;

    string public newRocketMinipoolAbi;

    // Save deployer to limit access to set functions
    address immutable deployer;

    // Claim intervals
    ClaimInterval[] public intervals;

    // Construct
    constructor(
        RocketStorageInterface _rocketStorageAddress
    ) RocketBase(_rocketStorageAddress) {
        // Version
        version = 1;
        deployer = msg.sender;
    }

    /// @notice Returns the address of the RocketStorage contract
    function getRocketStorageAddress() external view returns (address) {
        return address(rocketStorage);
    }

    function set(address[] memory _addresses, string[] memory _abis) external {
        require(msg.sender == deployer, "Only deployer");
        require(!locked, "Contract locked");

        // Set contract addresses
        newRocketNodeDeposit = _addresses[0];
        newRocketMinipoolDelegate = _addresses[1];
        newRocketDAOProtocolSettingsMinipool = _addresses[2];
        newRocketMinipoolQueue = _addresses[3];
        newRocketDepositPool = _addresses[4];
        newRocketDAOProtocolSettingsDeposit = _addresses[5];
        newRocketMinipoolManager = _addresses[6];
        newRocketNodeStaking = _addresses[7];
        newRocketNodeDistributorDelegate = _addresses[8];
        newRocketMinipoolFactory = _addresses[9];
        newRocketNetworkFees = _addresses[10];
        newRocketNetworkPrices = _addresses[11];
        newRocketDAONodeTrustedSettingsMinipool = _addresses[12];
        newRocketNodeManager = _addresses[13];
        newRocketDAOProtocolSettingsNode = _addresses[14];
        newRocketNetworkBalances = _addresses[15];
        rocketMinipoolBase = _addresses[16];
        rocketMinipoolBondReducer = _addresses[17];

        // Set ABIs
        newRocketNodeDepositAbi = _abis[0];
        newRocketMinipoolDelegateAbi = _abis[1];
        newRocketDAOProtocolSettingsMinipoolAbi = _abis[2];
        newRocketMinipoolQueueAbi = _abis[3];
        newRocketDepositPoolAbi = _abis[4];
        newRocketDAOProtocolSettingsDepositAbi = _abis[5];
        newRocketMinipoolManagerAbi = _abis[6];
        newRocketNodeStakingAbi = _abis[7];
        newRocketNodeDistributorDelegateAbi = _abis[8];
        newRocketMinipoolFactoryAbi = _abis[9];
        newRocketNetworkFeesAbi = _abis[10];
        newRocketNetworkPricesAbi = _abis[11];
        newRocketDAONodeTrustedSettingsMinipoolAbi = _abis[12];
        newRocketNodeManagerAbi = _abis[13];
        newRocketDAOProtocolSettingsNodeAbi = _abis[14];
        newRocketNetworkBalancesAbi = _abis[15];
        rocketMinipoolBaseAbi = _abis[16];
        rocketMinipoolBondReducerAbi = _abis[17];

        newRocketMinipoolAbi = _abis[18];
    }

    function setInterval(uint256 _interval, uint256 _block) external {
        require(msg.sender == deployer, "Only deployer");
        require(!locked, "Contract locked");

        intervals.push(ClaimInterval({
            interval: _interval,
            block: _block
        }));
    }

    /// @notice Prevents further changes from being applied
    function lock() external {
        require(msg.sender == deployer, "Only deployer");
        locked = true;
    }

    /// @notice Once this contract has been voted in by oDAO, guardian can perform the upgrade
    function execute() external onlyGuardian {
        require(!executed, "Already executed");
        executed = true;

        // Upgrade contracts
        _upgradeContract("rocketNodeDeposit", newRocketNodeDeposit, newRocketNodeDepositAbi);
        _upgradeContract("rocketMinipoolDelegate", newRocketMinipoolDelegate, newRocketMinipoolDelegateAbi);
        _upgradeContract("rocketDAOProtocolSettingsMinipool", newRocketDAOProtocolSettingsMinipool, newRocketDAOProtocolSettingsMinipoolAbi);
        _upgradeContract("rocketMinipoolQueue", newRocketMinipoolQueue, newRocketMinipoolQueueAbi);
        _upgradeContract("rocketDepositPool", newRocketDepositPool, newRocketDepositPoolAbi);
        _upgradeContract("rocketDAOProtocolSettingsDeposit", newRocketDAOProtocolSettingsDeposit, newRocketDAOProtocolSettingsDepositAbi);
        _upgradeContract("rocketMinipoolManager", newRocketMinipoolManager, newRocketMinipoolManagerAbi);
        _upgradeContract("rocketNodeStaking", newRocketNodeStaking, newRocketNodeStakingAbi);
        _upgradeContract("rocketNodeDistributorDelegate", newRocketNodeDistributorDelegate, newRocketNodeDistributorDelegateAbi);
        _upgradeContract("rocketMinipoolFactory", newRocketMinipoolFactory, newRocketMinipoolFactoryAbi);
        _upgradeContract("rocketNetworkFees", newRocketNetworkFees, newRocketNetworkFeesAbi);
        _upgradeContract("rocketNetworkPrices", newRocketNetworkPrices, newRocketNetworkPricesAbi);
        _upgradeContract("rocketDAONodeTrustedSettingsMinipool", newRocketDAONodeTrustedSettingsMinipool, newRocketDAONodeTrustedSettingsMinipoolAbi);
        _upgradeContract("rocketNodeManager", newRocketNodeManager, newRocketNodeManagerAbi);
        _upgradeContract("rocketDAOProtocolSettingsNode", newRocketDAOProtocolSettingsNode, newRocketDAOProtocolSettingsNodeAbi);
        _upgradeContract("rocketNetworkBalances", newRocketNetworkBalances, newRocketNetworkBalancesAbi);

        // Add new contracts
        _addContract("rocketMinipoolBase", rocketMinipoolBase, rocketMinipoolBaseAbi);
        _addContract("rocketMinipoolBondReducer", rocketMinipoolBondReducer, rocketMinipoolBondReducerAbi);

        // Upgrade ABIs
        _upgradeABI("rocketMinipool", newRocketMinipoolAbi);

        // Migrate settings
        bytes32 settingNameSpace = keccak256(abi.encodePacked("dao.protocol.setting.", "deposit"));
        setUint(keccak256(abi.encodePacked(settingNameSpace, "deposit.assign.maximum")), 90);
        setUint(keccak256(abi.encodePacked(settingNameSpace, "deposit.assign.socialised.maximum")), 2);

        // Delete deprecated storage items
        deleteUint(keccak256("network.rpl.stake"));
        deleteUint(keccak256("network.rpl.stake.updated.block"));

        // Update node fee to 14%
        settingNameSpace = keccak256(abi.encodePacked("dao.protocol.setting.", "network"));
        setUint(keccak256(abi.encodePacked(settingNameSpace, "network.node.fee.minimum")), 0.14 ether);
        setUint(keccak256(abi.encodePacked(settingNameSpace, "network.node.fee.target")), 0.14 ether);
        setUint(keccak256(abi.encodePacked(settingNameSpace, "network.node.fee.maximum")), 0.14 ether);

        // Set new settings
        settingNameSpace = keccak256(abi.encodePacked("dao.trustednodes.setting.", "minipool"));
        setUint(keccak256(abi.encodePacked(settingNameSpace, "minipool.bond.reduction.window.start")), 2 days);
        setUint(keccak256(abi.encodePacked(settingNameSpace, "minipool.bond.reduction.window.length")), 2 days);
        setUint(keccak256(abi.encodePacked(settingNameSpace, "minipool.cancel.bond.reduction.quorum")), 0.51 ether);
        setUint(keccak256(abi.encodePacked(settingNameSpace, "minipool.promotion.scrub.period")), 3 days);
        setBool(keccak256(abi.encodePacked(settingNameSpace, "minipool.scrub.penalty.enabled")), true);
        settingNameSpace = keccak256(abi.encodePacked("dao.protocol.setting.", "minipool"));
        setUint(keccak256(abi.encodePacked(settingNameSpace, "minipool.user.distribute.window.start")), 14 days);
        setUint(keccak256(abi.encodePacked(settingNameSpace, "minipool.user.distribute.window.length")), 2 days);
        setBool(keccak256(abi.encodePacked(settingNameSpace, "minipool.bond.reduction.enabled")), false);
        setBool(keccak256(abi.encodePacked(settingNameSpace, "minipool.submit.withdrawable.enabled")), false);
        settingNameSpace = keccak256(abi.encodePacked("dao.protocol.setting.", "node"));
        setBool(keccak256(abi.encodePacked(settingNameSpace, "node.vacant.minipools.enabled")), false);

        // Claim intervals
        for (uint256 i = 0; i < intervals.length; i++) {
            ClaimInterval memory interval = intervals[i];
            setUint(keccak256(abi.encodePacked("rewards.pool.interval.execution.block", interval.interval)), interval.block);
        }
    }

    /// @dev Add a new network contract
    function _addContract(string memory _name, address _contractAddress, string memory _contractAbi) internal {
        // Check contract name
        require(bytes(_name).length > 0, "Invalid contract name");
        // Cannot add contract if it already exists (use upgradeContract instead)
        require(getAddress(keccak256(abi.encodePacked("contract.address", _name))) == address(0x0), "Contract name is already in use");
        // Cannot add contract if already in use as ABI only
        string memory existingAbi = getString(keccak256(abi.encodePacked("contract.abi", _name)));
        require(bytes(existingAbi).length == 0, "Contract name is already in use");
        // Check contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(!getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))), "Contract address is already in use");
        // Check ABI isn't empty
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Register contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
        setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
    }

    /// @dev Upgrade a network contract
    function _upgradeContract(string memory _name, address _contractAddress, string memory _contractAbi) internal {
        // Get old contract address & check contract exists
        address oldContractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _name)));
        require(oldContractAddress != address(0x0), "Contract does not exist");
        // Check new contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(_contractAddress != oldContractAddress, "The contract address cannot be set to its current address");
        require(!getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))), "Contract address is already in use");
        // Check ABI isn't empty
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        // Register new contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setString(keccak256(abi.encodePacked("contract.name", _contractAddress)), _name);
        setAddress(keccak256(abi.encodePacked("contract.address", _name)), _contractAddress);
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
        // Deregister old contract
        deleteString(keccak256(abi.encodePacked("contract.name", oldContractAddress)));
        deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
    }

    /// @dev Deletes a network contract
    function _deleteContract(string memory _name) internal {
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _name)));
        deleteString(keccak256(abi.encodePacked("contract.name", contractAddress)));
        deleteBool(keccak256(abi.encodePacked("contract.exists", contractAddress)));
        deleteAddress(keccak256(abi.encodePacked("contract.address", _name)));
        deleteString(keccak256(abi.encodePacked("contract.abi", _name)));
    }

    /// @dev Upgrade a network contract ABI
    function _upgradeABI(string memory _name, string memory _contractAbi) internal {
        // Check ABI exists
        string memory existingAbi = getString(keccak256(abi.encodePacked("contract.abi", _name)));
        require(bytes(existingAbi).length > 0, "ABI does not exist");
        // Sanity checks
        require(bytes(_contractAbi).length > 0, "Empty ABI is invalid");
        require(keccak256(bytes(existingAbi)) != keccak256(bytes(_contractAbi)), "ABIs are identical");
        // Set ABI
        setString(keccak256(abi.encodePacked("contract.abi", _name)), _contractAbi);
    }
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../RocketBase.sol";
import "../../interface/util/AddressQueueStorageInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

// Address queue storage helper for RocketStorage data (ring buffer implementation)

contract AddressQueueStorage is RocketBase, AddressQueueStorageInterface {

    // Libs
    using SafeMath for uint256;

    // Settings
    uint256 constant public capacity = 2 ** 255; // max uint256 / 2

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // The number of items in a queue
    function getLength(bytes32 _key) override public view returns (uint) {
        uint start = getUint(keccak256(abi.encodePacked(_key, ".start")));
        uint end = getUint(keccak256(abi.encodePacked(_key, ".end")));
        if (end < start) { end = end.add(capacity); }
        return end.sub(start);
    }

    // The item in a queue by index
    function getItem(bytes32 _key, uint _index) override external view returns (address) {
        uint index = getUint(keccak256(abi.encodePacked(_key, ".start"))).add(_index);
        if (index >= capacity) { index = index.sub(capacity); }
        return getAddress(keccak256(abi.encodePacked(_key, ".item", index)));
    }

    // The index of an item in a queue
    // Returns -1 if the value is not found
    function getIndexOf(bytes32 _key, address _value) override external view returns (int) {
        int index = int(getUint(keccak256(abi.encodePacked(_key, ".index", _value)))) - 1;
        if (index != -1) {
            index -= int(getUint(keccak256(abi.encodePacked(_key, ".start"))));
            if (index < 0) { index += int(capacity); }
        }
        return index;
    }

    // Add an item to the end of a queue
    // Requires that the queue is not at capacity
    // Requires that the item does not exist in the queue
    function enqueueItem(bytes32 _key, address _value) override external onlyLatestContract("addressQueueStorage", address(this)) onlyLatestNetworkContract {
        require(getLength(_key) < capacity.sub(1), "Queue is at capacity");
        require(getUint(keccak256(abi.encodePacked(_key, ".index", _value))) == 0, "Item already exists in queue");
        uint index = getUint(keccak256(abi.encodePacked(_key, ".end")));
        setAddress(keccak256(abi.encodePacked(_key, ".item", index)), _value);
        setUint(keccak256(abi.encodePacked(_key, ".index", _value)), index.add(1));
        index = index.add(1);
        if (index >= capacity) { index = index.sub(capacity); }
        setUint(keccak256(abi.encodePacked(_key, ".end")), index);
    }

    // Remove an item from the start of a queue and return it
    // Requires that the queue is not empty
    function dequeueItem(bytes32 _key) override external onlyLatestContract("addressQueueStorage", address(this)) onlyLatestNetworkContract returns (address) {
        require(getLength(_key) > 0, "Queue is empty");
        uint start = getUint(keccak256(abi.encodePacked(_key, ".start")));
        address item = getAddress(keccak256(abi.encodePacked(_key, ".item", start)));
        start = start.add(1);
        if (start >= capacity) { start = start.sub(capacity); }
        setUint(keccak256(abi.encodePacked(_key, ".index", item)), 0);
        setUint(keccak256(abi.encodePacked(_key, ".start")), start);
        return item;
    }

    // Remove an item from a queue
    // Swaps the item with the last item in the queue and truncates it; computationally cheap
    // Requires that the item exists in the queue
    function removeItem(bytes32 _key, address _value) override external onlyLatestContract("addressQueueStorage", address(this)) onlyLatestNetworkContract {
        uint index = getUint(keccak256(abi.encodePacked(_key, ".index", _value)));
        require(index-- > 0, "Item does not exist in queue");
        uint lastIndex = getUint(keccak256(abi.encodePacked(_key, ".end")));
        if (lastIndex == 0) lastIndex = capacity;
        lastIndex = lastIndex.sub(1);
        if (index != lastIndex) {
            address lastItem = getAddress(keccak256(abi.encodePacked(_key, ".item", lastIndex)));
            setAddress(keccak256(abi.encodePacked(_key, ".item", index)), lastItem);
            setUint(keccak256(abi.encodePacked(_key, ".index", lastItem)), index.add(1));
        }
        setUint(keccak256(abi.encodePacked(_key, ".index", _value)), 0);
        setUint(keccak256(abi.encodePacked(_key, ".end")), lastIndex);
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../RocketBase.sol";
import "../../interface/util/AddressSetStorageInterface.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";

// Address set storage helper for RocketStorage data (contains unique items; has reverse index lookups)

contract AddressSetStorage is RocketBase, AddressSetStorageInterface {

    using SafeMath for uint;

    // Construct
    constructor(RocketStorageInterface _rocketStorageAddress) RocketBase(_rocketStorageAddress) {
        version = 1;
    }

    // The number of items in a set
    function getCount(bytes32 _key) override external view returns (uint) {
        return getUint(keccak256(abi.encodePacked(_key, ".count")));
    }

    // The item in a set by index
    function getItem(bytes32 _key, uint _index) override external view returns (address) {
        return getAddress(keccak256(abi.encodePacked(_key, ".item", _index)));
    }

    // The index of an item in a set
    // Returns -1 if the value is not found
    function getIndexOf(bytes32 _key, address _value) override external view returns (int) {
        return int(getUint(keccak256(abi.encodePacked(_key, ".index", _value)))) - 1;
    }

    // Add an item to a set
    // Requires that the item does not exist in the set
    function addItem(bytes32 _key, address _value) override external onlyLatestContract("addressSetStorage", address(this)) onlyLatestNetworkContract {
        require(getUint(keccak256(abi.encodePacked(_key, ".index", _value))) == 0, "Item already exists in set");
        uint count = getUint(keccak256(abi.encodePacked(_key, ".count")));
        setAddress(keccak256(abi.encodePacked(_key, ".item", count)), _value);
        setUint(keccak256(abi.encodePacked(_key, ".index", _value)), count.add(1));
        setUint(keccak256(abi.encodePacked(_key, ".count")), count.add(1));
    }

    // Remove an item from a set
    // Swaps the item with the last item in the set and truncates it; computationally cheap
    // Requires that the item exists in the set
    function removeItem(bytes32 _key, address _value) override external onlyLatestContract("addressSetStorage", address(this)) onlyLatestNetworkContract {
        uint256 index = getUint(keccak256(abi.encodePacked(_key, ".index", _value)));
        require(index-- > 0, "Item does not exist in set");
        uint count = getUint(keccak256(abi.encodePacked(_key, ".count")));
        if (index < count.sub(1)) {
            address lastItem = getAddress(keccak256(abi.encodePacked(_key, ".item", count.sub(1))));
            setAddress(keccak256(abi.encodePacked(_key, ".item", index)), lastItem);
            setUint(keccak256(abi.encodePacked(_key, ".index", lastItem)), index.add(1));
        }
        setUint(keccak256(abi.encodePacked(_key, ".index", _value)), 0);
        setUint(keccak256(abi.encodePacked(_key, ".count")), count.sub(1));
    }

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketAuctionManagerInterface {
    function getTotalRPLBalance() external view returns (uint256);
    function getAllottedRPLBalance() external view returns (uint256);
    function getRemainingRPLBalance() external view returns (uint256);
    function getLotCount() external view returns (uint256);
    function getLotExists(uint256 _index) external view returns (bool);
    function getLotStartBlock(uint256 _index) external view returns (uint256);
    function getLotEndBlock(uint256 _index) external view returns (uint256);
    function getLotStartPrice(uint256 _index) external view returns (uint256);
    function getLotReservePrice(uint256 _index) external view returns (uint256);
    function getLotTotalRPLAmount(uint256 _index) external view returns (uint256);
    function getLotTotalBidAmount(uint256 _index) external view returns (uint256);
    function getLotAddressBidAmount(uint256 _index, address _bidder) external view returns (uint256);
    function getLotRPLRecovered(uint256 _index) external view returns (bool);
    function getLotPriceAtBlock(uint256 _index, uint256 _block) external view returns (uint256);
    function getLotPriceAtCurrentBlock(uint256 _index) external view returns (uint256);
    function getLotPriceByTotalBids(uint256 _index) external view returns (uint256);
    function getLotCurrentPrice(uint256 _index) external view returns (uint256);
    function getLotClaimedRPLAmount(uint256 _index) external view returns (uint256);
    function getLotRemainingRPLAmount(uint256 _index) external view returns (uint256);
    function getLotIsCleared(uint256 _index) external view returns (bool);
    function createLot() external;
    function placeBid(uint256 _lotIndex) external payable;
    function claimBid(uint256 _lotIndex) external;
    function recoverUnclaimedRPL(uint256 _lotIndex) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface DepositInterface {
    function deposit(bytes calldata _pubkey, bytes calldata _withdrawalCredentials, bytes calldata _signature, bytes32 _depositDataRoot) external payable;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedActionsInterface {
    function actionJoin() external;
    function actionJoinRequired(address _nodeAddress) external;
    function actionLeave(address _rplBondRefundAddress) external;
    function actionKick(address _nodeAddress, uint256 _rplFine) external;
    function actionChallengeMake(address _nodeAddress) external payable;
    function actionChallengeDecide(address _nodeAddress) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedInterface {
    function getBootstrapModeDisabled() external view returns (bool);
    function getMemberQuorumVotesRequired() external view returns (uint256);
    function getMemberAt(uint256 _index) external view returns (address);
    function getMemberCount() external view returns (uint256);
    function getMemberMinRequired() external view returns (uint256);
    function getMemberIsValid(address _nodeAddress) external view returns (bool);
    function getMemberLastProposalTime(address _nodeAddress) external view returns (uint256);
    function getMemberID(address _nodeAddress) external view returns (string memory);
    function getMemberUrl(address _nodeAddress) external view returns (string memory);
    function getMemberJoinedTime(address _nodeAddress) external view returns (uint256);
    function getMemberProposalExecutedTime(string memory _proposalType, address _nodeAddress) external view returns (uint256);
    function getMemberRPLBondAmount(address _nodeAddress) external view returns (uint256);
    function getMemberIsChallenged(address _nodeAddress) external view returns (bool);
    function getMemberUnbondedValidatorCount(address _nodeAddress) external view returns (uint256);
    function incrementMemberUnbondedValidatorCount(address _nodeAddress) external;
    function decrementMemberUnbondedValidatorCount(address _nodeAddress) external;
    function bootstrapMember(string memory _id, string memory _url, address _nodeAddress) external;
    function bootstrapSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) external;
    function bootstrapSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) external;
    function bootstrapUpgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) external;
    function bootstrapDisable(bool _confirmDisableBootstrapMode) external;
    function memberJoinRequired(string memory _id, string memory _url) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedProposalsInterface {
    function propose(string memory _proposalMessage, bytes memory _payload) external returns (uint256);
    function vote(uint256 _proposalID, bool _support) external;
    function cancel(uint256 _proposalID) external;
    function execute(uint256 _proposalID) external;
    function proposalInvite(string memory _id, string memory _url, address _nodeAddress) external;
    function proposalLeave(address _nodeAddress) external;
    function proposalKick(address _nodeAddress, uint256 _rplFine) external;
    function proposalSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) external;
    function proposalSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) external;
    function proposalUpgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedUpgradeInterface {
    function upgrade(string memory _type, string memory _name, string memory _contractAbi, address _contractAddress) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedSettingsInterface {
    function getSettingUint(string memory _settingPath) external view returns (uint256);
    function setSettingUint(string memory _settingPath, uint256 _value) external;
    function getSettingBool(string memory _settingPath) external view returns (bool);
    function setSettingBool(string memory _settingPath, bool _value) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedSettingsMembersInterface {
    function getQuorum() external view returns (uint256);
    function getRPLBond() external view returns(uint256);
    function getMinipoolUnbondedMax() external view returns(uint256);
    function getMinipoolUnbondedMinFee() external view returns(uint256);
    function getChallengeCooldown() external view returns(uint256);
    function getChallengeWindow() external view returns(uint256);
    function getChallengeCost() external view returns(uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedSettingsMinipoolInterface {
    function getScrubPeriod() external view returns(uint256);
    function getPromotionScrubPeriod() external view returns(uint256);
    function getScrubQuorum() external view returns(uint256);
    function getCancelBondReductionQuorum() external view returns(uint256);
    function getScrubPenaltyEnabled() external view returns(bool);
    function isWithinBondReductionWindow(uint256 _time) external view returns (bool);
    function getBondReductionWindowStart() external view returns (uint256);
    function getBondReductionWindowLength() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedSettingsProposalsInterface {
    function getCooldownTime() external view returns(uint256);
    function getVoteTime() external view returns(uint256);
    function getVoteDelayTime() external view returns(uint256);
    function getExecuteTime() external view returns(uint256);
    function getActionTime() external view returns(uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAONodeTrustedSettingsRewardsInterface {
    function getNetworkEnabled(uint256 _network) external view returns (bool);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolActionsInterface {

}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;
pragma abicoder v2;

import "../../../types/SettingType.sol";

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolInterface {
    function getBootstrapModeDisabled() external view returns (bool);
    function bootstrapSettingMulti(string[] memory _settingContractNames, string[] memory _settingPaths, SettingType[] memory _types, bytes[] memory _values) external;
    function bootstrapSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) external;
    function bootstrapSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) external;
    function bootstrapSettingAddress(string memory _settingContractName, string memory _settingPath, address _value) external;
    function bootstrapSettingClaimer(string memory _contractName, uint256 _perc) external;
    function bootstrapSpendTreasury(string memory _invoiceID, address _recipientAddress, uint256 _amount) external;
    function bootstrapDisable(bool _confirmDisableBootstrapMode) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;
pragma abicoder v2;

import "../../../types/SettingType.sol";

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolProposalsInterface {
    function proposalSettingMulti(string[] memory _settingContractNames, string[] memory _settingPaths, SettingType[] memory _types, bytes[] memory _data) external;
    function proposalSettingUint(string memory _settingContractName, string memory _settingPath, uint256 _value) external;
    function proposalSettingBool(string memory _settingContractName, string memory _settingPath, bool _value) external;
    function proposalSettingAddress(string memory _settingContractName, string memory _settingPath, address _value) external;
    function proposalSettingRewardsClaimer(string memory _contractName, uint256 _perc) external;
    function proposalSpendTreasury(string memory _invoiceID, address _recipientAddress, uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsAuctionInterface {
    function getCreateLotEnabled() external view returns (bool);
    function getBidOnLotEnabled() external view returns (bool);
    function getLotMinimumEthValue() external view returns (uint256);
    function getLotMaximumEthValue() external view returns (uint256);
    function getLotDuration() external view returns (uint256);
    function getStartingPriceRatio() external view returns (uint256);
    function getReservePriceRatio() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsDepositInterface {
    function getDepositEnabled() external view returns (bool);
    function getAssignDepositsEnabled() external view returns (bool);
    function getMinimumDeposit() external view returns (uint256);
    function getMaximumDepositPoolSize() external view returns (uint256);
    function getMaximumDepositAssignments() external view returns (uint256);
    function getMaximumDepositSocialisedAssignments() external view returns (uint256);
    function getDepositFee() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsInflationInterface {
    function getInflationIntervalRate() external view returns (uint256);
    function getInflationIntervalStartTime() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsInterface {
    function getSettingUint(string memory _settingPath) external view returns (uint256);
    function setSettingUint(string memory _settingPath, uint256 _value) external;
    function getSettingBool(string memory _settingPath) external view returns (bool);
    function setSettingBool(string memory _settingPath, bool _value) external;
    function getSettingAddress(string memory _settingPath) external view returns (address);
    function setSettingAddress(string memory _settingPath, address _value) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../../../../types/MinipoolDeposit.sol";

interface RocketDAOProtocolSettingsMinipoolInterface {
    function getLaunchBalance() external view returns (uint256);
    function getPreLaunchValue() external pure returns (uint256);
    function getDepositUserAmount(MinipoolDeposit _depositType) external view returns (uint256);
    function getFullDepositUserAmount() external view returns (uint256);
    function getHalfDepositUserAmount() external view returns (uint256);
    function getVariableDepositAmount() external view returns (uint256);
    function getSubmitWithdrawableEnabled() external view returns (bool);
    function getBondReductionEnabled() external view returns (bool);
    function getLaunchTimeout() external view returns (uint256);
    function getMaximumCount() external view returns (uint256);
    function isWithinUserDistributeWindow(uint256 _time) external view returns (bool);
    function hasUserDistributeWindowPassed(uint256 _time) external view returns (bool);
    function getUserDistributeWindowStart() external view returns (uint256);
    function getUserDistributeWindowLength() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsNetworkInterface {
    function getNodeConsensusThreshold() external view returns (uint256);
    function getNodePenaltyThreshold() external view returns (uint256);
    function getPerPenaltyRate() external view returns (uint256);
    function getSubmitBalancesEnabled() external view returns (bool);
    function getSubmitBalancesFrequency() external view returns (uint256);
    function getSubmitPricesEnabled() external view returns (bool);
    function getSubmitPricesFrequency() external view returns (uint256);
    function getMinimumNodeFee() external view returns (uint256);
    function getTargetNodeFee() external view returns (uint256);
    function getMaximumNodeFee() external view returns (uint256);
    function getNodeFeeDemandRange() external view returns (uint256);
    function getTargetRethCollateralRate() external view returns (uint256);
    function getRethDepositDelay() external view returns (uint256);
    function getSubmitRewardsEnabled() external view returns (bool);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsNodeInterface {
    function getRegistrationEnabled() external view returns (bool);
    function getSmoothingPoolRegistrationEnabled() external view returns (bool);
    function getDepositEnabled() external view returns (bool);
    function getVacantMinipoolsEnabled() external view returns (bool);
    function getMinimumPerMinipoolStake() external view returns (uint256);
    function getMaximumPerMinipoolStake() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProtocolSettingsRewardsInterface {
    function setSettingRewardsClaimer(string memory _contractName, uint256 _perc) external;
    function getRewardsClaimerPerc(string memory _contractName) external view returns (uint256);
    function getRewardsClaimerPercTimeUpdated(string memory _contractName) external view returns (uint256);
    function getRewardsClaimersPercTotal() external view returns (uint256);
    function getRewardsClaimIntervalTime() external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDAOProposalInterface {

    // Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Cancelled,
        Defeated,
        Succeeded,
        Expired,
        Executed
    }

    function getTotal() external view returns (uint256);
    function getDAO(uint256 _proposalID) external view returns (string memory);
    function getProposer(uint256 _proposalID) external view returns (address);
    function getMessage(uint256 _proposalID) external view returns (string memory);
    function getStart(uint256 _proposalID) external view returns (uint256);
    function getEnd(uint256 _proposalID) external view returns (uint256);
    function getExpires(uint256 _proposalID) external view returns (uint256);
    function getCreated(uint256 _proposalID) external view returns (uint256);
    function getVotesFor(uint256 _proposalID) external view returns (uint256);
    function getVotesAgainst(uint256 _proposalID) external view returns (uint256);
    function getVotesRequired(uint256 _proposalID) external view returns (uint256);
    function getCancelled(uint256 _proposalID) external view returns (bool);
    function getExecuted(uint256 _proposalID) external view returns (bool);
    function getPayload(uint256 _proposalID) external view returns (bytes memory);
    function getReceiptHasVoted(uint256 _proposalID, address _nodeAddress) external view returns (bool);
    function getReceiptSupported(uint256 _proposalID, address _nodeAddress) external view returns (bool);
    function getState(uint256 _proposalID) external view returns (ProposalState);
    function add(address _member, string memory _dao, string memory _message, uint256 _startBlock, uint256 _durationBlocks, uint256 _expiresBlocks, uint256 _votesRequired, bytes memory _payload) external returns (uint256);
    function vote(address _member, uint256 _votes, uint256 _proposalID, bool _support) external; 
    function cancel(address _member, uint256 _proposalID) external;
    function execute(uint256 _proposalID) external;
    
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketDepositPoolInterface {
    function getBalance() external view returns (uint256);
    function getNodeBalance() external view returns (uint256);
    function getUserBalance() external view returns (int256);
    function getExcessBalance() external view returns (uint256);
    function deposit() external payable;
    function getMaximumDepositAmount() external view returns (uint256);
    function nodeDeposit(uint256 _totalAmount) external payable;
    function nodeCreditWithdrawal(uint256 _amount) external;
    function recycleDissolvedDeposit() external payable;
    function recycleExcessCollateral() external payable;
    function recycleLiquidatedStake() external payable;
    function assignDeposits() external;
    function maybeAssignDeposits() external returns (bool);
    function withdrawExcessBalance(uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketMinipoolBaseInterface {
    function initialise(address _rocketStorage, address _nodeAddress) external;
    function delegateUpgrade() external;
    function delegateRollback() external;
    function setUseLatestDelegate(bool _setting) external;
    function getUseLatestDelegate() external view returns (bool);
    function getDelegate() external view returns (address);
    function getPreviousDelegate() external view returns (address);
    function getEffectiveDelegate() external view returns (address);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >0.5.0 <0.9.0;
pragma abicoder v2;

interface RocketMinipoolBondReducerInterface {
    function beginReduceBondAmount(address _minipoolAddress, uint256 _newBondAmount) external;
    function getReduceBondTime(address _minipoolAddress) external view returns (uint256);
    function getReduceBondValue(address _minipoolAddress) external view returns (uint256);
    function getReduceBondCancelled(address _minipoolAddress) external view returns (bool);
    function canReduceBondAmount(address _minipoolAddress) external view returns (bool);
    function voteCancelReduction(address _minipoolAddress) external;
    function reduceBondAmount() external returns (uint256);
    function getLastBondReductionTime(address _minipoolAddress) external view returns (uint256);
    function getLastBondReductionPrevValue(address _minipoolAddress) external view returns (uint256);
    function getLastBondReductionPrevNodeFee(address _minipoolAddress) external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/MinipoolDeposit.sol";

interface RocketMinipoolFactoryInterface {
    function getExpectedAddress(address _nodeAddress, uint256 _salt) external view returns (address);
    function deployContract(address _nodeAddress, uint256 _salt) external returns (address);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/MinipoolDeposit.sol";
import "../../types/MinipoolStatus.sol";
import "../RocketStorageInterface.sol";

interface RocketMinipoolInterface {
    function version() external view returns (uint8);
    function initialise(address _nodeAddress) external;
    function getStatus() external view returns (MinipoolStatus);
    function getFinalised() external view returns (bool);
    function getStatusBlock() external view returns (uint256);
    function getStatusTime() external view returns (uint256);
    function getScrubVoted(address _member) external view returns (bool);
    function getDepositType() external view returns (MinipoolDeposit);
    function getNodeAddress() external view returns (address);
    function getNodeFee() external view returns (uint256);
    function getNodeDepositBalance() external view returns (uint256);
    function getNodeRefundBalance() external view returns (uint256);
    function getNodeDepositAssigned() external view returns (bool);
    function getPreLaunchValue() external view returns (uint256);
    function getNodeTopUpValue() external view returns (uint256);
    function getVacant() external view returns (bool);
    function getPreMigrationBalance() external view returns (uint256);
    function getUserDistributed() external view returns (bool);
    function getUserDepositBalance() external view returns (uint256);
    function getUserDepositAssigned() external view returns (bool);
    function getUserDepositAssignedTime() external view returns (uint256);
    function getTotalScrubVotes() external view returns (uint256);
    function calculateNodeShare(uint256 _balance) external view returns (uint256);
    function calculateUserShare(uint256 _balance) external view returns (uint256);
    function preDeposit(uint256 _bondingValue, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot) external payable;
    function deposit() external payable;
    function userDeposit() external payable;
    function distributeBalance() external;
    function beginUserDistribute() external;
    function userDistributeAllowed() external view returns (bool);
    function refund() external;
    function slash() external;
    function finalise() external;
    function canStake() external view returns (bool);
    function canPromote() external view returns (bool);
    function stake(bytes calldata _validatorSignature, bytes32 _depositDataRoot) external;
    function prepareVacancy(uint256 _bondAmount, uint256 _currentBalance) external;
    function promote() external;
    function dissolve() external;
    function close() external;
    function voteScrub() external;
    function reduceBondAmount() external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/MinipoolDeposit.sol";
import "../../types/MinipoolDetails.sol";
import "./RocketMinipoolInterface.sol";

interface RocketMinipoolManagerInterface {
    function getMinipoolCount() external view returns (uint256);
    function getStakingMinipoolCount() external view returns (uint256);
    function getFinalisedMinipoolCount() external view returns (uint256);
    function getActiveMinipoolCount() external view returns (uint256);
    function getMinipoolRPLSlashed(address _minipoolAddress) external view returns (bool);
    function getMinipoolCountPerStatus(uint256 offset, uint256 limit) external view returns (uint256, uint256, uint256, uint256, uint256);
    function getPrelaunchMinipools(uint256 offset, uint256 limit) external view returns (address[] memory);
    function getMinipoolAt(uint256 _index) external view returns (address);
    function getNodeMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeActiveMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeFinalisedMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeStakingMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeStakingMinipoolCountBySize(address _nodeAddress, uint256 _depositSize) external view returns (uint256);
    function getNodeMinipoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getNodeValidatingMinipoolCount(address _nodeAddress) external view returns (uint256);
    function getNodeValidatingMinipoolAt(address _nodeAddress, uint256 _index) external view returns (address);
    function getMinipoolByPubkey(bytes calldata _pubkey) external view returns (address);
    function getMinipoolExists(address _minipoolAddress) external view returns (bool);
    function getMinipoolDestroyed(address _minipoolAddress) external view returns (bool);
    function getMinipoolPubkey(address _minipoolAddress) external view returns (bytes memory);
    function updateNodeStakingMinipoolCount(uint256 _previousBond, uint256 _newBond, uint256 _previousFee, uint256 _newFee) external;
    function getMinipoolWithdrawalCredentials(address _minipoolAddress) external pure returns (bytes memory);
    function createMinipool(address _nodeAddress, uint256 _salt) external returns (RocketMinipoolInterface);
    function createVacantMinipool(address _nodeAddress, uint256 _salt, bytes calldata _validatorPubkey, uint256 _bondAmount, uint256 _currentBalance) external returns (RocketMinipoolInterface);
    function removeVacantMinipool() external;
    function getVacantMinipoolCount() external view returns (uint256);
    function getVacantMinipoolAt(uint256 _index) external view returns (address);
    function destroyMinipool() external;
    function incrementNodeStakingMinipoolCount(address _nodeAddress) external;
    function decrementNodeStakingMinipoolCount(address _nodeAddress) external;
    function incrementNodeFinalisedMinipoolCount(address _nodeAddress) external;
    function setMinipoolPubkey(bytes calldata _pubkey) external;
    function getMinipoolDetails(address _minipoolAddress) external view returns (MinipoolDetails memory);
    function getMinipoolDepositType(address _minipoolAddress) external view returns (MinipoolDeposit);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketMinipoolPenaltyInterface {
    // Max penalty rate
    function setMaxPenaltyRate(uint256 _rate) external;
    function getMaxPenaltyRate() external view returns (uint256);

    // Penalty rate
    function setPenaltyRate(address _minipoolAddress, uint256 _rate) external;
    function getPenaltyRate(address _minipoolAddress) external view returns(uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/MinipoolDeposit.sol";

interface RocketMinipoolQueueInterface {
    function getTotalLength() external view returns (uint256);
    function getContainsLegacy() external view returns (bool);
    function getLengthLegacy(MinipoolDeposit _depositType) external view returns (uint256);
    function getLength() external view returns (uint256);
    function getTotalCapacity() external view returns (uint256);
    function getEffectiveCapacity() external view returns (uint256);
    function getNextCapacityLegacy() external view returns (uint256);
    function getNextDepositLegacy() external view returns (MinipoolDeposit, uint256);
    function enqueueMinipool(address _minipool) external;
    function dequeueMinipoolByDepositLegacy(MinipoolDeposit _depositType) external returns (address minipoolAddress);
    function dequeueMinipools(uint256 _maxToDequeue) external returns (address[] memory minipoolAddress);
    function removeMinipool(MinipoolDeposit _depositType) external;
    function getMinipoolAt(uint256 _index) external view returns(address);
    function getMinipoolPosition(address _minipool) external view returns (int256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNetworkBalancesInterface {
    function getBalancesBlock() external view returns (uint256);
    function getLatestReportableBlock() external view returns (uint256);
    function getTotalETHBalance() external view returns (uint256);
    function getStakingETHBalance() external view returns (uint256);
    function getTotalRETHSupply() external view returns (uint256);
    function getETHUtilizationRate() external view returns (uint256);
    function submitBalances(uint256 _block, uint256 _total, uint256 _staking, uint256 _rethSupply) external;
    function executeUpdateBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _rethSupply) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNetworkFeesInterface {
    function getNodeDemand() external view returns (int256);
    function getNodeFee() external view returns (uint256);
    function getNodeFeeByDemand(int256 _nodeDemand) external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNetworkPenaltiesInterface {
    function submitPenalty(address _minipoolAddress, uint256 _block) external;
    function executeUpdatePenalty(address _minipoolAddress, uint256 _block) external;
    function getPenaltyCount(address _minipoolAddress) external view returns (uint256);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNetworkPricesInterface {
    function getPricesBlock() external view returns (uint256);
    function getRPLPrice() external view returns (uint256);
    function getLatestReportableBlock() external view returns (uint256);
    function submitPrices(uint256 _block, uint256 _rplPrice) external;
    function executeUpdatePrices(uint256 _block, uint256 _rplPrice) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/MinipoolDeposit.sol";

interface RocketNodeDepositInterface {
    function getNodeDepositCredit(address _nodeOperator) external view returns (uint256);
    function increaseDepositCreditBalance(address _nodeOperator, uint256 _amount) external;
    function deposit(uint256 _depositAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) external payable;
    function depositWithCredit(uint256 _depositAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, bytes calldata _validatorSignature, bytes32 _depositDataRoot, uint256 _salt, address _expectedMinipoolAddress) external payable;
    function isValidDepositAmount(uint256 _amount) external pure returns (bool);
    function getDepositAmounts() external pure returns (uint256[] memory);
    function createVacantMinipool(uint256 _bondAmount, uint256 _minimumNodeFee, bytes calldata _validatorPubkey, uint256 _salt, address _expectedMinipoolAddress, uint256 _currentBalance) external;
    function increaseEthMatched(address _nodeAddress, uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNodeDistributorFactoryInterface {
    function getProxyBytecode() external pure returns (bytes memory);
    function getProxyAddress(address _nodeAddress) external view returns(address);
    function createProxy(address _nodeAddress) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNodeDistributorInterface {
    function getNodeShare() external view returns (uint256);
    function getUserShare() external view returns (uint256);
    function distribute() external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/NodeDetails.sol";

interface RocketNodeManagerInterface {

    // Structs
    struct TimezoneCount {
        string timezone;
        uint256 count;
    }

    function getNodeCount() external view returns (uint256);
    function getNodeCountPerTimezone(uint256 offset, uint256 limit) external view returns (TimezoneCount[] memory);
    function getNodeAt(uint256 _index) external view returns (address);
    function getNodeExists(address _nodeAddress) external view returns (bool);
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodeTimezoneLocation(address _nodeAddress) external view returns (string memory);
    function registerNode(string calldata _timezoneLocation) external;
    function getNodeRegistrationTime(address _nodeAddress) external view returns (uint256);
    function setTimezoneLocation(string calldata _timezoneLocation) external;
    function setRewardNetwork(address _nodeAddress, uint256 network) external;
    function getRewardNetwork(address _nodeAddress) external view returns (uint256);
    function getFeeDistributorInitialised(address _nodeAddress) external view returns (bool);
    function initialiseFeeDistributor() external;
    function getAverageNodeFee(address _nodeAddress) external view returns (uint256);
    function setSmoothingPoolRegistrationState(bool _state) external;
    function getSmoothingPoolRegistrationState(address _nodeAddress) external returns (bool);
    function getSmoothingPoolRegistrationChanged(address _nodeAddress) external returns (uint256);
    function getSmoothingPoolRegisteredNodeCount(uint256 _offset, uint256 _limit) external view returns (uint256);
    function getNodeDetails(address _nodeAddress) external view returns (NodeDetails memory);
    function getNodeAddresses(uint256 _offset, uint256 _limit) external view returns (address[] memory);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketNodeStakingInterface {
    function getTotalRPLStake() external view returns (uint256);
    function getNodeRPLStake(address _nodeAddress) external view returns (uint256);
    function getNodeETHMatched(address _nodeAddress) external view returns (uint256);
    function getNodeETHProvided(address _nodeAddress) external view returns (uint256);
    function getNodeETHCollateralisationRatio(address _nodeAddress) external view returns (uint256);
    function getNodeRPLStakedTime(address _nodeAddress) external view returns (uint256);
    function getNodeEffectiveRPLStake(address _nodeAddress) external view returns (uint256);
    function getNodeMinimumRPLStake(address _nodeAddress) external view returns (uint256);
    function getNodeMaximumRPLStake(address _nodeAddress) external view returns (uint256);
    function getNodeETHMatchedLimit(address _nodeAddress) external view returns (uint256);
    function stakeRPL(uint256 _amount) external;
    function stakeRPLFor(address _nodeAddress, uint256 _amount) external;
    function setStakeRPLForAllowed(address _caller, bool _allowed) external;
    function withdrawRPL(uint256 _amount) external;
    function slashRPL(address _nodeAddress, uint256 _ethSlashAmount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketClaimDAOInterface {
    function spend(string memory _invoiceID, address _recipientAddress, uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketClaimNodeInterface {
    function getEnabled() external view returns (bool);
    function getClaimPossible(address _nodeAddress) external view returns (bool);
    function getClaimRewardsPerc(address _nodeAddress) external view returns (uint256);
    function getClaimRewardsAmount(address _nodeAddress) external view returns (uint256);
    function register(address _nodeAddress, bool _enable) external;
    function claim() external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketClaimTrustedNodeInterface {
    function getEnabled() external view returns (bool);
    function getClaimPossible(address _trustedNodeAddress) external view returns (bool);
    function getClaimRewardsPerc(address _trustedNodeAddress) external view returns (uint256);
    function getClaimRewardsAmount(address _trustedNodeAddress) external view returns (uint256);
    function register(address _trustedNode, bool _enable) external;
    function claim() external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;
pragma abicoder v2;

import "../../types/RewardSubmission.sol";

// SPDX-License-Identifier: GPL-3.0-only

interface RocketRewardsPoolInterface {
    function getRewardIndex() external view returns(uint256);
    function getRPLBalance() external view returns(uint256);
    function getPendingRPLRewards() external view returns (uint256);
    function getPendingETHRewards() external view returns (uint256);
    function getClaimIntervalTimeStart() external view returns(uint256);
    function getClaimIntervalTime() external view returns(uint256);
    function getClaimIntervalsPassed() external view returns(uint256);
    function getClaimIntervalExecutionBlock(uint256 _interval) external view returns(uint256);
    function getClaimingContractPerc(string memory _claimingContract) external view returns(uint256);
    function getClaimingContractsPerc(string[] memory _claimingContracts) external view returns (uint256[] memory);
    function getTrustedNodeSubmitted(address _trustedNodeAddress, uint256 _rewardIndex) external view returns (bool);
    function getSubmissionCount(RewardSubmission calldata _submission) external view returns (uint256);
    function submitRewardSnapshot(RewardSubmission calldata _submission) external;
    function executeRewardSnapshot(RewardSubmission calldata _submission) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketRewardsRelayInterface {
    function relayRewards(uint256 _intervalIndex, bytes32 _merkleRoot, uint256 _rewardsRPL, uint256 _rewardsETH) external;
    function claim(address _nodeAddress, uint256[] calldata _intervalIndex, uint256[] calldata _amountRPL, uint256[] calldata _amountETH, bytes32[][] calldata _merkleProof) external;
    function claimAndStake(address _nodeAddress, uint256[] calldata _intervalIndex, uint256[] calldata _amountRPL, uint256[] calldata _amountETH, bytes32[][] calldata _merkleProof, uint256 _stakeAmount) external;
    function isClaimed(uint256 _intervalIndex, address _claimer) external view returns (bool);
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketSmoothingPoolInterface {
    function withdrawEther(address _to, uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketStorageInterface {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;

    // Protected storage
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

interface RocketVaultInterface {
    function balanceOf(string memory _networkContractName) external view returns (uint256);
    function depositEther() external payable;
    function withdrawEther(uint256 _amount) external;
    function depositToken(string memory _networkContractName, IERC20 _tokenAddress, uint256 _amount) external;
    function withdrawToken(address _withdrawalAddress, IERC20 _tokenAddress, uint256 _amount) external;
    function balanceOfToken(string memory _networkContractName, IERC20 _tokenAddress) external view returns (uint256);
    function transferToken(string memory _networkContractName, IERC20 _tokenAddress, uint256 _amount) external;
    function burnToken(ERC20Burnable _tokenAddress, uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface RocketVaultWithdrawerInterface {
    function receiveVaultWithdrawalETH() external payable; 
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RocketTokenRETHInterface is IERC20 {
    function getEthValue(uint256 _rethAmount) external view returns (uint256);
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
    function getExchangeRate() external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getCollateralRate() external view returns (uint256);
    function depositExcess() external payable;
    function depositExcessCollateral() external;
    function mint(uint256 _ethAmount, address _to) external;
    function burn(uint256 _rethAmount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface RocketTokenRPLInterface is IERC20 {
    function getInflationCalcTime() external view returns(uint256);
    function getInflationIntervalTime() external view returns(uint256);
    function getInflationIntervalRate() external view returns(uint256);
    function getInflationIntervalsPassed() external view returns(uint256);
    function getInflationIntervalStartTime() external view returns(uint256);
    function getInflationRewardsContractAddress() external view returns(address);
    function inflationCalculate() external view returns (uint256);
    function inflationMintTokens() external returns (uint256);
    function swapTokens(uint256 _amount) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface AddressQueueStorageInterface {
    function getLength(bytes32 _key) external view returns (uint);
    function getItem(bytes32 _key, uint _index) external view returns (address);
    function getIndexOf(bytes32 _key, address _value) external view returns (int);
    function enqueueItem(bytes32 _key, address _value) external;
    function dequeueItem(bytes32 _key) external returns (address);
    function removeItem(bytes32 _key, address _value) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity >0.5.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

interface AddressSetStorageInterface {
    function getCount(bytes32 _key) external view returns (uint);
    function getItem(bytes32 _key, uint _index) external view returns (address);
    function getIndexOf(bytes32 _key, address _value) external view returns (int);
    function addItem(bytes32 _key, address _value) external;
    function removeItem(bytes32 _key, address _value) external;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

// Represents the type of deposits required by a minipool

enum MinipoolDeposit {
    None,       // Marks an invalid deposit type
    Full,       // The minipool requires 32 ETH from the node operator, 16 ETH of which will be refinanced from user deposits
    Half,       // The minipool required 16 ETH from the node operator to be matched with 16 ETH from user deposits
    Empty,      // The minipool requires 0 ETH from the node operator to be matched with 32 ETH from user deposits (trusted nodes only)
    Variable    // Indicates this minipool is of the new generation that supports a variable deposit amount
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "./MinipoolDeposit.sol";
import "./MinipoolStatus.sol";

// A struct containing all the information on-chain about a specific minipool

struct MinipoolDetails {
    bool exists;
    address minipoolAddress;
    bytes pubkey;
    MinipoolStatus status;
    uint256 statusBlock;
    uint256 statusTime;
    bool finalised;
    MinipoolDeposit depositType;
    uint256 nodeFee;
    uint256 nodeDepositBalance;
    bool nodeDepositAssigned;
    uint256 userDepositBalance;
    bool userDepositAssigned;
    uint256 userDepositAssignedTime;
    bool useLatestDelegate;
    address delegate;
    address previousDelegate;
    address effectiveDelegate;
    uint256 penaltyCount;
    uint256 penaltyRate;
    address nodeAddress;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

// Represents a minipool's status within the network

enum MinipoolStatus {
    Initialised,    // The minipool has been initialised and is awaiting a deposit of user ETH
    Prelaunch,      // The minipool has enough ETH to begin staking and is awaiting launch by the node operator
    Staking,        // The minipool is currently staking
    Withdrawable,   // NO LONGER USED
    Dissolved       // The minipool has been dissolved and its user deposited ETH has been returned to the deposit pool
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

// A struct containing all the information on-chain about a specific node

struct NodeDetails {
    bool exists;
    uint256 registrationTime;
    string timezoneLocation;
    bool feeDistributorInitialised;
    address feeDistributorAddress;
    uint256 rewardNetwork;
    uint256 rplStake;
    uint256 effectiveRPLStake;
    uint256 minimumRPLStake;
    uint256 maximumRPLStake;
    uint256 ethMatched;
    uint256 ethMatchedLimit;
    uint256 minipoolCount;
    uint256 balanceETH;
    uint256 balanceRETH;
    uint256 balanceRPL;
    uint256 balanceOldRPL;
    uint256 depositCreditBalance;
    uint256 distributorBalanceUserETH;
    uint256 distributorBalanceNodeETH;
    address withdrawalAddress;
    address pendingWithdrawalAddress;
    bool smoothingPoolRegistrationState;
    uint256 smoothingPoolRegistrationChanged;
    address nodeAddress;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

struct RewardSubmission {
    uint256 rewardIndex;
    uint256 executionBlock;
    uint256 consensusBlock;
    bytes32 merkleRoot;
    string merkleTreeCID;
    uint256 intervalsPassed;
    uint256 treasuryRPL;
    uint256[] trustedNodeRPL;
    uint256[] nodeRPL;
    uint256[] nodeETH;
    uint256 userETH;
}

/**
  *       .
  *      / \
  *     |.'.|
  *     |'.'|
  *   ,'|   |`.
  *  |,-'-|-'-.|
  *   __|_| |         _        _      _____           _
  *  | ___ \|        | |      | |    | ___ \         | |
  *  | |_/ /|__   ___| | _____| |_   | |_/ /__   ___ | |
  *  |    // _ \ / __| |/ / _ \ __|  |  __/ _ \ / _ \| |
  *  | |\ \ (_) | (__|   <  __/ |_   | | | (_) | (_) | |
  *  \_| \_\___/ \___|_|\_\___|\__|  \_|  \___/ \___/|_|
  * +---------------------------------------------------+
  * |  DECENTRALISED STAKING PROTOCOL FOR ETHEREUM 2.0  |
  * +---------------------------------------------------+
  *
  *  Rocket Pool is a first-of-its-kind ETH2 Proof of Stake protocol, designed to be community owned,
  *  decentralised, trustless and compatible with staking in Ethereum 2.0.
  *
  *  For more information about Rocket Pool, visit https://rocketpool.net
  *
  *  Authors: David Rugendyke, Jake Pospischil, Kane Wallmann, Darren Langley, Joe Clapis, Nick Doherty
  *
  */

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

enum SettingType {
  UINT256,
  BOOL,
  ADDRESS,
  STRING,
  BYTES,
  BYTES32,
  INT256
}