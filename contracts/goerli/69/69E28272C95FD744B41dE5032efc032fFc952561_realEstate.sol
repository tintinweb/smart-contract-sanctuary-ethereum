// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 

// Parent  
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
        string propertyType;
        uint titleDeedNo;
        uint titleDeedYear;
        string streetName;
        uint area;
        string apartmentNum;
        uint listedPrice;
        bool valid; 
        properyStatus propStatus;
        string ipfsHash;
        uint facilities;
    }

    enum properyStatus {
        uninitialized,
        agreementStarted,
        agreementInProgress,
        agreementCompleted
    }

    struct AgreementDraft {
        uint agreementId;
        address landlordAddress; 
        address buyerAddress; 
        uint listedPrice;
        string otherTerms;
        string landlordSignedHash;
        string buyerSignedHash;
        AgreementStatus status;
        bool exists;
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

    // ----------------------------
    // list of events emitted to log
    event newLandlordAdded(address _landlordAddress, uint _landlordId);
    event newPropertyAdded(address payable landlordAddress, uint _propertyId, uint titleDeedNo, uint titleDeedYear, string propertyType, string streetName, uint area, string apartmentNum, uint listedPrice, properyStatus propStatus, string ipfsHash, uint facilities);
    event propertTransfered(address _landlordAddress, address _buyerAddress, uint _propertyID, uint _price);
    event propertyStatusChanged(address payable _landlordAddress, uint _propertyId, properyStatus _status);
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
    // MAIN FUNCTIONS OF THE CONTRACT

    /*  @dev - adds a new landlord to the mapping of landlords && landlordCounter++
        @filters - landlordDoesNotExist 
        @params - landlordAddress
    */ 
    function addLandlord (address payable _landlordAddress) 
    public 
    landlordDoesNotExist(_landlordAddress) 
    {
        landlordsPropertyCounter[_landlordAddress] = 0;
        landlordsCounter ++;
        // adds landlord to list of landlords
        landLordsMap[_landlordAddress] = landlordsCounter;
        emit newLandlordAdded(_landlordAddress, landlordsCounter);
    }

    /*  @dev - creates a new property for a landlord && (Adds landlord if not exists) && landlordsPropertyCounter++
        @filters - landlordExists 
        @params - landlordAddress, streetName, area, apartmentNum, listedPrice
    */ 
    function createPropertyListing(address payable _landlordAddress, string memory _propertyType, uint _titleDeedNo, uint _titleDeedYear, string memory _streetName, uint _area, string memory _apartmentNum, uint _listedPrice, string memory _ipfsHash, uint _facilities )
    public payable 
    {
        require(msg.sender == _landlordAddress, "You cannot create a property for the user! Only the owner can create the property."); 
        // If the landlord does not exist
        if (landLordsMap[_landlordAddress] == 0) {
            landlordsPropertyCounter[_landlordAddress] = 0;
            landlordsCounter ++;
               // adds landlord to list of landlords
            landLordsMap[_landlordAddress] = landlordsCounter;
            emit newLandlordAdded(_landlordAddress, landlordsCounter);
        } 
        // increment landlordPropertyCounter 
        landlordsPropertyCounter[_landlordAddress]++;
        uint counter = landlordsPropertyCounter[_landlordAddress];
        // adds property to the list of lands owned by a landlord
        landlordProperties[_landlordAddress][counter] = Property(counter, _propertyType, _titleDeedNo, _titleDeedYear, _streetName, _area, _apartmentNum, _listedPrice, true, properyStatus.uninitialized, _ipfsHash, _facilities);  
        emit propertyStatusChanged(_landlordAddress, counter, properyStatus.uninitialized); 
        emit newPropertyAdded(_landlordAddress, counter, _titleDeedNo, _titleDeedYear, _propertyType, _streetName, _area, _apartmentNum, _listedPrice, properyStatus.uninitialized, _ipfsHash, _facilities );
    }

    /*  @dev - gets the listed price for an existing property for a landlord
        @filters - landlordExists, propertyExists
        @params - landlordAddress, propertyID
    */ 
    function getPropertyListedPrice(address payable _landlordAddress, uint _propertyID) 
    view public  
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    returns (uint) 
    {
        return (
            landlordProperties[_landlordAddress][_propertyID].listedPrice
        );
    }

    /*  @dev - gets an existing property's details for a landlord
        @filters - landlordExists, propertyExists 
        @params - landlordAddress, propertyID
    */ 
    function getPropertyDetails(address payable _landlordAddress, uint _propertyID) 
    view public  
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    returns (string memory, uint, uint, uint) 
    {
        return (
            landlordProperties[_landlordAddress][_propertyID].propertyType, 
            landlordProperties[_landlordAddress][_propertyID].titleDeedYear, 
            landlordProperties[_landlordAddress][_propertyID].listedPrice,
            landlordProperties[_landlordAddress][_propertyID].facilities
        );
    }

    /*  @dev - gets an existing property's location details for a landlord
        @filters - landlordExists, propertyExists 
        @params - landlordAddress, propertyID
    */ 
    function getPropertyLocationDetails(address payable _landlordAddress, uint _propertyID) 
    view public  
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    returns (string memory, uint, string memory, string memory) 
    {
        return (
            landlordProperties[_landlordAddress][_propertyID].streetName, 
            landlordProperties[_landlordAddress][_propertyID].area,
            landlordProperties[_landlordAddress][_propertyID].apartmentNum,
            landlordProperties[_landlordAddress][_propertyID].ipfsHash
        );
    }

    /*  @dev - checks if the property exists for the specific landlord
        @filters - none
        @params - landlordAddress, propertyId  
    */ 
    function checkPropertyExists (address payable _landlordAddress, uint _propertyId) 
    view public 
    returns(bool){
        return landlordProperties[_landlordAddress][_propertyId].valid; 
    }

    /*  @dev - gets the counter for landlords
        @filters - none
        @params - landlordAddress
    */ 
    function getLandlordCounter (address _landlordAddress) 
    public view 
    returns(uint) {
        return(landlordsPropertyCounter[_landlordAddress]);
    }

    /*  @dev - transfers a property from the landlord to the buyer && landlordsPropertyCounter-- && buyerCounter++
        @filters - landlordExists, propertyExists
        @params - landlordAddress, streetName, area, apartmentNum, listedPrice
    */ 
    function transferProperty(address payable _landlordAddress, uint _propertyID, address payable _buyerAddress) 
    public payable
    landlordExists(_landlordAddress) 
    landlordExists(_buyerAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    {
        require(msg.sender == _landlordAddress, "You cannot transfer the property! Only the owner can transfer the property.");
        require(_landlordAddress != _buyerAddress, "You cannot transfer the property to the same address! Buyer and Landlord Address should be different.");
        // increment buyer's counter 
        landlordsPropertyCounter[_buyerAddress]++;
        uint buyerCounter = landlordsPropertyCounter[_buyerAddress];
        // transfer property from landlord to buyer
        landlordProperties[_buyerAddress][buyerCounter] = landlordProperties[_landlordAddress][_propertyID];
        // remove the property from landlordProperties
        delete landlordProperties[_landlordAddress][_propertyID];
        // decrement landlord's counter 
        landlordsPropertyCounter[_landlordAddress]--;
        emit propertTransfered(_landlordAddress, _buyerAddress, _propertyID, landlordProperties[_buyerAddress][buyerCounter].listedPrice);
    }

    /*  @dev - transfers the amount from the contract to the landlord using the property listed price
        @filters - onlyOwner, landlordExists, propertyExists
        @params - landlordAddress, buyerAddress, propertyId
    */ 
    function transferAmountUsingPropertyID(address payable _landlordAddress, uint _propertyID) 
    public payable
    onlyOwner
    landlordExists(_landlordAddress) 
    propertyExists(_landlordAddress, _propertyID) 
    {
        // get price of property listed 
        uint _amount = landlordProperties[_landlordAddress][_propertyID].listedPrice;    
        // transfer amount from contract to landlord
        (bool sent, ) = _landlordAddress.call{value: _amount}("");
        require(sent, "Failed to send amount!");
        emit amountTransfered(_landlordAddress, _amount);
    }

    /*  @dev - transfers the amount from the contract to the a landlord address
        @filters - onlyOwner, landlordExists
        @params - landlordAddress, amount
    */ 
    function transferAmount(address payable _landlordAddress, uint _amount) 
    public payable
    onlyOwner
    landlordExists(_landlordAddress) 
    {
        // transfer amount from contract to landlord
        (bool sent, ) = _landlordAddress.call{value: _amount}("");
        require(sent, "Failed to send amount!");
        emit amountTransfered(_landlordAddress, _amount);
    }

    /*  @dev - gets the property status for a property
        @filters - propertyExists
        @params - landlordAddress, propertyId
    */ 
    function getPropertyStatus (address payable _landlordAddress, uint _propertyId) 
    public view
    propertyExists(_landlordAddress, _propertyId)
    returns (properyStatus)
    {
        return(landlordProperties[_landlordAddress][_propertyId].propStatus);
    }

    /*  @dev - gets the agreement status for a property
        @filters - agreementExists
        @params - landlordAddress, propertyId
    */ 
    function getAgreementStatus (address payable _landlordAddress, uint _propertyId) 
    public view
    agreementExists(_landlordAddress, _propertyId)
    returns (AgreementStatus)
    {
        return(agreementsMap[_landlordAddress][_propertyId].status);
    }

    /*  @dev - gets the agreement details for a property
        @filters - agreementExists
        @params - landlordAddress, propertyId
    */ 
    function getAgreement (address payable _landlordAddress, uint _propertyId) 
    public view
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
        @filters - landlordExists, propertyExists, agreementCanBeInitiated, agreementDoesNotExist
        @params - landlordAddress, propertyId, buyerAddress, otherTerms
    */ 
    function submitDraft(address payable _landlordAddress, uint _propertyId, address payable _buyerAddress, string memory otherTerms)
    public payable
    landlordExists(_landlordAddress) 
    landlordExists(_buyerAddress) 
    propertyExists(_landlordAddress, _propertyId) 
    agreementCanBeInitiated(_landlordAddress, _propertyId) 
    agreementDoesNotExist(_landlordAddress, _propertyId)
    {
        agreementsCounter++; 
        agreementsMap[_landlordAddress][_propertyId] = AgreementDraft(agreementsCounter, _landlordAddress, _buyerAddress, getPropertyListedPrice(_landlordAddress, _propertyId), otherTerms, "", "", AgreementStatus.pending, true);
        landlordProperties[_landlordAddress][_propertyId].propStatus = properyStatus.agreementStarted;
        emit propertyStatusChanged(_landlordAddress, _propertyId, properyStatus.agreementStarted); 
        emit agreementDraftSubmitted(_landlordAddress, _buyerAddress, agreementsCounter, _propertyId);
    }

    /*  @dev - sets the agreement status to cancelled for a property
        @filters - agreementExists, agreementCancellable
        @params - landlordAddress, propertyId
    */ 
    function cancelAgreement(address payable _landlordAddress, uint _propertyId) 
    public
    agreementExists(_landlordAddress, _propertyId)
    agreementCancellable(_landlordAddress, _propertyId)
    {
        require(msg.sender == _landlordAddress, "You cannot cancel the agreement! Only the owner can cancel the agreement.");
        agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.cancelled;
        emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.cancelled);
    }

    /*  @dev - sets the agreement status to confirmed or rejected for a property
        @filters - agreementExists, agreementCancellable
        @params - landlordAddress, propertyId, decision
    */ 
    function agreementDecision(address payable _landlordAddress, uint _propertyId, bool decision) 
    public
    agreementExists(_landlordAddress, _propertyId)
    agreementInStatus(_landlordAddress, _propertyId, AgreementStatus.pending)
    {
        require(msg.sender == _landlordAddress, "You cannot make a decision on the agreement! Only the owner can make a decision on the agreement.");
        if (decision){
            agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.confirmed;
            landlordProperties[_landlordAddress][_propertyId].propStatus = properyStatus.agreementInProgress;
            emit propertyStatusChanged(_landlordAddress, _propertyId, properyStatus.agreementInProgress); 
            emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.confirmed);
        } else {
            agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.rejected;
            emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.rejected);
        }
    }

    /*  @dev - sets the agreement status to landlord_Approved for a property
        @filters - agreementExists, agreementInStatus
        @params - landlordAddress, propertyId
    */ 
    function landlordSignedAgreement(address payable _landlordAddress, uint _propertyId, string memory _landlordSignedHash) 
    public
    agreementExists(_landlordAddress, _propertyId)
    agreementInStatus(_landlordAddress, _propertyId, AgreementStatus.confirmed)
    {
        require(msg.sender == _landlordAddress, "You cannot sign the agreement! Only the owner can sign the agreement.");
        agreementsMap[_landlordAddress][_propertyId].landlordSignedHash = _landlordSignedHash;
        agreementsMap[_landlordAddress][_propertyId].status = AgreementStatus.landlord_Approved;
        emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.landlord_Approved);
    }

    /*  @dev - sets the agreement status to buyer_Approved for a property
        @filters - agreementExists, agreementInStatus
        @params - landlordAddress, propertyId
    */ 
    function buyerSignedAgreement(address payable _landlordAddress, address payable _buyerAddress, uint _propertyId, string memory _buyerSignedHash) 
    public
    agreementExists(_landlordAddress, _propertyId)
    agreementInStatus(_landlordAddress, _propertyId, AgreementStatus.landlord_Approved)
    {
        require(msg.sender == _buyerAddress, "You cannot sign the agreement! Only the owner can sign the agreement.");
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
        landlordProperties[_landlordAddress][_propertyId].propStatus = properyStatus.agreementCompleted;
        emit propertyStatusChanged(_landlordAddress, _propertyId, properyStatus.agreementCompleted); 
        emit agreementStatusChanged(_landlordAddress, _propertyId, AgreementStatus.completed);
        emit propertTransfered(_landlordAddress, _buyerAddress, _propertyId, getPropertyListedPrice(_landlordAddress, _propertyId));
    }
}