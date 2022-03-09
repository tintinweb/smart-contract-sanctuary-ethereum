pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Desub is Ownable {
    constructor(uint256 _priorityKeeperSeconds, uint256 _keeperFeePct) { 
        priorityKeeperSeconds = _priorityKeeperSeconds;
        keeperFeePct = _keeperFeePct;
    }

    event SponsorshipExtended(
        address indexed sponsor,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 period,
        uint256 nextRenewalTimestamp
    );
    event SponsorshipPaused(address indexed sponsor, address indexed recipient);

    // Sponsorship vars
    mapping(address => mapping(address => uint256)) public nextRenewalTimestamps;
    mapping(address => mapping(address => address)) public tokens;
    mapping(address => mapping(address => uint256)) public amounts;
    mapping(address => mapping(address => uint256)) public periodSeconds;
    mapping(address => mapping(address => bool)) public isPaused;

    // Keeper vars
    uint256 public priorityKeeperSeconds;
    uint256 public keeperFeePct;
    mapping(address => bool) public isPriorityKeeper;

    function prioritizeKeeper(address keeper, bool priority) public onlyOwner {
        isPriorityKeeper[keeper] = priority;
    }

    function getSponsorship(address sponsor, address recipient) public view returns (
        bool, address, uint256, uint256, uint256
    ) {
        return (
            isPaused[sponsor][recipient],
            tokens[sponsor][recipient],
            amounts[sponsor][recipient],
            periodSeconds[sponsor][recipient],
            nextRenewalTimestamps[sponsor][recipient]
        );
    }

    function startSponsorship(
        address recipient,
        address token,
        uint256 amount,
        uint256 _periodSeconds
    ) public {
        require(IERC20(token).transferFrom(msg.sender, recipient, amount), "Payment failed");

        nextRenewalTimestamps[msg.sender][recipient] = block.timestamp + _periodSeconds;
        tokens[msg.sender][recipient] = token;
        amounts[msg.sender][recipient] = amount;
        periodSeconds[msg.sender][recipient] = _periodSeconds;
        isPaused[msg.sender][recipient] = false;

        emit SponsorshipExtended(
            msg.sender,
            recipient,
            token,
            amount,
            _periodSeconds,
            nextRenewalTimestamps[msg.sender][recipient]
        );
    }

    function pauseOrUnpauseSponsorship(address recipient, bool pausedOrUnpaused) public {
        isPaused[msg.sender][recipient] = pausedOrUnpaused;
        emit SponsorshipPaused(msg.sender, recipient);
    }

    function extendSponsorship(
        address sponsor,
        address recipient
    ) public {
        require(block.timestamp >= nextRenewalTimestamps[sponsor][recipient], "Too early");
        require(!isPaused[sponsor][recipient], "Paused");
        require(tokens[sponsor][recipient] != address(0), "No subscription plan");

        if (block.timestamp < nextRenewalTimestamps[sponsor][recipient] + priorityKeeperSeconds) {
            require(isPriorityKeeper[msg.sender], "Priority keeper window");
        }

        require(IERC20(tokens[sponsor][recipient]).transferFrom(sponsor, recipient, amounts[sponsor][recipient] * (100 - keeperFeePct) / 100),
            "Payment failed");
        require(IERC20(tokens[sponsor][recipient]).transferFrom(sponsor, msg.sender, amounts[sponsor][recipient] * keeperFeePct / 100),
            "Keeper payment failed");

        nextRenewalTimestamps[sponsor][recipient] =  block.timestamp + periodSeconds[sponsor][recipient];

        emit SponsorshipExtended(
            sponsor,
            recipient,
            tokens[sponsor][recipient],
            amounts[sponsor][recipient],
            periodSeconds[sponsor][recipient],
            nextRenewalTimestamps[sponsor][recipient]
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