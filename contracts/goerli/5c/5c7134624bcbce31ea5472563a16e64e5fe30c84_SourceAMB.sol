pragma solidity 0.8.14;
pragma experimental ABIEncoderV2;

contract SourceAMB {
    mapping(uint256 => bytes32) public messages;
    uint256 public nonce;
    uint256 chainId;

    event SentMessage(uint256 indexed nonce, bytes32 indexed msgHash, bytes message);

    constructor() {
        nonce = 0;
        chainId = block.chainid;
    }

    function send(address recipient, uint16 recipientChainId, uint256 gasLimit, bytes calldata data)
        external
        returns (bytes32)
    {
        bytes memory message =
            abi.encode(nonce, msg.sender, recipient, recipientChainId, gasLimit, data);
        bytes32 messageRoot = keccak256(message);
        messages[nonce] = messageRoot;
        emit SentMessage(nonce++, messageRoot, message);
        return messageRoot;
    }
}