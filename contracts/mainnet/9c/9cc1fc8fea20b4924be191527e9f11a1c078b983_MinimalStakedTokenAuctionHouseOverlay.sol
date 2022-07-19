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

abstract contract StakedTokenAuctionHouseLike {
    function modifyParameters(bytes32, address) external virtual;
    function disableContract() external virtual;
}

contract MinimalStakedTokenAuctionHouseOverlay is GebAuth {
    StakedTokenAuctionHouseLike public auctionHouse;

    constructor(address auctionHouse_) public GebAuth() {
        require(auctionHouse_ != address(0), "MinimalStakedTokenAuctionHouseOverlay/null-address");
        auctionHouse = StakedTokenAuctionHouseLike(auctionHouse_);
    }

    /*
    * @notice Change the tokenBurner address in the auction house
    */
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(parameter == "tokenBurner", "MinimalStakedTokenAuctionHouseOverlay/invalid-parameter");
        auctionHouse.modifyParameters(parameter, data);
    }

    /*
    * @notice Disable the auction house
    */
    function disableContract() external isAuthorized {
        auctionHouse.disableContract();
    }
}