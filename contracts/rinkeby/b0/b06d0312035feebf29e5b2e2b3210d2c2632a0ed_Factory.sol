// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Address.sol";
import "./NSIMidWallet.sol";

contract Factory is AccessControl{
    using Address for address;

    bytes32 constant public OWNER_ROLE = keccak256("Owner ");
    bytes32 constant public ADMIN_ROLE = keccak256("Admin ");
    bytes32 constant public TRADER_ROLE = keccak256("Trader ");

    //owner => midWallet
    mapping(address => address) public owners;

    modifier onlyAdmin(){
        require(hasRole(ADMIN_ROLE, msg.sender), "Just Admin!");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(OWNER_ROLE, tx.origin);
    }

    function createFor(address owner) public returns(address created){
        if (owners[owner] != address(0)) {
            return owners[owner];
        }
        address ret = address(new MidWallet(
            owner
        ));
        owners[owner] = ret;
        return ret;
    }

    function addTrader(address addr) public onlyAdmin{
        _setupRole(TRADER_ROLE, addr);
    }
}