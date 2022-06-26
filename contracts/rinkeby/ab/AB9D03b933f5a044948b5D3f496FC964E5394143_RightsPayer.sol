// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract RightsPayer {
    uint256 private payPerPlay;
    address payable public owner;
    address payable public receiver;

    mapping(address => bool) public isAdmin;

    error WithdrawalFailed();

    constructor(
        uint256 _payPerPlay,
        address payable _receiver,
        address _admin
    ) {
        payPerPlay = _payPerPlay;
        receiver = _receiver;
        isAdmin[_admin] = true;
        owner = payable(msg.sender);
        isAdmin[owner] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || isAdmin[msg.sender]);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getPayPerPlay() public view returns (uint256) {
        return payPerPlay;
    }

    function getTotalPlay(uint256 plays) public view returns (uint256) {
        return plays * payPerPlay;
    }

    function setPayPerPlay(uint256 newPrice) public onlyAdmin {
        payPerPlay = newPrice;
    }

    function setReceiver(address payable _receiver) public onlyAdmin {
        receiver = _receiver;
    }

    function withdraw(uint256 plays) public onlyAdmin {
        uint256 total = plays * payPerPlay;

        (bool success, ) = payable(receiver).call{value: total}("");
        if (!success) revert WithdrawalFailed();
    }

    function addAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
    }

    function deleteAdmin(address _admin) external onlyOwner {
        delete isAdmin[_admin];
    }

    function setOwner(address payable _owner) external onlyOwner {
        owner = _owner;
    }
}