pragma solidity ^0.8.13;

// SPDX-License-Identifier: Apache-2.0

import "./Ownable.sol";

contract EthForwarder is Ownable {

    struct ForwardData {
        address receivingAddress;
        uint256 sharePercentage;
    }

    ForwardData[] private distributionInfo;

    function configure(ForwardData[] memory distribution) external onlyOwner {
        delete distributionInfo;
        
        uint256 totalShares = 0;
        for (uint i = 0; i < distribution.length; ++i) {
            ForwardData memory data = distribution[i];
            totalShares += data.sharePercentage;
            distributionInfo.push(ForwardData(data.receivingAddress, data.sharePercentage));
        }
        require(totalShares == 1000, "total shares must equal 100%");
    }

    function distribute() external onlyOwner {
        require(distributionInfo.length > 0, "no forward addresses found");

        // forward ETH
        uint256 contractBalance = address(this).balance;
        for (uint i = 0; i < distributionInfo.length; ++i) {
            ForwardData memory data = distributionInfo[i];
            payable(address(data.receivingAddress)).transfer(contractBalance * data.sharePercentage / 1000);
        }
    }

    receive() external payable {
    }
}