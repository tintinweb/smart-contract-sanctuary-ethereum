/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: Fair_Test.sol

pragma solidity ^0.8.17; //0xe7ff7b10d46b5da9e06f7a83646277bad69f3890adc8ed758924b5ac978b3dc0


contract Fair_Test {
    address public owner; //Define the contract owner
    uint public FarmerNumber;

    constructor() {
        owner = msg.sender; //Add contract owner at initialization
    }

//Create an object which stores all farmer data
    struct FarmerInfo {
        string Crop;
        uint AskPrice;
        string Unit;
        uint Amount;
    }

//Map farmer names to their info
    mapping (string => FarmerInfo) AllFarmers;


//Function that adds information
    function Add_Farmer_Info(string memory _Name, string memory _Crop, uint _Amount, string memory _Unit, uint  _AskPrice) public {
        //require(_Crop == "White Maize" || _Crop == "Yellow Maize", "Only white and yellow maize accepted")
        //require(AllFarmers[_Name].isValue(), "Only owner can add info");
        require(msg.sender == owner, "Only owner can add info");
        AllFarmers[_Name].Crop = _Crop;
        AllFarmers[_Name].Amount = _Amount;
        AllFarmers[_Name].AskPrice = _AskPrice;
        AllFarmers[_Name].Unit = _Unit;   
        FarmerNumber += 1;
    }


//Function that returens farmer info
    function Get_Farmer_Info(string memory _Name) public view returns(string memory) {
        return(string.concat("Farmer ", _Name, " is selling ", Strings.toString(AllFarmers[_Name].Amount), " ", AllFarmers[_Name].Unit, " of ", AllFarmers[_Name].Crop, " for ", Strings.toString(AllFarmers[_Name].AskPrice), " GHS"));
    }

    function Get_Farmer_Info2(string memory _Name) public view returns(string memory, uint, string memory,  string memory, uint) {
        return(AllFarmers[_Name].Crop, AllFarmers[_Name].Amount, AllFarmers[_Name].Unit, AllFarmers[_Name].Crop, AllFarmers[_Name].AskPrice);
    }

    function Get_Fair_Data() public view returns(string memory){
        return(string.concat("Number of Registered Farmers is ", Strings.toString(FarmerNumber)));
    }

}