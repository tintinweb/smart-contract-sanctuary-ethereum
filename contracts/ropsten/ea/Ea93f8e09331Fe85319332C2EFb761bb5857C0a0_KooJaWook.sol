/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface BerryStaking {
    function lockedStaking(address user, uint256 tokenId) external;
    function getTotalIds(address _user) external view returns(uint256[] memory);
}


interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {

    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    address[] public NFTHolders;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        bool _isAvailable = isAlreadyAvailable(to);
        if(!_isAvailable && tokenId<10000){
            NFTHolders.push(to);
        }

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }


    function removeIndex(address to) private {
        for(uint256 i; i<NFTHolders.length; i++){
            if(NFTHolders[i] == to){
                NFTHolders[i] = NFTHolders[NFTHolders.length -1];
                NFTHolders.pop();
            }
        }
    }
    function isAlreadyAvailable(address _to) private view returns(bool){
        for(uint256 i; i<NFTHolders.length; i++){
            if(_to == NFTHolders[i])
                return true;
        }
        return false;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        (bool _isAvailable) = isAlreadyAvailable(to);
       
        if(balanceOf(from) == 1){
            removeIndex(from);
        }

        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);

        if(!_isAvailable && tokenId<10000){
            NFTHolders.push(to);
        }

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
library Strings {

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract SignVerify {

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(hash, v, r, s);
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}



contract KooJaWook is Ownable,SignVerify,ERC721Enumerable{

    IERC20 public Token;
    IERC20 public BCash;
    BerryStaking public BERRY;

    using Strings for uint256;
    using SafeMath for uint256;

    /*************************************** VARIABLES *****************************************/
    address signerAddress;
    address public collectionWallet;
    uint256 startAT;
    uint256 startingPrice = 2_400 ether ;
    uint256 discountRate = 1 ether;
    uint256 setSlot = 190;
    uint256 priceDecrementTime = 10 minutes;
    uint256 public publicPrice = 0.5 ether;
    uint256 public genesisPrice = 1_0000 ether;
    uint256 public totalFreeMintedNfts;
    uint256 public totalOwnerMintedNfts;
    uint256 public totalDutchMintedNfts;
    uint256 public totalPublicMintedNfts;
    uint256 public totalGenesisMintedNfts;
    uint256 public totalCommonMintedNfts;
    uint256 public totalBoosterMintedNfts;
    uint256 public BcashPercentage = 3;
    uint256 public randomBoxPrice = 1_000 ether;
    uint256 level5Price = 1_000 ether;
    uint256 level6Price = 2_000 ether;

    uint256[1100] private _firstCollection;     
    uint256[1000] private _secondCollection;    
    uint256[5400] private _thirdCollection;     
    uint256[100] private _fourthCollection;     
    uint256[400] private _fifthCollection;      
    uint256[2000] private _sixthCollection;     
    uint256[500] private _seventhCollection;
    uint256[] public openSeaNFTS;

    string public prefix10kURI = "https://gateway.pinata.cloud/ipfs/QmPYw6aAtmN8JRM6cU9uDYr9uHL5TUqdf2SNvdo6UnxCH4/";
    string public prefixBoosterURI = "https://gateway.pinata.cloud/ipfs/QmSBQJdaBDsK7QnogeFcU9DYhqBCvNLnjDgT2rvsHELoQb/";


    uint256[100] randomBoxProbability =
    [
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
    ,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    ,3,3,3,3,3,3,3,3,3,3,3,3
    ,4,4,4,4,4,4,4,4,4,4
    ,5,5,5
    ,6,6,
    7
    ];
    
    bool public randomBoxStatus ;
    bool public freeMintStarted ;
    bool public auctionStarted ;
    bool public publicStarted ;
    bool public genesisStarted ;
    bool public lock = false;
    
    /*************************************** MAPPING *****************************************/

    mapping (bytes32 => bool) public usedHash;
    mapping (address => bool) public claimedUser;
    mapping (address => uint256) public totalFreeMinted;
    mapping (address => uint256) public totalOwnerMinted;
    mapping (address => uint256) public totalDutchMinted;
    mapping (address => uint256) public totalPublicMinted;
    mapping (address => uint256) public totalBreedMinted;
    mapping (address => uint256) public totalCommonMinted;
    mapping (address => uint256) public totalBoosterMinted;

    mapping (uint256 => string) public tokenURIs;
    mapping (uint256 => Collection) public collection;
    mapping (uint256 => uint256) private freeMintingTime;
    mapping (uint256 => uint256) public dutchMintingTime;
    mapping (uint256 => uint256) public tokenIdType;
    mapping (uint256=>address) public NFTcontractAddresses;
    mapping (address=>uint256[]) public userWinnerLevel;


    /*************************************** EVENTS *****************************************/
    event freeMint(address indexed from, address indexed to, uint256 _count);
    event dutchMint(address indexed from, address indexed to, uint256 _count);
    event publicMint(address indexed from, address indexed to, uint256 _count);
    event ownerMint(address indexed from, address indexed to, uint256 _count);
    event randomBoxMint(address indexed from, address indexed to, uint256 tokenId);
    event genesisMint(address indexed from, address indexed to, uint256 tokenId);
    event unCommonMint(address indexed from, address indexed to, uint256 tokenId);
    event boosterMint(address indexed from, address indexed to, uint256 tokenId);
    event klayWithDraw(address indexed from, address indexed to, uint256 indexed _balance);
    event randomBox_(uint256 indexed randomBoxNo);
    event collectionSet(bool indexed collectionset);
    event OddsSet(bool indexed oddsSet);


    struct Collection 
    {
        uint256 collectionSupply;
        uint256 availableTokens; 
    }

    constructor
    (IERC20 _BCB ,IERC20 _BCash) 
    ERC721("KooJaWook", "KJW")
    {
        Token = _BCB;
        BCash = _BCash;
        setCollectionData();
        collectionWallet = owner();
    }

    function setCollectionData()
    internal
    {

        collection[1].collectionSupply = 1100;
        collection[1].availableTokens = 1100;

        collection[2].collectionSupply = 1000;
        collection[2].availableTokens = 1000;

        collection[3].collectionSupply = 5400;
        collection[3].availableTokens = 5400;

        collection[4].collectionSupply = 100;
        collection[4].availableTokens = 100;

        collection[5].collectionSupply = 400;
        collection[5].availableTokens = 400;    

        collection[6].collectionSupply = 2000;
        collection[6].availableTokens = 2000;
        
        collection[7].collectionSupply = 500;
        collection[7].availableTokens = 500;

        emit collectionSet(true);
    }

    /*
    *   The user can claim NFT only one time
    *   Generated tokenId will directly stake into Staking contract and lock for 150 days 
    */

    function claimNFT
    (uint256 _count,uint256 _nonce, bytes memory signature)
    external
    {
      require(freeMintStarted, "Mint Not Started");
      require(_count <= collection[1].availableTokens ,"NOT ENOUGH TOKENS IN SUPPLY");
      require(claimedUser[msg.sender] != true," Already Claimed ");
      address user = msg.sender;
      uint256 random_id;
      bytes32 hash = keccak256(   
              abi.encodePacked(   
                toString(address(this)),   
                toString(msg.sender),
                _nonce
              )
          );
      require(!usedHash[hash], "Invalid Hash");   
      require(recoverSigner(hash, signature) == signerAddress, "Signature Failed");   
      usedHash[hash] = true;
        for(uint256 i = 1; i <= _count; i++)
        {   random_id = useRandomAvailableToken(1,1,1);
            _mint(address(BERRY), random_id);
            BERRY.lockedStaking(user, random_id);
            freeMintingTime[random_id] = block.timestamp;
            tokenIdType[random_id] = 1;
        }
        totalFreeMinted[msg.sender]+=_count;
        claimedUser[msg.sender] = true;
        totalFreeMintedNfts += _count;

        emit freeMint(address(this), address(BERRY), _count);
    }

    /*
    *   The user can check price per card or for more than one card
    *   Price will decrease after every 10 minutes
    *   Maximum priceDecrement is 50 BCB
    */

    function getPrice(uint256 _count) public view returns (uint256)
    {
        uint256 totalPrice;
        uint256 discount;
        uint256 Price;
        uint256 timeElapsed = (block.timestamp.sub(startAT)).div(priceDecrementTime) ;
        if(timeElapsed <= setSlot)
        {discount = discountRate.mul(timeElapsed);
        Price = startingPrice.sub(discount);
        totalPrice = Price.mul(_count);
        }
        else
        {totalPrice = _count.mul(500 ether);}
        return totalPrice;
    }

    /*
    *   The user 
    */

    function mintDutch(uint256 _count)
    public
    {
        require(auctionStarted, " AUCTION HAS NOT STARTED YET.! ");
        require(_count <= collection[2].availableTokens ,"NOT ENOUGH TOKENS IN SUPPLY");
        address user = msg.sender;
        uint256
        total
        =
        collection[1].collectionSupply;
        Token.transferFrom(msg.sender,collectionWallet,getPrice(_count));
        uint256 random_id;
        for(uint256 i = 1; i <= _count; i++)
        {   random_id = useRandomAvailableToken(1,1,2);
            uint256 tokenId = random_id + total;
            _mint(address(BERRY),tokenId);
            BERRY.lockedStaking(user, tokenId);
            dutchMintingTime[tokenId] = block.timestamp;
            tokenIdType[tokenId] = 2;
        }
        totalDutchMinted[msg.sender] += _count;
        totalDutchMintedNfts += _count;
        
        emit dutchMint(address(this), address(BERRY), _count);
    }

    function mintPublic (uint256 _count)
    public
    payable
    {
        require (publicStarted, "Mint Not Started");
        require(_count <= collection[3].availableTokens ,"NOT ENOUGH TOKENS IN SUPPLY");
        require (msg.value >=(_count * publicPrice), "Invalid Klay Sent");
        uint256
        total
        =
         collection[1].collectionSupply
        +collection[2].collectionSupply;

        uint256 random_id;
        uint256 tokenId;
        for (uint256 i = 1; i <= _count; i++)
        {   random_id = useRandomAvailableToken(1,1,3);
            tokenId = random_id + total;
            _mint(msg.sender, tokenId);
            tokenIdType[tokenId] = 3;
        }
        payable(collectionWallet).transfer(msg.value);
        totalPublicMinted[msg.sender]+=_count;
        totalPublicMintedNfts += _count;

        emit publicMint(address(this), msg.sender, _count);

    }

    function mintOwner (uint256 _count, address _account)
    public
    onlyOwner
    {   
        require(_count <= collection[4].availableTokens ,"NOT ENOUGH TOKENS IN SUPPLY");
        uint256
        total
        =
         collection[1].collectionSupply
        +collection[2].collectionSupply
        +collection[3].collectionSupply;

        uint256 random_id;
        uint256 tokenId;
        for (uint256 i = 1; i <= _count; i++)
        {   random_id = useRandomAvailableToken(1,1,4);
            tokenId = random_id + total;
            _mint(_account, tokenId);
            tokenIdType[tokenId] = 4;
        }
        totalOwnerMinted[msg.sender]+=_count;
        totalOwnerMintedNfts += _count;

        emit ownerMint(address(this), _account, _count);
    }

    function mintUncommonIds()
    private
    {
        require(collection[5].availableTokens>0 ,"NOT ENOUGH TOKENS IN SUPPLY");
        uint256 random_id ;
        uint256 tokenId;
        uint256
        total
        =
         collection[1].collectionSupply
        +collection[2].collectionSupply
        +collection[3].collectionSupply
        +collection[4].collectionSupply;
        random_id = useRandomAvailableToken(1,1,5);
        tokenId = random_id + total;
        _mint(msg.sender, tokenId);
        tokenIdType[tokenId] = 5;
        totalCommonMinted[msg.sender] += 1;
        totalCommonMintedNfts += 1;
        emit unCommonMint(address(this), msg.sender, tokenId);
    }

    function mintBreed(uint256 _id1,uint256 _id2, uint256 _nonce, bytes memory signature)
    public
    {
        require(genesisStarted," Mint Not Started ");
        require(collection[6].availableTokens>0,"NOT ENOUGH TOKENS IN SUPPLY");
        require(Token.balanceOf(msg.sender) >= genesisPrice," Don't have enough BCB ");
        uint256 tokenId;
        uint256 random_id;
        bytes32 hash = keccak256
        (   
            abi.encodePacked(   
            toString(address(this)),   
            toString(msg.sender),
            _nonce
            )
        );
        require(!usedHash[hash], " Invalid Hash ");   
        require(recoverSigner(hash, signature) == signerAddress, " Signature Failed ");   
        usedHash[hash] = true ;
        Token.transferFrom(msg.sender,collectionWallet,genesisPrice);
        uint256
        total
        = 
         collection[1].collectionSupply
        +collection[2].collectionSupply
        +collection[3].collectionSupply
        +collection[4].collectionSupply
        +collection[5].collectionSupply
        ;
        ERC721._burn(_id1);
        ERC721._burn(_id2);
        random_id = useRandomAvailableToken(1,1,6);
        tokenId = random_id + total;
        _mint(msg.sender,tokenId);
        totalBreedMinted[msg.sender] += 1;
        tokenIdType[tokenId] = 6;
        totalGenesisMintedNfts += 1 ;

        emit genesisMint(address(this), msg.sender, tokenId);
    }

    

    function mintBoosterId()
    private
    {
        require(collection[7].availableTokens>0 ,"NOT ENOUGH TOKENS IN SUPPLY");
        uint256 tokenId;
        uint256 random_id;
        uint256 total
        = 
         collection[1].collectionSupply
        +collection[2].collectionSupply
        +collection[3].collectionSupply
        +collection[4].collectionSupply
        +collection[5].collectionSupply
        +collection[6].collectionSupply
        ;

        random_id = useRandomAvailableToken(1,1,7);
        tokenId = random_id+total;
        _mint(msg.sender,tokenId);
        tokenIdType[tokenId] = 7;
        totalBoosterMinted[msg.sender] += 1;
        totalBoosterMintedNfts += 1;
        emit boosterMint(address(this), msg.sender, tokenId);
    }
    /*
    * Function to get NFTHolders except BoosterCards
    */
    function getNFtHolders() public view returns(address[] memory)
    {return NFTHolders;}
    /*
    * Function to get Id-Type of each sale
    */
    function getIdType(uint256 tokenId) public view returns(uint256)
    {return tokenIdType[tokenId];}
    /*
    * Function to get freeMintingTime of tokenId
    */
    function getFreeMintingTime(uint256 tokenId) external view returns(uint256)
    {return freeMintingTime[tokenId];}
    /*
    * Function to get dutchMintingTime of tokenId
    */
    function getDutchMintingTime(uint256 tokenId) external view returns(uint256)
    {return dutchMintingTime[tokenId];}
    /*
    * Function to make minting time zero which will be called externally
    */
    function forMintingTimeZero(uint256 tokenID) external
    {   if(tokenIdType[tokenID] == 1)
        {freeMintingTime[tokenID] = 0;}
        else if(tokenIdType[tokenID] == 2)
        {dutchMintingTime[tokenID] = 0;}
    }
    /*
    * Function to set TokenIDType = 0
    */
    function setTokenIdType(uint256 tokenId) external
    {tokenIdType[tokenId] = 0 ;}
    /*
    * Function to get allMinted tokenIds from this contract
    */
    function walletOfOwner(address _owner) public view returns (uint256[] memory)
    {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++)
        {tokenIds[i] = tokenOfOwnerByIndex(_owner, i);}
        return tokenIds;
    }

    /***************************** Owner functions *****************************/


    /*
        Owner has to add staking contract address and signer address
    */
    function addSignerNstaking(address _signer,BerryStaking _stakingAddress)
    public 
    onlyOwner
    {
        signerAddress = _signer;                
        BERRY = _stakingAddress;
    }
    /*
      Function to start sales
        - FreeMint
        - dutchMint
        - publicMint
        - genesisMint
        - RandomBox
        onlyOwner can call this function
    */ 
    function startSale(uint256 saleNo)
    public
    onlyOwner
    {   require(saleNo >=1 && saleNo <= 5,"Choose the saleNo Between Ranges");
        if(saleNo == 1)
        {   if(freeMintStarted)
            {   freeMintStarted = false;
                auctionStarted = false;
                publicStarted = false;
                genesisStarted = false;
            }
            else
            {   freeMintStarted = true;
                auctionStarted = true;
                startAT = block.timestamp;
            }
        }
        else if(saleNo == 2)
        {   if(auctionStarted)
            {   auctionStarted = false;
                freeMintStarted = false;
                publicStarted = false;
                genesisStarted = false;
                startAT = 0;
            }
            else
            {   auctionStarted = true;
                startAT = block.timestamp;
            }
        }
        else if(saleNo == 3) 
        {   if(publicStarted)
            {   publicStarted = false;
                freeMintStarted = false;
                auctionStarted = false;
                genesisStarted = false;
            }
            else
            {publicStarted = true;}
        }
        else if(saleNo == 4)
        {   if(genesisStarted)
            {   publicStarted = false;
                freeMintStarted = false;
                auctionStarted = false;
                genesisStarted = false;
            }
            else
            {genesisStarted = true;}
        }
        else if(saleNo == 5)
        {   if(randomBoxStatus)
            {randomBoxStatus = false;}
            else
            {randomBoxStatus = true;}
        }
    }

    /*
    * Function to change the Collection Wallet in which BCB or KLAY will be collected
    * onlyOwner can call this function.
    */  
    function changeCollectionWallet(address wallet) public onlyOwner
    {collectionWallet = wallet;}
    /*
    * Function to withdraw BCB-Tokens
    * onlyOwner can call this function.
    */ 
    function withdrawBCB() public onlyOwner
    {Token.transferFrom(address(this),msg.sender,Token.balanceOf(address(this)));}
    /*
    * Function to withdraw BCash-Tokens
    * onlyOwner can call this function.
    */ 
    function withdrawBCasH() public onlyOwner
    {BCash.transferFrom(address(this),msg.sender,Token.balanceOf(address(this)));}
    /*
    * Function to withdraw KLAY
    * onlyOwner can call this function.
    */ 
    function withDrawKLAY() public onlyOwner
    {   payable(msg.sender).transfer(address(this).balance);
        emit klayWithDraw(address(this), msg.sender, address(this).balance);
    }
    /*
    * Function to change genesisPrice
    * onlyOwner can call this function.
    */ 
    function setRandomBoxPrice(uint256 Price) public onlyOwner
    {randomBoxPrice = Price;}
    /*
    * Function to change genesisPrice
    * onlyOwner can call this function.
    */ 
    function setGenesisPrice(uint256 Price) public onlyOwner
    {genesisPrice = Price;}
    /*
    * Function to change publicPrice
    * onlyOwner can call this function. 
    */ 
    function setPublicPrice(uint256 Price) public onlyOwner
    {publicPrice = Price;}
    /*
    * Function to change BcashPercentage
    * onlyOwner can call this function.
    */ 
    function setBcashPercentage(uint256 _percent) public onlyOwner
    {BcashPercentage = _percent;}
    /*
    * Function to change level5price
    * onlyOwner can call this function.
    */ 
    function setLevel5PRice(uint256 _amount) public onlyOwner
    {level5Price = _amount;}
    /*
    * Function to change level6price
    * onlyOwner can call this function.
    */ 
    function setLevel6PRice(uint256 _amount) public onlyOwner
    {level6Price = _amount;}
    /*
    * Function to change odds in randomBox
    * onlyOwner can call this function.
    */
    function setRandomOdds(uint256[100] memory Odds) public onlyOwner
    {   randomBoxProbability = Odds;
        emit OddsSet(true);
    }
    /*
    * Function to set preFix URI for all 10k cards except booster card
    * onlyOwner can call this function.
    */
    function setprefix10kURI(string calldata _uri) external onlyOwner
    {prefix10kURI = _uri;}
    /*
    * Function to set preFix URI for booster card
    * onlyOwner can call this function.
    */
    function setprefixBoosterURI(string calldata _uri) external onlyOwner
    {prefixBoosterURI = _uri;}
    /*
    * Function to set token URI of tokenid
    * onlyOwner can call this function.
    */
    function setTokenURI(string calldata _uri, uint256 _tokenId) external onlyOwner
    {   require(!lock, "ALREADY_LOCKED");
        tokenURIs[_tokenId] = _uri;
    }
    /*
    * Function to storeData of openSeaNFTS for randomBox
    * onlyOwner can call this function.
    */
    function storeNFTdata(uint256[] memory _tokenIds,address[] memory _contractAddress) public onlyOwner
    {
        for(uint256 i;i<_tokenIds.length;i++)
        {   NFTcontractAddresses[_tokenIds[i]]=_contractAddress[i];
            openSeaNFTS.push(_tokenIds[i]);
        }
    }
    /**************************************************************************************************/
    /*
    * Function to get randomAvailable token for all sales 
    */
    function useRandomAvailableToken(uint256 _numToFetch, uint256 _i,uint256 id) internal returns (uint256)
    {
        uint256 valAtIndex;
        uint256 lastIndex;
        uint256 randomNum = 
        uint256(
        keccak256(
        abi.encode(msg.sender,tx.gasprice,block.number,block.timestamp,blockhash(block.number - 1),_numToFetch,_i)));

        uint256 randomIndex = (randomNum % collection[id].availableTokens);
        if(id==1)
        {
        valAtIndex = _firstCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex)
        {   uint256 lastValInArray =_firstCollection[lastIndex];
            if (lastValInArray == 0)
            {_firstCollection[randomIndex] = lastIndex;} 
            else 
            { _firstCollection[randomIndex] = lastValInArray;}
            }
        }
        else if(id==2)
        {
        valAtIndex = _secondCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex)
        {   uint256 lastValInArray = _secondCollection[lastIndex];
            if (lastValInArray == 0)
            {_secondCollection[randomIndex] = lastIndex;}
            else
            {_secondCollection[randomIndex] = lastValInArray;}
            }  
        }
        else if(id==3)
        {
        valAtIndex = _thirdCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex)
        {
            uint256 lastValInArray = _thirdCollection[lastIndex];
            if (lastValInArray == 0)
            {_thirdCollection[randomIndex] = lastIndex;}
            else
            {_thirdCollection[randomIndex] = lastValInArray;}
            }  
        }
        else if(id==4)
        {
        valAtIndex = _fourthCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex)
        {
            uint256 lastValInArray = _fourthCollection[lastIndex];
            if (lastValInArray == 0)
            {_fourthCollection[randomIndex] = lastIndex;}
            else
            {_fourthCollection[randomIndex] = lastValInArray;}
            }
        }
        else if(id==5)
        {
        valAtIndex = _fifthCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex)
        {
            uint256 lastValInArray = _fifthCollection[lastIndex];
            if (lastValInArray == 0)
            {_fifthCollection[randomIndex] = lastIndex;}
            else
            { _fifthCollection[randomIndex] = lastValInArray;}
            }
        }
        else if(id==6)
        {
        valAtIndex = _sixthCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex)
        {
            uint256 lastValInArray = _sixthCollection[lastIndex];
            if (lastValInArray == 0)
            {_sixthCollection[randomIndex] = lastIndex;}
            else
            {_sixthCollection[randomIndex] = lastValInArray;}
            }
        }
        else if(id==7)
        {
        valAtIndex = _seventhCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex)
        {
            uint256 lastValInArray = _seventhCollection[lastIndex];
            if (lastValInArray == 0)
            {_seventhCollection[randomIndex] = lastIndex;}
            else
            { _seventhCollection[randomIndex] = lastValInArray;}
            }
        }

        uint256 result;
        if (valAtIndex == 0)
        {result = randomIndex;}
        else
        {result = valAtIndex;}
        collection[id].availableTokens--;
        return result + 1;
    }
    /*
    * Function to ClaimNFt of opensea 
    * it will be called internally in random box
    * noOne else can call this function outside of the randombox
    */
    function claimOpenSeaNFT(uint256 tokenId) internal
    {
        IERC721(NFTcontractAddresses[tokenId]).transferFrom(address(this), msg.sender, tokenId);
        NFTcontractAddresses[tokenId]=address(0);
        for(uint256 i; i< openSeaNFTS.length; i++)
        {   if(openSeaNFTS[i] == tokenId)
            {openSeaNFTS[i] = openSeaNFTS[openSeaNFTS.length -1];
            openSeaNFTS.pop();
            }
        }
    }
    /*
    * Function to get randomBox price
    * RandomBox has 7 levels
    * each levels has its own odds
    */
    function RandomBox() public
    {
        require(randomBoxStatus, "NO MORE AVAILABILITY OF RANDOM BOX");
        uint256 randomNo = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, blockhash(block.number -1), randomBoxProbability.length)));
        uint256 randomId = randomNo % randomBoxProbability.length;
        Token.transferFrom(msg.sender,address(this), randomBoxPrice);

        if(randomBoxProbability[randomId] == 1)
        {uint256 bCashAmount = (randomBoxPrice.mul(BcashPercentage)).div(100);
        BCash.transfer(msg.sender, bCashAmount);}
        else if(randomBoxProbability[randomId] == 2)
        {Token.transfer(msg.sender, 200 ether);}
        else if(randomBoxProbability[randomId] == 3)
        {mintUncommonIds();}
        else if(randomBoxProbability[randomId] == 4)
        {uint256 tokenId = getRandomOpenSeaNft();
        claimOpenSeaNFT(tokenId);}
        else if(randomBoxProbability[randomId] == 5)
        {payable(msg.sender).transfer(level5Price);} // 1000 klay
        else if(randomBoxProbability[randomId] == 6)
        {payable(msg.sender).transfer(level6Price);} // 2000 klay
        else if(randomBoxProbability[randomId] == 7)
        {mintBoosterId();}
        userWinnerLevel[msg.sender].push(randomBoxProbability[randomId]);
        emit randomBox_(randomId);
    }

    /*
    * Function to get randomBoxProbability
    */
    function getRandomBoxProb() public view returns(uint256[100] memory)
    {return randomBoxProbability;}
    /*
    * Function to get random LEVEL
    */
    function getRandomOpenSeaNft() private view returns(uint256)
    {   uint256 randomIndex;
        uint256 randomNum = 
        uint256(
        keccak256(
        abi.encode(msg.sender,tx.gasprice,block.number,block.timestamp)));
        randomIndex = (randomNum % openSeaNFTS.length);
        uint256 tokenId = openSeaNFTS[randomIndex];
        return tokenId;
    }
    /*
    * Function to get all openSeaNFTS
    */
    function getOpenSeaNFTs() public view returns(uint256[] memory)
    {return openSeaNFTS;}
    /*
    * Function to get UserRewardedLevel in randomBox
    */
    function getUserRewardedLevel(address user) public view returns(uint256[] memory)
    {return userWinnerLevel[user];}

    function _toString(uint256 value) internal pure returns (string memory ptr)
    {
        assembly {
            ptr := add(mload(0x40), 128)
            mstore(0x40, ptr)
            let end := ptr
            for { 
                let temp := value
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                temp := div(temp, 10)
            } {
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            let length := sub(end, ptr)
            ptr := sub(ptr, 32)
            mstore(ptr, length)
        }
    }
    /*
    * Function to get tokenURI of 10500 cards
    */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        string memory URI;
        if(tokenId<10001)
        {URI = string(abi.encodePacked(prefix10kURI,_toString(tokenId),".json"));}
        else if(tokenId>10000 && tokenId<10501)
        {URI = string(abi.encodePacked(prefixBoosterURI,_toString(tokenId),".json"));}
        return URI;
    }
    /*
    * Function to get RemainingSupply of all collection
    */
    function getRemainingSupply(uint256 _collection) public view returns(uint256)
    {return collection[_collection].availableTokens;}

}