// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// artist: 0xhaiku

interface IMnemonic {
    function getMulti(uint256[] memory arr) external view returns (string[] memory);
}

contract MnemonicHaikuComposer {
    mapping(uint8 => uint16[]) public syllablesTable;
    mapping(uint8 => mapping(uint8 => uint8[][])) linePatterns;
    uint8[][] haikuPatterns;

    IMnemonic private mnemonic;

    constructor(
        uint16[] memory _syllables1,
        uint16[] memory _syllables2,
        uint16[] memory _syllables3,
        uint16[] memory _syllables4,
        address _mnemonic
    ) {
        syllablesTable[1] = _syllables1;
        syllablesTable[2] = _syllables2;
        syllablesTable[3] = _syllables3;
        syllablesTable[4] = _syllables4;

        linePatterns[5][5].push([1, 1, 1, 1, 1]);
        linePatterns[5][4].push([1, 1, 1, 2]);
        linePatterns[5][3].push([1, 2, 2]);
        linePatterns[5][2].push([2, 3]);
        linePatterns[5][3].push([1, 1, 3]);
        linePatterns[5][2].push([1, 4]);
        linePatterns[7][7].push([1, 1, 1, 1, 1, 1, 1]);
        linePatterns[7][6].push([1, 1, 1, 1, 1, 2]);
        linePatterns[7][5].push([1, 1, 1, 2, 2]);
        linePatterns[7][4].push([1, 2, 2, 2]);
        linePatterns[7][4].push([1, 1, 2, 3]);
        linePatterns[7][3].push([2, 2, 3]);
        linePatterns[7][4].push([1, 1, 1, 4]);
        linePatterns[7][3].push([1, 2, 4]);
        linePatterns[7][2].push([3, 4]);

        haikuPatterns = [
            [3, 7, 2],
            [2, 7, 3],
            [3, 6, 3],
            [4, 6, 2],
            [2, 6, 4],
            [2, 5, 5],
            [5, 5, 2],
            [3, 5, 4],
            [4, 5, 3],
            [4, 4, 4],
            [5, 4, 3],
            [3, 4, 5],
            [4, 3, 5],
            [5, 3, 4],
            [5, 2, 5]
        ];

        mnemonic = IMnemonic(_mnemonic);
    }

    function shuffle(uint8[] memory _arr, uint256 _seed) private pure returns (uint8[] memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(_seed)));
        for (uint256 i = 0; i < _arr.length; i++) {
            uint256 n = i + (rand % (_arr.length - i));
            uint8 temp = _arr[n];
            _arr[n] = _arr[i];
            _arr[i] = temp;
        }
        return _arr;
    }

    function getHaiku(uint256 _seed) external view returns (string[][] memory) {
        uint8[] memory pattern = haikuPatterns[
            uint256(keccak256(abi.encodePacked(_seed))) % haikuPatterns.length
        ];

        string[][] memory words = new string[][](pattern.length);
        for (uint8 i = 0; i < pattern.length; i++) {
            uint8 syllables = i == 0 || i == 2 ? 5 : 7;
            words[i] = getLine(syllables, pattern[i], i, _seed);
        }
        return words;
    }

    function getLine(
        uint8 _syllables,
        uint8 _length,
        uint8 _line,
        uint256 _seed
    ) private view returns (string[] memory) {
        require(_syllables == 7 || _syllables == 5);

        uint8[] memory pattern = linePatterns[_syllables][_length][
            uint256(keccak256(abi.encodePacked(_seed))) % linePatterns[_syllables][_length].length
        ];
        pattern = shuffle(pattern, _seed);

        uint256[] memory indicies = new uint256[](pattern.length);
        for (uint8 i = 0; i < pattern.length; i++) {
            indicies[i] = uint256(
                syllablesTable[pattern[i]][
                    uint256(keccak256(abi.encodePacked("wi", i, _line, _seed))) %
                        syllablesTable[pattern[i]].length
                ]
            );
        }

        return mnemonic.getMulti(indicies);
    }
}