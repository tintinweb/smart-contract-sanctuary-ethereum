import './base64.sol';

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title  GitHub Renoun Non-Transferrable Tokens
/// @author Jonathan Becker <[email protected]>
/// @author Badge design by Achal <@achalvs>
/// @notice This contract is an ERC721 compliant implementation of
///           a badge system for rewarding GitHub contributions with
///           a non-transferrable, on-chain token.
/// @dev    This contract is NOT fully compliant with ERC721, and will
///           REVERT all transfers.
/// 
///         https://github.com/Jon-Becker/renoun


interface ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
  
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
  function totalSupply() external view returns (uint256);
}

interface ERC165 {
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract IBadgeRenderer {
  function renderPullRequest(
    uint256 _pullRequestID,
    string memory _pullRequestTitle,
    uint256 _additions,
    uint256 _deletions,
    string memory _pullRequestCreatorPictureURL,
    string memory _pullRequestCreatorUsername,
    string memory _commitHash,
    string memory _repositoryOwner,
    string memory _repositoryName,
    uint256 _repositoryStars,
    uint256 _repositoryContributors
  ) public pure returns (string memory) {}
}

contract Renoun is ERC721 {

  string public   name;
  string public   repositoryOwner;
  string public   repositoryName;
  string public   symbol;
  uint256 public  totalSupply;
  address private _admin;
  address private _rendererAddress;

  /// @param _pullRequestID The ID of the pull request
  /// @param _pullRequestTitle The title of the pull request
  /// @param _additions The number of additions in the pull request
  /// @param _deletions The number of deletions in the pull request
  /// @param _pullRequestCreatorPictureURL The URL of the pull request creator's profile picture
  /// @param _pullRequestCreatorUsername The username of the pull request creator
  /// @param _commitHash The hash of the commit
  /// @param _repositoryOwner The owner of the repository
  /// @param _repositoryName The name of the repository
  /// @param _repositoryStars The number of stars the repository has
  /// @param _repositoryContributors The number of contributors to the repository
  struct Contribution {
    uint256 _pullRequestID;
    string _pullRequestTitle;
    uint256 _additions;
    uint256 _deletions;
    string _pullRequestCreatorPictureURL;
    string _pullRequestCreatorUsername;
    string _commitHash;
    string _repositoryOwner;
    string _repositoryName;
    uint256 _repositoryStars;
    uint256 _repositoryContributors;
  }

  mapping(uint256 => address) private _ownership;
  mapping(address => uint256) private _balances;
  mapping(uint256 => Contribution) public contribution;
  

  constructor(
    string memory _repositoryName, 
    string memory _repositoryOwner, 
    string memory _name,
    string memory _symbol, 
    address _renderer
  ) {
    name = _name;
    totalSupply = 0;
    symbol = _symbol;
    _admin = msg.sender;
    _rendererAddress = _renderer;
    repositoryName = _repositoryName;
    repositoryOwner = _repositoryOwner;
  }

  function mint(
    address _to,
    uint256 _pullRequestID,
    string memory _pullRequestTitle,
    uint256 _additions,
    uint256 _deletions,
    string memory _pullRequestCreatorPictureURL,
    string memory _pullRequestCreatorUsername,
    string memory _commitHash,
    uint256 _repositoryStars,
    uint256 _repositoryContributors
  ) public returns (bool) {
    require(msg.sender == _admin, "Renoun: Only the admin can mint new tokens");
    require(_to != address(0), "Renoun: Cannot mint to the null address");
    require(_pullRequestID > 0, "Renoun: Pull request ID must be greater than 0");

    Contribution memory _contribution = Contribution(
      _pullRequestID,
      _pullRequestTitle,
      _additions,
      _deletions,
      _pullRequestCreatorPictureURL,
      _pullRequestCreatorUsername,
      _commitHash,
      repositoryOwner,
      repositoryName,
      _repositoryStars,
      _repositoryContributors
    );
    totalSupply++;
    _ownership[totalSupply] = _to;
    _balances[_to] = _balances[_to] + 1;
    contribution[totalSupply] = _contribution;

    emit Transfer(address(0), _to, totalSupply);

    return true;
  }

  function changeRenderer(address _newRenderer)public returns (bool) {
    require(msg.sender == _admin, "Renoun: Only the admin can change the renderer address");
    require(_newRenderer != address(0), "Renoun: Cannot change to the null address");
    _rendererAddress = _newRenderer;
  }

  function tokenURI(uint256 _tokenId) public override view virtual returns (string memory) {
    require(_ownership[_tokenId] != address(0x0), "Renoun: token doesn't exist.");
    
    Contribution memory _contribution = contribution[_tokenId];
    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      '{',
      '"name": "Pull Request #',_integerToString(_contribution._pullRequestID),'",',
      '"description": "A shiny, non-transferrable badge to show off my GitHub contribution.",',
      '"tokenId": ',_integerToString(_tokenId),',',
      '"image": "data:image/svg+xml;base64,',Base64.encode(bytes(_renderSVG(_contribution))),'"',
      '}'
      ))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function balanceOf(address _owner) public view virtual override returns (uint256) {
    return _balances[_owner];
  }

  function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
    return _ownership[_tokenId];
  }

  // this function is disabled since we don;t want to allow transfers
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable virtual override {
    revert("Renoun: Transfer not supported.");
  }
  
  // this function is disabled since we don;t want to allow transfers
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public payable virtual override {
    revert("Renoun: Transfer not supported.");
  }

  // this function is disabled since we don;t want to allow transfers
  function transferFrom(address _from, address _to, uint256 _tokenId) public payable virtual override {
    revert("Renoun: Transfer not supported.");
  }

  // this function is disabled since we don;t want to allow transfers
  function approve(address _to, uint256 _tokenId) public payable virtual override {
    revert("Renoun: Approval not supported.");
  }

  // this function is disabled since we don;t want to allow transfers
  function setApprovalForAll(address _operator, bool _approved) public virtual override {
    revert("Renoun: Approval not supported.");
  }

  // this function is disabled since we don;t want to allow transfers
  function getApproved(uint256 _tokenId) public view override returns (address) {
    return address(0x0);
  }

  // this function is disabled since we don;t want to allow transfers
  function isApprovedForAll(address _owner, address _operator) public view override returns (bool){
    return false;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == 0x01ffc9a7 ||
      interfaceId == 0x80ac58cd ||
      interfaceId == 0x5b5e139f;
  }


  /// @notice Converts an integer to a string
  /// @param  _i The integer to convert
  /// @return The string representation of the integer
  function _integerToString(uint _i) internal pure returns (string memory) {
    
    if (_i == 0) {
      return "0";
    }
   
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k-1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function _renderSVG(Contribution memory _contribution) internal view returns (string memory){
    IBadgeRenderer renderer = IBadgeRenderer(_rendererAddress);
    return renderer.renderPullRequest(
      _contribution._pullRequestID,
      _contribution._pullRequestTitle,
      _contribution._additions,
      _contribution._deletions,
      _contribution._pullRequestCreatorPictureURL,
      _contribution._pullRequestCreatorUsername,
      _contribution._commitHash,
      _contribution._repositoryOwner,
      _contribution._repositoryName,
      _contribution._repositoryStars,
      _contribution._repositoryContributors
    );
  }
}