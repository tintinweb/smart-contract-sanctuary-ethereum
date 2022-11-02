pragma solidity ^0.8.7;



interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

function name() 
external view returns(string memory);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}





//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract FrinkTok is IBEP20, Auth {
    using SafeMath for uint256;

    address USDT;
    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "FrinkCoin";
    string constant _symbol = "$FRINK";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000000 * (10**_decimals);
    uint256 public _maxTxAmount = _totalSupply / 200;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
     uint256 public maxWalletLimit = _totalSupply/50; 
    uint16 public AUTOMATION_FEE=10;


   address AutomateWallet = 0xF1BC72cC7b8c9B711b46d2D1A2cE131c5F167772;
    
    address public LotteryWalletDaily = payable(address(this));
    address public LotteryWalletWeekly = payable(address(this));
     address[] public WeeklyList;
    address[] public DailyList;
    uint256 public day = 1 days;
    uint256 public week = 7 days;
    mapping(address => bool) public inDailyList;
    mapping(address => bool) public inWeeklyList;

    mapping(address => uint256) public tokenHoldTime;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;


    uint256 liquidityFee = 200;
    uint256 totalFee = 200;
    uint256 feeDenominator = 10000;



    IDEXRouter public router;
    address public pair;

    uint256 public launchedAt;

    uint96 public TOKEN_THRESHOLD;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 200000; // 0.005%
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(address usdtAddress, address routerA) Auth(msg.sender) {
       
      
        USDT = usdtAddress;
        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }
    function changeLotteryAddress(address _LotteryWalletDaily, address _LotteryWalletWeekly)public onlyOwner{
        LotteryWalletWeekly = _LotteryWalletWeekly;
        LotteryWalletDaily = _LotteryWalletDaily;
    }
    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(2500000000 * 10**_decimals));
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (
            _allowances[sender][msg.sender] !=
            uint256(2500000000 * 10**_decimals)
        ) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
function getDailyList() public view returns (address[] memory) {
        return DailyList;
    }

    function getWeeklyList() public view returns (address[] memory) {
        return WeeklyList;
    }

    function isWeeklyReady(address addr) internal view returns (bool) {
        return ((block.timestamp - tokenHoldTime[addr]) >= week &&
            balanceOf(addr) >= 10 * 10**_decimals);
    }

    function isDailyReady(address addr) internal view returns (bool) {
        return ((block.timestamp - tokenHoldTime[addr]) >= day &&
            balanceOf(addr) >= TOKEN_THRESHOLD * 10**_decimals);
    }

     function filterDailyList() external {
        for (uint256 index = 0; index < DailyList.length; index++) {
            if (
                inDailyList[DailyList[index]] && !isDailyReady(DailyList[index])
            ) {
                
                    if (index >= DailyList.length) return;

                    for (uint256 i = index; i < DailyList.length - 1; i++) {
                        DailyList[i] = DailyList[i + 1];
                    }
                    DailyList.pop();
                    inDailyList[DailyList[index]] = false;
                
            }
            if (!isDailyReady(DailyList[index])) {
                for (uint256 i = index; i < DailyList.length - 1; i++) {
                    DailyList[i] = DailyList[i + 1];
                }
                DailyList.pop();
            }
        }
        
    }


