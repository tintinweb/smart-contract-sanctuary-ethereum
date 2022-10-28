// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Will {
    uint fortune;
    
    address payable[] public investorWallets; 
    
    mapping(address => uint) investors;
    
    
    
    function payInvestors(address payable wallet, uint amount) public {
        investorWallets.push(wallet);
        investors[wallet] = amount;
    }
    
    function payout() private {
/*        address payable newAddress = "0x6b3c86BA074E27E06Fc3853f6Fb970d2cced5c1f";
        newAddress.transfer(5);
*/
        for(uint i =0; i<investorWallets.length; i++) {
            investorWallets[i].transfer(investors[investorWallets[i]]);

        }

    } 
    
    constructor() payable public {
            fortune= msg.value;
    }
    
    function makePayment() payable public {
                        payout();
    }


function checkInvestors() public view returns (uint) {
    return investorWallets.length;
}    
}