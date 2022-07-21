/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

pragma solidity ^0.4.21;

contract CTFTokenSaleChallenge {
    uint256 public maxUint256 = 0;
    uint256 public eightyPow = 0;
    uint256 public sendToken = 0;
    uint256 public sendValue = 0;

    function CTFTokenSaleChallenge() {
        maxUint256 = 2 ** 256 - 1;
        eightyPow = 10 ** 18;

        sendToken = (maxUint256 / eightyPow) + 1;
        uint256 modvalue = maxUint256 % eightyPow;
        sendToken = eightyPow - modvalue;
    }

    function getMax256() public view returns(uint256){
        return maxUint256;
    }

    function buyOvewrFlowIt() public payable {
        
    }
}