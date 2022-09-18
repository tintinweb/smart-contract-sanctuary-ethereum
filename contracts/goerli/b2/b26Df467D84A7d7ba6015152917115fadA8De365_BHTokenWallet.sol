/**
 *Submitted for verification at Etherscan.io on 2022-09-18
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

    // account withdraw
    mapping(address => uint) private _withdraw;

    // events
    event Transfer(
        address token,
        address indexed from,
        address indexed to,
        uint value
    );
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

    // transfer token from wallet
    function transferToken(address _to, uint _amount) public onlyOwner {
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "token allowance not enough"
        );
        require(
            token.balanceOf(address(this)) >= _amount,
            "contract balance not enough"
        );
        _withdraw[_to] += _amount;
        token.transfer(_to, _amount);
        emit Transfer(address(token), msg.sender, _to, _amount);
    }

    // withdraw all token to owner
    function withdrawToken() external onlyOwner {
        uint amount = token.balanceOf(address(this));
        require(amount > 0, "token balance is 0");
        transferToken(msg.sender, amount);
    }

    // get token balance
    function getTokenBalance() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    // get wallet withdraw
    function getWalletWithdraw(address _account) external view returns (uint) {
        return _withdraw[_account];
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
}