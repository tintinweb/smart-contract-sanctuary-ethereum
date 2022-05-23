/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

interface IERC20PoolPair is IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function pairInfo(address owner) external view returns (uint32, uint, uint32, uint32);
    function mint(address owner, uint256 amount) external;
    function burn(address owner, uint amount) external;
    function updateTokenTime(address owner) external;
    function setInterestRate(uint32 _interestRate) external;
}

contract ERC20PoolPair is IERC20PoolPair, ERC20 {
    address public factory;
    address public token;

    uint32  private blockStartTime; // uses single storage slot, accessible via getReserves

    uint32 private interestRate = 30;
    uint16 constant private INTEREST_RATE_MOL = 1000;

     // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    uint8 private _decimals = 18;

    mapping(address => uint32) private _lpTokensTimes;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'ERC20PoolPair: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    constructor() {
        factory = msg.sender;
        blockStartTime = uint32(block.timestamp % 2 ** 32);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // called once by the factory at time of deployment
    function initialize(string memory name_, string memory symbol_, uint8 decimals_, address token_, uint32 _interestRate) external lock {
        require(msg.sender == factory, 'DDF: FORBIDDEN'); // sufficient check
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_; 
        token = token_;
        interestRate = _interestRate;
    }

    function pairInfo(address owner) external view override returns (uint32, uint, uint32, uint32){
        return (_lpTokensTimes[owner], balanceOf(owner), interestRate, INTEREST_RATE_MOL);
    }

    function mint(address owner, uint256 amount) external lock override {
        IERC20(token).transferFrom(_msgSender(), address(this), amount);
        
        _mint(owner, amount);
        _lpTokensTimes[owner] = uint32(block.timestamp % 2 ** 32);
    }

    function burn(address owner, uint amount) external lock override {
        uint allAmount = balanceOf(owner);
        require(amount <= allAmount, "ERC20PoolPair:burn amount not enough");

        uint256 currentAllowance = allowance(owner, _msgSender());
        require(currentAllowance >= amount, "ERC20PoolPair: transfer amount exceeds allowance");

        IERC20(token).transfer(owner, amount);

        _approve(owner, _msgSender(), currentAllowance - amount);
        _burn(owner, amount);
        if(amount == allAmount){
             delete _lpTokensTimes[owner];
        }else{
           _lpTokensTimes[owner] = uint32(block.timestamp % 2 ** 32);
        }
    }

    function updateTokenTime(address owner) external lock override {
        uint amount = balanceOf(owner);
        require(amount > 0, "burn amount not enough");

        uint256 currentAllowance = allowance(owner, _msgSender());
        require(currentAllowance >= amount, "ERC20PoolPair: transfer amount exceeds allowance");

        _lpTokensTimes[owner] = uint32(block.timestamp % 2 ** 32);
    }

    function setInterestRate(uint32 _interestRate) external lock override{
        require(msg.sender == factory, 'DDF: FORBIDDEN'); // sufficient check
        interestRate = _interestRate;
    }
}

interface IDDFERC20Factory {
    function getPair(address token) external view returns (address pair);
    function allTokensLength() external view returns (uint);
    function findAllTokens() external view returns (address[] memory);
    function createPair(string memory name_, string memory symbol_, uint8 decimals_, address token, uint32 interestRate) external returns (address pair);
    function setInterestRate(address token, uint32 _interestRate) external;
}

contract DDFERC20Factory is IDDFERC20Factory {
    mapping(address => address) private pairs;
    address[] private allTokens;
    address private _owner;

    event PairCreated(address indexed token, address pair, uint);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "DDFERC20Factory: caller is not the owner");
        _;
    }

    function getPair(address token) external view override returns (address pair){
         pair = pairs[token];
    }

    function allTokensLength() public view override returns (uint) {
        return allTokens.length;
    }

    function findAllTokens() external view override returns (address[] memory){
        return allTokens;
    }

    function createPair(string memory name_, string memory symbol_, uint8 decimals_, address token, uint32 interestRate) external onlyOwner override returns (address pair) {
        require(token != address(0), 'DDF: ZERO_ADDRESS');
        require(pairs[token] == address(0), 'DDF: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(ERC20PoolPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ERC20PoolPair(pair).initialize(name_, symbol_, decimals_, token, interestRate);
        pairs[token] = pair;
        allTokens.push(token);
        emit PairCreated(token, pair, allTokens.length);
    }

    function setInterestRate(address token, uint32 _interestRate) external onlyOwner override{
        address pair = pairs[token]; 
        require(pair != address(0), "ERC721: The DDFFactory query for nonexistent pair");

        ERC20PoolPair(pair).setInterestRate(_interestRate);
    }
}