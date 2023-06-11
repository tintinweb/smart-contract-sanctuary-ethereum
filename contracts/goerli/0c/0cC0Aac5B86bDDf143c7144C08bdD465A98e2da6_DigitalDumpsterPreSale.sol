pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT

// WEBSITE DIGITALDUMPSTER.XYZ 
// TWITTER @TRASHCOINETH
// DEVELOPED BY @DREYKNOWSCRYPTO

import "ReentrancyGuard.sol";
import "SafeMath.sol";
import "IERC20.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract DigitalDumpsterPreSale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public _contributions;
    mapping(address => uint256) public claimedTokens;
    mapping(address => uint256) public lastClaimed;

    IERC20 public _token;
    uint256 private _tokenDecimals;
    address payable public _wallet;
    uint256 public startDate;
    uint256 public startICODate;
    uint256 public _weiRaised;
    uint256 public minPurchase = 0.05 ether;
    uint256 public maxPurchase = 0.5 ether;
    uint256 public softCap = 30 ether;
    uint256 public hardCap = 300 ether;
    uint256 public availableTokensICO = 14000000 * (10**18); // Assuming TRASH has 18 decimals
    uint256 public refundStartDate;
    uint256 public endICO;
    bool public startRefund = false;
    mapping(address => bool) public airdropRecipients;
    address[] public airdropAddresses;
    uint256 public numRecipients;

    event AirdropAdded(address indexed recipient);
    event AirdropDistributed(address indexed recipient, uint256 amount);
    event TokensPurchased(address purchaser, address beneficiary, uint256 value, uint256 amount);
    event Refund(address recipient, uint256 amount);

    modifier icoActive() {
        require(endICO > 0 && block.timestamp >= startDate && block.timestamp < endICO, "ICO must be active");
        _;
    }

    modifier icoNotActive() {
        require(endICO == 0 || block.timestamp >= endICO, "ICO must not be active");
        _;
    }

    modifier icoNotStarted() {
        require(block.timestamp < startDate || startDate == 0, "ICO must not have started");
        _;
    }

    constructor (
        address payable wallet,
        address tokenAddress,
        uint256 tokenDecimals
    ) {
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(tokenAddress != address(0), "Pre-Sale: token is the zero address");
        
        _wallet = wallet;
        _token = IERC20(tokenAddress);
        _tokenDecimals = tokenDecimals;
    }

    receive () external payable {
        if (endICO > 0 && block.timestamp < endICO) {
            buyTokens(_msgSender());
        } else {
            endICO = 0;
            revert('Pre-Sale is closed');
        }
    }

    function startICO(uint _startDate, uint _endDate) external onlyOwner icoNotActive icoNotStarted {
        require(_startDate > block.timestamp, 'start date should be in the future');
        require(_endDate > _startDate, 'end date should be after start date');
        startDate = _startDate;
        endICO = _endDate;
        _weiRaised = 0;
        startRefund = false;
        refundStartDate = 0;
        availableTokensICO = _token.balanceOf(address(this));
    }

 function stopICO() external onlyOwner {
    require(endICO != 0, "ICO is already stopped");
    endICO = 0;
    if (_weiRaised >= softCap) {
        _forwardFunds();
    } else {
        startRefund = true;
        refundStartDate = block.timestamp;
    }
}

    function buyTokens(address beneficiary) public nonReentrant icoActive payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        availableTokensICO = availableTokensICO.sub(tokens);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(_contributions[beneficiary].add(weiAmount) <= maxPurchase, 'can\'t buy more than: maxPurchase');
        require((_weiRaised.add(weiAmount)) <= hardCap, 'Hard Cap reached');
        require(block.timestamp >= startDate && block.timestamp <= endICO, "ICO is not active");
    }

function claimTokens() public nonReentrant icoNotActive returns (bool) {
    uint256 totalPercentageClaimed = claimedTokens[msg.sender];
    require(totalPercentageClaimed < 100, "Already claimed 100% of allocation");
    require(lastClaimed[msg.sender] + 1 days <= block.timestamp, "Must wait 24 hours between claims");

    uint256 totalTokensPurchasedByUser = totalAllocation(msg.sender);

    uint256 tokensToClaim;
    uint256 percentageToClaim;
    if (totalPercentageClaimed == 0) {
        percentageToClaim = 50;
    } else {
        percentageToClaim = 10;
    }
    
    tokensToClaim = totalTokensPurchasedByUser.mul(percentageToClaim).div(100);

    claimedTokens[msg.sender] = totalPercentageClaimed.add(percentageToClaim);
    lastClaimed[msg.sender] = block.timestamp;

    bool sent = _token.transfer(msg.sender, tokensToClaim);
    require(sent, "Token transfer failed");
    return true;
}

