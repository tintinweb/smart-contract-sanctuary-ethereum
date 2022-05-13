/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Interfaces
interface IERC165 {
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface IERC721 {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) external view returns (address owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _to, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address operator);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Metadata {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IERC721Receiver {
  function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

library LibPart {
  bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");
  struct Part {
    address payable account;
    uint256 value;
  }
  function hash(Part memory part) internal pure returns (bytes32) {
    return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
  }
}

// Abstract Contracts
abstract contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function transferOwnership(address _newOwner) public virtual onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    owner = _newOwner;
  }
}

abstract contract Mintable {
  mapping (address => bool) public minters;

  constructor() {
    minters[msg.sender] = true;
  }

  modifier onlyMinter() {
    require(minters[msg.sender], "Mintable: caller is not the minter");
    _;
  }

  function setMinter(address _newMinter) public virtual onlyMinter {
    require(_newMinter != address(0), "Mintable: new minter is the zero address");
    minters[_newMinter] = true;
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;

  uint256 private _status;

  constructor() {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }
}

// Contract
contract DebugNft is Ownable, Mintable, ReentrancyGuard {
  // ERC721
  mapping(uint256 => address) private _owners;
  mapping(address => uint256) private _balances;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalities);

  // Constants
  bytes4 private constant _INTERFACE_ID_ROYALTIES = 0xcad96cca; // Rarible
  // !!!↓参照されてない
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a; // ERC2981

  // ERC721Metadata
  string public name = 'DebugNft';
  string public symbol = 'DBG';

  // ERC721Enumerable
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;
  uint256[] private _allTokens;
  mapping(uint256 => uint256) private _allTokensIndex;

  // Rarible
  mapping (uint256 => LibPart.Part[]) internal royalties;
  LibPart.Part internal globalRoyalty;

  // Customized
  mapping(uint256 => TokenInfo) public tokenInfo; // tokenId => traitCode
  mapping(bytes12 => uint256) public traitCodeIndex; // traitCode => tokenId

  struct TokenInfo {
    bytes12 traitCode;
    string metadataHash;
    string contentHash;
  }
    
  // Constructor
  constructor() {}

  // ERC165
  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return
      interfaceId == type(IERC165).interfaceId ||
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == _INTERFACE_ID_ROYALTIES;
  }

  // Customized (public)
  // 代行
  function mint(
    address _to,
    bytes12 _traitCode,  // 見た目をカスタマイズするためのパラメタ
    string memory _metadataHash,
    string memory _contentHash,
    bytes memory _sig) external onlyMinter returns (bool) {

    address signer = getSigner(_traitCode, _metadataHash, _contentHash, _sig);
    require(minters[signer], "DebugNft: invalid signature");

    _mint(_to, _traitCode, _metadataHash, _contentHash);

    return true;
  }

  // 本人実行
  function mint(
    address _to,
    bytes12 _traitCode,
    string memory _metadataHash,
    string memory _contentHash) external onlyMinter returns (bool) {

    require(minters[msg.sender], "DebugNft: no minter role");

    _mint(_to, _traitCode, _metadataHash, _contentHash);

    return true;
  }

