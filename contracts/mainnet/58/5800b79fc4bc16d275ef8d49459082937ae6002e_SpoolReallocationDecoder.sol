// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

/**
 * @notice Strict holding information how to swap the asset
 * @member slippage minumum output amount
 * @member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./../ISwapData.sol";

/// @notice Strategy total underlying slippage, to verify validity of the strategy state
struct StratUnderlyingSlippage {
    uint256 min;
    uint256 max;
}

/// @notice Containig information if and how to swap strategy rewards at the DHW
/// @dev Passed in by the do-hard-worker
struct RewardSlippages {
    bool doClaim;
    SwapData[] swapData;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the withdraw part of the reallocation DHW
struct ReallocationWithdrawData {
    uint256[][] reallocationTable;
    StratUnderlyingSlippage[] priceSlippages;
    RewardSlippages[] rewardSlippages;
    uint256[] stratIndexes;
    uint256[][] slippages;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the deposit part of the reallocation DHW
struct ReallocationData {
    uint256[] stratIndexes;
    uint256[][] slippages;
}

interface ISpoolHelper {
    /* ========== FUNCTIONS ========== */
    function batchDoHardWorkReallocation(
        ReallocationWithdrawData memory withdrawData,
        ReallocationData memory depositData,
        address[] memory allStrategies,
        bool isOneTransaction
    ) external;

    function isDoHardWorker(address account) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// extends
import "../interfaces/spool/ISpoolHelper.sol";

/**
 * @notice Spool part of implementation dealing with the do hard work
 *
 * @dev
 * Do hard work is the process of interacting with other protocols.
 * This process aggregates many actions together to act in as optimized
 * manner as possible. It optimizes for underlying assets and gas cost.
 *
 * Do hard work (DHW) is executed periodically. As users are depositing
 * and withdrawing, these actions are stored in the buffer system.
 * When executed the deposits and withdrawals are matched against
 * eachother to minimize slippage and protocol fees. This means that
 * for a normal DHW only deposit or withdrawal is executed and never
 * both in the same index. Both can only be if the DHW is processing
 * the reallocation as well.
 *
 * Each strategy DHW is executed once per index and then incremented.
 * When all strategies are incremented to the same index, the batch
 * is considered complete. As soon as a new batch starts (first strategy
 * in the new batch is processed) global index is incremented.
 *
 * Global index is always one more or equal to the strategy index.
 * This constraints the system so that all strategy DHWs have to be
 * executed to complete the batch.
 *
 * Do hard work can only be executed by the whitelisted addresses.
 * The whitelisting can be done only by the Spool DAO.
 *
 * Do hard work actions:
 * - deposit
 * - withdrawal
 * - compound rewards
 * - reallocate assets across protocols
 *
 */
contract SpoolReallocationDecoder {
    ISpoolHelper public immutable spool;

    constructor(ISpoolHelper _spool) {
        spool = _spool;
    }

    /**
     * @notice Executes do hard work of specified strategies if reallocation is in progress.
     * 
     * @dev
     * withdrawData.reallocationTable contains a compressed version of the reallocation table
     * where each element contains two values, one in first 128 bits and the second one in
     * last 128 bits of the uint256.
     *
     * Requirements:
     *
     * - caller must be a valid do hard worker
     * - provided strategies must be valid
     * - reallocation is pending for current index
     * - at least one strategy must be processed
     * - the system should not be paused
     *
     * @param withdrawData Reallocation values addressing withdrawal part of the reallocation DHW
     * @param depositData Reallocation values addressing deposit part of the reallocation DHW
     * @param allStrategies Array of all strategy addresses in the system for current set reallocation
     * @param isOneTransaction Flag denoting if the DHW should execute in one transaction
     */
    function batchDoHardWorkReallocation(
        ReallocationWithdrawData memory withdrawData,
        ReallocationData calldata depositData,
        address[] calldata allStrategies,
        bool isOneTransaction
    ) external onlyDoHardWorker {
        uint256[][] memory reallocationTable = new uint256[][](allStrategies.length);
        for (uint256 i; i < allStrategies.length; i++) {
            reallocationTable[i] = new uint256[](allStrategies.length);

            for (uint256 j; j < allStrategies.length; j++) {
                uint256 idx = j / 2;
                if (withdrawData.reallocationTable[i][idx] == 0) {
                    j++;
                    continue;
                }

                if (j % 2 == 0) {
                    reallocationTable[i][j] = withdrawData.reallocationTable[i][idx] >> 128;
                } else {
                    reallocationTable[i][j] = withdrawData.reallocationTable[i][idx] << 128 >> 128;
                }
            }
        }

        withdrawData.reallocationTable = reallocationTable;

        spool.batchDoHardWorkReallocation(
            withdrawData,
            depositData,
            allStrategies,
            isOneTransaction
        );
    }

    function _onlyDoHardWorker() private view {
        require(
            spool.isDoHardWorker(msg.sender),
            "ODHW"
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Throws if called by anyone else other than the controller
     */
    modifier onlyDoHardWorker() {
        _onlyDoHardWorker();
        _;
    }
}