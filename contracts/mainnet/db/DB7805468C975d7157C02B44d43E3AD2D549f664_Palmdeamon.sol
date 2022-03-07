//SPDX-License-Identifier: Unlicense
import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./metadata.sol";

pragma solidity ^0.8.0;

contract Palmdeamon is ERC721, Metadata {
    address public admin;
    address public verificationcontract;

    mapping(uint256 => tdata) public tokendata;

    struct tdata {
        uint256 moisture;
        uint256 temperature;
        uint256 colorandlocation;
        string rtimestamp;
    }

    constructor(address _admin) ERC721("Seed Capital", "SDC") {
        admin = _admin;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            generatemetadata(
                id,
                tokendata[id].moisture,
                tokendata[id].temperature,
                tokendata[id].colorandlocation,
                tokendata[id].rtimestamp
            );
    }

    function setverificationcontract(address _verificationcontract) public {
        require(msg.sender == admin, "only admin can set verificationcontract");
        verificationcontract = _verificationcontract;
    }

    function setadmin(address newadmin) public {
        require(msg.sender == admin, "only admin can set admin");
        admin = newadmin;
    }

    function generatecolorprofile(
        uint256 profile,
        string memory firsthex,
        string memory secondhex,
        string memory venue,
        string memory plant,
        string memory curator 
    ) public {
        require(msg.sender == admin, "only admin can set colorprofile");
        _generatecolorprofile(
            profile,
            firsthex,
            secondhex,
            venue,
            plant,
            curator 
        );
    }

    function mintafterverification(
        uint256 value1,
        uint256 value2,
        uint256 colorpointer,
        uint256 tokenid,
        string memory rtimestamp
    ) public {
        require(
            msg.sender == verificationcontract,
            "minting can only be called from verification contract"
        );
        require(
            verificationcontract != address(0),
            "no verification contract set"
        );
        tokendata[tokenid].moisture = value1;
        tokendata[tokenid].temperature = value2;
        tokendata[tokenid].colorandlocation = colorpointer;
        tokendata[tokenid].rtimestamp = rtimestamp;
        _mint(tx.origin, tokenid);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;
import "./generativesvg.sol";

contract Metadata is GenerativeSvg {
    function generatemetadata(
        uint256 id,
        uint256 moisture,
        uint256 temperature,
        uint256 locationcolor,
        string memory rtimestamp
    ) public view returns (string memory) {
        string memory name = generatename(id);
        string memory description = "Seed Capital - Certificates of Growth";
        string memory attributes = generateattributes(
            cschemes[locationcolor].venue,
            cschemes[locationcolor].curator
        );
        string memory image = getsvgbase64(
            moisture,
            temperature,
            locationcolor,
            rtimestamp,
            id
        );
        return
            string(
                abi.encodePacked(
                    "data:text/plain,"
                    '{"name":"',
                    name,
                    '", "description":"',
                    description,
                    '", "image": "',
                    image,
                    '",',
                    '"attributes": ',
                    attributes,
                    "}"
                )
            );
    }

    function generatename(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "Certificate of Growth ",
                    Strings.toString(tokenId)
                )
            );
    }

    function generateattributes(
        string memory venue,
        string memory curator
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    '{"trait_type":"Venue",',
                    '"value":"',
                    venue,
                    '"},',
                    '{"trait_type":"Curator",',
                    '"value":"',
                    curator,
                    '"}'
                    "]"
                )
            );
    }
}

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

//mapfunction example moisture: 411,300,1000,3600,5600   mapfactor: 1000
// moisture: 1013, temperature: 20.125,

