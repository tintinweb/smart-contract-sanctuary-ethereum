/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/
            
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
     * ////IMPORTANT: The same issues {IERC20-approve} has related to transaction
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



/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/
            

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/
            
pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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



/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/
            
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



/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/
            

pragma solidity ^0.8.0;


////import "./Address.sol";

////import "./IERC20.sol";
////import "./IERC20Permit.sol";
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




/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/
            
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
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




/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/
            

pragma solidity ^0.8.0;

////import "./Context.sol";

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


/** 
 *  SourceUnit: c:\Users\HP\Desktop\IBCO\hardhat-security-fcc\contracts\Staking.sol
*/

pragma solidity ^0.8.4;

////import "./lib/Ownable.sol";
////import "./lib/AggregatorV3Interface.sol";
////import "./lib/SafeERC20.sol";

contract ContractStaking is Ownable {
    using SafeERC20 for IERC20;

    AggregatorV3Interface internal priceFeedBNB;
    AggregatorV3Interface internal priceFeedBUSD;

    address[][] internal stakeholders;
    IERC20 private DakShow;
    address internal ColdWallet;

    IERC20 internal BUSD;
    IERC20 internal BNB;

    // Address owner contract
    uint256 public totalDakRewardInContract;
    uint256 public priceDAK = 285 * 10**13;
    uint256 public constant DECIMALS = 10**18; // DakShow Token has the same decimals as BNB (18)

    struct Staking {
        uint256 id;
        address owner; // nguoi tao
        uint256 duration; // thoi gian staking
        uint256 totalStakes; // so luong token ma user stake
        uint256 interestRate; // lai suat
        string typeToken; // symbol token
        uint256 timeUnlocks; // thoi gian unlock
        address[] userStaking; // ds user stake
    }

    struct StakeInfo {
        uint256 id;
        bool isStake; // trang thai user co dang stake hay khong
        uint256 startTS;
        uint256 endTS;
        uint256 totalUserClaim; // so lan user da nhan
        uint256 amountStake; // so luong token user stake
        uint256 amountReward; // so luong token dak ma user co the nhan moi lan, toi da 11
        uint256 totalReward; // so luong DAK toi da user co the nhan
        uint256 claimed; // so luong token dak user da rut = moi lan x so lan
    }

    mapping(uint256 => mapping(address => StakeInfo)) public stakeInfos;

    Staking[] public Stakings;

    event CreateStakingBNB(
        uint256 id,
        address owner,
        uint256 time,
        uint256 interestRate,
        uint256 timeUnlocks
    );

    event CreateStakingBUSD(
        uint256 id,
        address owner,
        uint256 time,
        uint256 interestRate,
        uint256 timeUnlocks
    );

    event CreateUserStake(
        uint256 id,
        string typeToken,
        uint256 balance,
        uint256 reward,
        uint256 rDak
    );

    event AddBalanceUserStake(
        uint256 id,
        string typeToken,
        uint256 balance,
        uint256 rStake,
        uint256 rDak,
        uint256 time
    );

    event OwnerSetPriceDAK(uint256 newPrice, address onwer);

    event OwnerSetInterestRate(uint256 newInterestRate, address onwer);

    event ClaimDAK(uint256 id, address userClaim, uint256 amount);

    event ClaimStakeBNB(uint256 id, address userClaim, uint256 amount);

    event ClaimStakeBUSD(uint256 id, address userClaim, uint256 amount);

    event OwnerWithdrawFunds(
        address owner,
        uint256 balanceBNB,
        uint256 balanceBUSD,
        uint256 balanceDAK
    );

    // Time staking

    mapping(uint256 => mapping(address => uint256)) internal DakShowWithdraw;

    mapping(uint256 => mapping(address => uint256)) internal unLocks;

    constructor(
        address _coldWallet,
        IERC20 _DAK,
        IERC20 _busd,
        IERC20 _bnb
    ) {
        require(_coldWallet != address(0), "ColdWallet must be different from address(0)");
        ColdWallet = _coldWallet;
        DakShow = _DAK;
        BUSD = _busd;
        BNB = _bnb;

        priceFeedBNB = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

        priceFeedBUSD = AggregatorV3Interface(0xAb5c49580294Aff77670F839ea425f5b78ab3Ae7);
    }

    function getLatestPriceBNB() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedBNB.latestRoundData();
        return price;
    }

    function getLatestPriceBUSD() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeedBUSD.latestRoundData();
        return price;
    }

    /**
     * @notice ADMIN Function
     *
     */
    function createStakingWithBNB(
        uint256 duration,
        uint256 interestRate,
        uint256 timeUnlocks
    ) external onlyOwner {
        require(duration > timeUnlocks, "Duration must be greater than timeUnlocks");

        uint256 id = Stakings.length;

        Staking memory newStaking = Staking({
            id: id,
            owner: msg.sender,
            duration: duration,
            totalStakes: 0,
            interestRate: interestRate,
            typeToken: "BNB",
            timeUnlocks: timeUnlocks,
            userStaking: new address[](0)
        });

        Stakings.push(newStaking);

        emit CreateStakingBNB(id, msg.sender, duration, interestRate, timeUnlocks);
    }

    function createStakingWithBUSD(
        uint256 duration,
        uint256 interestRate,
        uint256 timeUnlocks
    ) external onlyOwner {
        require(duration > timeUnlocks, "Duration must be greater than timeUnlocks");

        uint256 id = Stakings.length;

        Staking memory newStaking = Staking({
            id: id,
            owner: msg.sender,
            duration: duration,
            totalStakes: 0,
            interestRate: interestRate,
            typeToken: "BUSD",
            timeUnlocks: timeUnlocks,
            userStaking: new address[](0)
        });

        Stakings.push(newStaking);

        emit CreateStakingBNB(id, msg.sender, duration, interestRate, timeUnlocks);
    }

    function withdrawFunds() external onlyOwner returns (bool) {
        require(msg.sender == ColdWallet, "Only Owner can withdraw funds");
        uint256 balanceBNB = BNB.balanceOf(address(this));
        uint256 balanceBUSD = BUSD.balanceOf(address(this));
        uint256 balanceDAK = DakShow.balanceOf(address(this));

        emit OwnerWithdrawFunds(msg.sender, balanceBNB, balanceBUSD, balanceDAK);

        SafeERC20.safeTransfer(BNB, msg.sender, balanceBNB);
        SafeERC20.safeTransfer(BUSD, msg.sender, balanceBUSD);
        SafeERC20.safeTransfer(DakShow, msg.sender, balanceDAK);

        return true;
    }

    function setInterestRate(uint256 id, uint256 newInterestRate) external onlyOwner {
        emit OwnerSetInterestRate(newInterestRate, msg.sender);

        Stakings[id].interestRate = newInterestRate;
    }

    function setPriceDak(uint256 newPrice) external onlyOwner {
        require(newPrice >= 285 * 10**13, "newPrice >=  0.00285 USDT");

        emit OwnerSetPriceDAK(newPrice, msg.sender);

        priceDAK = newPrice;
    }

    // User function

    function addStakeholderBNB(uint256 id, uint256 amount) external {
        require(!stakeInfos[id][msg.sender].isStake, "The address is staking");

        require(BNB.balanceOf(msg.sender) >= amount, "Insufficient BNB token in address");

        require(BNB.allowance(msg.sender, address(this)) >= amount, "Caller must approve first");

        int256 price = getLatestPriceBNB();

        uint256 rStake = uint256(price) / 10**8;

        uint256 sumReward = calculateReward(id, amount, rStake);

        Stakings[id].userStaking.push(msg.sender);

        Stakings[id].totalStakes += amount;

        uint256 reward = (sumReward * Stakings[id].timeUnlocks) / (Stakings[id].duration);

        StakeInfo memory newStakeInfo = StakeInfo({
            id: id,
            isStake: true, // trang thai user co dang stake hay khong
            startTS: block.timestamp,
            endTS: block.timestamp + Stakings[id].duration,
            totalUserClaim: 0, // so lan user da nhan
            amountStake: amount, // so luong token user stake
            amountReward: reward, // so luong token dak ma user co the nhan moi lan, toi da = (endTS - startTS) / Stakings[id].timeUnlocks
            totalReward: sumReward, // so luong token DAK toi da user se nhan
            claimed: 0
        });

        stakeInfos[id][msg.sender] = newStakeInfo;

        emit CreateUserStake(id, Stakings[id].typeToken, amount, sumReward, priceDAK);

        SafeERC20.safeTransferFrom(BNB, msg.sender, ColdWallet, amount);
    }

    function addStakeholderBUSD(uint256 id, uint256 amount) external {
        require(!stakeInfos[id][msg.sender].isStake, "The address is staking");

        require(BUSD.balanceOf(msg.sender) >= amount, "Insufficient BUSD token in address");

        require(BUSD.allowance(msg.sender, address(this)) >= amount, "Caller must approve first");

        int256 price = getLatestPriceBUSD();

        uint256 rStake = uint256(price) / 10**8;

        uint256 sumReward = calculateReward(id, amount, rStake);

        Stakings[id].userStaking.push(msg.sender);

        Stakings[id].totalStakes += amount;

        uint256 reward = (sumReward * Stakings[id].timeUnlocks) / (Stakings[id].duration);

        StakeInfo memory newStakeInfo = StakeInfo({
            id: id,
            isStake: true, // trang thai user co dang stake hay khong
            startTS: block.timestamp,
            endTS: block.timestamp + Stakings[id].duration,
            totalUserClaim: 0, // so lan user da nhan
            amountStake: amount, // so luong token user stake
            amountReward: reward, // so luong token dak ma user co the nhan moi lan, toi da = (endTS - startTS) / Stakings[id].timeUnlocks
            totalReward: sumReward, // so luong token DAK toi da user se nhan
            claimed: 0
        });

        stakeInfos[id][msg.sender] = newStakeInfo;

        emit CreateUserStake(id, Stakings[id].typeToken, amount, sumReward, priceDAK);

        SafeERC20.safeTransferFrom(BUSD, msg.sender, ColdWallet, amount);
    }
    

    function removeStakeholder(uint256 id, address userAddress) internal {
        
        uint256 index = Stakings[id].userStaking.length;
        for (uint256 i = 0; i < Stakings[id].userStaking.length; i++) {
            if (Stakings[id].userStaking[i] == userAddress) {
                index = i;
            }
        }

        for (uint256 i = index; i < Stakings[id].userStaking.length - 1; i++) {
            Stakings[id].userStaking[i] = Stakings[id].userStaking[i + 1];
        }

        delete Stakings[id].userStaking[Stakings[id].userStaking.length - 1];
        Stakings[id].userStaking.pop();
    }

    // Public view function

    function nextTimeClaim(uint256 id, address userAddress) public view returns (uint256) {
        uint256 totalCalim = (block.timestamp - stakeInfos[id][userAddress].startTS) /
            Stakings[id].timeUnlocks;

        if (block.timestamp >= stakeInfos[id][userAddress].endTS) {
            return stakeInfos[id][userAddress].endTS;
        }

        uint256 nextTime = stakeInfos[id][userAddress].startTS +
            (totalCalim + 1) *
            Stakings[id].timeUnlocks;

        return nextTime;
    }

    /**
        * @notice A method to take all existing stakings.
        
    */
    function getStakings() public view returns (Staking[] memory) {
        return Stakings;
    }

    /**
       * @notice A method to get the number of users staking at a specified staking
      
       */
    function getUserInStaking(uint256 id) public view returns (address[] memory) {
        return Stakings[id].userStaking;
    }

    /**
       * @notice A method to calculate interest is based on the formula (x*rStake*interest rate)/(rDak)
      
    */
    function calculateReward(
        uint256 id,
        uint256 amount,
        uint256 rStake
    ) public view returns (uint256) {
        return (amount * rStake * Stakings[id].interestRate * DECIMALS) / (priceDAK * 100);
    }

    function getBalanceInStaking(uint256 id) public view returns (uint256) {
        return Stakings[id].totalStakes;
    }

    function getStakeInfos(uint256 id, address userAddress) public view returns (StakeInfo memory) {
        return stakeInfos[id][userAddress];
    }

    function getTotalDakReward() public view returns (uint256) {
        return totalDakRewardInContract;
    }

    // ---------- Withdraw Function ----------

    function withdrawReward(uint256 id) external returns (bool) {
        uint256 maxClaim = (stakeInfos[id][msg.sender].endTS - stakeInfos[id][msg.sender].startTS) /
            Stakings[id].timeUnlocks;

        uint256 currentClaim = (block.timestamp - stakeInfos[id][msg.sender].startTS) /
            Stakings[id].timeUnlocks;

        if (currentClaim >= maxClaim) {
            currentClaim = maxClaim - 1;
        }

        uint256 amountWithdraw = stakeInfos[id][msg.sender].amountReward *
            (currentClaim - stakeInfos[id][msg.sender].totalUserClaim);

        require(stakeInfos[id][msg.sender].isStake, "User not staking");

        require(
            DakShow.balanceOf(address(this)) >= amountWithdraw,
            "Not enough DAK tokens to transfer"
        );

        require(
            maxClaim > stakeInfos[id][msg.sender].totalUserClaim,
            "Exceed the number of withdrawals"
        );

        require(
            currentClaim > stakeInfos[id][msg.sender].totalUserClaim,
            "Not enough time to withdraw"
        );

        require(amountWithdraw > 0, "amountWithdraw is not 0");

        totalDakRewardInContract += amountWithdraw;

        stakeInfos[id][msg.sender].totalUserClaim = currentClaim;

        stakeInfos[id][msg.sender].claimed += amountWithdraw;

        emit ClaimDAK(id, msg.sender, amountWithdraw);

        SafeERC20.safeTransfer(DakShow, msg.sender, amountWithdraw);

        return true;
    }

    /**
     * @notice A method to withdraw the last deposit and bonus tokens
     */
    function withdrawStake(uint256 id) external returns (bool) {
        uint256 maxClaim = (stakeInfos[id][msg.sender].endTS - stakeInfos[id][msg.sender].startTS) /
            Stakings[id].timeUnlocks;

        uint256 amountDAK = stakeInfos[id][msg.sender].totalReward -
            stakeInfos[id][msg.sender].claimed;

        require(block.timestamp >= stakeInfos[id][msg.sender].endTS, "Not enough time to withdraw");

        require(stakeInfos[id][msg.sender].isStake, "User not staking");

        require(DakShow.balanceOf(address(this)) >= amountDAK, "Not enough DAK tokens to transfer");

        removeStakeholder(id, msg.sender);

        totalDakRewardInContract += amountDAK;

        uint256 amountStake = stakeInfos[id][msg.sender].amountStake;

        stakeInfos[id][msg.sender].totalUserClaim = maxClaim;

        stakeInfos[id][msg.sender].isStake = false;

        stakeInfos[id][msg.sender].amountStake = 0;

        emit ClaimDAK(id, msg.sender, amountDAK);

        if (
            keccak256(abi.encodePacked(Stakings[id].typeToken)) ==
            keccak256(abi.encodePacked("BNB"))
        ) {
            require(BNB.balanceOf(address(this)) >= amountDAK, "Not enough BNB tokens to transfer");

            emit ClaimStakeBNB(id, msg.sender, amountStake);

            SafeERC20.safeTransfer(BNB, msg.sender, amountStake);
        }
        if (
            keccak256(abi.encodePacked(Stakings[id].typeToken)) ==
            keccak256(abi.encodePacked("BUSD"))
        ) {
            require(
                BUSD.balanceOf(address(this)) >= amountDAK,
                "Not enough BUSD tokens to transfer"
            );

            emit ClaimStakeBUSD(id, msg.sender, amountStake);

            SafeERC20.safeTransfer(BUSD, msg.sender, amountStake);
        }

        SafeERC20.safeTransfer(DakShow, msg.sender, amountDAK);

        return true;
    }
}