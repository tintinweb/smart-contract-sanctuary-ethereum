/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Strings {

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

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);


    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event NFT(uint256 indexed tokenId, address indexed owner, string indexed image);


    function balanceOf(address owner) external view returns (uint256 balance);

     function ownerOf(uint256 tokenId) external view returns (address owner);

    function mint(string memory picture
    ) external;

    function transfer(
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

}
interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function tokenURI(uint256 tokenId) external view returns (address);
}
contract ERC721 is IERC721,IERC721Metadata {
    using Strings for uint256;

    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;

    struct nfts {
        uint256 key;
        address owner;
        string image;
    }

    mapping(uint256 => nfts)  private _nfts;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;
     constructor(string memory name_, string memory symbol_,uint256 decimals) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals;

        emit Transfer(msg.sender, msg.sender,0);
    }
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

     function ownerOf(uint256 tokenId) public view override returns (address) {
         address owner = _nfts[tokenId].owner;
         require(owner != address(0), "ERC721: owner query for nonexistent token");
         return owner;
     }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
     function tokenURI(uint256 tokenId) public view virtual override returns (address) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

         return _nfts[tokenId].owner;
     }

     function _baseURI() internal view virtual returns (string memory) {
        return "https://www.imgonline.com.ua/examples/bee-on-daisy.jpg";
    }

     function approve(address to, uint256 tokenId) public virtual override {
         address owner = ERC721.ownerOf(tokenId);
         require(to != owner, "ERC721: approval to current owner");

         require(
             msg.sender == owner || isApprovedForAll(owner, msg.sender),
             "ERC721: approve caller is not owner nor approved for all"
         );

         _approve(to, tokenId);
     }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function mint(string memory picture) public virtual override {
        _mint(picture);
    }
    function transfer(
        address to,
        uint256 tokenId
    ) public virtual override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(msg.sender, to, tokenId);
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function _mint(string memory picture) internal {
        uint256 tokenId = _totalSupply + 1;
        require(!_exists(tokenId), "ERC721: token already minted");
    
         _beforeTokenTransfer(address(0), msg.sender, tokenId);
         _totalSupply = _totalSupply + 1;
        _nfts[tokenId] = nfts(tokenId, address(this), picture);

        emit Transfer(address(0), address(this), tokenId);

         _afterTokenTransfer(address(0), msg.sender, tokenId);
    }

     function _burn(uint256 tokenId) internal virtual {
         address owner = ERC721.ownerOf(tokenId);

         _beforeTokenTransfer(owner, address(0), tokenId);

         _approve(address(0), tokenId);

         _balances[owner] -= 1;
          delete _nfts[tokenId];

         emit Transfer(owner, address(0), tokenId);

         _afterTokenTransfer(owner, address(0), tokenId);
     }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _nfts[tokenId].key != 0;
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
         require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
         require(to != address(0), "ERC721: transfer to the zero address");

         _beforeTokenTransfer(from, to, tokenId);

         _approve(address(0), tokenId);

         _balances[from] -= 1;
         _balances[to] += 1;
        _nfts[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

       _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

     function _beforeTokenTransfer(
         address from,
         address to,
         uint256 tokenId
     ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

}