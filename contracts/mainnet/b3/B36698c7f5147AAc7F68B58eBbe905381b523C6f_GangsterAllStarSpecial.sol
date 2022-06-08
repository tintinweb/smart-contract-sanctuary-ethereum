/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//////////////////////////////////////////////////////////////////////////////
//    _____                   __            ___   ____  ______              //
//   / ___/__ ____  ___ ____ / /____ ____  / _ | / / / / __/ /____ _____    //
//  / (_ / _ `/ _ \/ _ `(_-</ __/ -_) __/ / __ |/ / / _\ \/ __/ _ `/ __/    //
//  \___/\_,_/_//_/\_, /___/\__/\__/_/   /_/ |_/_/_/ /___/\__/\_,_/_/       //
//                /___/                                                     //
//     ____             _      __                                           //
//    / __/__  ___ ____(_)__ _/ /                                           //
//   _\ \/ _ \/ -_) __/ / _ `/ /                                            //
//  /___/ .__/\__/\__/_/\_,_/_/                                             //
//     /_/                                                                  //
//                                                                          //
//   Migration by: 0xInuarashi                                              //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_,
        uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_,
        uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_)
        external returns (bytes4);
}

contract ERC1155I {
    
    // Events
    event TransferSingle(address indexed operator_, address indexed from_, 
    address indexed to_, uint256 id_, uint256 amount_);
    event TransferBatch(address indexed operator_, address indexed from_, 
    address indexed to_, uint256[] ids_, uint256[] amounts_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, 
    bool approved_);
    event URI(string value_, uint256 indexed id_);

    // Mappings
    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // Base Info
    string public name; 
    string public symbol; 

    // Setting Name and Symbol (Missing in ERC1155 Generally)
    constructor(string memory name_, string memory symbol_) {
        name = name_; 
        symbol = symbol_; 
    }
    
    // URI Display Type Setting (Default to ERC721 Style)
        // 1 - ERC1155 Style
        // 2 - ERC721 Style
        // 3 - Mapping Style
    uint256 public URIType = 2; 
    function _setURIType(uint256 uriType_) internal virtual {
        URIType = uriType_;
    }   

    // ERC1155 URI
    string public _uri;
    function _setURI(string memory uri_) internal virtual { _uri = uri_; }
    
    // ERC721 URI (Override)
    string internal baseTokenURI; 
    string internal baseTokenURI_EXT;

    function _setBaseTokenURI(string memory uri_) internal virtual { 
        baseTokenURI = uri_; }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_; }
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Mapping Style URI (Override)
    mapping(uint256 => string) public tokenIdToURI;
    
    function _setURIOfToken(uint256 id_, string memory uri_) internal virtual {
        tokenIdToURI[id_] = uri_; }


    // URI (0xInuarashi Version)
    function uri(uint256 id_) public virtual view returns (string memory) {
        // ERC1155
        if (URIType == 1) return _uri;
        // ERC721
        else if (URIType == 2) return 
            string(abi.encodePacked(baseTokenURI, _toString(id_), baseTokenURI_EXT));
        // Mapping 
        else if (URIType == 3) return tokenIdToURI[id_];
        else return "";
    }

    // Internal Logics
    function _isSameLength(uint256 a, uint256 b) internal pure returns (bool) {
        return a == b;
    }
    function _isApprovedOrOwner(address from_) internal view returns (bool) {
        return msg.sender == from_ 
            || isApprovedForAll[from_][msg.sender];
    }
    function _ERC1155Supported(address from_, address to_, uint256 id_,
    uint256 amount_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155Received(
                msg.sender, from_, id_, amount_, data_) ==
            ERC1155TokenReceiver.onERC1155Received.selector,
                "_ERC1155Supported(): Unsupported Recipient!"
        );
    }
    function _ERC1155BatchSupported(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155BatchReceived(
                msg.sender, from_, ids_, amounts_, data_) ==
            ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "_ERC1155BatchSupported(): Unsupported Recipient!"
        );
    }

    // ERC1155 Logics
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    function safeTransferFrom(address from_, address to_, uint256 id_, 
    uint256 amount_, bytes memory data_) public virtual {
        require(_isApprovedOrOwner(from_));
        
        balanceOf[from_][id_] -= amount_;
        balanceOf[to_][id_] += amount_;

        emit TransferSingle(msg.sender, from_, to_, id_, amount_);

        _ERC1155Supported(from_, to_, id_, amount_, data_);
    }
    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_,
    uint256[] memory amounts_, bytes memory data_) public virtual {
        require(_isSameLength(ids_.length, amounts_.length));
        require(_isApprovedOrOwner(from_));

        for (uint256 i = 0; i < ids_.length; i++) {
            balanceOf[from_][ids_[i]] -= amounts_[i];
            balanceOf[to_][ids_[i]] += amounts_[i];
        }

        emit TransferBatch(msg.sender, from_, to_, ids_, amounts_);

        _ERC1155BatchSupported(from_, to_, ids_, amounts_, data_);
    }

    // Internal Mint / Burn Logic
    function _mint(address to_, uint256 id_, uint256 amount_, bytes memory data_)
    internal {
        balanceOf[to_][id_] += amount_;

        emit TransferSingle(msg.sender, address(0), to_, id_, amount_);

        _ERC1155Supported(address(0), to_, id_, amount_, data_);
    }
    function _batchMint(address to_, uint256[] memory ids_, uint256[] memory amounts_,
    bytes memory data_) internal {
        require(_isSameLength(ids_.length, amounts_.length));

        for (uint256 i = 0; i < ids_.length; i++) {
            balanceOf[to_][ids_[i]] += amounts_[i];
        }

        emit TransferBatch(msg.sender, address(0), to_, ids_, amounts_);

        _ERC1155BatchSupported(address(0), to_, ids_, amounts_, data_);
    }
    function _batchBurn(address from_, uint256[] memory ids_, 
    uint256[] memory amounts_) internal {
        require(_isSameLength(ids_.length, amounts_.length));
        
        for (uint256 i = 0; i < ids_.length; i++) {
            balanceOf[from_][ids_[i]] -= amounts_[i];
        }

        emit TransferBatch(msg.sender, from_, address(0), ids_, amounts_);
    }
    function _burn(address from_, uint256 id_, uint256 amount_) internal {
        balanceOf[from_][id_] -= amount_;
        emit TransferSingle(msg.sender, from_, address(0), id_, amount_);
    }

    // ERC165 Logic
    function supportsInterface(bytes4 interfaceId_) public pure virtual returns (bool) {
        return 
        interfaceId_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
        interfaceId_ == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
        interfaceId_ == 0x0e89341c;   // ERC165 Interface ID for ERC1155MetadataURI
    }

    // View Functions
    function balanceOfBatch(address[] memory owners_, uint256[] memory ids_) public
    view virtual returns (uint256[] memory) {
        require(_isSameLength(owners_.length, ids_.length));

        uint256[] memory _balances = new uint256[](owners_.length);

        for (uint256 i = 0; i < owners_.length; i++) {
            _balances[i] = balanceOf[owners_[i]][ids_[i]];
        }
        return _balances;
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

contract GangsterAllStarSpecial is ERC1155I, Ownable {
    constructor() ERC1155I("Gangster All Star Specials", "GAS Specials") {}

    // Migration Variables
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public constant OSAddress = 0x495f947276749Ce646f68AC8c248420045cb7b5e;
    IERC1155 public OSStore = IERC1155(OSAddress);

    bool public migrationEnabled = true; 

    // Events
    event Migrated(address migrator_, uint256 newTokenId_, uint256 oldTokenId_);

    // Modifiers
    modifier onlySender { require(msg.sender == tx.origin, "No Smart Contract!"); _; }
    modifier onlyMigration { require(migrationEnabled, "Migration Disabled!"); _; }

    // Administration
    function setMigration(bool bool_) external onlyOwner {
        migrationEnabled = bool_;
    }

    // Ownable ERC1155I URI Administration
    function setURIType(uint256 uriType_) external onlyOwner {
        _setURIType(uriType_);
    }
    function setURI(string calldata uri_) external onlyOwner {
        _setURI(uri_);
    }
    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }
    function setURIOfToken(uint256 id_, string calldata uri_) external onlyOwner {
        _setURIOfToken(id_, uri_);
    }

    // Minting New Assets
    function mintSingleToMany(address[] calldata tos_, uint256 id_, 
    uint256 amount_, bytes calldata data_) external onlyOwner {
        for (uint256 i; i < tos_.length; i++) {
            _mint(tos_[i], id_, amount_, data_);
        }
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

    // Specials IDs
    function getTokenOffsets(uint256 tokenId_) public pure returns (uint256) {
        if ((tokenId_ >= 125 && tokenId_ <= 133))
            return 124;
        
        if (tokenId_ == 198) return 188;
        
        if (tokenId_ == 204 
            || tokenId_ == 205)
            return 193;
        
        if (tokenId_ == 255
            || tokenId_ == 256)
            return 242;

        else revert ("GAS Specials: Unable to determine offset!");
    }
    function getValidSpecialTokenId(uint256 tokenId_) public pure returns (uint256) {
        require(isCreatedByGAS(tokenId_), 
            "This token was not created by GAS!");

        uint256 _rawId = getRawIdFromOS(tokenId_);
        return _rawId - getTokenOffsets(_rawId);
    }

    // Migration Logic
    function migrateGangster(uint256 tokenId_) external onlySender onlyMigration {
        uint256 _newTokenId = getValidSpecialTokenId(tokenId_);

        // Burn the OpenStore Token
        OSStore.safeTransferFrom(msg.sender, burnAddress, tokenId_, 1, "");

        // Mint the new Token ID to msg.sender
        _mint(msg.sender, _newTokenId, 1, "");

        // Emit the Migration Event
        emit Migrated(msg.sender, _newTokenId, tokenId_);
    }
}