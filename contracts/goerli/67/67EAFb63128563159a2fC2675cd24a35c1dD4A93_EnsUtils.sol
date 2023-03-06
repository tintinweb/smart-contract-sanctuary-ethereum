// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {HexStrings} from "src/lib/HexStrings.sol";

library AddressUtils {
    using HexStrings for uint160;

    function toString(address value) internal pure returns (string memory) {
        return uint160(value).toHexString(20);
    }

    function toStringNoPrefix(address value) internal pure returns (string memory) {
        return uint160(value).toHexStringNoPrefix(20);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AddressUtils} from "src/lib/AddressUtils.sol";

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}

interface IENSReverseResolver {
    function name(bytes32 node) external view returns (string memory name);
}

library EnsUtils {
    using AddressUtils for address;

    function nameOrAddress(address registry, address address_) public view returns (string memory) {
        if (registry.code.length == 0) {
            return address_.toString();
        }

        bytes32 node = reverseResolveNameHash(address_);

        address resolverAddress;
        try IENS(registry).resolver(node) returns (address resolverAddress_) {
            if (resolverAddress_.code.length == 0) {
                return address_.toString();
            }
            resolverAddress = resolverAddress_;
        } catch {
            return address_.toString();
        }

        try IENSReverseResolver(resolverAddress).name(node) returns (string memory name) {
            return name;
        } catch {
            return address_.toString();
        }
    }

    function reverseResolveNameHash(address address_) public pure returns (bytes32 namehash) {
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked("reverse"))));
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked("addr"))));
        namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(address_.toStringNoPrefix()))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// HexStrings.sol from Uniswap v3 (MIT) https://github.com/Uniswap/v3-periphery/blob/6cce88e63e176af1ddb6cc56e029110289622317/contracts/libraries/HexStrings.sol

library HexStrings {
    bytes16 internal constant ALPHABET = "0123456789abcdef";

    /// @notice Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    /// @dev Credit to Open Zeppelin under MIT license https://github.com/OpenZeppelin/openzeppelin-contracts/blob/243adff49ce1700e0ecb99fe522fb16cff1d1ddc/contracts/utils/Strings.sol#L55
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }
}