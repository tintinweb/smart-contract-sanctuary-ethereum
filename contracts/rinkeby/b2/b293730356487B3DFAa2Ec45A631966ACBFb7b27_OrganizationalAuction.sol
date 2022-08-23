// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OrganizationalAuction is Initializable {
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    event AuctionCreated(uint256 auctionId, Auction auction, string metadata);
    event AuctionFinalized(uint256 auctionId);
    event AuctionClosed(uint256 auctionId);

    event BidReceived(uint256 auctionId, uint64 endTime);

    event WithdrawlFallback(uint256 amount, address to);

    enum AuctionTypes {
        BUYNOW,
        TRADITIONAL
    }

    struct Bid {
        address bidder;
        uint256 amount;
        uint64 timestamp;
        bool refunded;
    }

    struct Beneficiary {
        uint16 percentage;
        address payable wallet;
    }

    struct CreateAuction {
        string metadata;
        uint256 initialBidAmount;
        int256 maximumIncrease;
        uint64 startTime;
        uint64 endTime;
        uint32 duration;
        uint32 extensionPeriod;
        uint32 quantity;
        uint8 percentIncrease;
        AuctionTypes auctionType;
        Beneficiary[] beneficiaries;
    }

    struct AuctionDefaults {
        uint32 duration;
        uint32 extensionPeriod;
        uint32 quantity;
        uint8 percentIncrease;
        int256 maximumIncrease;
    }

    struct Auction {
        uint64 startTime;
        uint64 endTime;
        uint64 finalizedTime;
        uint32 duration;
        uint32 extensionPeriod;
        uint32 quantity;
        uint8 percentIncrease;
        int256 maximumIncrease;
        uint256 initialBidAmount;
        uint256 treasury;
        AuctionTypes auctionType;
        Bid[] bids;
        Beneficiary[] beneficiaries;
    }

    Counters.Counter private auctionIds;

    mapping(uint256 => Auction) public auctions;

    uint256 public organizationId;

    function initialize(uint256 _organizationId) public virtual initializer {
        organizationId = _organizationId;
    }

    function getForwarder() internal pure returns (address) {
        return 0x55A0f5aa3f5724208063344694eAd4EB09642234;
    }

    function canBid(Auction memory auction) internal view {
        Auction memory auctionWithDefaults = getAuctionWithDefaults(auction);
        uint64 currentTime = uint64(block.timestamp);

        require(auction.startTime > 0, "No auction found");

        require(
            auction.startTime <= currentTime,
            "Auction has not started yet"
        );

        require(
            auction.endTime == 0 || auction.endTime >= currentTime,
            "Auction already ended."
        );

        uint256 minimum = auction.initialBidAmount;

        if (
            auction.auctionType == AuctionTypes.TRADITIONAL &&
            auction.bids.length > 0
        ) {
            Bid memory lastBid = auction.bids[auction.bids.length - 1];

            uint256 maximumIncrease = uint256(
                auctionWithDefaults.maximumIncrease
            );

            uint256 percentIncrease = (lastBid.amount *
                auctionWithDefaults.percentIncrease) / 100;

            minimum = maximumIncrease > 0 && percentIncrease > maximumIncrease
                ? lastBid.amount + maximumIncrease
                : lastBid.amount + percentIncrease;
        }

        require(msg.value >= minimum, "Incorrect purchase price received");
    }

    function canFinalize(Auction memory auction) internal view {
        require(
            auction.auctionType == AuctionTypes.TRADITIONAL,
            "Auction type does not require finalization"
        );

        require(
            auction.endTime != 0 && auction.endTime <= uint64(block.timestamp),
            "This auction is still active"
        );

        require(
            auction.finalizedTime == 0,
            "Auction has already been finalized"
        );
    }

    function getAuctionDefaults() public pure returns (AuctionDefaults memory) {
        return
            AuctionDefaults({
                duration: 86400,
                extensionPeriod: 900,
                quantity: 1,
                percentIncrease: 10,
                maximumIncrease: 0.1 ether
            });
    }

    function getAuctionWithDefaults(Auction memory auction)
        internal
        pure
        returns (Auction memory)
    {
        AuctionDefaults memory defaults = getAuctionDefaults();

        if (auction.duration == 0) {
            auction.duration = defaults.duration;
        }

        if (auction.extensionPeriod == 0) {
            auction.extensionPeriod = defaults.extensionPeriod;
        }

        if (auction.maximumIncrease == 0) {
            auction.maximumIncrease = defaults.maximumIncrease;
        }

        if (auction.percentIncrease == 0) {
            auction.percentIncrease = defaults.percentIncrease;
        }

        if (auction.quantity == 0) {
            auction.quantity = defaults.quantity;
        }

        return auction;
    }

    function checkBeneficiaries(Beneficiary[] memory beneficiaries)
        internal
        pure
    {
        address monegraphAddress = 0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9;
        bool monegraphFound = false;

        uint16 total = 0;

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            address payable wallet = beneficiaries[i].wallet;

            require(
                wallet != address(0),
                "Black Hole wallet cannot be a beneficiary"
            );

            require(
                beneficiaries[i].percentage > 0,
                "Zero value beneficiary distribution"
            );

            if (wallet == monegraphAddress) {
                monegraphFound = true;
            }

            total += beneficiaries[i].percentage;
        }

        require(
            monegraphFound,
            "OrganizationAuctions: Auction created without Monegraph split defined"
        );

        require(
            total == 10000,
            "OrganizationAuctions: Beneficiary allocation must equal 100%"
        );
    }

    function populateFromParams(
        Auction storage auction,
        CreateAuction calldata params
    ) internal {
        AuctionDefaults memory defaults = getAuctionDefaults();
        uint64 currentTime = uint64(block.timestamp);

        if (params.duration != defaults.duration) {
            auction.duration = params.duration;
        }

        if (params.extensionPeriod != defaults.extensionPeriod) {
            auction.extensionPeriod = params.extensionPeriod;
        }

        if (params.maximumIncrease != defaults.maximumIncrease) {
            auction.maximumIncrease = params.maximumIncrease;
        }

        if (params.percentIncrease != defaults.percentIncrease) {
            auction.percentIncrease = params.percentIncrease;
        }

        if (params.quantity != defaults.quantity) {
            auction.quantity = params.quantity;
        }

        auction.auctionType = params.auctionType;
        auction.initialBidAmount = params.initialBidAmount;

        auction.startTime = params.startTime > 0 &&
            params.startTime > currentTime
            ? params.startTime
            : currentTime;

        if (params.endTime > 0) {
            auction.endTime = params.endTime;
        }
    }

    function getVerificationMessage(address tokenAddress, uint256 tokenId)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(organizationId, msg.sender, tokenId, tokenAddress)
        );

        return hash.toEthSignedMessageHash();
    }

    function createAuction(
        address tokenAddress,
        uint256 tokenId,
        CreateAuction calldata params,
        bytes calldata signature
    ) external {
        uint256 auctionId = auctionIds.current();

        Auction storage auction = auctions[auctionId];

        address from = getVerificationMessage(tokenAddress, tokenId).recover(
            signature
        );

        require(from == getForwarder(), "Validation Failed");

        require(
            params.endTime == 0 || params.endTime > uint64(block.timestamp),
            "Auction end time set in the past"
        );

        checkBeneficiaries(params.beneficiaries);

        populateFromParams(auction, params);

        for (uint256 i = 0; i < params.beneficiaries.length; i++) {
            auction.beneficiaries.push(params.beneficiaries[i]);
        }

        emit AuctionCreated(
            auctionId,
            getAuctionWithDefaults(auction),
            params.metadata
        );

        auctionIds.increment();
    }

    function traditionalBid(Auction storage auction) internal {
        Auction memory auctionWithDefaults = getAuctionWithDefaults(auction);
        uint64 currentTime = uint64(block.timestamp);

        if (auctionWithDefaults.quantity > 1) {
            if (auction.bids.length >= auctionWithDefaults.quantity) {
                Bid storage refundedBid = auction.bids[
                    auction.bids.length - auctionWithDefaults.quantity
                ];

                if (refundedBid.refunded == false && refundedBid.amount > 0) {
                    refundedBid.refunded = true;

                    address payable refundee = payable(refundedBid.bidder);

                    (bool success, ) = refundee.call{
                        value: refundedBid.amount,
                        gas: 20000
                    }("");

                    auction.treasury -= refundedBid.amount;

                    if (!success) {
                        payable(0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9)
                            .transfer(refundedBid.amount);
                    }
                }
            }
        } else {
            if (auction.bids.length > 0) {
                Bid storage lastBid = auction.bids[auction.bids.length - 1];

                lastBid.refunded = true;

                address payable refundee = payable(lastBid.bidder);

                (bool success, ) = refundee.call{
                    value: lastBid.amount,
                    gas: 20000
                }("");

                auction.treasury -= lastBid.amount;

                if (!success) {
                    payable(0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9)
                        .transfer(lastBid.amount);
                }
            }
        }

        if (auction.endTime == 0) {
            auction.endTime = currentTime + auctionWithDefaults.duration;
        }

        auction.bids.push(
            Bid({
                bidder: msg.sender,
                amount: msg.value,
                timestamp: uint64(block.timestamp),
                refunded: false
            })
        );

        auction.treasury += msg.value;

        if (
            currentTime + auctionWithDefaults.extensionPeriod > auction.endTime
        ) {
            auction.endTime = currentTime + auctionWithDefaults.extensionPeriod;
        }
    }

    function buyNowBid(Auction storage auction) internal {
        Auction memory auctionWithDefaults = getAuctionWithDefaults(auction);

        auction.bids.push(
            Bid({
                bidder: msg.sender,
                amount: msg.value,
                timestamp: uint64(block.timestamp),
                refunded: false
            })
        );

        if (auction.bids.length == auctionWithDefaults.quantity) {
            uint64 currentTime = uint64(block.timestamp);

            auction.endTime = currentTime - 1;
            auction.finalizedTime = currentTime - 1;
        }

        disperse(msg.value, auction.beneficiaries);
    }

    function disperse(uint256 total, Beneficiary[] memory beneficiaries)
        internal
    {
        for (uint256 i = 0; i < beneficiaries.length; i++) {
            Beneficiary memory beneficiary = beneficiaries[i];

            uint256 amount = (total / 10000) * beneficiary.percentage;

            (bool success, ) = beneficiary.wallet.call{
                value: amount,
                gas: 20000
            }("");

            if (!success) {
                emit WithdrawlFallback(total, beneficiary.wallet);

                payable(0xF82d31541fE4F96dfeE2A2C306f70086D91d67c9).transfer(
                    amount
                );
            }
        }
    }

    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];

        canBid(auction);

        if (auction.auctionType == AuctionTypes.TRADITIONAL) {
            traditionalBid(auction);
        } else {
            buyNowBid(auction);
        }

        emit BidReceived(auctionId, auction.endTime);

        if (auction.finalizedTime > 0) {
            emit AuctionFinalized(auctionId);
        }
    }

    function close(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        uint64 currentTime = uint64(block.timestamp);

        require(auction.bids.length == 0, "Auction has bids");

        auction.endTime = currentTime - 1;
        auction.finalizedTime = currentTime - 1;

        emit AuctionClosed(auctionId);
    }

    function finalize(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];

        canFinalize(auction);

        auction.finalizedTime = uint64(block.timestamp);

        require(
            auction.treasury > 0,
            "Auction had no bids and can not be finalized"
        );

        disperse(auction.treasury, auction.beneficiaries);

        emit AuctionFinalized(auctionId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
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

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}