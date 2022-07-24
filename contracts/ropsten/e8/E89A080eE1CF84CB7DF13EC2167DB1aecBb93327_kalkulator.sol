/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// dAPP (Decentralized Application) Sederhana
// Kalkulator Online
pragma solidity 0.8.15;
contract kalkulator{
    // Kata dari public berfungsi agar fungsi ini dapat di interaksikan dengan menggunakan etherscan
    int public hasil;

    function tambah(int a,int b) public{
        hasil = a + b;
    }
    function kurang(int a, int b) public {
        hasil = a - b;
    }
    function kali (int a,int b) public{
        hasil = a * b;
    }
    function bagi (int a,int b) public{
        // Diperlukan syarat B != 0
        // Jika terjadi, batalkan transaksi dan kembalikan dengan hasil kalau "Tidak bisa membagi dengan angka nol"
        require(b != 0, "Tidak bisa membagi dengan angka nol");
        hasil = a / b;
    }

}