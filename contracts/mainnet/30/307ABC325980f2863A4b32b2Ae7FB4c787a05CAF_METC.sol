// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract METC is ERC20 {
    address public admin;

    mapping(address => bool) public minters;

    event NewAdmin(address indexed newAdmin);
    event NewMinter(address indexed newMinter, bool isMinter);

    constructor(
        address newAdmin,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        admin = newAdmin;
        minters[admin] = true;
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "admin");
        admin = newAdmin;

        emit NewAdmin(admin);
    }

    function setMinter(address newMinter) external {
        require(msg.sender == admin, "admin");

        minters[newMinter] = !minters[newMinter];

        emit NewMinter(newMinter, minters[newMinter]);
    }

    function mint(address to, uint amount) external {
        require(minters[msg.sender], "minter");
        _mint(to, amount);
    }

    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}