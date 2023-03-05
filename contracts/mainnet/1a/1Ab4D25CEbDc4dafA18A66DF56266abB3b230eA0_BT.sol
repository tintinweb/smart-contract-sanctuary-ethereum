// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IPair.sol";

contract BT is Ownable {
    using SafeERC20 for IERC20;

    struct NFTinfo {
        address nftAddress;
        uint256[] ids;
    }

    struct TestamentTokens {
        IERC20[] erc20Tokens;
        NFTinfo[] erc721Tokens;
        NFTinfo[] erc1155Tokens;
    }

    struct Successors {
        address nft721successor; // nft721 tokens receiver
        address nft1155successor; // nft1155 tokens receiver
        address[] erc20successors; // array of erc20 tokens receivers
        uint256[] erc20shares; //array of erc20 tokens shares corresponding to erc20successors
    }

    struct Subscription {
        bool active;
        uint256 priceInQuoteToken;
        address paymentToken;
        address exchangePair;
        uint256 erc20SuccessorsLimit;
    }

    struct DeathConfirmation {
        uint256 confirmed;
        uint256 quorum;
        uint256 confirmationTime;
        address[] validators;
    }

    struct Testament {
        uint256 subscriptionID;
        uint256 expirationTime;
        Successors successors;
        DeathConfirmation voting;
    }

    enum DeathConfirmationState {
        NotExist,
        StillAlive,
        TestamentCanceled,
        Active,
        ConfirmationWaiting,
        Confirmed
    }

    uint256 public constant CONFIRMATION_LOCK = 180 days;
    uint256 public constant CONFIRMATION_PERIOD = 360 days;
    uint256 public constant BASE_POINT = 10000;
    uint256 public constant MAX_VALIDATORS = 30;
    uint256 public constant DISCOUNT_BP = 5000; // 50%
    uint256 public constant FREEMIUM_ID = 0;
    uint256 public constant FREEMIUM_FEE_BP = 300; // 3%

    address public feeAddress;
    address public immutable quoteTokenAddress;
    mapping(address => Testament) public testaments;
    mapping(address => bool) public firstPayment;

    // testamentOwner  => token   =>  amountPerShare
    mapping(address => mapping(address => uint256)) private amountsPerShare;
    // testamentOwner   =>  successor   =>  token  => already withdrawn
    mapping(address => mapping(address => mapping(address => bool)))
        private alreadyWithdrawn;

    Subscription[] public subscriptions;

    modifier validSubscriptionID(uint256 _sid) {
        require(
            _sid < subscriptions.length && subscriptions[_sid].active,
            "subscription is not valid"
        );
        _;
    }

    modifier correctStatus(
        DeathConfirmationState _state,
        address _testamentOwner,
        string memory _error
    ) {
        require(getDeathConfirmationState(_testamentOwner) == _state, _error);
        _;
    }

    event SubscriptionsAdded(Subscription _subscription);
    event SubscriptionStateChanged(uint256 subscriptionID, bool active);
    event TestamentDeleted(address testamentOwner);
    event SuccessorsChanged(address testamentOwner, Successors newSuccessors);
    event ValidatorsChanged(
        address user,
        uint256 newVoteQuorum,
        address[] newValidators
    );

    event CreateTestament(
        address user,
        uint256 priceInPaymentToken,
        Testament newTestament
    );
    event UpgradeTestamentPlan(
        address user,
        uint256 newSubscriptionId,
        uint256 expirationTime,
        uint256 priceInPaymentToken
    );

    event BillPayment(
        address testamentOwner,
        uint256 amountInPaymentToken,
        uint256 newexpirationTime
    );

    event DeathConfirmed(address testamentOwner, uint256 deathConfirmationTime);

    event GetTestament(address testamentOwner, address successor);

    constructor(address _feeAddress, address _quoteTokenAddress) {
        feeAddress = _feeAddress;
        quoteTokenAddress = _quoteTokenAddress;
        // FREEMIUM
        subscriptions.push(
            Subscription(
                true, // active
                0, 
                address(0), 
                address(0), 
                1 // erc20SuccessorsLimit
            )
        ); 
    }

    /**
     * @param _feeAddress: new feeAddress
     */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    /**
     * @notice add new payment plan
     * @param _subscription: {bool active;uint256 priceInQuoteToken;address paymentToken;address exchangePair;uint256 erc20SuccessorsLimit;}
     */
    function addSubscription(
        Subscription calldata _subscription
    ) external onlyOwner {
        require(
            _subscription.paymentToken !=address(0) 
            || _subscription.priceInQuoteToken == 0, 
            "paymentToken cannot be zero address"
        );
        if (_subscription.exchangePair != address(0)) {
            require(
                _subscription.priceInQuoteToken > 0,
                "priceInQuoteToken cannot be zero"
            );
            //not free
            IPair pair = IPair(_subscription.exchangePair);
            address token0 = pair.token0();
            address token1 = pair.token1();
            require(
                (token0 == quoteTokenAddress &&
                    token1 == _subscription.paymentToken) ||
                    (token0 == _subscription.paymentToken &&
                        token1 == quoteTokenAddress),
                "bad exchangePair address"
            );
        }
        subscriptions.push(_subscription);
        emit SubscriptionsAdded(_subscription);
    }

    /**
     * @notice activate-deactivate a subscription
     */
    function subscriptionStateChange(
        uint256 _sId,
        bool _active
    ) external onlyOwner {
        subscriptions[_sId].active = _active;
        emit SubscriptionStateChanged(_sId, _active);
    }

    function getPriceInPaymentToken(
        address _pair,
        uint256 _priceInQuoteToken
    ) public view returns (uint256) {
        if (_priceInQuoteToken > 0) {
            if (_pair == address(0)) {
                return (_priceInQuoteToken);
            }
            IPair pair = IPair(_pair);
            (uint112 reserves0, uint112 reserves1, ) = pair.getReserves();
            (uint112 reserveQuote, uint112 reserveBase) = pair.token0() ==
                quoteTokenAddress
                ? (reserves0, reserves1)
                : (reserves1, reserves0);

            if (reserveQuote > 0 && reserveBase > 0) {
                return (_priceInQuoteToken * reserveBase) / reserveQuote + 1;
            } else {
                revert("can't determine price");
            }
        } else {
            return 0;
        }
    }

    function checkSharesSUM(uint256[] memory _erc20shares) private pure {
        uint256 sharesSum;
        for (uint256 i = 0; i < _erc20shares.length; i++) {
            sharesSum += _erc20shares[i];
        }
        require(sharesSum == BASE_POINT, "incorrect shares sum");
    }

    /**
     * @notice assignment of successors
     */
    function setSuccessors(
        Successors calldata _newSuccessors
    )
        external
        correctStatus(
            DeathConfirmationState.StillAlive,
            msg.sender,
            "first confirm that you are still alive"
        )
    {
        Testament storage userTestament = testaments[msg.sender];
        Subscription memory userPaymentPlan = subscriptions[
            userTestament.subscriptionID
        ];
        require(
            _newSuccessors.erc20shares.length ==
                _newSuccessors.erc20successors.length,
            "erc20 successors and shares must be the same length"
        );
        require(
            userPaymentPlan.erc20SuccessorsLimit == 0 ||
                userPaymentPlan.erc20SuccessorsLimit >=
                _newSuccessors.erc20successors.length,
            "erc20 successors limit exceeded"
        );

        checkSharesSUM(_newSuccessors.erc20shares);

        userTestament.successors = _newSuccessors;

        emit SuccessorsChanged(msg.sender, _newSuccessors);
    }

    /**
     * @notice check validator's and quorum
     */
    function checkVoteParam(uint256 _quorum,uint256 _validatorsLength) private pure{
        require(_quorum >0 , "_quorum value must be greater than null");
        require(_validatorsLength <= MAX_VALIDATORS, "too many validators");
        require(_validatorsLength >= _quorum, "_quorum should be equal to number of validators");
    }

    /**
     * @notice the weight of the validator's vote in case of repetition of the address in _validators increases
     */
    function setValidators(
        uint256 _quorum,
        address[] calldata _validators
    )
        external 
        correctStatus(
            DeathConfirmationState.StillAlive,
            msg.sender,
            "first confirm that you are still alive"
        )
    {
        checkVoteParam(_quorum,_validators.length);

        Testament storage userTestament = testaments[msg.sender];
        // reset current voting state
        userTestament.voting.confirmed = 0;
        userTestament.voting.validators = _validators;
        userTestament.voting.quorum = _quorum;
        emit ValidatorsChanged(msg.sender, _quorum, _validators);
    }

    function deleteTestament() external {
        require(
            getDeathConfirmationState(msg.sender) <
                DeathConfirmationState.Confirmed,
            "alive only"
        );
        delete testaments[msg.sender];
        emit TestamentDeleted(msg.sender);
    }

    /**
     * @notice create testament 
     * @param _subscriptionId: ID of payment plan
     * @param _quorum: voting quorum
     * @param _validators: array of validators
     * @param _successors: array of successors
     */
    function createTestament(
        uint256 _subscriptionId,
        uint256 _quorum,
        address[] calldata _validators,
        Successors calldata _successors
    )
        external 
        correctStatus(
            DeathConfirmationState.NotExist,
            msg.sender,
            "already exist"
        )
        validSubscriptionID(_subscriptionId)
    {
        
        Subscription memory paymentPlan = subscriptions[_subscriptionId];

        require(
            _successors.erc20shares.length ==
                _successors.erc20successors.length,
            "erc20 successors and shares must be the same length"
        );
        require(
            paymentPlan.erc20SuccessorsLimit == 0 ||
                paymentPlan.erc20SuccessorsLimit >=
                _successors.erc20successors.length,
            "erc20 successors limit exceeded"
        );

        checkVoteParam(_quorum,_validators.length);
        checkSharesSUM(_successors.erc20shares);

        uint256 priceInPaymentToken = getPriceInPaymentToken(
                    paymentPlan.exchangePair,
                    paymentPlan.priceInQuoteToken
                );

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );
            // subscription is not free
            firstPayment[msg.sender]=true;
        }

        Testament memory newTestament = Testament(
            _subscriptionId,
            block.timestamp + CONFIRMATION_PERIOD,
            _successors,
            DeathConfirmation(0, _quorum, 0, _validators)
        );

        testaments[msg.sender] = newTestament;

        emit CreateTestament(msg.sender, priceInPaymentToken, newTestament);
    }

    function upgradeTestamentPlan(
        uint256 _subscriptionId
    )
        external
        correctStatus(
            DeathConfirmationState.StillAlive,
            msg.sender,
            "first confirm that you are still alive"
        )
        validSubscriptionID(_subscriptionId)
    {
        Testament memory userTestament = testaments[msg.sender];

        require(
            userTestament.subscriptionID != _subscriptionId,
            "already done"
        );
        Subscription memory paymentPlan = subscriptions[_subscriptionId];

        require(
            paymentPlan.erc20SuccessorsLimit == 0 ||
                paymentPlan.erc20SuccessorsLimit >=
                userTestament.successors.erc20successors.length,
            "the number of successors exceeds the limit for this subscription"
        );

        userTestament.expirationTime = block.timestamp + CONFIRMATION_PERIOD;
        
        bool _firstPayment=firstPayment[msg.sender];
        uint256 priceInPaymentToken = getPriceInPaymentToken(
                    paymentPlan.exchangePair,
                    (_firstPayment ? 
                    paymentPlan.priceInQuoteToken * DISCOUNT_BP / BASE_POINT 
                    : 
                    paymentPlan.priceInQuoteToken)
                );
        

        if (priceInPaymentToken > 0) {
            IERC20(paymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                priceInPaymentToken
            );

            if(!_firstPayment){
                firstPayment[msg.sender]=true;
            }
        }
        userTestament.subscriptionID = _subscriptionId;
        testaments[msg.sender] = userTestament;

        emit UpgradeTestamentPlan(
            msg.sender,
            _subscriptionId,
            userTestament.expirationTime,
            priceInPaymentToken
        );
    }

    /**
     * @notice confirm that you are still alive
     */
    function billPayment() external {
        DeathConfirmationState currentState = getDeathConfirmationState(
            msg.sender
        );
        require(
            currentState == DeathConfirmationState.StillAlive ||
                currentState == DeathConfirmationState.Active,
            "state should be StillAlive or Active or you can try to delete the testament while it not Confirmed"
        );
        Testament memory userTestament = testaments[msg.sender];
        Subscription memory userpaymentPlan = subscriptions[
            userTestament.subscriptionID
        ];

        require(
            block.timestamp >
                (userTestament.expirationTime - CONFIRMATION_PERIOD),
            "no more than two periods"
        );
        userTestament.voting.confirmed = 0;
        userTestament.expirationTime += CONFIRMATION_PERIOD;

        uint256 amountInPaymentToken = getPriceInPaymentToken(
                    userpaymentPlan.exchangePair,
                    userpaymentPlan.priceInQuoteToken * DISCOUNT_BP / BASE_POINT
                );
        if (amountInPaymentToken > 0) {
            IERC20(userpaymentPlan.paymentToken).safeTransferFrom(
                msg.sender,
                feeAddress,
                amountInPaymentToken
            );
        }

        testaments[msg.sender] = userTestament;

        emit BillPayment(
            msg.sender,
            amountInPaymentToken,
            userTestament.expirationTime
        );
    }

    function _getVotersCount(
        uint256 confirmed
    ) private pure returns (uint256 voiceCount) {
        while (confirmed > 0) {
            voiceCount += confirmed & 1;
            confirmed >>= 1;
        }
    }

    function getVotersCount(
        address testamentOwner
    ) external view returns (uint256 voiceCount) {
        DeathConfirmation memory voting = testaments[testamentOwner].voting;
        voiceCount = _getVotersCount(voting.confirmed);
    }

    function getVoters(
        address testamentOwner
    ) external view returns (address[] memory) {
        DeathConfirmation memory voting = testaments[testamentOwner].voting;
        address[] memory voters = new address[](voting.validators.length);
        if (voters.length > 0 && voting.confirmed > 0) {
            uint256 count;
            for (uint256 i = 0; i < voting.validators.length; i++) {
                if (voting.confirmed & (1 << i) != 0) {
                    voters[count] = voting.validators[i];
                    count++;
                }
            }

            assembly {
                mstore(voters, count)
            }
        }
        return voters;
    }

    function confirmDeath(
        address testamentOwner
    )
        external
        correctStatus(
            DeathConfirmationState.Active,
            testamentOwner,
            "voting is not active"
        )
    {
        Testament storage userTestament = testaments[testamentOwner];
        DeathConfirmation memory voting = userTestament.voting;

        for (uint256 i = 0; i < voting.validators.length; i++) {
            if (
                msg.sender == voting.validators[i] &&
                voting.confirmed & (1 << i) == 0
            ) {
                voting.confirmed |= (1 << i);
            }
        }
        userTestament.voting.confirmed = voting.confirmed;

        if (_getVotersCount(voting.confirmed) >= voting.quorum) {
            userTestament.voting.confirmationTime =
                block.timestamp +
                CONFIRMATION_LOCK;
            emit DeathConfirmed(
                testamentOwner,
                userTestament.voting.confirmationTime
            );
        }
    }

    /**
     * @notice get testament after death confirmation
     * call from successors
     * @param testamentOwner: testament creator
     * withdrawal info:
     * @param tokens: {IERC20[] erc20Tokens;NFTinfo[] erc721Tokens;NFTinfo[] erc1155Tokens;}
     * erc20Tokens: array of erc20 tokens
     * erc721Tokens: array of {address nftAddress;uint256[] ids;} objects
     * erc1155Tokens: array of {address nftAddress;uint256[] ids;} objects
     */

    function getTestament(
        address testamentOwner,
        TestamentTokens calldata tokens
    )
        external
        correctStatus(
            DeathConfirmationState.Confirmed,
            testamentOwner,
            "death must be confirmed"
        )
    {
        Testament memory userTestament = testaments[testamentOwner];
        Successors memory userSuccessors = userTestament.successors;

        if (userTestament.subscriptionID == FREEMIUM_ID) {
            require(
                tokens.erc20Tokens.length == 1 &&
                    address(tokens.erc20Tokens[0]) == quoteTokenAddress &&
                    tokens.erc721Tokens.length == 0 &&
                    tokens.erc1155Tokens.length == 0,
                "invalid tokens, the current subscription does not allow receiving these tokens"
            );
        }
        {
            uint256 userERC20Shares;

            for (
                uint256 i = 0;
                i < userSuccessors.erc20successors.length;
                i++
            ) {
                if (msg.sender == userSuccessors.erc20successors[i]) {
                    userERC20Shares += userSuccessors.erc20shares[i];
                }
            }

            if (userERC20Shares > 0) {
                // ERC20
                for (uint256 i = 0; i < tokens.erc20Tokens.length; i++) {
                    mapping(address => bool)
                        storage alreadyDone = alreadyWithdrawn[testamentOwner][
                            msg.sender
                        ];
                    if (alreadyDone[address(tokens.erc20Tokens[i])] == false) {
                        alreadyDone[address(tokens.erc20Tokens[i])] = true;
                        mapping(address => uint256)
                            storage amountPerShare = amountsPerShare[
                                testamentOwner
                            ];
                        uint256 perShare = amountPerShare[
                            address(tokens.erc20Tokens[i])
                        ];
                        
                        if (perShare == 0) {
                            
                            uint256 testamentOwnerBalance = tokens
                                .erc20Tokens[i]
                                .balanceOf(testamentOwner);
                            
                            if (userTestament.subscriptionID == FREEMIUM_ID) {
                                uint256 feeAmount =
                                    (testamentOwnerBalance * FREEMIUM_FEE_BP) /
                                    BASE_POINT;
                                if (feeAmount > 0) {
                                    IERC20(quoteTokenAddress).safeTransferFrom(
                                        testamentOwner,
                                        feeAddress,
                                        feeAmount
                                    );
                                    testamentOwnerBalance-=feeAmount;
                                }
                            }
                            
                            if(testamentOwnerBalance>0){
                                perShare = testamentOwnerBalance / BASE_POINT;
                                amountPerShare[
                                    address(tokens.erc20Tokens[i])
                                ] = perShare;
                                
                                tokens.erc20Tokens[i].safeTransferFrom(
                                    testamentOwner,
                                    address(this),
                                    testamentOwnerBalance
                                );
                            }
                        }
                        uint256 erc20Amount = userERC20Shares * perShare;
                        if (erc20Amount > 0) {
                            tokens.erc20Tokens[i].safeTransfer(
                                msg.sender,
                                erc20Amount
                            );
                        }
                    }
                }
            }
        }

        if (msg.sender == userSuccessors.nft721successor) {
            // ERC721
            for (uint256 i = 0; i < tokens.erc721Tokens.length; i++) {
                for (
                    uint256 x = 0;
                    x < tokens.erc721Tokens[i].ids.length;
                    x++
                ) {
                    IERC721(tokens.erc721Tokens[i].nftAddress).safeTransferFrom(
                            testamentOwner,
                            msg.sender,
                            tokens.erc721Tokens[i].ids[x]
                        );
                }
            }
        }

        if (msg.sender == userSuccessors.nft1155successor) {
            // ERC1155
            for (uint256 i = 0; i < tokens.erc1155Tokens.length; i++) {
                uint256[] memory batchBalances = new uint256[](
                    tokens.erc1155Tokens[i].ids.length
                );
                for (
                    uint256 x = 0;
                    x < tokens.erc1155Tokens[i].ids.length;
                    ++x
                ) {
                    batchBalances[x] = IERC1155(
                        tokens.erc1155Tokens[i].nftAddress
                    ).balanceOf(testamentOwner, tokens.erc1155Tokens[i].ids[x]);
                }
                IERC1155(tokens.erc1155Tokens[i].nftAddress)
                    .safeBatchTransferFrom(
                        testamentOwner,
                        msg.sender,
                        tokens.erc1155Tokens[i].ids,
                        batchBalances,
                        ""
                    );
            }
        }

        emit GetTestament(testamentOwner, msg.sender);
    }

    function getDeathConfirmationState(
        address testamentOwner
    ) public view returns (DeathConfirmationState) {
        Testament memory userTestament = testaments[testamentOwner];
        DeathConfirmation memory voting = userTestament.voting;

        if (userTestament.expirationTime > 0) {
            // voting started
            if (block.timestamp > userTestament.expirationTime) {
                if (_getVotersCount(voting.confirmed) >= voting.quorum) {
                    if (block.timestamp < voting.confirmationTime) {
                        return DeathConfirmationState.ConfirmationWaiting;
                    }

                    return DeathConfirmationState.Confirmed;
                }

                if (
                    block.timestamp <
                    (userTestament.expirationTime + CONFIRMATION_PERIOD)
                ) {
                    return DeathConfirmationState.Active;
                }

                return DeathConfirmationState.TestamentCanceled;
            } else {
                return DeathConfirmationState.StillAlive;
            }
        }

        return DeathConfirmationState.NotExist;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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