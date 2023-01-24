// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
pragma abicoder v2;

import "./TokenFile.sol";
import "./Modifiers.sol";

contract MainFile is TokenFile, Modifiers {
    uint256 private penaltyPercentage;
    uint256 private totalInvestment;
    uint256 private totalInvestors;
    uint256 private totalAllocatedProfit;
    uint256 private maxPeriod = 730;

    uint256 private minInvest = 100000000;
    uint256 private minPeriod = 30;
    uint256 private profitPerDayWithoutReferral = 10;
    uint256 private profitPerDayWithReferral = 15;
    uint256 private referralProfit = 100;
    uint256 private monthlyCoeficient = 50;
    uint256 private payProfitPeriod = 30;
    uint256 private fee = 2;

    struct InvestingInfo {
        uint256 investedAt;
        uint256 endAt;
        uint256 amount;
        uint256 period;
        uint256 payProfitPeriod;
        address referral;
        uint256 lastSettlementAt;
        uint256 settledTill;
        uint256 receivedProfits;
        uint256 profitPercentPerDay;
        uint256 profitPercentPerExtraDays;
    }

    struct InvestingInfoList {
        address _address;
        uint256 investedAt;
        uint256 endAt;
        uint256 amount;
        uint256 period;
        uint256 payProfitPeriod;
        address referral;
        uint256 lastSettlementAt;
        uint256 settledTill;
        uint256 receivedProfits;
        uint256 profitPercentPerDay;
        uint256 profitPercentPerExtraDays;
    }

    mapping(address => address) private referrals;
    mapping(address => InvestingInfo[]) private investings;
    mapping(address => InvestingInfo[]) private investmentHistory;
    mapping(address => uint256) private withdrawable;
    mapping(address => uint256) private numOfReferrees;
    address[] private investorsList;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimal
    ) TokenFile(name, symbol, decimal) {
         owner = msg.sender;
    }

    function getInvestorsList()
        public
        view
        returns (address[] memory _investorsList)
    {
        _investorsList = investorsList;
    }

    function getInvestorsListSize()
        external
        view
        returns (uint256 _investorsListSize)
    {
        _investorsListSize = investorsList.length;
    }

    
    function numOfUserActiveInvestings(address address_)
        external
        view
        returns (uint256 _num)
    {
        _num = investings[address_].length;
    }

    function getInvestingInfo(address _address, uint256 i_)
        external
        view
        returns (
            uint256 _investedAt,
            uint256 _endAt,
            uint256 _lastSettlementAt,
            uint256 _settledTill,
            uint256 _receivedProfits,
            uint256 _amount,
            uint256 _period,
            uint256 _payProfitPeriod,
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        )
    {
        InvestingInfo[] memory tmp = investings[_address];

        _investedAt = tmp[i_].investedAt;
        _endAt = tmp[i_].endAt;
        _lastSettlementAt = tmp[i_].lastSettlementAt;
        _settledTill = tmp[i_].settledTill;
        _receivedProfits = tmp[i_].receivedProfits;
        _amount = tmp[i_].amount;
        _period = tmp[i_].period;
        _payProfitPeriod = tmp[i_].payProfitPeriod;
        _profitPercentPerDay = tmp[i_].profitPercentPerDay;
        _profitPercentPerExtraDays = tmp[i_].profitPercentPerExtraDays;
    }

    function getInvestingOverview(address address_)
        external
        view
        userExists(address_)
        returns (uint256 _totalInvestment, uint256 _totalReceivedProfit)
    {
        InvestingInfo[] memory tmp = investings[address_];
        for (uint256 i; i < tmp.length; ++i) {
            _totalInvestment += tmp[i].amount;
            _totalReceivedProfit += tmp[i].receivedProfits;
        }
    }

    function getBalance(address address_)
        external
        view
        returns (uint256 _withdrawable)
    {
        _withdrawable = withdrawable[address_];
    }

    function numOfActiveInvestings(address _address) external view returns (uint256 _num) {
        _num = investings[_address].length;
    }

    function getOveralInfo()
        external
        view
        returns (
            uint256 _totalAllocatedProfit,
            uint256 _totalInvestments,
            uint256 _totalInvestors,
            uint256 _penaltyPercentage
        )
    {
        _totalAllocatedProfit = totalAllocatedProfit;
        _totalInvestments = totalInvestment;
        _penaltyPercentage = penaltyPercentage;
        _totalInvestors = totalInvestors;
    }

    function getSetting()
        external
        view
        returns (
            uint256 _minInvest,
            uint256 _minPeriod,
            uint256 _profitPerDayWithoutReferral,
            uint256 _profitPerDayWithReferral,
            uint256 _referralProfit,
            uint256 _monthlyCoeficient,
            uint256 _payProfitPeriod,
            uint256 _fee
        )
    {
        _minInvest = minInvest;
        _minPeriod = minPeriod;
        _profitPerDayWithoutReferral = profitPerDayWithoutReferral;
        _profitPerDayWithReferral = profitPerDayWithReferral;
        _referralProfit = referralProfit;
        _monthlyCoeficient = monthlyCoeficient;
        _payProfitPeriod = payProfitPeriod;
        _fee = fee;
    }

    function getReferral(address _address)
        external
        view
        returns (address _referral)
    {
        _referral = referrals[_address];
    }

    function getAcceptableTokensList()
        external
        view
        returns (address[] memory _tokens)
    {
        _tokens = acceptableTokensList;
    }

    function getTokenRate(address address_)
        external
        view
        tokenExists(address_)
        returns (uint256 _rate)
    {
        _rate = acceptableTokens[address_];
    }

    function getNumOfReferrees(address address_)
        external
        view
        returns (uint256 _referees)
    {
        _referees = numOfReferrees[address_];
    }

    function calculateInvestmentRate(uint256 period_)
        external
        view
        returns (
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        )
    {
        require(minPeriod <= period_, "Min investment period not satisfied!!");
        require(maxPeriod >= period_, "Max investment period not satisfied!");

        (
            _profitPercentPerDay,
            _profitPercentPerExtraDays
        ) = _calculateInvestmentRate(period_);
    }

    function _calculateInvestmentRate(uint256 period_)
        internal
        view
        returns (
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        )
    {
        address _referral = referrals[msg.sender];
        if (_referral == address(0)) {
            _profitPercentPerDay = profitPerDayWithoutReferral;
        } else {
            _profitPercentPerDay = profitPerDayWithReferral;
        }
        _profitPercentPerExtraDays = _profitPercentPerDay;
        uint256 c = period_ / minPeriod;
        if (c > 1) {
            _profitPercentPerDay +=
                ((c - 1) * monthlyCoeficient) /
                (c * minPeriod);
        }
    }

    function getInvestmentHistory(address address_)
        external
        view
        returns (InvestingInfo[] memory)
    {
        InvestingInfo[] memory _info = investmentHistory[address_];
        uint256 l = _info.length;
        InvestingInfo[] memory items = new InvestingInfo[](l);

        for (uint256 i = 0; i < l; i++) {
            items[i] = _info[i];
        }
        return items;
    }

    function timeDiff(uint256 endDate_, uint256 startDate_)
        internal
        pure
        returns (uint256 _diff)
    {
        _diff = (endDate_ - startDate_) / 60; //86400;
    }

    function calculateCancelationPenalty(uint256 i_)
        external
        view
        returns (uint256 _penalty)
    {
        InvestingInfo[] memory _info = investings[msg.sender];
        require(i_ < _info.length, "Investment does not exists!");
        _penalty =
            _info[i_].receivedProfits +
            (penaltyPercentage * _info[i_].amount) /
            10000;
    }

    function setReferral(address address_)
        external
        notMe(address_)
        notZero(address_)
        returns (bool _result)
    {
        referrals[msg.sender] = address_;
        ++numOfReferrees[address_];
        _result = true;
    }

    function buy(address tokenToSend_, uint256 amount_)
        external
        tokenExists(tokenToSend_)
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToSend_);
        _token.transferFrom(msg.sender, address(this), amount_);
        uint256 _qty = (amount_ * acceptableTokens[tokenToSend_]) / 10000;
        _transfer(address(this), msg.sender, _qty);
        _result = true;
    }

    function sell(address tokenToGet_, uint256 amount_)
        external
        tokenExists(tokenToGet_)
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToGet_);
        uint256 _fee = (fee * amount_) / 10000;
        uint256 _qty = (10000 * (amount_ - _fee)) /
            acceptableTokens[tokenToGet_];

        _transfer(msg.sender, address(this), amount_);
        _token.transfer(msg.sender, _qty);

        _result = true;
    }

    function withdrawMyBalance() external returns (bool _result) {
        require(withdrawable[msg.sender] != 0);
        _transfer(address(this), msg.sender, withdrawable[msg.sender]);
        withdrawable[msg.sender] = 0;
        _result = true;
    }

    function invest(uint256 amount_, uint256 period_)
        external
        returns (bool _result)
    {
        require(amount_ != 0);
        require(minInvest <= amount_, "Min investment not satisfied!");
        require(minPeriod <= period_, "Min investment period not satisfied!");
        require(maxPeriod >= period_, "Max investment period not satisfied!");

        if (investors[msg.sender] == 0) {
            ++totalInvestors;
            if (investmentHistory[msg.sender].length == 0) {
                investorsList.push(msg.sender);
            }
        }

        investors[msg.sender] += amount_;
        address _referral = referrals[msg.sender];
        (
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        ) = _calculateInvestmentRate(period_);
        uint256 bt = block.timestamp;
        investings[msg.sender].push(
            InvestingInfo({
                investedAt: bt,
                endAt: bt + period_ * 1 minutes,
                amount: amount_,
                period: period_,
                payProfitPeriod: payProfitPeriod,
                referral: _referral,
                lastSettlementAt: bt,
                settledTill: bt,
                receivedProfits: 0,
                profitPercentPerDay: _profitPercentPerDay,
                profitPercentPerExtraDays: _profitPercentPerExtraDays
            })
        );
        totalInvestment += amount_;
        _transfer(msg.sender, address(this), amount_);
        _result = true;
    }

    function updateMyInvestingInfo()
        external
        userExists(msg.sender)
        returns (bool _result)
    {
        _result = _updateInvestingInfo(msg.sender);
    }

    function destroyInvestment(address address_, uint256 i_)
        internal
        returns (bool _result)
    {
        InvestingInfo[] storage _investingInfo = investings[address_];
        uint256 l = _investingInfo.length;
        totalInvestment -= _investingInfo[i_].amount;
        investors[address_] -= _investingInfo[i_].amount;
        investmentHistory[address_].push(_investingInfo[i_]);
        if (l - 1 != i_ && l > 1) {
            _investingInfo[i_] = _investingInfo[l - 1];
        }
        _investingInfo.pop();
        if (l == 1) {
            --totalInvestors;
        }

        _result = true;
    }

    function _updateInvestingInfo(address address_)
        internal
        returns (bool _result)
    {
        InvestingInfo[] memory _investingInfo = investings[address_];
        uint256 l = _investingInfo.length;
        uint256 _now = block.timestamp;
        uint256 _totalProfit;
        uint256 _mainFund;
        for (uint256 i; i != l; ) {
            InvestingInfo memory _info = _investingInfo[i];
            uint256 _profit;
            uint256 d;
            uint256 c;
            if (_info.endAt <= _now) {
                if (_info.settledTill == _info.endAt) {
                    --l;
                    destroyInvestment(address_, i);
                    continue;
                }
                d = timeDiff(_info.endAt, _info.settledTill);
                if (d == 0) {
                    ++i;
                    continue;
                }
                c = d / _info.payProfitPeriod;
                investings[address_][i].settledTill = _info.endAt;
                investings[address_][i].lastSettlementAt = _now;
                if (c != 0) {
                    _profit +=
                        (c *
                            _info.payProfitPeriod *
                            _info.amount *
                            _info.profitPercentPerDay) /
                        10000;
                }
                uint256 r = d - c * _info.payProfitPeriod;
                if (r != 0) {
                    _profit +=
                        (r * _info.amount * _info.profitPercentPerExtraDays) /
                        10000;
                }
                _mainFund += _info.amount;
                investings[address_][i].receivedProfits += _profit;
                _totalProfit += _profit;
                destroyInvestment(address_, i);
                --l;
            } else {
                d = timeDiff(_now, _info.settledTill);
                if (d < _info.payProfitPeriod) {
                    ++i;
                    continue;
                }
                c = d / _info.payProfitPeriod;
                if (c == 0) {
                    ++i;
                    continue;
                }
                investings[address_][i].settledTill +=
                    c *
                    _info.payProfitPeriod *
                    1 minutes;
                investings[address_][i].lastSettlementAt = _now;
                _profit +=
                    (c *
                        _info.payProfitPeriod *
                        _info.amount *
                        _info.profitPercentPerDay) /
                    10000;

                investings[address_][i].receivedProfits += _profit;
                _totalProfit += _profit;
                ++i;
            }
        }

        withdrawable[address_] += _totalProfit + _mainFund;
        if (referrals[address_] != address(0)) {
            uint256 _referralProfit = (_totalProfit * referralProfit) / 10000;
            withdrawable[referrals[address_]] += _referralProfit;
            _totalProfit += _referralProfit;
        }
        totalAllocatedProfit += _totalProfit;
        _result = true;
    }

    function calculateProfit(uint256 till_)
        external
        view
        returns (uint256 _profit)
    {
        uint256 _till = block.timestamp + till_ * 1 minutes;
        uint256 l = investorsList.length;
        address _address;
        for (uint256 i; i < l; i++) {
            _address = investorsList[i];
            _profit += _calcProfit(_address, _till);
        }
    }

    function _calcProfit(address address_, uint256 till_)
        internal
        view
        returns (uint256 _totalProfit)
    {
        InvestingInfo[] memory _investingInfo = investings[address_];
        uint256 l = _investingInfo.length;
        uint256 _now = till_;
        for (uint256 i; i != l; i++) {
            InvestingInfo memory _info = _investingInfo[i];
            uint256 _profit;
            uint256 d;
            uint256 c;
            if (_info.endAt <= _now) {
                if (_info.settledTill == _info.endAt) {
                    continue;
                }
                d = timeDiff(_info.endAt, _info.settledTill);
                if (d == 0) {
                    continue;
                }
                c = d / _info.payProfitPeriod;
                if (c != 0) {
                    _profit +=
                        (c *
                            _info.payProfitPeriod *
                            _info.amount *
                            _info.profitPercentPerDay) /
                        10000;
                }
                uint256 r = d - c * _info.payProfitPeriod;
                if (r != 0) {
                    _profit +=
                        (r * _info.amount * _info.profitPercentPerExtraDays) /
                        10000;
                }
                _totalProfit += _info.amount;
                _totalProfit += _profit;
            } else {
                d = timeDiff(_now, _info.settledTill);
                if (d < _info.payProfitPeriod) {
                    continue;
                }
                c = d / _info.payProfitPeriod;
                if (c == 0) {
                    continue;
                }
                _profit +=
                    (c *
                        _info.payProfitPeriod *
                        _info.amount *
                        _info.profitPercentPerDay) /
                    10000;
                _totalProfit += _profit;
            }
        }

        if (referrals[address_] != address(0)) {
            uint256 _referralProfit = (_totalProfit * referralProfit) / 10000;
            _totalProfit += _referralProfit;
        }
    }

    function cancelInvestment(uint256 i_) external returns (bool _result) {
        InvestingInfo[] memory _info = investings[msg.sender];
        require(i_ < _info.length, "Investment does not exists!");
        uint256 penalty = _info[i_].receivedProfits +
            (penaltyPercentage * _info[i_].amount) /
            10000;
        uint256 remainingQty;
        require(penalty < _info[i_].amount, "Investment can not be canceled!");

        remainingQty = _info[i_].amount - penalty;
        destroyInvestment(msg.sender, i_);

        withdrawable[msg.sender] += remainingQty;

        _result = true;
    }

    function Z_SetProfitPerDayWithReferral(uint256 profitPerDayWithReferral_)
        external
        isOwner
        returns (bool _result)
    {
        require(profitPerDayWithReferral_ > 0);
        profitPerDayWithReferral = profitPerDayWithReferral_;
        _result = true;
    }

    function Z_SetReferralProfit(uint256 referralProfit_)
        external
        isOwner
        returns (bool _result)
    {
        referralProfit = referralProfit_;
        _result = true;
    }

    function Z_SetMonthlyCoeficient(uint256 monthlyCoeficient_)
        external
        isOwner
        returns (bool _result)
    {
        monthlyCoeficient = monthlyCoeficient_;
        _result = true;
    }

    function Z_SetPayProfitPeriod(uint256 payProfitPeriod_)
        external
        isOwner
        returns (bool _result)
    {
        require(payProfitPeriod_ > 0);
        payProfitPeriod = payProfitPeriod_;
        _result = true;
    }

    function Z_SetFee(uint256 fee_) external isOwner returns (bool _result) {
        fee = fee_;
        _result = true;
    }

    function Z_SetProfitPerDayWithoutReferral(
        uint256 profitPerDayWithoutReferral_
    ) external isOwner returns (bool _result) {
        require(profitPerDayWithoutReferral_ > 0);
        profitPerDayWithoutReferral = profitPerDayWithoutReferral_;
        _result = true;
    }

    function Z_SetPenaltyPercentage(uint256 penaltyPercentage_)
        external
        isOwner
        returns (bool _result)
    {
        require(penaltyPercentage_ > 0);
        penaltyPercentage = penaltyPercentage_;
        _result = true;
    }

    function Z_SetMinInvest(uint256 minInvest_)
        external
        isOwner
        returns (bool _result)
    {
        require(minInvest_ > 0);
        minInvest = minInvest_;
        _result = true;
    }

    function Z_SetMinPeriod(uint256 minPeriod_)
        external
        isOwner
        returns (bool _result)
    {
        require(minPeriod_ > 0);
        minPeriod = minPeriod_;
        _result = true;
    }

    function Z_SetMaxPeriod(uint256 maxPeriod_)
        external
        isOwner
        returns (bool _result)
    {
        require(maxPeriod_ > 0);
        maxPeriod = maxPeriod_;
        _result = true;
    }

    function Z_AddToken(address address_, uint256 rate_)
        external
        isOwner
        tokenNotExists(address_)
        notZero(address_)
        returns (bool _result)
    {
        require(rate_ != 0);

        acceptableTokens[address_] = rate_;
        acceptableTokensList.push(address_);
        _result = true;
    }

    function Z_ChangeTokenRate(address address_, uint256 rate_)
        external
        isOwner
        tokenExists(address_)
        returns (bool _result)
    {
        require(rate_ != 0);

        acceptableTokens[address_] = rate_;
        _result = true;
    }

    function Z_Withdraw(address tokenToGet_, uint256 amount_)
        external
        isOwner
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToGet_);
        _token.transfer(msg.sender, amount_);
        _result = true;
    }

    function Z_Deposit(address tokenToSend_, uint256 amount_)
        external
        isOwner
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToSend_);
        _token.transferFrom(msg.sender, address(this), amount_);
        _result = true;
    }

    function Z_UpdateUserInvestingInfo(address address_)
        external
        isOwner
        userExists(address_)
        returns (bool _result)
    {
        _result = _updateInvestingInfo(address_);
    }
}