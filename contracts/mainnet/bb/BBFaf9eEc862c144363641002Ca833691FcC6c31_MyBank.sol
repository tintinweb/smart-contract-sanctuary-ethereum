pragma solidity >=0.8.0 <0.9.0;

interface ERC20Basic {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function transfer(address to, uint256 value) external;
}

contract MyBank {
    address private owner;
    ERC20Basic token;

    constructor(address _token) {
        owner = msg.sender;
        token = ERC20Basic(_token);
    }

    function payout(address to, uint256 amount) external {
        require(owner == msg.sender, "Only allowed for owner");

        uint256 usdtBalance = this.tokenBalance();
        require(usdtBalance >= amount, "Not enough tokens for payout");

        token.transfer(to, amount);
    }

    // Allow you to show how many tokens owns this smart contract
    function tokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}