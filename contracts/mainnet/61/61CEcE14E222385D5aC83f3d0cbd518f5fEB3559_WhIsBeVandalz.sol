// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

// library
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Errors } from "./types/Errors.sol";
import { Constants } from "./Constants.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// contracts
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC165Storage } from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC721RandomlyAssignVandalzTier.sol";

interface IGoodKarmaToken {
    function burnTokenForVandal(address holderAddress) external;
}

// solhint-disable

// // // // // // // // // // // // // // // // // // // // // //
// ██╗   ██╗ █████╗ ███╗   ██╗██████╗  █████╗ ██╗     ███████╗ //
// ██║   ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██║     ╚══███╔╝ //
// ██║   ██║███████║██╔██╗ ██║██║  ██║███████║██║       ███╔╝  //
// ╚██╗ ██╔╝██╔══██║██║╚██╗██║██║  ██║██╔══██║██║      ███╔╝   //
//  ╚████╔╝ ██║  ██║██║ ╚████║██████╔╝██║  ██║███████╗███████╗ //
//   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝ //
// // // // // // // // // // // // // // // // // // // // // //

// solhint-enable

/**
 * @title tirewise random assignment contract for vandalz
 * @author
 */
contract WhIsBeVandalz is
    ERC721,
    Ownable,
    ERC721RandomlyAssignVandalzTier,
    ERC721Holder,
    ERC721Burnable,
    ERC165Storage,
    IERC2981
{
    //==Type declarations==//

    using Strings for uint256;
    using SafeERC20 for IERC20;

    //==state variables==//
    /**
     * @notice
     * @dev
     */
    uint256 public publicSalePrice;

    /**
     * @notice
     * @dev
     */
    bool public publicMintPaused = true;

    /**
     * @notice
     * @dev
     */
    bool public whitelistState = true;

    /**
     * @notice
     * @dev
     */
    bool public revealed = true;

    /**
     * @notice
     * @dev
     */
    bool public redeemPaused = true;

    /**
     * @notice
     * @dev
     */
    bool public includeTier1 = false;

    /**
     * @notice list of allowlist address hashed
     * @dev the merkle root hash allowlist
     */
    bytes32 public merkleRoot;

    address public royaltyAddress;
    uint256 public royaltyPercent;

    /**
     * @notice
     * @dev
     */
    uint256[] public groupTier15678Indexes;

    /**
     * @notice
     * @dev
     */
    uint256[] public groupTier5678Indexes;

    /**
     * @notice
     * @dev
     */
    string public baseURI;

    /**
     * @notice
     * @dev
     */
    string public baseExtension = ".json";

    /**
     * @notice
     * @dev
     */
    string public notRevealedUri;

    /**
     * @notice
     * @dev
     */
    mapping(address => bool) public acceptedCollections;

    /**
     * @notice nft burn tracker
     * @dev increments the counter whenever nft is redeemed
     */
    mapping(address => uint256) public burnCounter;

    /**
     * @notice public mint tracker per wallet
     * @dev maps amount of "publicly" minted vandalz per wallet
     */
    mapping(address => uint256) public publicMintCounter;

    //==Constants==//

    // bytes4 constants for ERC165
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_IERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_IERC721Metadata = 0x5b5e139f;

    /**
     * @notice number of tiers
     * @dev the length of `_tiers` array in constructor should exactly match this number
     */
    uint256 public constant TIERS = uint256(8);

    //==events==//
    event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);

    //==Modifiers==//

    /**
     * @dev Throws if timestamp already set.
     */
    modifier publicMintNotPaused() {
        require(publicMintPaused == false, "Public mint is paused");
        _;
    }

    /**
     * @dev Throws if timestamp already set.
     */
    modifier redeemNotPaused() {
        require(redeemPaused == false, "Redeem is paused");
        _;
    }

    //===Constructor===//

    /**
     * @notice
     * @dev
     * @param _name name of the collection
     * @param _symbol symbol of the collection
     * @param _totalSupply maximum pieces if the collection
     * @param _startFrom first token ID of collection
     * @param _tiers list of tier details
     * @param _initBaseURI x
     * @param _initNotRevealedUri v
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _startFrom,
        DataTypes.Tier[] memory _tiers,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) ERC721RandomlyAssignVandalzTier(_totalSupply, _startFrom) {
        uint256 _tiersLen = _tiers.length;
        if (_tiersLen != TIERS) {
            revert Errors.WhisbeVandalz__EightTiersRequired(_tiersLen);
        }

        baseURI = _initBaseURI;

        // no reveal uri
        notRevealedUri = _initNotRevealedUri;

        // whitelisted collections
        acceptedCollections[address(Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.THE_HORNED_KARMA_CHAMELEON_BURN_REDEMPTION_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.KARMA_KEY_BLACK_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.KARMA_KEYS_BY_WHISBE)] = true;
        acceptedCollections[address(Constants.GOOD_KARMA_TOKEN)] = true;

        // tiers
        for (uint256 _i; _i < _tiersLen; _i++) {
            tiers.push(_tiers[_i]);
        }

        // custom : group tiers 1,5,6,7,& 8
        groupTier15678Indexes.push(0); // tier1 , group index -> 0
        groupTier15678Indexes.push(4); // tier5 , group index -> 1
        groupTier15678Indexes.push(5); // tier6 , group index -> 2
        groupTier15678Indexes.push(6); // tier7 , group index -> 3
        groupTier15678Indexes.push(7); // tier8 , group index -> 4

        // custom : group tiers 5,6,7,& 8
        groupTier5678Indexes.push(4); // tier5 , group index -> 0
        groupTier5678Indexes.push(5); // tier6 , group index -> 1
        groupTier5678Indexes.push(6); // tier7 , group index -> 2
        groupTier5678Indexes.push(7); // tier8 , group index -> 3

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_IERC2981);
        _registerInterface(_INTERFACE_ID_IERC721Metadata);
        _setRoyalties(msg.sender, 1100); // 11% royalty
    }

    //===receive function===//

    receive() external payable {
        publicMint(new bytes32[](0));
    }

    //===External functions===//

    /**
     * @notice
     * @dev
     */
    function redeem(address[] memory _collections, uint256[][] memory _tokenIds) external redeemNotPaused {
        uint256 _collectionsLen = _collections.length;
        require(_collectionsLen == _tokenIds.length, "");
        for (uint256 _j; _j < _collectionsLen; _j++) {
            if (!acceptedCollections[_collections[_j]]) {
                revert Errors.WhisbeVandalz__InvalidCollection(_collections[_j]);
            }
            uint256 _tokenIdsLen = _tokenIds[_j].length;
            burnCounter[_collections[_j]] += _tokenIdsLen;
            for (uint256 _i; _i < _tokenIdsLen; _i++) {
                // transfer ownership or burn
                if (_collections[_j] == Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE) {
                    ERC721Burnable(_collections[_j]).safeTransferFrom(msg.sender, address(this), _tokenIds[_j][_i]);
                } else if (_collections[_j] == Constants.GOOD_KARMA_TOKEN) {
                    IGoodKarmaToken(_collections[_j]).burnTokenForVandal(msg.sender);
                } else {
                    ERC721Burnable(_collections[_j]).burn(_tokenIds[_j][_i]);
                }
                // mint Vandalz
                _mintRandomVandalz(msg.sender, _collections[_j]);
            }
        }
    }

    /**
     * @notice
     * @dev
     */
    function airDropToOG(address[] memory _tos) external onlyOwner {
        if (includeTier1) {
            for (uint256 _i; _i < _tos.length; _i++) {
                _handleMintRandomlyFromTierGroup15678(_tos[_i], 1);
            }
        } else {
            for (uint256 _i; _i < _tos.length; _i++) {
                _handleMintRandomlyFromTierGroup5678(_tos[_i], 1);
            }
        }
    }

    /**
     * @notice
     * @dev
     */
    function creatorMint(address _to, uint256[] memory _tokenIds) external onlyOwner {
        for (uint256 _i; _i < _tokenIds.length; _i++) {
            _internalCreatorMint(_to, _tokenIds[_i]);
        }
    }

    /**
     * @notice
     * @dev
     */
    function _internalCreatorMint(address _to, uint256 _tokenId) internal ensureAvailability {
        _updateTierTokenCount(_tokenId);
        _safeMint(_to, _tokenId);
    }

    /**
     * @notice
     * @dev
     */
    function setSupply(uint256 _supply) external onlyOwner {
        _setSupply(_supply);
    }

    /**
     * @notice
     * @dev
     */
    function setTier(
        uint256[] memory _tierIndex,
        uint256[] memory _from,
        uint256[] memory _to
    ) external onlyOwner {
        require(
            _tierIndex.length == _from.length && _from.length == _to.length,
            "WhisbeVandalz: tier details length mismatch"
        );
        for (uint256 _i; _i < _tierIndex.length; _i++) {
            require(_tierIndex[_i] < TIERS, "WhisbeVandalz: tierIndex exceeds max permitted tiers");
            _setTier(_tierIndex[_i], _from[_i], _to[_i]);
        }
    }

    /**
     * @notice
     * @dev
     */
    function reveal() external onlyOwner {
        revealed = true;
    }

    /**
     * @notice
     * @dev
     */
    function setPublicSalePrice(uint256 _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    /**
     * @notice
     * @dev
     */
    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    /**
     * @notice
     * @dev
     */
    function pauseRedeem(bool _state) external onlyOwner {
        redeemPaused = _state;
    }

    /**
     * @notice
     * @dev
     */
    function pausePublicMint(bool _state) external onlyOwner {
        publicMintPaused = _state;
    }

    /**
     * @notice
     * @dev
     */
    function setWhitelistState(bool _state) external onlyOwner {
        whitelistState = _state;
    }

    /**
     * @notice
     * @dev
     */
    function setIncludeTier1(bool _includeTier1) external onlyOwner {
        includeTier1 = _includeTier1;
    }

    /**
     * @notice
     * @dev
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice
     * @dev
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice
     * @dev
     */
    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /**
     * @notice
     * @dev
     */
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Transfer accidentally locked ERC20 tokens
     * @dev can be called by owner only.
     * @param _token - ERC20 token address.
     * @param _amount - ERC20 token amount.
     */
    function transferAccidentallyLockedTokens(IERC20 _token, uint256 _amount) external onlyOwner {
        require(address(_token) != address(0), "Token address can not be zero");
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        _token.safeTransfer(msg.sender, _amount);
    }

    function setRoyaltyInfo(address $royaltyAddress, uint256 $percentage) external onlyOwner {
        _setRoyalties($royaltyAddress, $percentage);
        emit UpdatedRoyalties($royaltyAddress, $percentage);
    }

    //===Public functions===//

    /**
     * @notice
     * @dev
     * @param _proof a
     */
    function publicMint(bytes32[] memory _proof) public payable publicMintNotPaused {
        // Notes: 1592 will be comprised of Tier 3 pieces (approximately 650pieces)
        // Remaining pieces chosen from Tier 1/5/6/7/8

        // cannot mint more than two Vandalz
        if (publicMintCounter[msg.sender] >= 2) {
            revert Errors.WhisbeVandalz__PublicMintUpToTwoPerWallet();
        }

        require(msg.value == publicSalePrice, "WhisbeVandalz: eth value should be equal to publicSalePrice");
        if (whitelistState) {
            _isWhitelistedAddress(_proof);
        }
        _safeMint(msg.sender, _nextToken());
        publicMintCounter[msg.sender] += 1;
    }

    //===Public view functions===//

    function royaltyInfo(uint256, uint256 $salePrice)
        public
        view
        override(IERC2981)
        returns (address _receiver, uint256 _royaltyAmount)
    {
        _receiver = royaltyAddress;

        // This sets percentages by price * percentage / 10000
        _royaltyAmount = ($salePrice * royaltyPercent) / 10000;
    }

    function supportsInterface(bytes4 $interfaceId)
        public
        view
        override(ERC165Storage, ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface($interfaceId);
    }

    /**
     * @notice
     * @dev
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
                : "";
    }

    /**
     * @notice
     * @dev
     */
    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    //===Internal functions===//

    function _setRoyalties(address $receiver, uint256 $percentage) internal {
        royaltyAddress = $receiver;
        royaltyPercent = $percentage;
    }

    /**
     * @notice
     * @dev
     */
    function _mintRandomVandalz(address _to, address _collection) internal {
        if (_collection == Constants.EXTINCTION_OPEN_EDITION_BY_WHISBE) {
            _handleMintForExtinctionOpenEditionByWhisbe(_to);
        } else if (_collection == Constants.THE_HORNED_KARMA_CHAMELEON_BURN_REDEMPTION_BY_WHISBE) {
            _handleMintForTheHornedKarmaChamaleonBurnRedemptionByWhisbe(_to);
        } else if (_collection == Constants.KARMA_KEY_BLACK_BY_WHISBE) {
            _handleMintForKarmaKeyBlackByWhisbe(_to);
        } else if (_collection == Constants.KARMA_KEYS_BY_WHISBE) {
            _handleMintForKarmaKeysByWhisbe(_to);
        } else if (_collection == Constants.GOOD_KARMA_TOKEN) {
            _handleMintForGoodKarmaToken(_to);
        } else {
            revert Errors.WhisbeVandalz__MintNotAvailable();
        }
    }

    //===Internal view functions===//

    /**
     * @notice function to check via merkle proof whether an address is whitelisted
     * @param _proof the nodes required for the merkle proof
     */
    function _isWhitelistedAddress(bytes32[] memory _proof) internal view {
        bytes32 addressHash = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, addressHash), "Whitelist: caller is not whitelisted");
    }

    /**
     * @inheritdoc ERC721
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //===Private functions===//

    /**
     * @notice
     * @dev
     */
    function _handleMintForExtinctionOpenEditionByWhisbe(address _to) private {
        // 1 from tier 4
        _safeMint(_to, _nextTokenFromTier(3));

        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, 1);
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, 1);
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForTheHornedKarmaChamaleonBurnRedemptionByWhisbe(address _to) private {
        // 1 from tier 2
        _safeMint(_to, _nextTokenFromTier(1));

        // 1 from tier 4
        _safeMint(_to, _nextTokenFromTier(3));

        // 8 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(8));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(8));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForKarmaKeyBlackByWhisbe(address _to) private {
        // 1 from tier 4
        _safeMint(_to, _nextTokenFromTier(3));

        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(1));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(1));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForKarmaKeysByWhisbe(address _to) private {
        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(1));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(1));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintForGoodKarmaToken(address _to) private {
        // 1 from tier 1,5,6,7,8
        if (includeTier1) {
            _handleMintRandomlyFromTierGroup15678(_to, uint256(1));
        } else {
            _handleMintRandomlyFromTierGroup5678(_to, uint256(1));
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintRandomlyFromTierGroup15678(address _to, uint256 _count) private {
        uint256 _groupTier15678IndexesLen = groupTier15678Indexes.length;
        if (_groupTier15678IndexesLen == 0) {
            revert Errors.WhisbeVandalz__NoGroupTier15678Group();
        }
        uint256 _randomTier15678GroupIndex;
        for (uint256 _i; _i < _count; _i++) {
            // get random tier index from tier group
            _randomTier15678GroupIndex = _getRandomNumber() % _groupTier15678IndexesLen;

            // mint
            _safeMint(_to, _nextTokenFromTier(groupTier15678Indexes[_randomTier15678GroupIndex]));

            // check and update tier group based on each tier's token availability
            _checkAndUpdateGroupTier15678TokenAvailability(_randomTier15678GroupIndex);
            if (_randomTier15678GroupIndex != 0) {
                _checkAndUpdateGroupTier5678TokenAvailability(_randomTier15678GroupIndex - 1);
            }
        }
    }

    /**
     * @notice
     * @dev
     */
    function _handleMintRandomlyFromTierGroup5678(address _to, uint256 _count) private {
        uint256 _groupTier5678IndexesLen = groupTier5678Indexes.length;
        if (_groupTier5678IndexesLen == 0) {
            revert Errors.WhisbeVandalz__NoGroupTier5678Group();
        }
        uint256 _randomTier5678GroupIndex;
        for (uint256 _i; _i < _count; _i++) {
            // get random tier index from tier group
            _randomTier5678GroupIndex = _getRandomNumber() % _groupTier5678IndexesLen;

            // mint
            _safeMint(_to, _nextTokenFromTier(groupTier5678Indexes[_randomTier5678GroupIndex]));

            // check and update tier group based on each tier's token availability
            _checkAndUpdateGroupTier5678TokenAvailability(_randomTier5678GroupIndex);
            _checkAndUpdateGroupTier15678TokenAvailability(_randomTier5678GroupIndex + 1);
        }
    }

    /**
     * @dev
     * @param _index
     */
    function _checkAndUpdateGroupTier15678TokenAvailability(uint256 _index) private {
        if (availableTierTokenCount(groupTier15678Indexes[_index]) == 0) {
            groupTier15678Indexes[_index] = groupTier15678Indexes[groupTier15678Indexes.length - 1];
            groupTier15678Indexes.pop();
        }
    }

    /**
     * @dev
     * @param _index
     */
    function _checkAndUpdateGroupTier5678TokenAvailability(uint256 _index) private {
        if (availableTierTokenCount(groupTier5678Indexes[_index]) == 0) {
            groupTier5678Indexes[_index] = groupTier5678Indexes[groupTier5678Indexes.length - 1];
            groupTier5678Indexes.pop();
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.7;

library Errors {
    error WhisbeVandalz__InvalidCollection(address);
    error WhisbeVandalz__EightTiersRequired(uint256);
    error ERC721RandomlyAssignVandalzTier__UnavailableTierTokens(uint256);
    error WhisbeVandalz__MintNotAvailable();
    error WhisbeVandalz__PublicMintUpToTwoPerWallet();
    error WhisbeVandalz__NoGroupTier15678Group();
    error WhisbeVandalz__NoGroupTier5678Group();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title
 * @author
 */
library Constants {
    address public constant EXTINCTION_OPEN_EDITION_BY_WHISBE = 0xcD136E30b316837C190241e838639c619516Fdf9;
    address public constant THE_HORNED_KARMA_CHAMELEON_BURN_REDEMPTION_BY_WHISBE =
        0x41C884CC6847a95CfFf4EaC251173ea72C3c5eFB;
    address public constant KARMA_KEY_BLACK_BY_WHISBE = 0xe2C2613E647Ebd03fdC71a1Cf1fD1F938321356c;
    address public constant KARMA_KEYS_BY_WHISBE = 0xA53e7Fd6abC0fe9769690Af55f19c2b4A13F2Bc3;
    address public constant GOOD_KARMA_TOKEN = 0xC5dd321472f80A3EC9779F55cc1Af854712fAE70;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.0;

import "./ERC721Extensions/ERC721LimitedSupply.sol";
import { DataTypes } from "./types/DataTypes.sol";
import { Errors } from "./types/Errors.sol";

/**
 * @title Randomly assign tokenIDs from a given set of tokens.
 */
abstract contract ERC721RandomlyAssignVandalzTier is ERC721LimitedSupply {
    using Counters for Counters.Counter;

    /**
     * @dev token id of first token
     */
    uint256 public startFrom;

    /**
     * @dev Used for random index assignment
     */
    mapping(uint256 => uint256) private tokenMatrix;

    /**
     * @notice
     * @dev
     */
    DataTypes.Tier[] public tiers;

    /**
     * @notice Instanciate the contract
     * @param _totalSupply how many tokens this collection should hold
     */
    constructor(uint256 _totalSupply, uint256 _startFrom) ERC721LimitedSupply(_totalSupply) {
        startFrom = _startFrom;
    }

    /**
     * @notice Get the current token count of give tier
     * @param _tierIndex the tier index
     * @return the created token count of given tier
     */
    function tierWiseTokenCount(uint256 _tierIndex) public view returns (uint256) {
        return tiers[_tierIndex].tokenCount.current();
    }

    /**
     * @notice Check whether tokens are still available for a given tier
     * @param _tierIndex the tier index
     * @return the available token count for given tier
     */
    function availableTierTokenCount(uint256 _tierIndex) public view returns (uint256) {
        return tiers[_tierIndex].pieces - tiers[_tierIndex].tokenCount.current();
    }

    /**
     * @notice Get the next token ID
     * @dev Randomly gets a new token ID and keeps track of the ones that are still available.
     * @return the next token ID
     */
    function _nextToken() internal override ensureAvailability returns (uint256) {
        uint256 _nextTokenId = _internalNextToken(totalSupply() - tokenCount()) + startFrom;
        _updateTierTokenCount(_nextTokenId);
        return _nextTokenId;
    }

    function _updateTierTokenCount(uint256 _nextTokenId) internal {
        for (uint256 _i; _i < tiers.length; _i++) {
            if (_nextTokenId >= tiers[_i].from && _nextTokenId <= tiers[_i].to) {
                // Increment tier token count
                tiers[_i].tokenCount.increment();
                break;
            }
        }
    }

    /**
     * @notice Get the next token ID from given tier
     * @dev Randomly gets a new token ID from given tier and keeps track of the ones that are still available.
     * @return the next token ID from given tier
     */
    function _nextTokenFromTier(uint256 _tierIndex) internal ensureAvailability returns (uint256) {
        if (availableTierTokenCount(_tierIndex) == 0) {
            revert Errors.ERC721RandomlyAssignVandalzTier__UnavailableTierTokens(_tierIndex);
        }

        uint256 _nextTokenId =
            _internalNextToken(tiers[_tierIndex].pieces - tiers[_tierIndex].tokenCount.current()) +
                tiers[_tierIndex].from;

        // Increment tier token count
        tiers[_tierIndex].tokenCount.increment();

        return _nextTokenId;
    }

    function _internalNextToken(uint256 _maxIndex) internal returns (uint256) {
        uint256 _randomNumber = _getRandomNumber() % _maxIndex;
        uint256 value;
        if (tokenMatrix[_randomNumber] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = _randomNumber;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[_randomNumber];
        }
        // If the last available tokenID is still unused...
        if (tokenMatrix[_maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[_randomNumber] = _maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[_randomNumber] = tokenMatrix[_maxIndex - 1];
        }
        // Increment counts
        super._nextToken();

        return value;
    }

    function _setTier(
        uint256 _tierIndex,
        uint256 _from,
        uint256 _to
    ) internal virtual {
        require(_to - _from >= tiers[_tierIndex].pieces, "ERC721RandomlyAssignVandalzTier : misaligned pieces");
        tiers[_tierIndex].from = _from;
        tiers[_tierIndex].to = _to;
        tiers[_tierIndex].pieces = _to - _from + 1;
    }

    /**
     * @notice Get the next token ID
     * @dev Randomly gets a new token ID and keeps track of the ones that are still available.
     * @return the next token ID
     */
    function _getRandomNumber() internal view virtual returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.coinbase,
                        blockhash(block.number),
                        block.gaslimit,
                        block.timestamp,
                        tokenCount(),
                        availableTokenCount(),
                        totalSupply()
                    )
                )
            );
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title A token tracker that limits the token supply and increments token IDs on each new mint.
 * @author
 */
abstract contract ERC721LimitedSupply {
    using Counters for Counters.Counter;

    /**
     * @dev Emitted when the supply of this collection changes
     */
    event SupplyChanged(uint256 indexed supply);

    /**
     * @dev Keeps track of how many we have minted
     */
    Counters.Counter private _tokenCount;

    /**
     * @dev The maximum count of tokens this token tracker will hold.
     */
    uint256 private _totalSupply;

    /**
     * @dev Instanciate the contract
     * @param totalSupply_ how many tokens this collection should hold
     */
    constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_;
    }

    /**
     * @notice Get the max Supply
     * @return the maximum token count
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Get the current token count
     * @return the created token count
     */
    function tokenCount() public view returns (uint256) {
        return _tokenCount.current();
    }

    /**
     * @notice Check whether tokens are still available
     * @return the available token count
     */
    function availableTokenCount() public view returns (uint256) {
        return totalSupply() - tokenCount();
    }

    /**
     * @dev Increment the token count and fetch the latest count
     * @return the next token id
     */
    function _nextToken() internal virtual returns (uint256) {
        uint256 token = _tokenCount.current();

        _tokenCount.increment();

        return token;
    }

    /**
     * @dev Check whether another token is still available
     */
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    /**
     * @dev Check whether tokens are still available
     * @param amount Check whether number of tokens are still available
     */
    modifier ensureAvailabilityFor(uint256 amount) {
        require(availableTokenCount() >= amount, "Requested number of tokens not available");
        _;
    }

    /**
     * @notice Update the supply for the collection
     * @dev create additional token supply for this collection.
     * @param _supply the new token supply.
     */
    function _setSupply(uint256 _supply) internal virtual {
        require(_supply > tokenCount(), "Can't set the supply to less than the current token count");
        _totalSupply = _supply;

        emit SupplyChanged(totalSupply());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title container of the data types
 * @author
 */
library DataTypes {
    /**
     * @notice
     * @dev
     * @param
     * @param
     */
    struct Tier {
        uint256 from;
        uint256 to;
        uint256 pieces;
        Counters.Counter tokenCount;
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