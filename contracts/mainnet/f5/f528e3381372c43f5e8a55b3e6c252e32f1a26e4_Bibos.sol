// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

/* solhint-disable */
// -╖╖╖╖╖╖╖╖╖╖╖»─  ─┬╖╖╖╖─~  -╖╖╖╖╖╖╖╖╖╖╖»─    -╖╖╖╖╖╖╖╖╖╖»─   ~─╖╖╖╖╖╖╖╖╖╖╖~
//    ███   `███      ███▌      ███   `███      ┌▓██^ █ ╙██╗     á███^   ╔██
//    █B█     ███▌    █I█Γ      █B█     ███▌    █O█   █   ███▄   █S█▌    ███
//    ███    ╒███     ███Γ      ███    ╒███    ███    █    ███   ▀██▓    ██
//    ███   á██▀      ███Γ      ███   #██╜    ╞███    █    ███    `███▄  '█╕
//    ███▄▓██▄        ███Γ      ███▄▓██▄      ╞██▌    █    ███       ╙██╗  `
//    ███    "██▌     ███Γ      ███    "██▌   '██▌    █'   ███   ,╗█"   ▀██w
//   ▓███      ▓██    ████     ▓███      ███   ███    █   ┌██   ██        ███▓
//    ███      ▐███  ^╙███     └███      ╞███   ██╕   ╫   ██▌  ██          ███
//    █B█      â██▌    I▐█      █B█      ║██▌    █O┐  ║   █▀   ██          █S█
//    ███     #██`     ╓▓█      ███     #██`      └█▌ ║ ╣█     ║█ε        ╒███
//   ╔██▓╗╗@▀╝^        "╙██┐   á██▓╗╗@▀╨^           `▀██        '█╗     ,Æ██`
//                         "▀≥»-                      ╞            ^╙▀▀╜"
/* solhint-enable */

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {Render} from "libraries/Render.sol";

error InsufficentValue();
error MintedOut();
error InvalidTokenId();
error AmountNotAvailable();

