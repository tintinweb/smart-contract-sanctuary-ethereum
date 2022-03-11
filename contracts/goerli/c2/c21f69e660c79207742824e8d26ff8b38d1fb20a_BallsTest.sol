/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract BallsTest is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;
    uint256 public _feePercentage;
    uint256 public _finalPercentage;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) contractManagers;

    address public managementWallet;
    address public owner;
    address public stakingcontract;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "TestCoin";
        symbol = "TC";
        decimals = 18;
        _totalSupply = 1000000000000000000000000;
        _feePercentage = 5;
        _finalPercentage = 100 - _feePercentage;
        managementWallet = 0x5dA9814CAaB718930a1406e22973dDc99B649783;
        owner = 0x5dA9814CAaB718930a1406e22973dDc99B649783;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyOwner() {
    require(msg.sender == owner, "Ownable: caller is not the owner");
    _;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {

        uint amount = safeMul(tokens, 1000000000000000000);

        uint finalAmount = safeMul(amount, _finalPercentage) / 100;
        uint feeAmount = safeMul(amount, _feePercentage) / 100;

        balances[msg.sender] = safeSub(balances[msg.sender], amount);

        balances[to] = safeAdd(balances[to], finalAmount);
        balances[managementWallet] = safeAdd(balances[managementWallet], feeAmount);

        emit Transfer(msg.sender, to, finalAmount);
        emit Transfer(msg.sender, managementWallet, feeAmount);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        uint amount = safeMul(tokens, 1000000000000000000);

        uint finalAmount = safeMul(amount, _finalPercentage) / 100;
        uint feeAmount = safeMul(amount, _feePercentage) / 100;

        balances[from] = safeSub(balances[from], amount);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], amount);

        balances[to] = safeAdd(balances[to], finalAmount);
        balances[managementWallet] = safeAdd(balances[managementWallet], feeAmount);

        emit Transfer(from, to, finalAmount);
        emit Transfer(from, managementWallet, feeAmount);
        return true;
    }

    function setStakingContract(address newContractAddress) public {
        require(msg.sender == owner);
        stakingcontract = newContractAddress;
    }

    function changeManagementAddress(address to) public returns (bool success){
        
        require(contractManagers[msg.sender] == true, "Sender is not authorised to perform this action");
        managementWallet = to;
        return true;
    }

    function addManager(address newManager) public onlyOwner{
        contractManagers[newManager] = true;
    }
}