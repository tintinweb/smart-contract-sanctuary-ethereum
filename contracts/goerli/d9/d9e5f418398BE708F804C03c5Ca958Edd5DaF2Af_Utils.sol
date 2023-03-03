// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

struct Attr {
    address owner;
    uint256 tokenId;
    string name;
    uint256 supply;
    string metadata;
    uint256 unlockTime;
    uint256 targetBalance;
    address piggyBank;
}

interface ISignatureMintERC1155 {
    /**
     *  @notice The body of a request to mint tokens.
     *
     *  @param to The receiver of the tokens to mint.
     *  @param quantity The quantity of tokens to mint.
     *  @param validityStartTimestamp The unix timestamp after which the payload is valid.
     *  @param validityEndTimestamp The unix timestamp at which the payload expires.
     *  @param uri The metadata URI of the token to mint. (Not applicable for ERC20 tokens)
     */
    struct MintRequest {
        address to;
        uint256 quantity;
        uint128 validityStartTimestamp;
        uint128 validityEndTimestamp;
        string name;
        string metadata;
        uint256 unlockTime;
        uint256 targetBalance;
    }

    /// @dev Emitted when tokens are minted.
    event TokensMintedWithSignature(
        address indexed signer,
        uint256 indexed tokenIdMinted,
        MintRequest mintRequest
    );

    /**
     *  @notice Verifies that a mint request is signed by an account holding
     *          MINTER_ROLE (at the time of the function call).
     *
     *  @param req The payload / mint request.
     *  @param signature The signature produced by an account signing the mint request.
     *
     *  returns (success, signer) Result of verification and the recovered address.
     */
    function verify(MintRequest calldata req, bytes calldata signature)
        external
        view
        returns (bool success, address signer);

    /**
     *  @notice Mints tokens according to the provided mint request.
     *
     *  @param req The payload / mint request.
     *  @param signature The signature produced by an account signing the mint request.
     */
    function mintWithSignature(MintRequest calldata req, bytes calldata signature)
        external
        payable
        returns (address signer);
}

