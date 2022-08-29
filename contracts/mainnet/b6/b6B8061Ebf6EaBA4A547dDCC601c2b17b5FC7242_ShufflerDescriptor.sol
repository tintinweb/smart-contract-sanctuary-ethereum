// SPDX-License-Identifier: GPL-3.0
// Modified from nouns.wtf

/// @title The Shuffler NFT descriptor

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { IShufflerDescriptor } from './interfaces/IShufflerDescriptor.sol';
import { IShufflerToken } from './interfaces/IShufflerToken.sol';
import { NFTDescriptor } from './libs/NFTDescriptor.sol';
import { MultiPartRLEToSVG } from './libs/MultiPartRLEToSVG.sol';

contract ShufflerDescriptor is IShufflerDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Shuffler parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = false;

    // Base URI
    string public override baseURI = "ipfs://bafkreig7xbpcavvxpfqdn6x6ojsh4nboac62kxsc5dl6oyi7lt2mzunri4";

    //  Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Shuffler Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Shuffler card （Custom RLE)
    bytes[] public override cards;

    // Shuffler frames (Custom RLE)
    bytes[] public override sides;

    // Shuffler ranks and suites (Custom RLE)
    bytes[] public override corners;

    // Shuffler centers (Custom RLE)
    bytes[] public override centers;

    mapping (address => bool) public composableContracts;

    constructor() {
        composableContracts[NFTDescriptor.NOUNS_CONTRACT] = true;
        composableContracts[NFTDescriptor.PUNK_ORIGINAL_CONTRACT] = true;
        composableContracts[NFTDescriptor.BLITMAP_CONTRACT] = true;
        composableContracts[NFTDescriptor.CHAIN_RUNNER_CONTRACT] = true;
        composableContracts[NFTDescriptor.LOOT_CONTRACT] = true;
        composableContracts[NFTDescriptor.ONCHAIN_MONKEY_CONTRACT] = true;
    }

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Get the number of available Shuffler `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available `cards``
     */
    function cardCount() external view override returns (uint256) {
        return cards.length;
    }

    /**
     * @notice Get the number of available `frames`.
     */
    function sideCount() external view override returns (uint256) {
        return sides.length;
    }

    /**
     * @notice Get the number of available `corners`.
     */
    function cornerCount() external view override returns (uint256) {
        return corners.length;
    }

    /**
     * @notice Get the number of available `centers`.
     */
    function centerCount() external view override returns (uint256) {
        return centers.length;
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add cards
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyCards(bytes[] calldata _cards) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _cards.length; i++) {
            _addCard(_cards[i]);
        }
    }

    /**
     * @notice Batch add frames.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManySides(bytes[] calldata _sides) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _sides.length; i++) {
            _addSide(_sides[i]);
        }
    }

    /**
     * @notice Batch add corners.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyCorners(bytes[] calldata _corners) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _corners.length; i++) {
            _addCorner(_corners[i]);
        }
    }

    /**
     * @notice Batch add centers.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyCenters(bytes[] calldata _centers) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _centers.length; i++) {
            _addCenter(_centers[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external override onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a frame.
     * @dev This function can only be called by the owner when not locked.
     */
    function addSide(bytes calldata _side) external override onlyOwner whenPartsNotLocked {
        _addSide(_side);
    }

    /**
     * @notice Add a corner.
     * @dev This function can only be called by the owner when not locked.
     */
    function addCorner(bytes calldata _corner) external override onlyOwner whenPartsNotLocked {
        _addCorner(_corner);
    }

    /**
     * @notice Add a center.
     * @dev This function can only be called by the owner when not locked.
     */
    function addCenter(bytes calldata _center) external override onlyOwner whenPartsNotLocked {
        _addCenter(_center);
    }

    /**
     * @notice Lock all parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override {
        // using tx.origin instead of msg.sender here because we want to
        // allow the blind box reveal and data uri toggling done in one transaction
        // security is not a big concern here since the action is easily reversible
        require(owner() == tx.origin, "Ownable: caller is not the owner");
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for the give Onchain Shuffler token
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IShufflerToken.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return baseURI;
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI
     */
    function dataURI(uint256 tokenId, IShufflerToken.Seed memory seed) public view override returns (string memory) {
        string memory shufflerId = tokenId.toString();
        string memory name = string(abi.encodePacked('Shuffler #', shufflerId));

        return genericDataURI(name, "", seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        IShufflerToken.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background],
            override_contract: seed.override_contract,
            override_token_id: seed.override_token_id
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(IShufflerToken.Seed memory seed) external view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background],
            center_svg: NFTDescriptor.fetchTokenSvg(seed.override_contract, seed.override_token_id)
        });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a card.
     */
    function _addCard(bytes calldata _card) internal {
        cards.push(_card);
    }

    /**
     * @notice Add a frame.
     */
    function _addSide(bytes calldata _side) internal {
        sides.push(_side);
    }

    /**
     * @notice Add a corner.
     */
    function _addCorner(bytes calldata _corner) internal {
        corners.push(_corner);
    }

    /**
     * @notice Add a center.
     */
    function _addCenter(bytes calldata _center) internal {
        centers.push(_center);
    }

    /**
     * @notice Get all parts for the passed `seed`.
     */
    function _getPartsForSeed(IShufflerToken.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](4);
        _parts[0] = cards[seed.card];
        _parts[1] = sides[seed.side];
        _parts[2] = corners[seed.corner];
        _parts[3] = centers[seed.center];
        return _parts;
    }

    function isComposable(address addr) external view override returns (bool) {
        return composableContracts[addr];
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShufflerDescriptor

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

pragma solidity ^0.8.6;

import { IShufflerToken } from './IShufflerToken.sol';

interface IShufflerDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external view returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function cards(uint256 index) external view returns (bytes memory);

    function sides(uint256 index) external view returns (bytes memory);

    function corners(uint256 index) external view returns (bytes memory);

    function centers(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function cardCount() external view returns (uint256);

    function sideCount() external view returns (uint256);

    function cornerCount() external view returns (uint256);

    function centerCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyCards(bytes[] calldata cards) external;

    function addManySides(bytes[] calldata sides) external;

    function addManyCorners(bytes[] calldata corners) external;

    function addManyCenters(bytes[] calldata centers) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addSide(bytes calldata side) external;

    function addCorner(bytes calldata corner) external;

    function addCenter(bytes calldata center) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IShufflerToken.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IShufflerToken.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IShufflerToken.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IShufflerToken.Seed memory seed) external view returns (string memory);

    function isComposable(address addr) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for ShufflerToken

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

pragma solidity ^0.8.6;

import { IShufflerDescriptor } from './IShufflerDescriptor.sol';

interface IShufflerToken {
    event ShufflerCreated(address indexed creator, uint256 indexed startTokenId, uint256 indexed endTokenId);
    
    event NftOverridden(uint256 indexed tokenId, address indexed override_contract, uint256 indexed override_token_id);

    event DescriptorUpdated(IShufflerDescriptor descriptor);

    event DescriptorLocked();

    event SeedsLocked();

    event SeedsAdded(uint256[] seeds);

    event Reveal(uint64 offset);

    struct Seed {
        uint48 background;
        uint48 card;
        uint48 side;
        uint48 corner;
        uint48 center;
        address override_contract;
        uint64 override_token_id;
    }

    function setTreasury(address payable _treasury) external;

    function lockSeeds() external;

    function areSeedsLocked() external returns (bool);

    function addManySeeds(uint256[] calldata seeds) external;

    function seedCount() external view returns (uint256);

    function mint(uint256 count) external payable;

    function ownerMint(address to, uint256 count) external;

    function mintWhiteList(uint256 count, uint256 maxCount, bytes32[] calldata merkleProof) external payable;

    function reveal() external;

    function setDescriptor(IShufflerDescriptor descriptor) external;

    function lockDescriptor() external;

    function withdraw() external;

    function setComposePrice(uint256 _price) external;

    function setOverrideNft(uint256 tokenId, address override_contract, uint64 override_token_id) external payable;

    function removeOverrideNft(uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0
// Modified from nouns.wtf

/// @title A library used to construct ERC721 token URIs and SVG images

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

pragma solidity ^0.8.6;

import { Base64 } from './base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';
import { IERC721Metadata } from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import { NounsProxy, DescriptorProxy } from '../NounsProxy.sol';
import { PunkDataProxy } from "../PunkDataProxy.sol";
import { BlitmapProxy } from "../BlitmapProxy.sol";
import { ChainRunnerProxy, ChainRunnerRenderProxy } from "../ChainRunnerProxy.sol";

library NFTDescriptor {
    address constant NOUNS_CONTRACT = address(0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03);
    address constant PUNK_ORIGINAL_CONTRACT = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    address constant PUNK_DATA_CONTRACT = address(0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2);
    address constant BLITMAP_CONTRACT = address(0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63);
    address constant CHAIN_RUNNER_CONTRACT = address(0x97597002980134beA46250Aa0510C9B90d87A587);
    address constant LOOT_CONTRACT = address(0xFF9C1b15B16263C61d017ee9F65C50e4AE0113D7);
    address constant ONCHAIN_MONKEY_CONTRACT = address(0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A);

    struct TokenURIParams {
        string name;
        string description;
        bytes[] parts;
        string background;
        address override_contract;
        uint256 override_token_id;
    }

    // Return a substring of _data[start, end), include _data[start], exclude _data[end]
    function slice(string memory _data, uint start, uint end) internal pure returns (string memory) {
        bytes memory data = bytes(_data);
        string memory result;
        uint outputLen = end - start;

        require(start >= 0, "param error: negtive start");
        require(end > start, "param error: end is smaller or equal than start");
        require(end <= data.length, "param error: end greater than string length");

        if (data.length == 0) return "";
        assembly {
            result := add(data, start)
            mstore(result, outputLen)
        }

        return result;
    }

    function fetchTokenSvg(address tokenContract, uint256 tokenId) public view returns (string memory) {
        string memory decoded_uri = "";
        if (tokenContract == address(0)) {
            return decoded_uri;
        }
        if (NOUNS_CONTRACT == tokenContract) {
            decoded_uri = _handleNounsTokenUri(tokenContract, tokenId);
        } else if (PUNK_ORIGINAL_CONTRACT == tokenContract) {
            decoded_uri = _handlePunkTokenUri(tokenId);
        } else if (BLITMAP_CONTRACT == tokenContract) {
            decoded_uri = _handleBlitmapTokenUri(tokenContract, tokenId);
        } else if (CHAIN_RUNNER_CONTRACT == tokenContract) {
            decoded_uri = _handleChainRunnerTokenUri(tokenContract, tokenId);
        } else {
            decoded_uri = _handleGeneral721TokenUri(tokenContract, tokenId);
        }
        return decoded_uri;
    }

    function _handleNounsTokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        NounsProxy otherContract = NounsProxy(tokenContract);
        (uint48 a, uint48 b, uint48 c, uint48 d, uint48 e) = otherContract.seeds(tokenId);
        NounsProxy.Seed memory seed = NounsProxy.Seed(a, b, c, d, e);
        DescriptorProxy descriptor = otherContract.descriptor();

        string memory encoded_uri = descriptor.generateSVGImage(seed);
        return string(Base64.decode(encoded_uri));
    }

    function _handlePunkTokenUri(uint256 tokenId) internal view returns (string memory) {
        PunkDataProxy otherContract = PunkDataProxy(PUNK_DATA_CONTRACT);
        string memory svgWithHeader = otherContract.punkImageSvg(uint16(tokenId));
        // remove header "data:image/svg+xml;utf8," and return
        return slice(svgWithHeader, 24, bytes(svgWithHeader).length);
    }

    function _handleBlitmapTokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        BlitmapProxy otherContract = BlitmapProxy(tokenContract);
        string memory svgWithHeader = otherContract.tokenSvgDataOf(tokenId);
        return slice(svgWithHeader, 54, bytes(svgWithHeader).length);
    }

    function _handleChainRunnerTokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        ChainRunnerProxy otherContract = ChainRunnerProxy(tokenContract);
        ChainRunnerRenderProxy renderContract = ChainRunnerRenderProxy(otherContract.renderingContractAddress());
        string memory encodedUri = renderContract.onChainTokenURI(tokenId);
        // remove prefix "data:application/json;base64," and decode
        string memory headlessEncodedUri = slice(encodedUri, 29, bytes(encodedUri).length);
        return string(Base64.decodeChainRunnerBase64(headlessEncodedUri));
    }

    function _handleGeneral721TokenUri(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        IERC721Metadata otherContract = IERC721Metadata(tokenContract);
        string memory encodedUri = otherContract.tokenURI(tokenId);
        // remove prefix "data:application/json;base64," and decode
        string memory headlessEncodedUri = slice(encodedUri, 29, bytes(encodedUri).length);
        return string(Base64.decodeGetJsonImgDecoded(headlessEncodedUri));
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            MultiPartRLEToSVG.SVGParams({
                parts: params.parts,
                background: params.background,
                center_svg: fetchTokenSvg(params.override_contract, params.override_token_id)
            }),
            palettes
        );

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

library MultiPartRLEToSVG {
    struct SVGParams {
        bytes[] parts;
        string background;
        string center_svg;
    }

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteIndex;
        ContentBounds bounds;
        Rect[] rects;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        internal
        view
        returns (string memory svg)
    {
        string memory svg_head = string(
            abi.encodePacked(
                '<svg viewBox="0 0 840 840" xmlns="http://www.w3.org/2000/svg">',
                '<svg width="840" height="840" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '</svg>'
            )
        );
        if (bytes(params.center_svg).length == 0) {
            return string(abi.encodePacked(svg_head, '</svg>'));
        } else {
            return string(
                abi.encodePacked(
                    svg_head,
                    '<svg width="320" height="320" x="260" y="260">',
                    params.center_svg,
                    '</svg></svg>'
                )
            );
        }

    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        view
        returns (string memory svg)
    {
        string[85] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70', '80', '90',
            '100', '110', '120', '130', '140', '150', '160', '170', '180', '190',
            '200', '210', '220', '230', '240', '250', '260', '270', '280', '290',
            '300', '310', '320', '330', '340', '350', '360', '370', '380', '390',
            '400', '410', '420', '430', '440', '450', '460', '470', '480', '490',
            '500', '510', '520', '530', '540', '550', '560', '570', '580', '590',
            '600', '610', '620', '630', '640', '650', '660', '670', '680', '690',
            '700', '710', '720', '730', '740', '750', '760', '770', '780', '790',
            '800', '810', '820', '830', '840'
        ];
        string memory rects;
        uint256 len = params.parts.length;
        if (bytes(params.center_svg).length > 0) {
            // if there is an override center image then we don't have to render the center
            len--;
        }
        for (uint8 p = 0; p < len; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            string[] storage palette = palettes[image.paletteIndex];
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all rects in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }
        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**************************************************************************
...........................................................................
...........................................................................
...........................................................................
...........................................................................
.....................     ...............      .......      ...............
...................  .?5?:  ........... .::::::. ... .:::::.  .............
.................  :?B&@&B?:  ....... .^7??????!:. .~7??????~: ............
...............  :J#&&&&&&&#J:  .....^7??????JJJ?!!7????JJJ?J?!............
.............  ^Y#&&&&&&&&&&&#Y^  .. !J??YGGP^^~?JJ?5GGJ^^~????: ..........
...........  ^5&@&&&&&&&&&&&&&@&5~   [email protected]@B. [email protected]@Y  :????:...........
.......... :5&&BBB###&&&&#BBB###&&P: [email protected]@B. [email protected]@Y  :???7............
......... ^P&&#:..7J?G&&&5..:??J#&&G~ ~??J55Y!!!????Y5PJ!!!??7.............
......... [email protected]&&#.  7??G&&&5  :??J#&&@7  ^?????JJJ????????JJJ?7..............
......... [email protected]&&#~^^JYJB&&&P^^~JYY#&&@7 ..:~?J??????????????7^...............
......... :JB&&&&&&&&B#&#B&&&&&&&&#J: ..  .~?J????????J?!:. ...............
..........  :?BBBBBB5YB&BY5BBBBBB?:  .....  .~77???J?7!:. .................
............  ....^Y#@@&@@#Y^....  .......... ..^!7~:.. ...................
..............   .!777???777!.   ............   :^^^.   ...................
..................  .^7?7^.  .............. .~Y5#&&&G57: ..................
................  :~???????~:  .............!&&&&&&&&@@5:..................
.............. .:!?J???????J?!:  ......... ~&&&&&&&&&&&@5 .................
............ .:!??JJJ????????J?!:. ......  ^B&&&&&&&&&&&J  ................
............^!JGBG!^^7???YBBP^^~?!^. .   .^^~YG&&&&&&#57^^:   .............
......... :7??J&&&^  [email protected]@B. .?J?7: :?5G&&&#PY#&&&P5B&&&#5Y^ ............
...........~7?J&&&^  [email protected]@B. .?J?~.:Y&@G77?555#&&&Y!7J55P&&#~............
........... .^75557!!7???J55Y!!!7~.  [email protected]&&5  .???#&&&7  ^??Y&&&&: ..........
............. .^7?JJ?????????J7^. .. J&&&5  .??J#&&&7  ^??Y&&&G: ..........
............... .^7?J???????7^. ..... ?#@#55PBG5#&&&5J5PBBB&&P: ...........
................. .:!?JJJ?!:. ........ ^!JBBBGYP&&&&B5PBBBP!!. ............
................... .:!7!:. ...........   ..:JGBGGGGBG5~ ..   .............
..................... ... ................. ............ ..................
...........................................................................
...........................................................................
...........................................................................
...........................................................................
***************************************************************************/

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }

    // @author onchain shufflers
    // optimized decoder for Chainrunners, one pass base64 decode and json string retrieval
    // return "image_data" field and insert "svg:nth-child(2) " in <style>
    // input: base64 encoded json with format
    // {"name":"Runner #0", "description":"Chain Runners", "image_data": "<begin><style></style></end>"}
    // output: base64 string from the "image_data" field, i.e. "<begin><style>svg:nth-child(2) </style></end>"
    function decodeChainRunnerBase64(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes((data.length / 4) * 3 + 32);

        assembly {
            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            let state := 0 // FSM state
            let resultLen := 0
            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
                    ),
                    add(
                        shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                let threeChar := shl(232, output)

                for {let i := 0} lt(i, 3) {i := add(i, 1)} {
                    let b := byte(i, threeChar)

                    switch state
                    // "
                    case 0 {switch eq(and(b, 0xFF), 0x22) case 1 {state := add(state, 1)}}
                    // i
                    case 1 {switch eq(and(b, 0xFF), 0x69) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // m
                    case 2 {switch eq(and(b, 0xFF), 0x6d) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // a
                    case 3 {switch eq(and(b, 0xFF), 0x61) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // g
                    case 4 {switch eq(and(b, 0xFF), 0x67) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // e
                    case 5 {switch eq(and(b, 0xFF), 0x65) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // _
                    case 6 {switch eq(and(b, 0xFF), 0x5f) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // d
                    case 7 {switch eq(and(b, 0xFF), 0x64) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // a
                    case 8 {switch eq(and(b, 0xFF), 0x61) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // t
                    case 9 {switch eq(and(b, 0xFF), 0x74) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // a
                    case 10 {switch eq(and(b, 0xFF), 0x61) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // "
                    case 11 {switch eq(and(b, 0xFF), 0x22) case 1 {state := add(state, 1)} case 0 {state := 0}}
                    // until "
                    case 12 {switch eq(and(b, 0xFF), 0x22) case 1 {state := add(state, 1)} case 0 {}}
                    // store char string until <style>
                    case 13 {
                        switch eq(and(b, 0xFF), 0x3c) case 1 {state := add(state, 1)} case 0 {}
                        mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)
                    }
                    // s
                    case 14 {mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)
                        switch eq(and(b, 0xFF), 0x73) case 1 {state := add(state, 1)} case 0 {state := 13}}
                    // t
                    case 15 {mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)
                        switch eq(and(b, 0xFF), 0x74) case 1 {state := add(state, 1)} case 0 {state := 13}}
                    // y
                    case 16 {mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)
                        switch eq(and(b, 0xFF), 0x79) case 1 {state := add(state, 1)} case 0 {state := 13}}
                    // l
                    case 17 {mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)
                        switch eq(and(b, 0xFF), 0x6c) case 1 {state := add(state, 1)} case 0 {state := 13}}
                    // e
                    case 18 {mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)
                        switch eq(and(b, 0xFF), 0x65) case 1 {state := add(state, 1)} case 0 {state := 13}}
                    // >
                    case 19 {
                        mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)
                        switch eq(and(b, 0xFF), 0x3e)
                        case 1 {
                            // some svg magic
                            // insert "svg:nth-child(2) " to limit the scope of <style>
                            // chainrunner uses customized style for svg <rect> which messed up our pokers
                            mstore8(resultPtr, 0x73) resultPtr := add(resultPtr, 1) // s
                            mstore8(resultPtr, 0x76) resultPtr := add(resultPtr, 1) // v
                            mstore8(resultPtr, 0x67) resultPtr := add(resultPtr, 1) // g
                            mstore8(resultPtr, 0x3a) resultPtr := add(resultPtr, 1) // :
                            mstore8(resultPtr, 0x6e) resultPtr := add(resultPtr, 1) // n
                            mstore8(resultPtr, 0x74) resultPtr := add(resultPtr, 1) // t
                            mstore8(resultPtr, 0x68) resultPtr := add(resultPtr, 1) // h
                            mstore8(resultPtr, 0x2d) resultPtr := add(resultPtr, 1) // -
                            mstore8(resultPtr, 0x63) resultPtr := add(resultPtr, 1) // c
                            mstore8(resultPtr, 0x68) resultPtr := add(resultPtr, 1) // h
                            mstore8(resultPtr, 0x69) resultPtr := add(resultPtr, 1) // i
                            mstore8(resultPtr, 0x6c) resultPtr := add(resultPtr, 1) // l
                            mstore8(resultPtr, 0x64) resultPtr := add(resultPtr, 1) // d
                            mstore8(resultPtr, 0x28) resultPtr := add(resultPtr, 1) // (
                            mstore8(resultPtr, 0x32) resultPtr := add(resultPtr, 1) // 2
                            mstore8(resultPtr, 0x29) resultPtr := add(resultPtr, 1) // )
                            mstore8(resultPtr, 0x20) resultPtr := add(resultPtr, 1) // " "
                            resultLen := add(resultLen, 17)
                            state := add(state, 1)
                        } case 0 {state := 13}}
                    // store char string until "
                    case 20 {switch eq(and(b, 0xFF), 0x22) case 1 {state := add(state, 1)} case 0 {
                        mstore(resultPtr, shl(248, b)) resultPtr := add(resultPtr, 1) resultLen := add(resultLen, 1)}
                    }
                    default {}
                }
            }
            mstore(result, resultLen)
        }
        return result;
    }

    // @author onchain shufflers
    // optimized decoder: one pass decode, string slicing and decode
    // input: base64 encoded json with format
    //        {"name":"Noun 0", "description":"Nouns DAO", "image": "data:image/svg+xml;base64,aGVsbG8="}
    // output: decoded base64 string from the "image" field, i.e. "hello"
    // ref: Decoding Base64 with padding, https://en.wikipedia.org/wiki/Base64
    function decodeGetJsonImgDecoded(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes((data.length / 4) * 3 + 32);

        assembly {
            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            let state := 0 // FSM state
            let resultLen := 0
            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )

                input := 0
                for { let i := 0 } lt(i, 3) { i := add(i, 1) } {
                    let b := byte(i, shl(232, output)) // top three char

                    switch state
                        // "
                        case 0 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } }
                        // i
                        case 1 { switch eq(and(b, 0xFF), 0x69) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // m
                        case 2 { switch eq(and(b, 0xFF), 0x6d) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // a
                        case 3 { switch eq(and(b, 0xFF), 0x61) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // g
                        case 4 { switch eq(and(b, 0xFF), 0x67) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // e
                        case 5 { switch eq(and(b, 0xFF), 0x65) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // "
                        case 6 { switch eq(and(b, 0xFF), 0x22) case 1 { state := add(state, 1) } case 0 { state := 0 } }
                        // until ,
                        case 7 { switch eq(and(b, 0xFF), 0x2c) case 1 { state := add(state, 1) } case 0 {  } }
                        // start processing embeded base64 string, until "
                        case 8 { switch eq(and(b, 0xFF), 0x22) // if "
                            case 1 { state := 100 } // exit
                            case 0 { // store 1st char
                                mstore8(resultPtr, b)
                                resultPtr := add(resultPtr, 1)
                                state := add(state, 1)
                            }
                        }
                        case 9 { // store 2nd char
                            mstore8(resultPtr, b)
                            resultPtr := add(resultPtr, 1)
                            state := add(state, 1)
                        }

                        case 10 { switch eq(and(b, 0xFF), 0x3d) // if =
                            case 1 { // decode and exit
                                resultPtr := sub(resultPtr, 2)
                                input := shr(224, mload(resultPtr))
                                data := add(
                                    add(
                                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                                    add(
                                        shl(6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                                    )
                                )
                                mstore(resultPtr, shl(232, data))
                                resultLen := add(resultLen, 1)
                                state := 100
                            } case 0 { // store 3rd char
                                mstore8(resultPtr, b)
                                resultPtr := add(resultPtr, 1)
                                state := add(state, 1)
                            }
                        }
                        case 11 { switch eq(and(b, 0xFF), 0x3d) // if =
                            case 1 { // decode and exit
                                resultPtr := sub(resultPtr, 3)
                                input := shr(224, mload(resultPtr))
                                data := add(
                                    add(
                                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                                    add(
                                        shl(6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                                    )
                                )
                                mstore(resultPtr, shl(232, data))
                                resultLen := add(resultLen, 2)
                                state := 100
                            } case 0 { // decode and continue parsing
                                mstore8(resultPtr, b)
                                resultPtr := add(resultPtr, 1)
                                resultPtr := sub(resultPtr, 4)
                                input := shr(224, mload(resultPtr))
                                data := add(
                                    add(
                                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                                    add(
                                        shl(6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                                    )
                                )
                                mstore(resultPtr, shl(232, data))
                                resultPtr := add(resultPtr, 3)
                                resultLen := add(resultLen, 3)
                            }
                            state := 8
                        }
                        default { }
                }
            }
            mstore(result, resultLen)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


/**
 * A mock contract we use to call method from nouns contract without depending on nouns contract
 */
abstract contract NounsProxy {
    struct Seed {
        uint48 background;
        uint48 card;
        uint48 side;
        uint48 corner;
        uint48 center;
    }

    mapping(uint256 => Seed) public seeds;

    DescriptorProxy public descriptor;
}

abstract contract DescriptorProxy {
    function generateSVGImage(NounsProxy.Seed memory seed) virtual external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


abstract contract PunkDataProxy {
    function punkImageSvg(uint16 index) virtual external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


abstract contract BlitmapProxy {
    function tokenSvgDataOf(uint256 tokenId) virtual external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


abstract contract ChainRunnerProxy {
    address public renderingContractAddress;
}

abstract contract ChainRunnerRenderProxy {
    function onChainTokenURI(uint256 tokenId) virtual external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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