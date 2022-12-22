//SPDX-License-Identifier: 0BSD
//Specifies the version of Solidity, using semantic versioning.
pragma solidity >=0.8.17; //Solidity last version


contract insureTech {

   enum PolicyType { yearly, monthly }
   mapping(uint256 => InsuranceConditionsData) internal _insurance;
   address public _owner; // address of the intializer of the contract, this address has more access permissions
   uint internal _insuranceCount=0;

   event LogNewInsuranceConditionsCreated(
        uint expiryDate, 
        uint price
    );
   
   struct InsuranceConditionsData{
        uint expiryDate; // Insure Expiry date
        uint price; // Price
    }

    constructor() {
        _owner = msg.sender;
    }

    modifier ownerOnly() { //This modifier verifies that the owner is who calls a function
        require(
            _owner == msg.sender,
            "Error: Only owner can access this function."
        );
        _;
    }
    function createNewInsuranceConditions(
        uint _expiryDate,
        uint _price) external ownerOnly {
        InsuranceConditionsData memory insuranceConditionsData = InsuranceConditionsData(
            _expiryDate,
            _price
        );
        //Verifies that the expiration date is valid, this means that cannot be less than the current date
        if (_expiryDate<block.timestamp){
            revert("Error: Expiration date is less than the current date");
        }
        //Verifies that the price is valid, this means that is more than 0
        if (_price==0){
            revert("Error: Price cannot be 0");
        }

        _insuranceCount++;
        _insurance[_insuranceCount] = insuranceConditionsData;

        emit LogNewInsuranceConditionsCreated(
            _expiryDate, 
            _price);
    }

    function getInsuranceConditionsData(uint idInsuranceConditions)
        external
        view
        ownerOnly
        returns (InsuranceConditionsData memory)
    {
        if(_insurance[idInsuranceConditions].price==0){
            revert("Error: insurance does not exits");
        }else{
         return _insurance[idInsuranceConditions];
        }
    }

    function getInsuranceCount () external
        view
        ownerOnly
        returns (uint _counter){
            return _insuranceCount;
        }
}