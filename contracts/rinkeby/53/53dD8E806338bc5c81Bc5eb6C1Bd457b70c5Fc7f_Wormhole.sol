/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: contracts/Owner.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

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
    constructor() public {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface ERC20 {
    function totalSupply() external returns (uint256);

    function balanceOf(address tokenOwner) external returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

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

// File: contracts/Wormhole.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;


contract Wormhole is Owner {
  enum Status {
    SUBMITTED,
    DEPOSITED,
    WITHDRAWED
  }

  struct Order {
    address user;
    uint256 txIndex;
    uint256 fromChainId;
    address fromToken;
    uint256 fromAmount;
    uint256 toChainId;
    address toToken;
    uint256 toAmount;
    uint256 createdAt;
    string depositTxHash;
    string withdrawTxHash;
    Status status;
  }

  event CashOut(
    address user,
    uint256 txIndex,
    uint256 fromAmount,
    uint256 toChainId,
    address toToken
  );

  event CashIn(
    address user,
    uint256 txIndex,
    address fromToken,
    uint256 fromAmount,
    uint256 toChainId
  );

  address owner;
  string constant NULL = "0x0";
  uint256 constant ZERO = 0;
  address constant NATIVE = address(0x0);
  mapping(address => Order[]) booking;

  function cashOut(uint256 toChainId, address toToken)
    public
    payable
    returns (Order memory)
  {
    address user = msg.sender;
    uint256 txIndex = booking[user].length;
    uint256 fromChainId;

    assembly {
      fromChainId := chainid()
    }

    address fromToken = NATIVE;
    uint256 fromAmount = msg.value;
    uint256 toAmount = ZERO;
    uint256 createdAt = now;

    booking[user].push(
      Order(
        user,
        txIndex,
        fromChainId,
        fromToken,
        fromAmount,
        toChainId,
        toToken,
        toAmount,
        createdAt,
        NULL,
        NULL,
        Status.SUBMITTED
      )
    );

    emit CashOut(user, txIndex, fromAmount, toChainId, toToken);
    return booking[user][txIndex];
  }

  function cashIn(
    address fromToken,
    uint256 fromAmount,
    uint256 toChainId
  ) public {
    require(fromAmount > 0, "You need to sell at least some tokens");

    address user = msg.sender;
    uint256 allowance = ERC20(fromToken).allowance(user, address(this));

    require(allowance >= fromAmount, "Check the token allowance");
    ERC20(fromToken).transferFrom(user, address(this), fromAmount);

    uint256 txIndex = booking[user].length;
    uint256 fromChainId;
    uint256 createdAt = now;

    assembly {
      fromChainId := chainid()
    }

    booking[user].push(
      Order(
        user,
        txIndex,
        fromChainId,
        fromToken,
        fromAmount,
        toChainId,
        NATIVE,
        ZERO,
        createdAt,
        NULL,
        NULL,
        Status.SUBMITTED
      )
    );

    emit CashIn(user, txIndex, fromToken, fromAmount, toChainId);
  }

  function withdrawToken(
    address user,
    address token,
    uint256 amount
  ) public isOwner {
    ERC20(token).transfer(user, amount);
  }

  function withdrawCoin(address payable user, uint256 amount) public isOwner {
    user.transfer(amount);
  }

  function listUserOrders(address user) public view returns (Order[] memory) {
    return booking[user];
  }

  function readUserOrder(address user, uint256 txIndex)
    public
    view
    returns (Order memory)
  {
    return booking[user][txIndex];
  }

  function updateUserOrderDepositTxHash(
    address user,
    uint256 txIndex,
    bytes32 depositTxHash
  ) public view isOwner returns (Order memory) {
    Order memory order = booking[user][txIndex];
    order.depositTxHash = bytes32ToString(depositTxHash);
    order.status = Status.DEPOSITED;
    return order;
  }

  function updateUserOrderWithdrawTxHash(
    address user,
    uint256 txIndex,
    uint256 toAmount,
    bytes32 withdrawTxHash
  ) public view isOwner returns (Order memory) {
    Order memory order = booking[user][txIndex];
    order.toAmount = toAmount;
    order.withdrawTxHash = bytes32ToString(withdrawTxHash);
    order.status = Status.WITHDRAWED;
    return order;
  }

  function bytes32ToString(bytes32 _bytes32)
    public
    pure
    returns (string memory)
  {
    uint8 i = 0;
    while (i < 32 && _bytes32[i] != 0) {
      i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
      bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  receive() external payable {
    // Receive Native Token (Coin)
  }

  fallback() external payable {
    // Fallback
  }
}