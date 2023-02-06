// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// SPDX-License-Identifier: AGPL-3.0-or-later

/// AaveStoplLossCommand.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.13;
import { IServiceRegistry } from "../interfaces/IServiceRegistry.sol";
import { ILendingPool } from "../interfaces/AAVE/ILendingPool.sol";
import { IAccountImplementation } from "../interfaces/IAccountImplementation.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SwapData } from "./../libs/EarnSwapData.sol";
import { ISwap } from "./../interfaces/ISwap.sol";
import { DataTypes } from "../libs/AAVEDataTypes.sol";
import { BaseAAveFlashLoanCommand } from "./BaseAAveFlashLoanCommand.sol";
import { IWETH } from "../interfaces/IWETH.sol";

struct AaveData {
    address collateralTokenAddress;
    address debtTokenAddress;
    address borrower;
    address payable fundsReceiver;
}

struct AddressRegistry {
    address aaveStopLoss;
    address exchange;
}

struct StopLossTriggerData {
    address positionAddress;
    uint16 triggerType;
    address collateralToken;
    address debtToken;
    uint256 slLevel;
}

struct CloseData {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] modes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
}

interface AaveStopLoss {
    function closePosition(
        SwapData calldata exchangeData,
        AaveData memory aaveData,
        AddressRegistry calldata addressRegistry
    ) external;

    function trustedCaller() external returns (address);

    function self() external returns (address);
}