  // ERC721 (public)
  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address tokenOwner = _owners[tokenId];
    require(tokenOwner != address(0), "ERC721: owner query for nonexistent token");
    return tokenOwner;
  }

  function approve(address to, uint256 tokenId) public returns (bool) {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "ERC721: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
    return true;
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "ERC721: approved query for nonexistent token");
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public returns (bool) {
    require(operator != msg.sender, "ERC721: approve to caller");

    _operatorApprovals[msg.sender][operator] = approved;
    emit ApprovalForAll(msg.sender, operator, approved);
    return true;
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(address from, address to, uint256 tokenId) public returns (bool) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
    return true;
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public returns (bool) {
    require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
    return true;
  }

  // ERC721 (private)
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) private {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
  }

  function _exists(uint256 tokenId) private view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) private view returns (bool) {
    require(_exists(tokenId), "ERC721: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }

  function _mint(
    address _to,
    bytes12 _traitCode,
    string memory _metadataHash,
    string memory _contentHash) private {
    
    uint256 tokenId = _allTokens.length + 1;

    require(tokenId > 0, "DebugNft: tokenId should be non-zero");
    require(!_exists(tokenId), "ERC721: token already minted");
    require(_to != address(0), "ERC721: mint to the zero address");

    require(traitCodeIndex[_traitCode] == 0, "DebugNft: same traitCode already minted");

    _beforeTokenTransfer(address(0), _to, tokenId);

    _balances[_to] += 1;
    _owners[tokenId] = _to;
    tokenInfo[tokenId] = TokenInfo(
      _traitCode,
      _metadataHash,
      _contentHash
    );
    traitCodeIndex[_traitCode] = tokenId;

    emit Transfer(address(0), owner, tokenId);
    emit Transfer(owner, _to, tokenId);
  }

  function _burn(uint256 tokenId) private {
    address owner = ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(address from, address to, uint256 tokenId) private {
    require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
    if (isContract(to)) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
        // ??? 要調査
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  // ERC721Metadata
  function tokenURI(uint256 _tokenId) public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked('ipfs://', tokenInfo[_tokenId].metadataHash));
  }

  // ERC721Enumerable (public)
  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
    return _allTokens[index];
  }

  // ERC721Enumerable (private)
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) private {
    if (from == address(0)) {
      _addTokenToAllTokensEnumeration(tokenId);
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      _removeTokenFromAllTokensEnumeration(tokenId);
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    uint256 lastTokenIndex = balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    if (tokenIndex != lastTokenIndex) {
       uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
    uint256 lastTokenIndex = _allTokens.length - 1;
    uint256 tokenIndex = _allTokensIndex[tokenId];

    uint256 lastTokenId = _allTokens[lastTokenIndex];

    _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
    _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

    delete _allTokensIndex[tokenId];
    _allTokens.pop();
  }

  // ERC2981
  function royaltyInfo(uint256 id, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {

    // !!! globalRoyalty
    if(globalRoyalty.value == 0) {
      if (royalties[id].length == 0) {
        receiver = address(0);
        royaltyAmount = 0;
        return(receiver, royaltyAmount);
      }
      LibPart.Part[] memory _royalties = royalties[id];
      receiver = _royalties[0].account;
      uint percent;
      for (uint i = 0; i < _royalties.length; i++) {
        percent += _royalties[i].value;
      }
      royaltyAmount = percent * _salePrice / 10000;
    } else{
      return (globalRoyalty.account, globalRoyalty.value);
    }
  }

  // Rarible
  function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties) internal {
    uint256 totalValue;
    for (uint i = 0; i < _royalties.length; i++) {
      require(_royalties[i].account != address(0x0), "Recipient should be present");
      require(_royalties[i].value != 0, "Royalty value should be positive");
      totalValue += _royalties[i].value;
      royalties[id].push(_royalties[i]);
    }
    require(totalValue < 10000, "Royalty total value should be < 10000");
    _onRoyaltiesSet(id, _royalties);
  }

  function _updateAccount(uint256 _id, address _from, address _to) internal {
    uint length = royalties[_id].length;
    for(uint i = 0; i < length; i++) {
      if (royalties[_id][i].account == _from) {
        royalties[_id][i].account = payable(address(uint160(_to)));
      }
    }
  }

  function getRaribleV2Royalties(uint256 id) external view returns (LibPart.Part[] memory) {
    if(globalRoyalty.value == 0) {
      return royalties[id];
    } else{
      LibPart.Part[] memory _royalties = new LibPart.Part[](1);
      _royalties[0] = globalRoyalty;
      return _royalties;
    }
  }

  function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties) internal {
    emit RoyaltiesSet(id, _royalties);
  }

  function setRoyalties(uint256 _tokenId, address payable _royaltiesRecipentAddress, uint96 _percentageBasisPoints) public onlyOwner returns (bool) {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesRecipentAddress;
    _saveRoyalties(_tokenId, _royalties);
    return true;
  }

  function setGlobalRoyalty(address payable _royaltiesRecipentAddress, uint96 _percentageBasisPoints) public onlyOwner returns (bool) {
    globalRoyalty = LibPart.Part(_royaltiesRecipentAddress, _percentageBasisPoints);
    return true;    
  }

  // Utils
  function isContract(address account) private view returns (bool) {
    uint256 size;
    // extcodesize: アドレス→コードサイズ
    // コードサイズを見てEOAかスマコンかをチェック
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function toString(uint256 value) private pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function getSigner(
    bytes12 _traitCode,
    string memory _metadataHash,
    string memory _contentHash,
    bytes memory _sig) private pure returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(_traitCode, _metadataHash, _contentHash));
    return recover(hash, _sig);
  }

  // 署名の検証・アドレス復元
  // チェーンIDが違うと挙動が変わりそう？
  function recover(bytes32 _hash, bytes memory _sig) public pure returns (address) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      //Check the signature length
      if (_sig.length != 65) {
        return (address(0));
      }

      // Divide the signature in r, s and v variables
      assembly {
        r := mload(add(_sig, 32))
        s := mload(add(_sig, 64))
        v := byte(0, mload(add(_sig, 96)))
      }

      // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
      if (v < 27) {
        v += 27;
      }

      // If the version is correct return the signer address
      if (v != 27 && v != 28) {
        return (address(0));
      } else {
        return ecrecover(_hash, v, r, s);
      }
    }
}