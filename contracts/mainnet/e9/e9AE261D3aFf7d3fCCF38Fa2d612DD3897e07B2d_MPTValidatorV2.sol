// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "./LayerZeroPacket.sol";
import "./Buffer.sol";
import "./ILayerZeroValidationLibrary.sol";
import "./UltraLightNodeEVMDecoder.sol";

contract MPTValidatorV2 is ILayerZeroValidationLibrary {
    using RLPDecode for RLPDecode.RLPItem;
    using RLPDecode for RLPDecode.Iterator;
    using Buffer for Buffer.buffer;
    using SafeMath for uint;

    bytes32 public constant PACKET_SIGNATURE = 0xe8d23d927749ec8e512eb885679c2977d57068839d8cca1a85685dbbea0648f6;

    struct ULNLog{
        bytes32 contractAddress;
        bytes32 topicZeroSig;
        bytes data;
    }

    function validateProof(bytes32 _receiptsRoot, bytes calldata _transactionProof, uint _remoteAddressSize) external pure override returns (LayerZeroPacket.Packet memory packet) {
        (uint16 remoteChainId, bytes[] memory proof, uint[] memory receiptSlotIndex, uint logIndex) = abi.decode(_transactionProof, (uint16, bytes[], uint[], uint));

        ULNLog memory log = _getVerifiedLog(_receiptsRoot, receiptSlotIndex, logIndex, proof);
        require(log.topicZeroSig == PACKET_SIGNATURE, "ProofLib: packet not recognized"); //data

        return _getPacket(log.data, remoteChainId, _remoteAddressSize, log.contractAddress);
    }

    function _getVerifiedLog(bytes32 hashRoot, uint[] memory paths, uint logIndex, bytes[] memory proof) internal pure returns(ULNLog memory) {
        require(paths.length == proof.length, "ProofLib: invalid proof size");

        RLPDecode.RLPItem memory item;
        bytes memory proofBytes;

        for (uint i = 0; i < proof.length; i++) {
            proofBytes = proof[i];
            require(hashRoot == keccak256(proofBytes), "ProofLib: invalid hashlink");
            item = RLPDecode.toRlpItem(proofBytes).safeGetItemByIndex(paths[i]);
            if (i < proof.length - 1) hashRoot = bytes32(item.toUint());
        }

        // burning status + gasUsed + logBloom
        RLPDecode.RLPItem memory logItem = item.typeOffset().safeGetItemByIndex(3);
        RLPDecode.Iterator memory it =  logItem.safeGetItemByIndex(logIndex).iterator();
        ULNLog memory log;
        log.contractAddress = bytes32(it.next().toUint());
        log.topicZeroSig = bytes32(it.next().getItemByIndex(0).toUint());
        log.data = it.next().toBytes();

        return log;
    }

    // profiling and test
    function getVerifyLog(bytes32 hashRoot, uint[] memory receiptSlotIndex, uint logIndex, bytes[] memory proof) external pure returns(ULNLog memory){
        return _getVerifiedLog(hashRoot, receiptSlotIndex, logIndex, proof);
    }

    function getPacket(bytes memory data, uint16 srcChain, uint sizeOfSrcAddress, bytes32 ulnAddress) external pure returns(LayerZeroPacket.Packet memory) {
        return _getPacket(data, srcChain, sizeOfSrcAddress, ulnAddress);
    }

    function _getPacket(
        bytes memory data,
        uint16 srcChain,
        uint sizeOfSrcAddress,
        bytes32 ulnAddress
    ) internal pure returns (LayerZeroPacket.Packet memory) {
        uint16 dstChainId;
        address dstAddress;
        uint size;
        uint64 nonce;

        // The log consists of the destination chain id and then a bytes payload
        //      0--------------------------------------------31
        // 0   |  destination chain id
        // 32  |  defines bytes array
        // 64  |
        // 96  |  bytes array size
        // 128 |  payload
        assembly {
            dstChainId := mload(add(data, 32))
            size := mload(add(data, 96)) /// size of the byte array
            nonce := mload(add(data, 104)) // offset to convert to uint64  128  is index -24
            dstAddress := mload(add(data, sub(add(128, sizeOfSrcAddress), 4))) // offset to convert to address 12 -8
        }

        Buffer.buffer memory srcAddressBuffer;
        srcAddressBuffer.init(sizeOfSrcAddress);
        srcAddressBuffer.writeRawBytes(0, data, 136, sizeOfSrcAddress); // 128 + 8

        uint payloadSize = size.sub(20).sub(sizeOfSrcAddress);
        Buffer.buffer memory payloadBuffer;
        payloadBuffer.init(payloadSize);
        payloadBuffer.writeRawBytes(0, data, sizeOfSrcAddress.add(156), payloadSize); // 148 + 8
        return LayerZeroPacket.Packet(srcChain, dstChainId, nonce, dstAddress, srcAddressBuffer.buf, ulnAddress, payloadBuffer.buf);
    }
}