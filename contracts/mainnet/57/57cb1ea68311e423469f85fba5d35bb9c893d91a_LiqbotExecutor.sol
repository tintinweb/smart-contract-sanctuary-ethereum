/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function transfer(address to, uint value) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract LiqbotExecutor {
    uint256 private constant ONE = 1e18;

    address payable private immutable owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    receive() external payable {}

    function execute(
        address to,
        bytes calldata data,
        uint256 minerCutRate,
        IERC20[] calldata sweepTokens
    )
        external
        onlyOwner
    {
        (bool success, ) = to.call(data);
        require(success);

        for (uint256 i = 0; i < sweepTokens.length; ++i) {
            require(sweepTokens[i].transfer(owner, sweepTokens[i].balanceOf(address(this))));
        }

        block.coinbase.transfer(address(this).balance * minerCutRate / ONE);
        owner.transfer(address(this).balance);
    }
}