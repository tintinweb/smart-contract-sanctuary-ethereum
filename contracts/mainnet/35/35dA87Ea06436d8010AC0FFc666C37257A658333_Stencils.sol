// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { ERC721, ERC721Enumerable, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IStencils is IERC721Enumerable {

    enum BuyerType { Regular, Free, MinimumPrice }

    /// @notice Emitted when the hash of the asset generator is set.
    event AssetGeneratorHashSet(bytes32 indexed assetGeneratorHash);

    /// @notice Emitted when the base URI is set (or re-set).
    event BaseURISet(string baseURI);

    /// @notice Emitted when an account is set as a type of buyer.
    event BuyerSet(address indexed account, BuyerType indexed buyerType, uint128 promotionalQuantity);

    /// @notice Emitted when an account has accepted ownership.
    event OwnershipAccepted(address indexed previousOwner, address indexed owner);

    /// @notice Emitted when owner proposed an account that can accept ownership.
    event OwnershipProposed(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a token holder purchased a physical copy.
    event PhysicalCopyClaimed(uint256 indexed tokenId, address indexed recipient);

    /// @notice Emitted when the minting parameters have be set.
    event ParametersSet(uint256 startingPrice, uint256 auctionStages, uint256 physicalPrice, uint256 specialsTarget);

    /// @notice Emitted when proceeds have been withdrawn to proceeds destination.
    event ProceedsWithdrawn(address indexed destination, uint256 amount);

    /// @notice Emitted when an account is set as the destination where proceeds will be withdrawn to.
    event ProceedsDestinationSet(address indexed account);

    /*************/
    /*** State ***/
    /*************/

    function LAUNCH_TIMESTAMP() external view returns (uint256 launchTimestamp_);

    function AUCTION_END_TIMESTAMP() external view returns (uint256 auctionEndTimestamp_);

    function MAX_SUPPLY() external view returns (uint128 maxSupply_);

    function assetGeneratorHash() external view returns (bytes32 assetGeneratorHash_);

    function baseURI() external view returns (string memory baseURI_);

    function owner() external view returns (address owner_);

    function pendingOwner() external view returns (address pendingOwner_);

    function physicalPrice() external view returns (uint256 physicalPrice_);

    function auctionStages() external view returns (uint256 auctionStages_);

    function proceedsDestination() external view returns (address proceedsDestination_);

    function startingPricePerTokenMint() external view returns (uint256 startingPricePerTokenMint_);

    function specialCount() external view returns (uint128 specialCount_);

    function specialsTarget() external view returns (uint128 specialsTarget_);

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    function acceptOwnership() external;

    function proposeOwnership(address newOwner_) external;

    function setAssetGeneratorHash(bytes32 assetGeneratorHash_) external;

    function setBaseURI(string calldata baseURI_) external;

    function setBuyerInfos(address[] calldata accounts_, BuyerType[] calldata buyerTypes_, uint128[] calldata quantities_) external;

    function setReseeds(address[] calldata accounts_, uint8[] calldata counts_, uint32[7][] calldata seeds_) external;

    function setParameters(uint256 startingPricePerTokenMint_, uint256 priceStages_, uint256 physicalPrice_, uint128 specialsTarget_) external;

    function setProceedsDestination(address proceedsDestination_) external;

    function withdrawProceeds() external;

    /**************************/
    /*** External Functions ***/
    /**************************/

    function claim(address destination_, uint128 quantity_, uint128 minQuantity_) external payable returns (uint256[] memory tokenIds_);

    function give(address[] calldata destinations_, uint256[] calldata amounts_, bool[] calldata physicals_) external;

    function purchase(address destination_, uint128 quantity_, uint128 minQuantity_) external payable returns (uint256[] memory tokenIds_);

    function purchasePhysical(uint256 tokenId_) external payable;

    /***************/
    /*** Getters ***/
    /***************/

    function availableSupply() external view returns (uint256 availableSupply_);

    function buyerInfoFor(address account_) external view returns (BuyerType buyerType_, uint128 promotionalQuantity_);

    function reseedInfoFor(address account_) external view returns (uint8 count_, uint32[7] memory seeds_);

    function contractURI() external view returns (string memory contractURI_);

    function currentAuctionStage() external view returns (uint256 auctionStage_);

    function getPurchaseInformationFor(address buyer_) external view returns (
        bool canClaim_,
        uint256 claimableQuantity_,
        uint256 price_,
        bool physicalCopyIncluded_,
        bool specialIncluded_,
        uint256 auctionStage_,
        uint256 timeRemaining_
    );

    function isLive() external view returns (bool isLive_);

    function isPriceStatic() external view returns (bool priceIsStatic_);

    function physicalCopyRecipient(uint256 tokenId_) external view returns (address physicalCopyRecipient_);

    function pricePerTokenMint() external view returns (uint256 pricePerTokenMint_);

    function timeToLaunch() external view returns (uint256 timeToLaunch_);

    function tokensOfOwner(address owner_) external view returns (uint256[] memory tokenIds_);

}

