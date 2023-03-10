// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

import "./Interfaces/IProvider.sol";
import "./Interfaces/IController.sol";

contract Controller is IController {
  UniswapParams public uniswapParams;

  address private dao;
  address public curve3Pool;
  uint256 public curve3PoolFee;

  // (vaultNumber => protocolNumber => protocolInfoStruct): struct in IController
  mapping(uint256 => mapping(uint256 => ProtocolInfoS)) public protocolInfo;
  // (vaultNumber => protocolNumber => protocolName): name of underlying protocol vaults
  mapping(uint256 => mapping(uint256 => string)) public protocolNames;

  // (vaultAddress => bool): true when address is whitelisted
  mapping(address => bool) public vaultWhitelist;
  // (vaultAddress => bool): true when protocol has claimable tokens / extra rewards
  mapping(address => bool) public claimable;

  // (vaultNumber => protocolNumber => bool): true when protocol is blacklisted
  mapping(uint256 => mapping(uint256 => bool)) public protocolBlacklist;
  // (vaultNumber => protocolNumber => address): address of the governance token
  mapping(uint256 => mapping(uint256 => address)) public protocolGovToken;
  // (vaultNumber => latestProtocolId)
  mapping(uint256 => uint256) public latestProtocolId;

  // (stableCoinAddress => curveIndex): curve index for stable coins
  mapping(address => int128) public curveIndex;
  // (stableCoinAddress => uScale): uScale for vault currency coins (i.e. stables) used for swapping
  mapping(address => uint256) public underlyingUScale; // index is address of vaultcurrency erc20 contract

  event SetProtocolNumber(uint256 protocolNumber, address protocol);

  constructor(address _dao) {
    dao = _dao;
  }

  // Modifier for only vault?
  modifier onlyDao() {
    require(msg.sender == dao, "Controller: only DAO");
    _;
  }

  modifier onlyVault() {
    require(vaultWhitelist[msg.sender] == true, "Controller: only Vault");
    _;
  }

  /// @notice Harvest tokens from underlying protocols
  /// @param _vaultNumber Number of the vault
  /// @param _protocolNumber Protocol number linked to protocol vault
  function claim(
    uint256 _vaultNumber,
    uint256 _protocolNumber
  ) external override onlyVault returns (bool) {
    if (claimable[protocolInfo[_vaultNumber][_protocolNumber].LPToken]) {
      return
        IProvider(protocolInfo[_vaultNumber][_protocolNumber].provider).claim(
          protocolInfo[_vaultNumber][_protocolNumber].LPToken,
          msg.sender
        );
    } else {
      return false;
    }
  }

  function getUniswapParams() external view returns (UniswapParams memory) {
    return uniswapParams;
  }

  function getUniswapPoolFee() external view returns (uint24) {
    return uniswapParams.poolFee;
  }

  function getUniswapQuoter() external view returns (address) {
    return uniswapParams.quoter;
  }

  function getCurveParams(address _in, address _out) external view returns (CurveParams memory) {
    CurveParams memory curveParams;
    curveParams.indexTokenIn = curveIndex[_in];
    curveParams.indexTokenOut = curveIndex[_out];
    curveParams.pool = curve3Pool;
    curveParams.poolFee = curve3PoolFee;

    return curveParams;
  }

  /// @notice Getter for protocol blacklist, given an vaultnumber and protocol number returns true if blacklisted. Can only be called by vault.
  /// @param _vaultNumber Number of the vault
  /// @param _protocolNum Protocol number linked to protocol vault
  function getProtocolBlacklist(
    uint256 _vaultNumber,
    uint256 _protocolNum
  ) external view override onlyVault returns (bool) {
    return protocolBlacklist[_vaultNumber][_protocolNum];
  }

  /// @notice Getter for the ProtocolInfo struct
  /// @param _vaultNumber Number of the vault
  /// @param _protocolNum Protocol number linked to protocol vault
  function getProtocolInfo(
    uint256 _vaultNumber,
    uint256 _protocolNum
  ) external view override returns (ProtocolInfoS memory) {
    return protocolInfo[_vaultNumber][_protocolNum];
  }

  /// @notice Setter for protocol blacklist, given an vaultnumber and protocol number puts the protocol on the blacklist. Can only be called by vault.
  /// @param _vaultNumber Number of the vault
  /// @param _protocolNum Protocol number linked to protocol vault
  function setProtocolBlacklist(
    uint256 _vaultNumber,
    uint256 _protocolNum
  ) external override onlyVault {
    protocolBlacklist[_vaultNumber][_protocolNum] = true;
  }

  /// @notice Gets the gas price from Chainlink oracle
  /// @return gasPrice latest gas price from oracle
  function getGovToken(uint256 _vaultNumber, uint256 _protocolNum) external view returns (address) {
    return protocolGovToken[_vaultNumber][_protocolNum];
  }

  /// @notice Getter for dao address
  function getDao() public view returns (address) {
    return dao;
  }

  /*
  Only Dao functions
  */

  /// @notice Add protocol and vault to Controller
  /// @param _name Name of the protocol vault combination
  /// @param _vaultNumber Number of the vault
  /// @param _provider Address of the protocol provider
  /// @param _protocolLPToken Address of protocolToken eg cUSDC
  /// @param _underlying Address of underlying protocol vault eg USDC
  /// @param _govToken Address governance token of the protocol
  function addProtocol(
    string calldata _name,
    uint256 _vaultNumber,
    address _provider,
    address _protocolLPToken,
    address _underlying,
    address _govToken,
    uint256 _uScale
  ) external onlyDao returns (uint256) {
    uint256 protocolNumber = latestProtocolId[_vaultNumber];

    protocolNames[_vaultNumber][protocolNumber] = _name;
    protocolGovToken[_vaultNumber][protocolNumber] = _govToken;
    protocolInfo[_vaultNumber][protocolNumber] = ProtocolInfoS(
      _protocolLPToken,
      _provider,
      _underlying,
      _uScale
    );

    emit SetProtocolNumber(protocolNumber, _protocolLPToken);

    latestProtocolId[_vaultNumber]++;

    return protocolNumber;
  }

  /// @notice Add protocol and vault to Controller
  /// @param _vault Vault address to whitelist
  function addVault(address _vault) external onlyDao {
    vaultWhitelist[_vault] = true;
  }

  /// @notice Set the Uniswap Router address
  /// @param _uniswapRouter New Uniswap Router address
  function setUniswapRouter(address _uniswapRouter) external onlyDao {
    uniswapParams.router = _uniswapRouter;
  }

  /// @notice Set the Uniswap Factory address
  /// @param _uniswapQuoter New Uniswap Quoter address
  function setUniswapQuoter(address _uniswapQuoter) external onlyDao {
    uniswapParams.quoter = _uniswapQuoter;
  }

  /// @notice Set the Uniswap Pool fee
  /// @param _poolFee New Pool fee
  function setUniswapPoolFee(uint24 _poolFee) external onlyDao {
    uniswapParams.poolFee = _poolFee;
  }

  /// @notice Set the Curve3Pool fee
  /// @param _poolFee New Pool fee
  function setCurvePoolFee(uint24 _poolFee) external onlyDao {
    curve3PoolFee = _poolFee;
  }

  /// @notice Set curve pool index for underlying token
  /// @param _token Address of Token
  /// @param _index Curve index as decribed in Swap pool
  function addCurveIndex(address _token, int128 _index) external onlyDao {
    curveIndex[_token] = _index;
  }

  /// @notice Set the Curve 3 pool address
  /// @param _pool New pool address
  function setCurve3Pool(address _pool) external onlyDao {
    curve3Pool = _pool;
  }

  function addUnderlyingUScale(address _stable, uint256 _decimals) external onlyDao {
    underlyingUScale[_stable] = 10 ** _decimals;
  }

  /// @notice Set if provider have claimable tokens
  /// @param _LPToken Address of the underlying protocol vault
  /// @param _bool True of the underlying protocol has claimable tokens
  function setClaimable(address _LPToken, bool _bool) external onlyDao {
    claimable[_LPToken] = _bool;
  }

  /// @notice Setter for DAO address
  /// @param _dao DAO address
  function setDao(address _dao) external onlyDao {
    dao = _dao;
  }
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

interface IController {
  struct ProtocolInfoS {
    address LPToken;
    address provider;
    address underlying; // address of underlying token of the protocol eg USDC
    uint256 uScale; // uScale of protocol LP Token
  }

  struct UniswapParams {
    address router;
    address quoter;
    uint24 poolFee;
  }

  struct CurveParams {
    int128 indexTokenIn;
    int128 indexTokenOut;
    address pool;
    uint256 poolFee;
  }

  function claim(uint256 _ETFnumber, uint256 protocolNumber) external returns (bool);

  function addProtocol(
    string calldata name,
    uint256 _ETFnumber,
    address provider,
    address protocolLPToken,
    address underlying,
    address govToken,
    uint256 _uScale
  ) external returns (uint256);

  function curve3Pool() external view returns (address);

  function curve3PoolFee() external view returns (uint256);

  function curveIndex(address _token) external view returns (int128);

  function getProtocolInfo(
    uint256 _ETFnumber,
    uint256 protocolNumber
  ) external view returns (ProtocolInfoS memory);

  function getUniswapParams() external view returns (UniswapParams memory);

  function getCurveParams(address _in, address _out) external view returns (CurveParams memory);

  function latestProtocolId(uint256 _ETFnumber) external view returns (uint256);

  function addVault(address _vault) external;

  function addCurveIndex(address _token, int128 _index) external;

  function underlyingUScale(address _token) external view returns (uint256);

  function setUniswapRouter(address _uniswapRouter) external;

  function setUniswapQuoter(address _uniswapQuoter) external;

  function setUniswapPoolFee(uint24 _poolFee) external;

  function getUniswapPoolFee() external view returns (uint24);

  function getUniswapQuoter() external view returns (address);

  function getProtocolBlacklist(
    uint256 _ETFnumber,
    uint256 _protocolNum
  ) external view returns (bool);

  function setProtocolBlacklist(uint256 _ETFnumber, uint256 _protocolNum) external;

  function getGovToken(uint256 _vaultNumber, uint256 _protocolNum) external view returns (address);

  function getDao() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Derby Finance - 2022
pragma solidity ^0.8.11;

interface IProvider {
  function deposit(
    uint256 _amount,
    address _uToken,
    address _protocolLPToken
  ) external returns (uint256);

  function withdraw(
    uint256 _amount,
    address _uToken,
    address _protocolLPToken
  ) external returns (uint256);

  function exchangeRate(address _protocolLPToken) external view returns (uint256);

  function balanceUnderlying(address _address, address _protocolLPToken)
    external
    view
    returns (uint256);

  function calcShares(uint256 _amount, address _protocolLPToken) external view returns (uint256);

  function balance(address _address, address _protocolLPToken) external view returns (uint256);

  function claim(address _protocolLPToken, address _claimer) external returns (bool);
}