/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

contract Roll {

    address public diceAddress;
    uint256 public nonce = 0;
    uint256 public predictedRandomNumber;
    function TheRoll() public {
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, diceAddress, nonce));
        predictedRandomNumber = uint256(hash) % 16;
        nonce++;
    }

    function setDiceAddress(address _diceAddress) public {
        diceAddress = _diceAddress;
    }

    // This function is used in case `Dice::nonce` changes and `Roll::nonce` is no longer equal to it.
    function setNonce(uint216 _nonce) public {
        nonce = _nonce;
    }

}