// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../openzeppelin/contracts/access/AccessControl.sol";
import "../openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@quant-finance/solidity-datetime/contracts/DateTime.sol";
import "./interface/IBWGToken.sol";
import "./interface/ITokenTransferOperator.sol";

/**
 * @title The StorageOperator Contract is an administrative contract responsible for deduction of token storage cost.
 * @author Md Faysal 
 * @notice The contract allows the deduction of storage fees for the different time interval.
 * @dev The Storage operator contract is an administrative contract responsible for deduction of token storage cost basis of monthly / quarterly / half yearly / yearly
 * Contract initiates batchProcess on a specific date of the month with specific month interval.
 * and the batchSend method transfers a token as a storage cost by using operatorSend of TokenTransferOperator
 * This contract can be re-deployable incase of failure or adjustment business need.
 * Grand admin user to DEFAULT_ADMIN_ROLE and deployer to MAINTAINER_ROLE and BATCH_EXECUTOR_ROLE role.
 */
contract StorageOperator is AccessControl {  

    event BatchProcess(bool isProcessRunning);    
    event LastPerformTimestamp(uint256 timestamp);
    event PerformTimeDuration(uint256 duration);
    event PerformDay(uint256 day); 
    event StorageCostRate(uint256 storageCostRate);
    event FundAddress(address fundAddress);    
    event BatchSize(uint256 batchSize);
    event TransactionFee(uint256 fee);
    event MinTokenBalance(uint256 minBalance);
    event StorageCostSummary(
        address fundAddress,
        uint256 storageCostRate,        
        uint256 totalFee
    );

    bytes32 public constant BATCH_EXECUTOR_ROLE = keccak256("BATCH_EXECUTOR_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    
    uint256 private constant _RATE_PRECISION = 10000;
    uint256 private _storageCostRate;
    uint256 private _performDay;
    uint256 private _lastPerformTimestamp;    
    uint256 private _minTokenBalance;

    uint256 private _batchSize = 1000;
    uint256 private _batchCursor;
    uint256 private _transactionFee;
    uint256 private _timeDuration = 3; // 1 for monthly 3 for quarterly, 6 for half yearly, 12 yearly
    bool private _isProcessRunning = false; 
    
    address private _fundAddress;    
    address private immutable _baseContract;
        
    constructor(address baseContract_, address fundAddress_, uint256 storageCostRate_, uint256 transactionFee_, uint256 minTokenBalance_, address adminUser ) {     
        _baseContract = baseContract_;
        _fundAddress = fundAddress_;
        _storageCostRate = storageCostRate_;
        _lastPerformTimestamp = block.timestamp;
        _performDay = 1;
        _transactionFee = transactionFee_; 
        _minTokenBalance = minTokenBalance_; 
        _grantRole(DEFAULT_ADMIN_ROLE, adminUser);
        _grantRole(BATCH_EXECUTOR_ROLE, msg.sender);         
        _grantRole(MAINTAINER_ROLE, msg.sender);
              
    } 

    /**     
     * @dev Modifier that checks that the batch process is running or not . Reverts
     * with a standardized message including the required role.
     */
    modifier _notProcessingDeductions() {
         require(!_isProcessRunning, "Processing deductions");
        _;
    }

    /**
     * @notice Override Access control revokeRole method for admin role.
     * @dev Override Access control revokeRole is allows them to revoke all role except the admin.
     * Admin can't revoke himself from DEFAULT_ADMIN_ROLE, can only revoke roles for others.
     * If the calling account had been revoked `role`, emits a {RoleRevoked} event.
     * the caller must have admin role.
     * emit a {RoleRevoked} event
     */
    function revokeRole(bytes32 role, address account) public virtual override  onlyRole(getRoleAdmin(role)){
        require(account != msg.sender && role != DEFAULT_ADMIN_ROLE, "AccessControl: can only revoke roles for others");
        _revokeRole(role, account);
    }

    /**
     * @notice Override Access control renounceRole method for admin role.
     * @dev Override Access control renounceRole is allows them to renounce all role except the admin.
     * Admin can't renounce himself from DEFAULT_ADMIN_ROLE.    
     * the caller must be `account`.
     * emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");
        require(role != DEFAULT_ADMIN_ROLE, "AccessControl: admin can't renounce for self");
        _revokeRole(role, account);
    }
    
    /**
     * @notice Used to know that the month is valid for batch process.
     * @dev The internal method is used to know the month is valid for batch process.
     * if month = 1, It is valid for all timeDuration.
     * if month = 3, It is valid for only timeDuration(1 or 3)          
     * @param month, The numeric value of month.
     * @return  bool(true/false)
     */
    function _isValidMonth(uint256 month)internal view returns(bool){
        return  _timeDuration == 1 || month % _timeDuration == 1 ;
    }
 
    /**
     * @notice Used to know that the batch process request is valid or not.
     * @dev The internal method is used to know the batch process request is valid for current month
     * if timeDuration = 1, It is valid for all month.
     * if timeDuration = 3, It is valid for only January, April, July and October.
     * if timeDuration = 6, It is valid for only January and July
     * if timeDuration = 12, It is valid for only January    
     * @return  bool(true/false)
     */
    function _isValidBatchRequest() internal view returns (bool) {
        uint256 timestamp = block.timestamp;
        uint256 day = DateTime.getDay(timestamp);
        uint256 month = DateTime.getMonth(timestamp);
        uint256 monthDifference = DateTime.diffMonths(
            _lastPerformTimestamp,
            timestamp
        ); 
        return ( day >= _performDay && monthDifference >= 1 && _isValidMonth(month) );
    }
  
    /**
     * @notice The external method is used to update batch-size of batch process. 
     * @dev The external method is used to update batch-size of batch process. 
     * Maintainer permission required to change batch size.
     * newBatchSize should be greater than 0 and less than or equal to 2000
     * Emits a {BatchSize} event.
     * Not allowed to perform during batch process.
     * @param newBatchSize, The requested batchSize to set
     */
    function setBatchSize(uint256 newBatchSize) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        require(newBatchSize > 0 && newBatchSize <= 2000, "Invalid batch size");
        _batchSize = newBatchSize;
        emit BatchSize(newBatchSize);
    }

    /**
     * @notice The external method is used to know current batch-size of batch process. 
     * @return batchSize, The current batch-size of batch process. 
     */
    function getBatchSize() external view returns (uint256) {
        return _batchSize;
    }

    /**
     * @notice The external method is used to update performDay (day of month). 
     * @dev The external method is used to update performDay (day of month). 
     * Maintainer permission required to change perform day.
     * The dayOfMonth should be greater than 0 and less than or equal to 28.
     * Not allowed to perform during batch process.
     * Emits a {PerformDay} event.
     * @param dayOfMonth, The requested day of month to set.
     */
    function setPerformDay(uint256 dayOfMonth) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        require(dayOfMonth > 0 && dayOfMonth <= 28 , "Invalid day of month");
        _performDay = dayOfMonth;
        emit PerformDay(dayOfMonth);
    }

    /**
     * @notice The external method is used to get updated performDay (day of month).
     * @return performDay, The monthly storage cost deduction day.
     */
    function getPerformDay() external view returns (uint256) {
        return _performDay;
    }
  
    /**
     * @notice The external method is used to update time-duration.
     * @dev The external method is used to update time-duration. (1 for monthly, 3 for quarterly, 6 for half yearly and 12 for yearly). 
     * Maintainer permission required to change time duration.
     * The duration should be 1 or 3 or 6 or 12.
     * Not allowed to perform during batch process.
     * Emits a {PerformTimeDuration} event.
     * @param duration,  uint256 time-duration to be updated.
     */
    function setPerformTimeDuration(uint256 duration) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        require(duration == 1 || duration == 3 || duration == 6 || duration == 12 , 'Invalid interval');        
        _timeDuration = duration;
        emit PerformTimeDuration(duration);        
    }

    /**
     * @notice The external method is used to get updated PerformTimeDuration (1 for monthly, 3 for quarterly, 6 for half yearly and 12 for yearly).
     * @return timeDuration
     */
    function getPerformTimeDuration() external view returns (uint256) {
        return _timeDuration;
    }

    /**
     * @notice The external method is used to update lastPerformTimestamp.
     * @dev The external method is used to update lastPerformTimestamp.
     * Maintainer permission required to change lastPerformTimestamp.
     * The newTimestamp should not greater than block timestamp.
     * Not allowed to perform during batch process.
     * Emits a {LastPerformTimestamp} event.
     * @param newTimestamp, uint256 timestamp to be updated  
     */   
    function setLastPerformTimestamp(uint256 newTimestamp) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        require(newTimestamp <= block.timestamp, "Invalid timestamp");
        _setLastPerformTimestamp(newTimestamp);
    }
   
    /**
     * @notice The internal method is used to update lastPerformTimestamp.
     * @dev The internal method is used to update lastPerformTimestamp.   
     * Emits a {LastPerformTimestamp} event.
     * @param newTimestamp, uint256 timestamp to be updated  
     */
    function _setLastPerformTimestamp(uint256 newTimestamp) internal  {
        _lastPerformTimestamp = newTimestamp;
        emit LastPerformTimestamp(newTimestamp);
    }

    /**
     * @notice The external method is used to get updated lastPerformTimestamp 
     * @return lastPerformTimestamp
     */
    function getLastPerformTimestamp() external view returns (uint256) {
        return _lastPerformTimestamp;
    }

    /**
     * @notice The external method is used to update fund-address, where the storage cost will be transferred.
     * @dev The external method is used to update fund addresses, where the storage cost will be transferred.
     * Maintainer permission required to change fund-address.
     * The newFundAddress should not be zero address.
     * Not allowed to perform during batch process.
     * Emits a {FundAddress} event.
     * @param newFundAddress, uint256 fund-address to be updated  
     */
    function setFundAddress(address newFundAddress) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        require(newFundAddress != address(0), "Invalid or zero address");
        _fundAddress = newFundAddress;
        emit FundAddress(newFundAddress);
    }

    /**
     * @notice The external method is used to get an updated fund address.
     * @return fundAddress
     */
    function getFundAddress() external view returns (address) {
        return _fundAddress;
    }

    /**
     * @notice The external method is used to update minTokenBalance.
     * @dev The external method is used to update minTokenBalance
     * Maintainer permission required to change minTokenBalance.
     * Not allowed to perform during batch process.
     * Emits {MinTokenBalance} event.
     * @param newMinTokenBalance,uint256 minTokenBalance to be updated       
     */
    function setMinTokenBalance(uint256 newMinTokenBalance) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {        
        _minTokenBalance = newMinTokenBalance;
        emit MinTokenBalance(newMinTokenBalance);
    }

    /**
     * @notice The external method is used to get an updated minTokenBalance.
     * @return _minTokenBalance
     */
    function getMinTokenBalance() external view returns (uint256) {
        return _minTokenBalance;
    }

       /**
     * @notice The external method is used to update transaction-fee.
     * @dev The external method is used to update transaction-fee.
     * Maintainer permission required to change transaction-fee.
     * Not allowed to perform during batch process.
     * Emits {TransactionFee} event.
     * @param newTransactionFee,uint256 transaction-fee to be updated       
     */
    function setTransactionFee(uint256 newTransactionFee) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {        
        _transactionFee = newTransactionFee;
        emit TransactionFee(newTransactionFee);
    }

    /**
     * @notice The external method is used to get an updated transaction fee .
     * @return transactionFee
     */
    function getTransactionFee() external view returns (uint256) {
        return _transactionFee;
    }

    /**
     * @notice The addCostFreeWallet method is used to add a costfree wallet to the list.
     * @dev The addCostFreeWallet method is used to add a costfree wallet to the list.
     * Maintainer permission required to change storage-cost-rate.
     * Not allowed to perform during batch process.
     * @param wallet, The wallet is to add a costable list.   
     */
    function addCostFreeWallet(address wallet) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        IBWGToken(_baseContract).addCostFreeWallet(wallet);       
    }

    /**
     * @notice The removeCostFreeWallet method is used to remove a wallet from the costable wallet list.
     * @dev The removeCostFreeWallet method is used to remove a wallet from the costable wallet list.
     * Maintainer permission required to change storage-cost-rate.
     * Not allowed to perform during batch process.
     * @param wallet, The wallet will be removed from the costable list.   
     */
    function removeCostFreeWallet(address wallet) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        IBWGToken(_baseContract).removeCostFreeWallet(wallet);       
    }

    /**
    * @notice The external method is used to update storage-cost-rate 
    * @dev The external method is used to update storage-cost-rate, the requested rate percentage should be multiply by ratePrecision.    
    * Maintainer permission required to change storage-cost-rate.
    * Not allowed to perform during batch process.
    * Emits {StorageCostRate} event.
    * @param newStorageCostRate, uint256 storage-cost-rate to be updated   
    */
    function setStorageCostRate(uint256 newStorageCostRate) external _notProcessingDeductions onlyRole(MAINTAINER_ROLE) {
        require(newStorageCostRate > 0 && newStorageCostRate < _RATE_PRECISION, "Invalid storage cost rate");
        _storageCostRate = newStorageCostRate;
        emit StorageCostRate(newStorageCostRate);
    }

    /**
    * @notice The external method is used to know updated storage-cost-rate,
    * @return storageCostRate
    */
    function getStorageCostRate() external view returns (uint256) {
        return _storageCostRate;
    }

    /**
    * @notice The private method is used to increment value by 1 
    */
    function _increment(uint256 x) private pure returns (uint256) {
        unchecked { return ++x; }
    }    
 
    /**
    * @notice The external method used to get total storage wallets 
    * @return totalStoredWallet  
    */
    function storageWalletCount() external view returns (uint256 ) {                
        return IBWGToken(_baseContract).storageWallets().length;
    }
   
    /**
    * @notice The external method used to get total costfree wallets count
    * @return costFreeWallet count
    */
    function costFreeWalletCount() external view returns ( uint256 ) {                
        return IBWGToken(_baseContract).costFreeWallets().length;   
    }

    /**
    * @notice The external method used to get list of costfree wallets
    * @return costFreeWallet list
    */
    function costFreeWallets() external  view returns ( address[] memory  ){            
       return IBWGToken(_baseContract).costFreeWallets();  
    }
   
    /**
    * @notice The external method used to get lastIndex of current batch process execution
    * @return batchCursor, the last index of costable wallet executed
    */
    function getBatchCursor() external view returns ( uint256 ) {         
        return _batchCursor;   
    }
  
    /**
    * @notice The external method used to get overview of next batch process
    * @dev The external method used to get overview of next batch process 
    * @return totalStorageCost  
    * @return totalWallet  
    * @return totalWalletUnderThreshold  
    * @return totalCostUnderThreshold  
    * @return day  
    * @return duration  
    * @return lastPerformTime  
    * @return costRate  
    */
    function getStorageOverview() external view 
        returns ( 
            uint256 totalStorageCost, 
            uint256 totalWallet, 
            uint256 totalWalletUnderThreshold,
            uint256 totalCostUnderThreshold,
            uint256 day,
            uint256 duration,
            uint256 lastPerformTime,
            uint256 costRate
        ){                   
        IERC777 token = IERC777(_baseContract);
        IBWGToken bwgToken = IBWGToken(_baseContract);             
        address[] memory wallets = bwgToken.storageWallets();                 
        
        for (uint256 index = 0; index < wallets.length; index = _increment(index)) {
            address balanceWallet = wallets[index];
            uint256 balance = token.balanceOf(balanceWallet);
            if (balance > 0 && !bwgToken.isCostFreeWallet(balanceWallet)){
                uint256 cost = ((balance * _storageCostRate)/_RATE_PRECISION) + _transactionFee;

                // calculate total storage cost and number of wallet under threshold 
                if (balance <  (cost + _minTokenBalance)){
                    cost = balance;
                    totalCostUnderThreshold += balance;
                    totalWalletUnderThreshold++; 
                }
                // calculate total storage cost and wallet count
                totalStorageCost += cost;
                totalWallet++;  
            }          
        }
        day = _performDay;
        duration = _timeDuration;
        lastPerformTime = _lastPerformTimestamp;
        costRate = _storageCostRate;
    }

    /**
     * @notice The pause method is used to stop token transfers 
     * @dev The BWGtoken contract can be paused by openzeppelin p​​​​​​​​​​ausable contract and the method is implemented from the IBWGToken interface. 
     * Maintainer permission required to pause token transfer
     * Emits a {Paused} event.
     */
    function pause() external  onlyRole(MAINTAINER_ROLE){        
        IBWGToken(_baseContract).pause();
    }

    /**
     * @notice The unpause method is used to unpause token transfers. 
     * @dev The BWGtoken contract can be unpaused by openzeppelin p​​​​​​​​​​ausable contract and the method is implemented from the IBWGToken interface. 
     * Maintainer permission required to unpause token transfer
     * Emits an {Unpaused} event.
     */
    function unpause() external onlyRole(MAINTAINER_ROLE) {            
        IBWGToken(_baseContract).unpause();
    }

    /**
     * @notice The external method used to get first available empty wallet array     
     * @return emptyWallets
     */
    function getEmptyWallets() external view returns( address[] memory ) {      
        return IBWGToken(_baseContract).getEmptyWallets();
    }

    /**
     * @notice The external method used to remove from storage wallet.
     * @dev The external method used to remove from storage wallet.
     * BatchExecutor permission required to execute bulkRemoveEmptyWallets.
     * Not allowed to perform during batch process.
     * @param wallets, the list of empty wallet to be removed from storage wallet list.
     */
    function bulkRemoveEmptyWallets(address[] calldata wallets) external _notProcessingDeductions onlyRole(BATCH_EXECUTOR_ROLE)  {      
        IBWGToken(_baseContract).bulkRemoveEmptyWallets(wallets);
    }
 
    /**
     * @notice The external method used to initiate batch process.  
     * @dev The external method used to initiate batch process.
     * BatchExecutor permission required to change initiate batch process.
     * Valid batch request required.
     * Token transfer will paused until finish batch process.
     * Emits {InitBatchProcess} event. 
     */
    function initBatchProcess() external onlyRole(BATCH_EXECUTOR_ROLE) {
        require(_isValidBatchRequest() && !_isProcessRunning , "Invalid batch-process initialization"); 
        
        IBWGToken bwgToken = IBWGToken(_baseContract); 
        bwgToken.pause();

        _isProcessRunning = true;
        emit BatchProcess(_isProcessRunning);        
    }

    /**
    * @notice The external method used to get all information of current batch.
    * @dev The external method used to get all information of current batch.  
    * Valid batch request required.
    * @return wallets
    * @return costs
    * @return totalCost
    * @return isCompleted 
    */
    function getCostableWalletBatch() external view 
        returns (
            address[] memory wallets, 
            uint256[] memory costs,            
            uint256 totalCost, 
            bool isCompleted
        ){
        isCompleted = true;
        if (_isValidBatchRequest() && _isProcessRunning){
            IERC777 token = IERC777(_baseContract);
            IBWGToken iBWGToken = IBWGToken(_baseContract);         
            address[] memory storageWallets = iBWGToken.storageWallets();                 
            wallets = new address[](_batchSize);
            costs = new uint256[](_batchSize);
                        
            if(storageWallets.length > _batchCursor) {
                isCompleted = false;
            }
            uint256 lastIndex = (_batchCursor + _batchSize) >=  storageWallets.length? storageWallets.length: (_batchCursor + _batchSize);
            uint256 count =0;
            for (uint256 index = _batchCursor; index < lastIndex; index = _increment(index)) {
                address balanceWallet = storageWallets[index];
                uint256 balance = token.balanceOf(balanceWallet);
                if (balance > 0 && !iBWGToken.isCostFreeWallet(balanceWallet)){ 
                    // calculate storage cost for wallet.
                    uint256 cost = ((balance * _storageCostRate)/_RATE_PRECISION) + _transactionFee;
                    // collect all tokens if the remaining balance after a deduction is less than the minimum threshold token balance.
                    if (balance <  (cost + _minTokenBalance)){
                        cost = balance;                      
                    }
                    wallets[count] = balanceWallet;
                    costs[count] = cost;
                    totalCost += cost; 
                }                
                count++;
            }
        }        
    }

    /**
    * @notice The external method used to perform batch process to collection storage fees
    * @dev The external method used to perform batch process to collection storage fees
    * BatchExecutor permission required to execute batchSend.   
    * Valid batch request required.  
    * Wallets and costs length should are match.
    * Wallets length and batch-size are match.
    * Emits {StorageCostSummary} event. 
    */
    function batchSend(address[] calldata wallets, uint256[] calldata costs, uint256 totalCost) external onlyRole(BATCH_EXECUTOR_ROLE)  {
        
        IERC777 token = IERC777(_baseContract);
        IBWGToken bwgToken = IBWGToken(_baseContract);        
        ITokenTransferOperator tokenTransferOperator = ITokenTransferOperator(token.defaultOperators()[0]); 
        
        require(_isValidBatchRequest() && _isProcessRunning, "Invalid batch-send request"); 
        require(wallets.length == costs.length , "Wallets and costs length are mismatch"); 
        require(wallets.length == _batchSize , "Wallets length and batch-size are mismatch");
                
        address fundAddress = _fundAddress;
        for (uint256 index = 0; index < _batchSize; index++) {
            if (wallets[index] != address(0)){
                tokenTransferOperator.operatorSend(
                    token,
                    wallets[index],
                    fundAddress,
                    costs[index]
                );      
            }
        }                     
           
        emit StorageCostSummary(
            fundAddress,
            _storageCostRate,            
            totalCost
        );
        
        uint256 maxLimit = bwgToken.storageWallets().length;
        _batchCursor = _batchCursor + _batchSize; 
        
        // reach the final index of storageWallet list if true
        if (maxLimit <= _batchCursor) {
            // update lastPerformTimestamp by block.timestamp
            _setLastPerformTimestamp(block.timestamp);            
            // unpause token transfer
            bwgToken.unpause();    

            delete _batchCursor; 
            delete _isProcessRunning;                  
            emit BatchProcess(_isProcessRunning);     
        }    
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`.
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`.
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../../openzeppelin/contracts/token/ERC777/IERC777.sol";
/**
 * @author Md Faysal 
 * @dev External interface of ITokenTransferOperator declared to access BWGToken operatorSend method.
 */
interface ITokenTransferOperator {
    /**
     * @notice The operatorSend used to transfer tokens on behalf of token holders.    
     * @param token, The BWGToken instance.
     * @param from, The token sender sends a token.
     * @param to, The token recipient receives a token.
     * @param amount, The amount of tokens to be transferred.
     */
    function operatorSend(
        IERC777 token,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @author Md Faysal 
 * @dev External interface of IBWGToken declared to access BWGToken from storage-operator contract.
 */
interface IBWGToken  {

    /**
     * @dev The storageWallets interface method is used to get a list of all stored token holder wallet addresses.
     * @return storageWallets,
     */
    
    function storageWallets() external view returns (address[] memory);

    /**
     * @dev The costFreeWallets interface method is used to get a list of all stored cost-free wallets.
     * @return costFreeWallets,
     */
    function costFreeWallets() external view returns (address[] memory);
    /**
     * @notice The getEmptyWallets interface method is used to return the first batch of an available wallet with an empty balance.
     * @return emptyWallets
     */
    function getEmptyWallets() external view returns (address[] memory);

    /**
     * @dev The bulkRemoveEmptyWallets interface method is used to remove a list of empty wallets from storageWalletList.        
     * @param wallets, 
     */  
    function bulkRemoveEmptyWallets(address[] memory wallets ) external ;

    /**
     * @dev The isCostFreeWallet interface method is used to check if the wallet is cost free or not.    
     * @param wallet, Check if the wallet is cost free or not.
     * @return bool(true/false)
     */
    function isCostFreeWallet(address wallet) external view returns (bool);
    
    /**
     * @notice The isCostableWallet interface method is used to check if the wallet is costable or not.
     * @param wallet, Check if the wallet is costable or not.
     * @return bool(true/false)
     */
    function isCostableWallet(address wallet) external view returns (bool);

     /**
     * @dev The pause interface method is used to pause token transfers.     
     * Emits an {Paused} event.
     */     
    function pause() external ;

    /**
     * @dev The unpause interface method is used to unpause token transfers. 
     * Emits an {Unpaused} event.
     */
    function unpause() external;

    /**
     * @dev The addCostFreeWallet interface method is used to add wallet to costfree list.    
     * @param wallet, the wallet will add to the costfree list.
     */
    function addCostFreeWallet(address wallet) external;
    
    /**
     * @dev The removeCostFreeWallet interface method is used to remove wallet from costfree list.    
     * @param wallet, the wallet will remove from the costfree list.
     */
    function removeCostFreeWallet(address wallet) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}