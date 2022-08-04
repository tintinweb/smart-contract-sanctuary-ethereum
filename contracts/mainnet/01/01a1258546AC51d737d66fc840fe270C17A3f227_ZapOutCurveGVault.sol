/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/interfaces/IVault.sol

interface IVault {
    function deposit(uint256) external;

    function deposit(uint256 amount, address recipient)
        external
        returns (uint256);

    function withdraw(uint256) external;

    function withdraw(uint256 maxShares, address recipient, uint256 maxLoss)
        external
        returns (uint256);

    function withdraw(uint256 maxShares, address recipient, uint256 maxLoss, address endRecipient)
        external
        returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function token() external view returns (address);

    function decimals() external view returns (uint256);

    // V2
    function pricePerShare() external view returns (uint256);
}


// File contracts/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}


// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


// File contracts/interfaces/ICurveSwap.sol

interface ICurveSwap {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount,
        bool removeUnderlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function calc_withdraw_one_coin(uint256 tokenAmount, int128 index)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(
        uint256 tokenAmount,
        int128 index,
        bool _use_underlying
    ) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 tokenAmount, uint256 index)
        external
        view
        returns (uint256);
}


// File contracts/interfaces/ICurveEthSwap.sol

interface ICurveEthSwap {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount)
        external
        payable
        returns (uint256);
}


// File contracts/interfaces/ICurveRegistry.sol

interface ICurveRegistry {
    function getSwapAddress(address tokenAddress)
        external
        view
        returns (address swapAddress);

    function getTokenAddress(address swapAddress)
        external
        view
        returns (address tokenAddress);

    function getDepositAddress(address swapAddress)
        external
        view
        returns (address depositAddress);

    function getPoolTokens(address swapAddress)
        external
        view
        returns (address[4] memory poolTokens);

    function shouldAddUnderlying(address swapAddress)
        external
        view
        returns (bool);

    function getNumTokens(address swapAddress)
        external
        view
        returns (uint8 numTokens);

    function isBtcPool(address swapAddress) external view returns (bool);

    function isEthPool(address swapAddress) external view returns (bool);

    function isUnderlyingToken(
        address swapAddress,
        address tokenContractAddress
    ) external view returns (bool, uint8);
}


// File contracts/libraries/Context.sol


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


// File contracts/libraries/Ownable.sol


pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/libraries/Address.sol


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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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


// File contracts/libraries/SafeERC20.sol


pragma solidity ^0.8.0;


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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}


// File contracts/ZapOutBase.sol


pragma solidity ^0.8.0;



