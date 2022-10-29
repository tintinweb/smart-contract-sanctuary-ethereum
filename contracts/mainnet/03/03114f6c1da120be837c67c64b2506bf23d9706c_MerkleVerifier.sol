/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/IPolicyManager.sol


pragma solidity 0.8.17;

interface IPolicyManager {
    function addPolicy(address policy) external;

    function removePolicy(address policy) external;

    function isPolicyWhitelisted(address policy) external view returns (bool);

    function viewWhitelistedPolicies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedPolicies() external view returns (uint256);
}
// File: contracts/lib/MerkleVerifier.sol


pragma solidity 0.8.17;

/**
 * @title MerkleVerifier
 * @dev Utility functions for Merkle tree computations
 */
library MerkleVerifier {
    error InvalidProof();

    /**
     * @dev Verify the merkle proof
     * @param leaf leaf
     * @param root root
     * @param proof proof
     */
    function _verifyProof(
        bytes32 leaf,
        bytes32 root,
        bytes32[] memory proof
    ) public pure {
        bytes32 computedRoot = _computeRoot(leaf, proof);
        if (computedRoot != root) {
            revert InvalidProof();
        }
    }

    /**
     * @dev Compute the merkle root
     * @param leaf leaf
     * @param proof proof
     */
    function _computeRoot(
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            computedHash = _hashPair(computedHash, proofElement);
        }
        return computedHash;
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(
        bytes32 a,
        bytes32 b
    ) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
// File: contracts/lib/OrderStructs.sol


pragma solidity 0.8.17;

enum Side { Buy, Sell }
enum SignatureVersion { Single, Bulk }
enum AssetType { ERC721, ERC1155 }

struct Fee {
    uint16 rate;
    address payable recipient;
}

struct Order {
    address trader;
    Side side;
    address matchingPolicy;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address paymentToken;
    uint256 price;
    uint256 listingTime;
    /* Order expiration timestamp - 0 for oracle cancellations. */
    uint256 expirationTime;
    Fee[] fees;
    uint256 salt;
    bytes extraParams;
}

struct Input {
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes extraSignature;
    SignatureVersion signatureVersion;
    uint256 blockNumber;
}
// File: contracts/interfaces/IMatchingPolicy.sol


pragma solidity 0.8.17;


interface IMatchingPolicy {
    function canMatchMakerAsk(Order calldata makerAsk, Order calldata takerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        );

    function canMatchMakerBid(Order calldata makerBid, Order calldata takerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            AssetType
        );
}
// File: contracts/lib/EIP712.sol


pragma solidity 0.8.17;


/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    /* Order typehash for EIP 712 compatibility. */
    bytes32 constant public FEE_TYPEHASH = keccak256(
        "Fee(uint16 rate,address recipient)"
    );
    bytes32 constant public ORDER_TYPEHASH = keccak256(
        "Order(address trader,uint8 side,address matchingPolicy,address collection,uint256 tokenId,uint256 amount,address paymentToken,uint256 price,uint256 listingTime,uint256 expirationTime,Fee[] fees,uint256 salt,bytes extraParams,uint256 nonce)Fee(uint16 rate,address recipient)"
    );
    bytes32 constant public ORACLE_ORDER_TYPEHASH = keccak256(
        "OracleOrder(Order order,uint256 blockNumber)Fee(uint16 rate,address recipient)Order(address trader,uint8 side,address matchingPolicy,address collection,uint256 tokenId,uint256 amount,address paymentToken,uint256 price,uint256 listingTime,uint256 expirationTime,Fee[] fees,uint256 salt,bytes extraParams,uint256 nonce)"
    );
    bytes32 constant public ROOT_TYPEHASH = keccak256(
        "Root(bytes32 root)"
    );

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
  /* Constants */
    string public constant NAME = "Blur Exchange";
    string public constant VERSION = "1.0";
    uint256 public constant INVERSE_BASIS_POINT = 10_000;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    bytes32 public DOMAIN_SEPARATOR = _hashDomain(EIP712Domain({
            name              : NAME,
            version           : VERSION,
            chainId           : block.chainid,
            verifyingContract : address(this)
        }));

    function _hashDomain(EIP712Domain memory eip712Domain)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                EIP712DOMAIN_TYPEHASH,
                keccak256(bytes(eip712Domain.name)),
                keccak256(bytes(eip712Domain.version)),
                eip712Domain.chainId,
                eip712Domain.verifyingContract
            )
        );
    }

    function _hashFee(Fee calldata fee)
        public 
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                FEE_TYPEHASH,
                fee.rate,
                fee.recipient
            )
        );
    }

    function _packFees(Fee[] calldata fees)
        public
        pure
        returns (bytes32)
    {
        bytes32[] memory feeHashes = new bytes32[](
            fees.length
        );
        for (uint256 i = 0; i < fees.length; i++) {
            feeHashes[i] = _hashFee(fees[i]);
        }
        return keccak256(abi.encodePacked(feeHashes));
    }


    function _hashOrder(Order calldata order, uint256 nonce)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            bytes.concat(
                abi.encode(
                      ORDER_TYPEHASH,
                      order.trader,
                      order.side,
                      order.matchingPolicy,
                      order.collection,
                      order.tokenId,
                      order.amount,
                      order.paymentToken,
                      order.price,
                      order.listingTime,
                      order.expirationTime,
                      _packFees(order.fees),
                      order.salt,
                      keccak256(order.extraParams)
                ),
                abi.encode(nonce)
            )
        );
    }

    function _hashToSign(bytes32 orderHash)
        public
        view
        returns (bytes32 hash)
    {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            orderHash
        ));
    }

    function _hashToSignRoot(bytes32 root)
        public
        view
        returns (bytes32 hash)
    {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                ROOT_TYPEHASH,
                root
            ))
        ));
    }

    function _hashToSignOracle(bytes32 orderHash, uint256 blockNumber)
        public
        view
        returns (bytes32 hash)
    {
        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(
                ORACLE_ORDER_TYPEHASH,
                orderHash,
                blockNumber
            ))
        ));
    }

    uint256[44] private __gap;
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/BlurExchange.sol

