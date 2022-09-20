// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/INFT.sol';
import './interfaces/IHUB.sol';
import './interfaces/IWETH.sol';
import './interfaces/IPYESwapRouter.sol';

contract TopiaPeerExchange is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // The Metatopia ERC721 token contracts
    INFT public GENESIS;
    INFT public ALPHA;
    INFT public RATS;

    // The address of the HUB contract
    IHUB public HUB;

    // The address of the WETH contract
    address public WETH;

    // The address of the TOPIA contract
    IERC20 public TOPIA;

    IPYESwapRouter public pyeSwapRouter;

    // The minimum percentage difference between the last offer amount and the current offer
    uint16 public minOfferIncrementPercentage;
    
    // The minimum listing and offer variables
    bool public useManualMinListPrice;
    uint256 public manualMinListPrice;
    uint16 public minListPercent;
    uint16 public minOfferPercent;

    // Restriction Bools
    bool public isPaused;
    bool public allListersAllowed = true;
    bool public allBuyersAllowed = true;
    bool public allOfferersAllowed = true;

    // The listing info
    struct Listing {
        // The address of the Lister
        address payable lister;
        // The current highest offer amount
        uint256 topiaAmount;
        // The Requested ETH for the listing
        uint256 requestedEth;
        // The time that the listing started
        uint256 startTime;
        // The time that the listing is scheduled to end
        uint256 endTime;
        // The address of the current highest offer
        address payable offerer;
        // The current offer below the requested ETH amount
        uint256 currentOffer;
        // The previous offer
        uint256 previousOffer;
        // The active offerId
        uint256 activeOfferId;
        // The number of offers placed
        uint16 numberOffers;
        // The statuses of the listing
        bool settled;
        bool canceled;
        bool failed;
    }
    mapping(uint256 => Listing) public listingId;
    uint256 private currentId = 1;
    uint256 private currentOfferId = 1;
    mapping(uint256 => uint256[]) public allListingOfferIds;

    struct Offers {
        address offerer;
        uint256 offerAmount;
        uint256 listingId;
        uint8 offerStatus; // 1 = active, 2 = outoffer, 3 = canceled, 4 = accepted
    }
    mapping(uint256 => Offers) public offerId;
    mapping(address => uint256[]) userOffers;
    uint256 public activeListingCount;

    uint16 public tax;
    address payable public taxWallet;

    modifier holdsNFTLister() {
        require(allListersAllowed || HUB.balanceOf(msg.sender) > 0 || GENESIS.balanceOf(msg.sender) > 0 || ALPHA.balanceOf(msg.sender) > 0 || RATS.balanceOf(msg.sender) > 0, "Must hold a Metatopia NFT");
        _;
    }

    modifier holdsNFTBuyer() {
        require(allBuyersAllowed || HUB.balanceOf(msg.sender) > 0 || GENESIS.balanceOf(msg.sender) > 0 || ALPHA.balanceOf(msg.sender) > 0 || RATS.balanceOf(msg.sender) > 0, "Must hold a Metatopia NFT");
        _;
    }

    modifier holdsNFTOfferer() {
        require(allOfferersAllowed || HUB.balanceOf(msg.sender) > 0 || GENESIS.balanceOf(msg.sender) > 0 || ALPHA.balanceOf(msg.sender) > 0 || RATS.balanceOf(msg.sender) > 0, "Must hold a Metatopia NFT");
        _;
    }

    modifier notPaused() {
        require(!isPaused, "Contract is Paused to new listings");
        _;
    }

    event ListingCreated(uint256 indexed ListingId, uint256 startTime, uint256 endTime, uint256 TopiaAmount, uint256 EthPrice);
    event OfferPlaced(uint256 indexed OfferId, uint256 indexed ListingId, address sender, uint256 value);
    event OfferCanceled(uint256 indexed OfferId, uint256 indexed ListingId, uint256 TimeStamp);
    event ListingSettled(uint256 indexed ListingId, address Buyer, address Seller, uint256 FinalAmount, uint256 TaxAmount, bool wasOffer, uint256 listedAmount);
    event ListingTimeBufferUpdated(uint256 timeBuffer);
    event ListingMinOfferIncrementPercentageUpdated(uint256 minOfferIncrementPercentage);
    event ListingRefunded(uint256 indexed ListingId, address Lister, uint256 TopiaRefundAmount, address Offerer, uint256 OffererRefundAmount, address Caller);
    event ListingCanceled(uint256 indexed ListingId, address Lister, uint256 TopiaAmount, uint256 TimeStamp);
    event Received(address indexed From, uint256 Amount);

    /**
     * @notice Initialize the listing house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    constructor(
        address _topia, 
        address _weth, 
        // address _genesis, 
        // address _alpha, 
        // address _hub, 
        address _router,
        uint16 _minOfferIncrementPercentage, 
        uint256 _minListPrice, 
        uint16 _minListPercent, 
        uint16 _minOfferPercent, 
        address payable _taxWallet, 
        uint16 _tax
    ) {
        TOPIA = IERC20(_topia);
        WETH = _weth;
        // GENESIS = INFT(_genesis);
        // ALPHA = INFT(_alpha);
        // HUB = IHUB(_hub);
        pyeSwapRouter = IPYESwapRouter(_router);
        minOfferIncrementPercentage = _minOfferIncrementPercentage;
        manualMinListPrice = _minListPrice;
        useManualMinListPrice = true;
        minListPercent = _minListPercent;
        minOfferPercent = _minOfferPercent;
        taxWallet = _taxWallet;
        tax = _tax;
    }

    /**
     * @notice Set the listing minimum offer increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinOfferIncrementPercentage(uint16 _minOfferIncrementPercentage) external onlyOwner {
        minOfferIncrementPercentage = _minOfferIncrementPercentage;

        emit ListingMinOfferIncrementPercentageUpdated(_minOfferIncrementPercentage);
    }

    function setPaused(bool _flag) external onlyOwner {
        isPaused = _flag;
    }

    function setListersAllowed(bool _flag) external onlyOwner {
        allListersAllowed = _flag;
    }

    function setBuyersAllowed(bool _flag) external onlyOwner {
        allBuyersAllowed = _flag;
    }

    function setOfferersAllowed(bool _flag) external onlyOwner {
        allOfferersAllowed = _flag;
    }

    function setRatsContract(address _rats) external onlyOwner {
        RATS = INFT(_rats);
    }

    function setHubContract(address _hub) external onlyOwner {
        HUB = IHUB(_hub);
    }

    function setTax(address payable _taxWallet, uint16 _tax) external onlyOwner {
        taxWallet = _taxWallet;
        tax = _tax;
    }

    function setMinListPrice(uint256 _minListPrice) external onlyOwner {
        manualMinListPrice = _minListPrice;
    }

    function setUseManualMinListPrice(bool _flag) external onlyOwner {
        useManualMinListPrice = _flag;
    }

    function setMinListPercent(uint16 _percent) external onlyOwner {
        minListPercent = _percent;
    }

    function setMinOfferPercent(uint16 _percent) external onlyOwner {
        minOfferPercent = _percent;
    }

    function createListing(uint256 _topiaAmount, uint256 _requestedEth, uint256 _endTime) external notPaused holdsNFTLister nonReentrant {
        require((_requestedEth * 10**9) / _topiaAmount >= minListPrice(), "Listing Price too low");
        uint256 startTime = block.timestamp;
        uint256 _listingId = currentId++;

        listingId[_listingId].lister = payable(msg.sender);
        listingId[_listingId].topiaAmount = _topiaAmount;
        listingId[_listingId].requestedEth = _requestedEth;
        listingId[_listingId].startTime = startTime;
        listingId[_listingId].endTime = _endTime;
        activeListingCount++;

        TOPIA.safeTransferFrom(msg.sender, address(this), _topiaAmount);

        emit ListingCreated(_listingId, startTime, _endTime, _topiaAmount, _requestedEth);
    }

    function cancelListing(uint256 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can cancel");
        require(listingStatus(_id) == 1, "Listing is not active");
        listingId[_id].canceled = true;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            listingId[_id].offerer = payable(address(0));
            listingId[_id].currentOffer = 0;
            offerId[listingId[_id].activeOfferId].offerStatus = 3;
        }
        activeListingCount--;
        TOPIA.safeTransfer(listingId[_id].lister, listingId[_id].topiaAmount);

        emit ListingCanceled(_id, listingId[_id].lister, listingId[_id].topiaAmount, block.timestamp);
        emit ListingRefunded(_id, listingId[_id].lister, listingId[_id].topiaAmount, listingId[_id].offerer, listingId[_id].currentOffer, msg.sender);
    }

    /**
     * @notice Create a offer for TOPIA, with a given ETH amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createOffer(uint256 _id) external payable holdsNFTOfferer nonReentrant {
        require(listingStatus(_id) == 1, 'Topia Listing is not Active');
        require(block.timestamp < listingId[_id].endTime, 'Listing expired');
        require(msg.value <= listingId[_id].requestedEth, 'Must send less than requestedEth');
        require(msg.value >= listingId[_id].requestedEth * minOfferPercent / 10000, 'Must offer more than minimum offer amount');
        require(
            msg.value >= listingId[_id].currentOffer + ((listingId[_id].currentOffer * minOfferIncrementPercentage) / 10000),
            'Must send more than last offer by minOfferIncrementPercentage amount'
        );
        require(msg.sender != listingId[_id].lister, 'Lister not allowed to Offer');

        address payable lastOfferer = listingId[_id].offerer;
        uint256 _offerId = currentOfferId++;

        // Refund the last offerer, if applicable
        if (lastOfferer != address(0)) {
            _safeTransferETHWithFallback(lastOfferer, listingId[_id].currentOffer);  
            offerId[listingId[_id].activeOfferId].offerStatus = 2;
            listingId[_id].previousOffer = listingId[_id].currentOffer;
        }

        listingId[_id].currentOffer = msg.value;
        listingId[_id].offerer = payable(msg.sender);
        listingId[_id].activeOfferId = _offerId;
        listingId[_id].numberOffers++;
        allListingOfferIds[_id].push(_offerId);
        offerId[_offerId].offerer = msg.sender;
        offerId[_offerId].offerAmount = msg.value;
        offerId[_offerId].listingId = _id;
        offerId[_offerId].offerStatus = 1;
        userOffers[msg.sender].push(_offerId);

        emit OfferPlaced(_offerId, _id, msg.sender, msg.value);
    }

    function cancelOffer(uint256 _id, uint256 _offerId) external nonReentrant {
        require(offerId[_offerId].offerer == msg.sender, "Caller is not Offerer");
        require(offerId[_offerId].listingId == _id && listingId[_id].activeOfferId == _offerId, "IDs do not match");
        require(listingStatus(_id) == 1, "Topia Listing is not Active");
        require(offerId[_offerId].offerStatus == 1, "Offer is not active");

        _safeTransferETHWithFallback(payable(msg.sender), offerId[_offerId].offerAmount);
        offerId[listingId[_id].activeOfferId].offerStatus = 3;
        listingId[_id].currentOffer = listingId[_id].previousOffer;
        listingId[_id].offerer = payable(address(0));
        listingId[_id].activeOfferId = 0;

        emit OfferCanceled(_offerId, _id, block.timestamp);
    }

    /**
     * @notice Settle a listing to high offerer and paying out to the lister.
     */
    function acceptOffer(uint256 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister, "Only Lister can accept offer");
        require(listingStatus(_id) == 1, "Listing has already been settled or canceled");
        require(block.timestamp <= listingId[_id].endTime, "Listing has expired");
        require(listingId[_id].offerer != address(0), "No active Offerer");
        require(offerId[listingId[_id].activeOfferId].offerStatus == 1, "Offer is not active");

        listingId[_id].settled = true;
        activeListingCount--;

        uint256 taxAmount = listingId[_id].currentOffer * tax / 10000;
        uint256 finalEthAmount = listingId[_id].currentOffer - taxAmount;

        TOPIA.safeTransfer(listingId[_id].offerer, listingId[_id].topiaAmount);
        _safeTransferETHWithFallback(taxWallet, taxAmount);
        _safeTransferETHWithFallback(listingId[_id].lister, finalEthAmount);
        offerId[listingId[_id].activeOfferId].offerStatus = 4;

        emit ListingSettled(_id, listingId[_id].offerer, listingId[_id].lister, listingId[_id].currentOffer, taxAmount, true, listingId[_id].requestedEth);
    }

    function buyNow(uint256 _id) external payable holdsNFTBuyer nonReentrant {
        require(listingStatus(_id) == 1, 'Listing has already been settled or canceled');
        require(block.timestamp <= listingId[_id].endTime, 'Listing has expired');
        require(msg.value == listingId[_id].requestedEth, 'ETH Value must be equal to listing price');

        listingId[_id].settled = true;
        activeListingCount--;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            offerId[listingId[_id].activeOfferId].offerStatus = 2;
        }

        uint256 taxAmount = listingId[_id].requestedEth * tax / 10000;
        uint256 finalEthAmount = listingId[_id].requestedEth - taxAmount;

        TOPIA.safeTransfer(msg.sender, listingId[_id].topiaAmount);
        _safeTransferETHWithFallback(taxWallet, taxAmount);
        _safeTransferETHWithFallback(listingId[_id].lister, finalEthAmount);

        emit ListingSettled(_id, listingId[_id].offerer, listingId[_id].lister, listingId[_id].requestedEth, taxAmount, false, listingId[_id].requestedEth);
    }

    function claimRefundOnExpire(uint256 _id) external nonReentrant {
        require(msg.sender == listingId[_id].lister || msg.sender == listingId[_id].offerer, 'Only Lister can accept offer');
        require(listingStatus(_id) == 3, 'Listing has not expired');
        listingId[_id].failed = true;
        activeListingCount--;

        if(listingId[_id].offerer != address(0) && listingId[_id].currentOffer > 0) {
            _safeTransferETHWithFallback(listingId[_id].offerer, listingId[_id].currentOffer);
            listingId[_id].offerer = payable(address(0));
            listingId[_id].currentOffer = 0;
        }
        TOPIA.safeTransfer(listingId[_id].lister, listingId[_id].topiaAmount);

        emit ListingRefunded(_id, listingId[_id].lister, listingId[_id].topiaAmount, listingId[_id].offerer, listingId[_id].currentOffer, msg.sender);
    }

    function listingStatus(uint256 _id) public view returns (uint8) {
        if (listingId[_id].canceled) {
        return 3; // CANCELED - Lister canceled
        }
        if ((block.timestamp > listingId[_id].endTime) && !listingId[_id].settled) {
        return 3; // FAILED - not sold by end time
        }
        if (listingId[_id].settled) {
        return 2; // SUCCESS - hardcap met
        }
        if ((block.timestamp <= listingId[_id].endTime) && !listingId[_id].settled) {
        return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUEUED - awaiting start time
    }

    function getOffersByListingId(uint256 _id) external view returns (uint256[] memory offerIds) {
        uint256 length = allListingOfferIds[_id].length;
        offerIds = new uint256[](length);
        for(uint i = 0; i < length; i++) {
            offerIds[i] = allListingOfferIds[_id][i];
        }
    }

    function getOffersByUser(address _user) external view returns (uint256[] memory offerIds) {
        uint256 length = userOffers[_user].length;
        offerIds = new uint256[](length);
        for(uint i = 0; i < length; i++) {
            offerIds[i] = userOffers[_user][i];
        }
    }

    function getTotalOffersLength() external view returns (uint256) {
        return currentOfferId;
    }

    function getOffersLengthForListing(uint256 _id) external view returns (uint256) {
        return allListingOfferIds[_id].length;
    }

    function getOffersLengthForUser(address _user) external view returns (uint256) {
        return userOffers[_user].length;
    }

    function getOfferInfoByIndex(uint256 _offerId) external view returns (address _offerer, uint256 _offerAmount, uint256 _listingId, string memory _offerStatus) {
        _offerer = offerId[_offerId].offerer;
        _offerAmount = offerId[_offerId].offerAmount;
        _listingId = offerId[_offerId].listingId;
        if(offerId[_offerId].offerStatus == 1) {
            _offerStatus = 'active';
        } else if(offerId[_offerId].offerStatus == 2) {
            _offerStatus = 'outOffered';
        } else if(offerId[_offerId].offerStatus == 3) {
            _offerStatus = 'canceled';
        } else if(offerId[_offerId].offerStatus == 4) {
            _offerStatus = 'accepted';
        } else {
            _offerStatus = 'invalid OfferID';
        }
    }

    function getOfferStatus(uint256 _offerId) external view returns (string memory _offerStatus) {
        if(offerId[_offerId].offerStatus == 1) {
            _offerStatus = 'active';
        } else if(offerId[_offerId].offerStatus == 2) {
            _offerStatus = 'outoffer';
        } else if(offerId[_offerId].offerStatus == 3) {
            _offerStatus = 'canceled';
        } else if(offerId[_offerId].offerStatus == 4) {
            _offerStatus = 'accepted';
        } else {
            _offerStatus = 'invalid OfferID';
        }
    }

    function getAllActiveListings() external view returns (uint256[] memory _activeListings) {
        uint256 length = activeListingCount;
        _activeListings = new uint256[](length);
        uint256 z = 0;
        for(uint i = 1; i <= currentId; i++) {
            if(listingStatus(i) == 1) {
                _activeListings[z] = i;
                z++;
            } else {
                continue;
            }
        }
    }

    function getAllListings() external view returns (uint256[] memory listings, uint256[] memory status) {
        listings = new uint256[](currentId);
        status = new uint256[](currentId);
        for(uint i = 1; i < currentId; i++) {
            listings[i - 1] = i;
            status[i - 1] = listingStatus(i);
        }
    }

    function minListPrice() public view returns (uint256) {
        if(useManualMinListPrice) {
            return manualMinListPrice; 
        } else {
            address[] memory path = new address[](2);
            path[0] = address(TOPIA);
            path[1] = WETH;
            uint256 amountOut = 1 * 10**16;
            uint256[] memory amounts = pyeSwapRouter.getAmountsIn(1 * 10**16, path, 0);
            uint256 ethPerToken = (amountOut * 10**9) / amounts[0];
            return ethPerToken * minListPercent / 10000;
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(WETH).deposit{ value: amount }();
            IERC20(WETH).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IPYESwapRouter {
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path, uint totalFee) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path, uint totalFee) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IHUB {
    function emitGenesisStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitAlphaStaked(address owner, uint16[] calldata tokenIds, uint8 gameId) external;
    function emitGenesisUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitAlphaUnstaked(address owner, uint16[] calldata tokenIds) external;
    function emitTopiaClaimed(address owner, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INFT is IERC721Enumerable {
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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