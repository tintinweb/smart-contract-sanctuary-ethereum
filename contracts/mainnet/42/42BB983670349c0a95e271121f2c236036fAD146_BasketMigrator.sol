// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {CERC20} from "CERC20.sol";
import {IRecipe} from "IRecipe.sol";
import {SushiBar} from "SushiBar.sol";
import {VaultAPI} from "VaultAPI.sol";
import {IBasketFacet} from "IBasketFacet.sol";
import {IBasketLogic} from "IBasketLogic.sol";
import {ISwapRouter} from "ISwapRouter.sol";
import {ICurvePool_2Token} from "ICurvePool_2Token.sol";
import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {IUniswapV2Router01} from "IUniswapV2Router01.sol";

/// @title BasketMigrator
/// @author dantop114
/// @notice BasketDAO indexes migration contract.
contract BasketMigrator {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                    Constants and immutables
    ///////////////////////////////////////////////////////////////*/

    /// @notice BDI contract address.
    address public constant BDI = 0x0309c98B1bffA350bcb3F9fB9780970CA32a5060;

    /// @notice DEFI++ contract address.
    address public constant DPP = 0x8D1ce361eb68e9E05573443C407D4A3Bed23B033;

    /// @notice WETH contract address.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice yvCurveLink address.
    address internal constant yvCurveLink =
        0xf2db9a7c0ACd427A680D640F02d90f6186E71725;

    /// @notice yvUNI address.
    address internal constant yvUNI =
        0xFBEB78a723b8087fD2ea7Ef1afEc93d35E8Bed42;

    /// @notice yvYFI address.
    address internal constant yvYFI =
        0xE14d13d8B3b85aF791b2AADD661cDBd5E6097Db1;

    /// @notice yvSNX address.
    address internal constant yvSNX =
        0xF29AE508698bDeF169B89834F76704C3B205aedf;

    /// @notice cCOMP address.
    address internal constant cCOMP =
        0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    /// @notice xSUSHI address.
    address internal constant xSUSHI =
        0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    /// @notice Curve Liquidity Pool LINK/sLINK
    address internal constant curvePoolLINK =
        0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0;

    /// @notice Curve LP Token LINK/sLINK
    address internal constant crvLINK =
        0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a;

    /// @notice Governance address for this contract.
    address public immutable gov;

    /*///////////////////////////////////////////////////////////////
                    Structs declarations
    ///////////////////////////////////////////////////////////////*/

    /// @notice Swap struct.
    /// @param v3 boolean telling us if the swap is done on UniswapV3
    /// @param data abi.encode of Router and swap data.
    struct Swap {
        bool v3;
        bytes data;
    }

    /*///////////////////////////////////////////////////////////////
                    Errors definition
    ///////////////////////////////////////////////////////////////*/

    /// @notice Error emitted when users try to deposit in state != 0.
    error EntryClosed();

    /// @notice Error emitted when contract is not in state 1.
    error NotBaking();

    /// @notice Error emitted when a contract is not in state 2.
    error NotBaked();

    /// @notice Error emitted when the user did not deposit.
    error NoDeposit();

    /// @notice Error emitted when amount to deposit is zero.
    error AmountZero();

    /// @notice Error emitted when caller is not the governance address.
    error NotGovernance();

    /// @notice Error emitted when the burn of shares fails.
    error BurnFailed();

    /// @notice Error emitted when the deadline to swap is reached.
    error DeadlineReached();

    /// @notice Error emitted when the baking fails.
    error BakeFailed();

    /*///////////////////////////////////////////////////////////////
                    Events definition
    ///////////////////////////////////////////////////////////////*/

    /// @notice Event emitted when a user deposits.
    event Entry(address indexed who, uint256 amount);

    /// @notice Event emitted when the deposits are closed.
    event Closed();

    /*///////////////////////////////////////////////////////////////
                          Storage
    ///////////////////////////////////////////////////////////////*/

    /// @notice Exchange rate at settlement.
    uint256 public rate;

    /// @notice State of the contract.
    /// @dev The state is an uint8 acting as an enum:
    ///         - 0: accepting deposits (open)
    ///         - 1: no more deposits accepted (baking)
    ///         - 2: users can withdraw (done)
    uint8 public state;

    /// @notice Total deposited in the contract.
    uint256 public totalDeposits;

    /// @notice Deposited amount per user.
    mapping(address => uint256) public deposits;

    /*///////////////////////////////////////////////////////////////
                          Constructor
    ///////////////////////////////////////////////////////////////*/

    constructor(address _gov) {
        gov = _gov;
    }

    /*///////////////////////////////////////////////////////////////
                       State changing logic
    ///////////////////////////////////////////////////////////////*/

    function closeEntry() external {
        if (msg.sender != gov) revert NotGovernance();
        if (state != 0) revert EntryClosed();

        state = 1;

        emit Closed();
    }

    /*///////////////////////////////////////////////////////////////
                    User deposit/redeem logic
    ///////////////////////////////////////////////////////////////*/

    /// @notice Let users enter the migration process.
    /// @param amount Amount of BDI to take from the user.
    function enter(uint256 amount) external {
        if (state != 0) revert EntryClosed();
        if (amount == 0) revert AmountZero();

        totalDeposits += amount;
        deposits[msg.sender] += amount;
        IERC20(BDI).safeTransferFrom(msg.sender, address(this), amount);

        emit Entry(msg.sender, amount);
    }

    /// @notice Let users withdraw their share.
    function exit() external {
        if (state != 2) revert NotBaked();

        uint256 deposited = deposits[msg.sender];

        if (deposited == 0) revert NoDeposit();

        deposits[msg.sender] = 0;
        uint256 amount = (rate * deposited) / 1e18;
        IERC20(DPP).transfer(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Burn, unwrap and swap
    ///////////////////////////////////////////////////////////////*/

    /// @notice Burns all BDI present in the contract and unwraps for underlying.
    function burnAndUnwrap() external {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();

        // Burn BDI.
        IBasketLogic(BDI).burn(IERC20(BDI).balanceOf(address(this)));

        // Unwrap Yearn vaults' shares.
        VaultAPI(yvSNX).withdraw();
        VaultAPI(yvUNI).withdraw();
        VaultAPI(yvYFI).withdraw();
        VaultAPI(yvCurveLink).withdraw();

        // Unwrap LINK from Curve Pool
        uint256 bal = IERC20(crvLINK).balanceOf(address(this));
        ICurvePool_2Token(curvePoolLINK).remove_liquidity_one_coin(bal, 0, 0);

        // Unwrap Compound cTokens.
        CERC20(cCOMP).redeem(IERC20(cCOMP).balanceOf(address(this)));

        // Unwrap xSUSHI
        SushiBar(xSUSHI).leave(IERC20(xSUSHI).balanceOf(address(this)));
    }

    /// @notice Execute swaps.
    /// @param swaps A list of swaps (v2 or v3) encoded in structs.
    /// @param deadline A deadline for the swaps to happen.
    function execSwaps(Swap[] calldata swaps, uint256 deadline) external {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();
        if (deadline <= block.timestamp) revert DeadlineReached();

        for (uint256 i; i < swaps.length; ) {
            if (swaps[i].v3) {
                _swapV3GivenIn(swaps[i]);
            } else {
                _swapV2GivenIn(swaps[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Bake it all.
    /// @param amountOut Amount to bake.
    /// @param maxAmountIn Maximum amount of WETH to use.
    /// @param deadline A deadline for the bake to occour.
    /// @param approvals Indicates if approvals for underlyings should be done.
    /// @param swaps Swaps from WETH to underlyings.
    function bake(
        uint256 amountOut,
        uint256 maxAmountIn,
        uint256 deadline,
        bool approvals,
        Swap[] calldata swaps
    ) external payable {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();
        if (deadline <= block.timestamp) revert DeadlineReached();

        if (msg.value != 0) {
            // help the bake by sending some ETH
            (bool succ, ) = WETH.call{value: msg.value}("");
            if (!succ) revert();
        }

        uint256 balanceIn = IERC20(WETH).balanceOf(address(this));

        // Execute swaps
        _execSwapsGivenOut(swaps);

        // Execute approvals if needed
        if (approvals) _execApprovalsForBasket();

        // Join DEFI++
        IBasketFacet(DPP).joinPool(amountOut);

        // Check amount used is less than required
        uint256 usedIn = balanceIn - IERC20(WETH).balanceOf(address(this));

        if (usedIn >= maxAmountIn) revert BakeFailed();

        if (msg.value != 0) {
            balanceIn = IERC20(WETH).balanceOf(address(this));
            uint256 refund = (balanceIn >= msg.value) ? msg.value : balanceIn;
            if (refund != 0) IERC20(WETH).transfer(msg.sender, refund);
        }
    }

    /// @notice Settle the migration and broadcast exchange rate.
    function settle(bool finalRate) external {
        if (state != 1) revert NotBaking();
        if (msg.sender != gov) revert NotGovernance();
        if (finalRate) state = 2;

        uint256 dppBalance = IERC20(DPP).balanceOf(address(this)); // DEFI++ balance
        uint256 total = totalDeposits - IERC20(BDI).balanceOf(address(this)); // account for dust
        rate = (dppBalance * 1e18) / total; // compute rate
    }

    /*///////////////////////////////////////////////////////////////
                            Internal
    ///////////////////////////////////////////////////////////////*/

    function _execSwapsGivenOut(Swap[] calldata swaps) internal {
        for (uint256 i; i < swaps.length; ) {
            if (swaps[i].v3) {
                _swapV3GivenOut(swaps[i]);
            } else {
                _swapV2GivenOut(swaps[i]);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _execApprovalsForBasket() internal {
        address[] memory tokens = IBasketFacet(DPP).getTokens();

        for (uint256 i = 0; i < tokens.length; ) {
            IERC20(tokens[i]).approve(DPP, type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    function _swapV2GivenIn(Swap memory swap) internal {
        // decode data
        (
            address router,
            address[] memory path,
            uint256 amountOut,
            uint256 amountInMin
        ) = abi.decode(swap.data, (address, address[], uint256, uint256));

        IERC20 tokenIn = IERC20(path[0]);
        if (tokenIn.allowance(address(this), router) <= amountOut) {
            tokenIn.approve(router, type(uint256).max);
        }

        IUniswapV2Router01(router).swapExactTokensForTokens(
            amountOut,
            amountInMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapV2GivenOut(Swap memory swap) internal {
        // decode data
        (
            address router,
            address[] memory path,
            uint256 amountOut,
            uint256 amountInMax
        ) = abi.decode(swap.data, (address, address[], uint256, uint256));

        IERC20 tokenIn = IERC20(path[0]);
        if (tokenIn.allowance(address(this), router) <= amountInMax) {
            tokenIn.approve(router, type(uint256).max);
        }

        IUniswapV2Router01(router).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapV3GivenIn(Swap memory swap) internal {
        // decode data
        (
            address router,
            address tokenIn,
            address tokenOut,
            uint24 fee,
            uint256 amountIn,
            uint256 amountOutMin
        ) = abi.decode(
                swap.data,
                (address, address, address, uint24, uint256, uint256)
            );

        if (IERC20(tokenIn).allowance(address(this), router) <= amountIn) {
            IERC20(tokenIn).approve(router, type(uint256).max);
        }

        ISwapRouter.ExactInputSingleParams memory params;
        params.tokenIn = tokenIn;
        params.tokenOut = tokenOut;
        params.fee = fee;
        params.recipient = address(this);
        params.deadline = block.timestamp;
        params.amountIn = amountIn;
        params.amountOutMinimum = amountOutMin;

        ISwapRouter(router).exactInputSingle(params);
    }

    function _swapV3GivenOut(Swap memory swap) internal {
        // decode data
        (
            address router,
            address tokenIn,
            address tokenOut,
            uint24 fee,
            uint256 amountOut,
            uint256 amountInMax
        ) = abi.decode(
                swap.data,
                (address, address, address, uint24, uint256, uint256)
            );

        if (IERC20(tokenIn).allowance(address(this), router) <= amountInMax) {
            IERC20(tokenIn).approve(router, type(uint256).max);
        }

        ISwapRouter.ExactOutputSingleParams memory params;
        params.tokenIn = tokenIn;
        params.tokenOut = tokenOut;
        params.fee = fee;
        params.recipient = address(this);
        params.deadline = block.timestamp;
        params.amountOut = amountOut;
        params.amountInMaximum = amountInMax;

        ISwapRouter(router).exactOutputSingle(params);
    }

    /*///////////////////////////////////////////////////////////////
                            Receive
    ///////////////////////////////////////////////////////////////*/

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

abstract contract CERC20 {
    function mint(uint256) external virtual returns (uint256);

    function borrow(uint256) external virtual returns (uint256);

    function redeem(uint256) external virtual returns (uint256);

    function underlying() external view virtual returns (address);

    function totalBorrows() external view virtual returns (uint256);

    function totalFuseFees() external view virtual returns (uint256);

    function repayBorrow(uint256) external virtual returns (uint256);

    function totalReserves() external view virtual returns (uint256);

    function exchangeRateCurrent() external virtual returns (uint256);

    function totalAdminFees() external view virtual returns (uint256);

    function fuseFeeMantissa() external view virtual returns (uint256);

    function adminFeeMantissa() external view virtual returns (uint256);

    function exchangeRateStored() external view virtual returns (uint256);

    function accrualBlockNumber() external view virtual returns (uint256);

    function redeemUnderlying(uint256) external virtual returns (uint256);

    function balanceOfUnderlying(address) external virtual returns (uint256);

    function reserveFactorMantissa() external view virtual returns (uint256);

    function borrowBalanceCurrent(address) external virtual returns (uint256);

    function interestRateModel() external view virtual returns (address);

    function initialExchangeRateMantissa()
        external
        view
        virtual
        returns (uint256);

    function repayBorrowBehalf(address, uint256)
        external
        virtual
        returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IRecipe {
    function bake(
        address _inputToken,
        address _outputToken,
        uint256 _maxInput,
        bytes memory _data
    ) external returns (uint256 inputAmountUsed, uint256 outputAmount);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface SushiBar {
    // Enter the bar. Pay some SUSHIs. Earn some shares.
    function enter(uint256 _amount) external;

    // Leave the bar. Claim back your SUSHIs.
    function leave(uint256 _share) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface VaultAPI {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient)
        external
        returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20} from "IERC20.sol";

interface IBasketFacet is IERC20 {
    event TokenAdded(address indexed _token);
    event TokenRemoved(address indexed _token);
    event EntryFeeSet(uint256 fee);
    event ExitFeeSet(uint256 fee);
    event AnnualizedFeeSet(uint256 fee);
    event FeeBeneficiarySet(address indexed beneficiary);
    event EntryFeeBeneficiaryShareSet(uint256 share);
    event ExitFeeBeneficiaryShareSet(uint256 share);

    event PoolJoined(address indexed who, uint256 amount);
    event PoolExited(address indexed who, uint256 amount);
    event FeeCharged(uint256 amount);
    event LockSet(uint256 lockBlock);
    event CapSet(uint256 cap);

    /** 
        @notice Sets entry fee paid when minting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setEntryFee(uint256 _fee) external;

    /**
        @notice Get the entry fee
        @return Current entry fee
    */
    function getEntryFee() external view returns (uint256);

    /**
        @notice Set the exit fee paid when exiting
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setExitFee(uint256 _fee) external;

    /**
        @notice Get the exit fee
        @return Current exit fee
    */
    function getExitFee() external view returns (uint256);

    /**
        @notice Set the annualized fee. Often referred to as streaming fee
        @param _fee Amount of fee. 1e18 == 100%, capped at 10%
    */
    function setAnnualizedFee(uint256 _fee) external;

    /**
        @notice Get the annualized fee.
        @return Current annualized fee.
    */
    function getAnnualizedFee() external view returns (uint256);

    /**
        @notice Set the address receiving the fees.
    */
    function setFeeBeneficiary(address _beneficiary) external;

    /**
        @notice Get the fee benificiary
        @return The current fee beneficiary
    */
    function getFeeBeneficiary() external view returns (address);

    /**
        @notice Set the fee beneficiaries share of the entry fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100% 
    */
    function setEntryFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the entry fee beneficiary share
        @return Feeshare amount
    */
    function getEntryFeeBeneficiaryShare() external view returns (uint256);

    /**
        @notice Set the fee beneficiaries share of the exit fee
        @notice _share Share of the fee. 1e18 == 100%. Capped at 100% 
    */
    function setExitFeeBeneficiaryShare(uint256 _share) external;

    /**
        @notice Get the exit fee beneficiary share
        @return Feeshare amount
    */
    function getExitFeeBeneficiaryShare() external view returns (uint256);

    /**
        @notice Calculate the oustanding annualized fee
        @return Amount of pool tokens to be minted to charge the annualized fee
    */
    function calcOutStandingAnnualizedFee() external view returns (uint256);

    /**
        @notice Charges the annualized fee
    */
    function chargeOutstandingAnnualizedFee() external;

    /**
        @notice Pulls underlying from caller and mints the pool token
        @param _amount Amount of pool tokens to mint
    */
    function joinPool(uint256 _amount) external;

    /**
        @notice Burns pool tokens from the caller and returns underlying assets
    */
    function exitPool(uint256 _amount) external;

    /**
        @notice Get if the pool is locked or not. (not accepting exit and entry)
        @return Boolean indicating if the pool is locked
    */
    function getLock() external view returns (bool);

    /**
        @notice Get the block until which the pool is locked
        @return The lock block
    */
    function getLockBlock() external view returns (uint256);

    /**
        @notice Set the lock block
        @param _lock Block height of the lock
    */
    function setLock(uint256 _lock) external;

    /**
        @notice Get the maximum of pool tokens that can be minted
        @return Cap
    */
    function getCap() external view returns (uint256);

    /**
        @notice Set the maximum of pool tokens that can be minted
        @param _maxCap Max cap 
    */
    function setCap(uint256 _maxCap) external;

    /**
        @notice Get the amount of tokens owned by the pool
        @param _token Addres of the token
        @return Amount owned by the contract
    */
    function balance(address _token) external view returns (uint256);

    /**
        @notice Get the tokens in the pool
        @return Array of tokens in the pool
    */
    function getTokens() external view returns (address[] memory);

    /**
        @notice Add a token to the pool. Should have at least a balance of 10**6
        @param _token Address of the token to add
    */
    function addToken(address _token) external;

    /**
        @notice Removes a token from the pool
        @param _token Address of the token to remove
    */
    function removeToken(address _token) external;

    /**
        @notice Checks if a token was added to the pool
        @param _token address of the token
        @return If token is in the pool or not
    */
    function getTokenInPool(address _token) external view returns (bool);

    /**
        @notice Calculate the amounts of underlying needed to mint that pool amount.
        @param _amount Amount of pool tokens to mint
        @return tokens Tokens needed
        @return amounts Amounts of underlying needed
    */
    function calcTokensForAmount(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);

    /**
        @notice Calculate the amounts of underlying to receive when burning that pool amount
        @param _amount Amount of pool tokens to burn
        @return tokens Tokens returned
        @return amounts Amounts of underlying returned
    */
    function calcTokensForAmountExit(uint256 _amount)
        external
        view
        returns (address[] memory tokens, uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IBasketLogic {
    function getAssetsAndBalances()
        external
        view
        returns (address[] memory, uint256[] memory);

    /// @notice Gets the amount of assets backing each Basket token
    /// @return (the addresses of the assets,
    ///          the amount of backing 1 Basket token)
    function getOne()
        external
        view
        returns (address[] memory, uint256[] memory);

    /// @notice Gets the fees and the fee recipient
    /// @return (mint fee, burn fee, recipient)
    function getFees()
        external
        view
        returns (
            uint256,
            uint256,
            address
        );

    // **** Mint/Burn functionality **** //

    /// @notice Mints a new Basket token
    /// @param  _amountOut  Amount of Basket tokens to mint
    function mint(uint256 _amountOut) external;

    /// @notice Previews the corresponding assets and amount required to mint `_amountOut` Basket tokens
    /// @param  _amountOut  Amount of Basket tokens to mint
    function viewMint(uint256 _amountOut)
        external
        view
        returns (uint256[] memory _amountsIn);

    /// @notice Burns the basket token and retrieves
    /// @param  _amount  Amount of Basket tokens to burn
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ICurvePool_2Token {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        payable;

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] calldata amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external payable;

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}