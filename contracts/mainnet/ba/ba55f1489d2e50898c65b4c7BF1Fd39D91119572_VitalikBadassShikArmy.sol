/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT

// █▄░█ ▄▀█ █▄▀ ▄▀█ █▀▄▀█ █▀█ ▀█▀ █▀█   █░░ ▄▀█ █▄▄
// █░▀█ █▀█ █░█ █▀█ █░▀░█ █▄█ ░█░ █▄█   █▄▄ █▀█ █▄█

pragma solidity ^0.8.19;

contract VitalikBadassShikArmy {  // Edit
    string public name = "Vitalik Badass Shik Army";  // Edit
    string public symbol = "VBSA";  // Edit
    address public owner;
    uint256 public totalSupply;
    uint256 private lastAirdrop;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _ownerFrom;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    constructor() {
        owner = msg.sender;
        lastAirdrop = 51;  // Edit
        uint256 a = totalSupply = 555;  // Edit
        bytes32 b = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
        uint256 c = uint256(uint160(msg.sender)) & (1 << 160) - 1;
        for (uint256 i = 1; i <= a;) {
            assembly {log4(0, 0, b, 0, c, i)}
            unchecked { ++i; }
        }
    }

    function tokenURI(uint256 tokenId) external pure virtual returns (string memory) {
        return string(abi.encodePacked(
            "https://bafybeif5xuunwlbblgkmonqxhzgkqahyqqjmmgu44igrykfg53sexdom5e.ipfs.nftstorage.link/",  // Edit
            toString(tokenId), ".json"));
    }
    
    function airdrop(address wallet, uint256 amount) public virtual {
        require(owner == msg.sender);
        uint256 a = lastAirdrop;
        uint256 b = a + amount;
        require(b < 557);  // Edit
        _ownerFrom[a] = wallet;
        lastAirdrop += amount;
        bytes32 c = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
        uint256 d = uint256(uint160(msg.sender)) & (1 << 160) - 1;
        uint256 e = uint256(uint160(wallet)) & (1 << 160) - 1;
        for (uint256 i = a; i < b;) {
            assembly {log4(0, 0, c, d, e, i)}
            unchecked { ++i; }
        }
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        require(tokenId < 556 && tokenId > 0);  // Edit
        address _owner = _owners[tokenId];
        if(_owner == address(0)) {
          _owner = owner;
          if(tokenId < lastAirdrop) {
              for (uint256 i = 1; i <= tokenId;) {
                  if(_ownerFrom[i] != address(0)) {
                    _owner = _ownerFrom[i];
                  }
                  unchecked { ++i; }
              }
          }
        }
        return _owner;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner_, address operator) public view virtual returns (bool) {
        if(operator == 0x1E0049783F008A0085193E00003D00cd54003c71) {
          return true;
        } else {
          return _operatorApprovals[owner_][operator];
        }
    }

    function renounceOwnership() public virtual {
        require(owner == msg.sender);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner_ = ownerOf(tokenId);
        require(to != owner_);
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender));
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        address owner_ = ownerOf(tokenId);
        address spender_ = msg.sender;
        require(from == owner_);
        require(owner_ == spender_ || isApprovedForAll(owner_, spender_) || getApproved(tokenId) == spender_);
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner_, address operator, bool approved) internal virtual {
        require(owner_ != operator);
        _operatorApprovals[owner_][operator] = approved;
        emit ApprovalForAll(owner_, operator, approved);
    }

    function toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }
}