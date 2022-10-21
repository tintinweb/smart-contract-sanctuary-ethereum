/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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


// Dependency file: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// pragma solidity ^0.8.0;

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

library IterableNFTList {
    // Iterable mapping from uint256 to (address, uint256);
	struct NFTItem {
	    address target;
		uint256 tokenId;
	}
    struct Map {
        uint256[] keys;
        mapping(uint256 => NFTItem) values;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function getKey(address target, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(bytes.concat(bytes20(target), bytes32(tokenId))));
    }

    function get(Map storage map, uint256 index) public view returns (address, uint256) {
        require(index < map.keys.length);
        uint256 key = map.keys[index];

        NFTItem storage item = map.values[key];
        return (item.target, item.tokenId);
	}

    function getIndexOf(Map storage map, address target, uint256 tokenId)
        public
        view
        returns (int256)
    {
	    uint256 key = getKey(target, tokenId);
	
        if (!map.inserted[key]) {
            return -1;
        }

        return int256(map.indexOf[key]);
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address target,
		uint256 tokenId
    ) public {
        uint256 key = getKey(target, tokenId);

        if (!map.inserted[key]) {
            map.inserted[key] = true;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }

        NFTItem storage item = map.values[key];
        item.target = target;
        item.tokenId = tokenId;
    }

    function remove(Map storage map, address target, uint256 tokenId) public {
        uint256 key = getKey(target, tokenId);

        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}


// pragma solidity ^0.8.0;

contract NFTMarket is IERC721Receiver {
    address public operator;
    address payable public payee;
    uint32 public default_service_charge;
    uint32 public default_royalty;
	uint32 public constant fee_scale = 1000;

    struct NFTInfo {
	    address payable author;
        uint32 service_charge;
		uint32 royalty;
		bool setFee;
    }

    struct Offer {
	    address target;
		uint256 tokenId;
		address owner;
		uint256 price;
		uint32 service_charge;
		uint32 royalty;
		uint deadline;
	}

    mapping(address => NFTInfo) private nftInfo;
	mapping(address => mapping(uint256 => Offer)) private book;

    using IterableNFTList for IterableNFTList.Map;
    IterableNFTList.Map private nftList;

    event FeeChange(address indexed target, uint32 old_service_charge, uint32 old_royalty, uint32 new_service_charge, uint32 new_royalty);
	event StartSell(address indexed target, uint256 indexed tokenId, uint256 price,
	                uint32 service_charge, uint32 royalty, uint deadline);
    event Deal(address indexed target, uint256 indexed tokenId, uint256 price);
    event ExpireSell(address indexed target, uint256 indexed tokenId, uint deadline);
    event OperatorshipTransferred(address oldOperator, address newOperator);
    event PayeeChange(address oldPayee, address newPayee);

    constructor(
        address _operator,
        address payable _payee,
        uint32 service_charge,
        uint32 royalty
	) {
        if (_operator != address(0)) {
            operator = _operator;
        } else {
            operator = msg.sender;
        }

        if (_payee != address(0)) {
		    payee = _payee;
        } else {
            payee = payable(msg.sender);
        }

        require(service_charge + royalty < fee_scale);
        default_service_charge = service_charge;
        default_royalty = royalty;
	}

    modifier isOperator() {
        require(msg.sender == operator, "No permission to operate.");
        _;
    }

    function setAuthor(address target, address payable author) public isOperator {
	    require(target != address(0));
        require(author != address(0), "NFT Author is zero address.");

        nftInfo[target].author = author;
    }

    function setFee(address target, uint32 service_charge, uint32 royalty) public isOperator {
        require(service_charge + royalty < fee_scale);

        uint32 old_service_charge;
        uint32 old_royalty;
        if (target != address(0)) {
            NFTInfo storage info = nftInfo[target];

            if (info.setFee) {
                old_service_charge = info.service_charge;
                old_royalty = info.royalty;
			} else {
                old_service_charge = default_service_charge;
                old_royalty = default_royalty;
			}

            info.service_charge = service_charge;
            info.royalty = royalty;
            info.setFee = true;
        } else {
            old_service_charge = default_service_charge;
            old_royalty = default_royalty;

            default_service_charge = service_charge;
            default_royalty = royalty;
        }

        emit FeeChange(target, old_service_charge, old_royalty, service_charge, royalty);
	}

    function sell(address target, uint256 tokenId, uint256 price, uint32 feeLimit, uint period) public {
        require(target != address(0));
        require(nftInfo[target].author != address(0), "NFT author is unknown.");

        Offer storage item = book[target][tokenId];
        require(item.target == address(0), "NFT is selling.");

        address owner = IERC721(target).ownerOf(tokenId);
        require(msg.sender == owner || IERC721(target).isApprovedForAll(owner, msg.sender) || IERC721(target).getApproved(tokenId) == msg.sender,
                "No privilege to sell the token."); 

        IERC721(target).transferFrom(owner, address(this), tokenId);

        item.target = target;
        item.tokenId = tokenId;
        item.owner = owner;
        item.price = price;
        (item.service_charge, item.royalty) = getFee(target);
        require(item.service_charge + item.royalty <= feeLimit, "Fee too much.");
        item.deadline = block.timestamp + period;

        nftList.set(target, tokenId);
        emit StartSell(target, tokenId, price, item.service_charge, item.royalty, item.deadline);
    }

    function buy(address target, uint256 tokenId) public payable {
        Offer storage item = book[target][tokenId];
        require(item.target != address(0), "NFT is not selling.");
        require(block.timestamp <= item.deadline, "Selling is expired.");
        require(msg.value >= item.price, "Your payment is less than seller's price.");

        IERC721(target).transferFrom(address(this), msg.sender, tokenId);

        address payable author = nftInfo[target].author;
        uint256 amount1 = item.price * item.royalty / fee_scale;
        author.transfer(amount1);

        uint256 amount2 = item.price * item.service_charge / fee_scale;
        payee.transfer(amount2);

        payable(item.owner).transfer(item.price - amount1 - amount2);
        if (msg.value > item.price) {
            payable(msg.sender).transfer(msg.value - item.price);
        }

        emit Deal(target, tokenId, item.price);
        nftList.remove(target, tokenId);
        delete book[target][tokenId];
    }

    function end(address target, uint256 tokenId) public {
        Offer storage item = book[target][tokenId];
        require(item.target != address(0), "NFT is not selling.");
        require(block.timestamp > item.deadline, "Selling is not expired.");

        IERC721(target).transferFrom(address(this), item.owner, tokenId);

        emit ExpireSell(target, tokenId, item.deadline);
        nftList.remove(target, tokenId);
        delete book[target][tokenId];
    }

    function getAuthor(address target) public view returns (address) {
        return nftInfo[target].author;
    }

    function getFee(address target) public view returns (uint32, uint32) {	
        NFTInfo storage info = nftInfo[target];

        if (info.setFee) {
            return (info.service_charge, info.royalty);
        }

        return (default_service_charge, default_royalty);		
	}

    function onERC721Received(
        address sender,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        require(sender == address(this), "Don't send token to me directly.");
        return msg.sig;
    }

    function getOfferNumber() public view returns (uint256) {
        return nftList.size();
    }

    function getOfferInfo(address target, uint256 tokenId) public view returns (address owner, uint256 price, uint32 service_charge, uint32 royalty, uint deadline) {
        Offer storage item = book[target][tokenId];

        owner = item.owner;
        price = item.price;
		service_charge = item.service_charge;
        royalty = item.royalty;
		deadline = item.deadline;
    }

    function getOfferInfoByIndex(uint256 index) public view returns (address target, uint256 tokenId, address owner, uint256 price, uint32 service_charge,
                                                                     uint32 royalty, uint deadline) {
        (target, tokenId) = nftList.get(index);

        (owner, price, service_charge, royalty, deadline) = getOfferInfo(target, tokenId);	
    }

    function transferOperatorship(address newOperator) public isOperator {
        address oldOperator = operator;
        operator = newOperator;
        emit OperatorshipTransferred(oldOperator, newOperator);
    }

    function setPayee(address newPayee) public isOperator {
        require(newPayee != address(0), "New payee is zero address.");
        address oldPayee = payee;
        payee = payable(newPayee);
        emit PayeeChange(oldPayee, newPayee);
    }
}