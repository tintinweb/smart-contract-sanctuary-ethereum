// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Controller.sol";
import "../IDocumentVerificationManagement.sol";
import "./IManagement.sol";

/**
 * @title Management contract for multi document verification contract
 */
contract ManagementMulti is IManagement, Controller {
    /// @dev See {IManagement-configureDocumentCreator}
    function configureDocumentCreator(address documentCreator, uint256 allowedAmount) external override onlyController {
        address managementAddress = getDocumentVerificationManagement(msg.sender);
        IDocumentVerificationManagement managementInterface = IDocumentVerificationManagement(managementAddress);

        _configureDocumentCreator(managementInterface, documentCreator, allowedAmount);
    }

    /// @dev See {IManagement-removeDocumentCreator}
    function removeDocumentCreator(address documentCreator) external override onlyController {
        address managementAddress = getDocumentVerificationManagement(msg.sender);
        IDocumentVerificationManagement managementInterface = IDocumentVerificationManagement(managementAddress);

        managementInterface.removeDocumentCreator(documentCreator);

        emit DocumentCreatorRemoved(documentCreator);
    }

    /// @dev See {IManagement-increaseDocumentCreatorAllowance}
    function increaseDocumentCreatorAllowance(address documentCreator, uint256 incrementAmount)
        external
        override
        onlyController
    {
        address managementAddress = getDocumentVerificationManagement(msg.sender);
        IDocumentVerificationManagement managementInterface = IDocumentVerificationManagement(managementAddress);

        if (!managementInterface.isDocumentCreator(documentCreator)) revert DocumentCreatorNotFound();

        uint256 currentAllowance = managementInterface.documentCreatorAllowance(documentCreator);
        uint256 newAllowance = currentAllowance + incrementAmount;

        _configureDocumentCreator(managementInterface, documentCreator, newAllowance);
    }

    /// @dev See {IManagement-decreaseDocumentCreatorAllowance}
    function decreaseDocumentCreatorAllowance(address documentCreator, uint256 decrementAmount)
        external
        override
        onlyController
    {
        address managementAddress = getDocumentVerificationManagement(msg.sender);
        IDocumentVerificationManagement managementInterface = IDocumentVerificationManagement(managementAddress);

        if (!managementInterface.isDocumentCreator(documentCreator)) revert DocumentCreatorNotFound();

        uint256 currentAllowance = managementInterface.documentCreatorAllowance(documentCreator);
        if (decrementAmount > currentAllowance) revert DecrementAmountExceedsAllowance();

        uint256 newAllowance = currentAllowance - decrementAmount;

        _configureDocumentCreator(managementInterface, documentCreator, newAllowance);
    }

    /// @dev Internal configure document creator function
    function _configureDocumentCreator(
        IDocumentVerificationManagement managementInterface,
        address documentCreator,
        uint256 allowedAmount
    ) private {
        managementInterface.configureDocumentCreator(documentCreator, allowedAmount);

        emit DocumentCreatorConfigured(documentCreator, allowedAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Controller contract for the management
 */
contract Controller is Ownable {
    error CallerIsNotController();

    // A mapping for storing document verification management for each controller
    mapping(address => address) private _controllers;

    /**
     * @dev Emitted when the controller configured
     * @param controller The address of the controller
     * @param documentVerificationManagement The address of the document verification management
     */
    event ControllerConfigured(address indexed controller, address indexed documentVerificationManagement);
    /**
     * @dev Emitted when the controller removed
     * @param controller The address of the controller
     */
    event ControllerRemoved(address indexed controller);

    modifier onlyController() {
        if (_controllers[msg.sender] == address(0)) revert CallerIsNotController();
        _;
    }

    /**
     * @dev Sets document verification management for the controller
     * @param controller Controller address
     * @param documentVerificationManagement documentVerificationManagement address
     */
    function configureController(address controller, address documentVerificationManagement) external onlyOwner {
        _controllers[controller] = documentVerificationManagement;

        emit ControllerConfigured(controller, documentVerificationManagement);
    }

    /**
     * @dev Removes document verification management from the controller
     * @param controller Controller address
     */
    function removeController(address controller) external onlyOwner {
        _controllers[controller] = address(0);

        emit ControllerRemoved(controller);
    }

    /**
     * @dev Returns document verification management for controller
     * @param controller Controller address
     * @return documentVerificationManagement document verification management address
     */
    function getDocumentVerificationManagement(address controller)
        public
        view
        returns (address documentVerificationManagement)
    {
        documentVerificationManagement = _controllers[controller];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IDocumentVerificationManagement {
    /**
     * @dev Adds document creator with given `allowedAmount`
     * @param documentCreator document creator address
     * @param allowedAmount allowed document amount for document creator
     */
    function configureDocumentCreator(address documentCreator, uint256 allowedAmount) external;

    /**
     * @dev Removes document creator
     * @param documentCreator document creator address
     */
    function removeDocumentCreator(address documentCreator) external;

    /**
     * @dev Returns document creator allowance
     * @param documentCreator document creator address
     * @return allowance document creator allowance
     */
    function documentCreatorAllowance(address documentCreator) external view returns (uint256 allowance);

    /**
     * @dev Returns if the given address document creator
     * @param documentCreator document creator address
     * @return result document creator result
     */
    function isDocumentCreator(address documentCreator) external view returns (bool result);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IManagement {
    error DocumentCreatorNotFound();
    error DecrementAmountExceedsAllowance();

    /**
     * @dev Emitted when the document creator configured
     * @param documentCreator The address of the document creator
     * @param allowedAmount The allowed amount for the document creator
     */
    event DocumentCreatorConfigured(address indexed documentCreator, uint256 allowedAmount);
    /**
     * @dev Emitted when the document creator removed
     * @param documentCreator The address of the document creator
     */
    event DocumentCreatorRemoved(address indexed documentCreator);

    /**
     * @dev Adds document creator with given `allowedAmount`
     * @param documentCreator document creator address
     * @param allowedAmount allowed document amount for document creator
     */
    function configureDocumentCreator(address documentCreator, uint256 allowedAmount) external;

    /**
     * @dev Removes document creator
     * @param documentCreator document creator address
     */
    function removeDocumentCreator(address documentCreator) external;

    /**
     * @dev Increases document creator allowance with given `incrementAmount`
     * @param documentCreator document creator address
     * @param incrementAmount increment amount for the document creator
     */
    function increaseDocumentCreatorAllowance(address documentCreator, uint256 incrementAmount) external;

    /**
     * @dev Decreases document creator allowance with given `decrementAmount`
     * @param documentCreator document creator address
     * @param decrementAmount decrement amount for the document creator
     */
    function decreaseDocumentCreatorAllowance(address documentCreator, uint256 decrementAmount) external;
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