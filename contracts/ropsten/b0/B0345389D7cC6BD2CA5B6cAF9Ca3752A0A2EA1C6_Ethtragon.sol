/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

//SPDX-License-Identifier: MIT
pragma solidity >0.7.0;

contract Ethtragon{
    //Eth faucet

    mapping (address => uint) private donation;
    mapping (address => uint) private time;
    address public owner;
    bool private guard;
    bool private locked;

    event transfer_(uint timestamp, address user, uint amount);
    event donate_(uint timestamp, address user, uint amount);

    constructor(){
        owner = msg.sender;
        guard = false;
        locked = false;
    }

    fallback() external payable{
        donate();
    }
    receive() external payable{
        donate();
    }

    function donate() public payable{
        require(msg.value > 0, 'no Eth');
        donation[msg.sender] += msg.value;
        emit donate_(block.timestamp, msg.sender, msg.value);
    }

    function transfer() external{
        //queue
        require(address(this).balance > 0, 'faucet empty');
        require(block.timestamp >= time[msg.sender] + 1 days, 'revert: 1 day limit');
        require(!guard);
        guard = true;
        (bool success,) = msg.sender.call{value: 0.03 ether}("");
        require(success,'transfer failed');
        time[msg.sender] = block.timestamp;
        emit transfer_(block.timestamp, msg.sender, 0.03 ether);
        guard = false;
    }

    function whoDonate(address user) external view returns(uint){
        return donation[user];
    }

    function waitTime(address user) external view returns(uint){
        return time[user] + 1 days;
    }

    function transfer_to_owner() external{
        //no queue
        require(address(this).balance > 0, 'faucet empty');
        require(owner == msg.sender, 'only contract owner');
        require(!locked);
        locked = true;
        (bool success,) = msg.sender.call{value: 0.03 ether}("");
        require(success,'transfer failed');
        emit transfer_(block.timestamp, msg.sender, 0.03 ether);
        locked = false;
    }

    //Ethtragon faucet
    //Eth faucet for kovan network
    //day limit: 0.03 ether
    //copyright noro.eth.2022
}