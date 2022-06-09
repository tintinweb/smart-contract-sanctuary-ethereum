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

pragma solidity ^0.8.4;

import './Ownable.sol';
import './ERC721A.sol';
import './MerkleProof.sol';

interface IBurnable {
  function isApprovedForAll(address owner, address operator) external view returns(bool);
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IRugBurn {
  function balanceOf(address owner) external view returns(uint256);
}

contract ASCENSION is ERC721A, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;

  uint256 public maxSupply = 6666;
  uint256 public mintStartTime;
  uint256 public mintStopTime;

  struct phaseData {
    bytes32 merkleRoot;
    uint256 price;
  }

  struct mintData {
    address minter;
    bool rugburn;
    uint itemsMintedInTX;
  }

  bool public paused = true;
  bool public pausedBurn = true;
  bool public revealed = false;

  //mapping(address => bool) public addressClaimed;
  //mapping(address => bool) public addressClaimedWL;
  mapping(address => uint) public addressClaimedAmt;
  mapping(address => uint) public addressClaimedAmtPublic;

  mapping(address => uint[]) public burnedMetalIDs;
  mapping(address => uint[]) public burnedDroneIDs;

  mapping(uint256 => phaseData) public phaseInfo;
  mapping(uint256 => mintData) public tokenMinter;

  IBurnable public liquidMetals = IBurnable(0xA49F31C7C90137e8d76FCf339E242e97B8f417D9);
  IBurnable public drones = IBurnable(0x4841e01fCC3dBa02b30C56E04589F70aC00C0eF0);
  IRugBurn public rugburn = IRugBurn(0xA17F63Bcd85Fd3B01C5996Da0327f84c6AE86a82);

  // Adding this modifier to a function will ensure the function can only be executed before the mint is started
  modifier beforeSale {
    require(mintStartTime == 0, "Sale has started");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    ////// PHASE PRICING SETTINGS
    /// @dev Molten holders will be airdropped due to there being <10 tokens
    phaseInfo[1].price = 0.01 ether;  // DIAMOND
    phaseInfo[2].price = 0.025 ether;  // GOLD
    phaseInfo[3].price = 0.035 ether;  // SILVER
    phaseInfo[4].price = 0.055 ether;  // WL
    phaseInfo[5].price = 0.065 ether;  // PUBLIC
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // external / public
  /// @notice               Burns a Liquid Metal NFT and saves the burned token to the users data
  /// @param _metalTokenID  TokenID for the Liquid Metal
  function burnMetal(uint _metalTokenID) public beforeSale {
    require(liquidMetals.isApprovedForAll(msg.sender, address(this)), "Contract not approved");
    liquidMetals.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _metalTokenID);
    burnedMetalIDs[msg.sender].push(_metalTokenID);
  }

