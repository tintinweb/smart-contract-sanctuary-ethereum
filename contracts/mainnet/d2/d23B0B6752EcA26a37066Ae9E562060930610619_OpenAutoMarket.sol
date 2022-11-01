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
// EIP-2981: NFT Royalty Standard
// https://eips.ethereum.org/EIPS/eip-2981
//
// Derived from OpenZeppelin Contracts (token/common/ERC2981.sol)
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/common/ERC2981.sol
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
//  OpenERC2981 —— IERC2981 —— IOpenReceiverInfos
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721.sol";
import "OpenNFTs/contracts/interfaces/IERC2981.sol";
import "OpenNFTs/contracts/interfaces/IOpenReceiverInfos.sol";

abstract contract OpenERC2981 is IERC2981, IOpenReceiverInfos, OpenERC165 {
    uint256 internal _mintPrice;
    ReceiverInfos internal _defaultRoyalty;
    mapping(uint256 => ReceiverInfos) internal _tokenRoyalty;

    uint96 internal constant _MAX_FEE = 10_000;

    modifier notTooExpensive(uint256 price) {
        /// otherwise may overflow
        require(price < 2 ** 128, "Too expensive");
        _;
    }

    modifier lessThanMaxFee(uint256 fee) {
        require(fee <= _MAX_FEE, "Royalty fee exceed price");
        _;
    }

    function royaltyInfo(uint256 tokenID, uint256 price)
        public
        view
        override (IERC2981)
        notTooExpensive(price)
        returns (address receiver, uint256 royaltyAmount)
    {
        ReceiverInfos memory royalty = _tokenRoyalty[tokenID];

        if (royalty.account == address(0)) {
            royalty = _defaultRoyalty;
        }

        royaltyAmount = _calculateAmount(price, royalty.fee);

        /// MINIMAL royaltyAmount
        if (royalty.minimum > 0) {
            /// with zero price, token owner can bypass royalties...
            /// SO set a minimumRoyaltyAmount calculated on mintPrice (than can only be modified by collection owner)
            /// BUT collection owner can higher too much mintPrice making fees too high
            /// SO moreover store a minimumRoyaltyAmount per token defined during mint, or last transfer

            /// MIN(royalty.minimum, defaultRoyaltyAmount)
            uint256 defaultRoyaltyAmount = _calculateAmount(_mintPrice, royalty.fee);
            uint256 minimumRoyaltyAmount =
                royalty.minimum < defaultRoyaltyAmount ? royalty.minimum : defaultRoyaltyAmount;

            /// MAX(normalRoyaltyAmount, minimumRoyaltyAmount)
            royaltyAmount =
                royaltyAmount < minimumRoyaltyAmount ? minimumRoyaltyAmount : royaltyAmount;
        }

        return (royalty.account, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC165)
        returns (bool)
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    function _calculateAmount(uint256 price, uint96 fee) internal pure returns (uint256) {
        return (price * fee) / _MAX_FEE;
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
//   OpenGuard
//
pragma solidity 0.8.9;

abstract contract OpenGuard {
    bool private _locked;

    modifier reEntryGuard() {
        require(!_locked, "No re-entry!");

        _locked = true;

        _;

        _locked = false;
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
//   (supports)
//        |
//        ————————————————————————————
//        |            |             |
//   OpenERC721    OpenERC173   OpenERC2981
//      (NFT)      (Ownable)   (RoyaltyInfo)
//        |            |             |
//        ————————————————————————————
//        |
//  OpenMarketable —— IOpenMarketable - OpenGuard
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/OpenERC/OpenERC721.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC173.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC2981.sol";
import "OpenNFTs/contracts/OpenNFTs/OpenGuard.sol";
import "OpenNFTs/contracts/interfaces/IOpenMarketable.sol";

abstract contract OpenMarketable is
    IOpenMarketable,
    OpenERC721,
    OpenERC173,
    OpenERC2981,
    OpenGuard
{
    mapping(uint256 => uint256) internal _tokenPrice;

    bool public minimal;

    ReceiverInfos internal _treasury;

    receive() external payable override (IOpenMarketable) {}

    /// @notice withdraw eth
    function withdraw() external override (IOpenMarketable) onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice SET default mint price
    /// @param price : default price in wei
    function setMintPrice(uint256 price) public override (IOpenMarketable) onlyOwner {
        _setMintPrice(price);
    }

    /// @notice SET default royalty info
    /// @param receiver : address of the royalty receiver, or address(0) to reset
    /// @param fee : fee Numerator, less than 10000
    function setDefaultRoyalty(address receiver, uint96 fee)
        public
        override (IOpenMarketable)
        onlyOwner
    {
        _setDefaultRoyalty(receiver, fee);
    }

    /// @notice SET token price
    /// @param tokenID : token ID
    /// @param price : token price in wei
    function setTokenPrice(uint256 tokenID, uint256 price)
        public
        override (IOpenMarketable)
        onlyTokenOwnerOrApproved(tokenID)
    {
        _setTokenPrice(tokenID, price, address(this), Approve.All);
    }

    /// @notice SET token royalty info
    /// @param tokenID : token ID
    /// @param receiver : address of the royalty receiver, or address(0) to reset
    /// @param fee : fee Numerator, less than 10_000
    function setTokenRoyalty(uint256 tokenID, address receiver, uint96 fee)
        public
        override (IOpenMarketable)
        existsToken(tokenID)
        onlyOwner
        onlyTokenOwnerOrApproved(tokenID)
    {
        _setTokenRoyalty(tokenID, receiver, fee);
    }

    function getMintPrice() public view override (IOpenMarketable) returns (uint256) {
        return _mintPrice;
    }

    function getTokenPrice(uint256 tokenID)
        public
        view
        override (IOpenMarketable)
        returns (uint256)
    {
        return _tokenPrice[tokenID];
    }

    /// @notice GET default royalty info
    /// @return receiver : default royalty receiver infos
    function getDefaultRoyalty()
        public
        view
        override (IOpenMarketable)
        returns (ReceiverInfos memory receiver)
    {
        receiver = _defaultRoyalty;
    }

    /// @notice GET token royalty info
    /// @param tokenID : token ID
    /// @return receiver :  token royalty receiver infos
    function getTokenRoyalty(uint256 tokenID)
        public
        view
        override (IOpenMarketable)
        returns (ReceiverInfos memory receiver)
    {
        receiver = _tokenRoyalty[tokenID];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC721, OpenERC173, OpenERC2981)
        returns (bool)
    {
        return interfaceId == type(IOpenMarketable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function _initialize(
        uint256 mintPrice_,
        address receiver_,
        uint96 fee_,
        address treasury_,
        uint96 treasuryFee_,
        bool minimal_
    ) internal {
        minimal = minimal_;
        _mintPrice = mintPrice_;
        _defaultRoyalty = _createReceiverInfos(receiver_, fee_);
        _treasury = _createReceiverInfos(treasury_, treasuryFee_);
    }

    function _mint(address to, string memory tokenURI, uint256 tokenID)
        internal
        virtual
        override (OpenERC721)
    {
        _setTokenRoyalty(tokenID, _defaultRoyalty.account, _defaultRoyalty.fee);

        if (to != owner()) _pay(tokenID, _mintPrice, to, owner());

        super._mint(to, tokenURI, tokenID);
    }

    function _burn(uint256 tokenID) internal virtual override (OpenERC721) {
        delete _tokenRoyalty[tokenID];
        delete _tokenPrice[tokenID];

        super._burn(tokenID);
    }

    function _transferFromBefore(address from, address to, uint256 tokenID)
        internal
        virtual
        override (OpenERC721)
    {
        /// Transfer: pay token price (including royalties) to previous token owner (and royalty receiver)
        _pay(tokenID, _tokenPrice[tokenID], to, ownerOf(tokenID));

        delete _tokenPrice[tokenID];

        super._transferFromBefore(from, to, tokenID);
    }

    function _setDefaultRoyalty(address receiver, uint96 fee) internal lessThanMaxFee(fee) {
        _defaultRoyalty = _createReceiverInfos(receiver, fee);

        emit SetDefaultRoyalty(receiver, fee);
    }

    function _setTokenRoyalty(uint256 tokenID, address receiver, uint96 fee)
        internal
        lessThanMaxFee(fee)
    {
        _tokenRoyalty[tokenID] = _createReceiverInfos(receiver, fee);

        emit SetTokenRoyalty(tokenID, receiver, fee);
    }

    /// @notice SET token price
    /// @param tokenID : token ID
    /// @param price : token price in wei
    function _setTokenPrice(uint256 tokenID, uint256 price, address approved, Approve approveType)
        internal
        onlyTokenOwnerOrApproved(tokenID)
        notTooExpensive(price)
    {
        _tokenPrice[tokenID] = price;

        emit SetTokenPrice(tokenID, price);

        if (approveType == Approve.All) {
            setApprovalForAll(approved, true);
        } else if (approveType == Approve.One) {
            approve(approved, tokenID);
        }
    }

    function _setMintPrice(uint256 price) internal notTooExpensive(price) {
        _mintPrice = price;
        _setDefaultRoyalty(_defaultRoyalty.account, _defaultRoyalty.fee);

        emit SetMintPrice(price);
    }

    function _createReceiverInfos(address receiver, uint96 fee)
        internal
        view
        returns (ReceiverInfos memory)
    {
        return ReceiverInfos(receiver, fee, minimal ? _calculateAmount(_mintPrice, fee) : 0);
    }

    function _transferValue(address to, uint256 value) private returns (uint256) {
        bool success;
        if (value > 0) {
            (success,) = to.call{value: value, gas: 2300}("");
        }
        return success ? value : 0;
    }

    function _pay(uint256 tokenID, uint256 price, address buyer, address seller)
        private
        reEntryGuard
    {
        require(msg.value >= price, "Not enough funds");
        require(buyer != address(0), "Invalid buyer");
        require(seller != address(0), "Invalid seller");

        address receiver;
        uint256 royalties;
        uint256 fee;
        uint256 paid;
        uint256 unspent;

        (receiver, royalties) = royaltyInfo(tokenID, price);
        if (receiver == address(0)) royalties = 0;

        if (price > 0 || royalties > 0) {
            fee = _calculateAmount(price, _treasury.fee);
            require(msg.value >= royalties + fee, "Not enough funds");

            /// Transfer amount to be paid to seller
            if (price > royalties + fee) {
                paid = _transferValue(seller, price - (royalties + fee));
            }

            /// Transfer royalties to receiver
            royalties = _transferValue(receiver, royalties);

            /// Transfer fee to protocol treasury
            fee = _transferValue(_treasury.account, fee);
        }
        unspent = msg.value - (paid + royalties + fee);

        /// Transfer back unspent funds to buyer
        unspent = _transferValue(buyer, unspent);

        emit Pay(tokenID, price, seller, paid, receiver, royalties, fee, buyer, unspent);
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
//   (supports)
//       |
//       ——————————————————————————————————————————————————————————————————————
//       |                                       |             |              |
//   OpenERC721                            OpenERC2981    OpenERC173    OpenCloneable
//     (NFT)                              (RoyaltyInfo)    (ownable)          |
//       |                                        |            |              |
//       ——————————————————————————————————————   |     ————————              |
//       |                        |           |   |     |      |              |
//  OpenERC721Metadata  OpenERC721Enumerable  |   ———————      |              |
//       |                        |           |   |            |              |
//       |                        |      OpenMarketable   OpenPauseable       |
//       |                        |             |              |              |
//       ——————————————————————————————————————————————————————————————————————
//       |
//    OpenNFTs —— IOpenNFTs
//
pragma solidity 0.8.9;

import "OpenNFTs/contracts/interfaces/IERC165.sol";

import "OpenNFTs/contracts/interfaces/IOpenNFTs.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC721Metadata.sol";
import "OpenNFTs/contracts/OpenERC/OpenERC721Enumerable.sol";
import "OpenNFTs/contracts/OpenNFTs/OpenMarketable.sol";
import "OpenNFTs/contracts/OpenNFTs/OpenPauseable.sol";
import "OpenNFTs/contracts/OpenCloner/OpenCloneable.sol";

/// @title OpenNFTs smartcontract
abstract contract OpenNFTs is
    IOpenNFTs,
    OpenERC721Metadata,
    OpenERC721Enumerable,
    OpenMarketable,
    OpenPauseable,
    OpenCloneable
{
    /// @notice tokenID of next minted NFT
    uint256 public tokenIdNext;

    /// @notice onlyMinter, by default only owner can mint, can be overriden
    modifier onlyMinter() virtual {
        require(msg.sender == owner(), "Not minter");
        _;
    }

    /// @notice burn NFT
    /// @param tokenID tokenID of NFT to burn
    function burn(uint256 tokenID)
        external
        override (IOpenNFTs)
        onlyTokenOwnerOrApproved(tokenID)
    {
        _burn(tokenID);
    }

    function mint(address minter, string memory tokenURI)
        public
        override (IOpenNFTs)
        onlyMinter
        returns (uint256 tokenID)
    {
        tokenID = tokenIdNext++;
        _mint(minter, tokenURI, tokenID);
    }

    /// @notice test if this interface is supported
    /// @param interfaceId interfaceId to test
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (
            OpenMarketable, OpenERC721Metadata, OpenERC721Enumerable, OpenCloneable, OpenPauseable
        )
        returns (bool)
    {
        return interfaceId == type(IOpenNFTs).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice _initialize
    /// @param name_ name of the NFT Collection
    /// @param symbol_ symbol of the NFT Collection
    /// @param owner_ owner of the NFT Collection
    // solhint-disable-next-line comprehensive-interface
    function _initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 mintPrice_,
        address receiver_,
        uint96 fee_,
        address treasury_,
        uint96 treasuryFee_,
        bool minimal_
    ) internal {
        tokenIdNext = 1;

        OpenCloneable._initialize("OpenNFTs", 4);
        OpenERC721Metadata._initialize(name_, symbol_);
        OpenERC173._initialize(owner_);
        OpenMarketable._initialize(mintPrice_, receiver_, fee_, treasury_, treasuryFee_, minimal_);
    }

    /// @notice _mint
    /// @param minter minter address
    /// @param tokenURI token metdata URI
    /// @param tokenID token ID
    function _mint(address minter, string memory tokenURI, uint256 tokenID)
        internal
        override (OpenERC721Enumerable, OpenERC721Metadata, OpenMarketable)
    {
        super._mint(minter, tokenURI, tokenID);
    }

    function _burn(uint256 tokenID)
        internal
        override (OpenERC721Enumerable, OpenERC721Metadata, OpenMarketable)
    {
        super._burn(tokenID);
    }

    function _transferFromBefore(address from, address to, uint256 tokenID)
        internal
        override (OpenERC721, OpenMarketable, OpenERC721Enumerable)
    {
        super._transferFromBefore(from, to, tokenID);
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

    function togglePause() external override (IOpenPauseable) onlyOwner {
        _setPaused(!_paused);
    }

    function paused() external view override (IOpenPauseable) returns (bool) {
        return _paused;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC173)
        returns (bool)
    {
        return interfaceId == type(IOpenPauseable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function _setPaused(bool paused_) private {
        _paused = paused_;
        emit SetPaused(_paused, msg.sender);
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

interface IERC2981 {
    function royaltyInfo(uint256 tokenID, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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

import "OpenNFTs/contracts/interfaces/IOpenReceiverInfos.sol";

interface IOpenMarketable is IOpenReceiverInfos {
    enum Approve {
        None,
        One,
        All
    }

    event SetDefaultRoyalty(address receiver, uint96 fee);

    event SetTokenRoyalty(uint256 tokenID, address receiver, uint96 fee);

    event SetMintPrice(uint256 price);

    event SetTokenPrice(uint256 tokenID, uint256 price);

    event Pay(
        uint256 tokenID,
        uint256 price,
        address seller,
        uint256 paid,
        address receiver,
        uint256 royalties,
        uint256 fee,
        address buyer,
        uint256 unspent
    );

    receive() external payable;

    function withdraw() external;

    function setMintPrice(uint256 price) external;

    function setDefaultRoyalty(address receiver, uint96 fee) external;

    function setTokenPrice(uint256 tokenID, uint256 price) external;

    function setTokenRoyalty(uint256 tokenID, address receiver, uint96 fee) external;

    function minimal() external view returns (bool);

    function getMintPrice() external view returns (uint256 price);

    function getDefaultRoyalty() external view returns (ReceiverInfos memory receiver);

    function getTokenPrice(uint256 tokenID) external view returns (uint256 price);

    function getTokenRoyalty(uint256 tokenID)
        external
        view
        returns (ReceiverInfos memory receiver);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenNFTs {
    function mint(address minter, string memory tokenURI) external returns (uint256 tokenID);

    function burn(uint256 tokenID) external;
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

interface IOpenReceiverInfos {
    struct ReceiverInfos {
        address account;
        uint96 fee;
        uint256 minimum;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOpenAutoMarket {
    function mint(string memory tokenURI) external returns (uint256 tokenID);

    function mint(
        address minter,
        string memory tokenURI,
        uint256 price,
        address receiver,
        uint96 fee
    ) external payable returns (uint256 tokenID);

    function gift(address to, uint256 tokenID) external payable;

    function buy(uint256 tokenID) external payable;

    function open() external view returns (bool);
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
//   OpenERC165
//   (supports)
//       |
//       ———————————————————————————————————————————————————————————————————————————
//       |                                                         |               |
//   OpenERC721                                               OpenERC173     OpenCloneable
//     (NFT)                                                   (ownable)           |
//       |                                                         |               |
//       —————————————————————————————————————————————      ————————               |
//       |                        |                  |      |      |               |
//  OpenERC721Metadata  OpenERC721Enumerable   OpenERC2981  |      |               |
//       |                        |           (RoyaltyInfo) |      |               |
//       |                        |                  |      |      |               |
//       |                        |                  ————————      |               |
//       |                        |                  |             |               |
//       |                        |            OpenMarketable OpenPauseable        |
//       |                        |                  |             |               |
//       ———————————————————————————————————————————————————————————————————————————
//       |
//    OpenNFTs
//       |
//   OpenAutoMarket —— IOpenAutoMarket
//
pragma solidity ^0.8.9;

import "OpenNFTs/contracts/OpenNFTs/OpenNFTs.sol";
import "../interfaces/IOpenAutoMarket.sol";
import {IOpenNFTs as IOpenNFTsOld} from "../interfaces/IOpenNFTs.old.sol";

/// @title OpenNFTs smartcontract
contract OpenAutoMarket is IOpenAutoMarket, OpenNFTs {
    /// @notice Mint NFT allowed to everyone or only collection owner
    bool public open;

    /// @notice onlyOpenOrOwner, either everybody in open collection,
    /// @notice either only owner in specific collection
    modifier onlyMinter() override(OpenNFTs) {
        require(open || (owner() == msg.sender), "Not minter");
        _;
    }

    function gift(address to, uint256 tokenID) external payable override(IOpenAutoMarket) existsToken(tokenID) {
        setTokenPrice(tokenID, 0);

        safeTransferFrom(msg.sender, to, tokenID);
    }

    function buy(uint256 tokenID) external payable override(IOpenAutoMarket) existsToken(tokenID) {
        /// Get token price
        uint256 price = _tokenPrice[tokenID];

        /// Require price defined
        require(price > 0, "Not to sell");

        /// Require enough value sent
        require(msg.value >= price, "Not enough funds");

        /// Get previous token owner
        address from = ownerOf(tokenID);
        assert(from != address(0));
        require(from != msg.sender, "Already token owner!");

        /// This AutoMarket approves msg.sender (requires AutoMarket isAprovedForAll)
        this.approve(msg.sender, tokenID);

        /// Transfer token
        safeTransferFrom(from, msg.sender, tokenID);

        /// Reset token price (to be eventualy defined by new owner)
        delete _tokenPrice[tokenID];
    }

    function mint(string memory tokenURI) external override(IOpenAutoMarket) returns (uint256 tokenID) {
        tokenID = mint(msg.sender, tokenURI, 0, address(0), 0);
    }

    function mint(
        address minter_,
        string memory tokenURI_,
        uint256 tokenPrice_,
        address receiver_,
        uint96 receiverFee_
    ) public payable override(IOpenAutoMarket) onlyMinter onlyWhenNotPaused returns (uint256 tokenID) {
        tokenID = OpenNFTs.mint(minter_, tokenURI_);

        if (tokenPrice_ > 0) OpenMarketable._setTokenPrice(tokenID, tokenPrice_, address(this), Approve.All);
        if (receiverFee_ > 0) OpenMarketable._setTokenRoyalty(tokenID, receiver_, receiverFee_);
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        bytes memory params_
    ) public virtual override(OpenCloneable) {
        (bytes memory subparams_, address treasury_, uint96 treasuryFee_) = abi.decode(
            params_,
            (bytes, address, uint96)
        );

        (uint256 mintPrice_, address receiver_, uint96 receiverFee_, bool[] memory options_) = abi.decode(
            subparams_,
            (uint256, address, uint96, bool[])
        );
        open = options_[0];

        OpenNFTs._initialize(
            name_,
            symbol_,
            owner_,
            mintPrice_,
            receiver_,
            receiverFee_,
            treasury_,
            treasuryFee_,
            options_[1]
        );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OpenNFTs) returns (bool) {
        return interfaceId == type(IOpenAutoMarket).interfaceId || super.supportsInterface(interfaceId);
    }
}