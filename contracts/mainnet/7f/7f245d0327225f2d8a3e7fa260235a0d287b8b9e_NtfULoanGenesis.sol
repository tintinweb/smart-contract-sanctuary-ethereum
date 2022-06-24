/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

struct TDates
{
 uint raffleStartDate;
 uint raffleEndDate;
 uint presalesDate;
 uint salesDate;
}

struct TQuantities
{
 uint mint;
 uint vip;
 uint whitelist;
 uint claim;
}

//==============================================================================
interface IERC165
{
 function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
//==============================================================================
interface IERC721 is IERC165
{
 event Transfer( address indexed from, address indexed to, uint indexed tokenId);
 event Approval( address indexed owner, address indexed approved, uint indexed tokenId);
 event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

 function balanceOf( address owner) external view returns (uint balance);
 function ownerOf( uint tokenId) external view returns (address owner);
 function safeTransferFrom( address from, address to, uint tokenId) external;
 function transferFrom( address from, address to, uint tokenId) external;
 function approve( address to, uint tokenId) external;
 function getApproved( uint tokenId) external view returns (address operator);
 function setApprovalForAll(address operator, bool _approved) external;
 function isApprovedForAll( address owner, address operator) external view returns (bool);
 function safeTransferFrom( address from, address to, uint tokenId, bytes calldata data) external;
}
//==============================================================================
interface IERC721Metadata is IERC721
{
 function name() external view returns (string memory);
 function symbol() external view returns (string memory);
 function tokenURI(uint tokenId) external view returns (string memory);
}
//==============================================================================
interface IERC721Enumerable is IERC721
{
 function totalSupply() external view returns (uint);
 function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);
 function tokenByIndex(uint index) external view returns (uint);
}
//==============================================================================
interface IERC721Receiver
{
 function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) external returns (bytes4);
}
//================================================================================
library Strings
{
 bytes16 private constant alphabet = "0123456789abcdef";

 function toString(uint value) internal pure returns (string memory)
 {
 if (value==0) return "0";
 
 uint temp = value;
 uint digits;
 
 while (temp!=0)
 {
 digits++;
 temp /= 10;
 }
 
 bytes memory buffer = new bytes(digits);
 
 while (value!=0)
 {
 digits -= 1;
 buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
 value /= 10;
 }
 
 return string(buffer);
 }
}
//================================================================================
library Address
{
 function isContract(address account) internal view returns (bool)
 {
 uint size;
 
 assembly { size := extcodesize(account) } // solhint-disable-next-line no-inline-assembly
 return size > 0;
 }
}
//==============================================================================
abstract contract ERC165 is IERC165
{
 function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool)
 {
 return (interfaceId == type(IERC165).interfaceId);
 }
}
//==============================================================================
abstract contract Context
{
 function _msgSender() internal view virtual returns (address)
 {
 return msg.sender;
 }
 //----------------------------------------------------------------
 function _msgData() internal view virtual returns (bytes calldata)
 {
 this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
 return msg.data;
 }
}
//--------------------------------------------------------------------------------
abstract contract Ownable is Context
{
 address private _owner;
 address private _admin;

 event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 event AdminChanged(address previousAdmin, address newAdmin);

 constructor ()
 {
 address msgSender = _msgSender();
 _owner = msgSender;
 _admin = 0x738C30758b22bCe4EE64d4dd2dc9f0dcCd097229;
 
 emit OwnershipTransferred(address(0), msgSender);
 }
 
 function admin() public view virtual returns (address)
 {
 return _admin;
 }
 
 function owner() public view virtual returns (address)
 {
 return _owner;
 }
 
 function setAdmin(address newAdmin) public onlyOwner
 {
 address previousAdmin = _admin;
 _admin = newAdmin;

 emit AdminChanged(previousAdmin, newAdmin);
 }

 modifier onlyOwner()
 {
 require(owner() == _msgSender(), "Not owner");
 _;
 }
 
 modifier onlyAdminOrOwner()
 {
 require(_msgSender()==owner() || _msgSender()==admin(), "Owner or Admin only");
 _;
 }

 function transferOwnership(address newOwner) public virtual onlyOwner
 {
 require(newOwner != address(0), "Bad addr");
 
 emit OwnershipTransferred(_owner, newOwner);
 
 _owner = newOwner;
 }
}
//==============================================================================
abstract contract ReentrancyGuard 
{
 uint private constant _NOT_ENTERED = 1;
 uint private constant _ENTERED = 2;

 uint private _status;

 constructor() 
 { 
 _status = _NOT_ENTERED;
 }

 modifier nonReentrant() // Prevents a contract from calling itself, directly or indirectly.
 {
 require(_status != _ENTERED, "ReentrancyGuard: reentrant call"); // On the first call to nonReentrant, _notEntered will be true
 _status = _ENTERED; // Any calls to nonReentrant after this point will fail
 _;
 _status = _NOT_ENTERED; // By storing the original value once again, a refund is triggered (see // https://eips.ethereum.org/EIPS/eip-2200)
 }
}
//==============================================================================
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable, ReentrancyGuard
{
 using Address for address;
 using Strings for uint;

 string private _name; // Token name
 string private _symbol; // Token symbol

 mapping(uint => address) internal _owners; // Mapping from token ID to owner address
 mapping(address => uint) internal _balances; // Mapping owner address to token count
 mapping(uint => address) private _tokenApprovals; // Mapping from token ID to approved address
 mapping(address => mapping(address => bool)) private _operatorApprovals; // Mapping from owner to operator approvals
 
 constructor(string memory name_, string memory symbol_)
 {
 _name = name_;
 _symbol = symbol_;
 }
 function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool)
 {
 return interfaceId == type(IERC721).interfaceId ||
 interfaceId == type(IERC721Metadata).interfaceId ||
 super.supportsInterface(interfaceId);
 }
 function balanceOf(address owner) public view virtual override returns (uint)
 {
 require(owner != address(0), "ERC721: balance query for the zero address");
 
 return _balances[owner];
 }
 function ownerOf(uint tokenId) public view virtual override returns (address)
 {
 address owner = _owners[tokenId];
 require(owner != address(0), "ERC721: owner query for nonexistent token");
 return owner;
 }
 function name() public view virtual override returns (string memory)
 {
 return _name;
 }
 function symbol() public view virtual override returns (string memory)
 {
 return _symbol;
 }
 function tokenURI(uint tokenId) public view virtual override returns (string memory)
 {
 require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

 string memory baseURI = _baseURI();
 
 return (bytes(baseURI).length>0) ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
 }
 function _baseURI() internal view virtual returns (string memory)
 {
 return "";
 }
 function approve(address to, uint tokenId) public virtual override
 {
 address owner = ERC721.ownerOf(tokenId);
 
 require(to!=owner, "ERC721: approval to current owner");
 require(_msgSender()==owner || ERC721.isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

 _approve(to, tokenId);
 }
 function getApproved(uint tokenId) public view virtual override returns (address)
 {
 require(_exists(tokenId), "ERC721: approved query for nonexistent token");

 return _tokenApprovals[tokenId];
 }
 function setApprovalForAll(address operator, bool approved) public virtual override
 {
 require(operator != _msgSender(), "ERC721: approve to caller");

 _operatorApprovals[_msgSender()][operator] = approved;
 
 emit ApprovalForAll(_msgSender(), operator, approved);
 }
 function isApprovedForAll(address owner, address operator) public view virtual override returns (bool)
 {
 return _operatorApprovals[owner][operator];
 }
 function transferFrom(address from, address to, uint tokenId) public virtual override
 {
 //----- solhint-disable-next-line max-line-length
 
 require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

 _transfer(from, to, tokenId);
 }
 function safeTransferFrom(address from, address to, uint tokenId) public virtual override
 {
 safeTransferFrom(from, to, tokenId, "");
 }
 function safeTransferFrom(address from, address to, uint tokenId, bytes memory _data) public virtual override
 {
 require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
 
 _safeTransfer(from, to, tokenId, _data);
 }
 function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal virtual
 {
 _transfer(from, to, tokenId);
 
 require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
 }
 function _exists(uint tokenId) internal view virtual returns (bool)
 {
 return _owners[tokenId] != address(0);
 }
 function _isApprovedOrOwner(address spender, uint tokenId) internal view virtual returns (bool)
 {
 require(_exists(tokenId), "ERC721: operator query for nonexistent token");
 
 address owner = ERC721.ownerOf(tokenId);
 
 return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
 }
 function _safeMint(address to, uint tokenId) internal virtual
 {
 _safeMint(to, tokenId, "");
 }
 function _safeMint(address to, uint tokenId, bytes memory _data) internal virtual
 {
 _mint(to, tokenId);
 
 require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
 }
 function _mint(address to, uint tokenId) internal virtual
 {
 require(to != address(0), "ERC721: mint to the zero address");
 require(!_exists(tokenId), "ERC721: token already minted");

 _beforeTokenTransfer(address(0), to, tokenId);

 _balances[to] += 1;
 _owners[tokenId] = to;

 emit Transfer(address(0), to, tokenId);
 }
 function _batchMint(address to, uint[] memory tokenIds) internal virtual
 {
 require(to != address(0), "ERC721: mint to the zero address");
 
 _balances[to] += tokenIds.length;

 for (uint i=0; i < tokenIds.length; i++)
 {
 require(!_exists(tokenIds[i]), "ERC721: token already minted");

 _beforeTokenTransfer(address(0), to, tokenIds[i]);

 _owners[tokenIds[i]] = to;

 emit Transfer(address(0), to, tokenIds[i]);
 }
 }
 function _burn(uint tokenId) internal virtual
 {
 address owner = ERC721.ownerOf(tokenId);

 _beforeTokenTransfer(owner, address(0), tokenId);

 _approve(address(0), tokenId); // Clear approvals

 _balances[owner] -= 1;

 delete _owners[tokenId];

 emit Transfer(owner, address(0), tokenId);
 }
 function _transfer(address from, address to, uint tokenId) internal virtual
 {
 require(ERC721.ownerOf(tokenId)==from, "ERC721: transfer of token that is not own");
 require(to != address(0), "ERC721: transfer to the zero address");

 _beforeTokenTransfer(from, to, tokenId);

 _approve(address(0), tokenId); // Clear approvals from the previous owner

 _balances[from] -= 1;
 _balances[to] += 1;
 _owners[tokenId] = to;

 emit Transfer(from, to, tokenId);
 }
 function _approve(address to, uint tokenId) internal virtual
 {
 _tokenApprovals[tokenId] = to;
 
 emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
 }
 function _checkOnERC721Received(address from,address to,uint tokenId,bytes memory _data) private returns (bool)
 {
 if (to.isContract())
 {
 try
 
 IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
 
 returns (bytes4 retval)
 {
 return retval == IERC721Receiver(to).onERC721Received.selector;
 }
 catch (bytes memory reason)
 {
 if (reason.length==0)
 {
 revert("ERC721: transfer to non ERC721Receiver implementer");
 }
 else
 {
 assembly { revert(add(32, reason), mload(reason)) } //// solhint-disable-next-line no-inline-assembly
 }
 }
 }
 else
 {
 return true;
 }
 }
 function _beforeTokenTransfer(address from, address to, uint tokenId) internal virtual
 {
 //
 }
}
//==============================================================================
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable
{
 mapping(address => mapping(uint => uint)) private _ownedTokens; // Mapping from owner to list of owned token IDs
 mapping(uint => uint) private _ownedTokensIndex; // Mapping from token ID to index of the owner tokens list
 mapping(uint => uint) private _allTokensIndex; // Mapping from token id to position in the allTokens array

 uint[] private _allTokens; // Array with all token ids, used for enumeration

 function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool)
 {
 return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
 }
 function totalSupply() public view virtual override returns (uint)
 {
 return _allTokens.length;
 }
 function tokenOfOwnerByIndex(address owner, uint index) public view virtual override returns (uint)
 {
 require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
 
 return _ownedTokens[owner][index];
 }
 function tokenByIndex(uint index) public view virtual override returns (uint)
 {
 require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
 
 return _allTokens[index];
 }
 function _beforeTokenTransfer(address from,address to,uint tokenId) internal virtual override
 {
 super._beforeTokenTransfer(from, to, tokenId);

 if (from == address(0)) _addTokenToAllTokensEnumeration(tokenId);
 else if (from != to) _removeTokenFromOwnerEnumeration(from, tokenId);
 
 if (to == address(0)) _removeTokenFromAllTokensEnumeration(tokenId);
 else if (to != from) _addTokenToOwnerEnumeration(to, tokenId);
 }
 function _addTokenToOwnerEnumeration(address to, uint tokenId) private
 {
 uint length = ERC721.balanceOf(to);
 
 _ownedTokens[to][length] = tokenId;
 _ownedTokensIndex[tokenId] = length;
 }
 function _addTokenToAllTokensEnumeration(uint tokenId) private
 {
 _allTokensIndex[tokenId] = _allTokens.length;
 
 _allTokens.push(tokenId);
 }
 function _removeTokenFromOwnerEnumeration(address from, uint tokenId) private
 {
 // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
 // then delete the last slot (swap and pop).

 uint lastTokenIndex = ERC721.balanceOf(from) - 1;
 uint tokenIndex = _ownedTokensIndex[tokenId];

 // When the token to delete is the last token, the swap operation is unnecessary
 if (tokenIndex != lastTokenIndex) {
 uint lastTokenId = _ownedTokens[from][lastTokenIndex];

 _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
 _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
 }

 // This also deletes the contents at the last position of the array
 delete _ownedTokensIndex[tokenId];
 delete _ownedTokens[from][lastTokenIndex];
 }
 function _removeTokenFromAllTokensEnumeration(uint tokenId) private
 {
 // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
 // then delete the last slot (swap and pop).

 uint lastTokenIndex = _allTokens.length - 1;
 uint tokenIndex = _allTokensIndex[tokenId];

 // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
 // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
 // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
 uint lastTokenId = _allTokens[lastTokenIndex];

 _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
 _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

 // This also deletes the contents at the last position of the array
 delete _allTokensIndex[tokenId];
 _allTokens.pop();
 }
}
//==============================================================================
contract NtfULoanGenesis is ERC721Enumerable
{
 using Address for address;
 using Strings for uint;

 modifier callerIsUser()
 {
 require(tx.origin == msg.sender, "The caller is another contract");
 _;
 }

 event onWidthdrawal(address from, address to, uint amount);
 event Reserved(address wallet, uint amount);
 event SetRaffleDates(uint startDate, uint endDate);
 event SetPresalesDate(uint newDate, uint oldDate);
 event SetSalesDate(uint newDate, uint oldDate);
 event SetWhitelistPrice(uint newPrice);
 event SetSalesPrice(uint newPrice);
 event SetVIPPrice(uint newPrice);
 
 uint private totalTokens = 3555; 
 uint private maxMintable = 3333;
 uint private leftTokenCount = totalTokens;
 uint private mintedTokenCount = 0;
 uint private generatedTokenCount = 0;

 string private baseURI = '/';

 address private ownerWallet;

 uint[] whitelistPrices = [ 0.2 ether, 0.2 ether ];
 uint[] salesPrices = [ 0.3 ether, 0.3 ether ];
 uint[] vipPrices = [ 0.2 ether, 0.2 ether ];

 uint public whitelistPrice;
 uint public salesPrice;
 uint public vipPrice;

 uint public raffleStartDate = 1656262800;
 uint public raffleEndDate = 1656277199;
 uint public presalesDate = 1656277200;
 uint public salesDate = 1656338400;

 string private signHeader = "\x19Ethereum Signed Message:\n32";

 mapping(bytes32 => bool) private proposedHashes; // used to avoid using the same hash on CreateLoan calls

 mapping(address => uint) private walletMintedTokenIds;

 mapping(address => uint) private mintedQuantities;
 mapping(address => uint) private vipQuantities;
 mapping(address => uint) private whitelistedQuantities;
 mapping(address => uint) private claimedQuantities;

 mapping(uint => uint) private mintedTokenTimestamps;

 string private magicLettersCode = "FFFNTNTAFAANAFOANTNTFNTLONOFNFNNTNOFFAAUTOOUNTNFNNANAFTNOFNNLTOLNNNOFNNNFTTFFNFTNTNFNOLUTTTUTUTATNFL";
 mapping(uint => string) private tokenMagicLetters;

 constructor() ERC721("Genesis Alpha", "ULGAP") // temporary Symbol and title
 //constructor() ERC721("ULoan Genesis Pass", "ULGP")
 {
 ownerWallet = msg.sender;

 uint priceIdx = 0;
 if (block.chainid!=1) priceIdx = 1;

 whitelistPrice = whitelistPrices[priceIdx];
 salesPrice = salesPrices[priceIdx];
 vipPrice = vipPrices[priceIdx];
 }
 //------------------------------------------------------------------------
 function isERC721ReceivedCheck(address from,address to,uint tokenId,bytes memory _data) private returns (bool)
 {
 if (to.isContract())
 {
 try
 
 IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
 
 returns (bytes4 retval)
 {
 return retval == IERC721Receiver(to).onERC721Received.selector;
 }
 catch (bytes memory reason)
 {
 if (reason.length==0)
 {
 revert("ERC721: transfer to non ERC721Receiver implementer");
 }
 else
 {
 assembly { revert(add(32, reason), mload(reason)) } //// solhint-disable-next-line no-inline-assembly
 }
 }
 }
 else
 {
 return true;
 }
 }
 //------------------------------------------------------------------------
 function setBaseTokenURI(string memory newUri) external onlyOwner
 {
 baseURI = newUri;
 }
 //------------------------------------------------------------------------
 function baseTokenURI() external view returns (string memory)
 {
 return baseURI;
 }
 //------------------------------------------------------------------------
 function getAvailableTokens() external view returns (uint)
 {
 return leftTokenCount;
 }
 //------------------------------------------------------------------------
 function _baseURI() internal view virtual override returns (string memory)
 {
 return baseURI;
 }
 //------------------------------------------------------------------------
 function getTokenIdsByWallet(address walletAddress) external view returns(uint[] memory)
 {
 require(walletAddress!=address(0), "BlackHole wallet is not a real owner");
 
 uint count = balanceOf(walletAddress);
 uint[] memory result = new uint[](count);
 
 for (uint i=0; i<count; i++)
 {
 result[i] = tokenOfOwnerByIndex(walletAddress, i);
 }
 
 return result;
 }
 //---------------------------------------------------------------------------
 function setWhitelistPrice(uint newPrice) external onlyOwner
 {
 whitelistPrice = newPrice;

 emit SetWhitelistPrice(newPrice);
 }
 //---------------------------------------------------------------------------
 function setVIPPrice(uint newPrice) external onlyOwner
 {
 vipPrice = newPrice;

 emit SetVIPPrice(newPrice);
 }
 //---------------------------------------------------------------------------
 function getVIPPrice() external view returns(uint price)
 {
 return vipPrice;
 }
 //---------------------------------------------------------------------------
 function setSalesPrice(uint newPrice) external onlyOwner
 {
 salesPrice = newPrice;

 emit SetSalesPrice(newPrice);
 }
 //---------------------------------------------------------------------------
 function reserve(uint amount) external onlyOwner
 {
 require(leftTokenCount >= amount, "Not enough tokens left to reserve anymore");

 for (uint i=0; i < amount; i++)
 {
 generatedTokenCount++;
 
 mintedTokenTimestamps[generatedTokenCount] = block.timestamp;
 
 _safeMint(msg.sender, generatedTokenCount);

 setTokenMagicLetter(generatedTokenCount);
 }

 leftTokenCount = totalTokens - generatedTokenCount;

 emit Reserved(msg.sender, amount);
 }
 //---------------------------------------------------------------------------
 function mint(address toWallet, uint quantity) external payable // toWallet is used for compatibility with crossmint.io
 {
 require(block.timestamp>=salesDate, "Minting is closed"); // mint possible only during public sales
 require(toWallet!=address(0), "Blackhole forbidden");
 require(salesPrice!=0, "Invalid internal price");
 require(quantity>0 && quantity<=2, "Invalid NFT quantity");
 require(msg.value==salesPrice*quantity, "Send exact Amount to claim your Nft");
 require(leftTokenCount > 0, "No tokens left to be claimed");
 require(mintedTokenCount<maxMintable, "Sold-out");
 require(mintedTokenCount+quantity<=maxMintable, "Not enough NFT left to mint");

 uint qty = mintedQuantities[toWallet] + quantity;

 require(qty<=2, "Too many claimed"); 

 mintedQuantities[toWallet] += quantity;

 for (uint i=0; i < quantity; i++)
 {
 mintedTokenCount++;
 generatedTokenCount++;
 leftTokenCount--;

 mintedTokenTimestamps[generatedTokenCount] = block.timestamp;

 _mint(toWallet, generatedTokenCount);

 setTokenMagicLetter(generatedTokenCount);
 }
 }
 //---------------------------------------------------------------------------
 function whitelistMint(address toWallet, uint quantity, bytes32 proposedHash,uint8 v,bytes32 r,bytes32 s) external payable // toWallet is used for compatibility with crossmint.io
 {
 //----- Signed function checker

 bool isProposedHashedUsed = proposedHashes[proposedHash];

 require(isProposedHashedUsed==false, "Bad Hash");

 proposedHashes[proposedHash] = true;

 bytes32 messageDigest = keccak256(abi.encodePacked(signHeader, proposedHash));
 bool isFromAdmin = (ecrecover(messageDigest, v, r, s)==admin());

 require(isFromAdmin==true, "Bad call");

 //----- 

 require(block.timestamp>=presalesDate, "Pre-minting is not opened"); 
 require(block.timestamp<salesDate, "Pre-minting is closed");
 require(toWallet!=address(0), "Blackhole forbidden");
 require(quantity>0 && quantity<=2, "Invalid NFT quantity");
 require(whitelistPrice!=0, "Invalid internal price");
 require(msg.value==whitelistPrice*quantity, "Send exact Amount to claim your Nft");
 require(leftTokenCount > 0, "No tokens left to be claimed");
 require(mintedTokenCount<maxMintable, "Sold-out");
 require(mintedTokenCount+quantity<=maxMintable, "Not enough NFT left to mint");

 uint qty = whitelistedQuantities[toWallet] + quantity;

 require(qty<=2, "Too many claimed"); 

 whitelistedQuantities[toWallet] += quantity;

 for (uint i=0; i < quantity; i++)
 {
 mintedTokenCount++;
 generatedTokenCount++;
 leftTokenCount--;

 mintedTokenTimestamps[generatedTokenCount] = block.timestamp;

 _mint(toWallet, generatedTokenCount);

 setTokenMagicLetter(generatedTokenCount);
 }
 }
 //---------------------------------------------------------------------------
 function vipMint(address toWallet, uint quantity, bytes32 proposedHash,uint8 v,bytes32 r,bytes32 s) external payable // toWallet is used for compatibility with crossmint.io
 {
 //----- Signed function checker

 bool isProposedHashedUsed = proposedHashes[proposedHash];

 require(isProposedHashedUsed==false, "Bad Hash");

 proposedHashes[proposedHash] = true;

 bytes32 messageDigest = keccak256(abi.encodePacked(signHeader, proposedHash));
 bool isFromAdmin = (ecrecover(messageDigest, v, r, s)==admin());

 require(isFromAdmin==true, "Bad call");

 //-----
 
 require(quantity>0 && quantity<=3, "Invalid NFT quantity");
 require(leftTokenCount>= quantity, "No tokens left to be minted");
 require(vipPrice!=0, "Invalid internal price");
 require(msg.value==vipPrice*quantity, "Bad price amount");
 require(getGenesisPassMode()!=0, "Mint is closed");

 uint qty = vipQuantities[toWallet] + quantity;

 require(qty<=3, "You cannot mint any more"); 

 //-----

 vipQuantities[toWallet] += quantity;

 for (uint i=0; i < quantity; i++)
 {
 mintedTokenCount++;
 generatedTokenCount++;
 leftTokenCount--;

 mintedTokenTimestamps[generatedTokenCount] = block.timestamp;

 _mint(toWallet, generatedTokenCount);

 setTokenMagicLetter(generatedTokenCount);
 }
 }
 //---------------------------------------------------------------------------
 function claim(uint quantity, bytes32 proposedHash,uint8 v,bytes32 r,bytes32 s) external 
 {
 //----- Signed function checker

 bool isProposedHashedUsed = proposedHashes[proposedHash];

 require(isProposedHashedUsed==false, "Bad Hash");

 proposedHashes[proposedHash] = true;

 bytes32 messageDigest = keccak256(abi.encodePacked(signHeader, proposedHash));
 bool isFromAdmin = (ecrecover(messageDigest, v, r, s)==admin());

 require(isFromAdmin==true, "Bad call");

 //-----
 
 require(getGenesisPassMode()>1, "Claim is not active");
 require(leftTokenCount>= quantity, "No tokens left to be claimed");

 claimedQuantities[msg.sender] += quantity;

 for (uint i=0; i < quantity; i++)
 {
 generatedTokenCount++;
 leftTokenCount--;

 mintedTokenTimestamps[generatedTokenCount] = block.timestamp;

 _mint(msg.sender, generatedTokenCount);

 setTokenMagicLetter(generatedTokenCount);
 }
 }
 //---------------------------------------------------------------------------
 function hasClaimed(address wallet) external view returns(bool)
 {
 return claimedQuantities[wallet]!=0;
 }
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 function getWalletQuantities(address wallet) external view returns(TQuantities memory)
 {
 TQuantities memory QTY = TQuantities
 (
 mintedQuantities[wallet],
 vipQuantities[wallet],
 whitelistedQuantities[wallet],
 claimedQuantities[wallet]
 );

 return QTY;
 }
 //---------------------------------------------------------------------------
 function getGenesisPassMode() public view returns(uint currentSellMode) // MODE => 0:OFF 1:RAFFLE 2:PRESALE 3:PUBLICSALE
 {
 uint mode = 0; // OFF

 if (block.timestamp>=salesDate) mode = 3; // PUBLIC SALE
 else if (block.timestamp>=presalesDate) mode = 2; // PRE-SALE
 else if (block.timestamp>=raffleStartDate && block.timestamp<=raffleEndDate)
 {
 mode = 1; // RAFFLE
 }
 return mode;
 }
 //---------------------------------------------------------------------------
 function getCurrentPrice() public view returns(uint currentPrice) // MODE => 0:OFF 1:RAFFLE 2:PRESALE 3:PUBLICSALE
 {
 uint mode = getGenesisPassMode();

 uint price = salesPrice;
 if (mode==2) price = whitelistPrice;
 else if (mode==1) price = vipPrice;

 return price;
 }
 //---------------------------------------------------------------------------
 function getMintedCount() public view returns(uint leftCount)
 {
 return mintedTokenCount;
 }
 //---------------------------------------------------------------------------
 function getMintLeft() public view returns(uint leftCount)
 {
 return maxMintable - mintedTokenCount;
 }
 //---------------------------------------------------------------------------
 function getMaxMintableCount() public view returns(uint leftCount)
 {
 return maxMintable;
 }
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 function getDates() external view returns(TDates memory)
 {
 TDates memory datesInfo = TDates
 (
 raffleStartDate,
 raffleEndDate,
 presalesDate,
 salesDate
 );

 return datesInfo;
 }
 //---------------------------------------------------------------------------
 function setRaffleDates(uint startDate, uint endDate) external onlyOwner
 {
 require(startDate < presalesDate, "Cannot start during presales or sale period");
 require(endDate < presalesDate, "Cannot end during presales or sale period");
 require(startDate < endDate, "Invalid date");

 raffleStartDate = startDate;
 raffleEndDate = endDate;

 emit SetRaffleDates(startDate, endDate);
 }
 //---------------------------------------------------------------------------
 function setPresalesDate(uint newDate) external onlyOwner
 {
 require(newDate < salesDate, "Presales should start before public sale");

 uint oldDate = presalesDate;
 presalesDate = newDate;

 emit SetPresalesDate(newDate, oldDate);
 }
 //---------------------------------------------------------------------------
 function setSalesDate(uint newDate) external onlyOwner
 {
 require(newDate > presalesDate, "Presales should start before public sale");

 uint oldDate = salesDate;
 salesDate = newDate;

 emit SetSalesDate(newDate, oldDate);
 }
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 function withdraw() external onlyOwner
 {
 uint balance = address(this).balance;

 payable(ownerWallet).transfer(balance);

 emit onWidthdrawal(address(this), ownerWallet, balance);
 }
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 function getStringChar(string memory str, uint index) public pure returns (string memory ) 
 {
 bytes memory strBytes = bytes(str);
 bytes memory result = new bytes(1);

 result[0] = strBytes[index];
 
 return string(result);
 }
 //---------------------------------------------------------------------------
 function getMagicLettersByTokenIds(uint[] memory tokenIds) external view returns(string[] memory magicLetters)
 {
 string[] memory result = new string[](tokenIds.length);
 
 for (uint i=0; i<tokenIds.length; i++)
 {
 result[i] = tokenMagicLetters[ tokenIds[i] ];
 }
 
 return result;
 }
 //---------------------------------------------------------------------------
 function setTokenMagicLetter(uint tokenId) internal
 {
 string memory letter = getStringChar(magicLettersCode, tokenId % 100);

 tokenMagicLetters[tokenId] = letter;
 }
 //---------------------------------------------------------------------------
 function setTokenMagicLetters(string memory hashCode) external onlyOwner
 {
 magicLettersCode = hashCode;
 }
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
 //---------------------------------------------------------------------------
}