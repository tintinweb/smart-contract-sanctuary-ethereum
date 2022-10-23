//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;


contract StolToken {

    // State Variables
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    uint public totalSupply;
    uint public immutable supplyCap;
    string public name;
    string public symbol;
    address payable public immutable owner;
    uint8 public immutable decimals;
    bool public isPaused;
    bool locked;
    

    // Events
    event Transfer(address indexed _from, address indexed _to, uint _amount);
    event Approval(address indexed _owner, address indexed _spender, uint _amount);
    event Paused(address _owner);
    event Unpaused(address _owner);

    // Constructor
    constructor (
        uint _initialSupply,
        uint _supplyCap,
        string memory _name,
        string memory _symbol,
        uint8 _decimals) payable
         {
            require(_supplyCap >= _initialSupply, "Cap is less than initial supply");
            totalSupply = _initialSupply * (10 **_decimals);
            supplyCap = _supplyCap * (10 ** _decimals);
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            isPaused = false;
            locked = false;
            owner = payable(address(msg.sender));
            balances[msg.sender] = _initialSupply * (10 ** _decimals);
    }


    // Function Modifiers

    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    modifier unPaused {
        require(!isPaused, "Token transfers are paused");
        _;
    }

    modifier paused {
        require(isPaused, "Token transfers are not paused");
        _;
    }

    modifier noReEntrancy {
        require(!locked, "No reEntrancy");
        locked = true;
        _;
        locked = false;
    }


    // Functions

    function pauseTransfers() external onlyOwner unPaused returns (bool) {
        isPaused = true;
        emit Paused(address(msg.sender));
        return true;
    }

    function unPauseTransfers() external onlyOwner paused returns (bool) {
        isPaused = false;
        emit Unpaused(address(msg.sender));
        return true;
    }

    function balanceOf(address _account) public view returns (uint) {
        return balances[_account];
    }

    function transfer(address _to, uint _amount) external noReEntrancy unPaused returns (bool) {
        require(balances[msg.sender] >= _amount, "Not enough tokens");
        require(_to != address(0), "Zero address is invalid");
        balances[msg.sender] -=  _amount ;
        balances[_to] += _amount;
        emit Transfer(address(msg.sender), _to, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint _amount) external noReEntrancy returns (bool) {
        require(balances[msg.sender] >= _amount, "Not enough tokens");
        require(_spender != address(0), "Cannot approve Zero address");
        require(_spender != address(msg.sender), "Self delegation is disallowed");
        allowances[msg.sender][_spender] += _amount;
        emit Approval(address(msg.sender), _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) external noReEntrancy unPaused returns (bool) {
        require(_to != address(0) && _from != address(0), "Invalid zero address");
        require(balances[_from] >= _amount, "Insufficient token balance");
        require(allowances[_from][msg.sender] >= _amount, "Not enough allowance");
        allowances[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }


    function mint(uint _amount) external onlyOwner unPaused returns (bool) {
        require(totalSupply + _amount <= supplyCap, "Exceeds supply cap");
        totalSupply += _amount;
        balances[msg.sender] += _amount;
        emit Transfer(address(0), address(msg.sender), _amount);
        return true;
    }

   
    function burn(uint _amount) external noReEntrancy unPaused returns (bool) {
        require(balances[msg.sender] >= _amount, "Token amount exceeds balance");
        balances[msg.sender] -= _amount;
        totalSupply -= _amount;
        emit Transfer(address(msg.sender), address(0), _amount);
        return true;
    }

    function destroy() external onlyOwner {
        selfdestruct(owner);
    }

}