/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract jenisVariable {
    // ada 3 jenis variable:
    // 1. state variable
    // ia dideklarasikan di luar function
    // juga disimpan di dalam blockchain
    string public salamHangat = "Assalamu'alaikum, pak Haji!";
    uint public angkaFavorit = 77;

    function localVariable() public view returns (uint, address) {
        // 2. local variable
        // dideklarasikan di dalam function
        // tidak disimpan di dalam blockchain
        // apakah bisa local variable ditandai sebagai public?
        // ternyata tidak bisa

        uint angkSial = 90;
        address alamatku = 0xA36ACa10170185F663C804f36e69D6BA0C62CED5;

        return (angkSial, alamatku);
    }

    function globalVariable() public view returns (uint, address) {
        // local variable juga tidak dapat digunakan di function lain.
        // return (angkSial, alamatku);

        // 3. global variable
        // digunakan untuk menujukan informasi mengenai blockchain, contohnya:

        address alamatDaku = msg.sender; // msg.sender adalah global variable,
        // menunjukan alamat pemanggil kontrak, atau function kontrak.

        uint timestamp = block.timestamp; // block.timestamp digunakan untuk
        // memberikan informasi timestamp block saat ini

        return (timestamp, alamatDaku);
    }
}