// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/ICollectionManager.sol";
import "../commons/OwnableInitializable.sol";
import "../libs/String.sol";

contract Rarities is OwnableInitializable {
    using String for string;

    struct Rarity {
        string name;
        uint256 maxSupply;
        uint256 price;
    }

    Rarity[] public rarities;

    /// @dev indexes will start in 1
    mapping(bytes32 => uint256) rarityIndex;

    event AddRarity(Rarity _rarity);
    event UpdatePrice(string _name, uint256 _price);


   /**
    * @notice Create the contract
    * @param _owner - owner of the contract
    */
    constructor(address _owner,  Rarity[] memory _rarities) {
        // Ownable init
        _initOwnable();
        transferOwnership(_owner);

        for (uint256 i = 0 ; i < _rarities.length; i++) {
            _addRarity(_rarities[i]);
        }
    }

    function updatePrices(string[] calldata _names, uint256[] calldata _prices) external onlyOwner {
        require(_names.length == _prices.length, "Rarities#updatePrices: LENGTH_MISMATCH");

        for (uint256 i = 0; i < _names.length; i++) {
            string memory name = _names[i];
            uint256 price = _prices[i];
            bytes32 rarityKey = keccak256(bytes(name.toLowerCase()));
            uint256 index = rarityIndex[rarityKey];

            require(rarityIndex[rarityKey] > 0, "Rarities#updatePrices: INVALID_RARITY");

            rarities[index - 1].price = price;

            emit UpdatePrice(name, price);
        }
    }

    function addRarities(Rarity[] memory _rarities) external onlyOwner {
        for (uint256 i = 0; i < _rarities.length; i++) {
            _addRarity(_rarities[i]);
        }
    }

    function _addRarity(Rarity memory _rarity) internal {
        uint256 rarityLength = bytes(_rarity.name).length;
        require(rarityLength > 0 && rarityLength <= 32, "Rarities#_addRarity: INVALID_LENGTH");

        bytes32 rarityKey = keccak256(bytes(_rarity.name.toLowerCase()));
        require(rarityIndex[rarityKey] == 0, "Rarities#_addRarity: RARITY_ALREADY_ADDED");

        rarities.push(_rarity);

        rarityIndex[rarityKey] = rarities.length;

        emit AddRarity(_rarity);
    }

    /**
     * @notice Returns the amount of item in the collection
     * @return Amount of items in the collection
     */
    function raritiesCount() external view returns (uint256) {
        return rarities.length;
    }

    /**
     * @notice Returns a rarity
     * @dev will revert if the rarity is out of bounds
     * @return rarity for the given index
     */
    function getRarityByName(string memory _rarity) public view returns (Rarity memory) {
        bytes32 rarityKey = keccak256(bytes(_rarity.toLowerCase()));

        uint256 index = rarityIndex[rarityKey];

        require(rarityIndex[rarityKey] > 0, "Rarities#getRarityByName: INVALID_RARITY");

        return rarities[index - 1];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface ICollectionManager {
   function manageCollection(address _forwarder, address _collection, bytes calldata _data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ContextMixin.sol";

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
abstract contract OwnableInitializable is ContextMixin {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initOwnable () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

library String {

    /**
     * @dev Convert bytes32 to string.
     * @param _x - to be converted to string.
     * @return string
     */
    function bytes32ToString(bytes32 _x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            bytes1 currentChar = bytes1(bytes32(uint(_x) * 2 ** (8 * j)));
            if (currentChar != 0) {
                bytesString[charCount] = currentChar;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /**
     * @dev Convert uint to string.
     * @param _i - uint256 to be converted to string.
     * @return _uintAsString uint in string
     */
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        uint i = _i;

        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Convert an address to string.
     * @param _x - address to be converted to string.
     * @return string representation of the address
     */
    function addressToString(address _x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint160(_x) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Lowercase a string.
     * @param _str - to be converted to string.
     * @return string
     */
    function toLowerCase(string memory _str) internal pure returns (string memory) {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 0x20 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 0x20);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


abstract contract ContextMixin {
    function _msgSender()
        internal
        view
        virtual
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}