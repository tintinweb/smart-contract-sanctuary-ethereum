/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/PresaleContract.sol

pragma solidity ^0.8.0;

contract SolidaPreSale is Ownable {
    using SafeERC20 for IERC20;
    uint256 private _levelOne = 30;
    uint256 private _levelTwo = 20;
    uint256 USDTprice = 200000;
    uint256 tokenSold;
    uint256 totalRefferalCount;
    uint256 private _totalETHInvestment;
    uint256 private _totalUSDTInvestMent;
    AggregatorV3Interface internal priceFeed;
    address private specialAddress = 0x7D32C68AD076EC3e78Ce4540936059778E7c27dD;
    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 SOLIDA = IERC20(0xd0b2FbadA0aaB960a819E5bcCc98D3c0c897313B);
    struct refferalData {
        address userAddress;
        uint256 totalRefferals;
        uint256 usdtAmount;
        uint256 etherAmount;
    }

    struct claimData {
        address[] claimAddress;
        uint256 usdtAmount;
        uint256 etherAmount;
        uint256 totalClaims;
        uint256 totalInvestmentETH;
        uint256 totalInvestmentUSDT;
    }
    struct buyRequests {
        address userAddress;
        uint256 quantity;
        address referredBy;
        uint256 amountPaid;
    }
    mapping(address => buyRequests) internal BuyRequests;
    mapping(uint256 => claimData) internal ClaimStatistics;
    mapping(address => refferalData) public Refferals;
    mapping(address => address[]) public myRefferals;
    event TransferUSDTev(
        address fromAddress,
        address toAddress,
        uint256 amount
    );
    event TransferSOLIDA(
        address fromAddress,
        address toAddress,
        uint256 amount
    );
    event Received(address, uint256);

    constructor() {
        Refferals[msg.sender] = refferalData(msg.sender, 0, 0, 0);
        BuyRequests[msg.sender] = buyRequests(
            msg.sender,
            0,
            address(0),
            0
        );
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    event PriceGot(address indexed Sender, uint256 value);
    event Reffered(address indexed _referrer, uint256 value);

    function buyTokenUSDT(uint256 quantity, address _refferalAddress) external {
        require(
            BuyRequests[_refferalAddress].userAddress != address(0),
            "Invalid referral address"
        );

        require(
            _refferalAddress != address(0),
            "Can't use Address 0 as refferal!"
        );
        require(quantity > 0, "Quantity should be more than 0");
        uint256 payment = (quantity * USDTprice);
        uint256 balance = USDT.balanceOf(msg.sender);
        require(balance >= payment, "Balance should be");
        uint256 allowance = USDT.allowance(msg.sender, address(this));
        require(allowance >= payment, "Allowance should equal to the amount");
        uint256 ethPrice = getUsdtToEth(payment);
        emit PriceGot(msg.sender, ethPrice);
        if (_refferalAddress != address(0)) {
            if (Refferals[_refferalAddress].userAddress == address(0)) {
                Refferals[_refferalAddress] = refferalData(
                    _refferalAddress,
                    1,
                    (payment * _levelOne) / 100,
                    (ethPrice * _levelOne) / 100
                );
                myRefferals[_refferalAddress].push(msg.sender);
                emit Reffered(msg.sender, (ethPrice * _levelTwo) / 100);
            } else {
                Refferals[_refferalAddress].usdtAmount +=
                    (payment * _levelOne) /
                    100;
                Refferals[_refferalAddress].etherAmount +=
                    (ethPrice * _levelOne) /
                    100;
                Refferals[_refferalAddress].totalRefferals += 1;

                emit Reffered(msg.sender, (ethPrice * _levelTwo) / 100);
            }
        }
        if (BuyRequests[msg.sender].userAddress == address(0)) {
            BuyRequests[msg.sender] = buyRequests(
                specialAddress,
                quantity,
                _refferalAddress,
                payment
            );
        }
        Refferals[specialAddress].etherAmount += (ethPrice * _levelTwo) / 100;
        Refferals[specialAddress].usdtAmount += ((payment * _levelTwo) / 100);
        USDT.safeTransferFrom(msg.sender, address(this), payment);
        _totalUSDTInvestMent += payment;
        ClaimStatistics[1].totalInvestmentUSDT += payment;
        emit TransferUSDTev(msg.sender, address(this), payment);
        // require(_transferUSDT, "USDT transfer failed.");
        SOLIDA.safeTransfer(msg.sender, quantity * 10**9);
        emit TransferSOLIDA(msg.sender, address(this), quantity * 10**9);
        // require(transferSLD, "Token transfer failed.");
        totalRefferalCount++;
        tokenSold += quantity * 10**9;
    }

    function buyTokenETH(address _refferalAddress) external payable {
        require(
            BuyRequests[_refferalAddress].userAddress != address(0),
            "Invalid referral address"
        );
        require(
            _refferalAddress != address(0),
            "Can't use Address 0 as refferal!"
        );
        // require(quantity > 0, "Quantity should be more than 0");
        uint256 usdAmount = getValueInUSDT(msg.value);
        uint256 solidaAmt = ((usdAmount / USDTprice) * 1e9);
        _totalETHInvestment += msg.value;

        if (Refferals[_refferalAddress].userAddress == address(0)) {
            Refferals[_refferalAddress] = refferalData(
                _refferalAddress,
                1,
                (usdAmount * _levelOne) / 100,
                (msg.value * _levelOne) / 100
            );
            myRefferals[_refferalAddress].push(msg.sender);
        } else {
            Refferals[_refferalAddress].usdtAmount +=
                usdAmount *
                (_levelOne / 100);
            Refferals[_refferalAddress].etherAmount +=
                msg.value *
                (_levelOne / 100);
            Refferals[_refferalAddress].totalRefferals += 1;
            myRefferals[_refferalAddress].push(msg.sender);
        }
        BuyRequests[msg.sender] = buyRequests(
            specialAddress,
            solidaAmt,
            _refferalAddress,
            usdAmount
        );

        Refferals[specialAddress].etherAmount += ((msg.value * _levelTwo) /
            100);
        Refferals[specialAddress].usdtAmount += ((usdAmount * _levelTwo) / 100);
        ClaimStatistics[2].totalInvestmentETH += msg.value;

        SOLIDA.safeTransfer(msg.sender, solidaAmt);
        totalRefferalCount++;
        tokenSold += solidaAmt;
        emit TransferSOLIDA(msg.sender, address(this), solidaAmt);
        // require(transferSLD, "Token transfer failed.");
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimal = getDecimals();
        return uint256(price) * 10**(18 - decimal);
    }

    function getValueInUSDT(uint256 _ethAmount)
        internal
        view
        returns (uint256)
    {
        uint256 valuePrice = getLatestPrice();
        // uint decimals = getDecimals();
        uint256 Amount = ((valuePrice) * _ethAmount) / 1e30;
        return Amount;
    }

    function getUsdtToEth(uint256 _usdtAmount) internal view returns (uint256) {
        uint256 ethPrice = getValueInUSDT(1000000000000000000);
        uint256 toEth = (uint256(_usdtAmount) * 1e18) / uint256(ethPrice);
        return toEth;
    }

    function getDecimals() internal view returns (uint8) {
        return priceFeed.decimals();
    }

    function changeLevelOneCommission(uint256 _howMuch) public onlyOwner {
        _levelOne = _howMuch;
    }

    function changeLevelTwoCommision(uint256 _howMuch) public onlyOwner {
        _levelTwo = _howMuch;
    }

    function tokenBalance() public view returns (uint256) {
        uint256 balance = SOLIDA.balanceOf(address(this));
        return balance;
    }

    function totalReferrals() public view returns (uint256) {
        return totalRefferalCount;
    }

    function myEarningsInUSDT(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 earning = Refferals[_userAddress].usdtAmount;
        return earning;
    }

    function myEarningsInETH(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 earning = Refferals[_userAddress].usdtAmount;
        return earning;
    }

    function userData(address _userAddress)
        public
        view
        returns (refferalData memory)
    {
        return Refferals[_userAddress];
    }

    function claimCommissionUSDT() public {
        uint256 earnings = Refferals[msg.sender].usdtAmount;
        require(
            USDT.balanceOf(address(this)) >= earnings,
            "insufficient funds for transfer, please wait till replenishment."
        );
        USDT.safeTransfer(msg.sender, earnings);
        ClaimStatistics[1].claimAddress.push(msg.sender);
        ClaimStatistics[1].usdtAmount += earnings;
        ClaimStatistics[1].totalClaims += 1;

        Refferals[msg.sender].usdtAmount = 0;
        Refferals[msg.sender].etherAmount = 0;
    }

    function claimCommissionETH() public {
        uint256 earnings = Refferals[msg.sender].etherAmount;
        bool _tranx = payable(msg.sender).send(earnings);
        require(
            _tranx,
            "insufficient funds for transfer, please wait till replenishment."
        );
        ClaimStatistics[1].claimAddress.push(msg.sender);
        ClaimStatistics[1].etherAmount += earnings;
        ClaimStatistics[1].totalClaims += 1;
        Refferals[msg.sender].usdtAmount = 0;
        Refferals[msg.sender].etherAmount = 0;
    }

    function totalUsdInvestMent() public view onlyOwner returns (uint256) {
        return _totalUSDTInvestMent;
    }

    function totalETHInvestMent() public view onlyOwner returns (uint256) {
        return _totalETHInvestment;
    }

    function withdrawETH(address payable payee) public onlyOwner {
        require(address(this).balance > 0, "Insufficient contract balance!");
        payee.transfer(address(this).balance);
    }

    function withdrawUSDT(address payable payee) public onlyOwner {
        uint256 _USDbalance = USDT.balanceOf(address(this));
        require(_USDbalance > 0, "NO USDT balance in the Contract");
        USDT.safeTransfer(payee, _USDbalance);
    }

    function changeL2Address(address _userAddress) public onlyOwner {
        require(_userAddress != address(0), "INvalid address");
        specialAddress = _userAddress;
    }

    function withdrawSLD(address payable payee) public onlyOwner {
        uint256 _SLDbalance = SOLIDA.balanceOf(address(this));
        require(
            SOLIDA.balanceOf(address(this)) > 0,
            "NO SOLIDA balance in the Contract"
        );
        SOLIDA.safeTransfer(payee, _SLDbalance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
// Developed by SolidChainSolutions
// Business Inquires - Telegram: @CryptoEmpire1337