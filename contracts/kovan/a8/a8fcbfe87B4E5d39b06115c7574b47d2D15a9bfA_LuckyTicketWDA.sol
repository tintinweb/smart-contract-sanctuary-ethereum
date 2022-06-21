// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract LuckyTicketWDA is ReentrancyGuard, VRFConsumerBase {
    bytes32 internal _keyHash =
        0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
    uint256 internal _fee = 0.1 * 10**18; // MAINNET CHANGE IT TO 0.2 LINK
    uint256 _randomResult;

    IERC20 WDAToken;
    address private _owner;
    address public DAOTreasuryWallet =
        0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    uint256 constant maxTicketProvidePerDay = 50000;
    uint256 public lastTimeCheck = block.timestamp;
    uint256 public totalTicketSoldPerPeriod = 0; // maximum 50000 * 5 days = 250000
    uint256 constant ownerTicketMaxCount = 50;
    uint256 _feePerTicket = 0.0004 * 10**18; // BNB
    uint256 _ticketCost = 1000 * 10**18; // WDA
    uint256 currentSession = 0;
    uint256 checkpointProposal;

    enum ContractState {
        NORMAL,
        GETTING_RANDOM_NUMBER,
        REWARDING_TICKET
    }
    ContractState public contractState = ContractState.NORMAL;

    struct TicketReward {
        uint256 amount;
        uint256 claimableDate;
    }

    event BuyTicket(
        address indexed buyer,
        uint256 amount,
        uint256 timestamp,
        uint256 checkpoint
    );
    event TicketWin(
        address indexed owner,
        uint256 indexed amount,
        uint8 ticketType
    );
    event RandomWinner(uint256 timestamp);

    /**
     * KOVAN Testnet
     * VRF coordinator 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK 0xa36085F69e2889c224210F603D836748e7dC0088
     * keyHash 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * More information https://docs.chain.link/docs/vrf-contracts/v1/
     */

    constructor(IERC20 _token)
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088 // link
        )
    {
        WDAToken = _token;
        _owner = msg.sender;
    }

    // address user => session => amount
    mapping(address => mapping(uint256 => uint256)) ownerTicketCount;
    // player address => ticket reward amount
    mapping(address => TicketReward[]) ownerWinningTicket5000WDA;
    // player address => ticket reward amount
    mapping(address => TicketReward[]) ownerWinningTicket100000WDA;
    // address => ticket reward
    mapping(address => TicketReward[]) ownerTicketReward;
    // ticket each day
    mapping(uint256 => uint256) ticketEachDay;
    mapping(uint256 => uint256) checkpointToJackpot;
    mapping(uint256 => uint256) checkpointToLucky;
    mapping(address => bool) validTarget;

    /**
     * --------------- TEST ONLY -----------------
     */
    uint256 lockTime = 1800;
    uint256 minimumPlayer = 100;

    // minimum player la 100
    function setMinimumPlayer(uint256 amount) external {
        minimumPlayer = amount;
    }

    function setLockTime(uint256 time) external {
        lockTime = time;
    }

    uint256 maxPercent = 10;

    function setMaxPercentProposal(uint256 maxP) external {
        maxPercent = maxP;
    }

    /** ------------- END OF TEST ONLY --------------- */

    function withdrawWDAToDAOTreasury() external onlyOwner {
        uint256 amount = WDAToken.balanceOf(address(this));
        WDAToken.transfer(DAOTreasuryWallet, amount);
    }

    function setValidTarget(address target, bool permission)
        external
        onlyOwner
    {
        validTarget[target] = permission;
    }

    function initialize() external onlyOwner {
        checkpointToJackpot[checkpointProposal] = 100000 * 10**18;
        checkpointToLucky[checkpointProposal] = 5000 * 10**18;
    }

    /**
     * @param percentChange: update percent proposal
     * @param action: 0 deceasing, 1: increasting
     */
    function setProposal(uint256 percentChange, uint8 action)
        external
        onlyValidTarget
    {
        require(percentChange <= maxPercent, "Percentage too big");
        uint256 prevCheckpointJackpot = checkpointToJackpot[checkpointProposal];
        uint256 prevCheckpointLucky = checkpointToLucky[checkpointProposal];
        checkpointProposal++;
        if (action == 0) {
            checkpointToJackpot[checkpointProposal] =
                prevCheckpointJackpot -
                ((prevCheckpointJackpot * percentChange) / 100);
            checkpointToLucky[checkpointProposal] =
                prevCheckpointLucky -
                ((prevCheckpointLucky * percentChange) / 100);
        } else {
            checkpointToJackpot[checkpointProposal] =
                prevCheckpointJackpot +
                ((prevCheckpointJackpot * percentChange) / 100);
            checkpointToLucky[checkpointProposal] =
                prevCheckpointLucky +
                ((prevCheckpointLucky * percentChange) / 100);
        }
    }

    function getOwnerWinningTicket5000WDA() external view returns (uint256) {
        uint256 count = 0;
        TicketReward[] memory ownerReward = ownerWinningTicket5000WDA[
            msg.sender
        ];
        for (uint256 i = 0; i < ownerReward.length; i++) {
            if (
                ownerReward[i].amount != 0 && ownerReward[i].claimableDate != 0
            ) {
                count++;
            }
        }
        return count;
    }

    function getOwnerWinningTicket100000WDA() external view returns (uint256) {
        uint256 count = 0;
        TicketReward[] memory ownerReward = ownerWinningTicket100000WDA[
            msg.sender
        ];
        for (uint256 i = 0; i < ownerReward.length; i++) {
            if (
                ownerReward[i].amount != 0 && ownerReward[i].claimableDate != 0
            ) {
                count++;
            }
        }
        return count;
    }

    function getOwnerWinningTicket5000WDAAvailable()
        external
        view
        returns (uint256)
    {
        uint256 amount = 0;
        TicketReward[] memory ownerReward = ownerWinningTicket5000WDA[
            msg.sender
        ];
        for (uint256 i = 0; i < ownerReward.length; i++) {
            if (
                ownerReward[i].claimableDate != 0 &&
                ownerReward[i].claimableDate <= block.timestamp
            ) {
                amount++;
            }
        }
        return amount;
    }

    function getOwnerWinningTicket100000WDAAvailable()
        external
        view
        returns (uint256)
    {
        uint256 amount = 0;
        TicketReward[] memory ownerReward = ownerWinningTicket100000WDA[
            msg.sender
        ];
        for (uint256 i = 0; i < ownerReward.length; i++) {
            if (
                ownerReward[i].claimableDate != 0 &&
                ownerReward[i].claimableDate <= block.timestamp
            ) {
                amount++;
            }
        }
        return amount;
    }

    function getOwnerTicketReward() external view returns (uint256) {
        uint256 amount = 0;
        TicketReward[] memory ownerTicket = ownerTicketReward[msg.sender];
        for (uint256 i = 0; i < ownerTicket.length; i++) {
            if (ownerTicket[i].claimableDate != 0) {
                amount += ownerTicket[i].amount;
            }
        }
        return amount;
    }

    function getOwnerTicketRewardAvailable() external view returns (uint256) {
        uint256 amount = 0;
        TicketReward[] memory ownerTicket = ownerTicketReward[msg.sender];
        for (uint256 i = 0; i < ownerTicket.length; i++) {
            if (
                ownerTicket[i].claimableDate != 0 &&
                ownerTicket[i].claimableDate <= block.timestamp
            ) {
                amount += ownerTicket[i].amount;
            }
        }
        return amount;
    }

    function getOwnerTicket() external view returns (uint256) {
        return ownerTicketCount[msg.sender][currentSession];
    }

    function setDAOTreasuryWallet(address _newDAOTreasuryWallet)
        external
        onlyOwner
    {
        DAOTreasuryWallet = _newDAOTreasuryWallet;
    }

    function getFeePerTicket() external view returns (uint256) {
        return _feePerTicket;
    }

    function setFeePerTicket(uint256 _newFeePerTicket) external onlyOwner {
        _feePerTicket = _newFeePerTicket;
    }

    function payWinner(
        address winner,
        uint256 rewardAmount,
        uint256 purchaseDate,
        uint256 checkpoint
    ) external onlyValidTarget {
        if (rewardAmount == 100000) {
            ownerWinningTicket100000WDA[winner].push(
                TicketReward(
                    checkpointToJackpot[checkpoint],
                    purchaseDate + lockTime
                )
            );
            emit TicketWin(winner, checkpointToJackpot[checkpoint], 1);
        } else {
            ownerWinningTicket5000WDA[winner].push(
                TicketReward(
                    checkpointToLucky[checkpoint],
                    purchaseDate + lockTime
                )
            );
            emit TicketWin(winner, checkpointToLucky[checkpoint], 0);
        }
    }

    function rewardTicket(
        address player,
        uint256 purchaseDate,
        uint256 amount
    ) external onlyValidTarget {
        ownerTicketReward[player].push(
            TicketReward(amount, purchaseDate + lockTime)
        );
    }

    function getTicketSoldPerDay() public view returns (uint256) {
        uint256 currentDate = (block.timestamp - lastTimeCheck) / 1 days;
        return ticketEachDay[currentDate];
    }

    function resetAllTicket() external onlyValidTarget {
        currentSession++;
        for (uint256 i = 0; i < 5; i++) {
            ticketEachDay[i] = 0;
        }
        totalTicketSoldPerPeriod = 0;
        lastTimeCheck = block.timestamp;
        contractState = ContractState.NORMAL;
    }

    function getRandomNumber()
        public
        onlyValidTarget
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= _fee,
            "Not enough fee LINK in contract"
        );
        contractState = ContractState.GETTING_RANDOM_NUMBER;
        return requestRandomness(_keyHash, _fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        _randomResult = randomness;
        contractState = ContractState.REWARDING_TICKET;
        emit RandomWinner(block.timestamp);
    }

    function generateRandomNum(uint256 mod) public view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(_randomResult, block.timestamp, msg.sender)
            )
        );
        return randomNumber % mod;
    }

    function _calculateReward(uint8 ticketType) internal returns (uint256) {
        uint256 earned = 0;
        if (ticketType == 0) {
            for (
                uint256 i = 0;
                i < ownerWinningTicket5000WDA[msg.sender].length;
                i++
            ) {
                TicketReward memory reward = ownerWinningTicket5000WDA[
                    msg.sender
                ][i];
                if (
                    reward.claimableDate != 0 &&
                    reward.claimableDate <= block.timestamp
                ) {
                    earned += reward.amount;
                    delete ownerWinningTicket5000WDA[msg.sender][i];
                }
            }
        } else {
            for (
                uint256 i = 0;
                i < ownerWinningTicket100000WDA[msg.sender].length;
                i++
            ) {
                TicketReward memory reward = ownerWinningTicket100000WDA[
                    msg.sender
                ][i];
                if (
                    reward.claimableDate != 0 &&
                    reward.claimableDate <= block.timestamp
                ) {
                    earned += reward.amount;
                    delete ownerWinningTicket100000WDA[msg.sender][i];
                }
            }
        }
        require(earned > 0, "Ticket locked");
        return earned;
    }

    function claimCoin(uint8 _ticketType) external {
        // _ticketType: 0: 5000, 1: 100000
        if (_ticketType == 0) {
            require(
                ownerWinningTicket5000WDA[msg.sender].length > 0,
                "None ticket is available to claim"
            );
        } else {
            require(
                ownerWinningTicket100000WDA[msg.sender].length > 0,
                "None ticket is available to claim"
            );
        }
        uint256 _earned = _calculateReward(_ticketType);
        WDAToken.transfer(msg.sender, _earned);
    }

    function claimReward() external {
        TicketReward[] memory ownerReward = ownerTicketReward[msg.sender];
        require(ownerReward.length > 0, "None ticket is available");
        uint256 count = 0;
        for (uint256 i = 0; i < ownerReward.length; i++) {
            if (
                ownerReward[i].amount != 0 &&
                ownerReward[i].claimableDate != 0 &&
                ownerReward[i].claimableDate <= block.timestamp
            ) {
                delete ownerTicketReward[msg.sender][i];
                count += ownerReward[i].amount;
            }
        }
        WDAToken.transfer(msg.sender, count * _ticketCost);
    }

    function buyTicket(uint256 _quantity) external payable nonReentrant {
        require(contractState == ContractState.NORMAL, "Not time to buy");
        require(_quantity > 0, "Invalid quantity");
        // check maximum ticket allow of each user
        require(
            ownerTicketCount[msg.sender][currentSession] + _quantity <=
                ownerTicketMaxCount,
            "Maximum ticket allow"
        );
        // check quantity provide per day
        require(
            _quantity + getTicketSoldPerDay() <= maxTicketProvidePerDay,
            "Over limited ticket"
        );
        // check fee
        uint256 _totalFeeBNB = _quantity * _feePerTicket;
        require(msg.value >= _totalFeeBNB, "Not enough fee BNB");
        // check allowance
        uint256 _totalFeeWDA = _quantity * _ticketCost;
        uint256 allowance = WDAToken.allowance(msg.sender, address(this));
        require(allowance >= _totalFeeWDA, "Over allowance WDA");
        WDAToken.transferFrom(
            msg.sender,
            address(this),
            _totalFeeWDA // send ticket cost only to address(this)
        );
        totalTicketSoldPerPeriod += _quantity;
        uint256 currentDate = (block.timestamp - lastTimeCheck) / 1 days;
        ownerTicketCount[msg.sender][currentSession] += _quantity;
        ticketEachDay[currentDate] += _quantity;

        // send fee per ticket (BNB) to DAO treasury
        payable(DAOTreasuryWallet).transfer(_totalFeeBNB);
        emit BuyTicket(
            msg.sender,
            _quantity,
            block.timestamp,
            checkpointProposal
        );
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }

    modifier onlyValidTarget() {
        require(validTarget[msg.sender], "Not valid target");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: Not owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}