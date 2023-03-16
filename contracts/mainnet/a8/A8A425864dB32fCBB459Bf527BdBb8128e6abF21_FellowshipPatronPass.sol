// SPDX-License-Identifier: MIT
// Copyright (c) 2023 Fellowship

/*

███████ ███████ ██      ██       ██████  ██     ██ ███████ ██   ██ ██ ██████
██      ██      ██      ██      ██    ██ ██     ██ ██      ██   ██ ██ ██   ██
█████   █████   ██      ██      ██    ██ ██  █  ██ ███████ ███████ ██ ██████
██      ██      ██      ██      ██    ██ ██ ███ ██      ██ ██   ██ ██ ██
██      ███████ ███████ ███████  ██████   ███ ███  ███████ ██   ██ ██ ██


██████   █████  ████████ ██████   ██████  ███    ██
██   ██ ██   ██    ██    ██   ██ ██    ██ ████   ██
██████  ███████    ██    ██████  ██    ██ ██ ██  ██
██      ██   ██    ██    ██   ██ ██    ██ ██  ██ ██
██      ██   ██    ██    ██   ██  ██████  ██   ████


██████   █████  ███████ ███████
██   ██ ██   ██ ██      ██
██████  ███████ ███████ ███████
██      ██   ██      ██      ██
██      ██   ██ ███████ ███████


contract + token art by steviep.eth

*/


pragma solidity ^0.8.17;

import "./Dependencies.sol";
import "./FellowshipTokenURI.sol";


