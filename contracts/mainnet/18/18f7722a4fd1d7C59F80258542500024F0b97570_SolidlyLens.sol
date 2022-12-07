// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBribe {
    function rewardsListLength() external view returns (uint256);

    function rewards(uint256) external view returns (address);

    function earned(address, uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISolid {
    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function router() external view returns (address);

    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISolidlyLens {
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

    struct PositionVe {
        uint256 tokenId;
        uint256 balanceOf;
        uint256 locked;
    }

    struct PositionBribesByTokenId {
        uint256 tokenId;
        PositionBribe[] bribes;
    }

    struct PositionBribe {
        address bribeTokenAddress;
        uint256 earned;
    }

    struct PositionPool {
        address id;
        uint256 balanceOf;
    }

    function poolsLength() external view returns (uint256);

    function voterAddress() external view returns (address);

    function veAddress() external view returns (address);

    function poolsFactoryAddress() external view returns (address);

    function gaugesFactoryAddress() external view returns (address);

    function minterAddress() external view returns (address);

    function solidAddress() external view returns (address);

    function vePositionsOf(address) external view returns (PositionVe[] memory);

    function bribeAddresByPoolAddress(address) external view returns (address);

    function gaugeAddressByPoolAddress(address) external view returns (address);

    function poolsPositionsOf(address)
        external
        view
        returns (PositionPool[] memory);

    function poolsPositionsOf(
        address,
        uint256,
        uint256
    ) external view returns (PositionPool[] memory);

    function poolInfo(address) external view returns (Pool memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface ISolidPool {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function fees() external view returns (address);

    function stable() external view returns (bool);

    function symbol() external view returns (string memory);

    function claimable0(address) external view returns (uint256);

    function claimable1(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function totalSupply() external view returns (uint256);

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function allowance(address, address) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVe {
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external;

    function ownerOf(uint256) external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function balanceOfNFT(uint256) external view returns (uint256);

    function balanceOfNFTAt(uint256, uint256) external view returns (uint256);

    function balanceOfAtNFT(uint256, uint256) external view returns (uint256);

    function locked(uint256) external view returns (uint256);

    function create_lock(uint256, uint256) external returns (uint256);

    function approve(address, uint256) external;

    function merge(uint256, uint256) external;

    function token() external view returns (address);

    function voter() external view returns (address);

    function voted(uint256) external view returns (bool);

    function tokenOfOwnerByIndex(address, uint256)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IVoter {
    function isWhitelisted(address) external view returns (bool);

    function length() external view returns (uint256);

    function pools(uint256) external view returns (address);

    function gauges(address) external view returns (address);

    function bribes(address) external view returns (address);

    function feeDists(address) external view returns (address);

    function factory() external view returns (address);

    function gaugeFactory() external view returns (address);

    function generalFees() external view returns (address);

    function vote(
        uint256,
        address[] memory,
        int256[] memory
    ) external;

    function whitelist(address, uint256) external;

    function updateFor(address[] memory _gauges) external;

    function claimRewards(address[] memory _gauges, address[][] memory _tokens)
        external;

    function distribute(address _gauge) external;

    function usedWeights(uint256) external returns (uint256);

    function reset(uint256 _tokenId) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

/**
 * @title Solidly+ Implementation
 * @author Solidly+
 * @notice Governable implementation that relies on governance slot to be set by the proxy
 */
contract SolidlyImplementation {
    bytes32 constant GOVERNANCE_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')
    bytes32 constant INITIALIZED_SLOT =
        0x834ce84547018237034401a09067277cdcbe7bbf7d7d30f6b382b0a102b7b4a3; // keccak256('eip1967.proxy.initialized')

    /**
     * @notice Reverts if msg.sender is not governance
     */
    modifier onlyGovernance() {
        require(msg.sender == governanceAddress(), "Only governance");
        _;
    }

    /**
     * @notice Reverts if contract is already initialized
     * @dev U4sed by implementations to ensure initialize() is only called once
     */
    modifier notInitialized() {
        bool initialized;
        assembly {
            initialized := sload(INITIALIZED_SLOT)
            if eq(initialized, 1) {
                revert(0, 0)
            }
        }
        _;
    }

    /**
     * @notice Fetch current governance address
     * @return _governanceAddress Returns current governance address
     */
    function governanceAddress()
        public
        view
        virtual
        returns (address _governanceAddress)
    {
        assembly {
            _governanceAddress := sload(GOVERNANCE_SLOT)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "./interfaces/ISolidlyLens.sol";
import "./interfaces/IVe.sol";
import "./interfaces/IBribe.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/ISolidPool.sol";
import "./interfaces/ISolid.sol";
import "./ProxyPattern/SolidlyImplementation.sol";

/**************************************************
 *                   Interfaces
 **************************************************/

interface IMinter {
    function _ve_dist() external view returns (address);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}

/**************************************************
 *                 Core contract
 **************************************************/
contract SolidlyLens is SolidlyImplementation {
    address public veAddress;
    address public routerAddress;
    address public deployerAddress;
    address public ownerAddress;
    address public libraryAddress;

    // Internal interfaces
    IVoter internal voter;
    IMinter internal minter;
    IVe internal ve;
    ISolid internal solid;

    /**************************************************
     *                   Structs
     **************************************************/
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
    }

    struct ProtocolMetadata {
        address veAddress;
        address solidAddress;
        address voterAddress;
        address poolsFactoryAddress;
        address gaugesFactoryAddress;
        address minterAddress;
    }

    /**************************************************
     *                   Configuration
     **************************************************/

    /**
     * @notice Initialize proxy storage
     */
    function initializeProxyStorage(
        address _veAddress,
        address _routerAddress,
        address _libraryAddress,
        address _deployerAddress
    ) public onlyGovernance notInitialized {
        veAddress = _veAddress;
        ownerAddress = msg.sender;
        routerAddress = _routerAddress;
        libraryAddress = _libraryAddress;
        deployerAddress = _deployerAddress;
        ve = IVe(veAddress);
        solid = ISolid(ve.token());
        voter = IVoter(ve.voter());
        minter = IMinter(solid.minter());
    }

    function setVeAddress(address _veAddress) external {
        require(msg.sender == ownerAddress, "Only owner");
        veAddress = _veAddress;
    }

    function setOwnerAddress(address _ownerAddress) external {
        require(msg.sender == ownerAddress, "Only owner");
        ownerAddress = _ownerAddress;
    }

    /**************************************************
     *                 Protocol addresses
     **************************************************/
    function voterAddress() public view returns (address) {
        return ve.voter();
    }

    function poolsFactoryAddress() public view returns (address) {
        return voter.factory();
    }

    function gaugesFactoryAddress() public view returns (address) {
        return voter.gaugeFactory();
    }

    function generalFeesAddress() public view returns (address) {
        return voter.generalFees();
    }

    function solidAddress() public view returns (address) {
        return ve.token();
    }

    function veDistAddress() public view returns (address) {
        return minter._ve_dist();
    }

    function minterAddress() public view returns (address) {
        return solid.minter();
    }

    /**************************************************
     *                  Protocol data
     **************************************************/
    function protocolMetadata()
        external
        view
        returns (ProtocolMetadata memory)
    {
        return
            ProtocolMetadata({
                veAddress: veAddress,
                voterAddress: voterAddress(),
                solidAddress: solidAddress(),
                poolsFactoryAddress: poolsFactoryAddress(),
                gaugesFactoryAddress: gaugesFactoryAddress(),
                minterAddress: minterAddress()
            });
    }

    function poolsLength() public view returns (uint256) {
        return voter.length();
    }

    function poolsAddresses() public view returns (address[] memory) {
        uint256 _poolsLength = poolsLength();
        address[] memory _poolsAddresses = new address[](_poolsLength);
        for (uint256 poolIndex; poolIndex < _poolsLength; poolIndex++) {
            address poolAddress = voter.pools(poolIndex);
            _poolsAddresses[poolIndex] = poolAddress;
        }
        return _poolsAddresses;
    }

    function poolInfo(address poolAddress)
        public
        view
        returns (ISolidlyLens.Pool memory)
    {
        ISolidPool pool = ISolidPool(poolAddress);
        address token0Address = pool.token0();
        address token1Address = pool.token1();
        address gaugeAddress = voter.gauges(poolAddress);
        address bribeAddress = voter.bribes(gaugeAddress);
        address feeDistAddress = voter.feeDists(poolAddress);
        address[]
            memory _bribeTokensAddresses = bribeTokensAddressesByBribeAddress(
                bribeAddress
            );
        uint256 totalSupply = pool.totalSupply();
        if (_bribeTokensAddresses.length < 2) {
            _bribeTokensAddresses = new address[](2);
            _bribeTokensAddresses[0] = token0Address;
            _bribeTokensAddresses[1] = token1Address;
        }
        return
            ISolidlyLens.Pool({
                id: poolAddress,
                symbol: pool.symbol(),
                stable: pool.stable(),
                token0Address: token0Address,
                token1Address: token1Address,
                gaugeAddress: gaugeAddress,
                bribeAddress: bribeAddress,
                bribeTokensAddresses: _bribeTokensAddresses,
                fees: pool.fees(),
                totalSupply: totalSupply,
                feeDistAddress: feeDistAddress
            });
    }

    function poolsInfo() external view returns (ISolidlyLens.Pool[] memory) {
        address[] memory _poolsAddresses = poolsAddresses();
        ISolidlyLens.Pool[] memory pools = new ISolidlyLens.Pool[](
            _poolsAddresses.length
        );
        for (
            uint256 poolIndex;
            poolIndex < _poolsAddresses.length;
            poolIndex++
        ) {
            address poolAddress = _poolsAddresses[poolIndex];
            ISolidlyLens.Pool memory _poolInfo = poolInfo(poolAddress);
            pools[poolIndex] = _poolInfo;
        }
        return pools;
    }

    function poolReservesInfo(address poolAddress)
        public
        view
        returns (ISolidlyLens.PoolReserveData memory)
    {
        ISolidPool pool = ISolidPool(poolAddress);
        address token0Address = pool.token0();
        address token1Address = pool.token1();
        (uint256 token0Reserve, uint256 token1Reserve, ) = pool.getReserves();
        uint8 token0Decimals = IERC20(token0Address).decimals();
        uint8 token1Decimals = IERC20(token1Address).decimals();
        return
            ISolidlyLens.PoolReserveData({
                id: poolAddress,
                token0Address: token0Address,
                token1Address: token1Address,
                token0Reserve: token0Reserve,
                token1Reserve: token1Reserve,
                token0Decimals: token0Decimals,
                token1Decimals: token1Decimals
            });
    }

    function poolsReservesInfo(address[] memory _poolsAddresses)
        external
        view
        returns (ISolidlyLens.PoolReserveData[] memory)
    {
        ISolidlyLens.PoolReserveData[]
            memory _poolsReservesInfo = new ISolidlyLens.PoolReserveData[](
                _poolsAddresses.length
            );
        for (
            uint256 poolIndex;
            poolIndex < _poolsAddresses.length;
            poolIndex++
        ) {
            address poolAddress = _poolsAddresses[poolIndex];
            _poolsReservesInfo[poolIndex] = poolReservesInfo(poolAddress);
        }
        return _poolsReservesInfo;
    }

    function gaugesAddresses() public view returns (address[] memory) {
        address[] memory _poolsAddresses = poolsAddresses();
        address[] memory _gaugesAddresses = new address[](
            _poolsAddresses.length
        );
        for (
            uint256 poolIndex;
            poolIndex < _poolsAddresses.length;
            poolIndex++
        ) {
            address poolAddress = _poolsAddresses[poolIndex];
            address gaugeAddress = voter.gauges(poolAddress);
            _gaugesAddresses[poolIndex] = gaugeAddress;
        }
        return _gaugesAddresses;
    }

    function bribesAddresses() public view returns (address[] memory) {
        address[] memory _gaugesAddresses = gaugesAddresses();
        address[] memory _bribesAddresses = new address[](
            _gaugesAddresses.length
        );
        for (uint256 gaugeIdx; gaugeIdx < _gaugesAddresses.length; gaugeIdx++) {
            address gaugeAddress = _gaugesAddresses[gaugeIdx];
            address bribeAddress = voter.bribes(gaugeAddress);
            _bribesAddresses[gaugeIdx] = bribeAddress;
        }
        return _bribesAddresses;
    }

    function bribeTokensAddressesByBribeAddress(address bribeAddress)
        public
        view
        returns (address[] memory)
    {
        uint256 bribeTokensLength = IBribe(bribeAddress).rewardsListLength();
        address[] memory _bribeTokensAddresses = new address[](
            bribeTokensLength
        );
        for (
            uint256 bribeTokenIdx;
            bribeTokenIdx < bribeTokensLength;
            bribeTokenIdx++
        ) {
            address bribeTokenAddress = IBribe(bribeAddress).rewards(
                bribeTokenIdx
            );
            _bribeTokensAddresses[bribeTokenIdx] = bribeTokenAddress;
        }
        return _bribeTokensAddresses;
    }

    function poolsPositionsOf(
        address accountAddress,
        uint256 startIndex,
        uint256 endIndex
    ) public view returns (ISolidlyLens.PositionPool[] memory) {
        uint256 _poolsLength = poolsLength();
        ISolidlyLens.PositionPool[]
            memory _poolsPositionsOf = new ISolidlyLens.PositionPool[](
                _poolsLength
            );
        uint256 positionsLength;
        if (_poolsLength < endIndex) endIndex = _poolsLength;
        for (
            uint256 poolIndex = startIndex;
            poolIndex < endIndex;
            poolIndex++
        ) {
            address poolAddress = voter.pools(poolIndex);
            uint256 balanceOf = ISolidPool(poolAddress).balanceOf(
                accountAddress
            );
            if (balanceOf > 0) {
                _poolsPositionsOf[positionsLength] = ISolidlyLens.PositionPool({
                    id: poolAddress,
                    balanceOf: balanceOf
                });
                positionsLength++;
            }
        }

        bytes memory encodedPositions = abi.encode(_poolsPositionsOf);
        assembly {
            mstore(add(encodedPositions, 0x40), positionsLength)
        }
        return abi.decode(encodedPositions, (ISolidlyLens.PositionPool[]));
    }

    function poolsPositionsOf(address accountAddress)
        public
        view
        returns (ISolidlyLens.PositionPool[] memory)
    {
        uint256 _poolsLength = poolsLength();
        ISolidlyLens.PositionPool[]
            memory _poolsPositionsOf = new ISolidlyLens.PositionPool[](
                _poolsLength
            );

        uint256 positionsLength;

        for (uint256 poolIndex; poolIndex < _poolsLength; poolIndex++) {
            address poolAddress = voter.pools(poolIndex);
            uint256 balanceOf = ISolidPool(poolAddress).balanceOf(
                accountAddress
            );
            if (balanceOf > 0) {
                _poolsPositionsOf[positionsLength] = ISolidlyLens.PositionPool({
                    id: poolAddress,
                    balanceOf: balanceOf
                });
                positionsLength++;
            }
        }

        bytes memory encodedPositions = abi.encode(_poolsPositionsOf);
        assembly {
            mstore(add(encodedPositions, 0x40), positionsLength)
        }
        return abi.decode(encodedPositions, (ISolidlyLens.PositionPool[]));
    }

    function veTokensIdsOf(address accountAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256 veBalanceOf = ve.balanceOf(accountAddress);
        uint256[] memory _veTokensOf = new uint256[](veBalanceOf);

        for (uint256 tokenIdx; tokenIdx < veBalanceOf; tokenIdx++) {
            uint256 tokenId = ve.tokenOfOwnerByIndex(accountAddress, tokenIdx);
            _veTokensOf[tokenIdx] = tokenId;
        }
        return _veTokensOf;
    }

    function gaugeAddressByPoolAddress(address poolAddress)
        external
        view
        returns (address)
    {
        return voter.gauges(poolAddress);
    }

    function bribeAddresByPoolAddress(address poolAddress)
        public
        view
        returns (address)
    {
        address gaugeAddress = voter.gauges(poolAddress);
        address bribeAddress = voter.bribes(gaugeAddress);
        return bribeAddress;
    }

    function feeDistAddressByPoolAddress(address poolAddress)
        external
        view
        returns (address)
    {
        return voter.feeDists(poolAddress);
    }

    function bribeTokensAddressesByPoolAddress(address poolAddress)
        public
        view
        returns (address[] memory)
    {
        address bribeAddress = bribeAddresByPoolAddress(poolAddress);
        return bribeTokensAddressesByBribeAddress(bribeAddress);
    }

    function bribesPositionsOf(
        address accountAddress,
        address poolAddress,
        uint256 tokenId
    ) public view returns (ISolidlyLens.PositionBribe[] memory) {
        address bribeAddress = bribeAddresByPoolAddress(poolAddress);
        address[]
            memory bribeTokensAddresses = bribeTokensAddressesByBribeAddress(
                bribeAddress
            );
        ISolidlyLens.PositionBribe[]
            memory _bribesPositionsOf = new ISolidlyLens.PositionBribe[](
                bribeTokensAddresses.length
            );
        uint256 currentIdx;
        for (
            uint256 bribeTokenIdx;
            bribeTokenIdx < bribeTokensAddresses.length;
            bribeTokenIdx++
        ) {
            address bribeTokenAddress = bribeTokensAddresses[bribeTokenIdx];
            uint256 earned = IBribe(bribeAddress).earned(
                bribeTokenAddress,
                tokenId
            );
            if (earned > 0) {
                _bribesPositionsOf[currentIdx] = ISolidlyLens.PositionBribe({
                    bribeTokenAddress: bribeTokenAddress,
                    earned: earned
                });
                currentIdx++;
            }
        }
        bytes memory encodedBribes = abi.encode(_bribesPositionsOf);
        assembly {
            mstore(add(encodedBribes, 0x40), currentIdx)
        }
        ISolidlyLens.PositionBribe[] memory filteredBribes = abi.decode(
            encodedBribes,
            (ISolidlyLens.PositionBribe[])
        );
        return filteredBribes;
    }

    function bribesPositionsOf(address accountAddress, address poolAddress)
        public
        view
        returns (ISolidlyLens.PositionBribesByTokenId[] memory)
    {
        address bribeAddress = bribeAddresByPoolAddress(poolAddress);
        address[]
            memory bribeTokensAddresses = bribeTokensAddressesByBribeAddress(
                bribeAddress
            );

        uint256[] memory veTokensIds = veTokensIdsOf(accountAddress);
        ISolidlyLens.PositionBribesByTokenId[]
            memory _bribePositionsOf = new ISolidlyLens.PositionBribesByTokenId[](
                veTokensIds.length
            );

        uint256 currentIdx;
        for (
            uint256 veTokenIdIdx;
            veTokenIdIdx < veTokensIds.length;
            veTokenIdIdx++
        ) {
            uint256 tokenId = veTokensIds[veTokenIdIdx];
            _bribePositionsOf[currentIdx] = ISolidlyLens
                .PositionBribesByTokenId({
                    tokenId: tokenId,
                    bribes: bribesPositionsOf(
                        accountAddress,
                        poolAddress,
                        tokenId
                    )
                });
            currentIdx++;
        }
        return _bribePositionsOf;
    }

    function vePositionsOf(address accountAddress)
        public
        view
        returns (ISolidlyLens.PositionVe[] memory)
    {
        uint256 veBalanceOf = ve.balanceOf(accountAddress);
        ISolidlyLens.PositionVe[]
            memory _vePositionsOf = new ISolidlyLens.PositionVe[](veBalanceOf);

        for (uint256 tokenIdx; tokenIdx < veBalanceOf; tokenIdx++) {
            uint256 tokenId = ve.tokenOfOwnerByIndex(accountAddress, tokenIdx);
            uint256 balanceOf = ve.balanceOfNFT(tokenId);
            uint256 locked = ve.locked(tokenId);
            _vePositionsOf[tokenIdx] = ISolidlyLens.PositionVe({
                tokenId: tokenId,
                balanceOf: balanceOf,
                locked: locked
            });
        }
        return _vePositionsOf;
    }
}