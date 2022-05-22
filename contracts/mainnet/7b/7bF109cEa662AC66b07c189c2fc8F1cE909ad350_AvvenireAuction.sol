// SPDX-License-Identifier: MIT

/**
 *@title Avvenire ERC721 Contract
 */
pragma solidity ^0.8.4;

import "AvvenireCitizensInterface.sol";
import "Ownable.sol";
import "Strings.sol";
import "ReentrancyGuard.sol";

contract AvvenireAuction is Ownable, ReentrancyGuard {
    // mint information
    uint256 public maxPerAddressDuringWhiteList;

    uint256 public amountForTeam; // Amount of NFTs for team
    uint256 public amountForAuctionAndTeam; // Amount of NFTs for the team and auction
    uint256 public collectionSize; // Total collection size

    // AvvenireCitizensERC721 contract
    AvvenireCitizensInterface avvenireCitizens;

    struct SaleConfig {
        uint32 auctionSaleStartTime; 
        uint32 publicSaleStartTime; 
        uint64 mintlistPrice; 
        uint64 publicPrice; 
        uint32 publicSaleKey; 
    }

    SaleConfig public saleConfig; 

    // whitelist mapping (address => amount they can mint)
    mapping(address => uint256) public allowlist;

    // Mappings used to calculate the amount to refund a user from the dutch auctin
    mapping(address => uint256) public totalPaidDuringAuction;
    mapping(address => uint256) public numberMintedDuringAuction;

    /**
     * @notice Constructor calls on ERC721A constructor and sets the previously defined global variables
     * @param maxPerAddressDuringWhiteList_ the number for the max batch size and max # of NFTs per address during the whiteList
     * @param collectionSize_ the number of NFTs in the collection
     * @param amountForTeam_ the number of NFTs for the team
     * @param amountForAuctionAndTeam_ specifies total amount to auction + the total amount for the team
     * @param avvenireCitizensContractAddress_ address for AvvenireCitizensERC721 contract 
     */
    constructor(
        uint256 maxPerAddressDuringWhiteList_,
        uint256 collectionSize_,
        uint256 amountForAuctionAndTeam_,
        uint256 amountForTeam_,
        address avvenireCitizensContractAddress_
    ) {
        maxPerAddressDuringWhiteList = maxPerAddressDuringWhiteList_;

        amountForAuctionAndTeam = amountForAuctionAndTeam_;
        amountForTeam = amountForTeam_;
        collectionSize = collectionSize_;

        // set avvenire citizens address
        avvenireCitizens = AvvenireCitizensInterface(
            avvenireCitizensContractAddress_
        );

        require(
            amountForAuctionAndTeam_ <= collectionSize_, 
            "larger collection size needed"
        );
    }

    /**
      Modifier to make sure that the caller is a user and not another contract
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract."); 
        _;
    }

    /**
     * @notice function used to mint during the auction
     * @param quantity is the quantity to mint
     */
    function auctionMint(uint256 quantity) external payable callerIsUser {
        uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);

        // Require that the current time is past the designated start time 
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );

        // Require that quantity does not exceed designated amount 
        require(
            avvenireCitizens.getTotalSupply() + quantity <=
                amountForAuctionAndTeam,
            "not enough remaining reserved for auction to support desired mint amount"
        );

        uint256 totalCost = getAuctionPrice() * quantity; // total amount of ETH needed for the transaction
        avvenireCitizens.safeMint(msg.sender, quantity); 

        //Add to numberMinted mapping 
        numberMintedDuringAuction[msg.sender] =
            numberMintedDuringAuction[msg.sender] +
            quantity;

        //Add to totalPaid mapping
        totalPaidDuringAuction[msg.sender] =
            totalPaidDuringAuction[msg.sender] +
            totalCost;

        refundIfOver(totalCost); // make sure to refund the excess

    }

    /**
     * @notice function to mint for allow list
     * @param quantity amount to mint for whitelisted users
     */
    function whiteListMint(uint256 quantity) external payable callerIsUser {
        // Sets the price var to the mintlistPrice, which was set by endAuctionAndSetupNonAuctionSaleInfo(...)
        // mintlistPrice will be set to 30% below the publicSalePrice
        uint256 price = uint256(saleConfig.mintlistPrice);

        require(price != 0, "Allowlist sale has not begun yet");

        require(allowlist[msg.sender] > 0, "not eligible for allowlist mint"); 

        require(
            avvenireCitizens.getTotalSupply() + quantity <= collectionSize,
            "Reached max supply"
        );
        require(quantity <= allowlist[msg.sender], "Can not mint this many");

        allowlist[msg.sender] = allowlist[msg.sender] - quantity;

        avvenireCitizens.safeMint(msg.sender, quantity);

        uint256 totalCost = quantity * price;

        refundIfOver(totalCost);
    }

    /**
     * @notice mint function for the public sale
     * @param quantity quantity to mint
     * @param callerPublicSaleKey the key for the public sale
     */
    function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
        external
        payable
        callerIsUser
    {
        SaleConfig memory config = saleConfig; 

        uint256 publicSaleKey = uint256(config.publicSaleKey); // log the key
        uint256 publicPrice = uint256(config.publicPrice); // get the price 
        uint256 publicSaleStartTime = uint256(config.publicSaleStartTime); 

        require(
            publicSaleKey == callerPublicSaleKey,
            "called with incorrect public sale key"
        );

        require(
            isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime),
            "public sale has not begun yet"
        );
        require(
            avvenireCitizens.getTotalSupply() + quantity <= collectionSize,
            "reached max supply"
        );

        avvenireCitizens.safeMint(msg.sender, quantity);

        uint256 totalCost = publicPrice * quantity;
        refundIfOver(totalCost);
    }

    /**
     * @notice private function that refunds a user if msg.value > totalCost
     * @param price current price
     */
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH"); 

        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @notice function that user can call to be refunded
     */
    function refundMe() external callerIsUser nonReentrant {
        uint256 endingPrice = saleConfig.publicPrice;
        require(endingPrice > 0, "public price not set yet");

        uint256 actualCost = endingPrice *
            numberMintedDuringAuction[msg.sender];

        int256 reimbursement = int256(totalPaidDuringAuction[msg.sender]) -
            int256(actualCost);

        require(reimbursement > 0, "You are not eligible for a refund");

        totalPaidDuringAuction[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: uint256(reimbursement)}("");
        require(success, "Refund failed");
    }

    /**
     * @notice function to refund user on the price they paid
     * @param toRefund the address to refund
     */
    function refund(address toRefund) external onlyOwner nonReentrant {
        uint256 endingPrice = saleConfig.publicPrice;
        require(endingPrice > 0, "public price not set yet");

        uint256 actualCost = endingPrice * numberMintedDuringAuction[toRefund];

        int256 reimbursement = int256(totalPaidDuringAuction[toRefund]) -
            int256(actualCost);
        require(reimbursement > 0, "Not eligible for a refund");

        totalPaidDuringAuction[toRefund] = 0;

        (bool success, ) = toRefund.call{value: uint256(reimbursement)}("");
        require(success, "Refund failed");
    }

    /**
     * @notice function that returns a boolean indicating whtether the public sale is enabled
     * @param publicPriceWei must sell for more than 0
     * @param publicSaleKey must have a key that is non-zero
     * @param publicSaleStartTime  must be past the public start time
     */
    function isPublicSaleOn(
        // check if the public sale is on
        uint256 publicPriceWei,
        uint256 publicSaleKey,
        uint256 publicSaleStartTime
    ) public view returns (bool) {
        return
            publicPriceWei != 0 && 
            publicSaleKey != 0 && 
            block.timestamp >= publicSaleStartTime; 
    }

    uint256 public constant AUCTION_START_PRICE = .3 ether; // start price
    uint256 public constant AUCTION_END_PRICE = 0.1 ether; // floor price
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 80 minutes; // total time of the auction
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;

    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
            (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL); // how much the auction price will drop the price per unit of time

    /**
     * @notice Returns the current auction price. Uses block.timestamp to properly calculate price
     */
    function getAuctionPrice() public view returns (uint256) {
        uint256 _saleStartTime = uint256(saleConfig.auctionSaleStartTime);
        require(_saleStartTime != 0, "auction has not started");
        if (block.timestamp < _saleStartTime) {
            return AUCTION_START_PRICE; // if the timestamp is less than the start of the sale, no discount
        }
        if (block.timestamp - _saleStartTime >= AUCTION_PRICE_CURVE_LENGTH) {
            return AUCTION_END_PRICE; // lower limit of the auction
        } else {
            uint256 steps = (block.timestamp - _saleStartTime) /
                AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP); // calculate the price based on how far away from the start we are
        }
    }

    /**
     * @notice function to set up the saleConfig variable; sets auctionSaleStartTime to 0
     * @param mintlistPriceWei the mintlist price in wei
     * @param publicPriceWei the public sale price in wei
     * @param publicSaleStartTime the start time of the sale
     */
    function endAuctionAndSetupNonAuctionSaleInfo(
        uint64 mintlistPriceWei,
        uint64 publicPriceWei,
        uint32 publicSaleStartTime
    ) external onlyOwner {
        saleConfig = SaleConfig(
            0,
            publicSaleStartTime,
            mintlistPriceWei,
            publicPriceWei,
            saleConfig.publicSaleKey
        );
    }

    /**
     * @notice Sets the auction's starting time
     * @param timestamp the starting time
     */
    function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
        // set the start time
        saleConfig.auctionSaleStartTime = timestamp;
    }

    /**
     * @notice sets the public sale key
     */
    function setPublicSaleKey(uint32 key) external onlyOwner {
        // set the special key (not viewable to the public)
        saleConfig.publicSaleKey = key;
    }

    /**
     * @notice sets the whitelist w/ the respective amount of number of NFTs that each address can mint
     * Requires that the addresses[] and numSlots[] are the same length
     * @param addresses the whitelist addresses
     */
    function seedWhitelist(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = maxPerAddressDuringWhiteList;
        }
    }

    /**
     * @notice Removes a user from the whitelist
     * @param toRemove the public address of the user
     */
    function removeFromWhitelist(address toRemove) external onlyOwner {
        require(allowlist[toRemove] > 0, "allowlist at 0 already");
        allowlist[toRemove] = 0;
    }

    /**
     * @notice function to mint for the team
     */
    function teamMint(uint256 quantity) external onlyOwner {
        require(avvenireCitizens.getTotalSupply() + quantity <= amountForTeam, "NFTs already minted");
        avvenireCitizens.safeMint(msg.sender, quantity);  
    }

    /**
     * @notice function to withdraw the money from the contract. Only callable by the owner
     */
    function withdrawQuantity(uint256 toWithdraw) external onlyOwner nonReentrant {
        require (toWithdraw <= address(this).balance, "quantity to withdraw > balance");

        (bool success, ) = msg.sender.call{value: toWithdraw}("");
        require(success, "withdraw failed.");
    }

    /**
     * @notice function to withdraw the money from the contract. Only callable by the owner
     */
    function withdrawAll() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "withdraw failed.");
    }

}

