// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "solmate/utils/SafeTransferLib.sol";
import "authorised/Authorised.sol";
import "./libraries/UniPoolAddress.sol";
import "./interfaces/IAaveLendingPool.sol";
import "./interfaces/IUniV2Pool.sol";
import "./interfaces/IUniV3Pool.sol";
import "./interfaces/IUniV2Callback.sol";
import "./interfaces/IUniV3Callback.sol";
import "./interfaces/IWETH.sol";

contract AaveStrategy is IUniV3Callback, IUniswapV2Callback, Authorised {

    using SafeTransferLib for ERC20;

    enum Action { LEVERAGE, DELEVERAGE, SWAP_COLLATERAL }

    enum Network { NONE, POS, POW }

    //Uniswap V3 trading pool constant.
    uint160 internal constant MIN_SQRT_RATIO = 4295128739 + 1;
    //Uniswap V3 trading pool constant.
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342 - 1;
    //Uniswap V3 factory.
    address internal constant uniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    //Weth address.
    ERC20 internal constant weth = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //Aave lending pool.
    ILendingPool internal constant lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    //Verify sender for pool callbacks.
    address internal callbackAddress;

    constructor() Authorised(msg.sender) {}

    modifier enforceNetwork(Network network) {
        if (network == Network.POS) {
            require(block.difficulty > 2 ** 64, "We are not on POS.");
        } else if (network == Network.POW) {
            require(block.difficulty <= 2 ** 64, "We are not on POW.");
        }
        _;
    }

    modifier validCallback() {
        require(msg.sender == callbackAddress, "Invalid call.");
        _;
    }

    receive() external payable {
        _wrapEth(msg.value);
        _deposit(weth, msg.value);
    }

    function uniswapV3SwapCallback(int256 change0, int256 change1, bytes calldata data) external validCallback {
        (Action action, ERC20 tokenIn, ERC20 tokenOut) = abi.decode(data, (Action, ERC20, ERC20));
        if (change0 > change1) {
            closeSwap(tokenIn, tokenOut, uint256(change0), uint256(-change1), action);
        } else {
            closeSwap(tokenIn, tokenOut, uint256(change1), uint256(-change0), action);
        }
    }

    function uniswapV2Call(address, uint amount0Out, uint amount1Out, bytes calldata data) external validCallback {
        (Action action, uint256 amountIn, ERC20 tokenIn, ERC20 tokenOut) = abi.decode(data, (Action, uint256, ERC20, ERC20));
        closeSwap(tokenIn, tokenOut, amountIn, amount1Out + amount0Out, action);
    }

    function closeSwap(ERC20 tokenIn, ERC20 tokenOut, uint256 amountIn, uint256 amountOut, Action action) internal {
        if (action == Action.LEVERAGE) {
            _deposit(tokenOut, amountOut);
            _borrow(tokenIn, amountIn, 2);
            tokenIn.safeTransfer(msg.sender, amountIn);
        } else if (action == Action.DELEVERAGE) {
            _repay(tokenOut, amountOut, 2);
            _withdraw(tokenIn, amountIn, msg.sender);
        } else if (action == Action.SWAP_COLLATERAL) {
            _deposit(tokenOut, amountOut);
            _withdraw(tokenIn, amountIn, msg.sender);
        }
    }

    function withdrawFromAave(ERC20 asset, uint256 amount, Network network) external onlyAuthorised enforceNetwork(network) {
        _withdraw(asset, amount, address(this));
    }

    function depositToAave(ERC20 asset, uint256 amount, Network network) external onlyAuthorised enforceNetwork(network) {
        _deposit(asset, amount);
    }

    function borrowFromAave(ERC20 asset, uint256 amount, Network network) external onlyAuthorised enforceNetwork(network) {
        _borrow(asset, amount, 2);
    }

    function repayToAave(ERC20 asset, uint256 amount, Network network)  external onlyAuthorised enforceNetwork(network) {
        _repay(asset, amount, 2);
    }

    function withdrawToken(ERC20 token, address to, uint256 amount, Network network) external onlyAuthorised enforceNetwork(network) {
        if (address(token) == address(0)) {
            SafeTransferLib.safeTransferETH(to, amount);
        } else {
            token.safeTransfer(to, amount);
        }
    }

    // Buy weth with usdc on a uni v3 pool. usdc is token 0, weth is token 1.
    // exactInput ~ positive number
    // exactOutput ~ negative number
    // Assume we have some borrowing power in aave already.
    /// @param tokenIn Token in for the Uniswap trade.
    /// @param tokenOut Token out for the Uniswap trade.
    /// @param fee Uniswap pool fee tier.
    /// @param amountOut Amount out of the trade that will be sent to aave as collateral.
    /// @param maxAmountIn Slippage protection - max
    function leverageV3(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV3(tokenIn, tokenOut, fee, amountOut, maxAmountIn, Action.LEVERAGE);
    }

    function leverageV2(address factory, address tokenIn, address tokenOut, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV2(factory, tokenIn, tokenOut, amountOut, maxAmountIn, Action.LEVERAGE);
    }

    function repayV3(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV3(tokenIn, tokenOut, fee, amountOut, maxAmountIn, Action.DELEVERAGE);
    }

    function repayV2(address factory, address tokenIn, address tokenOut, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV2(factory, tokenIn, tokenOut, amountOut, maxAmountIn, Action.DELEVERAGE);
    }

    function swapCollateralV3(address tokenIn, address tokenOut, uint24 fee, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV3(tokenIn, tokenOut, fee, amountOut, maxAmountIn, Action.SWAP_COLLATERAL);
    }

    function swapCollateralV2(address factory, address tokenIn, address tokenOut, uint256 amountOut, uint256 maxAmountIn, Network network) external onlyAuthorised  enforceNetwork(network) returns (uint256 amountIn) {
        amountIn = _swapUniV2(factory, tokenIn, tokenOut, amountOut, maxAmountIn, Action.SWAP_COLLATERAL);
    } 

    function getUserAccountData() external view returns (uint256 totalCollateralETH, uint256 totalDebtETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor) {
        return lendingPool.getUserAccountData(address(this));
    }

    function availableEthToWithdraw() external view returns (uint256) {
        (,,uint256 availableBorrowsETH,,,) = lendingPool.getUserAccountData(address(this));
        return availableBorrowsETH * 1000 / 825;
    }

    function getDebt(address asset) external view returns (uint256) {
        ERC20 debtToken = ERC20(lendingPool.getReserveData(asset).variableDebtTokenAddress);
        return debtToken.balanceOf(address(this));
    }

    function getAvailalbeFunds(ERC20[] memory assets) external view returns (uint256[] memory available) {
        uint256 n = assets.length;
        available = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            ERC20 asset = assets[i];
            available[i] = asset.balanceOf(lendingPool.getReserveData(address(asset)).aTokenAddress) / (asset.decimals() - 2);
        }
    }

    function _swapUniV3(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint256 maxAmountIn,
        Action action
    ) internal returns (uint256 amountIn) {
        address pool = UniPoolAddress.computeAddress(uniV3Factory, UniPoolAddress.getPoolKey(tokenIn, tokenOut, fee));
        callbackAddress = pool;
        amountIn = __swapUniV3(IUniV3Pool(pool), tokenIn < tokenOut, amountOut, abi.encode(action, tokenIn, tokenOut));
        require(amountIn <= maxAmountIn, "Slippage.");
        callbackAddress = address(0);
    }

    function __swapUniV3(
        IUniV3Pool pool,
        bool zeroForOne,
        uint256 amountOut,
        bytes memory data
    ) internal returns (uint256 amountIn) {
        (int256 change0, int256 change1) = pool.swap(
            address(this),
            zeroForOne,
            -int256(amountOut),
            zeroForOne ? MIN_SQRT_RATIO : MAX_SQRT_RATIO,
            data
        );
        amountIn = uint256(zeroForOne ? change0 : change1);
    }

    function _swapUniV2(
        address factory,
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        Action action
    ) internal returns (uint256 amountIn) {
        IUniV2Pool pool = IUniV2Pool(UniPoolAddress.pairFor(factory, tokenIn, tokenOut));
        callbackAddress = address(pool);
        (uint256 reserve0, uint256 reserve1,) = pool.getReserves();
        if (tokenIn < tokenOut) { // zeroForOne ~ true
            amountIn = _getAmountIn(amountOut, reserve0, reserve1);
            pool.swap(0, amountOut, address(this), abi.encode(action, amountIn, tokenIn, tokenOut));
        } else {
            amountIn = _getAmountIn(amountOut, reserve1, reserve0);
            pool.swap(amountOut, 0, address(this), abi.encode(action, amountIn, tokenIn, tokenOut));
        }
        require(amountIn <= maxAmountIn, "Slippage.");
        callbackAddress = address(0);
    }

    function _wrapEth(uint256 amount) internal {
        IWETH(address(weth)).deposit{value: amount}();
    }

    function _deposit(ERC20 asset, uint256 amount) internal {
        asset.safeApprove(address(lendingPool), amount);
        lendingPool.deposit(address(asset), amount, address(this), 0);
    }

    function _borrow(ERC20 asset, uint256 amount, uint256 rateMode) internal {
        lendingPool.borrow(address(asset), amount, rateMode, 0, address(this));
    }

    function _repay(ERC20 asset, uint256 amount, uint256 rateMode) internal {
        asset.safeApprove(address(lendingPool), amount);
        lendingPool.repay(address(asset), amount, rateMode, address(this));
    }

    function _withdraw(ERC20 asset, uint256 amount, address to) internal {
        lendingPool.withdraw(address(asset), amount, to);
    }

    function _getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = numerator / denominator + 1;
    }

    function executeAnything(address target, uint256 val, bytes memory data) external onlyOwner returns (bytes memory res) {
        bool ok;
        (ok, res) = target.call{value: val}(data);
        require(ok, "failed");
    }

}

