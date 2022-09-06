// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "contracts/SimpleStorage_DOCTOR.sol";
contract ObjectCreation_DOCTOR {
    SimpleStorage_DOCTOR [] doctor;
    function set(string memory name, string memory location) public payable {
        doctor.push(new SimpleStorage_DOCTOR(name,location));
    }
    function FETCH_LOCATION() public view returns (string memory)  {
        string memory get_loction;
        for(uint256 pointer=0; pointer<doctor.length; pointer++){
           get_loction  = doctor[pointer].getLoc();
        }
        return get_loction;
    }
    function FETCH_NAME() public view returns (string memory)  {
        string memory get_name;
        for(uint256 pointer=0; pointer<doctor.length; pointer++){
            get_name = doctor[pointer].getName();
        }
        return get_name;
    } 
}

/*
CONTRACT NAME: SimpleStorage_DOCTOR
THIS CONTRACT SERVES AS A SINGLE CONTRACT FILE FOR : STORAGE DOCTOR META DATA
TO GET USER CAT: DOCTOR TO CREATE A NEW BLOCK CHAIN
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
contract SimpleStorage_DOCTOR {
    string  NAME; 
    string  LOCATION;
    constructor(string memory name, string memory location) {
        NAME  =     name;
        LOCATION = location;
    }
    function getLoc() external view returns (string memory) {
        return LOCATION;
    }
    function getName() external view returns (string memory)    {
        return NAME;
    }
}