contract Bibos is ERC721, Owned {
    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/

    uint256 public constant price = .1 ether;
    uint256 public constant maxSupply = 1111;

    uint256 public totalSupply;
    mapping(uint256 => bytes32) public seeds; // (tokenId => seed)

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier OnlyIfYouPayEnough(uint256 _amount) {
        if (msg.value != _amount * price) revert InsufficentValue();
        _;
    }

    modifier OnlyIfNotMintedOut() {
        if (totalSupply >= maxSupply) revert MintedOut();
        _;
    }

    modifier OnlyIfAvailableSupply(uint256 _amount) {
        if (_amount + totalSupply > maxSupply) revert AmountNotAvailable();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("Bibos", "BIBO") Owned(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                                TOKENURI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        if (_tokenId >= totalSupply) revert InvalidTokenId();
        bytes32 seed = seeds[_tokenId];

        return Render.tokenURI(_tokenId, seed);
    }

    /*//////////////////////////////////////////////////////////////
                                  MINT
    //////////////////////////////////////////////////////////////*/

    function mint() public payable OnlyIfNotMintedOut OnlyIfYouPayEnough(1) {
        _mint(msg.sender);
    }

    function mint(uint256 _amount)
        public
        payable
        OnlyIfNotMintedOut
        OnlyIfAvailableSupply(_amount)
        OnlyIfYouPayEnough(_amount)
    {
        for (; _amount > 0; ) {
            _mint(msg.sender);
            --_amount;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function withdraw(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _mint(address _to) internal {
        uint256 tokenId = totalSupply++;
        seeds[tokenId] = _seed(tokenId);
        ERC721._mint(_to, tokenId);
    }

    function _seed(uint256 _tokenId) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, block.timestamp, _tokenId));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Metadata} from "libraries/Metadata.sol";
import {Util} from "libraries/Util.sol";
import {Traits} from "libraries/Traits.sol";
import {Data} from "./Data.sol";
import {Palette} from "libraries/Palette.sol";
import {Background} from "./Background.sol";
import {Body} from "./Body.sol";
import {Face} from "./Face.sol";
import {Motes} from "./Motes.sol";
import {Glints} from "./Glints.sol";
import {Traits} from "./Traits.sol";
import {SVG} from "./SVG.sol";

library Render {
    string public constant description =
        "Floating. Hypnotizing. Divine? Bibos are 1111 friendly spirits for your wallet. Join the billions of people who love and adore bibos today.";

    /*//////////////////////////////////////////////////////////////
                                TOKENURI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 _tokenId, bytes32 _seed) internal pure returns (string memory) {
        return
            Metadata.encodeMetadata({
                _tokenId: _tokenId,
                _name: _name(_tokenId),
                _description: description,
                _attributes: Traits.attributes(_seed, _tokenId),
                _backgroundColor: Palette.backgroundFill(_seed, _tokenId),
                _svg: _svg(_seed, _tokenId)
            });
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _svg(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        return
            SVG.element(
                "svg",
                SVG.svgAttributes(),
                Data.defs(),
                Background.render(_seed, _tokenId),
                Body.render(_seed, _tokenId),
                Motes.render(_seed, _tokenId),
                Glints.render(_seed),
                Face.render(_seed)
            );
    }

    function _name(uint256 _tokenId) internal pure returns (string memory) {
        return string.concat("Bibo ", Util.uint256ToString(_tokenId, 4));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {Base64} from "./Base64.sol";
import {Util} from "./Util.sol";

library Metadata {
    string constant JSON_BASE64_HEADER = "data:application/json;base64,";
    string constant SVG_XML_BASE64_HEADER = "data:image/svg+xml;base64,";

    function encodeMetadata(
        uint256 _tokenId,
        string memory _name,
        string memory _description,
        string memory _attributes,
        string memory _backgroundColor,
        string memory _svg
    ) internal pure returns (string memory) {
        string memory metadata = string.concat(
            "{",
            Util.keyValue("tokenId", Util.uint256ToString(_tokenId)),
            ",",
            Util.keyValue("name", _name),
            ",",
            Util.keyValue("description", _description),
            ",",
            Util.keyValueNoQuotes("attributes", _attributes),
            ",",
            Util.keyValue("backgroundColor", _backgroundColor),
            ",",
            Util.keyValue("image", _encodeSVG(_svg)),
            "}"
        );

        return _encodeJSON(metadata);
    }

    /// @notice base64 encode json
    /// @param _json, stringified json
    /// @return string, bytes64 encoded json with prefix
    function _encodeJSON(string memory _json) internal pure returns (string memory) {
        return string.concat(JSON_BASE64_HEADER, Base64.encode(_json));
    }

    /// @notice base64 encode svg
    /// @param _svg, stringified json
    /// @return string, bytes64 encoded svg with prefix
    function _encodeSVG(string memory _svg) internal pure returns (string memory) {
        return string.concat(SVG_XML_BASE64_HEADER, Base64.encode(bytes(_svg)));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;
import {Test, console2} from "forge-std/Test.sol";

/// @title the bibos utility library
/// @notice utility functions
library Util {
    error NumberHasTooManyDigits();

    /// @notice wraps a string in quotes and adds a space after
    function quote(string memory value) internal pure returns (string memory) {
        return string.concat('"', value, '" ');
    }

    function keyValue(string memory _key, string memory _value) internal pure returns (string memory) {
        return string.concat('"', _key, '":"', _value, '"');
    }

    function keyValueNoQuotes(string memory _key, string memory _value) internal pure returns (string memory) {
        return string.concat('"', _key, '":', _value);
    }

    /// @notice converts a tokenId to string and pads to _digits digits
    /// @dev tokenId must be less than 10**_digits
    /// @param _tokenId, uint256, the tokenId
    /// @param _digits, uint8, the number of digits to pad to
    /// @return result the resulting string
    function uint256ToString(uint256 _tokenId, uint8 _digits) internal pure returns (string memory result) {
        uint256 max = 10**_digits;
        if (_tokenId >= max) revert NumberHasTooManyDigits();
        // add leading zeroes
        result = uint256ToString(_tokenId + max);
        assembly {
            // cut off one character
            result := add(result, 1)
            // store new length = _digits
            mstore(result, _digits)
        }
    }

    /// @notice converts a uint256 to ascii representation, without leading zeroes
    /// @param _value, uint256, the value to convert
    /// @return result the resulting string
    function uint256ToString(uint256 _value) internal pure returns (string memory result) {
        if (_value == 0) return "0";

        assembly {
            // largest uint = 2^256-1 has 78 digits
            // reserve 110 = 78 + 32 bytes of data in memory
            // (first 32 are for string length)

            // get 110 bytes of free memory
            result := add(mload(0x40), 110)
            mstore(0x40, result)

            // keep track of digits
            let digits := 0

            for {

            } gt(_value, 0) {

            } {
                // increment digits
                digits := add(digits, 1)
                // go back one byte
                result := sub(result, 1)
                // compute ascii char
                let c := add(mod(_value, 10), 48)
                // store byte
                mstore8(result, c)
                // advance to next digit
                _value := div(_value, 10)
            }
            // go back 32 bytes
            result := sub(result, 32)
            // store the length
            mstore(result, digits)
        }
    }

    function bytes1ToString(bytes1 _value) internal pure returns (string memory) {
        return uint256ToString(uint8(_value));
    }

    function uint8ToString(uint8 _value) internal pure returns (string memory) {
        return uint256ToString(_value);
    }

    /// @notice will revert in any characters are not in [0-9]
    function stringToUint256(string memory _value) internal pure returns (uint256 result) {
        // 0-9 are 48-57

        bytes memory value = bytes(_value);
        if (value.length == 0) return 0;
        uint256 multiplier = 10**(value.length - 1);
        uint256 i;
        while (multiplier != 0) {
            result += uint256((uint8(value[i]) - 48)) * multiplier;
            unchecked {
                multiplier /= 10;
                ++i;
            }
        }
    }

    function bytes1ToHex(bytes1 _value) internal pure returns (string memory) {
        bytes memory result = new bytes(2);
        uint8 x = uint8(_value);

        result[0] = getHexChar(x >> 4);
        result[1] = getHexChar(x % 16);

        return string(result);
    }

    function getHexChar(uint8 _value) internal pure returns (bytes1) {
        if (_value < 10) {
            return bytes1(_value + 48);
        }
        _value -= 10;
        return bytes1(_value + 97);
    }

    function stringToBytes1(string memory _value) internal pure returns (bytes1 result) {
        return bytes1(uint8(stringToUint256(_value)));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DensityType, PolarityType} from "./Palette.sol";
import {MoteType} from "./Motes.sol";
import {EyeType} from "./Eyes.sol";
import {CheekType} from "./Cheeks.sol";
import {MouthType} from "./Mouth.sol";
import {Glints} from "./Glints.sol";
import {Util} from "./Util.sol";

library Traits {
    /*//////////////////////////////////////////////////////////////
                                 TRAITS
    //////////////////////////////////////////////////////////////*/

    function attributes(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        string memory result = "[";
        result = string.concat(result, _attribute("Density", densityTrait(_seed, _tokenId)));
        result = string.concat(result, ",", _attribute("Polarity", polarityTrait(_seed, _tokenId)));
        result = string.concat(result, ",", _attribute("Glints", glintTrait(_seed)));
        result = string.concat(result, ",", _attribute("Motes", moteTrait(_seed)));
        result = string.concat(result, ",", _attribute("Eyes", eyeTrait(_seed)));
        result = string.concat(result, ",", _attribute("Mouth", mouthTrait(_seed)));
        result = string.concat(result, ",", _attribute("Cheeks", cheekTrait(_seed)));
        result = string.concat(result, ",", _attribute("Virtue", virtueTrait(_seed)));
        return string.concat(result, "]");
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _attribute(string memory _traitType, string memory _value) internal pure returns (string memory) {
        return string.concat("{", Util.keyValue("trait_type", _traitType), ",", Util.keyValue("value", _value), "}");
    }

    function _rarity(bytes32 _seed, string memory _salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(_seed, _salt))) % 100;
    }

    /*//////////////////////////////////////////////////////////////
                                 DENSITY
    //////////////////////////////////////////////////////////////*/

    function densityTrait(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        DensityType type_ = densityType(_seed, _tokenId);
        return type_ == DensityType.HIGH ? "High" : "Low";
    }

    function densityType(bytes32 _seed, uint256 _tokenId) internal pure returns (DensityType) {
        uint256 densityRarity = _rarity(_seed, "density");

        if (_tokenId == 0) return DensityType.HIGH;
        if (densityRarity < 80) return DensityType.HIGH;
        return DensityType.LOW;
    }

    /*//////////////////////////////////////////////////////////////
                                POLARITY
    //////////////////////////////////////////////////////////////*/

    function polarityTrait(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        PolarityType type_ = polarityType(_seed, _tokenId);
        return type_ == PolarityType.POSITIVE ? "Positive" : "Negative";
    }

    function polarityType(bytes32 _seed, uint256 _tokenId) internal pure returns (PolarityType) {
        uint256 polarityRarity = _rarity(_seed, "polarity");

        if (_tokenId == 0) return PolarityType.POSITIVE;
        if (polarityRarity < 80) return PolarityType.POSITIVE;
        return PolarityType.NEGATIVE;
    }

    /*//////////////////////////////////////////////////////////////
                                  MOTE
    //////////////////////////////////////////////////////////////*/

    function moteTrait(bytes32 _seed) internal pure returns (string memory) {
        MoteType type_ = moteType(_seed);

        if (type_ == MoteType.FLOATING) return "Floating";
        if (type_ == MoteType.RISING) return "Rising";
        if (type_ == MoteType.FALLING) return "Falling";
        if (type_ == MoteType.GLISTENING) return "Glistening";
        return "None";
    }

    function moteType(bytes32 _seed) internal pure returns (MoteType) {
        uint256 moteRarity = _rarity(_seed, "mote");

        if (moteRarity < 20) return MoteType.FLOATING;
        if (moteRarity < 35) return MoteType.RISING;
        if (moteRarity < 50) return MoteType.FALLING;
        if (moteRarity < 59) return MoteType.GLISTENING;
        return MoteType.NONE;
    }

    /*//////////////////////////////////////////////////////////////
                                   EYE
    //////////////////////////////////////////////////////////////*/

    function eyeTrait(bytes32 _seed) internal pure returns (string memory) {
        EyeType type_ = eyeType(_seed);

        if (type_ == EyeType.OVAL) return "Oval";
        if (type_ == EyeType.SMILEY) return "Smiley";
        if (type_ == EyeType.WINK) return "Wink";
        if (type_ == EyeType.ROUND) return "Round";
        if (type_ == EyeType.SLEEPY) return "Sleepy";
        if (type_ == EyeType.CLOVER) return "Clover";
        if (type_ == EyeType.STAR) return "Star";
        if (type_ == EyeType.DIZZY) return "Dizzy";
        if (type_ == EyeType.HEART) return "Heart";
        if (type_ == EyeType.HAHA) return "Haha";
        if (type_ == EyeType.CYCLOPS) return "Cyclops";
        return "Opaline";
    }

    function eyeType(bytes32 _seed) internal pure returns (EyeType) {
        uint256 eyeRarity = _rarity(_seed, "eye");

        if (eyeRarity < 20) return EyeType.OVAL;
        if (eyeRarity < 40) return EyeType.ROUND;
        if (eyeRarity < 50) return EyeType.SMILEY;
        if (eyeRarity < 60) return EyeType.SLEEPY;
        if (eyeRarity < 70) return EyeType.WINK;
        if (eyeRarity < 80) return EyeType.HAHA;
        if (eyeRarity < 84) return EyeType.CLOVER;
        if (eyeRarity < 88) return EyeType.STAR;
        if (eyeRarity < 92) return EyeType.DIZZY;
        if (eyeRarity < 96) return EyeType.HEART;
        if (eyeRarity < 99) return EyeType.CYCLOPS;
        return EyeType.OPALINE;
    }

    /*//////////////////////////////////////////////////////////////
                                  MOUTH
    //////////////////////////////////////////////////////////////*/

    function mouthTrait(bytes32 _seed) internal pure returns (string memory) {
        MouthType type_ = mouthType(_seed);
        if (type_ == MouthType.SMILE) return "Smile";
        if (type_ == MouthType.SMIRK) return "Smirk";
        if (type_ == MouthType.GRATIFIED) return "Gratified";
        if (type_ == MouthType.POLITE) return "Polite";
        if (type_ == MouthType.HMM) return "Hmm";
        if (type_ == MouthType.OOO) return "Ooo";
        if (type_ == MouthType.TOOTHY) return "Toothy";
        if (type_ == MouthType.VEE) return "Vee";
        if (type_ == MouthType.GRIN) return "Grin";
        if (type_ == MouthType.BLEP) return "Blep";
        if (type_ == MouthType.SMOOCH) return "Smooch";
        return "Cat";
    }

    function mouthType(bytes32 _seed) internal pure returns (MouthType) {
        uint256 mouthRarity = _rarity(_seed, "mouth");

        if (mouthRarity < 20) return MouthType.SMILE;
        if (mouthRarity < 40) return MouthType.GRATIFIED;
        if (mouthRarity < 60) return MouthType.POLITE;
        if (mouthRarity < 70) return MouthType.GRIN;
        if (mouthRarity < 80) return MouthType.SMIRK;
        if (mouthRarity < 89) return MouthType.VEE;
        if (mouthRarity < 92) return MouthType.OOO;
        if (mouthRarity < 94) return MouthType.HMM;
        if (mouthRarity < 95) return MouthType.TOOTHY;
        if (mouthRarity < 97) return MouthType.BLEP;
        if (mouthRarity < 98) return MouthType.SMOOCH;
        return MouthType.CAT;
    }

    /*//////////////////////////////////////////////////////////////
                                 CHEEKS
    //////////////////////////////////////////////////////////////*/

    function cheekTrait(bytes32 _seed) internal pure returns (string memory) {
        CheekType type_ = cheekType(_seed);
        if (type_ == CheekType.NONE) return "None";
        if (type_ == CheekType.CIRCULAR) return "Circular";
        if (type_ == CheekType.BIG) return "Big";
        return "Freckles";
    }

    function cheekType(bytes32 _seed) internal pure returns (CheekType) {
        uint256 cheekRarity = _rarity(_seed, "cheeks");

        if (cheekRarity < 50) return CheekType.NONE;
        if (cheekRarity < 75) return CheekType.CIRCULAR;
        if (cheekRarity < 85) return CheekType.BIG;
        return CheekType.FRECKLES;
    }

    /*//////////////////////////////////////////////////////////////
                                  GLINT
    //////////////////////////////////////////////////////////////*/

    function glintTrait(bytes32 _seed) internal pure returns (string memory) {
        uint256 count = glintCount(_seed);
        return Util.uint256ToString(count);
    }

    function glintCount(bytes32 _seed) internal pure returns (uint256) {
        uint256 glintRarity = _rarity(_seed, "glint");

        if (glintRarity < 1) return 3;
        if (glintRarity < 5) return 2;
        if (glintRarity < 35) return 1;
        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                                  VIRTUE
    //////////////////////////////////////////////////////////////*/

    function virtueTrait(bytes32 _seed) internal pure returns (string memory) {
        return virtueType(_seed);
    }

    function virtueType(bytes32 _seed) internal pure returns (string memory) {
        uint256 virtueRarity = _rarity(_seed, "virtue");

        if (virtueRarity < 15) return "Gentleness";
        if (virtueRarity < 30) return "Bravery";
        if (virtueRarity < 45) return "Modesty";
        if (virtueRarity < 60) return "Temperance";
        if (virtueRarity < 70) return "Rightous Indignation";
        if (virtueRarity < 80) return "Justice";
        if (virtueRarity < 85) return "Sincerity";
        if (virtueRarity < 88) return "Friendliness";
        if (virtueRarity < 92) return "Dignity";
        if (virtueRarity < 94) return "Endurance";
        if (virtueRarity < 96) return "Greatness of Spirit";
        if (virtueRarity < 98) return "Magnificence";
        if (virtueRarity < 99) return "Wisdom";
        return "Extreme Tardiness";
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "src/libraries/Util.sol";

library Data {
    /*//////////////////////////////////////////////////////////////
                                 POINTS
    //////////////////////////////////////////////////////////////*/

    function bodyPoints(uint256 _i) external pure returns (string[2] memory) {
        uint256 pos = (_i % length) * 2;
        string memory x = Util.bytes1ToString(bodyPointsBytes[pos]);
        string memory y = Util.bytes1ToString(bodyPointsBytes[pos + 1]);
        return [x, y];
    }

    function motePoints(uint256 _i) external pure returns (string[2] memory) {
        uint256 pos = (_i % length) * 2;
        string memory x = Util.bytes1ToString(motesPointsBytes[pos]);
        string memory y = Util.bytes1ToString(motesPointsBytes[pos + 1]);
        return [x, y];
    }

    function glintPoints(uint256 _i) external pure returns (string[2][3] memory) {
        uint256 pos = (_i % length) * 6;
        string[2][3] memory result;
        uint256 i;
        for (; i < 3; ) {
            string memory x = Util.bytes1ToString(glintPointsBytes[pos + 2 * i]);
            string memory y = Util.bytes1ToString(glintPointsBytes[pos + 2 * i + 1]);
            result[i] = [x, y];
            ++i;
        }
        return result;
    }

    /*//////////////////////////////////////////////////////////////
                                  TIMES
    //////////////////////////////////////////////////////////////*/

    function shorterTimes(uint256 _i) external pure returns (string memory) {
        uint256 val = uint256(uint8(shorterTimesBytes[_i % length]));
        return string.concat(Util.uint256ToString(val / 10), ".", Util.uint256ToString(val % 10));
    }

    function shortTimes(uint256 _i) external pure returns (string memory) {
        uint256 val = uint256(uint8(shortTimesBytes[_i % length]));
        return string.concat(Util.uint256ToString(val / 10), ".", Util.uint256ToString(val % 10));
    }

    function longTimes(uint256 _i) external pure returns (string memory) {
        uint256 val = uint256(uint8(longTimesBytes[_i % length]));
        return string.concat(Util.uint256ToString(val / 10), ".", Util.uint256ToString(val % 10));
    }

    /*//////////////////////////////////////////////////////////////
                                 PALETTE
    //////////////////////////////////////////////////////////////*/

    function lightestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(lightestPaletteBytes, _i % length);
    }

    function lightPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(lightPaletteBytes, _i % length);
    }

    function darkestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(darkestPaletteBytes, _i % length);
    }

    function invertedLightestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(invertedLightestPaletteBytes, _i % length);
    }

    function invertedLightPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(invertedLightPaletteBytes, _i % length);
    }

    function invertedDarkestPalette(uint256 _i) external pure returns (string memory) {
        return _getRGBString(invertedDarkestPaletteBytes, _i % length);
    }

    function _getRGBString(bytes memory _palette, uint256 _pos) internal pure returns (string memory result) {
        return
            string.concat(
                "#",
                Util.bytes1ToHex(_palette[3 * _pos]),
                Util.bytes1ToHex(_palette[3 * _pos + 1]),
                Util.bytes1ToHex(_palette[3 * _pos + 2])
            );
    }

    /*//////////////////////////////////////////////////////////////
                                  DEFS
    //////////////////////////////////////////////////////////////*/

    function defs() external pure returns (string memory) {
        return
            string.concat(
                "<defs>",
                '<filter id="bibo-blur" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="15" result="out" />',
                "</filter>",
                '<filter id="bibo-blur-sm" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="5" result="out" />',
                "</filter>",
                '<filter id="bibo-blur-lg" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="32" result="out" />',
                "</filter>",
                '<path id="bibo-jitter-sm" d="M0.9512 0.9818C4.7033 2.4814 10 4.5234 10 0.9818c0 -3.5299 -5.0997 -1.5806 -9.0488 0zM0.9512 0.9818C0.9381 0.987 0.925 0.9923 0.9118 0.9975C-3.0426 2.5808 -8 4.5628 -8 1.0211s5.1991 -1.5389 8.9512 -0.0394z" />',
                '<path id="bibo-jitter-lg" d="M-0.0596 -0.0403C4.5263 3.4116 11 5.4815 11 -0.0404c0 -5.4948 -6.2329 -3.6384 -11.0596 0zM-0.0596 -0.0403c-0.016 0.0121 -0.0321 0.0242 -0.0481 0.0362C-4.941 3.6406 -11 5.5721 -11 0.0503c0 -5.5218 6.3545 -3.5425 10.9404 -0.0906z" />',
                "</defs>"
            );
    }

    function mpathJitterLg() internal pure returns (string memory) {
        return '<mpath xlink:href="#bibo-jitter-lg" />';
    }

    function mpathJitterSm() internal pure returns (string memory) {
        return '<mpath xlink:href="#bibo-jitter-sm"/>';
    }

    /*//////////////////////////////////////////////////////////////
                                  DATA
    //////////////////////////////////////////////////////////////*/

    uint256 constant length = 64;
    bytes constant bodyPointsBytes =
        hex"75727a8f887c748087736b88906c8a8b7ba397906b7f7a79729488a1829766966faa92846da1a578947983849e6c79af8db891a686b48dafae95a09e9099ad8aa7a49e88a28073887a98b670b77abd84b58eae7ca391b484ad6f7e7278b78bc39ac69ebaa5b483ab85bc9da895ad95bec68eaeabb89aadbebbb1a6c19db1b2b6";
    bytes constant motesPointsBytes =
        hex"f183ee6ce186db75f29ae15fdf97d28dc364c680e8add850efc3d4abc69cb54daa67b971aa84b397c753d5c4c5c1b8b2a055957ca19ee4d2cedcbed3b0c0a2b2a3448f469163878e8ea69a90b5e9a1d897c989b97c44786282547e7172967b8287e683d379b46c5069706287579aa3eb71ee73d461b75b5a5a6b507e6ca548a0";
    bytes constant glintPointsBytes =
        hex"ad5e6bc1ce7f6bc196d2c1c1adce5e7f96d25e7fc16b6b6b965ac1c16bc16bc15ead5a96ce7fcead96d2965a5e7fce7fc16b5a9696d2ad5e6b6bc1c17f5e5ead7fcece7f5eadd296d296c1c17f5e6b6b5ead7f5eadcecead5a965a9696d26b6b965aadce5a96ceadadce6b6b965a5a967f5e5e7f7f5ecead7f5ec1c1ce7f7f5e7fce96d25e7f7f5e96d2d2965a96965aad5e6bc1ce7f6bc196d2c1c1adce5e7f96d25e7fc16b6b6b965ac1c16bc16bc15ead5a96ce7fcead96d2965a5e7fce7fc16b5a9696d2ad5e6b6bc1c17f5e5ead7fcece7f5eadd296d296c1c17f5e6b6b5ead7f5eadcecead5a965a9696d26b6b965aadce5a96ceadadce6b6b965a5a967f5e5e7f7f5ecead7f5ec1c1ce7f7f5e7fce96d25e7f7f5e96d2d2965a96965aad5e6bc1ce7f6bc196d2c1c1adce5e7f96d25e7fc16b6b6b965ac1c16bc16bc15ead5a96ce7fcead96d2965a5e7fce7fc16b5a9696d2ad5e6b6bc1c17f5e5ead7fcece7f5eadd296d296c1c17f5e6b6b5ead7f5eadcecead5a965a9696d26b6b";
    bytes public constant shorterTimesBytes =
        hex"13121013120f13110f12130f1212100f13130f0f1111100f100f1308070509070505060708090808090507070709080908050008090700090008000600080900";
    bytes public constant shortTimesBytes =
        hex"59614460553a60493b505f3753543e3a6163343849473e333c325e53483b624d34343e48505c595562364d4f4e5d515d53384457604c5a5b4454534148586063";
    bytes public constant longTimesBytes =
        hex"70927d8856956369837b55785486625886664f4f4d78875460754c7c785c7f4e709074877c6c788e5f63636478597586777a85746c82799271746d698c4f9288";
    bytes public constant lightPaletteBytes =
        hex"ff3333ff4633ff5933ff6c33ff7e33ff9133ffa433ffb733ffca33ffdd33fff033fcff33e9ff33d6ff33c3ff33b0ff339dff338aff3378ff3365ff3352ff333fff3333ff3a33ff4d33ff6033ff7233ff8533ff9833ffab33ffbe33ffd133ffe433fff733f5ff33e2ff33cfff33bcff33a9ff3396ff3383ff3371ff335eff334bff3338ff4133ff5433ff6733ff7933ff8c33ff9f33ffb233ffc533ffd833ffeb33fffd33ffff33eeff33dbff33c8ff33b5ff33a2ff338fff337dff336aff3357";
    bytes public constant lightestPaletteBytes =
        hex"ffb3b3ffbab3ffc1b3ffc8b3ffcfb3ffd6b3ffddb3ffe4b3ffebb3fff2b3fff9b3feffb3f7ffb3f0ffb3e8ffb3e1ffb3daffb3d3ffb3ccffb3c5ffb3beffb3b7ffb3b3ffb5b3ffbcb3ffc3b3ffcab3ffd1b3ffd8b3ffe0b3ffe7b3ffeeb3fff5b3fffcb3fbffb3f4ffb3edffb3e6ffb3dfffb3d8ffb3d1ffb3caffb3c3ffb3bbffb3b4ffb8b3ffbfb3ffc6b3ffcdb3ffd4b3ffdbb3ffe2b3ffe9b3fff0b3fff7b3fffeb3ffffb3f9ffb3f1ffb3eaffb3e3ffb3dcffb3d5ffb3ceffb3c7ffb3c0";
    bytes public constant darkestPaletteBytes =
        hex"060a06060d07061007061407061907051e07042306022805060a08060d0a06100c06140e061910051e1304231502281706090a060d0d061010061414061819051d1e04212302272806080a06090d060b10060d14060f1905111e04122302142806060a06060d06061006061406061905051e04042302022808060a09060d0b06100d06140f061911051e12042314022809060a0d060d1006101406141806191d051e2104232702280a06080d060a10060c14060e1906101e0513230415280217";
    bytes public constant invertedLightPaletteBytes =
        hex"50f0f04ddcf04bc8f04ab5f049a2f0498ef04a7af04b66f04c52f04e41f14f33f1502bf1552cf15d2df16a2ff17831f18933f19b36f0ac39f0bf3cf0d23ff0e642f0f244e9f243d5f242c1f241aff3419bf34087f43f72f43f5ef53e4af53e38f53e28f64123f54924f55625f56528f4772af48a2df39d30f3af33f2c336f2d73af2ea3de4ef3dd0f03dbdf03cabf03c98f03c87f03b76f03b67f03b5cf03b53f13b4ff13b4ef1414ef14b4df15a4cf16b4cf07e4bf0914bf0a34cf0b74df0ca";
    bytes public constant invertedLightestPaletteBytes =
        hex"3e45453c3e3e3838383133342a2e322328321d2233191c34161635141136120b371206371406381707381b09381f0a39230c39280e3a2d103b32123b37143c3c163e3f183d3e18373c18323b182d3a192939192539182139181d3917193a17173b16143b18143b1b153b1f173c23193d281b3f2c1e413220443722473d234a43254d4a264a4a26454a254149243c492238492134492030491f2c491e29481e27481d25481d25482026482427482929482d2b47322d473730463b34463f384542";
    bytes public constant invertedDarkestPaletteBytes =
        hex"f9f5f9f9f2f8f9eff8f9ebf8f9e6f8fae1f8fbdcf9fdd7faf9f5f7f9f2f5f9eff3f9ebf1f9e6effae1ecfbdceafdd7e8f9f6f5f9f2f2f9efeff9ebebf9e7e6fae2e1fbdedcfdd8d7f9f7f5f9f6f2f9f4eff9f2ebf9f0e6faeee1fbeddcfdebd7f9f9f5f9f9f2f9f9eff9f9ebf9f9e6fafae1fbfbdcfdfdd7f7f9f5f6f9f2f4f9eff2f9ebf0f9e6eefae1edfbdcebfdd7f6f9f5f2f9f2eff9efebf9ebe7f9e6e2fae1defbdcd8fdd7f5f9f7f2f9f5eff9f3ebf9f1e6f9efe1faecdcfbead7fde8";
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import {Traits} from "libraries/Traits.sol";
import {Data} from "libraries/Data.sol";

