/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract RealEstate {

    
    /************************************************
                        variables
    ************************************************/
    address public Owner;
    uint public OwnerFee;
    uint public PropertyID;

    
    /************************************************
                        constructor
    ************************************************/
    constructor() {
        Owner = msg.sender;
    }

    
    /************************************************
                        struct
    ************************************************/
    struct Property {
        uint    propertyID;
        uint    Price;

        string  FullName;
        string  Address;
        string  Phone;
        address CurrentOwner;

        string  PropertyName;
        string  PropertyType;
        string  PropertyAddress;
        string  AdditionalInformation;
    }

    struct PreviousOwner {
        uint    propertyID;

        string  FullName;
        string  Address;
        string  Phone;
        address CurrentOwner;
    }

    
    /************************************************
                        mappings
    ************************************************/
    mapping( uint => Property ) public properties;
    mapping( uint => PreviousOwner ) previousOwner;
    mapping( uint => string ) PurchasedDate;
    mapping( address => uint[] ) userAllPropertiesIDs;
    mapping( address => uint[] ) userAllPurchasedPropertiesIDs;

    mapping( uint => bool ) public Pending;
    mapping( uint => bool ) public Accepted;
    mapping( uint => bool ) public Declined;
    mapping( uint => bool ) public Sold;


    /************************************************
                        modifier
    ************************************************/
    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }


    /************************************************
                        event
    ************************************************/
    event _Sold( uint PropertyID );
    event _Pending( uint PropertyID );
    event _Accepted( uint PropertyID );
    event _Declined( uint PropertyID );
    event _addProperty( address _Owner, uint Price );
    event _ownershipTransferred( uint PropertyID, address Owner );


    /************************************************
                        function
    ************************************************/
    function addProperty(

        uint          _Price,
        string memory _FullName,
        string memory _Address,
        string memory _Phone,
        string memory _PropertyName,
        string memory _PropertyType,
        string memory _HouseAddress,
        string memory _AdditionalInformation

    ) external {

        PropertyID++;
        properties[PropertyID] = Property(
            PropertyID, (_Price + OwnerFee),
            _FullName, _Address, _Phone, msg.sender,
            _PropertyName, _PropertyType, _HouseAddress, _AdditionalInformation
        );

        userAllPropertiesIDs[msg.sender].push(PropertyID);

        Pending[PropertyID] = true;

        emit _Pending( PropertyID );
        emit _addProperty( msg.sender, _Price );

    }

    function buyProperty( 
        
        uint          _PropertyID,
        string memory _FullName,
        string memory _Address,
        string memory _Phone,
        string memory _Date

    ) external payable {

        require (
            Accepted[_PropertyID],
            "Real Estate: There is no such property for sell."
        );

        require (
            properties[_PropertyID].Price == msg.value,
            "Real Estate: Please Add Valid Amount"
        );

        uint _ethValue = ((msg.value) - OwnerFee);
        (bool Osuccess, ) = Owner.call{value: OwnerFee}("");
        (bool success, ) = properties[_PropertyID].CurrentOwner.call{value: _ethValue}("");
        require(Osuccess, "Real Estate: Failed to send Ether");
        require(success, "Real Estate: Failed to send Ether");

        previousOwner[_PropertyID] = PreviousOwner (
            _PropertyID,
            properties[_PropertyID].FullName,
            properties[_PropertyID].Address,
            properties[_PropertyID].Phone,
            properties[_PropertyID].CurrentOwner
        );

        PurchasedDate[_PropertyID] = _Date;
        userAllPurchasedPropertiesIDs[msg.sender].push(_PropertyID);

        properties[_PropertyID].FullName = _FullName;
        properties[_PropertyID].Address = _Address;
        properties[_PropertyID].Phone = _Phone;
        properties[_PropertyID].CurrentOwner = msg.sender;

        Accepted[_PropertyID] = false;
        Sold[_PropertyID] = true;

        emit _Sold( _PropertyID );
        emit _ownershipTransferred( _PropertyID, msg.sender );

    }


    /************************************************
                        onlyOwner function
    ************************************************/
    function Accepts( uint _PropertyID ) external onlyOwner {

        require(
            !Accepted[_PropertyID],
            "Real Estate: You already Accepted this property"
        );

        Pending[_PropertyID] = false;
        Accepted[_PropertyID] = true;

        emit _Accepted( _PropertyID );

    }

    function Decline( uint _PropertyID ) external onlyOwner {

        require(
            !Declined[_PropertyID],
            "Real Estate: You already Declined this property"
        );

        Pending[_PropertyID] = false;
        Declined[_PropertyID] = true;

        emit _Declined( _PropertyID );

    }

    function ChangeOwner(address _Owner) external onlyOwner {
        Owner = _Owner;
    }


    /************************************************
                        view function
    ************************************************/
    function getUserAllpropertiesIDs(address _user) public view returns( uint[] memory _IDs ) {
        return userAllPropertiesIDs[_user]; 
    }

    function getUserAllPurchasedPropertiesIDs(address _user) public view returns( uint[] memory _IDs ) {
        return userAllPurchasedPropertiesIDs[_user]; 
    }


    /************************************************
                        Fallback function
    ************************************************/
    receive() external payable {}
    fallback() external payable {}

}