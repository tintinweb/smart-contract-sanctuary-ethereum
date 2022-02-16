/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract TimedSafe {

	struct safeOwner{
		address _address;
		uint256 lastActive;
        uint256 withdrawLimit;
        uint256 withdrawn;
	}

    uint256 public blocksToExpire = 1 * 24 * 60 * 60 / 5;     // smartBCH: 1 block every 5 ~ 6 seconds; ethereum: 12 ~ 14 seconds
    mapping(uint256 => safeOwner) idToSafeOwner;

    constructor(address _safeOwnerAddress_1, address _safeOwnerAddress_2) {
        idToSafeOwner[0]._address = msg.sender;
        idToSafeOwner[1]._address = _safeOwnerAddress_1;
        idToSafeOwner[2]._address = _safeOwnerAddress_2;

        idToSafeOwner[0].lastActive = block.number;
        idToSafeOwner[1].lastActive = block.number;
        idToSafeOwner[2].lastActive = block.number;
    }

    modifier safeOwnerOnly(uint _safeOwnerId) {
        require (msg.sender == idToSafeOwner[_safeOwnerId]._address, "wrong ID or not owner");
        _;
    }

    function setBlocksToExpire(uint _safeOwnerId, uint _blocksToExpire) external safeOwnerOnly(_safeOwnerId) {
        blocksToExpire = _blocksToExpire;
    }

    function stayActive(uint _safeOwnerId) external safeOwnerOnly(_safeOwnerId) { 
        idToSafeOwner[_safeOwnerId].lastActive = block.number;
    }

    function showLastActive() external view returns(uint, uint, uint) {
        return (
            idToSafeOwner[0].lastActive,
            idToSafeOwner[1].lastActive,
            idToSafeOwner[2].lastActive
        );
    }

    function setWithdrawLimit(uint _safeOwnerId, uint _withdralLimit) external safeOwnerOnly(_safeOwnerId) {
        require(_withdralLimit > idToSafeOwner[_safeOwnerId].withdrawLimit, "limit can only be increased");
        idToSafeOwner[_safeOwnerId].lastActive = block.number;
        idToSafeOwner[_safeOwnerId].withdrawLimit = _withdralLimit;
    }

    function withdraw(uint _safeOwnerId, uint _amount) external safeOwnerOnly(_safeOwnerId) {
        require(_amount <= (getMinWithdrawLimit() - idToSafeOwner[_safeOwnerId].withdrawn), "amount exceeds limit");
        idToSafeOwner[_safeOwnerId].withdrawn += _amount;
        (bool sent, ) = idToSafeOwner[_safeOwnerId]._address.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function getMinWithdrawLimit() public view returns(uint) {
        uint256 min_ = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        for (uint256 i = 0; i < 3; i++) {
            if ( block.number < idToSafeOwner[i].lastActive + blocksToExpire && idToSafeOwner[i].withdrawLimit < min_ ) {
                min_ = idToSafeOwner[i].withdrawLimit;
            }
        }
        return min_;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

}