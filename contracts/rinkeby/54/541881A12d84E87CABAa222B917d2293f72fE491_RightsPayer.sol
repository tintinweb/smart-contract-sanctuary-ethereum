// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

contract RightsPayer {
    uint256 public payPerPlay;
    address payable public owner;
    address payable public receiver;

    mapping(address => bool) public isAdmin;

    event RightsPayed(
        uint256 paid,
        uint256 payPerPlay,
        uint256 plays,
        address receiver,
        address triggeredBy
    );

    error WithdrawalFailed();
    error PayRightsFailed();
    error NotAnAdmin();

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
        if (msg.sender != owner && !isAdmin[msg.sender]) revert NotAnAdmin();
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getTotalPay(uint256 plays) public view returns (uint256) {
        return plays * payPerPlay;
    }

    function setPayPerPlay(uint256 newPrice) public onlyAdmin {
        payPerPlay = newPrice;
    }

    function setReceiver(address payable _receiver) public onlyAdmin {
        receiver = _receiver;
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

    function payRights(uint256 plays) public onlyAdmin {
        uint256 total = plays * payPerPlay;

        (bool success, ) = receiver.call{value: total}("");
        if (!success) revert PayRightsFailed();
        emit RightsPayed(total, payPerPlay, plays, receiver, msg.sender);
    }

    // withdraw content to
    function withdraw() external onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert WithdrawalFailed();
    }

    function fundContract() external payable {}

    receive() external payable {}
}