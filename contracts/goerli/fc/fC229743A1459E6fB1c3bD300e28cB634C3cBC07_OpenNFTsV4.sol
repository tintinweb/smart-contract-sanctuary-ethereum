// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address currentOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC2981 {
    function royaltyInfo(uint256 tokenID, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenNFTsV4 {
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        bool[] memory options
    ) external;

    function mint(string memory jsonURI) external returns (uint256 tokenID);

    function mint(address minter, string memory jsonURI) external returns (uint256 tokenID);

    function burn(uint256 tokenID) external;

    function buy(uint256 tokenID) external payable;

    function withdraw(address to) external;

    function withdrawErc20(address token) external;

    function open() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenPausable {
    event SetPaused(bool indexed paused, address indexed account);

    function paused() external returns (bool);

    function togglePause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenPriceable {
    event SetDefaultRoyalty(address receiver, uint96 fee);

    event SetTokenRoyalty(uint256 tokenID, address receiver, uint96 fee);

    function tokenPrice(uint256 tokenID) external returns (uint256 price);

    function setDefaultRoyalty(address receiver, uint96 fee) external;

    function setTokenRoyalty(
        uint256 tokenID,
        address receiver,
        uint96 fee
    ) external;

    function setDefaultPrice(uint256 price) external;

    function setTokenPrice(uint256 tokenID) external;

    function setTokenPrice(uint256 tokenID, uint256 price) external;
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/utils/introspection/ERC165.sol
//
//                OpenERC165
//

pragma solidity 0.8.9;

import "../interfaces/IERC165.sol";

abstract contract OpenERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7;
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (access/Ownable.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/access/Ownable.sol

//
//                OpenERC165
//                     |
//                OpenERC721
//                     |
//                OpenERC173
//

pragma solidity 0.8.9;

import "./OpenERC721.sol";
import "../interfaces/IERC173.sol";

abstract contract OpenERC173 is IERC173, OpenERC721 {
    bool private _openERC173Initialized;
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external override(IERC173) onlyOwner {
        _setOwner(newOwner);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC721) returns (bool) {
        return interfaceId == 0x7f5828d0 || super.supportsInterface(interfaceId);
    }

    function owner() public view override(IERC173) returns (address) {
        return _owner;
    }

    function _initialize(address owner_) internal {
        require(_openERC173Initialized == false, "Init already call");
        _openERC173Initialized = true;

        _setOwner(owner_);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (token/common/ERC2981.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/common/ERC2981.sol

//
//                OpenERC165
//                     |
//                OpenERC721
//                     |
//                OpenERC173
//                     |
//                OpenERC2981
//

pragma solidity 0.8.9;

import "./OpenERC173.sol";
import "../interfaces/IERC2981.sol";

abstract contract OpenERC2981 is IERC2981, OpenERC173 {
    struct RoyaltyInfo {
        address receiver;
        uint96 fraction;
    }

    RoyaltyInfo internal _royaltyInfo;
    mapping(uint256 => RoyaltyInfo) internal _tokenRoyaltyInfo;

    uint96 internal constant _MAX_FEE = 10000;

    function royaltyInfo(uint256 tokenID, uint256 salePrice)
        public
        view
        override(IERC2981)
        returns (address receiver, uint256 royaltyAmount)
    {
        /// otherwise may overflow
        require(salePrice < 2**128, "Too expensive");

        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenID];

        if (royalty.receiver == address(0)) {
            royalty = _royaltyInfo;
        }

        royaltyAmount = (salePrice * royalty.fraction) / _MAX_FEE;

        return (royalty.receiver, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC173) returns (bool) {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (token/ERC721/ERC721.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721/ERC721.sol

//
//                OpenERC165
//                     |
//                OpenERC721
//

pragma solidity 0.8.9;

import "./OpenERC165.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/IERC721TokenReceiver.sol";

abstract contract OpenERC721 is IERC721, OpenERC165 {
    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    modifier onlyTokenOwnerOrApproved(uint256 tokenID) {
        require(_isOwnerOrApproved(msg.sender, tokenID), "Not token owner nor approved");
        _;
    }

    function approve(address spender, uint256 tokenID) external override(IERC721) {
        require(_isOwnerOrOperator(msg.sender, tokenID), "Not token owner nor operator");

        _tokenApprovals[tokenID] = spender;
        emit Approval(ownerOf(tokenID), spender, tokenID);
    }

    function setApprovalForAll(address operator, bool approved) external override(IERC721) {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external override(IERC721) {
        _transferFrom(from, to, tokenID);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
    ) external override(IERC721) {
        safeTransferFrom(from, to, tokenID, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) public override(IERC721) {
        _transferFrom(from, to, tokenID);
        require(_isERC721Receiver(from, to, tokenID, data), "Not ERC721Received");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC165) returns (bool) {
        return
            interfaceId == 0x80ac58cd || // = type(IERC721).interfaceId
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override(IERC721) returns (uint256) {
        require(owner != address(0), "Zero address not valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenID) public view override(IERC721) returns (address owner) {
        require((owner = _owners[tokenID]) != address(0), "Invalid token ID");
    }

    function getApproved(uint256 tokenID) public view override(IERC721) returns (address) {
        require(_exists(tokenID), "Invalid token ID");

        return _tokenApprovals[tokenID];
    }

    function isApprovedForAll(address owner, address operator) public view override(IERC721) returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _mintNft(address to, uint256 tokenID) internal {
        require(to != address(0), "Mint to zero address");
        require(!_exists(tokenID), "Token already minted");

        _balances[to] += 1;
        _owners[tokenID] = to;

        emit Transfer(address(0), to, tokenID);
        require(_isERC721Receiver(address(0), to, tokenID, ""), "Not ERC721Received");
    }

    function _burnNft(uint256 tokenID) internal {
        address owner = ownerOf(tokenID);
        assert(_balances[owner] > 0);

        _balances[owner] -= 1;
        delete _tokenApprovals[tokenID];
        delete _owners[tokenID];

        emit Transfer(owner, address(0), tokenID);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenID
    ) internal onlyTokenOwnerOrApproved(tokenID) {
        require(from == ownerOf(tokenID), "From not owner");
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");

        _transferFromBefore(from, to, tokenID);

        delete _tokenApprovals[tokenID];

        if (from != to) {
            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenID] = to;
        }

        emit Transfer(from, to, tokenID);
    }

    function _transferFromBefore(
        address from,
        address to,
        uint256 tokenID
    ) internal virtual;

    function _exists(uint256 tokenID) internal view returns (bool) {
        return _owners[tokenID] != address(0);
    }

    function _isOwnerOrOperator(address spender, uint256 tokenID) internal view virtual returns (bool) {
        address owner = ownerOf(tokenID);
        return (owner == spender || isApprovedForAll(owner, spender));
    }

    function _isOwnerOrApproved(address spender, uint256 tokenID) internal view returns (bool) {
        return (_isOwnerOrOperator(spender, tokenID) || getApproved(tokenID) == spender);
    }

    function _isERC721Receiver(
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) private returns (bool) {
        return
            to.code.length == 0 ||
            IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenID, data) ==
            IERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (token/ERC721/extensions/ERC721Enumerable.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/...
// ...contracts/token/ERC721/extensions/ERC721Enumerable.sol

//
//                OpenERC165
//                     |
//                OpenERC721
//                     |
//            OpenERC721Enumerable
//

pragma solidity 0.8.9;

import "./OpenERC721.sol";
import "../interfaces/IERC721Enumerable.sol";

abstract contract OpenERC721Enumerable is IERC721Enumerable, OpenERC721 {
    // Array of all tokens ID
    uint256[] private _allTokens;

    // Mapping from owner to list of token IDs owned
    // mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to owned index
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Mapping from token ID to all index
    mapping(uint256 => uint256) private _allTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        override(IERC721Enumerable)
        returns (uint256)
    {
        require(index < OpenERC721.balanceOf(owner), "Invalid index!");
        return _ownedTokens[owner][index];
    }

    function totalSupply() external view override(IERC721Enumerable) returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) external view override(IERC721Enumerable) returns (uint256) {
        require(index < _allTokens.length, "Invalid index!");
        return _allTokens[index];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC721) returns (bool) {
        return interfaceId == 0x780e9d63 || super.supportsInterface(interfaceId);
    }

    function _mintEnumerable(address to, uint256 tokenID) internal {
        _addOwnedToken(to, tokenID);

        _allTokensIndex[tokenID] = _allTokens.length;
        _allTokens.push(tokenID);
    }

    function _burnEnumerable(uint256 tokenID) internal {
        address from = ownerOf(tokenID);

        _removeOwnedToken(from, tokenID);

        uint256 allBurnIndex = _allTokensIndex[tokenID];
        uint256 allLastIndex = _allTokens.length - 1;
        uint256 allLastTokenId = _allTokens[allLastIndex];

        _allTokensIndex[allLastTokenId] = allBurnIndex;
        delete _allTokensIndex[tokenID];

        _allTokens[allBurnIndex] = allLastTokenId;
        _allTokens.pop();
    }

    function _transferFromBefore(
        address from,
        address to,
        uint256 tokenID
    ) internal virtual override(OpenERC721) {
        _removeOwnedToken(from, tokenID);
        _addOwnedToken(to, tokenID);
    }

    function _addOwnedToken(address owner, uint256 tokenID) private {
        _ownedTokensIndex[tokenID] = _ownedTokens[owner].length;
        _ownedTokens[owner].push(tokenID);
    }

    function _removeOwnedToken(address owner, uint256 tokenID) private {
        uint256 burnIndex = _ownedTokensIndex[tokenID];
        uint256 lastIndex = OpenERC721.balanceOf(owner) - 1;

        if (burnIndex != lastIndex) {
            uint256 lastTokenId = _ownedTokens[owner][lastIndex];
            _ownedTokens[owner][burnIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = burnIndex;
        }

        delete _ownedTokensIndex[tokenID];
        _ownedTokens[owner].pop();
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (token/ERC721/ERC721.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721/ERC721.sol

//
//                OpenERC165
//                     |
//                OpenERC721
//                     |
//            OpenERC721Metadata
//

pragma solidity 0.8.9;

import "./OpenERC721.sol";
import "../interfaces/IERC721Metadata.sol";

abstract contract OpenERC721Metadata is IERC721Metadata, OpenERC721 {
    bool private _openERC721MetadataInitialized;
    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;

    function name() external view virtual override(IERC721Metadata) returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override(IERC721Metadata) returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenID) external view virtual override(IERC721Metadata) returns (string memory) {
        return _tokenURIs[tokenID];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC721) returns (bool) {
        return interfaceId == 0x5b5e139f || super.supportsInterface(interfaceId);
    }

    function _initialize(string memory name_, string memory symbol_) internal {
        require(_openERC721MetadataInitialized == false, "Only once!");
        _openERC721MetadataInitialized = true;

        _name = name_;
        _symbol = symbol_;
    }

    function _mintMetadata(uint256 tokenID, string memory newTokenURI) internal {
        _tokenURIs[tokenID] = newTokenURI;
    }

    function _burnMetadata(uint256 tokenID) internal {
        delete _tokenURIs[tokenID];
    }
}

// SPDX-License-Identifier: MIT
//
//       ___           ___           ___          _____          ___           ___           ___
//      /__/|         /  /\         /  /\        /  /::\        /  /\         /__/\         /__/\
//     |  |:|        /  /::\       /  /:/_      /  /:/\:\      /  /:/_        \  \:\       |  |::\
//     |  |:|       /  /:/\:\     /  /:/ /\    /  /:/  \:\    /  /:/ /\        \  \:\      |  |:|:\
//   __|  |:|      /  /:/~/:/    /  /:/ /:/_  /__/:/ \__\:|  /  /:/ /:/_   ___  \  \:\   __|__|:|\:\
//  /__/\_|:|____ /__/:/ /:/___ /__/:/ /:/ /\ \  \:\ /  /:/ /__/:/ /:/ /\ /__/\  \__\:\ /__/::::| \:\
//  \  \:\/:::::/ \  \:\/:::::/ \  \:\/:/ /:/  \  \:\  /:/  \  \:\/:/ /:/ \  \:\ /  /:/ \  \:\~~\__\/
//   \  \::/~~~~   \  \::/~~~~   \  \::/ /:/    \  \:\/:/    \  \::/ /:/   \  \:\  /:/   \  \:\
//    \  \:\        \  \:\        \  \:\/:/      \  \::/      \  \:\/:/     \  \:\/:/     \  \:\
//     \  \:\        \  \:\        \  \::/        \__\/        \  \::/       \  \::/       \  \:\
//      \__\/         \__\/         \__\/                       \__\/         \__\/         \__\/
//       ___           ___         ___           ___                    ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\                  /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\                 \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\                 \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\            _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\          /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/          \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~            \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\                 \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\                 \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/                  \__\/         \__\/                   \__\/
//
//
//                         OpenERC165 (supports)
//                             |
//                         OpenERC721 (NFT)
//                             |
//                     ——————————————————————————————————————————————
//                     |                       |                    |
//                OpenERC173          OpenERC721Metadata  OpenERC721Enumerable
//                 (Ownable)                   |                    |
//                     |                       |                    |
//              ————————————————               |                    |
//              |              |               |                    |
//         OpenERC2981     OpenPausable        |                    |
//        (RoyaltyInfo)        |               |                    |
//              |              |               |                    |
//              ————————————————               |                    |
//                     |                       |                    |
//               OpenPriceable                 |                    |
//                     |                       |                    |
//                     ——————————————————————————————————————————————
//                                |
//                            OpenNFTsV4
//

pragma solidity 0.8.9;

import "./OpenPriceable.sol";
import "./OpenERC721Enumerable.sol";
import "./OpenERC721Metadata.sol";
import "./OpenERC173.sol";

import "../interfaces/IOpenNFTsV4.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC2981.sol";

/// @title OpenNFTs smartcontract
contract OpenNFTsV4 is IOpenNFTsV4, OpenERC721Metadata, OpenERC721Enumerable, OpenPriceable {
    /// event priceHistory

    /// @notice tokenID of next minted NFT
    uint256 public tokenIdNext = 1;

    /// @notice Mint NFT allowed to everyone or only collection owner
    bool public open;

    /// @notice onlyOpenOrOwner, either everybody in open collection,
    /// @notice either only owner in specific collection
    modifier onlyOpenOrOwner() {
        require(open || (owner() == msg.sender), "Not minter");
        _;
    }

    /// @notice initialize
    /// @param name_ name of the NFT Collection
    /// @param symbol_ symbol of the NFT Collection
    /// @param owner_ owner of the NFT Collection
    /// @param options select minting open to everyone or only owner
    // solhint-disable-next-line comprehensive-interface
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        bool[] memory options
    ) external {
        OpenERC721Metadata._initialize(name_, symbol_);
        OpenERC173._initialize(owner_);
        open = options[0];
    }

    function mint(string memory jsonURI)
        external
        override(IOpenNFTsV4)
        onlyOpenOrOwner
        onlyWhenNotPaused
        returns (uint256)
    {
        return _mint(msg.sender, jsonURI);
    }

    function mint(address to, string memory jsonURI) external override(IOpenNFTsV4) onlyOwner returns (uint256) {
        return _mint(to, jsonURI);
    }

    /// @notice burn NFT
    /// @param tokenID tokenID of NFT to burn
    function burn(uint256 tokenID) external override(IOpenNFTsV4) onlyTokenOwnerOrApproved(tokenID) {
        _burn(tokenID);
    }

    function withdraw(address to) external override(IOpenNFTsV4) onlyOwner {
        require(to != address(0), "Don't throw your money !");
        payable(to).transfer(address(this).balance);
    }

    function withdrawErc20(address token) external override(IOpenNFTsV4) onlyOwner {
        require(IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this))), "Withdraw failed");
    }

    function buy(uint256 tokenID) external payable override(IOpenNFTsV4) {
        /// Get token price
        uint256 price = tokenPrice[tokenID];

        /// Require price defined
        require(price > 0, "Not to sell");

        /// Require enough value sent
        require(msg.value >= price, "Not enough funds");

        /// Get previous token owner
        address from = ownerOf(tokenID);
        assert(from != address(0));
        require(from != msg.sender, "Already token owner!");

        /// Reset token price (to be eventualy defined by new owner)
        delete tokenPrice[tokenID];

        /// Transfer token
        this.safeTransferFrom(from, msg.sender, tokenID);

        (address receiver, uint256 royalties) = royaltyInfo(tokenID, price);

        assert(price >= royalties);
        uint256 paid = price - royalties;
        uint256 unspent = msg.value - price;
        assert(paid + royalties + unspent == msg.value);

        /// Transfer amount to previous owner
        payable(from).transfer(paid);

        /// Transfer royalties to receiver
        if (royalties > 0) payable(receiver).transfer(royalties);

        /// Transfer back unspent funds to sender
        if (unspent > 0) payable(msg.sender).transfer(unspent);
    }

    /// @notice test if this interface is supported
    /// @param interfaceId interfaceId to test
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(OpenPriceable, OpenERC721Metadata, OpenERC721Enumerable)
        returns (bool)
    {
        return interfaceId == type(IOpenNFTsV4).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice _mint
    /// @param minter address of minter
    /// @param jsonURI json URI of NFT metadata
    function _mint(address minter, string memory jsonURI) internal returns (uint256 tokenID) {
        tokenID = tokenIdNext++;

        _mintMetadata(tokenID, jsonURI);
        _mintEnumerable(minter, tokenID);
        _mintNft(minter, tokenID);
    }

    function _burn(uint256 tokenID) internal {
        _burnPriceable(tokenID);
        _burnMetadata(tokenID);
        _burnEnumerable(tokenID);
        _burnNft(tokenID);
    }

    function _transferFromBefore(
        address from,
        address to,
        uint256 tokenID
    ) internal override(OpenERC721, OpenERC721Enumerable) {
        OpenERC721Enumerable._transferFromBefore(from, to, tokenID);
    }
}

// SPDX-License-Identifier: MIT
//
//       ___           ___           ___          _____          ___           ___           ___
//      /__/|         /  /\         /  /\        /  /::\        /  /\         /__/\         /__/\
//     |  |:|        /  /::\       /  /:/_      /  /:/\:\      /  /:/_        \  \:\       |  |::\
//     |  |:|       /  /:/\:\     /  /:/ /\    /  /:/  \:\    /  /:/ /\        \  \:\      |  |:|:\
//   __|  |:|      /  /:/~/:/    /  /:/ /:/_  /__/:/ \__\:|  /  /:/ /:/_   ___  \  \:\   __|__|:|\:\
//  /__/\_|:|____ /__/:/ /:/___ /__/:/ /:/ /\ \  \:\ /  /:/ /__/:/ /:/ /\ /__/\  \__\:\ /__/::::| \:\
//  \  \:\/:::::/ \  \:\/:::::/ \  \:\/:/ /:/  \  \:\  /:/  \  \:\/:/ /:/ \  \:\ /  /:/ \  \:\~~\__\/
//   \  \::/~~~~   \  \::/~~~~   \  \::/ /:/    \  \:\/:/    \  \::/ /:/   \  \:\  /:/   \  \:\
//    \  \:\        \  \:\        \  \:\/:/      \  \::/      \  \:\/:/     \  \:\/:/     \  \:\
//     \  \:\        \  \:\        \  \::/        \__\/        \  \::/       \  \::/       \  \:\
//      \__\/         \__\/         \__\/                       \__\/         \__\/         \__\/
//
//
//                OpenERC165
//                     |
//                OpenERC721
//                     |
//                OpenERC173
//                     |
//               OpenPausable
//

pragma solidity 0.8.9;

import "./OpenERC173.sol";
import "../interfaces/IOpenPausable.sol";

abstract contract OpenPausable is IOpenPausable, OpenERC173 {
    bool private _paused;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Paused!");
        _;
    }

    function togglePause() external override(IOpenPausable) onlyOwner {
        _setPaused(!_paused);
    }

    function paused() external view override(IOpenPausable) returns (bool) {
        return _paused;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC173) returns (bool) {
        return interfaceId == type(IOpenPausable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _setPaused(bool paused_) private {
        _paused = paused_;
        emit SetPaused(_paused, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
//

//       ___           ___           ___          _____          ___           ___           ___
//      /__/|         /  /\         /  /\        /  /::\        /  /\         /__/\         /__/\
//     |  |:|        /  /::\       /  /:/_      /  /:/\:\      /  /:/_        \  \:\       |  |::\
//     |  |:|       /  /:/\:\     /  /:/ /\    /  /:/  \:\    /  /:/ /\        \  \:\      |  |:|:\
//   __|  |:|      /  /:/~/:/    /  /:/ /:/_  /__/:/ \__\:|  /  /:/ /:/_   ___  \  \:\   __|__|:|\:\
//  /__/\_|:|____ /__/:/ /:/___ /__/:/ /:/ /\ \  \:\ /  /:/ /__/:/ /:/ /\ /__/\  \__\:\ /__/::::| \:\
//  \  \:\/:::::/ \  \:\/:::::/ \  \:\/:/ /:/  \  \:\  /:/  \  \:\/:/ /:/ \  \:\ /  /:/ \  \:\~~\__\/
//   \  \::/~~~~   \  \::/~~~~   \  \::/ /:/    \  \:\/:/    \  \::/ /:/   \  \:\  /:/   \  \:\
//    \  \:\        \  \:\        \  \:\/:/      \  \::/      \  \:\/:/     \  \:\/:/     \  \:\
//     \  \:\        \  \:\        \  \::/        \__\/        \  \::/       \  \::/       \  \:\
//      \__\/         \__\/         \__\/                       \__\/         \__\/         \__\/
//
//
//                OpenERC165 (supports)
//                     |
//                OpenERC721 (NFT)
//                     |
//                OpenERC173 (Ownable)
//                     |
//                OpenERC2981 (RoyaltyInfo)
//                     |
//               OpenPriceable
//

pragma solidity 0.8.9;

import "./OpenERC2981.sol";
import "./OpenPausable.sol";
import "../interfaces/IOpenPriceable.sol";

abstract contract OpenPriceable is IOpenPriceable, OpenERC2981, OpenPausable {
    mapping(uint256 => uint256) public tokenPrice;
    uint256 public defaultPrice;

    modifier notTooExpensive(uint256 price) {
        /// otherwise may overflow
        require(price < 2**128, "Too expensive");
        _;
    }

    modifier lessThanMaxFee(uint256 fee) {
        require(fee <= _MAX_FEE, "Royalty fee exceed price");
        _;
    }

    /// @notice SET default royalty configuration
    /// @param receiver : address of the royalty receiver, or address(0) to reset
    /// @param fee : fee Numerator, less than 10000
    function setDefaultRoyalty(address receiver, uint96 fee)
        external
        override(IOpenPriceable)
        onlyOwner
        lessThanMaxFee(fee)
    {
        _royaltyInfo = RoyaltyInfo(receiver, fee);
        emit SetDefaultRoyalty(receiver, fee);
    }

    /// @notice SET token royalty configuration
    /// @param tokenID : token ID
    /// @param receiver : address of the royalty receiver, or address(0) to reset
    /// @param fee : fee Numerator, less than 10000
    function setTokenRoyalty(
        uint256 tokenID,
        address receiver,
        uint96 fee
    ) external override(IOpenPriceable) onlyTokenOwnerOrApproved(tokenID) lessThanMaxFee(fee) {
        _setTokenRoyalty(tokenID, receiver, fee);
    }

    function setDefaultPrice(uint256 price) external override(IOpenPriceable) onlyOwner notTooExpensive(price) {
        defaultPrice = price;
    }

    function setTokenPrice(uint256 tokenID) external override(IOpenPriceable) {
        setTokenPrice(tokenID, defaultPrice);
    }

    function setTokenPrice(uint256 tokenID, uint256 price)
        public
        override(IOpenPriceable)
        onlyTokenOwnerOrApproved(tokenID)
        notTooExpensive(price)
    {
        _setTokenPrice(tokenID, price);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OpenERC2981, OpenPausable)
        returns (bool)
    {
        return interfaceId == type(IOpenPriceable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _setTokenRoyalty(
        uint256 tokenID,
        address receiver,
        uint96 fee
    ) internal {
        _tokenRoyaltyInfo[tokenID] = RoyaltyInfo(receiver, fee);
        emit SetTokenRoyalty(tokenID, receiver, fee);
    }

    function _setTokenPrice(uint256 tokenID, uint256 price) internal {
        tokenPrice[tokenID] = price;
    }

    function _mintPriceable(
        uint256 tokenID,
        address receiver,
        uint96 fee,
        uint256 price
    ) internal {
        _setTokenRoyalty(tokenID, receiver, fee);
        _setTokenPrice(tokenID, price);
    }

    function _burnPriceable(uint256 tokenID) internal {
        delete _tokenRoyaltyInfo[tokenID];
        delete tokenPrice[tokenID];
    }
}