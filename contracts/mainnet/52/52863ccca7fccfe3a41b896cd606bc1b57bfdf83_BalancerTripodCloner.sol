/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// File: .deps/TripodCloner.sol


pragma solidity >=0.8.12;
pragma experimental ABIEncoderV2;





// Import necessary libraries and interfaces:



/*    :::::::::::       :::::::::       :::::::::::       :::::::::       ::::::::       ::::::::: 
         :+:           :+:    :+:          :+:           :+:    :+:     :+:    :+:      :+:    :+: 
        +:+           +:+    +:+          +:+           +:+    +:+     +:+    +:+      +:+    +:+  
       +#+           +#++:++#:           +#+           +#++:++#+      +#+    +:+      +#+    +:+   
      +#+           +#+    +#+          +#+           +#+            +#+    +#+      +#+    +#+    
     #+#           #+#    #+#          #+#           #+#            #+#    #+#      #+#    #+#     
    ###           ###    ###      ###########       ###             ########       #########       
.........................................,;**?????*+:...............................................
.......................................:+??*********?*:.............................................
.....................................,+??************??*,...........................................
..................................,:+???**************???+;,........................................
...........................,,:::;+*???%?**************??%???*+;::::,,,..............................
....................,:;+**??%%%%%????*%%?*************?%?*????%%%%%%???*++;:........................
...................,*?%%%%%%%%%%?*????*%%?***********?%%*????*?%%%%%%%%%%S%?,.......................
...................,%%%%%%%%%%%%*??????*?%??********?%?*??????*%%%%%%%%%%%%%,.......................
....................?%%%%%%%%%%?*???????*?????????????*???????*?%%%%%%%%%%%?,.......................
....................+%%%%%%%%??*?????????*?????????????*???????*??%%%%%%%%%*........................
....................;S%%%%???**????????*?????+;;;;;*??%?*???????**???%%%%%%:........................
....................+?**??%%*******????%%?S%*:.....:*S%?S%??????????%%??**?;........................
...................;?????%%********????%%?%%??*....*?%%%*%%??????*??*??%%%???,.......................
..................:%S%%S%??*****????*?%SS?*%%%%%%%%%%??%%SS????????*???%S%%S?,......................
.................:%%S%?*%%***?%SS??**%%SS%%%??%%%%?%??%%SS%%***?%%%??%%%%%%??*......................
................,??S%%*;%%?%?**?%S%?*?%%%SSS%??%%??%%%%S%%%%???SS%*++?S%%%%+*?;.....................
................+?%%S%+*%S%%;,,*%%S%??%%%%%%SSSSSSSSS%%%%%%???SS%%+::*%%S%S*;*?:....................
...............:?%S%%+?%%S%%?*?%%SS%%*?%%%%%%%%%%%%%%%%%%%?**?%S%%%??%%S%%S?+;?*,...................
...............:;,....,?%%%%%%%%%%%%???????%%%%%%%S%%%?????????%%%%%%%%%%%%,..,::...................
.......................+S%%%%%%%%%::?????????%%%%%%%%?????*????+;S%%%%%%SS?.........................
.......................*%%%S%%SS#*..:??????*??????????**??????:..*##%?S%%%%;........................
......................,+?%%?;,,:;,...:*??????????????????????:...,;:,.;*??+,........................
.............................:*???:,::;+*%????????????????%*++;;????*,..............................
.............................*????%SSS##SS????????????????S####S?????,..............................
...........................,;*???*?SSSSS%S%??????????????%#SSSSS*???%*+;,...........................
..........................;???%???*%S%%%?SSS%%?????????%SSS?%%S%*???????*,..........................
..........................,;*??%?%??%%%**%SS??%??????S%?SS%?*%S??%??*??+,...........................
............................,+???%%*%S%?*?S%?*%SS%%SSS?*?S%??%S?%????*:.............................
..............................:*?*%?*%S?*?S%??%%?%%?%S??%S???S%?%*??+,..............................
...............................,+??%??S%**%S???S%%%%%S??%S??%S?%???:................................
..............................+%?%??%*%S?*%S%??SS##SSS??%S%?%%?%?%%?%*,.............................
............................:%@#S%%%%??%S??SSS?%####SS*SS%%????%%%%S#@S:............................
...........................:%#SSSSSSS%*%%%??;+?%#####%?++%%%%?%SSSSSSS#%;...........................
..........................:??SSSSSS?::??+;?*..???SSS%*?,.?%;;?;:?SSSSSS??:..........................
.........................:????%SSS*...;??:??,.+?%%%%%?*.:%?,+?,..*SSS%????;.........................
........................:??**?????:....;?++?:.:?%????%;.+%;;%;...,*????????;........................
.......................,????????*,......,::?+.,?%????%:.??,+;.....,*????????:.......................
......................,????????*,..........+%;.*%???%?.+%+.........,+????????,......................
...................;%#%****?+..................*?***?:..................;?****%#%+..................
..................:%?%S%%??*,..................*???*?:....................*??%%S%?%;................
.................,?%????S?:,...................??????,....................,:*S%???%?,...............
................,????%?%;......................*%%%%?,......................:%?%???%:...............
...............*????*..........................*??*?+...........................*????*,.............
..............;????,...........................;????,............................,*???+.............
.............*%?,...............................;%%?,.............................,*%*..............
............;%%%+..............................,?%%%;.............................+%%%;.............
...........,?%%%%,.............................:%%%%?............................,%%%%?,............
...........:%%%%%+.............................+%%%%%:...........................+%%%%%;............
...........*%%%%%?.............................?%%%%%;...........................?%%%%%*............
...........?%%%%%%,...........................,?%%%%%+..........................,?%%%%%?,...........
..........,%%%%%%%:...........................,%%%%%%*..........................:%%%%%%%:...........
..........:%%%%%%%;...........................,%%%%%%?..........................;%%%%%%%:...........
..........:%%%%%%%+............................%%%%%%?..........................;%%%%%%%;...........
..........;%%%%%%%+............................+S%%%S*..........................+%%%%%%%;...........
..........:S%%%%%%*............................+S%%%S*..........................+%%%%%%S;...........
...........?S%%%%S;............................;S%%%%+..........................:%S%%%S?............
..........*S*;%%:?S+..........................+S+;S*;S*........................,%%;%%+*S+...........
..........?S;:S?.*S*..........................+S+;S*;S*........................;S?,?S;+S*...........
.........,%%::%?.+S?..........................*S;;S*:S?........................+S*.?%;:S?...........
.........:%%,:%?.;S%,.........................?S:;S*,%%,.......................*S+.?S;,%%,..........
.........:%%,,%?.:%%,........................,%%,:S*.%%........................*S+.?S:,%%,..........
.........;%?,+%%;:%%,........................,%%,:S*.%%,.......................?S;,?%+,%%:..........
.........;S?*S%%S+%%,........................,%%,:S?,?%:.......................?%+?%%%;?%:..........
.........;%%;;;;::%%,........................,%%;%SS??%:.......................?S;,,,,,%%:..........
.........;%%,....:%%:........................,%%;....+%%,......................?S+....:%%;..........
........;?%%%;..:%%%%;.......................:%SSS;.:%SSS+...................,?%S%*,.:%%%%*.........
........?%%%%*..?%%%%*.......................:;;;;,.,;;;;:....................;????*,.+???*+......*/





// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)



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


interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}


// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)



/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)



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



// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)






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










interface IFeedRegistry {
    function getFeed(address, address) external view returns (address);
    function latestRoundData(address, address) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}















struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface IVault is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function lockedProfit() external pure returns(uint256);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    function initialize(
        address token,
        address governance,
        address rewards,
        string memory name,
        string memory symbol,
        address guardian,
        address management
    ) external;

    function addStrategy(
        address _strategy,
        uint256 _debtRatio,
        uint256 _minDebtPerHarvest,
        uint256 _maxDebtPerHarvest,
        uint256 _performanceFee
    ) external;

    function setDepositLimit(uint256 amount) external;

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

    function strategies(address _strategy)
        external
        view
        returns (StrategyParams memory);

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

    function creditAvailable(address strategy) external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    function debtOutstanding(address _strategy) external view returns (uint256);

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

    function revokeStrategy(address strategy) external;

    function migrateStrategy(address oldVersion, address newVersion) external;

    function setEmergencyShutdown(bool active) external;

    function setManagementFee(uint256 fee) external;

    function updateStrategyDebtRatio(address strategy, uint256 debtRatio)
        external;

    function withdraw(
        uint256 maxShare,
        address recipient,
        uint256 maxLoss
    ) external;

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


interface IProviderStrategy {
    function vault() external view returns (IVault);

    function keeper() external view returns (address);

    function want() external view returns (address);

    function balanceOfWant() external view returns (uint256);

    function harvest() external;
}

interface ITripod{
    function pool() external view returns(address);
    function tokenA() external view returns (address);
    function providerA() external view returns (IProviderStrategy);
    function balanceOfA() external view returns(uint256);
    function tokenB() external view returns (address);
    function providerB() external view returns (IProviderStrategy);
    function balanceOfB() external view returns(uint256);
    function tokenC() external view returns (address);
    function providerC() external view returns (IProviderStrategy);
    function balanceOfC() external view returns(uint256);
    function invested(address) external view returns(uint256);
    function totalLpBalance() external view returns(uint256);
    function investedWeight(address)external view returns(uint256);
    function quote(address, address, uint256) external view returns(uint256);
    function usingReference() external view returns(bool);
    function referenceToken() external view returns(address);
    function minAmountToSell() external view returns(uint256);
    function balanceOfTokensInLP() external view returns(uint256, uint256, uint256);
    function getRewardTokens() external view returns(address[] memory);
    function pendingRewards() external view returns(uint256[] memory);
    function dontInvestWant() external view returns(bool);
}

interface IBalancerTripod is ITripod{
    //Struct for each bb pool that makes up the main pool
    struct PoolInfo {
        address token;
        address bbPool;
        bytes32 poolId;
    }
    function poolInfo(uint256) external view returns(PoolInfo memory);
    function curveIndex(address) external view returns(int128);
    function poolId() external view returns(bytes32);
    function toSwapToIndex() external view returns(uint256); 
    function toSwapToPoolId() external view returns(bytes32);
}



