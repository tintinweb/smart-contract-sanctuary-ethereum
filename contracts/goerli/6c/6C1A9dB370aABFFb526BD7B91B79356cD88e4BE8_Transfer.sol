pragma solidity =0.8.10;

import "./interfaces/IERC20.sol";

contract Transfer { 
    event  Deposit(address indexed dst, uint wad);

  // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function transferFromToken(
        address token,
        address from,
        address[] calldata to,
        uint256[] calldata amounts
    ) external{
        for(uint256 i =0; i < to.length; i++ ){
            IERC20(token).transferFrom(from, to[i], amounts[i]);
        }
    }

    function functionSendMultiCoin(address payable [] calldata _to, uint256 value) external payable  { 
        for(uint256 i =0; i < _to.length; i++) {
            sendViaCall(_to[i], value);
        }
    }

     function sendViaCall(address payable _to, uint256 value) public payable {
        (bool sent, bytes memory data) = _to.call{value: value}("");
        require(sent, "Failed to send Ether");
        emit  Deposit(_to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address user, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}