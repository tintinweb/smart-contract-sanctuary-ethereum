// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CustomWallet {
    address payable public owner;
    address[] public masters;
    bool public paused;

    constructor () {
        owner = payable(msg.sender);
    }

    receive () external payable {}
    
    fallback() external payable {}

    modifier onlyOwner {
      require(msg.sender == owner, "You are not the owner.");
      _;
    }

    modifier onlyMasters {
       bool isMaster;
       for (uint i = 0; i < masters.length; i ++) {
           if (masters[i] == msg.sender) {
               isMaster = true;
               break;
           }
       }
       require(isMaster, "You are one of the masters");
       _;
    }

    modifier onlyWhenPaused {
        require(paused, "The contract is not paused yet.");
        _;
    }

    function setPaused(bool _paused) public onlyMasters {
        paused = _paused;
    }

    function addMaster(address newMaster) public onlyOwner {
        _addMaster(newMaster);
    }

    function _addMaster(address newMaster) internal {
        masters.push(newMaster);
    }

    function changeOwner(address payable _newOwner) public onlyWhenPaused onlyMasters{
        _changeOwner(_newOwner);
    }

    function _changeOwner(address payable  _newOwner) internal {
        owner = _newOwner;
    }

    function deposit() external payable  {
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Fail to deposit.");
    }

    function withdraw(uint _amount) public onlyOwner returns(bool) {
        require(paused == false, "The contract is now paused.");
        address caller = msg.sender;
        _withdraw(payable(caller), _amount);
        return true;
    }

    function _withdraw(address payable caller, uint _amount) internal {
        (bool sent, ) = caller.call{value: _amount}("");
        require(sent, "Fail to Withdraw.");
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}