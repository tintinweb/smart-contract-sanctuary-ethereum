// SPDX-License-Identifier: UNLICENSED
/*

██████╗ ███████╗███████╗██╗██████╗ ███╗   ███╗
██╔══██╗██╔════╝██╔════╝██║██╔══██╗████╗ ████║
██║  ██║█████╗  █████╗  ██║██████╔╝██╔████╔██║
██║  ██║██╔══╝  ██╔══╝  ██║██╔══██╗██║╚██╔╝██║
██████╔╝███████╗██║     ██║██║  ██║██║ ╚═╝ ██║
╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

*/
// DEFIRM PROTOCOL COPYRIGHT (C) 2022 

pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Ownable.sol";
import "./ERC20DetailedUpgradeable.sol";
import "./USDCReceiver.sol";
import "./IUSDCReceiver.sol";
import "./ILiquidityManager.sol";


interface IUniswapV2Pair {
	function sync() external;
}

interface IUniswapV2Router02{
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Defirm is Ownable, ERC20DetailedUpgradeable{

    using SafeMath for uint256;
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    uint256 public constant MAX_UINT256 = ~uint256(0);

    uint256 public DECIMALS;
    uint256 public RATE_DECIMALS;
    uint256 private INITIAL_FRAGMENTS_SUPPLY;
    uint256 private TOTAL_GONS;
    uint256 private MAX_SUPPLY;

    uint256 public LMSFee;
    uint256 public treasuryFee;
    uint256 public liquidityFee;
    uint256 public totalFee;
    uint256 public feeDenominator;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address constant USDC = 0xDDB43ebc3F34947C104A747a6150F4BbAA78a5eB;
    // avax 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664
    // ropsten 0xDDB43ebc3F34947C104A747a6150F4BbAA78a5eB

    address public usdcReceiver;
    address public LMSReceiver;
    address public treasuryReceiver;
    address public autoLiquidityReceiver;
    
    address public pair;
    IUniswapV2Router02 public router;
    ILiquidityManager liquidityManager;

    bool public tradingActive;
    bool private inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool public swappingOnlyFromContract;
    bool public _takeFee;
    bool public _autoRebase;
    bool public _autoSwapback;
    bool public _autoAddLiquidity;
    uint256 public _globalRebaseRate;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;
    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public _isFeeExempt;
    mapping(address => bool) public blacklist;
    mapping(address => bool) private _AddressesClearedForSwap;
    mapping (address => bool) public automatedMarketMakerPairs;
    

    function initialize(address _router, address _lms, address _liqreceiver) public {
        require(treasuryReceiver == address(0), "initialized");
        // avax 0x60aE616a2155Ee3d9A68541Ba4544862310933d4
        // ropsten 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        RATE_DECIMALS = 7;
        DECIMALS = 18;
        INITIAL_FRAGMENTS_SUPPLY = 10**6 * 10**DECIMALS;
        TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
        MAX_SUPPLY = 10**8 * 10**DECIMALS;

        _transferOwnership(msg.sender);
        __ERC20_init("DeFirm", "DEFIRM", uint8(DECIMALS));
        // __USDCReceiver_init();

        LMSFee = 50;
        treasuryFee = 50;
        liquidityFee = 50;
        totalFee = liquidityFee.add(LMSFee).add(treasuryFee);
        feeDenominator = 1000;

        tradingActive = false;
        inSwap = false;

        router = IUniswapV2Router02(_router);
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            USDC
        );

        automatedMarketMakerPairs[pair] = true;
        liquidityManager = ILiquidityManager(_lms);
        LMSReceiver = _lms;
        treasuryReceiver = msg.sender;
        autoLiquidityReceiver = _liqreceiver;
        
        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryReceiver] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        _isFeeExempt[treasuryReceiver] = true;
        _isFeeExempt[address(this)] = true;
        
