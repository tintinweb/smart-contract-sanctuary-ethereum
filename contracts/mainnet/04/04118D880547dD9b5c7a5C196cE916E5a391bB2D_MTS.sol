/**
 *Submitted for verification at Etherscan.io on 2022-08-12
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
        _setOwner(_msgSender());
    }

 
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
        require(address(this).balance >= amount, "Add");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Add");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Add");
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
        return functionCallWithValue(target, data, value, "Add");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Add");
        require(isContract(target), "Add");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Add");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Add");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Add");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Add");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        require(value == 0, "Strings");
        return string(buffer);
    }
}

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath");
        return a / b;
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

        require(_status != _ENTERED, "ReentrancyGuard");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
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



interface IERC721Receiver {
 
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC20 {
  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
  
    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface IERC721Metadata is IERC721 {
 
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
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

  uint256 internal immutable mintSize;
  uint256 internal immutable maxSize;

  string private _name;

  string private _symbol;

  mapping(uint256 => TokenOwnership) private _ownerships;

  mapping(address => AddressData) private _addressData;

  mapping(uint256 => address) private _tokenApprovals;

  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSize_,
    uint256 mintSize_
  ) {
    require(
      mintSize_ > 0,
      "nonzero supply"
    );
    require(maxSize_ > 0, "nonzero");
    _name = name_;
    _symbol = symbol_;
    maxSize = maxSize_;
    mintSize = mintSize_;
  }

  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "index out");
    return index;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "owner index out");
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
    revert("no index");
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
    require(owner != address(0), "balance zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxSize) {
      lowestTokenToCheck = tokenId - maxSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("unable");
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
      "nonexistent token"
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
    require(to != owner, "approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "not owner"
    );

    _approve(to, tokenId, owner);
  }

  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "nonexistent token");

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "approve to caller");

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
      "non Receiver"
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
    require(to != address(0), "to zero address");

    require(!_exists(startTokenId), "minted");
    require(quantity <= maxSize, "exceed");

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
        ""
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
      ""
    );

    require(
      prevOwnership.addr == from,
      ""
    );
    require(to != address(0), "");

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
    require(quantity > 0, "");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > mintSize - 1) {
      endIndex = mintSize - 1;
    }

    require(_exists(endIndex), "");
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
          revert("");
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

contract MTS is Ownable, ERC721A, ReentrancyGuard {
  using SafeMath for uint256;
  using Strings for uint256;

  uint256 public immutable amountW;
  uint256 public immutable amountFM;

  uint256 public maxPMPT;

  address payoutWT;

  uint256 public mintSTime;
  uint256 public wlSTime;

  uint256 public plMintCost;
  uint256 public wlMintCost;

  MTS tokenURIPlan;
  MTS upgradePlan;

  mapping(address => uint256) public wlMints;

  mapping(uint256 => bool) public upgradedNFTs;
  
  bytes32[] _wlRootHash;

  constructor(
    uint256 maxSize_,
    uint256 mintSize_,
    uint256 amountFM_,
    uint256 amountW_
  ) ERC721A("MetaThreeStar", "MTS", maxSize_, mintSize_) {
    amountFM = amountFM_;
    amountW = amountW_;
    require(
      amountFM_ <= mintSize_,
      "mintable size needed"
    );
    plMintCost = 0.1 ether;
    wlMintCost = 0.05 ether;
    maxPMPT = 10;
  }

  function addToWRHash(bytes32 _hash) public onlyOwner{
        _wlRootHash.push(_hash);
  }

  function clearWL() external onlyOwner{
    delete _wlRootHash;
  }

  function PayoutWallet(address newoutWallet) external onlyOwner{
    payoutWT = newoutWallet;
  }

  function setwlSTime(uint256 _time) external onlyOwner {
    wlSTime = _time;
  }

  function setMintSTime(uint256 _time) external onlyOwner {
    mintSTime = _time;
  }

  function setwlMintCost(uint256 _cost) public onlyOwner{
    wlMintCost = _cost;
  }

  function setplMintCost(uint256 _cost) external onlyOwner {
    plMintCost = _cost;
  }

  function wlValidated(address wallet, uint256 index, uint256 amount, bytes32[] memory proof) internal view returns (bool) {

        bytes32 node = keccak256(abi.encodePacked(index, wallet, amount));
        uint256 path = index;
        for (uint16 i = 0; i < proof.length; i++) {
            if ((path & 0x01) == 1) {
                node = keccak256(abi.encodePacked(proof[i], node));
            } else {
                node = keccak256(abi.encodePacked(node, proof[i]));
            }
            path /= 2;
        }

        for(uint i = 0; i < _wlRootHash.length; i++)
        {
            if (node == _wlRootHash[i])
            {
                return true;
            }
        }

        return false;
    }

  function plMint(uint256 quantity) external payable {
    require(mintSTime != 0 && block.timestamp >= mintSTime, "not started");
    require(totalSupply() + quantity <= amountFM, "Not enough amount");
    require(quantity <= maxPMPT, "Can't mint that many");

    uint256 totalCost = plMintCost * quantity;
    _safeMint(_msgSender(), quantity);
    refundIfOver(totalCost);
  }

  function wlMint(uint256 quantity, uint256 spot, uint256 maxMints, bytes32[] memory proof) external payable {
    require(wlValidated(_msgSender(), spot, maxMints, proof), "Sorry for not on the whitelist");
    require(wlSTime != 0 && block.timestamp >= wlSTime, "not started yet");
    require(totalSupply() + quantity <= amountW, "Not enough remaining");
    require(wlMints[_msgSender()] + quantity <= maxMints, "Not enough available");

    wlMints[_msgSender()] += quantity;

    _safeMint(_msgSender(), quantity);
    refundIfOver(wlMintCost * quantity);
  }

  function upgradeNFT(uint256 tokenId) public {
    require(upgradedNFTs[tokenId] == false, "upgraded");
    upgradePlan.upgradeNFT(tokenId);
  }

  function setMaxplMints(uint256 _max) onlyOwner external {
    maxPMPT = _max;
  }

  function setNFTUpgraded(uint256 tokenId) external {
    require(msg.sender == address(upgradePlan), "Only the upgrade Master");
    upgradedNFTs[tokenId] = true;
  }

  function setTokenURIPlan(address newContract) onlyOwner external{
    tokenURIPlan = MTS(newContract);
  }

  function setUpgradePlan(address newContract) onlyOwner external{
    upgradePlan = MTS(newContract);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need more ETH");
    if (msg.value > price) {
      payable(_msgSender()).transfer(msg.value - price);
    }
  }

  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata"
    );
    if(tokenURIPlan != MTS(address(0)))
    {
      return tokenURIPlan.tokenURI(tokenId);
    }
    else
    {
      string memory baseURI = _baseURI();
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
  }

  function withdraw() external onlyOwner {
        require(payoutWT != address(0), "wallet");
        uint256 balance = address(this).balance;
        payable(payoutWT).transfer(balance);
  }

  function ERC20Withdraw(address Add) external onlyOwner {
        IERC20 tgToken = IERC20(Add);
        uint256 balance = tgToken.balanceOf(address(this));
        require(balance > 0, "Nothing");
        require(payoutWT != address(0), "wallet");

        tgToken.transferFrom(address(this), payoutWT, balance);
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

    function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}