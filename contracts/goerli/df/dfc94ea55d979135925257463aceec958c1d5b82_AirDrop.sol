/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external pure returns (uint8);

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

contract AirDrop {
    address public owner;
    address public ETH = address(0);

    struct airDropdata {
        address tokenAddress;
        uint256 totalAmount;
        uint256 totalClaimed;
        uint256 totalUsers;
        uint256 airDropMax;
        uint256 totalAirDropClaimed;
        uint256 airDropAmount;
    }

    struct User {
        address userAddress;
        uint256 amount;
        bool claimed;
        bool isWhitelisted;
        bool airDropClaimed;
    }

    mapping(address => mapping(address => User)) users;
    mapping(address => airDropdata) airDrop;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function privateAirDrop(
        address[] memory _users,
        uint256[] memory _amounts,
        address tokenAddress
    ) public onlyOwner {
        require(_users.length == _amounts.length, "Invalid data");
        for (uint256 i = 0; i < _users.length; i++) {
            uint256 amount = _amounts[i];
            users[tokenAddress][_users[i]].amount = amount;
            users[tokenAddress][_users[i]].userAddress = _users[i];
            users[tokenAddress][_users[i]].isWhitelisted = true;
            users[tokenAddress][_users[i]].claimed = false;
            airDrop[tokenAddress].totalAmount += amount;
            airDrop[tokenAddress].totalUsers += 1;
        }
    }

    function publicAirDrop(address tokenAddress) public {
        airDropdata storage _airdrop = airDrop[tokenAddress];
        require(
            !users[tokenAddress][msg.sender].airDropClaimed,
            "You have already claimed"
        );

        require(
            _airdrop.totalAirDropClaimed + _airdrop.airDropAmount <=
                _airdrop.airDropMax,
            "Airdrop is over"
        );
        users[tokenAddress][msg.sender].airDropClaimed = true;
        _airdrop.totalAirDropClaimed += _airdrop.airDropAmount;
        if (tokenAddress == ETH) {
            payable(msg.sender).transfer(_airdrop.airDropAmount);
        } else {
            IERC20(tokenAddress).transfer(msg.sender, _airdrop.airDropAmount);
        }
    }

    function claim(address tokenAddress) public {
        require(
            users[tokenAddress][msg.sender].isWhitelisted,
            "You are not whitelisted"
        );
        require(
            !users[tokenAddress][msg.sender].claimed,
            "You have already claimed"
        );
        if (tokenAddress == ETH) {
            payable(msg.sender).transfer(
                users[tokenAddress][msg.sender].amount
            );
        } else {
            IERC20(tokenAddress).transfer(
                msg.sender,
                users[tokenAddress][msg.sender].amount
            );
        }
        users[tokenAddress][msg.sender].claimed = true;
        airDrop[tokenAddress].totalClaimed += users[tokenAddress][msg.sender]
            .amount;
    }

    function withdraw(uint256 _amount, address _tokenAddress)
        external
        onlyOwner
    {
        if (_tokenAddress == ETH) {
            payable(msg.sender).transfer(_amount);
        } else {
            IERC20(_tokenAddress).transfer(msg.sender, _amount);
        }
    }

    function withdrawAll(address _tokenAddress) external onlyOwner {
        if (_tokenAddress == ETH) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(_tokenAddress).transfer(
                msg.sender,
                IERC20(_tokenAddress).balanceOf(address(this))
            );
        }
    }

    function setAirDropValues(
        uint256 _airDropMax,
        uint256 _airDropAmount,
        address tokenAddress
    ) public onlyOwner {
        airDrop[tokenAddress].airDropMax = _airDropMax;
        airDrop[tokenAddress].airDropAmount = _airDropAmount;
    }

    function getAirDropValues(address tokenAddress)
        public
        view
        returns (airDropdata memory)
    {
        return airDrop[tokenAddress];
    }

    function getUser(address tokenAddress, address _user)
        public
        view
        returns (User memory)
    {
        return users[tokenAddress][_user];
    }
}