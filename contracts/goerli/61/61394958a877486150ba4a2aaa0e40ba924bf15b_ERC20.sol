/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {
    // erc1155
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );


    event Transfer(address indexed from, address indexed to, uint256 value);
    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor() {
        _name = "MyToken_1155";
        _symbol = "MTK";
        _totalSupply = 100000;
        _balances[msg.sender] = 1000000;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return 3;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _balances[to] += amount;
        // emit Transfer(msg.sender, to, amount);//erc20
        emit Transfer(msg.sender, to, amount);//erc721
        return true;
    }

    function transfer_1(address to, uint256 amount) public returns (bool) {
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);//erc20
        // emit Transfer(msg.sender, to, amount);//erc721
        return true;
    }

    function transfer_2(address to, uint256 amount) public returns (bool) {
        _balances[to] += amount;
        // emit Transfer(msg.sender, to, amount);//erc20
        emit Transfer(msg.sender, to, amount);//erc721
        return true;
    }

    //
    function transfer_1155(uint256[] memory ids, uint256[] memory amounts) public returns (bool) {
        emit TransferBatch(msg.sender, msg.sender, msg.sender, ids, amounts);
        return true;
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        emit TransferBatch(from, to, msg.sender, ids, amounts);
    }
}