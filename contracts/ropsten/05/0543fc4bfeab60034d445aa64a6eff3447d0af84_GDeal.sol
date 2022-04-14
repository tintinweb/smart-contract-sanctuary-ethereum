/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (uint256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (uint256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(uint256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

abstract contract ERC20Detailed  is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory __name, string memory __symbol, uint8 __decimals) {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) override public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) override public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) override  public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) override public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

contract GDeal is ERC20, ERC20Detailed {
    address deployer;
    address payable owner;
    AggregatorInterface internal priceFeed;

    uint[] public claim_periods;
    
    uint initial_limit = 1500;
    uint ref_bonus = 5;
    uint limit_increase_by = 100;
    uint max_direct_ref_income = 5;
    uint min_condition = 1000;
    uint devider = 100;
    uint256 coin_rate = 15;

    modifier onlyDeployer() {
        require (msg.sender == deployer);
        _;
    }

    struct User {
        address upline;
        uint referrals;
        uint counted_directs;
        uint256 direct_bonus;
        uint    deposit_time;
        uint256 total_deposit;
        uint256 limit;
        uint no_of_deposits;
        Investments [] investment;
    }
    struct Investments {
        uint256 deposit_amount;
        uint256 left_amount;
        uint time;
        uint claim_period;
        uint256 usd_value;
        uint256 price;

    }

    mapping(address => User) public users;

    constructor (address payable _owner)  ERC20Detailed("Great Deal Coin", "GDS", 8) {
        deployer = msg.sender;
        owner = _owner;

        priceFeed = AggregatorInterface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        _mint(msg.sender, 250000000 * (10 ** uint256(decimals())));

        claim_periods.push(5 minutes);
        claim_periods.push(10 minutes);
        claim_periods.push(15 minutes);
        claim_periods.push(20 minutes);
    }

    function _setUpline(address _addr, address _upline) private {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner)) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;
        }
    }

    function participate(address _upline) external payable{
        _setUpline(msg.sender, _upline);
        _participate(msg.sender);
    }

    function _participate(address _addr) private {
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");

        (uint256 latest_price, uint256 usd_amount, uint256 tokens) = this.calculateCoins(msg.value);

        if(users[_addr].deposit_time == 0){
            users[_addr].deposit_time = block.timestamp;
            users[_addr].limit = initial_limit;
        }

        require(usd_amount + users[_addr].total_deposit < users[_addr].limit, "can not buy more than limit");

        users[_addr].no_of_deposits++;
        users[_addr].total_deposit += usd_amount;

        Investments memory inv = Investments({
            deposit_amount: tokens,
            time: block.timestamp,
            claim_period : 0,
            usd_value:usd_amount,
            price : latest_price,
            left_amount : tokens
        });

        users[_addr].investment.push(inv);

        if(users[_addr].upline != address(0)){
            if(users[users[_addr].upline].counted_directs < max_direct_ref_income && usd_amount >= min_condition){
                users[users[_addr].upline].direct_bonus += ref_bonus;

                Investments memory invr = Investments({
                    deposit_amount: ref_bonus,
                    time: block.timestamp,
                    claim_period : 0,
                    usd_value:0,
                    price : 0,
                    left_amount : ref_bonus
                });

                users[users[_addr].upline].investment.push(invr);
                users[users[_addr].upline].counted_directs++;
                users[users[_addr].upline].limit += limit_increase_by;
            }
        }

        owner.transfer(msg.value);
    }

    function claim(uint _level) external {
        require(users[msg.sender].investment[_level].left_amount > 0 , "no amount left");
        require(users[msg.sender].investment[_level].time + claim_periods[users[msg.sender].investment[_level].claim_period] < block.timestamp, "claim time not came");
        require(users[msg.sender].investment[_level].claim_period < 4, "no claim left");
        
        uint256 claim_amount = users[msg.sender].investment[_level].deposit_amount / 4;

        if(claim_amount > users[msg.sender].investment[_level].left_amount){
            claim_amount = users[msg.sender].investment[_level].left_amount;
        }

        users[msg.sender].investment[_level].left_amount -= claim_amount;
        users[msg.sender].investment[_level].claim_period++;

        require(balanceOf(address(this)) >= claim_amount , "no balance in system");
        _transfer(address(this), msg.sender, claim_amount * 1e8);
    }

    function getInvestments(address _addr, uint _level) public view returns(uint256 deposit_amount, uint time, uint claim_period, uint256 usd_value, uint256 price, uint256 left_amount) { 
        return (users[_addr].investment[_level].deposit_amount, users[_addr].investment[_level].time, users[_addr].investment[_level].claim_period, users[_addr].investment[_level].usd_value, users[_addr].investment[_level].price, users[_addr].investment[_level].left_amount);
    }

    function calculateCoins(uint256 _value) public view returns(uint256 latestPrice, uint256 usd_amount, uint256 tokens) { 
        latestPrice = priceFeed.latestAnswer() / 1e8;
        usd_amount = (latestPrice * _value) / 1e18;
        tokens = (usd_amount * devider) / coin_rate;
    }

    function mint(uint256 _amount) 
        external onlyDeployer {
        _mint(msg.sender, _amount);
    }
}