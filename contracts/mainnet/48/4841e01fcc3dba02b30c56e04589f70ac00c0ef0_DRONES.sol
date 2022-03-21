///////////////////////////////////////////////////////////////////////////
//                                                                       //
//▄▄▄█████▓ ██▀███   ██▓ ██▓███   ██▓    ▓█████      ██████  ██▓▒██   ██▒//
//▓  ██▒ ▓▒▓██ ▒ ██▒▓██▒▓██░  ██▒▓██▒    ▓█   ▀    ▒██    ▒ ▓██▒▒▒ █ █ ▒░//
//▒ ▓██░ ▒░▓██ ░▄█ ▒▒██▒▓██░ ██▓▒▒██░    ▒███      ░ ▓██▄   ▒██▒░░  █   ░//
//░ ▓██▓ ░ ▒██▀▀█▄  ░██░▒██▄█▓▒ ▒▒██░    ▒▓█  ▄      ▒   ██▒░██░ ░ █ █ ▒ //
//  ▒██▒ ░ ░██▓ ▒██▒░██░▒██▒ ░  ░░██████▒░▒████▒   ▒██████▒▒░██░▒██▒ ▒██▒//
//  ▒ ░░   ░ ▒▓ ░▒▓░░▓  ▒▓▒░ ░  ░░ ▒░▓  ░░░ ▒░ ░   ▒ ▒▓▒ ▒ ░░▓  ▒▒ ░ ░▓ ░//
//    ░      ░▒ ░ ▒░ ▒ ░░▒ ░     ░ ░ ▒  ░ ░ ░  ░   ░ ░▒  ░ ░ ▒ ░░░   ░▒ ░//
//  ░        ░░   ░  ▒ ░░░         ░ ░      ░      ░  ░  ░   ▒ ░ ░    ░  //
//            ░      ░               ░  ░   ░  ░         ░   ░   ░    ░  //
//                                          SPDX-License-Identifier: MIT //
///////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract DRONES is ERC721A, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public maxSupply = 2999;
  uint256 public nftPerAddressLimit = 1;

  struct mintInfo {
    uint256 metalsHeld;
    uint256 tokenID;
  }

  bool public paused = true;
  bool public revealed = false;
  bool public pausedBurn = true;

  mapping(address => mintInfo) mintedTokenIDs;
  mapping(address => uint256) public addressMintedBalance;
  mapping(address => bool) public giveaway;
  mapping(address => bool) public hasMintedGW;

  bytes32 public merkleRoot;

  address[] mintedAddreses;
  uint256[] public silverMints;
  uint256[] public goldMints;

  address public constant LIQUID_METALS = 0xA49F31C7C90137e8d76FCf339E242e97B8f417D9;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(bytes32[] calldata _merkleProof) public {
    uint256 supply = totalSupply();
    uint256 balanceOfUser = ERC721A(LIQUID_METALS).balanceOf(msg.sender);

    require(!paused, "Public sale is paused.");
    require(isWhitelisted(msg.sender, _merkleProof), "User is not whitelisted.");
    require(tx.origin == msg.sender, "Origin doesnt match sender.");
    require(supply + 1 <= maxSupply, "Max supply reached");
    
    uint256 localnftPerAddressLimit = nftPerAddressLimit;
    uint256 senderMintCount = addressMintedBalance[msg.sender];

    if(balanceOfUser >= 15) {
      localnftPerAddressLimit = 2;
    }
    require(senderMintCount + 1 <= localnftPerAddressLimit, "Max NFT per address exceeded");

    _safeMint(msg.sender, 1);
    addressMintedBalance[msg.sender] += 1;

    if (senderMintCount == 0) {
      mintedTokenIDs[msg.sender] = mintInfo(balanceOfUser, supply);
      mintedAddreses.push(msg.sender);
    } else if (senderMintCount == 1) {
      goldMints.push(supply);
    }
  }

  function mintGiveaway() public {
    uint256 supply = totalSupply();
    require(!paused, "Public sale is paused.");
    require(giveaway[msg.sender], "You are not in the giveaway winner list.");
    require(!hasMintedGW[msg.sender], "Already minted the giveaway.");
    require(supply + 1 < maxSupply, "Max supply reached");
    require(tx.origin == msg.sender, "Origin doesn't match sender");

    _safeMint(msg.sender, 1);
    hasMintedGW[msg.sender] = true;
    silverMints.push(supply);
  }

  function mintAdmin(uint256 mintAmount) external onlyOwner {
    uint256 supply = totalSupply();
    require(supply + mintAmount < maxSupply, "Too many tokens.");
    _safeMint(msg.sender, mintAmount);
  }

  function burnToken(uint256 tokenId) public {
    require(!pausedBurn, "Burn is paused");
    _burn(tokenId);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function pauseBurn(bool _state) public onlyOwner {
    pausedBurn = _state;
  }

  function getMinters() public view returns (address[] memory minted) { return mintedAddreses; }
  function getSilvers() public view returns (uint256[] memory silvers) { return silverMints; }
  function getGolds() public view returns (uint256[] memory golds) { return goldMints; }
  
  function getMinterInfo(address _minter) public view returns (uint256 minterMetalsHeld, uint256 mintedTokenID){
    require(addressMintedBalance[_minter] >= 1, "ERROR: Address has not minted the NFT from the main sale.");
    mintInfo memory minterInfo = mintedTokenIDs[_minter];
    return (minterInfo.metalsHeld, minterInfo.tokenID);
  }

  function isWhitelisted(address _user, bytes32[] calldata _merkleProof) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(_user));
    return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function isGiveaway(address _user) public view returns (bool) {
    return giveaway[_user];
  }

  function addGiveaway(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      giveaway[addresses[i]] = true;
    }
  }
}