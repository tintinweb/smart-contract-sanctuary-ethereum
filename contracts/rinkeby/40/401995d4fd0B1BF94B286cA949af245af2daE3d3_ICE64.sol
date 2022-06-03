// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

import {Owned} from "@rari-capital/solmate/src/auth/Owned.sol";
import {ERC1155} from "@rari-capital/solmate/src/tokens/ERC1155.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";
import {DynamicBuffer} from "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import {Base64} from "./Base64.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IICE64Renderer} from "./interfaces/IICE64Renderer.sol";
import {IICE64} from "./interfaces/IICE64.sol";

/// @title ICE64, a photo collection by Sam King
/// @author Sam King (samkingstudio.eth)
contract ICE64 is ERC1155, Owned, IICE64 {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /* DEPENDENCIES -------------------------------------------------------- */

    IICE64Renderer public metadata;
    IERC721 public roots;

    /* SALE DATA ----------------------------------------------------------- */

    uint256 private _rootsClaims;

    uint256 private constant _maxTokenId = 16;
    uint256 private constant _editionStartId = 100;
    uint256 private constant _maxEditions = 32;

    uint256 public constant priceOriginal = 0.0032 ether;
    uint256 public constant priceEdition = 0.0002 ether;
    mapping(uint256 => uint256) private _salesCount;

    struct RoyaltyInfo {
        address receiver;
        uint24 amount;
    }

    RoyaltyInfo private _royaltyInfo;

    /* IMAGE DATA ---------------------------------------------------------- */

    string private _originalsBaseURI;

    uint256 private constant _photoDataByteSize = 4360;
    uint256 private constant _photoDataChunkLength = 2;
    mapping(uint256 => address) private _photoDataChunks;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    /* MINT ---------------------------------------------------------------- */

    error SaleNotActive();
    error AlreadyOwnerOfEdition();
    error IncorrectEthAmount();
    error SoldOut();
    error EditionForOriginalHolderStillReserved();
    error NotOwnerOfOriginal();
    error ReservedEditionAlreadyClaimed();
    error NotOwnerOfRootsPhoto();
    error RootsPhotoAlreadyUsedClaim();

    /* ADMIN --------------------------------------------------------------- */

    error InvalidPhotoData();
    error InvalidToken();
    error NoMetadataYet();
    error PaymentFailed();

    /* BURN ---------------------------------------------------------------- */

    error NotOwner();

    /* ------------------------------------------------------------------------
                                 M O D I F I E R S
    ------------------------------------------------------------------------ */

    /// @dev Limits purchases etc to a certain range of token ids
    /// @param id The id of the token to check
    modifier onlyValidToken(uint256 id) {
        if (id == 0 || id > _maxTokenId) revert InvalidToken();
        _;
    }

    /// @dev Checks the payment amount matches exactly (no more, no less)
    /// @param cost The amount that should be checked against
    modifier onlyCorrectPayment(uint256 cost) {
        if (msg.value != cost) revert IncorrectEthAmount();
        _;
    }

    /// @dev Require the metadata address to be set
    modifier onlyWithMetadata() {
        if (address(metadata) == address(0)) revert NoMetadataYet();
        _;
    }

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /// @param owner The owner of the contract upon deployment
    /// @param originalsBaseURI_ The base URI for original photos (usually arweave or ipfs)
    /// @param roots_ The Roots collection address
    constructor(
        address owner,
        address royalties,
        string memory originalsBaseURI_,
        IERC721 roots_
    ) ERC1155() Owned(owner) {
        // Set initial storage values
        _originalsBaseURI = originalsBaseURI_;
        roots = roots_;

        // Set the initial storage value to non-zero to save gas costs for first roots claimer
        _rootsClaims = _setBool(_rootsClaims, 0, true);

        // Set the default royalties to 6.4% for the owner
        _royaltyInfo = RoyaltyInfo(royalties, 640);
    }

    /// @notice Sets the rendering/metadata contract address
    /// @dev The metadata address handles on-chain images and construction of baseURI for originals
    /// @param metadataAddr The address of the metadata contract
    function setMetadata(IICE64Renderer metadataAddr) external onlyOwner {
        metadata = metadataAddr;
    }

    /* ------------------------------------------------------------------------
                                P U R C H A S I N G
    ------------------------------------------------------------------------ */

    /// @notice Purchase an original 1/1 photo and an on-chain edition
    /// @dev Mints a 1/1 and an on-chain edition of the same token, but only if the buyer
    ///      doesn't already own an edition
    /// @param id The id of the photo to purchase
    function purchaseOriginal(uint256 id)
        external
        payable
        onlyValidToken(id)
        onlyCorrectPayment(priceOriginal)
    {
        (uint256 originalsSold, , ) = _decodeSalesCount(_salesCount[id]);
        if (originalsSold > 0) revert SoldOut();

        uint256 editionId = getEditionTokenId(id);
        if (balanceOf[msg.sender][editionId] > 0) {
            // Already owner of an edition so just mint an original and mark the
            // reserved edition as claimed so someone else can get an edition
            _mint(msg.sender, id, 1, "");
            _addSalesCount(id, 1, 0, true);
        } else {
            // Else mint both the original and the reserved edition
            /// @dev We could use `_batchMint` here, but there are issues with those tokens
            ///      not being picked up by certain marketplaces *cough* OpenSea *cough*.
            ///      Gas should be the same since we're only updating one of each token anyway.
            _mint(msg.sender, id, 1, "");
            _mint(msg.sender, editionId, 1, "");
            _addSalesCount(id, 1, 1, true);
        }
    }

    /// @notice Purchase an edition of a photo, rendered as a 64x64px on-chain SVG
    /// @dev Editions are sold out when `_maxEditions` editions have been minted, less one reserved
    ///      token for the holder of an original photo
    /// @param id The id of the edition to purchase (use original photo's id: `getEditionId(id)`)
    function purchaseEdition(uint256 id)
        external
        payable
        onlyValidToken(id)
        onlyCorrectPayment(priceEdition)
    {
        _mintEdition(id);
    }

    /// @notice Claim a free edition (whill supply lasts) if you hold a Roots photo. Check if the
    ///         Roots photo has been claimed with `hasEditionBeenClaimedForRootsPhoto`.
    /// @dev Requires holding a Roots photo that hasn't been previously used to claim an edition
    /// @param id The id of the edition to claim
    /// @param rootsId The id of the Roots photo to use when claiming
    function claimEditionAsRootsHolder(uint256 id, uint256 rootsId) external onlyValidToken(id) {
        if (roots.ownerOf(rootsId) != msg.sender) revert NotOwnerOfRootsPhoto();
        if (_getBool(_rootsClaims, rootsId)) revert RootsPhotoAlreadyUsedClaim();
        _mintEdition(id);
        _rootsClaims = _setBool(_rootsClaims, rootsId, true);
    }

    /// @dev Internal function to mint an edition, checking if there's still supply
    /// @param id The id of the edition to mint (use original photo's id: `getEditionId(id)`)
    function _mintEdition(uint256 id) internal {
        uint256 editionId = getEditionTokenId(id);
        (, uint256 editionsSold, bool reservedEditionClaimed) = _decodeSalesCount(_salesCount[id]);
        uint256 editionsAvailable = reservedEditionClaimed ? _maxEditions : _maxEditions - 1;
        if (editionsSold == editionsAvailable) {
            if (reservedEditionClaimed) {
                revert SoldOut();
            } else {
                revert EditionForOriginalHolderStillReserved();
            }
        }
        if (balanceOf[msg.sender][editionId] > 0) revert AlreadyOwnerOfEdition();
        _mint(msg.sender, editionId, 1, "");
        _addSalesCount(id, 0, 1, reservedEditionClaimed);
    }

    /// @dev Increments sales data for a given id
    /// @param id The id of the photo to add sales data for
    /// @param originalsSold_ The number of originals sold for this given call
    /// @param editionsSold_ The number of editions sold for this given call
    /// @param reservedEditionClaimed_ Whether the original photo has claimed the reserved edition
    function _addSalesCount(
        uint256 id,
        uint256 originalsSold_,
        uint256 editionsSold_,
        bool reservedEditionClaimed_
    ) internal {
        (uint256 originalsSold, uint256 editionsSold, ) = _decodeSalesCount(_salesCount[id]);
        _salesCount[id] = _encodeSalesCount(
            originalsSold + originalsSold_,
            editionsSold + editionsSold_,
            reservedEditionClaimed_
        );
    }

    /// @dev Encodes sales data into a single uint256 for cheaper storage updates
    /// @param originalsSoldCount The number of originals sold
    /// @param editionsSoldCount The number of editions sold
    /// @param reservedEditionClaimed Whether the original photo has claimed the reserved edition
    /// @return salesCount A packed uint256
    function _encodeSalesCount(
        uint256 originalsSoldCount,
        uint256 editionsSoldCount,
        bool reservedEditionClaimed
    ) internal pure returns (uint256 salesCount) {
        salesCount = salesCount | (originalsSoldCount << 0);
        salesCount = salesCount | (editionsSoldCount << 8);
        salesCount = reservedEditionClaimed ? salesCount | (1 << 16) : salesCount | (0 << 16);
    }

    /// @dev Decodes sales data from a single uint256
    /// @param salesCount The packed uint256 to decode
    /// @return originalsSoldCount The number of originals sold
    /// @return editionsSoldCount The number of editions sold
    /// @return reservedEditionClaimed Whether the original photo has claimed the reserved edition
    function _decodeSalesCount(uint256 salesCount)
        internal
        pure
        returns (
            uint256 originalsSoldCount,
            uint256 editionsSoldCount,
            bool reservedEditionClaimed
        )
    {
        originalsSoldCount = uint8(salesCount >> 0);
        editionsSoldCount = uint8(salesCount >> 8);
        reservedEditionClaimed = uint8(salesCount >> 16) > 0;
    }

    /* ------------------------------------------------------------------------
                                 O R I G I N A L S
    ------------------------------------------------------------------------ */

    /// @notice Admin function to set the baseURI for original photos (arweave or ipfs)
    /// @param baseURI The new baseURI to set
    function setOriginalsBaseURI(string memory baseURI) external onlyOwner {
        _originalsBaseURI = baseURI;
    }

    /// @notice Retrieve the currently set baseURI
    /// @dev Used by the metadata contract to construct the tokenURI
    function getOriginalsBaseURI() external view returns (string memory) {
        return _originalsBaseURI;
    }

    /// @notice Gets the original token id from an edition token id
    /// @param editionId The token id of the edition
    function getOriginalTokenId(uint256 editionId) public pure returns (uint256) {
        return editionId - _editionStartId;
    }

    /// @notice Checks if an original photo has been sold
    /// @param id The id of the photo
    function getOriginalSold(uint256 id) external view returns (bool) {
        (uint256 originalsSold, , ) = _decodeSalesCount(_salesCount[id]);
        return originalsSold > 0;
    }

    /* ------------------------------------------------------------------------
                                  E D I T I O N S
    ------------------------------------------------------------------------ */

    /// @notice Admin function to store chunked photo data for on-chain editions
    /// @dev Stores the data in chunks for more efficient storage and costs
    /// @param chunkId The chunk id to save data for
    /// @param data The packed data in .xqst format
    function storeChunkedEditionPhotoData(uint256 chunkId, bytes calldata data) external onlyOwner {
        if (data.length != _photoDataByteSize * _photoDataChunkLength) revert InvalidPhotoData();
        _photoDataChunks[chunkId] = SSTORE2.write(data);
    }

    /// @notice Gets the raw .xqst data for a given photo
    /// @dev Used by the metadata contract to read data from storage
    /// @param id The id of the photo to get data for
    function getRawEditionPhotoData(uint256 id)
        external
        view
        onlyValidToken(id)
        returns (bytes memory)
    {
        return _getRawEditionPhotoData(id);
    }

    /// @notice Gets a photo in SVG format
    /// @dev Calls out to the metadata contract for rendering
    /// @param id The id of the photo to render
    function getEditionPhotoSVG(uint256 id)
        external
        view
        onlyValidToken(id)
        onlyWithMetadata
        returns (string memory)
    {
        bytes memory data = _getRawEditionPhotoData(id);
        return metadata.drawSVGToString(data);
    }

    /// @notice Gets a photo in Base64 encoded SVG format
    /// @dev Calls out to the metadata contract for rendering
    /// @param id The id of the photo to render
    function getEditionPhotoBase64SVG(uint256 id)
        external
        view
        onlyValidToken(id)
        onlyWithMetadata
        returns (string memory)
    {
        bytes memory data = _getRawEditionPhotoData(id);
        bytes memory svg = metadata.drawSVGToBytes(data);
        bytes memory svgBase64 = DynamicBuffer.allocate(2**19);

        svgBase64.appendSafe("data:image/svg+xml;base64,");
        svgBase64.appendSafe(bytes(Base64.encode(svg)));

        return string(svgBase64);
    }

    /// @dev Gets the raw photo data from storage
    /// @param id The id of the photo to render
    function _getRawEditionPhotoData(uint256 id) internal view returns (bytes memory) {
        uint256 chunkId = ((id - 1) / _photoDataChunkLength) + 1;
        uint256 chunkIndex = (id - 1) % _photoDataChunkLength;
        uint256 startBytes = chunkIndex * _photoDataByteSize;
        return SSTORE2.read(_photoDataChunks[chunkId], startBytes, startBytes + _photoDataByteSize);
    }

    /// @notice Gets the edition token id from the original token id
    /// @param id The id of the original photo
    function getEditionTokenId(uint256 id) public pure returns (uint256) {
        return id + _editionStartId;
    }

    /// @notice Gets the total number of editions that have been sold for a photo
    /// @param id The id of the photo to get the number of editions sold
    function getEditionsSold(uint256 id) external view returns (uint256) {
        (, uint256 editionsSold, ) = _decodeSalesCount(_salesCount[id]);
        return editionsSold;
    }

    /// @notice Gets the maximum number of editions per photo
    function getMaxEditions() external pure returns (uint256) {
        return _maxEditions;
    }

    /// @notice Checks if a token id is an original or an edition
    /// @param id The token id to check
    function isEdition(uint256 id) public pure returns (bool) {
        return id > _editionStartId;
    }

    /// @notice Check if a particular Roots photo has been used to claim an edition
    /// @param rootsId The id of the Roots photo
    function hasEditionBeenClaimedForRootsPhoto(uint256 rootsId) external view returns (bool) {
        return _getBool(_rootsClaims, rootsId);
    }

    /* ------------------------------------------------------------------------
                                  E R C - 1 1 5 5
    ------------------------------------------------------------------------ */

    /// @notice Burn your token :(
    /// @param id The id of the token you want to burn
    function burn(uint256 id) external {
        if (balanceOf[msg.sender][id] == 0) revert NotOwner();
        _burn(msg.sender, id, 1);
    }

    /// @notice Standard URI function to get the token metadata
    /// @param id The token id to get metadata for
    function uri(uint256 id) public view virtual override onlyWithMetadata returns (string memory) {
        return metadata.tokenURI(id);
    }

    /* ------------------------------------------------------------------------
                                  W I T H D R A W
    ------------------------------------------------------------------------ */

    /// @notice Withdraw the contracts ETH balance to the admin wallet
    function withdrawBalance() external {
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        if (!success) revert PaymentFailed();
    }

    /// @notice Withdraw all tokens for a given contract to the admin wallet
    function withdrawToken(IERC20 tokenAddress) external {
        tokenAddress.transfer(owner, tokenAddress.balanceOf(address(this)));
    }

    /* ------------------------------------------------------------------------
                                 R O Y A L T I E S
    ------------------------------------------------------------------------ */

    /// @notice EIP-2981 royalty standard for on-chain royalties
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = _royaltyInfo.receiver;
        royaltyAmount = (salePrice * _royaltyInfo.amount) / 10_000;
    }

    /// @notice Update royalty information
    /// @param receiver The receiver of royalty payments
    /// @param amount The royalty percentage with two decimals (10000 = 100)
    function setRoyaltyInfo(address receiver, uint256 amount) external onlyOwner {
        _royaltyInfo = RoyaltyInfo(receiver, uint24(amount));
    }

    /// @dev Extend `supportsInterface` to suppoer EIP-2981
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // EIP-2981 = bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /* ------------------------------------------------------------------------
                                M I S C   U T I L S
    ------------------------------------------------------------------------ */

    /// @dev Internal function to store up to 256 bools in a single uint256
    /// @param packed The uint256 that contains the packed booleans
    /// @param idx The index of the boolean to set
    /// @param value Whether the bool is true or false
    /// @return packed The updated packed uint256
    function _setBool(
        uint256 packed,
        uint256 idx,
        bool value
    ) internal pure returns (uint256) {
        if (value) return packed | (uint256(1) << idx);
        return packed & ~(uint256(1) << idx);
    }

    /// @dev Internal function to get a specific boolean from a packed uint256
    /// @param packed The uint256 that contains the packed booleans
    /// @param idx The index of the boolean to get
    /// @return value If the value is set to true or false
    function _getBool(uint256 packed, uint256 idx) internal pure returns (bool) {
        uint256 flag = (packed >> idx) & uint256(1);
        return flag == 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
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
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64Renderer {
    function drawSVGToString(bytes memory data) external pure returns (string memory);

    function drawSVGToBytes(bytes memory data) external pure returns (bytes memory);

    function tokenURI(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64 {
    function getOriginalsBaseURI() external view returns (string memory);

    function getOriginalTokenId(uint256 editionId) external pure returns (uint256);

    function getRawEditionPhotoData(uint256 id) external view returns (bytes memory);

    function getEditionTokenId(uint256 id) external pure returns (uint256);

    function getMaxEditions() external view returns (uint256);

    function isEdition(uint256 id) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
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