/*
Configuration

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IConfiguration.sol";
import "./OwnerController.sol";

/**
 * @title Configuration
 *
 * @notice configuration contract to define global variables for GYSR protocol
 */
contract Configuration is IConfiguration, OwnerController {
    // data
    mapping(bytes32 => uint256) private _data;
    mapping(address => mapping(bytes32 => uint256)) _overrides;

    /**
     * @inheritdoc IConfiguration
     */
    function setUint256(
        bytes32 key,
        uint256 value
    ) external override onlyController {
        _data[key] = value;
        emit ParameterUpdated(key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function setAddress(
        bytes32 key,
        address value
    ) external override onlyController {
        _data[key] = uint256(uint160(value));
        emit ParameterUpdated(key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function setAddressUint96(
        bytes32 key,
        address value0,
        uint96 value1
    ) external override onlyController {
        uint256 val = uint256(uint160(value0));
        val |= uint256(value1) << 160;
        _data[key] = val;
        emit ParameterUpdated(key, value0, value1);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function getUint256(bytes32 key) external view override returns (uint256) {
        if (_overrides[msg.sender][key] > 0) return _overrides[msg.sender][key];
        return _data[key];
    }

    /**
     * @inheritdoc IConfiguration
     */
    function getAddress(bytes32 key) external view override returns (address) {
        if (_overrides[msg.sender][key] > 0)
            return address(uint160(_overrides[msg.sender][key]));
        return address(uint160(_data[key]));
    }

    /**
     * @inheritdoc IConfiguration
     */
    function getAddressUint96(
        bytes32 key
    ) external view override returns (address, uint96) {
        uint256 val = _overrides[msg.sender][key] > 0
            ? _overrides[msg.sender][key]
            : _data[key];
        return (address(uint160(val)), uint96(val >> 160));
    }

    /**
     * @inheritdoc IConfiguration
     */
    function overrideUint256(
        address caller,
        bytes32 key,
        uint256 value
    ) external override onlyController {
        _overrides[caller][key] = value;
        emit ParameterOverridden(caller, key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function overrideAddress(
        address caller,
        bytes32 key,
        address value
    ) external override onlyController {
        uint256 val = uint256(uint160(value));
        _overrides[caller][key] = val;
        emit ParameterOverridden(caller, key, value);
    }

    /**
     * @inheritdoc IConfiguration
     */
    function overrideAddressUint96(
        address caller,
        bytes32 key,
        address value0,
        uint96 value1
    ) external override onlyController {
        uint256 val = uint256(uint160(value0));
        val |= uint256(value1) << 160;
        _overrides[caller][key] = val;
        emit ParameterOverridden(caller, key, value0, value1);
    }
}

/*
IConfiguration

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Configuration interface
 *
 * @notice this defines the protocol configuration interface
 */
interface IConfiguration {
    // events
    event ParameterUpdated(bytes32 indexed key, address value);
    event ParameterUpdated(bytes32 indexed key, uint256 value);
    event ParameterUpdated(bytes32 indexed key, address value0, uint96 value1);
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        uint256 value
    );
    event ParameterOverridden(
        address indexed caller,
        bytes32 indexed key,
        address value0,
        uint96 value1
    );

    /**
     * @notice set or update uint256 parameter
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function setUint256(bytes32 key, uint256 value) external;

    /**
     * @notice set or update address parameter
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function setAddress(bytes32 key, address value) external;

    /**
     * @notice set or update packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function setAddressUint96(
        bytes32 key,
        address value0,
        uint96 value1
    ) external;

    /**
     * @notice get uint256 parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice get address parameter
     * @param key keccak256 hash of parameter key
     * @return uint256 parameter value
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @notice get packed address + uint96 pair
     * @param key keccak256 hash of parameter key
     * @return address parameter value
     * @return uint96 parameter value
     */
    function getAddressUint96(
        bytes32 key
    ) external view returns (address, uint96);

    /**
     * @notice override uint256 parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value uint256 parameter value
     */
    function overrideUint256(
        address caller,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value address parameter value
     */
    function overrideAddress(
        address caller,
        bytes32 key,
        address value
    ) external;

    /**
     * @notice override address parameter for specific caller
     * @param caller address of caller
     * @param key keccak256 hash of parameter key
     * @param value0 address parameter value
     * @param value1 uint96 parameter value
     */
    function overrideAddressUint96(
        address caller,
        bytes32 key,
        address value0,
        uint96 value1
    ) external;
}

/*
IOwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Owner controller interface
 *
 * @notice this defines the interface for any contracts that use the
 * owner controller access pattern
 */
interface IOwnerController {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() external view returns (address);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) external;
}

/*
OwnerController

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

import "./interfaces/IOwnerController.sol";

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController is IOwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view override returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "oc1");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "oc2");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "oc1");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "oc2");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override {
        requireOwner();
        require(newOwner != address(0), "oc3");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual override {
        requireOwner();
        require(newController != address(0), "oc4");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}