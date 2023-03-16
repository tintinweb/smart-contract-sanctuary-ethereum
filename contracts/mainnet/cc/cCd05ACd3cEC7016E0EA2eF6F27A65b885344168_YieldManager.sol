// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IUniV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function totalSupply() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface ILockedStakingrewards {
    function balanceOf(address account) external view returns (uint256);
    function stakingToken() external view returns(address);
}

contract YieldManager is ReentrancyGuard {
    using SafeERC20 for IERC20;
    mapping(address => address) public affiliateLookup;
    mapping(address => address) public vestingLookup;

    event AffiliateSet(address indexed sponsor, address indexed client);
    event NewOwner(address owner);
    event NewCanSetSponsor(address canSet, bool status);
    event NewStaking(address staking);
    event NewLPStaking(address lpStaking);
    event NewYFlow(address yflow);
    event NewLPFactor(uint lpFactor);
    event VestingSet(address client, address vesting);

    // struct configStruct
    // val1 client:  withdrawal fee sponsor: % of fee
    struct configStruct {
        uint level;
        uint val1;
        uint val2;
        uint val3;
        uint val4;
    }

    configStruct[] public clientLevels;
    configStruct[] public sponsorLevels;

    address[] public stakingAddresses;
    address[] public lpStakingAddresses;

    address public owner;
    mapping(address => bool) public canSetSponsor;

    address public YFlowAddress;
    uint public lpFactor = 1;

    // only owner modifier
    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    // only owner view
    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    constructor(address _YFlow) {
        owner = msg.sender;
        YFlowAddress = _YFlow;
        //set client levels initial
        clientLevels.push(
            configStruct({
                level: 0,
                val1: 0,
                // performance fee
                val2: 1500,
                // mgmt fee
                val3: 100,
                // mgmt fee fixed
                val4: 200
            })
        );
        clientLevels.push(
            configStruct({
                level: 500 * 10 ** 18,
                val1: 0,
                val2: 1250,
                val3: 100,
                val4: 200
            })
        );
        clientLevels.push(
            configStruct({
                level: 10000 * 10 ** 18,
                val1: 0,
                val2: 1000,
                val3: 100,
                val4: 200
            })
        );
        clientLevels.push(
            configStruct({
                level: 100000 * 10 ** 18,
                val1: 0,
                val2: 750,
                val3: 75,
                val4: 125
            })
        );
        clientLevels.push(
            configStruct({
                level: 1000000 * 10 ** 18,
                val1: 0,
                val2: 500,
                val3: 75,
                val4: 125
            })
        );

        //set sponsor levels initial
        sponsorLevels.push(
            configStruct({
                level: 0,
                val1: 0,
                val2: 0,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 500 * 10 ** 18,
                val1: 1000,
                val2: 1500,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 10000 * 10 ** 18,
                val1: 1500,
                val2: 2500,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 100000 * 10 ** 18,
                val1: 2000,
                val2: 5000,
                val3: 0,
                val4: 0
            })
        );
        sponsorLevels.push(
            configStruct({
                level: 500000 * 10 ** 18,
                val1: 2500,
                val2: 7500,
                val3: 0,
                val4: 0
            })
        );
    }

    function setYflow(address _Yflow) public onlyOwner {
        YFlowAddress = _Yflow;
        emit NewYFlow(YFlowAddress);
    }

    function setLPFactor(uint _lpFactor) public onlyOwner {
        lpFactor = _lpFactor;
        emit NewLPFactor(lpFactor);
    }

    //updates client levels
    function setClientLevels(uint[] memory levels, uint[] memory val1s, uint[] memory val2s, uint[] memory val3s, uint[] memory val4s) public onlyOwner {
        require(levels.length == val1s.length, "length mismatch");
        require(val1s.length == val2s.length, "length mismatch");
        require(val2s.length == val3s.length, "length mismatch");
        require(val3s.length == val4s.length, "length mismatch");
        delete clientLevels;

        for (uint i=0; i<levels.length; i++) {
            clientLevels.push(
                configStruct({
                    level: levels[i],
                    val1: val1s[i],
                    val2: val2s[i],
                    val3: val3s[i],
                    val4: val4s[i]
            })
            );
        }
    }

    //updates client levels
    function setSponsorLevels(uint[] memory levels, uint[] memory val1s, uint[] memory val2s, uint[] memory val3s, uint[] memory val4s) public onlyOwner {
        require(levels.length == val1s.length, "length mismatch");
        require(val1s.length == val2s.length, "length mismatch");
        require(val2s.length == val3s.length, "length mismatch");
        require(val3s.length == val4s.length, "length mismatch");
        delete sponsorLevels;

        for (uint i=0; i<levels.length; i++) {
            sponsorLevels.push(
                configStruct({
                    level: levels[i],
                    val1: val1s[i],
                    val2: val2s[i],
                    val3: val3s[i],
                    val4: val4s[i]
            })
            );
        }
    }

    // returns sponsor
    function getAffiliate(address client) public view returns (address) {
        return affiliateLookup[client];
    }

    function setAffiliate(address client, address sponsor) public {
        require (canSetSponsor[msg.sender] == true, "not allowed to set sponsor");
        require(affiliateLookup[client] == address(0), "sponsor already set");
        affiliateLookup[client] = sponsor;
        emit AffiliateSet(sponsor, client);
    }

    function ownerSetAffiiliate(address client, address sponsor) public onlyOwner {
        affiliateLookup[client] = sponsor;
        emit AffiliateSet(sponsor, client);
    }

    function ownerSetVestingAddress(address client, address vesting) public onlyOwner {
        vestingLookup[client] = vesting;
        emit VestingSet(client, vesting);
    }

    function setStakingAddress(address[] memory stakingContract) public onlyOwner {
        delete stakingAddresses;

        for (uint i=0; i<stakingContract.length; i++) {
            stakingAddresses.push(stakingContract[i]);
            emit NewStaking(stakingContract[i]);
        }
    }

    function setLPStakingAddress(address[] memory stakingContract) public onlyOwner {
        delete lpStakingAddresses;
        for (uint i=0; i<stakingContract.length; i++) {
            lpStakingAddresses.push(stakingContract[i]);
            emit NewLPStaking(stakingContract[i]);
        }
    }

    function calcLPTokenBonus(uint liquidity, address lpAddress) public view returns (uint) {
        address _token0 = IUniV2Pair(lpAddress).token0();                                // gas savings
        address _token1 = IUniV2Pair(lpAddress).token1();                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(lpAddress);
        uint balance1 = IERC20(_token1).balanceOf(lpAddress);

        uint _totalSupply = IUniV2Pair(lpAddress).totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        uint amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        uint amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution

        if ( _token0 == YFlowAddress) {
            return amount0 * lpFactor;
        }

        return amount1 * lpFactor;
    }

    function getUserStakedAmount(address user) public view returns (uint) {
        uint stakedTokens;

        // check normal staking
        for (uint i = 0; i < stakingAddresses.length; i++) {
            uint tempStaked = ILockedStakingrewards(stakingAddresses[i])
                .balanceOf(user);
            stakedTokens += tempStaked;

            // check if user is in vesting
                if (vestingLookup[user] != (address(0))) {
                    uint tempStakedVester = ILockedStakingrewards(stakingAddresses[i])
                        .balanceOf(vestingLookup[user]);
                    stakedTokens += tempStakedVester;
            }
        }

        // check lp staking
        for (uint i = 0; i < lpStakingAddresses.length; i++) {
            uint tempStaked = ILockedStakingrewards(lpStakingAddresses[i])
                .balanceOf(user);

            address lpAddress = ILockedStakingrewards(lpStakingAddresses[i]).stakingToken();
            uint userCalc = calcLPTokenBonus(tempStaked,lpAddress);
            stakedTokens += userCalc;
        }

        return stakedTokens;
    }

    function getUserFactors(
        address user,
        uint typer
    ) public view returns (uint, uint, uint, uint) {
        uint stakedtokens = getUserStakedAmount(user);

        // if its for client
        if (typer == 0) {
            // check normal staking
            if (stakedtokens < clientLevels[1].level) {
                return (
                    clientLevels[0].val1,
                    clientLevels[0].val2,
                    clientLevels[0].val3,
                    clientLevels[0].val4
                );
            } else if (
                stakedtokens >= clientLevels[1].level &&
                stakedtokens < clientLevels[2].level
            ) {
                return (
                    clientLevels[1].val1,
                    clientLevels[1].val2,
                    clientLevels[1].val3,
                    clientLevels[1].val4
                );
            } else if (
                stakedtokens >= clientLevels[2].level &&
                stakedtokens < clientLevels[3].level
            ) {
                return (
                    clientLevels[2].val1,
                    clientLevels[2].val2,
                    clientLevels[2].val3,
                    clientLevels[2].val4
                );
            } else if (
                stakedtokens >= clientLevels[3].level &&
                stakedtokens < clientLevels[4].level
            ) {
                return (
                    clientLevels[3].val1,
                    clientLevels[3].val2,
                    clientLevels[3].val3,
                    clientLevels[3].val4
                );
            } else {
                return (
                    clientLevels[4].val1,
                    clientLevels[4].val2,
                    clientLevels[4].val3,
                    clientLevels[4].val4
                );
            }
        }

        // else we calculate sponsor
        if (stakedtokens < sponsorLevels[1].level) {
            return (
                sponsorLevels[0].val1,
                sponsorLevels[0].val2,
                sponsorLevels[0].val3,
                sponsorLevels[0].val4
            );
        } else if (
            stakedtokens >= sponsorLevels[1].level &&
            stakedtokens < sponsorLevels[2].level
        ) {
            return (
                sponsorLevels[1].val1,
                sponsorLevels[1].val2,
                sponsorLevels[1].val3,
                sponsorLevels[1].val4
            );
        } else if (
            stakedtokens >= sponsorLevels[2].level &&
            stakedtokens < sponsorLevels[3].level
        ) {
            return (
                sponsorLevels[2].val1,
                sponsorLevels[2].val2,
                sponsorLevels[2].val3,
                sponsorLevels[2].val4
            );
        } else if (
            stakedtokens >= sponsorLevels[3].level &&
            stakedtokens < sponsorLevels[4].level
        ) {
            return (
                sponsorLevels[3].val1,
                sponsorLevels[3].val2,
                sponsorLevels[3].val3,
                sponsorLevels[3].val4
            );
        } else {
            return (
                sponsorLevels[4].val1,
                sponsorLevels[4].val2,
                sponsorLevels[4].val3,
                sponsorLevels[4].val4
            );
        }
    }

    function newOwner(address newOwner_) external {
        require(msg.sender == owner, "Only factory owner");
        require(newOwner_ != address(0), "No zero address for newOwner");

        owner = newOwner_;
        emit NewOwner(owner);
    }

    function setCanSetSponsor(address factoryContract, bool val) external onlyOwner {
        canSetSponsor[factoryContract] = val;
        emit NewCanSetSponsor(factoryContract, val);
    }
}