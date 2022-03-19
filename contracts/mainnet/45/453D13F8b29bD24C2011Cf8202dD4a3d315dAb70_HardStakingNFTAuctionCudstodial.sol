/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

pragma solidity =0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function tokenCustodian(uint tokenId) external view returns (address);
}

interface ICollectionToken is IERC721Metadata {
    struct Collection {
        uint collectionId;
        string name;
        uint maxCollectionSize;
        bool isDigitalObject;
        uint[] tokens;
    }

    function tokenToCollection(uint tokenId) external view returns (uint);
    function collection(uint collectionId) external view returns (Collection memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC20Permit is IERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

interface IAggregatorInterface {
  function latestAnswer() external view returns (int256);
  function decimals() external view returns (uint8);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender) + value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint value) internal {
        uint newAllowance = token.allowance(address(this), spender) - value;
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint private _guardCounter;

    constructor () {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract HardStakingNFTAuctionCudstodial is ReentrancyGuard, Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;

    enum AuctionType {
        Custodian,      // 0
        NonCustodian,   // 1
        NonCustodianKYC // 2
    }

    struct Auction {
        uint tokenId;
        uint auctionEnd;
        uint topBid;
        uint allBids;
        address topBidder;
        bool isWithdrawn;
        bool isEnded;
        address owner;
        string description;
        bool canceled;
        AuctionType auctionType;
        bool isDigitalObject;
        bool isFirstAuction;
    }

    struct TokenAuctionParams {
        uint auctionRoundDuration;
        uint successAuctionFeePercentage;
        AuctionType prevAuctionType;
        AuctionType auctionType;
    }

    struct Stake {
        uint lockTime;
        uint stakeAmount;
        bool isWithdrawn;
        bool isCustodian;
    }

    ICollectionToken public immutable auctionToken;
    IERC20 public purchaseToken;
    address public custodianAdmin;
    uint public constant MIN_AUCTION_DURATION = 4320 minutes;
    uint public minAuctionStartPrice;
    uint public nextBidStepPercentage;

    uint public defaultAuctionDuration;
    uint public lastAuctionId;
    mapping(uint => Auction) public auctions;
    mapping(uint => TokenAuctionParams) public tokenAuctionParams;
    mapping(uint => uint) public tokenLastAuctionId;
    mapping(uint => bool) public approvedAuctionsForCustodian;
    mapping(uint => bool) public providedKYCForNonCustodian;

    mapping(address => mapping(uint => Stake)) public userStakes;
    mapping(address => uint[]) internal _userAuctions;
    mapping(address => uint[]) internal _userCustodianStakes;

    uint internal _totalSupply;
    mapping(address => uint) internal _balances;

    event Staked(address indexed user, uint amount, uint indexed auctionId, uint indexed tokenId);
    event NewAuction(uint indexed auctionId, uint indexed tokenId, uint indexed collectionId, AuctionType auctionType, bool isDigitalObject, bool isFirstAuction);
    event AuctionInited(uint indexed auctionId, uint auctionEnd, uint indexed tokenId);
    event NewTopBid(uint indexed auctionId, uint indexed tokenId, uint bidAmount, address indexed bidder);
    event Withdraw(address indexed user, uint amount);
    event AuctionTokenWithdraw(address indexed winner, address previousOwner, uint bidAmount, uint fee, uint indexed tokenId, uint indexed auctionId);
    event AuctionProcessingKYC(address indexed winner, address previousOwner, uint bidAmount, uint indexed tokenId, uint indexed auctionId);
    event RescueAuctionToken(address indexed to, uint indexed auctionId, uint indexed tokenId, bool wasAuctionFinished);
    event ApproveAuctionForCustodian(uint indexed auctionId, bool indexed isApproved);
    event UpdateCustodianAdmin(address indexed oldCustodianAdmin, address indexed newCustodianAdmin);
    event UpdateTokenAuctionParams(uint indexed tokenId, uint indexed auctionRoundDuration, uint indexed successAuctionFeePercentage, AuctionType prevAuctionType, AuctionType auctionType);
    event UpdatePriceFeed(address indexed priceFeed);
    event UpdateMinAuctionStartPrice(uint indexed newMinAuctionStartPrice);
    event UpdateDefaultAuctionDuration(uint indexed newDefaultAuctionDuration);
    event UpdateNextBidStepPercentage(uint indexed newNextBidStepPercentage);
    event RescueToken(address indexed to, address token, uint amount);

    constructor(
        address _auctionToken,
        address _custodianAdmin,
        address _purchaseToken
    ) {
        require(Address.isContract(_auctionToken), "NFTAuction: Not contract(s)");
        require(Address.isContract(_purchaseToken), "NFTAuction: Not contract(s)");
        require(_custodianAdmin != address(0), "NFTAuction: Zero custodian admin address");
        auctionToken = ICollectionToken(_auctionToken);
        custodianAdmin = _custodianAdmin;
        nextBidStepPercentage = 1050e17; //5% or 1.05
        purchaseToken = IERC20(_purchaseToken);
        defaultAuctionDuration = 4320 minutes;
    }

    modifier onlyCustodianAdmin {
        require(msg.sender == custodianAdmin, "NFTAuction: Caller is not the custodian admin");
        _;
    }

    modifier onlyOwnerOrCustodianAdmin {
        require(msg.sender == owner || msg.sender == custodianAdmin, "NFTAuction: Caller is not the custodian admin nor owner");
        _;
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        //equal to return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return 0x150b7a02;
    }

    function balanceOf(address account) external view returns (uint) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    function userAuctions(address user) external view returns (uint[] memory auctionIds) {
        return _userAuctions[user];
    }

    function userCustodianStakes(address user) external view returns (uint[] memory auctionIds) {
        return _userCustodianStakes[user];
    }

    function userCustodianStakeCounts(address user) external view returns (uint) {
        return _userCustodianStakes[user].length;
    }

    function userUnwithdrawnAuctions(address user) external view returns (uint[] memory auctionIds) {
        uint unwithdrawnStakesCnt;
        for (uint i; i < _userAuctions[user].length; i++) {
            uint auctionId = _userAuctions[user][i];
            if (!isAuctionActive(auctionId) 
                && userStakes[user][auctionId].stakeAmount > 0 
                && auctions[auctionId].topBidder != user)
                unwithdrawnStakesCnt++;
        }
        auctionIds = new uint[](unwithdrawnStakesCnt);
        unwithdrawnStakesCnt = 0;
        for (uint i; i < _userAuctions[user].length; i++) {
            uint auctionId = _userAuctions[user][i];
            if (!isAuctionActive(auctionId) 
                && userStakes[user][auctionId].stakeAmount > 0 
                && auctions[auctionId].topBidder != user) {
                auctionIds[unwithdrawnStakesCnt] = _userAuctions[user][i];
                unwithdrawnStakesCnt++;
            }
        }
    }

    function availableForWithdraw(address user, uint auctionId) public view returns (uint stake) {
        if (!isAuctionActive(auctionId) && auctions[auctionId].topBidder != user) {
            stake = userStakes[user][auctionId].stakeAmount;
        }
    }

    function getNextBidMinAmount(uint auctionId) external view returns (uint nextBid) {
        Auction storage auction = auctions[auctionId];
        if (auction.auctionEnd != 0 && auction.auctionEnd > block.timestamp) {
            nextBid = auction.topBid * nextBidStepPercentage / 1e20;
        } else if (auction.auctionEnd <= block.timestamp) {
            nextBid = 0;
        } else {
            nextBid = auction.topBid;
        }
    }

    function isAuctionActive(uint auctionId) public view returns (bool) {
        return block.timestamp < auctions[auctionId].auctionEnd;
    }

    function getLastSalePrice(uint tokenId) external view returns (uint) {
        uint auctionId = tokenLastAuctionId[tokenId];
        if (auctionId == 0) return 0;
        if (auctions[auctionId].auctionEnd > block.timestamp) {
            return auctions[auctionId].topBid;
        } else {
            return 0;
        }
    }

    function stake(uint auctionId, uint amount) external virtual {
        _stake(auctionId, amount, msg.sender);
    }

    function stakeFor(uint auctionId, uint amount, address user) external virtual {
        _stake(auctionId, amount, user);
    }

    function withdraw(uint auctionId) public {
        _withdraw(auctionId);
    }

    function withdrawByTokenId(uint tokenId) external {
        uint auctionId = tokenLastAuctionId[tokenId];
        withdraw(auctionId);
    }

    function withdrawForAuctions(uint[] memory auctionIds) external {
        for (uint i; i < auctionIds.length; i++) {
            withdraw(auctionIds[i]);
        }
    }

    function processSuccesfullAuction(uint auctionId) public { 
        Auction storage auction = auctions[auctionId];
        require(auction.auctionEnd != 0, "NFTAuction: Auction is not started");
        require(auction.auctionEnd < block.timestamp, "NFTAuction: Auction is not finished");
        require(!auction.isEnded, "NFTAuction: Auction already ended");
        require(auction.auctionType != AuctionType.NonCustodianKYC || (auction.auctionType == AuctionType.NonCustodianKYC && (msg.sender == owner || msg.sender == custodianAdmin)), "NFTAuction: Non-custodian KYC auction can be processed by custodian admin or owner");
        bool isCustodial = auction.auctionType == AuctionType.Custodian;
        if (isCustodial) {
            require(msg.sender == custodianAdmin || msg.sender == owner, "NFTAuction: Caller is not the custodian admin nor owner");
            require(approvedAuctionsForCustodian[auctionId], "NFTAuction: Not approved auction for processing by custodian");
        }

        address winner = auction.topBidder;        
        uint tokenId = auction.tokenId;
        bool isFirstAuction = auction.isFirstAuction;
        address tokenCustodian = auctionToken.tokenCustodian(tokenId);
        if (winner == address(0)) {
            auctionToken.transferFrom(address(this), owner, tokenId);
            emit RescueAuctionToken(owner, auctionId, tokenId, true);
        } else if (auction.auctionType != AuctionType.NonCustodianKYC || (auction.auctionType == AuctionType.NonCustodianKYC && auction.isWithdrawn && providedKYCForNonCustodian[auctionId])) {
            auctionToken.transferFrom(address(this), winner, tokenId);
            
            uint stakeAmount = auction.topBid;

            uint bidFinalAmount;
            uint successFee;
            uint successAuctionFeePercentage = tokenAuctionParams[tokenId].successAuctionFeePercentage;
            if (successAuctionFeePercentage != 0 && !isFirstAuction) {
                successFee = stakeAmount * successAuctionFeePercentage / 1e20;
                require(stakeAmount > successFee, "NFTAuction: successFee is greater than stakeAmount");
                bidFinalAmount = stakeAmount - successFee;
                if (!isCustodial)
                    purchaseToken.safeTransfer(tokenCustodian, successFee);
            } else {
                bidFinalAmount = stakeAmount;
            }

            if (!isFirstAuction) {
                (address author, uint royaltyAmount) = IERC2981(address(auctionToken)).royaltyInfo(tokenId, stakeAmount);
                if (royaltyAmount > 0 && royaltyAmount < bidFinalAmount) {
                    if (!isCustodial) purchaseToken.safeTransfer(author, royaltyAmount);
                    bidFinalAmount -= royaltyAmount;
                }
            }

            address finalBidReceiver = isFirstAuction ? tokenCustodian : auction.owner;
            if (!isCustodial) {
                purchaseToken.safeTransfer(finalBidReceiver, bidFinalAmount);
                
                _totalSupply -= stakeAmount;
                _balances[winner] -= stakeAmount;
                userStakes[winner][auctionId].isWithdrawn = true;
            }
            auction.isEnded = true;

            emit AuctionTokenWithdraw(winner, finalBidReceiver, bidFinalAmount, successFee, tokenId, auctionId);
        } else {
            emit AuctionProcessingKYC(winner, auction.owner, auction.topBid, tokenId, auctionId);
        }
        auction.isWithdrawn = true;
    }

    function endKYCAuction(uint auctionId, bool kycResult) external onlyCustodianAdmin {
        require(auctionId <= lastAuctionId, "NFTAuction: No such auction Id");
        require(auctions[auctionId].auctionType == AuctionType.NonCustodianKYC, "NFTAuction: Not a non-custodian KYC auction");
        require(auctions[auctionId].isWithdrawn && !auctions[auctionId].isEnded, "NFTAuction: Already ended or processSuccesfullAuction not used yet");
        
        providedKYCForNonCustodian[auctionId] = kycResult;
        if (!kycResult) {
            auctionToken.transferFrom(address(this), auctions[auctionId].owner, auctions[auctionId].tokenId);
            uint stakeAmount = auctions[auctionId].topBid;
            address winner = auctions[auctionId].topBidder; 

            purchaseToken.safeTransfer(custodianAdmin, stakeAmount);
            _totalSupply -= stakeAmount;
            _balances[winner] -= stakeAmount;
            userStakes[winner][auctionId].isWithdrawn = true;
            auctions[auctionId].isEnded = true;
        }
        else processSuccesfullAuction(auctionId);
    }

    function startNewAuctions(uint[] memory tokenIds, uint[] memory startBidAmounts, AuctionType[] memory auctionTypes, string[] memory descriptions) external { 
        require(tokenIds.length == startBidAmounts.length, "NFTAuction: Wrong lengths");
        require(tokenIds.length == auctionTypes.length, "NFTAuction: Wrong lengths");
        require(tokenIds.length == descriptions.length, "NFTAuction: Wrong lengths");
        for (uint i; i < tokenIds.length; i++) {
            startNewAuction(tokenIds[i], startBidAmounts[i], descriptions[i], auctionTypes[i]);
        }
    }

    function startNewAuction(uint tokenId, uint startBidAmount, uint roundDuration, uint successAuctionFeePercentage, string memory description, AuctionType auctionType) onlyOwner public {
        _updateTokenAuctionParams(tokenId, roundDuration, successAuctionFeePercentage, auctionType);
        startNewAuction(tokenId, startBidAmount, description, auctionType);
    }

    function startNewAuction(uint tokenId, uint startBidAmount, string memory description, AuctionType auctionType) public {
        bool isFirstAuction = tokenLastAuctionId[tokenId] == 0;
        require(isFirstAuction || tokenAuctionParams[tokenId].auctionType == auctionType, "NFTAuction: subsequent auctions for token should have same custodial setting");

        auctionToken.transferFrom(msg.sender, address(this), tokenId);
        if(startBidAmount < minAuctionStartPrice) startBidAmount = minAuctionStartPrice;

        uint auctionId = ++lastAuctionId;
        tokenLastAuctionId[tokenId] = auctionId;
        uint collectionId = auctionToken.tokenToCollection(tokenId);
        bool isDigitalObject = auctionToken.collection(collectionId).isDigitalObject; 

        tokenAuctionParams[tokenId].auctionType == auctionType;

        auctions[auctionId].tokenId = tokenId;
        auctions[auctionId].description = description;
        auctions[auctionId].topBid = startBidAmount;
        auctions[auctionId].owner = msg.sender;
        auctions[auctionId].auctionType = auctionType;
        auctions[auctionId].isFirstAuction = isFirstAuction;
        if (isDigitalObject)
            auctions[auctionId].isDigitalObject = true; 

        emit NewAuction(auctionId, collectionId, tokenId, auctionType, isDigitalObject, isFirstAuction);
    }

    function rescueUnbiddenTokenByTokenId(uint tokenId) external {
        uint auctionId = tokenLastAuctionId[tokenId];
        rescueUnbiddenToken(auctionId);
    }

    function rescueUnbiddenToken(uint auctionId) public { 
        Auction storage auction = auctions[auctionId];
        require(auction.auctionEnd == 0, "NFTAuction: Token is already bidden");
        require(!auction.canceled, "NFTAuction: Token is already rescued");
        require(auction.owner == msg.sender, "NFTAuction: Not token owner");
        auction.canceled = true;
        auctionToken.transferFrom(address(this), msg.sender, auction.tokenId);
        emit RescueAuctionToken(msg.sender, auctionId, auction.tokenId, false);
    }

    function _stake(uint auctionId, uint amount, address user) internal virtual nonReentrant {
        require(auctionId <= lastAuctionId, "NFTAuction: No such auction Id");
        Auction storage auction = auctions[auctionId];
        require(!auction.canceled, "NFTAuction: Auction is canceled");
        if (auction.auctionEnd == 0) _initAuction(auctionId);
        else require(auction.auctionEnd > block.timestamp, "NFTAuction: Round is finished");

        uint nextMinBid;
        if (auction.topBidder != address(0)) {
            nextMinBid = auction.topBid * nextBidStepPercentage / 1e20;
        } else {
            nextMinBid = auction.topBid;
        }

        uint totalAmount = amount;

        uint previousStakeForCurrentAuction = userStakes[user][auctionId].stakeAmount;
        if (previousStakeForCurrentAuction == 0) {
            _userAuctions[user].push(auctionId);
            userStakes[user][auctionId].lockTime = auction.auctionEnd;
            if (auction.auctionType == AuctionType.Custodian) userStakes[user][auctionId].isCustodian = true;
        } else {
            totalAmount += previousStakeForCurrentAuction;
        }
        require(totalAmount >= nextMinBid, "NFTAuction: Not enough amount for a bid");
        
        userStakes[user][auctionId].stakeAmount = totalAmount;

        if(auction.auctionType == AuctionType.Custodian) {
            address tokenCustodian = auctionToken.tokenCustodian(auction.tokenId);
            purchaseToken.safeTransferFrom(msg.sender, tokenCustodian, amount);
            _userCustodianStakes[user].push(auctionId);
        } else {
            purchaseToken.safeTransferFrom(msg.sender, address(this), amount);
            _balances[user] += amount;
            _totalSupply += amount;
        }
        
        auction.topBid = totalAmount;
        auction.topBidder = user;
        auction.allBids += amount;
        emit NewTopBid(auctionId, auction.tokenId, totalAmount, user);  
        emit Staked(user, amount, auctionId, auction.tokenId);
    }

    function _withdraw(uint auctionId) internal virtual nonReentrant {
        require(auctions[auctionId].auctionType != AuctionType.Custodian, "NFTAuction: Custodian return stakes on custodial auctions");
        address user = msg.sender;
        require(!userStakes[user][auctionId].isWithdrawn, "NFTAuction: Already withdrawn");
        require(userStakes[user][auctionId].lockTime < block.timestamp, "NFTAuction: Locked");
        require(auctions[auctionId].isWithdrawn, "NFTAuction: processSuccesfullAuction not executed yet");
        require(auctions[auctionId].topBidder != user, "NFTAuction: Winner can withdraw using processSuccesfullAuction");

        uint amount = userStakes[user][auctionId].stakeAmount;
        require(amount > 0, "NFTAuction: Stake amount should be more then 0");
        purchaseToken.safeTransfer(user, amount);

        _totalSupply -= amount;
        _balances[user] -= amount;
        userStakes[user][auctionId].isWithdrawn = true;
        emit Withdraw(user, amount);
    }

    function _initAuction(uint auctionId) internal {
        uint auctionRoundDuration = tokenAuctionParams[auctions[auctionId].tokenId].auctionRoundDuration;
        if (auctionRoundDuration == 0)
            auctionRoundDuration = defaultAuctionDuration;
        uint auctionEnd = block.timestamp + auctionRoundDuration;
        auctions[auctionId].auctionEnd = auctionEnd;
        emit AuctionInited(auctionId, auctionEnd, auctions[auctionId].tokenId);
    }



    /* === CUSTODIAN ACTIONS === */

    function updateCustodianAdmin(address newAdmin) external onlyOwnerOrCustodianAdmin {
        require(newAdmin != address(0), "NFTAuction: Zero address");
        emit UpdateCustodianAdmin(custodianAdmin, newAdmin);
        custodianAdmin = newAdmin;
    }


    /* === OWNER ACTIONS === */

    function approveAuctionForCustodian(uint auctionId, bool isApproved) external onlyOwner { 
        require(auctionId <= lastAuctionId, "NFTAuction: No such auction Id");
        require(auctions[auctionId].auctionType == AuctionType.Custodian, "NFTAuction: Not a custodial auction");
        approvedAuctionsForCustodian[auctionId] = isApproved;
        emit ApproveAuctionForCustodian(auctionId, isApproved);
    }

    function updateMinAuctionStartPrice(uint newMinAuctionStartPrice) external onlyOwner {
        require(newMinAuctionStartPrice > 0, "NFTAuction: New min stake amount must be greater than 0");
        minAuctionStartPrice = newMinAuctionStartPrice;
        emit UpdateMinAuctionStartPrice(newMinAuctionStartPrice);
    }

    function updateDefaultAuctionDuration(uint newDefaultAuctionDuration) external onlyOwner {
        require(newDefaultAuctionDuration >= MIN_AUCTION_DURATION, "NFTAuction: Auction duration is too short");
        defaultAuctionDuration = newDefaultAuctionDuration;
        emit UpdateDefaultAuctionDuration(newDefaultAuctionDuration);
    }

    function updateTokenAuctionParams(uint tokenId, uint auctionRoundDuration, uint successAuctionFeePercentage, AuctionType auctionType) external onlyOwner {
        _updateTokenAuctionParams(tokenId, auctionRoundDuration, successAuctionFeePercentage, auctionType);
    }

    function _updateTokenAuctionParams(uint tokenId, uint auctionRoundDuration, uint successAuctionFeePercentage, AuctionType auctionType) private {
        require(auctionRoundDuration >= MIN_AUCTION_DURATION, "NFTAuction: Auction duration is too short");
        if (successAuctionFeePercentage > 0) { //successAuctionFeePercentage can be a zero value
            require(successAuctionFeePercentage < 1e20, "NFTAuction: successAuctionFeePercentage must be lower than 1e20");
        }
        bool isFirstAuction = tokenLastAuctionId[tokenId] == 0;
        if (!isFirstAuction && auctionType != AuctionType.Custodian && auctionType != tokenAuctionParams[tokenId].auctionType) {
            require(tokenAuctionParams[tokenId].auctionType != AuctionType.Custodian, "NFTAuction: token auctions can be only custodian");
            require(tokenAuctionParams[tokenId].prevAuctionType == AuctionType.Custodian, "NFTAuction: token auction type cannot be changed to this type");
        }
        tokenAuctionParams[tokenId].auctionRoundDuration = auctionRoundDuration;
        tokenAuctionParams[tokenId].successAuctionFeePercentage = successAuctionFeePercentage;
        if (tokenAuctionParams[tokenId].prevAuctionType != auctionType)
            tokenAuctionParams[tokenId].prevAuctionType = tokenAuctionParams[tokenId].auctionType;
        tokenAuctionParams[tokenId].auctionType = auctionType;
        emit UpdateTokenAuctionParams(tokenId, auctionRoundDuration, successAuctionFeePercentage, tokenAuctionParams[tokenId].prevAuctionType, auctionType);
    }
    
    function updateNextBidStepPercentage(uint newNextBidStepPercentage) external onlyOwner {
        require(newNextBidStepPercentage >= 1e20);
        nextBidStepPercentage = newNextBidStepPercentage;
        emit UpdateNextBidStepPercentage(newNextBidStepPercentage);
    }

    function rescue(address to, address tokenAddress, uint amount) external onlyOwner {
        require(to != address(0), "NFTAuction: Cannot rescue to the zero address");
        require(amount > 0, "NFTAuction: Cannot rescue 0");
        
        IERC20(tokenAddress).safeTransfer(to, amount);
        emit RescueToken(to, address(tokenAddress), amount);
    }

}