contract AaveStoplLossCommand is BaseAAveFlashLoanCommand {
    string private constant OPERATION_EXECUTOR = "OPERATION_EXECUTOR";
    string private constant AAVE_POOL = "AAVE_POOL";
    string private constant AUTOMATION_BOT = "AUTOMATION_BOT_V2";
    string private constant WETH = "WETH";

    constructor(
        IServiceRegistry _serviceRegistry,
        ILendingPool _lendingPool
    ) BaseAAveFlashLoanCommand(_serviceRegistry, _lendingPool) {}

    function validateTriggerType(uint16 triggerType, uint16 expectedTriggerType) public pure {
        require(triggerType == expectedTriggerType, "base-aave-fl-command/type-not-supported");
    }

    function validateSelector(bytes4 expectedSelector, bytes memory executionData) public pure {
        bytes4 selector = abi.decode(executionData, (bytes4));
        require(selector == expectedSelector, "base-aave-fl-command/invalid-selector");
    }

    function isExecutionCorrect(bytes memory triggerData) external view override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );
        address weth = address(serviceRegistry.getRegisteredService(WETH));
        require(reciveExpected == false, "base-aave-fl-command/contract-not-empty");
        require(
            IERC20(stopLossTriggerData.collateralToken).balanceOf(self) == 0 &&
                IERC20(stopLossTriggerData.debtToken).balanceOf(self) == 0 &&
                (stopLossTriggerData.collateralToken != weth ||
                    (IERC20(weth).balanceOf(self) == 0 && self.balance == 0)),
            "base-aave-fl-command/contract-not-empty"
        );
        (uint256 totalCollateralETH, uint256 totalDebtETH, , , , ) = lendingPool.getUserAccountData(
            stopLossTriggerData.positionAddress
        );

        return !(totalCollateralETH > 0 && totalDebtETH > 0);
    }

    function isExecutionLegal(bytes memory triggerData) external view override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );

        (uint256 totalCollateralETH, uint256 totalDebtETH, , , , ) = lendingPool.getUserAccountData(
            stopLossTriggerData.positionAddress
        );

        if (totalDebtETH == 0) return false;

        uint256 ltv = (10 ** 8 * totalDebtETH) / totalCollateralETH;
        bool vaultHasDebt = totalDebtETH != 0;
        return vaultHasDebt && ltv >= stopLossTriggerData.slLevel;
    }

    function execute(
        bytes calldata executionData,
        bytes memory triggerData
    ) external override nonReentrant {
        require(
            serviceRegistry.getRegisteredService(AUTOMATION_BOT) == msg.sender,
            "aaveSl/caller-not-bot"
        );

        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );
        trustedCaller = stopLossTriggerData.positionAddress;
        validateSelector(AaveStopLoss.closePosition.selector, executionData);
        IAccountImplementation(stopLossTriggerData.positionAddress).execute(self, executionData);

        trustedCaller = address(0);
    }

    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external pure override returns (bool) {
        StopLossTriggerData memory stopLossTriggerData = abi.decode(
            triggerData,
            (StopLossTriggerData)
        );

        return
            !continuous &&
            stopLossTriggerData.slLevel < 10 ** 8 &&
            (stopLossTriggerData.triggerType == 10 || stopLossTriggerData.triggerType == 11);
    }

    function closePosition(
        SwapData calldata exchangeData,
        AaveData memory aaveData,
        AddressRegistry calldata addressRegistry
    ) external {
        require(
            AaveStopLoss(addressRegistry.aaveStopLoss).trustedCaller() == address(this),
            "aaveSl/caller-not-allowed"
        );
        require(self == msg.sender, "aaveSl/msg-sender-is-not-sl");

        DataTypes.ReserveData memory collReserveData = lendingPool.getReserveData(
            aaveData.collateralTokenAddress
        );
        DataTypes.ReserveData memory debtReserveData = lendingPool.getReserveData(
            aaveData.debtTokenAddress
        );
        uint256 totalToRepay = IERC20(debtReserveData.variableDebtTokenAddress).balanceOf(
            aaveData.borrower
        );
        uint256 totalCollateral = IERC20(collReserveData.aTokenAddress).balanceOf(
            aaveData.borrower
        );
        IERC20(collReserveData.aTokenAddress).approve(
            addressRegistry.aaveStopLoss,
            totalCollateral
        );

        {
            CloseData memory closeData;

            address[] memory debtTokens = new address[](1);
            debtTokens[0] = address(aaveData.debtTokenAddress);
            uint256[] memory amounts = new uint256[](1);
            amounts[0] = totalToRepay;
            uint256[] memory modes = new uint256[](1);
            modes[0] = uint256(0);

            closeData.receiverAddress = addressRegistry.aaveStopLoss;
            closeData.assets = debtTokens;
            closeData.amounts = amounts;
            closeData.modes = modes;
            closeData.onBehalfOf = address(this);
            closeData.params = abi.encode(
                collReserveData.aTokenAddress,
                aaveData.collateralTokenAddress,
                addressRegistry.exchange,
                aaveData.borrower,
                aaveData.fundsReceiver,
                exchangeData
            );
            closeData.referralCode = 0;
            lendingPool.flashLoan(
                closeData.receiverAddress,
                closeData.assets,
                closeData.amounts,
                closeData.modes,
                closeData.onBehalfOf,
                closeData.params,
                closeData.referralCode
            );
        }
        IERC20(aaveData.debtTokenAddress).transfer(
            aaveData.fundsReceiver,
            IERC20(aaveData.debtTokenAddress).balanceOf(aaveData.borrower)
        );
    }

    function flashloanAction(bytes memory data) internal override {
        FlData memory flData;
        (flData.assets, flData.amounts, flData.premiums, flData.initiator, flData.params) = abi
            .decode(data, (address[], uint256[], uint256[], address, bytes));
        (
            address aTokenAddress,
            address collateralTokenAddress,
            address exchangeAddress,
            address borrower,
            address fundsReceiver,
            SwapData memory exchangeData
        ) = abi.decode(flData.params, (address, address, address, address, address, SwapData));

        require(flData.initiator == borrower, "aaveSl/initiator-not-borrower");

        IERC20 collateralToken = IERC20(collateralTokenAddress);
        IERC20 debtToken = IERC20(flData.assets[0]);
        IERC20 aToken = IERC20(aTokenAddress);
        uint256 flTotal = (flData.amounts[0] + flData.premiums[0]);
        uint256 aTokenBalance = aToken.balanceOf(borrower);

        _repay(address(debtToken), borrower, flData.amounts[0]);
        _pullTokenAndWithdraw(aToken, collateralTokenAddress, borrower, aTokenBalance);
        _exchange(
            collateralToken,
            debtToken,
            exchangeAddress,
            aTokenBalance,
            flTotal,
            exchangeData
        );
        address weth = address(serviceRegistry.getRegisteredService(WETH));
        if (address(collateralToken) == weth) {
            expectRecive();
            uint256 balance = IERC20(weth).balanceOf(self);
            IWETH(weth).withdraw(balance);
            ethReceived();
            payable(fundsReceiver).transfer(self.balance);
        } else {
            _transfer(address(collateralToken), fundsReceiver, 0);
        }
        _transfer(address(debtToken), fundsReceiver, debtToken.balanceOf(self) - flTotal);
    }

    function _transfer(address token, address to, uint256 amount) internal {
        if (amount == 0) {
            IERC20(token).transfer(to, IERC20(token).balanceOf(self));
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    function _repay(address token, address onBehalf, uint256 amount) internal {
        IERC20(token).approve(address(lendingPool), amount);
        lendingPool.repay(token, amount, 2, onBehalf);
    }

    function _exchange(
        IERC20 collateralToken,
        IERC20 debtToken,
        address exchangeAddress,
        uint256 balance,
        uint256 flTotal,
        SwapData memory exchangeData
    ) internal {
        collateralToken.approve(exchangeAddress, balance);

        uint256 debtTokenBalanceBefore = debtToken.balanceOf(self);
        ISwap(exchangeAddress).swapTokens(exchangeData);
        require(
            (debtToken.balanceOf(self) - debtTokenBalanceBefore) > (flTotal),
            "aaveSl/recieved-too-little-from-swap"
        );
    }

    function _pullTokenAndWithdraw(
        IERC20 aToken,
        address collateralTokenAddress,
        address borrower,
        uint256 balance
    ) internal {
        aToken.transferFrom(borrower, self, balance);
        lendingPool.withdraw(collateralTokenAddress, (type(uint256).max), self);
    }

    receive() external payable {
        require(reciveExpected == true, "aaveSl/unexpected-eth-receive");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// BaseAAveFlashLoanCommand.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import { ICommand } from "../interfaces/ICommand.sol";

import { ILendingPool } from "../interfaces/AAVE/ILendingPool.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IServiceRegistry } from "../interfaces/IServiceRegistry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IFlashLoanReceiver {
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

abstract contract BaseAAveFlashLoanCommand is ICommand, IFlashLoanReceiver, ReentrancyGuard {
    IServiceRegistry public immutable serviceRegistry;
    ILendingPool public immutable lendingPool;

    address public trustedCaller;
    address public immutable self;

    bool public reciveExpected;

    struct FlData {
        address initiator;
        address[] assets;
        uint256[] amounts;
        uint256[] modes;
        uint256[] premiums;
        address onBehalfOf;
        bytes params;
    }

    constructor(IServiceRegistry _serviceRegistry, ILendingPool _lendingPool) {
        serviceRegistry = _serviceRegistry;
        lendingPool = _lendingPool;
        self = address(this);
    }

    function expectRecive() internal {
        reciveExpected = true;
    }

    function ethReceived() internal {
        reciveExpected = false;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        require(initiator == trustedCaller, "aaveSl/caller-not-initiator");
        require(msg.sender == address(lendingPool), "aaveSl/caller-must-be-lending-pool");

        bytes memory data = abi.encode(assets, amounts, premiums, initiator, params);

        flashloanAction(data);

        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).approve(address(lendingPool), amounts[i] + premiums[i]);
        }

        return true;
    }

    function flashloanAction(bytes memory _data) internal virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { ILendingPoolAddressesProvider } from "./ILendingPoolAddressesProvider.sol";
import { DataTypes } from "../../libs/AAVEDataTypes.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(
        address asset
    ) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(
        address user
    ) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IAccountImplementation {
    function execute(
        address _target,
        bytes memory _data
    ) external payable returns (bytes32 response);

    function send(address _target, bytes memory _data) external payable;

    function guard() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ICommand {
    function isTriggerDataValid(
        bool continuous,
        bytes memory triggerData
    ) external view returns (bool);

    function isExecutionCorrect(bytes memory triggerData) external view returns (bool);

    function isExecutionLegal(bytes memory triggerData) external view returns (bool);

    function execute(bytes calldata executionData, bytes memory triggerData) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.13;

interface IServiceRegistry {
    function getRegisteredService(string memory) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { SwapData } from "./../libs/EarnSwapData.sol";

interface ISwap {
    function swapTokens(SwapData calldata swapData) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IWETH {
    function withdraw(uint256 wad) external;

    function deposit() external payable;

    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
struct SwapData {
    address fromAsset;
    address toAsset;
    uint256 amount;
    uint256 receiveAtLeast;
    uint256 fee;
    bytes withData;
    bool collectFeeInFromToken;
}

library EarnSwapData {}