// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ERC721{
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC20{
    function decimals() external view returns(uint256);
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
}

contract RevogSecondaryMarketplace is Ownable, ReentrancyGuard{

//VARIABLES

    uint256 private constant DENOMINATOR = 10000;
    uint256 private constant ONEDAY = 1 days;
    uint256 private constant SEVENDAY = 7 days;
    uint256 private constant THIRTYDAY = 30 days;
    uint256 private constant RANGE = 10;
    uint256 private constant BASE_DECIMAL = 18;
    uint256 public fees;   
    
    enum Status{ Sold, UnSold, Removed } 
    struct Sale {
        address seller;
        address buyer;
        uint256 nftId;
        uint256 listedAt;
        uint256 price;
        uint256 fees;
        uint256 authorFees;
        uint256 priceTokenId;
        Status status;
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
    
    struct ContractDetails {
        bool isWhitelisted;
        address author;
        uint256 authorFees;
        uint256 totalVolume;
        uint256 totalFeesCollected;
        uint256 totalAuthorFeesCollected;
        uint256 totalSold;
        uint256 totalListed;
        uint256 totalRemoved;
    }
    mapping(address => ContractDetails) public whitelistedContracts;
    address[] private whitelistedContractsInternal;
    
    struct SaleIdDetail {
        uint256[] allSaleIds;
        uint256 currentSaleId;
    }
    mapping(address => mapping(uint256 => SaleIdDetail)) public nftSaleIds;
    
    struct PriceToken {
        address priceTokenAddress;
        bool enabled;
    }
    uint256 public totalSupportedPriceTokens;
    mapping(uint256 => PriceToken) public supportedPriceTokens;
    
//EVENTS
    event FeesChanged(uint256 newFee, address changedBy, uint256 time);
    event AddedToMarketplace(address nftContract, uint256 nftId, address seller, uint256 listedAt, uint256 price, uint256 fees, uint256 authorFees, uint256 saleId, uint256 tokenId);
    event Buy(address nftContract, address buyer, uint256 saleId, uint256 boughtAt);
    event RemovedFromMarketplace(address nftContract, uint256 saleId);
    event PriceUpdated(address nftContract, uint256 saleId, uint256 price, uint256 priceTokenId);
    event PriceTokenAdded(address tokenAddress, address addedBy, uint256 addedAt);
    event PriceTokenDisabled(uint256 tokenAddress, address disabledBy, uint256 disabledAt);
    event WhitelistedContract(address nftContract, address author, uint256 authorFees, address whitelistedBy, uint256 whitelistedAt);
    event AuthorDetailsChanged(address nftContract, address author, uint256 authorFees, address changedBy, uint256 changedAt);
    event BlacklistedContract(address nftContract, address blacklistedBy, uint256 blacklistedAt);
    event FeesWithdrawal(uint256 priceTokenId, uint256 amount, address withdrawalBy, uint256 withdrawalAt);
//CONSTRUCTOR
    constructor(uint256 _fees){
        require(fees <= DENOMINATOR, 'INVALID FEES');
        fees = _fees;
        supportedPriceTokens[totalSupportedPriceTokens].priceTokenAddress = address(0);
        supportedPriceTokens[totalSupportedPriceTokens].enabled = true;
        totalSupportedPriceTokens = totalSupportedPriceTokens + 1;
        emit PriceTokenAdded(address(0), msg.sender, block.timestamp);
        emit FeesChanged(_fees, msg.sender, block.timestamp);
    }
    
//USER FUNCTIONS
    function addToMarketplace(address _contract, uint256 _nftId, uint256 _price, uint256 _priceTokenId) external nonReentrant() returns(bool){
        require(supportedPriceTokens[_priceTokenId].enabled, 'Invalid price token id');
        ContractDetails storage contractDetails = whitelistedContracts[_contract];
        require(contractDetails.isWhitelisted, 'NFT contract not whitelisted!!');
        uint256 currentSaleId = nftSaleIds[_contract][_nftId].currentSaleId;
        require(currentSaleId == 0, 'Already listed');
        uint256 saleId = contractDetails.totalListed + 1;
        Sale storage sale = sales[_contract][saleId];
        sale.nftId = _nftId;
        sale.seller = msg.sender;
        sale.listedAt = block.timestamp;
        sale.price = convertValue(_price, _priceTokenId, true);
        sale.fees = fees;
        sale.authorFees = contractDetails.authorFees;
        sale.priceTokenId = _priceTokenId;
        sale.status = Status.UnSold;
        nftSaleIds[_contract][_nftId].allSaleIds.push(saleId);
        nftSaleIds[_contract][_nftId].currentSaleId = saleId;
        contractDetails.totalListed = contractDetails.totalListed + 1;
        ERC721(_contract).transferFrom(msg.sender, address(this), _nftId);
        emit AddedToMarketplace(_contract, _nftId, msg.sender, sale.listedAt, sale.price, fees, contractDetails.authorFees, saleId, _priceTokenId);
        return true;
    }
    
    function removeFromMarketplace(address _contract, uint256 _nftId) external nonReentrant() returns(bool){
        uint256 saleId = nftSaleIds[_contract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        Sale storage sale = sales[_contract][saleId];
        require(sale.seller == msg.sender, 'Only seller can remove');
        sale.status = Status.Removed;
        nftSaleIds[_contract][_nftId].currentSaleId = 0;
        whitelistedContracts[_contract].totalRemoved = whitelistedContracts[_contract].totalRemoved + 1;
        ERC721(_contract).transferFrom(address(this), sale.seller, _nftId);
        emit RemovedFromMarketplace(_contract, saleId);
        return true;
    }
    
    function buy(address _contract, uint256 _nftId) external nonReentrant() payable returns(bool){
        uint256 saleId = nftSaleIds[_contract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        Sale storage sale = sales[_contract][saleId];
        ContractDetails storage contractDetails = whitelistedContracts[_contract];
        sale.status = Status.Sold;
        nftSaleIds[_contract][_nftId].currentSaleId = 0;
        uint256 authorShare = sale.price * sale.authorFees / DENOMINATOR;
        uint256 marketPlaceFees = sale.price * sale.fees / DENOMINATOR;
        uint256 priceTokenId = sale.priceTokenId;
        feesDetail.collected = feesDetail.collected + marketPlaceFees;
        feesDetail.collectedPerToken[priceTokenId] = feesDetail.collectedPerToken[priceTokenId] + marketPlaceFees;
        feesDetail.authorFees[_contract] = feesDetail.authorFees[_contract] + authorShare;
        contractDetails.totalVolume = contractDetails.totalVolume + sale.price;
        contractDetails.totalSold = contractDetails.totalSold + 1;
        contractDetails.totalFeesCollected = contractDetails.totalFeesCollected + marketPlaceFees;
        contractDetails.totalAuthorFeesCollected = contractDetails.totalAuthorFeesCollected + authorShare;
        if(priceTokenId == 0){
            require(msg.value >= sale.price, 'amount paid is less than the price of NFT');
            uint256 extraAmountPaid = msg.value - sale.price;
            payable(sale.seller).transfer(sale.price - authorShare - marketPlaceFees);
            payable(contractDetails.author).transfer(authorShare);
            if(extraAmountPaid > 0){
                payable(msg.sender).transfer(extraAmountPaid);
            }
        } else {
            ERC20 priceTokenAddress = ERC20(supportedPriceTokens[priceTokenId].priceTokenAddress);
            priceTokenAddress.transferFrom(msg.sender, contractDetails.author, convertValue(authorShare, priceTokenId, false));
            priceTokenAddress.transferFrom(msg.sender, address(this), convertValue(marketPlaceFees, priceTokenId, false));
            priceTokenAddress.transferFrom(msg.sender, sale.seller, convertValue(sale.price - authorShare - marketPlaceFees, priceTokenId, false));
        }
        ERC721(_contract).transferFrom(address(this), msg.sender, _nftId);
        emit Buy(_contract, msg.sender, saleId, block.timestamp);
        return true;
    }
    
    function updatePrice(address _contract, uint256 _nftId, uint256 _newPrice, uint256 _priceTokenId) external returns(bool){
        require(supportedPriceTokens[_priceTokenId].enabled, 'Invalid price token id');
        uint256 saleId = nftSaleIds[_contract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        Sale storage sale = sales[_contract][saleId];
        require(sale.seller == msg.sender, 'Only seller can update price');
        sale.priceTokenId = _priceTokenId;
        sale.price = convertValue(_newPrice, _priceTokenId, true);
        emit PriceUpdated(_contract, saleId, sale.price, _priceTokenId);
        return true;
    }
  
//OWNER FUNCTIONS

    function whitelistContract(address _contract, address _author, uint256 _authorFees) external onlyOwner() returns(bool){
        require(!whitelistedContracts[_contract].isWhitelisted, 'Already whitelisted');
        require(_contract != address(0), 'Invalid contract address');
        require(_author != address(0), 'Invalid author');
        require(_authorFees + fees <= DENOMINATOR, 'Invalid author fees');
        if(whitelistedContracts[_contract].author == address(0)){
            whitelistedContractsInternal.push(_contract);
        }
        whitelistedContracts[_contract].author = _author;
        whitelistedContracts[_contract].authorFees = _authorFees;
        whitelistedContracts[_contract].isWhitelisted = true;
        emit WhitelistedContract(_contract, _author, _authorFees, msg.sender, block.timestamp);
        return true;
    }
    
    function changeAuthorDetails(address _contract, address _author, uint256 _authorFees) external onlyOwner() returns(bool){
        require(whitelistedContracts[_contract].isWhitelisted, 'Not whitelisted, whitelist it with new details');
        require(_contract != address(0), 'Invalid contract address');
        require(_author != address(0), 'Invalid author');
        require(_authorFees + fees <= DENOMINATOR, 'Invalid author fees');
        whitelistedContracts[_contract].author = _author;
        whitelistedContracts[_contract].authorFees = _authorFees;
        emit AuthorDetailsChanged(_contract, _author, _authorFees, msg.sender, block.timestamp);
        return true;
    }
    
    function blacklistContract(address _contract) external onlyOwner() returns(bool){
        require(whitelistedContracts[_contract].author != address(0), 'Invalid contract');
        require(whitelistedContracts[_contract].isWhitelisted , 'Already blacklisted');
        whitelistedContracts[_contract].isWhitelisted = false;
        emit BlacklistedContract(_contract, msg.sender, block.timestamp);
        return true;
    }
    
    function updateFees(uint256 _newFees) external onlyOwner() returns(bool){
        require(checkFeesValid(_newFees), 'Invalid Fees');
        fees = _newFees;
        emit FeesChanged( _newFees, msg.sender, block.timestamp);
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
    function getUnSoldNFTs(address _contract, uint256 _fromSaleId) external view returns(uint256, Sale[10] memory){
        uint256 toSaleId = whitelistedContracts[_contract].totalListed;
        if(toSaleId > _fromSaleId + RANGE){
            toSaleId = _fromSaleId + RANGE;
        }
        Sale[10] memory saleList;
        uint8 totalSaleAdded = 0;
        for (uint256 i = _fromSaleId; i <= toSaleId; i++ ){
            Sale memory sale = sales[_contract][_fromSaleId];
            if (sale.status == Status.UnSold){
                saleList[totalSaleAdded] = sale;
                totalSaleAdded++;
            } else {
                toSaleId = toSaleId+1;
            }
        }
        return (toSaleId, saleList);
    }
    
    function NFTSaleDetail(address _contract, uint256 _nftId) external view returns(Sale memory){
        uint256 saleId = nftSaleIds[_contract][_nftId].currentSaleId;
        require(saleId > 0, 'This NFT is not listed');
        return sales[_contract][saleId];
    }
    
    function totalNFTListed(address _contract) external view returns(uint256, uint256, uint256){
        uint256 totalListedLast24Hours = 0;
        uint256 totalListedLast7Days = 0;
        uint256 totalListedLast30Days = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = whitelistedContracts[_contract].totalListed; i >= 1; i--){
            Sale memory sale = sales[_contract][i];
            if(sale.listedAt >= currentTime - ONEDAY){
                totalListedLast24Hours = totalListedLast24Hours + 1;
            } 
            if(sale.listedAt >= currentTime - SEVENDAY){
                totalListedLast7Days = totalListedLast7Days + 1;
            } 
            if(sale.listedAt >= currentTime - THIRTYDAY){
                totalListedLast30Days = totalListedLast30Days + 1;
            } else {
                break;
            }
        }
        return (totalListedLast24Hours, totalListedLast7Days, totalListedLast30Days);
    }
    
    function totalNFTSold(address _contract) external view returns(uint256, uint256, uint256){
        uint256 totalSoldLast24Hours = 0;
        uint256 totalSoldLast7Days = 0;
        uint256 totalSoldLast30Days = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = whitelistedContracts[_contract].totalListed; i >= 1; i--){
            Sale memory sale = sales[_contract][i];
            if(sale.listedAt < currentTime - THIRTYDAY ){
                break;
            }
            else if(sale.status == Status.Sold){
                if(sale.listedAt >= currentTime - ONEDAY){
                    totalSoldLast24Hours = totalSoldLast24Hours + 1;
                } 
                if(sale.listedAt >= currentTime - SEVENDAY){
                    totalSoldLast7Days = totalSoldLast7Days + 1;
                } 
                if(sale.listedAt >= currentTime - THIRTYDAY){
                    totalSoldLast30Days = totalSoldLast30Days + 1;
                }
            }
        }
        return (totalSoldLast24Hours, totalSoldLast7Days, totalSoldLast30Days);
    }
    
    function totalVolume(address _contract) external view returns(uint256, uint256, uint256){
        uint256 totalVolumeLast24Hours = 0;
        uint256 totalVolumeLast7Days = 0;
        uint256 totalVolumeLast30Days = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = whitelistedContracts[_contract].totalListed; i >= 1; i--){
            Sale memory sale = sales[_contract][i];
            if(sale.listedAt < currentTime - THIRTYDAY ){
                break;
            }
            else if(sale.status == Status.Sold){
                if(sale.listedAt >= currentTime - ONEDAY){
                    totalVolumeLast24Hours = totalVolumeLast24Hours + sale.price;
                } 
                if(sale.listedAt >= currentTime - SEVENDAY){
                    totalVolumeLast7Days = totalVolumeLast7Days + sale.price;
                } 
                if(sale.listedAt >= currentTime - THIRTYDAY){
                    totalVolumeLast30Days = totalVolumeLast30Days + sale.price;
                }
            }
        }
        return (totalVolumeLast24Hours, totalVolumeLast7Days, totalVolumeLast30Days);
    }
    
    function totalUnsold(address _contract) external view returns(uint256, uint256, uint256){
        uint256 totalUnsoldLast24Hours = 0;
        uint256 totalUnsoldLast7Days = 0;
        uint256 totalUnsoldLast30Days = 0;
        uint256 currentTime = block.timestamp;
        for(uint256 i = whitelistedContracts[_contract].totalListed; i >= 1; i--){
            Sale memory sale = sales[_contract][i];
            if(sale.listedAt < currentTime - THIRTYDAY ){
                break;
            }
            else if(sale.status == Status.UnSold){
                if(sale.listedAt >= currentTime - ONEDAY){
                    totalUnsoldLast24Hours = totalUnsoldLast24Hours + sale.price;
                } 
                if(sale.listedAt >= currentTime - SEVENDAY){
                    totalUnsoldLast7Days = totalUnsoldLast7Days + sale.price;
                } 
                if(sale.listedAt >= currentTime - THIRTYDAY){
                    totalUnsoldLast30Days = totalUnsoldLast30Days + sale.price;
                }
            }
        }
        return (totalUnsoldLast24Hours, totalUnsoldLast7Days, totalUnsoldLast30Days);
    }
    
    function getAllSaleIds(address _contract, uint256 _nftId) external view returns(uint256[] memory){
        return nftSaleIds[_contract][_nftId].allSaleIds;
    }
    
//INTERNAL FUNCTIONS
    function checkFeesValid(uint256 _fees) internal view returns(bool){
        for(uint256 i = 0; i < whitelistedContractsInternal.length; i++){
            if(whitelistedContracts[whitelistedContractsInternal[i]].authorFees + _fees > DENOMINATOR){
                return false;
            }
        }
        return true;
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

    receive() payable external{
        
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