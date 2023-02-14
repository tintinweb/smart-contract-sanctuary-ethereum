// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";

error BuffPurchasesNotEnabled();
error InvalidInput();

/**
 * @title Open JTM Buff Boosts V2
 */

contract OpenJimmyTheMonkeyBuffsV2 is Ownable {
    uint256 public constant BUFF_TIME_INCREASE = 600;
    uint256 public constant BUFF_TIME_INCREASE_PADDING = 60;
    uint256 public constant MAX_BUFFS_PER_TRANSACTIONS = 48;
    uint256 public immutable buffCost;
    address public immutable apeCoinContract;
    bool public buffPurchasesEnabled;
    mapping(address => uint256) public playerAddressToBuffTimestamp;

    event BuffPurchased(
        address indexed playerAddress,
        uint256 indexed buffTimestamp,
        uint256 quantityPurchased
    );

    constructor(
        address _apeCoinContract,
        uint256 _buffCost
    ) {
        apeCoinContract = _apeCoinContract;
        buffCost = _buffCost;
    }

    /**
     * @notice Purchase a buff boost - time starts when the transaction is confirmed
     * @param quantity amount of boosts to purchase
     */
    function purchaseBuffs(uint256 quantity) external {
        if (!buffPurchasesEnabled) revert BuffPurchasesNotEnabled();
        if (quantity < 1 || quantity > MAX_BUFFS_PER_TRANSACTIONS)
            revert InvalidInput();

        uint256 newTimestamp;
        uint256 totalBuffIncrease;
        uint256 totalBuffCost;

        uint256 currentBuffTimestamp = playerAddressToBuffTimestamp[
            _msgSender()
        ];

        unchecked {
            totalBuffIncrease = quantity * BUFF_TIME_INCREASE;
            totalBuffCost = quantity * buffCost;
        }

        // player has V2 seconds remaining
        if (currentBuffTimestamp > block.timestamp) {
            unchecked {
                newTimestamp = currentBuffTimestamp + totalBuffIncrease;
            }
        } else {
            // player has no V2 seconds remaining
            unchecked {
                newTimestamp =
                    block.timestamp +
                    totalBuffIncrease +
                    BUFF_TIME_INCREASE_PADDING;
            }
        }

        IERC20(apeCoinContract).transferFrom(
            _msgSender(),
            address(this),
            totalBuffCost
        );

        emit BuffPurchased(_msgSender(), newTimestamp, quantity);
        playerAddressToBuffTimestamp[_msgSender()] = newTimestamp;
    }

    /**
     * @notice Get the ending boost timestamp for a player address
     * @param playerAddress the address of the player
     * @return uint256 unix timestamp
     */
    function getBuffTimestampForPlayer(
        address playerAddress
    ) external view returns (uint256) {
        return playerAddressToBuffTimestamp[playerAddress];
    }

    /**
     * @notice Get the seconds remaining in the boost for a player address
     * @param playerAddress the address of the player
     * @return uint256 seconds of boost remaining
     */
    function getRemainingBuffTimeInSeconds(
        address playerAddress
    ) external view returns (uint256) {
        uint256 currentBuffTimestamp = playerAddressToBuffTimestamp[
            playerAddress
        ];
        if (currentBuffTimestamp > block.timestamp) {
            return currentBuffTimestamp - block.timestamp;
        }
        return 0;
    }

    // Operator functions

    /**
     * @notice Toggle the purchase state of buffs
     */
    function flipBuffPurchasesEnabled() external onlyOwner {
        buffPurchasesEnabled = !buffPurchasesEnabled;
    }

    /**
     * @notice Withdraw erc-20 tokens
     * @param coinContract the erc-20 contract address
     */
    function withdraw(address coinContract) external onlyOwner {
        uint256 balance = IERC20(coinContract).balanceOf(address(this));
        if (balance > 0) {
            IERC20(coinContract).transfer(msg.sender, balance);
        }
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