/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

contract Test {
    function test() public view returns (address) {
        return block.coinbase;
    }
}