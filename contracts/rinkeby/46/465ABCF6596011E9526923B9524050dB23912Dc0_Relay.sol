// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Testnet: 0x8C2B8825e04A8f24aBDF0E803d5a2Af53Ee32658
// Mainnet: 0x642627dE56a4ba8Dc0c77BcD60C5087Ce3B27e90

contract Relay {
    event b(address buyer, address token, uint256 amount);
    event s(address seller, address token, uint256 amount);
    event l(address user, address token, bool t);
    event n(address token, bool iu, bool t);

    mapping(address=>bool) public admins;
    mapping(address=>bool) public tokens;
    mapping(address=>mapping(address=>bool)) public perms;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(admins[msg.sender], "Forbidden:owner");
        _;
    }

    function allow(address user, bool perm, bool iu) public onlyOwner() {
        admins[user] = perm;
        emit n(user, iu, perm);
    }

    function set(address token, address user, bool perm) public onlyOwner() {
        perms[token][user] = perm;
        emit l(user, token, perm);
    }

    function get(address token, address user) public view returns (bool) {
        return perms[token][user];
    }

    function relay(address token, address user, uint256 amount, bool t) public {
        if (t) {
            emit b(user, token, amount);
        } else {
            emit s(user, token, amount);
        }
    }
}