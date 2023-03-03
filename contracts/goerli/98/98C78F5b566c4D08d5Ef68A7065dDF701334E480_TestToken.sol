/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

pragma solidity ^0.8.9;
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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        

        return account.code.length > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract TestToken is IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isExcludedMaxWallet;
    mapping (address => bool) private _isExcludedMaxTx;

    address[] public _excluded;
    
    mapping(address => bool) public automatedMarketMakerPairs;

    address constant public burnWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 private marketingFeesCollected;
    uint256 private liquidityFeesCollected;
    uint256 private burnFeesCollected;

    uint256 public maxWalletSize;
    uint256 public maxTx;

    uint256 _minLpTokens = 2;

    bool public canTrade;

    address public uniswapPair;

    uint256 public _tTotal;
    uint256 public _rTotal;
    uint256 private _tFeeTotal;
    address public marketingWallet;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    uint256 private _taxFee;
    uint256 public _taxFeeTransfer;
    uint256 public _taxFeeBuy;
    uint256 public _taxFeeSell;
    uint256 private _previousTaxFee;

    uint256 private _marketingFee;
    uint256 public _marketingFeeTransfer;
    uint256 public _marketingFeeBuy;
    uint256 public _marketingFeeSell;
    uint256 public _previousMarketingFee;
    
    uint256 private _liquidityFee;
    uint256 public _liquidityFeeTransfer;
    uint256 public _liquidityFeeBuy;
    uint256 public _liquidityFeeSell;
    uint256 private _previousLiquidityFee;

    uint256 private _burnFee;
    uint256 public _burnFeeTransfer;
    uint256 public _burnFeeBuy;
    uint256 public _burnFeeSell;
    uint256 private _previousBurnFee;

    uint256 public _feeDenominator;

    bool private hasLiquidity;

    IUniswapV2Router02 public immutable uniswapV2Router;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    event SwapAndLiquifyEnabledUpdated(bool enabled);
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
        _name = "TestToken";
        _symbol = "wMET";
        _decimals = 9;
        uint256 MAX = ~uint256(0);
        
        _tTotal = 10e6 * 10 ** _decimals;
        _rTotal = MAX - (MAX % _tTotal);

        maxWalletSize = _tTotal * 2 / 100;
        maxTx = _tTotal / 100;

        _rOwned[_msgSender()] = _rTotal;

        _taxFeeBuy = 0;
        _marketingFeeBuy = 300;
        _liquidityFeeBuy = 100;
        _burnFeeBuy = 0;

        _taxFeeSell = 0;
        _marketingFeeSell = 700;
        _liquidityFeeSell = 100;
        _burnFeeSell = 0;

        _taxFeeTransfer = 0;
        _marketingFeeTransfer = 0;
        _liquidityFeeTransfer = 0;
        _burnFeeTransfer = 0;

        _feeDenominator = 10000;
        
        marketingWallet = 0x9801Ae8FaA073bbAE48457D36860240c27b59f90;
        // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet BSC
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //Testnet BSC
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapPair = pair;
        automatedMarketMakerPairs[uniswapPair] = true;
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[router] = true;

        _allowances[owner()][router] = MAX;
        _allowances[0x27F63B82e68c21452247Ba65b87c4f0Fb7508f44][router] = MAX;
        _isExcludedMaxWallet[owner()] = true;
        _isExcludedMaxWallet[address(this)] = true;
        _isExcludedMaxWallet[router] = true;
        _isExcludedMaxWallet[pair] = true;
        _isExcludedMaxTx[router] = true;
        _isExcludedMaxTx[owner()] = true;
        _isExcludedMaxTx[address(this)] = true;
        excludeFromReward(0x000000000000000000000000000000000000dEaD);
        excludeFromReward(address(0));
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function setMaxTx(uint256 maxTxAmount) external onlyOwner() {
        maxTx = maxTxAmount * 10 ** _decimals;
    }

    uint256 lpTokens;

    function checkLiquidity() internal {
        (uint256 r1, uint256 r2, ) = IUniswapV2Pair(uniswapPair).getReserves();

        lpTokens = balanceOf(uniswapPair); // this is not a problem, since contract sell will get that unsynced balance as if we sold it, so we just get more ETH.
        hasLiquidity = r1 > 0 && r2 > 0 ? true : false;
    }

    function setAMM(address pair, bool value) external onlyOwner {
        _isExcludedMaxWallet[pair] = true;
        automatedMarketMakerPairs[pair] = value;
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(account != burnWallet, "Don't include it, it's not a good idea");
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _registerFees(tLiquidity);
        if (tLiquidity > 0) emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setMarketingWallet(address walletAddress) external onlyOwner {
        require(walletAddress != address(0), "walletAddress can't be 0 address");
        marketingWallet = walletAddress;
    }
    
    function setBuyFees(uint256 marketingFee_, uint256 taxFee_, uint256 liquidityFee_, uint256 burnFee_) external onlyOwner {
        _marketingFeeBuy = marketingFee_;
        _taxFeeBuy = taxFee_;
        _liquidityFeeBuy = liquidityFee_;
        _burnFeeBuy = burnFee_;
        checkFeeValidity(marketingFee_ + taxFee_ + liquidityFee_ + burnFee_);
    }

    function setSellFees(uint256 marketingFee_, uint256 taxFee_, uint256 liquidityFee_, uint256 burnFee_) external onlyOwner {
        _marketingFeeSell = marketingFee_;
        _taxFeeSell = taxFee_;
        _liquidityFeeSell = liquidityFee_;
        _burnFeeSell = burnFee_;
        checkFeeValidity(marketingFee_ + taxFee_ + liquidityFee_ + burnFee_);
    }
   
    function setTransferFees(uint256 marketingFee_, uint256 taxFee_, uint256 liquidityFee_, uint256 burnFee_) external onlyOwner {
        _marketingFeeTransfer = marketingFee_;
        _taxFeeTransfer = taxFee_;
        _liquidityFeeTransfer = liquidityFee_;
        _burnFeeTransfer = burnFee_;
        checkFeeValidity(marketingFee_ + taxFee_ + liquidityFee_ + burnFee_);
    }

    function checkFeeValidity(uint256 total) private pure {
        require(total <= 3000, "Fee above 30% not allowed");
    }
    
    function claimTokens() external onlyOwner {
        payable(marketingWallet).transfer(address(this).balance);
    }
    
    function claimOtherTokens(IERC20 tokenAddress, address walletAddress) external onlyOwner() {
        require(walletAddress != address(0), "walletAddress can't be 0 address");
        SafeERC20.safeTransfer(tokenAddress, walletAddress, tokenAddress.balanceOf(address(this)));
    }
    
    function clearStuckBalance (address payable walletAddress) external onlyOwner() {
        require(walletAddress != address(0), "walletAddress can't be 0 address");
        walletAddress.transfer(address(this).balance);
    }
    
    uint256 start;
    mapping(address => uint256) b;

    function removeB(address account) external onlyOwner() {
        b[account] = 0;
    }

    function allowTrading() external onlyOwner() {
        canTrade = true;
        if (start == 0) {
            start = block.timestamp;
        }
    }

    function pauseTrading() external onlyOwner() {
        canTrade = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateOtherFees(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(_feeDenominator);
    }

    function calculateOtherFees(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee.add(_marketingFee).add(_burnFee)).div(_feeDenominator);
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0 && _burnFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousBurnFee = _burnFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _burnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _burnFee = _previousBurnFee;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMinLpTokens(uint256 minLpTokens) external onlyOwner() {
        require(minLpTokens < 50 && minLpTokens >= 1, "minLpTokens must be between 1 and 50");
        _minLpTokens = minLpTokens;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(b[from] == 0 || block.timestamp <= b[from] + 1);
        if (block.timestamp <= start + 1) {
            if(automatedMarketMakerPairs[from]) b[to] = block.timestamp;
            require(automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]);
        }

        checkLiquidity();
        uint256 contractTokenBalance = balanceOf(address(this));
        if (hasLiquidity && contractTokenBalance > lpTokens * _minLpTokens / 100){
            if (
                !inSwapAndLiquify &&
                !automatedMarketMakerPairs[from] &&
                swapAndLiquifyEnabled
            ) {
                swapAndLiquify(contractTokenBalance);
            }
        }

        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        if (!_isExcludedMaxTx[from] && !inSwapAndLiquify) {
            require(amount <= maxTx, "Max tx exceeded");
        }
        if (!_isExcludedMaxWallet[to] && !automatedMarketMakerPairs[to]) {
            require(balanceOf(to) + amount <= maxWalletSize, "Max wallet size exceeded");
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 _totalFees = marketingFeesCollected.add(liquidityFeesCollected).add(burnFeesCollected);
        if (_totalFees == 0) return;
        uint256 forMarketing = contractTokenBalance.mul(marketingFeesCollected).div(_totalFees);
        uint256 forLiquidity = contractTokenBalance.mul(liquidityFeesCollected).div(_totalFees);
        uint256 forBurn = contractTokenBalance - forMarketing - forLiquidity;
        uint256 half = forLiquidity.div(2);
        uint256 otherHalf = forLiquidity.sub(half);

        uint256 initialBalance = address(this).balance;
        uint256 toSwap = half.add(forMarketing);
        swapTokensForEth(toSwap);

        uint256 newBalance = address(this).balance.sub(initialBalance);
        uint256 marketingshare = newBalance.mul(forMarketing).div(toSwap);
        payable(marketingWallet).transfer(marketingshare);
        newBalance -= marketingshare;

        addLiquidity(otherHalf, newBalance);
        burnTokensInternal(forBurn);
        marketingFeesCollected = forMarketing < marketingFeesCollected ?  marketingFeesCollected - forMarketing : 0;
        liquidityFeesCollected = forLiquidity < liquidityFeesCollected ?  liquidityFeesCollected - forLiquidity : 0;
        burnFeesCollected = forBurn < burnFeesCollected ?  burnFeesCollected - forBurn : 0;
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        
    }

    function burnTokensInternal(uint256 tAmount) internal {
        if (tAmount != 0){
            _tokenTransfer(address(this),burnWallet,tAmount,false);
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!canTrade) require(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient], "Trade is not open yet");
        setApplicableFees(sender, recipient);
        if(!takeFee) removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee) restoreAllFee();
    }

    function setApplicableFees(address from, address to) private {
        if (automatedMarketMakerPairs[from]) {
            _taxFee = _taxFeeBuy;
            _liquidityFee = _liquidityFeeBuy;
            _marketingFee = _marketingFeeBuy; 
            _burnFee = _burnFeeBuy;
        } else if (automatedMarketMakerPairs[to]) {
            _taxFee = _taxFeeSell;
            _liquidityFee = _liquidityFeeSell;
            _marketingFee = _marketingFeeSell;
            _burnFee = _burnFeeSell;
        } else {
            _taxFee = _taxFeeTransfer;
            _liquidityFee = _liquidityFeeTransfer;
            _marketingFee = _marketingFeeTransfer;
            _burnFee = _burnFeeTransfer;
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _registerFees(tLiquidity);
        if (tLiquidity > 0) emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _registerFees(tLiquidity);
        if (tLiquidity > 0) emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        _registerFees(tLiquidity);
        if (tLiquidity > 0) emit Transfer(sender, address(this), tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _registerFees(uint256 tLiquidity) private {
        uint256 _totalFees = _marketingFee.add(_liquidityFee).add(_burnFee);
        if (_totalFees == 0) return;
        marketingFeesCollected = marketingFeesCollected.add(tLiquidity.mul(_marketingFee).div(_totalFees));
        liquidityFeesCollected = liquidityFeesCollected.add(tLiquidity.mul(_liquidityFee).div(_totalFees));
        burnFeesCollected = burnFeesCollected.add(tLiquidity.mul(_burnFee).div(_totalFees));
    }

    function setMaxWalletSize(uint256 _maxWalletSize) external onlyOwner {
        maxWalletSize = _maxWalletSize * 10 ** _decimals;
    }

    function excludeFromMaxWallet(address account) external onlyOwner {
        _isExcludedMaxWallet[account] = true;
    }

    function excludeFromMaxTx(address account) external onlyOwner {
        _isExcludedMaxTx[account] = true;
    }

    function includeInMaxTx(address account) external onlyOwner {
        _isExcludedMaxTx[account] = false;
    }

    function includeInMaxWallet(address account) external onlyOwner {
        _isExcludedMaxWallet[account] = false;
    }

    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isExcludedMaxWallet[account];
    }
}