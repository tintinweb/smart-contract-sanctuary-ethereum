/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @chainlink/contracts/src/v0.8/interfaces/[email protected]


pragma solidity ^0.8.0;

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
}


// File @chainlink/contracts/src/v0.8/[email protected]


pragma solidity ^0.8.4;

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


// File @openzeppelin/contracts/utils/structs/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
}


// File contracts/Crowdfund.sol

pragma solidity ^0.8.0;

enum CrowdfundStatus{ OnSale, Traded, PrizeDrawn, Expired, Stopped }

struct Crowdfund {
    address creator;
    address asset;
    uint factor;
    uint sharePriceWithoutFactor;
    uint sharePrice;
    uint expirationTime;

    uint soldShares;
    EnumerableMap.AddressToUintMap participants;

    uint proxyId;
    uint tokenId;
    uint tradePrice;
    uint tradeShares;
    uint changePerShare;
    uint revenue;

    uint randNum;
    bool cashedNFT;
    mapping(address => bool) cashedChange;
    CrowdfundStatus status;
}

struct CrowdfundGetInfo {
    address creator;
    address asset;
    uint factor;
    uint sharePriceWithoutFactor;
    uint sharePrice;
    uint expirationTime;

    uint soldShares;

    uint proxyId;
    uint tokenId;
    uint tradePrice;
    uint tradeShares;
    uint changePerShare;
    uint revenue;

    uint randNum;
    bool cashedNFT;
    CrowdfundStatus status;
}

struct TradeBaseInfo {
    address asset;
    uint tokenId;
    uint tradePrice;
}


// File contracts/interface/IProxy.sol

pragma solidity ^0.8.0;

interface IProxy {
    function buyNFT(TradeBaseInfo calldata crowdfundInfo, bytes calldata data) external payable;
}


// File contracts/Utils.sol

pragma solidity ^0.8.0;

library MoneyUtils {
    function transferInMoneyFromSender(address token, uint amount)
    internal
    {
        if (amount > 0) {
            if (token == address(0)) {
                require(msg.value >= amount, "not enough");
            } else {
                require(IERC20(token).transferFrom(msg.sender, address(this), amount), "transfer in money fail");
            }
        }
    }
}