library Utils {
    function getSvg(
        string calldata name,
        address piggyBank,
        uint256 targetBalance,
        uint256 unlockTime
    ) public view returns (string memory) {
        uint256 percentage = (address(piggyBank).balance * 100) / targetBalance;
        string memory markup = string(
            abi.encodePacked(
                '<svg class="piggy" width="350" height="350" viewBox="0 0 512 456" xmlns="http://www.w3.org/2000/svg"><path d="M497.797 199.111H471.574C463.751 181.333 452.373 165.6 438.328 152.444L455.129 85.3333H426.683C400.549 85.3333 377.437 97.3333 361.792 115.822C355.036 114.844 348.369 113.778 341.347 113.778H227.564C158.762 113.778 101.426 162.667 88.1812 227.556H49.7797C36.6237 227.556 26.2233 215.556 28.89 201.956C30.8457 191.822 40.3571 184.889 50.6687 184.889H51.5576C54.491 184.889 56.8911 182.489 56.8911 179.556V161.778C56.8911 158.844 54.491 156.444 51.5576 156.444C26.2233 156.444 3.6446 174.578 0.444472 199.644C-3.46679 230.044 20.1786 256 49.7797 256H85.3367C85.3367 302.4 107.915 343.2 142.228 369.156V440.889C142.228 448.711 148.628 455.111 156.451 455.111H213.342C221.164 455.111 227.564 448.711 227.564 440.889V398.222H341.347V440.889C341.347 448.711 347.747 455.111 355.569 455.111H412.461C420.283 455.111 426.683 448.711 426.683 440.889V369.156C437.173 361.244 446.506 351.911 454.507 341.333H497.797C505.62 341.333 512.02 334.933 512.02 327.111V213.333C512.02 205.511 505.62 199.111 497.797 199.111ZM384.015 256C376.192 256 369.792 249.6 369.792 241.778C369.792 233.956 376.192 227.556 384.015 227.556C391.838 227.556 398.238 233.956 398.238 241.778C398.238 249.6 391.838 256 384.015 256ZM227.564 85.3333H341.347C346.147 85.3333 350.858 85.6889 355.481 86.0444C355.481 85.7778 355.569 85.6 355.569 85.3333C355.569 38.2222 317.346 0 270.233 0C223.12 0 184.896 38.2222 184.896 85.3333C184.896 87.2 185.341 88.9778 185.429 90.8444C198.941 87.3778 212.986 85.3333 227.564 85.3333Z" fill="#6f397e91;"/><style>svg.piggy{background:linear-gradient(to top, #000 ',
                Utils.uint2str(percentage)
            )
        );

        markup = string(abi.encodePacked(markup, "%, #6f397e91 "));
        // linear-gradient value 2:
        markup = string(
            abi.encodePacked(markup, Utils.uint2str(percentage + 10))
        );
        markup = string(
            abi.encodePacked(
                markup,
                '%);}.a,.b,.c{font-weight:bold;fill:white;}.a{font-size:28px;text-align:center;}.b{font-size:14px;}.c{font-size:10px;}</style><text class="a" x="235" y="50">'
            )
        );
        // percent of target balance
        markup = string(abi.encodePacked(markup, Utils.uint2str(percentage)));
        markup = string(
            abi.encodePacked(
                markup,
                '%</text><text class="b" x="222" y="75"><tspan>'
            )
        );
        // days to go
        markup = string(
            abi.encodePacked(
                markup,
                Utils.uint2str(Utils.diffDays(block.timestamp, unlockTime))
            )
        );
        markup = string(
            abi.encodePacked(
                markup,
                '</tspan><tspan> days to go</tspan></text><text class="a" x="180" y="165">'
            )
        );
        markup = string(abi.encodePacked(markup, name));
        markup = string(
            abi.encodePacked(
                markup,
                '</text><text class="b" x="180" y="185"><tspan>Maturity Date: </tspan><tspan>'
            )
        );
        markup = string(
            abi.encodePacked(markup, Utils.getDateFromTimestamp(unlockTime))
        );
        markup = string(
            abi.encodePacked(
                markup,
                '</tspan></text><text class="b" x="180" y="260"><tspan>Piggy needs </tspan><tspan id="PiggyNeeds"></tspan> ETH</text><text class="b" x="180" y="280"><tspan>Piggy has </tspan><tspan id="PiggyHas"> ETH</tspan></text><text class="b" x="165" y="335">Piggy needs ETH! Send to:</text><text class="c" x="165" y="355">'
            )
        );
        markup = string(
            abi.encodePacked(markup, Utils.toAsciiString(address(piggyBank)))
        );
        markup = string(
            abi.encodePacked(
                markup,
                '</text><script id="PiggyScript" data-target="',
                Utils.uint2str(targetBalance),
                '" data-balance="',
                Utils.uint2str(address(piggyBank).balance),
                '" type="text/javascript">function refreshValues(){ var s = document.getElementById("PiggyScript"); var bal = s.getAttribute("data-balance"); var target = s.getAttribute("data-target"); var n = document.getElementById("PiggyNeeds"); var h = document.getElementById("PiggyHas"); n.innerHTML=Math.round(target-bal / 10000000000000000, 2).toString(); h.innerHTML=Math.round(bal / 10000000000000000, 2).toString(); }window.addEventListener("load",refreshValues);</script></svg>'
            )
        );
        return markup;
    }

    function _daysToDate(
        uint _days
    ) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);
        int L = __days + 2509157;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;
        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function getDateFromTimestamp(
        uint timestamp
    ) internal pure returns (string memory) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / 86400);
        return
            string(
                abi.encodePacked(
                    uint2str(day),
                    "/",
                    uint2str(month),
                    "/",
                    uint2str(year)
                )
            );
    }

    function diffDays(
        uint fromTimestamp,
        uint toTimestamp
    ) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / 86400;
    }

    function uint2str(
        uint _i
    ) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        {
            uint k = len;
            while (_i != 0) {
                k = k - 1;
                uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
                bytes1 b1 = bytes1(temp);
                bstr[k] = b1;
                _i /= 10;
            }
        }

        return string(bstr);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}