contract Stencils is IStencils, ERC721Enumerable {

    struct BuyerInfo {
        BuyerType buyerType;
        uint128 quantity;
    }

    struct ReseedInfo {
        uint8 count;
        uint32[7] seeds;
    }

    using Strings for uint256;

    uint128 public immutable MAX_SUPPLY;
    uint256 public immutable LAUNCH_TIMESTAMP;
    uint256 public immutable AUCTION_END_TIMESTAMP;

    address public owner;
    address public pendingOwner;
    address public proceedsDestination;

    bytes32 public assetGeneratorHash;

    string public baseURI;

    uint256 public startingPricePerTokenMint;
    uint256 public auctionStages;
    uint256 public physicalPrice;

    uint128 public specialsTarget;
    uint128 public specialCount;

    mapping(uint256 => address) public physicalCopyRecipient;

    mapping(address => BuyerInfo) public buyerInfoFor;

    mapping(address => ReseedInfo) internal _reseedInfoFor;

    constructor (
        string memory baseURI_,
        uint128 maxSupply_,
        uint256 launchTimestamp_,
        uint256 auctionEndTimestamp_,
        uint256 startingPricePerTokenMint_,
        uint256 auctionStages_,
        uint256 physicalPrice_,
        uint128 specialsTarget_
    ) ERC721("Stencils", "STEN") {
        baseURI = baseURI_;
        MAX_SUPPLY = maxSupply_;
        LAUNCH_TIMESTAMP = launchTimestamp_;
        AUCTION_END_TIMESTAMP = auctionEndTimestamp_;
        startingPricePerTokenMint = startingPricePerTokenMint_;
        require((auctionStages = auctionStages_) > 0, "INVALID_STAGES");
        physicalPrice = physicalPrice_;
        specialsTarget = specialsTarget_;

        owner = msg.sender;
    }

    modifier onlyAfterLaunch() {
        require(block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        _;
    }

    modifier onlyBeforeLaunch() {
        require(block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "UNAUTHORIZED");
        _;
    }

    /***********************/
    /*** Admin Functions ***/
    /***********************/

    function acceptOwnership() external {
        require(pendingOwner == msg.sender, "UNAUTHORIZED");

        emit OwnershipAccepted(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    function proposeOwnership(address newOwner_) external onlyOwner {
        emit OwnershipProposed(owner, pendingOwner = newOwner_);
    }

    function setAssetGeneratorHash(bytes32 assetGeneratorHash_) external onlyOwner {
        require(assetGeneratorHash == bytes32(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit AssetGeneratorHashSet(assetGeneratorHash = assetGeneratorHash_);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        emit BaseURISet(baseURI = baseURI_);
    }

    function setBuyerInfos(address[] calldata accounts_, BuyerType[] calldata buyerTypes_, uint128[] calldata quantities_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            address account = accounts_[i];
            BuyerType buyerType = buyerTypes_[i];
            uint128 quantity = quantities_[i];

            buyerInfoFor[account] = BuyerInfo(buyerType, quantity);

            emit BuyerSet(account, buyerType, quantity);

            unchecked {
                ++i;
            }
        }
    }

    function setReseeds(address[] calldata accounts_, uint8[] calldata counts_, uint32[7][] calldata seeds_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < accounts_.length;) {
            uint8 count = counts_[i];
            uint32[7] calldata seeds = seeds_[i];

            for (uint256 j; j < 7;) {
                // The seed at a position should be zero if its position is the count or greater.
                // The seed at a position should be non-zero if its position is lower than the count.
                require((seeds[j] == uint32(0)) == (j >= count), "INVALID_COUNT");

                unchecked {
                    ++j;
                }
            }

            _reseedInfoFor[accounts_[i]] = ReseedInfo(count, seeds);

            unchecked {
                ++i;
            }
        }
    }

    function setParameters(
        uint256 startingPricePerTokenMint_,
        uint256 auctionStages_,
        uint256 physicalPrice_,
        uint128 specialsTarget_
    ) external onlyOwner onlyBeforeLaunch {
        require(auctionStages_ > 0, "INVALID_STAGES");

        emit ParametersSet(
            startingPricePerTokenMint = startingPricePerTokenMint_,
            auctionStages = auctionStages_,
            physicalPrice = physicalPrice_,
            specialsTarget = specialsTarget_
        );
    }

    function setProceedsDestination(address proceedsDestination_) external onlyOwner {
        require(proceedsDestination == address(0) || block.timestamp < LAUNCH_TIMESTAMP, "ALREADY_LAUNCHED");
        emit ProceedsDestinationSet(proceedsDestination = proceedsDestination_);
    }

    function withdrawProceeds() external {
        uint256 amount = address(this).balance;
        address destination = proceedsDestination;
        destination = destination == address(0) ? owner : destination;

        require(_transferEther(destination, amount), "ETHER_TRANSFER_FAILED");
        emit ProceedsWithdrawn(destination, amount);
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function claim(address destination_, uint128 quantity_, uint128 minQuantity_) external payable onlyAfterLaunch returns (uint256[] memory tokenIds_) {
        require(destination_ != address(0), "INVALID_DESTINATION");

        uint128 count = _getMintCount(quantity_, minQuantity_);

        // Compute the price this purchase will cost.
        BuyerInfo storage buyerInfo = buyerInfoFor[msg.sender];

        // Prevent a non-preferred buyer from claiming.
        require(buyerInfo.buyerType != BuyerType.Regular, "NOT_GRANTED");

        // Prevent a preferred buyer from claiming more than was alloted with this function.
        require(buyerInfo.quantity >= count, "NOT_GRANTED");

        // If the buyer type is MinimumPrice, then compute the total cost, else it is free. Regular buyers would have buyerInfo.quantity = 0;
        uint256 totalCost;
        unchecked {
            totalCost = buyerInfo.buyerType == BuyerType.MinimumPrice
                ? count * _pricePerTokenMint(auctionStages)
                : 0;
        }

        if (buyerInfo.quantity == count) {
            // Delete the buyer info if quantity exactly used.
            delete buyerInfoFor[msg.sender];
        } else {
            // Else, try to decrement, which will error if trying to claim more than alloted.
            buyerInfo.quantity -= count;
        }

        _checkAndRefundEther(totalCost);

        // Initialize the array of token IDs to a length of the nfts to be purchased.
        tokenIds_ = new uint256[](count);

        while (count > 0) {
            unchecked {
                // Get a pseudo random number and generate a token id to mint the molecule NFT.
                _givePhysical(
                    tokenIds_[--count] = _giveToken(destination_, false)
                );
            }
        }
    }

    function give(address[] calldata destinations_, uint256[] calldata amounts_, bool[] calldata physicals_) external onlyOwner onlyBeforeLaunch {
        for (uint256 i; i < destinations_.length;) {
            for (uint256 j; j < amounts_[i];) {
                uint256 tokenId = _giveToken(destinations_[i], false);

                if (physicals_[i]) {
                    _givePhysical(tokenId);
                }

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function purchase(address destination_, uint128 quantity_, uint128 minQuantity_) external payable onlyAfterLaunch returns (uint256[] memory tokenIds_) {
        require(destination_ != address(0), "INVALID_DESTINATION");

        uint128 count = _getMintCount(quantity_, minQuantity_);

        // Compute the price this purchase will cost.
        uint256 totalCost;
        unchecked {
            totalCost = pricePerTokenMint() * count;
        }

        _checkAndRefundEther(totalCost);

        uint256 auctionStage = currentAuctionStage();

        // Initialize the array of token IDs to a length of the nfts to be purchased.
        tokenIds_ = new uint256[](count);

        while (count > 0) {
            unchecked {
                // Get a pseudo random number and generate a token id to mint the molecule NFT.
                tokenIds_[--count] = _giveToken(destination_, auctionStage == 1);
            }

            if (auctionStage > 2) continue;

            _givePhysical(tokenIds_[count]);
        }
    }

    function purchasePhysical(uint256 tokenId_) external payable {
        require(ownerOf(tokenId_) == msg.sender, "NOT_OWNER");
        _checkAndRefundEther(physicalPrice);
        _givePhysical(tokenId_);
    }

    /***************/
    /*** Getters ***/
    /***************/

    function availableSupply() external view returns (uint256 availableSupply_) {
        availableSupply_ = MAX_SUPPLY - totalSupply();
    }

    function contractURI() external view returns (string memory contractURI_) {
        return baseURI;
    }

    function currentAuctionStage() public view returns (uint256 auctionStage_) {
        if (block.timestamp >= AUCTION_END_TIMESTAMP) return auctionStages;

        if (block.timestamp < LAUNCH_TIMESTAMP) return 0;

        auctionStage_ = 1 + (auctionStages * (block.timestamp - LAUNCH_TIMESTAMP)) / (AUCTION_END_TIMESTAMP - LAUNCH_TIMESTAMP);
    }

    function getPurchaseInformationFor(address buyer_) external view returns (
        bool canClaim_,
        uint256 claimableQuantity_,
        uint256 price_,
        bool physicalCopyIncluded_,
        bool specialIncluded_,
        uint256 auctionStage_,
        uint256 timeRemaining_
    ) {
        BuyerInfo memory buyerInfo = buyerInfoFor[buyer_];

        canClaim_ = buyerInfo.buyerType != BuyerType.Regular;
        claimableQuantity_ = buyerInfo.quantity;

        price_ = buyerInfo.buyerType == BuyerType.Free
            ? 0
            : buyerInfo.buyerType == BuyerType.MinimumPrice
                ? _pricePerTokenMint(auctionStages)
                : pricePerTokenMint();

        auctionStage_ = currentAuctionStage();

        physicalCopyIncluded_ = canClaim_ || auctionStage_ == 1 || auctionStage_ == 2;

        specialIncluded_ = auctionStage_ == 1;

        timeRemaining_ = auctionStage_ == 0
            ? LAUNCH_TIMESTAMP - block.timestamp
            : auctionStage_ == 4
                ? 0
                : LAUNCH_TIMESTAMP + auctionStage_ * (AUCTION_END_TIMESTAMP - LAUNCH_TIMESTAMP) / auctionStages - block.timestamp;
    }

    function isLive() external view returns (bool isLive_) {
        isLive_ = block.timestamp >= LAUNCH_TIMESTAMP;
    }

    function isPriceStatic() external view returns (bool priceIsStatic_) {
        priceIsStatic_ = block.timestamp >= AUCTION_END_TIMESTAMP;
    }

    function pricePerTokenMint() public view returns (uint256 pricePerTokenMint_) {
        pricePerTokenMint_ = _pricePerTokenMint(currentAuctionStage());
    }

    function reseedInfoFor(address account_) external view returns (uint8 count_, uint32[7] memory seeds_) {
        ReseedInfo memory reseedInfo = _reseedInfoFor[account_];
        count_ = reseedInfo.count;
        seeds_ = reseedInfo.seeds;
    }

    function timeToLaunch() external view returns (uint256 timeToLaunch_) {
        timeToLaunch_ = LAUNCH_TIMESTAMP > block.timestamp ? LAUNCH_TIMESTAMP - block.timestamp : 0;
    }

    function tokensOfOwner(address owner_) public view returns (uint256[] memory tokenIds_) {
        uint256 balance = balanceOf(owner_);

        tokenIds_ = new uint256[](balance);

        for (uint256 i; i < balance;) {
            tokenIds_[i] = tokenOfOwnerByIndex(owner_, i);

            unchecked {
                ++i;
            }
        }
    }

    function tokenURI(uint256 tokenId_) public override view returns (string memory tokenURI_) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURICache = baseURI;

        tokenURI_ = bytes(baseURICache).length > 0 ? string(abi.encodePacked(baseURICache, "/", tokenId_.toString())) : "";
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _beforeTokenTransfer(address from_, address to_, uint256 tokenId_) internal override {
        // Can mint before launch, but transfers and burns can only happen after launch.
        require(from_ == address(0) || block.timestamp >= LAUNCH_TIMESTAMP, "NOT_LAUNCHED_YET");
        super._beforeTokenTransfer(from_, to_, tokenId_);
    }

    function _checkAndRefundEther(uint256 totalCost_) internal {
        // Require that enough ether was provided.
        require(msg.value >= totalCost_, "INSUFFICIENT_VALUE");

        if (msg.value > totalCost_) {
            // If extra, require that it is successfully returned to the caller.
            unchecked {
                require(_transferEther(msg.sender, msg.value - totalCost_), "REFUND_FAILED");
            }
        }
    }

    function _generatePseudoRandomNumber() internal view returns (uint256 pseudoRandomNumber_) {
        unchecked {
            pseudoRandomNumber_ = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, totalSupply(), gasleft())));
        }
    }

    function _generateSeed(uint256 pseudoRandomNumber_, bool special_) internal pure returns (uint32 seed_) {
        // Keep only 32 bits of pseudoRandomNumber.
        seed_ = uint32(pseudoRandomNumber_ >> 224);

        // Set/unset the special marker.
        if (special_) {
            // If special, ensure 11th bit from right is set.
            seed_ |= 1 << 10;
        } else {
            // If not special, ensure 11th bit from right is not set.
            seed_ &= ~(uint32(1) << 10);
        }
    }

    function _generateTokenId(uint32 seed_, uint32 sequence_) internal pure returns (uint256 tokenId_) {
        // Prepend (add to the left) seed with sequence.
        tokenId_ = uint256(seed_) + (uint256(sequence_) << 32);
    }

    function _getMintCount(uint128 quantity_, uint128 minQuantity_) internal view returns (uint128 mintCount_) {
        // Get the number of stencils available and determine how many stencils will be purchased in this call.
        uint128 available = uint128(MAX_SUPPLY - totalSupply());
        mintCount_ = available >= quantity_ ? quantity_ : available;

        // Prevent a purchase of 0 stencils, as well as a purchase of less stencils than the user expected.
        require(mintCount_ != 0, "NO_STENCILS_AVAILABLE");
        require(mintCount_ >= minQuantity_, "CANNOT_FULLFIL_REQUEST");
    }

    function _givePhysical(uint256 tokenId_) internal {
        require(physicalCopyRecipient[tokenId_] == address(0), "ALREADY_CLAIMED");

        emit PhysicalCopyClaimed(
            tokenId_,
            physicalCopyRecipient[tokenId_] = ownerOf(tokenId_)
        );
    }

    function _giveToken(address destination_, bool special_) internal returns (uint256 tokenId_) {
        require(MAX_SUPPLY > totalSupply(), "NO_STENCILS_AVAILABLE");

        // Can safely cast because MAX_SUPPLY < 4_294_967_295.
        uint32 sequence = uint32(totalSupply() + 1);

        ReseedInfo storage reseedInfo = _reseedInfoFor[msg.sender];

        uint8 seedCount = reseedInfo.count;

        if (seedCount > 0) {
            // Reduce the seed count so that it is a valid index and a valid new seed count.
            --seedCount;

            _mint(
                destination_,
                tokenId_ = _generateTokenId(
                    reseedInfo.seeds[seedCount],
                    sequence
                )
            );

            // Clear the seed at that index and set the new seed count.
            reseedInfo.seeds[seedCount] = 0;
            reseedInfo.count = seedCount;
        } else {
            // If not explicitly giving a special, then if there is still special supply, there is a 5% chance of getting one anyway.
            if (!special_ && (specialCount < specialsTarget)) {
                special_ = (_generatePseudoRandomNumber() % 20) == 0;
            }

            if (special_) {
                ++specialCount;
            }

            // Get a pseudo random number and generate a token id from the moleculeType and randomNumber (saving it in the array of token IDs) and mint the molecule NFT.
            _mint(destination_, tokenId_ = _generateTokenId(_generateSeed(_generatePseudoRandomNumber(), special_), sequence));
        }
    }

    function _pricePerTokenMint(uint256 auctionStage_) internal view returns (uint256 pricePerTokenMint_) {
        pricePerTokenMint_ = startingPricePerTokenMint;

        while (auctionStage_ > 1) {
            pricePerTokenMint_ /= 2;
            --auctionStage_;
        }
    }

    function _transferEther(address destination_, uint256 amount_) internal returns (bool success_) {
        ( success_, ) = destination_.call{ value: amount_ }("");
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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