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
    bool public initialized;
    string public template;
    uint256 public version;

    function parent() external view override (IOpenCloneable) returns (address parent_) {
        // eip1167 deployed code = 45 bytes = 10 bytes + 20 bytes address + 15 bytes
        // extract bytes 10 to 30: shift 2 bytes (16 bits) then truncate to address 20 bytes (uint160)
        return (address(this).code.length == 45)
            ? address(uint160(uint256(bytes32(address(this).code)) >> 16))
            : address(0);
    }

    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        bytes memory params
    ) public virtual override (IOpenCloneable);

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == type(IOpenCloneable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function _initialize(string memory template_, uint256 version_) internal {
        require(initialized == false, "Already initialized");
        initialized = true;

        template = template_;
        version = version_;
    }
}

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

    function transferOwnership(address newOwner) external override (IERC173) onlyOwner {
        _transferOwnership(newOwner);
    }

    function owner() public view override (IERC173) returns (address) {
        return _owner;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == 0x7f5828d0 || super.supportsInterface(interfaceId);
    }

    function _initialize(address owner_) internal {
        require(_openERC173Initialized == false, "Already initialized");
        _openERC173Initialized = true;

        _transferOwnership(owner_);
    }

    function _transferOwnership(address newOwner) internal {
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

    modifier existsToken(uint256 tokenID) {
        require(_owners[tokenID] != address(0), "Invalid token ID");
        _;
    }

    function transferFrom(address from, address to, uint256 tokenID)
        external
        payable
        override (IERC721)
    {
        _transferFrom(from, to, tokenID);
    }

    function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory data)
        external
        payable
        override (IERC721)
    {
        _safeTransferFrom(from, to, tokenID, data);
    }

    function approve(address spender, uint256 tokenID) public override (IERC721) {
        require(_isOwnerOrOperator(msg.sender, tokenID), "Not token owner nor operator");

        _tokenApprovals[tokenID] = spender;
        emit Approval(ownerOf(tokenID), spender, tokenID);
    }

    function setApprovalForAll(address operator, bool approved) public override (IERC721) {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenID)
        public
        payable
        override (IERC721)
    {
        _safeTransferFrom(from, to, tokenID, "");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == 0x80ac58cd // = type(IERC721).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override (IERC721) returns (uint256) {
        require(owner != address(0), "Invalid zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenID)
        public
        view
        override (IERC721)
        existsToken(tokenID)
        returns (address)
    {
        return _owners[tokenID];
    }

    function getApproved(uint256 tokenID)
        public
        view
        override (IERC721)
        existsToken(tokenID)
        returns (address)
    {
        return _tokenApprovals[tokenID];
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override (IERC721)
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function _mint(address to, string memory, uint256 tokenID) internal virtual {
        require(to != address(0), "Mint to zero address");
        require(_owners[tokenID] == address(0), "Token already minted");

        _balances[to] += 1;
        _owners[tokenID] = to;

        emit Transfer(address(0), to, tokenID);
        require(_isERC721Receiver(address(0), to, tokenID, ""), "Not ERC721Received");
    }

    function _burn(uint256 tokenID) internal virtual {
        address owner = ownerOf(tokenID);
        require(owner != address(0), "Invalid token ID");

        assert(_balances[owner] > 0);

        _balances[owner] -= 1;
        delete _tokenApprovals[tokenID];
        delete _owners[tokenID];

        emit Transfer(owner, address(0), tokenID);
    }

    function _transferFromBefore(address from, address to, uint256 tokenID) internal virtual {}

    function _isOwnerOrOperator(address spender, uint256 tokenID)
        internal
        view
        virtual
        returns (bool ownerOrOperator)
    {
        address tokenOwner = ownerOf(tokenID);
        ownerOrOperator = (tokenOwner == spender || isApprovedForAll(tokenOwner, spender));
    }

    function _safeTransferFrom(address from, address to, uint256 tokenID, bytes memory data)
        private
    {
        _transferFrom(from, to, tokenID);

        require(_isERC721Receiver(from, to, tokenID, data), "Not ERC721Receiver");
    }

    function _transferFrom(address from, address to, uint256 tokenID)
        private
        onlyTokenOwnerOrApproved(tokenID)
    {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        require(from == ownerOf(tokenID), "From not owner");

        _transferFromBefore(from, to, tokenID);

        delete _tokenApprovals[tokenID];

        if (from != to) {
            _balances[from] -= 1;
            _balances[to] += 1;
            _owners[tokenID] = to;
        }

        emit Transfer(from, to, tokenID);
    }

    function _isERC721Receiver(address from, address to, uint256 tokenID, bytes memory data)
        private
        returns (bool)
    {
        return to.code.length == 0
            || IERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenID, data)
                == IERC721TokenReceiver.onERC721Received.selector;
    }

    function _isOwnerOrApproved(address spender, uint256 tokenID)
        private
        view
        returns (bool ownerOrApproved)
    {
        ownerOrApproved =
            (_isOwnerOrOperator(spender, tokenID) || (getApproved(tokenID) == spender));
    }
}

// SPDX-License-Identifier: MIT
//
// EIP-721: Non-Fungible Token Standard
// https://eips.ethereum.org/EIPS/eip-721
//
// Derived from OpenZeppelin Contracts (token/ERC721/extensions/ERC721Enumerable.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/...
// ...contracts/token/ERC721/extensions/ERC721Enumerable.sol
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
//      OpenERC165
//           |
//      OpenERC721
//           |
//  OpenERC721Enumerable —— IERC721Enumerable
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC721Enumerable.sol";

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
        override (IERC721Enumerable)
        returns (uint256)
    {
        require(index < OpenERC721.balanceOf(owner), "Invalid index!");
        return _ownedTokens[owner][index];
    }

    function totalSupply() external view override (IERC721Enumerable) returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index)
        external
        view
        override (IERC721Enumerable)
        returns (uint256)
    {
        require(index < _allTokens.length, "Invalid index!");
        return _allTokens[index];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC721)
        returns (bool)
    {
        return interfaceId == 0x780e9d63 || super.supportsInterface(interfaceId);
    }

    function _mint(address to, string memory tokenURI, uint256 tokenID)
        internal
        virtual
        override (OpenERC721)
    {
        _addOwnedToken(to, tokenID);

        _allTokensIndex[tokenID] = _allTokens.length;
        _allTokens.push(tokenID);

        super._mint(to, tokenURI, tokenID);
    }

    function _burn(uint256 tokenID) internal virtual override (OpenERC721) {
        address from = ownerOf(tokenID);

        _removeOwnedToken(from, tokenID);

        uint256 allBurnIndex = _allTokensIndex[tokenID];
        uint256 allLastIndex = _allTokens.length - 1;
        uint256 allLastTokenId = _allTokens[allLastIndex];

        _allTokensIndex[allLastTokenId] = allBurnIndex;
        delete _allTokensIndex[tokenID];

        _allTokens[allBurnIndex] = allLastTokenId;
        _allTokens.pop();

        super._burn(tokenID);
    }

    function _transferFromBefore(address from, address to, uint256 tokenID)
        internal
        virtual
        override (OpenERC721)
    {
        _removeOwnedToken(from, tokenID);
        _addOwnedToken(to, tokenID);

        super._transferFromBefore(from, to, tokenID);
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
//     OpenERC165
//          |
//     OpenERC721
//          |
//  OpenERC721Metadata —— IERC721Metadata
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC721Metadata.sol";

abstract contract OpenERC721Metadata is IERC721Metadata, OpenERC721 {
    bool private _openERC721MetadataInitialized;
    string private _name;
    string private _symbol;
    mapping(uint256 => string) private _tokenURIs;

    function name() external view virtual override (IERC721Metadata) returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override (IERC721Metadata) returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenID)
        external
        view
        virtual
        override (IERC721Metadata)
        existsToken(tokenID)
        returns (string memory)
    {
        return _tokenURIs[tokenID];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC721)
        returns (bool)
    {
        return interfaceId == 0x5b5e139f || super.supportsInterface(interfaceId);
    }

    function _initialize(string memory name_, string memory symbol_) internal {
        require(_openERC721MetadataInitialized == false, "Already initialized");
        _openERC721MetadataInitialized = true;

        _name = name_;
        _symbol = symbol_;
    }

    function _mint(address to, string memory newTokenURI, uint256 tokenID)
        internal
        virtual
        override (OpenERC721)
    {
        _tokenURIs[tokenID] = newTokenURI;

        super._mint(to, newTokenURI, tokenID);
    }

    function _burn(uint256 tokenID) internal virtual override (OpenERC721) {
        delete _tokenURIs[tokenID];

        super._burn(tokenID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address currentOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        external
        payable;

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

    function transferFrom(address from, address to, uint256 tokenId) external payable;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenCloneable {
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        bytes memory params
    ) external;

    function initialized() external view returns (bool);

    function template() external view returns (string memory);

    function version() external view returns (uint256);

    function parent() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenNFTsV4 {
    function mint(string memory tokenURI) external returns (uint256 tokenID);

    function mint(address minter, string memory tokenURI) external returns (uint256 tokenID);

    function burn(uint256 tokenID) external;

    function open() external view returns (bool);
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
//   OpenERC165
//   (supports)
//       |
//       ———————————————————————————————————————————————————
//       |                                    |            |
//   OpenERC721                          OpenERC173  OpenCloneable
//     (NFT)                              (ownable)        |
//       |                                    |            |
//       ——————————————————————————           |            |
//       |                        |           |            |
//  OpenERC721Metadata  OpenERC721Enumerable  |            |
//       |                        |           |            |
//       ———————————————————————————————————————————————————
//       |
//   OpenNFTsV4 —— IOpenNFTsV4
//
pragma solidity ^0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721Metadata.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC721Enumerable.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC173.sol";
import "OpenNFTs/contracts/OpenCloner/OpenCloneable.sol";
import "../interfaces/IOpenNFTsV4.sol";

/// @title OpenNFTs smartcontract
contract OpenNFTsV4 is IOpenNFTsV4, OpenERC721Metadata, OpenERC721Enumerable, OpenERC173, OpenCloneable {
    /// @notice tokenID of next minted NFT
    uint256 public tokenIdNext;

    /// @notice Mint NFT allowed to everyone or only collection owner
    bool public open;

    /// @notice onlyOpenOrOwner, either everybody in open collection,
    /// @notice either only owner in specific collection
    modifier onlyMinter() {
        require(open || (owner() == msg.sender), "Not minter");
        _;
    }

    function mint(string memory tokenURI_) external override(IOpenNFTsV4) returns (uint256 tokenID) {
        tokenID = _mint(msg.sender, tokenURI_);
    }

    function mint(address minter, string memory tokenURI_)
        external
        override(IOpenNFTsV4)
        onlyOwner
        returns (uint256 tokenID)
    {
        tokenID = _mint(minter, tokenURI_);
    }

    /// @notice burn NFT
    /// @param tokenID tokenID of NFT to burn
    function burn(uint256 tokenID) external override(IOpenNFTsV4) onlyTokenOwnerOrApproved(tokenID) {
        _burn(tokenID);
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        bytes memory params_
    ) public override(OpenCloneable) {
        (bytes memory subparams_, , ) = abi.decode(params_, (bytes, address, uint96));

        (, , , bool[] memory options_) = abi.decode(subparams_, (uint256, address, uint96, bool[]));
        open = options_[0];

        tokenIdNext = 1;

        OpenCloneable._initialize("OpenNFTsV4", 4);
        OpenERC721Metadata._initialize(name_, symbol_);
        OpenERC173._initialize(owner_);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OpenERC721Metadata, OpenERC721Enumerable, OpenERC173, OpenCloneable)
        returns (bool)
    {
        return interfaceId == type(IOpenNFTsV4).interfaceId || super.supportsInterface(interfaceId);
    }

    function _mint(address minter, string memory tokenURI) internal returns (uint256 tokenID) {
        tokenID = tokenIdNext++;

        _mint(minter, tokenURI, tokenID);
    }

    function _mint(
        address minter,
        string memory tokenURI,
        uint256 tokenID
    ) internal override(OpenERC721Enumerable, OpenERC721Metadata) {
        super._mint(minter, tokenURI, tokenID);
    }

    function _burn(uint256 tokenID) internal override(OpenERC721Enumerable, OpenERC721Metadata) {
        super._burn(tokenID);
    }

    function _transferFromBefore(
        address from,
        address to,
        uint256 tokenID
    ) internal override(OpenERC721, OpenERC721Enumerable) {
        super._transferFromBefore(from, to, tokenID);
    }
}