/// @title Tripod Math
/// @notice Contains the Rebalancing Logic and Math for the Tripod Base. Used during both the rebalance and quote rebalance functions
library TripodMath {

    /*
    * @notice
    *   The rebalancing math aims to have each tokens relative return be equal after the rebalance irregardless of the strating weights or exchange rates
    *   These functions are called during swapOneToTwo() or swapTwoToOne() in the Tripod.sol https://github.com/Schlagonia/Tripod/blob/master/src/Tripod.sol
    *   All math was adopted from the original joint strategies https://github.com/fp-crypto/joint-strategy

        All equations will use the following variables:
            a0 = The invested balance of the first token
            a1 = The ending balance of the first token
            b0 = The invested balance of the second token
            b1 = The ending balance of the second token
            c0 = the invested balance of the third token
            c1 = The ending balance of the third token
            eOfB = The exchange rate of either a => b or b => a depending on which way we are swapping
            eOfC = The exchange rate of either a => c or c => a depending on which way we are swapping
            precision = 10 ** first token decimals
            precisionB = 10 ** second token decimals
            precisionC = 10 ** third token decimals

            Variables specific to swapOneToTwo()
            n = The amount of a token we will be selling
            p = The % of n we will be selling from a => b

            Variables specific to swapTwoToOne()
            nb = The amount of b we will be swapping to a
            nc = The amount of c we will be swapping to a 

        The starting equations that all of the following are derived from is:

         a1 - n       b1 + eOfB*n*p      c1 + eOfC*n*(1-p) 
        --------  =  --------------  =  -------------------
           a0              b0                   c0

    */

    struct RebalanceInfo {
        uint256 precisionA;
        uint256 a0;
        uint256 a1;
        uint256 b0;
        uint256 b1;
        uint256 eOfB;
        uint256 precisionB;
        uint256 c0;
        uint256 c1;
        uint256 eOfC;
        uint256 precisionC;
    }   

    struct Tokens {
        address tokenA;
        uint256 ratioA;
        address tokenB;
        uint256 ratioB;
        address tokenC;
        uint256 ratioC;
    }
    
    uint256 private constant RATIO_PRECISION = 1e18;
    /*
    * @notice
    *   Internal function to be called during swapOneToTwo to return n: the amount of a to sell and p: the % of n to sell to b
    * @param info, Rebalance info struct with all needed variables
    * @return n, The amount of a to sell
    * @return p, The percent of a we will sell to b repersented as 1e18. i.e. 50% == .5e18
    */
    function getNandP(RebalanceInfo memory info) public pure returns(uint256 n, uint256 p) {
        p = getP(info);
        n = getN(info, p);
    }

    /*
    * @notice
    *   Internal function used to calculate the percent of n that will be sold to b
    *   p is repersented as 1e18
    * @param info, RebalanceInfo stuct
    * @return the percent of a to sell to b as 1e18
    */
    function getP(RebalanceInfo memory info) public pure returns (uint256 p) {
        /*
        *             a1*b0*eOfC + b0c1 - b1c0 - a0*b1*eOfC
        *   p = ----------------------------------------------------
        *        a1*c0*eOfB + a1*b0*eOfC - a0*c1*eOfB - a0*b1*eOfC
        */
        unchecked {
            //pre-calculate a couple of parts that are used twice
            //var1 = a0*b1*eOfC
            uint256 var1 = info.a0 * info.b1 * info.eOfC / info.precisionA;
            //var2 = a1*b0*eOfC
            uint256 var2 = info.a1 * info.b0 * info.eOfC / info.precisionA;

            uint256 numerator = var2 + (info.b0 * info.c1) - (info.b1 * info.c0) - var1;

            uint256 denominator = 
                (info.a1 * info.c0 * info.eOfB / info.precisionA) + 
                    var2 - 
                        (info.a0 * info.c1 * info.eOfB / info.precisionA) - 
                            var1;
    
            p = numerator * 1e18 / denominator;
        }
    }

    /*
    * @notice
    *   Internal function used to calculate the amount of a to sell once p has been calculated
    *   Converts all uint's to int's because the numerator will be negative
    * @param info, RebalanceInfo stuct
    * @param p, % calculated to of b to sell to a in 1e18
    * @return The amount of a to sell
    */
    function getN(RebalanceInfo memory info, uint256 p) public pure returns(uint256) {
        /*
        *          (a1*b0) - (a0*b1)  
        *    n = -------------------- 
        *           b0 + eOfB*a0*P
        */
        unchecked{
            uint256 numerator = 
                (info.a1 * info.b0) -
                    (info.a0 * info.b1);

            uint256 denominator = 
                (info.b0 * 1e18) + 
                    (info.eOfB * info.a0 / info.precisionA * p);

            return numerator * 1e18 / denominator;
        }
    }

    /*
    * @notice
    *   Internal function used to calculate the _nb: the amount of b to sell to a
    *       and nc : the amount of c to sell to a. For the swapTwoToOne() function.
    *   The calculations for both b and c use the same denominator and the numerator is the same consturction but the variables for b or c are swapped 
    * @param info, RebalanceInfo stuct
    * @return _nb, the amount of b to sell to a in terms of b
    * @return nc, the amount of c to sell to a in terms of c 
    */
    function getNbAndNc(RebalanceInfo memory info) public pure returns(uint256 nb, uint256 nc) {
        /*
        *          a0*x1 + y0*eOfy*x1 - a1*x0 - y1*eOfy*x0
        *   nx = ------------------------------------------
        *               a0 + eOfc*c0 + b0*eOfb
        */
        unchecked {
            uint256 numeratorB = 
                (info.a0 * info.b1) + 
                    (info.c0 * info.eOfC * info.b1 / info.precisionC) - 
                        (info.a1 * info.b0) - 
                            (info.c1 * info.eOfC * info.b0 / info.precisionC);

            uint256 numeratorC = 
                (info.a0 * info.c1) + 
                    (info.b0 * info.eOfB * info.c1 / info.precisionB) - 
                        (info.a1 * info.c0) - 
                            (info.b1 * info.eOfB * info.c0 / info.precisionB);

            uint256 denominator = 
                info.a0 + 
                    (info.eOfC * info.c0 / info.precisionC) + 
                        (info.b0 * info.eOfB / info.precisionB);

            nb = numeratorB / denominator;
            nc = numeratorC / denominator;
        }
    }

    /*
     * @notice
     *  Function available publicly estimating the balancing ratios for the tokens in the form:
     * ratio = currentBalance / invested Balance
     * @param startingA, the invested balance of TokenA
     * @param currentA, current balance of tokenA
     * @param startingB, the invested balance of TokenB
     * @param currentB, current balance of tokenB
     * @param startingC, the invested balance of TokenC
     * @param currentC, current balance of tokenC
     * @return _a, _b _c, ratios for tokenA tokenB and tokenC. Will return 0's if there is nothing invested
     */
    function getRatios(
        uint256 startingA,
        uint256 currentA,
        uint256 startingB,
        uint256 currentB,
        uint256 startingC,
        uint256 currentC
    ) public pure returns (uint256 _a, uint256 _b, uint256 _c) {
        unchecked {
            _a = (currentA * RATIO_PRECISION) / startingA;
            _b = (currentB * RATIO_PRECISION) / startingB;
            _c = (currentC * RATIO_PRECISION) / startingC;
        }
    }

    /*
    * @notice 
    *   Internal function called when a new position has been opened to store the relative weights of each token invested
    *   uses the most recent oracle price to get the dollar value of the amount invested. This is so the rebalance function
    *   can work with different dollar amounts invested upon lp creation
    * @param investedA, the amount of tokenA that was invested
    * @param investedB, the amount of tokenB that was invested
    * @param investedC, the amoun of tokenC that was invested
    * @return, the relative weight for each token expressed as 1e18
    */
    function getWeights(
        uint256 investedA,
        uint256 investedB,
        uint256 investedC
    ) public view returns (uint256 wA, uint256 wB, uint256 wC) {
        ITripod tripod = ITripod(address(this));
        unchecked {
            uint256 adjustedA = getOraclePrice(tripod.tokenA(), investedA);
            uint256 adjustedB = getOraclePrice(tripod.tokenB(), investedB);
            uint256 adjustedC = getOraclePrice(tripod.tokenC(), investedC);
            uint256 total = adjustedA + adjustedB + adjustedC; 
                        
            wA = adjustedA * RATIO_PRECISION / total;
            wB = adjustedB * RATIO_PRECISION / total;
            wC = adjustedC * RATIO_PRECISION / total;
        }
    }

    /*
    * @notice
    *   Returns the oracle adjusted price for a specific token and amount expressed in the oracle terms of 1e8
    *   This uses the chainlink feed Registry and returns in terms of the USD
    * @param _token, the address of the token to get the price for
    * @param _amount, the amount of the token we have
    * @return USD price of the _amount of the token as 1e8
    */
    function getOraclePrice(address _token, uint256 _amount) public view returns(uint256) {
        address token = _token;
        //Adjust if we are using WETH of WBTC for chainlink to work
        if(_token == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        if(_token == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) token = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

        (uint80 roundId, int256 price,, uint256 updateTime, uint80 answeredInRound) = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf).latestRoundData(
                token,
                address(0x0000000000000000000000000000000000000348) // USD
            );

        require(price > 0 && updateTime != 0 && answeredInRound >= roundId);
        //return the dollar amount to 1e8
        return uint256(price) * _amount / (10 ** IERC20Extended(_token).decimals());
    }

    /*
    * @notice
    *   Function to be called during harvests that attempts to rebalance all 3 tokens evenly
    *   in comparision to the amounts the started with, i.e. return the same % return
    * @return uint8 that corresponds to what action Tripod should take, 0 means no swaps,
    *   1 means swap one token to the other two and 2 means swap two to the other one
    *   The tokens are returned in order of how they should be swapped
    */
    function rebalance() public view returns(uint8, address, address, address){
        ITripod tripod = ITripod(address(this));
        //We use the tokens struct to cache our variables and avoid stack to deep
        Tokens memory tokens = Tokens(tripod.tokenA(), 0, tripod.tokenB(), 0, tripod.tokenC(), 0);

        (tokens.ratioA, tokens.ratioB, tokens.ratioC) = getRatios(
                    tripod.invested(tokens.tokenA),
                    tripod.balanceOfA(),
                    tripod.invested(tokens.tokenB),
                    tripod.balanceOfB(),
                    tripod.invested(tokens.tokenC),
                    tripod.balanceOfC()
                );
        
        //If they are all the same or very close we dont need to do anything
        if(isCloseEnough(tokens.ratioA, tokens.ratioB) && isCloseEnough(tokens.ratioB, tokens.ratioC)) {
            //Return a 0 for direction to do nothing
            return(0, tokens.tokenA, tokens.tokenB, tokens.tokenC);
        }
        // Calculate the average ratio. Could be at a loss does not matter here
        uint256 avgRatio;
        unchecked{
            avgRatio = (tokens.ratioA * tripod.investedWeight(tokens.tokenA) + 
                            tokens.ratioB * tripod.investedWeight(tokens.tokenB) + 
                                tokens.ratioC * tripod.investedWeight(tokens.tokenC)) / 
                                    RATIO_PRECISION;
        }
        //If only one is higher than the average ratio, then ratioX - avgRatio is split between the other two in relation to their diffs
        //If two are higher than the average each has its diff traded to the third
        //We know all three cannot be above the avg
        //This flow allows us to keep track of exactly what tokens need to be swapped from and to 
        //as well as how much with little extra memory/storage used and a max of 3 if() checks
        if(tokens.ratioA > avgRatio) {

            if (tokens.ratioB > avgRatio) {
                //Swapping A and B -> C
                return(2, tokens.tokenA, tokens.tokenB, tokens.tokenC);
            } else if (tokens.ratioC > avgRatio) {
                //swapping A and C -> B
                return(2, tokens.tokenA, tokens.tokenC, tokens.tokenB);
            } else {
                //Swapping A -> B and C
                return(1, tokens.tokenA, tokens.tokenB, tokens.tokenC);
            }
            
        } else if (tokens.ratioB > avgRatio) {
            //We know A is below avg so we just need to check C
            if (tokens.ratioC > avgRatio) {
                //Swap B and C -> A
                return(2, tokens.tokenB, tokens.tokenC, tokens.tokenA);
            } else {
                //swapping B -> C and A
                return(1, tokens.tokenB, tokens.tokenA, tokens.tokenC);
            }

        } else {
            //We know A and B are below so C has to be the only one above the avg
            //swap C -> A and B
            return(1, tokens.tokenC, tokens.tokenA, tokens.tokenB);
        }
    }

    /*
     * @notice
     *  Function estimating the current assets in the tripod, taking into account:
     * - current balance of tokens in the LP
     * - pending rewards from the LP (if any)
     * - hedge profit (if any)
     * - rebalancing of tokens to maintain token ratios
     * @return estimated tokenA tokenB and tokenC balances
     */
    function estimatedTotalAssetsAfterBalance()
        public
        view
        returns (uint256, uint256, uint256)
    {
        ITripod tripod = ITripod(address(this));
        // Current status of tokens in LP (includes potential IL)
        (uint256 _aBalance, uint256 _bBalance, uint256 _cBalance) = tripod.balanceOfTokensInLP();

        // Add remaining balance in tripod (if any)
        unchecked{
            _aBalance += tripod.balanceOfA();
            _bBalance += tripod.balanceOfB();
            _cBalance += tripod.balanceOfC();
        }

        // Include rewards (swapping them if not one of the LP tokens)
        uint256[] memory _rewardsPending = tripod.pendingRewards();
        address[] memory _rewardTokens = tripod.getRewardTokens();
        address reward;
        for (uint256 i; i < _rewardsPending.length; ++i) {
            reward = _rewardTokens[i];
            if (reward == tripod.tokenA()) {
                _aBalance += _rewardsPending[i];
            } else if (reward == tripod.tokenB()) {
                _bBalance += _rewardsPending[i];
            } else if (reward == tripod.tokenC()) {
                _cBalance += _rewardsPending[i];
            } else if (_rewardsPending[i] != 0) {
                //If we are using the reference token swap to that otherwise use A
                address swapTo = tripod.usingReference() ? tripod.referenceToken() : tripod.tokenA();
                uint256 outAmount = tripod.quote(
                    reward,
                    swapTo,
                    _rewardsPending[i]
                );

                if (swapTo == tripod.tokenA()) { 
                    _aBalance += outAmount;
                } else if (swapTo == tripod.tokenB()) {
                    _bBalance += outAmount;
                } else if (swapTo == tripod.tokenC()) {
                    _cBalance += outAmount;
                }
            }
        }
        return quoteRebalance(_aBalance, _bBalance, _cBalance);
    }

    /*
    * @notice 
    *    This function is a fucking disaster.
    *    But it works...
    */
    function quoteRebalance(
        uint256 startingA,
        uint256 startingB,
        uint256 startingC
    ) public view returns(uint256, uint256, uint256) {
        ITripod tripod = ITripod(address(this));
        //Use tokens struct to avoid stack to deep error
        Tokens memory tokens = Tokens(tripod.tokenA(), 0, tripod.tokenB(), 0, tripod.tokenC(), 0);

        //We cannot rebalance with a 0 starting position, should only be applicable if called when everything is 0 so just return
        if(tripod.invested(tokens.tokenA) == 0 || tripod.invested(tokens.tokenB) == 0 || tripod.invested(tokens.tokenC) == 0) {
            return (startingA, startingB, startingC);
        }

        (tokens.ratioA, tokens.ratioB, tokens.ratioC) = getRatios(
                    tripod.invested(tokens.tokenA),
                    startingA,
                    tripod.invested(tokens.tokenB),
                    startingB,
                    tripod.invested(tokens.tokenC),
                    startingC
                );
        
        //If they are all the same or very close we dont need to do anything
        if(isCloseEnough(tokens.ratioA, tokens.ratioB) && isCloseEnough(tokens.ratioB, tokens.ratioC)) {
            return(startingA, startingB, startingC);
        }
        // Calculate the average ratio. Could be at a loss does not matter here
        uint256 avgRatio;
        unchecked{
            avgRatio = (tokens.ratioA * tripod.investedWeight(tokens.tokenA) + 
                            tokens.ratioB * tripod.investedWeight(tokens.tokenB) + 
                                tokens.ratioC * tripod.investedWeight(tokens.tokenC)) / 
                                    RATIO_PRECISION;
        }
        
        uint256 change0;
        uint256 change1;
        uint256 change2;
        RebalanceInfo memory info;
        //See Rebalance() for explanation
        if(tokens.ratioA > avgRatio) {
            if (tokens.ratioB > avgRatio) {
                //Swapping A and B -> C
                info = RebalanceInfo(0, 0, startingC, 0, startingA, 0, 0, 0, startingB, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapTwoToOne(tripod, info, tokens.tokenA, tokens.tokenB, tokens.tokenC);
                return ((startingA - change0), 
                            (startingB - change1), 
                                (startingC + change2));
            } else if (tokens.ratioC > avgRatio) {
                //swapping A and C -> B
                info = RebalanceInfo(0, 0, startingB, 0, startingA, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapTwoToOne(tripod, info, tokens.tokenA, tokens.tokenC, tokens.tokenB);
                return ((startingA - change0), 
                            (startingB + change2), 
                                (startingC - change1));
            } else {
                //Swapping A -> B and C
                info = RebalanceInfo(0, 0, startingA, 0, startingB, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapOneToTwo(tripod, info, tokens.tokenA, tokens.tokenB, tokens.tokenC);
                return ((startingA - change0), 
                            (startingB + change1), 
                                (startingC + change2));
            }
        } else if (tokens.ratioB > avgRatio) {
            //We know A is below avg so we just need to check C
            if (tokens.ratioC > avgRatio) {
                //Swap B and C -> A
                info = RebalanceInfo(0, 0, startingA, 0, startingB, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapTwoToOne(tripod, info, tokens.tokenB, tokens.tokenC, tokens.tokenA);
                return ((startingA + change2), 
                            (startingB - change0), 
                                (startingC - change1));
            } else {
                //swapping B -> A and C
                info = RebalanceInfo(0, 0, startingB, 0, startingA, 0, 0, 0, startingC, 0, 0);
                (change0, change1, change2) = 
                    _quoteSwapOneToTwo(tripod, info, tokens.tokenB, tokens.tokenA, tokens.tokenC);
                return ((startingA + change1), 
                            (startingB - change0), 
                                (startingC + change2));
            }
        } else {
            //We know A and B are below so C has to be the only one above the avg
            //swap C -> A and B
            info = RebalanceInfo(0, 0, startingC, 0, startingA, 0, 0, 0, startingB, 0, 0);
            (change0, change1, change2) = 
                _quoteSwapOneToTwo(tripod, info, tokens.tokenC, tokens.tokenA, tokens.tokenB);
            return ((startingA + change1), 
                        (startingB + change2), 
                            (startingC - change0));
        }   
    }
    
    
    /*
     * @notice
     *  Function to be called during mock rebalancing.
     *  This will quote swapping the extra tokens from the one that has returned the highest amount to the other two
     *  in relation to what they need attempting to make everything as equal as possible
     *  will return the absolute changes expected for each token, accounting will take place in parent function
     * @param tripod, the instance of the tripod to use
     * @param info, struct of all needed info OF token addresses and amounts
     * @param toSwapToken, the token we will be swapping from to the other two
     * @param token0Address, address of one of the tokens we are swapping to
     * @param token1Address, address of the second token we are swapping to
     * @return negative change in toSwapToken, positive change for token0, positive change for token1
    */
    function _quoteSwapOneToTwo(
        ITripod tripod,
        RebalanceInfo memory info, 
        address toSwapFrom, 
        address toSwapTo0, 
        address toSwapTo1
    ) internal view returns (uint256 n, uint256 amountOut, uint256 amountOut2) {
        uint256 swapTo0;
        uint256 swapTo1;

        unchecked {
            uint256 precisionA = 10 ** IERC20Extended(toSwapFrom).decimals();
            
            uint256 p;

            (n, p) = getNandP(RebalanceInfo({
                precisionA : precisionA,
                a0 : tripod.invested(toSwapFrom),
                a1 : info.a1,
                b0 : tripod.invested(toSwapTo0),
                b1 : info.b1,
                eOfB : tripod.quote(toSwapFrom, toSwapTo0, precisionA),
                precisionB : 0, //Not needed for this calculation
                c0 : tripod.invested(toSwapTo1),
                c1 : info.c1,
                eOfC : tripod.quote(toSwapFrom, toSwapTo1, precisionA),
                precisionC : 0 // Not needed
            }));

            swapTo0 = n * p / RATIO_PRECISION;
            //To assure we dont sell to much 
            swapTo1 = n - swapTo0;
        }

        amountOut = tripod.quote(
            toSwapFrom, 
            toSwapTo0, 
            swapTo0
        );

        amountOut2 = tripod.quote(
            toSwapFrom, 
            toSwapTo1, 
            swapTo1
        );
    }   

    /*
     * @notice
     *  Function to be called during mock rebalancing.
     *  This will quote swap the extra tokens from the two that returned raios higher than target return to the other one
     *  in relation to what they gained attempting to make everything as equal as possible
     *  will return the absolute changes expected for each token, accounting will take place in parent function
     * @param tripod, the instance of the tripod to use
     * @param info, struct of all needed info OF token addresses and amounts
     * @param token0Address, address of one of the tokens we are swapping from
     * @param token1Address, address of the second token we are swapping from
     * @param toTokenAddress, address of the token we are swapping to
     * @return negative change for token0, negative change for token1, positive change for toTokenAddress
    */
    function _quoteSwapTwoToOne(
        ITripod tripod,
        RebalanceInfo memory info,
        address token0Address,
        address token1Address,
        address toTokenAddress
    ) internal view returns(uint256, uint256, uint256) {

        (uint256 toSwapFrom0, uint256 toSwapFrom1) = 
            getNbAndNc(RebalanceInfo({
                precisionA : 0, //Not needed
                a0 : tripod.invested(toTokenAddress),
                a1 : info.a1,
                b0 : tripod.invested(token0Address),
                b1 : info.b1,
                eOfB : tripod.quote(token0Address, toTokenAddress, 10 ** IERC20Extended(token0Address).decimals()),
                precisionB : 10 ** IERC20Extended(token0Address).decimals(),
                c0 : tripod.invested(token1Address),
                c1 : info.c1,
                eOfC : tripod.quote(token1Address, toTokenAddress, 10 ** IERC20Extended(token1Address).decimals()),
                precisionC : 10 ** IERC20Extended(token1Address).decimals()
            }));

        uint256 amountOut = tripod.quote(
            token0Address, 
            toTokenAddress, 
            toSwapFrom0
        );

        uint256 amountOut2 = tripod.quote(
            token1Address, 
            toTokenAddress, 
            toSwapFrom1
        );

        return (toSwapFrom0, toSwapFrom1, (amountOut + amountOut2));
    }
    
    /*
    * @notice
    *   Function used to determine wether or not the ratios between the 3 tokens are close enough 
    *       that it is not worth the cost to do any rebalancing
    * @param ratio0, the current ratio of the first token to check
    * @param ratio1, the current ratio of the second token to check
    * @return boolean repersenting true if the ratios are withen the range to not need to rebalance 
    */
    function isCloseEnough(uint256 ratio0, uint256 ratio1) public pure returns(bool) {
        if(ratio0 == 0 && ratio1 == 0) return true;

        uint256 delta = ratio0 > ratio1 ? ratio0 - ratio1 : ratio1 - ratio0;
        //We wont rebalance withen .01
        uint256 maxRelDelta = ratio1 / 10_000;

        if (delta < maxRelDelta) return true;
    }

    /*
    * @notice
    *   function used internally to determine if a provider has funds available to deposit
    *   Checks the providers want balance of the Tripod, the provider and the credit available to it
    * @param _provider, the provider to check
    */  
    function hasAvailableBalance(IProviderStrategy _provider) 
        public 
        view 
        returns (bool) 
    {
        uint256 minAmountToSell = ITripod(address(this)).minAmountToSell();
        return 
            _provider.balanceOfWant() > minAmountToSell ||
                IERC20(_provider.want()).balanceOf(address(this)) > minAmountToSell ||
                    _provider.vault().creditAvailable(address(_provider)) > minAmountToSell;
    }

    /*
     * @notice
     *  Function used in harvestTrigger in providers to decide wether an epoch can be started or not:
     * - if there is an available for all three tokens but no position open, return true
     * @return wether to start a new epoch or not
     */
    function shouldStartEpoch() public view returns (bool) {
        ITripod tripod = ITripod(address(this));
        //If we are currently invested return false
        if(tripod.invested(tripod.tokenA()) != 0 ||
            tripod.invested(tripod.tokenB()) != 0 || 
                tripod.invested(tripod.tokenC()) != 0) return false;
        
        if(tripod.dontInvestWant()) return false;

        return
            hasAvailableBalance(tripod.providerA()) && 
                hasAvailableBalance(tripod.providerB()) && 
                    hasAvailableBalance(tripod.providerC());
    }
}



interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}

/// @title Tripod
/// @notice This is the base contract for a 3 token joint LP strategy to be used with @Yearn vaults
///     The contract takes tokens from 3 seperate Provider strategies each with a different token that corresponds to one of the tokens that
///     makes up the LP of "pool". Each harvest the Tripod will attempt to rebalance each token into an equal relative return percentage wise
///     irrespective of the begining weights, exchange rates or decimal differences. 
///
///     Made by Schlagania https://github.com/Schlagonia/Tripod adapted from the 2 token joint strategy https://github.com/fp-crypto/joint-strategy
///
abstract contract Tripod {
    using SafeERC20 for IERC20;
    using Address for address;

    // Constant to use in ratio calculations
    uint256 internal constant RATIO_PRECISION = 1e18;
    // Provider strategy of tokenA
    IProviderStrategy public providerA;
    // Provider strategy of tokenB
    IProviderStrategy public providerB;
    // Provider strategy of tokenC
    IProviderStrategy public providerC;

    // Address of tokenA
    address public tokenA;
    // Address of tokenB
    address public tokenB;
    // Address of tokenC
    address public tokenC;

    // Reference token to use in swaps: WETH, WFTM...
    address public referenceToken;
    // Bool repersenting if one of the tokens is == referencetoken
    bool public usingReference;
    // Array containing reward tokens
    address[] public rewardTokens;

    // Address of the pool to LP
    address public pool;

    //Mapping of the Amounts that actually go into the LP position
    mapping(address => uint256) public invested;
    //Mapping of the weights of each token that was invested to 1e18, .33e18 == 33%
    mapping(address => uint256) public investedWeight;

    //Address of the Keeper for this strategy
    address public keeper;

    //Bool manually set to determine wether we should harvest
    bool public launchHarvest;
    // Boolean values protecting against re-investing into the pool
    bool public dontInvestWant;

    // Thresholds to operate the strat
    uint256 public minAmountToSell;
    uint256 public minRewardToHarvest;
    uint256 public maxPercentageLoss;
    //Tripod version of maxReportDelay
    uint256 public maxEpochTime;

    // Modifiers needed for access control normally inherited from BaseStrategy 
    modifier onlyGovernance() {	
        checkGovernance();	
        _;	
    }	
    modifier onlyVaultManagers() {	
        checkVaultManagers();	
        _;	
    }	
    modifier onlyProviders() {	
        checkProvider();	
        _;	
    }	
    modifier onlyKeepers() {	
        checkKeepers();	
        _;	
    }	
    function checkKeepers() internal view {	
        require(isKeeper() || isGovernance() || isVaultManager(), "auth");	
    }	
    function checkGovernance() internal view {	
        require(isGovernance(), "auth");	
    }	
    function checkVaultManagers() internal view {	
        require(isGovernance() || isVaultManager(), "auth");	
    }	
    function checkProvider() internal view {	
        require(isProvider(), "auth");	
    }

    function isGovernance() internal view returns (bool) {
        return
            msg.sender == providerA.vault().governance() &&
            msg.sender == providerB.vault().governance() &&
            msg.sender == providerC.vault().governance();
    }

    function isVaultManager() internal view returns (bool) {
        return
            msg.sender == providerA.vault().management() &&
            msg.sender == providerB.vault().management() &&
            msg.sender == providerC.vault().management();
    }

    function isKeeper() internal view returns (bool) {
        return msg.sender == keeper;
    }

    function isProvider() internal view returns (bool) {
        return
            msg.sender == address(providerA) ||
            msg.sender == address(providerB) ||
            msg.sender == address(providerC);
    }

    /*
     * @notice
     *  Constructor, only called during original deploy
     * @param _providerA, provider strategy of tokenA
     * @param _providerB, provider strategy of tokenB
     * @param _providerC, provider strategy of tokenC
     * @param _referenceToken, token to use as reference, for pricing oracles and paying hedging costs (if any)
     * @param _pool, Pool to LP
     */
    constructor(
        address _providerA,
        address _providerB,
        address _providerC,
        address _referenceToken,
        address _pool
    ) {
        _initialize(_providerA, _providerB, _providerC, _referenceToken, _pool);
    }

    /*
     * @notice
     *  Constructor equivalent for clones, initializing the tripod
     * @param _providerA, provider strategy of tokenA
     * @param _providerB, provider strategy of tokenB
     * @param _providerC, provider strategy of tokenC
     * @param _referenceToken, token to use as reference, for pricing oracles and paying hedging costs (if any)
     * @param _pool, Pool to LP
     */
    function _initialize(
        address _providerA,
        address _providerB,
        address _providerC,
        address _referenceToken,
        address _pool
    ) internal virtual {
        require(address(providerA) == address(0));
        providerA = IProviderStrategy(_providerA);
        providerB = IProviderStrategy(_providerB);
        providerC = IProviderStrategy(_providerC);

        //Make sure we have the same gov set for all Providers
        address vaultGov = providerA.vault().governance();
        require(vaultGov == providerB.vault().governance() && 
                    vaultGov == providerC.vault().governance());

        referenceToken = _referenceToken;
        pool = _pool;
        keeper = msg.sender;
        maxEpochTime = type(uint256).max;

        // NOTE: we let some loss to avoid getting locked in the position if something goes slightly wrong
        maxPercentageLoss = 1e15; // 0.10%

        tokenA = address(providerA.want());
        tokenB = address(providerB.want());
        tokenC = address(providerC.want());
        require(tokenA != tokenB && tokenB != tokenC && tokenA != tokenC);

        //Approve providers so they can pull during harvests
        IERC20(tokenA).safeApprove(_providerA, type(uint256).max);
        IERC20(tokenB).safeApprove(_providerB, type(uint256).max);
        IERC20(tokenC).safeApprove(_providerC, type(uint256).max);

        //Check if we are using the reference token for easier swaps from rewards
        if (tokenA == _referenceToken || tokenB == _referenceToken || tokenC == _referenceToken) {
            usingReference = true;
        }
    }

    function name() external view virtual returns (string memory);

    /* @notice
     *  Used to change `keeper`.
     *  This may only be called by Vault Gov managment or current keeper.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) 
        external 
        onlyVaultManagers 
    {
        keeper = _keeper;
    }

    /*
    * @notice
    * Function available to vault managers to set Tripod parameters.
    *   We combine them all to save byte code
    * @param _dontInvestWant, new booelan value to use
    * @param _minRewardToHarvest, new value to use
    * @param _minAmountToSell, new value to use
    * @param _maxEpochTime, new value to use
    * @param _maxPercentageLoss, new value to use
    * @param _newLaunchHarvest, bool to have keepers launch a harvest
    */
    function setParamaters(
        bool _dontInvestWant,
        uint256 _minRewardToHarvest,
        uint256 _minAmountToSell,
        uint256 _maxEpochTime,
        uint256 _maxPercentageLoss,
        bool _newLaunchHarvest
    ) external onlyVaultManagers {
        dontInvestWant = _dontInvestWant;
        minRewardToHarvest = _minRewardToHarvest;
        minAmountToSell = _minAmountToSell;
        maxEpochTime = _maxEpochTime;
        require(_maxPercentageLoss <= RATIO_PRECISION);
        maxPercentageLoss = _maxPercentageLoss;
        launchHarvest = _newLaunchHarvest;
    }

    /*
    * @notice
    *   External Functions for the keepers to call
    *   Will exit all positions and sell all rewards applicable attempting to rebalance profits
    *   Will then call the harvest function on each Provider to avoid redundant harvests
    *   This only sends funds back if we will not be reinvesting funds
    *   Providers have approval to pull whatever they need
    */
    function harvest() external onlyKeepers {
        if (launchHarvest) {
            launchHarvest = false;
        }

    	//Exits all positions into equal amounts
        _closeAllPositions();

        //Check if we should reopen position
        //If not return all funds
        if(dontInvestWant) {
            _returnLooseToProviders();
        }

        //Harvest all three providers
        providerA.harvest();
        providerB.harvest();
        providerC.harvest();

        //Try and open new position
        //If DontInvestWant == True we should have no funds and this will return;
        _openPosition();
    }

    /*
     * @notice internal function to be called during harvest or by a provider
     *  will pull out of all LP positions, sell all rewards and rebalance back to as even as possible
     *  Will fail if we do not get enough of each asset based on maxPercentLoss
    */
    function _closeAllPositions() internal {
        // Check that we have a position to close
        if (totalLpBalance() == 0) {
            return;
        }

        // 1. CLOSE LIQUIDITY POSITION
        // Closing the position will:
        // - Withdraw from staking contract
        // - Remove liquidity from DEX
        // - Claim pending rewards
        // - Close Hedge and receive payoff
        _closePosition();

        // 2. SELL REWARDS FOR WANT's
        _swapRewardTokens();

        // 3. REBALANCE PORTFOLIO
        // to leave the position with the initial proportions
        _rebalance();

        // Check that we have returned with no losses
        require( 
            balanceOfA() >=
                (invested[tokenA] *
                    (RATIO_PRECISION - maxPercentageLoss)) /
                    RATIO_PRECISION,
            "!A"
        );
        require(
            balanceOfB() >=
                (invested[tokenB] *
                    (RATIO_PRECISION - maxPercentageLoss)) /
                    RATIO_PRECISION,
            "!B"
        );
        require(
            balanceOfC() >=
                (invested[tokenC] *
                    (RATIO_PRECISION - maxPercentageLoss)) /
                    RATIO_PRECISION,
            "!C"
        );

        // reset invested balances
        invested[tokenA] = invested[tokenB] = invested[tokenC] = 0;
        investedWeight[tokenA] = investedWeight[tokenB] = investedWeight[tokenC] = 0;
    }

    /*
     * @notice
     *  Function available for providers to close the tripod position and can then pull funds back
     * provider strategy
     */
    function closeAllPositions() external onlyProviders {
        _closeAllPositions();
        //This is only called during liquidateAllPositions after a strat or vault is shutdown so we should not reinvest
        dontInvestWant = true;
    }
	
    /*
     * @notice
     *  Function called during harvests to open new position:
     * - open the LP position
     * - open the hedge position if necessary
     * - deposit the LPs if necessary
     */
    function _openPosition() internal {
        // No capital, nothing to do
        if (balanceOfA() == 0 || balanceOfB() == 0 || balanceOfC() == 0) {
            return;
        }

        require(
            totalLpBalance() == 0 &&
                invested[tokenA] == 0 &&
                invested[tokenB] == 0 &&
                invested[tokenC] == 0,
                "invested"
        ); // don't create LP if we are already invested

        // Open the LP position
        // Set invested amounts
        (invested[tokenA], invested[tokenB], invested[tokenC]) = _createLP();

        (investedWeight[tokenA], investedWeight[tokenB], investedWeight[tokenC]) =
            TripodMath.getWeights(
                invested[tokenA], 
                invested[tokenB], 
                invested[tokenC]
            );

        // Deposit LPs (if any)
        _depositLP();

        // If there is loose balance, return it
        _returnLooseToProviders();
    }

    /*
     * @notice
     *  Function used by keepers to assess whether to harvest the tripod and compound generated
     * fees into the existing position
     * @param callCost, call cost parameter
     * @return bool, assessing whether to harvest or not
     */
    function harvestTrigger(uint256 /*callCost*/) external view virtual returns (bool) {
        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) {
            return false;
        }

        if(launchHarvest) {
            return true;
        }

        if (shouldStartEpoch()) {
            return true;
        }

        //Check if we have assets and are past our max time
        if(totalLpBalance() > 0 &&
            block.timestamp - providerA.vault().strategies(address(providerA)).lastReport > maxEpochTime
        ) {
            return true;
        }

        return false;
    }

    /*
     * @notice
     *  Function used in harvestTrigger in providers to decide wether an epoch can be started or not:
     * - if there is an available for all three tokens but no position open, return true
     * @return wether to start a new epoch or not
     */
    function shouldStartEpoch() public view returns (bool) {
        return TripodMath.shouldStartEpoch();
    }

    /*
    * @notice 
    *  To be called inbetween harvests if applicable
    *  Default will just claim rewards and sell out of them
    *  It will not create a new LP position
    *  Can be overwritten if othe logic is preffered
    */
    function tend() external virtual onlyKeepers {
        //Claim all outstanding rewards
        _getReward();
        //Swap out of all Reward Tokens
        _swapRewardTokens();
    }

    /*
    * @notice
    *   Trigger to tell Keepers if they should call tend()
    *   Defaults to false. Can be implemented in children if needed
    */
    function tendTrigger(uint256 /*callCost*/) external view virtual returns (bool) {
        return false;
    }

    /*
    * @notice
    *   Function to be called during harvests that attempts to rebalance all 3 tokens evenly
    *   in comparision to the amounts the started with, i.e. return the same % return
    */
    function _rebalance() internal {
        (uint8 direction, address token0, address token1, address token2) = TripodMath.rebalance();
        //If direction == 1 we swap one to two
        //if direction == 2 we swap two to one
        //else if its 0 we dont need to swap anything
        if(direction == 1) {
            _swapOneToTwo(token0, token1, token2);
        } else if(direction == 2){
            _swapTwoToOne(token0, token1, token2);
        }
    }

    /*
     * @notice
     *  Function to be called during rebalancing.
     *  This will swap the extra tokens from the one that has returned the highest amount to the other two
     *  in relation to what they need attempting to make everything as equal as possible
     *  The math is all handled by the functions in TripodMath.sol
     *  All minAmountToSell checks will be handled in the swap function
     * @param toSwapToken, the token we will be swapping from to the other two
     * @param token0Address, address of one of the tokens we are swapping to
     * @param token1Address, address of the second token we are swapping to
    */
    function _swapOneToTwo(
        address toSwapToken,
        address token0Address,
        address token1Address
    ) internal {
        uint256 swapTo0;
        uint256 swapTo1;
        
        unchecked {
            uint256 precisionA = 10 ** IERC20Extended(toSwapToken).decimals();
            // n = the amount of toSwapToken to sell
            // p = the percent of n to swap to token0Address repersented as 1e18
            (uint256 n, uint256 p) = TripodMath.getNandP(
                TripodMath.RebalanceInfo({
                    precisionA : precisionA,
                    a0 : invested[toSwapToken],
                    a1 : IERC20(toSwapToken).balanceOf(address(this)),
                    b0 : invested[token0Address],
                    b1 : IERC20(token0Address).balanceOf(address(this)),
                    eOfB : quote(toSwapToken, token0Address, precisionA),
                    precisionB : 0, //Not Needed
                    c0 : invested[token1Address],
                    c1 : IERC20(token1Address).balanceOf(address(this)),
                    eOfC : quote(toSwapToken, token1Address, precisionA),
                    precisionC : 0 //not needed
                }));
            //swapTo0 = the amount to sell * The percent going to 0
            swapTo0 = n * p / RATIO_PRECISION;
            //To assure we dont sell to much 
            swapTo1 = n - swapTo0;
        }
        
        _swap(
            toSwapToken, 
            token0Address, 
            swapTo0,
            0
        );

        _swap(
            toSwapToken, 
            token1Address, 
            swapTo1, 
            0
        );
    }   

    /*
     * @notice
     *  Function to be called during rebalancing.
     *  This will swap the extra tokens from the two that returned raios higher than target return to the other one
     *  in relation to what they gained attempting to make everything as equal as possible
     *  The math is all handled by the functions in TripodMath.sol
     *  All minAmountToSell checks will be handled in the swap function
     * @param token0Address, address of one of the tokens we are swapping from
     * @param token1Address, address of the second token we are swapping from
     * @param toTokenAddress, address of the token we are swapping to
    */
    function _swapTwoToOne(
        address token0Address,
        address token1Address,
        address toTokenAddress
    ) internal {

        (uint256 toSwapFrom0, uint256 toSwapFrom1) = TripodMath.getNbAndNc(
            TripodMath.RebalanceInfo({
                precisionA : 0, //not needed
                a0 : invested[toTokenAddress],
                a1 : IERC20(toTokenAddress).balanceOf(address(this)),
                b0 : invested[token0Address],
                b1 : IERC20(token0Address).balanceOf(address(this)),
                eOfB : quote(token0Address, toTokenAddress, 10 ** IERC20Extended(token0Address).decimals()),
                precisionB : 10 ** IERC20Extended(token0Address).decimals(),
                c0 : invested[token1Address],
                c1 : IERC20(token1Address).balanceOf(address(this)),
                eOfC : quote(token1Address, toTokenAddress, 10 ** IERC20Extended(token1Address).decimals()),
                precisionC : 10 ** IERC20Extended(token1Address).decimals()
            }));

        _swap(
            token0Address, 
            toTokenAddress, 
            toSwapFrom0, 
            0
        );

        _swap(
            token1Address, 
            toTokenAddress, 
            toSwapFrom1, 
            0
        );
    }

    /*
     * @notice
     *  Function estimating the current assets in the tripod, taking into account:
     * - current balance of tokens in the LP
     * - pending rewards from the LP (if any)
     * - hedge profit (if any)
     * - rebalancing of tokens to maintain token ratios
     * @return estimated tokenA tokenB and tokenC balances
     */
    function estimatedTotalAssetsAfterBalance()
        public
        view
        returns (uint256, uint256, uint256)
    {
        return TripodMath.estimatedTotalAssetsAfterBalance();
    }

    /*
     * @notice
     *  Function available publicly estimating the balance of one of the providers 
     * (one of the tokens). Re-uses the estimatedTotalAssetsAfterBalance function but only uses
     * one the 2 returned values
     * @param _provider, address of the provider of interest
     * @return _balance, balance of the requested provider
     */
    function estimatedTotalProviderAssets(address _provider)
        public
        view
        returns (uint256 _balance)
    {
        if (_provider == address(providerA)) {
            (_balance, , ) = TripodMath.estimatedTotalAssetsAfterBalance();
        } else if (_provider == address(providerB)) {
            (, _balance, ) = TripodMath.estimatedTotalAssetsAfterBalance();
        } else if (_provider == address(providerC)) {
            (, , _balance) = TripodMath.estimatedTotalAssetsAfterBalance();
        }
    }

    function _createLP() internal virtual returns (uint256, uint256, uint256);

    /*
     * @notice
     *  Function used internally to close the LP position: 
     *      - burns the LP liquidity specified amount, all mins are 0
     * @param amount, amount of liquidity to burn
     */
    function _burnLP(uint256 _amount) internal virtual;

    /*
     * @notice
     *  Function used internally to close the LP position: 
     *      - burns the LP liquidity specified amount
     *      - Assures that the min is received
     *  
     * @param amount, amount of liquidity to burn
     * @param minAOut, the min amount of Token A we should receive
     * @param minBOut, the min amount of Token B we should recieve
     * @param minCout, the min amount of Token C we should recieve
     */
    function _burnLP(
        uint256 _amount,
        uint256 minAOut, 
        uint256 minBOut, 
        uint256 minCOut
    ) internal virtual {
        _burnLP(_amount);
        require(minAOut <= balanceOfA() &&
                    minBOut <= balanceOfB() &&
                        minCOut <= balanceOfC(), "min");
    }

    function _getReward() internal virtual;

    function _depositLP() internal virtual;

    function _withdrawLP(uint256 amount) internal virtual;

    /*
     * @notice
     *  Function available internally swapping amounts necessary to swap rewards
     *  This can be overwritten in order to apply custom reward token swaps
     */
    function _swapRewardTokens() internal virtual;

    function _swap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn,
        uint256 _minOutAmount
    ) internal virtual returns (uint256 _amountOut);

    /*
    * @notice
    *   Internal function to swap the reward tokens into one of the provider tokens
    *   Can be overwritten if different logic is required for reward tokens than provider tokens
    * @param _from, address of the reward token we are swapping from
    * @param _t0, address of the token we are swapping to
    * @param _amount, amount to swap from
    * @param _minOut, minimum out we will accept
    * @returns the amount swapped to
    */
    function _swapReward(
        address _from, 
        address _to, 
        uint256 _amountIn, 
        uint256 _minOut
    ) internal virtual returns (uint256) {
        return _swap(_from, _to, _amountIn, _minOut);
    }

    function quote(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn
    ) public view virtual returns (uint256 _amountOut);

    /*
     * @notice
     *  Function available internally closing the tripod postion:
     *  - withdraw LPs (if any)
     *  - close hedging position (if any)
     *  - close LP position 
     * @return balance of each token
     */
    function _closePosition() internal returns (uint256, uint256, uint256) {
        // Unstake LP from staking contract
        _withdrawLP(balanceOfStake());

        if (balanceOfPool() == 0) {
            return (0, 0, 0);
        }

        // **WARNING**: This call is sandwichable, care should be taken
        //              to always execute with a private relay
        // We take care of mins in the harvest logic to assure we account for swaps
        _burnLP(balanceOfPool());

        return (balanceOfA(), balanceOfB(), balanceOfC());
    }

    /*
     * @notice
     *  Function available internally sending back all funds to provuder strategies
     * @return balance of tokenA and tokenB
     */
    function _returnLooseToProviders()
        internal
        returns (uint256 balanceA, uint256 balanceB, uint256 balanceC)
    {
        balanceA = balanceOfA();
        if (balanceA > 0) {
            IERC20(tokenA).safeTransfer(address(providerA), balanceA);
        }

        balanceB = balanceOfB();
        if (balanceB > 0) {
            IERC20(tokenB).safeTransfer(address(providerB), balanceB);
        }

        balanceC = balanceOfC();
        if (balanceC > 0) {
            IERC20(tokenC).safeTransfer(address(providerC), balanceC);
        }
    }

    /*
     * @notice
     *  Function available publicly returning the tripod's balance of tokenA
     * @return balance of tokenA 
     */
    function balanceOfA() public view returns (uint256) {
        return IERC20(tokenA).balanceOf(address(this));
    }

    /*
     * @notice
     *  Function available publicly returning the tripod's balance of tokenB
     * @return balance of tokenB
     */
    function balanceOfB() public view returns (uint256) {
        return IERC20(tokenB).balanceOf(address(this));
    }

    /*
     * @notice
     *  Function available publicly returning the tripod's balance of tokenC
     * @return balance of tokenC
     */
    function balanceOfC() public view returns (uint256) {
        return IERC20(tokenC).balanceOf(address(this));
    }

    /*
    * @notice
    *   Public funtion that will return the total LP balance held by the Tripod
    * @return both the staked and unstaked balances
    */
    function totalLpBalance() public view virtual returns (uint256) {
        unchecked {
            return balanceOfPool() + balanceOfStake();
        }
    }

    /*
    * @notice
    *   Function used return the array of reward Tokens for this Tripod
    */
    function getRewardTokens() public view returns(address[] memory) {
        return rewardTokens;
    }

    function balanceOfPool() public view virtual returns (uint256);


    function balanceOfStake() public view virtual returns (uint256 _balance);

    function balanceOfTokensInLP()
        public
        view
        virtual
        returns (uint256 _balanceA, uint256 _balanceB, uint256 _balanceC);

    function pendingRewards() public view virtual returns (uint256[] memory);

    // --- MANAGEMENT FUNCTIONS ---
	/*
     * @notice
     *  Function available to vault managers closing the tripod position manually
     *  This will attempt to rebalance properly after withdraw.
     *  Will set dontInvestWant == True so harvestTriggers dont return true
     * @param expectedBalanceA, expected balance of tokenA to receive
     * @param expectedBalanceB, expected balance of tokenB to receive
     * @param expectedBalanceC, expected balance of tokenC to receive
     */
    function liquidatePositionManually(
        uint256 expectedBalanceA,
        uint256 expectedBalanceB,
        uint256 expectedBalanceC
    ) external onlyVaultManagers {
        dontInvestWant = true;
        uint256 _a = balanceOfA();
        uint256 _b = balanceOfB();
        uint256 _c = balanceOfC();
        _closeAllPositions();
        require(expectedBalanceA <= balanceOfA() - _a &&
                    expectedBalanceB <= balanceOfB() - _b &&
                        expectedBalanceC <= balanceOfC() - _c, "min");
        // reset invested balances or we wont be able to open up a position again
        invested[tokenA] = invested[tokenB] = invested[tokenC] = 0;
        investedWeight[tokenA] = investedWeight[tokenB] = investedWeight[tokenC] = 0;
    }

    /*
     * @notice
     *  Function available to vault managers returning the funds to the providers manually
     */
    function returnLooseToProvidersManually() external onlyVaultManagers {
        _returnLooseToProviders();
    }

    /*
     * @notice
     *  Function available to vault managers closing the LP position manually
     *  Will set dontInvestWant == True so harvestTriggers dont return true
     * @param expectedBalanceA, expected balance of tokenA to receive
     * @param expectedBalanceB, expected balance of tokenB to receive
     * @param expectedBalanceC, expected balance of tokenC to receive
     */
    function removeLiquidityManually(
        uint256 expectedBalanceA,
        uint256 expectedBalanceB,
        uint256 expectedBalanceC
    ) external virtual onlyVaultManagers {
        dontInvestWant = true;
        _withdrawLP(balanceOfStake());
        //Burn lp will handle min Out checks
        _burnLP(
            balanceOfPool(),
            expectedBalanceA,
            expectedBalanceB,
            expectedBalanceC
        );

        // reset invested balances or we wont be able to open up a position again
        invested[tokenA] = invested[tokenB] = invested[tokenC] = 0;
        investedWeight[tokenA] = investedWeight[tokenB] = investedWeight[tokenC] = 0;
    }

    /*
    * @notice
    *   External function available to vault Managers to swap tokens manually
    *   This function should be implemented with at least an onlyVaultManagers modifier
    *       assuming swap logic checks the address parameters are legit, or onlyGovernance if
    *        those checks are not in place
    * @param tokenFrom, the token we will be swapping from
    * @param tokenTo, the token we will be swapping to
    * @param swapInAmount, the amount to swap from
    * @param minOutAmount, the min of tokento we will accept
    * @param core, bool repersenting if we are swapping the 3 provider tokens on both sides of the trade
    */
    function swapTokenForTokenManually(
        address tokenFrom,
        address tokenTo,
        uint256 swapInAmount,
        uint256 minOutAmount,
        bool core
    ) external virtual returns (uint256);

    /*
     * @notice
     *  Function available to governance sweeping a specified token but not tokenA B or C
     * @param _token, address of the token to sweep
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != tokenA && _token != tokenB && _token != tokenC);

        SafeERC20.safeTransfer(
            IERC20(_token),
            providerA.vault().governance(),
            IERC20(_token).balanceOf(address(this))
        );
    }

    /*
     * @notice
     *  Function available to providers to change the provider addresses
     *  will decrease the allowance for old and increase for new for applicable token
     * @param _newProvider, new address of provider
     */
    function migrateProvider(address _newProvider) external onlyProviders {
        IProviderStrategy newProvider = IProviderStrategy(_newProvider);
        address providerWant = address(newProvider.want());
        if (providerWant == tokenA) {
            IERC20(tokenA).safeApprove(address(providerA), 0);
            IERC20(tokenA).safeApprove(_newProvider, type(uint256).max);
            providerA = newProvider;
        } else if (providerWant == tokenB) {
            IERC20(tokenB).safeApprove(address(providerB), 0);
            IERC20(tokenB).safeApprove(_newProvider, type(uint256).max);
            providerB = newProvider;
        } else if(providerWant == tokenC) {
            IERC20(tokenC).safeApprove(address(providerC), 0);
            IERC20(tokenC).safeApprove(_newProvider, type(uint256).max);
            providerC = newProvider;
        } else {
            revert("!token");
        }
    }

    /*
     * @notice
     *  Internal function checking if allowance is already enough for the contract
     * and if not, safely sets it to max
     * @param _contract, spender contract
     * @param _token, token to approve spend
     * @param _amount, _amoun to approve
     */
    function _checkAllowance(
        address _contract,
        IERC20 _token,
        uint256 _amount
    ) internal {
        if (_token.allowance(address(this), _contract) < _amount) {
            _token.safeApprove(_contract, 0);
            _token.safeApprove(_contract, type(uint256).max);
        }
    }

    // check if the current baseFee is below our external target
    function isBaseFeeAcceptable() internal view returns (bool) {
        return
            IBaseFee(0xb5e1CAcB567d98faaDB60a1fD4820720141f064F)
                .isCurrentBaseFeeAcceptable();
    }
}







interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancerVault {
    enum PoolSpecialization {GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN}
    enum JoinKind {INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT}
    enum ExitKind {EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT}
    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    // enconding formats https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/pkg/balancer-js/src/pool-weighted/encoder.ts
    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest calldata request
    ) external;

    function getPool(bytes32 poolId) external view returns (address poolAddress, PoolSpecialization);

    function getPoolTokenInfo(bytes32 poolId, IERC20 token) external view returns (
        uint256 cash,
        uint256 managed,
        uint256 lastChangeBlock,
        address assetManager
    );

    function getPoolTokens(bytes32 poolId) external view returns (
        IERC20[] calldata tokens,
        uint256[] calldata balances,
        uint256 lastChangeBlock
    );
    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    function queryBatchSwap(
        SwapKind kind, 
        BatchSwapStep[] memory swaps, 
        IAsset[] memory assets, 
        FundManagement memory funds
    ) external view returns (int256[] memory assetDeltas);
}






