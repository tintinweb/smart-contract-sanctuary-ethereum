/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

contract Test {

    function getGasPrice() public view returns (uint256) {
        return tx.gasprice;
    }

    function getBlockFee() public view returns (uint256) {
        return block.basefee;
    }
}