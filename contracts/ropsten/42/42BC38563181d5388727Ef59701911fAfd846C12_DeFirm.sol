/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: Unlicensed
/*

██████╗ ███████╗███████╗██╗██████╗ ███╗   ███╗
██╔══██╗██╔════╝██╔════╝██║██╔══██╗████╗ ████║
██║  ██║█████╗  █████╗  ██║██████╔╝██╔████╔██║
██║  ██║██╔══╝  ██╔══╝  ██║██╔══██╗██║╚██╔╝██║
██████╔╝███████╗██║     ██║██║  ██║██║ ╚═╝ ██║
╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

*/
// DEFIRM PROTOCOL COPYRIGHT (C) 2022 

pragma solidity ^0.7.4;

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

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITraderJoePair {
	function sync() external;
}

interface ITraderJoePairRouter{
		function factory() external pure returns (address);

		function addLiquidity(
				address tokenA,
				address tokenB,
				uint amountADesired,
				uint amountBDesired,
				uint amountAMin,
				uint amountBMin,
				address to,
				uint deadline
		) external returns (uint amountA, uint amountB, uint liquidity);
		function swapExactTokensForTokensSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
}

interface ITraderJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ILiquidityManager {
    function rebalance(uint256 amount, bool buyback) external;

    function swapUsdcForToken(
        address to,
        uint256 amountIn,
        uint256 amoutnOutMin
    ) external;

    function swapTokenForUsdc(
        address to,
        uint256 amountIn,
        uint256 amountOutMin
    ) external;

    function swapTokenForUSDCToWallet(
        address from,
        address destination,
        uint256 tokenAmount,
        uint256 slippage
    ) external;

    function enableLiquidityManager(bool value) external;
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


interface IUSDCReceiver {

    function initialize(address) external;
    function withdraw() external;
    function withdrawUnsupportedAsset(address, uint256) external;
    function transferOwnership(address) external;
}

contract USDCReceiver is Ownable {

    address public usdc;
    address public token;

    constructor() Ownable() {
        token = msg.sender;
    }

    function initialize(address _usdc) public onlyOwner {
        require(usdc == address(0x0), "Already initialized");
        usdc = _usdc;
    }

    function withdraw() public {
        require(msg.sender == token, "Caller is not token");
        IERC20(usdc).transfer(token, IERC20(usdc).balanceOf(address(this)));
    }

    function withdrawUnsupportedAsset(address _token, uint256 _amount) public onlyOwner {
        if(_token == address(0))
            payable(owner()).transfer(_amount);
        else
            IERC20(_token).transfer(owner(), _amount);
    }
}

contract DeFirm is ERC20Detailed, Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    string public constant _name = "DeFirm";
    string public constant _symbol = "DEFIRM";
    uint8 public constant _decimals = 18;

    ITraderJoePair public pairContract;
    ILiquidityManager liquidityManager = ILiquidityManager(0x90E46E1022a5F30869B443efAB58c886654D47C8);
    mapping(address => bool) _isFeeExempt;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint8 public RATE_DECIMALS = 7;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 10**6 * 10**DECIMALS;

    uint256 public constant treasuryFee = 50;
    uint256 public constant LMSFee = 50;
    uint256 public constant liquidityFee = 50;

    uint256 public totalFee = liquidityFee.add(LMSFee).add(treasuryFee);
    uint256 public constant feeDenominator = 1000;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant USDC = 0xDDB43ebc3F34947C104A747a6150F4BbAA78a5eB;
    // avax 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664
    // ropsten 0xDDB43ebc3F34947C104A747a6150F4BbAA78a5eB

    address public usdcReceiver;
    address public treasuryReceiver;
    address public LMSReceiver;
    address public autoLiquidityReceiver;    
    address public pairAddress;
    bool public tradingActive;

    ITraderJoePairRouter public router;
    address public pair;
    bool inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MAX_SUPPLY = 10**8 * 10**DECIMALS;

    bool public swappingOnlyFromContract;
    bool public _autoRebase;
    bool public _autoAddLiquidity;
    uint256 public _globalRebaseRate;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;
    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public blacklist;
    mapping(address => bool) private _AddressesClearedForSwap;
    mapping (address => bool) public automatedMarketMakerPairs;

    constructor() ERC20Detailed("DeFirm", "DEFIRM", uint8(DECIMALS)) Ownable() {
        // creating USDC Receiver contract
        bytes memory bytecode = type(USDCReceiver).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(USDC));
        address receiver;
        assembly {
            receiver := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUSDCReceiver(receiver).initialize(USDC);

        usdcReceiver = receiver;

        router = ITraderJoePairRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // avax 0x60aE616a2155Ee3d9A68541Ba4544862310933d4
        // ropsten 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        pair = ITraderJoeFactory(router.factory()).createPair(
            USDC,
            address(this)
        );

        automatedMarketMakerPairs[pair] = true;
        LMSReceiver = 0x90E46E1022a5F30869B443efAB58c886654D47C8;
        treasuryReceiver = 0x6474F3960d51aE2cBE07ccf1630F1C6A3d96327E;
        autoLiquidityReceiver = 0x223cE900d58275a89294bCb5dE007eeDD1505a58;

        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairAddress = pair;
        pairContract = ITraderJoePair(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[address(this)] = true;

        IUSDCReceiver(receiver).transferOwnership(treasuryReceiver);
        _transferOwnership(treasuryReceiver);
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
    }

