/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

contract Dice {

    uint256 public nonce = 0;
    uint256 public predictedRandomNumber;
    function TheDice() public {
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(this), nonce));
        predictedRandomNumber = uint256(hash) % 16;
        nonce++;
    }

}