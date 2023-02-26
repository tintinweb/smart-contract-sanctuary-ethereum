// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC20 {
    // token总量
    function totalSupply() external view returns (uint256);

    // 查询某一账号余额
    function balanceOf(address account) external view returns (uint256);

    // 当前调用者向其他账号发生余额
    function transfer(address to, uint256 amount) external returns (bool);

    // 查询某个账号对合约的批准额度
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * 批准/授权
     * @param spender 授权的合约地址
     * @param amount 授权金额
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * 合约通过该方法将账号余额转到合约中
     * @param from 普通账户
     * @param to 目标地址
     * @param amount 金额
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Send {
    function sendsToken(
        address erc20Address,
        address[] memory toList,
        uint256 _amount
    ) external payable {
        for (uint i = 0; i < toList.length; i++) {
            IERC20(erc20Address).transferFrom(msg.sender, toList[i], _amount);
        }
    }

    function sends(address[] memory toList, uint256 _amount) external payable {
        for (uint i = 0; i < toList.length; i++) {
            payable(toList[i]).transfer(_amount);
        }
    }
}