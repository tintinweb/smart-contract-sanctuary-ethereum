/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;
  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }
  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }
  uint256 private currentIndex = 0;
  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;
  string private _name;
  string private _symbol;
  mapping(uint256 => TokenOwnership) private _ownerships;
  mapping(address => AddressData) private _addressData;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  }
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }
  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }
  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");
    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }
    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }
    revert("ERC721A: unable to determine the owner of token");
  }
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }
  function name() public view virtual override returns (string memory) {
    return _name;
  }
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");
    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );
    _approve(to, tokenId, owner);
  }
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");
    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }
  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");
    _beforeTokenTransfers(address(0), to, startTokenId, quantity);
    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));
    uint256 updatedIndex = startTokenId;
    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }
    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);
    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));
    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );
    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");
    _beforeTokenTransfers(from, to, tokenId, 1);
    _approve(address(0), tokenId, prevOwnership.addr);
    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }
    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }
  uint256 public nextOwnerToExplicitlySet = 0;
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
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
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract KER is ERC721A, Ownable, ReentrancyGuard {
    bytes32 whroot;
    bytes32 raroot;
    string public baseTokenURI;
    uint256 public wlprice = 0.025 ether;
    uint256 public wlmaxmint = 10;
    uint256 public rlprice = 0.025 ether;
    uint256 public rlmaxmint = 10;
    uint256 public pbprice = 0.04 ether;
    uint256 public pbmaxmint = 20;
    uint256 public collectionsize = 100;
    uint256 public reservedsize = 10;
    uint256 public mintpause;
    uint256 public whitelistmintopen;
    uint256 public rafflemintopen;
    uint256 public publicmintopen=1;
    mapping(address => uint256) public mintedq;
constructor() ERC721A("KKEERR", "KER",5,100){}
    function _onlyMinter() private view 
    { 
	require(msg.sender == tx.origin);
    }
    modifier onlyMinter 
    {
	_onlyMinter();
	_;
    }
    function mintTo(address recipient) public onlyOwner returns (uint256) 
    {
	_safeMint(recipient, 1);
	return 1;
    }
    function calculateq(uint256 ev, uint256 aprice) internal view returns (uint256) 
    {
        uint256 r=ev%aprice;
        require(r==0,"Bad ammount of ETH");
        uint256 a=ev/aprice;
        require(a>0,"Input amount=0");
        require(totalSupply() + a <= collectionsize - reservedsize, "Sold out!" );
        return a;
    }
    function whitelistMint(bytes32[] memory proof) external payable onlyMinter nonReentrant
    {
	uint256 st;
	uint256 pri;
	uint256 max;
	bytes32 cHa;
	require(mintpause==0, "Minting is not live yet!");
	cHa = keccak256(abi.encodePacked(msg.sender));
    	for (uint256 i = 0; i < proof.length; i++) 
	{
	    bytes32 pEl = proof[i];
    	    if (cHa <= pEl) 
	    {
        	cHa = keccak256(abi.encodePacked(cHa, pEl));
    	    } else {
                cHa = keccak256(abi.encodePacked(pEl, cHa));
    	    }
    	}
	if ( whitelistmintopen == 1 && cHa == whroot ) 
	{
	    st=1;
	    pri=wlprice;
	    max=wlmaxmint;
	}
	if ( rafflemintopen == 1 && cHa == raroot )
	{
	    st=1;
	    pri=rlprice;
	    max=rlmaxmint;
	}
	require( st==1, "You are not eligible for Whitelist or Raffle mint!" );
        st=calculateq(msg.value,pri);
        require(mintedq[msg.sender]+st<=max,"This would exceed the maximum NFTs/address!");
        mintedq[msg.sender]+=st;
	_safeMint(msg.sender,st);
    }
    function publicMint() external payable onlyMinter nonReentrant
    {
	uint256 st;
	require(mintpause==0, "Minting is not live yet!");
	require(publicmintopen!=0, "Public minting is not open!");
        st=calculateq(msg.value,pbprice);
        require(mintedq[msg.sender]+st<=pbmaxmint,"This would exceed the maximum NFTs/address!");
        mintedq[msg.sender]+=st;
	_safeMint(msg.sender,st);
    }
    function _baseURI() internal view virtual override returns (string memory) 
    {
	return baseTokenURI;
    }
    function setBaseTokenURI(string memory _b) public onlyOwner 
    {
	baseTokenURI = _b;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
	string memory currentBaseURI = _baseURI();
	return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), "")) : "";
    }
    function _sendmoney(address _address, uint256 _amount) private 
    {
        (bool success, ) = _address.call{value: _amount}("");
	require(success, "Transfer failed.");
    }
    function withdraw() public onlyOwner 
    {
	_sendmoney(owner(),address(this).balance);
    }
    function withdrawto(address payable to, uint256 amount) public onlyOwner 
    {
	require( address(this).balance >= amount, "Insufficient balance to withdraw");
	_sendmoney(to,amount);
    }
    function setwlprice(uint256 _p) external onlyOwner 
    {
	wlprice=_p;
    }
    function setwlmaxmint(uint256 _p) external onlyOwner 
    {
	wlmaxmint=_p;
    }
    function setrlprice(uint256 _p) external onlyOwner 
    {
	rlprice=_p;
    }
    function setrlmaxmint(uint256 _p) external onlyOwner 
    {
	rlmaxmint=_p;
    }
    function setpbprice(uint256 _p) external onlyOwner 
    {
	pbprice=_p;
    }
    function setpbmaxmint(uint256 _p) external onlyOwner 
    {
	pbmaxmint=_p;
    }
    function setreserveditem(uint256 _p) external onlyOwner 
    {
	reservedsize=_p;
    }
    function setcollectionsize(uint256 _p) external onlyOwner 
    {
	collectionsize=_p;
    }
    function setmintpause(uint256 _st) external onlyOwner
    {
        mintpause = _st;
    }
    function setwhitelistmintopen(uint256 _st) external onlyOwner
    {
        whitelistmintopen = _st;
    }
    function setrafflemintopen(uint256 _st) external onlyOwner
    {
        rafflemintopen = _st;
    }
    function setpublicmintopen(uint256 _st) external onlyOwner
    {
        publicmintopen = _st;
    }
    function getmintstatus(address minter) public view virtual returns (string memory) 
    {
	string memory o1 = string(abi.encodePacked(
	"mintpause:",Strings.toString(mintpause),
	";whitelist:",Strings.toString(whitelistmintopen), 
	";raffle:",Strings.toString(rafflemintopen), 
	";public:",Strings.toString(publicmintopen), 
	";wlprice:",Strings.toString(wlprice), 
	";wlmaxmint:",Strings.toString(wlmaxmint)
	));
	string memory o2 = string(abi.encodePacked(
	";rlprice:",Strings.toString(rlprice), 
	";rlmaxmint:",Strings.toString(rlmaxmint),
	";pbprice:",Strings.toString(pbprice), 
	";pbmaxmint:",Strings.toString(pbmaxmint),
	";currenttokeid:", Strings.toString(totalSupply()), 
	";reservedsize:", Strings.toString(reservedsize), 
	";collectionsize:", Strings.toString(collectionsize),
	";minted:", Strings.toString(mintedq[minter]) 
	));
	string memory outstring = string(abi.encodePacked(o1,o2));
	return outstring;
    }
    function gettokens(address tokenowner) public view virtual returns(uint32[] memory) 
    {
	uint256 j;
	uint256 all;
	require(totalSupply() > 0);
	require(ERC721A.balanceOf(tokenowner) > 0);
        uint32[] memory _tokens = new uint32[](ERC721A.balanceOf(tokenowner));
	all = totalSupply();
        for (uint256 i = 0; i < all; i++) 
	{
	    if ( ownerOf(i) == tokenowner )
	    {
    	        _tokens[j] = uint32(i);
		j += 1;
	    }
        }
	return _tokens;
    }
    function setwhitelistroot(bytes32 _mr) external onlyOwner
    {
	whroot = _mr;
    }
    function setraffleroot(bytes32 _mr) external onlyOwner
    {
	raroot = _mr;
    }
}