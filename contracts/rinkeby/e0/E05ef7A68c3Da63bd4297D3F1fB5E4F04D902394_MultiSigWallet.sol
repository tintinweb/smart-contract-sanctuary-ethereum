// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./AddNewToken.sol";
import "./GoldenOwner.sol";
import "./Limits.sol";
import "./OwnerFunctions.sol";
import "./Transactions.sol";
import "./View.sol";
import "./WhiteList.sol";

contract MultiSigWallet is variables, Transactions, AddNewToken, GoldenOwner, Limits, OwnerFunctions, ViewFunctions, WhiteLists {
    //CONSTRUCTOR
    function initialize(address _owners) public {
        require(_owners != address(0) && owners.length == 0);
        isOwner[_owners] = OwnerStatus.OWNER;
        userInfo[_owners].limit = 1 ether;
        reservedBalances["eth"] = 0;
        numTransactions = 0;
        owners.push(_owners);
    }

    receive() external payable {}
}