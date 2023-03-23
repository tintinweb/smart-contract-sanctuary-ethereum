/* solhint-disable max-states-count */
/* solhint-disable ordering */
/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-unused-vars */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {MerkleProofUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol';
import {ECDSAUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import {IERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import {AddressUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import {IAtlanteans} from '../interfaces/IAtlanteans.sol';
import {IWETH} from '../interfaces/IWETH.sol';

/**
 * ▄▀█ ▀█▀ █░░ ▄▀█ █▄░█ ▀█▀ █ █▀   █░█░█ █▀█ █▀█ █░░ █▀▄
 * █▀█ ░█░ █▄▄ █▀█ █░▀█ ░█░ █ ▄█   ▀▄▀▄▀ █▄█ █▀▄ █▄▄ █▄▀
 *
 *
 * Atlantis World is building the Web3 social metaverse by connecting Web3 with social,
 * gaming and education in one lightweight virtual world that's accessible to everybody.
 *
 * @title AtlanteansSale
 * @author Carlo Miguel Dy, Rachit Anand Srivastava
 * @dev Implements the Ducth Auction for Atlanteans Collection, code is exact same from Forgotten Runes.
 */
contract AtlanteansSale is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    struct InitializerArgs {
        address atlanteans;
        address treasury;
        address weth;
        address server;
        uint256 mintlistStartTime;
        uint256 daStartTime;
        uint256 publicStartTime;
        uint256 publicEndTime;
        uint256 claimsStartTime;
        uint256 claimsEndTime;
        uint256 startPrice;
        uint256 lowestPrice;
        uint256 dropPerStep;
        uint256 daPriceCurveLength;
        uint256 daDropInterval;
        uint256 mintlistPrice;
        uint256 maxMintlistSupply;
        uint256 maxDaSupply;
        uint256 maxForSale;
        uint256 maxForClaim;
        uint256 maxTreasurySupply;
    }

    /// @notice The treasury address
    address public treasury;

    /// @notice The wrapped ether address
    address public weth;

    /// @notice The server address
    address public server;

    /// @notice The start timestamp for mintlisters
    /// @dev This is the start of minting. DA phase will follow after 24 hrs
    uint256 public mintlistStartTime;

    /// @notice The start timestamp for the Dutch Auction (DA) sale and price
    uint256 public daStartTime;

    /// @notice The start timestamp for the public sale
    uint256 public publicStartTime;

    /// @notice The end timestamp for the public sale
    uint256 public publicEndTime;

    /// @notice The start timestamp for the claims
    uint256 public claimsStartTime;

    /// @notice The end timestamp for the claims
    uint256 public claimsEndTime;

    /// @notice The start timestamp for self refunds,
    /// it starts after 24 hrs the issueRefunds is called
    uint256 public selfRefundsStartTime;

    /// @notice The main Merkle root
    bytes32 public mintlist1MerkleRoot;

    /// @notice The secondary Merkle root
    /// @dev Having a backup merkle root lets us atomically update the merkletree without downtime on the frontend
    bytes32 public mintlist2MerkleRoot;

    /// @notice The address of the Atlanteans contract
    address public atlanteans;

    /// @notice The start price of the DA
    uint256 public startPrice;

    /// @notice The lowest price of the DA
    uint256 public lowestPrice;

    /// @notice The price drop for each hour
    uint256 public dropPerStep;

    /// @notice The length of time for the price curve in the DA
    uint256 public daPriceCurveLength;

    /// @notice The interval of time in which the price steps down
    uint256 public daDropInterval;

    /// @notice The last price of the DA from the last minter. Will be updated everytime someone calls bidSummon
    uint256 public lastPrice;

    /// @notice The mintlist price
    uint256 public mintlistPrice;

    /// @notice An array of the addresses of the DA minters
    /// @dev An entry is created for every da minting tx, so the same minter address is quite likely to appear more than once
    address[] public daMinters;

    /// @notice Tracks the total amount paid by a given address in the DA
    mapping(address => uint256) public daAmountPaid;

    /// @notice Tracks the total amount refunded to a given address for the DA
    mapping(address => uint256) public daAmountRefunded;

    /// @notice Tracks the total count of NFTs minted by a given address in the DA
    mapping(address => uint256) public daNumMinted;

    /// @notice Tracks the total count of minted NFTs on mintlist phase
    mapping(address => uint256) public mintlistMinted;

    /**
     * @notice Tracks the remaining claimable for a Founding Atlantean during claim phase
     */
    mapping(address => uint256) public faToRemainingClaim;

    /**
     * @notice Tracks if a Founding Atlantean is registered
     */
    mapping(address => bool) public faRegistered;

    /// @notice The max supply for mintlist allocation sale
    uint256 public maxMintlistSupply;

    /// @notice Tracks the total count of NFTs sold on mintlist phase
    uint256 public numMintlistSold;

    /// @notice The total number of tokens reserved for the DA phase
    uint256 public maxDaSupply;

    /// @notice Tracks the total count of NFTs sold (vs. freebies)
    uint256 public numSold;

    /// @notice Tracks the total count of NFTs for sale
    uint256 public maxForSale;

    /// @notice Tracks the total count of NFTs claimed for free
    uint256 public numClaimed;

    /// @notice Tracks the total count of NFTs that can be claimed
    /// @dev While we will have a merkle root set for this group, putting a hard cap helps limit the damage of any problems with an overly-generous merkle tree
    uint256 public maxForClaim;

    /// @notice The total number of tokens reserved for AW treasury
    uint256 public maxTreasurySupply;

    /// @notice Tracks the total count of NFTs minted to treasury
    uint256 public numTreasuryMinted;

    /**
     * @notice Validates if given address is not empty
     */
    modifier validAddress(address _address) {
        require(_address != address(0), 'AtlanteansSale: Invalid address');
        _;
    }

    /**
     * @notice Common modifier for 2 functions mintlistSummon but with different arguments
     */
    modifier mintlistValidations(
        bytes32[] calldata _merkleProof,
        uint256 numAtlanteans,
        uint256 amount
    ) {
        require(msg.sender == tx.origin && !AddressUpgradeable.isContract(msg.sender), 'AtlanteansSale: Not EOA');

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProofUpgradeable.verify(_merkleProof, mintlist1MerkleRoot, node) ||
                MerkleProofUpgradeable.verify(_merkleProof, mintlist2MerkleRoot, node),
            'AtlanteansSale: Invalid proof'
        );

        require(numSold < maxForSale, 'AtlanteansSale: Sold out');
        require(numMintlistSold < maxMintlistSupply, 'AtlanteansSale: Sold out for mintlist phase');
        require(mintlistStarted(), 'AtlanteansSale: Mintlist phase not started');
        require(amount == mintlistPrice * numAtlanteans, 'AtlanteansSale: Ether value incorrect');
        require(mintlistMinted[msg.sender] < 2, 'AtlanteansSale: Already minted twice');
        require(numAtlanteans < 3, 'AtlanteansSale: Can only request max of 2');
        _;
    }

    /**
     * @notice Common modifier for 2 functions bidSummon but with different arguments
     */
    modifier daValidations(uint256 numAtlanteans) {
        require(msg.sender == tx.origin && !AddressUpgradeable.isContract(msg.sender), 'AtlanteansSale: Not EOA');
        require(numSold < maxDaSupply + mintlistRemainingSupply(), 'AtlanteansSale: Auction sold out');
        require(numAtlanteans <= remainingForSale(), 'AtlanteansSale: Not enough remaining');
        require(daStarted(), 'AtlanteansSale: Auction not started');
        require(!claimsStarted(), 'AtlanteansSale: Auction phase over');
        require(
            // slither-disable-next-line reentrancy-eth,reentrancy-benign
            numAtlanteans > 0 && numAtlanteans <= IAtlanteans(atlanteans).MAX_QUANTITY_PER_TX(),
            'AtlanteansSale: You can summon no more than 19 atlanteans at a time'
        );
        _;
    }

    /**
     * @notice Common modifier for 2 functions publicSummon but with different arguments
     */
    modifier publicValidations(uint256 numAtlanteans, uint256 amount) {
        require(msg.sender == tx.origin && !AddressUpgradeable.isContract(msg.sender), 'AtlanteansSale: Not EOA');
        require(publicStarted(), 'AtlanteansSale: Public sale not started');
        require(!publicEnded(), 'AtlanteansSale: Public sale has ended');
        require(numSold < maxForSale, 'AtlanteansSale: Sold out');
        require(numSold + numAtlanteans <= maxForSale, 'AtlanteansSale: Not enough remaining');
        require(
            numAtlanteans > 0 && numAtlanteans <= IAtlanteans(atlanteans).MAX_QUANTITY_PER_TX(),
            'AtlanteansSale: You can summon no more than 19 Atlanteans at a time'
        );
        // slither-disable-next-line incorrect-equality
        require(amount == lastPrice * numAtlanteans, 'AtlanteansSale: Ether value sent is incorrect');
        _;
    }

    /**
     * @notice Emits event when someone mints during mintlist phase
     */
    event MintlistSummon(address indexed minter);

    /**
     * @notice Emits event when someone buys during DA
     */
    event BidSummon(address indexed minter, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event when someone mints during public phase
     */
    event PublicSummon(address indexed minter, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event when someone claims a free character
     */
    event ClaimSummon(address indexed minter, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event minting via teamSummon
     */
    event TeamSummon(address indexed recipient, uint256 indexed numAtlanteans);

    /**
     * @notice Emits event when any arbitrary mint tx is called
     */
    event AtlanteanMint(address indexed to, uint256 indexed quantity);

    /**
     * @notice Emits event when a new DA start time is set
     */
    event SetDaStartTime(uint256 indexed oldStartTime, uint256 indexed newStartTime);

    /**
     * @notice Emits event when a new mintlist start time is set
     */
    event SetMintlistStartTime(uint256 indexed oldStartTime, uint256 indexed newStartTime);

    /**
     * @notice Emits event when a new claims start time is set
     */
    event SetClaimsStartTime(uint256 indexed oldStartTime, uint256 indexed newStartTime);

    /**
     * @notice Emits event when phase times are set
     */
    event SetPhaseTimes(uint256 indexed newDaStartTime, uint256 indexed newMintlistStartTime, uint256 indexed newClaimsStartTime);

    /**
     * @notice Emits event when mintlist1 merkle root is set
     */
    event SetMintlist1MerkleRoot(bytes32 indexed oldMerkleRoot, bytes32 indexed newMerkleRoot);

    /**
     * @notice Emits event when mintlist2 merkle root is set
     */
    event SetMintlist2MerkleRoot(bytes32 indexed oldMerkleRoot, bytes32 indexed newMerkleRoot);

    /**
     * @notice Emits event when a new treasury is set
     */
    event SetTreasury(address indexed oldTreasury, address indexed newTreasury);

    /**
     * @notice Emits event when a new address for Atlanteans ERC721A is set
     */
    event SetAtlanteans(address indexed oldAtlanteans, address indexed newAtlanteans);

    /**
     * @notice Emits event when a new weth address is set
     */
    event SetWeth(address indexed oldWeth, address indexed newWeth);

    /**
     * @notice Emits event when a new server address is set
     */
    event SetServer(address indexed oldServer, address indexed newServer);

    fallback() external payable {}

    receive() external payable {}

    /**
     * @dev Create the contract and set the initial baseURI
     * @param _initializerArgs The initializer args.
     */
    function initialize(InitializerArgs calldata _initializerArgs) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        atlanteans = _initializerArgs.atlanteans;
        treasury = _initializerArgs.treasury;
        weth = _initializerArgs.weth;
        server = _initializerArgs.server;

        mintlistStartTime = _initializerArgs.mintlistStartTime;
        daStartTime = _initializerArgs.daStartTime;
        publicStartTime = _initializerArgs.publicStartTime;
        publicEndTime = _initializerArgs.publicEndTime;
        claimsStartTime = _initializerArgs.claimsStartTime;
        claimsEndTime = _initializerArgs.claimsEndTime;

        // initial val, but will be updated for every mint during auction phase
        lastPrice = _initializerArgs.startPrice;

        startPrice = _initializerArgs.startPrice;
        lowestPrice = _initializerArgs.lowestPrice;
        dropPerStep = _initializerArgs.dropPerStep;
        daPriceCurveLength = _initializerArgs.daPriceCurveLength;
        daDropInterval = _initializerArgs.daDropInterval;
        mintlistPrice = _initializerArgs.mintlistPrice;

        maxMintlistSupply = _initializerArgs.maxMintlistSupply;
        maxDaSupply = _initializerArgs.maxDaSupply;
        maxForSale = _initializerArgs.maxForSale;
        maxForClaim = _initializerArgs.maxForClaim;
        maxTreasurySupply = _initializerArgs.maxTreasurySupply;

        selfRefundsStartTime = type(uint256).max;
    }

    /*
     * Timeline:
     *
     * mintlistSummon  : |------------|
     * bidSummon       :              |------------|
     * publicSummon    :                           |------------|
     * claimSummon     :                           |------------|------------------------|
     * teamSummon      : |---------------------------------------------------------------|
     */

    /**
     * @notice Mint an Atlantean in the mintlist phase (paid)
     * @param _merkleProof bytes32[] your proof of being able to mint
     */
    function mintlistSummon(bytes32[] calldata _merkleProof, uint256 numAtlanteans)
        external
        payable
        nonReentrant
        whenNotPaused
        mintlistValidations(_merkleProof, numAtlanteans, msg.value)
    {
        _mintlistMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the mintlist phase (paid)
     * @param _merkleProof bytes32[] your proof of being able to mint
     * @param amount uint256 of the wrapped ether amount sent by caller
     */
    function mintlistSummon(
        bytes32[] calldata _merkleProof,
        uint256 numAtlanteans,
        uint256 amount
    ) external payable nonReentrant whenNotPaused mintlistValidations(_merkleProof, numAtlanteans, amount) {
        _sendWethPayment(mintlistPrice * numAtlanteans);
        _mintlistMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Dutch Auction phase
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     */
    function bidSummon(uint256 numAtlanteans) external payable nonReentrant whenNotPaused daValidations(numAtlanteans) {
        uint256 bidPrice = _bidPrice(numAtlanteans);
        require(msg.value == bidPrice, 'AtlanteansSale: Ether value incorrect');

        _daMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Dutch Auction phase
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     * @param amount uint256 of the wrapped ether amount sent by caller
     */
    function bidSummon(uint256 numAtlanteans, uint256 amount) external payable nonReentrant whenNotPaused daValidations(numAtlanteans) {
        uint256 bidPrice = _bidPrice(numAtlanteans);
        require(amount == bidPrice, 'AtlanteansSale: Ether value incorrect');

        _sendWethPayment(bidPrice);
        _daMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Public phase (paid)
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     */
    function publicSummon(uint256 numAtlanteans) external payable nonReentrant whenNotPaused publicValidations(numAtlanteans, msg.value) {
        _publicMint(numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean in the Public phase (paid)
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     * @param amount uint256 of the wrapped ether amount sent by caller
     */
    function publicSummon(uint256 numAtlanteans, uint256 amount)
        external
        payable
        nonReentrant
        whenNotPaused
        publicValidations(numAtlanteans, amount)
    {
        _sendWethPayment(lastPrice * numAtlanteans);
        _publicMint(numAtlanteans);
    }

    /**
     * @dev claim a free Atlantean(s) if wallet is part of snapshot
     * @param signature bytes server side generated signature
     * @param scrollsAmount uint256 can be fetched from server side
     * @param numAtlanteans uint256 the amount to be minted during claiming
     */
    function claimSummon(
        bytes calldata signature,
        uint256 scrollsAmount,
        uint256 numAtlanteans
    ) external nonReentrant whenNotPaused {
        require(claimsStarted(), 'AtlanteansSale: Claim phase not started');
        require(numClaimed < maxForClaim, 'AtlanteansSale: No more claims');

        bytes32 hash = keccak256(
            abi.encodePacked(
                msg.sender,
                scrollsAmount,
                numAtlanteans,
                !faRegistered[msg.sender] ? scrollsAmount : faToRemainingClaim[msg.sender]
            )
        );
        require(hash.toEthSignedMessageHash().recover(signature) == server, 'AtlanteansSale: Invalid signature.');

        if (!faRegistered[msg.sender]) {
            faRegistered[msg.sender] = true;
            faToRemainingClaim[msg.sender] = scrollsAmount;
        }

        require(faRegistered[msg.sender] && faToRemainingClaim[msg.sender] >= numAtlanteans, 'AtlanteansSale: Not enough remaining for claim.');

        numClaimed += numAtlanteans;
        faToRemainingClaim[msg.sender] -= numAtlanteans;
        _mint(msg.sender, numAtlanteans);

        emit ClaimSummon(msg.sender, numAtlanteans);
    }

    /**
     * @notice Mint an Atlantean (owner only)
     * @param recipient address the address of the recipient
     * @param numAtlanteans uint256 of the number of atlanteans you're trying to mint
     */
    function teamSummon(address recipient, uint256 numAtlanteans) external onlyOwner {
        require(address(recipient) != address(0), 'AtlanteansSale: Address req');

        _mint(recipient, numAtlanteans);
        emit TeamSummon(recipient, numAtlanteans);
    }

    function _mint(address to, uint256 quantity) private {
        // slither-disable-next-line reentrancy-eth,reentrancy-no-eth,reentrancy-benign,reentrancy-events
        IAtlanteans(atlanteans).mintTo(to, quantity);
        emit AtlanteanMint(to, quantity);
    }

    /**
     * @notice Minting relevant for mintlist phase
     */
    function _mintlistMint(uint256 numAtlanteans) private {
        mintlistMinted[msg.sender] += numAtlanteans;
        numMintlistSold += numAtlanteans;
        numSold += numAtlanteans;

        _mint(msg.sender, numAtlanteans);
        emit MintlistSummon(msg.sender);
    }

    /**
     * @notice Minting relevant for auction phase
     * @param numAtlanteans uint256 The quantity of tokens to be minted
     */
    function _daMint(uint256 numAtlanteans) private {
        daMinters.push(msg.sender);
        daAmountPaid[msg.sender] += msg.value;
        daNumMinted[msg.sender] += numAtlanteans;
        numSold += numAtlanteans;
        lastPrice = currentDaPrice();

        _mint(msg.sender, numAtlanteans);
        emit BidSummon(msg.sender, numAtlanteans);
    }

    /**
     * @notice Minting for public phase
     * @param numAtlanteans uint256 The quantity of tokens to be minted
     */
    function _publicMint(uint256 numAtlanteans) private {
        numSold += numAtlanteans;

        _mint(msg.sender, numAtlanteans);
        emit PublicSummon(msg.sender, numAtlanteans);
    }

    /*
     * View utilities
     */

    /**
     * @notice returns the current dutch auction price
     */
    function currentDaPrice() public view returns (uint256) {
        if (!daStarted()) {
            return startPrice;
        }
        if (block.timestamp >= daStartTime + daPriceCurveLength) {
            // end of the curve
            return lowestPrice;
        }

        uint256 elapsed = block.timestamp - daStartTime;
        // slither-disable-next-line divide-before-multiply
        uint256 steps = elapsed / daDropInterval;
        uint256 stepDeduction = steps * dropPerStep;

        // don't go negative in the next step
        if (stepDeduction > startPrice) {
            return lowestPrice;
        }
        uint256 currentPrice = startPrice - stepDeduction;
        return currentPrice > lowestPrice ? currentPrice : lowestPrice;
    }

    /**
     * @notice returns whether the mintlist has started
     */
    function mintlistStarted() public view returns (bool) {
        return block.timestamp > mintlistStartTime;
    }

    /**
     * @notice returns whether the dutch auction has started
     */
    function daStarted() public view returns (bool) {
        return block.timestamp > daStartTime;
    }

    /**
     * @notice returns whether the public mint has started
     */
    function publicStarted() public view returns (bool) {
        return block.timestamp > publicStartTime;
    }

    /**
     * @notice returns whether the public phase has end
     */
    function publicEnded() public view returns (bool) {
        return block.timestamp > publicEndTime;
    }

    /**
     * @notice returns whether the claims phase has started
     */
    function claimsStarted() public view returns (bool) {
        return block.timestamp > claimsStartTime;
    }

    /**
     * @notice returns whether the claims phase has end
     */
    function claimsEnded() public view returns (bool) {
        return block.timestamp > claimsEndTime;
    }

    /**
     * @notice returns whether self refunds phase has started
     */
    function selfRefundsStarted() public view returns (bool) {
        return block.timestamp > selfRefundsStartTime;
    }

    /**
     * @notice returns the number of minter addresses in the DA phase (includes duplicates)
     */
    function numDaMinters() public view returns (uint256) {
        return daMinters.length;
    }

    /**
     * @dev util function, getting the bid price
     * @param numAtlanteans uint256 The quantity of tokens to be minted
     */
    function _bidPrice(uint256 numAtlanteans) private view returns (uint256) {
        uint256 daPrice = currentDaPrice();
        return (daPrice * numAtlanteans);
    }

    /**
     * @notice returns the mintlist remaining supply
     */
    function mintlistRemainingSupply() public view returns (uint256) {
        return maxMintlistSupply - numMintlistSold;
    }

    /**
     * @notice returns the auction remaining supply
     */
    function remainingForSale() public view returns (uint256) {
        return maxForSale - numSold;
    }

    /*
     * Only the owner can do these things
     */

    /**
     * @notice pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice set the dutch auction start timestamp
     */
    function setDaStartTime(uint256 _newTime) external onlyOwner {
        emit SetDaStartTime(daStartTime, _newTime);
        daStartTime = _newTime;
    }

    /**
     * @notice set the mintlist start timestamp
     */
    function setMintlistStartTime(uint256 _newTime) external onlyOwner {
        emit SetMintlistStartTime(mintlistStartTime, _newTime);
        mintlistStartTime = _newTime;
    }

    /**
     * @notice set the claims phase start timestamp
     */
    function setClaimsStartTime(uint256 _newTime) external onlyOwner {
        emit SetClaimsStartTime(claimsStartTime, _newTime);
        claimsStartTime = _newTime;
    }

    /**
     * @notice A convenient way to set all phase times at once
     * @param newDaStartTime uint256 the dutch auction start time
     * @param newMintlistStartTime uint256 the mintlst phase start time
     * @param newPublicStartTime uint256 the public phase start time
     * @param newPublicEndTime uint256 the public phase end time
     * @param newClaimsStartTime uint256 the claims phase start time
     * @param newClaimsEndTime uint256 the claims phase end time
     */
    function setPhaseTimes(
        uint256 newDaStartTime,
        uint256 newMintlistStartTime,
        uint256 newPublicStartTime,
        uint256 newPublicEndTime,
        uint256 newClaimsStartTime,
        uint256 newClaimsEndTime
    ) external onlyOwner {
        // we put these checks here instead of in the setters themselves
        // because they're just guardrails of the typical case
        require(newDaStartTime >= newMintlistStartTime, 'AtlanteansSale: Set auction after mintlist');
        require(newClaimsStartTime >= newDaStartTime, 'AtlanteansSale: Set claims after auction');
        require(newClaimsEndTime > newClaimsStartTime, 'AtlanteansSale: The claims end time must be greater than claims start time');

        daStartTime = newDaStartTime;
        mintlistStartTime = newMintlistStartTime;
        publicStartTime = newPublicStartTime;
        publicEndTime = newPublicEndTime;
        claimsStartTime = newClaimsStartTime;
        claimsEndTime = newClaimsEndTime;

        emit SetPhaseTimes(newDaStartTime, newMintlistStartTime, newClaimsStartTime);
    }

    /**
     * @notice set the merkle root for the mintlist phase
     */
    function setMintlist1MerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        emit SetMintlist1MerkleRoot(mintlist1MerkleRoot, newMerkleRoot);
        mintlist1MerkleRoot = newMerkleRoot;
    }

    /**
     * @notice set the alternate merkle root for the mintlist phase
     * @dev we have two because it lets us idempotently update the website without downtime
     */
    function setMintlist2MerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        emit SetMintlist2MerkleRoot(mintlist2MerkleRoot, newMerkleRoot);
        mintlist2MerkleRoot = newMerkleRoot;
    }

    /**
     * @notice set the vault address where the funds are withdrawn
     */
    function setTreasury(address _treasury) external onlyOwner validAddress(_treasury) {
        emit SetTreasury(treasury, _treasury);
        treasury = _treasury;
    }

    /**
     * @notice set the atlanteans token address
     */
    function setAtlanteans(address _atlanteans) external onlyOwner validAddress(_atlanteans) {
        emit SetAtlanteans(atlanteans, _atlanteans);
        atlanteans = _atlanteans;
    }

    /**
     * @notice set the wrapped ether address
     */
    function setWeth(address _weth) external onlyOwner validAddress(_weth) {
        emit SetWeth(weth, _weth);
        weth = _weth;
    }

    /**
     * @notice set the server address
     */
    function setServer(address _server) external onlyOwner validAddress(_server) {
        emit SetServer(server, _server);
        server = _server;
    }

    /**
     * @notice Sends payment to treasury and returns excess amount back to caller.
     * @param price The current auction price or final price.
     */
    function _sendWethPayment(uint256 price) private {
        // slither-disable-next-line unchecked-transfer,reentrancy-events
        IWETH(weth).transferFrom(msg.sender, address(this), price);
    }

    /*
     * Refund logic
     */

    /**
     * @notice issues refunds for the accounts in minters between startIdx and endIdx inclusive
     * @param startIdx uint256 the starting index of daMinters
     * @param endIdx uint256 the ending index of daMinters, inclusive
     */
    function issueRefunds(uint256 startIdx, uint256 endIdx) public onlyOwner nonReentrant {
        selfRefundsStartTime = block.timestamp + 24 hours;
        for (uint256 i = startIdx; i < endIdx + 1; i++) {
            _refundAddress(daMinters[i]);
        }
    }

    /**
     * @notice issues a refund for the address
     * @param minter address the address to refund
     */
    function refundAddress(address minter) public onlyOwner nonReentrant {
        _refundAddress(minter);
    }

    /**
     * @notice refunds msg.sender what they're owed
     */
    function selfRefund() public nonReentrant {
        require(selfRefundsStarted(), 'Self refund period not started');
        _refundAddress(msg.sender);
    }

    function _refundAddress(address minter) private {
        uint256 owed = refundOwed(minter);

        if (owed > 0) {
            daAmountRefunded[minter] += owed;
            _safeTransferETH(minter, owed);
        }
    }

    /**
     * @notice returns the amount owed the address
     * @param minter address the address of the account that wants a refund
     */
    function refundOwed(address minter) public view returns (uint256) {
        uint256 totalCostOfMints = lastPrice * daNumMinted[minter];
        uint256 refundsPaidAlready = daAmountRefunded[minter];
        return daAmountPaid[minter] - totalCostOfMints - refundsPaidAlready;
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     * @param to account who to send the ETH to
     * @param value uint256 how much ETH to send
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    /**
     * @notice Withdraws all funds out to treasury
     */
    function withdrawAll() external onlyOwner returns (bool, bool) {
        (bool success, ) = payable(treasury).call{value: address(this).balance, gas: 30_000}(new bytes(0));
        bool successERC20 = IWETH(weth).transfer(treasury, IWETH(weth).balanceOf(address(this)));

        return (success, successERC20);
    }
}

/* solhint-disable func-name-mixedcase */
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

interface IAtlanteans {
    function MAX_SUPPLY() external returns (uint256);

    function MAX_QUANTITY_PER_TX() external returns (uint256);

    /**
     * @notice Allows admin to mint a batch of tokens to a specified arbitrary address
     * @param to The receiver of the minted tokens
     * @param quantity The amount of tokens to be minted
     */
    function mintTo(address to, uint256 quantity) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

interface IWETH {
    function balanceOf(address account) external returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}