/**
 *Submitted for verification at Etherscan.io on 2022-09-19
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address token0, address token1) external view returns (address);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
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
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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

contract SandrenFlames is IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    event TokensBurned(uint256, uint256);
    event RaffleWinner(address, uint256);
    event SandrenLiquidityAdded(uint, uint256);
    struct SandrenConfig {
        uint256 maxWalletAmount;
        uint256 ethPriceToSwap;
        uint256 ethPriceForRewards;
        uint256 liquidityPoolPercentage;
        uint256 burnFrequencynMinutes;
        uint256 burnRateInBasePoints;
        uint256 minimumSandrenTokens;
        uint8[3] buyFees;
        uint8[3] sellFees; 
        bool isBurnEnabled;        
    }

    struct LastWinner {
        address holder;
        uint ethAmount;
    }

    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
    address public uniswapV2Pair = address(0);
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    string private _name = "Sandren Flames";
    string private _symbol = "SNDRNFLMS";
    uint8 private _decimals = 9;
    uint256 private _tTotal = 1000000000 * 10 ** 9; 
    IterableMapping private sandrenHoldersMap = new IterableMapping();
    bool inSwapAndLiquify;
    uint256 public tokensBurnedSinceLaunch;
    uint256 public totalEthRewardedSinceLaunch;
    uint public liquidityUnlockDate;    
    uint public nextLiquidityBurnTimeStamp;   
    TokenBurner public tokenBurner = new TokenBurner(address(this));
    IERC20 private sandrenToken = IERC20(0xC39F5519123d40D695012f779afBAcBd3AdbEb91);  //Mainnet
    LastWinner public lastWinner = LastWinner(address(0), 0);
    SandrenConfig public sandrenConfig = SandrenConfig(
        100000000001 * 10 ** 9,
        // 10000001 * 10 ** _decimals,  //maxWalletAmount
        300000000000000000,    //ethPriceToSwap .3ETH
        100000000000000000, //ethPriceForRewards - .1 ETH is the minimum amount to be included in rewards.
        75,  //liquidityPoolPercentage
        60,  //burnFrequencynMinutes
        100,  //burnRateInBasePoints - .05% for Buyback and Burn and .05% for SNDRN LP
        100000 * 10 ** 9,  //minimumSandrenTokens 100K tokens of SNDRN required for Eth reward entry
        [3, 4, 5], //buyFees random taxation between 3%-5% on every buy
        [4, 5, 6], //sellFees random taxation between 4%-6% on every sell
        true  //isBurnEnabled
    );
 
    constructor () {
         _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(tokenBurner)] = true;
        _isExcludedFromFee[address(this)] = true;
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

    function setSandrenFlamesConfig(uint256 maxWalletAmount, uint ethPriceToSwap,uint256 ethPriceForRewards, uint256 liquidityPoolPercentage, uint256 burnFrequencynMinutes,
                                    uint256 minimumSandrenTokens, uint8[3] calldata buyFees, uint8[3] calldata sellFees, bool isBurnEnabled) external onlyOwner {
        sandrenConfig.maxWalletAmount = maxWalletAmount * 10 ** 9;
        sandrenConfig.ethPriceToSwap = ethPriceToSwap;
        sandrenConfig.ethPriceForRewards = ethPriceForRewards;
        sandrenConfig.liquidityPoolPercentage = liquidityPoolPercentage;
        sandrenConfig.burnFrequencynMinutes = burnFrequencynMinutes;
        sandrenConfig.minimumSandrenTokens = minimumSandrenTokens * 10 ** 9;
        sandrenConfig.buyFees = buyFees;
        sandrenConfig.sellFees = sellFees;
        sandrenConfig.isBurnEnabled = isBurnEnabled;
    }

    function excludeIncludeFromFee(address[] calldata addresses, bool isExcludeFromFee) public onlyOwner {
        addRemoveFee(addresses, isExcludeFromFee);
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

    function checkIncludedInEthRaffle(address holder) public view returns(bool) {
        return sandrenHoldersMap.keyExists(holder);
    }

    function totalRaffleParticipants() public view returns(uint256) {
        return sandrenHoldersMap.size();
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function chooseRandomWinner() private returns(address) {
        uint256 totalHolders = sandrenHoldersMap.size();
        //We should at least have more than one Sandren holder to use the random pick
        if(totalHolders > 1 ) {
            uint256 randomIndex = getRandomeNumberByRange(totalHolders);
            address holder = sandrenHoldersMap.getKeyAtIndex(randomIndex);
            uint256 balance = sandrenToken.balanceOf(holder);
            if(balance >= sandrenConfig.minimumSandrenTokens) {
                return holder;
            } else {
                sandrenHoldersMap.remove(holder);
                return address(0);
            }
        } 
        return address(0);
    }
    
    function getRandomTax(uint8[3] memory fees) public view returns(uint256) {
        uint256 range = fees.length;
        uint256 index = getRandomeNumberByRange(range);
        return fees[index];
    }

    function getRandomeNumberByRange(uint256 range) public view returns(uint) {
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp))) % range;
        return randomnumber;
    }

    function burnTokens() external {
        require(block.timestamp >= nextLiquidityBurnTimeStamp, "Next burn time is not due yet, be patient");
        require(!sandrenConfig.isBurnEnabled, "Burning tokens is currently disabled");
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
        removeLiquidity(liquidity, owner());
    } 

    function burnTokensFromLiquidityPool() private lockTheSwap {
        uint liquidity = IERC20(uniswapV2Pair).balanceOf(address(this));
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), liquidity);
        uint tokensToBurn = liquidity.div(sandrenConfig.burnRateInBasePoints);
        removeLiquidity(tokensToBurn, address(tokenBurner));
         //this puts ETH back in the liquidity pool
        tokenBurner.buyBack(); 
        //burn all of the tokens that were removed from the liquidity pool and tokens from the buy back
        uint256 tokenBurnAmount = balanceOf(address(tokenBurner)); 
        if(tokenBurnAmount > 0) {
            //burn the tokens we removed from LP and what was bought
            _burn(address(tokenBurner), tokenBurnAmount);
            tokensBurnedSinceLaunch = tokensBurnedSinceLaunch.add(tokenBurnAmount);
            nextLiquidityBurnTimeStamp = block.timestamp.add(sandrenConfig.burnFrequencynMinutes.mul(60));
            emit TokensBurned(tokenBurnAmount, nextLiquidityBurnTimeStamp);
        }
        buySandrenTokensAndAddToLiquidityPool();
    }

    function removeLiquidity(uint256 tokenAmount, address toAddress) private {
         uniswapV2Router.removeLiquidity(
            uniswapV2Router.WETH(),
            address(this),
            tokenAmount,
            1,
            1,
            toAddress,
            block.timestamp
        );
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
        bool isSell = false;
        if(from != owner() && to != owner() && from != address(this) &&
           from != address(tokenBurner) && to != address(tokenBurner)) {
            uint256 holderBalance = balanceOf(to).add(amount);
            if (from == uniswapV2Pair) {
                require(holderBalance <= sandrenConfig.maxWalletAmount, "Wallet cannot exceed max Wallet limit");
                uint256 tokenAmount = getTokenAmountByEthPrice(sandrenConfig.ethPriceForRewards);
                if(holderBalance >= tokenAmount) {
                    addRemoveSandrenHolder(to);
                }
            }
            if (from != uniswapV2Pair && to != uniswapV2Pair) {
                require(holderBalance <= sandrenConfig.maxWalletAmount, "Wallet cannot exceed max Wallet limit");
            }
            if (from != uniswapV2Pair && to == uniswapV2Pair) {
                isSell = true;
                if(block.timestamp >= nextLiquidityBurnTimeStamp && sandrenConfig.isBurnEnabled) {
                    burnTokensFromLiquidityPool();
                } else {
                    sellTokens();
                }
            }  
        }
        tokenTransfer(from, to, amount, takeFees, isSell);
    }

    function addSandrenHoldersForEthRewards(address[] calldata holders) external onlyOwner {
       for(uint256 i =0; i < holders.length; i++) {
            addRemoveSandrenHolder(holders[i]);
       }
    }

    function tokenTransfer(address from, address to, uint256 amount, bool takeFees, bool isSell) private {
        uint256 taxFee = isSell ? getRandomTax(sandrenConfig.sellFees) : getRandomTax(sandrenConfig.buyFees);
        uint256 taxAmount = takeFees ? amount.mul(taxFee).div(100) : 0;  
        uint256 transferAmount = amount.sub(taxAmount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        emit Transfer(from, to, amount);
    }

    function addRemoveSandrenHolder(address holder) private {
        if(!Address.isContract(holder) && sandrenToken.balanceOf(holder) >= sandrenConfig.minimumSandrenTokens) {
            sandrenHoldersMap.add(holder);
        } else {
            sandrenHoldersMap.remove(holder);
        }
    }

    function sellTokens() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            uint256 tokenAmount = getTokenAmountByEthPrice(sandrenConfig.ethPriceToSwap);
            if (contractTokenBalance >= tokenAmount && !inSwapAndLiquify) {
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
        uint256 lpShare = ethBalance.mul(sandrenConfig.liquidityPoolPercentage).div(100);
        uint256 ethPrize = ethBalance.sub(lpShare);
        address chosenWinner = chooseRandomWinner();
        // if random winner has Sandren tokens, then chooseWinner will be the winners address and the eth prize will be sent immediately
        // otherwise the eth prize amount will be used to add to the liquidity pool for Sandren Token      
        if(chosenWinner != address(0)) {
            payable(chosenWinner).transfer(ethPrize);
            lastWinner.holder = chosenWinner;
            lastWinner.ethAmount = ethPrize;
            totalEthRewardedSinceLaunch = totalEthRewardedSinceLaunch.add(ethPrize);
            sandrenHoldersMap.remove(chosenWinner);
            emit RaffleWinner(chosenWinner, ethPrize);
        } else {
            lastWinner.holder = address(0);
            lastWinner.ethAmount = 0;
        }
        buySandrenTokensAndAddToLiquidityPool();
    }

    function buySandrenTokensAndAddToLiquidityPool() private {
        uint256 ethBalance = address(this).balance;
        if(ethBalance > 0) {
            uint256 takeHalfEth = ethBalance.div(2);
            swapEthForSandren(takeHalfEth);
            uint256 tokenAmount = sandrenToken.balanceOf(address(this));
            addSandrenLiquidity(takeHalfEth, tokenAmount);
            emit SandrenLiquidityAdded(takeHalfEth, tokenAmount);
        }
    }

    function addSandrenLiquidity(uint256 ethAmount, uint256 tokenAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        sandrenToken.approve(address(uniswapV2Router), tokenAmount);
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(sandrenToken),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function swapEthForSandren(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(sandrenToken);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: ethAmount}(
        0,
        path,
        address(this),
        block.timestamp);
    }

    function getTokenAmountByEthPrice(uint ethAmount) private view returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        return uniswapV2Router.getAmountsOut(ethAmount, path)[1];
    }

    receive() external payable {}

    function recoverEthInContract() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(owner()).transfer(ethBalance);
    }

}

contract TokenBurner is Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 private uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 private wethToken = IERC20(uniswapV2Router.WETH());
    IERC20 public tokenContractAddress;
    event sentEthForSandrenLiquidityPool(uint);
    constructor(address tokenAddr) {
        tokenContractAddress = IERC20(tokenAddr);
    }

    function buyBack() external {
        withdrawWETH();
        uint256 ethAmount = address(this).balance;
        uint256 halfForBuyBack = ethAmount.div(2);
        swapEthForSandrenFlames(halfForBuyBack);
         (bool success,) = address(tokenContractAddress).call{value : halfForBuyBack}("");
          if (success) {
            emit sentEthForSandrenLiquidityPool(halfForBuyBack);
        }
    }

    function swapEthForSandrenFlames(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(tokenContractAddress);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: ethAmount}(
        0,
        path,
        address(this),
        block.timestamp);
    }

    function withdrawWETH() private {
        uint weth = IERC20(uniswapV2Router.WETH()).balanceOf(address(this));
        IWETH(uniswapV2Router.WETH()).withdraw(weth);
    }

    receive() external payable {}

    function recoverEth() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        payable(owner()).transfer(ethBalance);
    }

}

contract IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    Map private map;

    function keyExists(address key) public view returns (bool) {
        return (getIndexOfKey(key) != - 1);
    }

    function getIndexOfKey(address key) public view returns (int) {
        if (!map.inserted[key]) {
            return - 1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(uint index) public view returns (address) {
        return map.keys[index];
    }

    function size() public view returns (uint) {
        return map.keys.length;
    }

    function add(address key) public {
        if (!map.inserted[key]) {
            map.inserted[key] = true;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(address key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}