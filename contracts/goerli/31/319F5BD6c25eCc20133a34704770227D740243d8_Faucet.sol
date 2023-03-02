// SPDX-License-Identifier: UNLISCENSED

pragma solidity ^0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Faucet {
    address public immutable token_address; // Reward token
    IERC20 token;
    mapping(address=>uint256) public nextRequestAt;
    uint256 public withdrawAmount;
    uint256 public delay;

    constructor (address _tokenAddress, uint256 _withdrawAmount, uint256 _delay) {
        token_address = _tokenAddress;
        token = IERC20(token_address);
        withdrawAmount = _withdrawAmount;
        delay = _delay;
    }

    function withdraw() external {
        require(token.balanceOf(address(this)) > 1,"FaucetError: Empty");
        require(nextRequestAt[msg.sender] < block.timestamp, "Must wait 1 full week");
        nextRequestAt[msg.sender] = block.timestamp + delay;
        token.transfer(msg.sender, withdrawAmount * 10 ** token.decimals());
    }
}