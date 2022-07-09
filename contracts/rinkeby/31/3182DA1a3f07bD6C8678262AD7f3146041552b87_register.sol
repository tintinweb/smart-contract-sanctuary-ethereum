// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //THIS WILL DEFINE SOLIDITY VERSION

contract register {
    uint256 addUniversityNumber; //this type and variable can be used for the whole code

    struct bio {
        uint256 rollno;
        string name; //THIS IS TO MAKE A SPECIFIC CLASS TO STORE ALL FUNCTION
        uint256 class;
    }

    bio[] public CheckAcadmeicInfo; //ARRAY TO TAKE ALL THE DATA of many people
    mapping(uint256 => string) public findname; //IN A SINGEL BUTTON

    function RegistrationNumber(uint256 UniversityNumber) public virtual {
        //virtual for override
        addUniversityNumber = UniversityNumber; //FUNCTION TO STORE DATA
    }

    function SeeRegistration() public view returns (uint256) {
        return addUniversityNumber; //FUCTION TO RETERIVE DATA
    }

    function AcadmeicInfo(
        uint256 Rollno,
        string memory Name,
        uint256 Class
    ) public {
        CheckAcadmeicInfo.push(bio(Rollno, Name, Class)); //FUNCTION TO STORE ARRAY
        findname[Rollno] = Name;
    }
}