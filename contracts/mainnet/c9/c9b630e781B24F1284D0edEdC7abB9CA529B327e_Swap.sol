// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint256 balance);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract Swap {
    address public owner;
    address public nextOwner;
    uint256 public swapFee;
    address public vault;
    address public token;
    bool public paused;

    constructor() {
        owner = msg.sender;
        swapFee = 0;
        vault = address(0);
        token = address(0);
        paused = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    event RequestSwap(
        address indexed requester,
        string network,
        uint256 amount,
        address receiver
    );

    event Pause();
    event Unpause();

    function swapRequest(string memory network, uint256 amount, address receiver) external payable {
        require(!paused, "The contract is paused");
        require(msg.value == swapFee, "Inadequate swap fee");
        require(vault != address(0), "Vault is not set");
        require(token != address(0), "Token is not set");
        require(receiver != address(0), "Receiver cannot be zero address");

        _sendTokenToVault(msg.sender, amount);

        payable(owner).transfer(msg.value);

        emit RequestSwap(msg.sender, network, amount, receiver);
    }

    function initialize(uint256 _swapFee, address _vault, address _token) external onlyOwner {
        require(_vault != address(0), "Vault cannot be zero address");
        require(_token != address(0), "Token cannot be zero address");

        swapFee = _swapFee;
        vault = _vault;
        token = _token;
    }

    function changeSwapFee(uint256 _swapFee) external onlyOwner {
        swapFee = _swapFee;
    }

    function changeValut(address _vault) external onlyOwner {
        require(_vault != address(0), "Vault cannot be zero address");
        vault = _vault;
    }

    function changeToken(address _token) external onlyOwner {
        require(_token != address(0), "Token cannot be zero address");
        token = _token;
    }

    function setNextOwner(address _nextOwner) external onlyOwner {
        require(_nextOwner != address(0), "Owner cannot be the zero address");
        nextOwner = _nextOwner;
    }

    function getOwnership() external {
        require(nextOwner == msg.sender, "You are not the next owner");
        owner = nextOwner;
        nextOwner = address(0);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Pause();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpause();
    }

    function _sendTokenToVault(address sender, uint256 amount) private {
        require(ERC20(token).transferFrom(sender, vault, amount), "Transfer Failed");
    }
}