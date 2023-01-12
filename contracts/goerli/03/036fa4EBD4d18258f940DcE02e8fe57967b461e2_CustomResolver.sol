// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BytesUtils} from "../wrapper/BytesUtils.sol";

library NameEncoder {
    using BytesUtils for bytes;

    function dnsEncodeName(string memory name)
        internal
        pure
        returns (bytes memory dnsName, bytes32 node)
    {
        uint8 labelLength = 0;
        bytes memory bytesName = bytes(name);
        uint256 length = bytesName.length;
        dnsName = new bytes(length + 2);
        node = 0;
        if (length == 0) {
            dnsName[0] = 0;
            return (dnsName, node);
        }

        // use unchecked to save gas since we check for an underflow
        // and we check for the length before the loop
        unchecked {
            for (uint256 i = length - 1; i >= 0; i--) {
                if (bytesName[i] == ".") {
                    dnsName[i + 1] = bytes1(labelLength);
                    node = keccak256(
                        abi.encodePacked(
                            node,
                            bytesName.keccak(i + 1, labelLength)
                        )
                    );
                    labelLength = 0;
                } else {
                    labelLength += 1;
                    dnsName[i + 1] = bytesName[i];
                }
                if (i == 0) {
                    break;
                }
            }
        }

        node = keccak256(
            abi.encodePacked(node, bytesName.keccak(0, labelLength))
        );

        dnsName[0] = bytes1(labelLength);
        return (dnsName, node);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ~0.8.17;

library BytesUtils {
    /*
     * @dev Returns the keccak-256 hash of a byte range.
     * @param self The byte string to hash.
     * @param offset The position to start hashing at.
     * @param len The number of bytes to hash.
     * @return The hash of the byte range.
     */
    function keccak(
        bytes memory self,
        uint256 offset,
        uint256 len
    ) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /**
     * @dev Returns the ENS namehash of a DNS-encoded name.
     * @param self The DNS-encoded name to hash.
     * @param offset The offset at which to start hashing.
     * @return The namehash of the name.
     */
    function namehash(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes32)
    {
        (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
        if (labelhash == bytes32(0)) {
            require(offset == self.length - 1, "namehash: Junk at end of name");
            return bytes32(0);
        }
        return
            keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
    }

    /**
     * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
     * @param self The byte string to read a label from.
     * @param idx The index to read a label at.
     * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
     * @return newIdx The index of the start of the next label.
     */
    function readLabel(bytes memory self, uint256 idx)
        internal
        pure
        returns (bytes32 labelhash, uint256 newIdx)
    {
        require(idx < self.length, "readLabel: Index out of bounds");
        uint256 len = uint256(uint8(self[idx]));
        if (len > 0) {
            labelhash = keccak(self, idx + 1, len);
        } else {
            labelhash = bytes32(0);
        }
        newIdx = idx + len + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ICustomResolver} from "./interfaces/ICustomResolver.sol";
import {Relationship} from "./libraries/Relationship.sol";

contract CustomResolver is ICustomResolver {
    mapping(bytes4 => address) internal _interfaceImplementer;
    address public owner;

    string public constant NOT_CURRENT_OWNER = "018001";

    constructor() {
        owner = tx.origin;
        _interfaceImplementer[type(ICustomResolver).interfaceId] = address(
            this
        );
    }

    function setInterfaceImplementer(
        bytes4 interfaceID,
        address addr
    ) external {
        require(msg.sender == owner || tx.origin == owner, NOT_CURRENT_OWNER);
        _interfaceImplementer[interfaceID] = addr;
    }

    function interfaceImplementer(
        bytes4 interfaceID
    ) external view returns (address) {
        return _interfaceImplementer[interfaceID];
    }

    function resolverAddress() external view returns (address) {
        return Relationship.resolverAddress();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICustomResolver {
    function setInterfaceImplementer(bytes4 interfaceID, address addr) external;

    function interfaceImplementer(
        bytes4 interfaceID
    ) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {NameEncoder} from "@ensdomains/ens-contracts/contracts/utils/NameEncoder.sol";

import {IENS} from "../interfaces/IENS.sol";

library Relationship {
    function resolverAddress() internal view returns (address) {
        IENS ens = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
        (, bytes32 ifragNameHash) = NameEncoder.dnsEncodeName("ifrag-dev.ru");

        return ens.resolver(ifragNameHash);
    }
}