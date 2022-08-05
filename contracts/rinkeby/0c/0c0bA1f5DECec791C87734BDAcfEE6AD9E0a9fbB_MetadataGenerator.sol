/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// File: contracts/Interfaces/ITraitNames.sol

pragma solidity ^0.8.0;

interface iTraitNames {
    function getFuselageText() external view returns (string[5] memory);
    function getDrillerText() external view returns (string[4] memory);
    function getSmelterText() external view returns (string[3] memory);
    function getShieldText() external view returns (string[5] memory);
    function getThrusterText() external view returns (string[4] memory);
    function getStarbaseText() external view returns (string[1] memory);
}
// File: contracts/Interfaces/IShieldFuselage_2.sol

pragma solidity ^0.8.0;

interface iShieldFuselage_2 {
    function getFuselage_2() external view returns (string[5][2] memory);
}
// File: contracts/Interfaces/IShieldFuselage_1.sol

pragma solidity ^0.8.0;

interface iShieldFuselage_1 {
    function getFuselage_1() external view returns (string[5][3] memory);
}
// File: contracts/Interfaces/ISmelterDrillerThruster.sol

pragma solidity ^0.8.0;

interface iSmelterDrillerThruster {
    function getSmelter() external view returns (string[5][3] memory);
    function getDriller() external view returns (string[5][4] memory);
    function getThruster() external view returns (string[5][4] memory);
}
// File: contracts/Interfaces/ICard.sol

pragma solidity ^0.8.0;

interface icards {
    function getCards() external view returns (string[5] memory);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Base64.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

