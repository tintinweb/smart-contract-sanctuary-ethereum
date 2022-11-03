// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../interfaces/IWToken.sol";

contract Demo {
    address public weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    function deposit() public payable {
        IWToken(weth).deposit{value: msg.value}();
    }

    function withdraw(uint256 amount) public {
        IWToken(weth).withdraw(amount);
		payable(msg.sender).call{value: amount}(new bytes(0));
    }

    receive() external payable {
        require(msg.sender == address(weth), "Receive not allowed");
    }

    fallback() external payable {
        revert("Fallback not allowed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IWToken {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function approve(address guy, uint256 wad) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}