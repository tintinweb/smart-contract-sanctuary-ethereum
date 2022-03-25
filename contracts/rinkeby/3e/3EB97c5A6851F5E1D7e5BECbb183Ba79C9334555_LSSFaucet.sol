// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract LSSFaucet {
    IERC20 public token;
    address public owner;
    mapping(address => uint256) public nextRequestAt;
    uint256 public faucetDripAmount = 5000;

    constructor(address _tokenAddress, address _ownerAddress) {
        token = IERC20(_tokenAddress);
        owner = _ownerAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FaucetError: Caller not owner");
        _;
    }

    function send() external {
        require(token.balanceOf(address(this)) > 1, "FaucetError: Empty");
        require(nextRequestAt[msg.sender] < block.timestamp, "FaucetError: Try again later");

        // Next request from the address can be made only after 5 minutes
        nextRequestAt[msg.sender] = block.timestamp + (1 days);

        token.transfer(msg.sender, faucetDripAmount * 10**token.decimals());
    }

    function setTokenAddress(address _tokenAddr) external onlyOwner {
        token = IERC20(_tokenAddr);
    }

    function setFaucetDripAmount(uint256 _amount) external onlyOwner {
        faucetDripAmount = _amount;
    }

    function withdrawTokens(address _receiver, uint256 _amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "FaucetError: Insufficient funds");
        token.transfer(_receiver, _amount);
    }
}