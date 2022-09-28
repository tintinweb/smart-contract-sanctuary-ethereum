// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "../interfaces/IERC20.sol";
import "../libraries/libERC20.sol";

contract ERC20V2Facet {
    ERC20Storage internal store;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function burn(uint256 amount) external {
        store.balanceOf[msg.sender] -= amount;
        store.totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

    function name() external view returns (string memory) {
        return store.name;
    }

    function symbol() external view returns (string memory) {
        return store.symbol;
    }

    function decimals() external view returns (uint8) {
        return store.decimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ERC20Storage {
    uint256 totalSupply;
    mapping(address => mapping(address => uint256)) allowance;
    mapping(address => uint256) balanceOf;
    string name;
    string symbol;
    uint8 decimals;
}