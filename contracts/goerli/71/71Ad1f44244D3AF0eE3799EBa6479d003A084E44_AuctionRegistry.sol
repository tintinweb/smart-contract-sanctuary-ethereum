// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "../libraries/AuctionUtility.sol";

error AuctionRegistry_RestrictedOwnerAccess();
error AuctionRegistry_RestrictedContractFactoryAccess();
error AuctionRegistry__RestrictedManagerAccess();
error AuctionRegistry__AuctionOngoing();

error Auction_RestrictedSellerAccess();
error Auction_NotInPendingPaymentState();
error Auction_RestrictedWinnerPaymentAccess();
error Auction_SelfBiddingIsNotAllowed();
error Auction_NoProceeds();
error Auction_UnauthorizedAccess();

error ContractFactory__RestrictedManagerAccess();
error ContractFactory_RestrictedOwnerAccess();

/*
1. Seller can register a new vehicle by minting a vehicle NFT
2. Seller can host an auction for vehicles NFT that they own by creating a new BiddingHost contract
3. BiddingHost can call HAP to emit events 
    to record each bid, extend bid end time, end bid, and record pending payments
4. Chainlink Keeper is needed for automated end bid + refund deposit, lock contract + send deposit to HAP owner
5. Chainlink Oracle is needed to fetch the latest usd -> eth rate
*/
contract ContractFactory {
    address public immutable owner;
    address public auctionManagerAddress;
    address public auctionRegistryAddress;
    AuctionManager private auctionManager;
    AuctionRegistry private auctionRegistry;

    constructor(address _auctionRegistryAddress) {
        owner = msg.sender;
        auctionRegistryAddress = _auctionRegistryAddress;
        auctionRegistry = AuctionRegistry(_auctionRegistryAddress);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert ContractFactory_RestrictedOwnerAccess();
        }
        _;
    }

    modifier onlyAuctionManager() {
        if (msg.sender != auctionManagerAddress) {
            revert ContractFactory__RestrictedManagerAccess();
        }
        _;
    }

    function getContractType() public pure returns (Constants.ContractType) {
        return Constants.ContractType.CONTRACT_FACTORY;
    }

    function setAuctionManagerAddress(address _auctionManagerAddress)
        public
        onlyOwner
    {
        auctionManagerAddress = _auctionManagerAddress;
        auctionManager = AuctionManager(auctionManagerAddress);
    }

    function createAuction(
        address _seller,
        address _nftAddress,
        uint256 _tokenId,
        address _eventEmitterAddress,
        address _auctionKeeperAddress
    ) public onlyAuctionManager {
        // call AuctionRegistry, register auction
        // create Auction contract
        Auction newAuctionInstance = new Auction(
            owner,
            _seller,
            auctionManagerAddress,
            _eventEmitterAddress,
            _auctionKeeperAddress,
            _nftAddress,
            _tokenId
        );

        auctionRegistry.registerAuction(
            _nftAddress,
            _tokenId,
            address(newAuctionInstance)
        );
    }
}

