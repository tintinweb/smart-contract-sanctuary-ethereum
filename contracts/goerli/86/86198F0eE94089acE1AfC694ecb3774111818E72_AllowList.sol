pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./interfaces/IAllowList.sol";
import "./libraries/UncheckedMath.sol";

/// @author Matter Labs
/// @notice The smart contract that stores the permissions to call the function on different contracts.
/// @dev The contract is fully controlled by the owner, that can grant and revoke any permissions at any time.
/// @dev The permission list is implemented as both:
/// - Access list of (caller address, target address, function to call, boolean value of permission to call)
/// - Access list to call any function from the target contract by any caller
/// If the target contract is in the second list, then it is automatically available for calling any function.
/// Otherwise, it checks whether the caller has access to call the contract from the first list.
contract AllowList is IAllowList {
    using UncheckedMath for uint256;

    /// @notice The address that the owner proposed as one that will replace its
    address public pendingOwner;

    /// @notice The address with permission to change other users' permissions
    address public owner;

    /// @notice mapping of the addresses that everyone has permission to call
    mapping(address => bool) public isAccessPublic;

    /// @notice The mapping that stores permissions to call the function on the target address by the caller
    /// @dev caller => target => function signature => permission to call target function for the given caller address
    mapping(address => mapping(address => mapping(bytes4 => bool))) public hasSpecialAccessToCall;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "kx");
        _;
    }

    /// @return Whether the caller can call the specific function on the target contract
    /// @param _caller The caller address, who is granted access
    /// @param _target The address of the smart contract which is called
    /// @param _functionSig The function signature (selector), access to which need to check
    function canCall(
        address _caller,
        address _target,
        bytes4 _functionSig
    ) external view returns (bool) {
        return isAccessPublic[_target] || hasSpecialAccessToCall[_caller][_target][_functionSig];
    }

    /// @notice Set the permission to call the target contract by anyone
    /// @param _target The address of the smart contract, of which access to the call is to be changed
    /// @param _enable Whether enable or disable the public access
    function setPublicAccess(address _target, bool _enable) external onlyOwner {
        _setPublicAccess(_target, _enable);
    }

    /// @notice Set many permissions to call the targets contract by anyone
    /// @dev Analogous to function `setPublicAccess` but performs a batch of changes
    /// @param _targets The array of smart contract addresses, of which access to the call is to be changed
    /// @param _enables The array of boolean flags, whether enable or disable the public access to the corresponding target address
    function setBatchPublicAccess(address[] calldata _targets, bool[] calldata _enables) external onlyOwner {
        uint256 targetsLength = _targets.length;
        require(targetsLength == _enables.length, "yg"); // The size of arrays should be equal

        for (uint256 i = 0; i < targetsLength; i = i.uncheckedInc()) {
            _setPublicAccess(_targets[i], _enables[i]);
        }
    }

    /// @dev Changes public access and emits the event if the access was changed
    function _setPublicAccess(address _target, bool _enable) internal {
        bool isEnabled = isAccessPublic[_target];

        if (isEnabled != _enable) {
            isAccessPublic[_target] = _enable;
            emit UpdatePublicAccess(_target, _enable);
        }
    }

    /// @notice Set many permissions to call the function on the contract to the specified caller address
    /// @param _callers The array of caller addresses, who are granted access
    /// @param _targets The array of smart contract addresses, of which access to the call are to be changed
    /// @param _functionSigs The array of function signatures (selectors), access to which need to be changed
    /// @param _enables The array of boolean flags, whether enable or disable the function access to the corresponding target address
    function setBatchPermissionToCall(
        address[] calldata _callers,
        address[] calldata _targets,
        bytes4[] calldata _functionSigs,
        bool[] calldata _enables
    ) external onlyOwner {
        uint256 callersLength = _callers.length;
        require(
            callersLength == _targets.length &&
                callersLength == _functionSigs.length &&
                callersLength == _enables.length,
            "yw"
        ); // The size of arrays should be equal

        for (uint256 i = 0; i < callersLength; i = i.uncheckedInc()) {
            _setPermissionToCall(_callers[i], _targets[i], _functionSigs[i], _enables[i]);
        }
    }

    /// @notice Set the permission to call the function on the contract to the specified caller address
    /// @param _caller The caller address, who is granted access
    /// @param _target The address of the smart contract, of which access to the call is to be changed
    /// @param _functionSig The function signature (selector), access to which need to be changed
    /// @param _enable Whether enable or disable the permission
    function setPermissionToCall(
        address _caller,
        address _target,
        bytes4 _functionSig,
        bool _enable
    ) external onlyOwner {
        _setPermissionToCall(_caller, _target, _functionSig, _enable);
    }

    /// @dev Changes permission to call and emits the event if the permission was changed
    function _setPermissionToCall(
        address _caller,
        address _target,
        bytes4 _functionSig,
        bool _enable
    ) internal {
        bool currentPermission = hasSpecialAccessToCall[_caller][_target][_functionSig];

        if (currentPermission != _enable) {
            hasSpecialAccessToCall[_caller][_target][_functionSig] = _enable;
            emit UpdateCallPermission(_caller, _target, _functionSig, _enable);
        }
    }

    /// @notice Starts the transfer of the ownership rights. Only the current owner can propose a new pending one.
    /// @notice New owner can accept owner rights by calling `acceptOwner` function.
    /// @param _newPendingOwner Address of the new owner
    function setPendingOwner(address _newPendingOwner) external onlyOwner {
        // Save previous value into the stack to put it into the event later
        address oldPendingOwner = pendingOwner;

        if (oldPendingOwner != _newPendingOwner) {
            // Change pending owner
            pendingOwner = _newPendingOwner;

            emit NewPendingOwner(oldPendingOwner, _newPendingOwner);
        }
    }

    /// @notice Accepts transfer of admin rights. Only the pending owner can accept the role.
    function acceptOwner() external {
        address newOwner = pendingOwner;
        require(msg.sender == newOwner, "n0"); // Only proposed by current owner address can claim the owner rights

        if (newOwner != owner) {
            owner = newOwner;
            delete pendingOwner;

            emit NewPendingOwner(newOwner, address(0));
            emit NewOwner(newOwner);
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



interface IAllowList {
    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice public access is changed
    event UpdatePublicAccess(address indexed target, bool newStatus);

    /// @notice permission to call is changed
    event UpdateCallPermission(address indexed caller, address indexed target, bytes4 indexed functionSig, bool status);

    /// @notice pendingOwner is changed
    /// @dev Also emitted when the new owner is accepted and in this case, `newPendingOwner` would be zero address
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    /// @notice Owner changed
    event NewOwner(address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function pendingOwner() external view returns (address);

    function owner() external view returns (address);

    function isAccessPublic(address _target) external view returns (bool);

    function hasSpecialAccessToCall(
        address _caller,
        address _target,
        bytes4 _functionSig
    ) external view returns (bool);

    function canCall(
        address _caller,
        address _target,
        bytes4 _functionSig
    ) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                           ALLOW LIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function setBatchPublicAccess(address[] calldata _targets, bool[] calldata _enables) external;

    function setPublicAccess(address _target, bool _enable) external;

    function setBatchPermissionToCall(
        address[] calldata _callers,
        address[] calldata _targets,
        bytes4[] calldata _functionSigs,
        bool[] calldata _enables
    ) external;

    function setPermissionToCall(
        address _caller,
        address _target,
        bytes4 _functionSig,
        bool _enable
    ) external;

    function setPendingOwner(address _newPendingOwner) external;

    function acceptOwner() external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



library UncheckedMath {
    function uncheckedInc(uint256 _number) internal pure returns (uint256) {
        unchecked {
            return _number + 1;
        }
    }

    function uncheckedAdd(uint256 _lhs, uint256 _rhs) internal pure returns (uint256) {
        unchecked {
            return _lhs + _rhs;
        }
    }
}