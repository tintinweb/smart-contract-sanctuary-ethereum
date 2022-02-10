// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract DemonParty is ERC721, Ownable {
  //---------------------------------------------------------------
  //  CONSTANTS
  //---------------------------------------------------------------
  uint256 public constant MAX_SUPPLY = 6666;
  uint256 public constant NFT_PRICE = 0.001 ether;
  uint256 public constant WHITELIST_PRICE = 0.0005 ether;
  uint256 public saleStartBlock;
  uint256 public revealedAt;

  //---------------------------------------------------------------
  //  METADATA
  //---------------------------------------------------------------
  string public baseURI;
  string public coverURI;

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    if(block.number >= revealedAt) {
      return string(abi.encodePacked(baseURI, Strings.toString(id), ".json"));
    }

    return coverURI;
  }

  //---------------------------------------------------------------
  //  CONSTRUCTOR
  //---------------------------------------------------------------

  constructor(string memory _coverURI, uint256 _saleStartBlock) ERC721("DemonParty", "DEMONS") {
    coverURI = _coverURI;
    saleStartBlock = _saleStartBlock;
    factions = [ "F1", "F2", "F3", "F4", "F5" ];
  }

  function mint(uint256 amount) public payable {
    require(msg.value == (amount * NFT_PRICE), "wrong ETH amount");
    require(owners.length < MAX_SUPPLY, "SOLD_OUT");
    require(block.number >= saleStartBlock, "SALE_NOT_LIVE");
    require(minters[msg.sender] < 5, "ADDRESS_MAX_REACHED");
    for(uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender, owners.length);
    }
  }

  mapping (address => uint256) public minters;

  function burn(uint256 id) public {
    _burn(id);
  }

  /* name functions */
  mapping(uint256 => string) public tokenNames;

  function setName(uint256 id, string memory name) public {
    require(msg.sender == owners[id], "NOT_OWNER");
    tokenNames[id] = name;
  }

  string[5] private factions;
  mapping(uint256 => string) public tokenFactions;
  function setFaction(uint256 id, uint8 factionId) public {
    require(msg.sender == owners[id], "NOT_OWNER");
    require(factionId < factions.length, "INVALID_FACTION");
    tokenFactions[id] = factions[factionId];
  }

  //----------------------------------------------------------------
  //  WHITELISTS
  //----------------------------------------------------------------

  /// @dev - Merkle Tree root hash
  bytes32 public root;

  function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
    root = merkleroot;
  }

  function redeem(address account, bytes32[] calldata proof)
  external
  payable
  {
    // by requiring the account to be a valid leaf in the merkle tree
    // and passing in the same account arg here to _safeMint, that's how
    // we guarantee that the account is approved for minting
    require(_verify(_leaf(account), proof), "INVALID_MERKLE_PROOF");
    require(msg.value == (WHITELIST_PRICE), "WRONG_ETH_AMOUNT");
    require(owners.length < MAX_SUPPLY, "SOLD_OUT");
    require(minters[account] < 3, "ADDRESS_MAX_REACHED");
    _safeMint(account, owners.length);
  }

  function _leaf(address account)
  public pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
  public view returns (bool)
  {
    return MerkleProof.verify(proof, root, leaf);
  }

  // ADMIN FUNCTIONS //
  function setBaseUri(string memory uri) public onlyOwner {
    baseURI = uri;
  }
  function setSaleStartTime(uint256 _saleStartBlock) public onlyOwner {
    saleStartBlock = _saleStartBlock;
  }
  function setRevealedAt(uint256 _revealedAt) public onlyOwner {
    revealedAt = _revealedAt;
  }
  function withdraw(address to, uint256 amount) public onlyOwner {
    require(address(this).balance >= amount, "AMOUNT_TOO_HIGH");
    payable(to).transfer(amount);
  }
}