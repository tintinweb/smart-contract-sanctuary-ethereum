// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/INupayICO.sol";

contract NupayICO is INupayICO, Ownable, ReentrancyGuard, Pausable {
    address public constant ZERO_ADDRESS = address(0);
    uint256 public constant NATIVE_DECIMALS = 18;

    uint256 private _minDeposit;
    uint256 private _maxDeposit;
    bool private _initialized;

    INupayICO private _fromIcoContract;
    INupayICO private _toIcoContract;
    AggregatorV3Interface private _aggregatorPriceFeed;

    mapping(address => Deposit[]) private _deposits;

    function aggregatorPriceFeed() external view returns (AggregatorV3Interface) {
        return _aggregatorPriceFeed;
    }

    function deposits(
        address account,
        uint256 skip,
        uint256 limit
    ) external view returns (Deposit[] memory depositItems) {
        uint256 thisDepositItemsLength = _deposits[account].length;
        uint256 depositItemsLength = depositsLength(account);
        if (skip >= depositItemsLength) return depositItems;
        uint256 to = skip + limit;
        if (depositItemsLength < to) to = depositItemsLength;
        uint256 length = to - skip;
        depositItems = new Deposit[](length);
        Deposit[] memory previousDepositItems;
        if (address(_fromIcoContract) != ZERO_ADDRESS && skip < depositItemsLength - thisDepositItemsLength) {
            previousDepositItems = _fromIcoContract.deposits(account, skip, limit);
        }
        uint256 previousLength = previousDepositItems.length;
        for (uint256 i = 0; i < length; i++) {
            if (i < previousLength) {
                depositItems[i] = previousDepositItems[i];
            } else {
                depositItems[i] = _deposits[account][thisDepositItemsLength + i - (depositItemsLength - skip)];
            }
        }
    }

    function fromIcoContract() external view returns (address) {
        return address(_fromIcoContract);
    }

    function initialized() external view returns (bool) {
        return _initialized;
    }

    function toIcoContract() external view returns (address) {
        return address(_toIcoContract);
    }

    function minDeposit() external view returns (uint256) {
        return _minDeposit;
    }

    function maxDeposit() external view returns (uint256) {
        return _maxDeposit;
    }

    function depositsLength(address account) public view returns (uint256 length) {
        if (address(_fromIcoContract) != ZERO_ADDRESS) {
            length = _fromIcoContract.depositsLength(account);
        }
        length += _deposits[account].length;
    }

    event Deposited(address indexed account, bytes32 heloAddress, uint256 amount);
    event Initialized(address indexed icoContract, address aggregator, uint256 minValue, uint256 maxValue);
    event MaxDepositSetted(uint256 amount);
    event Migrated(address indexed icoContract);
    event MinDepositSetted(uint256 amount);
    event Received(address indexed sender, uint256 value);
    event Withdrawn(address indexed account, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function deposit(bytes32 heloAddress) external payable whenNotPaused whenNotMigrated returns (bool) {
        require(heloAddress != bytes32(0), "Helo address is zero bytes");
        address caller = msg.sender;
        uint256 value = msg.value;
        require(value > 0, "Value is not positive");
        require(_initialized, "Not initialized");
        uint256 price = getPrice();
        uint256 usdValue = (price * value) / 10**NATIVE_DECIMALS;
        require(usdValue >= _minDeposit, "Deposit lt min price");
        require(usdValue <= _maxDeposit || _maxDeposit == 0, "Deposit gt max price");
        _deposits[caller].push(Deposit(heloAddress, value));
        emit Deposited(caller, heloAddress, value);
        return true;
    }

    function initialize(
        address icoContract_,
        uint256 minDeposit_,
        uint256 maxDeposit_,
        address aggregatorPriceFeed_
    ) external onlyOwner returns (bool) {
        require(!_initialized, "Already initialized");
        require(aggregatorPriceFeed_ != ZERO_ADDRESS, "Aggregator is zero address");
        require(maxDeposit_ >= minDeposit_, "MinDeposit gte MaxDeposit");
        _minDeposit = minDeposit_;
        _maxDeposit = maxDeposit_;
        _aggregatorPriceFeed = AggregatorV3Interface(aggregatorPriceFeed_);
        _fromIcoContract = INupayICO(icoContract_);
        if (icoContract_ != ZERO_ADDRESS) {
            _fromIcoContract = INupayICO(icoContract_);
        }
        _initialized = true;
        emit Initialized(icoContract_, aggregatorPriceFeed_, minDeposit_, maxDeposit_);
        return _initialized;
    }

    function migrateTo(address icoContract) external onlyOwner whenNotMigrated nonReentrant returns (bool) {
        require(icoContract != ZERO_ADDRESS, "Ico contract is zero address");
        uint256 balance = address(this).balance;
        _toIcoContract = INupayICO(icoContract);
        if (balance > 0) payable(icoContract).transfer(balance);
        emit Migrated(icoContract);
        return true;
    }

    function pause() external onlyOwner returns (bool) {
        _pause();
        return true;
    }

    function unpause() external onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    function setMinDeposit(uint256 value) external onlyOwner returns (bool) {
        _minDeposit = value;
        emit MinDepositSetted(value);
        return true;
    }

    function setMaxDeposit(uint256 value) external onlyOwner returns (bool) {
        _maxDeposit = value;
        emit MaxDepositSetted(value);
        return true;
    }

    function withdraw(address to, uint256 amount) external onlyOwner nonReentrant returns (bool) {
        require(to != ZERO_ADDRESS, "Recipient is zero address");
        require(amount > 0, "Value is not positive");
        payable(to).transfer(amount);
        emit Withdrawn(to, amount);
        return true;
    }

    function getPrice() internal virtual view returns (uint256) {
        (, int256 price, , , ) = _aggregatorPriceFeed.latestRoundData();
        return uint256(price);
    }

    modifier whenNotMigrated() {
        require(address(_toIcoContract) == ZERO_ADDRESS, "Contract already migrated");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface INupayICO {
    struct Deposit {
        bytes32 heloAddress;
        uint256 amount;
    }

    function depositsLength(address account) external view returns (uint256 length);

    function deposits(
        address account,
        uint256 skip,
        uint256 limit
    ) external view returns (Deposit[] memory depositItems);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}