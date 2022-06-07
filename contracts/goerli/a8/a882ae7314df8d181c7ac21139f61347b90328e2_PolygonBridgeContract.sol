/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PolygonBridgeContract {
    
    event WMaticDeposited(address deposited_by, uint256 value);
    event WMaticReleased(address deposited_by, uint256 value);

    function depositMatic(address _receiver) public payable {
        uint256 decimalPart = msg.value % (10**18);
        
        // transfer the decimal points back to user
        payable(msg.sender).transfer(decimalPart);
        // this event will be catched by bridge listener
        emit WMaticDeposited(_receiver, msg.value);
    }

    function ReleaseMatic(address _receiver, uint256 _amount) public {
        require(
            _amount < totalDepositedMatic(),
            "Amount exceeding total Matic supply"
        );
        payable(_receiver).transfer(_amount);
        emit WMaticReleased(_receiver, _amount);
    }

    function totalDepositedMatic() public view returns (uint256) {
        return (address(this).balance);
    }
}