enum DensityType {
    HIGH,
    LOW
}

enum PolarityType {
    POSITIVE,
    NEGATIVE
}

library Palette {
    uint256 constant length = 64;
    uint256 constant opacityLength = 5;

    /*//////////////////////////////////////////////////////////////
                                  FILL
    //////////////////////////////////////////////////////////////*/

    function bodyFill(
        bytes32 _seed,
        uint256 _i,
        uint256 _tokenId
    ) internal pure returns (string memory) {
        uint256 bodyFillValue = uint256(keccak256(abi.encodePacked(_seed, "bodyFill", _i)));

        if (Traits.densityType(_seed, _tokenId) == DensityType.HIGH) {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _light(bodyFillValue);
            else return _invertedLight(bodyFillValue);
        } else {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _lightest(bodyFillValue);
            else return _invertedLightest(bodyFillValue);
        }
    }

    function backgroundFill(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        uint256 backgroundFillValue = uint256(keccak256(abi.encodePacked(_seed, "backgroundFill")));

        if (Traits.densityType(_seed, _tokenId) == DensityType.HIGH) {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _darkest(backgroundFillValue);
            else return _invertedDarkest(backgroundFillValue);
        } else {
            if (Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE) return _darkest(backgroundFillValue);
            else return _invertedDarkest(backgroundFillValue);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 OPACITY
    //////////////////////////////////////////////////////////////*/

    function opacity(
        uint256 _glintSeed,
        bytes32 _seed,
        uint256 _tokenId
    ) internal pure returns (string memory) {
        return
            (
                Traits.densityType(_seed, _tokenId) == DensityType.HIGH
                    ? ["0.3", "0.4", "0.5", "0.6", "0.7"]
                    : ["0.6", "0.7", "0.8", "0.9", "1.0"]
            )[_glintSeed % opacityLength];
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _lightest(uint256 _i) internal pure returns (string memory) {
        return Data.lightestPalette(_i % length);
    }

    function _light(uint256 _i) internal pure returns (string memory) {
        return Data.lightPalette(_i % length);
    }

    function _darkest(uint256 _i) internal pure returns (string memory) {
        return Data.darkestPalette(_i % length);
    }

    function _invertedLightest(uint256 _value) internal pure returns (string memory) {
        return Data.invertedLightestPalette(_value);
    }

    function _invertedLight(uint256 _value) internal pure returns (string memory) {
        return Data.invertedLightPalette(_value);
    }

    function _invertedDarkest(uint256 _value) internal pure returns (string memory) {
        return Data.invertedDarkestPalette(_value);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette} from "./Palette.sol";
import {SVG} from "./SVG.sol";

library Background {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        return
            SVG.element(
                "rect",
                SVG.rectAttributes({
                    _width: "100%",
                    _height: "100%",
                    _fill: Palette.backgroundFill(_seed, _tokenId),
                    _attributes: ""
                })
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette, DensityType, PolarityType} from "./Palette.sol";
import {Traits} from "./Traits.sol";
import {Data} from "./Data.sol";
import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Body {
    uint256 constant circlesCount = 7;

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed, uint256 _tokenId) internal pure returns (string memory) {
        string[7] memory radii = ["64", "64", "64", "56", "48", "32", "24"];

        string memory backgroundFill = Palette.backgroundFill(_seed, _tokenId);
        string memory mixBlendMode = Traits.polarityType(_seed, _tokenId) == PolarityType.POSITIVE
            ? "lighten"
            : "multiply";

        string memory bodyGroupChildren = _bodyBackground(backgroundFill);

        for (uint8 index = 0; index < circlesCount; ++index) {
            bodyGroupChildren = string.concat(
                bodyGroupChildren,
                _bodyCircle(_seed, index, _tokenId, radii[index], mixBlendMode)
            );
        }
        return
            SVG.element(
                "g",
                string.concat(SVG.filterAttribute("bibo-blur"), 'shape-rendering="optimizeSpeed"'),
                bodyGroupChildren
            );
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _bodyCircle(
        bytes32 _seed,
        uint256 _index,
        uint256 _tokenId,
        string memory _radius,
        string memory _mixMode
    ) internal pure returns (string memory) {
        uint256 bodySeed = uint256(keccak256(abi.encodePacked(_seed, "body", _index)));
        string memory bodyFill1 = Palette.bodyFill(_seed, _index, _tokenId);
        string memory bodyFill2 = Palette.bodyFill(_seed, _index + circlesCount, _tokenId);
        string memory dur = Data.shortTimes(bodySeed /= Data.length);
        string[2] memory coords = (_index == 0) ? ["150", "150"] : Data.bodyPoints(bodySeed /= 2);
        bool reverse = bodySeed % 2 == 0;

        return
            SVG.element(
                "circle",
                SVG.circleAttributes({
                    _radius: _radius,
                    _coords: coords,
                    _fill: bodyFill1,
                    _opacity: "1",
                    _mixMode: _mixMode,
                    _attributes: ""
                }),
                SVG.element("animateMotion", SVG.animateMotionAttributes(reverse, dur, "linear"), Data.mpathJitterLg()),
                (_tokenId == 0) ? _genesis(bodyFill1, bodyFill2, dur) : ""
            );
    }

    function _genesis(
        string memory _bodyFill1,
        string memory _bodyFill2,
        string memory _dur
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<animate attributeName="fill" repeatCount="indefinite" values="',
                _bodyFill1,
                ";",
                _bodyFill2,
                ";",
                _bodyFill1,
                '" dur="',
                _dur,
                '"/>'
            );
    }

    function _bodyBackground(string memory _fill) internal pure returns (string memory) {
        return
            SVG.element("rect", SVG.rectAttributes({_width: "100%", _height: "100%", _fill: _fill, _attributes: ""}));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {SVG} from "./SVG.sol";
import {Eyes} from "./Eyes.sol";
import {Mouth} from "./Mouth.sol";
import {Cheeks} from "./Cheeks.sol";
import {Data} from "./Data.sol";

library Face {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) internal pure returns (string memory) {
        uint256 faceSeed = uint256(keccak256(abi.encodePacked(_seed, "face")));
        bool reverse = (faceSeed /= 2) % 2 == 0;
        string memory rotation = ["1", "2", "4", "6", "-1", "-2", "-4", "-6"][faceSeed % 8];

        string memory circleAttributes = SVG.circleAttributes({
            _radius: "80",
            _coords: ["100", "100"],
            _fill: "white",
            _opacity: "0.2",
            _mixMode: "lighten",
            _attributes: SVG.filterAttribute("bibo-blur-lg")
        });

        string memory faceGroupAttributes = string.concat(
            "transform=",
            "'",
            "translate(100,100) scale(0.5) ",
            "rotate(",
            rotation,
            ")",
            "'"
        );

        return
            SVG.element(
                "g",
                faceGroupAttributes,
                SVG.element(
                    "rect",
                    SVG.rectAttributes({_width: "200", _height: "200", _fill: "#00000000", _attributes: ""})
                ),
                SVG.element("circle", circleAttributes),
                Eyes.render(_seed),
                Mouth.render(_seed),
                Cheeks.render(_seed),
                SVG.element(
                    "animateMotion",
                    SVG.animateMotionAttributes(reverse, "11s", "linear"),
                    Data.mpathJitterLg()
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette} from "./Palette.sol";
import {Data} from "./Data.sol";
import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";
import {Traits} from "./Traits.sol";

enum MoteType {
    NONE,
    FLOATING,
    RISING,
    FALLING,
    GLISTENING
}

library Motes {
    uint256 constant GLINT_COUNT = 20;

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed, uint256 _tokenId) external pure returns (string memory) {
        string memory motesChildren;

        MoteType moteType = Traits.moteType(_seed);
        if (moteType == MoteType.NONE) return "";

        for (uint8 i = 0; i < GLINT_COUNT; i++) {
            uint256 moteSeed = uint256(keccak256(abi.encodePacked(_seed, "mote", i)));

            string memory dur = Data.longTimes(moteSeed /= Data.length);
            string memory delay = Data.shorterTimes(moteSeed /= Data.length);
            string[2] memory coords = Data.motePoints(moteSeed /= Data.length);
            string memory radius = (moteSeed /= 2) % 2 == 0 ? "1" : "2";
            string memory opacity = Palette.opacity(moteSeed /= Palette.opacityLength, _seed, _tokenId);
            bool reverse = moteSeed % 2 == 0;

            if (moteType == MoteType.FLOATING)
                motesChildren = string.concat(motesChildren, _floatingMote(radius, coords, opacity, dur, reverse));
            else if (moteType == MoteType.RISING)
                motesChildren = string.concat(motesChildren, _risingMote(radius, coords, opacity, dur));
            else if (moteType == MoteType.FALLING)
                motesChildren = string.concat(motesChildren, _fallingMote(radius, coords, opacity, dur));
            else if (moteType == MoteType.GLISTENING)
                motesChildren = string.concat(
                    motesChildren,
                    _glisteningMote(radius, coords, opacity, dur, reverse, delay)
                );
        }

        return SVG.element({_type: "g", _attributes: "", _children: motesChildren});
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _risingMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur
    ) internal pure returns (string memory) {
        return
            SVG.element({
                _type: "g",
                _attributes: 'transform="translate(0,25)"',
                _children: SVG.element(
                    "circle",
                    SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                    _animateTransform(_dur, "-100"),
                    _animate(_dur)
                )
            });
    }

    function _floatingMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur,
        bool _reverse
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "circle",
                SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                SVG.element(
                    "animateMotion",
                    SVG.animateMotionAttributes(_reverse, _dur, "linear"),
                    Data.mpathJitterSm()
                )
            );
    }

    function _fallingMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "g",
                'transform="translate(0,-25)">',
                SVG.element(
                    "circle",
                    SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                    _animateTransform(_dur, "100"),
                    _animate(_dur)
                )
            );
    }

    function _glisteningMote(
        string memory _radius,
        string[2] memory _coords,
        string memory _opacity,
        string memory _dur,
        bool _reverse,
        string memory _delay
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "g",
                'opacity="0"',
                SVG.element(
                    "animate",
                    string.concat(
                        'calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.4 0 0.4 1; 0.4 0 0.4 1" attributeName="opacity" values="0;1;0" dur="1.5s" repeatCount="indefinite" begin="',
                        _delay,
                        '"/>'
                    )
                ),
                SVG.element(
                    "circle",
                    SVG.circleAttributes(_radius, _coords, "white", _opacity, "lighten", ""),
                    SVG.element(
                        "animateMotion",
                        SVG.animateMotionAttributes(_reverse, _dur, "paced"),
                        Data.mpathJitterSm()
                    )
                )
            );
    }

    function _animateTransform(string memory _dur, string memory _to) internal pure returns (string memory) {
        string memory attributes = string.concat(
            'attributeName="transform" ',
            "dur=",
            Util.quote(_dur),
            'repeatCount="indefinite" ',
            'type="translate" ',
            'additive="sum" ',
            'from="0 0" ',
            'to="0 ',
            _to,
            '"'
        );

        return SVG.element("animateTransform", attributes);
    }

    function _animate(string memory _dur) internal pure returns (string memory) {
        return
            SVG.element(
                "animate",
                string.concat(
                    'attributeName="opacity" ',
                    'values="0;1;0" ',
                    "dur=",
                    Util.quote(_dur),
                    'repeatCount="indefinite" '
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Traits} from "libraries/Traits.sol";
import {Palette} from "./Palette.sol";
import {Data} from "./Data.sol";
import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Glints {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        string memory glintsGroupChildren;
        uint256 glintCount = Traits.glintCount(_seed);

        uint256 glintSeed = uint256(keccak256(abi.encodePacked(_seed, "glint")));
        bool reverseRotate = glintSeed % 2 == 0;
        glintSeed /= 2;
        bool reverse = glintSeed % 2 == 0;
        glintSeed /= 2;
        string[2][3] memory coords = Data.glintPoints(glintSeed);
        glintSeed /= Data.length;

        for (uint8 index = 0; index < glintCount; index++) {
            glintsGroupChildren = string.concat(
                glintsGroupChildren,
                _glint(
                    Data.shortTimes(glintSeed),
                    Data.shorterTimes(glintSeed),
                    Data.longTimes(glintSeed),
                    coords[index],
                    reverseRotate,
                    reverse
                )
            );
        }

        return SVG.element("g", "id='glints'", glintsGroupChildren);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _glint(
        string memory _durationShort,
        string memory _durationShorter,
        string memory _durationLong,
        string[2] memory _coords,
        bool _reverseRotate,
        bool _reverse
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "g",
                _transformAttribute(_coords),
                SVG.element(
                    "g",
                    "",
                    SVG.element(
                        "circle",
                        SVG.circleAttributes({
                            _radius: "10",
                            _coords: ["0", "0"],
                            _fill: "white",
                            _opacity: "1.0",
                            _mixMode: "lighten",
                            _attributes: SVG.filterAttribute("bibo-blur-sm")
                        })
                    ),
                    SVG.element(
                        "path",
                        'fill-opacity="0.85" fill="white" style="mix-blend-mode:normal" fill-rule="evenodd" clip-rule="evenodd" d="M2.60676 11.4891C2.49095 12.4964 1.95054 13 0.985526 13C0.580218 13 0.223162 12.8644 -0.0856447 12.5932C-0.39445 12.322 -0.577804 11.9831 -0.635705 11.5763C-0.86731 9.71671 -1.10856 8.28329 -1.35947 7.27603C-1.59107 6.2494 -1.97708 5.47458 -2.51749 4.95157C-3.0386 4.42857 -3.85887 4.02179 -4.97829 3.73123C-6.07841 3.42131 -7.62244 3.05327 -9.61037 2.62712C-10.5368 2.43341 -11 1.89104 -11 0.999999C-11 0.593219 -10.8649 0.234868 -10.5947 -0.0750589C-10.3245 -0.384987 -9.98673 -0.569006 -9.58142 -0.627117C-7.61279 -0.878934 -6.07841 -1.13075 -4.97829 -1.38257C-3.87817 -1.63438 -3.0579 -2.03147 -2.51749 -2.57385C-1.97708 -3.11622 -1.59107 -3.92978 -1.35947 -5.01453C-1.10856 -6.09927 -0.86731 -7.60048 -0.635705 -9.51816C-0.500603 -10.5061 0.0398083 -11 0.985526 -11C1.95054 -11 2.49095 -10.4964 2.60676 -9.4891C2.83836 -7.64891 3.06997 -6.2155 3.30157 -5.18886C3.53317 -4.1816 3.91918 -3.42615 4.45959 -2.92252C5 -2.41889 5.82992 -2.0121 6.94934 -1.70218C8.06876 -1.41162 9.61279 -1.05327 11.5814 -0.627117C12.5271 -0.414042 13 0.128328 13 0.999999C13 1.92978 12.4692 2.47215 11.4077 2.62712C9.47768 2.91767 7.97226 3.19855 6.89144 3.46973C5.81062 3.74092 5 4.1477 4.45959 4.69007C3.91918 5.23244 3.53317 6.03632 3.30157 7.10169C3.06997 8.16707 2.83836 9.62954 2.60676 11.4891Z"',
                        string.concat(
                            '<animateTransform dur="1.5s" repeatCount="indefinite" calcMode="spline" keyTimes="0; 0.5; 1" keySplines="0.4 0 0.4 1; 0.4 0 0.4 1" values="1; 1.25; 1" attributeName="transform" attributeType="XML" type="scale" additive="sum" begin="',
                            _durationShorter,
                            '"/>'
                        )
                    ),
                    _animateTransform(_durationShort, _reverseRotate)
                ),
                SVG.element(
                    "animateMotion",
                    SVG.animateMotionAttributes(_reverse, _durationLong, "linear"),
                    Data.mpathJitterLg()
                )
            );
    }

    function _transformAttribute(string[2] memory _coords) internal pure returns (string memory) {
        return string.concat('transform="translate(', _coords[0], ",", _coords[1], ') scale(1)"');
    }

    function _animateTransform(string memory _dur, bool _reverseRotate) internal pure returns (string memory) {
        string memory reverseRotate = _reverseRotate ? "from='0 0 0' to='360 0 0'" : "from='360 0 0' to='0 0 0'";

        return
            SVG.element(
                "animateTransform",
                string.concat(
                    'attributeName="transform" ',
                    "dur=",
                    Util.quote(_dur),
                    'repeatCount="indefinite" ',
                    'type="rotate" ',
                    reverseRotate
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";

library SVG {
    /*//////////////////////////////////////////////////////////////
                                 ELEMENT
    //////////////////////////////////////////////////////////////*/

    function element(string memory _type, string memory _attributes) internal pure returns (string memory) {
        return string.concat("<", _type, " ", _attributes, "/>");
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _children
    ) internal pure returns (string memory) {
        return string.concat("<", _type, " ", _attributes, ">", _children, "</", _type, ">");
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4, _child5));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4, _child5, _child6));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6,
        string memory _child7
    ) internal pure returns (string memory) {
        return
            element(_type, _attributes, string.concat(_child1, _child2, _child3, _child4, _child5, _child6, _child7));
    }

    /*//////////////////////////////////////////////////////////////
                               ATTRIBUTES
    //////////////////////////////////////////////////////////////*/

    function svgAttributes() internal pure returns (string memory) {
        return
            string.concat(
                'xmlns="http://www.w3.org/2000/svg" '
                'xmlns:xlink="http://www.w3.org/1999/xlink" '
                'width="100%" '
                'height="100%" '
                'viewBox="0 0 300 300" ',
                'preserveAspectRatio="xMidYMid meet" ',
                'fill="none" '
            );
    }

    function circleAttributes(
        string memory _radius,
        string[2] memory _coords,
        string memory _fill,
        string memory _opacity,
        string memory _mixMode,
        string memory _attributes
    ) internal pure returns (string memory) {
        return
            string.concat(
                "r=",
                Util.quote(_radius),
                "cx=",
                Util.quote(_coords[0]),
                "cy=",
                Util.quote(_coords[1]),
                "fill=",
                Util.quote(_fill),
                "opacity=",
                Util.quote(_opacity),
                "style=",
                Util.quote(string.concat("mix-blend-mode:", _mixMode)),
                " ",
                _attributes,
                " "
            );
    }

    function rectAttributes(
        string memory _width,
        string memory _height,
        string memory _fill,
        string memory _attributes
    ) internal pure returns (string memory) {
        return
            string.concat(
                "width=",
                Util.quote(_width),
                "height=",
                Util.quote(_height),
                "fill=",
                Util.quote(_fill),
                " ",
                _attributes,
                " "
            );
    }

    function animateMotionAttributes(
        bool _reverse,
        string memory _dur,
        string memory _calcMode
    ) internal pure returns (string memory) {
        string memory reverse = _reverse ? "keyPoints='1;0' keyTimes='0;1'" : "keyPoints='0;1' keyTimes='0;1'";

        return
            string.concat(
                reverse,
                " ",
                "dur=",
                Util.quote(_dur),
                'repeatCount="indefinite" ',
                "calcMode=",
                Util.quote(_calcMode)
            );
    }

    function filterAttribute(string memory _id) internal pure returns (string memory) {
        return string.concat("filter=", '"', "url(#", _id, ")", '" ');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(string memory _data) internal pure returns (string memory) {
        return encode(bytes(_data));
    }

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

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
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
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
pragma solidity >=0.6.0 <0.9.0;

import "./Script.sol";
import "ds-test/test.sol";

// Wrappers around Cheatcodes to avoid footguns
abstract contract Test is DSTest, Script {
    using stdStorage for StdStorage;

    uint256 internal constant UINT256_MAX =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    StdStorage internal stdstore;

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-LOGS
    //////////////////////////////////////////////////////////////////////////*/

    event log_array(uint256[] val);
    event log_array(int256[] val);
    event log_array(address[] val);
    event log_named_array(string key, uint256[] val);
    event log_named_array(string key, int256[] val);
    event log_named_array(string key, address[] val);

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-CHEATS
    //////////////////////////////////////////////////////////////////////////*/

    // Skip forward or rewind time by the specified number of seconds
    function skip(uint256 time) internal {
        vm.warp(block.timestamp + time);
    }

    function rewind(uint256 time) internal {
        vm.warp(block.timestamp - time);
    }

    // Setup a prank from an address that has some ether
    function hoax(address who) internal {
        vm.deal(who, 1 << 128);
        vm.prank(who);
    }

    function hoax(address who, uint256 give) internal {
        vm.deal(who, give);
        vm.prank(who);
    }

    function hoax(address who, address origin) internal {
        vm.deal(who, 1 << 128);
        vm.prank(who, origin);
    }

    function hoax(address who, address origin, uint256 give) internal {
        vm.deal(who, give);
        vm.prank(who, origin);
    }

    // Start perpetual prank from an address that has some ether
    function startHoax(address who) internal {
        vm.deal(who, 1 << 128);
        vm.startPrank(who);
    }

    function startHoax(address who, uint256 give) internal {
        vm.deal(who, give);
        vm.startPrank(who);
    }

    // Start perpetual prank from an address that has some ether
    // tx.origin is set to the origin parameter
    function startHoax(address who, address origin) internal {
        vm.deal(who, 1 << 128);
        vm.startPrank(who, origin);
    }

    function startHoax(address who, address origin, uint256 give) internal {
        vm.deal(who, give);
        vm.startPrank(who, origin);
    }

    function changePrank(address who) internal {
        vm.stopPrank();
        vm.startPrank(who);
    }

    // DEPRECATED: Use `deal` instead
    function tip(address token, address to, uint256 give) internal {
        emit log_named_string("WARNING", "Test tip(address,address,uint256): The `tip` stdcheat has been deprecated. Use `deal` instead.");
        stdstore
            .target(token)
            .sig(0x70a08231)
            .with_key(to)
            .checked_write(give);
    }

    // The same as Vm's `deal`
    // Use the alternative signature for ERC20 tokens
    function deal(address to, uint256 give) internal {
        vm.deal(to, give);
    }

    // Set the balance of an account for any ERC20 token
    // Use the alternative signature to update `totalSupply`
    function deal(address token, address to, uint256 give) internal {
        deal(token, to, give, false);
    }

    function deal(address token, address to, uint256 give, bool adjust) internal {
        // get current balance
        (, bytes memory balData) = token.call(abi.encodeWithSelector(0x70a08231, to));
        uint256 prevBal = abi.decode(balData, (uint256));

        // update balance
        stdstore
            .target(token)
            .sig(0x70a08231)
            .with_key(to)
            .checked_write(give);

        // update total supply
        if(adjust){
            (, bytes memory totSupData) = token.call(abi.encodeWithSelector(0x18160ddd));
            uint256 totSup = abi.decode(totSupData, (uint256));
            if(give < prevBal) {
                totSup -= (prevBal - give);
            } else {
                totSup += (give - prevBal);
            }
            stdstore
                .target(token)
                .sig(0x18160ddd)
                .checked_write(totSup);
        }
    }

    function bound(uint256 x, uint256 min, uint256 max) internal virtual returns (uint256 result) {
        require(min <= max, "Test bound(uint256,uint256,uint256): Max is less than min.");

        uint256 size = max - min;

        if (size == 0)
        {
            result = min;
        }
        else if (size == UINT256_MAX)
        {
            result = x;
        }
        else
        {
            ++size; // make `max` inclusive
            uint256 mod = x % size;
            result = min + mod;
        }

        emit log_named_uint("Bound Result", result);
    }

    // Deploy a contract by fetching the contract bytecode from
    // the artifacts directory
    // e.g. `deployCode(code, abi.encode(arg1,arg2,arg3))`
    function deployCode(string memory what, bytes memory args)
        internal
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string,bytes): Deployment failed."
        );
    }

    function deployCode(string memory what)
        internal
        returns (address addr)
    {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string): Deployment failed."
        );
    }

    /// deploy contract with value on construction
    function deployCode(string memory what, bytes memory args, uint256 val)
        internal
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(vm.getCode(what), args);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string,bytes,uint256): Deployment failed."
        );
    }

    function deployCode(string memory what, uint256 val)
        internal
        returns (address addr)
    {
        bytes memory bytecode = vm.getCode(what);
        /// @solidity memory-safe-assembly
        assembly {
            addr := create(val, add(bytecode, 0x20), mload(bytecode))
        }

        require(
            addr != address(0),
            "Test deployCode(string,uint256): Deployment failed."
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    STD-ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function fail(string memory err) internal virtual {
        emit log_named_string("Error", err);
        fail();
    }

    function assertFalse(bool data) internal virtual {
        assertTrue(!data);
    }

    function assertFalse(bool data, string memory err) internal virtual {
        assertTrue(!data, err);
    }

    function assertEq(bool a, bool b) internal {
        if (a != b) {
            emit log                ("Error: a == b not satisfied [bool]");
            emit log_named_string   ("  Expected", b ? "true" : "false");
            emit log_named_string   ("    Actual", a ? "true" : "false");
            fail();
        }
    }

    function assertEq(bool a, bool b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes memory a, bytes memory b) internal {
        assertEq0(a, b);
    }

    function assertEq(bytes memory a, bytes memory b, string memory err) internal {
        assertEq0(a, b, err);
    }

    function assertEq(uint256[] memory a, uint256[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [uint[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(int256[] memory a, int256[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [int[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(address[] memory a, address[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log("Error: a == b not satisfied [address[]]");
            emit log_named_array("  Expected", b);
            emit log_named_array("    Actual", a);
            fail();
        }
    }

    function assertEq(uint256[] memory a, uint256[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(int256[] memory a, int256[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }


    function assertEq(address[] memory a, address[] memory b, string memory err) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function assertApproxEqAbs(
        uint256 a,
        uint256 b,
        uint256 maxDelta
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log            ("Error: a ~= b not satisfied [uint]");
            emit log_named_uint ("  Expected", b);
            emit log_named_uint ("    Actual", a);
            emit log_named_uint (" Max Delta", maxDelta);
            emit log_named_uint ("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(
        uint256 a,
        uint256 b,
        uint256 maxDelta,
        string memory err
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string   ("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqAbs(
        int256 a,
        int256 b,
        uint256 maxDelta
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log            ("Error: a ~= b not satisfied [int]");
            emit log_named_int  ("  Expected", b);
            emit log_named_int  ("    Actual", a);
            emit log_named_uint (" Max Delta", maxDelta);
            emit log_named_uint ("     Delta", delta);
            fail();
        }
    }

    function assertApproxEqAbs(
        int256 a,
        int256 b,
        uint256 maxDelta,
        string memory err
    ) internal virtual {
        uint256 delta = stdMath.delta(a, b);

        if (delta > maxDelta) {
            emit log_named_string   ("Error", err);
            assertApproxEqAbs(a, b, maxDelta);
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta // An 18 decimal fixed point number, where 1e18 == 100%
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log                    ("Error: a ~= b not satisfied [uint]");
            emit log_named_uint         ("    Expected", b);
            emit log_named_uint         ("      Actual", a);
            emit log_named_decimal_uint (" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint ("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(
        uint256 a,
        uint256 b,
        uint256 maxPercentDelta, // An 18 decimal fixed point number, where 1e18 == 100%
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string       ("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }

    function assertApproxEqRel(
        int256 a,
        int256 b,
        uint256 maxPercentDelta
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log                   ("Error: a ~= b not satisfied [int]");
            emit log_named_int         ("    Expected", b);
            emit log_named_int         ("      Actual", a);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta, 18);
            fail();
        }
    }

    function assertApproxEqRel(
        int256 a,
        int256 b,
        uint256 maxPercentDelta,
        string memory err
    ) internal virtual {
        if (b == 0) return assertEq(a, b); // If the expected is 0, actual must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log_named_string      ("Error", err);
            assertApproxEqRel(a, b, maxPercentDelta);
        }
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                STD-ERRORS
//////////////////////////////////////////////////////////////////////////*/

library stdError {
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
    // DEPRECATED: Use Vm's `expectRevert` without any arguments instead
    bytes public constant lowLevelError = bytes(""); // `0x`
}

/*//////////////////////////////////////////////////////////////////////////
                                STD-STORAGE
//////////////////////////////////////////////////////////////////////////*/

struct StdStorage {
    mapping (address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping (address => mapping(bytes4 =>  mapping(bytes32 => bool))) finds;

    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}

library stdStorage {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint slot);
    event WARNING_UninitedSlot(address who, uint slot);

    uint256 private constant UINT256_MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    int256 private constant INT256_MAX = 57896044618658097711785492504343953926634992332820282019728792003956564819967;

    Vm private constant vm_std_store = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

    function sigs(
        string memory sigStr
    )
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(
        StdStorage storage self
    )
        internal
        returns (uint256)
    {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        vm_std_store.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }

        (bytes32[] memory reads, ) = vm_std_store.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = vm_std_store.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(false, "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported.");
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = vm_std_store.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                // store
                vm_std_store.store(who, reads[i], bytes32(hex"1337"));
                bool success;
                bytes memory rdat;
                {
                    (success, rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32*field_depth);
                }

                if (success && fdat == bytes32(hex"1337")) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    vm_std_store.store(who, reads[i], prev);
                    break;
                }
                vm_std_store.store(who, reads[i], prev);
            }
        } else {
            require(false, "stdStorage find(StdStorage): No storage use detected for target.");
        }

        require(self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))], "stdStorage find(StdStorage): Slot(s) not found.");

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }
    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        /// @solidity memory-safe-assembly
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(
        StdStorage storage self,
        bytes32 set
    ) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }
        bytes32 curr = vm_std_store.load(who, slot);

        if (fdat != curr) {
            require(false, "stdStorage find(StdStorage): Packed slot. This would cause dangerous overwriting and currently isn't supported.");
        }
        vm_std_store.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth;
    }

    function read(StdStorage storage self) private returns (bytes memory) {
        address t = self._target;
        uint256 s = find(self);
        return abi.encode(vm_std_store.load(t, bytes32(s)));
    }

    function read_bytes32(StdStorage storage self) internal returns (bytes32) {
        return abi.decode(read(self), (bytes32));
    }


    function read_bool(StdStorage storage self) internal returns (bool) {
        int256 v = read_int(self);
        if (v == 0) return false;
        if (v == 1) return true;
        revert("stdStorage read_bool(StdStorage): Cannot decode. Make sure you are reading a bool.");
    }

    function read_address(StdStorage storage self) internal returns (address) {
        return abi.decode(read(self), (address));
    }

    function read_uint(StdStorage storage self) internal returns (uint256) {
        return abi.decode(read(self), (uint256));
    }

    function read_int(StdStorage storage self) internal returns (int256) {
        return abi.decode(read(self), (int256));
    }

    function bytesToBytes32(bytes memory b, uint offset) public pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory)
    {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            /// @solidity memory-safe-assembly
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                STD-MATH
//////////////////////////////////////////////////////////////////////////*/

library stdMath {
    int256 private constant INT256_MIN = -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function abs(int256 a) internal pure returns (uint256) {
        // Required or it will fail when `a = type(int256).min`
        if (a == INT256_MIN)
            return 57896044618658097711785492504343953926634992332820282019728792003956564819968;

        return uint256(a > 0 ? a : -a);
    }

    function delta(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b
            ? a - b
            : b - a;
    }

    function delta(int256 a, int256 b) internal pure returns (uint256) {
        // a and b are of the same sign
        // this works thanks to two's complement, the left-most bit is the sign bit
        if ((a ^ b) > -1) {
            return delta(abs(a), abs(b));
        }

        // a and b are of opposite signs
        return abs(a) + abs(b);
    }

    function percentDelta(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);

        return absDelta * 1e18 / b;
    }

    function percentDelta(int256 a, int256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);
        uint256 absB = abs(b);

        return absDelta * 1e18 / absB;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette} from "libraries/Palette.sol";
import {Util} from "libraries/Util.sol";
import {SVG} from "libraries/SVG.sol";
import {Traits} from "libraries/Traits.sol";
import {Eyes2} from "libraries/Eyes2.sol";

enum EyeType {
    OVAL,
    SMILEY,
    WINK,
    ROUND,
    SLEEPY,
    CLOVER,
    DIZZY,
    STAR,
    HEART,
    HAHA,
    CYCLOPS,
    OPALINE
}

library Eyes {
    string constant fill = "black";

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        EyeType eyeType = Traits.eyeType(_seed);

        if (eyeType == EyeType.OVAL) return _oval(fill);
        if (eyeType == EyeType.SMILEY) return _smiley(fill);
        if (eyeType == EyeType.WINK) return _wink(fill);
        if (eyeType == EyeType.ROUND) return _round(fill);
        if (eyeType == EyeType.SLEEPY) return _sleepy(fill);
        if (eyeType == EyeType.CLOVER) return _clover(fill);
        if (eyeType == EyeType.DIZZY) return _dizzy(fill);
        if (eyeType == EyeType.STAR) return _star(fill);
        if (eyeType == EyeType.HEART) return _heart(fill);
        if (eyeType == EyeType.HAHA) return _haha(fill);
        if (eyeType == EyeType.CYCLOPS) return _cyclops(fill);
        return Eyes2.opaline(fill);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _oval(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<ellipse cx="58" cy="79" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="142" cy="79" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="65" cy="75.5" rx="6" ry="6.5" fill="white"/>',
                '<ellipse cx="149" cy="75.5" rx="6" ry="6.5" fill="white"/>'
            );
    }

    function _clover(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M50 69L66 85M50 85L66 69" stroke="',
                _fill,
                '" stroke-width="24" stroke-linecap="round"/>',
                '<path d="M134 69L150 85M134 85L150 69" stroke="',
                _fill,
                '" stroke-width="24" stroke-linecap="round"/>',
                '<circle cx="149" cy="72" r="6" fill="white"/>',
                '<circle cx="65" cy="72" r="6" fill="white"/>'
            );
    }

    function _dizzy(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M59.6645 74.0529C61.0054 72.9366 59.3272 69.9131 56.2074 70.5958C53.2108 70.9583 50.279 75.8268 52.9588 80.7586C55.2103 85.6761 63.4411 88.7892 70.0358 84.4242C76.7252 80.5755 79.5444 69.1782 73.0767 60.6407C67.2313 51.9471 52.4557 48.7063 42.3791 56.7675C32.004 64.0877 29.2918 82.0505 39.5466 94.1708" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<path d="M140.459 73.9503C139.143 75.046 140.79 78.0136 143.852 77.3435C146.793 76.9877 149.671 72.2092 147.04 67.3687C144.83 62.542 136.752 59.4865 130.279 63.7708C123.713 67.5484 120.946 78.7349 127.295 87.1145C133.032 95.6473 147.534 98.8282 157.424 90.9161C167.608 83.7313 170.27 66.1006 160.204 54.2045" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>'
            );
    }

    function _cyclops(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<ellipse cx="100" cy="70" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="107" cy="66.5" rx="6" ry="6.5" fill="white"/>'
            );
    }

    function _heart(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M58.0103 99C58.3112 99 58.66 98.8972 59.0567 98.6915C59.467 98.4995 59.8569 98.2801 60.2262 98.0332C64.0288 95.5649 67.3322 92.9731 70.1363 90.2579C72.9541 87.529 75.1358 84.7247 76.6815 81.8449C78.2272 78.9515 79 76.0374 79 73.1028C79 71.1556 78.6854 69.3797 78.0562 67.7753C77.427 66.1709 76.5652 64.7859 75.4709 63.6203C74.3767 62.4546 73.1045 61.5633 71.6546 60.9462C70.2047 60.3154 68.6522 60 66.9971 60C64.9453 60 63.1602 60.5211 61.6419 61.5633C60.1236 62.5918 58.913 63.9494 58.0103 65.6361C57.0938 63.9631 55.8764 62.6055 54.3581 61.5633C52.8534 60.5211 51.0684 60 49.0029 60C47.3478 60 45.7953 60.3154 44.3454 60.9462C42.9091 61.5633 41.637 62.4546 40.5291 63.6203C39.4211 64.7859 38.5525 66.1709 37.9233 67.7753C37.3078 69.3797 37 71.1556 37 73.1028C37 76.0374 37.7728 78.9515 39.3185 81.8449C40.8642 84.7247 43.0459 87.529 45.8637 90.2579C48.6815 92.9731 51.9849 95.5649 55.7738 98.0332C56.1568 98.2801 56.5467 98.4995 56.9433 98.6915C57.3537 98.8972 57.7093 99 58.0103 99Z" fill="',
                _fill,
                '"/>',
                '<path d="M142.01 99C142.311 99 142.66 98.8972 143.057 98.6915C143.467 98.4995 143.857 98.2801 144.226 98.0332C148.029 95.5649 151.332 92.9731 154.136 90.2579C156.954 87.529 159.136 84.7247 160.681 81.8449C162.227 78.9515 163 76.0374 163 73.1028C163 71.1556 162.685 69.3797 162.056 67.7753C161.427 66.1709 160.565 64.7859 159.471 63.6203C158.377 62.4546 157.105 61.5633 155.655 60.9462C154.205 60.3154 152.652 60 150.997 60C148.945 60 147.16 60.5211 145.642 61.5633C144.124 62.5918 142.913 63.9494 142.01 65.6361C141.094 63.9631 139.876 62.6055 138.358 61.5633C136.853 60.5211 135.068 60 133.003 60C131.348 60 129.795 60.3154 128.345 60.9462C126.909 61.5633 125.637 62.4546 124.529 63.6203C123.421 64.7859 122.553 66.1709 121.923 67.7753C121.308 69.3797 121 71.1556 121 73.1028C121 76.0374 121.773 78.9515 123.319 81.8449C124.864 84.7247 127.046 87.529 129.864 90.2579C132.681 92.9731 135.985 95.5649 139.774 98.0332C140.157 98.2801 140.547 98.4995 140.943 98.6915C141.354 98.8972 141.709 99 142.01 99Z" fill="',
                _fill,
                '"/>',
                '<circle cx="152" cy="74" r="6" fill="white"/>',
                '<circle cx="68" cy="74" r="6" fill="white"/>'
            );
    }

    function _smiley(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M40 77.5C46 71.8333 61.6 64.6 76 81" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<path d="M160 77.5C154 71.8333 138.4 64.6 124 81" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>'
            );
    }

    function _sleepy(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M74.9877 69.8113C70.6588 76.8378 57.4625 87.8622 39.3086 75.748" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<path d="M125.012 69.8113C129.341 76.8378 142.537 87.8622 160.691 75.748" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>'
            );
    }

    function _star(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M121.162 79.0869C121.502 80.5275 122.637 81.8486 124.907 84.4908L125.109 84.7264C124.84 87.7584 124.737 89.3509 125.27 90.6376C125.768 91.8434 126.645 92.8641 127.774 93.5533C128.979 94.2887 130.603 94.4663 133.706 94.7339L133.909 94.9695C136.179 97.6116 137.314 98.9327 138.707 99.5104C139.933 100.019 141.292 100.135 142.589 99.8422C144.064 99.5096 145.416 98.401 148.122 96.184L148.363 95.9863C151.467 96.2492 153.097 96.3497 154.415 95.8298C155.649 95.3426 156.694 94.4862 157.4 93.3833C158.153 92.2064 158.335 90.6206 158.609 87.589L158.85 87.3913C161.555 85.1743 162.907 84.0658 163.499 82.7048C164.019 81.5076 164.138 80.1803 163.838 78.9131C163.498 77.4725 162.363 76.1514 160.093 73.5092L159.891 73.2737C160.16 70.2417 160.263 68.6491 159.731 67.3624C159.232 66.1566 158.355 65.1359 157.226 64.4467C156.021 63.7113 154.397 63.5337 151.294 63.2661L151.091 63.0305C148.821 60.3884 147.686 59.0673 146.293 58.4896C145.067 57.9814 143.708 57.8653 142.411 58.1578C140.936 58.4904 139.584 59.599 136.878 61.816L136.637 62.0137C133.533 61.7508 131.903 61.6503 130.585 62.1702C129.351 62.6574 128.306 63.5138 127.6 64.6167C126.847 65.7936 126.666 67.3794 126.392 70.4109L126.15 70.6087C123.445 72.8257 122.093 73.9342 121.501 75.2952C120.981 76.4924 120.862 77.8197 121.162 79.0869Z" fill="',
                _fill,
                '"/>',
                '<path d="M36.4896 82.7048C37.0673 84.0658 38.3884 85.1743 41.0305 87.3913L41.2662 87.5891C41.5338 90.6206 41.7114 92.2064 42.4468 93.3833C43.1359 94.4862 44.1566 95.3426 45.3625 95.8298C46.6492 96.3497 48.2417 96.2492 51.2736 95.9863L51.5092 96.184C54.1514 98.401 55.4725 99.5096 56.9131 99.8422C58.1803 100.135 59.5076 100.019 60.7048 99.5104C62.0658 98.9327 63.1743 97.6116 65.3913 94.9695L65.589 94.7339C68.6206 94.4663 70.2064 94.2887 71.3833 93.5533C72.4862 92.8641 73.3427 91.8434 73.8299 90.6376C74.3498 89.3509 74.2492 87.7583 73.9864 84.7263L74.184 84.4908C76.401 81.8486 77.5096 80.5275 77.8422 79.0869C78.1347 77.8197 78.0186 76.4924 77.5104 75.2952C76.9327 73.9342 75.6116 72.8257 72.9695 70.6087L72.7339 70.411C72.4663 67.3794 72.2888 65.7936 71.5533 64.6167C70.8642 63.5138 69.8435 62.6574 68.6376 62.1702C67.3509 61.6503 65.7584 61.7508 62.7264 62.0137L62.4908 61.816C59.8486 59.599 58.5275 58.4904 57.0869 58.1578C55.8197 57.8653 54.4924 57.9814 53.2952 58.4896C51.9342 59.0673 50.8257 60.3884 48.6087 63.0305L48.411 63.2661C45.3795 63.5337 43.7937 63.7113 42.6168 64.4467C41.5139 65.1359 40.6574 66.1566 40.1702 67.3624C39.6504 68.6491 39.7509 70.2416 40.0137 73.2736L39.816 73.5092C37.599 76.1514 36.4904 77.4725 36.1578 78.9131C35.8653 80.1803 35.9814 81.5076 36.4896 82.7048Z" fill="',
                _fill,
                '"/>',
                '<circle cx="148" cy="73" r="6" fill="white"/>',
                '<circle cx="64" cy="73" r="6" fill="white"/>'
            );
    }

    function _wink(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M160 77.5C154 71.8333 138.4 64.6 124 81" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round"/>',
                '<ellipse cx="58" cy="79" rx="18" ry="20" fill="',
                _fill,
                '"/>',
                '<ellipse cx="65" cy="75.5" rx="6" ry="6.5" fill="white"/>'
            );
    }

    function _haha(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M74 80.5L44 77.5833M74 80.5L57.8571 61M74 80.5L52.8571 94" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>',
                '<path d="M126 80.5L156 77.5833M126 80.5L142.143 61M126 80.5L147.143 94" stroke="',
                _fill,
                '" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>'
            );
    }

    function _round(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<circle cx="142" cy="79" r="19" fill="',
                _fill,
                '"/>',
                '<circle cx="58" cy="79" r="19" fill="',
                _fill,
                '"/>',
                '<circle cx="65" cy="75" r="6" fill="white"/>',
                '<circle cx="149" cy="75" r="6" fill="white"/>'
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";
import {Traits} from "./Traits.sol";

enum CheekType {
    NONE,
    CIRCULAR,
    FRECKLES,
    BIG
}

library Cheeks {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        CheekType cheekType = Traits.cheekType(_seed);
        if (cheekType == CheekType.CIRCULAR) return _circular();
        if (cheekType == CheekType.FRECKLES) return _freckles();
        if (cheekType == CheekType.BIG) return _big();
        return "";
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _circular() internal pure returns (string memory) {
        return
            string.concat(
                "<g opacity='0.25'>",
                "<circle cx='148' cy='112' r='6' fill='black'/>",
                "<circle cx='52' cy='112' r='6' fill='black'/>",
                "</g>"
            );
    }

    function _big() internal pure returns (string memory) {
        return
            string.concat(
                "<g opacity='0.15'>",
                "<ellipse cx='150' cy='112' rx='11' ry='10' fill='black'/>",
                "<ellipse cx='50' cy='112' rx='11' ry='10' fill='black'/>",
                "</g>"
            );
    }

    function _freckles() internal pure returns (string memory) {
        return
            string.concat(
                "<g opacity='0.25'>",
                "<path d='M53 109.5C53 111.433 54.567 113 56.5 113C58.433 113 60 111.433 60 109.5C60 107.567 58.433 106 56.5 106C54.567 106 53 107.567 53 109.5Z' fill='black'/>",
                "<path d='M46 116.5C46 118.433 47.567 120 49.5 120C51.433 120 53 118.433 53 116.5C53 114.567 51.433 113 49.5 113C47.567 113 46 114.567 46 116.5Z' fill='black'/>",
                "<path d='M42 107.5C42 109.433 43.567 111 45.5 111C47.433 111 49 109.433 49 107.5C49 105.567 47.433 104 45.5 104C43.567 104 42 105.567 42 107.5Z' fill='black'/>",
                "<path d='M147 109.5C147 111.433 145.433 113 143.5 113C141.567 113 140 111.433 140 109.5C140 107.567 141.567 106 143.5 106C145.433 106 147 107.567 147 109.5Z' fill='black'/>",
                "<path d='M154 116.5C154 118.433 152.433 120 150.5 120C148.567 120 147 118.433 147 116.5C147 114.567 148.567 113 150.5 113C152.433 113 154 114.567 154 116.5Z' fill='black'/>",
                "<path d='M158 107.5C158 109.433 156.433 111 154.5 111C152.567 111 151 109.433 151 107.5C151 105.567 152.567 104 154.5 104C156.433 104 158 105.567 158 107.5Z' fill='black'/>",
                "</g>"
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Palette} from "./Palette.sol";
import {Traits} from "./Traits.sol";

enum MouthType {
    SMILE,
    GRATIFIED,
    POLITE,
    HMM,
    OOO,
    GRIN,
    SMOOCH,
    TOOTHY,
    SMIRK,
    VEE,
    CAT,
    BLEP
}

library Mouth {
    string constant fill = "black";

    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(bytes32 _seed) external pure returns (string memory) {
        MouthType mouthType = Traits.mouthType(_seed);

        if (mouthType == MouthType.SMILE) return _smile(fill);
        if (mouthType == MouthType.GRATIFIED) return _gratified(fill);
        if (mouthType == MouthType.POLITE) return _polite(fill);
        if (mouthType == MouthType.HMM) return _hmm(fill);
        if (mouthType == MouthType.OOO) return _ooo(fill);
        if (mouthType == MouthType.GRIN) return _grin(fill);
        if (mouthType == MouthType.SMOOCH) return _smooch(fill);
        if (mouthType == MouthType.TOOTHY) return _toothy(fill);
        if (mouthType == MouthType.CAT) return _cat(fill);
        if (mouthType == MouthType.VEE) return _vee(fill);
        if (mouthType == MouthType.BLEP) return _blep(fill);
        return _smirk(fill);
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _smile(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M71 115.208C83.2665 139.324 116.641 138.602 129 115' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _gratified(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M80 115.139C88.4596 131.216 111.476 130.735 120 115' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _polite(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M90 110.081C94.2298 119.459 105.738 119.179 110 110' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _ooo(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M108 121.5C108 126.747 104.418 129 100 129C95.5817 129 92 126.747 92 121.5C92 116.253 95.5817 112 100 112C104.418 112 108 116.253 108 121.5Z' fill='",
                _fill,
                "'/>"
            );
    }

    function _smooch(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M97 100C118 95.9999 122 116 103.993 119C122 121 119 140.5 98 138' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round' stroke-linejoin='round'/>",
                "<path d='M131.055 124.545C131.141 124.54 131.238 124.505 131.348 124.44C131.462 124.378 131.569 124.309 131.67 124.233C132.713 123.467 133.612 122.675 134.366 121.856C135.123 121.033 135.699 120.199 136.091 119.354C136.484 118.505 136.655 117.664 136.606 116.829C136.574 116.276 136.454 115.776 136.248 115.33C136.042 114.884 135.773 114.505 135.442 114.192C135.11 113.879 134.733 113.647 134.309 113.495C133.885 113.34 133.437 113.277 132.966 113.304C132.381 113.339 131.88 113.517 131.465 113.838C131.049 114.156 130.727 114.563 130.498 115.057C130.208 114.597 129.839 114.231 129.388 113.96C128.942 113.689 128.425 113.571 127.836 113.606C127.364 113.633 126.927 113.749 126.524 113.953C126.125 114.152 125.777 114.427 125.48 114.777C125.184 115.127 124.959 115.535 124.807 116.002C124.658 116.469 124.6 116.979 124.633 117.532C124.682 118.367 124.951 119.183 125.44 119.98C125.928 120.773 126.597 121.534 127.446 122.262C128.295 122.987 129.28 123.669 130.401 124.308C130.514 124.371 130.629 124.427 130.745 124.475C130.866 124.527 130.969 124.55 131.055 124.545Z' fill='",
                _fill,
                "'/>"
            );
    }

    function _grin(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M79 119C90.8621 122.983 110.138 123.017 122 119' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _toothy(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M72 115L76.9006 121.006C78.7745 123.303 82.045 123.887 84.5981 122.381L86.358 121.343C88.6999 119.961 91.678 120.327 93.6157 122.235L96.2815 124.859C98.6159 127.157 102.362 127.158 104.697 124.861L107.373 122.231C109.311 120.326 112.287 119.961 114.628 121.342L116.393 122.383C118.945 123.888 122.214 123.306 124.088 121.012L129 115' stroke='",
                _fill,
                "' stroke-width='10' stroke-miterlimit='10' stroke-linecap='round'/>"
            );
    }

    function _cat(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M77 112.5C77 119.404 82.5964 125 89.5 125C93.9023 125 97.773 122.724 100 119.285C102.227 122.724 106.098 125 110.5 125C117.404 125 123 119.404 123 112.5' stroke='",
                _fill,
                "' stroke-width='10' stroke-linejoin='round' stroke-linecap='round'/>"
            );
    }

    function _vee(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M85 112L95.7711 117.027C98.4516 118.277 101.548 118.277 104.229 117.027L115 112' stroke='",
                _fill,
                "' stroke-width='10' stroke-linejoin='round' stroke-linecap='round'/>"
            );
    }

    function _hmm(string memory _fill) internal pure returns (string memory) {
        return string.concat("<path d='M83 119H118' stroke='", _fill, "' stroke-width='10' stroke-linecap='round'/>");
    }

    function _smirk(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                "<path d='M129 115C120.699 130.851 102.919 136.383 88.4211 131' stroke='",
                _fill,
                "' stroke-width='10' stroke-linecap='round'/>"
            );
    }

    function _blep(string memory _fill) internal pure returns (string memory) {
        return
            string.concat(
                '<path d="M70 115C86.5517 120.557 113.448 120.606 130 115" stroke-width="10" stroke-linecap="round" stroke="',
                _fill,
                '"/>',
                '<path d="M96.2169 124.829C94.7132 149.357 132.515 145.477 126.034 121.514" stroke-width="8" stroke-linecap="round" stroke="',
                _fill,
                '"/>',
                '<path d="M111.011 121.05L113 141" stroke-width="4" stroke-linecap="round" stroke="',
                _fill,
                '"/>'
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Vm.sol";
import "./console.sol";
import "./console2.sol";

abstract contract Script {
    bool public IS_SCRIPT = true;
    address constant private VM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    Vm public constant vm = Vm(VM_ADDRESS);

    /// @dev Compute the address a contract will be deployed at for a given deployer address and nonce
    /// @notice adapated from Solmate implementation (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
    function computeCreateAddress(address deployer, uint256 nonce) internal pure returns (address) {
        // The integer zero is treated as an empty byte string, and as a result it only has a length prefix, 0x80, computed via 0x80 + 0.
        // A one byte integer uses its own value as its length prefix, there is no additional "0x80 + length" prefix that comes before it.
        if (nonce == 0x00)             return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))));
        if (nonce <= 0x7f)             return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))));

        // Nonces greater than 1 byte all follow a consistent encoding scheme, where each value is preceded by a prefix of 0x80 + length.
        if (nonce <= 2**8 - 1)  return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd7), bytes1(0x94), deployer, bytes1(0x81), uint8(nonce))));
        if (nonce <= 2**16 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd8), bytes1(0x94), deployer, bytes1(0x82), uint16(nonce))));
        if (nonce <= 2**24 - 1) return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xd9), bytes1(0x94), deployer, bytes1(0x83), uint24(nonce))));

        // More details about RLP encoding can be found here: https://eth.wiki/fundamentals/rlp
        // 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x84 ++ nonce)
        // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
        // 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
        // We assume nobody can have a nonce large enough to require more than 32 bytes.
        return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xda), bytes1(0x94), deployer, bytes1(0x84), uint32(nonce))));
    }

    function addressFromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.0;

