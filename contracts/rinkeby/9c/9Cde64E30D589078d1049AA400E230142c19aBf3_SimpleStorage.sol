// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //version

// 0.8.12  //^ قبل ورژن میاد که یعنی ورژن های دیگه هم اوکی هست

contract SimpleStorage {
    // types: boolean, uint, int, address, bytes
    /* bool hasFavoritNumber = false;
    uint ffsdf = 123;
    string hasFrwerewravoritNumber = "Five";
    int hasFavorerewritNumber = -5;
    address myAdress = 0x6f1e49cB37986f9b556b2669cAEfd343279d8963;
    bytes32 haewrwersFavoritNumber = "cat";  // 0x312323j34nh234n32423 */

    // this gets initialzed to Zero!
    uint256 public favoritNumber;
    Peaple public peaple = Peaple({age: 12, name: "masih"});

    mapping(string => uint256) public nameToFavoritNumber;

    // ذخیره مجموعه داده با:
    // object
    struct Peaple {
        uint256 age;
        string name;
    }
    //array
    Peaple[] public peaple2;

    // view , pure فقط اطلاعات رو میخونند پس تاثیری بر میزان فی ندارند

    function store(uint256 _favoritNumber) public virtual {
        favoritNumber = _favoritNumber;
    }

    // ذخیره سازی
    // calldata , memory : تا زمان اجرای فانکشن ذخیره میشن
    // storage: حتی بعد از فانکشن هم ذخیره هست
    // calldate رو که بزاری دیگر اون اطلاعات قابل تغییر نیستند
    // struct, maping and arrays need to give memory or calldata.

    function addPerson(string memory _name, uint256 _age) public {
        peaple2.push(Peaple(_age, _name));
        nameToFavoritNumber[_name] = _age;
    }
}