/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;



contract BestInvestmentEver {
    
    /**
    You can invest, by calling the foundBusiness function, adding in the referrers wallet address, and sending 0.05 ETH with it.
    After that every new Investor you refer, will be your "children", the investors they refer your "grandchildren", the investors they refer your "great-grandchildren".
    You get the following rewards after each of them:
        - children: 0.025 ETH
        - grandchildren: 0.0125 ETH
        - great-grandchildren: 0.00625 ETH

    The way the smart contract works guarantees these rewards for you.

    So that means that if you refer 6 people, they each refer 6, and they too each refer 6, you can easily have
    6 children, 36 grandchildren, 216 great-grandchildren
    In this case you get close to 2 ETH in rewards from your initial 0.05 ETH investment (thats a 4000% profit!)
    */

    struct BusinessOwner{
        bool isActive;
        address parent;
    }

    mapping (address=>BusinessOwner) public members;

    constructor() {
        treasury=msg.sender;
        members[treasury].parent=treasury;
        members[treasury].isActive=true;
    }  
    address public treasury;

    function foundBusiness (address referrer) external payable {
        createNewBusiness(referrer);
    }


    event newBusinessCreated(address businesOwner, address agent);
    function createNewBusiness (address parent) private {
        require(msg.value>=5e16, "price of founding business is 0.05 ETH");
        require (members[parent].isActive==true, "invalid referral address");
        require (members[msg.sender].isActive==false, "already a business owner");
        members[msg.sender].isActive=true;
        members[msg.sender].parent=parent;
        address grandParent=members[parent].parent;
        address greatGrandParent=members[grandParent].parent;
        payable(parent).transfer(0.025 ether);
        payable(grandParent).transfer(0.0125 ether);
        payable(greatGrandParent).transfer(0.00625 ether);
        payable(treasury).transfer(address(this).balance);
        emit newBusinessCreated(msg.sender, parent);
    }

    fallback() external payable {
        createNewBusiness(treasury);
    }

}