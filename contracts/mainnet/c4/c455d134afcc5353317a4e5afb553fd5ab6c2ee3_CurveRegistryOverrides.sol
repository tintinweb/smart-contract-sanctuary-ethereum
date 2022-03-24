/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

contract Ownable {
    address public ownerAddress;

    constructor() {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Ownable: caller is not the owner");
        _;
    }

    function setOwnerAddress(address _ownerAddress) public onlyOwner {
        ownerAddress = _ownerAddress;
    }
}

interface ICurveRegistry {
    function get_pool_from_lp_token(address) external view returns (address);
}

contract CurveRegistryOverrides is Ownable {
    address[] public curveRegistries;
    mapping(address => address) public poolByLpOverride;

    /// @notice Sets the registries this contract will search when running poolByLp
    /// @dev Registries added must have .get_pool_from_lp_token method
    function setCurveRegistries(address[] memory _curveRegistries)
        public
        onlyOwner
    {
        curveRegistries = _curveRegistries;
    }

    /// @notice Returns all curve registries that have been set
    function curveRegistriesList() public view returns (address[] memory) {
        return curveRegistries;
    }

    /// @notice Adds an override pool address for an LP
    /// @dev Maintains an additional pool address list for indexing
    function setPoolForLp(address _poolAddress, address _lpAddress)
        public
        onlyOwner
    {
        poolByLpOverride[_lpAddress] = _poolAddress;
    }

    /// @notice Search through pool registry overrides and curve registries for a LP Pool
    function poolByLp(address _lpAddress) public view returns (address) {
        address pool = poolByLpOverride[_lpAddress];
        if (pool != address(0)) {
            return pool;
        }
        for (uint256 i; i < curveRegistries.length; i++) {
            pool = ICurveRegistry(curveRegistries[i]).get_pool_from_lp_token(
                _lpAddress
            );
            if (pool != address(0)) {
                return pool;
            }
        }
        return address(0);
    }
}