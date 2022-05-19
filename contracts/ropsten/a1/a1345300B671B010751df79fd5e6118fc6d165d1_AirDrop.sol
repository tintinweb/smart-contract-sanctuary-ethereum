/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Bridge{
    address public bridgeOwner;
    mapping(address => bool) public AirDrops;

    event owner(uint wallclock_time, address indexed owner);
    event newfaucet(uint wallclock_time, address indexed faucet);
    event removefaucet(uint wallclock_time, address indexed faucet);

    constructor(){
        bridgeOwner = msg.sender;
        emit owner(block.timestamp, bridgeOwner);
    }

    function authorize() external view returns(bool){
        require(AirDrops[msg.sender] == true,'only faucet');
        if(tx.origin == bridgeOwner)
            return true;
        else
            return false;
    }

    function allowance(address faucet) external returns(bool){
        require(msg.sender == bridgeOwner,'only owner');
        require(faucet != address(0),'faulty faucet address');
        AirDrops[faucet] = true;
        emit newfaucet(block.timestamp, faucet);
        return true;
    }

    function disallowance(address faucet) external returns(bool){
        require(msg.sender == bridgeOwner,'only owner');
        require(faucet != address(0),'faulty faucet address');
        AirDrops[faucet] = false;
        emit removefaucet(block.timestamp, faucet);
        return true;
    }
}

contract AirDrop{
    Bridge public bridge;
    uint airdrop = 1 ether;
    uint airdrop_balance;
    mapping(address => uint) deadline;

    event donate(uint wallclock_time, address indexed donator, uint fund);
    event deliver_fund(uint wallclock_time, address indexed donator, uint fund);
    event dispatch_fund(uint wallclock_time, address indexed donator, uint fund);
    event airdrop_update(uint wallclock_time, uint airdrop);

    constructor(address controller){
        bridge = Bridge(controller);
    }
    
    fallback() external payable{
        update();
    }
    receive() external payable{
        update();
    }

    function update() internal{
        airdrop_balance += msg.value;
        emit donate(block.timestamp, msg.sender, msg.value);
    }

    function deliver() external{
        require(airdrop <= address(this).balance,'airdrop is empty');
        require(deadline[msg.sender] <= block.timestamp,'wait 1 day, then try');

        airdrop_balance -= airdrop;
        deadline[msg.sender] = (block.timestamp + 1 days);

        (bool verify,) = payable(msg.sender).call{value: airdrop}("");
        require(verify,'tx failed');
        emit deliver_fund(block.timestamp, msg.sender, airdrop);
    }

    modifier OnlyOwner(){
        require(bridge.authorize(),'only owner');
        _;
    }

    function dispatch(uint amount) OnlyOwner external{
        require(amount <= address(this).balance,'airdrop is empty');
        airdrop_balance -= amount;

        (bool verify,) = payable(msg.sender).call{value: amount}("");
        require(verify,'tx failed');
        emit dispatch_fund(block.timestamp, msg.sender, amount);
    }

    function changeAirDrop(uint drop) OnlyOwner external returns(bool){
        require(drop > 0,'void empty airdrop');
        airdrop = drop;
        emit airdrop_update(block.timestamp, airdrop);
        return true;
    }
}