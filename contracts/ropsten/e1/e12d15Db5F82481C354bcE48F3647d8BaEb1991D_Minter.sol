// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

enum AccessoryType {
    Skin,
    Body,
    EyeWear,
    HeadWear,
    Props
}

enum BoxType {
    Virtual,
    Bronze,
    Silver,
    Gold,
    Platinum,
    Diamond
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./DataTypes.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IOracleRegistry.sol";

/**
    @title Minter, this contract is inherited from chainlink VRFConsumerBase,
    this contract contains purchase function which users interact to mint several base or accessory illuvitars.
    @author Dmitry Yakovlevich
 */

contract Minter is VRFConsumerBase, Ownable {
    using SafeERC20 for IERC20;

    event TreasurySet(address indexed treasury);
    event OracleRegistrySet(address indexed oracleRegistry);
    event RequestFulfilled(bytes32 indexed requestId, uint256 randomNumber);

    /**
     * @notice event emitted random accessory requested.
     * @dev emitted in {purchase} or {requestRandomAgain} function.
     * @param requester requester address.
     * @param requestId requestId number.
     */
    event MintRequested(address indexed requester, bytes32 requestId);

    //Purchase Body struct
    struct PortraitMintParams {
        BoxType boxType;
        uint64 amount;
    }

    //Purchase Accessory struct
    struct AccessorySemiRandomMintParams {
        AccessoryType accessoryType;
        BoxType boxType;
        uint64 amount;
    }

    struct AccessoryFullRandomMintParams {
        BoxType boxType;
        uint64 amount;
    }

    //Purchase RandomAccessory struct
    struct MintRequest {
        address requester;
        PortraitMintParams[] portraitMintParams;
        AccessorySemiRandomMintParams[] accessorySemiRandomMintParams;
        AccessoryFullRandomMintParams[] accessoryFullRandomMintParams;
        uint256 randomNumber;
    }

    struct PortraitInfo {
        BoxType boxType;
        uint8 tier;
        uint256 rand;
    }

    struct AccessoryInfo {
        BoxType boxType;
        AccessoryType accessoryType;
        uint8 tier;
    }

    struct PortraitMintInfo {
        uint256 price;
        uint16[6] tierChances;
    }

    struct AccessoryMintInfo {
        uint256 randomPrice;
        uint256 semiRandomPrice;
        uint16[6] tierChances;
    }

    address private constant ETHER_ADDRESS = address(0x0000000000000000000000000000000000000000);
    uint16 public constant MAX_TIER_CHANCE = 10000;
    uint8 public constant TIER_COUNT = 6;

    mapping(BoxType => PortraitMintInfo) public portraitMintInfo;
    mapping(BoxType => AccessoryMintInfo) public accessoryMintInfo;

    mapping(bytes32 => MintRequest) public mintRequests;

    address public treasury;
    address public weth;
    address public oracleRegistry;
    bytes32 public vrfKeyHash;
    uint256 public vrfFee;

    /**
     * @notice Constructor.
     * @param _vrfCoordinator Chainlink VRF Coordinator address.
     * @param _linkToken LINK token address.
     * @param _vrfKeyhash Key Hash.
     * @param _vrfFee Fee.
     * @param _treasury Treasury Address.
     * @param _weth WETH Address.
     * @param _oracleRegistry IlluviumOracleRegistry Address.
     */
    constructor(
        address _vrfCoordinator,
        address _linkToken,
        bytes32 _vrfKeyhash,
        uint256 _vrfFee,
        address _treasury,
        address _weth,
        address _oracleRegistry
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        require(_treasury != address(0), "cannot zero address");

        vrfKeyHash = _vrfKeyhash;
        vrfFee = _vrfFee;

        emit TreasurySet(_treasury);
        treasury = _treasury;
        weth = _weth;
        oracleRegistry = _oracleRegistry;

        _initializePortraitMintInfo();
        _initializeAccessoryMintInfo();
    }

    /**
     * @notice setFunction for Treasury Address.
     * @dev only owner can call this function.
     * @param treasury_ Treasury Address.
     */
    function setTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "Treasury address cannot zero");
        treasury = treasury_;

