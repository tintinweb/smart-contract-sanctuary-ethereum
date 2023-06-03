// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Owner {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function setOwner(address wallet) external onlyOwner{
        owner = wallet;
    }
}

contract WhiteList is Owner {
    mapping(address => bool) whiteList;
    
    modifier checkOfWhiteLists(address adr) {
        require(checkOfWhiteList(adr), "Not WhiteList");
        _;
    }

    function checkOfWhiteList(address adr) private view returns (bool) {
        return whiteList[adr];
    }

    function deleteFromWhiteList(address adr)
        external
        checkOfWhiteLists(adr)
        onlyOwner
    {
        delete whiteList[adr];
    }

    function addWhiteList(address adr) external onlyOwner {
        whiteList[adr] = true;
    }
}

contract Transfer is Owner, WhiteList {
    event ProxyDeposit(address token, address from, address to, uint256 amount);

    function proxyToken(
        address token,
        address to,
        uint256 amount
    ) external payable checkOfWhiteLists(to) {
        IERC20(token).transferFrom(msg.sender, to, amount);

        emit ProxyDeposit(token, msg.sender, to, amount);
    }
}