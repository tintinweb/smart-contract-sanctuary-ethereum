//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTStoreHouse {
    function emitStartAuctionEvent(address _user, uint _price) external;

    function emitAuctionEndEvent(address _user, uint _price) external;
    
    function emitRedeemWithAllSupplyEvent(address _user) external;
    
    function emitDirectBuyoutEvent(address _approver, address _buyer, uint _price) external;
}

import './ERC20Upgradeable.sol';
import './ERC721HolderUpgradeable.sol';
import './ILockedNFT.sol';
import './ReentrancyGuard.sol';
import './IERC721.sol';
import './IERC20.sol';
import './Address.sol';
import './IGlobalGovernanceSettings.sol';


contract LockedNFT is ERC20Upgradeable, ERC721HolderUpgradeable, ILockedNFT, ReentrancyGuard {
    using Address for address;

    address internal constant eth = address(0);

    //store all owner
    address[] private owners;

    IERC721 public lockedNFTContract; //ori contract address of the nft
    uint public tokenID;
    uint public ownerBuyoutFee;
    uint public requireVoterTurnoutRate;
    address public override curator;
    uint public requireShareholdingRatio;
    uint public override ownerTradingFee;
    address public currency;

    // Vote by FNFT owners
    uint public reservePriceTotal; //reserve price of the whole token after vote
    uint public auctionLengthTotal; //auction price after vote
    uint public bidIncrementTotal; //bidincrement after vote
    
    uint public lastClaimed;  //use for store the fnft created time
    uint public totalVoted;
    
    mapping(address => uint) public userReservePrice; 
    mapping(address => uint) public userAuctionLength;
    mapping(address => uint) public userBidIncrement;
    
    IGlobalGovernanceSettings internal globalGovernanceSettings; //contract instance
    State public currentState;
    
    enum State { normal, auctioning, auctionEnd, redeemed, directlySold }
    
    address public highestBidder;
    uint public highestBidPrice;
    uint public auctionEndTime;
    
    uint public finalSupply;
    uint private totalFNFT;
    uint private initReservePrice;
    
    bool public allowDirectBuyout;
    bool public directBuyoutEnabled;

    mapping(address => uint) public userAddressToPrice; //store the price of user make offer on direct buyout
    address[] public usersMakeBuyoutOffer; //store the user who made offer

    event UserUpdateReservePrice(address indexed user, uint oldValue, uint newValue, uint tokenCount);
    event UserUpdateAuctionLength(address indexed user, uint oldValue, uint newValue, uint tokenCount);
    event UserUpdateBidIncrement(address indexed user, uint oldValue, uint newValue, uint tokenCount);
    event StartAuction(address indexed user, uint price);
    event Bid(address indexed user, uint price);
    event RedeemWithAllSupply(address indexed user);
    event AuctionEnd(address indexed user, uint price);
    event ClaimMoney(address indexed user, uint money);
    event MakeBuyoutOffer(address indexed user, uint price);
    event RemoveBuyoutOffer(address indexed user);
    event AcceptBuyoutOffer(address indexed approver, address buyer, uint price);

    function initialize(
        address _globalGovernanceSettings,
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        uint _reservePrice,
        address _currency,
        address _lockedNFTContract,
        uint _tokenID,
        // uint _ownerBuyoutFee,
        uint _requireVoterTurnoutRate,
        address _previousNFTOwner,
        uint _requireShareholdingRatio,
        bool _allowDirectBuyout
    ) initializer external {
        globalGovernanceSettings = IGlobalGovernanceSettings(_globalGovernanceSettings);

        require((_requireVoterTurnoutRate >= globalGovernanceSettings.minRequireVoterTurnoutRate()) && (_requireVoterTurnoutRate <= globalGovernanceSettings.maxRequireVoterTurnoutRate()), "Vote percentage threshold too high or too low");
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
        currentState = State.normal;
    }
    
    ///@notice set trading fee in trading market
    function setOwnerTradingFee(uint _ownerTradingFee) public {
        require(_ownerTradingFee <= globalGovernanceSettings.originalOwnerTradingFeeUpperBound(), "Too high owner fee");
        require(currentState == State.normal, "Current state must not be in auction");
        ownerTradingFee = _ownerTradingFee;
    }
    
    ///@notice set buyout fee for this contract
    function setOwnerBuyoutFee(uint _ownerBuyoutFee) public {
        require(_ownerBuyoutFee <= globalGovernanceSettings.originalOwnerBuyoutFeeUpperBound(), "Too high owner fee");
        require(currentState == State.normal, "Current state must not be in auction");
        ownerBuyoutFee = _ownerBuyoutFee;
    }
    
    ///@notice change curator
    function delegateCurator(address _delegate) public {
        require(msg.sender == curator);
        curator = _delegate;
    }
    
    ///@notice enable direct buyout
    function toggleDirectBuyoutEnabled() public { 
        require(allowDirectBuyout);
        require(balanceOf(msg.sender) * 2 >= totalSupply(), "You don't have right to do so");
        directBuyoutEnabled = !directBuyoutEnabled;
    }
    
    //claimFees counted by second
    function _claimFees() internal {
        require(currentState != State.auctionEnd, "claim:cannot claim after auction ends");
        uint governanceFee = globalGovernanceSettings.governanceFee() * totalSupply() * (block.timestamp - lastClaimed) / 31536000000;
        uint originalOwnerBuyoutFee = ownerBuyoutFee * totalSupply() * (block.timestamp - lastClaimed) / 31536000000;
        lastClaimed = block.timestamp;
        _mint(curator, originalOwnerBuyoutFee);
        _mint(globalGovernanceSettings.feeClaimer(),governanceFee); 
    }
    
    /// @notice vote for the unit reserve price and the auction length, bid increment
    function vote(uint _reservePrice, uint _auctionLength, uint _bidIncrement) public {
        uint weight = balanceOf(msg.sender);

        _updateReservePrice(_reservePrice, weight);
        _updateAuctionLength(_auctionLength, weight);
        _updateBidIncrement(_bidIncrement, weight);
    }
    
    // calculate the new price
    function _updateReservePrice(uint _reservePrice, uint weight) internal {
        uint lowerBound = initReservePrice * globalGovernanceSettings.reservePriceLowerLimitPercentage() / 10000;
        uint upperBound = initReservePrice * globalGovernanceSettings.reservePriceUpperLimitPercentage() / 10000;
        
        require((_reservePrice >= lowerBound), "Reserve price too low");
        require(_reservePrice <= upperBound, "Reserve price too high");
        require(currentState == State.normal, "Current state must not be in auction");
        uint oldChoice = userReservePrice[msg.sender];
        /* if (_reservePrice * weight * totalFNFT) is smaller than totalSupply, weightedReservePrice will become 0 
           reason: (_reservePrice * weight * totalFNFT / totalSupply()) < 1, it become a float (about 0.xxxxxxxx) */
        uint weightedReservePrice = _reservePrice * weight  * totalFNFT / totalSupply();

        //if never voted
        if ((oldChoice == 0)) {
            userReservePrice[msg.sender] = _reservePrice;
            reservePriceTotal += weightedReservePrice;
            totalVoted += weight;
        } else {
            userReservePrice[msg.sender] = _reservePrice;
            uint userOldChoice = oldChoice * weight * totalFNFT / totalSupply();
            reservePriceTotal = reservePriceTotal - userOldChoice + weightedReservePrice;
        }
        require(totalVoted > 0, "There must be at least one voter");
        emit UserUpdateReservePrice(msg.sender, oldChoice, _reservePrice, weight);
    }
    
    function _updateAuctionLength(uint _auctionLength, uint weight) internal {
        require(_auctionLength <= globalGovernanceSettings.maxAuctionLength(), "Auction length too high");
        require(_auctionLength >= globalGovernanceSettings.minAuctionLength(), "Auction length too low");
        require(currentState == State.normal, "Current state must not be in auction");
        uint oldChoice = userAuctionLength[msg.sender];
        /* if (_auctionLength * weight) is smaller than totalSupply, weightedAuctionLength will become 0 
           reason: (_auctionLength * weight / totalSupply()) < 1, it become a float (about 0.xxxxxxxx) */
        uint weightedAuctionLength = _auctionLength * weight / totalSupply();

        if ((oldChoice == 0) && (_auctionLength != 0)) {
            userAuctionLength[msg.sender] = _auctionLength; //save auction length of the msg.sender
            auctionLengthTotal += weightedAuctionLength;
        } 
        else {
            userAuctionLength[msg.sender] = _auctionLength;
            uint userOldChoice = oldChoice * weight / totalSupply();
            auctionLengthTotal = auctionLengthTotal - userOldChoice + weightedAuctionLength;
        }
        emit UserUpdateAuctionLength(msg.sender, oldChoice, _auctionLength, weight);
    }
    
    function _updateBidIncrement(uint _bidIncrement, uint weight) internal {
        require(_bidIncrement <= globalGovernanceSettings.maxBidIncrement(), "Bid increment too high");
        require(_bidIncrement >= globalGovernanceSettings.minBidIncrement(), "Bid increment too low");
        require(currentState == State.normal, "Current state must not be in auction");
        uint oldChoice = userBidIncrement[msg.sender];
        uint weightedBidIncrement = _bidIncrement * weight / totalSupply();

        if ((oldChoice == 0) && (_bidIncrement != 0)) {
            userBidIncrement[msg.sender] = _bidIncrement;
            bidIncrementTotal += weightedBidIncrement;
        }
        else {
            userBidIncrement[msg.sender] = _bidIncrement;
            uint userOldChoice = oldChoice * weight / totalSupply();
            bidIncrementTotal = bidIncrementTotal - userOldChoice + weightedBidIncrement;
        }
        emit UserUpdateAuctionLength(msg.sender, oldChoice, _bidIncrement, weight);
    }
    
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if ((_from != address(0)) && (_to != address(0))) {
            if(currentState == State.normal && userReservePrice[_from] != userReservePrice[_to]) {
                if (userReservePrice[_to] != 0) {
                    //_to have voted
                    totalVoted += _amount;
                    reservePriceTotal += _amount * userReservePrice[_to] * totalFNFT / totalSupply();
                    auctionLengthTotal += _amount * userAuctionLength[_to] / totalSupply();
                    bidIncrementTotal += _amount * userBidIncrement[_to] / totalSupply();
                } 
                if (userReservePrice[_from] != 0) {
                    //_from have voted
                    totalVoted -= _amount;
                    reservePriceTotal -= _amount * userReservePrice[_from] * totalFNFT / totalSupply();
                    auctionLengthTotal -= _amount * userAuctionLength[_from] / totalSupply();
                    bidIncrementTotal -= _amount * userBidIncrement[_from] / totalSupply();
                }
            }

            if(balanceOf(_from) == _amount) {
                //user pay all value to others
                uint position;
                address lastPerson = owners[owners.length-1];
                for(uint i = 0; i<owners.length; i++) {
                    //find out the position of _from
                    if(owners[i] == _from) {
                        position = i;
                    }
                }
                owners[position] = lastPerson;
                owners.pop();
            }
        }

        if(balanceOf(_to) == 0 && _to != address(0)) {
            //_to not in the owner list
            owners.push(_to);
        }
    }

    // Input: price for all fnft supply
    function startAuction(uint _price) public payable nonReentrant {
        require(currentState == State.normal, "Current state must not be in auction");
        require(totalVoted != 0, "Nobody has voted for auction length and bid increment");
        require(balanceOf(msg.sender) >= totalSupply() * requireShareholdingRatio / 10000, "Your balance is not enough to buy");
        require(_price >= reservePriceTotal, "Price lower than reserve price for all supply");
        require(totalVoted * 10000 / totalSupply() >= requireVoterTurnoutRate, "Not enough FNFT holders accept buyout");
        if (currency == eth) {
            require(msg.value == _price, "Please send exact amount of ETH you specified to start an auction");
        } else {
            require(IERC20(currency).transferFrom(msg.sender, address(this), _price), "No enough tokens");
        }
        auctionEndTime = block.timestamp + auctionLengthTotal;
        currentState = State.auctioning;
        highestBidder = msg.sender;
        highestBidPrice = _price;
        
        emit StartAuction(msg.sender, _price);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitStartAuctionEvent(msg.sender, _price);
    }
    
    function bid(uint _price) public payable nonReentrant {
        require(currentState == State.auctioning, "Current state not be in auction");
        require(balanceOf(msg.sender) >= totalSupply() * requireShareholdingRatio / 10000);
        require(_price >= highestBidPrice * bidIncrementTotal / 10000 + highestBidPrice, "Price too low");
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
        require(currentState == State.normal, "Current state must not be in auction");
        require(balanceOf(msg.sender) == totalSupply(), "You dont own all FNFT tokens");
        lockedNFTContract.safeTransferFrom(address(this), msg.sender, tokenID);
        _burn(msg.sender, balanceOf(msg.sender));
        currentState = State.redeemed;
        highestBidder = msg.sender; //seems can delete
        
        emit RedeemWithAllSupply(msg.sender);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitRedeemWithAllSupplyEvent(msg.sender);
    }
    
    function _endAuction() internal {
        require(block.timestamp > auctionEndTime, "Auction is still on-going");

        _claimFees();

        currentState = State.auctionEnd;
        lockedNFTContract.safeTransferFrom(address(this), highestBidder, tokenID); //transfer the NFT to the bidder
        finalSupply = totalSupply();
        
        emit AuctionEnd(highestBidder, highestBidPrice);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitAuctionEndEvent(highestBidder, highestBidPrice);
    }

    ///@notice request for direct buyout
    function makeBuyoutOffer(uint _price) public payable nonReentrant {
        require(currentState == State.normal, "The NFT has been sold or auction is on-going");
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
            require(IERC20(currency).transferFrom(msg.sender, address(this), _price), "No enough tokens");
            if (userAddressToPrice[msg.sender] > 0) {
                IERC20(currency).transfer(msg.sender, userAddressToPrice[msg.sender]);
            } else {
                usersMakeBuyoutOffer.push(msg.sender);
            }
        }
        userAddressToPrice[msg.sender] = _price;
        
        emit MakeBuyoutOffer(msg.sender, _price);
    }

    function removeBuyoutOffer() public nonReentrant {
        require(userAddressToPrice[msg.sender] > 0);
        require(currentState != State.directlySold, "The fnft is directly sold");

        uint price = userAddressToPrice[msg.sender];
        userAddressToPrice[msg.sender] = 0;

        if (currency == eth) {
            payable(msg.sender).transfer(price);
        } else {
            IERC20(currency).transfer(msg.sender, price);
        }
        
        address latestBuyer = usersMakeBuyoutOffer[usersMakeBuyoutOffer.length - 1];
        uint userIndex;
        for(uint i=0; i<usersMakeBuyoutOffer.length; i++) {
            if(usersMakeBuyoutOffer[i] == msg.sender){
                userIndex = i;
            }
        }
        usersMakeBuyoutOffer[userIndex] = latestBuyer; //position of msg.sender inside usersMakeBuyoutOffer change to become lastest Buyer
        usersMakeBuyoutOffer.pop();
        emit RemoveBuyoutOffer(msg.sender);
    }

    function getBuyoutOfferCount() public view returns (uint) {
        return usersMakeBuyoutOffer.length;
    }

    ///@notice read the list of buyout offers from _start with length _length
    function getBuyoutOfferList(uint _start, uint _length) public view returns (address[] memory, uint[] memory) {
        uint maxLength = (_start + _length > usersMakeBuyoutOffer.length) ? (usersMakeBuyoutOffer.length - _start) : _length;
        address[] memory addressList = new address[](maxLength);
        uint[] memory priceList = new uint[](maxLength);
        for (uint i = 0; i < maxLength; i++) {
            addressList[i] = usersMakeBuyoutOffer[_start + i];
            priceList[i] = userAddressToPrice[usersMakeBuyoutOffer[_start + i]];
        }
        return (addressList, priceList);
    }

    //return money to the fnft owners
    function returnCost() internal returns (bool){
        for(uint i = 0; i < owners.length; i++) {
            uint ownerFee = highestBidPrice * balanceOf(owners[i]) / finalSupply;
            if (currency == eth) {
                require(address(this).balance >= ownerFee, "address's balance is not enough to pay");
                if(owners[i] != address(0)){
                    payable(owners[i]).transfer(ownerFee);
                }
            } else {
                if(owners[i] != address(0)){
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
        for(uint i = 0; i < usersMakeBuyoutOffer.length; i++) {
            uint price = userAddressToPrice[usersMakeBuyoutOffer[i]];

            if (currency == eth) {
                require(address(this).balance >= price, "contract balance is not enough to pay");
                payable(usersMakeBuyoutOffer[i]).transfer(price);
            } else {
                IERC20(currency).transfer(usersMakeBuyoutOffer[i], price);
            }
            userAddressToPrice[usersMakeBuyoutOffer[i]] = 0;
        }
        delete usersMakeBuyoutOffer;
        return true;
    }

    function acceptBuyoutOffer(address buyerAddress) public nonReentrant {
        require(currentState == State.normal, "The NFT has been sold");
        require(allowDirectBuyout && directBuyoutEnabled, "Direct buyout is not allowed");
        require(balanceOf(msg.sender) * 2 >= totalSupply(), "You don't have right to accept buyout offer");
        currentState = State.directlySold;
        _claimFees();
        highestBidder = buyerAddress;
        highestBidPrice = userAddressToPrice[buyerAddress];

        lockedNFTContract.safeTransferFrom(address(this), buyerAddress, tokenID);
        
        finalSupply = totalSupply();

        //return money to all owners
        require(returnCost(), "money has no totally transfer to the owner");
        
        //delete the buyer in offer list
        address latestBuyer = usersMakeBuyoutOffer[usersMakeBuyoutOffer.length - 1];
        uint userIndex;
        for(uint i=0; i<usersMakeBuyoutOffer.length; i++) {
            if(usersMakeBuyoutOffer[i] == buyerAddress){
                userIndex = i;
            }
        }
        usersMakeBuyoutOffer[userIndex] = latestBuyer;
        usersMakeBuyoutOffer.pop();
        require(returnBuyoutFee(), "money has no totally transfer to the offer maker");
        require(usersMakeBuyoutOffer.length == 0, "buyout offer not clean");
        require(owners.length == 0, "owners list not clean");
        
        emit AcceptBuyoutOffer(msg.sender, highestBidder, highestBidPrice);
        INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitDirectBuyoutEvent(msg.sender, highestBidder, highestBidPrice);
    }

    function claimMoneyAfterAuctionEnd() public nonReentrant {
        require((currentState == State.auctioning) || (currentState == State.auctionEnd) || (currentState == State.directlySold), "Auction has not ended");
        require(block.timestamp > auctionEndTime, "Auction is still on-going"); //same function with up
        require(balanceOf(msg.sender) > 0 || msg.sender == highestBidder, "You dont have any token");
        if (currentState == State.auctioning) {
             _claimFees();
            currentState = State.auctionEnd;
            lockedNFTContract.safeTransferFrom(address(this), highestBidder, tokenID); //transfer the NFT to the bidder  
            finalSupply = totalSupply();
            emit AuctionEnd(highestBidder, highestBidPrice);
            INFTStoreHouse(globalGovernanceSettings.nftStoreHouse()).emitAuctionEndEvent(highestBidder, highestBidPrice);
        } 
        
        require(returnCost(), "money has no totally transfer to the owner");
        require(returnBuyoutFee(), "money has no totally transfer to the offer maker");

        require(owners.length == 0, "owners list not clean");
        require(usersMakeBuyoutOffer.length == 0, "buyout offer not clean");
    }
}