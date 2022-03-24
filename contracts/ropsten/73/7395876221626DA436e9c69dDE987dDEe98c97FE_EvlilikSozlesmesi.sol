/***
Fatih Belediyesi Evlendirme Memurluğuna

Taraflar: A A - asda
Taraf Cüzdanları: 0xf3ED573C2D326EFA84AB33f0c5b80A33a93d0f40 - 0xf3ED573C2D326EFA84AB33f0c5b80A33a93d0f40

Biz 01.01.1970 evlenme tarihinden itibaren “… Mal Ayrılığı Rejimine” tabi olmak istediğimizi bildirir, bu seçimlik mal rejimimizi kayda geçmesini saygıyla dileriz.

asdasd

***/
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 value) public returns (bool success);

    function approve(address spender, uint256 value)
        public
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 value
    );
}

contract EvlilikSozlesmesi is ERC20Interface {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;
    address public owner;
    bool public activeStatus = true;

    uint256 constant tokenPrice = 0.00027 ether;
    uint256 _saledTokens = 0 * 10**uint256(decimals);
    event Active(address msgSender);
    event Reset(address msgSender);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    mapping(address => uint256) public balances;
    mapping(address => uint256) public freezeOf;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) _allowList;
    address constant public party = 0xf3ED573C2D326EFA84AB33f0c5b80A33a93d0f40;

    constructor() public {
        name = "EvlilikSozlesmesi";
        symbol = "EVLS";
        decimals = 18;
        _totalSupply = 2 * 10**uint256(decimals);
        owner = msg.sender;

        balances[msg.sender] = balanceOf(msg.sender) + 1 * 10**uint256(decimals);
        _saledTokens = _saledTokens + 1;
        emit Transfer(address(0), msg.sender, 1 * 10**uint256(decimals));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        0xf3ED573C2D326EFA84AB33f0c5b80A33a93d0f40.transfer(balance);
    }

    function signTheContract() public payable {
        require(msg.sender == party, "You are not the other party!");
        require(_allowList[msg.sender] < 1, "You have already signed this contract!");

        uint256 aToken = 1 * 10**uint256(decimals);
        balances[msg.sender] = balanceOf(msg.sender) + aToken;
        _saledTokens = _saledTokens + 1 * 10**uint256(decimals);
        emit Transfer(address(0), msg.sender, aToken);
        _allowList[msg.sender] += 1 * 10**uint256(decimals);
    }

    function isOwner(address add) public view returns (bool) {
        if (add == owner) {
            return true;
        } else return false;
    }

    modifier onlyOwner() {
        if (!isOwner(msg.sender)) {
            revert();
        }
        _;
    }

    modifier onlyActive() {
        if (!activeStatus) {
            revert();
        }
        _;
    }

    function activeMode() public onlyOwner {
        activeStatus = true;
        emit Active(msg.sender);
    }

    function resetMode() public onlyOwner {
        activeStatus = false;
        emit Reset(msg.sender);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

        function approve(address spender, uint256 value)
        public
        onlyActive
        returns (bool success)
    {
        if (value <= 0) {
            revert();
        }
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

        function transfer(address to, uint256 value)
        public
        onlyActive
        returns (bool success)
    {
        if (to == address(0)) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        if (balances[msg.sender] < value) {
            revert();
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public onlyActive returns (bool success) {
        if (to == address(0)) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        if (balances[from] < value) {
            revert();
        }
        if (value > allowed[from][msg.sender]) {
            revert();
        }
        balances[from] = balances[from].sub(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function contractTermination(uint256 value) public onlyActive returns (bool success) {
        if (balances[msg.sender] < value) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Burn(msg.sender, value);
        return true;
    }

    function freeze(uint256 value) public onlyActive returns (bool success) {
        if (balances[msg.sender] < value) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        balances[msg.sender] = balances[msg.sender].sub(value);
        freezeOf[msg.sender] = freezeOf[msg.sender].add(value);
        emit Freeze(msg.sender, value);
        return true;
    }

    function unfreeze(uint256 value) public onlyActive returns (bool success) {
        if (freezeOf[msg.sender] < value) {
            revert();
        }
        if (value <= 0) {
            revert();
        }
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(value);
        balances[msg.sender] = balances[msg.sender].add(value);
        emit Unfreeze(msg.sender, value);
        return true;
    }
}