/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

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

// File: @chainlink/contracts/src/v0.8/VRFRequestIDBase.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBase.sol


pragma solidity ^0.8.0;



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
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
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

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/DevBearcoin.sol


pragma solidity 0.8.10;








struct Deflation {
    uint blocknumber;
    address account;
    uint256 amount;
}

contract DevBearcoin is ERC20, Ownable, KeeperCompatibleInterface, VRFConsumerBase {
  bool private _inflationDeflationPaused;  //Used temporarily in case of price data failure...
  uint32 private _inflationCoef = 1e6;  //1000000 = 1 = no change; valid range 950000 - 1050000 (since max 5% swing)
  uint256 private constant _oneToken = 1e8;

  uint256 private _genesisTimestamp;
  uint256 private _genesisBitcoinPrice = 363097e7;  //Only reason it's not a constant is so we can mess with it in dev mode
  uint256 private constant _genesisBearcoinSupply = 21e6 * _oneToken;

  uint256 private _airdropStartAt;
  uint256 private constant _airdropSupply = _genesisBearcoinSupply * 38 / 100;
  uint256 private _lastAirdropAt;
  uint256 private constant _airdropsPerUpkeep = 20;  //Max airdrop distributions a single upkeep run will attempt (must be <= than maxPendingDeflationCount, since we could need to deflate once for each airdrop)
  uint8 private constant _startAirdropAfterDays = 30; //Start the airdrop this many days after contract is deployed
  uint256 private constant _minPreferredAirdrop = 100 * _oneToken;  //Minimum amount of each airdrop (though on the last distribution we'll probably do less)

  uint8 private constant _maxPendingDeflationCount = 50;  //Only allow this many pending deflations to accumulate
  Deflation[_maxPendingDeflationCount] private _pendingDeflation; //Tracks deflation for the current transaction and the previous ones

  AggregatorV3Interface private _priceFeed;

  uint256 private _bitcoinPrice = _genesisBitcoinPrice;
  uint256 private _desiredSupply = _genesisBearcoinSupply;

  uint256 private _lastUpkeepAt;
  uint256 private _lastRateUpdateAt;
  uint256 private _lastRandomSeedUpdateAt;

  //Every address which has enabled inflation/deflation
  address[] private _inflatees_deflatees;
  mapping(address => uint256) private _inflatees_deflatees_map;
  uint8 private constant _minInflationPoolBalance = 100;

  //Randomness
  uint32 private constant _randomSeedUpdateSeconds = 3600;
  bytes32 private s_keyHash;
  uint256 private s_fee;
  uint256 private _randomSeed = 1111111; //Will be updated periodically with truly random data

  //How often will the upkeep function run
  uint32 private constant _upkeepSeconds = 200;

  //Don't let the bitcoin price be updated more than every few seconds
  uint32 private constant _bitcoinPriceUpdateRateLimitSeconds = 60;

  event RateUpdateFailure(uint256 unixtime, uint8 diffPercent);
  event RateUpdateSuccess(uint256 unixtime, uint32 inflationCoef);
  event RandomSeedUpdateSuccess(uint256 unixtime);
  event FetchedBitcoinPrice(uint256 unixtime, int256 price);
  event ReceivedInflation(address indexed recipient, uint256 amount);
  event BurnedDeflation(address indexed account, uint256 amount);
  event InflationDeflationEnabled(address account);
  event Airdrop(address indexed account, uint256 amount);
  event InsufficientLINK();
  event DailyAirdropComplete();

  /* DEV/TEST EVENTS */

  event DebugUint256(uint256 value);
  event DebugAddress(address value);
  event DebugBool( bool value );
  event DebugBytes32(bytes32 value);

  constructor() ERC20("BTC Bearcoin", "BTCBEAR") VRFConsumerBase(
        0x8C7382F9D8f56b33781fE506E897a4F1e2d17255, // VRF Coordinator
        0x326C977E6efc84E512bB9C30f76E30c160eD06FB  // LINK Token
    )
  {
    _priceFeed = AggregatorV3Interface(0x007A22900a3B98143368Bd5906f8E17e9867581b);  //Polygon Testnet BTC / USD

    //Randomness
    s_keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;

    onDeploy();
  }

  /* START DEV/TEST FUNCTIONS */

  function devSetGenesisTimestamp( uint256 timestamp ) public onlyOwner {
    _genesisTimestamp = timestamp;
  }

  function devSetGenesisBitcoinPrice( uint256 price ) public onlyOwner {
    _genesisBitcoinPrice = price;
  }

  function devSetCurrentBitcoinPrice( uint256 price ) public onlyOwner {
    _bitcoinPrice = price;
    updateInflationDeflationRate();
  }

  function devSetLastRateUpdateAt( uint256 timestamp ) public onlyOwner {
    _lastRateUpdateAt = timestamp;
  }

  function devSetLastRandomSeedUpdateAt( uint256 timestamp ) public onlyOwner {
    _lastRandomSeedUpdateAt = timestamp;
  }

  function devSetRandomSeed( uint256 seed ) public onlyOwner {
    _randomSeed = seed;
  }

  function devRandomSeed() public view onlyOwner returns (uint256) {
    return _randomSeed;
  }

  function devSetLastUpkeepAt( uint256 timestamp ) public onlyOwner {
    _lastUpkeepAt = timestamp;
  }

  function devPerformUpkeepUpdateRate( bytes calldata /* performData */ ) external onlyOwner {
    updateInflationDeflationRate();
  }

  function devPerformUpkeepCheckLink( bytes calldata /* performData */ ) external onlyOwner {
    if ( LINK.balanceOf(address(this)) >= s_fee ) {
      emit DebugBool(true);
    }
    else {
      emit DebugBool(false);
    }
  }

  function devPerformUpkeepRequestRandomness( bytes calldata /* performData */ ) external onlyOwner {
    requestRandomness(s_keyHash, s_fee);
  }

  function devSetAirdropStartAt( uint256 timestamp ) public onlyOwner {
    _airdropStartAt = timestamp;
  }

  function devStartAirdrop() public onlyOwner {
    _startAirdrop();
  }

  function devAirdrop() external onlyOwner {
    airdrop();
  }

  function devSetLastAirdropAt( uint256 timestamp ) public onlyOwner {
    _lastAirdropAt = timestamp;
  }

  function devInflateOrDeflateAmount(uint256 amount) public view returns (uint256)  {
    return inflateOrDeflateAmount(amount);
  }

  /* END DEV/TEST FUNCTIONS */

  function decimals() public view virtual override returns (uint8) {
    return 8;
  }

  //If we have deflation pending from a previous transaction, burn it
  function burnPreviousDeflation() public {
    for ( uint8 i = 0; i < _pendingDeflation.length; i++ ) {
      if ( _pendingDeflation[i].account != address(0) && _pendingDeflation[i].blocknumber != block.number ) {
        address account = _pendingDeflation[i].account;
        uint256 amount = _pendingDeflation[i].amount;

        //Clear out the record before we actually burn
        _pendingDeflation[i].account = address(0);
        _pendingDeflation[i].amount = 0;
        _pendingDeflation[i].blocknumber = 0;

        _burn(account, amount);
        emit BurnedDeflation(account, amount);
      }
    }
  }

  //Returns the balanceOf an account, less pending deflation
  function balanceLessDeflationOf(address account) public view returns (uint256) {
    uint256 balance = balanceOf(account);
    uint256 pending = pendingDeflationOf(account);

    return balance - pending;
  }

  function pendingDeflationOf(address account) public view returns (uint256) {
    uint256 totalPendingDeflation = 0;
    for ( uint8 i=0; i < _pendingDeflation.length; i++ ) {
      if ( _pendingDeflation[i].account == account ) {
        totalPendingDeflation += _pendingDeflation[i].amount;
      }
    }

    return totalPendingDeflation;
  }

  //If only one account is deflatable, it gets deflated. If both are deflatable, the receiver gets deflated
  function _allocateDeflation(address sender, address recipient, uint256 amount) private {
    bool sender_enabled = inflationDeflationEnabled(sender);
    bool recipient_enabled = inflationDeflationEnabled(recipient);

    if ( recipient_enabled ) {
      //Recipient pays if both are enabled or just the recipient is enabled
      _pushPendingDeflation(recipient, amount);
    }
    else if ( sender_enabled ) {
      //Sender pays if only sender is enabled
      _pushPendingDeflation(sender, amount);
    }
  }

  //Record pending deflation so it can be burned by the next transaction
  function _pushPendingDeflation(address account, uint256 amount) private {
    bool added = false;

    //Attempt to find an unused slot
    for( uint8 i = 0; i < _pendingDeflation.length; i++) {
      if ( _pendingDeflation[i].account == address(0) ) {
        _pendingDeflation[i].blocknumber = block.number;
        _pendingDeflation[i].account = account;
        _pendingDeflation[i].amount = amount;
        added = true;
        break;
      }
    }

    require(added, "too much deflation in one transaction");
  }

  //Returns whether a particular account is subject to inflation/deflation
  function inflationDeflationEnabled( address account ) public view returns (bool) {
    return _inflatees_deflatees_map[account] > 0; //The special value 1 counts as true
  }

  //Returns whether the _msgSender account account is subject to inflation/deflation
  function inflationDeflationEnabled() external virtual returns (bool) {
    return inflationDeflationEnabled( _msgSender() );
  }

  //Enables inflation/deflation on a particular account
  function enableInflationDeflation() external virtual {
    require(_msgSender() != owner(), "the owner account is not allowed to enable inflation/deflation");
    require(!inflationDeflationEnabled(_msgSender()), "inflation/deflation was already enabled on this account");
    _addInflateeDeflatee( _msgSender() );
  }

  //Implement inflation and deflation
  function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
    super._beforeTokenTransfer(sender, recipient, amount);

    //Ignore if we're minting or burning
    if ( sender != address(0) && recipient != address(0) && sender != recipient && amount > 0 ) {
      //Burn any deflation from the previous transaction
      burnPreviousDeflation();

      require(recipient != address(this), "transfer not allowed to the contract address (you're welcome)");

      if ( !_inflationDeflationPaused ) {
        uint256 correctAmount = inflateOrDeflateAmount(amount);

        if ( correctAmount > amount ) {
          _inflate(correctAmount - amount); //Randomly allocate the inflation
        }
        else if ( amount > correctAmount ) {
          _allocateDeflation(sender, recipient, amount - correctAmount); //Earmark deflation
        }
      }

      //Make sure they can't bypass pending deflation (even if inflation/deflation are paused)
      if ( inflationDeflationEnabled(sender) ) {
        uint256 senderBalance = balanceLessDeflationOf(sender);
        require(senderBalance >= amount, "transfer amount (including pending deflation) exceeds balance");

        //Now remove the sender from the inflation pool if they have too small a balance
        if ( senderBalance - amount < _minInflationPoolBalance ) {
          _removeFromInflationDeflationPool(sender);
        }
      }
      //Can't transfer negative balances, so don't have to worry about the recipient's pending deflation
    }
  }

  //See if we might need to add them to the pool (if inflation/deflation is enabled but they're not in the pool yet)
  function _afterTokenTransfer(address /*from*/, address to, uint256 /*amount*/) internal override {
    if ( inflationDeflationEnabled(to) && _inflatees_deflatees_map[to] == 1 ) {
      _addInflateeDeflatee(to);
    }
  }

  //This address is removed from the pool but remains in the mapping with the special value 1 (meaning "enabled but not a pool-worthy balance")
  function _removeFromInflationDeflationPool(address account) private {
    uint256 currentIndex = _inflatees_deflatees_map[account];
    //Since 1 is a special case meaning "not in the pool"
    if ( currentIndex > 1 ) {
      _inflatees_deflatees[currentIndex] = address(0);  //Remove address from the pool
    }

    //Mark address as "not currently the pool"
    //1 is a special case meaning "inflation/deflation is enabled on this account but below minimum balance so not in the pool"
    _inflatees_deflatees_map[account] = 1;
  }

  //Adds an account to the inflatee/deflatee mapping and (balance permitting) to the inflation pool
  function _addInflateeDeflatee(address account) private {
    uint256 currentIndex = _inflatees_deflatees_map[account];
    bool poolEligible = balanceLessDeflationOf(account) >= _minInflationPoolBalance;

    //Only add them if they're not there already (or there but not in the pool and now they have a pool-worthy balance)
    if ( currentIndex == 0 || (currentIndex == 1 && poolEligible) ) {
      if ( currentIndex == 0) {
        emit InflationDeflationEnabled( account );
      }

      //Default is special value 1 meaning "enabled but insufficient balance"
      uint256 addedIndex = 1;

      //If they deserve a spot in the pool, add them to _inflatees_deflatees as well
      if ( poolEligible ) {
        //Try to find an empty slot to pop them in (to keep the array dense)
        bool added = false;
        uint256 poolSize = _inflatees_deflatees.length;
        for ( uint8 i = 0; i < 50; i++ ) {
          uint256 randomIndex = random(i) % poolSize;

          //Ignore 0 and 1 since those are special
          if ( randomIndex > 1 ) {
            if ( _inflatees_deflatees[randomIndex] == address(0) ) {
              _inflatees_deflatees[randomIndex] = account;
              added = true;
              addedIndex = randomIndex;
              break;
            }
          }
        }

        //Append only if we didn't find a blank one
        if ( !added ) {
          _inflatees_deflatees.push( account );
          addedIndex = poolSize;  //since we just added one
        }
      }

      //Now add the proper index to the mapping
      _inflatees_deflatees_map[account] = addedIndex;
    }
  }

  //Uses a truly random seed plus some block information plus a one-time use seed
  function random(uint256 callSeed) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(_randomSeed, block.difficulty, block.timestamp, callSeed)));
  }

  //Uses the _inflationCoef to calculate a new inflated/deflated amount
  function inflateOrDeflateAmount(uint256 amount) private view returns (uint256)  {
    uint256 newAmount = (amount * inflationCoef()) / 1e6;
    uint256 currentTotalSupply = totalSupplyLessPendingDeflation();

    //If we're inflating
    if ( newAmount > amount ) {
      if ( _desiredSupply > currentTotalSupply ) {
        uint256 maxDiff = _desiredSupply - currentTotalSupply;
        uint256 amountDiff = newAmount - amount;

        //Make sure we never swing passed the desired supply
        if ( amountDiff > maxDiff ) {
          return amount + maxDiff;
        }
        else {
          return newAmount;
        }
      }
    }
    else if ( amount > newAmount ) {  //We're deflating
      if ( currentTotalSupply > _desiredSupply ) {
        uint256 maxDiff = currentTotalSupply - _desiredSupply;
        uint256 amountDiff = amount - newAmount;

        //Make sure we never swing passed the desired supply
        if ( amountDiff > maxDiff ) {
          return amount - maxDiff;
        }
        else {
          return newAmount;
        }
      }
    }

    return amount;
  }

  //Returns total supply less pending deflation
  function totalSupplyLessPendingDeflation() public view returns (uint256) {
    uint256 totalPendingDeflation = 0;
    for ( uint8 i=0; i < _pendingDeflation.length; i++ ) {
      if ( _pendingDeflation[i].account != address(0) ) {
        totalPendingDeflation += _pendingDeflation[i].amount;
      }
    }

    return totalSupply() - totalPendingDeflation;
  }

  //Can be called by anyone to update the inflation rate (subject to rate limiting)
  function updateInflationDeflationRate() public returns (bool)  {
    require(block.timestamp >= _lastRateUpdateAt + _bitcoinPriceUpdateRateLimitSeconds, "too many requests");

    uint256 previousBitcoinPrice = _bitcoinPrice;
    int256 rawBitcoinPrice = _fetchBitcoinPrice();

    uint256 latestBitcoinPrice = 0;

    //Never, ever allow a bitcoin price of zero or negative
    if ( rawBitcoinPrice > 0 ) {
      latestBitcoinPrice = uint256(rawBitcoinPrice);
    }
    else {
      _inflationDeflationPaused = true;
      return false;
    }

    //Require reasonable changes (otherwise wait until forced reset)
    uint256 priceDiff = 0;
    if ( latestBitcoinPrice > previousBitcoinPrice ) {
      priceDiff = latestBitcoinPrice - previousBitcoinPrice;
    }
    else {
      priceDiff = previousBitcoinPrice - latestBitcoinPrice;
    }

    if ( priceDiff > 0 ) {
      //If more than a 20% price change since the last check (which should happen every few minutes),
      //pause inflation/deflation temporarily since it's probably bad data
      uint8 diffPercent = previousBitcoinPrice > 0 ? uint8((priceDiff * 100) / previousBitcoinPrice) : 100;
      if ( diffPercent > 20 ) {
        if ( !_inflationDeflationPaused ) {
          _inflationDeflationPaused = true;
        }

        //If legit-looking data is unavailable for 7 days, just go with whatever we have now
        if ( _lastRateUpdateAt < block.timestamp - 604800 ) {
          _bitcoinPrice = latestBitcoinPrice;
          _inflationDeflationPaused = false;
          _lastRateUpdateAt = block.timestamp;
        }
        else {
          emit RateUpdateFailure(block.timestamp, diffPercent);
        }
      }
      else {
        _bitcoinPrice = latestBitcoinPrice;
        _lastRateUpdateAt = block.timestamp;
        if ( _inflationDeflationPaused ) {
          _inflationDeflationPaused = false;
        }
      }
    }
    else {  //No change
      if ( _inflationDeflationPaused ) {
        _inflationDeflationPaused = false;
        //Even if there's no change in the price, we still update the inflation rate to take into account totalSupply changes
      }
    }

    if ( _inflationDeflationPaused ) {
      return false;
    }
    else {
      //(bearcoin_desired_supply / bearcoin_genesis_supply) = (bitcoin_current_price / bitcoin_genesis_price)
      _desiredSupply = ( _bitcoinPrice * _genesisBearcoinSupply ) / _genesisBitcoinPrice;

      //Limit to 5% inflation/deflation, normalized to 1,000,000:
      //(desiredBearcoin / currentBearcoin) = (x / 1000000), then capped at +-5%
      _inflationCoef = uint32( Math.max( Math.min( (_desiredSupply * 1e6 / totalSupplyLessPendingDeflation()), 105e4 ), 95e4) );

      emit RateUpdateSuccess(block.timestamp, inflationCoef());
      return true;
    }
  }

  //Randomly distribute tokens to an address in the inflation pool, weighted by balance -
  //we ignore pending deflation for performance/gas cost reasons
  function _inflate(uint256 amount) private {
    if ( amount > 0 ){
      address recipient = address(0);
      uint256 eachBalance = 0;
      address randomAccount = address(0);
      uint256 randomIndex = 0;

      uint256 poolSize = _inflatees_deflatees.length;

      //One tenth of one percent of inflation goes to maintenance costs
      if ( random(poolSize) % 1000 == 500 ) {
        recipient = owner();
      }
      else {
        //Try hard to find the top holder in a bunch of random addresses, weighted by balance (though without burning too much gas)
        //ten cycles pulling 10 addresses each cycle
        for ( uint8 cycle = 0; cycle < 10; cycle++ ) {
          uint256 maxBalance = 0;

          for (uint8 i = 0; i < 10; i++) {
            randomIndex = random(i) % poolSize;

            //Ignore 0 and 1, as they're special values
            if ( randomIndex > 1 ) {
              randomAccount = _inflatees_deflatees[randomIndex];
              if ( randomAccount != address(0) ) {
                eachBalance = balanceOf(randomAccount);
                if ( eachBalance > maxBalance ) {
                  recipient = randomAccount;
                  maxBalance = eachBalance;
                }
              }
            }
          }

          //If we found a winner this cycle, break
          if ( recipient != address(0) ) {
            break;
          }
        }
      }

      if ( recipient != address(0) ) {
        _mint( recipient, amount );
        emit ReceivedInflation(recipient, amount);
      }
      //Else unable to inflate
    }
  }

  //Fetches the latest bitcoin price
  function _fetchBitcoinPrice() private returns (int256) {
    (,int price,,,) = _priceFeed.latestRoundData();
    emit FetchedBitcoinPrice(block.timestamp, price);
    return price;
  }

  //Returns either _inflationCoef or (if inflation/deflation is paused), the default coef representing "no change"
  function inflationCoef() public view returns (uint32) {
    return _inflationDeflationPaused ? 1e6 : _inflationCoef;
  }

  //Returns the current bitcoin price
  function bitcoinPrice() external view returns (uint256) {
    return _bitcoinPrice;
  }

  //Returns the total airdrop amount
  function airdropSupply() public pure returns (uint256) {
    return _airdropSupply;
  }

  //Returns the timestamp when the airdrop started
  function airdropStartAt() external view returns (uint256) {
    return _airdropStartAt;
  }

  //Returns the amount of airdrop that's been distributed
  function airdropDistributed() public view returns (uint256) {
    return airdropSupply() - balanceOf(address(this));
  }

  //Returns the amount of airdrop yet to be distributed
  function airdropRemaining() external view returns (uint256) {
    return airdropSupply() - airdropDistributed();
  }

  //Returns the last airdrop completion timestamp
  function lastAirdropAt() external view returns (uint256) {
    return _lastAirdropAt;
  }

  //Returns the genesis bearcoin supply
  function genesisBearcoinSupply() external pure returns (uint256) {
    return _genesisBearcoinSupply;
  }

  //Returns the genesis bitcoin price
  function genesisBitcoinPrice() external view returns (uint256) {
    return _genesisBitcoinPrice;
  }

  //Returns whether inflation/deflation is paused
  function inflationDeflationPaused() external view returns (bool) {
    return _inflationDeflationPaused;
  }

  //Returns the current desired bearcoin supply
  function desiredSupply() external view returns (uint256) {
    return _desiredSupply;
  }

  //See if the Chainlink Keeper needs to do work
  function checkUpkeep(bytes calldata /*checkData*/) external view override returns (bool upkeepNeeded, bytes memory performData) {
    upkeepNeeded = block.timestamp > _lastUpkeepAt + _upkeepSeconds;
  }

  //Get the latest bitcoin price, request randomness, and airdrop
  //Each of these actions is only called 1/3 of the time, so even if problems with one action
  //cause a revert, the others will continue to function (though less frequently)
  function performUpkeep(bytes calldata /* performData */) public virtual override {
    _lastUpkeepAt = block.timestamp;

    if ( random(1) % 3 == 1 ) {
      //Don't even try if we'd fail
      if ( block.timestamp >= _lastRateUpdateAt + _bitcoinPriceUpdateRateLimitSeconds ) {
        updateInflationDeflationRate();
      }
    }

    if ( random(2) % 3 == 1 ) {
      //Rate limit to protect from draining LINK from the contract...
      if ( block.timestamp >= _lastRandomSeedUpdateAt + _randomSeedUpdateSeconds ) {
        //Be careful not to attempt this unless we have enough LINK
        if ( LINK.balanceOf(address(this)) >= s_fee ) {
          requestRandomness(s_keyHash, s_fee);
        }
        else {
          emit InsufficientLINK();
        }
      }
    }

    if ( random(3) % 3 == 1 ) {
      if ( _airdropStartAt > 0 && _lastAirdropAt < block.timestamp - 1 days && balanceOf(address(this)) > 0 ) {
        //This may be called multiple times until the airdrop is complete for the current day
        airdrop();
      }
      else if ( _airdropStartAt == 0 && block.timestamp > _genesisTimestamp + (1 days * _startAirdropAfterDays) ) {
        //Force the airdrop to start
        _startAirdrop();
      }
    }
  }

  //Internal function to start the airdrop
  function _startAirdrop() private {
    if ( _airdropStartAt == 0 ) {
      _airdropStartAt = block.timestamp;
    }
  }

  function dailyAirdropAmount() public pure returns ( uint256 ) {
    return _airdropSupply / 365;
  }

  function daysIntoAirdrop() public view returns ( uint256 ) {
    return ((block.timestamp - _airdropStartAt) / 1 days);
  }

  //Called by upkeep to distribute airdrops every day
  function airdrop() private {
    //How much was actually distributed by now?
    uint256 distributed = airdropDistributed();

    //How much should have been distributed by now?
    uint256 shouldHaveBeenDistributed = dailyAirdropAmount() * daysIntoAirdrop();

    if ( distributed < shouldHaveBeenDistributed ) {
      //Distribute the difference
      uint256 toBeDistributed = shouldHaveBeenDistributed - distributed;
      uint256 distribution = 0;

      for( uint256 i = 0; i < _airdropsPerUpkeep; i++) {
        if ( toBeDistributed > 0 ) {
          distribution = random(i) % toBeDistributed;
        }
        else {
          //All done
          break;
        }

        //Prefer distributions to be at least _minPreferredAirdrop
        if ( distribution < _minPreferredAirdrop && toBeDistributed >= _minPreferredAirdrop ) {
          distribution = _minPreferredAirdrop;
        }
        else if ( toBeDistributed < _minPreferredAirdrop ) { //Once the total amount remaining drops below the minimum preferred amount, use the full remaining amount
          distribution = toBeDistributed;
        }

        if ( distribution > 0 ) {
          uint256 randomIndex = random(i) % _inflatees_deflatees.length;

          //can't ever run off the end if random() is real small so check end bound too
          if ( randomIndex > 1 && randomIndex < _inflatees_deflatees.length ) {
              address randomAccount = _inflatees_deflatees[randomIndex];
              if ( randomAccount != address(0) ) {
                _transfer(address(this), randomAccount, distribution);
                emit Airdrop(randomAccount, distribution);
                toBeDistributed -= distribution;
              }
          }
        }
        else {
          //All done for today
          break;
        }
      }
    }

    //If we're all caught up on distributions, stop checking till tomorrow
    distributed = airdropDistributed();
    if ( distributed == shouldHaveBeenDistributed ) {
      _lastAirdropAt = block.timestamp;
      emit DailyAirdropComplete();
    }
  }

  //Callback function used by VRF Coordinator
  function fulfillRandomness(bytes32 /*requestId*/, uint256 randomness) internal override {
    _randomSeed = randomness;
    _lastRandomSeedUpdateAt = block.timestamp;
    emit RandomSeedUpdateSuccess(block.timestamp);
  }

  //Initial setup when deploying the contract
  function onDeploy() private {
    _genesisTimestamp = block.timestamp;

    s_fee = 0.0001 * 10 ** 18; // 0.1 LINK (Varies by network)
    _mint(address(this), _airdropSupply);  //Keep airdrop tokens at contract address
    _mint(msg.sender, _genesisBearcoinSupply - _airdropSupply); //Send the rest to owner address for token sale

    //Since 0 and 1 are special values, fill them up with zeros so we start pushing real accounts
    _inflatees_deflatees.push( address(0) );
    _inflatees_deflatees.push( address(0) );
  }
}