contract EventEmitter {
    modifier onlyAuction(address _senderAddress) {
        require(
            (AuctionUtility.getContractType(_senderAddress) ==
                Constants.ContractType.AUCTION),
            "eventEmit can only be called by Auction"
        );
        _;
    }

    event AuctionRegistered(
        address indexed auction,
        address seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 registerTime
    );

    event AuctionStartedBidding(
        address indexed auction,
        address seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 depositWei,
        uint256 bidStartTime,
        uint256 bidEndTime,
        uint256 startingBid
    );

    event AuctionVerifyingWinner(
        address indexed auction,
        address seller,
        address nftAddress,
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid,
        uint256 platformCharge,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionPendingPayment(
        address indexed auction,
        address seller,
        address nftAddress,
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionAuditResult(
        address indexed auction,
        address seller,
        address nftAddress,
        uint256 indexed tokenId,
        address indexed winner,
        uint256 winningBid,
        uint256 time,
        bool pass
    );

    // if winner did not pay, in the event listener, change the deposit placed event record (boolean winnerWithdrawal to false)
    event AuctionClosed(
        address indexed auction,
        address seller,
        address nftAddress,
        uint256 indexed tokenId,
        uint256 closeTime,
        address winner,
        uint256 winningBid,
        Constants.AuctionEndState indexed endState
    );

    event AuctionDepositPlaced(
        address indexed auction,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address bidder,
        uint256 depositAmount,
        uint256 depositTime
    );

    event AuctionDepositRetrieved(
        address indexed auction,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address bidder,
        uint256 retrieveAmount,
        uint256 retrievalTime
    );

    event AuctionBidPlaced(
        address indexed auction,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address bidder,
        uint256 bidAmount,
        uint256 bidTime
    );

    event AuctionFullSettlementPaid(
        address indexed auction,
        address nftAddress,
        uint256 tokenId,
        address indexed winner,
        address seller,
        uint256 indexed paidAmount,
        uint256 paidTime
    );

    event SellerEarningsRetrieved(
        address indexed auction,
        address nftAddress,
        uint256 tokenId,
        address indexed seller,
        uint256 indexed retrieveAmount,
        uint256 retrievalTime
    );

    event WinnerPaymentRefunded(
        address indexed auction,
        address nftAddress,
        uint256 tokenId,
        address winner,
        uint256 indexed refundAmount,
        uint256 retrievalTime
    );

    event PlatformEarnings(
        address indexed platformOwner,
        address payer,
        address indexed auction,
        Constants.PlatformEarnings earningType,
        uint256 time
    );

    event NftTransferred(
        address indexed auction,
        address indexed nftAddress,
        uint256 indexed tokenId,
        address from,
        address to
    );

    function emitAuctionRegistered(
        address _auction,
        address _seller,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _registerTime
    ) public {
        emit AuctionRegistered(
            _auction,
            _seller,
            _nftAddress,
            _tokenId,
            _registerTime
        );
    }

    function emitAuctionStartedBidding(
        address _auction,
        address _seller,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _depositWei,
        uint256 _startTime,
        uint256 _bidEndTime,
        uint256 _startingBid
    ) public onlyAuction(msg.sender) {
        emit AuctionStartedBidding(
            _auction,
            _seller,
            _nftAddress,
            _tokenId,
            _depositWei,
            _startTime,
            _bidEndTime,
            _startingBid
        );
    }

    function emitAuctionVerifyingWinner(
        address _auction,
        address _seller,
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        uint256 _winningBid,
        uint256 _platformCharge,
        uint256 _startTime,
        uint256 _expiryTime
    ) public onlyAuction(msg.sender) {
        emit AuctionVerifyingWinner(
            _auction,
            _seller,
            _nftAddress,
            _tokenId,
            _winner,
            _winningBid,
            _platformCharge,
            _startTime,
            _expiryTime
        );
    }

    function emitAuctionPendingPayment(
        address _auction,
        address _seller,
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        uint256 _winningBid,
        uint256 _startTime,
        uint256 _expiryTime
    ) public onlyAuction(msg.sender) {
        emit AuctionPendingPayment(
            _auction,
            _seller,
            _nftAddress,
            _tokenId,
            _winner,
            _winningBid,
            _startTime,
            _expiryTime
        );
    }

    function emitAuctionAuditResult(
        address _auction,
        address _seller,
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        uint256 _winningBid,
        uint256 _time,
        bool _pass
    ) public onlyAuction(msg.sender) {
        emit AuctionAuditResult(
            _auction,
            _seller,
            _nftAddress,
            _tokenId,
            _winner,
            _winningBid,
            _time,
            _pass
        );
    }

    function emitAuctionClosed(
        address _auction,
        address _seller,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _closeTime,
        address _winner,
        uint256 _winningBid,
        Constants.AuctionEndState _endState
    ) public onlyAuction(msg.sender) {
        emit AuctionClosed(
            _auction,
            _seller,
            _nftAddress,
            _tokenId,
            _closeTime,
            _winner,
            _winningBid,
            _endState
        );
    }

    function emitAuctionDepositPlaced(
        address _auction,
        address _nftAddress,
        uint256 _tokenId,
        address _bidder,
        uint256 _depositAmount,
        uint256 _depositTime
    ) public onlyAuction(msg.sender) {
        emit AuctionDepositPlaced(
            _auction,
            _nftAddress,
            _tokenId,
            _bidder,
            _depositAmount,
            _depositTime
        );
    }

    function emitAuctionBidPlaced(
        address _auction,
        address _nftAddress,
        uint256 _tokenId,
        address _bidder,
        uint256 _bidAmount,
        uint256 _bidTime
    ) public onlyAuction(msg.sender) {
        emit AuctionBidPlaced(
            _auction,
            _nftAddress,
            _tokenId,
            _bidder,
            _bidAmount,
            _bidTime
        );
    }

    function emitAuctionFullSettlementPaid(
        address _auction,
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        address _seller,
        uint256 _paidAmount,
        uint256 _paidTime
    ) public onlyAuction(msg.sender) {
        emit AuctionFullSettlementPaid(
            _auction,
            _nftAddress,
            _tokenId,
            _winner,
            _seller,
            _paidAmount,
            _paidTime
        );
    }

    function emitAuctionDepositRetrieved(
        address _auction,
        address _nftAddress,
        uint256 _tokenId,
        address _bidder,
        uint256 _retrieveAmount,
        uint256 _retrievalTime
    ) public onlyAuction(msg.sender) {
        emit AuctionDepositRetrieved(
            _auction,
            _nftAddress,
            _tokenId,
            _bidder,
            _retrieveAmount,
            _retrievalTime
        );
    }

    function emitSellerEarningsRetrieved(
        address _auction,
        address _nftAddress,
        uint256 _tokenId,
        address _seller,
        uint256 _retrieveAmount,
        uint256 _retrievalTime
    ) public onlyAuction(msg.sender) {
        emit SellerEarningsRetrieved(
            _auction,
            _nftAddress,
            _tokenId,
            _seller,
            _retrieveAmount,
            _retrievalTime
        );
    }

    function emitWinnerPaymentRefunded(
        address _auction,
        address _nftAddress,
        uint256 _tokenId,
        address _winner,
        uint256 _refundAmount,
        uint256 _retrievalTime
    ) public onlyAuction(msg.sender) {
        emit WinnerPaymentRefunded(
            _auction,
            _nftAddress,
            _tokenId,
            _winner,
            _refundAmount,
            _retrievalTime
        );
    }

    function emitPlatformEarnings(
        address _platformOwner,
        address _payer,
        address _auction,
        Constants.PlatformEarnings _earningType,
        uint256 _time
    ) public onlyAuction(msg.sender) {
        emit PlatformEarnings(
            _platformOwner,
            _payer,
            _auction,
            _earningType,
            _time
        );
    }

    function emitNftTransferred(
        address _auction,
        address _nftAddress,
        uint256 _tokenId,
        address _from,
        address _to
    ) public onlyAuction(msg.sender) {
        emit NftTransferred(_auction, _nftAddress, _tokenId, _from, _to);
    }
}

contract AuctionRegistry {
    address public immutable owner;
    address public auctionManagerAddress;
    AuctionManager private auctionManager;

    mapping(address => mapping(uint256 => address)) public auctionListings;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert AuctionRegistry_RestrictedOwnerAccess();
        }
        _;
    }

    modifier onlyAuctionManager() {
        if (msg.sender != auctionManagerAddress) {
            revert AuctionRegistry__RestrictedManagerAccess();
        }
        _;
    }

    modifier onlyContractFactory() {
        if (
            AuctionUtility.getContractType(msg.sender) !=
            Constants.ContractType.CONTRACT_FACTORY
        ) {
            revert AuctionRegistry_RestrictedContractFactoryAccess();
        }
        _;
    }

    modifier onlyAuctionInactive(
        address _nftAddress,
        uint256 _tokenId,
        address _auctionAddress
    ) {
        // if event still not ended, unable to create a same auction for the NFT
        // create interface of Auction.sol
        Auction auction = Auction(_auctionAddress);
        // call Auction.getEventState();
        require(
            auctionListings[_nftAddress][_tokenId] == address(0x0) ||
                (!auction.inClosedState() && !auction.inRegisteredState()),
            "Duplicate auction for the vehicle is active!"
        );
        _;
    }

    function getContractType() public pure returns (Constants.ContractType) {
        return Constants.ContractType.AUCTION_REGISTRY;
    }

    function setAuctionManagerAddress(address _auctionManagerAddress)
        public
        onlyOwner
    {
        auctionManagerAddress = _auctionManagerAddress;
        auctionManager = AuctionManager(auctionManagerAddress);
    }

    function registerAuction(
        address _nftAddress,
        uint256 _tokenId,
        address _auctionAddress
    )
        public
        onlyContractFactory
        onlyAuctionInactive(_nftAddress, _tokenId, _auctionAddress)
    {
        // if NFT id not in map, store the NFT -> address mapping
        // else if NFT id already exist, update the mapping
        auctionListings[_nftAddress][_tokenId] = _auctionAddress; // this line does it all
    }

    // TODO: registerTechnician
}

