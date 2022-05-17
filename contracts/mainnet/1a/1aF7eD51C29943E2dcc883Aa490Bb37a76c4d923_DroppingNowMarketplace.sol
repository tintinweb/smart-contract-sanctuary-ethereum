// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/ITokenManagerSelector.sol";
import "./interfaces/IPriceCalculatorManager.sol";
import "./interfaces/ITokenManager.sol";
import "./interfaces/IPriceCalculator.sol";
import "./interfaces/ICollectionsRegistry.sol";
import "./interfaces/IDroppingNowToken.sol";
import "./interfaces/IDropperToken.sol";
import "./libraries/HashHelper.sol";

contract DroppingNowMarketplace is Ownable, Pausable {
    bytes32 public immutable DOMAIN_SEPARATOR;
    
    ITokenManagerSelector public tokenManagerSelector;
    IPriceCalculatorManager public priceCalculatorManager;
    IDroppingNowToken public droppingNowToken;
    IDropperToken public dropperToken;
    ICollectionsRegistry public collectionsRegistry;
    address public saleRewardRecipient;
    address public dropRewardRecipient;
    address public dropRewardEscrowRecipient;
    uint256 public dropperFee;
    uint256 public marketplaceFee;
    uint256 public minItemPriceForDN;

    mapping (bytes32 => bool) private _auctions;

    event NewTokenManagerSelector(address indexed tokenManagerSelector);
    event NewPriceCalculatorManager(address indexed priceCalculatorManager);
    event NewDroppingNowToken(address indexed droppingNowToken);
    event NewDropperToken(address indexed dropperToken);
    event NewSaleRewardRecepient(address indexed saleRewardRecepient);
    event NewDropRewardRecepient(address indexed dropRewardRecepient);
    event NewDropRewardEscrowRecepient(address indexed dropRewardEscrowRecepient);
    event NewDropperFee(uint256 dropperFee);
    event NewMarketplaceFee(uint256 marketplaceFee);
    event NewMinItemPriceForDN(uint256 minItemPriceForDN);

    event SingleAuctionCreated(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string description
    );

    event BundleAuctionCreated(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        address seller,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string name,
        string description
    );

    event SingleSale(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        address buyer,
        address priceCalculator,
        uint256 price
    );

    event BundleSale(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        address seller,
        address buyer,
        address priceCalculator,
        uint256 price
    );

    event SingleAuctionCanceled(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount,
        address seller,
        address priceCalculator
    );

    event BundleAuctionCanceled(
        bytes32 indexed auctionHash,
        address indexed tokenAddress,
        uint256[] tokenIds,
        uint256[] amounts,
        address seller,
        address priceCalculator
    );

    constructor(
        address tokenManagerSelectorAddress,
        address priceCalculatorManagerAddress,
        address droppingNowTokenAddress,
        address dropperTokenAddress,
        address collectionsRegistryAddress,
        address saleRewardRecipientAddress,
        address dropRewardRecipientAddress,
        address dropRewardEscrowRecipientAddress,
        uint256 dropperFeeValue,
        uint256 marketplaceFeeValue,
        uint256 minItemPriceForDNValue
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0xc94add498610ef8f6b104cb561856491569d6e3bb6f1dd4762b8f7a04dc69952, // keccak256("DroppingNowMarketplace")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid,
                address(this)
            )
        );

        tokenManagerSelector = ITokenManagerSelector(tokenManagerSelectorAddress);
        priceCalculatorManager = IPriceCalculatorManager(priceCalculatorManagerAddress);
        droppingNowToken = IDroppingNowToken(droppingNowTokenAddress);
        dropperToken = IDropperToken(dropperTokenAddress);
        collectionsRegistry = ICollectionsRegistry(collectionsRegistryAddress);
        saleRewardRecipient = saleRewardRecipientAddress;
        dropRewardRecipient = dropRewardRecipientAddress;
        dropRewardEscrowRecipient = dropRewardEscrowRecipientAddress;
        dropperFee = dropperFeeValue;
        marketplaceFee = marketplaceFeeValue;
        minItemPriceForDN = minItemPriceForDNValue;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function createSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string calldata description
    ) external whenNotPaused {
        _createSingleAuction(
            tokenAddress,
            tokenId,
            amount,
            listOn,
            startingPrice,
            priceCalculator,
            description);
    }

    function createMultipleSingleAuctions(
        address[] calldata tokenAddresses,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata listOns,
        uint256[] memory startingPrices,
        address[] memory priceCalculators,
        string[] calldata descriptions
    ) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _createSingleAuction(
                tokenAddresses[i],
                tokenIds[i],
                amounts[i],
                listOns[i],
                startingPrices[i],
                priceCalculators[i],
                descriptions[i]);
        }
    }

    function createBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string memory name,
        string memory description
    ) external whenNotPaused {
        if (listOn < block.timestamp) {
            listOn = block.timestamp;
        }

        require(tokenIds.length > 1, "DroppingNowMarketplace: bundle auction cannot be created with single token");
        require(amounts.length == tokenIds.length, "DroppingNowMarketplace: count of amounts must be same as tokens count");
        require(listOn < (block.timestamp + 30 days), "DroppingNowMarketplace: cannot be listed later than 30 days");
        require(priceCalculatorManager.isCalculatorAllowed(priceCalculator), "DroppingNowMarketplace: calculator is not allowed");
        require(IPriceCalculator(priceCalculator).isPriceAllowed(startingPrice), "DroppingNowMarketplace: price is not allowed");

        uint256[] memory amountsEscrow = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 amount = _escrowToken(msg.sender, tokenAddress, tokenIds[i], amounts[i]);
            amountsEscrow[i] = amount;
        }

        bytes32 auctionHash = HashHelper.bundleAuctionHash(
            tokenAddress,
            tokenIds,
            amountsEscrow,
            listOn,
            startingPrice,
            priceCalculator,
            msg.sender,
            DOMAIN_SEPARATOR);

        _auctions[auctionHash] = true;
        emit BundleAuctionCreated(
            auctionHash,
            tokenAddress,
            tokenIds,
            amountsEscrow,
            msg.sender,
            listOn,
            startingPrice,
            priceCalculator,
            name,
            description);
    }

    function buySingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external payable whenNotPaused {
        require(listOn <= block.timestamp, "DroppingNowMarketplace: auction is not started");

        // validate
        bytes32 auctionHash = HashHelper.singleAuctionHash(
            tokenAddress,
            tokenId,
            amount,
            listOn,
            startingPrice,
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        uint256 totalPrice = IPriceCalculator(priceCalculator).calculateCurrentPrice(startingPrice, listOn);
        require(msg.value >= totalPrice, "DroppingNowMarketplace: insufficient money sent");

        _auctions[auctionHash] = false;

        uint256 sellerValue = totalPrice;

        {
            // 1. calculate, transfer and reward dropper fee
            uint256 dropperFeePayed = _payDropperFee(tokenAddress, amount, totalPrice);
            _dropReward(seller, tokenAddress, tokenId, amount);
            sellerValue = sellerValue - dropperFeePayed;
        }

        {
            // 2. calculate, transfer and reward marketplace fee
            uint256 marketplaceFeePayed = _payMarketplaceFee(totalPrice);
            _saleReward(seller, tokenAddress, 1, totalPrice);
            sellerValue = sellerValue - marketplaceFeePayed;
        }

        // 3. transfer tokens from manager to buyer
        _withdrawToken(msg.sender, tokenAddress, tokenId, amount);

        // 4. transfer money to seller
        seller.transfer(sellerValue);

        // 5. return bid excess
        if (msg.value > totalPrice) {
            uint256 excess = msg.value - totalPrice;
            payable(msg.sender).transfer(excess);
        }

        emit SingleSale(auctionHash, tokenAddress, tokenId, amount, seller, msg.sender, priceCalculator, totalPrice);
    }

    function buyBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external payable whenNotPaused {
        require(listOn <= block.timestamp, "DroppingNowMarketplace: auction is not started");

        // validate
        bytes32 auctionHash = HashHelper.bundleAuctionHash(
            tokenAddress,
            tokenIds,
            amounts,
            listOn,
            startingPrice,
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        uint256 totalPrice = IPriceCalculator(priceCalculator).calculateCurrentPrice(startingPrice, listOn);
        require(msg.value >= totalPrice, "DroppingNowMarketplace: insufficient money sent");

        _auctions[auctionHash] = false;

        uint256 sellerValue = totalPrice;

        {
            // 1. calculate, transfer and reward dropper fee
            uint256 dropperFeePayed = _payDropperFee(tokenAddress, amounts[0], totalPrice);
            _dropRewardBundle(seller, tokenAddress, tokenIds, amounts[0]);
            sellerValue = sellerValue - dropperFeePayed;
        }
        
        {
            // 2. calculate, transfer and reward marketplace fee
            uint256 marketplaceFeePayed = _payMarketplaceFee(totalPrice);
            _saleReward(seller, tokenAddress, tokenIds.length, totalPrice);
            sellerValue = sellerValue - marketplaceFeePayed;
        }

        // 3. transfer tokens from manager to buyer
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _withdrawToken(msg.sender, tokenAddress, tokenIds[i], amounts[i]);
        }

        // 4. transfer money to seller
        seller.transfer(sellerValue);

        // 5. return bid excess
        if (msg.value > totalPrice) {
            uint256 excess = msg.value - totalPrice;
            payable(msg.sender).transfer(excess);
        }

        emit BundleSale(auctionHash, tokenAddress, tokenIds, amounts, seller, msg.sender, priceCalculator, totalPrice);
    }

    function cancelSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external whenPaused {
        require(msg.sender == seller, "DroppingNowMarketplace: only auction seller can cancel");

        _cancelSingleAuction(tokenAddress, tokenId, amount, listOn, startingPrice, priceCalculator, seller);
    }

    function ownerCancelSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external onlyOwner {
        _cancelSingleAuction(tokenAddress, tokenId, amount, listOn, startingPrice, priceCalculator, seller);
    }

    function cancelBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external whenPaused {
        require(msg.sender == seller, "DroppingNowMarketplace: only auction seller can cancel");

        _cancelBundleAuction(tokenAddress, tokenIds, amounts, listOn, startingPrice, priceCalculator, seller);
    }

    function ownerCancelBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) external onlyOwner {
        _cancelBundleAuction(tokenAddress, tokenIds, amounts, listOn, startingPrice, priceCalculator, seller);
    }

    function setTokenManagerSelector(address newTokenManagerSelector) external onlyOwner {
        require(newTokenManagerSelector != address(0), "DroppingNowMarketplace: address cannot be null");
        tokenManagerSelector = ITokenManagerSelector(newTokenManagerSelector);
        emit NewTokenManagerSelector(newTokenManagerSelector);
    }

    function setPriceCalculatorManager(address newPriceCalculatorManager) external onlyOwner {
        require(newPriceCalculatorManager != address(0), "DroppingNowMarketplace: address cannot be null");
        priceCalculatorManager = IPriceCalculatorManager(newPriceCalculatorManager);
        emit NewPriceCalculatorManager(newPriceCalculatorManager);
    }

    function setDroppingNowToken(address newDroppingNowToken) external onlyOwner {
        require(newDroppingNowToken != address(0), "DroppingNowMarketplace: address cannot be null");
        droppingNowToken = IDroppingNowToken(newDroppingNowToken);
        emit NewDroppingNowToken(newDroppingNowToken);
    }

    function setDropperToken(address newDropperToken) external onlyOwner {
        require(newDropperToken != address(0), "DroppingNowMarketplace: address cannot be null");
        dropperToken = IDropperToken(newDropperToken);
        emit NewDropperToken(newDropperToken);
    }

    function setSaleRewardRecipient(address newSaleRewardRecipient) external onlyOwner {
        require(newSaleRewardRecipient != address(0), "DroppingNowMarketplace: address cannot be null");
        saleRewardRecipient = newSaleRewardRecipient;
        emit NewSaleRewardRecepient(newSaleRewardRecipient);
    }

    function setDropRewardRecipient(address newDropRewardRecipient) external onlyOwner {
        require(newDropRewardRecipient != address(0), "DroppingNowMarketplace: address cannot be null");
        dropRewardRecipient = newDropRewardRecipient;
        emit NewDropRewardRecepient(newDropRewardRecipient);
    }

    function setDropRewardEscrowRecipient(address newDropRewardEscrowRecipient) external onlyOwner {
        require(newDropRewardEscrowRecipient != address(0), "DroppingNowMarketplace: address cannot be null");
        dropRewardEscrowRecipient = newDropRewardEscrowRecipient;
        emit NewDropRewardEscrowRecepient(newDropRewardEscrowRecipient);
    }
    
    function setDropperFee(uint256 newDropperFee) external onlyOwner {
        require(newDropperFee >= 0 && newDropperFee <= 10000, "DroppingNowMarketplace: fee must be between 0 and 10000");
        dropperFee = newDropperFee;
        emit NewDropperFee(newDropperFee);
    }

    function setMarketplaceFee(uint256 newMarketplaceFee) external onlyOwner {
        require(newMarketplaceFee >= 0 && newMarketplaceFee <= 10000, "DroppingNowMarketplace: fee must be between 0 and 10000");
        marketplaceFee = newMarketplaceFee;
        emit NewMarketplaceFee(newMarketplaceFee);
    }

    function setMinItemPriceForDN(uint256 newMinItemPriceForDN) external onlyOwner {
        minItemPriceForDN = newMinItemPriceForDN;
        emit NewMinItemPriceForDN(newMinItemPriceForDN);
    }

    function isAuctionAvailable(bytes32 auctionHash) external view returns (bool) {
        return _auctions[auctionHash];
    }

    function _createSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        string calldata description
    ) internal {
        if (listOn < block.timestamp) {
            listOn = block.timestamp;
        }

        require(listOn < (block.timestamp + 30 days), "DroppingNowMarketplace: cannot be listed later than 30 days");
        require(priceCalculatorManager.isCalculatorAllowed(priceCalculator), "DroppingNowMarketplace: calculator is not allowed");
        require(IPriceCalculator(priceCalculator).isPriceAllowed(startingPrice), "DroppingNowMarketplace: price is not allowed");

        uint256 amountEscrow = _escrowToken(msg.sender, tokenAddress, tokenId, amount);

        bytes32 auctionHash = HashHelper.singleAuctionHash(
            tokenAddress,
            tokenId,
            amountEscrow, 
            listOn,
            startingPrice,
            priceCalculator,
            msg.sender,
            DOMAIN_SEPARATOR);
        _auctions[auctionHash] = true;

        emit SingleAuctionCreated(
            auctionHash,
            tokenAddress,
            tokenId,
            amountEscrow,
            msg.sender,
            listOn,
            startingPrice,
            priceCalculator,
            description);
    }

    function _cancelSingleAuction(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) internal {
        bytes32 auctionHash = HashHelper.singleAuctionHash(
            tokenAddress,
            tokenId,
            amount,
            listOn,
            startingPrice, 
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        _auctions[auctionHash] = false;

        _withdrawToken(seller, tokenAddress, tokenId, amount);

        emit SingleAuctionCanceled(auctionHash, tokenAddress, tokenId, amount, seller, priceCalculator);
    }

    function _cancelBundleAuction(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address payable seller
    ) internal {
        bytes32 auctionHash = HashHelper.bundleAuctionHash(
            tokenAddress,
            tokenIds,
            amounts,
            listOn,
            startingPrice,
            priceCalculator,
            seller,
            DOMAIN_SEPARATOR);
        require(_auctions[auctionHash] == true, "DroppingNowMarketplace: is not on auction");

        _auctions[auctionHash] = false;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _withdrawToken(seller, tokenAddress, tokenIds[i], amounts[i]);
        }

        emit BundleAuctionCanceled(auctionHash, tokenAddress, tokenIds, amounts, seller, priceCalculator);
    }

    function _escrowToken(
        address seller, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount
    ) internal returns (uint256) {
        address tokenManager = _getTokenManager(tokenAddress);
        uint256 amountDeposit = ITokenManager(tokenManager).deposit(seller, tokenAddress, tokenId, amount);
        return amountDeposit;
    }

    function _withdrawToken(
        address buyer, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount
    ) internal returns (uint256) {
        address tokenManager = _getTokenManager(tokenAddress);
        uint256 amountWithdraw = ITokenManager(tokenManager).withdraw(buyer, tokenAddress, tokenId, amount);
        return amountWithdraw;
    }

    function _getTokenManager(address tokenAddress) internal view returns (address) {
        address tokenManager = tokenManagerSelector.getManagerAddress(tokenAddress);
        require(tokenManager != address(0), "DroppingNowMarketplace: no token manager available");
        return tokenManager;
    }

    function _payDropperFee(
        address tokenAddress,
        uint256 amount,
        uint256 totalPrice
    ) internal returns(uint256) {
        if (amount != 0) {
            // ERC-1155 is not a subject for dropper fees
            return 0;
        }

        uint256 dropperFeeValue = totalPrice * dropperFee / 10000;
        try dropperToken.addReward{value: dropperFeeValue}(tokenAddress) {
            return dropperFeeValue;
        } catch {
            return 0;
        }
    }

    function _dropReward (
        address seller,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (amount != 0) {
            // ERC-1155 is not a subject for dropper rewards
            return;
        }

        address[] memory recipients = _getDropRewardRecipients(seller, tokenAddress);
        uint256[] memory amounts = _getDropRewardAmounts();
        dropperToken.tryAddMintable(recipients, amounts, tokenAddress, tokenId);
    }

    function _dropRewardBundle (
        address seller,
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256 amount
    ) internal {
        if (amount != 0) {
            // ERC-1155 is not a subject for dropper rewards
            return;
        }

        address[] memory recipients = _getDropRewardRecipients(seller, tokenAddress);
        uint256[] memory amounts = _getDropRewardAmounts();
        dropperToken.tryAddMintableBatch(recipients, amounts, tokenAddress, tokenIds);
    }

    function _payMarketplaceFee(
        uint256 totalPrice
    ) internal returns(uint256) {
        uint256 marketplaceFeeValue = totalPrice * marketplaceFee / 10000;
        try droppingNowToken.addReward{value: marketplaceFeeValue}() {
            return marketplaceFeeValue;
        } catch {
            return 0;
        }
    }

    function _saleReward (address seller, address tokenAddress, uint256 tokensLength, uint256 totalPrice) internal {
        uint256 rewardableTokensLength = totalPrice / minItemPriceForDN;
        if (rewardableTokensLength > tokensLength) {
            rewardableTokensLength = tokensLength;
        }

        if (rewardableTokensLength == 0) {
            return;
        }

        bool isApproved = collectionsRegistry.isCollectionApproved(tokenAddress);
        address owner;
        bool ownerHasCorrectAddressAndApproved;
        if (isApproved) {
            owner = Ownable(tokenAddress).owner();
            ownerHasCorrectAddressAndApproved = isApproved && owner != address(0);
        }

        uint256 arraySize = 2;
        if (ownerHasCorrectAddressAndApproved) {
            arraySize = 3;
        }

        address[] memory recipients = new address[](arraySize);
        recipients[0] = seller;
        recipients[1] = saleRewardRecipient;

        uint256[] memory amounts = new uint256[](arraySize);
        amounts[0] = 10 * rewardableTokensLength;
        amounts[1] = 10 * rewardableTokensLength;
        
        if (ownerHasCorrectAddressAndApproved) {
            recipients[2] = owner;
            amounts[1] = 5 * rewardableTokensLength;
            amounts[2] = 5 * rewardableTokensLength;
        }
        
        droppingNowToken.addMintable(recipients, amounts);
    }

    function _getDropRewardRecipients (
        address seller,
        address tokenAddress
    ) internal view returns (address[] memory) {
        address[] memory recipients = new address[](3);
        recipients[0] = seller;
        recipients[1] = dropRewardRecipient;
        recipients[2] = dropRewardEscrowRecipient;

        if (collectionsRegistry.isCollectionApproved(tokenAddress)) {
            address owner = Ownable(tokenAddress).owner();
            if (owner != address(0)) {
                recipients[2] = owner;
            }
        }

        return recipients;
    }

    function _getDropRewardAmounts() internal pure returns (uint256[] memory) {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 2;
        amounts[1] = 1;
        amounts[2] = 1;

        return amounts;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITokenManagerSelector {
    function getManagerAddress(address tokenAddress) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPriceCalculatorManager {
    function addCalculator(address calculator) external;

    function removeCalculator(address calculator) external;

    function isCalculatorAllowed(address calculator) external view returns (bool);

    function viewAllowedCalculators(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountAllowedCalculators() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ITokenManager {
    function deposit(
        address from,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external returns (uint256);

    function withdraw(
        address to,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IPriceCalculator {
    function calculatePrice(
        uint256 startingPrice,
        uint256 listedOn,
        uint256 time
    ) external pure returns (uint256);

    function calculateCurrentPrice(
        uint256 startingPrice,
        uint256 listedOn
    ) external view returns (uint256);

    function isPriceAllowed(
        uint256 startingPrice
    ) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICollectionsRegistry {
    function isCollectionApproved(address collectionAddress) external view returns(bool);

    function approveCollection(address tokenAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDroppingNowToken is IERC20 {
    function addMintable(address[] memory to, uint256[] memory amounts) external;

    function addReward() external payable;

    function claimReward() external;

    function claimTokens() external;

    function rewardBalanceOf(address owner) external view returns (uint256);

    function mintableBalanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDropperToken is IERC1155 {
    function tryAddMintable(address[] memory to, uint256[] memory amounts, address tokenAddress, uint256 tokenId) external;

    function tryAddMintableBatch(address[] memory to, uint256[] memory amounts, address tokenAddress, uint256[] memory tokenIds) external;

    function addReward(address tokenAddress) external payable;

    function claimRewardBatch(uint256[] calldata ids) external;

    function claimTokens(uint256 id) external;

    function claimTokensBatch(uint256[] calldata ids) external;

    function getId(address tokenAddress) external view returns (uint256);

    function mintableBalanceOf(address owner, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library HashHelper {
    // keccak256("SingleItemAuction(address tokenAddress,uint256 tokenId,uint256 amount,uint256 listOn,uint256 startingPrice,address priceCalculator,address seller)")
    bytes32 internal constant SINGLE_ITEM_AUCTION_HASH = 0x690efce55f6873cc2cf4903c21f626dea40a056811d11e48e991e5e2c7b2e1f4;

    // keccak256("BundleAuction(address tokenAddress,uint256[] tokenIds,uint256[] amounts,uint256 listOn,uint256 startingPrice,address priceCalculator,address seller)")
    bytes32 internal constant BUNDLE_AUCTION_HASH = 0x4a8431ddb4840ad14978d81bf98f5b14f5bc0f9306fab2c4c72c2e01593ad2db;

    function singleAuctionHash(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address seller,
        bytes32 domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    domain,
                    SINGLE_ITEM_AUCTION_HASH,
                    tokenAddress,
                    tokenId,
                    amount,
                    listOn,
                    startingPrice,
                    priceCalculator,
                    seller
                )
            );
    }

    function bundleAuctionHash(
        address tokenAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 listOn,
        uint256 startingPrice,
        address priceCalculator,
        address seller,
        bytes32 domain) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    domain,
                    BUNDLE_AUCTION_HASH,
                    tokenAddress,
                    tokenIds,
                    amounts,
                    listOn,
                    startingPrice,
                    priceCalculator,
                    seller
                )
            );
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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