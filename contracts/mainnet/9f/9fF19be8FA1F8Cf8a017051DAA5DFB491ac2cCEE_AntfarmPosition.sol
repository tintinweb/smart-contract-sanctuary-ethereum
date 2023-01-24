// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "../interfaces/IAntfarmPair.sol";
import "../interfaces/IAntfarmPosition.sol";
import "../interfaces/IAntfarmFactory.sol";
import "../interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";
import "../utils/AntfarmPositionErrors.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title NFT positions
/// @notice Wraps Antfarm positions in ERC721
contract AntfarmPosition is IAntfarmPosition, ERC721Enumerable {
    address public immutable factory;
    address public immutable WETH;
    address public immutable antfarmToken;

    using Counters for Counters.Counter;
    Counters.Counter private _positionIds;

    mapping(uint256 => Position) public positions;

    modifier ensure(uint256 deadline) {
        if (deadline < block.timestamp) revert Expired();
        _;
    }

    modifier isOwner(uint256 positionId) {
        // ownerOf will revert if positionId isn't a position owned
        if (msg.sender != ownerOf(positionId)) revert NotOwner();
        _;
    }

    modifier isOwnerOrAllowed(uint256 positionId) {
        // check if sender is owner or delegate, used to claim dividends
        if (
            msg.sender != ownerOf(positionId) &&
            msg.sender != positions[positionId].delegate
        ) revert NotAllowed();
        _;
    }

    constructor(
        address _factory,
        address _WETH,
        address _antfarmToken
    ) ERC721("Antfarm Positions", "ANTPOS") {
        require(_factory != address(0), "NULL_FACTORY_ADDRESS");
        require(_WETH != address(0), "NULL_WETH_ADDRESS");
        require(_antfarmToken != address(0), "NULL_ATF_ADDRESS");
        factory = _factory;
        WETH = _WETH;
        antfarmToken = _antfarmToken;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    /// @notice Create a position in an AntFarmPair. Create an NFT for this position
    /// @param tokenA Token of the AntfarmPair
    /// @param tokenB Token of the AntfarmPair
    /// @param fee Associated fee to the AntFarmPair
    /// @param amountADesired tokenA amount to be added as liquidity
    /// @param amountBDesired tokenB amount to be added as liquidity
    /// @param amountAMin Minimum tokenA amount to be added as liquidity
    /// @param amountBMin Minimum tokenB amount to be added as liquidity
    /// @param to The address to be used to mint the NFT position
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountA tokenA amount added to the AntfarmPair as liquidity
    /// @return amountB tokenB amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function createPosition(
        address tokenA,
        address tokenB,
        uint16 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        address pair = pairFor(tokenA, tokenB, fee);
        _positionIds.increment();
        positions[_positionIds.current()] = Position(
            pair,
            address(0),
            false,
            0,
            0
        );

        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            fee,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        liquidity = IAntfarmPair(pair).mint(
            address(this),
            _positionIds.current()
        );

        _safeMint(to, _positionIds.current());
        emit Create(
            to,
            _positionIds.current(),
            pair,
            amountA,
            amountB,
            liquidity
        );
    }

    /// @notice Create a position in an AntFarmPair using WETH. Create an NFT for this position
    /// @param token Token of the AntfarmPair
    /// @param fee associated fee to the AntFarmPair
    /// @param amountTokenDesired token amount to be added as liquidity
    /// @param amountTokenMin Minimum token amount to be added as liquidity
    /// @param amountETHMin Minimum ETH amount to be added as liquidity
    /// @param to The address to be used to mint the NFT position
    /// @param deadline Unix timestamp after which the transaction will revert
    /// @return amountToken token amount added to the AntfarmPair as liquidity
    /// @return amountETH ETH amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function createPositionETH(
        address token,
        uint16 fee,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        virtual
        ensure(deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        _positionIds.increment();
        address pair = pairFor(token, WETH, fee);
        positions[_positionIds.current()] = Position(
            pair,
            address(0),
            false,
            0,
            0
        );

        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            fee,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );

        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        liquidity = IAntfarmPair(pair).mint(
            address(this),
            _positionIds.current()
        );

        _safeMint(to, _positionIds.current());

        // refund dust ETH, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);

        emit Create(
            to,
            _positionIds.current(),
            pair,
            amountToken,
            amountETH,
            liquidity
        );
    }

    /// @notice Increase liquidity for an existing position
    /// @param params Predefined parameters struct
    // @param tokenA Base token from the AntfarmPair
    // @param tokenB Quote token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param amountADesired tokenA amount to be added as liquidity
    // @param amountBDesired tokenB amount to be added as liquidity
    // @param amountAMin Minimum tokenA amount to be added as liquidity
    // @param amountBMin Minimum tokenB amount to be added as liquidity
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId position ID
    /// @return amountA tokenA amount added to the AntfarmPair as liquidity
    /// @return amountB tokenB amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function increasePosition(IncreasePositionParams calldata params)
        external
        virtual
        isOwnerOrAllowed(params.positionId)
        ensure(params.deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            params.tokenA,
            params.tokenB,
            params.fee,
            params.amountADesired,
            params.amountBDesired,
            params.amountAMin,
            params.amountBMin
        );

        address pair = pairFor(params.tokenA, params.tokenB, params.fee);

        TransferHelper.safeTransferFrom(
            params.tokenA,
            msg.sender,
            pair,
            amountA
        );
        TransferHelper.safeTransferFrom(
            params.tokenB,
            msg.sender,
            pair,
            amountB
        );

        liquidity = IAntfarmPair(pair).mint(address(this), params.positionId);

        emit Increase(
            ownerOf(params.positionId),
            params.positionId,
            pair,
            amountA,
            amountB,
            liquidity
        );
    }

    /// @notice Increase liquidity for an existing position for an ETH Antfarmpair
    /// @param params Predefined parameters struct
    // @param token Token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param amountTokenDesired Token amount to be added as liquidity
    // @param amountTokenMin Minimum token amount to be added as liquidity
    // @param amountETHMin Minimum ETH amount to be added as liquidity
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId Position ID
    /// @return amountToken Token amount added to the AntfarmPair as liquidity
    /// @return amountETH ETH amount added to the AntfarmPair as liquidity
    /// @return liquidity Liquidity minted
    function increasePositionETH(IncreasePositionETHParams calldata params)
        external
        payable
        virtual
        isOwnerOrAllowed(params.positionId)
        ensure(params.deadline)
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        (amountToken, amountETH) = _addLiquidity(
            params.token,
            WETH,
            params.fee,
            params.amountTokenDesired,
            msg.value,
            params.amountTokenMin,
            params.amountETHMin
        );

        address pair = pairFor(params.token, WETH, params.fee);

        TransferHelper.safeTransferFrom(
            params.token,
            msg.sender,
            pair,
            amountToken
        );
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));

        liquidity = IAntfarmPair(pair).mint(address(this), params.positionId);
        // refund dust ETH, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);

        emit Increase(
            ownerOf(params.positionId),
            params.positionId,
            pair,
            amountToken,
            amountETH,
            liquidity
        );
    }

    /// @notice Enable lock option for a position
    /// @param positionId Position ID to enable lock
    /// @param deadline Unix timestamp after which the transaction will revert
    function enableLock(uint256 positionId, uint256 deadline)
        external
        virtual
        isOwner(positionId)
        ensure(deadline)
    {
        if (positions[positionId].enableLock) revert AlreadyAllowed();
        positions[positionId].enableLock = true;
    }

    /// @notice Disable lock option for a position
    /// @param positionId Position ID to enable lock
    /// @param deadline Unix timestamp after which the transaction will revert
    function disableLock(uint256 positionId, uint256 deadline)
        external
        virtual
        isOwner(positionId)
        ensure(deadline)
    {
        if (!positions[positionId].enableLock) revert AlreadyDisallowed();
        if (positions[positionId].lock > block.timestamp) {
            revert LockedLiquidity();
        }
        positions[positionId].enableLock = false;
    }

    /// @notice Lock a position for a custom period
    /// @param locktime Timestamp until liquidity is locked
    /// @param positionId Position ID to enable lock
    /// @param deadline Unix timestamp after which the transaction will revert
    function lockPosition(
        uint32 locktime,
        uint256 positionId,
        uint256 deadline
    ) external virtual isOwner(positionId) ensure(deadline) {
        if (!positions[positionId].enableLock) revert LockNotAllowed();
        if (
            locktime <= block.timestamp ||
            locktime <= positions[positionId].lock
        ) revert WrongLocktime();
        positions[positionId].lock = locktime;

        emit Lock(msg.sender, positionId, positions[positionId].pair, locktime);
    }

    /// @notice Burn a position NFT if it has no liquidity nor claimable dividends
    /// @param positionId Owner postion ID to burn
    function burn(uint256 positionId) external isOwner(positionId) {
        IAntfarmPair pair = IAntfarmPair(positions[positionId].pair);
        if (pair.getPositionLP(address(this), positionId) != 0) {
            revert LiquidityToClaim();
        }
        if (pair.claimableDividends(address(this), positionId) != 0) {
            revert DividendsToClaim();
        }
        emit Burn(msg.sender, positionId);
        _burn(positionId);
    }

    /// @notice Claim dividends for multiple positions
    /// @param positionIds Owner position IDs array to claim
    /// @return claimedAmount Claimed amount from positions given
    function claimDividendGrouped(uint256[] calldata positionIds)
        external
        returns (uint256 claimedAmount)
    {
        uint256 positionsLength = positionIds.length;
        for (uint256 i; i < positionsLength; ++i) {
            claimedAmount = claimedAmount + claimDividend(positionIds[i]);
        }
    }

    function setDelegate(uint256 positionId, address delegate)
        public
        isOwner(positionId)
    {
        positions[positionId].delegate = delegate;
    }

    function setDelegates(uint256[] calldata positionIds, address delegate)
        external
    {
        uint256 numPositions = positionIds.length;

        for (uint256 i; i < numPositions; ++i) {
            setDelegate(positionIds[i], delegate);
        }
    }

    function getPositionsDetails(uint256[] calldata positionIds)
        external
        view
        returns (PositionDetails[] memory)
    {
        PositionDetails[] memory positionsDetails = new PositionDetails[](
            positionIds.length
        );
        for (uint256 i; i < positionIds.length; ++i) {
            positionsDetails[i] = getPositionDetails(positionIds[i]);
        }

        return positionsDetails;
    }

    function getPositionDetails(uint256 positionId)
        public
        view
        returns (PositionDetails memory positionDetails)
    {
        Position memory position = positions[positionId];
        IAntfarmPair pair = IAntfarmPair(position.pair);

        uint256 lp = pair.getPositionLP(address(this), positionId);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        uint256 positionReserve0 = (lp * reserve0) / pair.totalSupply();
        uint256 positionReserve1 = (lp * reserve1) / pair.totalSupply();

        positionDetails = PositionDetails(
            positionId, // uint256 id;
            ownerOf(positionId), // address owner;
            position.delegate, // address delegate;
            position.pair, // address pair;
            pair.token0(), // address token0;
            pair.token1(), // address token1;
            lp, // uint256 lp;
            positionReserve0, // uint256 reserve0;
            positionReserve1, // uint256 reserve1;
            getDividend(positionId), // uint256 dividend;
            position.claimedAmount, // uint256 cumulatedDividend;
            pair.fee(), // uint16 fee;
            position.enableLock, // bool enableLock;
            position.lock // uint32 lock;
        );
    }

    /// @notice Get dividend for each position given
    /// @param owner Positions's owner
    /// @return uint[] Positions IDs
    /// @return uint[] Dividends
    function getDividendPerPosition(address owner)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory positionIds = getPositionsIds(owner);
        uint256[] memory dividends = new uint256[](positionIds.length);

        uint256 positionsLength = positionIds.length;
        for (uint256 i; i < positionsLength; ++i) {
            dividends[i] = getDividend(positionIds[i]);
        }

        return (positionIds, dividends);
    }

    /// @notice Decrease LP for a position
    /// @param params Predefined parameters struct
    // @param tokenA Base token from the AntfarmPair
    // @param tokenB Quote token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param liquidity Liquidity to be burned
    // @param amountAMin Minimum tokenA amount to be withdrawn from the position
    // @param amountBMin Minimum tokenB amount to be withdrawn from the position
    // @param to Address owner associated to the position
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId Position ID
    /// @return amountA tokenA amount received
    /// @return amountB tokenB amount received
    function decreasePosition(DecreasePositionParams calldata params)
        external
        virtual
        isOwner(params.positionId)
        ensure(params.deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        if (block.timestamp <= positions[params.positionId].lock) {
            revert LockedLiquidity();
        }

        (uint256 amount0, uint256 amount1) = IAntfarmPair(
            pairFor(params.tokenA, params.tokenB, params.fee)
        ).burn(params.to, params.positionId, params.liquidity);
        (address token0, ) = sortTokens(params.tokenA, params.tokenB);
        (amountA, amountB) = params.tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        if (amountA < params.amountAMin) revert InsufficientAAmount();
        if (amountB < params.amountBMin) revert InsufficientBAmount();

        emit Decrease(
            msg.sender,
            params.positionId,
            positions[params.positionId].pair,
            amountA,
            amountB,
            params.liquidity
        );
    }

    /// @notice Decrease LP for a position in an AntFarmPair with ETH
    /// @param params Predefined parameters struct
    // @param token Token from the AntfarmPair
    // @param fee Associated fee to the AntFarmPair
    // @param liquidity Liquidity to be burned
    // @param amountTokenMin Minimum token amount to be withdrawn from the position
    // @param amountETHMin Minimum ETH amount to be withdrawn from the position
    // @param to Address owner associated to the position
    // @param deadline Unix timestamp after which the transaction will revert
    // @param positionId Position ID
    /// @return amountToken Token amount received
    /// @return amountETH ETH amount received
    function decreasePositionETH(DecreasePositionETHParams calldata params)
        external
        isOwner(params.positionId)
        ensure(params.deadline)
        returns (uint256 amountToken, uint256 amountETH)
    {
        if (block.timestamp <= positions[params.positionId].lock) {
            revert LockedLiquidity();
        }

        (uint256 amount0, uint256 amount1) = IAntfarmPair(
            pairFor(params.token, WETH, params.fee)
        ).burn(address(this), params.positionId, params.liquidity);
        (address token0, ) = sortTokens(params.token, WETH);
        (amountToken, amountETH) = params.token == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        if (amountToken < params.amountTokenMin) revert InsufficientAAmount();
        if (amountETH < params.amountETHMin) revert InsufficientBAmount();

        TransferHelper.safeTransfer(params.token, params.to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(params.to, amountETH);

        emit Decrease(
            msg.sender,
            params.positionId,
            positions[params.positionId].pair,
            amountToken,
            amountETH,
            params.liquidity
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://metadata.antfarm.finance/positions/metadata/";
    }

    /// @notice Claim dividend for a position
    /// @param positionId Position ID to claim
    /// @return claimedAmount Dividend amount claimed
    function claimDividend(uint256 positionId)
        public
        isOwnerOrAllowed(positionId)
        returns (uint256 claimedAmount)
    {
        IAntfarmPair pair = IAntfarmPair(positions[positionId].pair);
        positions[positionId].claimedAmount += pair.claimableDividends(
            address(this),
            positionId
        );
        claimedAmount = pair.claimDividend(msg.sender, positionId);
        emit Claim(
            ownerOf(positionId),
            positionId,
            positions[positionId].pair,
            claimedAmount
        );
    }

    /// @notice Get all position IDs for an address
    /// @param owner Owner address
    /// @return positionIds Position IDs array associated with the owner address
    function getPositionsIds(address owner)
        public
        view
        returns (uint256[] memory positionIds)
    {
        uint256 balance = balanceOf(owner);
        positionIds = new uint256[](balance);

        for (uint256 i; i < balance; ++i) {
            positionIds[i] = tokenOfOwnerByIndex(owner, i);
        }
    }

    // ADD LIQUIDITY
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint16 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        // create pair if it doesn't exist
        if (
            IAntfarmFactory(factory).getPair(tokenA, tokenB, fee) == address(0)
        ) {
            IAntfarmFactory(factory).createPair(tokenA, tokenB, fee);
        }
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB, fee);
        if (reserveA == 0 && reserveB == 0) {
            // pool is a new one
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @notice Get the dividend of a single position
    /// @param positionId Position ID
    /// @return dividend Dividends owed
    function getDividend(uint256 positionId)
        internal
        view
        returns (uint256 dividend)
    {
        IAntfarmPair pair = IAntfarmPair(positions[positionId].pair);
        dividend = pair.claimableDividends(address(this), positionId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 positionId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, positionId);
        positions[positionId].delegate = address(0);
    }

    // **** LIBRARY FUNCTIONS ADDED INTO THE CONTRACT ****
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        view
        returns (address token0, address token1)
    {
        if (tokenA == tokenB) revert IdenticalAddresses();
        if (tokenA == antfarmToken || tokenB == antfarmToken) {
            (token0, token1) = tokenA == antfarmToken
                ? (antfarmToken, tokenB)
                : (antfarmToken, tokenA);
            if (token1 == address(0)) revert ZeroAddress();
        } else {
            (token0, token1) = tokenA < tokenB
                ? (tokenA, tokenB)
                : (tokenB, tokenA);
            if (token0 == address(0)) revert ZeroAddress();
        }
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address tokenA,
        address tokenB,
        uint16 fee
    ) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encodePacked(
                                    token0,
                                    token1,
                                    fee,
                                    antfarmToken
                                )
                            ),
                            token0 == antfarmToken
                                ? hex"b174de46ec9038ead3d74ed04c79d4885d8e642175833c4da037d5e052492e5b" // AtfPair init code hash
                                : hex"2f47d72b208014a5ba4f32371ac96dd421a39152dcaf104e8232b6c9f1a92280" // Pair init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA,
        address tokenB,
        uint16 fee
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IAntfarmPair(
            pairFor(tokenA, tokenB, fee)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256) {
        if (amountA == 0) revert InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
        return (amountA * reserveB) / reserveA;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IAntfarmBase.sol";

interface IAntfarmPair is IAntfarmBase {
    /// @notice Initialize the pair
    /// @dev Can only be called by the factory
    function initialize(
        address,
        address,
        uint16,
        address
    ) external;

    /// @notice The Antfarm token address
    /// @return address Address
    function antfarmToken() external view returns (address);

    /// @notice The Oracle instance used to compute swap's fees
    /// @return AntfarmOracle Oracle instance
    function antfarmOracle() external view returns (address);

    /// @notice Calcul fee to pay
    /// @param amount0Out The token0 amount going out of the pool
    /// @param amount0In The token0 amount going in the pool
    /// @param amount1Out The token1 amount going out of the pool
    /// @param amount1In The token1 amount going in the pool
    /// @return feeToPay Calculated fee to be paid
    function getFees(
        uint256 amount0Out,
        uint256 amount0In,
        uint256 amount1Out,
        uint256 amount1In
    ) external view returns (uint256 feeToPay);

    /// @notice Check for the best Oracle to use to perform fee calculation for a swap
    /// @dev Returns address(0) if no better oracle is found.
    /// @param maxReserve Actual oracle reserve0
    /// @return bestOracle Address from the best oracle found
    function scanOracles(uint112 maxReserve)
        external
        view
        returns (address bestOracle);

    /// @notice Update oracle for token
    /// @custom:usability Update the current Oracle with a more suitable one. Revert if the current Oracle is already the more suitable
    function updateOracle() external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint16 fee,
        uint256 allPairsLength
    );

    function possibleFees(uint256) external view returns (uint16);

    function allPairs(uint256) external view returns (address);

    function antfarmToken() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external view returns (address pair);

    function feesForPair(
        address tokenA,
        address tokenB,
        uint256
    ) external view returns (uint16);

    function getFeesForPair(address tokenA, address tokenB)
        external
        view
        returns (uint16[8] memory fees);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint16 fee
    ) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPosition {
    event Create(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event Increase(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event Decrease(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    event Claim(
        address owner,
        uint256 positionId,
        address pair,
        uint256 amount
    );

    event Lock(
        address owner,
        uint256 positionId,
        address pair,
        uint256 locktime
    );

    event Burn(address owner, uint256 positionId);

    struct Position {
        address pair;
        address delegate;
        bool enableLock;
        uint32 lock;
        uint256 claimedAmount;
    }

    function factory() external view returns (address);

    function WETH() external view returns (address);

    function antfarmToken() external view returns (address);

    struct PositionDetails {
        uint256 id;
        address owner;
        address delegate;
        address pair;
        address token0;
        address token1;
        uint256 lp;
        uint256 reserve0;
        uint256 reserve1;
        uint256 dividend;
        uint256 cumulatedDividend;
        uint16 fee;
        bool enableLock;
        uint32 lock;
    }

    function getPositionDetails(uint256 positionId)
        external
        view
        returns (PositionDetails memory positionDetails);

    function getPositionsDetails(uint256[] calldata positionIds)
        external
        view
        returns (PositionDetails[] memory positionsDetails);

    function createPosition(
        address tokenA,
        address tokenB,
        uint16 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function createPositionETH(
        address token,
        uint16 fee,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    struct IncreasePositionParams {
        address tokenA;
        address tokenB;
        uint16 fee;
        uint256 amountADesired;
        uint256 amountBDesired;
        uint256 amountAMin;
        uint256 amountBMin;
        uint256 deadline;
        uint256 positionId;
    }

    function increasePosition(IncreasePositionParams calldata params)
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    struct IncreasePositionETHParams {
        address token;
        uint16 fee;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        uint256 deadline;
        uint256 positionId;
    }

    function increasePositionETH(IncreasePositionETHParams calldata params)
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function enableLock(uint256 positionId, uint256 deadline) external;

    function disableLock(uint256 positionId, uint256 deadline) external;

    function lockPosition(
        uint32 locktime,
        uint256 positionId,
        uint256 deadline
    ) external;

    function burn(uint256 positionId) external;

    function claimDividendGrouped(uint256[] calldata positionIds)
        external
        returns (uint256 claimedAmount);

    function getDividendPerPosition(address owner)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    struct DecreasePositionParams {
        address tokenA;
        address tokenB;
        uint16 fee;
        uint256 liquidity;
        uint256 amountAMin;
        uint256 amountBMin;
        address to;
        uint256 deadline;
        uint256 positionId;
    }

    function decreasePosition(DecreasePositionParams calldata params)
        external
        returns (uint256 amountA, uint256 amountB);

    struct DecreasePositionETHParams {
        address token;
        uint16 fee;
        uint256 liquidity;
        uint256 amountTokenMin;
        uint256 amountETHMin;
        address to;
        uint256 deadline;
        uint256 positionId;
    }

    function decreasePositionETH(DecreasePositionETHParams calldata params)
        external
        returns (uint256 amountToken, uint256 amountETH);

    function claimDividend(uint256 positionId)
        external
        returns (uint256 claimedAmount);

    function getPositionsIds(address owner)
        external
        view
        returns (uint256[] memory positionIds);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

error Expired();
error NotOwner();
error NotAllowed();
error AlreadyAllowed();
error AlreadyDisallowed();
error LockedLiquidity();
error LockNotAllowed();
error WrongLocktime();
error LiquidityToClaim();
error DividendsToClaim();
error InsufficientAAmount();
error InsufficientBAmount();
error IdenticalAddresses();
error ZeroAddress();
error InsufficientAmount();
error InsufficientLiquidity();

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("approve(address,uint256)")));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transfer(address,uint256)")));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./pair/IAntfarmPairState.sol";
import "./pair/IAntfarmPairEvents.sol";
import "./pair/IAntfarmPairActions.sol";
import "./pair/IAntfarmPairDerivedState.sol";

interface IAntfarmBase is
    IAntfarmPairState,
    IAntfarmPairEvents,
    IAntfarmPairActions,
    IAntfarmPairDerivedState
{}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;
import "../IAntfarmToken.sol";

interface IAntfarmPairState {
    /// @notice The contract that deployed the AntfarmPair, which must adhere to the IAntfarmFactory interface
    /// @return address The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the AntfarmPair, sorted by address
    /// @return address The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the AntfarmPair, sorted by address
    /// @return address The token contract address
    function token1() external view returns (address);

    /// @notice Fee associated to the AntfarmPair instance
    /// @return uint16 Fee
    function fee() external view returns (uint16);

    /// @notice The LP tokens total circulating supply
    /// @return uint Total LP tokens
    function totalSupply() external view returns (uint256);

    /// @notice The AntFarmPair AntFarm's tokens cumulated fees
    /// @return uint Total Antfarm tokens
    function antfarmTokenReserve() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairActions {
    /// @notice Mint liquidity for a specific position
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param to The address to mint liquidity
    /// @param positionId The ID to store the position to allow multiple positions for a single address
    /// @return liquidity Minted liquidity
    function mint(address to, uint256 positionId)
        external
        returns (uint256 liquidity);

    /// @notice Burn liquidity from a specific position
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param to The address to return the liquidity to
    /// @param positionId The ID of the position to burn liquidity from
    /// @param liquidity Liquidity amount to be burned
    /// @return amount0 The token0 amount received from the liquidity burn
    /// @return amount1 The token1 amount received from the liquidity burn
    function burn(
        address to,
        uint256 liquidity,
        uint256 positionId
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap tokens
    /// @dev Low-level function. Should be called from another contract which performs all necessary checks
    /// @param amount0Out token0 amount to be swapped
    /// @param amount1Out token1 amount to be swapped
    /// @param to The address to send the swapped tokens
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    /// @notice Force balances to match reserves
    /// @param to The address to send excessive tokens
    function skim(address to) external;

    /// @notice Force reserves to match balances
    function sync() external;

    /// @notice Claim dividends for a specific position
    /// @param to The address to receive claimed dividends
    /// @param positionId The ID of the position to claim
    /// @return claimedAmount The amount claimed
    function claimDividend(address to, uint256 positionId)
        external
        returns (uint256 claimedAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairEvents {
    /// @notice Emitted when a position's liquidity is removed
    /// @param sender The address that initiated the burn call
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    /// @param to The address to send token0 & token1
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that initiated the mint call
    /// @param amount0 Required token0 for the minted liquidity
    /// @param amount1 Required token1 for the minted liquidity
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call
    /// @param amount0In Amount of token0 sent to the pair
    /// @param amount1In Amount of token1 sent to the pair
    /// @param amount0Out Amount of token0 going out of the pair
    /// @param amount1Out Amount of token1 going out of the pair
    /// @param to Address to transfer the swapped amount
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    /// @notice Emitted by the pool for any call to Sync function
    /// @param reserve0 reserve0 updated from the pair
    /// @param reserve1 reserve1 updated from the pair
    event Sync(uint112 reserve0, uint112 reserve1);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmPairDerivedState {
    /// @notice Get position LP tokens
    /// @param operator Position owner
    /// @param positionId ID of the position
    /// @return uint128 LP tokens owned by the operator
    function getPositionLP(address operator, uint256 positionId)
        external
        view
        returns (uint128);

    /// @notice Get pair reserves
    /// @return reserve0 Reserve for token0
    /// @return reserve1 Reserve for token1
    /// @return blockTimestampLast Last block proceeded
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    /// @notice Get Dividend from a specific position
    /// @param operator The address used to get dividends
    /// @param positionId Specific position
    /// @return amount Dividends owned by the address
    function claimableDividends(address operator, uint256 positionId)
        external
        view
        returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

interface IAntfarmToken {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function nonces(address owner) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}