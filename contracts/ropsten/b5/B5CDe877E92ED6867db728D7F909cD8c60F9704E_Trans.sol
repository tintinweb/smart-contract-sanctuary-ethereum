/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

pragma solidity >=0.7.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}

contract Trans {
    function trans(address contractAddress,address to,uint256 amount) public {
        IERC20(contractAddress).transferFrom(msg.sender,to,amount);
    }
}