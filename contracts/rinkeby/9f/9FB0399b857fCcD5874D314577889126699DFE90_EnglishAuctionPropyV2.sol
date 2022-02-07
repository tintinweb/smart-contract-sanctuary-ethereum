// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IEthAddressWhitelist {
    function isWhitelisted(address _address) external view returns(bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract EnglishAuctionPropyV2 {
    using SafeMath for uint256;
    using SafeMath for uint8;
    // System settings
    uint8 public percentageIncreasePerBid;
    uint256 public stakingRewardPercentageBasisPoints;
    uint256 public tokenId;
    address public tokenAddress;
    bool public ended = false;
    address public controller;
    address public deployer;
    address public tokenHolder;
    
    // Current winning bid
    uint256 public lastBid;
    address public winning;
    
    uint256 public length;
    uint256 public minimumStartTime;
    uint256 public startTime;
    uint256 public endTime;
    
    address public hausAddress;
    address public stakingSwapContract;

    mapping(address => uint256) public ethCredits;
    
    event Bid(address who, uint256 amount);
    event Won(address who, uint256 amount);

    IEthAddressWhitelist ethAddressWhitelistContract;
    IERC721 nftContract;
    
    constructor(
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _reservePriceWei,
        uint256 _minimumStartTime,
        uint256 _stakingRewardPercentageBasisPoints,
        uint8 _percentageIncreasePerBid,
        address _hausAddress,
        address _stakingSwapContract,
        address _ethWhitelistAddress, // 0xBE2779646C64e0f7111F4Dd32f3a6940B4717629 mainnet
        address _tokenHolder,
        address _propyController
    ) public {
        tokenAddress = address(_tokenAddress);
        tokenId = _tokenId;
        lastBid = _reservePriceWei;
        percentageIncreasePerBid = _percentageIncreasePerBid;
        stakingSwapContract = _stakingSwapContract;
        hausAddress = _hausAddress;
        controller = _propyController;
        minimumStartTime = _minimumStartTime;
        deployer = msg.sender;
        stakingRewardPercentageBasisPoints = _stakingRewardPercentageBasisPoints;
        ethAddressWhitelistContract = IEthAddressWhitelist(_ethWhitelistAddress);
        nftContract = IERC721(_tokenAddress);
        tokenHolder = _tokenHolder;
    }
    
    function bid() public payable {
        // Checks
        require(ethAddressWhitelistContract.isWhitelisted(msg.sender), "Bidder not verified, please visit propy.com/kyc");
        require(ethCredits[msg.sender] == 0, "withdraw ethCredits before bidding again");
        require(msg.sender == tx.origin, "no contracts");
        require(block.timestamp >= minimumStartTime, "Bidding has not opened");
        
        // Give back the last bidders money
        if (winning != address(0)) {
            // Checks
            require(block.timestamp >= startTime, "Auction not started");
            require(block.timestamp < endTime, "Auction ended");
            if ((endTime - now) < 15 minutes) {
                endTime = now + 15 minutes;
            }
            address lastBidderMemory = winning;
            uint256 lastBidMemory = lastBid;
            uint8 base = 100;
            uint256 multiplier = base.add(percentageIncreasePerBid);
            require(msg.value >= lastBidMemory.mul(multiplier).div(100), "Bid too small"); // % increase

            // Effects
            lastBid = msg.value;
            winning = msg.sender;

            // Interactions
            (bool returnPreviousBidSuccess, ) = winning.call{value: lastBidMemory}("");
            if(!returnPreviousBidSuccess) {
              ethCredits[lastBidderMemory] = lastBidMemory;
            }
        } else {
            require(msg.value >= lastBid, "Bid too small"); // no increase required for reserve price to be met
            // First bid, reserve met, start auction
            startTime = block.timestamp;
            length = 30 minutes; // TODO set to 7 hours
            endTime = startTime + length;
        }

        emit Bid(msg.sender, msg.value);
    }
    
    function end() public {
        require(msg.sender == controller, "can only be ended by controller");
        require(!ended, "end already called");
        require(winning != address(0), "no bids");
        require(!live(), "Auction live");

        // transfer erc721 to winner
        nftContract.safeTransferFrom(tokenHolder, winning, tokenId); // Will transfer ERC721 from current owner to new owner

        uint256 halfSeenFee = lastBid.mul(stakingRewardPercentageBasisPoints).div(10000);

        (bool stakingRewardSuccess, ) = stakingSwapContract.call{value: halfSeenFee}("");
        require(stakingRewardSuccess, "Seen Staking transfer failed.");

        (bool successMultisig, ) = hausAddress.call{value: halfSeenFee}("");
        require(successMultisig, "Seen Multisig transfer failed.");

        (bool successPropy, ) = tokenHolder.call{value: address(this).balance}("");
        require(successPropy, "Propy payout transfer failed.");

        ended = true;
        emit Won(winning, lastBid);
    }

    function isBidderWhitelisted(address _bidder) public view returns(bool) {
      return ethAddressWhitelistContract.isWhitelisted(_bidder);
    }

    function withdrawEthCredits() external {
      uint256 currentCredits = ethCredits[msg.sender];
      require(currentCredits > 0, "no outstanding credits");
      ethCredits[msg.sender] = 0;
      (bool returnEthCredits, ) = msg.sender.call{value: currentCredits}("");
      require(returnEthCredits, "failed to withdraw credits");
    }
    
    function live() public view returns(bool) {
        return block.timestamp < endTime;
    }

    function setStartPrice(uint256 _reservePriceWei) external {
      require(msg.sender == deployer, "can only be set by deployer");
      require(winning == address(0), "can only be set before bidding has started");
      lastBid = _reservePriceWei;
    }

    function setControllerAddress(address _controller) external {
      require(msg.sender == deployer, "can only be set by deployer");
      controller = _controller;
    }

    function setTokenHolderAddress(address _tokenHolder) external {
      require(msg.sender == deployer, "can only be set by deployer");
      tokenHolder = _tokenHolder;
    }
    
    function onERC721Received(address, address, uint256, bytes memory) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}