function updateMaxWalletlimit(uint256 amount) external onlyOwner{
         maxWalletLimit = amount * 10**_decimals;
     }
     function filterWeeklyList() external {
        for (uint256 index = 0; index < WeeklyList.length; index++) {
            if (
                inWeeklyList[WeeklyList[index]] &&
                !(isWeeklyReady(WeeklyList[index]))
            ) {
                if (index >= WeeklyList.length) return;
                inWeeklyList[WeeklyList[index]] = false;
                for (uint256 i = index; i < WeeklyList.length - 1; i++) {
                    WeeklyList[i] = WeeklyList[i + 1];
                }
                WeeklyList.pop();
            }

            if (!isWeeklyReady(WeeklyList[index])) {
                for (uint256 i = index; i < WeeklyList.length - 1; i++) {
                    WeeklyList[i] = WeeklyList[i + 1];
                }
                WeeklyList.pop();
            }
        }
    }
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
          if (inDailyList[sender]) {
            if (balanceOf(sender) - amount <= TOKEN_THRESHOLD * 10**_decimals) {
                inDailyList[sender] = false;
                tokenHoldTime[sender] = 0;
            }
        }
        if (inWeeklyList[sender]) {
            if (balanceOf(sender) - amount <= TOKEN_THRESHOLD * 10**_decimals) {
                inWeeklyList[sender] = false;
                tokenHoldTime[sender] = 0;
            }
        }
        if (
            !inDailyList[sender] &&
            tokenHoldTime[sender] != 0 &&
            isDailyReady(sender)
        ) {
            inDailyList[sender] = true;
            DailyList.push(sender);
        }
        if (
            !inDailyList[recipient] &&
            tokenHoldTime[recipient] != 0 &&
            isDailyReady(recipient)
        ) {
            inDailyList[recipient] = true;
            DailyList.push(recipient);
        }
        if (
            !inWeeklyList[sender] &&
            tokenHoldTime[sender] != 0 &&
            isWeeklyReady(sender)
        ) {
            inWeeklyList[sender] = true;
            WeeklyList.push(sender);
        }
        if (
            !inWeeklyList[recipient] &&
            tokenHoldTime[recipient] != 0 &&
            isWeeklyReady(recipient)
        ) {
            inWeeklyList[recipient] = true;
            WeeklyList.push(recipient);
        }

        if (
            balanceOf(recipient) + amount >= 10 * 10**_decimals &&
            tokenHoldTime[recipient] == 0
        ) {
            WeeklyList.push(recipient);
            DailyList.push(recipient);
            tokenHoldTime[recipient] = block.timestamp;
        }
        
       
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        checkTxLimit(sender, amount);


        if(shouldSwapBack()){ 
            // swapBack();

            // swapTokensForUSDC(balanceOf(address(this)));
             }
       
if(recipient != pair){
             require(balanceOf(recipient) + amount <= maxWalletLimit, "You are exceeding max wallet limit.");

}
        if(!launched() && recipient == pair){ require(_balances[sender] > 0); launch(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee() public view returns (uint256) {
     
        return totalFee;
    }



    function takeFee(
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeAmount = amount.mul(getTotalFee()).div(
            feeDenominator
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
     
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;


        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceOf(address(this)) ,
            0,
            path,
            address(this),
            block.timestamp
        );
//  address[] memory path = new address[](2);


        uint256 amountETH = address(this).balance.sub(address(this).balance * AUTOMATION_FEE/100);
      

        path[0] = WETH;
        path[1] = USDT;
     router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountETH
        }(0, path, address(this), block.timestamp);

    

                IBEP20(USDT).transfer(LotteryWalletWeekly,IBEP20(USDT).balanceOf(address(this)) /2);
        IBEP20(USDT).transfer(LotteryWalletDaily,IBEP20(USDT).balanceOf(address(this)));
        payable(AutomateWallet).transfer(address(this).balance);
        
    }




    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }



    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }


    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        authorized
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(
        uint256 _liquidityFee,
        uint16 _AUTOMATION_FEE,
        uint256 _feeDenominator
    ) external authorized {
        liquidityFee = _liquidityFee;
AUTOMATION_FEE = _AUTOMATION_FEE;
        totalFee = _liquidityFee;
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator / 4);
    }


    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        authorized
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

 

 

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }


    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
}


contract Managed {
    address public manager;
    address public newManager;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Sender not authorized.");
        _;
    }

    function transferOwnership(address _newManager) public onlyManager {
        newManager = _newManager;
    }

    function acceptOwnership() public {
        require(msg.sender == newManager, "Sender not authorized.");
        manager = newManager;
        newManager = address(0);
    }
}

