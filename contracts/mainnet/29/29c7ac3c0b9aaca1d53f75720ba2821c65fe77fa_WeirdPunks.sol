// SPDX-License-Identifier: MIT

/*
 __    __    ___  ____  ____   ___        ____  __ __  ____   __  _  _____
|  |__|  |  /  _]|    ||    \ |   \      |    \|  |  ||    \ |  |/ ]/ ___/
|  |  |  | /  [_  |  | |  D  )|    \     |  o  )  |  ||  _  ||  ' /(   \_ 
|  |  |  ||    _] |  | |    / |  D  |    |   _/|  |  ||  |  ||    \ \__  |
|  `  '  ||   [_  |  | |    \ |     |    |  |  |  :  ||  |  ||     \/  \ |
 \      / |     | |  | |  .  \|     |    |  |  |     ||  |  ||  .  |\    |
  \_/\_/  |_____||____||__|\_||_____|    |__|   \__,_||__|__||__|\_| \___|
                                                                          
*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./ERC1155Tradable.sol";
import "./AccessControlMixin.sol";

contract WeirdPunks is ERC721, Ownable, AccessControlMixin {
  using Strings for uint256;
 
  string public baseURI;
  string public baseExtension = '.json';
  mapping(uint256 => uint256) public weirdMapping;
  ERC1155Tradable public openseaContract;
  uint256 public maxSupply = 1000;
  uint256 public totalSupply = 0;
  bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
  bytes32 public constant ORACLE = keccak256("ORACLE");
  address public oracleAddress;
  bool public allowMigration = false;
  bool public allowBridging = false;
  uint256 public constant BATCH_LIMIT = 20;
  address public delistWallet;
  mapping(uint256 => uint256) internal migrateTimestamp;

  event startBatchBridge(address user, uint256[] IDs, uint256[] bridgeMigrateTimestamps);

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  constructor(
    string memory _initBaseURI,
    address _openseaContract,
    address _MintableAssetProxy,
    address _oracleAddress,
    address _delistWallet
  ) ERC721("Weird Punks", "WP") {
    setBaseURI(_initBaseURI);
    openseaContract = ERC1155Tradable(_openseaContract);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PREDICATE_ROLE, _MintableAssetProxy);
    _setupRole(ORACLE, _oracleAddress);
    setDelistWallet(_delistWallet);
  }
 
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // external for mapping
  function mint(address user, uint256 tokenId) external only(PREDICATE_ROLE) {
    _mint(user, tokenId);
    totalSupply++;
  }

  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  function depositBridge(address user, uint256[] memory IDs) public only(ORACLE) {
    for (uint256 i; i < IDs.length; i++) {
      _mint(user, IDs[i]);
      totalSupply++;
    }
  }
 
  // public
  function batchBridge(uint256[] memory IDs) public {
    require(allowBridging);
    require(IDs.length <= BATCH_LIMIT, "WeirdPunks: Exceeds limit");
    uint256[] memory bridgeMigrateTimestamps = new uint256[](IDs.length);
    for (uint256 i; i < IDs.length; i++) {
      require(msg.sender == ownerOf(IDs[i]), string(abi.encodePacked("WeirdPunks: Invalid owner of ", IDs[i])));
      _burn(IDs[i]);
      totalSupply--;
      bridgeMigrateTimestamps[i] = getMigrateTimestamp(IDs[i]);
    }
    emit startBatchBridge(msg.sender, IDs, bridgeMigrateTimestamps);
  }


  function burnAndMint(address _to, uint256[] memory _IDs) public {
    require(allowMigration, "WeirdPunks: Migration is currently closed");
    require(openseaContract.isApprovedForAll(_to, address(this)), "WeirdPunks: Not approved for burn");
    require(totalSupply + _IDs.length <= maxSupply, "WeirdPunks: Exceeds max supply");

    for(uint256 i = 0; i < _IDs.length; i++) {
        require(!_exists(_IDs[i]), string(abi.encodePacked("WeirdPunks: Already Minted ID #", _IDs[i])));
        uint256 openseaID = weirdMapping[_IDs[i]];
        bytes memory _data;
        openseaContract.safeTransferFrom(_to, delistWallet, openseaID, 1, _data); 
        migrateTimestamp[_IDs[i]] = block.timestamp;

        _mint(_to, _IDs[i]);
        totalSupply++;
    }
  }
 
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "WeirdPunks: URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function getMigrateTimestamp(uint256 _id) public view returns(uint256) {
    return migrateTimestamp[_id];
  }

  function getMigrateTimestamps(uint256[] memory _ids) public view returns(uint256[] memory) {
    uint256[] memory timestamps = new uint256[](_ids.length);
    for(uint256 i = 0; i < _ids.length; i++) {
      timestamps[i] = migrateTimestamp[_ids[i]];
    }
    return timestamps;
  }
 
  //only owner
  function overrideMint(address _to, uint256[] memory _IDs) public onlyOwner {
    require(!allowMigration, "WeirdPunks: Migration is currently open");
    require(totalSupply + _IDs.length <= maxSupply, "WeirdPunks: Exceeds max supply");
    for(uint256 i = 0; i < _IDs.length; i++) {
        require(!_exists(_IDs[i]), string(abi.encodePacked("WeirdPunks: Already Minted ID #", _IDs[i])));
        
        _mint(_to, _IDs[i]);
        totalSupply++;

        if(migrateTimestamp[_IDs[i]] < 1) {
          migrateTimestamp[_IDs[i]] = block.timestamp;
        }
    }
  }

  function addSingleWeirdMapping(uint256 ID, uint256 OSID) private returns(bool success) {
    weirdMapping[ID] = OSID;
    success = true;
  }
 
  function addWeirdMapping(uint256[] memory IDs, uint256[] memory OSIDs) public onlyOwner returns(bool success) {
    require(IDs.length == OSIDs.length, "WeirdPunks: IDs and OSIDs must be the same length");
    for (uint256 i = 0; i < IDs.length; i++) {
      if (addSingleWeirdMapping(IDs[i], OSIDs[i])) {
        success = true;
      }
    }    
  }
 
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setOpenseaContract(address _openseaContract) public onlyOwner {
    openseaContract = ERC1155Tradable(_openseaContract);
  }

  function setAllowMigration(bool allow) public onlyOwner {
    allowMigration = allow;
  }

  function setAllowBridging(bool allow) public onlyOwner {
    allowBridging = allow;
  }

  function setDelistWallet(address _delistWallet) public onlyOwner {
    delistWallet = _delistWallet;
  }

  function setOracleAddress(address newOracleAddress) public onlyOwner {
    _revokeRole(ORACLE, oracleAddress);
    _grantRole(ORACLE, newOracleAddress);
    oracleAddress = newOracleAddress;
  }
}