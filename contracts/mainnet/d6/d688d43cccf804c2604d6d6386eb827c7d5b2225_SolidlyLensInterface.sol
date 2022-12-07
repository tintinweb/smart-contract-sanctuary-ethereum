// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

contract SolidlyLensInterface {
    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    struct PositionBribesByTokenId {
        uint256 tokenId;
        PositionPool[] bribes;
    }

    struct Pool {
        address id;
        string symbol;
        bool stable;
        address token0Address;
        address token1Address;
        address gaugeAddress;
        address bribeAddress;
        address[] bribeTokensAddresses;
        address fees;
        uint256 totalSupply;
        address feeDistAddress;
    }

    struct PoolReserveData {
        address id;
        address token0Address;
        address token1Address;
        uint256 token0Reserve;
        uint256 token1Reserve;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    struct ProtocolMetadata {
        address veAddress;
        address solidAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
    }

    struct PositionVe {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    function bribeAddresByPoolAddress(address poolAddress)
        external
        view
        returns (address)
    {}

    function bribeTokensAddressesByBribeAddress(address bribeAddress)
        external
        view
        returns (address[] memory)
    {}

    function bribeTokensAddressesByPoolAddress(address poolAddress)
        external
        view
        returns (address[] memory)
    {}

    function bribesAddresses() external view returns (address[] memory) {}

    function bribesPositionsOf(
        address accountAddress,
        address poolAddress,
        uint256 tokenId
    ) external view returns (PositionPool[] memory) {}

    function bribesPositionsOf(address accountAddress, address poolAddress)
        external
        view
        returns (PositionBribesByTokenId[] memory)
    {}

    function deployerAddress() external view returns (address) {}

    function feeDistAddressByPoolAddress(address poolAddress)
        external
        view
        returns (address)
    {}

    function gaugeAddressByPoolAddress(address poolAddress)
        external
        view
        returns (address)
    {}

    function gaugesAddresses() external view returns (address[] memory) {}

    function gaugesFactoryAddress() external view returns (address) {}

    function initializeProxyStorage(
        address _veAddress,
        address _routerAddress,
        address _libraryAddress,
        address _deployerAddress
    ) external {}

    function libraryAddress() external view returns (address) {}

    function minterAddress() external view returns (address) {}

    function ownerAddress() external view returns (address) {}

    function poolInfo(address poolAddress)
        external
        view
        returns (Pool memory)
    {}

    function poolReservesInfo(address poolAddress)
        external
        view
        returns (PoolReserveData memory)
    {}

    function poolsAddresses() external view returns (address[] memory) {}

    function poolsFactoryAddress() external view returns (address) {}

    function poolsInfo() external view returns (Pool[] memory) {}

    function poolsLength() external view returns (uint256) {}

    function poolsPositionsOf(address accountAddress)
        external
        view
        returns (PositionPool[] memory)
    {}

    function poolsPositionsOf(
        address accountAddress,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (PositionPool[] memory) {}

    function poolsReservesInfo(address[] memory _poolsAddresses)
        external
        view
        returns (PoolReserveData[] memory)
    {}

    function protocolMetadata()
        external
        view
        returns (ProtocolMetadata memory)
    {}

    function proxyStorageInitialized() external view returns (bool) {}

    function routerAddress() external view returns (address) {}

    function setOwnerAddress(address _ownerAddress) external {}

    function setVeAddress(address _veAddress) external {}

    function solidAddress() external view returns (address) {}

    function veAddress() external view returns (address) {}

    function veDistAddress() external view returns (address) {}

    function vePositionsOf(address accountAddress)
        external
        view
        returns (PositionVe[] memory)
    {}

    function veTokensIdsOf(address accountAddress)
        external
        view
        returns (uint256[] memory)
    {}

    function voterAddress() external view returns (address) {}
}