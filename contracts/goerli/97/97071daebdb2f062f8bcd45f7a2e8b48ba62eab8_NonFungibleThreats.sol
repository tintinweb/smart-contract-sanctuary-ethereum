// SPDX-License-Identifier: MIT
// FlightlessApteryx.eth

pragma solidity ^0.8.7;

import "./Base64.sol";

contract NonFungibleThreats {
    // contract basics
    string public name = "NonFungibleThreats";
    string public symbol = "DIE";
    address private contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    // Approvals
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function approve(address spender, uint256 id) external {
        address owner = _ownerOf[id];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");
        getApproved[id] = spender;
        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ownership storage
    mapping(uint256 => address) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) external view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");
        return _balanceOf[owner];
    }

    // transfers
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function transferFrom(address from, address to, uint256 id) public {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }

    function safeTransferFrom( address from, address to, uint256 id) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    // data storage + minting
    string private _contractMetadataURI;
    uint256 private _tokenIds;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => bool) private _shouldBase64TokenURIs;
    bool private _shouldBase64MetadataURI = false;

    function mintNFT(address to, string calldata _tokenURI, bool _shouldBase64TokenURI) external returns (uint256) {
        unchecked {
            _tokenIds += 1;
        }

        uint256 newItemId = _tokenIds;
        unchecked {
            _balanceOf[to]++;
        }
        _ownerOf[newItemId] = to;
        _tokenURIs[newItemId] = _tokenURI;
        _shouldBase64TokenURIs[newItemId] = _shouldBase64TokenURI;

        emit Transfer(address(0), to, newItemId);
        return newItemId;
    }

    function contractURI() external view returns (string memory) {
        if (_shouldBase64MetadataURI) {
            return Base64.encodeAndPackURI(_contractMetadataURI);
        }
        return _contractMetadataURI;
    }

    function setContractURI(string calldata _newContractMetadataURI, bool _shouldBase64) external {
        require(contractOwner == msg.sender, "NOT_OWNER");
        _contractMetadataURI = _newContractMetadataURI;
        _shouldBase64MetadataURI = _shouldBase64;
    }

    function tokenURI(uint256 id) external view returns (string memory) {
        require(_ownerOf[id] != address(0), "NOT_MINTED");
        if (_shouldBase64TokenURIs[id]) {
            return Base64.encodeAndPackURI(_tokenURIs[id]);
        }
        return _tokenURIs[id];
    }

    // optional stuff
    // if you comment this out, you should also comment out the constructor
    function withdraw() external {
        payable(contractOwner).transfer(address(this).balance);
    }

    function setNameAndSymbol(string calldata newName, string calldata newSymbol) external {
        require(contractOwner == msg.sender, "NOT_OWNER");
        name = newName;
        symbol = newSymbol;
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}