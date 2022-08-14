// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.0;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Exchange {
  uint256 constant RATE_DENOMINATOR = 2 ** 64;
  uint256 constant REFERRAL_FEE = 100;
  uint256 constant REFERRAL_FEE_DENOMINATOR = 10000;

  // Whether the order needs to be executed for the exact total amount of tokens offered, or can be partially consumed
  uint8 constant EXACT_ORDER = 0;
  uint8 constant PARTIAL_ORDER = 1;

  // Off-chain order representing a token sale (seller is the signer of the order)
  struct Order {
    address referrer;     // optional referrer field that takes a 1% of the amount paid in ETH
    address token;        // token being offered in this order
    uint128 rate;         // amount of tokens per eth sold (times RATE_DENOMINATOR)
    uint24 nonce;         // nonce for differentiating two otherwise identical orders
    uint256 amount;       // amount of tokens offered in this order
    uint8 orderType;      // type of order (see constants above)
  }

  // How much of the total amount of tokens of an order have been purchased so far (indexed by order hash)
  mapping(bytes32 => uint256) public amountExecutedPerOrder;

  // Executes an order purchasing however many tokens correspond to the msg.value sent based on the order rate
  function executeOrder(Order calldata order, uint8 v, bytes32 r, bytes32 s) external payable {
    uint256 tokensPurchased = msg.value * order.rate / RATE_DENOMINATOR;
    uint256 fee = order.referrer != address(0) ? (msg.value * REFERRAL_FEE / REFERRAL_FEE_DENOMINATOR) : 0;
    bytes32 orderHash = getOrderHash(order);
    address seller = ecrecover(orderHash, v, r, s);
    
    require(msg.value > 0, "Payment required");
    require(seller != address(0), "Wrong signature");
    require(order.orderType == EXACT_ORDER ? tokensPurchased == order.amount : true, "Cannot take partial amount");
    require(tokensPurchased <= order.amount + amountExecutedPerOrder[orderHash], "Amount purchased exceeds order");

    amountExecutedPerOrder[orderHash] += tokensPurchased;

    IERC20(order.token).transferFrom(seller, msg.sender, tokensPurchased);
    if (fee > 0) payable(order.referrer).transfer(fee);
    payable(seller).transfer(msg.value - fee);
  }

  // Gets the hash of an order (used as its identifier)
  function getOrderHash(Order memory order) public view returns (bytes32) {
    return keccak256(abi.encodePacked(
      order.referrer,
      order.token,
      order.rate,
      order.nonce,
      address(this), // include address of this contract to prevent replay attacks
      order.amount,
      order.orderType
    ));
  }
}