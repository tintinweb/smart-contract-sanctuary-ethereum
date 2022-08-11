/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

pragma solidity 0.6.12;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract bank{
    mapping(address=>uint256) balances;
    address public donor_recipient;
    address private weth =  0xd0A1E359811322d97991E03f863a0C30C2cF029C; //kovan

    constructor(address donee) public{
        donor_recipient = donee;
    }

    fallback() external payable {    
    }
    receive() external payable {
    }

    function deposit() payable public{
        balances[msg.sender] += msg.value;
        IWETH(weth).deposit{value: msg.value}();
        //IWETH(weth).transfer(msg.sender, msg.value);
    }

    function direct_donation() payable public{
        payable(donor_recipient).transfer(msg.value);
    }

    function withdraw() payable public{
        require(balances[msg.sender]>= msg.value);
        balances[msg.sender] -= msg.value;
        IWETH(weth).transfer(msg.sender, msg.value);
        //payable(msg.sender).transfer(amount); If using eth instead of weth
    }
    function check_balance(address account) public view returns(uint256){
        return balances[account];
    }

}