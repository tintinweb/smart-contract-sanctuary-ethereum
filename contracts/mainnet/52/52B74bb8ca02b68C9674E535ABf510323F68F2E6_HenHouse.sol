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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import './interfaces/IEGGToken.sol';
import './interfaces/IEggShop.sol';
import './interfaces/IFarmAnimals.sol';
import './interfaces/IHenHouse.sol';
import './interfaces/IHenHouseCalc.sol';
import './interfaces/IHenHouseAdvantage.sol';
import './interfaces/ITheFarmGameMint.sol';
import './interfaces/IRandomizer.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract HenHouse is IHenHouse, Ownable, ReentrancyGuard, IERC721Receiver, Pausable {
  using SafeMath for uint256;

  // Events
  event InitializedContract(address thisContract);
  event TokenStaked(
    address indexed owner,
    uint16 indexed tokenId,
    string kind,
    uint256 eggPerRank,
    uint256 stakedTimestamp,
    uint256 unstakeTimestamp
  );
  event EggClaimedUnstaked(
    uint16 indexed tokenId,
    bool indexed unstaked,
    string kind,
    uint256 earned,
    uint256 unstakeTimestamp
  );
  event RoosterReceivedDroppedEgg(address indexed owner, uint16 indexed tokenId, uint256 amount);
  event GoldenEggAwarded(address indexed recipient);

  // Interfaces
  IFarmAnimals public farmAnimalsNFT; // ref to the FarmAnimals NFT contract
  ITheFarmGameMint public theFarmGameMint; // ref to the TheFarmGameMint contract
  IEGGToken public eggToken; // ref to the $EGG contract for minting $EGG earnings
  IRandomizer public randomizer; // ref to the EggShop contract
  IEggShop public eggshop; // ref to the EggShop contract
  IHenHouseAdvantage public henHouseAdvantage; // ref to HenHouseAdvantage contract
  IHenHouseCalc public henHouseCalc; // ref to HenHouseCalc contract

  mapping(address => bool) private controllers; // address => allowedToCallFunctions

  mapping(address => uint256[]) public stakedNFTs; // mapping from user address to Token List
  mapping(uint256 => uint256) public stakedNFTsIndices;

  uint8 public constant MAX_RANK = 5; // Maximum rank for a Hen/Coyote/Rooster

  // Hens
  uint256 public constant DAILY_EGG_RATE = 10000 ether; // Hens earn 10000 $EGG per day
  uint256 private numHensStaked; // Track staked hens
  uint256 public totalEGGEarnedByHen; // Amount of $EGG earned so far
  uint256 private lastClaimTimestampByHen; // The last time $EGG was claimed
  mapping(uint256 => Stake) public henHouse; // Maps tokenId to stake in henHouse
  uint256 public HEN_MINIMUM_TO_EXIT = 2 days; // hens must have 2 days worth of $EGG quota to unstake

  // Coyotes
  uint256 private numCoyotesStaked;
  uint256 private totalCoyoteRankStaked;
  uint256 private eggPerCoyoteRank = 0; // Amount of tax $EGG due per Wily rank point staked
  uint256 private unaccountedCoyoteTax = 0; // Any EGG distributed when no coyotes are staked
  uint256 public dropCoyoteRate = 40; // $EGG drop rate to coyote when hen claim their reward $EGG token
  uint256 public constant COYOTE_TAX = 20; // Coyotes take a 20% tax on all $EGG claimed by Hens
  mapping(uint256 => Stake[]) private den; // Maps rank to all Coyote staked with that rank
  mapping(uint256 => uint256) private denIndices; // Tracks location of each Coyote in Den

  // Roosters
  uint256 private numRoostersStaked;
  uint256 private totalRoosterRankStaked;
  uint256 private eggPerRoosterRank = 0; // Amount of dialy $EGG due per Guard rank point staked
  uint256 private rescueEggPerRank = 0; // Amunt of rescued $EGG due per Guard rank staked
  uint256 public totalEGGEarnedByRooster; // amount of $EGG earned so far
  uint256 private lastClaimTimestampByRooster;
  mapping(uint256 => Stake[]) private guardHouse; // Maps rank to all Roosters staked with that rank
  mapping(uint256 => uint256) private guardHouseIndices; // Tracks location of each Rooster in Guard house
  uint256 public constant DAILY_ROOSTER_EGG_RATE = 1000 ether; // Rooster earn 1000 ether per day on guard duty
  uint256 public ROOSTER_MUG_RATE = 30; // Coyotes have a 10% chance of taking 30% of the rooster's claimed $EGG when unstake
  uint256 public ROOSTER_MINIMUM_TO_EXIT = 5 days; // Roosters must have 5 days worth of $EGG quota to unstake

  // Recource tracking
  uint256 public constant MAXIMUM_GLOBAL_EGG = 2880000000 ether; // there will only ever be (roughly) 2.88 billion $EGG earned through staking
  uint256 public rescuedEggPool; // Rescue EGG token pool from EGG transfer tax
  uint256 public rescuedEggPoolRate = 20; // Rate to separate the amount of tokens coming from EggToken Contract for RescuedEggPool
  uint256 public genericEggPool; // Generic EGG token pool from EGG transfer tax
  uint256 public genericEggPoolRate = 8; // Rate to separate the amount of tokens coming from EggToken Contract for GenericEggPool

  // Egg Shop
  uint256 public goldenEggTypeId = 4; // EggShop Golden Egg Type Id
  uint256 public goldenRate = 60;
  uint256 private lastGoldenClaimedTimestamp; // the last time Golden Egg claimed
  uint256 private goldenCountPerDay;

  bool public rescueEnabled = false; // emergency rescue to allow unstaking without any checks but without $EGG

  /** MODIFIERS */

  modifier requireContractsSet() {
    require(
      address(farmAnimalsNFT) != address(0) &&
        address(eggToken) != address(0) &&
        address(theFarmGameMint) != address(0) &&
        address(randomizer) != address(0) &&
        address(henHouseAdvantage) != address(0) &&
        address(henHouseCalc) != address(0),
      'Contracts not set'
    );
    _;
  }

  /**
   * @dev Modifer to require _msgSender() to be a controller
   */
  modifier onlyController() {
    _isController();
    _;
  }

  // Optimize for bytecode size
  function _isController() internal view {
    require(controllers[_msgSender()], 'Only controllers');
  }

  constructor(
    IEGGToken _eggToken,
    IFarmAnimals _farmAnimalsNFT,
    IRandomizer _randomizer,
    IEggShop _eggshop,
    IHenHouseAdvantage _henHouseAdvantage,
    IHenHouseCalc _henHouseCalc
  ) {
    eggToken = _eggToken;
    farmAnimalsNFT = _farmAnimalsNFT;
    randomizer = _randomizer;
    eggshop = _eggshop;
    henHouseAdvantage = _henHouseAdvantage;
    henHouseCalc = _henHouseCalc;
    lastGoldenClaimedTimestamp = block.timestamp;
    _addController(msg.sender);
    _addController(address(farmAnimalsNFT));
    _pause();
    emit InitializedContract(address(this));
  }

  /**
   * ██ ███    ██ ████████
   * ██ ████   ██    ██
   * ██ ██ ██  ██    ██
   * ██ ██  ██ ██    ██
   * ██ ██   ████    ██
   * This section has internal only functions
   */

  /**
   * @notice Adds a single Hen to the HenHouse
   * @param account the address of the staker
   * @param tokenId the ID of the Hen to add to the HenHouse
   */
  function _addHenToHenHouse(address account, uint256 tokenId) internal _updateEarnings {
    uint256 unstakeTimestamp = block.timestamp + HEN_MINIMUM_TO_EXIT;
    henHouse[tokenId] = Stake({
      tokenId: uint16(tokenId),
      owner: account,
      eggPerRank: uint80(block.timestamp),
      rescueEggPerRank: 0,
      oneOffEgg: 0,
      stakedTimestamp: block.timestamp,
      unstakeTimestamp: unstakeTimestamp
    });
    numHensStaked = numHensStaked.add(1);
    emit TokenStaked(account, uint16(tokenId), 'HEN', DAILY_EGG_RATE, block.timestamp, unstakeTimestamp);
  }

  /**
   * @notice Adds a single Coyote to the Den
   * @param account the address of the staker
   * @param tokenId the ID of the Coyote to add to the Den
   */
  function _addCoyoteToDen(address account, uint16 tokenId) internal {
    uint8 rank = _rankForCoyoteRooster(tokenId);

    totalCoyoteRankStaked = totalCoyoteRankStaked.add(rank); // Portion of earnings ranges from 8 to 5
    denIndices[tokenId] = den[rank].length; // Store the location of the coyote in the Den
    den[rank].push(
      Stake({
        tokenId: uint16(tokenId),
        owner: account,
        eggPerRank: uint80(eggPerCoyoteRank),
        rescueEggPerRank: 0,
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: block.timestamp
      })
    ); // Add the coyote to the Den
    numCoyotesStaked = numCoyotesStaked.add(1);
    emit TokenStaked(account, uint16(tokenId), 'COYOTE', eggPerCoyoteRank, block.timestamp, block.timestamp);
  }

  /**
   * @notice Adds a single Rooster to the Guard house
   * @param account the address of the staker
   * @param tokenId the ID of the Rooster to add to the Guard house
   */
  function _addRoosterToGuardHouse(address account, uint16 tokenId) internal {
    uint256 rank = uint256(_rankForCoyoteRooster(tokenId));
    uint256 unstakeTimestamp = block.timestamp + ROOSTER_MINIMUM_TO_EXIT;
    totalRoosterRankStaked = totalRoosterRankStaked.add(rank); // Portion of earnings ranges from 8 to 5
    guardHouseIndices[tokenId] = guardHouse[rank].length; // Store the location of the rooster in the Guard house
    guardHouse[rank].push(
      Stake({
        tokenId: uint16(tokenId),
        owner: account,
        eggPerRank: uint80(eggPerRoosterRank),
        rescueEggPerRank: uint80(rescueEggPerRank),
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: unstakeTimestamp
      })
    ); // Add the rooster to the Guard house

    numRoostersStaked = numRoostersStaked.add(1);

    emit TokenStaked(account, uint16(tokenId), 'ROOSTER', eggPerRoosterRank, block.timestamp, unstakeTimestamp);
  }

  /**
   * @notice Realize $EGG earnings for a single Hen and optionally unstake it
   * if not unstaking, pay a 20% tax to the staked Coyotes
   * if unstaking, there is a 50% chance all $EGG is stolen
   * @param tokenId the ID of the Hens to claim earnings from
   * @param unstake whether or not to unstake the Hens
   * @return owed - the amount of $EGG earned
   */
  function _claimHenFromHenHouse(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
    Stake memory stake = henHouse[tokenId];

    require(stake.owner == tx.origin, 'Caller not owner');
    owed = henHouseCalc.calculateRewardsHen(uint16(tokenId), stake);
    henHouseAdvantage.updateAdvantageBonus(tokenId);

    if (unstake) {
      require(block.timestamp > stake.unstakeTimestamp, 'Need the min EGG quota to unstake');
      if (randomizer.random() & 1 == 1) {
        // 50% chance of all $EGG stolen
        _payCoyoteTax(owed);
        owed = 0;
      }

      delete henHouse[tokenId];
      henHouseAdvantage.removeAdvantageBonus(uint16(tokenId)); // delete production bonus of tokenId when unstaked
      numHensStaked = numHensStaked.sub(1);
      // Always transfer last to guard against reentrance
      farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // send back Hen
      _removeStakedAddress(_msgSender(), tokenId);
    } else {
      uint256 henCoyoteTax = (owed.mul(COYOTE_TAX)).div(100);
      _payCoyoteTax(henCoyoteTax); // percentage tax to staked coyotes
      owed = (owed.sub(henCoyoteTax)); // remainder goes to Hen owner
      uint256 unstakeTimestamp = block.timestamp + HEN_MINIMUM_TO_EXIT;
      henHouse[tokenId] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        eggPerRank: uint80(block.timestamp),
        rescueEggPerRank: 0,
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: unstakeTimestamp
      }); // reset stake
    }
    emit EggClaimedUnstaked(uint16(tokenId), unstake, 'HEN', owed, block.timestamp + HEN_MINIMUM_TO_EXIT);
  }

  /**
   * @notice Realize $EGG earnings for a single Coyote and optionally unstake it
   * Coyotes earn $EGG proportional to their rank
   * @param tokenId the ID of the Coyote to claim earnings from
   * @param unstake whether or not to unstake the Coyote
   * @return owed - the amount of $EGG earned
   */
  function _claimCoyoteFromDen(uint16 tokenId, bool unstake) internal returns (uint256 owed) {
    uint8 rank = _rankForCoyoteRooster(tokenId);
    owed = henHouseCalc.calculateRewardsCoyote(uint16(tokenId), rank);

    henHouseAdvantage.updateAdvantageBonus(tokenId);

    // If there are roosters then chance that one may rescues some dropped EGGs
    if (randomizer.random() & 10 == 1 && numRoostersStaked > 0) {
      // Calculate 10% chance coyote drops some egg
      uint256 dAmount = _calcCoyoteDropRate(owed); // Calculate the Drop Amount Egg of owned
      owed = owed.sub(dAmount); // Remove Drop Amount of owned
      _coyoteDropEggToRooster(tokenId, dAmount);
    }

    if (unstake) {
      totalCoyoteRankStaked = totalCoyoteRankStaked.sub(rank); // Remove rank from total staked
      Stake memory lastStake = den[rank][den[rank].length - 1];
      den[rank][denIndices[tokenId]] = lastStake; //  Shuffle last Coyote to current position
      denIndices[lastStake.tokenId] = denIndices[tokenId];
      den[rank].pop(); // Remove duplicate
      delete denIndices[tokenId]; // Delete old mapping
      henHouseAdvantage.removeAdvantageBonus(tokenId); // Delete old mapping
      numCoyotesStaked = numCoyotesStaked.sub(1);
      // Always remove last to guard against reentrance
      farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Coyote
      _removeStakedAddress(_msgSender(), tokenId);
    } else {
      den[rank][denIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        eggPerRank: uint80(eggPerCoyoteRank),
        rescueEggPerRank: 0,
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: block.timestamp
      }); // reset stake
    }
    emit EggClaimedUnstaked(uint16(tokenId), unstake, 'COYOTE', owed, block.timestamp);
  }

  /**
   * @notice Realize $EGG earnings for a single Rooster and optionally unstake it
   * Rooster earn $EGG proportional to their rank
   * @param tokenId the ID of the Rooster to claim earnings from
   * @param unstake whether or not to unstake the Rooster
   * @return owed - the amount of $EGG earned
   */
  function _claimRoosterFromGuardHouse(uint16 tokenId, bool unstake) internal returns (uint256 owed) {
    uint8 rank = _rankForCoyoteRooster(tokenId);
    Stake memory stake = guardHouse[rank][guardHouseIndices[tokenId]];
    require(stake.owner == tx.origin, 'Caller not owner');

    owed = henHouseCalc.calculateRewardsRooster(tokenId, rank, stake);

    henHouseAdvantage.updateAdvantageBonus(tokenId);

    if (unstake) {
      require(block.timestamp > stake.unstakeTimestamp, 'Roosters should finish 5 days of guard duty');
      // Roosters 10% chance pay 30% tax to coyotes
      if (randomizer.random() & 10 == 1) {
        uint256 roosterCoyoteTax = (owed.mul(ROOSTER_MUG_RATE)).div(100);
        _payCoyoteTax(roosterCoyoteTax); // percentage tax to staked coyotes
        owed = (owed.sub(roosterCoyoteTax));
      }

      totalRoosterRankStaked -= rank; // Remove rank from total staked
      Stake memory lastStake = guardHouse[rank][guardHouse[rank].length - 1];
      guardHouse[rank][guardHouseIndices[tokenId]] = lastStake; // Shuffle last Rooster to current position
      guardHouseIndices[lastStake.tokenId] = guardHouseIndices[tokenId];
      guardHouse[rank].pop(); // Remove duplicate
      delete guardHouseIndices[tokenId]; // Delete old mapping
      henHouseAdvantage.removeAdvantageBonus(tokenId); // Delete old mapping
      numRoostersStaked = numRoostersStaked.sub(1);
      // Always remove last to guard against reentrance
      farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Rooster
      _removeStakedAddress(_msgSender(), tokenId);
    } else {
      uint256 unstakeTimestamp = block.timestamp + ROOSTER_MINIMUM_TO_EXIT;
      guardHouse[rank][guardHouseIndices[tokenId]] = Stake({
        owner: _msgSender(),
        tokenId: uint16(tokenId),
        eggPerRank: uint80(eggPerRoosterRank),
        rescueEggPerRank: uint80(rescueEggPerRank),
        oneOffEgg: 0,
        stakedTimestamp: block.timestamp,
        unstakeTimestamp: unstakeTimestamp
      }); // reset stake
    }
    emit EggClaimedUnstaked(uint16(tokenId), unstake, 'ROOSTER', owed, block.timestamp + ROOSTER_MINIMUM_TO_EXIT);
  }

  /**
   * @notice Get token kind (chicken, coyote, rooster)
   * @param tokenId the ID of the token to check
   * @return kind
   */
  function _getKind(uint16 tokenId) internal view returns (IFarmAnimals.Kind) {
    return farmAnimalsNFT.getTokenTraits(tokenId).kind;
  }

  /** ACCOUNTING */

  /**
   * @notice Add $EGG to claimable pot for the Coyote Den
   * @param amount $EGG to add to the pot
   */
  function _payCoyoteTax(uint256 amount) internal {
    if (totalCoyoteRankStaked == 0) {
      // if there's no staked coyotes
      unaccountedCoyoteTax += amount; // keep track of $EGG due to coyotes
      return;
    }
    // makes sure to include any unaccounted $EGG
    eggPerCoyoteRank += (amount + unaccountedCoyoteTax) / totalCoyoteRankStaked;
    unaccountedCoyoteTax = 0;
  }

  /**
   * @notice Add Dropped $EGG amount to a randome Rooster
     @param tokenId the ID of the Coyote to claim earnings from
   * @param amount $EGG amount of dropped from Coyote
   */

  function _coyoteDropEggToRooster(uint256 tokenId, uint256 amount) internal {
    uint256 seed = randomizer.randomToken(tokenId);
    uint16 roosterTokenId = randomRoosterTokenId(seed); // Get a random rooster
    uint8 rank = _rankForCoyoteRooster(uint16(roosterTokenId)); // Rank for the random rooster
    Stake storage stake = guardHouse[rank][guardHouseIndices[roosterTokenId]]; // Grab the rooster to update

    uint256 accruedOneOffEgg = stake.oneOffEgg;
    accruedOneOffEgg += amount;
    stake.oneOffEgg = accruedOneOffEgg;
    // eggToken.mint(stakeOwner.owner, amount);
    emit RoosterReceivedDroppedEgg(stake.owner, uint16(stake.tokenId), amount);
  }

  /**
   * @notice Gets the rank score for a Coyote
   * @param tokenId the ID of the Coyote to get the rank score for
   * @return the rank score of the Coyote & Rooster(5-8)
   */
  function _rankForCoyoteRooster(uint16 tokenId) internal view returns (uint8) {
    IFarmAnimals.Traits memory s = farmAnimalsNFT.getTokenTraits(tokenId);
    return uint8(s.advantage + 1); // rank index is 0-4
  }

  /**
   * @notice Tracks $EGG earnings to ensure it stops once max $EGG Token is eclipsed
   */
  modifier _updateEarnings() {
    if ((totalEGGEarnedByHen + totalEGGEarnedByRooster) < MAXIMUM_GLOBAL_EGG) {
      // update hen
      totalEGGEarnedByHen += ((block.timestamp - lastClaimTimestampByHen) * numHensStaked * DAILY_EGG_RATE) / 1 days;
      lastClaimTimestampByHen = block.timestamp;

      // update rooster
      totalEGGEarnedByRooster +=
        ((block.timestamp - lastClaimTimestampByRooster) * numRoostersStaked * DAILY_ROOSTER_EGG_RATE) /
        1 days;
      lastClaimTimestampByRooster = block.timestamp;
    }

    _calcEggPerRankOfRooster();
    _;
  }

  /**
   * @notice calc the rescuedEggPool, genericEggPool from the Contract $Egg Balance.
   */
  function _calcEggPerRankOfRooster() internal {
    // Only calculate if there is Roosters staked
    if (numRoostersStaked > 0 && rescuedEggPool > 0) {
      uint256 balance = eggToken.balanceOf(address(this));
      // If HenHouse has an $EGG token balance from transfer tax, include that in updated pool calcs
      if (balance > 0) {
        uint256 _extraRescuedEggPool = (balance * rescuedEggPoolRate) / (rescuedEggPoolRate + genericEggPoolRate);
        rescuedEggPool += _extraRescuedEggPool;

        uint256 _extraGenericEggPool = balance - _extraRescuedEggPool;

        genericEggPool += _extraGenericEggPool;

        eggToken.burn(address(this), balance);
      }

      rescueEggPerRank += rescuedEggPool / totalRoosterRankStaked; // Recalculate eggRankForRooster
      // rescueEggPerRank += rescuedEggPool / numRoostersStaked; // Recalculate eggRankForRooster
      rescuedEggPool = 0; // Since rescuedEggPool added to EggRankForRooster, reset pool to 0
    }
  }

  /**
   * @notice Get drop amount from Coyote by dropCoyoteRate
     @param amount claim amount for calculating drop amount from coyote
   */

  function _calcCoyoteDropRate(uint256 amount) internal view returns (uint256) {
    return amount.mul(dropCoyoteRate).div(10**2);
  }

  /** @notice Mint a golen egg token to receipt
   * @param receipt receipt address to get golden token
   */

  function _awardGoldenEgg(address receipt) internal {
    if (block.timestamp.sub(lastGoldenClaimedTimestamp) <= 1 days) {
      uint256 randomRate = randomizer.random().mod(100);
      if (goldenCountPerDay < 24 && (randomRate < goldenRate)) {
        eggshop.mint(goldenEggTypeId, 1, receipt, uint256(0));
        goldenCountPerDay += 1;
        emit GoldenEggAwarded(receipt);
      } else {
        lastGoldenClaimedTimestamp = block.timestamp;
        goldenCountPerDay = 0;
      }
    }
  }

  /** @notice Remove the staked info from HenHouse staked history list by token owner
   * @param stakedOwner Owner address of staked NFT
   * @param tokenId Token Id to remove the staked info from HenHouse
   */

  function _removeStakedAddress(address stakedOwner, uint256 tokenId) internal {
    uint256 lastStakedNFTs = stakedNFTs[stakedOwner][stakedNFTs[stakedOwner].length - 1];
    stakedNFTs[stakedOwner][stakedNFTsIndices[tokenId]] = lastStakedNFTs;
    stakedNFTsIndices[stakedNFTs[stakedOwner][stakedNFTs[stakedOwner].length - 1]] = stakedNFTsIndices[tokenId];
    stakedNFTs[_msgSender()].pop();
    delete stakedNFTsIndices[tokenId];
  }

  /**
   * ███████ ██   ██ ████████
   * ██       ██ ██     ██
   * █████     ███      ██
   * ██       ██ ██     ██
   * ███████ ██   ██    ██
   * This section has external functions
   */

  /** STAKING */

  /**
   * @notice Adds Hens, Coyotes & Roosters to the Hen House, Den & Guard house
   * @param account the address of the staker
   * @param tokenIds the IDs of the Hens, Coyotes or Roosters to stake
   */
  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external override nonReentrant whenNotPaused{
    require(tx.origin == _msgSender() || _msgSender() == address(theFarmGameMint), 'Only EOA');
    require(account == tx.origin, 'Account to sender mismatch');
    for (uint8 i = 0; i < tokenIds.length; i++) {
      if (_msgSender() != address(theFarmGameMint)) {
        // dont do this step if its a mint + stake
        require(farmAnimalsNFT.ownerOf(tokenIds[i]) == _msgSender(), 'Caller not owner');
        farmAnimalsNFT.transferFrom(_msgSender(), address(this), tokenIds[i]);
      } else if (tokenIds[i] == 0) {
        continue; // there may be gaps in the array for stolen tokens
      }

      IFarmAnimals.Kind kind = _getKind(tokenIds[i]);
      if (kind == IFarmAnimals.Kind.HEN) {
        _addHenToHenHouse(account, tokenIds[i]);
      } else if (kind == IFarmAnimals.Kind.COYOTE) {
        _addCoyoteToDen(account, tokenIds[i]);
      } else if (kind == IFarmAnimals.Kind.ROOSTER) {
        _addRoosterToGuardHouse(account, tokenIds[i]);
      }
      stakedNFTs[account].push(tokenIds[i]);
      stakedNFTsIndices[tokenIds[i]] = stakedNFTs[account].length - 1;

      henHouseAdvantage.updateAdvantageBonus(tokenIds[i]);
    }
  }

  /** CLAIMING / UNSTAKING */

  /**
   * @notice Check if tokenID is eligible to be unstaked
   * @param tokenId the ID of the Rooster to claim earnings from
   * @return bool - true/false
   */
  function canUnstake(uint16 tokenId) external view returns (bool) {
    bool canUnstak = false;
		if (paused() == true) return false;
    IFarmAnimals.Kind kind = _getKind(tokenId);
    if (kind == IFarmAnimals.Kind.HEN) {
      Stake memory stake = henHouse[tokenId];
      if (stake.unstakeTimestamp <= block.timestamp) {
        canUnstak = true;
      }
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      Stake memory stake = den[rank][denIndices[tokenId]];
      if (stake.unstakeTimestamp <= block.timestamp) {
        canUnstak = true;
      }
    } else if (kind == IFarmAnimals.Kind.ROOSTER) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      Stake memory stake = guardHouse[rank][guardHouseIndices[tokenId]];
      if (stake.unstakeTimestamp <= block.timestamp) {
        canUnstak = true;
      }
    }
    return canUnstak;
  }

  /**
   * @notice Realize $EGG earnings and optionally unstake tokens from the HenHouse / Den
   * to unstake a Hen it will require it has 2 days worth of $EGG unclaimed
   * @param tokenIds the IDs of the tokens to claim earnings from
   * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
   */
  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake)
    external
    whenNotPaused
    _updateEarnings
    nonReentrant
  {
    require(tx.origin == _msgSender() || _msgSender() == address(theFarmGameMint), 'Only EOA');
    uint256 owed = 0;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(farmAnimalsNFT.ownerOf(tokenIds[i]) == address(this), 'Hen House not owner');
      if (tx.origin == _msgSender()) {
        IEggShop.TypeInfo memory goldenTypeInfo = eggshop.getInfoForType(goldenEggTypeId);
        if ((goldenTypeInfo.mints + goldenTypeInfo.burns) <= goldenTypeInfo.maxSupply) {
          _awardGoldenEgg(_msgSender());
        }
      }
      IFarmAnimals.Kind kind = _getKind(tokenIds[i]);
      if (kind == IFarmAnimals.Kind.HEN) {
        owed = owed.add(_claimHenFromHenHouse(tokenIds[i], unstake));
      } else if (kind == IFarmAnimals.Kind.COYOTE) {
        owed = owed.add(_claimCoyoteFromDen(tokenIds[i], unstake));
      } else if (kind == IFarmAnimals.Kind.ROOSTER) {
        owed = owed.add(_claimRoosterFromGuardHouse(tokenIds[i], unstake));
      }
    }
    if (owed == 0) {
      return;
    }
    eggToken.mint(_msgSender(), owed);
  }

  /**
   * @notice Emergency unstake tokens
   * @param tokenIds the IDs of the tokens to rescue, egg earnings are lost
   */
  function rescue(uint16[] calldata tokenIds) external nonReentrant {
    require(rescueEnabled, 'RESCUE DISABLED');
    uint16 tokenId;
    uint8 rank;

    for (uint256 i = 0; i < tokenIds.length; i++) {
      tokenId = tokenIds[i];

      IFarmAnimals.Kind kind = _getKind(tokenId);

      if (kind == IFarmAnimals.Kind.HEN) {
        Stake memory stake;
        stake = henHouse[tokenId];
        require(stake.owner == _msgSender(), 'Caller not owner');
        delete henHouse[tokenId];
        numHensStaked = numHensStaked.sub(1);
        farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // send back Hens
        emit EggClaimedUnstaked(uint16(tokenId), true, 'HEN', 0, block.timestamp);
      } else if (kind == IFarmAnimals.Kind.COYOTE) {
        rank = _rankForCoyoteRooster(tokenId);
        Stake memory stake = den[rank][denIndices[tokenId]];
        Stake memory lastStake;
        require(stake.owner == _msgSender(), 'Caller not owner');
        totalCoyoteRankStaked -= rank; // Remove Rank from total staked
        lastStake = den[rank][den[rank].length - 1];
        den[rank][denIndices[tokenId]] = lastStake; // Shuffle last Coyote to current position
        denIndices[lastStake.tokenId] = denIndices[tokenId];
        den[rank].pop(); // Remove duplicate
        delete denIndices[tokenId]; // Delete old mapping
        numCoyotesStaked = numCoyotesStaked.sub(1);
        farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Coyote
        emit EggClaimedUnstaked(uint16(tokenId), true, 'COYOTE', 0, block.timestamp);
      } else if (kind == IFarmAnimals.Kind.ROOSTER) {
        Stake memory stake;
        Stake memory lastStake;
        rank = _rankForCoyoteRooster(tokenId);
        stake = guardHouse[rank][guardHouseIndices[tokenId]];
        require(stake.owner == _msgSender(), 'Caller not owner');
        totalRoosterRankStaked -= rank; // Remove Rank from total staked
        lastStake = guardHouse[rank][guardHouse[rank].length - 1];
        guardHouse[rank][guardHouseIndices[tokenId]] = lastStake; // Shuffle last Rooster to current position
        guardHouseIndices[lastStake.tokenId] = guardHouseIndices[tokenId];
        guardHouse[rank].pop(); // Remove duplicate
        delete guardHouseIndices[tokenId]; // Delete old mapping
        numRoostersStaked = numRoostersStaked.sub(1);
        farmAnimalsNFT.safeTransferFrom(address(this), _msgSender(), tokenId, ''); // Send back Rooster
        emit EggClaimedUnstaked(uint16(tokenId), true, 'ROOSTER', 0, block.timestamp);
      }
    }
  }

  /** READ ONLY */

  /**
   * @notice Get stake info for a token
   * @param tokenId the ID of the token to check
   * @return Stake struct info
   */
  function getStakeInfo(uint16 tokenId) external view returns (Stake memory) {
    IFarmAnimals.Kind kind = _getKind(tokenId);
    if (kind == IFarmAnimals.Kind.HEN) {
      return henHouse[tokenId];
    } else if (kind == IFarmAnimals.Kind.COYOTE) {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      return den[rank][denIndices[tokenId]];
    } else {
      uint8 rank = _rankForCoyoteRooster(tokenId);
      return guardHouse[rank][guardHouseIndices[tokenId]];
    }
  }

  /**
   * @notice Return staked nfts token id list
   * @param account the address of the staker
   */

  function getStakedByAddress(address account) external view returns (uint256[] memory) {
    return stakedNFTs[account];
  }

  /**
   * @notice Chooses a random Coyote thief when a newly minted token is stolen
   * @param seed a random value to choose a Coyote from
   * @return the owner address of the randomly selected Coyote thief
   */
  function randomCoyoteOwner(uint256 seed) external view override returns (address) {
    if (totalCoyoteRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalCoyoteRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Coyotes with the same rank score
    for (uint256 i = MAX_RANK - 5; i <= MAX_RANK; i++) {
      cumulative += den[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the address of a random Coyote with that rank score
      return den[i][seed % den[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * @notice Chooses a random Rooster rescuer when claim $EGG token of coyote is dropped
   * @param seed a random value to choose a Rooster from
   * @return the owner address of the randomly selected Rooster rescuer
   */

  function randomRoosterOwner(uint256 seed) external view returns (address) {
    if (totalRoosterRankStaked == 0) {
      return address(0x0);
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRoosterRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Roosters with the same rank score
    for (uint256 i = MAX_RANK - 5; i <= MAX_RANK; i++) {
      cumulative += guardHouse[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the token id of a random Rooster with that rank score
      return guardHouse[i][seed % guardHouse[i].length].owner;
    }
    return address(0x0);
  }

  /**
   * @notice Chooses a random Rooster rescuer when claim $EGG token of coyote is dropped
   * @param seed a random value to choose a Rooster from
   * @return the token id of the randomly selected Rooster rescuer
   */

  function randomRoosterTokenId(uint256 seed) internal view returns (uint16) {
    if (totalRoosterRankStaked == 0) {
      return 0;
    }
    uint256 bucket = (seed & 0xFFFFFFFF) % totalRoosterRankStaked; // choose a value from 0 to total rank staked
    uint256 cumulative;
    seed >>= 32;
    // loop through each bucket of Roosters with the same rank score
    for (uint256 i = MAX_RANK - 5; i <= MAX_RANK; i++) {
      cumulative += guardHouse[i].length * i;
      // if the value is not inside of that bucket, keep going
      if (bucket >= cumulative) continue;
      // get the token id of a random Rooster with that rank score
      return guardHouse[i][seed % guardHouse[i].length].tokenId;
    }
    return 0;
  }

  function onERC721Received(
    address,
    address from,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    require(from == address(0x0), 'Cannot send directly');
    return IERC721Receiver.onERC721Received.selector;
  }

  /**
   *   ██████  ██     ██ ███    ██ ███████ ██████
   *  ██    ██ ██     ██ ████   ██ ██      ██   ██
   *  ██    ██ ██  █  ██ ██ ██  ██ █████   ██████
   *  ██    ██ ██ ███ ██ ██  ██ ██ ██      ██   ██
   *   ██████   ███ ███  ██   ████ ███████ ██   ██
   * This section will have all the internals set to onlyOwner
   */

  /**
   * @notice Allows owner to enable "rescue mode"
   * @dev Simplifies accounting, prioritizes tokens out in emergency
   */
  function setRescueEnabled(bool _enabled) external onlyOwner {
    rescueEnabled = _enabled;
  }

  /**
   *  ██████  ██████  ███    ██ ████████ ██████   ██████  ██      ██      ███████ ██████
   * ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   * ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      ██      █████   ██████
   * ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      ██      ██      ██   ██
   *  ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ ███████ ███████ ██   ██
   * This section if for controllers (possibly Owner) only functions
   */

  /**
   * @notice Get info for Hen House data
   * @return Hen House staking info
   */
  function getHenHouseInfo() external view onlyController returns (HenHouseInfo memory) {
    HenHouseInfo memory henHouseInfo = HenHouseInfo({
      numHensStaked: numHensStaked,
      totalEGGEarnedByHen: totalEGGEarnedByHen,
      lastClaimTimestampByHen: lastClaimTimestampByHen
    });
    return henHouseInfo;
  }

  /**
   * @notice Get info for Den data
   * @return Den staking info
   */
  function getDenInfo() external view onlyController returns (DenInfo memory) {
    DenInfo memory denInfo = DenInfo({
      numCoyotesStaked: numCoyotesStaked,
      totalCoyoteRankStaked: totalCoyoteRankStaked,
      eggPerCoyoteRank: eggPerCoyoteRank
    });
    return denInfo;
  }

  /**
   * @notice Get info for Guard House data
   * @return Guard House staking info
   */
  function getGuardHouseInfo() external view onlyController returns (GuardHouseInfo memory) {
    GuardHouseInfo memory guardHouseInfo = GuardHouseInfo({
      numRoostersStaked: numRoostersStaked,
      totalRoosterRankStaked: totalRoosterRankStaked,
      totalEGGEarnedByRooster: totalEGGEarnedByRooster,
      lastClaimTimestampByRooster: lastClaimTimestampByRooster,
      eggPerRoosterRank: eggPerRoosterRank,
      rescueEggPerRank: rescueEggPerRank
    });
    return guardHouseInfo;
  }

  /**
   * @notice Add $EGG amount to rescuedPool
   * @dev Only callable by the controller.
   */

  function addRescuedEggPool(uint256 _amount) external onlyController _updateEarnings {
    rescuedEggPool += _amount;
  }

  /**
   * @notice Add $EGG amount to rescuedPool
   * @dev Only callable by the controller.
   */

  function addGenericEggPool(uint256 _amount) external onlyController _updateEarnings {
    genericEggPool += _amount;
  }

  /**
   * @notice Internal call to enable an address to call controller only functions
   * @param _address the address to enable
   */
  function _addController(address _address) internal {
    controllers[_address] = true;
  }

  /**
   * @notice enables multiple addresses to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _addresses array of the address to enable
   */
  function addManyControllers(address[] memory _addresses) external onlyController {
    for (uint256 i = 0; i < _addresses.length; i++) {
      _addController(_addresses[i]);
    }
  }

  /**
   * @notice removes an address from controller list and ability to call controller only functions
   * @dev Only callable by the owner or existing controller
   * @param _address the address to disable
   */
  function removeController(address _address) external onlyController {
    controllers[_address] = false;
  }

  /**
   * @notice Enables owner to pause / unpause contract
   */
  function setPaused(bool _paused) external requireContractsSet onlyController {
    if (_paused) _pause();
    else _unpause();
  }

  /**
   * @notice Set the henHouseAdvantage contract address.
   * @dev Only callable by the owner.
   */
  function setHenHouseAdvantage(address _henHouseAdvantage) external onlyController {
    henHouseAdvantage = IHenHouseAdvantage(_henHouseAdvantage);
  }

  /**
   * @notice Set the theFarmGameMint contract address.
   * @dev Only callable by the owner.
   */
  function setTheFarmGameMint(address _theFarmGameMint) external onlyController {
    theFarmGameMint = ITheFarmGameMint(_theFarmGameMint);
  }

  /**
   * @notice Set new golden egg type id of EggShop.
   * @dev Only callable by the controller.
   */

  function setGoldenEggId(uint256 typeId) external onlyController {
    goldenEggTypeId = typeId;
  }

  /**
   * @notice Set drop rate to calculate dropped amount when coyote drop
   * @dev Only callable by the controller.
   */

  function setCoyoteDropRate(uint256 _dropCoyoteRate) external onlyController {
    dropCoyoteRate = _dropCoyoteRate;
  }

  /**
   * @notice Set coyote tax percent of the rooster's claimed $EGG by rate when unstake
   * @dev Only callable by the controller.
   */

  function setRoosterClaimTaxPercent(uint256 _taxPercent) external onlyController {
    ROOSTER_MUG_RATE = _taxPercent;
  }

  /**
   * @notice Set new rate to separate the amount of tokens coming from EggToken Contract for GenericEggPool
   * @dev Only callable by the controller.
   */

  function setGenericEggPoolRate(uint256 _rate) external onlyController {
    genericEggPoolRate = _rate;
  }

  /**
   * @notice Set new rate to separate the amount of tokens coming from EggToken Contract for RescuedEggPool
   * @dev Only callable by the controller.
   */

  function setRescuedEggPoolRate(uint256 _rate) external onlyController {
    rescuedEggPoolRate = _rate;
  }

  /**
   * @notice Set new golden reward rate
   * @dev Only callable by the controller.
   */

  function setGoldenRate(uint256 _rate) external onlyController {
    goldenRate = _rate;
  }

  /**
   * @notice Allows owner or conroller to send GenericPool egg to an address (to be used in future seasons)
   * @param to Address to send all GenericPool token
   */
  function sendGenericPool(address to) external onlyController nonReentrant {
    eggToken.mint(to, genericEggPool);
    genericEggPool = 0;
  }
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IEGGToken {
  function balanceOf(address account) external view returns (uint256);

  function mint(address to, uint256 amount) external;

  function burn(address from, uint256 amount) external;

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount)
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

pragma solidity ^0.8.17;

interface IEggShop is IERC1155 {
  struct TypeInfo {
    uint16 mints;
    uint16 burns;
    uint16 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
  }

  struct DetailedTypeInfo {
    uint16 mints;
    uint16 burns;
    uint16 maxSupply;
    uint256 eggMintAmt;
    uint256 eggBurnAmt;
    string name;
  }

  function mint(
    uint256 typeId,
    uint16 qty,
    address recipient,
    uint256 eggAmt
  ) external;

  function burn(
    uint256 typeId,
    uint16 qty,
    address burnFrom,
    uint256 eggAmt
  ) external;

  // function balanceOf(address account, uint256 id) external returns (uint256);

  function getInfoForType(uint256 typeId) external view returns (TypeInfo memory);

  function getInfoForTypeName(uint256 typeId) external view returns (DetailedTypeInfo memory);

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.13;

import 'erc721a/contracts/extensions/IERC721AQueryable.sol';

interface IFarmAnimals is IERC721AQueryable {
  // Kind of Character
  enum Kind {
    HEN,
    COYOTE,
    ROOSTER
  }

  // NFT Traits
  struct Traits {
    Kind kind;
    uint8 advantage;
    uint8[8] traits;
  }

  function burn(uint16 tokenId) external;

  function maxGen0Supply() external view returns (uint16);

  function maxSupply() external view returns (uint256);

  function getTokenTraits(uint16 tokenId) external view returns (Traits memory);

  function getTokenWriteBlock(uint256 tokenId) external view returns (uint64);

  function mint(address recipient, uint256 seed) external returns (uint16[] memory);

  function minted() external view returns (uint16);

  function mintedRoosters() external returns (uint16);

  function specialMint(
    address recipient,
    uint256 seed,
    uint16 specificKind,
    bool twinHen,
    uint16 quantity
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function updateAdvantage(
    uint16 tokenId,
    uint8 score,
    bool decrement
  ) external;

  function updateOriginAccess(uint16[] memory tokenIds) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouse {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  struct HenHouseInfo {
    uint256 numHensStaked; // Track staked hens
    uint256 totalEGGEarnedByHen; // Amount of $EGG earned so far
    uint256 lastClaimTimestampByHen; // The last time $EGG was claimed
  }

  struct DenInfo {
    uint256 numCoyotesStaked;
    uint256 totalCoyoteRankStaked;
    uint256 eggPerCoyoteRank; // Amount of tax $EGG due per Wily rank point staked
  }

  struct GuardHouseInfo {
    uint256 numRoostersStaked;
    uint256 totalRoosterRankStaked;
    uint256 totalEGGEarnedByRooster;
    uint256 lastClaimTimestampByRooster;
    uint256 eggPerRoosterRank; // Amount of dialy $EGG due per Guard rank point staked
    uint256 rescueEggPerRank; // Amunt of rescued $EGG due per Guard rank staked
  }

  function addManyToHenHouse(address account, uint16[] calldata tokenIds) external;

  function addGenericEggPool(uint256 _amount) external;

  function addRescuedEggPool(uint256 _amount) external;

  function canUnstake(uint16 tokenId) external view returns (bool);

  function claimManyFromHenHouseAndDen(uint16[] calldata tokenIds, bool unstake) external;

  function getDenInfo() external view returns (DenInfo memory);

  function getGuardHouseInfo() external view returns (GuardHouseInfo memory);

  function getHenHouseInfo() external view returns (HenHouseInfo memory);

  function getStakeInfo(uint16 tokenId) external view returns (Stake memory);

  function randomCoyoteOwner(uint256 seed) external view returns (address);

  function randomRoosterOwner(uint256 seed) external view returns (address);

  function rescue(uint16[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IHenHouseAdvantage {
  // struct to store the production bonus info of all nfts
  struct AdvantageBonus {
    uint256 tokenId;
    uint256 bonusPercentage;
    uint256 bonusDurationMins;
    uint256 startTime;
  }

  function addAdvantageBonus(
    uint16 tokenId,
    uint256 _durationMins,
    uint16 _percentage
  ) external;

  function removeAdvantageBonus(uint16 tokenId) external;

  function getAdvantageBonus(uint16 tokenId) external view returns (AdvantageBonus memory);

  function updateAdvantageBonus(uint256 tokenId) external;

  function calculateAdvantageBonus(uint256 tokenId, uint256 owed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

import './IHenHouse.sol';

pragma solidity ^0.8.17;

interface IHenHouseCalc {
  // struct to store a stake's token, owner, and earning values
  struct Stake {
    uint16 tokenId;
    address owner;
    uint80 eggPerRank; // This is the value of EggPerRank (Coyote/Rooster)
    uint80 rescueEggPerRank; // Value per rank of rescued $EGG
    uint256 oneOffEgg; // One off per staker
    uint256 stakedTimestamp;
    uint256 unstakeTimestamp;
  }

  function calculateRewards(uint16 tokenId) external view returns (uint256 owed);

  function calculateAllRewards(uint16[] calldata tokenIds) external view returns (uint256 owed);

  function calculateRewardsHen(uint16 tokenId, IHenHouse.Stake memory stake) external returns (uint256 owed);

  function calculateRewardsCoyote(uint16 tokenId, uint8 rank) external returns (uint256 owed);

  function calculateRewardsRooster(
    uint16 tokenId,
    uint8 rank,
    IHenHouse.Stake memory stake
  ) external returns (uint256 owed);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface IRandomizer {
  function random() external view returns (uint256);

  function randomToken(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

interface ITheFarmGameMint {
  function addCommitRandom(uint256 seed) external;

  function canMint() external view returns (bool);

  function getSaleStatus() external view returns (string memory);

  function mint(uint256 quantity, bool stake) external payable;

  function mintCommit(uint256 quantity, bool stake) external;

  function mintCostEGG(uint256 tokenId) external view returns (uint256);

  function mintReveal() external;

  function paused() external view returns (bool);

  function preSaleMint(
    uint256 quantity,
    bool stake,
    bytes32[] memory merkleProof,
    uint256 maxQuantity,
    uint256 priceInWei
  ) external payable;

  function preSaleTokens() external view returns (uint256);

  function preSalePrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
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
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

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
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    ) external;

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
    function approve(address to, uint256 tokenId) external;

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

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}