// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
 *                                     _H_
 *                                    /___\
 *                                    \888/
 * ~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~U~^~^~^~^~^~^~^
 *                       ~              |
 *       ~                        o     |        ~
 *                 ___        o         |
 *        _,.--,.'`   `~'-.._    O      |
 *       /_  .-"      _   /_\'.         |   ~
 *      .-';'       (( `  \0/  `\       #
 *     /__;          ((_  ,_     |  ,   #
 *     .-;                  \_   /  #  _#,
 *    /  ;    .-' /  _.--""-.\`~`   `#(('\\        ~
 *    ;-';   /   / .'                  )) \\
 *        ; /.--'.'                   ((   ))
 *         \     |        ~            \\ ((
 *          \    |                      )) `
 *    ~      \   |                      `
 *            \  |
 *            .` `""-.
 *          .'        \         ~               ~
 *          |    |\    |
 *          \   /  '-._|
 *           \.'
 */

import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";
import {Pair, ReservoirOracle} from "caviar/Pair.sol";
import {IRoyaltyRegistry} from "royalty-registry-solidity/IRoyaltyRegistry.sol";

import {PrivatePool} from "./PrivatePool.sol";
import {IStolenNftOracle} from "./interfaces/IStolenNftOracle.sol";

/// @title Eth Router
/// @author out.eth (@outdoteth)
/// @notice This contract is used to route buy, sell, and change orders to multiple pools in one transaction. It
/// will route the orders to either a private pool or a public pool. If the order goes to a public pool, then users
/// can choose whether or not they would like to pay royalties. The only base token which is supported is native ETH.
contract EthRouter is ERC721TokenReceiver {
    using SafeTransferLib for address;
    using SafeTransferLib for address payable;

    struct Buy {
        address payable pool;
        uint256[] tokenIds;
        uint256[] tokenWeights;
        PrivatePool.MerkleMultiProof proof;
        uint256 baseTokenAmount;
        bool isPublicPool;
    }

    struct Sell {
        address payable pool;
        uint256[] tokenIds;
        uint256[] tokenWeights;
        PrivatePool.MerkleMultiProof proof;
        IStolenNftOracle.Message[] stolenNftProofs;
        bool isPublicPool;
        bytes32[][] publicPoolProofs;
    }

    struct Change {
        address payable pool;
        uint256[] inputTokenIds;
        uint256[] inputTokenWeights;
        PrivatePool.MerkleMultiProof inputProof;
        IStolenNftOracle.Message[] stolenNftProofs;
        uint256[] outputTokenIds;
        uint256[] outputTokenWeights;
        PrivatePool.MerkleMultiProof outputProof;
        uint256 baseTokenAmount;
        bool isPublicPool;
    }

    error DeadlinePassed();
    error OutputAmountTooSmall();
    error PriceOutOfRange();
    error InvalidRoyaltyFee();
    error MismatchedTokenIds();

    address public immutable royaltyRegistry;

    receive() external payable {}

    constructor(address _royaltyRegistry) {
        royaltyRegistry = _royaltyRegistry;
    }

    /// @notice Executes a series of buy operations against public or private pools.
    /// @param buys The buy operations to execute.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// If it's set to 0 then there is no deadline.
    /// @param payRoyalties Whether to pay royalties or not.
    function buy(Buy[] calldata buys, uint256 deadline, bool payRoyalties) public payable {
        // check that the deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // loop through and execute the the buys
        for (uint256 i = 0; i < buys.length; i++) {
            // fetch the nft address (PrivatePool and Pair both have an nft() method)
            address nft = PrivatePool(buys[i].pool).nft();

            if (buys[i].isPublicPool) {
                // execute the buy against a public pool
                uint256 inputAmount = Pair(buys[i].pool).nftBuy{value: buys[i].baseTokenAmount}(
                    buys[i].tokenIds, buys[i].baseTokenAmount, 0
                );

                // pay the royalties if buyer has opted-in
                if (payRoyalties) {
                    uint256 salePrice = inputAmount / buys[i].tokenIds.length;
                    for (uint256 j = 0; j < buys[i].tokenIds.length; j++) {
                        // get the royalty fee and recipient
                        (uint256 royaltyFee, address royaltyRecipient) = getRoyalty(nft, buys[i].tokenIds[j], salePrice);

                        if (royaltyFee > 0 && royaltyRecipient != address(0)) {
                            // transfer the royalty fee to the royalty recipient
                            royaltyRecipient.safeTransferETH(royaltyFee);
                        }
                    }
                }
            } else {
                // execute the buy against a private pool
                PrivatePool(buys[i].pool).buy{value: buys[i].baseTokenAmount}(
                    buys[i].tokenIds, buys[i].tokenWeights, buys[i].proof
                );
            }

            for (uint256 j = 0; j < buys[i].tokenIds.length; j++) {
                // transfer the NFT to the caller
                ERC721(nft).safeTransferFrom(address(this), msg.sender, buys[i].tokenIds[j]);
            }
        }

        // refund any surplus ETH to the caller
        if (address(this).balance > 0) {
            msg.sender.safeTransferETH(address(this).balance);
        }
    }

    /// @notice Executes a series of sell operations against public or private pools.
    /// @param sells The sell operations to execute.
    /// @param minOutputAmount The minimum amount of output tokens that must be received for the transaction to succeed.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// Set to 0 for there to be no deadline.
    /// @param payRoyalties Whether to pay royalties or not.
    function sell(Sell[] calldata sells, uint256 minOutputAmount, uint256 deadline, bool payRoyalties) public {
        // check that the deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // loop through and execute the sells
        for (uint256 i = 0; i < sells.length; i++) {
            // fetch the nft address (PrivatePool and Pair both have an nft() method)
            address nft = PrivatePool(sells[i].pool).nft();

            // transfer the NFTs into the router from the caller
            for (uint256 j = 0; j < sells[i].tokenIds.length; j++) {
                ERC721(nft).safeTransferFrom(msg.sender, address(this), sells[i].tokenIds[j]);
            }

            // approve the pair to transfer NFTs from the router
            _approveNfts(nft, sells[i].pool);

            if (sells[i].isPublicPool) {
                // execute the sell against a public pool
                uint256 outputAmount = Pair(sells[i].pool).nftSell(
                    sells[i].tokenIds,
                    0,
                    0,
                    sells[i].publicPoolProofs,
                    // ReservoirOracle.Message[] is the exact same as IStolenNftOracle.Message[] and can be
                    // decoded/encoded 1-to-1.
                    abi.decode(abi.encode(sells[i].stolenNftProofs), (ReservoirOracle.Message[]))
                );

                // pay the royalties if seller has opted-in
                if (payRoyalties) {
                    uint256 salePrice = outputAmount / sells[i].tokenIds.length;
                    for (uint256 j = 0; j < sells[i].tokenIds.length; j++) {
                        // get the royalty fee and recipient
                        (uint256 royaltyFee, address royaltyRecipient) =
                            getRoyalty(nft, sells[i].tokenIds[j], salePrice);

                        if (royaltyFee > 0 && royaltyRecipient != address(0)) {
                            // transfer the royalty fee to the royalty recipient
                            royaltyRecipient.safeTransferETH(royaltyFee);
                        }
                    }
                }
            } else {
                // execute the sell against a private pool
                PrivatePool(sells[i].pool).sell(
                    sells[i].tokenIds, sells[i].tokenWeights, sells[i].proof, sells[i].stolenNftProofs
                );
            }
        }

        // check that the output amount is greater than the minimum
        if (address(this).balance < minOutputAmount) {
            revert OutputAmountTooSmall();
        }

        // transfer the output amount to the caller
        msg.sender.safeTransferETH(address(this).balance);
    }

    /// @notice Executes a deposit to a private pool (transfers NFTs and ETH to the pool).
    /// @param privatePool The private pool to deposit to.
    /// @param nft The NFT contract address.
    /// @param tokenIds The token IDs of the NFTs to deposit.
    /// @param minPrice The minimum price of the pool. Will revert if price is smaller than this.
    /// @param maxPrice The maximum price of the pool. Will revert if price is greater than this.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// Set to 0 for deadline to be ignored.
    function deposit(
        address payable privatePool,
        address nft,
        uint256[] calldata tokenIds,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline
    ) public payable {
        // check deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // check pool price is in between min and max
        uint256 price = PrivatePool(privatePool).price();
        if (price > maxPrice || price < minPrice) {
            revert PriceOutOfRange();
        }

        // transfer NFTs from caller
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        // approve the pair to transfer NFTs from the router
        _approveNfts(nft, privatePool);

        // execute deposit
        PrivatePool(privatePool).deposit{value: msg.value}(tokenIds, msg.value);
    }

    /// @notice Executes a series of change operations against a private pool.
    /// @param changes The change operations to execute.
    /// @param deadline The deadline for the transaction to be mined. Will revert if timestamp is greater than deadline.
    /// Set to 0 for deadline to be ignored.
    function change(Change[] calldata changes, uint256 deadline) public payable {
        // check deadline has not passed (if any)
        if (block.timestamp > deadline && deadline != 0) {
            revert DeadlinePassed();
        }

        // loop through and execute the changes
        for (uint256 i = 0; i < changes.length; i++) {
            Change memory _change = changes[i];

            // fetch the nft address (PrivatePool and Pair both have an nft() method)
            address nft = PrivatePool(_change.pool).nft();

            // transfer NFTs from caller
            for (uint256 j = 0; j < changes[i].inputTokenIds.length; j++) {
                ERC721(nft).safeTransferFrom(msg.sender, address(this), _change.inputTokenIds[j]);
            }

            // approve the pair to transfer NFTs from the router
            _approveNfts(nft, _change.pool);

            if (_change.isPublicPool) {
                // check that the input token ids length matches the output token ids length
                if (_change.inputTokenIds.length != _change.outputTokenIds.length) {
                    revert MismatchedTokenIds();
                }

                // empty proofs assumes that we only change against floor public pools
                bytes32[][] memory publicPoolProofs = new bytes32[][](0);

                // get some fractional tokens for the input tokens
                uint256 fractionalTokenAmount = Pair(_change.pool).wrap(
                    _change.inputTokenIds,
                    publicPoolProofs,
                    // ReservoirOracle.Message[] is the exact same as IStolenNftOracle.Message[] and can be
                    // decoded/encoded 1-to-1.
                    abi.decode(abi.encode(_change.stolenNftProofs), (ReservoirOracle.Message[]))
                );

                // buy the surplus fractional tokens required to pay the fee
                uint256 fractionalTokenFee = fractionalTokenAmount * 3 / 1000;
                Pair(_change.pool).buy{value: _change.baseTokenAmount}(fractionalTokenFee, _change.baseTokenAmount, 0);

                // exchange the fractional tokens for the target output tokens
                Pair(_change.pool).unwrap(_change.outputTokenIds, true);
            } else {
                // execute change
                PrivatePool(_change.pool).change{value: _change.baseTokenAmount}(
                    _change.inputTokenIds,
                    _change.inputTokenWeights,
                    _change.inputProof,
                    _change.stolenNftProofs,
                    _change.outputTokenIds,
                    _change.outputTokenWeights,
                    _change.outputProof
                );
            }

            // transfer NFTs to caller
            for (uint256 j = 0; j < changes[i].outputTokenIds.length; j++) {
                ERC721(nft).safeTransferFrom(address(this), msg.sender, _change.outputTokenIds[j]);
            }
        }

        // refund any surplus ETH to the caller
        if (address(this).balance > 0) {
            msg.sender.safeTransferETH(address(this).balance);
        }
    }

    /// @notice Gets the royalty and recipient for a given NFT and sale price. Looks up the royalty info from the
    /// manifold registry.
    /// @param nft The NFT contract address.
    /// @param tokenId The token ID of the NFT.
    /// @param salePrice The sale price of the NFT.
    /// @return royaltyFee The royalty fee to pay.
    /// @return recipient The address to pay the royalty fee to.
    function getRoyalty(address nft, uint256 tokenId, uint256 salePrice)
        public
        view
        returns (uint256 royaltyFee, address recipient)
    {
        // get the royalty lookup address
        address lookupAddress = IRoyaltyRegistry(royaltyRegistry).getRoyaltyLookupAddress(nft);

        if (IERC2981(lookupAddress).supportsInterface(type(IERC2981).interfaceId)) {
            // get the royalty fee from the registry
            (recipient, royaltyFee) = IERC2981(lookupAddress).royaltyInfo(tokenId, salePrice);

            // revert if the royalty fee is greater than the sale price
            if (royaltyFee > salePrice) revert InvalidRoyaltyFee();
        }
    }

    function _approveNfts(address nft, address target) internal {
        // check if the router is already approved to transfer NFTs from the caller
        if (ERC721(nft).isApprovedForAll(address(this), target)) return;

        // approve the target to transfer NFTs from the router
        ERC721(nft).setApprovalForAll(target, true);
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC721.sol";
import "solmate/utils/MerkleProofLib.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "openzeppelin/utils/math/Math.sol";
import "reservoir-oracle/ReservoirOracle.sol";

import "./LpToken.sol";
import "./Caviar.sol";
import "./StolenNftFilterOracle.sol";

/// @title Pair
/// @author out.eth (@outdoteth)
/// @notice A pair of an NFT and a base token that can be used to create and trade fractionalized NFTs.
contract Pair is ERC20, ERC721TokenReceiver {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    uint256 public constant CLOSE_GRACE_PERIOD = 7 days;
    uint256 private constant ONE = 1e18;
    uint256 private constant MINIMUM_LIQUIDITY = 100_000;

    address public immutable nft;
    address public immutable baseToken; // address(0) for ETH
    bytes32 public immutable merkleRoot;
    LpToken public immutable lpToken;
    Caviar public immutable caviar;
    uint256 public closeTimestamp;

    event Add(uint256 indexed baseTokenAmount, uint256 indexed fractionalTokenAmount, uint256 indexed lpTokenAmount);
    event Remove(uint256 indexed baseTokenAmount, uint256 indexed fractionalTokenAmount, uint256 indexed lpTokenAmount);
    event Buy(uint256 indexed inputAmount, uint256 indexed outputAmount);
    event Sell(uint256 indexed inputAmount, uint256 indexed outputAmount);
    event Wrap(uint256[] indexed tokenIds);
    event Unwrap(uint256[] indexed tokenIds);
    event Close(uint256 indexed closeTimestamp);
    event Withdraw(uint256 indexed tokenId);

    constructor(
        address _nft,
        address _baseToken,
        bytes32 _merkleRoot,
        string memory pairSymbol,
        string memory nftName,
        string memory nftSymbol
    ) ERC20(string.concat(nftName, " fractional token"), string.concat("f", nftSymbol), 18) {
        nft = _nft;
        baseToken = _baseToken; // use address(0) for native ETH
        merkleRoot = _merkleRoot;
        lpToken = new LpToken(pairSymbol);
        caviar = Caviar(msg.sender);
    }

    // ************************ //
    //      Core AMM logic      //
    // ***********************  //

    /// @notice Adds liquidity to the pair.
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param fractionalTokenAmount The amount of fractional tokens to add.
    /// @param minLpTokenAmount The minimum amount of LP tokens to mint.
    /// @param minPrice The minimum price that the pool should currently be at.
    /// @param maxPrice The maximum price that the pool should currently be at.
    /// @param deadline The deadline before the trade expires.
    /// @return lpTokenAmount The amount of LP tokens minted.
    function add(
        uint256 baseTokenAmount,
        uint256 fractionalTokenAmount,
        uint256 minLpTokenAmount,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline
    ) public payable returns (uint256 lpTokenAmount) {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // check the token amount inputs are not zero
        require(baseTokenAmount > 0 && fractionalTokenAmount > 0, "Input token amount is zero");

        // check that correct eth input was sent - if the baseToken equals address(0) then native ETH is used
        require(baseToken == address(0) ? msg.value == baseTokenAmount : msg.value == 0, "Invalid ether input");

        uint256 lpTokenSupply = lpToken.totalSupply();

        // check that the price is within the bounds if there is liquidity in the pool
        if (lpTokenSupply != 0) {
            uint256 _price = price();
            require(_price >= minPrice && _price <= maxPrice, "Slippage: price out of bounds");
        }

        // calculate the lp token shares to mint
        lpTokenAmount = addQuote(baseTokenAmount, fractionalTokenAmount, lpTokenSupply);

        // check that the amount of lp tokens outputted is greater than the min amount
        require(lpTokenAmount >= minLpTokenAmount, "Slippage: lp token amount out");

        // *** Effects *** //

        // transfer fractional tokens in
        _transferFrom(msg.sender, address(this), fractionalTokenAmount);

        // *** Interactions *** //

        // mint lp tokens to sender
        lpToken.mint(msg.sender, lpTokenAmount);

        // transfer first MINIMUM_LIQUIDITY lp tokens to the owner
        if (lpTokenSupply == 0) {
            lpToken.mint(caviar.owner(), MINIMUM_LIQUIDITY);
        }

        // transfer base tokens in if the base token is not ETH
        if (baseToken != address(0)) {
            // transfer base tokens in
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), baseTokenAmount);
        }

        emit Add(baseTokenAmount, fractionalTokenAmount, lpTokenAmount);
    }

    /// @notice Removes liquidity from the pair.
    /// @param lpTokenAmount The amount of LP tokens to burn.
    /// @param minBaseTokenOutputAmount The minimum amount of base tokens to receive.
    /// @param minFractionalTokenOutputAmount The minimum amount of fractional tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @return baseTokenOutputAmount The amount of base tokens received.
    /// @return fractionalTokenOutputAmount The amount of fractional tokens received.
    function remove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 minFractionalTokenOutputAmount,
        uint256 deadline
    ) public returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // calculate the output amounts
        (baseTokenOutputAmount, fractionalTokenOutputAmount) = removeQuote(lpTokenAmount);

        // check that the base token output amount is greater than the min amount
        require(baseTokenOutputAmount >= minBaseTokenOutputAmount, "Slippage: base token amount out");

        // check that the fractional token output amount is greater than the min amount
        require(fractionalTokenOutputAmount >= minFractionalTokenOutputAmount, "Slippage: fractional token out");

        // *** Effects *** //

        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, fractionalTokenOutputAmount);

        // *** Interactions *** //

        // burn lp tokens from sender
        lpToken.burn(msg.sender, lpTokenAmount);

        if (baseToken == address(0)) {
            // if base token is native ETH then send ether to sender
            msg.sender.safeTransferETH(baseTokenOutputAmount);
        } else {
            // transfer base tokens to sender
            ERC20(baseToken).safeTransfer(msg.sender, baseTokenOutputAmount);
        }

        emit Remove(baseTokenOutputAmount, fractionalTokenOutputAmount, lpTokenAmount);
    }

    /// @notice Buys fractional tokens from the pair.
    /// @param outputAmount The amount of fractional tokens to buy.
    /// @param maxInputAmount The maximum amount of base tokens to spend.
    /// @param deadline The deadline before the trade expires.
    /// @return inputAmount The amount of base tokens spent.
    function buy(uint256 outputAmount, uint256 maxInputAmount, uint256 deadline)
        public
        payable
        returns (uint256 inputAmount)
    {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // check that correct eth input was sent - if the baseToken equals address(0) then native ETH is used
        require(baseToken == address(0) ? msg.value == maxInputAmount : msg.value == 0, "Invalid ether input");

        // calculate required input amount using xyk invariant
        inputAmount = buyQuote(outputAmount);

        // check that the required amount of base tokens is less than the max amount
        require(inputAmount <= maxInputAmount, "Slippage: amount in");

        // *** Effects *** //

        // transfer fractional tokens to sender
        _transferFrom(address(this), msg.sender, outputAmount);

        // *** Interactions *** //

        if (baseToken == address(0)) {
            // refund surplus eth
            uint256 refundAmount = maxInputAmount - inputAmount;
            if (refundAmount > 0) msg.sender.safeTransferETH(refundAmount);
        } else {
            // transfer base tokens in
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), inputAmount);
        }

        emit Buy(inputAmount, outputAmount);
    }

    /// @notice Sells fractional tokens to the pair.
    /// @param inputAmount The amount of fractional tokens to sell.
    /// @param deadline The deadline before the trade expires.
    /// @param minOutputAmount The minimum amount of base tokens to receive.
    /// @return outputAmount The amount of base tokens received.
    function sell(uint256 inputAmount, uint256 minOutputAmount, uint256 deadline)
        public
        returns (uint256 outputAmount)
    {
        // *** Checks *** //

        // check that the trade has not expired
        require(deadline == 0 || deadline >= block.timestamp, "Expired");

        // calculate output amount using xyk invariant
        outputAmount = sellQuote(inputAmount);

        // check that the outputted amount of fractional tokens is greater than the min amount
        require(outputAmount >= minOutputAmount, "Slippage: amount out");

        // *** Effects *** //

        // transfer fractional tokens from sender
        _transferFrom(msg.sender, address(this), inputAmount);

        // *** Interactions *** //

        if (baseToken == address(0)) {
            // transfer ether out
            msg.sender.safeTransferETH(outputAmount);
        } else {
            // transfer base tokens out
            ERC20(baseToken).safeTransfer(msg.sender, outputAmount);
        }

        emit Sell(inputAmount, outputAmount);
    }

    // ******************** //
    //      Wrap logic      //
    // ******************** //

    /// @notice Wraps NFTs into fractional tokens.
    /// @param tokenIds The ids of the NFTs to wrap.
    /// @param proofs The merkle proofs for the NFTs proving that they can be used in the pair.
    /// @return fractionalTokenAmount The amount of fractional tokens minted.
    function wrap(uint256[] calldata tokenIds, bytes32[][] calldata proofs, ReservoirOracle.Message[] calldata messages)
        public
        returns (uint256 fractionalTokenAmount)
    {
        // *** Checks *** //

        // check that wrapping is not closed
        require(closeTimestamp == 0, "Wrap: closed");

        // check the tokens exist in the merkle root
        _validateTokenIds(tokenIds, proofs);

        // check that the tokens are not stolen with reservoir oracle
        _validateTokensAreNotStolen(tokenIds, messages);

        // *** Effects *** //

        // mint fractional tokens to sender
        fractionalTokenAmount = tokenIds.length * ONE;
        _mint(msg.sender, fractionalTokenAmount);

        // *** Interactions *** //

        // transfer nfts from sender
        for (uint256 i = 0; i < tokenIds.length;) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            unchecked {
                i++;
            }
        }

        emit Wrap(tokenIds);
    }

    /// @notice Unwraps fractional tokens into NFTs.
    /// @param tokenIds The ids of the NFTs to unwrap.
    /// @param withFee Whether to pay a fee for unwrapping or not.
    /// @return fractionalTokenAmount The amount of fractional tokens burned.
    function unwrap(uint256[] calldata tokenIds, bool withFee) public returns (uint256 fractionalTokenAmount) {
        // *** Effects *** //

        // burn fractional tokens from sender
        fractionalTokenAmount = tokenIds.length * ONE;
        _burn(msg.sender, fractionalTokenAmount);

        // Take the fee if withFee is true
        if (withFee) {
            // calculate fee
            uint256 fee = fractionalTokenAmount * 3 / 1000;

            // transfer fee from sender
            _transferFrom(msg.sender, address(this), fee);
            fractionalTokenAmount += fee;
        }

        // transfer nfts to sender
        for (uint256 i = 0; i < tokenIds.length;) {
            ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            unchecked {
                i++;
            }
        }

        emit Unwrap(tokenIds);
    }

    // *********************** //
    //      NFT AMM logic      //
    // *********************** //

    /// @notice nftAdd Adds liquidity to the pair using NFTs.
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param tokenIds The ids of the NFTs to add.
    /// @param minLpTokenAmount The minimum amount of lp tokens to receive.
    /// @param minPrice The minimum price of the pair.
    /// @param maxPrice The maximum price of the pair.
    /// @param deadline The deadline for the transaction.
    /// @param proofs The merkle proofs for the NFTs.
    /// @return lpTokenAmount The amount of lp tokens minted.
    function nftAdd(
        uint256 baseTokenAmount,
        uint256[] calldata tokenIds,
        uint256 minLpTokenAmount,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    ) public payable returns (uint256 lpTokenAmount) {
        // wrap the incoming NFTs into fractional tokens
        uint256 fractionalTokenAmount = wrap(tokenIds, proofs, messages);

        // add liquidity using the fractional tokens and base tokens
        lpTokenAmount = add(baseTokenAmount, fractionalTokenAmount, minLpTokenAmount, minPrice, maxPrice, deadline);
    }

    /// @notice Removes liquidity from the pair using NFTs.
    /// @param lpTokenAmount The amount of lp tokens to remove.
    /// @param minBaseTokenOutputAmount The minimum amount of base tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @param tokenIds The ids of the NFTs to remove.
    /// @param withFee Whether to pay a fee for unwrapping or not.
    /// @return baseTokenOutputAmount The amount of base tokens received.
    /// @return fractionalTokenOutputAmount The amount of fractional tokens received.
    function nftRemove(
        uint256 lpTokenAmount,
        uint256 minBaseTokenOutputAmount,
        uint256 deadline,
        uint256[] calldata tokenIds,
        bool withFee
    ) public returns (uint256 baseTokenOutputAmount, uint256 fractionalTokenOutputAmount) {
        // remove liquidity and send fractional tokens and base tokens to sender
        (baseTokenOutputAmount, fractionalTokenOutputAmount) =
            remove(lpTokenAmount, minBaseTokenOutputAmount, tokenIds.length * ONE, deadline);

        // unwrap the fractional tokens into NFTs and send to sender
        unwrap(tokenIds, withFee);
    }

    /// @notice Buys NFTs from the pair using base tokens.
    /// @param tokenIds The ids of the NFTs to buy.
    /// @param maxInputAmount The maximum amount of base tokens to spend.
    /// @param deadline The deadline before the trade expires.
    /// @return inputAmount The amount of base tokens spent.
    function nftBuy(uint256[] calldata tokenIds, uint256 maxInputAmount, uint256 deadline)
        public
        payable
        returns (uint256 inputAmount)
    {
        // buy fractional tokens using base tokens
        inputAmount = buy(tokenIds.length * ONE, maxInputAmount, deadline);

        // unwrap the fractional tokens into NFTs and send to sender
        unwrap(tokenIds, false);
    }

    /// @notice Sells NFTs to the pair for base tokens.
    /// @param tokenIds The ids of the NFTs to sell.
    /// @param minOutputAmount The minimum amount of base tokens to receive.
    /// @param deadline The deadline before the trade expires.
    /// @param proofs The merkle proofs for the NFTs.
    /// @return outputAmount The amount of base tokens received.
    function nftSell(
        uint256[] calldata tokenIds,
        uint256 minOutputAmount,
        uint256 deadline,
        bytes32[][] calldata proofs,
        ReservoirOracle.Message[] calldata messages
    ) public returns (uint256 outputAmount) {
        // wrap the incoming NFTs into fractional tokens
        uint256 inputAmount = wrap(tokenIds, proofs, messages);

        // sell fractional tokens for base tokens
        outputAmount = sell(inputAmount, minOutputAmount, deadline);
    }

    // ****************************** //
    //      Emergency exit logic      //
    // ****************************** //

    /// @notice Closes the pair to new wraps.
    /// @dev Can only be called by the caviar owner. This is used as an emergency exit in case
    ///      the caviar owner suspects that the pair has been compromised.
    function close() public {
        // check that the sender is the caviar owner
        require(caviar.owner() == msg.sender, "Close: not owner");

        // set the close timestamp with a grace period
        closeTimestamp = block.timestamp + CLOSE_GRACE_PERIOD;

        // remove the pair from the Caviar contract
        caviar.destroy(nft, baseToken, merkleRoot);

        emit Close(closeTimestamp);
    }

    /// @notice Withdraws a particular NFT from the pair.
    /// @dev Can only be called by the caviar owner after the close grace period has passed. This
    ///      is used to auction off the NFTs in the pair in case NFTs get stuck due to liquidity
    ///      imbalances. Proceeds from the auction should be distributed pro rata to fractional
    ///      token holders. See documentation for more details.
    function withdraw(uint256 tokenId) public {
        // check that the sender is the caviar owner
        require(caviar.owner() == msg.sender, "Withdraw: not owner");

        // check that the close period has been set
        require(closeTimestamp != 0, "Withdraw not initiated");

        // check that the close grace period has passed
        require(block.timestamp >= closeTimestamp, "Not withdrawable yet");

        // transfer the nft to the caviar owner
        ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdraw(tokenId);
    }

    // ***************** //
    //      Getters      //
    // ***************** //

    function baseTokenReserves() public view returns (uint256) {
        return _baseTokenReserves();
    }

    function fractionalTokenReserves() public view returns (uint256) {
        return balanceOf[address(this)];
    }

    /// @notice The current price of one fractional token in base tokens with 18 decimals of precision.
    /// @dev Calculated by dividing the base token reserves by the fractional token reserves.
    /// @return price The price of one fractional token in base tokens * 1e18.
    function price() public view returns (uint256) {
        uint256 exponent = baseToken == address(0) ? 18 : (36 - ERC20(baseToken).decimals());
        return (_baseTokenReserves() * 10 ** exponent) / fractionalTokenReserves();
    }

    /// @notice The amount of base tokens required to buy a given amount of fractional tokens.
    /// @dev Calculated using the xyk invariant and a 30bps fee.
    /// @param outputAmount The amount of fractional tokens to buy.
    /// @return inputAmount The amount of base tokens required.
    function buyQuote(uint256 outputAmount) public view returns (uint256) {
        return FixedPointMathLib.mulDivUp(
            outputAmount * 1000, baseTokenReserves(), (fractionalTokenReserves() - outputAmount) * 990
        );
    }

    /// @notice The amount of base tokens received for selling a given amount of fractional tokens.
    /// @dev Calculated using the xyk invariant and a 30bps fee.
    /// @param inputAmount The amount of fractional tokens to sell.
    /// @return outputAmount The amount of base tokens received.
    function sellQuote(uint256 inputAmount) public view returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 990;
        return (inputAmountWithFee * baseTokenReserves()) / ((fractionalTokenReserves() * 1000) + inputAmountWithFee);
    }

    /// @notice The amount of lp tokens received for adding a given amount of base tokens and fractional tokens.
    /// @dev Calculated as a share of existing deposits. If there are no existing deposits, then initializes to
    ///      sqrt(baseTokenAmount * fractionalTokenAmount).
    /// @param baseTokenAmount The amount of base tokens to add.
    /// @param fractionalTokenAmount The amount of fractional tokens to add.
    /// @return lpTokenAmount The amount of lp tokens received.
    function addQuote(uint256 baseTokenAmount, uint256 fractionalTokenAmount, uint256 lpTokenSupply)
        public
        view
        returns (uint256)
    {
        if (lpTokenSupply != 0) {
            // calculate amount of lp tokens as a fraction of existing reserves
            uint256 baseTokenShare = (baseTokenAmount * lpTokenSupply) / baseTokenReserves();
            uint256 fractionalTokenShare = (fractionalTokenAmount * lpTokenSupply) / fractionalTokenReserves();
            return Math.min(baseTokenShare, fractionalTokenShare);
        } else {
            // if there is no liquidity then init
            return Math.sqrt(baseTokenAmount * fractionalTokenAmount) - MINIMUM_LIQUIDITY;
        }
    }

    /// @notice The amount of base tokens and fractional tokens received for burning a given amount of lp tokens.
    /// @dev Calculated as a share of existing deposits.
    /// @param lpTokenAmount The amount of lp tokens to burn.
    /// @return baseTokenAmount The amount of base tokens received.
    /// @return fractionalTokenAmount The amount of fractional tokens received.
    function removeQuote(uint256 lpTokenAmount) public view returns (uint256, uint256) {
        uint256 lpTokenSupply = lpToken.totalSupply();
        uint256 baseTokenOutputAmount = (baseTokenReserves() * lpTokenAmount) / lpTokenSupply;
        uint256 fractionalTokenOutputAmount = (fractionalTokenReserves() * lpTokenAmount) / lpTokenSupply;
        uint256 upperFractionalTokenOutputAmount = (fractionalTokenReserves() * (lpTokenAmount + 1)) / lpTokenSupply;

        if (
            fractionalTokenOutputAmount % 1e18 != 0
                && upperFractionalTokenOutputAmount - fractionalTokenOutputAmount <= 1000 && lpTokenSupply > 1e15
        ) {
            fractionalTokenOutputAmount = upperFractionalTokenOutputAmount;
        }

        return (baseTokenOutputAmount, fractionalTokenOutputAmount);
    }

    // ************************ //
    //      Internal utils      //
    // ************************ //

    function _transferFrom(address from, address to, uint256 amount) internal returns (bool) {
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    function _validateTokensAreNotStolen(uint256[] calldata tokenIds, ReservoirOracle.Message[] calldata messages)
        internal
        view
    {
        address stolenNftFilterAddress = caviar.stolenNftFilterOracle();

        // if filter address is not set then no need to check if nfts are stolen
        if (stolenNftFilterAddress == address(0)) return;

        // validate that nfts are not stolen
        StolenNftFilterOracle(stolenNftFilterAddress).validateTokensAreNotStolen(nft, tokenIds, messages);
    }

    /// @dev Validates that the given tokenIds are valid for the contract's merkle root. Reverts
    ///      if any of the tokenId proofs are invalid.
    function _validateTokenIds(uint256[] calldata tokenIds, bytes32[][] calldata proofs) internal view {
        // if merkle root is not set then all tokens are valid
        if (merkleRoot == bytes32(0)) return;

        // validate merkle proofs against merkle root
        for (uint256 i = 0; i < tokenIds.length;) {
            bool isValid = MerkleProofLib.verify(
                proofs[i],
                merkleRoot,
                // double hash to prevent second preimage attacks
                keccak256(bytes.concat(keccak256(abi.encode(tokenIds[i]))))
            );

            require(isValid, "Invalid merkle proof");

            unchecked {
                i++;
            }
        }
    }

    /// @dev Returns the current base token reserves. If the base token is ETH then it ignores
    ///      the msg.value that is being sent in the current call context - this is to ensure the
    ///      xyk math is correct in the buy() and add() functions.
    function _baseTokenReserves() internal view returns (uint256) {
        return baseToken == address(0)
            ? address(this).balance - msg.value // subtract the msg.value if the base token is ETH
            : ERC20(baseToken).balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Royalty registry interface
 */
interface IRoyaltyRegistry is IERC165 {
    event RoyaltyOverride(address owner, address tokenAddress, address royaltyAddress);

    /**
     * Override the location of where to look up royalty information for a given token contract.
     * Allows for backwards compatibility and implementation of royalty logic for contracts that did not previously support them.
     *
     * @param tokenAddress    - The token address you wish to override
     * @param royaltyAddress  - The royalty override address
     */
    function setRoyaltyLookupAddress(address tokenAddress, address royaltyAddress) external returns (bool);

    /**
     * Returns royalty address location.  Returns the tokenAddress by default, or the override if it exists
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function getRoyaltyLookupAddress(address tokenAddress) external view returns (address);

    /**
     * Returns the token address that an overrideAddress is set for.
     * Note: will not be accurate if the override was created before this function was added.
     *
     * @param overrideAddress - The override address you are looking up the token for
     */
    function getOverrideLookupTokenAddress(address overrideAddress) external view returns (address);

    /**
     * Whether or not the message sender can override the royalty address for the given token address
     *
     * @param tokenAddress    - The token address you are looking up the royalty for
     */
    function overrideAllowed(address tokenAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
 *                                   ____
 *                                /\|    ~~\
 *                              /'  |   ,-. `\
 *                             |       | X |  |
 *                            _|________`-'   |X
 *                          /'          ~~~~~~~~~,
 *                        /'             ,_____,/_
 *                     ,/'        ___,'~~         ;
 * ~~~~~~~~|~~~~~~~|---          /  X,~~~~~~~~~~~~,
 *         |       |            |  XX'____________'
 *         |       |           /' XXX|            ;
 *         |       |        --x|  XXX,~~~~~~~~~~~~,
 *         |       |          X|     '____________'
 *         |   o   |---~~~~\__XX\             |XX
 *         |       |          XXX`\          /XXXX
 * ~~~~~~~~'~~~~~~~'               `\xXXXXx/' \XXX
 *                                  /XXXXXX\
 *                                /XXXXXXXXXX\
 *                              /XXXXXX/^\XXXXX\
 *                             ~~~~~~~~   ~~~~~~~
 */

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {SafeCast} from "openzeppelin/utils/math/SafeCast.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";
import {IRoyaltyRegistry} from "royalty-registry-solidity/IRoyaltyRegistry.sol";
import {IERC3156FlashBorrower} from "openzeppelin/interfaces/IERC3156FlashLender.sol";

import {IStolenNftOracle} from "./interfaces/IStolenNftOracle.sol";
import {Factory} from "./Factory.sol";

/// @title Private Pool
/// @author out.eth (@outdoteth)
/// @notice A private pool is a an NFT AMM controlled by a single owner with concentrated liquidity, custom fee rates,
/// stolen NFT filtering, custom NFT weightings, royalty support, and flash loans. You can create a pool and change
/// these parameters to your liking. Deposit NFTs and base tokens (or ETH) into the pool to enable trading. Earn fees on
/// each trade.
contract PrivatePool is ERC721TokenReceiver {
    using SafeTransferLib for address payable;
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Merkle proof input for a sparse merkle multi proof. It can be generated with a library like:
    /// https://github.com/OpenZeppelin/merkle-tree#treegetmultiproof
    struct MerkleMultiProof {
        bytes32[] proof;
        bool[] flags;
    }

    // forgefmt: disable-start
    event Initialize(address indexed baseToken, address indexed nft, uint128 virtualBaseTokenReserves, uint128 virtualNftReserves, uint56 changeFee, uint16 feeRate, bytes32 merkleRoot, bool useStolenNftOracle, bool payRoyalties);
    event Buy(uint256[] tokenIds, uint256[] tokenWeights, uint256 inputAmount, uint256 feeAmount, uint256 protocolFeeAmount, uint256 royaltyFeeAmount);
    event Sell(uint256[] tokenIds, uint256[] tokenWeights, uint256 outputAmount, uint256 feeAmount, uint256 protocolFeeAmount, uint256 royaltyFeeAmount);
    event Deposit(uint256[] tokenIds, uint256 baseTokenAmount);
    event Withdraw(address indexed nft, uint256[] tokenIds, address token, uint256 amount);
    event Change(uint256[] inputTokenIds, uint256[] inputTokenWeights, uint256[] outputTokenIds, uint256[] outputTokenWeights, uint256 feeAmount, uint256 protocolFeeAmount);
    event SetVirtualReserves(uint128 virtualBaseTokenReserves, uint128 virtualNftReserves);
    event SetMerkleRoot(bytes32 merkleRoot);
    event SetFeeRate(uint16 feeRate);
    event SetUseStolenNftOracle(bool useStolenNftOracle);
    event SetPayRoyalties(bool payRoyalties);
    event SetChangeFee(uint56 changeFee);
    // forgefmt: disable-end

    error AlreadyInitialized();
    error Unauthorized();
    error InvalidEthAmount();
    error InvalidMerkleProof();
    error InsufficientInputWeight();
    error FeeRateTooHigh();
    error NotAvailableForFlashLoan();
    error FlashLoanFailed();
    error InvalidRoyaltyFee();
    error InvalidTarget();
    error PrivatePoolNftNotSupported();
    error InvalidTokenWeights();
    error VirtualReservesNotSet();

    /// @notice The address of the base ERC20 token.
    address public baseToken;

    /// @notice The address of the nft.
    address public nft;

    /// @notice The change/flash fee to 4 decimals of precision. For example, 0.0025 ETH = 25. 500 USDC = 5_000_000.
    uint56 public changeFee;

    /// @notice The buy/sell fee rate (in basis points) 200 = 2%
    uint16 public feeRate;

    /// @notice Whether or not the pool has been initialized.
    bool public initialized;

    /// @notice Whether or not the pool pays royalties to the NFT creator on each trade.
    bool public payRoyalties;

    /// @notice Whether or not the pool uses the stolen NFT oracle to check if an NFT is stolen.
    bool public useStolenNftOracle;

    /// @notice The virtual base token reserves used in the xy=k invariant. Changing this will change the liquidity
    /// depth and price of the pool.
    uint128 public virtualBaseTokenReserves;

    /// @notice The virtual nft reserves used in the xy=k invariant. Changing this will change the liquidity
    /// depth and price of the pool.
    /// @dev The virtual NFT reserves that a user sets. If it's desired to set the reserves to match 16 NFTs then the
    /// virtual reserves should be set to 16e18. If weights are enabled by setting the merkle root to be non-zero then
    /// the virtual reserves should be set to the sum of the weights of the NFTs; where floor NFTs all have a weight of
    /// 1e18. A rarer NFT may have a weight of 2.3e18 if it's 2.3x more valuable than a floor.
    uint128 public virtualNftReserves;

    /// @notice The merkle root of all the token weights in the pool. If the merkle root is set to bytes32(0) then all
    /// NFTs are set to have a weight of 1e18.
    bytes32 public merkleRoot;

    /// @notice The NFT oracle to check if an NFT is stolen.
    address public immutable stolenNftOracle;

    /// @notice The factory contract that created this pool.
    address payable public immutable factory;

    /// @notice The royalty registry from manifold.xyz.
    address public immutable royaltyRegistry;

    modifier onlyOwner() virtual {
        if (msg.sender != Factory(factory).ownerOf(uint160(address(this)))) {
            revert Unauthorized();
        }
        _;
    }

    receive() external payable {}

    /// @dev This is only called when the base implementation contract is deployed. The following immutable parameters
    /// are set:
    /// - factory: The address of the factory contract
    /// - royaltyRegistry: The address of the royalty registry from manifold.xyz
    /// - stolenNftOracle: The address of the stolen NFT oracle
    /// These are all stored in immutable storage, which enables all minimal proxy contracts to read them without
    /// incurring additional deployment costs and re-initializing them at point of creation in the factory contract.
    constructor(address _factory, address _royaltyRegistry, address _stolenNftOracle) {
        factory = payable(_factory);
        royaltyRegistry = _royaltyRegistry;
        stolenNftOracle = _stolenNftOracle;
    }

    /// @notice Initializes the private pool and sets the initial parameters. Should only be called once by the factory.
    /// @param _baseToken The address of the base token
    /// @param _nft The address of the NFT
    /// @param _virtualBaseTokenReserves The virtual base token reserves
    /// @param _virtualNftReserves The virtual NFT reserves
    /// @param _feeRate The fee rate (in basis points) 200 = 2%
    /// @param _merkleRoot The merkle root
    /// @param _useStolenNftOracle Whether or not the pool uses the stolen NFT oracle to check if an NFT is stolen
    function initialize(
        address _baseToken,
        address _nft,
        uint128 _virtualBaseTokenReserves,
        uint128 _virtualNftReserves,
        uint56 _changeFee,
        uint16 _feeRate,
        bytes32 _merkleRoot,
        bool _useStolenNftOracle,
        bool _payRoyalties
    ) public {
        // prevent duplicate initialization
        if (initialized) revert AlreadyInitialized();

        // check that the fee rate is less than 50%
        if (_feeRate > 5_000) revert FeeRateTooHigh();

        // check that the nft is not a private pool NFT
        if (_nft == factory) revert PrivatePoolNftNotSupported();

        // set the state variables
        baseToken = _baseToken;
        nft = _nft;
        virtualBaseTokenReserves = _virtualBaseTokenReserves;
        virtualNftReserves = _virtualNftReserves;
        changeFee = _changeFee;
        feeRate = _feeRate;
        merkleRoot = _merkleRoot;
        useStolenNftOracle = _useStolenNftOracle;
        payRoyalties = _payRoyalties;

        // mark the pool as initialized
        initialized = true;

        // emit the event
        emit Initialize(
            _baseToken,
            _nft,
            _virtualBaseTokenReserves,
            _virtualNftReserves,
            _changeFee,
            _feeRate,
            _merkleRoot,
            _useStolenNftOracle,
            _payRoyalties
        );
    }

    /// @notice Buys NFTs from the pool, paying with base tokens from the caller. Then transfers the bought NFTs to the
    /// caller. The net cost depends on the current price, fee rate and assigned NFT weights.
    /// @dev DO NOT call this function directly unless you know what you are doing. Instead, use a wrapper contract that
    /// will check the max input amount and revert if the slippage is too high.
    /// @param tokenIds The token IDs of the NFTs to buy.
    /// @param tokenWeights The weights of the NFTs to buy.
    /// @param proof The merkle proof for the weights of each NFT to buy.
    /// @return netInputAmount The amount of base tokens spent inclusive of fees.
    /// @return feeAmount The amount of base tokens spent on fees.
    /// @return protocolFeeAmount The amount of base tokens spent on protocol fees.
    function buy(uint256[] calldata tokenIds, uint256[] calldata tokenWeights, MerkleMultiProof calldata proof)
        public
        payable
        returns (uint256 netInputAmount, uint256 feeAmount, uint256 protocolFeeAmount)
    {
        // ~~~ Checks ~~~ //

        // check that virtual reserves are set
        if (virtualBaseTokenReserves == 0 || virtualNftReserves == 0) revert VirtualReservesNotSet();

        // calculate the sum of weights of the NFTs to buy
        uint256 weightSum = sumWeightsAndValidateProof(tokenIds, tokenWeights, proof);

        // calculate the required net input amount and fee amount
        (netInputAmount, feeAmount, protocolFeeAmount) = buyQuote(weightSum);

        // check that the caller sent 0 ETH if the base token is not ETH
        if (baseToken != address(0) && msg.value > 0) revert InvalidEthAmount();

        // ~~~ Effects ~~~ //

        // update the virtual reserves
        virtualBaseTokenReserves += SafeCast.toUint128(netInputAmount - feeAmount - protocolFeeAmount);
        virtualNftReserves -= SafeCast.toUint128(weightSum);

        // ~~~ Interactions ~~~ //

        if (baseToken != address(0)) {
            // transfer the base token from the caller to the contract
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), netInputAmount);

            // if the protocol fee is set then pay the protocol fee
            if (protocolFeeAmount > 0) ERC20(baseToken).safeTransfer(factory, protocolFeeAmount);
        }

        // calculate the sale price (assume it's the same for each NFT even if weights differ)
        uint256 salePrice = (netInputAmount - feeAmount - protocolFeeAmount) / tokenIds.length;
        uint256 royaltyFeeAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // transfer the NFT to the caller
            ERC721(nft).safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            if (payRoyalties) {
                // get the royalty fee for the NFT
                (uint256 royaltyFee, address recipient) = _getRoyalty(tokenIds[i], salePrice);

                if (royaltyFee > 0 && recipient != address(0)) {
                    // add the royalty fee amount to the net input amount
                    netInputAmount += royaltyFee;

                    // transfer the royalties to the recipient
                    if (baseToken != address(0)) {
                        ERC20(baseToken).safeTransferFrom(msg.sender, recipient, royaltyFee);
                    } else {
                        recipient.safeTransferETH(royaltyFee);
                    }
                }
            }
        }

        if (baseToken == address(0)) {
            // check that the caller sent enough ETH to cover the net required input
            if (msg.value < netInputAmount) revert InvalidEthAmount();

            // if the protocol fee is set then pay the protocol fee
            if (protocolFeeAmount > 0) factory.safeTransferETH(protocolFeeAmount);

            // refund any excess ETH to the caller
            if (msg.value > netInputAmount) msg.sender.safeTransferETH(msg.value - netInputAmount);
        }

        // emit the buy event
        emit Buy(tokenIds, tokenWeights, netInputAmount, feeAmount, protocolFeeAmount, royaltyFeeAmount);
    }

    /// @notice Sells NFTs into the pool and transfers base tokens to the caller. NFTs are transferred from the caller
    /// to the pool. The net sale amount depends on the current price, fee rate and assigned NFT weights.
    /// @dev DO NOT call this function directly unless you know what you are doing. Instead, use a wrapper contract that
    /// will check the min output amount and revert if the slippage is too high.
    /// @param tokenIds The token IDs of the NFTs to sell.
    /// @param tokenWeights The weights of the NFTs to sell.
    /// @param proof The merkle proof for the weights of each NFT to sell.
    /// @param stolenNftProofs The proofs that show each NFT is not stolen.
    /// @return netOutputAmount The amount of base tokens received inclusive of fees.
    /// @return feeAmount The amount of base tokens to pay in fees.
    /// @return protocolFeeAmount The amount of base tokens to pay in protocol fees.
    function sell(
        uint256[] calldata tokenIds,
        uint256[] calldata tokenWeights,
        MerkleMultiProof calldata proof,
        IStolenNftOracle.Message[] memory stolenNftProofs // put in memory to avoid stack too deep error
    ) public returns (uint256 netOutputAmount, uint256 feeAmount, uint256 protocolFeeAmount) {
        // ~~~ Checks ~~~ //

        // check that virtual reserves are set
        if (virtualBaseTokenReserves == 0 || virtualNftReserves == 0) revert VirtualReservesNotSet();

        // calculate the sum of weights of the NFTs to sell
        uint256 weightSum = sumWeightsAndValidateProof(tokenIds, tokenWeights, proof);

        // calculate the net output amount and fee amount
        (netOutputAmount, feeAmount, protocolFeeAmount) = sellQuote(weightSum);

        //  check the nfts are not stolen
        if (useStolenNftOracle) {
            IStolenNftOracle(stolenNftOracle).validateTokensAreNotStolen(nft, tokenIds, stolenNftProofs);
        }

        // ~~~ Effects ~~~ //

        // update the virtual reserves
        virtualBaseTokenReserves -= SafeCast.toUint128(netOutputAmount + protocolFeeAmount + feeAmount);
        virtualNftReserves += SafeCast.toUint128(weightSum);

        // ~~~ Interactions ~~~ //

        uint256 royaltyFeeAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // transfer each nft from the caller
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            if (payRoyalties) {
                // calculate the sale price (assume it's the same for each NFT even if weights differ)
                uint256 salePrice = (netOutputAmount + feeAmount + protocolFeeAmount) / tokenIds.length;

                // get the royalty fee for the NFT
                (uint256 royaltyFee, address recipient) = _getRoyalty(tokenIds[i], salePrice);

                // transfer the royalty fee to the recipient if it's greater than 0
                if (royaltyFee > 0 && recipient != address(0)) {
                    // tally the royalty fee amount
                    royaltyFeeAmount += royaltyFee;

                    if (baseToken != address(0)) {
                        ERC20(baseToken).safeTransfer(recipient, royaltyFee);
                    } else {
                        recipient.safeTransferETH(royaltyFee);
                    }
                }
            }
        }

        // subtract the royalty fee amount from the net output amount
        netOutputAmount -= royaltyFeeAmount;

        if (baseToken == address(0)) {
            // transfer ETH to the caller
            msg.sender.safeTransferETH(netOutputAmount);

            // if the protocol fee is set then pay the protocol fee
            if (protocolFeeAmount > 0) factory.safeTransferETH(protocolFeeAmount);
        } else {
            // transfer base tokens to the caller
            ERC20(baseToken).transfer(msg.sender, netOutputAmount);

            // if the protocol fee is set then pay the protocol fee
            if (protocolFeeAmount > 0) ERC20(baseToken).safeTransfer(factory, protocolFeeAmount);
        }

        // emit the sell event
        emit Sell(tokenIds, tokenWeights, netOutputAmount, feeAmount, protocolFeeAmount, royaltyFeeAmount);
    }

    /// @notice Changes a set of NFTs that the caller owns for another set of NFTs in the pool. The caller must approve
    /// the pool to transfer the NFTs. The sum of the caller's NFT weights must be greater than or equal to the sum of
    /// the output pool NFTs weights. The caller must also pay a fee depending the net input weight and change fee
    /// amount.
    /// @param inputTokenIds The token IDs of the NFTs to change.
    /// @param inputTokenWeights The weights of the NFTs to change.
    /// @param inputProof The merkle proof for the weights of each NFT to change.
    /// @param stolenNftProofs The proofs that show each input NFT is not stolen.
    /// @param outputTokenIds The token IDs of the NFTs to receive.
    /// @param outputTokenWeights The weights of the NFTs to receive.
    /// @param outputProof The merkle proof for the weights of each NFT to receive.
    /// @return feeAmount The amount of base tokens to pay in fees.
    /// @return protocolFeeAmount The amount of base tokens to pay in protocol fees.
    function change(
        uint256[] memory inputTokenIds,
        uint256[] memory inputTokenWeights,
        MerkleMultiProof memory inputProof,
        IStolenNftOracle.Message[] memory stolenNftProofs,
        uint256[] memory outputTokenIds,
        uint256[] memory outputTokenWeights,
        MerkleMultiProof memory outputProof
    ) public payable returns (uint256 feeAmount, uint256 protocolFeeAmount) {
        // ~~~ Checks ~~~ //

        // check that the caller sent 0 ETH if base token is not ETH
        if (baseToken != address(0) && msg.value > 0) revert InvalidEthAmount();

        // check that NFTs are not stolen
        if (useStolenNftOracle) {
            IStolenNftOracle(stolenNftOracle).validateTokensAreNotStolen(nft, inputTokenIds, stolenNftProofs);
        }

        // fix stack too deep
        {
            // calculate the sum of weights for the input nfts
            uint256 inputWeightSum = sumWeightsAndValidateProof(inputTokenIds, inputTokenWeights, inputProof);

            // calculate the sum of weights for the output nfts
            uint256 outputWeightSum = sumWeightsAndValidateProof(outputTokenIds, outputTokenWeights, outputProof);

            // check that the input weights are greater than or equal to the output weights
            if (inputWeightSum < outputWeightSum) revert InsufficientInputWeight();

            // calculate the fee amount
            (feeAmount, protocolFeeAmount) = changeFeeQuote(inputWeightSum);
        }

        // ~~~ Interactions ~~~ //

        if (baseToken != address(0)) {
            // transfer the fee amount of base tokens from the caller
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), feeAmount);

            // if the protocol fee is non-zero then transfer the protocol fee to the factory
            if (protocolFeeAmount > 0) ERC20(baseToken).safeTransferFrom(msg.sender, factory, protocolFeeAmount);
        } else {
            // check that the caller sent enough ETH to cover the fee amount and protocol fee
            if (msg.value < feeAmount + protocolFeeAmount) revert InvalidEthAmount();

            // if the protocol fee is non-zero then transfer the protocol fee to the factory
            if (protocolFeeAmount > 0) factory.safeTransferETH(protocolFeeAmount);

            // refund any excess ETH to the caller
            if (msg.value > feeAmount + protocolFeeAmount) {
                msg.sender.safeTransferETH(msg.value - feeAmount - protocolFeeAmount);
            }
        }

        // transfer the input nfts from the caller
        for (uint256 i = 0; i < inputTokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), inputTokenIds[i]);
        }

        // transfer the output nfts to the caller
        for (uint256 i = 0; i < outputTokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(address(this), msg.sender, outputTokenIds[i]);
        }

        // emit the change event
        emit Change(inputTokenIds, inputTokenWeights, outputTokenIds, outputTokenWeights, feeAmount, protocolFeeAmount);
    }

    /// @notice Executes a transaction from the pool account to a target contract. The caller must be the owner of the
    /// pool. This allows for use cases such as claiming airdrops.
    /// @param target The address of the target contract.
    /// @param data The data to send to the target contract.
    /// @return returnData The return data of the transaction.
    function execute(address target, bytes memory data) public payable onlyOwner returns (bytes memory) {
        if (target == address(baseToken) || target == address(nft)) revert InvalidTarget();

        // call the target with the value and data
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);

        // if the call succeeded return the return data
        if (success) return returnData;

        // if we got an error bubble up the error message
        if (returnData.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        }

        revert();
    }

    /// @notice Deposits base tokens and NFTs into the pool. The caller must approve the pool to transfer their NFTs and
    /// base tokens.
    /// @dev DO NOT call this function directly unless you know what you are doing. Instead, use a wrapper contract that
    /// will check the current price is within the desired bounds.
    /// @param tokenIds The token IDs of the NFTs to deposit.
    /// @param baseTokenAmount The amount of base tokens to deposit.
    function deposit(uint256[] calldata tokenIds, uint256 baseTokenAmount) public payable {
        // ~~~ Checks ~~~ //

        // ensure the caller sent a valid amount of ETH if base token is ETH or that the caller sent 0 ETH if base token
        // is not ETH
        if ((baseToken == address(0) && msg.value != baseTokenAmount) || (msg.value > 0 && baseToken != address(0))) {
            revert InvalidEthAmount();
        }

        // ~~~ Interactions ~~~ //

        // transfer the nfts from the caller
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(nft).safeTransferFrom(msg.sender, address(this), tokenIds[i]);
        }

        if (baseToken != address(0)) {
            // transfer the base tokens from the caller
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), baseTokenAmount);
        }

        // emit the deposit event
        emit Deposit(tokenIds, baseTokenAmount);
    }

    /// @notice Withdraws NFTs and tokens from the pool. Can only be called by the owner of the pool.
    /// @param _nft The address of the NFT.
    /// @param tokenIds The token IDs of the NFTs to withdraw.
    /// @param token The address of the token to withdraw.
    /// @param tokenAmount The amount of tokens to withdraw.
    function withdraw(address _nft, uint256[] calldata tokenIds, address token, uint256 tokenAmount) public onlyOwner {
        // ~~~ Interactions ~~~ //

        // transfer the nfts to the caller
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(_nft).safeTransferFrom(address(this), msg.sender, tokenIds[i]);
        }

        if (token == address(0)) {
            // transfer the ETH to the caller
            msg.sender.safeTransferETH(tokenAmount);
        } else {
            // transfer the tokens to the caller
            ERC20(token).transfer(msg.sender, tokenAmount);
        }

        // emit the withdraw event
        emit Withdraw(_nft, tokenIds, token, tokenAmount);
    }

    /// @notice Sets the virtual base token reserves and virtual NFT reserves. Can only be called by the owner of the
    /// pool. These parameters affect the price and liquidity depth of the pool.
    /// @param newVirtualBaseTokenReserves The new virtual base token reserves.
    /// @param newVirtualNftReserves The new virtual NFT reserves.
    function setVirtualReserves(uint128 newVirtualBaseTokenReserves, uint128 newVirtualNftReserves) public onlyOwner {
        // set the virtual base token reserves and virtual nft reserves
        virtualBaseTokenReserves = newVirtualBaseTokenReserves;
        virtualNftReserves = newVirtualNftReserves;

        // emit the set virtual reserves event
        emit SetVirtualReserves(newVirtualBaseTokenReserves, newVirtualNftReserves);
    }

    /// @notice Sets the merkle root. Can only be called by the owner of the pool. The merkle root is used to validate
    /// the NFT weights.
    /// @param newMerkleRoot The new merkle root.
    function setMerkleRoot(bytes32 newMerkleRoot) public onlyOwner {
        // set the merkle root
        merkleRoot = newMerkleRoot;

        // emit the set merkle root event
        emit SetMerkleRoot(newMerkleRoot);
    }

    /// @notice Sets the fee rate. Can only be called by the owner of the pool. The fee rate is used to calculate the
    /// fee amount when swapping NFTs. The fee rate is in basis points (1/100th of a percent). For example,
    /// 10_000 == 100%, 200 == 2%, 1 == 0.01%.
    /// @param newFeeRate The new fee rate (in basis points)
    function setFeeRate(uint16 newFeeRate) public onlyOwner {
        // check that the fee rate is less than or equal to 50%
        if (newFeeRate > 5_000) revert FeeRateTooHigh();

        // set the fee rate
        feeRate = newFeeRate;

        // emit the set fee rate event
        emit SetFeeRate(newFeeRate);
    }

    /// @notice Sets the whether or not to use the stolen NFT oracle. Can only be called by the owner of the pool. The
    /// stolen NFT oracle is used to check if an NFT is stolen.
    /// @param newUseStolenNftOracle The new use stolen NFT oracle flag.
    function setUseStolenNftOracle(bool newUseStolenNftOracle) public onlyOwner {
        // set the use stolen NFT oracle flag
        useStolenNftOracle = newUseStolenNftOracle;

        // emit the set use stolen NFT oracle event
        emit SetUseStolenNftOracle(newUseStolenNftOracle);
    }

    /// @notice Sets the pay royalties flag. Can only be called by the owner of the pool. If royalties are enabled then
    /// the pool will pay royalties when buying or selling NFTs.
    /// @param newPayRoyalties The new pay royalties flag.
    function setPayRoyalties(bool newPayRoyalties) public onlyOwner {
        // set the pay royalties flag
        payRoyalties = newPayRoyalties;

        // emit the set pay royalties event
        emit SetPayRoyalties(newPayRoyalties);
    }

    /// @notice Sets the change fee. Can only be called by the owner. The change fee is used to calculate the
    /// fixed fee amount when changing or flashloaning NFTs. The fee rate is to 4 decimals of accuracy. For
    /// example, 0.0025 ETH = 25. 500 USDC = 5_000_000.
    /// @param _newChangeFee The new pay change fee.
    function setChangeFee(uint56 _newChangeFee) public onlyOwner {
        // set the pay royalties flag
        changeFee = _newChangeFee;

        // emit the set pay royalties event
        emit SetChangeFee(changeFee);
    }

    /// @notice Updates all parameter settings in one go.
    /// @param newVirtualBaseTokenReserves The new virtual base token reserves.
    /// @param newVirtualNftReserves The new virtual NFT reserves.
    /// @param newMerkleRoot The new merkle root.
    /// @param newFeeRate The new fee rate (in basis points)
    /// @param newUseStolenNftOracle The new use stolen NFT oracle flag.
    /// @param newPayRoyalties The new pay royalties flag.
    /// @param newChangeFee The new change fee.
    function setAllParameters(
        uint128 newVirtualBaseTokenReserves,
        uint128 newVirtualNftReserves,
        bytes32 newMerkleRoot,
        uint16 newFeeRate,
        bool newUseStolenNftOracle,
        bool newPayRoyalties,
        uint56 newChangeFee
    ) public {
        setVirtualReserves(newVirtualBaseTokenReserves, newVirtualNftReserves);
        setMerkleRoot(newMerkleRoot);
        setFeeRate(newFeeRate);
        setUseStolenNftOracle(newUseStolenNftOracle);
        setPayRoyalties(newPayRoyalties);
        setChangeFee(newChangeFee);
    }

    /// @notice Executes a flash loan.
    /// @param receiver The receiver of the flash loan.
    /// @param token The address of the NFT contract.
    /// @param tokenId The ID of the NFT.
    /// @param data The data to pass to the receiver.
    /// @return success Whether or not the flash loan was successful.
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 tokenId, bytes calldata data)
        external
        payable
        returns (bool)
    {
        // check that the NFT is available for a flash loan
        if (!availableForFlashLoan(token, tokenId)) revert NotAvailableForFlashLoan();

        // calculate the fee
        (uint256 flashFee, uint256 protocolFee) = flashFeeAndProtocolFee();
        uint256 fee = flashFee + protocolFee;

        // if base token is ETH then check that caller sent enough for the fee or if base token is not ETH
        // then check that the user sent 0 ETH
        if ((baseToken == address(0) && msg.value < fee) || (baseToken != address(0) && msg.value > 0)) {
            revert InvalidEthAmount();
        }

        // transfer the NFT to the borrower
        ERC721(token).safeTransferFrom(address(this), address(receiver), tokenId);

        // call the borrower
        bool success =
            receiver.onFlashLoan(msg.sender, token, tokenId, fee, data) == keccak256("ERC3156FlashBorrower.onFlashLoan");

        // check that flashloan was successful
        if (!success) revert FlashLoanFailed();

        // transfer the NFT from the borrower
        ERC721(token).safeTransferFrom(address(receiver), address(this), tokenId);

        if (baseToken != address(0)) {
            // transfer the fee from the borrower
            ERC20(baseToken).safeTransferFrom(msg.sender, address(this), flashFee);

            // transfer the protocol fee to the factory
            ERC20(baseToken).safeTransferFrom(msg.sender, factory, protocolFee);
        } else {
            // transfer the protocol fee to the factory
            factory.safeTransferETH(protocolFee);

            // refund the excess ETH to the borrower
            if (msg.value > fee) msg.sender.safeTransferETH(msg.value - fee);
        }

        return success;
    }

    /// @notice Sums the weights of each NFT and validates that the weights are correct by verifying the merkle proof.
    /// @param tokenIds The token IDs of the NFTs to sum the weights for.
    /// @param tokenWeights The weights of each NFT in the token IDs array.
    /// @param proof The merkle proof for the weights of each NFT.
    /// @return sum The sum of the weights of each NFT.
    function sumWeightsAndValidateProof(
        uint256[] memory tokenIds,
        uint256[] memory tokenWeights,
        MerkleMultiProof memory proof
    ) public view returns (uint256) {
        if (merkleRoot == bytes32(0)) {
            // if the merkle root is not set then check that the token weights array is empty
            if (tokenWeights.length > 0) revert InvalidTokenWeights();

            // if the merkle root is not set then set the weight of each nft to be 1e18
            return tokenIds.length * 1e18;
        }

        uint256 sum;
        bytes32[] memory leafs = new bytes32[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            // create the leaf for the merkle proof
            leafs[i] = keccak256(bytes.concat(keccak256(abi.encode(tokenIds[i], tokenWeights[i]))));

            // sum each token weight
            sum += tokenWeights[i];
        }

        // validate that the weights are valid against the merkle proof
        if (!MerkleProofLib.verifyMultiProof(proof.proof, merkleRoot, leafs, proof.flags)) {
            revert InvalidMerkleProof();
        }

        return sum;
    }

    /// @notice Returns the required input of buying a given amount of NFTs inclusive of the fee which is dependent on
    /// the currently set fee rate.
    /// @param outputAmount The amount of NFTs to buy multiplied by 1e18.
    /// @return netInputAmount The required input amount of base tokens inclusive of the fee.
    /// @return feeAmount The fee amount.
    /// @return protocolFeeAmount The protocol fee amount.
    function buyQuote(uint256 outputAmount)
        public
        view
        returns (uint256 netInputAmount, uint256 feeAmount, uint256 protocolFeeAmount)
    {
        // calculate the input amount based on xy=k invariant and round up by 1 wei
        uint256 inputAmount =
            FixedPointMathLib.mulDivUp(outputAmount, virtualBaseTokenReserves, (virtualNftReserves - outputAmount));

        protocolFeeAmount = inputAmount * Factory(factory).protocolFeeRate() / 10_000;
        feeAmount = inputAmount * feeRate / 10_000;
        netInputAmount = inputAmount + feeAmount + protocolFeeAmount;
    }

    /// @notice Returns the output amount of selling a given amount of NFTs inclusive of the fee which is dependent on
    /// the currently set fee rate.
    /// @param inputAmount The amount of NFTs to sell multiplied by 1e18.
    /// @return netOutputAmount The output amount of base tokens inclusive of the fee.
    /// @return feeAmount The fee amount.
    /// @return protocolFeeAmount The protocol fee amount.
    function sellQuote(uint256 inputAmount)
        public
        view
        returns (uint256 netOutputAmount, uint256 feeAmount, uint256 protocolFeeAmount)
    {
        // calculate the output amount based on xy=k invariant
        uint256 outputAmount = inputAmount * virtualBaseTokenReserves / (virtualNftReserves + inputAmount);

        protocolFeeAmount = outputAmount * Factory(factory).protocolFeeRate() / 10_000;
        feeAmount = outputAmount * feeRate / 10_000;
        netOutputAmount = outputAmount - feeAmount - protocolFeeAmount;
    }

    /// @notice Returns the fee required to change a given amount of NFTs. The fee is based on the current changeFee
    /// (which contains 4 decimals of precision) multiplied by some exponent depending on the base token decimals.
    /// @param inputAmount The amount of NFTs to change multiplied by 1e18.
    /// @return feeAmount The fee amount.
    /// @return protocolFeeAmount The protocol fee amount.
    function changeFeeQuote(uint256 inputAmount) public view returns (uint256 feeAmount, uint256 protocolFeeAmount) {
        // multiply the changeFee to get the fee per NFT (4 decimals of accuracy)
        uint256 exponent = baseToken == address(0) ? 18 - 4 : ERC20(baseToken).decimals() - 4;
        uint256 feePerNft = changeFee * 10 ** exponent;

        feeAmount = inputAmount * feePerNft / 1e18;
        protocolFeeAmount = feeAmount * Factory(factory).protocolChangeFeeRate() / 10_000;
    }

    /// @notice Returns the price of the pool to 18 decimals of accuracy.
    /// @return price The price of the pool.
    function price() public view returns (uint256) {
        // ensure that the exponent is always to 18 decimals of accuracy
        uint256 exponent = baseToken == address(0) ? 18 : (36 - ERC20(baseToken).decimals());
        return (virtualBaseTokenReserves * 10 ** exponent) / virtualNftReserves;
    }

    /// @notice Returns the fee and protocol fee required to flash swap a given NFT.
    /// @return feeAmount The fee amount.
    /// @return protocolFeeAmount The protocol fee amount.
    function flashFeeAndProtocolFee() public view returns (uint256 feeAmount, uint256 protocolFeeAmount) {
        // multiply the changeFee to get the fee per NFT (4 decimals of accuracy)
        uint256 exponent = baseToken == address(0) ? 18 - 4 : ERC20(baseToken).decimals() - 4;
        feeAmount = changeFee * 10 ** exponent;
        protocolFeeAmount = feeAmount * Factory(factory).protocolChangeFeeRate() / 10_000;
    }

    /// @notice Returns the fee required to flash swap a given NFT.
    /// @return feeAmount The fee amount.
    function flashFee(address, uint256) public view returns (uint256) {
        (uint256 feeAmount, uint256 protocolFeeAmount) = flashFeeAndProtocolFee();
        return feeAmount + protocolFeeAmount;
    }

    /// @notice Returns the token that is used to pay the flash fee.
    function flashFeeToken() public view returns (address) {
        return baseToken;
    }

    /// @notice Returns whether or not an NFT is available for a flash loan.
    /// @param token The address of the NFT contract.
    /// @param tokenId The ID of the NFT.
    /// @return available Whether or not the NFT is available for a flash loan.
    function availableForFlashLoan(address token, uint256 tokenId) public view returns (bool) {
        // return if the NFT is owned by this contract
        try ERC721(token).ownerOf(tokenId) returns (address result) {
            return result == address(this);
        } catch {
            return false;
        }
    }

    /// @notice Gets the royalty and recipient for a given NFT and sale price. Looks up the royalty info from the
    /// manifold registry.
    /// @param tokenId The token ID of the NFT.
    /// @param salePrice The sale price of the NFT.
    /// @return royaltyFee The royalty fee to pay.
    /// @return recipient The address to pay the royalty fee to.
    function _getRoyalty(uint256 tokenId, uint256 salePrice)
        internal
        view
        returns (uint256 royaltyFee, address recipient)
    {
        // get the royalty lookup address
        address lookupAddress = IRoyaltyRegistry(royaltyRegistry).getRoyaltyLookupAddress(nft);

        if (IERC2981(lookupAddress).supportsInterface(type(IERC2981).interfaceId)) {
            // get the royalty fee from the registry
            (recipient, royaltyFee) = IERC2981(lookupAddress).royaltyInfo(tokenId, salePrice);

            // revert if the royalty fee is greater than the sale price
            if (royaltyFee > salePrice) revert InvalidRoyaltyFee();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStolenNftOracle {
    // copied from https://github.com/reservoirprotocol/oracle/blob/main/contracts/ReservoirOracle.sol
    struct Message {
        bytes32 id;
        bytes payload;
        // The UNIX timestamp when the message was signed by the oracle
        uint256 timestamp;
        // ECDSA signature or EIP-2098 compact signature
        bytes signature;
    }

    /// @notice Validates that a set of token ids have not been marked as stolen by the oracle.
    /// @dev Check a signed message from the oracle to ensure that the token ids have not been marked as stolen.
    /// @param tokenAddress The address of the token contract.
    /// @param tokenIds The token ids to validate.
    /// @param proofs The proofs that the token ids have not been marked as stolen.
    function validateTokensAreNotStolen(address tokenAddress, uint256[] calldata tokenIds, Message[] calldata proofs)
        external;
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
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

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

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
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Inspired by https://github.com/ZeframLou/trustus
abstract contract ReservoirOracle {
    // --- Structs ---

    struct Message {
        bytes32 id;
        bytes payload;
        // The UNIX timestamp when the message was signed by the oracle
        uint256 timestamp;
        // ECDSA signature or EIP-2098 compact signature
        bytes signature;
    }

    // --- Errors ---

    error InvalidMessage();

    // --- Fields ---

    address public RESERVOIR_ORACLE_ADDRESS;

    // --- Constructor ---

    constructor(address reservoirOracleAddress) {
        RESERVOIR_ORACLE_ADDRESS = reservoirOracleAddress;
    }

    // --- Public methods ---

    function updateReservoirOracleAddress(address newReservoirOracleAddress)
        public
        virtual;

    // --- Internal methods ---

    function _verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) internal view virtual returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            return false;
        }

        // Ensure the message timestamp is valid
        if (
            message.timestamp > block.timestamp ||
            message.timestamp + validFor < block.timestamp
        ) {
            return false;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;
        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            return false;
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Message(bytes32 id,bytes payload,uint256 timestamp)"
                            ),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == RESERVOIR_ORACLE_ADDRESS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "solmate/tokens/ERC20.sol";

/// @title LP token
/// @author out.eth (@outdoteth)
/// @notice LP token which is minted and burned by the Pair contract to represent liquidity in the pool.
contract LpToken is Owned, ERC20 {
    constructor(string memory pairSymbol)
        Owned(msg.sender)
        ERC20(string.concat(pairSymbol, " LP token"), string.concat("LP-", pairSymbol), 18)
    {}

    /// @notice Mints new LP tokens to the given address.
    /// @param to The address to mint to.
    /// @param amount The amount to mint.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @notice Burns LP tokens from the given address.
    /// @param from The address to burn from.
    /// @param amount The amount to burn.
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";

import "./lib/SafeERC20Namer.sol";
import "./Pair.sol";

/// @title caviar.sh
/// @author out.eth (@outdoteth)
/// @notice An AMM for creating and trading fractionalized NFTs.
contract Caviar is Owned {
    using SafeERC20Namer for address;

    /// @dev pairs[nft][baseToken][merkleRoot] -> pair
    mapping(address => mapping(address => mapping(bytes32 => address))) public pairs;

    /// @dev The stolen nft filter oracle address
    address public stolenNftFilterOracle;

    event SetStolenNftFilterOracle(address indexed stolenNftFilterOracle);
    event Create(address indexed nft, address indexed baseToken, bytes32 indexed merkleRoot);
    event Destroy(address indexed nft, address indexed baseToken, bytes32 indexed merkleRoot);

    constructor(address _stolenNftFilterOracle) Owned(msg.sender) {
        stolenNftFilterOracle = _stolenNftFilterOracle;
    }

    /// @notice Sets the stolen nft filter oracle address.
    /// @param _stolenNftFilterOracle The stolen nft filter oracle address.
    function setStolenNftFilterOracle(address _stolenNftFilterOracle) public onlyOwner {
        stolenNftFilterOracle = _stolenNftFilterOracle;
        emit SetStolenNftFilterOracle(_stolenNftFilterOracle);
    }

    /// @notice Creates a new pair.
    /// @param nft The NFT contract address.
    /// @param baseToken The base token contract address.
    /// @param merkleRoot The merkle root for the valid tokenIds.
    /// @return pair The address of the new pair.
    function create(address nft, address baseToken, bytes32 merkleRoot) public returns (Pair pair) {
        // check that the pair doesn't already exist
        require(pairs[nft][baseToken][merkleRoot] == address(0), "Pair already exists");
        require(nft.code.length > 0, "Invalid NFT contract");
        require(baseToken.code.length > 0 || baseToken == address(0), "Invalid base token contract");

        // deploy the pair
        string memory baseTokenSymbol = baseToken == address(0) ? "ETH" : baseToken.tokenSymbol();
        string memory nftSymbol = nft.tokenSymbol();
        string memory nftName = nft.tokenName();
        string memory pairSymbol = string.concat(nftSymbol, ":", baseTokenSymbol);
        pair = new Pair(nft, baseToken, merkleRoot, pairSymbol, nftName, nftSymbol);

        // save the pair
        pairs[nft][baseToken][merkleRoot] = address(pair);

        emit Create(nft, baseToken, merkleRoot);
    }

    /// @notice Deletes the pair for the given NFT, base token, and merkle root.
    /// @param nft The NFT contract address.
    /// @param baseToken The base token contract address.
    /// @param merkleRoot The merkle root for the valid tokenIds.
    function destroy(address nft, address baseToken, bytes32 merkleRoot) public {
        // check that a pair can only destroy itself
        require(msg.sender == pairs[nft][baseToken][merkleRoot], "Only pair can destroy itself");

        // delete the pair
        delete pairs[nft][baseToken][merkleRoot];

        emit Destroy(nft, baseToken, merkleRoot);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "reservoir-oracle/ReservoirOracle.sol";

/// @title StolenNftFilterOracle
/// @author out.eth (@outdoteth)
/// @notice A contract to check that a set of NFTs are not stolen.
contract StolenNftFilterOracle is ReservoirOracle, Owned {
    bytes32 private constant TOKEN_TYPE_HASH = keccak256("Token(address contract,uint256 tokenId)");
    uint256 public cooldownPeriod = 0;
    uint256 public validFor = 60 minutes;

    mapping(address => bool) public isDisabled;

    constructor() Owned(msg.sender) ReservoirOracle(0xAeB1D03929bF87F69888f381e73FBf75753d75AF) {}

    /// @notice Sets the cooldown period.
    /// @param _cooldownPeriod The cooldown period.
    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyOwner {
        cooldownPeriod = _cooldownPeriod;
    }

    /// @notice Sets the valid for period.
    /// @param _validFor The valid for period.
    function setValidFor(uint256 _validFor) public onlyOwner {
        validFor = _validFor;
    }

    /// @notice Updates the reservoir oracle address.
    /// @param newReservoirOracleAddress The new reservoir oracle address.
    function updateReservoirOracleAddress(address newReservoirOracleAddress) public override onlyOwner {
        RESERVOIR_ORACLE_ADDRESS = newReservoirOracleAddress;
    }

    /// @notice Sets whether a token validation is disabled.
    /// @param tokenAddress The token address.
    /// @param _isDisabled Whether the token validation is disabled.
    function setIsDisabled(address tokenAddress, bool _isDisabled) public onlyOwner {
        isDisabled[tokenAddress] = _isDisabled;
    }

    /// @notice Checks that a set of NFTs are not stolen.
    /// @param tokenAddress The address of the NFT contract.
    /// @param tokenIds The ids of the NFTs.
    /// @param messages The messages signed by the reservoir oracle.
    function validateTokensAreNotStolen(address tokenAddress, uint256[] calldata tokenIds, Message[] calldata messages)
        public
        view
    {
        if (isDisabled[tokenAddress]) return;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            Message calldata message = messages[i];

            // check that the signer is correct and message id matches token id + token address
            bytes32 expectedMessageId = keccak256(abi.encode(TOKEN_TYPE_HASH, tokenAddress, tokenIds[i]));
            require(_verifyMessage(expectedMessageId, validFor, message), "Message has invalid signature");

            (bool isFlagged, uint256 lastTransferTime) = abi.decode(message.payload, (bool, uint256));

            // check that the NFT is not stolen
            require(!isFlagged, "NFT is flagged as suspicious");

            // check that the NFT was not transferred too recently
            require(lastTransferTime + cooldownPeriod < block.timestamp, "NFT was transferred too recently");
        }
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProofLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            MERKLE PROOF VERIFICATION OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(proof) {
                // Initialize `offset` to the offset of `proof` elements in memory.
                let offset := add(proof, 0x20)
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(offset, shl(5, mload(proof)))
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, mload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), mload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether all `leafs` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32[] memory leafs,
        bool[] memory flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leafs` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the lengths of the arrays.
            let leafsLength := mload(leafs)
            let proofLength := mload(proof)
            let flagsLength := mload(flags)

            // Advance the pointers of the arrays to point to the data.
            leafs := add(0x20, leafs)
            proof := add(0x20, proof)
            flags := add(0x20, flags)

            // If the number of flags is correct.
            for {} eq(add(leafsLength, proofLength), add(flagsLength, 1)) {} {
                // For the case where `proof.length + leafs.length == 1`.
                if iszero(flagsLength) {
                    // `isValid = (proof.length == 1 ? proof[0] : leafs[0]) == root`.
                    isValid := eq(mload(xor(leafs, mul(xor(proof, leafs), proofLength))), root)
                    break
                }

                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leafs into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                // Left shift by 5 is equivalent to multiplying by 0x20.
                leafsLength := shl(5, leafsLength)
                for { let i := 0 } iszero(eq(i, leafsLength)) { i := add(i, 0x20) } {
                    mstore(add(hashesFront, i), mload(add(leafs, i)))
                }
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, leafsLength)
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables
                // (this trick may not always save gas).
                flagsLength := add(hashesBack, shl(5, flagsLength))

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(mload(flags)) {
                        // Loads the next proof.
                        b := mload(proof)
                        proof := add(proof, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag.
                    flags := add(flags, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flagsLength)) { break }
                }
                // Checks if the last value in the queue is same as the root.
                isValid := eq(mload(sub(hashesBack, 0x20)), root)
                break
            }
        }
    }

    /// @dev Returns whether all `leafs` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProofCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leafs,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leafs` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // If the number of flags is correct.
            for {} eq(add(leafs.length, proof.length), add(flags.length, 1)) {} {
                // For the case where `proof.length + leafs.length == 1`.
                if iszero(flags.length) {
                    // `isValid = (proof.length == 1 ? proof[0] : leafs[0]) == root`.
                    // forgefmt: disable-next-item
                    isValid := eq(
                        calldataload(
                            xor(leafs.offset, mul(xor(proof.offset, leafs.offset), proof.length))
                        ),
                        root
                    )
                    break
                }

                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leafs into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                // Left shift by 5 is equivalent to multiplying by 0x20.
                calldatacopy(hashesFront, leafs.offset, shl(5, leafs.length))
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, shl(5, leafs.length))
                // This is the end of the memory for the queue.
                // We recycle `flags.length` to save on stack variables
                // (this trick may not always save gas).
                flags.length := add(hashesBack, shl(5, flags.length))

                // We don't need to make a copy of `proof.offset` or `flags.offset`,
                // as they are pass-by-value (this trick may not always save gas).

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(calldataload(flags.offset)) {
                        // Loads the next proof.
                        b := calldataload(proof.offset)
                        proof.offset := add(proof.offset, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag offset.
                    flags.offset := add(flags.offset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flags.length)) { break }
                }
                // Checks if the last value in the queue is same as the root.
                isValid := eq(mload(sub(hashesBack, 0x20)), root)
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes32 array.
    function emptyProof() internal pure returns (bytes32[] calldata proof) {
        /// @solidity memory-safe-assembly
        assembly {
            proof.length := 0
        }
    }

    /// @dev Returns an empty calldata bytes32 array.
    function emptyLeafs() internal pure returns (bytes32[] calldata leafs) {
        /// @solidity memory-safe-assembly
        assembly {
            leafs.length := 0
        }
    }

    /// @dev Returns an empty calldata bool array.
    function emptyFlags() internal pure returns (bool[] calldata flags) {
        /// @solidity memory-safe-assembly
        assembly {
            flags.length := 0
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC3156FlashLender.sol)

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
 *
 *       __________...----..____..-'``-..___
 *     ,'.                                  ```--.._
 *    :                                             ``._
 *    |                           --                    ``.
 *    |                 -0-           -.     -   -.        `.
 *    :                     __           --            .     \
 *     `._____________     (  `.   -.-      --  -   .   `     \
 *        `-----------------\   \_.--------..__..--.._ `. `.   :
 *                           `--'                     `-._ .   |
 *                                                        `.`  |
 *                                                          \` |
 *                                                           \ |
 *                                                           / \`.
 *                                                          /  _\-'
 *                                                         /_,'
 */

import {LibClone} from "solady/utils/LibClone.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {PrivatePool} from "./PrivatePool.sol";
import {PrivatePoolMetadata} from "./PrivatePoolMetadata.sol";

/// @title Caviar Private Pool Factory
/// @author out.eth (@outdoteth)
/// @notice This contract is used to create and initialize new private pools. Each time a private pool is created, a new
/// NFT representing that private pool is minted to the creator. All protocol fees also accrue to this contract and can
/// be withdrawn by the admin.
contract Factory is ERC721, Owned {
    using LibClone for address;
    using SafeTransferLib for address;

    event Create(address indexed privatePool, uint256[] tokenIds, uint256 baseTokenAmount);
    event Withdraw(address indexed token, uint256 indexed amount);
    event SetPrivatePoolMetadata(address indexed privatePoolMetadata);
    event SetPrivatePoolImplementation(address indexed privatePoolImplementation);
    event SetProtocolFeeRate(uint16 indexed protocolFeeRate);
    event SetProtocolChangeFeeRate(uint16 indexed protocolChangeFeeRate);

    error ProtocolFeeRateTooHigh();
    error ProtocolChangeFeeRateTooHigh();
    error URIQueryForNonExistentToken();

    /// @notice The address of the private pool implementation that proxies point to.
    address public privatePoolImplementation;

    /// @notice Helper contract that constructs the private pool metadata svg and json for each pool NFT.
    address public privatePoolMetadata;

    /// @notice The protocol fee that is taken on each buy/sell/change. It's in basis points: 350 = 3.5%.
    uint16 public protocolFeeRate;

    /// @notice The protocol change fee rate that is taken on each change/flash loan. It's in basis points: 200 = 2.00%.
    uint16 public protocolChangeFeeRate;

    constructor() ERC721("Caviar Private Pools", "POOL") Owned(msg.sender) {}

    receive() external payable {}

    /// @notice Creates a new private pool using the minimal proxy pattern that points to the private pool
    /// implementation. The caller must approve the factory to transfer the NFTs that will be deposited to the pool.
    /// @param _baseToken The address of the base token.
    /// @param _nft The address of the NFT.
    /// @param _virtualBaseTokenReserves The virtual base token reserves.
    /// @param _virtualNftReserves The virtual NFT reserves.
    /// @param _changeFee The change fee.
    /// @param _feeRate The fee rate.
    /// @param _merkleRoot The merkle root.
    /// @param _useStolenNftOracle Whether to use the stolen NFT oracle.
    /// @param _salt The salt that will used on deployment.
    /// @param tokenIds The token ids to deposit to the pool.
    /// @param baseTokenAmount The amount of base tokens to deposit to the pool.
    /// @return privatePool The address of the private pool.
    function create(
        address _baseToken,
        address _nft,
        uint128 _virtualBaseTokenReserves,
        uint128 _virtualNftReserves,
        uint56 _changeFee,
        uint16 _feeRate,
        bytes32 _merkleRoot,
        bool _useStolenNftOracle,
        bool _payRoyalties,
        bytes32 _salt,
        uint256[] memory tokenIds, // put in memory to avoid stack too deep error
        uint256 baseTokenAmount
    ) public payable returns (PrivatePool privatePool) {
        // check that the msg.value is equal to the base token amount if the base token is ETH or the msg.value is equal
        // to zero if the base token is not ETH
        if ((_baseToken == address(0) && msg.value != baseTokenAmount) || (_baseToken != address(0) && msg.value > 0)) {
            revert PrivatePool.InvalidEthAmount();
        }

        // deploy a minimal proxy clone of the private pool implementation
        bytes32 salt = keccak256(abi.encode(msg.sender, _salt));
        privatePool = PrivatePool(payable(privatePoolImplementation.cloneDeterministic(salt)));

        // mint the nft to the caller
        _safeMint(msg.sender, uint256(uint160(address(privatePool))));

        // initialize the pool
        privatePool.initialize(
            _baseToken,
            _nft,
            _virtualBaseTokenReserves,
            _virtualNftReserves,
            _changeFee,
            _feeRate,
            _merkleRoot,
            _useStolenNftOracle,
            _payRoyalties
        );

        if (_baseToken == address(0)) {
            // transfer eth into the pool if base token is ETH
            address(privatePool).safeTransferETH(baseTokenAmount);
        } else {
            // deposit the base tokens from the caller into the pool
            SafeTransferLib.safeTransferFrom(ERC20(_baseToken), msg.sender, address(privatePool), baseTokenAmount);
        }

        // deposit the nfts from the caller into the pool
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ERC721(_nft).safeTransferFrom(msg.sender, address(privatePool), tokenIds[i]);
        }

        // emit create event
        emit Create(address(privatePool), tokenIds, baseTokenAmount);
    }

    /// @notice Sets private pool metadata contract.
    /// @param _privatePoolMetadata The private pool metadata contract.
    function setPrivatePoolMetadata(address _privatePoolMetadata) public onlyOwner {
        privatePoolMetadata = _privatePoolMetadata;
        emit SetPrivatePoolMetadata(_privatePoolMetadata);
    }

    /// @notice Sets the private pool implementation contract that newly deployed proxies point to.
    /// @param _privatePoolImplementation The private pool implementation contract.
    function setPrivatePoolImplementation(address _privatePoolImplementation) public onlyOwner {
        privatePoolImplementation = _privatePoolImplementation;
        emit SetPrivatePoolImplementation(_privatePoolImplementation);
    }

    /// @notice Sets the protocol fee that is taken on each buy/sell/change. It's in basis points: 350 = 3.5%.
    /// @param _protocolFeeRate The protocol fee.
    function setProtocolFeeRate(uint16 _protocolFeeRate) public onlyOwner {
        // check that the protocol fee rate is not higher than 5%
        if (_protocolFeeRate > 500) revert ProtocolFeeRateTooHigh();

        protocolFeeRate = _protocolFeeRate;
        emit SetProtocolFeeRate(_protocolFeeRate);
    }

    /// @notice Sets the protocol fee that is taken on change or flash loan. It's in basis points: 350 = 3.5%.
    /// @param _protocolChangeFeeRate The protocol change fee rate.
    function setProtocolChangeFeeRate(uint16 _protocolChangeFeeRate) public onlyOwner {
        // check that the protocol change fee rate is not higher than 100%
        if (_protocolChangeFeeRate > 10_000) revert ProtocolChangeFeeRateTooHigh();

        protocolChangeFeeRate = _protocolChangeFeeRate;
        emit SetProtocolChangeFeeRate(_protocolChangeFeeRate);
    }

    /// @notice Withdraws the earned protocol fees.
    /// @param token The token to withdraw.
    /// @param amount The amount to withdraw.
    function withdraw(address token, uint256 amount) public onlyOwner {
        if (token == address(0)) {
            msg.sender.safeTransferETH(amount);
        } else {
            ERC20(token).transfer(msg.sender, amount);
        }

        emit Withdraw(token, amount);
    }

    /// @notice Returns the token URI for a given token id.
    /// @param id The token id.
    /// @return uri The token URI.
    function tokenURI(uint256 id) public view override returns (string memory) {
        // check that the token exists
        if (_ownerOf[id] == address(0)) revert URIQueryForNonExistentToken();

        return PrivatePoolMetadata(privatePoolMetadata).tokenURI(id);
    }

    /// @notice Predicts the deployment address of a new private pool.
    /// @param salt The salt that will used on deployment.
    /// @return predictedAddress The predicted deployment address of the private pool.
    function predictPoolDeploymentAddress(bytes32 salt) public view returns (address predictedAddress) {
        predictedAddress = privatePoolImplementation.predictDeterministicAddress(salt, address(this));
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

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin/utils/Strings.sol";

// modified from https://github.com/Uniswap/solidity-lib/blob/master/contracts/libraries/SafeERC20Namer.sol
// produces token descriptors from inconsistent or absent ERC20 symbol implementations that can return string or bytes32
// this library will always produce a string symbol to represent the token
library SafeERC20Namer {
    function bytes32ToString(bytes32 x) private pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = x[j];
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }

        return string(bytesStringTrimmed);
    }

    // uses a heuristic to produce a token name from the address
    // the heuristic returns the full hex of the address string
    function addressToName(address token) private pure returns (string memory) {
        return Strings.toHexString(uint160(token));
    }

    // uses a heuristic to produce a token symbol from the address
    // the heuristic returns the first 4 hex of the address string
    function addressToSymbol(address token) private pure returns (string memory) {
        return Strings.toHexString(uint160(token) >> (160 - 4 * 4));
    }

    // calls an external view token contract method that returns a symbol or name, and parses the output into a string
    function callAndParseStringReturn(address token, bytes4 selector) private view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(selector));
        // if not implemented, or returns empty data, return empty string
        if (!success || data.length == 0) {
            return "";
        }
        // bytes32 data always has length 32
        if (data.length == 32) {
            bytes32 decoded = abi.decode(data, (bytes32));
            return bytes32ToString(decoded);
        } else if (data.length > 64) {
            return abi.decode(data, (string));
        }
        return "";
    }

    // attempts to extract the token symbol. if it does not implement symbol, returns a symbol derived from the address
    function tokenSymbol(address token) internal view returns (string memory) {
        // 0x95d89b41 = bytes4(keccak256("symbol()"))
        string memory symbol = callAndParseStringReturn(token, 0x95d89b41);
        if (bytes(symbol).length == 0) {
            // fallback to 6 uppercase hex of address
            return addressToSymbol(token);
        }
        return symbol;
    }

    // attempts to extract the token name. if it does not implement name, returns a name derived from the address
    function tokenName(address token) internal view returns (string memory) {
        // 0x06fdde03 = bytes4(keccak256("name()"))
        string memory name = callAndParseStringReturn(token, 0x06fdde03);
        if (bytes(name).length == 0) {
            // fallback to full hex of address
            return addressToName(token);
        }

        return name;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC3156FlashBorrower.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "IERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here implements a `receive()` method that emits the
/// `ReceiveETH(uint256)` event. This skips the `DELEGATECALL` when there is no calldata,
/// enabling us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability. The minimal proxy implementation does not offer this feature.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// @dev The salt must start with either the zero address or the caller.
    error SaltDoesNotStartWithCaller();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a clone of `implementation`.
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 3d         | RETURNDATASIZE    | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (44 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | 0                      |                       |
             * 3d      | RETURNDATASIZE | 0 0                    |                       |
             * 3d      | RETURNDATASIZE | 0 0 0                  |                       |
             * 3d      | RETURNDATASIZE | 0 0 0 0                |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            |                       |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          |                       |
             * 3d      | RETURNDATASIZE | 0 0 cds 0 0 0 0        |                       |
             * 37      | CALLDATACOPY   | 0 0 0 0                | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success 0 0        | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | rds rds success 0 0    | [0..cds): calldata    |
             * 93      | SWAP4          | 0 rds success 0 rds    | [0..cds): calldata    |
             * 80      | DUP1           | 0 0 rds success 0 rds  | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success 0 rds          | [0..rds): returndata  |
             *                                                                           |
             * 60 0x2a | PUSH1 0x2a     | 0x2a success 0 rds     | [0..rds): returndata  |
             * 57      | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */

            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create(0, 0x0c, 0x35)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create2(0, 0x0c, 0x35, salt)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            hash := keccak256(0x0c, 0x35)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x21, 0)
        }
    }

    /// @dev Returns the address of the deterministic clone of `implementation`,
    /// with `salt` by `deployer`.
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           CLONES WITH IMMUTABLE ARGS OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a minimal proxy with `implementation`,
    /// using immutable arguments encoded in `data`.
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 108`
            // The `runSize` is `creationSize - 10`.

            /**
             * ---------------------------------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                                                |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                                                |
             * ---------------------------------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                                                       |
             * 3d         | RETURNDATASIZE    | 0 r       |                                                       |
             * 81         | DUP2              | r 0 r     |                                                       |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                                                       |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                                                       |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code                            |
             * f3         | RETURN            |           | [0..runSize): runtime code                            |
             * ---------------------------------------------------------------------------------------------------|
             * RUNTIME (98 bytes + extraLength)                                                                   |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                    | Memory                                      |
             * ---------------------------------------------------------------------------------------------------|
             *                                                                                                    |
             * ::: if no calldata, emit event & return w/o `DELEGATECALL` ::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 60 0x2c  | PUSH1 0x2c     | 0x2c cds                 |                                             |
             * 57       | JUMPI          |                          |                                             |
             * 34       | CALLVALUE      | cv                       |                                             |
             * 3d       | RETURNDATASIZE | 0 cv                     |                                             |
             * 52       | MSTORE         |                          | [0..0x20): callvalue                        |
             * 7f sig   | PUSH32 0x9e..  | sig                      | [0..0x20): callvalue                        |
             * 59       | MSIZE          | 0x20 sig                 | [0..0x20): callvalue                        |
             * 3d       | RETURNDATASIZE | 0 0x20 sig               | [0..0x20): callvalue                        |
             * a1       | LOG1           |                          | [0..0x20): callvalue                        |
             * 00       | STOP           |                          | [0..0x20): callvalue                        |
             * 5b       | JUMPDEST       |                          |                                             |
             *                                                                                                    |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 3d       | RETURNDATASIZE | 0 cds                    |                                             |
             * 3d       | RETURNDATASIZE | 0 0 cds                  |                                             |
             * 37       | CALLDATACOPY   |                          | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                        | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0                      | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0                    | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0 0                  | [0..cds): calldata                          |
             * 61 extra | PUSH2 extra    | e 0 0 0 0                | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: copy extra data to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 80       | DUP1           | e e 0 0 0 0              | [0..cds): calldata                          |
             * 60 0x62  | PUSH1 0x62     | 0x62 e e 0 0 0 0         | [0..cds): calldata                          |
             * 36       | CALLDATASIZE   | cds 0x62 e e 0 0 0 0     | [0..cds): calldata                          |
             * 39       | CODECOPY       | e 0 0 0 0                | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 01       | ADD            | cds+e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | 0 cds+e 0 0 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 73 addr  | PUSH20 addr    | addr 0 cds+e 0 0 0 0     | [0..cds): calldata, [cds..cds+e): extraData |
             * 5a       | GAS            | gas addr 0 cds+e 0 0 0 0 | [0..cds): calldata, [cds..cds+e): extraData |
             * f4       | DELEGATECALL   | success 0 0              | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | rds rds success 0 0      | [0..cds): calldata, [cds..cds+e): extraData |
             * 93       | SWAP4          | 0 rds success 0 rds      | [0..cds): calldata, [cds..cds+e): extraData |
             * 80       | DUP1           | 0 0 rds success 0 rds    | [0..cds): calldata, [cds..cds+e): extraData |
             * 3e       | RETURNDATACOPY | success 0 rds            | [0..rds): returndata                        |
             *                                                                                                    |
             * 60 0x60  | PUSH1 0x60     | 0x60 success 0 rds       | [0..rds): returndata                        |
             * 57       | JUMPI          | 0 rds                    | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                          | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                    | [0..rds): returndata                        |
             * f3       | RETURN         |                          | [0..rds): returndata                        |
             * ---------------------------------------------------------------------------------------------------+
             */
            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create(0, sub(data, 0x4c), add(extraLength, 0x6c))

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Deploys a deterministic clone of `implementation`,
    /// using immutable arguments encoded in `data`, with `salt`.
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(0, sub(data, 0x4c), add(extraLength, 0x6c), salt)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation, bytes memory data)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e606057fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Compute and store the bytecode hash.
            hash := keccak256(sub(data, 0x4c), add(extraLength, 0x6c))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `deployer`.
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /// @dev Reverts if `salt` does not start with either the zero address or the caller.
    function checkStartsWithCaller(bytes32 salt) internal view {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or the caller.
            if iszero(or(iszero(shr(96, salt)), eq(caller(), shr(96, salt)))) {
                // Store the function selector of `SaltDoesNotStartWithCaller()`.
                mstore(0x00, 0x2f634836)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Strings} from "openzeppelin/utils/Strings.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import {PrivatePool} from "./PrivatePool.sol";

/// @title Private Pool Metadata
/// @author out.eth (@outdoteth)
/// @notice This contract is used to generate NFT metadata for private pools.
contract PrivatePoolMetadata {
    /// @notice Returns the tokenURI for a pool with it's metadata.
    /// @param tokenId The private pool's token ID.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        // forgefmt: disable-next-item
        bytes memory metadata = abi.encodePacked(
            "{",
                '"name": "Private Pool ',Strings.toHexString(tokenId),'",',
                '"description": "Caviar private pool AMM position.",',
                '"image": ','"data:image/svg+xml;base64,', Base64.encode(svg(tokenId)),'",',
                '"attributes": [',
                    attributes(tokenId),
                "]",
            "}"
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    /// @notice Returns the attributes for a pool encoded as json.
    /// @param tokenId The private pool's token ID.
    function attributes(uint256 tokenId) public view returns (string memory) {
        PrivatePool privatePool = PrivatePool(payable(address(uint160(tokenId))));

        // forgefmt: disable-next-item
        bytes memory _attributes = abi.encodePacked(
            _trait("Pool address", Strings.toHexString(address(privatePool))), ',',
            _trait("Base token", Strings.toHexString(privatePool.baseToken())), ',',
            _trait("NFT", Strings.toHexString(privatePool.nft())), ',',
            _trait("Virtual base token reserves",Strings.toString(privatePool.virtualBaseTokenReserves())), ',',
            _trait("Virtual NFT reserves", Strings.toString(privatePool.virtualNftReserves())), ',',
            _trait("Fee rate (bps): ", Strings.toString(privatePool.feeRate())), ',',
            _trait("NFT balance", Strings.toString(ERC721(privatePool.nft()).balanceOf(address(privatePool)))), ',',
            _trait("Base token balance",  Strings.toString(privatePool.baseToken() == address(0) ? address(privatePool).balance : ERC20(privatePool.baseToken()).balanceOf(address(privatePool))))
        );

        return string(_attributes);
    }

    /// @notice Returns an svg image for a pool.
    /// @param tokenId The private pool's token ID.
    function svg(uint256 tokenId) public view returns (bytes memory) {
        PrivatePool privatePool = PrivatePool(payable(address(uint160(tokenId))));

        // break up svg building into multiple scopes to avoid stack too deep errors
        bytes memory _svg;
        {
            // forgefmt: disable-next-item
            _svg = abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400" style="width:100%;background:black;fill:white;font-family:serif;">',
                    '<text x="24px" y="24px" font-size="12">',
                        "Caviar AMM private pool position",
                    "</text>",
                    '<text x="24px" y="48px" font-size="12">',
                        "Private pool: ", Strings.toHexString(address(privatePool)),
                    "</text>",
                    '<text x="24px" y="72px" font-size="12">',
                        "Base token: ", Strings.toHexString(privatePool.baseToken()),
                    "</text>",
                    '<text x="24px" y="96px" font-size="12">',
                        "NFT: ", Strings.toHexString(privatePool.nft()),
                    "</text>"
            );
        }

        {
            // forgefmt: disable-next-item
            _svg = abi.encodePacked(
                _svg,
                '<text x="24px" y="120px" font-size="12">',
                    "Virtual base token reserves: ", Strings.toString(privatePool.virtualBaseTokenReserves()),
                "</text>",
                '<text x="24px" y="144px" font-size="12">',
                    "Virtual NFT reserves: ", Strings.toString(privatePool.virtualNftReserves()),
                "</text>",
                '<text x="24px" y="168px" font-size="12">',
                    "Fee rate (bps): ", Strings.toString(privatePool.feeRate()),
                "</text>"
            );
        }

        {
            // forgefmt: disable-next-item
            _svg = abi.encodePacked(
                _svg, 
                    '<text x="24px" y="192px" font-size="12">',
                        "NFT balance: ", Strings.toString(ERC721(privatePool.nft()).balanceOf(address(privatePool))),
                    "</text>",
                    '<text x="24px" y="216px" font-size="12">',
                        "Base token balance: ", Strings.toString(privatePool.baseToken() == address(0) ? address(privatePool).balance : ERC20(privatePool.baseToken()).balanceOf(address(privatePool))),
                    "</text>",
                "</svg>"
            );
        }

        return _svg;
    }

    function _trait(string memory traitType, string memory value) internal pure returns (string memory) {
        // forgefmt: disable-next-item
        return string(
            abi.encodePacked(
                '{ "trait_type": "', traitType, '",', '"value": "', value, '" }'
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}