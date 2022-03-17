pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-4.4.1/proxy/Clones.sol";
import "./ExoticPositionalMarket.sol";
import "../interfaces/IThalesBonds.sol";
import "../interfaces/IExoticPositionalTags.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";

contract ExoticPositionalMarketManager is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    using SafeMathUpgradeable for uint;

    uint private constant backstopTimeoutDefault = 4 hours;
    uint private constant fixedBondAmountDefault = 100 * 1e18;

    uint public fixedBondAmount;
    uint public backstopTimeout;
    uint public minimumPositioningDuration;
    uint public claimTimeoutDefaultPeriod;
    uint public pDAOResolveTimePeriod;
    uint public safeBoxPercentage;
    uint public creatorPercentage;
    uint public resolverPercentage;
    uint public withdrawalPercentage;

    uint public maxOracleCouncilMembers;
    address public exoticMarketMastercopy;
    address public oracleCouncilAddress;
    address public safeBoxAddress;

    address public thalesBonds;
    address public paymentToken;
    uint public maximumPositionsAllowed;
    uint public disputePrice;

    mapping(uint => address) public pauserAddress;
    uint public pausersCount;
    mapping(address => uint) public pauserIndex;

    mapping(address => address) public creatorAddress;
    mapping(address => address) public resolverAddress;

    mapping(uint => address) public activeMarkets;
    uint public numOfActiveMarkets;

    address public tagsAddress;
    uint public maxNumberOfTags;
    uint public backstopTimeoutGeneral;
    uint public safeBoxLowAmount;
    uint public arbitraryRewardForDisputor;
    address public theRundownConsumerAddress;
    mapping(address => bool) public isChainLinkMarket;

    function initialize(
        address _owner,
        uint _minimumPositioningDuration,
        address _paymentToken
    ) public initializer {
        setOwner(_owner);
        initNonReentrant();
        minimumPositioningDuration = _minimumPositioningDuration;
        backstopTimeout = backstopTimeoutDefault;
        maximumPositionsAllowed = 5;
        paymentToken = _paymentToken;
        safeBoxPercentage = 1;
        creatorPercentage = 1;
        resolverPercentage = 1;
        withdrawalPercentage = 6;
        claimTimeoutDefaultPeriod = 1 days;
        pDAOResolveTimePeriod = 2 days;
        maxOracleCouncilMembers = 5;
        disputePrice = 10 * 1e18;
        maxNumberOfTags = 5;
    }

    // Create Exotic market
    function createExoticMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external checkMarketRequirements(_endOfPositioning) nonReentrant {
        require(IERC20(paymentToken).balanceOf(msg.sender) >= fixedBondAmount, "Low token amount for market creation");
        require(
            IERC20(paymentToken).allowance(msg.sender, thalesBonds) >= fixedBondAmount,
            "No allowance. Please approve ticket price allowance"
        );
        require(_tags.length > 0 && _tags.length <= maxNumberOfTags);
        require(
            keccak256(abi.encode(_marketQuestion)) != keccak256(abi.encode("")),
            "Invalid market question (empty string)"
        );
        require(keccak256(abi.encode(_marketSource)) != keccak256(abi.encode("")), "Invalid market source (empty string)");
        require(_positionCount == _positionPhrases.length, "Invalid position count with position phrases");
        require(bytes(_marketQuestion).length < 110, "Market question exceeds length");

        for (uint i = 0; i < _tags.length; i++) {
            require(
                IExoticPositionalTags(tagsAddress).isValidTagNumber(_tags[i]),
                "Not a valid tag. Tag number does not exists"
            );
        }

        ExoticPositionalMarket exoticMarket = ExoticPositionalMarket(Clones.clone(exoticMarketMastercopy));
        exoticMarket.initialize(
            _marketQuestion,
            _marketSource,
            _endOfPositioning,
            _fixedTicketPrice,
            _withdrawalAllowed,
            _tags,
            _positionCount,
            _positionPhrases
        );
        creatorAddress[address(exoticMarket)] = msg.sender;
        IThalesBonds(thalesBonds).sendCreatorBondToMarket(address(exoticMarket), msg.sender, exoticMarket.fixedBondAmount());
        activeMarkets[numOfActiveMarkets] = address(exoticMarket);
        numOfActiveMarkets = numOfActiveMarkets.add(1);
        emit MarketCreated(
            address(exoticMarket),
            _marketQuestion,
            _marketSource,
            _endOfPositioning,
            _fixedTicketPrice,
            _withdrawalAllowed,
            _tags,
            _positionCount,
            _positionPhrases,
            msg.sender
        );
    }

    function createCLMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external checkMarketRequirements(_endOfPositioning) nonReentrant {
        require(
            theRundownConsumerAddress != address(0),
            "Invalid theRundownConsumer address in Manager. Please set the theRundownConsumerAddress"
        );
        require(msg.sender == theRundownConsumerAddress, "Invalid creator. Creator has to be Therundownconsumer");
        require(_tags.length > 0 && _tags.length <= maxNumberOfTags);
        require(IERC20(paymentToken).balanceOf(msg.sender) >= fixedBondAmount, "Low token amount for market creation");
        require(
            IERC20(paymentToken).allowance(msg.sender, thalesBonds) >= fixedBondAmount,
            "No allowance. Please approve ticket price allowance"
        );
        require(
            keccak256(abi.encode(_marketQuestion)) != keccak256(abi.encode("")),
            "Invalid market question (empty string)"
        );
        require(keccak256(abi.encode(_marketSource)) != keccak256(abi.encode("")), "Invalid market source (empty string)");
        require(_positionCount == _positionPhrases.length, "Invalid position count with position phrases");
        require(bytes(_marketQuestion).length < 110, "Market question exceeds length");

        ExoticPositionalMarket exoticMarket = ExoticPositionalMarket(Clones.clone(exoticMarketMastercopy));
        exoticMarket.initialize(
            _marketQuestion,
            _marketSource,
            _endOfPositioning,
            _fixedTicketPrice,
            _withdrawalAllowed,
            _tags,
            _positionCount,
            _positionPhrases
        );
        isChainLinkMarket[address(exoticMarket)] = true;
        creatorAddress[address(exoticMarket)] = msg.sender;
        IThalesBonds(thalesBonds).sendCreatorBondToMarket(address(exoticMarket), msg.sender, exoticMarket.fixedBondAmount());
        activeMarkets[numOfActiveMarkets] = address(exoticMarket);
        numOfActiveMarkets = numOfActiveMarkets.add(1);
        emit MarketCreated(
            address(exoticMarket),
            _marketQuestion,
            _marketSource,
            _endOfPositioning,
            _fixedTicketPrice,
            _withdrawalAllowed,
            _tags,
            _positionCount,
            _positionPhrases,
            msg.sender
        );
    }

    function resolveMarket(address _marketAddress, uint _outcomePosition) external {
        require(isActiveMarket(_marketAddress), "Market is not active");
        if (isChainLinkMarket[_marketAddress]) {
            require(msg.sender == theRundownConsumerAddress, "Invalid resolver. Resolver can be only theRundownConsumer");
        }
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        if (creatorAddress[_marketAddress] != msg.sender) {
            require(
                IERC20(paymentToken).balanceOf(msg.sender) >= ExoticPositionalMarket(_marketAddress).fixedBondAmount(),
                "Low token amount for market creation"
            );
            require(
                IERC20(paymentToken).allowance(msg.sender, thalesBonds) >=
                    ExoticPositionalMarket(_marketAddress).fixedBondAmount(),
                "No allowance. Please approve ticket price allowance"
            );
            IThalesBonds(thalesBonds).sendResolverBondToMarket(
                _marketAddress,
                msg.sender,
                ExoticPositionalMarket(_marketAddress).fixedBondAmount()
            );
        }
        resolverAddress[_marketAddress] = msg.sender;
        ExoticPositionalMarket(_marketAddress).resolveMarket(_outcomePosition, msg.sender);
        emit MarketResolved(_marketAddress, _outcomePosition);
    }

    function cancelMarket(address _marketAddress) external onlyOracleCouncilAndOwner {
        require(isActiveMarket(_marketAddress), "Market is not active");
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        ExoticPositionalMarket(_marketAddress).cancelMarket();
        resolverAddress[msg.sender] = safeBoxAddress;
        removeActiveMarket(_marketAddress);
        emit MarketCanceled(_marketAddress);
    }

    function resetMarket(address _marketAddress) external onlyOracleCouncilAndOwner {
        require(isActiveMarket(_marketAddress), "Market is not active");
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        ExoticPositionalMarket(_marketAddress).resetMarket();
        emit MarketReset(_marketAddress);
    }

    function sendRewardToDisputor(
        address _market,
        address _disputorAddress,
        uint _amount
    ) external onlyOracleCouncilAndOwner {
        require(_amount > 0, "The arbitrary reward is zero. Please adjust.");
        IERC20(paymentToken).transfer(_disputorAddress, _amount);
        emit RewardSentToDisputorForMarket(_market, _disputorAddress, _amount);
    }

    function sendMarketBondAmountTo(
        address _market,
        address _recepient,
        uint _amount
    ) external onlyOracleCouncilAndOwner {
        require(_amount > 0, "Invalid amount");
        ExoticPositionalMarket(_market).transferFromBondAmountToRecepient(_recepient, _amount);
    }

    function disputeMarket(address _marketAddress, address _disputor) external onlyOracleCouncil {
        IThalesBonds(thalesBonds).sendDisputorBondToMarket(
            _marketAddress,
            _disputor,
            ExoticPositionalMarket(_marketAddress).disputePrice()
        );
        require(!ExoticPositionalMarket(_marketAddress).paused(), "Market is already paused");
        if (!ExoticPositionalMarket(_marketAddress).disputed()) {
            ExoticPositionalMarket(_marketAddress).openDispute();
        }
    }

    function closeDispute(address _marketAddress) external onlyOracleCouncilAndOwner {
        if (ExoticPositionalMarket(_marketAddress).paused()) {
            require(msg.sender == owner, "Only Protocol DAO can operate on paused market");
        }
        require(ExoticPositionalMarket(_marketAddress).disputed(), "Market not disputed");
        ExoticPositionalMarket(_marketAddress).closeDispute();
    }

    function getMarketBondAmount(address _market) external view returns (uint) {
        return ExoticPositionalMarket(_market).totalBondAmount();
    }

    function getActiveMarketAddress(uint _index) external view returns (address) {
        return activeMarkets[_index];
    }

    function getActiveMarketIndex(address _marketAddress) public view returns (uint) {
        for (uint i = 0; i < numOfActiveMarkets; i++) {
            if (activeMarkets[i] == _marketAddress) {
                return i;
            }
        }
        return numOfActiveMarkets;
    }

    function isActiveMarket(address _marketAddress) public view returns (bool) {
        return getActiveMarketIndex(_marketAddress) < numOfActiveMarkets;
    }

    function isPauserAddress(address _pauser) external view returns (bool) {
        return pauserIndex[_pauser] > 0;
    }

    // SETTERS ///////////////////////////////////////////////////////////////////////////

    function setSafeBoxAddress(address _safeBoxAddress) external onlyOwner {
        require(_safeBoxAddress != address(0), "Invalid safeBox address");
        safeBoxAddress = _safeBoxAddress;
        emit NewSafeBoxAddress(_safeBoxAddress);
    }

    function setBackstopTimeout(address _market) external onlyOracleCouncilAndOwner {
        ExoticPositionalMarket(_market).setBackstopTimeout(backstopTimeout);
    }

    function setCustomBackstopTimeout(address _market, uint _timeout) external onlyOracleCouncilAndOwner {
        require(_timeout > 0, "Invalid timeout");
        require(ExoticPositionalMarket(_market).backstopTimeout() != _timeout, "Equal timeout. No changes needed");
        ExoticPositionalMarket(_market).setBackstopTimeout(_timeout);
    }

    function setExoticMarketMastercopy(address _exoticMastercopy) external onlyOwner {
        require(_exoticMastercopy != address(0), "Exotic market invalid");
        exoticMarketMastercopy = _exoticMastercopy;
        emit ExoticMarketMastercopyChanged(_exoticMastercopy);
    }

    function setMinimumPositioningDuration(uint _duration) external onlyOwner {
        minimumPositioningDuration = _duration;
        emit MinimumPositionDurationChanged(_duration);
    }

    function setSafeBoxPercentage(uint _safeBoxPercentage) external onlyOwner {
        safeBoxPercentage = _safeBoxPercentage;
        emit SafeBoxPercentageChanged(_safeBoxPercentage);
    }

    function setCreatorPercentage(uint _creatorPercentage) external onlyOwner {
        creatorPercentage = _creatorPercentage;
        emit CreatorPercentageChanged(_creatorPercentage);
    }

    function setResolverPercentage(uint _resolverPercentage) external onlyOwner {
        resolverPercentage = _resolverPercentage;
        emit ResolverPercentageChanged(_resolverPercentage);
    }

    function setWithdrawalPercentage(uint _withdrawalPercentage) external onlyOwner {
        withdrawalPercentage = _withdrawalPercentage;
        emit WithdrawalPercentageChanged(_withdrawalPercentage);
    }

    function setPDAOResolveTimePeriod(uint _pDAOResolveTimePeriod) external onlyOwner {
        pDAOResolveTimePeriod = _pDAOResolveTimePeriod;
        emit setPDAOResolveTimePeriodChanged(_pDAOResolveTimePeriod);
    }

    function setOracleCouncilAddress(address _councilAddress) external onlyOwner {
        require(_councilAddress != address(0), "Invalid address");
        oracleCouncilAddress = _councilAddress;
        emit NewOracleCouncilAddress(_councilAddress);
    }

    function setTheRundownConsumerAddress(address _theRundownConsumerAddress) external onlyOwner {
        require(_theRundownConsumerAddress != address(0), "Invalid address");
        theRundownConsumerAddress = _theRundownConsumerAddress;
        emit NewTheRundownConsumerAddress(_theRundownConsumerAddress);
    }

    function setMaximumPositionsAllowed(uint _maximumPositionsAllowed) external onlyOwner {
        require(_maximumPositionsAllowed > 2, "Invalid Maximum positions allowed");
        maximumPositionsAllowed = _maximumPositionsAllowed;
        emit NewMaximumPositionsAllowed(_maximumPositionsAllowed);
    }

    function setMaxNumberOfTags(uint _maxNumberOfTags) external onlyOwner {
        require(_maxNumberOfTags > 2, "Invalid Maximum positions allowed");
        maxNumberOfTags = _maxNumberOfTags;
        emit NewMaxNumberOfTags(_maxNumberOfTags);
    }

    function setDisputePrice(uint _disputePrice) external onlyOwner {
        require(_disputePrice > 0, "Invalid dispute price");
        require(_disputePrice != disputePrice, "Price equal to last disputePrice");
        disputePrice = _disputePrice;
        emit NewDisputePrice(_disputePrice);
    }

    function setDefaultBackstopTimeout(uint _timeout) external onlyOwner {
        require(_timeout > 0, "Invalid timeout");
        require(_timeout != backstopTimeout, "Timeout equal to last backstopTimeout");
        backstopTimeout = _timeout;
        emit NewDefaultBackstopTimeout(_timeout);
    }

    function setFixedBondAmount(uint _bond) external onlyOwner {
        require(_bond > 0, "Invalid bond");
        require(_bond != fixedBondAmount, "Bond equal to last fixedBondAmount");
        fixedBondAmount = _bond;
        emit NewFixedBondAmount(_bond);
    }

    function setSafeBoxLowAmount(uint _safeBoxLowAmount) external onlyOwner {
        require(_safeBoxLowAmount > 0, "Invalid amount");
        require(_safeBoxLowAmount != safeBoxLowAmount, "Amount equal to SafeBoxLowAmount");
        require(_safeBoxLowAmount < disputePrice, "Amount must be lower than dispute price. Please adjust accordingly.");
        safeBoxLowAmount = _safeBoxLowAmount;
        emit NewSafeBoxLowAmount(_safeBoxLowAmount);
    }

    function setArbitraryRewardForDisputor(uint _arbitraryRewardForDisputor) external onlyOwner {
        require(_arbitraryRewardForDisputor > 0, "Invalid amount");
        require(_arbitraryRewardForDisputor != arbitraryRewardForDisputor, "Amount equal to ArbitraryRewardForDisputor");
        arbitraryRewardForDisputor = _arbitraryRewardForDisputor;
        emit NewArbitraryRewardForDisputor(_arbitraryRewardForDisputor);
    }

    function setClaimTimeoutDefaultPeriod(uint _claimTimeout) external onlyOwner {
        require(_claimTimeout > 0, "Invalid timeout");
        require(_claimTimeout != claimTimeoutDefaultPeriod, "Timeout equal to last ClaimTimeoutDefaultPeriod");
        claimTimeoutDefaultPeriod = _claimTimeout;
        emit NewClaimTimeoutDefaultPeriod(_claimTimeout);
    }

    function setMaxOracleCouncilMembers(uint _maxOracleCouncilMembers) external onlyOwner {
        require(_maxOracleCouncilMembers > 3, "Invalid Maximum Oracle Council members. Number too low");
        maxOracleCouncilMembers = _maxOracleCouncilMembers;
        emit NewMaxOracleCouncilMembers(_maxOracleCouncilMembers);
    }

    function setPaymentToken(address _paymentToken) external onlyOwner {
        require(_paymentToken != address(0), "Invalid address");
        paymentToken = _paymentToken;
        emit NewPaymentToken(_paymentToken);
    }

    function setThalesBonds(address _thalesBonds) external onlyOwner {
        require(_thalesBonds != address(0), "Invalid address");
        thalesBonds = _thalesBonds;
        emit NewThalesBonds(_thalesBonds);
    }

    function setTagsAddress(address _tagsAddress) external onlyOwner {
        require(_tagsAddress != address(0), "Invalid address");
        tagsAddress = _tagsAddress;
        emit NewTagsAddress(_tagsAddress);
    }

    function addPauserAddress(address _pauserAddress) external onlyOracleCouncilAndOwner {
        require(_pauserAddress != address(0), "Invalid address");
        require(pauserIndex[_pauserAddress] == 0, "Address already exists as pauser");
        pausersCount = pausersCount.add(1);
        pauserIndex[_pauserAddress] = pausersCount;
        pauserAddress[pausersCount] = _pauserAddress;
        emit PauserAddressAdded(_pauserAddress);
    }

    function removePauserAddress(address _pauserAddress) external onlyOracleCouncilAndOwner {
        require(_pauserAddress != address(0), "Invalid address");
        require(pauserIndex[_pauserAddress] != 0, "Invalid pauser address, not exists as pauser");
        pauserAddress[pauserIndex[_pauserAddress]] = pauserAddress[pausersCount];
        pauserIndex[pauserAddress[pausersCount]] = pauserIndex[_pauserAddress];
        pausersCount = pausersCount.sub(1);
        pauserIndex[_pauserAddress] = 0;
        emit PauserAddressRemoved(_pauserAddress);
    }

    // INTERNAL FUNCTIONS

    function removeActiveMarket(address _marketAddress) internal {
        activeMarkets[getActiveMarketIndex(_marketAddress)] = activeMarkets[numOfActiveMarkets.sub(1)];
        numOfActiveMarkets = numOfActiveMarkets.sub(1);
        activeMarkets[numOfActiveMarkets] = address(0);
    }

    event MinimumPositionDurationChanged(uint duration);
    event MinimumMarketMaturityDurationChanged(uint duration);
    event ExoticMarketMastercopyChanged(address _exoticMastercopy);
    event MarketResolved(address marketAddress, uint outcomePosition);
    event MarketCanceled(address marketAddress);
    event MarketReset(address marketAddress);
    event NewOracleCouncilAddress(address oracleCouncilAddress);
    event NewFixedBondAmount(uint fixedBond);
    event NewSafeBoxAddress(address safeBox);
    event NewTagsAddress(address tagsAddress);
    event NewMaximumPositionsAllowed(uint maximumPositionsAllowed);
    event NewPaymentToken(address paymentTokenAddress);
    event NewThalesBonds(address thalesBondsAddress);
    event ResolverPercentageChanged(uint resolverPercentage);
    event CreatorPercentageChanged(uint creatorPercentage);
    event SafeBoxPercentageChanged(uint safeBoxPercentage);
    event WithdrawalPercentageChanged(uint withdrawalPercentage);
    event setPDAOResolveTimePeriodChanged(uint pDAOResolveTimePeriod);
    event NewMaxOracleCouncilMembers(uint maxOracleCouncilMembers);
    event PauserAddressAdded(address pauserAddress);
    event PauserAddressRemoved(address pauserAddress);
    event MarketPaused(address marketAddress);
    event NewDisputePrice(uint disputePrice);
    event NewMaxNumberOfTags(uint maxNumberOfTags);
    event NewArbitraryRewardForDisputor(uint arbitraryRewardForDisputor);
    event NewClaimTimeoutDefaultPeriod(uint claimTimeout);
    event NewDefaultBackstopTimeout(uint timeout);
    event NewSafeBoxLowAmount(uint safeBoxLowAmount);
    event RewardSentToDisputorForMarket(address market, address disputorAddress, uint amount);
    event NewTheRundownConsumerAddress(address theRundownConsumerAddress);
    event MarketCreated(
        address marketAddress,
        string marketQuestion,
        string marketSource,
        uint endOfPositioning,
        uint fixedTicketPrice,
        bool withdrawalAllowed,
        uint[] tags,
        uint positionCount,
        string[] positionPhrases,
        address marketOwner
    );

    modifier checkMarketRequirements(uint _endOfPositioning) {
        require(exoticMarketMastercopy != address(0), "No ExoticMarket mastercopy present. Please update the mastercopy");
        require(thalesBonds != address(0), "Invalid Thales bond address");
        require(
            _endOfPositioning >= block.timestamp.add(minimumPositioningDuration),
            "Posiitioning period too low. Increase the endOfPositioning"
        );
        _;
    }

    modifier onlyOracleCouncil() {
        require(msg.sender == oracleCouncilAddress, "Not OracleCouncil address");
        require(oracleCouncilAddress != address(0), "Not OracleCouncil address. Please update valid Oracle address");
        _;
    }
    modifier onlyOracleCouncilAndOwner() {
        require(msg.sender == oracleCouncilAddress || msg.sender == owner, "Not OracleCouncil Address or Owner address");
        if (msg.sender != owner) {
            require(oracleCouncilAddress != address(0), "Not OracleCouncil address. Please update valid Oracle address");
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-4.4.1/access/Ownable.sol";
import "@openzeppelin/contracts-4.4.1/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "./OraclePausable.sol";
import "@openzeppelin/contracts-4.4.1/token/ERC20/utils/SafeERC20.sol";
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../interfaces/IExoticPositionalMarketManager.sol";

contract ExoticPositionalMarket is Initializable, ProxyOwned, OraclePausable, ProxyReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    enum TicketType {FIXED_TICKET_PRICE, FLEXIBLE_BID}
    uint private safeBoxAmount;
    uint private constant HUNDRED = 100;
    uint private constant ONE_PERCENT = 1e16;
    uint private constant HUNDRED_PERCENT = 1e18;
    uint private constant FIXED_BOND_AMOUNT = 100 * 1e18;
    uint private constant CANCELED = 0;

    struct MarketData {
        string marketQuestion;
        string marketSource;
        TicketType ticketType;
        uint endOfPositioning;
        uint fixedTicketPrice;
        uint creationTime;
        bool withdrawalAllowed;
        bool disputed;
        bool resolved;
        uint resolvedTime;
        string[] positionPhrasesList;
        uint[] tags;
        uint totalPlacedAmount;
        uint totalClaimableAmount;
        uint[] amountsPerPosition;
        bool canUsersPlacePosition;
        bool canMarketBeResolved;
        bool canMarketBeResolvedByPDAO;
        bool canUsersClaim;
        bool isCancelled;
        bool paused;
        uint winningPosition;
        address creatorAddress;
        address resolverAddress;
        uint fixedBondAmount;
        uint disputePrice;
        uint safeBoxLowAmount;
        uint arbitraryRewardForDisputor;
    }

    uint public creationTime;
    uint public resolvedTime;
    uint public lastDisputeTime;
    bool public disputed;

    // from init
    string public marketQuestion;
    string public marketSource;
    TicketType public ticketType;
    mapping(uint => string) public positionPhrase;
    uint public positionCount;
    uint public endOfPositioning;
    uint public marketMaturity;
    uint public fixedTicketPrice;
    uint[] public tags;
    uint public backstopTimeout;
    bool public withdrawalAllowed;
    IExoticPositionalMarketManager public marketManager;
    address public resolverAddress;

    //stats
    uint public totalUsersTakenPositions;
    mapping(uint => uint) public ticketsPerPosition;
    mapping(address => uint) public userPosition;

    // open bid parameters
    uint public totalOpenBidAmount;
    uint public claimableOpenBidAmount;
    mapping(uint => uint) public totalOpenBidAmountPerPosition;
    mapping(address => mapping(uint => uint)) public userOpenBidPosition;

    bool public resolved;
    bool public disputedInPositioningPhase;
    bool public firstUserClaimed;
    uint public winningPosition;
    uint public claimableTicketsCount;

    uint public totalBondAmount;
    uint public disputeClosedTime;

    uint public fixedBondAmount;
    uint public disputePrice;
    uint public safeBoxLowAmount;
    uint public arbitraryRewardForDisputor;

    function initialize(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external initializer {
        require(
            _positionCount >= 2 && _positionCount <= IExoticPositionalMarketManager(msg.sender).maximumPositionsAllowed(),
            "Invalid number of provided positions"
        );
        require(_tags.length > 0);
        setOwner(msg.sender);
        marketManager = IExoticPositionalMarketManager(msg.sender);
        _initializeWithTwoParameters(
            _marketQuestion,
            _marketSource,
            _endOfPositioning,
            _fixedTicketPrice,
            _withdrawalAllowed,
            _tags,
            _positionPhrases[0],
            _positionPhrases[1]
        );
        if (_positionCount > 2) {
            for (uint i = 2; i < _positionCount; i++) {
                _addPosition(_positionPhrases[i]);
            }
        }
        fixedBondAmount = marketManager.fixedBondAmount();
        disputePrice = marketManager.disputePrice();
        safeBoxLowAmount = marketManager.safeBoxLowAmount();
        arbitraryRewardForDisputor = marketManager.arbitraryRewardForDisputor();
    }

    function takeAPosition(uint _position) external notPaused {
        require(_position > 0, "Position can not be zero. Non-zero position expected");
        require(_position <= positionCount, "Position exceeds number of positions");
        require(canUsersPlacePosition(), "Not able to position. Positioning time finished or market resolved");
        //require(same position)
        require(ticketType == TicketType.FIXED_TICKET_PRICE, "Not a Fixed price market");
        if (userPosition[msg.sender] == 0) {
            transferToMarket(msg.sender, fixedTicketPrice);
            totalUsersTakenPositions = totalUsersTakenPositions.add(1);
        } else {
            ticketsPerPosition[userPosition[msg.sender]] = ticketsPerPosition[userPosition[msg.sender]].sub(1);
        }
        ticketsPerPosition[_position] = ticketsPerPosition[_position].add(1);
        userPosition[msg.sender] = _position;
        emit NewPositionTaken(msg.sender, _position, fixedTicketPrice);
    }

    function takeOpenBidPositions(uint[] memory _positions, uint[] memory _amounts) external notPaused {
        require(_positions.length > 0, "Invalid positions. Please add at least a single position");
        require(_positions.length <= positionCount, "Position exceeds number of positions");
        require(canUsersPlacePosition(), "Not able to position. Positioning time finished or market resolved");
        require(ticketType == TicketType.FLEXIBLE_BID, "Not an Open Bid market type");
        uint totalDepositedAmount = 0;
        bool firstTime = true;
        for (uint i = 0; i < _positions.length; i++) {
            require(_positions[i] > 0, "Position can not be zero. Non-zero position expected");
            require(_positions[i] <= positionCount, "Position exceeds number of positions");
            require(_amounts[i] > 0, "Zero amount for position");
            // add to the amount of the position
            totalOpenBidAmountPerPosition[_positions[i]] = totalOpenBidAmountPerPosition[_positions[i]].add(_amounts[i]);
            // add to the total amount
            totalOpenBidAmount = totalOpenBidAmount.add(_amounts[i]);
            if (userOpenBidPosition[msg.sender][_positions[i]] > 0) {
                firstTime = false;
            }
            userOpenBidPosition[msg.sender][_positions[i]] = userOpenBidPosition[msg.sender][_positions[i]].add(_amounts[i]);
            totalDepositedAmount = totalDepositedAmount.add(_amounts[i]);
        }
        totalUsersTakenPositions = firstTime ? totalUsersTakenPositions.add(1) : totalUsersTakenPositions;
        transferToMarket(msg.sender, totalDepositedAmount);
        emit NewOpenBidsForPositions(msg.sender, _positions, _amounts);
    }

    function withdraw() external notPaused {
        require(withdrawalAllowed, "Withdrawal not allowed");
        require(canUsersPlacePosition(), "Not able to withdraw. Positioning time finished or market resolved");
        if (ticketType == TicketType.FIXED_TICKET_PRICE) {
            require(userPosition[msg.sender] > 0, "Not a ticket holder");
            uint withdrawalFee =
                fixedTicketPrice.mul(marketManager.withdrawalPercentage()).mul(ONE_PERCENT).div(HUNDRED_PERCENT);
            safeBoxAmount = safeBoxAmount.add(withdrawalFee.div(2));
            totalUsersTakenPositions = totalUsersTakenPositions.sub(1);
            ticketsPerPosition[userPosition[msg.sender]] = ticketsPerPosition[userPosition[msg.sender]].sub(1);
            userPosition[msg.sender] = 0;
            IERC20(marketManager.paymentToken()).safeTransfer(
                marketManager.creatorAddress(address(this)),
                withdrawalFee.div(2)
            );
            IERC20(marketManager.paymentToken()).safeTransfer(msg.sender, fixedTicketPrice.sub(withdrawalFee));
            emit TicketWithdrawn(msg.sender, fixedTicketPrice.sub(withdrawalFee));
        } else {
            // withdraw all for open bid
            uint totalToWithdraw;
            for (uint i = 1; i <= positionCount; i++) {
                if (userOpenBidPosition[msg.sender][i] > 0) {
                    totalToWithdraw = totalToWithdraw.add(userOpenBidPosition[msg.sender][i]);
                    userOpenBidPosition[msg.sender][i] = 0;
                }
            }
            totalUsersTakenPositions = totalUsersTakenPositions.sub(1);
            totalOpenBidAmount = totalOpenBidAmount.sub(totalToWithdraw);
            uint withdrawalFee =
                totalToWithdraw.mul(marketManager.withdrawalPercentage()).mul(ONE_PERCENT).div(HUNDRED_PERCENT);
            safeBoxAmount = safeBoxAmount.add(withdrawalFee.div(2));
            IERC20(marketManager.paymentToken()).safeTransfer(
                marketManager.creatorAddress(address(this)),
                withdrawalFee.div(2)
            );
            IERC20(marketManager.paymentToken()).safeTransfer(msg.sender, totalToWithdraw.sub(withdrawalFee));
            emit OpenBidUserWithdrawn(msg.sender, totalToWithdraw.sub(withdrawalFee), totalOpenBidAmount);
        }
    }

    function withdrawFromOpenBidPosition(uint _openBidPosition) external notPaused {
        require(withdrawalAllowed, "Withdrawal not allowed");
        require(canUsersPlacePosition(), "Not able to withdraw. Positioning time finished or market resolved");
        require(ticketType == TicketType.FLEXIBLE_BID, "Market is not open bid");
        require(userOpenBidPosition[msg.sender][_openBidPosition] > 0, "No amount placed for the position by the user");
        uint totalToWithdraw = userOpenBidPosition[msg.sender][_openBidPosition];
        userOpenBidPosition[msg.sender][_openBidPosition] = 0;
        if (getUserOpenBidTotalPlacedAmount(msg.sender) == 0) {
            totalUsersTakenPositions = totalUsersTakenPositions.sub(1);
        }
        totalOpenBidAmount = totalOpenBidAmount.sub(totalToWithdraw);
        uint withdrawalFee = totalToWithdraw.mul(marketManager.withdrawalPercentage()).mul(ONE_PERCENT).div(HUNDRED_PERCENT);
        safeBoxAmount = safeBoxAmount.add(withdrawalFee.div(2));
        IERC20(marketManager.paymentToken()).safeTransfer(marketManager.creatorAddress(address(this)), withdrawalFee.div(2));
        IERC20(marketManager.paymentToken()).safeTransfer(msg.sender, totalToWithdraw.sub(withdrawalFee));
        emit OpenBidUserWithdrawn(msg.sender, totalToWithdraw.sub(withdrawalFee), totalOpenBidAmount);
    }

    // market resolved only through the Manager
    function resolveMarket(uint _outcomePosition, address _resolverAddress) external onlyOwner {
        require(canMarketBeResolved(), "Market can not be resolved. It is disputed/not matured/resolved");
        require(_outcomePosition <= positionCount, "Outcome position exeeds the position");
        winningPosition = _outcomePosition;
        if (ticketType == TicketType.FIXED_TICKET_PRICE) {
            if (_outcomePosition == CANCELED) {
                claimableTicketsCount = totalUsersTakenPositions;
                ticketsPerPosition[winningPosition] = totalUsersTakenPositions;
            } else {
                claimableTicketsCount = ticketsPerPosition[_outcomePosition];
            }
        } else {
            // Flexible bid
            if (_outcomePosition == CANCELED) {
                claimableOpenBidAmount = totalOpenBidAmount;
                totalOpenBidAmountPerPosition[_outcomePosition] = totalOpenBidAmount;
            } else {
                claimableOpenBidAmount = getTotalClaimableAmount();
            }
        }
        resolved = true;
        resolvedTime = block.timestamp;
        resolverAddress = _resolverAddress;
        emit MarketResolved(_outcomePosition, _resolverAddress);
    }

    function resetMarket() external onlyOwner {
        require(resolved, "Market is not resolved");
        if (ticketType == TicketType.FIXED_TICKET_PRICE) {
            if (winningPosition == CANCELED) {
                ticketsPerPosition[winningPosition] = 0;
            }
            claimableTicketsCount = 0;
        } else {
            // Flexible bid
            if (winningPosition == CANCELED) {
                totalOpenBidAmountPerPosition[winningPosition] = 0;
            }
            claimableOpenBidAmount = 0;
        }
        resolved = false;
        resolvedTime = 0;
        resolverAddress = address(0);
        emit MarketReset();
    }

    function cancelMarket() external onlyOwner {
        winningPosition = CANCELED;
        if (ticketType == TicketType.FIXED_TICKET_PRICE) {
            claimableTicketsCount = totalUsersTakenPositions;
            ticketsPerPosition[winningPosition] = totalUsersTakenPositions;
        } else {
            // _resolveFlexibleBid(_outcomePosition);
            claimableOpenBidAmount = totalOpenBidAmount;
            totalOpenBidAmountPerPosition[winningPosition] = totalOpenBidAmount;
        }
        resolved = true;
        resolvedTime = block.timestamp;
        resolverAddress = marketManager.safeBoxAddress();
        emit MarketResolved(CANCELED, msg.sender);
    }

    function claimWinningTicket() external notPaused {
        require(canUsersClaim(), "Market not finalized");
        uint amount = getUserClaimableAmount(msg.sender);
        require(amount > 0, "Claimable amount is zero.");
        if (ticketType == TicketType.FIXED_TICKET_PRICE) {
            claimableTicketsCount = claimableTicketsCount.sub(1);
            userPosition[msg.sender] = 0;
        } else {
            claimableOpenBidAmount = claimableOpenBidAmount.sub(amount);
            resetForUserAllPositionsToZero(msg.sender);
        }
        IERC20(marketManager.paymentToken()).safeTransfer(msg.sender, amount);
        if (!firstUserClaimed) {
            IERC20(marketManager.paymentToken()).safeTransfer(
                marketManager.creatorAddress(address(this)),
                getAdditionalCreatorAmount()
            );
            IERC20(marketManager.paymentToken()).safeTransfer(
                marketManager.resolverAddress(address(this)),
                getAdditionalResolverAmount()
            );
            IERC20(marketManager.paymentToken()).safeTransfer(marketManager.safeBoxAddress(), getSafeBoxAmount());
            firstUserClaimed = true;
        }
        emit WinningTicketClaimed(msg.sender, amount);
    }

    function claimWinningTicketOnBehalf(address _user) external onlyOwner {
        require(canUsersClaim(), "Market not finalized");
        uint amount = getUserClaimableAmount(_user);
        require(amount > 0, "Claimable amount is zero.");
        if (ticketType == TicketType.FIXED_TICKET_PRICE) {
            claimableTicketsCount = claimableTicketsCount.sub(1);
            userPosition[_user] = 0;
        } else {
            claimableOpenBidAmount = claimableOpenBidAmount.sub(amount);
            resetForUserAllPositionsToZero(_user);
        }
        IERC20(marketManager.paymentToken()).safeTransfer(_user, amount);
        if (!firstUserClaimed) {
            IERC20(marketManager.paymentToken()).safeTransfer(
                marketManager.creatorAddress(address(this)),
                getAdditionalCreatorAmount()
            );
            IERC20(marketManager.paymentToken()).safeTransfer(
                marketManager.resolverAddress(address(this)),
                getAdditionalResolverAmount()
            );
            IERC20(marketManager.paymentToken()).safeTransfer(marketManager.safeBoxAddress(), getSafeBoxAmount());
            firstUserClaimed = true;
        }
        emit WinningTicketClaimed(msg.sender, amount);
    }

    function openDispute() external onlyOwner {
        require(isMarketCreated(), "Market not created");
        require(!disputed, "Market already disputed");
        disputed = true;
        disputedInPositioningPhase = canUsersPlacePosition();
        lastDisputeTime = block.timestamp;
        emit MarketDisputed(true);
    }

    function closeDispute() external onlyOwner {
        require(disputed, "Market not disputed");
        disputeClosedTime = block.timestamp;
        if (disputedInPositioningPhase) {
            disputed = false;
            disputedInPositioningPhase = false;
        } else {
            disputed = false;
        }
        emit MarketDisputed(false);
    }

    function transferToMarket(address _sender, uint _amount) public notPaused nonReentrant {
        require(_sender != address(0), "Invalid sender address");
        require(IERC20(marketManager.paymentToken()).balanceOf(_sender) >= _amount, "Sender balance low");
        require(
            IERC20(marketManager.paymentToken()).allowance(_sender, address(this)) >= _amount,
            "No allowance. Please adjust the allowance"
        );
        IERC20(marketManager.paymentToken()).safeTransferFrom(_sender, address(this), _amount);
    }

    function transferBondToMarket(address _sender, uint _amount) external notPaused {
        totalBondAmount = totalBondAmount.add(_amount);
        transferToMarket(_sender, _amount);
    }

    function transferFromBondAmountToRecepient(address _recepient, uint _amount) public onlyOwner {
        require(_amount <= totalBondAmount, "Exceeds the total bond amount");
        require(_recepient != address(0), "Invalid sender address");
        require(IERC20(marketManager.paymentToken()).balanceOf(address(this)) >= _amount, "Market balance low");
        totalBondAmount = totalBondAmount.sub(_amount);
        IERC20(marketManager.paymentToken()).safeTransfer(_recepient, _amount);
    }

    // SETTERS ///////////////////////////////////////////////////////

    function setBackstopTimeout(uint _timeoutPeriod) external onlyOwner {
        backstopTimeout = _timeoutPeriod;
        emit BackstopTimeoutPeriodChanged(_timeoutPeriod);
    }

    // VIEWS /////////////////////////////////////////////////////////

    function isMarketCreated() public view returns (bool) {
        return creationTime > 0;
    }

    function isMarketCancelled() public view returns (bool) {
        return resolved && winningPosition == CANCELED;
    }

    function canUsersPlacePosition() public view returns (bool) {
        return block.timestamp <= endOfPositioning && creationTime > 0 && !resolved;
    }

    function canMarketBeResolved() public view returns (bool) {
        return block.timestamp >= endOfPositioning && creationTime > 0 && (!disputed) && !resolved;
    }

    function canMarketBeResolvedByPDAO() public view returns (bool) {
        return canMarketBeResolved() && block.timestamp >= endOfPositioning.add(marketManager.pDAOResolveTimePeriod());
    }

    function canUsersClaim() public view returns (bool) {
        return
            resolved &&
            (!disputed) &&
            ((resolvedTime > 0 && block.timestamp > resolvedTime.add(marketManager.claimTimeoutDefaultPeriod())) ||
                (backstopTimeout > 0 &&
                    resolvedTime > 0 &&
                    disputeClosedTime > 0 &&
                    block.timestamp > disputeClosedTime.add(backstopTimeout)));
    }

    function canUserClaim(address _user) external view returns (bool) {
        return canUsersClaim() && getUserClaimableAmount(_user) > 0;
    }

    function canUserWithdraw(address _account) public view returns (bool) {
        if (ticketType == TicketType.FLEXIBLE_BID) {
            return withdrawalAllowed && canUsersPlacePosition() && getUserOpenBidTotalPlacedAmount(_account) > 0;
        } else {
            return withdrawalAllowed && canUsersPlacePosition() && userPosition[_account] > 0;
        }
    }

    function getPositionPhrase(uint index) public view returns (string memory) {
        return (index <= positionCount && index > 0) ? positionPhrase[index] : string("");
    }

    function getTotalPlacedAmount() public view returns (uint) {
        if (ticketType == TicketType.FLEXIBLE_BID) {
            return totalOpenBidAmount;
        } else {
            return fixedTicketPrice.mul(totalUsersTakenPositions);
        }
    }

    function getTotalClaimableAmount() public view returns (uint) {
        if (totalUsersTakenPositions == 0) {
            return 0;
        } else {
            return applyDeduction(getTotalPlacedAmount());
        }
    }

    function getTotalFeesAmount() public view returns (uint) {
        return getTotalPlacedAmount().sub(getTotalClaimableAmount());
    }

    function getPlacedAmountPerPosition(uint _position) public view returns (uint) {
        if (ticketType == TicketType.FLEXIBLE_BID) {
            return totalOpenBidAmountPerPosition[_position];
        } else {
            return fixedTicketPrice.mul(ticketsPerPosition[_position]);
        }
    }

    function getUserClaimableAmount(address _account) public view returns (uint) {
        if (ticketType == TicketType.FLEXIBLE_BID) {
            return getUserOpenBidTotalClaimableAmount(_account);
        } else {
            return
                (userPosition[_account] > 0 && (userPosition[_account] == winningPosition || winningPosition == CANCELED))
                    ? getWinningAmountPerTicket()
                    : 0;
        }
    }

    /// FLEXIBLE BID FUNCTIONS

    function getUserOpenBidTotalPlacedAmount(address _account) public view returns (uint) {
        uint amount = 0;
        for (uint i = 1; i <= positionCount; i++) {
            amount = amount.add(userOpenBidPosition[_account][i]);
        }
        return amount;
    }

    function getUserOpenBidPositionPlacedAmount(address _account, uint _position) external view returns (uint) {
        return userOpenBidPosition[_account][_position];
    }

    function getAllUserPositions(address _account) external view returns (uint[] memory) {
        uint[] memory userAllPositions = new uint[](positionCount);
        if (positionCount == 0) {
            return userAllPositions;
        }
        if (ticketType == TicketType.FLEXIBLE_BID) {
            for (uint i = 1; i <= positionCount; i++) {
                userAllPositions[i - 1] = userOpenBidPosition[_account][i];
            }
            return userAllPositions;
        } else {
            userAllPositions[userPosition[_account]] = 1;
            return userAllPositions;
        }
    }

    function getUserOpenBidPotentialWinningForPosition(address _account, uint _position) public view returns (uint) {
        if (_position == CANCELED) {
            return 0;
        }
        return
            userOpenBidPosition[_account][_position].mul(getTotalClaimableAmount()).div(
                totalOpenBidAmountPerPosition[_position]
            );
    }

    function getUserOpenBidTotalClaimableAmount(address _account) public view returns (uint) {
        return getUserOpenBidPotentialWinningForPosition(_account, winningPosition);
    }

    /// FIXED TICKET FUNCTIONS

    function getUserPosition(address _account) external view returns (uint) {
        return userPosition[_account];
    }

    function getUserPositionPhrase(address _account) external view returns (string memory) {
        return (userPosition[_account] > 0) ? positionPhrase[userPosition[_account]] : string("");
    }

    function getPotentialWinningAmountForPosition(uint _position) external view returns (uint) {
        if (totalUsersTakenPositions == 0) {
            return 0;
        } else {
            return getTotalClaimableAmount().div(ticketsPerPosition[_position]);
        }
    }

    function getWinningAmountPerTicket() public view returns (uint) {
        if (totalUsersTakenPositions == 0 || !resolved || (ticketsPerPosition[winningPosition] == 0)) {
            return 0;
        } else {
            return getTotalClaimableAmount().div(ticketsPerPosition[winningPosition]);
        }
    }

    function getAlreadyClaimedTickets() external view returns (uint) {
        return canUsersClaim() ? ticketsPerPosition[winningPosition].sub(claimableTicketsCount) : 0;
    }

    function applyDeduction(uint value) internal view returns (uint) {
        return
            (value)
                .mul(
                HUNDRED.sub(
                    marketManager.safeBoxPercentage().add(marketManager.creatorPercentage()).add(
                        marketManager.resolverPercentage()
                    )
                )
            )
                .mul(ONE_PERCENT)
                .div(HUNDRED_PERCENT);
    }

    function getTagsCount() public view returns (uint) {
        return tags.length;
    }

    function getAllMarketData() external view returns (MarketData memory) {
        string[] memory positionPhrasesList = new string[](positionCount);
        uint[] memory amountsPerPosition = new uint[](positionCount);
        if (positionCount > 0) {
            for (uint i = 1; i <= positionCount; i++) {
                positionPhrasesList[i - 1] = positionPhrase[i];
                amountsPerPosition[i - 1] = getPlacedAmountPerPosition(i);
            }
        }

        MarketData memory marketData;
        marketData.marketQuestion = marketQuestion;
        marketData.marketSource = marketSource;
        marketData.ticketType = ticketType;
        marketData.endOfPositioning = endOfPositioning;
        marketData.fixedTicketPrice = fixedTicketPrice;
        marketData.creationTime = creationTime;
        marketData.withdrawalAllowed = withdrawalAllowed;
        marketData.disputed = disputed;
        marketData.resolved = resolved;
        marketData.resolvedTime = resolvedTime;
        marketData.positionPhrasesList = positionPhrasesList;
        marketData.tags = tags;
        marketData.totalPlacedAmount = getTotalPlacedAmount();
        marketData.totalClaimableAmount = getTotalClaimableAmount();
        marketData.amountsPerPosition = amountsPerPosition;
        marketData.canUsersPlacePosition = canUsersPlacePosition();
        marketData.canMarketBeResolved = canMarketBeResolved();
        marketData.canMarketBeResolvedByPDAO = canMarketBeResolvedByPDAO();
        marketData.canUsersClaim = canUsersClaim();
        marketData.isCancelled = isMarketCancelled();
        marketData.paused = paused;
        marketData.winningPosition = winningPosition;
        marketData.creatorAddress = marketManager.creatorAddress(address(this));
        marketData.resolverAddress = marketManager.resolverAddress(address(this));
        marketData.fixedBondAmount = fixedBondAmount;
        marketData.disputePrice = disputePrice;
        marketData.safeBoxLowAmount = safeBoxLowAmount;
        marketData.arbitraryRewardForDisputor = arbitraryRewardForDisputor;

        return marketData;
    }

    function getAllAmounts()
        external
        view
        returns (
            uint,
            uint,
            uint,
            uint
        )
    {
        return (fixedBondAmount, disputePrice, safeBoxLowAmount, arbitraryRewardForDisputor);
    }

    // INTERNAL FUNCTIONS

    function resetForUserAllPositionsToZero(address _account) internal nonReentrant {
        if (positionCount > 0) {
            for (uint i = 1; i <= positionCount; i++) {
                userOpenBidPosition[_account][i] = 0;
            }
        }
    }

    function getAdditionalCreatorAmount() internal view returns (uint) {
        return getTotalPlacedAmount().mul(marketManager.creatorPercentage()).mul(ONE_PERCENT).div(HUNDRED_PERCENT);
    }

    function getAdditionalResolverAmount() internal view returns (uint) {
        return getTotalPlacedAmount().mul(marketManager.resolverPercentage()).mul(ONE_PERCENT).div(HUNDRED_PERCENT);
    }

    function getSafeBoxAmount() internal view returns (uint) {
        return getTotalFeesAmount().add(safeBoxAmount).sub(getAdditionalCreatorAmount()).sub(getAdditionalResolverAmount());
    }

    function _initializeWithTwoParameters(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        string memory _positionPhrase1,
        string memory _positionPhrase2
    ) internal {
        creationTime = block.timestamp;
        marketQuestion = _marketQuestion;
        marketSource = _marketSource;
        endOfPositioning = _endOfPositioning;
        // Ticket Type can be determined based on ticket price
        ticketType = _fixedTicketPrice > 0 ? TicketType.FIXED_TICKET_PRICE : TicketType.FLEXIBLE_BID;
        fixedTicketPrice = _fixedTicketPrice;
        // Withdrawal allowance determined based on withdrawal percentage, if it is over 100% then it is forbidden
        withdrawalAllowed = _withdrawalAllowed;
        // The tag is just a number for now
        tags = _tags;
        _addPosition(_positionPhrase1);
        _addPosition(_positionPhrase2);
    }

    function _addPosition(string memory _position) internal {
        require(keccak256(abi.encode(_position)) != keccak256(abi.encode("")), "Invalid position label (empty string)");
        require(bytes(_position).length < 50, "Position label exceeds length");
        positionCount = positionCount.add(1);
        positionPhrase[positionCount] = _position;
    }

    event MarketDisputed(bool disputed);
    event MarketCreated(uint creationTime, uint positionCount, bytes32 phrase);
    event MarketResolved(uint winningPosition, address resolverAddress);
    event MarketReset();
    event WinningTicketClaimed(address account, uint amount);
    event BackstopTimeoutPeriodChanged(uint timeoutPeriod);
    event NewPositionTaken(address account, uint position, uint fixedTicketAmount);
    event TicketWithdrawn(address account, uint amount);
    event BondIncreased(uint amount, uint totalAmount);
    event BondDecreased(uint amount, uint totalAmount);
    event NewOpenBidsForPositions(address account, uint[] openBidPositions, uint[] openBidAmounts);
    event OpenBidUserWithdrawn(address account, uint withdrawnAmount, uint totalOpenBidAmountLeft);
}

pragma solidity ^0.8.0;

interface IThalesBonds {
    /* ========== VIEWS / VARIABLES ========== */
    function getTotalDepositedBondAmountForMarket(address _market) external view returns(uint);
    function getClaimedBondAmountForMarket(address _market) external view returns(uint);
    function getClaimableBondAmountForMarket(address _market) external view returns(uint);
    function getDisputorBondForMarket(address _market, address _disputorAddress) external view returns (uint);

    function sendCreatorBondToMarket(address _market, address _creatorAddress, uint _amount) external;
    function sendResolverBondToMarket(address _market, address _resolverAddress, uint _amount) external;
    function sendDisputorBondToMarket(address _market, address _disputorAddress, uint _amount) external;
    function sendBondFromMarketToUser(address _market, address _account, uint _amount) external;
    function sendOpenDisputeBondFromMarketToDisputor(address _market, address _account, uint _amount) external;
    function setOracleCouncilAddress(address _oracleCouncilAddress) external;
    function setManagerAddress(address _managerAddress) external;
}

pragma solidity ^0.8.0;

interface IExoticPositionalTags {
    /* ========== VIEWS / VARIABLES ========== */
    function isValidTagNumber(uint _number) external view returns (bool);
    function isValidTagLabel(string memory _label) external view returns (bool);
    function isValidTag(string memory _label, uint _number) external view returns (bool);
    function getTagLabel(uint _number) external view returns (string memory);
    function getTagNumber(string memory _label) external view returns (uint);
    function getTagNumberIndex(uint _number) external view returns (uint);
    function getTagIndexNumber(uint _index) external view returns (uint);
    function getTagByIndex(uint _index) external view returns (string memory, uint);
    function getTagsCount() external view returns (uint);

    function addTag(string memory _label, uint _number) external;
    function editTagNumber(string memory _label, uint _number) external;
    function editTagLabel(string memory _label, uint _number) external;
    function removeTag(uint _number) external;
}

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

// Inheritance
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../interfaces/IExoticPositionalMarketManager.sol";

// Clone of syntetix contract without constructor

contract OraclePausable is ProxyOwned {
    uint public lastPauseTime;
    bool public paused;

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused) external pauserOnly {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }
        if (paused) {
            require(msg.sender == IExoticPositionalMarketManager(owner).owner(), "Only Protocol DAO can unpause");
        }
        // Set our paused state.
        paused = _paused;

        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }

    modifier pauserOnly {
        require(
            IExoticPositionalMarketManager(owner).isPauserAddress(msg.sender) ||
                IExoticPositionalMarketManager(owner).owner() == msg.sender ||
                owner == msg.sender,
            "This action cannot be performed by non-pauser address"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;

interface IExoticPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */
    function getActiveMarketAddress(uint _index) external view returns(address);
    function getActiveMarketIndex(address _marketAddress) external view returns(uint);
    function isActiveMarket(address _marketAddress) external view returns(bool);
    function numOfActiveMarkets() external view returns(uint);
    function getMarketBondAmount(address _market) external view returns (uint);
    function maximumPositionsAllowed() external view returns(uint);
    function paymentToken() external view returns(address);
    function owner() external view returns(address);
    function thalesBonds() external view returns(address);
    function oracleCouncilAddress() external view returns(address);
    function safeBoxAddress() external view returns(address);
    function creatorAddress(address _market) external view returns(address);
    function resolverAddress(address _market) external view returns(address);
    function isPauserAddress(address _pauserAddress) external view returns(bool);
    function safeBoxPercentage() external view returns(uint);
    function creatorPercentage() external view returns(uint);
    function resolverPercentage() external view returns(uint);
    function withdrawalPercentage() external view returns(uint);
    function pDAOResolveTimePeriod() external view returns(uint);
    function claimTimeoutDefaultPeriod() external view returns(uint);
    function maxOracleCouncilMembers() external view returns(uint);
    function fixedBondAmount() external view returns(uint);
    function disputePrice() external view returns(uint);
    function safeBoxLowAmount() external view returns(uint);
    function arbitraryRewardForDisputor() external view returns(uint);

    function createExoticMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external;
    
    function createCLMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external;
    
    function disputeMarket(address _marketAddress, address disputor) external;
    function resolveMarket(address _marketAddress, uint _outcomePosition) external;
    function resetMarket(address _marketAddress) external;
    function cancelMarket(address _market) external ;
    function closeDispute(address _market) external ;
    function setBackstopTimeout(address _market) external; 
    function sendMarketBondAmountTo(address _market, address _recepient, uint _amount) external;
    function addPauserAddress(address _pauserAddress) external;
    function removePauserAddress(address _pauserAddress) external;
    function sendRewardToDisputor(address _market, address _disputorAddress, uint amount) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}