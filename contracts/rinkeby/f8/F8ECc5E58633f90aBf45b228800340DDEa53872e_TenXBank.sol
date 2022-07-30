// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ITenXBank.sol";
import "./abstract/FeeCollector.sol";

contract TenXBank is ITenXBank, FeeCollector, Ownable {
    IERC20 public immutable bankToken;

    constructor(IERC20 bankToken_) {
        bankToken = bankToken_;
    }

    mapping(string => Account) public accounts;
    mapping(address => string[]) allAccounts;

    function _checkAccount(string memory name) internal view returns (bool) {
        return accounts[name].exists;
    }

    modifier _checkAccountOwner(string memory name) {
        require(_checkAccount(name), "Account not found");
        require(
            msg.sender == accounts[name].owner,
            "Account owner does not match"
        );
        _;
    }

    function createAccount(string memory name) external override {
        require(!_checkAccount(name), "Account name has already been taken");
        accounts[name].exists = true;
        accounts[name].owner = msg.sender;
        accounts[name].balance = 0;
        allAccounts[msg.sender].push(name);
        emit AccountCreated(name, msg.sender);
    }

    function deposit(string memory name, uint256 amount)
        external
        override
        _checkAccountOwner(name)
    {
        bankToken.transferFrom(msg.sender, address(this), amount);
        accounts[name].balance += amount;
        emit TokenDeposited(name, amount);
    }

    function withdraw(string memory name, uint256 amount)
        external
        override
        _checkAccountOwner(name)
    {
        require(
            accounts[name].balance > amount,
            "Insufficient account balance"
        );
        accounts[name].balance -= amount;
        bankToken.transfer(msg.sender, amount);
        emit TokenWithdrawn(name, amount);
    }

    function _transfer(
        string memory from,
        string memory to,
        uint256 amount
    ) internal _checkAccountOwner(from) {
        require(_checkAccount(to), "Receiver account not found");
        require(
            accounts[from].balance > amount,
            "Insufficient account balance"
        );

        uint256 amountWithFee = amount;
        if (msg.sender != accounts[to].owner) {
            (uint256 remaining, ) = calculateFee(amount);
            amountWithFee = remaining;
        }

        accounts[from].balance -= amountWithFee;
        accounts[to].balance += amountWithFee;
        emit TokenTransferred(from, to, amount);
    }

    function transfer(
        string memory from,
        string memory to,
        uint256 amount
    ) external override {
        _transfer(from, to, amount);
    }

    function transferBatch(
        string memory from,
        string[] memory to,
        uint256[] memory amounts
    ) external override {
        require(to.length == amounts.length, "Receivers and amounts missmatch");
        for (uint256 i = 0; i < to.length; i++) {
            _transfer(from, to[i], amounts[i]);
        }
    }

    function getOwnerAccounts(address owner)
        external
        view
        returns (string[] memory)
    {
        return allAccounts[owner];
    }

    function setFee(uint256 newFee) external onlyOwner {
        _setFee(newFee);
    }

    function collectFee(uint256 amount, address beneficiary)
        external
        onlyOwner
    {
        _collectFee(bankToken, amount, beneficiary);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ITenXBank {
    struct Account {
        bool exists;
        address owner;
        uint256 balance;
    }

    event AccountCreated(string indexed name, address indexed owner);
    event TokenDeposited(string indexed name, uint256 indexed amount);
    event TokenWithdrawn(string indexed name, uint256 indexed amount);
    event TokenTransferred(
        string indexed from,
        string indexed to,
        uint256 indexed amount
    );

    function createAccount(string memory name) external;

    function deposit(string memory name, uint256 amount) external;

    function withdraw(string memory name, uint256 amount) external;

    function transfer(
        string memory from,
        string memory to,
        uint256 amount
    ) external;

    function transferBatch(
        string memory from,
        string[] memory to,
        uint256[] memory amounts
    ) external;

    function getOwnerAccounts(address owner)
        external
        view
        returns (string[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IFeeCollector.sol";

abstract contract FeeCollector is IFeeCollector {
    uint256 public constant override feeDecimals = 4;
    uint256 public constant override shifter = 10**feeDecimals;
    uint256 public override fee = 100;

    function calculateFee(uint256 amount)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 collectedFee = (amount * fee) / shifter;
        uint256 remaining = amount - collectedFee;
        return (remaining, collectedFee);
    }

    function _collectFee(
        IERC20 token,
        uint256 amount,
        address beneficiary
    ) internal {
        token.transfer(beneficiary, amount);
        emit FeeCollected(beneficiary, amount);
    }

    function _setFee(uint256 newFee) internal {
        uint256 oldFee = fee;
        fee = newFee;
        emit FeeChanged(oldFee, fee);
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFeeCollector {
    event FeeCollected(address indexed beneficiary, uint256 indexed amount);

    event FeeChanged(uint256 indexed oldFee, uint256 indexed newFee);

    function feeDecimals() external returns (uint256);

    function shifter() external returns (uint256);

    function fee() external returns (uint256);

    function collectFee(uint256 amount, address beneficiary) external;

    function setFee(uint256 newFee) external;
}