/// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import "../helpers/STOErrors.sol";
import "../interfaces/IRouter.sol";

/// @title STOEscrowUpgradeable
/// @custom:security-contact [email protected]
contract STOEscrowUpgradeable is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    STOErrors
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using MathUpgradeable for uint256;

    /// @dev An issuance can be ACTIVE, WITHDRAWN (The issuance was succesfull and the issuer withdrawn),
    /// ROLLBACK (The issuance was not succesfull and the issuer has finalized it)
    enum IssuanceStatuses {
        ACTIVE,
        WITHDRAWN,
        ROLLBACK
    }

    /// @dev Issuance struct
    /// @param status Issuance status based on previous enum
    /// @param minTicket Min amount in USD (18 decimals) for issuance participation
    /// @param maxTicket Max amount in USD (18 decimals) for issuance participation
    /// @param startDate Unix timestamp of when the issuance will start
    /// @param endDate Unix timestamp of when the issuance will end
    /// @param hardCap Amount in USD (18 decimals) that can be collected at most
    /// @param softCap Amount in USD (18 decimals) that must be collected at least for an issuance to be succesfull
    /// @param raisedAmount Amount in USD (18 decimals) raised in the issuance so far
    /// @param issuanceAmount Amount of STO tokens issued
    /// @param priceInUSD Price in USD (18 decimals) of each STO token unit -> hardCap / issuanceAmount
    struct Issuance {
        IssuanceStatuses status;
        uint256 minTicket;
        uint256 maxTicket;
        uint256 startDate;
        uint256 endDate;
        uint256 hardCap;
        uint256 softCap;
        uint256 raisedAmount;
        uint256 issuanceAmount;
        uint256 priceInUSD;
    }

    /// @dev Struct to whitelist a new ERC20 token
    /// @param status status to enable or disable the token
    /// @param multiplier Multiplier of ERC20 token (1 ether = 1e18 by default, otherwise specified)
    struct ERC20Token {
        bool status;
        uint256 multiplier;
    }

    /// @dev Investor struct
    /// @param redeemed whether the user has reedemed the STO tokens or not
    /// @param redeemed whether the user has been refunded or not
    /// @param amountInPaymentToken Amount of paymentToken used to buy STO tokens in the issuance
    /// @param amountInSTO Amount of STO tokens estimated in this issuance
    struct Investor {
        bool redeemed;
        bool refunded;
        uint256 amountInPaymentToken;
        uint256 amountInSTO;
    }

    /// @dev Address of the STO token related to this escrow service
    ISTOToken public stoRelatedToken;

    /// @dev Address of the ERC20 token used for the issuer to withdraw the funds or investors being refunded
    IERC20MetadataUpgradeable public paymentToken;

    /// @dev Address of Uniswap v2 router to swap whitelisted ERC20 tokens to paymentToken
    IRouter public router;

    /// @dev Address of the issuer of new STO token offerings
    address public issuer;

    ///@dev Treasury address
    address public treasuryAddress;

    /// @dev Array of Address ERC20 Token Whitelisted
    address[] private tokensERC20;

    /// @dev Fee for each withdraw in paymentToken in each issuance. (from 1 to 10000, equivalent to 0.01% to 100%)
    uint256 public withdrawalFee;

    /// @dev Index of latest issuance
    uint256 public issuanceIndex;

    /// @dev Mapping of ERC20 whitelisted tokens
    mapping(address => ERC20Token) public tokenERC20Whitelist;

    /// @dev Issuances by issuance index
    mapping(uint256 => Issuance) public issuances;

    /// @dev Issuance Index ---> Address of investor ---> Investor struct
    mapping(uint256 => mapping(address => Investor)) public investors;

    /// Events

    /// @dev Event to signal that a new offering has been created
    /// @param issuanceIndex Issuannce index of the new issuance
    /// @param issuance Initial struct of the new issuance
    event NewOffering(uint256 indexed issuanceIndex, Issuance issuance);

    /// @dev Event to signal that the list of whitelisted ERC20 tokens has changed
    /// @param issuer Issuer address
    /// @param token Array of ERC20 tokens where whitelist changed
    /// @param multiplier Array of multipliers applied to each ERC20 token
    /// @param status Array of statuses applied to each ERC20 token
    event ERC20Whitelisted(
        address indexed issuer,
        address[] token,
        uint256[] multiplier,
        bool[] status
    );

    /// @dev Event to signal that an user redeemed his tokens
    /// @param investor User address
    /// @param issuanceIndex Index of the issuance
    /// @param amountInSTO Amount of STO token redeemed
    event Redeemed(
        address indexed investor,
        uint256 indexed issuanceIndex,
        uint256 indexed amountInSTO
    );

    /// @dev Event to signal that an user has been refunded
    /// @param investor User address
    /// @param issuanceIndex Index of the issuance
    /// @param amountInPaymentToken Amount of paymentToken equivalent to the user investment that has been refunded
    event Refunded(
        address indexed investor,
        uint256 indexed issuanceIndex,
        uint256 indexed amountInPaymentToken
    );

    /// @dev Event to signal that an user made an offer to buy STO tokens
    /// @param investor User address
    /// @param ERC20Token ERC20 token used by the user
    /// @param issuanceIndex Index of the issuance
    /// @param amountInPaymentToken Amount of paymentToken offered by the user
    event TicketOffered(
        address indexed investor,
        address indexed ERC20Token,
        uint256 indexed issuanceIndex,
        uint256 amountInPaymentToken
    );

    /// @dev Event to signal that the issuer has withdrawn all the funds collected in the issuance
    /// @param issuer Issuer address
    /// @param issuanceIndex Index of the issuance
    /// @param fee Brickken success fee (amount of paymentToken)
    /// @param amountInPaymentToken Amount of paymentToken raised in the issuance
    event Withdrawn(
        address indexed issuer,
        uint256 indexed issuanceIndex,
        uint256 fee,
        uint256 indexed amountInPaymentToken
    );

    /// @dev Event to signal that an issuance has entered into rollback state, funds will be refunded
    /// @param issuer Issuer address
    /// @param issuanceIndex Index of the issuance
    /// @param amountInPaymentToken Amount of paymentToken raised during the issuance
    event RollBack(
        address indexed issuer,
        uint256 indexed issuanceIndex,
        uint256 indexed amountInPaymentToken
    );

    /// @dev Event to signal that the issuer has changed
    /// @param issuer New issuer address
    event ChangeIssuer(address indexed issuer);

    /// @dev Event to signal that the paymentToken address changed
    /// @param newPaymentTokenAddress paymentToken address
    event ChangePaymentTokenAddress(address indexed newPaymentTokenAddress);

    /// @dev Event to signal that the router changed address
    /// @param newRouterAddress New router address
    event ChangeRouterAddress(address indexed newRouterAddress);

    /// @dev Event to signal that the success fee has changed, (from 1 to 10000, equivalent to 0.01% to 100%)
    /// @param oldFee Old fee percentage
    /// @param newFee New fee percentage
    event ChangeWithdrawalFee(uint256 indexed oldFee, uint256 indexed newFee);

    /// @dev modifier for check if the address is the issuer of the STO Escrow
    modifier onlyIssuer() {
        if (_msgSender() != issuer) revert CallerIsNotIssuer(_msgSender());
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _stoToken,
        address _newIssuer,
        address _owner,
        address _paymentToken,
        address _router,
        address _treasuryAddress
    ) public reinitializer(1) {
        ///Prevent anyone from reinitializing the contract
        if (owner() != address(0) && _msgSender() != owner())
            revert CallerIsNotOwner(_msgSender());

        _transferOwnership(_owner);
        __ReentrancyGuard_init();

        stoRelatedToken = ISTOToken(_stoToken);
        paymentToken = IERC20MetadataUpgradeable(_paymentToken);

        //Automatically add the paymentToken as mean of payment with 1 as multiplier
        tokenERC20Whitelist[address(paymentToken)].status = true;
        tokenERC20Whitelist[address(paymentToken)].multiplier = 1 ether;

        router = IRouter(_router);
        issuer = _newIssuer;
        treasuryAddress = _treasuryAddress;
        withdrawalFee = 1; /// 0,01%
    }

    /// @dev Method to change the issuer of the contract
    /// @param newIssuer The new issuer
    function changeIssuer(address newIssuer) external onlyOwner {
        issuer = newIssuer;

        emit ChangeIssuer(issuer);
    }

    /// @dev Method to change the paymentToken related to this escrow contract
    /// @param newPaymentToken Address of new payment token
    /// This function should not be called with an active issuance going on
    function setPaymentToken(address newPaymentToken) external onlyOwner {
        tokenERC20Whitelist[address(paymentToken)].status = false;
        tokenERC20Whitelist[address(newPaymentToken)].status = true;
        tokenERC20Whitelist[address(newPaymentToken)].multiplier = 1 ether;

        paymentToken = IERC20MetadataUpgradeable(newPaymentToken);
        emit ChangePaymentTokenAddress(newPaymentToken);
    }

    /// @dev Method to change the Uniswap router address
    /// @param newRouter Address of the new router contract
    /// This function should not be called with an active issuance going on
    function setRouter(address newRouter) external onlyOwner {
        router = IRouter(newRouter);
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            IERC20MetadataUpgradeable _token = IERC20MetadataUpgradeable(
                tokensERC20[i]
            );

            uint256 currentAllowance = _token.allowance(
                address(this),
                address(router)
            );

            if (currentAllowance != type(uint256).max) {
                SafeERC20Upgradeable.safeApprove(
                    _token,
                    address(router),
                    type(uint256).max - currentAllowance
                );
            }
        }
        emit ChangeRouterAddress(newRouter);
    }

    /// @dev Method to change the list of whitelisted ERC20 tokens
    /// @param tokensToChange Array of ERC20 tokens to be changed in the whitelist
    /// @param multipliers Array of multipliers for each ERC20 token
    /// @param statuses Array of statuses for each ERC20 token
    function changeWhitelist(
        address[] calldata tokensToChange,
        uint256[] calldata multipliers,
        bool[] calldata statuses
    ) external onlyOwner {
        for (uint256 i = 0; i < tokensToChange.length; i++) {
            if (multipliers[i] == 0) revert InitialValueWrong(issuer);

            if (!tokensToChange[i].isContract())
                revert AddressIsNotContract(tokensToChange[i], issuer);

            if (!isTokenERC20(tokensToChange[i]))
                tokensERC20.push(tokensToChange[i]);

            uint256 allowance = IERC20Upgradeable(tokensToChange[i]).allowance(
                address(this),
                address(router)
            );

            if (statuses[i] && allowance != type(uint256).max) {
                SafeERC20Upgradeable.safeIncreaseAllowance(
                    IERC20Upgradeable(tokensToChange[i]),
                    address(router),
                    type(uint256).max - allowance
                );
            } else {
                SafeERC20Upgradeable.safeDecreaseAllowance(
                    IERC20Upgradeable(tokensToChange[i]),
                    address(router),
                    allowance
                );
            }

            tokenERC20Whitelist[tokensToChange[i]].status = statuses[i];
            tokenERC20Whitelist[tokensToChange[i]].multiplier = multipliers[i];
        }

        emit ERC20Whitelisted(issuer, tokensToChange, multipliers, statuses);
    }

    /// @dev Method to change the withdrawal fee (success fee)
    /// @param newFee Fee to be charged for withdrawal
    function changeWithdrawalFee(uint256 newFee) external onlyOwner {
        if (newFee > 10000) revert FeeOverLimits(newFee);
        uint256 oldFee = withdrawalFee;
        withdrawalFee = newFee;

        emit ChangeWithdrawalFee(oldFee, newFee);
    }

    /// @dev Method to start a new offering
    /// @param newIssuance Struct with all the data of the new issuance
    function newOffering(Issuance memory newIssuance) external onlyIssuer {
        address caller = _msgSender();

        if ((issuanceIndex != 0) && (!isEnded(issuanceIndex)))
            revert IssuanceNotEnded(caller, issuances[issuanceIndex].endDate);

        if (
            (issuanceIndex != 0) &&
            !(isWithdrawn(issuanceIndex) || isRollback(issuanceIndex))
        ) revert IssuanceNotFinalized(caller);

        if (
            newIssuance.maxTicket < newIssuance.minTicket ||
            newIssuance.startDate < block.timestamp ||
            newIssuance.endDate <= newIssuance.startDate ||
            newIssuance.hardCap < newIssuance.softCap ||
            newIssuance.raisedAmount != 0 ||
            newIssuance.issuanceAmount == 0 ||
            newIssuance.priceInUSD !=
            newIssuance.hardCap.mulDiv(1 ether, newIssuance.issuanceAmount)
        ) revert InitialValueWrong(caller);

        if (
            stoRelatedToken.maxSupply() > 0 &&
            newIssuance.issuanceAmount >
            (stoRelatedToken.maxSupply() - stoRelatedToken.totalSupply())
        ) revert MaxSupplyExceeded();

        issuanceIndex++;

        issuances[issuanceIndex] = Issuance({
            status: IssuanceStatuses.ACTIVE,
            minTicket: newIssuance.minTicket,
            maxTicket: newIssuance.maxTicket,
            startDate: newIssuance.startDate,
            endDate: newIssuance.endDate,
            hardCap: newIssuance.hardCap,
            softCap: newIssuance.softCap,
            raisedAmount: 0,
            issuanceAmount: newIssuance.issuanceAmount,
            priceInUSD: newIssuance.priceInUSD
        });

        emit NewOffering(issuanceIndex, issuances[issuanceIndex]);
    }

    /// @dev Method to finalize an issuance
    /// @dev Only the issuer or the owner can finalize it
    function finalizeIssuance() external nonReentrant {
        address caller = _msgSender();

        if (caller != issuer && caller != owner())
            revert CallerIsNotOwner(caller);

        _checkIssuanceCompleteness(caller, issuanceIndex);

        if (isSuccess(issuanceIndex)) {
            _withdraw();
        } else if (!isSuccess(issuanceIndex)) {
            _rollBack();
        }
    }

    /// @dev Method for the user to either redeem the STO tokens or be refunded in paymentTokens
    function getTokens(uint256 index) external nonReentrant {
        address caller = _msgSender();

        _checkIssuanceCompleteness(caller, index);

        if (isSuccess(index)) {
            _redeemToken(index);
        } else {
            _refundToken(index);
        }
    }

    /// @dev Method to offer a ticket in the current issuance
    /// @param tokenUsed ERC20 token to be used to buy the ticket
    /// @param amountOfTokens Amount of tokens to offer, exchanged for paymentToken. Decimals are the ones of the `tokenUsed`.
    function buyToken(address tokenUsed, uint256 amountOfTokens)
        external
        nonReentrant
    {
        address caller = _msgSender();
        uint256 actualAmount;

        _checkValidStatus(caller, tokenUsed);

        // Auxiliary variables useful for the calculations
        uint256 paymentTokenScale = 10**paymentToken.decimals();
        uint256 stoRelatedTokenScale = 10**stoRelatedToken.decimals();

        if (tokenUsed != address(paymentToken)) {
            uint256 priceInPaymentToken = getPriceInPaymentToken(tokenUsed)
                .mulDiv( // Price in paymentToken of the ERC20 used
                tokenERC20Whitelist[tokenUsed].multiplier, /// Discount the Price in case of BKN token
                1 ether,
                MathUpgradeable.Rounding.Up
            ); /// Rounding Up

            uint256 amountOfPaymentTokens = amountOfTokens.mulDiv( // Amount of paymentTokens equivalent to the amount passed in
                priceInPaymentToken,
                10**IERC20MetadataUpgradeable(tokenUsed).decimals(),
                MathUpgradeable.Rounding.Down
            ); ///Rounding Down

            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(tokenUsed),
                caller,
                address(this),
                amountOfTokens
            );

            uint256 previewBalance = paymentToken.balanceOf(address(this));

            _swapTokensForTokens(
                tokenUsed,
                amountOfTokens,
                amountOfPaymentTokens
            );

            uint256 balance = paymentToken.balanceOf(address(this));

            //Slippage user protection must be tested
            /*
                if (
                    (balance - previewBalance) <
                    amountOfPaymentTokens.sub(
                        amountOfPaymentTokens.mulDiv(
                            3,
                            1000,
                            MathUpgradeable.Rounding.Up
                        )
                    )
                )
                    revert SwapFailure(
                        caller,
                        _tokenERC20,
                        priceInPaymentToken,
                        balance - previewBalance
                    );
            */
            actualAmount = balance - previewBalance;

            _validateInputs(actualAmount, caller);
        } else {
            actualAmount = amountOfTokens;

            _validateInputs(actualAmount, caller);

            SafeERC20Upgradeable.safeTransferFrom(
                IERC20MetadataUpgradeable(tokenUsed),
                caller,
                address(this),
                actualAmount
            );
        }

        /// Logic to store the ticket to the investor
        if (!isInvestor(issuanceIndex, caller)) {
            investors[issuanceIndex][caller] = Investor({
                redeemed: false,
                refunded: false,
                amountInPaymentToken: actualAmount,
                amountInSTO: actualAmount
                    .mulDiv(
                        stoRelatedTokenScale,
                        paymentTokenScale,
                        MathUpgradeable.Rounding.Up
                    )
                    .mulDiv(
                        stoRelatedTokenScale,
                        issuances[issuanceIndex].priceInUSD,
                        MathUpgradeable.Rounding.Down
                    )
            });
        } else {
            uint256 newAmount = investors[issuanceIndex][caller]
                .amountInPaymentToken
                .add(actualAmount);
            investors[issuanceIndex][caller].amountInPaymentToken = newAmount;
            investors[issuanceIndex][caller].amountInSTO = newAmount
                .mulDiv(
                    stoRelatedTokenScale,
                    paymentTokenScale,
                    MathUpgradeable.Rounding.Up
                )
                .mulDiv(
                    stoRelatedTokenScale,
                    issuances[issuanceIndex].priceInUSD,
                    MathUpgradeable.Rounding.Down
                );
        }

        issuances[issuanceIndex].raisedAmount += actualAmount
            .mulDiv(
                stoRelatedTokenScale,
                paymentTokenScale,
                MathUpgradeable.Rounding.Up
            )
            .mulDiv(
                stoRelatedTokenScale,
                issuances[issuanceIndex].priceInUSD,
                MathUpgradeable.Rounding.Down
            );

        emit TicketOffered(
            caller,
            tokenUsed,
            issuanceIndex,
            investors[issuanceIndex][caller].amountInPaymentToken
        );
    }

    /// @dev Method to getting the token Whitelisted
    /// @return result Array of whitelisted ERC20 tokens
    function getAllTokenERC20Whitelist()
        external
        view
        returns (address[] memory result)
    {
        uint256 index;
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            if (tokenERC20Whitelist[tokensERC20[i]].status) {
                index++;
            }
        }
        result = new address[](index);
        index = 0;
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            if (tokenERC20Whitelist[tokensERC20[i]].status) {
                result[index] = tokensERC20[i];
                index++;
            }
        }
    }

    /// Helpers

    /// @dev Method to estimate how many STO tokens are received based on amountOfTokens of tokenUsed
    /// @param tokenUsed Address of the ERC20 token used
    /// @param amountOfTokens Amount of tokenUsed tokens
    /// @return expectedAmount Amount of STO tokens expected to be received
    function getEstimationSTOToken(address tokenUsed, uint256 amountOfTokens)
        public
        view
        returns (uint256 expectedAmount)
    {
        uint256 actualAmount;

        _checkValidStatus(_msgSender(), tokenUsed);

        uint256 paymentTokenScale = 10**paymentToken.decimals();
        uint256 stoRelatedTokenScale = 10**stoRelatedToken.decimals();

        if (tokenUsed != address(paymentToken)) {
            uint256 priceInPaymentToken = getPriceInPaymentToken(tokenUsed)
                .mulDiv( // Price in paymentToken of the ERC20 used
                tokenERC20Whitelist[tokenUsed].multiplier, /// Discount the Price in case of BKN token
                1 ether,
                MathUpgradeable.Rounding.Up
            ); /// Rounding Up

            uint256 amountOfPaymentTokens = amountOfTokens.mulDiv( // Amount of paymentTokens equivalent to the amount passed in
                priceInPaymentToken,
                10**IERC20MetadataUpgradeable(tokenUsed).decimals(),
                MathUpgradeable.Rounding.Down
            ); ///Rounding Down

            actualAmount = amountOfPaymentTokens;
        } else {
            actualAmount = amountOfTokens;
        }
        expectedAmount = actualAmount
            .mulDiv(
                stoRelatedTokenScale,
                paymentTokenScale,
                MathUpgradeable.Rounding.Up
            )
            .mulDiv(
                stoRelatedTokenScale,
                issuances[issuanceIndex].priceInUSD,
                MathUpgradeable.Rounding.Down
            ); ///Rounding Down
    }

    /// @dev Method to validate it tokenContract is part of the list of whitelisted ERC20 tokens
    /// @param tokenContract is the ERC20 contract to validate
    /// @return flag indicating if the token is whitelisted
    function isTokenERC20(address tokenContract) public view returns (bool) {
        for (uint256 i = 0; i < tokensERC20.length; i++) {
            if (tokensERC20[i] == tokenContract) {
                return true;
            }
        }
        return false;
    }

    /// @dev Method to validate if an issuance has started
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance started
    function isStarted(uint256 issuanceIndexQueried)
        public
        view
        returns (bool)
    {
        return block.timestamp >= issuances[issuanceIndexQueried].startDate;
    }

    /// @dev Method to validate if an issuance has ended
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance ended
    function isEnded(uint256 issuanceIndexQueried) public view returns (bool) {
        return block.timestamp >= issuances[issuanceIndexQueried].endDate;
    }

    /// @dev Method to validate if an issuance is active
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance is active
    function isActive(uint256 issuanceIndexQueried) public view returns (bool) {
        return
            isStarted(issuanceIndexQueried) && !isEnded(issuanceIndexQueried);
    }

    /// @dev Method to validate if an issuance was succesfull
    /// @param issuanceIndexQueried Index of the issuance
    /// @return True if the issuance was succesfull
    function isSuccess(uint256 issuanceIndexQueried)
        public
        view
        returns (bool)
    {
        return
            issuances[issuanceIndexQueried].raisedAmount >=
            issuances[issuanceIndexQueried].softCap;
    }

    /// @dev Method validate if the issuance is in rollback state
    /// @param issuanceIndexQueried Index of the Issuance Process
    /// @return True if the issuance is in rollback state
    function isRollback(uint256 issuanceIndexQueried)
        public
        view
        returns (bool)
    {
        return
            issuances[issuanceIndexQueried].status == IssuanceStatuses.ROLLBACK;
    }

    /// @dev Method validate if the issuance is in withdrawn state
    /// @param issuanceIndexQueried Index of the Issuance Process
    /// @return True if the issuance is in withdrawn state
    function isWithdrawn(uint256 issuanceIndexQueried)
        public
        view
        returns (bool)
    {
        return
            issuances[issuanceIndexQueried].status ==
            IssuanceStatuses.WITHDRAWN;
    }

    /// @dev Method if an user position has been redeemed or not
    /// @param issuanceIndexQueried Index of the issuance
    /// @param user Address of the user/investor
    /// @return True if the has reedemed the STO tokens
    function isRedeemed(uint256 issuanceIndexQueried, address user)
        public
        view
        returns (bool)
    {
        return investors[issuanceIndexQueried][user].redeemed;
    }

    /// @dev Method if an user position has been refunded or not
    /// @param issuanceIndexQueried Index of the issuance
    /// @param user Address of the user/investor
    /// @return True if the has been refunded
    function isRefunded(uint256 issuanceIndexQueried, address user)
        public
        view
        returns (bool)
    {
        return investors[issuanceIndexQueried][user].refunded;
    }

    /// @dev Method to validate if an user is an investor in the issuance
    /// @param issuanceIndexQueried Index of the issuance
    /// @param user Address of the user/investor
    /// @return True if the user has an opened position in the issuance
    function isInvestor(uint256 issuanceIndexQueried, address user)
        public
        view
        returns (bool)
    {
        return
            investors[issuanceIndexQueried][user].amountInSTO > 0 &&
            investors[issuanceIndexQueried][user].amountInPaymentToken > 0 &&
            !investors[issuanceIndexQueried][user].redeemed;
    }

    /// @dev Method to calculate amount of STO tokens avaialable to be bought
    /// @dev It is equal or less to the max ticket allowed per investor in the issuance
    function amountAvailable(uint256 issuanceIndexQueried)
        public
        view
        returns (uint256)
    {
        if (isActive(issuanceIndexQueried)) {
            return
                issuances[issuanceIndexQueried].hardCap.sub(
                    issuances[issuanceIndexQueried].raisedAmount
                ) > issuances[issuanceIndexQueried].maxTicket
                    ? issuances[issuanceIndexQueried].maxTicket
                    : issuances[issuanceIndexQueried].hardCap.sub(
                        issuances[issuanceIndexQueried].raisedAmount
                    );
        } else {
            return 0;
        }
    }

    /// @dev Method to get the price of 1 token of tokenAddress if swapped for paymentToken
    /// @param tokenAddress ERC20 token address of a whitelisted ERC20 token
    /// @return price Price in paymentToken equivalent with its decimals
    function getPriceInPaymentToken(address tokenAddress)
        public
        view
        returns (uint256 price)
    {
        address[] memory path = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        path[0] = address(tokenAddress);
        path[1] = address(paymentToken);
        amounts = router.getAmountsOut(
            1 * 10**IERC20MetadataUpgradeable(tokenAddress).decimals(),
            path
        );

        price = amounts[1];
    }

    /// Internal methods

    /// @dev Internal method to check whether the issuance is started AND ended
    function _checkIssuanceCompleteness(address caller, uint256 index)
        internal
        view
    {
        if (issuanceIndex == 0) revert IssuanceNotStarted(caller);

        if (!isStarted(index)) revert IssuanceNotStarted(caller);

        if (!isEnded(index))
            revert IssuanceNotEnded(caller, issuances[issuanceIndex].endDate);
    }

    /// @dev Internal method to check whether the issuance is valid status and that the caller and the token are whitelisted
    function _checkValidStatus(address caller, address tokenUsed)
        internal
        view
    {
        if (!stoRelatedToken.whitelist(caller))
            revert UserIsNotWhitelisted(caller);

        if (issuanceIndex == 0) revert IssuanceNotStarted(caller);

        if (!isStarted(issuanceIndex)) revert IssuanceNotStarted(caller);

        if (isEnded(issuanceIndex))
            revert IssuanceEnded(caller, issuances[issuanceIndex].endDate);

        if (!tokenERC20Whitelist[tokenUsed].status)
            revert TokenIsNotWhitelisted(tokenUsed, caller);

        if (
            issuances[issuanceIndex].raisedAmount ==
            issuances[issuanceIndex].hardCap
        ) revert HardCapRaised();
    }

    function _validateInputs(uint256 amount, address caller) internal view {
        // Auxiliary variables useful for the calculations
        uint256 paymentTokenScale = 10**paymentToken.decimals();
        uint256 stoRelatedTokenScale = 10**stoRelatedToken.decimals();
        uint256 scaledMinTicket = issuances[issuanceIndex].minTicket.mulDiv(
            paymentTokenScale,
            stoRelatedTokenScale
        );
        uint256 scaledMaxTicket = issuances[issuanceIndex].maxTicket.mulDiv(
            paymentTokenScale,
            stoRelatedTokenScale
        );
        uint256 scaledRaisedAmount = issuances[issuanceIndex]
            .raisedAmount
            .mulDiv(paymentTokenScale, stoRelatedTokenScale);
        uint256 scaledHardCap = issuances[issuanceIndex].hardCap.mulDiv(
            paymentTokenScale,
            stoRelatedTokenScale
        );
        uint256 scaledIssuanceAmount = issuances[issuanceIndex]
            .issuanceAmount
            .mulDiv(paymentTokenScale, stoRelatedTokenScale);

        if (
            (amount < scaledMinTicket) &&
            (scaledIssuanceAmount - scaledRaisedAmount) >= scaledMinTicket
        ) revert InsufficientAmount(caller, amount, scaledMinTicket);

        if (amount > scaledMaxTicket)
            revert AmountExceeded(caller, amount, scaledMaxTicket);

        if (
            (isInvestor(issuanceIndex, caller)) &&
            (investors[issuanceIndex][caller].amountInPaymentToken.add(amount) >
                scaledMaxTicket)
        )
            revert AmountExceeded(
                caller,
                investors[issuanceIndex][caller].amountInPaymentToken.add(
                    amount
                ),
                scaledMaxTicket
            );

        if (amount.add(scaledRaisedAmount) > scaledHardCap)
            revert HardCapExceeded(
                caller,
                amount,
                amountAvailable(issuanceIndex).mulDiv(
                    paymentTokenScale,
                    stoRelatedTokenScale
                )
            );
    }

    /// @dev Internal method for the investor to redeem the STO tokens bought
    function _redeemToken(uint256 index) internal {
        address caller = _msgSender();

        if (isRedeemed(index, caller)) revert RedeemedAlready(caller, index);

        if (!isInvestor(index, caller)) revert NotInvestor(caller, index);

        if (!isWithdrawn(index)) revert IssuanceNotWithdrawn(issuer);

        stoRelatedToken.mint(caller, investors[index][caller].amountInSTO);

        investors[index][caller].redeemed = true;

        emit Redeemed(caller, index, investors[index][caller].amountInSTO);
    }

    /// @dev Internal method for the investor to be refunded in paymentToken
    function _refundToken(uint256 index) internal {
        address caller = _msgSender();

        if (isRefunded(index, caller)) revert RefundedAlready(caller, index);

        if (!isInvestor(index, caller)) revert NotInvestor(caller, index);

        if (!isRollback(index)) revert IssuanceNotInRollback(index);

        /// Add Logic to refund the USDC of each issuance investor (investor)
        SafeERC20Upgradeable.safeTransfer(
            paymentToken,
            caller,
            investors[index][caller].amountInPaymentToken
        );

        investors[index][caller].refunded = true;

        emit Refunded(
            caller,
            index,
            investors[index][caller].amountInPaymentToken
        );
    }

    /// @dev Internal method to withdraw the paymentToken funds after a succesfull issuance
    /// @dev Only the issuer or owner can initialize this, the issuer will always receive the paymentToken funds
    /// @dev Brickken is gettting a succesfull fee
    function _withdraw() internal {
        if (isWithdrawn(issuanceIndex)) revert IssuanceWasWithdrawn(issuer);

        uint256 amount = issuances[issuanceIndex].raisedAmount.mulDiv(
            10**paymentToken.decimals(),
            10**stoRelatedToken.decimals()
        );

        uint256 fee = amount.mulDiv(
            withdrawalFee,
            10000,
            MathUpgradeable.Rounding.Up
        );

        SafeERC20Upgradeable.safeTransfer(paymentToken, treasuryAddress, fee);

        SafeERC20Upgradeable.safeTransfer(paymentToken, issuer, amount - fee);

        issuances[issuanceIndex].status = IssuanceStatuses.WITHDRAWN;

        emit Withdrawn(issuer, issuanceIndex, fee, amount - fee);
    }

    /// @dev Internal method to rollback the paymentToken funds after an unsuccesfull issuance
    /// @dev Only the issuer or owner can initialize this
    function _rollBack() internal {
        if (isRollback(issuanceIndex)) revert IssuanceWasRollbacked(issuer);

        issuances[issuanceIndex].status = IssuanceStatuses.ROLLBACK;

        emit RollBack(
            issuer,
            issuanceIndex,
            issuances[issuanceIndex].raisedAmount
        );
    }

    /// @dev Internal method to swap ERC20 whitelisted tokens for paymentToken
    /// @param tokenAddress  ERC20 token address of the whitelisted token
    /// @param tokenAmount Amount of tokens to be swapped with Uni v2 router to paymentToken
    function _swapTokensForTokens(
        address tokenAddress,
        uint256 tokenAmount,
        uint256 expectedAmount
    ) internal {
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = address(paymentToken);

        /// do the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            expectedAmount.mulDiv(0.90 ether, 1 ether), // Allow for up to 10% max slippage
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "../interfaces/ISTOToken.sol";

/// @title STOErrors
/// @custom:security-contact [email protected]
abstract contract STOErrors {
    /// User `caller` is not the owner of the contract
    error CallerIsNotOwner(address caller);
    /// User `caller` is not the issuer of the contract
    error CallerIsNotIssuer(address caller);
	/// User `caller` is not the same address of the Claimer Address
    error CallerIsNotClaimer(address caller);
    /// Issuer `issuer` can't start a new Issuance Process if not Finalized and Withdraw the Previous one
    error IssuanceNotFinalized(address issuer);
    /// Issuer `issuer` can't start a new Issuance Process if not Started the Previous one
    error IssuanceNotStarted(address issuer);
    /// The Iniiialization of the Issuannce Process sent by the Issuer `issuer` is not valid
    error InitialValueWrong(address issuer);
    /// This transaction exceed the Max Supply of STO Token
    error MaxSupplyExceeded();
    /// The issuance collected funds are not withdrawn yet
    error IssuanceNotWithdrawn(address issuer);
    /// The issuance process is not in rollback state
    error IssuanceNotInRollback(uint256 index);
    /// Fired when fees are over 100%
    error FeeOverLimits(uint256 newFee);
    /// The Issuer `issuer` tried to Whitelisted not valid ERC20 Smart Contract (`token`)
    error AddressIsNotContract(address token, address issuer);
    /// The Issuer `issuer` tried to Finalize the Issuance Process before to End Date `endDate`
    error IssuanceNotEnded(address issuer, uint256 endDate);
    /// The Issuer `issuer` tried to Finalize the Issuance Process was Finalized
    error IssuanceWasFinalized(address issuer);
    /// The Issuer `issuer` tried to Withdraw the Issuance Process was Withdrawn
    error IssuanceWasWithdrawn(address issuer);
    /// The Issuer `issuer` tried to Rollback the Issuance Process was Rollbacked
    error IssuanceWasRollbacked(address issuer);
    /// The User `user` tried to refund the ERC20 Token in the Issuance Process was Successful
    error IssuanceWasSuccessful(address user);
    /// The User `user` tried to redeem the STO Token in the Issuance Process was not Successful
    error IssuanceWasNotSuccessful(address user);
    /// The User `user` tried to buy STO Token in the Issuance Process was ended in `endDate`
    error IssuanceEnded(address user, uint256 endDate);
    /// The User `user` tried to buy with ERC20 `token` is not WhiteListed in the Issuance Process
    error TokenIsNotWhitelisted(address token, address user);
    /// The User `user` tried to buy STO Token, and the Amount `amount` exceed the Maximal Ticket `maxTicket`
    error AmountExceeded(address user, uint256 amount, uint256 maxTicket);
	/// the User `user` tried to buy STO Token, and the Amount `amount` is under the Minimal Ticket `minTicket`
	error InsufficientAmount(address user, uint256 amount, uint256 minTicket);
    /// The user `user` tried to buy STO Token, and the Amount `amount` exceed the Amount Available `amountAvailable`
	/// @param user The user address
	/// @param amount The amount of token to buy
	/// @param amountAvailable The amount of token available
    error HardCapExceeded(
        address user,
        uint256 amount,
        uint256 amountAvailable
    );
    /// The User `user` has not enough balance `amount` in the ERC20 Token `token`
    error InsufficientBalance(address user, address token, uint256 amount);
    /// The User `user` tried to buy USDC Token, and the Swap with ERC20 Token `tokenERC20` was not Successful
    error SwapFailure(address user, address tokenERC20, uint256 priceInUSD, uint256 balanceAfter);
    /// The User `user` tried to redeem the ERC20 Token Again! in the Issuance Process with Index `index`
    error RedeemedAlready(address user, uint256 index);
    /// The User `user` tried to be refunded with payment tokend Again! in the Issuance Process with Index `index`
    error RefundedAlready(address user, uint256 index);
    /// The User `user` is not Investor in the Issuance Process with Index `index`
    error NotInvestor(address user, uint256 index);
    /// The Max Amount of STO Token in the Issuance Process will be Raised
    error HardCapRaised();
    /// User `user`,don't have permission to reinitialize the contract
    error UserIsNotOwner(address user);
    /// User is not Whitelisted, User `user`,don't have permission to transfer or call some functions
    error UserIsNotWhitelisted(address user);
	/// At least pair of arrays have a different length
    error LengthsMismatch();
	/// The premit Amount of STO Token in the Issuance Process will be exceed the Max Amount of STO Token
    error PremintGreaterThanMaxSupply();
	/// The Address can't be the zero address
	error NotZeroAddress();
	/// The Variable can't be the zero value
	error NotZeroValue();
	/// The Address is not a Contract
	error NotContractAddress();
	/// The Dividend Amount is can't be zero
	error DividendAmountIsZero();
	/// The Wallet `claimer` is not Available to Claim Dividend
	error NotAvailableToClaim(address claimer);
	/// The User `claimer` can't claim
	error NotAmountToClaim(address claimer);
	///The User `user` try to claim an amount `amountToClaim` more than the amount available `amountAvailable`
	error ExceedAmountAvailable(address claimer, uint256 amountAvailable, uint256 amountToClaim);
	/// The User `user` is not the Minter of the STO Token
	error NotMinter(address user);
	/// The Transaction sender by User `user`, with Token ERC20 `tokenERC20` is not valid
	error ApproveFailed(address user, address tokenERC20);
}

/// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// @title IRouter
/// @custom:security-contact [email protected]
interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) 	external;

	function swapExactETHForTokens(
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	)	external
        returns (uint[] memory amounts);
}

