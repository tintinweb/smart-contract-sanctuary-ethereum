/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

pragma solidity ^0.8.0;

interface mintInterface {
    function mintsTo(uint _count, address _destination) external;
    function getexapproveflag() external view returns(bool);
}

contract selfish{
    address public targetContract;
    uint mintflag = 0;
    uint level = 0;
    function setTargetContract(address _target) public{
        targetContract = _target;
    }

    function execMint(uint _mintCount) public{
        require(mintflag >= level, "not started");
        mintInterface(targetContract).mintsTo(_mintCount, msg.sender);
    }
    function getflag() public view returns(bool){
        return mintInterface(targetContract).getexapproveflag();
    }

    function setFlag(uint _flag) public {
        mintflag = _flag;
    }
    function setLevel(uint _level) public {
        level = _level;
    }
    function checkLevel() public view returns(uint){
        return level;
    }
    function checkFlag() public view returns(uint){
        return mintflag;
    }

}