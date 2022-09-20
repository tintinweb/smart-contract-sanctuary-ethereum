/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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



contract Utilities {
    // String append Utility
    function append(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c, d));
    }

    // Get Current TimeStamp
    function getCurrentTimeStamp() internal view returns(uint){
        return block.timestamp;
    }   
}

contract AssetType is Utilities, Ownable {
    struct AssetsTypeStruct
    {    
        uint assetTypeID;               // Asset Type ID (Number auto-increased)
        string assetTypeName;               // Asset Type Name
        uint assetPrice;             // Asset Price as wei
        uint createdDate;               // Created Date as Unixtimestamp       
        bool isActive;                  // Active status
    }

    AssetsTypeStruct[] private assetTypeArray;
    uint internal currentAssetTypeCount;

    constructor(){
        currentAssetTypeCount = 0;
    }

    function addNewAssetType(string memory _assetTypeName, uint _assetPrice) public onlyOwner{
        require(_assetPrice != 0, "Asset Price can't be zero.");
        bytes memory tempEmptyStringTest = bytes(_assetTypeName); // Uses memory
        require(tempEmptyStringTest.length != 0, "Asset Type can't be null.");

        // require(msg.value == 10000000000000000, "Fund should be 1000000000000000000 wei = 0.01 ETH");

        AssetsTypeStruct memory newAssetType;
        newAssetType.assetTypeID = currentAssetTypeCount;
        currentAssetTypeCount = currentAssetTypeCount + 1;
        newAssetType.assetTypeName = _assetTypeName;
        newAssetType.assetPrice = _assetPrice;
        newAssetType.createdDate = Utilities.getCurrentTimeStamp();
        newAssetType.isActive = true;
        // Didn't create providerArray
        assetTypeArray.push(newAssetType);
    }

    function setAssetTypeStatus(uint _assetTypeID,bool _isActive) public onlyOwner {
        require(_assetTypeID < currentAssetTypeCount, "Invalid Asset Type ID");
        assetTypeArray[_assetTypeID].isActive = _isActive;
    }

    function checkValidAssetTypeID(uint _assetTypeID) public view returns(bool){
        bool isValid = false;
        if(_assetTypeID < currentAssetTypeCount){
            isValid = true;
        }
        // if(!assetTypeArray[_assetTypeID].isActive){
        //     isValid = false;
        // }

        return isValid;
    }

    function getAssetsTypeArray() public view returns(AssetsTypeStruct[] memory){
        return assetTypeArray;
    }

    function getAssetTypeByID(uint _assetTypeID) internal view returns(AssetsTypeStruct memory){        
        return assetTypeArray[_assetTypeID];
    }
}

