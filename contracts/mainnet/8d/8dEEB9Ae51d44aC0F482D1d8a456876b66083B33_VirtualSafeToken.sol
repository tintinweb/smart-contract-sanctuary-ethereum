/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Enum - Collection of enums used in Safe contracts.
 * @author Richard Meissner - @rmeissner
 */
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     * See the corresponding EIP section
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

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

/// @title Virtual Safe Token.
/// @author z0r0z.eth
/// @custom:coauthor ellie.lens
/// @notice Makes Safe Token (SAFE) opt-in transferable via tx guard.
/// Users can mint vSAFE equal to their SAFE while it is paused.
/// SAFE can be reclaimed from vSAFE pool by burning vSAFE.
contract VirtualSafeToken is BaseGuard, ERC20("Virtual Safe Token", "vSAFE", 18) {
    /// @dev Canonical deployment of SAFE on Ethereum.
    address internal constant safeToken = 0x5aFE3855358E112B5647B952709E6165e1c1eEEe;

    /// @dev Internal flag to ensure this guard is enabled.
    uint256 internal guardCheck = 1;

    /// @dev Tracks mint claims by Safes.
    mapping(address safe => bool mint) public minted;

    /// @dev We can cut 10 opcodes in the creation-time
    /// EVM bytecode by declaring constructor payable.
    constructor() payable {}

    /// @dev Fetches whether SAFE is paused.
    function paused() public view returns (bool) {
        return VirtualSafeToken(safeToken).paused();
    }

    /// @dev Mints unclaimed vSAFE to SAFE holders.
    function mint(address to) public payable {
        // Ensure this call is by guarded Safe.
        require(guardCheck == 2, "UNGUARDED");

        // Reset guard value.
        guardCheck = 1;

        // Ensure no mint during transferable period.
        require(paused(), "UNPAUSED");

        // Ensure that SAFE custody is given to vSAFE to fund reclaiming.
        require(VirtualSafeToken(safeToken).allowance(msg.sender, address(this)) == type(uint256).max, "UNAPPROVED");

        // Ensure no double mint and mint vSAFE per SAFE balance.
        if (minted[msg.sender] = true == !minted[msg.sender]) {
            _mint(to, ERC20(safeToken).balanceOf(msg.sender));
        } else revert("MINTED");
    }

    /// @dev Burn an amount of vSAFE.
    function burn(uint256 amount) public payable {
        _burn(msg.sender, amount);
    }

    /// @dev Burn an amount of vSAFE to reclaim SAFE.
    function reclaim(address from, uint256 amount) public payable {
        VirtualSafeToken(safeToken).transferFrom(from, msg.sender, amount);

        _burn(msg.sender, amount);
    }

    /// @dev Called by a Safe contract before a transaction is executed.
    /// @param to Destination address of the Safe transaction.
    function checkTransaction(
        address to,
        uint256,
        bytes memory,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    )
        external
        override
    {
        // Ensure mint by guarded Safe.
        if (to == address(this)) {
            guardCheck = 2;
        } else {
            // Ensure no callbacks or calls to SAFE.
            require(to != msg.sender, "RESTRICTED");
            require(to != safeToken, "RESTRICTED");
        }
    }

    /// @dev Placeholder for after-execution check in Safe guard.
    function checkAfterExecution(bytes32, bool) external view override {}
}