/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Sender {

    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    function transfer(
        address recipient,
        uint256 value
    ) external onlyOwner {
        payable(recipient).transfer(value);
    }

    function transferDifferentValue(
        address[] memory wallets,
        uint256[] memory values
    ) public onlyOwner {
        require(wallets.length == values.length);
        for (uint8 i = 0; i < wallets.length; i++) {
            payable(wallets[i]).transfer(values[i]);
        }
    }

    function transferSameValue(
        address[] memory wallets,
        uint256 value
    ) public onlyOwner {
        for (uint8 i = 0; i < wallets.length; i++) {
            payable(wallets[i]).transfer(value);
        }
    }

    function transferToken(
        address token,
        address recipient,
        uint256 value
    ) external onlyOwner {
        IERC20 ERC20 = IERC20(token);
        ERC20.transfer(recipient, value);
    }

    function transferTokenDifferentValue(
        address token,
        address[] memory wallets,
        uint256[] memory values
    ) public {
        require(wallets.length == values.length);
        IERC20 ERC20 = IERC20(token);
        for (uint8 i = 0; i < wallets.length; i++) {
            ERC20.transferFrom(msg.sender, wallets[i], values[i]);
        }
    }

    function transferTokenSameValue(
        address token,
        address[] memory wallets,
        uint256 value
    ) public {
        IERC20 ERC20 = IERC20(token);
        for (uint8 i = 0; i < wallets.length; i++) {
            ERC20.transferFrom(msg.sender, wallets[i], value);
        }
    }

    function transferOwner(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }
}