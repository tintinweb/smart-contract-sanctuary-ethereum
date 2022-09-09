// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/


/// ============ Imports ============

import "./interfaces/IDCNTSDK.sol";

contract DCNTVaultNFT {

  /// ============ Immutable storage ============

  /// ============ Mutable storage ============

  /// ============ Events ============

  /// @notice Emitted after successfully deploying a contract
  event Create(address nft, address vault);

  /// ============ Constructor ============

  /// @notice Creates a new DecentVaultWrapped instance
  constructor() { }

  /// ============ Functions ============

  function create(
    address _DCNTSDK,
    string memory _name,
    string memory _symbol,
    uint256 _maxTokens,
    uint256 _tokenPrice,
    uint256 _maxTokenPurchase,
    address _vaultDistributionTokenAddress,
    uint256 _unlockDate,
    bool _supports4907
  ) external returns (address nft, address vault) {
    IDCNTSDK sdk = IDCNTSDK(_DCNTSDK);

    address deployedNFT;
    if ( _supports4907 ) {
      deployedNFT = sdk.deployDCNT4907A(
        _name,
        _symbol,
        _maxTokens,
        _tokenPrice,
        _maxTokenPurchase
      );
    } else {
      deployedNFT = sdk.deployDCNT721A(
        _name,
        _symbol,
        _maxTokens,
        _tokenPrice,
        _maxTokenPurchase
      );
    }

    address deployedVault = sdk.deployDCNTVault(
      _vaultDistributionTokenAddress,
      deployedNFT,
      _maxTokens,
      _unlockDate
    );

    emit Create(deployedNFT, deployedVault);
    return (deployedNFT, deployedVault);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDCNTSDK {

  /// @notice implementation addresses for base contracts
  function DCNT721AImplementation() external returns (address);
  function DCNT4907AImplementation() external returns (address);
  function DCNTCrescendoImplementation() external returns (address);
  function DCNTVaultImplementation() external returns (address);
  function DCNTStakingImplementation() external returns (address);

  /// ============ Functions ============

  // deploy and initialize an erc721a clone
  function deployDCNT721A(
    string memory _name,
    string memory _symbol,
    uint256 _maxTokens,
    uint256 _tokenPrice,
    uint256 _maxTokenPurchase
  ) external returns (address clone);

  // deploy and initialize an erc4907a clone
  function deployDCNT4907A(
    string memory _name,
    string memory _symbol,
    uint256 _maxTokens,
    uint256 _tokenPrice,
    uint256 _maxTokenPurchase
  ) external returns (address clone);

  // deploy and initialize a Crescendo clone
  function deployDCNTCrescendo(
    string memory _name,
    string memory _symbol,
    string memory _uri,
    uint256 _initialPrice,
    uint256 _step1,
    uint256 _step2,
    uint256 _hitch,
    uint256 _trNum,
    uint256 _trDenom,
    address payable _payouts
  ) external returns (address clone);

  // deploy and initialize a vault wrapper clone
  function deployDCNTVault(
    address _vaultDistributionTokenAddress,
    address _nftVaultKeyAddress,
    uint256 _nftTotalSupply,
    uint256 _unlockDate
  ) external returns (address clone);

  // deploy and initialize a vault wrapper clone
  function deployDCNTStaking(
    address _nft,
    address _token,
    uint256 _vaultDuration,
    uint256 _totalSupply
  ) external returns (address clone);
}