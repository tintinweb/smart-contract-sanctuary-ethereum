// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

// Parent - supposedly 
contract Ownable {
    address private _owner;

    modifier onlyOwner  {
        require(msg.sender == _owner,"Only the owner can run this function.");
        _;
    }
    constructor () {
        _owner = msg.sender;
    }
    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
    function owner() public view returns(address) {
        return _owner;
    }

}

contract realEstate is Ownable {

    address payable landlord;
    uint landlordsCounter;
    uint agreementsCounter;
    
    mapping (address => uint) landLordsMap;
    mapping (address => uint) landlordsPropertyCounter;
    mapping(address => mapping (uint => Property)) landlordProperties;
    mapping(address => mapping(uint => AgreementDraft)) agreementsMap;

    struct Property { 
        uint propertyId;
        string streetName;
        uint area;
        uint apartmentNum;
        uint listedPrice;
        bool valid; 
        properyStatus propStatus;
    }

    enum properyStatus {
        uninitialized,
        agreementStarted,
        agreementInProgress,
        agreementCompleted
    }

    // CURRENT STATE OF ANY AGREEMENT REGARDING AN OFFER
    enum AgreementStatus { 
        pending,
        confirmed,
        buyer_Approved,
        landlord_Approved,
        cancelled,
        rejected,
        completed
    }

    struct AgreementDraft {
        uint agreementId;
        address landlordAddress; 
        address buyerAddress; 
        uint listedPrice;
        string otherTerms;
        string agreementHash;
        string landlordSignedHash;
        string buyerSignedHash;
        AgreementStatus status;
        bool exists;
    }

    // ----------------------------
    // list of events emitted to log
    event newLandlordAdded(address _landlordAddress, uint _landlordId);
    event newPropertyAdded(address _landlordAddress, uint _propertyId);
    event propertyModified(address _landlordAddress, uint _propertyID);
    event propertyRemoved(address _landlordAddress, uint _propertyID);
    event propertTransfered(address _landlordAddress, address _buyerAddress, uint _propertyID, uint _price);
    event amountTransfered(address _to, uint _amount);
    event agreementDraftSubmitted(address payable _landlordAddress, address payable _buyerAddress, uint _agreementId, uint _propertyID);
    event agreementStatusChanged(address payable _landlordAddress, uint _propertyId, AgreementStatus _status);


    // will run the first time contract is deployed -- owner here is govn.
    constructor () payable {
        landlordsCounter = 0;
        agreementsCounter = 0;
        super;
    }

       // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    // gets the balance of the smart contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }   


    // ---------------------------------
    // MODIFIERS FOR OUR CONTRACTS: 
    // ensures that landlord does not exist
    modifier landlordDoesNotExist (address payable _landlordAddress) {
        require(landLordsMap[_landlordAddress] == 0, "Landlord already exists.");
        _;
    }
    
    // ensures that landlord exists 
    modifier landlordExists (address payable _landlordAddress) {
        require(landLordsMap[_landlordAddress] != 0, "Landlord does not exist.");
        _;
    }

    // ensures that property exists
    modifier propertyExists (address payable _landlordAddress, uint _propertyId) {
        require(landlordProperties[_landlordAddress][_propertyId].valid == true, "Property does not exist for this landlord.");
        _;
    }
    
    // ensure that property does not exist
    modifier propertyDoesNotExists (address payable _landlordAddress, uint _propertyId) {
        require(landlordProperties[_landlordAddress][_propertyId].valid == false, "This property already exists for this landlord.");
        _;
    }

    // ensure the buyer has sufficient balance to complte the transaction
    modifier hasSufficientBalance (address payable _landlordAddress, uint amount) {
        require (_landlordAddress.balance >= amount, "Insufficient balance to complete transaction.");
        _;
    }

    // ensure the agreement can be initiated for a property
    modifier agreementCanBeInitiated (address payable _landlordAddress, uint _propertyId ) {
        require(landlordProperties[_landlordAddress][_propertyId].propStatus == properyStatus.uninitialized);
        _;
    }

    // ensure the agreement can be cancelled for a property
    modifier agreementCancellable (address _landlordAddress, uint _propertyId) {
        AgreementStatus status = agreementsMap[_landlordAddress][_propertyId].status;
        require(!(
            status == AgreementStatus.cancelled 
            || status == AgreementStatus.completed 
            || status == AgreementStatus.buyer_Approved 
            || status == AgreementStatus.rejected), "Agreement cannot be cancelled."
        );
        _;
    }

    // ensure the agreemnet exists 
    modifier agreementExists (address _landlordAddress, uint _propertyId) {
        require(agreementsMap[_landlordAddress][_propertyId].exists == true, "Agreement does not exist.");
        _;
    }

    // ensure the agreemnet does not exist
    modifier agreementDoesNotExist (address _landlordAddress, uint _propertyId ) {
        require(agreementsMap[_landlordAddress][_propertyId].exists == false, "Agreement already exists.");
        _;
    }

    // ensure the agreement is in specific status
    modifier agreementInStatus (address _landlordAddress, uint _propertyId, AgreementStatus _status) {
        require(agreementsMap[_landlordAddress][_propertyId].status == _status, "Agreement status invalid.");
        _;
    }

    // ------------------------------
    // MAIN Functions of the contract

    /*  @dev - checks if the property exists for the specific landlord
        @filters - onlyOwner 
        @params - landlordAddress, propertyId  
    */ 
    function checkPropertyExists (address payable _landlordAddress, uint _propertyId) 
    view public 
    onlyOwner
    returns(bool){
        return landlordProperties[_landlordAddress][_propertyId].valid; 
    }

    /*  @dev - adds a new landlord to the mapping of landlords && landlordCounter++
        @filters - onlyOwner, landlordDoesNotExist 
        @params - landlordAddress
    */ 
    function addLandlord (address payable _landlordAddress) 
    public 
    onlyOwner
    landlordDoesNotExist(_landlordAddress) 
    {
        landlordsPropertyCounter[_landlordAddress] = 0;
        landlordsCounter ++;
        // adds landlord to list of landlords
        landLordsMap[_landlordAddress] = landlordsCounter;
        emit newLandlordAdded(_landlordAddress, landlordsCounter);
    }

    /*  @dev - creates a new property for a landlord && landlordsPropertyCounter++
        @filters - onlyOwner, landlordExists 
        @params - landlordAddress, streetName, area, apartmentNum, listedPrice
    */ 
    function createPropertyListing(address payable _landlordAddress, string memory _streetName, uint _area, uint _apartmentNum, uint _listedPrice) 
    public 
    onlyOwner
    landlordExists(_landlordAddress)  
    {
        // increment landlordPropertyCounter 
        landlordsPropertyCounter[_landlordAddress]++;
        uint counter = landlordsPropertyCounter[_landlordAddress];
        // adds property to the list of lands owned by a landlord
        landlordProperties[_landlordAddress][counter] = Property(counter, _streetName, _area, _apartmentNum, _listedPrice, true, properyStatus.uninitialized);   
        emit newPropertyAdded(_landlordAddress, counter );
    }

    /*  @dev - modifies an existing property for a landlord
        @filters - onlyOwner, landlordExists, propertyExists 
        @params - landlordAddress, propertyID, streetName, area, apartmentNum, listedPrice
    */ 
    function modifyPropertyListing(address payable _landlordAddress, uint _propertyID, string memory _streetName, uint _area, uint _apartmentNum, uint _listedPrice) 
    public 
    onlyOwner
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID)
    {
        Property storage property = landlordProperties[_landlordAddress][_propertyID];
        property.streetName = _streetName;
        property.area = _area;
        property.apartmentNum = _apartmentNum;
        property.listedPrice = _listedPrice;
        emit propertyModified(_landlordAddress, _propertyID );
    }

    /*  @dev - modifies an existing property for a landlord
        @filters - onlyOwner, landlordExists, propertyExists 
        @params - landlordAddress, propertyID, streetName, area, apartmentNum, listedPrice
    */ 
    function removePropertyListing(address payable _landlordAddress, uint _propertyID) 
    public 
    onlyOwner
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    {
        delete landlordProperties[_landlordAddress][_propertyID];
        emit propertyRemoved(_landlordAddress, _propertyID );
    }

    /*  @dev - gets the listed price for an existing property for a landlord
        @filters - onlyOwner, landlordExists, propertyExists
        @params - landlordAddress, propertyID
    */ 
    function getPropertyListedPrice(address payable _landlordAddress, uint _propertyID) 
    view public  
    onlyOwner
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    returns (uint) 
    {
        return (
            landlordProperties[_landlordAddress][_propertyID].listedPrice
        );
    }

    /*  @dev - gets an existing property for a landlord
        @filters - onlyOwner, landlordExists, propertyExists 
        @params - landlordAddress, propertyID
    */ 
    function getProperty(address payable _landlordAddress, uint _propertyID) 
    view public  
    onlyOwner
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    returns (string memory, uint, uint, uint) 
    {
        return (
            landlordProperties[_landlordAddress][_propertyID].streetName, 
            landlordProperties[_landlordAddress][_propertyID].area,
            landlordProperties[_landlordAddress][_propertyID].apartmentNum,
            landlordProperties[_landlordAddress][_propertyID].listedPrice
        );
    }

    function getLandlordCounter (address _landlordAddress) public view returns(uint) {
        return(landlordsPropertyCounter[_landlordAddress]);
    }
    /*  @dev - transfers a property from the landlord to the buyer && landlordsPropertyCounter-- && buyerCounter++
        @filters - onlyOwner, landlordExists, propertyExists
        @params - landlordAddress, streetName, area, apartmentNum, listedPrice
    */ 
    function transferProperty(address payable _landlordAddress, uint _propertyID, address payable _buyerAddress) 
    public payable
    onlyOwner
    landlordExists(_landlordAddress) 
    landlordExists(_buyerAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    {

        // increment buyer's counter 
        landlordsPropertyCounter[_buyerAddress]++;
        uint buyerCounter = landlordsPropertyCounter[_buyerAddress];
        // transfer property from landlord to buyer
        landlordProperties[_buyerAddress][buyerCounter] = landlordProperties[_landlordAddress][_propertyID];
        // remove the property from landlordProperties
        delete landlordProperties[_landlordAddress][_propertyID];
        // decrement landlord's counter 
        landlordsPropertyCounter[_landlordAddress]--;
        emit propertyRemoved(_landlordAddress, _propertyID );
        emit propertTransfered(_landlordAddress, _buyerAddress, _propertyID, landlordProperties[_buyerAddress][buyerCounter].listedPrice);
    }

    /*  @dev - transfers the amount from the contract to the landlord 
        @filters - onlyOwner, landlordExists
        @params - landlordAddress, streetName, area, apartmentNum, listedPrice
    */ 
    function transferAmount(address payable _landlordAddress, uint _propertyID, address payable _buyerAddress) 
    public payable
    onlyOwner
    landlordExists(_landlordAddress) 
    landlordExists(_buyerAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    {

        // get price of property listed 
        uint _amount = landlordProperties[_landlordAddress][_propertyID].listedPrice;    

        // transfer amount from contract to landlord
        (bool sent, ) = _landlordAddress.call{value: _amount}("");
        require(sent, "Failed to send amount!");

        emit amountTransfered(_landlordAddress, _amount);

    }

    /*  @dev - gets the agreement status for a property
        @filters - onlyOwner, agreementExists
        @params - landlordAddress, propertyId
    */ 
    function getAgreementStatus (address payable _landlordAddress, uint _propertyId) 
    internal view
    onlyOwner
    agreementExists(_landlordAddress, _propertyId)
    returns (AgreementStatus)
    {
        return(agreementsMap[_landlordAddress][_propertyId].status);
    }

    /*  @dev - gets the agreement details for a property
        @filters - onlyOwner, agreementExists
        @params - landlordAddress, propertyId
    */ 
    function getAgreement (address payable _landlordAddress, uint _propertyId) 
    public view
    onlyOwner
    agreementExists(_landlordAddress, _propertyId)
    returns (uint, address, address, uint, string memory)
    {
        return(
            agreementsMap[_landlordAddress][_propertyId].agreementId, 
            agreementsMap[_landlordAddress][_propertyId].landlordAddress, 
            agreementsMap[_landlordAddress][_propertyId].buyerAddress, 
            agreementsMap[_landlordAddress][_propertyId].listedPrice,
            agreementsMap[_landlordAddress][_propertyId].otherTerms
            );
    }

    /*  @dev - submits the agreement draft for a property
        @filters - onlyOwner, landlordExists, propertyExists, agreementCanBeInitiated, agreementDoesNotExist
        @params - landlordAddress, propertyId, buyerAddress, otherTerms, agreementHash
    */ 
    function submitDraft(address payable _landlordAddress, uint _propertyId, address payable _buyerAddress, string memory otherTerms, string memory _agreementHash) 
    public 
    onlyOwner
    landlordExists(_landlordAddress) 
    landlordExists(_buyerAddress) 
    propertyExists(_landlordAddress, _propertyId) 
    agreementCanBeInitiated(_landlordAddress, _propertyId) 
    agreementDoesNotExist(_landlordAddress, _propertyId)
    {
        agreementsCounter++; 
        agreementsMap[_landlordAddress][_propertyId] = AgreementDraft(agreementsCounter, _landlordAddress, _buyerAddress, getPropertyListedPrice(_landlordAddress, _propertyId), otherTerms, _agreementHash, "", "", AgreementStatus.pending, true);
        emit agreementDraftSubmitted(_landlordAddress, _buyerAddress, agreementsCounter, _propertyId);
    }

    /*  @dev - sets the agreement status to cancelled for a property
        @filters - onlyOwner, agreementExists, agreementCancellable
        @params - landlordAddress, propertyId
    */ 
    function cancellAgreement(address payable _landlordAddress, uint _propertyId) 
    public
    onlyOwner
    agreementExists(_landlordAddress, _propertyId)
    agreementCancellable(_landlordAddress, _propertyId)
    {
        agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.cancelled;
        emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.cancelled);
    }

    /*  @dev - sets the agreement status to confirmed or rejected for a property
        @filters - onlyOwner, agreementExists, agreementCancellable
        @params - landlordAddress, propertyId, decision
    */ 
    function agreementDecision(address payable _landlordAddress, uint _propertyId, bool decision) 
    public
    onlyOwner
    agreementExists(_landlordAddress, _propertyId)
    agreementInStatus(_landlordAddress, _propertyId, AgreementStatus.pending)
    {
        if (decision){
            agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.confirmed;
            emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.confirmed);
        } else {
            agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.rejected;
            emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.rejected);
        }
    }

    /*  @dev - sets the agreement status to landlord_Approved for a property
        @filters - onlyOwner, agreementExists, agreementInStatus
        @params - landlordAddress, propertyId
    */ 
    function landlordSignedAgreement(address payable _landlordAddress, uint _propertyId, string memory _landlordSignedHash) 
    public
    onlyOwner
    agreementExists(_landlordAddress, _propertyId)
    agreementInStatus(_landlordAddress, _propertyId, AgreementStatus.confirmed)
    {
        agreementsMap[_landlordAddress][_propertyId].landlordSignedHash = _landlordSignedHash;
        agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.landlord_Approved;
        emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.landlord_Approved);
    }

    /*  @dev - sets the agreement status to buyer_Approved for a property
        @filters - onlyOwner, agreementExists, agreementInStatus
        @params - landlordAddress, propertyId
    */ 
    function buyerSignedAgreement(address payable _landlordAddress, uint _propertyId, string memory _buyerSignedHash) 
    public
    onlyOwner
    agreementExists(_landlordAddress, _propertyId)
    agreementInStatus(_landlordAddress, _propertyId, AgreementStatus.landlord_Approved)
    {
        agreementsMap[_landlordAddress][_propertyId].buyerSignedHash = _buyerSignedHash;
        agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.buyer_Approved;
        emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.buyer_Approved);
    }

    /*  @dev - sets the agreement status to completed && tranfers the property from landlord to buyer
        @filters - onlyOwner, agreementExists, agreementInStatus
        @params - landlordAddress, buyerAddress, propertyId
    */ 
    function completeAgreement(address payable _landlordAddress, address payable _buyerAddress, uint _propertyId)
    public payable
    onlyOwner
    agreementExists(_landlordAddress, _propertyId)
    agreementInStatus(_landlordAddress, _propertyId, AgreementStatus.buyer_Approved)
    {
        agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.completed;
        emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.completed);
        emit propertTransfered(_landlordAddress, _buyerAddress, _propertyId, getPropertyListedPrice(_landlordAddress, _propertyId));
    }

}