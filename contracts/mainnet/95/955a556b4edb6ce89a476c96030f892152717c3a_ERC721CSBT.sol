/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ERC721CSBT (ERC721 Claimable Soulbound Token)
// Author: 0xInuarashi of CypherLabz
// https://twitter.com/0xInuarashi || 0xInuarashi#1234 (Discord)

// NOTE: This does NOT comply to IERC721 Standards. It is purely experimental.
// It does NOT work like a normal ERC721, so I did not make it have to comply.

// JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJJYYYYYYYYYYYYYYYYYYJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJ?~~~~~~~~~~~~~~~~~~!JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJY! ................ :JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJ7::::::::::::::::::~JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJ?????????JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJ?.........!YJJJJJJJ?^::::::::!JJJJJJJJJJJJ
// JJJJJJJJJJJJJ?.........!YJJJJJJJ?:::::::::!YJJJJJJJJJJJ
// JJJJJJJJJJJJJ?..........:::::::::.....::::!YJJJJJJJJJJJ
// JJJJJJJJJJJJJ?........................::::!YJJJJJJJJJJJ
// JJJJJJJJJJJJJ?~~~~^..................:!!!!?JJJJJJJJJJJJ
// JJJJJJJJJJJJJJYYYY7::::..............:YYYYJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJY!....^~~~~. . .^^^^!JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJJJJY!    ?####.    5PPP5JJJJJJJJJJJJJJJJJ
// JJJJJJJJJJJJJJYYYY! .. 7GGGG.    YYYYYYYYYJJJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGJ:::::....:::::....~GGGG5JJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGJ::::.....:::::....^GGGG5JJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGP5555~.............^YYYYYJJJJJJJJJJJJ
// JJJJJJJJJJJJJYGGGGGGGGB!.............:JJJJJJJJJJJJJJJJJ
// JJJJJJJJJ5PPPPGGGG57777^.........????J5555YJJJJJJJJJJJJ
// JJJJJJJJJGBGBGGGGGJ.:::.........:GBBBBGGGG5JJJJJJJJJJJJ
// JJJJJJJJJGGGGGPPPGY!!!!:........:PGGGP5PPPYJJJJJJJJJJJJ
// JJJJJJJJJGGGGG5555PPPPP~........:5P555JJJJJJJJJJJJJJJJJ
// JJJJJJJJJGGGGG55555555P!::::....:5P5P5YYYYJJJJJJJJJJJJJ
// JJJJJJJJJ5P5P5555555555PGGGG^...:5P555555PYJJJJJJJJJJJJ
// JJJJJJJJJ55555555555555GBGGG^...:5PPPP555PYJJJJJJJJJJJJ
// JJJJY555555555555555555GGGGG5YYYYGGGGG555555555YJJJJJJJ
// JJJJ5PPPP55555555555555GGGGGPPPPPGGGGG55555PPPPYJJJJJJJ

///// Import Solidity Modules /////

// Short and Simple Ownable by 0xInuarashi
// Ownable follows EIP-173 compliant standard

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { 
        owner = msg.sender; 
    }
    modifier onlyOwner { 
        require(owner == msg.sender, "onlyOwner not owner!");
        _; 
    }
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}

abstract contract ERC721TokenURI {

    string public baseTokenURI;

    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }

    function _toString(uint256 value_) internal pure virtual 
    returns (string memory _str) {
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            _str := sub(m, 0x20)
            mstore(_str, 0)

            let end := _str

            for { let temp := value_ } 1 {} {
                _str := sub(_str, 1)
                mstore8(_str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, _str)
            _str := sub(_str, 0x20)
            mstore(_str, length)
        }
    }

    function _getTokenURI(uint256 tokenId_) internal virtual view 
    returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_)));
    }
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) 
    external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

contract ERC721CSBT is ERC721TokenURI, Ownable {
    
    ///// Events /////
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    
    ///// Token Data /////
    string public name; 
    string public symbol;

    ///// Interface Data /////
    IERC721 public immutable ERC721Token;

    ///// Token Storage /////
    /** @dev these structs can be expanded to fill the empty bytes */
    struct TokenData {
        address owner;
    }

    //// Token Mappings /////
    mapping(uint256 => TokenData) public _tokenData;

    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        address _owner = _tokenData[tokenId_].owner;
        return _owner;
    }

    ///// Constructor /////
    constructor(string memory name_, string memory symbol_, address erc721_) {
        name = name_;
        symbol = symbol_;
        ERC721Token = IERC721(erc721_);
    }
    
    ///// Ownable Settings /////
    function setBaseTokenURI(string calldata uri_) external onlyOwner {
        _setBaseTokenURI(uri_);
    }

    ///// ERC721-Like Functions /////
    function _transfer(address from_, address to_, uint256 tokenId_) internal 
    virtual { unchecked {
        _tokenData[tokenId_].owner = to_;
        emit Transfer(from_, to_, tokenId_);
    }}

    ///// ERC721CSBT Functions /////
    function callToken(uint256 tokenId_) external {
        address _owner = ownerOf(tokenId_);
        address _ERC721Owner = ERC721Token.ownerOf(tokenId_);
        require(_ERC721Owner == msg.sender, "You are not the owner!");
        _transfer(_owner, _ERC721Owner, tokenId_);
    }
    function burnToken(uint256 tokenId_) external {
        address _owner = ownerOf(tokenId_);
        address _ERC721Owner = ERC721Token.ownerOf(tokenId_);
        require(_ERC721Owner == msg.sender, "You are not the owner!");
        _transfer(_owner, address(0), tokenId_);
    }

    ///// ERC165 Interface /////
    function supportsInterface(bytes4 iid_) public virtual view returns (bool) {
        return  iid_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
                iid_ == 0x80ac58cd || // ERC165 Interface ID for ERC721
                iid_ == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
    }

    ///// TokenURI Things /////
    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {
        return _getTokenURI(tokenId_);
    }
}