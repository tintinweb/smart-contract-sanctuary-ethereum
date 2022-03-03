/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

contract T {
    event BlockHash(bytes32 hash);

    function getBlockHash() public {
        emit BlockHash(blockhash(block.number));
    }

    function getPreviousBlockHash() public {
        emit BlockHash(blockhash(block.number - 1));
    }
}