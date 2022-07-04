/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT
// File: contracts/Metaverse/ERC721SRC/OWNABLE.sol


pragma solidity 0.8;

abstract contract Ownable {
    address private owner_;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
    constructor() {
        _transferOwnership(msg.sender);
    }

  
    function owner() public view virtual returns (address) {
        return owner_;
    }


    modifier onlyOwner() {
        require(owner() == msg.sender, "ERROR: caller is not the owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        // _transferOwnership(address(0));
        _transferOwnership(address(this)); // immortality
    }

  
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERROR: new owner can not zero address");
        _transferOwnership(newOwner);
    }

 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner_;
        owner_ = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/Metaverse/ERC721SRC/ADDRESS.sol


pragma solidity 0.8;

library ADDRESS {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}
// File: contracts/Metaverse/ERC721SRC/MATH.sol


pragma solidity 0.8;

library MATH {

    bytes16 private constant SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) { return "0"; }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    // =============================================================

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function dec(uint256 val) internal pure { // decrement
        require(val > 0, "ERROR: overflow");
        unchecked { val -= 1; }
    }

    function inc(uint256 val) internal pure { // increment
        unchecked { val += 1; }
    }
}
// File: contracts/Metaverse/ERC721SRC/IERC2981.sol


pragma solidity 0.8;

/// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
/// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
interface IERC2981 /*is IERC165*/ {
    /*
        tokenId 
        _salePrice  by _tokenId
        receiver
        royaltyAmount for _salePrice (10000 = 100%)
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

/*
// https://eips.ethereum.org/EIPS/eip-2981
bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

function checkRoyalties(address _contract) internal returns (bool) {
    (bool success) = IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
    return success;
 }
*/
// File: contracts/Metaverse/ERC721SRC/IERC721Enumerable.sol


pragma solidity 0.8;

///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}
// File: contracts/Metaverse/ERC721SRC/IERC721Metadata.sol


pragma solidity 0.8;

///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
// File: contracts/Metaverse/ERC721SRC/IERC721TokenReceiver.sol


pragma solidity 0.8;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}
// File: contracts/Metaverse/ERC721SRC/IERC721.sol


pragma solidity 0.8;

///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is IERC165 */ {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
// File: contracts/Metaverse/ERC721SRC/IERC165.sol


pragma solidity 0.8;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
// File: contracts/Metaverse/ERC721SRC/ERC721.sol


pragma solidity 0.8;
// https://eips.ethereum.org/EIPS/eip-721

// dev shadow protection: 
// local var = _xyz  -  satate var = xyz_  -  other var = xyz || XYZ
// pub/ext func = xyz()  -  priv/int func = _xyz()

// almost marcketplaces need => ownable + ierc165 => for connect to nft`s

// --- requirments ---






// --- libs ---




