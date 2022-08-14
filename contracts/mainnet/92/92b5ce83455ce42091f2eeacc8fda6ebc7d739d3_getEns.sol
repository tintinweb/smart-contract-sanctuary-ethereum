/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: contracts/ENSTesting.sol


pragma solidity ^0.8.0;


abstract contract ReverseRegistrar {
  function node(address addr) public pure virtual returns (bytes32);
}

abstract contract ENSBackwards {
  function resolver(bytes32 node) public view virtual returns (address);
}

abstract contract ENSForwards {
  function resolver(bytes32 node) public virtual view returns (Resolver);
}

abstract contract Resolver {
    function name(bytes32 node) public view virtual returns (string memory);
    function addr(bytes32 node) public virtual view returns (address);

}

contract getEns {
    ENSBackwards ensBackwards = ENSBackwards(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    ENSForwards ensForwards = ENSForwards(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    ReverseRegistrar reverseRegistrar = ReverseRegistrar(
      0x084b1c3C81545d370f3634392De611CaaBFf8148
    );

    function forwardResolve(bytes32 _node) public view returns (address) {
      Resolver forwardResolver = ensForwards.resolver(_node); 
      return forwardResolver.addr(_node);
    }

    function viewNode(address _address) public view returns (bytes32) {
      return reverseRegistrar.node(_address);
    }

    function viewResolver(bytes32 _node) public view returns (address) {
      return ensBackwards.resolver(_node);
    }


    function addressToENS(address _address) public view returns (string memory) {
        bytes32 node = reverseRegistrar.node(_address);
        address resolverAddress = ensBackwards.resolver(node);

        if (resolverAddress == address(0)) return Strings.toHexString(uint160(_address), 20);
       
        Resolver resolver = Resolver(resolverAddress);

        Resolver forwardResolver = ensForwards.resolver(node);
        
        address resolved = forwardResolver.addr(node);

        if (resolved != _address) return Strings.toHexString(uint160(_address), 20);

        return resolver.name(node);
  }
}