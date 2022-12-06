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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.17 <0.9.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

/// @title Multi Split - Allows to batch multiple split swap transactions into one.
/// @notice Based on Gnosis MultiSend v1.1.1 (https://etherscan.io/address/0x8d29be29923b68abfdd21e541b9374737b49cdad#code)
/// @author Sandy Bradley - <@sandybradley>
contract MultiSplit {
    using SafeTransferLib for ERC20;

    /// @notice Split Swap Router address
    address public ROUTER;
    /// @dev Governence for sweeping dust
    address internal GOV;
    /// @dev max uint256 for approvals
    uint256 internal constant MAX_UINT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    error ExecuteNotAuthorized();

    constructor(address router) {
        ROUTER = router;
        GOV = tx.origin;
    }

    /// @dev Sends multiple transactions, allowing fails.
    ///      NB assumes all swaps originate from same token / eth to save multiple transfer gas fees
    /// @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
    ///                     value as a uint256 (=> 32 bytes),
    ///                     data length as a uint256 (=> 32 bytes),
    ///                     data as bytes.
    ///                     see abi.encodePacked for more information on packed encoding
    function multiSplit(bytes memory transactions) external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // ERC20 helper functions
            function allowance(token0) -> tokenAllowance {
                let pos := mload(0x40) // free memory pointer
                mstore(pos, add(pos, 68)) // allocate memory
                mstore(pos, shl(224, 0xdd62ed3e)) // store allowance sig
                mstore(add(pos, 0x04), address()) // store owner address
                mstore(
                    add(pos, 0x24),
                    and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                ) // store spender address
                let success := staticcall(gas(), token0, pos, 68, pos, 0x20) // call allowance of token0 for router
                tokenAllowance := mload(pos)
            }

            function balanceOf(token0) -> bal {
                let pos := mload(0x40) // free memory pointer
                mstore(pos, add(pos, 36)) // allocate memory
                mstore(pos, shl(224, 0x70a08231)) // store balanceof sig
                mstore(add(pos, 0x04), address()) // store address
                let success := staticcall(gas(), token0, pos, 36, pos, 0x20) // call balance of token0 at this address
                bal := mload(pos)
            }

            function approve(token0, amount) {
                let pos := mload(0x40) // free memory pointer
                mstore(pos, add(pos, 68)) // allocate memory
                mstore(pos, shl(224, 0x095ea7b3)) // store approve sig
                mstore(
                    add(pos, 0x04),
                    and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                ) // store spender address
                mstore(add(pos, 0x24), amount) // store amount
                let success := call(gas(), token0, 0, pos, 68, 0, 0) // call approve 0 of token0 for router
            }

            function transferFrom(token0, amountIn) {
                let pos := mload(0x40) // free memory pointer
                mstore(pos, add(pos, 100)) // allocate memory
                mstore(pos, shl(224, 0x23b872dd)) // store transferFrom sig
                mstore(add(pos, 0x04), caller()) // store sender address
                mstore(add(pos, 0x24), address()) // store recipient address
                mstore(add(pos, 0x44), amountIn) // store amount
                let success := call(gas(), token0, 0, pos, 100, 0, 0) // call transferFrom of token0 to this address
                if iszero(success) {
                    revert(0, 0)
                }
            }

            function transfer(token0, amount) {
                let pos := mload(0x40) // free memory pointer
                mstore(pos, add(pos, 68)) // allocate memory
                mstore(pos, shl(224, 0xa9059cbb)) // store transfer sig
                mstore(add(pos, 0x04), caller()) // store address
                mstore(add(pos, 0x24), amount) // store amount
                let success := call(gas(), token0, 0, pos, 68, 0, 0) // call transfer token0 to sender
            }

            let bal := 0
            let token0 := 0
            let amountIn := 0
            let length := mload(transactions)
            let i := 0x20
            // assume all txs have same origin token
            // i.e. either eth or a single token
            // get initial tokens / eth and record balance
            // assure approve allowance is good
            switch iszero(iszero(callvalue()))
            case 1 {
                bal := balance(address()) // eth balance
            }
            default {
                for {
                    // Pre block is not used in "while mode"
                } lt(i, length) {
                    // Post block is not used in "while mode"
                } {
                    let data := add(transactions, add(i, 0x40))
                    // extract token0 and amountIn from data
                    amountIn := add(amountIn, mload(add(data, 0x04))) // amountIn at slot 1 of data (offset = 4)
                    if iszero(token0) {
                        token0 := mload(add(data, 0xC4)) // token0 at slot 7 of data (offset = 6 * 32 = 196 = 0xC4)
                    }
                    // Next entry starts at 0x40 byte + data length
                    i := add(i, add(0x40, mload(add(transactions, add(i, 0x20)))))
                }
                // transfer token0 to this contract
                transferFrom(token0, amountIn)
                // check token balance
                bal := balanceOf(token0) // token0 balance
                // check router allowance
                let tokenAllowance := allowance(token0)
                if gt(amountIn, tokenAllowance) {
                    // if allowance greater than 0, be safe and reset to 0 first (for usdt etc)
                    if iszero(iszero(tokenAllowance)) {
                        approve(token0, 0)
                    }
                    // set to max
                    approve(token0, MAX_UINT)
                }
            }

            //  run swaps
            i := 0x20
            for {
                // Pre block is not used in "while mode"
            } lt(i, length) {
                // Post block is not used in "while mode"
            } {
                let dataLength := mload(add(transactions, add(i, 0x20)))
                let success := call(
                    gas(), // gas left
                    and(sload(0), 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), // router
                    mload(add(transactions, i)), // value
                    add(transactions, add(i, 0x40)), // input data (0x(4 byte func sig hash)(abi encoded args))
                    dataLength, // input data byte length
                    0, // output
                    0 // output byte length
                )
                // Next entry starts at 0x40 byte + data length
                i := add(i, add(0x40, dataLength))
            }

            //  refund any input dust
            switch iszero(iszero(callvalue()))
            case 1 {
                if gt(balance(address()), sub(bal, callvalue())) {
                    // refund any dust
                    let success := call(gas(), caller(), sub(balance(address()), sub(bal, callvalue())), 0, 0, 0, 0)
                }
            }
            default {
                let newBal := balanceOf(token0) // re-assign value as tokenBal2
                if gt(newBal, sub(bal, amountIn)) {
                    // transfer dust
                    transfer(token0, sub(newBal, sub(bal, amountIn)))
                }
            }
        }
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function changeGov(address newGov) external {
        if (msg.sender != GOV) revert ExecuteNotAuthorized();
        GOV = newGov;
    }

    function changeRouter(address newRouter) external {
        if (msg.sender != GOV) revert ExecuteNotAuthorized();
        ROUTER = newRouter;
    }

    /// @notice Sweep dust tokens and eth to recipient
    /// @param tokens Array of token addresses
    /// @param recipient Address of recipient
    function sweep(address[] calldata tokens, address recipient) external {
        if (msg.sender != GOV) revert ExecuteNotAuthorized();
        for (uint256 i; i < tokens.length; i++) {
            address token = tokens[i];
            ERC20(token).safeTransfer(recipient, ERC20(token).balanceOf(address(this)));
        }
        SafeTransferLib.safeTransferETH(recipient, address(this).balance);
    }
}