// SPDX-License-Identifier: MIT

/**
 * @title Avvenire Citizens Interface
 */
pragma solidity ^0.8.4;

import "AvvenireCitizenDataInterface.sol";
import "IERC721.sol";

interface AvvenireCitizensInterface is AvvenireCitizenDataInterface, IERC721 {

    // other functions
    function getTotalSupply() external returns (uint256);

    function requestChange(uint256) external payable;

    function setCitizenData(Citizen memory, bool) external;

    function bind(
        uint256,
        uint256,
        Sex,
        TraitType
    ) external;

    function safeMint(address, uint256) external;

    function numberMinted(address) external returns (uint256);

    function setOwnersExplicit(uint256) external;

    function burn(uint256) external;

    function numberBurned(address) external view returns (uint256);
}

interface AvvenireTraitsInterface is AvvenireCitizenDataInterface, IERC721 {
    function getTotalSupply() external returns (uint256);

    function setTraitData(Trait memory, bool) external;

    function safeMint(address, uint256) external;

    function numberMinted(address) external returns (uint256);

    function setOwnersExplicit(uint256) external;

    function burn(uint256) external;

    function numberBurned(address) external view returns (uint256);

    function makeTraitTransferable(uint256, bool) external;

    function makeTraitNonTransferrable(uint256) external;

