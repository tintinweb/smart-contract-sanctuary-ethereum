// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

//*~~~> SPDX-License-Identifier: MIT OR Apache-2.0
/*~~~>
    Thank you Phunks, your inspiration and phriendship meant the world to me and helped me through hard times.
      Never stop phighting, never surrender, always stand up for what is right and make the best of all situations towards all people.
      Phunks are phreedom phighters!
        "When the power of love overcomes the love of power the world will know peace." - Jimi Hendrix <3

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 <~~~*/
pragma solidity  >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*~~~>
Interface declarations for upgradable contracts
<~~~*/
interface NFTMkt {
  function transferNftForSale(address receiver, uint itemId) external;
}
interface IERC721 {
  function ownerOf(uint tokenId) external view returns(address);
  function balanceOf(address owner) external view returns(uint);
}
interface RewardsController {
  function splitRewards(uint split) external payable;
  function getFee() external returns(uint);
}
interface RoleProvider {
  function hasTheRole(bytes32 role, address _address) external returns(bool);
  function fetchAddress(bytes32 _var) external returns(address);
}
interface Offers {
  function fetchOfferId(uint marketId) external returns(uint);
  function refundOffer(uint itemID, uint offerId) external;
}
interface Trades {
  function fetchTradeId(uint marketId) external returns(uint);
  function refundTrade(uint itemId, uint tradeId) external;
}
interface Collections {
  function isRestricted(address nftContract) external returns(bool);
}

