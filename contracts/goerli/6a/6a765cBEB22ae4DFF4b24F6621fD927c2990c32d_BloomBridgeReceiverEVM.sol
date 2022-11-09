// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract BloomBridgeReceiverEVM {
    address private constant CALL_PROXY_ADDRESS =
        0xD2b88BA56891d43fB7c108F23FE6f92FEbD32045;
    address private destination;
    event NewMsg(string msg);

    function anyExecute(bytes memory _data)
        external
        returns (bool success, bytes memory result)
    {
        string memory _msg = abi.decode(_data, (string));
        emit NewMsg(_msg);
        success = true;
        result = "";
    }
}