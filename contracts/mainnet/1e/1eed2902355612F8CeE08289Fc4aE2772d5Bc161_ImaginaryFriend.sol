// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
@title SignatureChecker
@notice Additional functions for EnumerableSet.Addresset that require a valid
ECDSA signature of a standardized message, signed by any member of the set.
 */
library SignatureChecker {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation + signature verification
    + marking message as used
    @param signers Set of addresses from which signatures are accepted.
    @param usedMessages Set of already-used messages.
    @param signature ECDSA signature of message.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes memory data,
        bytes calldata signature,
        mapping(bytes32 => bool) storage usedMessages
    ) internal {
        bytes32 message = generateMessage(data);
        require(
            !usedMessages[message],
            "SignatureChecker: Message already used"
        );
        usedMessages[message] = true;
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation + signature verification.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes memory data,
        bytes calldata signature
    ) internal view {
        bytes32 message = generateMessage(data);
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Requires that the message has not been used previously and that the
    recovered signer is contained in the signers AddressSet.
    @dev Convenience wrapper for message generation from address +
    signature verification.
     */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        address a,
        bytes calldata signature
    ) internal view {
        bytes32 message = generateMessage(abi.encodePacked(a));
        requireValidSignature(signers, message, signature);
    }

    /**
    @notice Common validator logic, checking if the recovered signer is
    contained in the signers AddressSet.
    */
    function validSignature(
        EnumerableSet.AddressSet storage signers,
        bytes32 message,
        bytes calldata signature
    ) internal view returns (bool) {
        return signers.contains(ECDSA.recover(message, signature));
    }

    /**
    @notice Requires that the recovered signer is contained in the signers
    AddressSet.
    @dev Convenience wrapper that reverts if the signature validation fails.
    */
    function requireValidSignature(
        EnumerableSet.AddressSet storage signers,
        bytes32 message,
        bytes calldata signature
    ) internal view {
        require(
            validSignature(signers, message, signature),
            "SignatureChecker: Invalid signature"
        );
    }

    /**
    @notice Generates a message for a given data input that will be signed
    off-chain using ECDSA.
    @dev For multiple data fields, a standard concatenation using 
    `abi.encodePacked` is commonly used to build data.
     */
    function generateMessage(bytes memory data)
        internal
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(data);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
@notice ERC721 extension that overrides the OpenZeppelin _baseURI() function to
return a prefix that can be set by the contract owner.
 */
