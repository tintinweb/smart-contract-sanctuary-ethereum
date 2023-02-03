// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./lib/EIP712.sol";
import "./lib/MerkleVerifier.sol";

contract BlurHelper is EIP712 {
    
    function domainSeparator() public view returns(bytes32)  {
        return DOMAIN_SEPARATOR;
    }
    
    function hashDomain(EIP712Domain memory eip712Domain) public pure returns (bytes32){
        return _hashDomain(eip712Domain);
    }
    
    function hashFee(Fee calldata fee) public pure returns (bytes32) {
        return _hashFee(fee);
    }
    
    function packFees(Fee[] calldata fees) public pure returns (bytes32) {
        return _packFees(fees);
    }
    
    function hashOrder(Order calldata order, uint256 nonce) public pure returns (bytes32) {
        return _hashOrder(order,nonce);
    }
    
    function hashToSign(bytes32 orderHash) public view returns (bytes32 hash) {
        return _hashToSign(orderHash);
    }

    function hashToSignRoot(bytes32 root) public view returns (bytes32 hash) {
        return _hashToSignRoot(root);
    }

    function hashToSignOracle(bytes32 orderHash, uint256 blockNumber) public view returns (bytes32 hash) {
        return
            _hashToSignOracle(
               orderHash,
               blockNumber
            );
    }
    
    function verifyProof(bytes32 leaf, bytes32 root, bytes32[] memory proof) public pure returns(bool){
        bytes32 computedRoot = MerkleVerifier._computeRoot(leaf, proof);
        return computedRoot != root;
    }
    
    function computeRoot(bytes32 leaf, bytes32[] memory proof) public pure returns (bytes32) {
        return MerkleVerifier._computeRoot(leaf,proof);
    }
    
    function hashPair(bytes32 a, bytes32 b) public pure returns (bytes32) {
        return a < b ? efficientHash(a, b) : efficientHash(b, a);
    }
    
    function efficientHash(bytes32 a, bytes32 b) public pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Order, Fee} from "./OrderStructs.sol";

/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    /* Order typehash for EIP 712 compatibility. */
    bytes32 public constant FEE_TYPEHASH = keccak256("Fee(uint16 rate,address recipient)");
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(address trader,uint8 side,address matchingPolicy,address collection,uint256 tokenId,uint256 amount,address paymentToken,uint256 price,uint256 listingTime,uint256 expirationTime,Fee[] fees,uint256 salt,bytes extraParams,uint256 nonce)Fee(uint16 rate,address recipient)"
        );
    bytes32 public constant ORACLE_ORDER_TYPEHASH =
        keccak256(
            "OracleOrder(Order order,uint256 blockNumber)Fee(uint16 rate,address recipient)Order(address trader,uint8 side,address matchingPolicy,address collection,uint256 tokenId,uint256 amount,address paymentToken,uint256 price,uint256 listingTime,uint256 expirationTime,Fee[] fees,uint256 salt,bytes extraParams,uint256 nonce)"
        );
    bytes32 public constant ROOT_TYPEHASH = keccak256("Root(bytes32 root)");

    bytes32 constant EIP712DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 DOMAIN_SEPARATOR;

    function _hashDomain(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712DOMAIN_TYPEHASH,
                    keccak256(bytes(eip712Domain.name)),
                    keccak256(bytes(eip712Domain.version)),
                    eip712Domain.chainId,
                    eip712Domain.verifyingContract
                )
            );
    }

    function _hashFee(Fee calldata fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.rate, fee.recipient));
    }

    function _packFees(Fee[] calldata fees) internal pure returns (bytes32) {
        bytes32[] memory feeHashes = new bytes32[](fees.length);
        for (uint256 i = 0; i < fees.length; i++) {
            feeHashes[i] = _hashFee(fees[i]);
        }
        return keccak256(abi.encodePacked(feeHashes));
    }

    function _hashOrder(Order calldata order, uint256 nonce) internal pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        ORDER_TYPEHASH,
                        order.trader,
                        order.side,
                        order.matchingPolicy,
                        order.collection,
                        order.tokenId,
                        order.amount,
                        order.paymentToken,
                        order.price,
                        order.listingTime,
                        order.expirationTime,
                        _packFees(order.fees),
                        order.salt,
                        keccak256(order.extraParams)
                    ),
                    abi.encode(nonce)
                )
            );
    }

    function _hashToSign(bytes32 orderHash) internal view returns (bytes32 hash) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, orderHash));
    }

    function _hashToSignRoot(bytes32 root) internal view returns (bytes32 hash) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(ROOT_TYPEHASH, root))));
    }

    function _hashToSignOracle(bytes32 orderHash, uint256 blockNumber) internal view returns (bytes32 hash) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(abi.encode(ORACLE_ORDER_TYPEHASH, orderHash, blockNumber))
                )
            );
    }

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title MerkleVerifier
 * @dev Utility functions for Merkle tree computations
 */
library MerkleVerifier {
    error InvalidProof();

    /**
     * @dev Verify the merkle proof
     * @param leaf leaf
     * @param root root
     * @param proof proof
     */
    function _verifyProof(bytes32 leaf, bytes32 root, bytes32[] memory proof) public pure {
        bytes32 computedRoot = _computeRoot(leaf, proof);
        if (computedRoot != root) {
            revert InvalidProof();
        }
    }

    /**
     * @dev Compute the merkle root
     * @param leaf leaf
     * @param proof proof
     */
    function _computeRoot(bytes32 leaf, bytes32[] memory proof) public pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            computedHash = _hashPair(computedHash, proofElement);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum Side {
    Buy,
    Sell
}
enum SignatureVersion {
    Single,
    Bulk
}
enum AssetType {
    ERC721,
    ERC1155
}

struct Fee {
    uint16 rate;
    address payable recipient;
}

struct Order {
    address trader;
    Side side;
    address matchingPolicy;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address paymentToken;
    uint256 price;
    uint256 listingTime;
    /* Order expiration timestamp - 0 for oracle cancellations. */
    uint256 expirationTime;
    Fee[] fees;
    uint256 salt;
    bytes extraParams;
}

struct Input {
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes extraSignature;
    SignatureVersion signatureVersion;
    uint256 blockNumber;
}

struct Execution {
    Input sell;
    Input buy;
}