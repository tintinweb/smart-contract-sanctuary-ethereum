/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)
// MetaPiggyBanks.io

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


interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
  external
  view
  returns (
    uint16,
    uint32,
    bytes32[] memory
  );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
  external
  view
  returns (
    uint96 balance,
    uint64 reqCount,
    address owner,
    address[] memory consumers
  );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

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
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
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
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}



/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
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
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId) external view returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

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
 * @dev String operations.
 */
library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }
}

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
  unchecked {
    counter._value += 1;
  }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    require(value > 0, "Counter: decrement overflow");
  unchecked {
    counter._value = value - 1;
  }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
  }
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}

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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
  /**
   * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
  function verify(
    bytes32[] memory proof,
    bytes32 root,
    bytes32 leaf
  ) internal pure returns (bool) {
    return processProof(proof, leaf) == root;
  }

  /**
   * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
  function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];
      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = _efficientHash(computedHash, proofElement);
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = _efficientHash(proofElement, computedHash);
      }
    }
    return computedHash;
  }

  function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
    assembly {
      mstore(0x00, a)
      mstore(0x20, b)
      value := keccak256(0x00, 0x40)
    }
  }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
}


contract PiggyBreaker is VRFConsumerBaseV2, IERC721Receiver, Ownable {

  VRFCoordinatorV2Interface COORDINATOR;

  // Your subscription ID.
  uint64 s_subscriptionId;

  // Rinkeby coordinator. For other networks,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // RINKEBY = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;

  // The gas lane to use, which specifies the maximum gas price to bump to.
  // For a list of available gas lanes on each network,
  // see https://docs.chain.link/docs/vrf-contracts/#configurations
  // RINKEBY = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

  // Depends on the number of requested values that you want sent to the
  // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
  // so 100,000 is a safe default for this example contract. Test and adjust
  // this limit based on the network that you select, the size of the request,
  // and the processing of the callback request in the fulfillRandomWords()
  // function.
  uint32 callbackGasLimit = 1000000;

  // The default is 3, but you can set this higher.
  uint16 requestConfirmations = 3;

  IERC721 MetaPiggyBanksToken;
  // RINKEBY = 0x728B18D1Bc6F0d9e0E5D23212Bf69B334DDC6De2
  address MPBAddress = 0x728B18D1Bc6F0d9e0E5D23212Bf69B334DDC6De2;

  uint16[555] public piggyIds = [69, 138, 234, 217, 110, 342, 362, 536, 17, 336, 87, 165, 292, 419, 222, 468, 455, 335, 236, 500, 421, 210, 386, 62, 41, 58, 457, 76, 146, 300, 511, 313, 134, 231, 438, 443, 309, 64, 223, 254, 97, 391, 498, 256, 485, 425, 337, 250, 117, 530, 509, 394, 417, 247, 172, 31, 244, 426, 372, 34, 157, 1, 72, 522, 299, 200, 378, 189, 281, 95, 168, 142, 14, 273, 369, 61, 550, 460, 514, 465, 546, 140, 183, 431, 521, 123, 60, 315, 93, 35, 324, 59, 177, 311, 302, 293, 180, 184, 195, 321, 73, 418, 305, 12, 148, 396, 524, 303, 475, 308, 349, 218, 253, 204, 377, 202, 374, 504, 190, 467, 43, 554, 547, 490, 385, 403, 107, 278, 91, 527, 114, 285, 287, 116, 11, 255, 534, 68, 13, 330, 352, 10, 298, 551, 453, 484, 214, 160, 22, 101, 437, 149, 212, 216, 477, 243, 213, 387, 487, 18, 176, 45, 120, 320, 196, 370, 325, 466, 407, 8, 441, 379, 19, 225, 478, 510, 505, 211, 445, 482, 351, 435, 99, 508, 399, 430, 294, 126, 187, 411, 454, 108, 329, 67, 121, 89, 92, 5, 27, 310, 470, 226, 20, 162, 414, 474, 105, 267, 290, 322, 347, 230, 9, 398, 175, 533, 258, 119, 77, 182, 232, 317, 436, 206, 291, 486, 245, 185, 25, 440, 464, 450, 48, 193, 151, 57, 472, 502, 499, 304, 96, 420, 129, 220, 237, 462, 412, 106, 458, 439, 229, 532, 427, 181, 112, 136, 289, 388, 416, 301, 164, 307, 529, 33, 528, 376, 75, 340, 55, 153, 280, 506, 523, 150, 433, 360, 145, 429, 456, 241, 356, 23, 90, 26, 535, 319, 446, 262, 406, 491, 405, 548, 493, 327, 341, 409, 389, 463, 141, 63, 246, 428, 331, 344, 513, 543, 233, 132, 531, 127, 288, 81, 21, 37, 208, 297, 339, 286, 239, 422, 415, 155, 401, 334, 537, 221, 179, 392, 74, 380, 367, 481, 24, 49, 371, 449, 29, 50, 444, 272, 113, 276, 51, 538, 539, 125, 7, 39, 248, 432, 100, 282, 312, 82, 346, 143, 279, 158, 306, 520, 517, 314, 70, 355, 503, 365, 326, 263, 277, 94, 390, 16, 174, 84, 252, 109, 124, 78, 488, 197, 452, 44, 496, 448, 397, 135, 476, 170, 6, 442, 4, 343, 104, 479, 215, 552, 259, 191, 357, 47, 152, 423, 434, 192, 173, 404, 363, 516, 459, 205, 381, 98, 71, 495, 79, 295, 553, 186, 130, 383, 52, 169, 469, 53, 265, 318, 269, 545, 88, 54, 348, 178, 424, 36, 451, 384, 32, 364, 3, 358, 86, 489, 413, 473, 163, 154, 350, 224, 42, 167, 542, 257, 354, 219, 80, 544, 497, 375, 139, 549, 207, 131, 483, 133, 228, 102, 338, 494, 147, 323, 471, 56, 526, 515, 209, 353, 368, 28, 480, 156, 103, 260, 268, 65, 201, 144, 519, 410, 115, 122, 30, 188, 382, 361, 159, 2, 393, 66, 198, 333, 518, 275, 461, 194, 283, 296, 402, 501, 492, 137, 242, 408, 203, 235, 271, 525, 328, 447, 240, 118, 264, 555, 85, 366, 251, 46, 345, 284, 40, 199, 227, 270, 400, 161, 111, 373, 83, 238, 266, 249, 261, 359, 512, 316, 395, 171, 507, 15, 166, 274, 332, 38, 128, 541, 540];
  enum Rarities{ LEGENDARY, EPIC, RARE, UNCOMMON, COMMON }
  mapping(Rarities => mapping(uint8 => uint32)) public rarityPrizes;

  struct NFTReward {
    bool exists;
    uint256[] tokenIds;
  }
  struct Piggy {
    bool isBroken;
    Rarities rarity;
    address holder;
    bool rewardsClaimed;
  }
  struct BreakingRequestor {
    uint16 piggyId;
    address holder;
  }

  mapping(uint256 => BreakingRequestor) public requestorForRequestId;
  mapping(uint16 => Piggy) public piggies;
  uint256 public remainingPiggies = 555;
  address[] public nftRewardsAddresses;
  mapping(address => uint256[]) public nftRewards;
  mapping(uint16 => uint256[]) public piggiesRandomWords;

  mapping(uint256 => bool) public emergencyVotes;
  uint256 public emergencyVotesCount = 0;

  constructor(uint64 _subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    initRarities();

    MetaPiggyBanksToken = IERC721(MPBAddress);
    for (uint16 prop = 0; prop < piggyIds.length; prop++) {
      Rarities rarity = Rarities.COMMON;
      if (prop == 0) {
        rarity = Rarities.LEGENDARY;
      } else if (prop >= 1 && prop <= 19) {
        rarity = Rarities.EPIC;
      } else if (prop >= 20 && prop <= 69) {
        rarity = Rarities.RARE;
      } else if (prop >= 70 && prop <= 269) {
        rarity = Rarities.UNCOMMON;
      }
      piggies[piggyIds[prop]] = Piggy(false, rarity, address(0x00), false);
    }

    setSubscriptionId(_subscriptionId);
    setVrfCoordinator(vrfCoordinator);
  }

  /* Chainlink configuration */
  function setSubscriptionId(uint64 _subscriptionId) public onlyOwner {
    s_subscriptionId = _subscriptionId;
  }

  function setKeyHash(bytes32 _keyHash) public onlyOwner {
    keyHash = _keyHash;
  }

  function setVrfCoordinator(address _vrfCoordinator) public onlyOwner {
    vrfCoordinator = _vrfCoordinator;
    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
  }

  function setCallbackGasLimit(uint32 _callbackGasLimit) public onlyOwner {
    callbackGasLimit = _callbackGasLimit;
  }

  /* Breaking system */
  function initRarities() private {
    rarityPrizes[Rarities.COMMON][1] = 2500000;
    rarityPrizes[Rarities.COMMON][3] = 1100000;
    rarityPrizes[Rarities.COMMON][4] = 750000;
    rarityPrizes[Rarities.COMMON][7] = 600000;
    rarityPrizes[Rarities.COMMON][15] = 500000;
    rarityPrizes[Rarities.COMMON][30] = 450000;
    rarityPrizes[Rarities.COMMON][40] = 400000;

    rarityPrizes[Rarities.UNCOMMON][1] = 6500000;
    rarityPrizes[Rarities.UNCOMMON][3] = 2860000;
    rarityPrizes[Rarities.UNCOMMON][4] = 1950000;
    rarityPrizes[Rarities.UNCOMMON][7] = 1560000;
    rarityPrizes[Rarities.UNCOMMON][15] = 1300000;
    rarityPrizes[Rarities.UNCOMMON][30] = 1170000;
    rarityPrizes[Rarities.UNCOMMON][40] = 1040000;

    rarityPrizes[Rarities.RARE][1] = 7500000;
    rarityPrizes[Rarities.RARE][3] = 3300000;
    rarityPrizes[Rarities.RARE][4] = 2250000;
    rarityPrizes[Rarities.RARE][7] = 1800000;
    rarityPrizes[Rarities.RARE][15] = 1500000;
    rarityPrizes[Rarities.RARE][30] = 1350000;
    rarityPrizes[Rarities.RARE][40] = 1200000;

    rarityPrizes[Rarities.EPIC][1] = 15000000;
    rarityPrizes[Rarities.EPIC][3] = 6600000;
    rarityPrizes[Rarities.EPIC][4] = 4500000;
    rarityPrizes[Rarities.EPIC][7] = 3600000;
    rarityPrizes[Rarities.EPIC][15] = 3000000;
    rarityPrizes[Rarities.EPIC][30] = 2700000;
    rarityPrizes[Rarities.EPIC][40] = 2400000;

    rarityPrizes[Rarities.LEGENDARY][1] = 90000000;
    rarityPrizes[Rarities.LEGENDARY][3] = 39600000;
    rarityPrizes[Rarities.LEGENDARY][4] = 27000000;
    rarityPrizes[Rarities.LEGENDARY][7] = 21600000;
    rarityPrizes[Rarities.LEGENDARY][15] = 18000000;
    rarityPrizes[Rarities.LEGENDARY][30] = 16200000;
    rarityPrizes[Rarities.LEGENDARY][40] = 14400000;
  }

  event Received(address, uint);

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes calldata _data
  )
  external
  override
  returns(bytes4)
  {
    _from;
    _data;
    _operator;
    _tokenId;
    emit Received(msg.sender, 1);
    return 0x150b7a02;
  }

  function normalizer(uint256 random) private pure returns (uint8) {
    if (random <= 40) {
      return 40;
    }
    if (random <= 70) {
      return 30;
    }
    if (random <= 85) {
      return 15;
    }
    if (random <= 92) {
      return 7;
    }
    if (random <= 96) {
      return 4;
    }
    if (random <= 99) {
      return 3;
    }
    if (random == 100) {
      return 1;
    }
    return 40;
  }

  function fulfillRandomWords(
    uint256 requestId,
    uint256[] memory randomWords
  ) internal override {
    piggiesRandomWords[requestorForRequestId[requestId].piggyId] = randomWords;

    sendRewards(requestorForRequestId[requestId].piggyId);
  }

  function sendRewards(uint16 piggyId) private {
    if (piggies[piggyId].isBroken == true && !piggies[piggyId].rewardsClaimed && piggiesRandomWords[piggyId].length > 0) {
      sendETHReward(piggyId, piggiesRandomWords[piggyId][0]);
      checkAdditionalRewards(piggyId);
      piggies[piggyId].rewardsClaimed = true;
      remainingPiggies = remainingPiggies - 1;
    }
  }

  function claimRewards(uint16 piggyId) public {
    require(piggies[piggyId].isBroken, "This piggy is not broken yet.");
    require(!piggies[piggyId].rewardsClaimed, "The rewards for this piggy have already been claimed.");
    require(piggiesRandomWords[piggyId].length > 0, "The random generation is not done yet, please try again later.");

    sendRewards(piggyId);
  }

  function sendETHReward(uint16 piggyId, uint256 randomWord) private {
    // uint256 rewardPercent = rarityPrizes[piggies[piggyId].rarity][normalizer(randomWord % 100 + 1)] / (remainingPiggies);
    uint256 rewardPercent = rarityPrizes[piggies[piggyId].rarity][normalizer(randomWord % 100 + 1)] / (remainingPiggies);
    if (rewardPercent > 1000000 || remainingPiggies == 1) {
      rewardPercent = 1000000;
    }

    // Send ETH to holder
    payable(piggies[piggyId].holder).transfer((address(this).balance * rewardPercent) / 1000000);
  }

  function checkAdditionalRewards(uint16 piggyId) private {
    for (uint i = 0; i < nftRewardsAddresses.length && i < piggiesRandomWords[piggyId].length - 1; i++) {
      uint randomValue = piggiesRandomWords[piggyId][i + 1] % remainingPiggies;

      address rewardAddress = nftRewardsAddresses[i];
      if (randomValue < nftRewards[rewardAddress].length) {
        uint256 tokenId = nftRewards[rewardAddress][randomValue];
        IERC721(nftRewardsAddresses[i]).safeTransferFrom(address(this), piggies[piggyId].holder, tokenId);

        delete nftRewards[rewardAddress][randomValue];
        if (nftRewards[rewardAddress].length <= 0) {
          delete nftRewards[rewardAddress];
          delete nftRewardsAddresses[i];
        }
      }
    }
  }

  function breakPiggy(uint16 piggyId) public {
    require(piggyId <= 555, "This NFT is not registered in the list of breakable piggies.");
    require(!piggies[piggyId].isBroken, "This piggy is already broken.");
    require(MetaPiggyBanksToken.ownerOf(piggyId) == msg.sender, "You are not the owner of this MPB");
    piggies[piggyId].isBroken = true;
    piggies[piggyId].holder = msg.sender;

    uint32 numWords = uint32(nftRewardsAddresses.length + 1);
    requestorForRequestId[COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    )] = BreakingRequestor(piggyId, msg.sender);
  }

  function addReward(address contractAddress, uint256 tokenId) public onlyOwner {
    require(IERC721(contractAddress).ownerOf(tokenId) == address(this), "PiggyBreaker doesn't have this NFT so it cannot be added to the rewards");

    nftRewards[contractAddress].push(tokenId);
    nftRewardsAddresses.push(contractAddress);
  }

  function emergencyWithdrawEth() public onlyOwner {
    require(emergencyVotesCount >= 55);

    (bool payment, ) = payable(owner()).call{value: address(this).balance}("");
    require(payment);
  }

  function emergencyWithdrawNft(address contractAddress, uint256 tokenId) public onlyOwner {
    require(emergencyVotesCount >= 55); // 10% of owners

    IERC721(contractAddress).safeTransferFrom(address(this), owner(), tokenId);
  }

  function voteForEmergency(uint256 piggyId) public {
    require(MetaPiggyBanksToken.ownerOf(piggyId) == msg.sender, "You are not the owner of this MPB");
    require(!emergencyVotes[piggyId], "Piggy already used for emergency vote");

    emergencyVotes[piggyId] = true;
    emergencyVotesCount = emergencyVotesCount + 1;
  }
}