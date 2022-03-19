// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Halffin {
  address public factory;

  Product public product;
  struct Product {
    uint256 id;
    string name;
    string description;
    uint256 price;
  }

  uint256 public fee;
  address public seller;
  address public buyer;
  Status public status;

  enum Status {
    Available,
    WaitForShipment,
    Shipping,
    Completed
  }

  event OrderInitiate(address indexed _buyer);

  constructor(
    uint256 _id,
    string memory _name,
    string memory _description,
    uint256 _price,
    address _factory
  ) {
    product = Product(_id, _name, _description, _price);
    seller = msg.sender;
    status = Status.Available;
    fee = (_price * 3) / 100; // fee = 3% of the price
    factory = _factory;
  }

  modifier onlySeller() {
    require(msg.sender == seller);
    _;
  }

  modifier onlyBuyer() {
    require(msg.sender == buyer);
    _;
  }

  function buyProduct() external payable {
    require(msg.sender != seller, 'Cannot buy your own product!');
    require(msg.value == product.price, 'Not enough ethers!');
    buyer = msg.sender;
    status = Status.WaitForShipment;
    emit OrderInitiate(buyer);
  }

  function updateShipment(uint256 _trackingId) external onlySeller {
    // check with aftership
    // requestForShipment

    // dummy tracking id
    if (_trackingId == 1) {
      status = Status.Shipping;
    }
    if (_trackingId == 2) {
      status = Status.WaitForShipment;
    }
  }

  // function fulfillShipmentRequest(uint256 requestId, bytes32 shipmentStatus) internal override {

  // if success -> status = Status.Completed;
  // }

  // once buyer receive product, claimProduct transfer the money to the seller
  function claimProduct() external onlyBuyer {
    require(status == Status.Completed, 'Cannot claim the incompleted product');

    payable(seller).transfer(address(this).balance - fee);
    payable(factory).transfer(fee);
  }
}