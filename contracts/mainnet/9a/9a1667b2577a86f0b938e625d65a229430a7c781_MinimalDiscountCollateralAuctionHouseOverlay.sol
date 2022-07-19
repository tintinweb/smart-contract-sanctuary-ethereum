/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

pragma solidity 0.6.7;

contract GebAuth {
    // --- Authorization ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "GebAuth/account-not-authorized");
        _;
    }

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);

    constructor () public {
        authorizedAccounts[msg.sender] = 1;
        emit AddAuthorization(msg.sender);
    }
}

abstract contract DiscountCollateralAuctionHouseLike {
    function modifyParameters(bytes32, uint256) virtual external;
    function modifyParameters(bytes32, address) virtual external;
}
contract MinimalDiscountCollateralAuctionHouseOverlay is GebAuth {
    uint256                            public discountLimit;
    uint256                            public constant WAD = 10 ** 18;

    DiscountCollateralAuctionHouseLike public auctionHouse;

    constructor(address auctionHouse_, uint256 discountLimit_) public GebAuth() {
        require(auctionHouse_ != address(0), "MinimalDiscountCollateralAuctionHouseOverlay/null-address");
        require(both(discountLimit_ > 0, discountLimit_ < WAD), "MinimalDiscountCollateralAuctionHouseOverlay/invalid-discount-limit");

        auctionHouse  = DiscountCollateralAuctionHouseLike(auctionHouse_);
        discountLimit = discountLimit_;
    }

    // --- Boolean Logic ---
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    /**
     * @notice Modify an uint256 parameter
     * @param parameter The name of the parameter to modify
     * @param data New value for the parameter
     */
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        require(
          either(either(parameter == "minDiscount", parameter == "maxDiscount"), parameter == "perSecondDiscountUpdateRate"),
          "MinimalDiscountCollateralAuctionHouseOverlay/modify-forbidden-param"
        );

        if (parameter == "maxDiscount") {
            require(data >= discountLimit, "MinimalDiscountCollateralAuctionHouseOverlay/invalid-max-discount");
        }

        auctionHouse.modifyParameters(parameter, data);
    }

    /*
    * @notice Modify the systemCoinOracle address
    * @param parameter Must be "systemCoinOracle"
    * @param data The new systemCoinOracle address
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        if (parameter == "systemCoinOracle") {
          auctionHouse.modifyParameters(parameter, data);
        } else revert("MinimalDiscountCollateralAuctionHouseOverlay/modify-forbidden-param");
    }
}