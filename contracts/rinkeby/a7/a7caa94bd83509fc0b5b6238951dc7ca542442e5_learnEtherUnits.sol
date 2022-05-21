/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity >= 0.7.0 < 0.9.0;

contract learnEtherUnits {
    
    function test() public{
        assert(1000000000000000000 wei == 1 ether);
        assert(1 wei == 1);
        assert(1 ether == 1e18);
        
        assert(2 ether == 2000000000000000000 wei);
    }
    
    function exercise() public {
        
        assert(1 minutes == 60 seconds);
        assert(60 minutes == 1 hours);
        assert(24 hours == 1 days);
        assert(1 weeks == 7 days);
        
        assert(10 == 9 + 1);
    }
}