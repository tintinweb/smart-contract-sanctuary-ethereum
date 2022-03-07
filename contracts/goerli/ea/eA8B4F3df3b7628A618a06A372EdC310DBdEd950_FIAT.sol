/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// Verified using https://dapp.tools

// hevm: flattened sources of lib/fiat/src/FIAT.sol
// SPDX-License-Identifier: AGPL-3.0-or-later AND Unlicensed
pragma solidity >=0.8.4 <0.9.0;

////// lib/fiat/src/interfaces/IFIAT.sol
/* pragma solidity ^0.8.4; */

interface IFIAT {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function transfer(address from, uint256 amount) external returns (bool);

    function transferFrom(
        address to,
        address from,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

////// lib/fiat/src/interfaces/IGuarded.sol
/* pragma solidity ^0.8.4; */

interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
}

////// lib/fiat/src/utils/Guarded.sol
/* pragma solidity ^0.8.4; */

/* import {IGuarded} from "../interfaces/IGuarded.sol"; */

/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded is IGuarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant override ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant override ANY_CALLER = address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _canCall[ANY_SIG][root] = false;
        emit AllowCaller(ANY_SIG, root);
    }
}

////// lib/fiat/src/utils/Math.sol
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
/* pragma solidity ^0.8.4; */

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */

////// lib/fiat/src/FIAT.sol
/* pragma solidity ^0.8.4; */

/* import "./interfaces/IFIAT.sol"; */

/* import "./utils/Guarded.sol"; */
/* import "./utils/Math.sol"; */

/// @title Fixed Income Asset Token (FIAT)
/// @notice `FIAT` is the protocol's stable asset which can be redeemed for `Credit` via `Moneta`
contract FIAT is Guarded, IFIAT {
    /// ======== Custom Errors ======== ///

    error FIAT__transferFrom_insufficientBalance();
    error FIAT__transferFrom_insufficientAllowance();
    error FIAT__burn_insufficientBalance();
    error FIAT__burn_insufficientAllowance();
    error FIAT__permit_ownerIsZero();
    error FIAT__permit_invalidOwner();
    error FIAT__permit_deadline();

    /// ======== Storage ======== ///

    /// @notice Name of the token
    string public constant override name = "Fixed Income Asset Token";
    /// @notice Symbol of the token
    string public constant override symbol = "FIAT";
    /// @notice Version of the token contract. Used by `permit`.
    string public constant override version = "1";
    /// @notice Uses WAD precision
    uint8 public constant override decimals = 18;
    /// @notice Amount of tokens in existence [wad]
    uint256 public override totalSupply;

    /// @notice Amount of tokens owned by `Account`
    /// @dev Account => Balance [wad]
    mapping(address => uint256) public override balanceOf;
    /// @notice Remaining amount of tokens that `spender` will be allowed to spend on behalf of `owner`
    /// @dev Owner => Spender => Allowance [wad]
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice Current nonce for `owner`. This value must be included whenever a signature is generated for `permit`.
    /// @dev Account => nonce
    mapping(address => uint256) public override nonces;

    /// @notice Domain Separator used in the encoding of the signature for `permit`, as defined by EIP712 and EIP2612
    bytes32 public immutable override DOMAIN_SEPARATOR;
    /// @notice Hash of the permit data structure. Used to verify the callers signature for `permit`,
    /// as defined by EIP2612.
    bytes32 public immutable override PERMIT_TYPEHASH;

    /// ======== Events ======== ///

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor() Guarded() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
        PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    }

    /// ======== ERC20 ======== ///

    /// @notice Transfers `amount` tokens from the caller's account to `to`
    /// @dev Boolean value indicating whether the operation succeeded
    /// @param to Address of the recipient
    /// @param amount Amount of tokens to transfer [wad]
    function transfer(address to, uint256 amount) external override returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    /// @notice Transfers `amount` tokens from `from` to `to` using the allowance mechanism
    /// `amount` is then deducted from the caller's allowance
    /// @dev Boolean value indicating whether the operation succeeded
    /// @param from Address of the sender
    /// @param to Address of the recipient
    /// @param amount Amount of tokens to transfer [wad]
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (from != msg.sender) {
            uint256 allowance_ = allowance[from][msg.sender];
            if (allowance_ != type(uint256).max) {
                if (allowance_ < amount) revert FIAT__transferFrom_insufficientAllowance();
                allowance[from][msg.sender] = sub(allowance_, amount);
            }
        }

        if (balanceOf[from] < amount) revert FIAT__transferFrom_insufficientBalance();
        balanceOf[from] = sub(balanceOf[from], amount);
        unchecked {
            // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens
    /// @param spender Address of the spender
    /// @param amount Amount of tokens the spender is allowed to spend
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// ======== Minting and Burning ======== ///

    /// @notice Increases the totalSupply by `amount` and transfers the new tokens to `to`
    /// @dev Sender has to be allowed to call this method
    /// @param to Address to which tokens should be credited to
    /// @param amount Amount of tokens to be minted [wad]
    function mint(address to, uint256 amount) external override checkCaller {
        totalSupply = add(totalSupply, amount);
        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    /// @notice Decreases the totalSupply by `amount` and using the tokens from `from`
    /// @dev If `from` is not the caller, caller needs to have sufficient allowance from `from`,
    /// `amount` is then deducted from the caller's allowance
    /// @param from Address from which tokens should be burned from
    /// @param amount Amount of tokens to be burned [wad]
    function burn(address from, uint256 amount) external override {
        if (from != msg.sender) {
            uint256 allowance_ = allowance[from][msg.sender];
            if (allowance_ != type(uint256).max) {
                if (allowance_ < amount) revert FIAT__transferFrom_insufficientAllowance();
                allowance[from][msg.sender] = sub(allowance_, amount);
            }
        }

        uint256 balance = balanceOf[from];
        if (balance < amount) revert FIAT__burn_insufficientBalance();
        balanceOf[from] = sub(balance, amount);

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    /// ======== EIP2612 ======== ///

    /// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval
    /// @dev Check that the `owner` cannot is not zero, that `deadline` is greater than the current block.timestamp
    /// and that the signature uses the `owner`'s current nonce
    /// @param owner Address of the owner who sets allowance for `spender`
    /// @param spender Address of the spender for is given allowance to
    /// @param value Amount of tokens the `spender` is allowed to spend
    /// @param v From the secp256k1 signature
    /// @param r From the secp256k1 signature
    /// @param s From the secp256k1 signature
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    // owner's nonce which cannot realistically overflow
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            if (owner == address(0)) revert FIAT__permit_ownerIsZero();
            if (owner != ecrecover(digest, v, r, s)) revert FIAT__permit_invalidOwner();
            if (block.timestamp > deadline) revert FIAT__permit_deadline();

            allowance[owner][spender] = value;
            emit Approval(owner, spender, value);
        }
    }
}