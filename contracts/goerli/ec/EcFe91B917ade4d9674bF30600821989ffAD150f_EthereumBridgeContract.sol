//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract EthereumBridgeContract {
    
    event WETHDeposited(address deposited_by, uint256 value);

    function depositETH(address _receiver) public payable {
        require(msg.value >= 1 ether, "Must send at least 1 ETH");
        uint256 decimalPart = msg.value % (10**18);
        
        // transfer the decimal points back to user
        payable(msg.sender).transfer(decimalPart);
        // this event will be catched by bridge listener
        emit WETHDeposited(_receiver, msg.value);
    }

    function ReleaseETH(address _receiver, uint256 _amount) public {
        require(
            _amount < totalDepositedETH(),
            "Amount exceeding total ETH supply"
        );
        payable(_receiver).transfer(_amount);
    }

    function totalDepositedETH() public view returns (uint256) {
        return (address(this).balance);
    }
}