/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract RealEstate {

    
    /************************************************
                        variables
    ************************************************/
    address public Owner;
    uint public OwnerFee = 2000000000000000000;
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

    struct BuyerRequestInformation {
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
    mapping( uint => PreviousOwner ) public previousOwner;
    mapping( uint => BuyerRequestInformation ) public buyerRequestInformation;

    mapping( uint => string ) public PurchasedDate;
    mapping( uint => string ) public requestForBuyDate;
    mapping( uint => string ) public requestForBuyDateIFAccepted;

    mapping( address => uint[] ) public userAllPropertiesIDs;
    mapping( address => uint[] ) public userAllPurchasedPropertiesIDs;

    mapping( uint => bool ) public PendingForSell;
    mapping( uint => bool ) public AcceptedForSell;
    mapping( uint => bool ) public DeclinedForSell;
    
    mapping( uint => bool ) public PendingforBuy;
    mapping( uint => bool ) public AcceptedforBuy;
    mapping( uint => bool ) public DeclinedforBuy;

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

        PendingForSell[PropertyID] = true;

        emit _Pending( PropertyID );
        emit _addProperty( msg.sender, _Price );

    }

    function requestForBuyProperty( 
        
        uint          _PropertyID,
        string memory _FullName,
        string memory _Address,
        string memory _Phone,
        string memory _Date,
        string memory _DateIFAccepted

    ) external payable {

        require (
            AcceptedForSell[_PropertyID],
            "Real Estate: There is no such property for sell."
        );

        require (
            properties[_PropertyID].Price == msg.value,
            "Real Estate: Please Add Valid Amount"
        );

        (bool success, ) = (address(this)).call{value: msg.value}("");
        require(success, "Real Estate: Failed to send Ether");

        buyerRequestInformation[_PropertyID] = BuyerRequestInformation (
            _PropertyID, _FullName, _Address, _Phone, msg.sender
        );

        requestForBuyDate[_PropertyID] = _Date;
        requestForBuyDateIFAccepted[_PropertyID] = _DateIFAccepted;

        AcceptedForSell[_PropertyID] = false;
        PendingforBuy[_PropertyID] = true;

    }

    function BuyProperty( uint _PropertyID ) external {

        require (
            AcceptedforBuy[_PropertyID],
            "Real Estate: There is no such property for sell."
        );

        require (
            buyerRequestInformation[_PropertyID].CurrentOwner == msg.sender,
            "Real Estate: Please Add Valid Amount"
        );

        uint _ethValue = ((properties[_PropertyID].Price) - OwnerFee);
        (bool Osuccess, ) = (Owner).call{value: OwnerFee}("");
        (bool success, ) = (properties[_PropertyID].CurrentOwner).call{value: _ethValue}("");
        require(Osuccess, "Real Estate: Failed to send Ether");
        require(success, "Real Estate: Failed to send Ether");

        previousOwner[_PropertyID] = PreviousOwner (
            _PropertyID,
            properties[_PropertyID].FullName,
            properties[_PropertyID].Address,
            properties[_PropertyID].Phone,
            properties[_PropertyID].CurrentOwner
        );

        PurchasedDate[_PropertyID] = requestForBuyDateIFAccepted[_PropertyID];
        userAllPurchasedPropertiesIDs[msg.sender].push(_PropertyID);

        properties[_PropertyID].FullName = buyerRequestInformation[_PropertyID].FullName;
        properties[_PropertyID].Address = buyerRequestInformation[_PropertyID].Address;
        properties[_PropertyID].Phone = buyerRequestInformation[_PropertyID].Phone;
        properties[_PropertyID].CurrentOwner = buyerRequestInformation[_PropertyID].CurrentOwner;

        AcceptedforBuy[_PropertyID] = false;
        Sold[_PropertyID] = true;

        emit _Sold( _PropertyID );
        emit _ownershipTransferred( _PropertyID, msg.sender );

    }


    /************************************************
                        onlyOwner function
    ************************************************/
    function AcceptSellerRequest( uint _PropertyID ) external onlyOwner {

        require(
            !AcceptedForSell[_PropertyID],
            "Real Estate: You already Accepted this property"
        );

        PendingForSell[_PropertyID] = false;
        AcceptedForSell[_PropertyID] = true;

        emit _Accepted( _PropertyID );

    }

    function DeclineSellerRequest( uint _PropertyID ) external onlyOwner {

        require(
            !DeclinedForSell[_PropertyID],
            "Real Estate: You already Declined this property"
        );

        PendingForSell[_PropertyID] = false;
        DeclinedForSell[_PropertyID] = true;

        emit _Declined( _PropertyID );

    }

    function AcceptBuyerRequest( uint _PropertyID ) external onlyOwner {

        require(
            !AcceptedForSell[_PropertyID],
            "Real Estate: You already Accepted this property"
        );

        PendingforBuy[_PropertyID] = false;
        AcceptedforBuy[_PropertyID] = true;

        emit _Accepted( _PropertyID );

    }

    function DeclineBuyerRequest( uint _PropertyID ) external onlyOwner {

        require(
            !DeclinedForSell[_PropertyID],
            "Real Estate: You already Declined this property"
        );

        AcceptedForSell[_PropertyID] = true;
        DeclinedforBuy[_PropertyID] = true;
        PendingforBuy[_PropertyID] = false;

        emit _Declined( _PropertyID );

    }

    function updateOwnerFee( uint _OwnerFee ) external onlyOwner {
        OwnerFee = _OwnerFee;
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