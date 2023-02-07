/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
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
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract DWORM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    address payable private infrastructure;
        
    mapping(address => uint256) private _holders;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    mapping(address => bool) private _isExcludedFromFee;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 580_000_000 * 1e9;
 
    string private constant _name = "DWORM";
    string private constant _symbol = "DWORM";
    uint8 private constant _decimals = 9;

    uint256 private _taxFee;
    uint256 private _previousTaxFee = _taxFee;
    

    uint256 public _buyTaxFee = 4;
    uint256 public _sellTaxFee = 4;
        
    uint256 public maxHoldAmount;
    uint256 public maxTxnAmount;
    mapping (address => bool) public _isExcludedMaxHoldAmount;
    mapping (address => bool) public _isExcludedFromTxnAmount;
        

    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 private minimumTokensBeforeSwap;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public tradingActive = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
            
    event TransferForeignToken(address token, uint256 amount);
    
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _holders[_msgSender()] = _tTotal;
     
        maxHoldAmount = _tTotal.mul(4).div(100); 
        maxTxnAmount = _tTotal.mul(2).div(100); 
        minimumTokensBeforeSwap = 100_000 * 1e9;
        
        infrastructure = payable(0x101CcBb1Dcc5923424402db8C845B56EE0242007); 
        
    
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[infrastructure] = true;
        
        _isExcludedMaxHoldAmount[owner()] = true;
        _isExcludedMaxHoldAmount[address(0)] = true;
        _isExcludedMaxHoldAmount[address(this)] = true;
        _isExcludedMaxHoldAmount[infrastructure] = true;

        _isExcludedFromTxnAmount[owner()] = true;
        _isExcludedFromTxnAmount[address(this)] = true;
        _isExcludedFromTxnAmount[infrastructure] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _holders[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }
    
    function toggleAccountMaxHold(address account, bool status) public onlyOwner {
        _isExcludedMaxHoldAmount[account] = status;
    }

    function toggleAccountMaxTxn(address account, bool status) public onlyOwner {
        _isExcludedFromTxnAmount[account] = status;
    }
    
    // once enabled, can never be turned off
    function enableTrading() public onlyOwner {
        require(!tradingActive, "trading is already active");
        tradingActive = true;
        swapAndLiquifyEnabled = true;
    }
    
    function launch(address[] memory airdropWallets, uint256[] memory amounts) external onlyOwner returns (bool){
        require(!tradingActive, "trading is already active");
        require(airdropWallets.length < 100, "max 100 wallets");
        for(uint256 i = 0; i < airdropWallets.length; i++){
            address wallet = airdropWallets[i];
            uint256 amount = amounts[i];
            _transfer(msg.sender, wallet, amount);
        }
        enableTrading();
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        toggleAccountMaxHold(address(_uniswapV2Router), true);
        toggleAccountMaxTxn(address(_uniswapV2Router), true);

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        toggleAccountMaxHold(address(uniswapV2Pair), true);
        toggleAccountMaxTxn(address(uniswapV2Pair), true);

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        require(address(this).balance > 0, "ETH required for launch");
        addLiquidity(balanceOf(address(this)), address(this).balance);
        swapAndLiquifyEnabled = true;
        return true;
    }
    
    function minimumTokensBeforeSwapAmount() external view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function setMinimumTokensBeforeSwapAmount(uint256 amount) external onlyOwner {
        minimumTokensBeforeSwap = amount;
    }

    function setMaxHoldAmount(uint256 amount) external onlyOwner {
        maxHoldAmount = amount;
    }

    function setMaxTxnAmount(uint256 amount) external onlyOwner {
        maxTxnAmount = amount;
    }
    
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _isExcludedMaxHoldAmount[pair] = value;
        _isExcludedFromTxnAmount[pair] = value;
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!tradingActive){
            require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading is not active yet.");
        }

        if (!_isExcludedMaxHoldAmount[to]) {
            uint256 toBalance = balanceOf(to);
            require(toBalance.add(amount) <= maxHoldAmount, "Exceeded max hold");
        }

        if (!_isExcludedFromTxnAmount[from]) {
            require(amount <= maxTxnAmount);
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        // swap and liquify
        if (
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled &&
            balanceOf(uniswapV2Pair) > 0 &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from] &&
            automatedMarketMakerPairs[to] &&
            overMinimumTokenBalance
        ) {
            swapBack();
        }

        bool takeFee = true;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from]) {
            takeFee = false;
        } else {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                removeFee();
                _taxFee = _buyTaxFee;
            } 
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                removeFee();
                _taxFee = _sellTaxFee;
             
            } else {
                removeFee();
            }
        }
        
        _tokenTransfer(from, to, amount, takeFee);
        
    }

    function swapBack() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));               

        swapTokensForETH(contractBalance); 
        
        uint256 ethBalance = address(this).balance;
        
        (bool success,) = address(infrastructure).call{value: ethBalance}("");
        require(success, "Failed to send eth");
    }
    
    function forceSwapBack() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        require(contractBalance >= 100_000 * 1e9, " < 100,000 of tokens stuck");
        swapBack();
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
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

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeFee();

        (
            uint256 transferAmount,
            uint256 tFee
        ) = _getValues(amount);
        _holders[sender] = _holders[sender].sub(amount);
        _holders[address(this)] = _holders[address(this)].add(tFee);
        _holders[recipient] = _holders[recipient].add(transferAmount);

        emit Transfer(sender, recipient, transferAmount);

        if (!takeFee) restoreFee();
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 transferAmount = tAmount.sub(tFee);
        uint256 fees = tFee;
        
        return (transferAmount, fees);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }


    function removeFee() private {
        if (_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    function restoreFee() private {
        _taxFee = _previousTaxFee;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }
    
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setBuyFee(uint256 buyTaxFee)
        external
        onlyOwner
    {
        _buyTaxFee = buyTaxFee;
        require(_buyTaxFee <= 10, " > 10%");
    }

    function setSellFee(uint256 sellTaxFee)
        external
        onlyOwner
    {
        _sellTaxFee = sellTaxFee;
        require(_sellTaxFee  <= 15, " > 15%");
    }

    function setInfrastructureAddress(address _infrastructure) external onlyOwner {
        require(_infrastructure != address(0), "0 address");
        _isExcludedFromFee[infrastructure] = false;
        toggleAccountMaxHold(infrastructure, false);
        toggleAccountMaxTxn(infrastructure, false);

        infrastructure = payable(_infrastructure);
        _isExcludedFromFee[infrastructure] = true;
        toggleAccountMaxHold(infrastructure, true);
        toggleAccountMaxTxn(infrastructure, true);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    // To receive ETH from uniswapV2Router when swapping
    receive() external payable {}

    function transferForeignToken(address _token, address _to)
        external
        onlyOwner
        returns (bool _sent)
    {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "ICHIGO not allowed");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
    
    function withdrawStuckETH() external onlyOwner {
        require(!tradingActive, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }
}