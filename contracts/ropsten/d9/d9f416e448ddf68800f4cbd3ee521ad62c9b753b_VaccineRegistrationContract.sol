/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.5.10;

contract VaccineRegistrationContract {
    address private owner;

    struct Vaccine {
        uint vaccineBatchID; 
        string vaccineBrand;
        string manufacture;
        Distributor distributor;
        string clinicHospital; 
        string transferStatus;
    }

    struct Distributor {
        string distributorName;
        address walletAddress;
    } 

    mapping(uint => Vaccine) private vaccineList;
    uint public vaccineCount;

    mapping(address => uint) public balances;

    function getDistributor(uint _vaccineBatchID) public view returns (uint vaccineBatchID, string memory vaccineBrand, string memory manufacture, string memory distributorName, string memory clinicHospital, string memory transferStatus, address _address){
        return (vaccineList[_vaccineBatchID].vaccineBatchID, vaccineList[_vaccineBatchID].vaccineBrand, vaccineList[_vaccineBatchID].manufacture, vaccineList[_vaccineBatchID].distributor.distributorName, vaccineList[_vaccineBatchID].clinicHospital, vaccineList[_vaccineBatchID].transferStatus, vaccineList[_vaccineBatchID].distributor.walletAddress );
    }

    function mintCoins (address receiver, uint amount) public{
        balances[receiver] += amount;
    }
    function sendCoins (address sender, address receiver, uint amount) public{
        require(amount <= balances[sender], "insufficient balance");
        balances[sender] -= amount;
        balances[receiver] += amount;
    }

    function registerNewVaccine (string memory _vaccineBrand, string memory _manufacture, string memory _distributor , string memory _clinicHospital, string memory _transferStatus, address _address, uint _amount ) public onlyOwner {
        balances[_address] -= _amount;

        vaccineCount ++;
        VaccineRegistrationContract.Distributor memory newDistributor = Distributor(_distributor, _address);
        vaccineList[vaccineCount] = Vaccine(vaccineCount, _vaccineBrand, _manufacture,  newDistributor, _clinicHospital, _transferStatus);
    }

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
        registerNewVaccine("Pfizer", "Received in America on Tuesday", "a", "Singapore General Hospital", "Exported", 0x6a50CA1EAdc4c66ffE76592e8eB68697D0f92f31, 1000);
        registerNewVaccine("Moderna",  "Received in America on Tuesday", "a" ,"Singapore General Hospital", "Still in warehouse", 0x6973144F94AaabcBc53EFe23E5d443399E24979F, 1000);
    }

// a way to reuse the required statement at multiple places
    modifier onlyOwner() {
        require(owner == msg.sender, "Only the owner can register the vaccines.");
        _; //special syntax for modifier, store a variable for the rest of the function
    }

   
}