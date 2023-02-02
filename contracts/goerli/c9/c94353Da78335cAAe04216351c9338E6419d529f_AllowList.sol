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
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./interfaces/IAllowList.sol";
import "./libraries/UncheckedMath.sol";

/// @author Matter Labs
/// @notice The smart contract that stores the permissions to call the function on different contracts.
/// @dev The contract is fully controlled by the owner, that can grant and revoke any permissions at any time.
/// @dev The permission list has three different modes:
/// - Closed. The contract can NOT be called by anyone.
/// - SpecialAccessOnly. Only some contract functions can be called by specifically granted addresses.
/// - Public. Access list to call any function from the target contract by any caller
contract AllowList is IAllowList, Ownable2Step {
    using UncheckedMath for uint256;

    /// @notice The Access mode by which it is decided whether the caller has access
    mapping(address => AccessMode) public getAccessMode;

    /// @notice The mapping that stores permissions to call the function on the target address by the caller
    /// @dev caller => target => function signature => permission to call target function for the given caller address
    mapping(address => mapping(address => mapping(bytes4 => bool))) public hasSpecialAccessToCall;

    /// @dev The mapping L1 token address => struct Withdrawal
    mapping(address => Withdrawal) public tokenWithdrawal;

    /// @dev The mapping L1 token address => struct Deposit
    mapping(address => Deposit) public tokenDeposit;

    constructor(address _owner) {
        _transferOwnership(_owner);
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
        AccessMode accessMode = getAccessMode[_target];
        return
            accessMode == AccessMode.Public ||
            (accessMode == AccessMode.SpecialAccessOnly && hasSpecialAccessToCall[_caller][_target][_functionSig]);
    }

    /// @notice Set the permission mode to call the target contract
    /// @param _target The address of the smart contract, of which access to the call is to be changed
    /// @param _accessMode Whether no one, any or only some addresses can call the target contract
    function setAccessMode(address _target, AccessMode _accessMode) external onlyOwner {
        _setAccessMode(_target, _accessMode);
    }

    /// @notice Set many permission modes to call the target contracts
    /// @dev Analogous to function `setAccessMode` but performs a batch of changes
    /// @param _targets The array of smart contract addresses, of which access to the call is to be changed
    /// @param _accessModes The array of new permission modes, whether no one, any or only some addresses can call the target contract
    function setBatchAccessMode(address[] calldata _targets, AccessMode[] calldata _accessModes) external onlyOwner {
        uint256 targetsLength = _targets.length;
        require(targetsLength == _accessModes.length, "yg"); // The size of arrays should be equal

        for (uint256 i = 0; i < targetsLength; i = i.uncheckedInc()) {
            _setAccessMode(_targets[i], _accessModes[i]);
        }
    }

    /// @dev Changes access mode and emit the event if the access was changed
    function _setAccessMode(address _target, AccessMode _accessMode) internal {
        AccessMode accessMode = getAccessMode[_target];

        if (accessMode != _accessMode) {
            getAccessMode[_target] = _accessMode;
            emit UpdateAccessMode(_target, accessMode, _accessMode);
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

        // The size of arrays should be equal
        require(callersLength == _targets.length, "yw");
        require(callersLength == _functionSigs.length, "yx");
        require(callersLength == _enables.length, "yy");

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

    /// @dev Set withdrwal limit data for a token
    /// @param _l1Token The address of L1 token
    /// @param _withdrawalLimitation withdrawal limitation is active or not
    /// @param _withdrawalFactor The percentage of allowed withdrawal. A withdrawalFactor of 10 means maximum %10 of bridge balance can be withdrawn
    function setWithdrawalLimit(
        address _l1Token,
        bool _withdrawalLimitation,
        uint256 _withdrawalFactor
    ) external onlyOwner {
        require(_withdrawalFactor <= 100, "wf");
        tokenWithdrawal[_l1Token].withdrawalLimitation = _withdrawalLimitation;
        tokenWithdrawal[_l1Token].withdrawalFactor = _withdrawalFactor;
    }

    /// @dev Get withdrawal limit data of a token
    /// @param _l1Token The address of L1 token
    function getTokenWithdrawalLimitData(address _l1Token) external view returns (Withdrawal memory) {
        return tokenWithdrawal[_l1Token];
    }

    /// @dev Set deposit limit data for a token
    /// @param _l1Token The address of L1 token
    /// @param _depositLimitation deposit limitation is active or not
    /// @param _depositCap The maximum amount that can be deposited.
    function setDepositLimit(
        address _l1Token,
        bool _depositLimitation,
        uint256 _depositCap
    ) external onlyOwner {
        tokenDeposit[_l1Token].depositLimitation = _depositLimitation;
        tokenDeposit[_l1Token].depositCap = _depositCap;
    }

    /// @dev Get deposit limit data of a token
    /// @param _l1Token The address of L1 token
    function getTokenDepositLimitData(address _l1Token) external view returns (Deposit memory) {
        return tokenDeposit[_l1Token];
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



interface IAllowList {
    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Access mode of target contract is changed
    event UpdateAccessMode(address indexed target, AccessMode previousMode, AccessMode newMode);

    /// @notice Permission to call is changed
    event UpdateCallPermission(address indexed caller, address indexed target, bytes4 indexed functionSig, bool status);

    /// @notice Type of access to a specific contract includes three different modes
    /// @param Closed No one has access to the contract
    /// @param SpecialAccessOnly Any address with granted special access can interact with a contract (see `hasSpecialAccessToCall`)
    /// @param Public Everyone can interact with a contract
    enum AccessMode {
        Closed,
        SpecialAccessOnly,
        Public
    }

    /// @dev A struct that contains withdrawal limit data of a token
    /// @param withdrawalLimitation Whether any withdrawal limitation is placed or not
    /// @param withdrawalFactor Percentage of allowed withdrawal. A withdrawalFactor of 10 means maximum %10 of bridge balance can be withdrawn
    struct Withdrawal {
        bool withdrawalLimitation;
        uint256 withdrawalFactor;
    }

    /// @dev A struct that contains deposit limit data of a token
    /// @param depositLimitation Whether any deposit limitation is placed or not
    /// @param depositCap The maximum amount that can be deposited.
    struct Deposit {
        bool depositLimitation;
        uint256 depositCap;
    }

    /*//////////////////////////////////////////////////////////////
                            GETTERS
    //////////////////////////////////////////////////////////////*/

    function getAccessMode(address _target) external view returns (AccessMode);

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

    function getTokenWithdrawalLimitData(address _l1Token) external view returns (Withdrawal memory);

    function getTokenDepositLimitData(address _l1Token) external view returns (Deposit memory);

    /*//////////////////////////////////////////////////////////////
                           ALLOW LIST LOGIC
    //////////////////////////////////////////////////////////////*/

    function setBatchAccessMode(address[] calldata _targets, AccessMode[] calldata _accessMode) external;

    function setAccessMode(address _target, AccessMode _accessMode) external;

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

    /*//////////////////////////////////////////////////////////////
                           WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setWithdrawalLimit(
        address _l1Token,
        bool _withdrawalLimitation,
        uint256 _withdrawalFactor
    ) external;

    /*//////////////////////////////////////////////////////////////
                           DEPOSIT LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setDepositLimit(
        address _l1Token,
        bool _depositLimitation,
        uint256 _depositCap
    ) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



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