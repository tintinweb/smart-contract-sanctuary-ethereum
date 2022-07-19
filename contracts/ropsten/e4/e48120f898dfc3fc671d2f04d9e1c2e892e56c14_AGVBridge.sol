/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract AGVBridge {
    
    address public AGV_address;
    address public owner;
    uint256 public swapFee;
    
    constructor() {
        AGV_address = 0xB647988393B5DF9862c6872d733b060f18C5336e;
        owner = msg.sender;
        swapFee = 1000000000000000; // 0.001
    }
    event Swap(address indexed _address,uint256 _amount,uint256 _chainId); 
    
    modifier onlyOwner() {
        require(owner == msg.sender , "Only owner access");
        _;
    }
    modifier isEnoughFee(){
        require(msg.value >= swapFee , "Low Fee");
        _;
    }
    function changeAgvAddress(address _address) external onlyOwner {
        AGV_address = _address;
    }
    function changeSwapfee(uint256 _swapFee) external onlyOwner {
        swapFee = _swapFee;
    }
    function transferOwnership(address _address) external onlyOwner{
        owner = _address;
    }
    function swap(uint256 _amount,uint256 _chainId) payable isEnoughFee() external{
        IERC20(AGV_address).transferFrom(msg.sender,address(this),_amount);
        emit Swap(msg.sender,_amount,_chainId);
    }
    function transerTo(address _address,uint256 _amount) external onlyOwner{
        IERC20(AGV_address).transfer(_address,_amount);
    }
    function withdrawToken(address _address ,uint256 _amount) external onlyOwner{
        IERC20(_address).transfer(msg.sender,_amount);
    }
    function withdraw(uint256 _amount) external onlyOwner{
       payable(msg.sender).transfer(_amount);    
    }
}