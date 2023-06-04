// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AweBucks {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    bool public isOwnershipRenounced;
    uint256 public dividendPercentage;

    mapping(address => uint256) public lastDividendWithdrawn;
    mapping(address => uint256) public lastDividendsWithdrawnTimeStamp;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event OwnershipRenounced(address indexed previousOwner);
    event DividendClaimed(address indexed account, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10**uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        isOwnershipRenounced = false;
        dividendPercentage = 1; // 1% dividend reward for everyone holding AweBucks for 24 hours
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        require(!isOwnershipRenounced, "Ownership already renounced");

        isOwnershipRenounced = true;
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value <= balanceOf[msg.sender], "Insufficient balance");

        distributeDividends(msg.sender);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Invalid spender address");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(to != address(0), "Invalid recipient address");
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");

        distributeDividends(from);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);

        allowance[from][msg.sender] -= value;

        return true;
    }

    function claimDividends() public {
        distributeDividends(msg.sender);
    }

    function distributeDividends(address account) internal {
        require(account != address(0), "Invalid account address");
        require(
            balanceOf[account] > 0,
            "Cannot distribute dividends to zero balance account"
        );
        if (dividendPercentage > 0) {
            uint256 accountBalance = balanceOf[account];
            uint256 newDividends = (accountBalance * dividendPercentage) / 100;

            if ((newDividends > lastDividendWithdrawn[account]) && (block.timestamp > lastDividendsWithdrawnTimeStamp[account] + 24 hours)) {
                uint256 dividendAmount = newDividends - lastDividendWithdrawn[account];
                balanceOf[account] += dividendAmount;
                lastDividendWithdrawn[account] = newDividends;
                lastDividendsWithdrawnTimeStamp[account] = block.timestamp;
                emit Transfer(address(this), account, dividendAmount);
            }
        }
    }
}