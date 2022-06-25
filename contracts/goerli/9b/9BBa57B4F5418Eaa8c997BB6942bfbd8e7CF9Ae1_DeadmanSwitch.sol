//SPDX-License-Identifier:MIT

pragma solidity ^0.8.4;

contract DeadmanSwitch{

    uint private s_blockNumber;
    address private s_owner;
    address private s_presetAddress;

    constructor(){
        s_blockNumber = block.number;
        s_owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == s_owner);
        _;
    }

    function still_alive() external onlyOwner{
        s_blockNumber = block.number;
    } 

    function transferFund() payable external{
        require(block.number - s_blockNumber> 10 );
        payable(s_presetAddress).transfer(address(this).balance);
    }

    function changePresetAddress(address newAddress) external onlyOwner{
        s_presetAddress = newAddress;
    }

    function getOwner() external view returns(address) {
        return s_owner;
    }

    function getBlockNumber() external view returns(uint){
        return s_blockNumber;
    }

    function getPresetAddress() external view returns(address){
        return s_presetAddress;
    }
}