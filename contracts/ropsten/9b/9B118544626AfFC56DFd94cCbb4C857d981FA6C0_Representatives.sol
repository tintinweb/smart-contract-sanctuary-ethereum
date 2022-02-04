/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;


interface IToken {
    function balanceOf(address tokenOwner) external view returns (uint balance);

}

contract Representatives {
    address public tokenAddress;
    uint public representativeMin;
    uint public repMaturation;
    mapping(address => Representative )  public registeredReps;
    address consul;

    struct Representative{
        address _rep;
        uint _startBlock;
        uint _unlockBlock;
    }


    constructor(address _tokenAddress) {
        repMaturation = 60480;  //About 7 days
        representativeMin = 10_000e18; // 10000 Digitrade
        tokenAddress = _tokenAddress;
        consul = msg.sender;
    }

    modifier onlyConsul(){
        require(msg.sender == consul);
        _;
    }

    function getUnlockBlock(address _address) private view returns (uint){
        return registeredReps[_address]._unlockBlock;
    }

    function getRep(address _address) public view returns (bool isRep){
        require(getUnlockBlock(_address) > 0, "Not registered");
        require(block.number > getUnlockBlock(_address), "Registered but not a rep yet");
        return true;
    }

    function removeNonHodlers(address _address) public onlyConsul{
       if(IToken(tokenAddress).balanceOf(_address) < representativeMin){
        delete registeredReps[_address];
       }
    }

    function registerRep() public {
      require(IToken(tokenAddress).balanceOf(msg.sender) > representativeMin, "Balance under 10K DGT");
      uint _unlockBlock = block.number + repMaturation;  //unlocks after 30 days or so
      registeredReps[msg.sender] = Representative(msg.sender,block.number, _unlockBlock);
    }

}