/**
 *Submitted for verification at Etherscan.io on 2022-03-21
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


abstract contract Utilities {
    // String append Utility
    function append(string memory a, string memory b, string memory c, string memory d) public pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }

    // Get Current TimeStamp
    function getCurrentTimeStamp() public view returns(uint){
        return block.timestamp;
    }   
}


contract REscrow is Ownable, Utilities {
    struct EscrowStruct
    {    
        uint escrowID;
        address buyer;
        string escrowName;
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

    function getBuyerDataBaseByAddress(address _buyerAddress)public view onlyOwner returns(EscrowStruct[] memory){
        return buyerDatabase[_buyerAddress];
    }
    function getSellerDataBaseByAddress(address _sellerAddress)public view onlyOwner returns(SellerStruct[] memory){
        return sellerDatabase[_sellerAddress];
    }
    function getEscrowArray()public view onlyOwner returns(EscrowStruct[] memory){
        return escrowArray;
    }
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
        require(isExist, "Invalid ID");
        escrowInfo.isActive = _isActive;
    }
    // Get Escrow Fee By ID
    function getEscrowStatusByID(uint _escrowID) public view onlyOwner returns(bool){
        (EscrowStruct memory escrowInfo, bool isExist) = getEscrowByID(_escrowID);
        require(isExist, "Invalid ID");
        return escrowInfo.isActive;
    }
    // Set Escrow Fee By ID
    function setEscrowFeeByID(uint _escrowID,uint _escrowFee) external view onlyOwner {
        (EscrowStruct memory escrowInfo, bool isExist) = getEscrowByID(_escrowID);
        require(isExist, "Invalid ID");
        escrowInfo.escrowFee = _escrowFee;
    }
    // Get Escrow Fee By ID
    function getEscrowFeeByID(uint _escrowID) public view onlyOwner returns(uint){
        (EscrowStruct memory escrowInfo, bool isExist) = getEscrowByID(_escrowID);
        require(isExist, "Invalid ID");
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
        require(_partyApercentage+_partyBpercentage== 100,"Total should be 100%");
        partyApercentage = _partyBpercentage;
        partyBpercentage = _partyBpercentage;
    }
    // Get Contract Escrow Fee
    function getSplitPercentage() public view onlyOwner returns(uint, uint){
        return (partyApercentage, partyBpercentage);
    }

    function getEscrowNameByEscroID(uint _escrowID) public view returns(string memory) {
        (,bool isExist,) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "Invalid ID");
        return  escrowArray[_escrowID].escrowName;
    }
    function updateEscrowNameByID(string memory _newEscrowName, uint _escrowID) public {
        (address buyeraddress, bool isExist,) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "EscrowID is invaild");
        require(msg.sender == buyeraddress, "You are not the onwer of this escrow.");
        uint index = getBuyerDataBaseIndexByAddress(buyeraddress, _escrowID);
        buyerDatabase[buyeraddress][index].escrowName = _newEscrowName;
        escrowArray[_escrowID].escrowName = _newEscrowName;
    }
    function updateEscrowNameByIDByOwner(string memory _newEscrowName, uint _escrowID) public onlyOwner{
        (address buyeraddress, bool isExist,) = getBuyerAddressByEscrowID(_escrowID);
        require(isExist, "Invalid ID");
        uint index = getBuyerDataBaseIndexByAddress(buyeraddress, _escrowID);
        buyerDatabase[buyeraddress][index].escrowName = _newEscrowName;
        escrowArray[_escrowID].escrowName = _newEscrowName;
    }

    // Functions for finding Mached assets

   
    // Find Matched Assets by Escrow ID and collected assets    
    function getMatchedAssets(uint _escrowID, uint[] memory _collectedAssets) private returns(uint[] memory){   

        (uint[] memory postedAssets, bool[] memory postedAssetsIsRedeemed, bool isExist) = getPostedAssetsByEscrowID(_escrowID);
        require(isExist, "Invalid ID");

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
        (uint[] memory postedAssets, bool[] memory postedAssetsIsRedeemed,) = getPostedAssetsByEscrowID(_escrowID);
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
        (address buyerAddress,,) = getBuyerAddressByEscrowID(_escrowID);
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
    // function getListofActiveEscrow() public view returns(uint[] memory,address[] memory){
    function getListofActiveEscrow() public view returns(uint[] memory, string[] memory,address[] memory){
        (uint activeEscrowcount) = getCountOfActiveEscrow();
        uint[] memory escrowIDArray = new uint[](activeEscrowcount);
        address[] memory buyerAddressArray = new address[](activeEscrowcount);
        string[] memory escrowNameArray = new string[](activeEscrowcount);
        for (uint i = 0 ; i < escrowArray.length; i ++){
            if(escrowArray[i].isActive){
                escrowIDArray[i] = escrowArray[i].escrowID;
                buyerAddressArray[i] = escrowArray[i].buyer;
                escrowNameArray[i] = escrowArray[i].escrowName;
            }
        }
        return (escrowIDArray,escrowNameArray, buyerAddressArray);
        // return (escrowIDArray, buyerAddressArray);
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
    // function getListofSellers() public view returns(uint[] memory, address[] memory){
    //     uint[] memory escrowIDArray = new uint[](sellerArray.length);
    //     address[] memory sellerAddressArray = new address[](sellerArray.length);

    //     for (uint i = 0 ; i < sellerArray.length; i ++){
    //         escrowIDArray[i] = sellerArray[i].escrowID;
    //         sellerAddressArray[i] = sellerArray[i].seller;
    //     }

    //     return (escrowIDArray, sellerAddressArray);
    // }

    // Get List of Seller Array by Escrow ID
    // function getListOfSellersByEscrowID(uint _escrowID) public view returns(address[] memory){
    //     (EscrowStruct memory buyerInfo, bool isExist) = getBuyerInformationByEscrowID(_escrowID);
    //     require(isExist, "Invalid ID");
    //     return buyerInfo.sellerAddressArray;
    // }

    // Get Buyer Information by Escrow ID
    // function getBuyerInformationByEscrowID(uint _escrowID) private view returns(EscrowStruct memory,bool){
    //     bool isExist = false;
    //     EscrowStruct memory buyerInfo;
    //     for (uint i = 0; i < escrowArray.length; i++)
    //     {
    //         if (escrowArray[i].escrowID == _escrowID){
    //             buyerInfo = escrowArray[i];
    //             isExist = true;
    //         }
    //     }
    //     return (buyerInfo, isExist);
    // }

    // Get Redeemed Cost By Escrow Id
    // function getRedeemedCostPerAssetsrByEscrowID(uint _escrowID) public view returns(uint){
    //     (address buyeraddress, bool isExist,) = getBuyerAddressByEscrowID(_escrowID);
    //     require(isExist, "EscrowID is invaild");
    //     uint index = getBuyerDataBaseIndexByAddress(buyeraddress, _escrowID);
    //     return buyerDatabase[buyeraddress][index].redeemAmountPerNumber;
    // }
    

// Create Escrow and Post Collected Numbers

    // Create Escrow with posted assets from Party A
    // function createNewEscrow(uint[] memory _postedAssets) public payable{
    function createNewEscrow(uint[] memory _postedAssets,string memory _escrowname) public payable{
        require(msg.value == 1000000000000000000, "Fund should be 1000000000000000000 wei = 1 ETH");
        require(_postedAssets.length == 10, "Random Array size should be 10.");
        // require(msg.value == 10, "Fund should be 10 wei");
        // require(msg.value == 10000000000000000000, "Fund should be 10 wei");
        EscrowStruct memory newEscrow;
        newEscrow.escrowID = escrowCount;
        newEscrow.escrowName = _escrowname;
        escrowCount = escrowCount + 1;
        newEscrow.buyer = msg.sender;
        newEscrow.amount = msg.value;
        newEscrow.postedAssets = _postedAssets;
        bool[] memory _postedAssetsIsRedeemed = new bool[](_postedAssets.length);
        newEscrow.postedAssetsIsRedeemed = _postedAssetsIsRedeemed;
        newEscrow.redeemAmountPerNumber = msg.value/_postedAssets.length;
        newEscrow.createdDate = Utilities.getCurrentTimeStamp();
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
}