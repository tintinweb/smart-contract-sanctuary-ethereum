/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

/*
Catopia
https://www.catopiatoken.com
https://www.t.me/catopiatoken
*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        //C U ON THE MOON
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IAntiSnipe {
  function setTokenOwner(address owner, address pair) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external returns (bool checked);
}

contract Catopia is IERC20, Ownable, VRFConsumerBaseV2 {
    using Address for address;
    
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Catopia";
    string constant _symbol = "Cats";
    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    uint256 constant _totalSupply = 1_000_000_000_000 * _decimalFactor;

    //For ease to the end-user these checks do not adjust for burnt tokens and should be set accordingly.
    uint256 public _maxTxAmount = (_totalSupply * 1) / 500; //0.2%
    uint256 public _maxWalletSize = (_totalSupply * 1) / 500; //0.2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => uint256) lastBuy;
    mapping (address => uint256) lastSell;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 public jackpotFee = 20; // kept for jackpot
    uint256 public stakingFee = 20; 
    uint256 public liquidityFee = 20;
    uint256 public marketingFee = 40;
    uint256 public devFee = 20;
    uint256 public totalFee = jackpotFee + marketingFee + devFee + liquidityFee + stakingFee;

    uint256 sellBias = 0;

    //Higher tax for a period of time from the first purchase on an address
    uint256 sellPercent = 200;
    uint256 sellPeriod = 48 hours;

    uint256 feeDenominator = 1000;

    struct userData {
        uint256 totalWon;
        uint256 lastWon;
    }
    
    struct lottery {
        uint48 transactionsSinceLastLottery;
        uint48 transactionsPerLottery;
        uint48 playerNewId;
        uint8 maximumWinners;
        uint64 price;
        uint16 winPercentageThousandth;
        uint8 w_rt;
        bool enabled;
        bool multibuy;
        uint256 created;
        uint128 maximumJackpot;
        uint128 minTxAmount;
        uint256[] playerIds;
        mapping(uint256 => address) players;
        mapping(address => uint256[]) tickets;
        uint256[] winnerValues;
        address[] winnerAddresses;
        string name;
    }
    
    mapping(address => userData) private userByAddress;
    uint256 numLotteries;
    mapping(uint256 => lottery) public lotteries;
    mapping (address => bool) private _isExcludedFromLottery;
    uint256 private activeLotteries = 0;
    uint256 private _allWon;
    uint256 private _txCounter = 0;

    address public immutable stakingReceiver;
    address payable public immutable marketingReceiver;
    address payable public immutable devReceiver;

    uint256 targetLiquidity = 40;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public immutable router;
    
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping (address => bool) liquidityPools;
    mapping (address => bool) liquidityProviders;

    address public immutable pair;

    uint256 public launchedAt;
 
    IAntiSnipe public antisnipe;
    bool public protectionEnabled = true;
    bool public protectionDisabled = false;

    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 s_subscriptionId = 25;
    address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    address link = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    bytes32 keyHash = 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 5;
    uint32 numWords =  1;
    mapping(uint256 => uint256[]) public s_randomWords;
    mapping(uint256 => uint256) public s_requestId;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 400; //0.25%
    uint256 public swapMinimum = _totalSupply / 10000; //0.01%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _newOwner, address _staking, address _marketing, address _dev) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);

        stakingReceiver = _staking;
        marketingReceiver = payable(_marketing);
        devReceiver = payable(_dev);

        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        liquidityPools[pair] = true;
        _allowances[_newOwner][routerAddress] = type(uint256).max;
        _allowances[address(this)][routerAddress] = type(uint256).max;
        
        isFeeExempt[_newOwner] = true;
        liquidityProviders[_newOwner] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[_newOwner] = true;
        isTxLimitExempt[routerAddress] = true;
        isTxLimitExempt[stakingReceiver] = true;

        _balances[_newOwner] = _totalSupply / 2;
        _balances[DEAD] = _totalSupply / 2;
        emit Transfer(address(0), _newOwner, _totalSupply / 2);
        emit Transfer(address(0), DEAD, _totalSupply / 2);
    }

    receive() external payable { }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(amount > 0, "Zero amount transferred");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        checkTxLimit(sender, amount);
        
        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) checkWalletLimit(recipient, amount);
        }

        if(!launched()){ require(liquidityProviders[sender] || liquidityProviders[recipient], "Contract not launched yet."); }
        else if(liquidityPools[sender]) { require(activeLotteries > 0, "No lotteries to buy."); }

        _balances[sender] -= amount;

        uint256 amountReceived = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(recipient)){ if (amount > 0) swapBack(amount); }
        
        _balances[recipient] += amountReceived;
            
        if(launched() && protectionEnabled)
            antisnipe.onPreTransferCheck(sender, recipient, amount);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(_balances[recipient] + amount <= walletLimit, "Transfer amount exceeds the bag size.");
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function getTotalFee(bool selling, bool inHighPeriod) public view returns (uint256) {
        if(launchedAt == block.number){ return feeDenominator - 1; }
        if (selling) return inHighPeriod ? (totalFee * sellPercent) / 100 : totalFee + sellBias;
        return inHighPeriod ? (totalFee * sellPercent) / 100 : totalFee - sellBias;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        bool highSellPeriod = !liquidityPools[sender] && lastBuy[sender] + sellPeriod > block.timestamp;

        uint256 feeAmount = (amount * getTotalFee(liquidityPools[recipient], highSellPeriod)) / feeDenominator;
        
        if (liquidityPools[sender] && lastBuy[recipient] == 0)
            lastBuy[recipient] = block.timestamp;
        else if(!liquidityPools[sender])
            lastSell[sender] = block.timestamp;

        uint256 staking = 0;
        if (stakingFee > 0) {
            staking = feeAmount * stakingFee / totalFee;
            feeAmount -= staking;
            _balances[stakingReceiver] += feeAmount;
            emit Transfer(sender, stakingReceiver, staking);
        }
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return amount - (feeAmount + staking);
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return !liquidityPools[msg.sender]
        && !isFeeExempt[msg.sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum &&
        totalFee > 0;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = ((amountToSwap * dynamicLiquidityFee) / (totalFee - stakingFee)) / 2;
        amountToSwap -= amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        //Guaranteed swap desired to prevent trade blockages
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractBalance = address(this).balance;
        uint256 totalETHFee = totalFee - (stakingFee + dynamicLiquidityFee / 2);

        uint256 amountLiquidity = (contractBalance * dynamicLiquidityFee) / totalETHFee / 2;
        uint256 amountMarketing = (contractBalance * marketingFee) / totalETHFee;
        uint256 amountDev = (contractBalance * devFee) / totalETHFee;

        if(amountToLiquify > 0) {
            //Guaranteed swap desired to prevent trade blockages, return values ignored
            router.addLiquidityETH{value: amountLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(amountLiquidity, amountToLiquify);
        }
        
        if (amountMarketing > 0)
            transferToAddressETH(marketingReceiver, amountMarketing);
            
        if (amountDev > 0)
            transferToAddressETH(devReceiver, amountDev);

    }

    function transferToAddressETH(address wallet, uint256 amount) internal {
        (bool sent, ) = wallet.call{value: amount}("");
        require(sent, "Failed to send ETH");
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(pair)) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function getBuysUntilJackpot(uint256 lotto) external view  returns (uint256) {
        return lotteries[lotto].transactionsPerLottery - lotteries[lotto].transactionsSinceLastLottery;
    }
    
    function getTotalEntries(uint256 lotto) external view  returns (uint256) {
        return lotteries[lotto].playerIds.length;
    }
    
    function getWinningChance(address addr, uint256 lotto) external view returns(uint256 myEntries, uint256 ineligibleEntries ,uint256 totalEntries) {
        require(addr != address(0), "Please enter valid address");
        uint256 entries = lotteries[lotto].tickets[addr].length;
        bool ineligible = lastSell[addr] >= lotteries[lotto].created;
        return (ineligible ? 0 : entries,ineligible ? entries : 0,lotteries[lotto].playerIds.length);
     }
    
    function getTotalWon(address userAddress) external view returns(uint256 totalWon) {
        return userByAddress[userAddress].totalWon;
    }

    function getLastWon(address userAddress) external view returns(uint256 lastWon) {
        return userByAddress[userAddress].lastWon;
    }

    function getTotalWon() external view returns(uint256) {
        return _allWon;
    }
    
    function getPotBalance() external view returns(uint256) {
        return address(this).balance;
    }
    
    function getLottoDetails(uint256 lotto) external view returns(
        string memory lottoName, uint256 transPerLotto, uint256 winPercent, 
        uint256 maxETH, uint256 minTx, uint256 price, bool isEnabled) 
    {
        return (lotteries[lotto].name,
        lotteries[lotto].transactionsPerLottery,
        lotteries[lotto].winPercentageThousandth / 10,
        lotteries[lotto].maximumJackpot,
        lotteries[lotto].minTxAmount,
        lotteries[lotto].price,
        lotteries[lotto].enabled);
    }
    
    function getLastWinner(uint256 lotto) external view returns (address, uint256) {
        return (lotteries[lotto].winnerAddresses[lotteries[lotto].winnerAddresses.length-1], lotteries[lotto].winnerValues[lotteries[lotto].winnerValues.length-1]);
    }
    
    function getWinnerCount(uint256 lotto) external view returns (uint256) {
        return (lotteries[lotto].winnerAddresses.length);
    }
    
    function getWinnerDetails(uint256 lotto, uint256 winner) external view returns (address, uint256) {
        return (lotteries[lotto].winnerAddresses[winner], lotteries[lotto].winnerValues[winner]);
    }

    function getLotteryCount() external view returns (uint256) {
        return numLotteries;
    }

    function createLotto(string memory lottoName, uint48 transPerLotto, uint16 winPercentThousandth, uint8 maxWin, uint128 maxEth, uint128 minTx, uint64 price, bool isEnabled, uint8 randomSelection, bool multiple) external onlyOwner() {
        lottery storage l = lotteries[numLotteries++];
        l.name = lottoName;
        l.transactionsSinceLastLottery = 0;
        l.transactionsPerLottery = transPerLotto;
        l.winPercentageThousandth = winPercentThousandth;
        l.maximumWinners = maxWin;
        l.maximumJackpot = maxEth * 10**18;
        l.minTxAmount = minTx;
        l.price = price;
        l.enabled = isEnabled;
        l.w_rt = randomSelection;
        l.multibuy = multiple;
        
        if (isEnabled) {
            activeLotteries++;
            l.created = block.timestamp;
        }
    }
    
    function setMaximumWinners(uint8 max, uint256 lotto) external onlyOwner() {
        lotteries[lotto].maximumWinners = max;
    }
    
    function setMaximumJackpot(uint128 max, uint256 lotto) external onlyOwner() {
        lotteries[lotto].maximumJackpot = max * 10**18;
    }

    function BuyTickets(uint48 number, uint256 lotto) external payable {
        require(!_isExcludedFromLottery[msg.sender], "Not eligible for lottery");
        require(msg.value == number * lotteries[lotto].price, "Not enough paid");
        require(lotteries[lotto].enabled, "Lottery not enabled");
        require(lotteries[lotto].transactionsSinceLastLottery + number <= lotteries[lotto].transactionsPerLottery, "Lottery full");
        require(_balances[msg.sender] >= lotteries[lotto].minTxAmount, "Not enough tokens held");
        require(lastSell[msg.sender] < lotteries[lotto].created, "Ineligible for this lottery due to token sale");
        if (number > 1)
            require(lotteries[lotto].multibuy, "Only ticket purchase at a time allowed");
        
        require(!msg.sender.isContract(), "Humans only");
        for (uint256 i=0; i < number; i++) {
            insertPlayer(msg.sender, lotto);
        }
        lotteries[lotto].transactionsSinceLastLottery += number;

        transferToAddressETH(owner(), msg.value/10);
    }

    function ShredTickets() external {
        uint256 number = lotteries[numLotteries-1].tickets[msg.sender].length / 5;
        require(number > 0, "Not enough tickets in previous lottery");
        require(lotteries[numLotteries].created > 0, "New lottery not ready yet");

        for (uint256 i=0; i < number; i++) {
            insertPlayer(msg.sender, numLotteries);
            for (uint256 popper=0; popper < 5; popper++)
                lotteries[numLotteries-1].tickets[msg.sender].pop();
        }
    }

    function setPrice(uint64 price, uint256 lotto) external onlyOwner() {
        lotteries[lotto].price = price;
    }
    
    function setMinTxTokens(uint128 minTxTokens, uint256 lotto) external onlyOwner() {
        lotteries[lotto].minTxAmount = minTxTokens;
    }
    
    function setTransactionsPerLottery(uint16 transactions, uint256 lotto) external onlyOwner() {
        lotteries[lotto].transactionsPerLottery = transactions;
    }
    
    function setWinPercentThousandth(uint16 winPercentThousandth, uint256 lotto) external onlyOwner() {
        lotteries[lotto].winPercentageThousandth = winPercentThousandth;
    }
    
    function setLottoEnabled(bool enabled, uint256 lotto) external onlyOwner() {
        if (enabled && !lotteries[lotto].enabled){
            activeLotteries++;
            lotteries[lotto].created = block.timestamp;
        } else if (!enabled && lotteries[lotto].enabled)
            activeLotteries--;

        lotteries[lotto].enabled = enabled;
    }
    
    function setRandomSelection(uint8 randomSelection, uint256 lotto) external onlyOwner() {
        lotteries[lotto].w_rt = randomSelection;
    }
    
    function setMultibuy(bool multiple, uint256 lotto) external onlyOwner() {
        lotteries[lotto].multibuy = multiple;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        isTxLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.transferOwnership(newOwner);
        isFeeExempt[newOwner] = true;
        isTxLimitExempt[newOwner] = true;
        liquidityProviders[newOwner] = true;
        _allowances[newOwner][routerAddress] = type(uint256).max;
    }

    function renounceOwnership() public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        isTxLimitExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.renounceOwnership();
    }

    function setProtectionEnabled(bool _protect) external onlyOwner {
        if (_protect)
            require(!protectionDisabled, "Protection disabled");
        protectionEnabled = _protect;
        emit ProtectionToggle(_protect);
    }
    
    function setProtection(address _protection, bool _call) external onlyOwner {
        if (_protection != address(antisnipe)){
            require(!protectionDisabled, "Protection disabled");
            antisnipe = IAntiSnipe(_protection);
        }
        if (_call)
            antisnipe.setTokenOwner(address(this), pair);
        
        emit ProtectionSet(_protection);
    }
    
    function disableProtection() external onlyOwner {
        protectionDisabled = true;
        emit ProtectionDisabled();
    }
    
    function setLiquidityProvider(address _provider) external onlyOwner {
        require(_provider != pair && _provider != routerAddress, "Can't alter trading contracts in this manner.");
        isFeeExempt[_provider] = true;
        liquidityProviders[_provider] = true;
        isTxLimitExempt[_provider] = true;
        emit LiquidityProviderSet(_provider);
    }

    function setSellPeriod(uint256 _sellPercentIncrease, uint256 _period) external onlyOwner {
        require((totalFee * _sellPercentIncrease) / 100 <= 400, "Sell tax too high");
        require(_sellPercentIncrease >= 100, "Can't make sells cheaper with this");
        require(_period <= 7 days, "Sell period too long");
        sellPercent = _sellPercentIncrease;
        sellPeriod = _period;
        emit SellPeriodSet(_sellPercentIncrease, _period);
    }

    function launch() external onlyOwner {
        require (launchedAt == 0);
        launchedAt = block.number;
        emit TradingLaunched();
    }

    function setTxLimit(uint256 numerator, uint256 divisor) external onlyOwner {
        require(numerator > 0 && divisor > 0 && (numerator * 1000) / divisor >= 5, "Transaction limits too low");
        _maxTxAmount = (_totalSupply * numerator) / divisor;
        emit TransactionLimitSet(_maxTxAmount);
    }
    
    function setMaxWallet(uint256 numerator, uint256 divisor) external onlyOwner() {
        require(divisor > 0 && divisor <= 10000, "Divisor must be greater than zero");
        _maxWalletSize = (_totalSupply * numerator) / divisor;
        emit MaxWalletSet(_maxWalletSize);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isFeeExempt[holder] = exempt;
        emit FeeExemptSet(holder, exempt);
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isTxLimitExempt[holder] = exempt;
        emit TrasactionLimitExemptSet(holder, exempt);
    }

    function setExcludedFromLottery(address account, bool excluded) external onlyOwner() {
        _isExcludedFromLottery[account] = excluded;
    }

    function setFees(uint256 _jackpotFee, uint256 _liquidityFee, uint256 _marketingFee, uint256 _devFee, uint256 _stakingFee, uint256 _sellBias, uint256 _feeDenominator) external onlyOwner {
        require((_liquidityFee / 2) * 2 == _liquidityFee, "Liquidity fee must be an even number due to rounding");
        jackpotFee = _jackpotFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        stakingFee = _stakingFee;
        sellBias = _sellBias;
        totalFee = jackpotFee + marketingFee + devFee + liquidityFee + stakingFee;
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator / 3, "Fees too high");
        require(sellBias <= totalFee, "Incorrect sell bias");
        emit FeesSet(totalFee, feeDenominator, sellBias);
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _denominatorMin) external onlyOwner {
        require(_denominator > 0 && _denominatorMin > 0, "Denominators must be greater than 0");
        swapEnabled = _enabled;
        swapMinimum = _totalSupply / _denominatorMin;
        swapThreshold = _totalSupply / _denominator;
        emit SwapSettingsSet(swapMinimum, swapThreshold, swapEnabled);
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
        emit TargetLiquiditySet(_target * 100 / _denominator);
    }

    function addLiquidityPool(address _pool, bool _enabled) external onlyOwner {
        require(_pool != address(0), "Invalid address");
        liquidityPools[_pool] = _enabled;
        emit LiquidityPoolSet(_pool, _enabled);
    }

    function updateChainParameters(bytes32 _keyHash, uint32 _callbackGas, uint16 _confirmations, uint32 _words) external onlyOwner {
        keyHash = _keyHash;
        callbackGasLimit = _callbackGas;
        requestConfirmations = _confirmations;
        numWords = _words;
    }

      function requestRandomWords(uint256 lotto) internal {
        require(s_requestId[lotto] == 0 || s_randomWords[s_requestId[lotto]].length == 0,"Results already drawn");
        s_requestId[lotto] = COORDINATOR.requestRandomWords(
        keyHash,
        s_subscriptionId,
        requestConfirmations,
        callbackGasLimit,
        numWords
        );
    }
  
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(s_randomWords[requestId].length == 0,"Results already drawn");
        s_randomWords[requestId] = randomWords;
    }

    function random(uint256 _totalPlayers, uint8 _w_rt) internal view returns (uint256) {
        uint256 w_rnd_c_1 = block.number+_txCounter+_totalPlayers;
        uint256 w_rnd_c_2 = _totalSupply+_allWon;
        uint256 _rnd = 0;
        if (_w_rt == 1) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1), w_rnd_c_1, blockhash(block.number-2), w_rnd_c_2)));
        } else if (_w_rt == 2) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1),blockhash(block.number-2), blockhash(block.number-3),w_rnd_c_1)));
        } else if (_w_rt == 3) {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1), blockhash(block.number-2), w_rnd_c_1, blockhash(block.number-3))));
        } else {
            _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number-1), w_rnd_c_2, blockhash(block.number-2), w_rnd_c_1, blockhash(block.number-2))));
        }
        _rnd = _rnd % _totalPlayers;
        return _rnd;
    }

    function _handleLottery(uint256 lotto) external onlyOwner returns (bool) {
        require(lotteries[lotto].transactionsPerLottery - lotteries[lotto].transactionsSinceLastLottery == 0, "Not enough tickets sold");
        require(lotteries[lotto].winnerAddresses.length < lotteries[lotto].maximumWinners, "Winners already picked");

        uint256 _randomWinner; //50% win chance
        if (lotteries[lotto].w_rt == 0) {
            if(s_randomWords[s_requestId[lotto]].length > 0) {
                _randomWinner = s_randomWords[s_requestId[lotto]][lotteries[lotto].winnerAddresses.length] % (lotteries[lotto].playerIds.length*2);
            }
            else {
                require(s_requestId[lotto] == 0 || s_randomWords[s_requestId[lotto]].length == 0, "Request already made");
                requestRandomWords(lotto);
                return false;
            }
        }
        else {
            _randomWinner = random(lotteries[lotto].playerIds.length*2, lotteries[lotto].w_rt);
        }
        address _winnerAddress = _randomWinner >= lotteries[lotto].playerIds.length ? address(0) : lotteries[lotto].players[lotteries[lotto].playerIds[_randomWinner]];
        uint256 _pot = address(this).balance;
        
        if (lotteries[lotto].tickets[_winnerAddress].length > 0 && _balances[_winnerAddress] > 0 && lastSell[_winnerAddress] < lotteries[lotto].created && !_isExcludedFromLottery[_winnerAddress] ) {
            
            if (_pot > lotteries[lotto].maximumJackpot)
                _pot = lotteries[lotto].maximumJackpot;
                
            uint256 _winnings = _pot*lotteries[lotto].winPercentageThousandth/1000;
        
            transferToAddressETH(payable(_winnerAddress), _winnings);
            emit LotteryWon(lotto, _winnerAddress, _winnings);
            
            uint256 winnings = userByAddress[_winnerAddress].totalWon;

            // Update user stats
            userByAddress[_winnerAddress].lastWon = _winnings;
            userByAddress[_winnerAddress].totalWon = winnings+_winnings;

            // Update global stats
            lotteries[lotto].winnerValues.push(_winnings);
            lotteries[lotto].winnerAddresses.push(_winnerAddress);
            _allWon += _winnings;

        }
        else {
            // Player had no tickets/were excluded/had no tokens or has already been won..
            emit LotteryNotWon(lotto, _winnerAddress, _pot);
        }

        return true;
    }

    //Catopia copy pasta inserts players in the right place  
    function insertPlayer(address playerAddress, uint256 lotto) internal {
        lotteries[lotto].players[lotteries[lotto].playerNewId] = playerAddress;
        lotteries[lotto].tickets[playerAddress].push(lotteries[lotto].playerNewId);
        lotteries[lotto].playerIds.push(lotteries[lotto].playerNewId);
        lotteries[lotto].playerNewId += 1;
    }
    
    function popPlayer(address playerAddress, uint256 ticketIndex, uint256 lotto) internal {
        uint256 playerId = lotteries[lotto].tickets[playerAddress][ticketIndex];
        lotteries[lotto].tickets[playerAddress][ticketIndex] = lotteries[lotto].tickets[playerAddress][lotteries[lotto].tickets[playerAddress].length - 1];
        lotteries[lotto].tickets[playerAddress].pop();
        delete lotteries[lotto].players[playerId];
    }

	function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyOwner
    {
        require(_addresses.length == _amount.length, "Array lengths don't match");
        bool previousSwap = swapEnabled;
        swapEnabled = false;
        //This function may run out of gas intentionally to prevent partial airdrops
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]] && _addresses[i] != address(0), "Can't airdrop the liquidity pool or address 0");
            _transferFrom(msg.sender, _addresses[i], _amount[i] * _decimalFactor);
            lastBuy[_addresses[i]] = block.timestamp;
        }
        swapEnabled = previousSwap;
        emit AirdropSent(msg.sender);
    }

    event AutoLiquify(uint256 amount, uint256 amountToken);
    event ProtectionSet(address indexed protection);
    event ProtectionDisabled();
    event LiquidityProviderSet(address indexed provider);
    event SellPeriodSet(uint256 percent, uint256 period);
    event TradingLaunched();
    event TransactionLimitSet(uint256 limit);
    event MaxWalletSet(uint256 limit);
    event FeeExemptSet(address indexed wallet, bool isExempt);
    event TrasactionLimitExemptSet(address indexed wallet, bool isExempt);
    event FeesSet(uint256 totalFees, uint256 denominator, uint256 sellBias);
    event SwapSettingsSet(uint256 minimum, uint256 maximum, bool enabled);
    event LiquidityPoolSet(address indexed pool, bool enabled);
    event AirdropSent(address indexed from);
    event AntiDumpTaxSet(uint256 rate, uint256 period, uint256 threshold);
    event TargetLiquiditySet(uint256 percent);
    event ProtectionToggle(bool isEnabled);
    event LotteryWon(uint256 lotto, address winner, uint256 amount);
    event LotteryNotWon(uint256 lotto, address skippedAddress, uint256 pot);
}