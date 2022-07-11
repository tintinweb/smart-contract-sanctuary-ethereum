/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

pragma solidity ^0.7.5;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256); 
    function transferFrom(address sender, address recipient, uint256 amount) external ;
    function decimals() external view returns (uint8);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract  MyContract {
   	address public usdt;        // 0x8Df243c224E54a60817E477c620300D71D14932C   0x77Feb2b3410B5A15A88f607D5158Ad31fC84eBD4
	constructor(address _usdt) public  {
        usdt = _usdt;
    }

    // 查询外部合约余额
    function getBalance(address addr) public view returns(uint) {
        return IERC20(usdt).balanceOf(addr);
    }

    // 授权转账金额
    function approveContarct(address spender, uint amount) external {
        IERC20(usdt).approve(spender, amount);
    }

    // 查看授权账户额度
    function allowanceContract(address owner, address spender) external view returns (uint256){
        return IERC20(usdt).allowance(owner,spender);
    }

    // 授权转账
    function transferFrom(address from, address to, uint256 value) external {
        require(IERC20(usdt).balanceOf(from) >= value);
        IERC20(usdt).transferFrom(from, to, value);
    }
}