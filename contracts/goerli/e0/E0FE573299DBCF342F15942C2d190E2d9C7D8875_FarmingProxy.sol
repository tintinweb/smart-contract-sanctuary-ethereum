// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IManager } from '../manager/IManager.sol';
import { IFarmingProxy } from './IFarmingProxy.sol';
import { IERC20 } from '../interfaces/IERC20.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract FarmingProxy is NonReentrant, IFarmingProxy {
    address public managerProxyAddress;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        require(tx.origin == msg.sender, 'FarmingProxy: FORBIDDEN, not a direct call');
        _;
    }

    modifier requireManager() {
        require(msg.sender == manager(), 'FarmingProxy: FORBIDDEN, not Manager');
        _;
    }

    event Staked(
        address indexed user,
        uint256 amount,
        uint256 newestLockingParcelIndex,
        uint256 lockTime
    );
    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 oldestLockingParcelIndex,
        uint256 leftoverAmountLockingParcel
    );
    event RewardPaid(address indexed user, uint256 reward);
    event LockingPeriodUpdate(uint256 lockingPeriodInSeconds);
    event AllocPointsUpdate(uint256 allocPoints);
    event MaxPoolRewardPerTokenPerSecondUpdated(uint256 maxPoolRewardPerTokenPerSecond);

    constructor(address _managerProxyAddress) public {
        managerProxyAddress = _managerProxyAddress;
    }

    function manager() private view returns (address _manager) {
        _manager = address(
            IGovernedProxy_New(address(uint160(managerProxyAddress))).implementation()
        );
    }

    function safeTransferTokenFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external noReentry requireManager {
        IERC20(_token).transferFrom(_from, _to, _amount);
    }

    function safeTransferToken(
        address _token,
        address _to,
        uint256 _amount
    ) external noReentry requireManager {
        IERC20(_token).transfer(_to, _amount);
    }

    function emitMaxPoolRewardPerTokenPerSecondUpdated(uint256 maxPoolRewardPerTokenPerSecond)
        external
        requireManager
    {
        emit MaxPoolRewardPerTokenPerSecondUpdated(maxPoolRewardPerTokenPerSecond);
    }

    function emitStaked(
        address user,
        uint256 amount,
        uint256 newestLockingParcelIndex,
        uint256 lockTime
    ) external requireManager {
        emit Staked(user, amount, newestLockingParcelIndex, lockTime);
    }

    function emitWithdrawn(
        address user,
        uint256 amount,
        uint256 oldestLockingParcelIndex,
        uint256 leftoverAmountLockingParcel
    ) external requireManager {
        emit Withdrawn(user, amount, oldestLockingParcelIndex, leftoverAmountLockingParcel);
    }

    function emitRewardPaid(address user, uint256 reward) external requireManager {
        emit RewardPaid(user, reward);
    }

    function emitLockingPeriodUpdate(uint256 lockingPeriodInSeconds) external requireManager {
        emit LockingPeriodUpdate(lockingPeriodInSeconds);
    }

    function emitAllocPointsUpdate(uint256 allocPoints) external requireManager {
        emit AllocPointsUpdate(allocPoints);
    }

    function proxy() external view returns (address) {
        return address(this);
    }

    // Proxy all other calls to Manager.
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        IManager _manager = IManager(manager());

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let res := call(sub(gas(), 10000), _manager, callvalue(), ptr, calldatasize(), 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())

            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IManager {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function availableToWithdraw(
        address farmingProxy,
        uint256 amount,
        address account,
        bool checkIfUnlocked,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 availableAmount, uint256 index);

    function registerPool(address _farmingProxy, address _farmingStorage) external;

    function accruedRewardPerToken(address farmingProxy) external view returns (uint256);

    function owedRewards(address farmingProxy, address account) external view returns (uint256);

    function returnLPTokensInBatches(
        address farmingProxy,
        address[] calldata stakerAccounts,
        uint256[] calldata LPTokenAmounts,
        bool checkIfUnlocked,
        uint256 limit
    ) external;

    function rewardPerTokenPerSecondApplicable(address farmingProxy)
        external
        view
        returns (uint256);

    function getBalance(address farmingProxy, address account) external view returns (uint256);

    function getLPTokenAddress() external view returns (address);

    function getTotalRewardRate() external view returns (uint256);

    function getRewardPerTokenPaid(address farmingProxy, address staker)
        external
        view
        returns (uint256);

    function getOwedRewards(address farmingProxy, address staker) external view returns (uint256);

    function getReward() external;

    function getReward(address farmingProxy) external;

    function stake(uint256 amount) external;

    function stake(address farmingProxy, uint256 amount) external;

    function withdraw(uint256 amount, uint256 limit) external;

    function withdraw(
        address farmingProxy,
        uint256 amount,
        uint256 limit
    ) external;

    function exit(uint256 limit) external;

    function exit(address farmingProxy, uint256 limit) external;

    function updatePayout(uint256 reward, uint256 rewardsDuration) external;

    function getStakedTokenAmount(address farmingProxy) external view returns (uint256);

    function getToken0(address farmingProxy) external view returns (address);

    function getToken1(address farmingProxy) external view returns (address);

    function getAccruedRewardsPerToken(address farmingProxy) external view returns (uint256);

    function getLastUpdateTime() external view returns (uint256);

    function getMaxPoolRewardPerTokenPerSecond(address farmingProxy)
        external
        view
        returns (uint256);

    function getTotalAllocPoints() external view returns (uint256);

    function getTimePayoutEnds() external view returns (uint256);

    function getLockingPeriodInSeconds(address farmingProxy) external view returns (uint256);

    function getAllocPoints(address farmingProxy) external view returns (uint256);

    function getFarmingStorage(address farmingProxy) external view returns (address);

    function getFarmingProxyByIndex(uint256 index) external view returns (address);

    function getAllFarmingProxiesCount() external view returns (uint256);

    // Mutative

    function setMaxPoolRewardPerTokenPerSecondInBatches(
        address[] calldata farmingProxies,
        uint256[] calldata maxPoolRewardPerTokenPerSeconds
    ) external;

    function setOperatorAddress(address _newOperatorAddress) external;

    function setLPTokenAddress(address _newLPTokenAddress) external;

    function setGMIProxyAddress(address _GMIProxyAddress) external;

    function setTotalAllocPoints(uint256 _totalAllocPoints) external;

    function setLockingPeriodInSeconds(address farmingProxy, uint256 lockingPeriod) external;

    function setAllocPoints(address farmingProxy, uint256 allocPoints) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy_New {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external view returns (IGovernedContract);

    function implementation() external view returns (IGovernedContract);

    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IERC20 {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFarmingProxy {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 newestLockingParcelIndex,
        uint256 lockTime
    );
    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 oldestLockingParcelIndex,
        uint256 leftoverAmountLockingParcel
    );
    event RewardPaid(address indexed user, uint256 reward);
    event LockingPeriodUpdate(uint256 lockingPeriodInSeconds);
    event AllocPointsUpdate(uint256 allocPoints);
    event MaxPoolRewardPerTokenPerSecondUpdated(uint256 maxPoolRewardPerTokenPerSecond);

    function safeTransferTokenFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function safeTransferToken(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function emitMaxPoolRewardPerTokenPerSecondUpdated(uint256 maxPoolRewardPerTokenPerSecond)
        external;

    function emitStaked(
        address user,
        uint256 amount,
        uint256 newestLockingParcelIndex,
        uint256 lockTime
    ) external;

    function emitWithdrawn(
        address user,
        uint256 amount,
        uint256 oldestLockingParcelIndex,
        uint256 leftoverAmountLockingParcel
    ) external;

    function emitRewardPaid(address user, uint256 reward) external;

    function emitLockingPeriodUpdate(uint256 lockingPeriodInSeconds) external;

    function emitAllocPointsUpdate(uint256 allocPoints) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}