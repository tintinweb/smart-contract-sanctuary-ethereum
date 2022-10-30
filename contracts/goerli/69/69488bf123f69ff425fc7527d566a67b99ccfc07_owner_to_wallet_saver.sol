pragma solidity ^0.8.0;

contract owner_to_wallet_saver {
    mapping(address => address) public mapping_owner_to_wallet_saver;

    function add_pair(address owner_address, address wallet_address) public {
        mapping_owner_to_wallet_saver[owner_address] = wallet_address;
    }
}