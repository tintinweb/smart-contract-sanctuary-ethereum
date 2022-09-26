// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IPublicSharedMetadata} from "@zoralabs/nft-editions-contracts/contracts/IPublicSharedMetadata.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IFaucet} from "../IFaucet.sol";
import "./external/PTMonoFont.sol";
import "./IFaucetMetadataRenderer.sol";
import './SVG.sol';
import {ColorLib} from './ColorLib.sol';

interface IZorbRenderer {
    function zorbForAddress(address user) external view returns (string memory);
}

contract FaucetMetadataRenderer is IFaucetMetadataRenderer {
    using Strings for uint256;
    IZorbRenderer private immutable zorbRenderer;
    PtMonoFont private immutable font;
    IPublicSharedMetadata private immutable sharedMetadata;

    /// @param _sharedMetadata Link to metadata renderer contract
    /// @param _zorbRenderer zorb project svg renderer
    /// @param _font link to the font style
    constructor(
        IPublicSharedMetadata _sharedMetadata,
        address _zorbRenderer,
        PtMonoFont _font
    ) {
        sharedMetadata = _sharedMetadata;
        zorbRenderer = IZorbRenderer(_zorbRenderer);
        font = _font;
    }

    function getPolylinePoints(address faucetAddress, uint256 _tokenId, IFaucet.FaucetDetails memory fd) internal view returns (bytes memory) {
        bytes memory points;
        uint256 stepFidelity = 100;
        uint256 rangeStep = (((fd.faucetExpiry - fd.faucetStart) * 100) / stepFidelity) / 100;

        for (uint256 i = 0; i <= stepFidelity; i++) {
            uint256 x = fd.faucetStart + (i*rangeStep);
            uint256 y = IFaucet(faucetAddress).claimableAmountForFaucet(_tokenId, x);
            uint256 normalizedY = y * 100 / fd.totalAmount;

            bytes memory point = abi.encodePacked(Strings.toString(i), ",-", Strings.toString(normalizedY));
            points = abi.encodePacked(points, point, " ");
        }

        return points;
    }

    function getLinearGradient(address faucetAddress) internal pure returns (bytes memory) {
        bytes[5] memory colors = ColorLib.gradientForAddress(faucetAddress);
        return abi.encodePacked(
            '<linearGradient id="gradient" x1="0%" y1="0%" x2="0%" y2="100%">',
            '<stop offset="15.62%" stop-color="',
            colors[0],
            '" /><stop offset="39.58%" stop-color="',
            colors[1],
            '" /><stop offset="72.92%" stop-color="',
            colors[2],
            '" /><stop offset="90.63%" stop-color="',
            colors[3],
            '" /><stop offset="100%" stop-color="',
            colors[4],
            '" /></linearGradient>'
        );
    }

    function getRadialGradient(address faucetAddress) internal pure returns (bytes memory) {
        bytes[5] memory colors = ColorLib.gradientForAddress(faucetAddress);
        return abi.encodePacked(
            '<radialGradient id="gzr" gradientTransform="translate(66.4578 24.3575) scale(75.2908)" gradientUnits="userSpaceOnUse" r="1" cx="0" cy="0%">'
                // '<radialGradient fx="66.46%" fy="24.36%" id="grad">'
                '<stop offset="15.62%" stop-color="',
                colors[0],
                '" /><stop offset="39.58%" stop-color="',
                colors[1],
                '" /><stop offset="72.92%" stop-color="',
                colors[2],
                '" /><stop offset="90.63%" stop-color="',
                colors[3],
                '" /><stop offset="100%" stop-color="',
                colors[4],
                '" /></radialGradient>'
        );
    }

    function renderSVG(address _faucetAddress, uint256 _tokenId, IFaucet.FaucetDetails memory _fd) public view returns (bytes memory) {
        string memory header = string(abi.encodePacked(
            '<svg width="500" height="900" viewBox="0 0 500 900" fill="none" xmlns="http://www.w3.org/2000/svg"><defs><style>'
            "svg {background:#000; margin: 0 auto;} @font-face { font-family: CourierFont; src: url('",
            font.font(),
            "') format('opentype');} text { font-family: CourierFont; fill: white; white-space: pre; letter-spacing: 0.05em; font-size: 10px; } text.eyebrow { fill-opacity: 0.4; }"
            '</style>',
            getLinearGradient(_faucetAddress),
            getRadialGradient(_faucetAddress),
            '</defs>'
            '<rect x="39" y="41" width="422" height="65" rx="1" fill="black" />'
            '<rect x="39.5" y="41.5" width="421" height="64" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<rect x="39" y="105" width="422" height="35" rx="1" fill="black" />'
            '<rect x="39.5" y="105.5" width="421" height="34" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<path transform="translate(57, 57)" fill-rule="evenodd" clip-rule="evenodd" d="M2.07683 0V6.21526H28.2708L5.44618 14.2935C3.98665 14.8571 2.82212 15.6869 1.96814 16.7828C1.11416 17.8787 0.539658 19.0842 0.244645 20.3836C-0.0503676 21.6986 -0.0814215 23.0294 0.16701 24.3914C0.415442 25.7534 0.896778 26.9902 1.64207 28.1174C2.37184 29.229 3.36557 30.1526 4.5922 30.8571C5.83436 31.5616 7.29389 31.9217 8.98633 31.9217H50.8626L50.8703 31.8988C51.1535 31.914 51.4386 31.9217 51.7255 31.9217C60.4671 31.9217 67.5474 24.7828 67.5474 15.9687C67.5474 12.3143 66.333 8.94525 64.2882 6.25304L89.4471 6.2935C90.5651 6.2935 91.388 6.60661 91.9159 7.23284C92.4594 7.85906 92.7078 8.54791 92.6767 9.29937C92.6457 10.0508 92.3351 10.7397 91.7606 11.3659C91.1706 11.9921 90.3322 12.3052 89.2142 12.3052L67.7534 12.3563V12.7123L98.8254 31.9742V31.9061H105.036L104.912 9.04895C104.912 8.45404 105.036 7.93741 105.285 7.46774C105.533 7.01373 105.875 6.65365 106.309 6.43447C106.744 6.21529 107.257 6.13701 107.816 6.19964C108.375 6.26226 108.98 6.5284 109.617 6.98241L143.947 32V24.3444L113.467 2.12919C111.992 1.0333 110.377 0.391416 108.67 0.172238C106.962 -0.0469397 105.362 0.125272 103.887 0.673217C102.412 1.22116 101.186 2.12919 100.223 3.41294C99.2447 4.6967 98.7633 6.29357 98.7633 8.2192V24.7626L87.2423 18.1135L90.0682 18.0665C92.0091 18.0508 93.6084 17.5812 94.8971 16.6888C96.1858 15.7808 97.133 14.6692 97.7385 13.3385C98.3441 11.9921 98.608 10.5518 98.5459 8.98626C98.4838 7.43636 98.0801 5.98039 97.3193 4.66532C96.5585 3.35025 95.4716 2.23871 94.0431 1.36199C92.6146 0.485282 90.829 0.0469261 88.6863 0.0469261H59.4304L52.8915 0.041576C52.5116 0.0140175 52.1279 0 51.741 0C51.3629 0 50.9878 0.0133864 50.6163 0.0397145L2.07683 0ZM37.7103 8.5589L7.86839 20.227C7.23178 20.4932 6.79703 20.9315 6.56412 21.5264C6.33122 22.1213 6.28464 22.7319 6.43991 23.3425C6.59518 23.953 6.93677 24.501 7.43364 24.9706C7.9305 25.4403 8.59816 25.6751 9.42109 25.6751L39.1905 25.7073C37.1293 23.0135 35.9035 19.6361 35.9035 15.9687C35.9035 13.2949 36.5565 10.7739 37.7103 8.5589ZM61.3522 15.9687C61.3522 10.6145 57.0357 6.26223 51.741 6.26223C46.4308 6.26223 42.1143 10.6145 42.1298 15.9687C42.1298 21.3072 46.4308 25.6595 51.741 25.6595C57.0357 25.6595 61.3522 21.3229 61.3522 15.9687Z" fill="white" />'
            '<g transform="translate(393,50.25) scale(0.45 0.45)"><path d="M100 50C100 22.3858 77.6142 0 50 0C22.3858 0 0 22.3858 0 50C0 77.6142 22.3858 100 50 100C77.6142 100 100 77.6142 100 50Z" fill="url(#gzr)" /><path stroke="rgba(0,0,0,0.075)" fill="transparent" stroke-width="1" d="M50,0.5c27.3,0,49.5,22.2,49.5,49.5S77.3,99.5,50,99.5S0.5,77.3,0.5,50S22.7,0.5,50,0.5z" /></g>' // ZORB
            '<text><tspan x="57" y="125.076">',
            IERC721Metadata(_faucetAddress).name(),
            '</tspan></text>'
        ));
        string memory graph = string(abi.encodePacked(
            '<polyline fill="none" stroke="url(#gradient)" stroke-width="1" transform="translate(50,600) scale(4 4)" stroke-linejoin="round" points="',
            getPolylinePoints(_faucetAddress, _tokenId, _fd),
            '"/>'
        ));
        string memory footer = string(abi.encodePacked(
            // Supplier
            '<rect x="38" y="683" width="422" height="44" rx="1" fill="black" />'
            '<rect x="38.5" y="683.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<text class="eyebrow"><tspan x="53" y="708.076">Supplier</tspan></text>'
            '<text text-anchor="end"><tspan x="427" y="708.076">',
            addressToString(_fd.supplier),
            '</tspan></text>'

            // Unclaimed Funds
            '<rect x="38" y="726" width="422" height="44" rx="1" fill="black" />'
            '<rect x="38.5" y="726.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<text class="eyebrow"><tspan x="53" y="752.977">Unclaimed Funds</tspan></text>'
            '<text text-anchor="end"><tspan x="427" y="752.977">',
            parsedAmountString(_fd.totalAmount - _fd.claimedAmount, IFaucet(_faucetAddress).faucetTokenAddress()),
            '</tspan></text>'

            // Fully Vested By
            '<rect x="38" y="769" width="422" height="44" rx="1" fill="black" />'
            '<rect x="38.5" y="769.5" width="421" height="43" rx="0.5" stroke="white" stroke-opacity="0.08" />'
            '<text class="eyebrow"><tspan x="53" y="795.977">Fully Vested By</tspan></text>'
            '<text text-anchor="end"><tspan x="427" y="795.977">',
            timestampToDateTime(_fd.faucetExpiry),
            '</tspan></text>'
            '</svg>'
        ));
        return abi.encodePacked(header, graph, footer);
    }

    function attributeFragment(string memory key, string memory value, bool includeComma) private pure returns (string memory) {
        return string(abi.encodePacked('{"trait_type": "', key, '", "value": "', value, includeComma ? '"},' : '"}'));
    }

    function getTokenURIForFaucet(address _faucetAddress, uint256 _tokenId, IFaucet.FaucetDetails memory _fd) external view returns (string memory) {
        string memory faucetName = IERC721Metadata(_faucetAddress).name();

        return
        // TODO: attributes
        sharedMetadata.encodeMetadataJSON(
            abi.encodePacked(
                '{"name": "',
                faucetName,
                '", "description": "ZORA Faucets are ERC-721 tokens representing ETH or ERC-20 tokens on a vesting strategy", ',
                '"image": "data:image/svg+xml;base64,',
                sharedMetadata.base64Encode(renderSVG(_faucetAddress, _tokenId, _fd)),
                '","attributes": [',
                attributeFragment('Total Amount', _fd.totalAmount.toString(), true),
                attributeFragment('Rescindable', _fd.canBeRescinded ? 'true' : 'false', true),
                attributeFragment('Faucet Strategy', addressToString(_fd.faucetStrategy), true),
                attributeFragment('Faucet Token', addressToString(IFaucet(_faucetAddress).faucetTokenAddress()), true),
                attributeFragment('Supplier', addressToString(_fd.supplier), false),
                ']'
                '}'
            )
        );
    }

    function addressToString(address _addr) private pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(_addr)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(abi.encodePacked('0x', string(s)));
    }

    function char(bytes1 b) private pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function parsedAmountString(uint256 _rawAmt, address _tokenAddress) private view returns (string memory) {
        uint8 decimals = 18;
        string memory symbol = 'ETH';
        if(_tokenAddress != address(0)) {
            IERC20Metadata token = IERC20Metadata(_tokenAddress);
            try token.decimals() returns (uint8 _decimals) {
                decimals = _decimals;
            } catch {
                decimals = 18;
            }
            try token.symbol() returns (string memory _symbol) {
                symbol = _symbol;
            } catch {
                symbol = 'Units';
            }
        }

        uint256 factor = 10**2;
        uint256 quotient = _rawAmt / 10**decimals;
        uint256 remainder = (_rawAmt * factor / 10**decimals) % factor;
        
        return string(abi.encodePacked(quotient.toString(), '.', remainder.toString(), ' ', symbol));
    }

    function timestampToDateTime(uint256 timestamp) private pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / (24*60*60));
        uint256 secs = timestamp % (24*60*60);
        uint256 hour = secs / (60*60);
        secs = secs % (60*60);
        uint256 minute = secs / 60;
        uint256 second = secs % 60;

        return string(abi.encodePacked(
            year.toString(),
            '/',
            month.toString(),
            '/',
            day.toString(),
            ' ',
            hour.toString(),
            ':',
            minute.toString(),
            ':',
            second.toString(),
            ' UTC'
        ));
    }

    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        int __days = int(_days);

        int L = __days + 68569 + 2440588;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

