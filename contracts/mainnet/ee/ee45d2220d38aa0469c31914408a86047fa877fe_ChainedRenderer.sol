// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Renderer} from "./Renderer.sol";
import {Base64} from "../../utils/Base64.sol";
import {Metadata} from "./Metadata.sol";
import {ENSNameResolver} from "../../utils/ENSNameResolver.sol";
import {DateTime, Date} from "../../utils/DateTime.sol";

/// @notice On-chain renderer designed for Nation3 Passport
/// @author Nation3 (https://github.com/nation3/app/blob/master/contracts/src/passport/ChainedRenderer.sol).
contract ChainedRenderer is Renderer {
    function render(
        uint256 tokenId,
        address owner,
        uint256 timestamp
    ) public view override returns (string memory) {
        string memory name = ENSNameResolver.lookupENSName(owner);

        if (bytes(name).length == 0) {
            // Shorten URL to 8 chars
            name = Strings.toHexString(uint32(uint160(owner) >> 128));
        }

        string memory imageData = encodedSVG(
            tokenId,
            name,
            timestamp
        );

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    Metadata.getMetadataJson(
                        tokenId,
                        owner,
                        timestamp,
                        imageData
                    )
                )
            )
        ));
    }

    function encodedSVG(uint256 tokenId, string memory name, uint256 timestamp) public pure virtual returns (string memory) {
        string memory svg = renderSVG(tokenId, name, timestamp);
        return Base64.encode(bytes(svg));
    }

    function renderSVG(uint256 id, string memory name, uint256 timestamp) public pure virtual returns (string memory) {
        Date memory ts = DateTime.timestampToDateTime(timestamp);

        return string(abi.encodePacked(
            '<svg width="585" height="671" viewBox="0 0 585 671" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="585" height="671" rx="10" fill="#fff" />',
            genArtBackground(),
            genPattern(),
            genOrbe(),
            genBrandStamp(),
            genGenesisBanner(),
            genDataLabels(id, name, ts),
            genDef(),
            '</svg>'
        ));
    }

    function genArtBackground() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<svg width="585" height="493" viewBox="0 0 585 493" fill="none" xmlns="http://www.w3.org/2000/svg">'
            // Shape
            '<rect opacity="0.09" y="243" width="585" height="250" fill="url(#back_gradient_0)"/>',
            // Gradient
            '<linearGradient id="back_gradient_0" x1="292.5" y1="243" x2="292.5" y2="493" gradientUnits="userSpaceOnUse"><stop stop-color="#6FD1F4" stop-opacity="0" /><stop offset="1" stop-color="#6FD1F4" /></linearGradient>',
            '</svg>'
        ));
    }

    function genDataLabels(uint256 id, string memory name, Date memory timestamp) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<svg x="24" y="511" width="537" height="130" viewBox="0 0 537 130" fill="none" xmlns="http://www.w3.org/2000/svg">',
            string(abi.encodePacked(
                '<text y="24" font-family="Open Sans, Helvetica" font-size="24" font-weight="lighter" font-variant="all-small-caps" fill="#7395B2" >Passport Holder</text>',
                '<text y="55" font-family="Open Sans, Helvetica" font-size="24" font-weight="bold" fill="#224059" >',
                name,
                '</text>'
            )),
            string(abi.encodePacked(
                '<text x="370" y="96" text-anchor="end" font-family="Open Sans, Helvetica" font-size="24" font-weight="lighter" font-variant="all-small-caps" fill="#7395B2" >Issue Date</text>',
                '<text x="370" y="126" text-anchor="end" font-family="Open Sans, Helvetica" font-size="23" fill="#224059" >',
                string(abi.encodePacked(Strings.toString(timestamp.day),'/',Strings.toString(timestamp.month),'/',Strings.toString(timestamp.year))),
                '</text>'
            )),
            string(abi.encodePacked(
                '<text x="537" y="96" text-anchor="end" font-family="Open Sans, Helvetica" font-size="24" font-weight="lighter" font-variant="all-small-caps" fill="#7395B2" >Number</text>',
                '<text x="537" y="126" text-anchor="end" font-family="Open Sans, Helvetica" font-size="23" fill="#224059" >',
                Strings.toString(id),
                '</text>'
            )),
            '</svg>'
        ));
    }

    function genOrbe() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<svg width="585" height="493" viewBox="0 0 585 493" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<circle cx="293" cy="247" r="90" fill="#FCFCFC" />',
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M396.516 246.758C396.516 304.062 350.062 350.516 292.758 350.516C235.454 350.516 189 304.062 189 246.758C189 189.454 235.454 143 292.758 143C350.062 143 396.516 189.454 396.516 246.758ZM292.757 331.494C277.539 267.164 228.773 248.199 206.292 246.758H292.757V331.494ZM379.223 246.758C356.742 245.317 307.976 226.352 292.758 162.022V246.758H379.223Z" fill="url(#nation_gradient)" />',
            '<defs>',
            '<linearGradient id="nation_gradient" x1="189" y1="143" x2="322.701" y2="103.11" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient>',
            '</defs>',
            '</svg>'
        ));
    }

    function genPattern() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<svg width="585" height="493" viewBox="0 0 585 493" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<mask id="mask0_546_6980" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="585" height="493"><rect width="585" height="493" fill="white" /></mask>',
            string(abi.encodePacked('<g mask="url(#mask0_546_6980)">', genPatternPath(), '</g>')),
            genPatternDefs(),
            '</svg>'
        ));
    }

    function genPatternPath() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<path opacity="0.4" d="M293.015 534.018L291.995 534.137C240.602 316.884 75.9366 252.886 0.109506 248.025L0.142578 246.992H292.498H293.015V247.509V534.018Z" stroke="url(#paint0_linear_546_6980)" stroke-width="1.03398" />',
            '<path opacity="0.4" d="M293.015 534.018L291.995 534.137C240.602 316.884 75.9366 252.886 0.109506 248.025L0.142578 246.992H292.498H293.015V247.509V534.018Z" stroke="url(#paint0_linear_546_6980)" stroke-width="1.03398" />',
            '<path opacity="0.4" d="M292.987 -40L294.007 -40.119C345.4 177.134 510.065 241.132 585.892 245.993L585.859 247.026H293.504H292.987V246.509V-40Z" stroke="url(#paint1_linear_546_6980)" stroke-width="1.03398" />',
            '<circle cx="293.873" cy="247.127" r="208.687" transform="rotate(45 293.873 247.127)" stroke="url(#paint2_linear_546_6980)" stroke-width="1.41433" />',
            '<path d="M181.4 359.601C222.11 400.311 271.548 424.622 318.591 430.995C365.635 437.368 410.327 425.801 441.437 394.691C472.547 363.581 484.114 318.889 477.741 271.845C471.368 224.802 447.057 175.364 406.347 134.654C365.637 93.9437 316.199 69.6322 269.156 63.2595C222.112 56.8868 177.42 68.4534 146.31 99.5635C115.2 130.674 103.633 175.366 110.006 222.41C116.378 269.453 140.69 318.891 181.4 359.601Z" stroke="url(#paint3_linear_546_6980)" stroke-width="1.41433" />',
            '<path d="M225.643 178.894C184.954 219.583 155.654 264.025 141.2 303.021C126.779 341.928 127.014 375.807 146.105 394.898C165.195 413.989 199.074 414.223 237.981 399.802C276.978 385.348 321.42 356.048 362.108 315.36C402.797 274.671 432.097 230.229 446.551 191.233C460.972 152.326 460.737 118.447 441.646 99.3561C422.556 80.2654 388.677 80.0307 349.77 94.4516C310.773 108.906 266.331 138.206 225.643 178.894Z" stroke="url(#paint4_linear_546_6980)" stroke-width="2" />',
            '<path d="M265.256 271.508C296.95 308.706 328.802 339.719 354.687 359.788C367.625 369.818 379.103 377.139 388.346 381.123C392.965 383.114 397.064 384.288 400.529 384.532C403.998 384.776 406.901 384.09 409.026 382.278C411.152 380.467 412.29 377.711 412.6 374.247C412.91 370.787 412.401 366.554 411.169 361.677C408.703 351.919 403.297 339.424 395.448 325.058C379.743 296.314 354.181 259.943 322.487 222.745C290.792 185.548 258.941 154.535 233.055 134.466C220.117 124.435 208.64 117.115 199.397 113.131C194.777 111.14 190.679 109.965 187.213 109.722C183.744 109.478 180.842 110.164 178.716 111.975C176.591 113.787 175.452 116.543 175.142 120.007C174.833 123.467 175.341 127.7 176.574 132.577C179.04 142.335 184.445 154.829 192.295 169.196C207.999 197.939 233.562 234.31 265.256 271.508Z" stroke="url(#paint5_linear_546_6980)" stroke-width="1.41433" />'
        ));
    }

    function genPatternDefs() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<defs>',
            '<linearGradient id="paint0_linear_546_6980" x1="0.142578" y1="534.018" x2="187.873" y2="591.171" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient>',
            '<linearGradient id="paint1_linear_546_6980" x1="585.859" y1="-40" x2="398.129" y2="-97.1532" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient>',
            '<linearGradient id="paint2_linear_546_6980" x1="85.8935" y1="39.1479" x2="353.893" y2="-40.811" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient>',
            '<linearGradient id="paint3_linear_546_6980" x1="258.783" y1="-11.9099" x2="507.79" y2="96.8892" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient>',
            '<linearGradient id="paint4_linear_546_6980" x1="508.465" y1="167.589" x2="457.646" y2="406.983" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient>',
            '<linearGradient id="paint5_linear_546_6980" x1="207.252" y1="88.5908" x2="348.795" y2="75.0223" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient>',
            '</defs>'
        ));
    }

    function genBrandStamp() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<svg x="24" y="589" width="147" height="59" viewBox="0 0 147 59" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<ellipse cx="29.1838" cy="29.5" rx="29.1838" ry="29.5" fill="#69C9FF" /><path d="M29.1831 53.5919C24.9029 35.3019 11.1864 29.91 4.86328 29.5003H29.1831V53.5919Z" fill="white" /><path d="M29.184 5.40857C33.4643 23.6986 47.1807 29.0905 53.5039 29.5002H29.184V5.40857Z" fill="white" />',
            '<text x="69" y="37" font-family="Open Sans, Helvetica" fill="#224059" font-size="20">Nation3</text>',
            '</svg>'
        ));
    }

    function genGenesisBanner() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<svg x="472" y="517" width="89" height="28" viewBox="0 0 89 28" fill="none" xmlns="http://www.w3.org/2000/svg">',
            '<rect width="89" height="28" rx="6" fill="url(#nation_gradient_banner)" />',
            '<path d="M16.823 20.16C20.055 20.16 22.039 18.24 22.039 15.072V14.016H17.063V15.616H19.943C19.879 17.2 18.999 18.496 16.855 18.496C14.455 18.496 13.319 16.816 13.319 14.368V14.24C13.319 11.728 14.615 10.064 16.855 10.064C18.343 10.064 19.367 10.72 19.623 12.24H21.751C21.447 9.504 19.271 8.384 16.823 8.384C13.479 8.384 11.111 10.816 11.111 14.224V14.352C11.111 17.728 13.159 20.16 16.823 20.16ZM24.0933 20H31.5173V18.32H26.2213V14.976H30.2533V13.376H26.2213V10.24H31.2453V8.56H24.0933V20ZM33.437 20H35.373V11.232L40.525 20H42.733V8.56H40.797V16.832L35.981 8.56H33.437V20ZM45.3589 20H52.7829V18.32H47.4869V14.976H51.5189V13.376H47.4869V10.24H52.5109V8.56H45.3589V20ZM58.6063 20.16C61.1343 20.16 62.8142 18.608 62.8142 16.624C62.8142 14.336 61.4223 13.568 58.7343 13.2C56.7503 12.912 56.3663 12.448 56.3663 11.52C56.3663 10.64 57.0383 10.016 58.3343 10.016C59.6463 10.016 60.3343 10.528 60.5423 11.728H62.4943C62.2703 9.536 60.7983 8.416 58.3343 8.416C55.9503 8.416 54.3503 9.824 54.3503 11.696C54.3503 13.84 55.6463 14.672 58.3823 15.04C60.2383 15.344 60.7663 15.744 60.7663 16.8C60.7663 17.856 59.8703 18.56 58.6063 18.56C56.6703 18.56 56.2063 17.6 56.0623 16.448H54.0143C54.1743 18.608 55.4863 20.16 58.6063 20.16ZM64.9385 20H67.0825V8.56H64.9385V20ZM73.6688 20.16C76.1968 20.16 77.8767 18.608 77.8767 16.624C77.8767 14.336 76.4848 13.568 73.7968 13.2C71.8128 12.912 71.4288 12.448 71.4288 11.52C71.4288 10.64 72.1008 10.016 73.3968 10.016C74.7088 10.016 75.3968 10.528 75.6048 11.728H77.5568C77.3328 9.536 75.8608 8.416 73.3968 8.416C71.0128 8.416 69.4128 9.824 69.4128 11.696C69.4128 13.84 70.7088 14.672 73.4448 15.04C75.3008 15.344 75.8288 15.744 75.8288 16.8C75.8288 17.856 74.9328 18.56 73.6688 18.56C71.7328 18.56 71.2688 17.6 71.1248 16.448H69.0768C69.2368 18.608 70.5488 20.16 73.6688 20.16Z" fill="white" />',
            '<defs><linearGradient id="nation_gradient_banner" x1="0" y1="0" x2="32.8778" y2="-31.1793" gradientUnits="userSpaceOnUse"><stop stop-color="#69C9FF" /><stop offset="1" stop-color="#88F1BB" /></linearGradient></defs>',
            '</svg>'
        ));
    }

    function genDef() internal pure returns(string memory) {
        return string(abi.encodePacked(
            '<def>',
            '<style>@import url("https://fonts.googleapis.com/css2?family=Open+Sans:[email protected];400;500");</style>'
            '</def>' 
        ));
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2018 The Officious BokkyPooBah / Bok Consulting Pty Ltd

pragma solidity ^0.8.0;

struct Date {
    uint256 year;
    uint256 month;
    uint256 day;
    uint256 hour;
    uint256 minute;
    uint256 second;
}

library DateTime {
    // for datetime conversion.
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 private constant SECONDS_PER_HOUR = 60 * 60;
    uint256 private constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function timestampToDateTime(uint256 timestamp) internal pure returns (Date memory) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        uint256 hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        uint256 minute = secs / SECONDS_PER_MINUTE;
        uint256 second = secs % SECONDS_PER_MINUTE;

        return Date(year, month, day, hour, minute, second);
    }

    // ------------------------------------------------------------------------
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
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IDefaultResolver {
    function name(bytes32 node) external view returns (string memory);
}

interface IReverseRegistrar {
    function node(address addr) external view returns (bytes32);

    function defaultResolver() external view returns (IDefaultResolver);
}

library ENSNameResolver {
    function lookupENSName(address _address) public view returns (string memory) {
        
        // Rinkeby & Goerli
        // address REGISTRAR_ADDRESS = 0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c;
        // Mainnet
        address REGISTRAR_ADDRESS = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
        address OLD_REGISTRAR_ADDRESS = 0x9062C0A6Dbd6108336BcBe4593a3D1cE05512069;

        string memory ens = tryLookupENSName(REGISTRAR_ADDRESS, _address);

        if (bytes(ens).length == 0) {
            ens = tryLookupENSName(OLD_REGISTRAR_ADDRESS, _address);
        }

        return ens;
    }

    function tryLookupENSName(address _registrar, address _address) public view returns (string memory) {
        uint32 size;
        assembly {
            size := extcodesize(_registrar)
        }
        if (size == 0) {
            return "";
        }
        IReverseRegistrar ensReverseRegistrar = IReverseRegistrar(_registrar);
        bytes32 node = ensReverseRegistrar.node(_address);
        return ensReverseRegistrar.defaultResolver().name(node);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DateTime, Date} from "../../utils/DateTime.sol";

library Metadata {
    function getMetadataJson(
        uint256 tokenId,
        address owner,
        uint256 timestamp,
        string memory imageData
    ) public pure returns (string memory) {
        string memory attributes = renderAttributes(tokenId, owner, timestamp);
        return string(abi.encodePacked(
            '{"name": "',
            renderName(tokenId),
            '", "image": "data:image/svg+xml;base64,',
            imageData,
            '","attributes":[',
            attributes,
            "]}"
        ));
    }

    function renderName(
        uint256 id
    ) public pure returns (string memory) {
        return string(abi.encodePacked("Nation3 Genesis Passport #", Strings.toString(id)));
    }

    function renderAttributes(
        uint256 id,
        address owner,
        uint256 timestamp
    ) public pure returns (string memory) {
        Date memory ts = DateTime.timestampToDateTime(timestamp);

        return
            string(abi.encodePacked(
                attributeString("Passport Holder", Strings.toHexString(uint256(uint160(owner)))),
                ",",
                attributeString("Passport Number", Strings.toString(id)),
                ",",
                attributeString(
                    "Issue Date",
                    string(abi.encodePacked(Strings.toString(ts.day),'/',Strings.toString(ts.month),'/',Strings.toString(ts.year)))
                )
            ));
    }

    function attributeString(string memory _name, string memory _value)
        public
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                "{",
                kv("trait_type", string(abi.encodePacked('"', _name, '"'))),
                ",",
                kv("value", string(abi.encodePacked('"', _value, '"'))),
                "}"
            ));
    }

    function kv(string memory _key, string memory _value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', _key, '"', ":", _value));
    }
}

// SPDX-License-Identifier: MIT
// Author: Brecht Devos

pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Renderer {
    function render(
        uint256 tokenId,
        address owner,
        uint256 timestamp
    ) public view virtual returns (string memory tokenURI) {
        string memory name = Strings.toString(uint256(uint160(owner)));
        tokenURI = string(abi.encodePacked(Strings.toString(tokenId),'-',name,'-',Strings.toString(timestamp)));
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