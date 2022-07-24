/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


contract helpInvestorsJoin{
    /**
    This contract stores the funds for people that are getting compensated by me for investing in contract 0x6c1FFa8BE1eD411C2E9e0Cee4935AB51695e821c
    
    You can check if funds for you are avaible by reading "areFundsAvaible" mapping.
    You can withdraw your funds after investing by calling "withdrawFunds" function.

    Note that owner cant withdraw your funds once you have invested, so you are guaranteed to recieve that money
    */

    address public owner;
    myContract public _contract;

    constructor (address payable addressOfContract){
        owner=msg.sender;
        _contract=myContract(addressOfContract);
    }

    mapping (address => bool) public areFundsAvaible;

    function withdrawFunds() public {
        require (isMemberActive(msg.sender)==true, "you are not registered, you cannot get your funds yet");
        require (areFundsAvaible[msg.sender]==true, "funds are not avaible for this wallet");
        areFundsAvaible[msg.sender]=false;
        payable(msg.sender).transfer(0.05 ether);
    }

    function ownerAddFunds(address allowed) public payable onlyOwner {
        require (msg.value==0.05 ether, "exactly 0.05 ETH needed");
        require (areFundsAvaible[allowed]==false, "person already has allowance");
        areFundsAvaible[allowed]=true;
    }

    function ownerWithdrawFunds(address allowed) public onlyOwner {
        require (areFundsAvaible[allowed]==true, "person already has allowance");
        require (isMemberActive(allowed)==false, "member is registered, you cannot withdraw funds");
        areFundsAvaible[allowed]=false;
        payable(owner).transfer(0.05 ether);
    }

    function isMemberActive(address person) internal view returns (bool) {
        bool _isActive;
        address _parent;
        (_isActive, _parent)=_contract.members(person);
        return (_isActive && _parent==owner);
    }

    modifier onlyOwner() { 
        require(msg.sender == owner, "only owner can call this function"); 
        _; 
    }

}



///The following is only only a reference to the original contract at address 0x6c1FFa8BE1eD411C2E9e0Cee4935AB51695e821c

contract myContract {
    
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