contract MarketBids is ReentrancyGuard, Pausable {
  using SafeMath for uint;
  using Counters for Counters.Counter;

  //*~~~> counter increments Bids
  Counters.Counter private _bidIds;

  //*~~~> counter increments Blind Bid
  Counters.Counter private _blindBidIds;

  constructor(address _role) {
    roleAdd = _role;
  }

  //*~~~> State variables
  uint[] private openStorage;
  uint[] private blindOpenStorage;
  address public roleAdd;

  //*~~~> global address variable from Role Provider contract
  bytes32 public constant COLLECTION = keccak256("COLLECTION");

  bytes32 public constant MARKET = keccak256("MARKET");

  bytes32 public constant NFT = keccak256("NFT");
  
  bytes32 public constant REWARDS = keccak256("REWARDS");

  bytes32 public constant OFFERS = keccak256("OFFERS");

  bytes32 public constant TRADES = keccak256("TRADES");

  //*~~~> Roles for designated accessibility
  bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");
  bytes32 public constant CONTRACT_ROLE = keccak256("CONTRACT_ROLE");
  bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");

  modifier hasAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(PROXY_ROLE, msg.sender), "DOES NOT HAVE ADMIN ROLE");
    _;
  }
  modifier hasContractAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(CONTRACT_ROLE, msg.sender), "DOES NOT HAVE CONTRACT ROLE");
    _;
  }
  modifier hasDevAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(DEV_ROLE, msg.sender), "DOES NOT HAVE DEV ROLE");
    _;
  }

  //*~~~> Declaring object structures for listed items with bids
  struct Bid {
    uint itemId;
    uint tokenId;
    uint bidId;
    uint bidValue;
    uint timestamp;
    address payable bidder;
    address payable seller;
  }

  //*~~~> Declaring object structure for blind bids
  struct BlindBid {
    bool specific;
    uint tokenId;
    uint bidId;
    uint bidValue;
    uint amount;
    address collectionBid;
    address bidder;
  }

  //*~~~> Memory array of all Bids internal id
  mapping (uint256 => Bid) private idToNftBid;

  //*~~~> Memory array of Market contract Ids to bid Ids
  mapping (uint256 => uint256) private mktIdToBidId;

  //*~~~> Memory array of all Blind Bids
  mapping (uint256 => BlindBid) private idToBlindBid;

  //*~~~> Declaring event object structures for bids
  event BidEntered(
    uint tokenId,
    uint itemId,
    uint bidId,
    uint bidValue, 
    address indexed bidder,
    address indexed seller
    );

  //*~~~> Declaring event object structure for blind bids
  event BlindBidentered (
    bool isSpecified,
    uint indexed tokenId,
    uint bidId,
    uint bidValue,
    uint amount,
    address indexed collectionBid,
    address indexed bidder
  );

  //*~~~> Declaring event object structures for Bid accepted
  event BlindBidAccepted(
    uint indexed tokenId,
    uint blindBidId,
    uint bidValue,
    address indexed bidder,
    address indexed seller
  );

  //*~~~> Declaring event object structures for Bid accepted
  event BidAccepted(
    uint indexed tokenId,
    uint bidId,
    uint bidValue,
    address indexed bidder,
    address indexed seller
  );

  //*~~~> Declaring event object structures for bids withdrawn
  event BidWithdrawn(
    uint256 indexed tokenId, 
    uint indexed bidId,
    address indexed bidder
    );

  //*~~~> Declaring event object structures for blind bids withdrawn
  event BlindBidWithdrawn(
    uint indexed bidId,
    address indexed bidder
    );

  //*~~~> Decalring event object structures for bids refunded
  event BidRefunded(
    uint indexed tokenId,
    uint indexed bidId,
    address indexed bidder
  );

  /*~~~> Allowing for upgradability of proxy addresses <~~~*/
  function setRoleAdd(address _role) public hasAdmin returns(bool){
    roleAdd = _role;
    return true;
  }

  /// @notice 
  /*~~~> 
    Calculating the platform fee, 
      Base fee set at 2% (i.e. value * 200 / 10,000) 
      Future fees can be set by the controlling DAO 
    <~~~*/
  /// @return platform fee
  function calcFee(uint256 _value) public returns (uint256) {
      address rewardsAdd = RoleProvider(roleAdd).fetchAddress(REWARDS);
      uint fee = RewardsController(rewardsAdd).getFee();
      uint256 percent = (_value.mul(fee)).div(10000);
      return percent;
    }

  /// @notice 
  //*~~~> Allows user to enter bids on listed market items
  /// @dev 
    /*~~~>
      tokenId: token_id of the NFT to be bid on;
      itemId: itemId for internal storage index in the Market Contract;
      bidValue: Value of the bid entered;
      seller: ownerOf NFT;
    <~~~*/
  /// @return Bool
  function enterBidForNft(
    uint[] memory tokenId,
    uint[] memory itemId,
    uint[] memory bidValue,
    address[] memory seller
  ) public payable whenNotPaused returns(bool){
    uint total;
    for (uint i;i < tokenId.length;i++){
      total = total.add(bidValue[i]);
      require(bidValue[i] > 1e12, "Must be greater than 1e12 gwei.");
      /*~~~> 
        Check for the case where there is a bid.
          If the bid entered is lesser than the existing bid, revert.
          If the existing bid is lesser than the bid entered, 
            transfer the existing biddder the existing bidValue of the bid. 
      <~~~*/
      uint id = mktIdToBidId[itemId[i]];
      if (id > 0) {
        Bid memory existing = idToNftBid[id];
        if (bidValue[i] <= existing.bidValue) revert();
        if (existing.bidValue < bidValue[i]) {
          //*~~~> Refund the failing bid
          payable(existing.bidder).transfer(existing.bidValue);
        }
      }
      uint bidId;
      uint len = openStorage.length;
      if (len>=1){
        bidId = openStorage[len-1];
        _remove(0);
      } else {
        _bidIds.increment();
        bidId = _bidIds.current();
      }
      idToNftBid[bidId] = Bid(itemId[i], tokenId[i], bidId, bidValue[i], block.timestamp, payable(msg.sender), payable(seller[i]));

      emit BidEntered(
        tokenId[i],
        itemId[i],
        bidId,
        bidValue[i],
        msg.sender, 
        seller[i]);
    }
    require(total == msg.value);
    return true;
  }

  /// @notice
  //*~~~> Public function for entering specific or collection wide blind bids
  /// @dev 
      /*~~~>
        isSpecific: Is bid for a specific NFT(true) or collection-wide bid(false?;
        value: Bid value;
        tokenId: token_id being bid on;
        amount: Amount to be bid on if the specific item is an ERC1155;
        bidAddress: Address of collection to be bid on;
      <~~~*/
  /// @return Bool
  function enterBlindBid(
    bool[] memory isSpecific, 
    uint[] memory value, 
    uint[] memory tokenId, 
    uint[] memory amount, 
    address[] memory bidAddress) public payable whenNotPaused nonReentrant returns(bool){

    address collectionAdd = RoleProvider(roleAdd).fetchAddress(COLLECTION);
    
    uint total;
    for (uint i;i<bidAddress.length;i++){
      total = total.add(value[i]);
      require(value[i] > 1e12, "Must be greater than 1e12 gwei.");
      require(Collections(collectionAdd).isRestricted(bidAddress[i]) == false);
      uint bidId;
      uint len = blindOpenStorage.length;
      if (len>=1){
        bidId=blindOpenStorage[len-1];
        _remove(1);
      } else {
        _blindBidIds.increment();
        bidId = _blindBidIds.current();
      }
      idToBlindBid[bidId] = BlindBid(isSpecific[i], tokenId[i], bidId, value[i], amount[i], bidAddress[i], msg.sender);

      emit BlindBidentered(
        isSpecific[i],
        tokenId[i],
        bidId,
        value[i],
        amount[i],
        bidAddress[i],
        msg.sender
      );
    }
    require(msg.value == total);
    return true;
  }

  /// @notice 
  //*~~~> Public function for accpeting specific or collection wide blind bids
  /// @dev 
      /*~~~>
        blindBidId: Id of the Bid for reference;
        tokenId: token_id being bid on;
        listedId: If the item is listed on Market, 
          and a regular bid is placed on it,
          this allows us to update the market listings;
        is1155: if 1155(true);
      <~~~*/
  /// @return Bool
  function acceptBlindBid(
    uint[] memory blindBidId, 
    uint[] memory tokenId,
    uint[] memory listedId, 
    bool[] memory is1155) public whenNotPaused nonReentrant returns(bool){
    
    address rewardsAdd = RoleProvider(roleAdd).fetchAddress(REWARDS);
    address marketAdd = RoleProvider(roleAdd).fetchAddress(MARKET);
    uint balance = IERC721(marketAdd).balanceOf(msg.sender);

    for (uint i;i<blindBidId.length;i++){
      BlindBid memory bid = idToBlindBid[blindBidId[i]];
      //*~~~> Disallow random acceptances if specific
      if(bid.specific){
          require(tokenId[i]==bid.tokenId,"Wrong item!");
        }
        if(balance<1){
          /*~~~> Calculating the platform fee <~~~*/
          uint256 saleFee = calcFee(bid.bidValue);
          uint256 userAmnt = bid.bidValue.sub(saleFee);
          /// send saleFee to rewards controller
          RewardsController(rewardsAdd).splitRewards{value: saleFee}(saleFee);
          /// send (bidValue - saleFee) to user
          payable(msg.sender).transfer(userAmnt);
        } else {
          payable(msg.sender).transfer(bid.bidValue);
        }
        if (!is1155[i]){
        //*~~~> Disallow if the msg.sender is not the token owner
        require(IERC721(bid.collectionBid).ownerOf(tokenId[i]) == msg.sender, "Not the token owner!");
        if(listedId[i]>0){
            NFTMkt(marketAdd).transferNftForSale(bid.bidder, listedId[i]);
          } else {
            transferFromERC721(bid.collectionBid, tokenId[i], bid.bidder);
          }
      } else {
        uint bal = IERC1155(bid.collectionBid).balanceOf(msg.sender, tokenId[i]);
        require( bal> 0, "Not the token owner!");
        if(listedId[i]==0){
          IERC1155(bid.collectionBid).safeTransferFrom(address(msg.sender), bid.bidder, tokenId[i], bid.amount, "");
        } else {
          NFTMkt(marketAdd).transferNftForSale(bid.bidder, listedId[i]);
        }
      }
      blindOpenStorage.push(blindBidId[i]);
      idToBlindBid[blindBidId[i]] = BlindBid(false, 0, blindBidId[i], 0, 0, address(0x0), address(0x0));
      emit BlindBidAccepted(tokenId[i], blindBidId[i], bid.bidValue, bid.bidder, msg.sender);
    }
    return true;
  }
  
  /// @notice 
  //*~~~> Public function for accepting bids
  /// @dev 
      /*~~~>
        bidId: Id of the Bid;
      <~~~*/
  /// @return Bool
  function acceptBidForNft(
      uint[] memory bidId
  ) public whenNotPaused nonReentrant returns (bool) {

    address marketNft = RoleProvider(roleAdd).fetchAddress(NFT);
    address marketAdd = RoleProvider(roleAdd).fetchAddress(MARKET);
    address offersAdd = RoleProvider(roleAdd).fetchAddress(OFFERS);
    address tradesAdd = RoleProvider(roleAdd).fetchAddress(TRADES);
    address rewardsAdd = RoleProvider(roleAdd).fetchAddress(REWARDS);

    uint balance = IERC721(marketNft).balanceOf(msg.sender);
    for (uint i; i<bidId.length; i++){
      Bid memory bid = idToNftBid[bidId[i]];
      require(msg.sender == bid.seller);
      if(balance<1) {
          /*~~~> Calculating the platform fee <~~~*/
          uint256 saleFee = calcFee(bid.bidValue);
          uint256 userAmnt = bid.bidValue.sub(saleFee);
          /// send saleFee to rewards controller
          RewardsController(rewardsAdd).splitRewards{value: saleFee}(saleFee);
          /// send (bidValue - saleFee) to user
          payable(bid.seller).transfer(userAmnt);
      } else {
        payable(bid.seller).transfer(bid.bidValue);
      }
      /*~~~> Check for the case where there is a trade and refund it. <~~~*/
      uint offerId = Offers(offersAdd).fetchOfferId(bid.itemId);
      if (offerId > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the NFT offered for trade
        Offers(offersAdd).refundOffer(bid.itemId, offerId);
      }
      /*~~~> Check for the case where there is an offer and refund it. <~~~*/
      uint tradeId = Trades(tradesAdd).fetchTradeId(bid.itemId);
      if (tradeId > 0) {
      /*~~~> Kill offer and refund amount <~~~*/
        //*~~~> Call the contract to refund the ERC20 offered for trade
        Trades(tradesAdd).refundTrade(bid.itemId, tradeId);
      }
      openStorage.push(bidId[i]);
      idToNftBid[bidId[i]] = Bid(0, 0, bidId[i], 0, 0, payable(address(0x0)), payable(address(0x0)));
      NFTMkt(marketAdd).transferNftForSale(address(bid.bidder), bid.itemId);
      emit BidAccepted(bid.itemId, bidId[i], bid.bidValue, bid.bidder, bid.seller);
    }
  return true;
  }

  /// @notice 
    //*~~~> Public function to withdraw both blind or regular bids
  /// @dev
    /*~~~>
      bidId: Id of the bid in storage to be withdrawn;
      isBlind: if it is a blind blind (true);
    <~~~*/
  /// @return Bool
  function withdrawBid(uint[] memory bidId, bool[] memory isBlind) public  nonReentrant returns(bool){
    for (uint i;i<bidId.length;i++){
      if (isBlind[i]){
        BlindBid memory bid = idToBlindBid[bidId[i]];
        if (bid.bidder != msg.sender) revert();
        payable(bid.bidder).transfer(bid.bidValue);
        blindOpenStorage.push(bidId[i]);
        idToBlindBid[bidId[i]] = BlindBid(false, 0, bid.bidId, 0, 0, (address(0x0)), payable(address(0x0)));
        emit BlindBidWithdrawn(bidId[i], msg.sender);
      } else {
        Bid memory bid = idToNftBid[bidId[i]];
        require(bid.timestamp < block.timestamp - 1 days);
        if (bid.bidder != msg.sender) revert();
        payable(bid.bidder).transfer(bid.bidValue);
        openStorage.push(bidId[i]);
        idToNftBid[bidId[i]] = Bid(0, 0, bid.bidId, 0, 0, payable(address(0x0)), payable(address(0x0)));
        emit BidWithdrawn(bid.tokenId, bidId[i], msg.sender);
      }
    }
    return true;
  }

  /// @notice 
    //*~~~> only CONTRACT_ROLE function to refund regular bids if the item is bought
  /// @dev
    /*~~~>
      tokenId: Id of the NFT to be refunded;
      bidId: Id for the bid item to return;
    <~~~*/
  /// @return Bool
  function refundBid(uint bidId) public nonReentrant hasContractAdmin returns(bool) {
    Bid memory bid = idToNftBid[bidId];
    payable(bid.bidder).transfer(bid.bidValue);
    openStorage.push(bidId);
    emit BidRefunded(bid.tokenId, bidId, msg.sender);
    idToNftBid[bidId] = Bid(0, 0, bid.bidId, 0, 0, payable(address(0x0)), payable(address(0x0)));
    return true;
  }

  /// @notice 
    /*~~~> 
      Internal function to transfer ERC721 NFTs, including crypto kitties/punks
    <~~~*/
  /// @dev
    /*~~~>
      assetAddr: address of the token to be transfered;
      tokenId: Id of the token to be transfered;
      to: to be transfered to;
    <~~~*/
