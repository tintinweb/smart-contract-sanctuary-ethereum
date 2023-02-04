/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Rekber {
    address public buyer; // address buyer
    address public rekber; // address rekber
    address public seller; // address seller
    bool public isApproved; // status transaksi, secara default nilainya false.
    uint public funding;

    event Approved(uint); // membuat event Approved

    constructor(address _rekber, address _seller) payable {
        // saat contract dideploy, buyer harus mengirim dana ke smart contract
        // dan menentukan address rekber/penengah, dan address seller
        buyer = msg.sender; // address buyer adalah address yang mendeploy contract
        rekber = _rekber; // address rekber sesuai argumen yang ditentukan
        seller = _seller; // begitu juga dengan address seller;
        funding = address(this).balance; // nilai funding adalah balance contract
    }

    function approve() external {
        require(rekber == msg.sender); // memastikan bahwa yang memanggil fungsi ini adalah rekber
        (bool success, ) = seller.call{value: funding}(""); // mengirim dana pada contract seller
        require(success); // transaksi tadi harus berhasil sebelum mengeksekusi kode selanjutnya
        isApproved = true;
        emit Approved(funding); // menjalankan event Approved yang berisi informasi dana yang dikirim

    }
}