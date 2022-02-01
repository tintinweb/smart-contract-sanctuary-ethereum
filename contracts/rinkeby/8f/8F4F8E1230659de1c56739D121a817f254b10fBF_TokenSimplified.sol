// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {CustomERC1155} from "./CustomERC1155.sol";

contract TokenSimplified is CustomERC1155 {
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    )
        CustomERC1155(
            _name,
            _symbol,
            _uri,
            3, /* numOptions */
            3000, /* maxSupplyPerOption */
            1, /* unlockTime */
            0xF57B2c51dED3A29e6891aba85459d600256Cf317, /* openseaProxyAddress */
            1, /* maxAllowListRedemptions */
            0xed2ea62124906818bda99512204fa6beb610c56a9ffead65673043928746a924 /* merkleRoot */
        )
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Withdrawable is Ownable {
    ////////////////////////
    // Withdrawal methods //
    ////////////////////////

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TimeLock is Ownable {
    uint256 public unlockTime;

    event UpdateUnlockTime(uint256 oldUnlockTime, uint256 newUnlockTime);

    error NotUnlocked();

    constructor(uint256 _unlockTime) {
        unlockTime = _unlockTime;
    }

    modifier onlyAfterUnlock() {
        if (block.timestamp < unlockTime) {
            revert NotUnlocked();
        }
        _;
    }

    function isUnlocked() public virtual returns (bool) {
        return block.timestamp >= unlockTime;
    }

    function setUnlockTime(uint256 _unlockTime) external onlyOwner {
        _setUnlockTime(_unlockTime);
    }

    function _setUnlockTime(uint256 _unlockTime) internal virtual {
        emit UpdateUnlockTime(unlockTime, unlockTime = _unlockTime);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract OwnerPausable is Ownable, Pausable {
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
///@notice Forked from OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.11;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 * @dev converted from a library into a contract since foreign method calls cost extra gas
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
contract MerkleVerifier {
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
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
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

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ProxyRegistry} from "./ProxyRegistry.sol";

contract AllowsConfigurableProxy is Ownable {
    uint256 public isProxyActive;
    address public proxyAddress;

    error FlagMustBe1Or0();

    constructor(address _proxyAddress, uint256 _isProxyActive) {
        if (_isProxyActive > 1) {
            revert FlagMustBe1Or0();
        }
        proxyAddress = _proxyAddress;
        isProxyActive = _isProxyActive;
    }

    function setIsProxyActive(uint256 _isProxyActive) public onlyOwner {
        if (_isProxyActive > 1) {
            revert FlagMustBe1Or0();
        }
        isProxyActive = _isProxyActive;
    }

    function setProxyAddress(address _proxyAddress) public onlyOwner {
        proxyAddress = _proxyAddress;
    }

    function isApprovedForProxy(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyAddress);
        if (
            isProxyActive == 1 &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleVerifier} from "./MerkleVerifier.sol";

contract AllowList is MerkleVerifier, Ownable {
    uint256 public immutable MAX_REDEMPTIONS;
    bytes32 public merkleRoot;
    mapping(address => uint256) addressRedemptions;

    error NotAllowListed();
    error MaxRedeemed();

    constructor(uint256 _maxRedemptions, bytes32 _merkleRoot) {
        MAX_REDEMPTIONS = _maxRedemptions;
        merkleRoot = _merkleRoot;
    }

    modifier onlyAllowListed(bytes32[] calldata _proof) {
        if (!isAllowListed(_proof, msg.sender)) {
            revert NotAllowListed();
        }
        _;
    }

    modifier redeemsAllowList() {
        _;
        unchecked {
            addressRedemptions[msg.sender]++;
        }
    }

    modifier notYetRedeemed() {
        if (addressRedemptions[msg.sender] >= MAX_REDEMPTIONS) {
            revert MaxRedeemed();
        }
        _;
    }

    function isAllowListed(bytes32[] calldata _proof, address _address)
        public
        view
        returns (bool)
    {
        return
            verify(_proof, merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _setMerkleRoot(_merkleRoot);
    }

    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {ERC1155} from "../token/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Metadata is ERC1155, Ownable {
    string public name;
    string public symbol;
    string internal uri_;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) {
        name = _name;
        symbol = _symbol;
        uri_ = _uri;
    }

    //////////////////////
    // Metadata methods //
    //////////////////////

    function uri(uint256) public view override returns (string memory) {
        return uri_;
    }

    function setUri(string calldata _uri) external onlyOwner {
        uri_ = _uri;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @notice Slightly modified to include an overrideable function for isApprovedForAll
/// @author Original: Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return _isApprovedForAll[owner][operator];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            msg.sender == from || isApprovedForAll(from, msg.sender),
            "NOT_AUTHORIZED"
        );

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || isApprovedForAll(from, msg.sender),
            "NOT_AUTHORIZED"
        );

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import {AllowList} from "./util/AllowList.sol";
import {AllowsConfigurableProxy} from "./util/AllowsConfigurableProxy.sol";
import {ERC1155Metadata} from "./token/ERC1155Metadata.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {OwnerPausable} from "./util/OwnerPausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {TimeLock} from "./util/TimeLock.sol";
import {Withdrawable} from "./util/Withdrawable.sol";

contract CustomERC1155 is
    AllowsConfigurableProxy,
    AllowList,
    ERC1155Metadata,
    OwnerPausable,
    ReentrancyGuard,
    TimeLock,
    Withdrawable
{
    uint256 public immutable NUM_OPTIONS;
    uint256 public immutable MAX_SUPPLY_PER_ID;
    uint256 public immutable MINT_PRICE = 0.1 ether;
    mapping(uint256 => uint256) public numMinted;

    error InvalidOptionID();
    error MaxSupplyForID();
    error IncorrectPayment();

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _numOptions,
        uint256 _maxSupply,
        uint256 _unlockTime,
        address _proxyAddress,
        uint256 _maxAllowListRedemptions,
        bytes32 _allowListMerkleRoot
    )
        AllowList(_maxAllowListRedemptions, _allowListMerkleRoot)
        AllowsConfigurableProxy(_proxyAddress, 1)
        ERC1155Metadata(_name, _symbol, _uri)
        TimeLock(_unlockTime)
    {
        name = _name;
        symbol = _symbol;
        NUM_OPTIONS = _numOptions;
        MAX_SUPPLY_PER_ID = _maxSupply;
    }

    //////////////////////////////
    // Access control modifiers //
    //////////////////////////////

    modifier includesCorrectPayment() {
        if (msg.value != MINT_PRICE) {
            revert IncorrectPayment();
        }
        _;
    }
    modifier canMint(uint256 _id) {
        if (_id >= NUM_OPTIONS) {
            revert InvalidOptionID();
        }
        if (numMinted[_id] >= MAX_SUPPLY_PER_ID) {
            revert MaxSupplyForID();
        }
        _;
    }

    modifier canMintMultiple(uint256 _id, uint256 _numTokens) {
        if (_id >= NUM_OPTIONS) {
            revert InvalidOptionID();
        }
        if (numMinted[_id] + _numTokens > MAX_SUPPLY_PER_ID) {
            revert MaxSupplyForID();
        }
        _;
    }

    modifier incrementsNumMinted(uint256 _id, uint256 _quantity) {
        _;
        unchecked {
            numMinted[_id] += _quantity;
        }
    }

    //////////////////
    // Mint Methods //
    //////////////////

    function mint(uint256 _id)
        external
        payable
        canMint(_id)
        includesCorrectPayment
        nonReentrant
        onlyAfterUnlock
        whenNotPaused
        incrementsNumMinted(_id, 1)
    {
        _mint(msg.sender, _id, 1, "");
    }

    function mintAllowList(uint256 _id, bytes32[] calldata _proof)
        public
        payable
        whenNotPaused
        canMint(_id)
        includesCorrectPayment
        nonReentrant
        notYetRedeemed
        onlyAllowListed(_proof)
        redeemsAllowList
        incrementsNumMinted(_id, 1)
    {
        _mint(msg.sender, _id, 1, "");
    }

    ///@dev bulk mint tokens to an address
    ///@notice onlyOwner
    function bulkMint(
        address _to,
        uint256 _id,
        uint256 _quantity
    )
        external
        onlyOwner
        canMintMultiple(_id, _quantity)
        incrementsNumMinted(_id, _quantity)
    {
        _mint(_to, _id, _quantity, "");
    }

    ////////////////////////
    // Overridden methods //
    ////////////////////////

    ///@dev overridden to allow proxy approvals for gas-free listing
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            isApprovedForProxy(_owner, _operator) ||
            super.isApprovedForAll(_owner, _operator);
    }

    function isValidTokenId(uint256 _tokenId)
        public
        view
        returns (
            // override
            bool
        )
    {
        return (_tokenId < NUM_OPTIONS);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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