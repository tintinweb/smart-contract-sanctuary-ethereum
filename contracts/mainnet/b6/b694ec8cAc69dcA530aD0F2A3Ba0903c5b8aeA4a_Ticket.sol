/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.7.4;
pragma abicoder v2;
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

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
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface InterfacePair {
    function sync() external;
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Ticket is ERC20Detailed, Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    event LogWinner(uint256 indexed amount, address indexed winner);

    InterfacePair public pairContract;
    mapping(address => bool) _isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint8 public constant RATE_DECIMALS = 7;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 467963 * 10**DECIMALS;

    uint256 public liquidityFee = 40;
    uint256 public treasuryFee = 25;
    uint256 public ticketInsuranceFundFee = 50;
    uint256 public sellFee = 20;
    uint256 public infinityFee = 25;
    uint256 public sweepFee = 10;
    uint256 public totalFee =
    liquidityFee.add(treasuryFee).add(ticketInsuranceFundFee)
    .add(infinityFee).add(sweepFee);

    uint256 public feeDenominator = 1000;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public autoLiquidityReceiver;
    address public treasuryReceiver;
    address public ticketInsuranceFundReceiver;
    address public infinityPool;
    bool public swapEnabled = true;
    IDEXRouter public router;
    address public pair;
    bool inSwap = false;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS =
    MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY =  8 * 10**9 * 10**DECIMALS;

    bool public _autoRebase;
    bool public _autoAddLiquidity;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;
    uint256 private _gonsPerFragment;
    uint256 private _totalSupply;

    uint256 public INDEX;

    Win[] public winList;
    mapping(address => uint256) public winners;
    address public winner;
    uint256 public winAmount;
    uint256 public length = 15 * 60;
    uint256 public maxTimestamp = 60 * 60;
    uint256 public lastTimestamp;
    uint256 public startTimestamp;
    uint256 public MinPurchaseAmount;

    struct Win{
        address user;
        uint256 winA;
        uint256 time;
    }

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;

    constructor() ERC20Detailed("Ticket Token", "TICKET", uint8(DECIMALS)) Ownable() {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        autoLiquidityReceiver = 0xaebfD2a447D3fB006B441f62B52F9371b4Dd58d4;
        treasuryReceiver = 0xd25AbfDdbc4394CB7b1fE9eB6fB379725e44b947;
        ticketInsuranceFundReceiver = 0x826c9bdC8cfbA6129FcDd26FA412229c45b943F0;
        infinityPool = 0x3229af4BB6B93Bd7b8CB258e3EE66A43D16646E2;

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairContract = InterfacePair(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _autoRebase = false;
        _autoAddLiquidity = false;
        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[address(this)] = true;

        INDEX = (10 ** DECIMALS ).mul(_gonsPerFragment);

        MinPurchaseAmount = 10 ** DECIMALS;

        _transferOwnership(treasuryReceiver);
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
    }

    function rebase() internal {

        if ( inSwap ) return;
        uint256 rebaseRate;
        uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(15 minutes);
        uint256 epoch = times.mul(15);

        if (deltaTimeFromInit > ( 8 * 365 days)) {
            rebaseRate = 2;
        } else if (deltaTimeFromInit > ( 2 * 365 days)) {
            rebaseRate = 23;
        } else if (deltaTimeFromInit > (365 days)) {
            rebaseRate = 238;
        } else {
            rebaseRate = 2383;
        }

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply
            .mul((10**RATE_DECIMALS).add(rebaseRate))
            .div(10**RATE_DECIMALS);
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(15 minutes));
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function transfer(address to, uint256 value)
    external
    override
    validRecipient(to)
    returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(to) returns (bool) {

        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
            msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");

        rewardSend();
        reward(sender,recipient,amount);

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldRebase()) {
            rebase();
        }

        if (shouldAddLiquidity()) {
            addLiquidity();
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
        ? takeFee(sender, recipient, gonAmount)
        : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );


        emit Transfer(
            sender,
            recipient,
            gonAmountReceived.div(_gonsPerFragment)
        );
        return true;
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 gonAmount
    ) internal  returns (uint256) {
        uint256 _totalFee = totalFee;
        uint256 _treasuryFee = treasuryFee;
        uint256 _sweepFee = sweepFee;

        if (recipient == pair) {
            _totalFee = totalFee.add(sellFee).add(sweepFee);
            _treasuryFee = treasuryFee.add(sellFee);
            _sweepFee = sweepFee.add(sweepFee);
        }

        uint256 feeAmount = gonAmount.div(feeDenominator).mul(_totalFee);

        _gonBalances[infinityPool] = _gonBalances[infinityPool].add(
            gonAmount.div(feeDenominator).mul(infinityFee)
        );
        emit Transfer(sender,infinityPool, gonAmount.div(feeDenominator).mul(infinityFee).div(_gonsPerFragment));

        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            gonAmount.div(feeDenominator).mul(_treasuryFee.add(ticketInsuranceFundFee).add(_sweepFee))
        );
        emit Transfer(sender, address(this), gonAmount.div(feeDenominator)
        .mul(_treasuryFee.add(ticketInsuranceFundFee).add(_sweepFee))
        .div(_gonsPerFragment));

        _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(
            gonAmount.div(feeDenominator).mul(liquidityFee)
        );
        emit Transfer(sender, autoLiquidityReceiver, gonAmount.div(feeDenominator).mul(liquidityFee).div(_gonsPerFragment));
        return gonAmount.sub(feeAmount);
    }

    function addLiquidity() internal swapping {
        uint256 autoLiquidityAmount = _gonBalances[autoLiquidityReceiver].div(
            _gonsPerFragment
        );
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            _gonBalances[autoLiquidityReceiver]
        );

        _gonBalances[autoLiquidityReceiver] = 0;
        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

        if( amountToSwap == 0 ) {
            return;
        }
        emit Transfer(autoLiquidityReceiver, address(this), autoLiquidityAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        emit Transfer(address(this), pair, amountToSwap);

        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

        if (amountToLiquify > 0&&amountETHLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit Transfer(address(this), pair, amountToLiquify);
        }
        _lastAddLiquidityTime = block.timestamp;
    }

    function swapBack() internal swapping {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);

        if( amountToSwap == 0) {
            return;
        }

        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();


        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        emit Transfer(address(this), pair, amountToSwap);

        uint256 amountETHToTreasuryAndSIF = address(this).balance.sub(
            balanceBefore
        );

        (bool success, ) = payable(treasuryReceiver).call{
        value: amountETHToTreasuryAndSIF.mul(treasuryFee).div(
            treasuryFee.add(ticketInsuranceFundFee).add(sweepFee)
        ),
        gas: 30000
        }("");
        (success, ) = payable(ticketInsuranceFundReceiver).call{
        value: amountETHToTreasuryAndSIF.mul(ticketInsuranceFundFee).div(
            treasuryFee.add(ticketInsuranceFundFee).add(sweepFee)
        ),
        gas: 30000
        }("");
        winAmount += amountETHToTreasuryAndSIF
        .mul(sweepFee)
        .div(treasuryFee.add(ticketInsuranceFundFee).add(sweepFee));

    }

    function reward(address sender,address recipient , uint256 amount) internal {
        if(sender == pair && amount >= MinPurchaseAmount){
            if(block.timestamp < lastTimestamp){
                if(lastTimestamp.sub(startTimestamp) < maxTimestamp){
                    if(lastTimestamp.sub(startTimestamp).add(length) > maxTimestamp){
                        lastTimestamp = lastTimestamp.add(maxTimestamp.sub(lastTimestamp.sub(startTimestamp)));
                    }else{
                        lastTimestamp = lastTimestamp.add(length);
                    }
                }
            }else{
                startTimestamp = block.timestamp;
                lastTimestamp = block.timestamp.add(length);
            }
            winner = recipient;
        }
    }

    function rewardSend() internal {
        if(block.timestamp > lastTimestamp && winner != address(0)) {
            if(winAmount > 0){
                emit LogWinner(winAmount, winner);
                winners[winner] += winAmount;
                Win memory w = Win({
                user:winner,
                winA:winAmount,
                time:lastTimestamp
                });
                winList.push(w);
            }
            winAmount = uint256(0);
            winner = address(0);
        }
    }

    function withdraw() external {
        if (shouldRebase()) {
            rebase();
        }
        rewardSend();
        if(winners[msg.sender] > 0){
            (bool success, ) = payable(msg.sender).call{
            value: winners[msg.sender],
            gas: 30000
            }("");
            winners[msg.sender] = 0;
            success = false;
        }
    }


    function withdrawAllToTreasury() external swapping onlyOwner {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        require( amountToSwap > 0,"There is no Ticket token deposited in token contract");
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            treasuryReceiver,
            block.timestamp
        );
    }

    function shouldTakeFee(address from, address to)
    internal
    view
    returns (bool)
    {
        return
        (pair == from || pair == to) &&
        !_isFeeExempt[from];
    }

    function shouldRebase() internal view returns (bool) {
        return
        _autoRebase &&
        (_totalSupply < MAX_SUPPLY) &&
        msg.sender != pair  &&
        !inSwap &&
        block.timestamp >= (_lastRebasedTime + 15 minutes);
    }

    function shouldAddLiquidity() internal view returns (bool) {
        return
        _autoAddLiquidity &&
        !inSwap &&
        msg.sender != pair &&
        block.timestamp >= (_lastAddLiquidityTime + 2 days);
    }

    function shouldSwapBack() internal view returns (bool) {
        return
        !inSwap &&
        msg.sender != pair  ;
    }

    function setAutoRebase(bool _flag) external onlyOwner {
        if (_flag) {
            _autoRebase = _flag;
            _lastRebasedTime = block.timestamp;
            if(_initRebaseStartTime == 0){
                _initRebaseStartTime = block.timestamp;
            }
        } else {
            _autoRebase = _flag;
        }
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if(_flag) {
            _autoAddLiquidity = _flag;
            _lastAddLiquidityTime = block.timestamp;
        } else {
            _autoAddLiquidity = _flag;
        }
    }

    function allowance(address owner_, address spender)
    external
    view
    override
    returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
    external
    returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
        spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
    external
    override
    returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
        (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
            _gonsPerFragment
        );
    }

    function isNotInSwap() external view returns (bool) {
        return !inSwap;
    }

    function manualSync() external {
        InterfacePair(pair).sync();
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _treasuryReceiver,
        address _ticketInsuranceFundReceiver,
        address _infinityPool
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
        ticketInsuranceFundReceiver = _ticketInsuranceFundReceiver;
        infinityPool = _infinityPool;
    }

    function getLiquidityBacking(uint256 accuracy)
    public
    view
    returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
        accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function setWhitelist(address _addr) external onlyOwner {
        _isFeeExempt[_addr] = true;
    }

    function clearStuckBalance(uint256 amountPercentage, address adr) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(adr).transfer(
            (amountETH * amountPercentage) / 100
        );
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(isContract(_botAddress), "only contract address, not allowed exteranlly owned account");
        blacklist[_botAddress] = _flag;
    }

    function setLP(address _address) external onlyOwner {
        pair = _address;
        pairContract = InterfacePair(_address);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function index() public view returns ( uint256 ) {
        return INDEX.div(_gonsPerFragment);
    }

    function setWinAmount(uint256 _winAmount) external onlyOwner {
        winAmount += _winAmount;
    }

    function setMinPurchaseAmount(uint256 _MinPurchaseAmount) external onlyOwner {
        MinPurchaseAmount = _MinPurchaseAmount;
    }

    function getWinList() external view returns (Win[] memory) {
        uint size = winList.length;
        uint len = size > 10 ? 10: size ;
        Win[] memory ws = new Win[](len);
        for(uint i = 0 ; i < len ; i++){
            ws[i] = winList[ size - i - 1 ];
        }
        return ws;
    }
    receive() external payable {}
}