pragma solidity ^0.8.13;

import "../registry/IRegistryConsumer.sol";

interface hookey {

    function Process(bytes memory data) external;
}


contract hook {

    RegistryConsumer reg = RegistryConsumer(0x1e8150050A7a4715aad42b905C08df76883f396F);
 
    function TJHooker(string memory key, bytes memory data) external {
        hookey hookAddress = hookey(reg.getRegistryAddress(key));
        if (address(hookAddress) == address(0)) return;
        hookAddress.Process(data);
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