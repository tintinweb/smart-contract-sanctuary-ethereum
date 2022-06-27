/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract UniDirectionalPayment {
    address payable public sender;
    address payable public receiver;

    uint public immutable timeLimit;
    uint public expiresAt;

    constructor(address payable _receiver, uint _timeLimit) payable {
        sender = payable(msg.sender);
        receiver = _receiver;
        timeLimit = _timeLimit;
        expiresAt = block.timestamp + _timeLimit;
    }

    function getMessageHash(string memory _message) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthSignedMessageHash(bytes32 _message) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    }

    function recover(bytes32 _getEthSignedMessage, bytes memory _sig) public pure returns(address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        return ecrecover(_getEthSignedMessage, v, r, s);
    }

    function _split(bytes memory _sig) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65);

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0,mload(add(_sig, 96)))
        }
    }

    function verifySignature(string memory _message, bytes memory _sign) public view returns(bool) {
        bytes32 message = getMessageHash(_message);
        bytes32 getEthSignedMessage = getEthSignedMessageHash(message);

        return recover(getEthSignedMessage, _sign) == sender;
    }

    function withdrawAndClose(string memory _message, bytes memory _signature) external payable {
        require(msg.sender == receiver, "Not Receiver");
        require(block.timestamp < expiresAt, "Already Expired");
        require(verifySignature(_message, _signature), "Invalid signature");

        (bool success, ) = receiver.call{value: msg.value}("");
        require(success, "Transaction Failed!");
        selfdestruct(sender);
    }

    function cancel() external {
        require(msg.sender == sender, "Not Contract Owner");
        require(block.timestamp > expiresAt, "Not yet expired");
        selfdestruct(sender);
    }
}