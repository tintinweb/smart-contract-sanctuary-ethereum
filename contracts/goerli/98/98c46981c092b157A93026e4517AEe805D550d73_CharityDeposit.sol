// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract CharityDeposit {
    event DepositEth(address indexed sender, string name, uint256 amount);

    event DepositErc20(
        address indexed sender,
        string name,
        address tokenAddress,
        uint256 amount
    );

    address public owner;
    mapping(string => uint256) public balances;
    mapping(uint256 => string[]) public einToName;

    //@dev: This function is used to set the owner of the contract

    constructor() {
        owner = msg.sender;
    }

    //@dev: This function is used to deposit ETH into the contract

    function depositEth(string memory _name) public payable {
        balances[_name] += msg.value;
        emit DepositEth(msg.sender, _name, msg.value);
    }

    //@dev: This function is used to deposit ERC20 tokens into the contract

    function depositErc20(
        uint256 ein,
        string memory _name,
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
        balances[_name] += amount;
        emit DepositErc20(msg.sender, _name, tokenAddress, amount);
    }

    //@dev: This function is used to withdraw ETH from the contract

    function withdraw(
      string memory _name,
        address tokenAddress,
        uint256 amount
    ) public {
    
        require(msg.sender == owner, "Only owner can withdraw");
        require(balances[ _name] >= amount, "Not enough balance for withdrawal");
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Failed to transfer ERC20 tokens"
        );
        balances[_name] -= amount;
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

    function withDrawETH(string memory _name , uint256 amount) public {
    
        require(msg.sender == owner, "Only owner can withdraw");
        require(balances[_name] >= amount, "Not enough balance for withdrawal");
        payable(msg.sender).transfer(amount);
        balances[_name] -= amount;
    }

    //@dev: This function is used to withdraw all ETH from the contract

    function withdrawAllEth() public {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

   

    function showBalance(string memory _name) public view returns (uint256) {
 
        return balances[_name];
    }

    function showBalanceOf(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function showAllowance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).allowance(msg.sender, address(this));
    }

    function showBalanceOfOwner(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(msg.sender);
    }

    function showBalanceOfContract(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}