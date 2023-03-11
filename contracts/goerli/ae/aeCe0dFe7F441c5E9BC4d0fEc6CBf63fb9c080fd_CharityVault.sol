// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract CharityVault {
    event Donated(address sender, string ein, uint256 amount);

    event DonatedTokens(
        address sender,
        string ein,
        address tokenAddress,
        uint256 amount
    );

    event ReceivedDonation(address sender, uint256 amount);

    address public owner;

    mapping(string => uint256) public balances;

    mapping(address => address) public donors;

    //@dev: This function is used to set the owner of the contract

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit ReceivedDonation(msg.sender, msg.value);
    }

    function donate(string memory ein) public payable {
        balances[ein] += msg.value;
        emit Donated(msg.sender, ein, msg.value);
    }

    //@dev: This function is used to deposit ERC20 tokens into the contract

    function donateTokens(
        string memory ein,
        address tokenAddress,
        uint256 amount
    ) public {
        require(
            IERC20(tokenAddress).allowance(msg.sender, address(this)) >= amount,
            "Not enough allowance for deposit"
        );
        require(
            IERC20(tokenAddress).balanceOf(msg.sender) >= amount,
            "Not enough balance for deposit"
        );
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Failed to transfer ERC20 tokens"
        );
        balances[ein] += amount;
        emit DonatedTokens(msg.sender, ein, tokenAddress, amount);
    }

    //@dev: This function is used to withdraw ETH from the contract

    function withdraw(
        string memory ein,
        address tokenAddress,
        uint256 amount
    ) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(balances[ein] >= amount, "Not enough balance for withdrawal");
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Failed to transfer ERC20 tokens"
        );
        balances[ein] -= amount;
    }

    //@dev: This function is used to withdraw all  erc20s from the contract

    function withdrawAll(address tokenAddress) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(
            IERC20(tokenAddress).transfer(
                msg.sender,
                IERC20(tokenAddress).balanceOf(address(this))
            ),
            "Failed to transfer ERC20 tokens"
        );
    }

    // @dev: This function is used to withdraw ETH from the contract

    function withDrawETH(string memory ein, uint256 amount) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(balances[ein] >= amount, "Not enough balance for withdrawal");
        payable(msg.sender).transfer(amount);
        balances[ein] -= amount;
    }

    //@dev: This function is used to withdraw all ETH from the contract

    function withdrawAllEth() public {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function showBalance(string memory ein) public view returns (uint256) {
        return balances[ein];
    }

    function showBalanceOf(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function showAllowance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).allowance(msg.sender, address(this));
    }

    function showBalanceOfOwner(
        address tokenAddress
    ) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(msg.sender);
    }

    function showBalanceOfContract(
        address tokenAddress
    ) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}