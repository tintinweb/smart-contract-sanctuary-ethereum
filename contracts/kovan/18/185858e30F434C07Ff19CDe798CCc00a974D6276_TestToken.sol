// SPDX-License-Identifier: MIT
import "./ITestTarget.sol";

pragma solidity >=0.7.0 <0.9.0;

// token with a call back
contract TestToken {
    function transfer(
        address from,
        address to,
        uint256 _amount
    ) external {
        // calls back EmergencyWithdrawal.
        ITestTarget(msg.sender).emergencyWithdraw();
    }

    function mint(uint256 _amount) external {
        // calls back mintNative.
        ITestTarget(msg.sender).mintNative();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface ITestTarget {
    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function emergencyWithdraw() external;

    function mint(uint256 mintAmount) external returns (uint256);

    function mintNative() external payable returns (uint256);
}