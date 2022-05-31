pragma solidity 0.6.12;

contract MockUmeeOracl {
    address[] addresses = [address(this)];

    function getReservesList() external view returns (address[] memory) {
        return addresses;
    }

    function getSourceOfAsset(address asset) external view returns (address) {
        return address(this);
    }

    function latestTimestamp() external view returns (uint256) {
        return 1;
    }
}