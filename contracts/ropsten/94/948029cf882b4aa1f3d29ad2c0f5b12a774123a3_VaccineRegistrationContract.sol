/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.5.10;

contract VaccineRegistrationContract {
    // later go rewatch video to understand this code
    address private owner;

    // Model a vaccine 
    struct Vaccine {
        uint vaccineBatchID; 
        string vaccineBrand;
        string manufacture;
        Distributor distributor;
        string clinicHospital; 
        string transferStatus;
    }

    // Model vaccine distributor
    struct Distributor {
        string distributorName;
        address walletAddress;
    } 

    // Read/write vaccine that u register
    //became private
    mapping(uint => Vaccine) private vaccineList;
    uint public vaccineCount;

    // read/write balances
    mapping(address => uint) public balances;

    //create a getDistributor function
    // gets distributor information 
    function getDistributor(uint _vaccineBatchID) public view returns (uint vaccineBatchID, string memory vaccineBrand, string memory manufacture, string memory distributorName, string memory clinicHospital, string memory transferStatus, address _address){
        return (vaccineList[_vaccineBatchID].vaccineBatchID, vaccineList[_vaccineBatchID].vaccineBrand, vaccineList[_vaccineBatchID].manufacture, vaccineList[_vaccineBatchID].distributor.distributorName, vaccineList[_vaccineBatchID].clinicHospital, vaccineList[_vaccineBatchID].transferStatus, vaccineList[_vaccineBatchID].distributor.walletAddress );
    }

    // add specified amount of coins into a specified receiver's wallet address
    function mintCoins (address receiver, uint amount) public{
        balances[receiver] += amount;
    }

    // send specifited amount of coins from sender to receiver
    function sendCoins (address sender, address receiver, uint amount) public{
        require(amount <= balances[sender], "insufficient balance");
        balances[sender] -= amount;
        balances[receiver] += amount;
    }

    // create a register vaccine function
    // create a new vaccine registration entry and store it into the vaccine list  
    function registerNewVaccine (string memory _vaccineBrand, string memory _manufacture, string memory _distributor , string memory _clinicHospital, string memory _transferStatus, address _address, uint _amount ) public onlyOwner {

        balances[_address] -= _amount;

        //register distributor 
        vaccineCount ++;
        VaccineRegistrationContract.Distributor memory newDistributor = Distributor(_distributor, _address); //store distributor name and address
        vaccineList[vaccineCount] = Vaccine(vaccineCount, _vaccineBrand, _manufacture,  newDistributor, _clinicHospital, _transferStatus);
    }

    // create a transfer vaccine function
    
    function transferVaccine (uint _vaccineBatchID, string memory _vaccineBrand, string memory _manufacture , string memory _distributor, string memory _clinicHospital, string memory _transferStatus, address _address, uint _amount) public onlyOwner  {
        address receiver = vaccineList[_vaccineBatchID].distributor.walletAddress;
        sendCoins(_address, receiver, _amount);
        VaccineRegistrationContract.Distributor memory newDistributor = Distributor(_distributor, _address);     
        vaccineList[_vaccineBatchID] = Vaccine(_vaccineBatchID, _vaccineBrand , _manufacture, newDistributor,  _clinicHospital, _transferStatus ); 
    }

    constructor() public { 
        owner = msg.sender;  
        mintCoins(0x6a50CA1EAdc4c66ffE76592e8eB68697D0f92f31, 5000); // if change wallet amount, need to regenerate the wallet address again 
        mintCoins(0x6973144F94AaabcBc53EFe23E5d443399E24979F,10000);
        registerNewVaccine("Pfizer", "Received in America on Tuesday", "", "", "In manufacture warehouse", 0x6a50CA1EAdc4c66ffE76592e8eB68697D0f92f31, 1000);
        registerNewVaccine("Moderna",  "Received in America on Tuesday", "" ,"", "In manufacture warehouse", 0x6973144F94AaabcBc53EFe23E5d443399E24979F, 1000);
    }

// a way to reuse the required statement at multiple places
    modifier onlyOwner() {
        require(owner == msg.sender, "Only the owner can register the vaccines.");
        _; //special syntax for modifier, store a variable for the rest of the function
    }

}