contract DSTest {
    event log                    (string);
    event logs                   (bytes);

    event log_address            (address);
    event log_bytes32            (bytes32);
    event log_int                (int);
    event log_uint               (uint);
    event log_bytes              (bytes);
    event log_string             (string);

    event log_named_address      (string key, address val);
    event log_named_bytes32      (string key, bytes32 val);
    event log_named_decimal_int  (string key, int val, uint decimals);
    event log_named_decimal_uint (string key, uint val, uint decimals);
    event log_named_int          (string key, int val);
    event log_named_uint         (string key, uint val);
    event log_named_bytes        (string key, bytes val);
    event log_named_string       (string key, string val);

    bool public IS_TEST = true;
    bool private _failed;

    address constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    modifier mayRevert() { _; }
    modifier testopts(string memory) { _; }

    function failed() public returns (bool) {
        if (_failed) {
            return _failed;
        } else {
            bool globalFailed = false;
            if (hasHEVMContext()) {
                (, bytes memory retdata) = HEVM_ADDRESS.call(
                    abi.encodePacked(
                        bytes4(keccak256("load(address,bytes32)")),
                        abi.encode(HEVM_ADDRESS, bytes32("failed"))
                    )
                );
                globalFailed = abi.decode(retdata, (bool));
            }
            return globalFailed;
        }
    } 

    function fail() internal {
        if (hasHEVMContext()) {
            (bool status, ) = HEVM_ADDRESS.call(
                abi.encodePacked(
                    bytes4(keccak256("store(address,bytes32,bytes32)")),
                    abi.encode(HEVM_ADDRESS, bytes32("failed"), bytes32(uint256(0x01)))
                )
            );
            status; // Silence compiler warnings
        }
        _failed = true;
    }

    function hasHEVMContext() internal view returns (bool) {
        uint256 hevmCodeSize = 0;
        assembly {
            hevmCodeSize := extcodesize(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D)
        }
        return hevmCodeSize > 0;
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            assertTrue(condition);
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            emit log_named_bytes32("  Expected", b);
            emit log_named_bytes32("    Actual", a);
            fail();
        }
    }
    function assertEq(bytes32 a, bytes32 b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }
    function assertEq32(bytes32 a, bytes32 b, string memory err) internal {
        assertEq(a, b, err);
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [int]");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            fail();
        }
    }
    function assertEq(int a, int b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }
    function assertEq(uint a, uint b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal int]");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGt(uint a, uint b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGt(int a, int b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGt(int a, int b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGtDecimal(int a, int b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGe(uint a, uint b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGe(int a, int b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGe(int a, int b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGeDecimal(int a, int b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLt(uint a, uint b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLt(int a, int b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLt(int a, int b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLtDecimal(int a, int b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLe(uint a, uint b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLe(int a, int b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLe(int a, int b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLeDecimal(int a, int b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertEq(string memory a, string memory b) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log("Error: a == b not satisfied [string]");
            emit log_named_string("  Expected", b);
            emit log_named_string("    Actual", a);
            fail();
        }
    }
    function assertEq(string memory a, string memory b, string memory err) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function checkEq0(bytes memory a, bytes memory b) internal pure returns (bool ok) {
        ok = true;
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }
    function assertEq0(bytes memory a, bytes memory b) internal {
        if (!checkEq0(a, b)) {
            emit log("Error: a == b not satisfied [bytes]");
            emit log_named_bytes("  Expected", b);
            emit log_named_bytes("    Actual", a);
            fail();
        }
    }
    function assertEq0(bytes memory a, bytes memory b, string memory err) internal {
        if (!checkEq0(a, b)) {
            emit log_named_string("Error", err);
            assertEq0(a, b);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library Eyes2 {
    function opaline(string memory _fill) external pure returns (string memory) {
        return
            string.concat(
                '<circle cx="58" cy="79" r="22" fill="',
                _fill,
                '"/>',
                '<circle cx="142" cy="79" r="22" fill="',
                _fill,
                '"/>',
                '<path d="M45.6829 86.5051C45.615 86.0823 45.8239 85.6632 46.2023 85.4628L48.3117 84.3458C48.6981 84.1411 49.1727 84.2113 49.4834 84.5191L51.1522 86.1722C51.4589 86.476 51.536 86.9422 51.3435 87.3286L50.2685 89.486C50.076 89.8724 49.6573 90.0916 49.2301 90.0297L46.9054 89.6929C46.4726 89.6302 46.1308 89.2936 46.0614 88.8618L45.6829 86.5051Z" fill="white" fill-opacity="0.9"/>',
                '<path d="M49.0832 72.1223C49.0972 72.4245 48.962 72.5987 48.6777 72.6448C48.5583 72.6642 48.4466 72.6413 48.3427 72.5762C48.2387 72.511 48.1685 72.4199 48.132 72.3028C47.975 71.766 47.8354 71.3552 47.7134 71.0705C47.5961 70.7791 47.4453 70.5692 47.2611 70.441C47.0826 70.3118 46.8215 70.2311 46.4779 70.199C46.1389 70.1602 45.6664 70.1256 45.0604 70.095C44.7782 70.0822 44.6158 69.9445 44.5733 69.682C44.5538 69.5621 44.5765 69.4501 44.6413 69.3459C44.7061 69.2417 44.7968 69.1713 44.9135 69.1348C45.4814 68.9666 45.9215 68.8191 46.2336 68.6924C46.5456 68.5656 46.7683 68.4094 46.9016 68.2238C47.0349 68.0382 47.1098 67.7801 47.1262 67.4494C47.1483 67.1179 47.1477 66.6641 47.1243 66.088C47.1169 65.7905 47.2525 65.6192 47.5312 65.574C47.8155 65.5279 47.9988 65.6504 48.081 65.9417C48.2371 66.4728 48.3738 66.884 48.4911 67.1754C48.6075 67.4611 48.7573 67.6652 48.9406 67.7878C49.1238 67.9104 49.3878 67.9906 49.7324 68.0284C50.0761 68.0605 50.5481 68.0923 51.1485 68.1238C51.4373 68.1414 51.6025 68.2786 51.6441 68.5355C51.6885 68.8094 51.5581 68.9945 51.2527 69.0909C50.698 69.2687 50.2679 69.4234 49.9624 69.5549C49.6569 69.6864 49.4375 69.845 49.3042 70.0306C49.1709 70.2162 49.0956 70.4715 49.0783 70.7964C49.0609 71.1214 49.0626 71.5633 49.0832 72.1223Z" fill="white" fill-opacity="0.9"/>',
                '<circle cx="61.5" cy="64.5" r="2.5" fill="white" fill-opacity="0.9"/>',
                '<circle cx="54.5" cy="65.5" r="1.5" fill="white" fill-opacity="0.9"/>',
                '<circle cx="69" cy="67" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="73" cy="74" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="63" cy="93" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="43" cy="84" r="1" fill="white" fill-opacity="0.9"/>',
                '<circle cx="44" cy="72" r="1" fill="white" fill-opacity="0.9"/>',
                string.concat(
                    '<circle cx="51" cy="94" r="1" fill="white" fill-opacity="0.9"/>',
                    '<ellipse cx="71.2904" cy="83.7158" rx="3.60879" ry="2.40586" transform="rotate(-25.2591 71.2904 83.7158)" fill="white" fill-opacity="0.9"/>',
                    '<path d="M56.6664 88.3688C56.7484 88.5271 56.871 88.6329 57.0344 88.6863C57.199 88.7431 57.3906 88.7546 57.6091 88.7208L59.8863 88.3738L60.9745 90.3967C61.0816 90.5926 61.2062 90.7386 61.3483 90.8346C61.4918 90.9339 61.6513 90.9686 61.827 90.9387C61.9992 90.9097 62.1345 90.8289 62.2328 90.696C62.3334 90.5643 62.3962 90.3942 62.4211 90.1857L62.6945 87.964L64.9705 87.6458C65.1902 87.6153 65.367 87.5509 65.5008 87.4525C65.6345 87.3541 65.7107 87.2187 65.7294 87.0462C65.7504 86.8748 65.7103 86.7206 65.6091 86.5835C65.5079 86.4464 65.3583 86.3299 65.1605 86.2342L63.0724 85.2154L63.3893 82.9944C63.4199 82.7803 63.4041 82.5948 63.3419 82.438C63.2821 82.2823 63.1737 82.1654 63.0168 82.0873C62.8575 82.008 62.6966 81.9908 62.5339 82.0357C62.3736 82.0817 62.2173 82.1814 62.0649 82.3349L60.4834 83.9261L58.4085 82.8719C58.2153 82.7729 58.0334 82.7243 57.863 82.7261C57.6926 82.728 57.5459 82.7878 57.4229 82.9055C57.2965 83.0244 57.2338 83.168 57.2347 83.3363C57.2391 83.5035 57.2942 83.6834 57.4 83.8759L58.5176 85.884L56.9093 87.4409C56.7579 87.5865 56.66 87.7391 56.6155 87.8988C56.5711 88.0584 56.5881 88.2151 56.6664 88.3688Z" fill="white" fill-opacity="0.9"/>',
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="M52.9292 80.493C53.3951 78.0879 56.1205 79.674 54.2643 81.2575C56.5734 80.4584 56.5579 83.6048 54.2589 82.796C56.1189 84.3923 53.3779 85.9525 52.9351 83.5603C52.4693 85.9654 49.7535 84.3959 51.6 82.7957C49.2838 83.6212 49.2993 80.4748 51.6055 81.2572C49.7384 79.6873 52.4864 78.1007 52.9292 80.493Z" fill="white" fill-opacity="0.9"/>',
                    '<path fill-rule="evenodd" clip-rule="evenodd" d="M57.3165 92.4697C57.5912 91.0518 59.198 91.9869 58.1036 92.9205C59.465 92.4494 59.4559 94.3044 58.1004 93.8275C59.197 94.7686 57.5811 95.6885 57.32 94.2781C57.0454 95.6961 55.4442 94.7708 56.5329 93.8274C55.1673 94.314 55.1765 92.459 56.5361 92.9203C55.4353 91.9948 57.0555 91.0593 57.3165 92.4697ZM57.2111 93.1997C57.3099 93.1426 57.4442 93.17 57.501 93.2684C57.5578 93.3668 57.5201 93.5067 57.4213 93.5637C57.3225 93.6208 57.1923 93.5778 57.1355 93.4794C57.0787 93.3811 57.1123 93.2567 57.2111 93.1997Z" fill="white" fill-opacity="0.9"/>',
                    '<path d="M57.4651 77.0869C57.683 77.417 57.6477 77.7029 57.3593 77.9448C57.2382 78.0464 57.0975 78.0954 56.9372 78.0918C56.777 78.0881 56.6372 78.0328 56.5179 77.9257C55.9826 77.428 55.5512 77.0601 55.2238 76.822C54.8972 76.5733 54.5876 76.4385 54.295 76.4176C54.0082 76.3919 53.6611 76.476 53.2538 76.6697C52.8473 76.8529 52.2936 77.1299 51.5927 77.5008C51.2673 77.6752 50.9929 77.6292 50.7696 77.3629C50.6676 77.2413 50.6182 77.1004 50.6212 76.94C50.6243 76.7797 50.6791 76.64 50.7857 76.5211C51.3109 75.9524 51.7063 75.4925 51.972 75.1415C52.2376 74.7905 52.3832 74.4662 52.4088 74.1687C52.4343 73.8711 52.3457 73.5312 52.1431 73.149C51.9461 72.762 51.642 72.2529 51.2305 71.6217C51.0232 71.2926 51.0609 71.0095 51.3436 70.7725C51.632 70.5306 51.9197 70.5457 52.2068 70.8176C52.7372 71.3095 53.1658 71.6799 53.4923 71.9286C53.814 72.1716 54.1187 72.3006 54.4064 72.3156C54.6942 72.3307 55.0442 72.2442 55.4564 72.0563C55.8637 71.8625 56.415 71.5826 57.1101 71.2165C57.4462 71.0431 57.7234 71.0867 57.9419 71.3472C58.175 71.625 58.1523 71.9201 57.8739 72.2325C57.37 72.8031 56.9905 73.2644 56.7354 73.6164C56.4804 73.9683 56.3401 74.2931 56.3146 74.5906C56.289 74.8882 56.3752 75.2252 56.573 75.6016C56.7708 75.978 57.0682 76.4731 57.4651 77.0869Z" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="45" cy="78" r="2" fill="white" fill-opacity="0.9"/>',
                    '<ellipse cx="53.5" cy="90" rx="1.5" ry="1" fill="white" fill-opacity="0.9"/>',
                    '<ellipse cx="67.5" cy="90" rx="1.5" ry="2" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="149" cy="75" r="6" fill="white"/>',
                    '<path d="M129.683 86.5051C129.615 86.0823 129.824 85.6632 130.202 85.4628L132.312 84.3458C132.698 84.1411 133.173 84.2113 133.483 84.5191L135.152 86.1722C135.459 86.476 135.536 86.9422 135.344 87.3286L134.269 89.486C134.076 89.8724 133.657 90.0916 133.23 90.0297L130.905 89.6929C130.473 89.6302 130.131 89.2936 130.061 88.8618L129.683 86.5051Z" fill="white" fill-opacity="0.9"/>',
                    '<path d="M133.083 72.1223C133.097 72.4245 132.962 72.5987 132.678 72.6448C132.558 72.6642 132.447 72.6413 132.343 72.5762C132.239 72.511 132.169 72.4199 132.132 72.3028C131.975 71.766 131.835 71.3552 131.713 71.0705C131.596 70.7791 131.445 70.5692 131.261 70.441C131.083 70.3118 130.822 70.2311 130.478 70.199C130.139 70.1602 129.666 70.1256 129.06 70.095C128.778 70.0822 128.616 69.9445 128.573 69.682C128.554 69.5621 128.577 69.4501 128.641 69.3459C128.706 69.2417 128.797 69.1713 128.913 69.1348C129.481 68.9666 129.921 68.8191 130.234 68.6924C130.546 68.5656 130.768 68.4094 130.902 68.2238C131.035 68.0382 131.11 67.7801 131.126 67.4494C131.148 67.1179 131.148 66.6641 131.124 66.088C131.117 65.7905 131.253 65.6192 131.531 65.574C131.815 65.5279 131.999 65.6504 132.081 65.9417C132.237 66.4728 132.374 66.884 132.491 67.1754C132.607 67.4611 132.757 67.6652 132.941 67.7878C133.124 67.9104 133.388 67.9906 133.732 68.0284C134.076 68.0605 134.548 68.0923 135.148 68.1238C135.437 68.1414 135.602 68.2786 135.644 68.5355C135.689 68.8094 135.558 68.9945 135.253 69.0909C134.698 69.2687 134.268 69.4234 133.962 69.5549C133.657 69.6864 133.438 69.845 133.304 70.0306C133.171 70.2162 133.096 70.4715 133.078 70.7964C133.061 71.1214 133.063 71.5633 133.083 72.1223Z" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="145.5" cy="64.5" r="2.5" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="138.5" cy="65.5" r="1.5" fill="white" fill-opacity="0.9"/>',
                    '<circle cx="153" cy="67" r="1" fill="white" fill-opacity="0.9"/>',
                    string.concat(
                        '<circle cx="157" cy="74" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="147" cy="93" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="127" cy="84" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="128" cy="72" r="1" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="135" cy="94" r="1" fill="white" fill-opacity="0.9"/>',
                        '<ellipse cx="155.29" cy="83.7158" rx="3.60879" ry="2.40586" transform="rotate(-25.2591 155.29 83.7158)" fill="white" fill-opacity="0.9"/>',
                        '<path d="M140.666 88.3688C140.748 88.5271 140.871 88.6329 141.034 88.6863C141.199 88.7431 141.391 88.7546 141.609 88.7208L143.886 88.3738L144.975 90.3967C145.082 90.5926 145.206 90.7386 145.348 90.8346C145.492 90.9339 145.651 90.9686 145.827 90.9387C145.999 90.9097 146.134 90.8289 146.233 90.696C146.333 90.5643 146.396 90.3942 146.421 90.1857L146.695 87.964L148.971 87.6458C149.19 87.6153 149.367 87.5509 149.501 87.4525C149.635 87.3541 149.711 87.2187 149.729 87.0462C149.75 86.8748 149.71 86.7206 149.609 86.5835C149.508 86.4464 149.358 86.3299 149.16 86.2342L147.072 85.2154L147.389 82.9944C147.42 82.7803 147.404 82.5948 147.342 82.438C147.282 82.2823 147.174 82.1654 147.017 82.0873C146.858 82.008 146.697 81.9908 146.534 82.0357C146.374 82.0817 146.217 82.1814 146.065 82.3349L144.483 83.9261L142.409 82.8719C142.215 82.7729 142.033 82.7243 141.863 82.7261C141.693 82.728 141.546 82.7878 141.423 82.9055C141.297 83.0244 141.234 83.168 141.235 83.3363C141.239 83.5035 141.294 83.6834 141.4 83.8759L142.518 85.884L140.909 87.4409C140.758 87.5865 140.66 87.7391 140.616 87.8988C140.571 88.0584 140.588 88.2151 140.666 88.3688Z" fill="white" fill-opacity="0.9"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M136.929 80.493C137.395 78.0879 140.121 79.674 138.264 81.2575C140.573 80.4584 140.558 83.6048 138.259 82.796C140.119 84.3923 137.378 85.9525 136.935 83.5603C136.469 85.9654 133.753 84.3959 135.6 82.7957C133.284 83.6212 133.299 80.4748 135.605 81.2572C133.738 79.6873 136.486 78.1007 136.929 80.493Z" fill="white" fill-opacity="0.9"/>',
                        '<path fill-rule="evenodd" clip-rule="evenodd" d="M141.317 92.4697C141.591 91.0518 143.198 91.9869 142.104 92.9205C143.465 92.4494 143.456 94.3044 142.1 93.8275C143.197 94.7686 141.581 95.6885 141.32 94.2781C141.045 95.6961 139.444 94.7708 140.533 93.8274C139.167 94.314 139.176 92.459 140.536 92.9203C139.435 91.9948 141.055 91.0593 141.317 92.4697ZM141.211 93.1997C141.31 93.1426 141.444 93.17 141.501 93.2684C141.558 93.3668 141.52 93.5067 141.421 93.5637C141.322 93.6208 141.192 93.5778 141.135 93.4794C141.079 93.3811 141.112 93.2567 141.211 93.1997Z" fill="white" fill-opacity="0.9"/>',
                        '<path d="M141.465 77.0869C141.683 77.417 141.648 77.7029 141.359 77.9448C141.238 78.0464 141.097 78.0954 140.937 78.0918C140.777 78.0881 140.637 78.0328 140.518 77.9257C139.983 77.428 139.551 77.0601 139.224 76.822C138.897 76.5733 138.588 76.4385 138.295 76.4176C138.008 76.3919 137.661 76.476 137.254 76.6697C136.847 76.8529 136.294 77.1299 135.593 77.5008C135.267 77.6752 134.993 77.6292 134.77 77.3629C134.668 77.2413 134.618 77.1004 134.621 76.94C134.624 76.7797 134.679 76.64 134.786 76.5211C135.311 75.9524 135.706 75.4925 135.972 75.1415C136.238 74.7905 136.383 74.4662 136.409 74.1687C136.434 73.8711 136.346 73.5312 136.143 73.149C135.946 72.762 135.642 72.2529 135.23 71.6217C135.023 71.2926 135.061 71.0095 135.344 70.7725C135.632 70.5306 135.92 70.5457 136.207 70.8176C136.737 71.3095 137.166 71.6799 137.492 71.9286C137.814 72.1716 138.119 72.3006 138.406 72.3156C138.694 72.3307 139.044 72.2442 139.456 72.0563C139.864 71.8625 140.415 71.5826 141.11 71.2165C141.446 71.0431 141.723 71.0867 141.942 71.3472C142.175 71.625 142.152 71.9201 141.874 72.2325C141.37 72.8031 140.99 73.2644 140.735 73.6164C140.48 73.9683 140.34 74.2931 140.315 74.5906C140.289 74.8882 140.375 75.2252 140.573 75.6016C140.771 75.978 141.068 76.4731 141.465 77.0869Z" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="129" cy="78" r="2" fill="white" fill-opacity="0.9"/>',
                        '<ellipse cx="137.5" cy="90" rx="1.5" ry="1" fill="white" fill-opacity="0.9"/>',
                        '<ellipse cx="151.5" cy="90" rx="1.5" ry="2" fill="white" fill-opacity="0.9"/>',
                        '<circle cx="65" cy="75" r="6" fill="white"/>'
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface Vm {
    struct Log {
        bytes32[] topics;
        bytes data;
    }

    // Sets block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Sets block.height (newHeight)
    function roll(uint256) external;
    // Sets block.basefee (newBasefee)
    function fee(uint256) external;
    // Sets block.chainid
    function chainId(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external;
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Gets the address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Gets the nonce of an account
    function getNonce(address) external returns (uint64);
    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address, uint64) external;
    // Performs a foreign function call via the terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Sets environment variables, (name, value)
    function setEnv(string calldata, string calldata) external;
    // Reads environment variables, (name) => (value)
    function envBool(string calldata) external returns (bool);
    function envUint(string calldata) external returns (uint256);
    function envInt(string calldata) external returns (int256);
    function envAddress(string calldata) external returns (address);
    function envBytes32(string calldata) external returns (bytes32);
    function envString(string calldata) external returns (string memory);
    function envBytes(string calldata) external returns (bytes memory);
    // Reads environment variables as arrays, (name, delim) => (value[])
    function envBool(string calldata, string calldata) external returns (bool[] memory);
    function envUint(string calldata, string calldata) external returns (uint256[] memory);
    function envInt(string calldata, string calldata) external returns (int256[] memory);
    function envAddress(string calldata, string calldata) external returns (address[] memory);
    function envBytes32(string calldata, string calldata) external returns (bytes32[] memory);
    function envString(string calldata, string calldata) external returns (string[] memory);
    function envBytes(string calldata, string calldata) external returns (bytes[] memory);
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address,address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address,address) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;
    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;
    // Expects an error on next call
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;
    function expectRevert() external;
    // Records all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);
    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool,bool,bool,bool) external;
    function expectEmit(bool,bool,bool,bool,address) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address,uint256,bytes calldata,bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expects a call to an address with the specified calldata.
    // Calldata can either be a strict or a partial match
    function expectCall(address,bytes calldata) external;
    // Expects a call to an address with the specified msg.value and calldata
    function expectCall(address,uint256,bytes calldata) external;
    // Gets the code from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata) external returns (bytes memory);
    // Labels an address in call traces
    function label(address, string calldata) external;
    // If the condition is false, discard this run's fuzz inputs and generate new ones
    function assume(bool) external;
    // Sets block.coinbase (who)
    function coinbase(address) external;
    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;
    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address) external;
    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast(address) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;
    // Reads the entire content of file to string, (path) => (data)
    function readFile(string calldata) external returns (string memory);
    // Reads next line of file to string, (path) => (line)
    function readLine(string calldata) external returns (string memory);
    // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // (path, data) => ()
    function writeFile(string calldata, string calldata) external;
    // Writes line to file, creating a file if it does not exist.
    // (path, data) => ()
    function writeLine(string calldata, string calldata) external;
    // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
    // (path) => ()
    function closeFile(string calldata) external;
    // Removes file. This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - Path points to a directory.
    // - The file doesn't exist.
    // - The user lacks permissions to remove the file.
    // (path) => ()
    function removeFile(string calldata) external;
    // Convert values to a string, (value) => (stringified value)
    function toString(address) external returns(string memory);
    function toString(bytes calldata) external returns(string memory);
    function toString(bytes32) external returns(string memory);
    function toString(bool) external returns(string memory);
    function toString(uint256) external returns(string memory);
    function toString(int256) external returns(string memory);
    // Record all the transaction logs
    function recordLogs() external;
    // Gets all the recorded logs, () => (logs)
    function getRecordedLogs() external returns (Log[] memory);
    // Snapshot the current state of the evm.
    // Returns the id of the snapshot that was created.
    // To revert a snapshot use `revertTo`
    function snapshot() external returns(uint256);
    // Revert the state of the evm to a previous snapshot
    // Takes the snapshot id to revert to.
    // This deletes the snapshot and all snapshots taken after the given snapshot id.
    function revertTo(uint256) external returns(bool);
    // Creates a new fork with the given endpoint and block and returns the identifier of the fork
    function createFork(string calldata,uint256) external returns(uint256);
    // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
    function createFork(string calldata) external returns(uint256);
    // Creates _and_ also selects a new fork with the given endpoint and block and returns the identifier of the fork
    function createSelectFork(string calldata,uint256) external returns(uint256);
    // Creates _and_ also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
    function createSelectFork(string calldata) external returns(uint256);
    // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
    function selectFork(uint256) external;
    /// Returns the currently active fork
    /// Reverts if no fork is currently active
    function activeFork() external returns(uint256);
    // Updates the currently active fork to given block number
    // This is similar to `roll` but for the currently active fork
    function rollFork(uint256) external;
    // Updates the given fork to given block number
    function rollFork(uint256 forkId, uint256 blockNumber) external;
    /// Returns the RPC url for the given alias
    function rpcUrl(string calldata) external returns(string memory);
    /// Returns all rpc urls and their aliases `[alias, url][]`
    function rpcUrls() external returns(string[2][] memory);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
    function deriveKey(string calldata, uint32) external returns (uint256);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path {path}{index}
    function deriveKey(string calldata, string calldata, uint32) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// The orignal console.sol uses `int` and `uint` for computing function selectors, but it should
// use `int256` and `uint256`. This modified version fixes that. This version is recommended
// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
// Reference: https://github.com/NomicFoundation/hardhat/issues/2178

library console2 {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}