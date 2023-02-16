// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IStrategy.sol";

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    /// @notice The callback for batched flashloans. Every amount + fee needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param tokens Array of addresses for ERC-20 tokens that is loaned.
    /// @param amounts A one-to-one map to `tokens` that is loaned.
    /// @param fees A one-to-one map to `tokens` that needs to be paid on top for each loan. Needs to be the same token.
    /// @param data Additional data that was passed to the flashloan function.
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

interface IBentoBoxV1 {
    function balanceOf(IERC20, address) external view returns (uint256);

    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);

    function batchFlashLoan(
        IBatchFlashBorrower borrower,
        address[] calldata receivers,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function claimOwnership() external;

    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address);

    function deposit(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    function harvest(
        IERC20 token,
        bool balance,
        uint256 maxChangeAmount
    ) external;

    function masterContractApproved(address, address) external view returns (bool);

    function masterContractOf(address) external view returns (address);

    function nonces(address) external view returns (uint256);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingStrategy(IERC20) external view returns (IStrategy);

    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function registerProtocol() external;

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function setStrategy(IERC20 token, IStrategy newStrategy) external;

    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;

    function strategy(IERC20) external view returns (IStrategy);

    function strategyData(IERC20)
        external
        view
        returns (
            uint64 strategyStartDate,
            uint64 targetPercentage,
            uint128 balance
        );

    function toAmount(
        IERC20 token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20 token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20) external view returns (Rebase memory totals_);

    function transfer(
        IERC20 token,
        address from,
        address to,
        uint256 share
    ) external;

    function transferMultiple(
        IERC20 token,
        address from,
        address[] calldata tos,
        uint256[] calldata shares
    ) external;

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function whitelistMasterContract(address masterContract, bool approved) external;

    function whitelistedMasterContracts(address) external view returns (bool);

    function withdraw(
        IERC20 token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "interfaces/IOracle.sol";

interface ICauldronV2 {
    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function accrueInfo()
        external
        view
        returns (
            uint64,
            uint128,
            uint64
        );

    function BORROW_OPENING_FEE() external view returns (uint256);

    function COLLATERIZATION_RATE() external view returns (uint256);

    function LIQUIDATION_MULTIPLIER() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function bentoBox() external view returns (address);

    function feeTo() external view returns (address);

    function masterContract() external view returns (ICauldronV2);

    function collateral() external view returns (IERC20);

    function setFeeTo(address newFeeTo) external;

    function accrue() external;

    function totalBorrow() external view returns (Rebase memory);

    function userBorrowPart(address account) external view returns (uint256);

    function userCollateralShare(address account) external view returns (uint256);

    function withdrawFees() external;

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) external;

    function removeCollateral(address to, uint256 share) external;

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function repay(
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function reduceSupply(uint256 amount) external;

    function magicInternetMoney() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/ICauldronV2.sol";

interface ICauldronV3 is ICauldronV2 {
    function borrowLimit() external view returns (uint128 total, uint128 borrowPartPerAddres);

    function changeInterestRate(uint64 newInterestRate) external;

    function changeBorrowLimit(uint128 newBorrowLimit, uint128 perAddressPart) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "interfaces/ICauldronV3.sol";

interface ICauldronV4 is ICauldronV3 {
    function setBlacklistedCallee(address callee, bool blacklisted) external;

    function blacklistedCallees(address callee) external view returns (bool);

    function repayForAll(uint128 amount, bool skim) external returns (uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log

import "interfaces/IBentoBoxV1.sol";
import "interfaces/ICauldronV2.sol";
import "interfaces/ICauldronV3.sol";
import "BoringSolidity/interfaces/IERC20.sol";
import "libraries/MathLib.sol";
import "libraries/CauldronLib.sol";

contract MarketLens {
    struct UserPosition {
        uint256 ltvBps;
        uint256 borrowValue;
        AmountValue collateralValue;
        uint256 liquidationPrice;
    }

    struct MarketInfo {
        uint256 borrowFee;
        uint256 maximumCollateralRatio;
        uint256 liquidationFee;
        uint256 interestPerYear;
        uint256 marketMaxBorrow;
        uint256 userMaxBorrow;
        uint256 totalBorrowed;
        uint256 oracleExchangeRate;
        uint256 collateralPrice;
        AmountValue totalCollateral;
    }

    struct AmountValue {
        uint256 amount;
        uint256 value;
    }

    uint256 constant PRECISION = 1e18;
    uint256 constant TENK_PRECISION = 1e5;
    uint256 constant BPS_PRECISION = 1e4;

    function getBorrowFee(ICauldronV2 cauldron) public view returns (uint256) {
        return (cauldron.BORROW_OPENING_FEE() * BPS_PRECISION) / TENK_PRECISION;
    }

    function getMaximumCollateralRatio(ICauldronV2 cauldron) public view returns (uint256) {
        return (cauldron.COLLATERIZATION_RATE() * BPS_PRECISION) / TENK_PRECISION;
    }

    function getLiquidationFee(ICauldronV2 cauldron) public view returns (uint256) {
        uint256 liquidationFee = cauldron.LIQUIDATION_MULTIPLIER() - 100_000;
        return (liquidationFee * BPS_PRECISION) / TENK_PRECISION;
    }

    function getInterestPerYear(ICauldronV2 cauldron) public view returns (uint64) {
        (, , uint64 interestPerSecond) = cauldron.accrueInfo();
        return CauldronLib.getInterestPerYearFromInterestPerSecond(interestPerSecond);
    }

    function getMimInBentoBox(ICauldronV2 cauldron) private view returns (uint256 mimInBentoBox) {
        IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
        IERC20 mim = IERC20(cauldron.magicInternetMoney());
        uint256 poolBalance = bentoBox.balanceOf(mim, address(cauldron));
        mimInBentoBox = bentoBox.toAmount(mim, poolBalance, false);
    }

    function getTokenInBentoBox(
        IBentoBoxV1 bentoBox,
        IERC20 token,
        address account
    ) private view returns (uint256 share, uint256 amount) {
        return (bentoBox.balanceOf(token, account), bentoBox.toAmount(token, share, false));
    }

    function getMaxMarketBorrowForCauldronV2(ICauldronV2 cauldron) public view returns (uint256) {
        return getMimInBentoBox(cauldron);
    }

    function getMaxUserBorrowForCauldronV2(ICauldronV2 cauldron) public view returns (uint256) {
        return getMimInBentoBox(cauldron);
    }

    // Returns the maximum amount that can be borrowed across all users
    function getMaxMarketBorrowForCauldronV3(ICauldronV3 cauldron) public view returns (uint256) {
        (uint256 totalBorrowLimit, ) = cauldron.borrowLimit();

        uint256 mimInBentoBox = getMimInBentoBox(cauldron);
        uint256 remainingBorrowLimit = MathLib.subWithZeroFloor(totalBorrowLimit, getTotalBorrowed(cauldron));

        return MathLib.min(mimInBentoBox, remainingBorrowLimit);
    }

    // Returns the maximum amount that a single user can borrow
    function getMaxUserBorrowForCauldronV3(ICauldronV3 cauldron) public view returns (uint256) {
        (uint256 totalBorrowLimit, uint256 userBorrowLimit) = cauldron.borrowLimit();

        uint256[] memory values = new uint256[](3);
        values[0] = getMimInBentoBox(cauldron);
        values[1] = MathLib.subWithZeroFloor(totalBorrowLimit, getTotalBorrowed(cauldron));
        values[2] = userBorrowLimit;

        return MathLib.min(values);
    }

    function getTotalBorrowed(ICauldronV2 cauldron) public view returns (uint256) {
        return CauldronLib.getTotalBorrowWithAccruedInterests(cauldron).elastic;
    }

    function getOracleExchangeRate(ICauldronV2 cauldron) public view returns (uint256) {
        return CauldronLib.getOracleExchangeRate(cauldron);
    }

    function getCollateralPrice(ICauldronV2 cauldron) public view returns (uint256) {
        return CauldronLib.getCollateralPrice(cauldron);
    }

    function getTotalCollateral(ICauldronV2 cauldron) public view returns (AmountValue memory) {
        IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
        uint256 amount = bentoBox.toAmount(cauldron.collateral(), cauldron.totalCollateralShare(), false);
        uint256 value = (amount * PRECISION) / getOracleExchangeRate(cauldron);
        return AmountValue(amount, value);
    }

    function getUserBorrow(ICauldronV2 cauldron, address account) public view returns (uint256) {
        return CauldronLib.getUserBorrowAmount(cauldron, account);
    }

    function getUserMaxBorrow(ICauldronV2 cauldron, address account) public view returns (uint256) {
        (, uint256 value) = CauldronLib.getUserCollateral(cauldron, account);
        return (value * getMaximumCollateralRatio(cauldron)) / TENK_PRECISION;
    }

    function getUserCollateral(ICauldronV2 cauldron, address account) public view returns (AmountValue memory) {
        (uint256 amount, uint256 value) = CauldronLib.getUserCollateral(cauldron, account);
        return AmountValue(amount, value);
    }

    function getUserLtv(ICauldronV2 cauldron, address account) public view returns (uint256 ltvBps) {
        (ltvBps, , , , ) = CauldronLib.getUserPositionInfo(cauldron, account);
    }

    function getUserLiquidationPrice(ICauldronV2 cauldron, address account) public view returns (uint256 liquidationPrice) {
        (, , , liquidationPrice, ) = CauldronLib.getUserPositionInfo(cauldron, account);
    }

    function getUserPosition(ICauldronV2 cauldron, address account) public view returns (UserPosition memory) {
        (uint256 ltvBps, uint256 borrowValue, uint256 collateralValue, uint256 liquidationPrice, uint256 collateralAmount) = CauldronLib
            .getUserPositionInfo(cauldron, account);

        return UserPosition(ltvBps, borrowValue, AmountValue({amount: collateralAmount, value: collateralValue}), liquidationPrice);
    }

    // Get many user position information at once.
    // Beware of hitting RPC `eth_call` gas limit
    function getUserPositions(ICauldronV2 cauldron, address[] calldata accounts) public view returns (UserPosition[] memory positions) {
        positions = new UserPosition[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            positions[i] = getUserPosition(cauldron, accounts[i]);
        }
    }

    function getMarketInfoCauldronV2(ICauldronV2 cauldron) public view returns (MarketInfo memory) {
        return
            MarketInfo({
                borrowFee: getBorrowFee(cauldron),
                maximumCollateralRatio: getMaximumCollateralRatio(cauldron),
                liquidationFee: getLiquidationFee(cauldron),
                interestPerYear: getInterestPerYear(cauldron),
                marketMaxBorrow: getMaxMarketBorrowForCauldronV2(cauldron),
                userMaxBorrow: getMaxUserBorrowForCauldronV2(cauldron),
                totalBorrowed: getTotalBorrowed(cauldron),
                oracleExchangeRate: getOracleExchangeRate(cauldron),
                collateralPrice: getCollateralPrice(cauldron),
                totalCollateral: getTotalCollateral(cauldron)
            });
    }

    function getMarketInfoCauldronV3(ICauldronV3 cauldron) public view returns (MarketInfo memory marketInfo) {
        marketInfo = getMarketInfoCauldronV2(cauldron);
        marketInfo.marketMaxBorrow = getMaxMarketBorrowForCauldronV3(cauldron);
        marketInfo.userMaxBorrow = getMaxUserBorrowForCauldronV3(cauldron);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringRebase.sol";
import "BoringSolidity/libraries/BoringERC20.sol";
import "interfaces/IBentoBoxV1.sol";
import "interfaces/ICauldronV3.sol";
import "interfaces/ICauldronV4.sol";

library CauldronLib {
    using BoringERC20 for IERC20;

    uint256 constant PRECISION = 1e18;
    uint256 constant BPS_PRECISION = 1e4;

    /// @dev example: 200 is 2% interests
    function getInterestPerSecond(uint256 interestBips) internal pure returns (uint64 interestsPerSecond) {
        return uint64((interestBips * 316880878) / 100); // 316880878 is the precomputed integral part of 1e18 / (36525 * 3600 * 24)
    }

    function getInterestPerYearFromInterestPerSecond(uint64 interestPerSecond) internal pure returns (uint64 interestPerYearBips) {
        return (interestPerSecond * 100) / 316880878;
    }

    function getUserBorrowAmount(ICauldronV2 cauldron, address user) internal view returns (uint256 borrowPart) {
        Rebase memory totalBorrow = getTotalBorrowWithAccruedInterests(cauldron);
        return (cauldron.userBorrowPart(user) * totalBorrow.elastic) / totalBorrow.base;
    }

    // total borrow with on-fly accrued interests
    function getTotalBorrowWithAccruedInterests(ICauldronV2 cauldron) internal view returns (Rebase memory totalBorrow) {
        totalBorrow = cauldron.totalBorrow();
        (uint64 lastAccrued, , uint64 INTEREST_PER_SECOND) = cauldron.accrueInfo();
        uint256 elapsedTime = block.timestamp - lastAccrued;

        if (elapsedTime != 0 && totalBorrow.base != 0) {
            totalBorrow.elastic = totalBorrow.elastic + uint128((uint256(totalBorrow.elastic) * INTEREST_PER_SECOND * elapsedTime) / 1e18);
        }
    }

    function getOracleExchangeRate(ICauldronV2 cauldron) internal view returns (uint256) {
        IOracle oracle = IOracle(cauldron.oracle());
        bytes memory oracleData = cauldron.oracleData();
        return oracle.peekSpot(oracleData);
    }

    function getUserCollateral(ICauldronV2 cauldron, address account) internal view returns (uint256 amount, uint256 value) {
        IBentoBoxV1 bentoBox = IBentoBoxV1(cauldron.bentoBox());
        uint256 share = cauldron.userCollateralShare(account);

        amount = bentoBox.toAmount(cauldron.collateral(), share, false);
        value = (amount * PRECISION) / getOracleExchangeRate(cauldron);
    }

    function getUserPositionInfo(ICauldronV2 cauldron, address account)
        internal
        view
        returns (
            uint256 ltvBps,
            uint256 borrowValue,
            uint256 collateralValue,
            uint256 liquidationPrice,
            uint256 collateralAmount
        )
    {
        (collateralAmount, collateralValue) = getUserCollateral(cauldron, account);

        borrowValue = getUserBorrowAmount(cauldron, account);
        ltvBps = (borrowValue * BPS_PRECISION) / collateralValue;

        uint256 COLLATERIZATION_RATE = cauldron.COLLATERIZATION_RATE(); // 1e5 precision

        // example with WBTC (8 decimals)
        // 18 + 8 + 5 - 5 - 8 - 10 = 8 decimals
        IERC20 collateral = cauldron.collateral();
        uint256 collateralPrecision = 10**collateral.safeDecimals();
        liquidationPrice = (borrowValue * collateralPrecision**2 * 1e5) / COLLATERIZATION_RATE / collateralAmount / PRECISION;
    }

    function getCollateralPrice(ICauldronV2 cauldron) internal view returns (uint256) {
        IERC20 collateral = cauldron.collateral();
        uint256 collateralPrecision = 10**collateral.safeDecimals();
        return (PRECISION * collateralPrecision) / getOracleExchangeRate(cauldron);
    }

    function decodeInitData(bytes calldata data)
        internal
        pure
        returns (
            address collateral,
            address oracle,
            bytes memory oracleData,
            uint64 INTEREST_PER_SECOND,
            uint256 LIQUIDATION_MULTIPLIER,
            uint256 COLLATERIZATION_RATE,
            uint256 BORROW_OPENING_FEE
        )
    {
        (collateral, oracle, oracleData, INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi
            .decode(data, (address, address, bytes, uint64, uint256, uint256, uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MathLib {
    function max(uint256[] memory values) internal pure returns (uint256) {
        uint256 maxValue = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            if (values[i] > maxValue) {
                maxValue = values[i];
            }
        }
        return maxValue;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256[] memory values) internal pure returns (uint256) {
        uint256 minValue = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            if (values[i] < minValue) {
                minValue = values[i];
            }
        }
        return minValue;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function subWithZeroFloor(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}