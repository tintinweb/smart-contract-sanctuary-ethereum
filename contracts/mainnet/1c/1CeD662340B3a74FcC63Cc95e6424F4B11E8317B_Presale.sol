// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
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
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IAggregatorV3} from "./interfaces/IAggregatorV3.sol";

/*//////////////////////////////////////////////////////////////
                          ERRORS
//////////////////////////////////////////////////////////////*/

error SaleOngoing(uint256 current, uint256 ends);
error SaleNotStarted(uint256 current, uint256 start);
error SaleEnded(uint256 current, uint256 ends);
error InvalidProof();
error AlreadyInitialised();
error NotInitialised();
error AlreadyClaimed();
error ClaimsNotOpen();
error PaymentCalcUnderflow();
error NotPaymentToken();
error ModularError(uint120 by, uint120 remainder);
error ZeroAddress();
error ZeroAmount();
error MoreThanBalance();
error NoAccess();

/*//////////////////////////////////////////////////////////////
                          INTERFACES
//////////////////////////////////////////////////////////////*/

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

interface IPresale {
    event PresaleInit(address indexed token, address indexed priceFeed, address indexed admin, address treasury);
    event Initialised(uint40 start, uint40 duration, uint256 price);
    event ClaimRootSet(bytes32 indexed root);
    event BuyOrder(address indexed buyer, address indexed paymentToken, uint256 payment, uint256 tokens);
    event Claim(
        address indexed buyer,
        uint256 filledTokens,
        uint256 unusedUsdc,
        uint256 unusedUsdt,
        uint256 unusedDai,
        uint256 unusedEth
    );
    event PriceFeedUpdate(address indexed priceFeed);
    event BuyOrderEth(address indexed buyer, int256 priceOfEth, uint256 amountOfEth, uint256 tokens);
    event AdminUpdate(address indexed admin);
    event TreasuryUpdate(address indexed treasury);
    event ClaimStatus(bool claimStatus);
    event DurationUpdate(uint40 duration);
    event PriceUpdate(uint256 price);
}

