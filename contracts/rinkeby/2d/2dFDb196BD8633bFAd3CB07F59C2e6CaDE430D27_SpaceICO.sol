//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./helpers/Ownable.sol";

// @title SpaceICO
// @author Mathias Scherer
// @notice This contract handles the SpaceCoin ICO
// @dev This contract handles the SpaceCoin ICO and gets a fixed amount of tokens from the SpaceCoin contract
contract SpaceICO is Ownable {
    // Enums
    // @notice The different states the ICO can be in
    enum Phases {
        SEED,
        GENERAL,
        OPEN
    }

    // Structs
    // @dev Struct for the configs for each phase
    struct PhaseConfig {
        uint120 individualMax;
        uint120 totalMax;
        bool usesWhitelist;
        bool allowTransfer;
    }

    // Variables
    // @notice The exchange rate for the contribution (5 SpaceCoin for 1 ether)
    uint256 public constant EXCHANGE_RATE = 5;
    // @dev Used to check if the contract is already initialized or not
    bool public initialized;
    // @notice Variable to store if the ICO is paused or not
    bool public paused;
    // @notice The address of the SpaceCoin contract
    IERC20 public tokenContract;
    // @notice The current phase of the ICO
    Phases public phase;
    // @notice Total amount of contributions
    uint256 public totalContributions;
    // @notice Total amount of contributions per contributor
    mapping(address => uint256) public contributions;
    // @notice The total amount of tokens claimed per contributor
    mapping(address => uint256) public transferedContributions;
    // @notice Whitelist for the ICO (used in the SEED phase)
    mapping(address => bool) public whitelist;
    // @dev Mapping to store the configs for each phase
    mapping(Phases => PhaseConfig) public phaseConfigs;

    // Events
    // @notice Event to emit when a contribution is made
    // @param contributor The address of the contributor
    // @param amount The amount of ETH contributed
    event Contribution(address indexed contributor, uint256 amount);

    // @notice Event to emit when a contributor is whitelisted
    // @param contributor The address of the contributor
    event Whitelisted(address indexed contributor);

    // @notice Event to emit when the ICO is paused
    // @param paused The new paused state
    event ChangedPaused(bool paused);

    // @notice Event to emit when the ICO advances to the next phase
    // @param newPhase The new phase
    event PhaseAdvanced(Phases newPhase);

    // @notice Event to emit when a contributor claims their tokens
    // @param contributor The address of the contributor
    // @param amount The amount of tokens claimed
    event TokensClaimed(address indexed contributor, uint256 amount);

    // @notice Event to emit when the contract is initialized
    event Initialized();

    // Modifiers
    // @dev Modifier to check if a phase uses the whitelist and if the sender is whitelisted
    modifier onlyWhitelisted() {
        if (phaseConfigs[phase].usesWhitelist) {
            require(whitelist[msg.sender], "Not whitelisted");
        }
        _;
    }

    // @dev Modifier to check if the contract is initialized
    modifier onlyInitialized() {
        require(initialized, "Contract not initialized");
        _;
    }

    // Public functions

    // @notice Initializes the contract
    // @param _tokenContract The address of the SpaceCoin contract
    function initialize(address _tokenContract) external onlyOwner {
        require(!initialized, "Already initialized");
        tokenContract = IERC20(_tokenContract);
        phaseConfigs[Phases.SEED] = PhaseConfig(
            1500 ether,
            15000 ether,
            true,
            false
        );
        phaseConfigs[Phases.GENERAL] = PhaseConfig(
            1000 ether,
            30000 ether,
            false,
            false
        );
        phaseConfigs[Phases.OPEN] = PhaseConfig(0, 30000 ether, false, true);
        initialized = true;
        emit Initialized();
    }

    // @notice Allows the owner to set an address as whitelisted
    // @param _address The address to whitelist
    function addToWhitelist(address _contributor) public onlyOwner {
        whitelist[_contributor] = true;
        emit Whitelisted(_contributor);
    }

    // @notice Allows the owner to add addresses to the whitelist in bulk
    // @param _addresses The addresses to whitelist
    function addToWhitelistBulk(address[] calldata _contributors)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _contributors.length; i++) {
            addToWhitelist(_contributors[i]);
        }
    }

    // @notice Allows the owner advance the ICO to the next phase
    // @param _currentPhase The current phase to prevent advancing to the next phase if the call expects the wrong current phase
    function advancePhase(Phases _currentPhase) external onlyOwner {
        require(phase == _currentPhase, "Not the current phase");
        uint8 nextPhase = uint8(phase) + 1;
        require(nextPhase < 3, "Already at last phase");
        phase = Phases(nextPhase);
        emit PhaseAdvanced(phase);
    }

    // @notice Allows the owner to pause the ICO
    // @param _paused The new paused state
    function togglePause(bool _pause) external onlyOwner {
        paused = _pause;
        emit ChangedPaused(paused);
    }

    // @notice Allows a contributor to contribute to the ICO
    // @dev Checks if the contract is initalized, if a whitelist is used and if the sender is whitelisted and if the ICO is paused. If the ICO is in phase that allows transfers it transfers the tokens immediately.
    function contribute() external payable onlyWhitelisted onlyInitialized {
        require(!paused, "ICO is paused");
        totalContributions += msg.value;
        require(
            totalContributions <= phaseConfigs[phase].totalMax ||
                phaseConfigs[phase].totalMax == 0,
            "Total limit reached"
        );
        contributions[msg.sender] += msg.value;
        require(
            contributions[msg.sender] <= phaseConfigs[phase].individualMax ||
                phaseConfigs[phase].individualMax == 0,
            "Personal limit reached"
        );

        emit Contribution(msg.sender, msg.value);

        if (phaseConfigs[phase].allowTransfer) {
            _transfer(msg.value);
        }
    }

    // @notice Allows the contributor to claim the tokens
    // @dev Checks if the ICO is in a phase that allows transfers and if the contributor has tokens to claim.
    function claimTokens() external onlyInitialized {
        require(
            phaseConfigs[phase].allowTransfer,
            "Not allowed to claim tokens in this phase"
        );
        require(contributions[msg.sender] > 0, "No contributions to claim");
        require(
            transferedContributions[msg.sender] < contributions[msg.sender],
            "All contributions have been minted"
        );
        uint256 pendingMints = contributions[msg.sender] -
            transferedContributions[msg.sender];
        _transfer(pendingMints);
    }

    // @notice Allows the owner to withdraw the ETH from the ICO
    // @param _to Address to send the ETH to
    // @param _amount Amount of ETH to send
    function withdraw(address _to, uint256 _amount) external onlyOwner onlyInitialized {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdraw failed");
    }

    // Private functions
    // @notice Transfers the tokens to the contributor with the applied exchange rate
    // @param amount The amount of tokens to transfer
    function _transfer(uint256 _amount) internal {
        transferedContributions[msg.sender] += _amount;
        emit TokensClaimed(msg.sender, _amount * EXCHANGE_RATE);
        bool success = tokenContract.transfer(
            msg.sender,
            _amount * EXCHANGE_RATE
        );
        require(success, "Transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

// @title SpaceCoin
// @author Mathias Scherer
// @notice Helper contract to check if it is the owner or not
contract Ownable {
    // variables
    // @notice The address of the owner
    address public owner;

    // Modifiers
    // @notice Modifier to check if the sender is the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Constructor
    // @notice Constructor
    constructor() {
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
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