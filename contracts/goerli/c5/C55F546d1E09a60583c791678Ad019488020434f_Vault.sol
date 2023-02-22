// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC721A} from "erc721a/contracts/IERC721A.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDiamond} from "../interfaces/IDiamond.sol";



/**
 * @title XGain Vault contract
 * @notice users will deposit NFT to play game and will withdraw NFT from vault
 */
contract Vault is Ownable {
  using SafeERC20 for IERC20;

  struct BuddySlotType {
    uint64 slot0;
    uint64 slot1;
    uint64 slot2;
    uint64 slot3;
  }

  struct BuddySetting {
    uint256 level;
    BuddySlotType slotType;
    uint64 slot0;
    uint64 slot1;
    uint64 slot2;
    uint64 slot3;
    address owner;
  }

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  /// @dev xrcs token address
  address public immutable xrcs;
  /// @dev og contract address
  address public immutable og;
  /// @dev yg contract address
  address public immutable yg;
  /// @dev diamond contract address
  address public immutable diamond;
  /// @dev backend signer address
  address public immutable signer;

  /// @dev level uo fees
  uint256 public ogLevelUpFee = 1e9;
  uint256 public ygLevelUpFee = 1e9;
  uint256 public diamondLevelUpFee = 1e9;

  /// @dev og and yg data mapping(tokenId => BuddySetting)
  mapping(uint256 => BuddySetting) public ogs;
  mapping(uint256 => BuddySetting) public ygs;

  /// @dev diamonds data mapping(tokenId => DiamondSetting)
  mapping(uint256 => uint256) public diamondLevel;

  /// @dev fires when register nft
  event OGRegister(uint256 tokenId, BuddySlotType data);
  event YGRegister(uint256 tokenId, BuddySlotType data);

  /// @dev fires when deposit OG
  event OGDeposit(uint256 tokenId, address owner);

  /// @dev fires when deposit YG
  event YGDeposit(uint256 tokenId, address owner);

  /// @dev fires when withdraw OG
  event OGWithdraw(uint256 tokenId, address owner);

  /// @dev fires when withdraw YG
  event YGWithdraw(uint256 tokenId, address owner);

  /// @dev fires when diamond injected & reject
  event DiamondInjectToOG(uint256 buddyId, uint256 diamondId, uint256 slotId);
  event DiamondRejectFromOG(uint256 buddyId, uint256 slotId);
  event DiamondInjectToYG(uint256 buddyId, uint256 diamondId, uint256 slotId);
  event DiamondRejectFromYG(uint256 buddyId, uint256 slotId);

  /// @dev fires when fee value change
  event FeeChange(uint256 ogLevelUpFee, uint256 ygLevelUpFee, uint256 diamondLevelUpFee);

  /**
   * @param _xrcs og contract address
   * @param _og og contract address
   * @param _yg yg contract address
   * @param _diamond diamond contract address
   * @param _signer signer address
   */
  constructor(address _xrcs, address _og, address _yg, address _diamond, address _signer) {
    xrcs = _xrcs;
    og = _og;
    yg = _yg;
    diamond = _diamond;
    signer = _signer;

    emit FeeChange(ogLevelUpFee, ygLevelUpFee, diamondLevelUpFee);
  }

  /// @dev receive ERC721 contract
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @dev set fees
   * @param _ogLevelUpFee og nft levelup fee
   * @param _ygLevelUpFee yg nft levelup fee
   * @param _diamondLevelUpFee diamond nft levelup fee
   */
  function setFees(
    uint256 _ogLevelUpFee,
    uint256 _ygLevelUpFee,
    uint256 _diamondLevelUpFee
  ) external onlyOwner {
    ogLevelUpFee = _ogLevelUpFee;
    ygLevelUpFee = _ygLevelUpFee;
    diamondLevelUpFee = _diamondLevelUpFee;

    emit FeeChange(_ogLevelUpFee, _ygLevelUpFee, _diamondLevelUpFee);
  }

  /**
   * @dev register buddy nft to vault contract
   * @param isOG true => og, false => yg
   * @param tokenId buddy id
   * @param data buddy slot type data
   * @param sig backend signer wallet sign
   */
  function register(
    bool isOG,
    uint256 tokenId,
    BuddySlotType calldata data,
    Sig calldata sig
  ) external {
    require(_isValidateRegisterParam(data, sig), "Vault: invalid sign");

    if (isOG) {
      require(ogs[tokenId].level == 0, "Vault: your nft already registered");

      ogs[tokenId] = BuddySetting(1, data, 0, 0, 0, 0, address(0));
      emit OGRegister(tokenId, data);
    } else {
      require(ygs[tokenId].level == 0, "Vault: your nft already registered");

      ygs[tokenId] = BuddySetting(1, data, 0, 0, 0, 0, address(0));
      emit YGRegister(tokenId, data);
    }
  }

  /**
   * @dev deposit NFT to vault
   * @param tokenId nft id
   */
  function depositOG(uint256 tokenId) external {
    require(ogs[tokenId].level > 0, "Vault: your nft doesn't registered");

    ogs[tokenId].owner = msg.sender;

    IERC721A(og).safeTransferFrom(msg.sender, address(this), tokenId);

    emit OGDeposit(tokenId, msg.sender);
  }

  /**
   * @dev withdraw NFT from vault
   * @param tokenId nft id
   */
  function withdrawOG(uint256 tokenId) external {
    require(ogs[tokenId].owner == msg.sender, "Vault: your aren't owner of nft");

    ogs[tokenId].owner = address(0);

    IERC721A(og).safeTransferFrom(address(this), msg.sender, tokenId);

    emit OGWithdraw(tokenId, msg.sender);
  }

  /**
   * @dev deposit NFT to vault
   * @param tokenId nft id
   */
  function depositYG(uint256 tokenId) external {
    require(ygs[tokenId].level > 0, "Vault: your nft doesn't registered");

    ygs[tokenId].owner = msg.sender;

    IERC721A(yg).safeTransferFrom(msg.sender, address(this), tokenId);

    emit YGDeposit(tokenId, msg.sender);
  }

  /**
   * @dev withdraw NFT from vault
   * @param tokenId nft id
   */
  function withdrawYG(uint256 tokenId) external {
    require(ygs[tokenId].owner == msg.sender, "Vault: your aren't owner of nft");

    ygs[tokenId].owner = address(0);

    IERC721A(yg).safeTransferFrom(address(this), msg.sender, tokenId);

    emit YGWithdraw(tokenId, msg.sender);
  }

  /**
   * @dev inject diamond to og
   * @param buddyId buddy token Id
   * @param diamondId diamond token Id
   * @param slotId slot id of buddy
   */
  function injectDiamondToOG(uint256 buddyId, uint256 diamondId, uint256 slotId) external {
    require(ogs[buddyId].owner == msg.sender, "Vault: you aren't owner of this nft");

    uint64 slotType;
    if (slotId == 0) {
      slotType = ogs[buddyId].slotType.slot0;
      require(ogs[buddyId].slot0 == 0, "Vault: already injected another diamond");

      ogs[buddyId].slot0 = uint64(diamondId);
    } else if (slotId == 1) {
      slotType = ogs[buddyId].slotType.slot1;
      require(ogs[buddyId].slot3 == 0, "Vault: already injected another diamond");

      ogs[buddyId].slot1 = uint64(diamondId);
    } else if (slotId == 2) {
      slotType = ogs[buddyId].slotType.slot2;
      require(ogs[buddyId].slot2 == 0, "Vault: already injected another diamond");

      ogs[buddyId].slot2 = uint64(diamondId);
    } else if (slotId == 3) {
      slotType = ogs[buddyId].slotType.slot3;
      require(ogs[buddyId].slot3 == 0, "Vault: already injected another diamond");

      ogs[buddyId].slot3 = uint64(diamondId);
    } else {
      revert("Vault: invalid slot id");
    }
    require(slotType == IDiamond(diamond).types(diamondId), "Vault: invalid slot type");

    IERC721A(diamond).safeTransferFrom(msg.sender, address(this), diamondId);

    emit DiamondInjectToOG(buddyId, diamondId, slotId);
  }

  /**
   * @dev reject diamond from og
   * @param buddyId buddy token Id
   * @param slotId slot id of buddy
   */
  function rejectDiamondFromOG(uint256 buddyId, uint256 slotId) external {
    require(ogs[buddyId].owner == msg.sender, "Vault: Vault: you aren't owner of this nft");

    uint256 diamondId;
    if (slotId == 0) {
      require(ogs[buddyId].slot0 > 0, "Vault: diamond doesn't injected");

      diamondId = ogs[buddyId].slot0;
      ogs[buddyId].slot0 = uint64(0);
    } else if (slotId == 1) {
      require(ogs[buddyId].slot3 > 0, "Vault: diamond doesn't injected");

      diamondId = ogs[buddyId].slot1;
      ogs[buddyId].slot1 = uint64(0);
    } else if (slotId == 2) {
      require(ogs[buddyId].slot2 > 0, "Vault: diamond doesn't injected");

      diamondId = ogs[buddyId].slot2;
      ogs[buddyId].slot2 = uint64(0);
    } else if (slotId == 3) {
      require(ogs[buddyId].slot3 > 0, "Vault: diamond doesn't injected");

      diamondId = ogs[buddyId].slot0;
      ogs[buddyId].slot3 = uint64(0);
    } else {
      revert("Vault: invalid slot id");
    }

    IERC721A(diamond).safeTransferFrom(address(this), msg.sender, diamondId);

    emit DiamondRejectFromOG(buddyId, slotId);
  }

  /**
   * @dev inject diamond to yg
   * @param buddyId buddy token Id
   * @param diamondId diamond token Id
   * @param slotId slot id of buddy
   */
  function injectDiamondToYG(uint256 buddyId, uint256 diamondId, uint256 slotId) external {
    require(ygs[buddyId].owner == msg.sender, "Vault: Vault: you aren't owner of this nft");

    uint64 slotType;
    if (slotId == 0) {
      slotType = ygs[buddyId].slotType.slot0;
      require(ygs[buddyId].slot0 == 0, "Vault: already injected another diamond");

      ygs[buddyId].slot0 = uint64(diamondId);
    } else if (slotId == 1) {
      slotType = ygs[buddyId].slotType.slot1;
      require(ygs[buddyId].slot3 == 0, "Vault: already injected another diamond");

      ygs[buddyId].slot1 = uint64(diamondId);
    } else if (slotId == 2) {
      slotType = ygs[buddyId].slotType.slot2;
      require(ygs[buddyId].slot2 == 0, "Vault: already injected another diamond");

      ygs[buddyId].slot2 = uint64(diamondId);
    } else if (slotId == 3) {
      slotType = ygs[buddyId].slotType.slot3;
      require(ygs[buddyId].slot3 == 0, "Vault: already injected another diamond");

      ygs[buddyId].slot3 = uint64(diamondId);
    } else {
      revert("Vault: invalid slot id");
    }
    require(slotType == IDiamond(diamond).types(diamondId), "Vault: invalid slot type");

    if (diamondLevel[diamondId] == 0) {
      diamondLevel[diamondId] = 1;
    }

    IERC721A(diamond).safeTransferFrom(msg.sender, address(this), diamondId);

    emit DiamondInjectToYG(buddyId, diamondId, slotId);
  }

  /**
   * @dev reject diamond from yg
   * @param buddyId buddy token Id
   * @param slotId slot id of buddy
   */
  function rejectDiamondFromYG(uint256 buddyId, uint256 slotId) external {
    require(ygs[buddyId].owner == msg.sender, "Vault: Vault: you aren't owner of this nft");

    uint256 diamondId;
    if (slotId == 0) {
      require(ygs[buddyId].slot0 > 0, "Vault: diamond doesn't injected");

      diamondId = ygs[buddyId].slot0;
      ygs[buddyId].slot0 = uint64(0);
    } else if (slotId == 1) {
      require(ygs[buddyId].slot3 > 0, "Vault: diamond doesn't injected");

      diamondId = ygs[buddyId].slot1;
      ygs[buddyId].slot1 = uint64(0);
    } else if (slotId == 2) {
      require(ygs[buddyId].slot2 > 0, "Vault: diamond doesn't injected");

      diamondId = ygs[buddyId].slot2;
      ygs[buddyId].slot2 = uint64(0);
    } else if (slotId == 3) {
      require(ygs[buddyId].slot3 > 0, "Vault: diamond doesn't injected");

      diamondId = ygs[buddyId].slot0;
      ygs[buddyId].slot3 = uint64(0);
    } else {
      revert("Vault: invalid slot id");
    }

    IERC721A(diamond).safeTransferFrom(address(this), msg.sender, diamondId);

    emit DiamondRejectFromYG(buddyId, slotId);
  }

  /// @dev validate register params
  function _isValidateRegisterParam(
    BuddySlotType calldata data,
    Sig calldata sig
  ) private view returns (bool) {
    bytes32 messageHash = keccak256(
      abi.encodePacked(msg.sender, data.slot0, data.slot1, data.slot2, data.slot3)
    );

    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    return signer == ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IDiamond {
  /**
   * @dev enum of diamond type
   */
  enum DiamondType {
    BMUpperBody,
    BMCore,
    BMLowerBody,
    REUpperBody,
    RECore,
    RELowerBody,
    BoosterCardio,
    BoosterStrength,
    XRCSgains,
    Luck,
    Recovery
  }

  /// @dev returns diamond types
  function types(uint256) external returns (uint32);

  /// @dev A way for the owner to reserve a specifc number of NFTs without having to
  function reserve(address _to, uint256 _amount, DiamondType _diamondType) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}