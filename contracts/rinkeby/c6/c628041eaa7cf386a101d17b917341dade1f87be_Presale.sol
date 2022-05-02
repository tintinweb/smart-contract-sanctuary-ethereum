/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
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




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

library Signature {

    function splitSignature(bytes memory sig) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

}



/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}




/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;
////import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


/** 
 *  SourceUnit: c:\Projects\ibl\sc-capital-dao\contracts\launchpad\Presale.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
////import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

////import "./../lib/Signature.sol";

interface ITokenVesting {

    function createRound(uint256 _idoId, uint256 _roundId, address _token, uint128 _startTime, uint128 _cliff, uint128 _vestingCliff, uint128 _vestingDuration, uint128 _tgePercent) external;
    function updateRound(uint256 _idoId, uint256 _roundId, address _token, uint128 _startTime, uint128 _cliff, uint128 _vestingCliff, uint128 _vestingDuration, uint128 _tgePercent) external;
    function lockToken(uint256 _idoId, uint256 _roundId, address _account, uint256 _amount) external;

}

interface IToken {

    function decimals() external view returns (uint8);

}

interface IRole {

    function isAdmin(address _account) external view returns (bool);
    function isOperator(address _account) external view returns (bool);

}

contract Presale is ContextUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20 for IERC20;
    using Signature for bytes32;

    event SignerUpdated(address signer);
    event TreasuryUpdated(address treasury);
    event TokenWithdrawed(address token, address to, uint256 amount);

    event SaleCreated(uint256 id, address token, address currency, uint128[3] startTimes, uint128[3] endTimes, uint128 price, uint128 totalSupply, uint128 tgeTime, uint128 tgePercent, uint128[3] vesting, uint128 referralPercent);
    event SaleUpdated(uint256 id, address token, address currency, uint128[3] startTimes, uint128[3] endTimes, uint128 price, uint128 totalSupply, uint128 tgeTime, uint128 tgePercent, uint128[3] vesting, uint128 referralPercent);
    event SaleEnabled(uint256 id);
    event SaleDisabled(uint256 id);

    event BoughtInPrimarySale(uint256 saleId, address account, uint256 amount, string referralCode, uint256 referralBonus);
    event BoughtInFCFS(uint256 saleId, address account, uint256 amount, string referralCode, uint256 referralBonus);

    uint256 public constant ONE_HUNDRED_PERCENT = 10000; // 100%

    IRole public role;

    ITokenVesting public vestingContract;

    address public referralContract;

    address public treasury;

    address public signer;

    struct Sale {
        address token;
        address currency;
        uint128 registrationStartTime;
        uint128 registrationEndTime;
        uint128 saleStartTime;
        uint128 saleEndTime;
        uint128 fcfsStartTime;
        uint128 fcfsEndTime;
        uint128 price;
        uint128 totalSupply;
        uint128 totalSold;
        uint128 totalParticipants;
        bool enable;
    }

    struct Referral {
        uint128 percent;
    }

    struct User {
        uint128 primarySaleBought;
        uint128 fcfsBought;
    }

    mapping(uint256 => Sale) public sales;

    mapping(uint256 => Referral) public referrals;

    mapping(uint256 => mapping(address => User)) public users;

    mapping(address => uint256[]) private _claims;

    mapping(address => uint256) public nonces;

    modifier onlyAdmin() {
        require(role.isAdmin(_msgSender()), "Presale: caller is not admin");
        _;
    }

    modifier onlyOperator() {
        require(role.isOperator(_msgSender()), "Presale: caller is not operator");
        _;
    }

    modifier saleExist(uint256 id) {
        require(sales[id].token != address(0), "Presale: sale does not exist");
        _;
    }

    modifier saleNotExist(uint256 id) {
        require(sales[id].token == address(0), "Presale: sale already existed");
        _;
    }

    modifier saleNotPause(uint256 id) {
        require(sales[id].enable, "Presale: sale was disabled");
        _;
    }

    function initialize(IRole _role, ITokenVesting _vestingContract, address _referralContract)
        public
        initializer
    {
        __Context_init();
        __ReentrancyGuard_init();

        address msgSender = _msgSender();

        signer = msgSender;
        treasury = msgSender;

        role = _role;
        vestingContract = _vestingContract;
        referralContract = _referralContract;
    }

    function enableSale(uint256 id)
        public
        onlyOperator
        saleExist(id)
    {
        sales[id].enable = true;

        emit SaleEnabled(id);
    }

    function disableSale(uint256 id)
        public
        onlyOperator
        saleExist(id)
    {
        sales[id].enable = false;

        emit SaleDisabled(id);
    }

    function _checkSaleParams(address token, address currency, uint128[3] memory startTimes, uint128[3] memory endTimes, uint128 price, uint128 totalSupply, uint128 tgeTime, uint128 tgePercent, uint128 referralPercent)
        internal
        pure
    {
        require(token != address(0), "Presale: token address is invalid");

        require(currency != address(0), "Presale: currency address is invalid");

        require(startTimes[0] <= endTimes[0], "Presale: registration time is invalid");

        require(startTimes[1] > 0 && startTimes[1] < endTimes[1], "Presale: sale time is invalid");

        require(startTimes[2] <= endTimes[2], "Presale: FCFS time is invalid");

        require(price > 0, "Presale: price is invalid");

        require(totalSupply > 0, "Presale: total supply is invalid");

        require(tgeTime > 0, "Presale: TGE time is invalid");

        require(tgePercent <= ONE_HUNDRED_PERCENT, "Presale: TGE percent is invalid");

        require(referralPercent <= ONE_HUNDRED_PERCENT, "Presale: referral percent is invalid");
    }

    function createSale(uint256 id, address token, address currency, uint128[3] memory startTimes, uint128[3] memory endTimes, uint128 price, uint128 totalSupply, uint128 tgeTime, uint128 tgePercent, uint128[3] memory vesting, uint128 referralPercent)
        external
        onlyOperator
        saleNotExist(id)
    {
        _checkSaleParams(token, currency, startTimes, endTimes, price, totalSupply, tgeTime, tgePercent, referralPercent);

        sales[id] = Sale(token, currency, startTimes[0], endTimes[0], startTimes[1], endTimes[1], startTimes[2], endTimes[2], price, totalSupply, 0, 0, true);

        referrals[id] = Referral(referralPercent);

        vestingContract.createRound(id, 1, token, tgeTime, vesting[0], vesting[1], vesting[2], tgePercent);

        emit SaleCreated(id, token, currency, startTimes, endTimes, price, totalSupply, tgeTime, tgePercent, vesting, referralPercent);
    }

    function updateSale(uint256 id, address token, address currency, uint128[3] memory startTimes, uint128[3] memory endTimes, uint128 price, uint128 totalSupply, uint128 tgeTime, uint128 tgePercent, uint128[3] memory vesting, uint128 referralPercent)
        external
        onlyOperator
        saleExist(id)
    {
        _checkSaleParams(token, currency, startTimes, endTimes, price, totalSupply, tgeTime, tgePercent, referralPercent);

        Sale storage sale = sales[id];

        require(totalSupply >= sale.totalSold, "Presale: total supply is invalid");

        if (sale.token != token) {
            sale.token = token;
        }

        if (sale.currency != currency) {
            sale.currency = currency;
        }

        if (sale.registrationStartTime != startTimes[0]) {
            sale.registrationStartTime = startTimes[0];
        }

        if (sale.registrationEndTime != endTimes[0]) {
            sale.registrationEndTime = endTimes[0];
        }

        if (sale.saleStartTime != startTimes[1]) {
            sale.saleStartTime = startTimes[1];
        }

        if (sale.saleEndTime != endTimes[1]) {
            sale.saleEndTime = endTimes[1];
        }

        if (sale.fcfsStartTime != startTimes[2]) {
            sale.fcfsStartTime = startTimes[2];
        }

        if (sale.fcfsEndTime != endTimes[2]) {
            sale.fcfsEndTime = endTimes[2];
        }

        if (sale.price != price) {
            sale.price = price;
        }

        if (sale.totalSupply != totalSupply) {
            sale.totalSupply = totalSupply;
        }

        if (referrals[id].percent != referralPercent) {
            referrals[id].percent = referralPercent;
        }

        vestingContract.updateRound(id, 1, token, tgeTime, vesting[0], vesting[1], vesting[2], tgePercent);

        emit SaleUpdated(id, token, currency, startTimes, endTimes, price, totalSupply, tgeTime, tgePercent, vesting, referralPercent);
    }

    function withdrawFund(IERC20 token, address to, uint256 amount)
        public
        onlyAdmin
        nonReentrant
    {
        require(to != address(0), "Presale: address is invalid");

        require(amount > 0, "Presale: amount is invalid");

        token.safeTransfer(to, amount);

        emit TokenWithdrawed(address(token), to, amount);
    }

    function setSigner(address addr)
        public
        onlyAdmin
    {
        require(addr != address(0), "Presale: address is invalid");

        signer = addr;

        emit SignerUpdated(addr);
    }

    function setTreasury(address addr)
        public
        onlyAdmin
    {
        require(addr != address(0), "Presale: address is invalid");

        treasury = addr;

        emit TreasuryUpdated(addr);
    }

    function _buy(uint256 saleId, uint256 amount, uint256 allocation, bytes memory signature, bool isPrimarySale, string memory referralCode)
        internal
        nonReentrant
        saleNotPause(saleId)
    {
        require(amount > 0, "Presale: amount is invalid");

        require(allocation > 0, "Presale: allocation is invalid");

        Sale storage sale = sales[saleId];

        address msgSender = _msgSender();

        // Avoids stack too deep error
        {
            bytes32 message = keccak256(abi.encodePacked(saleId, msgSender, amount, allocation, referralCode, nonces[msgSender], block.chainid, this)).prefixed();

            require(message.recoverSigner(signature) == signer, "Presale: signature is invalid");
        
            uint256 remain = sale.totalSupply - sale.totalSold;

            require(remain > 0, "Presale: sold out");

            if (amount > remain) {
                amount = remain;
            }

            User storage user = users[saleId][msgSender];

            if (user.primarySaleBought == 0 && user.fcfsBought == 0) {
                sale.totalParticipants++;

                _claims[msgSender].push(saleId);
            }

            if (isPrimarySale) {
                require(block.timestamp >= sale.saleStartTime && block.timestamp < sale.saleEndTime, "Presale: can not buy");

                require(user.primarySaleBought + amount <= allocation, "Presale: can not buy over allocation");

                user.primarySaleBought += uint128(amount);

            } else {
                require(block.timestamp >= sale.fcfsStartTime && block.timestamp < sale.fcfsEndTime, "Presale: can not buy");

                require(user.fcfsBought + amount <= allocation, "Presale: can not buy over allocation");
            
                user.fcfsBought += uint128(amount);
            }
        }

        nonces[msgSender]++;

        sale.totalSold += uint128(amount);

        uint8 decimal = IToken(sale.token).decimals();

        uint256 payment = amount * sale.price / (10 ** decimal);

        require(payment > 0, "Presale: payment is invalid");

        uint256 referralBonus = payment * referrals[saleId].percent / ONE_HUNDRED_PERCENT;

        payment -= referralBonus;

        IERC20(sale.currency).safeTransferFrom(msgSender, treasury, payment);

        IERC20(sale.currency).safeTransferFrom(msgSender, referralContract, referralBonus);

        IERC20(sale.token).safeTransfer(address(vestingContract), amount);

        vestingContract.lockToken(saleId, 1, msgSender, amount);

        if (isPrimarySale) {
            emit BoughtInPrimarySale(saleId, msgSender, amount, referralCode, referralBonus);

        } else {
            emit BoughtInFCFS(saleId, msgSender, amount, referralCode, referralBonus);
        }
    }

    function buyTokenInPrimarySale(uint256 saleId, uint256 amount, uint256 allocation, bytes memory signature, string memory referralCode)
        public
    {
        _buy(saleId, amount, allocation, signature, true, referralCode);
    }

    function buyTokenInFCFS(uint256 saleId, uint256 amount, uint256 allocation, bytes memory signature, string memory referralCode)
        public
    {
        _buy(saleId, amount, allocation, signature, false, referralCode);
    }

    function getClaims(address account, uint256 offset, uint256 limit)
        external
        view
        returns(uint256[] memory data)
    {
        uint256 max = _claims[account].length;

        if (offset >= max) {
            return data;
        }

        if (offset + limit < max) {
            max = offset + limit;
        }

        data = new uint256[](max - offset);

        uint256 cnt = 0;

        for (uint256 i = offset; i < max; i++) {
            data[cnt++] = _claims[account][i];
        }

        return data;
    }

    function getTotalClaims(address account)
        external
        view
        returns(uint256)
    {
        return _claims[account].length;
    }

}