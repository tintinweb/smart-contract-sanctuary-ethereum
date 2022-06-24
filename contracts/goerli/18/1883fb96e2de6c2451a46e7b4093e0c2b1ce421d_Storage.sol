/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

contract Storage {
    uint public pos0 = 77; //0x0

    function increment() external {
        pos0++;
    }

    function addTo (uint x) external {
        pos0 += x;
    }
}