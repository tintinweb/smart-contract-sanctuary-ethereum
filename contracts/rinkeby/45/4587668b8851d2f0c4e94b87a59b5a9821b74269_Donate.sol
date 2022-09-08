/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

pragma solidity >=0.7.0 <0.9.0;

contract Donate{

    address payable meritDonation;
    
    constructor(){
        meritDonation = payable(0xE95C118a1492fE4287354b701eE8e047B69A4639);
    }
   
    function donateBulk() external payable {
        require(msg.value % 1e15 == 0, "Invalid Amount");
        
        uint value = msg.value;

        for(uint i = 0 ; i < 100 ;i++){
            if(value <=0){
                break;
            }

            meritDonation.transfer(1e15);
            value -= 1e15;
        }
    }


}