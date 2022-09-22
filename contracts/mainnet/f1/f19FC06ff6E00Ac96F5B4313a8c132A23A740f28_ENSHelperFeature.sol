// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IENSHelperFeature.sol";
import "./IENSInterface.sol";


contract ENSHelperFeature is IENSHelperFeature {

    function queryENSInfosByNode(address ens, bytes32[] calldata nodes) external override view returns (ENSQueryResult[] memory) {
        ENSQueryResult[] memory results = new ENSQueryResult[](nodes.length);
        for (uint256 i; i < nodes.length; ++i) {
            try IENS(ens).resolver(nodes[i]) returns (address _resolver) {
                results[i].resolver = _resolver;
            } catch {
            }

            if (results[i].resolver != address(0)) {
                try IENSResolver(results[i].resolver).addr(nodes[i]) returns (address _address) {
                    results[i].domainAddr = _address;
                } catch {
                }
            }
        }
        return results;
    }

    function queryENSInfosByToken(address token, address ens, uint256[] calldata tokenIds) external override view returns (ENSQueryResult[] memory) {
        ENSQueryResult[] memory results = new ENSQueryResult[](tokenIds.length);
        bytes32 baseNode = IENSToken(token).baseNode();
        for (uint i; i < tokenIds.length; ++i) {
            try IENSToken(token).ownerOf(tokenIds[i]) returns (address _owner) {
                results[i].owner = _owner;
            } catch {
            }

            try IENSToken(token).available(tokenIds[i]) returns (bool _available) {
                results[i].available = _available;
            } catch {
            }

            bytes32 node = keccak256(abi.encodePacked(baseNode, tokenIds[i]));
            try IENS(ens).resolver(node) returns (address _resolver) {
                results[i].resolver = _resolver;
            } catch {
            }

            if (results[i].resolver != address(0)) {
                try IENSResolver(results[i].resolver).addr(node) returns (address _address) {
                    results[i].domainAddr = _address;
                } catch {
                }
            }
        }
        return results;
    }

    function queryENSReverseInfos(address ens, address[] calldata addresses) external override view returns (ENSReverseResult[] memory) {
        ENSReverseResult[] memory reverses = _queryENSReverses(ens, addresses);
        for (uint i; i < reverses.length; ++i) {
            if (reverses[i].domain.length == 0) {
                continue;
            }

            bytes32 node = _namehash(reverses[i].domain);

            try IENS(ens).resolver(node) returns (address _resolver) {
                reverses[i].verifyResolver = _resolver;
            } catch {
            }

            if (reverses[i].verifyResolver != address(0)) {
                try IENSResolver(reverses[i].verifyResolver).addr(node) returns (address _address) {
                    reverses[i].verifyAddr = _address;
                } catch {
                }
            }
        }
        return reverses;
    }

    // BASE_REVERSE_HASH = namehash("addr.reverse")
    bytes32 constant BASE_REVERSE_HASH = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    function _queryENSReverses(address ens, address[] calldata addresses) internal view returns (ENSReverseResult[] memory) {
        ENSReverseResult[] memory results = new ENSReverseResult[](addresses.length);
        for (uint256 i; i < addresses.length; ++i) {
            if (addresses[i] == address(0)) {
                continue;
            }

            bytes32 label = keccak256(_toHexString(addresses[i]));
            bytes32 node = keccak256(abi.encodePacked(BASE_REVERSE_HASH, label));

            try IENS(ens).resolver(node) returns (address _resolver) {
                results[i].resolver = _resolver;
            } catch {
            }

            if (results[i].resolver != address(0)) {
                try IENSResolver(results[i].resolver).name(node) returns (bytes memory _name) {
                    results[i].domain = _name;
                } catch {
                }
            }
        }
        return results;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function _toHexString(address addr) internal pure returns (bytes memory) {
    unchecked {
        uint256 value = uint160(addr);
        bytes memory buffer = new bytes(40);
        for (uint256 i = 0; i < 40; ++i) {
            buffer[39 - i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return buffer;
    }
    }

    function _namehash(bytes memory domain) internal pure returns (bytes32 hash) {
        uint256 total = bytes(domain).length;
        assembly {
            let ptrFree := mload(0x40)
            mstore(ptrFree, 0)

            let i
            let start := add(domain, 0x20)
            let ptrEnd := add(start, total)

            let length := _getLabelLength(ptrEnd, total, i)
            for {} length {} {
                let labelHash := keccak256(sub(ptrEnd, add(i, length)), length)
                mstore(add(ptrFree, 0x20), labelHash)
                mstore(ptrFree, keccak256(ptrFree, 0x40))

                i := add(i, length)
                if lt(i, total) {
                    i := add(i, 1)
                }
                length := _getLabelLength(ptrEnd, total, i)
            }

            hash := mload(ptrFree)

            function _getLabelLength(endPtr, t, offset) -> len {
                for {let ptr := sub(endPtr, add(offset, 1))} and(lt(add(offset, len), t), iszero(eq(byte(0, mload(ptr)), 0x2e))) {} {
                    ptr := sub(ptr, 1)
                    len := add(len, 1)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IENSHelperFeature {

    struct ENSQueryResult {
        address resolver;
        address domainAddr;
        address owner;
        bool available;
    }

    struct ENSReverseResult {
        address resolver;
        bytes domain;
        address verifyResolver;
        address verifyAddr;
    }

    function queryENSInfosByNode(address ens, bytes32[] calldata nodes) external view returns (ENSQueryResult[] memory);

    function queryENSInfosByToken(address token, address ens, uint256[] calldata tokenIds) external view returns (ENSQueryResult[] memory);

    function queryENSReverseInfos(address ens, address[] calldata addresses) external view returns (ENSReverseResult[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IENSToken {
    function baseNode() external view returns (bytes32);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function available(uint256 id) external view returns (bool);
}

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}

interface IENSResolver {
    function addr(bytes32 node) external view returns (address);

    function name(bytes32 node) external view returns (bytes memory);
}