contract AuctionKeeper is KeeperCompatibleInterface {
    address public immutable owner;
    address public auctionManagerAddress;
    AuctionManager private auctionManager;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert AuctionRegistry_RestrictedOwnerAccess();
        }
        _;
    }

    function getContractType() public pure returns (Constants.ContractType) {
        return Constants.ContractType.AUCTION_KEEPER;
    }

    function setAuctionManagerAddress(address _auctionManagerAddress)
        public
        onlyOwner
    {
        auctionManagerAddress = _auctionManagerAddress;
        auctionManager = AuctionManager(auctionManagerAddress);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (keccak256(checkData) == keccak256(hex"01")) {
            address[] memory biddingAuctions = auctionManager
                .getBiddingAuctions();
            upkeepNeeded = false;
            performData = checkData;
            for (uint i = 0; i < biddingAuctions.length; i++) {
                if (Auction(biddingAuctions[i]).getBidTimeLeft() == 0) {
                    upkeepNeeded = true;
                }
            }
            return (upkeepNeeded, performData);
        }

        if (keccak256(checkData) == keccak256(hex"02")) {
            address[] memory verifyWinnerAuctions = auctionManager
                .getVerifyWinnerAuctions();
            upkeepNeeded = false;
            performData = checkData;
            for (uint i = 0; i < verifyWinnerAuctions.length; i++) {
                if (Auction(verifyWinnerAuctions[i]).getVerifyTimeLeft() == 0) {
                    upkeepNeeded = true;
                }
            }
            return (upkeepNeeded, performData);
        }

        if (keccak256(checkData) == keccak256(hex"03")) {
            address[] memory pendingPaymentAuctions = auctionManager
                .getPendingPaymentAuctions();
            upkeepNeeded = false;
            performData = checkData;
            for (uint i = 0; i < pendingPaymentAuctions.length; i++) {
                if (
                    Auction(pendingPaymentAuctions[i]).getPaymentTimeLeft() == 0
                ) {
                    upkeepNeeded = true;
                }
            }
            return (upkeepNeeded, performData);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        address[] memory biddingAuctions = auctionManager.getBiddingAuctions();
        if (keccak256(performData) == keccak256(hex"01")) {
            for (uint i = 0; i < biddingAuctions.length; i++) {
                if (Auction(biddingAuctions[i]).getBidTimeLeft() == 0) {
                    Auction(biddingAuctions[i]).endBidding();
                }
            }
        }

        if (keccak256(performData) == keccak256(hex"02")) {
            address[] memory verifyWinnerAuctions = auctionManager
                .getVerifyWinnerAuctions();
            for (uint i = 0; i < verifyWinnerAuctions.length; i++) {
                if (Auction(verifyWinnerAuctions[i]).getVerifyTimeLeft() == 0) {
                    Auction(verifyWinnerAuctions[i]).verifyWinner(false);
                }
            }
        }

        if (keccak256(performData) == keccak256(hex"03")) {
            address[] memory pendingPaymentAuctions = auctionManager
                .getPendingPaymentAuctions();
            for (uint i = 0; i < pendingPaymentAuctions.length; i++) {
                if (
                    Auction(pendingPaymentAuctions[i]).getPaymentTimeLeft() == 0
                ) {
                    Auction(pendingPaymentAuctions[i]).closeAuction(
                        Constants.AuctionEndState.PAYMENT_OVERDUE
                    );
                }
            }
        }
    }
}

