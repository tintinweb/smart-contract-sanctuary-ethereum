// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.10 <0.9.0;

import "./RLPReader.sol";

contract Honeypot {

    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    struct EnclaveData {
        bytes sgx_report;
        bytes ias_sig;
    }

    address public owner;
    uint public bounty;
    bool public claimed;

    mapping (address => bool) public enclaveRequested;
    mapping (address => bool) public enclaveApproved;
    mapping (address => EnclaveData) public enclaveData;


    event BountyClaimed(address winner);


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    constructor() payable public {
        owner = msg.sender;
        bounty = msg.value;
    }

    function submitEnclave(address enclaveAddr, bytes memory sgxReport, bytes memory iasSig) public {
        require(!enclaveRequested[enclaveAddr], "address already requested");
        require(!enclaveApproved[enclaveAddr], "address already approved");
        require(sgxReport.length > 0, "empty sgx_report");
        require(iasSig.length > 0, "empty ias_sig");

        enclaveData[enclaveAddr] = EnclaveData(sgxReport, iasSig);
        enclaveRequested[enclaveAddr] = true;
    }

    function approveEnclave(address enclaveAddr) public onlyOwner {
        require(enclaveRequested[enclaveAddr], "address not requested");
        require(!enclaveApproved[enclaveAddr], "address already approved");

        enclaveRequested[enclaveAddr] = false;
        enclaveApproved[enclaveAddr] = true;
    }

    function collectBounty(address enclaveAddr, bytes memory proofBlob, bytes memory sig) public {
        require(!claimed, "bounty already claimed");
        require(enclaveApproved[enclaveAddr], "address not approved");

        bytes32 hash = hash_data(proofBlob);
        address signer = recover(hash, sig);
        require(signer == enclaveAddr, "incorrect signature");

        RLPReader.RLPItem[] memory items = proofBlob.toRlpItem().toList();
        uint blockNum = items[0].toUint();
        bytes32 blockHash = toBytes32(items[1].toBytes());
        require(blockhash(blockNum) == blockHash, "block hash does not match block number");

        claimed = true;
        payable(msg.sender).transfer(bounty);
        emit BountyClaimed(msg.sender);
    }

    function hash_data(bytes memory data) internal pure returns (bytes32) {
        bytes memory eth_prefix = '\x19Ethereum Signed Message:\n';
        bytes memory packed = abi.encodePacked(eth_prefix,uint2str(data.length),data);
        return keccak256(packed);
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                revert("ECDSA: invalid signature 's' value");
            }
            address signer = ecrecover(hash, v, r, s);
            if (signer == address(0)) {
                revert("ECDSA: invalid signature");
            }
            return signer;
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    function uint2str( uint256 _i ) internal pure returns (string memory str) {
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }

    function toBytes32(bytes memory b) internal pure returns (bytes32) {
        bytes32 out;
        for (uint i = 0; i < 32; i++) {
          out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

}