function transferFromERC721(address assetAddr, uint256 tokenId, address to) internal virtual {
    address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    bytes memory data;
    if (assetAddr == kitties) {
        //*~~~> Cryptokitties.
        data = abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, to, tokenId);
    } else if (assetAddr == punks) {
        //*~~~> CryptoPunks.
        bytes memory punkIndexToAddress = abi.encodeWithSignature("punkIndexToAddress(uint256)", tokenId);
        (bool checkSuccess, bytes memory result) = address(assetAddr).staticcall(punkIndexToAddress);
        (address nftOwner) = abi.decode(result, (address));
        require(checkSuccess && nftOwner == msg.sender, "Not the NFT owner");
        data = abi.encodeWithSignature("transferPunk(address,uint256)", msg.sender, tokenId);
    } else {
        //*~~~> Default.
        //*~~~> We push to avoid an unneeded transfer.
        data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", msg.sender, to, tokenId);
    }
    (bool success, bytes memory resultData) = address(assetAddr).call(data);
    require(success, string(resultData));
  }

  /// @notice 
  /*~~~> 
    Internal function for removing elements from an array
    Only used for internal storage array index recycling

      In order to reduce storage array size of listed items 
        while maintaining specific enumerable bidId's, 
        any sold or removed item spots are re-used by referring to their index,
        else a new storage spot is created;

        We use the last item in the storage (length of array - 1),
        in order to pop off the item and avoid rewriting 
  <~~~*/
  function _remove(uint store) internal {
      if (store==0){
      openStorage.pop();
      } else if (store==1){
      blindOpenStorage.pop();
      }
    }

  /// @notice 
  //*~~~> Public read functions
  function fetchBidItems() public view returns (Bid[] memory) {
    uint bidcount = _bidIds.current();
    Bid[] memory bids = new Bid[](bidcount);
    for (uint i; i < bidcount; i++) {
      if (idToNftBid[i + 1].itemId > 0) {
        Bid storage currentItem = idToNftBid[i + 1];
        bids[i] = currentItem;
      }
    }
    return bids;
  }

  function fetchBidItemsByBidder(address bidder) public view returns (Bid[] memory) {
    uint bidcount = _bidIds.current();
    Bid[] memory bids = new Bid[](bidcount);
    for (uint i; i < bidcount; i++) {
      if (idToNftBid[i + 1].bidder == bidder) {
        Bid storage currentItem = idToNftBid[i + 1];
        bids[i] = currentItem;
      }
    }
    return bids;
  }

  function fetchBlindBidItems() public view returns (BlindBid[] memory) {
    uint bidcount = _blindBidIds.current();
    BlindBid[] memory bids = new BlindBid[](bidcount);
    for (uint i; i < bidcount; i++) {
      if (idToBlindBid[i + 1].bidValue > 0) {
        BlindBid storage currentItem = idToBlindBid[i + 1];
        bids[i] = currentItem;
      }
    }
    return bids;
  }

  function fetchBlindBidItemsByBidder(address bidder) public view returns (BlindBid[] memory) {
    uint bidcount = _blindBidIds.current();
    BlindBid[] memory bids = new BlindBid[](bidcount);
    for (uint i; i < bidcount; i++) {
      if (idToBlindBid[i + 1].bidder == bidder) {
        BlindBid storage currentItem = idToBlindBid[i + 1];
        bids[i] = currentItem;
      }
    }
    return bids;
  }

  function fetchBlindBidItemById(uint _bidId) public view returns (BlindBid memory bid) {
    BlindBid memory currentItem = idToBlindBid[_bidId];
    return currentItem;
  }

  function fetchBidItemById(uint tokenId) public view returns (Bid memory bid) { 
    uint bidcount = _bidIds.current();
    for (uint i; i < bidcount; i++) {
      if (idToNftBid[i + 1].tokenId == tokenId) {
        Bid memory currentItem = idToNftBid[i + 1];
        return currentItem;
      }
    }
  }

  function fetchBidId(uint marketId) public view returns (uint id) {
    uint _id = mktIdToBidId[marketId];
    return _id;
  }

  ///@notice DEV operations for emergency functions
  function pause() public hasDevAdmin {
      _pause();
  }
  function unpause() public hasDevAdmin {
      _unpause();
  }

  ///@notice
  /*~~~> External ETH transfer forwarded to role provider contract <~~~*/
  event FundsForwarded(uint value, address _from, address _to);
  receive() external payable {
    payable(roleAdd).transfer(msg.value);
      emit FundsForwarded(msg.value, msg.sender, roleAdd);
  }
}