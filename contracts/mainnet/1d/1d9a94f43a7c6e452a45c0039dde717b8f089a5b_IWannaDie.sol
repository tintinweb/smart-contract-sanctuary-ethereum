/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

contract IWannaDie {
    function killMe() pure public {
        revert("ERROR: Already dead");
    }
}