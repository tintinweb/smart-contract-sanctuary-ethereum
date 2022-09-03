/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface USDT{

    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;


    }

contract DOI{


      struct allInvestments{

            uint investedAmount;
            uint claim_Time;
            uint buying_Time;
            uint investmentNum;
            uint unstakeTime;
            bool claimed;



        }



    struct user_info{

        mapping(uint=>allInvestments) investment;
        uint tokens_for_claiming;
        address referralFrom;
        bool investBefore;
        address[] hisReferrals;
        uint ref_tokens_claiming;
        uint total_investments;
         


    }


    struct Data{

        uint  upper_limit;
        uint  quantity;
        uint  total_limit;

    }

    constructor(address _usdt_add, address _buy_token_add){

        usdt_address=_usdt_add;
        buy_token_add=_buy_token_add;
        owner=msg.sender;

        for(uint i=0; i<3;i++)
        {
            if(i==0)
            {
                round[i].upper_limit=100;
                round[i].quantity=5000;
                round[i].total_limit=10000;//50000000

            }
            if(i==1)
            {
                round[i].upper_limit=500;
                round[i].quantity=2000;
                round[i].total_limit=10000;//50000000

            }
            if(i==2)
            {
                round[i].upper_limit=1000;
                round[i].quantity=2000;
                round[i].total_limit=10000;//66666667

            }
        }

    }

    mapping(address=>user_info) public user;
    mapping(uint=>Data) public round;
    address public usdt_address;
    address public buy_token_add;
    address public owner;
    uint public time_end;

    uint public num;

    function sendRewardToReferrals(address investor,uint _investedAmount)  internal  //this is the freferral function to transfer the reawards to referrals
    { 

        address temp = investor;       
        uint[] memory percentage = new uint[](5);
        percentage[0] = 5;
        percentage[1] = 4;
        // percentage[2] = 3;



        uint j;



        for(uint i=0;i<2;i++)
        {

            if(i==0)
            {
                j=0;
            }
            else if(i==1)
            {
                j=1;
            }
            // else if(i==2)
            // {
            //     j=2;
            // }
            
            if(user[temp].referralFrom!=address(0))
            {

                temp=user[temp].referralFrom;
                uint reward1 = (percentage[j] * _investedAmount)/100;

                user[temp].ref_tokens_claiming+=reward1;



            } 
            else{
                break;
            }

        }

    }





    function buy_tokens(address _referral) external returns(bool){
        require(round[num].quantity<=round[num].total_limit,"asking tokens are more than the limit");
        require(USDT(usdt_address).balanceOf(msg.sender)>round[num].upper_limit*10**18,"you dont have enough balance to buy");
        require(USDT(usdt_address).transferFrom(msg.sender,owner,round[num].upper_limit*10**18),"tokens does not transferred");

        user[msg.sender].investment[user[msg.sender].total_investments].investedAmount=round[num].quantity;
        user[msg.sender].investment[user[msg.sender].total_investments].buying_Time=block.timestamp;
        // user[msg.sender].investment[user[msg.sender].total_investments].claim_Time=block.timestamp+ 10 days;

        user[msg.sender].total_investments++;
        user[msg.sender].tokens_for_claiming+=round[num].quantity;
        round[num].total_limit-=round[num].quantity;
        
        if(_referral==address(0) || _referral==msg.sender)                                         //checking that investor comes from the referral link or not
        {

            user[msg.sender].referralFrom = address(0);
        }
        else
        {
            if(user[msg.sender].investBefore == false)
            { 
                user[msg.sender].referralFrom = _referral;
                user[_referral].hisReferrals.push(msg.sender);
            }
            sendRewardToReferrals(msg.sender,round[num].quantity);      //with this function, sending the reward to the all 12 parent referrals
            
        }
        if(round[num].total_limit==0)
        {
            if(num==2)
            {
                //time_end=block.timestamp+100 days;            

                time_end=block.timestamp+2 minutes;            
            }
            num++;
        }
        user[msg.sender].investBefore=true;

        return true;
    }

    function claim_ref_tokens() external returns(bool)
    {
        require(user[msg.sender].ref_tokens_claiming>0,"you dont have tokens to claim");
        require(round[2].total_limit==0 && time_end > 0 && time_end > block.timestamp);

        USDT(buy_token_add).transfer(msg.sender,(user[msg.sender].ref_tokens_claiming)*10**18);
        user[msg.sender].ref_tokens_claiming=0;


        return true;
    }

    function claim_bought_tokens(uint _num) external returns(bool)
    {
        require(user[msg.sender].investment[_num].investedAmount>0,"you dont have tokens to claim");
        // require(user[msg.sender].investment[_num].claim_Time>0 && user[msg.sender].investment[_num].claim_Time<block.timestamp,"investment claim time time is not completed");
        require(round[2].total_limit==0 && time_end > 0 && time_end > block.timestamp);
        require(!user[msg.sender].investment[_num].claimed,"investment claim time time is not completed");

        USDT(buy_token_add).transfer(msg.sender,(user[msg.sender].investment[_num].investedAmount)*10**18);
        user[msg.sender].investment[_num].claimed=true;
        user[msg.sender].tokens_for_claiming-=user[msg.sender].investment[_num].investedAmount;



        return true;
    }

    function getAll_Buyings() public view returns (allInvestments[] memory) { //this function will return the all investments of the investor and withware date
            uint _num = user[msg.sender].total_investments;
            uint temp;
            uint currentIndex;
            
            for(uint i=0;i<_num;i++)
            {
               if( user[msg.sender].investment[i].investedAmount > 0 && !user[msg.sender].investment[i].claimed ){
                   temp++;
               }

            }
         
            allInvestments[] memory Invested =  new allInvestments[](temp) ;

            for(uint i=0;i<_num;i++)
            {
               if( user[msg.sender].investment[i].investedAmount > 0 && !user[msg.sender].investment[i].claimed){
                 //allInvestments storage currentitem=DUSDinvestor[msg.sender].investment[i];
                   Invested[currentIndex]=user[msg.sender].investment[i];
                   currentIndex++;
               }

            }
            return Invested;

        }


    function get_claim_ref_tokens() external view returns(uint)
    {
        return user[msg.sender].ref_tokens_claiming;
    }

    function get_claimable_tokens() external view returns(uint)
    {
        return user[msg.sender].tokens_for_claiming;
    }

    function change_upperLimit(uint _upper_limit,uint _round)  public
    {
        require(msg.sender==owner,"only Owner can call this function");
        round[_round-1].upper_limit=_upper_limit;
    
    }

    function transferOwnership(address _owner)  public
    {
        require(msg.sender==owner,"only Owner can call this function");
        owner = _owner;
    }










}