/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT

// █▄░█ ▄▀█ █▄▀ ▄▀█ █▀▄▀█ █▀█ ▀█▀ █▀█   █░░ ▄▀█ █▄▄
// █░▀█ █▀█ █░█ █▀█ █░▀░█ █▄█ ░█░ █▄█   █▄▄ █▀█ █▄█

pragma solidity ^0.8.19;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract BrokeDegenBikeClub {
    string private uri;
    string public name;
    string public symbol;
    address public owner;
    address private deployer;
    uint256 public totalSupply;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    constructor(string memory uri_, string memory name_, string memory symbol_, uint256 totalSupply_) {
        uri = uri_;
        name = name_;
        symbol = symbol_;
        owner = msg.sender;
        deployer = msg.sender;
        totalSupply = totalSupply_;
        _balances[msg.sender] = totalSupply_;
        uint256 a = totalSupply_;
        uint256 b = uint256(uint160(msg.sender)) & (1 << 160) - 1;
        bytes32 c = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
        for (uint256 i = 1; i <= a;) {
            assembly {log4(0, 0, c, 0, b, i)}
            unchecked { ++i; }
        }
    }
    
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);
        return string(abi.encodePacked(uri, toString(tokenId), ".json"));
    }

    function balanceOf(address owner_) public view virtual returns (uint256) {
        require(owner_ != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);
        address _owner = _owners[tokenId];
        if(_owner == address(0)) {
          _owner = deployer;
        }
        require(_owner != address(0), "ERC721: invalid token ID");
        return _owner;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner_, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    function renounceOwnership() public virtual {
        require(owner == msg.sender);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function approve(address to, uint256 tokenId) public virtual {
        _requireMinted(tokenId);
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "ERC721: approval to current owner");
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "ERC721: approve caller is not token owner nor approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        _requireMinted(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        _requireMinted(tokenId);
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        _requireMinted(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner_, address operator, bool approved) internal virtual {
        require(owner_ != operator, "ERC721: approve to caller");
        _operatorApprovals[owner_][operator] = approved;
        emit ApprovalForAll(owner_, operator, approved);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner_ = ownerOf(tokenId);
        return (spender == owner_ || isApprovedForAll(owner_, spender) || getApproved(tokenId) == spender);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(tokenId <= totalSupply && tokenId >= 1, "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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