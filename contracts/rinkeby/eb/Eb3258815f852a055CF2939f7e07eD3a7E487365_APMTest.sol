pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT


import "debond-apm/contracts/APM.sol";

contract APMTest is APM {

    constructor(address governanceAddress) APM(governanceAddress) {}
}

// SPDX-License-Identifier: apache 2.0

pragma solidity ^0.8.0;

import "../interfaces/IActivable.sol";
import "../interfaces/IGovernanceAddressUpdatable.sol";

contract GovernanceOwnable is IActivable, IGovernanceAddressUpdatable {

    constructor(address _governanceAddress) {
        governanceAddress = _governanceAddress;
        isActive = true;
    }

    address governanceAddress;
    bool isActive;

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Governance Restriction: Not allowed");
        _;
    }

    modifier _onlyIsActive() {
        require(isActive, "Contract Is Not Active");
        _;
    }

    function setIsActive(bool _isActive) external onlyGovernance {
        isActive = _isActive;
    }

    function setGovernanceAddress(address _governanceAddress) external onlyGovernance {
        require(_governanceAddress != address(0), "null address given");
        governanceAddress = _governanceAddress;
    }
}

// SPDX-License-Identifier: apache 2.0

pragma solidity ^0.8.0;

interface IGovernanceAddressUpdatable {

    function setGovernanceAddress(address _governanceAddress) external;
}

// SPDX-License-Identifier: apache 2.0

pragma solidity ^0.8.0;

interface IActivable {

    function setIsActive(bool _isActive) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

interface IAPM {

    function getReserves(address tokenA, address tokenB) external view returns (uint reserveA, uint reserveB);

    function updateWhenAddLiquidity(
        uint _amountA, 
        uint _amountB,
        address _tokenA,
        address _tokenB) external;

    function updateWhenRemoveLiquidity(
        uint amount, 
        address token) external;

    function swap(uint amount0Out, uint amount1Out,address token0, address token1, address to) external;

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function updateTotalReserve(address tokenAddress, uint amount) external;

