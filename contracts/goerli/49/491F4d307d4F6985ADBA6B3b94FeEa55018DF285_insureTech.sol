//SPDX-License-Identifier: 0BSD
/// @author Exsis Digital Angels
/// @dev Specifies the version of Solidity, using semantic versioning.
pragma solidity >=0.8.17; //Solidity last version


contract insureTech {

   enum PolicyType { yearly, monthly }
   mapping(uint256 => InsuranceConditionsData) internal _insurance;
   
   address public _owner; /// @dev address of the intializer of the contract, this address has more access permissions
   uint internal _insuranceCount=0;

   event LogNewInsuranceConditionsCreated(
        string idAuth0,
        uint expiryDate, 
        uint price
    );
   
   struct InsuranceConditionsData{
        string idAuth0; // Auth0 id
        uint expiryDate; // Insure Expiry date
        uint price; // Price
    }

    constructor() {
        _owner = msg.sender;
    }

    modifier ownerOnly() { /// @dev This modifier verifies that the owner is who calls a function
        require(
            _owner == msg.sender,
            "Error: Only owner can access this function."
        );
        _;
    }
    function createNewInsuranceConditions(
        string memory _idAuth0,
        uint _expiryDate,
        uint _price) external ownerOnly {
        InsuranceConditionsData memory insuranceConditionsData = InsuranceConditionsData(
            _idAuth0,
            _expiryDate,
            _price
        );
        ///@dev Verifies that the expiration date is valid, this means that cannot be less than the current date
        if (_expiryDate<block.timestamp){
            revert("Error: Expiration date is less than the current date");
        }
        ///@dev Verifies that the price is valid, this means that is more than 0
        if (_price==0){
            revert("Error: Price cannot be 0");
        }

        _insuranceCount++;
        _insurance[_insuranceCount] = insuranceConditionsData;

        emit LogNewInsuranceConditionsCreated(
            _idAuth0,
            _expiryDate,
            _price);
    }

    /*
    Temporary unused function
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
    }*/
    
    function getInsuranceDataByIdAuth0(string memory _idAuth0)
    external
    returns (InsuranceConditionsData[] memory insurances){
        InsuranceConditionsData[] memory insurancesByIdAuth0 = new InsuranceConditionsData[](_insuranceCount);
        bool found = false;
        uint256 u = 0;
        for (uint i=0; i <= _insuranceCount; i++){
            if(keccak256(abi.encodePacked(_insurance[i].idAuth0)) == keccak256(abi.encodePacked(_idAuth0))){
                InsuranceConditionsData storage insur = _insurance[i];
                insurancesByIdAuth0[u]=insur;
                found = true;
                u++;
            }                     
        }
        if(!found){
            revert("Error: No insurances found");
        }else{
            return insurancesByIdAuth0;
        }
    }

    function getInsuranceCount () external
        view
        ownerOnly
        returns (uint _counter){
            return _insuranceCount;
        }
}