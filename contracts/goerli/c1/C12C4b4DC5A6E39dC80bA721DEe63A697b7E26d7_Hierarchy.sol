/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//推荐制度奖励合约
contract Hierarchy {
    struct User{
        address superior;
        //uint balance;
        uint earnedBNB;
        uint inviterNum;//level 跟Num挂钩
    }

    uint public c;

    mapping(address => User) public getUser;

    uint constant oneRecommendationFor = 10;
    uint constant twoRecommendationFor = 5;
    //uint levelFator;

    address target;

    address owner;

    modifier onlyTarget {
        require(target == msg.sender,"no enought autho");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner,"??????");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function setTarget(address _target) public onlyOwner{
        target = _target;

    }

    function pushUser(address _user, address _superior) public onlyTarget {
        //require(msg.sender != _superior,"require msg.sender != _superior");
        User storage user = getUser[_user];
        user.superior = _superior;
    }


    function pushSuperior(address _superior, uint _price) internal  returns(address granSuperior ,uint superiorProfit,uint granSuperiorProfit){
        if(_superior == address(0)){

        } else
        {
            uint levelFator;
            User storage superior = getUser[_superior];
            superior.inviterNum ++;
            if(superior.inviterNum < 5)
            {
                levelFator = 100;
            }
            else if(superior.inviterNum < 10)
            {
                levelFator = 150;
            }
            else
            {
                levelFator = 200;
            }
            superiorProfit = _price * oneRecommendationFor * levelFator / 10000;

            superior.earnedBNB += superiorProfit;
            granSuperior = superior.superior;
            if(granSuperior == address(0))
            {
                granSuperiorProfit = 0;
                //return(superiorProfit,0);
            }
            else
            {
                granSuperiorProfit = _price * twoRecommendationFor / 100;
                getUser[granSuperior].earnedBNB += granSuperiorProfit;
                //return (superiorProfit,granSuperiorProfit);
            }
        }

    }

    function pushData(address user, uint price) public onlyTarget returns(address gransuperior, uint a, uint b){
        return (pushSuperior(user,price));
    }

    function getUserData(address user) public view returns(User memory){
        return getUser[user];
    }
}