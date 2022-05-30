//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTStoreHouse {
    function emitStartAuctionEvent(address _user, uint256 _price) external;

    function emitAuctionEndEvent(address _user, uint256 _price) external;

    function emitRedeemWithAllSupplyEvent(address _user) external;

    function emitDirectBuyoutEvent(
        address _approver,
        address _buyer,
        uint256 _price
    ) external;
}

import "./ERC20Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./ILockedNFT.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./IGlobalGovernanceSettings.sol";

contract LockedNFT is
    ERC20Upgradeable,
    ERC721HolderUpgradeable,
    ILockedNFT,
    ReentrancyGuard
{
    using Address for address;

    address internal constant eth = address(0);

    //store all owner
    address[] private owners;

    IERC721 public lockedNFTContract; //ori contract address of the nft
    uint256 public tokenID;
    uint256 public ownerBuyoutFee;
    uint256 public requireVoterTurnoutRate;
    address public override curator;
    uint256 public requireShareholdingRatio;
    uint256 public override ownerTradingFee;
    address public currency;

    // Vote by FNFT owners
    uint256 public reservePriceTotal; //reserve price of the whole token after vote
    uint256 public auctionLengthTotal; //auction price after vote
    uint256 public bidIncrementTotal; //bidincrement after vote

    uint256 public lastClaimed; //use for store the fnft created time
    uint256 public totalVoted;

    mapping(address => uint256) public userReservePrice;
    mapping(address => uint256) public userAuctionLength;
    mapping(address => uint256) public userBidIncrement;

    IGlobalGovernanceSettings internal globalGovernanceSettings; //contract instance
    Status public currentStatus;

    enum Status {
        forFractionSale,
        inLiveAuction,
        auctionEnd,
        redeemed,
        boughtOut
    }

    address public highestBidder;
    uint256 public highestBidPrice;
    uint256 public auctionEndTime;

    uint256 public finalSupply;
    uint256 private totalFNFT;
    uint256 public initReservePrice;

    bool public allowDirectBuyout;
    bool public directBuyoutEnabled;

    mapping(address => uint256) public userAddressToPrice; //store the price of user make offer on direct buyout
    address[] public usersMakeBuyoutOffer; //store the user who made offer

    event Vote(address indexed user, uint256 reservePrice, uint256 auctionAuction, uint256 bidIncrement);
    event StartAuction(address indexed user, uint256 price);
    event Bid(address indexed user, uint256 price);
    event RedeemWithAllSupply(address indexed user);
    event AuctionEnd(address indexed user, uint256 price);
    event ClaimMoney(address indexed user, uint256 money);
    event MakeBuyoutOffer(address indexed user, uint256 price);
    event RemoveBuyoutOffer(address indexed user);
    event AcceptBuyoutOffer(
        address indexed approver,
        address buyer,
        uint256 price
    );

    function initialize(
        address _globalGovernanceSettings,
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _reservePrice,
        address _currency,
        address _lockedNFTContract,
        uint256 _tokenID,
        uint256 _requireVoterTurnoutRate,
        address _previousNFTOwner,
        uint256 _requireShareholdingRatio,
        bool _allowDirectBuyout
    ) external initializer {
        globalGovernanceSettings = IGlobalGovernanceSettings(
            _globalGovernanceSettings
        );

        require((_requireVoterTurnoutRate >=globalGovernanceSettings.minRequireVoterTurnoutRate()) && (_requireVoterTurnoutRate <= globalGovernanceSettings.maxRequireVoterTurnoutRate()), "Vote percentage threshold too high or too low");
        require(globalGovernanceSettings.currencyToAcceptableForTrading(_currency) == true, "The currency is not accepted now"); //check trading ERC20 is enabled
        require(_reservePrice > 0, "Reserve price must be positive");
        require(_requireShareholdingRatio <= 10000); //10000 = 100%

        __ERC20_init(_name, _symbol);
        __ERC721Holder_init();

        lockedNFTContract = IERC721(_lockedNFTContract);
        tokenID = _tokenID;
        requireVoterTurnoutRate = _requireVoterTurnoutRate;
        curator = _previousNFTOwner;
        requireShareholdingRatio = _requireShareholdingRatio;
        currency = _currency;

        _mint(curator, _totalSupply * 1 ether);

        initReservePrice = _reservePrice;
        reservePriceTotal = 0;
        totalVoted = 0;
        totalFNFT = _totalSupply;

        allowDirectBuyout = _allowDirectBuyout;

        lastClaimed = block.timestamp;
        currentStatus = Status.forFractionSale;
    }

    ///@notice set trading fee in trading market
    function setOwnerTradingFee(uint256 _ownerTradingFee) public {
        require(msg.sender == curator);
        require( _ownerTradingFee <=globalGovernanceSettings.originalOwnerTradingFeeUpperBound(), "Too high owner fee");
        require(currentStatus == Status.forFractionSale, "Current Status must not be in auction");
        ownerTradingFee = _ownerTradingFee;
    }

    ///@notice set buyout fee for this contract
    function setOwnerBuyoutFee(uint256 _ownerBuyoutFee) public {
        require(msg.sender == curator);
        require(_ownerBuyoutFee <= globalGovernanceSettings.originalOwnerBuyoutFeeUpperBound(), "Too high owner fee");
        require(currentStatus == Status.forFractionSale, "Current Status must not be in auction");
        ownerBuyoutFee = _ownerBuyoutFee;
    }

    ///@notice change curator
    function delegateCurator(address _delegate) public {
        require(msg.sender == curator);
        curator = _delegate;
    }

    ///@notice enable direct buyout
    function toggleDirectBuyoutEnabled() public {
        require(allowDirectBuyout, "Direct buyout is not start");
        require(balanceOf(msg.sender) * 2 >= totalSupply(),"You don't have right to do so");
        directBuyoutEnabled = !directBuyoutEnabled;
    }

    //claimFees counted by second
    function _claimFees() internal {
        require(currentStatus != Status.auctionEnd, "claim:cannot claim after auction ends");
        uint256 governanceFee = (globalGovernanceSettings.governanceFee() * totalSupply() * (block.timestamp - lastClaimed)) / 31536000000;
        uint256 originalOwnerBuyoutFee = (ownerBuyoutFee * totalSupply() * (block.timestamp - lastClaimed)) / 31536000000;
        lastClaimed = block.timestamp;
        _mint(curator, originalOwnerBuyoutFee);
        _mint(globalGovernanceSettings.feeClaimer(), governanceFee);
    }

    /// @notice vote for the unit reserve price and the auction length, bid increment
    function vote(uint256 _reservePrice, uint256 _auctionLength, uint256 _bidIncrement) public {
        require(currentStatus == Status.forFractionSale, "Current Status must not be in auction");
        require(userReservePrice[msg.sender] == 0, "User can only vote for one time");
        uint256 weight = balanceOf(msg.sender);
        require(weight > 0, "You don't have any token to vote");

        _updateReservePrice(_reservePrice, weight);
        _updateAuctionLength(_auctionLength, weight);
        _updateBidIncrement(_bidIncrement, weight);

        emit Vote(msg.sender, _reservePrice, _auctionLength, _bidIncrement);
    }

    // calculate the new price
    function _updateReservePrice(uint256 _reservePrice, uint256 weight) internal {
        uint256 lowerBound = (initReservePrice *
            globalGovernanceSettings.reservePriceLowerLimitPercentage()) /
            10000;
        uint256 upperBound = (initReservePrice *
            globalGovernanceSettings.reservePriceUpperLimitPercentage()) /
            10000;

        require((_reservePrice >= lowerBound), "Reserve price too low");
        require(_reservePrice <= upperBound, "Reserve price too high");
        /* if (_reservePrice * weight * totalFNFT) is smaller than totalSupply, weightedReservePrice will become 0 
           reason: (_reservePrice * weight * totalFNFT / totalSupply()) < 1, it become a float (about 0.xxxxxxxx) */
        uint256 weightedReservePrice = (_reservePrice * weight * totalFNFT) /
            totalSupply();

        userReservePrice[msg.sender] = _reservePrice;
        reservePriceTotal += weightedReservePrice;
        totalVoted += weight;
        require(totalVoted > 0, "There must be at least one voter");
    }

    function _updateAuctionLength(uint256 _auctionLength, uint256 weight)
        internal
    {
        require(
            _auctionLength <= globalGovernanceSettings.maxAuctionLength(),
            "Auction length too high"
        );
        require(
            _auctionLength >= globalGovernanceSettings.minAuctionLength(),
            "Auction length too low"
        );
        /* if (_auctionLength * weight) is smaller than totalSupply, weightedAuctionLength will become 0 
           reason: (_auctionLength * weight / totalSupply()) < 1, it become a float (about 0.xxxxxxxx) */
        uint256 weightedAuctionLength = (_auctionLength * weight) /
            totalSupply();

        userAuctionLength[msg.sender] = _auctionLength; //save auction length of the msg.sender
        auctionLengthTotal += weightedAuctionLength;
    }

    function _updateBidIncrement(uint256 _bidIncrement, uint256 weight)
        internal
    {
        require(
            _bidIncrement <= globalGovernanceSettings.maxBidIncrement(),
            "Bid increment too high"
        );
        require(
            _bidIncrement >= globalGovernanceSettings.minBidIncrement(),
            "Bid increment too low"
        );
        uint256 weightedBidIncrement = (_bidIncrement * weight) / totalSupply();

        userBidIncrement[msg.sender] = _bidIncrement;
        bidIncrementTotal += weightedBidIncrement;
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        if (currentStatus == Status.forFractionSale ) { 
                if (userReservePrice[_to] != 0) {
                    //_to have voted
                    totalVoted += _amount;
                    reservePriceTotal += (_amount * userReservePrice[_to] * totalFNFT) / totalSupply();
                    auctionLengthTotal += (_amount * userAuctionLength[_to]) / totalSupply();
                    bidIncrementTotal += (_amount * userBidIncrement[_to]) / totalSupply();
                }
                if (userReservePrice[_from] != 0) {
                    //_from have voted
                    totalVoted -= _amount;
                    reservePriceTotal -= (_amount * userReservePrice[_from] * totalFNFT) / totalSupply();
                    auctionLengthTotal -= (_amount * userAuctionLength[_from]) / totalSupply();
                    bidIncrementTotal -= (_amount * userBidIncrement[_from]) / totalSupply();
                }
        }

        if(currentStatus == Status.forFractionSale || currentStatus == Status.inLiveAuction) {
            if (balanceOf(_from) == _amount) {
                //user pay all value to others
                uint256 position;
                address lastPerson = owners[owners.length - 1];
                for (uint256 i = 0; i < owners.length; i++) {
                    //find out the position of _from
                    if (owners[i] == _from) {
                        position = i;
                    }
                }
                owners[position] = lastPerson;
                owners.pop();
            }
        }

        if (balanceOf(_to) == 0 && _to != address(0)) {
            //_to not in the owner list
            owners.push(_to);
        }
    }

    // Input: price for all fnft supply
    function startAuction(uint256 _price) public payable nonReentrant {
        require((totalVoted * 10000) / totalSupply() >= requireVoterTurnoutRate, "Not enough FNFT holders accept buyout");
        require(balanceOf(msg.sender) >= (totalSupply() * requireShareholdingRatio) / 10000, "Your balance is not enough to buy");
        require(currentStatus == Status.forFractionSale, "Current Status must not be in auction");
        require(_price >= reservePriceTotal, "Price lower than reserve price for all supply");
        if (currency == eth) {
            require(msg.value == _price, "Please send exact amount of ETH you specified to start an auction");
        } else {
            require(IERC20(currency).transferFrom(msg.sender, address(this), _price), "No enough tokens");
        }

        auctionEndTime = block.timestamp + auctionLengthTotal;
        currentStatus = Status.inLiveAuction;
        highestBidder = msg.sender;
        highestBidPrice = _price;

        emit StartAuction(msg.sender, _price);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse())
            .emitStartAuctionEvent(msg.sender, _price);
    }

    function bid(uint256 _price) public payable nonReentrant {
        require(currentStatus == Status.inLiveAuction, "Current is not in auction");
        require(balanceOf(msg.sender) >= (totalSupply() * requireShareholdingRatio) / 10000, "Balance is not enough to bid");
        require(_price >= (reservePriceTotal * bidIncrementTotal) / 10000 + highestBidPrice, "Price too low");
        require(block.timestamp < auctionEndTime, "Auction ended");

        if (block.timestamp + 15 minutes >= auctionEndTime) {
            auctionEndTime = auctionEndTime + 15 minutes;
        }

        if (currency == eth) {
            require(msg.value == _price, "Please send exact amount of ETH you specified to bid");
            payable(highestBidder).transfer(highestBidPrice); //pay back money to the previous highest bidder
        } else {
            require(IERC20(currency).transfer(highestBidder, highestBidPrice), "No enough tokens");
            require(IERC20(currency).transferFrom(msg.sender, address(this), _price), "No enough tokens");
        }

        highestBidder = msg.sender;
        highestBidPrice = _price;

        emit Bid(msg.sender, _price);
    }

    function revertToNFT() public {
        require(currentStatus == Status.forFractionSale, "Current Status must not be in auction");
        require(balanceOf(msg.sender) == totalSupply(), "You dont own all FNFT tokens");
        lockedNFTContract.safeTransferFrom(address(this), msg.sender, tokenID);
        _burn(msg.sender, balanceOf(msg.sender));
        currentStatus = Status.redeemed;
        highestBidder = msg.sender; //seems can delete

        emit RedeemWithAllSupply(msg.sender);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse())
            .emitRedeemWithAllSupplyEvent(msg.sender);
    }

    function _endAuction() internal {
        require(block.timestamp > auctionEndTime, "Auction is still on-going");

        _claimFees();

        currentStatus = Status.auctionEnd;

        finalSupply = totalSupply();

        emit AuctionEnd(highestBidder, highestBidPrice);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse())
            .emitAuctionEndEvent(highestBidder, highestBidPrice);
    }

    ///@notice request for direct buyout
    function makeBuyoutOffer(uint256 _price) public payable nonReentrant {
        require(currentStatus == Status.forFractionSale, "The NFT has been sold or auction is on-going");
        require(allowDirectBuyout && directBuyoutEnabled, "Direct buyout is not allowed");
        require(_price > 0);

        if (currency == eth) {
            require(msg.value == _price, "Please send exact amount of ETH you specified to start an auction");
            if (userAddressToPrice[msg.sender] > 0) {
                //if user already make offer before, pay back the money
                payable(msg.sender).transfer(userAddressToPrice[msg.sender]);
            } else {
                usersMakeBuyoutOffer.push(msg.sender);
            }
        } else {
            require(
                IERC20(currency).transferFrom(
                    msg.sender,
                    address(this),
                    _price
                ),
                "No enough tokens"
            );
            if (userAddressToPrice[msg.sender] > 0) {
                IERC20(currency).transfer(
                    msg.sender,
                    userAddressToPrice[msg.sender]
                );
            } else {
                usersMakeBuyoutOffer.push(msg.sender);
            }
        }
        userAddressToPrice[msg.sender] = _price;

        emit MakeBuyoutOffer(msg.sender, _price);
    }

    function removeBuyoutOffer() public nonReentrant {
        require(userAddressToPrice[msg.sender] > 0, "You have no buyout offer");
        require(currentStatus == Status.forFractionSale || currentStatus == Status.inLiveAuction, "Current status is not avalible for remove offer");

        require(_claimBuyoutFee(msg.sender), "buyout fee claim fail");

        address latestBuyer = usersMakeBuyoutOffer[
            usersMakeBuyoutOffer.length - 1
        ];
        uint256 userIndex;
        for (uint256 i = 0; i < usersMakeBuyoutOffer.length; i++) {
            if (usersMakeBuyoutOffer[i] == msg.sender) {
                userIndex = i;
            }
        }
        usersMakeBuyoutOffer[userIndex] = latestBuyer; //position of msg.sender inside usersMakeBuyoutOffer change to become lastest Buyer
        usersMakeBuyoutOffer.pop();
        emit RemoveBuyoutOffer(msg.sender);
    }

    function getBuyoutOfferCount() public view returns (uint256) {
        return usersMakeBuyoutOffer.length;
    }

    ///@notice read the list of buyout offers from _start with length _length
    function getBuyoutOfferList(uint256 _start, uint256 _length)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 maxLength = (_start + _length > usersMakeBuyoutOffer.length)
            ? (usersMakeBuyoutOffer.length - _start)
            : _length;
        address[] memory addressList = new address[](maxLength);
        uint256[] memory priceList = new uint256[](maxLength);
        for (uint256 i = 0; i < maxLength; i++) {
            addressList[i] = usersMakeBuyoutOffer[_start + i];
            priceList[i] = userAddressToPrice[usersMakeBuyoutOffer[_start + i]];
        }
        return (addressList, priceList);
    }

    //return money to the fnft owners
    function returnCost() internal returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            uint256 ownerFee = (highestBidPrice * balanceOf(owners[i])) /
                finalSupply;
            if (currency == eth) {
                require(address(this).balance >= ownerFee, "address's balance is not enough to pay");
                if (owners[i] != address(0)) {
                    payable(owners[i]).transfer(ownerFee);
                }
            } else {
                if (owners[i] != address(0)) {
                    IERC20(currency).transfer(owners[i], ownerFee);
                }
            }
            _burn(owners[i], balanceOf(owners[i]));
            emit ClaimMoney(owners[i], ownerFee);
        }
        delete owners;
        return true;
    }

    function returnBuyoutFee() internal returns (bool) {
        for (uint256 i = 0; i < usersMakeBuyoutOffer.length; i++) {
            require(_claimBuyoutFee(usersMakeBuyoutOffer[i]), "buyout fee claim fail");
        }
        delete usersMakeBuyoutOffer;
        return true;
    }

    function _claimBuyoutFee(address _claimer) internal returns (bool) {
        uint256 price = userAddressToPrice[_claimer];

        if (currency == eth) {
            require(
                address(this).balance >= price,
                "contract balance is not enough to pay"
            );
            payable(_claimer).transfer(price);
        } else {
            IERC20(currency).transfer(_claimer, price);
        }
        userAddressToPrice[_claimer] = 0;

        return true;
    }

    function acceptBuyoutOffer(address buyerAddress) public nonReentrant {
        require(currentStatus == Status.forFractionSale, "The NFT has been sold");
        require(allowDirectBuyout && directBuyoutEnabled, "Direct buyout is not allowed");
        require(balanceOf(msg.sender) * 2 >= totalSupply(), "You don't have right to accept buyout offer");
        currentStatus = Status.boughtOut;
        _claimFees();
        highestBidder = buyerAddress;
        highestBidPrice = userAddressToPrice[buyerAddress];

        lockedNFTContract.safeTransferFrom(
            address(this),
            buyerAddress,
            tokenID
        );

        finalSupply = totalSupply();

        //return money to all owners
        require(returnCost(), "money has no totally transfer to the owner");

        //delete the buyer in offer list
        address latestBuyer = usersMakeBuyoutOffer[
            usersMakeBuyoutOffer.length - 1
        ];
        uint256 userIndex;
        for (uint256 i = 0; i < usersMakeBuyoutOffer.length; i++) {
            if (usersMakeBuyoutOffer[i] == buyerAddress) {
                userIndex = i;
            }
        }
        usersMakeBuyoutOffer[userIndex] = latestBuyer;
        usersMakeBuyoutOffer.pop();
        require(
            returnBuyoutFee(),
            "money has no totally transfer to the offer maker"
        );

        require(usersMakeBuyoutOffer.length == 0, "buyout offer not clean");
        require(owners.length == 0, "owners list not clean");

        emit AcceptBuyoutOffer(msg.sender, highestBidder, highestBidPrice);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse())
            .emitDirectBuyoutEvent(msg.sender, highestBidder, highestBidPrice);
    }

    function claim() public nonReentrant {
        require(block.timestamp > auctionEndTime, "Auction is still on-going");
        if (currentStatus == Status.inLiveAuction) {
            _claimFees();
            currentStatus = Status.auctionEnd;
            finalSupply = totalSupply();
            emit AuctionEnd(highestBidder, highestBidPrice);
            INFTStoreHouse(globalGovernanceSettings.nftStoreHouse())
                .emitAuctionEndEvent(highestBidder, highestBidPrice);
        }
        require((currentStatus == Status.auctionEnd) || (currentStatus == Status.boughtOut), "Auction has not ended");
        require(
            balanceOf(msg.sender) > 0 || msg.sender == highestBidder || userAddressToPrice[msg.sender] > 0,
            "You dont have any token"
        );

        //transfer the NFT to the bidder
        if (msg.sender == highestBidder) {
            lockedNFTContract.safeTransferFrom(
                address(this),
                highestBidder,
                tokenID
            );
        }

        //claim money
        uint256 fee = (highestBidPrice * balanceOf(msg.sender)) / finalSupply;
        if (currency == eth) {
            payable(msg.sender).transfer(fee);
        } else {
            IERC20(currency).transfer(msg.sender, fee);
        }
        _burn(msg.sender, balanceOf(msg.sender));
        emit ClaimMoney(msg.sender, fee);

        //get buyout money
        if (userAddressToPrice[msg.sender] > 0) {
            require(_claimBuyoutFee(msg.sender), "buyout fee claim fail");
        }
    }

    function kickCurator() external {
        require(msg.sender == globalGovernanceSettings.owner());
        curator = globalGovernanceSettings.owner();
    }

    ///@notice use for other contract to check current state
    function checkCurrentStatus() external view returns (uint) {
        return uint(currentStatus);
    }
}