//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

    contract HelloWorld {

        string private phrase;

        function setPhrase(string memory _phrase) public {
            phrase = _phrase;
        }

        function getPhrase() public view returns (string memory) {
            return phrase;
        }
    }