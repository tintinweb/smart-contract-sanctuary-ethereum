// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Voucher} from "./Voucher.sol";

contract AMM is ReentrancyGuard {

    ///@notice The bridged token A.
    ERC20 public tokenA;
    ///@notice The bridged token B.
    ERC20 public tokenB;
    /// @dev The vouchers are ERC20 emitted whenever swapping in token A or B
    /// @dev and can be redeemed for the L1 tokens.
    Voucher public voucherA;
    Voucher public voucherB;

    uint256 public reserveA; // initially should be set with the L1 data
    uint256 public reserveB; // initially should be set with the L1 data

    /// @notice The L1 address of the token Voucher A represents.
    address public L1AddressForA;
    /// @notice The L1 address of the token Voucher B represents.
    address public L1AddressForB;


    constructor(
        bytes memory dataA,
        bytes memory dataB
    ) {
        (
            address voucherA2L1, // L1 address of the token the voucher represents
            address L2TokenA, // L2 address of the L2 bridged token 
            string memory vAName,
            string memory vASymbol,
            uint8 vADecimals
        ) = abi.decode(dataA, (address, address, string, string, uint8));
        voucherA = new Voucher(vAName, vASymbol, vADecimals);
        tokenA = ERC20(L2TokenA);
        L1AddressForA = voucherA2L1;

        (
            address voucherB2L1,
            address L2TokenB,
            string memory vBName,
            string memory vBSymbol,
            uint8 vBDecimals
        ) = abi.decode(dataB, (address, address, string, string, uint8));
        voucherB = new Voucher(vBName, vBSymbol, vBDecimals);
        tokenB = ERC20(L2TokenB);
        L1AddressForB = voucherB2L1;
    }

    // / @notice Swaps voucher A/B for voucher B/A.
    // / @param isVoucherAIn if the voucher we swap in is the A.
    // / @param amountIn the amount of the voucher we swap in.
    // / @return amountOut the amount of the voucher we swap out.
    // function swap(bool isVoucherAIn, uint256 amountIn) nonReentrant external returns (uint256 amountOut) {
    //     require(amountIn > 0);
    //     (
    //         Voucher tokenIn,
    //         Voucher tokenOut,
    //         uint256 reserveIn,
    //         uint256 reserveOut
    //     ) = isVoucherAIn ? (voucherA, voucherB, reserveA, reserveB) : (voucherB, voucherA, reserveB, reserveA);
    //     tokenIn.transferFrom(msg.sender, address(this), amountIn);
    //     amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    //     tokenOut.transfer(msg.sender, amountOut);

    //     // update reserves
    //     if (isVoucherAIn) {
    //         reserveA += amountIn;
    //         reserveB -= amountOut;
    //     } else {
    //         reserveA -= amountOut;
    //         reserveB += amountIn;
    //     }
    // }

    function swap(uint256 amountAIn, uint256 amountBIn) nonReentrant external returns (uint256 amountOut) {
        require(amountAIn > 0 || amountBIn > 0, "Amounts are 0");
        (
            Voucher tokenIn,
            Voucher tokenOut,
            uint256 amountIn,
            uint256 reserveIn,
            uint256 reserveOut
        ) = amountAIn > 0 ? (voucherA, voucherB, amountAIn, reserveA, reserveB) : (voucherB, voucherA, amountBIn, reserveB, reserveA);
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        tokenOut.transfer(msg.sender, amountOut);

        // update reserves
        if (amountAIn > 0) {
            reserveA += amountAIn;
            reserveB -= amountOut;
        } else {
            reserveA -= amountOut;
            reserveB += amountBIn;
        }
    }

    function convert(bool isTokenA, uint256 amount) external {
        (ERC20 tokenToSwap, Voucher tokenToMint) = isTokenA ? (tokenA, voucherA) : (tokenB, voucherB);
        tokenToSwap.transferFrom(msg.sender, address(this), amount);
        tokenToMint.mint(msg.sender, amount);
    }

    function sync(uint256 newReserveA, uint256 newReserveB) external {
        // should be authenticated call
        reserveA = newReserveA;
        reserveB = newReserveB;
    }
}

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

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

/// @notice A voucher ERC20 to represent a L1 token.
/// @notice Can be burned to redeem the token on the L1.
contract Voucher is ERC20, Owned {

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    )
    ERC20(_name, _symbol, _decimals)
    Owned(msg.sender)
    {
        /// only the minter, which should be the AMM, can mint and burn
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}