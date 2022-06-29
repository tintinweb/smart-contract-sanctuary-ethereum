// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "solmate/tokens/ERC20.sol";

import "../src/ERC20PermitEverywhere.sol";

interface IUniswapV2Router {
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        returns (uint256[] memory amounts);
}

contract TestUni2Router {
    IUniswapV2Router public immutable ROUTER;
    ERC20PermitEverywhere public immutable PERMIT_EVERYWHERE;

    constructor(IUniswapV2Router router, ERC20PermitEverywhere pe) {
        ROUTER = router;
        PERMIT_EVERYWHERE = pe;
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address payable to,
        uint256 deadline,
        ERC20PermitEverywhere.PermitTransferFrom memory permit,
        ERC20PermitEverywhere.Signature memory permitSig
    )
        external
        returns (uint256[] memory amounts)
    {
        require(path[0] == address(permit.token), 'WRONG_PERMIT_TOKEN');
        PERMIT_EVERYWHERE.executePermitTransferFrom(
            msg.sender,
            address(this),
            amountIn,
            permit,
            permitSig
        );
        ERC20(permit.token).approve(address(ROUTER), type(uint256).max);
        amounts = ROUTER.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

/// @title ERC20PermitEverywhere
/// @notice Enables permit-style approvals for all ERC20 tokens,
/// regardless of whether they implement EIP2612 or not.
contract ERC20PermitEverywhere {
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable TRANSFER_PERMIT_TYPEHASH;

    // Permit message to be consumed by executePermitTransferFrom().
    struct PermitTransferFrom {
        // The token being spent.
        address token;
        // Who is allowed to execute/burn the permit message.
        address spender;
        // The maximum amount of `token` `spender` can transfer.
        uint256 maxAmount;
        // The timestamp beyond which this permit is no longer valid.
        uint256 deadline;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice The current nonce for a signer. This value will be incremented
    ///         for each executed permit message.
    /// @dev Owner -> current nonce.
    mapping(address => uint256) public currentNonce;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            keccak256(bytes('ERC20PermitEverywhere')),
            keccak256('1.0.0'),
            block.chainid,
            address(this)
        ));
        TRANSFER_PERMIT_TYPEHASH =
            keccak256('PermitTransferFrom(address token,address spender,uint256 maxAmount,uint256 deadline,uint256 nonce)');
    }

    /// @notice Increase sender's nonce by `increaseAmount`. This will effectively
    ///         cancel any outstanding permits signed with a nonce lower than the
    ///         final value.
    function increaseNonce(uint256 increaseAmount) external {
        currentNonce[msg.sender] += increaseAmount;
    }

    /// @notice Execute a signed permit message to transfer ERC20 tokens
    ///         on behalf of the signer. The signer's nonce will be incremented
    ///         during execution, preventing the message from being used again.
    /// @param from Permit signer.
    /// @param to Recipient of tokens.
    /// @param amount Amount of tokens to transfer (may be less than permit amount).
    /// @param permit Permit message.
    /// @param sig Signature for permit message, signed by `from`.
    function executePermitTransferFrom(
        address from,
        address to,
        uint256 amount,
        PermitTransferFrom calldata permit,
        Signature calldata sig
    )
        external
    {
        require(msg.sender == permit.spender, 'SPENDER_NOT_PERMITTED');
        require(permit.deadline >= block.timestamp, 'PERMIT_EXPIRED');
        require(permit.maxAmount >= amount, 'EXCEEDS_PERMIT_AMOUNT');

        // Unchecked because the only math done is incrementing
        // the nonce which cannot realistically overflow.
        unchecked {
            require(
                from == _getSigner(hashPermit(permit, currentNonce[from]++), sig),
                'INVALID_SIGNER'
            );
        }

        _transferFrom(permit.token, from, to, amount);
    }

    /// @notice Compute the EIP712 hash of a permit message.
    function hashPermit(PermitTransferFrom memory permit, uint256 nonce)
        public
        view
        returns (bytes32 hash)
    {
        bytes32 domainSeparator = DOMAIN_SEPARATOR;
        bytes32 typeHash = TRANSFER_PERMIT_TYPEHASH;
        assembly {
            // Hash the permit message in-place to compute the struct hash.
            if lt(permit, 0x20)  {
                invalid()
            }
            // Overwrite the words above and below the permit object temporarily.
            let wordAbove := mload(sub(permit, 0x20))
            let wordBelow := mload(add(permit, 0x80))
            mstore(sub(permit, 0x20), typeHash)
            mstore(add(permit, 0x80), nonce)
            let structHash := keccak256(sub(permit, 0x20), 0xC0)
            // Restore overwritten words.
            mstore(sub(permit, 0x20), wordAbove)
            mstore(add(permit, 0x80), wordBelow)

            // 0x40 will be overwritten temporarily.
            let memPointer := mload(0x40)
            // Hash the domain separator and struct hash to compute the final EIP712 hash.
            mstore(0x00, 0x1901000000000000000000000000000000000000000000000000000000000000)
            mstore(0x02, domainSeparator)
            mstore(0x22, structHash)
            hash := keccak256(0x00, 0x42)
            // Restore 0x40.
            mstore(0x40, memPointer)
        }
    }

    function _getSigner(bytes32 hash, Signature calldata sig) private pure returns (address signer) {
        signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer != address(0), 'INVALID_SIGNATURE');
    }

    function _transferFrom(address token, address from, address to, uint256 amount) private {
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                if or(eq(mload(0x00), 0), iszero(returndatasize())) {
                    mstore(0x00, hex"08c379a0") // Function selector of the error method.
                    mstore(0x04, 0x20) // Offset of the error string.
                    mstore(0x24, 26) // Length of the error string.
                    mstore(0x44, "ERC20_TRANSFER_FROM_FAILED") // The error string.
                    revert(0x00, 0x64) // Revert with (offset, size).
                }
                // Bubble up revert data if present.
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}