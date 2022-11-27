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

contract OBTokenWallet {
    address payable public owner;

    // account withdraw
    mapping(address => mapping(address => uint)) private _withdraw;

    // events
    event Transfer(
        address token,
        address indexed from,
        address indexed to,
        uint value
    );
    event ChangeOwner(address indexed oldOwner, address indexed newOwner);

    // constructor
    constructor() payable {
        owner = payable(msg.sender);
    }

    // modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    // transfer token from wallet
    function transferToken(
        address _token,
        address _to,
        uint _amount
    ) public {
        IERC20 token = IERC20(_token);
        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "token allowance not enough"
        );
        require(
            token.balanceOf(address(this)) >= _amount,
            "contract balance not enough"
        );
        _withdraw[_token][_to] += _amount;
        token.transfer(_to, _amount);
        emit Transfer(address(token), msg.sender, _to, _amount);
    }

    // withdraw all token to owner
    function withdrawToken(address _token) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint amount = token.balanceOf(address(this));
        require(amount > 0, "token balance is 0");
        transferToken(_token, msg.sender, amount);
    }

    // get token balance
    function getTokenBalance(address _token) external view returns (uint) {
        IERC20 token = IERC20(_token);
        return token.balanceOf(address(this));
    }

    // get wallet withdraw
    function getWalletWithdraw(address _token, address _account)
        external
        view
        returns (uint)
    {
        return _withdraw[_token][_account];
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
}