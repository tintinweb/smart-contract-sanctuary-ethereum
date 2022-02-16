/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity 0.8.6;

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Protected {

    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
        _;
    }

    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {}
    fallback() external payable {}
}


contract ChiaraCoin is ERC20, Protected {

    string public constant _name = 'ChiaraCoin';
    string public constant _symbol = 'CCOIN';
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply= 100 * 10**6 * 10**_decimals;
    uint256 public  _circulatingSupply= InitialSupply;
    address public constant UniswapRouter=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; /// ROUTER DELLA RETE
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;

    uint marketingTax = 1;

    uint burnTax = 5;

    uint max_tx = 1;

    function modify_burn_tax(uint newtax) public onlyOwner {
        burnTax = newtax;
    }

    function modify_marketing_tax(uint newtax) public onlyOwner {
        marketingTax = newtax;
    }

    function _transfer(address sender, address recipient, uint amount) public safe {
      require(_balances[sender]>=amount, "We non hai i soldi");
      require(amount <= ((_circulatingSupply*max_tx)/100));
      uint taxed = (amount*marketingTax)/100;
      uint burned = (amount*burnTax)/100;
      uint final_amount = amount - taxed - burned;
      _circulatingSupply -= burned;
      _balances[recipient] += final_amount;
      _balances[sender] -= amount;
      _balances[address(this)] += taxed;
      emit Transfer(sender, Dead, burned);
      emit Transfer(sender, address(this), taxed);
      emit Transfer(sender, recipient, final_amount);
      
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() view public override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }    

}