/// @title Presale
/// @author DeGatchi (https://github.com/DeGatchi)
/// @author 0xHessian (https://github.com/0xHessian)
/// @author 7811 (https://github.com/cranium7811)
contract Presale is IPresale, Ownable {
    /*//////////////////////////////////////////////////////////////
                                STATE
    //////////////////////////////////////////////////////////////*/

    /// Whether the contract's variables have been set.
    bool public initialised;
    // check the status of claim
    // 0 - false - not ready
    // 1 - true - ready
    bool public claimStatus;
    // address of the admin
    address public admin;
    // address of the treasury
    address public immutable treasury;

    /// Tokens being used as payment
    address public immutable dai;
    address public immutable usdt;
    address public immutable usdc;
    /// Token being sold
    IERC20 public immutable token;
    // Chainlink Aggregator interface
    IAggregatorV3 public priceFeed;

    /// When the sale begins.
    uint40 public start;
    /// How long the sale goes for.
    uint40 public duration;
    /// Total amount of tokens ordered.
    uint120 public supplyOrdered;
    /// Price per token
    uint256 public price;

    /// Root used to set the claim statistics.
    bytes32 public claimRoot;

    struct Receipt {
        uint120 dai; // Total DAI used as payment (18 decimals).
        uint120 usdt; // Total USDT used as payment (6 decimals).
        uint120 usdc; // Total USDC used as payment (6 decimals).
        uint120 eth; // Total ETH used as payment (18 decimals).
        uint120 tokens; // Total presale tokens ordered.
        bool claimed; // Whether the order has been claimed.
    }

    /// A record of EOAs and their corresponding order receipts.
    mapping(address => Receipt) public receipt;

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// Enable use when contract has initialised.
    modifier onlyInit() {
        if (!initialised) revert NotInitialised();
        _;
    }

    /// Enable use when the sale has finished.
    modifier onlyEnd() {
        if (block.timestamp < start + duration) {
            revert SaleOngoing(block.timestamp, start + duration);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZE
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets up the contract addresses as immutable for gas saving.
    /// @param _dai ERC20 USDC token being used as payment (has 18 decimals).
    /// @param _usdt ERC20 USDC token being used as payment (has 6 decimals).
    /// @param _usdc ERC20 USDC token being used as payment (has 6 decimals).
    /// @param _token ERC20 token being sold for `_usdc`.
    /// @param _admin address of the admin
    /// @param _treasury address of the treasury
    constructor(
        address _dai,
        address _usdt,
        address _usdc,
        address _token,
        address _priceFeed,
        address _admin,
        address _treasury
    ) {
        dai = _dai;
        usdt = _usdt;
        usdc = _usdc;
        token = IERC20(_token);
        priceFeed = IAggregatorV3(_priceFeed);
        admin = _admin;
        treasury = _treasury;

        emit PresaleInit(_token, _priceFeed, _admin, _treasury);
    }

    /// @notice Sets up the sale.
    /// @dev Requires the initialiser to send `_supply` of `_token` to this address.
    /// @param _start Timestamp of when the sale begins.
    /// @param _duration How long the sale goes for.
    /// @param _price The `_usdc` payment value of each `_token`.
    function initialise(uint40 _start, uint40 _duration, uint256 _price) external onlyOwner {
        if (initialised) revert AlreadyInitialised();

        initialised = true;
        start = _start;
        duration = _duration;
        price = _price;

        emit Initialised(_start, _duration, _price);
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows owner to update the claim root to enable `claim()`.
    /// @dev Used to update the `claimRoot` to enable claiming.
    /// @param _newRoot Merkle root used after sale has ended to allow buyers to claim their tokens.
    function setClaimRoot(bytes32 _newRoot) public onlyOwner onlyEnd {
        if (block.timestamp < start) {
            revert SaleNotStarted(block.timestamp, start);
        }
        claimRoot = _newRoot;
        emit ClaimRootSet(_newRoot);
    }

    /// @notice allows the owner to set the priceFeed contract's address
    /// @param _priceFeed address of the new priceFeed contract
    function setPriceFeed(address _priceFeed) external {
        if (msg.sender != admin) revert NoAccess();
        if (_priceFeed == address(0)) revert ZeroAddress();
        priceFeed = IAggregatorV3(_priceFeed);
        emit PriceFeedUpdate(_priceFeed);
    }

    /// @notice allows the owner to set the address of `admin`
    /// @param _admin address of the `admin`
    function setAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert ZeroAddress();
        admin = _admin;
        emit AdminUpdate(_admin);
    }

    /// @notice allows the admin to set the claim status
    /// @param _claimStatus status of the claim, 0 - not ready, 1 - ready
    function setClaimStatus(bool _claimStatus) external {
        if (msg.sender != admin) revert NoAccess();
        claimStatus = _claimStatus;
        emit ClaimStatus(_claimStatus);
    }

    /// @notice allows the admin to set the duration of the sale
    /// @param _duration duration of the ongoing sale
    function setDuration(uint40 _duration) external {
        if (msg.sender != admin) revert NoAccess();
        duration = _duration;
        emit DurationUpdate(_duration);
    }

    /*//////////////////////////////////////////////////////////////
                            CREATE BUY ORDERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows users to create an order to purchase presale tokens usdc, usdt or dai.
    /// @dev The buy event is used for the backend bot to determine the orders.
    /// @param _purchaseAmount Amount of usd value in the ERC20 token's decimal units
    /// @param _paymentToken Token paying with.
    function createBuyOrder(uint256 _purchaseAmount, address _paymentToken) external onlyInit {
        // Add a revert if purchaseAmount is less than 1
        if (_purchaseAmount < 1) revert ZeroAmount();

        uint40 _start = start;
        if (block.timestamp < _start) {
            revert SaleNotStarted(block.timestamp, _start);
        }
        if (block.timestamp >= _start + duration) {
            revert SaleEnded(block.timestamp, _start + duration);
        }

        Receipt storage _receipt = receipt[msg.sender];
        uint256 _tokens;
        if (_paymentToken == dai) {
            _tokens = (_purchaseAmount * 1e6) / price;
            _receipt.dai += uint120(_purchaseAmount);
        } else {
            _tokens = (_purchaseAmount * 1e18) / price;
            if (_paymentToken == usdc) _receipt.usdc += uint120(_purchaseAmount);
            else if (_paymentToken == usdt) _receipt.usdt += uint120(_purchaseAmount);
            else revert NotPaymentToken();
        }

        _receipt.tokens += uint120(_tokens);
        supplyOrdered += uint120(_tokens);
        IERC20(_paymentToken).transferFrom(msg.sender, treasury, _purchaseAmount);

        emit BuyOrder(msg.sender, _paymentToken, _purchaseAmount, _tokens);
    }

    /// @notice Allows users to create an order to purchase presale tokens w/ ETH.
    /// @dev The buy event is used for the backend bot to determine the orders.
    function createBuyOrderEth() external payable onlyInit {
        if (msg.value < 1) revert ZeroAmount();

        // Make sure the sale is ongoing.
        uint40 _start = start;
        if (block.timestamp < _start) revert SaleNotStarted(block.timestamp, _start);
        if (block.timestamp >= _start + duration) revert SaleEnded(block.timestamp, _start + duration);

        int256 _ethPrice = _getLatestPrice();
        uint256 _tokens = (uint256(_ethPrice) * msg.value) / (price * 1e2);
        Receipt storage _receipt = receipt[msg.sender];

        _receipt.eth += uint120(msg.value);
        _receipt.tokens += uint120(_tokens);
        supplyOrdered += uint120(_tokens);

        payable(treasury).transfer(msg.value);

        emit BuyOrderEth(msg.sender, _ethPrice, msg.value, _tokens);
    }

    /*//////////////////////////////////////////////////////////////
                            CLAIM AND TRANSFER
    //////////////////////////////////////////////////////////////*/

    /// @notice When sale ends, users can redeem their allocation w/ the filler bot's output.
    /// @dev Set owner as the treasury claimer to receive all used USDC + unsold tokens.
    ///      E.g, 90/100 tokens sold for 45 usdc paid; owner claims 10 tokens + 45 USDC.
    /// @param _claimer The EOA claiming on behalf for by the caller.
    /// @param _filledTokens Total presale tokens being sent to `_claimer`.
    /// @param _unusedUsdc Total USDC amount, that weren't used to buy `token`, being sent to `_claimer`.
    /// @param _unusedUsdt Total USDT amount, that weren't used to buy `token`, being sent to `_claimer`.
    /// @param _unusedDai Total DAI amount, that weren't used to buy `token`, being sent to `_claimer`.
    /// @param _unusedDai Total ETH amount, that weren't used to buy `token`, being sent to `_claimer`.
    /// @param _proof Merkle tree verification path.
    function claim(
        address _claimer,
        uint120 _filledTokens,
        uint120 _unusedUsdc,
        uint120 _unusedUsdt,
        uint120 _unusedDai,
        uint120 _unusedEth,
        bytes32[] memory _proof
    ) external onlyInit onlyEnd {
        if (claimRoot == bytes32(0)) revert ClaimsNotOpen();
        if (!claimStatus) revert ClaimsNotOpen();

        Receipt storage _receipt = receipt[_claimer];
        if (_receipt.claimed) revert AlreadyClaimed();

        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(abi.encode(_claimer, _filledTokens, _unusedUsdc, _unusedUsdt, _unusedDai, _unusedEth))
            )
        );
        if (!MerkleProof.verify(_proof, claimRoot, leaf)) revert InvalidProof();

        _receipt.claimed = true;

        if (_filledTokens > 0) token.transfer(_claimer, _filledTokens);
        if (_unusedUsdc > 0) IERC20(usdc).transfer(_claimer, _unusedUsdc);
        if (_unusedUsdt > 0) IERC20(usdt).transfer(_claimer, _unusedUsdt);
        if (_unusedDai > 0) IERC20(dai).transfer(_claimer, _unusedDai);
        if (_unusedEth > 0) payable(_claimer).transfer(_unusedEth);

        emit Claim(_claimer, _filledTokens, _unusedUsdc, _unusedUsdt, _unusedDai, _unusedEth);
    }

    /// @notice transfers the tokens and the remaining stablecoin/ETH tokens after filling the order
    /// @dev can be only called by the `admin`
    /// @param _buyer addresses of all the buyers
    /// @param _filledTokens amount of all the allocated tokens per address
    /// @param _unusedUsdc total remaining usdc which was not used when filling the order
    /// @param _unusedUsdt total remaining usdt which was not used when filling the order
    /// @param _unusedDai total remaining dai which was not used when filling the order
    /// @param _unusedEth total remaining eth which was not used when filling the order
    function transferTokens(
        address[] calldata _buyer,
        uint120[] calldata _filledTokens,
        uint120[] calldata _unusedUsdc,
        uint120[] calldata _unusedUsdt,
        uint120[] calldata _unusedDai,
        uint120[] calldata _unusedEth
    ) external {
        if (msg.sender != admin) revert NoAccess();
        if (!claimStatus) revert ClaimsNotOpen();

        uint256 length = _buyer.length;
        if (
            (_filledTokens.length != length) || (_unusedUsdc.length != length) || (_unusedUsdt.length != length)
                || (_unusedDai.length != length) || (_unusedEth.length != length)
        ) revert NoAccess();

        for (uint256 i; i < _buyer.length;) {
            transferTokensWithoutProof(
                _buyer[i], _filledTokens[i], _unusedUsdc[i], _unusedUsdt[i], _unusedDai[i], _unusedEth[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    /// @notice transfers the tokens and the remaining stablecoin/ETH tokens after filling the order
    /// @dev can be only called by the `admin`
    /// @param _buyer address of the buyer/claimer
    /// @param _filledTokens amount of tokens which we transfer when filling the order per buyer
    /// @param _unusedUsdc total remaining usdc which was not used when filling the order per buyer
    /// @param _unusedUsdt total remaining usdt which was not used when filling the order per buyer
    /// @param _unusedDai total remaining dai which was not used when filling the order per buyer
    /// @param _unusedEth total remaining eth which was not used when filling the order per buyer
    function transferTokensWithoutProof(
        address _buyer,
        uint120 _filledTokens,
        uint120 _unusedUsdc,
        uint120 _unusedUsdt,
        uint120 _unusedDai,
        uint120 _unusedEth
    ) public {
        if (msg.sender != admin) revert NoAccess();
        if (!claimStatus) revert ClaimsNotOpen();

        Receipt storage _receipt = receipt[_buyer];
        if (_receipt.claimed) revert AlreadyClaimed();
        _receipt.claimed = true;

        if (_filledTokens > 0) token.transfer(_buyer, _filledTokens);
        if (_unusedUsdc > 0) IERC20(usdc).transfer(_buyer, _unusedUsdc);
        if (_unusedUsdt > 0) IERC20(usdt).transfer(_buyer, _unusedUsdt);
        if (_unusedDai > 0) IERC20(dai).transfer(_buyer, _unusedDai);
        if (_unusedEth > 0) payable(_buyer).transfer(_unusedEth);
    }

    /*//////////////////////////////////////////////////////////////
                          WITHDRAW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraw any amount(less than the balance) of an ERC20 token from this contract to a receiver
    /// @dev can only be called by the owner
    /// @param _token address of the ERC20 token to be withdrawn
    /// @param _amount the amount of tokens to be withdrawn
    function withdraw(address _token, uint120 _amount) external onlyOwner {
        // check if the balance is more than the amount
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        if (uint256(_amount) > _balance) revert MoreThanBalance();

        // transfer the `ERC20` token
        IERC20(_token).transfer(treasury, _amount);
    }

    /// @notice withdraw any amount (less than the balance) of ETH from this contract to a receiver
    /// @dev can only be called by the owner
    /// @param _amount the amount of ETH to be withdrawn
    function withdrawEth(uint120 _amount) external onlyOwner {
        // check if the balance is more than the amount
        uint256 _balance = address(this).balance;
        if (uint256(_amount) > _balance) revert MoreThanBalance();

        // transfer the eth
        payable(treasury).transfer(_amount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice get the latest price for eth from Chainlink's Aggregator PriceFeed
    function _getLatestPrice() internal view returns (int256) {
        (, int256 _price,,,) = priceFeed.latestRoundData();
        return _price;
    }

    /*//////////////////////////////////////////////////////////////
                            FALLBACK
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}
}