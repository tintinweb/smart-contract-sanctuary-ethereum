// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title ERC721 contract for crowdfunds from allowed artists/content creators */

///@dev inhouse implemented smart contracts and interfaces.
import "./interfaces/ICrowdfund.sol";
import "./interfaces/IERC721Art.sol";
import "./interfaces/IManagement.sol";

///@dev security settings.
import "./@openzeppelin/proxy/utils/Initializable.sol";
import "./@openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import "./@openzeppelin/upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./@openzeppelin/upgradeable/security/PausableUpgradeable.sol";

contract Crowdfund is
    ICrowdfund,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    // fund settings
    uint256 public minSoldRate; // over 10000
    uint256 public dueDate;
    uint256 public nextInvestId; // 0 is for invalid invest ID
    mapping(address => uint256[]) public investIdsPerInvestor;
    mapping(QuotaClass => QuotaInfos) private quotaInfos;
    mapping(uint256 => InvestIdInfos) private investIdInfos;

    // donation
    uint256 public donationFee; // over 10000
    address public donationReceiver;

    // investments made per coin
    mapping(address => mapping(IManagement.Coin => uint256))
        public paymentsPerCoin;

    // constants
    uint256 private constant MAX_UINT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    // Management contract
    IManagement public management;

    // ERC721Art contract
    IERC721Art public collection;

    /// -----------------------------------------------------------------------
    /// Initialization
    /// -----------------------------------------------------------------------

    /// @dev initializer modifier added.
    /// @inheritdoc ICrowdfund
    function initialize(
        uint256[3] memory _valuesLowQuota,
        uint256[3] memory _valuesRegQuota,
        uint256[3] memory _valuesHighQuota,
        uint256 _amountLowQuota,
        uint256 _amountRegQuota,
        uint256 _amountHighQuota,
        address _donationReceiver,
        uint256 _donationFee,
        uint256 _minSoldRate,
        address _collection
    ) public override(ICrowdfund) initializer {
        if (_amountLowQuota + _amountRegQuota + _amountHighQuota == 0) {
            revert CrowdfundMaxSupplyIs0();
        }
        if (_minSoldRate < 2500 || _minSoldRate > 10000) {
            revert CrowdfundInvalidMinSoldRate();
        }

        // checking _collection address
        collection = IERC721Art(_collection);

        if (
            msg.sender != address(collection.management()) ||
            collection.maxSupply() !=
            _amountLowQuota + _amountRegQuota + _amountHighQuota ||
            collection.pricePerCoin(IManagement.Coin.ETH_COIN) != MAX_UINT ||
            collection.pricePerCoin(IManagement.Coin.USD_TOKEN) != MAX_UINT ||
            collection.pricePerCoin(IManagement.Coin.CREATORS_TOKEN) != MAX_UINT
        ) {
            revert CrowdfundInvalidCollection();
        }

        __Ownable_init();
        transferOwnership(OwnableUpgradeable(_collection).owner());
        __ReentrancyGuard_init();
        __Pausable_init();

        quotaInfos[QuotaClass.LOW].amount = _amountLowQuota;
        quotaInfos[QuotaClass.REGULAR].amount = _amountRegQuota;
        quotaInfos[QuotaClass.HIGH].amount = _amountHighQuota;

        quotaInfos[QuotaClass.LOW].values = _valuesLowQuota;
        quotaInfos[QuotaClass.REGULAR].values = _valuesRegQuota;
        quotaInfos[QuotaClass.HIGH].values = _valuesHighQuota;

        quotaInfos[QuotaClass.REGULAR].nextTokenId = _amountLowQuota;
        quotaInfos[QuotaClass.HIGH].nextTokenId =
            _amountLowQuota +
            _amountRegQuota;

        donationReceiver = _donationReceiver;
        donationFee = _donationFee;
        minSoldRate = _minSoldRate;

        management = IManagement(msg.sender);

        dueDate = block.timestamp + 6 * 30 days; // standard duration of crowdfund (6 months)
        nextInvestId = 1;
    }

    /// -----------------------------------------------------------------------
    /// Permissions and Restrictions (private functions)
    /// -----------------------------------------------------------------------

    ///@dev checks if the caller has still shares/is an investor
    function __checkIfInvestor(address _investor) private view {
        if (!(investIdsPerInvestor[_investor].length > 0)) {
            revert CrowdfundCallerNotInvestor();
        }
    }

    ///@dev checks if collection/creator is corrupted
    function __notCorrupted() private view {
        if (management.isCorrupted(owner())) {
            revert CrowdfundCollectionOrCreatorCorrupted();
        }
    }

    ///@dev checks if caller is authorized
    function __onlyAuthorized() private view {
        if (!management.isCorrupted(owner())) {
            if (!(management.managers(msg.sender) || msg.sender == owner())) {
                revert CrowdfundNotAllowed();
            }
        } else {
            if (!management.managers(msg.sender)) {
                revert CrowdfundNotAllowed();
            }
        }
    }

    ///@dev checks if minimum goal/objective is reached
    function __checkIfMinGoalReached() private view {
        uint256 soldQuotaAmount = quotaInfos[QuotaClass.LOW].bought +
            quotaInfos[QuotaClass.REGULAR].bought +
            quotaInfos[QuotaClass.HIGH].bought;
        uint256 maxQuotasAmount = quotaInfos[QuotaClass.LOW].amount +
            quotaInfos[QuotaClass.REGULAR].amount +
            quotaInfos[QuotaClass.HIGH].amount;
        if ((soldQuotaAmount * 10000) / maxQuotasAmount < minSoldRate) {
            revert CrowdfundMinGoalNotReached();
        }
    }

    ///@dev checks if crowdfund is still ongoing
    function __checkIfCrowdfundOngoing() private view {
        if (!(block.timestamp < dueDate)) {
            revert CrowdfundPastDue();
        }
    }

    ///@dev private function for whenNotPaused modifier
    function __whenNotPaused() private view whenNotPaused {}

    ///@dev private function for nonReentrant modifier
    function __nonReentrant() private nonReentrant {}

    /// -----------------------------------------------------------------------
    /// Implemented functions
    /// -----------------------------------------------------------------------

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function invest(
        uint256 _amountOfLowQuota,
        uint256 _amountOfRegularQuota,
        uint256 _amountOfHighQuota,
        IManagement.Coin _coin
    ) external payable override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __notCorrupted();
        __checkIfCrowdfundOngoing();

        uint256 totalPayment = __invest(
            msg.sender,
            msg.sender,
            _amountOfLowQuota,
            _amountOfRegularQuota,
            _amountOfHighQuota,
            _coin
        );

        emit Invested(
            msg.sender,
            nextInvestId - 1,
            _amountOfLowQuota,
            _amountOfRegularQuota,
            _amountOfHighQuota,
            totalPayment,
            _coin,
            false
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only authorized parties 
    can call this function. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function investForAddress(
        address _investor,
        uint256 _amountOfLowQuota,
        uint256 _amountOfRegularQuota,
        uint256 _amountOfHighQuota,
        IManagement.Coin _coin
    ) external payable override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __onlyAuthorized();
        __checkIfCrowdfundOngoing();

        uint256 totalPayment = __invest(
            _investor,
            msg.sender,
            _amountOfLowQuota,
            _amountOfRegularQuota,
            _amountOfHighQuota,
            _coin
        );

        emit Invested(
            _investor,
            nextInvestId - 1,
            _amountOfLowQuota,
            _amountOfRegularQuota,
            _amountOfHighQuota,
            totalPayment,
            _coin,
            true
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function donate(
        uint256 _amount,
        IManagement.Coin _coin
    ) external payable override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __notCorrupted();
        __checkIfCrowdfundOngoing();

        __donate(msg.sender, msg.sender, _amount, _coin);

        emit DonationTransferred(msg.sender, _amount, _coin, false);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only authorized parties 
    can call this function. It will revert if either the due date has been reached or if
    there is no more quotas available */
    /// @inheritdoc ICrowdfund
    function donateForAddress(
        address _donor,
        uint256 _amount,
        IManagement.Coin _coin
    ) external payable override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __onlyAuthorized();
        __checkIfCrowdfundOngoing();

        __donate(_donor, msg.sender, _amount, _coin);

        emit DonationTransferred(_donor, _amount, _coin, true);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only investors will be able to
    refund. If the invest ID is not in the refund period or the minimum sold rate is reached, it will be disconsiderd.
    If creator/collection has been corrupted, the refund will continue without the checks previously explained.  */
    /// @inheritdoc ICrowdfund
    function refundAll() external override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __checkIfInvestor(msg.sender);

        uint256 soldQuotaAmount = quotaInfos[QuotaClass.LOW].bought +
            quotaInfos[QuotaClass.REGULAR].bought +
            quotaInfos[QuotaClass.HIGH].bought;
        uint256 maxQuotasAmount = quotaInfos[QuotaClass.LOW].amount +
            quotaInfos[QuotaClass.REGULAR].amount +
            quotaInfos[QuotaClass.HIGH].amount;

        if (
            !management.isCorrupted(owner()) &&
            (!((soldQuotaAmount * 10000) / maxQuotasAmount < minSoldRate) ||
                block.timestamp < dueDate)
        ) {
            revert CrowdfundRefundNotPossible();
        }

        (
            uint256[] memory amountPerCoin,
            uint256[] memory _investIdsRefunded
        ) = _computeRefundToInvestor(msg.sender);

        emit InvestorWithdrawedAll(
            msg.sender,
            amountPerCoin[0],
            amountPerCoin[1],
            amountPerCoin[2],
            _investIdsRefunded
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only investors can refund.
    It will revert if either the 7 days period has past or the min rate of sold quotas has been reached (if not corrupted).
    If corrupted, investors can refund at any time. */
    /// @inheritdoc ICrowdfund
    function refundWithInvestId(uint256 _investId) public override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __checkIfInvestor(msg.sender);

        if (investIdInfos[_investId].investor != msg.sender) {
            revert CrowdfundNotInvestIdOwner();
        }

        uint256 soldQuotaAmount = quotaInfos[QuotaClass.LOW].bought +
            quotaInfos[QuotaClass.REGULAR].bought +
            quotaInfos[QuotaClass.HIGH].bought;
        uint256 maxQuotasAmount = quotaInfos[QuotaClass.LOW].amount +
            quotaInfos[QuotaClass.REGULAR].amount +
            quotaInfos[QuotaClass.HIGH].amount;
        if (
            !management.isCorrupted(owner()) &&
            !(block.timestamp < investIdInfos[_investId].sevenDaysPeriod) &&
            (!((soldQuotaAmount * 10000) / maxQuotasAmount < minSoldRate) ||
                block.timestamp < dueDate)
        ) {
            revert CrowdfundRefundNotPossible();
        }

        (uint256 amount, IManagement.Coin _coin) = _computeRefund(
            _investId,
            msg.sender
        );

        uint256[] storage _investIds = investIdsPerInvestor[msg.sender];
        uint256 last_index = _investIds.length - 1;

        _investIds[investIdInfos[_investId].index] = _investIds[last_index];
        investIdInfos[_investIds[last_index]].index = investIdInfos[_investId]
            .index;
        _investIds.pop();

        delete investIdInfos[_investId];

        emit InvestorWithdrawed(msg.sender, _investId, amount, _coin);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only investors can be refunded. */
    /// @inheritdoc ICrowdfund
    function refundToAddress(address _investor) external override(ICrowdfund) {
        __nonReentrant();
        __onlyAuthorized();
        __checkIfInvestor(_investor);

        (
            uint256[] memory amountPerCoin,
            uint256[] memory _investIdsRefunded
        ) = _computeRefundToInvestor(_investor);

        emit RefundedAllToAddress(
            msg.sender,
            _investor,
            amountPerCoin[0],
            amountPerCoin[1],
            amountPerCoin[2],
            _investIdsRefunded
        );
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. Only creator/owner can execute function. It will revert if the min 
    rate of sold quotas has been reached. */
    /// @inheritdoc ICrowdfund
    function withdrawFund() external override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __onlyAuthorized();
        __checkIfMinGoalReached();

        address multisig = management.multiSig();
        uint256[] memory amounts = new uint256[](3);
        uint256[] memory donationAmounts = new uint256[](3);
        for (uint256 ii = 1; ii < 4; ++ii) {
            IManagement.Coin coin = IManagement.Coin(ii - 1);
            uint256 coinBalance = coin == IManagement.Coin.ETH_COIN
                ? address(this).balance
                : management.tokenContract(coin).balanceOf(address(this));

            if (coinBalance == 0) {
                continue;
            }

            uint256 donationAmount = (coinBalance * donationFee) / 10000;
            uint256 creatorsProRoyalty = (coinBalance * 900) / 10000; // royalty to CreatorsPRO = 9%
            uint256 amount = donationReceiver != address(0)
                ? coinBalance - donationAmount - creatorsProRoyalty
                : coinBalance - creatorsProRoyalty;

            if (donationReceiver != address(0)) {
                _executeTransfer(
                    donationAmount,
                    coin,
                    address(this),
                    donationReceiver
                );
            }
            _executeTransfer(creatorsProRoyalty, coin, address(this), multisig);
            _executeTransfer(amount, coin, address(this), owner());

            amounts[ii - 1] = amount;
            donationAmounts[ii - 1] = donationAmount;
        }

        emit CreatorWithdrawed(amounts[0], amounts[1], amounts[2]);
        emit DonationSent(
            donationReceiver,
            donationAmounts[0],
            donationAmounts[1],
            donationAmounts[2]
        );
    }

    /** @dev function to be used by the creator. Same rules for the mint public function (below) */
    /// @inheritdoc ICrowdfund
    function mint() external override(ICrowdfund) {
        mint(msg.sender);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Function won't work if 
    creator/collection has been corrupted. It will revert if array of invest IDs for a given investor
    address is empty. Once minted, the list of invest IDs per investor and the list of token IDs per 
    invest ID are deleted.  */
    /// @inheritdoc ICrowdfund
    function mint(address _investor) public override(ICrowdfund) {
        __whenNotPaused();
        __nonReentrant();
        __notCorrupted();
        __checkIfMinGoalReached();

        uint256[] memory _investIds = investIdsPerInvestor[_investor];
        if (_investIds.length == 0) {
            revert CrowdfundNoMoreTokensToMint();
        }

        uint256[] memory tokenAmounts = new uint256[](3);
        bool deleteInvestIds = true;
        unchecked {
            for (uint256 jj; jj < _investIds.length; ++jj) {
                InvestIdInfos memory _investIdInfos = investIdInfos[
                    _investIds[jj]
                ];
                if (
                    block.timestamp < _investIdInfos.sevenDaysPeriod &&
                    (_investIdInfos.lowQuotaAmount > 0 ||
                        _investIdInfos.regQuotaAmount > 0 ||
                        _investIdInfos.highQuotaAmount > 0)
                ) {
                    deleteInvestIds = false;
                    continue;
                }

                tokenAmounts[0] += _investIdInfos.lowQuotaAmount;

                tokenAmounts[1] += _investIdInfos.regQuotaAmount;

                tokenAmounts[2] += _investIdInfos.highQuotaAmount;

                delete investIdInfos[_investIds[jj]];
                delete investIdsPerInvestor[_investor];
            }
        }

        if (deleteInvestIds) {
            delete investIdsPerInvestor[_investor];
        }

        uint256[] memory _nextTokenIds = new uint256[](3);
        _nextTokenIds[0] = quotaInfos[QuotaClass.LOW].nextTokenId;
        _nextTokenIds[1] = quotaInfos[QuotaClass.REGULAR].nextTokenId;
        _nextTokenIds[2] = quotaInfos[QuotaClass.HIGH].nextTokenId;

        quotaInfos[QuotaClass.LOW].nextTokenId += tokenAmounts[0];
        quotaInfos[QuotaClass.REGULAR].nextTokenId += tokenAmounts[1];
        quotaInfos[QuotaClass.HIGH].nextTokenId += tokenAmounts[2];

        uint256[] memory _tokenIds = new uint256[](
            tokenAmounts[0] + tokenAmounts[1] + tokenAmounts[2]
        );
        uint8[] memory _classes = new uint8[](_tokenIds.length);

        unchecked {
            uint256 kk;
            for (uint8 ii; ii < 3; ++ii) {
                for (uint256 jj; jj < tokenAmounts[ii]; ++jj) {
                    _tokenIds[kk] = _nextTokenIds[ii] + jj;
                    _classes[kk] = ii;
                    ++kk;
                }
            }
        }

        collection.mintForCrowdfund(_tokenIds, _classes, _investor);

        emit InvestorMinted(_investor, msg.sender);
    }

    /** @dev whenNotPaused and nonReentrant third parties modifiers added. Only managers are allowed 
    to execute this function. */
    /// @inheritdoc ICrowdfund
    function withdrawToAddress(
        address _receiver,
        uint256 _amount
    ) external override(ICrowdfund) {
        __nonReentrant();

        if (!management.managers(msg.sender)) {
            revert CrowdfundNotAllowed();
        }

        payable(_receiver).transfer(_amount);

        emit WithdrawnToAddress(msg.sender, _receiver, _amount);
    }

    /// -----------------------------------------------------------------------
    /// Setter functions
    /// -----------------------------------------------------------------------

    // --- Pause and Unpause functions ---

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. Uses _pause internal function from PausableUpgradeable. */
    /// @inheritdoc ICrowdfund
    function pause() external override(ICrowdfund) {
        __nonReentrant();
        __onlyAuthorized();

        _pause();
        collection.pause();
    }

    /** @dev Function won't work if creator/collection has been corrupted. Only authorized addresses 
    are allowed to execute this function. Uses _pause internal function from PausableUpgradeable. */
    /// @inheritdoc ICrowdfund
    function unpause() external override(ICrowdfund) {
        __nonReentrant();
        __onlyAuthorized();

        _unpause();
        collection.unpause();
    }

    /// -----------------------------------------------------------------------
    /// Getter functions
    /// -----------------------------------------------------------------------

    /// @inheritdoc ICrowdfund
    function getInvestIdsPerInvestor(
        address _investor
    ) external view override(ICrowdfund) returns (uint256[] memory) {
        return investIdsPerInvestor[_investor];
    }

    /// @inheritdoc ICrowdfund
    function getQuotaInfos(
        QuotaClass _class
    ) external view override(ICrowdfund) returns (QuotaInfos memory) {
        return quotaInfos[_class];
    }

    /// @inheritdoc ICrowdfund
    function getInvestIdInfos(
        uint256 _investId
    ) external view override(ICrowdfund) returns (InvestIdInfos memory) {
        return investIdInfos[_investId];
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /** @dev executes all the transfers
        @param _amount: amount to be transferred
        @param _coin: coin of transfer
        @param _from: the address from which the transfer should be executed
        @param _to: the recipient of the transfer */
    function _executeTransfer(
        uint256 _amount,
        IManagement.Coin _coin,
        address _from,
        address _to
    ) internal {
        if (_coin != IManagement.Coin.ETH_COIN) {
            if (_from == address(this)) {
                management.tokenContract(_coin).transfer(_to, _amount);
            } else {
                management.tokenContract(_coin).transferFrom(
                    _from,
                    _to,
                    _amount
                );
            }
        } else {
            if (_from == address(this)) {
                payable(_to).transfer(_amount);
            } else {
                if (msg.value < _amount) {
                    revert CrowdfundNotEnoughValueSent();
                } else if (msg.value > _amount) {
                    uint256 aboveValue = msg.value - _amount;
                    payable(_from).transfer(aboveValue);
                }
            }
        }
    }

    /** @dev computes all storage variables for refund
        @param _investId: ID of investment
        @return (uint256, Coin) amount refunded and token/coin of refund */
    function _computeRefund(
        uint256 _investId,
        address _investor
    ) internal returns (uint256, IManagement.Coin) {
        quotaInfos[QuotaClass.LOW].bought -= investIdInfos[_investId]
            .lowQuotaAmount;
        quotaInfos[QuotaClass.REGULAR].bought -= investIdInfos[_investId]
            .regQuotaAmount;
        quotaInfos[QuotaClass.HIGH].bought -= investIdInfos[_investId]
            .highQuotaAmount;

        uint256 amount = investIdInfos[_investId].totalPayment;

        IManagement.Coin _coin = investIdInfos[_investId].coin;
        paymentsPerCoin[_investor][_coin] -= amount;
        _executeTransfer(amount, _coin, address(this), _investor);

        return (amount, _coin);
    }

    /** @dev performs the refund computations for given investor address
        @param _investor: investor address */
    function _computeRefundToInvestor(
        address _investor
    ) internal returns (uint256[] memory, uint256[] memory) {
        uint256[] storage _investIds = investIdsPerInvestor[_investor];
        uint256[] memory _investIdsRefunded = new uint256[](_investIds.length);
        uint256[] memory amountPerCoin = new uint256[](3);
        unchecked {
            uint256 ii;
            while (ii < _investIds.length) {
                (uint256 amount, IManagement.Coin _coin) = _computeRefund(
                    _investIds[ii],
                    _investor
                );
                amountPerCoin[uint256(_coin)] += amount;
                _investIdsRefunded[ii] = _investIds[ii];
                _investIds[ii] = _investIds[_investIds.length - 1];
                _investIds.pop();
            }
        }

        return (amountPerCoin, _investIdsRefunded);
    }

    /** @dev performs every invest computation
        @param _investor: investor's address
        @param _paymentFrom: address from which the payment will be transferred
        @param _amountOfLowQuota: amount of low quotas to be bought
        @param _amountOfRegularQuota: amount of regular quotas to be bought
        @param _amountOfHighQuota: amount of high quotas to be bought
        @param _coin: coin of transfer
        @return uint256 value for the total amount paid */
    function __invest(
        address _investor,
        address _paymentFrom,
        uint256 _amountOfLowQuota,
        uint256 _amountOfRegularQuota,
        uint256 _amountOfHighQuota,
        IManagement.Coin _coin
    ) private returns (uint256) {
        if (
            quotaInfos[QuotaClass.LOW].bought + _amountOfLowQuota >
            quotaInfos[QuotaClass.LOW].amount
        ) {
            revert CrowdfundLowQuotaMaxAmountReached();
        }
        if (
            quotaInfos[QuotaClass.REGULAR].bought + _amountOfRegularQuota >
            quotaInfos[QuotaClass.REGULAR].amount
        ) {
            revert CrowdfundRegQuotaMaxAmountReached();
        }
        if (
            quotaInfos[QuotaClass.HIGH].bought + _amountOfHighQuota >
            quotaInfos[QuotaClass.HIGH].amount
        ) {
            revert CrowdfundHighQuotaMaxAmountReached();
        }

        uint256 totalPayment = _amountOfLowQuota *
            quotaInfos[QuotaClass.LOW].values[uint8(_coin)] +
            _amountOfRegularQuota *
            quotaInfos[QuotaClass.REGULAR].values[uint8(_coin)] +
            _amountOfHighQuota *
            quotaInfos[QuotaClass.HIGH].values[uint8(_coin)];

        _executeTransfer(totalPayment, _coin, _paymentFrom, address(this));

        unchecked {
            investIdInfos[nextInvestId].index = investIdsPerInvestor[_investor]
                .length;
            investIdInfos[nextInvestId].investor = _investor;
            investIdInfos[nextInvestId].totalPayment = totalPayment;
            investIdInfos[nextInvestId].coin = _coin;
            investIdInfos[nextInvestId].sevenDaysPeriod =
                block.timestamp +
                7 days;
            investIdInfos[nextInvestId].lowQuotaAmount = _amountOfLowQuota;
            investIdInfos[nextInvestId].regQuotaAmount = _amountOfRegularQuota;
            investIdInfos[nextInvestId].highQuotaAmount = _amountOfHighQuota;
            investIdsPerInvestor[_investor].push(nextInvestId);

            quotaInfos[QuotaClass.LOW].bought += _amountOfLowQuota;
            quotaInfos[QuotaClass.REGULAR].bought += _amountOfRegularQuota;
            quotaInfos[QuotaClass.HIGH].bought += _amountOfHighQuota;

            paymentsPerCoin[_investor][_coin] += totalPayment;

            nextInvestId++;
        }

        return totalPayment;
    }

    /** @dev performs every donation computation
        @param _donor: donor's address
        @param _paymentFrom: address from which the payment will be transferred
        @param _amount: donation amount
        @param _coin: coin/token for donation */
    function __donate(
        address _donor,
        address _paymentFrom,
        uint256 _amount,
        IManagement.Coin _coin
    ) private {
        if (_coin == IManagement.Coin.ETH_COIN) {
            _amount = msg.value;
        }

        _executeTransfer(_amount, _coin, _paymentFrom, address(this));

        unchecked {
            investIdInfos[nextInvestId].index = investIdsPerInvestor[_donor]
                .length;
            investIdInfos[nextInvestId].investor = _donor;
            investIdInfos[nextInvestId].totalPayment = _amount;
            investIdInfos[nextInvestId].coin = _coin;
            investIdInfos[nextInvestId].sevenDaysPeriod =
                block.timestamp +
                7 days;
            investIdsPerInvestor[_donor].push(nextInvestId);

            paymentsPerCoin[_donor][_coin] += _amount;

            nextInvestId++;
        }
    }

    /// -----------------------------------------------------------------------
    /// Receive function
    /// -----------------------------------------------------------------------

    receive() external payable {}

    /// -----------------------------------------------------------------------
    /// Storage space for upgrades
    /// -----------------------------------------------------------------------

    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../upgradeable/utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
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
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
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
        if (_initialized != type(uint8).max) {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../../proxy/utils/Initializable.sol";

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

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
pragma solidity ^0.8.11;

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title Interface for the ERC721 contract for crowdfunds from allowed 
    artists/content creators */

import "./IERC721Art.sol";
import "./IManagement.sol";

interface ICrowdfund {
    /// -----------------------------------------------------------------------
    /// Structs and Enums
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the quota class 
        @param LOW: low class
        @param REGULAR: regular class
        @param HIGH: high class */
    enum QuotaClass {
        LOW,
        REGULAR,
        HIGH
    }

    /** @dev struct with important informations of an invest ID 
        @param index: invest ID index in investIdsPerInvestor array
        @param totalPayment: total amount paid in the investment
        @param sevenDaysPeriod: 7 seven days period end timestamp
        @param coin: coin used for the investment
        @param lowQuotaAmount: low class quota amount bought 
        @param regQuotaAmount: regular class quota amount bought 
        @param highQuotaAmount: high class quota amount bought */
    struct InvestIdInfos {
        uint256 index;
        uint256 totalPayment;
        uint256 sevenDaysPeriod;
        IManagement.Coin coin;
        address investor;
        uint256 lowQuotaAmount;
        uint256 regQuotaAmount;
        uint256 highQuotaAmount;
    }

    /** @dev struct with important information about each quota 
        @param values: array of price values for each coin. Array order: [ETH, US dollar token, CreatorsPRO token]
        @param amount: total amount
        @param bough: amount of bought quotas
        @param nextTokenId: next token ID for the current quota */
    struct QuotaInfos {
        uint256[3] values;
        uint256 amount;
        uint256 bought;
        uint256 nextTokenId;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when shares are bought 
        @param investor: investor's address
        @param investId: ID of the investment
        @param lowQuotaAmount: amount of low class quota
        @param regQuotaAmount: amount of regular class quota
        @param highQuotaAmount: amount of high class quota
        @param totalPayment: amount of shares bought 
        @param coin: coin of investment 
        @param forAddress: specifies if investment was in behalf of another address */
    event Invested(
        address indexed investor,
        uint256 indexed investId,
        uint256 lowQuotaAmount,
        uint256 regQuotaAmount,
        uint256 highQuotaAmount,
        uint256 totalPayment,
        IManagement.Coin coin,
        bool indexed forAddress
    );

    /** @dev event for when an investor withdraws investment 
        @param investor: investor's address 
        @param investId: ID of investment 
        @param amount: amount to be withdrawed
        @param coin: coin of withdrawal */
    event InvestorWithdrawed(
        address indexed investor,
        uint256 indexed investId,
        uint256 amount,
        IManagement.Coin coin
    );

    /** @dev event for when investor refunds his/her whole investment at once
        @param investor: investor's address 
        @param ETHAmount: amount refunded in ETH/MATIC
        @param USDAmount: amount refunded in USD 
        @param CreatorsCoinAmount: amount refunded in CreatorsCoin 
        @param investIdsRefunded: array of refunded invest IDs */
    event InvestorWithdrawedAll(
        address indexed investor,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount,
        uint256[] investIdsRefunded
    );

    /** @dev event for when the crowdfund creator withdraws funds 
        @param ETHAmount: amount withdrawed in ETH/MATIC
        @param USDAmount: amount withdrawed in USD
        @param CreatorsCoinAmount: amount withdrawed in CreatorsCoin */
    event CreatorWithdrawed(
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount
    );

    /** @dev event for when the donantion is sent
        @param _donationReceiver: receiver address of the donation
        @param ETHAmount: amount donated in ETH
        @param USDAmount: amount donated in USD
        @param CreatorsCoinAmount: amount donated in CreatorsCoin */
    event DonationSent(
        address indexed _donationReceiver,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount
    );

    /** @dev event for when an investor has minted his/her tokens
        @param investor: address of investor 
        @param caller: function's caller address */
    event InvestorMinted(address indexed investor, address indexed caller);

    /** @dev event for when a donation is made
        @param caller: function caller address
        @param amount: donation amount
        @param coin: coin of donation 
        @param forAddress: specifies if investment was in behalf of another address */
    event DonationTransferred(
        address indexed caller,
        uint256 amount,
        IManagement.Coin coin,
        bool indexed forAddress
    );

    /** @dev event for when a manager refunds all quotas to given investor address 
        @param manager: manager address that called the function
        @param investor: investor address
        @param ETHAmount: amount refunded in ETH/MATIC
        @param USDAmount: amount refunded in USD 
        @param CreatorsCoinAmount: amount refunded in CreatorsCoin 
        @param investIdsRefunded: array of refunded invest IDs */
    event RefundedAllToAddress(
        address indexed manager,
        address indexed investor,
        uint256 ETHAmount,
        uint256 USDAmount,
        uint256 CreatorsCoinAmount,
        uint256[] investIdsRefunded
    );

    /** @notice event for when a manager withdraws funds to address
        @param manager: manager address
        @param receiver: withdrawn fund receiver address
        @param amount: amount withdrawn */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed receiver,
        uint256 amount
    );

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the crowdfund has past due data
    error CrowdfundPastDue();

    ///@dev error for when the caller is not an investor
    error CrowdfundCallerNotInvestor();

    ///@dev error for when low class quota maximum amount has reached
    error CrowdfundLowQuotaMaxAmountReached();

    ///@dev error for when regular class quota maximum amount has reached
    error CrowdfundRegQuotaMaxAmountReached();

    ///@dev error for when low high quota maximum amount has reached
    error CrowdfundHighQuotaMaxAmountReached();

    ///@dev error for when minimum fund goal is not reached
    error CrowdfundMinGoalNotReached();

    ///@dev error for when not enough ETH value is sent
    error CrowdfundNotEnoughValueSent();

    ///@dev error for when the resulting max supply is 0
    error CrowdfundMaxSupplyIs0();

    ///@dev error for when the caller has no more tokens to mint
    error CrowdfundNoMoreTokensToMint();

    ///@dev error for when the caller is not invest ID owner
    error CrowdfundNotInvestIdOwner();

    ///@dev error for when the collection/creator has been corrupted
    error CrowdfundCollectionOrCreatorCorrupted();

    ///@dev error for when an invalid collection address is given
    error CrowdfundInvalidCollection();

    ///@dev error for when caller is neighter manager nor collection creator
    error CrowdfundNotAllowed();

    ///@dev error for when refund is not possible
    error CrowdfundRefundNotPossible();

    ///@dev error for when an invalid minimum sold rate is given
    error CrowdfundInvalidMinSoldRate();

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- From storage variables ---

    /** @notice reads minSoldRate public storage variable 
        @return uint256 value for the minimum rate of sold quotas */
    function minSoldRate() external view returns (uint256);

    /** @notice reads dueDate public storage variable 
        @return uint256 value for the crowdfunding due date timestamp */
    function dueDate() external view returns (uint256);

    /** @notice reads nextInvestId public storage variable 
        @return uint256 value for the next investment ID */
    function nextInvestId() external view returns (uint256);

    /** @notice reads investIdsPerInvestor public storage mapping
        @param _investor: address of the investor
        @param _index: array index
        @return uint256 value for the investment ID  */
    function investIdsPerInvestor(
        address _investor,
        uint256 _index
    ) external view returns (uint256);

    /** @notice reads donationFee public storage variable 
        @return uint256 value for fee of donation (over 10000) */
    function donationFee() external view returns (uint256);

    /** @notice reads donationReceiver public storage variable 
        @return address of the donation receiver */
    function donationReceiver() external view returns (address);

    /** @notice reads paymentsPerCoin public storage mapping
        @param _investor: address of the investor
        @param _coin: coin of transfer
        @return uint256 value for amount deposited from the given investor, of the given coin  */
    function paymentsPerCoin(
        address _investor,
        IManagement.Coin _coin
    ) external view returns (uint256);

    /** @notice reads management public storage variable 
        @return IManagement instance of Management interface */
    function management() external view returns (IManagement);

    /** @notice reads collection public storage variable 
        @return IERC721Art instance of ERC721Art interface */
    function collection() external view returns (IERC721Art);

    // --- Implemented functions ---

    /** @notice initializes this contract.
        @param _valuesLowQuota: array of values for low quota
        @param _valuesRegQuota: array of values for regular quota
        @param _valuesHighQuota: array of values for high quota 
        @param _amountLowQuota: amount for low quota 
        @param _amountRegQuota: amount for regular quota 
        @param _amountHighQuota: amount for high quota 
        @param _donationReceiver: address for donation 
        @param _donationFee: fee for donation 
        @param _minSoldRate: minimum rate for sold quotas 
        @param _collection: ERC721Art collection address */
    function initialize(
        uint256[3] memory _valuesLowQuota,
        uint256[3] memory _valuesRegQuota,
        uint256[3] memory _valuesHighQuota,
        uint256 _amountLowQuota,
        uint256 _amountRegQuota,
        uint256 _amountHighQuota,
        address _donationReceiver,
        uint256 _donationFee,
        uint256 _minSoldRate,
        address _collection
    ) external;

    /** @notice buys the given amount of shares in the given coin/token. Payable function.
        @param _amountOfLowQuota: amount of low quotas to be bought
        @param _amountOfRegularQuota: amount of regular quotas to be bought
        @param _amountOfHighQuota: amount of high quotas to be bought
        @param _coin: coin of transfer */
    function invest(
        uint256 _amountOfLowQuota,
        uint256 _amountOfRegularQuota,
        uint256 _amountOfHighQuota,
        IManagement.Coin _coin
    ) external payable;

    /** @notice buys the given amount of shares in the given coin/token for given address. Payable function.
        @param _amountOfLowQuota: amount of low quotas to be bought
        @param _amountOfRegularQuota: amount of regular quotas to be bought
        @param _amountOfHighQuota: amount of high quotas to be bought 
        @param _coin: coin of transfer */
    function investForAddress(
        address _investor,
        uint256 _amountOfLowQuota,
        uint256 _amountOfRegularQuota,
        uint256 _amountOfHighQuota,
        IManagement.Coin _coin
    ) external payable;

    /** @notice donates the given amount of the given to the crowdfund (will not get ERC721 tokens as reward) 
        @param _amount: donation amount
        @param _coin: coin/token for donation */
    function donate(uint256 _amount, IManagement.Coin _coin) external payable;

    /** @notice donates the given amount to the crowdfund (will not get ERC721 tokens as reward) for the given address
        @param _donor: donor's address
        @param _amount: donation amount
        @param _coin: coin/token for donation */
    function donateForAddress(
        address _donor,
        uint256 _amount,
        IManagement.Coin _coin
    ) external payable;

    /** @notice withdraws the fund invested to the calling investor address */
    function refundAll() external;

    /** @notice withdraws the fund invested for the given invest ID to the calling investor address 
        @param _investId: ID of the investment */
    function refundWithInvestId(uint256 _investId) external;

    /** @notice refunds all quotas to the given investor address
        @param _investor: investor address */
    function refundToAddress(address _investor) external;

    /** @notice withdraws fund to the calling collection's creator wallet address */
    function withdrawFund() external;

    /** @notice mints token IDs for an investor */
    function mint() external;

    /** @notice mints token IDs for an investor 
        @param _investor: investor's address */
    function mint(address _investor) external;

    /** @notice withdraws funds to given address
        @param _receiver: fund receiver address
        @param _amount: amount to withdraw */
    function withdrawToAddress(address _receiver, uint256 _amount) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    /** @notice reads the investIdsPerInvestor public storage mapping 
        @param _investor: address of the investor 
        @return uint256 array of invest IDs */
    function getInvestIdsPerInvestor(
        address _investor
    ) external view returns (uint256[] memory);

    /** @notice reads the quotaInfos public storage mapping 
        @param _class: QuotaClass class of quota 
        @return QuotaInfos struct of information about the given quota class */
    function getQuotaInfos(
        QuotaClass _class
    ) external view returns (QuotaInfos memory);

    /** @notice reads the investIdInfos public storage mapping 
        @param _investId: ID of the investment
        @return all information of the given invest ID */
    function getInvestIdInfos(
        uint256 _investId
    ) external view returns (InvestIdInfos memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title Interface for the reward contract of CreatorsPRO NFTs */

import "./IManagement.sol";

interface ICRPReward {
    /// -----------------------------------------------------------------------
    /// Structs and Enums
    /// -----------------------------------------------------------------------

    /** @dev struct to store important token infos
        @param index: index of the token ID in the tokenIdsPerUser mapping
        @param hashpower: CreatorsPRO hashpower
        @param characteristId: CreatorsPRO characterist ID */
    struct TokenInfo {
        uint256 index; // 0 is for no longer listed
        uint256 hashpower;
        uint256 characteristId;
    }

    /** @dev struct to store user's info
        @param index: user index in usersArray storage array
        @param score: sum of the hashpowers from the NFTs owned by the user
        @param points: sum of interactions points done by the user
        @param timeOfLastUpdate: timestamp for the last information update
        @param unclaimedRewards: total amount of rewards still unclaimed
        @param conditionIdOflastUpdate: condition ID for the last update 
        @param collections: array of collection addresses of the user's NFTs */
    struct User {
        uint256 index; // 0 is for address no longer a user
        uint256 score;
        uint256 points;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
        uint256 conditionIdOflastUpdate;
        address[] collections;
    }

    /** @dev struct for staking condition
        @param timeUnit: unit of time to be considered when calculating rewards
        @param rewardsPerUnitTime: array of rewards per time unit (timeUnit)
        @param startTimestamp: timestamp for when the condition begins
        @param endTimestamp: timestamp for when the condition ends */
    struct RewardCondition {
        uint256 timeUnit;
        uint256 rewardsPerUnitTime;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when points are added/increased
        @param user: user address
        @param tokenId: ID of the token
        @param points: amount of points increased
        @param interaction: interaction ID (0: mint, 1: send transfer, 2: receive transfer) */
    event PointsIncreased(
        address indexed user,
        uint256 indexed tokenId,
        uint256 points,
        uint8 interaction
    );

    /** @dev event for when a token has been removed from tokenInfo mapping for
    the given user address
        @param user: user address
        @param tokenId: ID of the token */
    event TokenRemoved(address indexed user, uint256 indexed tokenId);

    /** @dev event for when reward tokens are deposited into the contract
        @param depositor: depositor address
        @param amount: amount of reward tokens deposited */
    event RewardTokensDeposited(address indexed depositor, uint256 amount);

    /** @dev event for when rewards are claimed
        @param caller: address of the function caller (user)
        @param amount: amount of reward tokens claimed */
    event RewardsClaimed(address indexed caller, uint256 amount);

    /** @dev event for when the hash object for the tokenId is set.
        @param manager: address of the manager that has set the hash object
        @param collection: address of the collection
        @param tokenId: array of IDs of ERC721 token
        @param hashpower: array of hashpowers set by manager
        @param characteristId: array of IDs of the characterist */
    event HashObjectSet(
        address indexed manager,
        address indexed collection,
        uint256[] indexed tokenId,
        uint256[] hashpower,
        uint256[] characteristId
    );

    /** @dev event for when a new reward condition is set
        @param caller: function caller address
        @param timeUnit: time unit to be considered when calculating rewards
        @param rewardsPerUnitTime: amount of rewards per unit time */
    event NewRewardCondition(
        address indexed caller,
        uint256 timeUnit,
        uint256 rewardsPerUnitTime
    );

    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error CRPRewardNotAllowed();

    ///@dev error for when a contract not instantiated by CreatorsPro calls increaseScore() function
    error CRPRewardNotAllowedCollectionAddress();

    ///@dev error for when the input arrays have not the same length
    error CRPRewardInputArraysNotSameLength();

    ///@dev error for when caller is not Management cotract
    error CRPRewardCallerNotManagement();

    ///@dev error for when time unit is zero
    error CRPRewardTimeUnitZero();

    ///@dev error for when there are no rewards
    error CRPRewardNoRewards();

    ///@dev error for when an invalid interaction is given
    error CRPRewardInvalidInteraction();

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- From storage variables ---

    /** @notice reads management public storage variable
        @return IManagement interface instance for the Management contract */
    function management() external view returns (IManagement);

    /** @notice reads nextConditionId public storage variable 
        @return uint256 value for the next condition ID */
    function nextConditionId() external view returns (uint256);

    // /** @notice reads totalScore public storage variable
    //     @return uint256 value for the sum of scores from all CreatorsPRO users */
    // function totalScore() external view returns (uint256);

    /** @notice reads interacPoints public static storage array 
        @param _index: index of the array
        @return uint256 value for the interaction point */
    function interacPoints(uint256 _index) external view returns (uint256);

    /** @notice reads usersArray public storage array 
        @param _index: index of the array
        @return address of a user */
    function usersArray(uint256 _index) external view returns (address);

    /** @notice reads collectionIndex public storage mapping
        @param _user: user address
        @param _collection: ERC721Art collection address
        @return uint256 value for the collection index in User struct */
    function collectionIndex(
        address _user,
        address _collection
    ) external view returns (uint256);

    /** @notice reads tokenIdsPerUser public storage mapping
        @param _user: user address
        @param _collection: ERC721Art collection address
        @param _index: index value for token IDs array
        @return uint256 value for the token ID  */
    function tokenIdsPerUser(
        address _user,
        address _collection,
        uint256 _index
    ) external view returns (uint256);

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param _management: Management contract address
        @param _timeUnit: time unit to be considered when calculating rewards
        @param _rewardsPerUnitTime: amount of rewards per unit time
        @param _interacPoints: array of interaction points for each interaction (0: min, 1: send transfer, 2: receive transfer) */
    function initialize(
        address _management,
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime,
        uint256[3] calldata _interacPoints
    ) external;

    /** @notice increases the user score by the given amount
        @param _user: user address
        @param _tokenId: ID of the token 
        @param _interaction: interaction ID (0: mint, 1: send transfer, 2: receive transfer) */
    function increasePoints(
        address _user,
        uint256 _tokenId,
        uint8 _interaction
    ) external;

    /** @notice removes given token ID from given user address
        @param _user: user address
        @param _tokenId: token ID to be removed 
        @param _emitEvent: true to emit event (external call), false otherwise (internal call)*/
    function removeToken(
        address _user,
        uint256 _tokenId,
        bool _emitEvent
    ) external;

    /** @notice deposits reward tokens into contract        
        @param _from: address from which the token will be trasferred 
        @param _amount: amount of reward tokens to be deposited */
    function depositRewardTokens(address _from, uint256 _amount) external;

    /** @notice claims rewards to the caller wallet */
    function claimRewards() external;

    /** @notice sets hashpower and characterist ID for the given token ID
        @param _collection: collection address
        @param _tokenId: array of token IDs
        @param _hashPower: array of hashpowers for the token ID
        @param _characteristId: array of characterit IDs */
    function setHashObject(
        address _collection,
        uint256[] memory _tokenId,
        uint256[] memory _hashPower,
        uint256[] memory _characteristId
    ) external;

    /** @notice sets new reward condition
        @param _timeUnit: time unit to be considered when calculating rewards
        @param _rewardsPerUnitTime: amount of rewards per unit time */
    function setRewardCondition(
        uint256 _timeUnit,
        uint256 _rewardsPerUnitTime
    ) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads hashObjects public storage mapping
        @param _collection: address of an CreatorsPRO collection (ERC721)
        @param _tokenId: ID of the token from the given collection
        @return uint256 values for hashpower and characterist ID */
    function getHashObject(
        address _collection,
        uint256 _tokenId
    ) external view returns (uint256, uint256);

    /** @notice reads tokenInfo public storage mapping
        @param _collection: address of an CreatorsPRO collection (ERC721)
        @param _tokenId: ID of the token from the given collection 
        @return TokenInfo struct with token infos */
    function getTokenInfo(
        address _collection,
        uint256 _tokenId
    ) external view returns (TokenInfo memory);

    /** @notice reads users public storage mapping 
        @param _user: CreatorsPRO user address
        @return User struct with user's info */
    function getUser(address _user) external view returns (User memory);

    /** @notice reads users public storage mapping, but the values are updated
        @param _user: CreatorsPRO user address
        @return User struct with user's info */
    function getUserUpdated(address _user) external view returns (User memory);

    /** @notice reads rewardCondition public storage mapping 
        @return RewardCondition struct with current reward condition info */
    function getCurrentRewardCondition()
        external
        view
        returns (RewardCondition memory);

    /** @notice reads rewardCondition public storage mapping 
        @param _conditionId: condition ID
        @return RewardCondition struct with reward condition info */
    function getRewardCondition(
        uint256 _conditionId
    ) external view returns (RewardCondition memory);

    /** @notice reads all token IDs from the array of tokenIdsPerUser public storage mapping
        @param _user: user address
        @param _collection: ERC721Art collection address
        @return uint256 array for the token IDs  */
    function getAllTokenIdsPerUser(
        address _user,
        address _collection
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title Interface for the ERC721 contract for artistic workpieces from allowed 
    artists/content creators */

import "./IManagement.sol";

interface IERC721Art {
    /// -----------------------------------------------------------------------
    /// Structs and Enums
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new mint price is set.
        @param newPrice: new mint price 
        @param coin: token/coin of transfer */
    event PriceSet(uint256 indexed newPrice, IManagement.Coin indexed coin);

    /** @dev event for when owner sets new price for his/her token.
        @param tokenId: ID of ERC721 token
        @param price: new token price
        @param coin: token/coin of transfer */
    event TokenPriceSet(
        uint256 indexed tokenId,
        uint256 price,
        IManagement.Coin indexed coin
    );

    /** @dev event for when royalties transfers are done (mint).
        @param tokenId: ID of ERC721 token
        @param creatorsProRoyalty: royalty to CreatorsPRO
        @param creatorRoyalty: royalty to collection creator 
        @param fromWallet: address from which the payments was made */
    event RoyaltiesTransferred(
        uint256 indexed tokenId,
        uint256 creatorsProRoyalty,
        uint256 creatorRoyalty,
        address fromWallet
    );

    /** @dev event for when owner payments are done (creatorsProSafeTransferFrom).
        @param tokenId: ID of ERC721 token
        @param owner: owner address
        @param amount: amount transferred */
    event OwnerPaymentDone(
        uint256 indexed tokenId,
        address indexed owner,
        uint256 amount
    );

    /** @dev event for when a new royalty fee is set
        @param _royalty: new royalty fee value */
    event RoyaltySet(uint256 _royalty);

    /** @dev event for when a new crowdfund address is set
        @param _crowdfund: address from crowdfund */
    event CrowdfundSet(address indexed _crowdfund);

    /** @dev event for when a new max discount for an ERC20 contract is set
        @param token: ERC20 contract address
        @param discount: discount value */
    event MaxDiscountSet(address indexed token, uint256 discount);

    /** @notice event for when a manager withdraws funds to address
        @param manager: manager address
        @param receiver: withdrawn fund receiver address
        @param amount: amount withdrawn */
    event WithdrawnToAddress(
        address indexed manager,
        address indexed receiver,
        uint256 amount
    );

    /** @notice event for when a new coreSFT address is set
        @param caller: function's caller address
        @param _coreSFT: new address for the SFT protocol */
    event NewCoreSFTSet(address indexed caller, address _coreSFT);

    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    ///@dev error for when the collection max supply is reached (when maxSupply > 0)
    error ERC721ArtMaxSupplyReached();

    ///@dev error for when the value sent or the allowance is not enough to mint/buy token
    error ERC721ArtNotEnoughValueOrAllowance();

    ///@dev error for when caller is neighter manager nor collection creator
    error ERC721ArtNotAllowed();

    ///@dev error for when caller is not token owner
    error ERC721ArtNotTokenOwner();

    ///@dev error for when the collection/creator has been corrupted
    error ERC721ArtCollectionOrCreatorCorrupted();

    ///@dev error for when collection is for a crowdfund
    error ERC721ArtCollectionForFund();

    ///@dev error for when an invalid crowdfund address is set
    error ERC721ArtInvalidCrowdFund();

    ///@dev error for when the caller is not the crowdfund contract
    error ERC721ArtCallerNotCrowdfund();

    ///@dev error for when a crowfund address is already set
    error ERC721ArtCrodFundIsSet();

    ///@dev error for when input arrays don't have same length
    error ERC721ArtArraysDoNotMatch();

    ///@dev error for when an invalid ERC20 contract address is given
    error ERC721ArtInvalidAddress();

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- From storage variables ---

    /** @notice reads management public storage variable
        @return IManagement interface instance for the Management contract */
    function management() external view returns (IManagement);

    /** @notice reads maxSupply public storage variable
        @return uint256 value of maximum supply */
    function maxSupply() external view returns (uint256);

    /** @notice reads baseURI public storage variable 
        @return string of the base URI */
    function baseURI() external view returns (string memory);

    /** @notice reads price public storage mapping
        @param _coin: coin/token for price
        @return uint256 value for price */
    function pricePerCoin(
        IManagement.Coin _coin
    ) external view returns (uint256);

    /** @notice reads lastTransfer public storage mapping 
        @param _tokenId: ID of the token
        @return uint256 value for last trasfer of the given token ID */
    function lastTransfer(uint256 _tokenId) external view returns (uint256);

    /** @notice reads tokenPrice public storage mapping 
        @param _tokenId: ID of the token
        @param _coin: coin/token for specific token price 
        @return uint256 value for price of specific token */
    function tokenPrice(
        uint256 _tokenId,
        IManagement.Coin _coin
    ) external view returns (uint256);

    /** @notice reads crowdfund public storage variable 
        @return address of the set crowdfund contract */
    function crowdfund() external view returns (address);

    /** @notice reads maxDiscountPerCoin public storage mapping by address
        @param _token: ERC20 contract address
        @return uint256 for the max discount of the SFTRec protocol */
    function maxDiscount(address _token) external view returns (uint256);

    // --- Implemented functions ---

    /** @notice initializes the contract. Required function, since a proxy pattern is used.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _owner: collection owner/creator
        @param _maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param _price: mint price of a single NFT
        @param _priceInUSD: mint price of a single NFT
        @param _priceInCreatorsCoin: mint price of a single NFT
        @param baseURI_: base URI for the collection's metadata 
        @param _royalty: royalty payment to owner 
            (final value = _royalty / 10000 (ERC2981Upgradeable._feeDenominator())) */
    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSD,
        uint256 _priceInCreatorsCoin,
        string memory baseURI_,
        uint256 _royalty
    ) external;

    /** @notice mints given the NFT of given tokenId, using the given coin for transfer. Payable function.
        @param _tokenId: tokenId to be minted 
        @param _coin: token/coin of transfer 
        @param _discount: discount given for NFT mint */
    function mint(
        uint256 _tokenId,
        IManagement.Coin _coin,
        uint256 _discount
    ) external payable;

    /** @notice mints NFT of the given tokenId to the given address
        @param _to: address to which the ticket is going to be minted
        @param _tokenId: tokenId (batch) of the ticket to be minted */
    function mintToAddress(address _to, uint256 _tokenId) external;

    /** @notice mints token for crowdfunding        
        @param _tokenIds: array of token IDs to mint
        @param _classes: array of classes 
        @param _to: address from tokens owner */
    function mintForCrowdfund(
        uint256[] memory _tokenIds,
        uint8[] memory _classes,
        address _to
    ) external;

    /** @notice burns NFT of the given tokenId.
        @param _tokenId: token ID to be burned */
    function burn(uint256 _tokenId) external;

    /** @notice safeTransferFrom function especifically for CreatorPRO. It enforces (onchain) the transfer of the 
        correct token price. Payable function.
        @param coin: which coin to use (0 => ETH, 1 => USD, 2 => CreatorsCoin)
        The other parameters are the same from safeTransferFrom function. */
    function creatorsProSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        IManagement.Coin coin
    ) external payable;

    /** @notice sets NFT mint price.
        @param _price: new NFT mint price 
        @param _coin: coin/token to be set */
    function setPrice(uint256 _price, IManagement.Coin _coin) external;

    /** @notice sets the price of the ginve token ID.
        @param _tokenId: ID of token
        @param _price: new price to be set 
        @param _coin: coin/token to be set */
    function setTokenPrice(
        uint256 _tokenId,
        uint256 _price,
        IManagement.Coin _coin
    ) external;

    /** @notice sets new base URI for the collection.
        @param _uri: new base URI to be set */
    function setBaseURI(string memory _uri) external;

    /** @notice sets new royaly value for NFT transfer
        @param _royalty: new value for royalty */
    function setRoyalty(uint256 _royalty) external;

    /** @notice sets the crowdfund address 
        @param _crowdfund: crowdfund contract address */
    function setCrowdfund(address _crowdfund) external;

    /** @notice sets maxDiscount mapping for given ERC20 address
        @param _token: ERC20 contract address
        @param _maxDiscount: max discount value */
    function setMaxDiscount(address _token, uint256 _maxDiscount) external;

    /** @notice sets new coreSFT address
        @param _coreSFT: new address for the SFT protocol */
    function setCoreSFT(address _coreSFT) external;

    /** @notice gets the royalty info (address and value) from ERC2981
        @return royalty receiver address and value */
    function getRoyalty() external view returns (address, uint);

    /** @notice gets the price of mint for the given address
        @param _token: ERC20 token contract address 
        @return uint256 price value in the given ERC20 token */
    function price(address _token) external view returns (uint256);

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    /** @notice withdraws funds to given address
        @param _receiver: fund receiver address
        @param _amount: amount to withdraw */
    function withdrawToAddress(address _receiver, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/** @author Omnes Blockchain team (@EWCunha, @Afonsodalvi, and @G-Deps)
    @title Interface for the management contract from CreatorsPRO */

import "../@openzeppelin/token/IERC20.sol";
import "./ICRPReward.sol";

interface IManagement {
    /// -----------------------------------------------------------------------
    /// Structs and Enums
    /// -----------------------------------------------------------------------

    /** @dev enum to specify the coin/token of transfer 
        @param ETH_COIN: ETH
        @param USD_TOKEN: a US dollar stablecoin
        @param CREATORS_TOKEN: ERC20 token from CreatorsPRO */
    enum Coin {
        ETH_COIN,
        USD_TOKEN,
        CREATORS_TOKEN
    }

    /** @dev struct to be used as imput parameter that comprises with values for
    setting the crowdfunding contract   
        @param _valuesLowQuota: array of values for the low class quota in ETH, USD token, and CreatorsPRO token
        @param _valuesRegQuota: array of values for the regular class quota in ETH, USD token, and CreatorsPRO token 
        @param _valuesHighQuota: array of values for the high class quota in ETH, USD token, and CreatorsPRO token 
        @param _amountLowQuota: amount of low class quotas available 
        @param _amountRegQuota: amount of low regular quotas available
        @param _amountHighQuota: amount of low high quotas available 
        @param _donationReceiver: address for the donation receiver 
        @param _donationFee: fee value for the donation
        @param _minSoldRate: minimum rate of sold quotas */
    struct CrowdFundParams {
        uint256[3] _valuesLowQuota;
        uint256[3] _valuesRegQuota;
        uint256[3] _valuesHighQuota;
        uint256 _amountLowQuota;
        uint256 _amountRegQuota;
        uint256 _amountHighQuota;
        address _donationReceiver;
        uint256 _donationFee;
        uint256 _minSoldRate;
    }

    struct Creator {
        address escrow;
        bool isAllowed;
    }

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /** @dev event for when a new ERC721 art collection is instantiated
        @param collection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event ArtCollection(
        address indexed collection,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a new ERC721 crowdfund collection is instantiated
        @param fundCollection: new ERC721 crowdfund collection address
        @param artCollection: new ERC721 art collection address
        @param creator: collection creator address 
        @param caller: caller address of the function */
    event Crowdfund(
        address indexed fundCollection,
        address indexed artCollection,
        address indexed creator,
        address caller
    );

    /** @dev event for when a new ERC721 collection from CreatorsPRO staff is instantiated
        @param collection: new ERC721 address
        @param creator: creator address of the ERC721 collection */
    event CreatorsCollection(
        address indexed collection,
        address indexed creator
    );

    /** @dev event for when a creator address is set
        @param creator: the creator address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event CreatorSet(
        address indexed creator,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new beacon admin address for ERC721 art collection contract is set
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminArt(address indexed _new, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 crowdfund collection contract is set 
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminFund(address indexed _new, address indexed manager);

    /** @dev event for when a new beacon admin address for ERC721 CreatorsPRO collection contract is set 
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminCreators(address indexed _new, address indexed manager);

    /** @dev event for when a new multisig wallet address is set
        @param _new: new multisig wallet address
        @param manager: the manager address that has done the setting */
    event NewMultiSig(address indexed _new, address indexed manager);

    /** @dev event for when a new royalty fee is set
        @param newFee: new royalty fee
        @param manager: the manager address that has done the setting */
    event NewFee(uint256 indexed newFee, address indexed manager);

    /** @dev event for when a creator address is set
        @param setManager: the manager address that was set
        @param allowed: the permission given for the address
        @param manager: the manager address that has done the setting */
    event ManagerSet(
        address indexed setManager,
        bool allowed,
        address indexed manager
    );

    /** @dev event for when a new token contract address is set
        @param manager: address of the manager that has set the hash object
        @param _contract: address of the token contract 
        @param coin: coin/token of the contract */
    event TokenContractSet(
        address indexed manager,
        address indexed _contract,
        Coin coin
    );

    /** @dev event for when a new ERC721 staking contract is instantiated
        @param staking: new ERC721 staking contract address
        @param creator: contract creator address 
        @param caller: caller address of the function */
    event CRPStaking(
        address indexed staking,
        address indexed creator,
        address indexed caller
    );

    /** @dev event for when a creator's address is set to corrupted (true) or not (false) 
        @param manager: maanger's address
        @param creator: creator's address
        @param corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    event CorruptedAddressSet(
        address indexed manager,
        address indexed creator,
        bool corrupted
    );

    /** @dev event for when a new beacon admin address for ERC721 staking contract is set 
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewBeaconAdminStaking(address indexed _new, address indexed manager);

    /** @dev event for when a new proxy address for reward contract is set 
        @param _new: new beacon admin address
        @param manager: the manager address that has done the setting */
    event NewProxyReward(address indexed _new, address indexed manager);

    /** @dev event for when a CreatorsPRO collection is set
        @param collection: collection address
        @param _set: true if collection is from CreatorsPRO, false otherwise */
    event CollectionSet(address indexed collection, bool _set);

    /// -----------------------------------------------------------------------
    /// Custom errors
    /// -----------------------------------------------------------------------

    ///@dev error for when caller is not allowed creator or manager
    error ManagementNotAllowed();

    ///@dev error for when collection name is invalid
    error ManagementInvalidName();

    ///@dev error for when collection symbol is invalid
    error ManagementInvalidSymbol();

    ///@dev error for when the input is an invalid address
    error ManagementInvalidAddress();

    ///@dev error for when the resulting max supply is 0
    error ManagementFundMaxSupplyIs0();

    ///@dev error for when a token contract address is set for ETH/MATIC
    error ManagementCannotSetAddressForETH();

    ///@dev error for when creator is corrupted
    error ManagementCreatorCorrupted();

    ///@dev error for when an invalid collection address is given
    error ManagementInvalidCollection();

    ///@dev error for when not the collection creator address calls function
    error ManagementNotCollectionCreator();

    ///@dev error for when given address is not allowed creator
    error ManagementAddressNotCreator();

    /// -----------------------------------------------------------------------
    /// Functions
    /// -----------------------------------------------------------------------

    // --- From storage variables ---

    /** @notice reads beaconAdminArt public storage variable
        @return address of the beacon admin for the art collection (ERC721) contract */
    function beaconAdminArt() external view returns (address);

    /** @notice reads beaconAdminFund public storage variable
        @return address of the beacon admin for the crowdfund (ERC721) contract */
    function beaconAdminFund() external view returns (address);

    /** @notice reads beaconAdminCreators public storage variable
        @return address of the beacon admin for the CreatorsPRO collection (ERC721) contract */
    function beaconAdminCreators() external view returns (address);

    /** @notice reads beaconAdminStaking public storage variable
        @return address of the beacon admin for staking contract */
    function beaconAdminStaking() external view returns (address);

    /** @notice reads proxyReward public storage variable
        @return address of the beacon admin for staking contract */
    function proxyReward() external view returns (ICRPReward);

    /** @notice reads multiSig public storage variable 
        @return address of the multisig wallet */
    function multiSig() external view returns (address);

    /** @notice reads fee public storage variable 
        @return the royalty fee */
    function fee() external view returns (uint256);

    /** @notice reads managers public storage mapping
        @param _caller: address to check if is manager
        @return boolean if the given address is a manager */
    function managers(address _caller) external view returns (bool);

    /** @notice reads tokenContract public storage mapping
        @param _coin: coin/token for the contract address
        @return IERC20 instance for the given coin/token */
    function tokenContract(Coin _coin) external view returns (IERC20);

    /** @notice reads isCorrupted public storage mapping 
        @param _creator: creator address
        @return bool that sepcifies if creator is corrupted (true) or not (false) */
    function isCorrupted(address _creator) external view returns (bool);

    /** @notice reads collections public storage mapping 
        @param _collection: collection address
        @return bool that sepcifies if collection is from CreatorsPRO (true) or not (false)  */
    function collections(address _collection) external view returns (bool);

    /** @notice reads stakingCollections public storage mapping 
        @param _collection: collection address
        @return bool that sepcifies if staking collection is from CreatorsPRO (true) or not (false)  */
    function stakingCollections(
        address _collection
    ) external view returns (bool);

    // --- Implemented functions ---

    /** @dev smart contract's initializer/constructor.
        @param _beaconAdminArt: address of the beacon admin for the creators ERC721 art smart contract 
        @param _beaconAdminFund: address of the beacon admin for the creators ERC721 fund smart contract
        @param _beaconAdminCreators: address of the beacon admin for the CreatorPRO ERC721 smart contract 
        @param _creatorsCoin: address of the CreatorsCoin ERC20 contract 
        @param _erc20USD: address of a stablecoin contract (USDC/USDT/DAI)
        @param _multiSig: address of the Multisig smart contract
        @param _fee: royalty fee */
    function initialize(
        address _beaconAdminArt,
        address _beaconAdminFund,
        address _beaconAdminCreators,
        address _creatorsCoin,
        address _erc20USD,
        address _multiSig,
        uint256 _fee
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param _price: mint price of a single NFT
        @param _baseURI: base URI for the collection's metadata 
        @param _royalty: royalty payment to owner */
    function newArtCollection(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSD,
        uint256 _priceInCreatorsCoin,
        string memory _baseURI,
        uint256 _royalty
    ) external;

    /** @notice instantiates/deploys new NFT art collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param _price: mint price of a single NFT
        @param _baseURI: base URI for the collection's metadata 
        @param _royalty: royalty payment to owner 
        @param _owner: owner address of the collection */
    function newArtCollection(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSD,
        uint256 _priceInCreatorsCoin,
        string memory _baseURI,
        uint256 _royalty,
        address _owner
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _baseURI: base URI for the collection's metadata
        @param _cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _royalty,
        CrowdFundParams memory _cfParams
    ) external;

    /** @notice instantiates/deploys new NFT fund collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _baseURI: base URI for the collection's metadata
        @param _owner: owner address of the collection
        @param _cfParams: parameters of the crowdfunding */
    function newCrowdfund(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint256 _royalty,
        address _owner,
        CrowdFundParams memory _cfParams
    ) external;

    /** @notice instantiates/deploys new CreatorPRO NFT art collection smart contract.
        @param _name: name of the NFT collection
        @param _symbol: symbol of the NFT collection
        @param _maxSupply: maximum NFT supply. If 0 is given, the maximum is 2^255 - 1
        @param _price: mint price of a single NFT
        @param _baseURI: base URI for the collection's metadata */
    function newCreatorsCollection(
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _price,
        uint256 _priceInUSDC,
        uint256 _priceInCreatorsCoin,
        string memory _baseURI
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param _stakingToken: crowdfunding contract NFTArt address
        @param _timeUnit: unit of time to be considered when calculating rewards
        @param _rewardsPerUnitTime: stipulated time reward */
    function newCRPStaking(
        address _stakingToken,
        uint256 _timeUnit,
        uint256[3] calldata _rewardsPerUnitTime
    ) external;

    /** @notice instantiates new ERC721 staking contract
        @param _stakingToken: crowdfunding contract NFTArt address
        @param _timeUnit: unit of time to be considered when calculating rewards
        @param _rewardsPerUnitTime: stipulated time reward
        @param _owner: owner address of the collection */
    function newCRPStaking(
        address _stakingToken,
        uint256 _timeUnit,
        uint256[3] calldata _rewardsPerUnitTime,
        address _owner
    ) external;

    // --- Setter functions ---

    /** @notice sets creator permission.
        @param _creator: creator address
        @param _allowed: boolean that specifies if creator address has permission (true) or not (false) */
    function setCreator(address _creator, bool _allowed) external;

    /** @notice sets manager permission.
        @param _manager: manager address
        @param _allowed: boolean that specifies if manager address has permission (true) or not (false) */
    function setManager(address _manager, bool _allowed) external;

    /** @notice sets new beacon admin address for the creators ERC721 art smart contract.
        @param _new: new address */
    function setBeaconAdminArt(address _new) external;

    /** @notice sets new beacon admin address for the creators ERC721 fund smart contract.
        @param _new: new address */
    function setBeaconAdminFund(address _new) external;

    /** @notice sets new beacon admin address for the CreatorPRO ERC721 smart contract.
        @param _new: new address */
    function setBeaconAdminCreators(address _new) external;

    /** @notice sets new address for the Multisig smart contract.
        @param _new: new address */
    function setMultiSig(address _new) external;

    /** @notice sets new fee for NFT minting.
        @param _fee: new fee */
    function setFee(uint256 _fee) external;

    /** @notice sets new contract address for the given token 
        @param _coin: coin/token for the given contract address
        @param _contract: new address of the token contract */
    function setTokenContract(Coin _coin, address _contract) external;

    /** @notice sets given creator address to corrupted (true) or not (false)
        @param _creator: creator address
        @param _corrupted: boolean that sets if creatos is corrupted (true) or not (false) */
    function setCorrupted(address _creator, bool _corrupted) external;

    /** @notice sets new beacon admin address for the ERC721 staking smart contract.
        @param _new: new address */
    function setBeaconAdminStaking(address _new) external;

    /** @notice sets new proxy address for the reward smart contract.
        @param _new: new address */
    function setProxyReward(address _new) external;

    /** @notice sets new collection address
        @param _collection: collection address
        @param _set: true (collection from CreatorsPRO) or false */
    function setCollections(address _collection, bool _set) external;

    ///@notice pauses the contract so that functions cannot be executed.
    function pause() external;

    ///@notice unpauses the contract so that functions can be executed
    function unpause() external;

    // --- Getter functions ---

    /** @notice gets the address of the current implementation smart contract 
        @return address of the current implementation contract */
    function getImplementation() external returns (address);

    /** @notice reads creators public storage mapping
        @param _caller: address to check if is allowed creator
        @return Creator struct with creator info */
    function getCreator(address _caller) external view returns (Creator memory);
}