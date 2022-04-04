// SPDX-License-Identifier: MIT,
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

contract SmartContract is ERC20Interface {
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 _totalSupply;
    address payable owner;
    bool public activeStatus = true;

    event Active(address msgSender);
    event Reset(address msgSender);
    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    mapping(address => uint256) public balances;
    mapping(address => uint256) public freezeOf;
    mapping(address => mapping(address => uint256)) public allowed;

    address public authorizedAddress = 0xe6B8312aC2731d1F606f4d6686aA60Fa0EAffEaf;
    address payable comissionAddress = 0xB65EdBC62E0a82ad44D6BaDFc7972cd672b846AF;
    address payable arrivalAddress0 = 0xBa18146EE072e5d84F6452FBe0b7Ff658dFc2bB0;
    address payable arrivalAddress1 = 0x60dAcCCB2d36bb0Aa631Db22973871a9fb7789a4;
    
    
    

    bool private shootingDone = false;
    bool public testamentValidity = true;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        name = "SmartContract";
        symbol = "SMC";
        decimals = 18;
        _totalSupply = 2 * 10**uint256(decimals);
        owner = msg.sender;

        balances[msg.sender] = balanceOf(msg.sender) + 1 * 10**uint256(decimals);
        emit Transfer(address(0), msg.sender, 1 * 10**uint256(decimals));
    }

    function addBalance() public payable onlyOwner {}

    function makeTheWill() public {
      require(address(this).balance > 0, "Insufficient balance!");
      require(msg.sender == authorizedAddress, "Unauthorized access prohibited!");
      uint256 balance = address(this).balance;
      uint256 remainder = balance-(balance * 10) / 100;
      comissionAddress.transfer((balance * 10) / 100);
      arrivalAddress0.transfer((remainder * 50) / 100);
      arrivalAddress1.transfer((remainder * 50) / 100);
      
      
      
    }

    function withdraw() public onlyOwner {
      require(address(this).balance > 0, "Insufficient balance!");
      require(!shootingDone, "For the 2nd time shoot, cancel the will!");
      shootingDone = true;
      owner.transfer((address(this).balance * 50) / 100);
    }

    function disclaimer() public onlyOwner {
      comissionAddress.transfer((address(this).balance * 10) / 100);
      owner.transfer(address(this).balance);
      testamentValidity = false;
      emit OwnershipTransferred(owner, 0x0000000000000000000000000000000000000000);
      owner = 0x0000000000000000000000000000000000000000;
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