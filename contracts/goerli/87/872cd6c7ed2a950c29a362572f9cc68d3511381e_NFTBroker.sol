/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
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
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}
interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
interface IERC1155 {
  function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
interface IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC1155Receiver {
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);
}
contract NFTBroker is IERC721Receiver, IERC1155Receiver, ReentrancyGuard {

  address public token;
  address public owner;
  uint256 public ethListFee;
  uint256 public ercListFee;

  struct package {
    uint256 ethPrice;
    uint256 ercPrice;
  }

  struct broke {
    address broker;
    uint256 expiry;
  }
  
  struct sell {
    address seller;
    uint256 price;
    bool isErc20;
  }

  mapping (string => bool) public promoCodes;
  mapping (uint256 => package) public packages;

  mapping (address => mapping (uint256 => sell)) public listings;
  mapping (address => mapping (uint256 => broke)) public brokerage;

  event _721Received();
  event _1155Received();
  event _addPromoCode(string promoCode);
  event _removePromoCode(string promoCode);
  event _addPackage(uint day, uint ethPrice, uint ercPrice);
  event _buyNFT(address userAddress, address tokenAddress, uint tokenId);
  event _brokeNFT(address userAddress, address tokenAddress, uint tokenId, uint timestamp);
  event _cancelSellNFT(address userAddress, address tokenAddress, uint tokenId);
  event _cancelBrokeNFT(address userAddress, address tokenAddress, uint tokenId);
  event _sellNFT(address userAddress, address tokenAddress, uint tokenId, uint price, string promoCode, bool isErc20);

  constructor() {
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner, "x");
    _;
  }
  function setToken(address _token) external onlyOwner {
    token = _token;
  }
  function setEthListFee(uint256 _fee) external onlyOwner {
    ethListFee = _fee;
  }
  function setErcListFee(uint256 _fee) external onlyOwner {
    ercListFee = _fee;
  }
  function addPromoCode(string memory _promoCode) external onlyOwner {
    promoCodes[_promoCode] = true;
    emit _addPromoCode(_promoCode);
  }
  function removePromoCode(string memory _promoCode) external onlyOwner {
    promoCodes[_promoCode] = false;
    emit _removePromoCode(_promoCode);
  }
  function addPackage(uint256 _days, uint256 _ethPrice, uint256 _ercPrice) external onlyOwner {
    packages[_days].ethPrice = _ethPrice;
    packages[_days].ercPrice = _ercPrice;
    emit _addPackage(_days, _ethPrice, _ercPrice);
  }
  function removePackage(uint256 _days) external onlyOwner {
    delete packages[_days];
  }
  function sellNft (address _address, uint256 _id, uint256 _price, string memory _promoCode, bool _isErc20, bool isERC721) public payable nonReentrant{
    if(!promoCodes[_promoCode]) {
      if(msg.value > 0) require(msg.value >= ethListFee, "1");
      else require(IERC20(token).transferFrom(msg.sender, address(this), ercListFee), "2"); 
    }
    if(isERC721) IERC721(_address).safeTransferFrom(msg.sender, address(this), _id);
    else IERC1155(_address).safeTransferFrom(msg.sender, address(this), _id, 1, "");
    listings[_address][_id].seller = msg.sender;
    listings[_address][_id].price = _price;
    listings[_address][_id].isErc20 = _isErc20;
    emit _sellNFT(msg.sender, _address, _id, _price, _promoCode, _isErc20);
  }
  function cancelSellNft(address _address, uint256 _id, bool isERC721) public nonReentrant{
    require(msg.sender == listings[_address][_id].seller, "3");
    require(brokerage[_address][_id].expiry < block.timestamp, "8");
    if(isERC721) IERC721(_address).safeTransferFrom(address(this), listings[_address][_id].seller, _id);
    else IERC1155(_address).safeTransferFrom(address(this), listings[_address][_id].seller, _id, 1, "");
    delete listings[_address][_id];
    delete brokerage[_address][_id];
    emit _cancelSellNFT(msg.sender, _address, _id);
  }
  function brokeNft(address _address, uint256 _id, uint256 _packageId) public payable nonReentrant {
    require(listings[_address][_id].seller != address(0), "3");
    require(packages[_packageId].ethPrice > 0 || packages[_packageId].ercPrice > 0, "5");
    if (msg.value > 0) require(msg.value >= packages[_packageId].ethPrice, "1");
    else require(IERC20(token).transferFrom(msg.sender, address(this), packages[_packageId].ercPrice), "7");
    if(brokerage[_address][_id].expiry < block.timestamp) delete brokerage[_address][_id];
    brokerage[_address][_id].broker = msg.sender;
    brokerage[_address][_id].expiry = block.timestamp + (_packageId * 86400);
    emit _brokeNFT(msg.sender, _address, _id, brokerage[_address][_id].expiry);
  }
  function cancelBrokeNft(address _address, uint256 _id) public nonReentrant{
    require(brokerage[_address][_id].broker == msg.sender, "3");
    delete brokerage[_address][_id];
    emit _cancelBrokeNFT(msg.sender, _address, _id);
  }
  function buyNft(address _address, uint256 _id, bool isERC721) public payable nonReentrant {
    require(brokerage[_address][_id].expiry > block.timestamp, "8");
    if (listings[_address][_id].isErc20) {
      uint256 fee = (listings[_address][_id].price * 95) / 100;
      uint256 priceAfterFee = listings[_address][_id].price - fee;
      require(IERC20(token).transferFrom(msg.sender, listings[_address][_id].seller, priceAfterFee), "7");
      require(IERC20(token).transferFrom(msg.sender, brokerage[_address][_id].broker, fee), "7");
    } else {
      require(msg.value >= listings[_address][_id].price, "5");
      uint256 brokerFee = (listings[_address][_id].price * 50) / 1000;
      uint256 companyFee = (listings[_address][_id].price * 25) / 1000;
      uint256 priceAfterFee = listings[_address][_id].price - brokerFee - companyFee;
      (bool sentToSeller, ) = listings[_address][_id].seller.call{value: priceAfterFee}("");
      require(sentToSeller, "6");
      (bool sentToBroker, ) = brokerage[_address][_id].broker.call{value: brokerFee}("");
      require(sentToBroker, "6");
    }
    if (isERC721) IERC721(_address).safeTransferFrom(address(this), msg.sender, _id);
    else IERC1155(_address).safeTransferFrom(address(this), msg.sender, _id, 1, "");
    delete listings[_address][_id];
    delete brokerage[_address][_id];
    emit _buyNFT(msg.sender, _address, _id);
  }
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual override returns (bytes4) {
    operator;
    from;
    tokenId;
    data;
    emit _721Received();
    return this.onERC721Received.selector;
  }
  function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external virtual override returns (bytes4) {
    operator;
    from;
    id;
    value;
    data;
    emit _1155Received();
    return this.onERC1155Received.selector;
  }
  function manageEth(address _to) external onlyOwner {
    (bool sent, ) = _to.call{value: address(this).balance}("");
    require(sent, "6");
  }
  function manageErc(address _to) external onlyOwner {
    uint256 ercBal = IERC20(token).balanceOf(address(this));
    require(IERC20(token).transfer(_to, ercBal), "7");
  }
}