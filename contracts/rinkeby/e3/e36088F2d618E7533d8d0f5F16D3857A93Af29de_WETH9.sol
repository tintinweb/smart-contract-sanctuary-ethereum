// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./interfaces/IWETH.sol";

contract WETH9 is IWETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed _src, address indexed _to, uint256 _amount);
    event Transfer(address indexed _src, address indexed _to, uint256 _amount);
    event Deposit(address indexed _to, uint256 _amount);
    event Withdrawal(address indexed _src, uint256 _amount);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public {
        require(balanceOf[msg.sender] >= _amount, "INSUFFICIENT_BALANCE");
        balanceOf[msg.sender] -= _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");

        emit Withdrawal(msg.sender, _amount);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address _to, uint256 _amount) public returns (bool) {
        allowance[msg.sender][_to] = _amount;
        emit Approval(msg.sender, _to, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        return transferFrom(msg.sender, _to, _amount);
    }

    function transferFrom(
        address _src,
        address _to,
        uint256 _amount
    ) public returns (bool) {
        require(balanceOf[_src] >= _amount, "INSUFFICIENT_BALANCE");

        if (_src != msg.sender && allowance[_src][msg.sender] >= 0) {
            require(allowance[_src][msg.sender] >= _amount, "EXCEED_ALLOWANCE");
            allowance[_src][msg.sender] -= _amount;
        }

        balanceOf[_src] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(_src, _to, _amount);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}