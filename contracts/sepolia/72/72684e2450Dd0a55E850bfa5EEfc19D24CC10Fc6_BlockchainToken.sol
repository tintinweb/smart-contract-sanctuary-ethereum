// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ierc20.sol";

contract BlockchainToken is IERC20 {
    string public name;
    string public symbol;
    uint public totalTokenSupply;
    address owner;
    bytes32 password;

    mapping(address userAddress => uint tokenBalance) userBalances;
    mapping(address => mapping(address => uint)) allowances_map;

    event NewTokensMinted(uint);
    event TokensBurned(address indexed from, uint256 value);
    event Log(string func, address sender, uint value, bytes data);
    event PasswordGuessed(address indexed user, uint256 amount);
    event Approval(address indexed owner,address indexed spender,uint256 amount);

    modifier OnlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function setOwner(address _newOwner) external OnlyOwner {
        require(_newOwner != address(0), "Zero address");
        owner = _newOwner;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint _totalSupply,
        bytes32 _pass
    ) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        mint(_totalSupply);
        password = _pass;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return totalTokenSupply;
    }

    function mint(uint _noOfTokens) public OnlyOwner {
        totalTokenSupply += _noOfTokens;
        userBalances[owner] += _noOfTokens;
        emit NewTokensMinted(_noOfTokens);
        emit Transfer(address(0), msg.sender, _noOfTokens);
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return userBalances[account];
    }

    // transferfrom x -> my
    // transfer my -> x

    function transfer(
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        require(to != address(0), "Zero address");
        // check if sender address is not zero
        require(msg.sender != address(0), "Zero address");

        require(userBalances[msg.sender] >= amount, "Low Balance");
        userBalances[msg.sender] -= amount;
        userBalances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // transferred to zero address
    // wrong logic sir said
    function burnToken(address acc, uint amount) external virtual override returns (bool) {
        require(acc != address(0), "Burning from zero addr");
        require(userBalances[msg.sender] >= amount, "Low Balance");
        userBalances[msg.sender] -= amount;
        totalTokenSupply -= amount;
        emit TokensBurned(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function selfdestructContract() external OnlyOwner {
        selfdestruct(payable(owner));
    }

    // executed when msg.data is not empty
    fallback() external payable {
        emit Log("fallback called", msg.sender, msg.value, msg.data);
    }

    // executed when msg.data is empty
    receive() external payable {
        emit Log("fallback called", msg.sender, msg.value, "");
    }

    function getToken(bytes32 _guessPass) public {
        require(_guessPass == password, "Incorrect Password");
        uint256 rewardAmt = 5;
        // token to contract addr
        userBalances[msg.sender] += rewardAmt;
        emit Transfer(address(0), msg.sender, rewardAmt);

        // contract addr to reward user
        emit PasswordGuessed(msg.sender, rewardAmt);
    }

    function allowances(
        address own,
        address spender
    ) external       view
returns (uint) {
        return allowances_map[own][spender];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(to != address(0), "Zero address not allowed");
        require(userBalances[from] >= amount, "Low Balance");
        require(
            allowances_map[from][msg.sender] >= amount,
            "Insufficient allowance"
        );
        userBalances[from] -= amount;
        userBalances[to] += amount;
        allowances_map[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedAmount
    ) external returns (bool) {
        allowances_map[msg.sender][spender] += addedAmount;
        emit Approval(msg.sender, spender, allowances_map[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedAmount
    ) external returns (bool) {
        uint256 currentAllowance = allowances_map[msg.sender][spender];
        require(currentAllowance >= subtractedAmount, "Allowance insufficient");
        allowances_map[msg.sender][spender] =
            currentAllowance -
            subtractedAmount;
        emit Approval(msg.sender, spender, allowances_map[msg.sender][spender]);
        return true;
    }
}
// ownable ?