/// SPDX-License-Identifier: MIT
pragma solidity <0.9.0;

/// Import all OZ intefaces from which it extends
/// Add custom functions
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title ISTOToken
/// @custom:security-contact [email protected]
interface ISTOToken is IERC20MetadataUpgradeable {

    struct Checkpoint {
        uint32 fromBlock;
        uint224 balance;
    }

    /// @dev Method to query past holder balance
    /// @param account address to query
    /// @param blockNumber which block in the past to query
    function getPastBalance(address account, uint256 blockNumber) external returns (uint256);

    /// @dev Method to query past total supply
    /// @param blockNumber which block in the past to query
    function getPastTotalSupply(uint256 blockNumber) external returns (uint256);

    /// @dev Method to query a specific checkpoint
    /// @param account address to query
    /// @param pos index in the array
    function checkpoints(address account, uint32 pos) external returns (Checkpoint memory);

    /// @dev Method to query the number of checkpoints
    /// @param account address to query
    function numCheckpoints(address account) external returns (uint32);

    /// @dev Method to check if account is tracked. If it returns address(0), user is not tracked
    /// @param account address to query
    function trackings(address account) external returns (address);

    /// @dev Method to get account balance, it should give same as balanceOf()
    /// @param account address to query
    function getBalance(address account) external returns (uint256);

