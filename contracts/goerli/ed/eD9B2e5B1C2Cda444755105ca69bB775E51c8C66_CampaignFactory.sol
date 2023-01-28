// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Campaign.sol";

// import hardhat console
// import "../node_modules/hardhat/console.sol";

contract CampaignFactory {
    address payable public immutable owner;
    mapping(string => address) public campaigns;

    // in US cents
    uint256 private deposit = 33300;

    // in US cents
    uint256 private fee = 0;

    constructor() {
        owner = payable(msg.sender);
    }

    event campaignCreated(address campaignContractAddress);

    function createCampaign(
        uint256 _chainId,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public {
        require(
            campaigns[_campaignId] == address(0),
            "Campaign with this id already exists"
        );

        bytes32 message = hashMessage(
            msg.sender,
            _chainId,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed
        );

        require(
            ecrecover(message, v, r, s) == owner,
            "You need signatures from the owner to create a campaign"
        );

        Campaign c = new Campaign(
            owner,
            msg.sender,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed,
            deposit,
            fee
        );

        campaigns[_campaignId] = address(c);
        emit campaignCreated(address(c));
    }

    function setDepositAmount(uint256 _deposit) public {
        require(msg.sender == owner, "Only owner can set deposit amount");
        deposit = _deposit;
    }

    function getDepositAmount() public view returns (uint256) {
        return deposit;
    }

    function setFeeAmount(uint256 _fee) public {
        require(msg.sender == owner, "Only owner can set fee amount");
        fee = _fee;
    }

    function getFeeAmount() public view returns (uint256) {
        return fee;
    }

    function hashMessage(
        address _campaignOwner,
        uint256 _chainId,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed
    ) public view returns (bytes32) {
        bytes memory pack = abi.encodePacked(
            this,
            _campaignOwner,
            _chainId,
            _campaignId,
            _prizeAddress,
            _prizeAmount,
            _maxEntries,
            _startTimestamp,
            _endTimestamp,
            _sealedSeed
        );
        return keccak256(pack);
    }

    function getCampaignContractAddress(string memory _campaignId)
        public
        view
        returns (address)
    {
        return campaigns[_campaignId];
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
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Campaign {
    string public campaignId;
    address payable immutable owner;
    address public immutable campaignOwner;
    address public immutable prizeAddress;
    uint256 public immutable prizeAmount;
    uint256 public immutable maxEntries;
    uint256 public immutable startTimestamp;
    uint256 public immutable endTimestamp;
    bytes32 private immutable sealedSeed;
    uint256 private feeAmount;
    uint256 private immutable depositAmount;

    uint256 private campaignOwnersContribution;
    uint256 private campaignOwnersContributionTotal;

    bytes32 public revealedSeed;

    mapping(address => bool) private freeEntry;
    mapping(address => address) private chain;
    mapping(uint256 => address) private cursorMap;

    uint256 public length;

    uint256 private rattleRandom;
    bool private cancelled;
    bool private depositReceived;

    function getUSDInWEI() public view returns (uint256) {
        address dataFeed;
        if (block.chainid == 1) {
            //Mainnet ETH/USD
            dataFeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
        } else if (block.chainid == 5) {
            //Goerli ETH/USD
            dataFeed = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
        } else if (block.chainid == 137) {
            //Polygon MATIC/USD
            dataFeed = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
        } else if (block.chainid == 80001) {
            //Mumbai MATIC/USD
            dataFeed = 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada;
        } else if (block.chainid == 56) {
            dataFeed = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
        } else if (block.chainid == 97) {
            //BSC BNBT/USD
            dataFeed = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;
        } else {
            // forTesting
            return 1e15;
        }
        AggregatorV3Interface priceFeed = AggregatorV3Interface(dataFeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return 1e26 / uint256(price);
    }

    function getUSCentInWEI() public view returns (uint256) {
        return getUSDInWEI() / 100;
    }

    event CampaignCreated(
        address campaignAddress,
        address campaignOwner,
        string campaignId,
        address prizeAddress,
        uint256 prizeAmount,
        uint256 maxEntries,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    constructor(
        address payable _owner,
        address _campaignOwner,
        string memory _campaignId,
        address _prizeAddress,
        uint256 _prizeAmount,
        uint256 _maxEntries,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bytes32 _sealedSeed,
        uint256 _deposit,
        uint256 _fee
    ) {
        owner = _owner;
        campaignOwner = _campaignOwner;
        campaignId = _campaignId;
        prizeAddress = _prizeAddress;
        prizeAmount = _prizeAmount;
        maxEntries = _maxEntries;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        sealedSeed = _sealedSeed;
        rattleRandom = uint256(_sealedSeed);
        uint256 cent = getUSCentInWEI();
        feeAmount = cent * _fee;
        depositAmount = cent * _deposit;
    }

    // function initialize(address creator, address payer) external {
    //     require(!initialized, "dao already initialized");
    //     initialized = true;
    //     ..
    // }

    function getDetail()
        public
        view
        returns (
            address _campaignOwner,
            string memory _campaignId,
            address _prizeAddress,
            uint256 _prizeAmount,
            uint256 _maxEntries,
            uint256 _startTimestamp,
            uint256 _endTimestamp,
            uint256 _entryCount
        )
    {
        return (
            campaignOwner,
            campaignId,
            prizeAddress,
            prizeAmount,
            maxEntries,
            startTimestamp,
            endTimestamp,
            length
        );
    }

    function hashMessage(address _user, uint256 _timestamp)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(this, _user, _timestamp));
    }

    function isStarted() public view returns (bool) {
        return block.timestamp >= startTimestamp;
    }

    function isNotClosed() public view returns (bool) {
        return block.timestamp < endTimestamp;
    }

    function isNotFull() public view returns (bool) {
        return length < maxEntries;
    }

    function isCancelled() public view returns (bool) {
        return cancelled;
    }

    function isDepositReceived() public view returns (bool) {
        return depositReceived;
    }

    function hasEntered(address _user) public view returns (bool) {
        return chain[_user] != address(0);
    }

    function getFreeDrawRemaining() public view returns (uint256) {
        return (feeAmount > 0) ? (campaignOwnersContribution / feeAmount) : 0;
    }

    function getStatus()
        public
        view
        returns (
            bool _hasEntered,
            bool _isStarted,
            bool _isNotClosed,
            bool _isRevealed,
            bool _isDepositReceived,
            bool _isCancelled,
            uint256 _totalEntries,
            uint256 _maxEntries,
            uint256 _fee,
            uint256 _freeDrawRemaining
        )
    {
        return (
            hasEntered(msg.sender),
            isStarted(),
            isNotClosed(),
            isRevealed(),
            isDepositReceived(),
            isCancelled(),
            length,
            maxEntries,
            feeAmount,
            getFreeDrawRemaining()
        );
    }

    function getFee() public view returns (uint256) {
        return feeAmount;
    }

    function setFeeZero() public {
        require(msg.sender == owner, "Only owner can set fee");
        require(!isStarted(), "Campaign has started");
        feeAmount = 0;
        if (campaignOwnersContribution > 0) {
            payable(campaignOwner).transfer(campaignOwnersContribution);
            campaignOwnersContribution = 0;
        }
    }

    function getEntryCount() public view returns (uint256) {
        return length;
    }

    function deposit() public payable {
        require(msg.sender == campaignOwner, "Only campaign owner can deposit");
        require(!depositReceived, "Deposit has already been received");
        require(!isCancelled(), "Campaign has been cancelled");
        require(isNotClosed(), "Campaign has ended");
        require(msg.value >= depositAmount, "You need to pay the deposit");
        if (msg.value > depositAmount) {
            payable(msg.sender).transfer(msg.value - depositAmount);
        }
        depositReceived = true;
    }

    function getDepositAmount() public view returns (uint256) {
        return depositAmount;
    }

    function setCampaignOwnersContribution() public payable {
        require(msg.sender == campaignOwner, "Only campaign owner can set");
        require(!isCancelled(), "Campaign has been cancelled");
        require(isNotClosed(), "Campaign has ended");
        require(
            campaignOwnersContribution + msg.value <= maxEntries * feeAmount,
            "You cannot contribute more than the maximum amount"
        );
        campaignOwnersContribution += msg.value;
    }

    function getCampaignOwnersContribution() public view returns (uint256) {
        return campaignOwnersContribution;
    }

    function isFreeDraw() public view returns (bool) {
        return campaignOwnersContribution >= feeAmount;
    }

    function isRevealed() public view returns (bool) {
        return revealedSeed != 0;
    }

    function setEntry(
        uint256 _timestamp,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public payable {
        require(isNotFull(), "Already reached the maximum number of entries");
        require(isStarted(), "Campaign has not started yet");
        require(isNotClosed(), "Campaign has ended");
        require(!isCancelled(), "Campaign has been cancelled");
        require(
            _timestamp + 5 minutes > block.timestamp,
            "Timestamp is not valid"
        );
        require(chain[msg.sender] == address(0), "You have already entered");

        bytes32 message = hashMessage(msg.sender, _timestamp);

        require(
            ecrecover(message, v, r, s) == owner,
            "You need signatures from the owner to set an entry"
        );

        if (isFreeDraw()) {
            campaignOwnersContribution -= feeAmount;
            campaignOwnersContributionTotal += feeAmount;
            freeEntry[msg.sender] = true;
        } else {
            require(
                msg.value >= feeAmount,
                "You need to pay the entry fee to enter"
            );
        }

        uint256 rand = uint256(
            keccak256(abi.encodePacked(message, rattleRandom, length))
        );

        if (length == 0) {
            chain[msg.sender] = msg.sender;
            cursorMap[0] = msg.sender;
        } else {
            address cursor = cursorMap[rand % length];
            chain[msg.sender] = chain[cursor];
            chain[cursor] = msg.sender;
            cursorMap[length] = msg.sender;
        }
        length++;
        rattleRandom = rand;
    }

    function withdrawAll() public {
        require(msg.sender == owner, "You are not the owner");
        require(
            endTimestamp + 365 days < block.timestamp,
            "Campaign has not ended yet"
        );
        payable(owner).transfer(address(this).balance);
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "transfer failed"
        );
    }

    function RecoverERC20(address _tokenAddress) public {
        require(msg.sender == owner, "You are not the owner");
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        safeTransfer(_tokenAddress, owner, balance);
    }

    function getPaybackAmount() public view returns (uint256) {
        return (length * feeAmount) / 2;
    }

    function payback() public payable {
        require(
            msg.sender == campaignOwner,
            "You are not the owner of the campaign"
        );
        require(!isCancelled(), "Campaign has been cancelled already");
        require(revealedSeed == 0, "Campaign has already been revealed");

        require(
            msg.value >= getPaybackAmount(),
            "You need to pay 1/2 of the fee that user paid"
        );

        uint256 campaignOwnersBack = isDepositReceived() ? depositAmount : 0;
        depositReceived = false;
        campaignOwnersBack += campaignOwnersContributionTotal;
        campaignOwnersBack += campaignOwnersContribution;
        campaignOwnersBack += msg.value - getPaybackAmount();
        payable(campaignOwner).transfer(campaignOwnersBack);
        payable(owner).transfer(msg.value);
        cancelled = true;
    }

    function paybackWithdraw() public {
        require(isCancelled(), "Campaign has not been cancelled");
        require(
            chain[msg.sender] != address(0) && !freeEntry[msg.sender],
            "You don't have right to withdraw"
        );
        chain[msg.sender] = address(0);
        payable(msg.sender).transfer(feeAmount);
    }

    function revealSeed(bytes32 _seed) public {
        require(!isNotClosed(), "Campaign has not ended yet");
        require(!isCancelled(), "Campaign has been cancelled");
        require(revealedSeed == 0, "Seed has already been revealed");
        require(
            block.timestamp > endTimestamp + 7 days ||
                msg.sender == campaignOwner,
            "You can not reveal the seed"
        );
        require(
            keccak256(abi.encodePacked(campaignId, _seed)) == sealedSeed,
            "Seed is not correct"
        );
        revealedSeed = _seed;
        rattleRandom = uint256(
            keccak256(abi.encodePacked(_seed, rattleRandom))
        );
        if (isDepositReceived()) {
            payable(msg.sender).transfer(depositAmount);
            depositReceived = false;
        }
        if (campaignOwnersContribution > 0) {
            payable(campaignOwner).transfer(campaignOwnersContribution);
            campaignOwnersContribution = 0;
        }
        payable(owner).transfer(address(this).balance);
    }

    function canDraw() public view returns (bool) {
        return revealedSeed > 0;
    }

    function draw() public view returns (address[] memory _winners) {
        require(canDraw(), "Seed has not been confirmed yet");

        address[] memory winners = new address[](prizeAmount);
        uint256 winnerNum = prizeAmount < length ? prizeAmount : length;
        address cursor = cursorMap[rattleRandom % length];
        for (uint256 i = 0; i < winnerNum; i++) {
            winners[i] = chain[cursor];
            cursor = chain[cursor];
        }
        for (uint256 i = winnerNum; i < prizeAmount; i++) {
            winners[i] = campaignOwner;
        }

        return winners;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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