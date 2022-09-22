// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract SimpleRegistry {
    event Registered(address indexed who, string name);

    error NeedNameToken(string);

    mapping (address => string) public names;
    mapping (string => address) public owners;

    function register(string memory name) external {
        if (owners[name] != address(0)) {
            revert NeedNameToken("Name token");
        }

        address owner = msg.sender;
        owners[name] = owner;
        names[owner] = name;

        emit Registered(owner, name);
    }
}