    function removeLiquidity(address _to, address tokenAddress, uint amount) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: apache 2.0
/*
    Copyright 2020 Sigmoid Foundation <[email protected]>
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/
import "./interfaces/IAPM.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "debond-governance/contracts/utils/GovernanceOwnable.sol";




contract APM is IAPM, GovernanceOwnable {

    using SafeERC20 for IERC20;


    mapping(address => uint256) internal totalReserve;
    mapping(address => uint256) internal totalVlp; //Vlp : virtual liquidity pool
    //mapping(address => mapping( address => Pair) ) pairs;
    mapping(address => mapping( address => uint) ) vlp;
    address bankAddress;


    struct UpdateData { //to avoid stack too deep error
        uint amountA;
        uint amountB;
        address tokenA;
        address tokenB;
    }

    constructor(address _governanceAddress) GovernanceOwnable(_governanceAddress) {}

    modifier onlyBank() {
        require(msg.sender == bankAddress, "APM: Not Authorised");
        _;
    }

    function setBankAddress(address _bankAddress) external onlyGovernance {
        require(_bankAddress != address(0), "APM: Address 0 given for Bank!");
        bankAddress = _bankAddress;
    }

    function getReservesOneToken(
        address tokenA, //token we want to know reserve
        address tokenB //pool associated
    ) private view returns (uint reserveA) {
        uint totalVlpA = totalVlp[tokenA]; //gas saving
        if( totalVlpA != 0){
            uint vlpA = vlp[tokenA][tokenB];
            reserveA = vlpA * totalReserve[tokenA] / totalVlpA; //use mulDiv?
        }
    }
    function getReserves(
        address tokenA,
        address tokenB
    ) public override view returns (uint reserveA, uint reserveB) {
        (reserveA, reserveB) = (getReservesOneToken(tokenA, tokenB), getReservesOneToken(tokenB, tokenA) );
    }
    function updateTotalReserve(address tokenAddress, uint amount) public {
        totalReserve[tokenAddress] = totalReserve[tokenAddress] + amount;
    }
    function getVlps(address tokenA, address tokenB) public view returns (uint vlpA) {
        vlpA = vlp[tokenA][tokenB];
    }
    function updateWhenAddLiquidityOneToken(
        uint amountA,
        address tokenA,
        address tokenB) private {

        UpdateData memory updateData;
        updateData.amountA = amountA;
        updateData.tokenA = tokenA;
        updateData.tokenB = tokenB;

        uint totalReserveA = totalReserve[updateData.tokenA];//gas saving

        if(totalReserveA != 0){
            //update Vlp
            uint oldVlpA = vlp[tokenA][tokenB];  //for update total vlp
            uint totalVlpA = totalVlp[updateData.tokenA]; //save gas

            uint vlpA = amountToAddVlp(oldVlpA, updateData.amountA, totalVlpA, totalReserveA);
            vlp[tokenA][tokenB] = vlpA;

            //update total vlp
            totalVlp[updateData.tokenA] = totalVlpA - oldVlpA + vlpA;
        }
        else {
            vlp[tokenA][tokenB] = amountA;
            totalVlp[updateData.tokenA] = updateData.amountA;
        }
        totalReserve[updateData.tokenA] = totalReserveA + updateData.amountA;
    }
    function updateWhenAddLiquidity(
        uint amountA,
        uint amountB,
        address tokenA,
        address tokenB) external onlyBank { //TODO : restrict update functions for bank only, using assert/require and not modifiers
        updateWhenAddLiquidityOneToken(amountA, tokenA, tokenB);
        updateWhenAddLiquidityOneToken(amountB, tokenB, tokenA);
    }
    function updateWhenRemoveLiquidityOneToken(
        uint amountA,
        address tokenA,
        address tokenB) private {
        UpdateData memory updateData;
        updateData.amountA = amountA;
        updateData.tokenA = tokenA;
        updateData.tokenB = tokenB;

        uint totalReserveA = totalReserve[updateData.tokenA];//gas saving

        if(totalReserveA != 0){
            //update Vlp
            uint oldVlpA = vlp[tokenA][tokenB];  //for update total vlp
            uint totalVlpA = totalVlp[updateData.tokenA]; //save gas

            uint vlpA = amountToRemoveVlp(oldVlpA, updateData.amountA, totalVlpA, totalReserveA);
            vlp[tokenA][tokenB] = vlpA;

            //update total vlp
            totalVlp[updateData.tokenA] = totalVlpA - oldVlpA + vlpA;
        }
        else {
            vlp[tokenA][tokenB] = amountA;
            totalVlp[updateData.tokenA] = updateData.amountA;
        }
        totalReserve[updateData.tokenA] = totalReserveA - updateData.amountA;
    }
    function updateWhenRemoveLiquidity(
        uint amount, //amountA is the amount of tokenA removed in total pool reserve ( so not the total amount of tokenA in total pool reserve)
        address token) public {
        require(msg.sender == bankAddress, "APM: Not Authorised");

        totalReserve[token] -= amount;
    }
    function updateWhenSwap(
        uint amountAAdded, //amountA is the amount of tokenA swapped in this pool ( so not the total amount of tokenA in this pool after the swap)
        uint amountBWithdrawn,
        address tokenA,
        address tokenB) private {

        updateWhenAddLiquidityOneToken(amountAAdded, tokenA, tokenB);
        updateWhenRemoveLiquidityOneToken(amountBWithdrawn, tokenB, tokenA);
    }
    function amountToAddVlp(uint oldVlp, uint amount, uint totalVlpToken, uint totalReserveToken) public pure returns (uint newVlp) {
        newVlp = oldVlp + amount * totalVlpToken / totalReserveToken;
    }
    function amountToRemoveVlp(uint oldVlp, uint amount, uint totalVlpToken, uint totalReserveToken) public pure returns (uint newVlp) {
        newVlp = oldVlp - amount * totalVlpToken / totalReserveToken;
    }
    struct SwapData { //to avoid stack too deep error
        uint totalReserve0;
        uint totalReserve1;
        uint currentReserve0;
        uint currentReserve1;
        uint amount0In;
        uint amount1In;
    }

    uint private unlocked = 1; //reentracy
    function swap(uint amount0Out, uint amount1Out,address token0, address token1, address to) external { //no need to have both amount >0, there is always one equals to 0 (according to yu).
        require(unlocked == 1, 'APM swap: LOCKED');
        unlocked = 0;
        require( (amount0Out != 0 && amount1Out == 0)|| (amount0Out == 0 && amount1Out != 0), 'APM swap: INSUFFICIENT_OUTPUT_AMOUNT_Or_Both_output >0');
        require(to != token0 && to != token1, 'APM swap: INVALID_TO'); // do we really need this?
        (uint _reserve0, uint _reserve1) = getReserves(token0, token1); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'APM swap: INSUFFICIENT_LIQUIDITY');

        if (amount0Out == 0) IERC20(token1).transfer(to, amount1Out);
        else IERC20(token0).transfer(to, amount0Out);

        SwapData memory swapData;

        swapData.totalReserve0 = IERC20(token0).balanceOf(address(this));
        swapData.totalReserve1 = IERC20(token1).balanceOf(address(this));
        swapData.currentReserve0 = _reserve0 + swapData.totalReserve0 - totalReserve[token0]; // should be >= 0
        swapData.currentReserve1 = _reserve1 + swapData.totalReserve1 - totalReserve[token1];
        require(swapData.currentReserve0 * swapData.currentReserve1 >= _reserve0 * _reserve1, 'APM swap: K');

        swapData.amount0In = swapData.currentReserve0 > _reserve0 - amount0Out ? swapData.currentReserve0 - (_reserve0 - amount0Out) : 0;
        swapData.amount1In = swapData.currentReserve1 > _reserve1 - amount1Out ? swapData.currentReserve1 - (_reserve1 - amount1Out) : 0;
        require(swapData.amount0In > 0 || swapData.amount1In > 0, 'APM swap: INSUFFICIENT_INPUT_AMOUNT');
        if (amount0Out == 0) {
            updateWhenSwap(swapData.amount0In, amount1Out, token0, token1);
        }
        else {
            updateWhenSwap(swapData.amount1In, amount0Out, token1, token0);
        }
        unlocked = 1;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'APM: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'APM: INSUFFICIENT_LIQUIDITY');
        uint numerator = amountIn * reserveOut;
        uint denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts) {
        require(path.length >= 2, 'APM: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }


    // Bank Access
    function removeLiquidity(address _to, address tokenAddress, uint amount) external onlyBank {
        // transfer
        IERC20(tokenAddress).safeTransfer(_to, amount);
        // update getReserves
        updateWhenRemoveLiquidity(amount, tokenAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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