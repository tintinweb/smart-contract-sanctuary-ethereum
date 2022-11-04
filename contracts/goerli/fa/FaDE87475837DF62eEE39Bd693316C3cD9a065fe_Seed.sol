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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

/*

██████╗░██████╗░██╗███╗░░░███╗███████╗██████╗░░█████╗░░█████╗░
██╔══██╗██╔══██╗██║████╗░████║██╔════╝██╔══██╗██╔══██╗██╔══██╗
██████╔╝██████╔╝██║██╔████╔██║█████╗░░██║░░██║███████║██║░░██║
██╔═══╝░██╔══██╗██║██║╚██╔╝██║██╔══╝░░██║░░██║██╔══██║██║░░██║
██║░░░░░██║░░██║██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝
╚═╝░░░░░╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░

*/

// SPDX-License-Identifier: GPL-3.0
// PrimeDAO Seed contract. Smart contract for seed phases of liquid launch.
// Copyright (C) 2022 PrimeDao

// solium-disable operator-whitespace
/* solhint-disable space-after-comma */
/* solhint-disable max-states-count */
// solium-disable linebreak-style
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PrimeDAO Seed contract V2
 * @dev   Smart contract for seed phases of Prime Launch.
 */
contract Seed {
    using SafeERC20 for IERC20;
    // Locked parameters
    address public beneficiary; // The address that recieves fees
    address public admin; // The address of the admin of this contract
    uint256 public softCap; // The minimum to be reached to consider this Seed successful,
    //                          expressed in Funding tokens
    uint256 public hardCap; // The maximum of Funding tokens to be raised in the Seed
    uint256 public seedAmountRequired; // Amount of seed required for distribution (buyable + tip)
    uint256 public totalBuyableSeed; // Amount of buyable seed tokens
    uint256 public startTime; // Start of the buyable period
    uint256 public endTime; // End of the buyable period
    uint256 public vestingStartTime; // timestamp for when vesting starts, by default == endTime,
    //                                  otherwise when maximumReached is reached
    bool public permissionedSeed; // Set to true if only allowlisted adresses are allowed to participate
    IERC20 public seedToken; // The address of the seed token being distributed
    IERC20 public fundingToken; // The address of the funding token being exchanged for seed token
    bytes public metadata; // IPFS Hash wich has all the Seed parameters stored

    uint256 internal constant PRECISION = 10**18; // used for precision e.g. 1 ETH = 10**18 wei; toWei("1") = 10**18

    // Contract logic
    bool public closed; // is the distribution closed
    bool public paused; // is the distribution paused
    bool public isFunded; // distribution can only start when required seed tokens have been funded
    bool public initialized; // is this contract initialized [not necessary that it is funded]
    bool public minimumReached; // if the softCap[minimum limit of funding token] is reached
    bool public maximumReached; // if the hardCap[maximum limit of funding token] is reached

    uint256 public totalFunderCount; // Total funders that have contributed.
    uint256 public seedRemainder; // Amount of seed tokens remaining to be distributed
    uint256 public seedClaimed; // Amount of seed token claimed by the user.
    uint256 public fundingCollected; // Amount of funding tokens collected by the seed contract.
    uint256 public fundingWithdrawn; // Amount of funding token withdrawn from the seed contract.

    uint256 public price; // Price of the Seed token, expressed in Funding token with precision 10**18
    Tip public tip; // State which stores all the Tip parameters

    ContributorClass[] public classes; // Array of contributor classes

    mapping(address => FunderPortfolio) public funders; // funder address to funder portfolio

    // ----------------------------------------
    //      EVENTS
    // ----------------------------------------

    event SeedsPurchased(
        address indexed recipient,
        uint256 indexed amountPurchased,
        uint256 indexed seedRemainder
    );
    event TokensClaimed(address indexed recipient, uint256 indexed amount);
    event FundingReclaimed(
        address indexed recipient,
        uint256 indexed amountReclaimed
    );
    event MetadataUpdated(bytes indexed metadata);
    event TipClaimed(uint256 indexed amountClaimed);

    // ----------------------------------------
    //      STRUCTS
    // ----------------------------------------

    // Struct which stores all the information of a given funder address
    struct FunderPortfolio {
        uint8 class; // Contibutor class id
        uint256 totalClaimed; // Total amount of seed tokens claimed
        uint256 fundingAmount; // Total amount of funding tokens contributed
        bool allowlist; // If permissioned Seed, funder needs to be allowlisted
    }
    // Struct which stores all the parameters of a contributor class
    struct ContributorClass {
        bytes32 className; // Name of the class
        uint256 classCap; // Amount of tokens that can be donated for class
        uint256 individualCap; // Amount of tokens that can be donated by specific contributor
        uint256 vestingCliff; // Cliff after which the vesting starts to get released
        uint256 vestingDuration; // Vesting duration for class
        uint256 classFundingCollected; // Total amount of staked tokens
    }
    // Struct which stores all the parameters related to the Tip
    struct Tip {
        uint256 tipPercentage; // Total amount of tip percentage,
        uint256 vestingCliff; // Tip cliff duration denominated in seconds.
        uint256 vestingDuration; // Tip vesting period duration denominated in seconds.
        uint256 tipAmount; // Tip amount denominated in Seed tokens
        uint256 totalClaimed; // Total amount of Seed tokens already claimed
    }

    // ----------------------------------------
    //      MODIFIERS
    // ----------------------------------------

    modifier claimable() {
        require(
            endTime < block.timestamp || maximumReached || closed,
            "Seed: Error 346"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Seed: Error 322");
        _;
    }

    modifier isActive() {
        require(!closed, "Seed: Error 348");
        require(!paused, "Seed: Error 349");
        _;
    }

    modifier isLive() {
        require(
            !closed && block.timestamp < vestingStartTime,
            "Seed: Error 350"
        );
        _;
    }

    modifier isNotClosed() {
        require(!closed, "Seed: Error 348");
        _;
    }

    modifier hasNotStarted() {
        require(block.timestamp < startTime, "Seed: Error 344");
        _;
    }

    modifier classRestriction(uint256 _classCap, uint256 _individualCap) {
        require(
            _individualCap <= _classCap && _classCap <= hardCap,
            "Seed: Error 303"
        );
        require(_classCap > 0, "Seed: Error 101");
        _;
    }

    modifier classBatchRestrictions(
        bytes32[] memory _classNames,
        uint256[] memory _classCaps,
        uint256[] memory _individualCaps,
        uint256[] memory _vestingCliffs,
        uint256[] memory _vestingDurations,
        address[][] memory _allowlist
    ) {
        require(
            _classNames.length == _classCaps.length &&
                _classNames.length == _individualCaps.length &&
                _classNames.length == _vestingCliffs.length &&
                _classNames.length == _vestingDurations.length &&
                _classNames.length == _allowlist.length,
            "Seed: Error 102"
        );
        require(_classNames.length <= 100, "Seed: Error 304");
        require(classes.length + _classNames.length <= 256, "Seed: Error 305");
        _;
    }

    /**
      * @dev                            Initialize Seed.
      * @param _beneficiary             The address that recieves fees.
      * @param _admin                   The address of the admin of this contract. Funds contract
                                            and has permissions to allowlist users, pause and close contract.
      * @param _tokens                  Array containing two params:
                                            - The address of the seed token being distributed.
      *                                     - The address of the funding token being exchanged for seed token.
      * @param _softAndHardCap          Array containing two params:
                                            - the minimum funding token collection threshold in wei denomination.
                                            - the highest possible funding token amount to be raised in wei denomination.
      * @param _price                   Price of a SeedToken, expressed in fundingTokens, with precision of 10**18
      * @param _startTimeAndEndTime     Array containing two params:
                                            - Distribution start time in unix timecode.
                                            - Distribution end time in unix timecode.
      * @param _defaultClassParameters  Array containing three params:
											- Individual buying cap for de default class, expressed in precision 10*18
											- Cliff duration, denominated in seconds.
                                            - Vesting period duration, denominated in seconds.
      * @param _permissionedSeed        Set to true if only allowlisted adresses are allowed to participate.
      * @param _allowlistAddresses      Array of addresses to be allowlisted for the default class, at creation time
      * @param _tip                     Array of containing three parameters:
											- Total amount of tip percentage expressed as a % (e.g. 45 / 100 * 10**18 = 45% fee, 10**16 = 1%)
											- Tip vesting period duration denominated in seconds.																								
											- Tipcliff duration denominated in seconds.	
    */
    function initialize(
        address _beneficiary,
        address _admin,
        address[] memory _tokens,
        uint256[] memory _softAndHardCap,
        uint256 _price,
        uint256[] memory _startTimeAndEndTime,
        uint256[] memory _defaultClassParameters,
        bool _permissionedSeed,
        address[] memory _allowlistAddresses,
        uint256[] memory _tip
    ) external {
        require(!initialized, "Seed: Error 001");
        initialized = true;

        beneficiary = _beneficiary;
        admin = _admin;
        softCap = _softAndHardCap[0];
        hardCap = _softAndHardCap[1];
        startTime = _startTimeAndEndTime[0];
        endTime = _startTimeAndEndTime[1];
        vestingStartTime = _startTimeAndEndTime[1] + 1;
        permissionedSeed = _permissionedSeed;
        seedToken = IERC20(_tokens[0]);
        fundingToken = IERC20(_tokens[1]);
        price = _price;

        totalBuyableSeed = (_softAndHardCap[1] * PRECISION) / _price;
        // Calculate tip
        uint256 tipAmount = (totalBuyableSeed * _tip[0]) / PRECISION;
        tip = Tip(_tip[0], _tip[1], _tip[2], tipAmount, 0);
        // Add default class
        _addClass(
            bytes32(""),
            _softAndHardCap[1],
            _defaultClassParameters[0],
            _defaultClassParameters[1],
            _defaultClassParameters[2]
        );

        // Add allowlist to the default class
        if (_permissionedSeed == true && _allowlistAddresses.length > 0) {
            uint256 arrayLength = _allowlistAddresses.length;
            for (uint256 i; i < arrayLength; ++i) {
                _addToClass(0, _allowlistAddresses[i]); // Value 0 for the default class
            }
            _addAddressesToAllowlist(_allowlistAddresses);
        }

        seedRemainder = totalBuyableSeed;
        seedAmountRequired = tipAmount + seedRemainder;
    }

    /**
     * @dev                     Buy seed tokens.
     * @param _fundingAmount    The amount of funding tokens to contribute.
     */
    function buy(uint256 _fundingAmount) external isActive returns (uint256) {
        FunderPortfolio storage funder = funders[msg.sender];
        require(!permissionedSeed || funder.allowlist, "Seed: Error 320");

        ContributorClass memory userClass = classes[funder.class];
        require(!maximumReached, "Seed: Error 340");
        require(_fundingAmount > 0, "Seed: Error 101");
        // Checks if contributor has exceeded his personal or class cap.
        require(
            (userClass.classFundingCollected + _fundingAmount) <=
                userClass.classCap,
            "Seed: Error 360"
        );

        require(
            (funder.fundingAmount + _fundingAmount) <= userClass.individualCap,
            "Seed: Error 361"
        );

        require(
            endTime >= block.timestamp && startTime <= block.timestamp,
            "Seed: Error 362"
        );

        if (!isFunded) {
            require(
                seedToken.balanceOf(address(this)) >= seedAmountRequired,
                "Seed: Error 343"
            );
            isFunded = true;
        }

        if ((fundingCollected + _fundingAmount) > hardCap) {
            _fundingAmount = hardCap - fundingCollected;
        }

        uint256 seedAmount = (_fundingAmount * PRECISION) / price;
        // total fundingAmount should not be greater than the hardCap

        fundingCollected += _fundingAmount;
        classes[funder.class].classFundingCollected += _fundingAmount;
        // the amount of seed tokens still to be distributed
        seedRemainder = seedRemainder - seedAmount;
        if (fundingCollected >= softCap) {
            minimumReached = true;
        }

        if (fundingCollected >= hardCap) {
            maximumReached = true;
            vestingStartTime = block.timestamp;
        }

        //functionality of addFunder
        if (funder.fundingAmount == 0) {
            totalFunderCount++;
        }
        funder.fundingAmount += _fundingAmount;

        // Here we are sending amount of tokens to pay for seed tokens to purchase

        fundingToken.safeTransferFrom(
            msg.sender,
            address(this),
            _fundingAmount
        );

        emit SeedsPurchased(msg.sender, seedAmount, seedRemainder);

        return (seedAmount);
    }

    /**
     * @dev                     Claim vested seed tokens.
     * @param _claimAmount      The amount of seed token a users wants to claim.
     */
    function claim(uint256 _claimAmount) external claimable {
        require(minimumReached, "Seed: Error 341");

        uint256 amountClaimable;

        amountClaimable = calculateClaimFunder(msg.sender);
        require(amountClaimable > 0, "Seed: Error 380");

        require(amountClaimable >= _claimAmount, "Seed: Error 381");

        funders[msg.sender].totalClaimed += _claimAmount;

        seedClaimed += _claimAmount;

        seedToken.safeTransfer(msg.sender, _claimAmount);

        emit TokensClaimed(msg.sender, _claimAmount);
    }

    function claimTip() external claimable returns (uint256) {
        uint256 amountClaimable;

        amountClaimable = calculateClaimBeneficiary();
        require(amountClaimable > 0, "Seed: Error 380");

        tip.totalClaimed += amountClaimable;

        seedToken.safeTransfer(beneficiary, amountClaimable);

        emit TipClaimed(amountClaimable);

        return amountClaimable;
    }

    /**
     * @dev         Returns funding tokens to user.
     */
    function retrieveFundingTokens() external returns (uint256) {
        require(startTime <= block.timestamp, "Seed: Error 344");
        require(!minimumReached, "Seed: Error 342");
        FunderPortfolio storage tokenFunder = funders[msg.sender];
        uint256 fundingAmount = tokenFunder.fundingAmount;
        require(fundingAmount > 0, "Seed: Error 380");
        seedRemainder += seedAmountForFunder(msg.sender);
        totalFunderCount--;
        tokenFunder.fundingAmount = 0;
        fundingCollected -= fundingAmount;
        classes[tokenFunder.class].classFundingCollected -= fundingAmount;

        fundingToken.safeTransfer(msg.sender, fundingAmount);

        emit FundingReclaimed(msg.sender, fundingAmount);

        return fundingAmount;
    }

    // ----------------------------------------
    //      ADMIN FUNCTIONS
    // ----------------------------------------

    /**
     * @dev                     Changes all de classes given in the _classes parameter, editing
                                    the different parameters of the class, and allowlist addresses
                                    if applicable.
     * @param _classes           Class for changing.
     * @param _classNames        The name of the class
     * @param _classCaps         The total cap of the contributor class, denominated in Wei.
     * @param _individualCaps    The personal cap of each contributor in this class, denominated in Wei.
     * @param _vestingCliffs     The cliff duration, denominated in seconds.
     * @param _vestingDurations  The vesting duration for this contributors class.
     * @param _allowlists        Array of addresses to be allowlisted
     */
    function changeClassesAndAllowlists(
        uint8[] memory _classes,
        bytes32[] memory _classNames,
        uint256[] memory _classCaps,
        uint256[] memory _individualCaps,
        uint256[] memory _vestingCliffs,
        uint256[] memory _vestingDurations,
        address[][] memory _allowlists
    )
        external
        onlyAdmin
        hasNotStarted
        isNotClosed
        classBatchRestrictions(
            _classNames,
            _classCaps,
            _individualCaps,
            _vestingCliffs,
            _vestingDurations,
            _allowlists
        )
    {
        for (uint8 i; i < _classes.length; ++i) {
            _changeClass(
                _classes[i],
                _classNames[i],
                _classCaps[i],
                _individualCaps[i],
                _vestingCliffs[i],
                _vestingDurations[i]
            );

            if (permissionedSeed) {
                _addAddressesToAllowlist(_allowlists[i]);
            }
            for (uint256 j; j < _allowlists[i].length; ++j) {
                _addToClass(_classes[i], _allowlists[i][j]);
            }
        }
    }

    /**
     * @dev                     Pause distribution.
     */
    function pause() external onlyAdmin isActive {
        paused = true;
    }

    /**
     * @dev                     Unpause distribution.
     */
    function unpause() external onlyAdmin {
        require(closed != true, "Seed: Error 348");
        require(paused == true, "Seed: Error 351");

        paused = false;
    }

    /**
      * @dev                Shut down contributions (buying).
                            Supersedes the normal logic that eventually shuts down buying anyway.
                            Also shuts down the admin's ability to alter the allowlist.
    */
    function close() external onlyAdmin {
        // close seed token distribution
        require(!closed, "Seed: Error 348");

        if (block.timestamp < vestingStartTime) {
            vestingStartTime = block.timestamp;
        }

        closed = true;
        paused = false;
    }

    /**
     * @dev                     retrieve remaining seed tokens back to project.
     * @param _refundReceiver   refund receiver address
     */
    function retrieveSeedTokens(address _refundReceiver) external onlyAdmin {
        // transfer seed tokens back to admin
        /*
            Can't withdraw seed tokens until buying has ended and
            therefore the number of distributable seed tokens can no longer change.
        */
        require(
            closed || maximumReached || block.timestamp >= endTime,
            "Seed: Error 382"
        );
        uint256 seedTokenBalans = seedToken.balanceOf(address(this));
        if (!minimumReached) {
            require(seedTokenBalans > 0, "Seed: Error 345");
            // subtract tip from Seed tokens
            uint256 retrievableSeedAmount = seedTokenBalans -
                (tip.tipAmount - tip.totalClaimed);
            seedToken.safeTransfer(_refundReceiver, retrievableSeedAmount);
        } else {
            // seed tokens to transfer = buyable seed tokens - totalSeedDistributed
            uint256 totalSeedDistributed = totalBuyableSeed - seedRemainder;
            uint256 amountToTransfer = seedTokenBalans -
                (totalSeedDistributed - seedClaimed) -
                (tip.tipAmount - tip.totalClaimed);
            seedToken.safeTransfer(_refundReceiver, amountToTransfer);
        }
    }

    /**
     * @dev                         Add classes and allowlists to the contract by batching them into one
                                        function call. It adds allowlists to the created classes if applicable
     * @param _classNames           The name of the class
     * @param _classCaps            The total cap of the contributor class, denominated in Wei.
     * @param _individualCaps       The personal cap of each contributor in this class, denominated in Wei.
     * @param _vestingCliffs        The cliff duration, denominated in seconds.
     * @param _vestingDurations     The vesting duration for this contributors class.
     * @param _allowlist            Array of addresses to be allowlisted
     */
    function addClassesAndAllowlists(
        bytes32[] memory _classNames,
        uint256[] memory _classCaps,
        uint256[] memory _individualCaps,
        uint256[] memory _vestingCliffs,
        uint256[] memory _vestingDurations,
        address[][] memory _allowlist
    )
        external
        onlyAdmin
        hasNotStarted
        isNotClosed
        classBatchRestrictions(
            _classNames,
            _classCaps,
            _individualCaps,
            _vestingCliffs,
            _vestingDurations,
            _allowlist
        )
    {
        uint256 currentClassId = uint256(classes.length);
        for (uint8 i; i < _classNames.length; ++i) {
            _addClass(
                _classNames[i],
                _classCaps[i],
                _individualCaps[i],
                _vestingCliffs[i],
                _vestingDurations[i]
            );
        }
        uint256 arrayLength = _allowlist.length;
        if (permissionedSeed) {
            for (uint256 i; i < arrayLength; ++i) {
                _addAddressesToAllowlist(_allowlist[i]);
            }
        }
        for (uint256 i; i < arrayLength; ++i) {
            uint256 numberOfAddresses = _allowlist[i].length;
            for (uint256 j; j < numberOfAddresses; ++j) {
                _addToClass(uint8(currentClassId), _allowlist[i][j]);
            }
            ++currentClassId;
        }
    }

    /**
     * @dev                     Add multiple addresses to contributor classes, and if applicable
                                    allowlist them.
     * @param _buyers           Array of addresses to be allowlisted
     * @param _classes          Array of classes assigned in batch
     */
    function allowlist(address[] memory _buyers, uint8[] memory _classes)
        external
        onlyAdmin
        isLive
    {
        if (permissionedSeed) {
            _addAddressesToAllowlist(_buyers);
        }
        _addMultipleAdressesToClass(_buyers, _classes);
    }

    /**
     * @dev                     Remove address from allowlist.
     * @param _buyer             Address which needs to be un-allowlisted
     */
    function unAllowlist(address _buyer) external onlyAdmin isLive {
        require(permissionedSeed == true, "Seed: Error 347");

        funders[_buyer].allowlist = false;
    }

    /**
     * @dev                     Withdraw funds from the contract
     */
    function withdraw() external onlyAdmin {
        /*
            Admin can't withdraw funding tokens until buying has ended and
            therefore contributors can no longer withdraw their funding tokens.
        */
        require(minimumReached, "Seed: Error 383");
        fundingWithdrawn = fundingCollected;
        // Send the entire seed contract balance of the funding token to the sale’s admin
        fundingToken.safeTransfer(
            msg.sender,
            fundingToken.balanceOf(address(this))
        );
    }

    /**
     * @dev                     Updates metadata.
     * @param _metadata         Seed contract metadata, that is IPFS Hash
     */
    function updateMetadata(bytes memory _metadata) external {
        require(initialized != true || msg.sender == admin, "Seed: Error 321");
        metadata = _metadata;
        emit MetadataUpdated(_metadata);
    }

    // ----------------------------------------
    //      INTERNAL FUNCTIONS
    // ----------------------------------------

    /**
     * @dev                         Change parameters in the class given in the _class parameter
     * @param _class                Class for changing.
     * @param _className            The name of the class
     * @param _classCap             The total cap of the contributor class, denominated in Wei.
     * @param _individualCap        The personal cap of each contributor in this class, denominated in Wei.
     * @param _vestingCliff         The cliff duration, denominated in seconds.
     * @param _vestingDuration      The vesting duration for this contributors class.
     */
    function _changeClass(
        uint8 _class,
        bytes32 _className,
        uint256 _classCap,
        uint256 _individualCap,
        uint256 _vestingCliff,
        uint256 _vestingDuration
    ) internal classRestriction(_classCap, _individualCap) {
        require(_class < classes.length, "Seed: Error 302");

        classes[_class].className = _className;
        classes[_class].classCap = _classCap;
        classes[_class].individualCap = _individualCap;
        classes[_class].vestingCliff = _vestingCliff;
        classes[_class].vestingDuration = _vestingDuration;
    }

    /**
     * @dev                             Internal function that adds a class to the classes array
     * @param _className                The name of the class
     * @param _classCap                 The total cap of the contributor class, denominated in Wei.
     * @param _individualCap            The personal cap of each contributor in this class, denominated in Wei.
     * @param _vestingCliff             The cliff duration, denominated in seconds.
     * @param _vestingDuration          The vesting duration for this contributors class.
     */
    function _addClass(
        bytes32 _className,
        uint256 _classCap,
        uint256 _individualCap,
        uint256 _vestingCliff,
        uint256 _vestingDuration
    ) internal classRestriction(_classCap, _individualCap) {
        classes.push(
            ContributorClass(
                _className,
                _classCap,
                _individualCap,
                _vestingCliff,
                _vestingDuration,
                0
            )
        );
    }

    /**
     * @dev                       Set contributor class.
     * @param _classId              Class of the contributor.
     * @param _buyer            Address of the contributor.
     */
    function _addToClass(uint8 _classId, address _buyer) internal {
        require(_classId < classes.length, "Seed: Error 302");
        funders[_buyer].class = _classId;
    }

    /**
     * @dev                       Set contributor class.
     * @param _buyers          Address of the contributor.
     * @param _classes            Class of the contributor.
     */
    function _addMultipleAdressesToClass(
        address[] memory _buyers,
        uint8[] memory _classes
    ) internal {
        uint256 arrayLength = _buyers.length;
        require(_classes.length == arrayLength, "Seed: Error 102");

        for (uint256 i; i < arrayLength; ++i) {
            _addToClass(_classes[i], _buyers[i]);
        }
    }

    /**
     * @dev                     Add address to allowlist.
     * @param _buyers        Address which needs to be allowlisted
     */
    function _addAddressesToAllowlist(address[] memory _buyers) internal {
        uint256 arrayLength = _buyers.length;
        for (uint256 i; i < arrayLength; ++i) {
            funders[_buyers[i]].allowlist = true;
        }
    }

    function _calculateClaim(
        uint256 seedAmount,
        uint256 vestingCliff,
        uint256 vestingDuration,
        uint256 totalClaimed
    ) internal view returns (uint256) {
        if (block.timestamp < vestingStartTime) {
            return 0;
        }

        // Check cliff was reached
        uint256 elapsedSeconds = block.timestamp - vestingStartTime;
        if (elapsedSeconds < vestingCliff) {
            return 0;
        }

        // If over vesting duration, all tokens vested
        if (elapsedSeconds >= vestingDuration) {
            return seedAmount - totalClaimed;
        } else {
            uint256 amountVested = (elapsedSeconds * seedAmount) /
                vestingDuration;
            return amountVested - totalClaimed;
        }
    }

    // ----------------------------------------
    //      GETTER FUNCTIONS
    // ----------------------------------------

    /**
     * @dev                     Calculates the maximum claim of the funder address
     * @param _funder           Address of funder to find the maximum claim
     */
    function calculateClaimFunder(address _funder)
        public
        view
        returns (uint256)
    {
        FunderPortfolio memory tokenFunder = funders[_funder];
        uint8 currentId = tokenFunder.class;
        ContributorClass memory claimed = classes[currentId];

        return
            _calculateClaim(
                seedAmountForFunder(_funder),
                claimed.vestingCliff,
                claimed.vestingDuration,
                tokenFunder.totalClaimed
            );
    }

    /**
     * @dev                     Calculates the maximum claim for the beneficiary
     */
    function calculateClaimBeneficiary() public view returns (uint256) {
        return
            _calculateClaim(
                tip.tipAmount,
                tip.vestingCliff,
                tip.vestingDuration,
                tip.totalClaimed
            );
    }

    /**
     * @dev                     Returns arrays with all the parameters of all the classes
     */
    function getAllClasses()
        external
        view
        returns (
            bytes32[] memory classNames,
            uint256[] memory classCaps,
            uint256[] memory individualCaps,
            uint256[] memory vestingCliffs,
            uint256[] memory vestingDurations,
            uint256[] memory classFundingsCollected
        )
    {
        uint256 numberOfClasses = classes.length;
        classNames = new bytes32[](numberOfClasses);
        classCaps = new uint256[](numberOfClasses);
        individualCaps = new uint256[](numberOfClasses);
        vestingCliffs = new uint256[](numberOfClasses);
        vestingDurations = new uint256[](numberOfClasses);
        classFundingsCollected = new uint256[](numberOfClasses);
        for (uint256 i; i < numberOfClasses; ++i) {
            ContributorClass storage class = classes[i];
            classNames[i] = class.className;
            classCaps[i] = class.classCap;
            individualCaps[i] = class.individualCap;
            vestingCliffs[i] = class.vestingCliff;
            vestingDurations[i] = class.vestingDuration;
            classFundingsCollected[i] = class.classFundingCollected;
        }
    }

    /**
     * @dev                     get seed amount for funder
     * @param _funder           address of funder to seed amount
     */
    function seedAmountForFunder(address _funder)
        public
        view
        returns (uint256)
    {
        return (funders[_funder].fundingAmount * PRECISION) / price;
    }
}