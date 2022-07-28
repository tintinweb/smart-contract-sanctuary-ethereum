// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Errors.sol";

interface ISpaceCoin {
    function treasury() external view returns (address);
    function maxSupply() external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function mint(address to, uint256 amount) external;
}

contract SpaceICO {
    // Target amount of SPCE to be raised (150k SPCE)
    uint256 public constant targetOfferingAmount = 150_000 * 10**18;
    
    // Owner of this contract
    address public immutable owner;

    // Address of the SpaceCoin ERC-20 token
    address public spaceCoin;

    // ICO phase
    uint8 public phase;

    // An array of limit amounts. Each index designates the phase.
    Limit[] limitAmount;

    // Flag that denotes if a contract is paused
    bool public isPaused;

    // Whitelist of allowed participants
    mapping(address => bool) public whitelist;

    // The amount ether contributed by address for SEED and GENERAL phases
    mapping(address => uint256) public preOpenContributions;

    // The amount ether in total for SEED and GENERAL phases
    uint256 public preOpenContributionsTotal;

    enum Phase {
        SEED,
        GENERAL,
        OPEN
    }

    struct Limit {
        uint256 total; // Max 30,000
        uint256 individual; 
    }

    modifier isPhase(Phase _phase) {
        if (uint8(_phase) != phase) revert WrongPhase(phase, uint8(_phase));
        _;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // Only applies during SEED phase
    modifier isWhitelisted {
        if (phase == uint8(Phase.SEED))
            if (!whitelist[msg.sender]) revert NotWhitelisted();
        _;
    }

    constructor(address _owner) {
        owner = _owner;

        // Initialize limits
        limitAmount.push(Limit(15_000 ether, 1_500 ether));
        limitAmount.push(Limit(30_000 ether, 1_000 ether));
        limitAmount.push(Limit(30_000 ether, 99999999999999 ether)); // Infinite-ish personal contribution amt
    }

    /**
     * @notice Advances the phases towards Phase.OPEN
     */
    function advancePhase() external onlyOwner {
        if (phase >= uint8(Phase.OPEN)) revert MaxPhaseReached();
        phase++;
    }

    /**
     * @notice Claims the pre-open contributions during OPEN phase
     */
    function claimTokens() external isPhase(Phase.OPEN) {
        uint256 amountToClaim = preOpenContributions[msg.sender];
        if (amountToClaim == 0 ) revert NothingToClaim();
        
        preOpenContributions[msg.sender] = 0;
        ISpaceCoin(spaceCoin).mint(msg.sender, amountToClaim);
    }
    
    /**
     * @notice Mints any remainder up to 500,000 SPCE to treasury during OPEN phase
     */
    function mintRemainderToTreasury() external onlyOwner isPhase(Phase.OPEN) {
        uint256 amountToMint = ISpaceCoin(spaceCoin).maxSupply() - preOpenContributionsTotal;
        address treasuryAddress = ISpaceCoin(spaceCoin).treasury();
        ISpaceCoin(spaceCoin).mint(treasuryAddress, amountToMint);
    }

    /**
     * @notice Toggles between paused states
     */
    function pause() external onlyOwner {
        isPaused = !isPaused;
    }

    /**
     * @notice Purchases some SPCE using ether.
     * Before the OPEN phase, ether is just tracked. Otherwise, mint instantly
     */
    function purchase() external payable isWhitelisted {
        if (isPaused) revert OfferingPaused();
        if (msg.value > getIndividualLimitRemaining(msg.sender)) revert IndividualLimitHit();

        // Check if the phase limit will be hit with the latest contribution
        if (preOpenContributionsTotal + msg.value > getPhaseLimitTotal()) revert PhaseLimitHit();
        
        if (phase < uint256(Phase.OPEN)) {
            preOpenContributions[msg.sender] += msg.value;
            preOpenContributionsTotal += msg.value;
        } else {
            ISpaceCoin(spaceCoin).mint(msg.sender, msg.value);
        }
    }

    /**
     * @notice sets the SpaceCoin contract address. Reverts if already set or zero address
     * @param _spaceCoin the address of the SpaceCoin
     */
    function setSpaceCoin(address _spaceCoin) external onlyOwner {
        if (spaceCoin != address(0)) revert AddressAlreadySet();
        spaceCoin = _spaceCoin;
    }

    /**
     * @notice Sets the member of the white list to be active/inactive
     * @param active is an active member
     */
    function setWhitelist(address member, bool active) external onlyOwner {
        whitelist[member] = active;
    }

    /**
     * @notice Helper function returns the phase total limit 
     */
    function getPhaseLimitTotal() public view returns (uint256) {
        return limitAmount[phase].total;
    }

    /**
     * @notice Helper function that returns the phase individual limit
     */
    function getPhaseLimitIndividual() public view returns (uint256) {
        return limitAmount[phase].individual;
    }

    /**
     * @notice Helper function that returns remaining limit in ether
     * @param individual address of look up
     */
    function getIndividualLimitRemaining(address individual) public view returns(uint256) {
        return getPhaseLimitIndividual() - preOpenContributions[individual];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error AddressAlreadySet();
error AddressZero();
error IndividualLimitHit();
error MaxTokensMinted();
error MaxPhaseReached();
error NothingToClaim();
error NotMinter();
error NotOwner();
error NotWhitelisted();
error NotReadyToBeClaimed();
error OfferingPaused();
error PhaseLimitHit();
error WrongPhase(uint8 current, uint8 lookingFor);