// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "./interfaces/IAffiliateProgram.sol";

//
contract AffiliateProgram is IAffiliateProgram {
    struct Account {
        bool registered;
        address affiliate;
        address[] referrals;
    }

    mapping(address => Account) public accounts;

    event RegisteredAffiliate(address affiliate);
    event RegisteredReferer(address affiliate, address referrer);

    function register() external {
        require(!accounts[msg.sender].registered, "Already registered");

        accounts[msg.sender].registered = true;
        emit RegisteredAffiliate(msg.sender);
    }

    // @dev called by referral
    function register(address _affiliate) external {
        require(!accounts[msg.sender].registered, "Already registered");
        require(_affiliate != address(0), "Zero address affiliate");
        require(_affiliate != msg.sender, "You cannot refer yourself");

        uint len = accounts[_affiliate].referrals.length;
        if (len == 0) {
            accounts[_affiliate].registered = true;
            emit RegisteredAffiliate(_affiliate);
        }

        accounts[_affiliate].referrals.push(msg.sender);
        accounts[msg.sender].affiliate = _affiliate;
        accounts[msg.sender].registered = true;
        emit RegisteredAffiliate(msg.sender);
        emit RegisteredReferer(_affiliate, msg.sender);
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function hasAffiliate(address _addr) external view override returns (bool result) {
        result = accounts[_addr].affiliate != address(0);
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function countReferrals(address _addr) external view override returns (uint256 amount) {
        amount = accounts[_addr].referrals.length;
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function getAffiliate(address _addr) external view override returns (address result) {
        result = accounts[_addr].affiliate;
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function getReferrals(address _addr) external view override returns (address[] memory result) {
        result = accounts[_addr].referrals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

interface IAffiliateProgram {
    function hasAffiliate(address _addr) external view returns (bool result);

    function countReferrals(address _addr) external view returns (uint256 amount);

    function getAffiliate(address _addr) external view returns (address account);

    function getReferrals(address _addr) external view returns (address[] memory results);
}