/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

/**
 *USDT version
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
        uint assetPrice;             // Asset Price as wei
        string assetTypeName;               // Asset Type Name        
    }

    uint internal currentAssetTypeCount;
    mapping(uint => AssetsTypeStruct) private assetTypeArrayMap;

    function addNewAssetType(string memory _assetTypeName, uint _assetPrice) public onlyOwner{
        require(_assetPrice != 0, "Asset Price can't be zero.");
        bytes memory tempEmptyStringTest = bytes(_assetTypeName); // Uses memory
        require(tempEmptyStringTest.length != 0, "Asset Type can't be null.");

        // require(msg.value == 10000000000000000, "Fund should be 1000000000000000000 wei = 0.01 ETH");

        AssetsTypeStruct memory newAssetType;
        newAssetType.assetTypeID = currentAssetTypeCount;
        newAssetType.assetTypeName = _assetTypeName;
        newAssetType.assetPrice = _assetPrice;
        // Didn't create providerArray
        assetTypeArrayMap[currentAssetTypeCount] = newAssetType;
        currentAssetTypeCount = currentAssetTypeCount + 1;
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
        AssetsTypeStruct[] memory assetTypeArray = new AssetsTypeStruct[](currentAssetTypeCount);

        for (uint i = 0; i < currentAssetTypeCount; i++)
        {
            assetTypeArray[i] = assetTypeArrayMap[i];
        }
        
        return assetTypeArray;
    }

    function getAssetTypeByID(uint _assetTypeID) internal view returns(AssetsTypeStruct memory){        
        return assetTypeArrayMap[_assetTypeID];
    }
}

abstract contract TetherToken {
    function transferFrom(address from, address to, uint value) virtual public payable;
    function balanceOf(address who) virtual public view returns (uint);
    function approve(address spender, uint value) virtual public;
    function allowance(address owner, address spender) virtual public returns (uint);
    function transfer(address to, uint value) virtual public;
}

contract EscrowProducer is Utilities, Ownable, AssetType{

    struct ProducerInfoStruct
    {    
        uint escrowID;                  // Escrow ID (Number auto-increased)
        uint createdDate;               // Created Date as Unixtimestamp
        uint quantity;                  // Count of Posted Assets
        uint amount;                    // Fund amount as Wei
        uint redeemedAmount;            // Redeemed amount as Wei
        uint redeemedQuantity;          // Count of Redeemed assets
        uint rebateReceivedAmount;      // Rebase Received amount as Wei
        uint remainingAmount;           // Remaining amount as Wei
        uint assetTypeID;               // Asset Type ID
        uint assetPrice;                // Asset Type Price
        string escrowName;              // Escrow Name
        address producer;               // Producer's wallet address
        string assetTypeName;               // Asset Type Name
        address[] providerArray;        // Provider address array
    }

    struct ProducerStruct
    {    
        uint escrowID;                  // Escrow ID (Number auto-increased)
        string escrowName;              // Escrow Name
        address producer;               // Producer's wallet address
        uint createdDate;               // Created Date as Unixtimestamp
        string[] postedAssets;            // Posted Assets as 10-digit array
        uint amount;                    // Fund amount as Wei
        uint redeemedAmount;            // Redeemed amount as Wei
        uint rebateReceivedAmount;      // Rebate Received amount as Wei
        uint remainingAmount;           // Remaining amount to redeem as Wei
        bool[] postedAssetsIsRedeemed;  // Posted Assets array as a bool - true if redeemed
        uint assetTypeID;               // Asset Type ID
        address[] providerArray;        // Provider address array
    }

    mapping(uint => ProducerStruct) private producerArrayMap;
    // ProducerStruct[] private producerArray;

    uint internal currentEscrowCount;
    uint public defaultEscrowFee;
    uint public producerRedeemPercentage;
    uint public providerRedeemPercentage;

    constructor(){
        // currentEscrowCount = 0;
        defaultEscrowFee = 10;
        producerRedeemPercentage = 20;
        providerRedeemPercentage = 80;
    }

    address constant usdtAddress = 0x791e8aa6A49A59FA37279247f136748c7DF38055; // Test net
    // address constant usdtAddress = 0xf8e81D47203A594245E36C48e151709F0C19fBe8; // Test net
    TetherToken usdtToken = TetherToken(address(usdtAddress));  

    function addNewProducerUSDT(string[] memory _postedAssets,string memory _escrowname, uint _assetTypeID, uint _amount) public returns(ProducerStruct memory){

        require(AssetType.checkValidAssetTypeID(_assetTypeID),"Invalid Asset Type");
        require(usdtToken.balanceOf(msg.sender) > _amount, "Your token is insufficient");
        require(usdtToken.allowance(msg.sender, address(this)) >= _amount, "You should get allowance from Tether USDT contract");

           
        require(_amount != 0, "Producer should deposit fund");
        // require(msg.value == 10000000000000000, "Fund should be 1000000000000000000 wei = 0.01 ETH");
        // require(_postedAssets.length == 10, "Random Array size should be 10.");

        // require(msg.value == 10, "Fund should be 10 wei");
        // require(msg.value == 10000000000000000000, "Fund should be 10 wei");


        AssetsTypeStruct memory assetType = AssetType.getAssetTypeByID(_assetTypeID);


        // check asset price 
        require(SafeMath.mul(assetType.assetPrice, _postedAssets.length) == _amount,"Insufficient funds");

        usdtToken.transferFrom(msg.sender, address(this), _amount);


        ProducerStruct memory newProducer;
        newProducer.escrowID = currentEscrowCount;
        newProducer.escrowName = _escrowname;
        newProducer.producer = msg.sender;
        newProducer.createdDate = Utilities.getCurrentTimeStamp();
        newProducer.postedAssets = _postedAssets;
        // newProducer.quantity = _postedAssets.length;
        newProducer.amount = _amount;     // it can set like msg.value
        newProducer.remainingAmount = _amount;   // Remaining amount = amount - (redeemedAmount + rebateReceivedAmount)     
        bool[] memory _postedAssetsIsRedeemed = new bool[](_postedAssets.length);
        newProducer.postedAssetsIsRedeemed = _postedAssetsIsRedeemed;
        
        newProducer.assetTypeID = _assetTypeID;

        address[] memory _providerArray;
        newProducer.providerArray = _providerArray;

        // Didn't create providerArray
        // producerArray.push(newProducer);  
        producerArrayMap[currentEscrowCount] = newProducer;
        currentEscrowCount = currentEscrowCount + 1;
        return newProducer;
    }

    function getProducerInfoArray() public view returns(ProducerInfoStruct[] memory){
        // ProducerInfoStruct[] memory producerInfoArray = new ProducerInfoStruct[](producerArray.length);
        ProducerInfoStruct[] memory producerInfoArray = new ProducerInfoStruct[](currentEscrowCount);

        for (uint i = 0; i < currentEscrowCount; i++)
        {
            ProducerInfoStruct memory producerInfo;
            producerInfo.escrowID = producerArrayMap[i].escrowID;
            producerInfo.escrowName = producerArrayMap[i].escrowName;
            producerInfo.producer = producerArrayMap[i].producer;
            producerInfo.createdDate = producerArrayMap[i].createdDate;
            producerInfo.quantity = producerArrayMap[i].postedAssets.length;
            producerInfo.amount = producerArrayMap[i].amount;
            producerInfo.redeemedAmount = producerArrayMap[i].redeemedAmount;
            producerInfo.rebateReceivedAmount = producerArrayMap[i].rebateReceivedAmount;
            producerInfo.remainingAmount = producerArrayMap[i].remainingAmount;
           
            AssetsTypeStruct memory assetType = AssetType.getAssetTypeByID(producerArrayMap[i].assetTypeID);

            producerInfo.assetTypeName = assetType.assetTypeName;
            producerInfo.assetPrice = assetType.assetPrice;
            producerInfo.assetTypeID = producerArrayMap[i].assetTypeID;

            producerInfo.providerArray = producerArrayMap[i].providerArray;

            uint redeemedCount;
            for (uint j = 0; j < producerArrayMap[i].postedAssetsIsRedeemed.length; j++)
            {
                if (producerArrayMap[i].postedAssetsIsRedeemed[j]){
                    redeemedCount += 1;
                }
            }
            producerInfo.redeemedQuantity = redeemedCount;

            producerInfoArray[i] = producerInfo;   
        }
        return producerInfoArray;
    }
    function getCountOfProducerByAddress(address _producer) internal view returns(uint){

        uint matchedCount ;
        for (uint i = 0; i < currentEscrowCount; i++)
        {
            if (producerArrayMap[i].producer == _producer){
                matchedCount += 1;
            }  
        }
        return matchedCount;
    }

    // function countOfMatchedAssets(uint _escrowID, string[] memory _collectedAssets) internal view returns(uint){  
    //     uint matchedCount ;
    //     for (uint i = 0; i < producerArrayMap[_escrowID].postedAssets.length; i++)
    //     {
    //         for (uint j = 0; j < _collectedAssets.length; j++)
    //         {
    //             // if (producerArray[_escrowID].postedAssets[i] == _collectedAssets[j]){
    //             if (keccak256(abi.encodePacked(producerArrayMap[_escrowID].postedAssets[i])) == keccak256(abi.encodePacked(_collectedAssets[j]))) {
    //                 if (producerArrayMap[_escrowID].postedAssetsIsRedeemed[i] != true){
    //                      matchedCount += 1;
    //                 }
    //             }
    //         }
    //     }
    //     return matchedCount;
    // }

    function findMatchedAssetsArray(uint _escrowID, string[] memory _collectedAssets) internal returns(uint){   

        // uint matchedCount = countOfMatchedAssets(_escrowID, _collectedAssets);
        // string[] memory matchedAssets = new string[](matchedCount);
        uint matchedCounttemp ;

        for (uint i = 0; i < producerArrayMap[_escrowID].postedAssets.length; i++)
        {
            for (uint j = 0; j < _collectedAssets.length; j++)
            {
                // if (producerArray[_escrowID].postedAssets[i] == _collectedAssets[j]){
                if (keccak256(abi.encodePacked(producerArrayMap[_escrowID].postedAssets[i])) == keccak256(abi.encodePacked(_collectedAssets[j]))) {
                    if (producerArrayMap[_escrowID].postedAssetsIsRedeemed[i] != true){
                        producerArrayMap[_escrowID].postedAssetsIsRedeemed[i] = true;
                        // matchedAssets[matchedCounttemp] = producerArrayMap[_escrowID].postedAssets[i];
                        matchedCounttemp += 1;
                    }
                }
            }
        }
        // return matchedAssets;
        return matchedCounttemp;
    }

    function findMatchedAssets(uint _escrowID, string[] memory _collectedAssets) internal returns(string memory,address, uint,uint,uint){
        // string[] memory matchedAssets = findMatchedAssetsArray(_escrowID,_collectedAssets);
        uint matchedAssetsLength = findMatchedAssetsArray(_escrowID,_collectedAssets);
      
        uint totalRedeemedAmount = matchedAssetsLength*producerArrayMap[_escrowID].amount/producerArrayMap[_escrowID].postedAssets.length;
        uint producerRedeemedAmount = SafeMath.div(SafeMath.mul(totalRedeemedAmount,SafeMath.mul(SafeMath.sub(100,defaultEscrowFee),producerRedeemPercentage)),10000);
        uint providerRedeemedAmount = SafeMath.div(SafeMath.mul(totalRedeemedAmount,SafeMath.mul(SafeMath.sub(100,defaultEscrowFee),providerRedeemPercentage)),10000);

        producerArrayMap[_escrowID].redeemedAmount = producerArrayMap[_escrowID].redeemedAmount + providerRedeemedAmount;
        producerArrayMap[_escrowID].rebateReceivedAmount = producerArrayMap[_escrowID].rebateReceivedAmount + producerRedeemedAmount;
        producerArrayMap[_escrowID].remainingAmount = producerArrayMap[_escrowID].remainingAmount - totalRedeemedAmount;
        
        uint redeemedCount ;
        for (uint j = 0; j < producerArrayMap[_escrowID].postedAssetsIsRedeemed.length; j++)
        {
            if (producerArrayMap[_escrowID].postedAssetsIsRedeemed[j]){
                redeemedCount += 1;
            }
        }
        // producerInfo.redeemedQuantity = redeemedCount;

        return (producerArrayMap[_escrowID].escrowName,producerArrayMap[_escrowID].producer, matchedAssetsLength,producerRedeemedAmount,providerRedeemedAmount);

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
        // string[] collectedAssets;         // Posted Assets as 10-digit array
        uint collectedAssetsLength;         // Posted Assets as 10-digit array
        // uint quantity;                  // Count of Posted Assets
        uint redeemedAmount;            // Redeemed amount as Wei
        uint rebateReceivedAmount;      // Rebate Received amount as Wei
    }
    // ProviderStruct[] private providerArray;
    uint public currentProviderCount;
    mapping(uint => ProviderStruct) private providerArrayMap;
    
    constructor(){
        // currentProviderCount = 0;
    }
    
    function addNewProvider(uint _escrowID, string memory _escrowName, address _producer,address _provider,uint _collectedAssetsLength, uint _redeemedAmount, uint _rebateReceivedAmount) internal returns(ProviderStruct memory){
       
        ProviderStruct memory newProvider;
        newProvider.providerID = currentProviderCount;
        newProvider.escrowID = _escrowID;
        newProvider.escrowName = _escrowName;
        newProvider.provider = _provider;
        newProvider.producer = _producer;
        newProvider.createdDate = Utilities.getCurrentTimeStamp();
        // newProvider.collectedAssets = _collectedAssets;
        newProvider.collectedAssetsLength = _collectedAssetsLength;
        // newProvider.quantity = _quantity;
        newProvider.redeemedAmount = _redeemedAmount;
        newProvider.rebateReceivedAmount = _rebateReceivedAmount;

        providerArrayMap[currentProviderCount] = newProvider;
        currentProviderCount = currentProviderCount + 1;

        return newProvider;
    }
    function getProviderInfoArray() public view returns(ProviderInfoStruct[] memory){
        ProviderInfoStruct[] memory providerInfoArray = new ProviderInfoStruct[](currentProviderCount);

        for (uint i = 0; i < currentProviderCount; i++)
        {
            ProviderInfoStruct memory providerInfo;
            providerInfo.providerID = providerArrayMap[i].providerID;
            providerInfo.escrowID = providerArrayMap[i].escrowID;
            providerInfo.escrowName = providerArrayMap[i].escrowName;
            providerInfo.provider = providerArrayMap[i].provider;
            providerInfo.producer = providerArrayMap[i].producer;
            providerInfo.createdDate = providerArrayMap[i].createdDate;
            providerInfo.quantity = providerArrayMap[i].collectedAssetsLength;
            providerInfo.redeemedAmount = providerArrayMap[i].redeemedAmount;
            providerInfo.rebateReceivedAmount = providerArrayMap[i].rebateReceivedAmount;

            providerInfoArray[i] = providerInfo;   
        }
        return providerInfoArray;
    }
    function getProviderInfoArrayByAddress(address _provider) public view returns(ProviderInfoStruct[] memory){
        uint matchedCount = getCountOfProviderByAddress(_provider);
        ProviderInfoStruct[] memory providerInfoArray = new ProviderInfoStruct[](matchedCount);
        uint matchedCounttemp ;

        for (uint i = 0; i < currentProviderCount; i++)
        {
             if (providerArrayMap[i].provider == _provider){
                ProviderInfoStruct memory providerInfo;
                providerInfo.providerID = providerArrayMap[i].providerID;
                providerInfo.escrowID = providerArrayMap[i].escrowID;
                providerInfo.escrowName = providerArrayMap[i].escrowName;
                providerInfo.provider = providerArrayMap[i].provider;
                providerInfo.producer = providerArrayMap[i].producer;
                providerInfo.createdDate = providerArrayMap[i].createdDate;
                providerInfo.quantity = providerArrayMap[i].collectedAssetsLength;
                providerInfo.redeemedAmount = providerArrayMap[i].redeemedAmount;
                providerInfo.rebateReceivedAmount = providerArrayMap[i].rebateReceivedAmount;

                providerInfoArray[matchedCounttemp] = providerInfo;
                matchedCounttemp += 1;
            }                
        }
        return providerInfoArray;
    }
    function getCountOfProviderByAddress(address _provider) internal view returns(uint){

        uint matchedCount ;
        for (uint i = 0; i < currentProviderCount; i++)
        {
            if (providerArrayMap[i].provider == _provider){
                matchedCount += 1;
            }  
        }
        return matchedCount;
    }
    function getProviderInfoByID(uint _providerID) public view returns(ProviderInfoStruct memory){
        ProviderInfoStruct memory providerInfo;
        providerInfo.providerID = providerArrayMap[_providerID].providerID;
        providerInfo.escrowID = providerArrayMap[_providerID].escrowID;
        providerInfo.escrowName = providerArrayMap[_providerID].escrowName;
        providerInfo.provider = providerArrayMap[_providerID].provider;
        providerInfo.producer = providerArrayMap[_providerID].producer;
        providerInfo.createdDate = providerArrayMap[_providerID].createdDate;
        providerInfo.quantity = providerArrayMap[_providerID].collectedAssetsLength;
        providerInfo.redeemedAmount = providerArrayMap[_providerID].redeemedAmount;
        providerInfo.rebateReceivedAmount = providerArrayMap[_providerID].rebateReceivedAmount;

        return providerInfo;
    }


// The below code must be disabled
    // Only Owner
    // function getProviderArray() public view returns(ProviderStruct[] memory) {
    //     return providerArray;
    // }
}
contract Redemption_v1_5 is EscrowProducer, EscrowProvider {
  
    
    function addProviderUSDT(string[] memory _collectedAssets) public returns(string memory){
        string memory result;
        result = "No Match Found";
        uint matchedAssetsCount ;
        for (uint i = 0; i < EscrowProducer.currentEscrowCount; i++)
        {
            (string memory producerEscrowName,address producerAddress, uint matchedAssetsLength, uint rebateReceivedAmount,uint redeemedAmount) = EscrowProducer.findMatchedAssets(i, _collectedAssets);
            
           
            if (matchedAssetsLength == 0 ) {
                
            }else{
                ProviderStruct memory newProvider;
                newProvider = EscrowProvider.addNewProvider(i, producerEscrowName, producerAddress, msg.sender,matchedAssetsLength,redeemedAmount,rebateReceivedAmount);

                // USDT
                usdtToken.transfer(msg.sender, redeemedAmount);
                usdtToken.transfer(producerAddress, rebateReceivedAmount);

               
                
                if (matchedAssetsCount == 0 ) {
                    result = "Match Found :";                    
                }else{

                }
               
                // for (uint j = 0; j<matchedAssets.length; j++){
                //         result = append(result,"#",matchedAssets[j], " ,");
                //         // result = append(result,"#",Strings.toString(matchedAssets[j]), " ,");
                // }
            }
            matchedAssetsCount = matchedAssetsCount + matchedAssetsLength;
        }            
        return result;
    }   

    function withdrawUSDT(uint256 _amount) external returns (uint256) {
        require(usdtToken.balanceOf(address(this)) > _amount, "Your token is insufficient");
        usdtToken.transfer(msg.sender, _amount);
        return usdtToken.balanceOf(msg.sender);
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}