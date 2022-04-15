// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ERC721OwnershipBasedStaking} from "../token/ERC721/extensions/ERC721OwnershipBasedStaking.sol";
import {ERC721Royalty} from "../token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721} from "../token/ERC721/ERC721.sol";
import {MintGate} from "../token/libraries/MintGate.sol";
import {Withdrawable} from "../utilities/Withdrawable.sol";

error AddressNotWhitelisted();

contract Metapass is ERC721OwnershipBasedStaking, ERC721Royalty, Withdrawable {

    uint256 public constant GAME_RESERVE = 250;

    uint256 public constant MAX_MINT_PER_WALLET = 2;
    uint256 public constant MAX_SUPPLY = 5000;

    // April 17, 2022 - 9:00 AM PST
    uint256 public constant MINT_END_TIME = 1650211200;

    // April 16, 2022 - 9:00 AM PST
    uint256 public constant MINT_START_TIME = 1650124800;

    uint256 public constant PUBLIC_PRICE = 0.2 ether;

    uint256 public constant VAULT_RESERVE = 750;
    address public constant VAULT_WALLET = 0x24D9EC1327eE15cD102ba72Fe98B580A7424af8B;

    bytes32 public constant WHITELIST_MERKLE_ROOT = 0xce40398c6324370b2faa1f4b6080e79641d61160efbb67c338bdde85a78e5313;
    uint256 public constant WHITELIST_PRICE = 0.15 ether;

    // April 15, 2022 - 9:00 AM PST
    uint256 public constant WHITELIST_START_TIME = 1650038400;


    constructor() ERC721OwnershipBasedStaking("Metapass", "metapass") ERC721Royalty(_msgSender(), 750) {
        setConfig(ERC721OwnershipBasedStaking.Config({
            fusible: false,
            listingFee: 0,
            resetOnTransfer: true,
            rewardsPerWeek: 3,
            // ( Rewards per week ) * ( 4 weeks ) * ( 6 months ) * ( x4 Minter Multiplier )
            upgradeFee: (3 * 4 * 3 * 4)
        }));
        setMultipliers(ERC721OwnershipBasedStaking.Multipliers({
            level: 1000,
            max: 80000,
            minter: 40000,
            // Once 'MINTER_MULTIPLIER' is lost it should take 4 months to regain
            month: 10000
        }));
    }


    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721, ERC721OwnershipBasedStaking) virtual {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function mintPublic(uint256 quantity) external nonReentrant payable {
        uint256 available = MAX_SUPPLY - GAME_RESERVE - VAULT_RESERVE - totalMinted();
        address buyer = _msgSender();

        MintGate.price(buyer, PUBLIC_PRICE, quantity, msg.value);
        MintGate.supply(available, MAX_MINT_PER_WALLET, uint256(_owner(buyer).minted), quantity);
        MintGate.time(MINT_END_TIME, MINT_START_TIME);

        _safeMint(buyer, quantity);
    }

    function mintToGameWallet(uint256 quantity) external nonReentrant onlyOwner {
        MintGate.supply((MAX_SUPPLY - totalMinted()), GAME_RESERVE, uint256(_owner(_msgSender()).minted), quantity);

        _safeMint(_msgSender(), quantity);
    }

    function mintToVaultWallet(uint256 quantity) external nonReentrant onlyOwner {
        MintGate.supply((MAX_SUPPLY - totalMinted()), VAULT_RESERVE, uint256(_owner(VAULT_WALLET).minted), quantity);

        _safeMint(VAULT_WALLET, quantity);
    }

    function mintUnsoldToVaultWallet() external nonReentrant onlyOwner {
        uint256 quantity = MAX_SUPPLY - totalMinted();

        if (MINT_END_TIME > block.timestamp || quantity == 0) {
            revert();
        }

        if (quantity > 10) {
            quantity = 10;
        }

        _safeMint(VAULT_WALLET, quantity);
    }

    function mintWhitelist(bytes32[] calldata proof, uint256 quantity) external nonReentrant payable {
        uint256 available = MAX_SUPPLY - GAME_RESERVE - VAULT_RESERVE - totalMinted();
        address buyer = _msgSender();

        if (proof.length == 0 || !MintGate.isWhitelisted(buyer, proof, WHITELIST_MERKLE_ROOT)) {
            revert AddressNotWhitelisted();
        }

        MintGate.price(buyer, WHITELIST_PRICE, quantity, msg.value);
        MintGate.supply(available, MAX_MINT_PER_WALLET, _owner(buyer).minted, quantity);
        MintGate.time(MINT_START_TIME, WHITELIST_START_TIME);

        _safeMint(buyer, quantity);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721OwnershipBasedStaking, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner nonReentrant whenNotPaused {
        _withdraw(owner(), address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Admin} from "../../../utilities/Admin.sol";
import {CallerNotOwnerNorApproved, ERC721} from "../ERC721.sol";

error AmountExceedsAccountBalance(string method);
error FeatureIsDisabled();
error ZeroRewards();

abstract contract ERC721OwnershipBasedStaking is Admin, ERC721, ReentrancyGuard {

    event Charged(uint256 indexed tokenId, uint64 amount, address indexed sender);
    event Deposited(uint256 indexed tokenId, uint64 amount, address indexed sender);
    event LevelUpdated(uint256 indexed tokenId, uint64 current, uint64 previous);


    struct Account {
        uint64 balance;
        uint64 claimedAt;
        uint64 level;
    }

    struct Config {
        // If true NFT can be fused with another within the collection
        bool fusible;
        // Fee charged ( in staking rewards ) when creating a token swap for staking rewards
        uint64 listingFee;
        // Reset staking rewards on transfer if true, otherwise false
        bool resetOnTransfer;
        // Staking rewards earned per week
        uint64 rewardsPerWeek;
        // Fee charged to upgrade the level of NFT
        // - Grants access to better perks in the system
        uint64 upgradeFee;
    }

    struct Multipliers {
        // Level staking multiplier ( in Basis Points )
        uint64 level;
        // Max staking multiplier ( in Basis Points )
        uint64 max;
        // Original minter multiplier ( in Basis Points )
        uint64 minter;
        // Multiplier per month owned ( in Basis Points )
        uint64 month;
    }


    mapping(uint256 => Account) private _accounts;

    Config private _config;

    Multipliers private _multipliers;



    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) ReentrancyGuard() { }


    function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override(ERC721) virtual {
        super._afterTokenTransfers(from, to, startTokenId, quantity);

        if (!_config.resetOnTransfer) {
            return;
        }

        for (uint256 i = 0; i < quantity; i++) {
            _accounts[startTokenId + i].balance = 0;
        }
    }

    function _charge(uint256 tokenId, uint64 amount, string memory method) private returns (uint256) {
        unchecked {
            Account storage account = _accounts[tokenId];

            if (account.balance < amount) {
                revert AmountExceedsAccountBalance({ method: method });
            }

            account.balance -= amount;

            return uint256(account.balance);
        }
    }

    function calculateStakingRewards(uint256 tokenId) public view returns (uint256) {
        Account memory account = _accounts[tokenId];
        Multipliers memory m = _multipliers;
        Token memory token = _token(tokenId);

        unchecked {
            uint64 claimedAt = account.claimedAt;
            uint64 timestamp = uint64(block.timestamp);

            if (claimedAt < token.updatedAt) {
                claimedAt = token.updatedAt;
            }

            if (timestamp < claimedAt) {
                return 0;
            }

            // Convert level to bonus in Basis Points ( Level 1 * 1000 = 10% bonus )
            uint64 multiplier = 10000 + (account.level * m.level);
            uint64 points = _config.rewardsPerWeek * ((timestamp - claimedAt) / uint64(1 weeks));

            // Apply original minter/owner multiplier
            if (token.state == ERC721.STATE_MINTED) {
                multiplier += m.minter;
            }

            multiplier += m.month * ((timestamp - token.updatedAt) / uint64(4 weeks));

            if (multiplier > m.max) {
                multiplier = m.max;
            }

            return uint256(points + (points * multiplier / 10000));
        }
    }

    function charge(uint256 tokenId, uint64 amount) external nonReentrant returns (uint256) {
        address sender = _msgSender();

        if (!_isAdmin(sender)) {
            revert CallerNotOwnerNorApproved({ method: 'charge' });
        }

        emit Charged(tokenId, amount, sender);

        return _charge(tokenId, amount, 'charge');
    }

    function claimStakingRewards(uint256 tokenId) external nonReentrant returns (uint256) {
        address sender = _msgSender();

        if (!_isApprovedOrOwner(tokenId, sender)) {
            revert CallerNotOwnerNorApproved({ method: 'claimStakingRewards' });
        }

        unchecked {
            uint256 rewards = calculateStakingRewards(tokenId);

            if (rewards == 0) {
                revert ZeroRewards();
            }

            Account storage account = _accounts[tokenId];

            account.balance += uint64(rewards);
            account.claimedAt = uint64(block.timestamp);

            return uint256(account.balance);
        }
    }

    function config() external view returns (bool, uint64, bool, uint64, uint64) {
        return (
            _config.fusible,
            _config.listingFee,
            _config.resetOnTransfer,
            _config.rewardsPerWeek,
            _config.upgradeFee
        );
    }

    function deposit(uint256 tokenId, uint64 amount) private returns (uint64) {
        address sender = _msgSender();

        if (!_isAdmin(sender)) {
            revert CallerNotOwnerNorApproved({ method: 'deposit' });
        }

        emit Deposited(tokenId, amount, sender);

        unchecked {
            Account storage account = _accounts[tokenId];

            account.balance += amount;

            return account.balance;
        }
    }

    function fuse(uint256 a, uint256 b) external nonReentrant virtual {
        if (!_config.fusible) {
            revert FeatureIsDisabled();
        }

        address sender = _msgSender();

        if (!_isAdmin(sender) && (ownerOf(a) != sender || ownerOf(b) != sender)) {
            revert CallerNotOwnerNorApproved({ method: 'fuse' });
        }

        Account storage A = _accounts[a];

        // Balances shouldn't be merged during fusing. Fused passes would become
        // too OP. They would have the ability to stake -> fuse -> continously
        // sweep the vault.
        // - Primary purpose of fusing should be to achieve max multiplier
        //   and access items available to rarer passes.
        // - In order to gain the above perks you will have to sacrifice the
        //   staking rewards in pass b.
        unchecked {
            uint64 previous = A.level;

            A.level += _accounts[b].level + 1;

            emit LevelUpdated(a, A.level, previous);
        }

        _burn(b, false);

        delete _accounts[b];
    }

    function multipliers() external view returns (uint64, uint64, uint64, uint64) {
        return (
            _multipliers.level,
            _multipliers.max,
            _multipliers.minter,
            _multipliers.month
        );
    }

    function rewardsOf(uint256 tokenId) external view returns (uint64) {
        return _accounts[tokenId].balance;
    }

    function rewardsOf(uint256[] memory tokenIds) external view returns (uint64[] memory) {
        uint64[] memory balances;
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n; i++) {
            balances[i] = _accounts[tokenIds[i]].balance;
        }

        return balances;
    }

    function setConfig(Config memory data) onlyOwner public {
        _config = data;
    }

    function setMultipliers(Multipliers memory data) onlyOwner public {
        _multipliers = data;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function upgrade(uint256 tokenId) external nonReentrant virtual {
        uint64 fee = _config.upgradeFee;

        if (fee == 0) {
            revert FeatureIsDisabled();
        }

        address sender = _msgSender();

        if (ownerOf(tokenId) != sender) {
            revert CallerNotOwnerNorApproved({ method: 'upgrade' });
        }

        _charge(tokenId, fee, 'upgrade');

        unchecked {
            Account storage account = _accounts[tokenId];
            uint64 previous = account.level;

            account.level += 1;

            emit LevelUpdated(tokenId, account.level, previous);
        }
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
// Fork of ERC721A created by Chiru Labs
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
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
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, Ownable, Pausable {
    using Address for address;
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

    mapping(uint256 => string) private _tokenURI;


    constructor(string memory name_, string memory symbol_) Ownable() Pausable() {
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
    function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
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
    function _exists(uint256 tokenId) internal view returns (bool) {
        return (tokenId + 1) > _startTokenId() && tokenId < _nextId && _tokens[tokenId].state != STATE_BURNED;
    }

    function _isApprovedOrOwner(uint256 tokenId, address sender) internal view returns (bool) {
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

            if (safe && to.isContract()) {
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

    function _owner(address owner) internal view returns (Owner memory) {
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

    function _startTokenId() internal view virtual returns (uint256) {
        return 1;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _token(uint256 tokenId) internal view returns (Token memory) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: '_token' });
        }

        unchecked {
            uint256 batch = MINT_BATCH_SIZE + 1;
            uint256 n = _startTokenId();

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
    function balanceOf(address owner) override public view returns (uint256) {
        if (owner == address(0)) {
            revert MethodReceivedZeroAddress({ method: 'balanceOf' });
        }

        return uint256(_owners[owner].balance);
    }

    /**
     * @dev See {IERC721-getApproved}
     */
    function getApproved(uint256 tokenId) override public view returns (address) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'getApproved' });
        }

        return _approvals.tokens[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}
     */
    function isApprovedForAll(address owner, address operator) override public view virtual returns (bool) {
        return _approvals.operators[owner][operator];
    }

    function name() override(IERC721Metadata) public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721-ownerOf}
     */
    function ownerOf(uint256 tokenId) override public view returns (address) {
        return _token(tokenId).owner;
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

        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, data)) {
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


    function setTokenURI(uint256 tokenId, string memory uri) public onlyOwner virtual {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'setTokenURI' });
        }

        _tokenURI[tokenId] = uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) override(ERC165, IERC165) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function symbol() override(IERC721Metadata) public view virtual returns (string memory) {
        return _symbol;
    }

    function tokensOf(address owner, uint256 cursor, uint256 size) external view returns (uint256[] memory, uint256) {
        uint256 balance = balanceOf(owner);
        uint256 max = _nextId;

        if (balance == 0) {
            return (new uint256[](0), cursor);
        }

        unchecked {
            if (cursor < _startTokenId()) {
                cursor = _startTokenId();
            }

            uint256 length = size;

            if (length > max - cursor) {
                length = max - cursor;
            }

            uint256[] memory ids = new uint256[](balance);

            // Cursor token may not be 'initialized' due to ERC721A design, use
            // normal token fetching function to find owner of token.
            Token memory token = _token(cursor);
            address current;

            if (token.state != STATE_BURNED) {
                current = token.owner;
            }

            uint256 j;

            for (uint256 i = cursor; i != length && j != balance; i++) {
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

            return (ids, (cursor + size));
        }
    }

    function tokenURI(uint256 tokenId) override(IERC721Metadata) public view virtual returns (string memory) {
        if (!_exists(tokenId)) {
            revert QueryForNonexistentToken({ method: 'tokenURI' });
        }

        string memory base = _baseURI;
        string memory token = _tokenURI[tokenId];

        if (bytes(token).length == 0) {
            token = tokenId.toString();
        }

        if (bytes(base).length != 0) {
            return string(abi.encodePacked(base, token));
        }

        return token;
    }

    function totalBurned() public view returns (uint256) {
        return _burned;
    }

    function totalMinted() public view returns (uint256) {
        unchecked {
            return _nextId - _startTokenId();
        }
    }

    function totalSupply() public view returns (uint256) {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract Admin {

    mapping(address => bool) private _admin;


    function _isAdmin(address operator) internal view returns (bool) {
        return _admin[operator];
    }

    function _setAdmin(address operator, bool admin) internal {
        _admin[operator] = admin;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
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