contract GenerativeSvg {
    using Strings for string;

    string internal header =
        "<?xml version='1.0' encoding='UTF-8'?><svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' x='0px' y='0px' width='480px' height='740px' viewBox='0 0 480 740' enable-background='new 0 0 480 740' xml:space='preserve'>";
    string internal background =
        "<rect y='140' fill='#141414' width='480' height='500'/>";

    uint256 mapfactor;
    mapping(uint256 => colorscheme) cschemes;

    struct colorscheme {
        string firsthex;
        string secondhex;
        string venue;
        string plant;
        string curator;
    }

    constructor() {
        cschemes[0].firsthex = "#f63f3c";
        cschemes[0].secondhex = "#13b9bc";
        cschemes[0].venue = "Art Dubai";
        cschemes[0].plant = "Dypsis lutescens";
        cschemes[0].curator = "Fingerprints DAO";

        cschemes[1].firsthex = "#ffea00";
        cschemes[1].secondhex = "#481249";

        cschemes[2].firsthex = "#167d5e";
        cschemes[2].secondhex = "#5e67b0";

        mapfactor = 100;
    }

    function mapvalue(
        uint256 value,
        uint256 leftMin,
        uint256 leftMax,
        uint256 rightMin,
        uint256 rightMax
    ) public view returns (uint256) {
        uint256 leftSpan = leftMax - leftMin;
        uint256 rightSpan = rightMax - rightMin;
        uint256 s = (value - leftMin) * mapfactor;
        uint256 valueScaled = s / uint256(leftSpan);
        return rightMin + (valueScaled * rightSpan) / mapfactor;
    }

    function _generatecolorprofile(
        uint256 profile,
        string memory firsthex,
        string memory secondhex,
        string memory venue,
        string memory plant,
        string memory curator
    ) internal {
        cschemes[profile].firsthex = firsthex;
        cschemes[profile].secondhex = secondhex;
        cschemes[profile].venue = venue;
        cschemes[profile].plant = plant;
        cschemes[profile].curator = curator;
    }

    function buildhsl(uint256 temp, uint256 moisture)
        internal
        view
        returns (string memory)
    {
        string memory h = Strings.toString(
            mapvalue(moisture, 70000, 80000, 0, 360)
        );
        string memory l = Strings.toString(
            mapvalue(temp, 19000, 23000, 50, 100)
        );
        return string(abi.encodePacked("hsl(", h, ",100%,", l, "%)"));
        //= 'hsl(0, 100%, 50%)';
    }

    function gradienty(uint256 temp) internal view returns (string memory) {
        return Strings.toString(mapvalue(temp, 19000, 23000, 300, 1000));
    }

    function gradientx(uint256 moisture) internal view returns (string memory) {
        return Strings.toString(mapvalue(moisture, 70000, 80000, 50, 700));
    }

    function gradientz(uint256 moisture) internal view returns (string memory) {
        return Strings.toString(mapvalue(moisture, 70000, 80000, 100, 500));
    }

    function lineargradienty(uint256 temp, uint256 locationcolor)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_1_' gradientUnits='userSpaceOnUse' x1='180.0005' y1='",
                    gradienty(temp),
                    "' x2='180.0005' y2='160.0005'> <stop  offset='0' style='stop-color:",
                    cschemes[locationcolor].secondhex,
                    ";stop-opacity:0'/><stop  offset='0.5' style='stop-color:",
                    cschemes[locationcolor].secondhex,
                    "'/> <stop  offset='1' style='stop-color:",
                    cschemes[locationcolor].secondhex,
                    ";stop-opacity:0'/></linearGradient> <rect y='160' fill='url(#SVGID_1_)' width='360' height='480'/>"
                )
            );
    }

    function lineargradientx(uint256 moisture, uint256 locationcolor)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_2_' gradientUnits='userSpaceOnUse' x1='0' y1='400' x2='",
                    gradientx(moisture),
                    "' y2='400'><stop  offset='0' style='stop-color:",
                    cschemes[locationcolor].firsthex,
                    ";stop-opacity:0'/><stop  offset='0.5' style='stop-color:",
                    cschemes[locationcolor].firsthex,
                    "'/> <stop  offset='1' style='stop-color:",
                    cschemes[locationcolor].firsthex,
                    ";stop-opacity:0'/></linearGradient> <rect y='160' fill='url(#SVGID_2_)' width='360' height='480'/>"
                )
            );
    }

    function lineargradientz(uint256 temp, uint256 moisture)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_3_' gradientUnits='userSpaceOnUse' x1='220.0225' y1='329.4453' x2='",
                    gradientz(moisture),
                    "' y2='219.445' gradientTransform='matrix(3.6 0 0 3.6 -684.0762 -606)'> <stop  offset='0' style='stop-color:",
                    buildhsl(temp, moisture),
                    ";stop-opacity:0'/> <stop  offset='1' style='stop-color:",
                    buildhsl(temp, moisture),
                    "'/> </linearGradient> <rect y='220' fill='url(#SVGID_3_)' width='360.001' height='360'/>"
                )
            );
    }

    function returnfixtext() internal pure returns (string memory) {
        return
            "<text transform='matrix(1 0 0 1 10 185.2061)' font-family='Arial' font-size='16'>Soil Moisture (x-axis)</text><text transform='matrix(1 0 0 1 10 141.4561)' font-family='Arial' font-size='16'>Time</text><text transform='matrix(1 0 0 1 10 605.2061)' font-family='Arial' font-size='16'>Plant</text><text transform='matrix(1 0 0 1 10 651.4561)' font-family='Arial' font-size='16'>Location</text><text transform='matrix(1 0 0 1 250 185.2061)' font-family='Arial' font-size='16'>Temperature (y-axis)</text><text transform='matrix(1 0 0 1 427.0029 241.4556)' fill='#EBEBEB' font-family='Arial' font-size='16'>terra0</text><text transform='matrix(1 0 0 1 9 80.7349)' fill='#141414' font-family='Times-Roman, Times' font-size='45'>Certificate of Growth </text>";
    }

    function buildpercentage(uint256 percentage)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    Strings.toString((percentage % 100000) / 1000),
                    ",",
                    Strings.toString((percentage % 1000) / 10)
                )
            );
    }



    function xypoint(uint256 moisture, uint256 temperature)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 ",
                    Strings.toString(mapvalue(moisture, 70000, 80000, 0, 335)),
                    " ",
                    Strings.toString(
                        580 -
                            (mapvalue(temperature, 19000, 23000, 245, 580) -
                                245)
                    ),
                    ")' fill='#EBEBEB' font-family='Courier, monospace' font-size='40'>+</text>"
                )
            );
    }

    function buildmoisture(uint256 moisture)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 9 205.3359)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    buildpercentage(moisture),
                    "%</text>"
                )
            );
    }

    function buildtemperature(uint256 temperature)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 249 205.3364)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    buildpercentage(temperature),
                    "C</text>"
                )
            );
    }

    function buildlocation(uint256 colorpointer)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 10 671.5859)'><tspan x='0' y='0' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    cschemes[colorpointer].venue,
                    "</tspan><tspan x='0' y='20' fill='#141414' font-family='Courier' font-size='24'>",
                    cschemes[colorpointer].curator,
                    "</tspan></text>"
                )
            );
    }

    function buildtokennumber(uint256 tokenid)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 412.3906 80)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    Strings.toString(tokenid),
                    "</text>"
                )
            );
    }

    function buildbars(uint256 moisture, uint256 temp)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text transform='matrix(1 0 0 1 360 ",
                    Strings.toString(
                        650 - mapvalue(moisture, 70000, 80000, 250, 390)
                    ),
                    ")' fill='#EBEBEB' font-family='Courier, monospace' font-size='49'>_</text>",
                    "<text transform='matrix(1 0 0 1 390 ",
                    Strings.toString(
                        650 - mapvalue(temp, 19000, 23000, 250, 390)
                    ),
                    ")' fill='#EBEBEB' font-family='Courier, monospace' font-size='49'>_</text>"
                )
            );
    }

    function returndynamictext(
        uint256 moisture,
        uint256 temp,
        uint256 locationcolor,
        string memory humantimestamp,
        uint256 tokenid
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    buildtemperature(temp),
                    buildmoisture(moisture),
                    buildlocation(locationcolor),
                    "<text transform='matrix(1 0 0 1 10 625.3359)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    cschemes[locationcolor].plant,
                    "</text>",
                    buildtokennumber(tokenid),
                    "<text transform='matrix(1 0 0 1 10 161.5859)' fill='#141414' font-family='Courier, monospace' font-size='24'>",
                    humantimestamp,
                    "</text>"
                )
            );
    }

    function generatebars() internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<linearGradient id='SVGID_4_' gradientUnits='userSpaceOnUse' x1='405' y1='580' x2='405' y2='220.1191'> <stop  offset='0' style='stop-color:#00FF00'/> <stop  offset='1' style='stop-color:#C2000B'/> </linearGradient> <rect x='390' y='220.119' fill='url(#SVGID_4_)' width='30' height='359.881'/><linearGradient id='SVGID_5_' gradientUnits='userSpaceOnUse' x1='375' y1='580' x2='375' y2='220.1191'> <stop  offset='0' style='stop-color:#141414'/> <stop  offset='1' style='stop-color:#00A0C6'/> </linearGradient>",
                    "<path opacity='0.25' fill='none' stroke='#EBEBEB' stroke-width='2' stroke-miterlimit='10' d='M300,220v360 M240,220v360 M180,220 v360 M120,220v360 M60,220v360 M360,520H0 M360,460H0 M360,400H0 M360,340H0 M360,280H0'/><rect x='360' y='260' opacity='0.25' fill='#EBEBEB' width='30' height='120'/><rect x='390' y='240' opacity='0.25' fill='#EBEBEB' width='30' height='160'/>",
                    "<rect x='360' y='220.119' fill='url(#SVGID_5_)' width='30' height='359.881'/>"
                )
            );
    }

    function generatesvg(
        uint256 moisture,
        uint256 temp,
        uint256 locationcolor,
        string memory humantimestamp,
        uint256 id
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    header,
                    background,
                    generatebars(),
                    lineargradienty(temp, locationcolor),
                    lineargradientx(moisture, locationcolor),
                    lineargradientz(temp, moisture),
                    "<path fill='#EBEBEB' d='M0,580v160h480V580H0z'/> <path fill='#EBEBEB' d='M0,0v220h480V0H0z'/>",
                    "<path opacity='0.25' fill='none' stroke='#EBEBEB' stroke-width='2' stroke-miterlimit='10' d='M300,220v360 M240,220v360 M180,220v360 M120,220v360 M60,220v360 M360,520H0 M360,460H0 M360,400H0 M360,340H0 M360,280H0'/>",
                    returnfixtext(),
                    returndynamictext(
                        moisture,
                        temp,
                        locationcolor,
                        humantimestamp,
                        id
                    ),
                    xypoint(moisture, temp),
                    buildbars(moisture, temp),
                    "</svg >"
                )
            );
    }

    function getsvgbase64(
        uint256 moisture,
        uint256 temperature,
        uint256 locationcolor,
        string memory humantimestamp,
        uint256 id
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        bytes(
                            generatesvg(
                                moisture,
                                temperature,
                                locationcolor,
                                humantimestamp,
                                id
                            )
                        )
                    )
                )
            );
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

pragma solidity >=0.6.0;

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
}