/**
 *Submitted for verification at Etherscan.io on 2022-09-20
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


// pragma solidity ^0.8.0;

contract PublicAuction is IERC721Receiver {
    uint public bidStart;
	uint public bidEnd;
	uint public startPrice;

    address public target;
    uint256 public tokenId;

    address payable public beneficiary;
    address payable public highestBidder;
    uint public highestBid;

    bool public ended;

    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    constructor(
        address _target,
        uint256 _tokenId,
        uint _startPrice,
        uint _bidStart,
        uint _bidPeriod,
        address payable _beneficiary
    ) {
        if (_bidStart != 0) {
            bidStart = _bidStart;
        } else {
            bidStart = block.timestamp;
        }

        bidEnd = bidStart + _bidPeriod;
        require(bidStart < bidEnd && block.timestamp < bidEnd, "Auction not yet started, but already ended.");

        startPrice = _startPrice;
        target = _target;
        tokenId = _tokenId;

        require(_isApprovedOrOwner(), "PublicAuction: No privilege to auction the specified token.");

        address owner = IERC721(_target).ownerOf(_tokenId);
        if (_beneficiary != address(0)) {
            beneficiary = _beneficiary;
        } else {
            beneficiary = payable(owner);
        }

        highestBidder = payable(owner);
	}

    function _isApprovedOrOwner() internal view virtual returns (bool) {
		address owner = IERC721(target).ownerOf(tokenId);

        return (msg.sender == owner || IERC721(target).isApprovedForAll(owner, msg.sender) || IERC721(target).getApproved(tokenId) == msg.sender);
    }

    modifier ownToken() {
        if (!ended) {
            require(IERC721(target).ownerOf(tokenId) == address(this), "Token must be deposited before auction");
        }
        _;
    }

    function bid() public payable ownToken {
        require(block.timestamp >= bidStart, "Auction not yet started.");
        require(block.timestamp <= bidEnd, "Auction already ended.");
        require(msg.value > highestBid, "There alread is a higher bid.");
        require(msg.value >= startPrice, "Bid price must be not less than start price.");
        require(msg.sender != beneficiary, "Bidder can not be beneficiary.");

        if (highestBid != 0) {
            highestBidder.transfer(highestBid);
        }

        highestBid = msg.value;
        highestBidder = payable(msg.sender);
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function end() public {
        require(block.timestamp > bidEnd, "Auction not yet ended.");
        require(!ended, "Auction already ended.");

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        IERC721(target).transferFrom(address(this), highestBidder, tokenId);
        if (highestBid != 0) {
            beneficiary.transfer(highestBid);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes calldata
    ) external view override returns (bytes4) {
        require(!ended, "Auction already ended.");
		require(tokenId == _tokenId, "Cann't receive the token.");
        return msg.sig;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract AuctionHouse {
    mapping(address => mapping(uint256 => address)) private auctions;

    using IterableMapping for IterableMapping.Map;
	IterableMapping.Map private current;
	IterableMapping.Map private all;

    mapping(address => string) private remarks;

	mapping(uint256 => address) private uids;

    event AuctionOpen(address auction, address target, uint256 tokenId, uint startPrice, uint startTime, uint endTime, address beneficiary, address operator);

    function _isApprovedOrOwner(address target, uint256 tokenId) internal view virtual returns (bool) {
        address owner = IERC721(target).ownerOf(tokenId);

        return (msg.sender == owner || IERC721(target).isApprovedForAll(owner, msg.sender) || IERC721(target).getApproved(tokenId) == msg.sender);
    }

    function openAuction(address target, uint256 tokenId, uint startPrice, uint startTime, uint bidPeriod,
						 address payable beneficiary, string memory remark, uint256 uid) public returns (address) {
        address auction = auctions[target][tokenId];
        require(auction == address(0) || PublicAuction(auction).ended(), "Auction is running for the same target.");
        require(uid == 0 || uids[uid] == address(0), "The aution with the same uid has existed.");

        if (beneficiary == address(0)) {
            beneficiary = payable(msg.sender);
        }

        if (auction != address(0)) {
            current.remove(auction); 
        }

        require(_isApprovedOrOwner(target, tokenId), "AuctionHouse: No privilege to auction the specified token.");
        if (startTime == 0) {
            startTime = block.timestamp;
        }
        auction = address(new PublicAuction(target, tokenId, startPrice, startTime, bidPeriod, beneficiary));

        address owner = IERC721(target).ownerOf(tokenId);
        IERC721(target).transferFrom(owner, auction, tokenId);

        if (uid == 0) {
            uid = uint256(keccak256(bytes.concat(bytes20(auction))));
        }

        auctions[target][tokenId] = auction;
        all.set(auction, uid);
        current.set(auction, uid);

        if (bytes(remark).length > 0) {
            remarks[auction] = remark;
        }
        uids[uid] = auction;

        uint endTime = startTime + bidPeriod;
        emit AuctionOpen(auction, target, tokenId, startPrice, startTime, endTime, beneficiary, msg.sender);
        return auction;
    }

    function getAuctionByUID(uint256 uid) public view returns (address) {
        return uids[uid];
	}

    function getAuctionFor(address target, uint256 tokenId) public view returns (address) {
        return auctions[target][tokenId];
	}

    function getAuctionRemark(address auction) public view returns (string memory) {
        return remarks[auction];
    }

    function getAuctionUID(address auction) public view returns (uint256) {
        return all.get(auction);
	}

    function getCurrentAuctionsNumber() public view returns (uint256) {
        return current.size();
    }

    function getCurrentAuctionByIndex(uint256 index) public view returns (address) {
        return current.getKeyAtIndex(index);
    }

    function getAuctionsNumber() public view returns (uint256) {
        return all.size();
    }

    function getAuctionByIndex(uint256 index) public view returns (address) {
        return all.getKeyAtIndex(index);
	}
}