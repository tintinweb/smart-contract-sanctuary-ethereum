/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: Unlicensed

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 {
    uint256 public decimals;
}

contract Lock {
    IERC20 private token;
    uint256 decimals;
    uint256 public lockedFor = 0;
    address private owner;
    address private tokenAddress = 0xFa14Fa6958401314851A17d6C5360cA29f74B57B;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "owner");
        _;
    }
    
    constructor() {
        decimals = ERC20(tokenAddress).decimals();
        token = IERC20(tokenAddress);
        owner = msg.sender;
    }

    function currentLocked() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function lock(uint256 amt, uint256 until) public onlyOwner {
        token.transferFrom(owner, address(this), amt);
        lockedFor = until;
    }
    
    function unlock(uint256 amt) public {
        token.transfer(msg.sender, amt);
    }
}