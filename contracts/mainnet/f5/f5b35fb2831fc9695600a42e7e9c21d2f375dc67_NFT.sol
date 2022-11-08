/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern, minimalist, and gas-optimized ERC721 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error NotMinted();

    error ZeroAddress();

    error Unauthorized();

    error WrongFrom();

    error InvalidRecipient();

    error UnsafeRecipient();

    error AlreadyMinted();

    /// -----------------------------------------------------------------------
    /// Metadata Storage/Logic
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// -----------------------------------------------------------------------
    /// ERC721 Balance/Owner Storage
    /// -----------------------------------------------------------------------

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = _ownerOf[id]) == address(0)) revert NotMinted();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balanceOf[owner];
    }

    /// -----------------------------------------------------------------------
    /// ERC721 Approval Storage
    /// -----------------------------------------------------------------------

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /// -----------------------------------------------------------------------
    /// ERC721 Logic
    /// -----------------------------------------------------------------------

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert Unauthorized();

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (from != _ownerOf[id]) revert WrongFrom();

        if (to == address(0)) revert InvalidRecipient();

        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[id])
            revert Unauthorized();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert UnsafeRecipient();
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert UnsafeRecipient();
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC165 Logic
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert InvalidRecipient();

        if (_ownerOf[id] != address(0)) revert AlreadyMinted();

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) revert NotMinted();

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /// -----------------------------------------------------------------------
    /// Internal Safe Mint Logic
    /// -----------------------------------------------------------------------

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert UnsafeRecipient();
        }
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert UnsafeRecipient();
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract NFT is ERC721("NFT", "NFT") {
    address public deployer = msg.sender;

    function tokenURI(uint256) public pure virtual override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmRpwSkTXhSv5Nr2KeNPdKyb3EfZN4bSp8HRkhUJusDwBV";
    }

    function mint(address to, uint256 id) public virtual {
        if (msg.sender != deployer) revert Unauthorized();

        _mint(to, id);
    }

    function burn(uint256 id) public virtual {
        if (!isApprovedForAll[_ownerOf[id]][msg.sender]) revert Unauthorized();

        _burn(id);
    }
}