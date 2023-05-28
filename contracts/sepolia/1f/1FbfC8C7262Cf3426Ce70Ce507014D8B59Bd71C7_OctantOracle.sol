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

    /// @dev The deployer address.
    address public deployer;

    /// @dev The multisig address.
    address public multisig;

    /// @param _multisig The initial Golem Foundation multisig address.
    constructor(address _multisig) {
        multisig = _multisig;
        deployer = msg.sender;
    }

    /// @dev Sets the multisig address.
    /// @param _multisig The new multisig address.
    function setMultisig(address _multisig) external {
        require(msg.sender == multisig, CommonErrors.UNAUTHORIZED_CALLER);
        emit MultisigSet(multisig, _multisig);
        multisig = _multisig;
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
        epochProps[0] = EpochProps({from : 1, fromTs: block.timestamp, to : 0, duration : _epochDuration, decisionWindow : _decisionWindow});
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
        require(isStarted(), EpochsErrors.NOT_STARTED);
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
            epochProps[epochPropsIndex + 1] = EpochProps({from : _currentEpoch + 1, fromTs: _currentEpochEnd,
            to : 0, duration : _epochDuration, decisionWindow : _decisionWindow});
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
        if(epochProps[epochPropsIndex].fromTs > block.timestamp) {
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

library AllocationErrors {
    /// @notice Thrown when the user trying to allocate before first epoch has started
    /// @return HN:Allocations/not-started-yet
    string public constant EPOCHS_HAS_NOT_STARTED_YET =
        "HN:Allocations/first-epoch-not-started-yet";

    /// @notice Thrown when the user trying to allocate after decision window is closed
    /// @return HN:Allocations/decision-window-closed
    string public constant DECISION_WINDOW_IS_CLOSED =
        "HN:Allocations/decision-window-closed";

    /// @notice Thrown when user trying to allocate more than he has in rewards budget for given epoch.
    /// @return HN:Allocations/allocate-above-rewards-budget
    string public constant ALLOCATE_ABOVE_REWARDS_BUDGET =
        "HN:Allocations/allocate-above-rewards-budget";

    /// @notice Thrown when user trying to allocate to a proposal that does not exist.
    /// @return HN:Allocations/no-such-proposal
    string public constant ALLOCATE_TO_NON_EXISTING_PROPOSAL =
        "HN:Allocations/no-such-proposal";
}

library OracleErrors {
    /// @notice Thrown when trying to set the balance in oracle for epochs other then previous.
    /// @return HN:Oracle/can-set-balance-for-previous-epoch-only
    string public constant CANNOT_SET_BALANCE_FOR_PAST_EPOCHS =
        "HN:Oracle/can-set-balance-for-previous-epoch-only";

    /// @notice Thrown when trying to set the balance in oracle when balance can't yet be determined.
    /// @return HN:Oracle/can-set-balance-at-earliest-in-second-epoch
    string public constant BALANCE_CANT_BE_KNOWN =
        "HN:Oracle/can-set-balance-at-earliest-in-second-epoch";

    /// @notice Thrown when trying to set the oracle balance multiple times.
    /// @return HN:Oracle/balance-for-given-epoch-already-exists
    string public constant BALANCE_ALREADY_SET =
        "HN:Oracle/balance-for-given-epoch-already-exists";

    /// @notice Thrown if contract is misconfigured
    /// @return HN:Oracle/WithdrawalsTarget-not-set
    string public constant NO_TARGET =
        "HN:Oracle/WithdrawalsTarget-not-set";

    /// @notice Thrown if contract is misconfigured
    /// @return HN:Oracle/PayoutsManager-not-set
    string public constant NO_PAYOUTS_MANAGER =
        "HN:Oracle/PayoutsManager-not-set";

}

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

    /// @notice Thrown when updating epoch props to invalid values (decision window bigger than epoch duration.
    /// @return HN:Epochs/decision-window-bigger-than-duration
    string public constant DECISION_WINDOW_TOO_BIG = "HN:Epochs/decision-window-bigger-than-duration";
}

library TrackerErrors {
    /// @notice Thrown when trying to get info about effective deposits in future epochs.
    /// @return HN:Tracker/future-is-unknown
    string public constant FUTURE_IS_UNKNOWN = "HN:Tracker/future-is-unknown";

    /// @notice Thrown when trying to get info about effective deposits in epoch 0.
    /// @return HN:Tracker/epochs-start-from-1
    string public constant EPOCHS_START_FROM_1 =
        "HN:Tracker/epochs-start-from-1";
}

library PayoutsErrors {
    /// @notice Thrown when trying to register more funds than possess.
    /// @return HN:Payouts/registering-withdrawal-of-unearned-funds
    string public constant REGISTERING_UNEARNED_FUNDS =
        "HN:Payouts/registering-withdrawal-of-unearned-funds";
}

library ProposalsErrors {
    /// @notice Thrown when trying to change proposals that could already have been voted upon.
    /// @return HN:Proposals/only-future-proposals-changing-is-allowed
    string public constant CHANGING_PROPOSALS_IN_THE_PAST =
        "HN:Proposals/only-future-proposals-changing-is-allowed";
}

library CommonErrors {
    /// @notice Thrown when trying to call as an unauthorized account.
    /// @return HN:Common/unauthorized-caller
    string public constant UNAUTHORIZED_CALLER =
        "HN:Common/unauthorized-caller";
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IOctantOracle {
    function getTotalETHStakingProceeds(
        uint32 epoch
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IWithdrawalsTarget {
    function withdrawToVault(uint256) external;
    function withdrawToMultisig(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "../interfaces/IOctantOracle.sol";
import "../Epochs.sol";
import {OracleErrors} from "../Errors.sol";
import "../interfaces/IWithdrawalsTarget.sol";

/// @title Protocol ETH income sampler
///
/// @notice This contract samples WithdrawalsTarget balance once in an epoch,
/// tracking Octant ETH income. WithdrawalsTarget profits include both funds
/// SKIMMED from validator balances on beacon chain (attestations etc)
/// and tx inclusion fees on execution layer (tips for block proposer and eventual MEVs).
contract OctantOracle is IOctantOracle {
    IWithdrawalsTarget public target;
    IEpochs public immutable epochs;
    mapping(uint256 => uint256) public balanceByEpoch;

    constructor(
        address _epochsAddress
    ) {
        epochs = Epochs(_epochsAddress);
    }

    /// @notice Checks how much yield (ETH staking proceeds) is generated by Golem Foundation at particular epoch.
    /// @param epoch - Octant Epoch's number.
    /// @return Total ETH staking proceeds made by foundation in wei for particular epoch.
    function getTotalETHStakingProceeds(
        uint32 epoch
    ) public view returns (uint256) {
        return balanceByEpoch[epoch];
    }

    function setTarget(address _target) public {
        require(address(target) == address(0x0));
        target = IWithdrawalsTarget(_target);
    }

    function writeBalance() external {
        uint32 epoch = epochs.getCurrentEpoch();
        require(epoch > 1, OracleErrors.BALANCE_CANT_BE_KNOWN);
        require(balanceByEpoch[epoch - 1] == 0, OracleErrors.BALANCE_ALREADY_SET);
        require(address(target) != address(0x0), OracleErrors.NO_TARGET);
        balanceByEpoch[epoch - 1] = address(target).balance;
        target.withdrawToVault(address(target).balance);
    }
}