contract DailyFrinkLottery is Managed {
    address public lastWinner;
    uint256 public minPlayers = 2;
    uint public day = 1 days;
    address[] public winners;
    FrinkTok public tokenContract;
    IERC20 public USDTToken;
        mapping(address => uint256) public winnerDetails;
    uint256 public TOKEN_THRESHOLD= 1000;
    address[] public LOTTERYLIST;
    address[] public NEWLOTTERYLIST;
    mapping(address=>bool) public AlreadyWon;
    mapping(address=>uint256) public LotteryAddr;
    address public pair = 0x0B44E1001e40D3A9E25Bcd5537128D77C569eAa3;
    event onLotteryEnd(address);

    constructor(FrinkTok FrinkAddress, address _USDTAddress) public {
        USDTToken = IERC20(_USDTAddress);
    tokenContract = FrinkTok(FrinkAddress);
    }
     function isDailyReady(address addr) public view returns (bool) {
        
        if(LotteryAddr[addr] == 0){
            return false;
        }
        else{
        return ((tokenContract.balanceOf(addr) >= TOKEN_THRESHOLD * 10 **18)&&
        (block.timestamp - LotteryAddr[addr] > day));
        }
    }
      

function filterDailyList() public {
    
    LOTTERYLIST = tokenContract.getDailyList();
    NEWLOTTERYLIST = tokenContract.getDailyList();
        for (uint256 index = 0; index < LOTTERYLIST.length; index++) {
        
         if (!isDailyReady(LOTTERYLIST[index])) {
            address addr = NEWLOTTERYLIST[index];
             
              
                if(LotteryAddr[addr] ==0 && (tokenContract.balanceOf(addr) >= TOKEN_THRESHOLD * 10 **18)){

            LotteryAddr[addr] = block.timestamp;
                }
            
                else if(LotteryAddr[addr] >0 && (tokenContract.balanceOf(addr) < TOKEN_THRESHOLD * 10 **18)){
            LotteryAddr[addr] = 0;
                }
                  for (uint256 i = index; i < LOTTERYLIST.length - 1; i++) {
                    
                    LOTTERYLIST[i] = LOTTERYLIST[i + 1];
                }
                LOTTERYLIST.pop();

            }         
            if(LOTTERYLIST[index] == pair){
                   for (uint256 i = index; i < LOTTERYLIST.length - 1; i++) {
                    
                    LOTTERYLIST[i] = LOTTERYLIST[i + 1];
                }
                LOTTERYLIST.pop();

                }
                
            }

             
        }
       
       
        
    

    function pickDailyLotteryWinner() public onlyManager {
        
        address winner = pickWinner();

if(isDailyReady(winner)){

        lastWinner = winner;

        winners.push(winner);
          AlreadyWon[winner] = true;
        uint256 lotteryBalance = USDTToken.balanceOf(address(this));
        winnerDetails[winner] = lotteryBalance;
        require(
            USDTToken.transfer(winner, lotteryBalance),
            "An error occurred when closing the lottery."
        );
        
        emit onLotteryEnd(winner);
}
    
    }

    function getPlayers() public view returns (address[] memory) {
        return LOTTERYLIST;
    }

    function changeTokenThreshold(uint256 tokenthreshold)public onlyManager{
        TOKEN_THRESHOLD = tokenthreshold;
    }

    function getLastWinner() public view returns (address) {
        return lastWinner;
    }
   
    function pickWinner() private view returns (address) {
         require(
            getPlayers().length >= minPlayers,
            "There are not enough participants"
        ); 
        uint256 index = random() % getPlayers().length -1;

        address winner = getPlayers()[index];
          if(AlreadyWon[winner] || !isDailyReady(winner)){
         winner = getPlayers()[random() % getPlayers().length -1];
          }
        return winner;
    }
    

    function random() private view returns (uint256) {
        return uint256(keccak256(encodeData()));
    }

    function encodeData() private view returns (bytes memory) {
        return
            abi.encodePacked(block.difficulty, block.timestamp, getPlayers());
    }

    function withdrawToken()public onlyManager{
        uint256 lotteryBalance = USDTToken.balanceOf(address(this));

     require(
            USDTToken.transfer(manager, lotteryBalance),
            "An error occurred when closing the lottery."
        );
        
    }

    fallback() external payable {
        revert("Don't accept ETH");
    }
}