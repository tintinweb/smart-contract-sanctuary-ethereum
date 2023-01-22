/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

pragma solidity ^0.5.17;

contract Layer2 {
    address private owner;

    // Layer2 state
    mapping(address => uint256) private offChainBalances;
    mapping(address => bool) private authorizedNodes;

    // Events
    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        owner = msg.sender;
    }

    // Functions
    function deposit(address payable to, uint256 value) public {
        require(value > 0, "Cannot deposit 0 or less funds.");
        offChainBalances[to] += value;
        emit Deposit(to, value);
    }

    function withdraw(address payable from, uint256 value) public {
        require(value > 0, "Cannot withdraw 0 or less funds.");
        require(offChainBalances[from] >= value, "Insufficient funds.");
        offChainBalances[from] -= value;
        from.transfer(value);
        emit Withdraw(from, value);
    }

    function transfer(address payable from, address payable to, uint256 value) public {
        require(value > 0, "Cannot transfer 0 or less funds.");
        require(offChainBalances[from] >= value, "Insufficient funds.");
        offChainBalances[from] -= value;
        offChainBalances[to] += value;
        emit Transfer(from, to, value);
    }

    function authorizeNode(address node) public {
        require(msg.sender == owner, "Only the owner can authorize nodes.");
        authorizedNodes[node] = true;
    }

    function revokeNode(address node) public {
        require(msg.sender == owner, "Only the owner can revoke nodes.");
        authorizedNodes[node] = false;
    }

    function checkAuthorizedNode(address node) public view returns (bool) {
        return authorizedNodes[node];
    }

    function checkBalance(address account) public view returns (uint256) {
                return offChainBalances[account];
    }
}