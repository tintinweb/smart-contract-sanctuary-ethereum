/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

contract tipeData {
    // beberapa tipe data yang umum digunakan
    // - boolean 
    // uint
    // int
    // string
    // address

    bool public boo = true; // variable bertipe boolean dengan nilai true.

    // uint adalah singkatan dari unsigned integer, yang merupakan bilangan tak bertanda
    // atau bilangan positif.
    // ada beberapa jenis uint yang didasarkan ukuran nilainya.
    // uint8 memiliki rentang 0 sampai 2^8-1
    // uint16 memiliki rentang 0 sampai 2^16-1
    // uint256 memiliki rentang 0 sampai 2^256-1
    // uint adalah nama lain uint256
    // kasih keyword public supaya bisa diakses atau dibaca oleh kontrak atau user lain lain
    uint8 public a = 1;
    uint256 public b = 282929;
    uint public c = 9876; // sama aja dengan uint256 public c = 9876
    // nah bagaimana kalo nilai dari uint melebihi ukuran yang semestinya?
    // 2^8-1 = 255
    // uint8 public errorKah = 256; error wkwkwk
    // jadi ga bisa menyimpan melebihi ukurannya

    // bilangan negatif dapat disimpan menggunakan int.
    // sama kek uint, int juga punya ukuran masing-masing, misalnya:
    // int256 memiliki rentang -2^255 sampai 2^255-1
    int8 public ia = -1;
    int public ib = -28288;
    int public yta = 638;

    // nilai minimum int
    int public minA = type(int).min;
    int public maxA = type(int).max;

    // tipe data address, yang menyimpan ... address

    address public alamatKu = 0xA36ACa10170185F663C804f36e69D6BA0C62CED5;

    // nilai default
    // variable yang nilainya tidak/belum ditetapkan, memiliki nilai default

    bool public defboo; // false
    uint public defUint; // 0
    int public defInt; // 0
    address public alamatMu; // 0x00000000000000000000000000000 (panjangnya ga sempat ngitung)
    // mari kita deploy
}