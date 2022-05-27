/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721Token {
    function balanceOf(address) external returns (uint256);
    function ownerOf(uint256) external returns (address);
    function safeTransferFrom(address, address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function approve(address, uint256) external;
    function getApproved(address, uint256) external returns (address);
    function setApprovalForAll(address, bool) external;
    function isApprovedForAll(address, address) external returns (bool);
    function safeTransferFrom(address, address, uint256, bytes memory) external;
}

interface IERC721TokenReceiver {
    function onERC721Received(
        address, address, uint256, bytes memory
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4) external returns (bool);
}

contract my_ERC721_Token {
    string private _name;
    function name() public view returns (string memory) {
        return _name;
    }
    string private _symbol;
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    constructor(
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;

        supportedInterfaces[type(IERC165).interfaceId] = true;
        supportedInterfaces[type(IERC721Token).interfaceId] = true;

        _tokenCounter = 0;
        _minter = msg.sender;
    }

    mapping(address => uint256) private _balances;
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0));
        return _balances[account];
    }

    mapping(uint256 => address) private _owners;
    function ownerOf(uint256 tokenID) public view returns (address) {
        address account = _owners[tokenID];
        require(account != address(0));
        return account;
    }

    event Transfer(address, address, uint256);
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    function checkSafeTransfer(
        address operator, 
        address from, 
        address to, 
        uint256 tokenID, 
        bytes memory data
    ) private {
        bytes4 magic = IERC721TokenReceiver(to).onERC721Received(
            operator, from, tokenID, data
        );
        require(magic == bytes4(keccak256(
            "onERC721Received(address,address,uint256,bytes)")
        ));
    }
    function safeTransferFrom(
        address from, address to, uint256 tokenID, bytes memory data
    ) public {
        _transferFrom(from, to, tokenID);
        if (isContract(to))
            checkSafeTransfer(msg.sender, from, to, tokenID, data);
        emit Transfer(from, to, tokenID);
    }

    function safeTransferFrom(address from, address to, uint256 tokenID) public {
        safeTransferFrom(from, to, tokenID, "");
    }

    function transferFrom(address from, address to, uint256 tokenID) public {
        _transferFrom(from, to, tokenID);
        emit Transfer(from, to, tokenID);
    }

    function _transferFrom(address from, address to, uint256 tokenID) private {
        require(from != address(0));
        require(to != address(0));

        require(from == ownerOf(tokenID));
        require(
            msg.sender == from ||
            msg.sender == getApproved(tokenID) ||
            isApprovedForAll(from, msg.sender)
        );
        
        _balances[from]--;
        _balances[to]++;
        _owners[tokenID] = to;

        approve(address(0), tokenID);
    }

    mapping (uint256 => address) _approved;
    event Approval(address, address, uint256);
    function approve(address approved, uint256 tokenID) public {
        address owner = ownerOf(tokenID);
        require(
            msg.sender == owner ||
            isApprovedForAll(owner, msg.sender)
        );

        _approved[tokenID] = approved;
        emit Approval(owner, approved, tokenID);
    }

    mapping (address => mapping (address => bool)) _isOperator;
    event ApprovalForAll(address, address, bool);
    function setApprovalForAll(address operator, bool approved) public {
        _isOperator[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenID) public view returns (address) {
        require(ownerOf(tokenID) != address(0));
        return _approved[tokenID];
    }

    function isApprovedForAll(
        address owner, address operator
    ) public view returns (bool) {
        return _isOperator[owner][operator];
    }

    mapping (bytes4 => bool) private supportedInterfaces;
    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return supportedInterfaces[interfaceID];
    }

    mapping (uint256 => string) _uris;
    function _exists(uint256 tokenID) private view returns (bool) {
        return (_owners[tokenID] != address(0));
    }
    function tokenURI(uint256 tokenID) public view returns (string memory) {
        require(_exists(tokenID));
        return _uris[tokenID];
    }

    uint256 private _tokenCounter;
    address private _minter;
    function mint(address to, string memory _tokenURI) public {
        require(msg.sender == _minter);
        require(to != address(0));

        uint tokenID = _tokenCounter++;
        _owners[tokenID] = to;
        _uris[tokenID] = _tokenURI;
        _balances[to]++;

        emit Transfer(address(0), to, tokenID);
    }
}