/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

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




/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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




/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}




/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721CollectionTemplate is IERC721{
    function initialize(string memory name_, string memory symbol_, address _owner, string memory _uri, uint256 _amount) external;
}



/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Template is IERC721{
    function initialize(string memory name_, string memory symbol_, address _owner, string memory _uri) external;
}



/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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


/** 
 *  SourceUnit: /home/talha/NFT MarketplaceDapp/NFTMarketplace.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";
////import "./interfaces/IERC721Template.sol";
////import "./interfaces/IERC721CollectionTemplate.sol";
////import "@openzeppelin/contracts/proxy/Clones.sol";

contract NFTMarket is Ownable {
    uint256 maxRoyaltyPercentage;
    uint256 ownerPercentage;
    address payable ownerFeesAccount;
    uint256 public _nftIdCounter;

    struct listingFixPrice {
        uint256 price;
        address seller;
    }

    struct nft {
        uint256 nftId;
        address erc721;
        uint256 tokenId;
        address creator;
    }

    struct royalty {
        address payable creator;
        uint256 percentageRoyalty;
    }

    //Constructor
    constructor() {}

    //Events
    event nftCreated(
        uint256 nftId,
        address indexed erc721,
        uint256 indexed tokenId,
        address creator,
        uint256 royalty,
        string uri
    );
    event tokenListedFixPrice(
        uint256 nftId,
        uint256 price
    );
    event tokenUnlistedFixPrice(
        uint256 nftId
    );
    event nftBoughtFixPrice(
        uint256 nftId,
        address owner
    );

    //Mappings
    mapping(address => mapping(uint256 => listingFixPrice)) listingFixPrices;
    mapping(address => mapping(uint256 => royalty)) royalties;
    mapping(uint256 => nft) nfts;
    mapping(address => uint256) balanceOf;
    mapping(uint256 => address) public templates;

    function createTemplate(
        address _template,
        uint256 _index
    ) public onlyOwner {
        require(
            templates[_index] == address(0),
            "Template already exists"
        );

        templates[_index] = _template;
    }

    function removeTemplate(uint256 _index) public onlyOwner {
        require(
            templates[_index] != address(0),
            "Template does not exist"
        );

        delete templates[_index];
    }

    // function createNft(
    //     uint256 _ERC721TemplateIndex,
    //     string memory _name,
    //     string memory _symbol,
    //     string memory _uri,
    //     uint256 _royalty
    // )
    //     public
    // {
    //     require(
    //         _royalty <= maxRoyaltyPercentage,
    //         "Royalty Percentage Must Be Less Than Or Equal To Max Royalty Percentage"
    //     );

    //     require(
    //         templates[_ERC721TemplateIndex].templateAddress != address(0) &&
    //             templates[_ERC721TemplateIndex].isActive &&
    //             templates[_ERC721TemplateIndex].templateType ==
    //             TemplateType.ERC721,
    //         "ERC721 template does not exist or is not active"
    //     );

    //     // clone ERC721Template
    //     address erc721Token = Clones.clone(
    //         templates[_ERC721TemplateIndex].templateAddress
    //     );

    //     // initialize erc721Token
    //     IERC721Template(erc721Token).initialize(
    //         _name,
    //         _symbol,
    //         msg.sender,
    //         _uri
    //     );

    //     uint256 nftId = _nftIdCounter;
    //     nfts[nftId] = nft(nftId, erc721Token, 0, msg.sender);
    //     address payable _creator = payable(msg.sender);
    //     royalties[erc721Token][0] = royalty(_creator , _royalty);
    //     emit nftCreated(nftId, erc721Token, 0, msg.sender, _uri);
    //     _nftIdCounter+= 1;

    // }

    function createNftCollection(
        uint256 _ERC721CollectionTemplateIndex,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _royalty,
        uint256 _amount
    )
        public
    {
        require(
            _royalty <= maxRoyaltyPercentage,
            "Royalty Percentage Must Be Less Than Or Equal To Max Royalty Percentage"
        );

        // clone ERC721Template
        address erc721CollectionToken = Clones.clone(
            templates[_ERC721CollectionTemplateIndex]
        );

        // initialize erc721Token
        IERC721CollectionTemplate(erc721CollectionToken).initialize(
            _name,
            _symbol,
            msg.sender,
            _uri,
            _amount
        );

        for (uint256 i = 0; i < _amount; i++) {
            uint256 nftId = _nftIdCounter;
            nfts[nftId] = nft(nftId, erc721CollectionToken, i, msg.sender);
            address payable _creator = payable(msg.sender);
            royalties[erc721CollectionToken][i] = royalty(_creator , _royalty);
            emit nftCreated(nftId, erc721CollectionToken, i, msg.sender, _royalty, _uri);
            _nftIdCounter+= 1;
        }

    }

    function getNftDetails(uint256 _nftId)
        public
        view
        returns (uint256, address, uint256, address)
    {
        require(
            nfts[_nftId].nftId == _nftId,
            "NFT does not exist"
        );

        return (nfts[_nftId].nftId, nfts[_nftId].erc721, nfts[_nftId].tokenId, nfts[_nftId].creator);
    }

    function setMaxRoyaltyPercentage(uint256 _maxRoyaltyPercentage)
        public
        onlyOwner
    {
        maxRoyaltyPercentage = _maxRoyaltyPercentage;
    }

    function setOwnerPercentage(uint256 _ownerPercentage) public onlyOwner {
        ownerPercentage = _ownerPercentage;
    }

    function setOwnerAccount(address payable _ownerFeesAccount)
        public
        onlyOwner
    {
        ownerFeesAccount = _ownerFeesAccount;
    }

    function listNftFixPrice(
        uint256 _price,
        uint256 _nftId
    ) public {

        require(
            IERC721(nfts[_nftId].erc721).ownerOf(nfts[_nftId].tokenId) == msg.sender,
            "You Dont Own the Given Token"
        );
        require(_price > 0, "Price Must Be Greater Than 0");
        require(
            IERC721(nfts[_nftId].erc721).isApprovedForAll(msg.sender, address(this)),
            "This Contract is not Approved"
        );

        listingFixPrices[nfts[_nftId].erc721][nfts[_nftId].tokenId] = listingFixPrice(
            _price,
            msg.sender
        );

        emit tokenListedFixPrice(_nftId, _price);
    }

    function unlistNftFixPrice(uint256 _nftId) public {
        require(
            IERC721(nfts[_nftId].erc721).ownerOf(nfts[_nftId].tokenId) == msg.sender,
            "You Dont Own the Given Token"
        );

        delete listingFixPrices[nfts[_nftId].erc721][nfts[_nftId].tokenId];
        delete royalties[nfts[_nftId].erc721][nfts[_nftId].tokenId];
        emit tokenUnlistedFixPrice(_nftId);
    }

    function buyNftFixedPrice(uint256 _nftId) public payable {
        require(
            msg.value >= listingFixPrices[nfts[_nftId].erc721][nfts[_nftId].tokenId].price,
            "You Must Pay At Least The Price"
        );

        uint256 feesToPayOwner = (listingFixPrices[nfts[_nftId].erc721][nfts[_nftId].tokenId].price *
            ownerPercentage) / 100;
        uint256 royaltyToPay = (listingFixPrices[nfts[_nftId].erc721][nfts[_nftId].tokenId].price *
            royalties[nfts[_nftId].erc721][nfts[_nftId].tokenId].percentageRoyalty) / 100;
        uint256 totalPrice = msg.value - royaltyToPay - feesToPayOwner;
        IERC721(nfts[_nftId].erc721).safeTransferFrom(
            listingFixPrices[nfts[_nftId].erc721][nfts[_nftId].tokenId].seller,
            msg.sender,
            nfts[_nftId].tokenId
        );
        balanceOf[listingFixPrices[nfts[_nftId].erc721][nfts[_nftId].tokenId].seller] += totalPrice;
        royalties[nfts[_nftId].erc721][nfts[_nftId].tokenId].creator.transfer(royaltyToPay);
        ownerFeesAccount.transfer(feesToPayOwner);
        unlistNftFixPrice(_nftId);

        emit nftBoughtFixPrice(_nftId, msg.sender);
    }

    function withdraw(uint256 amount, address payable desAdd) public {
        require(balanceOf[msg.sender] >= amount, "Insuficient Funds");

        desAdd.transfer(amount);
        balanceOf[msg.sender] -= amount;
    }
}