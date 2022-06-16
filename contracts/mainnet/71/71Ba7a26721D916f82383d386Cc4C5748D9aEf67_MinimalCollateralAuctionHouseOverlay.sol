/**
 *Submitted for verification at Etherscan.io on 2022-06-16
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

abstract contract CollateralAuctionHouseLike {
    function terminateAuctionPrematurely(uint256 id) virtual external;
}
abstract contract SAFEEngineLike {
    function transferCollateral(bytes32,address,address,uint256) virtual external;
}

contract MinimalCollateralAuctionHouseOverlay is GebAuth {
    SAFEEngineLike             public safeEngine;
    CollateralAuctionHouseLike public collateralAuctionHouse;

    constructor(address safeEngine_, address collateralAuctionHouse_) public GebAuth() {
        require(collateralAuctionHouse_ != address(0), "MinimalCollateralAuctionHouseOverlay/null-address");
        require(safeEngine_ != address(0), "MinimalCollateralAuctionHouseOverlay/null-address");
        safeEngine             = SAFEEngineLike(safeEngine_);
        collateralAuctionHouse = CollateralAuctionHouseLike(collateralAuctionHouse_);
    }

    /*
    * @notify Terminate a collateral auction prematurely
    * @param id ID of the auction to settle
    */
    function terminateAuctionPrematurely(uint256 id) external isAuthorized {
        collateralAuctionHouse.terminateAuctionPrematurely(id);
    }

    /*
    * @notify Transfer internal collateral to another address
    * @param collateralType Collateral type transferred
    * @param dst Collateral destination
    * @param wad Amount of collateral transferred
    */
    function transferCollateral(
        bytes32 collateralType,
        address dst,
        uint256 wad
    ) external isAuthorized {
        safeEngine.transferCollateral(collateralType, address(this), dst, wad);
    }
}