// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender)
        external
        view
        returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20BaseInternal } from './IERC20BaseInternal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20Base is IERC20BaseInternal, IERC20 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from '../../../interfaces/IERC20Internal.sol';

/**
 * @title ERC20 base interface
 */
interface IERC20BaseInternal is IERC20Internal {
    error ERC20Base__ApproveFromZeroAddress();
    error ERC20Base__ApproveToZeroAddress();
    error ERC20Base__BurnExceedsBalance();
    error ERC20Base__BurnFromZeroAddress();
    error ERC20Base__InsufficientAllowance();
    error ERC20Base__MintToZeroAddress();
    error ERC20Base__TransferExceedsBalance();
    error ERC20Base__TransferFromZeroAddress();
    error ERC20Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20ExtendedInternal } from './IERC20ExtendedInternal.sol';

/**
 * @title ERC20 extended interface
 */
interface IERC20Extended is IERC20ExtendedInternal {
    /**
     * @notice increase spend amount granted to spender
     * @param spender address whose allowance to increase
     * @param amount quantity by which to increase allowance
     * @return success status (always true; otherwise function will revert)
     */
    function increaseAllowance(address spender, uint256 amount)
        external
        returns (bool);

    /**
     * @notice decrease spend amount granted to spender
     * @param spender address whose allowance to decrease
     * @param amount quantity by which to decrease allowance
     * @return success status (always true; otherwise function will revert)
     */
    function decreaseAllowance(address spender, uint256 amount)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20BaseInternal } from '../base/IERC20BaseInternal.sol';

/**
 * @title ERC20 extended internal interface
 */
interface IERC20ExtendedInternal is IERC20BaseInternal {
    error ERC20Extended__ExcessiveAllowance();
    error ERC20Extended__InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Base } from './base/IERC20Base.sol';
import { IERC20Extended } from './extended/IERC20Extended.sol';
import { IERC20Metadata } from './metadata/IERC20Metadata.sol';
import { IERC20Permit } from './permit/IERC20Permit.sol';

interface ISolidStateERC20 is
    IERC20Base,
    IERC20Extended,
    IERC20Metadata,
    IERC20Permit
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20MetadataInternal } from './IERC20MetadataInternal.sol';

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata is IERC20MetadataInternal {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC20 metadata internal interface
 */
interface IERC20MetadataInternal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Metadata } from '../metadata/IERC20Metadata.sol';
import { IERC2612 } from './IERC2612.sol';
import { IERC20PermitInternal } from './IERC20PermitInternal.sol';

// TODO: note that IERC20Metadata is needed for eth-permit library

interface IERC20Permit is IERC20PermitInternal, IERC2612 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

interface IERC20PermitInternal is IERC2612Internal {
    error ERC20Permit__ExpiredDeadline();
    error ERC20Permit__InvalidSignature();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC2612Internal } from './IERC2612Internal.sol';

/**
 * @title ERC2612 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 is IERC2612Internal {
    /**
     * @notice return the EIP-712 domain separator unique to contract and chain
     * @return domainSeparator domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator);

    /**
     * @notice get the current ERC2612 nonce for the given address
     * @return current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice approve spender to transfer tokens held by owner via signature
     * @dev this function may be vulnerable to approval replay attacks
     * @param owner holder of tokens and signer of permit
     * @param spender beneficiary of approval
     * @param amount quantity of tokens to approve
     * @param v secp256k1 'v' value
     * @param r secp256k1 'r' value
     * @param s secp256k1 's' value
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC2612Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IOFTCore} from "./IOFTCore.sol";
import {ISolidStateERC20} from "@solidstate/contracts/token/ERC20/ISolidStateERC20.sol";

/**
 * @dev Interface of the OFT standard
 */
