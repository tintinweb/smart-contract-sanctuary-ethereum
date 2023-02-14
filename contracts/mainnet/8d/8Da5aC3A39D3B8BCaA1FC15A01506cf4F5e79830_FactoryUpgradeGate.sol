// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IFactoryUpgradeGate} from "./interfaces/IFactoryUpgradeGate.sol";
import {Ownable2Step} from "./utils/ownable/Ownable2Step.sol";

/**

 ________   _____   ____    ______      ____
/\_____  \ /\  __`\/\  _`\ /\  _  \    /\  _`\
\/____//'/'\ \ \/\ \ \ \L\ \ \ \L\ \   \ \ \/\ \  _ __   ___   _____     ____
     //'/'  \ \ \ \ \ \ ,  /\ \  __ \   \ \ \ \ \/\`'__\/ __`\/\ '__`\  /',__\
    //'/'___ \ \ \_\ \ \ \\ \\ \ \/\ \   \ \ \_\ \ \ \//\ \L\ \ \ \L\ \/\__, `\
    /\_______\\ \_____\ \_\ \_\ \_\ \_\   \ \____/\ \_\\ \____/\ \ ,__/\/\____/
    \/_______/ \/_____/\/_/\/ /\/_/\/_/    \/___/  \/_/ \/___/  \ \ \/  \/___/
                                                                 \ \_\
                                                                  \/_/

 */

/// @notice This contract handles gating allowed upgrades for Zora drops contracts
contract FactoryUpgradeGate is IFactoryUpgradeGate, Ownable2Step {
    /// @notice Private mapping of valid upgrade paths
    mapping(address => mapping(address => bool)) private _validUpgradePaths;

    /// @notice Emitted when an upgrade path is added / registered
    event UpgradePathRegistered(address newImpl, address oldImpl);

    /// @notice Emitted when an upgrade path is removed
    event UpgradePathRemoved(address newImpl, address oldImpl);

    /// @notice Error for when not called from admin
    error Access_OnlyOwner();

    /// @notice Sets the owner and inits the contract
    /// @param _initialOwner owner of the contract
    constructor(address _initialOwner) Ownable2Step(_initialOwner) {}

    /// @notice Ensures the given upgrade path is valid and does not overwrite existing storage slots
    /// @param _newImpl The proposed implementation address
    /// @param _currentImpl The current implementation address
    function isValidUpgradePath(address _newImpl, address _currentImpl)
        external
        view
        returns (bool)
    {
        return _validUpgradePaths[_newImpl][_currentImpl];
    }

    /// @notice Registers a new safe upgrade path for an implementation
    /// @param _newImpl The new implementation
    /// @param _supportedPrevImpls Safe implementations that can upgrade to this new implementation
    function registerNewUpgradePath(
        address _newImpl,
        address[] calldata _supportedPrevImpls
    ) external onlyOwner {
        for (uint256 i = 0; i < _supportedPrevImpls.length; i++) {
            _validUpgradePaths[_newImpl][_supportedPrevImpls[i]] = true;
            emit UpgradePathRegistered(_newImpl, _supportedPrevImpls[i]);
        }
    }

    /// @notice Unregisters an upgrade path, in case of emergency
    /// @param _newImpl the newer implementation
    /// @param _prevImpl the older implementation
    function unregisterUpgradePath(address _newImpl, address _prevImpl)
        external
        onlyOwner
    {
        _validUpgradePaths[_newImpl][_prevImpl] = false;
        emit UpgradePathRemoved(_newImpl, _prevImpl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IFactoryUpgradeGate {
  function isValidUpgradePath(address _newImpl, address _currentImpl) external returns (bool);

  function registerNewUpgradePath(address _newImpl, address[] calldata _supportedPrevImpls) external;

  function unregisterUpgradePath(address _newImpl, address _prevImpl) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IOwnable2Step
/// @author Rohan Kulkarni / Iain Nash
/// @notice The external Ownable events, errors, and functions
interface IOwnable2Step {
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();

    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();

    /// @dev Owner cannot be the zero/burn address
    error OWNER_CANNOT_BE_ZERO_ADDRESS();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;

    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IOwnable2Step} from "./IOwnable2Step.sol";

/// @title Ownable2Step
/// @author Iain Nash
/// @dev - Uses custom errors declared in IOwnable
/// @dev - Adds optional two-step ownership transfer (`safeTransferOwnership` + `acceptOwnership`)
abstract contract Ownable2Step is IOwnable2Step {
    /// @dev The address of the owner
    address internal _owner;

    /// @dev The address of the pending owner
    address internal _pendingOwner;

    constructor(address _defaultOwner) {
        _transferOwnership(_defaultOwner);
    }

    ///                                                          ///
    ///                            STORAGE                       ///
    ///                                                          ///

    /// @dev Modifier to check if the address argument is the zero/burn address
    modifier notZeroAddress(address check) {
        if (check == address(0)) {
            revert OWNER_CANNOT_BE_ZERO_ADDRESS();
        }
        _;
    }

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures the caller is the owner
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert ONLY_OWNER();
        }
        _;
    }

    /// @dev Ensures the caller is the pending owner
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner) {
            revert ONLY_PENDING_OWNER();
        }
        _;
    }

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @notice The address of the pending owner
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /// @notice Forces an ownership transfer from the last owner
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner)
        public
        notZeroAddress(_newOwner)
        onlyOwner
    {
        _transferOwnership(_newOwner);
    }

    /// @notice Forces an ownership transfer from any sender
    /// @param _newOwner New owner to transfer contract to
    /// @dev Ensure is called only from trusted internal code, no access control checks.
    function _transferOwnership(address _newOwner) internal {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;

        if (_pendingOwner != address(0)) {
            delete _pendingOwner;
        }
    }

    /// @notice Initiates a two-step ownership transfer
    /// @param _newOwner The new owner address
    function safeTransferOwnership(address _newOwner)
        public
        notZeroAddress(_newOwner)
        onlyOwner
    {
        _pendingOwner = _newOwner;

        emit OwnerPending(_owner, _newOwner);
    }

    /// @notice Resign ownership of contract
    /// @dev only callably by the owner, dangerous call.
    function resignOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Accepts an ownership transfer
    function acceptOwnership() public onlyPendingOwner {
        emit OwnerUpdated(_owner, msg.sender);

        _owner = _pendingOwner;

        delete _pendingOwner;
    }

    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() public onlyOwner {
        emit OwnerCanceled(_owner, _pendingOwner);

        delete _pendingOwner;
    }
}