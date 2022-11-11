// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
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
    ) public virtual returns (bool) {
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

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for an Initialization target contract.
interface IInitializer {
    function initialize(bytes memory _data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for an Issuer module contract
interface IIssuer {
    /// @dev Emitted when the caller has underpaid the aution
    error Underpaid(uint256 payment, uint256 price);
    /// @dev Emitted when the caller is not a registered vault
    error NotVault(address _vault);
    /// @dev Emitted when the auction has not started
    error NotStarted(address _vault, uint256 startTime);

    function initialize(bytes memory _data) external;

    function purchase(
        address _vault,
        uint256 _amount,
        bytes32[] calldata _mintProof
    ) external payable;

    function purchasePrice(address _vault, uint256 _amount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Permission} from "./IVaultRegistry.sol";

/// @dev Interface for generic Module contract
interface IModule {
    function getLeaves() external view returns (bytes32[] memory leaves);

    function getUnhashedLeaves() external view returns (bytes[] memory leaves);

    function getPermissions()
        external
        view
        returns (Permission[] memory permissions);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for Supply target contract
interface ISupply {
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error MintError(address _account);
    /// @dev Emitted when an account being called as an assumed contract does not have code and returns no data
    error BurnError(address _account);

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IIssuer} from "./IIssuer.sol";

/// @dev Interface for a VRGDA Issuer module contract
interface IVRGDA is IIssuer {
    function purchase(address _vault, bytes32[] calldata _mintProof)
        external
        payable;

    function purchasePrice(address _vault) external view returns (uint256);

    function getVRGDAPrice(
        address _vault,
        int256 _timeSinceStart,
        uint256 _sold
    ) external view returns (uint256);

    function getTargetSaleTime(address _vault, int256 _sold)
        external
        view
        returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Initialization call information
struct InitInfo {
    // Address of target contract
    address target;
    // Initialization data
    bytes data;
    // Merkle proof for call
    bytes32[] proof;
}

struct Plugin {
    //Address of plugin
    address target;
    //Function selector of plugin
    bytes4 selector;
}

/// @dev Interface for Vault proxy contract
interface IVault {
    /// @dev Emitted when execution reverted with no reason
    error ExecutionReverted();
    /// @dev Emitted when there is no implementation stored in methods for a function signature
    error MethodNotFound();
    /// @dev Emitted when a plugin selector would overwrite an existing plugin
    error InvalidSelector(bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotAuthorized(address _caller, address _target, bytes4 _selector);
    /// @dev Emitted when the caller is not the owner
    error NotOwner(address _owner, address _caller);
    /// @dev Emitted when the caller is not the factory
    error NotFactory(address _factory, address _caller);
    /// @dev Emitted when passing an EOA or an undeployed contract as the target
    error TargetInvalid(address _target);

    /// @dev Event log for executing transactions
    /// @param _target Address of target contract
    /// @param _data Transaction data being executed
    /// @param _response Return data of delegatecall
    event Execute(address indexed _target, bytes _data, bytes _response);
    /// @dev Event log for installing plugins
    /// @param _plugins List of plugin contracts
    event UpdatedPlugins(Plugin[] _plugins);

    function execute(
        address _target,
        bytes memory _data,
        bytes32[] memory _proof
    ) external payable returns (bool success, bytes memory response);

    function setPlugins(Plugin[] memory _plugins) external;

    function methods(bytes4) external view returns (address);

    function MERKLE_ROOT() external view returns (bytes32);

    function OWNER() external view returns (address);

    function FACTORY() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {InitInfo, Plugin} from "./IVault.sol";

/// @dev Vault permissions
struct Permission {
    // Address of module contract
    address module;
    // Address of target contract
    address target;
    // Function selector from target contract
    bytes4 selector;
}

/// @dev Vault information
struct VaultInfo {
    // Address of FERC1155 token contract
    address token;
    // ID of the token type
    uint256 id;
}

/// @dev Interface for VaultRegistry contract
interface IVaultRegistry {
    /// @dev Emitted when the caller is not the controller
    error InvalidController(address _controller, address _sender);
    /// @dev Emitted when the caller is not a registered vault
    error UnregisteredVault(address _sender);

    /// @dev Event log for deploying vault
    /// @param _vault Address of the vault
    /// @param _token Address of the token
    /// @param _id Id of the token
    event VaultDeployed(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id
    );

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function createFor(
        bytes32 _merkleRoot,
        address _owner,
        Plugin[] calldata _plugins
    ) external returns (address vault);

    function create(
        bytes32 _merkleRoot,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function create(bytes32 _merkleRoot, Plugin[] calldata _plugins)
        external
        returns (address vault);

    function createCollectionFor(
        bytes32 _merkleRoot,
        address _controller,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault, address token);

    function createCollection(
        bytes32 _merkleRoot,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault, address token);

    function createInCollection(
        bytes32 _merkleRoot,
        address _token,
        Plugin[] calldata _plugins,
        InitInfo[] calldata _calls
    ) external returns (address vault);

    function factory() external view returns (address);

    function fNFT() external view returns (address);

    function fNFTImplementation() external view returns (address);

    function burn(address _from, uint256 _value) external;

    function mint(address _to, uint256 _value) external;

    function nextId(address) external view returns (uint256);

    function totalSupply(address _vault) external view returns (uint256);

    function uri(address _vault) external view returns (string memory);

    function vaultToToken(address)
        external
        view
        returns (address token, uint256 id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule} from "../interfaces/IModule.sol";
import {Permission} from "../interfaces/IVaultRegistry.sol";

/// @title Module
/// @author Fractional Art
/// @notice Base module contract for converting vault permissions into leaf nodes
contract Module is IModule {
    /// @notice Gets the list of hashed leaf nodes used to generate a merkle tree
    /// @dev Leaf nodes are hashed permissions of the merkle tree
    /// @return leaves Hashed leaf nodes
    function getLeaves() external view returns (bytes32[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes32[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = keccak256(abi.encode(permissions[i]));
            }
        }
    }

    /// @notice Gets the list of unhashed leaf nodes used to generate a merkle tree
    /// @dev Only used for third party APIs (Lanyard) that require unhashed leaves
    /// @return leaves Unhashed leaf nodes
    function getUnhashedLeaves() external view returns (bytes[] memory leaves) {
        Permission[] memory permissions = getPermissions();
        uint256 length = permissions.length;
        leaves = new bytes[](length);
        unchecked {
            for (uint256 i; i < length; ++i) {
                leaves[i] = abi.encode(permissions[i]);
            }
        }
    }

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Intentionally left empty to be overridden by the module inheriting from this contract
    /// @return permissions List of vault permissions
    function getPermissions()
        public
        view
        virtual
        returns (Permission[] memory permissions)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Module} from "../Module.sol";
import {ISupply} from "../../interfaces/ISupply.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {IVaultRegistry, Permission} from "../../interfaces/IVaultRegistry.sol";
import {SafeSend} from "../../utils/SafeSend.sol";
import {IInitializer, Initialize} from "../../targets/Initialize.sol";
import {IVRGDA} from "../../interfaces/IVRGDA.sol";
import "@rari-capital/solmate/src/utils/SignedWadMath.sol";

/// @title VRGDA
/// @author Tessera
/// @notice Abstract contract for Variable Rate Gradual Dutch Auction (VRGDA) distribution modules
abstract contract VRGDA is IVRGDA, Module, SafeSend {
    /// @notice Address of VaultRegistry contract
    address public immutable registry;
    /// @notice Address of Supply target contract
    address public immutable supply;
    /// @notice Address of Initalization target contract
    address public immutable initializeTarget;

    /// @notice Mapping of vault address to target price
    mapping(address => int256) public targetPrice;
    /// @notice Mapping of vault address to decay constant
    mapping(address => int256) public decayConstant;
    /// @notice Mapping of vault address to start time
    mapping(address => uint256) public startTime;
    /// @notice Mapping of vault address to total RAEs sold
    mapping(address => uint256) public totalSold;

    /// @notice Initializes registry, supply, initializeTarget, and WETH addresses
    constructor(
        address _registry,
        address _supply,
        address payable _weth
    ) SafeSend(_weth) {
        registry = _registry;
        supply = _supply;
        initializeTarget = address(new Initialize(address(this)));
    }

    /// @notice Initializes auction for a vault
    /// @param _data Initialization parameters
    function initialize(bytes memory _data) external virtual;

    /// @notice Purchases single RAE from auction
    /// @param _vault Address of the vault
    /// @param _mintProof List of proofs to execute a mint function
    function purchase(address _vault, bytes32[] calldata _mintProof)
        external
        payable
    {
        (, uint256 id) = IVaultRegistry(registry).vaultToToken(_vault);
        if (id == 0) revert NotVault(_vault);

        uint256 startTime = startTime[_vault];
        if (block.timestamp < startTime) revert NotStarted(_vault, startTime);

        uint256 price = purchasePrice(_vault);
        ++totalSold[_vault];

        if (msg.value < price) revert Underpaid(msg.value, price);

        _mintFractions(_vault, msg.sender, 1, _mintProof);
        _sendEthOrWeth(msg.sender, msg.value - price);
    }

    /// @notice Purchases RAEs from auction
    /// @param _vault Address of the vault
    /// @param _amount Amount of RAEs to purchase
    /// @param _mintProof List of proofs to execute a mint function
    function purchase(
        address _vault,
        uint256 _amount,
        bytes32[] calldata _mintProof
    ) external payable {
        (, uint256 id) = IVaultRegistry(registry).vaultToToken(_vault);
        if (id == 0) revert NotVault(_vault);

        uint256 startTime = startTime[_vault];
        if (block.timestamp < startTime) revert NotStarted(_vault, startTime);

        uint256 price = purchasePrice(_vault, _amount);
        totalSold[_vault] += _amount;

        if (msg.value < price) revert Underpaid(msg.value, price);

        _mintFractions(_vault, msg.sender, _amount, _mintProof);
        _sendEthOrWeth(msg.sender, msg.value - price);
    }

    /// @notice Retrieves price to purchase single RAE from auction
    /// @param _vault Address of the vault
    function purchasePrice(address _vault) public view returns (uint256) {
        return
            getVRGDAPrice(
                _vault,
                toDaysWadUnsafe(block.timestamp - startTime[_vault]),
                totalSold[_vault]
            );
    }

    /// @notice Retrieves price to purchase RAEs from auction
    /// @param _vault Address of the vault
    /// @param _amount Amount of RAEs to purchase
    function purchasePrice(address _vault, uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256 price;
        uint256 sold = totalSold[_vault];
        unchecked {
            for (uint256 i = 0; i < _amount; i++) {
                price += getVRGDAPrice(
                    _vault,
                    toDaysWadUnsafe(block.timestamp - startTime[_vault]),
                    sold
                );
                ++sold;
            }
        }
        return price;
    }

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param _vault Address of the vault
    /// @param _timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param _sold The total number of tokens that have been sold so far.
    /// @return PRICE The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(
        address _vault,
        int256 _timeSinceStart,
        uint256 _sold
    ) public view returns (uint256) {
        unchecked {
            return
                uint256(
                    wadMul(
                        targetPrice[_vault],
                        wadExp(
                            unsafeWadMul(
                                decayConstant[_vault],
                                _timeSinceStart -
                                    getTargetSaleTime(
                                        _vault,
                                        toWadUnsafe(_sold + 1)
                                    )
                            )
                        )
                    )
                );
        }
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param _vault Address of the vault
    /// @param _sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return TIME The target time the tokens should be sold by, scaled by 1e18, where the time is relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(address _vault, int256 _sold)
        public
        view
        virtual
        returns (int256);

    /// @notice Gets the list of permissions installed on a vault
    /// @dev Permissions consist of a module contract, target contract, and function selector
    /// @return permissions List of vault permissions
    function getPermissions()
        public
        view
        override
        returns (Permission[] memory permissions)
    {
        permissions = new Permission[](2);
        permissions[0] = Permission(
            IVaultRegistry(registry).factory(),
            initializeTarget,
            IInitializer.initialize.selector
        );
        permissions[1] = Permission(
            address(this),
            supply,
            ISupply.mint.selector
        );
    }

    function _mintFractions(
        address _vault,
        address _to,
        uint256 _fractionSupply,
        bytes32[] calldata _mintProof
    ) internal {
        bytes memory data = abi.encodeCall(
            ISupply.mint,
            (_to, _fractionSupply)
        );
        IVault(payable(_vault)).execute(supply, data, _mintProof);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IVaultRegistry} from "../../../interfaces/IVaultRegistry.sol";
import {VRGDA} from "../VRGDA.sol";
import "@rari-capital/solmate/src/utils/SignedWadMath.sol";

/// @title LogisticSale
/// @author Tessera
/// @notice Module contract for a Logistic VRGDA
contract LogisticSale is VRGDA {
    /// @notice Mapping of vault address to logistic limit
    mapping(address => int256) public logisticLimit;
    /// @notice Mapping of vault address to logistic limit doubled
    mapping(address => int256) public logisticLimitDoubled;
    /// @notice Mapping of vault address to time scale
    mapping(address => int256) public timeScale;

    /// @notice Initializes registry, supply, and WETH addresses
    constructor(
        address _registry,
        address _supply,
        address payable _weth
    ) VRGDA(_registry, _supply, _weth) {}

    /// @notice Initializes auction for a vault
    /// @param _data Initialization parameters
    function initialize(bytes memory _data) external virtual override {
        (, uint256 id) = IVaultRegistry(registry).vaultToToken(msg.sender);
        if (id == 0) revert NotVault(msg.sender);

        (
            int256 _targetPrice,
            int256 _priceDecayPercent,
            int256 _maxSellable,
            int256 _timeScale,
            uint256 _startTime
        ) = abi.decode(_data, (int256, int256, int256, int256, uint256));

        if (_startTime < block.timestamp) {
            _startTime = block.timestamp;
        }

        targetPrice[msg.sender] = _targetPrice;
        decayConstant[msg.sender] = wadLn(1e18 - _priceDecayPercent);
        startTime[msg.sender] = _startTime;

        logisticLimit[msg.sender] = _maxSellable + 1e18;
        logisticLimitDoubled[msg.sender] = (_maxSellable + 1e18) * 2e18;
        timeScale[msg.sender] = _timeScale;
    }

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param _vault Address of the vault
    /// @param _sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return TIME The target time the tokens should be sold by, scaled by 1e18, where the time is relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(address _vault, int256 _sold)
        public
        view
        virtual
        override
        returns (int256)
    {
        unchecked {
            return
                -unsafeWadDiv(
                    wadLn(
                        unsafeDiv(
                            logisticLimitDoubled[_vault],
                            _sold + logisticLimit[_vault]
                        ) - 1e18
                    ),
                    timeScale[_vault]
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IInitializer} from "../interfaces/IInitializer.sol";

contract Initialize is IInitializer {
    address immutable module;

    constructor(address _module) {
        module = _module;
    }

    function initialize(bytes memory _data) external {
        IInitializer(module).initialize(_data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {WETH} from "@rari-capital/solmate/src/tokens/WETH.sol";

/// @title SafeSend
/// @author Fractional Art
/// @notice Utility contract for sending Ether or WETH value to an address
abstract contract SafeSend {
    /// @notice Address for WETH contract on network
    /// mainnet: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address payable public immutable WETH_ADDRESS;

    constructor(address payable _weth) {
        WETH_ADDRESS = _weth;
    }

    /// @notice Attempts to send ether to an address
    /// @param _to Address attemping to send to
    /// @param _value Amount to send
    /// @return success Status of transfer
    function _attemptETHTransfer(address _to, uint256 _value)
        internal
        returns (bool success)
    {
        // Here increase the gas limit a reasonable amount above the default, and try
        // to send ETH to the recipient.
        // NOTE: This might allow the recipient to attempt a limited reentrancy attack.
        (success, ) = _to.call{value: _value, gas: 30000}("");
    }

    /// @notice Sends eth or weth to an address
    /// @param _to Address to send to
    /// @param _value Amount to send
    function _sendEthOrWeth(address _to, uint256 _value) internal {
        if (!_attemptETHTransfer(_to, _value)) {
            WETH(WETH_ADDRESS).deposit{value: _value}();
            WETH(WETH_ADDRESS).transfer(_to, _value);
        }
    }
}