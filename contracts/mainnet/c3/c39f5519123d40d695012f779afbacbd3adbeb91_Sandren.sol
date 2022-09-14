/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

/********************************************************************

49206B6E6F7720796F752C2062757420796F7520646F6E2774206B6E6F
77206D652E2020492068617665206265656E206C697374656E696E6720
746F206D7920666F6C6C6F7765727320616E642049206861766520616E7
377657265642E2020436F6E7374616E74206275726E2066726F6D20756E
6973776170206C697175696469747920706F6F6C2069732068657265206
96E2053616E6472656E2E20204C65742074686520626C75652064726167
6F6E20666C616D65207475726E20746F6B656E7320696E746F2061736865732E

*********************************************************************/
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

contract Sandren is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event TokensBurned(uint256, uint256);
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair = address(0);
    address private dargonFlames = 0x040981E82D0ca51E9978078f21Af15264Ee8e0bd;
    address private tokensToAshes = 0x92092EA924e26739F24a9d1C4959F7057934ceAa;    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    string private _name = "Sandren";
    string private _symbol = "SNDRN";
    uint8 private _decimals = 9;
    uint256 private _tTotal = 948948317 * 10 ** _decimals;  //reducing total supply because of burns from previous launch
    bool inSwapAndLiquify;
    bool public swapEnabled = true;
    bool public isBurnEnabled = true;
    uint256 public ethPriceToSwap = 200000000000000000; //.2 ETH
    uint256 public _maxWalletAmount = 20000001 * 10 ** _decimals;
    uint256 public tokensBurnedSinceLaunch = 35964489110561625;  //This is the amount of tokens burned from previous launch
    uint256 public burnFrequencynMinutes = 60;  //starting off every 60 minutes to do liquidity burn
    uint256 public burnRateInBasePoints = 100;  //100 = 1%
    uint public nextLiquidityBurnTimeStamp;
    uint public liquidityUnlockDate;    
    uint256 public buySellFee = 5;

    TokenBurner public tokenBurner = new TokenBurner(address(this));

    constructor () {
         _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(tokenBurner)] = true;
        _isExcludedFromFee[address(this)] = true;
        nextLiquidityBurnTimeStamp = block.timestamp;
        emit Transfer(address(0), address(this), _tTotal);
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

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner {
        _maxWalletAmount = maxWalletAmount * 10 ** 9;
    }

    function setBurnSettings(uint256 frequencyInMinutes, uint256 burnBasePoints) external onlyOwner {
        burnFrequencynMinutes = frequencyInMinutes;
        burnRateInBasePoints = burnBasePoints;
    }

    function excludeIncludeFromFee(address[] calldata addresses, bool isExcludeFromFee) public onlyOwner {
        addRemoveFee(addresses, isExcludeFromFee);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _tTotal = _tTotal.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function addRemoveFee(address[] calldata addresses, bool flag) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _isExcludedFromFee[addr] = flag;
        }
    }
    
    function setTaxFee(uint256 taxFee) external onlyOwner {
        buySellFee = taxFee;
    }

    function burnTokens() external {
        require(block.timestamp >= nextLiquidityBurnTimeStamp, "Next burn time is not due yet, be patient");
        require(!isBurnEnabled, "Burning tokens is currently disabled");
        burnTokensFromLiquidityPool();
    }

    function lockLiquidity(uint256 newLockDate) external onlyOwner {
        require(newLockDate > liquidityUnlockDate, "New lock date must be greater than existing lock date");
        liquidityUnlockDate = newLockDate;
    }

    function openTrading() external onlyOwner() {
        require(uniswapV2Pair == address(0),"UniswapV2Pair has already been set");
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp);
        swapEnabled = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        nextLiquidityBurnTimeStamp = block.timestamp;
        liquidityUnlockDate = block.timestamp.add(3 days); //lock the liquidity for 3 days
    }

        //This is only for protection at launch in case of any issues.  Liquidity cannot be pulled if 
    //liquidityUnlockDate has not been reached or contract is renounced
    function removeLiqudityPool() external onlyOwner {
        require(liquidityUnlockDate < block.timestamp, "Liquidity is currently locked");
        uint liquidity = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), liquidity);
        uniswapV2Router.removeLiquidity(
            uniswapV2Router.WETH(),
            address(this),
            liquidity,
            1,
            1,
            owner(),
            block.timestamp
        );
    }

    function burnTokensFromLiquidityPool() private lockTheSwap {
        uint liquidity = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), liquidity);
        uint tokensToBurn = liquidity.div(burnRateInBasePoints);
        uniswapV2Router.removeLiquidity(
            uniswapV2Router.WETH(),
            address(this),
            tokensToBurn,
            1,
            1,
            address(tokenBurner),
            block.timestamp
        );
         //this puts ETH back in the liquidity pool
        tokenBurner.buyBack(); 
        //burn all of the tokens that were removed from the liquidity pool and tokens from the buy back
        uint256 tokenBurnAmount = balanceOf(address(tokenBurner)); 
        if(tokenBurnAmount > 0) {
            //burn the tokens we removed from LP and what was bought
            _burn(address(tokenBurner), tokenBurnAmount);
            tokensBurnedSinceLaunch = tokensBurnedSinceLaunch.add(tokenBurnAmount);
            nextLiquidityBurnTimeStamp = block.timestamp.add(burnFrequencynMinutes.mul(60));
            emit TokensBurned(tokenBurnAmount, nextLiquidityBurnTimeStamp);
        }
    }

    function enableDisableSwapTokens(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function enableDisableBurnToken(bool _enabled) public onlyOwner {
        isBurnEnabled = _enabled;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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
        bool takeFees = !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && from != owner() && to != owner();
        if(from != owner() && to != owner() && from != address(this) &&
           from != address(tokenBurner) && to != address(tokenBurner)) {
            uint256 holderBalance = balanceOf(to).add(amount);
            if (from == uniswapV2Pair) {
                require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
            }
            if (from != uniswapV2Pair && to != uniswapV2Pair) {
                require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
            }
            if (from != uniswapV2Pair && to == uniswapV2Pair) {
                if(block.timestamp >= nextLiquidityBurnTimeStamp && isBurnEnabled) {
                    burnTokensFromLiquidityPool();
                } else {
                    sellTokens();
                }
            }  
        }
        tokenTransfer(from, to, amount, takeFees);
    }

    function airDrops(address[] calldata holders, uint256[] calldata amounts) external onlyOwner {
        uint256 iterator = 0;
        require(holders.length == amounts.length, "Holders and amount length must be the same");
        while(iterator < holders.length){
            tokenTransfer(address(this), holders[iterator], amounts[iterator], false);
            iterator += 1;
        }
    }

    function tokenTransfer(address from, address to, uint256 amount, bool takeFees) private {
        uint256 taxAmount = takeFees ? amount.mul(buySellFee).div(100) : 0;  //5% taxation if takeFees is true
        uint256 transferAmount = amount.sub(taxAmount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        emit Transfer(from, to, amount);

    }

    function claimTokens() external {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            if (!inSwapAndLiquify && swapEnabled) {
                swapTokensForEth(contractTokenBalance);
            }
        }
    }

    function sellTokens() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            uint256 tokenAmount = getTokenAmountByEthPrice();
            if (contractTokenBalance >= tokenAmount && !inSwapAndLiquify && swapEnabled) {
                swapTokensForEth(tokenAmount);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
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

        uint256 ethBalance = address(this).balance;
        uint256 halfShare = ethBalance.div(2);  
        payable(dargonFlames).transfer(halfShare);
        payable(tokensToAshes).transfer(halfShare); 
    }

    function getTokenAmountByEthPrice() public view returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        return uniswapV2Router.getAmountsOut(ethPriceToSwap, path)[1];
    }

    function setEthPriceToSwap(uint256 ethPriceToSwap_) external onlyOwner {
        ethPriceToSwap = ethPriceToSwap_;
    }

    receive() external payable {}

    function recoverEthInContract() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(dargonFlames).transfer(ethBalance);
    }

}

contract TokenBurner is Ownable {

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 private wethToken = IERC20(uniswapV2Router.WETH());
    IERC20 public tokenContractAddress;
    
    constructor(address tokenAddr) {
        tokenContractAddress = IERC20(tokenAddr);
    }
    function buyBack() external {
        address[] memory path;
        path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(tokenContractAddress);
        
        uint256 wethAmount = wethToken.balanceOf(address(this));
        wethToken.approve(address(uniswapV2Router), wethAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            wethAmount,
            0,
            path,
            address(this),
            block.timestamp);    
    }
    
    receive() external payable {}

    function recoverEth() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(owner()).transfer(ethBalance);
    }

}