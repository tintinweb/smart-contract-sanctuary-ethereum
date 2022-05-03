/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

pragma solidity >=0.5.0 <0.7.0;


    interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
    // don't need to define other functions, only using `transfer()` in this case
}

contract BuyLow{

    //  0x3b00ef435fa4fcff5c209a37d1f3dcff37c705ad theter rinkeby testenet 
    // 0x01be23585060835e02b77ef475b0cc51aa1e0709 CHAINLINK rinkeby testenet
    uint8 ethPrice;
    mapping(address => uint) balances;

    



    // Do not use in production
    // This function can be executed by anyone
    function sendUSDT(address _to, uint256 _amount) public {
         // This is the kovan USDT contract address
         require(msg.sender == _to);
        IERC20 usdt = IERC20(address(0x07de306FF27a2B630B1141956844eB1552B956B5));
        usdt.transfer(_to, _amount);
    }

    

    
    


}