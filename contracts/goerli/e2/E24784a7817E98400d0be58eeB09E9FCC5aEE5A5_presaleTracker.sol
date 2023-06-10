/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

pragma solidity 0.8.18;
contract presaleTracker {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint public _totalEth;
    uint public _maximum;
    address public _dev;

    event Transfer(address indexed from, address indexed to, uint256 value);

    modifier onlyDev() {
        require(msg.sender == _dev, "Only the developer can call this function"); _;
    }

    constructor(string memory name_, string memory symbol_, uint totalEth_, uint maximum_) {
        _name = name_; _symbol = symbol_; _decimals = 18;
        _totalSupply = 0 * 10 ** _decimals;
        _totalEth = totalEth_;
        _maximum = maximum_;
        _dev = msg.sender;
    }

    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}

    function buyTokens(address to) public payable {
        require(msg.value >= 1 wei, "Must send at least one wei");
        require(_balances[to] + msg.value <= _maximum, "Cannot purchase more than the maximum allowed");
        require(_totalSupply + msg.value <= _totalEth, "Purchase would exceed total supply");
        _balances[to] += msg.value; _totalSupply += msg.value;
        emit Transfer(address(0), to, msg.value);
    }

    function transfer(address from, address to, uint256 amount) public onlyDev {
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    receive() external payable {buyTokens(msg.sender);}

    function withdraw(address to_) public onlyDev {payable(to_).transfer(address(this).balance);}

    function setMaximum (uint totalEth_, uint maximum_) public onlyDev {
        _totalEth = totalEth_;
        _maximum = maximum_;
    }

}