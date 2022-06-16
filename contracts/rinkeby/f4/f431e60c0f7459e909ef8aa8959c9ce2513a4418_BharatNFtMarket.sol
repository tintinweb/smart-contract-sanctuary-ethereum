/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

// import "https://github.com/NomicFoundation/hardhat/blob/master/packages/hardhat-core/console.sol";
// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
 
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;  // Token name    
    string private _symbol; // Token symbol
    mapping (uint256 => address) private _owners;  // Mapping from token ID to owner address
    mapping (address => uint256) private _balances; // Mapping owner address to token count
    mapping (uint256 => address) public _tokenApprovals; // Mapping from token ID to approved address
    mapping (address => mapping (address => bool)) private _operatorApprovals;  // Mapping from owner to operator approvals

    constructor (string memory name_, string memory symbol_) { _name = name_;_symbol = symbol_; }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
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

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
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

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
}


interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Full is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Full.totalSupply(), "ERC721Enumerable: global index out of bounds");
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

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        
        delete _ownedTokensIndex[tokenId]; // This also deletes the contents at the last position of the array
        delete _ownedTokens[from][lastTokenIndex]; // This also deletes the contents at the last position of the array
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    using Strings for uint256;
    mapping (uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

contract ImageContract is IERC721Metadata, ERC721Full{
    address admin;  
    uint TokenID = 0;
    // address  contract_owner = 0xAA737Df2b2C4175205Af4644cb4e44d7b9CeE5D4;
    address public contract_owner = msg.sender;
    uint service;
    uint total_p;

    struct metadata {
        string Artwork_name;
        string Artwork_type;
        address Author;//changed
        string Artwork_description;
        string Artwork_url_image;
        uint Artwork_price;
        uint Auction_Length;
        uint Royalty;
    }

    struct Vendor{
        uint nftCount; 
        uint withdrawnBalance;
        uint userWeiBalance;

    }
    mapping (address => Vendor) Vendors;   
    enum TokenState {Sold, Available}

    struct NFT {
        uint256 price;
        uint256 _tokenId;
        string  tokenURL;
        TokenState tokenState;
        uint bidcount;
        bool doesExist;
    }
    
    string[] public images;
    mapping(uint => metadata) imageData;
    mapping(string => bool) _imageExists;

    mapping(uint => bool) _listedForAuction;
    mapping(uint => bool) _listedForSale;
    mapping(uint => address) public _tokenToOwner;
    mapping (uint => NFT) public NFTs;

    struct auctionData {
        uint Artwork_price;
        uint time;
    }

    mapping(uint => auctionData) public tokenAuction;
    event BoughtNFT(uint256 _tokenId, address _buyer, uint256 _price);
    NFT[] allNFT;
     
    constructor() ERC721("Bharat NFT MarketPlace", "BharatNFT MarketPlace") { admin = payable( msg.sender);}

    function MintFixedNFT(string memory _Artwork_name, string memory _Artwork_type, string memory _Artwork_description, string memory _Artwork_url_image, uint _Artwork_price,uint _Royalty) public payable returns (uint){
        // require(!_imageExists[_Artwork_url_image]);
        metadata memory md;
        md.Artwork_name = _Artwork_name;
        md.Artwork_type = _Artwork_type;

        md.Artwork_description = _Artwork_description;
        md.Artwork_url_image = _Artwork_url_image;
        md.Artwork_price = _Artwork_price;
        //md.Auction_Length = _Auction_Length;
        md.Royalty= _Royalty;
        images.push(_Artwork_url_image);
        TokenID =  TokenID  +1;
        md.Author = msg.sender;

        imageData[ TokenID ] = md;
        _mint(msg.sender,TokenID);
        _tokenToOwner[TokenID] = msg.sender;
        // _imageExists[_Artwork_url_image] = true;

        payable(contract_owner).transfer(msg.value); 
        NFTs[TokenID] = NFT(_Artwork_price, TokenID,_Artwork_url_image, TokenState.Available,0,true);

        // console.log("fixed",TokenID);
        return  TokenID;
    }

    function mintAuctionLength(string memory _Artwork_name, string memory _Artwork_type, string memory _Artwork_description, string memory _Artwork_url_image, uint _Artwork_price, uint _Auction_Length,uint _Royalty) public payable returns (string memory,uint,uint){
        // require(!_imageExists[_Artwork_url_image]);
        metadata memory md;
        md.Artwork_name = _Artwork_name;
        md.Artwork_type = _Artwork_type;
        md.Artwork_description = _Artwork_description;
        md.Artwork_url_image = _Artwork_url_image;
        md.Artwork_price = _Artwork_price;
        md.Auction_Length = _Auction_Length;
        md.Royalty= _Royalty;
        images.push(_Artwork_url_image);
        TokenID  =  TokenID +1;
        md.Author = msg.sender;

        imageData[ TokenID ] = md;
        _mint(msg.sender,TokenID);
        _tokenToOwner[TokenID] = msg.sender;
        // _imageExists[_Artwork_url_image] = true;
        uint VendorNumberofNFT =  Vendors[msg.sender].nftCount++; 
        NFT memory allNFTs = NFT(_Artwork_price,TokenID,_Artwork_url_image, TokenState.Available, 0,true);
        NFTs[TokenID] = NFT(_Artwork_price, TokenID,_Artwork_url_image, TokenState.Available,0,true);
        allNFT.push(allNFTs);
        payable(contract_owner).transfer(msg.value); 

        return ("Auction NFT MINT sucessfully",TokenID, VendorNumberofNFT);
    }

    function nftSold(uint _tokenId) public {
        _listedForSale[_tokenId] = false;
        _listedForAuction[_tokenId] = false;
    }
  
    function approvethis(address add,uint256 _tokenId) public {
      _tokenApprovals[_tokenId] = add;
    }

    function BuyNFT(address _owner, uint256 _tokenId, uint256 _price) public payable returns(string memory,uint256) {
        _price = imageData[_tokenId].Artwork_price;
        uint256 royalty;
        if(_owner==imageData[_tokenId].Author){
            royalty = 0;
        }
        else{
            royalty = _price*imageData[_tokenId].Royalty/100;
                         
        }
        service = msg.value -(_price+royalty);
        total_p = msg.value - service;
        require(total_p==_price+royalty, "You need to send the correct amount.");
        approvethis(msg.sender,_tokenId);
        transferFrom(_owner, msg.sender, _tokenId);
        nftSold(_tokenId);
        emit BoughtNFT(_tokenId, msg.sender, _price);

        payable(_owner).transfer(_price); 

        if(royalty>0){
            payable(imageData[_tokenId].Author).transfer(royalty); 
        }

        _tokenToOwner[_tokenId] = msg.sender;
        payable(contract_owner).transfer(service); 
        return("You have sucessfully Buy this NFT",_tokenId);
    }
}

contract BharatNFtMarket  is ImageContract {
    mapping (address => mapping(uint => bool)) public hasBibedFor;
    mapping  (address => uint) public bidPrice;
    mapping  (uint => mapping (address => bider)) public biderToId;
    mapping  (uint => uint) public BidAmountToTokenId;

    uint public bidcount = 0;
    uint public BidAmount = 0;
    uint public HighestBiderPrice = 0;
    address public HighestBiderAddress ;
    uint public TotalBid = 0;

    struct bider {
        address biderAdress;
        uint bidPrice;
        bool canPay;
    }
 
    function bid (uint _tokenId, uint _bidAmount) public payable returns (string memory, uint, uint) {
       require(msg.sender != admin,"Token Owner cannot bid");
       require(NFTs[_tokenId].doesExist == true, "Token id does not exist"); 
    //    require (hasBibedFor[msg.sender][_tokenId] == false, "You cannot bid for an Nft twice");
       require (BidAmountToTokenId[_tokenId] < _bidAmount, "This Nft already has an higher or equal bider");
       require (NFTs[_tokenId].price <= _bidAmount, "You cannot bid below the startingPrice");
       
        TotalBid = NFTs[_tokenId].bidcount++;
        bidPrice[msg.sender] = _bidAmount;
        uint bidAmount = bidPrice[msg.sender];
        hasBibedFor[msg.sender][_tokenId]= true;

        biderToId[_tokenId][msg.sender]= bider(msg.sender,_bidAmount, true);
        if (BidAmountToTokenId[_tokenId] < _bidAmount ){
            BidAmountToTokenId[_tokenId] = _bidAmount;
        }
        HighestBiderPrice = BidAmountToTokenId[_tokenId];

        if ( biderToId[_tokenId][msg.sender].bidPrice == HighestBiderPrice){
            HighestBiderAddress = biderToId[_tokenId][msg.sender].biderAdress;
        }  
        payable(contract_owner).transfer(msg.value); 
        return("You have sucessfully bided for this NFT", bidAmount, TotalBid);
    }
   
    function BuyBidNFT (uint _tokenId) public payable returns(string memory)  {
        require(NFTs[_tokenId].doesExist == true, "Token id does not exist");
        uint256 bidAmount = bidPrice[msg.sender];

        uint256 royalty;
        if(ownerOf(_tokenId)==imageData[_tokenId].Author){
            royalty = 0;
        }else{
            royalty = bidAmount*imageData[_tokenId].Royalty/100;
        }

        address nftOwner = ownerOf(_tokenId);
        address buyer = msg.sender; 
        approvethis(msg.sender,_tokenId);

        transferFrom(nftOwner, buyer, _tokenId);
        nftSold(_tokenId);

        emit BoughtNFT(_tokenId, buyer, bidAmount);
        require(msg.value==bidAmount+royalty, "You need to send the correct amount.");
        payable(nftOwner).transfer(bidAmount); 

        if(royalty>0) {
            payable(imageData[_tokenId].Author).transfer(royalty);
        }

        _tokenToOwner[_tokenId] = msg.sender;
        bidPrice[msg.sender] = 0;
        HighestBiderPrice = 0;
        BidAmountToTokenId[_tokenId] = 0;
        return("Bid NFT Buy sucessfully");
    }

    function resellNFT(uint256 _token, uint256 _newPrice, string memory _newName,string memory _Artwork_type)public payable returns(string memory,uint) {//changed
        address _owner = _tokenToOwner[_token];
        require(msg.sender==_owner, "You are not the owner so you cannot resell this.");
        // NFTs[_token]=NFT(_newPrice, nft._tokenId,nft.tokenURL, nft.tokenState, nft.bidcount,  nft.doesExist );
        _listedForSale[_token] = true;
        NFTs[_token].price = _newPrice;
        imageData[_token].Artwork_price=_newPrice;
        imageData[_token].Artwork_name = _newName;
        imageData[_token].Artwork_type = _Artwork_type;
        payable(contract_owner).transfer(msg.value); //for Service Fees Trasnsfer to Contract Owner 
        return("Resell Fixed Price NFT  sucessfully",_token);
    }

    function resellAuctionNFT(uint256 _token, string memory _newName,string memory _Artwork_type,  uint256 _newPrice, uint _Auction_Length)public payable returns(string memory,uint) {//changed
        address _owner = _tokenToOwner[_token];
        require(msg.sender==_owner, "You are not the owner so you cannot resell this.");
        // NFTs[_token]=NFT(_newPrice, nft._tokenId,nft.tokenURL, nft.tokenState, nft.bidcount,  nft.doesExist );
        _listedForSale[_token] = true;
        NFTs[_token].price = _newPrice;
        imageData[_token].Artwork_price=_newPrice;
        imageData[_token].Artwork_name = _newName;
        imageData[_token].Artwork_type = _Artwork_type;
        imageData[_token].Auction_Length = _Auction_Length;
        payable(contract_owner).transfer(msg.value); 
        return("Resell Auction Length Price NFT  sucessfully",_token);
    }
}