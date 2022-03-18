/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract RandomNumArray {
    uint randArrayFixedSize = 10;
    uint[] public randArray = new uint[](randArrayFixedSize);
    uint maxRandNumber = 9999999999;

    function generateRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % maxRandNumber;
    }

    function createRandomArray() public view returns (uint256[] memory){
        uint[] memory randomArray = new uint[](randArrayFixedSize);
        for(uint i = 0; i< randArrayFixedSize ; i++){
            randomArray[i] = uint(keccak256(abi.encodePacked(block.timestamp+i,block.difficulty,msg.sender))) % maxRandNumber;
            if (randomArray[i] == 0){
                randomArray[i] = uint(keccak256(abi.encodePacked(block.timestamp+i,block.difficulty,msg.sender))) % maxRandNumber;
            }           
        }
        return randomArray;
    }
    
    function generateRandomArray()public returns (uint256[] memory){
        uint[] memory temprandomArray = createRandomArray();
        for(uint i = 0; i< randArrayFixedSize ; i++){
            randArray[i] = temprandomArray[i];                      
        }
        return randArray;
    }
    
    function get(uint256 i) public view returns (uint256) {
        return randArray[i];
    }

    function getArr() public view returns (uint256[] memory) {
        return randArray;
    }

    function getLength() public view returns (uint) {
        return randArray.length;
    }
}

