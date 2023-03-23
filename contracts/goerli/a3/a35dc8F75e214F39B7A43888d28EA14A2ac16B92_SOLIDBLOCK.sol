/**
 *Submitted for verification at Etherscan.io on 2023-03-23
*/

//
//░██████╗░█████╗░██╗░░░░░██╗██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
//██╔════╝██╔══██╗██║░░░░░██║██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
//╚█████╗░██║░░██║██║░░░░░██║██║░░██║██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
//░╚═══██╗██║░░██║██║░░░░░██║██║░░██║██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
//██████╔╝╚█████╔╝███████╗██║██████╔╝██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
//╚═════╝░░╚════╝░╚══════╝╚═╝╚═════╝░╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝



// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer (address indexed from, address indexed to, uint value);
    event Approval (address indexed owner, address indexed spender, uint value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addTreasuryETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint treasury);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

    

contract SOLIDBLOCK is IERC20, Ownable {

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTransactionLimit;
	mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isBot;
    mapping(address => bool) private _isPair;

    address[] private _excluded;
    
    bool private swapping;
    mapping(address => bool) private _operator;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 200_000_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    
    uint256 public swapTokensAtAmount = 1_000 * 10 ** 6;
    uint256 public maxTxAmount = 50_000_000_000 * 10**_decimals;
    uint256 public maxWalletAmount = 1_000_000_000 * 10**_decimals;
    
    // Anti Dump //
    mapping (address => uint256) public _lastTrade;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 30 seconds;

    address public treasuryAddress = 0x15564669B5E6737785B0b36875fC7668Fe4CAc01;
    address public developmentAddress = 0xF8449D6a454469732aD0c7f83d8a018d967BF588 ;
    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    address public USDT = 0x4a31f6A10D6A6777376E879bD225Cc1E64A88509;

    string private constant _name = "SOLIDBLOCK";
    string private constant _symbol = "SOLID";

    // Black List //
    mapping (address => bool) private _isBlocked;

    // Trading
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;
    bool public isTradingEnabled;
    mapping (address => bool) private _isAllowedToTradeWhenDisabled;
    
    struct Taxes {
      uint256 rfi;
      uint256 treasury;
      uint256 development;
      uint256 burn;
    }

    Taxes public taxes = Taxes(10,40,20,10);

    struct TotFeesPaidStruct {
        uint256 rfi;
        uint256 treasury;
        uint256 development;
        uint256 burn;
    }

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rTreasury;
      uint256 rDevelopment;
      uint256 rBurn;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tTreasury;
      uint256 tDevelopment;
      uint256 tBurn;
    }
    
    struct splitETHStruct{
        uint256 treasury;
        uint256 development;
    }

    splitETHStruct private splitETH = splitETHStruct(40,10);

    struct ETHAmountStruct{
        uint256 treasury;
        uint256 development;
    }

    ETHAmountStruct public ETHAmount;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);   
    event BlockedAccountChange(address indexed holder, bool indexed status);
    event FeesChanged();
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event TradingStatusChange(bool indexed newValue, bool indexed oldValue);
    event PresaleStatusChange(bool indexed newValue, bool indexed oldValue);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    modifier addressValidation(address _addr) {
        require(_addr != address(0), 'SOLIDBLOCK: Zero address');
        _;
    }

    modifier onlyOperatorOrOwner() {
        require(_operator[msg.sender] || owner() == msg.sender, "Caller is not an operator");
        //require(_operator == msg.sender || owner() == msg.sender, "operator: caller is not the operator or owner");
        _;
    }

    constructor () {
        IRouter _router = IRouter(0xadF53d7f35aA891a40B1e80f80CDA93ceAA6FEB8);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        addPair(pair);
    
        excludeFromReward(pair);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasuryAddress] = true;
        _isExcludedFromFee[burnAddress] = true;
        _isExcludedFromFee[developmentAddress] = true;

        _isExcludedFromMaxTransactionLimit[address(this)] = true;
		_isExcludedFromMaxTransactionLimit[owner()] = true;
        _isExcludedFromMaxTransactionLimit[_pair] = true;
        _isExcludedFromMaxTransactionLimit[address(_router)] = true;

		_isExcludedFromMaxWalletLimit[_pair] = true;
		_isExcludedFromMaxWalletLimit[address(_router)] = true;
		_isExcludedFromMaxWalletLimit[address(this)] = true;
		_isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[burnAddress] = true;


        emit Transfer(address(0), owner(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length <= 200, "Invalid length");
        require(account != owner(), "Owner cannot be excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
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

    function isOperator(address operator) public view returns (bool) {
    return _operator[operator];
    }

    function _setOperator(address operator_, bool hasPermission) external onlyOwner {
    require(operator_ != address(0), "Invalid operator address");
    _operator[operator_] = hasPermission;
    }   


    function excludeFromFee(address account) public onlyOperatorOrOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOperatorOrOwner {
        _isExcludedFromFee[account] = false;
    }


    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner{
		require(_isExcludedFromMaxTransactionLimit[account] != excluded, "SOLIDBLOCK: Account is already the value of 'excluded'");
		_isExcludedFromMaxTransactionLimit[account] = excluded;
	}

    function isExcludedFromMaxTransactionLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxTransactionLimit[account];
    }

	function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner{
		require(_isExcludedFromMaxWalletLimit[account] != excluded, "SOLIDBLOCK: Account is already the value of 'excluded'");
		_isExcludedFromMaxWalletLimit[account] = excluded;
	}

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }


    function blockAccount(address account) external onlyOwner{
		require(!_isBlocked[account], "SOLIDBLOCK: Account is already blocked");
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}

	function unblockAccount(address account) external onlyOwner{
		require(_isBlocked[account], "SOLIDBLOCK: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}

    function activateTrading() external onlyOwner{
		isTradingEnabled = true;
        if (_launchStartTimestamp == 0) {
            _launchStartTimestamp = block.timestamp;
            _launchBlockNumber = block.number;
        }
		emit TradingStatusChange(true, false);
	}
	function deactivateTrading() external  onlyOwner{
		isTradingEnabled = false;
		emit TradingStatusChange(false, true);
	}
	function allowTradingWhenDisabled(address account, bool allowed)  external onlyOwner{
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}

    function addPair(address _pair) public onlyOwner {
        _isPair[_pair] = true;
    }

    function removePair(address _pair) public onlyOwner {
        _isPair[_pair] = false;
    }

    function isPair(address account) public view returns(bool){
        return _isPair[account];
    }

    function setTaxes(uint256 _rfi, uint256 _treasury, uint256 _development, uint256 __burn) public {
        taxes.rfi = _rfi;
        taxes.treasury = _treasury;
        taxes.development = _development;
        taxes.burn = __burn;
        emit FeesChanged();
    }

    function setSplitETH(uint256 _treasury, uint256 _development) public {
        splitETH.treasury = _treasury;
        splitETH.development = _development;
        emit FeesChanged();
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takeTreasury(uint256 rTreasury, uint256 tTreasury) private {
        totFeesPaid.treasury += tTreasury;
        if(_isExcluded[treasuryAddress]) _tOwned[treasuryAddress] += tTreasury;
        _rOwned[treasuryAddress] +=rTreasury;
    }
    
    function _takeDevelopment(uint256 rDevelopment, uint256 tDevelopment) private{
        totFeesPaid.development += tDevelopment;
        if(_isExcluded[developmentAddress]) _tOwned[developmentAddress] += tDevelopment;
        _rOwned[developmentAddress] += rDevelopment;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        totFeesPaid.burn += tBurn;
        if(_isExcluded[developmentAddress])_tOwned[burnAddress] += tBurn;
        _rOwned[burnAddress] += rBurn;
    }

    function _getValues(uint256 tAmount, uint8 takeFee) private returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rTreasury,to_return.rDevelopment, to_return.rBurn) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }


    function _getTValues(uint256 tAmount, uint8 takeFee) private returns (valuesFromGetValues memory s) {

        if(takeFee == 0) {
          s.tTransferAmount = tAmount;
          return s;
        } else if(takeFee == 1){
            s.tRfi = (tAmount*taxes.rfi)/1000;
            s.tTreasury = (tAmount*taxes.treasury)/1000;
            s.tDevelopment = tAmount*taxes.development/1000;
            s.tBurn = tAmount*taxes.burn/1000;
            ETHAmount.treasury += s.tTreasury*splitETH.treasury/taxes.treasury;
            ETHAmount.development += s.tTreasury*splitETH.development/taxes.treasury;
            s.tTransferAmount = tAmount-s.tRfi-s.tDevelopment-s.tTreasury-s.tBurn;
            return s;
        } else {
            s.tRfi = tAmount*taxes.rfi/1000;
            s.tBurn = tAmount*taxes.burn/1000;
            s.tTreasury = tAmount*splitETH.development/1000;
            ETHAmount.development += s.tTreasury;
            s.tTransferAmount = tAmount-s.tRfi-s.tTreasury-s.tBurn;
            return s;
        }
        
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, uint8 takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi,uint256 rTreasury,uint256 rDevelopment,uint256 rBurn) {
        rAmount = tAmount*currentRate;

        if(takeFee == 0) {
          return(rAmount, rAmount, 0,0,0,0);
        }else if(takeFee == 1){
            rRfi = s.tRfi*currentRate;
            rTreasury = s.tTreasury*currentRate;
            rDevelopment = s.tDevelopment*currentRate;
            rBurn = s.tBurn*currentRate;
            rTransferAmount =  rAmount-rRfi-rTreasury-rDevelopment-rBurn;
            return (rAmount, rTransferAmount, rRfi,rTreasury,rDevelopment,rBurn);
        }
        else{
            rRfi = s.tRfi*currentRate;
            rDevelopment = s.tDevelopment*currentRate;
            rBurn = s.tBurn*currentRate;
            rTransferAmount =  rAmount-rRfi-rTreasury-rDevelopment-rBurn;
            return (rAmount, rTransferAmount, rRfi,rTreasury,rDevelopment,rBurn);
        }

    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }

        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
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
        require(amount > 0, "Zero amount");
        require(amount <= balanceOf(from),"Insufficient balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");

        if(!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
			require(isTradingEnabled, "SOLIDBLOCK: Trading is currently disabled.");
            require(!_isBlocked[to], "SOLIDBLOCK: Account is blocked");
			require(!_isBlocked[from], "SOLIDBLOCK: Account is blocked");
			if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
				require(amount <= maxTxAmount, "SOLIDBLOCK: Buy amount exceeds the maxTxBuyAmount.");
			}
			if (!_isExcludedFromMaxWalletLimit[to]) {
				require((balanceOf(to) + amount) <= maxWalletAmount, "SOLIDBLOCK: Expected wallet amount exceeds the maxWalletAmount.");

            }
		}

        if (coolDownEnabled) {
            uint256 timePassed = block.timestamp - _lastTrade[from];
            require(timePassed > coolDownTime, "You must wait coolDownTime");
        }
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping) {//check this !swapping
            if(_isPair[from] || _isPair[to]) {
                _tokenTransfer(from, to, amount, 1);
            } else {
                _tokenTransfer(from, to, amount, 2);
            }
        } else {
            _tokenTransfer(from, to, amount, 0);
        }

        _lastTrade[from] = block.timestamp;
        
        if(!swapping && from != pair && to != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            address[] memory path = new address[](3);
                path[0] = address(this);
                path[1] = router.WETH();
                path[2] = USDT;
            uint _amount = router.getAmountsOut(balanceOf(address(this)), path)[2];
            if(_amount >= swapTokensAtAmount) swapTokensForETH(balanceOf(address(this)));
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint8 takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if(s.rTreasury > 0 || s.tTreasury > 0){
            _takeTreasury(s.rTreasury, s.tTreasury);
            emit Transfer(sender, treasuryAddress, s.tTreasury);
        }
        if(s.rDevelopment > 0 || s.tDevelopment > 0){
            _takeDevelopment(s.rDevelopment, s.tDevelopment);
            emit Transfer(sender, developmentAddress, s.tDevelopment);
        }
        if(s.rBurn > 0 || s.tBurn > 0){
            _takeBurn(s.rBurn, s.tBurn);
            emit Transfer(sender, burnAddress, s.tBurn);
        }
        
        emit Transfer(sender, recipient, s.tTransferAmount);
        
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
                path[0] = address(this);
                path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        (bool success, ) = treasuryAddress.call{value: (ETHAmount.treasury * address(this).balance)/tokenAmount}("");
        require(success, 'ETH_TRANSFER_FAILED');
        ETHAmount.treasury = 0;

        (success, ) = developmentAddress.call{value: (ETHAmount.development * address(this).balance)/tokenAmount}("");
        require(success, 'ETH_TRANSFER_FAILED');
        ETHAmount.development = 0;
    }

    function updateTreasuryWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(treasuryAddress != newWallet, 'SOLIDBLOCK: Wallet already set');
        treasuryAddress = newWallet;
        _isExcludedFromFee[treasuryAddress];
    }

    function updateDevelopmentWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(developmentAddress != newWallet, 'SOLIDBLOCK: Wallet already set');
        developmentAddress = newWallet;
        _isExcludedFromFee[developmentAddress];
    }

    function updateStableCoin(address _usdt) external onlyOwner addressValidation(_usdt) {
        require(USDT != _usdt, 'SOLIDBLOCK: Wallet already set');
        USDT = _usdt;
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner{
        require(amount >= 100);
        maxTxAmount = amount * 10**_decimals;
    }

    function updateMaxWalletAmt(uint256 amount) external onlyOwner{
        require(amount >= 100);
        maxWalletAmount = amount * 10**_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        require(amount > 0);
        swapTokensAtAmount = amount * 10**6;
    }

    function updateCoolDownSettings(bool _enabled, uint256 _timeInSeconds) external onlyOwner{
        coolDownEnabled = _enabled;
        coolDownTime = _timeInSeconds * 1 seconds;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, 'SOLIDBLOCK: Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner {
        require(accounts.length <= 100, "SOLIDBLOCK: Invalid");
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner {
        router = IRouter(newRouter);
        pair = newPair;
        addPair(pair);
    }

    function updateRouterWithoutPair(address newRouter) external onlyOwner {
    require(newRouter != address(0), "Invalid router address");

    router = IRouter(newRouter);

    address newPair = IFactory(router.factory()).createPair(address(this), router.WETH());
    require(newPair != address(0), "Failed to create new pair");

    pair = newPair;
    addPair(pair);
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
    
    function airdropTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length,"Invalid size");
         address sender = msg.sender;

        for(uint256 i; i<recipients.length; i++){
            address recipient = recipients[i];
            uint256 rAmount = amounts[i]*_getRate();
            _rOwned[sender] = _rOwned[sender]- rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rAmount;
            emit Transfer(sender, recipient, amounts[i]);
        }
    }

    //Use this in case ETH are sent to the contract by mistake
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(owner()).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out catecoin from this smart contract
    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable {
    }
}