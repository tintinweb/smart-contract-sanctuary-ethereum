// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "./interfaces/IEpochs.sol";

import {EpochsErrors} from "./Errors.sol";
import "./OctantBase.sol";

/// @title Epochs
/// @notice Contract which handles Octant epochs mechanism.
/// Epoch duration and time when decision window is open is calculated in seconds.
/// These values are set when deploying a contract but can later be changed by calling
/// {setEpochProps} function.
contract Epochs is OctantBase, IEpochs {

    /// @dev Struct to store the properties of an epoch.
    /// @param from The epoch number from which properties are valid (inclusive).
    /// @param fromTs Timestamp from which properties are valid.
    /// @param to The epoch number to which properties are valid (inclusive).
    /// @param duration Epoch duration in seconds.
    /// @param decisionWindow Decision window in seconds.
    /// This value represents time, when participant can allocate funds to projects.
    /// It must be smaller or equal to {epochDuration}.
    struct EpochProps {
        uint256 from;
        uint256 fromTs;
        uint256 to;
        uint256 duration;
        uint256 decisionWindow;
    }

    /// @notice Timestamp when octant starts.
    uint256 public start;

    /// @dev Index of current or next epoch properties in epochProps mapping.
    uint256 public epochPropsIndex;

    /// @dev Mapping to store all properties of epochs.
    mapping(uint256 => EpochProps) public epochProps;

    /// @dev Constructor to initialize start and the first epoch properties.
    /// @param _start Timestamp when octant starts.
    /// @param _epochDuration Duration of an epoch in seconds.
    /// @param _decisionWindow Decision window in seconds for the first epoch.
    constructor(
        uint256 _start,
        uint256 _epochDuration,
        uint256 _decisionWindow,
        address _auth)
    OctantBase(_auth) {
        start = _start;
        epochProps[0] = EpochProps({from: 1, fromTs: start, to: 0, duration: _epochDuration, decisionWindow: _decisionWindow});
    }

    /// @notice Get the current epoch number.
    /// @dev Will revert when calling before the first epoch started.
    /// @return The current epoch number, number in range [1, inf)
    function getCurrentEpoch() public view returns (uint32) {
        require(isStarted(), EpochsErrors.NOT_STARTED);
        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        if (_currentEpochProps.to != 0) {
            return uint32(_currentEpochProps.to);
        }
        return uint32(((block.timestamp - _currentEpochProps.fromTs) / _currentEpochProps.duration) + _currentEpochProps.from);
    }

    /// @notice Gets the number of the last epoch for which the decision window has already ended.
    /// @dev Will revert when calling before the first epoch is finalized.
    /// @return The finalized epoch number, number in range [1, inf)
    function getFinalizedEpoch() external view returns (uint32) {
        uint32 currentEpoch = getCurrentEpoch();
        bool isWindowOpen = isDecisionWindowOpen();

        // Ensure we are not in the first epoch and not in the second one with the decision window still open
        require(currentEpoch > 1 && !(currentEpoch == 2 && isWindowOpen), EpochsErrors.NOT_FINALIZED);

        // If the decision window is still open, we return the previous to last epoch as the last finalized one.
        // If the decision window is closed, we return the last epoch as the last finalized one.
        if (isWindowOpen) {
            return currentEpoch - 2;
        }
        return currentEpoch - 1;
    }

    /// @notice Gets the number of the epoch for which the decision window is currently open.
    /// @dev Will revert when calling during closed decision window.
    /// @return The pending epoch number, number in range [1, inf)
    function getPendingEpoch() external view returns (uint32) {
        require(isDecisionWindowOpen(), EpochsErrors.NOT_PENDING);
        return getCurrentEpoch() - 1;
    }

    /// @dev Returns the duration of current epoch.
    /// @return The duration of current epoch in seconds.
    function getEpochDuration() external view returns (uint256) {
        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        return _currentEpochProps.duration;
    }

    /// @dev Returns the duration of the decision window in current epoch.
    /// @return The the duration of the decision window in current epoch in seconds.
    function getDecisionWindow() external view returns (uint256) {
        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        return _currentEpochProps.decisionWindow;
    }

    /// @return bool Whether the decision window is currently open or not.
    function isDecisionWindowOpen() public view returns (bool) {
        uint32 _currentEpoch = getCurrentEpoch();
        if (_currentEpoch == 1) {
            return false;
        }

        EpochProps memory _currentEpochProps = getCurrentEpochProps();
        uint256 moduloEpoch = uint256(
            (block.timestamp - _currentEpochProps.fromTs) % _currentEpochProps.duration
        );
        return moduloEpoch <= _currentEpochProps.decisionWindow;
    }

    /// @return bool Whether Octant has started or not.
    function isStarted() public view returns (bool) {
        return block.timestamp >= start;
    }

    /// @dev Sets the epoch properties of the next epoch.
    /// @param _epochDuration Epoch duration in seconds.
    /// @param _decisionWindow Decision window in seconds.
    function setEpochProps(uint256 _epochDuration, uint256 _decisionWindow) external onlyMultisig {
        require(_epochDuration >= _decisionWindow, EpochsErrors.DECISION_WINDOW_TOO_BIG);
        EpochProps memory _props = getCurrentEpochProps();

        // Next epoch props set up for the first time in this epoch. Storing the new props under
        // incremented epochPropsIndex.
        if (_props.to == 0) {
            uint32 _currentEpoch = getCurrentEpoch();
            uint256 _currentEpochEnd = _calculateCurrentEpochEnd(_currentEpoch, _props);
            epochProps[epochPropsIndex].to = _currentEpoch;
            epochProps[epochPropsIndex + 1] = EpochProps({from: _currentEpoch + 1, fromTs: _currentEpochEnd,
                to: 0, duration: _epochDuration, decisionWindow: _decisionWindow});
            epochPropsIndex = epochPropsIndex + 1;
            // Next epoch props were set up before, props are being updated. EpochPropsIndex has been
            // updated already, changing props in the latest epochPropsIndex
        } else {
            epochProps[epochPropsIndex].duration = _epochDuration;
            epochProps[epochPropsIndex].decisionWindow = _decisionWindow;
        }
    }

    /// @dev Gets the epoch properties of current epoch.
    function getCurrentEpochProps() public view returns (EpochProps memory) {
        if (epochProps[epochPropsIndex].fromTs > block.timestamp) {
            return epochProps[epochPropsIndex - 1];
        }
        return epochProps[epochPropsIndex];
    }

    /// @dev Gets current epoch end timestamp.
    function getCurrentEpochEnd() external view returns (uint256) {
        uint32 _currentEpoch = getCurrentEpoch();
        EpochProps memory _props = getCurrentEpochProps();
        return _calculateCurrentEpochEnd(_currentEpoch, _props);
    }

    /// @dev Calculates current epoch end timestamp.
    function _calculateCurrentEpochEnd(uint32 _currentEpoch, EpochProps memory _props) private pure returns (uint256) {
        return _props.fromTs + _props.duration * (1 + _currentEpoch - _props.from);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import {CommonErrors} from "./Errors.sol";

/// @title Auth
contract Auth {

    /// @dev Emitted when the Golem Foundation multisig address is set.
    /// @param oldValue The old Golem Foundation multisig address.
    /// @param newValue The new Golem Foundation multisig address.
    event MultisigSet(address oldValue, address newValue);

    /// @dev Emitted when the deployer address is set.
    /// @param oldValue The old deployer address.
    event DeployerRenounced(address oldValue);

    /// @dev Emitted when ownership transfer is initiated.
    /// @param previousOwner Old multisig, one that initiated the process.
    /// @param newOwner New multisig, one that should finalize the process.
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /// @dev The deployer address.
    address public deployer;

    /// @dev The multisig address.
    address public multisig;

    /// @dev Pending multisig address.
    address public pendingOwner;

    /// @param _multisig The initial Golem Foundation multisig address.
    constructor(address _multisig) {
        multisig = _multisig;
        deployer = msg.sender;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external {
        require(msg.sender == multisig, CommonErrors.UNAUTHORIZED_CALLER);
        pendingOwner = newOwner;
        emit OwnershipTransferStarted(multisig, newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, CommonErrors.UNAUTHORIZED_CALLER);
        emit MultisigSet(multisig, pendingOwner);
        multisig = pendingOwner;
        pendingOwner = address(0);
    }

    /// @dev Leaves the contract without a deployer. It will not be possible to call
    /// `onlyDeployer` functions. Can only be called by the current deployer.
    function renounceDeployer() external {
        require(msg.sender == deployer, CommonErrors.UNAUTHORIZED_CALLER);
        emit DeployerRenounced(deployer);
        deployer = address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

library DepositsErrors {
    /// @notice Thrown when transfer operation fails in GLM smart contract.
    /// @return HN:Deposits/cannot-transfer-from-sender
    string public constant GLM_TRANSFER_FAILED =
    "HN:Deposits/cannot-transfer-from-sender";

    /// @notice Thrown when trying to withdraw more GLMs than are in deposit.
    /// @return HN:Deposits/deposit-is-smaller
    string public constant DEPOSIT_IS_TO_SMALL =
    "HN:Deposits/deposit-is-smaller";
}

library EpochsErrors {
    /// @notice Thrown when calling the contract before the first epoch started.
    /// @return HN:Epochs/not-started-yet
    string public constant NOT_STARTED = "HN:Epochs/not-started-yet";

    /// @notice Thrown when getFinalizedEpoch function is called before any epoch has been finalized.
    /// @return HN:Epochs/not-finalized
    string public constant NOT_FINALIZED = "HN:Epochs/not-finalized";

    /// @notice Thrown when getPendingEpoch function is called during closed decision window.
    /// @return HN:Epochs/not-pending
    string public constant NOT_PENDING = "HN:Epochs/not-pending";

    /// @notice Thrown when updating epoch props to invalid values (decision window bigger than epoch duration.
    /// @return HN:Epochs/decision-window-bigger-than-duration
    string public constant DECISION_WINDOW_TOO_BIG = "HN:Epochs/decision-window-bigger-than-duration";
}

library ProposalsErrors {
    /// @notice Thrown when trying to change proposals that could already have been voted upon.
    /// @return HN:Proposals/only-future-proposals-changing-is-allowed
    string public constant CHANGING_PROPOSALS_IN_THE_PAST =
    "HN:Proposals/only-future-proposals-changing-is-allowed";
}

library VaultErrors {
    /// @notice Thrown when trying to set merkle root for an epoch multiple times.
    /// @return HN:Vault/merkle-root-already-set
    string public constant MERKLE_ROOT_ALREADY_SET = "HN:Vault/merkle-root-already-set";

    /// @notice Thrown when trying to withdraw without providing valid merkle proof.
    /// @return HN:Vault/invalid-merkle-proof
    string public constant INVALID_MERKLE_PROOF = "HN:Vault/invalid-merkle-proof";

    /// @notice Thrown when trying to withdraw multiple times.
    /// @return HN:Vault/already-claimed
    string public constant ALREADY_CLAIMED = "HN:Vault/already-claimed";
}

library CommonErrors {
    /// @notice Thrown when trying to call as an unauthorized account.
    /// @return HN:Common/unauthorized-caller
    string public constant UNAUTHORIZED_CALLER =
    "HN:Common/unauthorized-caller";

    /// @notice Thrown when failed to send eth.
    /// @return HN:Vault/failed-to-send
    string public constant FAILED_TO_SEND = "HN:Vault/failed-to-send";
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import {CommonErrors} from "./Errors.sol";
import "./Auth.sol";

/// @title OctantBase
/// @dev This is the base contract for all Octant contracts that have functions with access restricted
/// to deployer or the Golem Foundation multisig.
/// It provides functionality for setting and accessing the Golem Foundation multisig address.
abstract contract OctantBase {

    /// @dev The Auth contract instance
    Auth auth;

    /// @param _auth the contract containing Octant authorities.
    constructor(address _auth) {
        auth = Auth(_auth);
    }

    /// @dev Gets the Golem Foundation multisig address.
    function getMultisig() internal view returns (address) {
        return auth.multisig();
    }

    /// @dev Modifier that allows only the Golem Foundation multisig address to call a function.
    modifier onlyMultisig() {
        require(msg.sender == auth.multisig(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }

    /// @dev Modifier that allows only deployer address to call a function.
    modifier onlyDeployer() {
        require(msg.sender == auth.deployer(), CommonErrors.UNAUTHORIZED_CALLER);
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IEpochs {
    function getCurrentEpoch() external view returns (uint32);

    function getEpochDuration() external view returns (uint256);

    function getDecisionWindow() external view returns (uint256);

    function isStarted() external view returns (bool);

    function isDecisionWindowOpen() external view returns (bool);
}