abstract contract ZapOutBase is Ownable {
    using SafeERC20 for IERC20;
    bool public stopped = false;

    // SwapTarget => approval status
    mapping(address => bool) public approvedTargets;

    address internal constant ETHAddress =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Circuit breaker modifiers
    modifier stopInEmergency() {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    /**
        @dev Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param amount the amount of tokens to be transferred
        @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(address token, uint256 amount)
        internal
        returns (uint256)
    {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        return amount;
    }

    function _getBalance(address token)
        internal
        view
        returns (uint256 balance)
    {
        if (token == address(0)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    ///@notice Withdraw tokens like a sweep function
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;
            // Check weather if is native or just ERC20
            if (tokens[i] == ETHAddress) {
                qty = address(this).balance;
                Address.sendValue(payable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this));
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }

    receive() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}


// File contracts/ZapOutCurveGVault.sol

// Copyright (C) 2021 Zapper (Zapper.Fi)

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU Affero General Public License for more details.

///@author Zapper, modified and adapted for Grizzly.fi.
///@notice This contract removes liquidity from Grizzly Vaults to ETH or ERC20 Tokens.
///@notice These files have been changed from the original Zapper ones.


pragma solidity ^0.8.0;








contract ZapOutCurveGVault is ZapOutBase {
    using SafeERC20 for IERC20;

    address private constant wethTokenAddress =
        address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    ICurveRegistry public curveReg; // Grizzly Curve Registry Contract

    mapping(address => bool) internal v2Pool;

    constructor(ICurveRegistry _curveRegistry) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        v2Pool[0xD51a44d3FaE010294C616388b506AcdA1bfAAE46] = true;
        curveReg = _curveRegistry;
    }

    event zapCurveOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
    @notice This method removes the liquidity from curve pools to ETH/ERC tokens
    @param gVault Grizzly Vault from which to remove liquidity
    @param amountIn Indicates the quantity of Vault tokens to remove (shares)
    @param swapAddress indicates Curve swap address for the pool
    @param intermediateToken specifies in which token to exit the curve pool
    @param toToken indicates the ETH/ERC token to which tokens to convert
    @param minToTokens indicates the minimum amount of toTokens to receive
    @param _swapTarget Execution target for the first swap
    @param _swapCallData DEX quote data
    @return toTokensBought- indicates the amount of toTokens received
    */
    function ZapOut(
        address gVault,
        uint256 amountIn,
        address swapAddress,
        address intermediateToken,
        address toToken,
        uint256 minToTokens,
        address _swapTarget,
        bytes calldata _swapCallData
    ) external stopInEmergency returns (uint256) {
        address underlyingToken = IVault(gVault).token();
        address poolTokenAddress = curveReg.getTokenAddress(swapAddress); // ERC20 Curve LP Token
        // Safety check for underlying Vault Token = address LP
        require(poolTokenAddress == underlyingToken, "Wrong LpAddress");

        _approveToken(gVault, address(this), amountIn); // NOTE We should need an approve from sender to Zap Contract

        _pullTokens(gVault, amountIn);

        // Get the LP Tokens by withdrawing from Vault
        uint256 underlyingTokenReceived = _vaultWithdraw(
            gVault,
            amountIn,
            underlyingToken
        );

        if (intermediateToken == address(0)) {
            intermediateToken = ETHAddress;
        }

        // Perform zapOut
        uint256 toTokensBought = _zapOut(
            swapAddress,
            underlyingTokenReceived,
            intermediateToken,
            toToken,
            _swapTarget,
            _swapCallData
        );

        require(toTokensBought >= minToTokens, "High Slippage");

        // Transfer tokens
        if (toToken == address(0)) {
            Address.sendValue(payable(msg.sender), toTokensBought);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, toTokensBought);
        }

        emit zapCurveOut(msg.sender, swapAddress, toToken, toTokensBought);

        return toTokensBought;
    }

    function _vaultWithdraw(
        address fromVault,
        uint256 amount,
        address underlyingVaultToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingVaultToken);

        IVault(fromVault).withdraw(amount, address(this), 10, msg.sender);

        underlyingReceived =
            _getBalance(underlyingVaultToken) -
            iniUnderlyingBal;
    }

    function _zapOut(
        address swapAddress,
        uint256 incomingCrv,
        address intermediateToken,
        address toToken,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 toTokensBought) {
        /// @return true if the pool contains the token, false otherwise
        /// @return index of the token in the pool, 0 if pool does not contain the token
        (bool isUnderlying, uint256 underlyingIndex) = curveReg
            .isUnderlyingToken(swapAddress, intermediateToken);

        // Not Metapool
        if (isUnderlying) {
            uint256 intermediateBought = _exitCurve(
                swapAddress,
                incomingCrv,
                underlyingIndex,
                intermediateToken
            );

            if (intermediateToken == ETHAddress) intermediateToken = address(0);

            toTokensBought = _fillQuote(
                intermediateToken,
                toToken,
                intermediateBought,
                _swapTarget,
                _swapCallData
            );
        } else {
            // From Metapool: Token that trades with another underlying base pool [MIM, 3Pool]
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            uint8 i;
            for (; i < 4; i++) {
                if (curveReg.getSwapAddress(poolTokens[i]) != address(0)) {
                    intermediateSwapAddress = curveReg.getSwapAddress(
                        poolTokens[i]
                    );
                    break;
                }
            }
            // _exitCurve to intermediateSwapAddress Token
            uint256 intermediateCrvBought = _exitMetaCurve(
                swapAddress,
                incomingCrv,
                i,
                poolTokens[i]
            );
            // _performZapOut: fromPool = intermediateSwapAddress
            toTokensBought = _zapOut(
                intermediateSwapAddress,
                intermediateCrvBought,
                intermediateToken,
                toToken,
                _swapTarget,
                _swapCallData
            );
        }
    }

    /**
    @notice This method removes the liquidity from meta curve pools
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitMetaCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256) {
        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, swapAddress);

        uint256 iniTokenBal = IERC20(exitTokenAddress).balanceOf(address(this));
        ICurveSwap(swapAddress).remove_liquidity_one_coin(
            incomingCrv,
            int128(uint128(index)),
            0
        );
        uint256 tokensReceived = (
            IERC20(exitTokenAddress).balanceOf(address(this))
        ) - iniTokenBal;

        require(tokensReceived > 0, "Could not receive reserve tokens");

        return tokensReceived;
    }

    /**
    @notice This method removes the liquidity from given curve pool
    @param swapAddress indicates the curve pool address from which liquidity to be removed.
    @param incomingCrv indicates the amount of liquidity to be removed from the pool
    @param index indicates the index of underlying token of the pool in which liquidity will be removed. 
    @return tokensReceived- indicates the amount of reserve tokens received 
    */
    function _exitCurve(
        address swapAddress,
        uint256 incomingCrv,
        uint256 index,
        address exitTokenAddress
    ) internal returns (uint256) {
        address depositAddress = curveReg.getDepositAddress(swapAddress);

        address tokenAddress = curveReg.getTokenAddress(swapAddress);
        _approveToken(tokenAddress, depositAddress);

        address balanceToken = exitTokenAddress == ETHAddress
            ? address(0)
            : exitTokenAddress;

        uint256 iniTokenBal = _getBalance(balanceToken);

        if (curveReg.shouldAddUnderlying(swapAddress)) {
            // Aave
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(uint128(index)),
                0,
                true
            );
        } else if (v2Pool[swapAddress]) {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                index,
                0
            );
        } else {
            ICurveSwap(depositAddress).remove_liquidity_one_coin(
                incomingCrv,
                int128(uint128(index)),
                0
            );
        }

        uint256 tokensReceived = _getBalance(balanceToken) - iniTokenBal;

        require(tokensReceived > 0, "Could not receive reserve tokens");

        return tokensReceived;
    }

    /**
    @notice This method swaps the fromToken to toToken using the 0x swap
    @param _fromTokenAddress indicates the ETH/ERC20 token
    @param _toTokenAddress indicates the ETH/ERC20 token
    @param _amount indicates the amount of from tokens to swap
    @param _swapTarget Execution target for the first swap
    @param _swapCallData DEX quote data
    */
    function _fillQuote(
        address _fromTokenAddress,
        address _toTokenAddress,
        uint256 _amount,
        address _swapTarget,
        bytes memory _swapCallData
    ) internal returns (uint256 amountBought) {
        if (_fromTokenAddress == _toTokenAddress) return _amount;

        if (
            _fromTokenAddress == wethTokenAddress &&
            _toTokenAddress == address(0)
        ) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        } else if (
            _fromTokenAddress == address(0) &&
            _toTokenAddress == wethTokenAddress
        ) {
            IWETH(wethTokenAddress).deposit{value: _amount}();
            return _amount;
        }

        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) valueToSend = _amount;
        else _approveToken(_fromTokenAddress, _swapTarget, _amount);

        uint256 iniBal = _getBalance(_toTokenAddress);
        require(approvedTargets[_swapTarget], "Target not Authorized");
        (bool success, ) = _swapTarget.call{value: valueToSend}(_swapCallData);
        require(success, "Error Swapping Tokens");
        uint256 finalBal = _getBalance(_toTokenAddress);

        amountBought = finalBal - iniBal;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    /**
    @notice Utility function to determine the quantity and address of a token being removed
    @param swapAddress indicates the curve pool address from which liquidity to be removed
    @param tokenAddress token to be removed
    @param liquidity Quantity of LP tokens to remove
    @return amount Quantity of token removed
    */
    function removeLiquidityReturn(
        address swapAddress,
        address tokenAddress,
        uint256 liquidity
    ) external view returns (uint256 amount) {
        if (tokenAddress == address(0)) tokenAddress = ETHAddress;
        (bool underlying, uint256 index) = curveReg.isUnderlyingToken(
            swapAddress,
            tokenAddress
        );
        if (underlying) {
            if (v2Pool[swapAddress]) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(liquidity, uint256(index));
            } else if (curveReg.shouldAddUnderlying(swapAddress)) {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(
                            liquidity,
                            int128(uint128(index)),
                            true
                        );
            } else {
                return
                    ICurveSwap(curveReg.getDepositAddress(swapAddress))
                        .calc_withdraw_one_coin(
                            liquidity,
                            int128(uint128(index))
                        );
            }
        } else {
            address[4] memory poolTokens = curveReg.getPoolTokens(swapAddress);
            address intermediateSwapAddress;
            for (uint256 i = 0; i < 4; i++) {
                intermediateSwapAddress = curveReg.getSwapAddress(
                    poolTokens[i]
                );
                if (intermediateSwapAddress != address(0)) break;
            }
            uint256 metaTokensRec = ICurveSwap(swapAddress)
                .calc_withdraw_one_coin(liquidity, int128(1));

            (, index) = curveReg.isUnderlyingToken(
                intermediateSwapAddress,
                tokenAddress
            );

            return
                ICurveSwap(intermediateSwapAddress).calc_withdraw_one_coin(
                    metaTokensRec,
                    int128(uint128(index))
                );
        }
    }

    function updateCurveRegistry(ICurveRegistry newCurveRegistry)
        external
        onlyOwner
    {
        require(newCurveRegistry != curveReg, "Already using this Registry");
        curveReg = newCurveRegistry;
    }

    function setV2Pool(address[] calldata pool, bool[] calldata isV2Pool)
        external
        onlyOwner
    {
        require(pool.length == isV2Pool.length, "Invalid Input length");

        for (uint256 i = 0; i < pool.length; i++) {
            v2Pool[pool[i]] = isV2Pool[i];
        }
    }
}