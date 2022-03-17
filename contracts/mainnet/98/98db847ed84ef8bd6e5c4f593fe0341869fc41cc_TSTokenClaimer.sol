/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: contracts/TSTokenClaimer.sol

pragma solidity ^0.8.0;





contract TSTokenClaimer is Ownable {
    using SafeERC20 for IERC20;
    using Math for uint256;

    address public melosToken;

    uint256 public fromBlock;
    uint256 public toBlock;
    uint256 public stage1Blocks; // monthly vesting
    uint256 public stage2Blocks; // daily vesting

    mapping(address => uint256) public amounts;
    mapping(address => uint256) public withdrawn;

    uint256 private constant AVG_BLOCKS_PER_DAY = 7200;
    uint256 private constant AVG_BLOCKS_PER_MONTH = 219000;

    address private constant MELOS_CONTRACT =
        0x1afb69DBC9f54d08DAB1bD3436F8Da1af819E647;

    constructor() {}

    function setup(uint256 _fromBlock) external onlyOwner {
        require(fromBlock == 0, "already setup");
        melosToken = MELOS_CONTRACT;

        fromBlock = block.number.max(_fromBlock);
        toBlock = fromBlock + AVG_BLOCKS_PER_MONTH * 6;
        stage1Blocks = AVG_BLOCKS_PER_MONTH * 3;
        stage2Blocks = AVG_BLOCKS_PER_MONTH * 3;

        amounts[0xD6358e387446B8673ad7d3e48160B87bB246b634] = 200476 * 1e17;
        amounts[0x4332CBc500a70B6031b7329FDaA58f3737f8f77e] = 200476 * 1e17;
        amounts[0xfcf743d9785DfB4BCdF25377c00d7b0601655262] = 200476 * 1e17;
        amounts[0x7D7138182bF50613f5D7C9fB0f1Cb5f4583098E4] = 200476 * 1e17;
        amounts[0x2913E4Da9f4e10e0639724dD4dE6d486FFCA110C] = 200476 * 1e17;
        amounts[0x8B137dA1dB9a798De1f70d9D96Dd3F2E34B0e89A] = 200476 * 1e17;
        amounts[0x9c2deCDBD8e27717012A4401F0eEebDAf5591e15] = 2014676 * 1e16;
        amounts[0xd79019B30E667D4bD3c3E68183C5B5fEaDBCc119] = 2014676 * 1e16;
        amounts[0x8F09EeF679904F64752523f95dB664039dF278e2] = 2014676 * 1e16;
        amounts[0x12a0E25E62C1dBD32E505446062B26AECB65F028] = 2014676 * 1e16;
        amounts[0x0834e7a07eb9808c420c196bEe3147Aa90B274B2] = 2014676 * 1e16;
        amounts[0x09f4eB00fFf0C4Db19059CDFCF2ed6AB73093602] = 2014676 * 1e16;
        amounts[0x9db3523593cb8E22Dbe5A51F787920a7BD0fB20e] = 2014676 * 1e16;
        amounts[0xc51215C8ccb1EBB4303fC549F93B10A28d8Bd7D6] = 2014676 * 1e16;
        amounts[0xa11D0AD80934c07a4b4c0B1d4cdEcE62E372B26C] = 2014676 * 1e16;
        amounts[0x97C0776DeDfB9B10367232a1046D856d919A20c1] = 2003658 * 1e16;
        amounts[0xf682bf6EB26fd1083f0b499d958634Fe453CF146] = 2003658 * 1e16;
        amounts[0xf76B17Ce8ff08f96aD7bb785d4ed898d5d5014eF] = 200696 * 1e17;
        amounts[0xdc5635A17D51eb55f7fA77729482f7f744AB8982] = 200696 * 1e17;
        amounts[0xDadf5CDA15437181027Df014D75Dd0Be846DdEd3] = 16029264 * 1e15;
        amounts[0x29fa7fE1e8bA111667d1648b8Ecf60415becb999] = 19415446 * 1e9;
        amounts[0x29fa7fE1e8bA111667d1648b8Ecf60415becb999] = 1940608548 * 1e13;
        amounts[0x1076e03ed1528015d9731f3eAEbbd59910639771] = 2002692 * 1e16;
        amounts[0x10546B8246EE5a4c292Eaf3e4A218Cc87c5af431] = 2004064 * 1e16;
        amounts[0x9509716a6de734CD543D18d48E3b0ECe0aBbe633] = 1999186 * 1e16;
        amounts[0x5573bA7fF1C70b97346Ff3f7b4Ed746730d522Ac] = 1997606 * 1e16;
        amounts[0x88A0954CeF0574CccE8C4003c984b552fD9F8857] = 1997606 * 1e16;
        amounts[0xe4989e7B39a21089B128908E1603fdC9939DBB78] = 1997606 * 1e16;
        amounts[0x746355CDE56D0A123d661a0d52902567a4E86f61] = 1997606 * 1e16;
        amounts[0x4BD3d08BaE19C45B3BcE064BFEC0D5865bAf458a] = 1998372 * 1e16;
        amounts[0x35d0aC1786E912c5B83369C7d101889f1fE49618] = 1998324 * 1e16;
        amounts[0x510D98A49f727D27fbB7FEADE9dc842D8e54D521] = 1325337 * 1e16;
        amounts[0x54B7f8fe8D3AAEeB115D2Ae1AC9Ea5d6B824e2dc] = 11994852 * 1e15;
        amounts[0x43262777801E32306832e55675554951E0A7A599] = 1997518482 * 1e13;
        amounts[0xDa830d2D83A57Cea255bCfD0Cf89C3e94Abde0FD] = 103987624 * 1e14;
        amounts[0x94C99D650415CF4119Dd6398DBC160a4B3952c78] = 2001232 * 1e16;
        amounts[0xee366Bf782a0e5eAF080b1f6082da3aDE677A2a8] = 2001232 * 1e16;
        amounts[0x03F768383BDE7F8aDCfbc639F734362114545C57] = 2001232 * 1e16;
        amounts[0xcFeB2b5A5c62a308e6089DFbd1d16d4535949eA6] = 153094248 * 1e14;
        amounts[0xCA4A00C67d939640332fE2f83eB0C41C52f989C1] = 2001232 * 1e16;
        amounts[0x4C4b46Abe88F996d1B3B4A8Fa41876535675ef1E] = 2001232 * 1e16;
        amounts[0x499c45D00225FA3c282A6E1e3c679f77b68db3f4] = 2001232 * 1e16;
        amounts[0x8b24572eeB376e4b863cd11a311Fd2A46aDAba07] = 2001232 * 1e16;
        amounts[0x3524b2d9aF57D3Cf852A5f547152e061Aa011139] = 2001232 * 1e16;
        amounts[0xe642E847b16cdb13312F762a92eD4d5371A1B2F3] = 999961 * 1e16;
        amounts[0x70da180a49297B23f313DD62f86Ce345840eeEE5] = 2001232 * 1e16;
        amounts[0x69d7BEc89472C439B3544b5e04f50479b23FEbBF] = 1999922 * 1e16;
        amounts[0x93907dE38066D70109935732757B625d636E47B6] = 1999230768 * 1e13;
        amounts[0x69fAa59e22242667bdfa03c6AABEe7cB6a57666c] = 2001232 * 1e16;
        amounts[0xb0c6071582e9Eb0e3125B6CE85Ff6d57077CCf71] = 1999922 * 1e16;
        amounts[0xB2F9BbC5db84a95B598cAB0C464cF92D584d8900] = 2001232 * 1e16;
        amounts[0xB5e75846B0Aa3290ED60EB47A76071F4859903e6] = 2001232 * 1e16;
        amounts[0x3387c3ced164f7b9711d6fb322493D19d10EA673] = 2001232 * 1e16;
        amounts[0xdA9De07f971B3E6953eDc442275Cd01bC350548d] = 1999922 * 1e16;
        amounts[0x1C540DdBDB2F20867533d8C91a1104ba87c8d8F5] = 2001232 * 1e16;
        amounts[0x22e29029516Bd3bCF0c9B440AbDF13784798aF87] = 2001232 * 1e16;
        amounts[0xF6d1C01554D3b45B280107Cc592Bd6681C780D59] = 1999922 * 1e16;
        amounts[0xA0aB4b93b38277C592139e2469A3A5527281fC26] = 2001232 * 1e16;
        amounts[0x9a9C418463C3E215EEb43A459451c459C51E56f1] = 2001232 * 1e16;
        amounts[0x73F0e1C958b21e3fEAbB8Eb5c39a54B1e8eec3F6] = 2001232 * 1e16;
        amounts[0xD413358557eB9b9C88b9895cA77597D333A555E0] = 2001232 * 1e16;
        amounts[0xcc85D3B7fb301d347Ff4b6139e47f5a65A09b709] = 2001232 * 1e16;
        amounts[0xA61Ab1B1d0c5876c39068409e94F465d8b52e7EB] = 2001232 * 1e16;
        amounts[0x14d847E037631daDBe2Bf3c0febb1C9c14eDAf7e] = 2001232 * 1e16;
        amounts[0xAD2Dcf063cCc9AA9d090FDb7177BE7816153EbAC] = 2001232 * 1e16;
        amounts[0x81121696CAf4d05aD0954ed8aB552534448F9D29] = 1955203664 * 1e13;
        amounts[0xB883F497016D2015c7145347A86413E2DC866212] = 2001232 * 1e16;
        amounts[0xD578924E24399F87D0f064436C68b5975f2fc72b] = 1999922 * 1e16;
        amounts[0x89EcC2182b7Aedef78Ea9e4B45E112a6cC48f4cF] = 2001232 * 1e16;
        amounts[0xf8992A1f4e302460Bd49a1646Ee315D810235212] = 2001232 * 1e16;
        amounts[0xDEe7b41B7021FDb9b7864A401C27A7989BbB09F1] = 2001232 * 1e16;
        amounts[0xb61004dA135cC0FAE6A926Fe35Ed7DBb5CDEe058] = 999961 * 1e16;
        amounts[0xcB90ca4Fed42110C01E5CEc2f1d586E38B6C1aa2] = 1999922 * 1e16;
        amounts[0x36FBcbBe4B8344f2aED9E9D4D521f6ffd8594139] = 2001232 * 1e16;
        amounts[0x6BEd83622c2577Bd5b0d3DA196eC4D9285646eeC] = 2001232 * 1e16;
        amounts[0x2781bF6bB3458e1Fec609f898fd835B6ffDf8a81] = 2001232 * 1e16;
        amounts[0xfDD30e23D5d236b4A64166edDB66C25ED3A99aFb] = 1000616 * 1e16;
        amounts[0x4F7c2B7F25C466D135B41d81cC86ECa207Bcb200] = 2001232 * 1e16;
        amounts[0x6901300941DE2139ED8BFC914374856e3E477f51] = 1999922 * 1e16;
        amounts[0x315519c9a189a5F165BEa224791a2E84b63AD71f] = 1999922 * 1e16;
        amounts[0xc193e1f6a6F4322fC04909Fe5BD1046da9340f9D] = 2001232 * 1e16;
        amounts[0xc49DDE2CD41aA4Ee9b0a199AAA1287a7E87BbA1c] = 2001232 * 1e16;
        amounts[0xd67A21Ca851986f1acc46e5b897AF4978aCFec90] = 2001232 * 1e16;
        amounts[0x9B5caC9AFf59920270632Bf023aD18bbA7991569] = 14008624 * 1e15;
        amounts[0x2C73F6E5F5d1c70607e732657b75134cb50e06d6] = 194119504 * 1e14;
        amounts[0xECe53d3a2d58E565ddFef81Cb418c67A496fCDF9] = 2001232 * 1e16;
        amounts[0x45D266E91B564c237dE84CdaCa7d279237aB7E18] = 2001232 * 1e16;
        amounts[0x25Bf06B7CC2981123f1Bf3aD86751Dd1A563f466] = 2001232 * 1e16;
        amounts[0x88f03FbC43980f1B29c6759FCCa17811Ab97a1C9] = 2001232 * 1e16;
        amounts[0x91F59d43fCC4c70FDf22b989D2127dE9c47e1aF4] = 1999922 * 1e16;
        amounts[0x8f33e119Dd7EBF055614Cdd34591149dB779bC90] = 2001232 * 1e16;
        amounts[0x5816f19B666Df85c8f930b60d1dC3Ad77623a357] = 1046644336 * 1e13;
        amounts[0x58DDD561D4aBaE18eE19225153427c8c79e07858] = 1999922 * 1e16;
        amounts[0x37d6419944AEB6d146E1767D6B94828411270b6e] = 999961 * 1e16;
        amounts[0x6dbb95b7cf1575f7B7Bb09b4f47DF66f3Ff932b8] = 198992239 * 1e14;
        amounts[0xB0FEcff8Ab2b45778Cc022f7f0f98D0A2B0133a0] = 2001232 * 1e16;
        amounts[0x1Fd44f2147D1b3cf635E9727a83135cdF5aC14DD] = 1000616 * 1e16;
        amounts[0xa7934BADe938635D033b4AFfa2cF14BC61256597] = 2001232 * 1e16;
        amounts[0x8bA4f911EBAD585cDFC7F75138a5E694ed6C4666] = 2001232 * 1e16;
        amounts[0xaa18448Eb19CD801C63F05176d095b66E78E8A00] = 2001232 * 1e16;
        amounts[0x877b55e61338025a768977c881Fc252Ea0d72dfC] = 1999922 * 1e16;
        amounts[0xA1F762144262A585c5A8c4cd16D91cf36aeb4DB1] = 11006776 * 1e15;
        amounts[0x17d0fD4337307e74F369bDE8af43cCD9e0149e1b] = 12007392 * 1e15;
        amounts[0x824135aAdaC17608DD1390158F867a69c23fb7B7] = 2001232 * 1e16;
        amounts[0x32b838a20a30d72b3Bdd886b32bDf108eb373582] = 2001232 * 1e16;
        amounts[0x88cdAE6C95c1e4Fc01bcA7F203548C808D2ebaC9] = 1999922 * 1e16;
        amounts[0x73b98C9B4E59b49058aE3F9236Fdb970Bf4Ec00a] = 2001232 * 1e16;
        amounts[0x4FB0aB6b4f83F6924e3C7f5DAdC6690Eddeb4ae5] = 1999922 * 1e16;
        amounts[0xbDf44e1FE1284E1640A27733C0cF2DaD0Ed0324f] = 2001232 * 1e16;
        amounts[0xb00D4a17b76130ceB8ED445F112C3Ba018150c37] = 2001232 * 1e16;
        amounts[0x81cc7ce6Ab4A43F38eC2F1Da1Ee402855b759EcD] = 2001232 * 1e16;
        amounts[0x42b8e07D7bF8eD385A0f66039C979e83C043debD] = 2001232 * 1e16;
        amounts[0xf7b1F66d8c394b1f61E5D7a5a630c71Eba67A7fa] = 2001232 * 1e16;
        amounts[0x2EAD7C4d006Efe0501d720df5defb4a530Aa6F6b] = 18011088 * 1e15;
        amounts[0xF1328FDd7E333A413b3EE29e8cb91Dbbdd8aa176] = 2001232 * 1e16;
        amounts[0x25Ec155dfb60fAeB52d58eb337d979aB0C9431d9] = 2001232 * 1e16;
        amounts[0x772525bEBb83975FC340360E8263c7328C21B340] = 2001232 * 1e16;
        amounts[0x6505AF7d922CaE17906a3361a7Ce27343D70416c] = 1999922 * 1e16;
        amounts[0x11747fa7f010FFddf607cFf54b21b92446F7Cd5A] = 2001232 * 1e16;
        amounts[0xfd19aA675d557f594c8f237B6bd0a0Ee30e3b3Ea] = 1999230768 * 1e13;
        amounts[0x5e4856e5Aee9C3bC196Fa7E751d9D3E78803E0B8] = 1999922 * 1e16;
        amounts[0x5Fc60EC8D30Ea4cf01c80B61e3E3fecEF912641f] = 2001232 * 1e16;
        amounts[0xa82d274549a10eDC861Ef68024b1FdC4702AC4e0] = 2001232 * 1e16;
        amounts[0xeEa7D774189E9152DD70e73e5FD7c153306D2484] = 2001232 * 1e16;
        amounts[0xBbf00A88f49B252C587c353937Ea3ee84748c358] = 1999922 * 1e16;
        amounts[0x000000a392F74C072921bF91626D83A7d11194e1] = 1999922 * 1e16;
        amounts[0xF280Fb362EFc01FA1A41CB2f52906BD695294Bb9] = 2001232 * 1e16;
        amounts[0x3136bf1eBc4f6225D2b7aa2965A7498948596BB5] = 1999922 * 1e16;
        amounts[0x98364834FC16F68BCfbC0723b6293a82283b35C9] = 1999922 * 1e16;
        amounts[0x5a09A306f75F55f1a79E03C65712002b5fb2a1Df] = 2001232 * 1e16;
        amounts[0x036DC7499Fa70C646D6Db098334d5a708B8f1Fe1] = 1999922 * 1e16;
        amounts[0xCbE8d5281496b9687F30D2638fB9Db358c07bcb9] = 2001232 * 1e16;
        amounts[0x6784c8E9F394aC8852b45f613ce25D1e850891d7] = 1999230768 * 1e13;
        amounts[0x02647CBB1714fA9A5747EC5Be6333E06D806E85A] = 2001232 * 1e16;
        amounts[0x129e81DAD8cFAEecEE130309b39B5F22215062ED] = 1999922 * 1e16;
        amounts[0x28B6182569e04234Ef77bA48869dea352933d168] = 2001232 * 1e16;
        amounts[0x8e7b02Af5e749CC97e1551e13cd7230aD75D868F] = 2001232 * 1e16;
        amounts[0x28d6Ab273759Fc0eF4881d46644d85F412af3015] = 194119504 * 1e14;
        amounts[0x3e57164863219BdE0f0564f7d54c175b596c53D3] = 2001232 * 1e16;
        amounts[0xa6D6cde48CFa9f4ab04C4746C520D35C075Af442] = 2001232 * 1e16;
        amounts[0x87ac9c31a863e71921353e20Fbb7D1867b91F089] = 1999922 * 1e16;
        amounts[0xC9c907939bdBD0351B79B167B1DA2b3138310873] = 2001232 * 1e16;
        amounts[0x5c8D381FadFFAb0cdf5d19e8fBDF9B85fe7A113e] = 2001232 * 1e16;
        amounts[0xBa067Cb60bd7629c24ff46922F0295fC2c3025dB] = 2001232 * 1e16;
        amounts[0x38001785D90685BD706C7de68A922e1564711937] = 2001232 * 1e16;
        amounts[0xc23e76Bc86b10B81962C36d1811b5384A6603270] = 2001232 * 1e16;
        amounts[0xacdD6D00b9078C59B2212bAB0425EEb1f5F43Daa] = 1999922 * 1e16;
        amounts[0xc574e1d80417A0962DedEb4193564a20F861e996] = 12007392 * 1e15;
        amounts[0x2b5FA312acD8dC4D50A4952EB1F15c458949B26a] = 2001232 * 1e16;
        amounts[0x8b09C4Fd7f3beAFc91bbcA198313CFD0D1a5ecbB] = 2001232 * 1e16;
        amounts[0xCB2C1B56EeDC15B9064C62c08E5e84197de516d0] = 1999922 * 1e16;
        amounts[0x8F38F8f6d4Dee63E9A3Bc0cED4DeA5919C7A1915] = 2001232 * 1e16;
        amounts[0x319d116c3074aE7dA02Fa6ee50Ce453fe69d7B58] = 2001232 * 1e16;
        amounts[0xC7C05064bE4890102e6033fE568342B9e9238c73] = 1999922 * 1e16;
        amounts[0xf25D2D80Ebd8c262435f7088Ce0D5778F3ed9757] = 2001232 * 1e16;
        amounts[0xd71B9584Bb3508eF142d46e95b587294bb802D91] = 2001232 * 1e16;
        amounts[0x9B574b8896e0716197Cb018f8C8c4f68971a76c3] = 2001232 * 1e16;
        amounts[0xA18A5431793cFC87d49906dA2628774EE7b21E43] = 1999922 * 1e16;
        amounts[0x7504AbbC766f72C1D03d16094B38903378623361] = 2001232 * 1e16;
        amounts[0x1e3CD42FC42E932f07b44C4E5Be45B8CF11b2297] = 2001232 * 1e16;
        amounts[0x0BF9Ee982A4b1Bd7D8ec3dB94200c04176ab7A1B] = 2001232 * 1e16;
        amounts[0xFDCFE70E7eEACA6a0dB8Bb62eA577C10F7ca35Fb] = 2001232 * 1e16;
        amounts[0x2388e47e12123d17d0EE4040c6b73190Cd9B6A6e] = 2001232 * 1e16;
        amounts[0x8B5185BD15B7992C53b073795c6Ee6A915b5b8ea] = 14008624 * 1e15;
        amounts[0xD176c144aF770137dFe16c48D91c6De30Dc45307] = 1000616 * 1e16;
        amounts[0xa62b7abE42Dd988591CD91a026da1c291Cb9aAF9] = 1999922 * 1e16;
        amounts[0xF217402efA536aC01B75bAc59BE0a393c808a932] = 2001232 * 1e16;
        amounts[0xff1258411c564bbba9DC2544F4c48A7a3c9E2137] = 1999922 * 1e16;
        amounts[0xcEE4259732a903D6EeE406f15466247F08A84551] = 2001232 * 1e16;
        amounts[0x8d37c7122a5b1269752F24BF8802E740aC7A5da2] = 2001232 * 1e16;
        amounts[0x631Ff8D50C596cB357144ADE636749810569343a] = 2001232 * 1e16;
        amounts[0xC3C138ddbd3fCe623F25bd6E11Ff45cB2A9B2D16] = 2001232 * 1e16;
        amounts[0x295D7C0FB88897e1Be54aA92178C02902a696631] = 2001232 * 1e16;
        amounts[0x751dFce47faEa3399B9F82C68A7Fd61a4BC901e0] = 2001232 * 1e16;
        amounts[0xD8033Bf90D2E519c5442025d796408EF1ABd21c8] = 2001232 * 1e16;
        amounts[0xd2c34bc90C56B79F717A4DF57edC83B1ce1A1451] = 199122584 * 1e14;
        amounts[0xe99382f9262Bb7CD5963e0C7Cf792a462d01749f] = 2001232 * 1e16;
        amounts[0xc6753f87fEa4433192FEB0dA9e4231d594fD80bE] = 14008624 * 1e15;
        amounts[0xe2abcD46D89f471344F43c6533863D11B13b4FA6] = 2001232 * 1e16;
        amounts[0x05F284897641661Fee9f1c1413a4f599a43a746f] = 1999922 * 1e16;
        amounts[0xA013Fc2739251d3722C17D659586491428253459] = 2001232 * 1e16;
        amounts[0xbEcf8b799e87A4313B2881bdF0DF3915a623E858] = 1999922 * 1e16;
        amounts[0x9019173fA499C6a1D97268CbFC3b6C2425b86358] = 2001232 * 1e16;
        amounts[0xDAA0E934b4c48fB47C7f3929a91dC257CC091104] = 2001232 * 1e16;
        amounts[0x3A0C09Fb2273d865233dBA80f81b2Dc5b3Ce63Ce] = 2001232 * 1e16;
        amounts[0x12925c6DB179004bAD1091d0745712aC8D24132d] = 2001232 * 1e16;
        amounts[0xFdFC89fc7DEe5532CFBa75AE50Fd62add5ae5E21] = 113069608 * 1e14;
        amounts[0x619E9677F907122eebe85776194973260d87f1bA] = 1000616 * 1e16;
        amounts[0xBE6f15Fc07f64D9bAc44bdAaA5172F612632278F] = 2001232 * 1e16;
        amounts[0x7bc78839c2c5f27b653f2be26218064319F0A74b] = 2001232 * 1e16;
        amounts[0x23F3515E5825355A384d5d64104242BEb787CcB8] = 1999230768 * 1e13;
        amounts[0xdDE74aec0816D6E2E4739Bd9e8DcB6C9e41D6b6A] = 2001232 * 1e16;
        amounts[0xD060Fa1dBc0BbC590c6E473B54840E64EfFC3b70] = 1999922 * 1e16;
        amounts[0xB96D1110E5e1D47FC99ed3Ba5ad11d756d45cb61] = 2001232 * 1e16;
        amounts[0xA863706CCBf4A12895a428d53360564F66e432d6] = 2001232 * 1e16;
        amounts[0xc3A6E2b72EE8478A85593Bfe86fCd612855BeAe2] = 2001232 * 1e16;
        amounts[0x16d4D23CDfA1096A114459637baB9E71AD93f4e7] = 2001232 * 1e16;
        amounts[0x0a3Fe3ACD184E6516a119fC6ffFFe47CbdF386Bb] = 2001232 * 1e16;
        amounts[0xDb61Ea31E8C5D5df8b2cB0c4715558f61D09Ae46] = 2001232 * 1e16;
        amounts[0xD63Fe34F156c117E225B1bc4F71104e05F7B714b] = 2001232 * 1e16;
        amounts[0xBdF4CF8269C3883dd88975E1978a6aA9D3877F2E] = 2001232 * 1e16;
        amounts[0x1CbFFD63aECB14a25D0C4F494ABe798Eb6Dbb92A] = 1999230768 * 1e13;
        amounts[0xeAc1637442F6F758EA76F8475E6F4064EBbDdF8b] = 2001232 * 1e16;
        amounts[0xcbB5f3AC7Fd65E75bd17F3939bc377A3B066d158] = 2001232 * 1e16;
        amounts[0x4B8512DFfDCa971827F610aE6FA6159fE972dF87] = 2001232 * 1e16;
        amounts[0x5175F9D7B9934426eAe8D3Fb71E2745009301bFb] = 1997922078 * 1e13;
        amounts[0x6820684022D5cF75f8eB584522F23B70FD6C1DD1] = 2001232 * 1e16;
        amounts[0xb98331c95471b0E72D26663432BF8b0DbFB264B7] = 1999922 * 1e16;
        amounts[0x34BE3E49f74dEf9315Bfc0D567D03bb52E0C9dD6] = 1000616 * 1e16;
        amounts[0x4740AC1ef469B8b2fC9f5A4Fb1a7dC5bCBc5989e] = 2001232 * 1e16;
        amounts[0xc6c1E852ECCE4Ce5a0C93F0E68063202dA81202b] = 2001232 * 1e16;
        amounts[0x449b48da52293cE708583b7a3dC7da5E53075e7f] = 1999922 * 1e16;
        amounts[0x5eAa893b1953895dC1437f037A1F035fBd891E6e] = 2001232 * 1e16;
        amounts[0xD5b7BF71A471e6dE6b5a1F66A91CFE8f9ADBad14] = 1999922 * 1e16;
        amounts[0x18d213F0a8B8C9C82254C63f5e4aD593583Ec71C] = 2001232 * 1e16;
        amounts[0xE36595D4fB1012542f21180a28a447B64E17E555] = 2001232 * 1e16;
        amounts[0xaD09610C25Aa9De8635F0Ca4FAcD69C4beD92f66] = 2001232 * 1e16;
        amounts[0x1b908b7Cdc101999158097720Dac4fa6AEB132cf] = 2001232 * 1e16;
        amounts[0x654Ecf30edE43400D342Da2dCBc000d756882f64] = 2001232 * 1e16;
        amounts[0x8e9790364B4c458C7FEBF4ac92cC12FDF2218635] = 2001232 * 1e16;
        amounts[0xFc3D22f9653615943405146ed211Cf0234f133a2] = 2001232 * 1e16;
        amounts[0x59c023eE79B59dBf8DbF181575d2814a93953429] = 2001232 * 1e16;
        amounts[0xe452Ca92Dc9d8cA4699D75CCAB56d82B7cEF8711] = 2001232 * 1e16;
        amounts[0xa2d898E5FcCD8fcc349f6a98f64aeC00703E33D3] = 2001232 * 1e16;
        amounts[0x49d9623080eb79A11b67599ffAc0C89de9A83C94] = 2001232 * 1e16;
        amounts[0x66e1A0522aAe18c0C5eE4287276Da2095be3625d] = 2001232 * 1e16;
        amounts[0xa8a5b4E535268a91D330A1B26E11030831eeD35f] = 999961 * 1e16;
        amounts[0xAdB93d7615c518A73d2913f026544C2550EC7080] = 2001232 * 1e16;
        amounts[0xFb43ad7026CFcD2F2BFf9c083cDb5BE13fF1B69B] = 1999922 * 1e16;
        amounts[0xd45918673Ffc13C467A30c3880aE51F2d37854a3] = 2001232 * 1e16;
        amounts[0xaeD371f9052082dc0Aa87c35e89f03466c68dF66] = 2001232 * 1e16;
        amounts[0x78F4775Fb0aD590D7790BCbe460aE4304b06d02b] = 2001232 * 1e16;
        amounts[0x4DC80D417bD90CD31Dd61AD591FD7FA83779Da22] = 1999922 * 1e16;
        amounts[0xA68C3994C6a50DaE55001ff7c98612Dff3297202] = 1999922 * 1e16;
        amounts[0x1849E336D36b97C95ec159ACe91a43963EBe07bE] = 1999230768 * 1e13;
        amounts[0x23b565723C361C160628A0A20E8c972f38525540] = 2001232 * 1e16;
        amounts[0x6132afAa5C43E9E79B8B62e2Bee1A50247c3a2AE] = 1000616 * 1e16;
        amounts[0x8B5c15bF83a52BF27957B8392eC564A04f28e894] = 1999922 * 1e16;
        amounts[0xBebaED6ad218A0F24105b89011039c6445aF3f26] = 1999922 * 1e16;
        amounts[0xC472F04da63a742C9cf41D8617676A1116F4FfD5] = 1000616 * 1e16;
        amounts[0x9c49cAdc89a3B8Cb6239A37a692BA370c32BDFd3] = 2001232 * 1e16;
        amounts[0xfeCD0Cd891C95D274942f7ca6C373EA556B9b669] = 2001232 * 1e16;
        amounts[0xDeCa72397Ae5d9DBbdCbceCe33dE7Ae8Ac95608A] = 1999922 * 1e16;
        amounts[0x2EAD7C4d006Efe0501d720df5defb4a530Aa6F6b] = 2001232 * 1e15;
        amounts[0xfc4bA3D42C34246cF913703B312696e4151971C4] = 2001232 * 1e16;
        amounts[0x9938DFCB5A93e2242Db5dD5EEdb176AF0cAfCF99] = 2001232 * 1e16;
        amounts[0xE2EbbABB14c373bDE1248A127714E0b05E264531] = 2001232 * 1e16;
        amounts[0x1793E7B20e7246F6aFaFE7eB712114a230F06A6a] = 2001232 * 1e16;
        amounts[0x644F22132a265947A18299fe4c5cfde21e94015F] = 1999230768 * 1e13;
        amounts[0xA2cD5c2B63F9070dB0cb1F7b01b42055CBf44756] = 1999922 * 1e16;
        amounts[0x0c42B25f5aaCD767505Fe81D50BeBddd64d9C2C5] = 1999922 * 1e16;
        amounts[0x882668c887286d3dD0EB894A78Eb92798484978d] = 2001232 * 1e16;
        amounts[0x01201bdE033B5d060Be7693D931a8914f356a7B3] = 2001232 * 1e16;
        amounts[0xbF7Da1f568684889A69A5BED9F1311F703985590] = 1999922 * 1e16;
        amounts[0xC10a9a29AcD16bfAfbF216bCF21896a5C2F98182] = 2001232 * 1e16;
        amounts[0x1A9681f3272cf0861BC370dd2df2DbA3513B8a38] = 2001232 * 1e16;
        amounts[0xe345E00FF02f7792e11AE46468254447D13E71E0] = 1999922 * 1e16;
        amounts[0x9B476Dd00cEE2F00cD57C7B7CF79dd7f27951D02] = 2001232 * 1e16;
        amounts[0xfCC1C48EF07786Db04ca1c20c329e193997f3CE5] = 1000616 * 1e16;
        amounts[0x8fA3ffb44FA45Bc373F1D5D293d543D9e8C875b0] = 2001232 * 1e16;
        amounts[0x4c62c7Ee9D3CEb57a331B761A15820F660027aAa] = 2001232 * 1e16;
        amounts[0xb5Bfd0BC13e0593EcB1A87710a126d9A3439FFde] = 1997922078 * 1e13;
        amounts[0xda8d960F10dFb7174252f86906b7610aD4d21f42] = 2001232 * 1e16;
        amounts[0x58dD490B6E2add615d034D95b161c2b8a221d487] = 2001232 * 1e16;
        amounts[0x5c2D5Df3aC53d355579dc96e4147B0b3A48C3a1E] = 2001232 * 1e16;
        amounts[0x3D2c7eea1eFe0b0562088e03fEBDd205b9bBd039] = 1999230768 * 1e13;
        amounts[0xB4C429bf79c097ec6b1BE06eD862c9316C344356] = 2001232 * 1e16;
        amounts[0x783C97047bAd9E0b55A33F46c2aC3a968e217259] = 2001232 * 1e16;
        amounts[0x35e53EDDa5c012A4262Ada6953d75a2B7D3E7778] = 1999230768 * 1e13;
        amounts[0xd25D890c4b1C361BE911ca214a0cc37152a2c4b5] = 2001232 * 1e16;
        amounts[0x55B54819AF126AB64C9cF380B54EFBc902C5828f] = 2001232 * 1e16;
        amounts[0x12bD8709a7392E6f6E628c810Dea2dC7eec913D0] = 2001232 * 1e16;
        amounts[0x40DB80301E42C0490772C274dbe9524B0a3e854d] = 2001232 * 1e16;
        amounts[0x3D506215cCCED60b58f57CfC0e15f095f27E6699] = 1999922 * 1e16;
        amounts[0xDCFAb5Fd86F27B9d6f231AA392fF6Efa843D455D] = 2001232 * 1e16;
        amounts[0x85eFc14BDc15f43B26c5EF7CF6Dd96C9082cdA28] = 2001232 * 1e16;
        amounts[0x9577bF2Ddf91ca129a212638912e7d4BEe4115EF] = 2001232 * 1e16;
        amounts[0x2C688163839Ae38E12b3651E20039E62a2534E69] = 2001232 * 1e16;
        amounts[0xB4505E5E927f7cF092D8a687F00Ed80f1946636a] = 999961 * 1e16;
        amounts[0xD27Ad95230b3761EE68EbF7c3F0294a8Cf5be934] = 13008008 * 1e15;
        amounts[0x799B5D428aD558585A5231D84d17c42d368BF307] = 2001232 * 1e16;
        amounts[0xb75Da0c0280dD1e01f5a2dd6a8574f34696723bF] = 2001232 * 1e16;
        amounts[0x98D5179c8A963B03F8099106De800E2632586aC6] = 2001232 * 1e16;
        amounts[0x87830B66688b02e7242227126aa44627e2419af4] = 1999922 * 1e16;
        amounts[0x9b74047027B6D484b9D9f00B9024d301f860499E] = 2001232 * 1e16;
        amounts[0xb875DDa1166D63B3A12472c163606b635bad98E8] = 1000616 * 1e16;
        amounts[0x4855B7c789Cd893988Bf86BB1642dE8f60Ccd4cd] = 2001232 * 1e16;
        amounts[0x89743a7c66aCB96B81a599a124517F089AbB5c3d] = 2001232 * 1e16;
        amounts[0x4a3fd1569B6b40420e6542d753C2A38922d3612f] = 1999922 * 1e16;
        amounts[0x47d012990F9EB9e2A3B2DFFA6D0C2C878785D546] = 1999922 * 1e16;
        amounts[0x51be211FCA59391f39AD4eB13a6e88595383d18d] = 2001232 * 1e16;
        amounts[0xa00FaEaaafaAfdee4818D6eAa8fCCe99F76ACCa0] = 2001232 * 1e16;
        amounts[0x806E782aEbd0DC59d8fBfaf47bBBF9bE5f77a606] = 2001232 * 1e16;
        amounts[0x0E4730532278d37bD0a045523E01a3FD220d46f7] = 2001232 * 1e16;
        amounts[0xD09EA28f8f8b20A26A5D8f5b9770859865C6109c] = 2001232 * 1e16;
        amounts[0x101DCE3763440672EB59219AC3B43940Bf6A7271] = 2001232 * 1e16;
        amounts[0x0A4d01D364136395254AC6a55890C2723F866a8b] = 1999922 * 1e16;
        amounts[0x789bdde8acEfC0c48576400a29f0630b8aA75e45] = 2001232 * 1e16;
        amounts[0xA4Bc665fd24a2Ac4Ad8879Ac3359a9ca5d31ea90] = 1000616 * 1e16;
        amounts[0xeD394F9e65F1181A14d7A3429540b631bBFd94BF] = 1999922 * 1e16;
        amounts[0xDB099E06e52c611a702840ca986F75662A8bCA60] = 1000616 * 1e16;
        amounts[0x4F13dFFed9AA20fB22526463bed09C4E59e1b833] = 1777094016 * 1e13;
        amounts[0xFb2a902b03804272bF97f13a83D5Fd77C725691F] = 2001232 * 1e16;
        amounts[0xDd2Eb3E5E9DAd19A2164432F31F8F2C42720fC37] = 2001232 * 1e16;
        amounts[0x910AcFce5343b929c6E9Af19361a13145765B9D6] = 2001232 * 1e16;
        amounts[0x260Af316001BCF7fe6306D98c545A259d7C43857] = 2001232 * 1e16;
        amounts[0xeae8C9d7807E6985eFe43592E4E69BeaC96f120a] = 2001232 * 1e16;
        amounts[0x7C3754848A586Cb19f0d8d0D632bfA2d34419362] = 2001232 * 1e16;
        amounts[0xf4a953f7cc07B588758940fD7fBaAeE2102243A5] = 1000616 * 1e16;
        amounts[0x8D87d31921b8dDF8EF5db8b3f5428dca73D6B131] = 2001232 * 1e16;
        amounts[0x3E20EE83b443AEee2f96700051C3C674A6c10CAd] = 1919181488 * 1e13;
        amounts[0x5D61f50BbaA053029d19FBd03297c433A91F9Bfd] = 2001232 * 1e16;
        amounts[0xA1212eFec975Ad7d2A32eD96966760716Dc0Ab97] = 2001232 * 1e16;
        amounts[0x55c03369c274320045c0Deda20c8Ed429d39787f] = 1999230768 * 1e13;
        amounts[0x8fBEEEC4F3f6090D318497ee87c11316C4efDBDC] = 1999922 * 1e16;
        amounts[0x2BbB83F6de7a16536A1aeeDcBC7c0fAFbe37BAE4] = 2001232 * 1e16;
        amounts[0xDbC2E884720C3651Eb9a9fB656Db3a6713aF2B44] = 2001232 * 1e16;
        amounts[0x30d594B3817aEE730fAb4115a0aa3453499655F9] = 1999922 * 1e16;
        amounts[0xF3a3d633806a6A03eB748aE890456589f3d61a5D] = 2001232 * 1e16;
        amounts[0x4B25EA8297Fc7321fCc449e26335FdA476Aa571d] = 1000616 * 1e16;
        amounts[0x4B2D38b32BB7C351f7cf530586B87C045208C0a6] = 2001232 * 1e16;
        amounts[0x7463cf48d5D35eE954923Abf4Aa14B539C22EDe1] = 2001232 * 1e16;
        amounts[0xc7d12bAf534456C1755404c34D49D4DEA78CF3dA] = 2001232 * 1e16;
        amounts[0xccdB2ef28A9FE12E9661B82A439e9aB2ae478935] = 2001232 * 1e16;
        amounts[0x70fFb1f081DD6184BF706094f27DB048e1836Ae2] = 1000616 * 1e16;
        amounts[0x0A67bEDf924E679B35196832f871B8FF2c25Ff8D] = 2001232 * 1e16;
        amounts[0x4BdB5645fC52e5ABc219CA26257DCD9138F9dE82] = 1999922 * 1e16;
        amounts[0x29D5d1DB88213a2c7d9158F36B6f0145d78D9CA2] = 999961 * 1e16;
        amounts[0xecDbD5d8E2998AfDc7668c66EeD7ba44e378b924] = 2001232 * 1e16;
        amounts[0x1F172F66730d2Ef5cAe06EDe52f2C0c26055Ba56] = 2001232 * 1e16;
        amounts[0xa56A0E294DE2Bd4B50B5d05088ad5f4b6792e174] = 1999922 * 1e16;
        amounts[0xa7A81e2e5f7cbeFC93EaEf0C31194a4Ac31B10FD] = 1999922 * 1e16;
        amounts[0xC9Cc2C6473eE5bB144D4F2526d2Dc73b6Bbb5C02] = 1999922 * 1e16;
        amounts[0x017263F35D61819D0d680bFD12742E5082C59BB3] = 1999922 * 1e16;
        amounts[0x74f434676e52fEdf416c56E843995eB726D0935c] = 1999922 * 1e16;
        amounts[0x82e10D2E3b2698FC01E1b1EF30d766a7d9BCB54B] = 1999922 * 1e16;
        amounts[0x5F6D69a1978Ec9872C4d4234fEd9eD246f666Bab] = 1999922 * 1e16;
        amounts[0x81B7e05afa96CB3a3337FAF07E2bF34e2013946E] = 2001232 * 1e16;
        amounts[0xffac05715CDCfCCD177f5C4E75669b91dD723D8e] = 2001232 * 1e16;
        amounts[0x974B44ec5ac5972d4C771F0C5B9E9132871A080B] = 2001232 * 1e16;
        amounts[0x38530cC869630399cEfA1B8C1c07868874c13e8B] = 1999922 * 1e16;
        amounts[0x8AB3eaBAc8011aA897D3aE07C11744B5168861e2] = 2001232 * 1e16;
        amounts[0x896f382913Da96Fa69613Cec49b953F3E0D42c99] = 2001232 * 1e16;
        amounts[0x06840F6a61FfB24CC30564dC9c5497ACa0C45a27] = 2001232 * 1e16;
        amounts[0x04abd3E13cf3E86aFE5172757C862E707A10Eb0A] = 2001232 * 1e16;
        amounts[0x67251094bA143D02111E264C067B020d76C9F3d4] = 2001232 * 1e16;
        amounts[0x2AFe7251bF1600325E8CE7926ffbFb822b30abe2] = 999961 * 1e16;
        amounts[0x5c8b0C3159982D4B09Da7b8F8043b060FdDD4828] = 2001232 * 1e16;
        amounts[0x10A590f528Eff3D5de18C90da6e03A4ACDDE3a7D] = 1987922468 * 1e13;
        amounts[0xAB70588B24203e245bCEE352D050975931b16e20] = 2001232 * 1e16;
        amounts[0x30bfBeA58A748662ff621DfBB7bA8fE68dED6648] = 2001232 * 1e16;
        amounts[0xAdCCC73fe4349f3d70709Da8cd411541bBeB95bc] = 2001232 * 1e16;
        amounts[0x3c3dd55d16aCd1aAb51416144c52ff82280Afa9F] = 1000616 * 1e16;
        amounts[0xFaB2Eb1CD3Efa346B08BD4070De865E39bd3680C] = 2001232 * 1e16;
        amounts[0x240F896698438DBB7c4AD9b7372C6ee1e765A488] = 1999922 * 1e16;
        amounts[0xE2C2bbAc29a8991C21D50cFB76d56Ef455D85157] = 1999922 * 1e16;
        amounts[0xeaE98E98CeA0577Cf78e2Efce00B3Faa9444130C] = 184992785 * 1e14;
        amounts[0x956D079B656a3955AB4f2f596d1bbfd6F3Ae60dC] = 2001232 * 1e16;
        amounts[0x409b5A1E2daF5e733B8Eee374a8b33E1cB416ec9] = 1999230768 * 1e13;
        amounts[0xA287c2962547F04D3767cD3caec4328A2Eba4385] = 2001232 * 1e16;
        amounts[0xDCb508f3e0CD7C2FEC52d398d198b567d4F4105F] = 1000616 * 1e16;
        amounts[0xec0e8AA614ECF4b0f5d2e207b2429b513fd899D9] = 2001232 * 1e16;
        amounts[0xaBa8A692CD03D17544a2b1e6387E47337528d625] = 199122584 * 1e14;
        amounts[0xCA7E9521F7Ebad5427B56e9c3ca57Adc691c7532] = 1999922 * 1e16;
        amounts[0x36a28766E34fddA159F04e675dA2da4ca93CA80A] = 1999922 * 1e16;
        amounts[0xAEF26FeF1C987fBce2b11B6D9F2C80d6e6dBF0D7] = 1999922 * 1e16;
        amounts[0x6C07db3AA776E8dFC731056Db2BF9a61f57A71d5] = 2001232 * 1e16;
        amounts[0xf11314F7b48A88F95E58Fde80c6C316611A327F5] = 1999922 * 1e16;
        amounts[0xD0AaDbb08F6A4A2199db933920eB931D21acc3Cd] = 2001232 * 1e16;
        amounts[0xeFCE7A40Fff0873eE2119cECDCFfB221d2E03a21] = 1999922 * 1e16;
        amounts[0x86187Ff9CC0A89d1B27a1Dd091629aAd49EfC652] = 1999922 * 1e16;
        amounts[0xa529339aa7bE19DF5c89D4Ac793E499Ec32bddE1] = 1999922 * 1e16;
        amounts[0xb5E4D8f279E62cbB2D41FF32c4f485C0d465B862] = 1999922 * 1e16;
        amounts[0x450B42eE84b55453a8071b4C89AE8647e702CAc6] = 2001232 * 1e16;
        amounts[0xF48211166b3CC4652732191D8f1ED36792018bd5] = 1997922078 * 1e13;
        amounts[0xbdA86CA868e210e9c94542F413ff554088AE1a3B] = 2001232 * 1e16;
        amounts[0xaEC7a2D62B1bEB5BA9D036734d223Bb0b6092945] = 1999922 * 1e16;
        amounts[0xdD3b82b65Be202cE25384bB92957fFDA0B039AA9] = 2001232 * 1e16;
        amounts[0xF8C869b7db95945A9901e118aCa6C7186Ac7756F] = 2001232 * 1e16;
        amounts[0x19314B322dc158d5a12Ed716047232296786a3Df] = 2001232 * 1e16;
        amounts[0x5c6dB495970d78d1621cedECeBB33DfcF4F5B1E9] = 1999922 * 1e16;
        amounts[0xCa1FE4a17600Da42d26A68C30BD4618e5e3918E5] = 1743073072 * 1e13;
        amounts[0x1a51F545F1115F3047f1F21e8329290CAd2D5e8E] = 2001232 * 1e16;
        amounts[0x8D94877a73E8Cf7DF184a8d5BF4c682aF8f45873] = 2001232 * 1e16;
        amounts[0x32E9a9D06999a600061D34cb9Df05D94fA3F74A8] = 1999922 * 1e16;
        amounts[0x8Eca7FD92e075BDFae952313fc73a4d13a613269] = 999961 * 1e16;
        amounts[0xb72f9D750f822dfA2CeF5c4F0Ef8a098d78e63B4] = 1000616 * 1e16;
        amounts[0x74b46B5DA0bc325d656448dC491A6c7f997b35B3] = 108995749 * 1e14;
        amounts[0x5B8AA03aABde01C9639F5AF4B1bf78871AAc59e2] = 2001232 * 1e16;
        amounts[0xf78446D3Ba37BA7a07B571D487000877ffd12e75] = 2001232 * 1e16;
        amounts[0xc2F323A519beb642690Ea5d89DCcE8e7E5a3E6C8] = 2001232 * 1e16;
        amounts[0xBb30eAc72c3de07Faa25872C561897DC1518898D] = 2001232 * 1e16;
        amounts[0x24c71D60C22e6Ebff34a19fF7e6690a998e3D8a6] = 1997922078 * 1e13;
        amounts[0x545Ed81606A1859D606A9d9BD5E7382561d1A76B] = 1999922 * 1e16;
        amounts[0x4e0cB3d53FF93E447026715429c5C30FB9Ce5902] = 2001232 * 1e16;
        amounts[0xaf014F33A47E1f93465653fd79480Bfe7B59ca5F] = 2001232 * 1e16;
        amounts[0xd29482B384712252678e699A4b21CC6190600D4C] = 2001232 * 1e16;
        amounts[0x256274a216e0a349dC18cae08Ca45631176AF437] = 1999922 * 1e16;
        amounts[0x70fFb1f081DD6184BF706094f27DB048e1836Ae2] = 1000616 * 1e16;
        amounts[0xb1AC9db0d6a1eC291F427ad03fc3B632E1E93a56] = 1999922 * 1e16;
        amounts[0xBa069Ad8843B4bBeF9C92539313398d52846E457] = 1000616 * 1e16;
        amounts[0xd782606CA5c6F07BB806fEDB762b10D26Be0c7E0] = 2001232 * 1e16;
        amounts[0x7A75B04D16ec6840964b4be1e056CD67eCeA329C] = 2001232 * 1e16;
        amounts[0xb353F1f594650aB2E7dD590F06F3f90A20Bb34Ac] = 2001232 * 1e16;
        amounts[0x29F9c4DAE1024Eaf0919A0323d3D4bD87B3Ea27c] = 1999922 * 1e16;
        amounts[0x681C9617cD40921B804cC0556e0e1855e366B3b4] = 14008624 * 1e15;
        amounts[0xBD8Cc8734a4E6bd3B0fDa11Cb3FBa27ca8D91505] = 2001232 * 1e16;
        amounts[0xbDb6d3bB2D26d974D609baB7160a151B518C91b3] = 2001232 * 1e16;
        amounts[0xd569985a46Ce6E43a972b3C2C293CCCE78812634] = 2001232 * 1e16;
        amounts[0x2A682E5b30edE39b6fd6725ea79D28d261887Ee3] = 2001232 * 1e16;
        amounts[0x1Fbd7535F61B075c5c3eC7d5Dccb2C36F93AAAfc] = 2001232 * 1e16;
        amounts[0xe25F364ef1fD700Ff9Ae425B268148E00fDc8e27] = 2001232 * 1e16;
        amounts[0x4101e0c0989eAe6A240Fb61256a782Afe67373F2] = 2001232 * 1e16;
        amounts[0x05cc07b268f9323Efca748b963b7Bcf1a9773ca4] = 2001232 * 1e16;
        amounts[0xBDD426Fc4a728AdCA51D7A769E010EA728dd4bcB] = 2001232 * 1e16;
        amounts[0x7Cb3e2d85CA36148F584FeDDD1A6399b8b5BC2AA] = 2001232 * 1e16;
        amounts[0x79a222A7542C2E9af41e2340A1C929f43FaC698e] = 2001232 * 1e16;
        amounts[0x2aA996D3b385C8E2a8919584dbc6b469D0981910] = 2001232 * 1e16;
        amounts[0xCAf3A6483a1CB3668016596951f3972Db08fbA13] = 2001232 * 1e16;
        amounts[0xe3b2cEd47cF4Fc1D6CB4fE29341f85752b65318a] = 2001232 * 1e16;
        amounts[0x4D2450841261A969421E55AF0b3FEDDD08f08d62] = 2001232 * 1e16;
        amounts[0x21FbBd4bEE33e82773fEe5534e1C796722fbcC11] = 2001232 * 1e16;
        amounts[0x66147955fa144DbBFb47b33EC3E941342e02A6e1] = 2001232 * 1e16;
        amounts[0x770480CF04957719AAcC06DC11720B1Bf9a0e4cA] = 1999922 * 1e16;
        amounts[0x383A09A56E942c2e3A5e5e743E61b352550f668C] = 2001232 * 1e16;
        amounts[0x6C63389536D50D13F39da31C4eCba485BfCf0b04] = 1999230768 * 1e13;
        amounts[0x357CC8A6B19719d797aD77c239E6a0627007a478] = 2001232 * 1e16;
        amounts[0xE299118BCC379d0ccF846a32d554d1422aa6E815] = 2001232 * 1e16;
        amounts[0x7730aBE685F352fe4531Aa5a128fF00Ed12Da96d] = 2001232 * 1e16;
        amounts[0x39919d87F1ABB80BC441aBb5F832335199b9aD79] = 1999922 * 1e16;
        amounts[0x6e85e120e08882b9D3CBE624D294B094689895bE] = 2001232 * 1e16;
        amounts[0x13a3Dc47800fe94bEfb51ee774413A46B887040A] = 1000616 * 1e16;
        amounts[0x894Bdd307A9Dd3822CCB6dfA795c73269162E597] = 14008624 * 1e15;
        amounts[0xc3F9f1cA9ddccceb3e19072425F964dd1CD69453] = 2001232 * 1e16;
        amounts[0xA1fa0055b5ab3EeC696D02c96B3Fe157fB7D3b4f] = 1999230768 * 1e13;
        amounts[0x898F63aF71fEEE64bd579dca8b5c3b0dccccD965] = 2001232 * 1e16;
        amounts[0x9b8baeeEe0eA75dD97Ad57a8fC85701D9B513Fa0] = 999961 * 1e16;
        amounts[0x63EE44E9ea86eBEF09bC81125cA50186f87c984e] = 2001232 * 1e16;
        amounts[0x82CDE55F54A871c45eE01aF972DfEB813fb5A8B2] = 2001232 * 1e16;
        amounts[0xa5bAC91d612D1C296590C928D1a32c58C1128362] = 2001232 * 1e16;
        amounts[0x67675b745aE796C9599fd5e279b2821BE746cA65] = 1707050896 * 1e13;
        amounts[0x4e26Ec7798Cf6832B8D15216f43731016C696532] = 2001232 * 1e16;
        amounts[0x5A03eb5a41B78101745aA953Aa140CCbbAa9748e] = 999961 * 1e16;
        amounts[0xBF8eA672b417fa696A66FFDF71206676e767DF41] = 1000616 * 1e16;
        amounts[0x883398eb0449eD4ffcf287C8f0bDB50959532715] = 1999922 * 1e16;
        amounts[0xf59e7cF09B844cb0FFb8Fdd1C9219d462532A6fA] = 2001232 * 1e16;
        amounts[0x0379ed895F8b2DB1bA771ECDDEE2839E1539fe18] = 2001232 * 1e16;
        amounts[0x0c5A1d7cC48Bf34B90C18BD13c9A3F1aed108f21] = 2001232 * 1e16;
        amounts[0x70Eb0cf94403397374F6919472E6Cc7DdE407C6e] = 1999922 * 1e16;
        amounts[0x75964d63153fB4c496528f991d42231ac7d1715A] = 2001232 * 1e16;
        amounts[0x6024455E988c1c18a0C614Cd2959491F1f33C5A7] = 2001232 * 1e16;
        amounts[0x60A0F99757c3F6060D1CE71f8d35bCC910D06458] = 2001232 * 1e16;
        amounts[0x8159Ce8Ca0E6413f6ab43c3AA79A2926fc532C27] = 2001232 * 1e16;
        amounts[0xA40385991e4D364111e809c1EE045789e8f00Ad7] = 1000616 * 1e16;
        amounts[0x91A5af24fD7fdEb73a584af408E151D69B41eF08] = 1999922 * 1e16;
        amounts[0x83A63A9d490476DfF26c19d2Bc63e238049AFe20] = 11006776 * 1e15;
        amounts[0x8796155C013516341d7c2d6003B308dAA7d97E8b] = 1789101408 * 1e13;
        amounts[0xc4a9D5Eb9A520Bc127ef995f94bFB50b07CeB306] = 2001232 * 1e16;
        amounts[0x6EeB59abdb4250e5085517259d9adb9a3B396f9b] = 2001232 * 1e16;
        amounts[0x9032Ad96e083D26384Edb61a0D837E4a36249865] = 1999922 * 1e16;
        amounts[0x1eA5f3A1ddf6eA1f32B4509019f30AB7df107F55] = 2001232 * 1e16;
        amounts[0xe354D90AE6eB189d543Cb9A295CE7DC61D1f1CC7] = 2001232 * 1e16;
        amounts[0x4cDffd3E11E7B3D102b12B26AE9863C3A1973D31] = 1999922 * 1e16;
        amounts[0x7f2D07f71E5D39eebd85dde76b4c3a0a29BB79CE] = 2001232 * 1e16;
        amounts[0x9F6810A42184c9e8d0D7D0E842E7a97b334B75f1] = 2001232 * 1e16;
        amounts[0x545E3030901eA1dB7B0e6b5a33c955eFb70c60f4] = 2001232 * 1e16;
        amounts[0xa4a674350c1b3192BdE3103A858132AcCfd0E759] = 1999922 * 1e16;
        amounts[0x202834082dd26898e93fdF49973901172695a55f] = 2001232 * 1e16;
        amounts[0xF5012A0606D4EdbF3b0f05A2866C68D3454c0203] = 1999922 * 1e16;
        amounts[0x4270d0b353Af7D6039fCbbE973a2182355731861] = 1997922078 * 1e13;
        amounts[0x9bBD84D0d1A54ceF217c2F8560e8ACfd3D6EE2fC] = 1999922 * 1e16;
        amounts[0x558F634d12d3aC7a7C302b025CeeaC5219b69F34] = 2001232 * 1e16;
        amounts[0xc5DA6F75167F97e360403351F50049c25518dB5E] = 2001232 * 1e16;
        amounts[0x3224B2E817Ba8779A65135305d969e735a1756f9] = 2001232 * 1e16;
        amounts[0xC6279aa9b19F2627b4B0E51A46A975765536BaA1] = 2001232 * 1e16;
        amounts[0xd31A84c20bc430aD75E6a1903E7dDbee52211072] = 2001232 * 1e16;
        amounts[0x4aBe409d169A70676B426d8f851AEed778b6F6F3] = 2001232 * 1e16;
        amounts[0x0a837f75a892F4f21101607ECcEbB8A6525bAdD4] = 2001232 * 1e16;
        amounts[0x5F70AEC1A75BEDb304ED5655679715e6B8c388Fc] = 2003792 * 1e16;
        amounts[0xB6a93DFC06869fA464ECAc1a3500C3b4f73a9d73] = 2000286 * 1e16;
        amounts[0x91b4ADe96e8d0eEfdf2a57cef161D13DC633E0d7] = 2003792 * 1e16;
        amounts[0x5B090Ba5Ed5c9F33E6444AbD81615E4bd039a84D] = 199377304 * 1e14;
        amounts[0x13e5cAfaee2A38428f7dc53997a0d3840fb8DD07] = 1001896 * 1e16;
        amounts[0x39d47Cc8d67D258f4032d7D882d1D1957edcAE57] = 2000286 * 1e16;
        amounts[0x3f4b8C204c9e767cf5AB43Cf7804340d9E4bc910] = 1001896 * 1e16;
        amounts[0x840328CaE74DD63406eBa74A3dC9cF66C02D6602] = 2003792 * 1e16;
        amounts[0x531Cd3DCC079766dDCc33cD88a3dB38B59Bcaa7a] = 2003792 * 1e16;
        amounts[0xE7e65C9A0797A4E22915C60C1825142d57D393fB] = 2003792 * 1e16;
        amounts[0xEE4df0eCEaDA3af096Dd147fb6be740f7Ed8ea87] = 2003792 * 1e16;
        amounts[0x452208A279c9aB7895c7501FCE8c1E044D76D446] = 2000286 * 1e16;
        amounts[0xE89fD16185C2b8084dAFB732E4d857FAEfBE95CD] = 2003792 * 1e16;
        amounts[0xd976DFAd7F9f47490Cc4113d6611FE207C0d3586] = 2000286 * 1e16;
        amounts[0x3080cA7fA2FaB936b15731f176622A90534f679B] = 1001896 * 1e16;
        amounts[0xdbF6cf861828d21f8146a1855321Ec13Ba57D770] = 2001788208 * 1e13;
        amounts[0xdCB760F2f6230bAd77e762c74aCf82e124DAcD5e] = 2003792 * 1e16;
        amounts[0x19Fc031463460f66168421435C3134B9D5a47224] = 2003792 * 1e16;
        amounts[0x283f9AC496f6D43564597B6bEEDDE7847942C888] = 2003792 * 1e16;
        amounts[0xBAE54353D4Db5e4C5a6cC2dda3642211A8dd0f64] = 2003792 * 1e16;
        amounts[0x0C226a67191C7D850e26F9308dA3207cDaD68105] = 2003792 * 1e16;
        amounts[0xe3ECb6BFFa82697a59E6F917103Ef2A22e925dE5] = 2003792 * 1e16;
        amounts[0xa5B5F2dAe4F7C6F79a318EC72D3C2Ffd7Ca15Db0] = 2003792 * 1e16;
        amounts[0x58fa9F0fC5DD4c773fc045AD871445c5C9b6aD93] = 2003792 * 1e16;
        amounts[0x7ba6183BB6f346a670217F8Bb7D3dE90D7ff9147] = 2003792 * 1e16;
        amounts[0x200996Da1DA417327a8D5887d7EB67E78c35F9aa] = 2003792 * 1e16;
        amounts[0xd4eE97d01FFb8794a79089F4A7ced8bc40C0a06e] = 2000286 * 1e16;
        amounts[0xDAfD78B77E21eb6652D50349eB2F7821759A9D0a] = 2003792 * 1e16;
        amounts[0x7172F08a20915b938739CcD53F34D22c18042081] = 2003792 * 1e16;
        amounts[0xcc2bB809c16FAeC1503359D6C5bFB5f0A53F5507] = 2003792 * 1e16;
        amounts[0x1fc731e3c9Bc3877E42aBc3361b1fA0dC85f71D2] = 2003792 * 1e16;
        amounts[0xF53c20708E9Dbc2fb6798Cd8A6F78DA4df4d6F78] = 2003792 * 1e16;
        amounts[0xE883c1E1492bCB6E932e37c681478b2B752d0815] = 2003792 * 1e16;
        amounts[0x9883c9925aca25aD93907616DcBE4900869A9dd6] = 2003792 * 1e16;
        amounts[0x8AA417273f30D8a7127973668D340B8d80F9926B] = 2003792 * 1e16;
        amounts[0x21d3a04D4EFD01F712E432febabfD75B8fb2F2C1] = 2000286 * 1e16;
        amounts[0xF5956676EdB2a330a9865FF994dCFB41CA8D0d6c] = 2003792 * 1e16;
        amounts[0x0F804B0FaFbF7CFf4486DB4E40B7b7FCfa49872d] = 19036024 * 1e15;
        amounts[0x47e4C04d922F7Be5e3c06D9c0173D9Fb5e193308] = 2003792 * 1e16;
        amounts[0x80181c00Fb5F658CD65666FcA1aDa2c197a709BD] = 2003792 * 1e16;
        amounts[0xB9F987Edf468D7da5abC6D14Bc9E98C9C0C39195] = 2003792 * 1e16;
        amounts[0x8fb1209Bc371E543c9EE1F03DC70DcFC7CEb00e2] = 2003792 * 1e16;
        amounts[0xB1633B551011059334Bb8CBa6CeBF5fCC4b70Ea6] = 1015922544 * 1e13;
        amounts[0xC6aAf281B4E677B4910D1f5f05463ba28140b7Cb] = 2003792 * 1e16;
        amounts[0x114af1054aeAA518B00396Ebc45E2321F453a9D2] = 2003792 * 1e16;
        amounts[0xEF8775A84512E66Cb90b032AF6bAe962B5cF7710] = 2003792 * 1e16;
        amounts[0x974991641f4D5148Bd2CCAA972ddfd0750f0F35c] = 2003792 * 1e16;
        amounts[0x86914f65284A7E43F582A35dC4271b0065Cd7254] = 2000286 * 1e16;
        amounts[0x25Bea4C1C81695cd8B8e8BFbC730323882d70C0D] = 2003792 * 1e16;
        amounts[0xf0F56EAA2198Cb66769987F087D544e8c9E5E74c] = 2003792 * 1e16;
        amounts[0x9737D5F33c14B0F63D5E32Cc588a96a0DaBbace9] = 2003792 * 1e16;
        amounts[0xC7359FD33a6e345B77AD760a1815e353bf94f7a6] = 2002376 * 1e16;
        amounts[0x18C272C1A89c84677aAB15992318EC8E17A0cd0B] = 2002376 * 1e16;
        amounts[0xE344714BE22E94E1dcE901Ed339733dAe705d74D] = 2002376 * 1e16;
        amounts[0xa690F85D297E6dA6b94c0E83BBc4cefFb9f4f87F] = 14016632 * 1e15;
        amounts[0x090497Cd6A4C936408FB7c8b270E4272D1787A5A] = 2002376 * 1e16;
    }

    function getVestedAmount(address _account) public view returns (uint256) {
        uint256 totalAmount = amounts[_account];
        if (totalAmount == 0) {
            return 0;
        }

        if (block.number <= fromBlock) {
            return 0;
        }

        if (block.number >= toBlock) {
            return totalAmount;
        }

        uint256 delta = block.number - fromBlock;

        uint256 stage1Delta = delta >= stage1Blocks ? stage1Blocks : delta;
        uint256 numVestOnStage1 = (stage1Delta - 1) / AVG_BLOCKS_PER_MONTH + 1;

        uint256 vestAmount = (numVestOnStage1 * totalAmount) / 10;

        uint256 stage2Delta = delta - stage1Delta;
        uint256 vestBlocksOnStage2 = (stage2Delta / AVG_BLOCKS_PER_DAY) *
            AVG_BLOCKS_PER_DAY;

        vestAmount +=
            (vestBlocksOnStage2 * (totalAmount - vestAmount)) /
            stage2Blocks;

        return vestAmount.min(totalAmount);
    }

    function getWithdrawableAmount(address _account)
        public
        view
        returns (uint256)
    {
        return getVestedAmount(_account) - withdrawn[_account];
    }

    function withdraw() external {
        address beneficiary = _msgSender();

        uint256 amount = getWithdrawableAmount(beneficiary);
        if (amount > 0) {
            withdrawn[beneficiary] += amount;
            IERC20(melosToken).safeTransfer(beneficiary, amount);
        }
    }
}