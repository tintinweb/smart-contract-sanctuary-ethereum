/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Capstone {

    address private owner;                                                      // address of Owner who will deploy this contract

    struct LAND {                                                               // all information of Real Estate will be stored in LAND.
        uint256 id;                                                             // id
        string uri;                                                             // land image link
        uint256 price;                                                          // price
        mapping(address => uint256) holders;                                    // amount of holder, it mean who owns how much, it is not percent, it is eth amount.
        address max_holder;                                                     // address of holder who owns the highest percentage of the RE
        uint256 max_amount;                                                     // amount of max_holder
        uint256 remain;                                                         // amount remaining in property

        bool listed_rent;                                                       // state variable, this property is listed or not in RentList  default: false.
        bool rented;                                                            // state variable, this property is rented or not
        address renter;                                                         // address of renter
        uint256 rent_price;                                                     // when highest holder list to RentList, he will set this variable, renting price
        uint256 rent_start_date;                                                // rent start date
        uint256 rent_end_date;                                                  // rent end date
        mapping(address => bool) rewards;                                       // state variables, when holders claim their reward, this variable will set from "false" to "true"
                                                                                // why this needs? because if we don't have this state variable, we can't manage claiming
                                                                                // I mean, some holders can claim twice or more, but this is not allowed. we have to solve this problem,
                                                                                // I just added this variable to solve it.
    }
    
    event LANDADDED (uint256 index, string _uri);
    
    mapping(uint256 => LAND) public lands;                                      // the array of Real Estate
    uint256 land_count;                                                         // land counts, it means how many properties have been added to this.

    uint256[] landList;                                                         // list of Real Estate, so that users can buy the Property in this list, this variable stores ids of Lands
    uint256[] rentList;                                                         // list of renting Property, so that users can rent the Property in this list, this variable stores ids of Lands

    address public dead = 0x000000000000000000000000000000000000dEaD;           // Dead Address

    constructor() {
        owner = msg.sender;                                                     // We need to save the deployer address, so that we can clarify to the caller is owner(Company) or not.
        land_count = 0;                                                         // Initialize of Total counts
    }

    modifier onlyOwner {                                                        // This is modifier as you know, this modifier is to clarify to know that the caller is owner(Company) or not.
        require(owner == msg.sender, "This function can be called by only owner");
        _;
    }

    function addLand ( string memory uri_, uint256 price_ ) onlyOwner public returns (uint256) {  // Add Property
        lands[land_count].id = land_count;                                      // Initialize Property
        lands[land_count].uri = uri_;
        lands[land_count].price = price_;
        lands[land_count].max_holder = dead;
        lands[land_count].max_amount = 0;
        lands[land_count].remain = price_;
        lands[land_count].rented = false;
        lands[land_count].renter = dead;

        landList.push(land_count);                                              // When it just added, it will be listed to LandList.
        emit LANDADDED(land_count, uri_);
        land_count ++;
        return land_count - 1;
    }

    function buyLand ( uint256 id ) public payable {                            // Buy Property
        require(lands[id].remain >= msg.value, "This land is not enough.");     // if the amount of remaining is less than msg.value, this transaction will be rejected.
                                                                                // why? for example, The Property price is 1 eth. User A want to buy 100%, but User B owns 50% of it. so the remaining is 50%. This is a problem.
        uint256 land_price = lands[id].holders[msg.sender];                     // The Caller already bought the Property. In this case, we need to add new params. so I get the amount of caller here. default: 0
        if(lands[id].max_amount < land_price + msg.value) {                     // If the Caller can be max_holder after this action, so we need to check it and update the max_holder, max_amount.
            lands[id].max_amount = land_price + msg.value;                      // Update max_amount
            lands[id].max_holder = msg.sender;                                  // Update max_holder to the caller
        }
        lands[id].remain = lands[id].remain - msg.value;                        // Update remaining amount of Property
        lands[id].holders[msg.sender] += msg.value;                             // Update status of the Caller of Property
        if(lands[id].remain == 0) {                                             // if the remain is zero, there are no need to list in LandList, this block is for that.
            for(uint256 i = 0 ; i < landList.length ; i ++) {
                if(landList[i] == id) {
                    for(uint256 j = i ; j < landList.length - 1 ; j++) {
                        landList[j] = landList[j + 1];
                    }
                    landList.pop();
                    break;
                }
            }
        }
    }

    function listRent ( uint256 id, uint256 price ) public {                    // List the Property to RentList
        require(lands[id].remain == 0, "This land can not be list to rent. Because the property did not sell 100% yet");    // if remaining amount is not zero, it means that it is not sold 100%. We need to check it
        require(lands[id].max_holder == msg.sender, "You are not allowed to rent");     // if the caller of this function is max_holder, this condition will be passed but if not, this transaction will be rejected. 
        require(lands[id].listed_rent == false, "This land is already listed");         // this condition is for avoiding to list multiple times.
        rentList.push(id);
        lands[id].listed_rent = true;                                           // Update status of Property
        lands[id].rent_price = price;                                           // Update the renting price of Property
    }

    function stopRent ( uint256 id ) public {                                   // remove id item from RentList
        require(lands[id].max_holder == msg.sender, "You are not allowed to do this action");   // Only max holder can call this function
        for(uint256 i = 0 ; i < rentList.length ; i ++) {                       // this block is to remove item from RentList
            if(rentList[i] == id) {
                lands[id].listed_rent = false;
                lands[id].rent_price = 0;
                for(uint256 j = i ; j < rentList.length - 1; j ++) {
                    rentList[j] = rentList[j + 1];
                }
                rentList.pop();
                break;
            }
        }
    }

    function rentLand ( uint256 id, uint256 start_date, uint256 end_date ) public payable {     // This function is called when renter click "Rent" Button
        require(lands[id].listed_rent == true, "This land is not allowed to rent");     // if the id Property is not listed in RentList, this transaction will be rejected.
        require(lands[id].rented == false, "This land is already rented");      // if the id Property is already rented, this transaction will be rejected.
        uint256 period = (end_date - start_date) / 60 / 60 / 24;                // the Start Date and End Date is Unix Epoch time as you know, here we can calculate the period between two times.
        uint256 expected_price = lands[id].rent_price * period / 30;            // Calculate the expected price, for example, the highest user set the 1eth for 1 month. and if the period is 40days, the rent price will be 4/3eth for 40 days.
        require(expected_price <= msg.value, "Insufficient money");             // if the caller sent eth less than expected price, this transaction will be rejected.
        payable(msg.sender).transfer(msg.value - expected_price);               // if the caller sent eth more than expected price, the rest eth will resend to the caller.
        lands[id].renter = msg.sender;                                          // update the status of Property
        lands[id].rented = true;
        lands[id].rent_start_date = start_date;
        lands[id].rent_end_date = end_date;
    }

    function delayRent (uint256 id, uint256 to_date) public payable {           // This function is called when renter click "Delay" button
        require(lands[id].renter == msg.sender, "You can not delay to rent for this land.");    // if the caller is not renter, this transaction will be rejected.
        uint256 period = (to_date - lands[id].rent_end_date) / 60 / 60 / 24;    // it is similar to "rentLand" function, calculate period between (to - end_date)
        uint256 expected_price = lands[id].rent_price * period / 30;            // calculate expected price
        require(expected_price <= msg.value, "Insufficient money");             // if the caller sent eth less than expected price, this transaction will be rejected.
        payable(msg.sender).transfer(msg.value - expected_price);               // if the caller sent eth more than expected price, the rest eth will resend to the caller.
        lands[id].rent_end_date = to_date;                                      // update the status of Property
    }

    function getLandListByUser (address user) public view returns (uint256[] memory) {      // Get the property list that user owns
        uint256 len = 0;
        uint256 i;
        uint256 j;
        for(i = 0 ; i < landList.length ; i ++) {
            j = landList[i];
            if(lands[j].holders[user] != 0) {
                len ++;
            }
        }
        uint256[] memory result = new uint256 [] (len);
        uint256 k = 0;
        for(i = 0 ; i < landList.length ; i ++) {
            j = landList[i];
            if(lands[j].holders[user] != 0) {
                result[k ++] = j;
            }
        }

        return result;
    }

    function getRentListByUser (address user) public view returns (uint256[] memory) {      // Get the property rent list that user owns
        uint256 len = 0;
        uint256 i;
        uint256 j;
        for(i = 0 ; i < rentList.length ; i ++) {
            j = rentList[i];
            if(lands[j].renter == user) {
                len ++;
            }
        }
        uint256[] memory result = new uint256 [] (len);
        uint256 k = 0;
        for(i = 0 ; i < rentList.length ; i ++) {
            j = rentList[i];
            if(lands[j].renter == user) {
                result[k ++] = j;
            }
        }

        return result;
    }

    function getLandList () public view returns (uint256[] memory) {        // Get all property list
        return landList;
    }

    function getRentList () public view returns (uint256[] memory) {        // Get all property rent list
        return rentList;
    }

    function getLandInfo (uint256 id) public view returns (string memory , uint256, uint256) {      // Get the Property Information
        LAND storage current = lands[id];
        return (current.uri, current.price, current.remain);
    }

    function getRentInfo (uint256 id) public view returns (address, uint256, uint256, uint256) {    // Get the rent information of Property
        LAND storage current = lands[id];
        return (current.renter, current.rent_price, current.rent_start_date, current.rent_end_date);
    }

    function calcReward (uint256 id, address user) public view returns (uint256 ) {                 // Calculate rewards
        LAND storage current = lands[id];
        if(current.rented == false || current.rewards[user] == true) {
            return 0;
        }
        uint256 period = (current.rent_end_date - current.rent_start_date) / 60 / 60 / 24;
        uint256 total_amount = current.rent_price * period / 30;
        uint256 result = total_amount * current.holders[user] / current.price;
        return result;
    }

    function withdrawReward (uint256 id) public {                                                   // Claim rewards
        require(lands[id].rewards[msg.sender] == false, "You already withdraw reward");             // if the caller is already claimed once, this transaction will be rejected
        require(lands[id].holders[msg.sender] > 0, "You should have some part of this land,");      // if the caller don't own the percentage of property, this transaction will be rejected
        address receiver = msg.sender;
        uint256 reward = calcReward(id, receiver);                                                  // Calculate reward
        require(reward > 0, "No rewards");                                                          // if the reward is zero, this transaction will be rejected, so that users can save their eth
        payable(receiver).transfer(reward);                                                         // send eth to the caller
        lands[id].rewards[msg.sender] = true;                                                       // update the status of property
    }
}