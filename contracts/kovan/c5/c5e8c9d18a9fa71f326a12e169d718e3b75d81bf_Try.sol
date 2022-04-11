/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Try{

    bool private isThereAnyDept = false;
    uint256 private dept;
    uint private passwordOfDept;
    uint private digitOfDept;
    uint private dayDiff;
    uint private interest;
    uint private startDate;
    uint private endDate = 1648857600; // 1649980800 -> 15.04.2022 00.00.00


    constructor(){
        startDate = block.timestamp; // anlik zamani aliyor ve startDate degiskenine epoch seklinde atama yapiyor
        interest = 3; //  gunluk yuzde 3 faiz oldugunu dusunuyorum
        digitOfDept = 1; // borcun digitini simdilik 1 olarak atiyorum
    }

    // Kullanicidan borc degerini aliyoruz
    function enterYourDept(uint256 _dept) public{
        dept = _dept;
    }

    // CompareDates fonksiyonunda elimizdeki tarihleri karsilastirip, borc olunup olunmadigina bakiyorum
    function compareDates() public{
        if(endDate > startDate){ // borc yok
            dayDiff = (endDate - startDate) / 3600 / 24;
        }
        else{ // borc var
            dayDiff = (startDate - endDate) / 3600 / 24;
            isThereAnyDept = true;
            for(uint i=1; i<=dayDiff; i++){
                dept = dept + (dept * interest) / 100;
            }
        }
    }

    // Kullanicinin borcunu gosterir
    function getDept() public view returns(uint256){
        return dept;
    }

    // Kullanicinin borclu olup olmadigini gosterir
    function isUserHasDept() public view returns (string memory){
        if(isThereAnyDept == true)
            return "Borclu";
        else
            return "Faiz Borcu yok";
    }

    // Kullanicinin borclu oldugu gun sayisini gosterir
    function showDayDiff() public view returns (uint){
        if(isThereAnyDept == true)
            return dayDiff;
        else
            return 0;
    }

    // Kullanicinin borcunu kendi algoritmam ile sifreleyecegim
    function encrypt() public{
        uint temp = dept;
        uint digit;
        uint tempPassword = 0;

        while(temp > 10){
            digit = temp % 10;
            temp = temp / 10;

            tempPassword += digit * (2**digitOfDept);
            digitOfDept++;

        }
        digit = temp % 10;
        tempPassword = tempPassword + digit * (2**digitOfDept);

        passwordOfDept = tempPassword;
    }

    // Sifrelenmis borcu dondurur
    function showEncrypt() public view returns (uint){
        return passwordOfDept;
    }
}