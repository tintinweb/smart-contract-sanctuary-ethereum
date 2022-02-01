//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./BaseRelayRecipient.sol";

contract Greeter is BaseRelayRecipient {
    address public sender;

    constructor() {
        // _trustedForwarder = 0xeB230bF62267E94e657b5cbE74bdcea78EB3a5AB; // OpenGSN tBSC
        // _trustedForwarder = 0x61456BF1715C1415730076BB79ae118E806E74d2; // Biconomy tBSC
        _trustedForwarder = 0x83A54884bE4657706785D7309cf46B58FE5f6e8a; // OpenGSN Rinkeby
    }

    function trustedForwarder() external view returns (address) {
        return _trustedForwarder;
    }

    function setSender() external {
        sender = _msgSender();
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity ^0.8.0;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address internal _trustedForwarder;

    function _isTrustedForwarder(address forwarder) internal view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view returns (address payable ret) {
        if (msg.data.length >= 20 && _isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = payable(msg.sender);
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && _isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}