interface BlurOG {
    function nonces(address owner) external view returns (uint256);
    function cancelledOrFilled(bytes32 _hash) external view returns (bool);
    function blockRange() external view returns (uint256);
    function policyManager() external view returns (address);
    function oracle() external view returns (address);
}

contract BlurModified is EIP712, Ownable {

    address public mainAddress = address(0x000000000000Ad05Ccc4F10045630fb830B95127);

     function setMainAddress(address _address)
        public
        onlyOwner
    {
        mainAddress = _address;
    }

     function nonces(address owner) public view returns (uint256){
       return BlurOG(mainAddress).nonces(owner);
    }
    function cancelledOrFilled(bytes32 _hash) public view returns (bool){
       return BlurOG(mainAddress).cancelledOrFilled(_hash);
    }
    function blockRange() public view returns (uint256){
       return BlurOG(mainAddress).blockRange();
    }
    function policyManager() public view returns (IPolicyManager) {
        return IPolicyManager(BlurOG(mainAddress).policyManager());
    }
    function oracle() public view returns (address){
        return BlurOG(mainAddress).oracle();
    }
  

        /**
     * @dev Verify ECDSA signature
     * @param signer Expected signer
     * @param digest Signature preimage
     * @param v v
     * @param r r
     * @param s s
     */
    function _verify(
        address signer,
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (bool) {
        require(v == 27 || v == 28, "Invalid v parameter");
        address recoveredSigner = ecrecover(digest, v, r, s);
        if (recoveredSigner == address(0)) {
          return false;
        } else {
          return signer == recoveredSigner;
        }
    }

   
     /**
     * @dev Match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param sell Sell input
     * @param buy Buy input
     */
    function execute(Input calldata sell, Input calldata buy)
        public
        view
        returns (bytes32, bytes32, uint256, uint256, uint256, uint256)
    {
        require(sell.order.side == Side.Sell);
        uint256 sellNonce = nonces(sell.order.trader);
        bytes32 sellHash = _hashOrder(sell.order, sellNonce);
        bytes32 buyHash = _hashOrder(buy.order, nonces(buy.order.trader));

        require(_validateOrderParameters(sell.order, sellHash), "Sell has invalid parameters");
        require(_validateOrderParameters(buy.order, buyHash), "Buy has invalid parameters");

        require(_validateSignatures(sell, sellHash), "Sell failed authorization");
        require(_validateSignatures(buy, buyHash), "Buy failed authorization");

        (uint256 price, uint256 tokenId, uint256 amount, AssetType assetType) = _canMatchOrders(sell.order, buy.order);

        return (sellHash, buyHash, price, tokenId, amount, sellNonce);
    }

    /* Internal Functions */

    /**
     * @dev Verify the validity of the order parameters
     * @param order order
     * @param orderHash hash of order
     */


      /**
     * @dev Call the matching policy to check orders can be matched and get execution parameters
     * @param sell sell order
     * @param buy buy order
     */
    function _canMatchOrders(Order calldata sell, Order calldata buy)
        public
        view
        returns (uint256 price, uint256 tokenId, uint256 amount, AssetType assetType)
    {
        bool canMatch;
        if (sell.listingTime <= buy.listingTime) {
            /* Seller is maker. */
            require(policyManager().isPolicyWhitelisted(sell.matchingPolicy), "Policy is not whitelisted");
            (canMatch, price, tokenId, amount, assetType) = IMatchingPolicy(sell.matchingPolicy).canMatchMakerAsk(sell, buy);
        } else {
            /* Buyer is maker. */
            require(policyManager().isPolicyWhitelisted(buy.matchingPolicy), "Policy is not whitelisted");
            (canMatch, price, tokenId, amount, assetType) = IMatchingPolicy(buy.matchingPolicy).canMatchMakerBid(buy, sell);
        }
        require(canMatch, "Orders cannot be matched");

        return (price, tokenId, amount, assetType);
    }


    function _validateOrderParameters(Order calldata order, bytes32 orderHash)
        public
        view
        returns (bool)
    {
        return (
            /* Order must have a trader. */
            (order.trader != address(0)) &&
            /* Order must not be cancelled or filled. */
            (cancelledOrFilled(orderHash) == false) &&
            /* Order must be settleable. */
            _canSettleOrder(order.listingTime, order.expirationTime)
        );
    }

    /**
     * @dev Check if the order can be settled at the current timestamp
     * @param listingTime order listing time
     * @param expirationTime order expiration time
     */
    function _canSettleOrder(uint256 listingTime, uint256 expirationTime)
        view
        public
        returns (bool)
    {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Verify the validity of the signatures
     * @param order order
     * @param orderHash hash of order
     */
    function _validateSignatures(Input calldata order, bytes32 orderHash)
        public
        view
        returns (bool)
    {

        if (order.order.trader == msg.sender) {
          return true;
        }

        /* Check user authorization. */
        if (
            !_validateUserAuthorization(
                orderHash,
                order.order.trader,
                order.v,
                order.r,
                order.s,
                order.signatureVersion,
                order.extraSignature
            )
        ) {
            return false;
        }

        if (order.order.expirationTime == 0) {
            /* Check oracle authorization. */
            require(block.number - order.blockNumber < blockRange(), "Signed block number out of range");
            if (
                !_validateOracleAuthorization(
                    orderHash,
                    order.signatureVersion,
                    order.extraSignature,
                    order.blockNumber
                )
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Verify the validity of the user signature
     * @param orderHash hash of the order
     * @param trader order trader who should be the signer
     * @param v v
     * @param r r
     * @param s s
     * @param signatureVersion signature version
     * @param extraSignature packed merkle path
     */
    function _validateUserAuthorization(
        bytes32 orderHash,
        address trader,
        uint8 v,
        bytes32 r,
        bytes32 s,
        SignatureVersion signatureVersion,
        bytes calldata extraSignature
    ) public view returns (bool) {
        bytes32 hashToSign;
        if (signatureVersion == SignatureVersion.Single) {
            /* Single-listing authentication: Order signed by trader */
            hashToSign = _hashToSign(orderHash);
        } else if (signatureVersion == SignatureVersion.Bulk) {
            /* Bulk-listing authentication: Merkle root of orders signed by trader */
            (bytes32[] memory merklePath) = abi.decode(extraSignature, (bytes32[]));

            bytes32 computedRoot = MerkleVerifier._computeRoot(orderHash, merklePath);
            hashToSign = _hashToSignRoot(computedRoot);
        }

        return _verify(trader, hashToSign, v, r, s);
    }

     /**
     * @dev Verify the validity of oracle signature
     * @param orderHash hash of the order
     * @param signatureVersion signature version
     * @param extraSignature packed oracle signature
     * @param blockNumber block number used in oracle signature
     */
    function _validateOracleAuthorization(
        bytes32 orderHash,
        SignatureVersion signatureVersion,
        bytes calldata extraSignature,
        uint256 blockNumber
    ) public view returns (bool) {
        bytes32 oracleHash = _hashToSignOracle(orderHash, blockNumber);

        uint8 v; bytes32 r; bytes32 s;
        if (signatureVersion == SignatureVersion.Single) {
            (v, r, s) = abi.decode(extraSignature, (uint8, bytes32, bytes32));
        } else if (signatureVersion == SignatureVersion.Bulk) {
            /* If the signature was a bulk listing the merkle path must be unpacked before the oracle signature. */
            (bytes32[] memory merklePath, uint8 _v, bytes32 _r, bytes32 _s) = abi.decode(extraSignature, (bytes32[], uint8, bytes32, bytes32));
            v = _v; r = _r; s = _s;
        }

        return _verify(oracle(), oracleHash, v, r, s);
    }
}