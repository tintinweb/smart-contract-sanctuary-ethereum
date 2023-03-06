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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEpochs.sol";

import {EpochsErrors} from "./Errors.sol";

/// @title Epochs
/// @notice Contract which handles Octant epochs mechanism.
/// Epoch duration and time when decision window is open is calculated in seconds.
/// These values are set when deploying a contract but can later be changed with {setEpochDuration} and
/// {setDecisionWindow} by contract's owner.
contract Epochs is Ownable, IEpochs {

    /// @dev Struct to store the properties of an epoch.
    /// @param from The epoch number from which properties are valid (inclusive).
    /// @param to The epoch number to which properties are valid (exclusive).
    /// @param duration Epoch duration in seconds.
    /// @param decisionWindow Decision window in seconds.
    /// This value represents time, when participant can allocate funds to projects.
    /// It must be smaller or equal to {epochDuration}.
    struct EpochProps {
        uint256 from;
        uint256 to;
        uint256 duration;
        uint256 decisionWindow;
    }

    /// @notice Timestamp when octant starts.
    uint256 public start;

    /// @dev Index of current epoch properties in epochProps mapping.
    uint256 public epochPropsIndex;

    /// @dev Mapping to store the properties of all epochs.
    mapping(uint256 => EpochProps) public epochProps;

    /// @dev Constructor to initialize start and the first epoch properties.
    /// @param _start Timestamp when octant starts.
    /// @param _epochDuration Duration of an epoch in seconds.
    /// @param _decisionWindow Decision window in seconds for the first epoch.
    constructor(
        uint256 _start,
        uint256 _epochDuration,
        uint256 _decisionWindow
    ) {
        start = _start;
        epochProps[0] = EpochProps({from : 1, to : 0, duration : _epochDuration, decisionWindow : _decisionWindow});
    }

    /// @notice Get the current epoch number.
    /// @dev Will revert when calling before the first epoch started.
    /// @return The current epoch number, number in range [1, inf)
    function getCurrentEpoch() public view returns (uint32) {
        require(isStarted(), EpochsErrors.NOT_STARTED);
        uint256 _start = start;
        uint256 _epochsOffset = 1;
        uint256 _epochDuration = epochProps[epochPropsIndex].duration;
        for (uint256 i = 0; i <= epochPropsIndex; i = i + 1) {
            if (epochProps[i].to != 0) {
                uint256 _epochPropsValidityTime = epochProps[i].to - epochProps[i].from;
                uint256 _summedDurationFromProps = _epochPropsValidityTime * epochProps[i].duration;

                if (block.timestamp <= _start + _summedDurationFromProps) {
                    return uint32(((block.timestamp - _start) / _epochDuration) + _epochsOffset);
                } else {
                    _epochsOffset = _epochsOffset + _epochPropsValidityTime;
                    _start = _start + _epochPropsValidityTime * epochProps[i].duration;
                }
            }
        }
        return uint32(((block.timestamp - _start) / _epochDuration) + _epochsOffset);
    }

    /// @dev Returns the duration of current epoch.
    /// @return The duration of current epoch in seconds.
    function getEpochDuration() external view returns (uint256) {
        uint32 _currentEpoch = getCurrentEpoch();
        for (uint256 i = 0; i <= epochPropsIndex; i = i + 1) {
            if (_arePropsValidForEpoch(epochProps[i], _currentEpoch)) {
                return epochProps[i].duration;
            }
        }
        return 0;
    }

    /// @dev Returns the duration of the decision window in current epoch.
    /// @return The the duration of the decision window in current epoch in seconds.
    function getDecisionWindow() external view returns (uint256) {
        uint32 _currentEpoch = getCurrentEpoch();
        for (uint256 i = 0; i <= epochPropsIndex; i = i + 1) {
            if (_arePropsValidForEpoch(epochProps[i], _currentEpoch)) {
                return epochProps[i].decisionWindow;
            }
        }
        return 0;
    }

    /// @return bool Whether the decision window is currently open or not.
    function isDecisionWindowOpen() public view returns (bool) {
        require(isStarted(), EpochsErrors.NOT_STARTED);
        EpochProps memory _currentEpochProps = epochProps[epochPropsIndex];
        uint256 moduloEpoch = uint256(
            (block.timestamp - start) % _currentEpochProps.duration
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
    function setEpochProps(uint256 _epochDuration, uint256 _decisionWindow) external onlyOwner {
        require(_epochDuration >= _decisionWindow, EpochsErrors.DECISION_WINDOW_TOO_BIG);
        uint32 _currentEpoch = getCurrentEpoch();
        epochProps[epochPropsIndex].to = _currentEpoch + 1;
        epochProps[epochPropsIndex + 1] = EpochProps({from : _currentEpoch + 1, to : 0, duration : _epochDuration, decisionWindow : _decisionWindow});
        epochPropsIndex = epochPropsIndex + 1;
    }

    /// @dev Checks if the provided epoch properties are valid for the given epoch.
    /// @param props The epoch properties to validate.
    /// @param _epoch The epoch to validate the properties for.
    /// @return True if the properties are valid for the epoch, false otherwise.
    function _arePropsValidForEpoch(EpochProps memory props, uint32 _epoch) private pure returns (bool) {
        return _epoch >= props.from && (props.to == 0 || _epoch < props.to);
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

library AllocationStorageErrors {
    /// @notice Thrown when trying to allocate without removing it first. Should never occur as this
    /// is called from Allocations contract
    /// @return HN:AllocationsStorage/allocation-already-exists
    string public constant ALLOCATION_ALREADY_EXISTS =
        "HN:AllocationsStorage/allocation-already-exists";

    /// @notice Thrown when trying to allocate which does not exist. Should never occur as this
    /// is called from Allocations contract.
    /// @return HN:AllocationsStorage/allocation-does-not-exist
    string public constant ALLOCATION_DOES_NOT_EXIST =
        "HN:AllocationsStorage/allocation-does-not-exist";
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

import "../interfaces/IOctantOracle.sol";
import "../withdrawals/WithdrawalsTargetV3.sol";
import "../Epochs.sol";
import {OracleErrors} from "../Errors.sol";

/// @title Protocol ETH income sampler
///
/// @notice This contract samples WithdrawalsTarget balance once in an epoch,
/// tracking Octant ETH income. WithdrawalsTarget profits include both funds
/// SKIMMED from validator balances on beacon chain (attestations etc)
/// and tx inclusion fees on execution layer (tips for block proposer and eventual MEVs).
contract OctantOracle is IOctantOracle {
    WithdrawalsTargetV3 public target;
    address public payoutsManager;
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
        target = WithdrawalsTargetV3(_target);
    }

    function setPayoutsManager(address _manager) public {
        require(address(payoutsManager) == address(0x0));
        payoutsManager = _manager;
    }

    function writeBalance() external {
        uint32 epoch = epochs.getCurrentEpoch();
        require(epoch > 1, OracleErrors.BALANCE_CANT_BE_KNOWN);
        require(balanceByEpoch[epoch-1] == 0, OracleErrors.BALANCE_ALREADY_SET);
        require(address(target) != address(0x0), OracleErrors.NO_TARGET);
        require(address(payoutsManager) != address(0x0), OracleErrors.NO_PAYOUTS_MANAGER);
        balanceByEpoch[epoch-1] = address(target).balance;
        target.withdrawRewards(payable(payoutsManager));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

/// @title Contract that receives both ETH staking rewards and unstaked ETH
/// @author Golem Foundation
/// @notice
/// @dev This one is written to be upgradeable (hardhat-deploy variant).
/// Despite that, it can be deployed as-is without a proxy.
contract WithdrawalsTargetV3 {
    // This contract uses Proxy pattern.
    // Please read more here about limitations:
    //   https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    // Note that this contract uses hardhat's upgradeable, not OpenZeppelin's!

    /// @notice Octant address will receive rewards ETH
    address public octant;

    /// @notice Golem Foundation multisig address
    address public multisig;

    event OctantSet(address oldValue, address newValue);
    event MultisigSet(address oldValue, address newValue);
    event GotEth(uint amount, address sender);

    constructor () {
    }

    function setOctant(address newOctant) public onlyMultisig {
        emit OctantSet(octant, newOctant);
        octant = newOctant;
    }

    function setMultisig(address newMultisig) public {
        require((multisig == address(0x0)) || (msg.sender == multisig),
                "HN:WithdrawalsTarget/unauthorized-caller");
        emit MultisigSet(multisig, newMultisig);
        multisig = newMultisig;
    }

    function withdrawRewards(address payable rewardsVault) public onlyOctant {
        rewardsVault.transfer(address(this).balance);
    }

    function withdrawUnstaked(uint256 amount) public onlyMultisig {
        payable(multisig).transfer(amount);
    }

    /// @dev This will be removed before mainnet launch.
    /// Was added as a work-around for EIP173Proxy reverting bare ETH transfers.
    function sendETH() public payable {
        emit GotEth(msg.value, msg.sender);
    }

    modifier onlyOctant() {
        require(msg.sender == octant, "HN:WithdrawalsTarget/unauthorized-caller");
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig, "HN:WithdrawalsTarget/unauthorized-caller");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}