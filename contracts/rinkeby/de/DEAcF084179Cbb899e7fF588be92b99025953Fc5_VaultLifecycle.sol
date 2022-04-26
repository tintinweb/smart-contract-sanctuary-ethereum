// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

import "./Vault.sol";
import "./ShareMath.sol";
import "./WrappedAuction.sol";
import "../interfaces/IERC20Detailed.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IVToken.sol";
import "../interfaces/IPriceOracle.sol";

library VaultLifecycle {
    using SafeMathUpgradeable for uint256;

    struct CloseParams {
        address vTokenTemplate;
        address USDC;
        address currentVToken;
        uint256 delay;
        uint256 performanceFee;
    }

    /**
     * @notice Sets the next vtoken and closing the existing position
     * @param closeParams is the struct with details of vToken
     * @param vaultParams is the struct with vault general data
     * @return vTokenAddress is the address of the new vtoken
     * @return premium is the premium of the new vtoken
     * @return delta is the delta of the new vtoken
     */
    function commitAndClose(
        address feeRecipient,
        address priceOracle,
        CloseParams memory closeParams,
        Vault.VaultParams storage vaultParams,
        address auction,
        uint256 auctionID
    )
        external
        returns (
            address vTokenAddress,
            uint256 premium,
            uint256 delta
        )
    {
        uint256 preAssetPrice = vaultParams.assetPrice;
        uint256 assetPrice = IPriceOracle(priceOracle).latestAnswer(
            vaultParams.oracleIndex
        );
        delta = assetPrice > preAssetPrice
            ? assetPrice - preAssetPrice
            : preAssetPrice - assetPrice;

        uint256 premiumBeforeFee = _getPremium(auction, auctionID);
        uint256 performanceFeeInAsset = closeParams.performanceFee > 0
            ? premiumBeforeFee.mul(closeParams.performanceFee).div(
                100 * Vault.FEE_MULTIPLIER
            )
            : 0;
        premium = premiumBeforeFee - performanceFeeInAsset;
        IERC20Upgradeable(vaultParams.asset).transfer(
            feeRecipient,
            performanceFeeInAsset
        );

        vTokenAddress = cloneVToken(
            string(
                abi.encodePacked(
                    "Volmex ",
                    IERC20Detailed(address(this)).name()
                )
            ),
            string(
                abi.encodePacked("v", IERC20Detailed(address(this)).symbol())
            ),
            closeParams.vTokenTemplate,
            vaultParams,
            auctionID
        );

        return (vTokenAddress, premium, delta);
    }

    /**
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param asset is the address of the vault's asset
     * @param decimals is the decimals of the asset
     * @param lastQueuedWithdrawAmount is the amount queued for withdrawals from last round
     * @param performanceFee is the perf fee percent to charge on premiums
     * @param managementFee is the management fee percent to charge on the AUM
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 minVaultDeposit;
        uint256 managementFee;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from VolmexVault
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function rollover(
        Vault.VaultState storage vaultState,
        RolloverParams memory params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        uint256 pendingAmount = vaultState.totalPending;
        uint256 queuedWithdrawShares = vaultState.queuedWithdrawShares;

        uint256 balanceForVaultFees;
        {
            uint256 queuedWithdrawBeforeFee = params.currentShareSupply > 0
                ? ShareMath.sharesToAsset(
                    queuedWithdrawShares,
                    params.minVaultDeposit,
                    params.decimals
                )
                : 0;

            // Deduct the difference between the newly scheduled withdrawals
            // and the older withdrawals
            // so we can charge them fees before they leave
            uint256 withdrawAmountDiff = queuedWithdrawBeforeFee >
                params.lastQueuedWithdrawAmount
                ? queuedWithdrawBeforeFee.sub(params.lastQueuedWithdrawAmount)
                : 0;

            balanceForVaultFees = currentBalance
                .sub(queuedWithdrawBeforeFee)
                .add(withdrawAmountDiff);
        }

        {
            (, totalVaultFee) = VaultLifecycle.getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                pendingAmount,
                params.managementFee
            );
        }

        // Take into account the fee
        currentBalance = currentBalance.sub(totalVaultFee);

        {
            queuedWithdrawAmount = params.currentShareSupply > 0
                ? ShareMath.sharesToAsset(
                    queuedWithdrawShares,
                    params.minVaultDeposit,
                    params.decimals
                )
                : 0;
        }

        return (
            currentBalance.sub(queuedWithdrawAmount), // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            totalVaultFee
        );
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param managementFeePercent is the management fee pct.
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 managementFeePercent
    ) internal pure returns (uint256 managementFeeInAsset, uint256 vaultFee) {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending = currentBalance > pendingAmount
            ? currentBalance.sub(pendingAmount)
            : 0;

        // Take management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // vault expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {
            managementFeeInAsset = managementFeePercent > 0
                ? lockedBalanceSansPending.mul(managementFeePercent).div(
                    100 * Vault.FEE_MULTIPLIER
                )
                : 0;

            vaultFee = managementFeeInAsset;
        }
    }

    /**
     * @notice Starts the auction
     * @param auctionDetails is the struct with all the custom parameters of the auction
     * @return the auction id of the newly created auction
     */
    function startAuction(WrappedAuction.AuctionDetails memory auctionDetails)
        external
        returns (uint256)
    {
        return WrappedAuction.startAuction(auctionDetails);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param owner is the owner of the vault with critical permissions
     * @param feeRecipient is the address to recieve vault performance and management fees
     * @param performanceFee is the perfomance fee pct.
     * @param tokenName is the name of the token
     * @param tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address owner,
        address keeper,
        address feeRecipient,
        uint256 performanceFee,
        uint256 managementFee,
        string memory tokenName,
        string memory tokenSymbol,
        Vault.VaultParams memory _vaultParams
    ) public pure {
        require(owner != address(0), "VaultLifecycle: !owner");
        require(keeper != address(0), "VaultLifecycle: !keeper");
        require(feeRecipient != address(0), "VaultLifecycle: !feeRecipient");
        require(
            performanceFee < 100 * Vault.FEE_MULTIPLIER,
            "VaultLifecycle: performanceFee >= 100%"
        );
        require(
            managementFee < 100 * Vault.FEE_MULTIPLIER,
            "VaultLifecycle: managementFee >= 100%"
        );
        require(bytes(tokenName).length > 0, "VaultLifecycle: !tokenName");
        require(bytes(tokenSymbol).length > 0, "VaultLifecycle: !tokenSymbol");

        require(_vaultParams.asset != address(0), "VaultLifecycle: !asset");
        require(
            _vaultParams.underlying != address(0),
            "VaultLifecycle: !underlying"
        );
        require(
            _vaultParams.minimumSupply > 0,
            "VaultLifecycle: !minimumSupply"
        );
        require(_vaultParams.cap > 0, "VaultLifecycle: !cap");
        require(
            _vaultParams.cap > _vaultParams.minimumSupply,
            "VaultLifecycle: cap has to be higher than minimumSupply"
        );
    }

    /**
     * @notice Gets the next vToken expiry timestamp
     * @param timestamp is the expiry timestamp of the current vToken
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 timestamp) public pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }

    function getVTokenPrice(address easyAuction, uint256 auctionID)
        public
        view
        returns (uint256)
    {
        AuctionType.AuctionData memory auctionData = IAuction(
            easyAuction
        ).auctionData(auctionID);

        uint256 vTokenPrice;
        (, uint256 buyAmount, uint256 sellAmount) = _decodeOrder(
            auctionData.clearingPriceOrder
        );
        vTokenPrice = (sellAmount) / (buyAmount / 10**18);

        return vTokenPrice;
    }

    function cloneVToken(
        string memory name,
        string memory symbol,
        address template,
        Vault.VaultParams storage vaultParams,
        uint256 auctionID
    ) public returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, auctionID));
        IVToken newVToken = IVToken(
            ClonesUpgradeable.cloneDeterministic(template, salt)
        );
        newVToken.__VToken_init(
            name,
            symbol,
            vaultParams.asset,
            vaultParams.isShort
        );
        return address(newVToken);
    }

    function _getPremium(address _easyAuction, uint256 _auctionID)
        private
        view
        returns (uint256)
    {
        AuctionType.AuctionData memory auctionData = IAuction(
            _easyAuction
        ).auctionData(_auctionID);

        uint96 buyAmount;
        uint96 sellAmount;
        (, buyAmount, sellAmount) = _decodeOrder(
            auctionData.clearingPriceOrder
        );
        return uint256(sellAmount);
    }

    function _decodeOrder(bytes32 _orderData)
        private
        pure
        returns (
            uint64 userId,
            uint96 buyAmount,
            uint96 sellAmount
        )
    {
        // Note: converting to uint discards the binary digits that do not fit
        // the type.
        userId = uint64(uint256(_orderData) >> 192);
        buyAmount = uint96(uint256(_orderData) >> 96);
        sellAmount = uint96(uint256(_orderData));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    // vTokens have 8 decimal places.
    uint256 internal constant VTOKEN_DECIMALS = 18;

    // Percentage of funds allocated to vTokens is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant ALLOCATION_MULTIPLIER = 10**2;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // vTokens type the vault is selling
        bool isShort;
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in Vault
        address asset;
        // Underlying asset of the vTokens sold by vault
        address underlying;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint256 cap;
        // Price of asset at the time auction starts
        uint256 assetPrice;
        // Oracle index of the current asset
        uint8 oracleIndex;
    }

    struct VTokenState {
        // vTokens that the vault is shorting / longing in the next cycle
        address nextVToken;
        // vTokens that the vault is currently shorting / longing
        address currentVToken;
        // The timestamp when the `nextvTokens` can be used by the vault
        uint32 nextVTokenReadyAt;
        // The movement of the bid asset price
        uint256 delta;
        // price of vToken
        uint256 vTokenPrice;
        // realized price of vToken
        uint256 vTokenPnL;
        // minimum amount of vToken
        uint256 vTokenMinBidPremium;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling vTokens
        uint256 lockedAmount;
        // Amount that was locked for selling vTokens in the previous round
        // used for calculating performance fee deduction
        uint256 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint256 totalPending;
        // Amount locked for scheduled withdrawals;
        uint256 queuedWithdrawShares;
        // time after which next roll over happen
        uint256 nextRollOverTime;
        // boolean flag for auction status
        bool isAuctionStart;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint256 amount;
        // Unredeemed shares balance
        uint256 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint256 shares;
    }

    struct AuctionSellOrder {
        // Amount of `asset` token offered in auction
        uint96 sellAmount;
        // Amount of vToken requested in auction
        uint96 buyAmount;
        // User Id of delta vault in latest auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./Vault.sol";

library ShareMath {
    using SafeMathUpgradeable for uint256;

    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return assetAmount.mul(10**decimals).div(assetPerShare);
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return shares.mul(assetPerShare).div(10**decimals);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param assetPerShare is the price in asset per share
     * @param decimals is the number of decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound =
                assetToShares(depositReceipt.amount, assetPerShare, decimals);

            return
                uint256(depositReceipt.unredeemedShares).add(sharesFromRound);
        }
        return depositReceipt.unredeemedShares;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 pendingAmount,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return
            totalSupply > 0
                ? singleShare.mul(totalBalance.sub(pendingAmount)).div(
                    totalSupply
                )
                : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../vendor/DSMath.sol";
import "./Vault.sol";
import "../interfaces/IAuction.sol";
import "../interfaces/IVolmexRealizedVolVault.sol";

library WrappedAuction {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event InitiateWrappedAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    event PlaceAuctionBid(
        uint256 auctionId,
        address indexed auctioningToken,
        uint256 sellAmount,
        uint256 buyAmount,
        address indexed bidder
    );

    struct AuctionDetails {
        address vTokenAddress;
        address auction;
        address asset;
        uint256 assetDecimals;
        uint256 duration;
        uint256 minVtokenPremium;
    }

    struct BidDetails {
        address vTokenAddress;
        address auction;
        address asset;
        uint256 assetDecimals;
        uint256 auctionId;
        uint256 lockedBalance;
        uint256 vTokenAllocation;
        uint256 vTokenPremium;
        address bidder;
    }

    function startAuction(AuctionDetails memory auctionDetails)
        internal
        returns (uint256 auctionID)
    {
        uint256 vTokenSellAmount = getVTokenSellAmount(
            auctionDetails.vTokenAddress
        );

        IERC20Upgradeable(auctionDetails.vTokenAddress).safeApprove(
            auctionDetails.auction,
            vTokenSellAmount
        );

        // minBidAmount is total vTokens to sell * premium per vToken
        // shift decimals to correspond to decimals of USDC for puts
        // and underlying for calls
        uint256 minBidAmount = DSMath.wmul(
            vTokenSellAmount,
            auctionDetails.minVtokenPremium
        );

        minBidAmount = auctionDetails.assetDecimals > 18
            ? minBidAmount.mul(10**(auctionDetails.assetDecimals.sub(18)))
            : minBidAmount.div(
                10**(uint256(18).sub(auctionDetails.assetDecimals))
            );
        require(
            minBidAmount <= type(uint96).max,
            "WrappedAuction: vTokenSellAmount > type(uint96) max value!"
        );

        uint256 auctionEnd = block.timestamp.add(auctionDetails.duration);
        auctionID = IAuction(auctionDetails.auction).initiateAuction(
            // address of vToken we minted and are selling
            auctionDetails.vTokenAddress,
            // address of asset we want in exchange for vTokens. Should match vault `asset`
            auctionDetails.asset,
            // orders can be cancelled at any time during the auction
            auctionEnd,
            // order will last for `duration`
            auctionEnd,
            // we are selling all of the vtokens minus a fee taken by auction
            uint96(vTokenSellAmount),
            // the minimum we are willing to sell all the vTokens for.
            uint96(minBidAmount),
            // the minimum bidding amount must be 1 * 10 ** -assetDecimals
            1,
            // the min funding threshold
            0,
            // no atomic closure
            false,
            // access manager contract
            address(0),
            // bytes for storing info like a whitelist for who can bid
            bytes("")
        );

        emit InitiateWrappedAuction(
            auctionDetails.vTokenAddress,
            auctionDetails.asset,
            auctionID,
            msg.sender
        );
    }

    function claimAuctionVTokens(
        Vault.AuctionSellOrder memory auctionSellOrder,
        address auction,
        address counterpartyThetaVault
    ) internal {
        bytes32 order = encodeOrder(
            auctionSellOrder.userId,
            auctionSellOrder.buyAmount,
            auctionSellOrder.sellAmount
        );
        bytes32[] memory orders = new bytes32[](1);
        orders[0] = order;
        IAuction(auction).claimFromParticipantOrder(
            IVolmexRealizedVolVault(counterpartyThetaVault).vTokenAuctionID(),
            orders
        );
    }

    function getVTokenSellAmount(address vTokenAddress)
        internal
        view
        returns (uint256)
    {
        // We take our current vToken balance. That will be our sell amount
        // but vtokens will be transferred to auction contract.
        uint256 vTokenSellAmount = IERC20Upgradeable(vTokenAddress).balanceOf(
            address(this)
        );

        require(
            vTokenSellAmount <= type(uint96).max,
            "WrappedAuction: vTokenSellAmount > type(uint96) max value!"
        );

        return vTokenSellAmount;
    }

    function encodeOrder(
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(userId) << 192) +
                    (uint256(buyAmount) << 96) +
                    uint256(sellAmount)
            );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Detailed is IERC20Upgradeable {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

library AuctionType {
    struct AuctionData {
        IERC20Upgradeable auctioningToken;
        IERC20Upgradeable biddingToken;
        uint256 orderCancellationEndDate;
        uint256 auctionEndDate;
        bytes32 initialAuctionOrder;
        uint256 minimumBiddingAmountPerOrder;
        uint256 interimSumBidAmount;
        bytes32 interimOrder;
        bytes32 clearingPriceOrder;
        uint96 volumeClearingPriceOrder;
        bool minFundingThresholdNotReached;
        bool isAtomicClosureAllowed;
        uint256 feeNumerator;
        uint256 minFundingThreshold;
    }
}

interface IAuction {

    // getters
    function initiateAuction(
        address _auctioningToken,
        address _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 _auctionedSellAmount,
        uint96 _minBidAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256);
    function auctionCounter() external view returns (uint256);
    function auctionData(uint256 auctionId)
        external
        view
        returns (AuctionType.AuctionData memory);
    function auctionAccessManager(uint256 auctionId)
        external
        view
        returns (address);
    function auctionAccessData(uint256 auctionId)
        external
        view
        returns (bytes memory);
    function FEE_DENOMINATOR() external view returns (uint256);
    function feeNumerator() external view returns (uint256);

    //setters
    function placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData
    ) external;

    function placeSellOrdersOnBehalf(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData,
        address orderSubmitter
    ) external;

    function cancelSellOrders(uint256 auctionId, bytes32[] memory _sellOrders)
        external;

    function precalculateSellAmountSum(
        uint256 auctionId,
        uint256 iterationSteps
    ) external;

    function settleAuction(uint256 auctionId) external;

    function claimFromParticipantOrder(
        uint256 auctionId,
        bytes32[] memory orders
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVToken is IERC20Upgradeable {

    //getter
    function auth() external view returns (address);
    function asset() external view returns (address);
    function isShort() external view returns (bool);

    //setters
    function mint(uint256 _supply) external;
    function burn(address _account, uint256 _amount) external;
    function __VToken_init(
        string memory _name,
        string memory _symbol,
        address _assetToken,
        bool _isShort
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPriceOracle {
    event AggregatorsSet(address[] aggregators);

    //setter
    function setAggregators(address[] calldata _aggregators) external;

    // getters
    function decimals(uint8 _index) external view returns (uint256);
    function latestAnswer(uint8 _index) external view returns (uint256);
    function priceFeeds(uint8 _index) external returns (AggregatorV3Interface);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >0.4.13;

library DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";
import "./IVolmexVault.sol";

interface IVolmexRealizedVolVault is IVolmexVault {

    function vaultParams() external view returns (Vault.VaultParams memory);
    function vaultState() external view returns (Vault.VaultState memory);
    function vTokenState() external view returns (Vault.VTokenState memory);
    function vTokenAuctionID() external view returns (uint256);
    function setAuctionDuration(uint256 newAuctionDuration) external;
    function withdrawInstantly(uint256 amount) external;
    function completeWithdraw() external;
    function commitAndClose() external;
    function redeemByMarketMaker(address vToken, uint256 shares) external;
    function claimAuctionVTokens(
        Vault.AuctionSellOrder memory auctionSellOrder,
        address auction,
        address counterpartyThetaVault
    ) external;
    function rollToNextVtoken(
        uint256 _minVaultDeposit,
        uint256 _minVtokenPremium
    ) external;
    function startAuction() external;
    function burnRemainingVTokens() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.12;

import {Vault} from "../libraries/Vault.sol";

interface IVolmexVault {
    //events
    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    // getters
    function pricePerShare(uint256 round) external view returns (uint256);
    function minVaultDeposit(uint256 round) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function nextVTokenReadyAt() external view returns (uint256);
    function currentVToken() external view returns (address);
    function nextVToken() external view returns (address);
    function keeper() external view returns (address);
    function controller() external view returns (address);
    function feeRecipient() external view returns (address);
    function performanceFee() external view returns (uint256);
    function managementFee() external view returns (uint256);
    function totalPending() external view returns (uint256);
    function previewDeposit(uint256 _assets) external view returns (uint256);
    function previewMint(uint256 _shares) external view returns (uint256);
    function previewWithdraw(uint256 _assets) external view returns (uint256);
    function previewRedeem(uint256 _shares) external view returns (uint256);
    function maxDeposit(address) external view returns (uint256);
    function maxMint(address) external view returns (uint256);
    function maxWithdraw(address owner) external view returns (uint256);
    function maxRedeem(address owner) external view returns (uint256);
    function shares(address _account) external view returns (uint256);
    function getNextRollOver() external view returns (uint256);
    function shareBalances(address _account)
        external
        view
        returns (uint256 heldByAccount, uint256 heldByVault);

    // setters
    function deposit(uint256 amount, address sender) external;
    function cap() external view returns (uint256);
    function depositFor(uint256 amount, address creditor, address receiver) external;
    function setNewKeeper(address newKeeper) external;
    function setFeeRecipient(address newFeeRecipient) external;
    function setManagementFee(uint256 newManagementFee) external;
    function setPerformanceFee(uint256 newPerformanceFee) external;
    function setCap(uint256 newCap) external;
    function mint(uint256 _shares, address _receiver) external;
    function initiateWithdraw(uint256 _numShares) external;
    function redeem(uint256 _numShares) external;
    function maxRedeem() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}