// (1120,2493) ~ (-206107, -198107)
// (1300,2493) ~ (-204619, -198107)

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import "./Owned.sol";

abstract contract Authorised is Owned {
    
    event SetAuthorised(address indexed user, bool isAuthorised);

    mapping(address => bool) public authorised;

    modifier onlyAuthorised() {
        if (!authorised[msg.sender]) revert Unauthorised();
        _;
    }

    constructor(address _owner) Owned(_owner) {
        authorised[_owner] = true;
        emit SetAuthorised(_owner, true);
    }

    function setAuthorised(address user, bool _authorised) public onlyOwner {
        authorised[user] = _authorised;
        emit SetAuthorised(user, _authorised);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library UniPoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    ) & bytes32(uint256(type(uint160).max))
                )
            )
        );
    }

    function pairFor(address factory, address token0, address token1) internal pure returns (address pair) {
        if (token0 > token1) (token0, token1) = (token1, token0);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
                        )
                    ) & bytes32(uint256(type(uint160).max))
                )
            )
        );
    }
}

pragma solidity 0.8.16;

//import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../libraries/AaveDataTypes.sol';

interface ILendingPool {
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
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

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
  function getUserAccountData(address user)
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

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

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
  function getAddressesProvider() external view returns (address);
  function setPause(bool val) external;
  function paused() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IUniV2Pool {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IUniV3Pool {
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

pragma solidity >=0.5.0;

interface IUniswapV2Callback {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.16;

interface IUniV3Callback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

abstract contract Owned {
    
    event SetOwner(address indexed user, address indexed newOwner);

    address public owner;

    error Unauthorised();

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorised();
        _;
    }

    constructor(address _owner) {
        owner = _owner;
        emit SetOwner(address(0), _owner);
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
        emit SetOwner(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

library DataTypes {
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

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}