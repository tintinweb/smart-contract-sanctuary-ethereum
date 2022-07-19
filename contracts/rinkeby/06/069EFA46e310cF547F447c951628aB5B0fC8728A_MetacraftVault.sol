// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMetacraftSeasonPass {
    struct Summary {
        uint256 score;
        string creature;
        uint256 index;
    }

    function tokenSummary(uint256 tokenID)
        external
        view
        returns (Summary memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMetacraftSkinCollection {
    function creator() external view returns (address);

    function signer() external view returns (address);

    function previewType() external view returns (uint8);

    function vault() external view returns (address);

    // function mintFee(uint256 tokenID) external view returns (uint256);

    function mintRate() external view returns (uint256);

    function royaltyInfo(uint256 tokenID, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

    function totalSupply() external view returns (uint256);

    function supply() external view returns (uint256);

    function official() external view returns (bool);

    function factory() external view returns (address);

    // 0 原创 1 致敬1个系列  2 致敬多个系列
    function underlyingType() external view returns (uint8);

    function underlyingCollection() external view returns (address);

    // 致敬IP
    function underlyingTokenID(uint256 tokenID) external view returns (uint256);

    function creature(uint256 tokenID) external view returns (bytes32);

    function mint(
        uint256 tokenID,
        address to,
        uint256 mintFee,
        uint256 underlyingTokenID,
        bytes32 creature,
        bytes calldata _sign
    ) external payable;
}

pragma solidity >=0.8.0;

interface IMetacraftSkinCollectionFactory {
    function underlyingCollectionAmount(address)
        external
        view
        returns (uint256);

    event FactoryAdminChanged(address previousAdmin, address newAdmin);
    event SkinCreated(
        address skinAddress,
        string name,
        string symbol,
        uint256 totalSupply,
        uint8 previewType,
        uint8 _underlyingType,
        address _underlyingCollection
    );
    event AddSkinWhiteList(address skin);
    event RemoveSkinWhiteList(address skin);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMetacraftVault {
    event ValutAdminChanged(address oldAdmin, address newAdmin);
    event MintFeeCollected(address collection, uint256 tokenID, uint256 fee);
    event RoyaltyFeeArchived(address collection, uint256 fee);

    function collectMintFee(
        address collection,
        uint256 tokenID,
        bytes32 creature
    ) external payable;

    function archiveRoyaltyFee(address collection, uint256 amount) external;

    function claimCreatorFee() external;

    function creatorEarning(address creator) external view returns (uint256);

    function platformEarning() external view returns (uint256);

    function seasonPassHolderEarning(uint256 holdID)
        external
        view
        returns (uint256);

    function seasonPassCreatureEarning(uint256 holdID)
        external
        view
        returns (uint256);

    function underlyingHolderEarning(address collection, uint256 holdID)
        external
        view
        returns (uint256);

    function underlyingCollectionEarning(address collection, uint256 holdID)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

import "./IMetacraftVault.sol";
import "./IMetacraftSeasonPass.sol";
import "./IMetacraftSkinCollection.sol";
import "./IMetacraftSkinCollectionFactory.sol";
import "./utils/TransferHelper.sol";

contract MetacraftVault is IMetacraftVault {
    // keccak-256 hash of "metacraft.workshop.vault.admin"
    bytes32 internal constant _VAULT_ADMIN_SLOT =
        0xdafd13ae9c6d3de0c692f92d1f79c846a60edee17c6c8e28835ca211869d5c26;

    using SafeMath for uint256;

    address public factory;

    address public constant seasonPassAddress =
        0x0b1d6565d88F9Bf6473e21c2AB58D28A495d7BB5;
    uint16 public constant seasonPassAmout = 10000;
    // mint fee ratio, base 10000
    uint16 platformRatio = 2000;
    uint16 seasonPassHolderRatio = 2000;
    uint16 seasonPassCreatureRatio = 2000;
    uint16 underlyingCollectionRatio = 2000;
    uint16 underlyingHolderRatio = 2000;

    // royalty fee ratio, base 9000
    uint16 platformRoyaltyRatio = 3000;
    uint16 seasonPassRoyaltyRatio = 3000;
    uint16 creatorRoyaltyRatio = 3000;

    uint256 public royaltyFee;
    uint256 public platformFee;
    mapping(address => uint256) creatorFee;
    uint256 seasonPassHolderFee;
    mapping(uint256 => uint256) seasonPassHolderFeeIndex;

    mapping(address => uint256) underlyingCollectionFee;
    mapping(address => uint256) underlyingCollectionRemainFee;
    mapping(address => mapping(uint256 => uint256)) underlyingCollectionFeeIndex;

    mapping(address => mapping(uint256 => uint256)) underlyingHolderFee;

    mapping(bytes32 => uint256) creatureAmount;
    mapping(bytes32 => uint256) creatureFee;
    mapping(bytes32 => mapping(uint256 => uint256)) creatureFeeIndex;

    constructor(address _factory) {
        factory = _factory;
        creatureAmount[keccak256("cow")] = 100;
    }

    function collectMintFee(
        address collection,
        uint256 tokenID,
        bytes32 creature
    ) external payable {
        require(msg.value > 0, "mint fee must be greater than 0");
        uint256 amount = msg.value;
        platformFee = amount.mul(platformRatio).div(10000).add(platformFee);
        seasonPassHolderFee = amount
            .mul(seasonPassHolderRatio)
            .div(10000)
            .div(seasonPassAmout)
            .add(seasonPassHolderFee);
        creatureFee[creature] = amount
            .mul(seasonPassCreatureRatio)
            .div(10000)
            .div(creatureAmount[creature])
            .add(creatureFee[creature]);

        address underlyingCollection = IMetacraftSkinCollection(collection)
            .underlyingCollection();
        if (underlyingCollection != address(0)) {
            underlyingHolderFee[underlyingCollection][tokenID] = amount
                .mul(underlyingHolderRatio)
                .div(10000)
                .add(underlyingHolderFee[underlyingCollection][tokenID]);

            uint256 collectionAmount = IMetacraftSkinCollectionFactory(factory)
                .underlyingCollectionAmount(underlyingCollection);
            underlyingCollectionFee[underlyingCollection] = amount
                .mul(underlyingCollectionRatio)
                .div(10000)
                .div(collectionAmount)
                .add(underlyingCollectionFee[underlyingCollection]);
            underlyingCollectionRemainFee[underlyingCollection] = amount
                .mul(underlyingCollectionRatio)
                .div(10000)
                .add(underlyingCollectionRemainFee[underlyingCollection]);
        }

        emit MintFeeCollected(collection, tokenID, amount);
    }

    function archiveRoyaltyFee(address collection, uint256 amount)
        external
        onlyVaultAdmin
    {
        platformFee = amount.mul(platformRoyaltyRatio).div(9000).add(
            platformFee
        );
        seasonPassHolderFee = amount
            .mul(seasonPassRoyaltyRatio)
            .div(9000)
            .div(seasonPassAmout)
            .add(seasonPassHolderFee);
        address creator = IMetacraftSkinCollection(collection).creator();
        creatorFee[creator] = amount.mul(creatorRoyaltyRatio).div(9000).add(
            creatorFee[creator]
        );
        emit RoyaltyFeeArchived(collection, amount);
    }

    function creatorEarning(address creator) public view returns (uint256) {
        return creatorFee[creator];
    }

    function platformEarning() public view returns (uint256) {
        return platformFee;
    }

    function seasonPassHolderEarning(uint256 holdID)
        public
        view
        returns (uint256)
    {
        if (holdID > seasonPassAmout) {
            return 0;
        }
        return seasonPassHolderFee.sub(seasonPassHolderFeeIndex[holdID]);
    }

    function seasonPassCreatureEarning(uint256 holdID)
        public
        view
        returns (uint256)
    {
        if (holdID > seasonPassAmout) {
            return 0;
        }
        bytes32 creature = keccak256(
            bytes(
                IMetacraftSeasonPass(seasonPassAddress)
                    .tokenSummary(holdID)
                    .creature
            )
        );
        return creatureFee[creature].sub(creatureFeeIndex[creature][holdID]);
    }

    function underlyingCollectionEarning(address collection, uint256 holdID)
        public
        view
        returns (uint256)
    {
        if (IERC721(collection).ownerOf(holdID) == address(0)) {
            return 0;
        }
        if (underlyingCollectionRemainFee[collection] <= 0) {
            return 0;
        }
        uint256 amount = underlyingCollectionFee[collection].sub(
            underlyingCollectionFeeIndex[collection][holdID]
        );
        return Math.min(amount, underlyingCollectionRemainFee[collection]);
    }

    function underlyingHolderEarning(address collection, uint256 holdID)
        public
        view
        returns (uint256)
    {
        if (IERC721(collection).ownerOf(holdID) == address(0)) {
            return 0;
        }
        return underlyingHolderFee[collection][holdID];
    }

    function claimCreatorFee() external {
        uint256 amount = creatorEarning(msg.sender);
        require(amount > 0, "no creator fee to claim");
        creatorFee[msg.sender] = 0;
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function claimPlatformFee(address to) external {
        uint256 amount = platformEarning();
        require(amount > 0, "no platform fee to claim");
        platformFee = 0;
        TransferHelper.safeTransferETH(to, amount);
    }

    function claimseasonPassHolderFee(uint256 holdID) external {
        uint256 amount = seasonPassHolderEarning(holdID);
        require(amount > 0, "no season pass holder fee to claim");
        require(
            IERC721(seasonPassAddress).ownerOf(holdID) == msg.sender,
            "you are not the season pass holder"
        );
        seasonPassHolderFeeIndex[holdID] = seasonPassHolderFeeIndex[holdID].add(
            amount
        );
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function claimSeasonPassCreatureFee(uint256 holdID) external {
        uint256 amount = seasonPassCreatureEarning(holdID);
        require(amount > 0, "no season pass creature fee to claim");
        require(
            IERC721(seasonPassAddress).ownerOf(holdID) == msg.sender,
            "you are not the season pass holder"
        );
        bytes32 creature = keccak256(
            bytes(
                IMetacraftSeasonPass(seasonPassAddress)
                    .tokenSummary(holdID)
                    .creature
            )
        );
        creatureFeeIndex[creature][holdID] = creatureFeeIndex[creature][holdID]
            .add(amount);
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function claimunderlyingCollectionFee(address collection, uint256 holdID)
        external
    {
        uint256 amount = underlyingCollectionEarning(collection, holdID);
        require(amount > 0, "no underlying collection fee to claim");
        require(
            IERC721(collection).ownerOf(holdID) == msg.sender,
            "you are not the nft holder"
        );
        underlyingCollectionFeeIndex[collection][
            holdID
        ] = underlyingCollectionFeeIndex[collection][holdID].add(amount);
        underlyingCollectionRemainFee[
            collection
        ] = underlyingCollectionRemainFee[collection].sub(amount);
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function claimUnderlyingHolderFee(address collection, uint256 holdID)
        external
    {
        uint256 amount = underlyingHolderEarning(collection, holdID);
        require(amount > 0, "no underlying holder fee to claim");
        require(
            IERC721(collection).ownerOf(holdID) == msg.sender,
            "you are not the nft holder"
        );
        underlyingHolderFee[collection][holdID] = 0;
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function emergencyWithdraw(address to, uint256 amount) external {
        TransferHelper.safeTransferETH(to, amount);
    }

    function vaultAdmin() public view returns (address) {
        return StorageSlot.getAddressSlot(_VAULT_ADMIN_SLOT).value;
    }

    function changeVaultAdmin(address newAdmin) public onlyVaultAdmin {
        require(
            newAdmin != address(0),
            "vault : new admin is the zero address"
        );
        StorageSlot.getAddressSlot(_VAULT_ADMIN_SLOT).value = newAdmin;
        emit ValutAdminChanged(msg.sender, newAdmin);
    }

    modifier onlyVaultAdmin() {
        require(vaultAdmin() == msg.sender, "factory: caller is not the admin");
        _;
    }

    receive() external payable {
        royaltyFee = royaltyFee.add(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library TransferHelper {
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}