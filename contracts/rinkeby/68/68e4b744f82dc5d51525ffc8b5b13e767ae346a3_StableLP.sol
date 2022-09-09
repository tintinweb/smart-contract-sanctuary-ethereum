/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
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

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
}

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
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

interface IMALP is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

contract StableLP is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IMALP public MALP;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public burnAddress = address(0);

    uint256 public feeMult = 10**18;
    uint256 private feeCalcX = 10**15;
    uint256 private feeCalcY = 4 * 10**14;
    uint256 public depositorRevenueShare = 85 * 10**16; // 85% of depositor revenue
    uint256 public stakingShare = 10 * 10**16; //10% of profit goes to AQL stakers
    uint256 public daoShare = 3 * 10**16; //3% of profit goes to the DAO
    uint256 public burnShare = 2 * 10**16; //2% of profit goes to buying back and burning AQL tokens
    uint256 public loanInterestRate = 10**17; //simple interest for loans, set to 10%, in real world setting this will be dynamic
    uint256 public feeMalp = 10**16; // 1% MALP fee for test

    address stakingRewardsAddress = 0x9449ffD3048AFA2dBEF2b07EbdB37A8e84b21c46;
    address daoAddress = 0xb2815E448b50190d072A388ea26Fbb0Ea0B7C4E1;
    address burnShareAddress = 0x571E5e81D4Fb57E509118CfBB0De365C79888AAD;

    event CreateMALPByUSDT(address receiver, uint256 amount);
    event CreateMALPByUSDC(address receiver, uint256 amount);
    event CreateMALPByDAI(address receiver, uint256 amount);
    event RedeemMALPByUSDT(address receiver, uint256 malp, uint256 usdt);
    event RedeemMALPByUSDC(address receiver, uint256 malp, uint256 usdc);
    event RedeemMALPByDAI(address receiver, uint256 malp, uint256 dai);
    event Swap(
        address trader,
        address input,
        address output,
        uint256 inputAmount,
        uint256 outputAmount
    );
    event UpdatedFeeMult(uint256 feeMult);

    // sets the minimum swap amount to $20
    modifier minSwap(uint256 _swap) {
        require(_swap >= 20);
        _;
    }

    constructor(address _MALP) {
        require(_MALP != address(0), "Invalid MALP address");
        MALP = IMALP(_MALP);
    }

    function transferOwnership(address _owner) public override onlyOwner {
        require(_owner != address(0), "Invalid owner address");
        _transferOwnership(_owner);
    }

    function setMALP(address _MALP) external onlyOwner {
        require(_MALP != address(0), "Invalid MALP address");
        MALP = IMALP(_MALP);
    }

    function changeStableCoinAddress(
        address _usdt,
        address _usdc,
        address _dai
    ) external onlyOwner {
        require(_usdt != address(0), "Invalid USDT address");
        require(_usdc != address(0), "Invalid USDC address");
        require(_dai != address(0), "Invalid DAI address");
        USDC = _usdc;
        USDT = _usdt;
        DAI = _dai;
    }

    function changeProtocolOwnershipAddress(
        address _stakingRewardsAddress,
        address _daoAddress,
        address _burnShareAddress
    ) external onlyOwner {
        require(
            _stakingRewardsAddress != address(0),
            "Invalid stakingRewardsAddress address"
        );
        require(_daoAddress != address(0), "Invalid daoAddress address");
        require(
            _burnShareAddress != address(0),
            "Invalid burnShareAddress address"
        );
        stakingRewardsAddress = _stakingRewardsAddress;
        daoAddress = _daoAddress;
        burnShareAddress = _burnShareAddress;
    }

    /**
     * @dev set feeCalcX, feeCalcY by min and max fee
     * @param _min: min fee
     * @param _max: max fee
     */
    function setFee(uint256 _min, uint256 _max) external onlyOwner {
        require(_min > 0, "Invalid value");
        require(_max > 0, "Invalid value");
        feeCalcY = 0 - _min;
        feeCalcX = _max + feeCalcY;
    }

    /**
     * @param _amount: the amount into stable coins
     */
    function createMALPByUSDT(uint256 _amount) external nonReentrant {
        uint256 fee = (_amount * feeMalp) / 10**18;
        uint256 MALPAmount = _amount - fee; // it will be calculated by current liquidity ratios

        require(
            IERC20(USDT).allowance(msg.sender, address(this)) >= _amount,
            "It should be approved by transfer"
        );

        SafeERC20.safeTransferFrom(
            IERC20(USDT),
            msg.sender,
            address(this),
            _amount
        );
        MALP.mint(msg.sender, MALPAmount);

        emit CreateMALPByUSDT(msg.sender, MALPAmount);
    }

    function createMALPByUSDC(uint256 _amount) external nonReentrant {
        uint256 fee = (_amount * feeMalp) / 10**18;
        uint256 MALPAmount = _amount - fee; // it will be calculated by current liquidity ratios

        require(
            IERC20(USDC).allowance(msg.sender, address(this)) >= _amount,
            "It should be approved by transfer"
        );

        SafeERC20.safeTransferFrom(
            IERC20(USDC),
            msg.sender,
            address(this),
            _amount
        );
        MALP.mint(msg.sender, MALPAmount);

        emit CreateMALPByUSDC(msg.sender, MALPAmount);
    }

    function createMALPByDAI(uint256 _amount) external nonReentrant {
        uint256 fee = (_amount * feeMalp) / 10**18;
        uint256 MALPAmount = _amount - fee; // it will be calculated by current liquidity ratios

        require(
            IERC20(DAI).allowance(msg.sender, address(this)) >= _amount,
            "It should be approved by transfer"
        );

        SafeERC20.safeTransferFrom(
            IERC20(DAI),
            msg.sender,
            address(this),
            _amount
        );
        MALP.mint(msg.sender, MALPAmount);

        emit CreateMALPByDAI(msg.sender, MALPAmount);
    }

    /**
     * @param _amount: the amount into MALP token
     */
    function redeemMALPByUSDT(uint256 _amount) external nonReentrant {
        uint256 fee = (_amount * feeMalp) / 10**18;
        uint256 usdtAmount = _amount - fee; // it will be calculated by current liquidity ratios

        require(
            MALP.allowance(msg.sender, address(this)) >= _amount,
            "It should be approved by transfer"
        );
        require(
            IERC20(USDT).balanceOf(address(this)) >= usdtAmount,
            "Not enough USDT balace"
        );

        SafeERC20.safeTransferFrom(MALP, msg.sender, burnAddress, _amount);
        SafeERC20.safeTransfer(IERC20(USDT), msg.sender, usdtAmount);

        emit RedeemMALPByUSDT(msg.sender, _amount, usdtAmount);
    }

    function redeemMALPByUSDC(uint256 _amount) external nonReentrant {
        uint256 fee = (_amount * feeMalp) / 10**18;
        uint256 usdcAmount = _amount - fee; // it will be calculated by current liquidity ratios

        require(
            MALP.allowance(msg.sender, address(this)) >= _amount,
            "It should be approved by transfer"
        );
        require(
            IERC20(USDC).balanceOf(address(this)) >= usdcAmount,
            "Not enough USDT balace"
        );

        MALP.burn(msg.sender, _amount);
        SafeERC20.safeTransfer(IERC20(USDC), msg.sender, usdcAmount);

        emit RedeemMALPByUSDC(msg.sender, _amount, usdcAmount);
    }

    function redeemMALPByDAI(uint256 _amount) external nonReentrant {
        uint256 fee = (_amount * feeMalp) / 10**18;
        uint256 daiAmount = _amount - fee; // it will be calculated by current liquidity ratios

        require(
            MALP.allowance(msg.sender, address(this)) >= _amount,
            "It should be approved by transfer"
        );
        require(
            IERC20(DAI).balanceOf(address(this)) >= daiAmount,
            "Not enough USDT balace"
        );

        MALP.burn(msg.sender, _amount);
        SafeERC20.safeTransfer(IERC20(DAI), msg.sender, daiAmount);

        emit RedeemMALPByDAI(msg.sender, _amount, daiAmount);
    }

    /**
     * @dev fee = 0.001 * ((Li + amount/2) / (Li + Lo)) - 0.0004
     * @param _input: input token address
     * @param _output: output token address
     * @param _amount: input amount
     */
    function calculateFees(
        address _input,
        address _output,
        uint256 _amount
    ) private returns (uint256) {
        uint256 inputLiquidity = IERC20(_input).balanceOf(address(this));
        uint256 outputLiquidity = IERC20(_output).balanceOf(address(this));

        uint256 inputAmount = inputLiquidity + _amount / 2;
        uint256 totalLiquidity = inputLiquidity + outputLiquidity;

        uint256 fee = (inputAmount * feeCalcX) / totalLiquidity - feeCalcY;
        fee = (_amount * fee) / 10**18;

        accumulateFees(fee);

        return fee;
    }

    /**
     * @dev return total USD balance
     */
    function totalBalance() public view returns (uint256) {
        uint256 usdt = IERC20(USDT).balanceOf(address(this));
        uint256 usdc = IERC20(USDC).balanceOf(address(this));
        uint256 dai = IERC20(DAI).balanceOf(address(this));
        uint256 total = usdt + usdc + dai;

        return total;
    }

    /**
     * @dev exchange functions of different pairs
     */
    function USDTtoUSDC(uint256 _amount) public minSwap(_amount) nonReentrant {
        swap(_amount, USDT, USDC);
    }

    function USDTtoDAI(uint256 _amount) public minSwap(_amount) nonReentrant {
        swap(_amount, USDT, DAI);
    }

    function DAItoUSDT(uint256 _amount) public minSwap(_amount) nonReentrant {
        swap(_amount, DAI, USDT);
    }

    function DAItoUSDC(uint256 _amount) public minSwap(_amount) nonReentrant {
        swap(_amount, DAI, USDC);
    }

    function USDCtoUSDT(uint256 _amount) public minSwap(_amount) nonReentrant {
        swap(_amount, USDC, USDT);
    }

    function USDCtoDAI(uint256 _amount) public minSwap(_amount) nonReentrant {
        swap(_amount, USDC, DAI);
    }

    /**
     * @param _amount: input token amount
     * @param _input: input token address
     * @param _output: output token address
     */
    function swap(
        uint256 _amount,
        address _input,
        address _output
    ) private {
        require(
            IERC20(_output).balanceOf(address(this)) >= _amount,
            "Not enough balace"
        );

        uint256 fee = calculateFees(_input, _output, _amount);
        uint256 outputAmount = _amount - fee;

        SafeERC20.safeTransferFrom(
            IERC20(_input),
            msg.sender,
            address(this),
            _amount
        );
        SafeERC20.safeTransfer(IERC20(_output), msg.sender, outputAmount);

        emit Swap(msg.sender, _input, _output, _amount, outputAmount);
    }

    //(profitshare percentage) of all trading fees go to liquidity providers
    function accumulateFees(uint256 fee) private {
        uint256 total = totalBalance();
        uint256 revenue = fee * depositorRevenueShare;
        uint256 increaseFeeMult = 10**18 + revenue / total;
        feeMult = (feeMult * increaseFeeMult) / 10**18;

        emit UpdatedFeeMult(feeMult);
    }

    //calculates how much of the protocol is profit
    function protocolOwnership() public view returns (uint256) {
        uint256 totalBal = totalBalance();
        uint256 totalMalp = MALP.totalSupply();
        uint256 totalDeposits = (totalMalp * feeMult) / 10**18;
        uint256 protocol = totalBal - totalDeposits;
        return protocol;
    }

    //distributes all protocol revenue to relevant addresses
    function distributeProtocolOwnership() public onlyOwner {
        uint256 totalBal = totalBalance();
        uint256 protocolBalance = protocolOwnership();

        require(totalBal > 0, "balance is 0");

        // total balance of each stablecoin
        uint256 usdtBal = IERC20(USDT).balanceOf(address(this));
        uint256 usdcBal = IERC20(USDC).balanceOf(address(this));
        uint256 daiBal = IERC20(DAI).balanceOf(address(this));

        // total ratio of each stablecoin to total balance
        uint256 usdtRatio = (usdtBal * 10**18) / totalBal;
        uint256 usdcRatio = (usdcBal * 10**18) / totalBal;
        uint256 daiRatio = (daiBal * 10**18) / totalBal;

        // how much of each stablecoin to distribute
        uint256 usdtDist = (usdtRatio * protocolBalance) / 10**18;
        uint256 usdcDist = (usdcRatio * protocolBalance) / 10**18;
        uint256 daiDist = (daiRatio * protocolBalance) / 10**18;

        uint256 protocolPortion = 10**18 - depositorRevenueShare;

        // calculates portion of each respective pool
        uint256 stakePortion = (stakingShare * 10**18) / protocolPortion;
        uint256 daoPortion = (daoShare * 10**18) / protocolPortion;
        uint256 burnPortion = (burnShare * 10**18) / protocolPortion;

        payoutProtocolOwnership(
            stakePortion,
            daoPortion,
            burnPortion,
            usdtDist,
            usdcDist,
            daiDist
        );
    }

    function payoutProtocolOwnership(
        uint256 _stakePortion,
        uint256 _daoPortion,
        uint256 _burnPortion,
        uint256 _usdtDist,
        uint256 _usdcDist,
        uint256 _daiDist
    ) private onlyOwner {
        require(_stakePortion > 0, "stakeportion 0");
        require(_burnPortion > 0, "burn portion 0");
        require(_daoPortion > 0, "dao portion 0");

        // transfers funds to each respective pool based on their portion
        uint256 shareUsdt = (_usdtDist * _stakePortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(USDT), stakingRewardsAddress, shareUsdt);
        uint256 shareUsdc = (_usdcDist * _stakePortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(USDC), stakingRewardsAddress, shareUsdc);
        uint256 shareDai = (_daiDist * _stakePortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(DAI), stakingRewardsAddress, shareDai);

        shareUsdt = (_usdtDist * _burnPortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(USDT), burnShareAddress, shareUsdt);
        shareUsdc = (_usdcDist * _burnPortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(USDC), burnShareAddress, shareUsdc);
        shareDai = (_daiDist * _burnPortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(DAI), burnShareAddress, shareDai);

        shareUsdt = (_usdtDist * _daoPortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(USDT), daoAddress, shareUsdt);
        shareUsdc = (_usdcDist * _daoPortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(USDC), daoAddress, shareUsdc);
        shareDai = (_daiDist * _daoPortion) / 10**18;
        SafeERC20.safeTransfer(IERC20(DAI), daoAddress, shareDai);
    }
}