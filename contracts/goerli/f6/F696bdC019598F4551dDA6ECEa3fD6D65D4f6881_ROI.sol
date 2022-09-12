// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./Ownable.sol";
import "./SafeERC20.sol";

import "./ITreasury.sol";

contract ROI is Ownable {

    uint256 private immutable MAX_INT = 2 ** 256 - 1;

    uint8 private constant STAKE_POOL = 2;
    uint8 private constant LEND_POOL = 3;

    ITreasury public treasury;

    IERC20 public stabl3;

    uint256 private unlocked = 1;

    // mappings

    // contracts with permission to access treasury funds
    mapping (address => bool) public permitted;

    // events

    event UpdatedTreasury(address newTreasury, address oldTreasury);

    event UpdatedPermission(address contractAddress, bool state);

    event APR(uint256 rate, uint256 reserves, uint256 blockTimestampLast);

    // constructor

    constructor(ITreasury _treasury) {
        treasury = _treasury;

        stabl3 = IERC20(0xDf9c4990a8973b6cC069738592F27Ea54b27D569);

        updatePermission(address(_treasury), true);
    }

    function updateTreasury(address _treasury) external onlyOwner {
        require(address(treasury) != _treasury, "ROI: Treasury is already this address");
        updatePermission(address(treasury), false);
        updatePermission(_treasury, true);
        emit UpdatedTreasury(_treasury, address(treasury));
        treasury = ITreasury(_treasury);
    }

    function updatePermission(address _contractAddress, bool _state) public onlyOwner {
        require(permitted[_contractAddress] != _state, "ROI: Contract is already of the value 'state'");
        permitted[_contractAddress] = _state;

        if (_state) {
            delegateApprove(stabl3, _contractAddress, true);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, true);
            }
        }
        else {
            delegateApprove(stabl3, _contractAddress, false);

            for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
                delegateApprove(treasury.allReservedTokens(i), _contractAddress, false);
            }
        }

        emit UpdatedPermission(_contractAddress, _state);
    }

    function getReserves() public view returns (uint256) {
        uint256 totalReserves;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);
            if (treasury.isReservedToken(reservedToken)) {
                uint256 amount = reservedToken.balanceOf(address(this));

                uint256 decimals = reservedToken.decimals();

                if (decimals < 18) {
                    amount *= 10 ** (18 - decimals);
                }

                totalReserves += amount;
            }
        }

        return totalReserves;
    }

    // APR is in 18 decimals
    function getAPR() public view returns (uint256) {
        uint256 totalStakedAmount;
        uint256 totalLendedAmount;

        for (uint256 i = 0 ; i < treasury.allReservedTokensLength() ; i++) {
            IERC20 reservedToken = treasury.allReservedTokens(i);
            if (treasury.isReservedToken(reservedToken)) {
                uint256 stakedAmount = treasury.sumOfAllPools(STAKE_POOL, reservedToken);
                uint256 lendedAmount = treasury.getTreasuryPool(LEND_POOL, reservedToken);
                lendedAmount += treasury.getHQPool(LEND_POOL, reservedToken);

                uint256 decimalsReservedToken = reservedToken.decimals();

                if (decimalsReservedToken < 18) {
                    stakedAmount *= 10 ** (18 - decimalsReservedToken);
                    lendedAmount *= 10 ** (18 - decimalsReservedToken);
                }

                totalStakedAmount += stakedAmount;
                totalLendedAmount += lendedAmount;
            }
        }

        uint256 totalROIReserves = getReserves();

        uint256 currentAPR;
        if (totalStakedAmount != 0 || totalLendedAmount != 0) {
            currentAPR = (totalROIReserves * (10 ** 18)) / (totalStakedAmount + totalLendedAmount);
        }

        return currentAPR;
    }

    function updateAPR() public lock permission {
        uint256 currentAPR = getAPR();

        uint256 reserves = getReserves();

        emit APR(currentAPR, reserves, block.timestamp);
    }

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) public onlyOwner {
        if (_isApprove) {
            SafeERC20.safeApprove(_token, _spender, MAX_INT);
        }
        else {
            SafeERC20.safeApprove(_token, _spender, 0);
        }
    }

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external onlyOwner {
        require(!treasury.isReservedToken(_token), "ROI: Funds Locked");
        SafeERC20.safeTransfer(_token, owner(), _amountToken);
    }

    function withdrawAllFunds(IERC20 _token) external onlyOwner {
        require(!treasury.isReservedToken(_token), "ROI: Funds Locked");
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    // TODO remove
    // Testing only
    function testWithdrawAllFunds(IERC20 _token) external onlyOwner {
        SafeERC20.safeTransfer(_token, owner(), _token.balanceOf(address(this)));
    }

    // modifiers

    modifier lock() {
        require(unlocked == 1, "ROI: Locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier permission() {
        require(permitted[msg.sender] || msg.sender == owner(), "ROI: Not permitted");
        _;
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity 0.8.17;

import "./IERC20.sol";

interface ITreasury {
    function isReservedToken(IERC20 _token) external view returns (bool);

    function allReservedTokens(uint) external view returns (IERC20);

    function getTreasuryPool(uint8, IERC20) external view returns (uint256);
    function getROIPool(uint8, IERC20) external view returns (uint256);
    function getHQPool(uint8, IERC20) external view returns (uint256);

    function updateROI(address _ROI) external;

    function updateHQ(address _HQ) external;

    function updatePermission(address _contractAddress, bool _state) external;

    function updateReservedToken(IERC20 _token, bool _state) external;

    function allReservedTokensLength() external view returns (uint256);

    function allPools(uint8 _type, IERC20 _token) external view returns (uint256, uint256, uint256);

    function sumOfAllPools(uint8 _type, IERC20 _token) external view returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function provideInitialTreasurySupply(uint256 _amountStabl3) external;

    function getReserves() external view returns (uint256);

    function getRate() external view returns (uint256);

    function getRateImpact(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getRateImpact(uint256 _amountStabl3, IERC20 _token) external view returns (uint256);

    function getAmountOut(IERC20 _token, uint256 _amountToken) external view returns (uint256);

    function getAmountIn(uint256 _amountStabl3, IERC20 _token) external view returns (uint256);

    function updatePool(
        uint8 _type,
        IERC20 _token,
        uint256 _amountTokenTreasury,
        uint256 _amountTokenROI,
        uint256 _amountTokenHQ,
        bool _isIncrease
    ) external;

    function updateRate(IERC20 _token, uint256 _amountToken) external;

    function delegateApprove(IERC20 _token, address _spender, bool _isApprove) external;

    function withdrawFunds(IERC20 _token, uint256 _amountToken) external;

    function withdrawAllFunds(IERC20 _token) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

import "./Address.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: Unlicense

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
    * @dev Returns the amount of tokens in existence.
    */
    function totalSupply() external view returns (uint256);

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view returns (uint256);

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.17;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

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