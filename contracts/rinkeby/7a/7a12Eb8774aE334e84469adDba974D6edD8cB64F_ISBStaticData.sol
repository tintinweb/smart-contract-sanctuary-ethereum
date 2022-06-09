// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import './interface/IISBStaticData.sol';

contract ISBStaticData is IISBStaticData, ERC165 {
    using Strings for uint256;
    using Strings for uint16;

    function generationText(Generation gen) public pure override returns (string memory) {
        if (gen == Generation.GEN0) {
            return 'GEN0';
        } else if (gen == Generation.GEN05) {
            return 'GEN0.5';
        } else if (gen == Generation.GEN1) {
            return 'GEN1';
        } else {
            return '';
        }
    }

    function weaponTypeText(WeaponType weaponType) public pure override returns (string memory) {
        if (weaponType == WeaponType.Sword) {
            return 'Sword';
        } else if (weaponType == WeaponType.TwoHand) {
            return 'TwoHand';
        } else if (weaponType == WeaponType.Fists) {
            return 'Fists';
        } else if (weaponType == WeaponType.Bow) {
            return 'Bow';
        } else if (weaponType == WeaponType.Staff) {
            return 'Staff';
        } else {
            return '';
        }
    }

    function armorTypeText(ArmorType armorType) public pure override returns (string memory) {
        if (armorType == ArmorType.HeavyArmor) {
            return 'HeavyArmor';
        } else if (armorType == ArmorType.LightArmor) {
            return 'LightArmor';
        } else if (armorType == ArmorType.Robe) {
            return 'Robe';
        } else if (armorType == ArmorType.Cloak) {
            return 'Cloak';
        } else if (armorType == ArmorType.TribalWear) {
            return 'TribalWear';
        } else {
            return '';
        }
    }

    function sexTypeText(SexType sexType) public pure override returns (string memory) {
        if (sexType == SexType.Male) {
            return 'Male';
        } else if (sexType == SexType.Female) {
            return 'Female';
        } else if (sexType == SexType.Hermaphrodite) {
            return 'Hermaphrodite';
        } else if (sexType == SexType.Unknown) {
            return 'Unknown';
        } else {
            return '';
        }
    }

    function speciesTypeText(SpeciesType speciesType) public pure override returns (string memory) {
        if (speciesType == SpeciesType.Human) {
            return 'Human';
        } else if (speciesType == SpeciesType.Elf) {
            return 'Elf';
        } else if (speciesType == SpeciesType.Dwarf) {
            return 'Dwarf';
        } else if (speciesType == SpeciesType.Demon) {
            return 'Demon';
        } else if (speciesType == SpeciesType.Merfolk) {
            return 'Merfolk';
        } else if (speciesType == SpeciesType.Therianthrope) {
            return 'Therianthrope';
        } else if (speciesType == SpeciesType.Vampire) {
            return 'Vampire';
        } else if (speciesType == SpeciesType.Angel) {
            return 'Angel';
        } else if (speciesType == SpeciesType.Unknown) {
            return 'Unknown';
        } else if (speciesType == SpeciesType.Dragonewt) {
            return 'Dragonewt';
        } else if (speciesType == SpeciesType.Monster) {
            return 'Monster';
        } else {
            return '';
        }
    }

    function heritageTypeText(HeritageType heritageType) public pure override returns (string memory) {
        if (heritageType == HeritageType.LowClass) {
            return 'LowClass';
        } else if (heritageType == HeritageType.MiddleClass) {
            return 'MiddleClass';
        } else if (heritageType == HeritageType.HighClass) {
            return 'HighClass';
        } else if (heritageType == HeritageType.Unknown) {
            return 'Unknown';
        } else {
            return '';
        }
    }

    function personalityTypeText(PersonalityType personalityType) public pure override returns (string memory) {
        if (personalityType == PersonalityType.Cool) {
            return 'Cool';
        } else if (personalityType == PersonalityType.Serious) {
            return 'Serious';
        } else if (personalityType == PersonalityType.Gentle) {
            return 'Gentle';
        } else if (personalityType == PersonalityType.Optimistic) {
            return 'Optimistic';
        } else if (personalityType == PersonalityType.Rough) {
            return 'Rough';
        } else if (personalityType == PersonalityType.Diffident) {
            return 'Diffident';
        } else if (personalityType == PersonalityType.Pessimistic) {
            return 'Pessimistic';
        } else if (personalityType == PersonalityType.Passionate) {
            return 'Passionate';
        } else if (personalityType == PersonalityType.Unknown) {
            return 'Unknown';
        } else if (personalityType == PersonalityType.Frivolous) {
            return 'Frivolous';
        } else if (personalityType == PersonalityType.Confident) {
            return 'Confident';
        } else {
            return '';
        }
    }

    function createMetadata(
        uint256 tokenId,
        Character calldata char,
        Metadata calldata metadata,
        uint16[] calldata status,
        StatusMaster[] calldata statusMaster,
        string calldata image,
        Generation generation
    ) public pure override returns (string memory) {
        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "Name","value": "',
            char.name,
            '"},{"trait_type": "Generation Type","value": "',
            generationText(generation),
            abi.encodePacked(
                '"},{"trait_type": "Weapon","value": "',
                weaponTypeText(char.weapon),
                '"},{"trait_type": "Armor","value": "',
                armorTypeText(char.armor),
                '"},{"trait_type": "Sex","value": "',
                sexTypeText(char.sex),
                '"},{"trait_type": "Species","value": "',
                speciesTypeText(char.species),
                '"},{"trait_type": "Heritage","value": "',
                heritageTypeText(char.heritage),
                '"},{"trait_type": "Personality","value": "',
                personalityTypeText(char.personality)
            ),
            '"},{"trait_type": "Used Seed","value": ',
            metadata.seedHistory.length.toString(),
            '},{"trait_type": "Level","value": ',
            metadata.level.toString(),
            '}',
            statusMaster.length == 0 ? ',' : ''
        );
        for (uint256 i = 0; i < statusMaster.length; i++) {
            if (i == 0) attributes = abi.encodePacked(attributes, ',');
            attributes = abi.encodePacked(
                attributes,
                '{"trait_type": "',
                statusMaster[i].statusText,
                '","value": ',
                status[i].toString(),
                '}',
                i == statusMaster.length - 1 ? '' : ','
            );
        }
        bytes memory dataURI = abi.encodePacked(
            '{"name": "',
            char.name,
            ' #',
            tokenId.toString(),
            '","description": "When the seven Fragments come together,  \\nThe lost power of the gods will be revived and unleashed.  \\n  \\nExplore the Isekai, Turkenista, and defeat your rivals to collect Fragments (NFT)! Combining the Fragments will bring back SINKI blessing you with overflowing SINN(ERC20)!   \\n  \\nYou will need 3 or more characters to play this fully on-chain game on the Ethereum blockchain.  \\n  \\nBattle for NFTs!","image": "',
            image,
            '","attributes": [',
            attributes,
            ']}'
        );

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IISBStaticData).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IISBStaticData {
    enum Generation {
        GEN0,
        GEN05,
        GEN1
    }
    enum WeaponType {
        Sword,
        TwoHand,
        Fists,
        Bow,
        Staff
    }
    enum ArmorType {
        HeavyArmor,
        LightArmor,
        Robe,
        Cloak,
        TribalWear
    }
    enum SexType {
        Male,
        Female,
        Hermaphrodite,
        Unknown
    }
    enum SpeciesType {
        Human,
        Elf,
        Dwarf,
        Demon,
        Merfolk,
        Therianthrope,
        Vampire,
        Angel,
        Unknown,
        Dragonewt,
        Monster
    }
    enum HeritageType {
        LowClass,
        MiddleClass,
        HighClass,
        Unknown
    }
    enum PersonalityType {
        Cool,
        Serious,
        Gentle,
        Optimistic,
        Rough,
        Diffident,
        Pessimistic,
        Passionate,
        Unknown,
        Frivolous,
        Confident
    }
    enum Phase {
        BeforeMint,
        WLMint,
        PublicMint,
        MintByTokens
    }

    struct Tokens {
        IERC20 SINN;
        IERC20 GOV;
    }
    struct Metadata {
        uint16 characterId;
        uint16 level;
        uint256 transferTime;
        Status[] seedHistory;
    }
    struct Status {
        uint256 statusId;
        uint16 status;
    }
    struct Character {
        Status[] defaultStatus;
        WeaponType weapon;
        ArmorType armor;
        SexType sex;
        SpeciesType species;
        HeritageType heritage;
        PersonalityType personality;
        string name;
        uint16 imageId;
        bool canBuy;
    }
    struct EtherPrices {
        uint64 mintPrice1;
        uint64 mintPrice2;
        uint64 mintPrice3;
        uint64 mintPrice4;
        uint64 wlMintPrice1;
        uint64 wlMintPrice2;
        uint64 wlMintPrice3;
        uint64 wlMintPrice4;
    }
    struct TokenPrices {
        uint128 SINNPrice1;
        uint128 SINNPrice2;
        uint128 SINNPrice3;
        uint128 SINNPrice4;
        uint128 GOVPrice1;
        uint128 GOVPrice2;
        uint128 GOVPrice3;
        uint128 GOVPrice4;
    }
    struct StatusMaster {
        string statusText;
        bool withLevel;
    }

    function generationText(Generation gen) external pure returns (string memory);

    function weaponTypeText(WeaponType weaponType) external pure returns (string memory);

    function armorTypeText(ArmorType armorType) external pure returns (string memory);

    function sexTypeText(SexType sexType) external pure returns (string memory);

    function speciesTypeText(SpeciesType speciesType) external pure returns (string memory);

    function heritageTypeText(HeritageType heritageType) external pure returns (string memory);

    function personalityTypeText(PersonalityType personalityType) external pure returns (string memory);

    function createMetadata(
        uint256 tokenId,
        Character calldata char,
        Metadata calldata metadata,
        uint16[] calldata status,
        StatusMaster[] calldata statusTexts,
        string calldata image,
        Generation generation
    ) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}