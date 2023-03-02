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
    event DepositEth(
        address indexed sender,
        uint256 indexed ein,
        string name,
        uint256 amount
    );

    event DepositErc20(
        address indexed sender,
        uint256 indexed ein,
        string name,
        address tokenAddress,
        uint256 amount
    );

    address public owner;
    mapping(bytes32 => uint256) public balances;
    mapping(uint256 => string) public einToName;

    //@dev: This function is used to set the owner of the contract

    constructor() {
        owner = msg.sender;
    }

    //@dev: This function is used to deposit ETH into the contract

    function depositEth(uint256 ein, string memory _name) public payable {
        bytes32 key = bytes32(ein);
        einToName[ein] = _name;


        balances[key] += msg.value;
        emit DepositEth(msg.sender, ein, _name, msg.value);
    }

    //@dev: This function is used to deposit ERC20 tokens into the contract

    function depositErc20(
        uint256 ein,
        string memory _name,
        address tokenAddress,
        uint256 amount
    ) public {
        bytes32 key = bytes32(ein);
        einToName[ein] = _name;
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
        balances[key] += amount;
        emit DepositErc20(msg.sender, ein, _name, tokenAddress, amount);
    }

    //@dev: This function is used to withdraw ETH from the contract

    function withdraw(
        uint256 ein,
        address tokenAddress,
        uint256 amount
    ) public {
        bytes32 key = bytes32(ein);
        require(msg.sender == owner, "Only owner can withdraw");
        require(balances[key] >= amount, "Not enough balance for withdrawal");
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Failed to transfer ERC20 tokens"
        );
        balances[key] -= amount;
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

    function withDrawETH(uint256 ein, uint256 amount) public {
        bytes32 key = bytes32(ein);
        require(msg.sender == owner, "Only owner can withdraw");
        require(balances[key] >= amount, "Not enough balance for withdrawal");
        payable(msg.sender).transfer(amount);
        balances[key] -= amount;
    }

    //@dev: This function is used to withdraw all ETH from the contract

    function withdrawAllEth() public {
        require(msg.sender == owner, "Only owner can withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function showName(uint256 ein) public view returns (string memory) {
        return einToName[ein];
    }

    function showBalance(uint256 ein) public view returns (uint256) {
        bytes32 key = bytes32(ein);
        return balances[key];
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