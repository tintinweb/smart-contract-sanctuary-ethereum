/**
 *Submitted for verification at Etherscan.io on 2022-05-20
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
    // function append(string memory a, string memory b, string memory c, string memory d) internal pure returns (string memory) {
    //     return string(abi.encodePacked(a, b, c, d));
    // }

    // Get Current TimeStamp
    function getCurrentTimeStamp() internal view returns(uint){
        return block.timestamp;
    }   
}

contract POCEscrowAsset is Utilities,Ownable {
    struct POCEscrowAssetStruct {
        uint assetID;                   // Asset Type ID (Number auto-increased)
        string sellerName;              // Seller Name
        address sellerAddress;          // Seller Address
        // string assetName;              // Asset Name
        uint assetCost;                 // Asset Cost
        uint createdDate;               // Created Date as Unixtimestamp       
        bool isActive;                  // Asset Active status : true - Active, False : InActive
        uint assetStatusCode;           // asset status code - 0 : created, 1 : approved by seller, 2 : released, 3 : cancelled 
    }

    POCEscrowAssetStruct[] private pocEscrowAssetsArray;
    uint internal currentEscrowAssetCount;

    constructor(){
        currentEscrowAssetCount = 0;
    }
    function addNewAsset(string memory _sellerName, address _sellerAddress, uint _assetCost) internal {
        require(_assetCost != 0, "Asset Price can't be zero.");
        // bytes memory tempEmptyStringTest = bytes(_sellerName); // Uses memory
        // require(tempEmptyStringTest.length != 0, "Seller name can't be null.");

        POCEscrowAssetStruct memory newEscrowAsset;
        newEscrowAsset.assetID = currentEscrowAssetCount;
        currentEscrowAssetCount = currentEscrowAssetCount + 1;
        newEscrowAsset.sellerName = _sellerName;
        newEscrowAsset.sellerAddress = _sellerAddress;

        // newEscrowAsset.assetName = _assetName;

        newEscrowAsset.assetCost = _assetCost;
        newEscrowAsset.createdDate = Utilities.getCurrentTimeStamp();
        newEscrowAsset.isActive = true;
        newEscrowAsset.assetStatusCode = 0;
        pocEscrowAssetsArray.push(newEscrowAsset);
    }

    function getAssetsArray() public view returns(POCEscrowAssetStruct[] memory){
        return pocEscrowAssetsArray;
    }

    function setAssetActiveStatus(uint _assetID,bool _isActive) public  {
        require(_assetID < currentEscrowAssetCount, "Invalid Asset Type ID");
        pocEscrowAssetsArray[_assetID].isActive = _isActive;
    }
     // asset status code - 0 : created, 1 : approved by seller, 2 : released, 3 : cancelled 
    function setAssetStatusCode(uint _assetID,uint _assetStatusCode) public  {
        require(_assetID < currentEscrowAssetCount, "Invalid Asset Type ID");
        pocEscrowAssetsArray[_assetID].assetStatusCode = _assetStatusCode;
    }

    function getAssetByID(uint _assetID) internal view returns(POCEscrowAssetStruct memory){  
        require(_assetID < currentEscrowAssetCount, "Invalid Asset Type ID");
        return pocEscrowAssetsArray[_assetID];
    }

    function getCountOfAssetByAddress(address _sellerAddress) internal view returns(uint){

        uint matchedCount = 0;
        for (uint i = 0; i < pocEscrowAssetsArray.length; i++)
        {
            if (pocEscrowAssetsArray[i].sellerAddress == _sellerAddress){
                matchedCount += 1;
            }  
        }
        return matchedCount;
    }

    function getAssetByAddress(address _sellerAddress) public view returns(POCEscrowAssetStruct[] memory){ 

        uint matchedCount = getCountOfAssetByAddress(_sellerAddress);
        POCEscrowAssetStruct[] memory escrowAssetArray = new POCEscrowAssetStruct[](matchedCount);
        uint matchedCounttemp = 0;

        for (uint i = 0; i < pocEscrowAssetsArray.length; i++)
        {
            if(_sellerAddress == pocEscrowAssetsArray[i].sellerAddress){
                escrowAssetArray[matchedCounttemp] = pocEscrowAssetsArray[i];
                matchedCounttemp += 1;
            }
        }
        return escrowAssetArray;
    }

    function getCountOfAssetBySellerName(string memory _sellerName) public view returns(uint){

        uint matchedCount = 0;
        for (uint i = 0; i < pocEscrowAssetsArray.length; i++)
        {
            if (keccak256(abi.encodePacked(pocEscrowAssetsArray[i].sellerName)) == keccak256(abi.encodePacked(_sellerName))) {
                matchedCount += 1;
            }
        }
        return matchedCount;
    }

    function getAssetBySellerName(string memory _sellerName) public view returns(POCEscrowAssetStruct[] memory){ 

        uint matchedCount = getCountOfAssetBySellerName(_sellerName);
        POCEscrowAssetStruct[] memory escrowAssetArray = new POCEscrowAssetStruct[](matchedCount);
        uint matchedCounttemp = 0;

        for (uint i = 0; i < pocEscrowAssetsArray.length; i++)
        {
            if (keccak256(abi.encodePacked(pocEscrowAssetsArray[i].sellerName)) == keccak256(abi.encodePacked(_sellerName))) {
                escrowAssetArray[matchedCounttemp] = pocEscrowAssetsArray[i];
                matchedCounttemp += 1;
            }
        }
        return escrowAssetArray;
    }

    function checkValidAssetID(uint _assetID) public view returns(bool){
        bool isValid = false;
        if(_assetID < currentEscrowAssetCount){
            isValid = true;
        }
        return isValid;
    }
}

contract POCEscrow is Utilities, POCEscrowAsset {
    struct POCEscrowInfoStruct {
        uint escrowID;                          // Escrow ID (Auto-increased)
        
        string leadInvestorName;                // Lead Investor Name
        address leadInvestorAddress;            // Lead Investor Address
        uint leadInvestorAmount;                // Lead Investor Fund Amount
        uint leadInvestorPercentage;            // Lead Investor Fund Percentage
        bool leadInvestorFundStatus;            // Lead Investor Fund Status - True : Funded, False : Not Fund
        bool leadInvestorApproveStatus;         // Lead Investor Fund Approve Status - True : Approved, False : Not Approved

        uint countOfSubInvestors;               // Count of Sub Investors
        
        string[] subInvestorNameArray;          // Sub Investor's name address
        uint[] subInvestorPercentageArray;      // Sub Investor's fund percentage Array(divide equal for POC)
        uint[] subInvestorAmountArray;          // Sub Investor's Fund Amount Array    
        address[] subInvestorAddressArray;      // Sub Investor's Address Array
        bool[] subInvestorFundStatusArray;      // Sub Investor's Fund Status Arrray
        bool[] subInvestorApproveStatusArray;   // Sub Investor's Fund Approve Status Arrray

        uint fundedAmount;                      // Total Funded Amount in the escrwo
        uint assetID;                           // Escrow Asset ID
        uint createdDate;                       // Created Date as Unixtimestamp       
        bool isActive;                          // Active status
    }

    POCEscrowInfoStruct[] private pocEscrowInfoArray;
    uint internal currentEscrowCount;

    constructor(){
        currentEscrowCount = 0;
    }

    function getEscrowArray() public view returns(POCEscrowInfoStruct[] memory){
        return pocEscrowInfoArray;
    }
    function getEscrowByID(uint _escrowID) public view returns(POCEscrowInfoStruct memory){
        return pocEscrowInfoArray[_escrowID];
    }

    function createNewAsset(string memory _sellerName, uint _assetCost) public {
        POCEscrowAsset.addNewAsset(_sellerName, msg.sender, _assetCost);
    }
    function createNewEscrow(string memory _leadInvestorName, address _leadInvestorAddress, uint _leadInvestorPercentage, uint _countOfSubInvestors , uint _assetID) public {

        POCEscrowAssetStruct memory selectedAsset = getAssetByID(_assetID);

        require(_leadInvestorPercentage != 0, "Lead Investor's percentage can't be zero.");
        bytes memory tempEmptyStringTest = bytes(_leadInvestorName); // Uses memory
        require(tempEmptyStringTest.length != 0, "Lead Investor name can't be empty.");

        POCEscrowInfoStruct memory newEscrow;

        newEscrow.escrowID = currentEscrowCount;
        currentEscrowCount = currentEscrowCount + 1;

        newEscrow.leadInvestorName = _leadInvestorName;
        newEscrow.leadInvestorAddress = _leadInvestorAddress;
        
        newEscrow.leadInvestorAmount = SafeMath.mul(selectedAsset.assetCost, SafeMath.div(_leadInvestorPercentage,100));
        newEscrow.leadInvestorPercentage = _leadInvestorPercentage;
        newEscrow.leadInvestorFundStatus = false;
        newEscrow.leadInvestorApproveStatus = false;

        newEscrow.countOfSubInvestors = _countOfSubInvestors;

        // Need to add sub investors info
        string[] memory _subInvestorNameArray = new string[](_countOfSubInvestors);
        uint[] memory _subInvestorPercentageArray = new uint[](_countOfSubInvestors);
        uint[] memory _subInvestorAmountArray = new uint[](_countOfSubInvestors);
        address[] memory _subInvestorAddressArray = new address[](_countOfSubInvestors);
        bool[] memory _subInvestorFundStatusArray = new bool[](_countOfSubInvestors);
        bool[] memory _subInvestorApproveStatusArray = new bool[](_countOfSubInvestors);

        newEscrow.subInvestorNameArray = _subInvestorNameArray;
        newEscrow.subInvestorPercentageArray = _subInvestorPercentageArray;
        newEscrow.subInvestorAmountArray = _subInvestorAmountArray;
        newEscrow.subInvestorAddressArray = _subInvestorAddressArray;
        newEscrow.subInvestorFundStatusArray = _subInvestorFundStatusArray;
        newEscrow.subInvestorApproveStatusArray = _subInvestorApproveStatusArray;


        newEscrow.assetID = _assetID;
        newEscrow.createdDate = Utilities.getCurrentTimeStamp();
        newEscrow.isActive = true;

        pocEscrowInfoArray.push(newEscrow);
    }

    // function addSubInvestorsByEscrowID(uint _escrowID, string[] memory _subInvestorNames, address[] memory _subInvestorAddresses, uint[] memory _subInvestorAmounts,uint[] memory _subInvestorPercentages) public {
        
    //     POCEscrowInfoStruct memory selectedEscrowInfo = pocEscrowInfoArray[_escrowID];

    //     selectedEscrowInfo.subInvestorNameArray = _subInvestorNames;


    //     selectedEscrowInfo.subInvestorAddressArray = _subInvestorAddresses;
    //     selectedEscrowInfo.subInvestorAmountArray = _subInvestorAmounts;
    //     selectedEscrowInfo.subInvestorPercentageArray = _subInvestorPercentages;

    //     for (uint i = 0; i < _subInvestorNames.length; i++)
    //     {
    //         selectedEscrowInfo.subInvestorFundStatusArray[i] = false;
    //     }
    //     pocEscrowInfoArray[_escrowID] = selectedEscrowInfo;
    // }
    function addSubInvestorsByEscrowAndSubInvestorID(uint _escrowID,uint _subInvestorID, string memory _subInvestorName, uint _subInvestorAmount,uint _subInvestorPercentage) public {
        
        POCEscrowInfoStruct memory selectedEscrowInfo = pocEscrowInfoArray[_escrowID];

        selectedEscrowInfo.subInvestorNameArray[_subInvestorID] = _subInvestorName;

        
        selectedEscrowInfo.subInvestorAddressArray[_subInvestorID] = msg.sender;
        selectedEscrowInfo.subInvestorAmountArray[_subInvestorID] = _subInvestorAmount;
        selectedEscrowInfo.subInvestorPercentageArray[_subInvestorID] = _subInvestorPercentage;

        selectedEscrowInfo.subInvestorFundStatusArray[_subInvestorID] = false;
        pocEscrowInfoArray[_escrowID] = selectedEscrowInfo;
    }

    function addFundFromLeadInvestorByEscrowID(uint _escrowID) public payable{

        // lead investor address checking
        require(msg.sender == pocEscrowInfoArray[_escrowID].leadInvestorAddress , "Lead Investor Address doesn't match.");  
        require(msg.value != 0, "Lead Investor should deposit fund");        
        POCEscrowInfoStruct memory selectedEscrowInfo = pocEscrowInfoArray[_escrowID];
        require(msg.value >= selectedEscrowInfo.leadInvestorAmount, "Insufficient fund");
        selectedEscrowInfo.leadInvestorFundStatus = true;
        selectedEscrowInfo.leadInvestorAmount = msg.value;

        selectedEscrowInfo.fundedAmount = selectedEscrowInfo.fundedAmount + msg.value;

        
        pocEscrowInfoArray[_escrowID] = selectedEscrowInfo;
    }

    function addFundFromSubInvestorByEscrowAndSubinvestorID(uint _escrowID, uint _subInvestorID) public payable{

        require(msg.sender == pocEscrowInfoArray[_escrowID].subInvestorAddressArray[_subInvestorID] , "Sub Investor Address doesn't match.");  

        require(msg.value != 0, "Sub Investor should deposit fund");        
        POCEscrowInfoStruct memory selectedEscrowInfo = pocEscrowInfoArray[_escrowID];
        require(msg.value >= selectedEscrowInfo.subInvestorAmountArray[_subInvestorID], "Insufficient fund");
        selectedEscrowInfo.subInvestorFundStatusArray[_subInvestorID] = true;
        selectedEscrowInfo.subInvestorAmountArray[_subInvestorID] = msg.value;

        selectedEscrowInfo.fundedAmount = selectedEscrowInfo.fundedAmount + msg.value;

        pocEscrowInfoArray[_escrowID] = selectedEscrowInfo;
    }

    function approveFromSellerByEscrowID(uint _escrowID) public {
        POCEscrowAssetStruct memory selectedAsset = getAssetByID(pocEscrowInfoArray[_escrowID].assetID);

        require(msg.sender == selectedAsset.sellerAddress, "Seller address doesn't match");
        // asset status code - 0 : created, 1 : approved by seller, 2 : released, 3 : cancelled 
        POCEscrowAsset.setAssetStatusCode(pocEscrowInfoArray[_escrowID].assetID,1);
        releaseFundToSeller(_escrowID);
    }

    function approveFromLeadInvestorByEscrowID(uint _escrowID) public {
        require(msg.sender == pocEscrowInfoArray[_escrowID].leadInvestorAddress, "Lead Investor address doesn't match");
        // asset status code - 0 : created, 1 : approved by seller, 2 : released, 3 : cancelled 
        pocEscrowInfoArray[_escrowID].leadInvestorApproveStatus = true;
        releaseFundToSeller(_escrowID);
    }

    function approveFromSubInvestorByEscrowAndSubinvestorID(uint _escrowID, uint _subinvestorID) public {
        require(msg.sender == pocEscrowInfoArray[_escrowID].subInvestorAddressArray[_subinvestorID], "Sub Investor address doesn't match");
        // asset status code - 0 : created, 1 : approved by seller, 2 : released, 3 : cancelled 
        pocEscrowInfoArray[_escrowID].subInvestorApproveStatusArray[_subinvestorID] = true;
        releaseFundToSeller(_escrowID);
    }

    function releaseFundToSeller(uint _escrowID) public {
        if (isReadyToReleaseByID(_escrowID)){
            POCEscrowAssetStruct memory selectedAsset = getAssetByID(pocEscrowInfoArray[_escrowID].assetID);
            // asset status code - 0 : created, 1 : approved by seller, 2 : released, 3 : cancelled 
            POCEscrowAsset.setAssetStatusCode(pocEscrowInfoArray[_escrowID].assetID,2);
            payable(selectedAsset.sellerAddress).transfer(selectedAsset.assetCost);
        }
    }

    function isReadyToReleaseByID(uint _escrowID) public view returns(bool){
        bool isReadyToRelease = false;

        if(pocEscrowInfoArray[_escrowID].leadInvestorApproveStatus){
            for (uint i = 0; i < pocEscrowInfoArray[_escrowID].subInvestorApproveStatusArray.length; i++)
            {
                if(pocEscrowInfoArray[_escrowID].subInvestorApproveStatusArray[i]){
                    isReadyToRelease = true;
                }else{
                    isReadyToRelease = false;
                }
            }

            if (pocEscrowInfoArray[_escrowID].subInvestorApproveStatusArray.length == 0){
                isReadyToRelease = true;
            }

        }else{
            isReadyToRelease = false;
        }


        POCEscrowAssetStruct memory selectedAsset = getAssetByID(pocEscrowInfoArray[_escrowID].assetID);

        // asset status code - 0 : created, 1 : approved by seller, 2 : released, 3 : cancelled 
        if(selectedAsset.assetStatusCode == 1){

        }else{
            isReadyToRelease = false;
        }

        return isReadyToRelease;
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }


}