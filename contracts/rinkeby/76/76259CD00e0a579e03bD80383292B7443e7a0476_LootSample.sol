// SPDX-License-Identifier: Apache-2.0
pragma solidity >= 0.7.0;
contract LootSample {

    // サンプル
    string[] private weapons = [
        "Warhammer",
        "Quarterstaff",
        "Maul",
        "Mace",
        "Club",
        "Katana",
        "Falchion",
        "Scimitar",
        "Long Sword",
        "Short Sword",
        "Ghost Wand",
        "Grave Wand",
        "Bone Wand",
        "Wand",
        "Grimoire",
        "Chronicle",
        "Tome",
        "Book"
    ];

    function pluck(string memory input) public view returns (bytes32, uint256, string memory, uint256){
        // ①まずは生のkeccak256を見てみましょう。
        bytes32 randKeccak = keccak256(abi.encodePacked(input));
        
        // ②正の整数に変換しましょう
        uint256 rand = uint256(keccak256(abi.encodePacked(input)));

        // ③Weaponを取り出そう
        string memory output = weapons[rand % weapons.length];

        // ④greatnessを取り出そう
        uint256 greatness = rand % 21;

        return (randKeccak, rand, output, greatness);
    }

    function encodeTest(string memory test1, string memory test2) public pure returns (bytes memory, string memory,bytes memory , string memory ){

        // ①abi.encodePackedだけだと？
        bytes memory  output1 = abi.encodePacked(test1, test2);
        
        // ②stringで囲んだら？
        string memory output2 = string(abi.encodePacked(test1, test2));

        // ③bytesで囲んだら？
        bytes memory  output3 = bytes(string(abi.encodePacked(test1, test2)));

        // ④Base64.encodeで囲んだら？
        string memory output4 = Base64.encode(bytes(string(abi.encodePacked(test1, test2)))); 

        return (output1, output2, output3, output4);
    }
}


library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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