    function rebase() internal {
        
        if ( inSwap ) return;
        uint256 rebaseRate;
        uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(30 minutes);
        uint256 epoch = times.mul(30);

        if (deltaTimeFromInit < (365 days)) {
            rebaseRate = 1369;
        } else if (deltaTimeFromInit >= (7 * 365 days)) {
            rebaseRate = 11;
        } else if (deltaTimeFromInit >= (548 days)) {
            rebaseRate = 231;
        } else {
            rebaseRate = 627;
        }

        if(_globalRebaseRate > 0) {
            rebaseRate = _globalRebaseRate;
        }

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply
                .mul((10**RATE_DECIMALS).add(rebaseRate))
                .div(10**RATE_DECIMALS);
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(30 minutes));
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function _beforeTokenTransfer(address from, address recipient, uint256 ) internal view{
        if (swappingOnlyFromContract) {
            if (automatedMarketMakerPairs[from]) {
                require(_AddressesClearedForSwap[recipient], "You are not allowed to SWAP directly on Pancake");
            }
            if (automatedMarketMakerPairs[recipient]) {
                require(_AddressesClearedForSwap[from], "You are not allowed to SWAP directly on Pancake");
            } 
        }
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

        _beforeTokenTransfer(sender, recipient, amount);

        if(!tradingActive){
            require(_isFeeExempt[sender] || _isFeeExempt[recipient], "Trading is not active.");
        }

        require(!blacklist[sender] && !blacklist[recipient], "in_blacklist");

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
            ? takeFee(sender, gonAmount)
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
        uint256 gonAmount
    ) internal  returns (uint256) {
        uint256 feeAmount = gonAmount.mul(totalFee).div(feeDenominator);
       
        _gonBalances[LMSReceiver] = _gonBalances[LMSReceiver].add(
            gonAmount.mul(LMSFee).div(feeDenominator)
        );
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            gonAmount.mul(treasuryFee).div(feeDenominator)
        );
        _gonBalances[autoLiquidityReceiver] = _gonBalances[autoLiquidityReceiver].add(
            gonAmount.mul(liquidityFee).div(feeDenominator)
        );
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
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
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        uint256 balanceBefore = IERC20(USDC).balanceOf(address(this));

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            usdcReceiver,
            block.timestamp
        );

        IUSDCReceiver(usdcReceiver).withdraw();
        uint256 amountUSDCLiquidity = IERC20(USDC).balanceOf(address(this)).sub(balanceBefore);
        IERC20(USDC).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amountUSDCLiquidity);

        if (amountToLiquify > 0 && amountUSDCLiquidity > 0) {
            router.addLiquidity(
                address(this),
                USDC,
                amountToLiquify,
                amountUSDCLiquidity,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
        }
        _lastAddLiquidityTime = block.timestamp;
    }

    function swapBack() internal swapping {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        if( amountToSwap == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;
        
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            treasuryReceiver,
            block.timestamp
        );
    }

    function withdrawAllToTreasury() external swapping onlyOwner {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        require( amountToSwap > 0, "There is no DeFirm token deposited in token contract");
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = USDC;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
            block.timestamp >= (_lastRebasedTime + 30 minutes);
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
        ITraderJoePair(pair).sync();
    }

    function setLiquidityManager(address _liquidityManager) public onlyOwner {
        liquidityManager = ILiquidityManager(_liquidityManager);
    }

    function setSwappingOnlyFromContract(bool value) external onlyOwner {
        swappingOnlyFromContract = value;
        liquidityManager.enableLiquidityManager(value);
    }

    function allowSwap(address addr, bool value) external onlyOwner{
        require(addr != address(0));
        _setSwapAllowed(addr, value);
    }

    function _setSwapAllowed(address addr, bool value) private {
        _AddressesClearedForSwap[addr] = value;
    }

    function swapUsdcForToken(uint256 amountIn, uint256 amountOutMin) external {
        _setSwapAllowed(msg.sender, true);
        liquidityManager.swapUsdcForToken(msg.sender, amountIn,
        amountOutMin);
        _setSwapAllowed(msg.sender, false);
    }

    function swapTokenForUsdc(uint256 amountIn, uint256 amountOutMin) external {
        _setSwapAllowed(msg.sender, true);
        liquidityManager.swapTokenForUsdc(msg.sender, amountIn,
        amountOutMin);
        _setSwapAllowed(msg.sender, false);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(automatedMarketMakerPairs[_pair] != _value, "already set to that value");
        automatedMarketMakerPairs[_pair] = _value;
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _LMSReceiver,
        address _treasuryReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        LMSReceiver = _LMSReceiver;
        treasuryReceiver = _treasuryReceiver;
    }

    function setWhitelist(address _addr, bool _val) external onlyOwner {
        require(_isFeeExempt[_addr] != _val, "already set");
        _isFeeExempt[_addr] = _val;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(isContract(_botAddress), "only contract address, not allowed exteranlly owned account");
        blacklist[_botAddress] = _flag;    
    }
    
    function setPairAddress(address _pairAddress) public onlyOwner {
        pairAddress = _pairAddress;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = ITraderJoePair(_address);
    }
    
    function setGlobalRate(uint256 _val, uint8 _deciaml) external onlyOwner {
        _globalRebaseRate  = _val;
        RATE_DECIMALS = _deciaml;
    }

    function enableTrading() external onlyOwner {
        require (!tradingActive, "Trading is already enabled");
        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
        _autoRebase = true;
        _autoAddLiquidity = true;
        tradingActive= true;
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256){
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return
            accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function rescueBalance(address tokenAddress) external onlyOwner{
        if(tokenAddress != address(0)) {
            ERC20Detailed(tokenAddress).transfer(
                msg.sender, 
                ERC20Detailed(tokenAddress).balanceOf(address(this))
            );
        }
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
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

    receive() external payable {}
}