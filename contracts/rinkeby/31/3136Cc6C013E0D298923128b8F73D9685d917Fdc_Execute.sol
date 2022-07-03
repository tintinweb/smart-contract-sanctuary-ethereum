// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Execute {

    function execute() public returns( bool offset, bytes memory ) {
        bytes memory dataToSend = hex"6080604052348015600f57600080fd5b50603e80601d6000396000f3fe6080604052600080fdfea265627a7a7231582038266ad578d4e92225c15b8843fb6eab963c1463aa51f7a130b8ca820fb1acd964736f6c63430005100032";
        address receiver = payable(0);
        return receiver.call{value:1*10**17, gas: 100000}(dataToSend);  
    }
}