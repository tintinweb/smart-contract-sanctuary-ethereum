// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "./ITestToken.sol";

contract TestTarget {
    address private token;

    function setToken(address _token) external {
        token = _token;
    }

    function deposit(uint256 _amount) external {}

    // function that triggers a re-entrancy.
    function withdraw(uint256 _amount) external {
        ITestToken(token).transfer(address(this), msg.sender, _amount);
    }

    function emergencyWithdraw() external {}
}

// SPDX-License-Identifier: MIT
import "./ITestTarget.sol";

pragma solidity >=0.7.0 <0.9.0;

// token with a call back
interface ITestToken {
    function transfer(
        address from,
        address to,
        uint256 _amount
    ) external;

    function mint(uint256 _amount) external;
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