        emit TreasurySet(treasury_);
    }

    /**
     * @notice setFunction for OracleRegistry Address.
     * @dev only owner can call this function.
     * @param oracleRegistry_ OracleRegistry Address.
     */
    function setOracleRegistry(address oracleRegistry_) external onlyOwner {
        oracleRegistry = oracleRegistry_;

        emit OracleRegistrySet(oracleRegistry_);
    }

    /**
     * @notice Mint for random accessory, callback for VRFConsumerBase
     * @dev inaccessible from outside
     * @param requestId requested random accesory Id.
     * @param randomNumber Random Number.
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {
        require(mintRequests[requestId].requester != address(0), "No request exist");
        require(mintRequests[requestId].randomNumber == 0, "Random number already fulfilled");

        mintRequests[requestId].randomNumber = randomNumber;

        emit RequestFulfilled(requestId, randomNumber);
    }

    /**
     * @notice Mint for Portrait and Accesory items. Users will send ETH or sILV to mint itmes
     * @param portraitMintParams portrait layer mint params.
     * @param accessorySemiRandomMintParams accessory layer semi random mint params.
     * @param accessoryFullRandomMintParams accessory layer full random mint params.
     * @param paymentToken payment token address.
     */
    function purchase(
        PortraitMintParams[] calldata portraitMintParams,
        AccessorySemiRandomMintParams[] calldata accessorySemiRandomMintParams,
        AccessoryFullRandomMintParams[] calldata accessoryFullRandomMintParams,
        address paymentToken
    ) external payable {
        uint256 etherPrice;

        bytes32 requestId = requestRandomness(vrfKeyHash, vrfFee);

        MintRequest storage mintRequest = mintRequests[requestId];
        require(mintRequest.requester == address(0), "Already requested");
        mintRequest.requester = _msgSender();

        uint256 length = portraitMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            PortraitMintParams memory param = portraitMintParams[i];
            require(param.amount > 0, "Invalid amount");
            etherPrice += uint256(param.amount) * portraitMintInfo[param.boxType].price;
            mintRequest.portraitMintParams.push(param);
        }

        length = accessorySemiRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            AccessorySemiRandomMintParams memory param = accessorySemiRandomMintParams[i];
            require(param.amount > 0, "Invalid amount");
            etherPrice += uint256(param.amount) * accessoryMintInfo[param.boxType].semiRandomPrice;
            mintRequest.accessorySemiRandomMintParams.push(param);
        }

        length = accessoryFullRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            AccessoryFullRandomMintParams memory param = accessoryFullRandomMintParams[i];
            etherPrice += uint256(param.amount) * accessoryMintInfo[param.boxType].randomPrice;
            mintRequest.accessoryFullRandomMintParams.push(param);
        }

        if (paymentToken == ETHER_ADDRESS) {
            require(msg.value == etherPrice, "Invalid price");
            payable(treasury).transfer(etherPrice);
        } else {
            IOracle oracle = IOracle(IOracleRegistry(oracleRegistry).getOracle(weth, paymentToken));
            oracle.update();
            uint256 tokenAmount = oracle.consult(weth, etherPrice);
            require(tokenAmount > 0, "Invalid price");
            IERC20(paymentToken).safeTransferFrom(_msgSender(), treasury, tokenAmount);
        }

        emit MintRequested(_msgSender(), requestId);
    }

    function getMintResult(bytes32 requestId)
        external
        view
        returns (
            address requestor,
            uint256 seed,
            PortraitInfo[] memory portraits,
            AccessoryInfo[] memory accessories
        )
    {
        require(mintRequests[requestId].randomNumber != 0, "No random number generated");
        MintRequest memory mintRequest = mintRequests[requestId];
        requestor = mintRequest.requester;
        seed = mintRequest.randomNumber;

        uint256 rand = seed;
        if (mintRequest.portraitMintParams.length > 0) {
            (portraits, rand) = _getPortraitsInfo(rand, mintRequest.portraitMintParams);
        }

        if (
            mintRequest.accessoryFullRandomMintParams.length > 0 || mintRequest.accessorySemiRandomMintParams.length > 0
        ) {
            accessories = _getAccessoriesInfo(
                rand,
                mintRequest.accessoryFullRandomMintParams,
                mintRequest.accessorySemiRandomMintParams
            );
        }
    }

    function _getPortraitsInfo(uint256 seed, PortraitMintParams[] memory portraitMintParams)
        internal
        view
        returns (PortraitInfo[] memory portraits, uint256 lastRand)
    {
        uint256 portraitAmount;

        uint256 length = portraitMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            portraitAmount += portraitMintParams[i].amount;
        }

        uint256 rand = seed;
        if (portraitAmount > 0) {
            portraits = new PortraitInfo[](portraitAmount);

            for (uint256 i = 0; i < length; i += 1) {
                uint256 amount = portraitMintParams[i].amount;
                for (uint256 j = 0; j < amount; j += 1) {
                    rand = uint256(keccak256(abi.encode(rand, rand)));
                    uint16 chance = uint16(rand % MAX_TIER_CHANCE);
                    uint16[6] memory tierChances = portraitMintInfo[portraitMintParams[i].boxType].tierChances;
                    for (uint8 k = 0; k < TIER_COUNT; k += 1) {
                        if (tierChances[k] > chance) {
                            portraits[i] = PortraitInfo({
                                boxType: portraitMintParams[i].boxType,
                                tier: k,
                                rand: rand / MAX_TIER_CHANCE
                            });
                            break;
                        }
                    }
                }
            }
        }
        lastRand = rand;
    }

    function _getAccessoriesInfo(
        uint256 seed,
        AccessoryFullRandomMintParams[] memory fullRandomMintParams,
        AccessorySemiRandomMintParams[] memory semiRandomMintParams
    ) internal view returns (AccessoryInfo[] memory accessories) {
        uint256 fullRandomAmount;
        uint256 semiRandomAmount;
        uint256 length = fullRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            fullRandomAmount += fullRandomMintParams[i].amount;
        }

        length = semiRandomMintParams.length;
        for (uint256 i = 0; i < length; i += 1) {
            semiRandomAmount += semiRandomMintParams[i].amount;
        }

        uint256 rand = seed;
        if (semiRandomAmount > 0 || fullRandomAmount > 0) {
            accessories = new AccessoryInfo[](semiRandomAmount + fullRandomAmount);

            for (uint256 i = 0; i < length; i += 1) {
                uint256 amount = semiRandomMintParams[i].amount;
                for (uint256 j = 0; j < amount; j += 1) {
                    rand = uint256(keccak256(abi.encode(rand, rand)));
                    uint16 chance = uint16(rand % MAX_TIER_CHANCE);
                    uint16[6] memory tierChances = accessoryMintInfo[semiRandomMintParams[i].boxType].tierChances;
                    for (uint8 k = 0; k < TIER_COUNT; k += 1) {
                        if (tierChances[k] > chance) {
                            accessories[i] = AccessoryInfo({
                                boxType: semiRandomMintParams[i].boxType,
                                accessoryType: semiRandomMintParams[i].accessoryType,
                                tier: k
                            });
                            break;
                        }
                    }
                }
            }

            length = fullRandomMintParams.length;
            for (uint256 i = 0; i < length; i += 1) {
                uint256 amount = fullRandomMintParams[i].amount;
                for (uint256 j = 0; j < amount; j += 1) {
                    rand = uint256(keccak256(abi.encode(rand, rand)));
                    uint16 chance = uint16(rand % MAX_TIER_CHANCE);
                    AccessoryType accessoryType = AccessoryType(uint8((rand / MAX_TIER_CHANCE) % 5));
                    uint16[6] memory tierChances = accessoryMintInfo[fullRandomMintParams[i].boxType].tierChances;
                    for (uint8 k = 0; k < TIER_COUNT; k += 1) {
                        if (tierChances[k] > chance) {
                            accessories[i + semiRandomAmount] = AccessoryInfo({
                                boxType: fullRandomMintParams[i].boxType,
                                accessoryType: accessoryType,
                                tier: k
                            });
                            break;
                        }
                    }
                }
            }
        }
    }

    function fulfillMintRequest(bytes32 requestId) external onlyOwner {
        require(mintRequests[requestId].requester != address(0), "Request does not exist!");
        require(mintRequests[requestId].randomNumber != 0, "Random number not generated");
        delete mintRequests[requestId];
    }

    function _initializePortraitMintInfo() internal {
        portraitMintInfo[BoxType.Virtual] = PortraitMintInfo({ price: 0, tierChances: [10000, 0, 0, 0, 0, 0] });
        portraitMintInfo[BoxType.Bronze] = PortraitMintInfo({
            price: 5e16,
            tierChances: [0, 8000, 9700, 9930, 9980, 10000]
        });
        portraitMintInfo[BoxType.Silver] = PortraitMintInfo({
            price: 10e16,
            tierChances: [0, 6100, 8800, 9700, 9950, 10000]
        });
        portraitMintInfo[BoxType.Gold] = PortraitMintInfo({
            price: 25e16,
            tierChances: [0, 2400, 6600, 8800, 9700, 10000]
        });
        portraitMintInfo[BoxType.Platinum] = PortraitMintInfo({
            price: 75e16,
            tierChances: [0, 500, 2000, 4250, 8250, 10000]
        });
        portraitMintInfo[BoxType.Diamond] = PortraitMintInfo({
            price: 250e16,
            tierChances: [0, 200, 1000, 2500, 5000, 10000]
        });
    }

    function _initializeAccessoryMintInfo() internal {
        accessoryMintInfo[BoxType.Virtual] = AccessoryMintInfo({
            randomPrice: 0,
            semiRandomPrice: 0,
            tierChances: [10000, 0, 0, 0, 0, 0]
        });
        accessoryMintInfo[BoxType.Bronze] = AccessoryMintInfo({
            randomPrice: 5e16,
            semiRandomPrice: 10e16,
            tierChances: [0, 8100, 9200, 9700, 9900, 10000]
        });
        accessoryMintInfo[BoxType.Silver] = AccessoryMintInfo({
            randomPrice: 10e16,
            semiRandomPrice: 20e16,
            tierChances: [0, 3000, 7600, 8800, 9700, 10000]
        });
        accessoryMintInfo[BoxType.Gold] = AccessoryMintInfo({
            randomPrice: 15e16,
            semiRandomPrice: 30e16,
            tierChances: [0, 1500, 4700, 7200, 9000, 10000]
        });
        accessoryMintInfo[BoxType.Platinum] = AccessoryMintInfo({
            randomPrice: 20e16,
            semiRandomPrice: 40e16,
            tierChances: [0, 500, 2000, 5300, 8000, 10000]
        });
        accessoryMintInfo[BoxType.Diamond] = AccessoryMintInfo({
            randomPrice: 25e16,
            semiRandomPrice: 50e16,
            tierChances: [0, 100, 600, 2800, 6000, 10000]
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IOracle {
    /**
     * @notice Updates the oracle with the price values if required, for example
     *      the cumulative price at the start and end of a period, etc.
     *
     * @dev This function is part of the oracle maintenance flow
     */
    function update() external;

    /**
     * @notice For a pair of tokens A/B (sell/buy), consults on the amount of token B to be
     *      bought if the specified amount of token A to be sold
     *
     * @dev This function is part of the oracle usage flow
     *
     * @param token token A (token to sell) address
     * @param amountIn amount of token A to sell
     * @return amountOut amount of token B to be bought
     */
    function consult(address token, uint256 amountIn) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * @title Oracle Registry interface
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 */

interface IOracleRegistry {
    /**
     * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
     *
     * @param tokenA token A (token to sell) address
     * @param tokenB token B (token to buy) address
     * @return pairOracle pair price oracle address for A/B token pair
     */
    function getOracle(address tokenA, address tokenB) external view returns (address pairOracle);
}