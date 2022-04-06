/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract StoreKeys {

    address public owner;

    mapping(address => uint256) public totalCount;
    mapping(address => mapping(string => string)) private _storeBox;

    constructor() {
        owner = msg.sender;
    }

    event Store(address _from, string _account);

    // create
    function store(string memory account, string memory priv) external {
        _storeBox[msg.sender][account] = priv;
        totalCount[msg.sender] += 1;
        emit Store(msg.sender, account);
    }

    // search
    function getUserItem(string memory _account) external view returns(string memory) {
        return _storeBox[msg.sender][_account];
    }

    // update
    function updatePrivByAccount(string memory account, string memory priv) external {
        _storeBox[msg.sender][account] = priv;
    }

    // delete
    function deleteItem(string memory account) external {
        delete _storeBox[msg.sender][account];
        totalCount[msg.sender] -= 1;
    }

}