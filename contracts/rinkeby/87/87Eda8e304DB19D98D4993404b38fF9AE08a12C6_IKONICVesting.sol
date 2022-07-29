/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// File: locall.sol



//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.14;

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.14;


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

contract IKONICVesting is Ownable,ReentrancyGuard{

    using SafeERC20 for IERC20;
    IERC20 public token;
    uint public globalStartTime;
    bool public isVestingStarted;
    bool public isRewardTokenSet;

    struct Investor {
        address account;
        uint256 amount;
        uint256 investorType;
    }


    struct vestingDetails {
        uint investorType;
        uint totalBalance;
        uint lastClaimTime;
        uint initialToBeClaimed;
        uint intermediateToBeClaimed;
        uint linearToBeClaimed;
        uint initialClaimed;
        uint intermediateClaimed;
        uint linearClaimed;
        bool hasInitialClaimed;
        bool hasIntermediateClaim;
        bool hasLinearClaimed;
    }

    constructor () {
    }
      

    event InvestorAddress(address account, uint _amout,uint investorType);
    event VestingAmountTaken(address account, uint _amout);
    event SetRewardToken(address owner, address _tokenAddress);
    event BlockedUser(address _user);
    event UnBlockedUsers(address _user);
    event GetEth(address _user, uint amount);
    event TransferredToke(address _tokenAddress, uint amount);
    event RemoveUser(address _userAddress);


    mapping (address => vestingDetails) public InvestorDetails;
    mapping (address => bool) public isUserAdded;
    mapping (address => bool) public isBlackListed;
    mapping(address => uint256) public availableBalance; 
    mapping(address=>bool) public isIntermediateClaimed;
    mapping(address=>bool ) public isLinearClaimed;
    mapping(address=>uint) public uintPerDay;


    uint[] public initialVestingAmountWithdrawThresholdTime;
    uint[] public intermediateVestingAmountWithdrawThresholdTime;
    uint[] public linearVestingAmountWithdrawThresholdTime;
    uint[] public initialAmountReleased=[0,0,50,100,200,0,0,0,0,30,200];
    uint[] public intermediateAmountReleased=[0,0,0,0,0,0,0,0,60,0,0];
    uint[] public linearVestingAmountReleased=[0,1000,950,900,800,1000,1000,1000,940,970,800]; // stores percentage
    uint[] public intermediateVestingTimePeriod=[0,0,0,0,0,0,0,0,30 days,0,0];
    uint[] public linearVestingTimePeriod=[0,660 days,540 days,365 days,180 days,900 days ,1080 days ,1050 days,720 days,1350 days,480 days];

    function addInvestors(Investor[] memory vest) external onlyOwner {
        for (uint i = 0;i < vest.length;i++) {
            require (!isUserAdded[vest[i].account],'User already whitelisted');
            require (!isBlackListed[vest[i].account],'User BlackListed');
            isUserAdded[vest[i].account] = true;
            vestingDetails memory vesting;
            vesting.investorType = vest[i].investorType;
            vesting.totalBalance = vest[i].amount * 1 ether;
            uint256 _amount=vest[i].amount* 1 ether;
            availableBalance[vest[i].account]+=_amount;
            vesting.initialToBeClaimed = (initialAmountReleased[vest[i].investorType] *_amount) / 1000;
            vesting.intermediateToBeClaimed = (intermediateAmountReleased[vest[i].investorType] * _amount)/ 1000;
            vesting.linearToBeClaimed = (linearVestingAmountReleased[vest[i].investorType] * _amount ) / 1000;
             uintPerDay[vest[i].account]= vesting.linearToBeClaimed/(linearVestingTimePeriod[vest[i].investorType]/ 1 days);
            InvestorDetails[vest[i].account] = vesting;
            emit InvestorAddress(vest[i].account,_amount,vest[i].investorType);
        }
    }

      function getInvestorDetails(address _addr) public view returns(vestingDetails memory){
        return InvestorDetails[_addr];
    }
    function getContractTokenBalance() external view returns(uint){
        return token.balanceOf(address(this));
    }


    function withdraw() external nonReentrant{
        isIntermediateClaimed[msg.sender]=true;
        require (isUserAdded[msg.sender],'User Not Added');
        require (!isBlackListed[msg.sender],'User BlackListed');
        require (!InvestorDetails[msg.sender].hasLinearClaimed,'Vesting: All Amount Claimed');


        if (initialAmountReleased[InvestorDetails[msg.sender].investorType] == 0 && intermediateAmountReleased[InvestorDetails[msg.sender].investorType] > 0 && InvestorDetails[msg.sender].intermediateClaimed == 0)
                 {
                     InvestorDetails[msg.sender].lastClaimTime = intermediateVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
                 }
        else if (initialAmountReleased[InvestorDetails[msg.sender].investorType] == 0 && intermediateAmountReleased[InvestorDetails[msg.sender].investorType] == 0 && InvestorDetails[msg.sender].linearClaimed == 0 )
                {
                    InvestorDetails[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
                }

        (uint amount, uint returnType) = getVestingBalance(msg.sender);
        require(returnType != 4,'Time Period is Not Over');
        if (returnType == 1) {
            require (amount >0,'Initial Vesting: 0 amount');
            InvestorDetails[msg.sender].hasInitialClaimed = true;
            InvestorDetails[msg.sender].initialClaimed += amount;
            token.safeTransfer(msg.sender, amount);
            if (intermediateAmountReleased[InvestorDetails[msg.sender].investorType] > 0)
                InvestorDetails[msg.sender].lastClaimTime = intermediateVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
            else if (intermediateAmountReleased[InvestorDetails[msg.sender].investorType] == 0 )
                InvestorDetails[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
                 availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        } else if (returnType == 2) {
            require (amount >0,'Intermediate Vesting: 0 amount');
            InvestorDetails[msg.sender].lastClaimTime = block.timestamp;
            InvestorDetails[msg.sender].intermediateClaimed+=amount;
            
            require (InvestorDetails[msg.sender].intermediateToBeClaimed >= InvestorDetails[msg.sender].intermediateClaimed,'Intermediate Vesting: Cannot Claim More');
            if (InvestorDetails[msg.sender].intermediateToBeClaimed ==  InvestorDetails[msg.sender].intermediateClaimed)
            {
                InvestorDetails[msg.sender].hasIntermediateClaim = true;
                InvestorDetails[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime[InvestorDetails[msg.sender].investorType];
            }
            token.safeTransfer(msg.sender, amount);
            availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        }
        else {
            require (amount >0,'Linear Vesting: 0 amount');
            InvestorDetails[msg.sender].lastClaimTime = block.timestamp;
            InvestorDetails[msg.sender].linearClaimed += amount;
            require (InvestorDetails[msg.sender].linearToBeClaimed >= InvestorDetails[msg.sender].linearClaimed,'Linear Besting: Cannot Claim More');
            if (InvestorDetails[msg.sender].linearToBeClaimed == InvestorDetails[msg.sender].linearClaimed)
            {
                InvestorDetails[msg.sender].hasLinearClaimed = true;
            }
            isLinearClaimed[msg.sender]=true;
            token.safeTransfer(msg.sender, amount);
          availableBalance[msg.sender]-=amount;
            emit VestingAmountTaken(msg.sender, amount);
        }
    }

    //@dev Contract Setters

    function setRewardTokenAddress (address _tokenAddress) public onlyOwner {
        require(!isRewardTokenSet,"Already Reward Token Set");
        isRewardTokenSet=true;
        token = IERC20(_tokenAddress);
        emit SetRewardToken(msg.sender, _tokenAddress);
    }
    
    function setDates (uint startTime) external onlyOwner {
        require(!isVestingStarted,"Vesting Started");
        isVestingStarted=true;
        globalStartTime = startTime;
        initialVestingAmountWithdrawThresholdTime = [0,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime,startTime];
        intermediateVestingAmountWithdrawThresholdTime = [0,0,0,0,0,0,0,0,startTime + 14 days,0,0];
        linearVestingAmountWithdrawThresholdTime= [0,startTime+ 60 days ,startTime + 1 days ,startTime + 1 days,startTime +  1 days ,startTime + 180 days,startTime + 365 days,startTime + 30 days,startTime + 180 days, startTime + 90 days,startTime + 1 days];

    }
   

    //@dev Get Details About Vesting Time Period
    function getVestingBalance(address _userAddress) public view returns (uint, uint) {
        if (!InvestorDetails[_userAddress].hasInitialClaimed &&
            block.timestamp >= initialVestingAmountWithdrawThresholdTime[InvestorDetails[_userAddress].investorType] &&
            InvestorDetails[_userAddress].initialToBeClaimed > 0) {return (InvestorDetails[_userAddress].initialToBeClaimed, 1);}
        else if (
            !InvestorDetails[_userAddress].hasIntermediateClaim &&
            InvestorDetails[_userAddress].intermediateToBeClaimed > 0 &&
            block.timestamp >= intermediateVestingAmountWithdrawThresholdTime[InvestorDetails[_userAddress].investorType]) {
            (uint balance,uint _bal) = intermediateVestStatus(_userAddress);
           // console.log('Balance',balance);
            return (balance,_bal);
        }
        else if (!InvestorDetails[_userAddress].hasLinearClaimed && InvestorDetails[_userAddress].linearToBeClaimed > 0 && block.timestamp >= linearVestingAmountWithdrawThresholdTime[InvestorDetails[_userAddress].investorType]) return (linearVestingDetails(_userAddress),3);
        else return (0,4);
    }

    function intermediateVestStatus(address _userAddress) public view returns (uint,uint) {
        uint lastClaimTime = InvestorDetails[_userAddress].lastClaimTime;
        uint timeDifference;
        uint[11] memory intermediateArray = [0,0,0,0,0,0,0,0,globalStartTime + 14 days,0,0];// give Intermediate time
        if (block.timestamp <= intermediateVestingTimePeriod[InvestorDetails[_userAddress].investorType]+intermediateArray[InvestorDetails[_userAddress].investorType])
        {
            if(!isIntermediateClaimed[_userAddress]){
             timeDifference=block.timestamp-intermediateArray[InvestorDetails[_userAddress].investorType];
            }else{
             timeDifference = block.timestamp - lastClaimTime;
            }
            
        }
        else
        {
            //@dev to return people the exact amount if the intermediate vesting period is over
           return(InvestorDetails[_userAddress].intermediateToBeClaimed - InvestorDetails[_userAddress].intermediateClaimed,2);
        }

        timeDifference = timeDifference / 1 days;
        uint intermediateReleaseTimeSpan = intermediateVestingTimePeriod[InvestorDetails[_userAddress].investorType];
        uint totalIntermediateFund = InvestorDetails[_userAddress].intermediateToBeClaimed;
        uint perDayFund = totalIntermediateFund / (intermediateReleaseTimeSpan / 1 days);
        uint price = perDayFund * timeDifference;
        return (price,2);
    }


    function linearVestingDetails(address _userAddress) public view returns (uint) {
        uint lastClaimTime = InvestorDetails[_userAddress].lastClaimTime;
        uint timeDifference;
        uint[11] memory linearTime =[0,globalStartTime+ 60 days ,globalStartTime + 1 days ,globalStartTime + 1 days,globalStartTime +  1 days ,globalStartTime + 180 days,globalStartTime + 365 days,globalStartTime + 30 days,globalStartTime + 180 days, globalStartTime + 90 days,globalStartTime + 1 days];
        if (block.timestamp <= linearVestingTimePeriod[InvestorDetails[_userAddress].investorType]+linearTime[InvestorDetails[_userAddress].investorType]) {
             if(!isLinearClaimed[_userAddress]){

                    timeDifference=block.timestamp-linearTime[InvestorDetails[_userAddress].investorType];
             }else{
                 timeDifference = block.timestamp - lastClaimTime;
             }
        }
        else
        {
            //@dev to return people the exact amount if the intermediate vesting period is over
            return(InvestorDetails[_userAddress].linearToBeClaimed - InvestorDetails[_userAddress].linearClaimed);
        }

        timeDifference = timeDifference / 1 days;
        uint linearReleaseTimeSpan = linearVestingTimePeriod[InvestorDetails[_userAddress].investorType];
        uint totalIntermediateFund = InvestorDetails[_userAddress].linearToBeClaimed;
        uint perDayFund = totalIntermediateFund / (linearReleaseTimeSpan / 1 days);

        return perDayFund * timeDifference;
    }


    function getLinearVestEndTime(uint256 saletype) public view returns(uint){
        uint256 endDays=linearVestingAmountWithdrawThresholdTime[saletype]+linearVestingTimePeriod[saletype];
        return endDays;  
    }

    function blockUser(address[] memory blackListedAddresses) external onlyOwner {
        for (uint i=0; i< blackListedAddresses.length; i++) {
            isBlackListed[blackListedAddresses[i]] = true;
           emit  BlockedUser(blackListedAddresses[i]);
        }
    }

    function unBlockUser(address[] memory whitelistListedAddresses) external onlyOwner {
        for (uint i=0; i< whitelistListedAddresses.length; i++) {
            isBlackListed[whitelistListedAddresses[i]] = false;
            emit UnBlockedUsers(whitelistListedAddresses[i]);
        }
    }

    function extractETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
       emit  GetEth(msg.sender,address(this).balance );

    }

     function transferToken(address ERC20Address, uint256 value) public onlyOwner {
        require(value <= IERC20(ERC20Address).balanceOf(address(this)), 'Insufficient balance to withdraw');
        IERC20(ERC20Address).safeTransfer(msg.sender, value);
      emit   TransferredToke(ERC20Address, value);
    }


    function removeUser (address[] memory usersToRemove) external onlyOwner {
           require(globalStartTime==0,"Vesting Time Started");
        for (uint i=0; i< usersToRemove.length; i++) {
            removeSingleUser(usersToRemove[i]);
           emit RemoveUser(usersToRemove[i]);
        }
    }

    function removeSingleUser(address _userAddress)public onlyOwner{
        require(InvestorDetails[_userAddress].investorType>0,"Not a Investor");
        require(globalStartTime==0,"Vesting Time Started");
        availableBalance[_userAddress]=0;
        delete InvestorDetails[_userAddress];
        isUserAdded[_userAddress]=false;
         emit RemoveUser(_userAddress);
    }


}