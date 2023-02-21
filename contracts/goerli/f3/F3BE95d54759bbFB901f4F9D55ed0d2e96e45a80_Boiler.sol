/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract Boiler {
    address owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event Even(
        uint256 indexed timeStampNewStake,
        address indexed addresNewStake,
        uint256 indexed amountNewStake
    );

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        emit OwnershipTransferred(owner, owner);
    }

    function transferOwnership(address _newOwner) public virtual onlyOwner {
        require(
            _newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(_newOwner);
    }

    function _setOwner(address _newOwner) private {
        address _oldOwner = owner;

        owner = _newOwner;

        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    function getBalance(address _address) public view returns (uint256) {
        return _address.balance;
    }

    function transferTo(address _address, uint256 _amount) public onlyOwner {
        uint256 _timestamp = block.timestamp;
        address payable _to = payable(_address);

        _to.transfer(_amount);

        emit Even(_timestamp, _address, _amount);
    }

    receive() external payable {}
}