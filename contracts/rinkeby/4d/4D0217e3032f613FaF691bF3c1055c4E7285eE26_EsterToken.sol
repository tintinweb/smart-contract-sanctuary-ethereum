// SPDX-License-Identifier:MIT
// EsterToken is an ERC20 token, mints to 2000 tokens at the start
// Deposit 1 ETH to get 1 ESTR

pragma solidity ^0.8.0;

import "./IEsterToken.sol";


contract EsterToken is IEsterToken  {
    

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address private _owner;

    constructor() {
        _name = "Ester Token";
        _symbol = "ESTR";
        _owner = msg.sender;
        uint256 _supply = 2000 ether;
        _mint(_supply);
        _totalSupply = _supply;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can call this function");
        _;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }
    

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address from, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            // unchecked because it saves gas, and we used require check to ensure it wont overflo
            unchecked {
                _approve(from, msg.sender, currentAllowance - amount);
            }
        }

        _transfer(from, recipient, amount);

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");


        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        // unchecked because it saves gas, and we used require check to ensure it wont overflow
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

    }

    function mint(uint256 supply) public onlyOwner {
        _mint(supply);
    }

    function _mint(uint256 supply) private {
        _balances[msg.sender] += supply;
        _totalSupply += supply;
        emit Transfer(address(0), msg.sender, supply);
    }

    // To change allowance for transfer of owner's tokens by specified spender
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    function depositEth() public payable override {
        _transfer(address(this), msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdrawEth(uint256 amount) public override {
        require(_balances[msg.sender] >= amount, "You do not have enough ESTR tokens!");
        _transfer(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }


}

// SPDX-License-Identifier:MIT
// interface for EsterToken

pragma solidity ^0.8.0;


interface IEsterToken {
    

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address recipient, uint256 amount) external returns (bool);

    function depositEth() external payable;
    function withdrawEth(uint256 amount) external;

    event Transfer(address indexed _from, address indexed _to, uint256 amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 amount);
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);


}