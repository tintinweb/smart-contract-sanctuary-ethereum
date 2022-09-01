// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IAipFactory.sol";
import "./base/AipPoolDeployer.sol";
import "./access/Ownable.sol";
import "./security/NoDelegateCall.sol";
import "./libraries/PoolAddress.sol";

contract AipFactory is IAipFactory, AipPoolDeployer, NoDelegateCall {
    address public override owner;
    address public immutable swapManager;
    address public immutable DAI;
    address public immutable USDC;
    address public immutable USDT;
    address public immutable WETH9;

    mapping(address => PoolAddress.PoolInfo) public override getPoolInfo;
    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getPool;

    constructor(
        address _swapManager,
        address _DAI,
        address _USDC,
        address _USDT,
        address _WETH9
    ) {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);
        swapManager = _swapManager;
        DAI = _DAI;
        USDC = _USDC;
        USDT = _USDT;
        WETH9 = _WETH9;
    }

    function createPool(
        address token0,
        address token1,
        uint24 frequency
    ) external override noDelegateCall returns (address pool) {
        require(
            token0 != token1 && token0 != address(0) && token1 != address(0)
        );
        require(frequency > 0 && frequency <= 30, "Invalid date");
        require(
            token0 == DAI || token0 == USDC || token0 == USDT,
            "Only DAI, USDC, USDT accepted"
        );
        require(getPool[token0][token1][frequency] == address(0));
        pool = deploy(
            address(this),
            swapManager,
            WETH9,
            token0,
            token1,
            frequency
        );
        getPool[token0][token1][frequency] = pool;
        getPoolInfo[pool] = PoolAddress.PoolInfo({
            token0: token0,
            token1: token1,
            frequency: frequency
        });
        emit PoolCreated(token0, token1, frequency, pool);
    }

    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/PoolAddress.sol";

interface IAipFactory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event PoolCreated(
        address token0,
        address token1,
        uint24 frequency,
        address pool
    );

    function owner() external view returns (address);

    function getPoolInfo(address addr)
        external
        view
        returns (
            address,
            address,
            uint24
        );

    function getPool(
        address token0,
        address token1,
        uint24 frequency
    ) external view returns (address pool);

    function createPool(
        address token0,
        address token1,
        uint24 frequency
    ) external returns (address pool);

    function setOwner(address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "../AipPool.sol";
import "../interfaces/IAipPoolDeployer.sol";

contract AipPoolDeployer is IAipPoolDeployer {
    // 0: Token X, token for protection
    // 1: Token Y, protected token
    struct Parameters {
        address factory;
        address swapManager;
        address WETH9;
        address token0;
        address token1;
        uint24 frequency;
    }

    Parameters public override parameters;

    function deploy(
        address factory,
        address swapManager,
        address WETH9,
        address token0,
        address token1,
        uint24 frequency
    ) internal returns (address pool) {
        parameters = Parameters({
            factory: factory,
            swapManager: swapManager,
            WETH9: WETH9,
            token0: token0,
            token1: token1,
            frequency: frequency
        });
        // pool = address(
        //     new AipPool{
        //         salt: keccak256(abi.encode(token0, token1, frequency))
        //     }()
        // );
        delete parameters;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0x05f61300b01fa8f6f3958dcf84da588789362c9d6e910fb84e9b420520cb099e;

    struct PoolInfo {
        address token0;
        address token1;
        uint24 frequency;
    }

    function getPoolInfo(
        address token0,
        address token1,
        uint24 frequency
    ) internal pure returns (PoolInfo memory) {
        return PoolInfo({token0: token0, token1: token1, frequency: frequency});
    }

    function computeAddress(address factory, PoolInfo memory poolInfo)
        internal
        pure
        returns (address pool)
    {
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(
                                    poolInfo.token0,
                                    poolInfo.token1,
                                    poolInfo.frequency
                                )
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipPoolDeployer {
    function parameters()
        external
        view
        returns (
            address factory,
            address swapManager,
            address WETH9,
            address token0,
            address token1,
            uint24 frequency
        );
}