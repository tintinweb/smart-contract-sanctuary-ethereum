// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/SimpleERC721.sol";

contract MembershipNFT is SimpleERC721 {
  struct Tier {
    string name;
    uint256 ticker;
    uint256 salePrice;
  }

  uint256 constant TIER_SPACE = 1_000_000;

  bool public initialized;

  mapping(address => bool) public agents;
  string public baseURI;
  Tier[3] public tiers;
  uint256 public MAX_SUPPLY;

  function initialize(
    string calldata _name,
    string calldata _symbol,
    string calldata _baseURI,
    string[] calldata _tiers,
    uint256[] calldata supplies
  ) external onlyOwner {
    require(!initialized);
    initialized = true;

    name = _name;
    symbol = _symbol;
    baseURI = _baseURI;

    tiers[0].name = _tiers[0];
    tiers[1].name = _tiers[1];
    tiers[2].name = _tiers[2];

    MAX_SUPPLY = (supplies[2] << 128) | (supplies[1] << 64) | supplies[0];

    agents[msg.sender] = true;
  }

  function setAgents(address[] calldata _agents, bool isAgent) external onlyOwner {
    uint256 count = _agents.length;
    if (isAgent) {
      for (uint256 i = 0; i < count; i++) {
        agents[_agents[i]] = isAgent;
      }
    } else {
      for (uint256 i = 0; i < count; i++) {
        delete agents[_agents[i]];
      }
    }
  }

  function setSalePrices(uint256[3] calldata prices) external onlyOwner {
    tiers[0].salePrice = prices[0];
    tiers[1].salePrice = prices[1];
    tiers[2].salePrice = prices[2];
  }

  function setBaseURI(string calldata _baseURI) external onlyOwner {
    baseURI = _baseURI;
  }

  function distribute(uint256 _tier, address[] calldata users) external {
    uint256 amount = users.length;
    require(agents[msg.sender], "Invalid role");

    Tier storage tier = tiers[_tier];
    uint256 maxSupply = uint64(MAX_SUPPLY >> (64 * _tier));
    uint256 start = tier.ticker;
    uint256 newSupply = start + amount;
    require(newSupply <= maxSupply, "Invalid amount");

    tier.ticker = newSupply;
    start = (_tier * TIER_SPACE) + start + 1;
    for (uint256 i = 0; i < amount; i++) {
      _mint(users[i], start + i);
    }
  }

  function mint(uint256 _tier, uint256 amount) external payable {
    address user = msg.sender;

    Tier storage tier = tiers[_tier];
    require(tier.salePrice > 0, "Invalid state");
    require(tier.salePrice * amount <= msg.value, "Invalid price");

    uint256 maxSupply = uint64(MAX_SUPPLY >> (64 * _tier));
    uint256 start = tier.ticker;
    uint256 newSupply = start + amount;
    require(newSupply <= maxSupply, "Invalid amount");

    tier.ticker = newSupply;
    start = (_tier * TIER_SPACE) + start + 1;
    for (uint256 i = 0; i < amount; i++) {
      _mint(user, start + i);
    }
  }

  function totalSupply() external view returns (uint256) {
    return tiers[0].ticker + tiers[1].ticker + tiers[2].ticker;
  }

  function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    require(ownerOf[tokenId] != address(0));

    uint256 tier = tokenId / TIER_SPACE;
    return string(abi.encodePacked(baseURI, tiers[tier].name));
  }

  function withdraw() external onlyOwner {
    payable(admin).transfer(address(this).balance);
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  address implementation_;
  address public admin;

  string public name;
  string public symbol;

  mapping(address => uint256) public balanceOf;
  mapping(uint256 => address) public ownerOf;
  mapping(uint256 => address) public getApproved;
  mapping(address => mapping(address => bool)) public isApprovedForAll;

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function owner() external view returns (address) {
    return admin;
  }

  function transfer(address to, uint256 tokenId) external {
    require(msg.sender == ownerOf[tokenId], "NOT_OWNER");
    _transfer(msg.sender, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
    supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
  }

  function approve(address spender, uint256 tokenId) external {
    address owner_ = ownerOf[tokenId];
    require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");
    getApproved[tokenId] = spender;
    emit Approval(owner_, spender, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external {
    isApprovedForAll[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender], "NOT_APPROVED");
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0) {
      (, bytes memory returned) = to.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from, tokenId, data));
      bytes4 selector = abi.decode(returned, (bytes4));
      require(selector == 0x150b7a02, "NOT_ERC721_RECEIVER");
    }
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf[tokenId] == from);
    _beforeTokenTransfer(from, to, tokenId);

    balanceOf[from]--;
    balanceOf[to]++;

    delete getApproved[tokenId];

    ownerOf[tokenId] = to;
    emit Transfer(msg.sender, to, tokenId);
    _afterTokenTransfer(from, to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal {
    require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");

    unchecked {
      balanceOf[to]++;
    }

    ownerOf[tokenId] = to;

    emit Transfer(address(0), to, tokenId);
    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner_ = ownerOf[tokenId];

    require(owner_ != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner_, address(0), tokenId);

    balanceOf[owner_]--;

    delete ownerOf[tokenId];

    emit Transfer(owner_, address(0), tokenId);
    _afterTokenTransfer(owner_, address(0), tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}