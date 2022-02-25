/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require( address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require( success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall( address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value ) internal returns (bytes memory) {
        return functionCallWithValue( target, data, value, "Address: low-level call with value failed" );
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require( address(this).balance >= value, "Address: insufficient balance for call" );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall( target, data, "Address: low-level static call failed");
    }
    function functionStaticCall( address target, bytes memory data, string memory errorMessage ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall( target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult( bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer( address indexed from, address indexed to, uint256 indexed tokenId );
    event Approval( address indexed owner, address indexed approved, uint256 indexed tokenId );
    event ApprovalForAll( address indexed owner, address indexed operator, bool approved );
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Receiver {
    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
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
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
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
        require( owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require( owner != address(0), "ERC721: owner query for nonexistent token" );
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId),"ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom( address from, address to, uint256 tokenId) internal virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) internal virtual {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint( address to, uint256 tokenId,bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    function _transfer( address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received( address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
    function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal virtual {}
}
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require( _exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require( newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface NFT{
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address owner);

}
interface WETH{
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
}
contract ImagibleNFTMarketplace is ERC721, ERC721URIStorage, Ownable {
    address wethAddress;
    constructor(string memory tokenName, string memory tokenSymbol, address _weth) ERC721(tokenName, tokenSymbol){
        wethAddress = _weth;
    }
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    mapping(uint256 => mapping(address=>uint256)) public bidsOffers;
    mapping(address => mapping(uint256 => bool)) seenNonces;
    mapping(uint256 => tokenInfo) public allTokensInfo;
    mapping(uint256 => uint256) public royaltiesWeth;
    uint256 PLATFORM_SHARE_PERCENT = 0;
    Counters.Counter private _tokenIds;
    struct tokenInfo {
        uint256 tokenId;
        address payable currentOwner;
        uint256 price;
        uint selling;
        address contractAd;
        uint8 created;
    }
    struct createNftData {
        string metaData;
        bytes signature;
        uint256[] nftIds;
        string encodeKey;
        uint256 nonce;
        uint256 amount;
    }
    struct sellingConfigData {
        uint256 _tokenId;
        uint status;
        uint256 newPrice;
        address nft;
        uint256 nftId;
        bytes signature;
        string encodeKey;
        uint256 nonce;
    }
    struct placeBidData {
        uint256 nftId;
        uint256 price;
        bytes signature;
        string encodeKey;
        uint256 nonce;
    }
    struct placeOfferData {
        uint256 nftId;
        uint256 price;
        bytes signature;
        string encodeKey;
        uint256 nonce;
    }
    struct cancelBidOfferData {
        uint256 nftId;
        bytes signature;
        string encodeKey;
        uint256 nonce;
        uint256 price;
    }
    struct transferByOfferData {
        uint256 tokenId;
        uint256 nftId;
        address newOwner;
        address nft;
        bytes signature;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct transferByBidData {
        uint256 tokenId; 
        uint256 nftId;
        address newOwner;
        address nft;
        bytes signature;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
        string encodeKey;
        uint256 nonce;
    }
    struct acceptData {
        uint256 tokenId; 
        uint256 nftId;
        address newOwner;
        address nft;
        uint payThrough;
        uint256 amount;
        uint256 percent;
        uint256 collectionId;
    }
    event NewNFT(uint256 indexed tokenId);
    event NewBid(uint256 indexed tokenId,uint256 indexed price);
    event NewOffer(uint256 indexed tokenId,uint256 indexed price);
    event OfferAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to,uint256 creatorEarning);
    event BidAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to,uint256 creatorEarning);
    event AutoAccepted(uint256 indexed tokenId,uint256 creatorEarning);
    event NewNFTs(uint[] array);
    modifier onlyNftOwner(uint256 nftId) {
        tokenInfo memory tokenInfoById = allTokensInfo[nftId];
        require(tokenInfoById.created > 0,"Invalid token or owner");
        _;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }
    function createNFTs(createNftData memory _nftData) public {
        require(verify(msg.sender, msg.sender, _nftData.amount, _nftData.encodeKey, _nftData.nonce, _nftData.signature), "invalid signature");
        require(_nftData.nftIds.length > 0, "No NFTs provided to create");
        require(!seenNonces[msg.sender][_nftData.nonce], "Invalid sign");
        seenNonces[msg.sender][_nftData.nonce] = true;
        uint[] memory array = new uint[](_nftData.nftIds.length);
        for(uint x = 0; x < _nftData.nftIds.length; x++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, _nftData.metaData);
            array[x] = newTokenId;
            tokenInfo memory newTokenInfo = tokenInfo(
                newTokenId,
                payable(msg.sender),
                0,
                0,
                address(this),
                1
            );
            allTokensInfo[_nftData.nftIds[x]] = newTokenInfo;
        }
        emit NewNFTs(array);
    }
    function changeSellingStatus(sellingConfigData memory _sellingData) public {
        require(!seenNonces[msg.sender][_sellingData.nonce], "Invalid sign");
        seenNonces[msg.sender][_sellingData.nonce] = true;
        require(verify(msg.sender, msg.sender, _sellingData.newPrice, _sellingData.encodeKey, _sellingData.nonce, _sellingData.signature), "invalid signature");
        tokenInfo memory tokenInfoById = allTokensInfo[_sellingData.nftId];
        if(_sellingData.nft == address(this)) {
            require(ownerOf(_sellingData._tokenId) == msg.sender,"Not the owner 1");
            tokenInfoById.selling = _sellingData.status;
            tokenInfoById.price = _sellingData.newPrice;
            allTokensInfo[_sellingData.nftId] = tokenInfoById;
        }
        else {
            if(tokenInfoById.created > 0) {
                tokenInfoById.currentOwner = payable(msg.sender);
                tokenInfoById.price = _sellingData.newPrice;
                tokenInfoById.selling = _sellingData.status;
            } else {
                    tokenInfoById = tokenInfo(
                    _sellingData._tokenId,
                    payable(msg.sender),
                    _sellingData.newPrice,
                    _sellingData.status,
                    _sellingData.nft,
                    1
                );
            }
            allTokensInfo[_sellingData.nftId] = tokenInfoById;
        }
    }
    function cancelSelling(sellingConfigData memory _sellingData) public {
        require(!seenNonces[msg.sender][_sellingData.nonce], "Invalid sign");
        seenNonces[msg.sender][_sellingData.nonce] = true;
        require(verify(msg.sender, msg.sender, _sellingData.newPrice, _sellingData.encodeKey, _sellingData.nonce, _sellingData.signature), "invalid signature");
        tokenInfo memory tokenInfoById = allTokensInfo[_sellingData.nftId];
        tokenInfoById.selling = _sellingData.status;
    }
    function placeBid(placeBidData memory _bidData) external {
        require(!seenNonces[msg.sender][_bidData.nonce], "Invalid sign");
        seenNonces[msg.sender][_bidData.nonce] = true;
        require(verify(msg.sender, msg.sender, _bidData.price, _bidData.encodeKey, _bidData.nonce, _bidData.signature), "invalid signature");
        require(_bidData.price > 0, "Price must be non-zero");
        require(nftExists(_bidData.nftId), "Non-existent nft");
        tokenInfo memory tokenInfoById = allTokensInfo[_bidData.nftId];
        require(tokenInfoById.selling == 2, "Can only place bids on this NFT");
        bidsOffers[_bidData.nftId][msg.sender] = _bidData.price;
        emit NewBid(_bidData.nftId,_bidData.price);
    }
    function placeOffer(placeOfferData memory _offerData) external {
        require(!seenNonces[msg.sender][_offerData.nonce], "Invalid sign");
        seenNonces[msg.sender][_offerData.nonce] = true;
        require(verify(msg.sender, msg.sender, _offerData.price, _offerData.encodeKey, _offerData.nonce, _offerData.signature), "invalid signature");
        require(_offerData.price > 0,"Price must be non-zero");
        require(nftExists(_offerData.nftId), "Non-existent nft");
        tokenInfo memory tokenInfoById = allTokensInfo[_offerData.nftId];
        require(tokenInfoById.selling == 1, "Can only make offers on this NFT");
        bidsOffers[_offerData.nftId][msg.sender] = _offerData.price;
        emit NewBid(_offerData.nftId,_offerData.price);
    }
    function cancelOfferBid( cancelBidOfferData memory _cancelData) external payable {
        require(!seenNonces[msg.sender][_cancelData.nonce], "Invalid sign");
        seenNonces[msg.sender][_cancelData.nonce] = true;
        require(verify(msg.sender, msg.sender, _cancelData.price, _cancelData.encodeKey, _cancelData.nonce, _cancelData.signature), "invalid signature");
        require(nftExists(_cancelData.nftId), "Non-existent nft");
        bidsOffers[_cancelData.nftId][msg.sender] = 0;
        emit NewBid(_cancelData.nftId,0);
    }
    function transferByAcceptOffer(transferByOfferData memory _transferData) external payable onlyNftOwner(_transferData.nftId) {
        require(!seenNonces[msg.sender][_transferData.nonce], "Invalid sign");
        seenNonces[msg.sender][_transferData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferData.amount, _transferData.encodeKey, _transferData.nonce, _transferData.signature), "invalid signature");
        require(bidsOffers[_transferData.nftId][_transferData.newOwner] > 0, "Offer does not exist");
        require(_transferData.amount == bidsOffers[_transferData.nftId][_transferData.newOwner], "Invalid amount");
        tokenInfo memory tokenInfoById = allTokensInfo[_transferData.nftId];
        require(tokenInfoById.selling > 0, "NFT not available for sale");
        tokenInfoById.currentOwner = payable(_transferData.newOwner);
        allTokensInfo[_transferData.nftId] = tokenInfoById;
        uint256 amountToTransfer = _transferData.amount;
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            transferwethToOwner(_transferData.newOwner, address(this), platformSharePercent);
        }
        uint256 royaltyPercent;
        if(_transferData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _transferData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            transferwethToOwner(_transferData.newOwner, address(this), royaltyPercent);
            uint256 amount = royaltiesWeth[_transferData.collectionId];
            royaltiesWeth[_transferData.collectionId] = amount + royaltyPercent;
        }
        
        transferwethToOwner(_transferData.newOwner, msg.sender, amountToTransfer);
        transferNFT(_transferData.nft, msg.sender, _transferData.newOwner, _transferData.tokenId);
        emit OfferAccepted(_transferData.tokenId,msg.value,msg.sender,_transferData.newOwner, royaltyPercent);
    }
    function transferByBid(transferByBidData memory _transferData) external payable onlyNftOwner(_transferData.nftId) {
        require(!seenNonces[msg.sender][_transferData.nonce], "Invalid sign");
        seenNonces[msg.sender][_transferData.nonce] = true;
        require(verify(msg.sender, msg.sender, _transferData.amount, _transferData.encodeKey, _transferData.nonce, _transferData.signature), "invalid signature");
        require(bidsOffers[_transferData.nftId][_transferData.newOwner] > 0, "User did not palce bid");
        require(_transferData.amount == bidsOffers[_transferData.nftId][_transferData.newOwner], "Invalid amount");
        tokenInfo memory tokenInfoById = allTokensInfo[_transferData.nftId];
        require(tokenInfoById.selling > 0, "NFT not available for sale");
        tokenInfoById.currentOwner = payable(_transferData.newOwner);
        allTokensInfo[_transferData.nftId] = tokenInfoById;
        uint256 amountToTransfer = _transferData.amount;
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            
            transferwethToOwner(_transferData.newOwner, address(this), platformSharePercent);
        }
        uint256 royaltyPercent;
        if(_transferData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _transferData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            
            transferwethToOwner(_transferData.newOwner, address(this), royaltyPercent);
            uint256 amount = royaltiesWeth[_transferData.collectionId];
            royaltiesWeth[_transferData.collectionId] = amount + royaltyPercent;
        }
        
        transferwethToOwner(_transferData.newOwner, msg.sender, amountToTransfer);
        if(_transferData.nft == address(this)) {
            _transfer(msg.sender, _transferData.newOwner, _transferData.tokenId);
        }
        else {
            transferNFT(_transferData.nft, msg.sender, _transferData.newOwner, _transferData.tokenId);
        }
        emit BidAccepted(_transferData.tokenId,msg.value,msg.sender,_transferData.newOwner, royaltyPercent);
    }
    function acceptBid(acceptData memory _transferData) external payable onlyOwner {
        tokenInfo memory tokenInfoById = allTokensInfo[_transferData.nftId];
        uint256 amountToTransfer = _transferData.amount;
        if(PLATFORM_SHARE_PERCENT > 0) {
            uint256 platformSharePercent = calculatePercentValue(amountToTransfer, PLATFORM_SHARE_PERCENT);
            amountToTransfer = amountToTransfer-platformSharePercent;
            
            transferwethToOwner(_transferData.newOwner, address(this), platformSharePercent);
        }
        uint256 royaltyPercent;
        if(_transferData.percent > 0) {
            royaltyPercent = calculatePercentValue(amountToTransfer, _transferData.percent);
            amountToTransfer = amountToTransfer-royaltyPercent;
            
            transferwethToOwner(_transferData.newOwner, address(this), royaltyPercent);
            uint256 amount = royaltiesWeth[_transferData.collectionId];
            royaltiesWeth[_transferData.collectionId] = amount + royaltyPercent;
        }
        
        transferwethToOwner(_transferData.newOwner, tokenInfoById.currentOwner, amountToTransfer);
        if(_transferData.nft == address(this)) {
            _transfer(tokenInfoById.currentOwner, _transferData.newOwner, _transferData.tokenId);
        }
        else {
            transferNFT(_transferData.nft, tokenInfoById.currentOwner, _transferData.newOwner, _transferData.tokenId);
        }
        tokenInfoById.currentOwner = payable(_transferData.newOwner);
        allTokensInfo[_transferData.nftId] = tokenInfoById;
        emit AutoAccepted(_transferData.tokenId, royaltyPercent);
    }
    
    fallback () payable external {}
    receive () payable external {}
    
    function updatePlatformSharePercent(uint256 percent) public onlyOwner {
        PLATFORM_SHARE_PERCENT = percent;
    }
    function checkPlatformSharePercent() public view returns (uint256) {
        return PLATFORM_SHARE_PERCENT;
    }
    function calculatePercentValue(uint256 total, uint256 percent) pure private returns(uint256) {
        uint256 division = total.mul(percent);
        uint256 percentValue = division.div(100);
        return percentValue;
    }
    function nftExists(uint256 nftId) public view returns (bool) {
        tokenInfo memory tokenInfoById = allTokensInfo[nftId];
        if(tokenInfoById.created > 0 ) {
            return true;
        }
        return false;
    }
    function transferwethToOwner(address from, address to, uint256 amount) private {
        WETH weth = WETH(wethAddress);
        uint256 balance = weth.balanceOf(from);
        require(balance >= amount, "insufficient balance" );
        weth.transferFrom(from, to, amount);
    }
    function checkNFTOwner(address cAddress, uint256 token) public returns (address) {
        NFT nftToken = NFT(cAddress);
        return nftToken.ownerOf(token);
    }
    function transferNFT(address cAddress, address from, address to, uint256 token) public {
        NFT nftToken = NFT(cAddress);
        nftToken.safeTransferFrom(from, to, token);
    }
    
    function transferRoyalties(uint256 collection, address payout) public onlyOwner {
        uint256 wethShare = royaltiesWeth[collection];
        if(wethShare > 0) {
            transferwethToOwner(address(this), payout, wethShare);
            royaltiesWeth[collection] = 0;
        }
    }
    function verify( address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
    function getMessageHash( address _to, uint256 _amount, string memory _message, uint256 _nonce) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }
    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }
    function splitSignature(bytes memory sig) internal pure returns ( bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
}