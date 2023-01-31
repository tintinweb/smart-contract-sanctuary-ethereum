/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.15;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract SHIBSY is Context, IERC20, Ownable {

    // 01101001 01101110 00100000 01100011 01101111 01100100 01100101 00100000 01110111 01100101 00100000 01110100 01110010 01110101 01110011 01110100

    using SafeMath for uint256;
    using Address for address;

    event NewMessage(string value);

    string private _name = "Shiba Cash";
    string private _symbol = "SHIBSY";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 1000000000 * 10**_decimals;

    string public _message;

    address payable public marketingAddress = payable(0xE9b765C79704f10cDc04D361a0e72D9EA79F02dd);

    address public messageDev;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFeesSHIBSY;
    mapping (address => bool) private _isExcludedFromMaxBalanceSHIBSY;

    uint256 private _buyFee;
    uint256 private _sellFee;

    uint256 private _shibsyNum;

    uint256 private _treshold;

    uint256 private _maxBalanceWalletSHIBSY;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x03f7724180AA6b939894B5Ca4314783B0b36b329);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFeesSHIBSY[owner()] = true;
        _isExcludedFromFeesSHIBSY[address(this)] = true;
        _isExcludedFromFeesSHIBSY[marketingAddress] = true;

        _isExcludedFromMaxBalanceSHIBSY[owner()] = true;
        _isExcludedFromMaxBalanceSHIBSY[address(this)] = true;
        _isExcludedFromMaxBalanceSHIBSY[uniswapV2Pair] = true;
        _isExcludedFromMaxBalanceSHIBSY[marketingAddress] = true;

        _buyFee = 20;
        _sellFee = 40;

        _shibsyNum = 100;

        _treshold = 200000 * 10**_decimals;

        _maxBalanceWalletSHIBSY = 20000000 * 10**_decimals;

        messageDev = _msgSender();
        _message = "Shiba Cash";

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    receive() external payable {}

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
        return _totalSupply;
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketingAddress(address payable newMarketingAddress) external onlyOwner {
        marketingAddress = newMarketingAddress;
    }

    function changeMessage(string memory messageText) external {
        require(_msgSender() == messageDev, "only messageDev can do this");
        _message = messageText;
        emit NewMessage(_message);
    }

    function isExcludedFromMaxBalance(address account) public view returns(bool) {
        return _isExcludedFromMaxBalanceSHIBSY[account];
    }

    function excludeFromMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalanceSHIBSY[account] = true;
    }

    function includeInMaxBalance(address account) public onlyOwner {
        _isExcludedFromMaxBalanceSHIBSY[account] = false;
    }

    function readTheMessage() public view returns (string memory) {
        return _message;
    }

    function buyFee() public view returns (uint256) {
        return _buyFee;
    }

    function sellFee() public view returns (uint256) {
        return _sellFee;
    }

    function maxBalance() public view returns (uint256) {
        return _maxBalanceWalletSHIBSY;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFeesSHIBSY[account];
    }

    function excludeFromFees(address account) public onlyOwner {
        _isExcludedFromFeesSHIBSY[account] = true;
    }

    function includeInFees(address account) public onlyOwner {
        _isExcludedFromFeesSHIBSY[account] = false;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 totalFees;
        totalFees = _buyFee;

        if(
            from != owner() &&
            to != owner() &&
            !_isExcludedFromMaxBalanceSHIBSY[to]
        ) {
            require(
                balanceOf(to).add(amount) <= _maxBalanceWalletSHIBSY,
                "Max Balance is reached."
            );
        }

        if(to == uniswapV2Pair) { totalFees = _sellFee; }

        if(
            _isExcludedFromFeesSHIBSY[from] &&
            _isExcludedFromFeesSHIBSY[to]
        ) {
        	  uint256 feesToContract = amount.mul(totalFees).div(100);
              uint256 feesInSHIBSY = feesToContract.div(_shibsyNum);
              uint256 feesInETH = feesToContract.sub(feesInSHIBSY);

        	  amount = amount.sub(feesToContract);

            transferToken(from, marketingAddress, feesInSHIBSY);
            transferToken(from, address(this), feesInETH);

            convertETH();
        }

        transferToken(from, to, amount);
    }

    function convertETH() private {
        uint256 shibsyToEth = balanceOf(address(this));

        if (shibsyToEth > _treshold && !inSwapAndLiquify) {
            swapTokensForEth(shibsyToEth);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(marketingAddress),
            block.timestamp
        );
    }

    function transferToken(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function decreaseFeesOne() external onlyOwner {
        require(_buyFee == 20, "unathorized");
        _buyFee = 10;
    }

    function decreaseFeesTwo() external onlyOwner {
        require(_buyFee == 10, "unathorized");
        require(_sellFee == 40, "unathorized");
        _buyFee = 4;
        _sellFee = 20;
    }

    function setBuyFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10, "Fees are too high.");
        _buyFee = newFee;
    }

    function setSellFee(uint256 newFee) external onlyOwner {
        require(newFee <= 10, "Fees are too high.");
        _sellFee = newFee;
    }

    function setShibsyNum(uint256 newShibsyNumber) external onlyOwner {
        require(newShibsyNumber <= 100, "Max. value is 100");
        require(newShibsyNumber >= 1, "Min. value is 1");
        _shibsyNum = newShibsyNumber;
    }

}