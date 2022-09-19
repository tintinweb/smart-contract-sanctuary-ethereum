/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HelloPet{
    string PetName;
    string PetAge;
    
    struct MainInfo{
        string name;
        string phone;
    }
    MainInfo public main1 =  MainInfo("John","123456789");
    string onwer;

    function AddOrUpdatePetInformation(string memory _PetName,string memory _PetAge,string memory _MainInfo) public {
        PetName = _PetName;
        PetAge = _PetAge;
        onwer = _MainInfo;
    }

    function SearchPet() public view returns(string memory){
        return string(abi.encodePacked("hello world,My Name is ", PetName, "I m", PetAge, "years old,My main person is ",onwer));
    }

}