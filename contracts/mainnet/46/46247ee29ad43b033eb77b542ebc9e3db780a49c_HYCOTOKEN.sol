/*
Tokenomics: 
8% liquidity (subject to change, up to 12% total tax) 
2% redistribution (subject to change, up to 12% total tax) 
2% treasury (subject to change, up to 12% total tax) 

TALU!
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "IERC20.sol";
import "Ownable.sol";
import "Context.sol";
import "SafeMath.sol";
import "Address.sol";

contract HYCOTOKEN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    //// erc20
    mapping (address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    // total supply = 10 billion
    uint256 private constant _tTotal = 10000000000 * 10**_decimals; 
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    string private _name = 'HYCO TOKEN';
    string private _symbol = 'HYCO';
    uint8 private constant _decimals = 9;

    /// uniswap/ pancakeswap
    address public constant ROUTER_ADDR = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 public constant ROUTER = IUniswapV2Router02(ROUTER_ADDR);
    IERC20 public immutable WETH;
    address public constant FACTORY_ADDR = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public immutable PAIR_ADDR;
    address public immutable WETH_ADDR;
    address public immutable MY_ADDR;

    //// cooldown
    mapping (address => uint256) public timeTransfer;
    bool private _cooldownEnabled = true;
    uint256 private _cooldown = 10 seconds;

    //// taxes
    mapping (address => bool) public whitelist;
    struct Taxes {
        // 8%, subject to change (up to 12% total tax)
        uint256 liquidity;
        // 2%, subject to change (up to 12% total tax)
        uint256 redistribution;
        // 2%, subject to change (up to 12% total tax)
        uint256 treasury;
    }
    Taxes private _taxRates = Taxes(80, 20, 20);
    bool public taxesDisabled;
    address payable public treasuryAddr = payable(0xB2E3561FB02904DbABb761C32Abe4368538f5097);

    // gets set to true after openTrading is called, cannot be unset
    bool public tradingEnabled = false;
    // in case we want to turn the token in a standard erc20 token for various reasons, cannot be unset
    bool public isNormalToken = false;
    
    bool public swapEnabled = true;
    bool public inSwap = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    event SwapTokensForETH(uint256 amountIn, address[] path);
    event AddedLiquidity(uint256 amountEth, uint256 amountTokens);

    constructor () {
        PAIR_ADDR = UniswapV2Library.pairFor(FACTORY_ADDR, ROUTER.WETH(), address(this));
        WETH_ADDR = ROUTER.WETH();
        WETH = IERC20(IUniswapV2Router02(ROUTER).WETH());
        MY_ADDR = address(this);

        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);

        whitelist[address(this)] = true;
        whitelist[_msgSender()] = true;
        // not strictly necessary, but probably sensible
        whitelist[treasuryAddr] = true;
    }
    receive() external payable {}

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 tAmount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || whitelist[sender] || whitelist[recipient], "Trading is not live yet. ");
        
        if (isNormalToken || inSwap || whitelist[sender] || whitelist[recipient]) {
            _tokenTransferWithoutFees(sender, recipient, tAmount);
            return;
        }
        
        // buys
        if (sender == PAIR_ADDR && recipient != ROUTER_ADDR) {

            if (_cooldownEnabled) {
                _checkCooldown(recipient);
            }
        }
        
        // sells
        if (recipient == PAIR_ADDR && sender != ROUTER_ADDR) {
            
            if (_cooldownEnabled) {
                _checkCooldown(sender);
            }
            
            if (swapEnabled) {
                _doTheSwap();
            }
        } 
        
        _tokenTransferWithFees(sender, recipient, tAmount);
    }
    
    function _checkCooldown(address addr) private {
        // enforce cooldown and note down time
        require(
            timeTransfer[addr].add(_cooldown) < block.timestamp,
            "Need to wait until next transfer. "
        );
        timeTransfer[addr] = block.timestamp;
    }
    
    function _doTheSwap() private {
        if (balanceOf(MY_ADDR) == 0) {
            return;
        }
        
        // percentages of respective swaps
        uint256 total = _taxRates.liquidity.add(_taxRates.treasury);
        uint256 totalMinusLiq = total.sub(_taxRates.liquidity.div(2));
        uint256 toBeSwappedPerc = totalMinusLiq.mul(1000).div(total);
        
        uint256 liqEthPerc = _taxRates.liquidity.div(2).mul(1000).div(totalMinusLiq);
        
        swapTokensForETH(balanceOf(MY_ADDR).mul(toBeSwappedPerc).div(1000));
        
        uint256 ethForLiq = MY_ADDR.balance.mul(liqEthPerc).div(1000);
        uint256 ethForTreasury = MY_ADDR.balance.sub(ethForLiq);
        
        if (ethForLiq != 0) {
            uint256 tokensForLiq = balanceOf(MY_ADDR);
            addLiquidity(tokensForLiq, ethForLiq);
            emit AddedLiquidity(tokensForLiq, ethForLiq);
        }
        treasuryAddr.transfer(ethForTreasury);
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(MY_ADDR, ROUTER_ADDR, tokenAmount);

        ROUTER.addLiquidityETH{value: ethAmount}(
            MY_ADDR,
            tokenAmount,
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }

    function _tokenTransferWithoutFees(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _tokenTransferWithFees(address sender, address recipient, uint256 tAmount) private {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);

        // getting tax values
        Taxes memory tTaxValues = _getTTaxValues(tAmount, _taxRates);
        Taxes memory rTaxValues = _getRTaxValues(tTaxValues);
        
        uint256 rTransferAmount = _getTransferAmount(rAmount, rTaxValues);
        uint256 tTransferAmount = _getTransferAmount(tAmount, tTaxValues);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _rOwned[MY_ADDR] = _rOwned[MY_ADDR].add(rTaxValues.treasury).add(rTaxValues.liquidity);
        _rTotal = _rTotal.sub(rTaxValues.redistribution);
        
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = MY_ADDR;
        path[1] = WETH_ADDR;

        _approve(MY_ADDR, ROUTER_ADDR, tokenAmount);

        ROUTER.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            payable(this),
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function _getRate() private view returns(uint256) {
        return _rTotal.div(_tTotal);
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less or equal than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _getTTaxValues(uint256 amount, Taxes memory taxRates) private pure returns (Taxes memory) {
        Taxes memory taxValues;
        taxValues.redistribution = amount.div(1000).mul(taxRates.redistribution);
        taxValues.treasury = amount.div(1000).mul(taxRates.treasury);
        taxValues.liquidity = amount.div(1000).mul(taxRates.liquidity);
        return taxValues;
    }

    function _getRTaxValues(Taxes memory tTaxValues) private view returns (Taxes memory) {
        Taxes memory taxValues;
        uint256 currentRate = _getRate();
        taxValues.redistribution = tTaxValues.redistribution.mul(currentRate);
        taxValues.treasury = tTaxValues.treasury.mul(currentRate);
        taxValues.liquidity = tTaxValues.liquidity.mul(currentRate);
        return taxValues;
    }

    function _getTransferAmount(uint256 amount, Taxes memory taxValues) private pure returns (uint256) {
        return amount.sub(taxValues.treasury).sub(taxValues.liquidity).sub(taxValues.redistribution);
    }

    function openTrading() external onlyOwner() {
        tradingEnabled = true;
    }

    function manualTaxConv() external view onlyOwner() {
        _doTheSwap;
    }

    function setWhitelist(address addr, bool onoff) external onlyOwner() {
        whitelist[addr] = onoff;
    }

    function setTreasuryWallet(address payable treasury) external onlyOwner() {
        treasuryAddr = treasury;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
    }
    
    function setTaxesDisabled(bool onoff) external onlyOwner() {
        taxesDisabled = onoff;
    }
    
    function setSwapEnabled(bool onoff) external onlyOwner() {
        swapEnabled = onoff;
    }
    
    function convertToStandardToken() external onlyOwner() {
        isNormalToken = true;
    }
    
    function setTaxes(uint256 liquidity, uint256 redistribution, uint256 treasury) external onlyOwner {
        require(treasury.add(redistribution).add(liquidity) <= 120, "The taxes are too high, sire. ");
        _taxRates.liquidity = liquidity;
        _taxRates.redistribution = redistribution;
        _taxRates.treasury = treasury;
    }
}

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }
}

interface IUniswapV2Router02  {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}