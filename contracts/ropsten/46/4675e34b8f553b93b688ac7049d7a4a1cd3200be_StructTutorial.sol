/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
// import "hardhat/console.sol";

// 28-05-22
// Enums
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 0x0000000000000000000000000000000000000000
contract StructTutorial {
    address owner;

    enum CharacterStatus {
        Uninitialized,
        Initialized,
        InitializationCancelled
    }


    struct IndividualCharacteristics {
        string name;
        bool isLearning;
        bool lovesPizza;
        uint8 classRating;
        address characterAddress;
        CharacterStatus characterStatus;
    }

    event ContractInitialized();
    event ClassInitialized();

    constructor() {
        owner = msg.sender;
        emit ContractInitialized();
    }


 

    IndividualCharacteristics[] public individualCharacteristicsArray;
    mapping(address => IndividualCharacteristics) private _characters;

    // set characteristics for each unique class participant
    function setClassCharacter(string memory _name, bool _isLearning, uint8 _classRating, bool _lovesPizza, address _account) public {
        require(_account != address(0), "cannot be zero account"); // checks non-zero address is not passed in as _account parameter
        require(_account != _characters[_account].characterAddress, "address already exists"); // checks that _account parameter is unique
        // require(_isLearning == true || false, 'cannot be other data'); // checks that only boolean values are strictly passed as parameter
        // require(_lovesPizza== true || false, 'cannot be other data'); // checks that only boolean values are strictly passed as parameter
        IndividualCharacteristics memory individualCharacteristics = IndividualCharacteristics({
            name: _name,
            isLearning: _isLearning,
            lovesPizza: _lovesPizza,
            classRating: _classRating,
            characterAddress: _account,
            characterStatus: CharacterStatus.Initialized
        });
        _characters[_account] = individualCharacteristics;
        individualCharacteristicsArray.push(individualCharacteristics);
        emit ClassInitialized();

    }

    function getIndividualClassCharacter(address _account) public view returns(IndividualCharacteristics memory) {
        return _characters[_account];

    }
   function getIndividualClassCharacterStringifiedValues(address account) public view returns(
        string memory name_, 
        bool isLearning_, 
        uint8 classRating_, 
        string memory returnedStatus, 
        address classCharacterAddress
    ) {
        require(account != address(0), "cannot be zero address");
        name_ = _characters[account].name;
        isLearning_ = _characters[account].isLearning;
        classRating_ = _characters[account].classRating;
        classCharacterAddress = _characters[account].characterAddress;
        
        uint8 enumStatusToUint = uint8(_characters[account].characterStatus);
        if(enumStatusToUint == 0) {
            returnedStatus = "Uninitialized";
        } else if(enumStatusToUint == 1) {
            returnedStatus = "Initialized";
        } else {
            returnedStatus = "InitializationCancelled";
        }

        return (name_, isLearning_, classRating_, returnedStatus, classCharacterAddress);

    }  
    function getClassArray() public view returns(IndividualCharacteristics[] memory) {
        return individualCharacteristicsArray;
    }

    function getCharacterBasedOnIndex(uint8 _index) public view returns(IndividualCharacteristics memory indvidualCharacteristics) {
        return individualCharacteristicsArray[_index];
    }

    function getStringLength(string memory _string) public pure returns(uint256) {
        bytes memory stringToBytes = bytes(_string); // typecast string to bytes
        return stringToBytes.length;
    }

    // function getCallerMetadata(address account) public view returns(
    //     bool isCallerAddressSameAsSetCharacterAddress,
    //     string memory returnedName
       
        
    // ) {
    //     string memory name_;
    //     bool isLearning_;
    //     uint8 classRating_;
    //     string memory returnedStatus;
    //     address classCharacterAddress;
    //    (name_, isLearning_, classRating_, returnedStatus, classCharacterAddress) = getIndividualClassCharacterStringifiedValues(account);
    //    console.log("name: %s", name_);
    //    console.log("is learning: %s", isLearning_);
    //    console.log("class rating: %s", classRating_);
    //    console.log("returned status: %s", returnedStatus);
    //    console.log("class character address: %s", classCharacterAddress);
      
    //     returnedName = _characters[account].name;

    //    if(msg.sender == classCharacterAddress) {
    //     isCallerAddressSameAsSetCharacterAddress =  true;  
    //     return (isCallerAddressSameAsSetCharacterAddress, returnedName);
    //    } 
           
    //    if(keccak256(bytes(_characters[msg.sender].name)) == keccak256(bytes(returnedName))) {
    //        return (isCallerAddressSameAsSetCharacterAddress, returnedName);
    //    } else {

    //     return (isCallerAddressSameAsSetCharacterAddress, _characters[account].name);
    //    }
    // }

    function isOwner(address account) public view returns(bool ownerStatus) {
        if(account == owner) return ownerStatus = true;
    }

    






}