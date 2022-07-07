// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

interface IIncreOwnable {
    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the sender is not the owner
    error IncreOwnable_NotOwner();

    /// @notice Emitted when the sender is not the pending owner
    error IncreOwnable_NotPendingOwner();

    /// @notice Emitted when the proposed owner is equal to the zero address
    error IncreOwnable_TransferZeroAddress();

    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when ownership is directly transferred to new address
    /// @param sender Address transferring ownership
    /// @param recipient Address of new owner
    event TransferOwner(address indexed sender, address indexed recipient);

    /// @notice Emitted when ownership is claimed
    /// @param sender Address transferring ownership
    /// @param recipient Address of new owner
    event TransferOwnerClaim(address indexed sender, address indexed recipient);

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function claimOwner() external;

    function transferOwner(address recipient, bool direct) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

interface IVBase is IVirtualToken {
    /* ****************** */
    /*     Events         */
    /* ****************** */

    /// @notice Emitted when oracle heart beat is updated
    /// @param newHeartBeat New heart beat value
    event HeartBeatUpdated(uint256 newHeartBeat);

    /* ****************** */
    /*     Errors         */
    /* ****************** */

    /// @notice Emitted when the proposed aggregators decimals are less than PRECISION
    error VBase_InsufficientPrecision();

    /// @notice Emitted when the latest round is incomplete
    error VBase_InvalidRoundTimestamp();

    /// @notice Emitted when the latest round's price is invalid
    error VBase_InvalidRoundPrice();

    /// @notice Emitted when the latest round's data is older than the oracle's max refresh time
    error VBase_DataNotFresh();

    /* ****************** */
    /*     Viewer         */
    /* ****************** */

    function heartBeat() external view returns (uint256);

    function getIndexPrice() external view returns (int256);

    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function setHeartBeat(uint256 newHeartBeat) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVirtualToken is IERC20Metadata {
    /* ****************** */
    /*  State modifying   */
    /* ****************** */

    function mint(uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

// interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Modern and gas efficient ERC20 implementation.
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract BaseERC20 is IERC20, IERC20Metadata {
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public override name;

    string public override symbol;

    uint8 public constant override decimals = 18;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// contracts
import {VirtualToken} from "./VirtualToken.sol";
import {IncreOwnable} from "../utils/IncreOwnable.sol";

// interfaces
import {IVBase} from "../interfaces/IVBase.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @notice ERC20 token traded on the CryptoSwap pool
contract VBase is IVBase, IncreOwnable, VirtualToken {
    uint8 internal constant PRECISION = 18;
    uint256 public override heartBeat;

    AggregatorV3Interface public immutable aggregator;

    constructor(
        string memory _name,
        string memory _symbol,
        AggregatorV3Interface _aggregator,
        uint256 _heartBeat
    ) VirtualToken(_name, _symbol) {
        if (_aggregator.decimals() > PRECISION) revert VBase_InsufficientPrecision();
        aggregator = _aggregator;
        setHeartBeat(_heartBeat);
    }

    function getIndexPrice() external view override returns (int256) {
        return _chainlinkPrice(aggregator);
    }

    function setHeartBeat(uint256 newHeartBeat) public override onlyGovernance {
        heartBeat = newHeartBeat;

        emit HeartBeatUpdated(newHeartBeat);
    }

    function _chainlinkPrice(AggregatorV3Interface chainlinkInterface) internal view returns (int256) {
        uint8 chainlinkDecimals = chainlinkInterface.decimals();
        (, int256 roundPrice, , uint256 roundTimestamp, ) = chainlinkInterface.latestRoundData();

        // If the round is not complete yet, roundTimestamp is 0
        if (roundTimestamp <= 0) revert VBase_InvalidRoundTimestamp();
        if (roundPrice <= 0) revert VBase_InvalidRoundPrice();
        if (roundTimestamp + heartBeat < block.timestamp) revert VBase_DataNotFresh();

        int256 scaledPrice = (roundPrice * int256(10**(PRECISION - chainlinkDecimals)));
        return scaledPrice;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// contracts
import {BaseERC20} from "./BaseERC20.sol";
import {PerpOwnable} from "../utils/PerpOwnable.sol";

// interfaces
import {IVirtualToken} from "../interfaces/IVirtualToken.sol";

contract VirtualToken is IVirtualToken, BaseERC20, PerpOwnable {
    constructor(string memory _name, string memory _symbol) BaseERC20(_name, _symbol) {}

    function mint(uint256 amount) external override onlyPerp {
        _mint(perp, amount);
    }

    function burn(uint256 amount) external override onlyPerp {
        _burn(perp, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// interfaces
import {IIncreOwnable} from "../interfaces/IIncreOwnable.sol";

/// @notice Increment access control contract.
/// @author Adapted from https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol, License-Identifier: MIT.
/// @author Adapted from https://github.com/sushiswap/trident/blob/master/contracts/utils/TridentOwnable.sol, License-Identifier: GPL-3.0-or-later
contract IncreOwnable is IIncreOwnable {
    address public override owner;
    address public override pendingOwner;

    /// @notice Initialize and grant deployer account (`msg.sender`) `owner` access role.
    constructor() {
        owner = msg.sender;
        emit TransferOwner(address(0), msg.sender);
    }

    /// @notice Access control modifier that requires modified function to be called by the governance, i.e. the `owner` account
    modifier onlyGovernance() {
        if (msg.sender != owner) revert IncreOwnable_NotOwner();
        _;
    }

    /// @notice `pendingOwner` can claim `owner` account.
    function claimOwner() external override {
        if (msg.sender != pendingOwner) revert IncreOwnable_NotPendingOwner();
        emit TransferOwner(owner, msg.sender);
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /// @notice Transfer `owner` account.
    /// @param recipient Account granted `owner` access control.
    /// @param direct If 'true', ownership is directly transferred.
    function transferOwner(address recipient, bool direct) external override onlyGovernance {
        if (recipient == address(0)) revert IncreOwnable_TransferZeroAddress();
        if (direct) {
            owner = recipient;
            emit TransferOwner(msg.sender, recipient);
        } else {
            pendingOwner = recipient;
            emit TransferOwnerClaim(msg.sender, recipient);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

/// @notice Emitted when the sender is not perp
error PerpOwnable_NotOwner();

/// @notice Emitted when the proposed address is equal to the zero address
error PerpOwnable_TransferZeroAddress();

/// @notice Emitted when the ownership of the contract has already been claimed
error PerpOwnable_OwnershipAlreadyClaimed();

/// @notice Perp access control contract, simplied version of IncreOwnable
contract PerpOwnable {
    address public perp;

    event PerpOwnerTransferred(address indexed sender, address indexed recipient);

    /// @notice Access control modifier that requires modified function to be called by the perp contract
    modifier onlyPerp() {
        if (msg.sender != perp) revert PerpOwnable_NotOwner();
        _;
    }

    /// @notice Transfer `perp` account
    /// @notice Meant to be used only once at deployment as Perpetual can't transfer ownership afterwards
    /// @param recipient Account granted `perp` access control.
    function transferPerpOwner(address recipient) external {
        if (recipient == address(0)) revert PerpOwnable_TransferZeroAddress();
        if (perp != address(0)) revert PerpOwnable_OwnershipAlreadyClaimed();

        perp = recipient;
        emit PerpOwnerTransferred(msg.sender, recipient);
    }
}