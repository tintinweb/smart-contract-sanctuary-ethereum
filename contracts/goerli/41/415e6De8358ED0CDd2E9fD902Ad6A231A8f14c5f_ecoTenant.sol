//SPDX-License-Identifier: 0BSD
/// @author Exsis Digital Angels
/// @dev Specifies the version of Solidity, using semantic versioning.
pragma solidity >=0.8.17; //Solidity last version

contract ecoTenant {

    enum typeTenant { owner, renter, investor }
    mapping(uint256 => EcoTenantData) internal _tenants;
    address public _owner; // address of the intializer of the contract, this address has more access permissions
    uint internal _tenantsCount=0;

   struct EcoTenantData {
        string idAuth0; // user ID Auth0
        string name; // user name
        string email; // user email
        string company; // user company
        uint mortageLength; // mortage int months
        uint age; // user age
        uint mortagePrice; // mortage price
        uint lotDimension; // lot dimension
        uint expiryDate; // expiry date
    }
    event LogNewTenantCreated(
        string idAuth, 
        string name, 
        string email, 
        string company,
        uint mortageLength,
        uint age,
        uint mortagePrice,
        uint lotDimension,
        uint expiryDate
    );

   
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

    modifier idAuth0Validation(string memory _idAuth0) { //This modifier verifies if a tenant exsists
        require(bytes(_idAuth0).length>=21 && bytes(_idAuth0).length<=24 ,"The provided idAuth0 is invalid.");
        _;
    }

    function createNewTenant(
        string memory _idAuth0,
        string memory _name,
        string memory _email,
        string memory _company,
        uint _mortageLength,
        uint _age,
        uint _mortagePrice,
        uint _lotDimension,
        uint _expiryDate) external ownerOnly idAuth0Validation(_idAuth0) {
        EcoTenantData memory ecoTenantData = EcoTenantData(
            _idAuth0,
            _name,
            _email,
            _company,
            _mortageLength,
            _age,
            _mortagePrice,
            _lotDimension,
            _expiryDate
        );

        /// @dev Verifies that the expiration date is valid, this means that cannot be less than the current date
        if (_expiryDate<block.timestamp){
            revert("Error: Expiration date is less than the current date");
        }

        /// @dev Verifies that a tenant with the auth0 id was not created before
        if(searchIdAuth0(_idAuth0)){
            revert("Error: a tenant with the idAuth0 provided already exists");
        }


        _tenantsCount++;
        _tenants[_tenantsCount] = ecoTenantData;

        emit LogNewTenantCreated(
            _idAuth0,
            _name,
            _email,
            _company,
            _mortageLength,
            _age,
            _mortagePrice,
            _lotDimension,
            _expiryDate
        );
    }
    /// @dev Gets the tenant data with the idAuth0 provided
    function getTenantByIdAuth0(string memory _idAuth0)
        external
        ownerOnly
        returns (string memory,string memory,string memory,string memory,uint,uint,uint,uint,uint)
    {
        uint position=0;
        bool found=false;
        for (uint i=0; i<=_tenantsCount; i++){
            
            if(keccak256(abi.encodePacked(_tenants[i].idAuth0)) == keccak256(abi.encodePacked(_idAuth0))){
                position = i;
                found = true;
            }
        }
        if(!found){
            revert("Error: No tenant found");
        }else{
            return (_tenants[position].idAuth0,_tenants[position].name,
            _tenants[position].email,_tenants[position].company,
            _tenants[position].mortageLength,_tenants[position].age,
            _tenants[position].mortagePrice,_tenants[position].lotDimension,
            _tenants[position].expiryDate);
        }
    }
    /* Temporary unused function
    function getTenantbyId(uint256 tenantId)
        external
        view
        ownerOnly
        returns (EcoTenantData memory)
    {
        if(keccak256(abi.encodePacked(_tenants[tenantId].name)) == keccak256(abi.encodePacked(""))){
            revert("Error: tenant does not exits");
        }else{
         return _tenants[tenantId];
        }
    }
    */
    ///@dev Search if the idAuth0 already exists in the contract 
    function searchIdAuth0 (string memory _idAuth0) internal view returns (bool _found){
    for (uint i=0; i<=_tenantsCount; i++){
            if(keccak256(abi.encodePacked(_tenants[i].idAuth0)) == keccak256(abi.encodePacked(_idAuth0))){
            return true;
            }
        }
        return false;
    }
    /// @dev Gets the number of tenants registered in the contract
    function getTenantsCount () external
        view
        ownerOnly
        returns (uint _counter){
            return _tenantsCount;
        }
}