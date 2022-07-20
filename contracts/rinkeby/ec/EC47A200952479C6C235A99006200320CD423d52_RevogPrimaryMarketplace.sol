// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ERC721{
    function batchMint(address to, uint256 numberOfNFTs) external;
}

interface ERC20{
    function decimals() external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
}

contract RevogPrimaryMarketplace is Ownable, ReentrancyGuard{

//VARIABLES

    uint256 private constant ONEDAY = 1 days;
    uint256 private constant SEVENDAY = 7 days;
    uint256 private constant THIRTYDAY = 30 days;
    uint256 private constant RANGE = 10;
    uint256 private constant BASE_DECIMAL = 18;
    uint256 private constant DENOMINATOR = 100000;
    
    uint256 public maxBuyAllowed;
     
    struct PriceToken {
        address priceTokenAddress;
        bool enabled;
    }
    uint256 public totalSupportedPriceTokens;
    mapping(uint256 => PriceToken) public supportedPriceTokens;
  
    struct Sale {
        address buyer;
        uint256 boughtAt;
        uint256 price;
        uint256 totalUnits;
        uint256 priceTokenId;
    }
    mapping(address => mapping(uint256 => Sale)) public sales;
    
    struct FeesDetail {
        uint256 collected;
        uint256 withdrawal;
        mapping(address => uint256) authorFees;
        mapping(uint256 => uint256) collectedPerToken;
        mapping(uint256 => uint256) withdrawalPerToken;
    }
    FeesDetail public feesDetail;
    uint256 public fees;
    
    struct ContractDetails {
        bool isWhitelisted;
        uint256 price;
        uint256 totalVolume;
        uint256 totalUnitsSold;
        uint256 totalSale;
        uint256 statusUpdatedAt;
        uint256 priceTokenId;
        address author;
    }
    mapping(address => ContractDetails) public whitelistedContracts;
   
//EVENTS
    event PriceDetailsChanged(address nftContract, address changedBy, uint256 changedAt, uint256 newPrice, uint256 priceTokendId);
    event AuthorChanged(address newAuthor, address nftContract, address changedBy, uint256 changedAt);
    event Buy(address contractAddress, address buyer, uint256 boughtAt, uint256 price, uint256 totalUnits);
    event maxBuyAllowedChaned(uint256 newMaxBuyAllowed, address changedBy, uint256 changedAt);
    event WhitelistedContract(address contractAddress, address author, uint256 price, uint256 priceTokendId, address whitestedBy, uint256 whitelistedAt);
    event BlacklistedContract(address contractAddress, address whitestedBy, uint256 blacklistedAt);
    event PriceTokenAdded(address tokenAddress, address addedBy, uint256 addedAt);
    event PriceTokenDisabled(uint256 priceTokenId, address disabledBy, uint256 disabledAt);
    event FeesChanged(uint256 newFees, address changedBy, uint256 changedAt);
    event FeesWithdrawal(uint256 priceTokenId, uint256 amount, address withdrawalBy, uint256 withdrawalAt);
    
    constructor(uint256 _maxBuyAllowed, uint256 _fees){
        maxBuyAllowed = _maxBuyAllowed;
        supportedPriceTokens[totalSupportedPriceTokens].priceTokenAddress = address(0);
        supportedPriceTokens[totalSupportedPriceTokens].enabled = true;
        totalSupportedPriceTokens = totalSupportedPriceTokens + 1;
        fees = _fees;
        emit FeesChanged(_fees, msg.sender, block.timestamp);
        emit maxBuyAllowedChaned(_maxBuyAllowed, msg.sender, block.timestamp);
    }

//USER FUNCTIONS
    function buy(address _contract, uint256 _totalUnits) external nonReentrant() payable returns(bool){
        require(_totalUnits <= maxBuyAllowed, 'Invalid number of units' );
        ContractDetails storage contractDetails = whitelistedContracts[_contract];
        require(contractDetails.isWhitelisted, 'NFT contract is not whitelisted!!');
        uint256 priceTokenId = contractDetails.priceTokenId;
        uint256 totalPrice = _totalUnits * contractDetails.price;
        uint256 feeAmount = totalPrice * fees / DENOMINATOR;
     
        contractDetails.totalVolume = contractDetails.totalVolume + totalPrice;
        contractDetails.totalUnitsSold = contractDetails.totalUnitsSold + _totalUnits;
        contractDetails.totalSale = contractDetails.totalSale + 1;
        
        Sale storage sale = sales[_contract][ contractDetails.totalSale];
        sale.price = contractDetails.price;
        sale.priceTokenId = priceTokenId;
        sale.boughtAt = block.timestamp;
        sale.buyer = msg.sender;
        sale.totalUnits = _totalUnits;
        
        feesDetail.collected = feesDetail.collected + feeAmount;
        feesDetail.collectedPerToken[priceTokenId] = feesDetail.collectedPerToken[priceTokenId] + feeAmount;
        feesDetail.authorFees[_contract] =  feesDetail.authorFees[_contract] + totalPrice - feeAmount;
        if(priceTokenId == 0){
            require(msg.value >= totalPrice, 'amount paid is less than the total price of NFTs');
            uint256 extraAmountPaid = msg.value - totalPrice;
            payable(whitelistedContracts[_contract].author).transfer(totalPrice - feeAmount);
            if(extraAmountPaid > 0){
                payable(msg.sender).transfer(extraAmountPaid);
            }
        }else {
            ERC20(supportedPriceTokens[priceTokenId].priceTokenAddress).transferFrom(msg.sender, whitelistedContracts[_contract].author, convertValue(totalPrice - feeAmount, priceTokenId, false));
        }
     
        ERC721(_contract).batchMint(msg.sender, _totalUnits);
        emit Buy(_contract, msg.sender, block.timestamp, totalPrice, _totalUnits);
        return true;
    }
  
//OWNER FUNCTIONS

    function whitelistContract(address _contract, address _author, uint256 _price, uint256 _priceTokenId) external onlyOwner() returns(bool){
        require(_contract != address(0), 'Invalid contract address');
        require(_author != address(0), 'Invalid author');
        require(supportedPriceTokens[_priceTokenId].enabled, 'Invalid price token');
        require(!whitelistedContracts[_contract].isWhitelisted, 'Already whitelisred');
        whitelistedContracts[_contract].price = convertValue(_price, _priceTokenId, true);
        whitelistedContracts[_contract].priceTokenId = _priceTokenId;
        whitelistedContracts[_contract].isWhitelisted = true;
        whitelistedContracts[_contract].author = _author;
        whitelistedContracts[_contract].statusUpdatedAt = block.timestamp;
        emit WhitelistedContract(_contract, _author, whitelistedContracts[_contract].price, _priceTokenId, msg.sender, block.timestamp);
        return true;
    }
    
    function updatePriceDetails(address _contract, uint256 _newPrice, uint256 _newPriceTokenId) external onlyOwner() returns(bool){
        ContractDetails storage contractDetails = whitelistedContracts[_contract];
        require(contractDetails.isWhitelisted, 'NFT contract is not whitelisted!!');
        require(supportedPriceTokens[_newPriceTokenId].enabled, 'Invalid price token');
        contractDetails.price = convertValue(_newPrice, _newPriceTokenId, true) ;
        contractDetails.priceTokenId = _newPriceTokenId;
        emit PriceDetailsChanged(_contract, msg.sender, block.timestamp, _newPrice, _newPriceTokenId);
        return true;
    }
    
    function updateAuthor(address _contract, address _newAuthor) external onlyOwner() returns(bool){
        ContractDetails storage contractDetails = whitelistedContracts[_contract];
        require(contractDetails.isWhitelisted, 'NFT contract not whitelisted!!');
        require(_newAuthor != address(0), 'Invalid author');
        contractDetails.author = _newAuthor;
        emit AuthorChanged( _newAuthor, _contract, msg.sender, block.timestamp);
        return true;
    }
 
    function blacklistContract(address _contract) external onlyOwner() returns(bool){
        require(whitelistedContracts[_contract].isWhitelisted, 'Invalid contract');
        whitelistedContracts[_contract].isWhitelisted = false;
        whitelistedContracts[_contract].statusUpdatedAt = block.timestamp;
        emit BlacklistedContract(_contract, msg.sender, block.timestamp);
        return true;
    }
    
    function updateMaxBuyAllowed(uint256 _maxBuyAllowed) external onlyOwner() returns(bool){
        require(_maxBuyAllowed > 0, 'Max buy Allowed can not be zero');
        maxBuyAllowed = _maxBuyAllowed;
        emit maxBuyAllowedChaned(maxBuyAllowed, msg.sender, block.timestamp);
        return true;
    }
    
    function addPriceToken(address _newPriceToken) external onlyOwner() returns(bool){
        require(_newPriceToken != address(0), 'Invalid address');
        (bool isPriceTokenExist, uint256 priceTokenId) = priceTokenExist(_newPriceToken);
        if(isPriceTokenExist){
            supportedPriceTokens[priceTokenId].enabled = true;
            return true;
        }
        supportedPriceTokens[totalSupportedPriceTokens].priceTokenAddress = _newPriceToken;
        supportedPriceTokens[totalSupportedPriceTokens].enabled = true;
        totalSupportedPriceTokens = totalSupportedPriceTokens + 1;
        emit PriceTokenAdded(_newPriceToken, msg.sender, block.timestamp);
        return true;
    }
    
    function disablePriceToken(uint256 _priceTokenId) external onlyOwner() returns(bool){
        require(supportedPriceTokens[_priceTokenId].enabled, 'Invalid price token');
        supportedPriceTokens[_priceTokenId].enabled = false;
        totalSupportedPriceTokens = totalSupportedPriceTokens - 1;
        emit PriceTokenDisabled(_priceTokenId, msg.sender, block.timestamp);
        return true;
    }
    
    function withdrawFees(uint256 _priceTokenId) external onlyOwner() nonReentrant() returns(bool){
        uint256 availableFees = feesDetail.collectedPerToken[_priceTokenId] - feesDetail.withdrawalPerToken[_priceTokenId];
        require(availableFees > 0, 'Nothing to withdraw for this token');
        feesDetail.withdrawal = feesDetail.withdrawal + availableFees;
        feesDetail.withdrawalPerToken[_priceTokenId] = feesDetail.withdrawalPerToken[_priceTokenId] + availableFees;
        if(_priceTokenId == 0){
            payable(msg.sender).transfer(availableFees);
        } else {
            ERC20(supportedPriceTokens[_priceTokenId].priceTokenAddress).transfer(msg.sender, convertValue(availableFees, _priceTokenId, false));
        }
        emit FeesWithdrawal(_priceTokenId, availableFees, msg.sender, block.timestamp);
        return true;
    }
    
 
//VIEW FUNCTIONS
    function getSaleList(address _contract, uint256 _fromSaleId) external view returns(uint256, Sale[10] memory){
        uint256 toSaleId = whitelistedContracts[_contract].totalSale;
        if(toSaleId > _fromSaleId + RANGE){
            toSaleId = _fromSaleId + RANGE;
        }
        Sale[RANGE] memory saleList;
        uint8 totalSaleAdded = 0;
        for (uint256 i = _fromSaleId; i <= toSaleId; i++ ){
            Sale memory sale = sales[_contract][_fromSaleId];
            saleList[totalSaleAdded] = sale;
            totalSaleAdded++;
        }
        return (toSaleId, saleList);
    }
    
    function totalNFTSold(address _contract) external view returns(uint256, uint256, uint256){
        uint256 totalSoldLast24Hours = 0;
        uint256 totalSoldLast7Days = 0;
        uint256 totalSoldLast30Days = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = whitelistedContracts[_contract].totalSale; i >= 1; i--){
            Sale memory sale = sales[_contract][i];
            if(sale.boughtAt < currentTime - THIRTYDAY ){
                break;
            }
            if(sale.boughtAt >= currentTime - ONEDAY){
                totalSoldLast24Hours = totalSoldLast24Hours + 1;
            } 
            if(sale.boughtAt >= currentTime - SEVENDAY){
                totalSoldLast7Days = totalSoldLast7Days + 1;
            } 
            if(sale.boughtAt >= currentTime - THIRTYDAY){
                totalSoldLast30Days = totalSoldLast30Days + 1;
            }
        }
        return (totalSoldLast24Hours, totalSoldLast7Days, totalSoldLast30Days);
    }
    
    function totalVolume(address _contract) external view returns(uint256, uint256, uint256){
        uint256 totalVolumeLast24Hours = 0;
        uint256 totalVolumeLast7Days = 0;
        uint256 totalVolumeLast30Days = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = whitelistedContracts[_contract].totalSale; i >= 1; i--){
            Sale memory sale = sales[_contract][i];
            if(sale.boughtAt < currentTime - THIRTYDAY ){
                break;
            }
            if(sale.boughtAt >= currentTime - ONEDAY){
                totalVolumeLast24Hours = totalVolumeLast24Hours + (sale.price * sale.totalUnits);
            } 
            if(sale.boughtAt >= currentTime - SEVENDAY){
                totalVolumeLast7Days = totalVolumeLast7Days +  (sale.price * sale.totalUnits);
            } 
            if(sale.boughtAt >= currentTime - THIRTYDAY){
                totalVolumeLast30Days = totalVolumeLast30Days +  (sale.price * sale.totalUnits);
            }
        }
        return (totalVolumeLast24Hours, totalVolumeLast7Days, totalVolumeLast30Days);
    }
    
    
//INTERNAL FUNCTIONS
    receive() payable external{
        
    }
    
    function convertValue(uint256 _value, uint256 _priceTokenId, bool _toBase) internal view returns(uint256){
        if(_priceTokenId == 0 || ERC20(supportedPriceTokens[_priceTokenId].priceTokenAddress).decimals() == BASE_DECIMAL){
            return _value;
        }
        uint256 decimals = ERC20(supportedPriceTokens[_priceTokenId].priceTokenAddress).decimals();
        if(_toBase){
            return _value * 10**(BASE_DECIMAL - decimals);
        } else {
            return _value / 10**(BASE_DECIMAL - decimals);
        }
    }
        
    function priceTokenExist(address _newPriceToken) public view returns(bool, uint256){
        for(uint8 i = 1; i < totalSupportedPriceTokens; i++ ){
            if(supportedPriceTokens[i].priceTokenAddress == _newPriceToken){
                return (true, i);
            }
        }
        return (false, 0);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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