contract EscrowProducer is Utilities, Ownable, AssetType{

    struct ProducerInfoStruct
    {    
        uint escrowID;                  // Escrow ID (Number auto-increased)
        string escrowName;              // Escrow Name
        address producer;               // Producer's wallet address
        uint createdDate;               // Created Date as Unixtimestamp
        uint quantity;                  // Count of Posted Assets
        uint amount;                    // Fund amount as Wei
        uint redeemedAmount;            // Redeemed amount as Wei
        uint redeemedQuantity;          // Count of Redeemed assets
        uint rebateReceivedAmount;      // Rebase Received amount as Wei
        uint remainingAmount;           // Remaining amount as Wei
        uint escrowFee;                 // Escrow fee 
        bool isActive;                  // Active status
        uint redeemAmountPerNumber;     // Redeem amount per assets
        uint assetPrice;                // Asset Type Price
        string assetTypeName;               // Asset Type Name
        uint assetTypeID;               // Asset Type ID
        address[] providerArray;        // Provider address array
    }

    struct ProducerStruct
    {    
        uint escrowID;                  // Escrow ID (Number auto-increased)
        string escrowName;              // Escrow Name
        address producer;               // Producer's wallet address
        uint createdDate;               // Created Date as Unixtimestamp
        uint[] postedAssets;            // Posted Assets as 10-digit array
        uint quantity;                  // Count of Posted Assets
        uint amount;                    // Fund amount as Wei
        uint redeemedAmount;            // Redeemed amount as Wei
        uint rebateReceivedAmount;      // Rebate Received amount as Wei
        uint remainingAmount;           // Remaining amount to redeem as Wei
        bool[] postedAssetsIsRedeemed;  // Posted Assets array as a bool - true if redeemed
        uint escrowFee;                 // Escrow fee 
        bool isActive;                  // Active status
        uint redeemAmountPerNumber;     // Redeem amount per assets
        uint assetPrice;                // Asset Type Price
        string assetTypeName;               // Asset Type Name
        uint assetTypeID;               // Asset Type ID
        address[] providerArray;        // Provider address array
    }

    ProducerStruct[] private producerArray;

    uint internal currentEscrowCount;
    uint public defaultEscrowFee;
    uint public producerRedeemPercentage;
    uint public providerRedeemPercentage;

    constructor(){
        currentEscrowCount = 0;
        defaultEscrowFee = 10;
        producerRedeemPercentage = 20;
        providerRedeemPercentage = 80;
    }

    function addNewProducer(uint[] memory _postedAssets,string memory _escrowname, uint _assetTypeID) public payable returns(ProducerStruct memory){

        require(AssetType.checkValidAssetTypeID(_assetTypeID),"Invalid Asset Type");

        require(msg.value != 0, "Producer should deposit fund");
        // require(msg.value == 10000000000000000, "Fund should be 1000000000000000000 wei = 0.01 ETH");
        // require(_postedAssets.length == 10, "Random Array size should be 10.");

        // require(msg.value == 10, "Fund should be 10 wei");
        // require(msg.value == 10000000000000000000, "Fund should be 10 wei");


        AssetsTypeStruct memory assetType = AssetType.getAssetTypeByID(_assetTypeID);


        // check asset price 
        require(SafeMath.mul(assetType.assetPrice, _postedAssets.length) == msg.value,"Insufficient funds");


        ProducerStruct memory newProducer;
        newProducer.escrowID = currentEscrowCount;
        currentEscrowCount = currentEscrowCount + 1;
        newProducer.escrowName = _escrowname;
        newProducer.producer = msg.sender;
        newProducer.createdDate = Utilities.getCurrentTimeStamp();
        newProducer.postedAssets = _postedAssets;
        newProducer.quantity = _postedAssets.length;
        newProducer.amount = msg.value;     // it can set like msg.value
        newProducer.redeemedAmount = 0;     
        newProducer.rebateReceivedAmount = 0;     
        newProducer.remainingAmount = msg.value;   // Remaining amount = amount - (redeemedAmount + rebateReceivedAmount)     
        bool[] memory _postedAssetsIsRedeemed = new bool[](_postedAssets.length);
        newProducer.postedAssetsIsRedeemed = _postedAssetsIsRedeemed;
        newProducer.escrowFee = defaultEscrowFee;
        newProducer.isActive = true;
        newProducer.redeemAmountPerNumber = msg.value/_postedAssets.length;
        newProducer.assetTypeName = assetType.assetTypeName;
        newProducer.assetPrice = assetType.assetPrice;
        newProducer.assetTypeID = _assetTypeID;

        address[] memory _providerArray;
        newProducer.providerArray = _providerArray;

        // Didn't create providerArray
        producerArray.push(newProducer);

        return newProducer;
    }

    function getProducerInfoArray() public view returns(ProducerInfoStruct[] memory){
        ProducerInfoStruct[] memory producerInfoArray = new ProducerInfoStruct[](producerArray.length);

        for (uint i = 0; i < producerArray.length; i++)
        {
            ProducerInfoStruct memory producerInfo;
            producerInfo.escrowID = producerArray[i].escrowID;
            producerInfo.escrowName = producerArray[i].escrowName;
            producerInfo.producer = producerArray[i].producer;
            producerInfo.createdDate = producerArray[i].createdDate;
            producerInfo.quantity = producerArray[i].quantity;
            producerInfo.amount = producerArray[i].amount;
            producerInfo.redeemedAmount = producerArray[i].redeemedAmount;
            producerInfo.rebateReceivedAmount = producerArray[i].rebateReceivedAmount;
            producerInfo.remainingAmount = producerArray[i].remainingAmount;
            producerInfo.escrowFee = producerArray[i].escrowFee;
            producerInfo.isActive = producerArray[i].isActive;
            producerInfo.redeemAmountPerNumber = producerArray[i].redeemAmountPerNumber;
            
            producerInfo.assetTypeName = producerArray[i].assetTypeName;
            producerInfo.assetPrice = producerArray[i].assetPrice;
            producerInfo.assetTypeID = producerArray[i].assetTypeID;

            producerInfo.providerArray = producerArray[i].providerArray;

            uint redeemedCount = 0;
            for (uint j = 0; j < producerArray[i].postedAssetsIsRedeemed.length; j++)
            {
                if (producerArray[i].postedAssetsIsRedeemed[j]){
                    redeemedCount += 1;
                }
            }
            producerInfo.redeemedQuantity = redeemedCount;

            producerInfoArray[i] = producerInfo;   
        }
        return producerInfoArray;
    }
    function getProducerInfoArrayByAddress(address _producer) public view returns(ProducerInfoStruct[] memory){
        uint matchedCount = getCountOfProducerByAddress(_producer);
        ProducerInfoStruct[] memory producerInfoArray = new ProducerInfoStruct[](matchedCount);
        uint matchedCounttemp = 0;

        for (uint i = 0; i < producerArray.length; i++)
        {
             if (producerArray[i].producer == _producer){
                ProducerInfoStruct memory producerInfo;
                producerInfo.escrowID = producerArray[i].escrowID;
                producerInfo.escrowName = producerArray[i].escrowName;
                producerInfo.producer = producerArray[i].producer;
                producerInfo.createdDate = producerArray[i].createdDate;
                producerInfo.quantity = producerArray[i].quantity;
                producerInfo.amount = producerArray[i].amount;
                producerInfo.redeemedAmount = producerArray[i].redeemedAmount;
                producerInfo.rebateReceivedAmount = producerArray[i].rebateReceivedAmount;
                producerInfo.remainingAmount = producerArray[i].remainingAmount;
                producerInfo.escrowFee = producerArray[i].escrowFee;
                producerInfo.isActive = producerArray[i].isActive;
                producerInfo.redeemAmountPerNumber = producerArray[i].redeemAmountPerNumber;
                producerInfo.assetTypeName = producerArray[i].assetTypeName;
                producerInfo.assetPrice = producerArray[i].assetPrice;
                producerInfo.assetTypeID = producerArray[i].assetTypeID;
                producerInfo.providerArray = producerArray[i].providerArray;
                producerInfoArray[matchedCounttemp] = producerInfo;
                uint redeemedCount = 0;
                for (uint j = 0; j < producerArray[i].postedAssetsIsRedeemed.length; j++)
                {
                    if (producerArray[i].postedAssetsIsRedeemed[j]){
                        redeemedCount += 1;
                    }
                }
                producerInfo.redeemedQuantity = redeemedCount;
                matchedCounttemp += 1;
            } 
               
        }
        return producerInfoArray;
    }
    function getCountOfProducerByAddress(address _producer) internal view returns(uint){

        uint matchedCount = 0;
        for (uint i = 0; i < producerArray.length; i++)
        {
            if (producerArray[i].producer == _producer){
                matchedCount += 1;
            }  
        }
        return matchedCount;
    }

    function getProducerInfoByID(uint _escrowID) public view returns(ProducerInfoStruct memory){
        ProducerInfoStruct memory producerInfo;
        producerInfo.escrowID = producerArray[_escrowID].escrowID;
        producerInfo.escrowName = producerArray[_escrowID].escrowName;
        producerInfo.producer = producerArray[_escrowID].producer;
        producerInfo.createdDate = producerArray[_escrowID].createdDate;
        producerInfo.quantity = producerArray[_escrowID].quantity;
        producerInfo.amount = producerArray[_escrowID].amount;
        producerInfo.redeemedAmount = producerArray[_escrowID].redeemedAmount;
        producerInfo.rebateReceivedAmount = producerArray[_escrowID].rebateReceivedAmount;
        producerInfo.remainingAmount = producerArray[_escrowID].remainingAmount;
        producerInfo.escrowFee = producerArray[_escrowID].escrowFee;
        producerInfo.isActive = producerArray[_escrowID].isActive;
        producerInfo.redeemAmountPerNumber = producerArray[_escrowID].redeemAmountPerNumber;
        producerInfo.assetTypeName = producerArray[_escrowID].assetTypeName;
        producerInfo.assetPrice = producerArray[_escrowID].assetPrice;
        producerInfo.assetTypeID = producerArray[_escrowID].assetTypeID;
        producerInfo.providerArray = producerArray[_escrowID].providerArray;

        uint redeemedCount = 0;
        for (uint j = 0; j < producerArray[_escrowID].postedAssetsIsRedeemed.length; j++)
        {
            if (producerArray[_escrowID].postedAssetsIsRedeemed[j]){
                redeemedCount += 1;
            }
        }
        producerInfo.redeemedQuantity = redeemedCount;
        return producerInfo;
    }

    function countOfMatchedAssets(uint _escrowID, uint[] memory _collectedAssets) internal view returns(uint){  
        uint matchedCount = 0;
        for (uint i = 0; i < producerArray[_escrowID].postedAssets.length; i++)
        {
            for (uint j = 0; j < _collectedAssets.length; j++)
            {
                if (producerArray[_escrowID].postedAssets[i] == _collectedAssets[j]){
                    if (producerArray[_escrowID].postedAssetsIsRedeemed[i] != true){
                         matchedCount += 1;
                    }
                }
            }
        }
        return matchedCount;
    }

    function findMatchedAssetsArray(uint _escrowID, uint[] memory _collectedAssets) internal returns(uint[] memory){   

        uint matchedCount = countOfMatchedAssets(_escrowID, _collectedAssets);
        uint[] memory matchedAssets = new uint[](matchedCount);
        uint matchedCounttemp = 0;

        for (uint i = 0; i < producerArray[_escrowID].postedAssets.length; i++)
        {
            for (uint j = 0; j < _collectedAssets.length; j++)
            {
                if (producerArray[_escrowID].postedAssets[i] == _collectedAssets[j]){
                    if (producerArray[_escrowID].postedAssetsIsRedeemed[i] != true){
                        producerArray[_escrowID].postedAssetsIsRedeemed[i] = true;
                        matchedAssets[matchedCounttemp] = producerArray[_escrowID].postedAssets[i];
                        matchedCounttemp += 1;
                    }
                }
            }
        }
        return matchedAssets;
    }

    function findMatchedAssets(uint _escrowID, uint[] memory _collectedAssets) internal returns(ProducerInfoStruct memory, uint[] memory,uint,uint){
        uint[] memory matchedAssets = findMatchedAssetsArray(_escrowID,_collectedAssets);

        ProducerInfoStruct memory producerInfo;
        producerInfo.escrowID = producerArray[_escrowID].escrowID;
        producerInfo.escrowName = producerArray[_escrowID].escrowName;
        producerInfo.producer = producerArray[_escrowID].producer;
        producerInfo.createdDate = producerArray[_escrowID].createdDate;
        producerInfo.quantity = producerArray[_escrowID].quantity;
        producerInfo.amount = producerArray[_escrowID].amount;
        producerInfo.assetTypeName = producerArray[_escrowID].assetTypeName;
        producerInfo.assetPrice = producerArray[_escrowID].assetPrice;
        producerInfo.assetTypeID = producerArray[_escrowID].assetTypeID;

        uint totalRedeemedAmount = matchedAssets.length*producerArray[_escrowID].redeemAmountPerNumber;
        uint producerRedeemedAmount = SafeMath.div(SafeMath.mul(totalRedeemedAmount,SafeMath.mul(SafeMath.sub(100,defaultEscrowFee),producerRedeemPercentage)),10000);
        uint providerRedeemedAmount = SafeMath.div(SafeMath.mul(totalRedeemedAmount,SafeMath.mul(SafeMath.sub(100,defaultEscrowFee),providerRedeemPercentage)),10000);

        producerArray[_escrowID].redeemedAmount = producerArray[_escrowID].redeemedAmount + providerRedeemedAmount;
        producerArray[_escrowID].rebateReceivedAmount = producerArray[_escrowID].rebateReceivedAmount + producerRedeemedAmount;
        producerArray[_escrowID].remainingAmount = producerArray[_escrowID].remainingAmount - totalRedeemedAmount;

        producerInfo.redeemedAmount = producerArray[_escrowID].redeemedAmount;
        producerInfo.rebateReceivedAmount = producerArray[_escrowID].rebateReceivedAmount;
        producerInfo.remainingAmount = producerArray[_escrowID].remainingAmount;
        producerInfo.escrowFee = producerArray[_escrowID].escrowFee;
        producerInfo.isActive = producerArray[_escrowID].isActive;
        producerInfo.redeemAmountPerNumber = producerArray[_escrowID].redeemAmountPerNumber;
        producerInfo.providerArray = producerArray[_escrowID].providerArray;
        uint redeemedCount = 0;
        for (uint j = 0; j < producerArray[_escrowID].postedAssetsIsRedeemed.length; j++)
        {
            if (producerArray[_escrowID].postedAssetsIsRedeemed[j]){
                redeemedCount += 1;
            }
        }
        producerInfo.redeemedQuantity = redeemedCount;

        return (producerInfo, matchedAssets,producerRedeemedAmount,providerRedeemedAmount);

    }

// The below code must be disabled
    // Only Owner
    // function getProducerArray() public view returns(ProducerStruct[] memory) {
    //     return producerArray;
    // }
}


