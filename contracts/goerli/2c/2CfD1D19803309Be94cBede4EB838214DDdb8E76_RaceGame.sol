/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT
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


// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

// contract RaceGame is VRFConsumerBase {
contract RaceGame {
    event RaceFull(uint raceId);
    event RaceComplete(uint raceId, address winner, uint amount);
    
    struct Race {
        uint id;
        string eventName;
        uint status; // 0 initialized, 1 complete, 2 finished
        address[] players;
        uint maxPlayers;
        uint entryFee;
        bool started;
        address winner;
        uint nftWinner;
        uint distance;
    }
    
    uint public raceCounter;
    mapping(uint => Race) public races;
    mapping(address => uint) public balances;
    mapping(address => bool) public racePlayers;
    mapping(uint => uint) public countNftWinnings; // receive an nft id, and return cant of winnings
    mapping(uint => uint) public countNftPoints;
    mapping (uint => mapping (address => uint)) raceAddressNft;

    mapping(uint => uint) public xpForRacers;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    address public owner;
    uint public commission;
    address public tokenNft;

    // constructor(address vrfCoordinator, address link, bytes32 _keyHash, uint256 _fee, address _tokenNft)
    //     VRFConsumerBase(vrfCoordinator, link)
    // {
    //     keyHash = _keyHash;
    //     fee = _fee;
    //     owner = msg.sender;
    //     commission = 10;
    //     nftCollection = IERC721(_tokenNft);
    //     xpForRacers[1] = 100;
    //     xpForRacers[2] = 50;
    //     xpForRacers[3] = 25;
    // }

    constructor(address _tokenNft)
    {
        owner = msg.sender;
        commission = 4;
        tokenNft = _tokenNft;
        xpForRacers[1] = 100;
        xpForRacers[2] = 50;
        xpForRacers[3] = 25;
    }
    
    function createRace(uint _maxPlayers, uint _entryFee, uint _distance, string memory _eventName, uint _nftId) public payable {
        require(_maxPlayers > 0, "Max players must be greater than 0");
        require(_entryFee > 0, "Entry fee must be greater than 0");
        require(_entryFee >= msg.value, "Value sent has to be greater than 0");
        if (_nftId > 0) {
            require(IERC721(tokenNft).ownerOf(_nftId) == msg.sender, "You don't own this NFT");
        }

        raceCounter++;
        races[raceCounter] = Race(raceCounter, _eventName, 0, new address[](0), _maxPlayers, _entryFee, false, address(0), 0, _distance);
        joinRace(raceCounter, _nftId);
    }
    
    function joinRace(uint _raceId, uint _nftId) public payable {
        require(_raceId > 0 && _raceId <= raceCounter, "Invalid race ID");
        require(!races[_raceId].started, "Race has already started");
        require(races[_raceId].players.length < races[_raceId].maxPlayers, "Race is already full");
        require(msg.value == races[_raceId].entryFee, "Entry fee is incorrect");
        require(!racePlayers[msg.sender], "Already joined the race");
        if (_nftId > 0) {
            require(IERC721(tokenNft).ownerOf(_nftId) == msg.sender, "You don't own this NFT");
            raceAddressNft[_raceId][msg.sender] = _nftId;
        }

        races[_raceId].players.push(msg.sender);
        racePlayers[msg.sender] = true;
        if (races[_raceId].players.length == races[_raceId].maxPlayers) {
            startRace(_raceId);
            emit RaceFull(_raceId);
        }
    }

    // function getRandomNumber() public returns (bytes32 requestId) {
    //     // require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to fulfill request");
    //     return requestRandomness(keyHash, fee);
    // }

    //  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    //     randomResult = randomness;
    // }
    
    function startRace(uint _raceId) internal {
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

        // Sustitute for chainlink
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % races[_raceId].players.length;
        // require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK to fulfill request");
        // requestRandomness(keyHash, fee);
        // uint randomIndex = randomResult % races[_raceId].players.length;
        

        // Define winner
        races[_raceId].winner = races[_raceId].players[randomIndex];
        races[_raceId].nftWinner = raceAddressNft[_raceId][races[_raceId].players[randomIndex]];

        // Add points and winner race
        countNftWinnings[races[_raceId].nftWinner] = countNftWinnings[races[_raceId].nftWinner] + 1;
        countNftPoints[races[_raceId].nftWinner] = countNftPoints[races[_raceId].nftWinner] + xpForRacers[1];

        //Define second
        address secondAddress = races[_raceId].players[randomIndex + 1 & races[_raceId].players.length];
        uint nftSecondPlace = raceAddressNft[_raceId][secondAddress];
        // Add points to second
        countNftPoints[nftSecondPlace] = countNftPoints[nftSecondPlace] + xpForRacers[2];

        //Define Third
        if (races[_raceId].players.length > 2) {
            // Add points to third one
            address thirdAddress = races[_raceId].players[randomIndex + 1 & races[_raceId].players.length];
            uint nftThirdPlace = raceAddressNft[_raceId][thirdAddress];
            countNftPoints[nftThirdPlace] = countNftPoints[nftThirdPlace] + xpForRacers[3];
        }

        races[_raceId].status = 2;

        uint totalPrize = races[_raceId].entryFee * races[_raceId].players.length;
        uint commisionOfRaceDividend = totalPrize * commission;
        uint commisionOfRace = commisionOfRaceDividend / totalPrize;

        balances[races[_raceId].winner] = totalPrize - commisionOfRace;
        emit RaceComplete(_raceId, races[_raceId].winner, totalPrize - commisionOfRace);
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

    function getRacesIdByStatus(uint _status) public view returns (uint[] memory) {
        require(_status >= 0 && _status <= 3, "Invalid race status");
        uint[] memory racesByStatus;
        uint count = 0;
        for (uint i = 0; i < raceCounter; i++) {
            if (races[i].status == _status) {
                racesByStatus[count] = races[i].status;
                count++;
            }
        }
        
        return racesByStatus;
    }

    function getNFTForRaceAndUser(uint256 _raceId, address _userId) public view returns (uint) {
        return raceAddressNft[_raceId][_userId];
    }

    function setXpForRacers(uint index, uint value) public onlyOwner {
        xpForRacers[index] = value;
    }

    function setTokenNft(address _tokenNft) public onlyOwner {
        tokenNft = _tokenNft;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }
    
    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdraw_tokens(address _addy) public onlyOwner {
        bool approve_done = IERC20(_addy).approve(address(this), IERC20(_addy).balanceOf(address(this)));
        require(approve_done, "CA cannot approve tokens");
        require(IERC20(_addy).balanceOf(address(this)) > 0, "No tokens");
        IERC20(_addy).transfer(msg.sender, IERC20(_addy).balanceOf(address(this)));
    }
}