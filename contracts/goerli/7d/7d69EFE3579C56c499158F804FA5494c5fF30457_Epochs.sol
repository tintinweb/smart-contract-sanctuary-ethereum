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

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEpochs.sol";

/**
 * @notice Contract which handles Hexagon epochs mechanism.
 *
 * Epoch duration and time when decision window is open is calculated by number of blocks to pass.
 * These values are set when deploying a contract but can later be changed with {setEpochDuration} and
 * {setDecisionWindow} by contract's owner.
 */
contract Epochs is Ownable, IEpochs {
    /// @notice Block height when hexagon starts.
    uint256 public start;

    /// @notice Epoch duration in blocks count.
    uint256 public epochDuration;

    /**
     * @notice Decision window in blocks count.
     *
     * This value represents time, when participant can allocate founds to projects.
     * It must be smaller then {epochDuration}.
     */
    uint256 public decisionWindow;

    constructor(
        uint256 _start,
        uint256 _epochDuration,
        uint256 _decisionWindow
    ) {
        start = _start;
        epochDuration = _epochDuration;
        decisionWindow = _decisionWindow;
    }

    function getCurrentEpoch() public view returns (uint256) {
        require(isStarted(), "HN/not-started-yet");
        return uint256(((block.number - start) / epochDuration) + 1);
    }

    function isDecisionWindowOpen() public view returns (bool) {
        require(isStarted(), "HN/not-started-yet");
        uint256 moduloEpoch = uint256((block.number - start) % epochDuration);
        return moduloEpoch <= decisionWindow;
    }

    function isStarted() public view returns (bool) {
        return block.number >= start;
    }

    function setEpochDuration(uint256 _epochDuration) external onlyOwner {
        epochDuration = _epochDuration;
    }

    function setDecisionWindow(uint256 _decisionWindow) external onlyOwner {
        decisionWindow = _decisionWindow;
    }
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

interface IEpochs {
    function getCurrentEpoch() external view returns (uint256);

    function isStarted() external view returns (bool);

    function isDecisionWindowOpen() external view returns (bool);
}