/// Shared public library for on-chain NFT functions
interface IPublicSharedMetadata {
    /// @param unencoded bytes to base64-encode
    function base64Encode(bytes memory unencoded)
        external
        pure
        returns (string memory);

    /// Encodes the argument json bytes into base64-data uri format
    /// @param json Raw json to base64 and turn into a data-uri
    function encodeMetadataJSON(bytes memory json)
        external
        pure
        returns (string memory);

    /// Proxy to openzeppelin's toString function
    /// @param value number to return as a string
    function numberToString(uint256 value)
        external
        pure
        returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity 0.8.12;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IFaucet is IERC721Upgradeable {
    struct FaucetDetails {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 faucetStart;
        uint256 faucetExpiry;
        address faucetStrategy;
        address supplier;
        bool canBeRescinded;
    }

    /// @notice Cannot have more claimable than total faucet amount
    /// @param totalClaimableAmount Total amount that can be claimed
    /// @param totalAmount Total amount that is in the faucet
    error ClaimableOverflow(uint256 totalClaimableAmount, uint256 totalAmount);

    /// @notice Cannot mint with ETH value from ERC20 Faucet
    /// @param value msg.value
    error UnexpectedMsgValue(uint256 value);

    /// @notice msg.value and _amt must match
    /// @param value The provided msg.value
    /// @param amt The provided amot
    error MintValueMismatch(uint256 value, uint256 amt);

    /// @notice Cannot mint a faucet with no value
    error MintNoValue();

    /// @notice Cannot mint a faucet with no duration
    error MintNoDuration();

    /// @notice Provided strategy must support IFaucetStrategy interface
    /// @param strategy provided invalid strategy
    error MintInvalidStrategy(address strategy);

    /// @notice Only owner of token
    /// @param caller method caller
    /// @param owner current owner
    error OnlyOwner(address caller, address owner);

    /// @notice Only supplier of token
    /// @param caller method caller
    /// @param supplier current supplier
    error OnlySupplier(address caller, address supplier);

    /// @notice Faucet is not rescindable
    error RescindUnrescindable();

    /// @notice Faucet does not exist
    error FaucetDoesNotExist();

    /// @notice Create a new Faucet
    /// @param _to The address that can claim funds from the faucet
    /// @param _amt The total amount of tokens claimable in this faucet
    /// @param _faucetDuration The duration over which the faucet will vest
    /// @param _faucetStrategy The strategy to use for the faucet
    /// @param _canBeRescinded Whether or not the faucet can be canceled by the supplier
    /// @return The newly created faucet's token ID
    function mint(
        address _to,
        uint256 _amt,
        uint256 _faucetDuration,
        address _faucetStrategy,
        bool _canBeRescinded
    ) external payable returns (uint256);

    /// @notice Claim any available funds for a faucet
    /// @param _to Where to send the funds
    /// @param _tokenID Which faucet is being claimed
    function claim(address _to, uint256 _tokenID) external;

    /// @notice Rescind a faucet, sweeping any unclaimed funds and discarding the faucet information
    /// @param _remainingTokenDest The destination for any unclaimed funds
    /// @param _tokenID The faucet token ID
    function rescind(address _remainingTokenDest, uint256 _tokenID) external;

    /// @notice Get the total claimable amount of tokens for a given faucet at a given timestamp
    /// @param _tokenID The token ID of the faucet
    /// @param _timestamp The timestamp of the faucet
    /// @return The total claimable amount
    function claimableAmountForFaucet(uint256 _tokenID, uint256 _timestamp) external view returns (uint256);

    /// @param _tokenID The token ID for the faucet
    function getFaucetDetailsForToken(uint256 _tokenID) external view returns (FaucetDetails memory);

    /// @notice The underlying token address for this faucet
    function faucetTokenAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @notice PtMonoFont deployed for corruptions
contract PtMonoFont {
    // based off the very excellent PT Mono font

    /*
    Copyright (c) 2011, ParaType Ltd. (http://www.paratype.com/public),
    with Reserved Font Names "PT Sans", "PT Serif", "PT Mono" and "ParaType".
    This Font Software is licensed under the SIL Open Font License, Version 1.1.
    This license is copied below, and is also available with a FAQ at:
    http://scripts.sil.org/OFL
    -----------------------------------------------------------
    SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
    -----------------------------------------------------------
    PREAMBLE
    The goals of the Open Font License (OFL) are to stimulate worldwide
    development of collaborative font projects, to support the font creation
    efforts of academic and linguistic communities, and to provide a free and
    open framework in which fonts may be shared and improved in partnership
    with others.
    The OFL allows the licensed fonts to be used, studied, modified and
    redistributed freely as long as they are not sold by themselves. The
    fonts, including any derivative works, can be bundled, embedded,
    redistributed and/or sold with any software provided that any reserved
    names are not used by derivative works. The fonts and derivatives,
    however, cannot be released under any other type of license. The
    requirement for fonts to remain under this license does not apply
    to any document created using the fonts or their derivatives.
    DEFINITIONS
    "Font Software" refers to the set of files released by the Copyright
    Holder(s) under this license and clearly marked as such. This may
    include source files, build scripts and documentation.
    "Reserved Font Name" refers to any names specified as such after the
    copyright statement(s).
    "Original Version" refers to the collection of Font Software components as
    distributed by the Copyright Holder(s).
    "Modified Version" refers to any derivative made by adding to, deleting,
    or substituting -- in part or in whole -- any of the components of the
    Original Version, by changing formats or by porting the Font Software to a
    new environment.
    "Author" refers to any designer, engineer, programmer, technical
    writer or other person who contributed to the Font Software.
    PERMISSION & CONDITIONS
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of the Font Software, to use, study, copy, merge, embed, modify,
    redistribute, and sell modified and unmodified copies of the Font
    Software, subject to the following conditions:
    1) Neither the Font Software nor any of its individual components,
    in Original or Modified Versions, may be sold by itself.
    2) Original or Modified Versions of the Font Software may be bundled,
    redistributed and/or sold with any software, provided that each copy
    contains the above copyright notice and this license. These can be
    included either as stand-alone text files, human-readable headers or
    in the appropriate machine-readable metadata fields within text or
    binary files as long as those fields can be easily viewed by the user.
    3) No Modified Version of the Font Software may use the Reserved Font
    Name(s) unless explicit written permission is granted by the corresponding
    Copyright Holder. This restriction only applies to the primary font name as
    presented to the users.
    4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
    Software shall not be used to promote, endorse or advertise any
    Modified Version, except to acknowledge the contribution(s) of the
    Copyright Holder(s) and the Author(s) or with their explicit written
    permission.
    5) The Font Software, modified or unmodified, in part or in whole,
    must be distributed entirely under this license, and must not be
    distributed under any other license. The requirement for fonts to
    remain under this license does not apply to any document created
    using the Font Software.
    TERMINATION
    This license becomes null and void if any of the above conditions are
    not met.
    DISCLAIMER
    THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
    OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
    DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
    OTHER DEALINGS IN THE FONT SOFTWARE.
    */

    string public constant font = "data:font/otf;base64,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";
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IFaucet} from "../IFaucet.sol";

interface IFaucetMetadataRenderer {
    function getTokenURIForFaucet(
        address _faucetAddress,
        uint256 _tokenId,
        IFaucet.FaucetDetails memory _fd
    ) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import './Utils.sol';


// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('g', _props, _children);
    }

    function path(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('path', _props, _children);
    }

    function text(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('text', _props, _children);
    }

    function line(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('line', _props, _children);
    }

    function circle(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('circle', _props, _children);
    }

    function circle(string memory _props)
    internal
    pure
    returns (string memory)
    {
        return el('circle', _props);
    }

    function rect(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('rect', _props, _children);
    }

    function rect(string memory _props)
    internal
    pure
    returns (string memory)
    {
        return el('rect', _props);
    }

    function filter(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('filter', _props, _children);
    }

    function cdata(string memory _content)
    internal
    pure
    returns (string memory)
    {
        return string.concat('<![CDATA[', _content, ']]>');
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('radialGradient', _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
    {
        return el('linearGradient', _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
        el(
            'stop',
            string.concat(
                prop('stop-color', stopColor),
                ' ',
                prop('offset', string.concat(utils.uint2str(offset), '%')),
                ' ',
                _props
            )
        );
    }

    function animateTransform(string memory _props)
    internal
    pure
    returns (string memory)
    {
        return el('animateTransform', _props);
    }

    function image(string memory _href, string memory _props)
    internal
    pure
    returns (string memory)
    {
        return
        el(
            'image',
            string.concat(prop('href', _href), ' ', _props)
        );
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
        string.concat(
            '<',
            _tag,
            ' ',
            _props,
            '>',
            _children,
            '</',
            _tag,
            '>'
        );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(
        string memory _tag,
        string memory _props
    ) internal pure returns (string memory) {
        return
        string.concat(
            '<',
            _tag,
            ' ',
            _props,
            '/>'
        );
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
    internal
    pure
    returns (string memory)
    {
        return string.concat(_key, '=', '"', _val, '" ');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BBB#RROOOOOOOOOOOOOOORR#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@BBRRROOOOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZO#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@B#RRRRROOO[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@B#RRRRRROOOOOO[email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@B#RRRRRRRROOOOOOOO[email protected]@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@B#RRRRRRRROOOOOOOOOOO[email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@B###RRRRRRRROOOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ#@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@BB####RRRRRRRROOOOOOOOOOOOO[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@BB#####RRRRRRRROOOOOOOOOOOOOOZ[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@BB######RRRRRRRROOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZO#@@@@@@@@@@@@@@@
@@@@@@@@@@@@BBB######RRRRRRRROOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZO#@@@@@@@@@@@@@@
@@@@@@@@@@@BBBBB#####RRRRRRRROOOOOOOOOOOOOOOZZZ[email protected]@@@@@@@@@@@@
@@@@@@@@@@BBBBBB#####RRRRRRRROOOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZO#@@@@@@@@@@@@
@@@@@@@@@BBBBBBB#####RRRRRRRRROOOOOOOOOOOOOOZZZZZ[email protected]@@@@@@@@@@
@@@@@@@@BBBBBBBB######RRRRRRRROOOOOOOOOOOOOOOZZZZZ[email protected]@@@@@@@@@
@@@@@@@@BBBBBBBBB#####RRRRRRRRROOOOOOOOOOOOOOOZZZZ[email protected]@@@@@@@@@
@@@@@@@BBBBBBBBBB######RRRRRRRROOOOOOOOOOOOOOOOZZZZ[email protected]@@@@@@@@
@@@@@@@BBBBBBBBBBB#####RRRRRRRRROOOOOOOOOOOOOOOOZZZ[email protected]@@@@@@@@
@@@@@@@BBBBBBBBBBB######RRRRRRRRROOOOOOOOOOOOOOOOZZZ[email protected]@@@@@@@
@@@@@@BBBBBBBBBBBBB######RRRRRRRRROOOOOOOOOOOOOOOOZZ[email protected]@@@@@@@
@@@@@@BBBBBBBBBBBBBB######RRRRRRRRROOOOOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZOOOOOOOOOO#@@@@@@@@
@@@@@@BBBBBBBBBBBBBBB######RRRRRRRRROOOOOOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZOOOOOOOOOOOO#@@@@@@@@
@@@@@@BBBBBBBBBBBBBBB######RRRRRRRRRROOOOOOOOOOOOOOO[email protected]@@@@@@@
@@@@@@BBBBBBBBBBBBBBBB#######RRRRRRRRRROOOOOOOOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZOOOOOOOOOOOOOOOOO#@@@@@@@@
@@@@@@BBBBBBBBBBBBBBBBB#######RRRRRRRRRROOOOOOOOOOOOOOOOOOOOOOOZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZOOOOOOOOOOOOOOOOOOOO#@@@@@@@@
@@@@@@BBBBBBBBBBBBBBBBBBB######RRRRRRRRRRROOOOOOOOOO[email protected]@@@@@@@
@@@@@@BBBBBBBBBBBBBBBBBBBB#######RRRRRRRRRRROOOOOOOO[email protected]@@@@@@@
@@@@@@@BBBBBBBBBBBBBBBBBBBBB#######RRRRRRRRRRROOOOO[email protected]@@@@@@@@
@@@@@@@BBBBBBBBBBBBBBBBBBBBBB########RRRRRRRRRRRROO[email protected]@@@@@@@@
@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBB########RRRRRRRRRRRRROOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOORRRRRRR#@@@@@@@@@@
@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBB########RRRRRRRRR[email protected]@@@@@@@@@
@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBB########RRRRRR[email protected]@@@@@@@@@@
@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBB#########RRRRRRRRRRRRRRRRRRROOOOOOOOOOOOOOOOOOOOOOOOOORRRRRRRRRRRRRRRRRR##@@@@@@@@@@@@
@@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBBBB#########RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR###[email protected]@@@@@@@@@@@
@@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB###########RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR######[email protected]@@@@@@@@@@@@
@@@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#############RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR########[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB###############RRRRRRRRRRRRRRRRRRRRRRRRRRR#############[email protected]@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#################################################[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB#######################################[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB########################[email protected]@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@BBBBBBBBBBBBBBBBBBB[email protected]@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@BBBBBBBBBBBBBB[email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@BBBBBBBBBB[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@BBBBBB[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/


import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// Color lib is a custom library for handling the math functions required to generate the gradient step colors
/// Originally written in javascript, this is a solidity port.
library ColorLib {
    struct HSL {
        uint256 h;
        uint256 s;
        uint256 l;
    }

    /// Lookup table for cubicinout range 0-99
    function cubicInOut(uint16 p) internal pure returns (int256) {
        if (p < 13) {
            return 0;
        }
        if (p < 17) {
            return 1;
        }
        if (p < 19) {
            return 2;
        }
        if (p < 21) {
            return 3;
        }
        if (p < 23) {
            return 4;
        }
        if (p < 24) {
            return 5;
        }
        if (p < 25) {
            return 6;
        }
        if (p < 27) {
            return 7;
        }
        if (p < 28) {
            return 8;
        }
        if (p < 29) {
            return 9;
        }
        if (p < 30) {
            return 10;
        }
        if (p < 31) {
            return 11;
        }
        if (p < 32) {
            return 13;
        }
        if (p < 33) {
            return 14;
        }
        if (p < 34) {
            return 15;
        }
        if (p < 35) {
            return 17;
        }
        if (p < 36) {
            return 18;
        }
        if (p < 37) {
            return 20;
        }
        if (p < 38) {
            return 21;
        }
        if (p < 39) {
            return 23;
        }
        if (p < 40) {
            return 25;
        }
        if (p < 41) {
            return 27;
        }
        if (p < 42) {
            return 29;
        }
        if (p < 43) {
            return 31;
        }
        if (p < 44) {
            return 34;
        }
        if (p < 45) {
            return 36;
        }
        if (p < 46) {
            return 38;
        }
        if (p < 47) {
            return 41;
        }
        if (p < 48) {
            return 44;
        }
        if (p < 49) {
            return 47;
        }
        if (p < 50) {
            return 50;
        }
        if (p < 51) {
            return 52;
        }
        if (p < 52) {
            return 55;
        }
        if (p < 53) {
            return 58;
        }
        if (p < 54) {
            return 61;
        }
        if (p < 55) {
            return 63;
        }
        if (p < 56) {
            return 65;
        }
        if (p < 57) {
            return 68;
        }
        if (p < 58) {
            return 70;
        }
        if (p < 59) {
            return 72;
        }
        if (p < 60) {
            return 74;
        }
        if (p < 61) {
            return 76;
        }
        if (p < 62) {
            return 78;
        }
        if (p < 63) {
            return 79;
        }
        if (p < 64) {
            return 81;
        }
        if (p < 65) {
            return 82;
        }
        if (p < 66) {
            return 84;
        }
        if (p < 67) {
            return 85;
        }
        if (p < 68) {
            return 86;
        }
        if (p < 69) {
            return 88;
        }
        if (p < 70) {
            return 89;
        }
        if (p < 71) {
            return 90;
        }
        if (p < 72) {
            return 91;
        }
        if (p < 74) {
            return 92;
        }
        if (p < 75) {
            return 93;
        }
        if (p < 76) {
            return 94;
        }
        if (p < 78) {
            return 95;
        }
        if (p < 80) {
            return 96;
        }
        if (p < 82) {
            return 97;
        }
        if (p < 86) {
            return 98;
        }
        return 99;
    }

    /// Lookup table for cubicid range 0-99
    function cubicIn(uint256 p) internal pure returns (uint8) {
        if (p < 22) {
            return 0;
        }
        if (p < 28) {
            return 1;
        }
        if (p < 32) {
            return 2;
        }
        if (p < 32) {
            return 3;
        }
        if (p < 34) {
            return 3;
        }
        if (p < 36) {
            return 4;
        }
        if (p < 39) {
            return 5;
        }
        if (p < 41) {
            return 6;
        }
        if (p < 43) {
            return 7;
        }
        if (p < 46) {
            return 9;
        }
        if (p < 47) {
            return 10;
        }
        if (p < 49) {
            return 11;
        }
        if (p < 50) {
            return 12;
        }
        if (p < 51) {
            return 13;
        }
        if (p < 53) {
            return 14;
        }
        if (p < 54) {
            return 15;
        }
        if (p < 55) {
            return 16;
        }
        if (p < 56) {
            return 17;
        }
        if (p < 57) {
            return 18;
        }
        if (p < 58) {
            return 19;
        }
        if (p < 59) {
            return 20;
        }
        if (p < 60) {
            return 21;
        }
        if (p < 61) {
            return 22;
        }
        if (p < 62) {
            return 23;
        }
        if (p < 63) {
            return 25;
        }
        if (p < 64) {
            return 26;
        }
        if (p < 65) {
            return 27;
        }
        if (p < 66) {
            return 28;
        }
        if (p < 67) {
            return 30;
        }
        if (p < 68) {
            return 31;
        }
        if (p < 69) {
            return 32;
        }
        if (p < 70) {
            return 34;
        }
        if (p < 71) {
            return 35;
        }
        if (p < 72) {
            return 37;
        }
        if (p < 73) {
            return 38;
        }
        if (p < 74) {
            return 40;
        }
        if (p < 75) {
            return 42;
        }
        if (p < 76) {
            return 43;
        }
        if (p < 77) {
            return 45;
        }
        if (p < 78) {
            return 47;
        }
        if (p < 79) {
            return 49;
        }
        if (p < 80) {
            return 51;
        }
        if (p < 81) {
            return 53;
        }
        if (p < 82) {
            return 55;
        }
        if (p < 83) {
            return 57;
        }
        if (p < 84) {
            return 59;
        }
        if (p < 85) {
            return 61;
        }
        if (p < 86) {
            return 63;
        }
        if (p < 87) {
            return 65;
        }
        if (p < 88) {
            return 68;
        }
        if (p < 89) {
            return 70;
        }
        if (p < 90) {
            return 72;
        }
        if (p < 91) {
            return 75;
        }
        if (p < 92) {
            return 77;
        }
        if (p < 93) {
            return 80;
        }
        if (p < 94) {
            return 83;
        }
        if (p < 95) {
            return 85;
        }
        if (p < 96) {
            return 88;
        }
        if (p < 97) {
            return 91;
        }
        if (p < 98) {
            return 94;
        }
        return 97;
    }

    /// Lookup table for quintin range 0-99
    function quintIn(uint256 p) internal pure returns (uint8) {
        if (p < 39) {
            return 0;
        }
        if (p < 45) {
            return 1;
        }
        if (p < 49) {
            return 2;
        }
        if (p < 52) {
            return 3;
        }
        if (p < 53) {
            return 4;
        }
        if (p < 54) {
            return 4;
        }
        if (p < 55) {
            return 5;
        }
        if (p < 56) {
            return 5;
        }
        if (p < 57) {
            return 6;
        }
        if (p < 58) {
            return 6;
        }
        if (p < 59) {
            return 7;
        }
        if (p < 60) {
            return 7;
        }
        if (p < 61) {
            return 8;
        }
        if (p < 62) {
            return 9;
        }
        if (p < 63) {
            return 9;
        }
        if (p < 64) {
            return 10;
        }
        if (p < 65) {
            return 11;
        }
        if (p < 66) {
            return 12;
        }
        if (p < 67) {
            return 13;
        }
        if (p < 68) {
            return 14;
        }
        if (p < 69) {
            return 15;
        }
        if (p < 70) {
            return 16;
        }
        if (p < 71) {
            return 18;
        }
        if (p < 72) {
            return 19;
        }
        if (p < 73) {
            return 20;
        }
        if (p < 74) {
            return 22;
        }
        if (p < 75) {
            return 23;
        }
        if (p < 76) {
            return 25;
        }
        if (p < 77) {
            return 27;
        }
        if (p < 78) {
            return 28;
        }
        if (p < 79) {
            return 30;
        }
        if (p < 80) {
            return 32;
        }
        if (p < 81) {
            return 34;
        }
        if (p < 82) {
            return 37;
        }
        if (p < 83) {
            return 39;
        }
        if (p < 84) {
            return 41;
        }
        if (p < 85) {
            return 44;
        }
        if (p < 86) {
            return 47;
        }
        if (p < 87) {
            return 49;
        }
        if (p < 88) {
            return 52;
        }
        if (p < 89) {
            return 55;
        }
        if (p < 90) {
            return 59;
        }
        if (p < 91) {
            return 62;
        }
        if (p < 92) {
            return 65;
        }
        if (p < 93) {
            return 69;
        }
        if (p < 94) {
            return 73;
        }
        if (p < 95) {
            return 77;
        }
        if (p < 96) {
            return 81;
        }
        if (p < 97) {
            return 85;
        }
        if (p < 98) {
            return 90;
        }
        return 95;
    }

    // Util for keeping hue range in 0-360 positive
    function clampHue(int256 h) internal pure returns (uint256) {
    unchecked {
        h /= 100;
        if (h >= 0) {
            return uint256(h) % 360;
        } else {
            return (uint256(-1 * h) % 360);
        }
    }
    }

    /// find hue within range
    function lerpHue(
        uint8 optionNum,
        uint256 direction,
        uint256 uhue,
        uint8 pct
    ) internal pure returns (uint256) {
        // unchecked {
        uint256 option = optionNum % 4;
        int256 hue = int256(uhue);

        if (option == 0) {
            return
            clampHue(
                (((100 - int256(uint256(pct))) * hue) +
            (int256(uint256(pct)) *
            (direction == 0 ? hue - 10 : hue + 10)))
            );
        }
        if (option == 1) {
            return
            clampHue(
                (((100 - int256(uint256(pct))) * hue) +
            (int256(uint256(pct)) *
            (direction == 0 ? hue - 30 : hue + 30)))
            );
        }
        if (option == 2) {
            return
            clampHue(
                (
                (((100 - cubicInOut(pct)) * hue) +
                (cubicInOut(pct) *
                (direction == 0 ? hue - 50 : hue + 50)))
                )
            );
        }

        return
        clampHue(
            ((100 - cubicInOut(pct)) * hue) +
            (cubicInOut(pct) *
            int256(
                hue +
                ((direction == 0 ? int256(-60) : int256(60)) *
                int256(uint256(optionNum > 128 ? 1 : 0))) +
                30
            ))
        );
        // }
    }

    /// find lightness within range
    function lerpLightness(
        uint8 optionNum,
        uint256 start,
        uint256 end,
        uint256 pct
    ) internal pure returns (uint256) {
        uint256 lerpPercent;
        if (optionNum == 0) {
            lerpPercent = quintIn(pct);
        } else {
            lerpPercent = cubicIn(pct);
        }
        return
        1 + (((100.0 - lerpPercent) * start + (lerpPercent * end)) / 100);
    }

    /// find saturation within range
    function lerpSaturation(
        uint8 optionNum,
        uint256 start,
        uint256 end,
        uint256 pct
    ) internal pure returns (uint256) {
    unchecked {
        uint256 lerpPercent;
        if (optionNum == 0) {
            lerpPercent = quintIn(pct);
            return
            1 +
            (((100.0 - lerpPercent) * start + lerpPercent * end) / 100);
        }
        lerpPercent = pct;
        return ((100.0 - lerpPercent) * start + lerpPercent * end) / 100;
    }
    }

    /// encode a color string
    function encodeStr(
        uint256 h,
        uint256 s,
        uint256 l
    ) internal pure returns (bytes memory) {
        return
        abi.encodePacked(
            "hsl(",
            Strings.toString(h),
            ", ",
            Strings.toString(s),
            "%, ",
            Strings.toString(l),
            "%)"
        );
    }

    /// get gradient color strings for the given addresss
    function gradientForAddress(address addr)
    internal
    pure
    returns (bytes[5] memory)
    {
    unchecked {
        bytes32 addrBytes = bytes32(uint256(uint160(addr)));
        uint256 startHue = (uint256(uint8(addrBytes[31 - 12])) * 24) / 17; // 255 - 360
        uint256 startLightness = (uint256(uint8(addrBytes[31 - 2])) * 5) /
        34 +
        32; // 255 => 37.5 + 32 (32, 69.5)
        uint256 endLightness = 97;
        endLightness += (((uint256(uint8(addrBytes[31 - 8])) * 5) / 51) +
        72); // 72-97
        endLightness /= 2;

        uint256 startSaturation = uint256(uint8(addrBytes[31 - 7])) /
        16 +
        81; // 0-16 + 72

        uint256 endSaturation = uint256(uint8(addrBytes[31 - 10]) * 11) / 128 + 70; // 0-22 + 70
        if (endSaturation > startSaturation - 10) {
            endSaturation = startSaturation - 10;
        }

        return [
        // 0
        encodeStr(
            lerpHue(
                uint8(addrBytes[31 - 3]),
                uint8(addrBytes[31 - 6]) % 2,
                startHue,
                0
            ),
            lerpSaturation(
                uint8(addrBytes[31 - 3]) % 2,
                startSaturation,
                endSaturation,
                100
            ),
            lerpLightness(
                uint8(addrBytes[31 - 5]) % 2,
                startLightness,
                endLightness,
                100
            )
        ),
        // 1
        encodeStr(
            lerpHue(
                uint8(addrBytes[31 - 3]),
                uint8(addrBytes[31 - 6]) % 2,
                startHue,
                10
            ),
            lerpSaturation(
                uint8(addrBytes[31 - 3]) % 2,
                startSaturation,
                endSaturation,
                90
            ),
            lerpLightness(
                uint8(addrBytes[31 - 5]) % 2,
                startLightness,
                endLightness,
                90
            )
        ),
        // 2
        encodeStr(
            lerpHue(
                uint8(addrBytes[31 - 3]),
                uint8(addrBytes[31 - 6]) % 2,
                startHue,
                70
            ),
            lerpSaturation(
                uint8(addrBytes[31 - 3]) % 2,
                startSaturation,
                endSaturation,
                70
            ),
            lerpLightness(
                uint8(addrBytes[31 - 5]) % 2,
                startLightness,
                endLightness,
                70
            )
        ),
        // 3
        encodeStr(
            lerpHue(
                uint8(addrBytes[31 - 3]),
                uint8(addrBytes[31 - 6]) % 2,
                startHue,
                90
            ),
            lerpSaturation(
                uint8(addrBytes[31 - 3]) % 2,
                startSaturation,
                endSaturation,
                20
            ),
            lerpLightness(
                uint8(addrBytes[31 - 5]) % 2,
                startLightness,
                endLightness,
                20
            )
        ),
        // 4
        encodeStr(
            lerpHue(
                uint8(addrBytes[31 - 3]),
                uint8(addrBytes[31 - 6]) % 2,
                startHue,
                100
            ),
            lerpSaturation(
                uint8(addrBytes[31 - 3]) % 2,
                startSaturation,
                endSaturation,
                0
            ),
            startLightness
        )
        ];
    }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = '';

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
    internal
    pure
    returns (string memory)
    {
        return string.concat('--', _key, ':', _val, ';');
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
    internal
    pure
    returns (string memory)
    {
        return string.concat('var(--', _key, ')');
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
    internal
    pure
    returns (string memory)
    {
        return string.concat('url(#', _id, ')');
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
        ? string.concat('0.', utils.uint2str(_a))
        : '1';
        return
        string.concat(
            'rgba(',
            utils.uint2str(_r),
            ',',
            utils.uint2str(_g),
            ',',
            utils.uint2str(_b),
            ',',
            formattedA,
            ')'
        );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
    internal
    pure
    returns (bool)
    {
        return
        keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
    internal
    pure
    returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
            //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
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
interface IERC165Upgradeable {
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