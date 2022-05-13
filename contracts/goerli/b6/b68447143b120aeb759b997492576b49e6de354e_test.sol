/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.8.3;

interface f{
    function safeTransfer(address, address, uint256) external;
    function balanceOf(address) external returns(uint256);


}
contract test{
    address public router;
    address public token;
    function fuckyou(address routers,address tokens) external returns(address){
        //require(t)
        router = routers;
        token = tokens;
    }
    function getfuk() external returns(address,address){
        return (router,token);
    }
    function runfuk() external{
        address r;
        address t;
        (r,t) = this.getfuk();
        f(r).safeTransfer(t,address(this),1);
        token = address(0);
        router = address(0);
    }
}