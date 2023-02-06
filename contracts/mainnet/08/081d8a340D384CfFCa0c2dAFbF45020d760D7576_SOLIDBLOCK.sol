/**
 *Submitted for verification at Etherscan.io on 2023-02-06
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


library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }
}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    // Converts a `uint256` to its ASCII `string` hexadecimal representation.
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    // Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    // Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IAccessControl {

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

abstract contract ERC165 is IERC165 {
    // See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    // See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    // Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

contract SOLIDBLOCK is IERC20, Ownable, AccessControl {

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

    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    string private constant _name = "SOLIDBLOCK";
    string private constant _symbol = "SOLID";

    // Black List //
    mapping (address => bool) private _isBlocked;

    // Trading
    uint256 private _launchStartTimestamp;
    uint256 private _launchBlockNumber;
    bool public isTradingEnabled;
    mapping (address => bool) private _isAllowedToTradeWhenDisabled;

    // Presale
    bool public isPresale;
    mapping(address => bool) public whitelisted;
    uint256 public whitelistAccessCount;
    uint256 public presaleMaxWalletAmount = 100000000 * 10**_decimals;

    // Roles
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR_ROLE");
    
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

    constructor () {
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
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

        whitelisted[owner()] = true;
        whitelisted[address(this)] = true;
        whitelisted[treasuryAddress] = true;
        whitelisted[burnAddress] = true;
        whitelisted[developmentAddress] = true;
        whitelisted[burnAddress] = true;
        whitelisted[_pair] = true;

        _isExcludedFromMaxTransactionLimit[address(this)] = true;
		_isExcludedFromMaxTransactionLimit[owner()] = true;

		_isExcludedFromMaxWalletLimit[_pair] = true;
		_isExcludedFromMaxWalletLimit[address(_router)] = true;
		_isExcludedFromMaxWalletLimit[address(this)] = true;
		_isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[burnAddress] = true;
 
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(EDITOR_ROLE, msg.sender);

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


    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
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


    function blockAccount(address account) external{
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a blocker");
		require(!_isBlocked[account], "SOLIDBLOCK: Account is already blocked");
		_isBlocked[account] = true;
		emit BlockedAccountChange(account, true);
	}

	function unblockAccount(address account) external{
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a blocker");
		require(_isBlocked[account], "SOLIDBLOCK: Account is not blcoked");
		_isBlocked[account] = false;
		emit BlockedAccountChange(account, false);
	}

    function activateTrading() external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a pauser");
		isTradingEnabled = true;
        if (_launchStartTimestamp == 0) {
            _launchStartTimestamp = block.timestamp;
            _launchBlockNumber = block.number;
        }
		emit TradingStatusChange(true, false);
	}
	function deactivateTrading() external  {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a pauser");
		isTradingEnabled = false;
		emit TradingStatusChange(false, true);
	}
	function allowTradingWhenDisabled(address account, bool allowed)  external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a pauser");
		_isAllowedToTradeWhenDisabled[account] = allowed;
		emit AllowedWhenTradingDisabledChange(account, allowed);
	}

    function activatePresale() external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a editor");
		isPresale = true;
		emit PresaleStatusChange(true, false);
	}
	function deactivatePresale() external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a editor");
		isPresale = false;
		emit PresaleStatusChange(false, true);
	}

    function addWhiteListAddresses(address[] calldata addresses) external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a lister");
        require(whitelistAccessCount + addresses.length <= 1000, "Whitelist amount exceed");
        for (uint8 i = 0; i < addresses.length; i++)
        whitelisted[addresses[i]] = true;
        whitelistAccessCount += addresses.length;
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

    function _getValues(uint256 tAmount, uint8 takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rTreasury,to_return.rDevelopment, to_return.rBurn) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }


    function _getTValues(uint256 tAmount, uint8 takeFee) private view returns (valuesFromGetValues memory s) {

        if(takeFee == 0) {
          s.tTransferAmount = tAmount;
          return s;
        } else if(takeFee == 1){
            s.tRfi = (tAmount*taxes.rfi)/1000;
            s.tTreasury = (tAmount*taxes.treasury)/1000;
            s.tDevelopment = tAmount*taxes.development/1000;
            s.tBurn = tAmount*taxes.burn/1000;
            s.tTransferAmount = tAmount-s.tRfi-s.tTreasury-s.tDevelopment-s.tBurn;
            return s;
        } else {
            s.tRfi = tAmount*taxes.rfi/1000;
            s.tDevelopment = tAmount*taxes.development/1000;
            s.tBurn = tAmount*taxes.burn/1000;
            s.tTransferAmount = tAmount-s.tRfi-s.tDevelopment-s.tBurn;
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
            rTransferAmount =  rAmount-rRfi-rDevelopment-rBurn;
            return (rAmount, rTransferAmount, rRfi,0,rDevelopment,rBurn);
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

        if (isPresale){
            require(whitelisted[to], "SOLIDBLOCK: You need to be whitelisted");
            require(whitelisted[from], "SOLIDBLOCK: You need to be whitelisted");
            require((balanceOf(to) + amount) <= presaleMaxWalletAmount, "Expected wallet amount exceeds the PresaleMaxWalletAmount.");
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
            emit Transfer(sender, treasuryAddress, s.tDevelopment);
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

    function updateStableCoin(address _usdt) external addressValidation(_usdt) {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a editor");
        require(USDT != _usdt, 'SOLIDBLOCK: Wallet already set');
        USDT = _usdt;
    }

    function updateMaxTxAmt(uint256 amount) external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a editor");
        require(amount >= 100);
        maxTxAmount = amount * 10**_decimals;
    }

    function updateMaxWalletAmt(uint256 amount) external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a editor");
        require(amount >= 100);
        maxWalletAmount = amount * 10**_decimals;
    }

    function updatePresaleMaxWalletAmt(uint256 amount) external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a editor");
        require(amount >= 100);
        presaleMaxWalletAmount = amount * 10**_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external {
        require(hasRole(EDITOR_ROLE, msg.sender), "Caller is not a editor");
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