interface IBalancerPool is IERC20 {
    enum SwapKind {GIVEN_IN, GIVEN_OUT}

    struct SwapRequest {
        SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }

    // virtual price of bpt
    function getRate() external view returns (uint);

    function getPoolId() external view returns (bytes32 poolId);

    function symbol() external view returns (string memory s);

    function getMainToken() external view returns(address);

    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external view returns (uint256 amount);
}




interface IConvexDeposit {
    // deposit into convex, receive a tokenized deposit.  parameter to stake immediately (we always do this).
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    // burn a tokenized deposit (Convex deposit tokens) to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function poolLength() external view returns (uint256);
    function crv() external view returns (address);

    // give us info about a pool based on its pid
    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );
}




interface IConvexRewards {
    // strategy's staked balance in the synthetix staking contract
    function balanceOf(address account) external view returns (uint256);

    // read how much claimable CRV a strategy has
    function earned(address account) external view returns (uint256);

    function pid() external view returns (uint256);

    // stake a convex tokenized deposit
    function stake(uint256 _amount) external returns (bool);

    // withdraw to a convex tokenized deposit, probably never need to use this
    function withdraw(uint256 _amount, bool _claim) external returns (bool);

    // withdraw directly to curve LP token, this is what we primarily use
    function withdrawAndUnwrap(uint256 _amount, bool _claim)
        external
        returns (bool);

