// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;


contract L2_PolygonMessengerProxy {

    function sendCrossDomainMessage() public returns (bytes memory) {
        bytes memory message = abi.encodeWithSignature("setAmmWrapper(address)", '0x8ed4Cda3195C24F6F1E2b9784c6787b247CCFecE');
        return message;
    }
}