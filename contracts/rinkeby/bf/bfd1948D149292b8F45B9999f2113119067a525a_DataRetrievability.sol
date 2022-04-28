// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

/**
 * @title DataRetrievability
 */
contract DataRetrievability is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Defining provider struct
    struct Referee {
        bool active;
        string endpoint;
    }

    // Defining provider struct
    struct Provider {
        bool active;
        string endpoint;
    }

    // Defining deal struct
    struct Deal {
        // Hash subject of the deal
        string ipfs_hash;
        // Timestamp request
        uint256 timestamp_request;
        // Starting timestamp
        uint256 timestamp_start;
        // Duration of deal expressed in seconds
        uint256 duration;
        // Amount in wei paid for the deal
        uint256 value;
        // Amount in wei needed to accept the deal
        uint256 collateral;
        // Address of provider
        mapping(address => bool) providers;
        // Store provider who accepted the deal
        address accepted;
        // Address of owner
        address owner;
        // Describe if deal is active or not
        bool active;
        // Describe if deal is canceled or not
        bool canceled;
    }

    // Defining appeal struct
    struct Appeal {
        // Index object of the deal
        uint256 deal_index;
        // Describe if appeal is active or not
        bool active;
        // Mapping that stores what rounds were processed
        mapping(uint256 => bool) processed;
        // Counter for slashes
        uint128 slashes;
        // Adding block timestamp to calculate timeout
        uint256 origin_timestamp;
    }

    // Mapping referees addresses
    mapping(address => Referee) public referees;
    // Mapping referees providers
    mapping(address => Provider) public providers;
    // Mapping deals
    mapping(uint256 => Deal) public deals;
    // Mapping appeals
    mapping(uint256 => Appeal) public appeals;
    // Mapping active appeals using IPFS hash as index
    mapping(string => uint256) public active_appeals;
    // Referee, Providers and Clients vault
    mapping(address => uint256) public vault;
    // Array of active referees
    address[] public active_referees;
    // Array of active providers
    address[] public active_providers;
    // Protocol address
    address protocol_address;
    // Multipliers
    uint256 public deposit_multiplier = 100;
    uint256 public slashing_multiplier = 10;
    // Timeout to accept a deal (1 week)
    uint32 deal_timeout = 86_400;
    // Internal counters for deals and appeals mapping
    Counters.Counter private dealCounter;
    Counters.Counter private appealCounter;
    // Round parameters
    uint32 public round_duration = 300;
    uint32 public min_duration = 3600;
    uint32 public max_duration = 43_200;
    // Event emitted when new deal is created
    event DealProposalCreated(
        uint256 index,
        address[] providers,
        string ipfs_hash
    );
    // Event emitted when a deal is accepted
    event DealProposalAccepted(uint256 index);
    // Event emitted when a deal is rejected
    event DealRejected(uint256 index);
    // Event emitted when a deal is canceled before end
    event DealProposalCanceled(uint256 index);
    // Event emitted when a deal is redeemed
    event DealRedeemed(uint256 index);
    // Event emitted when a deal is invalidated
    event DealInvalidated(uint256 index);
    // Event emitted when new appeal is created
    event AppealCreated(uint256 index, address provider, string ipfs_hash);
    // Event emitted when a slash message is recorded
    event AppealSlashed(uint256 index);

    constructor(address _protocol_address) {
        protocol_address = _protocol_address;
    }

    function totalDeals() public view returns (uint256) {
        return dealCounter.current();
    }

    /*
        This method verifies a signature
    */
    function verifyRefereeSignature(
        bytes memory _signature,
        uint256 deal_index,
        address referee
    ) public view returns (bool) {
        require(referees[referee].active, "Provided address is not a referee");
        bytes memory message = getPrefix(deal_index);
        bytes32 hashed = ECDSA.toEthSignedMessageHash(message);
        address recovered = ECDSA.recover(hashed, _signature);
        return recovered == referee;
    }

    /*
        This method returns the prefix for
    */
    function getPrefix(uint256 appeal_index)
        public
        view
        returns (bytes memory)
    {
        uint256 deal_index = appeals[appeal_index].deal_index;
        uint256 round = getRound(appeal_index);
        return
            abi.encodePacked(
                Strings.toString(deal_index),
                Strings.toString(appeal_index),
                Strings.toString(round)
            );
    }

    /*
        This method will return the amount of slashes needed to close the appeal
    */
    function returnSlashesThreshold() public pure returns (uint8) {
        return 12;
    }

    /*
        This method will return the amount of rounds needed to positive timeout
    */
    function returnRoundsLimit() public pure returns (uint8) {
        return 12;
    }

    /*
        This method will return the amount in ETH needed to create an appeal
    */
    function returnAppealFee(uint256 deal_index) public view returns (uint256) {
        // QUESTION: How we calculate the amount needed?
        uint256 fee = deals[deal_index].value * 2;
        return fee;
    }

    /*
        This method will return the amount of signatures needed to close a rount
    */
    function refereeConsensusThreshold() public view returns (uint256) {
        // QUESTION: Provide the exact way to count the number for consensus
        uint256 half = (active_referees.length * 100) / 2;
        return half;
    }

    /*
        This method will return the leader for a provided appeal
    */
    function getElectedLeader(uint256 appeal_index)
        public
        view
        returns (address)
    {
        uint256 round = getRound(appeal_index);
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    appeals[appeal_index].origin_timestamp +
                        appeal_index +
                        round
                )
            )
        );
        uint256 leader = (seed -
            ((seed / active_referees.length) * active_referees.length));
        return active_referees[leader];
    }

    /*
        This method will return the round for provided appeal
    */
    function getRound(uint256 appeal_index) public view returns (uint256) {
        uint256 appeal_duration = round_duration * returnRoundsLimit();
        uint256 appeal_end = appeals[appeal_index].origin_timestamp +
            appeal_duration;
        if (appeal_end >= block.timestamp) {
            uint256 remaining_time = appeal_end - block.timestamp;
            uint256 remaining_rounds = remaining_time / round_duration;
            uint256 round = returnRoundsLimit() - remaining_rounds;
            return round;
        } else {
            // Means appeal is ended
            return 99;
        }
    }

    /*
        This method will say if address is a referee or not
    */
    function isReferee(address check) public view returns (bool) {
        // This may change if we use NFTs
        return referees[check].active == true;
    }

    /*
        This method will say if address is a provider or not
    */
    function isProvider(address check) public view returns (bool) {
        // This may change if we use NFT
        // QUESTION: Should we check here if there's enough balance?
        return providers[check].active == true;
    }

    /*
        This method will allow owner to enable or disable a referee
    */
    function setRefereeStatus(
        address _referee,
        bool _state,
        string memory _endpoint
    ) external onlyOwner {
        referees[_referee].active = _state;
        referees[_referee].endpoint = _endpoint;
        if (_state) {
            active_referees.push(_referee);
        } else {
            for (uint256 i = 0; i < active_referees.length; i++) {
                if (active_referees[i] == _referee) {
                    delete active_referees[i];
                }
            }
        }
    }

    /*
        This method will allow owner to enable or disable a provider
    */
    function setProviderStatus(
        address _provider,
        bool _state,
        string memory _endpoint
    ) external onlyOwner {
        providers[_provider].active = _state;
        providers[_provider].endpoint = _endpoint;
        if (_state) {
            active_providers.push(_provider);
        } else {
            for (uint256 i = 0; i < active_providers.length; i++) {
                if (active_providers[i] == _provider) {
                    delete active_providers[i];
                }
            }
        }
    }

    /*
        This method will allow client to create a deal
    */
    function createDealProposal(
        string memory _ipfs_hash,
        uint256 duration,
        uint256 collateral,
        address[] memory _providers
    ) external payable nonReentrant {
        require(
            duration >= min_duration && duration <= max_duration,
            "Duration is out allowed range"
        );
        uint256 maximum_collateral = slashing_multiplier * msg.value;
        require(
            collateral >= msg.value && collateral <= maximum_collateral,
            "Collateral out of range"
        );
        // Creating next id
        dealCounter.increment();
        uint256 index = dealCounter.current();
        // Creating the deal mapping
        deals[index].timestamp_request = block.timestamp;
        deals[index].owner = msg.sender;
        deals[index].active = true;
        deals[index].ipfs_hash = _ipfs_hash;
        deals[index].duration = duration;
        deals[index].collateral = collateral;
        deals[index].value = msg.value;
        // Check if provided providers are active and store in struct
        for (uint256 i = 0; i < _providers.length; i++) {
            require(
                isProvider(_providers[i]),
                "Requested provider is not active"
            );
            deals[index].providers[_providers[i]] = true;
        }
        // When created the amount of money is owned by sender
        vault[address(this)] += msg.value;
        // Emit event
        emit DealProposalCreated(index, _providers, _ipfs_hash);
    }

    /*
        This method will allow client to cancel deal if not accepted
    */
    function cancelDealProposal(uint256 deal_index) external nonReentrant {
        require(
            deals[deal_index].owner == msg.sender,
            "Only owner can cancel the deal"
        );
        require(!deals[deal_index].canceled, "Deal canceled yet");
        require(
            deals[deal_index].accepted == address(0),
            "Deal was accepted, can't cancel"
        );
        deals[deal_index].canceled = true;
        deals[deal_index].active = false;
        // Remove funds from internal vault giving back to user
        // user will be able to withdraw funds later
        vault[address(this)] -= deals[deal_index].value;
        vault[msg.sender] += deals[deal_index].value;
        emit DealProposalCanceled(deal_index);
    }

    /*
        This method will return provider status in deal
    */
    function isProviderInDeal(uint256 deal_index, address provider)
        external
        view
        returns (bool)
    {
        return deals[deal_index].providers[provider];
    }

    /*
        This method will allow a provider to accept a deal
    */
    function acceptDealProposal(uint256 deal_index) external nonReentrant {
        uint256 timeout = deals[deal_index].timestamp_request + deal_timeout;
        require(
            block.timestamp < timeout,
            "Deal expired, can't accept anymore"
        );
        require(
            deals[deal_index].providers[msg.sender],
            "Only selected providers can accept deal"
        );
        require(
            deals[deal_index].accepted == address(0),
            "Deal proposal was accepted yet"
        );
        uint256 deposit_margin = deals[deal_index].value * deposit_multiplier;
        require(
            vault[msg.sender] >= deals[deal_index].collateral &&
                vault[msg.sender] >= deposit_margin,
            "Can't accept because you don't have enough balance in contract"
        );
        deals[deal_index].active = true;
        deals[deal_index].accepted = msg.sender;
        deals[deal_index].timestamp_start = block.timestamp;
        // Deposit collateral to contract
        vault[msg.sender] -= deals[deal_index].collateral;
        vault[address(this)] += deals[deal_index].collateral;
        emit DealProposalAccepted(deal_index);
    }

    /*
        This method will allow provider to withdraw funds for deal
    */
    function redeemDeal(uint256 deal_index) external nonReentrant {
        require(
            deals[deal_index].accepted == msg.sender,
            "Only provider can redeem"
        );
        require(deals[deal_index].active, "Deal is not active");
        uint256 timeout = deals[deal_index].timestamp_start +
            deals[deal_index].duration;
        require(block.timestamp > timeout, "Deal didn't ended, can't redeem");
        require(
            getRound(active_appeals[deals[deal_index].ipfs_hash]) == 99,
            "Found an active appeal, can't redeem"
        );
        // QUESTION: How we detect the amount of value sent to provider
        // do it with parameters counting the total appeals and setting
        // a threshold to do remove the value.

        // Move value from contract to address
        vault[address(this)] -= deals[deal_index].value;
        vault[msg.sender] += deals[deal_index].value;

        // Giving back collateral to provider
        vault[address(this)] -= deals[deal_index].collateral;
        vault[msg.sender] += deals[deal_index].collateral;
        // Close the deal
        deals[deal_index].active = false;
        emit DealRedeemed(deal_index);
    }

    /*
        This method will allow referees to create an appeal
    */
    function createAppeal(uint256 deal_index) external payable nonReentrant {
        require(deals[deal_index].active, "Deal is not active");
        uint256 timeout = deals[deal_index].timestamp_start +
            deals[deal_index].duration;
        require(block.timestamp < timeout, "Deal ended, can't create appeals");
        require(
            deals[deal_index].owner == msg.sender,
            "Only owner can create appeal"
        );
        // Check if appeal exists or is expired
        require(
            active_appeals[deals[deal_index].ipfs_hash] == 0 ||
                // Check if appeal is expired
                getRound(active_appeals[deals[deal_index].ipfs_hash]) == 99,
            "Appeal exists yet for provided hash"
        );
        // Be sure sent amount is exactly the appeal fee
        require(
            msg.value == returnAppealFee(deal_index),
            "Must send exact fee to create an appeal"
        );
        // Sending fee to referees
        uint256 fee = msg.value / active_referees.length;
        for (uint256 i = 0; i < active_referees.length; i++) {
            vault[active_referees[i]] += fee;
        }
        // Creating next id
        appealCounter.increment();
        uint256 index = appealCounter.current();
        // Storing appeal status
        active_appeals[deals[deal_index].ipfs_hash] = index;
        // Creating appeal
        appeals[index].deal_index = deal_index;
        appeals[index].active = true;
        appeals[index].origin_timestamp = block.timestamp;
        // Emit appeal created event
        emit AppealCreated(
            index,
            deals[deal_index].accepted,
            deals[deal_index].ipfs_hash
        );
    }

    /*
        This method will allow referees to process an appeal
    */
    function processAppeal(
        uint256 deal_index,
        address[] memory _referees,
        bytes[] memory _signatures
    ) external {
        uint256 appeal_index = active_appeals[deals[deal_index].ipfs_hash];
        uint256 round = getRound(appeal_index);
        require(deals[deal_index].active, "Deal is not active");
        require(appeals[appeal_index].active, "Appeal is not active");
        require(
            referees[msg.sender].active,
            "Only referees can process appeals"
        );
        require(
            round <= returnRoundsLimit(),
            "This appeal can't be processed anymore"
        );
        require(
            !appeals[appeal_index].processed[round],
            "This round was processed yet"
        );
        appeals[appeal_index].processed[round] = true;
        bool slashed = false;
        if (getElectedLeader(appeal_index) == msg.sender) {
            appeals[appeal_index].slashes++;
            slashed = true;
        } else {
            for (uint256 i = 0; i < _referees.length; i++) {
                address referee = _referees[i];
                bytes memory signature = _signatures[i];
                // Be sure leader is not hacking the system
                require(
                    verifyRefereeSignature(signature, deal_index, referee),
                    "Signature doesn't matches"
                );
            }
            if (_signatures.length > refereeConsensusThreshold()) {
                appeals[appeal_index].slashes++;
                slashed = true;
            }
        }
        require(
            slashed,
            "Appeal wasn't slashed, not the leader or no consensus"
        );
        emit AppealSlashed(appeal_index);
        if (appeals[appeal_index].slashes >= returnSlashesThreshold()) {
            deals[deal_index].active = false;
            appeals[appeal_index].active = false;
            // Return value of deal back to owner
            vault[address(this)] -= deals[deal_index].value;
            vault[deals[deal_index].owner] += deals[deal_index].value;
            // Remove funds from provider and charge provider
            uint256 collateral = deals[deal_index].collateral;
            vault[address(this)] -= collateral;
            vault[protocol_address] += collateral;
            // Emit event of deal invalidated
            emit DealInvalidated(deal_index);
        }
    }

    /*
        This method will allow provider deposit ETH in order to accept deals
    */
    function depositToVault() external payable nonReentrant {
        require(
            isProvider(msg.sender),
            "Only providers can deposit into contract"
        );
        require(msg.value > 0, "Must send some value");
        vault[msg.sender] += msg.value;
    }

    /*
        This method will allow to withdraw ethers from contract
    */
    function withdrawFromVault(uint256 amount) external nonReentrant {
        uint256 balance = vault[msg.sender];
        require(balance >= amount, "Not enough balance to withdraw");
        bool success;
        (success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw to user failed");
        vault[msg.sender] -= amount;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
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