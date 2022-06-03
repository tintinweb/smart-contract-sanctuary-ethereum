// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// https://medium.com/scrappy-squirrels/tutorial-writing-an-nft-collectible-smart-contract-9c7e235e96da
// https://www.dappuniversity.com/articles/solidity-tutorial
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/mocks/EnumerableMapMock.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract MNFT {

// TESTING

    string[] RECORD = [
        "1",
        "2",
        "3",
        "4",
        "5",
        "6"
    ];
    
    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }


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

    function findResult(string memory output, uint n, uint id, uint seqNr) private view returns (string memory) {
        // return(RECORD[2]);
        // return(toString(id));

        // return toString(utfStringLength(string.concat(RECORD[4], RECORD[5])));
        if (n < 6) {
            return(toString(id));
        }

        if (utfStringLength(output) == 6) {
            seqNr += 1;
            if (seqNr == id) {
                // RESULT
                return output;
            }
        }

        if (n == 0) {
            return output;
        }

        for (uint i = 0; i < 6; ++i) {
            // Find result using recursion
    
            // string memory rec = RECORD[i];
            // string memory newString = string.concat(output,rec);
            // // return(toString(n - 1));
            // findResult(newString, n-1, id, seqNr);

            findResult(string.concat(output,RECORD[i]), n-1, id, seqNr);
        }

    }


    function code(uint id) internal view returns (string memory) {
        uint seqNr = 0;

        string memory out;
        string memory output_return;
        output_return = findResult(out, 6, id*4, seqNr);
        return output_return;
    }









}