abstract contract ERC721 is IERC165, IERC721, IERC721TokenReceiver, IERC721Metadata, IERC721Enumerable, IERC2981, Ownable {
    // lib's =====================================================================
    using MATH for uint256;
    using ADDRESS for address;

    // variables =====================================================================
    string private name_;       // NFT NAME
    string private symbol_;     // NFT SYMBOL
    string private baseURI_;    // core uri
    uint256 private tokenId_;   // iterat minted token`s
    uint256 private total_;     // total token`s
    uint256 private globalRoyality_; // between 0 to 10
    bool private isGlobalRoyality_ = false; // security check

    mapping(address => uint256) private balanceOf_;         // owner -> token`s 
    mapping(uint256 => address) private ownerOf_;           // token ID -> owner
    mapping(uint256 => string) private tokenURI_;           // token ID -> uri
    mapping(uint256 => address) private approval_;          // token ID -> approved address
    mapping(address => mapping(address => bool)) private allowance_; // owner -> operator -> approvals
    mapping(uint256 => uint256) private royalties_; // 10000 = 100% - 1000 = 10% - 100 = 1%

    // yells =====================================================================
    event RoyalityChange(uint256 indexed tokenId, uint256 percent, uint256 time);

    // validators =====================================================================
    modifier exist(uint256 _tokenId) {
        _exist(_tokenId);
        _;
    }

    // validators conterbut =====================================================================
    function _exist(uint256 _tokenId) internal view {
        ownerOf_[_tokenId] != address(0);
    }

    // initial =====================================================================
    constructor(
        string memory __name,
        string memory __symbol,
        uint256 __globalRoyality
    ) {
        name_ = __name;
        symbol_ = __symbol;
        tokenId_ = 0;
        if(__globalRoyality <= 100){globalRoyality_ = __globalRoyality;}
        __globalRoyality <= 100 ? globalRoyality_ = __globalRoyality : globalRoyality_ = 0;
    }

    // register =====================================================================
    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool) {
        return interfaceId == type(IERC165).interfaceId || 
        interfaceId == type(IERC721).interfaceId || 
        interfaceId == type(IERC721TokenReceiver).interfaceId || 
        interfaceId == type(IERC721Metadata).interfaceId || 
        interfaceId == type(IERC721Enumerable).interfaceId ||
        interfaceId == type(IERC2981).interfaceId;
    }

    // calculations / logics =====================================================================
    function name() external virtual override view returns (string memory _name) {
        _name = name_;
    }

    function symbol() external virtual override view returns (string memory _symbol) {
       _symbol = symbol_;
    }

    function tokenURI(uint256 _tokenId) external virtual override view returns (string memory) {
        return tokenURI_[_tokenId];
    }

    function balanceOf(address _owner) external virtual override view returns (uint256) {
        return balanceOf_[_owner];
    }

    function ownerOf(uint256 _tokenId) external virtual override view returns (address) {
        return ownerOf_[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable virtual override {
        require(_isApprovedForAll(ownerOf_[_tokenId],_from) || _from == ownerOf_[_tokenId], "ERROR: transfer would from the owner or approved");
        _transferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable virtual override {
        require(_isApprovedForAll(ownerOf_[_tokenId],_from) || _from == ownerOf_[_tokenId], "ERROR: transfer would from the owner or approved");
        _transfer(_from, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable virtual override {
        require(_isApprovedForAll(ownerOf_[_tokenId],_from) || _from == ownerOf_[_tokenId], "ERROR: transfer would from the owner or approved");
        _transfer(_from, _to, _tokenId);
    }
    
    function transfer(address _to, uint256 _tokenId) external payable virtual returns (bool) {
        _transfer(_msgSender(), _to, _tokenId);
        return true;
    }

    function approve(address _approved, uint256 _tokenId) external payable exist(_tokenId) virtual override {
        require(_msgSender() == ownerOf_[_tokenId], "ERROR: only owner of token");
        require(_msgSender() != _approved, "ERROR: owner was approved");
        approval_[_tokenId] = _approved;
        emit Approval(_msgSender(), _approved, _tokenId);
    }

    // setApprovalForAll function is a bug in ethereum, controling whole your nft`s to anonymus sign in frontend
    function setApprovalForAll(address _operator, bool _approved) external virtual override {
        require(_msgSender() != _operator, "ERROR: approve to not owner");
        allowance_[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external exist(_tokenId) virtual override view returns (address) {
        return approval_[_tokenId];
    }

    function _isApprovedForAll(address _owner, address _operator) internal virtual view returns (bool) {
       return allowance_[_owner][_operator];
    }

    function isApprovedForAll(address _owner, address _operator) external virtual override view returns (bool) {
       return allowance_[_owner][_operator];
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external virtual override returns(bytes4) {
        // use: _checkOnERC721Received in transfer functions
    }

    // if add MAX in your contract, total can not be higer then the maimum supply
    function totalSupply() external virtual override view returns (uint256) {
        return total_;
    }
    
    // royality set-update/get/delete & royaltyInfo + change isGlobalRoyality_ status - have 5 functions
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external exist(_tokenId) virtual override view returns (address _receiver, uint256 _royaltyAmount){
        // 10000 = 100% - 1000 = 10% - 100 = 1% -> we need 100\10% to 10\1%
        isGlobalRoyality_ == false ? 
            _royaltyAmount = (_salePrice * royalties_[_tokenId]) / 10000 : 
            _royaltyAmount = (_salePrice * globalRoyality_) / 10000;
        _receiver = ownerOf_[_tokenId];
    }

    function globalRoyalityStatus() external onlyOwner virtual {
        isGlobalRoyality_ != isGlobalRoyality_;
    }

    function setRoyaltyPercent(uint256 _tokenId, uint256 _percent) external exist(_tokenId) virtual {
        require(_isApprovedForAll(ownerOf_[_tokenId], _msgSender()) || _msgSender() == ownerOf_[_tokenId], "ERROR: would from the owner or approved");
        if(_percent < 100 && _percent >= 0){
            royalties_[_tokenId] = _percent;
            emit RoyalityChange(_tokenId, _percent, block.timestamp);
        } else {
            revert("ERROR: not more then 10% for royality, invest on your talents");
        }
    }

    function getRoyaltyPercent(uint256 _tokenId) external exist(_tokenId) virtual returns (uint256) {
        return royalties_[_tokenId];
    }

    function removeRoyaltyPercent(uint256 _tokenId) external exist(_tokenId) virtual {
        royalties_[_tokenId] = 0;
        emit RoyalityChange(_tokenId, 0, block.timestamp);
    }

    /*
    for indexing need alot of gas, watch below for conditions & functions : 
    Conditions: from == address(0) -- from != to -- to == address(0) -- to != from 
    call index funcs in --> _beforeTransfer(...)  &  _afterTransfer(...) --> by using conditions as a helper
    ** so i no recomend to use, but just use conditions if you like to use **
    */
    // tokenByIndex => more gas spending
    function tokenByIndex(uint256 _index) external virtual override view returns (uint256) {

    }

    // tokenOfOwnerByIndex => more gas spending
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external virtual override view returns (uint256) {

    }

    // logic`s =====================================================================
    function _transfer(address _from, address _to, uint256 _tokenId) internal exist(_tokenId) virtual {
        require(ownerOf_[_tokenId] == _from, "ERROR: why spen gas!");
        require(_to != address(0), "ERROR: black hole not accepted");
        _beforeTransfer(_from, _to, _tokenId);
        _approve(address(0), _tokenId);
        balanceOf_[_from] -= 1;
        balanceOf_[_to] += 1;
        ownerOf_[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        _afterTransfer(_from, _to, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) internal exist(_tokenId) virtual {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERROR: transfer to not accepted ERC721Receiver wallet/contract");
    }    

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) internal exist(_tokenId) virtual {
        _transferFrom(_from, _to, _tokenId, _data);
    }

    function _approve(address _approved, uint256 _tokenId) internal exist(_tokenId) virtual {
        require(_msgSender() == ownerOf_[_tokenId], "ERROR: only owner of token");
        require(_msgSender() != _approved, "ERROR: owner was approved");
        approval_[_tokenId] = _approved;
        emit Approval(_msgSender(), _approved, _tokenId);
    }

    // setup uri setting =====================================================================
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI_;
    }

    function _setURI(string calldata _uri) internal virtual {
        baseURI_ = _uri;
    }

    function _setTokenURI(string calldata _uri, uint256 _tokenId) internal exist(_tokenId) virtual {
        tokenURI_[_tokenId] = _uri;
    }
    
    function _tokenURI(uint256 _tokenId, string calldata _prefix) internal exist(_tokenId) view virtual returns (string memory) {
        string memory _URI = _baseURI();
        return bytes(_URI).length > 0
            ? string(abi.encodePacked(_URI, _tokenId.toString(), _prefix))
            : "";
    }

    // tools =====================================================================
    // ERC721 Holder | trackable
     function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal virtual returns (bool) {
        if (_to.isContract()) {
            try IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 _returnval) {
                return _returnval == IERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) { revert("ERROR: transfer to non ERC721Receiver implementer"); } 
                else { assembly { revert(add(32, reason), mload(reason)) } }
            }
        } else {
            return true;
        }
    }

    function _currentId() internal view virtual returns (uint256) {
        return tokenId_;
    }

    //*************************************************************************************************
    function _safeMint(address _to, uint256 _tokenId) internal exist(_tokenId) virtual {
        _safeMint(_to, _tokenId, "");
    }

    function _safeMint(address _to, uint256 _tokenId, bytes memory _data) internal exist(_tokenId) virtual {
        _mint(_to, _tokenId);
        require(
            _checkOnERC721Received(address(0), _to, _tokenId, _data),
            "ERROR: transfer to not accepted ERC721Receiver wallet/contract"
        );
    }
    
    function _safeMint(address _to, uint256 _tokenId, string calldata _uri) internal exist(_tokenId) virtual {
        _safeMint(_to, _tokenId, _uri, "");
    }

    function _safeMint(address _to, uint256 _tokenId, string calldata _uri, bytes memory _data) internal exist(_tokenId) virtual {
        _mint(_to, _tokenId, _uri);
        require(
            _checkOnERC721Received(address(0), _to, _tokenId, _data),
            "EERROR: transfer to not accepted ERC721Receiver wallet/contract"
        );
    }

    function _mint(address _to, uint256 _tokenId) internal exist(_tokenId) virtual {
        require(_to != address(0), "ERROR: mint to black hole!");
        _beforeTransfer(address(0), _to, _tokenId);
        balanceOf_[_to] += 1;
        ownerOf_[_tokenId] = _to;
        total_ += 1;
        royalties_[_tokenId] = globalRoyality_;
        emit Transfer(address(0), _to, _tokenId);
        _afterTransfer(address(0), _to, _tokenId);
    }

    function _mint(address _to, uint256 _tokenId, string calldata _uri) internal exist(_tokenId) virtual {
        require(_to != address(0), "ERROR: mint to black hole!");
        _beforeTransfer(address(0), _to, _tokenId);
        balanceOf_[_to] += 1;
        ownerOf_[_tokenId] = _to;
        _setTokenURI(_uri, _tokenId);
        total_ += 1;
        royalties_[_tokenId] = globalRoyality_;
        emit Transfer(address(0), _to, _tokenId);
        _afterTransfer(address(0), _to, _tokenId);
    }


    function mint(address _to, uint256 _tokenId) external payable virtual {
        _safeMint(_to, _tokenId);
    }

    function mint() external payable virtual {
        _safeMint(_msgSender(), tokenId_++);
    }

    function mint(string calldata _uri) external payable virtual {
        _safeMint(_msgSender(), tokenId_++, _uri);
    }

    // burn
    function _burn(uint256 _tokenId) internal exist(_tokenId) virtual {
        require(ownerOf_[_tokenId] != address(0), "ERROR: only existed item");
        require(_msgSender() == ownerOf_[_tokenId], "ERROR: only token owner");
        _beforeTransfer(_msgSender(), address(0), _tokenId);
        _approve(address(0), _tokenId);
        balanceOf_[_msgSender()] -= 1;
        ownerOf_[_tokenId] = address(0); // delete ownerOf_[_tokenId];
        
        if (bytes(tokenURI_[_tokenId]).length != 0) {
            delete tokenURI_[_tokenId];
        }

        emit Transfer(_msgSender(), address(0), _tokenId);
        _afterTransfer(_msgSender(), address(0), _tokenId);
    }

    function burn(uint256 _tokenId) external payable virtual {
        _burn(_tokenId);
    }

    //*************************************************************************************************

    // empty tester/validator
    function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTransfer(address from, address to, uint256 tokenId) internal virtual {}
    /* Conditions: from == address(0) -- from != to -- to == address(0) -- to != from */

    // helper =====================================================================
    function _this() internal view virtual returns (address) {
        return address(this);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    /* =============================================
                    --- ERC721 ---
    ================================================
            creator :       mosi
            version :       1.0.2022
            email :         [email protected]
            linkedin :      moslem-abbasi
            github :        mosi-sol
    ================================================
            fully functional NFT ERC721
    ================================================
    how to use : following this folder -> mock.sol
                    suggestion : 
    ================================================
        split each functional point to use in 
        your projects. absolutly for less gas.
    ===============================================*/
    

}
// File: contracts/Metaverse/ERC721SRC/MOCK.sol


pragma solidity 0.8;


// NFT MOCK
contract NFT is ERC721 {
    uint count;
    constructor(
        string memory __name,
        string memory __symbol,
        uint256 __globalRoyality
    ) ERC721(__name, __symbol, __globalRoyality) {
        count = 0;
        __globalRoyality = 100;
    }

    // this important for market places + owner funcions
    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool) {
        return interfaceId == type(ERC721).interfaceId;
    }

    function mint() external payable virtual override {
        _safeMint(_msgSender(), count);
        unchecked { count += 1; }
    }

    function mint(string calldata _uri) external payable virtual override {
        _safeMint(_msgSender(), count, _uri);
        unchecked { count += 1; }
    }

    function burn(uint256 _tokenId) external payable virtual override {
        _burn(_tokenId);
    }
}