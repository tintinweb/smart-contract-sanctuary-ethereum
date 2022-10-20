pragma solidity ^0.8.13;

import "../registry/IRegistryConsumer.sol";


contract lookup_contract {

    RegistryConsumer           reg = RegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);

    mapping(address => address) lookups;

    error ContractNameNotInitialised(string contract_name);
    error ContractInfoNotInitialised();

    function find_contract(string memory contract_name) external returns (address) {
        address adr = reg.getRegistryAddress(contract_name);
        if (adr == address(0)) revert ContractNameNotInitialised(contract_name);
        lookups[msg.sender] = adr;
        return adr;
    }

    function lookup() external view returns (address) {
        address adr = lookups[msg.sender];
        if (adr == address(0)) revert ContractInfoNotInitialised();
        return adr;
    }
}

pragma solidity ^0.8.13;

interface RegistryConsumer {

    function getRegistryAddress(string memory key) external view returns (address) ;

    function getRegistryBool(string memory key) external view returns (bool);

    function getRegistryUINT(string memory key) external view returns (uint256) ;

    function getRegistryString(string memory key) external view returns (string memory) ;

    function isAdmin(address user) external view returns (bool) ;

    function isAppAdmin(address app, address user) external view returns (bool);

}