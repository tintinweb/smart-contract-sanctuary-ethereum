/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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


//Módulo 02 > Lição 03 > Tóp 01 - ParOuImparV4: PvP
contract ParOuImpar {
    string public choicePlayer1 = ""; //EVEN or ODD
    address public player1;
    uint8 private numberPlayer1 = 0;
    string public status = "";

    function compare(string memory str1, string memory str2)
        private
        pure
        returns (bool)
    {
        bytes memory arrA = bytes(str1);
        bytes memory arrB = bytes(str2);
        return arrA.length == arrB.length && keccak256(arrA) == keccak256(arrB);
    }

    function choose(string memory newChoice) public {
        require(
            compare(newChoice, "EVEN") || compare(newChoice, "ODD"),
            "Choose EVEN or ODD"
        );

        string memory message = string.concat(
            "Player 1 already choose ",
            choicePlayer1
        );
        require(compare(choicePlayer1, ""), message);

        choicePlayer1 = newChoice;
        player1 = msg.sender;
        status = string.concat(
            "Player 1 is ",
            Strings.toHexString(player1),
            " and choose ",
            choicePlayer1
        );
    }

    function play(uint8 number) public {
        require(
            !compare(choicePlayer1, ""),
            "First, choose your option (EVEN or ODD)"
        );
        require(number > 0, "The number must be greater than 0.");

        if (msg.sender == player1) {
            numberPlayer1 = number;
            status = "Player 1 already played. Waiting player 2.";
        } else {
            require(numberPlayer1 > 0, "Player 1 needs to play first.");
            
            bool isEven = (number + numberPlayer1) % 2 == 0;
            string memory message = string.concat(
                "Player choose ",
                choicePlayer1,
                " and plays ",
                Strings.toString(numberPlayer1),
                ". Player 2 plays ",
                Strings.toString(number)
            );

            if (isEven && compare(choicePlayer1, "EVEN"))
                status = string.concat(message, ". Player 1 won.");
            else if (!isEven && compare(choicePlayer1, "ODD"))
                status = string.concat(message, ". Player 1 won.");
            else status = string.concat(message, ". Player 2 won.");

            choicePlayer1 = "";
            numberPlayer1 = 0;
            player1 = address(0);
        }
    }
}