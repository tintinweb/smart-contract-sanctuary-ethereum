// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC721WrapperVotes } from "./ERC721WrapperVotes.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract PVFDWrapperVotes is ERC721WrapperVotes {
    string public _tokenURI;

    /**
     * @param name_ Name to be set for the token
     * @param symbol_ Symbol to be set for the token
     * @param rootToken_ The address of the root token
     * @param _tokenURI_ The URI to be set for the token
     * @param maxSupply The maximum supply for the token (max 65535)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        IERC721Metadata rootToken_,
        string memory _tokenURI_,
        uint16 maxSupply
    ) ERC721WrapperVotes(name_, symbol_, rootToken_, maxSupply) {
        _tokenURI = _tokenURI_;
    }

    /**
     * @dev Return same URI for all tokens
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            ownerOf[tokenId] != address(0),
            "ERC721WrapperVotes::tokenURI: URI query for nonexistent token"
        );
        return _tokenURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ERC721Wrapper } from "./ERC721Wrapper.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { TimeCheckpoints } from "./TimeCheckpoint.sol";

/**
 * @title ERC721WrapperVotes
 * @notice A wrapper token which checkpoints delegations on the wrapper token
 * @author Arr00
 */
abstract contract ERC721WrapperVotes is ERC721Wrapper {
    using TimeCheckpoints for TimeCheckpoints.History;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );
    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(
        address indexed delegate,
        uint128 previousBalance,
        uint128 newBalance
    );

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegation;
    mapping(address => TimeCheckpoints.History) private _delegateCheckpoints;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC721Metadata rootToken_,
        uint16 maxSupply
    ) ERC721Wrapper(name_, symbol_, rootToken_, maxSupply) {}

    /**
     * @notice Called on token wrap, transfers voting units
     */
    function _onTokenWrap(address to, uint128 quantity) internal override {
        _transferVotingUnits(address(0), to, quantity);
    }

    /**
     * @notice Called on token unwrap, transfers voting units
     */
    function _onTokenUnwrap(address from, uint128 quantity) internal override {
        _transferVotingUnits(from, address(0), quantity);
    }

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) public view virtual returns (uint128) {
        return _delegateCheckpoints[account].latest();
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPriorVotes(address account, uint40 time)
        public
        view
        virtual
        returns (uint128)
    {
        return _delegateCheckpoints[account].getAtTime(time);
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegateOf(address account) public view virtual returns (address) {
        if (_delegation[account] == address(0)) {
            return account;
        }
        return _delegation[account];
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        _delegate(msg.sender, delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(
            block.timestamp <= expiry,
            "ERC721WrapperVotes::delegateBySig: signature expired"
        );
        bytes32 structHash = keccak256(
            abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "ERC721WrapperVotes::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "ERC721WrapperVotes::delegateBySig: invalid nonce"
        );
        _delegate(signatory, delegatee);
    }

    /**
     * @dev Delegate all of `account`'s voting units to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address account, address delegatee) internal virtual {
        require(
            delegatee != address(0),
            "ERC721WrapperVotes::_delegate: delegatee cannot be zero address"
        );

        address oldDelegate = delegateOf(account);
        _delegation[account] = delegatee;

        emit DelegateChanged(account, oldDelegate, delegatee);
        _moveDelegateVotes(oldDelegate, delegatee, userInfos[account].balance);
    }

    /**
     * @dev Transfers, mints, or burns voting units. To register a mint, `from` should be zero. To register a burn, `to`
     * should be zero.
     */
    function _transferVotingUnits(
        address from,
        address to,
        uint128 amount
    ) internal virtual {
        _moveDelegateVotes(delegateOf(from), delegateOf(to), amount);
    }

    /**
     * @dev Moves delegated votes from one delegate to another.
     */
    function _moveDelegateVotes(
        address from,
        address to,
        uint128 amount
    ) private {
        if (from != to && amount != 0) {
            if (from != address(0)) {
                uint128 oldValue = _delegateCheckpoints[from].push(
                    _subtract,
                    amount
                );
                emit DelegateVotesChanged(from, oldValue, oldValue - amount);
            }
            if (to != address(0)) {
                uint128 oldValue = _delegateCheckpoints[to].push(_add, amount);
                emit DelegateVotesChanged(to, oldValue, oldValue + amount);
            }
        }
    }

    function _add(uint128 a, uint128 b) private pure returns (uint128) {
        return a + b;
    }

    function _subtract(uint128 a, uint128 b) private pure returns (uint128) {
        return a - b;
    }

    /*//////////////////////////////////////////////////////////////
                        Disable All Transfers
    //////////////////////////////////////////////////////////////*/

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert("ERC721WrapperVotes::transferFrom: Transfer Disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        revert("ERC721WrapperVotes::safeTransferFrom: Transfer Disabled");
    }

    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public pure override {
        revert("ERC721WrapperVotes::safeTransferFrom: Transfer Disabled");
    }
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
pragma solidity ^0.8.16;

import { CommunityToken } from "./CommunityToken.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title ERC721Wrapper
 * @notice Implements a wrapper for the `CommunityToken` contract. Can wrap via `wrap` function or `safeTransferFrom` to the wrapper contract.
 * @author Arr00
 */
abstract contract ERC721Wrapper is CommunityToken, IERC721Receiver {
    bytes32 internal constant _WRAP_TYPEHASH =
        keccak256("Wrap(uint256 tokenId,uint256 nonce,uint256 expiry)");

    bytes32 internal constant _UNWRAP_TYPEHASH =
        keccak256("Unwrap(uint256 tokenId,uint256 nonce,uint256 expiry)");

    bytes32 internal constant _DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 DOMAIN_SEPARATOR used for signature validation
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    /// @notice The chainId which was used for calculating `DOMAIN_SEPARATOR`
    uint256 internal immutable _CHAIN_ID;

    mapping(address => uint256) public nonces;

    IERC721Metadata public immutable rootToken;

    constructor(
        string memory name_,
        string memory symbol_,
        IERC721Metadata rootToken_,
        uint16 maxSupply
    ) CommunityToken(name_, symbol_, maxSupply) {
        rootToken = rootToken_;

        // Setup EIP712

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _DOMAIN_TYPEHASH,
                keccak256(bytes(name_)),
                block.chainid,
                address(this)
            )
        );
        _CHAIN_ID = block.chainid;
    }

    /**
     * @notice Fetch the relevant domain seperator
     */
    function _domainSeparator() internal view returns (bytes32) {
        // If blockchain forked, need to get current domain separator
        return
            _CHAIN_ID == block.chainid
                ? _DOMAIN_SEPARATOR
                : keccak256(
                    abi.encode(
                        _DOMAIN_TYPEHASH,
                        keccak256(bytes(name)),
                        block.chainid,
                        address(this)
                    )
                );
    }

    /**
     * @notice Wrap an instance of `rootToken`. Must set approval first.
     * @param tokenId the tokenId of the token to wrap
     */
    function wrap(uint256 tokenId) external {
        _wrap(msg.sender, tokenId);
        _onTokenWrap(msg.sender, 1);
    }

    /**
     * @notice Wrap an instance of `rootToken` by sig. Must set approval first.
     */
    function wrapBySig(
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            block.timestamp <= expiry,
            "ERC721Wrapper::wrapBySig: signature expired"
        );

        bytes32 structHash = keccak256(
            abi.encode(_WRAP_TYPEHASH, tokenId, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
        address signatory = ecrecover(digest, v, r, s);

        require(
            signatory != address(0),
            "ERC721Wrapper::wrapBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "ERC721Wrapper::wrapBySig: invalid nonce"
        );

        _wrap(signatory, tokenId);
        _onTokenWrap(signatory, 1);
    }

    /**
     * @dev Transfer token in, then mint wrapped token to `from`
     */
    function _wrap(address from, uint256 tokenId) private {
        rootToken.transferFrom(from, address(this), tokenId);
        _mint(from, tokenId);
    }

    /**
     * @dev Wrap instances of `rootToken` when sent via `safeTransferFrom`. Send wrapped token to `from`.
     */
    function onERC721Received(
        address, /* operator */
        address from,
        uint256 tokenId,
        bytes calldata /* data */
    ) external virtual override returns (bytes4) {
        require(
            msg.sender == address(rootToken),
            "ERC721Wrapper::onERC721Received: NFT not root NFT"
        );
        _mint(from, tokenId);
        _onTokenWrap(from, 1);

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice Unwrap token. Burns the wrapped token and returns the root token.
     * @param tokenId The tokenId of the wrapped token to unwrap
     */
    function unwrap(uint256 tokenId) external {
        _unwrap(msg.sender, tokenId);
        _onTokenUnwrap(msg.sender, 1);
    }

    /**
     * @notice Unwrap token by sig. Burns the wrapped token and returns the root token.
     */
    function unwrapBySig(
        uint256 tokenId,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            block.timestamp <= expiry,
            "ERC721Wrapper::unwrapBySig: signature expired"
        );

        bytes32 structHash = keccak256(
            abi.encode(_UNWRAP_TYPEHASH, tokenId, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
        address signatory = ecrecover(digest, v, r, s);

        require(
            signatory != address(0),
            "ERC721Wrapper::unwrapBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "ERC721Wrapper::unwrapBySig: invalid nonce"
        );

        _unwrap(signatory, tokenId);
        _onTokenUnwrap(signatory, 1);
    }

    /**
     * @dev Checks that token to wrap is owned by `from`. Burns wrapped token and transfers back underlying.
     */
    function _unwrap(address from, uint256 tokenId) private {
        require(
            from == ownerOf[tokenId],
            "ERC721Wrapper::_unwrap: UNAUTHORIZED"
        );

        _burn(tokenId);
        rootToken.transferFrom(address(this), from, tokenId);
    }

    /**
     * @notice Get URI for the token with token id `tokenId`.
     * @dev Forward URI from the root token
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            ownerOf[tokenId] != address(0),
            "ERC721Wrapper::tokenURI: URI query for nonexistent token"
        );
        return rootToken.tokenURI(tokenId);
    }

    /**
     * @dev Called on token wrap
     * @param to The address which the wrapped tokens are sent to
     * @param quantity The number of tokens wrapped
     */
    function _onTokenWrap(address to, uint128 quantity) internal virtual;

    /**
     * @dev Called on token unwrap
     * @param from The address from which holds the wrapped tokens prior to unwrap
     * @param quantity The number of tokens unwrapped
     */
    function _onTokenUnwrap(address from, uint128 quantity) internal virtual;

    /*//////////////////////////////////////////////////////////////
                        Helper Function
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Wrap many instances of `rootToken`
     * @param tokenIds Array of tokenIds to wrap
     */
    function wrapMany(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            _wrap(msg.sender, tokenIds[i]);
        }
        // Wrapping of max uint128 value will always run out of gas
        _onTokenWrap(msg.sender, uint128(tokenIds.length));
    }

    /**
     * @notice Unwrap many wrapped tokens
     * @param tokenIds Array of tokenIds to unwrap
     */
    function unwrapMany(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            _unwrap(msg.sender, tokenIds[i]);
        }
        // Wrapping of max uint128 value will always run out of gas
        _onTokenUnwrap(msg.sender, uint128(tokenIds.length));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by timestamp. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction timestamp using the {push} function.
 */
library TimeCheckpoints {
    struct Checkpoint {
        uint128 _timestamp;
        uint128 _value;
    }

    struct History {
        Checkpoint[] _checkpoints;
    }

    /**
     * @dev Returns the value in the latest checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint128) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : self._checkpoints[pos - 1]._value;
    }

    /**
     * @dev Returns the value at a given timestamp. If a checkpoint is not available at that timestamp, the closest one
     * before it is returned, or zero otherwise.
     */
    function getAtTime(History storage self, uint128 timestamp)
        internal
        view
        returns (uint128)
    {
        require(
            timestamp < block.timestamp,
            "Checkpoints: block not yet mined"
        );

        uint256 high = self._checkpoints.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = (low & high) + ((low ^ high) >> 1);
            if (self._checkpoints[mid]._timestamp > timestamp) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high == 0 ? 0 : self._checkpoints[high - 1]._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current timestamp.
     */
    function push(History storage self, uint128 value)
        internal
        returns (uint128)
    {
        uint256 pos = self._checkpoints.length;
        uint128 old = latest(self);
        if (
            pos != 0 && self._checkpoints[pos - 1]._timestamp == block.timestamp
        ) {
            self._checkpoints[pos - 1]._value = value;
        } else {
            self._checkpoints.push(
                Checkpoint({
                    _timestamp: uint40(block.timestamp),
                    _value: value
                })
            );
        }

        return old;
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint128, uint128) view returns (uint128) op,
        uint128 delta
    ) internal returns (uint128) {
        return push(self, op(latest(self), delta));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 * @title CommunityToken
 * @notice Custom ERC-721 like token. Assigns a unique community ID to each holder of the NFT. Community ID is accessable via `getCommunityId`.
 * @author Arr00
 */
abstract contract CommunityToken {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    /// @notice per user storage
    struct UserInfo {
        uint128 communityId;
        uint128 balance;
    }
    /// @notice Global storage variables
    struct GlobalInfo {
        uint128 totalSupply;
        uint128 communityMembersCounter;
    }

    string public name;
    string public symbol;
    GlobalInfo internal globalInfo;
    mapping(address => UserInfo) internal userInfos;
    mapping(uint256 => address) public ownerOf;
    uint16 public immutable MAX_SUPPLY; /// @notice Max supply of the token

    /**
     * @param name_ Name to be set for the token
     * @param symbol_ Symbol to be set for the token
     * @param maxSupply The maximum supply for the token (max 65535)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint16 maxSupply
    ) {
        name = name_;
        symbol = symbol_;
        MAX_SUPPLY = maxSupply;
    }

    /**
     * @notice Returns the balance of the given `owner`
     * @param owner The address of the `owner` to check balance of
     * @return uin128 The balance of the given `owner`
     */
    function balanceOf(address owner) public view returns (uint128) {
        return userInfos[owner].balance;
    }

    /**
     * @notice Returns total supply of the token
     * @return uint128 integer value of the total supply
     */
    function totalSupply() public view returns (uint128) {
        return globalInfo.totalSupply;
    }

    /**
     * @notice Transfers `id` token from `from` to `to`.
     * @dev Does not check that `to` can receive token, use `safeTransferFrom` for that functionality
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(
            from == ownerOf[id],
            "CommunityToken::transferFrom: wrong from"
        );
        require(
            msg.sender == from,
            "CommunityToken::transferFrom: not authorized"
        );

        UserInfo storage toUserInfo = userInfos[to];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't overflow
        unchecked {
            userInfos[from].balance--;

            toUserInfo.balance++;
        }

        if (toUserInfo.communityId == 0) {
            toUserInfo.communityId = ++globalInfo.communityMembersCounter;
        }

        ownerOf[id] = to;

        emit Transfer(from, to, id);
    }

    /**
     * @notice Transfers `id` token from `from` to `to` with a safety check
     * @dev If `to` is a contract, it must implement the `IERC721Receiver` contract to receive successfully
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external virtual {
        safeTransferFrom(from, to, id, "");
    }

    /**
     * @notice Transfers `id` token from `from` to `to` with a safety check and sends `data` to receiver (`to`)
     * @dev If `to` is a contract, it must implement the `IERC721Receiver` contract to receive successfully
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId);

        require(
            to.code.length == 0 ||
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                ) ==
                IERC721Receiver.onERC721Received.selector,
            "CommunityToken::ERC721TokenReceiver: Unsafe"
        );
    }

    /**
     * @notice Mints `tokenId` and transfers it to `to`
     */
    function _mint(address to, uint256 tokenId) internal {
        require(
            to != address(0),
            "CommunityToken::_mint: mint to the zero address"
        );
        require(
            ownerOf[tokenId] == address(0),
            "CommunityToken::_mint: token already minted"
        );
        require(
            globalInfo.totalSupply < MAX_SUPPLY,
            "CommunityToken::_mint: max supply reached"
        );

        // Could overflow, mint will revert
        globalInfo.totalSupply++;

        UserInfo storage userInfo = userInfos[to];

        if (userInfo.communityId == 0) {
            userInfo.communityId = ++globalInfo.communityMembersCounter;
        }

        unchecked {
            // Can't overflow, total supply overflow first
            userInfo.balance++;
        }

        ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Destroys `tokenId`
     */
    function _burn(uint256 id) internal {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "CommunityToken::_burn: not minted");

        // Ownership check above ensures no underflow.
        unchecked {
            globalInfo.totalSupply--;
            userInfos[owner].balance--;
        }

        delete ownerOf[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                            Community ID Logic
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the community id for the given `user`
     * @dev will revert for addresses not part of community. Returns non-zero user id for members of community
     */
    function getCommunityId(address user) public view returns (uint128) {
        require(
            userInfos[user].communityId != 0,
            "CommunityToken::getCommunityId: not part of community"
        );
        return userInfos[user].communityId;
    }

    /**
     * @notice Returns the community id for the given `user`. Assigns a new community id if user is not part of community
     * @dev will revert for zero address
     */
    function getOrCreateCommunityId(address user) public returns (uint128) {
        require(
            user != address(0),
            "CommunityToken::getOrCreateCommunityId: zero address"
        );
        uint128 communityId = userInfos[user].communityId;
        if (communityId == 0) {
            userInfos[user].communityId = communityId = ++globalInfo
                .communityMembersCounter;
        }
        return communityId;
    }

    /**
     * @notice Returns the total number of community members
     */
    function getTotalCommunityMembers() public view returns (uint128) {
        return globalInfo.communityMembersCounter;
    }

    /**
     * @notice Returns the URI for the given `tokenId`
     */
    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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