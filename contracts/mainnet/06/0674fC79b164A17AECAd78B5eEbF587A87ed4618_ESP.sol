/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
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
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
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
contract ESP is ERC721A, Ownable, ReentrancyGuard {
    string public baseTokenURI;
    bytes32 whroot;
    uint256 public collectionsize = 555;
    uint256 public reservedsize = 20;
    uint256 public maxmint = 1;
    uint256 public whitelistprice = 0.055 ether;
    uint256 public publicprice = 0.075 ether;
    bytes internal constant alphabet = "0123456789abcdef";
    uint256 public mintpause=1;
    uint256 public whitelistmintopen;
    uint256 public publicmintopen;
    uint256 public textvisible=1;
    mapping(address => uint256) public mintedq;
constructor() ERC721A("Ether Sign Pass", "ESP",3,555)
{}
    function _onlyMinter() private view 
    { 
	require(msg.sender == tx.origin);
    }
    modifier onlyMinter 
    {
	_onlyMinter();
	_;
    }
    function ownerMintMulti(address recipient,uint256 value) public onlyOwner returns (uint256) 
    {
	_safeMint(recipient, value);
	return 1;
    }
    function isOwner(uint256 _id, address _address) public view virtual returns (bool) 
    {
	return ownerOf(_id) == _address;
    }
    function toString(address account) public pure returns(string memory) 
    {
	return toString(abi.encodePacked(account));
    }
    function toString(bytes memory data) public pure returns(string memory) 
    {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) 
	{
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
    function makecolor(uint256 c) public pure returns (string memory) 
    {
	bytes memory b2 = "0ff000";
	bytes memory b1 = "f0000f";
	bytes memory b0 = "000ff0";
	bytes memory str = new bytes(3);
	uint256 method = (c>>4)%6;
	str[2] = b2[method];
	str[1] = b1[method];
	str[0] = b0[method];
        str[method/2] = alphabet[uint(uint8(c%16))];
	return string(str);
    }
    function createSVG(uint256 tokenId,address wallet) public view returns (string memory) 
    {
	bytes memory pathstr;
	string memory outstr;
	uint256 i;
        uint256 segments;
        uint256 eltx;
        uint256 elty;
        uint256 maxx;
        uint256 miny;
        uint256 maxy;
	uint256[32] memory xc;
	uint256[32] memory yc;
	bytes memory w = abi.encodePacked(keccak256(abi.encodePacked(wallet)));
	segments = (uint256(uint8(w[0]))%(22-8))+8;
	xc[0]=0;
        yc[0]=uint256(uint8(w[3]))%400;
	for(i=1;i!=segments;i++)
	{
	    xc[i]=(400/segments)*i;
	    yc[i]=uint256(uint8(w[i+3]))%400;
	}
        miny=400-1;
        maxx = 0;
        maxy = 0;
	for(i=0;i!=segments;i++)
	{
	    if ( yc[i] <= miny ) miny = yc[i];
	    if ( xc[i] >= maxx ) maxx = xc[i];
	    if ( yc[i] >= maxy ) maxy = yc[i];
	}
	eltx = (500-400)/2 + (400-(maxx))/2;
        elty = (500-400)/2 + (400-(maxy-miny))/2 - miny;
	for(i=0;i!=segments;i++)
	{
	    xc[i] += eltx;
	    yc[i] += elty;
	}
	maxx = uint256(uint8(w[1]));
	maxy = uint256(uint8(w[2]));
	eltx = maxx % 96;
	elty = (maxy + maxx%48 + 11) % 96; 
	if ( textvisible == 1 )
	{
	    pathstr = abi.encodePacked("<text style=\"font-size: 14px;font-family: Courier\" x=\"50%\" y=\"30\" dominant-baseline=\"middle\" text-anchor=\"middle\" fill=\"#aaa\">Owned by ",toString(wallet),"</text>");
	} else {
	    pathstr = "";
	}
	pathstr = abi.encodePacked(pathstr,"<defs><linearGradient id=\"gr1\"><stop offset=\"0%\" style=\"stop-color:#",makecolor(eltx),"\"/><stop offset=\"100%\" style=\"stop-color:#",makecolor(elty),"\"/></linearGradient></defs><path d=\"M",Strings.toString(xc[0])," ",Strings.toString(yc[0])," Q");
	for(i=1;i!=segments;i++)
	{
	    pathstr = abi.encodePacked(pathstr,Strings.toString(xc[i])," ",Strings.toString(yc[i]),",");
	}
	pathstr = abi.encodePacked(pathstr,"\" fill=\"none\" stroke=\"url(#gr1)\" stroke-width=\"30\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/>");
	outstr = string(abi.encodePacked('<svg xmlns="http:/','/www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500"><rect x="0" y="0" width="500" height="500" fill="#fff"/>',pathstr,'</svg>'));
	outstr = b64encode(bytes(outstr));
	outstr = string(abi.encodePacked('{"name": "Ether Sign Pass #',Strings.toString(tokenId),'", "attributes": [{"trait_type": "Segments","value": "',Strings.toString(segments),'"},{"trait_type": "Start color","value": "#',makecolor(eltx),'"}, {"trait_type": "Stop color","value": "#',makecolor(elty),'"}],"image": "data:image/svg+xml;base64,',outstr,'"}'));
	return string(outstr);
    }
    function tokenURI(uint256 tokenId) override public view returns (string memory) 
    {
	string memory pathstr;
	pathstr = createSVG(tokenId,ownerOf(tokenId));
	return string(abi.encodePacked('data:application/json;base64,',b64encode(bytes(pathstr))));
    }
    function setPublicPrice(uint256 _p) external onlyOwner 
    {
	publicprice=_p;
    }
    function setPublicMintOpen(uint256 _st) external onlyOwner
    {
        publicmintopen = _st;
    }
    function setWhitelistPrice(uint256 _p) external onlyOwner 
    {
	whitelistprice=_p;
    }
    function setWhitelistMintOpen(uint256 _st) external onlyOwner
    {
        whitelistmintopen = _st;
    }
    function setCollectionSize(uint256 _p) external onlyOwner 
    {
	collectionsize=_p;
    }
    function setReservedSize(uint256 _p) external onlyOwner 
    {
	reservedsize=_p;
    }
    function setMintPause(uint256 _p) external onlyOwner
    {
        mintpause = _p;
    }
    function setMaxMint(uint256 _p) external onlyOwner 
    {
	maxmint=_p;
    }
    function setWhitelistRoot(bytes32 _wh) external onlyOwner
    {
	whroot = _wh;
    }
    function setTextVisible(uint256 _p) external onlyOwner 
    {
	textvisible=_p;
    }
    function getmintstatus(address minter) public view virtual returns (string memory) 
    {
	string memory o1 = string(abi.encodePacked(
	"mintpause:",Strings.toString(mintpause),
	";publicprice:",Strings.toString(publicprice), 
	";whitelistprice:",Strings.toString(whitelistprice), 
	";whitelist:",Strings.toString(whitelistmintopen), 
	";public:",Strings.toString(publicmintopen), 
	";maxmint:",Strings.toString(maxmint)
	));
	string memory o2 = string(abi.encodePacked(
	";totalsupply:", Strings.toString(totalSupply()), 
	";reservedsize:", Strings.toString(reservedsize), 
	";collectionsize:", Strings.toString(collectionsize),
	";minted:", Strings.toString(mintedq[minter]) 
	));
	string memory outstring = string(abi.encodePacked(o1,o2));
	return outstring;
    }
    function publicMint(uint256 st) external payable onlyMinter nonReentrant
    {
	require(mintpause==0, "Minting is not live yet!");
	require(publicmintopen!=0, "Public minting is not open!");
	if ( publicprice > 0 )
	{
    	    uint256 r=msg.value%publicprice;
    	    require(r==0,"Bad ammount of ETH");
    	    st=msg.value/publicprice;
    	    require(st>0,"Input amount=0");
	}
        require(mintedq[msg.sender] + st<=maxmint,"This would exceed the maximum NFTs/address!");
        require(totalSupply() + st <= collectionsize - reservedsize, "Sold out!" );
        mintedq[msg.sender]+=st;
	_safeMint(msg.sender,st);
    }
    function whitelistMint(uint256 st, bytes32[] memory proof) external payable onlyMinter nonReentrant
    {
	bytes32 cHa;
	require(mintpause==0, "Minting is not live yet!");
	require(whitelistmintopen!=0, "Whitelist minting is not open!");
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
	require( cHa==whroot, "You are not eligible for Whitelist mint!" );
	if ( whitelistprice > 0 )
	{
    	    uint256 r=msg.value%whitelistprice;
    	    require(r==0,"Bad ammount of ETH");
    	    st=msg.value/whitelistprice;
    	    require(st>0,"Input amount=0");
	}
        require(mintedq[msg.sender] + st<=maxmint,"This would exceed the maximum NFTs/address!");
        require(totalSupply() + st <= collectionsize - reservedsize, "Sold out!" );
        mintedq[msg.sender]+=st;
	_safeMint(msg.sender,st);
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
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    function b64encode(bytes memory data) internal pure returns (string memory) 
    {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}