    /// @dev Method to add a new dividend distribution
    /// @param totalAmount Total Amount of Dividend
    function addDistDividend(uint256 totalAmount) external;

    /// @dev Method to claim dividends of STO Token
    function claimDividend() external;

    /// @dev Method to check how much amount of dividends the user can claim
    /// @param claimer Address of claimer of STO Token
    /// @return amount of dividends to claim
    function getMaxAmountToClaim(address claimer) external view returns (uint256 amount);

    /// @dev Method to check the index of where to start claiming dividends
    /// @param claimer Address of claimer of STO Token
    /// @return index after the lastClaimedBlock
    function getIndexToClaim(address claimer) external view returns (uint256);

    /// @dev Verify last claimed block for user
    /// @param _address Address to verify
    function lastClaimedBlock(address _address) external view returns (bool);

    /// @dev Method to confiscate STO tokens
    /// @dev This method is only available to the owner of the contract
    /// @param from Address of where STO tokens are lost
    /// @param amount Amount of STO tokens to be confiscated
    function confiscate(address from, uint amount) external;

    /// @dev Method to enable/disable confiscation feature
    /// @dev This method is only available to the owner of the contract
    function changeConfiscation(bool status) external;

    /// @dev Method to disable confiscation feature forever
    /// @dev This method is only available to the owner of the contract
    function disableConfiscationFeature() external;