interface IOFT is IOFTCore, ISolidStateERC20 {
    error OFT_InsufficientAllowance();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface IOFTCore is IERC165 {
    /**
     * @dev estimate send token `tokenId` to (`dstChainId`, `toAddress`)
     * dstChainId - L0 defined chain id to send tokens too
     * toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * amount - amount of the tokens to transfer
     * useZro - indicates to use zro to pay L0 fees
     * adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        bool useZro,
        bytes calldata adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    /**
     * @dev send `amount` amount of token to (`dstChainId`, `toAddress`) from `from`
     * `from` the owner of token
     * `dstChainId` the destination chain identifier
     * `toAddress` can be any size depending on the `dstChainId`.
     * `amount` the quantity of tokens in wei
     * `refundAddress` the address LayerZero refunds if too much message fee is sent
     * `zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 amount,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable;

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint256);

    /**
     * @dev Emitted when `amount` tokens are moved from the `sender` to (`dstChainId`, `toAddress`)
     * `nonce` is the outbound nonce
     */
    event SendToChain(
        address indexed sender,
        uint16 indexed dstChainId,
        bytes indexed toAddress,
        uint256 amount
    );

    /**
     * @dev Emitted when `amount` tokens are received from `srcChainId` into the `toAddress` on the local chain.
     * `nonce` is the inbound nonce.
     */
    event ReceiveFromChain(
        uint16 indexed srcChainId,
        bytes indexed srcAddress,
        address indexed toAddress,
        uint256 amount
    );

    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

import {IPremiaStaking} from "./staking/IPremiaStaking.sol";

contract PremiaVoteProxy {
    address internal immutable VX_PREMIA;

    constructor(address vxPremia) {
        VX_PREMIA = vxPremia;
    }

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "PREMIAVOTE";
    }

    function symbol() external pure returns (string memory) {
        return "PREMIAVOTE";
    }

    function totalSupply() external view returns (uint256) {
        return IPremiaStaking(VX_PREMIA).getTotalPower();
    }

    function balanceOf(address voter) external view returns (uint256) {
        return IPremiaStaking(VX_PREMIA).getUserPower(voter);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {PremiaStakingStorage} from "./PremiaStakingStorage.sol";
import {IOFT} from "../layerZero/token/oft/IOFT.sol";

import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

// IERC20Metadata inheritance not possible due to linearization issue
interface IPremiaStaking is IERC2612, IOFT {
    error PremiaStaking__CantTransfer();
    error PremiaStaking__ExcessiveStakePeriod();
    error PremiaStaking__NoPendingWithdrawal();
    error PremiaStaking__NotEnoughLiquidity();
    error PremiaStaking__StakeLocked();
    error PremiaStaking__StakeNotLocked();
    error PremiaStaking__WithdrawalStillPending();
    error PremiaStaking__InsufficientSwapOutput();

    event Stake(
        address indexed user,
        uint256 amount,
        uint64 stakePeriod,
        uint64 lockedUntil
    );

    event Unstake(
        address indexed user,
        uint256 amount,
        uint256 fee,
        uint256 startDate
    );

    event Harvest(address indexed user, uint256 amount);

    event EarlyUnstakeRewardCollected(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event RewardsAdded(uint256 amount);

    struct StakeLevel {
        uint256 amount; // Amount to stake
        uint256 discountBPS; // Discount when amount is reached
    }

    struct SwapArgs {
        //min amount out to be used to purchase
        uint256 amountOutMin;
        // exchange address to call to execute the trade
        address callee;
        // address for which to set allowance for the trade
        address allowanceTarget;
        // data to execute the trade
        bytes data;
        // address to which refund excess tokens
        address refundAddress;
    }

    event BridgeLock(
        address indexed user,
        uint64 stakePeriod,
        uint64 lockedUntil
    );

    /**
     * @notice Returns the reward token address
     * @return The reward token address
     */
    function getRewardToken() external view returns (address);

    /**
     * @notice add premia tokens as available tokens to be distributed as rewards
     * @param amount amount of premia tokens to add as rewards
     */
    function addRewards(uint256 amount) external;

    /**
     * @notice get amount of tokens that have not yet been distributed as rewards
     * @return rewards amount of tokens not yet distributed as rewards
     * @return unstakeRewards amount of PREMIA not yet claimed from early unstake fees
     */
    function getAvailableRewards()
        external
        view
        returns (uint256 rewards, uint256 unstakeRewards);

    /**
     * @notice get pending amount of tokens to be distributed as rewards to stakers
     * @return amount of tokens pending to be distributed as rewards
     */
    function getPendingRewards() external view returns (uint256);

    /**
     * @notice get pending withdrawal data of a user
     * @return amount pending withdrawal amount
     * @return startDate start timestamp of withdrawal
     * @return unlockDate timestamp at which withdrawal becomes available
     */
    function getPendingWithdrawal(address user)
        external
        view
        returns (
            uint256 amount,
            uint256 startDate,
            uint256 unlockDate
        );

    /**
     * @notice get the amount of PREMIA available for withdrawal
     * @return amount of PREMIA available for withdrawal
     */
    function getAvailablePremiaAmount() external view returns (uint256);

    /**
     * @notice Stake using IERC2612 permit
     * @param amount The amount of xPremia to stake
     * @param period The lockup period (in seconds)
     * @param deadline Deadline after which permit will fail
     * @param v V
     * @param r R
     * @param s S
     */
    function stakeWithPermit(
        uint256 amount,
        uint64 period,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Lockup xPremia for protocol fee discounts
     *          Longer period of locking will apply a multiplier on the amount staked, in the fee discount calculation
     * @param amount The amount of xPremia to stake
     * @param period The lockup period (in seconds)
     */
    function stake(uint256 amount, uint64 period) external;

    /**
     * @notice harvest rewards, convert to PREMIA using exchange helper, and stake
     * @param s swap arguments
     * @param stakePeriod The lockup period (in seconds)
     */
    function harvestAndStake(
        IPremiaStaking.SwapArgs memory s,
        uint64 stakePeriod
    ) external;

    /**
     * @notice Harvest rewards directly to user wallet
     */
    function harvest() external;

    /**
     * @notice Get pending rewards amount, including pending pool update
     * @param user User for which to calculate pending rewards
     * @return reward amount of pending rewards from protocol fees (in REWARD_TOKEN)
     * @return unstakeReward amount of pending rewards from early unstake fees (in PREMIA)
     */
    function getPendingUserRewards(address user)
        external
        view
        returns (uint256 reward, uint256 unstakeReward);

    /**
     * @notice unstake tokens before end of the lock period, for a fee
     * @param amount the amount of vxPremia to unstake
     */
    function earlyUnstake(uint256 amount) external;

    /**
     * @notice get early unstake fee for given user
     * @param user address of the user
     * @return feePercentage % fee to pay for early unstake (1e4 = 100%)
     */
    function getEarlyUnstakeFeeBPS(address user)
        external
        view
        returns (uint256 feePercentage);

    /**
     * @notice Initiate the withdrawal process by burning xPremia, starting the delay period
     * @param amount quantity of xPremia to unstake
     */
    function startWithdraw(uint256 amount) external;

    /**
     * @notice Withdraw underlying premia
     */
    function withdraw() external;

    //////////
    // View //
    //////////

    /**
     * Calculate the stake amount of a user, after applying the bonus from the lockup period chosen
     * @param user The user from which to query the stake amount
     * @return The user stake amount after applying the bonus
     */
    function getUserPower(address user) external view returns (uint256);

    /**
     * Return the total power across all users (applying the bonus from lockup period chosen)
     * @return The total power across all users
     */
    function getTotalPower() external view returns (uint256);

    /**
     * @notice Calculate the % of fee discount for user, based on his stake
     * @param user The _user for which the discount is for
     * @return Percentage of protocol fee discount (in basis point)
     *         Ex : 1000 = 10% fee discount
     */
    function getDiscountBPS(address user) external view returns (uint256);

    /**
     * @notice Get stake levels
     * @return Stake levels
     *         Ex : 2500 = -25%
     */
    function getStakeLevels() external returns (StakeLevel[] memory);

    /**
     * @notice Get stake period multiplier
     * @param period The duration (in seconds) for which tokens are locked
     * @return The multiplier for this staking period
     *         Ex : 20000 = x2
     */
    function getStakePeriodMultiplierBPS(uint256 period)
        external
        returns (uint256);

    /**
     * @notice Get staking infos of a user
     * @param user The user address for which to get staking infos
     * @return The staking infos of the user
     */
    function getUserInfo(address user)
        external
        view
        returns (PremiaStakingStorage.UserInfo memory);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library PremiaStakingStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.staking.PremiaStaking");

    struct Withdrawal {
        uint256 amount; // Premia amount
        uint256 startDate; // Will unlock at startDate + withdrawalDelay
    }

    struct UserInfo {
        uint256 reward; // Amount of rewards accrued which havent been claimed yet
        uint256 rewardDebt; // Debt to subtract from reward calculation
        uint256 unstakeRewardDebt; // Debt to subtract from reward calculation from early unstake fee
        uint64 stakePeriod; // Stake period selected by user
        uint64 lockedUntil; // Timestamp at which the lock ends
    }

    struct Layout {
        uint256 pendingWithdrawal;
        uint256 _deprecated_withdrawalDelay;
        mapping(address => Withdrawal) withdrawals;
        uint256 availableRewards;
        uint256 lastRewardUpdate; // Timestamp of last reward distribution update
        uint256 totalPower; // Total power of all staked tokens (underlying amount with multiplier applied)
        mapping(address => UserInfo) userInfo;
        uint256 accRewardPerShare;
        uint256 accUnstakeRewardPerShare;
        uint256 availableUnstakeRewards;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}