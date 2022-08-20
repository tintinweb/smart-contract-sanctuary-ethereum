// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
interface _NFT {
    function getOwner(uint256 tokenId) external view returns (address owner);
    function getPrice(uint256 tokenId) external view returns (uint256 price);
    function getAmount() external view returns (uint amount);
    function getCreator() external view returns (address creator);
    function tokenOnSale(uint256 tokenId) external view returns(bool onSale);
    function isKit() external view returns(bool Kit);
    function uri(uint256) external view  returns (string memory);
    function getParents() external view returns (uint[2][] memory);
    function removeTokenFromSale(uint256 tokenId, address sender) external;
    function sendTokenToUser(uint256 tokenId, address NFTReceiver) external;
    function addChild(uint id, uint newNFTId) external;
    function addParents(address sender, uint256[2][] memory Ids) external;
    function returnToken(uint id, address sender) external;
}
interface _Connector {
    function createNFT(string memory NFTData, uint256 numberOfTokens) external returns (address);
}
contract NFTMarket is ERC1155Holder {
    uint private _NFTIds;
    uint private _tokensSold;
    uint256 private listingPrice = 0.025 ether;
    address payable owner;
    mapping(uint256 => address) private idToNFT;
    address private connectorAddr;
    constructor(address _connectorAddr) {
        connectorAddr = _connectorAddr;
        owner = payable(msg.sender);
    }
    function checkId(uint NFTId) private view {
        require(0<NFTId && NFTId <= _NFTIds, "Check NFT id");
    }
    /* returns NFT via NFT ID */
    function getNFT(uint256 NFTId) public view returns (address) {
        checkId(NFTId);
        return idToNFT[NFTId];
    }
    /* gets token Price */
    function getNumberOfSoldTokens() public view returns(uint) {
        return _tokensSold;
    }
    /* returns price of nft placement */
    function getListingPrice() public view returns(uint) {
        return listingPrice;
    }
    /* gets NFT's parents */
    function getNFTParents(uint NFTId) public view returns (uint[2][] memory) {
        checkId(NFTId);
        return _NFT(idToNFT[NFTId]).getParents();
    }
    /* gets number of NFT's on market */
    function getNFTIds() public view returns (uint256) {
        return _NFTIds;
    }
    /* returns all NFTs */
    function fetchNFTs() public view returns (_NFT[] memory) {
        _NFT[] memory items = new _NFT[](_NFTIds);
        for (uint256 NFTID=1; NFTID <= _NFTIds; NFTID++) {
            items[NFTID-1] = _NFT(idToNFT[NFTID]);
        }
        return items;
    }
    /* gets all user's nfts */
    function fetchUserNFTs(address user) public view returns (_NFT[] memory) {
        uint count = 0; // counting nfts
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            uint amount = _NFT(idToNFT[NFTId]).getAmount();
            // if any token is owned by user, adding this nft to nft array
            for (uint tokenId=1; tokenId<=amount; tokenId++) {
                if (_NFT(idToNFT[NFTId]).getOwner(tokenId) == user){
                    count++;
                    break;
                }
            }
        }
        _NFT[] memory items = new _NFT[](count);
        count = 0;
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            uint amount = _NFT(idToNFT[NFTId]).getAmount();
            // if any token is owned by user, adding this nft to nft array
            for (uint tokenId=1; tokenId<=amount; tokenId++) {
                if (_NFT(idToNFT[NFTId]).getOwner(tokenId) == user){
                    items[count] = _NFT(idToNFT[NFTId]);
                    count++;
                    break;
                }
            }
        }
        return items;
    }
    function fetchCreatedByUserNFTs(address user) public view returns (_NFT[] memory) {
        uint count = 0; // counting nfts
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            if (_NFT(idToNFT[NFTId]).getCreator() == user) {
                count++;
                break;
            }
        }
        _NFT[] memory items = new _NFT[](count);
        count = 0;
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            uint amount = _NFT(idToNFT[NFTId]).getAmount();
            // if any token is owned by user, adding this nft to nft array
            for (uint tokenId=1; tokenId<=amount; tokenId++) {
                if (_NFT(idToNFT[NFTId]).getOwner(tokenId) == user){
                    items[count] = _NFT(idToNFT[NFTId]);
                    count++;
                    break;
                }
            }
        }
        return items;
    }
    function fetchNFTsOnSale() public view returns (_NFT[] memory) {
        uint count = 0; // counting nfts
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            uint amount = _NFT(idToNFT[NFTId]).getAmount();
            for (uint tokenId=1; tokenId<=amount; tokenId++) {
                if (_NFT(idToNFT[NFTId]).tokenOnSale(tokenId)){
                    count++;
                    break;
                }
            }
        }
        _NFT[] memory items = new _NFT[](count);
        count = 0;
        for (uint NFTId=1; NFTId<=_NFTIds; NFTId++) {
            uint amount = _NFT(idToNFT[NFTId]).getAmount();
            // if any token on sale, adding this nft to nft array
            for (uint tokenId=1; tokenId<=amount; tokenId++) {
                if (_NFT(idToNFT[NFTId]).tokenOnSale(tokenId)){
                    items[count] = _NFT(idToNFT[NFTId]);
                    count++;
                    break;
                }
            }
        }
        return items;
    }
    /* creates NFT */
    function createNFT(string memory NFTData, uint256 numberOfTokens) public payable returns (uint256) {
        require(msg.value == listingPrice, "Please submit listing price");
        payable(owner).transfer(msg.value); // sending tax to market
        // create new nft via connector
        _NFTIds++;
        uint256 newNFTId = _NFTIds;
        idToNFT[newNFTId] = _Connector(connectorAddr).createNFT(NFTData, numberOfTokens);
        return newNFTId;
    }
    /* creates NFT Kit */
    /* requires to send all tokens to market before */
    function createNFTKit(uint[2][] memory Ids) public payable returns (uint256) {
        // create nftKit
        uint256 newNFTId = createNFT("NFTKit", 1);
        _NFT newNFTKit = _NFT(idToNFT[newNFTId]);
        newNFTKit.addParents(msg.sender, Ids); // add links to parents of new kit
        address sender = msg.sender;
        for (uint i; i < Ids.length; i++) {
            require(Ids[i].length == 2, "data isn't correct");
            uint tokenId = Ids[i][1];
            uint nftId = Ids[i][0];
            _NFT nft = _NFT(idToNFT[nftId]);
            require(nft.getOwner(tokenId) == sender, "You aren't owner of this token!");
            require(!nft.isKit(), "Merged tokens cannot be kits");
            _NFT(idToNFT[nftId]).addChild(tokenId, newNFTId);
        }
        return newNFTId;
    }
    /* makes NFT token sale */
    function buyToken(uint256 NFTId, uint256 tokenId) public payable {
        _NFT nft = _NFT(idToNFT[NFTId]);
        address seller = nft.getOwner(tokenId);
        require(nft.tokenOnSale(tokenId) == true, "this token is not on sale!");
        require(msg.sender != seller, "You can't buy this NFT");
        uint price = nft.getPrice(tokenId);
        require(msg.value == price, "Please submit the asking price in order to complete the purchase");
        nft.sendTokenToUser(tokenId, msg.sender);
        payable(seller).transfer(msg.value);
        _tokensSold++;
    }
    function returnTokenToOwner(uint NFTId, uint tokenId) public {
        checkId(NFTId);
        _NFT(idToNFT[NFTId]).returnToken(tokenId, msg.sender);
    }
    function removeTokenFromSale(uint NFTId, uint tokenId) public {
        checkId(NFTId);
        _NFT(idToNFT[NFTId]).removeTokenFromSale(tokenId, msg.sender);
    }
}
/* contact telegram: @alexanderbtw
           mail: [email protected]
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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