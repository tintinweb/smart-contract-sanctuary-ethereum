// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IERC721.sol";

contract TestCTR is IERC721 {
  uint8 private constant MAX_MINT_PER_TRX = 5;
  uint16 private constant TOTAL = 50;
  uint16 private constant ROYALTY = 500;
  uint64 private constant PRICE = 0.01 ether;
  bytes16 private constant NAME = "Test CTR";
  bytes16 private constant SYMBOL = "TESTCTR";
  
  address private DEPLOYER;
  uint16 private SUPPLY;
  string private BASE_URI;

  mapping(uint16 => address) private TOKENS;
  mapping(address => uint16[]) private OWNERS;
  mapping(uint16 => address) private APPROVALS;
  mapping(address => mapping(address => bool)) private OPERATOR_APPROVALS;
  
  constructor() {
    DEPLOYER = msg.sender;
  }

  function safeMint(uint256 _qty) external payable {
    require(0 < _qty && _qty <= MAX_MINT_PER_TRX, "invalid quantity");
    require(msg.value == _qty * PRICE, "incorrect amount");
    require(SUPPLY + _qty <= TOTAL, "exceed total supply");
    
    _safeMint(msg.sender, uint16(_qty));
  }

  function setBaseURI(string memory _baseUri) external {
    require(msg.sender == DEPLOYER, "not authorized");
    BASE_URI = _baseUri;
  }

  function withdraw() external {
    payable(DEPLOYER).transfer(address(this).balance);
  }

  /* ERC-721: NFT Standard */
  
  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0), "zero address cannot be queried");
    return OWNERS[_owner].length;
  }

  function ownerOf(uint256 _tokenId) external view returns (address) {
    address _owner = TOKENS[uint16(_tokenId)];
    require(_owner != address(0), "owner does not exist");
    return _owner;
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external payable {
    _safeTransfer(_from, _to, uint16(_tokenId), _data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _safeTransfer(_from, _to, uint16(_tokenId), "");
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _transfer(_from, _to, uint16(_tokenId));
  }

  function approve(address _approver, uint256 _tokenId) external payable {
    require(0 < _tokenId && _tokenId <= SUPPLY, "token not available");
    uint16 tokenId = uint16(_tokenId);
    require(TOKENS[tokenId] == msg.sender, "not authorized");
    APPROVALS[tokenId] = _approver;
    emit Approval(msg.sender, _approver, _tokenId);
  }

  function setApprovalForAll(address _operator, bool _approved) external {
    require(msg.sender != _operator, "approve to caller");
    OPERATOR_APPROVALS[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function getApproved(uint256 _tokenId) external view returns (address) {
    require(0 < _tokenId && _tokenId <= SUPPLY, "token not available");
    return APPROVALS[uint16(_tokenId)];
  }

  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return OPERATOR_APPROVALS[_owner][_operator];
  }

  /* ERC-721: NFT Metadata */

  function name() external pure returns (string memory) {
    return string(abi.encodePacked(NAME));
  }

  function symbol() external pure returns (string memory) {
    return string(abi.encodePacked(SYMBOL));
  }

  function tokenURI(uint256 _tokenId) external view virtual returns (string memory) {
    require(0 < _tokenId && uint16(_tokenId) <= SUPPLY, "token not available");
    return bytes(BASE_URI).length > 0 ? string(abi.encodePacked(BASE_URI, _toString(_tokenId))) : "";
  }

  /* ERC-721: NFT Enumerable */

  function totalSupply() external view returns (uint256) {
    return uint256(SUPPLY);
  }

  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < SUPPLY, "out of bounds");
    return _index + 1;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < OWNERS[_owner].length, "out of bounds");
    return OWNERS[_owner][_index];
  }

  /* ERC-2981: NFT Royalty */

  function royaltyInfo(uint256, uint256 _salePrice) external view returns (address, uint256) {
    return (address(this), _salePrice * ROYALTY / 10000);
  }

  /* ERC-165 */
  
  function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
    return _interfaceId == type(IERC165).interfaceId ||
      _interfaceId == type(IERC721).interfaceId ||
      _interfaceId == type(IERC721Metadata).interfaceId ||
      _interfaceId == type(IERC721Enumerable).interfaceId ||
      _interfaceId == type(IERC2981).interfaceId;
  }

  /* INTERNAL */

  function _safeTransfer(address _from, address _to, uint16 _tokenId, bytes memory _data) private {
    _transfer(_from, _to, _tokenId);
    require(_checkOnERC721Received(_from, _to, _tokenId, _data), "error on receiver");
  }

  function _transfer(address _from, address _to, uint16 _tokenId) private {
    require(TOKENS[_tokenId] == msg.sender || APPROVALS[_tokenId] == msg.sender || OPERATOR_APPROVALS[_from][msg.sender], "not authorized");
    require(TOKENS[_tokenId] == _from && _to != address(0), "not allowed");
    require(0 < _tokenId && _tokenId <= SUPPLY, "token not available");

    uint16[] storage _fromTokens = OWNERS[_from];
    for (uint i = 0; i < _fromTokens.length; i++) {
      if (_fromTokens[i] == _tokenId) {
        _fromTokens[i] = _fromTokens[_fromTokens.length - 1];
        _fromTokens.pop();
        break;
      }
    }

    OWNERS[_from] = _fromTokens;
    OWNERS[_to].push(_tokenId);
    TOKENS[_tokenId] = _to;
    APPROVALS[_tokenId] = address(0);

    emit Transfer(_from, _to, _tokenId);
  }

  function _safeMint(address _minter, uint16 _qty) private {
    uint16 _tokenId = SUPPLY + 1;
    uint16 _lastTokenId = _tokenId + _qty - 1;
    while (_tokenId <= _lastTokenId) {
      OWNERS[_minter].push(_tokenId);
      TOKENS[_tokenId] = _minter;

      emit Transfer(address(0), _minter, _tokenId);
      require(_checkOnERC721Received(address(0), _minter, _tokenId++, ""), "error on receiver");
    }
    SUPPLY = _lastTokenId;
  }

  function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool) {
    if (_to.code.length > 0) {
      try IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721TokenReceiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("transfer to non ERC721TokenReceiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
    return true;
  }

  function _toString(uint256 _i) private pure returns (string memory) {
    if (_i == 0) {
      return "0";
    }
    uint256 temp = _i;
    uint256 digits;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (_i != 0) {
        digits -= 1;
        buffer[digits] = bytes1(uint8(48 + uint256(_i % 10)));
        _i /= 10;
    }
    return string(buffer);
  }
}