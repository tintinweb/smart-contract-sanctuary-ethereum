/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: mrt_gateway/decryption.sol


pragma solidity ^0.8.14;

library Decryption {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return address(0);
        }
        if (v != 27 && v != 28) {
            return address(0);
        }
        address signer = ecrecover(hash, v, r, s);
        return signer;
    }

    function recoverSignedMessage(bytes32 hash, bytes memory message)
        internal
        pure
        returns (address)
    {
        require(message.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(message, 0x20))
            s := mload(add(message, 0x40))
            v := byte(0, mload(add(message, 0x60)))
        }
        return recover(hash, v, r, s);
    }
}

// File: mrt_gateway/library.sol


pragma solidity ^0.8.14;

library Lib {
    struct Order {
        uint8 withdrawal_status;
        uint16 token_id;
        uint232 value;
    }

    struct UserData {
        mapping(address => mapping(uint16 => Order)) orders;
        mapping(uint16 => uint256) balance;
        bool isActive;
    }

    struct ContractData {
        bool isActive;
        uint16 token_id;
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: mrt_gateway/mrt_support_erc20.sol


pragma solidity ^0.8.14;



contract MRTSupportContract is Ownable {
    event AddNewERC20(uint32 token_id, address indexed contractAddress);
    event RemoveERC20Contract(uint32 token_id, address indexed contractAddress);
    mapping(address => Lib.ContractData) public activeContracts;

    uint16 internal TOKENID = 1;

    function add_erc20_contract(address _address) public onlyOwner {
        require(
            _address != address(0) && activeContracts[_address].token_id == 0,
            "VW_CE"
        );
        Lib.ContractData storage erc20Contract = activeContracts[_address];
        TOKENID++;
        erc20Contract.isActive = true;
        erc20Contract.token_id = TOKENID;
        emit AddNewERC20(erc20Contract.token_id, _address);
    }

    function remove_erc20_contract(address _address) public onlyOwner {
        require(activeContracts[_address].token_id != 0, "CNE");
        Lib.ContractData storage erc20Contract = activeContracts[_address];
        erc20Contract.isActive = false;
        emit RemoveERC20Contract(erc20Contract.token_id, _address);
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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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

// File: mrt_gateway/mrt_erc20_contract.sol


pragma solidity ^0.8.14;




contract MrtToken is ERC20, MRTSupportContract {
    uint256 public END_REFERRAL_TIME;

    constructor() ERC20("MrtToken", "MRT") {}

    function get_referral_bonus(address user) internal {
        transfer_bonus(user, 50);
    }

    function transfer_bonus(address user, uint256 value) internal {
        if (
            END_REFERRAL_TIME > block.timestamp &&
            balanceOf(address(this)) >= 100 * 10**decimals()
        ) _transfer(address(this), user, value * 10**decimals());
    }

    function update_referral_time(uint256 timestamp) external onlyOwner {
        require(timestamp > END_REFERRAL_TIME, "UR");
        END_REFERRAL_TIME = timestamp;
    }

    function withdraw_mrt_token() external onlyOwner {
        require(block.timestamp > END_REFERRAL_TIME, "RO");
        uint256 balance = balanceOf(address(this));
        _transfer(address(this), _msgSender(), balance);
    }
}

// File: mrt_gateway/mrt_gatway_contract.sol


pragma solidity ^0.8.14;





contract MRT_GATEWAY is MrtToken {
    constructor() {
        _mint(address(this), 500000000000 * 10**decimals());
        _mint(msg.sender, 500000000000 * 10**decimals());
        END_REFERRAL_TIME = block.timestamp + (86400 * 365);
    }

    using Decryption for bytes32;
    mapping(address => Lib.UserData) public sellers;
    mapping(uint16 => uint256) internal creator_balance;
    mapping(address => bool) public signer;
    event UserCreated(string username, address indexed seller);
    event UpdatePercentage(uint8 indexed percentage);
    event WithdrawalSeller(
        uint16 indexed order_id,
        address indexed seller,
        address buyer
    );
    event WithdrawalBuyer(
        uint16 indexed order_id,
        address indexed buyer,
        address seller
    );
    event OrderPaid(
        uint256 total,
        uint16 indexed order_id,
        address indexed buyer,
        address indexed seller,
        address contract_address
    );
    uint8 public contractPercentage; // maximum 3 => 3%

    // submit new order in fourcorners with erc20 token
    // buyer must approve gateway if erc20 is own token dont need call approve
    function callTokenPayment(
        uint16 order_id,
        uint232 order_total,
        address contractAddress,
        address seller
    ) external {
        require(sellers[seller].isActive, "SNE");
        require(activeContracts[contractAddress].isActive, "CNE");
        require(
            sellers[seller].orders[_msgSender()][order_id].token_id == 0,
            "OWP"
        );
        ERC20(contractAddress).transferFrom(
            msg.sender,
            address(this),
            order_total
        );
        Lib.Order storage newOrder = sellers[seller].orders[_msgSender()][
            order_id
        ];
        (newOrder.withdrawal_status, newOrder.value, newOrder.token_id) = (
            1,
            order_total,
            activeContracts[contractAddress].token_id
        );
        sellers[seller].balance[
            activeContracts[contractAddress].token_id
        ] += order_total;
        emit OrderPaid(
            order_total,
            order_id,
            _msgSender(),
            seller,
            contractAddress
        );
    }

    // submit new order in fourcorners with network native token
    function callNativePayment(uint16 order_id, address seller)
        external
        payable
    {
        require(sellers[seller].isActive, "SNE");
        require(
            sellers[seller].orders[_msgSender()][order_id].token_id == 0,
            "OWP"
        );
        Lib.Order storage order = sellers[seller].orders[_msgSender()][
            order_id
        ];
        (order.value, order.token_id, order.withdrawal_status) = (
            uint232(msg.value),
            1,
            1
        );
        sellers[seller].balance[1] += msg.value;
        emit OrderPaid(msg.value, order_id, _msgSender(), seller, address(0));
    }

    // new user // now can sale in fourcorners with MRT Gateway and mint 20 contract own erc20 token
    function registerUser(string memory username, address referral) external {
        require(!sellers[_msgSender()].isActive, "SE");
        require(_msgSender() != address(0));
        sellers[_msgSender()].isActive = true; // active seller for sale in 4corners
        transfer_bonus(_msgSender(), 100);
        if (sellers[referral].isActive) get_referral_bonus(referral);
        emit UserCreated(username, _msgSender());
    }

    // buyers, buyer signer message at buyer index, orderid at buyer index;
    function widthrawForSellers(
        address[] memory buyer,
        bytes[] memory signature,
        uint16[] memory orderId,
        address contractAddress
    ) external {
        require(buyer.length > 0, "WIV");
        uint256 total;
        uint16 contract_id = contractAddress == address(0)
            ? 1
            : activeContracts[contractAddress].token_id;

        for (uint8 i = 0; i < orderId.length; ) {
            Lib.Order storage order = sellers[_msgSender()].orders[buyer[i]][
                orderId[i]
            ];
            require(order.token_id == contract_id, "WIV");
            require(order.withdrawal_status == 1, "ONE");
            require(
                _veryfiPayment(
                    orderId[i],
                    buyer[i],
                    _msgSender(),
                    signature[i]
                ),
                "WK"
            );

            total += order.value;
            order.withdrawal_status = 2;
            emit WithdrawalSeller(orderId[i], _msgSender(), buyer[i]);
            unchecked {
                i++;
            }
        }
        sellers[_msgSender()].balance[contract_id] -= total;
        if (contractPercentage > 0) {
            uint256 _contract_percentage = (total * contractPercentage) / 100;
            total -= _contract_percentage;
            creator_balance[contract_id] += _contract_percentage;
        }
        if (contract_id > 1)
            ERC20(contractAddress).transfer(_msgSender(), total);
        else {
            payable(_msgSender()).transfer(total);
        }
    }

    // some times seller reject order
    // Or in case of report, the amount will be returned to the buyer with the signature of the admin
    // can call multiple order for one address
    // maximum 5 order
    function widthrowForBuyers(
        address[] memory seller,
        bytes[] memory signature,
        uint16[] memory orderId,
        address contractAddress
    ) external {
        require(seller.length > 0, "WIV");
        uint256 total;
        uint16 contract_id = contractAddress == address(0)
            ? 1
            : activeContracts[contractAddress].token_id;
        for (uint8 i = 0; i < orderId.length; ) {
            Lib.Order storage order = sellers[seller[i]].orders[_msgSender()][
                orderId[i]
            ];
            require(order.withdrawal_status == 1, "ONE");
            require(order.token_id == contract_id, "WIV");
            require(
                _veryfiPayment(
                    orderId[i],
                    seller[i],
                    _msgSender(),
                    signature[i]
                ),
                "WK"
            );

            total += order.value;
            order.withdrawal_status = 3;
            sellers[seller[i]].balance[contract_id] -= total;
            emit WithdrawalBuyer(orderId[i], _msgSender(), seller[i]);
            unchecked {
                i++;
            }
        }
        if (contract_id > 1)
            ERC20(contractAddress).transfer(_msgSender(), total);
        else {
            payable(_msgSender()).transfer(total);
        }
    }

    // order balance // if seller have key can call withraw function
    function ordersBalance(address seller, address[] memory contractaddress)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](contractaddress.length);
        for (uint256 i = 0; i < contractaddress.length; ++i) {
            uint16 token_id = contractaddress[i] == address(0)
                ? 1
                : activeContracts[contractaddress[i]].token_id;
            balances[i] = sellers[seller].balance[token_id];
        }
        return balances;
    }

    // order balance // if seller have key can call withraw function
    function orderInfo(
        address seller,
        address buyer,
        uint16 order_id
    )
        external
        view
        returns (
            uint8,
            uint32,
            uint256
        )
    {
        Lib.Order memory order = sellers[seller].orders[buyer][order_id];
        return (order.withdrawal_status, order.token_id, order.value);
    }

    // withdraw creator balance
    function withdraw_creatotr_balance(uint256 value, address _contractAddress)
        external
        onlyOwner
    {
        uint16 token_id = _contractAddress == address(0)
            ? 1
            : activeContracts[_contractAddress].token_id;
        creator_balance[token_id] -= value;
        if (token_id > 1) {
            ERC20(_contractAddress).transfer(_msgSender(), value);
        } else {
            payable(_msgSender()).transfer(value);
        }
    }

    // bost fourcorners project
    function boost_fourcorners_project(address _contractAddress, uint256 value)
        external
        payable
    {
        uint16 token_id = _contractAddress == address(0)
            ? 1
            : activeContracts[_contractAddress].token_id;
        require(_msgSender() != address(0) && token_id > 0, "CNE");
        if (token_id > 1) {
            ERC20(_contractAddress).transferFrom(
                msg.sender,
                address(this),
                value
            );
            creator_balance[token_id] += value;
        } else {
            creator_balance[token_id] += msg.value;
        }
    }

    function update_contract_percentage(uint8 percentage) external onlyOwner {
        require(percentage <= 3, "M3P");
        contractPercentage = percentage;
        emit UpdatePercentage(contractPercentage);
    }

    // verification order widthraw
    // 4corners orderid
    // signer
    // receiver Who can receive? // buyer or seller
    // sign signature
    function _veryfiPayment(
        uint64 _orderId,
        address _signer,
        address _receiver,
        bytes memory sign
    ) internal view returns (bool) {
        bytes memory _hash = abi.encodePacked(
            "buyer",
            Strings.toHexString(uint160(_receiver), 20),
            Strings.toString(_orderId)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(_hash.length),
                _hash
            )
        );
        address signerAddress = hash.recoverSignedMessage(sign);
        return signerAddress == _signer || signer[signerAddress];
    }
}