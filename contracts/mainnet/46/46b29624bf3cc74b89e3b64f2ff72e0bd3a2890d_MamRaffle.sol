/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/MamRaffle.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;





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

abstract contract ERC165 is IERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(type(IERC165).interfaceId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}



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

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



contract MamRaffle {

    IERC20 public ammo;

   
    
    //_tokenIds variable has the most recent minted tokenId
    uint256 public count = 0;
    uint256 public itemsSold = 0;
    //Keeps track of the number of items sold on the marketplace
    
    //owner is the contract address that created the smart contract
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    
    
    

    //The structure to store info about a listed token
    struct ListedToken {
        uint256 listId;
        uint256 tokenId;
        address nft;
        uint256 price;
        address [] players;
        uint256 playerCount;
        uint256 endTime;
        address winner;
        bool winnerSelected;
        bool currentlyListed;
    }

    event TimeReset (uint256, uint256);
    event BulkRaffle (uint256);

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed listId,
        uint256 price,
        uint256 endTime,
        bool currentlyListed
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;
    mapping(uint256 => ListedToken) public listIds;
    uint256 [] public activeList;
    

    constructor(address _ammo){
        owner = payable(msg.sender);
        ammo = IERC20(_ammo);
       
       
    }


    function getOwner() external view returns (address) {
        return owner;
    }

    function getTotalListed() public view returns (uint256) {
        return count - itemsSold;
    }

    


    
    
    function createListedToken(address _nft, uint256 tokenId, uint256 _price, uint256 _endTime) external {
        require(msg.sender == owner, "Not authorized to list");
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the token owner or invalid tokenId");
        require(block.timestamp + _endTime > block.timestamp, "Invalid time entry");
        

        
        uint256 listId = count + 1;
        
       
        
        uint256 endTime = block.timestamp + _endTime;
        address [] memory players;
        
           

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        listIds[listId] = ListedToken(
            listId,
            tokenId,
            _nft,
            _price,
            players,
            0,
            endTime,
            address(0),
            false,
            true
        );
        

        nft.transferFrom(msg.sender, address(this), tokenId);
        count++;
        activeList.push(listId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            listId,
            _price,
            endTime,
            true
        );
    }


    function bulkRaffleCreate(address[] calldata _nft, uint256[] calldata tokenId, uint256[] calldata _price, uint256[] calldata _endTime) external {
        require(msg.sender == owner, "Not authorized to list");
        uint256 endTime;
        

        for(uint8 i; i < _nft.length; i++) {
            IERC721 nft = IERC721(_nft[i]);
        require(nft.ownerOf(tokenId[i]) == msg.sender, "Not the token owner or invalid tokenId");
        require(block.timestamp + _endTime[i] > block.timestamp, "Invalid time entry");

        uint256 listId = count + 1;
       
        
        endTime = block.timestamp + _endTime[i];
        address [] memory players;
        
        listIds[listId] = ListedToken(
            listId,
            tokenId[i],
            _nft[i],
            _price[i],
            players,
            0,
            endTime,
            address(0),
            false,
            true
        );
        

        nft.transferFrom(msg.sender, address(this), tokenId[i]);
        count++;
        activeList.push(listId);

        }

        emit BulkRaffle(_nft.length);

    }
/*
    function getAllNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = count;
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        uint currentId;
        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=0;i<nftCount;i++)
        {
            currentId = i;
            ListedToken storage currentItem = idToListedToken[currentId];
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
            
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }



    
    //This will return all the NFTs currently listed to be sold on the marketplace
    function getListedNFTs() public view returns (ListedToken[] memory) {
        uint nftCount = _tokenIds.current();
        ListedToken[] memory tokens = new ListedToken[](nftCount);
        uint currentIndex = 0;
        uint currentId;
        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=0;i<nftCount;i++)
        {
             currentId = i;
            if(idToListedToken[currentId].currentlyListed == true) {
                ListedToken storage currentItem = idToListedToken[currentId];
           
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
            }
        }
        //the array 'tokens' has the list of all NFTs in the marketplace
        return tokens;
    }*/

    function getActiveListIds() public view returns (uint256[] memory) {
        uint256 nftCount = getTotalListed();
        uint256[] memory tokens = new uint256[](nftCount);
        uint256 currentIndex = 0;

        for(uint8 i = 0; i< activeList.length; i++) {
            if(activeList[i] != 0){
                tokens[currentIndex] = activeList[i];
                currentIndex++;
            }
        }


        return tokens;
    }

/*
    function getActiveListIds() public view returns (uint256[] memory) {
        uint nftCount = count;
        uint256[] memory tokens = new uint256[](nftCount);

        uint currentIndex = 0;
        uint currentId;
        
        //at the moment currentlyListed is true for all, if it becomes false in the future we will 
        //filter out currentlyListed == false over here
        for(uint i=0;i<nftCount;i++)
        {
             currentId = i;
            if(listIds[currentId].currentlyListed == true) {
                uint256 currentItem = listIds[currentId].listId;
           
            tokens[currentIndex] = currentItem;
            currentIndex += 1;
            }
        }
        
        
        return tokens;
    }*/
    
    



    function getEndTime(uint256 listId) public view returns (uint256) {
        return listIds[listId].endTime;
    }

    function getWinner(uint256 listId) public view returns (address) {
        return listIds[listId].winner;
    }

    function isWinnerSelected(uint256 listId) public view returns (bool) {
        return listIds[listId].winnerSelected;
    }

    function getPlayerCount(uint256 listId) public view returns (uint256) {
        return listIds[listId].playerCount;
    }

    function getPrice(uint256 listId) public view returns (uint256) {
        return listIds[listId].price;
    }

    function getPlayers(uint256 listId) public view returns (address[] memory) {
        return listIds[listId].players;
    }

 

    function getTrueTokenID(uint256 listId) public view returns (uint256){
        return listIds[listId].tokenId;
    }


    function getContract(uint256 listId) public view returns (address){
        return listIds[listId].nft;
    }

    function enterRaffle(uint256 listId, address _player) external {
        uint256 price = listIds[listId].price;
        require(msg.sender == _player, "Cannot enter someone else");
        require(listId <= count, "ListId does not exist or raffle has not started");
        require(block.timestamp < listIds[listId].endTime, "Raffle has already ended");
        require(ammo.balanceOf(msg.sender) >= price, "Insufficient Ammo balance");
        listIds[listId].players.push(_player);
        listIds[listId].playerCount++;
        ammo.transferFrom(msg.sender, owner, price);
    }

    function pickWinner(uint256 listId, uint256 pos) external {
        require(msg.sender == owner, "Not authorized to select winner");
        require(listId <= count, "ListId does not exist or raffle has not started");
        listIds[listId].winner = listIds[listId].players[pos];
        listIds[listId].winnerSelected = true;

    }

    function claim(uint256 listId) external {
        require(msg.sender == listIds[listId].winner, "Not the winner");

        listIds[listId].currentlyListed = false;
        //idToListedToken[tokenId].seller = msg.sender;
        itemsSold++;
        for(uint8 i = 0; i < activeList.length; i++) {
            if(activeList[i] == listId) {
                delete activeList[i];
            }
        }

        IERC721 nft = IERC721(getContract(listId));

        //Actually transfer the token to the new owner
        nft.transferFrom(address(this), msg.sender, listIds[listId].tokenId);
        

    }

    function resetTime(uint256 listId, uint256 _newEndTime) external {
        require(msg.sender == owner, "Not authorized to select winner");
        uint256 newEndTime = block.timestamp + _newEndTime;
        listIds[listId].endTime = newEndTime;

        emit TimeReset(listId, newEndTime);

    }

    function setAmmoAddress(address _newAddress) external {
        require(msg.sender == owner, "Not authorized to trigger this function");
        ammo = IERC20(_newAddress);
    }

    function emergencyTokenWithdraw() external {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        uint256 balance = ammo.balanceOf(address(this));
        ammo.transfer(msg.sender, balance );
    }

    function emergencyNFTWithdraw(uint256[] calldata _listIds) external {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        IERC721 nft;
        for(uint8 i = 0; i < _listIds.length; i++) {
            nft = IERC721(getContract(_listIds[i]));
            nft.transferFrom(address(this), msg.sender, getTrueTokenID(_listIds[i]));
            listIds[_listIds[i]].currentlyListed = false;
            itemsSold++;
            for(uint8 j = 0; j < activeList.length; j++) {
            if(activeList[j] == _listIds[i]) {
                delete activeList[j];
            }
        }
            


        }
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == owner, "Not authorized to transfer ownership");
        require(_newOwner != address(0), "Cannot transfer ownership to the zero address");
        owner = payable(_newOwner);
    }

    //This is to remove the native currency of the network (e.g. ETH, BNB, MATIC, etc.)
    function emergencyWithdraw() public {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

     receive() external payable {}
    



    

    
}