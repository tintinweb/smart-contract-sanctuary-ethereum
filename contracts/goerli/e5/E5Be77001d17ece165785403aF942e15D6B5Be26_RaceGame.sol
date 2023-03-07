/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: RaceGame.sol


pragma solidity ^0.8.16;

contract RaceGame {
    
    struct Race {
        uint id;
        string eventName;
        uint status; // 0 initialized, 1 complete, 2 finished
        address[] players;
        uint maxPlayers;
        uint entryFee;
        bool started;
        address winner;
        uint distance;
    }
    
    uint public raceCounter;
    mapping(uint => Race) public races;
    mapping(address => uint) public balances;
    mapping(address => bool) public racePlayers;
    address public owner;
    uint public commission;
    IERC721 nftCollection;
    
    constructor(address _tokenNft) {
        owner = msg.sender;
        commission = 10;
        nftCollection = IERC721(_tokenNft);
    }
    
    function createRace(uint _maxPlayers, uint _entryFee, uint _distance, string memory _eventName) public payable {
        require(_maxPlayers > 0, "Max players must be greater than 0");
        require(_entryFee > 0, "Entry fee must be greater than 0");
        require(_entryFee >= msg.value, "Value sent has to be greater than 0");
        raceCounter++;
        races[raceCounter] = Race(raceCounter, _eventName, 1, new address[](0), _maxPlayers, _entryFee, false, address(0), _distance);
        joinRace(raceCounter);
    }
    
    function joinRace(uint _raceId) public payable {
        require(nftCollection.balanceOf(msg.sender) > 0, "Needs to hold an NFT");
        require(_raceId > 0 && _raceId <= raceCounter, "Invalid race ID");
        require(!races[_raceId].started, "Race has already started");
        require(races[_raceId].players.length < races[_raceId].maxPlayers, "Race is already full");
        require(msg.value == races[_raceId].entryFee, "Entry fee is incorrect");
        require(!racePlayers[msg.sender], "Already joined the race");
        races[_raceId].players.push(msg.sender);
        racePlayers[msg.sender] = true;
    }
    
    function startRace(uint _raceId) public onlyOwner {
        require(_raceId > 0 && _raceId <= raceCounter, "Invalid race ID");
        require(!races[_raceId].started, "Race has already started");
        require(races[_raceId].players.length == races[_raceId].maxPlayers, "Race is not full");
        races[_raceId].started = true;
        races[_raceId].status = 1;
    }
    
    function completeRace(uint _raceId) public onlyOwner {
        require(_raceId > 0 && _raceId <= raceCounter, "Invalid race ID");
        require(races[_raceId].started, "Race has not started yet");
        require(races[_raceId].winner == address(0), "Race winner has already been determined");
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % races[_raceId].players.length;
        races[_raceId].winner = races[_raceId].players[randomIndex];
        races[_raceId].status = 2;

        uint totalPrize = races[_raceId].entryFee * races[_raceId].players.length;
        uint commisionOfRaceDividend = totalPrize * commission;
        uint commisionOfRace = commisionOfRaceDividend / totalPrize;

        balances[races[_raceId].winner] = totalPrize - commisionOfRace;
    }

    // Helpers
    function getRace(uint _raceId) public view returns (Race memory) {
        return races[_raceId];
    }

    function setCommission(uint _commission) public onlyOwner {
        commission = _commission;
    }

    function claim() public  {
        require(balances[msg.sender] > 0, "User doesnt have funds");
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function getRacesByStatus(Race[] memory _races, uint _status) pure external returns (Race[] memory) {
        require(_status >= 0 && _status <= 3, "Invalid race status");
        Race[] memory racesByStatus = new Race[](_races.length);
        uint count = 0;
        for (uint i = 0; i < _races.length; i++) {
            if (_races[i].status == _status) {
                racesByStatus[count] = _races[i];
                count++;
            }
        }
        Race[] memory result = new Race[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = racesByStatus[i];
        }
        return result;
    }

    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
    
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}