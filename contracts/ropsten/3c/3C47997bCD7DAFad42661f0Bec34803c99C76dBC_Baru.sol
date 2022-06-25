// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Baru {

    // unsigned integer variable
    // 0, 1, 2, 3, ..., 255 -> untuk uint 8 bit (2 ^ 8)
    uint8 nomor = 255;

    // signed integer
    // -128, -127, ..., -1, 0, 1, ..., 126, 127 -> untuk int 8 bit (2 ^ 8)
    int8 number = 127;

    // unit price => wei/gwei/ether
    uint price = 0.1 ether;
    // 1000000000
    // arithmetic operator
    // +, -, /, *, %, **

    // boolean
    bool boolean = true;

    // address = 20bytes value
    address wallet1 = 0x895284A4059159E4D8e6c39df6b0Dc98e1a458EE;
    address owner;

    // bytes
    // bisa ditulis menggunakan string literal atau hexadecimal literal dengan awalan 0x
    bytes2 public sample = 0x696f;

    // string
    string iniString = "contoh string";
    string public a = unicode"Hello ð";

    // array
    uint8[] private iniArray1 = [10, 5, 8]; 
    address[] internal iniArray2 = [0x7b6803F349A39e0b88c9aC30C561c92c4354F3F5, 0x2f14912a7Ab49B7D671fd4211b23d7CE4EC85295];
    string[2] iniArray3 = ["nomor 1", "nomor 2"];

    // mapping
    mapping(uint => string) nomorKeNama;

    // enum
    enum iniEnum {pertama, kedua}

    // struct
    struct mobil {
        uint roda;
        uint8 kacaSpion;
        string merk;
        string model;
        bytes5 noSeri;
        iniEnum noModel;
    }

    mapping(string => uint) hargaMobil;

    mobil[] daftarMobil;

    mapping(uint => address) penjualanMobil;

    // event
    event mobilTerjual(mobil indexed, uint harga);

    // error
    error MobilDicuri(string waktuKejadian, uint PlatNomor);

    // constructor adalah function yang otomatis dijalankan ketika contract di deploy
    constructor(uint no, string memory nama) {
        nomorKeNama[no] = nama;
        owner = msg.sender;
    }

    modifier jumlahMobilYangDibeli(uint jumlah) {
        require(jumlah > 0, "Mobil yang dibeli minimal 1");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not allowed");
        _;
    }

    function setNomor(int8 input) public onlyOwner returns (uint8) {
        number = input;
        nomor = uint8(iniEnum.pertama);
        return nomor;
    }

    function getDariConstructor() public view returns (string memory) {
        return nomorKeNama[1];
    }

    function tambahListMobil(uint roda) external onlyOwner {
        daftarMobil.push(
            mobil({
                roda: roda,
                kacaSpion: 2,
                merk: "Toyota",
                model: "Avanza",
                noSeri: "a",
                noModel: iniEnum.pertama
            })
        );
    }

    function setHargaMobil(uint merk, uint harga) external onlyOwner {
        hargaMobil[daftarMobil[merk].model] = harga;
    }

    function _cariHargaMobil(string memory merk) private view returns (uint) {
        return hargaMobil[merk];
    }

    function cariHargaMobil(string memory merk) public view returns (uint) {
        return _cariHargaMobil(merk);
    } 

    function beliMobil() external payable {
        require(msg.value > 1 ether, "balance kurang");
        penjualanMobil[1] = msg.sender;
    }

    function getBalance() public returns (uint) {
        payable(owner).transfer(address(this).balance);
        return address(this).balance;
    }

}