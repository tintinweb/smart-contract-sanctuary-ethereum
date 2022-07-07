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
import "./AccessControlMixin.sol";

contract ExpansionWeirdPunks is ERC721, Ownable, AccessControlMixin {
  using Strings for uint256;
 
  string public baseURI;
  string public baseExtension = '.json';
  uint256 public maxSupply = 2000;
  uint256 public totalSupply = 1000;
  bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
  bytes32 public constant ORACLE = keccak256("ORACLE");
  address public oracleAddress;
  bool public allowBridging = false;
  uint256 public constant BATCH_LIMIT = 20;

  event startBatchBridge(address user, uint256[] IDs);

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  constructor(
    string memory _initBaseURI,
    address _MintableAssetProxy,
    address _oracleAddress
  ) ERC721("Expansion Weird Punks", "EWP") {
    setBaseURI(_initBaseURI);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(PREDICATE_ROLE, _MintableAssetProxy);
    oracleAddress = _oracleAddress;
    _setupRole(ORACLE, _oracleAddress);
  }
 
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address user, uint256 tokenId) external only(PREDICATE_ROLE) {
    _mint(user, tokenId);
    totalSupply++;
  }

  function depositBridge(address user, uint256[] memory IDs) public only(ORACLE) {
    for (uint256 i; i < IDs.length; i++) {
      _mint(user, IDs[i]);
      totalSupply++;
    }
  }
 
  function batchBridge(uint256[] memory IDs) public {
    require(allowBridging);
    require(IDs.length <= BATCH_LIMIT, "ExpansionWeirdPunks: Exceeds limit");
    for (uint256 i; i < IDs.length; i++) {
      require(msg.sender == ownerOf(IDs[i]), string(abi.encodePacked("ExpansionWeirdPunks: Invalid owner of ", IDs[i])));
      _burn(IDs[i]);
      totalSupply--;
    }
    emit startBatchBridge(msg.sender, IDs);
  }
 
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ExpansionWeirdPunks: URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
 
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setAllowBridging(bool allow) public onlyOwner {
    allowBridging = allow;
  }

  function setOracleAddress(address newOracleAddress) public onlyOwner {
    _revokeRole(ORACLE, oracleAddress);
    _grantRole(ORACLE, newOracleAddress);
    oracleAddress = newOracleAddress;
  }
}