contract FellowshipPatronPass is ERC721, ERC721Burnable, Ownable {
  uint256 private constant _maxSupply = 1000;
  uint256 private _totalSupply;
  address public minter;

  address private _royaltyBeneficiary;
  uint16 private _royaltyBasisPoints = 750;

  mapping(uint256 => uint256[]) _tokenIdToTransactions;
  mapping(uint256 => uint256) _tokenIdToTransactionOverflow;

  uint256 public totalProjects;

  struct ProjectInfo {
    address minter;
    address base;
    string name;
    bool locked;
  }

  mapping(uint256 => ProjectInfo) private _projectIdToInfo;
  mapping(uint256 => mapping(uint256 => uint256)) private _tokenIdToPassUses;

  FellowshipTokenURI public tokenURIContract;

  /// @notice Emitted when a token's metadata is updated
  /// @param _tokenId The ID of the updated token
  /// @dev See EIP-4906: https://eips.ethereum.org/EIPS/eip-4906
  event MetadataUpdate(uint256 _tokenId);

  constructor () ERC721('Fellowship Patron Pass', 'FPP') {
    minter = msg.sender;
    _royaltyBeneficiary = msg.sender;
    tokenURIContract = new FellowshipTokenURI();
  }

  /// @notice Current total supply of collection
  /// @return Total supply
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /// @notice Checks if given token ID exists
  /// @param tokenId Token to run existence check on
  /// @return True if token exists
  function exists(uint256 tokenId) external view returns (bool) {
    return _exists(tokenId);
  }

  /// @notice Mints a new token
  /// @param to Address to receive new token
  function mint(address to) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply < _maxSupply, 'Cannot exceed max supply');

    _mint(to, _totalSupply);

    _totalSupply += 1;
  }

  /// @notice Mints a batch of new tokens to a single address
  /// @param to Address to receive all new tokens
  /// @param amount Amount of tokens to mint
  function mintBatch(address to, uint256 amount) external {
    require(minter == msg.sender, 'Caller is not the minting address');
    require(_totalSupply + amount <= _maxSupply, 'Cannot exceed max supply');

    for (uint256 i; i < amount; i++) {
      _mint(to, _totalSupply + i);
    }
    _totalSupply += amount;
  }

  /// @notice Stores information related to the token transfer + emits a metadata update
  /// @dev This information is needed to render the token thumbnail
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
    if (_tokenIdToTransactions[tokenId].length <= 300) {
      _tokenIdToTransactions[tokenId].push(
        uint256(keccak256(abi.encodePacked(
          from, to, tokenId, block.difficulty
        )))
      );
    } else {
      _tokenIdToTransactionOverflow[tokenId]++;
    }
    emit MetadataUpdate(tokenId);
  }

  /// @notice Retrieves the list of transaction hashes for a given tokenId
  /// @param tokenId Token ID
  function tokenIdToTransactions(uint256 tokenId) external view returns (uint256[] memory) {
    return _tokenIdToTransactions[tokenId];
  }

  /// @notice Retrieves the number of times that a token has been transferred, including its mint
  /// @param tokenId Token ID
  function tokenTransactionCount(uint256 tokenId) external view returns (uint256) {
    return _tokenIdToTransactions[tokenId].length + _tokenIdToTransactionOverflow[tokenId];
  }

  /// @notice Token URI
  /// @param tokenId Token ID to look up URI of
  /// @return Token URI
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(tokenId < _totalSupply, "ERC721Metadata: URI query for nonexistent token");
    return tokenURIContract.tokenURI(tokenId);
  }

  /// @notice Adds a project that the mint pass can be used on
  /// @param minterAddress Address of the minter contract that will use the mint pass
  /// @param baseAddress Address of the target project's contract
  /// @param projectName Name to be used in the attributes of the mint pass
  /// @dev Each project will be assigned a project id, which increments by 1
  /// @dev Up to 20 different projects may be added
  function addProjectInfo(
    address minterAddress,
    address baseAddress,
    string memory projectName
  ) external onlyOwner {
    require(totalProjects < 20, 'Project max exceeded');
    uint256 projectId = totalProjects;
    _projectIdToInfo[projectId].minter = minterAddress;
    _projectIdToInfo[projectId].base = baseAddress;
    _projectIdToInfo[projectId].name = projectName;
    totalProjects++;
  }

  /// @notice Updates the info for a project
  /// @param minterAddress Address of the minter contract that will use the mint pass
  /// @param baseAddress Address of the target project's contract
  /// @param projectName Name to be used in the attributes of the mint pass
  function updateProjectInfo(
    uint256 projectId,
    address minterAddress,
    address baseAddress,
    string memory projectName
  ) external onlyOwner {
    require(projectId < totalProjects, 'Project does not exist');
    require(!_projectIdToInfo[projectId].locked, 'Project has been locked');

    _projectIdToInfo[projectId].minter = minterAddress;
    _projectIdToInfo[projectId].base = baseAddress;
    _projectIdToInfo[projectId].name = projectName;
  }

  /// @notice Returns the info for the project
  /// @param projectId Project ID
  /// @return minter address, project address, project name, locked status
  function projectInfo(uint256 projectId) public view returns (address, address, string memory, bool) {
    return (
      _projectIdToInfo[projectId].minter,
      _projectIdToInfo[projectId].base,
      _projectIdToInfo[projectId].name,
      _projectIdToInfo[projectId].locked
    );
  }

  function lockProjectInfo(uint256 projectId) external onlyOwner {
    require(projectId < totalProjects, 'Project does not exist');
    _projectIdToInfo[projectId].locked = true;
  }

  /// @notice Logs the fact that a specific mint pass has been used to mint a project
  /// @param tokenId Token ID
  /// @param projectId Project ID
  /// @dev This can only be called by the designated project minter contract
  function logPassUse(uint256 tokenId, uint256 projectId) external {
    require(msg.sender == _projectIdToInfo[projectId].minter, 'Sender not permissioned');
    require(!_projectIdToInfo[projectId].locked, 'Project has been locked');

    _tokenIdToPassUses[tokenId][projectId] += 1;
    emit MetadataUpdate(tokenId);
  }

  /// @notice Returns the number of times a pass has been used on a specific project
  /// @param tokenId Token ID
  /// @param projectId Project ID
  /// @return Pass uses
  function passUses(uint256 tokenId, uint256 projectId) public view returns (uint256) {
    return _tokenIdToPassUses[tokenId][projectId];
  }


  /// @notice Set the Token URI contract
  /// @param newContract Address of the new Token URI contract
  function setTokenURIContract(address newContract) external onlyOwner {
    tokenURIContract = FellowshipTokenURI(newContract);
  }

  /// @notice Reassigns the minter permission
  /// @param newMinter Address of new minter
  function setMinter(address newMinter) external onlyOwner {
    minter = newMinter;
  }

  /// @notice Sets royalty info for the collection
  /// @param royaltyBeneficiary Address to receive royalties
  /// @param royaltyBasisPoints Basis points of royalty commission
  /// @dev See EIP-2981: https://eips.ethereum.org/EIPS/eip-2981
  function setRoyaltyInfo(
    address royaltyBeneficiary,
    uint16 royaltyBasisPoints
  ) external onlyOwner {
    _royaltyBeneficiary = royaltyBeneficiary;
    _royaltyBasisPoints = royaltyBasisPoints;
  }

  /// @notice Called with the sale price to determine how much royalty is owed and to whom.
  /// @param (unused)
  /// @param _salePrice The sale price of the NFT asset specified by _tokenId
  /// @return receiver Address of who should be sent the royalty payment
  /// @return royaltyAmount The royalty payment amount for _salePrice
  /// @dev See EIP-2981: https://eips.ethereum.org/EIPS/eip-2981
  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (_royaltyBeneficiary, _salePrice * _royaltyBasisPoints / 10000);
  }

  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @return `true` if the contract implements `interfaceId` and
  ///         `interfaceId` is not 0xffffffff, `false` otherwise
  /// @dev Interface identification is specified in ERC-165. This function
  ///      uses less than 30,000 gas. See: https://eips.ethereum.org/EIPS/eip-165
  ///      See EIP-2981: https://eips.ethereum.org/EIPS/eip-2981
  ///      See EIP-4906: https://eips.ethereum.org/EIPS/eip-4906
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == bytes4(0x2a55205a) || interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }
}