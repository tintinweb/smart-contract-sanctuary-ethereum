// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Deposit, FCNVaultMetadata, OptionBarrier, VaultStatus, Withdrawal } from "../Structs.sol";

interface IFCNProduct {
    function cegaState() external view returns (address);

    function asset() external view returns (address);

    function name() external view returns (string memory);

    function managementFeeBps() external view returns (uint256);

    function yieldFeeBps() external view returns (uint256);

    function isDepositQueueOpen() external view returns (bool);

    function maxDepositAmountLimit() external view returns (uint256);

    function sumVaultUnderlyingAmounts() external view returns (uint256);

    function queuedDepositsTotalAmount() external view returns (uint256);

    function queuedDepositsCount() external view returns (uint256);

    function vaults(
        address vaultAddress
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            VaultStatus,
            bool
        );

    function vaultAddresses() external view returns (address[] memory);

    function depositQueue() external view returns (Deposit[] memory);

    function withdrawalQueues(address vaultAddress) external view returns (Withdrawal[] memory);

    function isValidVault(address vaultAddress) external view returns (bool);

    function getVaultAddresses() external view returns (address[] memory);

    function setManagementFeeBps(uint256 _managementFeeBps) external;

    function setYieldFeeBps(uint256 _yieldFeeBps) external;

    function setMaxDepositAmountLimit(uint256 _maxDepositAmountLimit) external;

    function createVault(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _vaultStart
    ) external returns (address vaultAddress);

    function setVaultMetadata(address vaultAddress, FCNVaultMetadata calldata metadata) external;

    function removeVault(address vaultAddress) external;

    function setTradeData(
        address vaultAddress,
        uint256 _tradeDate,
        uint256 _tradeExpiry,
        uint256 _aprBps,
        uint256 _tenorInDays
    ) external;

    function addOptionBarrier(address vaultAddress, OptionBarrier calldata optionBarrier) external;

    function getOptionBarriers(address vaultAddress) external view returns (OptionBarrier[] memory);

    function getOptionBarrier(address vaultAddress, uint256 index) external view returns (OptionBarrier memory);

    function updateOptionBarrier(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        uint256 _strikeAbsoluteValue,
        uint256 _barrierAbsoluteValue
    ) external;

    function updateOptionBarrierOracle(
        address vaultAddress,
        uint256 index,
        string calldata _asset,
        string memory newOracleName
    ) external;

    function removeOptionBarrier(address vaultAddress, uint256 index, string calldata _asset) external;

    function setVaultStatus(address vaultAddress, VaultStatus _vaultStatus) external;

    function openVaultDeposits(address vaultAddress) external;

    function setKnockInStatus(address vaultAddress, bool newState) external;

    function addToDepositQueue(uint256 amount, address receiver) external;

    function processDepositQueue(address vaultAddress, uint256 maxProcessCount) external;

    function addToWithdrawalQueue(address vaultAddress, uint256 amountShares, address receiver) external;

    function checkBarriers(address vaultAddress) external;

    function calculateVaultFinalPayoff(address vaultAddress) external returns (uint256 vaultFinalPayoff);

    function calculateKnockInRatio(address vaultAddress) external view returns (uint256 knockInRatio);

    function receiveAssetsFromCegaState(address vaultAddress, uint256 amount) external;

    function calculateFees(
        address vaultAddress
    ) external view returns (uint256 totalFee, uint256 managementFee, uint256 yieldFee);

    function collectFees(address vaultAddress) external;

    function processWithdrawalQueue(address vaultAddress, uint256 maxProcessCount) external;

    function rolloverVault(address vaultAddress) external;

    function sendAssetsToTrade(address vaultAddress, address receiver, uint256 amount) external;

    function calculateCurrentYield(address vaultAddress) external;