contract EscrowProvider is Utilities, Ownable{

    struct ProviderInfoStruct
    {    
        uint providerID;                // Provider ID
        uint escrowID;                  // Escrow ID (Number auto-increased)
        string escrowName;              // Escrow Name
        address producer;               // Producer's wallet address
        address provider;               // Provider's wallet address
        uint createdDate;               // Created Date as Unixtimestamp
        uint quantity;                  // Count of Posted Assets
        uint redeemedAmount;            // Redeemed amount as Wei
        uint rebateReceivedAmount;      // Rebate Received amount as Wei
    }

    struct ProviderStruct
    {    
        uint providerID;                // Provider ID 
        uint escrowID;                  // Escrow ID
        string escrowName;              // Escrow Name
        address producer;               // Producer's wallet address
        address provider;               // Provider's wallet address
        uint createdDate;               // Created Date as Unixtimestamp
        uint[] collectedAssets;         // Posted Assets as 10-digit array
        uint quantity;                  // Count of Posted Assets
        uint redeemedAmount;            // Redeemed amount as Wei
        uint rebateReceivedAmount;      // Rebate Received amount as Wei
    }
    ProviderStruct[] private providerArray;
    uint private currentProviderCount;
    
    constructor(){
        currentProviderCount = 0;
    }
    
    function addNewProvider(uint _escrowID, string memory _escrowName, address _producer,address _provider,uint[] memory _collectedAssets,uint _quantity, uint _redeemedAmount, uint _rebateReceivedAmount) internal returns(ProviderStruct memory){
       
        ProviderStruct memory newProvider;
        newProvider.providerID = currentProviderCount;
        currentProviderCount = currentProviderCount + 1;
        newProvider.escrowID = _escrowID;
        newProvider.escrowName = _escrowName;
        newProvider.provider = _provider;
        newProvider.producer = _producer;
        newProvider.createdDate = Utilities.getCurrentTimeStamp();
        newProvider.collectedAssets = _collectedAssets;
        newProvider.quantity = _quantity;
        newProvider.redeemedAmount = _redeemedAmount;
        newProvider.rebateReceivedAmount = _rebateReceivedAmount;

        providerArray.push(newProvider);

        return newProvider;
    }
    function getProviderInfoArray() public view returns(ProviderInfoStruct[] memory){
        ProviderInfoStruct[] memory providerInfoArray = new ProviderInfoStruct[](providerArray.length);

        for (uint i = 0; i < providerArray.length; i++)
        {
            ProviderInfoStruct memory providerInfo;
            providerInfo.providerID = providerArray[i].providerID;
            providerInfo.escrowID = providerArray[i].escrowID;
            providerInfo.escrowName = providerArray[i].escrowName;
            providerInfo.provider = providerArray[i].provider;
            providerInfo.producer = providerArray[i].producer;
            providerInfo.createdDate = providerArray[i].createdDate;
            providerInfo.quantity = providerArray[i].quantity;
            providerInfo.redeemedAmount = providerArray[i].redeemedAmount;
            providerInfo.rebateReceivedAmount = providerArray[i].rebateReceivedAmount;

            providerInfoArray[i] = providerInfo;   
        }
        return providerInfoArray;
    }
    function getProviderInfoArrayByAddress(address _provider) public view returns(ProviderInfoStruct[] memory){
        uint matchedCount = getCountOfProviderByAddress(_provider);
        ProviderInfoStruct[] memory providerInfoArray = new ProviderInfoStruct[](matchedCount);
        uint matchedCounttemp = 0;

        for (uint i = 0; i < providerArray.length; i++)
        {
             if (providerArray[i].provider == _provider){
                ProviderInfoStruct memory providerInfo;
                providerInfo.providerID = providerArray[i].providerID;
                providerInfo.escrowID = providerArray[i].escrowID;
                providerInfo.escrowName = providerArray[i].escrowName;
                providerInfo.provider = providerArray[i].provider;
                providerInfo.producer = providerArray[i].producer;
                providerInfo.createdDate = providerArray[i].createdDate;
                providerInfo.quantity = providerArray[i].quantity;
                providerInfo.redeemedAmount = providerArray[i].redeemedAmount;
                providerInfo.rebateReceivedAmount = providerArray[i].rebateReceivedAmount;

                providerInfoArray[matchedCounttemp] = providerInfo;
                matchedCounttemp += 1;
            }                
        }
        return providerInfoArray;
    }
    function getCountOfProviderByAddress(address _provider) internal view returns(uint){

        uint matchedCount = 0;
        for (uint i = 0; i < providerArray.length; i++)
        {
            if (providerArray[i].provider == _provider){
                matchedCount += 1;
            }  
        }
        return matchedCount;
    }
    function getProviderInfoByID(uint _providerID) public view returns(ProviderInfoStruct memory){
        ProviderInfoStruct memory providerInfo;
        providerInfo.providerID = providerArray[_providerID].providerID;
        providerInfo.escrowID = providerArray[_providerID].escrowID;
        providerInfo.escrowName = providerArray[_providerID].escrowName;
        providerInfo.provider = providerArray[_providerID].provider;
        providerInfo.producer = providerArray[_providerID].producer;
        providerInfo.createdDate = providerArray[_providerID].createdDate;
        providerInfo.quantity = providerArray[_providerID].quantity;
        providerInfo.redeemedAmount = providerArray[_providerID].redeemedAmount;
        providerInfo.rebateReceivedAmount = providerArray[_providerID].rebateReceivedAmount;

        return providerInfo;
    }


// The below code must be disabled
    // Only Owner
    // function getProviderArray() public view returns(ProviderStruct[] memory) {
    //     return providerArray;
    // }
}
contract REscrow is EscrowProducer, EscrowProvider {
  
    function addProvider(uint[] memory _collectedAssets) public returns(string memory){
        string memory result;
        result = "No Match Found";
        uint matchedAssetsCount = 0;
        for (uint i = 0; i < EscrowProducer.currentEscrowCount; i++)
        {
            (ProducerInfoStruct memory producerInfo, uint[] memory matchedAssets, uint rebateReceivedAmount,uint redeemedAmount) = EscrowProducer.findMatchedAssets(i, _collectedAssets);
            ProviderStruct memory newProvider;
            newProvider = EscrowProvider.addNewProvider(i, producerInfo.escrowName, producerInfo.producer, msg.sender,_collectedAssets,matchedAssets.length,redeemedAmount,rebateReceivedAmount);

            payable(msg.sender).transfer(redeemedAmount);
            payable(producerInfo.producer).transfer(rebateReceivedAmount);


            if (matchedAssets.length == 0 ) {
                
            }else{
                if (matchedAssetsCount == 0 ) {
                    result = "Match Found :";                    
                }else{

                }
                for (uint j = 0; j<matchedAssets.length; j++){
                        result = append(result,"#",Strings.toString(matchedAssets[j]), " ,");
                }
            }
            matchedAssetsCount = matchedAssetsCount + matchedAssets.length;
        }            
        return result;
    }   

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    // function addProvider(uint _escrowID, uint[] memory _collectedAssets) public returns(string memory){
    //     (ProducerInfoStruct memory producerInfo, uint[] memory matchedAssets, uint redeemedAmount, uint rebateReceivedAmount) = EscrowProducer.findMatchedAssets(_escrowID, _collectedAssets);
    //     ProviderStruct memory newProvider;
    //     newProvider = EscrowProvider.addNewProvider(_escrowID, producerInfo.escrowName, producerInfo.producer, msg.sender,_collectedAssets,matchedAssets.length,redeemedAmount,rebateReceivedAmount);


    //     payable(msg.sender).transfer(redeemedAmount);
    //     payable(producerInfo.producer).transfer(rebateReceivedAmount);

    //     string memory result;
    //     if (matchedAssets.length == 0 ) {
    //         result = "No Match Found";
    //     }else{
    //         result = "Match Found :";
    //         for (uint i = 0; i<matchedAssets.length; i++){
    //             result = append(result,"#",Strings.toString(matchedAssets[i]), " ,");
    //         }
    //     }
    //     return result;
    // }   
}