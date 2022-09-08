// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IAuctionHouse.sol";
import "./ISplitMain.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

/// @dev Pass this contract as the curator of an auction
contract JPGAuctionProxy {
    /// @dev Eth mainnet deployment of Zora's auction house
    IAuctionHouse constant auctionHouse =
        IAuctionHouse(0xE468cE99444174Bd3bBBEd09209577d25D1ad673);

    address immutable splitter;

    address public owner;

    error NotOwner();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    /// @dev Splitter is the already deployed split contract for
    /// the two parties that are splitting the commission
    constructor(address _splitter) {
        splitter = _splitter;

        owner = msg.sender;
    }

    /// @dev Allows the owner to start an auction of which this contract is the curator
    function setAuctionApproval(uint256 auctionId, bool approved)
        public
        onlyOwner
    {
        auctionHouse.setAuctionApproval(auctionId, approved);
    }

    /// @dev Forwards ETH directly to the splitter contract. The Zora contract will unwrap the eth for us and send
    /// it here. If for whatever reason that failed, we will have WETH in this contract (unfailable), so we add
    /// an emergency function to deal with that.
    receive() external payable {
        SafeTransferLib.safeTransferETH(splitter, address(this).balance);
    }

    /// @dev If zora's `endAuction` failed to send ETH here (or the splits contract rejected it and we failed to forward it), it winds up
    /// as WETH in this contract. If this happened, let the owner transfer it at their will. As well as if for whatever reason this contract
    /// received other ERC20 tokens.
    function emergencyERC20Withdraw(address token, address recipient)
        public
        onlyOwner
    {
        SafeTransferLib.safeTransfer(
            ERC20(token), recipient, ERC20(token).balanceOf(address(this))
        );
    }
}

pragma solidity ^0.8.13;

interface IAuctionHouse {
    struct Auction {
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract
        address tokenContract;
        // Whether or not the auction curator has approved the auction to start
        bool approved;
        // The current highest bid amount
        uint256 amount;
        // The length of time to run the auction for, after the first bid was made
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The sale percentage to send to the curator
        uint8 curatorFeePercentage;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
        // The address of the current highest bid
        address payable bidder;
        // The address of the auction's curator.
        // The curator can reject or approve an auction
        address payable curator;
        // The address of the ERC-20 currency to run the auction with.
        // If set to 0x0, the auction will be run in ETH
        address auctionCurrency;
    }

    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner,
        address curator,
        uint8 curatorFeePercentage,
        address auctionCurrency
    );

    event AuctionApprovalUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        bool approved
    );

    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );

    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address curator,
        address winner,
        uint256 amount,
        uint256 curatorFee,
        address auctionCurrency
    );

    event AuctionCanceled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    function createAuction(
        uint256 tokenId,
        address tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address payable curator,
        uint8 curatorFeePercentages,
        address auctionCurrency
    )
        external
        returns (uint256);

    function setAuctionApproval(uint256 auctionId, bool approved) external;

    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external;

    function createBid(uint256 auctionId, uint256 amount) external payable;

    function endAuction(uint256 auctionId) external;

    function cancelAuction(uint256 auctionId) external;

    function auctions(uint256 auctionId)
        external
        view
        returns (IAuctionHouse.Auction memory);
}

pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

/**
 * @title ISplitMain
 * @author 0xSplits <[email protected]>
 */
interface ISplitMain {
    /**
     * FUNCTIONS
     */

    function walletImplementation() external returns (address);

    function createSplit(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address controller
    )
        external
        returns (address);

    function predictImmutableSplitAddress(
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee
    )
        external
        view
        returns (address);

    function updateSplit(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee
    )
        external;

    function transferControl(address split, address newController) external;

    function cancelControlTransfer(address split) external;

    function acceptControl(address split) external;

    function makeSplitImmutable(address split) external;

    function distributeETH(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    )
        external;

    function updateAndDistributeETH(
        address split,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    )
        external;

    function distributeERC20(
        address split,
        ERC20 token,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    )
        external;

    function updateAndDistributeERC20(
        address split,
        ERC20 token,
        address[] calldata accounts,
        uint32[] calldata percentAllocations,
        uint32 distributorFee,
        address distributorAddress
    )
        external;

    function withdraw(
        address account,
        uint256 withdrawETH,
        ERC20[] calldata tokens
    )
        external;

    /**
     * EVENTS
     */

    /**
     * @notice emitted after each successful split creation
     * @param split Address of the created split
     */
    event CreateSplit(address indexed split);

    /**
     * @notice emitted after each successful split update
     * @param split Address of the updated split
     */
    event UpdateSplit(address indexed split);

    /**
     * @notice emitted after each initiated split control transfer
     * @param split Address of the split control transfer was initiated for
     * @param newPotentialController Address of the split's new potential controller
     */
    event InitiateControlTransfer(
        address indexed split, address indexed newPotentialController
    );

    /**
     * @notice emitted after each canceled split control transfer
     * @param split Address of the split control transfer was canceled for
     */
    event CancelControlTransfer(address indexed split);

    /**
     * @notice emitted after each successful split control transfer
     * @param split Address of the split control was transferred for
     * @param previousController Address of the split's previous controller
     * @param newController Address of the split's new controller
     */
    event ControlTransfer(
        address indexed split,
        address indexed previousController,
        address indexed newController
    );

    /**
     * @notice emitted after each successful ETH balance split
     * @param split Address of the split that distributed its balance
     * @param amount Amount of ETH distributed
     * @param distributorAddress Address to credit distributor fee to
     */
    event DistributeETH(
        address indexed split,
        uint256 amount,
        address indexed distributorAddress
    );

    /**
     * @notice emitted after each successful ERC20 balance split
     * @param split Address of the split that distributed its balance
     * @param token Address of ERC20 distributed
     * @param amount Amount of ERC20 distributed
     * @param distributorAddress Address to credit distributor fee to
     */
    event DistributeERC20(
        address indexed split,
        ERC20 indexed token,
        uint256 amount,
        address indexed distributorAddress
    );

    /**
     * @notice emitted after each successful withdrawal
     * @param account Address that funds were withdrawn to
     * @param ethAmount Amount of ETH withdrawn
     * @param tokens Addresses of ERC20s withdrawn
     * @param tokenAmounts Amounts of corresponding ERC20s withdrawn
     */
    event Withdrawal(
        address indexed account,
        uint256 ethAmount,
        ERC20[] tokens,
        uint256[] tokenAmounts
    );
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