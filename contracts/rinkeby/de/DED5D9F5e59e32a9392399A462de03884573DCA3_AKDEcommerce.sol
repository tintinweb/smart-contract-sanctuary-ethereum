// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./IKYC.sol";

contract AKDEcommerce {
  address public superOwner;
  address public benefector;
  mapping(address => bool) public owners;
  uint256 public fee;
  IKYC public kyc;

  constructor(address _kycAddress) {
    superOwner = msg.sender;
    benefector = msg.sender;
    kyc = IKYC(_kycAddress);
  }

  struct Product {
    uint256 _productId;
    uint256 _price;
    address _seller;
    bytes _data;
    uint256[] bundleIds;
    uint8 rating;
    bytes review;
    uint256 storeId;
    bytes data;
  }
  struct Escrew {
    address _buyer;
    address _seller;
    uint256 _amount;
    bool isConfirmed;
    uint256 orderTime;
  }
  struct Store {
    address owner;
    string storeName;
    string storeType;
    uint256 storeId;
  }

  mapping(uint256 => Product) public orders;
  mapping(uint256 => Product) public pendingOrder;
  mapping(uint256 => Product) public cancelOrder;
  mapping(uint256 => Product) public completeOrder;
  mapping(uint256 => bool) public isOrderExist;
  mapping(uint256 => Escrew) public escrew;
  mapping(address => Store[]) public store;
  mapping(uint256 => address) public storeOf;

  event StoreCreated(address sender, string _storeName, string _storeType, uint256 _storeId);
  event AddProduct(uint256 _productId, uint256 _price, uint256 _orderNo, uint256 _storeId, string _productName, bytes datas);
  event AddMultiProduct(uint256[] _productId, uint256[] _prices, uint256[] _orderNo);
  event PurchaseProduct(uint256 _orderNo, address _seller, address _buyer, uint256 _amount);
  event BuyerConfimation(uint256 _orderNo, address sender, uint256 _amount);
  event BuyerReview(uint256 _orderNo, string _reviewMsg, uint8 _rating, address sender);
  event CancelProduct(uint256 _orderNo, address sender);
  event StoreDeleted(address _sender, uint256 _storeId);


  modifier onlySuperOwner() {
    require(msg.sender == superOwner, "ONLY_SUPER_OWNER");
    _;
  }
  modifier isWhitelistedSeller() {
    (bool status, string memory usertype) = kyc.checkStatus(msg.sender);
    //    keccak256(bytes(tokenType)) == keccak256(bytes("bnb")
    require(status && keccak256(bytes(usertype)) == keccak256(bytes("seller")), "NOT_WHITELIST_SELLER");
    _;
  }
  modifier isWhitelistedBuyer() {
    (bool status, string memory usertype) = kyc.checkStatus(msg.sender);
    require(status && keccak256(bytes(usertype)) == keccak256(bytes("buyer")), "NOT_WHITELIST_BUYER");
    _;
  }

  // Add new Owner to Contract
  function addOwner(address _newOwner) external onlySuperOwner {
    require(msg.sender != address(0), "ZERO_ADDRESS");
    owners[_newOwner] = true;
    // Emit Event
  }

  // Super Ownership change
  function renounceOwnership(address _newOwner) external onlySuperOwner {
    require(msg.sender != address(0), "ZERO_ADDRESS");
    superOwner = _newOwner;
    // Emit Event
  }

  // Add Fee of Ecommerce
  function addFee(uint256 _feePercent) external onlySuperOwner {
    require(_feePercent > 0 && _feePercent < 10000, "INVALID_FEE");
    fee = _feePercent;
    // Emit Event
  }

  function getFee(uint256 _amount) public view returns (uint256) {
    return (_amount * fee) / 10000;
  }

  // Add Single Product on Listing
  function addProduct(
    uint256 _productId,
    uint256 _price,
    uint256 _orderNo,
    uint256 _storeId,
    string calldata _productName
  ) external isWhitelistedSeller {
    require(!isOrderExist[_orderNo], "ORDER_EXIST");
    require(storeOf[_storeId] == msg.sender, "NOT_OWNER_STORE");
    orders[_orderNo]._productId = _productId;
    orders[_orderNo]._price = _price;
    orders[_orderNo]._seller = msg.sender;
    isOrderExist[_orderNo] = true;
    orders[_orderNo].storeId = _storeId;
    bytes memory data = abi.encode(msg.sender, _productName, _orderNo); // address  _foo, string calldata _bar, uint _amount
    orders[_orderNo].data = data;
    // Emit Event
    emit AddProduct(_productId, _price, _orderNo, _storeId, _productName, data);
  }

  // Add Multiple Product with Max 100 Product List at a time
  function addMultiproduct(
    uint256[] calldata _productId,
    uint256[] calldata _prices,
    uint256[] calldata _orderNo,
    string[] calldata _productName,
    uint256 _storeId
  ) external isWhitelistedSeller {
    require(_productId.length == _prices.length, "DIFFERENT_PARAMS");
    require(_productId.length == _prices.length, "DIFFERENT_PARAMS");
    require(_productId.length == _productName.length, "DIFFERENT_PARAMS");
    for (uint256 i = 0; i < _orderNo.length; i++) {
      require(storeOf[_storeId] == msg.sender, "NOT_STORE_OWNER");
      require(!isOrderExist[_orderNo[i]], "ORDER_EXIST");
      orders[_orderNo[i]]._productId = _productId[i];
      orders[_orderNo[i]]._price = _prices[i];
      orders[_orderNo[i]]._seller = msg.sender;
      isOrderExist[_orderNo[i]] = true;
      bytes memory data = abi.encode(msg.sender, _productName[i], _orderNo[i]); // address  _foo, string calldata _bar, uint _amount
      orders[_orderNo[i]].data = data;
    }
    // Emit Event
    emit AddMultiProduct(_productId, _prices, _orderNo);
  }

  // Add Products in the form of Bundle
  //   function addBundleProduct(
  //     uint256[] calldata _producIds,
  //     uint256 _price,
  //     uint256 _orderNo
  //   ) external isWhitelistedSeller {
  //     for (uint256 i = 0; i < _producIds.length; i++) {}
  //   }

  // Purchase Product That on Listing
  function purchaseProduct(uint256 _orderNo) external payable isWhitelistedBuyer {
    require(isOrderExist[_orderNo], "ORDER_EXIST");
    require(msg.value >= orders[_orderNo]._price, "NOT_ENOUGH_PAYMENT");
    //  console.log("order Price",orders[_orderNo]._price,msg.value);
    isOrderExist[_orderNo] = false;
    pendingOrder[_orderNo] = orders[_orderNo];
    escrew[_orderNo]._seller = orders[_orderNo]._seller;
    escrew[_orderNo]._buyer = msg.sender;
    escrew[_orderNo]._amount = msg.value;
    escrew[_orderNo].orderTime = block.timestamp;
    delete orders[_orderNo];
    // Emit Event
    emit PurchaseProduct(_orderNo, escrew[_orderNo]._seller, escrew[_orderNo]._buyer, escrew[_orderNo]._amount);
  }

  // Confirmation Of Product Received
  function buyerConfirmation(uint256 _orderNo) external isWhitelistedBuyer{
    require(escrew[_orderNo]._buyer == msg.sender , "ORDER_NOT_EXIST");
    require(escrew[_orderNo].isConfirmed == false, "ORDER_ALREADY_CONFIRMED");
    escrew[_orderNo].isConfirmed = true;
    completeOrder[_orderNo] = pendingOrder[_orderNo];
    // console.log("Amount in Esc",escrew[_orderNo]._amount, getFee(escrew[_orderNo]._amount),escrew[_orderNo]._amount - getFee(escrew[_orderNo]._amount));
    payable(escrew[_orderNo]._seller).transfer(escrew[_orderNo]._amount - getFee(escrew[_orderNo]._amount)); // Transfer price to seller
    payable(benefector).transfer(getFee(escrew[_orderNo]._amount)); // Benefactor Fee
    delete pendingOrder[_orderNo];
    // Event Emit
    emit BuyerConfimation(_orderNo, msg.sender, escrew[_orderNo]._amount);
  }

  // Buyer Review about Product
  function buyerReview(
    uint256 _orderNo,
    string calldata _reviewMsg,
    uint8 _rating
  ) external {
    require(escrew[_orderNo]._buyer == msg.sender, "ORDER_NOT_EXIST");
    require(escrew[_orderNo].isConfirmed == true, "ORDER_PENDING");
    require(_rating >= 0 && _rating <= 10, "INVALID_RATING");
    completeOrder[_orderNo].rating = _rating;
    completeOrder[_orderNo].review = abi.encode(_reviewMsg);
    // Event Emit
    emit BuyerReview(_orderNo, _reviewMsg, _rating, msg.sender);
  }
  // Listed Product Cancelled
  function cancelProduct(uint256 _orderNo) external payable isWhitelistedSeller {
    require(isOrderExist[_orderNo], "ORDER_NOT_EXIST");
    cancelOrder[_orderNo] = orders[_orderNo];
    delete orders[_orderNo];
    if (orders[_orderNo]._seller == msg.sender) {
      cancelOrder[_orderNo] = orders[_orderNo];
      delete orders[_orderNo];
    } else {
      require(pendingOrder[_orderNo]._seller == msg.sender, "ORDER_NOT_EXIST");
      require(msg.value >= panalty(pendingOrder[_orderNo]._price),"NOT_ENPOUGH_PANALTY");
      cancelOrder[_orderNo] = pendingOrder[_orderNo];
      payable(escrew[_orderNo]._buyer).transfer(escrew[_orderNo]._amount + panalty(pendingOrder[_orderNo]._price)); // Transfer price to seller
      delete pendingOrder[_orderNo];
    }
    isOrderExist[_orderNo] = false;
    emit CancelProduct(_orderNo, msg.sender);
  }
function createStore(
    string memory _storeName,
    uint256 _storeId,
    string memory _storeType
  ) external isWhitelistedSeller {
    require(storeOf[_storeId] == address(0), "STORE_EXIST");
    store[msg.sender].push(Store(msg.sender, _storeName, _storeType, _storeId));
    storeOf[_storeId] = msg.sender; 
    // Emit Event
    emit StoreCreated(msg.sender, _storeName, _storeType, _storeId);
  }

  function getStore() public view returns (Store[] memory) {
    return store[msg.sender];
  }
function deleteStore(uint256 _storeId) public isWhitelistedSeller{
    require( storeOf[_storeId] == msg.sender,"NOT_STORE_OWNER");
    storeOf[_storeId] = address(this);
    emit StoreDeleted(msg.sender, _storeId);
}

function canceledOrder(uint256 _orderNo)external isWhitelistedBuyer
{ // Cancel Order by Buyer after Send order
    require(escrew[_orderNo]._buyer == msg.sender,"INVALID_BUYER");
    if(block.timestamp > escrew[_orderNo].orderTime + 2000){
        escrew[_orderNo].isConfirmed = true;
        cancelOrder[_orderNo] = pendingOrder[_orderNo];
        payable(escrew[_orderNo]._buyer).transfer(escrew[_orderNo]._amount - panalty(escrew[_orderNo]._amount)); // Transfer price to seller
        payable(escrew[_orderNo]._seller).transfer(panalty(escrew[_orderNo]._amount)); // Benefactor Fee
        delete pendingOrder[_orderNo];
        // Event Emit
        emit BuyerConfimation(_orderNo, msg.sender, escrew[_orderNo]._amount);
      
    }else{
        escrew[_orderNo].isConfirmed = true;
        cancelOrder[_orderNo] = pendingOrder[_orderNo];
        payable(escrew[_orderNo]._buyer).transfer(escrew[_orderNo]._amount); // Transfer price to seller
        delete pendingOrder[_orderNo];
        // Event Emit
        emit BuyerConfimation(_orderNo, msg.sender, escrew[_orderNo]._amount);
    }
    }

    function panalty(uint256 amount) internal returns(uint256){
        return ((amount *5)/100);
        
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

interface IKYC {
  function addOwner(address _newOwner) external;

  function removeOwner(address _owner) external;

  function addUserWhitelisted(
    address _user,
    string calldata _userType,
    uint256 _expiry
  ) external;

  function removeWhitelisted(address _user) external;

  function checkStatus(address _user) external returns (bool, string calldata);

  function renounceOwnership(address _newSupperOwner) external;
}