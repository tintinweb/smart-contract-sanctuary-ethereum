/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

/**
 * MuskATears is a meme project that tells the tale of a courageous blue baby bird named Tweeter 
 * and her battle against the evil lords of Twitter-land. With the help of Elon Musk and the MuskATears, 
 * Tweeter fights tirelessly against censorship and suppression, ultimately triumphing and ushering in a 
 * new era of creativity, unity, and free expression. Join us in our quest for a censorship-free world!
 */

// Social media links:
// Website: https://www.muskatears.com
// Twitter: https://twitter.com/MuskATears      // Follow us for memes, updates, and Elon Musk sightings!
// Telegram: https://t.me/MuskATearsChat        // Join our community of brave Tweeters and MuskATears!
// Discord: https://discord.gg/MuskATears       // Discuss the fight against censorship with like-minded individuals!
// TikTok: https://www.tiktok.com/@muskatears1   // Watch our memes and join the fun!


// Smart Contract: 0xe97b0De35ac2F4d0eA76a770871eb806f14400f1



// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol


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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


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



// File: contracts/MuskATears.sol

pragma solidity ^0.8.0;

contract MuskATears is ERC20, ERC20Burnable, Ownable {
    // Set the initial supply of the token
    uint256 private constant INITIAL_SUPPLY = 69_000_000_000 * 10**18;

    /* Addresses for the founders, marketing, and community distribution
    * NOTE: For distribution info check: https://docs.muskatears.com/tokenomics/token-distribution
    * NOTE: LP allocations will stay in contract owners address to ensure buyback with fees and burn to zero address
    * NOTE: Hard coded address values based on tokenomics and distributed to early investors
    */
    address private constant FOUNDERS_ADDRESS = 0x1A17bf5454319715912107354c1333A85BC348ef; 
    address private constant MARKETING_ADDRESS = 0xF5bd78Bf36b89386B4952a6848846BBa35598F15;
    // Community Allocation Addresses
    address private constant COMMUNITY_ADDRESS_1 = 0x14bE8d726Eb8d53494B27481449bDADbA78fb3D0; // * 0.2
    address private constant COMMUNITY_ADDRESS_2 = 0xDC9FCf69034bF5d30fb69a7ACB65ba2152667003; // * 1
    address private constant COMMUNITY_ADDRESS_3 = 0x24E68e5450E8dB86764E671501cbC852C140cF30; // * 1
    address private constant COMMUNITY_ADDRESS_4 = 0xD57876025d3D18C5062A93A32EEeaE0062c54738; // * 0.6
    address private constant COMMUNITY_ADDRESS_5 = 0x7ecbb34675EEDFbd7e6963B3B8287263Ad1Fa1b9; // * 0.1
    address private constant COMMUNITY_ADDRESS_6 = 0x9E38d4F7e7Cf7aF3f72E25351f9c15DeF6159284; // * 1
    address private constant COMMUNITY_ADDRESS_7 = 0x26d1FCd0a4C9191D027E835F8CFFc2696758D00b; // * 1 
    address private constant COMMUNITY_ADDRESS_8 = 0x5151d0C66f3d20daff7a8deB05170fC3AF4D59D5; // * 0.2
    address private constant COMMUNITY_ADDRESS_9 = 0x05E658aCf4d42597Ba94C29a3D4CaDCFB969bCE2; // * 0.6
    address private constant COMMUNITY_ADDRESS_10 = 0x5b3a778B86ECE9530dF2195f24Ab0C5806ed4843; // * 0.4
    address private constant COMMUNITY_ADDRESS_11 = 0x5151d0C66f3d20daff7a8deB05170fC3AF4D59D5; // * 0.1
    address private constant COMMUNITY_ADDRESS_12 = 0x301d85Ea2aD782E28ca61872371b1FD436CD9beB; // * 1
    address private constant COMMUNITY_ADDRESS_13 = 0x4d878F3CD729ae630D71f06b3e484f6bBE9786d0; // * 0.05
    address private constant COMMUNITY_ADDRESS_14 = 0x71020fDf6FCcDC7f986017657BF94bE9A284a69d; // * 0.1
    address private constant COMMUNITY_ADDRESS_15 = 0x06BbEf713837EDEBb823c4F2C9bdc06E75F1516C; // * 0.1
    address private constant COMMUNITY_ADDRESS_16 = 0x0E518Ba6DD77Dc26667f7DAf8f6a6919BaE82bB5; // * 0.05
    address private constant COMMUNITY_ADDRESS_17 = 0xD297D4472cc24DB4a7a012b37aE71021B946Fa31; // * 1
    address private constant COMMUNITY_ADDRESS_18 = 0x5D8d946776d52cD8982eD8B9B086a5fBDc88a242; // * 1
    address private constant COMMUNITY_ADDRESS_19 = 0xAc3ED66C5A0AF23F9776dC5292FaDaFF436757c9; // * 1
    address private constant COMMUNITY_ADDRESS_20 = 0x0039aB273e02789Da6431f1176e379A0a0ef7f32; // * 0.05
    address private constant COMMUNITY_ADDRESS_21 = 0x8FBCb2e4160a3675b889351B4fE58AeE23D1e88B; // * 1
    address private constant COMMUNITY_ADDRESS_22 = 0x4A0169B4bA9c2014f0da9838C8eC8BedEfdDD223; // * 0.05
    address private constant COMMUNITY_ADDRESS_23 = 0x4CEbE61E535144D88457F435a8022ADd308739f5; // * 0.4 from 2 transfer
    address private constant COMMUNITY_ADDRESS_24 = 0xf189156DA19f6943621C1C002A45CBc387ceb6d3; // * 0.7 from 2 transfers
    address private constant COMMUNITY_ADDRESS_25 = 0xE2Eb16C389326e99005802a2b7F4d556A5B1C629; // * 0.2
    address private constant COMMUNITY_ADDRESS_26 = 0x2fAC78278206F1854dd7db405d8C4A6838F1066e; // * 0.1
    address private constant COMMUNITY_ADDRESS_27 = 0x0492fF0471FFc333Cf5b798Ff8121cf93d1f4B8a; // * 0.1
    address private constant COMMUNITY_ADDRESS_28 = 0xDe8dE160A7aa8DCFc0b711B77464F0a5BF32fd3F; // * 0.6
    address private constant COMMUNITY_ADDRESS_29 = 0x6EF0b144cF25C53081b8a95b03219A1cd4f43ac0; // * 0.1



    // Token amounts for the founders, marketing, and community distribution
    uint256 FOUNDERS_AMOUNT = 6_900_000_000 * 10 ** decimals();
    uint256 MARKETING_AMOUNT = 2_070_000_000 * 10 ** decimals();
    // Community Distribution = 47_610_000_000
    uint256 COMMUNITY_DISTRIBUTION_TOTAL = 47_610_000_000 * 10 ** decimals();
    // Calculation based on contribution
    uint256 COMMUNITY_DISTRIBUTION_1 = 3_450_000_000 * 10 ** decimals(); // 1 ETH = 5%
    uint256 COMMUNITY_DISTRIBUTION_0_7 = 2_415_000_000 * 10 ** decimals(); // 0.7 ETH = 3.5%
    uint256 COMMUNITY_DISTRIBUTION_0_6 = 2_070_000_000 * 10 ** decimals(); // 0.6 ETH = 3%
    uint256 COMMUNITY_DISTRIBUTION_0_4 = 1_380_000_000 * 10 ** decimals(); // 0.4 ETH = 2%
    uint256 COMMUNITY_DISTRIBUTION_0_2 = 690_000_000 * 10 ** decimals(); // 0.2 ETH = 1%
    uint256 COMMUNITY_DISTRIBUTION_0_1 = 345_000_000 * 10 ** decimals(); // 0.1 ETH = 0.5%
    uint256 COMMUNITY_DISTRIBUTION_0_05 = 172_500_000 * 10 ** decimals(); // 0.05ETH = 0.25%



    /**
     * @dev Constructor that mints the initial supply of the token and distributes it to the founders
     * and marketing addresses.
     */
    constructor() ERC20("MuskATears", "MUSK") {
        _mint(msg.sender, INITIAL_SUPPLY);
        _transfer(msg.sender, FOUNDERS_ADDRESS, FOUNDERS_AMOUNT);
        _transfer(msg.sender, MARKETING_ADDRESS, MARKETING_AMOUNT);
    }

    /**
     * @dev Function that distributes the community distribution portion of the token supply to the specified wallet address.
     * Can only be called by the contract owner.
     */
    function distributeTokens() external onlyOwner {
        // Check if the tokens have already been distributed
        uint256 supply = balanceOf(msg.sender);
        require(supply >= COMMUNITY_DISTRIBUTION_TOTAL, "Tokens already distributed");
        // Transfer the tokens to the community address
        _transfer(msg.sender, COMMUNITY_ADDRESS_1, COMMUNITY_DISTRIBUTION_0_2); // * 0.2
        _transfer(msg.sender, COMMUNITY_ADDRESS_2, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_3, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_4, COMMUNITY_DISTRIBUTION_0_6); // * 0.6
        _transfer(msg.sender, COMMUNITY_ADDRESS_5, COMMUNITY_DISTRIBUTION_0_1); // * 0.1
        _transfer(msg.sender, COMMUNITY_ADDRESS_6, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_7, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_8, COMMUNITY_DISTRIBUTION_0_2); // * 0.2
        _transfer(msg.sender, COMMUNITY_ADDRESS_9, COMMUNITY_DISTRIBUTION_0_6); // * 0.6
        _transfer(msg.sender, COMMUNITY_ADDRESS_10, COMMUNITY_DISTRIBUTION_0_4); // * 0.4
        _transfer(msg.sender, COMMUNITY_ADDRESS_11, COMMUNITY_DISTRIBUTION_0_1); // * 0.1
        _transfer(msg.sender, COMMUNITY_ADDRESS_12, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_13, COMMUNITY_DISTRIBUTION_0_05); // * 0.05
        _transfer(msg.sender, COMMUNITY_ADDRESS_14, COMMUNITY_DISTRIBUTION_0_1); // * 0.1
        _transfer(msg.sender, COMMUNITY_ADDRESS_15, COMMUNITY_DISTRIBUTION_0_1); // * 0.1
        _transfer(msg.sender, COMMUNITY_ADDRESS_16, COMMUNITY_DISTRIBUTION_0_05); // * 0.05
        _transfer(msg.sender, COMMUNITY_ADDRESS_17, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_18, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_19, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_20, COMMUNITY_DISTRIBUTION_0_05); // * 0.05
        _transfer(msg.sender, COMMUNITY_ADDRESS_21, COMMUNITY_DISTRIBUTION_1); // * 1
        _transfer(msg.sender, COMMUNITY_ADDRESS_22, COMMUNITY_DISTRIBUTION_0_05); // * 0.05
        _transfer(msg.sender, COMMUNITY_ADDRESS_23, COMMUNITY_DISTRIBUTION_0_4); // * 0.4
        _transfer(msg.sender, COMMUNITY_ADDRESS_24, COMMUNITY_DISTRIBUTION_0_7); // * 0.7
        _transfer(msg.sender, COMMUNITY_ADDRESS_25, COMMUNITY_DISTRIBUTION_0_2); // * 0.2
        _transfer(msg.sender, COMMUNITY_ADDRESS_26, COMMUNITY_DISTRIBUTION_0_1); // * 0.1
        _transfer(msg.sender, COMMUNITY_ADDRESS_27, COMMUNITY_DISTRIBUTION_0_1); // * 0.1
        _transfer(msg.sender, COMMUNITY_ADDRESS_28, COMMUNITY_DISTRIBUTION_0_6); // * 0.6
        _transfer(msg.sender, COMMUNITY_ADDRESS_29, COMMUNITY_DISTRIBUTION_0_1); // * 0.1
    }
}