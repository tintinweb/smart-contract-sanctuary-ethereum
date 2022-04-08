/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]
// SPDX-License-Identifier: MIT

// License-Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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


// File contracts/HbNftDex.sol

// License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

// import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// import "./libs/order.sol";
// import "hardhat/console.sol";

contract HbNftDex {

    bytes32 public HashEIP712Domain = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    bytes32 public HashOrderSturct = keccak256(
        "FixedPriceOrder(address taker,address maker,uint256 maker_nonce,uint64 listing_time,uint64 expiration_time,address nft_contract,uint256 token_id,address payment_token,uint256 fixed_price,uint256 royalty_rate,address royalty_recipient)"
    );
    bytes32 public HashEIP712Version;
    bytes32 public HashEIP712Name;
    string public name;
    string public version;
    address public daoOwner;

    /* Recipient of protocol fees. */
    address public protocolFeeRecipient;

    /* minimum required protocol fee */
    uint256 public minProtocolFee;

    /* support contracts. */
    mapping(address => bool) public allowedNftContracts;
    bool public isAllowAllNftContracts;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public finalizedOrder;

    /* user operate times */
    mapping(address => uint256) public userNonce;

    /* user operate times */
    mapping(address => mapping(bytes32 => bool)) private userCanceledOrder;

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* 挂单类型: FixedPrice; EnglishAuction; DutchAuction */
    struct FixedPriceOrder {
        /* 订单taker，表示只与特定的taker进行交易，Address(0)表示同意与任意地址进行交易 */
        address taker;
        /* 订单maker. */
        address maker;
        /* nonce */
        uint256 maker_nonce;
        /* 挂单时间 */
        uint64 listing_time;
        /* 失效时间 */
        uint64 expiration_time;
        /* NFT 地址 */
        address nft_contract;
        /* NFT tokenId  */
        uint256 token_id;
        /* 支付代币地址, 如果用本币支付, 设置为address(0). */
        address payment_token;
        /* 如果order_type是FixedPrice, 即为成交价; 如果是拍卖, 按拍卖方式定义 */
        uint256 fixed_price;
        /* 版税比例 */
        uint256 royalty_rate;
        /* 版税接收地址 */
        address royalty_recipient;
    }

    /* 订单取消事件 */
    event OrderCancelled(address indexed maker, bytes32 indexed hash);
    /* 订单成交事件 */
    event FixedPriceOrderMatched(
        address msg_sender,
        address taker,
        address maker,
        bytes32 order_hash,
        bytes order_bytes
    );

    /* 取消所有的挂单 */
    event AllOrdersCancelled(address indexed maker, uint256 currentNonce);
    /* 是否允许接入所有NFT的设置改变 */
    event IsAllowAllNftContractsChanged(address indexed operator, bool shouldCheck);
    /* 增加允许接入的NFT合约*/
    event NftContractAdded(address indexed operator, address indexed nftContract);
    /* 取消允许接入的NFT合约*/
    event NftContractRemoved(address indexed operator, address indexed nftContract);

    modifier onlyOwner() {
        require(daoOwner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (
        string memory _name,
        string memory _version,
        address _protocolFeeRecipient,
        uint256 _minProtocolFee,
        address _daoOwner
    ) {
        daoOwner = _daoOwner;
        protocolFeeRecipient = _protocolFeeRecipient;
        minProtocolFee = _minProtocolFee;
        isAllowAllNftContracts = false;
        name = _name;
        version = _version;
        HashEIP712Name = keccak256(bytes(name));
        HashEIP712Version = keccak256(bytes(version));
    }

    /**
     * @dev Change the minimum fee paid to the protocol (owner only)
     * @param newMinProtocolFee New fee to set in basis points
     */
    function changeMinProtocolFee(uint256 newMinProtocolFee) public onlyOwner {
        minProtocolFee = newMinProtocolFee;
    }
    /**
    * 设置是否允许接入所有符合要求的ERC721合约
    */
    function setIsAllowedNftContracts(bool shouldCheck) public onlyOwner {
        require(shouldCheck != isAllowAllNftContracts, "status not changed");

        isAllowAllNftContracts = shouldCheck;

        emit IsAllowAllNftContractsChanged(msg.sender, shouldCheck);
    }
    /**
    * 增加允许接入的NFT合约地址
     */
    function addAllowedContract(address contractAddr) public onlyOwner {
        require(!allowedNftContracts[contractAddr], "contract added");
        allowedNftContracts[contractAddr] = true;

        emit NftContractAdded(msg.sender, contractAddr);
    }
    /**
    * 取消允许接入的NFT合约地址
     */
    function removeAllowedContract(address contractAddr) public onlyOwner {
        require(allowedNftContracts[contractAddr], "contract not supported");
        delete allowedNftContracts[contractAddr];

        emit NftContractRemoved(msg.sender, contractAddr);
    }

    function FixedPriceOrderEIP712Encode(FixedPriceOrder memory order) public view returns(bytes memory) {
        bytes memory order_bytes = abi.encode(
            HashOrderSturct,
            order.taker,
            order.maker,
            order.maker_nonce,
            order.listing_time,
            order.expiration_time,
            order.nft_contract,
            order.token_id,
            order.payment_token,
            order.fixed_price,
            order.royalty_rate,
            order.royalty_recipient
        );
        return order_bytes;
    }

    // CompilerError: Stack too deep, try removing local variables.
    function exchangeFixedPrice(
        address taker,
        FixedPriceOrder memory order,
        Sig memory maker_sig,
        Sig memory taker_sig
    ) external {
        // require(order.order_type == 0, "It is not a fixed-price order");
        address maker = order.maker;
        // TODO 若nft_contract不是真正的NFT合约会revert吗？
        address nft_owner = IERC721(order.nft_contract).ownerOf(order.token_id);
        require(
            maker != address(0) &&
            taker != address(0) &&
            nft_owner != address(0),
            "Maker, Taker or NFT_Owner is address(0)"
        );
        require(maker != taker, "Taker is same as maker");
        if(order.taker != address(0)) {
            require(taker == order.taker, "Taker is not the one set by maker");
        }
        require(nft_owner == maker || nft_owner == taker, "NFT owner must be maker or taker");
        require(isAllowAllNftContracts || allowedNftContracts[order.nft_contract], "NFT contract is not supported");

        require(order.expiration_time >= block.timestamp, "Order is expired");
        require(order.maker_nonce == userNonce[maker], "Maker nonce doesn't match");

        bytes memory order_bytes = FixedPriceOrderEIP712Encode(order);
        bytes32 order_hash = keccak256(order_bytes);
        require(
            (!finalizedOrder[order_hash]) &&
            (!userCanceledOrder[maker][order_hash]) &&
            (!userCanceledOrder[taker][order_hash])
        );

        bytes32 digest = _hashTypedDataV4(order_hash);
        require(maker == ecrecover(digest, maker_sig.v, maker_sig.r, maker_sig.s));
        require(taker == ecrecover(digest, taker_sig.v, taker_sig.r, taker_sig.s));

        // TODO set & get royalty_rate royalty_recipient EIP2981???
        // TODO 或者将版税先转给平台，再由平台按月发放给NFT原作者
        // TODO 检查订单中的版税参数是否符合在平台上创建专辑时设定的值
        // TODO NFT合约中，由NFT原创者设置版税？？？

        // TODO 执行NFT懒铸造
        // TODO 执行结算，多余的额度需退还
        emit FixedPriceOrderMatched(
            msg.sender,
            taker,
            maker,
            order_hash,
            order_bytes
        );
    }

    function cancelOrder(bytes32 order_hash) public {
        userCanceledOrder[msg.sender][order_hash] = true;

        emit OrderCancelled(msg.sender, order_hash);
    }

    function cancelAllOrders() public {
        ++userNonce[msg.sender];
        uint256 nonce = userNonce[msg.sender];

        emit AllOrdersCancelled(msg.sender, nonce);
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        // return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
        return _toTypedDataHash(_domainSeparatorV4(), structHash);
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
    function _toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return keccak256(abi.encode(HashEIP712Domain, HashEIP712Name, HashEIP712Version, block.chainid, address(this)));
    }


}