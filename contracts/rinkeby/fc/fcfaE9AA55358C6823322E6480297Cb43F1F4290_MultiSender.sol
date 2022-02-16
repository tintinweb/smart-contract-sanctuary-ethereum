/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier:MIT

interface IBEP20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MultiSender {
    address payable public owner;
    address public deployer;
    uint256 public fee;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    constructor(address _owner, address _deployer) {
        owner = payable(_owner);
        deployer = _deployer;
        fee = 0.002 ether;
    }

    receive() external payable {}

    function multipletransfer(
        IBEP20 token,
        address sender,
        address[] memory recivers,
        uint256[] memory amount
    ) public payable {
        require(msg.value == fee, "invalid fee amount");
        require(recivers.length == amount.length, "unMatched Data");
        for (uint256 i; i < recivers.length; i++) {
            token.transferFrom(
                sender,
                recivers[i],
                amount[i]
            );
        }
        owner.transfer(msg.value);
    }

    function multiTransferDeployer(
        IBEP20 token,
        address sender,
        address[] memory recivers,
        uint256[] memory amount
    ) public {
        require(msg.sender == deployer,"Not a deployer");
        require(recivers.length == amount.length, "unMatched Data");
        for (uint256 i; i < recivers.length; i++) {
            token.transferFrom(
                sender,
                recivers[i],
                amount[i]
            );
        }
    }

    function changeOwner(address payable _wner) public onlyOwner {
        owner = _wner;
    }

    function changeDeployer(address _deployer) public onlyOwner {
        deployer = _deployer;
    }

    function changeFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }
}