/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event FirstTimeToUse(address indexed account);
    event Win(address indexed account, uint256 your_number, uint256 random, uint256 reward);
    event Lose(address indexed account, uint256 your_number, uint256 random);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function firstTimeToUse() external returns (bool);
    function approval(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function choose_number_from_1_to_6_and_enter_your_bet(uint256 number, uint256 bet) external returns (string memory, uint256);
}

contract ERC20 is IERC20 {
    uint256 _totalSupply;
    mapping(address => uint256) _balance;
    mapping(address => mapping(address => uint256)) _allowance;
    mapping(address => bool) _firstTime;
    string _name;
    string _symbol;
    address _owner;
    uint256 _random;
    uint256 _bet;


    modifier onlyOwner() {
        require(msg.sender == _owner, "ERROR : Only Owner can access this function");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;

        _totalSupply = 1000000000000;
        _balance[msg.sender] = 1000000000000;
    }

    //鑄造
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0x0), "ERROR : mint to address 0");
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    //燒毀
    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0x0), "ERROR : burn from address 0");
        
        uint256 accountBalance = _balance[account];
        require(accountBalance >= amount, "ERROR : no more token to brun");

        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function deciamls() public pure returns (uint8) {
        return 18;
    }
    
    //內部使用的授權
    function _approval(address owner, address spender, uint256 amount) internal {
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //內部使用的轉帳
    function _transfer(address from, address to, uint256 amount) internal {
        uint256 myBalance =  _balance[from];

        //檢查餘額
        require (myBalance >= amount, "No money to transfer");
        require (to != address(0x0), "Transfer to address 0");

        //轉帳
        _balance[from] -= amount;
        _balance[to] += amount;

        emit Transfer(from, to, amount);
    }

    //每個使用者可以領一次錢
    function firstTimeToUse() public returns (bool){
        require (_firstTime[msg.sender] == false, "You have used this once");
        _firstTime[msg.sender] = true;
        _totalSupply += 10000;
        _balance[msg.sender] += 10000;
        emit FirstTimeToUse(msg.sender);
        return true;
    }

    //查詢總發行量
    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    //查詢用戶餘額
    function balanceOf(address account) public view returns (uint256) {
        return _balance[account];
    }

    //查詢授權餘額
    function allowance(address owner, address spender) public view returns (uint256){
        return _allowance[owner][spender];
    }

    //授權
    function approval(address spender, uint256 amount) public returns (bool){
        _approval(msg.sender, spender, amount);
        return true;
    }

    //轉帳
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    //從別人的帳戶轉帳
    function transferFrom(address from, address to, uint256 amount) public returns (bool){

        //檢查授權的額度
        uint256 myAllowance = _allowance[from][msg.sender];
        require(myAllowance >= amount, "Error : No allowance to transfer");

        _approval(from, msg.sender, myAllowance - amount);
        _transfer(from, to, amount);

        return true;
    }

    //開玩
    function choose_number_from_1_to_6_and_enter_your_bet(uint256 number, uint256 bet) public returns (string memory, uint256){
        require(_balance[msg.sender] >= bet, "No money to gamble");
        require(number <=6, "Please choose from 1 to 6");
        require(number >=1, "Please choose from 1 to 6");
        _transfer(msg.sender, _owner, bet);
        _bet = bet;
        _random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        _random %= 6;
        _random ++;
        if(number == _random){
            get_reward(msg.sender);
            emit Win(msg.sender, number, _random, bet * 6);
            return ("You win. The number is ", _random);
        }
        else{
            emit Lose(msg.sender, number, _random);
            return ("You lose. The number is ", _random);
        }
    }

    function get_reward(address account) internal returns (bool) {
        _transfer(_owner, account, _bet * 6);
        return true;
    } 
}