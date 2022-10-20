/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.15;
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {    
    function totalSupply() external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address internal _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }    
    function owner() public view virtual returns (address) {
        return _owner;
    }    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock.");
        require(block.timestamp > _lockTime , "Contract is locked.");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }
}

interface VRFCoordinatorV2Interface {
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);
  function createSubscription() external returns (uint64 subId);
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;
  function addConsumer(uint64 subId, address consumer) external;
  function removeConsumer(uint64 subId, address consumer) external;
  function cancelSubscription(uint64 subId, address to) external;
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;
  
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

contract ottto is IERC20, Ownable, ReentrancyGuard, VRFConsumerBaseV2 {
    using SafeMath for uint256;

    // Chainlink VRF variables
    VRFCoordinatorV2Interface COORDINATOR;

    // Mainnet: 312
    uint64 s_subscriptionId = 312;
    // Mainnet: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    // Mainnet: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
    bytes32 public keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;

    uint32 public callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 public numWords = 3;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;
    address public lastMsgSender;
    IDEXRouter public v2Router;
    address public v2Pair;
    uint256 private constant maxUint256 = ~uint256(0);
    uint256 private tax = 10;
    bool private taxOn = true;
    bool private growPotEnabled = true;
    bool public autoWin = true;
    bool private inSwap = false;
    address private routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;        
    mapping (address => bool) private excluded;
    uint256 public activeRound;
    uint256 public calculatingRound;
    bool public chainlinkActive;
    uint256 public totalTickets;
    uint256 public totalPayout;

    struct user {
        uint256 tokens;
        string ottoTicket;
        bool exists;
    }

    struct ottoTicket {
        uint256 ottoTicket;
        address user;
        uint256 round;
        uint256 created;
        bool winner;
        uint256 tokens;
        uint256 ethWon;
    }

    struct round {
        uint256 eth;
        uint256 totalAmt;
        uint256 expire;  
        bool launched;
        bool completed;
        bool calculatingResults;
        uint256 ticketCount;
    }

    mapping (uint256 => ottoTicket[]) ottoTickets;
    mapping(address => uint256[]) userTickets;
    mapping(address => mapping(uint256 => uint256)) public userTicketCount;  
    mapping (address => uint256) _balances;
    mapping (address => bool) isFeeExempt;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    mapping (uint256 => round) public rounds;
    mapping (address => uint256) public lastUserBlock;
    mapping(address => mapping(address => uint256)) private _allowances;
    address chainlink; 
    uint256 chainlinkPercent;
    uint256 nextRoundPercent = 10;
    string constant _name = "ottto.io";
    string constant _symbol = "OTTTO";
    uint8 constant _decimals = 6;
    uint256 _totalSupply = 1e9 * (10 ** _decimals);
    uint256 public maxTicketQuantity = _totalSupply.mul(1).div(100); // 1% Max Transaction Amount
    uint256 public maxTicketsPerRound = 10;
    uint256 public maxTokensForSwap = _totalSupply.mul(1).div(1000); // .1% Supply 
    uint256 public roundDuration = 96 hours;
    uint256 public launchTime;
    
    // Events
    event BoughtOtto(address to, uint256 ottoTicket, uint256 round, uint256 tokenAmt, uint256 created);
    event SoldEarly(uint256 ottoTicket);
    event WinningTicket(address to, uint256 ottoTicket, uint256 payout, uint256 round, uint256 created, uint8 position, uint256 roundEth);

    constructor (address _chainlink, uint256 _chainpercent) VRFConsumerBaseV2(vrfCoordinator) {

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;

        v2Router = IDEXRouter(routerAddress);
        v2Pair = IDEXFactory(v2Router.factory()).createPair(v2Router.WETH(), address(this));

        _allowances[msg.sender][address(v2Router)] = type(uint256).max;
        _allowances[address(this)][address(v2Router)] = type(uint256).max;
        _allowances[msg.sender][address(v2Pair)] = type(uint256).max;
        _allowances[address(this)][address(v2Pair)] = type(uint256).max;
        _allowances[address(this)][address(vrfCoordinator)] = type(uint256).max;

        chainlink = _chainlink;  
        chainlinkPercent = _chainpercent;

        isFeeExempt[msg.sender] = true;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);       
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;        
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {  
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
         // Complete Round and Declare Winners
        if (rounds[activeRound].expire < block.timestamp && rounds[activeRound].launched && !rounds[activeRound].completed && autoWin && !inSwap)
        {
            PayTheWinners();
        }  

        if(inSwap){ return _basicTransfer(sender, recipient, amount);}
        if(shouldGrowPot()){growPot();} 
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = isBuyingOtto(sender, recipient) ? buyOtto(sender, amount, recipient) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived); 

        // To prevent bad faith trading, if tokens are sold or transferred, all previous tickets for activeRound are zeroed out
        if (recipient == v2Pair || (sender != v2Pair && recipient != v2Pair)) {
            clearPreviousTicketsofCurrentRound(sender);
        }     

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }    

    // CUSTOM FUNCTIONS
    function clearPreviousTicketsofCurrentRound(address sender) internal {
        uint256 _cnt = userTicketCount[sender][activeRound];
        for (uint256 i=0; i < _cnt; i++) {
            ottoTickets[activeRound][userTickets[sender][i]].tokens = 0;
            emit SoldEarly(ottoTickets[activeRound][userTickets[sender][i]].ottoTicket);
        }
        userTicketCount[sender][activeRound] = 0;
    }

    function setchainlink(address _val) external onlyOwner {
        chainlink = _val;
    }

    function toggleChainlink() external onlyOwner {
        chainlinkActive = !chainlinkActive;
    }

    function isBuyingOtto(address sender, address recipient) internal view returns (bool) {
        return sender == v2Pair &&
               recipient != owner() &&
               recipient != address(0) &&
               recipient != address(0xdead);
    }

    function buyOtto(address sender, uint256 amount, address recipient) internal returns (uint256) {
        uint256 ottoTax = amount.mul(tax).div(100);
        _balances[address(this)] = _balances[address(this)].add(ottoTax);
        if (ottoTax > 0) {
                //require(lastUserBlock[recipient] != block.number, "Cannot have multiple buys on same block");
                require(userTicketCount[recipient][activeRound] < maxTicketsPerRound, "Ticket Limit per Round exceeded");
                require(amount <= maxTicketQuantity, "Exceeds Maximum Ticket Quantity");

                // Launch Lottery on first buy.  Will execute once.
                if (!rounds[0].launched) {
                    rounds[0].launched = true;
                    rounds[0].expire = block.timestamp + roundDuration;
                    launchTime = block.timestamp;
                }

                // Clear User Tickets on new round
                if (userTicketCount[recipient][activeRound] == 0) {
                    uint256[] memory _clearUserTickets;
                    userTickets[recipient] = _clearUserTickets;
                }

                rounds[activeRound].totalAmt = rounds[activeRound].totalAmt + ottoTax;
                rounds[activeRound].ticketCount = rounds[activeRound].ticketCount + 1;

                // Create otto ticket
                uint256[] storage _userTickets = userTickets[recipient];
                _userTickets.push(ottoTickets[activeRound].length);
                userTickets[recipient] = _userTickets;

                userTicketCount[recipient][activeRound] = userTicketCount[recipient][activeRound] + 1;
                uint256 ticketCount = totalTickets + 1;

                ottoTicket memory _ottoTicket;
                _ottoTicket.ottoTicket =  ticketCount;
                _ottoTicket.round = activeRound;
                _ottoTicket.created = block.timestamp;
                _ottoTicket.user = recipient;
                _ottoTicket.tokens = amount;
                ottoTickets[activeRound].push(_ottoTicket);
                lastUserBlock[recipient] = block.number;   

                totalTickets = ticketCount;                  

                emit BoughtOtto(recipient, ticketCount, activeRound, amount, block.timestamp);            
            }  

        emit Transfer(sender, address(this), ottoTax);
        return amount.sub(ottoTax);
    }

    function getUserTickets(address _user) public view returns (uint256[] memory) {
        return userTickets[_user];
    }

    function shouldGrowPot() internal view returns (bool) {
        return 
        msg.sender != v2Pair
        && !inSwap
        && growPotEnabled
        ;
    }

    function growPot() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = v2Router.WETH();

        uint256 roundTokens = rounds[activeRound].totalAmt;
        roundTokens > maxTokensForSwap ? roundTokens = maxTokensForSwap : 0;
        if (roundTokens > 0 && growPotEnabled) {            
            uint256 beforeEth = address(this).balance;
            v2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                roundTokens,
                0,
                path,
                address(this),
                block.timestamp
            );     

            rounds[activeRound].totalAmt = rounds[activeRound].totalAmt - roundTokens;  
            uint256 nextRound = activeRound + 1;
            uint256 afterEth = address(this).balance.sub(beforeEth);
            uint256 potEth = afterEth.mul(100-chainlinkPercent).div(100);            
            uint256 nextRoundEth = potEth.mul(nextRoundPercent).div(100);                      
            rounds[activeRound].eth = rounds[activeRound].eth + potEth - nextRoundEth;
            rounds[nextRound].eth = rounds[nextRound].eth + nextRoundEth;
            payable(chainlink).transfer(afterEth - potEth);
        }        
    }

    // Anyone can call Grow The Pot to sell otto tax tokens for ETH and fund the current jackpot
    function growPotPublic() swapping isHuman nonReentrant public {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = v2Router.WETH();

        uint256 roundTokens = rounds[activeRound].totalAmt;        
        if (roundTokens > 0 && growPotEnabled) {      
            _allowances[address(this)][address(msg.sender)] = roundTokens;      
            uint256 beforeEth = address(this).balance;
            v2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                roundTokens,
                0,
                path,
                address(this),
                block.timestamp
            );     
            rounds[activeRound].totalAmt = rounds[activeRound].totalAmt - roundTokens;  
            uint256 nextRound = activeRound + 1;
            uint256 afterEth = address(this).balance.sub(beforeEth);
            uint256 potEth = afterEth.mul(100-chainlinkPercent).div(100);            
            uint256 nextRoundEth = potEth.mul(nextRoundPercent).div(100);                      
            rounds[activeRound].eth = rounds[activeRound].eth + potEth - nextRoundEth;
            rounds[nextRound].eth = rounds[nextRound].eth + nextRoundEth;
            payable(chainlink).transfer(afterEth - potEth);
        }        
    }

    // Called immediately before closing the round to maximize ETH for winners
    function growThePotByRound(uint256 _round) internal swapping  {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = v2Router.WETH();

        uint256 roundTokens = rounds[_round].totalAmt;        
        if (roundTokens > 0 && growPotEnabled) {     
            _allowances[address(this)][address(msg.sender)] = roundTokens; 
            _allowances[address(msg.sender)][address(v2Router)] = roundTokens;           
            uint256 beforeEth = address(this).balance;
            v2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                roundTokens,
                0,
                path,
                address(this),
                block.timestamp
            );     
            rounds[_round].totalAmt = rounds[_round].totalAmt - roundTokens;  

            uint256 nextRound = _round + 1;

            uint256 afterEth = address(this).balance.sub(beforeEth);
            uint256 potEth = afterEth.mul(100-chainlinkPercent).div(100);            
            uint256 nextRoundEth = potEth.mul(nextRoundPercent).div(100);
                      
            rounds[_round].eth = rounds[_round].eth + potEth - nextRoundEth;
            rounds[nextRound].eth = rounds[nextRound].eth + nextRoundEth;
            payable(chainlink).transfer(afterEth - potEth);
        }
    }
    
    function PayTheWinners() internal  {
        // Call Chainlink Verifiable Randomness Function generator. https://vrf.chain.link
        // Callback function fulfillRandomWords() will choose winners and pay out ETH.   
        calculatingRound = activeRound;
        rounds[activeRound].completed = true;
        rounds[activeRound].calculatingResults = true;
        chainlinkActive = true;   
        
        //Start Next Round
        uint256 newRound = activeRound + 1;    
        activeRound = newRound;
        rounds[activeRound].launched = true;
        rounds[activeRound].expire = block.timestamp + roundDuration;
        launchTime = block.timestamp;

        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function testChainLink() public onlyOwner  {
        // Call Chainlink Verifiable Randomness Function generator. https://vrf.chain.link
        // Callback function fulfillRandomWords() will choose winners and pay out ETH for calculatingRound.   
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        ); 
    }

    function setCallbackGasLimit(uint32 _val) external onlyOwner {
        callbackGasLimit = _val;
    }

    function setGasKeyHash(bytes32 _val) external onlyOwner {
        keyHash = _val;
    }

    function setNextRoundPercent(uint256 _val) external onlyOwner {
        nextRoundPercent = _val;
    }    

    function setSubscriptionId(uint64 _val) external onlyOwner {
        s_subscriptionId = _val;
    }

    function setWords(uint32 _val) external onlyOwner {
        numWords = _val;
    }

    function setTaxRate(uint256 _val) external onlyOwner {
        require(tax <= 12 && tax > 0, "Exceeds tax rate limit");
        tax = _val;
    }

    function setMaxTicketQuantity(uint256 _val) external onlyOwner {
        maxTicketQuantity = _val;
    }

    function setMaxTicketsPerRound(uint256 _val) external onlyOwner {
        maxTicketsPerRound = _val;
    }

    function getTaxRate() public view returns (uint256) {
        return tax;
    }

    function setDuration(uint256 val) external onlyOwner {
        roundDuration = val;
    }

    function setActiveRound(uint256 val) external onlyOwner {
        activeRound = val;
    }

    function setMaxTokensForSwap(uint256 val) external onlyOwner {
        maxTokensForSwap = val;
    }

    function toggleTaxOn() external onlyOwner {
        taxOn = !taxOn;
    }

    function getTaxOn() public view returns (bool) {
        return taxOn;
    }

    function togglePot() external onlyOwner {
        growPotEnabled = !growPotEnabled;
    }

    function getPot() public view returns (bool) {
        return growPotEnabled;
    }

    function toggleAutowWin() external onlyOwner {
        autoWin = !autoWin;
    }

    function ticketsCurrent() public view returns (uint256) {
        return ottoTickets[activeRound].length;
    }

    function setExcluded(address _val, bool exclude) external onlyOwner {
        excluded[_val] = exclude;
    }

    function rescueEth() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function rescueTokens(address _stuckToken, uint256 _amount) external onlyOwner {
        IERC20(_stuckToken).transfer(msg.sender, _amount);
    }

    function boostOtto(uint256 _round) external payable onlyOwner {
        rounds[_round].eth = rounds[_round].eth + msg.value;
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {       
        s_randomWords = randomWords;
        chainlinkActive = false;
        growThePotByRound(calculatingRound);  

        uint256 roundEth = rounds[calculatingRound].eth;
        if (ottoTickets[calculatingRound].length > 0 && roundEth > 0 && rounds[calculatingRound].completed && rounds[calculatingRound].calculatingResults) {

            rounds[calculatingRound].calculatingResults = false;
            totalPayout = totalPayout + roundEth;

            uint256 winnerIndex1 = randomWords[0] % ottoTickets[calculatingRound].length;
            uint256 winnerIndex2 = randomWords[1] % ottoTickets[calculatingRound].length;
            uint256 winnerIndex3 = randomWords[2] % ottoTickets[calculatingRound].length;

            ottoTicket memory winnerTicket1 = ottoTickets[calculatingRound][winnerIndex1];
            ottoTicket memory winnerTicket2 = ottoTickets[calculatingRound][winnerIndex2];
            ottoTicket memory winnerTicket3 = ottoTickets[calculatingRound][winnerIndex3];

            uint256 totalWinnerTokens = winnerTicket1.tokens + winnerTicket2.tokens + winnerTicket3.tokens;

            if (totalWinnerTokens > 0) {
                uint256 winner1ETH = roundEth.mul(winnerTicket1.tokens).div(totalWinnerTokens);
                uint256 winner2ETH = roundEth.mul(winnerTicket2.tokens).div(totalWinnerTokens);
                uint256 winner3ETH = roundEth.mul(winnerTicket3.tokens).div(totalWinnerTokens);
    
                // Pay winners
                payable(winnerTicket1.user).transfer(winner1ETH);
                payable(winnerTicket2.user).transfer(winner2ETH);
                payable(winnerTicket3.user).transfer(winner3ETH);   

                emit WinningTicket(winnerTicket1.user, winnerTicket1.ottoTicket, winner1ETH, calculatingRound, block.timestamp, 1, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket2.user, winnerTicket2.ottoTicket, winner2ETH, calculatingRound, block.timestamp, 2, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket3.user, winnerTicket3.ottoTicket, winner3ETH, calculatingRound, block.timestamp, 3, rounds[calculatingRound].eth);
            }
            else {
                emit WinningTicket(winnerTicket1.user, winnerTicket1.ottoTicket, 0, calculatingRound, block.timestamp, 1, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket2.user, winnerTicket2.ottoTicket, 0, calculatingRound, block.timestamp, 2, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket3.user, winnerTicket3.ottoTicket, 0, calculatingRound, block.timestamp, 3, rounds[calculatingRound].eth);
            }
        }  
        else {
            rounds[calculatingRound].calculatingResults = false;
        }
        delete ottoTickets[calculatingRound];
    }

    // Chainlink down.  Emergency payout call
    function fulfillRandomWordsExternal(uint256 randomWords) external onlyOwner {
        chainlinkActive = false;
        growThePotByRound(calculatingRound);  

        uint256 roundEth = rounds[calculatingRound].eth;
        if (ottoTickets[calculatingRound].length > 0 && roundEth > 0 && rounds[calculatingRound].completed && rounds[calculatingRound].calculatingResults) {

            rounds[calculatingRound].calculatingResults = false;
            totalPayout = totalPayout + roundEth;

            uint256 winnerIndex1 = randomWords % ottoTickets[calculatingRound].length;
            uint256 winnerIndex2 = randomWords.add(block.timestamp) % ottoTickets[calculatingRound].length;
            uint256 winnerIndex3 = randomWords.add(block.timestamp).add(block.timestamp) % ottoTickets[calculatingRound].length;

            ottoTicket memory winnerTicket1 = ottoTickets[calculatingRound][winnerIndex1];
            ottoTicket memory winnerTicket2 = ottoTickets[calculatingRound][winnerIndex2];
            ottoTicket memory winnerTicket3 = ottoTickets[calculatingRound][winnerIndex3];

            uint256 totalWinnerTokens = winnerTicket1.tokens + winnerTicket2.tokens + winnerTicket3.tokens;

            if (totalWinnerTokens > 0) {
                uint256 winner1ETH = roundEth.mul(winnerTicket1.tokens).div(totalWinnerTokens);
                uint256 winner2ETH = roundEth.mul(winnerTicket2.tokens).div(totalWinnerTokens);
                uint256 winner3ETH = roundEth.mul(winnerTicket3.tokens).div(totalWinnerTokens);
    
                // Pay winners
                payable(winnerTicket1.user).transfer(winner1ETH);
                payable(winnerTicket2.user).transfer(winner2ETH);
                payable(winnerTicket3.user).transfer(winner3ETH);   

                emit WinningTicket(winnerTicket1.user, winnerTicket1.ottoTicket, winner1ETH, calculatingRound, block.timestamp, 1, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket2.user, winnerTicket2.ottoTicket, winner2ETH, calculatingRound, block.timestamp, 2, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket3.user, winnerTicket3.ottoTicket, winner3ETH, calculatingRound, block.timestamp, 3, rounds[calculatingRound].eth);
            }
            else {
                emit WinningTicket(winnerTicket1.user, winnerTicket1.ottoTicket, 0, calculatingRound, block.timestamp, 1, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket2.user, winnerTicket2.ottoTicket, 0, calculatingRound, block.timestamp, 2, rounds[calculatingRound].eth);
                emit WinningTicket(winnerTicket3.user, winnerTicket3.ottoTicket, 0, calculatingRound, block.timestamp, 3, rounds[calculatingRound].eth);
            }        
        }
        else {
            rounds[calculatingRound].calculatingResults = false;
        }  
        delete ottoTickets[calculatingRound];
    }
}