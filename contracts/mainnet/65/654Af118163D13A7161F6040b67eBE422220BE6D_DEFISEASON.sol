// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract DEFISEASON is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;

    mapping (address => uint) private cd;

    mapping (address => uint256) private _rOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromTxLimits;
    mapping (address => bool) private _isBot;

    bool public tradingOpen;
    bool public launched;
    bool private swapping;
    bool private swapEnabled = false;
    bool public cdEnabled = false;

    string private constant _name = "DeFi Season";
    string private constant _symbol = "SZN";

    uint8 private constant _decimals = 18;

    uint256 private constant _tTotal = 1e8 * (10**_decimals);
    uint256 public maxBuy = _tTotal;
    uint256 public maxSell = _tTotal;
    uint256 public maxWallet = _tTotal;
    uint256 public tradingActiveBlock = 0;
    uint256 private _deadBlocks = 1;
    uint256 private _cdBlocks = 1;
    uint256 private constant FEE_DIVISOR = 1000;
    uint256 private _buyLiqFee = 20;
    uint256 private _previousBuyLiqFee = _buyLiqFee;
    uint256 private _buyVaultFee = 30;
    uint256 private _previousBuyVaultFee = _buyVaultFee;
    uint256 private _sellLiqFee = 20;
    uint256 private _previousSellLiqFee = _sellLiqFee;
    uint256 private _sellVaultFee = 30;
    uint256 private _previousSellVaultFee = _sellVaultFee;
    uint256 private tokensForLiq;
    uint256 private tokensForVault;
    uint256 private swapTokensAtAmount = 0;

    address payable private _liquidityWalletAddress;
    address payable private _vaultWalletAddress;
    address private uniswapV2Pair;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;
    
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    constructor (address liquidityWalletAddress, address vaultWalletAddress) {
        _liquidityWalletAddress = payable(liquidityWalletAddress);
        _vaultWalletAddress = payable(vaultWalletAddress);
        _rOwned[_msgSender()] = _tTotal;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromTxLimits[owner()] = true;
        _isExcludedFromTxLimits[address(this)] = true;
        _isExcludedFromTxLimits[DEAD] = true;
        emit Transfer(ZERO, _msgSender(), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _rOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        INTERNAL_transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        INTERNAL_approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        INTERNAL_transfer(sender, recipient, amount);
        INTERNAL_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function INTERNAL_approve(address owner, address spender, uint256 amount) private {
        require(owner != ZERO, "ERC20: approve from the zero address");
        require(spender != ZERO, "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function INTERNAL_transfer(address from, address to, uint256 amount) private {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool takeFee = true;
        bool shouldSwap = false;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !swapping) {
            require(!_isBot[from] && !_isBot[to]);

            if(!tradingOpen) {
                require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not allowed yet.");
            }

            if (cdEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(cd[tx.origin] < block.number - _cdBlocks && cd[to] < block.number - _cdBlocks, "Transfer delay enabled. Try again later.");
                    cd[tx.origin] = block.number;
                    cd[to] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromTxLimits[to]) {
                require(amount <= maxBuy, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= maxWallet, "Exceeds maximum wallet token amount.");
            }
            
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !_isExcludedFromTxLimits[from]) {
                require(amount <= maxSell, "Transfer amount exceeds the maxSellAmount.");
                shouldSwap = true;
            }
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = (contractTokenBalance > swapTokensAtAmount) && shouldSwap;

        if (canSwap && swapEnabled && !swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            INTERNAL_swapBack();
            swapping = false;
        }

        INTERNAL_tokenTransfer(from, to, amount, takeFee, shouldSwap);
    }

    function INTERNAL_swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiq + tokensForVault;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 5) {
            contractBalance = swapTokensAtAmount * 5;
        }
        
        uint256 liqTokens = contractBalance * tokensForLiq / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liqTokens);
        
        uint256 initialETHBalance = address(this).balance;

        INTERNAL_swapTokensForETH(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForVault = ethBalance.mul(tokensForVault).div(totalTokensToSwap);
        uint256 ethForLiq = ethBalance - ethForVault;
        
        tokensForLiq = 0;
        tokensForVault = 0;
        
        if(liqTokens > 0 && ethForLiq > 0) {
            INTERNAL_addLiquidity(liqTokens, ethForLiq);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiq, tokensForLiq);
        }
        
        (success,) = address(_vaultWalletAddress).call{value: address(this).balance}("");
    }

    function INTERNAL_swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        INTERNAL_approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function INTERNAL_addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        INTERNAL_approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _liquidityWalletAddress,
            block.timestamp
        );
    }
        
    function INTERNAL_sendETHToFee(uint256 amount) private {
        _vaultWalletAddress.transfer(amount);
    }
    
    function initialize() public onlyOwner {
        require(!launched,"Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        INTERNAL_approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        cdEnabled = true;
        maxBuy = 1e6 * (10**_decimals);
        maxSell = 1e6 * (10**_decimals);
        maxWallet = 2e6 * (10**_decimals);
        swapTokensAtAmount = 5e4 * (10**_decimals);
        launched = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }
    
    function letsGo() public onlyOwner {
        require(!tradingOpen && launched,"Trading is already open");
        tradingOpen = true;
        tradingActiveBlock = block.number;
    }

    function CONFIG_setMaxBuy(uint256 amount) public onlyOwner {
        require(amount >= 1e4 * (10**_decimals), "Max buy cannot be lower than 0.01% total supply.");
        maxBuy = amount;
    }

    function CONFIG_setMaxSell(uint256 amount) public onlyOwner {
        require(amount >= 1e4 * (10**_decimals), "Max sell cannot be lower than 0.01% total supply.");
        maxSell = amount;
    }
    
    function CONFIG_setMaxWallet(uint256 amount) public onlyOwner {
        require(amount >= 1e5 * (10**_decimals), "Max wallet cannot be lower than 0.1% total supply.");
        maxWallet = amount;
    }
    
    function CONFIG_setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(amount >= 1e3 * (10**_decimals), "Swap amount cannot be lower than 0.001% total supply.");
        require(amount <= 5e5 * (10**_decimals), "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = amount;
    }

    function CONFIG_setLiquidityWalletAddress(address walletAddress) public onlyOwner {
        require(walletAddress != ZERO, "liquidityWallet address cannot be 0");
        _isExcludedFromFees[_liquidityWalletAddress] = false;
        _isExcludedFromTxLimits[_liquidityWalletAddress] = false;
        _liquidityWalletAddress = payable(walletAddress);
        _isExcludedFromFees[_liquidityWalletAddress] = true;
        _isExcludedFromTxLimits[_liquidityWalletAddress] = true;
    }

    function CONFIG_setVaultWalletAddress(address walletAddress) public onlyOwner {
        require(walletAddress != ZERO, "vaultWallet address cannot be 0");
        _isExcludedFromFees[_vaultWalletAddress] = false;
        _isExcludedFromTxLimits[_vaultWalletAddress] = false;
        _vaultWalletAddress = payable(walletAddress);
        _isExcludedFromFees[_vaultWalletAddress] = true;
        _isExcludedFromTxLimits[_vaultWalletAddress] = true;
    }

    function CONFIG_setExcludedFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = isEx;
        }
    }
    
    function CONFIG_setExcludedFromTxLimits(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isExcludedFromTxLimits[accounts[i]] = isEx;
        }
    }
    
    function CONFIG_setBots(address[] memory accounts, bool exempt) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _isBot[accounts[i]] = exempt;
        }
    }

    function CONFIG_setBuyFees(uint256 buyLiquidityFee, uint256 buyVaultFee) public onlyOwner {
        require(buyLiquidityFee + buyVaultFee <= 200, "Must keep buy taxes below 20%");
        _buyLiqFee = buyLiquidityFee;
        _buyVaultFee = buyVaultFee;
    }

    function CONFIG_setSellFees(uint256 sellLiquidityFee, uint256 sellVaultFee) public onlyOwner {
        require(sellLiquidityFee + sellVaultFee <= 200, "Must keep sell taxes below 20%");
        _sellLiqFee = sellLiquidityFee;
        _sellVaultFee = sellVaultFee;
    }

    function CONFIG_setCDEnabled(bool onoff) public onlyOwner {
        cdEnabled = onoff;
    }

    function CONFIG_setSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }

    function CONFIG_setDeadBlocks(uint256 blocks) public onlyOwner {
        _deadBlocks = blocks;
    }

    function CONFIG_setCDBlocks(uint256 blocks) public onlyOwner {
        _cdBlocks = blocks;
    }

    function INTERNAL_removeFees() private {
        if(_buyLiqFee == 0 && _buyVaultFee == 0 && _sellLiqFee == 0 && _sellVaultFee == 0) return;
        
        _previousBuyLiqFee = _buyLiqFee;
        _previousBuyVaultFee = _buyVaultFee;
        _previousSellLiqFee = _sellLiqFee;
        _previousSellVaultFee = _sellVaultFee;
        
        _buyLiqFee = 0;
        _buyVaultFee = 0;
        _sellLiqFee = 0;
        _sellVaultFee = 0;
    }
    
    function INTERNAL_restoreFees() private {
        _buyLiqFee = _previousBuyLiqFee;
        _buyVaultFee = _previousBuyVaultFee;
        _sellLiqFee = _previousSellLiqFee;
        _sellVaultFee = _previousSellVaultFee;
    }
        
    function INTERNAL_tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool isSell) private {
        if(!takeFee) {
            INTERNAL_removeFees();
        } else {
            amount = INTERNAL_takeFees(sender, amount, isSell);
        }

        INTERNAL_vanillaTransfer(sender, recipient, amount);
        
        if(!takeFee) {
            INTERNAL_restoreFees();
        }
    }

    function INTERNAL_vanillaTransfer(address sender, address recipient, uint256 tAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(tAmount);
        _rOwned[recipient] = _rOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function INTERNAL_takeFees(address sender, uint256 amount, bool isSell) private returns (uint256) {
        uint256 _totalFees;
        uint256 liqFee;
        uint256 vaultFee;
        if(tradingActiveBlock + _deadBlocks >= block.number) {
            _totalFees = 999;
            liqFee = 10;
            vaultFee = 989;
        } else {
            _totalFees = INTERNAL_getTotalFees(isSell);
            if (isSell) {
                liqFee = _sellLiqFee;
                vaultFee = _sellVaultFee;
            } else {
                liqFee = _buyLiqFee;
                vaultFee = _buyVaultFee;
            }
        }

        uint256 fees = amount.mul(_totalFees).div(FEE_DIVISOR);
        tokensForLiq += fees * liqFee / _totalFees;
        tokensForVault += fees * vaultFee / _totalFees;
            
        if(fees > 0) {
            INTERNAL_vanillaTransfer(sender, address(this), fees);
        }
            
        return amount -= fees;
    }

    function INTERNAL_getTotalFees(bool isSell) private view returns(uint256) {
        if (isSell) {
            return _sellLiqFee + _sellVaultFee;
        }
        return _buyLiqFee + _buyVaultFee;
    }

    receive() external payable {}
    fallback() external payable {}
    
    function CONFIG_unclogContract() public {
        require(_vaultWalletAddress == msg.sender);      
        uint256 contractBalance = balanceOf(address(this));
        INTERNAL_swapTokensForETH(contractBalance);
    }
    
    function CONFIG_distributeFeesAfterUnclog() public {
        require(_vaultWalletAddress == msg.sender);      
        uint256 contractETHBalance = address(this).balance;
        INTERNAL_sendETHToFee(contractETHBalance);
    }

    function CONFIG_rescueStuckETH() public {
        require(_vaultWalletAddress == msg.sender);      
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function CONFIG_rescueStuckTokens(address tkn) public {
        require(_vaultWalletAddress == msg.sender);      
        require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(msg.sender, amount);
    }

    function CONFIG_removeTradingLimits() public onlyOwner {
        maxBuy = _tTotal;
        maxSell = _tTotal;
        maxWallet = _tTotal;
        cdEnabled = false;
    }

}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}