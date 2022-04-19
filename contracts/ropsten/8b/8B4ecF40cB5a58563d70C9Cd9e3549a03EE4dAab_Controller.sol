// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IController.sol";
import "./IManaged.sol";
import "./Governed.sol";
import "./Pausable.sol";

/**
 * @title Graph Controller contract
 * @dev Controller is a registry of contracts for convenience. Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */

contract Controller is Governed, Pausable, IController {
    // Track contract ids to contract proxy address
    mapping(bytes32 => address) private registry;

    event SetContractProxy(bytes32 indexed id, address contractAddress);

    /** 
     * @dev Contract constructor.
     */
    constructor() {
        Governed._initialize(msg.sender);

        _setPaused(true);
    }

    /**
     * @dev Check if the caller is the governor or pause guardian.
     */
    modifier onlyGovernorOrGuardian {
        require(
            msg.sender == governor || msg.sender == pauseGuardian,
            "Only Governor or Guardian can call"
        );
        _;
    }

    /**
     * @notice Getter to access governor
     */
    function getGovernor() external override view returns (address) {
        return governor;
    }

    // -- Registry --

    /**
     * @notice Register contract id and mapped address
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _contractAddress Contract address
     */
    function setContractProxy(bytes32 _id, address _contractAddress)
        external
        override
        onlyGovernor
    {
        require(_contractAddress != address(0), "Contract address must be set");
        registry[_id] = _contractAddress;
        emit SetContractProxy(_id, _contractAddress);
    }

    /**
     * @notice Unregister a contract address
     * @param _id Contract id (keccak256 hash of contract name)
     */
    function unsetContractProxy(bytes32 _id)
        external
        override
        onlyGovernor
    {
        registry[_id] = address(0);
        emit SetContractProxy(_id, address(0));
    }

    /**
     * @notice Get contract proxy address by its id
     * @param _id Contract id
     */
    function getContractProxy(bytes32 _id) public override view returns (address) {
        return registry[_id];
    }

    /**
     * @notice Update contract's controller
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _controller Controller address
     */
    function updateController(bytes32 _id, address _controller) external override onlyGovernor {
        require(_controller != address(0), "Controller must be set");
        return IManaged(registry[_id]).setController(_controller);
    }

    // -- Pausing --

    /**
     * @notice Change the partial paused state of the contract
     * Partial pause is intended as a partial pause of the protocol
     */
    function setPartialPaused(bool _partialPaused) external override onlyGovernorOrGuardian {
        _setPartialPaused(_partialPaused);
    }

    /**
     * @notice Change the paused state of the contract
     * Full pause most of protocol functions
     */
    function setPaused(bool _paused) external override onlyGovernorOrGuardian {
        _setPaused(_paused);
    }

    /**
     * @notice Change the Pause Guardian
     * @param _newPauseGuardian The address of the new Pause Guardian
     */
    function setPauseGuardian(address _newPauseGuardian) external override onlyGovernor {
        require(_newPauseGuardian != address(0), "PauseGuardian must be set");
        _setPauseGuardian(_newPauseGuardian);
    }

    /**
     * @notice Getter to access paused
     */
    function paused() external override view returns (bool) {
        return _paused;
    }

    /**
     * @notice Getter to access partial pause status
     */
    function partialPaused() external override view returns (bool) {
        return _partialPaused;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12 <0.8.0;

interface IController {
    function getGovernor() external view returns (address);

    // -- Registry --

    function setContractProxy(bytes32 _id, address _contractAddress) external;

    function unsetContractProxy(bytes32 _id) external;

    function updateController(bytes32 _id, address _controller) external;

    function getContractProxy(bytes32 _id) external view returns (address);

    // -- Pausing --

    function setPartialPaused(bool _partialPaused) external;

    function setPaused(bool _paused) external;

    function setPauseGuardian(address _newPauseGuardian) external;

    function paused() external view returns (bool);

    function partialPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IManaged {
    function setController(address _controller) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

/**
 * @title Graph Governance contract
 * @dev All contracts that will be owned by a Governor entity should extend this contract.
 */
contract Governed {
    // -- State --

    address public governor;
    address public pendingGovernor;

    // -- Events --

    event NewPendingOwnership(address indexed from, address indexed to);
    event NewOwnership(address indexed from, address indexed to);

    /**
     * @dev Check if the caller is the governor.
     */
    modifier onlyGovernor {
        require(msg.sender == governor, "Only Governor can call");
        _;
    }

    /**
     * @dev Initialize the governor to the contract caller.
     */
    function _initialize(address _initGovernor) internal {
        governor = _initGovernor;
    }

    /**
     * @dev Admin function to begin change of governor. The `_newGovernor` must call
     * `acceptOwnership` to finalize the transfer.
     * @param _newGovernor Address of new `governor`
     */
    function transferOwnership(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "Governor must be set");

        address oldPendingGovernor = pendingGovernor;
        pendingGovernor = _newGovernor;

        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }

    /**
     * @dev Admin function for pending governor to accept role and update governor.
     * This function must called by the pending governor.
     */
    function acceptOwnership() external {
        require(
            pendingGovernor != address(0) && msg.sender == pendingGovernor,
            "Caller must be pending governor"
        );

        address oldGovernor = governor;
        address oldPendingGovernor = pendingGovernor;

        governor = pendingGovernor;
        pendingGovernor = address(0);

        emit NewOwnership(oldGovernor, governor);
        emit NewPendingOwnership(oldPendingGovernor, pendingGovernor);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

contract Pausable {
    // Partial paused paused exit and enter functions for GRT, but not internal
    // functions, such as allocating
    bool internal _partialPaused;
    // Paused will pause all major protocol functions
    bool internal _paused;

    // Time last paused for both pauses
    uint256 public lastPausePartialTime;
    uint256 public lastPauseTime;

    // Pause guardian is a separate entity from the governor that can pause
    address public pauseGuardian;

    event PartialPauseChanged(bool isPaused);
    event PauseChanged(bool isPaused);
    event NewPauseGuardian(address indexed oldPauseGuardian, address indexed pauseGuardian);

    /**
     * @notice Change the partial paused state of the contract
     */
    function _setPartialPaused(bool _toPause) internal {
        if (_toPause == _partialPaused) {
            return;
        }
        _partialPaused = _toPause;
        if (_partialPaused) {
            lastPausePartialTime = block.timestamp;
        }
        emit PartialPauseChanged(_partialPaused);
    }

    /**
     * @notice Change the paused state of the contract
     */
    function _setPaused(bool _toPause) internal {
        if (_toPause == _paused) {
            return;
        }
        _paused = _toPause;
        if (_paused) {
            lastPauseTime = block.timestamp;
        }
        emit PauseChanged(_paused);
    }

    /**
     * @notice Change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     */
    function _setPauseGuardian(address newPauseGuardian) internal {
        address oldPauseGuardian = pauseGuardian;
        pauseGuardian = newPauseGuardian;
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);
    }
}