    function isOwnerOf(uint256) external view returns (address); 

}

interface AvvenireCitizensMappingsInterface is AvvenireCitizenDataInterface {

    function getCitizen(uint256) external view returns (Citizen memory);

    function getTrait(uint256) external view returns (Trait memory);

    function setCitizen(Citizen memory) external;

    function setTrait(Trait memory) external;

    function setAllowedPermission(address, bool) external;

    function setTraitFreedom(uint256, bool) external;

    function isCitizenInitialized(uint256) external view returns (bool);

    function setCitizenChangeRequest(uint256, bool) external;

    function getCitizenChangeRequest(uint256) external view returns(bool);
 
    function setTraitChangeRequest (uint256, bool) external;

    function getTraitChangeRequest(uint256) external view returns(bool);

    // mutability config stuct
    struct MutabilityConfig {
        bool mutabilityMode; // initially set the contract to be immutable, this will keep people from trying to use the function before it is released
        // payment information
        uint256 mutabilityCost; // the amount that it costs to make a change (initializes to 0)
        // trading information
        bool tradeBeforeChange; // initially set to false, don't want people to tokens that are pending changes
    }

    function getMutabilityMode() external view returns (bool);

    function getTradeBeforeChange() external view returns (bool);

    function getChangeCost() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

/**
 * @title Avvenire Citizen Data Interface
*/
pragma solidity ^0.8.4;


interface AvvenireCitizenDataInterface {
    // traits are bound to sex for fitting
    enum Sex {NULL, MALE, FEMALE}

    // make an enumerable for trait types (meant to be overridden with traits from individual project)
    enum TraitType {
        NULL,
        BACKGROUND,
        BODY,
        TATTOO,
        EYES,
        MOUTH,
        MASK,
        NECKLACE,
        CLOTHING,
        EARRINGS,
        HAIR,
        EFFECT
    }

    // struct for storing trait data for the citizen (used ONLY in the citizen struct)
    struct Trait {
        uint256 tokenId; // for mapping traits to their tokens
        string uri;
        bool free; // stores if the trait is free from the citizen (defaults to false)
        bool exists; // checks existence (for minting vs transferring)
        Sex sex;
        TraitType traitType;
        uint256 originCitizenId; // for mapping traits to their previous citizen owners
    }

    // struct for storing all the traits
    struct Traits {
        Trait background;
        Trait body;
        Trait tattoo;
        Trait eyes;
        Trait mouth;
        Trait mask;
        Trait necklace;
        Trait clothing;
        Trait earrings;
        Trait hair;
        Trait effect;
    }


    // struct for storing citizens
    struct Citizen {
        uint256 tokenId;
        string uri;
        bool exists; //  checks existence (for minting vs transferring)
        Sex sex;
        Traits traits;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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