/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

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


contract AuctionRoom {
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address winner, uint amount);

    IERC721 public nft;
    uint public nftId;

    address payable public seller;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    uint public floorPrice;

    uint public startTime;
    uint public endTime;

    mapping(address => uint) public withdrawAmount;

    constructor(
        address _seller,
        address _nft,
        uint _nftId,
        uint _floorPrice,
        uint _startTime,
        uint _endTime
    ) {
        nft = IERC721(_nft);
        nftId = _nftId;

        seller = payable(_seller);
        highestBid = _floorPrice;
        floorPrice = _floorPrice;

        startTime = _startTime;
        endTime = _endTime;
    }

    function start() public {
        require(!started, "Already started");
        started = true;

        // require(msg.sender has perms)
        nft.transferFrom(seller, address(this), nftId);
    }

    function isRunning() public view returns(bool) {
        uint currentTime = block.timestamp;
        return startTime <= currentTime && currentTime < endTime;
    }

    function bid() external payable {
        require(started, "Hasn't started");
        require(isRunning(), "not running");
        require(msg.sender != seller, "original seller can't bid");

        if (highestBidder == msg.sender) {
            highestBid += msg.value;
            emit Bid(msg.sender, highestBid);
        } else {
            uint overallBid = withdrawAmount[msg.sender] + msg.value;
            require(overallBid > highestBid, "overall bid <= highest");

            if (highestBidder != address(0)) {
                withdrawAmount[highestBidder] = highestBid;
            }

            withdrawAmount[msg.sender] = 0;
            highestBidder = msg.sender;
            highestBid = overallBid;
            emit Bid(msg.sender, overallBid);
        }
    }

    function withdraw() external {
        uint bal = withdrawAmount[msg.sender];
        withdrawAmount[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: bal}("");
        require(success);

        emit Withdraw(msg.sender, bal);
    }

    function withdrawNFT() external {
        require(msg.sender == seller);
        nft.transferFrom(address(this), seller, nftId);
    }

    function end() external {
        require(started, "Hasn't started");
        require(!isRunning(), "Still running");
        require(!ended, "Already ended");

        ended = true;
        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            (bool success,) = payable(msg.sender).call{value: highestBid}("");
            require(success);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);
    }
}

contract AuctionHouse is KeeperCompatibleInterface {
    event AuctionRoomCreated(address seller, address roomAddress);

    struct RoomInfo {
        uint roomId;
        address _room;
    }

    uint numberOfRooms = 0;
    mapping (address => RoomInfo[]) public idToRoomArray;
    address[] rooms;

    function createNewRoom(
        uint _roomId,
        address _nft,
        uint _nftId,
        uint _floorPrice,
        uint _startTime,
        uint _endTime
    ) public {
        require(_startTime < _endTime, "Start time should be less than end time!");

        AuctionRoom newRoom = new AuctionRoom(
            msg.sender, _nft, _nftId, _floorPrice, _startTime, _endTime
        );

        numberOfRooms += 1;

        RoomInfo memory roomInfo = RoomInfo(_roomId, address(newRoom));
        idToRoomArray[msg.sender].push(roomInfo);
        
        rooms.push(address(newRoom));

        emit AuctionRoomCreated(msg.sender, address(newRoom));
    }

    function checkUpkeep(bytes calldata checkData) external view override 
        returns (bool upkeepNeeded, bytes memory performData) {

        uint countToBeStarted = 0;
        uint countToBeEnded = 0;

        for (uint i = 0; i < rooms.length; i++) {
            AuctionRoom currentRoom = AuctionRoom(rooms[i]);
            if (!currentRoom.started() && currentRoom.startTime() <= block.timestamp + 60 seconds) {
                countToBeStarted += 1;
            } else if (!currentRoom.ended() && block.timestamp >= currentRoom.endTime() + 60 seconds) {
                countToBeEnded += 1;
            }
        }

        uint[] memory toBeStarted = new uint[](countToBeStarted);
        uint[] memory toBeEnded = new uint[](countToBeEnded);

        for (uint i = 0; i < rooms.length; i++) {
            AuctionRoom currentRoom = AuctionRoom(rooms[i]);
            if (!currentRoom.started() && currentRoom.startTime() <= block.timestamp + 60 seconds) {
                countToBeStarted -= 1;
                toBeStarted[countToBeStarted] = i;
            } else if (!currentRoom.ended() && block.timestamp >= currentRoom.endTime() + 60 seconds) {
                countToBeEnded -= 1;
                toBeEnded[countToBeEnded] = i;
            }
        }

        upkeepNeeded = toBeStarted.length > 0 || toBeEnded.length > 0;
        performData = abi.encode(toBeStarted, toBeEnded);
    }

    function performUpkeep(bytes calldata performData) external override {
        (uint[] memory toBeStarted, uint[] memory toBeEnded) = abi.decode(performData, (uint[], uint[]));

        for (uint i = 0; i < toBeStarted.length; i++) {
            AuctionRoom(rooms[toBeStarted[i]]).start();
        }

        for (uint i = 0; i < toBeEnded.length; i++) {
            AuctionRoom(rooms[toBeEnded[i]]).end();
        }
    }
}