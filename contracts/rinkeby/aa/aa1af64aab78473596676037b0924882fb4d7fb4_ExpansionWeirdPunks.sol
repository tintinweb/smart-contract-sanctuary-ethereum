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
import "./ERC20.sol";
import "./AccessControlMixin.sol";
import "./IChildToken.sol";
import "./Math.sol";
import "./gasCalculator.sol";

contract ExpansionWeirdPunks is ERC721, Ownable, AccessControlMixin, IChildToken {
  using Strings for uint256;
 
  string public baseURI;
  string public baseExtension = '.json';
  uint256 public maxSupply = 2000;
  uint256 public totalSupply = 1000;
  bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
  bytes32 public constant ORACLE = keccak256("ORACLE");
  bytes32 public constant MINTER = keccak256("MINTER");
  mapping (uint256 => bool) public withdrawnTokens;
  address public minterAddress;
  address public oracleAddress;
  ERC20 public WeirdToken = ERC20(0xcB8BCDb991B45bF5D78000a0b5C0A6686cE43790);
  ERC20 public WETH = ERC20(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
  gasCalculator public gasETHContract;
  uint256 public WEIRD_BRIDGE_FEE = 50 ether;
  bool public allowBridging = false;
  bool public allowPolyBridging = false;
  uint256 public constant BATCH_LIMIT = 20;

  event WithdrawnBatch(address indexed user, uint256[] tokenIds);
  event startBatchBridge(address user, uint256[] IDs);

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  constructor(
    string memory _initBaseURI,
    address childChainManager,
    address _oracleAddress,
    address _minterAddress,
    address _gasCalculator
  ) ERC721("Weird Punks", "WP") {
    setBaseURI(_initBaseURI);
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(DEPOSITOR_ROLE, childChainManager);
    minterAddress = _minterAddress;
    _setupRole(MINTER, _minterAddress);
    oracleAddress = _oracleAddress;
    _setupRole(ORACLE, _oracleAddress);
    gasETHContract = gasCalculator(_gasCalculator);
  }
 
  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // external for mapping
  function deposit(address user, bytes calldata depositData) external override only(DEPOSITOR_ROLE) {
    if (depositData.length == 32) {
      uint256 tokenId = abi.decode(depositData, (uint256));
      withdrawnTokens[tokenId] = false;
      _mint(user, tokenId);
      totalSupply++;
    } else {
      uint256[] memory tokenIds = abi.decode(depositData, (uint256[]));
      uint256 length = tokenIds.length;
      for (uint256 i; i < length; i++) {
        withdrawnTokens[tokenIds[i]] = false;
        _mint(user, tokenIds[i]);
        totalSupply++;
      }
    }
  }

  function withdrawBatch(uint256[] calldata tokenIds) external {
    require(allowPolyBridging);
    uint256 length = tokenIds.length;
    require(length <= BATCH_LIMIT, "WeirdPunks: Exceeds batch limit");

    for (uint256 i; i < length; i++) {
      uint256 tokenId = tokenIds[i];

      require(_msgSender() == ownerOf(tokenId), string(abi.encodePacked("WeirdPunks: Invalid owner of ", tokenId)));
      withdrawnTokens[tokenId] = true;
      _burn(tokenId);
      totalSupply--;
  }
    emit WithdrawnBatch(_msgSender(), tokenIds);
  }

  function depositBridge(address user, uint256[] memory IDs) public only(ORACLE) {
    for (uint256 i; i < IDs.length; i++) {
      _mint(user, IDs[i]);
      totalSupply++;
    }
  }

  // public
  function batchBridge(uint256[] memory IDs, uint256 gas) public {
    require(allowBridging);

    uint256 payableGas = gasETHContract.gasETH() + (IDs.length - 1) * (gasETHContract.gasETH() / gasETHContract.gasMultiplier() * 10);
    require(WETH.allowance(msg.sender, address(this)) >= payableGas, "WeirdPunks: Not enough polygon eth");
    require(gas >= payableGas, "WeirdPunks: Not enough gas");
    WETH.transferFrom(msg.sender, oracleAddress, gas);

    uint256 payableWeird = WEIRD_BRIDGE_FEE * IDs.length;
    require(WeirdToken.allowance(msg.sender, address(this)) >= payableWeird, "WeirdPunks: Not enough Weird tokens allowed");
    WeirdToken.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, payableWeird);

    require(IDs.length <= BATCH_LIMIT, "WeirdPunks: Exceeds limit");
    for (uint256 i; i < IDs.length; i++) {
      require(msg.sender == ownerOf(IDs[i]), string(abi.encodePacked("WeirdPunks: Invalid owner of ", IDs[i])));
      _burn(IDs[i]);
      totalSupply--;
    }
    emit startBatchBridge(msg.sender, IDs);
  }
 
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "WeirdPunks: URI query for nonexistent token");
 
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  // only Minter
  function mint(address _to, uint256 amount) public only(MINTER) {
    require(totalSupply + amount <= maxSupply, "WeirdPunks: Exceeds max supply");
    for(uint256 i = 1; i <= amount; i++) {     
        _mint(_to, totalSupply + i);
    }
    totalSupply += amount;
  }
 
  // only owner
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setAllowPolyBridging(bool allow) public onlyOwner {
    allowPolyBridging = allow;
  }

  function setAllowBridging(bool allow) public onlyOwner {
    allowBridging = allow;
  }

  function setWeirdBridgeFee(uint256 _newFee) public onlyOwner {
    WEIRD_BRIDGE_FEE = _newFee;
  }

  function setOracleAddress(address newOracleAddress) public onlyOwner {
    _revokeRole(ORACLE, oracleAddress);
    _grantRole(ORACLE, newOracleAddress);
    oracleAddress = newOracleAddress;
  }

  function setMinterAddress(address newMinterAddress) public onlyOwner {
    _revokeRole(MINTER, minterAddress);
    _grantRole(MINTER, newMinterAddress);
    minterAddress = newMinterAddress;
  }

  function setGasCalculator(address newGasCalculator) public onlyOwner {
    gasETHContract = gasCalculator(newGasCalculator);
  }
}