// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';

interface ERC721 {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface ERC1155 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

interface ERC20 {
    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;
}

interface Distributor {
    function addFee(address[2] calldata addr, uint256 fee) external;
}

contract GolomTrader is Ownable {
    bytes32 public immutable EIP712_DOMAIN_TYPEHASH;
    mapping(address => uint256) public nonces; // all nonces other then this nonce
    mapping(bytes32 => uint256) public filled;

    ERC20 WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    struct Order {
        address collection; // NFT contract address
        uint256 tokenId; // order for which tokenId of the collection
        address signer; // maker of order address
        uint256 orderType; // 0 if selling nft for eth , 1 if offering weth for nft,2 if offering weth for collection with special criteria root
        uint256 totalAmt; // price value of the trade // total amt maker is willing to give up per unit of amount
        Payment exchange; // payment agreed by maker of the order to pay on succesful filling of trade this amt is subtracted from totalamt
        Payment prePayment; // another payment , can be used for royalty, facilating trades
        bool isERC721; // standard of the collection , if 721 then true , if 1155 then false
        uint256 tokenAmt; // token amt useful if standard is 1155 if >1 means whole order can be filled tokenAmt times
        uint256 refererrAmt; // amt to pay to the address that helps in filling your order
        bytes32 root; // A merkle root derived from each valid tokenId — set to 0 to indicate a collection-level or tokenId-specific order.
        address reservedAddress; // if not address(0) , only this address can fill the order
        uint256 nonce; // nonce of order usefull for cancelling in bulk
        uint256 deadline; // timestamp till order is valid epoch timestamp in secs
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Payment {
        uint256 paymentAmt;
        address paymentAddress;
    }

    address public governance;

    Distributor public distributor;
    address public pendingDistributor;
    uint256 public distributorEnableDate;

    // events
    event NonceIncremented(address indexed maker, uint256 newNonce);

    event OrderFilled(
        address indexed maker,
        address indexed taker,
        uint256 indexed orderType,
        bytes32 orderHash,
        uint256 price
    );

    event OrderCancelled(bytes32 indexed orderHash);

    /// @param _governance Address of the governance, responsible for setting distributor
    constructor(address _governance) {
        // sets governance as owner
        _transferOwnership(_governance);

        EIP712_DOMAIN_TYPEHASH = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes('GOLOM.IO')),
                keccak256(bytes('1')),
                1,
                address(this)
            )
        );
    }

    function hashPayment(Payment calldata p) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256('payment(uint256 paymentAmt,address paymentAddress)'),
                    p.paymentAmt,
                    p.paymentAddress
                )
            );
    }

    function _hashOrder(Order calldata o) private pure returns (bytes32) {
        return _hashOrderinternal(o, [o.nonce, o.deadline]);
    }

    function _hashOrderinternal(Order calldata o, uint256[2] memory extra) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        'order(address collection,uint256 tokenId,address signer,uint256 orderType,uint256 totalAmt,payment exchange,payment prePayment,bool isERC721,uint256 tokenAmt,uint256 refererrAmt,bytes32 root,address reservedAddress,uint256 nonce,uint256 deadline)payment(uint256 paymentAmt,address paymentAddress)'
                    ),
                    o.collection,
                    o.tokenId,
                    o.signer,
                    o.orderType,
                    o.totalAmt,
                    hashPayment(o.exchange),
                    hashPayment(o.prePayment),
                    o.isERC721,
                    o.tokenAmt,
                    o.refererrAmt,
                    o.root,
                    o.reservedAddress,
                    extra
                )
            );
    }

    function payEther(uint256 payAmt, address payAddress) internal {
        if (payAmt > 0) {
            // if royalty has to be paid
            payable(payAddress).transfer(payAmt); // royalty transfer to royaltyaddress
        }
    }

    /// @dev Validates Order and returns OrderStatus, hashedorder, amountRemaining to be filled
    ///      OrderStatus = 0 , if signature is invalid
    ///      OrderStatus = 1 , if deadline has been
    ///      OrderStatus = 2 , order is filled or cancelled
    ///      OrderStatus = 3 , valid order
    /// @param o the Order struct to be validated
    function validateOrder(Order calldata o)
        public
        view
        returns (
            uint256,
            bytes32,
            uint256
        )
    {
        // match signature
        bytes32 hashStruct = _hashOrder(o);
        bytes32 hash = keccak256(abi.encodePacked('\x19\x01', EIP712_DOMAIN_TYPEHASH, hashStruct));
        address signaturesigner = ecrecover(hash, o.v, o.r, o.s);
        require(signaturesigner == o.signer, 'invalid signature');
        if (signaturesigner != o.signer) {
            return (0, hashStruct, 0);
        }
        //deadline
        if (block.timestamp > o.deadline) {
            return (1, hashStruct, 0);
        }
        // not cancelled by nonce or by hash
        if (o.nonce != nonces[o.signer]) {
            return (2, hashStruct, 0);
        }
        if (filled[hashStruct] >= o.tokenAmt) {
            // handles erc1155
            return (2, hashStruct, 0);
        }
        return (3, hashStruct, o.tokenAmt - filled[hashStruct]);
    }

    /// @dev function to fill a signed order of ordertype 0, also has a payment param in case the taker wants
    ///      to send ether to that address on filling the order
    /// @param o the Order struct to be filled must be orderType 0
    /// @param amount the amount of times the order is to be filled(useful for ERC1155)
    /// @param referrer referrer of the order
    /// @param p any extra payment that the taker of this order wanna send on succesful execution of order
    function fillAsk(
        Order calldata o,
        uint256 amount,
        address referrer,
        Payment calldata p
    ) public payable {
        // check if the signed total amount has all the amounts as well as 50 basis points fee
        require(
            o.totalAmt >= o.exchange.paymentAmt + o.prePayment.paymentAmt + o.refererrAmt + (o.totalAmt * 50) / 10000,
            'amt not matching'
        );

        // attached ETH value should be greater than total value of one NFT * total number of NFTs + any extra payment to be given
        require(msg.value >= o.totalAmt * amount + p.paymentAmt, 'mgmtm');

        if (o.reservedAddress != address(0)) {
            require(msg.sender == o.reservedAddress);
        }
        require(o.orderType == 0, 'invalid orderType');

        (uint256 status, bytes32 hashStruct, uint256 amountRemaining) = validateOrder(o);

        require(status == 3, 'order not valid');
        require(amountRemaining >= amount, 'order already filled');

        filled[hashStruct] = filled[hashStruct] + amount;

        if (o.isERC721) {
            require(amount == 1, 'only 1 erc721 at 1 time');
            ERC721(o.collection).transferFrom(o.signer, msg.sender, o.tokenId);
        } else {
            ERC1155(o.collection).safeTransferFrom(o.signer, msg.sender, o.tokenId, amount, '');
        }

        // pay fees of 50 basis points to the distributor
        payEther(((o.totalAmt * 50) / 10000) * amount, address(distributor));

        // pay the exchange share
        payEther(o.exchange.paymentAmt * amount, o.exchange.paymentAddress);

        // pay the pre payment
        payEther(o.prePayment.paymentAmt * amount, o.prePayment.paymentAddress);

        if (o.refererrAmt > 0 && referrer != address(0)) {
            payEther(o.refererrAmt * amount, referrer);
            payEther(
                (o.totalAmt -
                    (o.totalAmt * 50) /
                    10000 -
                    o.exchange.paymentAmt -
                    o.prePayment.paymentAmt -
                    o.refererrAmt) * amount,
                o.signer
            );
        } else {
            payEther(
                (o.totalAmt - (o.totalAmt * 50) / 10000 - o.exchange.paymentAmt - o.prePayment.paymentAmt) * amount,
                o.signer
            );
        }
        payEther(p.paymentAmt, p.paymentAddress);

        distributor.addFee([o.signer, o.exchange.paymentAddress], ((o.totalAmt * 50) / 10000) * amount);
        emit OrderFilled(o.signer, msg.sender, 0, hashStruct, o.totalAmt * amount);
    }

    /// @dev function to fill a signed order of ordertype 1 also has a payment param in case the taker wants
    ///      to send ether to that address on filling the order
    /// @param o the Order struct to be filled must be orderType 1
    /// @param amount the amount of times the order is to be filled(useful for ERC1155)
    /// @param referrer referrer of the order
    /// @param p any extra payment that the taker of this order wanna send on succesful execution of order
    function fillBid(
        Order calldata o,
        uint256 amount,
        address referrer,
        Payment calldata p
    ) public {
        require(
            o.totalAmt * amount >
                (o.exchange.paymentAmt + o.prePayment.paymentAmt + o.refererrAmt) * amount + p.paymentAmt
        ); // cause bidder eth is paying for seller payment p , dont take anything extra from seller
        // require eth amt is sufficient
        if (o.reservedAddress != address(0)) {
            require(msg.sender == o.reservedAddress);
        }
        require(o.orderType == 1);
        (uint256 status, bytes32 hashStruct, uint256 amountRemaining) = validateOrder(o);
        require(status == 3);
        require(amountRemaining >= amount);
        filled[hashStruct] = filled[hashStruct] + amount;
        if (o.isERC721) {
            require(amount == 1, 'only 1 erc721 at 1 time');
            ERC721 nftcontract = ERC721(o.collection);
            nftcontract.transferFrom(msg.sender, o.signer, o.tokenId);
        } else {
            ERC1155 nftcontract = ERC1155(o.collection);
            nftcontract.safeTransferFrom(msg.sender, o.signer, o.tokenId, amount, '');
        }
        emit OrderFilled(msg.sender, o.signer, 1, hashStruct, o.totalAmt * amount);
        _settleBalances(o, amount, referrer, p);
    }

    // cancel by nonce and by individual order

    function cancelOrder(Order calldata o) public {
        require(o.signer == msg.sender);
        (, bytes32 hashStruct, ) = validateOrder(o);
        filled[hashStruct] = o.tokenAmt + 1;
        emit OrderCancelled(hashStruct);
    }

    /**
     * Increment a particular maker's nonce, thereby invalidating all orders that were not signed
     * with the original nonce.
     */
    function incrementNonce() external {
        uint256 newNonce = ++nonces[msg.sender];
        emit NonceIncremented(msg.sender, newNonce);
    }

    /// @dev function to fill a signed order of ordertype 2 also has a payment param in case the taker wants
    ///      to send ether to that address on filling the order, Match an criteria order, ensuring that the supplied proof demonstrates inclusion of the tokenId in the associated merkle root, if root is 0 then any token can be used to fill the order
    /// @param o the Order struct to be filled must be orderType 2
    /// @param amount the amount of times the order is to be filled(useful for ERC1155)
    /// @param referrer referrer of the order
    /// @param p any extra payment that the taker of this order wanna send on succesful execution of order
    function fillCriteriaBid(
        Order calldata o,
        uint256 amount,
        uint256 tokenId,
        bytes32[] calldata proof,
        address referrer,
        Payment calldata p
    ) public {
        require(o.totalAmt >= o.exchange.paymentAmt + o.prePayment.paymentAmt + o.refererrAmt);
        // require eth amt is sufficient
        if (o.reservedAddress != address(0)) {
            require(msg.sender == o.reservedAddress);
        }
        require(o.orderType == 2);
        (uint256 status, bytes32 hashStruct, uint256 amountRemaining) = validateOrder(o);
        require(status == 3);
        require(amountRemaining >= amount);

        filled[hashStruct] = filled[hashStruct] + amount;
        // Proof verification is performed when there's a non-zero root.
        if (o.root != bytes32(0)) {
            _verifyProof(tokenId, o.root, proof);
        }

        if (o.isERC721) {
            require(amount == 1, 'only 1 erc721 at 1 time');
            ERC721 nftcontract = ERC721(o.collection);
            nftcontract.transferFrom(msg.sender, o.signer, tokenId);
        } else {
            ERC1155 nftcontract = ERC1155(o.collection);
            nftcontract.safeTransferFrom(msg.sender, o.signer, tokenId, amount, '');
        }
        emit OrderFilled(msg.sender, o.signer, 2, hashStruct, o.totalAmt * amount);
        _settleBalances(o, amount, referrer, p);
    }

    /// @dev function to settle balances when a bid is filled succesfully
    /// @param o the Order struct to be filled must be orderType 1
    /// @param amount the amount of times the order is to be filled(useful for ERC1155)
    /// @param referrer referrer of the order
    /// @param p any extra payment that the taker of this order wanna send on succesful execution of order
    function _settleBalances(
        Order calldata o,
        uint256 amount,
        address referrer,
        Payment calldata p
    ) internal {
        uint256 protocolfee = ((o.totalAmt * 50) / 10000) * amount;
        WETH.transferFrom(o.signer, address(this), o.totalAmt * amount);
        WETH.withdraw(o.totalAmt * amount);
        payEther(protocolfee, address(distributor));
        payEther(o.exchange.paymentAmt * amount, o.exchange.paymentAddress);
        payEther(o.prePayment.paymentAmt * amount, o.prePayment.paymentAddress);
        if (o.refererrAmt > 0 && referrer != address(0)) {
            payEther(o.refererrAmt * amount, referrer);
            payEther(
                (o.totalAmt - protocolfee - o.exchange.paymentAmt - o.prePayment.paymentAmt - o.refererrAmt) *
                    amount -
                    p.paymentAmt,
                msg.sender
            );
        } else {
            payEther(
                (o.totalAmt - protocolfee - o.exchange.paymentAmt - o.prePayment.paymentAmt) * amount - p.paymentAmt,
                msg.sender
            );
        }
        payEther(p.paymentAmt, p.paymentAddress);
        distributor.addFee([msg.sender, o.exchange.paymentAddress], protocolfee);
    }

    /// @dev Ensure that a given tokenId is contained within a supplied merkle root using a supplied proof.
    /// @param leaf The tokenId.
    /// @param root A merkle root derived from each valid tokenId.
    /// @param proof A proof that the supplied tokenId is contained within the associated merkle root.
    function _verifyProof(
        uint256 leaf,
        bytes32 root,
        bytes32[] memory proof
    ) public view {
        bytes32 computedHash = keccak256(abi.encode(leaf));
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
        if (computedHash != root) {
            revert('invalid proof');
        }
    }

    /// @dev Efficiently hash two bytes32 elements using memory scratch space.
    /// @param a The first element included in the hash.
    /// @param b The second element included in the hash.
    /// @return value The resultant hash of the two bytes32 elements.
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    /// @notice Sets the distributor contract
    /// @param _distributor Address of the distributor
    function setDistributor(address _distributor) external onlyOwner {
        if (address(distributor) == address(0)) {
            distributor = Distributor(_distributor);
        } else {
            pendingDistributor = _distributor;
            distributorEnableDate = block.timestamp + 1 days;
        }
    }

    /// @notice Executes the set distributor function after the timelock
    function executeSetDistributor() external onlyOwner {
        require(distributorEnableDate >= block.timestamp, 'not allowed');
        distributor = Distributor(pendingDistributor);
    }

    fallback() external payable {}

    receive() external payable {}
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