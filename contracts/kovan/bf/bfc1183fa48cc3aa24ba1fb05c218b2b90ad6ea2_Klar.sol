/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Klar {
    IERC20 public token1;
    IERC20 public token2;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Swap (
        address indexed _account,
        address _token1,
        address _token2,
        uint256 _amount1,
        uint256 _amount2
    );

    function exchange (
        address _account,
        address _token1,
        address _token2,
        uint256 _amount1,
        uint256 _amount2
    ) public returns (bool success) {
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);

        token1.approve(address(this), _amount1);
        token2.approve(address(this), _amount2);
        
        emit Approval(_token1, address(this), _amount1);
        emit Approval(_token2, address(this), _amount2);

        token1.transferFrom(_token1, address(this), _amount1);
        token2.transferFrom(_token2, address(this), _amount2);

        emit Swap (
            _account,
            _token1,
            _token2,
            _amount1,
            _amount2
        );

        return true;
    }

}