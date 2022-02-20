pragma solidity ^0.5.16;

contract blankRewardsDistributorDelegate {

    bool public constant isRewardsDistributor = true;

    function flywheelPreSupplierAction(address market, address supplier) external {}

    function flywheelPreBorrowerAction(address market, address borrower) external {}

    function flywheelPreTransferAction(address market, address src, address dst) external {}
}