        /// @solidity memory-safe-assembly
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

// File: contracts/MetadataGenerator.sol


//  ██████╗██╗  ██╗ █████╗ ██╗███╗   ██╗███████╗ ██████╗ ██████╗ ██╗   ██╗████████╗███████╗    ███████╗██╗  ██╗██╗██████╗ 
// ██╔════╝██║  ██║██╔══██╗██║████╗  ██║██╔════╝██╔════╝██╔═══██╗██║   ██║╚══██╔══╝██╔════╝    ██╔════╝██║  ██║██║██╔══██╗
// ██║     ███████║███████║██║██╔██╗ ██║███████╗██║     ██║   ██║██║   ██║   ██║   ███████╗    ███████╗███████║██║██████╔╝
// ██║     ██╔══██║██╔══██║██║██║╚██╗██║╚════██║██║     ██║   ██║██║   ██║   ██║   ╚════██║    ╚════██║██╔══██║██║██╔═══╝ 
// ╚██████╗██║  ██║██║  ██║██║██║ ╚████║███████║╚██████╗╚██████╔╝╚██████╔╝   ██║   ███████║    ███████║██║  ██║██║██║     
//  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝    ╚══════╝╚═╝  ╚═╝╚═╝╚═╝     
                                                                                                                       

//  __      __   _     _    ____        
//  \ \    / /  (_)   | |  / __ \       
//   \ \  / /__  _  __| | | |  | |_ __  
//    \ \/ / _ \| |/ _` | | |  | | '_ \ 
//     \  / (_) | | (_| | | |__| | |_) |
//      \/ \___/|_|\__,_|  \____/| .__/ 
//                               | |    
//                               |_|    


pragma solidity ^0.8.0;









contract MetadataGenerator is Ownable  {
    icards public cards;
    iSmelterDrillerThruster public SmelterDrillerThruster;
    iShieldFuselage_1 public ShieldFuselage_1;
    iShieldFuselage_2 public ShieldFuselage_2;
    iTraitNames public TraitNames;

    constructor(
        address cardsContract,
        address SmelterDrillerThrusterContract,
        address ShieldFuselage_1Contract,
        address ShieldFuselage_2Contract,
        address TraitNamesContract
    ) public {
        require(cardsContract != address(0), "Enter Vaild Address for Cards");
        require(
            SmelterDrillerThrusterContract != address(0),
            "Enter Vaild Address for SmelterDrillerThruster"
        );
        require(
            ShieldFuselage_1Contract != address(0),
            "Enter Vaild Address for ShieldFuselage_1Contract"
        );
        require(
            ShieldFuselage_2Contract != address(0),
            "Enter Vaild Address for ShieldFuselage_2Contract"
        );
        require(
            TraitNamesContract != address(0),
            "Enter Vaild Address for TraitNamesContract"
        );

        cards = icards(cardsContract);
        SmelterDrillerThruster = iSmelterDrillerThruster(
            SmelterDrillerThrusterContract
        );
        ShieldFuselage_1 = iShieldFuselage_1(ShieldFuselage_1Contract);
        ShieldFuselage_2 = iShieldFuselage_2(ShieldFuselage_2Contract);
        TraitNames = iTraitNames(TraitNamesContract);
    }

    string[5] public Make = [
        "Greytoo",
        "Frostwing",
        "Ironpunch",
        "Hellflux",
        "Starcore"
    ];

    string[3] public Smelter = ["Diffusive", "Matte", "Magma"];

    string[4] public Driller = ["Fibre", "Electrostatic", "Pulsed", "Plasma"];

    string[5] public Fuselage = [
        "Truss",
        "Arched",
        "Retractable",
        "Geodesic",
        "Monocoque"
    ];

    string[5] public Shield = [
        "Confined",
        "Reflective",
        "Resonant",
        "Inductive",
        "Ablative"
    ];

    string[4] public Thruster = ["Bipropellant", "Cryogenic", "Ionic", "Photonic"];

    string public img_start =
        '<image x="1" y="1" width="100" height="100" image-rendering="pixelated" xlink:href="data:image/png;base64,';
    string public img_end = '"/>';
    string public svg_start =
        '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
    string public svg_end = "</svg>";

    // Traits order -> [0 Make,1 Smelter,2 Driller,3 Fuselage,4 Shield,5 Thruster]
    function getMetadata(uint8[] memory traits, uint256 tokenId)
        public
        view
        returns (string memory)
    {
        require(traits.length == 6, "Array Size !=6");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(generateMetadata(traits, tokenId))
                )
            );
    }

    function generateMetadata(uint8[] memory traits, uint256 tokenId)
        private
        view
        returns (bytes memory)
    {
        string memory metadata = string(
            abi.encodePacked(
                '{"name":"ChainScouts Ship #',
                Strings.toString(tokenId),
                '","description":"Chain Scouts Ships","attributes":[{"trait_type":"Make","value":"',
                Make[traits[0] - 1],
                '"},{"trait_type":"Smelter","value":"',
                Smelter[traits[1] - 1],
                '"},{"trait_type":"Driller","value":"',
                Driller[traits[2] - 1],
                '"},{"trait_type":"Fuselage","value":"',
                Fuselage[traits[3] - 1],
                '"},{"trait_type":"Shield","value":"',
                Shield[traits[4] - 1],
                '"},{"trait_type":"Thruster","value":"',
                Thruster[traits[5] - 1],
                '"}],"image":"',
                generateShip(traits),
                '","tokenId":',
                Strings.toString(tokenId),
                "}"
            )
        );
        return bytes(abi.encodePacked(metadata));
    }

    function generateShip(uint8[] memory traits)
        public
        view
        returns (string memory)
    {
        string memory newCardSVG = string(
            abi.encodePacked(
                img_start,
                cards.getCards()[traits[0] - 1],
                img_end
            )
        );

        string memory newSmelterSVG = string(
            abi.encodePacked(
                img_start,
                SmelterDrillerThruster.getSmelter()[traits[1] - 1][
                    traits[3] - 1
                ],
                img_end
            )
        );

        string memory newDrillerSVG = string(
            abi.encodePacked(
                img_start,
                SmelterDrillerThruster.getDriller()[traits[2] - 1][
                    traits[3] - 1
                ],
                img_end
            )
        );

        string memory newShieldFuselageSVG = string(
            abi.encodePacked(
                img_start,
                (
                    traits[4] < 4
                        ? ShieldFuselage_1.getFuselage_1()[traits[4] - 1][
                            traits[3] - 1
                        ]
                        : ShieldFuselage_2.getFuselage_2()[traits[4] - 4][
                            traits[3] - 1
                        ]
                ),
                img_end
            )
        );

        string memory newThrusterSVG = string(
            abi.encodePacked(
                img_start,
                SmelterDrillerThruster.getThruster()[traits[5] - 1][
                    traits[3] - 1
                ],
                img_end
            )
        );

        string memory newFuselageTextSVG = string(
            abi.encodePacked(
                img_start,
                TraitNames.getFuselageText()[traits[3] - 1],
                img_end
            )
        );

        string memory newDrillerTextSVG = string(
            abi.encodePacked(
                img_start,
                TraitNames.getDrillerText()[traits[2] - 1],
                img_end
            )
        );

        string memory newSmelterTextSVG = string(
            abi.encodePacked(
                img_start,
                TraitNames.getSmelterText()[traits[1] - 1],
                img_end
            )
        );

        string memory newShieldTextSVG = string(
            abi.encodePacked(
                img_start,
                TraitNames.getShieldText()[traits[4] - 1],
                img_end
            )
        );

        string memory newThrusterTextSVG = string(
            abi.encodePacked(
                img_start,
                TraitNames.getThrusterText()[traits[5] - 1],
                img_end
            )
        );

        string memory newStarbaseTextSVG = string(
            abi.encodePacked(
                img_start,
                TraitNames.getStarbaseText()[0],
                img_end
            )
        );
        string memory first = string(
            abi.encodePacked(
                svg_start,
                newCardSVG,
                newThrusterSVG,
                newShieldFuselageSVG,
                newDrillerSVG,
                newSmelterSVG,
                newFuselageTextSVG
            )
        );

        string memory second = string(
            abi.encodePacked(
                newDrillerTextSVG,
                newSmelterTextSVG,
                newShieldTextSVG,
                newThrusterTextSVG,
                newStarbaseTextSVG,
                svg_end
            )
        );

        bytes memory svg = abi.encodePacked(
            first,
            second
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    function setCardsInterface(address cardAddress) external onlyOwner{
        require(cardAddress != address(0), "Enter Vaild Address");
        cards = icards(cardAddress);
    }

    function setSmelterDrillerThrusterInterface(
        address SmelterDrillerThrusterContract
    ) external onlyOwner {
        require(
            SmelterDrillerThrusterContract != address(0),
            "Enter Vaild Address for SmelterDrillerThruster"
        );
        SmelterDrillerThruster = iSmelterDrillerThruster(
            SmelterDrillerThrusterContract
        );
    }

    function setShieldFuselage_1Interface(
        address ShieldFuselage_1Contract
    ) external onlyOwner  {
        require(
            ShieldFuselage_1Contract != address(0),
            "Enter Vaild Address for ShieldFuselage_1"
        );
        ShieldFuselage_1 = iShieldFuselage_1(
            ShieldFuselage_1Contract
        );
    }

    function setShieldFuselage_2Interface(
        address ShieldFuselage_2Contract
    ) external onlyOwner  {
        require(
            ShieldFuselage_2Contract != address(0),
            "Enter Vaild Address for ShieldFuselage_2"
        );
        ShieldFuselage_2 = iShieldFuselage_2(
            ShieldFuselage_2Contract
        );
    }

    function setTraitNamesThrusterInterface(
        address TraitNamesContract
    ) external onlyOwner  {
        require(
            TraitNamesContract != address(0),
            "Enter Vaild Address for TraitNames"
        );
        TraitNames = iTraitNames(
            TraitNamesContract
        );
    }
}