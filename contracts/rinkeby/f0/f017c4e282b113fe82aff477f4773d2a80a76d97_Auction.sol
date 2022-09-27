/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

pragma solidity ^0.8.7;

contract Auction {
    address public owner; //Define the contract owner

    constructor() {
        owner = msg.sender; //Add contract owner at initialization
    }

//Create an object which stores all farmer data
    struct FarmerInfo {
        string Crop;
        uint AskPrice;
        string Address;
    }

//Map farmer names to their info
    mapping (string => FarmerInfo) AllFarmers;


//Function that adds information
    function AddFarmerInfo(string memory _Name, string memory _Crop, uint  _AskPrice, string memory _Address) public {
        //require(_Crop == "White Maize" || _Crop == "Yellow Maize", "Only white and yellow maize accepted")
        //require(bytes(_Name).length>0, "Name not entered");
        AllFarmers[_Name].Crop = _Crop;
        AllFarmers[_Name].AskPrice = _AskPrice;
        AllFarmers[_Name].Address = _Address;   
    }


//Function that returens farmer info
    function GetFarmerInfo(string memory _Name) public view returns(string memory, uint, string memory) {
        return(AllFarmers[_Name].Crop, AllFarmers[_Name].AskPrice, AllFarmers[_Name].Address);
    }


}