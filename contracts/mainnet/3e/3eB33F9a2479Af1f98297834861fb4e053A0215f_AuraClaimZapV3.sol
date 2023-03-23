// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import { AuraMath } from "../utils/AuraMath.sol";
import { ICrvDepositorWrapper } from "../interfaces/ICrvDepositorWrapper.sol";
import { IAuraLocker } from "../interfaces/IAuraLocker.sol";
import { IRewardStaking } from "../interfaces/IRewardStaking.sol";
import { IRewardPool4626 } from "../interfaces/IRewardPool4626.sol";

/**
 * @title   ClaimZap
 * @author  ConvexFinance -> AuraFinance
 * @notice  Claim zap to bundle various reward claims
 * @dev     Claims from all pools, and stakes cvxCrv and CVX if wanted.
 *          v2:
 *           - change exchange to use curve pool
 *           - add getReward(address,token) type
 *           - add option to lock cvx
 *           - add option use all funds in wallet
 *          v3:
 *           - add option to deposit to compounder
 *           - reduce calls to cvxcrv rewards/compounder
 *           - removed enum and option bitshifting
 *           - introduced options struct
 *           - gas optimisation on use all funds balances
 *           - helper functions to reduce code repetition
 */
contract AuraClaimZapV3 {
    using SafeERC20 for IERC20;
    using AuraMath for uint256;

    address public immutable crv;
    address public immutable cvx;
    address public immutable cvxCrv;
    address public immutable crvDepositWrapper;
    address public immutable cvxCrvRewards;
    address public immutable locker;
    address public immutable owner;
    address public immutable compounder;

    /**
     * @dev Claim rewards amounts.
     * - depositCrvMaxAmount    The max amount of CRV to deposit if converting to crvCvx
     * - minAmountOut           The min amount out for crv:cvxCrv swaps if swapping. Set this to zero if you
     *                          want to use CrvDepositor instead of balancer swap
     * - depositCvxMaxAmount    The max amount of CVX to deposit if locking CVX
     * - depositCvxCrvMaxAmount The max amount of CVXCVR to stake.
     */
    struct ClaimRewardsAmounts {
        uint256 depositCrvMaxAmount;
        uint256 minAmountOut;
        uint256 depositCvxMaxAmount;
        uint256 depositCvxCrvMaxAmount;
    }

    /**
     * @dev options.
     * - claimCvxCrv             Flag: claim from the cvxCrv rewards contract
     * - claimLockedCvx          Flag: claim from the cvx locker contract
     * - lockCvxCrv              Flag: pull users cvxCrvBalance ready for locking
     * - lockCrvDeposit          Flag: locks crv rewards as cvxCrv
     * - useAllWalletFunds       Flag: lock rewards and existing balance
     * - useCompounder           Flag: deposit cvxCrv into autocompounder
     * - lockCvx                 Flag: lock cvx rewards in locker
     */
    struct Options {
        bool claimCvxCrv;
        bool claimLockedCvx;
        bool lockCvxCrv;
        bool lockCrvDeposit;
        bool useAllWalletFunds;
        bool useCompounder;
        bool lockCvx;
    }

    /**
     * @param _crv                CRV token (0xD533a949740bb3306d119CC777fa900bA034cd52);
     * @param _cvx                CVX token (0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
     * @param _cvxCrv             cvxCRV token (0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
     * @param _crvDepositWrapper  crvDepositWrapper (0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);
     * @param _cvxCrvRewards      cvxCrvRewards (0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e);
     * @param _locker             vlCVX (0xD18140b4B819b895A3dba5442F959fA44994AF50);
     * @param _compounder         cvxCrv autocompounder vault
     */
    constructor(
        address _crv,
        address _cvx,
        address _cvxCrv,
        address _crvDepositWrapper,
        address _cvxCrvRewards,
        address _locker,
        address _compounder
    ) {
        crv = _crv;
        cvx = _cvx;
        cvxCrv = _cvxCrv;
        crvDepositWrapper = _crvDepositWrapper;
        cvxCrvRewards = _cvxCrvRewards;
        locker = _locker;
        owner = msg.sender;
        compounder = _compounder;
    }

    /**
     * @notice Returns meta data of contract.
     */
    function getName() external pure returns (string memory) {
        return "ClaimZap V3.0";
    }

    /**
     * @notice Approve spending of:
     *          crv     -> crvDepositor
     *          cvxCrv  -> cvxCrvRewards
     *          cvxCrv  -> Compounder
     *          cvx     -> Locker
     */
    function setApprovals() external {
        require(msg.sender == owner, "!auth");
        _approveToken(crv, crvDepositWrapper);
        _approveToken(cvxCrv, cvxCrvRewards);
        _approveToken(cvxCrv, compounder);
        _approveToken(cvx, locker);
    }

    /**
     * @notice Allows a spender to spend a token
     * @param _token     Token that will be spend
     * @param _spender   Address that will be spending
     */
    function _approveToken(address _token, address _spender) internal {
        IERC20(_token).safeApprove(address(_spender), 0);
        IERC20(_token).safeApprove(address(_spender), type(uint256).max);
    }

    /**
     * @notice Claim all the rewards
     * @param rewardContracts        Array of addresses for LP token rewards
     * @param extraRewardContracts   Array of addresses for extra rewards
     * @param tokenRewardContracts   Array of addresses for token rewards e.g vlCvxExtraRewardDistribution
     * @param tokenRewardTokens      Array of token reward addresses to use with tokenRewardContracts
     * @param amounts                Claim rewards amounts.
     * @param options                Claim options
     */
    function claimRewards(
        address[] calldata rewardContracts,
        address[] calldata extraRewardContracts,
        address[] calldata tokenRewardContracts,
        address[] calldata tokenRewardTokens,
        ClaimRewardsAmounts calldata amounts,
        Options calldata options
    ) external {
        require(tokenRewardContracts.length == tokenRewardTokens.length, "!parity");

        //Read balances prior to reward claims only if required
        uint256 crvBalance;
        uint256 cvxBalance;
        uint256 cvxCrvBalance;
        if (!options.useAllWalletFunds && _callRelockRewards(options)) {
            crvBalance = IERC20(crv).balanceOf(msg.sender);
            cvxBalance = IERC20(cvx).balanceOf(msg.sender);
            cvxCrvBalance = IERC20(cvxCrv).balanceOf(msg.sender);
        }

        //claim from main curve LP pools
        for (uint256 i = 0; i < rewardContracts.length; i++) {
            IRewardStaking(rewardContracts[i]).getReward(msg.sender, true);
        }
        //claim from extra rewards
        for (uint256 i = 0; i < extraRewardContracts.length; i++) {
            IRewardStaking(extraRewardContracts[i]).getReward(msg.sender);
        }
        //claim from multi reward token contract
        for (uint256 i = 0; i < tokenRewardContracts.length; i++) {
            IRewardStaking(tokenRewardContracts[i]).getReward(msg.sender, tokenRewardTokens[i]);
        }

        //claim from cvxCrv rewards
        if (options.claimCvxCrv) {
            IRewardStaking(cvxCrvRewards).getReward(msg.sender, true);
        }

        //claim from locker
        if (options.claimLockedCvx) {
            IAuraLocker(locker).getReward(msg.sender);
        }

        // deposit/lock/stake
        if (_callRelockRewards(options)) {
            _relockRewards(crvBalance, cvxBalance, cvxCrvBalance, amounts, options);
        }
    }

    /**
     * @notice returns a bool if relocking of rewards should occur
     * @param options                Claim options
     */
    function _callRelockRewards(Options calldata options) internal view returns (bool) {
        return (options.lockCvxCrv || options.lockCrvDeposit || options.useCompounder || options.lockCvx);
    }

    /**
     * @notice  Claim additional rewards from:
     *          - cvxCrvRewards
     *          - cvxLocker
     * @param removeCrvBalance       crvBalance to ignore and not redeposit (starting Crv balance)
     * @param removeCvxBalance       cvxBalance to ignore and not redeposit (starting Cvx balance)
     * @param removeCvxCrvBalance    cvxcrvBalance to ignore and not redeposit (starting CvxCrv balance)
     * @param amounts                Claim rewards amoutns.
     * @param options                see claimRewards
     */
    // prettier-ignore
    function _relockRewards( // solhint-disable-line 
        uint256 removeCrvBalance,
        uint256 removeCvxBalance,
        uint256 removeCvxCrvBalance,          
        ClaimRewardsAmounts calldata amounts, 
        Options calldata options
    ) internal {
        
        //lock upto given amount of crv as cvxCrv
        if (amounts.depositCrvMaxAmount > 0) {
            (uint256 crvBalance, bool continued) = _checkBalanceAndPullToken(
                crv,
                removeCrvBalance, 
                amounts.depositCrvMaxAmount
            );

            if (continued) {ICrvDepositorWrapper(crvDepositWrapper).deposit(
                    crvBalance,
                    amounts.minAmountOut,
                    options.lockCrvDeposit,
                    address(0)
                );}
        }

        
        //Pull cvxCrv to contract if user wants to stake
        if (options.lockCvxCrv) {
            _checkBalanceAndPullToken(cvxCrv, removeCvxCrvBalance, amounts.depositCvxCrvMaxAmount);
        }
        

        //Locks CvxCrv balance held on contract
        //deposit in the autocompounder if flag is set, or stake in rewards contract if not set
        uint cvxCrvBalanceToLock = IERC20(cvxCrv).balanceOf(address(this));
        if(cvxCrvBalanceToLock > 0){
            if(options.useCompounder) {
                IRewardPool4626(compounder).deposit(cvxCrvBalanceToLock, msg.sender);
            }
            else{
                IRewardStaking(cvxCrvRewards).stakeFor(msg.sender, cvxCrvBalanceToLock);
            }   
        }

        //stake up to given amount of cvx
        if (options.lockCvx) {
            (uint256 cvxBalance, bool continued) = _checkBalanceAndPullToken(
                cvx, 
                removeCvxBalance, 
                amounts.depositCvxMaxAmount
            );
            if(continued){IAuraLocker(locker).lock(msg.sender, cvxBalance);}
        }
    }

    /**
     * @notice  Calculates the amount of a token to pull in, if this is above 0 then pulls token
     * @param _token                 the token to evaluate and pull
     * @param _removeAmount          quantity of token to ignore and not redeposit (ie starting balance)
     * @param _maxAmount             the maximum amount of a token
     */
    // prettier-ignore
    function _checkBalanceAndPullToken(
        address _token,
        uint256 _removeAmount,
        uint256 _maxAmount
    ) internal returns (uint256 _balance, bool continued) {
        _balance = IERC20(_token).balanceOf(msg.sender).sub(_removeAmount);
        _balance = AuraMath.min(_balance, _maxAmount);
        if (_balance > 0) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _balance);
            continued = true;
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
pragma solidity 0.8.11;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library AuraMath {
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        require(a <= type(uint224).max, "AuraMath: uint224 Overflow");
        c = uint224(a);
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "AuraMath: uint128 Overflow");
        c = uint128(a);
    }

    function to112(uint256 a) internal pure returns (uint112 c) {
        require(a <= type(uint112).max, "AuraMath: uint112 Overflow");
        c = uint112(a);
    }

    function to96(uint256 a) internal pure returns (uint96 c) {
        require(a <= type(uint96).max, "AuraMath: uint96 Overflow");
        c = uint96(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "AuraMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library AuraMath32 {
    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        c = a - b;
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint112.
library AuraMath112 {
    function add(uint112 a, uint112 b) internal pure returns (uint112 c) {
        c = a + b;
    }

    function sub(uint112 a, uint112 b) internal pure returns (uint112 c) {
        c = a - b;
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint224.
library AuraMath224 {
    function add(uint224 a, uint224 b) internal pure returns (uint224 c) {
        c = a + b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ICrvDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(
        uint256,
        uint256,
        bool,
        address _stakeAddress
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IAuraLocker {
    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRewardStaking {
    function getReward(address _account, bool _claimExtras) external;

    function getReward(address _account) external;

    function getReward(address _account, address _token) external;

    function stakeFor(address, uint256) external;

    function processIdleRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRewardPool4626 {
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function asset() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function processIdleRewards() external;
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