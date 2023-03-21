/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.7;

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

contract Test is Ownable {
    IERC20 public token;

    constructor() {}

    function transferToContract(
        address contractAddress,
        address account,
        uint256 amount
    ) external onlyOwner {
        IERC20 token = IERC20(contractAddress);
        token.transferFrom(account, address(this), amount);
    }

    function transferFromContract(
        address contractAddress,
        address toAccount,
        uint256 amount
    ) external onlyOwner {
        IERC20 token = IERC20(contractAddress);
        token.transfer(toAccount, amount);
    }


}