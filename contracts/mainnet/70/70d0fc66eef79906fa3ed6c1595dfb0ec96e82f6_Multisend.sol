// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
    function totalSupply() public view virtual returns (uint256);
    function balanceOf(address who) public view virtual returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Multisend {
    event TransferFail(address to, uint256 value);
    event TransferSuccess(address to, uint256 value);
    event MultisendSuccess(uint256 total, address tokenAddress);
    event ClaimedBalance(address token, address owner, uint256 balance);
    event NotClaimedBalance(address token, address owner, uint256 balance);
    address public owner;
    address public feeAddress;
    uint256 public fee;
    
    constructor(address _feeAddress, uint256 _fee) {
        feeAddress = _feeAddress;
        fee = _fee;
        owner = msg.sender;
    }

    function multisendEth(address payable [] memory _contributors, uint256[] memory _balances) public collectFee payable {
        require(msg.value >= fee);
        require(_contributors.length <= 200);
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            (bool success, ) = _contributors[i].call{value: _balances[i]}("");
            if(success) {
                emit TransferSuccess(_contributors[i], _balances[i]);
            } else {
                emit TransferFail(_contributors[i], _balances[i]);
                revert("multisendEth: multisend transfer failed");
            }
        }
        emit MultisendSuccess(msg.value - fee, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    }

    function multisendToken(address token, address payable[] memory _contributors, uint256[] memory _balances) public collectFee payable {
        uint256 total = 0;
        require(_contributors.length <= 200);
        ERC20 erc20token = ERC20(token);
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            if(erc20token.transferFrom(msg.sender, _contributors[i], _balances[i])) {
                emit TransferSuccess(_contributors[i], _balances[i]);
            } else {
                emit TransferFail(_contributors[i], _balances[i]);
                revert("multisendToken: multisend transfer failed");
            }
            total += _balances[i];
        }
        emit MultisendSuccess(total, token);
    }

    function claimBalance(address _token) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool success, ) = payable(owner).call{value: address(this).balance}("");
            if(success) {
              emit ClaimedBalance(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, owner, address(this).balance);
            } else {
              emit NotClaimedBalance(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, owner, address(this).balance);
            }
            return;
        }
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        if(erc20token.transferFrom(address(this), owner, balance)) {
            emit ClaimedBalance(_token, owner, balance);
        } else {
            emit NotClaimedBalance(_token, owner, balance);
            revert("claimBalance: claim balance failed");
        }
    }
    
    function changeFee (uint256 _fee) external onlyOwner {
        fee = _fee;
    }
    
    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }
    
    function changeFeeAddress (address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier collectFee {
        if(fee > 0) {
            require(msg.value >= fee, "insufficient fee sent");
            payable(feeAddress).transfer(fee);
        }
        _;
    }
}