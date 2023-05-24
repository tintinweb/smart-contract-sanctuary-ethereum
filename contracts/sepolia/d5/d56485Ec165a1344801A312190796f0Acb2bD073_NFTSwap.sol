// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Aggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract NFTSwap is ERC721Holder, Ownable {
    uint256 public swapId ;
    address public Nftaddress;
    uint256 public swappingFees = 1 * (10**10);

    // ETH <-> USD : 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e for Goerli
    // ETH <-> USD : 0x694AA1769357215DE4FAC081bf1f309aDC325306 for Sepolia

    address public dataOracle = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
    uint256 max_NFT = 5;
    uint public swapCount;


    struct Swap {
        address sender;
        address[] senderNftAddress;
        uint256[] senderNFTId;
        uint256[] senderPrice;
        address recipient;
        address[] recipientNftAddress;
        uint256[] recipientNFTId;
        uint256[] recipientPrice;
        uint256 startTime;
        uint256 endTime;
        bool active;
        bool swapComplete;
    }

    event InitiateSwap(
        uint256 swapId,
        address indexed sender,
        address[] senderNftAddress,
        uint256[] senderNFTId,
        uint256[] senderPrice,
        uint256 startTime,
        uint256 endTime
    );

    event SetRecipientDetails(
        uint256 swapId,
        address indexed recipient,
        address[] recipientNftAddress,
        uint256[] recipientNFTId,
        uint256[] recipientPrice
    );

    event SwapCompleted(
        uint256 swapId,
        address indexed sender,
        address indexed recipient,
        uint256[] senderNFTId,
        uint256[] recipientNFTId
    );

    event SwapCancel(
        uint256 swapId,
        address indexed sender,
        address indexed recipient,
        uint256[] senderNFTId,
        uint256[] recipientNFTId
    );

    mapping(uint256 => Swap) public swaps;

    modifier checkEndTime(uint256 _swapId) {
        require(
            block.timestamp < swaps[_swapId].endTime,
            "Swap Time has Expired"
        );
        _;
    }

    modifier checkSwapInitiator(uint256 _swapId) {
        require(
            swaps[_swapId].sender == msg.sender,
            "You're not a Swap Initiator"
        );
        _;
    }   

    function changeDataOracle(address _dataOracle) public onlyOwner {
        dataOracle = _dataOracle;
    }

    function getLatestEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = Aggregator(dataOracle).latestRoundData();
        int256 _price = (price * (10 * 10));
        return uint256(_price);
    }

    function changeSwappingFees(uint256 _newFees) public onlyOwner {
        swappingFees = (_newFees * (10**10)) / (10**18);
    }

    function getFees() public view returns (uint256 _price) {
        return
            _price =
                (((uint256(swappingFees) * (10**10)) / getLatestEthPrice()) *
                    (10**18)) /
                10**10;
    }

    function changeNftAddress(address newNftAddress) public onlyOwner {
        Nftaddress = newNftAddress;
    }

    function changeMaxNft(uint256 newMaxNft) public onlyOwner {
        max_NFT = newMaxNft;
    }

    function initiateSwap(
        address[] memory _senderNftAddress,
        uint256[] memory _senderPrice,
        uint256[] memory _senderNFTId,
        uint256 _endTimeOfSwapping
    ) public payable returns (uint256) {
        require(
            _senderNftAddress.length > 0 && _senderNftAddress.length <= max_NFT,
            "Invalid number of sender NFT addresses"
        );
        require(
            _senderNftAddress.length == _senderNFTId.length && _senderNftAddress.length == _senderPrice.length,
            "Mismatch in sender NFT details"
        );
        require(
            _endTimeOfSwapping > block.timestamp + 3 minutes,
            "End time should be at least 3 minutes in the future"
        );

        require(_senderNftAddress.length != 0, "Invalid sender NFT address");

        require(
            msg.value >= getFees(),
            "Please send the correct swapping fees amount"
        );

        for (uint256 i = 0; i < _senderNFTId.length; i++) {
            IERC721(_senderNftAddress[i]).transferFrom(
                msg.sender,
                address(this),
                _senderNFTId[i]
            );

        }

        swapId++;

        Swap memory senderData = Swap({
            sender: msg.sender,
            senderNftAddress: _senderNftAddress,
            senderNFTId: _senderNFTId,
            senderPrice: _senderPrice,
            recipient: address(0),
            recipientNftAddress: new address[](0),
            recipientNFTId: new uint256[](0),
            recipientPrice: new uint256[](0),
            startTime: block.timestamp,
            endTime: _endTimeOfSwapping,
            active: true,
            swapComplete: false
        });

        swaps[swapId] = senderData;

        emit InitiateSwap(
            swapId,
            msg.sender,
            _senderNftAddress,
            _senderNFTId,
            _senderPrice,
            block.timestamp,
            _endTimeOfSwapping
        );

        return swapId;
    }

    function getStuctData(uint256 _swapId) public view returns (Swap memory) {
        Swap memory swapData;
        swapData.sender = swaps[_swapId].sender;
        swapData.senderNftAddress = swaps[_swapId].senderNftAddress;
        swapData.senderNFTId = swaps[_swapId].senderNFTId;
        swapData.senderPrice = swaps[_swapId].senderPrice;
        swapData.recipient = swaps[_swapId].recipient;
        swapData.recipientNftAddress = swaps[_swapId].recipientNftAddress;
        swapData.recipientNFTId = swaps[_swapId].recipientNFTId;
        swapData.recipientPrice = swaps[_swapId].recipientPrice;
        swapData.startTime = swaps[_swapId].startTime;
        swapData.endTime = swaps[_swapId].endTime;
        swapData.active = swaps[_swapId].active;
        swapData.swapComplete = swaps[_swapId].swapComplete;
        return swapData;
    }
    
    function setRecipientNFT(
        uint256 _swapId,
        address[] memory _recipientNftAddress,
        uint256[] memory _recipientNFTId,
        uint256[] memory _recipientPrice
    )
        public
        checkEndTime(_swapId)
    {
        require(
            _recipientNftAddress.length > 0 &&
            _recipientNftAddress.length <= max_NFT,
            "Recipient NFT addresses cannot be more than 5"
        );
        require(
            swaps[_swapId].sender != msg.sender,
            "You can't Make a swap for your own NFT"
        );
        require(swaps[_swapId].active == true, "Swap is not initiated");
        require(
            swaps[_swapId].recipient == address(0),
            "Offer for swap has already been made to this NFT, try again later"
        );
        

        for (uint256 i = 0; i < _recipientNFTId.length; i++) {
            IERC721(_recipientNftAddress[i]).transferFrom(
                msg.sender,
                address(this),
                _recipientNFTId[i]
            );

            swaps[_swapId].recipientNftAddress.push(_recipientNftAddress[i]);
            swaps[_swapId].recipientNFTId.push(_recipientNFTId[i]);
            swaps[_swapId].recipientPrice.push(_recipientPrice[i]);
        }

        swaps[_swapId].recipient = msg.sender;
        swaps[_swapId].recipientNftAddress = _recipientNftAddress;
        swaps[_swapId].recipientNFTId = _recipientNFTId;
        swaps[_swapId].recipientPrice = _recipientPrice;
        
        
        emit SetRecipientDetails(
            _swapId, 
            msg.sender, 
            _recipientNftAddress,
            _recipientNFTId,
            _recipientPrice
            );
    }


    function completeSwap(uint256 _swapId)
        public
        checkSwapInitiator(_swapId)
    {
        require(
            swaps[_swapId].recipient != address(0),
            "No one has made any swap request yet"
        );
        require(swaps[_swapId].recipientNFTId.length > 0, "Recipient NFT not set");
        
        for (uint256 i = 0; i < swaps[_swapId].recipientNFTId.length; i++) {
            require(swaps[_swapId].recipientNFTId[i] > 0, "Recipient NFT not set");
        }
        
        require(swaps[_swapId].active == true, "Swap is not initiated");
        require(
            swaps[_swapId].swapComplete == false,
            "Swap for this NFT has already completed"
        );
        
        uint256[] memory recipientNFTIds = swaps[_swapId].recipientNFTId;
        address[] memory recipientNftAddress = swaps[_swapId].recipientNftAddress;
        for (uint256 i = 0; i < recipientNFTIds.length; i++) {
            IERC721(recipientNftAddress[i]).transferFrom(
                address(this),
                msg.sender,
                recipientNFTIds[i]
            );
        }
        
        
        uint256[] memory senderNFTIds = swaps[_swapId].senderNFTId;
        address[] memory senderNftAddress = swaps[_swapId].senderNftAddress;
        for (uint256 i = 0; i < senderNFTIds.length; i++) {
            IERC721(senderNftAddress[i]).transferFrom(
                address(this),
                swaps[_swapId].recipient,
                senderNFTIds[i]
            );
        }
        
        swaps[_swapId].active = false;
        swaps[_swapId].swapComplete = true;
        
        emit SwapCompleted(
            _swapId,
            swaps[_swapId].sender,
            swaps[_swapId].recipient,
            senderNFTIds,
            recipientNFTIds
        );
    }


    function cancelSwapAndClaimNFTBack(uint256 _swapId) public {
        uint256[] memory senderNFTIds = swaps[_swapId].senderNFTId;
        uint256[] memory recipientNFTIds = swaps[_swapId].senderNFTId;
        uint256[] memory recipientPrices = swaps[_swapId].recipientPrice;
        address[] memory recipientNftAddress = swaps[_swapId].recipientNftAddress;   

        if (msg.sender == swaps[_swapId].sender) {
            require(
                swaps[_swapId].swapComplete == false,
                "Swap is completed, you can't cancel now"
            );

            address[] memory senderNftAddress = swaps[_swapId].senderNftAddress;
            for (uint256 i = 0; i < senderNFTIds.length; i++) {
            IERC721(senderNftAddress[i]).transferFrom(
                address(this),
                swaps[_swapId].sender,
                senderNFTIds[i]
            );
            }
            if (swaps[_swapId].recipient != address(0)) {
            
            for (uint256 i = 0; i < recipientNFTIds.length; i++){
                IERC721(recipientNftAddress[i]).transferFrom(
                    address(this),
                    swaps[_swapId].recipient,
                    recipientNFTIds[i]
                );
            }

                require(address(this).balance >= swaps[_swapId].recipientPrice[0], "Insufficient contract balance");
                payable(msg.sender).transfer(swaps[_swapId].recipientPrice[0]);
            }
            swaps[_swapId].active = false;
        } else if (msg.sender == swaps[_swapId].recipient) {
            require(
                swaps[_swapId].swapComplete == false,
                "Swap is completed, you can't cancel now"
            );
            for (uint256 i = 0; i < recipientNFTIds.length; i++){
                    IERC721(Nftaddress).transferFrom(
                        address(this),
                        swaps[_swapId].recipient,
                        recipientNFTIds[i]
                    );
            }
            require(address(this).balance >= swaps[_swapId].senderPrice[0], "Insufficient contract balance");
            payable(swaps[_swapId].recipient).transfer(swaps[_swapId].senderPrice[0]);

            swaps[_swapId].recipient = address(0);
            recipientNFTIds[0];
            recipientNftAddress[0];
            recipientPrices[0];
        }else{
            require(false,"You're neither an Initiator nor a receiver for this swap");
        }
        emit SwapCancel(
            swapId,
            swaps[_swapId].sender,
            swaps[_swapId].recipient,
            senderNFTIds,
            recipientNFTIds
        );
    }

    function rejectSwap(uint256 _swapId)
        public
        checkSwapInitiator(_swapId)
        {
            require(
                swaps[_swapId].sender == msg.sender,
                "You are not the Swap Initiator of this swap"
            );
            require(
                swaps[_swapId].swapComplete == false,
                "Swap is completed, you can't cancel now"
            );
            uint256[] memory recipientNFTIds = swaps[_swapId].recipientNFTId;
            uint256[] memory recipientPrices = swaps[_swapId].recipientPrice;
            address[] memory recipientNftAddress = swaps[_swapId].recipientNftAddress;

            for (uint256 i = 0; i < recipientNFTIds.length; i++){
                IERC721(recipientNftAddress[i]).transferFrom(
                    address(this),
                    swaps[_swapId].recipient,
                    recipientNFTIds[i]
                );
            }
            require(address(this).balance >= swaps[_swapId].senderPrice[0], "Insufficient contract balance");
            payable(swaps[_swapId].recipient).transfer(swaps[_swapId].senderPrice[0]);

            swaps[_swapId].recipient = address(0);
            recipientNFTIds[0];
            recipientPrices[0];
        }

    function fetchAllSwaps() public view returns (Swap[] memory) {
        Swap[] memory allSwaps = new Swap[](swapCount); 

        for (uint i = 0; i < swapCount; i++) {
            allSwaps[i] = swaps[i];
        }

        return allSwaps;
    }

    function fetchMySwaps() external view returns (Swap[] memory) {
        Swap[] memory mySwaps = new Swap[](swapCount);
        
        uint256 mySwapCount = 0;

        for (uint256 i = 0; i < swapCount; i++) {
            if (swaps[i].sender == msg.sender || swaps[i].recipient == msg.sender) {
                mySwaps[mySwapCount] = swaps[i];
                mySwapCount++;
            }
        }
        
        assembly {
            mstore(mySwaps, mySwapCount)
        }
        
        return mySwaps;
    }

    function withDrawAmount() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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