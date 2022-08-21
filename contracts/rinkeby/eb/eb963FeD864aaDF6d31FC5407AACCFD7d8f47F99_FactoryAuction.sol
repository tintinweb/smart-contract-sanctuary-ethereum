// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Auction.sol";

contract FactoryAuction {
    address[] public auctions;
    address public owner;

    event AuctionCreated(address auctionContract, address owner, uint numActions, address[] allAuctions);

    constructor() {
        owner = msg.sender;
    }

    function createAuction(uint startBlock, uint endBlock, string memory ipfsHash, uint maxPrice) 
    public
    returns (address){
        Auction newAuction = new Auction(msg.sender,startBlock, endBlock, ipfsHash, maxPrice);
        auctions.push(address(newAuction));

        emit AuctionCreated(address(newAuction), msg.sender, auctions.length, auctions);
        return address(newAuction);
    }

    function allAuctions() public view returns(address[] memory){
        return auctions;
    }

    function amountAllAuctions() public view returns(uint){
        return auctions.length;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Auction {
    // Info about Factory
    address public _factoryAddress;

    // Main auction info
    address public _owner;
    uint public _startBlock;
    uint public _endBlock;
    uint public _maxPrice;
    string public _ipfsHash;

    // State auction info
    bool public _isCanceled;
    address public _highestBidder;
    mapping(address => uint256) public _bidByBidder;
    bool public _ownerIsWithdraw;

    event NewBid(address bidder, uint bid, address highestBidder, uint highestBid);
    event Withdrawal(address withdrawer, address withdrawalAccount, uint amount);
    event AuctionEnded(uint maxPrice, uint highestBid, address highestBidder);
    event AuctionCanceled();

    constructor(address owner, uint startBlock, uint endBlock, string memory ipfsHash, uint maxPrice) payable {
        require(startBlock <= endBlock, "StartBlock <= EndBlock!");
        require(startBlock > block.number, "Auction can't start in the past! Check StartBlock!");
        require(owner != address(0), "Check owner address!");
        require(maxPrice > 0, "You can't create auction with maxProca equal 0!");
        
        _owner = owner;
        _startBlock = startBlock;
        _endBlock = endBlock;
        _ipfsHash = ipfsHash;
        _maxPrice = maxPrice;

        _factoryAddress = msg.sender;
    }

    function getHighestBid() public view returns(uint){
        return _bidByBidder[_highestBidder];
    }

    function placeBid() 
    payable
    onlyAfterStartAuction
    onlyBeforeEndAuction
    onlyNotCanceled
    onlyNotOwner
    public
    returns(bool newBidSuccess){
        require(msg.value != 0, "The new bid must not be equal to 0!");

        uint newBid = _bidByBidder[msg.sender] + msg.value;
        uint highestBid = _bidByBidder[_highestBidder];
        require(newBid > highestBid, "The new bid must be greater than the previous highest bid!");
        
        _bidByBidder[msg.sender] = newBid;

        if(msg.sender != _highestBidder)
            _highestBidder = msg.sender;
        
        highestBid = newBid;
        
        if(highestBid >= _maxPrice){
            _endBlock = block.number;
            emit AuctionEnded(_maxPrice, highestBid, _highestBidder);
        }

        emit NewBid(msg.sender, newBid, _highestBidder, highestBid);
        return true;
    }

    function withdraw()
    onlyAfterEndedOrCanceled
    public
    returns(bool success){
        address withdrawAccount;
        uint withdrawAmount;

        if(_isCanceled){
            withdrawAccount = msg.sender;
            withdrawAmount = _bidByBidder[msg.sender];
        }
        else{
            uint maxBid = _bidByBidder[_highestBidder];

            if(msg.sender == _owner){
                withdrawAccount = _highestBidder;
                if(maxBid > _maxPrice)
                    withdrawAmount = _maxPrice;
                else    
                    withdrawAmount = maxBid;
                _ownerIsWithdraw = true;
            }
            else if(msg.sender == _highestBidder && _bidByBidder[msg.sender] >= _maxPrice){
                withdrawAccount = msg.sender;
                withdrawAmount = _bidByBidder[withdrawAccount] - _maxPrice;
            }
            else{
                withdrawAccount = msg.sender;
                withdrawAmount = _bidByBidder[withdrawAccount];
            }

            require(withdrawAmount != 0, "You have nothing to withdraw!");
            _bidByBidder[withdrawAccount] -= withdrawAmount;

            require(payable(msg.sender).send(withdrawAmount), "Error withdraw!");

            emit Withdrawal(msg.sender, withdrawAccount, withdrawAmount);
            return true;
        }
    }

    function acceptMaxBid()
    onlyOwner
    onlyAfterStartAuction
    onlyBeforeEndAuction
    onlyNotCanceled
    public 
    returns(bool success){
        address withdrawAccount;
        uint withdrawAmount;
        
        _endBlock = block.number;
        uint maxBid = _bidByBidder[_highestBidder];

        withdrawAccount = _highestBidder;
        if(maxBid > _maxPrice)
            withdrawAmount = _maxPrice;
        else    
            withdrawAmount = maxBid;
        _ownerIsWithdraw = true;

        require(withdrawAmount != 0, "You have nothing to withdraw!");
        _bidByBidder[withdrawAccount] -= withdrawAmount;

        require(payable(msg.sender).send(withdrawAmount), "Error withdraw!");

        emit AuctionEnded(_maxPrice, maxBid, _highestBidder);
        emit Withdrawal(msg.sender, withdrawAccount, withdrawAmount);
        return true;
    }


    function cancelAuction() 
        onlyOwner
        onlyBeforeEndAuction
        onlyNotCanceled 
    public returns (bool){
        _isCanceled = true;
        emit AuctionCanceled();
        return true;
    }

    modifier onlyOwner{
        require(msg.sender == _owner, "Only for owner!");
        _;
    }

    modifier onlyAfterStartAuction{
        require(block.number > _startBlock, "Auction not start yet!");
        _;
    }

    modifier onlyBeforeEndAuction{
        require(block.number < _endBlock, "Auction is ended!");
        _;
    }

    modifier onlyNotOwner{
        require(msg.sender != _owner, "Owner can't bid!");
        _;
    }

    modifier onlyNotCanceled{
        require(!_isCanceled, "Auction is canceled!");
        _;
    }

    modifier onlyAfterEndedOrCanceled{
        require(block.number > _endBlock || _isCanceled, "Auction not ended and not canceled!");
        _;
    }
}