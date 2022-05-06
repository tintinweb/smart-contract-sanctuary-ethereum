/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract HydroToken is IERC20 {
    using SafeMath for uint256;

    string public constant name = "HydroToken";
    string public constant symbol = "HT";
    uint8 public constant decimals = 18;

    address private _owner;

    event Blacklisted(address indexed _account);
    event UnBlacklisted(address indexed _account);
    event BlacklisterChanged(address indexed newBlacklister);

    address public blacklister;
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) internal blacklisted;

    uint256 totalSupply_;

    constructor(uint256 total) {
        setOwner(msg.sender);
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) internal {
        _owner = newOwner;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    modifier onlyBlacklister() {
        require(msg.sender == blacklister);
        _;
    }

    modifier notBlacklisted(address _account) {
        require(blacklisted[_account] == false);
        _;
    }

    function isBlacklisted(address _account) public view returns (bool) {
        return blacklisted[_account];
    }

    function blacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = true;
        emit Blacklisted(_account);
    }

    function unBlacklist(address _account) public onlyBlacklister {
        blacklisted[_account] = false;
        emit UnBlacklisted(_account);
    }

    function updateBlacklister(address _newBlacklister) public onlyOwner {
        require(_newBlacklister != address(0));
        blacklister = _newBlacklister;
        emit BlacklisterChanged(blacklister);
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) notBlacklisted(msg.sender) notBlacklisted(receiver)  public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        burn(msg.sender, 1);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) notBlacklisted(msg.sender) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) notBlacklisted(owner) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        require(owner != address(0), "ERC20: owner zero address");
        require(buyer != address(0), "ERC20: buyer address");

        burn(owner, 1);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    function burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        balances[account] = balances[account].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) notBlacklisted(account) external {
        require(account != address(0), "ERC20: mint to the zero address");
        require(amount > 0);

        _beforeTokenTransfer(address(0), account, amount);
        burn(account, 1);
        totalSupply_ = totalSupply_.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}