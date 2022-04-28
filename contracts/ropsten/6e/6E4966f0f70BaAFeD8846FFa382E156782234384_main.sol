// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "Roles.sol";
import "DistributorRole.sol";
import "ManufacturerRole.sol";
import "UserRole.sol";
import "ownable.sol";

contract main is UserRole, ManufacturerRole, DistributorRole {

  // Define 'owner'
  address owner;

  // Define a variable called 'batchno' for unique authentication
  

  // Define a public mapping 'medicines' that maps the batchno to an Medicine.
  mapping (string => Medicine) medicines;

  // Define a public mapping 'medicinesHistory' that maps the UPC to an array of TxHash, 
  // that track its journey through the supply chain -- to be sent from DApp.
  mapping (string => string[]) medicinesHistory;
  
  // Define enum 'State' with the following values:
  enum State
  { 
    Made,       // 0
    Packed,     // 1
    Sold       // 2
  }

  State constant defaultState = State.Made;

  // Define a struct 'Medicine' with the following fields:
  struct Medicine {
    string  batchno;  //the primary key batchno 
    string  medicineName; //Medicine name
    string dosage;//dosage
    address ownerID;  // Metamask-Ethereum address of the current owner as the medicine moves through 3 stages
    address originManufacturerID; // Metamask-Ethereum address of the Manufacturer
    string  FactoryName; // Manufacturer Name
    string  mfgdate;//mfgdate
    string  expdate; // expdate
    State   medicineState;  // Product State as represented in the enum above
    address distributorID;  // Metamask-Ethereum address of the Distributor
    address userID; // Metamask-Ethereum address of the user
  }

  // Define 8 events with the same 7 state values and accept 'batchno' as input argument
  event Made(string _batchno);
  event Packed(string _batchno);
  event Sold(string _batchno);

  // Define a modifer that checks to see if msg.sender == owner of the contract
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }

  // Define a modifier that checks if an medicine.state of a batchno is Made
  modifier made(string storage _batchno) {
    require(medicines[_batchno].medicineState == State.Made);
    _;
  }
  
  // Define a modifier that checks if an medicine.state of a batchno is Packed
  modifier packed(string storage _batchno) {
    require(medicines[_batchno].medicineState == State.Packed);

    _;
  }

  // Define a modifier that checks if an medicine.state of a batchno is Sold
  modifier sold(string storage  _batchno) {
    require(medicines[_batchno].medicineState == State.Sold);

    _;
  }

  // Define a function 'makeMedicine' that allows a manufacturer to mark a medicine 'Made'
  function _makeMedicine(string memory _batchno, string memory _medicineName,string memory _dosage, address  _originManufacturerID,address _ownerID, string memory _FactoryName, string memory _mfgdate,string memory _expdate,State,address _distributorID,address _userID) public
  
  onlyManufacturer

  {
    // Add the new medicine as part of medicines
    Medicine memory makeMedicine = Medicine({
      batchno:_batchno,  
      medicineName:_medicineName,
      dosage:_dosage,
      originManufacturerID:_originManufacturerID,// Metamask-Ethereum address of the Manufacturer
      ownerID:_ownerID, // Metamask-Ethereum address of the current owner as the medicine moves through 3 stages
      FactoryName:_FactoryName, // Manufacturer Name
      mfgdate:_mfgdate,//mfgdate
      expdate:_expdate,//expdate
      medicineState: State.Made,
      distributorID: _distributorID, 
      userID: _userID

      });
    medicines[_batchno] = makeMedicine;
    medicines[_batchno].medicineState = State.Made;

//     string batchno;//batchno
//     address ownerID;  // Metamask-Ethereum address of the current owner as the medicine moves through 8 stages
//     address originManufacturerID; // Metamask-Ethereum address of the Manufacturer
//     string  FactoryName; // Manufacturer Name
//     string  medicineName; // Product Name
//     string  mfgdate//mfgdate
//     string  expdate//expdate
//     State   medicineState;  // Product State as represented in the enum above
//     address distributorID;  // Metamask-Ethereum address of the Distributor
//     address userID; // Metamask-Ethereum address of the Patient


    // Emit the appropriate event

    emit Made(_batchno);
  }
  // Define a function 'packMedicine' that allows a manufacturer to mark an medicine 'Packed'
  function packMedicine(string  memory _batchno) public
  onlyDistributor 
  // Call modifier to check if batchno has passed previous supply chain stage
  //Made(_batchno)
  // Call modifier to verify caller of this function
  {
    // Update the appropriate fields
    medicines[_batchno].medicineState = State.Packed;

    // Emit the appropriate event
    emit Packed(_batchno);
  }
  function receiveMedicine(string memory _batchno) public 
  onlyUser
    // Call modifier to check if batchno has passed previous supply chain stage
    //Packed(_batchno)
    // Access Control List enforced by calling Smart Contract / DApp
    {
    medicines[_batchno].medicineState = State.Sold;

    // Emit the appropriate event
    emit Sold(_batchno);
  }
  function fetchMedicineBufferOne(string memory _batchno) public view returns 
  (
    string memory batchno,  //the primary key batchno 
    string memory  medicineName, //Medicine name
    address ownerID,  // Metamask-Ethereum address of the current owner as the medicine moves through 3 stages
    address originManufacturerID, // Metamask-Ethereum address of the Manufacturer
    string memory dosage,
    //string memory FactoryName, // Manufacturer Name
    //string memory mfgdate,//mfgdate
    //string memory expdate, // expdate
    State medicineState
    ) 
  {
  // Assign values to the 7 parameters
  

  return 
  (
    medicines[_batchno].batchno,
    medicines[_batchno].medicineName,
    medicines[_batchno].ownerID,
    medicines[_batchno].originManufacturerID,
    medicines[_batchno].dosage,
    //medicines[_batchno].mfgdate,
    //medicines[_batchno].expdate,
    medicines[_batchno].medicineState
    // medicines[_batchno].
    );
}
function fetchMedicineBufferTwo(string memory _batchno) public view returns 
  (
    string memory batchno,  //the primary key batchno 
    //string memory  medicineName, //Medicine name
    //address ownerID,  // Metamask-Ethereum address of the current owner as the medicine moves through 3 stages
    //address originManufacturerID, // Metamask-Ethereum address of the Manufacturer
    string memory FactoryName, // Manufacturer Name
    string memory mfgdate,//mfgdate
    string memory expdate, // expdate
    //State medicineState,
    address distributorID,
    address userID
    ) 
  {
  // Assign values to the 7 parameters
  

  return 
  (
    medicines[_batchno].batchno,
    //medicines[_batchno].medicineName,
    //medicines[_batchno].ownerID,
    //medicines[_batchno].originManufacturerID,
    medicines[_batchno].FactoryName,
    medicines[_batchno].mfgdate,
    medicines[_batchno].expdate,
    //medicines[_batchno].medicineState,
    medicines[_batchno].distributorID,
    medicines[_batchno].userID
    // medicines[_batchno].
    );
}
}