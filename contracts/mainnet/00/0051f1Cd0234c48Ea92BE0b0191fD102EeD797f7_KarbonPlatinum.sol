/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KarbonPlatinum {
    address private owner;

    ERC20 private foreignToken;

    address private constant subAddress1 =
        0x926994574F4A14c276cb652FF8BC2427BA3e89B3;
    address private constant subAddress2 =
        0xB0cE41a94cf9EFCb02F7b70771ad26C98f72265d;
    address private constant subAddress3 =
        0xBF30Ea9bD1A129Ee15a2FdBD0B8a4052966C31b0;
    address private constant mainAddress =
        0x5cA3a7f835573f872493f8Ca79d6D33B4Cba7287;

    struct karbonPlatinumStruct {
        address from;
        address subAddress1;
        address subAddress2;
        address subAddress3;
        address mainAddress;
        uint256 fullAmount;
        uint256 subAmount;
        uint256 mainAmount;
        uint256 timestamp;
        string userId;
    }

    event karbonPlatinumLiquidityEvent(karbonPlatinumStruct karbonPlatinumObj);

    constructor(address _foreignTokenAddress) {
        owner = msg.sender;
        foreignToken = ERC20(_foreignTokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only callable by owner");
        _;
    }

    function karbonPlatinumLiquidity(
        uint256 foreignTokenAmount,
        uint256 subAmount,
        uint256 mainAmount,
        string memory userId
    ) public returns (bool) {
        require(foreignTokenAmount > 0);

        bool foreignTokenTx1 = foreignToken.transferFrom(
            msg.sender,
            address(subAddress1),
            subAmount
        );
        require(foreignTokenTx1);

        bool foreignTokenTx2 = foreignToken.transferFrom(
            msg.sender,
            address(subAddress2),
            subAmount
        );
        require(foreignTokenTx2);

        bool foreignTokenTx3 = foreignToken.transferFrom(
            msg.sender,
            address(subAddress3),
            subAmount
        );
        require(foreignTokenTx3);
        bool foreignTokenTx4 = foreignToken.transferFrom(
            msg.sender,
            address(mainAddress),
            mainAmount
        );
        require(foreignTokenTx4);

        karbonPlatinumStruct memory karbonPlatinumEventObj = karbonPlatinumStruct(
            msg.sender,
            subAddress1,
            subAddress2,
            subAddress3,
            mainAddress,
            foreignTokenAmount,
            subAmount,
            mainAmount,
            block.timestamp,
            userId
        );

        emit karbonPlatinumLiquidityEvent(karbonPlatinumEventObj);

        return true;
    }
}

interface ERC20 {
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

    function decimals() external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}