// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

import './Types/Types.sol';

/*
   __           _      _        ___ _                __ _                 
  / /  __ _ ___| | ___( )__    / _ (_)__________ _  / _\ |__   ___  _ __  
 / /  / _` |_  / |/ _ \/ __|  / /_)/ |_  /_  / _` | \ \| '_ \ / _ \| '_ \ 
/ /__| (_| |/ /| | (_) \__ \ / ___/| |/ / / / (_| | _\ \ | | | (_) | |_) |
\____/\__,_/___|_|\___/|___/ \/    |_/___/___\__,_| \__/_| |_|\___/| .__/ 
                                                                   |_|    

LazlosRendering is the rendering contract used for rendering tokenURI's in Lazlo's kitchen.
*/
contract LazlosRendering is Ownable {
    using Strings for uint256;

    address public ingredientsContractAddress;
    address public pizzasContractAddress;
    string public ingredientsIPFSHash;
    string public baseURI;
    string private ingredientsDescription;
    string private pizzaDescription;

    function setIngredientsContractAddress(address addr) public onlyOwner {
        ingredientsContractAddress = addr;
    }

    function setPizzasContractAddress(address addr) public onlyOwner {
        pizzasContractAddress = addr;
    }

    function setIngredientsIPFSHash(string memory hash) public onlyOwner {
        ingredientsIPFSHash = hash;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setIngredientsDescription(string memory description) public onlyOwner {
        ingredientsDescription = description;
    }

    function setPizzaDescription(string memory description) public onlyOwner {
        pizzaDescription = description;
    }

    function ingredientTokenMetadata(uint256 id) public view returns (string memory) {
        Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(id);

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(abi.encodePacked(
                    '{"name":"', ingredient.name,
                    '","description":"', ingredientsDescription, '","image":"https://gateway.pinata.cloud/ipfs/',
                    ingredientsIPFSHash, '/', id.toString(), '.png"}'
                ))
            )
        );
    }

    function pizzaTokenMetadata(uint256 id) external view returns (string memory) {
        Pizza memory pizza = ILazlosPizzas(pizzasContractAddress).pizza(id);
        uint256 numIngredients = ILazlosIngredients(ingredientsContractAddress).getNumIngredients();
        
        string memory propertiesString;
        for (uint256 ingredientId = 1; ingredientId <= numIngredients; ingredientId++) {

            string memory comma = ",";
            if (bytes(propertiesString).length == 0) {
                comma = "";
            }

            Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(ingredientId);
            
            string memory traitType;
            string memory value;
            if (ingredient.ingredientType == IngredientType.Base ||
                ingredient.ingredientType == IngredientType.Sauce) {
                if (!(pizzaContainsIngredient(pizza, ingredientId))) {
                    continue;
                }

                traitType = getIngredientTypeName(ingredientId);
                value = getIngredientName(ingredientId);

            } else {
                traitType = getIngredientName(ingredientId);

                if (pizzaContainsIngredient(pizza, ingredientId)) {
                    value = "Yes";

                } else {
                    value = "No";
                }
            }

            propertiesString = string(abi.encodePacked(
                propertiesString, comma, '{"trait_type":"', traitType, '","value":"', value, '"}'
            ));
        }

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(abi.encodePacked(
                    '{"description":"', pizzaDescription, '","image":"',
                    baseURI, '/tokens/', id.toString(), '/pizza_image.png","attributes":[',
                    propertiesString, ']}'
                ))
            )
        );
    }

    function getIngredientName(uint256 ingredientTokenId) private view returns (string memory) {
        return ILazlosIngredients(ingredientsContractAddress).getIngredient(ingredientTokenId).name;
    }

    function pizzaContainsIngredient(Pizza memory pizza, uint256 ingredientId) private pure returns (bool) {
        if (pizza.base == ingredientId) {
            return true;
        
        }
        
        if (pizza.sauce == ingredientId) {
            return true;
        
        }

        for (uint256 i = 0; i < 3; i++) {
            uint16 cheese = pizza.cheeses[i];
            if (cheese == 0) {
                break;
            }

            if (cheese == ingredientId) {
                return true;
            }
        }

        for (uint256 i = 0; i < 4; i++) {
            uint16 meat = pizza.meats[i];
            if (meat == 0) {
                break;
            }

            if (meat == ingredientId) {
                return true;
            }
        }

        for (uint256 i = 0; i < 4; i++) {
            uint16 topping = pizza.toppings[i];
            if (topping == 0) {
                break;
            }

            if (topping == ingredientId) {
                return true;
            }
        }

        return false;
    }

    function getIngredientTypeName(uint256 ingredientTokenId) private view returns (string memory) {
        Ingredient memory ingredient = ILazlosIngredients(ingredientsContractAddress).getIngredient(ingredientTokenId);
        
        if (ingredient.ingredientType == IngredientType.Base) {
            return "Base";
        
        } else if (ingredient.ingredientType == IngredientType.Sauce) {
            return "Sauce";
        
        } else if (ingredient.ingredientType == IngredientType.Cheese) {
            return "Cheese";
        
        } else if (ingredient.ingredientType == IngredientType.Meat) {
            return "Meat";
        
        } else {
            return "Topping";
        }
    }

    function uintToByteString(uint256 a, uint256 fixedLen)
        internal
        pure
        returns (bytes memory _uintAsString)
    {
        uint256 j = a;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        j = fixedLen;
        if (a == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(" ");
        }
        uint256 k = len;
        while (a != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(a - (a / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            a /= 10;
        }
        return bstr;
    }
}

library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

enum IngredientType {
    Base,
    Sauce,
    Cheese,
    Meat,
    Topping
}

struct Ingredient {
    string name;
    IngredientType ingredientType;
    address artist;
    uint256 price;
    uint256 supply;
    uint256 initialSupply;
}

struct Pizza {
    uint16 base;
    uint16 sauce;
    uint16[3] cheeses;
    uint16[4] meats;
    uint16[4] toppings;
}

interface ILazlosIngredients {
    function getNumIngredients() external view returns (uint256);
    function getIngredient(uint256 tokenId) external view returns (Ingredient memory);
    function increaseIngredientSupply(uint256 tokenId, uint256 amount) external;
    function decreaseIngredientSupply(uint256 tokenId, uint256 amount) external;
    function mintIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) external;
    function burnIngredients(address addr, uint256[] memory tokenIds, uint256[] memory amounts) external;
    function balanceOfAddress(address addr, uint256 tokenId) external view returns (uint256);
}

interface ILazlosPizzas {
    function bake(address baker, Pizza memory pizza) external returns (uint256);
    function rebake(address baker, uint256 pizzaTokenId, Pizza memory pizza) external;
    function pizza(uint256 tokenId) external view returns (Pizza memory);
    function burn(uint256 tokenId) external;
}

interface ILazlosRendering {
    function ingredientTokenMetadata(uint256 id) external view returns (string memory); 
    function pizzaTokenMetadata(uint256 id) external view returns (string memory); 
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