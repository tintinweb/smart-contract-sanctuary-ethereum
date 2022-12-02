/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/////////////////////////////////
//                             //
//                             //
//                             //
//                             //
//                             //
//              N.             //
//              —              //
//             0xG             //
//                             //
//                             //
//                             //
//                             //
/////////////////////////////////

contract N {
  uint public tokenId;
  mapping(address => uint) public collectors;
  address _owner;
  address _tokenOwner;
  string _uri;

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  constructor() { _owner = msg.sender; }

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return (
      interfaceId == /* IERC721 */ 0x80ac58cd ||
      interfaceId == /* IERC721Metadata */ 0x5b5e139f ||
      interfaceId == /* IERC165 */ 0x01ffc9a7
    );
  }

  function ownerOf(uint256 _tokenId) public view virtual returns (address) {
    require(_tokenId == 0 || _tokenId == tokenId, "ERC721: invalid token ID");
    return _tokenOwner;
  }

  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "ERC721: address zero is not a valid owner");
    return owner == _tokenOwner ? 1 : 0;
  }

  function mint() external {
    if (tokenId != 0) {
      // Burn it.
      emit Transfer(_tokenOwner, address(0), tokenId);
    } else {
      require(msg.sender == _owner, "N.ot yet");
    }
    _tokenOwner = msg.sender;
    tokenId += 1;
    collectors[msg.sender] = tokenId;
    emit Transfer(address(0), msg.sender, tokenId);
  }

  function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {
    require(_tokenId == tokenId, "ERC721: invalid token ID");

    return string(
      abi.encodePacked(
        "data:application/json;utf8,",
        '{"name":"N. #',toString(tokenId),'","created_by":"0xG","description":"","image":"',
        bytes(_uri).length > 0 ? _uri : 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBzdGFuZGFsb25lPSJ5ZXMiPz4KPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMDAwIDEwMDAiIHN0eWxlPSJ3aWR0aDogMTAwdmg7IGhlaWdodDogMTAwdmg7IG1heC13aWR0aDogMTAwJTsgbWF4LWhlaWdodDogMTAwJTsgbWFyZ2luOiBhdXRvIj4KICA8IS0tIE4uIOKAkyDCqSAweEcgLS0+CiAgPGRlZnM+CiAgICA8bGluZWFyR3JhZGllbnQgaWQ9IjB4R19iZyIgeDE9IjAlIiB5MT0iMCUiIHgyPSIwJSIgeTI9IjEwMCUiPgogICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMTExIiAvPgogICAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiMwMDAiIC8+CiAgICA8L2xpbmVhckdyYWRpZW50PgogICAgPGxpbmVhckdyYWRpZW50IGlkPSIweEdfbCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIwJSIgeTI9IjEwMCUiPgogICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMDAwIiAvPgogICAgICA8c3RvcCBvZmZzZXQ9IjEwMCUiIHN0b3AtY29sb3I9IiMwMDAiIHN0b3Atb3BhY2l0eT0iMCIgLz4KICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICA8ZmlsdGVyIGlkPSIweEdfbm9pc2UiPgogICAgICA8ZmVUdXJidWxlbmNlIHR5cGU9ImZyYWN0YWxOb2lzZSIgYmFzZUZyZXF1ZW5jeT0iNSIgbnVtT2N0YXZlcz0iMyIgc3RpdGNoVGlsZXM9InN0aXRjaCIgLz4KICAgICAgPGZlQ29sb3JNYXRyaXggdHlwZT0ic2F0dXJhdGUiIHZhbHVlcz0iMCIgLz4KICAgICAgPGZlQ29tcG9uZW50VHJhbnNmZXI+CiAgICAgICAgPGZlRnVuY1IgdHlwZT0ibGluZWFyIiBzbG9wZT0iMC41IiAvPgogICAgICAgIDxmZUZ1bmNHIHR5cGU9ImxpbmVhciIgc2xvcGU9IjAuNSIgLz4KICAgICAgICA8ZmVGdW5jQiB0eXBlPSJsaW5lYXIiIHNsb3BlPSIwLjUiIC8+CiAgICAgIDwvZmVDb21wb25lbnRUcmFuc2Zlcj4KICAgICAgPGZlQmxlbmQgbW9kZT0ic2NyZWVuIiAvPgogICAgPC9maWx0ZXI+CiAgPC9kZWZzPgogIDxyZWN0IHdpZHRoPSIxMDAwIiBoZWlnaHQ9IjEwMDAiIGZpbGw9InVybCgjMHhHX2JnKSIgLz4KICA8cmVjdCBoZWlnaHQ9IjUwMCIgd2lkdGg9IjUwMCIgeT0iMjUwIiB4PSIyNTAiIGZpbGw9InVybCgjMHhHX2wpIiAgLz4KICA8cmVjdCB3aWR0aD0iMTAwMCIgaGVpZ2h0PSIxMDAwIiBmaWx0ZXI9InVybCgjMHhHX25vaXNlKSIgb3BhY2l0eT0iMC4xIi8+Cjwvc3ZnPgo=',
        '"}'
      )
    );
  }

  function name() public view virtual returns (string memory) {
    return "N.";
  }

  function symbol() public view virtual returns (string memory) {
    return "N";
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner {
    require(msg.sender == _owner, "Unauthorized");
    _;
  }

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function transferOwnership(address _new) external virtual onlyOwner {
    address _old = _owner;
    _owner = _new;
    emit OwnershipTransferred(_old, _new);
  }

  function setUri(string calldata _new) external onlyOwner {
    _uri = _new;
  }

  // Taken from "@openzeppelin/contracts/utils/Strings.sol";
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
}