// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Proxy.sol";
import "./utils/RoyaltySplitter.sol";
import "./utils/Vault.sol";
import "./utils/IOwnable.sol";

interface INFT {
  function mint(
    uint256 tokenId,
    string calldata metadata,
    address user
  ) external;

  function mint(
    uint256 tokenId,
    uint256 amount,
    string calldata metadata,
    address user
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function ownerOf(uint256 tokenId) external view returns (address);

  function balanceOf(address account, uint256 id) external view returns (uint256);

  function initialize(string calldata _name, string calldata _symbol) external;

  function transferOwnership(address newOwner) external;
}

contract UnitLondonMarketplace is Vault, IOwnable {
  struct CollectionData {
    address artist;
    address splitter;
    uint32 mintFeePlatform;
    uint32 royaltyCollection;
    uint32 royaltyPlatform;
    uint32 logicIndex;
    string contractURI;
  }

  struct TokenData {
    uint256 price;
    uint256 amount;
    uint256 startDate;
    string metadata;
  }

  event CollectionRegistered(address collection, CollectionData data);
  event TokenUpdated(address collection, uint256 tokenId, TokenData data);
  event TokenSold(address collection, uint256 tokenId, uint256 amount, uint256 value);
  event TokenAirdropped(address collection, uint256 tokenId, address[] redeemers);
  event TokenRedeemed(address collection, uint256 tokenId, address[] redeemers, uint256[] prices);

  uint256 constant RATIO = 10000;

  address implementation_;
  address public override owner;
  bool public initialized;

  address[2] public logics;

  uint32 public mintFeePlatform;
  uint32 public royaltyPlatform;

  mapping(address => bool) public artists;

  mapping(address => CollectionData) public collections;
  mapping(address => mapping(uint256 => TokenData)) public tokens;

  function initialize(address[2] memory _logics) external onlyOwner {
    require(!initialized);
    initialized = true;

    logics = _logics;
    mintFeePlatform = 3000; // 30.00%
    royaltyPlatform = 200; // 2.00%

    emit OwnershipTransferred(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public virtual override {
    require(msg.sender == owner);
    owner = newOwner;
    emit OwnershipTransferred(msg.sender, newOwner);
  }

  function setMintFeePlatform(uint32 newMintFeePlatform) external onlyOwner {
    mintFeePlatform = newMintFeePlatform;
  }

  function setRoyaltyPlatform(uint32 newRoyaltyPlatform) external onlyOwner {
    royaltyPlatform = newRoyaltyPlatform;
  }

  function setLogic(uint256 index, address newLogic) external onlyOwner {
    logics[index] = newLogic;
  }

  function setArtists(address[] calldata _artists) external onlyOwner {
    for (uint256 i = 0; i < _artists.length; i++) {
      artists[_artists[i]] = true;
    }
  }

  function removeArtist(address artist) external onlyOwner {
    delete artists[artist];
  }

  function withdraw() external onlyOwner {
    payable(owner).transfer(address(this).balance);
  }

  function escapeTokens(address token, uint256 amount) external onlyOwner {
    INFT(token).transferFrom(address(this), owner, amount);
  }

  function escapeSafeTokens(
    address token,
    uint256 id,
    uint256 amount
  ) external onlyOwner {
    INFT(token).safeTransferFrom(address(this), owner, id, amount, "");
  }

  function registerCollection(
    uint32 logicIndex,
    string calldata name,
    string calldata symbol,
    address artist,
    uint32 royaltyArtist,
    string calldata contractURI
  ) external {
    require(owner == msg.sender || artist == msg.sender, "Invalid permission");
    require(artists[artist], "Invalid artist");
    Proxy proxy = new Proxy();
    proxy.setImplementation(logics[logicIndex]);

    address collection = address(proxy);
    CollectionData storage data = collections[collection];
    data.artist = artist;
    data.splitter = address(new RoyaltySplitter());
    data.mintFeePlatform = mintFeePlatform;
    data.royaltyCollection = royaltyArtist + royaltyPlatform;
    data.royaltyPlatform = royaltyPlatform;
    data.logicIndex = logicIndex;
    data.contractURI = contractURI;

    INFT(collection).initialize(name, symbol);
    INFT(collection).transferOwnership(artist);

    emit CollectionRegistered(collection, data);
  }

  function collectionURI(address collection) external view returns (string memory) {
    return collections[collection].contractURI;
  }

  function syncLogic(Proxy collection) external {
    collection.setImplementation(logics[collections[address(collection)].logicIndex]);
  }

  function registerManifold(
    uint32 logicIndex,
    address manifold,
    address artist,
    string calldata contractURI
  ) external {
    require(owner == msg.sender || artist == msg.sender, "Invalid permission");
    require(artists[artist], "Invalid artist");

    CollectionData storage data = collections[manifold];
    require(data.artist == address(0), "Invalid collection");
    data.artist = artist;
    data.logicIndex = logicIndex;
    data.mintFeePlatform = mintFeePlatform;
    data.contractURI = contractURI;

    emit CollectionRegistered(manifold, data);
  }

  function updateCollectionMintFeePlatform(
    address collection,
    uint256 newMintFeePlatform
  ) external {
    CollectionData storage data = collections[collection];

    require(owner == msg.sender, "Invalid permission");
    data.mintFeePlatform = uint32(newMintFeePlatform);
  }

  function addToken(
    address collection,
    uint256 tokenId,
    uint256 tokenLogic, // amount - 0 for 721, N for 1155
    uint256 price,
    uint256 startDate,
    string calldata metadata
  ) external {
    require(owner == msg.sender || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.price == 0, "Invalid token");

    if (collections[collection].splitter == address(0)) {
      // Manifolds
      if (tokenLogic == 0) {
        // ERC721
        require(INFT(collection).ownerOf(tokenId) == address(this), "Invalid owner");
      } else {
        // ERC1155
        require(INFT(collection).balanceOf(address(this), tokenId) == tokenLogic, "Invalid owner");
      }
    } else {
      data.metadata = metadata;
    }

    data.amount = tokenLogic;
    data.price = price;
    data.startDate = startDate;

    emit TokenUpdated(collection, tokenId, data);
  }

  function updateTokenPrice(
    address collection,
    uint256 tokenId,
    uint256 price
  ) external {
    require(owner == msg.sender || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.price > 0, "Invalid token");

    data.price = price;

    emit TokenUpdated(collection, tokenId, data);
  }

  function updateTokenStartDate(
    address collection,
    uint256 tokenId,
    uint256 startDate
  ) external {
    require(owner == msg.sender || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.startDate > 0, "Invalid token");

    data.startDate = startDate;

    emit TokenUpdated(collection, tokenId, data);
  }

  function updateTokenMetadata(
    address collection,
    uint256 tokenId,
    string calldata metadata
  ) external {
    require(owner == msg.sender || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];

    data.metadata = metadata;

    emit TokenUpdated(collection, tokenId, data);
  }

  function buy(
    address collection,
    uint256 tokenId,
    uint256 tokenLogic // amount - 0 for 721, N for 1155
  ) external payable {
    address user = msg.sender;
    uint256 value = msg.value;
    TokenData storage tokenData = tokens[collection][tokenId];

    CollectionData memory collectionData = collections[collection];
    uint256 fee = (value * collectionData.mintFeePlatform) / RATIO;
    payable(owner).transfer(fee);
    payable(collectionData.artist).transfer(value - fee);

    require(tokenData.price > 0, "Invalid token");
    require(tokenData.startDate < block.timestamp, "Invalid sale");
    if (tokenLogic == 0) {
      // ERC721
      require(tokenData.price == value, "Invalid price");

      if (collections[collection].splitter == address(0)) {
        // Manifolds
        INFT(collection).transferFrom(address(this), user, tokenId);
      } else {
        INFT(collection).mint(tokenId, tokenData.metadata, user);
      }
      tokenLogic = 1;
    } else {
      // ERC1155
      require(tokenData.price * tokenLogic == value, "Invalid price");

      if (collections[collection].splitter == address(0)) {
        // Manifolds
        INFT(collection).safeTransferFrom(address(this), user, tokenId, tokenLogic, "");
      } else {
        tokenData.amount = tokenData.amount - tokenLogic;
        INFT(collection).mint(tokenId, tokenLogic, tokenData.metadata, user);
      }
    }
    emit TokenSold(collection, tokenId, tokenLogic, value);
  }

  function airdrop(
    address collection,
    uint256 tokenId,
    address[] calldata redeemers
  ) external {
    // Only for ERC1155
    require(owner == msg.sender || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.price > 0, "Invalid token");

    // ERC1155
    uint256 tokenLogic = redeemers.length;
    data.amount = data.amount - tokenLogic;
    for (uint256 i = 0; i < tokenLogic; i++) {
      INFT(collection).mint(tokenId, 1, data.metadata, redeemers[i]);
    }
    emit TokenAirdropped(collection, tokenId, redeemers);
  }

  function redeem(
    address collection,
    uint256 tokenId,
    address[] calldata redeemers,
    uint256[] calldata prices
  ) external {
    // Only for ERC1155
    require(owner == msg.sender || collections[collection].artist == msg.sender, "Invalid artist");
    TokenData storage data = tokens[collection][tokenId];
    require(data.price > 0, "Invalid token");

    // ERC1155
    uint256 tokenLogic = redeemers.length;
    data.amount = data.amount - tokenLogic;
    for (uint256 i = 0; i < tokenLogic; i++) {
      INFT(collection).mint(tokenId, 1, data.metadata, redeemers[i]);
    }
    emit TokenRedeemed(collection, tokenId, redeemers, prices);
  }

  function royaltyInfo(
    address collection,
    uint256,
    uint256 value
  ) external view returns (address, uint256) {
    CollectionData memory data = collections[collection];
    return (data.splitter, (value * data.royaltyCollection) / RATIO);
  }

  function collectRoyalties(address collection, ICoin[] calldata coins) external {
    address artist = msg.sender;
    CollectionData memory data = collections[collection];
    require(data.artist == artist, "Invalid artist");
    (uint256 balance, uint256[] memory coinBalances) = RoyaltySplitter(payable(data.splitter)).claim(coins);

    uint256 royalties = balance;
    uint256 feePlatform = (royalties * data.royaltyPlatform) / data.royaltyCollection;
    payable(owner).transfer(feePlatform);
    payable(artist).transfer(royalties - feePlatform);

    for (uint256 i = 0; i < coinBalances.length; i++) {
      royalties = coinBalances[i];
      feePlatform = (royalties * data.royaltyPlatform) / data.royaltyCollection;
      coins[i].transfer(owner, feePlatform);
      coins[i].transfer(artist, royalties - feePlatform);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function owner() external view returns (address);

  function transferOwnership(address newOwner) external;

  // function renounceOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ProxyData.sol";

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
contract Proxy is ProxyData {
  receive() external payable {}

  function setImplementation(address newImpl) public {
    require(msg.sender == admin);
    implementation_ = newImpl;
  }

  function implementation() public view returns (address impl) {
    impl = implementation_;
  }

  /**
   * @dev Delegates the current call to `implementation`.
   *
   * This function does not return to its internall call site, it will return directly to the external caller.
   */
  function _delegate(address implementation__) internal virtual {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation__, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
   * and {_fallback} should delegate.
   */
  function _implementation() internal view returns (address) {
    return implementation_;
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external payable virtual {
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProxyData {
  address implementation_;
  address public admin;

  constructor() {
    admin = msg.sender;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoin {
  function balanceOf(address) external view returns (uint256);

  function transfer(address, uint256) external returns (bool);
}

contract RoyaltySplitter {
  address owner;

  constructor() {
    owner = msg.sender;
  }

  function claim(ICoin[] calldata coins) external returns (uint256 balance, uint256[] memory coinBalances) {
    require(owner == msg.sender);

    balance = address(this).balance;
    payable(owner).transfer(balance);

    uint256 coinCount = coins.length;
    coinBalances = new uint256[](coinCount);

    for (uint256 i = 0; i < coinCount; i++) {
      coinBalances[i] = coins[i].balanceOf(address(this));
      coins[i].transfer(owner, coinBalances[i]);
    }
  }

  fallback() external payable {}

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Vault {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0x150b7a02;
  }

  // Used by ERC721BasicToken.sol
  function onERC721Received(
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0xf0b9e5ba;
  }

  receive() external payable {}
}