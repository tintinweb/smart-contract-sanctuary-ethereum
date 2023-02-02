// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "minter.sol";

contract BridgeMinter{
    address private notary;
    address private approver;
    address private tokenAddress;
    bool private bridging;
    uint256 private chainId;
    bytes32 private domainSeparator;

    mapping(bytes32 => bool) private nonces;

    event Bridged(address receiver, uint256 amount);
    event TransferOwnership(address indexed owner, bool indexed confirmed);

    constructor(address _approver, address _notary, address _tokenAddress, uint256 _chainId){
        require(_approver != address(0));     // dev: invalid approver
        require(_notary != address(0));       // dev: invalid notary
        require(_tokenAddress != address(0)); // dev: invalid notary
        approver = _approver;
        notary = _notary;
        tokenAddress = _tokenAddress;
        chainId = _chainId;

        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId)"),
                keccak256("Neptune Bridge"), 
                keccak256("0.0.1"), 
                _chainId
            )
        );
    }

    modifier checkNonce(bytes32 nonce) {
        require(nonces[nonce]==false); // dev: already processed
        _;
    }

    function bridge(address sender, uint256 bridgedAmount, bytes32 nonce, bytes32 messageHash, bytes calldata approvedMessage, bytes calldata notarizedMessage) 
    external checkNonce(nonce){
        require(bridging == false);                                                //dev: re-entrancy guard
        bridging = true;
        bytes32 hashToVerify = keccak256(
            abi.encode(keccak256("SignedMessage(bytes32 key,address sender,uint256 amount)"),nonce,sender,bridgedAmount)
        );

        require(checkEncoding(approvedMessage,messageHash,hashToVerify,approver)); //dev: invalid signature
        require(checkEncoding(notarizedMessage,messageHash,hashToVerify,notary));  //dev: invalid signature
        nonces[nonce]=true;

        IMinter(tokenAddress).mint(sender, bridgedAmount);

        emit Bridged(sender, bridgedAmount);
        bridging = false;
    }

    function checkEncoding(bytes memory signedMessage,bytes32 messageHash, bytes32 hashToVerify, address signer) 
    internal view returns(bool){

        bytes32 domainSeparatorHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashToVerify));
        require(messageHash == domainSeparatorHash); //dev: values do not match

        return signer == recoverSigner(messageHash, signedMessage);
    }

    function splitSignature(bytes memory sig)
    internal pure returns (uint8 v, bytes32 r, bytes32 s){
        require(sig.length == 65); // dev: signature invalid

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
    internal pure returns (address){
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return tryRecover(message, v, r, s);
    }

    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    internal 
    pure 
    returns (address) {
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        } else if (v != 27 && v != 28) {
            return address(0);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return address(0);
        }

        return signer;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.10;

/**
 * @dev Interface of to mint ERC20 tokens.
 */
interface IMinter {
    function mint(address to, uint256 value) external;
}