    // claim rewards, with an option to claim extra rewards or not
    function getReward(address _account, bool _claimExtras)
        external
        returns (bool);

    // check if we have rewards on a pool
    function extraRewardsLength() external view returns (uint256);

    // if we have rewards, see what the address is
    function extraRewards(uint256 _reward) external view returns (address);

    // read our rewards token
    function rewardToken() external view returns (address);

    // check our reward period finish
    function periodFinish() external view returns (uint256);
}




interface ICurveFi {

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 _fromIndex, 
        int128 _toIndex, 
        uint256 _from_amount
    ) external view returns (uint256);

    function balances(int128) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function coins(uint256) external view returns (address);

}

// Feel free to change the license, but this is what we use


interface ITradeFactory {
    function enable(address, address) external;

    function grantRole(bytes32 role, address account) external;

    function STRATEGY() external view returns (bytes32);
}
// Safe casting and math



/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}
















library BalancerHelper {

    //The main Balancer vault
    IBalancerVault internal constant balancerVault = 
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    ICurveFi internal constant curvePool =
        ICurveFi(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address internal constant balToken =
        0xba100000625a3754423978a60c9317c58a424e3D;
    uint256 internal constant RATIO_PRECISION = 1e18;

    /*
    * @notice
    *   This will return the expected balance of each token based on our lp balance
    *       This will not take into account the invested weight so it can be used to determine how in
            or out balance the pool currently is
    */
    function balanceOfTokensInLP()
        public
        view
        returns (uint256 _balanceA, uint256 _balanceB, uint256 _balanceC) 
    {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        uint256 lpBalance = tripod.totalLpBalance();
     
        if(lpBalance == 0) return (0, 0, 0);

        //Get the total tokens in the lp and the relative portion for each provider token
        uint256 total;
        (IERC20[] memory tokens, uint256[] memory balances, ) = balancerVault.getPoolTokens(tripod.poolId());
        for(uint256 i; i < tokens.length; ++i) {
            address token = address(tokens[i]);
   
            if(token == tripod.pool()) continue;
            uint256 balance = balances[i];
     
            if(token == tripod.poolInfo(0).bbPool) {
                _balanceA = balance;
            } else if(token == tripod.poolInfo(1).bbPool) {
                _balanceB = balance;
            } else if(token == tripod.poolInfo(2).bbPool){
                _balanceC = balance;
            }

            total += balance;
        }

        unchecked {
            uint256 lpDollarValue = lpBalance * IBalancerPool(tripod.pool()).getRate() / 1e18;

            //Adjust for decimals and pool balance
            _balanceA = (lpDollarValue * _balanceA) / (total * (10 ** (18 - IERC20Extended(tripod.tokenA()).decimals())));
            _balanceB = (lpDollarValue * _balanceB) / (total * (10 ** (18 - IERC20Extended(tripod.tokenB()).decimals())));
            _balanceC = (lpDollarValue * _balanceC) / (total * (10 ** (18 - IERC20Extended(tripod.tokenC()).decimals())));
        }
    }

    function quote(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn
    ) public view returns(uint256 amountOut) {
        if(_amountIn == 0) {
            return 0;
        }

        IBalancerTripod tripod = IBalancerTripod(address(this));

        require(_tokenTo == tripod.tokenA() || 
                    _tokenTo == tripod.tokenB() || 
                        _tokenTo == tripod.tokenC()); 

        if(_tokenFrom == balToken) {
            (, int256 balPrice,,,) = IFeedRegistry(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf).latestRoundData(
                balToken,
                address(0x0000000000000000000000000000000000000348) // USD
            );

            //Get the latest oracle price for bal * amount of bal / (1e8 + (diff of token decimals to bal decimals)) to adjust oracle price that is 1e8
            amountOut = uint256(balPrice) * _amountIn / (10 ** (8 + (18 - IERC20Extended(_tokenTo).decimals())));
        } else if(_tokenFrom == tripod.tokenA() || _tokenFrom == tripod.tokenB() || _tokenFrom == tripod.tokenC()){

            // Call the quote function in CRV 3pool
            amountOut = curvePool.get_dy(
                tripod.curveIndex(_tokenFrom), 
                tripod.curveIndex(_tokenTo), 
                _amountIn
            );
        } else {
            amountOut = 0;
        }
    }

    function getCreateLPVariables() public view returns(IBalancerVault.BatchSwapStep[] memory swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        swaps = new IBalancerVault.BatchSwapStep[](6);
        assets = new IAsset[](7);
        limits = new int[](7);
        bytes32 poolId = tripod.poolId();

        //Need two trades for each provider token to create the LP
        //Each trade goes token -> bb-token -> mainPool
        IBalancerTripod.PoolInfo memory _poolInfo;
        for (uint256 i; i < 3; ++i) {
            _poolInfo = tripod.poolInfo(i);
            address token = _poolInfo.token;
            uint256 balance = IERC20(token).balanceOf(address(this));
            //Used to offset the array to the correct index
            uint256 j = i * 2;
            //Swap fromt token -> bb-token
            swaps[j] = IBalancerVault.BatchSwapStep(
                _poolInfo.poolId,
                j,  //index for token
                j + 1,  //index for bb-token
                balance,
                abi.encode(0)
            );

            //swap from bb-token -> main pool
            swaps[j+1] = IBalancerVault.BatchSwapStep(
                poolId,
                j + 1,  //index for bb-token
                6,  //index for main pool
                0,
                abi.encode(0)
            );

            //Match the index used with the correct address and balance
            assets[j] = IAsset(token);
            assets[j+1] = IAsset(_poolInfo.bbPool);
            limits[j] = int(balance);
        }
        //Set the main lp token as the last in the array
        assets[6] = IAsset(tripod.pool());
    }

    function getBurnLPVariables(
        uint256 _amount
    ) public view returns(IBalancerVault.BatchSwapStep[] memory swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        swaps = new IBalancerVault.BatchSwapStep[](6);
        assets = new IAsset[](7);
        limits = new int[](7);
        //Burn a third for each token
        uint256 burnt;
        bytes32 poolId = tripod.poolId();

        //Need seperate swaps for each provider token
        //Each swap goes mainPool -> bb-token -> token
        IBalancerTripod.PoolInfo memory _poolInfo;
        for (uint256 i; i < 3; ++i) {
            _poolInfo = tripod.poolInfo(i);
            uint256 weightedToBurn = _amount * tripod.investedWeight(_poolInfo.token) / RATIO_PRECISION;
            uint256 j = i * 2;
            //Swap from main pool -> bb-token
            swaps[j] = IBalancerVault.BatchSwapStep(
                poolId,
                6,  //Index used for main pool
                j,  //Index for bb-token pool
                i == 2 ? _amount - burnt : weightedToBurn, //To make sure we burn all of the LP
                abi.encode(0)
            );

            //swap from bb-token -> token
            swaps[j+1] = IBalancerVault.BatchSwapStep(
                _poolInfo.poolId,
                j,  //Index used for bb-token pool
                j + 1,  //Index used for token
                0,
                abi.encode(0)
            );

            //adjust the already burnt LP amount
            burnt += weightedToBurn;
            //Match the index used with the applicable address
            assets[j] = IAsset(_poolInfo.bbPool);
            assets[j+1] = IAsset(_poolInfo.token);
        }
        //Set the lp token as asset 6
        assets[6] = IAsset(tripod.pool());
        limits[6] = int(_amount);
    }


    function getRewardVariables(
        uint256 balBalance, 
        uint256 auraBalance
    ) public view returns (IBalancerVault.BatchSwapStep[] memory _swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        _swaps = new IBalancerVault.BatchSwapStep[](4);
        assets = new IAsset[](4);
        limits = new int[](4);
        
        bytes32 toSwapToPoolId = tripod.toSwapToPoolId();
        _swaps[0] = IBalancerVault.BatchSwapStep(
            0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014, //bal-eth pool id
            0,  //Index to use for Bal
            2,  //index to use for Weth
            balBalance,
            abi.encode(0)
        );
        
        //Sell WETH -> toSwapTo token set
        _swaps[1] = IBalancerVault.BatchSwapStep(
            toSwapToPoolId,
            2,  //index to use for Weth
            3,  //Index to use for toSwapTo
            0,
            abi.encode(0)
        );

        //Sell Aura -> Weth
        _swaps[2] = IBalancerVault.BatchSwapStep(
            0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251, //aura eth pool id
            1,  //Index to use for Aura
            2,  //index to use for Weth
            auraBalance,
            abi.encode(0)
        );

        //Sell WETH -> toSwapTo
        _swaps[3] = IBalancerVault.BatchSwapStep(
            toSwapToPoolId,
            2,  //index to use for Weth
            3,  //index to use for toSwapTo
            0,
            abi.encode(0)
        );

        assets[0] = IAsset(0xba100000625a3754423978a60c9317c58a424e3D); //bal token
        assets[1] = IAsset(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF); //Aura token
        assets[2] = IAsset(tripod.referenceToken()); //weth
        assets[3] = IAsset(tripod.poolInfo(tripod.toSwapToIndex()).token); //to Swap to token

        limits[0] = int(balBalance);
        limits[1] = int(auraBalance);
    }

    function getTendVariables(
        IBalancerTripod.PoolInfo memory _poolInfo,
        uint256 balance
    ) public view returns(IBalancerVault.BatchSwapStep[] memory swaps, IAsset[] memory assets, int[] memory limits) {
        IBalancerTripod tripod = IBalancerTripod(address(this));
        swaps = new IBalancerVault.BatchSwapStep[](2);
        assets = new IAsset[](3);
        limits = new int[](3);

        swaps[0] = IBalancerVault.BatchSwapStep(
            _poolInfo.poolId,
            0,  //Index to use for toSwapTo
            1,  //Index to use for bb-toSwapTo
            balance,
            abi.encode(0)
        );

        swaps[1] = IBalancerVault.BatchSwapStep(
            tripod.poolId(),
            1,  //Index to use for bb-toSwapTo
            2,  //Index to use for the main lp token
            0, 
            abi.encode(0)
        );

        assets[0] = IAsset(_poolInfo.token);
        assets[1] = IAsset(_poolInfo.bbPool);
        assets[2] = IAsset(tripod.pool());

        //Only need to set the toSwapTo balance goin in
        limits[0] = int(balance);
    }

}

contract BalancerTripod is Tripod {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;
    
    //Used for swaps. We default to swap rewards to usdc
    address internal constant usdcAddress =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant daiAddress =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    //address of the trade factory to be used for extra rewards
    address public tradeFactory;

    //Curve 3 Pool is used for rebalancing and quoting of stable coin swaps
    //  due to easy getAmountOut functionality
    ICurveFi internal constant curvePool =
        ICurveFi(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    //Index mapping provider token to its crv index 
    mapping (address => int128) public curveIndex;

    /***
        Balancer specific variables
    ***/
    //Array of all 3 provider tokens structs
    IBalancerTripod.PoolInfo[3] public poolInfo;

    //The main Balancer vault
    IBalancerVault internal constant balancerVault = 
        IBalancerVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    //Pools we use for swapping rewards
    bytes32 internal constant ethUsdcPoolId =
        bytes32(0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019);
    bytes32 internal constant ethDaiPoolId = 
        bytes32(0x0b09dea16768f0799065c475be02919503cb2a3500020000000000000000001a);
    //The pool Id for the pool we will swap eth through to a provider token
    bytes32 public toSwapToPoolId;
    //Index of the token for the poolInfo array we are currently swapping to from eth
    uint256 public toSwapToIndex;
    //The main Balancer Pool Id
    bytes32 public poolId;

    /***
        Aura specific variables for staking
        We use the Convex interfaces since Aura is a fork, but using the Aura addresses for all contracts.
    ***/
    //Main contracts for staking and rewwards
    IConvexDeposit public constant depositContract = 
        IConvexDeposit(0x7818A1DA7BD1E64c199029E86Ba244a9798eEE10);
    //Specific for each LP token
    IConvexRewards public rewardsContract; 
    // this is unique to each pool
    uint256 public pid; 
    //If we chould claim extras on harvests. Usually true
    bool public harvestExtras; 

    //Base Reward Tokens
    address internal constant auraToken = 
        0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    address internal constant balToken =
        0xba100000625a3754423978a60c9317c58a424e3D;

    /*
     * @notice
     *  Constructor, only called during original deploy
     * @param _providerA, provider strategy of tokenA
     * @param _providerB, provider strategy of tokenB
     * @param _providerC, provider strrategy of tokenC
     * @param _referenceToken, token to use as reference, for pricing oracles and paying hedging costs (if any)
     * @param _pool, pool to LP
     * @param _rewardsContract The Aura rewards contract specific to this LP token
     */
    constructor(
        address _providerA,
        address _providerB,
        address _providerC,
        address _referenceToken,
        address _pool,
        address _rewardsContract
    ) Tripod(_providerA, _providerB, _providerC, _referenceToken, _pool) {
        _initializeBalancerTripod(_rewardsContract);
    }

    /*
     * @notice
     *  Constructor equivalent for clones, initializing the tripod and the specifics of the strat
     * @param _providerA, provider strategy of tokenA
     * @param _providerB, provider strategy of tokenB
	 * @param _providerC, provider strrategy of tokenC
     * @param _referenceToken, token to use as reference, for pricing oracles and paying hedging costs (if any)
     * @param _pool, pool to LP
     * @param _rewardsContract The Aura rewards contract specific to this LP token
     */
    function initialize(
        address _providerA,
        address _providerB,
        address _providerC,
        address _referenceToken,
        address _pool,
        address _rewardsContract
    ) external {
        _initialize(_providerA, _providerB, _providerC, _referenceToken, _pool);
        _initializeBalancerTripod(_rewardsContract);
    }

    /*
     * @notice
     *  Initialize BalancerTripod specifics
     * @param _rewardsContract, The Aura rewards contract specific to this LP token
     */
    function _initializeBalancerTripod(address _rewardsContract) internal {
        rewardsContract = IConvexRewards(_rewardsContract);
        //Update the PID for the rewards pool
        pid = rewardsContract.pid();
        //Default to always claim extras
        harvestExtras = true;

        //Main balancer PoolId
        poolId = IBalancerPool(pool).getPoolId();

        //Default to usdcEth pool ID.
        //If USDC was not set as Token A we will need to set the index after deployment
        toSwapToPoolId = ethUsdcPoolId;

        //Set array of pool Infos's for each token
        _setBalancerPoolInfos();

        //Set mapping of curve index's
        _setCRVPoolIndexs();

        // The reward tokens are the tokens provided to the pool
        //This will update them based on current rewards on Aura
        _updateRewardTokens();

        _maxApprove(tokenA, address(balancerVault));
        _maxApprove(tokenB, address(balancerVault));
        _maxApprove(tokenC, address(balancerVault));
        _maxApprove(pool, address(depositContract));
        
        //Max approve the curvePool as well for swaps during rebalnce
        _maxApprove(tokenA, address(curvePool));
        _maxApprove(tokenB, address(curvePool));
        _maxApprove(tokenC, address(curvePool));
    }

    /*
     * @notice
     *  Function returning the name of the tripod in the format "BalancerTripod(TokenSymbol)"
     * @return name of the strategy
     */
    function name() external view override returns (string memory) {

        return string(abi.encodePacked("NoHedgeBalancerTripod(", string(
            abi.encodePacked(
                IERC20Extended(pool).symbol()
            )
        ), ")"));
    }

    /*
    * @notice
    *   internal function called during initilization and by gov to update the rewardTokens array
    *   Auto adds Bal and Aura tokens, then checks the rewards contract to see if there are any "extra rewards"
    *   available for this pool
    *   Will max approve bal and aura to the balancer vault and any extras to the trade factory
    */
    function _updateRewardTokens() internal {
        delete rewardTokens; //empty the rewardsTokens and rebuild

        //We know we will be getting bal and Aura at least
        rewardTokens.push(balToken);
        _checkAllowance(address(balancerVault), IERC20(balToken), type(uint256).max);

        rewardTokens.push(auraToken);
        _checkAllowance(address(balancerVault), IERC20(auraToken), type(uint256).max);

        for (uint256 i; i < rewardsContract.extraRewardsLength(); ++i) {
            address virtualRewardsPool = rewardsContract.extraRewards(i);
            address _rewardsToken =
                IConvexRewards(virtualRewardsPool).rewardToken();

            rewardTokens.push(_rewardsToken);
            //We will use the trade factory for any extra rewards
            if(tradeFactory != address(0)) {
                _checkAllowance(tradeFactory, IERC20(_rewardsToken), type(uint256).max);
                ITradeFactory(tradeFactory).enable(_rewardsToken, poolInfo[toSwapToIndex].token);
            }
        }
    }

    /*
     * @notice
     *  Function returning the liquidity amount of the LP position
     *  This is just the non-staked balance
     * @return balance of LP token
     */
    function balanceOfPool() public view override returns (uint256) {
        return IERC20(pool).balanceOf(address(this));
    }

    /*
    * @notice will return the total staked balance
    *   Staked tokens in convex are treated 1 for 1 with lp tokens
    */
    function balanceOfStake() public view override returns (uint256) {
        return rewardsContract.balanceOf(address(this));
    }

    /*
    * @notice
    *   This will return the expected balance of each token based on our lp balance
    *       This will not take into account the invested weight so it can be used to determine how in
            or out balance the pool currently is
    */
    function balanceOfTokensInLP()
        public
        view
        override
        returns (uint256 _balanceA, uint256 _balanceB, uint256 _balanceC) 
    {
        return BalancerHelper.balanceOfTokensInLP();
    }

    /*
     * @notice
     *  Function returning the amount of rewards earned until now
     * @return uint256 array of amounts of expected rewards earned
     */
    function pendingRewards() public view override returns (uint256[] memory) {
        // Initialize the array to same length as reward tokens
        uint256[] memory _amountPending = new uint256[](rewardTokens.length);

        //Save the earned Bal rewards to 0 where bal will be
        _amountPending[0] = 
            rewardsContract.earned(address(this)) + 
                IERC20(balToken).balanceOf(address(this));

        //Dont qoute any extra rewards since ySwaps will handle them, or Aura since there is no oracle
        return _amountPending;
    }

    /*
     * @notice
     *  Function used internally to collect the accrued rewards mid epoch
     */
    function _getReward() internal override {
        rewardsContract.getReward(address(this), harvestExtras);
    }

    /*
     * @notice
     *  Function used internally to open the LP position: 
     *  Creates a batchSwap for each provider token
     * @return the amounts actually invested for each token
     */
    function _createLP() internal override returns (uint256, uint256, uint256) {
    
        (IBalancerVault.BatchSwapStep[] memory swaps, 
            IAsset[] memory assets, 
                int[] memory limits) = 
                    BalancerHelper.getCreateLPVariables();

        balancerVault.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, 
            swaps, 
            assets, 
            _getFundManagement(), 
            limits, 
            block.timestamp
        );

        unchecked {
            return (
                (uint256(limits[0]) - balanceOfA()), 
                (uint256(limits[2]) - balanceOfB()), 
                (uint256(limits[4]) - balanceOfC())
            );
        }
    }

    /*
     * @notice
     *  Function used internally to close the LP position: 
     *      - burns the LP liquidity specified amount, all mins are 0
     * @param amount, amount of liquidity to burn
     */
    function _burnLP(
        uint256 _amount
    ) internal override {

        (IBalancerVault.BatchSwapStep[] memory swaps, 
            IAsset[] memory assets, 
                int[] memory limits) = 
                    BalancerHelper.getBurnLPVariables(_amount);

        balancerVault.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, 
            swaps, 
            assets, 
            _getFundManagement(), 
            limits, 
            block.timestamp
        );
    }

    /*
    * @notice
    *   Internal function to deposit lp tokens into Convex and stake
    */
    function _depositLP() internal override {
        uint256 toStake = IERC20(pool).balanceOf(address(this));

        if(toStake == 0) return;

        depositContract.deposit(pid, toStake, true);
    }

    /*
    * @notice
    *   Internal function to unstake tokens from Convex
    *   harvesExtras will determine if we claim rewards, normally should be true
    */
    function _withdrawLP(uint256 amount) internal override {
        if(amount == 0) return;

        rewardsContract.withdrawAndUnwrap(
            amount, 
            harvestExtras
        );
    }

    /*
     * @notice
     *  Function used internally to swap core lp tokens during rebalancing.
     * @param _tokenFrom, adress of token to swap from
     * @param _tokenTo, address of token to swap to
     * @param _amountIn, amount of _tokenIn to swap for _tokenTo
     * @return swapped amount
     */
    function _swap(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn,
        uint256 _minOutAmount
    ) internal override returns (uint256) {
        if(_amountIn <= minAmountToSell) {
            return 0;
        }

        require(_tokenTo == tokenA || _tokenTo == tokenB || _tokenTo == tokenC); 
        require(_tokenFrom == tokenA || _tokenFrom == tokenB || _tokenFrom == tokenC);
        uint256 prevBalance = IERC20(_tokenTo).balanceOf(address(this));

        // Perform swap through curve since thats what rebalance quote are off of
        curvePool.exchange(
            curveIndex[_tokenFrom], 
            curveIndex[_tokenTo],
            _amountIn, 
            _minOutAmount
        );

        uint256 diff = IERC20(_tokenTo).balanceOf(address(this)) - prevBalance;
        require(diff >= _minOutAmount);
        return diff;
    }

    /*
     * @notice
     *  Function used internally to quote a potential rebalancing swap without actually 
     * executing it. 
     *  Will only quote bal reward token or a core token swap
     *  Uses a chainlink oracle for the balToken and the curve 3Pool for the core swaps
     * We are using the curve pool due to easier get Amount out ability for core coins
     * @param _tokenFrom, adress of token to swap from
     * @param _tokenTo, address of token to swap to
     * @param _amountIn, amount of _tokenIn to swap for _tokenTo
     * @return simulated swapped amount
     */
    function quote(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn
    ) public view override returns (uint256) {
        return BalancerHelper.quote(_tokenFrom, _tokenTo, _amountIn);
    }

    /*
    * @notice
    *   Overwritten main function to sell bal and aura with batchSwap
    *   function used internally to sell the available Bal and Aura tokens
    *   We sell bal/Aura -> WETH -> toSwapTo
    */
    function _swapRewardTokens() internal override {
        uint256 balBalance = IERC20(balToken).balanceOf(address(this));
        uint256 auraBalance = IERC20(auraToken).balanceOf(address(this));

        //Cant swap 0
        if(balBalance == 0 || auraBalance == 0) return;

        (IBalancerVault.BatchSwapStep[] memory swaps,
            IAsset[] memory assets, 
                int[] memory limits) = 
                    BalancerHelper.getRewardVariables(balBalance, auraBalance);

        balancerVault.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, 
            swaps,
            assets,
            _getFundManagement(), 
            limits, 
            block.timestamp
        );   
    }

    /*
    * @internal
    *   Function used internally to set all of a bb-pool info for each provider token
    *   Will set the poolInfoMapping based on the underlying token
    *   Will set the poolInfo array in order of A, B, C for createLP() accounting
    */
    function _setBalancerPoolInfos() internal {
        (IERC20[] memory _tokens, , ) = balancerVault.getPoolTokens(poolId);
        IBalancerTripod.PoolInfo memory _poolInfo;
        for(uint256 i; i < _tokens.length; ++i) {
            IBalancerPool _pool = IBalancerPool(address(_tokens[i]));
            
            //We cant call getMainToken on the main pool
            if(pool == address(_pool)) continue;
            
            address _token = _pool.getMainToken();
            _poolInfo = IBalancerTripod.PoolInfo(
                    _token,
                    address(_pool),
                    _pool.getPoolId()
                );

            if(_token == tokenA) {
                poolInfo[0] = _poolInfo;
            } else if(_token == tokenB) {
                poolInfo[1] = _poolInfo;
            } else if(_token == tokenC) {
                poolInfo[2] = _poolInfo;
            } 
        }
    }

    /*
     * @notice
     *  Function used internally to set the index for each token in the 3Pool
     */
    function _setCRVPoolIndexs() internal {
        uint256 i = 0; 
        int128 poolIndex = 0;
        while (i < 3) {
            address _token = curvePool.coins(i);
            curveIndex[_token] = poolIndex;
            i++;
            poolIndex++;
        }
    }

    /*
     * @notice
     *  Function used by governance to swap tokens manually if needed, can be used when closing 
     * the LP position manually and need some re-balancing before sending funds back to the 
     * providers. Should mainly be used for provider tokens but can be used for bal and aura if need be.
     * @param tokenFrom, address of token we are swapping from
     * @param tokenTo, address of token we are swapping to
     * @param swapInAmount, amount of swapPath[0] to swap for swapPath[1]
     * @param minOutAmount, minimum amount of want out
     * @param core, bool repersenting if this is a swap from LP -> LP token or if one is a none LP token
     * @return swapped amount
     */
    function swapTokenForTokenManually(
        address tokenFrom,
        address tokenTo,
        uint256 swapInAmount,
        uint256 minOutAmount,
        bool core
    ) external override onlyVaultManagers returns (uint256) {
        require(swapInAmount > 0 && IERC20(tokenFrom).balanceOf(address(this)) >= swapInAmount, "!amount");
        
        if(core) {
            return _swap(
                tokenFrom,
                tokenTo,
                swapInAmount,
                minOutAmount
                );
        } else {
            _swapRewardTokens();
            return IERC20(tokenTo).balanceOf(address(this));
        }
    }

    /*
    * @notice
    *   Function available internally to create an lp during tend
    *   Will only use toSwapTo since that is what is swapped to during tend
    */
    function _createTendLP() internal {
        IBalancerTripod.PoolInfo memory _poolInfo = poolInfo[toSwapToIndex];
        uint256 balance = IERC20(_poolInfo.token).balanceOf(address(this));

        (IBalancerVault.BatchSwapStep[] memory swaps, 
            IAsset[] memory assets, 
                int[] memory limits) = 
                    BalancerHelper.getTendVariables(_poolInfo, balance);
        
        balancerVault.batchSwap(
            IBalancerVault.SwapKind.GIVEN_IN, 
            swaps,
            assets,
            _getFundManagement(),
            limits, 
            block.timestamp
        );
    }

    /*
    * @notice 
    *  To be called inbetween harvests if applicable
    *  This will claim and sell rewards and create an LP with all available funds
    *  This will not adjust invested amounts, since it is all profit and is likely to be
    *       denominated in one token used to swap to i.e. WETH
    */
    function tend() external override onlyKeepers {
        //Claim all outstanding rewards
        _getReward();
        //Swap out of all Reward Tokens
        _swapRewardTokens();
        //Create LP tokens
        _createTendLP();
        //Stake LP tokens
        _depositLP();
    }

    /*
    * @notice
    *   Trigger to tell Keepers if they should call tend()
    */
    function tendTrigger(uint256 /*callCost*/) external view override returns (bool) {

        uint256 _minRewardToHarvest = minRewardToHarvest;
        if (_minRewardToHarvest == 0) {
            return false;
        }

        if (totalLpBalance() == 0) {
            return false;
        }

        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) {
            return false;
        }

        if (rewardsContract.earned(address(this)) + IERC20(balToken).balanceOf(address(this)) >= _minRewardToHarvest) {
            return true;
        }

        return false;
    }

    /*
    * @notice
    *   External function for management to call that updates our rewardTokens array
    *   Should be called if the convex contract adds or removes any extra rewards
    */
    function updateRewardTokens() external onlyVaultManagers {
        _updateRewardTokens();
    }

    /*
    * @notice 
    *   Function available from management to change wether or not we harvest extra rewards
    * @param _harvestExtras, bool of new harvestExtras status
    */
    function setHarvestExtras(bool _harvestExtras) external onlyVaultManagers {
        harvestExtras = _harvestExtras;
    }

        /*
    * @notice
    *   Function available to management to change which token we swap to from rewards
    *   will only be usdc or DAI
    */
    function changeToSwapTo(uint256 newIndex) external onlyVaultManagers {
        if(poolInfo[newIndex].token == usdcAddress) {
            toSwapToPoolId = ethUsdcPoolId;
        } else if(poolInfo[newIndex].token == daiAddress) {
            toSwapToPoolId = ethDaiPoolId;
        } else revert();
        toSwapToIndex = newIndex;
    }

    function _getFundManagement() 
        internal 
        view 
        returns (IBalancerVault.FundManagement memory fundManagement) 
    {
        fundManagement = IBalancerVault.FundManagement(
                address(this),
                false,
                payable(address(this)),
                false
            );
    }

    function _maxApprove(address _token, address _contract) internal {
        IERC20(_token).safeApprove(_contract, type(uint256).max);
    }

    // ---------------------- YSWAPS FUNCTIONS ----------------------
    function setTradeFactory(address _tradeFactory) external onlyGovernance {
        if (tradeFactory != address(0)) {
            _removeTradeFactoryPermissions();
        }

        address[] memory _rewardTokens = rewardTokens;
        ITradeFactory tf = ITradeFactory(_tradeFactory);
        //We only need to set trade factory for non aura/bal tokens
        for(uint256 i = 2; i < _rewardTokens.length; ++i) {
            address token = rewardTokens[i];
        
            IERC20(token).safeApprove(_tradeFactory, type(uint256).max);

            tf.enable(token, poolInfo[toSwapToIndex].token);
        }
        tradeFactory = _tradeFactory;
    }

    function removeTradeFactoryPermissions() external onlyVaultManagers {
        _removeTradeFactoryPermissions();
    }

    function _removeTradeFactoryPermissions() internal {
        address[] memory _rewardTokens = rewardTokens;
        for(uint256 i = 2; i < _rewardTokens.length; ++i) {
        
            IERC20(_rewardTokens[i]).safeApprove(tradeFactory, 0);
        }
        
        tradeFactory = address(0);
    }
}

