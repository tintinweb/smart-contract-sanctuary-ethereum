// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.7;

error Attack__TransferFailed();

contract Attack {
    constructor(address payable contractAddress) payable {
        (bool success, ) = contractAddress.call{value: msg.value}("");
        if (!success) {
            revert Attack__TransferFailed();
        }
    }
}