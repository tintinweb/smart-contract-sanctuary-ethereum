/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// File: contracts/NewProject.sol


pragma solidity ^0.8.0;
contract NewProject
{

    uint256[] thancurrent = [0,0,0,0];
    uint256[] degree = [0,0,0,0];
    address[] airconditioningswallet = [0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000,0x0000000000000000000000000000000000000000];
    address  maps;
    mapping(address => bool) shares;
    uint256 size = thancurrent.length;


    function getThancurrent(uint256 airconditioning) external view returns(uint256) {
        require(airconditioning < thancurrent.length, "out of bounds");
        return thancurrent[airconditioning];
    }

    function getDegree(uint256 airconditioning) external view returns(uint256) {
        require(airconditioning < thancurrent.length, "out of bounds");
        return degree[airconditioning];
    }

    function getWallet(uint256 airconditioning) external view returns(address) {
        require(airconditioning < thancurrent.length, "out of bounds");
        return airconditioningswallet[airconditioning];
    }

    function CreatedPay(uint256 _airconditioning,uint256 _ubxs , uint256 _degree ) external  returns(uint256) {
        require(_degree>18, "min");
        require(_degree<35, "maks");
        require(thancurrent[_airconditioning]<_ubxs,"new value must be greater than current");
        thancurrent[_airconditioning]=_ubxs;
        degree[_airconditioning]=_degree;
        airconditioningswallet[_airconditioning]=msg.sender;
    }

    function SetDegree(uint256 airconditioningid , uint256 degree_)
    public 
    {
        require(airconditioningswallet[airconditioningid] == msg.sender, "no admin");
        require(degree_>18, "min");
        require(degree_<35, "maks");
        degree[airconditioningid]=degree_;
    }



}