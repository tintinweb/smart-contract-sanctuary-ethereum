// SPDX-License-Identifier: MIT
//
// EIP-165: Standard Interface Detection
// https://eips.ethereum.org/EIPS/eip-165
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/utils/introspection/ERC165.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165 —— IERC165
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/interfaces/IERC165.sol";

abstract contract OpenERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7; //  type(IERC165).interfaceId
    }
}

// SPDX-License-Identifier: MIT
//
// EIP-173: Contract Ownership Standard
// https://eips.ethereum.org/EIPS/eip-173
//
// Derived from OpenZeppelin Contracts (access/Ownable.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/access/Ownable.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165
//       |
//  OpenERC173 —— IERC173
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";
import "OpenNFTs/contracts/interfaces/IERC173.sol";

abstract contract OpenERC173 is IERC173, OpenERC165 {
    bool private _openERC173Initialized;
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, "Not owner");
        _;
    }

    function transferOwnership(address newOwner) external override(IERC173) onlyOwner {
        _setOwner(newOwner);
    }

    function owner() public view override(IERC173) returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC165) returns (bool) {
        return interfaceId == 0x7f5828d0 || super.supportsInterface(interfaceId);
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
// EIP-721: Non-Fungible Token Standard
// https://eips.ethereum.org/EIPS/eip-721
//
// Derived from OpenZeppelin Contracts (token/ERC721/ERC721.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC721/ERC721.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//  OpenERC165
//       |
//  OpenERC721 —— IERC721
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";
import "OpenNFTs/contracts/interfaces/IERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC721TokenReceiver.sol";

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

    function approve(address spender, uint256 tokenID) external payable override(IERC721) {
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
    ) external payable override(IERC721) {
        _transferFrom(from, to, tokenID);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) external payable override(IERC721) {
        _transferFrom(from, to, tokenID);
        require(_isERC721Receiver(from, to, tokenID, data), "Not ERC721Received");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenID
    ) public payable override(IERC721) {
        _safeTransferFrom(from, to, tokenID, "");
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC165) returns (bool) {
        return
            interfaceId == 0x80ac58cd || // = type(IERC721).interfaceId
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override(IERC721) returns (uint256) {
        require(owner != address(0), "Invalid zero address");
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

    function _mint(
        address to,
        string memory,
        uint256 tokenID
    ) internal virtual {
        require(to != address(0), "Mint to zero address");
        require(!_exists(tokenID), "Token already minted");

        _balances[to] += 1;
        _owners[tokenID] = to;

        emit Transfer(address(0), to, tokenID);
        require(_isERC721Receiver(address(0), to, tokenID, ""), "Not ERC721Received");
    }

    function _burn(uint256 tokenID) internal virtual {
        address owner = ownerOf(tokenID);
        assert(_balances[owner] > 0);

        _balances[owner] -= 1;
        delete _tokenApprovals[tokenID];
        delete _owners[tokenID];

        emit Transfer(owner, address(0), tokenID);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenID,
        bytes memory data
    ) private {
        _transferFrom(from, to, tokenID);

        require(_isERC721Receiver(from, to, tokenID, data), "Not ERC721Receiver");
    }

    function _transferFrom(
        address from,
        address to,
        uint256 tokenID
    ) private onlyTokenOwnerOrApproved(tokenID) {
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
    ) internal virtual {}

    function _exists(uint256 tokenID) internal view returns (bool exists) {
        exists = _owners[tokenID] != address(0);
    }

    function _isOwnerOrOperator(address spender, uint256 tokenID) internal view virtual returns (bool ownerOrOperator) {
        address tokenOwner = ownerOf(tokenID);
        ownerOrOperator = (tokenOwner == spender || isApprovedForAll(tokenOwner, spender));
    }

    function _isOwnerOrApproved(address spender, uint256 tokenID) private view returns (bool ownerOrApproved) {
        ownerOrApproved = (_isOwnerOrOperator(spender, tokenID) || (getApproved(tokenID) == spender));
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
// Derived from Kredeum NFTs
// https://github.com/Kredeum/kredeum
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//  OpenCloneable —— IOpenCloneable
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/interfaces/IOpenCloneable.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";

abstract contract OpenCloneable is IOpenCloneable, OpenERC165 {
    bool private _openCloneableInitialized;
    string private _template;
    uint256 private _version;

    function getTemplate() external view override(IOpenCloneable) returns (string memory) {
        return _template;
    }

    function getVersion() external view override(IOpenCloneable) returns (uint256) {
        return _version;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC165) returns (bool) {
        return interfaceId == type(IOpenCloneable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _initialize(string memory template_, uint256 version_) internal {
        require(_openCloneableInitialized == false, "Only once!");
        _openCloneableInitialized = true;

        _template = template_;
        _version = version_;
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (token/common/ERC2981.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/Pausable.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//   OpenERC173
//        |
//  OpenPauseable –– IOpenPauseable
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC173.sol";
import "OpenNFTs/contracts/interfaces/IOpenPauseable.sol";

abstract contract OpenPauseable is IOpenPauseable, OpenERC173 {
    bool private _paused;

    modifier onlyWhenNotPaused() {
        require(!_paused, "Paused!");
        _;
    }

    function togglePause() external override(IOpenPauseable) onlyOwner {
        _setPaused(!_paused);
    }

    function paused() external view override(IOpenPauseable) returns (bool) {
        return _paused;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC173) returns (bool) {
        return interfaceId == type(IOpenPauseable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _setPaused(bool paused_) private {
        _paused = paused_;
        emit SetPaused(_paused, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
//
// Derived from OpenZeppelin Contracts (utils/introspection/ERC165Ckecker.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165Checker.sol
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//  OpenChecker —— IOpenChecker
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC165.sol";
import "OpenNFTs/contracts/interfaces/IOpenChecker.sol";

abstract contract OpenChecker is IOpenChecker, OpenERC165 {
    function checkSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        public
        view
        returns (bool[] memory interfaceIdsChecker)
    {
        interfaceIdsChecker = new bool[](interfaceIds.length);
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            interfaceIdsChecker[i] = IERC165(account).supportsInterface(interfaceIds[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenERC165) returns (bool) {
        return interfaceId == type(IOpenChecker).interfaceId || super.supportsInterface(interfaceId);
    }
}

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

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function approve(address to, uint256 tokenId) external payable;

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
pragma solidity ^0.8.9;

interface IOpenChecker {
    function checkSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        external
        view
        returns (bool[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenCloneable {
    function getTemplate() external view returns (string memory);

    function getVersion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenPauseable {
    event SetPaused(bool indexed paused, address indexed account);

    function paused() external returns (bool);

    function togglePause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Bafkrey {
    bytes32 private constant _BASE32_SYMBOLS = "abcdefghijklmnopqrstuvwxyz234567";

    /// Transfom uint256 to IPFS CID V1 base32 raw (starting with "bafkrei")
    function uint256ToCid(uint256 id) internal pure returns (string memory) {
        // IPFS CID V1 base32 raw "bafrei..." => 5 bits => uint32
        // uint256 id  = 256 bits = 1 bit + 51 uint32 = 1 + 51 * 5 = 256
        // 00 added right =>
        // uint8 + uint256 + 00 = 258 bits = uint8 + 50 uint32 + (3 bits + 00) = uint8 + 51 uint32 = 3 + 51 * 5 = 258

        bytes memory buffer = new bytes(52);
        uint8 high3 = uint8(id >> 253);
        buffer[0] = _BASE32_SYMBOLS[high3 & 0x1f];

        id <<= 2;
        for (uint256 i = 51; i > 0; i--) {
            buffer[i] = _BASE32_SYMBOLS[id & 0x1f];
            id >>= 5;
        }

        return string(abi.encodePacked("bafkrei", buffer));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenBound {
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        uint256 maxSupply
    ) external;

    function mint(uint256 tokenID) external returns (uint256);

    function claim(uint256 tokenID, uint256 cid) external;

    function burn(uint256 tokenID) external;

    function getMyTokenID(uint256 cid) external view returns (uint256);

    function getTokenID(address addr, uint256 cid) external view returns (uint256 tokenID);

    function getCID(uint256 tokenID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOpenNFTs {
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        bool[] memory options
    ) external;

    function mintOpenNFT(address minter, string memory jsonURI) external returns (uint256 tokenID);

    function burnOpenNFT(uint256 tokenID) external;
}

// SPDX-License-Identifier: MIT
//
// Derived from Kredeum NFTs
// https://github.com/Kredeum/kredeum
//
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
//  OpenERC165 (supports)
//      |
//      ———————————————————————————————————————————————
//      |                 |             |             |
//  OpenERC721 (NFT)  OpenERC173  OpenChecker  OpenCloneable
//      |             (ownable)         |             |
//      |                 |             |             |
//      |                 |             |             |
//      |            OpenPauseable      |             |
//      |                 |             |             |
//      ———————————————————————————————————————————————
//      |
//  OpenBound --- IOpenBound --- IERC721Enumerable --- IERC721Metadata
//
pragma solidity ^0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721.sol";
import "OpenNFTs/contracts/OpenNFTs/OpenPauseable.sol";
import "OpenNFTs/contracts/OpenNFTs/OpenCloneable.sol";
import "OpenNFTs/contracts/OpenResolver/OpenChecker.sol";

import "OpenNFTs/contracts/interfaces/IERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC721Enumerable.sol";
import "OpenNFTs/contracts/interfaces/IERC721Metadata.sol";
import "OpenNFTs/contracts/libraries/Bafkrey.sol";

import "../interfaces/IOpenBound.sol";
import {IOpenNFTs as IOpenNFTsOld} from "../interfaces/IOpenNFTs.sol";

/// @title OpenBound smartcontract
/// limited to one nft per address
contract OpenBound is
    IOpenBound,
    IERC721Enumerable,
    IERC721Metadata,
    OpenCloneable,
    OpenChecker,
    OpenPauseable,
    OpenERC721
{
    uint256 public maxSupply;

    string public name;
    string public symbol;

    mapping(address => uint256) internal _tokenOfOwner;
    mapping(address => uint256) internal _tokenIndexOfOwner;
    mapping(uint256 => uint256) internal _cidOfToken;
    uint256[] internal _tokens;

    string private constant _BASE_URI = "ipfs://";

    /// IOpenBound
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 maxSupply_
    ) external override(IOpenBound) {
        OpenCloneable._initialize("OpenBound", 1);
        OpenERC173._initialize(owner_);

        name = name_;
        symbol = symbol_;
        maxSupply = maxSupply_;
    }

    function mint(uint256 cid) external override(IOpenBound) onlyWhenNotPaused returns (uint256 tokenID) {
        tokenID = _mint(msg.sender, cid);
    }

    function claim(uint256 tokenID, uint256 cid) external override(IOpenBound) onlyWhenNotPaused {
        require(tokenID == _tokenID(msg.sender, cid), "Not owner");
        _mint(msg.sender, cid);
    }

    function burn(uint256 tokenID) external override(IOpenBound) {
        address from = ownerOf(tokenID);
        require(from == msg.sender, "Not owner");

        _burn(tokenID);
    }

    function getMyTokenID(uint256 cid) external view override(IOpenBound) returns (uint256 myTokenID) {
        myTokenID = _tokenID(msg.sender, cid);
    }

    function getCID(uint256 tokenID) external view override(IOpenBound) returns (uint256 cid) {
        cid = _cidOfToken[tokenID];
    }

    /// IERC721Enumerable
    function totalSupply() external view override(IERC721Enumerable) returns (uint256 tokensLength) {
        tokensLength = _tokens.length;
    }

    function tokenOfOwnerByIndex(address tokenOwner, uint256 index)
        external
        view
        override(IERC721Enumerable)
        returns (uint256 tokenID)
    {
        require(index == 0 && balanceOf(tokenOwner) == 1, "Invalid index");

        tokenID = _tokenOfOwner[tokenOwner];
    }

    function tokenByIndex(uint256 index) external view override(IERC721Enumerable) returns (uint256 tokenID) {
        require(index < _tokens.length, "Invalid index");

        tokenID = _tokens[index];
    }

    /// IERC721Metadata
    function tokenURI(uint256 tokenID) external view override(IERC721Metadata) returns (string memory) {
        require(_exists(tokenID), "NFT doesn't exists");

        return _tokenURI(_cidOfToken[tokenID]);
    }

    function getTokenID(address addr, uint256 cid) external pure override(IOpenBound) returns (uint256 tokenID) {
        tokenID = _tokenID(addr, cid);
    }

    /// IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(OpenPauseable, OpenCloneable, OpenERC721, OpenChecker)
        returns (bool)
    {
        return
            interfaceId == type(IOpenBound).interfaceId ||
            interfaceId == type(IOpenNFTsOld).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _mint(address to, uint256 cid) internal returns (uint256 tokenID) {
        require((maxSupply == 0) || _tokens.length < maxSupply, "Max supply reached");
        require(balanceOf(to) == 0, "Already minted or claimed");

        tokenID = _tokenID(to, cid);

        _tokens.push(tokenID);
        _tokenOfOwner[to] = tokenID;
        _tokenIndexOfOwner[to] = _tokens.length - 1;
        _cidOfToken[tokenID] = cid;

        _mint(to, _tokenURI(cid), tokenID);
    }

    function _mint(
        address to,
        string memory newTokenURI,
        uint256 tokenID
    ) internal override(OpenERC721) {
        super._mint(to, newTokenURI, tokenID);
    }

    function _burn(uint256 tokenID) internal override(OpenERC721) {
        address from = ownerOf(tokenID);
        uint256 index = _tokenIndexOfOwner[from];
        uint256 lastIndex = _tokens.length - 1;

        if (index != lastIndex) {
            _tokens[index] = _tokens[lastIndex];
            _tokenIndexOfOwner[ownerOf(_tokens[lastIndex])] = index;
        }
        _tokens.pop();

        delete _cidOfToken[tokenID];
        delete _tokenIndexOfOwner[from];
        delete _tokenOfOwner[from];

        super._burn(tokenID);
    }

    function _tokenID(address addr, uint256 cid) internal pure returns (uint256 tokenID) {
        tokenID = uint256(keccak256(abi.encodePacked(cid, addr)));
    }

    function _tokenURI(uint256 cid) internal pure returns (string memory) {
        return string(abi.encodePacked(_BASE_URI, Bafkrey.uint256ToCid(cid)));
    }

    function _transferFromBefore(
        address from,
        address to,
        uint256 // tokenId
    ) internal pure override {
        require(from == address(0) || to == address(0), "Non transferable NFT");
    }
}