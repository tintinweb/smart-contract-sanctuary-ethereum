/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721Receiver {
  // Checks if contract can receive ERC721 - reverts if not
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}


contract KungFuTigers {
  address public _admin;
  string private _name;
  string private _symbol;

  uint256 public maxSupply = 2000;
  uint256 public mintCount = 1;

  // Cost to mint
  uint256 public mintRate = 0.001 ether;
  uint256 public freeMintCount = 100;

  function changeFreeMintCount(uint256 _count) external isAdmin {
    freeMintCount = _count;
  }

  function changeMintRate(uint256 _price) external isAdmin {
    mintRate = _price;
  }

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _admin = msg.sender;
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721: address zero is not a valid owner");
    return _balances[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  function name() public view returns (string memory) {
    return _name;
  }

  function symbol() public view returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId), ".json")) : "";
  }

  // Set as the directory URL -- each mint URI looks like <uri>/<tokenId>
  function _baseURI() internal pure returns (string memory) {
    return "https://nftstorage.link/ipfs/bafybeicvyvhvx6etc2vvetgrehle66ogxs4swvuvrnr2tmm64mnumskmvi/";
  }

  function safeMint(address to) public payable {
    require(mintCount <= maxSupply, "Can not mint more");
    uint256 tokenId = mintCount;
    if (mintCount <= freeMintCount) {
      _safeMint(to, tokenId);
    } else {
      require(msg.value >= mintRate, "Not enough ether sent");
      _safeMint(to, tokenId);
    }
    mintCount += 1;
  }

  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner, "Approval to current owner");
    require(
      msg.sender == owner || isApprovedForAll(owner, msg.sender),
      "Approve caller is not owner nor approved for all"
    );
    _approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId), "Approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public {
    _setApprovalForAll(msg.sender, operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public {
    require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "Transfer to non ERC721Receiver implementer");
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return _owners[tokenId] != address(0);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
    require(_exists(tokenId), "Operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
  }

  function _safeMint(address to, uint256 tokenId) internal {
    _safeMint(to, tokenId, "");
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      "Transfer to non ERC721Receiver implementer"
    );
  }

  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), "ERC721: mint to the zero address");
    require(!_exists(tokenId), "ERC721: token already minted");
    _balances[to] += 1;
    _owners[tokenId] = to;
    emit Transfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner = ownerOf(tokenId);
    // Clear approvals
    _approve(address(0), tokenId);
    _balances[owner] -= 1;
    delete _owners[tokenId];
    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
    require(to != address(0), "ERC721: transfer to the zero address");

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal {
    require(owner != operator, "ERC721: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (isContract(to)) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("Transfer to non ERC721Receiver implementer");
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

  // ERC165 compliant
  // Tell everyone we support erc1155
  // interfaceId == 0x80ac58cd for erc721
  function supportsInterface(bytes4 interfaceId)
  public
  pure
  virtual
  returns (bool)
  {
    return interfaceId == 0x80ac58cd;
  }

  function isContract(address _addr) private view returns (bool _isContract){
    uint32 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  function toString(uint256 value) internal pure returns (string memory) {
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

  modifier isAdmin() {
    require(tx.origin == msg.sender, "Sender not admin");
    require(msg.sender == _admin, "Sender not admin");
    _;
  }

  function withdraw() public isAdmin {
    require(address(this).balance > 0, "Balance is 0");
    payable(_admin).transfer(address(this).balance);
  }

  receive() external payable {}
}