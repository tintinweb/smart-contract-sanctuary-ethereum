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
pragma solidity ^0.8.0;

library Errors {
    error OnlyKeeper();
    error TokenAlreadyAdded();
    error TokenNotAdded();
    error ZeroAddress();
    error InvalidBounds();
}

interface ITornadoVault {
    struct TokenRule {
        address token;
        bool disabled;
        uint256 lowerBound;
        uint256 upperBound;
    }

    struct ActionToken {
        address token;
        Action action;
        uint256 amount;
    }

    struct PodNonce {
        uint128 right;
        uint128 left;
    }

    event AddTokenRule(address indexed token, uint256 lowerBound, uint256 upperBound);
    event UpdateTokenRule(
        address indexed token,
        bool disabled,
        uint256 lowerBound,
        uint256 upperBound
    );
    event SetLimit(uint256 limit);
    event UpdateVaultBalance(
        address indexed token,
        Action indexed action,
        address pod,
        uint256 amount
    );

    enum Action {
        LOAD,
        UNLOAD
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ITornadoVault, Errors } from "./ITornadoVault.sol";
import { AutomationBase } from "./utils/AutomationBase.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

/// @title TornadoVault
/// @author regohiro
contract TornadoVault is ITornadoVault, AutomationBase {
    using SafeTransferLib for ERC20;

    // Multi-transaction limit
    uint256 public limit;
    // Chainlink keeper address
    address public immutable keeper;

    // List of token rules
    TokenRule[] private _tokenRules;
    // Index of token address in _tokenRules[]
    mapping(address => uint256) private _tokenIndex;
    // Left, right nonce of token pods
    mapping(address => PodNonce) private _podNonce;

    /// @notice Constructor
    /// @param limit_ Upper limit of token balance to update
    /// @param keeper_ Chainlink keeper address
    constructor(uint256 limit_, address keeper_) {
        limit = limit_;
        keeper = keeper_;

        // Skip the 0th slot of _tokenIndex array
        assembly {
            sstore(_tokenRules.slot, 1)
        }
    }

    /// @notice View function to return token rule
    /// @param token Address of the token
    /// @return Token rule struct
    function tokenRule(address token) external view returns (TokenRule memory) {
        return _tokenRules[_getTokenIndex(token)];
    }

    /// @notice View function to return left and right nonces of token pods
    /// @param token Address of the token
    /// @return (left nonce, right nonce)
    function nonceOf(address token) external view returns (uint128, uint128) {
        return (_podNonce[token].left, _podNonce[token].right);
    }

    /// @notice Add new token rule
    /// @param token Address of the token
    /// @param lowerBound .
    /// @param upperBound .
    function addTokenRule(
        address token,
        uint256 lowerBound,
        uint256 upperBound
    ) external {
        if (token == address(0)) revert Errors.ZeroAddress();
        if (lowerBound > upperBound) revert Errors.InvalidBounds();
        if (_tokenIndex[token] != 0) revert Errors.TokenAlreadyAdded();

        _tokenIndex[token] = _tokenRules.length;
        _tokenRules.push(TokenRule(token, false, lowerBound, upperBound));

        emit AddTokenRule(token, lowerBound, upperBound);
    }

    /// @notice Update existing token rule
    /// @param token Address of the token
    /// @param disabled .
    /// @param lowerBound .
    /// @param upperBound .
    function updateTokenRule(
        address token,
        bool disabled,
        uint256 lowerBound,
        uint256 upperBound
    ) external {
        if (lowerBound >= upperBound) revert Errors.InvalidBounds();

        _tokenRules[_getTokenIndex(token)] = TokenRule(token, disabled, lowerBound, upperBound);

        emit UpdateTokenRule(token, disabled, lowerBound, upperBound);
    }

    /// @notice Update limit
    /// @param limit_ New limit
    function setLimit(uint256 limit_) external {
        limit = limit_;

        emit SetLimit(limit);
    }

    function checkUpKeep(bytes calldata) external view cannotExecute returns (bool, bytes memory) {
        uint256 len = _tokenRules.length;
        uint256 num = 0;

        ActionToken[] memory actionTokens = new ActionToken[](len < limit ? len : limit);

        for (uint256 i = 1; i < len && num < limit; i++) {
            if (_tokenRules[i].disabled) {
                continue;
            }

            address token = _tokenRules[i].token;
            uint256 balance = ERC20(token).balanceOf(address(this));
            if (balance > _tokenRules[i].upperBound) {
                actionTokens[num++] = ActionToken(
                    token,
                    Action.UNLOAD,
                    (_tokenRules[i].upperBound - _tokenRules[i].lowerBound) / 2
                );
            } else if (
                balance < _tokenRules[i].lowerBound &&
                _podNonce[token].left < _podNonce[token].right
            ) {
                uint256 salt = _podNonce[token].left;
                bytes memory bytecode = abi.encodePacked(
                    _podCreationCode(),
                    abi.encode(address(token))
                );
                address pod = _computeAddress(bytecode, salt);
                actionTokens[num++] = ActionToken(token, Action.LOAD, ERC20(token).balanceOf(pod));
            }
        }

        if (num == 0) {
            return (false, "0x");
        }

        assembly {
            mstore(actionTokens, num)
        }
        return (true, abi.encode(actionTokens));
    }

    function performUpkeep(bytes calldata performData) external {
        ActionToken[] memory actionTokens = abi.decode(performData, (ActionToken[]));

        for (uint256 i = 0; i < actionTokens.length; i++) {
            address token = actionTokens[i].token;
            address pod;
            if (actionTokens[i].action == Action.UNLOAD) {
                uint256 salt = _podNonce[token].right++;
                bytes memory bytecode = abi.encodePacked(
                    _podCreationCode(),
                    abi.encode(address(token))
                );

                assembly {
                    pod := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
                    if iszero(pod) {
                        revert(0, 0)
                    }
                }

                ERC20(token).safeTransfer(pod, actionTokens[i].amount);
            } else if (actionTokens[i].action == Action.LOAD) {
                bytes memory bytecode = abi.encodePacked(
                    _podCreationCode(),
                    abi.encode(address(token))
                );
                pod = _computeAddress(bytecode, _podNonce[token].left++);

                ERC20(token).safeTransferFrom(pod, address(this), actionTokens[i].amount);
            }

            emit UpdateVaultBalance(token, actionTokens[i].action, pod, actionTokens[i].amount);
        }
    }

    function _getTokenIndex(address token) private view returns (uint256 index) {
        if ((index = _tokenIndex[token]) == 0) revert Errors.TokenNotAdded();
    }

    function _podCreationCode() private pure returns (bytes memory) {
        return
            hex"63095ea7b3600052336020526000196040526020803803606039602060006060601c826060515af161003057600080fd5b600080603a3d393df3";
    }

    function _computeAddress(bytes memory bytecode, uint256 salt) private view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        return address(uint160(uint256(hash)) & type(uint160).max);
    }

    modifier onlyKeeper() {
        if (msg.sender != keeper) revert Errors.OnlyKeeper();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
    error OnlySimulatedBackend();

    /**
     * @notice method that allows it to be simulated via eth_call by checking that
     * the sender is the zero address.
     */
    function preventExecution() internal view {
        if (tx.origin != address(0)) {
            revert OnlySimulatedBackend();
        }
    }

    /**
     * @notice modifier that allows it to be simulated via eth_call by checking
     * that the sender is the zero address.
     */
    modifier cannotExecute() {
        preventExecution();
        _;
    }
}