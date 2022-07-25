// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title deFOCUSed URI Contract
/// @author Matto
/// @notice This contract does the heavy lifting in creating the token metadata and image.
/// @dev The extra functions to retrieve/preview the SVG and return legible URI made main contract too large.
/// @custom:security-contact [email protected]
interface i_deFOCUSedTraits {
	function calculateTraitsArray(uint16[32] memory _hV, uint256 _tokenEntropy)
		external
		view
		returns (uint16[25] memory);

  function calculateTraitsJSON(uint16[25] memory _traitsArray)
  	external
		view
		returns (string memory);
}

interface i_deFOCUSedSVG {
	function assembleSVG(uint16[25] memory _traitsArray, string memory _metaPart, string memory traitsJSON)
		external
		view
		returns (string memory);
}

contract deFOCUSedURI is Ownable {
  using Strings for string;

  address public traitsContract;
  address public svgContract;
  bool public cruncherContractsLocked = false;

  function createHashValPairs(bytes32 _abEntropy)
    public
    pure
    returns (uint16[32] memory)
  {
    uint16[32] memory hV;
    for (uint i = 0; i < 32; i++) {
        hV[i] = uint16(uint(bytes32(bytes1(_abEntropy)) >> 248));
        _abEntropy = _abEntropy << 8;
    }
    return hV;
  }

  function buildMetaPart(uint256 _tokenId, string memory _description, address _artistAddy, uint256 _royaltyBps, string memory _collection, string memory _website, string memory _externalURL)
    external
    view
    virtual
    returns (string memory)
  {
    string memory metaPart = string(abi.encodePacked('{"name":"deFOCUSed #',Strings.toString(_tokenId),'","artist":"Matto","description":"',
      _description,'","royaltyInfo":{"artistAddress":"',Strings.toHexString(uint160(_artistAddy), 20),'","royaltyFeeByID":',Strings.toString(_royaltyBps/100),'},"collection_name":"',
      _collection,'","website":"',_website,'","external_url":"',_externalURL,'","script_type":"Solidity","image_type":"Generative SVG"'));
    return metaPart;
  }

  function buildContractURI(string memory _description, string memory _externalURL, uint256 _royaltyBps, address _artistAddy, string memory _svg)
    external
    view
    virtual
    returns (string memory)
  {
    string memory b64SVG = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(_svg))));
    string memory contractURI = string(abi.encodePacked('{"name":"deFOCUSed","description":"',_description,'","image":"', b64SVG,
      '","external_link":"',_externalURL,'","seller_fee_basis_points":',Strings.toString(_royaltyBps),',"fee_recipient":"',Strings.toHexString(uint160(_artistAddy), 20),'"}'));
    string memory base64ContractURI = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(contractURI))));
    return base64ContractURI;
  }

  function buildTokenURI(string memory _metaP, uint256 _tokenEntropy, bytes32 _abEntropy, bool _svgMode)
    external
    view
    virtual
    returns (string memory)
  {
    uint16[32] memory hV = createHashValPairs(_abEntropy);
    uint16[25] memory traitsArray = i_deFOCUSedTraits(traitsContract).calculateTraitsArray(hV, _tokenEntropy);
    string memory traitsJSON = i_deFOCUSedTraits(traitsContract).calculateTraitsJSON(traitsArray);
    string memory svg = i_deFOCUSedSVG(svgContract).assembleSVG(traitsArray, _metaP, traitsJSON);
    if (_svgMode) {
      return svg;
    } else {
      string memory b64SVG = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(svg))));
      string memory legibleURI = string(abi.encodePacked(_metaP,',"image":"',b64SVG,'",',traitsJSON,'}'));
      string memory base64URI = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(legibleURI))));
      return base64URI;
    }
  }  

  function updateSVGContract(address _svgContract)
		external 
		onlyOwner 
	{
    require(cruncherContractsLocked == false, "Contracts locked");
    svgContract = _svgContract;
  }

	function updateTraitsContract(address _traitsContract)
		external 
		onlyOwner 
	{
    require(cruncherContractsLocked == false, "Contracts locked");
    traitsContract = _traitsContract;
  }

  function DANGER_LockCruncherContracts()
    external
    payable
    onlyOwner
  {
    cruncherContractsLocked = true;
  }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}