// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface ICondos {
    function assembleRandomStreet(uint256 seed) external returns (uint16[5] memory ids);
    function breakupStreet(address to, uint256[] calldata ids) external;
    function assembleStreet(address from, uint256[] calldata ids) external;
}

interface IMetadata {
    function condosAddress() external pure returns (address contractAddress);
    function streetMetadata(uint256 tokenId) external view returns (string memory);
    function revealed() external pure returns (bool isRevealed);
    function CONDOS_IPFS_CID() external pure returns (string memory condosIPFS);
    function BACKGROUNDS_IPFS_CID() external pure returns (string memory backgroundsIPFS);
    function STREETS_PREREVEAL_URI() external pure returns (string memory streetsURI);
    function IPFS_URI_Prefix() external pure returns (string memory prefixURI);
    function totalBackgrounds() external pure returns (uint16 numBackgrounds);
}

interface IMoonCatSVGS {
    function uint2str(uint value) external pure returns (string memory);
}

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


/*
 * @title CondoMini Streets
 * @author Ponderware Ltd
 * @dev CondoMini Neighborhood ERC-721 NFT
 */
contract Streets is Ownable, IERC721Enumerable, IERC721Metadata {
    ICondos public Condos;
    IMetadata public Metadata;

    uint256 public price = 0.01 ether;
    bool public paused = true;

    string public name = "CondoMiniNeighborhood";
    string public symbol = "CMi";

    address[4000] private Owners;
    mapping(address => uint256[]) internal TokensByOwner;
    uint16[4000] internal OwnerTokenIndex;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private TokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private OperatorApprovals;

    uint256 public mintsAvailable = 4000;
    uint256 public totalSupply = 0;

    bool public onlyFriends = true;
    mapping(address => bool) private Friends;

    address private immutable publisher;

    struct Street {
        uint16[5] condos;
        uint16 background;
        bytes20 name;
    }

    Street[4000] directory;
    uint16[] availableIds;

    constructor(address metadataAddress, address publisherAddress) {
        publisher = publisherAddress;
        Metadata = IMetadata(metadataAddress);
        Condos = ICondos(Metadata.condosAddress());
    }

    /* Modifiers */
    modifier whenNotPaused() {
        require(paused == false, "Paused");
        _;
    }

    modifier notContracts() {
        require(tx.origin == msg.sender, "Contracts not allowed");
        _;
    }

    /* Administration */
    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function openPublicMint() public onlyOwner {
        onlyFriends = false;
    }

    function refreshCondosAdress() public onlyOwner {
        Condos = ICondos(Metadata.condosAddress());
    }

    function addFriends(address[] calldata friendAddresses) public onlyOwner {
        for (uint i = 0; i < friendAddresses.length; i++) {
            Friends[friendAddresses[i]] = true;
        }
    }

    function setPrice(uint256 priceWei) public onlyOwner {
        price = priceWei;
    }

    function clearName(uint256 tokenId) public onlyOwner {
        require(tokenExists(tokenId), "Nonexistent Token");
        directory[tokenId].name = 0;
    }

    function withdraw() public {
        require(msg.sender == owner() || msg.sender == publisher, "Unauthorized");
        uint256 publisherShare = (address(this).balance * 40) / 100;
        payable(publisher).transfer(publisherShare);
        payable(owner()).transfer(address(this).balance);
    }

    function isFriend(address friendAddress) public view returns (bool) {
        return Friends[friendAddress] == true;
    }

    function _handleMintStreet(address recipient) internal returns (uint256 tokenId) {
        require(mintsAvailable > 0, "Insufficient supply available");

        uint256 seed = uint256(keccak256(abi.encodePacked(recipient, blockhash(block.number - 1))));

        uint16[5] memory ids = Condos.assembleRandomStreet(seed);

        tokenId = _mint(recipient);

        uint16 backgroundId = uint16(uint256(keccak256(abi.encodePacked(tokenId, seed))) % Metadata.totalBackgrounds());

        directory[tokenId] = Street(ids, backgroundId, "");

        mintsAvailable--;
    }

    function premintRandomStreets(address recipient, uint256 quantity) public onlyOwner {
        for (uint256 i = 0; i < quantity; i++) {
            _handleMintStreet(recipient);
        }
    }

    function mintRandomStreet(address recipient) public payable whenNotPaused notContracts returns (uint256 id) {
        require(onlyFriends == false || Friends[msg.sender] == true, "Public minting not open");

        uint256 cost = price * 5;
        require(msg.value >= cost, "Insufficient Funds");

        id = _handleMintStreet(recipient);
    }

    function mintRandomStreets(address recipient, uint256 quantity) public payable whenNotPaused notContracts {
        require(onlyFriends == false || Friends[msg.sender] == true, "Public minting not open");

        uint256 cost = price * 5 * quantity;
        require(msg.value >= cost, "Insufficient Funds");

        for (uint256 i = 0; i < quantity; i++) {
            _handleMintStreet(recipient);
        }
    }

    function assembleStreet(uint256[] memory ids, uint16 backgroundId, bytes20 streetName) public whenNotPaused notContracts returns (uint256 tokenId) {
        require(Metadata.revealed(), "The metadata has not yet revealed");
        require(ids.length == 5, "Requires 5 Condos");
        require(backgroundId < Metadata.totalBackgrounds(), "Invalid background id");
        Condos.assembleStreet(msg.sender, ids);

        tokenId = _mint(msg.sender);

        uint16[5] memory newStreet;
        newStreet[0] = uint16(ids[0]);
        newStreet[1] = uint16(ids[1]);
        newStreet[2] = uint16(ids[2]);
        newStreet[3] = uint16(ids[3]);
        newStreet[4] = uint16(ids[4]);

        directory[tokenId] = Street(newStreet, backgroundId, streetName);
    }

    function breakupStreet(uint256 tokenId) public whenNotPaused notContracts {
        require(Metadata.revealed(), "The metadata has not yet revealed");
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner nor approved");

        Street storage street = directory[tokenId];
        uint256[] memory condoIds = new uint256[](5);
        condoIds[0] = street.condos[0];
        condoIds[1] = street.condos[1];
        condoIds[2] = street.condos[2];
        condoIds[3] = street.condos[3];
        condoIds[4] = street.condos[4];

        Condos.breakupStreet(msg.sender, condoIds);
        _burn(tokenId);
        delete directory[tokenId];
    }

    function breakupStreets(uint256[] calldata tokenIds) public {
        require(Metadata.revealed(), "The metadata has not yet revealed");

        for (uint i = 0; i < tokenIds.length; i++) {
            breakupStreet(tokenIds[i]);
        }
    }

    function getStreetCondos(uint256 tokenId) public view returns (uint16[5] memory ids) {
        require(tokenExists(tokenId), "Nonexistent Token");
        Street storage street = directory[tokenId];
        ids = street.condos;
    }

    /* Minting Helpers */

    function _mint(address to) internal returns (uint256 tokenId) {
        if (availableIds.length > 0) {
            tokenId = availableIds[availableIds.length - 1];
            availableIds.pop();
        } else {
            tokenId = totalSupply;
        }
        TokensByOwner[to].push(tokenId);
        OwnerTokenIndex[tokenId] = uint16(TokensByOwner[to].length);
        Owners[tokenId] = to;
        totalSupply++;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _approve(address(0), tokenId);
        address from = Owners[tokenId];
        uint16 valueIndex = OwnerTokenIndex[tokenId];
        uint256 toDeleteIndex = valueIndex - 1;
        uint256 lastIndex = TokensByOwner[from].length - 1;
        if (lastIndex != toDeleteIndex) {
            uint256 lastTokenId = TokensByOwner[from][lastIndex];
            TokensByOwner[from][toDeleteIndex] = lastTokenId;
            OwnerTokenIndex[lastTokenId] = valueIndex;
        }
        TokensByOwner[from].pop();
        Owners[tokenId] = address(0);

        totalSupply--;
        availableIds.push(uint16(tokenId));

        emit Transfer(from, address(0), tokenId);
    }

    /* ERC-721 Metadata */

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(tokenExists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (Metadata.revealed()) {
            return Metadata.streetMetadata(tokenId);
        } else {
            // Show unrevealed json
            return Metadata.STREETS_PREREVEAL_URI();
        }
    }

    function tokenImage(uint256 tokenId) public view returns (string memory) {
        require(tokenExists(tokenId), "Nonexistent Token");
        if (Metadata.revealed()) {
            return assembleSVG(directory[tokenId].condos, directory[tokenId].background);
        } else {
            // Show no image
            return "";
        }
    }

    function getStreetData(uint256 tokenId) public view returns (uint16[5] memory condoIds, uint16 background, bytes20 name) {
        require(tokenExists(tokenId), "Nonexistent Token");
        Street storage street = directory[tokenId];
        condoIds = street.condos;
        background = street.background;
        name = street.name;
    }

    /* ERC-721 Enumerable */

    function tokenByIndex(uint256 tokenId) public view returns (uint256) {
        require(tokenExists(tokenId), "Nonexistent Token");
        return tokenId;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return TokensByOwner[owner][index];
    }

    /* ERC 721 */

    function tokenExists(uint256 tokenId) public view returns (bool) {
        return Owners[tokenId] != address(0);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(tokenExists(tokenId), "ERC721: Nonexistent token");
        return Owners[tokenId];
    }

    function balanceOf(address owner) public view returns (uint256) {
        return TokensByOwner[owner].length;
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    function _approve(address to, uint256 tokenId) internal {
        TokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(tokenExists(tokenId), "ERC721: approved query for nonexistent token");
        return TokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return OperatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) external virtual {
        require(msg.sender != operator, "ERC721: approve to caller");
        OperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
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

    function _transfer(address from, address to, uint256 tokenId) private whenNotPaused {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint16 valueIndex = OwnerTokenIndex[tokenId];
        uint256 toDeleteIndex = valueIndex - 1;
        uint256 lastIndex = TokensByOwner[from].length - 1;
        if (lastIndex != toDeleteIndex) {
            uint256 lastTokenId = TokensByOwner[from][lastIndex];
            TokensByOwner[from][toDeleteIndex] = lastTokenId;
            OwnerTokenIndex[lastTokenId] = valueIndex;
        }
        TokensByOwner[from].pop();

        TokensByOwner[to].push(tokenId);
        OwnerTokenIndex[tokenId] = uint16(TokensByOwner[to].length);

        Owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(tokenExists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) private {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Claim ENS reverse-resolver rights for this contract.
     * https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
     */
    function setReverseResolver(address registrar) public onlyOwner {
        IReverseResolver(registrar).claim(msg.sender);
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public virtual onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /* SVG Assembly */

    IMoonCatSVGS MoonCatSVGS = IMoonCatSVGS(0xB39C61fe6281324A23e079464f7E697F8Ba6968f);

    /**
     * @dev Assemble one png layer of the SVG composite
     */
    function svgLayer(uint16 condoId, uint16 posX) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                '<image x="',
                MoonCatSVGS.uint2str(posX),
                '" y="104" width="385" height="385" href="',
                Metadata.IPFS_URI_Prefix(),
                Metadata.CONDOS_IPFS_CID(),
                "/",
                MoonCatSVGS.uint2str(condoId),
                '.png" />'
            );
    }

    /**
     * @dev Assemble the full SVG image for a street
     */
    function assembleSVG(uint16[5] memory condoIds, uint16 background) internal view returns (string memory) {
        bytes memory svg = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid meet" viewBox="0 0 1500 500" width="1500" height="500">';

        svg = abi.encodePacked(
            svg,
            '<image x="0" y="0" width="1500" height="500" href="',
            Metadata.IPFS_URI_Prefix(),
            Metadata.BACKGROUNDS_IPFS_CID(),
            "/",
            MoonCatSVGS.uint2str(background),
            '.jpg" />'
        );

        uint16 posX = 0;

        for (uint i = 0; i < 5; i++) {
            svg = abi.encodePacked(svg, svgLayer(condoIds[i], posX));
            posX = posX + 279;
        }

        return string(abi.encodePacked(svg, "</svg>"));
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