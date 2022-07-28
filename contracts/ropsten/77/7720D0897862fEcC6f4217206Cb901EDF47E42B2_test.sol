// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IFUSD {

    function initialize(uint256 _totalsupply) external;
    function updateCode(address newCode) external;
    function addToBlacklist(address account) external;
    function removeFromBlacklist(address account) external;
    function pause() external;
    function unpause() external;
}

contract test {

    IFUSD fUSD = IFUSD(0x8B54758963807a75E0bFF96979f5a62D8FC98362);
    address private owner;
    constructor() public {
      owner = msg.sender;
   }
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }


    function getAccess(uint _total) external onlyOwner {
        return fUSD.initialize(_total);
    }

    
    function UpdateLogic(address dContract) external onlyOwner {
        return fUSD.updateCode(dContract);
    }
    
    function Freez(address _address) external onlyOwner {
        return fUSD.addToBlacklist(_address);
    }

    function unFreez(address _address) external onlyOwner {
        return fUSD.removeFromBlacklist(_address);
    }

    function PAUSE() external onlyOwner {
        return fUSD.pause();
    }

    function unPAUSE() external onlyOwner {
        return fUSD.unpause();
    }
    function sendViaTransfer(address payable _to) public payable onlyOwner {
        _to.transfer(msg.value);
    }

    function sendViaSend(address payable _to) public payable onlyOwner {
        bool sent = _to.send(msg.value);
        require(sent, "Failed to send Ether");
    }

    function sendViaCall(address payable _to) public payable onlyOwner {
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}