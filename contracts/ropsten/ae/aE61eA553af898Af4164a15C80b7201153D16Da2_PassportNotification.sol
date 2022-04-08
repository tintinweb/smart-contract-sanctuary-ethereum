//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract PassportNotification {
    address public owner;
    uint public passId;
    string public name;
    uint public age;

    struct Info {
        Demgraphic[] informations;
    }
    struct Demgraphic{
        string name;
        uint256 age;
    }
    int constant SECONDS_PER_DAY = 24 * 60 * 60;

    struct PassportInfo {
        address user;
        PassportInput[] info;
    }

    struct PassportInput {
        string name;
        string email;
        string passportNumber;
        uint256 expireDate;
        uint256 notifyBefore;
        uint256 emailSendOn;
    }
    struct Passport{
        uint id;
        uint256 createdOn;
        PassportInput info;
    }

    struct PassportName{
        string name;
        uint256 expireDate;

    }

    Passport[] public passports;


    constructor(){
        owner = msg.sender; // store information who deployed contract
    }

    function isTodayDate(uint256 date) view public  returns(bool) {
        uint _block = block.timestamp;
        uint _today = date + 1 days - 1 days;
        return (_block == _today);
    }

    function diffDays(int first, int second)  public pure  returns(int) {
        int res =  first  - second;
        return res/SECONDS_PER_DAY;
    }

    function getPassports() public view returns(Passport[] memory) {
        uint256 resultCount;
        for (uint i = 0; i < passports.length; i++) {
            if(block.timestamp > passports[i].info.emailSendOn){
                uint256 diff = (block.timestamp -  passports[i].info.emailSendOn) /60/60/24;
                if (diff < 1) {
                    resultCount++;  // step 1 - determine the result count
                }
            }
        }

        Passport[] memory result = new Passport[](resultCount);  // step 2 - create the fixed-length array
        uint256 j;

        for (uint i = 0; i < passports.length; i++) {
            if(block.timestamp > passports[i].info.emailSendOn){
                uint256 diff = (block.timestamp -  passports[i].info.emailSendOn) /60/60/24;
                if (diff < 1) {
                    result[j] = passports[i];  // step 3 - fill the array
                    j++;
                }
            }
        }

        return result; // step 4 - return
    }


    function savePassportInfo(PassportInput[] memory input) public returns (Passport[] memory infoData) {
        for(uint256 i =0; i< input.length; i++){
            passId++;
            Passport memory info =  Passport(passId,block.timestamp, input[i]);
            passports.push(info);
        }
        return passports;
    }
    Demgraphic [] public values;

    function saveNewInfo(Demgraphic[] memory input) public {
        for(uint256 i =0; i< input.length; i++){
            Demgraphic memory d  = Demgraphic(input[i].name, input[i].age);
            values.push(d);
        }
    }

    function getAllPassportInfo()  public view returns (Passport[] memory info){
        return passports;
    }

}