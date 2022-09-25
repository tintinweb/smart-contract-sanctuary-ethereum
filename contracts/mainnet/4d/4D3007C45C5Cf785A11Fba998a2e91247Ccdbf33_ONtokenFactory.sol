// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ONtokenSpawner } from "./ONtokenSpawner.sol";
import { AddressBookInterface } from "../interfaces/AddressBookInterface.sol";
import { ONtokenInterface } from "../interfaces/ONtokenInterface.sol";
import { WhitelistInterface } from "../interfaces/WhitelistInterface.sol";

/**
 * @title A factory to create onTokens
 * @notice Create new onTokens and keep track of all created tokens
 * @dev Calculate contract address before each creation with CREATE2
 * and deploy eip-1167 minimal proxies for onToken logic contract
 */
contract ONtokenFactory is ONtokenSpawner {
    using SafeMath for uint256;
    /// @notice AddressBook contract that records the address of the Whitelist module and the ONtoken impl address. */
    address public addressBook;

    /// @notice array of all created onTokens */
    address[] public onTokens;

    /// @dev mapping from parameters hash to its deployed address
    mapping(bytes32 => address) private idToAddress;

    /// @dev max expiry that BokkyPooBahsDateTimeLibrary can handle. (2345/12/31)
    uint256 private constant MAX_EXPIRY = 11865398400;

    constructor(address _addressBook) {
        addressBook = _addressBook;
    }

    /// @notice emitted when the factory creates a new Option
    event ONtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address[] indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );

    struct ONtokenParams {
        // "Stack too deep, try removing local variables" workaround
        bytes32 id;
        address whitelist;
        address onTokenImpl;
        address newONtoken;
    }

    /**
     * @notice create new onTokens
     * @dev deploy an eip-1167 minimal proxy with CREATE2 and register it to the whitelist module
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets assets that is held as collateral against short/written options
     * @param _collateralConstraints limits the maximum number of untrusted collateral tokens (0 - no limit)
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return newONtoken address of the newly created option
     */
    function createONtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address) {
        ONtokenParams memory p;
        require(_expiry > block.timestamp, "ONtokenFactory: Can't create expired option");
        require(_expiry < MAX_EXPIRY, "ONtokenFactory: Can't create option with expiry > 2345/12/31");
        // 8 hours = 3600 * 8 = 28800 seconds
        require(_expiry.sub(28800).mod(86400) == 0, "ONtokenFactory: Option has to expire 08:00 UTC");
        p.id = _getOptionId(
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );

        require(idToAddress[p.id] == address(0), "ONtokenFactory: Option already created");

        p.whitelist = AddressBookInterface(addressBook).getWhitelist();
        require(
            WhitelistInterface(p.whitelist).isWhitelistedProduct(
                _underlyingAsset,
                _strikeAsset,
                _collateralAssets,
                _isPut
            ),
            "ONtokenFactory: Unsupported Product"
        );

        require(_strikePrice > 0, "ONtokenFactory: Can't create a $0 strike option");

        p.onTokenImpl = AddressBookInterface(addressBook).getONtokenImpl();
        bytes memory initializationCalldata;

        initializationCalldata = abi.encodeWithSelector(
            ONtokenInterface(p.onTokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );

        p.newONtoken = _spawn(p.onTokenImpl, initializationCalldata);
        idToAddress[p.id] = p.newONtoken;
        onTokens.push(p.newONtoken);
        WhitelistInterface(p.whitelist).whitelistONtoken(p.newONtoken);

        emit ONtokenCreated(
            p.newONtoken,
            msg.sender,
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _strikePrice,
            _expiry,
            _isPut
        );
        return p.newONtoken;
    }

    /**
     * @notice get the total onTokens created by the factory
     * @return length of the onTokens array
     */
    function getONtokensLength() external view returns (uint256) {
        return onTokens.length;
    }

    /**
     * @notice get the onToken address for an already created onToken, if no onToken has been created with these parameters, it will return address(0)
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return the address of target onToken.
     */
    function getONtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        bytes32 id = _getOptionId(
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );
        return idToAddress[id];
    }

    /**
     * @notice get the address at which a new onToken with these parameters would be deployed
     * @dev return the exact address that will be deployed at with _computeAddress
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets asset that is held as collateral against short/written options
     * @param _collateralConstraints limits the maximum number of untrusted collateral tokens (0 - no limit)
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return targetAddress the address this onToken would be deployed at
     */
    function getTargetONtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address) {
        address onTokenImpl = AddressBookInterface(addressBook).getONtokenImpl();

        bytes memory initializationCalldata = abi.encodeWithSelector(
            ONtokenInterface(onTokenImpl).init.selector,
            addressBook,
            _underlyingAsset,
            _strikeAsset,
            _collateralAssets,
            _collateralConstraints,
            _strikePrice,
            _expiry,
            _isPut
        );
        return _computeAddress(onTokenImpl, initializationCalldata);
    }

    /**
     * @dev hash onToken parameters and return a unique option id
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAssets asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return id the unique id of an onToken
     */
    function _getOptionId(
        address _underlyingAsset,
        address _strikeAsset,
        address[] calldata _collateralAssets,
        uint256[] calldata _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _underlyingAsset,
                    _strikeAsset,
                    _collateralAssets,
                    _collateralConstraints,
                    _strikePrice,
                    _expiry,
                    _isPut
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Spawn } from "../packages/Spawn.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