contract AuctionManager {
    address public immutable owner;
    address[] public biddingAuctions;
    address[] public verifyWinnerAuctions;
    address[] public pendingPaymentAuctions;
    address auctionRegistryAddress;
    address eventEmitterAddress;
    address auctionKeeperAddress;
    address contractFactoryAddress;

    constructor(
        address _auctionRegistryAddress,
        address _eventEmitterAddress,
        address _auctionKeeperAddress,
        address _contractFactoryAddress
    ) {
        owner = msg.sender;
        auctionRegistryAddress = _auctionRegistryAddress;
        eventEmitterAddress = _eventEmitterAddress;
        auctionKeeperAddress = _auctionKeeperAddress;
        contractFactoryAddress = _contractFactoryAddress;
    }

    function createAuction(address _nftAddress, uint256 _tokenId) external {
        ContractFactory contractFactory = ContractFactory(
            contractFactoryAddress
        );
        contractFactory.createAuction(
            msg.sender,
            _nftAddress,
            _tokenId,
            eventEmitterAddress,
            auctionKeeperAddress
        );
    }

    function getBiddingAuctions() public view returns (address[] memory) {
        return biddingAuctions;
    }

    function getVerifyWinnerAuctions() public view returns (address[] memory) {
        return verifyWinnerAuctions;
    }

    function getPendingPaymentAuctions()
        public
        view
        returns (address[] memory)
    {
        return pendingPaymentAuctions;
    }

    function getContractType() public pure returns (Constants.ContractType) {
        return Constants.ContractType.AUCTION_MANAGER;
    }

    function addBiddingAuction(address _auctionAddress) public {
        require(
            AuctionUtility.getContractType(msg.sender) ==
                Constants.ContractType.AUCTION
        );
        // to be called when bidding starts (by Auction.startAuction())
        biddingAuctions.push(address(_auctionAddress));
    }

    function removeBiddingAuction(address _auctionAddress) public {
        require(
            AuctionUtility.getContractType(msg.sender) ==
                Constants.ContractType.AUCTION
        );
        // to be called when bidding end time reached (by keepers)
        uint auctionIndex;
        int searchResult = searchBiddingAuction(_auctionAddress);
        if (searchResult >= 0) {
            auctionIndex = uint(searchResult);
            for (uint i = auctionIndex; i < biddingAuctions.length - 1; i++) {
                biddingAuctions[i] = biddingAuctions[i + 1];
            }
            biddingAuctions.pop();
        }
    }

    function addVerifyWinnerAuction(address _auctionAddress) public {
        require(
            AuctionUtility.getContractType(msg.sender) ==
                Constants.ContractType.AUCTION
        );
        //  to be called when bidding end time reached (by keepers)
        verifyWinnerAuctions.push(address(_auctionAddress));
    }

    function removeVerifyWinnerAuction(address _auctionAddress) public {
        require(
            AuctionUtility.getContractType(msg.sender) ==
                Constants.ContractType.AUCTION
        );
        // to be called when winner paid (by Auction.payFullSettlement()) / payment expiry time reached (by keepers)
        uint auctionIndex;
        int searchResult = searchVerifyWinnerAuction(_auctionAddress);
        if (searchResult >= 0) {
            auctionIndex = uint(searchResult);
            for (
                uint i = auctionIndex;
                i < verifyWinnerAuctions.length - 1;
                i++
            ) {
                verifyWinnerAuctions[i] = verifyWinnerAuctions[i + 1];
            }
            verifyWinnerAuctions.pop();
        }
    }

    function addPendingPaymentAuction(address _auctionAddress) public {
        require(
            AuctionUtility.getContractType(msg.sender) ==
                Constants.ContractType.AUCTION
        );
        // to be called when bidding end time reached (by keepers)
        pendingPaymentAuctions.push(address(_auctionAddress));
    }

    function removePendingPaymentAuction(address _auctionAddress) public {
        require(
            AuctionUtility.getContractType(msg.sender) ==
                Constants.ContractType.AUCTION
        );
        // to be called when winner paid (by Auction.payFullSettlement()) / payment expiry time reached (by keepers)
        uint auctionIndex;
        int searchResult = searchPendingPaymentAuction(_auctionAddress);
        if (searchResult >= 0) {
            auctionIndex = uint(searchResult);
            for (
                uint i = auctionIndex;
                i < pendingPaymentAuctions.length - 1;
                i++
            ) {
                pendingPaymentAuctions[i] = pendingPaymentAuctions[i + 1];
            }
            pendingPaymentAuctions.pop();
        }
    }

    function searchBiddingAuction(address _auctionAddress)
        public
        view
        returns (int)
    {
        for (uint i = 0; i < uint(biddingAuctions.length); i++) {
            if (biddingAuctions[i] == _auctionAddress) {
                return int(i);
            }
        }
        return -1;
    }

    function searchVerifyWinnerAuction(address _auctionAddress)
        public
        view
        returns (int)
    {
        for (uint i = 0; i < uint(verifyWinnerAuctions.length); i++) {
            if (verifyWinnerAuctions[i] == _auctionAddress) {
                return int(i);
            }
        }
        return -1;
    }

    function searchPendingPaymentAuction(address _auctionAddress)
        public
        view
        returns (int)
    {
        for (uint i = 0; i < uint(pendingPaymentAuctions.length); i++) {
            if (pendingPaymentAuctions[i] == _auctionAddress) {
                return int(i);
            }
        }
        return -1;
    }
}

