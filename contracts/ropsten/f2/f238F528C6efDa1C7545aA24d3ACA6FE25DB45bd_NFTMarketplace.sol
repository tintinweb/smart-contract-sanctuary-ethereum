/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

pragma solidity ^0.8.0;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity ^0.8.0;
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.1;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "ERR:1");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ERR:2");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed"); 
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "ERR:5");
        require(isContract(target), "ERR:6");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "ERR:8");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "ERR:10");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

pragma solidity ^0.8.0;

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
        require(value == 0, "ERR:11");
        return string(buffer);
    }
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;

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
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERR:12");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERR:13");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERR:14");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERR:15");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERR:16"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERR:17");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom( address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERR:18");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERR:19");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERR:20");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERR:21");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERR:22"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERR:23");
        require(!_exists(tokenId), "ERR:24");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERR:25");
        require(to != address(0), "ERR:26");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERR:27");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERR:28");
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

pragma solidity ^0.8.0;

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
        require(value > 0, "ERR:29");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }

}

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ERR:30");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

abstract contract ERC721URIStorage is ERC721 {

    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERR:31");
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
        require(_exists(tokenId), "ERR:32");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


// File contracts/NFTMarketplace.sol
pragma solidity ^0.8.4;
contract NFTMarketplace is ReentrancyGuard, ERC721URIStorage{
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter public _bidIds;
    address _scAddress;
    string public _tokenName;
    string public _tokenSymbol;
    uint256 private _maxTokenSupply;
    address payable owner;
    mapping (uint256 => string) _tokenIDURI;

    struct MarketItem {
        uint256 tokenId;
        address nftContract;
        string uri;
        address payable nftCreator;
        address payable nftOwner;
        uint256 price;
        bool forSale;
    }

    mapping(uint256 => MarketItem) private MarketItemDatabase;

    event MarketItemCreated(
        uint256 indexed tokenId,
        address indexed nftContract,
        string uri,
        address creator,
        address owner,
        uint256 price,
        bool forSale
    );

    constructor(string memory tokenName, string memory tokenSymbol, uint256 gotMaxTokenSupply) ERC721(tokenName, tokenSymbol){

        owner = payable(msg.sender);
        require(gotMaxTokenSupply > 0, "ERR:33");
        _maxTokenSupply = gotMaxTokenSupply;
        _tokenName = tokenName;
        _tokenSymbol = tokenSymbol;

    }

    function getMaxTokenSupply() public view returns (uint256){
        return (_maxTokenSupply);
    }

    function marketSetup(address scAddress) public{
        _scAddress = scAddress;
    }

    function getNewTokenID() public view returns (uint256){
        return _tokenIds.current();
    }

    function addTokens(uint256 gotNewMaxTokenSupply) public {
        require(msg.sender == owner, "ERR:34");
        require(gotNewMaxTokenSupply > _maxTokenSupply, "ERR:35");
        _maxTokenSupply = gotNewMaxTokenSupply;
    }

    function fetchTokenIDURI(uint256 tokenID) public view returns (string memory){
        bytes memory tempTokenURI = bytes(_tokenIDURI[tokenID]);
        if(tempTokenURI.length != 0){
            return _tokenIDURI[tokenID];
        } else
            return "fetchTokenIDURI: Token ID does not exist";
    }

    function mintNFT(string memory uri) public payable nonReentrant{
        require(_tokenIds.current() != _maxTokenSupply, "ERR:37");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);
        _tokenIDURI[newTokenId] = uri;

        MarketItemDatabase[newTokenId] = MarketItem(
            newTokenId, 
            _scAddress, 
            uri,
            payable(msg.sender), 
            payable(address(0)), 
            0,
            false
        );
        
        emit MarketItemCreated(
            newTokenId, 
            _scAddress, 
            uri,
            msg.sender, 
            address(0), 
            0,
            false
        );
    }

    function listNFT(uint256 tokenId, uint256 price) public {
        require((msg.sender == MarketItemDatabase[tokenId].nftCreator && MarketItemDatabase[tokenId].nftOwner == address(0)) || msg.sender == MarketItemDatabase[tokenId].nftOwner, "You are not the owner of this Item");
        setApprovalForAll(_scAddress, true);
        MarketItemDatabase[tokenId].forSale = true;
        MarketItemDatabase[tokenId].price = price;
        IERC721(_scAddress).transferFrom(msg.sender, address(this), tokenId);
    }

    function unlistNFT(uint256 tokenId) public {
        require((msg.sender == MarketItemDatabase[tokenId].nftCreator && MarketItemDatabase[tokenId].nftOwner == address(0)) || msg.sender == MarketItemDatabase[tokenId].nftOwner, "You are not the owner of this Item");
        require(MarketItemDatabase[tokenId].forSale == true, "ERR:38");
        setApprovalForAll(_scAddress, true);
        MarketItemDatabase[tokenId].forSale = false;
        MarketItemDatabase[tokenId].price = 0;
        IERC721(_scAddress).transferFrom(address(this), msg.sender, tokenId);
    }

    function sellNFT(uint256 tokenId, uint256 marketItemPrice, uint256 sellerGets, uint256 marketOwnerGets) public payable nonReentrant{
        require(msg.sender != owner, "ERR:39");
        require(MarketItemDatabase[tokenId].forSale == true, "ERR:40");
        require(msg.value == marketItemPrice, "ERR:41");

        if(MarketItemDatabase[tokenId].nftOwner == address(0)){
            MarketItemDatabase[tokenId].nftCreator.transfer(sellerGets);
        } else if((MarketItemDatabase[tokenId].nftOwner != address(0)))
        {
            MarketItemDatabase[tokenId].nftOwner.transfer(sellerGets);
        }
        
        IERC721(_scAddress).transferFrom(address(this), msg.sender, tokenId);
        MarketItemDatabase[tokenId].nftOwner = payable(msg.sender);
        MarketItemDatabase[tokenId].forSale = false;
        MarketItemDatabase[tokenId].price = 0;
        payable(owner).transfer(marketOwnerGets);
    }

    function transferNFT(address recieverAddress, uint256 tokenId, uint256 gotTransferFee) public payable nonReentrant{
        require((msg.sender == MarketItemDatabase[tokenId].nftCreator && MarketItemDatabase[tokenId].nftOwner == address(0)) || msg.sender == MarketItemDatabase[tokenId].nftOwner, "You are not the owner of this Item");
        require(MarketItemDatabase[tokenId].forSale == false, "ERR:42");
        require(msg.value == gotTransferFee, "ERR:43");
        setApprovalForAll(_scAddress, true);
        MarketItemDatabase[tokenId].nftOwner = payable(recieverAddress);
        payable(owner).transfer(gotTransferFee);
        IERC721(_scAddress).transferFrom(msg.sender, recieverAddress, tokenId);
    }

    function fetchWalletAddressURIs(address walletAddress) public view returns (string[] memory){
        uint256 totalItemCount = _tokenIds.current();
        uint256 uriCount = 0;
        uint256 currentIndex = 0;
        for(uint256 i=0; i<totalItemCount; i++){
            if(MarketItemDatabase[i+1].nftCreator == walletAddress && MarketItemDatabase[i+1].nftOwner == address(0) || MarketItemDatabase[i+1].nftOwner == walletAddress){
                uriCount +=1;
            }
        }

        string[] memory uris = new string[](uriCount);
        for(uint256 i=0; i<totalItemCount; i++){

            if(MarketItemDatabase[i+1].nftCreator == walletAddress && MarketItemDatabase[i+1].nftOwner == address(0) || MarketItemDatabase[i+1].nftOwner == walletAddress){
                string memory currentURI = MarketItemDatabase[i+1].uri;
                uris[currentIndex] = currentURI;
                currentIndex +=1;
            }

        }

        return uris;
    }

    uint256 totalUserMPWalletFunds;
    mapping(address => uint256) private mpWallets;

    function bidWalletIN(address gotAddress) public payable nonReentrant{
        require(gotAddress != owner, "ERR:49");
        mpWallets[gotAddress] = mpWallets[gotAddress] + msg.value;
        payable(owner).transfer(msg.value);
        totalUserMPWalletFunds = totalUserMPWalletFunds + msg.value;
    }

    function bidWalletOUT(address userWallet, uint256 withdrawAmount) public payable nonReentrant{
        require(userWallet != owner, "ERR:50");
        require(mpWallets[userWallet] <= withdrawAmount, "ERR:44");
        mpWallets[userWallet] = mpWallets[userWallet] - msg.value;
        totalUserMPWalletFunds = totalUserMPWalletFunds - withdrawAmount;
        payable(userWallet).transfer(withdrawAmount);
    }

    function bidPassCheck(address userWallet, uint256 currBid, uint256 tokenID) public view returns(bool){
        require(mpWallets[userWallet] > 0, "ERR:45");
        require((userWallet == MarketItemDatabase[tokenID].nftCreator && MarketItemDatabase[tokenID].nftOwner != address(0)) || userWallet != MarketItemDatabase[tokenID].nftOwner, "ERR:48");
        if(mpWallets[userWallet] >= currBid){
            return true;
        } else{
            return false;
        }
    }

    function soldBidNFT(address winner, uint256 bidAmount, uint256 nftOwnerGets, uint256 ownerGets, uint256 tokenId) public payable nonReentrant{
        require(MarketItemDatabase[tokenId].forSale == true, "ERR:46");
        require(msg.value == bidAmount, "ERR:47");
        setApprovalForAll(_scAddress, true);
        payable(MarketItemDatabase[tokenId].nftOwner).transfer(nftOwnerGets);
        payable(owner).transfer(ownerGets);
        IERC721(_scAddress).transferFrom(MarketItemDatabase[tokenId].nftOwner, winner, tokenId);
        MarketItemDatabase[tokenId].nftOwner = payable(winner);
        MarketItemDatabase[tokenId].forSale == false;
        MarketItemDatabase[tokenId].price = 0;
        totalUserMPWalletFunds-=msg.value;
        mpWallets[winner] = mpWallets[winner] - msg.value;
    }

    function actualOwnerWallet(uint256 altOwnerFund) public view returns (uint256){
        return altOwnerFund-totalUserMPWalletFunds;
    }
    
}