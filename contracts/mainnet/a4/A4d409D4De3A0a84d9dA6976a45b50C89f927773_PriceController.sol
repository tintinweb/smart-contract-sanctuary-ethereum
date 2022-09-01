/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Ownable {
  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

interface IPriceController {
  function addWhitelist(address) external;
  function addFreeWhitelist(address) external;
  function removeWhitelist(address) external;
  function addWhitelists(address[] calldata) external;
  function isWhitelist(address) external view returns (bool);
  function setPrice(uint256, uint256, uint256) external;
  function getPrice(address, uint256) external view returns (uint256);
  function getPrice(address) external view returns (uint256);
  function getPriceOnly(address, uint256) external view returns (uint256);
  function getPriceOnly(address) external view returns (uint256);
}

contract PriceController is Ownable {
  mapping(address => uint8) public notClaimed;
  mapping(uint256 => address) public whitelisted;
  uint256 whitelistSize;
  
  uint256 price;
  uint256 discount;
  uint256 discount2;
  uint256 whitelistSaleStart;
  uint256 publicSaleStart;
  uint256 publicSaleEnd;
  address nftContract;

  bool whitelistSale = true;
  bool saleEnabled = false;


  modifier onlyContract() {
    require(msg.sender == nftContract, "Only accessable through nftContract");
    _;
  }

  modifier timestamp() {
    if(block.timestamp < whitelistSaleStart) {
      whitelistSale = false;
      saleEnabled = false;
    }
    if(block.timestamp >= whitelistSaleStart) {
      whitelistSale = true;
      saleEnabled = true;
    }
    if(block.timestamp >= publicSaleStart) {
      whitelistSale = false;
      saleEnabled = true;
    }
    if(block.timestamp >= publicSaleEnd) {
      saleEnabled = false;
    }
    _;
  }

  function toggleWhitelistSale(bool state_) public onlyOwner {
      require(whitelistSale != state_, "State already set");
      whitelistSale = state_;
  }

  function isWhitelistSale() public view returns (bool) {
      return whitelistSale;
  }

  function setContract(address nftContract_) public onlyOwner {
    nftContract = nftContract_;
  }

  function addWhitelist(address user_) public onlyOwner {
    notClaimed[user_] = 1;
    whitelisted[whitelistSize++] = user_;
  }

  function addFreeWhitelist(address user_) public onlyOwner {
    notClaimed[user_] = 2;
    whitelisted[whitelistSize];
  }

  function removeWhitelist(address user_) public onlyOwner {
    notClaimed[user_] = 0;
  }

  function addWhitelists(address[] calldata user_) public onlyOwner {
    for(uint256 i=0; user_.length != i;) {
      notClaimed[user_[i]] = 1;
      ++i;
    }
  }

  function isWhitelisted(address user_) public view returns(bool) {
    return notClaimed[user_] != 0;
  }

  function setPrice(uint256 price_, uint256 discount_, uint256 discount2_) public onlyOwner {
    price = price_;
    discount = discount_;
    discount2 = discount2_;
  }

  function setTimestamp(uint256 whitelistSaleStart_, uint256 publicSaleStart_, uint256 publicSaleEnd_) public onlyOwner {
    whitelistSaleStart = whitelistSaleStart_;
    publicSaleStart = publicSaleStart_;
    publicSaleEnd = publicSaleEnd_;
  }

  function getTimestamp() public view returns(uint256, uint256, uint256) {
    return(whitelistSaleStart, publicSaleStart, publicSaleEnd);
  }

  function getPrice(address user_, uint256 amount_) public onlyContract timestamp returns(uint256) {
    require(amount_ > 1, "Insufficent mint quantity");
    require(saleEnabled, "Sale is offline");
    if(whitelistSale) { 
      uint256 amount;
      require(isWhitelisted(tx.origin), "Whitelist sale ongoing");
      if(notClaimed[user_] == 1) amount = amount_ * discount;
      if(notClaimed[user_] == 2) amount = --amount_ * discount + discount2;
      notClaimed[user_] = notClaimed[user_] != 0 ? 1 : 0;
      return amount;
    }

    return amount_ * price;
  }

  function getPrice(address user_) public onlyContract timestamp returns(uint256) {
    require(saleEnabled, "Sale is offline");
    if(whitelistSale) { 
      uint256 amount;
      require(isWhitelisted(tx.origin), "Whitelist sale ongoing");
      if(notClaimed[user_] == 1) amount = discount;
      if(notClaimed[user_] == 2) amount = discount2;
      notClaimed[user_] = notClaimed[user_] != 0 ? 1 : 0;
      return amount;
    }

    return price;
  }

  function getPriceOnly(address user_, uint256 amount_) public view returns(uint256) {
    require(amount_ > 1, "Insufficent mint quantity");
    if(whitelistSale) { 
      if(notClaimed[user_] == 1) return amount_ * discount;
      if(notClaimed[user_] == 2) return --amount_ * discount + discount2;
    }
    return amount_ * price;
  }

  function getPriceOnly(address user_) public view returns(uint256) {
    if(whitelistSale) { 
      if(notClaimed[user_] == 1) return discount;
      if(notClaimed[user_] == 2) return discount2;
    }
    return price;
  }

}