/**
 * @title ONtokenSpawner
 * @notice This contract spawns and initializes eip-1167 minimal proxies that
 * point to existing logic contracts.
 * @notice This contract was modified from Spawner.sol
 * https://github.com/0age/Spawner/blob/master/contracts/Spawner.sol to fit into ONtokenFactory
 */
contract ONtokenSpawner {
    // fixed salt value because we will only deploy an onToken with the same init value once
    bytes32 private constant SALT = bytes32(0);

    /**
     * @notice internal function for spawning an eip-1167 minimal proxy using `CREATE2`
     * @param logicContract address of the logic contract
     * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
     * from the spawned contract to the logic contract during contract creation
     * @return spawnedContract the address of the newly-spawned contract
     */
    function _spawn(address logicContract, bytes memory initializationCalldata) internal returns (address) {
        // place the creation code and constructor args of the contract to spawn in memory
        bytes memory initCode = abi.encodePacked(
            type(Spawn).creationCode,
            abi.encode(logicContract, initializationCalldata)
        );

        // spawn the contract using `CREATE2`
        return Create2.deploy(0, SALT, initCode);
    }

    /**
     * @notice internal view function for finding the address of the standard
     * eip-1167 minimal proxy created using `CREATE2` with a given logic contract
     * and initialization calldata payload
     * @param logicContract address of the logic contract
     * @param initializationCalldata calldata that will be supplied to the `DELEGATECALL`
     * from the spawned contract to the logic contract during contract creation
     * @return target address of the next spawned minimal proxy contract with the
     * given parameters.
     */
    function _computeAddress(address logicContract, bytes memory initializationCalldata)
        internal
        view
        returns (address target)
    {
        // place the creation code and constructor args of the contract to spawn in memory
        bytes memory initCode = abi.encodePacked(
            type(Spawn).creationCode,
            abi.encode(logicContract, initializationCalldata)
        );
        // get target address using the constructed initialization code
        bytes32 initCodeHash = keccak256(initCode);

        target = Create2.computeAddress(SALT, initCodeHash);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface AddressBookInterface {
    /* Getters */

    function getONtokenImpl() external view returns (address);

    function getONtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setONtokenImpl(address _onTokenImpl) external;

    function setONtokenFactory(address _factory) external;

    function setOracleImpl(address _onTokenImpl) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ONtokenInterface {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burnONtoken(address account, uint256 amount) external;

    function reduceCollaterization(
        uint256[] calldata collateralsAmountsForReduce,
        uint256[] calldata collateralsValuesForReduce,
        uint256 onTokenAmountBurnt
    ) external;

    function getCollateralAssets() external view returns (address[] memory);

    function getCollateralsAmounts() external view returns (uint256[] memory);

    function getCollateralConstraints() external view returns (uint256[] memory);

    function collateralsValues(uint256) external view returns (uint256);

    function getCollateralsValues() external view returns (uint256[] memory);

    function controller() external view returns (address);

    function decimals() external view returns (uint8);

    function collaterizedTotalAmount() external view returns (uint256);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function expiryTimestamp() external view returns (uint256);

    function getONtokenDetails()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address,
            address,
            uint256,
            uint256,
            bool,
            uint256
        );

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address[] memory _collateralAssets,
        uint256[] memory _collateralConstraints,
        uint256 _strikePrice,
        uint256 _expiryTimestamp,
        bool _isPut
    ) external;

    function isPut() external view returns (bool);

    function mintONtoken(
        address account,
        uint256 amount,
        uint256[] memory collateralsAmountsForMint,
        uint256[] memory collateralsValuesForMint
    ) external;

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function strikeAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function underlyingAsset() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface WhitelistInterface {
    function addressBook() external view returns (address);

    function blacklistCollateral(address[] memory _collaterals) external;

    function blacklistONtoken(address _onTokenAddress) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;

    function isWhitelistedCollaterals(address[] memory _collaterals) external view returns (bool);

    function isWhitelistedONtoken(address _onToken) external view returns (bool);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address[] memory _collateral,
        bool _isPut
    ) external view returns (bool);

    //  function owner() external view returns (address);

    //  function renounceOwnership() external;

    //  function transferOwnership(address newOwner) external;

    function whitelistCollaterals(address[] memory _collaterals) external;

    function whitelistONtoken(address _onTokenAddress) external;

    function whitelistProduct(
        address _underlying,
        address _strike,
        address[] memory _collaterals,
        bool _isPut
    ) external;
}

/* solhint-disable avoid-low-level-calls, indent, no-inline-assembly */
/* This contract is copied from Spawner package: https://github.com/0age/Spawner */
pragma solidity 0.8.9;

/**
 * @title Spawn
 * @author 0age
 * @notice This contract provides creation code that is used by Spawner in order
 * to initialize and deploy eip-1167 minimal proxies for a given logic contract.
 * SPDX-License-Identifier: MIT
 */
// version: https://github.com/0age/Spawner/blob/1b342afda0c1ec47e6a2d65828a6ca50f0a442fe/contracts/Spawner.sol
contract Spawn {
    constructor(address logicContract, bytes memory initializationCalldata) payable {
        // delegatecall into the logic contract to perform initialization.
        (bool ok, ) = logicContract.delegatecall(initializationCalldata);
        if (!ok) {
            // pass along failure message from delegatecall and revert.
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        // place eip-1167 runtime code in memory.
        bytes memory runtimeCode = abi.encodePacked(
            bytes10(0x363d3d373d3d3d363d73),
            logicContract,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );

        // return eip-1167 code to write it to spawned contract runtime.
        assembly {
            return(add(0x20, runtimeCode), 45) // eip-1167 runtime code, length
        }
    }
}