contract BaseTokenURI is Ownable {
    /// @notice Base token URI used as a prefix by tokenURI().
    string public baseTokenURI;

    constructor(string memory _baseTokenURI) {
        setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
    @notice Concatenates and returns the base token URI and the token ID without
    any additional characters (e.g. a slash).
    @dev This requires that an inheriting contract that also inherits from OZ's
    ERC721 will have to override both contracts; although we could simply
    require that users implement their own _baseURI() as here, this can easily
    be forgotten and the current approach guides them with compiler errors. This
    favours the latter half of "APIs should be easy to use and hard to misuse"
    from https://www.infoq.com/articles/API-Design-Joshua-Bloch/.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenURI;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721APreApproval.sol";
import "../utils/OwnerPausable.sol";

/**
@notice An ERC721A contract with common functionality:
 - OpenSea gas-free listings
 - Pausable with toggling functions exposed to Owner only
 */
contract ERC721ACommon is ERC721APreApproval, OwnerPausable {
    constructor(string memory name, string memory symbol)
        ERC721A(name, symbol)
    {} // solhint-disable-line no-empty-blocks

    /// @notice Requires that the token exists.
    modifier tokenExists(uint256 tokenId) {
        require(ERC721A._exists(tokenId), "ERC721ACommon: Token doesn't exist");
        _;
    }

    /// @notice Requires that msg.sender owns or is approved for the token.
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "ERC721ACommon: Not approved nor owner"
        );
        _;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(!paused(), "ERC721ACommon: paused");
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "../thirdparty/opensea/OpenSeaGasFreeListing.sol";
import "erc721a/contracts/ERC721A.sol";

/// @notice Pre-approval of OpenSea proxies for gas-less listing
/// @dev This wrapper allows users to revoke the pre-approval of their
/// associated proxy and emits the corresponding events. This is necessary for
/// external tools to index approvals correctly and inform the user.
/// @dev The pre-approval is triggered on a per-wallet basis during the first
/// transfer transactions. It will only be enabled for wallets with an existing
/// proxy. Not having a proxy incurs a gas overhead.
/// @dev This wrapper optimizes for the following scenario:
/// - The majority of users already have a wyvern proxy
/// - Most of them want to transfer tokens via wyvern exchanges
abstract contract ERC721APreApproval is ERC721A {
    /// @dev It is important that Active remains at first position, since this
    /// is the scenario that we are trying to optimize for.
    enum State {
        Active,
        Inactive
    }

    /// @notice The state of the pre-approval for a given owner
    mapping(address => State) private state;

    /// @dev Returns true if either standard `isApprovedForAll()` or if the
    /// `operator` is the OpenSea proxy for the `owner` provided the
    /// pre-approval is active.
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        if (super.isApprovedForAll(owner, operator)) {
            return true;
        }

        return
            state[owner] == State.Active &&
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator);
    }

    /// @dev Uses the standard `setApprovalForAll` or toggles the pre-approval
    /// state if `operator` is the OpenSea proxy for the sender.
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        address owner = _msgSender();
        if (operator == OpenSeaGasFreeListing.proxyFor(owner)) {
            state[owner] = approved ? State.Active : State.Inactive;
            emit ApprovalForAll(owner, operator, approved);
        } else {
            super.setApprovalForAll(operator, approved);
        }
    }

    /// @dev Checks if the receiver has an existing proxy. If not, the
    /// pre-approval is disabled.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);

        // Exclude burns and inactive pre-approvals
        if (to == address(0) || state[to] == State.Inactive) {
            return;
        }

        address operator = OpenSeaGasFreeListing.proxyFor(to);

        // Disable if `to` has no proxy
        if (operator == address(0)) {
            state[to] = State.Inactive;
            return;
        }

        // Avoid emitting unnecessary events.
        if (balanceOf(to) == 0) {
            emit ApprovalForAll(to, operator, true);
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "./Seller.sol";

/// @notice A Seller with fixed per-item price.
abstract contract FixedPriceSeller is Seller {
    constructor(
        uint256 _price,
        Seller.SellerConfig memory sellerConfig,
        address payable _beneficiary
    ) Seller(sellerConfig, _beneficiary) {
        setPrice(_price);
    }

    /**
    @notice The fixed per-item price.
    @dev Fixed as in not changing with time nor number of items, but not a
    constant.
     */
    uint256 public price;

    /// @notice Sets the per-item price.
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
    @notice Override of Seller.cost() with fixed price.
    @dev The second parameter, metadata propagated from the call to _purchase(),
    is ignored.
     */
    function cost(uint256 n, uint256) public view override returns (uint256) {
        return n * price;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "../utils/Monotonic.sol";
import "../utils/OwnerPausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
@notice An abstract contract providing the _purchase() function to:
 - Enforce per-wallet / per-transaction limits
 - Calculate required cost, forwarding to a beneficiary, and refunding extra
 */
abstract contract Seller is OwnerPausable, ReentrancyGuard {
    using Address for address payable;
    using Monotonic for Monotonic.Increaser;
    using Strings for uint256;

    /**
    @dev Note that the address limits are vulnerable to wallet farming.
    @param maxPerAddress Unlimited if zero.
    @param maxPerTex Unlimited if zero.
    @param freeQuota Maximum number that can be purchased free of charge by
    the contract owner.
    @param reserveFreeQuota Whether to excplitly reserve the freeQuota amount
    and not let it be eroded by regular purchases.
    @param lockFreeQuota If true, calls to setSellerConfig() will ignore changes
    to freeQuota. Can be locked after initial setting, but not unlocked. This
    allows a contract owner to commit to a maximum number of reserved items.
    @param lockTotalInventory Similar to lockFreeQuota but applied to
    totalInventory.
    */
    struct SellerConfig {
        uint256 totalInventory;
        uint256 maxPerAddress;
        uint256 maxPerTx;
        uint248 freeQuota;
        bool reserveFreeQuota;
        bool lockFreeQuota;
        bool lockTotalInventory;
    }

    constructor(SellerConfig memory config, address payable _beneficiary) {
        setSellerConfig(config);
        setBeneficiary(_beneficiary);
    }

    /// @notice Configuration of purchase limits.
    SellerConfig public sellerConfig;

    /// @notice Sets the seller config.
    function setSellerConfig(SellerConfig memory config) public onlyOwner {
        require(
            config.totalInventory >= config.freeQuota,
            "Seller: excessive free quota"
        );
        require(
            config.totalInventory >= _totalSold.current(),
            "Seller: inventory < already sold"
        );
        require(
            config.freeQuota >= purchasedFreeOfCharge.current(),
            "Seller: free quota < already used"
        );

        // Overriding the in-memory fields before copying the whole struct, as
        // against writing individual fields, gives a greater guarantee of
        // correctness as the code is simpler to read.
        if (sellerConfig.lockTotalInventory) {
            config.lockTotalInventory = true;
            config.totalInventory = sellerConfig.totalInventory;
        }
        if (sellerConfig.lockFreeQuota) {
            config.lockFreeQuota = true;
            config.freeQuota = sellerConfig.freeQuota;
        }
        sellerConfig = config;
    }

    /// @notice Recipient of revenues.
    address payable public beneficiary;

    /// @notice Sets the recipient of revenues.
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    /**
    @dev Must return the current cost of a batch of items. This may be constant
    or, for example, decreasing for a Dutch auction or increasing for a bonding
    curve.
    @param n The number of items being purchased.
    @param metadata Arbitrary data, propagated by the call to _purchase() that
    can be used to charge different prices. This value is a uint256 instead of
    bytes as this allows simple passing of a set cost (see
    ArbitraryPriceSeller).
     */
    function cost(uint256 n, uint256 metadata)
        public
        view
        virtual
        returns (uint256);

    /**
    @dev Called by both _purchase() and purchaseFreeOfCharge() after all limits
    have been put in place; must perform all contract-specific sale logic, e.g.
    ERC721 minting. When _handlePurchase() is called, the value returned by
    Seller.totalSold() will be the pre-purchase amount.
    @param to The recipient of the item(s).
    @param n The number of items allowed to be purchased, which MAY be less than
    to the number passed to _purchase() but SHALL be greater than zero.
    @param freeOfCharge Indicates that the call originated from
    purchaseFreeOfCharge() and not _purchase().
    */
    function _handlePurchase(
        address to,
        uint256 n,
        bool freeOfCharge
    ) internal virtual;

    /**
    @notice Tracks total number of items sold by this contract, including those
    purchased free of charge by the contract owner.
     */
    Monotonic.Increaser private _totalSold;

    /// @notice Returns the total number of items sold by this contract.
    function totalSold() public view returns (uint256) {
        return _totalSold.current();
    }

    /**
    @notice Tracks the number of items already bought by an address, regardless
    of transferring out (in the case of ERC721).
    @dev This isn't public as it may be skewed due to differences in msg.sender
    and tx.origin, which it treats in the same way such that
    sum(_bought)>=totalSold().
     */
    mapping(address => uint256) private _bought;

    /**
    @notice Returns min(n, max(extra items addr can purchase)) and reverts if 0.
    @param zeroMsg The message with which to revert on 0 extra.
     */
    function _capExtra(
        uint256 n,
        address addr,
        string memory zeroMsg
    ) internal view returns (uint256) {
        uint256 extra = sellerConfig.maxPerAddress - _bought[addr];
        if (extra == 0) {
            revert(string(abi.encodePacked("Seller: ", zeroMsg)));
        }
        return Math.min(n, extra);
    }

    /// @notice Emitted when a buyer is refunded.
    event Refund(address indexed buyer, uint256 amount);

    /// @notice Emitted on all purchases of non-zero amount.
    event Revenue(
        address indexed beneficiary,
        uint256 numPurchased,
        uint256 amount
    );

    /// @notice Tracks number of items purchased free of charge.
    Monotonic.Increaser private purchasedFreeOfCharge;

    /**
    @notice Allows the contract owner to purchase without payment, within the
    quota enforced by the SellerConfig.
     */
    function purchaseFreeOfCharge(address to, uint256 n)
        public
        onlyOwner
        whenNotPaused
    {
        uint256 freeQuota = sellerConfig.freeQuota;
        n = Math.min(n, freeQuota - purchasedFreeOfCharge.current());
        require(n > 0, "Seller: Free quota exceeded");

        uint256 totalInventory = sellerConfig.totalInventory;
        n = Math.min(n, totalInventory - _totalSold.current());
        require(n > 0, "Seller: Sold out");

        _handlePurchase(to, n, true);

        _totalSold.add(n);
        purchasedFreeOfCharge.add(n);
        assert(_totalSold.current() <= totalInventory);
        assert(purchasedFreeOfCharge.current() <= freeQuota);
    }

    /**
    @notice Convenience function for calling _purchase() with empty costMetadata
    when unneeded.
     */
    function _purchase(address to, uint256 requested) internal virtual {
        _purchase(to, requested, 0);
    }

    /**
    @notice Enforces all purchase limits (counts and costs) before calling
    _handlePurchase(), after which the received funds are disbursed to the
    beneficiary, less any required refunds.
    @param to The final recipient of the item(s).
    @param requested The number of items requested for purchase, which MAY be
    reduced when passed to _handlePurchase().
    @param costMetadata Arbitrary data, propagated in the call to cost(), to be
    optionally used in determining the price.
     */
    function _purchase(
        address to,
        uint256 requested,
        uint256 costMetadata
    ) internal nonReentrant whenNotPaused {
        /**
         * ##### CHECKS
         */
        SellerConfig memory config = sellerConfig;

        uint256 n = config.maxPerTx == 0
            ? requested
            : Math.min(requested, config.maxPerTx);

        uint256 maxAvailable;
        uint256 sold;

        if (config.reserveFreeQuota) {
            maxAvailable = config.totalInventory - config.freeQuota;
            sold = _totalSold.current() - purchasedFreeOfCharge.current();
        } else {
            maxAvailable = config.totalInventory;
            sold = _totalSold.current();
        }

        n = Math.min(n, maxAvailable - sold);
        require(n > 0, "Seller: Sold out");

        if (config.maxPerAddress > 0) {
            bool alsoLimitSender = _msgSender() != to;
            // solhint-disable-next-line avoid-tx-origin
            bool alsoLimitOrigin = tx.origin != _msgSender() && tx.origin != to;

            n = _capExtra(n, to, "Buyer limit");
            if (alsoLimitSender) {
                n = _capExtra(n, _msgSender(), "Sender limit");
            }
            if (alsoLimitOrigin) {
                // solhint-disable-next-line avoid-tx-origin
                n = _capExtra(n, tx.origin, "Origin limit");
            }

            _bought[to] += n;
            if (alsoLimitSender) {
                _bought[_msgSender()] += n;
            }
            if (alsoLimitOrigin) {
                // solhint-disable-next-line avoid-tx-origin
                _bought[tx.origin] += n;
            }
        }

        uint256 _cost = cost(n, costMetadata);
        if (msg.value < _cost) {
            revert(
                string(
                    abi.encodePacked(
                        "Seller: Costs ",
                        (_cost / 1e9).toString(),
                        " GWei"
                    )
                )
            );
        }

        /**
         * ##### EFFECTS
         */

        _handlePurchase(to, n, false);
        _totalSold.add(n);
        assert(_totalSold.current() <= config.totalInventory);

        /**
         * ##### INTERACTIONS
         */

        // Ideally we'd be using a PullPayment here, but the user experience is
        // poor when there's a variable cost or the number of items purchased
        // has been capped. We've addressed reentrancy with both a nonReentrant
        // modifier and the checks, effects, interactions pattern.

        if (_cost > 0) {
            beneficiary.sendValue(_cost);
            emit Revenue(beneficiary, n, _cost);
        }

        if (msg.value > _cost) {
            address payable reimburse = payable(_msgSender());
            uint256 refund = msg.value - _cost;

            // Using Address.sendValue() here would mask the revertMsg upon
            // reentrancy, but we want to expose it to allow for more precise
            // testing. This otherwise uses the exact same pattern as
            // Address.sendValue().
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = reimburse.call{
                value: refund
            }("");
            // Although `returnData` will have a spurious prefix, all we really
            // care about is that it contains the ReentrancyGuard reversion
            // message so we can check in the tests.
            require(success, string(returnData));

            emit Refund(reimburse, refund);
        }
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

// Inspired by BaseOpenSea by Simon Fremaux (@dievardump) but without the need
// to pass specific addresses depending on deployment network.
// https://gist.github.com/dievardump/483eb43bc6ed30b14f01e01842e3339b/

import "./ProxyRegistry.sol";

/// @notice Library to achieve gas-free listings on OpenSea.
library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        address proxy = proxyFor(owner);
        return proxy != address(0) && proxy == operator;
    }

    /**
    @notice Returns the OpenSea proxy address for the owner.
     */
    function proxyFor(address owner) internal view returns (address) {
        address registry;
        uint256 chainId;

        assembly {
            chainId := chainid()
            switch chainId
            // Production networks are placed higher to minimise the number of
            // checks performed and therefore reduce gas. By the same rationale,
            // mainnet comes before Polygon as it's more expensive.
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 137 {
                // polygon
                registry := 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
            case 80001 {
                // mumbai
                registry := 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c
            }
            case 1337 {
                // The geth SimulatedBackend iff used with the ethier
                // openseatest package. This is mocked as a Wyvern proxy as it's
                // more complex than the 0x ones.
                registry := 0xE1a2bbc877b29ADBC56D2659DBcb0ae14ee62071
            }
        }

        // Unlike Wyvern, the registry itself is the proxy for all owners on 0x
        // chains.
        if (registry == address(0) || chainId == 137 || chainId == 80001) {
            return registry;
        }

        return address(ProxyRegistry(registry).proxies(owner));
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

/// @notice A minimal interface describing OpenSea's Wyvern proxy registry.
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
@dev This pattern of using an empty contract is cargo-culted directly from
OpenSea's example code. TODO: it's likely that the above mapping can be changed
to address => address without affecting anything, but further investigation is
needed (i.e. is there a subtle reason that OpenSea released it like this?).
 */
// solhint-disable-next-line no-empty-blocks
contract OwnableDelegateProxy {

}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

/**
@notice Provides monotonic increasing and decreasing values, similar to
OpenZeppelin's Counter but (a) limited in direction, and (b) allowing for steps
> 1.
 */
library Monotonic {
    /**
    @notice Holds a value that can only increase.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and add().
     */
    struct Increaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Increaser.
    function current(Increaser storage incr) internal view returns (uint256) {
        return incr.value;
    }

    /// @notice Adds x to the Increaser's value.
    function add(Increaser storage incr, uint256 x) internal {
        incr.value += x;
    }

    /**
    @notice Holds a value that can only decrease.
    @dev The internal value MUST NOT be accessed directly. Instead use current()
    and subtract().
     */
    struct Decreaser {
        uint256 value;
    }

    /// @notice Returns the current value of the Decreaser.
    function current(Decreaser storage decr) internal view returns (uint256) {
        return decr.value;
    }

    /// @notice Subtracts x from the Decreaser's value.
    function subtract(Decreaser storage decr, uint256 x) internal {
        decr.value -= x;
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @notice A Pausable contract that can only be toggled by the Owner.
contract OwnerPausable is Ownable, Pausable {
    /// @notice Pauses the contract.
    function pause() public onlyOwner {
        Pausable._pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        Pausable._unpause();
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/common/ERC2981.sol)

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
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
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
     * - `tokenId` must be already minted.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

uint8 constant NUM_BACKGROUNDS = 13;
uint8 constant NUM_BODIES = 36;
uint8 constant NUM_MOUTHS = 35;
uint8 constant NUM_EYES = 45;

/// @notice The possible values of the Special trait.
enum Special {
    None,
    Devil,
    Angel,
    Both
}

/// @notice The features an ImaginaryFriend can have.
/// @dev The features are base 1 - zero means the corresponding trait is
/// deactivated.
struct Features {
    uint8 background;
    uint8 body;
    uint8 mouth;
    uint8 eyes;
    Special special;
    bool golden;
}

/// @notice A serialized version of `Features`
type FeaturesSerialized is bytes32;

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

import "./Common.sol";

interface IMetadataRenderer {
    function tokenFeatures(
        uint256 tokenId,
        FeaturesSerialized data,
        FeaturesSerialized[] memory allData,
        bool autogenerate
    ) external view returns (Features memory, bool);

    function tokenURI(
        uint256 tokenId,
        FeaturesSerialized data,
        string memory baseURI,
        FeaturesSerialized[] memory allData,
        bool autogenerate,
        bool countSiblings
    ) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.0 <0.9.0;

import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/sales/FixedPriceSeller.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./Common.sol";
import "./Serializer.sol";
import "./IMetadataRenderer.sol";

contract ImaginaryFriend is
    ERC721ACommon,
    FixedPriceSeller,
    BaseTokenURI,
    ERC2981
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SignatureChecker for EnumerableSet.AddressSet;
    using Deserializer for FeaturesSerialized;
    using Serializer for Features;

    uint256 private constant MAX_NUM_TOKENS = 3000;

    /// @notice Set of addresses that are approved to issue early access.
    /// allowances.
    EnumerableSet.AddressSet private _signersEarlyAccess;

    /// @notice Set of addresses that are approved to issue quiz allowances.
    EnumerableSet.AddressSet private _signersQuiz;

    /// @notice Stores the number of tokens minted from am allowance during the
    /// early access stage.
    /// @dev Used in `mintEarlyAccess`
    mapping(bytes32 => uint256) public numMintedFrom;

    /// @notice Contains quiz results for the tokens.
    /// @dev Null corresponds to the quiz not being answered.
    /// @dev Storing a serialized version of the data was needed to enable a
    /// more efficient handling in memory.
    mapping(uint256 => FeaturesSerialized) private _tokenFeatures;

    /// @notice The metadata renderer
    IMetadataRenderer public renderer;

    /// @notice Flag to disable use of setRenderer().
    bool private rendererLocked;

    /// @notice The different minting states of the collection.
    /// @dev This is used to enable/disable the respective minting methods.
    /// Closed = no minting
    /// EarlyAccess = mint using signatures, see `mintEarlyAccess`
    /// Public = public minting, see `mintPublic`
    enum MintingStage {
        Closed,
        EarlyAccess1,
        EarlyAccess2,
        EarlyAccess3,
        EarlyAccess4,
        Public
    }

    /// @notice The current minting stage of the contract.
    MintingStage public mintingStage;

    /// @notice The different states of the quiz.
    /// @dev This is used to control the behavior of `setQuizAnswers`,
    /// `_tokenFeatures` and `tokenURI`.
    /// Closed = quiz answers cannot be set in the contract. All tokenURIs
    /// point to the fallback URL.
    /// Open = quiz answers can be stored using `setQuizAnswers`. The
    /// corresponding token metadata and image URI will be returned.
    /// Finished = quiz answers can no longer be stored. Token metadata, etc.
    /// of the unanswered tokens will be autogenerated.
    enum QuizStage {
        Closed,
        Open,
        Finished
    }

    /// @notice The current state of the quiz.
    QuizStage public quizStage;

    constructor(
        address signerEarlyAccess,
        address signerQuiz,
        address payable paymentSplitter,
        address payable royaltyReceiver,
        string memory baseURI
    )
        ERC721ACommon("My Imaginary Friend by Kai", "KAIIF")
        FixedPriceSeller(
            0.5 ether,
            Seller.SellerConfig({
                totalInventory: MAX_NUM_TOKENS,
                maxPerAddress: 1,
                maxPerTx: 1,
                freeQuota: 300,
                reserveFreeQuota: true,
                lockFreeQuota: false,
                lockTotalInventory: true
            }),
            paymentSplitter
        )
        BaseTokenURI(baseURI)
    {
        _signersEarlyAccess.add(signerEarlyAccess);
        _signersQuiz.add(signerQuiz);

        _setDefaultRoyalty(royaltyReceiver, _feeDenominator() / 10); // 10 %
    }

    // -------------------------------------------------------------------------
    //
    //  Minting
    //
    // -------------------------------------------------------------------------

    /// @notice Minting interface for wallets on the early-access lists.
    /// @dev Only active during early-access `mintingStage`.
    /// @dev The minter might be different than the receiver.
    /// @param to Token receiver
    /// @param num Number of tokens to be minted.
    /// @param numMax Max number of tokens that can be minted to the receiver.
    /// @param nonce additional signature salt.
    /// @param signature to prove that the receiver is allowed to get mints.
    /// @dev The signed messages is generated by concatenating
    /// `address(this) || stage || to || numMax || nonce`.
    function mintEarlyAccess(
        MintingStage stage,
        address to,
        uint16 num,
        uint16 numMax,
        uint128 nonce,
        bytes calldata signature
    )
        external
        payable
        onlyBetweenMintingStages(MintingStage.EarlyAccess1, MintingStage.Public)
        bypassSellerLimits
    {
        if (mintingStage < stage) revert WrongStage();
        bytes32 message = SignatureChecker.generateMessage(
            abi.encodePacked(address(this), stage, to, numMax, nonce)
        );

        if (num + numMintedFrom[message] > numMax)
            revert TooManyMintsRequested();

        _signersEarlyAccess.requireValidSignature(message, signature);
        numMintedFrom[message] += num;

        _purchase(to, num);
    }

    /// @notice Public minting interface.
    /// @dev Only active during public `mintingStage`.
    /// @param num Number of tokens to be minted.
    function mintPublic(uint16 num)
        external
        payable
        onlyDuringMintingStage(MintingStage.Public)
    {
        _purchase(msg.sender, num);
    }

    /// @notice Mints tokens with the given sets of features.
    /// @dev Can only be called by the owner. Draws from the pool of free mints.
    /// @param to The token receiver.
    /// @param features Array of features that the minted tokens should have.
    function mintWithFeatures(address to, Features[] calldata features)
        external
        onlyOwner
    {
        uint256 num = features.length;
        uint256 nextId = totalSupply();
        purchaseFreeOfCharge(to, num);
        for (uint256 idx = 0; idx < num; ++idx) {
            _setFeatures(nextId, features[idx]);
            ++nextId;
        }
    }

    /// @notice Callback to handle purchasing logic.
    /// @dev The `freeOfCharge` boolean flag is deliberately ignored.
    function _handlePurchase(
        address to,
        uint256 num,
        bool
    ) internal override {
        _safeMint(to, num);
    }

    // -------------------------------------------------------------------------
    //
    //  Quiz
    //
    // -------------------------------------------------------------------------

    /// @notice Stores the `feature`s for a given token that resulted from the
    /// quiz.
    /// @dev Only active during open `quizState`.
    /// @dev The golden propperty of the `features` argument is ignored.
    /// @dev Can only be called once per token by either the token owner or
    /// approved wallets.
    /// @param tokenId The tokenId for which the results will be stored.
    /// @param features The quiz results to be stored.
    /// @param signature To prove that the caller is allowed to set the given
    /// features.
    function setQuizResults(
        uint256 tokenId,
        Features calldata features,
        bytes calldata signature
    ) external onlyWhileQuizOpen onlyApprovedOrOwner(tokenId) {
        if (_tokenFeatures[tokenId].isSet()) revert QuizResultsAlreadySet();

        bytes32 message = SignatureChecker.generateMessage(
            abi.encodePacked(
                address(this),
                tokenId,
                features.background,
                features.body,
                features.mouth,
                features.eyes,
                features.special
            )
        );
        _signersQuiz.requireValidSignature(message, signature);
        _setFeatures(tokenId, features);
    }

    /// @notice Checks if the quiz has already been answered for a given token.
    /// @dev Reverts if the token doesn't exist.
    /// @param tokenId The token of interest.
    function hasQuizResults(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (bool)
    {
        return _tokenFeatures[tokenId].isSet();
    }

    /// @notice Sets the features for a given token.
    /// @dev Ensures that only the genesis token is golden.
    function _setFeatures(uint256 tokenId, Features memory features) internal {
        features.golden = (tokenId == 0);
        _validateFeatures(features);
        _tokenFeatures[tokenId] = features.serialize();
    }

    /// @notice Checks if token features are valid.
    /// @dev Reverts on invalid features.
    function _validateFeatures(Features memory results) internal pure {
        if (
            results.background > 0 &&
            results.body > 0 &&
            results.mouth > 0 &&
            results.eyes > 0 &&
            results.background <= NUM_BACKGROUNDS &&
            results.body <= NUM_BODIES &&
            results.mouth <= NUM_MOUTHS &&
            results.eyes <= NUM_EYES &&
            results.special <= Special.Both
        ) return;

        revert InvalidTokenFeatures();
    }

    // -------------------------------------------------------------------------
    //
    //  Signature validataion
    //
    // -------------------------------------------------------------------------

    /// @notice Removes and adds addresses to the set of allowed signers for
    /// early access mint allowances.
    /// @dev Removal is performed before addition.
    function changeSignersEarlyAccess(
        address[] calldata delSigners,
        address[] calldata addSigners
    ) external onlyOwner {
        _changeSigners(_signersEarlyAccess, delSigners, addSigners);
    }

    /// @notice Returns the signer addresses that are approved to issue
    /// allowances for the early-access minting.
    function getSignersEarlyAccess() external view returns (address[] memory) {
        return _getSigners(_signersEarlyAccess);
    }

    /// @notice Removes and adds addresses to the set of allowed signers for
    /// quiz results.
    /// @dev Removal is performed before addition.
    function changeSignersQuiz(
        address[] calldata delSigners,
        address[] calldata addSigners
    ) external onlyOwner {
        _changeSigners(_signersQuiz, delSigners, addSigners);
    }

    /// @notice Returns the signer addresses that are approved to issue
    /// allowances for the early-access minting.
    function getSignersQuiz() external view returns (address[] memory) {
        return _getSigners(_signersQuiz);
    }

    /// @notice Removes and adds addresses to the set of allowed signers.
    /// @dev Removal is performed before addition.
    function _changeSigners(
        EnumerableSet.AddressSet storage signers,
        address[] calldata delSigners,
        address[] calldata addSigners
    ) internal {
        for (uint256 idx; idx < delSigners.length; ++idx) {
            signers.remove(delSigners[idx]);
        }
        for (uint256 idx; idx < addSigners.length; ++idx) {
            signers.add(addSigners[idx]);
        }
    }

    /// @notice Returns the signer addresses in a given set.
    function _getSigners(EnumerableSet.AddressSet storage signers)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = signers.length();
        address[] memory signers_ = new address[](len);
        for (uint256 idx = 0; idx < len; ++idx) {
            signers_[idx] = signers.at(idx);
        }
        return signers_;
    }

    // -------------------------------------------------------------------------
    //
    //  Metadata
    //
    // -------------------------------------------------------------------------

    /// @notice Sets the address of the rendering contract.
    function setRenderer(IMetadataRenderer renderer_) public onlyOwner {
        if (rendererLocked) revert RendererLocked();
        renderer = renderer_;
    }

    /// @notice Permanently disables `setRenderer`
    function lockRenderer() external onlyOwner {
        rendererLocked = true;
    }

    /// @notice Retrieves the features of an existing token.
    /// @param tokenId The token of interest.
    /// @dev Forwards the call to the metadata render.
    function tokenFeatures(uint256 tokenId)
        external
        view
        tokenExists(tokenId)
        returns (Features memory)
    {
        FeaturesSerialized data = _tokenFeatures[tokenId];
        FeaturesSerialized[] memory all = _loadAllTokenFeatures();
        bool autogenerate = (quizStage == QuizStage.Finished);

        (Features memory features, ) = renderer.tokenFeatures(
            tokenId,
            data,
            all,
            autogenerate
        );

        return features;
    }

    /// @notice Retrieves the data-uri encoded metadata json for an existing
    /// token.
    /// @param tokenId The token of interest.
    /// @dev Forwards the call to the metadata render.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        FeaturesSerialized data = _tokenFeatures[tokenId];
        FeaturesSerialized[] memory all = _loadAllTokenFeatures();
        bool autogenerate = (quizStage == QuizStage.Finished);

        return
            renderer.tokenURI(
                tokenId,
                data,
                _baseURI(),
                all,
                autogenerate,
                countSiblings
            );
    }

    /// @notice Loads all token features to memory.
    /// @dev This also loads data for unminted tokens (which will be zeroes).
    /// This ensures that the entropy derived therefrom can only be affected by
    /// actual quiz answers. Hence, allowing tokens to be safely minted even
    /// after the quiz was already finished without affecting the
    /// randomized autogeneration.
    function _loadAllTokenFeatures()
        private
        view
        returns (FeaturesSerialized[] memory)
    {
        FeaturesSerialized[] memory all = new FeaturesSerialized[](
            MAX_NUM_TOKENS
        );
        for (uint256 idx = 0; idx < MAX_NUM_TOKENS; idx++) {
            all[idx] = _tokenFeatures[idx];
        }
        return all;
    }

    // -------------------------------------------------------------------------
    //
    //  Royalties
    //
    // -------------------------------------------------------------------------

    /// @notice Sets the royalty receiver and percentage (in units of 0.01%).
    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    // -------------------------------------------------------------------------
    //
    //  Internals
    //
    // -------------------------------------------------------------------------

    /// @notice Sets the contract to a given minting stage.
    /// @dev Imposes minting limits when switching to public minting.
    function setMintingStage(MintingStage stage) external onlyOwner {
        mintingStage = stage;
    }

    /// @notice Sets the progress of the quiz to a given state.
    function setQuizStage(QuizStage stage) external onlyOwner {
        quizStage = stage;
    }

    /// @notice Sets limitations for minting.
    /// @dev This is a convenience interface for `setSellerConfig`.
    /// It is intended to eventuallty relax minting limits for the public
    /// minting stage.
    function setMintingLimits(uint256 maxPerAddress, uint256 maxPerTx)
        external
        onlyOwner
    {
        sellerConfig.maxPerAddress = maxPerAddress;
        sellerConfig.maxPerTx = maxPerTx;
    }

    /// @notice Determines if siblings are counted.
    bool private countSiblings;

    /// @notice Toggles `countSiblings`
    function setCountSiblings(bool toggle) external onlyOwner {
        countSiblings = toggle;
    }

    /// @notice Ensures that a method can only be called during a certain
    /// minting stage.
    modifier onlyDuringMintingStage(MintingStage stage) {
        if (mintingStage != stage) revert WrongStage();
        _;
    }

    /// @notice Ensures that a method can only be called between certain
    /// minting stages.
    modifier onlyBetweenMintingStages(MintingStage from, MintingStage to) {
        if (mintingStage < from || to < mintingStage) revert WrongStage();
        _;
    }

    /// @notice Ensures that a method can only be called while the quiz is open.
    modifier onlyWhileQuizOpen() {
        if (quizStage != QuizStage.Open) revert WrongStage();
        _;
    }

    /// @notice Bypasses ethiers Seller limits for a given method.
    modifier bypassSellerLimits() {
        SellerConfig memory savedConfig = sellerConfig;
        sellerConfig.maxPerTx = 0;
        sellerConfig.maxPerAddress = 0;
        _;
        sellerConfig.maxPerTx = savedConfig.maxPerTx;
        sellerConfig.maxPerAddress = savedConfig.maxPerAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    // -------------------------------------------------------------------------
    //
    //  Errors
    //
    // -------------------------------------------------------------------------

    error TooManyMintsRequested();
    error RendererLocked();
    error WrongStage();
    error InvalidTokenFeatures();
    error TokenNotYetRevealed();
    error QuizResultsAlreadySet();
}

// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 divergence.xyz
pragma solidity >=0.8.8 <0.9.0;

import "./Common.sol";

/// @notice A helper library for `TokenData` serialization.
/// @dev Data is serialized by following the same order and bit-width of fields
/// as given in the definition of the structs using litte-endian encoding.
/// `TokenDataSerialized` will therefore only ever use the rightmost 80 bits.
library Serializer {
    /// @notice Serializes a given set of features.
    function serialize(Features memory features)
        internal
        pure
        returns (FeaturesSerialized)
    {
        unchecked {
            uint48 packed;
            packed += features.background;
            packed <<= 8;
            packed += features.body;
            packed <<= 8;
            packed += features.mouth;
            packed <<= 8;
            packed += features.eyes;
            packed <<= 8;
            packed += uint8(features.special);
            packed <<= 8;
            packed += features.golden ? 1 : 0;
            return FeaturesSerialized.wrap(bytes32(uint256(packed)));
        }
    }

    /// @notice The hash based on which features can be considered to be the
    /// same.
    /// @dev Just a serializaiton and cast
    function hash(Features memory features) internal pure returns (bytes32) {
        return bytes32(FeaturesSerialized.unwrap(serialize(features)));
    }
}

/// @notice A helper library for `TokenDataSerialized` unpacking.
library Deserializer {
    /// @notice Retrieves the `feature` field from serialized data.
    /// @notice Deserializes data into a struct.
    function deserialize(FeaturesSerialized data_)
        internal
        pure
        returns (Features memory)
    {
        unchecked {
            Features memory feats;
            uint256 data = _toUint256(data_);
            feats.golden = uint8(data) == 1;
            data >>= 8;
            feats.special = Special(uint8(data));
            data >>= 8;
            feats.eyes = uint8(data);
            data >>= 8;
            feats.mouth = uint8(data);
            data >>= 8;
            feats.body = uint8(data);
            data >>= 8;
            feats.background = uint8(data);
            return feats;
        }
    }

    /// @notice Checks it the data is set, i.e. non-zero
    function isSet(FeaturesSerialized data) internal pure returns (bool) {
        return FeaturesSerialized.unwrap(data) != 0;
    }

    /// @notice Converts the serialized data to an `uint`.
    function _toUint256(FeaturesSerialized data)
        private
        pure
        returns (uint256)
    {
        return uint256(FeaturesSerialized.unwrap(data));
    }

    /// @notice The hash based on which features can be considered to be the
    /// same.
    /// @dev Just the serialized version
    function hash(FeaturesSerialized features) internal pure returns (bytes32) {
        return FeaturesSerialized.unwrap(features);
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr && curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex &&
            !_ownerships[tokenId].burned;
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
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
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
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (safe && to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex != end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex != end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev This is equivalent to _burn(tokenId, false)
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
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
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
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
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}