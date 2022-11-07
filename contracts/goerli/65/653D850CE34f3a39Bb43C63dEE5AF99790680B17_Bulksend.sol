// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IEmployees} from "./IEmployees.sol";

contract Bulksend is IEmployees {
    //Public state variable
    address public owner;
    address tokenAddress;
    IEmployees token;

    constructor() {
        owner = msg.sender;
    }

    //Mapping an address to its balance
    mapping(address => uint) balances;

    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {}

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {}

    //Function to get address of owner
    function getOwner() public view returns (address) {
        return owner;
    }

    //find balance of owner
    function balance() public view returns (uint256) {
        return owner.balance;
    }

    //Function to transfer to many addresses
    function multiTransfer(
        address _tokenAddress,
        address[] calldata _toAddresses,
        uint256[] calldata _amount
    ) external {
        token = IEmployees(_tokenAddress);
        require(_toAddresses.length == _amount.length, "Length inconsistent");
        for (uint i = 0; i < _toAddresses.length; i++) {
            require(token.balanceOf(address(this)) > _amount[i], "ERR 1");
            token.transfer(_toAddresses[i], _amount[i]);
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IEmployees {
    function balanceOf(address _owner) external view returns (uint256);

    function transfer(address to, uint256 value)
        external
        returns (bool);
}