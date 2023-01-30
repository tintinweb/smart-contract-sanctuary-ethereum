//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SoundPlayer {
    address private NEO = 0x0000000000000000000000000000000000000000;
    //{ songData: [{ i: [2, 192, 128, 0, 2, 192, 128, 3, 0, 0, 32, 222, 60, 0, 0, 0, 2, 188, 3, 1, 3, 55, 241, 60, 67, 53, 5, 75, 5], p: [1, 2, 3, 4, 3, 4], c: [{ n: [123], f: [] }, { n: [118], f: [] }, { n: [123, 111], f: [] }, { n: [118, 106], f: [] }] }, { i: [3, 100, 128, 0, 3, 201, 128, 7, 0, 0, 17, 43, 109, 0, 0, 0, 3, 113, 4, 1, 1, 23, 184, 2, 29, 147, 6, 67, 3], p: [, , 1, 2, 1, 2], c: [{ n: [123, , , , , , , , 123, , , , , , , , 123, , , , , , , , 123, , , , , , , , 126, , , , , , , , 126, , , , , , , , 126, , , , , , , , 126, , , , , , , , 130, , , , , , , , 130, , , , , , , , 130, , , , , , , , 130], f: [] }, { n: [122, , , , , , , , 122, , , , , , , , 122, , , , , , , , 122, , , , , , , , 125, , , , , , , , 125, , , , , , , , 125, , , , , , , , 125, , , , , , , , 130, , , , , , , , 130, , , , , , , , 130, , , , , , , , 130], f: [] }] }, { i: [0, 192, 99, 64, 0, 80, 99, 0, 0, 3, 4, 0, 66, 0, 0, 0, 0, 19, 4, 1, 2, 86, 241, 18, 195, 37, 4, 0, 0], p: [, , 1, 1, 1, 1, 1], c: [{ n: [147, , , , 147, , , , 147, , , , 147, , , , 147, , , , 147, , , , 147, , , , 147], f: [] }] }, { i: [2, 146, 140, 0, 2, 224, 128, 3, 0, 0, 84, 0, 95, 0, 0, 0, 3, 179, 5, 1, 2, 62, 135, 11, 15, 150, 3, 157, 6], p: [, , , , 1, 2], c: [{ n: [147, , 145, , 147, , , , , , , , , , , , 135], f: [11, , , , , , , , , , , , , , , , 11, , , , , , , , , , , , , , , , 27, , , , , , , , , , , , , , , , 84] }, { n: [142, , 140, , 142, , , , , , , , , , , , 130], f: [11, , , , , , , , , , , , , , , , 11, , , , , , , , , , , , , , , , 27, , , , , , , , , , , , , , , , 84] }] }], rowLen: 6615, patternLen: 32, endPattern: 6, numChannels: 4}
    string[2] private soundScript = [
        '<script type="text/javascript"> "use strict"; var songObj = Object.assign(JSON.parse(',
        '), { rowLen: 6615, patternLen: 32, endPattern: 6, numChannels: 4 }), CPlayer = function () { var $, _, n, e, r, i = function ($) { return Math.sin(6.283184 * $) }, t = function ($) { return .003959503758 * 2 ** (($ - 128) / 12) }, a = function ($, _, n) { var e, r, i, a, o, u, c = f[$.i[0]], s = $.i[1], v = $.i[3] / 32, g = f[$.i[4]], l = $.i[5], p = $.i[8] / 32, w = $.i[9], d = $.i[10] * $.i[10] * 4, h = $.i[11] * $.i[11] * 4, m = $.i[12] * $.i[12] * 4, L = 1 / m, y = -$.i[13] / 16, C = $.i[14], b = n * 2 ** (2 - $.i[15]), j = new Int32Array(d + h + m), D = 0, O = 0; for (e = 0, r = 0; e < d + h + m; e++, r++)r >= 0 && (C = C >> 8 | (255 & C) << 4, r -= b, o = t(_ + (15 & C) + $.i[2] - 128), u = t(_ + (15 & C) + $.i[6] - 128) * (1 + 8e-4 * $.i[7])), i = 1, e < d ? i = e / d : e >= d + h && (i = (1 - (i = (e - d - h) * L)) * 3 ** (y * i)), D += o * i ** v, a = c(D) * s, O += u * i ** p, a += g(O) * l, w && (a += (2 * Math.random() - 1) * w), j[e] = 80 * a * i | 0; return j }, f = [i, function ($) { return $ % 1 < .5 ? 1 : -1 }, function ($) { return 2 * ($ % 1) - 1 }, function ($) { var _ = $ % 1 * 4; return _ < 2 ? _ - 1 : 3 - _ }]; this.init = function (i) { $ = i, _ = i.endPattern, n = 0, e = i.rowLen * i.patternLen * (_ + 1) * 2, r = new Int32Array(e) }, this.generate = function () { var t, o, u, c, s, v, g, l, p, w, d, h, m, L, y = new Int32Array(e), C = $.songData[n], b = $.rowLen, j = $.patternLen, D = 0, O = 0, P = !1, T = []; for (u = 0; u <= _; ++u)for (c = 0, g = C.p[u]; c < j; ++c) { var B = g ? C.c[g - 1].f[c] : 0; B && (C.i[B - 1] = C.c[g - 1].f[c + j] || 0, B < 17 && (T = [])); var E = f[C.i[16]], R = C.i[17] / 512, U = 2 ** (C.i[18] - 9) / b, W = C.i[19], A = C.i[20], I = 135.82764118168 * C.i[21] / 44100, k = 1 - C.i[22] / 255, q = 1e-5 * C.i[23], x = C.i[24] / 32, z = C.i[25] / 512, F = 6.283184 * 2 ** (C.i[26] - 9) / b, G = C.i[27] / 255, H = C.i[28] * b & -2; for (s = 0, d = (u * j + c) * b; s < 4; ++s)if (v = g ? C.c[g - 1].n[c + s * j] : 0) { T[v] || (T[v] = a(C, v, b)); var J = T[v]; for (o = 0, t = 2 * d; o < J.length; o++, t += 2)y[t] += J[o] } for (o = 0; o < b; o++)(w = y[l = (d + o) * 2]) || P ? (h = I, W && (h *= E(U * l) * R + .5), D += (h = 1.5 * Math.sin(h)) * O, m = k * (w - O) - D, O += h * m, w = 3 == A ? O : 1 == A ? m : D, q && (w *= q, w = w < 1 ? w > -1 ? i(.25 * w) : -1 : 1, w /= q), w *= x, P = w * w > 1e-5, L = w * (1 - (p = Math.sin(F * l) * z + .5)), w *= p) : L = 0, l >= H && (L += y[l - H + 1] * G, w += y[l - H] * G), y[l] = 0 | L, y[l + 1] = 0 | w, r[l] += 0 | L, r[l + 1] += 0 | w } return ++n / $.numChannels }, this.createAudioBuffer = function ($) { for (var _ = $.createBuffer(2, e / 2, 44100), n = 0; n < 2; n++)for (var i = _.getChannelData(n), t = n; t < e; t += 2)i[t >> 1] = r[t] / 65536; return _ }, this.createWave = function () { var $ = 44 + 2 * e - 8, _ = $ - 36, n = new Uint8Array(44 + 2 * e); n.set([82, 73, 70, 70, 255 & $, $ >> 8 & 255, $ >> 16 & 255, $ >> 24 & 255, 87, 65, 86, 69, 102, 109, 116, 32, 16, 0, 0, 0, 1, 0, 2, 0, 68, 172, 0, 0, 16, 177, 2, 0, 4, 0, 16, 0, 100, 97, 116, 97, 255 & _, _ >> 8 & 255, _ >> 16 & 255, _ >> 24 & 255]); for (var i = 0, t = 44; i < e; ++i) { var a = r[i]; a = a < -32767 ? -32767 : a > 32767 ? 32767 : a, n[t++] = 255 & a, n[t++] = a >> 8 & 255 } return n }, this.getData = function ($, _) { for (var n = 2 * Math.floor(44100 * $), e = Array(_), i = 0; i < 2 * _; i += 1) { var t = n + i; e[i] = $ > 0 && t < r.length ? r[t] / 32768 : 0 } return e } }; function song() { var $ = new CPlayer; $.init(songObj); var _ = !1; setInterval(function () { if (!_ && (document.getElementById("status"), _ = $.generate() >= 1)) { var n = $.createWave(), e = document.createElement("audio"), r = document.createElement("audio"); e.src = URL.createObjectURL(new Blob([n], { type: "audio/wav" })), r.src = URL.createObjectURL(new Blob([n], { type: "audio/wav" })), function $(_, n) { if (_ || n ? _ && !n && (e.currentTime = 0, e.play(), _ = !1) : (r.currentTime = 0, r.play(), _ = !0), _ && r.currentTime >= r.duration - 4.5 || !_ && e.currentTime >= e.duration - 4.5) { $(_, !1); return } setTimeout(function () { $(_, !0) }, 250) }(!0) } }, 0) }</script>'
    ];

    string[] private songData = [
        "rowLen:",
        ",patternLen:",
        ",endPattern:",
        ",numChannels:"
    ];

    struct Song {
        string song;
        string name;
        string description;
        address owner;
        uint64 rowLen;
        uint64 patternLen;
        uint64 endPattern;
        uint64 numChannels;
    }

    uint256 public songIndex = 0;

    uint256[] public reuseSongIndexes;

    mapping(uint256 => Song) public songs;
    mapping(address => uint256[]) public userSongs;

    constructor() {
        //   NEO = _NEO;
    }

    function addSong(
        string memory _name,
        string memory _description,
        string memory _song,
        uint64 rowLen,
        uint64 patternLen,
        uint64 endPattern,
        uint64 numChannels
    ) public {
        songs[songIndex] = Song(
            _song,
            _name,
            _description,
            msg.sender,
            rowLen,
            patternLen,
            endPattern,
            numChannels
        );

        if (reuseSongIndexes.length > 0) {
            uint256 _songId = reuseSongIndexes[reuseSongIndexes.length - 1];
            reuseSongIndexes.pop();
            songs[_songId] = Song(
                _song,
                _name,
                _description,
                msg.sender,
                rowLen,
                patternLen,
                endPattern,
                numChannels
            );
            userSongs[msg.sender].push(_songId);
            return;
        }

        userSongs[msg.sender].push(songIndex);
        songIndex++;
    }

    function getScriptAndSongByAddress(
        address _address,
        uint256 _index
    ) public view returns (string memory) {
        uint256 _songId = userSongs[_address][_index];
        Song memory _song = songs[_songId];
        bytes memory song = abi.encodePacked(
            "{ songData:",
            _song.song,
            ",rowLen:",
            Strings.toString(_song.rowLen),
            ",patternLen:",
            Strings.toString(_song.patternLen),
            ",endPattern:",
            Strings.toString(_song.endPattern),
            ",numChannels:",
            Strings.toString(_song.numChannels),
            "}"
        );
        bytes memory script = abi.encodePacked(
            soundScript[0],
            song,
            soundScript[1]
        );

        return string(script);
    }

    function getScriptAndSongById(
        uint256 _id
    ) public view returns (string memory) {
        Song memory _song = songs[_id];
        bytes memory song = abi.encodePacked(
            _song.song,
            ",rowLen:",
            Strings.toString(_song.rowLen),
            ",patternLen:",
            Strings.toString(_song.patternLen),
            ",endPattern:",
            Strings.toString(_song.endPattern),
            ",numChannels:",
            Strings.toString(_song.numChannels),
            "}"
        );
        bytes memory script = abi.encodePacked(
            soundScript[0],
            song,
            soundScript[1]
        );

        return string(script);
    }

    function getSongWithOpt(
        address _address,
        uint256 _index,
        uint64 _rowLen,
        uint64 _patternLen,
        uint64 _endPattern,
        uint64 _numChannels
    ) public view returns (string memory) {
        uint256 _songId = userSongs[_address][_index];
        Song memory _song = songs[_songId];
        bytes memory song = abi.encodePacked(
            "{ songData:",
            _song.song,
            ",rowLen:",
            Strings.toString(_rowLen),
            ",patternLen:",
            Strings.toString(_patternLen),
            ",endPattern:",
            Strings.toString(_endPattern),
            ",numChannels:",
            Strings.toString(_numChannels),
            "}"
        );
        bytes memory script = abi.encodePacked(
            soundScript[0],
            song,
            soundScript[1]
        );

        return string(script);
    }

    function ownerOf(uint256 _index) public view returns (address) {
        return songs[_index].owner;
    }

    function ownerOfByAddress(
        address _address,
        uint256 _index
    ) public view returns (address) {
        uint256 _songId = userSongs[_address][_index];
        return songs[_songId].owner;
    }

    function getOwnerSongs(
        address _address
    ) public view returns (uint256[] memory) {
        return userSongs[_address];
    }

    function editSong(uint256 _id, string memory _song) public {
        require(
            msg.sender == songs[_id].owner,
            "You can only edit your own songs"
        );
        songs[_id].song = _song;
    }

    function editSongOpts(
        uint256 _id,
        uint64 rowLen,
        uint64 patternLen,
        uint64 endPattern,
        uint64 numChannels
    ) public {
        require(
            msg.sender == songs[_id].owner,
            "You can only edit your own songs"
        );
        songs[_id].rowLen = rowLen;
        songs[_id].patternLen = patternLen;
        songs[_id].endPattern = endPattern;
        songs[_id].numChannels = numChannels;
    }

    function removeSongAndMove(uint256 _id) public {
        require(
            msg.sender == songs[_id].owner,
            "You can only edit your own songs"
        );
        uint256[] storage _userSongs = userSongs[msg.sender];
        uint256 _index = 0;
        for (uint256 i = 0; i < _userSongs.length; i++) {
            if (_userSongs[i] == _id) {
                _index = i;

                break;
            }
        }

        for (uint256 i = _index; i < _userSongs.length - 1; i++) {
            _userSongs[i] = _userSongs[i + 1];
        }

        _userSongs.pop();

        delete songs[_id];

        reuseSongIndexes.push(_id);
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