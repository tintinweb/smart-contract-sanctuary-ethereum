/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// File: contracts/Owner.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
  address private owner;

  // event for EVM logging
  event OwnerSet(address indexed oldOwner, address indexed newOwner);

  // modifier to check if caller is owner
  modifier isOwner() {
    // If the first argument of 'require' evaluates to 'false', execution terminates and all
    // changes to the state and to Ether balances are reverted.
    // This used to consume all gas in old EVM versions, but not anymore.
    // It is often a good idea to use 'require' to check if functions are called correctly.
    // As a second argument, you can also provide an explanation about what went wrong.
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  /**
   * @dev Set contract deployer as owner
   */
  constructor() {
    owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    emit OwnerSet(address(0), owner);
  }

  /**
   * @dev Change owner
   * @param newOwner address of new owner
   */
  function changeOwner(address newOwner) public isOwner {
    emit OwnerSet(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Return owner address
   * @return address of owner
   */
  function getOwner() external view returns (address) {
    return owner;
  }
}

// File: contracts/ERC20.sol



pragma solidity >=0.8.14;

interface ERC20 {
  function totalSupply() external returns (uint256);

  function balanceOf(address tokenOwner) external returns (uint256 balance);

  function allowance(address tokenOwner, address spender)
    external
    returns (uint256 remaining);

  function transfer(address to, uint256 tokens) external returns (bool success);

  function approve(address spender, uint256 tokens)
    external
    returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) external returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint256 tokens
  );
}

// File: contracts/PaymentGatewayToken.sol


pragma solidity >=0.8.14;


contract PaymentGatewayToken is Owner {
  enum Status {
    UN_PAIDED,
    PAIDED
  }

  struct Order {
    string orderId;
    address user;
    uint256 amount;
    string merchantId;
    Status status;
    uint256 createdAt;
  }

  struct Withdraw {
    bytes32 wHash;
    address callBy;
    uint256 amount;
    address recipient;
    uint256 createdAt;
  }

  event OrderEvent(
    string orderId,
    address user,
    uint256 amount,
    string merchantId,
    Status status,
    uint256 createdAt
  );

  event WithdrawEvent(
    bytes32 wHash,
    address callBy,
    uint256 amount,
    address recipient,
    uint256 createdAt
  );

  string public name;
  address public vndtToken;
  uint256 public totalAmount;
  uint256 public totalWithdrawAmount;

  string[] orderIds;
  bytes32[] withdrawHashs;

  mapping(string => Order) public orders;
  mapping(bytes32 => Withdraw) public withdraws;

  constructor(
    string memory _name,
    address _vndtToken,
    address _owner
  ) {
    name = _name;
    vndtToken = _vndtToken;
    changeOwner(_owner);
  }

  function pay(
    uint256 amount,
    string memory orderId,
    string memory merchantId
  ) public {
    // Validate
    address user = msg.sender;
    uint256 allowance = ERC20(vndtToken).allowance(user, address(this));
    require(allowance >= amount, "Please check VNDT Token allowance");

    Order storage order = orders[orderId];
    require(order.status != Status.PAIDED, "Order already paid");

    // Process
    ERC20(vndtToken).transferFrom(user, address(this), amount);
    totalAmount = totalAmount + amount;

    Order memory record = Order(
      orderId,
      user,
      amount,
      merchantId,
      Status.PAIDED,
      block.timestamp
    );

    orders[orderId] = record;
    orderIds.push(orderId);

    // Event
    emit OrderEvent(
      record.orderId,
      record.user,
      record.amount,
      record.merchantId,
      record.status,
      record.createdAt
    );
  }

  function withdraw(uint256 amount, address payable recipient) public isOwner {
    // Validate
    require(
      ERC20(vndtToken).balanceOf(address(this)) >= amount,
      "Balance not enough"
    );

    // Process
    bytes32 wHash = keccak256(
      abi.encodePacked(msg.sender, amount, recipient, block.timestamp)
    );

    Withdraw memory record = Withdraw(
      wHash,
      msg.sender,
      amount,
      recipient,
      block.timestamp
    );

    withdraws[wHash] = record;
    withdrawHashs.push(wHash);
    ERC20(vndtToken).transfer(recipient, amount);
    totalWithdrawAmount = totalWithdrawAmount + amount;

    // Event
    emit WithdrawEvent(
      record.wHash,
      record.callBy,
      record.amount,
      record.recipient,
      record.createdAt
    );
  }

  function getOrders() public view returns (Order[] memory) {
    Order[] memory records = new Order[](orderIds.length);
    for (uint256 i = 0; i < orderIds.length; i++) {
      records[i] = orders[orderIds[i]];
    }
    return records;
  }

  function getWithdraws() public view returns (Withdraw[] memory) {
    Withdraw[] memory records = new Withdraw[](withdrawHashs.length);
    for (uint256 i = 0; i < withdrawHashs.length; i++) {
      records[i] = withdraws[withdrawHashs[i]];
    }
    return records;
  }

  function totalOrders() public view returns (uint256) {
    return orderIds.length;
  }

  function totalWithdraws() public view returns (uint256) {
    return withdrawHashs.length;
  }
}