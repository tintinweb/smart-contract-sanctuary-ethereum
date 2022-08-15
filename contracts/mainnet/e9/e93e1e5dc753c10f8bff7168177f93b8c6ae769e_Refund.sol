// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IOld {
    function getTokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

contract Refund is Ownable {
    uint256 public mintPrice;
    uint16 public BUYER_COUNT;
    address public banditAddress;
    mapping(uint8 => bool) public claimedFrom;

    constructor() {
        BUYER_COUNT = 647;
        mintPrice = 0.025 ether;
    }

    function setContractAddress(address _banditAddress) external onlyOwner {
        banditAddress = _banditAddress;
    }

    function setFreeCount(uint16 _buyer_count) external onlyOwner {
        BUYER_COUNT = _buyer_count;
    }

    function setClaimable(uint8[] memory _ids, bool status) external onlyOwner {
        require(_ids.length > 0, "Empty List");
        for (uint8 i = 0; i < _ids.length; i++) {
            claimedFrom[_ids[i]] = status;
        }
    }

    function getAvailableCount(address owner) public view returns (uint256) {
        uint256[] memory tokenIds = IOld(banditAddress).getTokensOfOwner(owner);

        uint256 availableCount;
        for (uint8 i; i < tokenIds.length; i++) {
            if (tokenIds[i] < BUYER_COUNT && !claimedFrom[uint8(tokenIds[i])]) {
                availableCount++;
            }
        }

        return availableCount;
    }

    function claim() external {
        require(tx.origin == msg.sender, "Only EOA");

        uint8 _numberOfTokens = uint8(getAvailableCount(msg.sender));
        uint256 totalBalance = address(this).balance;
        uint256 refundBalance = mintPrice * _numberOfTokens;
        require(totalBalance >= refundBalance, "Not Enough Fund");

        uint256[] memory tokenIds = IOld(banditAddress).getTokensOfOwner(
            msg.sender
        );

        for (uint8 i = 0; i < _numberOfTokens; i++) {
            claimedFrom[uint8(tokenIds[i])] = true;
        }

        payable(msg.sender).transfer(refundBalance);
    }

    function emergencyWithdrawAll() external onlyOwner {
        uint256 totalBalance = address(this).balance;
        payable(msg.sender).transfer(totalBalance);
    }

    receive() external payable {}
}