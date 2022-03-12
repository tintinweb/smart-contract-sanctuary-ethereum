/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

contract NftBroker {
  
  address token;
  address owner;
  uint256 ethListFee;
  uint256 ercListFee;

  mapping (string => bool) public promoCodes;
  
  struct sell {
    address seller;
    uint256 price;
    bool isErc20;
    uint256 timestamp;
  }

  mapping (address => mapping (uint256 => sell)) public _listings;

  struct broke {
    address broker;
    uint256 expiry;
  }

  mapping (address => mapping (uint256 => broke)) public _brokerages;

  bytes4 [] public listIERC721;
  bytes4 [] public listIERC1155;
  
  constructor() {
    owner = msg.sender;
  }

  function setToken(address _token) public {
    require(msg.sender == owner);
    token = _token;
  }
 
  function setEthListFee (uint256 _fee) public {
    require(msg.sender == owner);
    ethListFee = _fee;
  }

  function setErcListFee (uint256 _fee) public {
    require(msg.sender == owner);
    ercListFee = _fee;
  }

  function addPromoCode(string memory _promoCode) public {
    require(msg.sender == owner);
    promoCodes[_promoCode] = true;
  }

  function removePromoCode(string memory _promoCode) public {
    require(msg.sender == owner);
    promoCodes[_promoCode] = false;
  }

  function add721(bytes4 _interfaceID) public {
    require(msg.sender == owner);
    listIERC721.push(_interfaceID);
  }

  function add1155(bytes4 _interfaceID) public {
    require(msg.sender == owner);
    listIERC1155.push(_interfaceID);
  }

  function sellNft (address _address, uint256 _id, uint256 _price, bool _isErc20, string memory _promoCode) public payable {
    bool erc721 = is721(_address);
    bool erc1155 = is1155(_address);
    require(erc721 || erc1155, "token standard not supported");
    if (!promoCodes[_promoCode]) {
      if (msg.value > 0)
        require(msg.value >= ethListFee, "list fee required");
      else {
        require(IERC20(token).transferFrom(msg.sender, address(this), ercListFee), "list fee required");
      }
    }
    if (erc721)
      IERC721(_address).safeTransferFrom(msg.sender, address(this), _id);
    else
      IERC1155(_address).safeTransferFrom(msg.sender, address(this), 1, _id, "");
    _listings[_address][_id].seller = msg.sender;
    _listings[_address][_id].price = _price;
    _listings[_address][_id].isErc20 = _isErc20;
  }

  function cancelSellNft(address _address, uint256 _id) public {
    require(msg.sender == _listings[_address][_id].seller, "not allowed");
    require(_brokerages[_address][_id].expiry > 0 && _brokerages[_address][_id].expiry < block.timestamp, "invalid");
    delete _listings[_address][_id];
    delete _brokerages[_address][_id];
  }

  function brokeNft(address _address, uint256 _id) public {
    if (_brokerages[_address][_id].expiry > 0) {
      if (_brokerages[_address][_id].expiry < block.timestamp)
        delete _brokerages[_address][_id];
      else
        revert("brokerage exists");
    }
    _brokerages[_address][_id].broker = msg.sender;
    _brokerages[_address][_id].expiry = block.timestamp + (21 * 24 * 60 * 60);
  }

  function cancelBrokeNft(address _address, uint256 _id) public {
    require(_brokerages[_address][_id].broker == msg.sender, "invalid request");
    delete _brokerages[_address][_id];
  }

  function buyNft(address _address, uint256 _id) public payable {
    require(_brokerages[_address][_id].expiry > block.timestamp, "invalid brokerage");
    bool erc721 = is721(_address);
    if (_listings[_address][_id].isErc20) {
      uint256 fee = (_listings[_address][_id].price * 95) / 100;
      uint256 priceAfterFee = _listings[_address][_id].price - fee;
      require(IERC20(token).transferFrom(msg.sender, _listings[_address][_id].seller, priceAfterFee));
      require(IERC20(token).transferFrom(msg.sender, _brokerages[_address][_id].broker, fee));
    }
    else {
      require(msg.value >= _listings[_address][_id].price);
      uint256 brokerFee = (_listings[_address][_id].price * 50) / 1000;
      uint256 companyFee = (_listings[_address][_id].price * 25) / 1000;
      uint256 priceAfterFee = _listings[_address][_id].price - brokerFee - companyFee;
      (bool sentToSeller, ) = _listings[_address][_id].seller.call{value: priceAfterFee}("");
      require(sentToSeller, "Failed to send Ether");
      (bool sentToBroker, ) = _brokerages[_address][_id].broker.call{value: brokerFee}("");
      require(sentToBroker, "Failed to send Ether");
    }
    if (erc721)
      IERC721(_address).safeTransferFrom(address(this), msg.sender, _id);
    else 
      IERC1155(_address).safeTransferFrom(address(this), msg.sender, _id, 1, "");
    delete _listings[_address][_id];
    delete _brokerages[_address][_id];
  }

  function is721(address _address) internal view returns (bool) {
    for (uint256 i = 0; i < listIERC721.length; i++) {
      if (IERC721(_address).supportsInterface(listIERC721[i]))
        return true;
    }
    return false;
  }

  function is1155(address _address) internal view returns (bool) {
    for (uint256 i = 0; i < listIERC1155.length; i++) {
      if (IERC1155(_address).supportsInterface(listIERC1155[i]))
        return true;
    }
    return false;
  }
  
}