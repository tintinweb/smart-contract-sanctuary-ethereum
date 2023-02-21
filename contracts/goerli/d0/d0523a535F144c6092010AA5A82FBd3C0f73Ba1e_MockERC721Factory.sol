/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules

// Simplistic ERC721 Implementation by 0xInuarashi
// Library: CypherMate
// Inspirations: Solmate, Open Zeppelin

/** @dev this contract is designed to have modifiable structs to add 
         any custom data that you can fit into the free bytes
*/

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) 
    external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

abstract contract ERC721 {
    
    ///// Events /////
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    event Approval(address indexed owner_, address indexed spender_, 
        uint256 indexed id_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, 
        bool approved_);
    
    ///// Token Data /////
    string public name; 
    string public symbol;

    ///// Token Storage /////
    struct TokenData {
        address owner;
        /** @dev 12 free bytes */
    }
    struct BalanceData {
        uint32 balance;
        /** @dev 28 free bytes */
    }

    /** @dev these mappings replace ownerOf and balanceOf with structs */
    mapping(uint256 => TokenData) public _tokenData;
    mapping(address => BalanceData) public _balanceData;

    function balanceOf(address owner_) public virtual view returns (uint256) {
        require(owner_ != address(0), "balanceOf to 0x0");
        return _balanceData[owner_].balance;
    }
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        address _owner = _tokenData[tokenId_].owner;
        require(_owner != address(0), "ownerOf token does not exist!");
        return _owner;
    }

    ///// Token Approvals /////
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    ///// Constructor /////
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    ///// ERC721 Functions /////
    /** @dev _mint and _burn does not have totalSupply manipulations */
    function _mint(address to_, uint256 tokenId_) internal virtual { unchecked {
        require(to_ != address(0), "_mint to 0x0");
        require(_tokenData[tokenId_].owner == address(0), "_mint token exists");
        _tokenData[tokenId_].owner = to_;
        _balanceData[to_].balance++;
        emit Transfer(address(0), to_, tokenId_);
    }}
    function _burn(uint256 tokenId_) internal virtual { unchecked {
        address _owner = ownerOf(tokenId_); // will revert on 0x0
        _balanceData[_owner].balance--;
        delete _tokenData[tokenId_];
        delete getApproved[tokenId_];
        emit Transfer(_owner, address(0), tokenId_);
    }}

    /** @dev _transfer has a special checkApproved_ argument for gas-efficiency */
    function _transfer(address from_, address to_, uint256 tokenId_, 
    bool checkApproved_) internal virtual { unchecked {
        require(to_ != address(0), "_transfer to 0x0");
        address _owner = ownerOf(tokenId_);
        require(from_ == _owner, "_transfer not from owner");
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_),
                               "_transfer not approved");
        delete getApproved[tokenId_];
        _tokenData[tokenId_].owner = to_;
        _balanceData[from_].balance--;
        _balanceData[to_].balance++;
        emit Transfer(from_, to_, tokenId_);
    }}

    /** @dev transferFrom uses special _transfer with approval check flow */
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        _transfer(from_, to_, tokenId_, true);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_,
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        require(to_.code.length == 0 ||
            ERC721TokenReceiver(to_)
            .onERC721Received(msg.sender, from_, tokenId_, data_) ==
            ERC721TokenReceiver.onERC721Received.selector, 
            "safeTransferFrom to unsafe address");
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    ///// ERC721 Approvals /////
    function approve(address spender_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender],
                "approve not authorized!");
        getApproved[tokenId_] = spender_;
        emit Approval(_owner, spender_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }
    /** @dev _isApprovedOrOwner has a special owner_ argument for gas-efficiency */
    function _isApprovedOrOwner(address owner_, address spender_, uint256 tokenId_) 
    internal virtual view returns (bool) {
        return (owner_ == spender_ ||
                getApproved[tokenId_] == spender_ ||
                isApprovedForAll[owner_][spender_]);
    }

    ///// ERC165 Interface /////
    function supportsInterface(bytes4 iid_) public virtual view returns (bool) {
        return  iid_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
                iid_ == 0x80ac58cd || // ERC165 Interface ID for ERC721
                iid_ == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
    }

    /** @dev tokenURI is not implemented */
    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {}
}

// MockERC721 Product
contract MockERC721 is ERC721 {
    
    constructor(string memory name_, string memory symbol) ERC721(name_, symbol) {}

    function mint(address to_, uint256[] calldata tokenIds_) external {
        uint256 l = tokenIds_.length;
        uint256 i; unchecked { do {
            _mint(to_, tokenIds_[i]);
        } while (++i < l); }
    }
}

// MockERC721Factory
contract MockERC721Factory {
    
    mapping(address => MockERC721[]) public addressToDeployments;

    function getDeployments(address address_) 
    external view returns (MockERC721[] memory) {
        return addressToDeployments[address_];
    }

    function createMockERC721(string memory name_, string memory symbol_) public returns (uint256[] memory) {
        MockERC721 _MockERC721 = new MockERC721(name_, symbol_);
        addressToDeployments[msg.sender].push(_MockERC721);
        // Let's mint 10 tokens to the deployer
        uint256[] memory _mintIds = new uint256[] (10);
        uint256 i; while (_mintIds[9] == 0) _mintIds[i] = ++i;
        // _MockERC721.mint(msg.sender, _mintIds);
        return _mintIds;
    }

    function createMockERC721Batch(string[] calldata names_,
    string[] calldata symbols_) external {
        require(names_.length == symbols_.length, "length mismatch");
        uint256 l = names_.length;
        uint256 i; unchecked { do { 
            createMockERC721(names_[i], symbols_[i]);
        } while(++i < l); }
    }
}