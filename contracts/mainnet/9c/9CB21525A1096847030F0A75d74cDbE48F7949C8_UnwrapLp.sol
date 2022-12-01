// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/aave/IAaveLendingPoolV2.sol";
import "../interfaces/curve/ICurvePool.sol";
import "../interfaces/stargate/IStargateRouter.sol";
import "../interfaces/compound/ICToken.sol";
import "../interfaces/IUnwrapLp.sol";

contract UnwrapLp is Initializable, IUnwrapLp {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant VERSION = 3;

    // Regular assets
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // Stargate aTokens
    address public constant aUSDT = 0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811;

    // Stargate sTokens
    address public constant sUSDC = 0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56;
    address public constant sUSDT = 0x38EA452219524Bb87e18dE1C24D3bB59510BD783;

    // Compound cTokens
    address public constant cUSDT = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;
    address public constant cUSDC = 0x39AA39c021dfbaE8faC545936693aC917d5E7563;

    // Curve lp tokens
    address public constant CurveTricrypto2Lp = 0xc4AD29ba4B3c580e6D59105FFf484999997675Ff;
    address public constant Curve3PoolLp = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant CurveTUSDLp = 0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address public constant CurveCompoundLp = 0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2;
    address public constant CurveFraxUSDLp = 0x3175Df0976dFA876431C2E9eE6Bc45b65d3473CC;
    address public constant CurveBUSDv2Lp = 0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address public constant CurveAaveLp = 0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;

    // Curve pools
    address public constant CurveTricrypto2Pool = 0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address public constant Curve3Pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address public constant CurveTUSDPool = 0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1;
    address public constant CurveCompoundPool = 0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56;
    address public constant CurveFraxUSDPool = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
    address public constant CurveBUSDv2Pool = 0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a;
    address public constant CurveAavePool = 0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;

    // Platforms
    address public constant AaveLendingPool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address public constant ConvexBooster = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public constant StargateRouter = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;

    function initialize() public initializer {
        // silent
    }

    /**
     * @notice unwrap
     * @param assetLp assetLp
     * @param amount amount
     * @return asset
     * @return receivedAmount
     **/
    function unwrap(address assetLp, uint256 amount) external override returns (address, uint256) {
        IERC20Upgradeable(assetLp).safeTransferFrom(msg.sender, address(this), amount);

        if (assetLp == CurveTricrypto2Lp) {
            return unwrapCurveTriCrypto2(amount);
        }

        else if (assetLp == Curve3PoolLp) {
            return unwrapCurve3Pool(amount);
        }

        else if (assetLp == CurveTUSDLp) {
            return unwrapCurveTUSD(amount);
        }

        else if (assetLp == CurveCompoundLp) {
            return unwrapCurveCompound(amount);
        }

        else if (assetLp == CurveFraxUSDLp) {
            return unwrapCurveFraxUSD(amount);
        }

        else if (assetLp == CurveBUSDv2Lp) {
            return unwrapCurveBUSDv2(amount);
        }

        else if (assetLp == CurveAaveLp) {
            return unwrapCurveAave(amount);
        }

        else if (assetLp == sUSDC) {
            return unwrapSUSDC(amount);
        }

        else if (assetLp == sUSDT) {
            return unwrapSUSDT(amount);
        }

        else {
            revert("pool not supported yet");
        }
    }

    function unwrapCurveTriCrypto2(uint256 amount) internal returns (address, uint256) {
        // only want USDT from USDT+BTC+WETH LP
        uint256[3] memory min_amounts = [uint256(100), 0, 0];
        ICurvePool(CurveTricrypto2Pool).remove_liquidity(amount, min_amounts);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurve3Pool(uint256 amount) internal returns (address, uint256) {
        // only want USDT from DAI+USDC+USDT LP
        uint256[3] memory min_amounts = [0, 0, uint256(100)];
        ICurvePool(Curve3Pool).remove_liquidity(amount, min_amounts);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurveTUSD(uint256 amount) internal returns (address, uint256) {
        // only want 3CRV from tUSDT/3CRV LP
        uint256[2] memory min_amounts = [0, uint256(100)];
        ICurvePool(CurveTUSDPool).remove_liquidity(amount, min_amounts);

        uint256 receivedCrv3Pool = IERC20Upgradeable(Curve3PoolLp).balanceOf(address(this));

        // only want USDT from DAI/USDC/USDT LP (3CRV)
        uint256[3] memory min_amounts_3crv = [0, 0, uint256(100)];
        ICurvePool(Curve3Pool).remove_liquidity(receivedCrv3Pool, min_amounts_3crv);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurveFraxUSD(uint256 amount) internal returns (address, uint256) {
        // only want USDC from frax/USDC LP
        uint256[2] memory min_amounts = [0, uint256(100)];
        ICurvePool(CurveFraxUSDPool).remove_liquidity(amount, min_amounts);

        uint256 receivedAmount = IERC20Upgradeable(USDC).balanceOf(address(this));

        IERC20Upgradeable(USDC).safeTransfer(msg.sender, receivedAmount);

        return (USDC, receivedAmount);
    }

    function unwrapCurveBUSDv2(uint256 amount) internal returns (address, uint256) {
        // only want 3Crv from BUSD/3CRV LP
        uint256[2] memory min_amounts = [uint256(100), 0];
        ICurvePool(CurveBUSDv2Pool).remove_liquidity(amount, min_amounts);

        uint256 receivedCrv3Pool = IERC20Upgradeable(Curve3PoolLp).balanceOf(address(this));

        // only want USDT from DAI/USDC/USDT LP (3CRV)
        uint256[3] memory min_amounts_3crv = [0, 0, uint256(100)];
        ICurvePool(Curve3Pool).remove_liquidity(receivedCrv3Pool, min_amounts_3crv);

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapCurveCompound(uint256 amount) internal returns (address, uint256) {
        // only want cUSDC from cDAI/cUSDC LP
        uint256[2] memory min_amounts = [0, uint256(100)];
        ICurvePool(CurveCompoundPool).remove_liquidity(amount, min_amounts);

        // unwrap USDC from cUSDC
        uint receivedCTokenBalance = uint(ICToken(cUSDC).balanceOf(address(this)));
        ICToken(cUSDC).redeem(receivedCTokenBalance);

        uint256 receivedAmount = IERC20Upgradeable(USDC).balanceOf(address(this));

        IERC20Upgradeable(USDC).safeTransfer(msg.sender, receivedAmount);

        return (USDC, receivedAmount);
    }

    function unwrapCurveAave(uint256 amount) internal returns (address, uint256) {
        // only want aUSDT from aDAI/aUSDC/aUSDT LP
        uint256[3] memory min_amounts = [0, 0, uint256(100)];
        ICurvePool(CurveAavePool).remove_liquidity(amount, min_amounts);

        // unwrap USDT from aUSDT
        uint receivedATokenBalance = IERC20Upgradeable(aUSDT).balanceOf(address(this));
        IAaveLendingPoolV2(AaveLendingPool).withdraw(USDT, receivedATokenBalance, address(this));

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this));

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function unwrapSUSDC(uint256 amount) internal returns (address, uint256) {
        uint256 balancePrior = IERC20Upgradeable(USDC).balanceOf(address(this));

        IStargateRouter(StargateRouter).instantRedeemLocal(1, amount, address(this));

        uint256 receivedAmount = IERC20Upgradeable(USDC).balanceOf(address(this)) - balancePrior;

        IERC20Upgradeable(USDC).safeTransfer(msg.sender, receivedAmount);

        return (USDC, receivedAmount);
    }

    function unwrapSUSDT(uint256 amount) internal returns (address, uint256) {
        uint256 balancePrior = IERC20Upgradeable(USDT).balanceOf(address(this));

        IStargateRouter(StargateRouter).instantRedeemLocal(2, amount, address(this));

        uint256 receivedAmount = IERC20Upgradeable(USDT).balanceOf(address(this)) - balancePrior;

        IERC20Upgradeable(USDT).safeTransfer(msg.sender, receivedAmount);

        return (USDT, receivedAmount);
    }

    function getAssetOut(address assetLp) external pure returns (address) {
        if (
            assetLp == CurveTricrypto2Lp ||
            assetLp == Curve3PoolLp ||
            assetLp == CurveTUSDLp ||
            assetLp == CurveBUSDv2Lp ||
            assetLp == CurveAaveLp ||
            assetLp == sUSDT
        ) {
            return USDT;
        }

        else if (
            assetLp == CurveCompoundLp ||
            assetLp == CurveFraxUSDLp ||
            assetLp == sUSDC
        ) {
            return USDC;
        }

        else {
            revert("pool not supported yet");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

// See https://github.com/aave/protocol-v2/blob/master/contracts/protocol/lendingpool/LendingPool.sol
interface IAaveLendingPoolV2 {
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
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface IStargateRouter {
    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;
    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);

    function redeem(uint redeemTokens) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IUnwrapLp {
    function unwrap(address assetLp, uint256 amount) external returns (address, uint256);
    function getAssetOut(address assetIn) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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