/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Parcel_land {
    uint parcel_no;
    string owner_name;
    uint price;
    uint area;
}

// ภาระผูกพันของธนาคาร
struct OlgtBank {
    uint parcel_no;
    string olgt_name;
    uint olgt_price;
}

contract Parcel {
    address staff; //เจ้าหน้าที่สำนักงานที่ดิน
    mapping(address=>Parcel_land) _parcel_land;
    mapping(address=>OlgtBank) _olgt_bank;

    constructor() {
        staff = msg.sender;
    }

    modifier isStaff {
        require(msg.sender == staff, "You are not landoffice staff.");
        _;
    }

    // สร้างจดทะเบียนโฉนดที่ดิน
    function createParcel(address owner, uint parcel_no, string memory owner_name, uint price, uint area) isStaff public {
       _parcel_land[owner].parcel_no = parcel_no;
       _parcel_land[owner].owner_name = owner_name;
       _parcel_land[owner].price = price;
       _parcel_land[owner].area = area;
    }

    function getParcel(address owner) isStaff public view returns (Parcel_land memory parcel_land) {
        return _parcel_land[owner];
    }

    function getOlgt(address owner) isStaff public view returns (OlgtBank memory olgt) {
        return _olgt_bank[owner];
    }

    // จำนอง + เปลี่ยนผู้ถือกรรมสิทธิ์เป็นธนาคาร
    function mortgage(address owner, address bank, uint parcel_no, string memory owner_name) isStaff public payable  {
        _parcel_land[owner].owner_name = owner_name;
        _olgt_bank[owner].parcel_no = parcel_no;
        _olgt_bank[owner].olgt_name = owner_name;
        _olgt_bank[owner].olgt_price = msg.value;

        // โอนเงินจำนองให้ธนาคาร (หน่วยเป็น ETH)
        payable(bank).transfer(msg.value);
    }

    // ไถ่ถอนจำนอง + เปลี่ยนผู้ถือกรรมสิทธิ์เป็นเจ้าของเดิม
    function redeem(address owner, string memory owner_name, uint price) isStaff public  {
        require(_olgt_bank[owner].olgt_price < price, "Insufficient fund for redeem.");
        _parcel_land[owner].owner_name = owner_name;
        _olgt_bank[owner].parcel_no = 0;
        _olgt_bank[owner].olgt_name = "";
        _olgt_bank[owner].olgt_price = 0;
    }

}