    /// @dev Returns the address of the current owner.
    function owner() external returns (address);

    /// @dev Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner.
    function renounceOwnership() external;

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @notice Can only be called by the current owner.
    function transferOwnership(address newOwner) external;

    /// @dev Maximal amount of STO Tokens that can be minted
    function maxSupply() external view returns (uint256);

    /// @dev address of the minter
    function minter() external view returns (address);

    /// @dev address of the issuer
    function issuer() external view returns (address);

    /// @dev url for offchain records
    function url() external view returns (string memory);

    /// @dev Verify if the address is in the Whitelist
    /// @param adr Address to verify
    function whitelist(address adr) external view returns (bool);

    /// @dev Method to change the issuer address
    /// @dev This method is only available to the owner of the contract
    function changeIssuer(address newIssuer) external;

    /// @dev Method to change the minter address
    /// @dev This method is only available to the owner of the contract
    function changeMinter(address newMinter) external;

    /// @dev Set addresses in whitelist.
    /// @dev This method is only available to the owner of the contract
    /// @param users addresses to be whitelisted
    /// @param statuses statuses to be whitelisted
    function changeWhitelist(address[] calldata users, bool[] calldata statuses) external;

    /// @dev Method to setup or update the max supply of the token
    /// @dev This method is only available to the owner of the contract
    function changeMaxSupply(uint supplyCap) external;

    /// @dev Method to mint STO tokens
    /// @dev This method is only available to the owner of the contract
    function mint(address to, uint256 amount) external;

    /// @dev Method to setup or update the URI where the documents of the tokenization are stored
    /// @dev This method is only available to the owner of the contract
    function changeUrl(string memory newURL) external;

    /// @dev Expose the burn method, only the msg.sender can burn his own token
    function burn(uint256 amount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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