function canClaim(address user) public view returns (bool) {
    return (lastClaimed[user] + 1 days <= block.timestamp);
}

function claimedAll(address user) public view returns (bool) {
    return (claimedTokens[user] >= 100);
}


    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_weiRaised).div(10 ** _tokenDecimals);
    }

    function _forwardFunds() internal {
        _wallet.transfer(_weiRaised);
        uint256 totalTokens = _token.balanceOf(address(this));
        uint256 tokensToOwner = totalTokens.mul(48).div(100);
        _token.transfer(_wallet, tokensToOwner);
    }

    function checkContribution(address addr) public view returns(uint256) {
        return _contributions[addr];
    }

    function setAvailableTokens(uint256 amount) public onlyOwner icoNotActive {
        availableTokensICO = amount;
    }

    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    function setWalletReceiver(address payable newWallet) external onlyOwner {
        _wallet = newWallet;
    }

    function setHardCap(uint256 value) external onlyOwner {
        hardCap = value;
    }

    function setSoftCap(uint256 value) external onlyOwner {
        softCap = value;
    }

    function setMaxPurchase(uint256 value) external onlyOwner {
        maxPurchase = value;
    }

    function setMinPurchase(uint256 value) external onlyOwner {
        minPurchase = value;
    }

    function isICOActive() public view returns (bool) {
    return endICO > 0 && block.timestamp >= startDate && block.timestamp < endICO;
}

function totalAllocation(address user) public view returns (uint256) {
    uint256 totalTokensForSale = 14000000 * (10 ** 18);
    uint256 userContribution = _contributions[user];

    return totalTokensForSale.mul(userContribution).div(_weiRaised);
}

function unclaimedTokens(address user) public view returns (uint256) {
    uint256 totalTokensForSale = 14000000 * (10 ** 18);
    uint256 userContribution = _contributions[user];

    uint256 totalTokensPurchasedByUser = totalTokensForSale.mul(userContribution).div(_weiRaised);
    uint256 tokensRemaining = totalTokensPurchasedByUser.sub(claimedTokens[user]);

    return tokensRemaining;
}

function claimedTokensAmount(address user) public view returns (uint256) {
    return claimedTokens[user];
}

    function takeTokens(IERC20 tokenAddress) public onlyOwner icoNotActive returns (bool) {
        IERC20 tokenBEP = tokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, 'BEP-20 balance is 0');
        bool sent = tokenBEP.transfer(_wallet, tokenAmt);
        require(sent, "Token transfer failed");
        return true;
    }

    function refundMe() public icoNotActive {
        require(startRefund == true, 'no refund available');
        uint256 amount = _contributions[msg.sender];
        if (address(this).balance >= amount) {
            _contributions[msg.sender] = 0;
            if (amount > 0) {
                address payable recipient = payable(msg.sender);
                recipient.transfer(amount);
                emit Refund(msg.sender, amount);
            }
        }
    }

    function addAirdropRecipients(address[] memory recipients) public onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            if (!airdropRecipients[recipients[i]]) {
                airdropRecipients[recipients[i]] = true;
                airdropAddresses.push(recipients[i]);
                numRecipients++;
                emit AirdropAdded(recipients[i]);
            }
        }
    }

    function distributeAirdrop() public onlyOwner {
        require(numRecipients > 0, "No recipients for airdrop");
        uint256 totalAirdrop = _token.balanceOf(address(this)).mul(2).div(100);
        require(_token.balanceOf(address(this)) >= totalAirdrop, "Insufficient tokens for airdrop");

        uint256 amountPerRecipient = totalAirdrop.div(numRecipients);

        for (uint256 i = 0; i < airdropAddresses.length; i++) {
            if (airdropRecipients[airdropAddresses[i]]) {
                _token.transfer(airdropAddresses[i], amountPerRecipient);
                emit AirdropDistributed(airdropAddresses[i], amountPerRecipient);
                airdropRecipients[airdropAddresses[i]] = false;
            }
        }

        delete airdropAddresses;
        numRecipients = 0;
    }

    function withdrawTRASH() external onlyOwner icoNotActive {
        uint256 tokenBalance = _token.balanceOf(address(this));
        require(tokenBalance > 0, 'Contract has no TRASH balance');
        _token.transfer(_wallet, tokenBalance);
    }

    function withdrawETH() external onlyOwner {
        require(address(this).balance > 0, 'Contract has no ETH balance');
        _wallet.transfer(address(this).balance);
    }
}