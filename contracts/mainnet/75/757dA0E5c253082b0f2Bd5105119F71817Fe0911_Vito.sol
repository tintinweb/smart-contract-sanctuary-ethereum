/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

pragma solidity ^0.8.17;
// SPDX-License-Identifier: Unlicensed
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
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



interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address token0, address token1) external view returns (address);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);
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
    function WETH() external pure returns (address);
}

contract Vito is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event TokensBurned(uint256, uint256);
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public marketPair = address(0);
    IUniswapV2Pair private v2Pair;
    address private feeOne = 0xb4c31a2Cfc11f6493FA5E4B38c6a7EB1d95D9058;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    string private _name = "Very Special Dragon";
    string private _symbol = "Vito";
    uint8 private _decimals = 18;
    uint256 private _tTotal = 1e8 * 1e18;
    uint256 public _maxWalletAmount = (_tTotal * 3) / 100;
    bool inSwapAndLiquify;
    uint256 public buyFee = 5;
    uint256 public sellFee = 5;
    address public deployer;
    uint256 public ethPriceToSwap = 0.01 ether; 
    bool public isBurnEnabled = true;
    uint256 public burnFrequencynMinutes = 30;  
    uint256 public burnRateInBasePoints = 100;  //100 = 1%
    uint256 public tokensBurnedSinceLaunch = 0;
    uint public nextLiquidityBurnTimeStamp;

    uint256 totalShare = 50;
    uint256 feeShare = 30;
    uint256 lpShare = 20;
   
    constructor () {
        address tokenOwner = 0xc50a2b5c1E57ff8f1A9321f8213a332711222255;
         _balances[tokenOwner] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[feeOne] = true;

        deployer = tokenOwner;
        transferOwnership(deployer);
        emit Transfer(address(0), tokenOwner, _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function setShares(uint256 _feeShar, uint256 _lpShare) public onlyOwner{
        lpShare = _lpShare;
        feeShare = _feeShar;
        totalShare = _lpShare + _feeShar;
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

    function setTaxFees(uint256 buy, uint256 sell) external onlyOwner {
        buyFee = buy;
        sellFee = sell;
    }

   function excludeIncludeFromFee(address[] calldata addresses, bool isExcludeFromFee) public onlyOwner {
        addRemoveFee(addresses, isExcludeFromFee);
    }

   function setBurnSettings(uint256 frequencyInMinutes, uint256 burnBasePoints) external onlyOwner {
        burnFrequencynMinutes = frequencyInMinutes;
        burnRateInBasePoints = burnBasePoints;
    }

    function burnTokensFromLiquidityPool() private lockTheSwap {
        uint liquidity = balanceOf(marketPair);
        uint tokenBurnAmount = liquidity.div(burnRateInBasePoints);
        if(tokenBurnAmount > 0) {
            //burn tokens from LP and update liquidity pool price
            _burn(marketPair, tokenBurnAmount);
            v2Pair.sync();
            tokensBurnedSinceLaunch = tokensBurnedSinceLaunch.add(tokenBurnAmount);
            nextLiquidityBurnTimeStamp = block.timestamp.add(burnFrequencynMinutes.mul(60));
            emit TokensBurned(tokenBurnAmount, nextLiquidityBurnTimeStamp);
        }
    }

    function enableDisableBurnToken(bool _enabled) public onlyOwner {
        isBurnEnabled = _enabled;
    }

    function burnTokens() external {
        require(block.timestamp >= nextLiquidityBurnTimeStamp, "Next burn time is not due yet, be patient");
        require(isBurnEnabled, "Burning tokens is currently disabled");
        burnTokensFromLiquidityPool();
    }

    function addRemoveFee(address[] calldata addresses, bool flag) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _isExcludedFromFee[addr] = flag;
        }
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _tTotal = _tTotal.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function openTrading(address _pair) external onlyOwner() {
        require(marketPair == address(0),"UniswapV2Pair has already been set");
        _approve(address(this), address(uniswapV2Router), _tTotal);
        marketPair = _pair; 
        v2Pair = IUniswapV2Pair(marketPair);
        nextLiquidityBurnTimeStamp = block.timestamp;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        _maxWalletAmount = maxWalletAmount;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        bool takeFees = !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && from != owner() && to != owner();
        if(from != deployer && to != deployer && from != address(this) && to != address(this)) {
            if(takeFees) {
                if (from == marketPair) {
                    taxAmount = amount.mul(buyFee).div(100);
                    uint256 amountToHolder = amount.sub(taxAmount);
                    uint256 holderBalance = balanceOf(to).add(amountToHolder);
                    require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
                }
                if (from != marketPair && to == marketPair) {
                    if(block.timestamp >= nextLiquidityBurnTimeStamp && isBurnEnabled) {
                            burnTokensFromLiquidityPool();
                    } else {
                        uint256 contractTokenBalance = balanceOf(address(this));
                        if (contractTokenBalance > 0) {
                            
                                uint256 tokenAmount = getTokenPrice();
                                if (contractTokenBalance >= tokenAmount && !inSwapAndLiquify) {
                                    swapTokensForEth(tokenAmount);
                                }
                            }
                        }
                }
                if (from != marketPair && to != marketPair) {
                    uint256 fromBalance = balanceOf(from);
                    uint256 toBalance = balanceOf(to);
                    require(fromBalance <= _maxWalletAmount && toBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
                }
            }
        }       
        uint256 transferAmount = amount.sub(taxAmount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        emit Transfer(from, to, transferAmount);
    }

    function manualSwap() external {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            if (!inSwapAndLiquify) {
                swapTokensForEth(contractTokenBalance);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth

        uint256 lpTokens = (tokenAmount * lpShare) / totalShare;
        uint256 feeTokens = (tokenAmount * feeShare) / totalShare;

        uint256 beforeBalance;

        if(lpTokens > 0){
            uint256 firstHalf = lpTokens / 2;
            uint256 secondHalf = lpTokens - firstHalf;
            beforeBalance = address(this).balance;
            swapToETH(firstHalf);
            if(address(this).balance > beforeBalance){
                addLiquidity(secondHalf, address(this).balance - beforeBalance);
            }
        }          

        if(feeTokens > 0) {
            swapToETH(feeTokens);
            if(address(this).balance > 0) {
                uint256 ethBalance = address(this).balance;
                payable(feeOne).transfer(ethBalance);
            }
        }
   }

    function swapToETH(uint256 tokensAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokensAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
 
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function getTokenPrice() public view returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        return uniswapV2Router.getAmountsOut(ethPriceToSwap, path)[1];
    }

    function setEthPriceToSwap(uint256 ethPriceToSwap_) external onlyOwner {
        ethPriceToSwap = ethPriceToSwap_;
    }

    receive() external payable {}

    function sendEth() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(msg.sender).transfer(ethBalance);
    }

    function sendERC20Tokens(address contractAddress) external onlyOwner {
        IERC20 erc20Token = IERC20(contractAddress);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(msg.sender, balance);
    }
}