  /// @notice               Burns a Drone NFT and saves the burned token to the users data
  /// @param _droneTokenID  TokenID for the Drone
  function burnDrone(uint _droneTokenID) public beforeSale {
    require(drones.isApprovedForAll(msg.sender, address(this)), "Contract not approved");
    drones.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _droneTokenID);
    burnedDroneIDs[msg.sender].push(_droneTokenID);
  }

  /// @notice                 Retrieves the current whitelist phase
  function getCurrentPhase() public view returns (uint) {
    uint phase;
    // If the mint hasn't started or the contract is paused it will always return 0
    if (mintStartTime == 0 || paused) return 0;
    if (block.timestamp > mintStartTime + 48 hours) {
      phase = 5;
    } else if (block.timestamp > mintStartTime + 36 hours) {
      phase = 4;
    } else if (block.timestamp > mintStartTime + 24 hours) {
      phase = 3;
    } else if (block.timestamp > mintStartTime + 12 hours) {
      phase = 2;
    } else if (block.timestamp >= mintStartTime) {
      phase = 1;
    } else {
      phase = 0;
    }
    return phase;
  }

  /// @notice                 Gets the phase for the user
  /// @param _address         Address of the user
  /// @param _merkleProof     The users merkle proof
  function getUserPhase(address _address, bytes32[] calldata _merkleProof) public view returns (uint) {
    /// @dev Counts from 4 to 1 (inclusive) in case the user is whitelisted for several phases
    /// @dev The last iteration that returns 'true' needs to be the lowest (cheapest) phase the user is whitelisted for
    /// @dev Its safe to use 'unchecked' as we are iterating within a fixed known range
    uint userPhase;
    unchecked {
      for (uint i = 4; i > 0; --i) {
        bool status = isWhitelisted(_address, _merkleProof, i); 
        if (status) userPhase = i;
      }
    }
    return userPhase;
  }

  /// @notice                 Mint function for whitelisted users
  /// @param _merkleProof     Merkle proof of the caller (empty [] for non-whitelisted)
  /// @param _mintAmount      Amount to be minted
  /// @param _rugburnTrait    Optional parameter to qualify for a rugburn trait
  function mint(bytes32[] calldata _merkleProof, uint _mintAmount, bool _rugburnTrait) external payable {
    require(!paused, "Sale is paused");
    require(tx.origin == msg.sender, "Sender not origin");

    uint supply = totalSupply();
    uint currentPhase = getCurrentPhase();
    uint userPhase;
    uint perWalletLimit = 3;
    uint userClaimedIndex = addressClaimedAmt[msg.sender];

    require(supply + _mintAmount <= maxSupply, "Max supply reached");
    require(msg.value >= _mintAmount * phaseInfo[currentPhase].price, "Incorrect price");

    if (currentPhase < 5) {
      // If the current phase is the whitelist sale
      userPhase = getUserPhase(msg.sender, _merkleProof);
      require(userPhase > 0, "Not whitelisted");
      require(userPhase <= currentPhase, "Phase not started");
      if (_rugburnTrait) {
        require(burnedMetalIDs[msg.sender].length > 0 && rugburn.balanceOf(msg.sender) > 0, "Not eligible for rugburn");
      }
    } else {
      require(_mintAmount <= 5, "TX limit exceeded");
      perWalletLimit = 20;
      userClaimedIndex = addressClaimedAmtPublic[msg.sender];
    }
    require(userClaimedIndex + _mintAmount <= perWalletLimit, "Wallet limit exceeded");

    _safeMint(msg.sender, _mintAmount);
    tokenMinter[supply] = mintData(msg.sender, _rugburnTrait, _mintAmount);
    if (currentPhase < 5) {
      addressClaimedAmt[msg.sender] += _mintAmount;
    } else {
      addressClaimedAmtPublic[msg.sender] += _mintAmount;
    }
  }

  /// @notice               Owner function to reserve tokens
  /// @param _mintAmount    Amount of tokens to mint
  function mintAdmin(uint256 _mintAmount) public onlyOwner {
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "Max supply reached");
    _safeMint(msg.sender, _mintAmount);
  }

  /// @notice               Burn function
  /// @param _tokenId       Token to burn
  function burnToken(uint256 _tokenId) public {
    require(!pausedBurn, "Burn is paused");
    _burn(_tokenId, true);
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

  function tokensOfOwner(address owner) external view returns (uint256[] memory) {
      unchecked {
          uint256 tokenIdsIdx;
          address currOwnershipAddr;
          uint256 tokenIdsLength = balanceOf(owner);
          uint256[] memory tokenIds = new uint256[](tokenIdsLength);
          TokenOwnership memory ownership;
          for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
              ownership = _ownerships[i];
              if (ownership.burned) {
                  continue;
              }
              if (ownership.addr != address(0)) {
                  currOwnershipAddr = ownership.addr;
              }
              if (currOwnershipAddr == owner) {
                  tokenIds[tokenIdsIdx++] = i;
              }
          }
          return tokenIds;
      }
  }

  function reveal() public onlyOwner {
    revealed = true;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    require(paused != _state, "Already paused/unpaused");
    if (_state) {
      mintStopTime = block.timestamp;
    } else {
      mintStartTime += (block.timestamp - mintStopTime);
    }
    paused = _state;
  }

  function pauseBurn(bool _state) external onlyOwner {
    pausedBurn = _state;
  }

  function isWhitelisted(address _user, bytes32[] calldata _merkleProof, uint256 _phase) public view returns (bool) {
    return MerkleProof.verify(_merkleProof, phaseInfo[_phase].merkleRoot, keccak256(abi.encodePacked(_user)));
  }

  function setMerkleRoot(uint256 _phase, bytes32 _merkleRoot) public onlyOwner  {
    require(_phase > 0 && _phase < 5, "Phase should be between 1 and 4");
    phaseInfo[_phase].merkleRoot = _merkleRoot;
  }

  function setPriceInWei(uint256 _phase, uint _priceInWei) public onlyOwner beforeSale {
    require(_phase > 0 && _phase <= 5, "Phase should be between 1 and 5");
    phaseInfo[_phase].price = _priceInWei;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner beforeSale {
    maxSupply = _maxSupply;
  }

  function setMetalAddress(address _contract) public onlyOwner {
    liquidMetals = IBurnable(_contract);
  }

  function setDroneAddress(address _contract) public onlyOwner {
    drones = IBurnable(_contract);
  }

  function setRugburnAddress(address _contract) public onlyOwner {
    rugburn = IRugBurn(_contract);
  }

  function getBurnInfo(address _burner) public view returns (uint[] memory metalsBurned, uint[] memory dronesBurned) {
    uint[] memory metalTokenIDs = burnedMetalIDs[_burner];
    uint[] memory droneTokenIDs = burnedDroneIDs[_burner];
    return (metalTokenIDs, droneTokenIDs);
  }

  function withdraw() public onlyOwner { // functional
    uint256 balance = address(this).balance;
    uint256 dev_share = (balance * 12) / 100;
    payable(0x034Df4dA8802989c07c7Bc8A98338E83e6a1bF4b).transfer(dev_share);
    payable(owner()).transfer(address(this).balance);
  }
}