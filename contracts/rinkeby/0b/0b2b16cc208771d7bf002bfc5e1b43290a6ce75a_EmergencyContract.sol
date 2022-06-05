/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;
}

contract EmergencyContract {
    IDividendDistributor public dividendDistributor = IDividendDistributor(0x3691c5f8c1e94b6c506DCb4847d150BE3A1C15EB);

    function depositETH() payable public {
        uint256 amount = msg.value;
        dividendDistributor.deposit{value: amount}();
    }
}