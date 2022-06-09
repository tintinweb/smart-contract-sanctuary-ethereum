// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {Withdrawable} from "../../utilities/Withdrawable.sol";
import {MintGate} from "../libraries/MintGate.sol";
import {ERC721} from "./ERC721.sol";
import {ERC721Royalty} from "./extensions/ERC721Royalty.sol";

contract ERC721Basic is ERC721, ERC721Royalty, Withdrawable {

    uint256 public _endsAt;

    uint256 public _maxMintPerWallet;

    uint256 public _maxSupply;

    uint256 public _price;

    uint256 public _startsAt;


    constructor(
        string memory baseURI_,
        string memory name_,
        string memory symbol_,
        address receiver,
        uint64 fee,
        uint256 endsAt,
        uint256 maxMintPerWallet,
        uint256 maxSupply,
        uint256 price,
        uint256 startsAt
    ) ERC721(baseURI_, name_, symbol_) ERC721Royalty(receiver, fee) {
        _endsAt = endsAt;
        _maxMintPerWallet = maxMintPerWallet;
        _maxSupply = maxSupply;
        _price = price;
        _startsAt = startsAt;
    }

    function mint(uint256 quantity) external payable {
        uint256 available = _maxSupply - totalMinted();
        address buyer = _msgSender();

        MintGate.price(buyer, _price, quantity, msg.value);
        MintGate.supply(available, _maxMintPerWallet, uint256(_owner(buyer).minted), quantity);
        MintGate.time(_endsAt, _startsAt);

        _safeMint(buyer, quantity);
    }

    function supportsInterface(bytes4 interfaceId) override(ERC721, ERC721Royalty) public view virtual returns(bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner whenNotPaused {
        _withdraw(owner(), address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

error AlreadyWithdrawnForThisMonth();
error AmountExceedsBalance(string method);
error TransferFailed();
error WithdrawLockupActive();

abstract contract Withdrawable {

    bool private _locked;

    mapping(uint256 => bool) private _months;


    function _withdraw(address receiver, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AmountExceedsBalance({ method: '_withdraw' });
        }

        (bool success, ) = payable(receiver).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }
    }

    // Withdraw x% once per month
    function _withdrawOncePerMonth(address receiver, uint256 bips, uint256 deployedAt) internal {
        unchecked {
            uint256 amount = address(this).balance;
            uint256 month = ((block.timestamp - deployedAt) / 4 weeks) + 1;

            if (_months[month]) {
                revert AlreadyWithdrawnForThisMonth();
            }

            _months[month] = true;

            _withdraw(receiver, (amount * bips) / 10000);
        }
    }

    // Withdraw With x% Lockup
    // - x% available for withdraw on sale
    // - x% held by contract until `timestamp`
    function _withdrawWithLockup(address receiver, uint256 bips, uint256 unlockAt) internal {
        unchecked {
            uint256 amount = address(this).balance;

            if (amount < ((amount * bips) / 10000)) {
                revert AmountExceedsBalance({ method: '_withdrawWithLockup' });
            }

            // x% can be withdrawn to kickstart project; Remaining x% will be
            // held throughout `lockup` period
            if (!_locked) {
                amount = (amount * bips) / 10000;
                _locked = true;
            }
            else if (block.timestamp < unlockAt) {
                revert WithdrawLockupActive();
            }

            _withdraw(receiver, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error CannotMintMoreThan(uint256 amount);
error MaxMintPerWalletWouldBeReached(uint256 max);
error NeedToSendMoreETH();
error QuantityWouldExceedMaxSupply();
error SaleHasNotStarted();
error SaleHasEnded();

library MintGate {

    function isWhitelisted(address buyer, bytes32[] calldata proof, bytes32 root) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, keccak256(abi.encodePacked(buyer)));
    }

    function price(address buyer, uint256 cost, uint256 quantity, uint256 received) internal {
        unchecked {
            uint256 total = cost * quantity;

            if (total < received) {
                revert NeedToSendMoreETH();
            }

            // Refund remaining value
            if (received > total) {
                payable(buyer).transfer(received - total);
            }
        }
    }

    function supply(uint256 available, uint256 max, uint256 minted, uint256 quantity) internal pure {
        if (quantity > available) {
            revert QuantityWouldExceedMaxSupply();
        }

        if (max > 0) {
            if (quantity > max) {
                revert CannotMintMoreThan({ amount: max });
            }

            if ((minted + quantity) > max) {
                revert MaxMintPerWalletWouldBeReached({ max: max });
            }
        }
    }

    function time(uint256 end, uint256 start) internal view {
        if (block.timestamp < start) {
            revert SaleHasNotStarted();
        }

        if (end != 0 && block.timestamp > end) {
            revert SaleHasEnded();
        }
    }
}

// SPDX-License-Identifier: MIT
// Fork of ERC721A created by Chiru Labs
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

error ApproveToCaller();
error ApprovalToCurrentOwner();
error CallerNotOwnerNorApproved(string method);
error MethodReceivedZeroAddress(string method);
error MintZeroQuantity();
error QueryForNonexistentToken(string method);
error TokenQueryProducedVariant();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();

/**
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3...)
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * Assumes that the maximum token tokenId cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721 is Context, IERC721, Ownable, Pausable {
    using Strings for uint256;


    uint32 public constant MINT_BATCH_SIZE = 8;

    uint32 public constant STATE_BURNED = 1;
    uint32 public constant STATE_MINTED = 2;
    uint32 public constant STATE_TRANSFERRED = 3;


    struct Approvals {
        // Owner Address => [Operator Address => Approved if true, otherwise false]
        mapping(address => mapping(address => bool)) operators;

        // Token Id => Approved Address
        mapping(uint256 => address) tokens;
    }

    struct Owner {
        uint64 balance;
        uint64 burned;
        uint64 minted;
        uint64 misc;
    }

    struct Token {
        address owner;
        uint32 state;
        uint64 updatedAt;
    }


    string internal _baseURI;

    uint256 private _burned;

    string internal _name;

    uint256 private _nextId;

    string internal _symbol;


    // Namespaced Approval Data
    Approvals private _approvals;

    // Owner Address => Owner Data
    mapping(address => Owner) private _owners;

    // Token Id => Token Data
    mapping(uint256 => Token) private _tokens;


    constructor(string memory baseURI_, string memory name_, string memory symbol_) Ownable() Pausable() {
        _baseURI = baseURI_;
        _name = name_;
        _nextId = _startTokenId();
        _symbol = symbol_;
    }


    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token tokenId to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address from, address to, uint256 tokenId) private {
        _approvals.tokens[tokenId] = to;

        emit Approval(from, to, tokenId);
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are
     * about to be transferred. This includes minting. And also called before
     * burning one token.
     *
     * startTokenId - the first token tokenId to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool verifyApproved) internal virtual whenNotPaused {
        Token memory token = _token(tokenId);

        if (verifyApproved && !_isApprovedOrOwner(tokenId, _msgSender())) {
            revert CallerNotOwnerNorApproved({ method: '_burn' });
        }

        _beforeTokenTransfers(token.owner, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(token.owner, address(0), tokenId);

        // Update next 'tokenId' if owned by 'from'
        _setDeferredOwnership(tokenId, token);

        // Underflow of the sender's balance is impossible because we check for
        // token above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            Owner storage owner = _owners[token.owner];
            owner.balance -= 1;
            owner.burned += 1;

            _burned += 1;
        }

        // Keep track of last owner
        _tokens[tokenId] = Token({
            owner: token.owner,
            state: STATE_BURNED,
            updatedAt: uint64(block.timestamp)
        });

        emit Transfer(token.owner, address(0), tokenId);

        _afterTokenTransfers(token.owner, address(0), tokenId, 1);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token tokenId
     * @param to target address that will receive the tokens
     * @param tokenId uint256 tokenId of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns(bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns(bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        }
        catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            }

            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns(bool) {
        return (tokenId + 1) > _startTokenId() && tokenId < _nextId && _tokens[tokenId].state != STATE_BURNED;
    }

    function _isApprovedOrOwner(uint256 tokenId, address sender) internal view returns(bool) {
        address owner = ownerOf(tokenId);

        return sender == owner || getApproved(tokenId) == sender || isApprovedForAll(owner, sender);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity, bytes memory data, bool safe) internal whenNotPaused {
        uint256 start = _nextId;

        if (to == address(0)) {
            revert MethodReceivedZeroAddress({ method: '_mint' });
        }

        if (quantity == 0) {
            revert MintZeroQuantity();
        }

        _beforeTokenTransfers(address(0), to, start, quantity);

        // Overflows are incredibly unrealistic.
        // balance or minted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // tokenId overflows if _nextId + quantity > 1.2e77 (2**256) - 1
        unchecked {
            Owner storage owner = _owners[to];
            owner.balance += uint64(quantity);
            owner.minted += uint64(quantity);

            uint256 batches = quantity / MINT_BATCH_SIZE;

            if (quantity % MINT_BATCH_SIZE != 0) {
                batches += 1;
            }

            for (uint256 batch = 0; batch < batches; batch++) {
                _tokens[start + (MINT_BATCH_SIZE * batch)] = Token({
                    owner: to,
                    state: STATE_MINTED,
                    updatedAt: uint64(block.timestamp)
                });
            }

            uint256 current = start;
            uint256 last = current + quantity;

            if (safe && to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, current);

                    if (!_checkContractOnERC721Received(address(0), to, current++, data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (current != last);

                // Reentrancy protection
                if (_nextId != start) {
                    revert();
                }
            }
            else {
                do {
                    emit Transfer(address(0), to, current++);
                } while (current != last);
            }

            _nextId = current;
        }

        _afterTokenTransfers(address(0), to, start, quantity);
    }

    function _owner(address owner) internal view returns(Owner memory) {
        return _owners[owner];
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity, bytes memory data) internal {
        _mint(to, quantity, data, true);
    }

    /**
     * If the token slot of tokenId+1 is not explicitly set, that means the
     * transfer initiator owns it. Set the slot of tokenId+1 explicitly in
     * storage to maintain correctness for ownerOf(tokenId+1) calls.
     */
    function _setDeferredOwnership(uint256 tokenId, Token memory token) private {
        uint256 next = tokenId + 1;

        if (_exists(next) && _tokens[next].owner == address(0)) {
            _tokens[next] = token;
        }
    }

    function _startTokenId() internal view virtual returns(uint256) {
        return 1;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _token(uint256 tokenId) internal view returns(Token memory) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: '_token' });
        }

        unchecked {
            uint256 batch = MINT_BATCH_SIZE + 1;
            uint256 n = _startTokenId();

            if (n == 1) {
                n = 0;
            }

            if (tokenId > batch) {
                n = tokenId - batch;
            }

            for (uint256 i = tokenId; i > n; i--) {
                Token memory token = _tokens[i];

                if (token.owner != address(0)) {
                    return token;
                }
            }
        }

        revert TokenQueryProducedVariant();
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) private whenNotPaused {
        Token memory token = _token(tokenId);

        if (to == address(0)) {
            revert MethodReceivedZeroAddress({ method: '_transfer' });
        }

        if (token.owner != from) {
            revert TransferFromIncorrectOwner();
        }

        if (!_isApprovedOrOwner(tokenId, _msgSender())) {
            revert CallerNotOwnerNorApproved({ method: '_transfer' });
        }

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(token.owner, address(0), tokenId);

        // Update next tokenId if owned by 'from'
        _setDeferredOwnership(tokenId, token);

        // Underflow of the sender's balance is impossible because we check for
        // token above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _owners[from].balance -= 1;
            _owners[to].balance += 1;
        }

        _tokens[tokenId] = Token({
            owner: to,
            state: uint32(STATE_TRANSFERRED),
            updatedAt: uint64(block.timestamp)
        });

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev See {IERC721-approve}
     */
    function approve(address to, uint256 tokenId) override public {
        address owner = ownerOf(tokenId);
        address sender = _msgSender();

        if (to == owner) {
            revert ApprovalToCurrentOwner();
        }

        if (sender != owner && !isApprovedForAll(owner, sender)) {
            revert CallerNotOwnerNorApproved({ method: 'approve' });
        }

        _approve(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}
     */
    function balanceOf(address owner) override public view returns(uint256) {
        if (owner == address(0)) {
            revert MethodReceivedZeroAddress({ method: 'balanceOf' });
        }

        return uint256(_owners[owner].balance);
    }

    /**
     * @dev See {IERC721-getApproved}
     */
    function getApproved(uint256 tokenId) override public view returns(address) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'getApproved' });
        }

        return _approvals.tokens[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}
     */
    function isApprovedForAll(address owner, address operator) override public view virtual returns(bool) {
        return _approvals.operators[owner][operator];
    }

    function name() public view virtual returns(string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721-ownerOf}
     */
    function ownerOf(uint256 tokenId) override public view returns(address) {
        return _token(tokenId).owner;
    }

    function ownership(uint256 tokenId) external view returns(address, uint32, uint64) {
        Token memory token = _token(tokenId);

        return (token.owner, token.state, token.updatedAt);
    }

    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) override public virtual {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) override public virtual {
        _transfer(from, to, tokenId);

        if (to.code.length != 0 && !_checkContractOnERC721Received(from, to, tokenId, data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev See {IERC721-setApprovalForAll}
     */
    function setApprovalForAll(address operator, bool approved) override public virtual {
        address sender = _msgSender();

        if (operator == sender) {
            revert ApproveToCaller();
        }

        _approvals.operators[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    function setBaseURI(string memory uri) public onlyOwner virtual {
        _baseURI = uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) override public view virtual returns(bool) {
        return
            // ERC165 interface ID for ERC165.
            interfaceId == 0x01ffc9a7 ||
            // ERC165 interface ID for ERC721.
            interfaceId == 0x80ac58cd ||
            // ERC165 interface ID for ERC721Metadata.
            interfaceId == 0x5b5e139f;
    }

    function symbol() public view virtual returns(string memory) {
        return _symbol;
    }

    function tokensOf(address owner, uint256 start, uint256 stop) external view returns(uint256[] memory) {
        unchecked {
            uint256 balance = balanceOf(owner);
            uint256 max = _nextId;

            if (start < _startTokenId()) {
                start = _startTokenId();
            }

            if (stop > max) {
                stop = max;
            }

            if (start < stop) {
                if (balance > stop - start) {
                    balance = stop - start;
                }
            }
            else {
                balance = 0;
            }

            uint256[] memory ids = new uint256[](balance);

            if (balance == 0) {
                return ids;
            }

            // Cursor token may not be 'initialized' due to ERC721A design, use
            // normal token fetching function to find owner of token.
            Token memory token = _token(start);
            address current;

            if (token.state != STATE_BURNED) {
                current = token.owner;
            }

            uint256 j;

            for (uint256 i = start; i != stop && j != balance; ++i) {
                token = _tokens[i];

                if (token.owner == address(0) || token.state == STATE_BURNED) {
                    continue;
                }

                current = token.owner;

                if (current == owner) {
                    ids[j++] = i;
                }
            }

            // Downsize the array to fit
            assembly {
                mstore(ids, j)
            }

            return ids;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual returns(string memory) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'tokenURI' });
        }

        string memory base = _baseURI;

        if (bytes(base).length != 0) {
            return string(abi.encodePacked(base, tokenId.toString()));
        }

        return "";
    }

    function totalBurned() public view returns(uint256) {
        return _burned;
    }

    function totalMinted() public view returns(uint256) {
        unchecked {
            return _nextId - _startTokenId();
        }
    }

    function totalSupply() public view returns(uint256) {
        unchecked {
            return _nextId - _burned - _startTokenId();
        }
    }

    /**
     * @dev See {IERC721-transferFrom}
     */
    function transferFrom(address from, address to, uint256 tokenId) override public virtual {
        safeTransferFrom(from, to, tokenId);
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC2981} from "../../ERC2981/ERC2981.sol";
import {ERC721} from "../ERC721.sol";

abstract contract ERC721Royalty is ERC721, ERC2981 {

    constructor(address receiver, uint256 fee) ERC2981(receiver, fee) {}


    function setDefaultRoyaltyInfo(address receiver, uint256 fee) internal onlyOwner {
        _setDefaultRoyaltyInfo(receiver, fee);
    }

    function setRoyaltyInfo(uint256 tokenId, address receiver, uint256 fee) internal onlyOwner {
        _setRoyaltyInfo(tokenId, receiver, fee);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
pragma solidity ^0.8.12;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ERC2981 is ERC165, IERC2981 {

    struct RoyaltyInfo {
        // Fee in Basis Points
        uint256 fee;
        address receiver;
    }


    RoyaltyInfo private _default;

    mapping(uint256 => RoyaltyInfo) private _info;


    constructor(address receiver, uint256 fee) {
        _default = RoyaltyInfo({
            fee: fee,
            receiver: receiver
        });
    }


    function _setDefaultRoyaltyInfo(address receiver, uint256 fee) internal {
        _default = RoyaltyInfo({
            fee: fee,
            receiver: receiver
        });
    }

    function _setRoyaltyInfo(uint256 tokenId, address receiver, uint256 fee) internal {
        _info[tokenId] = RoyaltyInfo({
            fee: fee,
            receiver: receiver
        });
    }

    function royaltyInfo(uint256 tokenId, uint256 amount) external view override(IERC2981) returns (address, uint256) {
        uint256 fee = _info[tokenId].fee;
        address receiver = _info[tokenId].receiver;

        if (receiver == address(0) || fee == 0) {
            fee = _default.fee;
            receiver = _default.receiver;
        }

        return (receiver, (amount * fee / 10000));
    }

    function supportsInterface(bytes4 interfaceId) override(ERC165, IERC165) public view virtual returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
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