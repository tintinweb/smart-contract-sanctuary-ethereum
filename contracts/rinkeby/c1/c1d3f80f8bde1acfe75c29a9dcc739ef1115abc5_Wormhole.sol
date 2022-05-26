/**
 *Submitted for verification at Etherscan.io on 2022-05-26
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
    uint256 exchangeRate;
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
  string constant NULL_TX = "0x0";
  uint256 constant NULL_AMOUNT = 0;
  address constant NATIVE = address(0x0);
  mapping(address => Order[]) booking;

  function cashOut(uint256 toChainId, address toToken)
    public
    payable
    returns (Order memory)
  {
    address user = msg.sender;
    uint256 txIndex = booking[user].length;
    uint256 fromAmount = msg.value;
    uint256 fromChainId;

    assembly {
      fromChainId := chainid()
    }

    booking[user].push(
      Order(
        user,
        txIndex,
        fromChainId,
        NATIVE, //fromToken
        fromAmount,
        toChainId,
        toToken,
        NULL_AMOUNT, //toAmount
        NULL_AMOUNT, //exchangeRate
        block.timestamp, //createdAt
        NULL_TX, // depositTxHash
        NULL_TX, // withdrawTxHash
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
        NATIVE, // toToken
        NULL_AMOUNT, // toAmount
        NULL_AMOUNT, // exchangeRate
        block.timestamp, // createdAt
        NULL_TX, // depositTxHash
        NULL_TX, // withdrawTxHash
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

  function completeUserOrder(
    address user,
    uint256 txIndex,
    uint256 toAmount,
    uint256 exchangeRate,
    string memory depositTxHash,
    string memory withdrawTxHash
  ) public payable isOwner returns (Order memory) {
    booking[user][txIndex].toAmount = toAmount;
    booking[user][txIndex].exchangeRate = exchangeRate;
    booking[user][txIndex].depositTxHash = depositTxHash;
    booking[user][txIndex].withdrawTxHash = withdrawTxHash;
    booking[user][txIndex].status = Status.WITHDRAWED;
    return booking[user][txIndex];
  }

  function transferToken(address token, uint256 amount) public isOwner {
    ERC20(token).transfer(msg.sender, amount);
  }

  function transferCoin(uint256 amount) public isOwner {
    msg.sender.transfer(amount);
  }

  receive() external payable {
    // Receive Native Token (Coin)
  }

  fallback() external payable {
    // Fallback
  }
}