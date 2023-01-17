// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// keyword contract sama seperti keyword class pada OOP
contract SimpleStorage {
    // visibility public dalam variable artinya akan dibuat function getter untuk mendapatkan nilai dari variable tersebut
    uint256 favoriteNumber;

    // bahasa solidity di compile menggunakan Etherium Virtual Machine (EVM)
    // ada beberapa jaringan blockchain yang kompatibel dengan EVM seperti Polygon dan Avalanche

    // cara assign variable dengan tipe object yang kita buat sendiri
    // People public person = People({favoriteNumber: 30, name: "fikri"});

    // mapping dalam solidity
    mapping(string => uint256) public nameToFavoriteNumber;

    // struct dalam solidity
    // struct berfungsi untuk membuat tipe data/objek baru dalam solidity
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // function yang memiliki keyword view dan pure, artinya function tersebut hanya untuk read dan tidak akan menggunakan gas, function yang ada keyword ini juga tidak bisa untuk modifikasi state apapun
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // beberapa macam data location di solidity
    // calldata = ini berarti data tersebut besifat sementara dan tidak dapat diubah ketika sudah di inisialisasi
    // memory = ini berarti data tersebut bersifat sementara dan masih dapat diubah ketika sudah di inisialisasi
    // storage = ini berarti data tersebut bersifat permanen dan masih dapat diubah ketika sudah di inisialisasi
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}