/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

pragma solidity >=0.7.0 <0.9.0;

    interface ERC20 {
       function balanceOf(address owner) external view returns (uint);
       function allowance(address owner, address spender) external view returns (uint);
       function approve(address spender, uint value) external returns (bool);
       function transfer(address to, uint value) external returns (bool);
       function transferFrom(address from, address to, uint value) external returns (bool); 
    }

contract USDCDisperser {
    
    address public usdcAddress = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;
    address public immutable owner;
    uint amount = 10;


    constructor() {
        owner = msg.sender;
    }

    function disperse() public {
        ERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F).transfer(msg.sender, amount*10**6);
    }

    function withdraw() public {
        require(msg.sender == owner);
        uint bal = ERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F).balanceOf(address(this));
        ERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F).transfer(msg.sender, bal);
    } 
    
}