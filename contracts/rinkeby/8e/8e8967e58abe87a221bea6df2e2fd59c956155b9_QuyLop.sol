/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract QuyLop {
    struct SinhVien {
        address _Vi;
        string _HoTen;
        uint _Tien;
    }

    SinhVien[] private mangSinhVien;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function dongTien(string memory hoTen) public payable {
        require(msg.value>=1000000000000000, "So tien gui phai > 0.001 ETH");
        SinhVien memory sinhVienMoi = SinhVien(msg.sender, hoTen, msg.value);
        mangSinhVien.push(sinhVienMoi);
    }

    function rutTien() public {
        require(msg.sender==owner, "Ban khong duoc phep rut tien");
        require(address(this).balance>0, "Vi chua co tien");
        payable(owner).transfer(address(this).balance);
    }

    function dem_so_sinh_vien() public view returns(uint) {
        return mangSinhVien.length;
    }

    function thong_tin_mot_sinh_vien(uint thuTu) public view returns(address, string memory, uint) {
        return(mangSinhVien[thuTu]._Vi, mangSinhVien[thuTu]._HoTen, mangSinhVien[thuTu]._Tien);
    }

    function tong_tien() public view returns(uint) {
        return address(this).balance;
    }

}