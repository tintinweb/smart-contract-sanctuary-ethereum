//SPDX-License-Identifier: UNLICENSED

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


pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./Interfaces/ICard.sol";
import "./Interfaces/ISmelterDrillerThruster.sol";
import "./Interfaces/IShieldFuselage_1.sol";
import "./Interfaces/IShieldFuselage_2.sol";
import "./Interfaces/ITraitNames.sol";  
import "./Interfaces/ITraitGetter.sol";


contract MetadataGenerator is OwnableUpgradeable {
    icards public cards;
    iSmelterDrillerThruster public SmelterDrillerThruster;
    iShieldFuselage_1 public ShieldFuselage_1;
    iShieldFuselage_2 public ShieldFuselage_2;
    iTraitNames public TraitNames;
    ITraitGetter public TraitGetter;
    address public nftContract;
    string[5] public Make;
    string[3] public Smelter;
    string[4] public Driller;
    string[5] public Fuselage;
    string[5] public Shield;
    string[4] public Thruster;
    string public img_start;
    string public img_end;
    string public svg_start;
    string public svg_end;
    mapping (uint => uint[]) public traitMapper;

    //todo remove this function when testing is finished
    function getTraits(uint tokenId) external view returns(uint[] memory) {
        return traitMapper[tokenId];
    }


    function initialize(
        address cardsContract,
        address SmelterDrillerThrusterContract,
        address ShieldFuselage_1Contract,
        address ShieldFuselage_2Contract,
        address TraitNamesContract,
        address TraitGetterAddress
    ) public initializer {
        require(cardsContract != address(0), "Enter Valid Address for Cards");
        require(
            SmelterDrillerThrusterContract != address(0),
            "Enter Valid Address for SmelterDrillerThruster"
        );
        require(
            ShieldFuselage_1Contract != address(0),
            "Enter Valid Address for ShieldFuselage_1Contract"
        );
        require(
            ShieldFuselage_2Contract != address(0),
            "Enter Valid Address for ShieldFuselage_2Contract"
        );
        require(
            TraitNamesContract != address(0),
            "Enter Valid Address for TraitNamesContract"
        );
        cards = icards(cardsContract);
        TraitGetter = ITraitGetter(TraitGetterAddress);
        SmelterDrillerThruster = iSmelterDrillerThruster(
            SmelterDrillerThrusterContract
        );
        ShieldFuselage_1 = iShieldFuselage_1(ShieldFuselage_1Contract);
        ShieldFuselage_2 = iShieldFuselage_2(ShieldFuselage_2Contract);
        TraitNames = iTraitNames(TraitNamesContract);
        Make = [
        "Greytoo",
        "Frostwing",
        "Ironpunch",
        "Hellflux",
        "Starcore"
        ];
        Smelter = [
        "Diffusive",
        "Matte",
        "Magma"
        ];
        Driller = [
        "Fibre",
        "Electrostatic",
        "Pulsed",
        "Plasma"
        ];
        Fuselage = [
        "Truss",
        "Arched",
        "Retractable",
        "Geodesic",
        "Monocoque"
        ];
        Shield = [
        "Confined",
        "Reflective",
        "Resonant",
        "Inductive",
        "Ablative"
        ];
        Thruster = [
        "Bipropellant",
        "Cryogenic",
        "Ionic",
        "Photonic"
        ];
        img_start = '<image x="1" y="1" width="100" height="100" image-rendering="pixelated" xlink:href="data:image/png;base64,';
        img_end = '"/>';
        svg_start = '<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
        svg_end = "</svg>";
    }

    function addNFTAddress(address _nftAddress) external onlyOwner {
        nftContract = _nftAddress;
    }

    function createTraits(uint tokenId, uint randomNumber) external {
//        require (msg.sender == nftContract,'Error: Only nft contract can interact');
        uint[] memory traits = new uint[](6);
        traits[0] = TraitGetter.getMake(randomNumber);//(randomNumber);
        traits[1] = TraitGetter.getSmelter(randomNumber);
        traits[2] = TraitGetter.getDriller(randomNumber);
        traits[3] = TraitGetter.getFuselage(randomNumber);
        traits[4] = TraitGetter.getShield(randomNumber);
        traits[5] = TraitGetter.getThruster(randomNumber);
        traitMapper[tokenId] = traits;
    }

    //@dev Used only when migration is happening
    function forceCreateTraits(uint tokenId, uint256[] memory traits) external {
        require (msg.sender == nftContract,'Error: Only nft contract can interact');
        uint[] memory forceTraits = new uint[](6);
        forceTraits[0] = traits[0];
        forceTraits[1] = traits[1];
        forceTraits[2] = traits[2];
        forceTraits[3] = traits[3];
        forceTraits[4] = traits[4];
        forceTraits[5] = traits[5];
        traitMapper[tokenId] = forceTraits;
    }

    // Traits order -> [0 Make,1 Smelter,2 Driller,3 Fuselage,4 Shield,5 Thruster]
    function getMetadata(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64Upgradeable.encode(generateMetadata(traitMapper[tokenId], tokenId))
                )
            );
    }

    function generateMetadata(uint[] memory traits, uint256 tokenId)
        internal
        view
        returns (bytes memory)
    {
        string memory metadata = string(
            abi.encodePacked(
                '{"name":"ChainScouts Ship #',
                StringsUpgradeable.toString(tokenId),
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
                StringsUpgradeable.toString(tokenId),
                "}"
            )
        );
        return bytes(abi.encodePacked(metadata));
    }

    function generateShip(uint[] memory traits)
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
                    traits[4]-1 < 3
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
                    Base64Upgradeable.encode(svg)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface icards {
    function getCards() external view returns (string[5] memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface iSmelterDrillerThruster {
    function getSmelter() external view returns (string[5][3] memory);
    function getDriller() external view returns (string[5][4] memory);
    function getThruster() external view returns (string[5][4] memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface iShieldFuselage_1 {
    function getFuselage_1() external view returns (string[5][3] memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface iShieldFuselage_2 {
    function getFuselage_2() external view returns (string[5][2] memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface iTraitNames {
    function getFuselageText() external view returns (string[5] memory);
    function getDrillerText() external view returns (string[4] memory);
    function getSmelterText() external view returns (string[3] memory);
    function getShieldText() external view returns (string[5] memory);
    function getThrusterText() external view returns (string[4] memory);
    function getStarbaseText() external view returns (string[1] memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ITraitGetter {
    function getMake(uint randomNumber) external view returns(uint);
    function getSmelter(uint randomNumber) external view returns(uint);
    function getDriller(uint randomNumber) external view returns(uint);
    function getFuselage(uint randomNumber) external view returns(uint);
    function getShield(uint randomNumber) external view returns(uint);
    function getThruster(uint randomNumber) external view returns(uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}