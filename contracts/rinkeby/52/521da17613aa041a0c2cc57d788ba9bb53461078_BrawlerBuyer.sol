/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity ^0.5.17;

interface ERC20Interface {
  function allowance(address tokenOwner, address spender)
    external
    view
    returns (uint256 remaining);

  function transfer(address to, uint256 tokens) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) external returns (bool success);
}

interface Proxy {
    function postOutgoingMessage(
        bytes32 targetChainHash,
        address targetContract,
        bytes calldata data
    ) external;
}

// @title BrawlerBuyer
// @dev handles purchase of brawlers on mainnet Ethereum
// @author Block Brawlers (https://www.blockbrawlers.com)
// (c) 2022 Block Brawlers LLC. All Rights Reserved. This code is not open source.
contract BrawlerBuyer {
  address public gameplayContract;
  address public owner;
  address payable public recipient;

  Proxy public proxy; // Rinkeby address
  bytes32 public targetChainHash;
  address public targetContract;

  ERC20Interface[7] currencies;
  uint256[7] prices;
  uint256[7] limits;

  mapping(address => mapping(uint256 => uint256)) userPurchased;
  uint256[7] totalPurchased;

  event Purchase(
    uint256 packType,
    address sender,
    address currency,
    uint256 price,
    uint256 timestamp
  );

  constructor() public {
    owner = msg.sender;
    recipient = msg.sender;

    // 5000 @ 0.08 eth
    limits[1] = 5000;
    prices[1] = 8 * 10 ** 16;
    // 1500 @ 0.2 eth
    limits[2] = 1500;
    prices[2] = 2 * 10 ** 17;
    // 300 @ 1 eth
    limits[3] = 300;
    prices[3] = 10 ** 18;
    // 5000 @ 1000 SKL
    limits[4] = 5000;
    prices[4] = 1000;
    currencies[4] = ERC20Interface(0x00c83aeCC790e8a4453e5dD3B0B4b3680501a7A7); // SKALE
    // 1500 @ 5000 SKL
    limits[5] = 1500;
    prices[5] = 5000;
    currencies[5] = ERC20Interface(0x00c83aeCC790e8a4453e5dD3B0B4b3680501a7A7); // SKALE
    // 5000 @ 2000 GAME
    limits[6] = 5000;
    prices[6] = 2000 * 10 ** 18;
    currencies[6] = ERC20Interface(0x63f88A2298a5c4AEE3c216Aa6D926B184a4b2437); // GAME
  }

  // @dev Access modifier for Owner-only functionality
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == recipient, "onlyOwner");
    _;
  }

  // Pack #0 will always show as 0; it doesn't exist.
  function getPacks()
    external
    view
    returns (
      address[7] memory currency,
      uint256[7] memory price,
      uint256[7] memory limit,
      uint256[7] memory purchased
    )
  {
    for (uint256 i = 1; i < 7; i++) {
      currency[i] = address(currencies[i]);
      limit[i] = limits[i];
      price[i] = prices[i];
      purchased[i] = totalPurchased[i];
    }
  }

  // Pack #0 will always show as 0; it doesn't exist.
  function getPacksForUser(address user)
    external
    view
    returns (
      address[7] memory currency,
      uint256[7] memory price,
      uint256[7] memory limit,
      uint256[7] memory purchased,
      uint256[7] memory approvals,
      uint256[7] memory hasBought
    )
  {
    for (uint256 i = 1; i < 7; i++) {
      currency[i] = address(currencies[i]);
      limit[i] = limits[i];
      price[i] = prices[i];
      purchased[i] = totalPurchased[i];
      approvals[i] = address(currencies[i]) == address(0)
        ? 2**256 - 1
        : currencies[i].allowance(user, address(this));
      hasBought[i] = userPurchased[user][i];
    }
  }

  function setProxyInfo(address _proxy, address _targetContract, string calldata _targetChain)
    external
    onlyOwner
  {
      proxy = Proxy(_proxy);
      targetContract = _targetContract;
      targetChainHash = keccak256(abi.encodePacked(_targetChain));
  }

  function setRecipient(address recipient_) external onlyOwner {
    recipient = address(uint160(recipient_));
  }

  function setPackLimits(
    uint256 pack,
    address currency,
    uint256 limit,
    uint256 price
  ) external onlyOwner {
    require(pack >= 1 && pack <= 6, "valid packs are 1 to 6, inclusive");
    limits[pack] = limit;
    prices[pack] = price;
    currencies[pack] = ERC20Interface(currency);
  }

  function withdrawBalance(uint256 amount) external onlyOwner {
    msg.sender.transfer(amount);
  }

  function buyBrawlers(uint256 packType) public payable {
    require(tx.origin == msg.sender, "safety; must buy from an EOA");
    require(
      packType >= 1 && packType <= 6,
      "valid packs are 1 to 6, inclusive"
    );
    require(
      userPurchased[msg.sender][packType] == 0,
      "user must not have pack"
    );
    uint256 price = prices[packType];
    require(price > 0, "price must be non zero");

    uint256 limit = limits[packType];
    uint256 purchased = totalPurchased[packType];
    require(purchased < limit, "buy limit reached");

    ERC20Interface currency = currencies[packType];
    if (address(currency) == address(0)) {
      require(msg.value == price, "eth purchase, must send price in value");
    } else {
      bool isSuccess = currency.transferFrom(msg.sender, recipient, price);
      require(isSuccess, "transfer must have happened");
    }

    emit Purchase(
      packType,
      msg.sender,
      address(currency),
      price,
      block.timestamp
    );

    userPurchased[msg.sender][packType] = block.timestamp;
    totalPurchased[packType] = purchased + 1;
    proxy.postOutgoingMessage(targetChainHash, targetContract, abi.encode(msg.sender, packType));
  }

  function testPost(uint256 packType) external {
    proxy.postOutgoingMessage(targetChainHash, targetContract, abi.encode(msg.sender, packType));
  }

  // @dev Do not allow ETH to be sent here
  function() external payable {
    require(false, "not payable");
  }
}