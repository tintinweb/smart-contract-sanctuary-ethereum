// SPDX-License-Identifier: BSD
pragma solidity ^0.8.4;

/// @title Clone
/// @author zefram.eth
/// @notice Provides helper functions for reading immutable args from calldata
contract Clone {
    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgAddress(uint256 argOffset)
        internal
        pure
        returns (address arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint256(uint256 argOffset)
        internal
        pure
        returns (uint256 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @notice Reads a uint256 array stored in the immutable args.
    /// @param argOffset The offset of the arg in the packed data
    /// @param arrLen Number of elements in the array
    /// @return arr The array
    function _getArgUint256Array(uint256 argOffset, uint64 arrLen)
        internal
        pure
      returns (uint256[] memory arr)
    {
      uint256 offset = _getImmutableArgsOffset();
      uint256 el;
      arr = new uint256[](arrLen);
      for (uint64 i = 0; i < arrLen; i++) {
        assembly {
          // solhint-disable-next-line no-inline-assembly
          el := calldataload(add(add(offset, argOffset), mul(i, 32)))
        }
        arr[i] = el;
      }
      return arr;
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint64(uint256 argOffset)
        internal
        pure
        returns (uint64 arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The arg value
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            offset := sub(
                calldatasize(),
                add(shr(240, calldataload(sub(calldatasize(), 2))), 2)
            )
        }
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.4;

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    error CreateFail();

    /// @notice Creates a clone proxy of the implementation contract, with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data)
        internal
        returns (address payable instance)
    {
        // unrealistic for memory ptr or data length to exceed 256 bits
        unchecked {
            uint256 extraLength = data.length + 2; // +2 bytes for telling how much data there is appended to the call
            uint256 creationSize = 0x41 + extraLength;
            uint256 runSize = creationSize - 10;
            uint256 dataPtr;
            uint256 ptr;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                ptr := mload(0x40)

                // -------------------------------------------------------------------------------------------------------------
                // CREATION (10 bytes)
                // -------------------------------------------------------------------------------------------------------------

                // 61 runtime  | PUSH2 runtime (r)     | r                       | –
                mstore(
                    ptr,
                    0x6100000000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x01), shl(240, runSize)) // size of the contract running bytecode (16 bits)

                // creation size = 0a
                // 3d          | RETURNDATASIZE        | 0 r                     | –
                // 81          | DUP2                  | r 0 r                   | –
                // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
                // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
                // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
                // f3          | RETURN                |                         | [0-runSize): runtime code

                // -------------------------------------------------------------------------------------------------------------
                // RUNTIME (55 bytes + extraLength)
                // -------------------------------------------------------------------------------------------------------------

                // 3d          | RETURNDATASIZE        | 0                       | –
                // 3d          | RETURNDATASIZE        | 0 0                     | –
                // 3d          | RETURNDATASIZE        | 0 0 0                   | –
                // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
                // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
                // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
                // 61          | PUSH2 extra           | extra 0 0 0 0           | [0, cds) = calldata
                mstore(
                    add(ptr, 0x03),
                    0x3d81600a3d39f33d3d3d3d363d3d376100000000000000000000000000000000
                )
                mstore(add(ptr, 0x13), shl(240, extraLength))

                // 60 0x37     | PUSH1 0x37            | 0x37 extra 0 0 0 0      | [0, cds) = calldata // 0x37 (55) is runtime size - data
                // 36          | CALLDATASIZE          | cds 0x37 extra 0 0 0 0  | [0, cds) = calldata
                // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 61 extra    | PUSH2 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x15),
                    0x6037363936610000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x1b), shl(240, extraLength))

                // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x37) = extraData
                mstore(
                    add(ptr, 0x1d),
                    0x013d730000000000000000000000000000000000000000000000000000000000
                )
                mstore(add(ptr, 0x20), shl(0x60, implementation))

                // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x37) = extraData
                // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
                // 60 0x35     | PUSH1 0x35            | 0x35 sucess 0 rds       | [0, rds) = return data
                // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
                // fd          | REVERT                | –                       | [0, rds) = return data
                // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
                // f3          | RETURN                | –                       | [0, rds) = return data
                mstore(
                    add(ptr, 0x34),
                    0x5af43d3d93803e603557fd5bf300000000000000000000000000000000000000
                )
            }

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength -= 2;
            uint256 counter = extraLength;
            uint256 copyPtr = ptr + 0x41;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                dataPtr := add(data, 32)
            }
            for (; counter >= 32; counter -= 32) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    mstore(copyPtr, mload(dataPtr))
                }

                copyPtr += 32;
                dataPtr += 32;
            }
            uint256 mask = ~(256**(32 - counter) - 1);
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, and(mload(dataPtr), mask))
            }
            copyPtr += counter;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(copyPtr, shl(240, extraLength))
            }
            // solhint-disable-next-line no-inline-assembly
            assembly {
                instance := create(0, ptr, creationSize)
            }
            if (instance == address(0)) {
                revert CreateFail();
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.16;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {Clone} from "clones-with-immutable-args/Clone.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
// owner (20) -> underlying (ERC20 address) ,

interface ITokenBase {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

}

interface IERC4646Base is ITokenBase {
    function underlying() external view returns (address);
}

interface IAstariaVaultBase is IERC4646Base {
    function owner() external view returns (address);
    function COLLATERAL_TOKEN() external view returns (address);
    function ROUTER() external view returns (address);
    function AUCTION_HOUSE() external view returns (address);
    function START() external view returns (uint256);
    function EPOCH_LENGTH() external view returns (uint256);
    function VAULT_TYPE() external view returns (uint8);
    function VAULT_FEE() external view returns (uint256);
}


abstract contract ERC4626Base is Clone, IERC4646Base {
    function underlying() public view virtual returns (address);
}

//abstract contract TokenBase is Clone, ITokenCloneBase {
//    function name() external virtual view returns (string memory);
//
//    function symbol() external virtual view returns (string memory);
//}
abstract contract WithdrawVaultBase is ERC4626Base {
    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function owner() public pure returns (address) {
        return _getArgAddress(0);
    }

    function underlying() virtual override(ERC4626Base) public view returns (address) {
        return _getArgAddress(20);
    }
}


abstract contract AstariaVaultBase is ERC4626Base, IAstariaVaultBase {

    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function owner() public pure returns (address) {
        return _getArgAddress(0);
    }

    function underlying() virtual override(IERC4646Base, ERC4626Base) public view returns (address) {
        return _getArgAddress(20);
    }

    function COLLATERAL_TOKEN() public view returns (address) {
        return _getArgAddress(40);
    }

    function ROUTER() public view returns (address) {
        return _getArgAddress(60);
    }

    function AUCTION_HOUSE() public view returns (address) {
        return _getArgAddress(80);
    }

    function START() public view returns (uint256) {
        return _getArgUint256(100);
    }

    function EPOCH_LENGTH() public view returns (uint256) {
        return _getArgUint256(132);
    }

    function VAULT_TYPE() public view returns (uint8) {
        return _getArgUint8(164);
    }

    function VAULT_FEE() public view returns (uint256) {
        return _getArgUint256(172);
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.

abstract contract ERC20Cloned is ITokenBase {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    uint256 _totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public nonces;


    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
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

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

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

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _mint(address to, uint256 amount) internal virtual {
        _totalSupply += amount;

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
            _totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

interface IVault {
    function deposit(uint256, address) external returns (uint256);
}

abstract contract ERC4626Cloned is ERC20Cloned, ERC4626Base, IVault {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event LogUint(string name, uint256 value);
    event LogAddress(string name,address);

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(IVault)
        returns (uint256 shares)
    {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");
        emit LogUint("assets", assets);
        emit LogUint("shares", shares);

        emit LogAddress("underlying", underlying());
        // Need to transfer before minting or ERC777s could reenter.
        ERC20(underlying()).safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver)
        public
        virtual
        returns (uint256 assets)
    {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        ERC20(underlying()).safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        ERC20(underlying()).safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        ERC20(underlying()).safeTransfer(receiver, assets);
    }

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function totalSupply() public virtual view returns (uint256) {
        return _totalSupply;
    }

    function previewRedeem(uint256 shares)
        public
        view
        virtual
        returns (uint256)
    {
        return convertToAssets(shares);
    }

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import {IERC721} from "./interfaces/IERC721.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is IERC721 {
    /*//////////////////////////////////////////////////////////////
METADATA STORAGE/LOGIC
//////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) external view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
ERC721 BALANCE/OWNER STORAGE
//////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
ERC721 APPROVAL STORAGE
//////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
CONSTRUCTOR
//////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
ERC721 LOGIC
//////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) external virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) external virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public override (IERC721) {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );
        _transfer(from, to, id);
    }

    function _transfer(address from, address to, uint256 id) internal {
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) external virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external override (IERC721) {
        transferFrom(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
ERC165 LOGIC
//////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
INTERNAL MINT/BURN LOGIC
//////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
INTERNAL SAFE MINT LOGIC
//////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

pragma solidity ^0.8.13;

pragma experimental ABIEncoderV2;

interface IAuctionHouse {
    struct Auction {
        // The current highest bid amount
        uint256 currentBid;
        // The length of time to run the auction for, after the first bid was made
        uint64 duration;
        uint64 maxDuration;
        // The time of the first bid
        uint64 firstBidTime;
        uint256 reservePrice;
        uint256[] recipients;
        address token;
        address bidder;
        address initiator;
        uint256 initiatorFee;
    }

    event AuctionCreated(uint256 indexed tokenId, uint256 duration, uint256 reservePrice);

    event AuctionReservePriceUpdated(uint256 indexed tokenId, uint256 reservePrice);

    event AuctionBid(uint256 indexed tokenId, address sender, uint256 value, bool firstBid, bool extended);

    event AuctionDurationExtended(uint256 indexed tokenId, uint256 duration);

    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 winningBid, uint256[] recipients);

    event AuctionCanceled(uint256 indexed tokenId);

    function createAuction(uint256 tokenId, uint256 duration, address initiator, uint256 initiatorFee)
        external
        returns (uint256);

    function createBid(uint256 tokenId, uint256 amount) external;

    function endAuction(uint256 tokenId) external returns (address);

    function cancelAuction(uint256 tokenId, address canceledBy) external;

    function auctionExists(uint256 tokenId) external returns (bool);

    function getAuctionData(uint256 tokenId)
        external
        view
        returns (uint256 amount, uint256 duration, uint256 firstBidTime, uint256 reservePrice, address bidder);
}

pragma solidity ^0.8.16;

import {IERC165} from "../../../../src/interfaces/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

pragma solidity ^0.8.13;

interface ITransferProxy {
    function tokenTransferFrom(address token, address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
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

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
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

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 *
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

pragma experimental ABIEncoderV2;

import {Auth, Authority} from "solmate/auth/Auth.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {ERC721} from "gpl/ERC721.sol";
import {IAuctionHouse} from "gpl/interfaces/IAuctionHouse.sol";
import {IERC721, IERC165} from "gpl/interfaces/IERC721.sol";
import {ITransferProxy} from "gpl/interfaces/ITransferProxy.sol";
import {SafeCastLib} from "gpl/utils/SafeCastLib.sol";

import {Base64} from "./libraries/Base64.sol";
import {CollateralLookup} from "./libraries/CollateralLookup.sol";

import {IAstariaRouter} from "./interfaces/IAstariaRouter.sol";
import {ICollateralToken} from "./interfaces/ICollateralToken.sol";
import {ILienBase, ILienToken} from "./interfaces/ILienToken.sol";

import {IPublicVault} from "./PublicVault.sol";
import {VaultImplementation} from "./VaultImplementation.sol";

contract TransferAgent {
  address public immutable WETH;
  ITransferProxy public immutable TRANSFER_PROXY;

  constructor(ITransferProxy _TRANSFER_PROXY, address _WETH) {
    TRANSFER_PROXY = _TRANSFER_PROXY;
    WETH = _WETH;
  }
}

/**
 * @title LienToken
 * @author androolloyd
 * @notice This contract handles the creation, payments, buyouts, and liquidations of tokenized NFT-collateralized debt (liens). Vaults which originate loans against supported collateral are issued a LienToken representing the right to loan repayments and auctioned funds on liquidation.
 */
contract LienToken is ERC721, ILienToken, Auth, TransferAgent {
  using FixedPointMathLib for uint256;
  using CollateralLookup for address;
  using SafeCastLib for uint256;

  IAuctionHouse public AUCTION_HOUSE;
  IAstariaRouter public ASTARIA_ROUTER;
  ICollateralToken public COLLATERAL_TOKEN;

  uint256 INTEREST_DENOMINATOR = 1e18; //wad per second

  uint256 constant MAX_LIENS = uint256(5);

  mapping(uint256 => Lien) public lienData;
  mapping(uint256 => uint256[]) public liens;

  /**
   * @dev Setup transfer authority and initialize the buyoutNumerator and buyoutDenominator for the lien buyout premium.
   * @param _AUTHORITY The authority manager.
   * @param _TRANSFER_PROXY The TransferProxy for balance transfers.
   * @param _WETH The WETH address to use for transfers.
   */
  constructor(
    Authority _AUTHORITY,
    ITransferProxy _TRANSFER_PROXY,
    address _WETH
  )
    Auth(address(msg.sender), _AUTHORITY)
    TransferAgent(_TRANSFER_PROXY, _WETH)
    ERC721("Astaria Lien Token", "ALT")
  {}

  /**
   * @notice Sets addresses for the AuctionHouse, CollateralToken, and AstariaRouter contracts to use.
   * @param what The identifier for what is being filed.
   * @param data The encoded address data to be decoded and filed.
   */
  function file(bytes32 what, bytes calldata data) external requiresAuth {
    if (what == "setAuctionHouse") {
      address addr = abi.decode(data, (address));
      AUCTION_HOUSE = IAuctionHouse(addr);
    } else if (what == "setCollateralToken") {
      address addr = abi.decode(data, (address));
      COLLATERAL_TOKEN = ICollateralToken(addr);
    } else if (what == "setAstariaRouter") {
      address addr = abi.decode(data, (address));
      ASTARIA_ROUTER = IAstariaRouter(addr);
    } else {
      revert UnsupportedFile();
    }
    emit File(what, data);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(ILienToken).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @notice Purchase a LienToken for its buyout price.
   * @param params The LienActionBuyout data specifying the lien position, receiver address, and underlying CollateralToken information of the lien.
   */

  function buyoutLien(ILienToken.LienActionBuyout calldata params) external {
    (bool valid, IAstariaRouter.LienDetails memory ld) = ASTARIA_ROUTER
      .validateCommitment(params.incoming);

    if (!valid) {
      revert InvalidTerms();
    }

    uint256 collateralId = params.incoming.tokenContract.computeId(
      params.incoming.tokenId
    );
    (uint256 owed, uint256 buyout) = getBuyout(collateralId, params.position);
    uint256 lienId = liens[collateralId][params.position];

    //the borrower shouldn't incur more debt from the buyout than they already owe
    if (ld.maxAmount < owed) {
      revert InvalidBuyoutDetails(ld.maxAmount, owed);
    }
    if (!ASTARIA_ROUTER.isValidRefinance(lienData[lienId], ld)) {
      revert InvalidRefinance();
    }

    TRANSFER_PROXY.tokenTransferFrom(
      WETH,
      address(msg.sender),
      getPayee(lienId),
      uint256(buyout)
    );

    lienData[lienId].last = block.timestamp.safeCastTo32();
    lienData[lienId].start = block.timestamp.safeCastTo32();
    lienData[lienId].rate = ld.rate.safeCastTo240();
    lienData[lienId].duration = ld.duration.safeCastTo32();

    _transfer(ownerOf(lienId), address(params.receiver), lienId);
  }

  /**
   * @notice Public view function that computes the interest for a LienToken since its last payment.
   * @param collateralId The ID of the underlying CollateralToken
   * @param position The position of the lien to calculate interest for.
   */
  function getInterest(uint256 collateralId, uint256 position)
    public
    view
    returns (uint256)
  {
    uint256 lien = liens[collateralId][position];
    return _getInterest(lienData[lien], block.timestamp);
  }

  /**
   * @dev Computes the interest accrued for a lien since its last payment.
   * @param lien The Lien for the loan to calculate interest for.
   * @param timestamp The timestamp at which to compute interest for.
   */
  function _getInterest(Lien memory lien, uint256 timestamp)
    internal
    view
    returns (uint256)
  {
    if (!lien.active) {
      return uint256(0);
    }
    uint256 delta_t;
    if (block.timestamp >= lien.start + lien.duration) {
      delta_t = uint256(lien.start + lien.duration - lien.last);
    } else {
      delta_t = uint256(timestamp.safeCastTo32() - lien.last);
    }
    return
      delta_t.mulDivDown(lien.rate, 1).mulDivDown(
        lien.amount,
        INTEREST_DENOMINATOR
      );
  }

  /**
   * @notice Stops accruing interest for all liens against a single CollateralToken.
   * @param collateralId The ID for the  CollateralToken of the NFT used as collateral for the liens.
   */
  function stopLiens(uint256 collateralId)
    external
    requiresAuth
    returns (uint256 reserve, uint256[] memory lienIds)
  {
    reserve = 0;
    lienIds = liens[collateralId];
    //        amounts = new uint256[](lienIds.length);
    for (uint256 i = 0; i < lienIds.length; ++i) {
      ILienToken.Lien storage lien = lienData[lienIds[i]];
      unchecked {
        lien.amount += _getInterest(lien, block.timestamp);
        reserve += lien.amount;
      }
      //            amounts[i] = lien.amount;
      lien.active = false;
    }
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    pure
    override
    returns (string memory)
  {
    return "";
  }

  /**
   * @notice Creates a new lien against a CollateralToken.
   * @param params LienActionEncumber data containing CollateralToken information and lien parameters (rate, duration, and amount, rate, and debt caps).
   */
  function createLien(ILienBase.LienActionEncumber memory params)
    external
    requiresAuth
    returns (uint256 lienId)
  {
    // require that the auction is not under way

    uint256 collateralId = params.tokenContract.computeId(params.tokenId);

    if (AUCTION_HOUSE.auctionExists(collateralId)) {
      revert InvalidCollateralState(InvalidStates.AUCTION);
    }

    (address tokenContract, ) = COLLATERAL_TOKEN.getUnderlying(collateralId);
    if (tokenContract == address(0)) {
      revert InvalidCollateralState(InvalidStates.NO_DEPOSIT);
    }

    uint256 totalDebt = getTotalDebtForCollateralToken(collateralId);
    uint256 impliedRate = getImpliedRate(collateralId);

    uint256 potentialDebt = totalDebt *
      (impliedRate + 1) *
      params.terms.duration;

    if (potentialDebt > params.terms.maxPotentialDebt) {
      revert InvalidCollateralState(InvalidStates.DEBT_LIMIT);
    }

    lienId = uint256(
      keccak256(
        abi.encodePacked(
          abi.encode(
            bytes32(collateralId),
            params.vault,
            WETH,
            params.terms.maxAmount,
            params.terms.rate,
            params.terms.duration,
            params.terms.maxPotentialDebt
          ),
          params.strategyRoot
        )
      )
    );

    //0 - 4 are valid
    require(
      uint256(liens[collateralId].length) < MAX_LIENS,
      "too many liens active"
    );

    uint8 newPosition = uint8(liens[collateralId].length);

    _mint(VaultImplementation(params.vault).recipient(), lienId);
    lienData[lienId] = Lien({
      collateralId: collateralId,
      position: newPosition,
      amount: params.amount,
      active: true,
      rate: params.terms.rate.safeCastTo240(),
      last: block.timestamp.safeCastTo32(),
      start: block.timestamp.safeCastTo32(),
      duration: params.terms.duration.safeCastTo32(),
      payee: address(0)
    });

    liens[collateralId].push(lienId);
    emit NewLien(lienId, lienData[lienId]);
  }

  /**
   * @notice Removes all liens for a given CollateralToken.
   * @param collateralId The ID for the underlying CollateralToken.
   */
  function removeLiens(uint256 collateralId) external requiresAuth {
    delete liens[collateralId];
    emit RemovedLiens(collateralId);
  }

  /**
   * @notice Retrieves all liens taken out against the underlying NFT of a CollateralToken.
   * @param collateralId The ID for the underlying CollateralToken.
   * @return The IDs of the liens against the CollateralToken.
   */
  function getLiens(uint256 collateralId)
    public
    view
    returns (uint256[] memory)
  {
    return liens[collateralId];
  }

  /**
   * @notice Retrieves a specific Lien by its ID.
   * @param lienId The ID of the requested Lien.
   * @return lien The Lien for the lienId.
   */
  function getLien(uint256 lienId) public view returns (Lien memory lien) {
    lien = lienData[lienId];
    lien.amount = _getOwed(lien);
    lien.last = block.timestamp.safeCastTo32();
  }

  /**
   * @notice Retrives a specific Lien from the ID of the CollateralToken for the underlying NFT and the lien position.
   * @param collateralId The ID for the underlying CollateralToken.
   * @param position The requested lien position.
   *  @ return lien The Lien for the lienId.
   */
  function getLien(uint256 collateralId, uint256 position)
    public
    view
    returns (Lien memory)
  {
    uint256 lienId = liens[collateralId][position];
    return getLien(lienId);
  }

  /**
   * @notice Computes and returns the buyout amount for a Lien.
   * @param collateralId The ID for the underlying CollateralToken.
   * @param position The position of the Lien to compute the buyout amount for.
   * @return The outstanding debt for the lien and the buyout amount for the Lien.
   */
  function getBuyout(uint256 collateralId, uint256 position)
    public
    view
    returns (uint256, uint256)
  {
    Lien memory lien = getLien(collateralId, position);

    uint256 remainingInterest = _getRemainingInterest(lien, true);
    uint256 buyoutTotal = lien.amount +
      ASTARIA_ROUTER.getBuyoutFee(remainingInterest);

    return (lien.amount, buyoutTotal);
  }

  /**
   * @notice Make a payment for the debt against a CollateralToken.
   * @param collateralId The ID of the underlying CollateralToken.
   * @param paymentAmount The amount to pay against the debt.
   */
  function makePayment(uint256 collateralId, uint256 paymentAmount) public {
    makePayment(collateralId, paymentAmount, address(msg.sender));
  }

  /**
   * @notice Make a payment for the debt against a CollateralToken for a specific lien.
   * @param collateralId The ID of the underlying CollateralToken.
   * @param paymentAmount The amount to pay against the debt.
   * @param position The lien position to make a payment to.
   */
  function makePayment(
    uint256 collateralId,
    uint256 paymentAmount,
    uint256 position
  ) external {
    _payment(collateralId, position, paymentAmount, address(msg.sender));
  }

  /**
   * @notice Have a specified paymer make a payment for the debt against a CollateralToken.
   * @param collateralId The ID of the underlying CollateralToken.
   * @param totalCapitalAvailable The amount to pay against the debts
   * @param payer The account to make the payment.
   */
  function makePayment(
    uint256 collateralId,
    uint256 totalCapitalAvailable,
    address payer
  ) public {
    uint256[] memory openLiens = liens[collateralId];
    uint256 paymentAmount = totalCapitalAvailable;
    for (uint256 i = 0; i < openLiens.length; ++i) {
      uint256 capitalSpent = _payment(collateralId, i, paymentAmount, payer);
      paymentAmount -= capitalSpent;
    }
  }

  /**
   * @notice Computes the rate for a specified lien.
   * @param lienId The ID for the lien.
   * @return The rate for the specified lien, in WETH per second.
   */
  function calculateSlope(uint256 lienId) public view returns (uint256) {
    Lien memory lien = lienData[lienId];
    uint256 end = (lien.start + lien.duration);
    uint256 owedAtEnd = _getOwed(lien, end);
    return (owedAtEnd - lien.amount).mulDivDown(1, end - lien.last);
  }

  /**
   * @notice Computes the change in rate for a lien if a specific payment amount was made.
   * @param lienId The ID for the lien.
   * @param paymentAmount The hypothetical payment amount that would be made to the lien.
   * @return slope The difference between the current lien rate and the lien rate if the payment was made.
   */
  function changeInSlope(uint256 lienId, uint256 paymentAmount)
    public
    view
    returns (uint256 slope)
  {
    Lien memory lien = lienData[lienId];
    uint256 oldSlope = calculateSlope(lienId);
    uint256 newAmount = (lien.amount - paymentAmount);

    // slope = (rate*time*amount - amount) / time -> amount(rate*time - 1) / time
    uint256 newSlope = newAmount.mulDivDown(
      (uint256(lien.rate).mulDivDown(lien.duration, 1) - 1),
      lien.duration
    );

    slope = oldSlope - newSlope;
  }

  /**
   * @notice Computes the total amount owed on all liens against a CollateralToken.
   * @param collateralId The ID of the underlying CollateralToken.
   * @return totalDebt The aggregate debt for all loans against the collateral.
   */
  function getTotalDebtForCollateralToken(uint256 collateralId)
    public
    view
    returns (uint256 totalDebt)
  {
    uint256[] memory openLiens = getLiens(collateralId);
    totalDebt = 0;
    for (uint256 i = 0; i < openLiens.length; ++i) {
      totalDebt += _getOwed(lienData[openLiens[i]]);
    }
  }

  /**
   * @notice Computes the total amount owed on all liens against a CollateralToken at a specified timestamp.
   * @param collateralId The ID of the underlying CollateralToken.
   * @param timestamp The timestamp to use to calculate owed debt.
   * @return totalDebt The aggregate debt for all loans against the specified collateral at the specified timestamp.
   */
  function getTotalDebtForCollateralToken(
    uint256 collateralId,
    uint256 timestamp
  ) public view returns (uint256 totalDebt) {
    uint256[] memory openLiens = getLiens(collateralId);
    totalDebt = 0;

    for (uint256 i = 0; i < openLiens.length; ++i) {
      totalDebt += _getOwed(lienData[openLiens[i]], timestamp);
    }
  }

  /**
   * @notice Computes the combined rate of all liens against a CollateralToken
   * @param collateralId The ID of the underlying CollateralToken.
   * @return impliedRate The aggregate rate for all loans against the specified collateral.
   */
  function getImpliedRate(uint256 collateralId)
    public
    view
    returns (uint256 impliedRate)
  {
    uint256 totalDebt = getTotalDebtForCollateralToken(collateralId);
    uint256[] memory openLiens = getLiens(collateralId);
    impliedRate = 0;
    for (uint256 i = 0; i < openLiens.length; ++i) {
      Lien memory lien = lienData[openLiens[i]];

      impliedRate += lien.rate * lien.amount;
    }

    if (totalDebt > uint256(0)) {
      impliedRate = impliedRate.mulDivDown(1, totalDebt);
    }
  }

  /**
   * @dev Computes the debt owed to a Lien.
   * @param lien The specified Lien.
   * @return The amount owed to the specified Lien.
   */
  function _getOwed(Lien memory lien) internal view returns (uint256) {
    return _getOwed(lien, block.timestamp);
  }

  /**
   * @dev Computes the debt owed to a Lien at a specified timestamp.
   * @param lien The specified Lien.
   * @return The amount owed to the Lien at the specified timestamp.
   */
  function _getOwed(Lien memory lien, uint256 timestamp)
    internal
    view
    returns (uint256)
  {
    return lien.amount + _getInterest(lien, timestamp);
  }

  /**
   * @dev Computes the interest still owed to a Lien.
   * @param lien The specified Lien.
   * @param buyout compute with a ceiling based on the buyout interest window
   * @return The WETH still owed in interest to the Lien.
   */
  function _getRemainingInterest(Lien memory lien, bool buyout)
    internal
    view
    returns (uint256)
  {
    uint256 end = lien.start + lien.duration;
    if (buyout) {
      uint32 getBuyoutInterestWindow = ASTARIA_ROUTER.getBuyoutInterestWindow();
      if (
        lien.start + lien.duration >= block.timestamp + getBuyoutInterestWindow
      ) {
        end = block.timestamp + getBuyoutInterestWindow;
      }
    }

    uint256 delta_t = end - block.timestamp;

    return
      delta_t.mulDivDown(lien.rate, 1).mulDivDown(
        lien.amount,
        INTEREST_DENOMINATOR
      );
  }

  function getInterest(uint256 lienId) public view returns (uint256) {
    return _getInterest(lienData[lienId], block.timestamp);
  }

  /**
   * @dev Make a payment from a payer to a specific lien against a CollateralToken.
   * @param collateralId The ID of the underlying CollateralToken.
   * @param position The position of the lien to make a payment to.
   * @param paymentAmount The amount to pay against the debt.
   * @param payer The address to make the payment.
   * @return The paymentAmount for the payment.
   */
  function _payment(
    uint256 collateralId,
    uint256 position,
    uint256 paymentAmount,
    address payer
  ) internal returns (uint256) {
    if (paymentAmount == uint256(0)) {
      return uint256(0);
    }

    uint256 lienId = liens[collateralId][position];

    Lien storage lien = lienData[lienId];
    uint256 end = (lien.start + lien.duration);
    require(block.timestamp < end, "cannot pay off an expired lien");

    address lienOwner = ownerOf(lienId);
    bool isPublicVault = IPublicVault(lienOwner).supportsInterface(
      type(IPublicVault).interfaceId
    );

    lien.amount = _getOwed(lien);

    address payee = getPayee(lienId);

    if (isPublicVault) {
      IPublicVault(lienOwner).beforePayment(lienId, paymentAmount);
    }
    if (lien.amount > paymentAmount) {
      lien.amount -= paymentAmount;
      lien.last = block.timestamp.safeCastTo32();
      // slope does not need to be updated if paying off the rest, since we neutralize slope in beforePayment()
      if (isPublicVault) {
        IPublicVault(lienOwner).afterPayment(lienId);
      }
    } else {
      if (isPublicVault && !AUCTION_HOUSE.auctionExists(collateralId)) {
        // since the openLiens count is only positive when there are liens that haven't been paid off
        // that should be liquidated, this lien should not be counted anymore
        IPublicVault(lienOwner).decreaseEpochLienCount(
          IPublicVault(lienOwner).getLienEpoch(end)
        );
      }
      //delete liens
      _deleteLienPosition(collateralId, position);
      delete lienData[lienId]; //full delete

      _burn(lienId);
    }

    TRANSFER_PROXY.tokenTransferFrom(WETH, payer, payee, paymentAmount);

    emit Payment(lienId, paymentAmount);
    return paymentAmount;
  }

  function _deleteLienPosition(uint256 collateralId, uint256 position) public {
    uint256[] storage stack = liens[collateralId];
    require(position < stack.length, "index out of bound");

    emit RemoveLien(
      stack[position],
      lienData[stack[position]].collateralId,
      lienData[stack[position]].position
    );
    for (uint256 i = position; i < stack.length - 1; i++) {
      stack[i] = stack[i + 1];
    }
    stack.pop();
  }

  /**
   * @notice Retrieve the payee (address that receives payments and auction funds) for a specified Lien.
   * @param lienId The ID of the Lien.
   * @return The address of the payee for the Lien.
   */
  function getPayee(uint256 lienId) public view returns (address) {
    return
      lienData[lienId].payee != address(0)
        ? lienData[lienId].payee
        : ownerOf(lienId);
  }

  /**
   * @notice Change the payee for a specified Lien.
   * @param lienId The ID of the Lien.
   * @param newPayee The new Lien payee.
   */
  function setPayee(uint256 lienId, address newPayee) public {
    if (AUCTION_HOUSE.auctionExists(lienData[lienId].collateralId)) {
      revert InvalidCollateralState(InvalidStates.AUCTION);
    }
    require(
      !AUCTION_HOUSE.auctionExists(lienData[lienId].collateralId),
      "collateralId is being liquidated, cannot change payee from LiquidationAccountant"
    );
    require(
      msg.sender == ownerOf(lienId) || msg.sender == address(ASTARIA_ROUTER),
      "invalid owner"
    );

    lienData[lienId].payee = newPayee;
    emit PayeeChanged(lienId, newPayee);
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 * 
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Clone} from "clones-with-immutable-args/Clone.sol";

import {ILienToken} from "./interfaces/ILienToken.sol";

import {PublicVault} from "./PublicVault.sol";
import {WithdrawProxy} from "./WithdrawProxy.sol";

abstract contract LiquidationBase is Clone {
  function underlying() public pure returns (address) {
    return _getArgAddress(0);
  }

  function ROUTER() public pure returns (address) {
    return _getArgAddress(20);
  }

  function VAULT() public pure returns (address) {
    return _getArgAddress(40);
  }

  function LIEN_TOKEN() public pure returns (address) {
    return _getArgAddress(60);
  }

  function WITHDRAW_PROXY() public view returns (address) {
    return _getArgAddress(80);
  }
}

/**
 * @title LiquidationAccountant
 * @author santiagogregory
 * @notice This contract collects funds from liquidations that overlap with an epoch boundary where liquidity providers are exiting.
 * When the final auction being tracked by a LiquidationAccountant for a given epoch is completed,
 * claim() proportionally pays out auction funds to withdrawing liquidity providers and the PublicVault.
 */
contract LiquidationAccountant is LiquidationBase {
  using FixedPointMathLib for uint256;
  using SafeTransferLib for ERC20;

  uint256 withdrawRatio;

  uint256 expected; // Expected value of auctioned NFTs. yIntercept (virtual assets) of a PublicVault are not modified on liquidation, only once an auction is completed.
  uint256 finalAuctionEnd; // when this is deleted, we know the final auction is over

  address withdrawProxy;

  /**
   * @notice Proportionally sends funds collected from auctions to withdrawing liquidity providers and the PublicVault for this LiquidationAccountant.
   */
  function claim() public {
    require(
      block.timestamp > finalAuctionEnd || finalAuctionEnd == uint256(0),
      "final auction has not ended"
    );

    uint256 balance = ERC20(underlying()).balanceOf(address(this));
    // would happen if there was no WithdrawProxy for current epoch
    if (withdrawRatio == uint256(0)) {
      ERC20(underlying()).safeTransfer(VAULT(), balance);
    } else {
      //should be wad multiplication
      // declining
      uint256 transferAmount = withdrawRatio * balance;
      ERC20(underlying()).safeTransfer(withdrawProxy, transferAmount);

      unchecked {
        balance -= transferAmount;
      }

      ERC20(underlying()).safeTransfer(VAULT(), balance);
    }

    uint256 oldYIntercept = PublicVault(VAULT()).getYIntercept();

    //
    PublicVault(VAULT()).setYIntercept(
      oldYIntercept -
        (expected - ERC20(underlying()).balanceOf(address(this))).mulDivDown(
          1 - withdrawRatio,
          1
        )
    );
  }

  // pass in withdrawproxy address here instead of constructor in case liquidation called before first marked withdraw
  // called on epoch boundary (maybe rename)

  /**
   * @notice Called at epoch boundary, computes the ratio between the funds of withdrawing liquidity providers and the balance of the underlying PublicVault so that claim() proportionally pays out to all parties.
   */
  function calculateWithdrawRatio() public {
    require(msg.sender == VAULT());

    withdrawRatio = WithdrawProxy(WITHDRAW_PROXY()).totalSupply().mulDivDown(
      1,
      PublicVault(VAULT()).totalSupply()
    );
  }

  /**
   * @notice Adds an auction scheduled to end in a new epoch to this LiquidationAccountant.
   * @param newLienExpectedValue The expected auction value for the lien being auctioned.
   * @param finalAuctionTimestamp The timestamp by which the auction being added is guaranteed to end. As new auctions are added to the LiquidationAccountant, this value will strictly increase as all auctions have the same maximum duration.
   */
  function handleNewLiquidation(
    uint256 newLienExpectedValue,
    uint256 finalAuctionTimestamp
  ) public {
    require(msg.sender == ROUTER());
    expected += newLienExpectedValue;
    finalAuctionEnd = finalAuctionTimestamp;
  }

  function getFinalAuctionEnd() external view returns (uint256) {
    return finalAuctionEnd;
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 * 
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

import {Auth, Authority} from "solmate/auth/Auth.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IERC721, IERC165} from "gpl/interfaces/IERC721.sol";
import {
  IVault,
  ERC4626Cloned,
  ITokenBase,
  ERC4626Base,
  AstariaVaultBase
} from "gpl/ERC4626-Cloned.sol";

import {
  ClonesWithImmutableArgs
} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";

import {IAstariaRouter} from "./interfaces/IAstariaRouter.sol";
import {ILienBase} from "./interfaces/ILienToken.sol";
import {ILienToken} from "./interfaces/ILienToken.sol";

import {LienToken} from "./LienToken.sol";
import {LiquidationAccountant} from "./LiquidationAccountant.sol";
import {VaultImplementation} from "./VaultImplementation.sol";
import {WithdrawProxy} from "./WithdrawProxy.sol";

import {Math} from "./utils/Math.sol";
import {Pausable} from "./utils/Pausable.sol";

interface IPublicVault is IERC165 {
  function beforePayment(uint256 escrowId, uint256 amount) external;

  function decreaseEpochLienCount(uint256 lienId) external;

  function getLienEpoch(uint256 end) external view returns (uint256);

  function afterPayment(uint256 lienId) external;
}

/**
 * @title Vault
 * @author androolloyd
 */
contract Vault is AstariaVaultBase, VaultImplementation, IVault {
  using SafeTransferLib for ERC20;

  function name() public view override returns (string memory) {
    return string(abi.encodePacked("AST-Vault-", ERC20(underlying()).symbol()));
  }

  function symbol() public view override returns (string memory) {
    return
      string(
        abi.encodePacked("AST-V", owner(), "-", ERC20(underlying()).symbol())
      );
  }

  function _handleStrategistInterestReward(uint256 lienId, uint256 shares)
    internal
    virtual
    override
  {}

  function deposit(uint256 amount, address)
    public
    virtual
    override
    returns (uint256)
  {
    require(msg.sender == owner(), "only the appraiser can fund this vault");
    ERC20(underlying()).safeTransferFrom(
      address(msg.sender),
      address(this),
      amount
    );
    return amount;
  }

  function withdraw(uint256 amount) external {
    require(msg.sender == owner(), "only the appraiser can exit this vault");
    ERC20(underlying()).safeTransferFrom(
      address(this),
      address(msg.sender),
      amount
    );
  }
}

/*
 * @title PublicVault
 * @author androolloyd
 * @notice
 */
contract PublicVault is Vault, IPublicVault, ERC4626Cloned {
  using FixedPointMathLib for uint256;
  using SafeTransferLib for ERC20;

  // epoch seconds when yIntercept was calculated last
  uint256 public last;
  // sum of all LienToken amounts
  uint256 public yIntercept;
  // sum of all slopes of each LienToken
  uint256 public slope;

  // block.timestamp of first epoch
  uint256 public withdrawReserve = 0;
  uint256 liquidationWithdrawRatio = 0;
  uint256 strategistUnclaimedShares = 0;
  uint64 public currentEpoch = 0;

  //mapping of epoch to number of open liens
  mapping(uint256 => uint256) public liensOpenForEpoch;
  // WithdrawProxies and LiquidationAccountants for each epoch.
  // The first possible WithdrawProxy and LiquidationAccountant starts at index 0, i.e. an LP that marks a withdraw in epoch 0 to collect by the end of epoch *1* would use the 0th WithdrawProxy.
  mapping(uint64 => address) public withdrawProxies;
  mapping(uint64 => address) public liquidationAccountants;

  event YInterceptChanged(uint256 newYintercept);
  event WithdrawReserveTransferred(uint256 amount);

  function underlying()
    public
    view
    virtual
    override(ERC4626Base, AstariaVaultBase)
    returns (address)
  {
    return super.underlying();
  }

  /**
   * @notice Signal a withdrawal of funds (redeeming for underlying asset) in the next epoch.
   * @param shares The number of VaultToken shares to redeem.
   * @param receiver The receiver of the WithdrawTokens (and eventual underlying asset)
   * @param owner The owner of the VaultTokens.
   * @return assets The amount of the underlying asset redeemed.
   */
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) public virtual override returns (uint256 assets) {
    assets = redeemFutureEpoch(shares, receiver, owner, currentEpoch);
  }

  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) public virtual override returns (uint256 shares) {
    shares = previewWithdraw(assets);
    redeemFutureEpoch(shares, receiver, owner, currentEpoch);
  }

  /**
   * @notice Signal a withdrawal of funds (redeeming for underlying asset) in an arbitrary future epoch.
   * @param shares The number of VaultToken shares to redeem.
   * @param receiver The receiver of the WithdrawTokens (and eventual underlying asset)
   * @param owner The owner of the VaultTokens.
   * @param epoch The epoch to withdraw for.
   * @return assets The amount of the underlying asset redeemed.
   */
  function redeemFutureEpoch(
    uint256 shares,
    address receiver,
    address owner,
    uint64 epoch
  ) public virtual returns (uint256 assets) {
    // check to ensure that the requested epoch is not the current epoch or in the past
    require(epoch >= currentEpoch, "Exit epoch too low");

    require(msg.sender == owner, "Only the owner can redeem");
    // check for rounding error since we round down in previewRedeem.

    ERC20(address(this)).safeTransferFrom(owner, address(this), shares);

    // Deploy WithdrawProxy if no WithdrawProxy exists for the specified epoch
    _deployWithdrawProxyIfNotDeployed(epoch);

    emit Withdraw(msg.sender, receiver, owner, assets, shares);

    // WithdrawProxy shares are minted 1:1 with PublicVault shares
    WithdrawProxy(withdrawProxies[epoch]).mint(receiver, shares); // was withdrawProxies[withdrawEpoch]
  }

  function _deployWithdrawProxyIfNotDeployed(uint64 epoch) internal {
    if (withdrawProxies[epoch] == address(0)) {
      address proxy = ClonesWithImmutableArgs.clone(
        IAstariaRouter(ROUTER()).WITHDRAW_IMPLEMENTATION(),
        abi.encodePacked(
          address(this), //owner
          underlying() //token
        )
      );
      withdrawProxies[epoch] = proxy;
    }
  }

  /**
   * @notice Deposit funds into the PublicVault.
   * @param amount The amount of funds to deposit.
   * @param receiver The receiver of the resulting VaultToken shares.
   */
  function deposit(uint256 amount, address receiver)
    public
    override(Vault, ERC4626Cloned)
    whenNotPaused
    returns (uint256)
  {
    return super.deposit(amount, receiver);
  }

  /**
   * @notice Retrieve the domain separator.
   * @return The domain separator.
   */
  function computeDomainSeparator() internal view override returns (bytes32) {
    return super.domainSeparator();
  }

  /**
   * @notice Rotate epoch boundary. This must be called before the next epoch can begin.
   */

  function processEpoch() external {
    // check to make sure epoch is over
    require(getEpochEnd(currentEpoch) < block.timestamp, "Epoch has not ended");
    require(withdrawReserve == 0, "Withdraw reserve not empty");
    if (liquidationAccountants[currentEpoch] != address(0)) {
      require(
        LiquidationAccountant(liquidationAccountants[currentEpoch])
          .getFinalAuctionEnd() < block.timestamp,
        "Final auction not ended"
      );
    }
    // clear out any remaining withdrawReserve balance
    if (withdrawReserve > 0) {
      transferWithdrawReserve();
    }

    // split funds from LiquidationAccountant between PublicVault and WithdrawProxy if hasn't been already
    if (
      currentEpoch != 0 &&
      liquidationAccountants[currentEpoch - 1] != address(0)
    ) {
      LiquidationAccountant(liquidationAccountants[currentEpoch - 1]).claim();
    }

    require(
      liensOpenForEpoch[currentEpoch] == uint256(0),
      "loans are still open for this epoch"
    );

    // reset liquidationWithdrawRatio to prepare for re calcualtion
    liquidationWithdrawRatio = 0;

    // reset withdrawReserve to prepare for re calcualtion
    withdrawReserve = 0;

    // check if there are LPs withdrawing this epoch
    if (withdrawProxies[currentEpoch] != address(0)) {
      uint256 proxySupply = WithdrawProxy(withdrawProxies[currentEpoch])
        .totalSupply();

      if (liquidationAccountants[currentEpoch] != address(0)) {
        LiquidationAccountant(liquidationAccountants[currentEpoch])
          .calculateWithdrawRatio();
      }

      // compute the withdrawReserve
      withdrawReserve = convertToAssets(proxySupply);

      // burn the tokens of the LPs withdrawing
      _burn(address(this), proxySupply);
    }

    // increment epoch
    currentEpoch++;
  }

  /**
   * @notice Deploys a LiquidationAccountant for the WithdrawProxy for the upcoming epoch boundary.
   * @return accountant The address of the deployed LiquidationAccountant.
   */
  function deployLiquidationAccountant() public returns (address accountant) {
    require(
      liquidationAccountants[currentEpoch] == address(0),
      "cannot deploy two liquidation accountants for the same epoch"
    );

    _deployWithdrawProxyIfNotDeployed(currentEpoch);

    accountant = ClonesWithImmutableArgs.clone(
      IAstariaRouter(ROUTER()).LIQUIDATION_IMPLEMENTATION(),
      abi.encodePacked(
        underlying(),
        ROUTER(),
        address(this),
        address(LIEN_TOKEN()),
        address(withdrawProxies[currentEpoch])
      )
    );
    liquidationAccountants[currentEpoch] = accountant;
  }

  function supportsInterface(bytes4 interfaceId)
    public
    pure
    override(IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IPublicVault).interfaceId ||
      interfaceId == type(IVault).interfaceId ||
      interfaceId == type(ERC4626Cloned).interfaceId ||
      interfaceId == type(ERC4626).interfaceId ||
      interfaceId == type(ERC20).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  event TransferWithdraw(uint256 a, uint256 b);

  /**
   * @notice Transfers funds from the PublicVault to the WithdrawProxy.
   */

  function transferWithdrawReserve() public {
    // check the available balance to be withdrawn
    uint256 withdraw = ERC20(underlying()).balanceOf(address(this));
    emit TransferWithdraw(withdraw, withdrawReserve);

    // prevent transfer of more assets then are available
    if (withdrawReserve <= withdraw) {
      withdraw = withdrawReserve;
      withdrawReserve = 0;
    } else {
      withdrawReserve -= withdraw;
    }
    emit TransferWithdraw(withdraw, withdrawReserve);

    address currentWithdrawProxy = withdrawProxies[currentEpoch - 1]; //
    // prevents transfer to a non-existent WithdrawProxy
    // withdrawProxies are indexed by the epoch where they're deployed
    if (currentWithdrawProxy != address(0)) {
      ERC20(underlying()).safeTransfer(currentWithdrawProxy, withdraw);
      emit WithdrawReserveTransferred(withdraw);
    }
  }

  /**
   * @dev Hook for updating the slope of the PublicVault after a LienToken is issued.
   * @param lienId The ID of the lien.
   * @param amount The amount of debt
   */
  function _afterCommitToLien(uint256 lienId, uint256 amount)
    internal
    virtual
    override
  {
    // increment slope for the new lien
    unchecked {
      slope += LIEN_TOKEN().calculateSlope(lienId);
    }

    ILienToken.Lien memory lien = LIEN_TOKEN().getLien(lienId);

    uint256 epoch = Math.ceilDiv(
      lien.start + lien.duration - START(),
      EPOCH_LENGTH()
    ) - 1;

    liensOpenForEpoch[epoch]++;
    emit LienOpen(lienId, epoch);
  }

  event LienOpen(uint256 lienId, uint256 epoch);

  /**
   * @notice Retrieves the address of the LienToken contract for this PublicVault.
   * @return The LienToken address.
   */

  function LIEN_TOKEN() public view returns (ILienToken) {
    return IAstariaRouter(ROUTER()).LIEN_TOKEN();
  }

  /**
   * @notice Computes the implied value of this PublicVault. This includes interest payments that have not yet been made.
   * @return The implied value for this PublicVault.
   */

  function totalAssets() public view virtual override returns (uint256) {
    if (last == 0 || yIntercept == 0) {
      return ERC20(underlying()).balanceOf(address(this));
    }
    uint256 delta_t = block.timestamp - last;

    return slope.mulDivDown(delta_t, 1) + yIntercept;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply + strategistUnclaimedShares;
  }

  /**
   * @notice Mints earned fees by the strategist to the strategist address.
   */
  function claim() external onlyOwner {
    _mint(owner(), strategistUnclaimedShares);
    strategistUnclaimedShares = 0;
  }

  /**
   * @notice Hook to update the slope and yIntercept of the PublicVault on payment.
   * The rate for the LienToken is subtracted from the total slope of the PublicVault, and recalculated in afterPayment().
   * @param lienId The ID of the lien.
   * @param amount The amount paid off to deduct from the yIntercept of the PublicVault.
   */

  function beforePayment(uint256 lienId, uint256 amount) public onlyLienToken {
    _handleStrategistInterestReward(lienId, amount);
    if (totalAssets() > amount) {
      yIntercept = totalAssets() - amount;
    } else {
      yIntercept = 0;
    }
    uint256 lienSlope = LIEN_TOKEN().calculateSlope(lienId);
    if (lienSlope > slope) {
      slope = 0;
    } else {
      slope -= lienSlope;
    }
    last = block.timestamp;
  }

  function decreaseEpochLienCount(uint256 epoch) external {
    require(
      msg.sender == address(ROUTER()) || msg.sender == address(LIEN_TOKEN()),
      "only router or lien token"
    );
    liensOpenForEpoch[epoch]--;
  }

  function getLienEpoch(uint256 end) external view returns (uint256) {
    return Math.ceilDiv(end - START(), EPOCH_LENGTH()) - 1;
  }

  function getEpochEnd(uint256 epoch) public view returns (uint256) {
    return START() + (epoch + 1) * EPOCH_LENGTH();
  }

  function _increaseOpenLiens() internal {
    liensOpenForEpoch[currentEpoch]++;
  }

  /**
   * @notice Hook to recalculate the slope of a lien after a payment has been made.
   * @param lienId The ID of the lien.
   */
  function afterPayment(uint256 lienId) public onlyLienToken {
    slope += LIEN_TOKEN().calculateSlope(lienId);
  }

  modifier onlyLienToken() {
    require(msg.sender == address(LIEN_TOKEN()));
    _;
  }

  /**
   * @notice After-deposit hook to update the yIntercept of the PublicVault to reflect a capital contribution.
   * @param assets The amount of assets deposited to the PublicVault.
   * @param shares The resulting amount of VaultToken shares that were issued.
   */
  function afterDeposit(uint256 assets, uint256 shares)
    internal
    virtual
    override
  {
    emit LogUint("yintercept", yIntercept);
    emit LogUint("assets", assets);
    emit LogUint("shares", shares);

    yIntercept += assets;
    emit LogUint("yintercept", yIntercept);
  }

  /**
   * @dev Handles the dilutive fees (on lien repayments) for strategists in VaultTokens.
   * @param lienId The ID of the lien that received a payment.
   * @param amount The amount that was paid.
   */
  function _handleStrategistInterestReward(uint256 lienId, uint256 amount)
    internal
    virtual
    override
  {
    if (VAULT_FEE() != uint256(0)) {
      uint256 interestOwing = LIEN_TOKEN().getInterest(lienId);
      uint256 x = (amount > interestOwing) ? interestOwing : amount;
      uint256 fee = x.mulDivDown(VAULT_FEE(), 1000); //VAULT_FEE is a basis point
      strategistUnclaimedShares += convertToShares(fee);
    }
  }

  function updateSlopeAfterLiquidation(uint256 amount) public {
    require(msg.sender == ROUTER());

    slope -= amount;
  }

  function getYIntercept() public view returns (uint256) {
    return yIntercept;
  }

  function setYIntercept(uint256 _yIntercept) public {
    require(
      currentEpoch != 0 &&
        msg.sender == liquidationAccountants[currentEpoch - 1]
    );
    yIntercept = _yIntercept;
    emit YInterceptChanged(_yIntercept);
  }

  function getCurrentEpoch() public view returns (uint64) {
    return currentEpoch;
  }

  /**
   * @notice Computes the time until the current epoch is over.
   * @return Seconds until the current epoch ends.
   */
  function timeToEpochEnd() public view returns (uint256) {
    uint256 epochEnd = START() + ((currentEpoch + 1) * EPOCH_LENGTH());

    if (epochEnd >= block.timestamp) {
      return uint256(0);
    }

    return block.timestamp - epochEnd; //
  }

  function getLiquidationAccountant(uint64 epoch)
    public
    view
    returns (address)
  {
    return liquidationAccountants[epoch];
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 * 
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {IAuctionHouse} from "gpl/interfaces/IAuctionHouse.sol";
import {IVault, AstariaVaultBase} from "gpl/ERC4626-Cloned.sol";

import {CollateralLookup} from "./libraries/CollateralLookup.sol";

import {IAstariaRouter} from "./interfaces/IAstariaRouter.sol";
import {ICollateralToken} from "./interfaces/ICollateralToken.sol";
import {ILienBase, ILienToken} from "./interfaces/ILienToken.sol";
import {ILienToken} from "./interfaces/ILienToken.sol";

/**
 * @title VaultImplementation
 * @author androolloyd
 * @notice A base implementation for the minimal features of an Astaria Vault.
 */
abstract contract VaultImplementation is ERC721TokenReceiver, AstariaVaultBase {
  using SafeTransferLib for ERC20;
  using CollateralLookup for address;
  using FixedPointMathLib for uint256;

  address public delegate; //account connected to the daemon

  event NewLien(
    bytes32 strategyRoot,
    address tokenContract,
    uint256 tokenId,
    uint256 amount
  );

  event NewVault(address appraiser, address vault);

  /**
   * @notice receive hook for ERC721 tokens, nothing special done
   */
  function onERC721Received(
    address operator_,
    address from_,
    uint256 tokenId_,
    bytes calldata data_
  ) external pure override returns (bytes4) {
    return ERC721TokenReceiver.onERC721Received.selector;
  }

  modifier whenNotPaused() {
    if (IAstariaRouter(ROUTER()).paused()) {
      revert("protocol is paused");
    }
    _;
  }

  function domainSeparator() public view virtual returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string version,uint256 chainId,address verifyingContract)"
          ),
          keccak256("1"),
          block.chainid,
          address(this)
        )
      );
  }

  /*
   * @notice encodes the data for a 712 signature
   * @param tokenContract The address of the token contract
   * @param tokenId The id of the token
   * @param amount The amount of the token
   */

  // cast k "StrategyDetails(uint8 version,uint256 nonce,uint256 deadline,address vault,bytes32 root)"
  bytes32 private constant STRATEGY_TYPEHASH =
    0x13387dabcf46556a3ca406b99acf9197df1698efaab639c7772523bdfd4aa20e;

  function encodeStrategyData(
    IAstariaRouter.StrategyDetails calldata strategy,
    bytes32 root
  ) public view returns (bytes memory) {
    bytes32 hash = keccak256(
      abi.encode(
        STRATEGY_TYPEHASH,
        strategy.version,
        IAstariaRouter(ROUTER()).strategistNonce(strategy.strategist),
        strategy.deadline,
        address(this),
        root
      )
    );
    return
      abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), hash);
  }

  /**
   * @dev hook to allow inheriting contracts to perform payout for strategist
   */
  function _handleStrategistInterestReward(uint256, uint256) internal virtual {}

  struct InitParams {
    address delegate;
  }

  function init(InitParams calldata params) external virtual {
    require(msg.sender == address(ROUTER()), "only router");

    if (params.delegate != address(0)) {
      delegate = params.delegate;
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner(), "only strategist");
    _;
  }

  function setDelegate(address delegate_) public onlyOwner {
    delegate = delegate_;
  }

  /**
   * @dev Validates the terms for a requested loan.
   * Who is requesting the borrow, is it a smart contract? or is it a user?
   * if a smart contract, then ensure that the contract is approved to borrow and is also receiving the funds.
   * if a user, then ensure that the user is approved to borrow and is also receiving the funds.
   * The terms are hashed and signed by the borrower, and the signature validated against the strategist's address
   * lien details are decoded from the obligation data and validated the collateral
   *
   * @param params The Commitment information containing the loan parameters and the merkle proof for the strategy supporting the requested loan.
   * @param receiver The address of the prospective borrower.
   */
  function _validateCommitment(
    IAstariaRouter.Commitment calldata params,
    address receiver
  ) internal returns (IAstariaRouter.LienDetails memory) {
    uint256 collateralId = params.tokenContract.computeId(params.tokenId);

    address operator = ERC721(COLLATERAL_TOKEN()).getApproved(collateralId);

    address holder = ERC721(COLLATERAL_TOKEN()).ownerOf(collateralId);

    if (msg.sender != holder) {
      require(msg.sender == operator, "invalid request");
    }

    if (receiver != holder) {
      require(
        receiver == operator || IAstariaRouter(ROUTER()).isValidVault(receiver),
        "can only issue funds to an vault or operator if not the holder"
      );
    }

    address recovered = ecrecover(
      keccak256(
        encodeStrategyData(
          params.lienRequest.strategy,
          params.lienRequest.merkle.root
        )
      ),
      params.lienRequest.v,
      params.lienRequest.r,
      params.lienRequest.s
    );
    require(
      recovered == params.lienRequest.strategy.strategist,
      "strategist must match signature"
    );
    require(
      recovered == owner() || recovered == delegate,
      "invalid strategist"
    );

    (bool valid, IAstariaRouter.LienDetails memory ld) = IAstariaRouter(
      ROUTER()
    ).validateCommitment(params);

    require(
      valid,
      "Vault._validateCommitment(): Verification of provided merkle branch failed for the vault and parameters"
    );

    require(
      ld.rate > 0,
      "Vault._validateCommitment(): Cannot have a 0 interest rate"
    );

    require(
      ld.rate < IAstariaRouter(ROUTER()).maxInterestRate(),
      "Vault._validateCommitment(): Rate is above maximum"
    );

    require(
      ld.maxAmount >= params.lienRequest.amount,
      "Vault._validateCommitment(): Attempting to borrow more than maxAmount available for this asset"
    );

    uint256 seniorDebt = IAstariaRouter(ROUTER())
      .LIEN_TOKEN()
      .getTotalDebtForCollateralToken(
        params.tokenContract.computeId(params.tokenId)
      );
    require(
      params.lienRequest.amount <= ERC20(underlying()).balanceOf(address(this)),
      "Vault._validateCommitment():  Attempting to borrow more than available in the specified vault"
    );

    uint256 potentialDebt = seniorDebt * (ld.rate + 1) * ld.duration;
    require(
      potentialDebt <= ld.maxPotentialDebt,
      "Vault._validateCommitment(): Attempting to initiate a loan with debt potentially higher than maxPotentialDebt"
    );

    return ld;
  }

  function _afterCommitToLien(uint256 lienId, uint256 amount)
    internal
    virtual
  {}

  /**
   * @notice Pipeline for lifecycle of new loan origination.
   * Origination consists of a few phases: pre-commitment validation, lien token issuance, strategist reward, and after commitment actions
   * Starts by depositing collateral and take out a lien against it. Next, verifies the merkle proof for a loan commitment. Vault owners are then rewarded fees for successful loan origination.
   * @param params Commitment data for the incoming lien request
   * @param receiver The borrower receiving the loan.
   */
  function commitToLien(
    IAstariaRouter.Commitment calldata params,
    address receiver
  ) external whenNotPaused {
    IAstariaRouter.LienDetails memory ld = _validateCommitment(
      params,
      receiver
    );
    uint256 lienId = _requestLienAndIssuePayout(ld, params, receiver);
    _afterCommitToLien(lienId, params.lienRequest.amount);
    emit NewLien(
      params.lienRequest.merkle.root,
      params.tokenContract,
      params.tokenId,
      params.lienRequest.amount
    );
  }

  /**
   * @notice Returns whether a specific lien can be liquidated.
   * @param collateralId The ID of the underlying CollateralToken.
   * @param position The specified lien position.
   * @return A boolean value indicating whether the specified lien can be liquidated.
   */
  function canLiquidate(uint256 collateralId, uint256 position)
    public
    view
    returns (bool)
  {
    return IAstariaRouter(ROUTER()).canLiquidate(collateralId, position);
  }

  /**
   * @notice Buy out a lien to replace it with new terms.
   * @param collateralId The ID of the underlying CollateralToken.
   * @param position The position of the specified lien.
   * @param incomingTerms The loan terms of the new lien.
   */
  function buyoutLien(
    uint256 collateralId,
    uint256 position,
    IAstariaRouter.Commitment calldata incomingTerms
  ) external whenNotPaused {
    (, uint256 buyout) = IAstariaRouter(ROUTER()).LIEN_TOKEN().getBuyout(
      collateralId,
      position
    );

    require(
      buyout <= ERC20(underlying()).balanceOf(address(this)),
      "not enough balance to buy out loan"
    );

    _validateCommitment(incomingTerms, recipient());

    ERC20(underlying()).safeApprove(
      address(IAstariaRouter(ROUTER()).TRANSFER_PROXY()),
      buyout
    );
    IAstariaRouter(ROUTER()).LIEN_TOKEN().buyoutLien(
      ILienBase.LienActionBuyout(incomingTerms, position, recipient())
    );
  }

  /**
   * @notice Retrieves the recipient of loan repayments. For PublicVaults (VAULT_TYPE 2), this is always the vault address. For PrivateVaults, retrieves the owner() of the vault.
   * @return The address of the recipient.
   */
  function recipient() public view returns (address) {
    if (VAULT_TYPE() == uint8(IAstariaRouter.VaultType.PUBLIC)) {
      return address(this);
    } else {
      return owner();
    }
  }

  /**
   * @dev Generates a Lien for a valid loan commitment proof and sends the loan amount to the borrower.
   * @param c The Commitment information containing the loan parameters and the merkle proof for the strategy supporting the requested loan.
   * @param receiver The borrower requesting the loan.
   * @return The ID of the created Lien.
   */
  function _requestLienAndIssuePayout(
    IAstariaRouter.LienDetails memory ld,
    IAstariaRouter.Commitment calldata c,
    address receiver
  ) internal returns (uint256) {
    uint256 newLienId = IAstariaRouter(ROUTER()).requestLienPosition(ld, c);

    uint256 payout = _handleProtocolFee(c.lienRequest.amount);
    ERC20(underlying()).safeTransfer(receiver, payout);
    return newLienId;
  }

  function _handleProtocolFee(uint256 amount) internal returns (uint256) {
    address feeTo = IAstariaRouter(ROUTER()).feeTo();
    bool feeOn = feeTo != address(0);
    if (feeOn) {
      uint256 fee = IAstariaRouter(ROUTER()).getProtocolFee(amount);

      unchecked {
        amount -= fee;
      }
      ERC20(underlying()).safeTransfer(feeTo, fee);
    }
    return amount;
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 * 
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

import {Auth, Authority} from "solmate/auth/Auth.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {
  ERC4626Cloned,
  WithdrawVaultBase,
  ITokenBase
} from "gpl/ERC4626-Cloned.sol";
import {ITransferProxy} from "gpl/interfaces/ITransferProxy.sol";

/**
 * @title WithdrawProxy
 * @notice This contract collects funds for liquidity providers who are exiting. When a liquidity provider is the first
 * in an epoch to mark that they would like to withdraw their funds, a WithdrawProxy for the liquidity provider's
 * PublicVault is deployed to collect loan repayments until the end of the next epoch. Users are minted WithdrawTokens
 * according to their balance in the protocol which are redeemable 1:1 for the underlying PublicVault asset by the end
 * of the next epoch.
 *
 */
contract WithdrawProxy is ERC4626Cloned, WithdrawVaultBase {
  using SafeTransferLib for ERC20;
  using FixedPointMathLib for uint256;

  function totalAssets() public view override returns (uint256) {
    return ERC20(underlying()).balanceOf(address(this));
  }

  /**
   * @notice Public view function to return the name of this WithdrawProxy.
   * @return The name of this WithdrawProxy.
   */
  function name()
    public
    view
    override(ITokenBase, WithdrawVaultBase)
    returns (string memory)
  {
    return
      string(
        abi.encodePacked("AST-WithdrawVault-", ERC20(underlying()).symbol())
      );
  }

  /**
   * @notice Public view function to return the symbol of this WithdrawProxy.
   * @return The symbol of this WithdrawProxy.
   */
  function symbol()
    public
    view
    override(ITokenBase, WithdrawVaultBase)
    returns (string memory)
  {
    return
      string(
        abi.encodePacked("AST-W", owner(), "-", ERC20(underlying()).symbol())
      );
  }

  /**
   * @notice Mints WithdrawTokens for withdrawing liquidity providers, redeemable by the end of the next epoch.
   * @param receiver The receiver of the Withdraw Tokens.
   * @param shares The number of shares to mint.
   */
  function mint(address receiver, uint256 shares) public virtual {
    require(msg.sender == owner(), "only owner can mint");
    _mint(receiver, shares);
  }

}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 * 
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

import {IERC721} from "gpl/interfaces/IERC721.sol";
import {ITransferProxy} from "gpl/interfaces/ITransferProxy.sol";
import {IVault} from "gpl/ERC4626-Cloned.sol";

import {ICollateralToken} from "./ICollateralToken.sol";
import {ILienBase, ILienToken} from "./ILienToken.sol";

import {IPausable} from "../utils/Pausable.sol";

interface IAstariaRouter is IPausable {
  enum VaultType {
    SOLO,
    PUBLIC
  }

  struct LienDetails {
    uint256 maxAmount;
    uint256 rate; //rate per second
    uint256 duration;
    uint256 maxPotentialDebt;
  }

  enum LienRequestType {
    UNIQUE,
    COLLECTION,
    UNIV3_LIQUIDITY
  }

  struct StrategyDetails {
    uint8 version;
    address strategist;
    uint256 deadline;
    address vault;
  }

  struct MerkleData {
    bytes32 root;
    bytes32[] proof;
  }

  struct NewLienRequest {
    StrategyDetails strategy;
    uint8 nlrType;
    bytes nlrDetails;
    MerkleData merkle;
    uint256 amount;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  struct Commitment {
    address tokenContract;
    uint256 tokenId;
    NewLienRequest lienRequest;
  }

  struct RefinanceCheckParams {
    uint256 position;
    Commitment incoming;
  }

  struct BorrowAndBuyParams {
    Commitment[] commitments;
    address invoker;
    uint256 purchasePrice;
    bytes purchaseData;
    address receiver;
  }

  function strategistNonce(address strategist) external view returns (uint256);

  function validateCommitment(Commitment calldata)
    external
    returns (bool, IAstariaRouter.LienDetails memory);

  function newPublicVault(
    uint256,
    address,
    uint256
  ) external returns (address);

  function newVault(address) external returns (address);

  function feeTo() external returns (address);

  function commitToLiens(Commitment[] calldata)
    external
    returns (uint256 totalBorrowed);

  function requestLienPosition(
    IAstariaRouter.LienDetails memory,
    IAstariaRouter.Commitment calldata
  ) external returns (uint256);

  function LIEN_TOKEN() external view returns (ILienToken);

  function TRANSFER_PROXY() external view returns (ITransferProxy);

  function WITHDRAW_IMPLEMENTATION() external view returns (address);

  function LIQUIDATION_IMPLEMENTATION() external view returns (address);

  function VAULT_IMPLEMENTATION() external view returns (address);

  function COLLATERAL_TOKEN() external view returns (ICollateralToken);

  function minInterestBPS() external view returns (uint256);

  function maxInterestRate() external view returns (uint256);

  function getStrategistFee(uint256) external view returns (uint256);

  function getProtocolFee(uint256) external view returns (uint256);

  function getBuyoutFee(uint256) external view returns (uint256);

  function getBuyoutInterestWindow() external view returns (uint32);

  function lendToVault(IVault vault, uint256 amount) external;

  function liquidate(uint256 collateralId, uint256 position)
    external
    returns (uint256 reserve);

  function canLiquidate(uint256 collateralId, uint256 position)
    external
    view
    returns (bool);

  function isValidVault(address) external view returns (bool);

  function isValidRefinance(ILienBase.Lien memory, LienDetails memory)
    external
    view
    returns (bool);

  event Liquidation(uint256 collateralId, uint256 position, uint256 reserve);
  event NewVault(address appraiser, address vault);

  error InvalidAddress(address);
  error InvalidRefinanceRate(uint256);
  error InvalidRefinanceDuration(uint256);
}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 * 
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.15;

import {IAuctionHouse} from "gpl/interfaces/IAuctionHouse.sol";
import {IERC721} from "gpl/interfaces/IERC721.sol";

interface ICollateralBase {
  function auctionVault(
    uint256,
    address,
    uint256
  ) external returns (uint256);

  function AUCTION_HOUSE() external view returns (IAuctionHouse);

  function auctionWindow() external view returns (uint256);

  function getUnderlying(uint256) external view returns (address, uint256);
}

interface ICollateralToken is ICollateralBase, IERC721 {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 * 
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

import {IERC721} from "gpl/interfaces/IERC721.sol";

import {IAstariaRouter} from "./IAstariaRouter.sol";

interface ILienBase {
  struct Lien {
    uint256 amount; //32
    uint256 collateralId; //32
    address payee; // 20
    uint32 start; // 4
    uint32 last; // 4
    uint32 duration; // 4
    uint240 rate; // 30
    bool active; // 1
    uint8 position; // 1
  }

  struct LienActionEncumber {
    address tokenContract;
    uint256 tokenId;
    IAstariaRouter.LienDetails terms;
    bytes32 strategyRoot;
    uint256 amount;
    address vault;
  }

  struct LienActionBuyout {
    IAstariaRouter.Commitment incoming;
    uint256 position;
    address receiver;
  }

  function calculateSlope(uint256 lienId) external returns (uint256 slope);

  function changeInSlope(uint256 lienId, uint256 paymentAmount)
    external
    view
    returns (uint256 slope);

  function stopLiens(uint256 collateralId)
    external
    returns (uint256 reserve, uint256[] memory lienIds);

  function getBuyout(uint256 collateralId, uint256 index)
    external
    view
    returns (uint256, uint256);

  function removeLiens(uint256 collateralId) external;

  function getInterest(uint256 collateralId, uint256 position)
    external
    view
    returns (uint256);

  function getInterest(uint256) external view returns (uint256);

  function getLiens(uint256 _collateralId)
    external
    view
    returns (uint256[] memory);

  function getLien(uint256 lienId) external view returns (Lien memory);

  function getLien(uint256 collateralId, uint256 position)
    external
    view
    returns (Lien memory);

  function createLien(LienActionEncumber calldata params)
    external
    returns (uint256 lienId);

  function buyoutLien(LienActionBuyout calldata params) external;

  function makePayment(uint256 collateralId, uint256 paymentAmount) external;

  function makePayment(
    uint256 collateralId,
    uint256 paymentAmount,
    address payer
  ) external;

  function makePayment(
    uint256 collateralId,
    uint256 paymentAmount,
    uint256 index
  ) external;

  function getTotalDebtForCollateralToken(uint256 collateralId)
    external
    view
    returns (uint256 totalDebt);

  function getTotalDebtForCollateralToken(
    uint256 collateralId,
    uint256 timestamp
  ) external view returns (uint256 totalDebt);

  function getPayee(uint256 lienId) external view returns (address);

  function setPayee(uint256 lienId, address payee) external;

  event NewLien(uint256 indexed lienId, Lien lien);
  event RemoveLien(
    uint256 indexed lienId,
    uint256 indexed collateralId,
    uint8 position
  );
  event RemovedLiens(uint256 indexed collateralId);
  event Payment(uint256 indexed lienId, uint256 amount);
  event BuyoutLien(address indexed buyer, uint256 lienId, uint256 buyout);
  event PayeeChanged(uint256 indexed lienId, address indexed payee);
  event File(bytes32 indexed what, bytes data);

  error UnsupportedFile();
  error InvalidBuyoutDetails(uint256 lienMaxAmount, uint256 owed);
  error InvalidTerms();
  error InvalidRefinance();

  enum InvalidStates {
    AUCTION,
    NO_DEPOSIT,
    DEBT_LIMIT
  }

  error InvalidCollateralState(InvalidStates);
}

interface ILienToken is ILienBase, IERC721 {}

pragma solidity ^0.8.17;

library Base64 {
  bytes internal constant TABLE =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) {
      return "";
    }

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(
          out,
          and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
        )
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
  }
}

// SPDX-License-Identifier: UNLICENSED

/**
 *       __  ___       __
 *  /\  /__'  |   /\  |__) |  /\
 * /~~\ .__/  |  /~~\ |  \ | /~~\
 *
 * Copyright (c) Astaria Labs, Inc
 */

pragma solidity ^0.8.17;

import {IERC721} from "gpl/interfaces/IERC721.sol";

library CollateralLookup {
  function computeId(address token, uint256 tokenId)
    internal
    view
    returns (uint256)
  {
    require(
      IERC721(token).supportsInterface(type(IERC721).interfaceId),
      "must support erc721"
    );
    require(
      IERC721(token).ownerOf(tokenId) != address(0),
      "must be a valid token id"
    );
    return uint256(keccak256(abi.encodePacked(token, tokenId)));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
  /**
   * @dev Returns the largest of two numbers.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the average of two numbers. The result is rounded towards
   * zero.
   */
  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow.
    return (a & b) + (a ^ b) / 2;
  }

  /**
   * @dev Returns the ceiling of the division of two numbers.
   *
   * This differs from standard division with `/` in that it rounds up instead
   * of rounding down.
   */
  function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b - 1) / b can overflow on addition, so we distribute.
    return a / b + (a % b == 0 ? 0 : 1);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.17;

interface IPausable {
  function paused() external view returns (bool);
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is IPausable {
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  bool private _paused;

  /**
   * @dev Initializes the contract in unpaused state.
   */
  constructor() {
    _paused = false;
  }

  /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
  function paused() public view virtual returns (bool) {
    return _paused;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  modifier whenNotPaused() {
    require(!paused(), "Pausable: paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  modifier whenPaused() {
    require(paused(), "Pausable: not paused");
    _;
  }

  /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
  function _pause() internal virtual whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
  function _unpause() internal virtual whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}