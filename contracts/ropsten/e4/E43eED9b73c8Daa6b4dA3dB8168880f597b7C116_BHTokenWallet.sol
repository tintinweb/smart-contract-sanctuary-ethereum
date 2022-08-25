/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BHTokenWallet {
    address payable public owner;
    IERC20 token;

    // account balance
    mapping(address => uint) public balances;

    // events
    event Deposit(address token, address indexed from, uint value);
    event Withdraw(address token, address indexed to, uint value);
    event Transfer(
        address token,
        address indexed from,
        address indexed to,
        uint value
    );
    event ChangeBalance(string action, address indexed to, uint value);
    event ChangeOwner(address indexed oldOwner, address indexed newOwner);

    // constructor
    constructor(address _token) payable {
        owner = payable(msg.sender);
        token = IERC20(_token);
    }

    // modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    // deposit token to the wallet
    function depositToken() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(address(token), msg.sender, msg.value);
    }

    // withdraw all token to owner
    function withdrawToken() public onlyOwner {
        uint amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
        emit Withdraw(address(token), msg.sender, amount);
    }

    // transfer token from wallet
    function transferToken(address _to, uint _amount) external onlyOwner {
        require(balances[_to] >= _amount, "account not enough balance");
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "token allowance not enough"
        );
        require(
            token.balanceOf(address(this)) >= _amount,
            "contract not enough balance"
        );
        balances[_to] -= _amount;
        token.transfer(_to, _amount);
        emit Transfer(address(token), msg.sender, _to, _amount);
    }

    // add account balance
    function addBalance(address _account, uint _amount) public onlyOwner {
        balances[_account] += _amount;
        emit ChangeBalance("Add", msg.sender, _amount);
    }

    // remove account balance
    function removeBalance(address _account, uint _amount) public onlyOwner {
        balances[_account] -= _amount;
        emit ChangeBalance("Remove", _account, _amount);
    }

    // get token balance
    function getTokenBalance() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    // get wallet balance
    function getWalletBalance(address _account) external view returns (uint) {
        return balances[_account];
    }

    // get owner
    function getOwner() public view returns (address) {
        return owner;
    }

    // change owner
    function changeOwner(address _owner) public onlyOwner {
        owner = payable(_owner);
        emit ChangeOwner(msg.sender, _owner);
    }

    // get token
    function getToken() public view returns (address) {
        return address(token);
    }

    fallback() external payable {
        depositToken();
    }

    receive() external payable {
        depositToken();
    }
}