/*
1. Seller can start the auction directly or choose to send the vehicle for verification
2. Seller must set the duration for the auction and the starting price for the auction
3. Bidder can join the auction by paying a deposit of 500$, the deposit only has to be paid once
4. The deposit can be reclaimed by bidder after the auction ends,
    if the bidder lost the auction or 
    the bidder won the auction and settled the full payment of the vehicle
5. Bidder can bid for the vehicle provided that the new bid is higher than the current highest bid
6. Seller cannot bid on their own auction
7. When the highese bid is updated within 60 seconds of the ending time, 
    the duration of the auction will be reset to 3 minutes
8. The winner of the auction will be the bidder with the highest bid when the auction ends
9. The ownership of the auction will be transferred to the winner once the winner settled the payment
10. The payment must be exactly the amount of the winning bid
11. The payment must be made within 1 day(s) after the auction ends, 
    otherwise payment cannot be made and the NFT will not be transferred
12. If no one bid on the vehicle after the bidding time is up, the auctin will end with EndState.NO_BIDDER
*/
contract Auction {
    enum AuctionState {
        REGISTERED,
        BIDDING,
        VERIFYING_WINNER,
        PENDING_PAYMENT,
        PENDING_AUDIT,
        AUCTION_CLOSED
    }

    address payable public immutable platformOwner;
    address payable public immutable seller;
    address public nftAddress;
    uint256 public tokenId;
    address private auctionKeeperAddress;
    address private auctionManagerAddress;
    AuctionManager private auctionManager;
    EventEmitter private eventEmitter;
    uint128 public depositUSD = 1;
    uint256 public depositWei;
    uint256 public bidStartTime;
    uint256 public bidEndTime;
    uint128 public durationSec;
    uint256 public verify_startTime;
    uint256 public verify_expiryTime;
    uint256 public verify_duration = 1 days;
    uint256 public payment_startTime;
    uint256 public payment_expiryTime;
    uint256 public payment_duration = 1 days;
    uint256 public platformCharge;
    AuctionState public currAuctionState = AuctionState.REGISTERED;
    Constants.AuctionEndState public auctionEndState =
        Constants.AuctionEndState.NOT_ENDED;
    uint256 public highestBid;
    address public highestBidder;
    bool winnerPaid = false;
    mapping(address => uint128) private bidderToDeposits;
    mapping(address => uint256) private addressToProceeds;

    constructor(
        address _platformOwner,
        address _seller,
        address _auctionManagerAddress,
        address _eventEmitterAddress,
        address _auctionKeeperAddress,
        address _nftAddress,
        uint256 _tokenId
    ) {
        platformOwner = payable(_platformOwner);
        seller = payable(_seller);
        auctionManagerAddress = _auctionManagerAddress;
        auctionKeeperAddress = _auctionKeeperAddress;
        auctionManager = AuctionManager(_auctionManagerAddress);
        eventEmitter = EventEmitter(_eventEmitterAddress);
        nftAddress = _nftAddress;
        tokenId = _tokenId;
        currAuctionState = AuctionState.REGISTERED;
        depositWei = AuctionUtility.convertUsdToWei(depositUSD);
        eventEmitter.emitAuctionRegistered(
            address(this),
            _seller,
            _nftAddress,
            _tokenId,
            block.timestamp
        );
    }

    modifier onlySeller() {
        if (msg.sender != seller) {
            revert Auction_RestrictedSellerAccess();
        }
        _;
    }

    modifier onlySellerOrKeeper() {
        if ((msg.sender != seller) && (msg.sender != auctionKeeperAddress)) {
            revert Auction_RestrictedSellerAccess();
        }
        _;
    }

    modifier onlyWinnerPayment() {
        if (msg.sender != highestBidder && !(inPendingPaymentState())) {
            revert Auction_RestrictedWinnerPaymentAccess();
        }
        _;
    }

    modifier notForSeller() {
        if (msg.sender == seller) {
            revert Auction_SelfBiddingIsNotAllowed();
        }
        _;
    }

    modifier onlyAuthority(address _user) {
        (bool success, bytes memory data) = nftAddress.call(
            abi.encodeWithSignature("getAuthorityAddress()")
        );
        require(success, "Unable to determine the contract type!");
        address authority = abi.decode(data, (address));
        if (_user != authority) {
            revert Auction_UnauthorizedAccess();
        }
        _;
    }

    modifier onlyNftContract() {
        require(msg.sender == nftAddress);
        _;
    }

    function getContractType() public pure returns (Constants.ContractType) {
        return Constants.ContractType.AUCTION;
    }

    function inRegisteredState() public view returns (bool) {
        if (currAuctionState == AuctionState.REGISTERED) {
            return true;
        } else {
            return false;
        }
    }

    function inBiddingState() public view returns (bool) {
        if (currAuctionState == AuctionState.BIDDING) {
            return true;
        } else {
            return false;
        }
    }

    function inVerifyWinnerState() public view returns (bool) {
        if (currAuctionState == AuctionState.VERIFYING_WINNER) {
            return true;
        } else {
            return false;
        }
    }

    function inPendingPaymentState() public view returns (bool) {
        if (currAuctionState == AuctionState.PENDING_PAYMENT) {
            return true;
        } else {
            return false;
        }
    }

    function inPendingAuditState() public view returns (bool) {
        if (currAuctionState == AuctionState.PENDING_AUDIT) {
            return true;
        } else {
            return false;
        }
    }

    function inClosedState() public view returns (bool) {
        if (currAuctionState == AuctionState.AUCTION_CLOSED) {
            return true;
        } else {
            return false;
        }
    }

    function startAuction(uint128 _durationSec, uint128 _startingBid) external {
        require(inRegisteredState(), "Auction not in Registered state!");
        require(msg.sender == seller, "Requires owner!");
        require(_startingBid > 0, "Start bid < 0!");
        bidStartTime = block.timestamp;
        bidEndTime = bidStartTime + _durationSec;
        durationSec = _durationSec;
        highestBid = _startingBid;
        currAuctionState = AuctionState.BIDDING;

        eventEmitter.emitAuctionStartedBidding(
            address(this),
            seller,
            nftAddress,
            tokenId,
            depositWei,
            bidStartTime,
            bidEndTime,
            _startingBid
        );
        auctionManager.addBiddingAuction(address(this));
    }

    function endBidding() public {
        require(inBiddingState(), "Illegal state!");
        require(block.timestamp >= bidEndTime, "Bid time > 0!");
        if (highestBidder == address(0x0)) {
            closeAuction(Constants.AuctionEndState.NO_BIDDER);
        } else {
            currAuctionState = AuctionState.VERIFYING_WINNER;
            verify_startTime = block.timestamp;
            verify_expiryTime = verify_startTime + verify_duration;
            platformCharge = AuctionUtility.getPlatformCharge(highestBid);
            eventEmitter.emitAuctionVerifyingWinner(
                address(this),
                seller,
                nftAddress,
                tokenId,
                highestBidder,
                highestBid,
                platformCharge,
                verify_startTime,
                verify_expiryTime
            );
            auctionManager.addVerifyWinnerAuction(address(this));
        }
        auctionManager.removeBiddingAuction(address(this));
    }

    function verifyWinner(bool approveWinningBid) external onlySellerOrKeeper {
        // when timer's up, keepers call this function, verifyWinner(false)
        require(inVerifyWinnerState(), "Illegal state!");
        require(getVerifyTimeLeft() > 0, "Verify expired!");
        if (approveWinningBid) {
            payment_startTime = block.timestamp;
            payment_expiryTime = payment_startTime + payment_duration;
            currAuctionState = AuctionState.PENDING_PAYMENT;
            eventEmitter.emitAuctionPendingPayment(
                address(this),
                seller,
                nftAddress,
                tokenId,
                highestBidder,
                highestBid,
                payment_startTime,
                payment_expiryTime
            );
            auctionManager.removeVerifyWinnerAuction(address(this));
            auctionManager.addPendingPaymentAuction(address(this));
        } else {
            closeAuction(Constants.AuctionEndState.REJECTED_BY_SELLER);
            auctionManager.removeVerifyWinnerAuction(address(this));
        }
    }

    function closeAuction(Constants.AuctionEndState _endState) public {
        // can only be closed when the winner pays or the payment pending expired (chainlink keepers trigger)

        if (_endState == Constants.AuctionEndState.NO_BIDDER) {
            require(
                currAuctionState == AuctionState.BIDDING,
                "Illegal state transition!"
            );
            require(getBidTimeLeft() == 0, "auction still bidding!");
            require(
                highestBidder == address(0x0),
                "closeAuction.NO_BIDDER must not have winner!"
            );
            eventEmitter.emitPlatformEarnings(
                platformOwner,
                highestBidder,
                address(this),
                Constants.PlatformEarnings.NO_EARNINGS,
                block.timestamp
            );
        } else if (_endState == Constants.AuctionEndState.REJECTED_BY_SELLER) {
            require(
                currAuctionState == AuctionState.VERIFYING_WINNER,
                "illegal state transition!"
            );
            require(
                msg.sender == seller ||
                    AuctionUtility.getContractType(msg.sender) ==
                    Constants.ContractType.AUCTION_KEEPER,
                "closeAuction requires seller or keeper!"
            );
            eventEmitter.emitPlatformEarnings(
                platformOwner,
                highestBidder,
                address(this),
                Constants.PlatformEarnings.NO_EARNINGS,
                block.timestamp
            );
        } else if (_endState == Constants.AuctionEndState.PAYMENT_OVERDUE) {
            require(
                currAuctionState == AuctionState.PENDING_PAYMENT,
                "illegal state transition!"
            );
            require(
                msg.sender == seller ||
                    AuctionUtility.getContractType(msg.sender) ==
                    Constants.ContractType.AUCTION_KEEPER,
                "closeAuction requires seller or keeper!"
            );
            require(winnerPaid == false, "winner already paid!");
            // transfer winner's deposit to platform_owner
            uint128 depositBalance = bidderToDeposits[highestBidder];
            bidderToDeposits[msg.sender] = 0;
            (bool sent, ) = payable(msg.sender).call{value: depositBalance}("");
            require(sent, "ETH transfer failed!");
            eventEmitter.emitPlatformEarnings(
                platformOwner,
                highestBidder,
                address(this),
                Constants.PlatformEarnings.DEPOSIT,
                block.timestamp
            );
        } else if (
            (_endState == Constants.AuctionEndState.OWNERSHIP_TRANSFERRED) ||
            (_endState == Constants.AuctionEndState.AUDIT_REJECTED)
        ) {
            require(
                currAuctionState == AuctionState.PENDING_AUDIT,
                "illegal state transition!"
            );
            require(msg.sender == nftAddress, "only Auditor");
            if (_endState == Constants.AuctionEndState.AUDIT_REJECTED) {
                eventEmitter.emitPlatformEarnings(
                    platformOwner,
                    highestBidder,
                    address(this),
                    Constants.PlatformEarnings.NO_EARNINGS,
                    block.timestamp
                );
            }
            if (_endState == Constants.AuctionEndState.AUDIT_REJECTED) {
                eventEmitter.emitPlatformEarnings(
                    platformOwner,
                    highestBidder,
                    address(this),
                    Constants.PlatformEarnings.FULL_SETTLEMENT,
                    block.timestamp
                );
            }
        } else {
            // else if (_endState == Constants.AuctionEndState.CANCELED)
            require(
                currAuctionState == AuctionState.REGISTERED,
                "illegal state transition!"
            );
            require(msg.sender == seller, "only seller!");
            eventEmitter.emitPlatformEarnings(
                platformOwner,
                highestBidder,
                address(this),
                Constants.PlatformEarnings.NO_EARNINGS,
                block.timestamp
            );
        }

        currAuctionState = AuctionState.AUCTION_CLOSED;
        auctionEndState = _endState;
        eventEmitter.emitAuctionClosed(
            address(this),
            seller,
            nftAddress,
            tokenId,
            block.timestamp,
            highestBidder,
            highestBid,
            _endState
        );
        if ((_endState == Constants.AuctionEndState.PAYMENT_OVERDUE)) {
            auctionManager.removePendingPaymentAuction(address(this));
        }
    }

    function placeDeposit() external payable notForSeller {
        require(inBiddingState(), "Illegal state!");
        require((bidderToDeposits[msg.sender] == 0), "Account deposited!");
        require((msg.value >= depositWei), "Wrong deposit amount!");
        bidderToDeposits[msg.sender] += uint128(msg.value);
        eventEmitter.emitAuctionDepositPlaced(
            address(this),
            nftAddress,
            tokenId,
            msg.sender,
            msg.value,
            block.timestamp
        );
    }

    function placeBid(uint256 _bidAmount) external notForSeller {
        require(inBiddingState(), "Illegal state!");
        require(getBidTimeLeft() > 0, "Bid ongoing!");
        require(
            (bidderToDeposits[msg.sender] >= depositWei),
            "Deposit required for bidding!"
        );
        require(_bidAmount > highestBid, "Bid lower than highest bid!");

        highestBid = _bidAmount;
        highestBidder = msg.sender;
        eventEmitter.emitAuctionBidPlaced(
            address(this),
            nftAddress,
            tokenId,
            msg.sender,
            _bidAmount,
            block.timestamp
        );
    }

    function withdrawDeposit() external payable {
        require(
            ((msg.sender != highestBidder) ||
                (msg.sender == highestBidder && winnerPaid == true) ||
                (msg.sender == highestBidder && inClosedState())),
            "Cannot withdraw!"
        );
        // requires bidder to settle full payment for withdrawal (full payment only when the seller accepted the result)
        // requires bidder to not exceed the expiry date for full payment settlement
        // close the auction when the expiry date is reached
        uint128 depositBalance = bidderToDeposits[msg.sender];
        bidderToDeposits[msg.sender] = 0;
        (bool sent, ) = payable(msg.sender).call{value: depositBalance}("");
        require(sent, "ETH withdrawal failed!");
        eventEmitter.emitAuctionDepositRetrieved(
            address(this),
            nftAddress,
            tokenId,
            msg.sender,
            depositBalance,
            block.timestamp
        );
    }

    function payFullSettlement() external payable onlyWinnerPayment {
        require((inPendingPaymentState()), "Illegal state!");
        require(
            (getPaymentTimeLeft() > 0),
            "Payment window for full settlement closed!"
        );
        require(
            (msg.value == (highestBid + platformCharge)),
            "Payment value != (winning bid + platform charge)!"
        );
        require((!winnerPaid), "You have paid!");
        addressToProceeds[seller] = highestBid;
        addressToProceeds[platformOwner] = platformCharge;
        winnerPaid = true;
        auctionManager.removePendingPaymentAuction(address(this));
        eventEmitter.emitAuctionFullSettlementPaid(
            address(this),
            nftAddress,
            tokenId,
            msg.sender,
            seller,
            msg.value,
            block.timestamp
        );
        currAuctionState = AuctionState.PENDING_AUDIT;
    }

    function withdrawSellerEarnings() external onlySeller {
        require(
            (auctionEndState ==
                Constants.AuctionEndState.OWNERSHIP_TRANSFERRED),
            "Ownership not transferred!"
        );
        uint256 proceeds = addressToProceeds[seller];
        if (proceeds <= 0) {
            revert Auction_NoProceeds();
        }
        addressToProceeds[seller] = 0;
        (bool sent, ) = payable(seller).call{value: proceeds}("");
        require(sent, "ETH transfer failed");
        eventEmitter.emitSellerEarningsRetrieved(
            address(this),
            nftAddress,
            tokenId,
            msg.sender,
            proceeds,
            block.timestamp
        );
    }

    function refundFullSettlement() external {
        require(
            msg.sender == highestBidder,
            "Refund can only be made to payer!"
        );
        require(
            auctionEndState == Constants.AuctionEndState.AUDIT_REJECTED,
            "Inegligible for refund!"
        );
        uint256 proceeds = addressToProceeds[seller] +
            addressToProceeds[platformOwner];
        if (proceeds <= 0) {
            revert Auction_NoProceeds();
        }
        addressToProceeds[seller] = 0;
        addressToProceeds[platformOwner] = 0;
        (bool sent, ) = payable(highestBidder).call{value: (proceeds)}("");
        require(sent, "ETH transfer failed");
        eventEmitter.emitWinnerPaymentRefunded(
            address(this),
            nftAddress,
            tokenId,
            msg.sender,
            proceeds,
            block.timestamp
        );
    }

    function setAuditResult(bool _valid) external onlyNftContract {
        require(inPendingAuditState());
        if (_valid == true) {
            closeAuction(Constants.AuctionEndState.OWNERSHIP_TRANSFERRED);
            uint256 proceeds = addressToProceeds[platformOwner];
            addressToProceeds[platformOwner] = 0;
            (bool sent, ) = payable(platformOwner).call{value: proceeds}("");
            require(sent, "ETH transfer failed");
            eventEmitter.emitNftTransferred(
                address(this),
                nftAddress,
                tokenId,
                seller,
                highestBidder
            );
        } else {
            closeAuction(Constants.AuctionEndState.AUDIT_REJECTED);
        }
        eventEmitter.emitAuctionAuditResult(
            address(this),
            seller,
            nftAddress,
            tokenId,
            highestBidder,
            highestBid,
            block.timestamp,
            _valid
        );
    }

    function getBidTimeLeft() public view returns (uint256) {
        if (block.timestamp > bidEndTime) {
            return 0;
        } else {
            return (bidEndTime - block.timestamp);
        }
    }

    function getVerifyTimeLeft() public view returns (uint256) {
        if (block.timestamp > verify_expiryTime) {
            return 0;
        } else {
            return (verify_expiryTime - block.timestamp);
        }
    }

    function getPaymentTimeLeft() public view returns (uint256) {
        if (block.timestamp > payment_expiryTime) {
            return 0;
        } else {
            return (payment_expiryTime - block.timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library AuctionUtility {
    function getWeiPerUsdRate() internal view returns (uint256) {
        // for testnet
        /*
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData(); // WeiPerUsd (in 8 decimals)
        */
        // for local network
        int256 price = 132102000000;

        return uint256(price * 1e10);
    }

    function convertWeiToUsd(uint256 p_weiAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethRate = getWeiPerUsdRate();
        uint256 usdEquivalent = (p_weiAmount * ethRate) / (1e18 * 1e18);
        return usdEquivalent;
    }

    function convertUsdToWei(uint256 p_usdAmount)
        internal
        view
        returns (uint256)
    {
        uint256 ethRate = getWeiPerUsdRate();
        uint256 weiEquivalent = (1e18 * 1e18) / (p_usdAmount * ethRate);
        return weiEquivalent;
    }

    function hourToSec(uint inHours) internal pure returns (uint256 inMinutes) {
        return (inHours * 60 * 60);
    }

    function getContractType(address _contractAddress)
        internal
        returns (Constants.ContractType)
    {
        (bool success, bytes memory data) = _contractAddress.call(
            abi.encodeWithSignature("getContractType()")
        );
        require(success, "Unable to determine the contract type!");
        return abi.decode(data, (Constants.ContractType));
    }

    function getPlatformCharge(uint256 highestBid)
        internal
        pure
        returns (uint256 platformCharge)
    {
        return (highestBid * Constants.platformChargeRate) / 100;
    }
}

library Constants {
    enum ContractType {
        AUCTION,
        AUCTION_MANAGER,
        AUCTION_REGISTRY,
        CONTRACT_FACTORY,
        AUCTION_KEEPER
    }

    enum AuctionEndState {
        NOT_ENDED,
        CANCELED,
        NO_BIDDER,
        REJECTED_BY_SELLER,
        PAYMENT_OVERDUE,
        AUDIT_REJECTED,
        OWNERSHIP_TRANSFERRED
    }

    enum PlatformEarnings {
        NO_EARNINGS, // when auction fail audit or no bidder or seller disagree to sell or cancelled
        DEPOSIT, // when winner did not pay full settlement
        FULL_SETTLEMENT // when auction passed audit
    }

    uint32 internal constant platformChargeRate = 5; // 5 percent
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}