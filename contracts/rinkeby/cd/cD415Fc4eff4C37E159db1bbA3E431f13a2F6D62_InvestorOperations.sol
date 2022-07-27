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