/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// File: contracts/router/interfaces/SwapInfo.sol


pragma solidity ^0.8.6;

struct SwapInfo {
    bytes32 swapoutID;
    address token;
    address receiver;
    uint256 amount;
    uint256 fromChainID;
}

// File: contracts/router/interfaces/IRouterSecurity.sol


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

// File: contracts/access/PausableControl.sol



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

// File: contracts/access/MPCManageable.sol



pragma solidity ^0.8.10;

abstract contract MPCManageable {
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

    constructor(address _mpc) {
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

// File: contracts/access/MPCAdminControl.sol



pragma solidity ^0.8.10;


abstract contract MPCAdminControl is MPCManageable {
    address public admin;

    event ChangeAdmin(address indexed _old, address indexed _new);

    constructor(address _admin, address _mpc) MPCManageable(_mpc) {
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

// File: contracts/access/MPCAdminPausableControl.sol



pragma solidity ^0.8.10;



abstract contract MPCAdminPausableControl is MPCAdminControl, PausableControl {
    constructor(address _admin, address _mpc) MPCAdminControl(_admin, _mpc) {}

    function pause(bytes32 role) external onlyAdmin {
        _pause(role);
    }

    function unpause(bytes32 role) external onlyAdmin {
        _unpause(role);
    }
}

// File: contracts/router/security/MultichainV7RouterSecurity.sol



pragma solidity ^0.8.10;



abstract contract RoleControl is MPCAdminPausableControl {
    mapping(address => bool) public isSupportedCaller;
    address[] public supportedCallers;

    modifier onlyAuth() {
        require(isSupportedCaller[msg.sender], "not supported caller");
        _;
    }

    constructor(address _admin, address _mpc)
        MPCAdminPausableControl(_admin, _mpc)
    {}

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

    constructor(address _admin, address _mpc) RoleControl(_admin, _mpc) {}

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