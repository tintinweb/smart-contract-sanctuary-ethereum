// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";

contract BFYCPresale is Ownable {
    using Address for address payable;
    
    IERC20 public token;
    address public payee;
    address public creator;
    address public operator;
    
    bool public swapStatus;
    bool public canClaim;
    bool public isWhiteListEnabled;
    bool public cancelled;

    uint256 public swapRate; //Tokens to be swapped per BNB
    uint256 public launchRate; // Tokens per BNB for LP
    uint256 public totalSold; // Total tokens sold
    uint256 public decimalsModifier;
    uint256 public minBuy; // Minimum BNBs to be purchased
    uint256 public maxBuy; // Maximum BNBs to be purchased
    uint256 public softCap; // Minimum BNBs to be raised for finalizing presale
    uint256 public hardCap; // Maximum BNBs to be raised
    uint256 public startTime; // Presale Start time
    uint256 public endTime; // Presale End Time
    uint256 public percentFundsToAddToLP;

    uint256 public totalRaised;
    
    mapping (address => uint256) public spent;
    mapping (address => uint256) public owed;
    mapping (address => uint256) public claimed;
    mapping(address => bool) public isWhiteListed;

    string public tokenLogo;
    string public telegram;
    string public website;
    string public twitter;
    string public reddit;
    string public github;
    string public instagram;

    struct presaleInfo {
        string tokenLogo;
        string telegram;
        string website;
        string twitter;
        string reddit;
        string github;
        string instagram;
        bool isWhiteListEnabled;
        bool cancelled;
    }

    event AddedToWhiteList(address indexed whitelistAddress);
    event RemovedFromWhiteList(address indexed removedAddress);
    event Swap (address indexed user, uint256 inAmount, uint256 owedAmount);
    event Claim (address indexed user, uint256 amount);
    event PayeeTransferred (address indexed previousPayee, address indexed newPayee);
    event refundClaimed (address indexed user, uint256 refundAmount);

    constructor (address _operator) {
        operator = _operator;
        payee = msg.sender;
    }

    modifier onlyOwnerOrOperator {
        require(msg.sender == operator || msg.sender == owner(), "TokenPresale: only accessible by operator or owner");
        _;
    }

    function createPresale(
        address _creator, 
        IERC20 _token, 
        uint256 _swapRate,
        uint256 _launchRate, 
        uint256 _minBuy, 
        uint256 _maxBuy, 
        uint256 _softCap, 
        uint256 _hardCap, 
        uint256 _startTime, 
        uint256 _endTime,
        uint256 _percentFundsToAddToLP, 
        bool doSafetyCheck) external onlyOwnerOrOperator {
        require (address(_token) != address(0), "Error: Can't set token to zero address");
        require (_creator != address(0), "Error: Can't set payee to zero address");
        require (_startTime >= block.timestamp, "TokenPresale: opening time can't be in the past"); // solhint-disable-line not-rely-on-time
        require (_endTime > _startTime, "TokenPresale: closing time can't be before opening time");
        require (_percentFundsToAddToLP >= 70, "Alert! You need to add at least 70% of raised funds to LP!");
        require(!cancelled, "Error: Can't recreate a cancelled presale!");

        if (doSafetyCheck) {
            require (IERC20(_token).balanceOf(address(this)) >= (_launchRate * ((_percentFundsToAddToLP * _hardCap)/100)) +  (_hardCap * _swapRate), 
                "Error: Not enough tokens owned to create presale. Deposit tokens to presale contract before calling this function");
        }

        token = _token;
        creator = _creator;
        swapRate = _swapRate;
        launchRate = _launchRate;
        minBuy = _minBuy;
        maxBuy = _maxBuy;
        softCap = _softCap;
        hardCap = _hardCap;
        startTime = _startTime;
        endTime = _endTime;
        percentFundsToAddToLP = _percentFundsToAddToLP;
        swapStatus = true;
        decimalsModifier = 10**18 * 10**_token.decimals();
    }

    function configurePresale(
        bool _isWhiteListEnabled,
        string memory logo,
        string memory _telegram,
        string memory _website,
        string memory _twitter,
        string memory _reddit,
        string memory _github,
        string memory _instagram) external onlyOwnerOrOperator {            
        require(!cancelled, "Error: Can't configure a cancelled presale!");
        isWhiteListEnabled = _isWhiteListEnabled;
        tokenLogo = logo;
        telegram = _telegram;
        website = _website;
        twitter = _twitter;
        reddit = _reddit;
        github = _github;
        instagram = _instagram;
    }

    function cancelPresale() external onlyOwnerOrOperator {
        require (totalRaised < softCap, "TokenPresale: SoftCap has been reached, can't be cancelled now!");
        require(!cancelled, "Error: Presale already cancelled!");
        
            cancelled = true; // if we've already received payment then we need to officially cancel so refunds can be claimed. Cancelled presale contracts can't be re-used.
        
            swapRate = 0; 
            creator = address(0); 
            hardCap = 0; 
            softCap = 0;
            minBuy = 0;
            maxBuy = 0; 
            startTime = 0;
            endTime = 0;
    }

    function swap() external payable {
        require(startTime <= block.timestamp, "Error: Presale has not begun yet!");
        require(swapStatus == true, "Error: Swap disabled!");
        require(spent[msg.sender] + msg.value <= maxBuy, "Error: Reached Max Buy, can't buy more from this wallet!");
        require(!isWhiteListEnabled || isWhiteListed[_msgSender()],"Error: you are not whitelisted");
        require(totalRaised < hardCap, "Alert: HardCap reached!");
        require(!cancelled, "Error: Can't participate in a cancelled presale!");

        uint256 quota = token.balanceOf (address(this));
        uint256 outAmount = (msg.value * swapRate * decimalsModifier) / 10**36;

        require (totalSold + outAmount <= quota, "Error: Not enough tokens remaining");
        
        totalSold += outAmount;
        totalRaised += msg.value;
        // payable(payee).sendValue (msg.value);
        spent[msg.sender] += msg.value;
        owed[msg.sender] += outAmount;
        emit Swap (msg.sender, msg.value, outAmount);
    }

    function claim() external {
        require (canClaim == true, "Error: Presale hasn't been finalized yet");
        require(!cancelled, "Error: Can't claim tokens from a cancelled presale!");
        uint256 quota = token.balanceOf (address(this));
        uint256 owedNow = owed[msg.sender];

        if (owedNow > owed[msg.sender])
            owedNow = owed[msg.sender];

        require (owedNow - claimed[msg.sender] <= quota, "Error: Not enough tokens remaining");
        require (owedNow - claimed[msg.sender] > 0, "Error: No tokens left to claim");

        uint256 amount = owedNow - claimed[msg.sender];
        claimed[msg.sender] = owedNow;
        token.transfer (msg.sender, amount);

        emit Claim (msg.sender, amount);
    }

    // Used to claim a refund if the presale is unsuccessful
    // Users should be aware that if the payment token has transfer taxes they will receive less than they sent by 2 x the transfer tax
    function claimRefund() public {
        require (cancelled, "TokenPresale: not cancelled, try calling cancel before claiming refund");
        uint256 refundAmount = spent[msg.sender];
        if(refundAmount > 0)
        _msgSender().transfer(refundAmount);

        emit refundClaimed(msg.sender, refundAmount);
    }

    function switchToPublicPresale(bool) external onlyOwnerOrOperator{
        require(hardCap > totalRaised, "Error: Can't change whitelisted presale to public after successful presale!");
        require(isWhiteListEnabled == true, "Error: Can't change public presale to whitelisted presale!");
        isWhiteListEnabled= false;
    }

    function isHardCapReached() public view returns (bool) {
        return hardCap <= totalRaised;
    }

    function isSoftCapReached() public view returns (bool) {
        return softCap <= totalRaised;
    }

    function addToWhitelist(address[] memory _address) external onlyOwnerOrOperator{
        for (uint256 i = 0; i < _address.length; i++) {
            if (!isWhiteListed[_address[i]]) {
                isWhiteListed[_address[i]] = true;
                emit AddedToWhiteList(_address[i]);
            }
        }
    }

    function removeFromWhitelist(address _address) external onlyOwnerOrOperator{
        require(isWhiteListed[_address],"Error : address is not whitelisted");
        isWhiteListed[_address] = false;
        emit RemovedFromWhiteList(_address);
    }

    function isSwapStarted () public view returns (bool) {
        return startTime <= block.timestamp;
    }

    function editPresaleTiming(uint256 newStartTime, uint256 newEndTime) external onlyOwnerOrOperator {
        require(startTime > block.timestamp, "Error: Can't modify an already live presale!");
        startTime = newStartTime;
        endTime = newEndTime;
    }

    function extendPresale(uint256 newEndTime) external onlyOwnerOrOperator {
        require(newEndTime >= startTime, "Error: End time has to bre greater than the start time!");
        endTime = newEndTime;
    }

    function finalize (bool _canClaim) external onlyOwnerOrOperator {
        require(softCap <= totalRaised, "Error: Can't finalize before Soft Cap is met!");
        canClaim = _canClaim;
        swapStatus = false;
    }

    function changeSwapRate (uint256 newRate) external onlyOwner {
        require(startTime > block.timestamp, "Error: Can't modify swap rate after presale has begun!");
        swapRate = newRate;
    }

    function setMinBuy (uint newMin) external onlyOwnerOrOperator {
        require(startTime > block.timestamp, "Error: Can't modify swap rate after presale has begun!");
        minBuy = newMin;
    }
    
    function setMaxBuy (uint256 newMax) external onlyOwnerOrOperator {
        require(startTime > block.timestamp, "Error: Can't modify swap rate after presale has begun!");
        maxBuy = newMax;
    }
    
    function transferPayee (address newPayee) external onlyOwner {
        require (newPayee != address(0), "Error: Can't set payee to zero address");
        emit PayeeTransferred (payee, newPayee);
        payee = newPayee;
    }

   function transferBNB() external onlyOwner {
        payable(payee).sendValue (address(this).balance);
    }

    function withdrawOtherTokens(address _token, uint256 amount) external onlyOwnerOrOperator {
        IERC20(_token).transfer (msg.sender, amount);
    }

    function numTokensToAddToLP() public view returns(uint256) {
        return launchRate * (hardCap * percentFundsToAddToLP /100);
    }
}