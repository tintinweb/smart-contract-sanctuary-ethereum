/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

/**
 *Submitted for verification at polygonscan.com on 2022-10-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File contracts/router/interfaces/SwapInfo.sol

pragma solidity ^0.8.6;

struct SwapInfo {
    bytes32 swapoutID;
    address token;
    address receiver;
    uint256 amount;
    uint256 fromChainID;
}


// File contracts/router/interfaces/IRouterSecurity.sol

pragma solidity ^0.8.10;

interface IRouterSecurity {
    function registerSwapin(string calldata swapID, SwapInfo calldata swapInfo)
        external;

    function registerSwapout(
        address token,
        address from,
        string calldata to,
        uint256 amount,
        uint256 toChainID,
        string calldata anycallProxy,
        bytes calldata data
    ) external returns (bytes32 swapoutID);

    function isSwapCompleted(
        string calldata swapID,
        bytes32 swapoutID,
        uint256 fromChainID
    ) external view returns (bool);
}


// File contracts/access/PausableControl.sol


pragma solidity ^0.8.10;

abstract contract PausableControl {
    mapping(bytes32 => bool) private _pausedRoles;

    bytes32 public constant PAUSE_ALL_ROLE = 0x00;

    event Paused(bytes32 role);
    event Unpaused(bytes32 role);

    modifier whenNotPaused(bytes32 role) {
        require(
            !paused(role) && !paused(PAUSE_ALL_ROLE),
            "PausableControl: paused"
        );
        _;
    }

    modifier whenPaused(bytes32 role) {
        require(
            paused(role) || paused(PAUSE_ALL_ROLE),
            "PausableControl: not paused"
        );
        _;
    }

    function paused(bytes32 role) public view virtual returns (bool) {
        return _pausedRoles[role];
    }

    function _pause(bytes32 role) internal virtual whenNotPaused(role) {
        _pausedRoles[role] = true;
        emit Paused(role);
    }

    function _unpause(bytes32 role) internal virtual whenPaused(role) {
        _pausedRoles[role] = false;
        emit Unpaused(role);
    }
}


// File contracts/common/Initializable.sol


pragma solidity ^0.8.10;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (address(this).code.length == 0 && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}


// File contracts/access/MPCManageableUpgradeable.sol


pragma solidity ^0.8.10;

abstract contract MPCManageableUpgradeable is Initializable {
    address public mpc;
    address public pendingMPC;

    uint256 public constant delay = 2 days;
    uint256 public delayMPC;

    modifier onlyMPC() {
        require(msg.sender == mpc, "MPC: only mpc");
        _;
    }

    event LogChangeMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 effectiveTime
    );
    event LogApplyMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint256 applyTime
    );

    function __MPCManageable_init(address _mpc) internal onlyInitializing {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        mpc = _mpc;
        emit LogChangeMPC(address(0), mpc, block.timestamp);
    }

    function changeMPC(address _mpc) external onlyMPC {
        require(_mpc != address(0), "MPC: mpc is the zero address");
        pendingMPC = _mpc;
        delayMPC = block.timestamp + delay;
        emit LogChangeMPC(mpc, pendingMPC, delayMPC);
    }

    // only the `pendingMPC` can `apply`
    // except when `pendingMPC` is a contract, then `mpc` can also `apply`
    // in case `pendingMPC` has no `apply` wrapper method and cannot `apply`
    function applyMPC() external {
        require(
            msg.sender == pendingMPC ||
                (msg.sender == mpc && address(pendingMPC).code.length > 0),
            "MPC: only pending mpc"
        );
        require(
            delayMPC > 0 && block.timestamp >= delayMPC,
            "MPC: time before delayMPC"
        );
        emit LogApplyMPC(mpc, pendingMPC, block.timestamp);
        mpc = pendingMPC;
        pendingMPC = address(0);
        delayMPC = 0;
    }
}


// File contracts/access/MPCAdminControlUpgradeable.sol


pragma solidity ^0.8.10;

abstract contract MPCAdminControlUpgradeable is MPCManageableUpgradeable {
    address public admin;

    event ChangeAdmin(address indexed _old, address indexed _new);

    function __AdminControl_init(address _admin) internal onlyInitializing {
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "MPCAdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyMPC {
        emit ChangeAdmin(admin, _admin);
        admin = _admin;
    }
}


// File contracts/access/MPCAdminPausableControlUpgradeable.sol


pragma solidity ^0.8.10;


abstract contract MPCAdminPausableControlUpgradeable is
    MPCAdminControlUpgradeable,
    PausableControl
{
    function pause(bytes32 role) external onlyAdmin {
        _pause(role);
    }

    function unpause(bytes32 role) external onlyAdmin {
        _unpause(role);
    }
}


// File contracts/router/security/MultichainV7RouterSecurityUpgradeable.sol


pragma solidity ^0.8.10;


abstract contract RoleControl is MPCAdminPausableControlUpgradeable {
    mapping(address => bool) public isSupportedCaller;
    address[] public supportedCallers;

    modifier onlyAuth() {
        require(isSupportedCaller[msg.sender], "not supported caller");
        _;
    }

    function getAllSupportedCallers() external view returns (address[] memory) {
        return supportedCallers;
    }

    function addSupportedCaller(address caller) external onlyAdmin {
        require(!isSupportedCaller[caller]);
        isSupportedCaller[caller] = true;
        supportedCallers.push(caller);
    }

    function removeSupportedCaller(address caller) external onlyAdmin {
        require(isSupportedCaller[caller]);
        isSupportedCaller[caller] = false;
        uint256 length = supportedCallers.length;
        for (uint256 i = 0; i < length; i++) {
            if (supportedCallers[i] == caller) {
                supportedCallers[i] = supportedCallers[length - 1];
                supportedCallers.pop();
                return;
            }
        }
    }
}

contract MultichainV7RouterSecurity is IRouterSecurity, RoleControl {
    bytes32 public constant Pause_Register_Swapin =
        keccak256("Pause_Register_Swapin");
    bytes32 public constant Pause_Register_Swapout =
        keccak256("Pause_Register_Swapout");
    bytes32 public constant Pause_Check_SwapID_Completion =
        keccak256("Pause_Check_SwapID_Completion");
    bytes32 public constant Pause_Check_SwapoutID_Completion =
        keccak256("Pause_Check_SwapoutID_Completion");

    mapping(string => bool) public completedSwapin;
    mapping(bytes32 => mapping(uint256 => bool)) public completedSwapoutID;
    mapping(bytes32 => uint256) public swapoutNonce;

    uint256 public currentSwapoutNonce;
    modifier autoIncreaseSwapoutNonce() {
        currentSwapoutNonce++;
        _;
    }

    modifier checkCompletion(
        string calldata swapID,
        bytes32 swapoutID,
        uint256 fromChainID
    ) {
        require(
            !completedSwapin[swapID] || paused(Pause_Check_SwapID_Completion),
            "swapID is completed"
        );
        require(
            !completedSwapoutID[swapoutID][fromChainID] ||
                paused(Pause_Check_SwapoutID_Completion),
            "swapoutID is completed"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _mpc) external initializer {
        __AdminControl_init(_admin);
        __MPCManageable_init(_mpc);
    }

    function isSwapoutIDExist(bytes32 swapoutID) external view returns (bool) {
        return swapoutNonce[swapoutID] != 0;
    }

    function isSwapCompleted(
        string calldata swapID,
        bytes32 swapoutID,
        uint256 fromChainID
    ) external view returns (bool) {
        return
            completedSwapin[swapID] ||
            completedSwapoutID[swapoutID][fromChainID];
    }

    function registerSwapin(string calldata swapID, SwapInfo calldata swapInfo)
        external
        onlyAuth
        whenNotPaused(Pause_Register_Swapin)
        checkCompletion(swapID, swapInfo.swapoutID, swapInfo.fromChainID)
    {
        completedSwapin[swapID] = true;
        completedSwapoutID[swapInfo.swapoutID][swapInfo.fromChainID] = true;
    }

    function registerSwapout(
        address token,
        address from,
        string calldata to,
        uint256 amount,
        uint256 toChainID,
        string calldata anycallProxy,
        bytes calldata data
    )
        external
        onlyAuth
        whenNotPaused(Pause_Register_Swapout)
        autoIncreaseSwapoutNonce
        returns (bytes32 swapoutID)
    {
        swapoutID = keccak256(
            abi.encode(
                address(this),
                msg.sender,
                token,
                from,
                to,
                amount,
                currentSwapoutNonce,
                toChainID,
                anycallProxy,
                data
            )
        );
        require(!this.isSwapoutIDExist(swapoutID), "swapoutID already exist");
        swapoutNonce[swapoutID] = currentSwapoutNonce;
        return swapoutID;
    }
}