/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(address target, bool success, bytes memory returndata, string memory errorMessage) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {

                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
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

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    using Address for address payable;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public _balances;
    mapping(address => bool) feeExempt;
    mapping(address => bool) lpHolder;
    mapping(address => bool) lpPairs;
    mapping(address => bool) maxWalletExempt;

    uint256 _totalSupply;
    uint256 tokensToSwap;
    uint256 lastSwap;
    uint256 maxTxAmount;
    uint256 maxWalletAmount;
    uint256 feeAmount;
    uint16 marketingFee;
    uint16 public sellMarketingFee;
    uint16 public buyMarketingFee;
    uint16 public transferMarketingFee;
    uint8 swapDelay;
    uint feeDenominator = 1000; // 10 = 1%

    bool swapEnabled;
    bool feeEnabled;
    bool tradingOpen;
    bool txLimits;

    address public ownerWallet;
    address public marketingWallet;
    address public pair;

    string private _name;
    string private _symbol;

    IRouter public router;

    modifier onlyOwner() {
        require(isOwner(msg.sender), "You are not the owner");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 startingSupply, address _marketingWallet) {
        _name = name_;
        _symbol = symbol_;
        _mint(_msgSender(), startingSupply * (10**9));

        ownerWallet = _msgSender();
        setMarketingWallet(_marketingWallet);
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IFactory(router.factory()).createPair(router.WETH(), address(this));
        lpHolder[_msgSender()] = true;
        lpPairs[pair] = true;

        _approve(address(this), address(router), type(uint256).max);
        _approve(_msgSender(), address(router), type(uint256).max);

        maxWalletExempt[_msgSender()] = true;
        maxWalletExempt[address(this)] = true;
        maxWalletExempt[pair] = true;

        feeExempt[address(this)] = true;
        feeExempt[_msgSender()] = true;


        maxTxAmount = (_totalSupply * 1) / (100);
        maxWalletAmount = (_totalSupply * 2) / 100;

        txLimits = true;
        setSwapBackSettings(true, 5, 10);
        feeEnabled = true;
    }

    receive() external payable {}

    function name() public view override returns (string memory) {
        return _name;
    }
 
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
     
    function renounceOwnership(bool keepLimits) external onlyOwner {
        emit OwnershipRenounced();
        setExemptions(ownerWallet, false, false, false);
        limitsInEffect(keepLimits);
        ownerWallet = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address, use renounceOwnership Function");
        emit OwnershipTransferred(ownerWallet, newOwner);

        if(balanceOf(ownerWallet) > 0) _transfer(ownerWallet, newOwner, balanceOf(ownerWallet));
        setExemptions(ownerWallet, false, false, false);
        setExemptions(newOwner, true, true, true);

        ownerWallet = newOwner;
    }

    function clearStuckBalance(uint256 percent) external onlyOwner {
        require(percent <= 100);
        uint256 amountEth = address(this).balance;
        payable(marketingWallet).sendValue((amountEth* percent) / 100);
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0) && _token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function setTransactionLimits(uint256 percent, uint256 divisor, bool maxTx) external onlyOwner() {
        if(maxTx){
            require(percent >= 1 && divisor <= 1000, "Max Transaction must be set above .1%");
            maxTxAmount = (_totalSupply * percent) / (divisor);
        } else {
            require(percent >= 1 && divisor <= 100, "Max Wallet must be set above 1%");
            maxWalletAmount = (_totalSupply * percent) / divisor;
        }
    }

    function setExemptions(address holder, bool lpHolders, bool _feeExempt, bool _maxWalletExempt) public onlyOwner(){
        maxWalletExempt[holder] = _maxWalletExempt;
        feeExempt[holder] = _feeExempt;
        lpHolder[holder] = lpHolders;
    }

    function limitsInEffect(bool limit) public onlyOwner() {
        txLimits = limit;
    }

    function setPair(address pairing, bool lpPair) external onlyOwner {
        lpPairs[pairing] = lpPair;
    }

    function setBuyFee(uint16 fee) external onlyOwner {
        require(fee <= 100);
        buyMarketingFee = fee;
    }
    
    function setTransferFee(uint16 fee) external onlyOwner {
        require(fee <= 100);
        transferMarketingFee = fee;
    }

    function setSellFee(uint16 fee) external onlyOwner {
        require(fee <= 100);
        sellMarketingFee = fee;
    } 
    function setFeeEnabled(bool enabled) external onlyOwner {
        feeEnabled = enabled;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function setSwapBackSettings(bool _enabled, uint8 interval, uint256 _amount) public onlyOwner{
        swapEnabled = _enabled;
        swapDelay = interval;
        tokensToSwap = (_totalSupply * (_amount)) / (10000);
    }

    function limits(address from, address to) private view returns (bool) {
        return !isOwner(from)
            && !isOwner(to)
            && tx.origin != ownerWallet
            && !lpHolder[from]
            && !lpHolder[to]
            && to != address(0xdead)
            && from != address(this);
    }

    function massAirDropTokens(address[] memory addresses, uint256[] memory amounts) external {
        require(addresses.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < addresses.length; i++) {
            require(balanceOf(_msgSender()) >= amounts[i]*10**9);
            _transfer(_msgSender(), addresses[i], amounts[i]*10**9);
        }
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        if(!tradingOpen) {
            require(isOwner(from));                
            if(to == pair) {
                tradingOpen = true;
                emit Launched();
            }
        }
        _beforeTokenTransfer(from, to, amount);

        uint256 amountReceived = feeEnabled && !feeExempt[from] ? takeFee(from, to, amount) : amount;

        uint256 fromBalance = _balances[from];
        unchecked {
            _balances[from] = fromBalance - amountReceived;
            _balances[to] += amountReceived;
        }
        emit Transfer(from, to, amountReceived);

        if(!lpPairs[_msgSender()] 
        && swapEnabled 
        && block.timestamp >= lastSwap + swapDelay 
        && _balances[address(this)] >= tokensToSwap) {
            lastSwap = block.timestamp;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokensToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
    
            uint256 balance = address(this).balance;
            payable(marketingWallet).sendValue(balance);
        }
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if (feeExempt[receiver]) {
            return amount;
        }
        if(lpPairs[receiver]) {   
            marketingFee = sellMarketingFee;         
        } else if(lpPairs[sender]){
            marketingFee = buyMarketingFee;    
        } else {
            marketingFee = transferMarketingFee;
        }

        feeAmount = (amount * marketingFee) / feeDenominator;
        uint256 senderBalance = _balances[sender];
        unchecked {
            _balances[sender] = senderBalance - feeAmount;
            _balances[address(this)] += feeAmount;
        }

        emit Transfer(sender, address(this), feeAmount);

        return amount - feeAmount;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view {
        if(limits(from, to) && tradingOpen && txLimits){
            if(!maxWalletExempt[to]){
                require(amount <= maxTxAmount && balanceOf(to) + amount <= maxWalletAmount);
            } else if(lpPairs[to]){
                require(amount <= maxTxAmount);
            }
        }
    }

    function getTransactionLimits() external view returns(uint maxTransaction, uint maxWallet, bool transactionLimits){
        if(txLimits){
            maxTransaction = maxTxAmount / 10**9;
            maxWallet = maxWalletAmount / 10**9;
            transactionLimits = txLimits;
        } else {
            maxTransaction = totalSupply();
            maxWallet = totalSupply();
            transactionLimits = false;
        }
    }

    function isOwner(address account) public view returns (bool) {
        return account == ownerWallet;
    }

    event Launched();
    event OwnershipRenounced();
    event OwnershipTransferred(address oldOwner, address newOwner);
}