        emit Transfer(address(0x0), treasuryReceiver, _totalSupply);
    }

    function __USDCReceiver_init() internal {
        require(usdcReceiver == address(0), 'initialized');
        bytes memory bytecode = type(USDCReceiver).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(USDC));
        address receiver;
        assembly {
            receiver := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IUSDCReceiver(receiver).setUSDC(USDC);
        usdcReceiver = receiver;
        IUSDCReceiver(usdcReceiver).transferOwnership(treasuryReceiver);
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
        IUniswapV2Pair(pair).sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function _beforeTokenTransfer(address from, address recipient, uint256 ) internal view{
        if (swappingOnlyFromContract) {
            if (automatedMarketMakerPairs[from]) {
                require(_AddressesClearedForSwap[recipient], "no directly swap");
            }
            if (automatedMarketMakerPairs[recipient]) {
                require(_AddressesClearedForSwap[from], "no directly swap");
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
        
        if (_allowedFragments[from][msg.sender] != type(uint256).max) {
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

        if (shouldRebase() && sender != address(liquidityManager)) {
           rebase();
        }

        if (shouldAddLiquidity() && sender != address(liquidityManager)) {
            addLiquidity();
        }

        if (shouldSwapBack() && sender != address(liquidityManager)) {
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

        uint256 balanceBefore = IERC20(USDC).balanceOf(address(this));
        _swapTokensForUsdc(amountToSwap, usdcReceiver);
        USDCReceiver(usdcReceiver).withdraw();
        uint256 amountUSDCLiquidity = IERC20(USDC).balanceOf(address(this)).sub(balanceBefore);
        IERC20(USDC).approve(address(router), amountUSDCLiquidity);

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
        _swapTokensForUsdc(amountToSwap, treasuryReceiver);
    }

    function withdrawAllToTreasury() external swapping onlyOwner {

        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        require( amountToSwap > 0, "Insufficient balance");
        _swapTokensForUsdc(amountToSwap, treasuryReceiver);
    }

    function _swapTokensForUsdc(uint256 tokenAmount, address receiver) internal {
        if(swappingOnlyFromContract){
            liquidityManager.swapTokenForUSDCToWallet(address(this), receiver, tokenAmount, 10);
        } else {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = USDC;

            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                path,
                receiver,
                block.timestamp
            );
        }
    }

    function shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        if (_isFeeExempt[from] || _isFeeExempt[to] || !_takeFee) {
            return false;
        } else {
            return (automatedMarketMakerPairs[from] ||
            automatedMarketMakerPairs[to]);
        }
    }

    function shouldRebase() internal view returns (bool) {
        return
            _autoRebase && 
            (_totalSupply < MAX_SUPPLY) && 
            !automatedMarketMakerPairs[msg.sender]  && 
            !inSwap && 
            block.timestamp >= (_lastRebasedTime + 30 minutes);
    }

    function shouldAddLiquidity() internal view returns (bool) {
        return
            _autoAddLiquidity && 
            !inSwap && 
            !automatedMarketMakerPairs[msg.sender] && 
            block.timestamp >= (_lastAddLiquidityTime + 2 days);
    }

    function shouldSwapBack() internal view returns (bool) {
        return 
            !inSwap && 
            !automatedMarketMakerPairs[msg.sender] &&
            _autoSwapback;
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

    function setAutoSwapback(bool _flag) external onlyOwner {
        _autoSwapback = _flag;
    }

    function setTakeFee(bool _flag) external onlyOwner {
        _takeFee = _flag;
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
        IUniswapV2Pair(pair).sync();
    }

    function setLiquidityManager(address _liquidityManager) public onlyOwner {
        liquidityManager = ILiquidityManager(_liquidityManager);
        LMSReceiver = _liquidityManager;
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
        require(automatedMarketMakerPairs[_pair] != _value, "already set");
        automatedMarketMakerPairs[_pair] = _value;
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _treasuryReceiver
    ) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryReceiver = _treasuryReceiver;
    }

    function setWhitelist(address _addr, bool _val) external onlyOwner {
        require(_isFeeExempt[_addr] != _val, "already set");
        _isFeeExempt[_addr] = _val;
    }

    function setBotBlacklist(address _botAddress, bool _flag) external onlyOwner {
        require(isContract(_botAddress), "only contract address");
        blacklist[_botAddress] = _flag;    
    }
    
    function setPairAddress(address _pair) public onlyOwner {
        require(_pair != address(0), "invalid");
        pair = _pair;
    }
    
    function setGlobalRate(uint256 _val, uint256 _deciaml) external onlyOwner {
        _globalRebaseRate  = _val;
        RATE_DECIMALS = _deciaml;
    }

    function enableTrading() external onlyOwner {
        require (!tradingActive, "already enabled");
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
            IERC20(tokenAddress).transfer(
                msg.sender, 
                IERC20(tokenAddress).balanceOf(address(this))
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


abstract contract ERC20DetailedUpgradeable is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function __ERC20_init(string memory name_, string memory symbol_, uint8 decimals_) internal {
        __ERC20_init_unchained(name_, symbol_, decimals_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_, uint8 decimals_) internal {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract USDCReceiver is Ownable {

    address public usdc;
    address public token;

    constructor() Ownable() {
        token = msg.sender;
    }

    // function __USDCReceiver_init() internal onlyInitializing {
    //     __USDCReceiver_init_unchained();
    // }

    // function __USDCReceiver_init_unchained() internal onlyInitializing {
    //     token = msg.sender;    
    // }

    function setUSDC(address _usdc) public onlyOwner {
        require(usdc == address(0x0), "Already set");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
interface IUSDCReceiver {

    function setUSDC(address) external;
    function withdraw() external;
    function withdrawUnsupportedAsset(address, uint256) external;
    function transferOwnership(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
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