library RevertUtils {
    /// Reverts, forwarding the return data from the last external call.
    /// If there was no preceding external call, reverts with empty returndata.
    /// It's up to the caller to ensure that the preceding call actually reverted - if it did not,
    /// the return data will come from a successfull call.
    ///
    /// @dev This function writes to arbitrary memory locations, violating any assumptions the compiler
    /// might have about memory use. This may prevent it from doing some kinds of memory optimizations
    /// planned in future versions or make them unsafe. It's recommended to obtain the revert data using
    /// the try/catch statement and rethrow it with `rawRevert()` instead.
    function forwardRevert() internal pure {
        assembly {
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    /// Reverts, directly setting the return data from the provided `bytes` object.
    /// Unlike the high-level `revert` statement, this allows forwarding the revert data obtained from
    /// a failed external call (high-level `revert` would wrap it in an `Error`).
    ///
    /// @dev This function is recommended over `forwardRevert()` because it does not interfere with
    /// the memory allocation mechanism used by the compiler.
    function rawRevert(bytes memory revertData) internal pure {
        assembly {
        // NOTE: `bytes` arrays in memory start with a 32-byte size slot, which is followed by data.
            let revertDataStart := add(revertData, 32)
            let revertDataEnd := add(revertDataStart, mload(revertData))
            revert(revertDataStart, revertDataEnd)
        }
    }
}

//library SendUtils {
//    error EtherTransferFailed();
//
//    function _sendEthViaCall(address payable receiver, uint amount) internal {
//        if (amount > 0) {
//            (bool success, ) = receiver.call{value: amount}("");
//        if (!success)
//            revert EtherTransferFailed();
//        }
//    }
//
//    function _returnAllEth() internal {
//        // NOTE: This works on the assumption that the whole balance of the contract consists of
//        // the ether sent by the caller.
//        // (1) This is never 100% true because anyone can send ether to it with selfdestruct or by using
//        // its address as the coinbase when mining a block. Anyone doing that is doing it to their own
//        // disavantage though so we're going to disregard these possibilities.
//        // (2) For this to be safe we must ensure that no ether is stored in the contract long-term.
//        // It's best if it has no receive function and all payable functions should ensure that they
//        // use the whole balance or send back the remainder.
//        _sendEthViaCall(payable(msg.sender), address(this).balance);
//    }
//
//    function _returnAllToken() internal {
//        _sendEthViaCall(payable(msg.sender), address(this).balance);
//    }
//}


// File contracts/LuckyNFT.sol

pragma solidity ^0.8.0;

contract LuckyNFT is Ownable, IERC721Receiver, ReentrancyGuard, VRFConsumerBaseV2 {

    using SafeMath for uint;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    address public treasury;            // 收入支配账号
    address public trader;              // 交易员账号
    uint public revenue;                // 收入金额

    bool public open;                   // 开关
    uint public factor = 11000;         // 筹款比例因子
    uint constant factorBase = 10000;   // 比例因子基数

    // opensea 代理配置
    uint public nextProxyId = 1;
    mapping(uint => address) public proxies;
    mapping(uint => bool) public proxyStatus;

    // 众筹信息
    uint public nextCrowdfundId = 1;
    mapping(uint => Crowdfund) internal crowdfunds;

    // NFT资产信息
    mapping(address => bool) public assets;

    // Chainlink VRF随机数配置
    address public vrfCoordinator;
    uint64 public vrfSubId;
    bytes32 public vrfKeyHash;
    uint32 public vrfCBGasLimit;
    uint16 constant vrfReqConfirm = 3;
    uint32 constant vrfNumWords = 1;
    mapping(uint => uint) public vrfRequestIds;

    // event
    event Proxy(address proxy, uint id, bool status);
    event Asset(address asset, bool status);
    event NewCrowdfund(uint crowdfundId, address asset, uint sharePriceWithoutFactor, uint expirationTime);
    event StatusChanged(uint crowdfundId, CrowdfundStatus status);
    event Sold(uint crowdfundId, address user, uint quantity);
    event NewRevenue(uint crowdfundId, uint newRevenue);
    event CasedPrize(uint crowdfundId, address winner, address nft, uint tokenId);
    event GotChange(uint crowdfundId, address user, uint amount);
    event Withdrawn(uint crowdfundId, address user, uint shareQuantity, uint anount);

    // modifier
    modifier onlyOpening() {
        require(open, "only opening");
        _;
    }

    modifier onlyTreasury() {
        require(msg.sender == treasury, "only treasury");
        _;
    }

    modifier onlyTrader() {
        require(msg.sender == trader, "only trader");
        _;
    }

    constructor(
        address treasury_,
        address trader_,
        address vrfCoordinator_,
        uint64 vrfSubId_,
        bytes32 vrfKeyHash_,
        uint32 vrfCBGasLimit_
    )
    VRFConsumerBaseV2(vrfCoordinator_)
    {
        treasury = treasury_;
        trader = trader_;
        vrfCoordinator = vrfCoordinator_;
        vrfSubId = vrfSubId_;
        vrfKeyHash = vrfKeyHash_;
        vrfCBGasLimit = vrfCBGasLimit_;
    }

    /**
     * @dev 设置开关状态
     * @param open_: 是否打开
     * @notice 需要owner权限
     */
    function SetOpen(
        bool open_
    )
    external
    onlyOwner
    {
        open = open_;
    }

    /**
     * @dev 设置费率因子
     * @param factor_: 费率因子，基础因子是10000
     * @notice 需要owner权限
     */
    function SetFactor(
        uint factor_
    )
    external
    onlyOwner
    {
        require(factor_ >= factorBase, "invalid factor");
        factor = factor_;
    }

    /**
     * @dev 设置收益款管理账号
     * @param treasury_: 收益款管理账号
     * @notice 需要owner权限
     */
    function SetTreasury(
        address treasury_
    )
    external
    onlyOwner
    {
        treasury = treasury_;
    }

    /**
     * @dev 设置NFT交易账号
     * @param trader_: NFT交易账号
     * @notice 需要owner权限
     */
    function SetTrader(
        address trader_
    )
    external
    onlyOwner
    {
        trader = trader_;
    }

    /**
     * @dev 注册opensea代理器
     * @param proxy: 代理合约地址
     * @notice 需要owner权限。可以用来适配opensea不同的版本
     */
    function RegisterProxy(
        address proxy
    )
    external
    onlyOwner
    {
        proxies[nextProxyId] = proxy;
        proxyStatus[nextProxyId] = true;
        emit Proxy(proxy, nextProxyId, true);
        nextProxyId++;
    }

    /**
     * @dev 注销opensea代理器
     * @param id: 代理id
     * @notice 需要owner权限
     */
    function UnregisterProxy(
        uint id
    )
    external
    onlyOwner
    {
        require(id != 0 && id < nextProxyId, "invalid proxy id");
        require(proxyStatus[id], "unregisted already");

        proxyStatus[id] = false;
        emit Proxy(proxies[id], id, false);
    }

    /**
     * @dev 注册可以众筹的NFT
     * @param asset: NFT合约地址
     * @notice 需要owner权限
     */
    function RegisterAsset(
        address asset
    )
    external
    onlyOwner
    {
        assets[asset] = true;
        emit Asset(asset, true);
    }

    /**
     * @dev 注销NFT
     * @param asset: NFT合约地址
     * @notice 需要owner权限
     */
    function UnregisterAsset(
        address asset
    )
    external
    onlyOwner
    {
        assets[asset] = false;
        emit Asset(asset, false);
    }

    /**
     * @dev 设置Chainlink VRF随机数信息
     * @param vrfCoordinator_: 详见Chainlink文档
     * @param keyHash_: 详见Chainlink文档
     * @param callbackGasLimit_: 详见Chainlink文档
     * @param subscriptionId_: 详见Chainlink文档
     * @notice 需要owner权限
     */
    function SetChainlinkVRF(
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint32 callbackGasLimit_,
        uint64 subscriptionId_
    )
    external
    onlyOwner
    {
        vrfCoordinator = vrfCoordinator_;
        vrfKeyHash = keyHash_;
        vrfCBGasLimit = callbackGasLimit_;
        vrfSubId = subscriptionId_;
    }

    /**
     * @dev 提取平台收益
     * @param to: 收款地址
     * @param amount: 提取金额
     * @notice 需要treasury权限
     */
    function WithdrawRevenue(
        address to,
        uint amount
    )
    external
    onlyTreasury
    {
        require(amount <= revenue, "invalid amount");
        revenue -= amount;
        payable(to).transfer(amount);
    }

    /**
     * @dev 紧急出口（!!!!!!!!!!!!!!!!!!!!!!!!调试测试接口，生产环境需要删除）
     * @param erc20s: 要提取的token地址，0地址表示eth
     * @param quantities: 要提起的token的金额
     * @param erc721s: 要转移的NFT合约地址
     * @param ids: 要转移的NFT token id
     * @param to: 接受地址
     * @notice 需要owner权限
     */
    function Emergency(
        address[] calldata erc20s,
        uint[] calldata quantities,
        address[] calldata erc721s,
        uint[] calldata ids,
        address to
    )
    external
    onlyOwner
    {
        require(erc20s.length == quantities.length, "length dont match");
        require(erc721s.length == ids.length, "length dont match");
        require(to != address(0), "invalid to");
        for (uint i = 0; i < erc20s.length; i++) {
            if (erc20s[i] == address(0)) {
                payable(to).transfer(quantities[i]);
            } else {
                IERC20(erc20s[i]).transfer(to, quantities[i]);
            }
        }

        for (uint i = 0; i < erc721s.length; i++) {
            IERC721(erc721s[i]).transferFrom(address(this), to, ids[i]);
        }
    }

    /**
     * @dev 创建众筹
     * @param asset: NFT合约地址
     * @param sharePriceWithoutFactor: 众筹份额原始价格（不带费率因子）
     * @param expirationTime: 过期时间
     * @param buyQuantity: 购买份额数量
     */
    function CreateCrowdfund(
        address asset,
        uint sharePriceWithoutFactor,
        uint expirationTime,
        uint buyQuantity
    )
    external
    payable
    onlyOpening
    nonReentrant
    {
        require(asset != address(0), "invalid asset");
        require(assets[asset], "asset unregistered");
        require(sharePriceWithoutFactor != 0, "invalid share price");
        require(block.timestamp < expirationTime, "invalid expiration time");
        require(buyQuantity != 0, "invalid buy shares");

        Crowdfund storage crowdfund = crowdfunds[nextCrowdfundId];
        crowdfund.creator = msg.sender;
        crowdfund.factor = factor;
        crowdfund.asset = asset;
        crowdfund.sharePriceWithoutFactor = sharePriceWithoutFactor;
        crowdfund.expirationTime = expirationTime;
        crowdfund.status = CrowdfundStatus.OnSale;

        (bool suc, uint sharePrice) = sharePriceWithoutFactor.tryMul(factor);
        require(suc, "uint tryMul fail");

        sharePrice = sharePrice.div(factorBase);
        crowdfund.sharePrice = sharePrice;

        emit NewCrowdfund(nextCrowdfundId, asset, sharePriceWithoutFactor, expirationTime);
        emit StatusChanged(nextCrowdfundId, CrowdfundStatus.OnSale);

        buyShares_(nextCrowdfundId, crowdfund, buyQuantity);
        nextCrowdfundId++;
    }

    /**
     * @dev 购买指定众筹份额
     * @param crowdfundId: 众筹id
     * @param buyQuantity: 购买份额
     * @notice 需要owner权限
     */
    function BuyShares(
        uint crowdfundId,
        uint buyQuantity
    )
    external
    payable
    onlyOpening
    nonReentrant
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        require(block.timestamp < crowdfund.expirationTime, "expired");
        require(crowdfund.status == CrowdfundStatus.OnSale, "invalid crowdfund status");
        require(buyQuantity != 0, "invalid buy quantity");

        buyShares_(crowdfundId, crowdfund, buyQuantity);
    }

    /**
     * @dev 触发NFT交易
     * @param crowdfundId: 众筹id
     * @param proxyId: opensea代理id
     * @param tokenId：NFT token id
     * @param tradePrice：交易价格
     * @param data：交易详情序列化数据，数据格式根据proxyId变化
     * @notice 需要trader权限
     */
    function Trade(
        uint crowdfundId,
        uint proxyId,
        uint tokenId,
        uint tradePrice,
        bytes calldata data
    )
    external
    onlyTrader
    nonReentrant
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        require(block.timestamp < crowdfund.expirationTime, "expired");
        require(crowdfund.status == CrowdfundStatus.OnSale, "invalid crowdfund status");
        require(assets[crowdfund.asset], "invalid asset");
        require(tradePrice <= crowdfund.sharePriceWithoutFactor.mul(crowdfund.soldShares), "invalid trade price");
        require(IERC721(crowdfund.asset).ownerOf(tokenId) != address(this), "have owned NFT");

        address proxy = proxies[proxyId];
        require(proxy != address(0), "invalid proxy address");
        require(proxyStatus[proxyId], "invalid proxy status");
        IProxy p = IProxy(proxy);

        TradeBaseInfo memory baseInfo = TradeBaseInfo(
            crowdfund.asset,
            tokenId,
            tradePrice
        );

        try p.buyNFT{value: tradePrice}(
            baseInfo,
            data
        ) {
            require(IERC721(baseInfo.asset).ownerOf(tokenId) == address(this), "dont own NFT");
            crowdfund.status = CrowdfundStatus.Traded;
            crowdfund.proxyId = proxyId;
            crowdfund.tokenId = tokenId;
            crowdfund.tradePrice = tradePrice;
            updateRevenue_(crowdfundId, crowdfund);

            uint requestId = VRFCoordinatorV2Interface(vrfCoordinator).requestRandomWords(
                vrfKeyHash,
                vrfSubId,
                vrfReqConfirm,
                vrfCBGasLimit,
                vrfNumWords
            );

            vrfRequestIds[requestId] = crowdfundId;
        } catch (bytes memory lowLevelData) {
            RevertUtils.rawRevert(lowLevelData);
        }
    }

    /**
     * @dev 兑奖
     * @param crowdfundId: 众筹id。必须指向已经开奖的众筹
     * @notice 只有中奖者可以调用该接口。中奖者将领取自己的NFT以及找零
     */
    function CashPrize(
        uint crowdfundId
    )
    external
    nonReentrant
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        require(crowdfund.status == CrowdfundStatus.PrizeDrawn, "invalid crowdfund status");

        address winner = fixWinner_(crowdfund);
        require(msg.sender == winner, "is not winner");

        // transfer nft
        if (!crowdfund.cashedNFT) {
            crowdfund.cashedNFT = true;
            IERC721(crowdfund.asset).transferFrom(address(this), winner, crowdfund.tokenId);
            emit CasedPrize(crowdfundId, winner, crowdfund.asset, crowdfund.tokenId);
        }

        // transfer change
        if (!crowdfund.cashedChange[winner]) {
            uint shareQuantity;
            (, shareQuantity) = crowdfund.participants.tryGet(winner);
            (bool suc, uint change) = shareQuantity.tryMul(crowdfund.changePerShare);
            require(suc, "tryMul fail");

            crowdfund.cashedChange[winner] = true;
            if (change > 0) {
                payable(winner).transfer(change);
            }

            emit GotChange(crowdfundId, winner, change);
        }
    }

    /**
     * @dev 找零
     * @param crowdfundId: 众筹id。必须指向已经开奖的众筹
     * @notice 未中奖者可以领回剩余资金（中奖者也可以调用该接口，但是不推荐）
     */
    function GetChange(
        uint crowdfundId
    )
    external
    nonReentrant
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        require(crowdfund.status == CrowdfundStatus.PrizeDrawn, "invalid crowdfund status");
        require(!crowdfund.cashedChange[msg.sender], "have given out change");

        (bool suc, uint shareQuantity) = crowdfund.participants.tryGet(msg.sender);
        require(suc, "is not participant");

        uint change;
        (suc, change) = shareQuantity.tryMul(crowdfund.changePerShare);
        require(suc, "tryMul fail");

        crowdfund.cashedChange[msg.sender] = true;
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }

        emit GotChange(crowdfundId, msg.sender, change);
    }

    /**
     * @dev 退出众筹
     * @param crowdfundId: 众筹id。只能指向过期或者被终止的众筹
     * @notice 过期或者被终止的众筹，用户资金将全部退还
     */
    function Withdraw(
        uint crowdfundId
    )
    external
    nonReentrant
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        if (crowdfund.status == CrowdfundStatus.OnSale && block.timestamp >= crowdfund.expirationTime) {
            crowdfund.status = CrowdfundStatus.Expired;
            emit StatusChanged(crowdfundId, CrowdfundStatus.Expired);
        }

        require(crowdfund.status == CrowdfundStatus.Expired || crowdfund.status == CrowdfundStatus.Stopped, "invalid crowdfund status");
        require(!crowdfund.cashedChange[msg.sender], "have withdrawn");

        (bool suc, uint shareQuantity) = crowdfund.participants.tryGet(msg.sender);
        require(suc, "is not participant");

        uint money;
        (suc, money) = shareQuantity.tryMul(crowdfund.sharePrice);
        require(suc, "tryMul fail");

        crowdfund.cashedChange[msg.sender] = true;
        payable(msg.sender).transfer(money);
        emit Withdrawn(crowdfundId, msg.sender, shareQuantity, money);
    }

    /**
     * @dev 终止指定众筹
     * @param crowdfundId: 众筹id。只能指向售卖中的众筹
     * @notice 需要owner权限
     */
    function Stop(
        uint crowdfundId
    )
    external
    onlyOwner
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        require(crowdfund.status == CrowdfundStatus.OnSale, "invalid crowdfund status");
        crowdfund.status = CrowdfundStatus.Stopped;
        emit StatusChanged(crowdfundId, CrowdfundStatus.Stopped);
    }

    /**
     * @dev 获得众筹信息
     * @param crowdfundId: 众筹id
     */
    function GetCrowdfund(
        uint crowdfundId
    )
    public
    view
    returns (CrowdfundGetInfo memory)
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);

        CrowdfundGetInfo memory info = CrowdfundGetInfo(
            crowdfund.creator,
            crowdfund.asset,
            crowdfund.factor,
            crowdfund.sharePriceWithoutFactor,
            crowdfund.sharePrice,
            crowdfund.expirationTime,

            crowdfund.soldShares,

            crowdfund.proxyId,
            crowdfund.tokenId,
            crowdfund.tradePrice,
            crowdfund.tradeShares,
            crowdfund.changePerShare,
            crowdfund.revenue,

            crowdfund.randNum,
            crowdfund.cashedNFT,
            crowdfund.status
        );

        return info;
    }

    /**
     * @dev 获取用户已购买份额
     * @param crowdfundId: 众筹id
     * @param user: 指定用户
     * @return
     *   uint: 用户已购买份额
     */
    function GetShareQuantity(
        uint crowdfundId,
        address user
    )
    public
    view
    returns (uint)
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);

        uint value;
        (, value) = crowdfund.participants.tryGet(user);
        return value;
    }

    /**
     * @dev 获得开奖结果
     * @param crowdfundId: 众筹id
     * @return
     *   CrowdfundStatus: 众筹状态
     *   address：中奖者
     *   uint：每份额找零
     */
    function GetPrize(
        uint crowdfundId
    )
    public
    view
    returns (CrowdfundStatus, address, uint)
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        if (crowdfund.status != CrowdfundStatus.PrizeDrawn) {
            return (crowdfund.status, address(0), 0);
        }

        address winner = fixWinner_(crowdfund);
        return (CrowdfundStatus.PrizeDrawn, winner, crowdfund.changePerShare);
    }

    /**
     * @dev 获得用户的开奖结果
     * @param crowdfundId: 众筹id
     * @param user：用户
     * @return
     *   CrowdfundStatus: 众筹状态
     *   bool：是否中奖
     *   uint：找零金额
     *   bool: 找零是否已经领取
     */
    function GetUserPrize(
        uint crowdfundId,
        address user
    )
    public
    view
    returns (CrowdfundStatus, bool, uint, bool)
    {
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);

        bool isWinner = false;
        if (crowdfund.status == CrowdfundStatus.PrizeDrawn) {
            isWinner = fixWinner_(crowdfund) == user;
        }

        uint shareQuantity;
        (, shareQuantity) = crowdfund.participants.tryGet(user);

        uint changeValue = 0;
        if (crowdfund.status == CrowdfundStatus.PrizeDrawn) {
            changeValue = shareQuantity.mul(crowdfund.changePerShare);
        } else if (crowdfund.status > CrowdfundStatus.PrizeDrawn) {
            changeValue = shareQuantity.mul(crowdfund.sharePrice);
        }

        return (crowdfund.status, isWinner, changeValue, crowdfund.cashedChange[user]);
    }

    // --------------- internal functions ---------------
    function buyShares_(
        uint crowdfundId,
        Crowdfund storage crowdfund,
        uint quantity
    )
    internal
    {
        bool suc;
        (suc, crowdfund.soldShares) = crowdfund.soldShares.tryAdd(quantity);
        require(suc, "invalid quantity");

        uint amount;
        (suc, amount) = crowdfund.sharePrice.tryMul(quantity);
        require(suc, "invalid quantity");
        MoneyUtils.transferInMoneyFromSender(address(0), amount);

        uint userBuy;
        (, userBuy) = crowdfund.participants.tryGet(msg.sender);
        (suc, userBuy) = userBuy.tryAdd(quantity);
        require(suc, "invalid quantity");

        crowdfund.participants.set(msg.sender, userBuy);
        emit Sold(crowdfundId, msg.sender, quantity);
    }

    function getCrowdfundFromId_(
        uint crowdfundId
    )
    internal
    view
    returns (Crowdfund storage)
    {
        require(crowdfundId < nextCrowdfundId, "invalid crowdfund id");
        Crowdfund storage crowdfund = crowdfunds[crowdfundId];
        return crowdfund;
    }

    function fixWinner_(
        Crowdfund storage crowdfund
    )
    internal
    view
    returns (address)
    {
        address user;
        uint value;
        uint offset = crowdfund.randNum%crowdfund.soldShares + 1;
        uint length = crowdfund.participants.length();
        for (uint i = 0; i < length-1; i++) {
            (user, value) = crowdfund.participants.at(i);
            if (offset <= value) {
                return user;
            }

            offset -= value;
            continue;
        }

        (user,) = crowdfund.participants.at(length-1);
        return user;
    }

    function updateRevenue_(
        uint crowdfundId,
        Crowdfund storage crowdfund
    )
    internal
    {
        (bool suc, uint tradeShares) = crowdfund.tradePrice.tryDiv(crowdfund.sharePriceWithoutFactor);
        require(suc, "trySub fail");

        if (crowdfund.tradePrice % crowdfund.sharePriceWithoutFactor != 0) {
            tradeShares++;
        }

        uint totalChange;
        (suc, totalChange) = (crowdfund.soldShares - tradeShares).tryMul(crowdfund.sharePrice);
        require(suc, "tryMul fail");

        uint changePerShare;
        (suc, changePerShare) = totalChange.tryDiv(crowdfund.soldShares);
        require(suc, "tryDiv fail");

        uint totalMoney;
        (suc, totalMoney) = crowdfund.soldShares.tryMul(crowdfund.sharePrice);

        uint newRevenue;
        (suc, newRevenue) = totalMoney.trySub(changePerShare.mul(crowdfund.soldShares).add(crowdfund.tradePrice));
        require(suc, "trySub fail");

        (suc, revenue) = revenue.tryAdd(newRevenue);
        require(suc, "tryAdd fail");

        crowdfund.tradeShares = tradeShares;
        crowdfund.changePerShare = changePerShare;
        crowdfund.revenue = newRevenue;
        emit NewRevenue(crowdfundId, newRevenue);
    }

    // ------------ IERC721Receiver ------------
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )
    external
    override
    returns (bytes4)
    {
        operator;
        from;
        tokenId;
        data;
        return IERC721Receiver.onERC721Received.selector;
    }


    // ------------ Chainlink VRF ------------
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    )
    internal
    override
    {
        uint crowdfundId = vrfRequestIds[requestId];
        require(crowdfundId != 0, "invalid crowdfundId");
        Crowdfund storage crowdfund = getCrowdfundFromId_(crowdfundId);
        crowdfund.randNum = randomWords[0];
        crowdfund.status = CrowdfundStatus.PrizeDrawn;
        emit StatusChanged(crowdfundId, CrowdfundStatus.PrizeDrawn);
    }
}