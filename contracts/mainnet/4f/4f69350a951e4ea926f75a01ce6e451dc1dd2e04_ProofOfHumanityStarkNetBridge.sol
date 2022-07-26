// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/utils/Context.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "src/interfaces/IProofOfHumanityProxy.sol";
import "src/interfaces/IStarkNetMessaging.sol";

contract ProofOfHumanityStarkNetBridge is Context, Ownable {
    /// EVENTS

    /** @dev Emitted when the registration to L2 has been triggered.
     *  @param _submissionID The ID of the submission.
     *  @param _l2RecipientAddress The recipient address on L2.
     *  @param _timestamp The timestamp when the L2 registration has been triggered.
     */
    event L2RegistrationTriggered(
        address indexed _submissionID,
        uint256 _l2RecipientAddress,
        uint256 _timestamp
    );

    /// ERRORS

    /** @dev Thrown when the address of the sender is not registered on proof of humanity protocol.
     *  @param submissionID The ID of the submission.
     */
    error NotRegistered(address submissionID);
    /** @dev Thrown when the L2 parameters are not set.
     */
    error L2ParametersNotSet();

    /// STORAGE

    // Address of ProofOfHumanity proxy contract
    IProofOfHumanityProxy private _pohProxy;
    // Address of StarkNetMessaging contract
    IStarkNetMessaging private _starkNetMessaging;
    // Address of ProofOfHumanity registry contract on L2
    uint256 private _l2ProofOfHumanityRegistryContract;
    // Selector of register function
    uint256 private _registerSelector;

    /// MODIFIERS
    modifier onlyIfL2ParametersSet() {
        if (_l2ProofOfHumanityRegistryContract == 0 || _registerSelector == 0) {
            revert L2ParametersNotSet();
        }
        _;
    }

    /** @dev Constructor.
     *  @param pohProxy_ The address of the ProofOfHumanity proxy contract.
     *  @param starkNetMessaging_ The address of the StarkNetMessaging contract.
     */
    constructor(address pohProxy_, address starkNetMessaging_) {
        _pohProxy = IProofOfHumanityProxy(pohProxy_);
        _starkNetMessaging = IStarkNetMessaging(starkNetMessaging_);
    }

    /** @dev Configure L2 specific parameters.
     *  @param l2ProofOfHumanityRegistryContract_ The address of ProofOfHumanity registry contract on L2.
     *  @param registerSelector_ The selector of register function.
     */
    function configureL2Parameters(
        uint256 l2ProofOfHumanityRegistryContract_,
        uint256 registerSelector_
    ) public onlyOwner {
        require(
            _l2ProofOfHumanityRegistryContract == 0 && _registerSelector == 0,
            "ProofOfHumanityStarkNetBridge: L2 parameters can be set only once"
        );
        _l2ProofOfHumanityRegistryContract = l2ProofOfHumanityRegistryContract_;
        _registerSelector = registerSelector_;
    }

    /** @dev Register the submission on L2 if it is registered on L1.
     *  @param l2RecipientAddress The L2 address to associate the registration with.
     */
    function registerToL2(uint256 l2RecipientAddress)
        public
        onlyIfL2ParametersSet
    {
        // Get sender address
        address sender = _msgSender();
        // Check if address is registered
        bool isRegistered = _pohProxy.isRegistered(sender);
        if (!isRegistered) {
            revert NotRegistered({submissionID: sender});
        }

        // Get current timestamp
        uint256 registrationTimestamp = block.timestamp;

        // Build message payload
        uint256[] memory payload = new uint256[](3);
        payload[0] = uint256(uint160(sender));
        payload[1] = l2RecipientAddress;
        payload[2] = registrationTimestamp;

        // Send message to L2
        _starkNetMessaging.sendMessageToL2(
            _l2ProofOfHumanityRegistryContract,
            _registerSelector,
            payload
        );

        emit L2RegistrationTriggered(
            sender,
            l2RecipientAddress,
            registrationTimestamp
        );
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
pragma solidity ^0.8.15;

interface IProofOfHumanityProxy {
    function isRegistered(address _submissionID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IStarkNetMessaging {
    
    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external returns (bytes32);
}