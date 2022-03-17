// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract SV {
    uint256 tokenId = 0;
    uint256[] rarity_class_count = [2000, 3000, 3000, 1500, 500]; // index 0 = limit of vault with 5 traits, index 1 = limit of vault with 6 traits and so on..
    uint256[] rarity_class_count_tracker = [0, 0, 0, 0, 0]; // how much vaults of each rarity class are created, index 0 shows how much vaults are created of rarity class with 5 traits
    string[] private weapon = [
        "W1",
        "W2",
        "W3",
        "W4",
        "W5",
        "W6",
        "W7",
        "W8",
        "W9",
        "W10",
        "W11",
        "W12",
        "W13",
        "W14",
        "W15",
        "W16",
        "W17",
        "W18",
        "W19",
        "W20",
        "W21",
        "W22",
        "W23",
        "W24",
        "W25"
    ];
    string[] private body = [
        "B1",
        "B2",
        "B3",
        "B4",
        "B5",
        "B6",
        "B7",
        "B8",
        "B9",
        "B10",
        "B11",
        "B12",
        "B13",
        "B14",
        "B15",
        "B16",
        "B17",
        "B18",
        "B19",
        "B20",
        "B21",
        "B22",
        "B23",
        "B24",
        "B25"
    ];

    string[] private face = [
        "F1",
        "F2",
        "F3",
        "F4",
        "F5",
        "F6",
        "F7",
        "F8",
        "F9",
        "F10",
        "F11",
        "F12",
        "F13",
        "F14",
        "F15",
        "F16",
        "F17",
        "F18",
        "F19",
        "F20",
        "F21",
        "F22",
        "F23",
        "F24",
        "F25"
    ];
    string[] private city = [
        "C1",
        "C2",
        "C3",
        "C4",
        "C5",
        "C6",
        "C7",
        "C8",
        "C9",
        "C10",
        "C11",
        "C12",
        "C13",
        "C14",
        "C15",
        "C16",
        "C17",
        "C18",
        "C19",
        "C20",
        "C21",
        "C22",
        "C23",
        "C24",
        "C25"
    ];
    string[] private transportation = [
        "T1",
        "T2",
        "T3",
        "T4",
        "T5",
        "T6",
        "T7",
        "T8",
        "T9",
        "T10",
        "T11",
        "T12",
        "T13",
        "T14",
        "T15",
        "T16",
        "T17",
        "T18",
        "T19",
        "T20",
        "T21",
        "T22",
        "T23",
        "T24",
        "T25"
    ];
    string[] private book = [
        "Book1",
        "Book2",
        "Book3",
        "Book4",
        "Book5",
        "Book6",
        "Book7",
        "Book8",
        "Book9",
        "Book10",
        "Book11",
        "Book12",
        "Book13",
        "Book14",
        "Book15",
        "Book16",
        "Book17",
        "Book18",
        "Book19",
        "Book20",
        "Book21",
        "Book22",
        "Book23",
        "Book24",
        "Book25"
    ];
    string[] private game = [
        "G1",
        "G2",
        "G3",
        "G4",
        "G5",
        "G6",
        "G7",
        "G8",
        "G9",
        "G10",
        "G11",
        "G12",
        "G13",
        "G14",
        "G15",
        "G16",
        "G17",
        "G18",
        "G19",
        "G20",
        "G21",
        "G22",
        "G23",
        "G24",
        "G25"
    ];

    string[] private movie = [
        "M1",
        "M2",
        "M3",
        "M4",
        "M5",
        "M6",
        "M7",
        "M8",
        "M9",
        "M10",
        "M11",
        "M12",
        "M13",
        "M14",
        "M15",
        "M16",
        "M17",
        "M18",
        "M19",
        "M20",
        "M21",
        "M22",
        "M23",
        "M24",
        "M25"
    ];
    string[] private element = [
        "E1",
        "E2",
        "E3",
        "E4",
        "E5",
        "E6",
        "E7",
        "E8",
        "E9",
        "E10",
        "E11",
        "E12",
        "E13",
        "E14",
        "E15",
        "E16",
        "E17",
        "E18",
        "E19",
        "E20",
        "E21",
        "E22",
        "E23",
        "E24",
        "E25"
    ];

    // returns value of trait against and asked trait and tokenId
    function pluck(
        uint256 _tokenId,
        string memory traitName,
        string[] memory sourceArray
    ) internal pure returns (string memory) {
        //generate randomNumber against Asked trait and tokenId
        uint256 rand = random(
            string(abi.encodePacked(traitName, toString(_tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length]; // rand % sourceArray.length gives a number < length of asked trait array, that number is the index of trait vaule to be returned

        return output;
    }

    // generates random number
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // creates vault
    function createVault() external returns (string[9] memory) {
        require(tokenId < 10000, "Cap Reached");
        tokenId++;
        bool isUncappedRandom; // flag against generated random number(which represents how much traits to generate per vault) whether its capp reached or not
        uint256 loopCounter = 0; // for randomness
        uint256 rarity_rand; // represents vaults with n traits, e.g 0 means vault with 5 traits , 1 = vault with 6 traits and so on..

        string[9] memory vault; // to hold traits of vault
        // generating traits that are mandatory
        vault[0] = pluck(tokenId, "Weapon", weapon);
        vault[1] = pluck(tokenId, "Body", body);
        vault[2] = pluck(tokenId, "Face", face);
        vault[3] = pluck(tokenId, "City", city);
        //rarity class means class of vaults having N number of traits, e.g 0 rarity class = vaults with 5 traits and so on..
        // generates random number for rarity class whose cap is not reached, e.g it will generate only that number whose rarity class cap is not reached
        while (!isUncappedRandom) {
            loopCounter++;
            rarity_rand = random(
                string(
                    abi.encodePacked(
                        toString(tokenId),
                        toString(loopCounter),
                        msg.sender
                    )
                )
            );
            rarity_rand %= 5; //  to create vault with returned number of traits. e.g 0 means vault with 5 traits , 1 means vault with 6 traits
            if (
                rarity_class_count_tracker[rarity_rand] <
                rarity_class_count[rarity_rand]
            ) {
                rarity_class_count_tracker[rarity_rand]++;
                isUncappedRandom = true;
            }
        }
        // @param rarity_rand = represents vault with rarity_rand + 5 traits
        bool[9] memory rand_arr = generateRandomArray(rarity_rand, tokenId); // ture in array represents trait against that index should be created . e.g 0th index means "BODY" trait , 4th index means "TRANSPORATION" trait

        if (rand_arr[4]) {
            vault[4] = pluck(tokenId, "Transportation", transportation);
        }
        if (rand_arr[5]) {
            vault[5] = pluck(tokenId, "Book", book);
        }
        if (rand_arr[6]) {
            vault[6] = pluck(tokenId, "Game", game);
        }
        if (rand_arr[7]) {
            vault[7] = pluck(tokenId, "Movie", movie);
        }
        if (rand_arr[8]) {
            vault[8] = pluck(tokenId, "Element", element);
        }

        // string memory test = string(
        //     abi.encodePacked(
        //         vault[0],
        //         vault[1],
        //         vault[2],
        //         vault[3],
        //         vault[4],
        //         vault[5],
        //         vault[6],
        //         vault[7],
        //         vault[8]
        //     )
        // );
        // console.log(test);
        // console.log(vault[0]);
        // console.log(vault[1]);
        // console.log(vault[2]);
        // console.log(vault[3]);
        // console.log(vault[4]);
        // console.log(vault[5]);
        // console.log(vault[6]);
        // console.log(vault[7]);
        // console.log(vault[8]);
        return vault;
    }

    function generateRandomArray(uint256 _length, uint256 _tokenId)
        public
        view
        returns (bool[9] memory)
    {
        bool[9] memory randomArray;
        uint256 check = 0; // keeping track of number of indexes of traits to be generated
        uint256 loopCounter = 0;
        while (check < _length + 1) {
            loopCounter++;
            uint256 rand = ((
                random(
                    string(
                        abi.encodePacked(
                            toString(_tokenId),
                            toString(loopCounter),
                            msg.sender
                        )
                    )
                )
            ) % (8 - 4 + 1)) + 4; // generating random no. b/w 4-8 (due to indexing of traits)
            if (randomArray[rand] == false) {
                check++;
                randomArray[rand] = true;
            }
        }

        return randomArray;
    }

    function getBody(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "Body", body);
    }

    function getWeapon(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "Weapon", weapon);
    }

    function getFace(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "Face", face);
    }

    function getCity(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "City", city);
    }

    function getTransportation(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return pluck(_tokenId, "Transportation", transportation);
    }

    function getBook(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "Book", book);
    }

    function getGame(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "Game", game);
    }

    function getMovie(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "Movie", movie);
    }

    function getElement(uint256 _tokenId) public view returns (string memory) {
        return pluck(_tokenId, "Element", element);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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
}