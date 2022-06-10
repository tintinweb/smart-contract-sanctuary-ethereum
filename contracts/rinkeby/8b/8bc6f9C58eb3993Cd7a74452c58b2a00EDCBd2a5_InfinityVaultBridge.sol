// SPDX-License-Identifier: NONE
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMigrate {
    struct Deposit {
        bool exists;
        bool withdrawn;
        uint8 networkId; // Only for ethereum and bsc
        uint256 lockId;
        uint256 amount;
        uint256 lockUntil;
        address withdrawalAddress;
        string packageKey;
    }

    function remove(
        uint256,
        uint256
    ) external returns (bool);

    function get(
        uint256,
        uint256
    ) external returns (Deposit memory);

    function upsert(Deposit memory, bool) external returns (bool);
}

contract InfinityVaultBridge is IMigrate, Ownable {
    uint256 private constant ETHEREUM = 1;
    uint256 private constant BSC = 56;

    /**
     * @dev Hash(NetworkId + Version + depositId ) => Deposit Detail
     * Map of deterministic unique ID from a input
     **/
    mapping(bytes32 => Deposit) internal locks;
    bool isInitialState = false;
    IERC20 token;

    // Events
    event Withdrawal(
        uint256 id,
        uint256 networkId,
        string packageKey,
        address indexed withdrawalAddress,
        uint256 amount
    );

    /**
     * @dev Until the state is false, the user will not withdraw tokens.
     * At this time we can do a data import, and at the very end add a token contract.
     * @param contractAddress - token ERC20
     */
    function setInitialState(address contractAddress) external onlyOwner {
        token = IERC20(contractAddress);
        isInitialState = true;
    }

    /**
     * @dev create necessery key to read deposit
     * @param networkId - usually values are equivalent to ETHEREUM | BSC
     * @param lockId - any number value > 0
     */
    function getKeyDeposit(
        uint256 networkId,
        uint256 lockId
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(networkId, lockId));
    }

    /**
     * @dev get reference to locks and check does it exists
     **/
    function getRefLock(
        uint256 networkId,
        uint256 lockId
    ) internal view returns (bytes32 key, bool exist) {
        key = getKeyDeposit(networkId, lockId);
        exist = doesExistLock(networkId, lockId);
    }

    function doesExistLock(
        uint256 networkId,
        uint256 lockId
    ) public view returns (bool) {
        bytes32 key = getKeyDeposit(networkId, lockId);
        return locks[key].exists;
    }

    /**
     * @dev set lock id if not exist for network or update
     * @param deposit - Each UI or code takes an argument as a tuple
     * @param update - flag argument decides to update lock
     **/
    function upsert(Deposit memory deposit, bool update) external onlyOwner returns (bool) {
        (bytes32 key, bool exist) = getRefLock(deposit.networkId, deposit.lockId);
        if (exist && !update) return false;

        require(deposit.networkId == BSC ||
                deposit.networkId == ETHEREUM, "Inncorect network");
        locks[key] = deposit;

        return true;
    }

    function remove(
        uint256 networkId,
        uint256 lockId
    ) external onlyOwner returns (bool) {
        (bytes32 key, bool exist) = getRefLock(networkId, lockId);

        if (!exist) return false;
        delete locks[key];

        return true;
    }

    /**
     * @dev get detail locks
     **/
    function get(
        uint256 networkId,
        uint256 lockId
    ) external view returns (Deposit memory) {
        (bytes32 key, bool exist) = getRefLock(networkId, lockId);

        require(exist, "Deposit doesn't exists");
        return locks[key];
    }

    function withdrawDeposit(uint256 networkId, uint256 lockId) external {
        require(isInitialState, "Token is not added");
        bytes32 key = getKeyDeposit(networkId, lockId);

        require(locks[key].exists, "Deposit not found");
        require(_msgSender() == locks[key].withdrawalAddress, "Only deposit owner is allowed to withdraw");
        require(!locks[key].withdrawn, "Deposit is already withdrawn");

        locks[key].withdrawn = true;
        require(
            token.transfer(_msgSender(), locks[key].amount),
            "Transfer failed"
        );

        emit Withdrawal(
            locks[key].lockId,
            locks[key].networkId,
            locks[key].packageKey,
            locks[key].withdrawalAddress,
            locks[key].amount
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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