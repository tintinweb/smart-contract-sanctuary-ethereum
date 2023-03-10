/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

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
interface IERC20PermitUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]


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
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/ArityV2_5.sol


pragma solidity ^0.8.7;
error Arity__NotValidState();
error Arity__TheClaimStateIsClosed();
error Arity__NotOwner();
error Arity__ClaimOutOfDate();
error Arity__SenderIsNotOwnerOfTokens();
error Arity__ActualDateOutOfSemesterRange();
error Arity__TheUserHasBeenPayedOnThisDrop();
error Arity__ErrorSendingClaim();
error Arity__FailToRetrieveBalance();

contract ArityClaimV2_5 {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    enum ClaimState {
        CLOSED,
        OPENED
    }

    uint256 private constant BASE_PRICE = 1385;

    ClaimState private s_claimState;
    uint256 private s_startPrivateClaimDate;
    uint256 private s_endPrivateClaimDate;
    uint256 private s_goldPrice;
    uint256 private s_goldGrams;
    address private i_owner;
    uint32 private mappingVersion;
    uint256 private mappingLength;
    uint32 private usersLength;
    IERC20 private usdt;
    address payable[] private s_nftOwner; // solo para pruebas
    bool private isInitialized;

    IERC20Upgradeable private usdtST;
    
    mapping(uint8 => mapping(address => uint8)) private payedUsers;
    struct UserInfo {
        address userAddress;
        uint32 silverTokens;
        uint32 goldTokens;
        uint32 blackTokens;
    }
    struct UserInfo2 {
        address userAddress;
        uint32 silverTokens;
        uint32 goldTokens;
    }
   
    mapping(uint32 => mapping(uint32 => UserInfo)) private allUsersInfo;
   
    
    mapping(address=>uint256) bonoPayedChristmas;
    bool private bonoState;
    mapping(uint32 => mapping(uint32 => UserInfo2)) private allUsersInfo2;
    function init() external {
        usdtST = IERC20Upgradeable(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
    }


    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Arity__NotOwner();
        }
        _;
    }

    /**
     * @dev funcion que entrega a cada usuario la cantidad correspondiente
     */

    struct SlotInfo {
        uint8 actualDrop;
        uint8 actualSemester;
        uint256 goldTokens;
        uint256 silverTokens;
        uint256 blackTokens;
        uint16 porcentByNftsGold;
        uint256 valueByNft5YearsGold;
        uint16 porcentByNftsSilver;
        uint256 valueByNft5YearsSilver;
        int16 porcentByNftsBlack;
        int256 valueByNft5YearsBlack;
        uint256 gramsSemesterGold;
        uint256 gramsSemesterSilver;
        int256 gramsSemesterBlack;
        uint256 claimValueGold;
        uint256 claimValueSilver;
        int256 claimValueBlack;
        uint256 totalToClaim;
    }

    function calcClaim(bool isToPay, address _sender) public view returns(uint256){
        SlotInfo memory slot;

        slot.actualDrop = getActualDrop();
        slot.actualSemester = getActualSemester();

        slot.goldTokens = getGoldTokens(_sender); 
        slot.silverTokens = getSilverTokens(_sender);
        slot.blackTokens = getBlackTokens(_sender);
        uint16[11] memory porcentGold = getPorcentageGold();
        uint16[8] memory porcentSilver = getPorcentageSilver();
        int16[8] memory porcentBlack = getPorcentageBlack();
        uint16[9] memory porcentSemester = getPorcentageSemester();

        slot.porcentByNftsGold = 0;
        slot.valueByNft5YearsGold;

        slot.porcentByNftsSilver = 0;
        slot.valueByNft5YearsSilver;

        slot.porcentByNftsBlack = 0;
        slot.valueByNft5YearsBlack;
        if (getIsAllyBoost(_sender) > 0) {
            slot.porcentByNftsGold += 500;
            slot.porcentByNftsSilver += 500;
            slot.porcentByNftsBlack += 500;
        }

        if (slot.goldTokens > 0) {
            slot.porcentByNftsGold += porcentGold[
                getIterationGold(slot.goldTokens)
            ];
            slot.valueByNft5YearsGold =
                BASE_PRICE +
                ((BASE_PRICE * slot.porcentByNftsGold) / 10000) +
                200;
        }

        if (slot.silverTokens > 0) {
            slot.porcentByNftsSilver += porcentSilver[
                getIterationSilver(slot.silverTokens + slot.goldTokens)
            ];
            slot.valueByNft5YearsSilver =
                BASE_PRICE +
                ((BASE_PRICE * slot.porcentByNftsSilver) / 10000);
        }

        if (slot.blackTokens > 0) {
            slot.porcentByNftsBlack += porcentBlack[
                getIterationBlack(slot.goldTokens + slot.blackTokens)
            ];
            slot.valueByNft5YearsBlack =
                int(BASE_PRICE - uint32(35)) +
                ((int(BASE_PRICE - uint32(35)) * slot.porcentByNftsBlack) / 10000);
        }

        if(isToPay){
        slot.gramsSemesterGold = (slot.valueByNft5YearsGold *
            porcentSemester[slot.actualDrop]); //por cada NFT
        slot.gramsSemesterSilver = (slot.valueByNft5YearsSilver *
            porcentSemester[slot.actualDrop]); //por cada NFT
        slot.gramsSemesterBlack = (slot.valueByNft5YearsBlack *
            int16(porcentSemester[slot.actualDrop])); //por cada NFT
        }
        else{
        slot.gramsSemesterGold = (slot.valueByNft5YearsGold *
            porcentSemester[slot.actualSemester]); //por cada NFT
        slot.gramsSemesterSilver = (slot.valueByNft5YearsSilver *
            porcentSemester[slot.actualSemester]); //por cada NFT
        slot.gramsSemesterBlack = (slot.valueByNft5YearsBlack *
            int16(porcentSemester[slot.actualSemester])); //por cada NFT
        }
        

        slot.claimValueGold = (slot.gramsSemesterGold * (s_goldPrice / 100)); //por cada NFT
        slot.claimValueSilver = (slot.gramsSemesterSilver *
            (s_goldPrice / 100)); //por cada NFT
        slot.claimValueBlack = (slot.gramsSemesterBlack * int256((s_goldPrice / 100))); //por cada NFT

        slot.totalToClaim =
            (slot.claimValueGold * slot.goldTokens) +
            (slot.claimValueSilver * slot.silverTokens) +
            uint256(slot.claimValueBlack * int256(slot.blackTokens));


        slot.totalToClaim = slot.totalToClaim * 100000000000; // cantidad en wei
        return slot.totalToClaim;
    }

    function claim() external {
        if (s_claimState == ClaimState.CLOSED) {
            revert Arity__TheClaimStateIsClosed();
        }
        SlotInfo memory slot;
        slot.actualDrop = getActualDrop();

        if (slot.actualDrop == 99) {
            revert Arity__ClaimOutOfDate();
        }

        if (payedUsers[slot.actualDrop][msg.sender] == 1) {
            revert Arity__TheUserHasBeenPayedOnThisDrop();
        }

        slot.goldTokens = getGoldTokens(msg.sender); 
        slot.silverTokens = getSilverTokens(msg.sender);
        slot.blackTokens = getBlackTokens(msg.sender);
        if (slot.goldTokens == 0 && slot.silverTokens == 0 && slot.blackTokens == 0) {
            revert Arity__SenderIsNotOwnerOfTokens();
        }

        payedUsers[slot.actualDrop][msg.sender] = 1;

        address payable userAddres = payable(msg.sender);

        uint256 valueToPay = (calcClaim(true, msg.sender))/1000000000000;// cantidad en USDT
        require(usdtST.balanceOf(address(this)) > 0, "Not Enougth");
        if(slot.actualDrop == 0){
            valueToPay -= bonoPayedChristmas[msg.sender];
        }
        usdtST.safeTransfer(userAddres, valueToPay); //transaccion en USDT

    }




    /**
     * @dev Extrae todo el balance del contrato
     */
    function retrieveBalance() external onlyOwner {
        require(usdtST.balanceOf(address(this)) > 0, "Not Enougth");
        usdtST.safeTransfer(i_owner, usdtST.balanceOf(address(this)));
    }


    //-----------------------------------------------------------------------------------------Bono function

    /**
     * @dev Reclama el bono de navidad de 50 dolares
     */
    function bono() external returns(uint256) {
        require(bonoState == true, "Currently the distribution of the bonus is closed");
        uint32 userTokensGold = getGoldTokens(msg.sender); 
        uint32 userTokensSilver = getSilverTokens(msg.sender);
        uint32 userTokensBlack = getBlackTokens(msg.sender);
        require((userTokensGold + userTokensSilver + userTokensBlack) > 0, "User is not owner of tokens");
        require(bonoPayedChristmas[msg.sender] < 1, "User has been payed");

        uint256 amount = (userTokensGold + userTokensSilver + userTokensBlack)*50000000;
        bonoPayedChristmas[msg.sender] = amount;
        usdtST.safeTransfer(msg.sender, amount);
        return amount;

    }
    /**
     * @dev abre y cierra el state para poder reclamar el bono
     */
    function toggleBonoState() external onlyOwner{
        bonoState = !bonoState;
    }
    /**
     * @dev getter del bono
     */
    function getBonoState() external view returns(bool){
        return bonoState;
    }
    /**
     * @dev getter de la cantidad de dinero que se le entrego a la persona
     */
    function getBonoPayedByWallet (address _userWallet) external view returns(uint256){
        return bonoPayedChristmas[_userWallet];
    }

    /**
     * ----------------------------------------------------------------------------------------- Setters
     */
    function setAddresses(address[] memory _addresses, uint32[] memory _silverTokens, uint32[] memory _goldTokens, uint32[] memory _blackTokens) external onlyOwner {
        mappingVersion+=1;
        mappingLength = _addresses.length;
        for(uint32 i = 0; i < _addresses.length; i++){
            allUsersInfo[mappingVersion][i] = UserInfo(_addresses[i],_silverTokens[i],_goldTokens[i],_blackTokens[i]);
        }
    }


    function setClaimState(uint8 _state) public onlyOwner {
        if (_state == 0) {
            s_claimState = ClaimState.CLOSED;
        } else if (_state == 1) {
            s_claimState = ClaimState.OPENED;
        } else {
            revert Arity__NotValidState();
        }
    }

    function setGoldPrice(uint256 _goldPrice) public onlyOwner {
        s_goldPrice = _goldPrice;
    }

    /**
     * ----------------------------------------------------------------------------------------- Getters
     */
    function getAlllUsersInfo() public view returns(UserInfo[] memory){
        UserInfo[] memory allInfo = new UserInfo[](mappingLength);

        for (uint32 i = 0; i < mappingLength; i++) {
            allInfo[i] = allUsersInfo[mappingVersion][i];
        }

        return allInfo;
    }



    function getOwner() public view returns(address){
    return i_owner;
    }
    

    function getBalanceClaim() public view onlyOwner returns (uint256) {
        return usdtST.balanceOf(address(this));
        //return address(this).balance;
    }

    function getClaimState() public view returns (ClaimState) {
        return s_claimState;
    }

    function getGoldPrice() public view returns (uint256) {
        return s_goldPrice;
    }

    function getActualDrop() public view returns (uint8) {
        uint32[9] memory DropDates = getDropDates();
        uint8 actualDrop = 99;
        for (uint8 i = 0; i < DropDates.length; i++) {
            if (
                block.timestamp > DropDates[i] &&
                block.timestamp < (DropDates[i] + 3 weeks)
            ) {
                actualDrop = i;
                break;
            }
        }
        return actualDrop;
    }

    function getActualSemester() public view returns (uint8) {
        uint32[9] memory DropDates = getDropDates();
        uint8 actualSemester = 99;
        uint32 lasdDate = 0;
        for (uint8 i = 0; i < DropDates.length; i++) {
            if (
                block.timestamp > lasdDate + 3 weeks &&
                block.timestamp < (DropDates[i] + 3 weeks)
            ) {
                actualSemester = i;
                break;
            }
            else{
                lasdDate = DropDates[i];
            }
        }
        return actualSemester;
    }

    function getDropDates() public pure returns (uint32[9] memory) {
        return [
            1682812800, //2023-04-30
            1698624000, //2023-10-30 1682899200
            1714435200, //2024-04-30
            1730246400, //2024-10-30
            1745971200, //2025-04-30
            1761782400, //2025-10-30
            1777507200, //2026-04-30
            1793318400, //2026-10-30
            1809043200 //2027-04-30
        ]; // fechas cada 6 meses desde abril 28 2023 hasta abril 30 2027
    }

    function getPorcentageSilver() public pure returns (uint16[8] memory) {
        return [0, 1000, 1500, 2000, 2500, 3000, 3500, 4000];
    }

    function getPorcentageGold() public pure returns (uint16[11] memory) {
        return [
            2000,
            3500,
            4000,
            4500,
            5000,
            5500,
            6000,
            6500,
            7000,
            7500,
            8000
        ];
    }

    function getPorcentageBlack() public pure returns (int16[8] memory) {
        return [
            -4075,
            -3038,
            -2593,
            -2000,
            -1112,
            0,
            962,
            1481
        ];
    }

    function getPorcentageSemester() public pure returns (uint16[9] memory) {
        return [3448, 7389, 7389, 7389, 12315, 14778, 14778, 16256, 16256];
    }

    function getIterationGold(uint256 _goldTokens) public pure returns (uint8) {
        uint8[10] memory ranges = [1, 5, 10, 20, 25, 30, 35, 40, 45, 50];
        uint8 lastPosition = 0;
        uint8 result = 10;
        for (uint8 i = 0; i < ranges.length; i++) {
            if (_goldTokens > lastPosition && _goldTokens <= ranges[i]) {
                result = i;
                break;
            }
            lastPosition = ranges[i];
        }

        return result;
    }

    function getIterationSilver(uint256 _silverTokens)
        public
        pure
        returns (uint8)
    {
        uint8[7] memory ranges = [1, 5, 10, 20, 30, 40, 50];
        uint8 lastPosition = 0;
        uint8 result = 7;
        for (uint8 i = 0; i < ranges.length; i++) {
            if (_silverTokens > lastPosition && _silverTokens <= ranges[i]) {
                result = i;
                break;
            }
            lastPosition = ranges[i];
        }

        return result;
    }

    function getIterationBlack(uint256 _blackTokens) public pure returns (uint8) {
        uint8[7] memory ranges = [1, 5, 10, 20, 30, 40, 50];
        uint8 lastPosition = 0;
        uint8 result = 7;
        for (uint8 i = 0; i < ranges.length; i++) {
            if (_blackTokens > lastPosition && _blackTokens <= ranges[i]) {
                result = i;
                break;
            }
            lastPosition = ranges[i];
        }
        return result;
    }


    function getSilverTokens(address _tokenOwner) public view returns(uint32){
        uint32 tokensNumber = 0;
        for(uint32 i = 0; i < mappingLength; i++){
            if(allUsersInfo2[mappingVersion][i].userAddress == _tokenOwner)
            tokensNumber = allUsersInfo2[mappingVersion][i].silverTokens;

        }
        return tokensNumber; 
    }
    function getGoldTokens(address _tokenOwner) public view returns(uint32){
        uint32 tokensNumber = 0;
        for(uint32 i = 0; i < mappingLength; i++){
            if(allUsersInfo2[mappingVersion][i].userAddress == _tokenOwner)
            tokensNumber = allUsersInfo2[mappingVersion][i].goldTokens;

        }
        return tokensNumber; 
    }

    function getBlackTokens(address _tokenOwner) public view returns(uint32){
        uint32 tokensNumber = 0;
        for(uint32 i = 0; i < mappingLength; i++){
            if(allUsersInfo[mappingVersion][i].userAddress == _tokenOwner)
            tokensNumber = allUsersInfo[mappingVersion][i].blackTokens;

        }
        return tokensNumber; 
    }


     function getIsAllyBoost(address _sender) public view returns (uint256) {
        uint256 total = 0;
        //Enigma
        IERC20Upgradeable tokenEnigma = IERC20Upgradeable(0x0027FCb9c3605F30Bfadaa32a63d92DC62A94360);
        total += tokenEnigma.balanceOf(_sender);
        //EnigmaEconomy
        IERC20Upgradeable tokenEnigmaEconomy = IERC20Upgradeable(0x5298c6D5ac0f2964bbB27F496a8193CE78e8A8e6);
        total += tokenEnigmaEconomy.balanceOf(_sender);
        /* Test
        IERC20Upgradeable tokenTest = IERC20Upgradeable(0x7d54D6A85ed5E00de611c55CE1D0F675E396Cf0A);
        total += tokenTest.balanceOf(_sender);*/
        return total;
    }

function changeBonoDue(address[] memory _nftOwners , uint256[] memory _newDue) external onlyOwner {
        for (uint256 i = 0; i < _nftOwners.length; i++) {
            bonoPayedChristmas[_nftOwners[i]] = _newDue[i];
        }
    }
}