contract BalancerTripodCloner {
    address public immutable original;

    event Cloned(address indexed clone);
    event Deployed(address indexed original);

    constructor(
        address _providerA,
        address _providerB,
        address _providerC,
        address _referenceToken,
        address _pool,
        address _rewardsContract
    ) {
        BalancerTripod _original = new BalancerTripod(_providerA, _providerB, _providerC, _referenceToken, _pool, _rewardsContract);
        emit Deployed(address(_original));

        original = address(_original);
    }

    function name() external pure returns (string memory) {
        return "[email protected]";
    }

    /*
     * @notice
     *  Cloning function to migrate/ deploy to other pools
     * @param _providerA, provider strategy of tokenA
     * @param _providerB, provider strategy of tokenB
     * @param _providerC, provider strrategy of tokenC
     * @param _referenceToken, token to use as reference, for pricing oracles and paying hedging costs (if any)
     * @param _pool, pool to LP
     * @param _rewardsContract The Aura rewards contract specific to this LP token
     * @return newTripod, address of newly deployed tripod
     */
    function cloneBalancerTripod(
        address _providerA,
        address _providerB,
        address _providerC,
        address _referenceToken,
        address _pool,
        address _rewardsContract
    ) external returns (address newTripod) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(original);

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newTripod := create(0, clone_code, 0x37)
        }

        BalancerTripod(newTripod).initialize(
            _providerA,
            _providerB,
            _providerC,
            _referenceToken,
            _pool,
            _rewardsContract
        );

        emit Cloned(newTripod);
    }
}