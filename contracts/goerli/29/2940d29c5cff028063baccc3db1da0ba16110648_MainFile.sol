// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
        //address _address;
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
    // mapping(address => uint256) private tokenExchangeRate;
    mapping(address => InvestingInfo[]) internal investings;
    mapping(address => InvestingInfo[]) internal investmentHistory;
    mapping(address => uint256) internal withdrawable;
    mapping(address => uint256) internal numOfReferrees;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimal
    ) TokenFile(name, symbol, decimal) {
        _setOwner(msg.sender);
    }

    function numOfActiveInvestings() external view returns (uint256 _num) {
        _num = investings[msg.sender].length;
    }

    function numOfUserActiveInvestings(address address_)
        external
        view
        isOwner
        returns (uint256 _num)
    {
        _num = investings[address_].length;
    }

    function myInvestingInfo(uint256 i_)
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
        InvestingInfo[] memory tmp = investings[msg.sender];

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

    function getInvestingInfo(address _address, uint256 i_)
        external
        view
        isOwner
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

    function myInvestingOverview()
        external
        view
        userExists(msg.sender)
        returns (uint256 _totalInvestment, uint256 _totalReceivedProfit)
    {
        (_totalInvestment, _totalReceivedProfit) = _getInvestingOverview(
            msg.sender
        );
    }

    function getInvestingOverview(address address_)
        external
        view
        isOwner
        userExists(address_)
        returns (uint256 _totalInvestment, uint256 _totalReceivedProfit)
    {
        (_totalInvestment, _totalReceivedProfit) = _getInvestingOverview(
            address_
        );
    }

    function _getInvestingOverview(address address_)
        internal
        view
        returns (uint256 _totalInvestment, uint256 _totalReceivedProfit)
    {
        InvestingInfo[] memory tmp = investings[address_];
        for (uint256 i; i < tmp.length; ++i) {
            _totalInvestment += tmp[i].amount;
            _totalReceivedProfit += tmp[i].receivedProfits;
        }
    }

    function getMyWithdrawableBalance()
        external
        view
        returns (uint256 _withdrawable)
    {
        _withdrawable = _getUserWithdrawableBalance(msg.sender);
    }

    function getUserWithdrawableBalance(address address_)
        external
        view
        isOwner
        returns (uint256 _withdrawable)
    {
        _withdrawable = _getUserWithdrawableBalance(address_);
    }

    function _getUserWithdrawableBalance(address address_)
        internal
        view
        returns (uint256 _withdrawable)
    {
        _withdrawable = withdrawable[address_];
    }

    function getTotalAllocatedProfit()
        external
        view
        isOwner
        returns (uint256 _totalAllocatedProfit)
    {
        _totalAllocatedProfit = totalAllocatedProfit;
    }

    function getTotalInvestments()
        external
        view
        isOwner
        returns (uint256 _totalInvestments)
    {
        _totalInvestments = totalInvestment;
    }

    function getpenaltyPercentage()
        external
        view
        returns (uint256 _penaltyPercentage)
    {
        _penaltyPercentage = penaltyPercentage;
    }

    function setPenaltyPercentage(uint256 penaltyPercentage_)
        external
        isOwner
        returns (bool _result)
    {
        penaltyPercentage = penaltyPercentage_;
        _result = true;
    }

    function getTotalInvestors()
        external
        view
        isOwner
        returns (uint256 _totalInvestors)
    {
        _totalInvestors = totalInvestors;
    }

    function getSetting()
        external
        view
        isOwner
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

    function setMinInvest(uint256 minInvest_)
        external
        isOwner
        returns (bool _result)
    {
        minInvest = minInvest_;
        _result = true;
    }

    function setMinPeriod(uint256 minPeriod_)
        external
        isOwner
        returns (bool _result)
    {
        minPeriod = minPeriod_;
        _result = true;
    }

    function setProfitPerDayWithoutReferral(
        uint256 profitPerDayWithoutReferral_
    ) external isOwner returns (bool _result) {
        profitPerDayWithoutReferral = profitPerDayWithoutReferral_;
        _result = true;
    }

    function setProfitPerDayWithReferral(uint256 profitPerDayWithReferral_)
        external
        isOwner
        returns (bool _result)
    {
        profitPerDayWithReferral = profitPerDayWithReferral_;
        _result = true;
    }

    function setReferralProfit(uint256 referralProfit_)
        external
        isOwner
        returns (bool _result)
    {
        referralProfit = referralProfit_;
        _result = true;
    }

    function setMonthlyCoeficient(uint256 monthlyCoeficient_)
        external
        isOwner
        returns (bool _result)
    {
        monthlyCoeficient = monthlyCoeficient_;
        _result = true;
    }

    function setPayProfitPeriod(uint256 payProfitPeriod_)
        external
        isOwner
        returns (bool _result)
    {
        payProfitPeriod = payProfitPeriod_;
        _result = true;
    }

    function setFee(uint256 fee_) external isOwner returns (bool _result) {
        fee = fee_;
        _result = true;
    }

    // function getTokenExchangeRate(address _address)
    //     external
    //     view
    //     isOwner
    //     returns (uint256 _rate)
    // {
    //     require(tokenExchangeRate[_address] != 0, "Rate is not determined!");
    //     _rate = tokenExchangeRate[_address];
    // }

    // function setTokenExchangeRate(address _address, uint256 _rate)
    //     external
    //     isOwner
    //     returns (bool _result)
    // {
    //     require(_rate != 0, "Rate is not valid!");
    //     tokenExchangeRate[_address] = _rate;
    //     _result = true;
    // }

    function setReferral(address address_)
        external
        notMe(address_)
        returns (bool _result)
    {
        referrals[msg.sender] = address_;
        ++numOfReferrees[address_];
        _result = true;
    }

    function checkReferral() external view returns (address _referral) {
        require(referrals[msg.sender] != address(0), "Not set yet!");
        _referral = referrals[msg.sender];
    }

    function addToken(address address_, uint256 rate_)
        external
        isOwner
        tokenNotExists(address_)
        returns (bool _result)
    {
        require(address_ != address(0), "Token is not acceptable!");
        require(rate_ != 0, "Rate is not acceptable!");

        acceptableTokens[address_] = rate_;
        acceptableTokensList.push(address_);
        _result = true;
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

    function numOfMyReferrees() external view returns (uint256 _referees) {
        _referees = numOfUserReferrees(msg.sender);
    }

    function getNumOfUserReferrees(address address_)
        external
        view
        isOwner
        returns (uint256 _referees)
    {
        _referees = numOfUserReferrees(address_);
    }

    function numOfUserReferrees(address address_)
        internal
        view
        returns (uint256 _referees)
    {
        _referees = numOfReferrees[address_];
    }

    function changeTokenRate(address address_, uint256 rate_)
        external
        isOwner
        tokenExists(address_)
        returns (bool _result)
    {
        require(rate_ != 0, "Rate is not acceptable!");

        acceptableTokens[address_] = rate_;
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
        uint256 _qty = (10000 * amount_) / acceptableTokens[tokenToGet_];
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

    function withdraw(address tokenToGet_, uint256 amount_)
        external
        isOwner
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToGet_);
        _token.transfer(msg.sender, amount_);
        _result = true;
    }

    function deposit(address tokenToSend_, uint256 amount_)
        external
        isOwner
        returns (bool _result)
    {
        require(amount_ != 0);
        IERC20 _token = IERC20(tokenToSend_);
        _token.transferFrom(msg.sender, address(this), amount_);
        _result = true;
    }

    function calculateInvestmentRate(uint256 period_)
        external
        view
        returns (
            uint256 _profitPercentPerDay,
            uint256 _profitPercentPerExtraDays
        )
    {
        require(minPeriod <= period_, "Minimum investment period is 30 days!");
        require(maxPeriod >= period_, "Maximum investment period is 730 days!");

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

    function invest(uint256 amount_, uint256 period_)
        external
        returns (bool _result)
    {
        require(amount_ != 0);
        require(minInvest <= amount_, "Investment amount is too low!");
        require(minPeriod <= period_, "Minimum investment period is 30 days!");
        require(maxPeriod >= period_, "Maximum investment period is 730 days!");

        if (investors[msg.sender] == 0) {
            ++totalInvestors;
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

    function updateUserInvestingInfo(address address_)
        external
        isOwner
        userExists(address_)
        returns (bool _result)
    {
        _result = _updateInvestingInfo(address_);
    }

    function myInvestmentHistory()
        external
        view
        returns (InvestingInfo[] memory _history)
    {
        _history = getinvestmentHistory(msg.sender);
    }

    function getUserInvestmentHistory(address address_)
        external
        view
        isOwner
        returns (InvestingInfo[] memory _history)
    {
        _history = getinvestmentHistory(address_);
    }

    function getinvestmentHistory(address address_)
        internal
        view
        returns (InvestingInfo[] memory _history)
    {
        _history=investmentHistory[address_];
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
        // uint256 _referralProfitPercent = referralProfit;
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
                //_profit += _info.amount;
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
}