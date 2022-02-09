// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract TestToken is ERC20 {
    uint256 public constant MAX_SUPPLY = uint248(1e14 ether);

    // for DAO.
    uint256 public constant AMOUNT = MAX_SUPPLY;
    address public constant ADDR = 0x44D68832e0A5eB3C8DAc9CfF832F5818C7770CEB;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(ADDR, AMOUNT);
        _totalSupply = AMOUNT;
    }

    function claim(uint256 amount) external {
        uint256 amounttoken = uint248(amount);
        uint256 total = _totalSupply + amounttoken;
        _totalSupply = total;
        _mint(msg.sender, amounttoken);
    }
}