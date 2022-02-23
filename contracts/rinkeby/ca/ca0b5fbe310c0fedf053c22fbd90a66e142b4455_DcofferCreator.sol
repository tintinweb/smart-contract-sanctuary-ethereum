/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



interface IERC20 {        
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);  
}





contract DcofferCreator{
    

    IERC20 dcf = IERC20(0xB1Cd8ad16899318DA9F0A2c9933d599eB9cdC10c);

    function burn(uint dcf_amount)private{
        dcf.transferFrom(msg.sender,address(0x0),dcf_amount);
    }



}