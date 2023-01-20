// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "SafeERC20.sol";
import "ERC20.sol";
import "IGenericVault.sol";
import "ICurveV2Pool.sol";
import "ICurveFactoryPool.sol";
import "ICurveTriCrypto.sol";
import "ICVXLocker.sol";
import "IUniV2Router.sol";
import "ITriPool.sol";
import "IBooster.sol";
import "IRewards.sol";
import "IUnionVault.sol";

contract stkCvxCrvZaps {
    using SafeERC20 for IERC20;

    address public immutable vault;

    address private constant CONVEX_LOCKER =
        0x72a19342e8F1838460eBFCCEf09F6585e32db86E;
    address private constant CVXCRV_STAKING_CONTRACT =
        0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e;
    address private constant CURVE_CRV_ETH_POOL =
        0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address private constant CURVE_CVX_ETH_POOL =
        0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4;
    address private constant CURVE_CVXCRV_CRV_POOL =
        0x9D0464996170c6B9e75eED71c68B99dDEDf279e8;

    address private constant CRV_TOKEN =
        0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant CVXCRV_TOKEN =
        0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;
    address private constant CVX_TOKEN =
        0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private constant UNION_CRV =
        0x83507cc8C8B67Ed48BADD1F59F684D5d02884C81;
    address private constant WETH_TOKEN =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant USDT_TOKEN =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant TRICRYPTO =
        0xD51a44d3FaE010294C616388b506AcdA1bfAAE46;
    address private constant TRIPOOL =
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address private constant TRICRV =
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address private constant BOOSTER =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address private constant CONVEX_TRIPOOL_TOKEN =
        0x30D9410ED1D5DA1F6C8391af5338C93ab8d4035C;
    address private constant CONVEX_TRIPOOL_REWARDS =
        0x689440f2Ff927E1f24c72F1087E1FAF471eCe1c8;

    uint256 private constant CRVETH_ETH_INDEX = 0;
    uint256 private constant CRVETH_CRV_INDEX = 1;
    int128 private constant CVXCRV_CRV_INDEX = 0;
    int128 private constant CVXCRV_CVXCRV_INDEX = 1;
    uint256 private constant CVXETH_ETH_INDEX = 0;
    uint256 private constant CVXETH_CVX_INDEX = 1;

    ICurveV2Pool cvxEthSwap = ICurveV2Pool(CURVE_CVX_ETH_POOL);
    ICurveV2Pool crvEthSwap = ICurveV2Pool(CURVE_CRV_ETH_POOL);
    ITriPool triPool = ITriPool(TRIPOOL);
    IBooster booster = IBooster(BOOSTER);
    IRewards triPoolRewards = IRewards(CONVEX_TRIPOOL_REWARDS);
    ICurveFactoryPool crvCvxCrvSwap = ICurveFactoryPool(CURVE_CVXCRV_CRV_POOL);
    ICurveTriCrypto triCryptoSwap = ICurveTriCrypto(TRICRYPTO);
    ICVXLocker locker = ICVXLocker(CONVEX_LOCKER);

    constructor(address _vault) {
        vault = _vault;
    }

    /// @notice Set approvals for the contracts used when swapping & staking
    function setApprovals() external {
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, type(uint256).max);

        IERC20(CVXCRV_TOKEN).safeApprove(CVXCRV_STAKING_CONTRACT, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            CVXCRV_STAKING_CONTRACT,
            type(uint256).max
        );

        IERC20(CVXCRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(
            CURVE_CVXCRV_CRV_POOL,
            type(uint256).max
        );

        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CVXCRV_CRV_POOL, type(uint256).max);

        IERC20(TRICRV).safeApprove(BOOSTER, 0);
        IERC20(TRICRV).safeApprove(BOOSTER, type(uint256).max);

        IERC20(USDT_TOKEN).safeApprove(TRIPOOL, 0);
        IERC20(USDT_TOKEN).safeApprove(TRIPOOL, type(uint256).max);

        IERC20(CONVEX_TRIPOOL_TOKEN).safeApprove(CONVEX_TRIPOOL_REWARDS, 0);
        IERC20(CONVEX_TRIPOOL_TOKEN).safeApprove(
            CONVEX_TRIPOOL_REWARDS,
            type(uint256).max
        );

        IERC20(CVXCRV_TOKEN).safeApprove(vault, 0);
        IERC20(CVXCRV_TOKEN).safeApprove(vault, type(uint256).max);

        IERC20(CVX_TOKEN).safeApprove(CONVEX_LOCKER, 0);
        IERC20(CVX_TOKEN).safeApprove(CONVEX_LOCKER, type(uint256).max);

        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, 0);
        IERC20(CRV_TOKEN).safeApprove(CURVE_CRV_ETH_POOL, type(uint256).max);
    }

    /// @notice Swap CRV for cvxCRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _crvToCvxCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CRV_INDEX,
                CVXCRV_CVXCRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap cvxCRV for CRV on Curve
    /// @param amount - amount to swap
    /// @param recipient - where swapped tokens will be sent to
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _cvxCrvToCrv(
        uint256 amount,
        address recipient,
        uint256 minAmountOut
    ) internal returns (uint256) {
        return
            crvCvxCrvSwap.exchange(
                CVXCRV_CVXCRV_INDEX,
                CVXCRV_CRV_INDEX,
                amount,
                minAmountOut,
                recipient
            );
    }

    /// @notice Swap CRV for native ETH on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of ETH obtained after the swap
    function _crvToEth(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: 0}(
                CRVETH_CRV_INDEX,
                CRVETH_ETH_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CRV on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCrv(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            crvEthSwap.exchange_underlying{value: amount}(
                CRVETH_ETH_INDEX,
                CRVETH_CRV_INDEX,
                amount,
                minAmountOut
            );
    }

    /// @notice Swap native ETH for CVX on Curve
    /// @param amount - amount to swap
    /// @param minAmountOut - minimum expected amount of output tokens
    /// @return amount of CRV obtained after the swap
    function _ethToCvx(uint256 amount, uint256 minAmountOut)
        internal
        returns (uint256)
    {
        return
            cvxEthSwap.exchange_underlying{value: amount}(
                CVXETH_ETH_INDEX,
                CVXETH_CVX_INDEX,
                amount,
                minAmountOut
            );
    }

    /////////////////////////////////////////////////////////////

    /// @notice Deposit into the pounder from ETH
    /// @param minAmountOut - min amount of lp tokens expected
    /// @param to - address to stake on behalf of
    function depositFromEth(uint256 minAmountOut, address to)
        external
        payable
        notToZeroAddress(to)
    {
        require(msg.value > 0, "cheap");
        _depositFromEth(msg.value, minAmountOut, to);
    }

    /// @notice Internal function to deposit ETH to the pounder
    /// @param amount - amount of ETH
    /// @param minAmountOut - min amount of lp tokens expected
    /// @param to - address to stake on behalf of
    function _depositFromEth(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) internal {
        uint256 _crvAmount = _ethToCrv(amount, 0);
        _crvToCvxCrv(_crvAmount, address(this), minAmountOut);
        IGenericVault(vault).depositAll(to);
    }

    /// @notice Deposit into the pounder from CRV
    /// @param amount - amount of CRV
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param to - address to stake on behalf of
    function depositFromCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) {
        IERC20(CRV_TOKEN).safeTransferFrom(msg.sender, address(this), amount);
        _crvToCvxCrv(amount, address(this), minAmountOut);
        IGenericVault(vault).depositAll(to);
    }

    /// @notice Deposit into the pounder from legacy uCRV
    /// @param amount - amount of uCRV
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param to - address to stake on behalf of
    function depositFromUCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external notToZeroAddress(to) {
        IERC20(UNION_CRV).safeTransferFrom(msg.sender, address(this), amount);
        IUnionVault(UNION_CRV).withdrawAll(address(this));
        IGenericVault(vault).depositAll(to);
    }

    /// @notice Deposit into the pounder from any token via Uni interface
    /// @notice Use at your own risk
    /// @dev Zap contract needs approval for spending of inputToken
    /// @param amount - min amount of input token
    /// @param minAmountOut - min amount of cvxCRV expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param inputToken - address of the token to swap from, needs to have an ETH pair on router used
    /// @param to - address to stake on behalf of
    function depositViaUniV2EthPair(
        uint256 amount,
        uint256 minAmountOut,
        address router,
        address inputToken,
        address to
    ) external notToZeroAddress(to) {
        require(router != address(0));

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), amount);
        address[] memory _path = new address[](2);
        _path[0] = inputToken;
        _path[1] = WETH_TOKEN;

        IERC20(inputToken).safeApprove(router, 0);
        IERC20(inputToken).safeApprove(router, amount);

        IUniV2Router(router).swapExactTokensForETH(
            amount,
            1,
            _path,
            address(this),
            block.timestamp + 1
        );
        _depositFromEth(address(this).balance, minAmountOut, to);
    }

    /// @notice Retrieves a user's vault shares and withdraw all
    /// @param _amount - amount of shares to retrieve
    /// @return amount withdrawn
    function _claimAndWithdraw(uint256 _amount) internal returns (uint256) {
        IERC20(vault).safeTransferFrom(msg.sender, address(this), _amount);
        return IGenericVault(vault).withdrawAll(address(this));
    }

    /// @notice Claim as native ETH
    /// @param amount - amount to withdraw
    /// @param minAmountOut - minimum amount of ETH expected
    /// @param to - address to send ETH to
    /// @return amount of ETH withdrawn
    function claimFromVaultAsEth(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) returns (uint256) {
        uint256 _ethAmount = _claimAsEth(amount, minAmountOut);
        (bool success, ) = to.call{value: _ethAmount}("");
        require(success, "ETH transfer failed");
        return _ethAmount;
    }

    /// @notice Withdraw as native CRV
    /// @param amount - amount to withdraw
    /// @param to - address that will receive the CRV
    /// @param minAmountOut - min amount of  CRV expected
    /// @return amount of CRV withdrawn
    function claimFromVaultAsCrv(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public returns (uint256) {
        uint256 _cvxCrvAmount = _claimAndWithdraw(amount);
        return _cvxCrvToCrv(_cvxCrvAmount, to, minAmountOut);
    }

    /// @notice Withdraw as native ETH (internal)
    /// @param _amount - amount to withdraw
    /// @param _minAmountOut - min amount of ETH expected
    /// @return amount of ETH withdrawn
    function _claimAsEth(uint256 _amount, uint256 _minAmountOut)
        internal
        returns (uint256)
    {
        uint256 _crvAmount = claimFromVaultAsCrv(_amount, 0, address(this));
        return _crvToEth(_crvAmount, _minAmountOut);
    }

    /// @notice Claim to any token via a univ2 router
    /// @notice Use at your own risk
    /// @param amount - amount of uFXS to unstake
    /// @param minAmountOut - min amount of output token expected
    /// @param router - address of the router to use. e.g. 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F for Sushi
    /// @param outputToken - address of the token to swap to
    /// @param to - address of the final recipient of the swapped tokens
    function claimFromVaultViaUniV2EthPair(
        uint256 amount,
        uint256 minAmountOut,
        address router,
        address outputToken,
        address to
    ) public notToZeroAddress(to) {
        require(router != address(0));
        _claimAsEth(amount, 0);
        address[] memory _path = new address[](2);
        _path[0] = WETH_TOKEN;
        _path[1] = outputToken;
        IUniV2Router(router).swapExactETHForTokens{
            value: address(this).balance
        }(minAmountOut, _path, to, block.timestamp + 1);
    }

    /// @notice Claim as USDT via Tricrypto
    /// @param amount - the amount of uFXS to unstake
    /// @param minAmountOut - the min expected amount of USDT to receive
    /// @param to - the adress that will receive the USDT
    /// @return amount of USDT obtained
    function claimFromVaultAsUsdt(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) returns (uint256) {
        uint256 _ethAmount = claimFromVaultAsEth(amount, 0, address(this));
        _swapEthToUsdt(_ethAmount, minAmountOut);
        uint256 _usdtAmount = IERC20(USDT_TOKEN).balanceOf(address(this));
        IERC20(USDT_TOKEN).safeTransfer(to, _usdtAmount);
        return _usdtAmount;
    }

    /// @notice swap ETH to USDT via Curve's tricrypto
    /// @param amount - the amount of ETH to swap
    /// @param minAmountOut - the minimum amount expected
    function _swapEthToUsdt(uint256 amount, uint256 minAmountOut) internal {
        triCryptoSwap.exchange{value: amount}(
            2, // ETH
            0, // USDT
            amount,
            minAmountOut,
            true
        );
    }

    /// @notice Unstake from the Pounder to stables and stake on 3pool convex for yield
    /// @param amount - amount of uCRV to unstake
    /// @param minAmountOut - minimum amount of 3CRV (NOT USDT!)
    /// @param to - address on behalf of which to stake
    function claimFromVaultAndStakeIn3PoolConvex(
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) public notToZeroAddress(to) {
        // claim as USDT
        uint256 _usdtAmount = claimFromVaultAsUsdt(amount, 0, address(this));
        // add USDT to Tripool
        triPool.add_liquidity([0, 0, _usdtAmount], minAmountOut);
        // deposit on Convex
        booster.depositAll(9, false);
        // stake on behalf of user
        triPoolRewards.stakeFor(
            to,
            IERC20(CONVEX_TRIPOOL_TOKEN).balanceOf(address(this))
        );
    }

    /// @notice Claim as CVX via CurveCVX
    /// @param amount - the amount of uFXS to unstake
    /// @param minAmountOut - the min expected amount of USDT to receive
    /// @param to - the adress that will receive the CVX
    /// @param lock - whether to lock the CVX or not
    /// @return amount of CVX obtained
    function claimFromVaultAsCvx(
        uint256 amount,
        uint256 minAmountOut,
        address to,
        bool lock
    ) public notToZeroAddress(to) returns (uint256) {
        uint256 _ethAmount = _claimAsEth(amount, 0);
        uint256 _cvxAmount = _ethToCvx(_ethAmount, minAmountOut);
        if (lock) {
            locker.lock(to, _cvxAmount, 0);
        } else {
            IERC20(CVX_TOKEN).safeTransfer(to, _cvxAmount);
        }
        return _cvxAmount;
    }

    modifier notToZeroAddress(address _to) {
        require(_to != address(0), "Invalid address!");
        _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IGenericVault {
    function withdraw(address _to, uint256 _shares)
        external
        returns (uint256 withdrawn);

    function withdrawAll(address _to) external returns (uint256 withdrawn);

    function depositAll(address _to) external returns (uint256 _shares);

    function deposit(address _to, uint256 _amount)
        external
        returns (uint256 _shares);

    function harvest() external;

    function balanceOfUnderlying(address user)
        external
        view
        returns (uint256 amount);

    function totalUnderlying() external view returns (uint256 total);

    function totalSupply() external view returns (uint256 total);

    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function platform() external view returns (address);

    function setPlatform(address _platform) external;

    function setPlatformFee(uint256 _fee) external;

    function setCallIncentive(uint256 _incentive) external;

    function setWithdrawalPenalty(uint256 _penalty) external;

    function setApprovals() external;

    function callIncentive() external view returns (uint256);

    function platformFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurveV2Pool {
    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts)
        external
        view
        returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function lp_price() external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external payable returns (uint256);

    function price_oracle() external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurveFactoryPool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_balances() external view returns (uint256[2] memory);

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy,
        address _receiver
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICurveTriCrypto {
    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth
    ) external payable;

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function price_oracle(uint256 k) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICVXLocker {
    function lock(
        address _account,
        uint256 _amount,
        uint256 _spendRatio
    ) external;

    function balances(address _user)
        external
        view
        returns (
            uint112 locked,
            uint112 boosted,
            uint32 nextUnlockIndex
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniV2Router {
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ITriPool {
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external;

    function get_virtual_price() external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRewards {
    function balanceOf(address) external view returns (uint256);

    function stake(address, uint256) external;

    function stakeFor(address, uint256) external;

    function withdraw(address, uint256) external;

    function exit(address) external;

    function getReward(address) external;

    function queueNewRewards(uint256) external;

    function notifyRewardAmount(uint256) external;

    function addExtraReward(address) external;

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function earned(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUnionVault {
    enum Option {
        Claim,
        ClaimAsETH,
        ClaimAsCRV,
        ClaimAsCVX,
        ClaimAndStake
    }

    function withdraw(address _to, uint256 _shares)
        external
        returns (uint256 withdrawn);

    function withdrawAll(address _to) external returns (uint256 withdrawn);

    function withdrawAs(
        address _to,
        uint256 _shares,
        Option option
    ) external;

    function withdrawAs(
        address _to,
        uint256 _shares,
        Option option,
        uint256 minAmountOut
    ) external;

    function withdrawAllAs(address _to, Option option) external;

    function withdrawAllAs(
        address _to,
        Option option,
        uint256 minAmountOut
    ) external;

    function depositAll(address _to) external returns (uint256 _shares);

    function deposit(address _to, uint256 _amount)
        external
        returns (uint256 _shares);

    function harvest() external;

    function balanceOfUnderlying(address user)
        external
        view
        returns (uint256 amount);

    function outstanding3CrvRewards() external view returns (uint256 total);

    function outstandingCvxRewards() external view returns (uint256 total);

    function outstandingCrvRewards() external view returns (uint256 total);

    function totalUnderlying() external view returns (uint256 total);

    function underlying() external view returns (address);

    function setPlatform(address _platform) external;

    function setPlatformFee(uint256 _fee) external;

    function setCallIncentive(uint256 _incentive) external;

    function setWithdrawalPenalty(uint256 _penalty) external;

    function withdrawalPenalty() external view returns (uint256);

    function setApprovals() external;
}