contract testEscrow is Ownable {
    struct EscrowStruct
    {    
        uint escrowID;
        address buyer;
        uint[] postedAssets;
        bool[] postedAssetsIsRedeemed;
        address[] sellerAddressArray;
        uint amount;
        uint redeemAmountPerNumber;
        uint createdDate;
        bool isActive;  
        uint escrowFee;         
    }

    struct SellerStruct
    {    
        uint escrowID;
        address seller;
        uint[] collectedAssets;
        uint createdDate;
        uint redeemedAmount; 
    }

    mapping(address => EscrowStruct[]) private buyerDatabase;
    mapping(address => SellerStruct[]) private sellerDatabase;

    EscrowStruct[] private escrowArray;
    SellerStruct[] private sellerArray;
    uint public escrowCount;
    uint private contractEscrowFee;
    uint private partyApercentage;
    uint private partyBpercentage;

    constructor(){
        escrowCount = 0;
        contractEscrowFee = 10;
        partyApercentage = 20;
        partyBpercentage = 80;
    }


    // Functions for OnlyOwner

    // Get Buyer Database By Address - Only Owner
    function getBuyerDataBaseByAddress(address _buyerAddress)public view onlyOwner returns(EscrowStruct[] memory){
        return buyerDatabase[_buyerAddress];
    }
    // Get Seller Database By Address - Only Owner
    function getSellerDataBaseByAddress(address _sellerAddress)public view onlyOwner returns(SellerStruct[] memory){
        return sellerDatabase[_sellerAddress];
    }
    // Get EscrowArray - Only Owner
    function getEscrowArray()public view onlyOwner returns(EscrowStruct[] memory){
        return escrowArray;
    }
    // Get EscrowArray - Only Owner
    function getSellerArray()public view onlyOwner returns(SellerStruct[] memory){
        return sellerArray;
    }
    // Get Escrow By ID
    function getEscrowByID(uint _escrowID)public view onlyOwner returns(EscrowStruct memory,bool){
        bool isExist = false;
        EscrowStruct memory escrow;
        for (uint i = 0; i < escrowArray.length; i++)
        {
            if (escrowArray[i].escrowID == _escrowID){
                escrow = escrowArray[i];
                isExist = true;
            }
        }
        return (escrow, isExist);
    }
    // Get Seller By Address
    function getSellerInfoByAddressAndEscrowID(address _sellerAddress,uint _escrowID) public view onlyOwner returns(SellerStruct memory, bool){
        bool isExist = false;
        SellerStruct memory sellerInfo;

        for (uint i = 0; i < sellerDatabase[_sellerAddress].length; i++)
        {
            if (sellerDatabase[_sellerAddress][i].escrowID == _escrowID){
                sellerInfo = sellerDatabase[_sellerAddress][i];
                isExist = true;
            }
        }
        return (sellerInfo, isExist);
    }

     // Set Escrow Fee By ID
    function setEscrowStatusByID(uint _escrowID, bool _isActive) external view onlyOwner {
        (EscrowStruct memory escrowInfo, bool isExist) = getEscrowByID(_escrowID);
        require(isExist, "EscrowID is invaild in getListOfSellersByEscrowID");
        escrowInfo.isActive = _isActive;
    }
    // Get Escrow Fee By ID
    function getEscrowStatusByID(uint _escrowID) public view onlyOwner returns(bool){
        (EscrowStruct memory escrowInfo, bool isExist) = getEscrowByID(_escrowID);
        require(isExist, "EscrowID is invaild in getListOfSellersByEscrowID");
        return escrowInfo.isActive;
    }
    // Set Escrow Fee By ID
    function setEscrowFeeByID(uint _escrowID,uint _escrowFee) external view onlyOwner {
        (EscrowStruct memory escrowInfo, bool isExist) = getEscrowByID(_escrowID);
        require(isExist, "EscrowID is invaild in getListOfSellersByEscrowID");
        escrowInfo.escrowFee = _escrowFee;
    }
    // Get Escrow Fee By ID
    function getEscrowFeeByID(uint _escrowID) public view onlyOwner returns(uint){
        (EscrowStruct memory escrowInfo, bool isExist) = getEscrowByID(_escrowID);
        require(isExist, "EscrowID is invaild in getListOfSellersByEscrowID");
        return escrowInfo.escrowFee;
    }
    // Set Contract Escrow Fee
    function setContractEscrowFee(uint _escrowFee) external onlyOwner {
        contractEscrowFee = _escrowFee;
    }
    // Get Contract Escrow Fee
    function getContractEscrowFee() public view onlyOwner returns(uint){
        return contractEscrowFee;
    }
    // Set Contract Escrow Fee
    function setSplitPercentage(uint _partyApercentage, uint _partyBpercentage) external onlyOwner {
        require(_partyApercentage+_partyBpercentage== 100,"Party A + Party B should be 100%");
        partyApercentage = _partyBpercentage;
        partyBpercentage = _partyBpercentage;
    }
    // Get Contract Escrow Fee
    function getSplitPercentage() public view onlyOwner returns(uint, uint){
        return (partyApercentage, partyBpercentage);
    }

    // Functions for finding Mached assets

   
    // Find Matched Assets by Escrow ID and collected assets    
    function getMatchedAssets(uint _escrowID, uint[] memory _collectedAssets) private returns(uint[] memory){   

        (uint[] memory postedAssets, bool[] memory postedAssetsIsRedeemed, bool isExist) = getPostedAssetsByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");

        uint matchedCount = getCountOfMatchedAssets(_escrowID, _collectedAssets);
        uint[] memory matchedAssets = new uint[](matchedCount);
        uint matchedCounttemp = 0;

        for (uint i = 0; i < postedAssets.length; i++)
        {
            for (uint j = 0; j < _collectedAssets.length; j++)
            {
                if (postedAssets[i] == _collectedAssets[j]){
                    if (postedAssetsIsRedeemed[i] != true){
                        escrowArray[_escrowID].postedAssetsIsRedeemed[i] = true;
                        (address buyerAddress,,) = getBuyerAddressByEscrowID(_escrowID);
                        uint index = getBuyerDataBaseIndexByAddress(buyerAddress, _escrowID);
                        buyerDatabase[buyerAddress][index].postedAssetsIsRedeemed[i] = true;
                        matchedAssets[matchedCounttemp] = postedAssets[i];
                        matchedCounttemp += 1;
                    }
                }
            }
        }
        return matchedAssets;
    }

    // Get count of matched assets
    function getCountOfMatchedAssets(uint _escrowID, uint[] memory _collectedAssets) private view returns(uint){    
        (uint[] memory postedAssets, bool[] memory postedAssetsIsRedeemed, bool isExist) = getPostedAssetsByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        uint matchedCount = 0;
        for (uint i = 0; i < postedAssets.length; i++)
        {
            for (uint j = 0; j < _collectedAssets.length; j++)
            {
                if (postedAssets[i] == _collectedAssets[j]){
                    if (postedAssetsIsRedeemed[i] != true){
                         matchedCount += 1;
                    }
                }
            }
        }
        return matchedCount;
    }

    // Get posted Assets by escrow ID
    function getPostedAssetsByEscrowID(uint _escrowID) private view returns(uint[] memory,bool[] memory, bool){
        (address buyerAddress,bool isExist,) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        uint[] memory postedAssets;
        bool[] memory postedAssetsIsRedeemed;
        bool isExistInBuyerDatabase = false;

        for (uint i = 0; i < buyerDatabase[buyerAddress].length; i++){
            if (buyerDatabase[buyerAddress][i].escrowID == _escrowID){
                postedAssets = buyerDatabase[buyerAddress][i].postedAssets;
                postedAssetsIsRedeemed = buyerDatabase[buyerAddress][i].postedAssetsIsRedeemed;
                isExistInBuyerDatabase = true;
            }
        }
        
        return (postedAssets, postedAssetsIsRedeemed,isExistInBuyerDatabase);
    }

    // Get Buyer Address by Escrow ID
    function getBuyerAddressByEscrowID(uint _escrowID) public view returns(address, bool,bool){
        bool isExist = false;
        bool isActive = false;
        address buyerAddress;
        for (uint i = 0; i < escrowArray.length; i++)
        {
            if (escrowArray[i].escrowID == _escrowID){
                buyerAddress = escrowArray[i].buyer;
                isExist = true;
                isActive = escrowArray[i].isActive;
            }
        }
        return (buyerAddress, isExist,isActive);
    }

    // Get Buyer Database Index by Addres
    function getBuyerDataBaseIndexByAddress(address _buyerAddress, uint _escrowID) private view returns(uint){
        uint index = 0;
        for (uint i = 0; i < buyerDatabase[_buyerAddress].length; i++){
            if (buyerDatabase[_buyerAddress][i].escrowID == _escrowID){
                index = i;
            }
        }
        return index;
    }


    // Functions for Escrow and Sellers

    // Get List of Buyer Address and Escrow ID
    function getListofActiveEscrow() public view returns(uint[] memory, address[] memory){
        (uint activeEscrowcount) = getCountOfActiveEscrow();
        uint[] memory escrowIDArray = new uint[](activeEscrowcount);
        address[] memory buyerAddressArray = new address[](activeEscrowcount);
        for (uint i = 0 ; i < escrowArray.length; i ++){
            if(escrowArray[i].isActive){
                escrowIDArray[i] = escrowArray[i].escrowID;
                buyerAddressArray[i] = escrowArray[i].buyer;
            }
        }
        return (escrowIDArray, buyerAddressArray);
    }
    function getCountOfActiveEscrow() private view returns(uint){
        uint activeEscrowCount = 0;
        for (uint i = 0 ; i < escrowArray.length; i ++){
            if(escrowArray[i].isActive){
                activeEscrowCount +=1;                
            }
        }
        return activeEscrowCount;
    }

    // Get List of Sellers in this contract
    function getListofSellers() public view returns(uint[] memory, address[] memory){
        uint[] memory escrowIDArray = new uint[](sellerArray.length);
        address[] memory sellerAddressArray = new address[](sellerArray.length);

        for (uint i = 0 ; i < sellerArray.length; i ++){
            escrowIDArray[i] = sellerArray[i].escrowID;
            sellerAddressArray[i] = sellerArray[i].seller;
        }

        return (escrowIDArray, sellerAddressArray);
    }

    // Get List of Seller Array by Escrow ID
    function getListOfSellersByEscrowID(uint _escrowID) public view returns(address[] memory){
        (EscrowStruct memory buyerInfo, bool isExist) = getBuyerInformationByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild in getListOfSellersByEscrowID");
        return buyerInfo.sellerAddressArray;
    }

    // Get Buyer Information by Escrow ID
    function getBuyerInformationByEscrowID(uint _escrowID) private view returns(EscrowStruct memory,bool){
        bool isExist = false;
        EscrowStruct memory buyerInfo;
        for (uint i = 0; i < escrowArray.length; i++)
        {
            if (escrowArray[i].escrowID == _escrowID){
                buyerInfo = escrowArray[i];
                isExist = true;
            }
        }
        return (buyerInfo, isExist);
    }

    // Get Redeemed Cost By Escrow Id
    function getRedeemedCostPerAssetsrByEscrowID(uint _escrowID) public view returns(uint){
        (address buyeraddress, bool isExist,) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        uint index = getBuyerDataBaseIndexByAddress(buyeraddress, _escrowID);
        return buyerDatabase[buyeraddress][index].redeemAmountPerNumber;
    }
    

// Create Escrow and Post Collected Numbers

    // Create Escrow with posted assets from Party A
    function createNewEscrow(uint[] memory _postedAssets) public payable{
        require(msg.value == 1000000000000000000, "Fund should be 1000000000000000000 wei = 1 ETH");
        require(_postedAssets.length == 10, "Random Array size should be 10.");
        // require(msg.value == 10, "Fund should be 10 wei");
        // require(msg.value == 10000000000000000000, "Fund should be 10 wei");
        EscrowStruct memory newEscrow;
        newEscrow.escrowID = escrowCount;
        escrowCount = escrowCount + 1;
        newEscrow.buyer = msg.sender;
        newEscrow.amount = msg.value;
        newEscrow.postedAssets = _postedAssets;
        bool[] memory _postedAssetsIsRedeemed = new bool[](_postedAssets.length);
        newEscrow.postedAssetsIsRedeemed = _postedAssetsIsRedeemed;
        newEscrow.redeemAmountPerNumber = msg.value/_postedAssets.length;
        newEscrow.createdDate = getCurrentTimeStamp();
        newEscrow.isActive = true;
        newEscrow.escrowFee = contractEscrowFee;
        escrowArray.push(newEscrow);

        buyerDatabase[msg.sender].push(newEscrow);
    }

    // Post Collected assets from Party B
    function addNewSeller(uint _escrowID,uint[] memory _collectedNumbers) public payable returns(string memory){

        (address buyeraddress, bool isExist,bool isActive) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        require(isActive, "Escrow is not active");
        SellerStruct memory newSeller;
        newSeller.escrowID = _escrowID;
        newSeller.collectedAssets = _collectedNumbers;
        newSeller.createdDate = getCurrentTimeStamp();
        newSeller.seller = msg.sender;
        uint[] memory matchedAssets = getMatchedAssets(_escrowID,_collectedNumbers);

        uint index = getBuyerDataBaseIndexByAddress(buyeraddress, _escrowID);

        buyerDatabase[buyeraddress][index].sellerAddressArray.push(msg.sender);

        uint totalRedeemedAmount = matchedAssets.length*buyerDatabase[buyeraddress][index].redeemAmountPerNumber;
        uint sellerRedeemedAmount = totalRedeemedAmount * buyerDatabase[buyeraddress][index].escrowFee / 100 * partyBpercentage / 100;
        uint buyerRedeemedAmount = totalRedeemedAmount * buyerDatabase[buyeraddress][index].escrowFee / 100 * partyApercentage / 100;

        newSeller.redeemedAmount = sellerRedeemedAmount;
        sellerArray.push(newSeller);
        sellerDatabase[msg.sender].push(newSeller);
        
        payable(msg.sender).transfer(sellerRedeemedAmount);
        payable(buyeraddress).transfer(buyerRedeemedAmount);

        string memory result;
        if (matchedAssets.length == 0 ) {
            result = "No Match Found";
        }else{
            result = "Match Found :";
            for (uint i = 0; i<matchedAssets.length; i++){
                result = append(result,"#",Strings.toString(matchedAssets[i]), " ,");
            }
        }
        return result;
    }


    // String append Utility
    function append(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }

    // Get Current TimeStamp
    function getCurrentTimeStamp() private view returns(uint){
        return block.timestamp;
    }

    

}


