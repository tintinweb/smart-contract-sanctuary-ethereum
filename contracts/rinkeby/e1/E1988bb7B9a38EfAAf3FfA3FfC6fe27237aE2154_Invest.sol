// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./InvestorOperations.sol";

/**
* @title basic multilevel marketing system
* @notice implements invest and withdraw functionality
*/
contract Invest {
    mapping(address => uint256) private investedAmount;
    IInvestorOperations private investorOperations;
    uint256[] private depthPayment;
    uint256[] private levelCost;

    modifier onlyEntered() {
        require(investorOperations.getReferralToReferee(msg.sender) != address(0), "Not entered");
        _;
    }

    /// @param _investorOperations Address of IInvestorOperations contract
    constructor(address _investorOperations) {
        investorOperations = IInvestorOperations(_investorOperations);
        depthPayment = [10, 7, 5, 2, 1, 1, 1, 1, 1, 1];
        levelCost = [
        0.005 ether,
        0.01 ether,
        0.02 ether,
        0.05 ether,
        0.1 ether,
        0.2 ether,
        0.5 ether,
        1 ether,
        2 ether,
        5 ether
        ];
    }

    /// @dev mimics invest()
    receive() external payable {
        require (investorOperations.getReferralToReferee(msg.sender) != address(0), "Not entered");
        investedAmount[msg.sender] += msg.value * (100 - 5) / 100;
    }

    /// @notice allows to invest amount of ether; takes investment fee before enroll
    /// @dev updates investedAmount[msg.sender]
    function invest() external payable onlyEntered {
        investedAmount[msg.sender] += msg.value * (100 - 5) / 100;
    }

    /// @notice withdraws all the funds of msg.sender and pays payout to referees
    /// @dev sets investedAmount[msg.sender] = 0; transfers funds; updates investedAmount of referees
    function withdraw() external {
        uint256 amount = investedAmount[msg.sender];
        require(amount >= 5 * 1e15, "Too little balance");
        investedAmount[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
        _payToReferees(msg.sender, amount);
    }


    /// @return array with levels of referrals
    function getLevelOfReferrals() external view returns (uint256[] memory) {
        address[] memory _referrals = investorOperations.getRefereeToReferrals(msg.sender);
        uint256[] memory _levels = new uint256[](_referrals.length);
        for (uint256 i = 0; i < _levels.length; i++) {
            _levels[i] = _getLevel(_referrals[i]);
            }
        return _levels;
    }

    /// @return current level of msg.sender
    function getLevel() external view returns (uint256) {
        return _getLevel(msg.sender);
    }

    /// @param _currReferral The withdrawing referral
    /// @param _withdrawingAmount The investedAmount of '_currReferral'
    /// @dev gives payout to the referees of '_currReferral'; commission is calculated from '_withdrawingAmount'
    function _payToReferees(address _currReferral, uint256 _withdrawingAmount) private {
        address _currReferee = investorOperations.getReferralToReferee(_currReferral);
        for (uint256 i = 1; i <= depthPayment.length; i++) {
            // stops when investor doesn't have referee
            if (_currReferee == _currReferral) {
                break;
            }
            if (_getLevel(_currReferee) >= i) {
                uint256 amountToPay = (_withdrawingAmount * _getCommissionRate(i)) / 1000;
                investedAmount[_currReferee] += amountToPay;
            }
            // updates _currReferral and _currReferee 1 level deeper
            _currReferral = investorOperations.getReferralToReferee(_currReferral);
            _currReferee = investorOperations.getReferralToReferee(_currReferral);
        }
    }

    /// @param  _investor The address of investor
    /// @return current level of '_investor'
    function _getLevel(address _investor) private view returns (uint256) {
        uint256 _amount = investedAmount[_investor];
        for (uint256 i = levelCost.length - 1; i >= 0; i--) {
            if (_amount >= levelCost[i]) {
                return i + 1;
            }
        }
        return 0;
    }

    /// @return number of ones by thousand. For example 10 == 10/1000; 7 == 7/1000
    /// @param _depth The depth of referee of withdrawing referral
    function _getCommissionRate(uint256 _depth) private view returns (uint256) {
        return depthPayment[_depth - 1];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./interfaces/IInvestorOperations.sol";

/**
* @author Vlad Andrievski
* @notice contract provides the basic functionality of record keeping of investors
*/
contract InvestorOperations is IInvestorOperations {
    mapping(address => address[]) private refereeToReferrals;
    mapping(address => address) private referralToReferee;

    event NewDirectPartner(address referral, address referee);
    event NewUser(address userAddress);

    modifier firstTime() {
        require(referralToReferee[msg.sender] == address(0), "Already entered");
        _;
    }

    /// @notice sing up investor to the system without referee
    /// @dev sets referee of msg.sender as msg.sender
    function entry() external firstTime {
        referralToReferee[msg.sender] = msg.sender;
        emit NewUser(msg.sender);
    }

    /// @notice sing up investor to the system with referee
    /// @param _refereeAddress The address of signed up referee
    function entry(address _refereeAddress) external firstTime {
        require(referralToReferee[_refereeAddress] != address(0), "Referee not entered");
        refereeToReferrals[_refereeAddress].push(msg.sender);
        referralToReferee[msg.sender] = _refereeAddress;
        emit NewDirectPartner(msg.sender, _refereeAddress);
    }

    /// @return number of referrals of msg.sender
    function getNumberOfReferrals() external view returns (uint256) {
        return refereeToReferrals[msg.sender].length;
    }

    function getReferralToReferee(address _referral)
        external
        view
        override
        returns (address)
    {
        return referralToReferee[_referral];
    }

    function getRefereeToReferrals(address _referee)
        external
        view
        override
        returns (address[] memory)
    {
        return refereeToReferrals[_referee];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/**
* @author Vlad Andrievski
* @dev this interface is for interacting with Invest contract
*/
interface IInvestorOperations {
    /// @return referee of given address
    /// @param _referral The referral of returned referee
    function getReferralToReferee(address _referral) external view returns (address);

    /// @return referrals of given address
    /// @param _referee The referee of returned referrals
    function getRefereeToReferrals(address _referee) external view returns (address[] memory);
}