    function getVaultMetadata(address vaultAddress) external view returns (FCNVaultMetadata memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFCNVault is IERC20 {
    function asset() external view returns (address);

    function fcnProduct() external view returns (address);

    function totalAssets() external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function redeem(uint256 shares) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum OptionBarrierType {
    None,
    KnockIn
}

struct Deposit {
    uint256 amount;
    address receiver;
}

struct Withdrawal {
    uint256 amountShares;
    address receiver;
}

enum VaultStatus {
    DepositsClosed,
    DepositsOpen,
    NotTraded,
    Traded,
    TradeExpired,
    PayoffCalculated,
    FeesCollected,
    WithdrawalQueueProcessed,
    Zombie
}

struct OptionBarrier {
    uint256 barrierBps;
    uint256 barrierAbsoluteValue;
    uint256 strikeBps;
    uint256 strikeAbsoluteValue;
    string asset;
    string oracleName;
    OptionBarrierType barrierType;
}

struct FCNVaultMetadata {
    uint256 vaultStart;
    uint256 tradeDate;
    uint256 tradeExpiry;
    uint256 aprBps;
    uint256 tenorInDays;
    uint256 underlyingAmount; // This is how many assets were ever deposited into the vault
    uint256 currentAssetAmount; // This is how many assets are currently allocated for the vault (not sent for trade)
    uint256 totalCouponPayoff;
    uint256 vaultFinalPayoff;
    uint256 queuedWithdrawalsSharesAmount;
    uint256 queuedWithdrawalsCount;
    uint256 optionBarriersCount;
    uint256 leverage;
    address vaultAddress;
    VaultStatus vaultStatus;
    bool isKnockedIn;
    OptionBarrier[] optionBarriers;
}

struct RoundData {
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IFCNProduct } from "../interfaces/IFCNProduct.sol";
import { IFCNVault } from "../interfaces/IFCNVault.sol";
import { FCNVaultMetadata, OptionBarrier, VaultStatus } from "../Structs.sol";

contract FCNProductViewer {
    struct FCNProductInfo {
        address asset;
        string name;
        uint256 managementFeeBps; // basis points
        uint256 yieldFeeBps; // basis points
        bool isDepositQueueOpen;
        uint256 maxDepositAmountLimit;
        uint256 sumVaultUnderlyingAmounts;
        uint256 queuedDepositsTotalAmount;
        uint256 queuedDepositsCount;
    }

    struct FCNVaultAssetInfo {
        address vaultAddress;
        uint256 totalAssets;
        uint256 totalSupply;
        uint256 inputAssets;
        uint256 outputShares;
        uint256 inputShares;
        uint256 outputAssets;
    }

    function getFCNProductInfo(address fcnProductAddress) external view returns (FCNProductInfo memory) {
        IFCNProduct fcnProduct = IFCNProduct(fcnProductAddress);
        return
            FCNProductInfo({
                asset: fcnProduct.asset(),
                name: fcnProduct.name(),
                managementFeeBps: fcnProduct.managementFeeBps(),
                yieldFeeBps: fcnProduct.yieldFeeBps(),
                isDepositQueueOpen: fcnProduct.isDepositQueueOpen(),
                maxDepositAmountLimit: fcnProduct.maxDepositAmountLimit(),
                sumVaultUnderlyingAmounts: fcnProduct.sumVaultUnderlyingAmounts(),
                queuedDepositsTotalAmount: fcnProduct.queuedDepositsTotalAmount(),
                queuedDepositsCount: fcnProduct.queuedDepositsCount()
            });
    }

    function getFCNVaultMetadata(address fcnProductAddress) external view returns (FCNVaultMetadata[] memory) {
        IFCNProduct fcnProduct = IFCNProduct(fcnProductAddress);

        address[] memory vaultAddresses = fcnProduct.getVaultAddresses();

        FCNVaultMetadata[] memory vaultMetadata = new FCNVaultMetadata[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            vaultMetadata[i] = fcnProduct.getVaultMetadata(vaultAddresses[i]);
        }

        return vaultMetadata;
    }

    function getFCNVaultAssetInfo(
        address fcnProductAddress,
        uint256 inputAssets,
        uint256 inputShares
    ) external view returns (FCNVaultAssetInfo[] memory) {
        IFCNProduct fcnProduct = IFCNProduct(fcnProductAddress);

        address[] memory vaultAddresses = fcnProduct.getVaultAddresses();

        FCNVaultAssetInfo[] memory assetInfo = new FCNVaultAssetInfo[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            IFCNVault vault = IFCNVault(vaultAddresses[i]);

            assetInfo[i] = FCNVaultAssetInfo({
                vaultAddress: address(vault),
                totalAssets: vault.totalAssets(),
                totalSupply: vault.totalSupply(),
                inputAssets: inputAssets,
                outputShares: vault.convertToShares(inputAssets),
                inputShares: inputShares,
                outputAssets: vault.convertToAssets(inputShares)
            });
        }

        return assetInfo;
    }
}