contract ProjectREscrow is RandomNumArray, Ownable {
    //Version:  v1.0
       
    address public admin;

    
    //Each buyer address consist of an array of EscrowStruct
    //Used to store buyer's transactions and for buyers to interact with his transactions. (Such as releasing funds to seller)
    struct EscrowStruct
    {    
        address buyer;          //Person who is making payment
        address seller;         //Person who will receive funds
        address escrow_agent;   //Escrow agent to resolve disputes, if any
                                    
        uint escrow_fee;        //Fee charged by escrow
        uint amount;            //Amount of Ether (in Wei) seller will receive after fees

        bool escrow_intervention; //Buyer or Seller can call for Escrow intervention
        bool release_approval;   //Buyer or Escrow(if escrow_intervention is true) can approve release of funds to seller
        bool refund_approval;    //Seller or Escrow(if escrow_intervention is true) can approve refund of funds to buyer 

        bytes32 notes;             //Notes for Seller
        
    }

    struct TransactionStruct
    {                        
        //Links to transaction from buyer
        address buyer;          //Person who is making payment
        uint buyer_nounce;         //Nounce of buyer transaction                            
    }


    
    //Database of Buyers. Each buyer then contain an array of his transactions
    mapping(address => EscrowStruct[]) public buyerDatabase;

    //Database of Seller and Escrow Agent
    mapping(address => TransactionStruct[]) public sellerDatabase;       
    mapping(address => TransactionStruct[]) public escrowDatabase;
            
    //Every address have a Funds bank. All refunds, sales and escrow comissions are sent to this bank. Address owner can withdraw them at any time.
    mapping(address => uint) public Funds;

    mapping(address => uint) public escrowFee;


    //Constructor. Set contract creator/admin
    constructor() {
        admin = msg.sender;
    }

    function fundAccount(address sender_)  public payable
    {
        //LogFundsReceived(msg.sender, msg.value);
        // Add funds to the sender's account
        Funds[sender_] += msg.value;   
        
    }

    function setEscrowFee(uint fee) external{

        //Allowed fee range: 0.1% to 10%, in increments of 0.1%
        require (fee >= 1 && fee <= 100);
        escrowFee[msg.sender] = fee;
    }

    function getEscrowFee(address escrowAddress) internal view returns (uint) {
        return (escrowFee[escrowAddress]);
    }

    
    function newEscrowTransaction(address sellerAddress, address escrowAddress, bytes32 notes) public payable returns (bool) {

        require(msg.value > 0 && msg.sender != escrowAddress);
    
        //Store escrow details in memory
        EscrowStruct memory currentEscrow;
        TransactionStruct memory currentTransaction;
        
        currentEscrow.buyer = msg.sender;
        currentEscrow.seller = sellerAddress;
        currentEscrow.escrow_agent = escrowAddress;

        //Calculates and stores Escrow Fee.
        currentEscrow.escrow_fee = getEscrowFee(escrowAddress)*msg.value/1000;
        
        //0.25% dev fee
        uint dev_fee = msg.value/400;
        Funds[admin] += dev_fee;   

        //Amount seller receives = Total amount - 0.25% dev fee - Escrow Fee
        currentEscrow.amount = msg.value - dev_fee - currentEscrow.escrow_fee;

        //These default to false, no need to set them again
        /*currentEscrow.escrow_intervention = false;
        currentEscrow.release_approval = false;
        currentEscrow.refund_approval = false;  */ 
        
        currentEscrow.notes = notes;

        //Links this transaction to Seller and Escrow's list of transactions.
        currentTransaction.buyer = msg.sender;
        currentTransaction.buyer_nounce = buyerDatabase[msg.sender].length;

        sellerDatabase[sellerAddress].push(currentTransaction);
        escrowDatabase[escrowAddress].push(currentTransaction);
        buyerDatabase[msg.sender].push(currentEscrow);
        
        return true;

    }

    //switcher 0 for Buyer, 1 for Seller, 2 for Escrow
    function getNumTransactions(address inputAddress, uint switcher) external view returns (uint)
    {

        if (switcher == 0) return (buyerDatabase[inputAddress].length);

        else if (switcher == 1) return (sellerDatabase[inputAddress].length);

        else return (escrowDatabase[inputAddress].length);
    }

    //switcher 0 for Buyer, 1 for Seller, 2 for Escrow
    function getSpecificTransaction(address inputAddress, uint switcher, uint ID) external view returns (address, address, address, uint, bytes32, uint, bytes32)

    {
        bytes32 status;
        EscrowStruct memory currentEscrow;
        if (switcher == 0)
        {
            currentEscrow = buyerDatabase[inputAddress][ID];
            status = checkStatus(inputAddress, ID);
        } 
        
        else if (switcher == 1)

        {  
            currentEscrow = buyerDatabase[sellerDatabase[inputAddress][ID].buyer][sellerDatabase[inputAddress][ID].buyer_nounce];
            status = checkStatus(currentEscrow.buyer, sellerDatabase[inputAddress][ID].buyer_nounce);
        }

                    
        else if (switcher == 2)
        
        {        
            currentEscrow = buyerDatabase[escrowDatabase[inputAddress][ID].buyer][escrowDatabase[inputAddress][ID].buyer_nounce];
            status = checkStatus(currentEscrow.buyer, escrowDatabase[inputAddress][ID].buyer_nounce);
        }

        return (currentEscrow.buyer, currentEscrow.seller, currentEscrow.escrow_agent, currentEscrow.amount, status, currentEscrow.escrow_fee, currentEscrow.notes);
    }   


    function buyerHistory(address buyerAddress, uint startID, uint numToLoad) external view returns (address[] memory, address[] memory,uint[] memory, bytes32[] memory){


        uint length;
        if (buyerDatabase[buyerAddress].length < numToLoad)
            length = buyerDatabase[buyerAddress].length;
        
        else 
            length = numToLoad;
        
        address[] memory sellers = new address[](length);
        address[] memory escrow_agents = new address[](length);
        uint[] memory amounts = new uint[](length);
        bytes32[] memory statuses = new bytes32[](length);
        
        for (uint i = 0; i < length; i++)
        {

            sellers[i] = (buyerDatabase[buyerAddress][startID + i].seller);
            escrow_agents[i] = (buyerDatabase[buyerAddress][startID + i].escrow_agent);
            amounts[i] = (buyerDatabase[buyerAddress][startID + i].amount);
            statuses[i] = checkStatus(buyerAddress, startID + i);
        }
        
        return (sellers, escrow_agents, amounts, statuses);
    }


                
    function SellerHistory(address inputAddress, uint startID , uint numToLoad) external view returns (address[] memory, address[] memory, uint[] memory, bytes32[] memory){

        address[] memory buyers = new address[](numToLoad);
        address[] memory escrows = new address[](numToLoad);
        uint[] memory amounts = new uint[](numToLoad);
        bytes32[] memory statuses = new bytes32[](numToLoad);

        for (uint i = 0; i < numToLoad; i++)
        {
            if (i >= sellerDatabase[inputAddress].length)
                break;
            buyers[i] = sellerDatabase[inputAddress][startID + i].buyer;
            escrows[i] = buyerDatabase[buyers[i]][sellerDatabase[inputAddress][startID +i].buyer_nounce].escrow_agent;
            amounts[i] = buyerDatabase[buyers[i]][sellerDatabase[inputAddress][startID + i].buyer_nounce].amount;
            statuses[i] = checkStatus(buyers[i], sellerDatabase[inputAddress][startID + i].buyer_nounce);
        }
        return (buyers, escrows, amounts, statuses);
    }

    function escrowHistory(address inputAddress, uint startID, uint numToLoad) external view returns (address[] memory, address[] memory, uint[] memory, bytes32[] memory){
    
        address[] memory buyers = new address[](numToLoad);
        address[] memory sellers = new address[](numToLoad);
        uint[] memory amounts = new uint[](numToLoad);
        bytes32[] memory statuses = new bytes32[](numToLoad);

        for (uint i = 0; i < numToLoad; i++)
        {
            if (i >= escrowDatabase[inputAddress].length)
                break;
            buyers[i] = escrowDatabase[inputAddress][startID + i].buyer;
            sellers[i] = buyerDatabase[buyers[i]][escrowDatabase[inputAddress][startID +i].buyer_nounce].seller;
            amounts[i] = buyerDatabase[buyers[i]][escrowDatabase[inputAddress][startID + i].buyer_nounce].amount;
            statuses[i] = checkStatus(buyers[i], escrowDatabase[inputAddress][startID + i].buyer_nounce);
        }
        return (buyers, sellers, amounts, statuses);
    }

    function checkStatus(address buyerAddress, uint nounce) internal view returns (bytes32){

        bytes32 status = "";

        if (buyerDatabase[buyerAddress][nounce].release_approval){
            status = "Complete";
        } else if (buyerDatabase[buyerAddress][nounce].refund_approval){
            status = "Refunded";
        } else if (buyerDatabase[buyerAddress][nounce].escrow_intervention){
            status = "Pending Escrow Decision";
        } else
        {
            status = "In Progress";
        }
    
        return (status);
    }

    
    //When transaction is complete, buyer will release funds to seller
    //Even if EscrowEscalation is raised, buyer can still approve fund release at any time
    function buyerFundRelease(uint ID) public
    {
        require(ID < buyerDatabase[msg.sender].length && 
        buyerDatabase[msg.sender][ID].release_approval == false &&
        buyerDatabase[msg.sender][ID].refund_approval == false, 'Invalid request');
        
        //Set release approval to true. Ensure approval for each transaction can only be called once.
        buyerDatabase[msg.sender][ID].release_approval = true;

        address seller = buyerDatabase[msg.sender][ID].seller;
        address escrow_agent = buyerDatabase[msg.sender][ID].escrow_agent;

        uint amount = buyerDatabase[msg.sender][ID].amount;
        uint escrow_fee = buyerDatabase[msg.sender][ID].escrow_fee;

        //Move funds under seller's owership
        Funds[seller] += amount;
        Funds[escrow_agent] += escrow_fee;


    }

    //Seller can refund the buyer at any time
    function sellerRefund(uint ID) public
    {
        address buyerAddress = sellerDatabase[msg.sender][ID].buyer;
        uint buyerID = sellerDatabase[msg.sender][ID].buyer_nounce;

        require(
        buyerDatabase[buyerAddress][buyerID].release_approval == false &&
        buyerDatabase[buyerAddress][buyerID].refund_approval == false); 

        address escrow_agent = buyerDatabase[buyerAddress][buyerID].escrow_agent;
        uint escrow_fee = buyerDatabase[buyerAddress][buyerID].escrow_fee;
        uint amount = buyerDatabase[buyerAddress][buyerID].amount;
    
        //Once approved, buyer can invoke WithdrawFunds to claim his refund
        buyerDatabase[buyerAddress][buyerID].refund_approval = true;

        Funds[buyerAddress] += amount;
        Funds[escrow_agent] += escrow_fee;
        
    }
    
    

    //Either buyer or seller can raise escalation with escrow agent. 
    //Once escalation is activated, escrow agent can release funds to seller OR make a full refund to buyer

    //Switcher = 0 for Buyer, Switcher = 1 for Seller
    function EscrowEscalation(uint switcher, uint ID) external
    {
        //To activate EscrowEscalation
        //1) Buyer must not have approved fund release.
        //2) Seller must not have approved a refund.
        //3) EscrowEscalation is being activated for the first time

        //There is no difference whether the buyer or seller activates EscrowEscalation.
        address buyerAddress;
        uint buyerID; //transaction ID of in buyer's history
        if (switcher == 0) // Buyer
        {
            buyerAddress = msg.sender;
            buyerID = ID;
        } else if (switcher == 1) //Seller
        {
            buyerAddress = sellerDatabase[msg.sender][ID].buyer;
            buyerID = sellerDatabase[msg.sender][ID].buyer_nounce;
        }

        require(buyerDatabase[buyerAddress][buyerID].escrow_intervention == false  &&
        buyerDatabase[buyerAddress][buyerID].release_approval == false &&
        buyerDatabase[buyerAddress][buyerID].refund_approval == false);

        //Activate the ability for Escrow Agent to intervent in this transaction
        buyerDatabase[buyerAddress][buyerID].escrow_intervention = true;

        
    }
    
    //ID is the transaction ID from Escrow's history. 
    //Decision = 0 is for refunding Buyer. Decision = 1 is for releasing funds to Seller
    function escrowDecision(uint ID, uint Decision) public
    {
        //Escrow can only make the decision IF
        //1) Buyer has not yet approved fund release to seller
        //2) Seller has not yet approved a refund to buyer
        //3) Escrow Agent has not yet approved fund release to seller AND not approved refund to buyer
        //4) Escalation Escalation is activated

        address buyerAddress = escrowDatabase[msg.sender][ID].buyer;
        uint buyerID = escrowDatabase[msg.sender][ID].buyer_nounce;
        

        require(
        buyerDatabase[buyerAddress][buyerID].release_approval == false &&
        buyerDatabase[buyerAddress][buyerID].escrow_intervention == true &&
        buyerDatabase[buyerAddress][buyerID].refund_approval == false);
        
        uint escrow_fee = buyerDatabase[buyerAddress][buyerID].escrow_fee;
        uint amount = buyerDatabase[buyerAddress][buyerID].amount;

        if (Decision == 0) //Refund Buyer
        {
            buyerDatabase[buyerAddress][buyerID].refund_approval = true;    
            Funds[buyerAddress] += amount;
            Funds[msg.sender] += escrow_fee;
            
        } else if (Decision == 1) //Release funds to Seller
        {                
            buyerDatabase[buyerAddress][buyerID].release_approval = true;
            Funds[buyerDatabase[buyerAddress][buyerID].seller] += amount;
            Funds[msg.sender] += escrow_fee;
        }  
    }
    
    function WithdrawFunds() public payable
    {
        uint amount = Funds[msg.sender];
        Funds[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        // if (!msg.sender.send(amount))
        // if (!msg.sender.send(amount))
        //  payable(Funds[msg.sender] = amount);
    }


    function CheckBalance(address fromAddress) public view returns (uint){
        return (Funds[fromAddress]);
    }
     
}