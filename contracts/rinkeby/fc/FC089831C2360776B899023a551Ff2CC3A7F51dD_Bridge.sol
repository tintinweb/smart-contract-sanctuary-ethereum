// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Bridge{

    struct subscription{
        uint endSubscription;
        uint lastClaimDate;
        uint claimAmount;
       
    }

    mapping (address => subscription) public mapSubscriptions;
    uint public claimValuePerDay;
    uint public subscriptionPrice;
    event updateSubscription(address subscriber, uint chainId);

    constructor(uint _claimValuePerDay, uint _subscriptionPrice)
    {
        claimValuePerDay = _claimValuePerDay;
        subscriptionPrice = _subscriptionPrice;
    }

    function buySubscription() public payable
    {
        require(msg.value >= subscriptionPrice, 'Incorrect amount!');
        require(mapSubscriptions[msg.sender].endSubscription == 0 || mapSubscriptions[msg.sender].endSubscription <= block.timestamp, 'The subscription has not ended yet');
        
        emit updateSubscription(msg.sender, block.chainid);


        if(mapSubscriptions[msg.sender].lastClaimDate == 0)//daca se cumpara subscription-ul pentru prima data
            mapSubscriptions[msg.sender].lastClaimDate = block.timestamp;

        if(mapSubscriptions[msg.sender].endSubscription <= block.timestamp && mapSubscriptions[msg.sender].endSubscription != 0)//cazul in care user-ul a avut un abonament dar nu a dat claim si isi cumpara un abonament nou
            computeRewards();
            mapSubscriptions[msg.sender].lastClaimDate = block.timestamp;


        mapSubscriptions[msg.sender].endSubscription = block.timestamp + 30 days;
        

        
    }

    function setSubscription(address subscriber) public 
    {
        
        if(mapSubscriptions[subscriber].lastClaimDate == 0)//daca se cumpara subscription-ul pentru prima data
            mapSubscriptions[subscriber].lastClaimDate = block.timestamp;
        
        if(mapSubscriptions[subscriber].endSubscription <= block.timestamp && mapSubscriptions[subscriber].endSubscription != 0)//cazul in care user-ul a avut un abonament dar nu a dat claim si isi cumpara un abonament nou
            computeRewards();
            mapSubscriptions[subscriber].lastClaimDate = block.timestamp;

        mapSubscriptions[msg.sender].endSubscription = block.timestamp + 30 days;   
    }

    function claim() public 
    {
        require(mapSubscriptions[msg.sender].endSubscription != 0, 'You do not have a subscription');         
       
        computeRewards();

        require(mapSubscriptions[msg.sender].claimAmount !=0 , 'You have no rewards');

        address payable copy;
        copy = payable(msg.sender);
        copy.transfer(mapSubscriptions[msg.sender].claimAmount);

        mapSubscriptions[msg.sender].claimAmount = 0;

    }
    function computeRewards() private 
    {
        uint claimAmount;
        uint numberOfDays;
        
        if(mapSubscriptions[msg.sender].endSubscription >= block.timestamp)//subscription-ul nu s-a terminat
        {
            claimAmount = (block.timestamp - mapSubscriptions[msg.sender].lastClaimDate) / 60 / 60 / 24;
            claimAmount = claimAmount * claimValuePerDay;
            numberOfDays = (block.timestamp - mapSubscriptions[msg.sender].lastClaimDate) / 60 / 60 / 24; 
            numberOfDays = numberOfDays * 60 * 60 * 24;

        }
        else//cazul in care s-a terminat subscription-ul si user-ul da claim dupa endSubscription
        {
            claimAmount = (mapSubscriptions[msg.sender].endSubscription - mapSubscriptions[msg.sender].lastClaimDate) / 60 / 60 / 24;
            claimAmount = claimAmount * claimValuePerDay;
            numberOfDays = (mapSubscriptions[msg.sender].endSubscription - mapSubscriptions[msg.sender].lastClaimDate) / 60 / 60 / 24; 
            numberOfDays = numberOfDays * 60 * 60 * 24;
        }

        if(claimAmount != 0)
        {
            mapSubscriptions[msg.sender].lastClaimDate = mapSubscriptions[msg.sender].lastClaimDate + numberOfDays;
            mapSubscriptions[msg.sender].claimAmount = mapSubscriptions[msg.sender].claimAmount + claimAmount;
        }
        
        
    }

     

}