// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "./KillaCubs/KillaCubsERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract KillaCubsStaker is KillaCubsERC721 {
    event BitsAddedFull(uint256[] tokens, uint16[] bits);
    event BitUsed(uint256 token, uint16 bit);
    event FastForwardedFull(uint256[] tokens, uint256 indexed numberOfDays);
    event Rushed(address owner, uint256[] tokens);
    event GearExtraction(address owner, uint256[] tokens, uint256[] weapons);

    constructor(
        address superOwner
    )
        KillaCubsERC721(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            address(0),
            superOwner
        )
    {}

    function stake(uint256[] calldata tokenIds) public {
        if (tokenIds.length == 0) return;

        Token memory token;
        bool skip;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.owner != msg.sender) revert NotAllowed();

                if (token.stakeTimestamp > 0) revert NotAllowed();

                tokens[tokenId] = token;
                tokens[tokenId].stakeTimestamp = uint32(block.timestamp);
            }

            emit Transfer(msg.sender, address(this), tokenId);

            skip = _lookAhead(tokenIds, i, token, true);
        }

        wallets[msg.sender].stakes += uint16(tokenIds.length);
        wallets[msg.sender].balance -= uint16(tokenIds.length);
        counters.stakes += uint16(tokenIds.length);
        incubator.add(msg.sender, tokenIds);
    }

    function unstake(uint256[] calldata tokenIds, bool finalized) public {
        if (tokenIds.length == 0) return;

        Token memory token;
        bool skip;
        bool setLaterGeneration;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (tokens[tokenId].bit > 0) {
                bitsContract.transferFrom(
                    address(this),
                    msg.sender,
                    tokens[tokenId].bit
                );
                if (finalized) {
                    bitsUsed[tokens[tokenId].bit] = true;
                    emit BitUsed(tokenId, tokens[tokenId].bit);
                } else {
                    emit BitRemoved(tokenId, tokens[tokenId].bit);
                }
                tokens[tokenId].bit = 0;
            }

            if (!skip) {
                token = resolveToken(tokenId);
                setLaterGeneration = false;

                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

                tokens[tokenId] = token;
                tokens[tokenId].stakeTimestamp = 0;

                uint256 max = token.generation == 0
                    ? initialIncubationLength
                    : remixIncubationLength;

                if (phase >= max) {
                    if (!finalized) revert NotAllowed();
                    tokens[tokenId].incubationPhase = 0;
                    if (activeGeneration > 255) {
                        tokens[tokenId].generation = 255;
                        setLaterGeneration = true;
                    } else {
                        tokens[tokenId].generation = uint8(activeGeneration);
                    }
                } else {
                    if (finalized) revert NotAllowed();
                    tokens[tokenId].incubationPhase = uint8(phase);
                }
            }

            if (setLaterGeneration) {
                laterGenerations[tokenId] = activeGeneration;
            }

            emit Transfer(address(this), msg.sender, tokenId);

            skip = _lookAhead(tokenIds, i, token, true);
        }

        wallets[msg.sender].stakes -= uint16(tokenIds.length);
        wallets[msg.sender].balance += uint16(tokenIds.length);
        counters.stakes -= uint16(tokenIds.length);
        incubator.remove(msg.sender, tokenIds);
    }

    function addBits(
        uint256[] calldata tokenIds,
        uint16[] calldata bits
    ) public {
        if (tokenIds.length == 0) return;

        Token memory token;
        bool skip;
        bool modified;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (tokens[tokenId].bit > 0) revert NotAllowed();
            if (bitsUsed[bits[i]]) revert NotAllowed();
            tokens[tokenId].bit = bits[i];
            bitsContract.transferFrom(msg.sender, address(this), bits[i]);

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.generation > 0) revert NotAllowed();
                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

                if (phase >= initialIncubationLength) revert NotAllowed();
                if (phase > 0) {
                    tokens[tokenId] = token;
                    tokens[tokenId].stakeTimestamp = uint32(block.timestamp);
                    tokens[tokenId].incubationPhase = 0;
                    modified = true;
                } else {
                    modified = false;
                }
            }

            skip = _lookAhead(tokenIds, i, token, modified);
        }

        emit BitsAddedFull(tokenIds, bits);
    }

    function removeBits(uint256[] calldata tokenIds) public {
        uint16 n = uint16(tokenIds.length);
        for (uint256 i = 0; i < n; i++) {
            uint256 tokenId = tokenIds[i];
            Token memory token = resolveToken(tokenId);
            if (token.owner != msg.sender) revert NotAllowed();
            if (token.generation > 0) revert NotAllowed();

            uint256 phase = calculateIncubationPhase(
                token.incubationPhase,
                token.stakeTimestamp,
                token.generation
            );

            if (phase >= initialIncubationLength) {
                revert NotAllowed();
            } else {
                emit BitRemoved(tokenId, token.bit);
            }

            bitsContract.transferFrom(address(this), msg.sender, token.bit);
            tokens[tokenId].bit = 0;
        }
    }

    function extractGear(uint256[] calldata cubs) public {
        if (cubs.length == 0) revert NotAllowed();

        uint256[] memory weapons = new uint256[](cubs.length);

        bool[19] memory flags;

        for (uint256 i = 0; i < cubs.length; i++) {
            uint256 id = cubs[i];
            Token memory token = resolveToken(id);

            if (token.owner != msg.sender) revert NotAllowed();
            if (token.bit == 0) revert NotAllowed();

            uint256 phase = calculateIncubationPhase(
                token.incubationPhase,
                token.stakeTimestamp,
                token.generation
            );

            if (phase != 8) revert NotAllowed();

            uint256 weapon = bitsContract.tokenUpgrade(token.bit);
            bitsContract.detachUpgrade(token.bit);
            weapons[i] = weapon;
            flags[weapon - 175] = true;
        }

        for (uint256 i = 0; i < 19; i++) {
            if (!flags[i]) continue;
            uint256 id = i + 175;
            IERC1155 gear = IERC1155(address(gearContract));
            uint256 amount = gear.balanceOf(address(this), id);
            if (amount == 0) continue;
            gear.safeTransferFrom(
                address(this),
                0x000000000000000000000000000000000000dEaD,
                id,
                amount,
                ""
            );
        }

        emit GearExtraction(msg.sender, cubs, weapons);
    }

    function rush(uint256[] calldata tokenIds) external {
        if (tokenIds.length == 0) return;

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 1;
        amounts[0] = tokenIds.length;

        IKILLAGEAR traits = IKILLAGEAR(externalStorage[0]);
        traits.detokenize(msg.sender, ids, amounts);

        Token memory token;
        bool skip;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.owner != msg.sender) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();
                if (token.generation == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

                if (phase >= remixIncubationLength) revert NotAllowed();

                tokens[tokenId] = token;
                tokens[tokenId].incubationPhase = uint8(remixIncubationLength);
            }

            skip = _lookAhead(tokenIds, i, token, true);
        }
        emit Rushed(msg.sender, tokenIds);
    }

    function fastForward(
        address owner,
        uint256[] calldata tokenIds,
        uint256 numberOfDays
    ) public {
        if (tokenIds.length == 0) return;
        if (numberOfDays == 0) return;

        Token memory token;
        bool skip;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            if (!skip) {
                token = resolveToken(tokenId);

                if (token.owner != owner) revert NotAllowed();
                if (token.stakeTimestamp == 0) revert NotAllowed();

                uint256 phase = calculateIncubationPhase(
                    token.incubationPhase,
                    token.stakeTimestamp,
                    token.generation
                );

                uint256 max = token.generation == 0
                    ? initialIncubationLength
                    : remixIncubationLength;

                if (phase >= max) revert NotAllowed();

                tokens[tokenId] = token;
                tokens[tokenId].stakeTimestamp -= uint32(
                    numberOfDays * 24 * 3600
                );
            }

            skip = _lookAhead(tokenIds, i, token, true);
        }
        emit FastForwardedFull(tokenIds, numberOfDays);
    }

    function _lookAhead(
        uint256[] calldata tokenIds,
        uint256 index,
        Token memory current,
        bool modified
    ) public returns (bool sequential) {
        uint256 id = tokenIds[index];
        uint256 nextId;

        if (current.linkedNext != 0) {
            nextId = current.linkedNext;
        } else if (id > 3333 && id < 3333 + counters.batched) {
            nextId = id + 1;
        } else {
            return false;
        }

        if (tokens[nextId].owner != address(0)) return false;

        if (index + 1 < tokenIds.length && tokenIds[index + 1] == nextId)
            return true;

        if (modified) {
            Token memory temp = tokens[nextId];
            tokens[nextId] = current;
            tokens[nextId].bit = temp.bit;
            tokens[nextId].linkedNext = temp.linkedNext;
            tokens[nextId].linkedPrev = temp.linkedPrev;
        }

        return false;
    }

    function configureStakingWindows(
        uint256 initialLength,
        uint256 remixLength
    ) public onlyOwner {
        initialIncubationLength = initialLength;
        remixIncubationLength = remixLength;
    }

    function setIncubator(address addr) public onlyOwner {
        incubator = IIncubator(addr);
    }

    function startNexGeneration() public onlyOwner {
        activeGeneration++;
    }

    function finalizeGeneration(
        uint256 gen,
        string calldata uri
    ) public onlyOwner {
        finalizedGeneration = gen;
        baseURIFinalized = uri;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./KillaCubsStorage.sol";

abstract contract KillaCubsERC721 is KillaCubsStorage {
    constructor(
        address bitsAddress,
        address gearAddress,
        address bearsAddress,
        address passesAddress,
        address kiltonAddress,
        address labsAddress,
        address superOwner
    )
        KillaCubsStorage(
            bitsAddress,
            gearAddress,
            bearsAddress,
            passesAddress,
            kiltonAddress,
            labsAddress,
            superOwner
        )
    {
        name = "KillaCubs";
        symbol = "KillaCubs";
        _setDefaultRoyalty(msg.sender, 500);
    }

    function _mint(address to, uint256 n, bool staked) internal {
        uint256 tokenId = 3334 + counters.batched;
        uint256 end = tokenId + n - 1;
        if (end > 8888) revert NotAllowed();

        Token storage token = tokens[tokenId];
        token.owner = to;

        counters.batched += uint16(n);
        wallets[to].batchedMints += uint16(n);

        if (staked) {
            incubator.add(to, tokenId, n);
            token.stakeTimestamp = uint32(block.timestamp);
            counters.stakes += uint16(n);
            wallets[to].stakes += uint16(n);

            while (tokenId <= end) {
                emit Transfer(address(0), to, tokenId);
                emit Transfer(to, address(this), tokenId);
                tokenId++;
            }
        } else {
            wallets[to].balance += uint16(n);
            while (tokenId <= end) {
                emit Transfer(address(0), to, tokenId);
                tokenId++;
            }
        }
    }

    function _mint(
        address to,
        uint256[] calldata tokenIds,
        bool staked
    ) internal {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];

            Token storage token = tokens[id];

            if (id == 0) revert NotAllowed();
            if (token.owner != address(0)) revert NotAllowed();
            if (token.linkedPrev != 0) revert NotAllowed();

            token.owner = to;
            emit Transfer(address(0), to, id);

            if (staked) {
                emit Transfer(to, address(this), id);
                token.stakeTimestamp = uint32(block.timestamp);
            }

            if (i == 0) {
                token.owner = to;
            } else {
                token.linkedPrev = uint16(tokenIds[i - 1]);
                tokens[tokenIds[i - 1]].linkedNext = uint16(id);
            }
        }

        counters.linked += uint16(tokenIds.length);
        if (staked) {
            counters.stakes += uint16(tokenIds.length);
            wallets[to].stakes += uint16(tokenIds.length);
            incubator.add(to, tokenIds);
        } else {
            wallets[to].balance += uint16(tokenIds.length);
        }
        wallets[to].linkedMints += uint16(tokenIds.length);
    }

    function totalSupply() public view virtual returns (uint256) {
        return counters.linked + counters.batched;
    }

    function balanceOf(
        address owner
    ) external view virtual returns (uint256 balance) {
        if (owner == address(this)) return counters.stakes;
        return wallets[owner].balance;
    }

    function ownerOf(uint256 id) public view virtual returns (address) {
        Token memory token = resolveToken(id);
        if (token.stakeTimestamp != 0) return address(this);
        return token.owner;
    }

    function rightfulOwnerOf(
        uint256 tokenId
    ) public view virtual returns (address) {
        return resolveToken(tokenId).owner;
    }

    function resolveToken(uint256 id) public view returns (Token memory) {
        Token memory token = tokens[id];
        if (token.owner == address(0)) {
            Token memory temp = token;
            if (token.linkedPrev != 0) {
                do token = tokens[token.linkedPrev]; while (
                    token.owner == address(0)
                );
            } else if (id > 3333 && id <= 3333 + counters.batched) {
                do token = tokens[--id]; while (token.owner == address(0));
            } else {
                revert NonExistentToken();
            }

            token.bit = temp.bit;
            token.linkedNext = temp.linkedNext;
            token.linkedPrev = temp.linkedPrev;
        }
        return token;
    }

    function resolveTokens(
        uint256[] calldata ids
    ) public view returns (Token[] memory) {
        Token[] memory ret = new Token[](ids.length);
        bool skip = false;
        Token memory token;
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];

            if (skip) skip = false;
            else token = resolveToken(id);

            ret[i] = token;

            uint256 nextId;
            if (token.linkedNext != 0) {
                nextId = token.linkedNext;
            } else if (id > 3333 && id < 3333 + counters.batched) {
                nextId = id + 1;
            } else {
                continue;
            }

            if (tokens[nextId].owner != address(0)) continue;
            if (i + 1 < ids.length && ids[i + 1] == nextId) {
                skip = true;
                token.bit = tokens[nextId].bit;
                token.linkedNext = tokens[nextId].linkedNext;
                token.linkedPrev = tokens[nextId].linkedPrev;
                continue;
            }
        }
        return ret;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);
        if (to.code.length != 0)
            if (!_checkOnERC721Received(from, to, id, data))
                revert TransferToNonERC721ReceiverImplementer();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);
        if (to.code.length != 0)
            if (!_checkOnERC721Received(from, to, id, ""))
                revert TransferToNonERC721ReceiverImplementer();
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual onlyAllowedOperator(from) {
        if (to == from) revert NotAllowed();
        if (to == address(0)) revert NotAllowed();

        Token memory token = resolveToken(id);

        if (token.stakeTimestamp > 0 || token.owner != from)
            revert NotAllowed();

        if (msg.sender != token.owner) {
            if (
                !operatorApprovals[token.owner][msg.sender] &&
                tokenApprovals[id] != msg.sender
            ) revert NotAllowed();
        }

        if (tokenApprovals[id] != address(0)) {
            delete tokenApprovals[id];
            emit Approval(from, address(0), id);
        }

        emit Transfer(token.owner, to, id);
        _bakeNextToken(token, id);

        token.owner = to;

        wallets[from].balance--;
        wallets[to].balance++;
        tokens[id] = token;
    }

    function _bakeNextToken(Token memory current, uint256 id) internal {
        uint256 nextId;
        if (current.linkedNext != 0) {
            nextId = current.linkedNext;
        } else if (id > 3333) {
            nextId = id + 1;
            if (nextId > 3333 + counters.batched) return;
        } else {
            return;
        }

        Token memory temp = tokens[nextId];
        if (temp.owner != address(0)) return;

        tokens[nextId] = current;

        tokens[nextId].linkedNext = temp.linkedNext;
        tokens[nextId].linkedPrev = temp.linkedPrev;
        tokens[nextId].bit = temp.bit;
    }

    function approve(
        address to,
        uint256 id
    ) public virtual onlyAllowedOperatorApproval(to) {
        address owner = ownerOf(id);
        if (msg.sender != owner) {
            if (!isApprovedForAll(owner, msg.sender)) {
                revert NotAllowed();
            }
        }

        tokenApprovals[id] = to;
        emit Approval(msg.sender, to, id);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual onlyAllowedOperatorApproval(operator) {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(
        uint256 id
    ) external view virtual returns (address operator) {
        return tokenApprovals[id];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f || // ERC721Metadata;
            interfaceId == 0x4e2312e0 || // ERC1155Receiver
            interfaceId == 0x2a55205a; // ERC2981
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) private returns (bool) {
        try
            IERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
        returns (bytes4 retval) {
            return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function calculateIncubationPhase(
        uint256 phase,
        uint256 ts,
        uint256 gen
    ) public view returns (uint256) {
        if (ts != 0) {
            phase += (block.timestamp - ts) / 1 weeks;
        }
        uint256 max = gen == 0
            ? initialIncubationLength
            : remixIncubationLength;
        if (phase > max) return max;
        return phase;
    }

    function getIncubationPhase(uint256 id) public view returns (uint256) {
        Token memory token = resolveToken(id);
        return
            calculateIncubationPhase(
                token.incubationPhase,
                token.stakeTimestamp,
                token.generation
            );
    }

    function getGeneration(uint256 id) public view returns (uint256) {
        if (laterGenerations[id] != 0) return laterGenerations[id];
        Token memory token = resolveToken(id);
        return token.generation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "../SuperOwnable.sol";

interface IKillaPasses {
    function burn(uint256 typeId, address owner, uint256 n) external;
}

interface IURIManager {
    function getTokenURI(
        uint256 id,
        Token memory token
    ) external view returns (string memory);
}

interface IKILLABITS {
    function detachUpgrade(uint256 token) external;

    function tokenUpgrade(uint256 token) external view returns (uint64);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IKILLAGEAR {
    function detokenize(
        address addr,
        uint256[] calldata types,
        uint256[] calldata amounts
    ) external;
}

struct Token {
    address owner;
    uint16 linkedNext;
    uint16 linkedPrev;
    uint32 stakeTimestamp;
    uint8 generation;
    uint8 incubationPhase;
    uint16 bit;
}

struct Wallet {
    uint16 balance;
    uint16 stakes;
    uint16 linkedMints;
    uint16 batchedMints;
    uint16 allowlistMints;
    uint16 privateMints;
    uint16 holderMints;
    uint16 redeems;
}

struct MintCounters {
    uint16 linked;
    uint16 batched;
    uint16 redeems;
    uint16 stakes;
}

interface IIncubator {
    function add(address owner, uint256[] calldata tokenIds) external;

    function add(address owner, uint256 start, uint256 count) external;

    function remove(address owner, uint256[] calldata tokenIds) external;

    function remove(address owner, uint256 start, uint256 count) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

abstract contract KillaCubsStorage is
    DefaultOperatorFilterer,
    SuperOwnable,
    ERC2981
{
    string public name;
    string public symbol;

    uint256 public activeGeneration = 1;
    uint256 public initialIncubationLength = 8;
    uint256 public remixIncubationLength = 4;

    IIncubator public incubator;

    MintCounters public counters;

    mapping(address => Wallet) public wallets;
    mapping(uint256 => Token) public tokens;
    mapping(uint256 => address) internal tokenApprovals;
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    IKILLABITS public bitsContract;
    IKILLAGEAR public gearContract;

    IERC721 public bears;
    IKillaPasses public passes;
    IERC721 public kilton;
    IERC721 public labs;
    bool public claimsStarted;

    mapping(uint256 => bool) public bitsUsed;
    mapping(uint256 => uint256) public laterGenerations;

    address public airdropper;
    address public staker;
    address public claimer;

    IURIManager public uriManager;

    string public baseURI;
    string public baseURIFinalized;
    uint256 public finalizedGeneration;

    mapping(bytes4 => address) extensions;
    mapping(uint256 => address) externalStorage;

    error TransferToNonERC721ReceiverImplementer();
    error NonExistentToken();
    error NotAllowed();
    error Overflow();
    error ClaimNotStarted();

    event BitsAdded(uint256[] indexed tokens, uint16[] indexed bits);
    event BitRemoved(uint256 indexed token, uint16 indexed bit);
    event FastForwarded(uint256[] indexed tokens, uint256 indexed numberOfDays);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor(
        address bitsAddress,
        address gearAddress,
        address bearsAddress,
        address passesAddress,
        address kiltonAddress,
        address labsAddress,
        address superOwner
    ) SuperOwnable(superOwner) {
        bitsContract = IKILLABITS(bitsAddress);
        gearContract = IKILLAGEAR(gearAddress);
        bears = IERC721(bearsAddress);
        passes = IKillaPasses(passesAddress);
        kilton = IERC721(kiltonAddress);
        labs = IERC721(labsAddress);
    }

    function setAirdropper(address a) external onlyOwner {
        airdropper = a;
    }

    function setStaker(address a) external onlyOwner {
        staker = a;
    }

    function setClaimer(address a) external onlyOwner {
        claimer = a;
    }

    function setExtension(bytes4 id, address a) external onlyOwner {
        extensions[id] = a;
    }

    function setExternalStorage(uint256 id, address a) external onlyOwner {
        externalStorage[id] = a;
    }

    function _delegatecall(
        address target,
        bytes memory data
    ) internal returns (bool, bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        if (!success) {
            if (returndata.length == 0) revert();
            assembly {
                revert(add(32, returndata), mload(returndata))
            }
        }
        return (success, returndata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

abstract contract SuperOwnable {
    address public owner;
    address public superOwner;

    mapping(address => bool) authorities;

    error Denied();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address superOwner_) {
        _transferOwnership(msg.sender);
        superOwner = superOwner_;
    }

    modifier onlyOwner() {
        if (msg.sender != owner && msg.sender != superOwner) revert Denied();
        _;
    }

    modifier onlySuperOwner() {
        if (msg.sender != superOwner) revert Denied();
        _;
    }

    modifier onlyAuthority() {
        if (!authorities[msg.sender] && msg.sender != owner) revert Denied();
        _;
    }

    function transferOwnership(address addr) public virtual onlyOwner {
        _transferOwnership(addr);
    }

    function _transferOwnership(address addr) internal virtual {
        address oldOwner = owner;
        owner = addr;
        emit OwnershipTransferred(oldOwner, addr);
    }

    function setSuperOwner(address addr) public onlySuperOwner {
        if (addr == address(0)) revert Denied();
        superOwner = addr;
    }

    function toggleAuthority(address addr, bool enabled) public onlyOwner {
        authorities[addr] = enabled;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}