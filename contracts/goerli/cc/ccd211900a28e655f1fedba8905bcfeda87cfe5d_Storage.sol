/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

contract Storage {
    uint public pos0 = 77;

    function increment() external {
        pos0++;
    }

    function addTo(uint x) external {
        pos0 += x;
    }
}