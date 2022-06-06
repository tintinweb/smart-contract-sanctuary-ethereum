/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////////////////////////
//    _____                   __            ___   ____  ______              //
//   / ___/__ ____  ___ ____ / /____ ____  / _ | / / / / __/ /____ _____    //
//  / (_ / _ `/ _ \/ _ `(_-</ __/ -_) __/ / __ |/ / / _\ \/ __/ _ `/ __/    //
//  \___/\_,_/_//_/\_, /___/\__/\__/_/   /_/ |_/_/_/ /___/\__/\_,_/_/       //
//                /___/                                                     //
//     ____ ___    ___                                                      //
//    / __// _ \  / _ )___  ___ ___ ___ ___                                 //
//   /__ \/ // / / _  / _ \(_-<(_-</ -_|_-<                                 //
//  /____/\___/ /____/\___/___/___/\__/___/                                 //
//                                                                          //
//   Migration by: 0xInuarashi                                              //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

contract ERC721I {

    string public name; string public symbol;
    string internal baseTokenURI; string internal baseTokenURI_EXT;
    constructor(string memory name_, string memory symbol_) {
        name = name_; symbol = symbol_; 
    }

    uint256 public totalSupply; 
    mapping(uint256 => address) public ownerOf; 
    mapping(address => uint256) public balanceOf; 

    mapping(uint256 => address) public getApproved; 
    mapping(address => mapping(address => bool)) public isApprovedForAll; 

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Mint(address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, 
    uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, 
    bool approved);

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), 
            "ERC721I: _mint() Mint to Zero Address");
        require(ownerOf[tokenId_] == address(0x0), 
            "ERC721I: _mint() Token to Mint Already Exists!");

        balanceOf[to_]++;
        ownerOf[tokenId_] = to_;

        emit Transfer(address(0x0), to_, tokenId_);
    }

    // transfer
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf[tokenId_], 
            "ERC721I: _transfer() Transfer Not Owner of Token!");
        require(to_ != address(0x0), 
            "ERC721I: _transfer() Transfer to Zero Address!");

        // checks if there is an approved address clears it if there is
        if (getApproved[tokenId_] != address(0x0)) { 
            _approve(address(0x0), tokenId_); 
        } 

        ownerOf[tokenId_] = to_; 
        balanceOf[from_]--;
        balanceOf[to_]++;

        emit Transfer(from_, to_, tokenId_);
    }

    // approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf[tokenId_], to_, tokenId_);
        }
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_)
    internal virtual {
        require(owner_ != operator_, 
            "ERC721I: _setApprovalForAll() Owner must not be the Operator!");
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        require(ownerOf[tokenId_] != address(0x0), 
            "ERC721I: _isApprovedOrOwner() Owner is Zero Address!");
        address _owner = ownerOf[tokenId_];
        return (spender_ == _owner 
            || spender_ == getApproved[tokenId_] 
            || isApprovedForAll[_owner][spender_]);
    }
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }

    // // public write functions
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf[tokenId_];
        require(to_ != _owner, 
            "ERC721I: approve() Cannot approve yourself!");
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender],
            "ERC721I: Caller not owner or Approved!");
        _approve(to_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }
    function transferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), 
            "ERC721I: transferFrom() _isApprovedOrOwner = false!");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, 
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(
                0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, 
                "ERC721I: safeTransferFrom() to_ not ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // 0xInuarashi Custom Functions
    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_)
    public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, 
    uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
    
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf[tokenId_] != address(0x0), 
            "ERC721I: tokenURI() Token does not exist!");
        return string(abi.encodePacked(
            baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }
    // // public view functions
    // never use these for functions ever, they are expensive af and for view only 
    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf[address_];
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf[i] == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++; 
            }
            if (ownerOf[i] == address_) { 
                _tokens[_index] = i; _index++; 
            }
        }
        return _tokens;
    }

    // not sure when this will ever be needed but it conforms to erc721 enumerable
    function tokenOfOwnerByIndex(address address_, uint256 index_) public 
    virtual view returns (uint256) {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
    }
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface IERC1155 {
    function safeTransferFrom(address from_, address to_, uint256 id_,
    uint256 amount_, bytes calldata data_) external;
}

contract GangsterAllStarOG is ERC721I, Ownable {
    constructor() ERC721I("Gangster All Star OG", "GAS OG") {}

    // Migration Variables
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant OSAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    IERC1155 public OSStore = IERC1155(OSAddress);
    bool public migrationEnabled = true; 

    // Events
    event Migrated(address migrator_, uint256 newTokenId_, uint256 oldTokenId_);

    // Modifiers
    modifier onlySender { require(msg.sender == tx.origin, "No Smart Contracts!"); _; }
    modifier onlyMigration { require(migrationEnabled, "Migration Disabled!"); _; }

    // Administration
    function setMigration(bool bool_) external onlyOwner {
        migrationEnabled = bool_;
    }

    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // Token ID Finder
    function getRawIdFromOS(uint256 tokenId_) public pure returns (uint256) {
        return (tokenId_ 
        & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
    }
    function isCreatedByGAS(uint256 tokenId_) public pure returns (bool) {
        return tokenId_ >> 96 
            == 0x000000000000000000000000077afa85c86ac799b04d0f7aab6c81bfe4186773;
    }
    function getTokenOffsets(uint256 tokenId_) public pure returns (uint256) {
        if ((tokenId_ >= 71 && tokenId_ <= 80)
            || tokenId_ == 82) 
            return 70;

        if (tokenId_ == 83 
            || (tokenId_ >= 93 && tokenId_ <= 102)
            || (tokenId_ >= 105 && tokenId_ <= 112)) 
            return 72;

        if ((tokenId_ >= 84 && tokenId_ <= 91)) 
            return 71;
        
        if ((tokenId_ >= 115 && tokenId_ <= 124))
            return 74;

        if (tokenId_ == 113 
            || tokenId_ == 114)
            return 82;
        
        else revert ("GAS OG: Unable to determine offset!");
    }
    function getValidOGTokenId(uint256 tokenId_) public pure returns (uint256) {
        require(isCreatedByGAS(tokenId_), 
            "This token was not created by GAS!");

        uint256 _rawId = getRawIdFromOS(tokenId_);
        return _rawId - getTokenOffsets(_rawId);
    }

    // Migration Logic
    function migrateGangster(uint256 tokenId_) external onlySender onlyMigration {
        uint256 _newTokenId = getValidOGTokenId(tokenId_);

        // Burn the OpenStore Token
        OSStore.safeTransferFrom(msg.sender, burnAddress, tokenId_, 1, "");

        // Mint the new Token ID to msg.sender
        _mint(msg.sender, _newTokenId);

        // Increment TotalSupply
        totalSupply++;

        // Emit the Migration Event
        emit Migrated(msg.sender, _newTokenId, tokenId_);
    }

    // Mint ID 19
    function mintStuck(address to_) external onlyOwner {
        _mint(to_, 19);
        totalSupply++;
    }
}