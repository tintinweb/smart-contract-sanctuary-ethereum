/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/fs14a1fn2n0n355szi63iq33n5yzygnk-geb/dapp/geb/src/BasicTokenAdapters.sol

pragma solidity =0.6.7;

////// /nix/store/fs14a1fn2n0n355szi63iq33n5yzygnk-geb/dapp/geb/src/BasicTokenAdapters.sol
/// BasicTokenAdapters.sol

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.6.7; */

abstract contract CollateralLike_2 {
    function decimals() virtual public view returns (uint256);
    function transfer(address,uint256) virtual public returns (bool);
    function transferFrom(address,address,uint256) virtual public returns (bool);
}

abstract contract DSTokenLike_2 {
    function mint(address,uint256) virtual external;
    function burn(address,uint256) virtual external;
}

abstract contract SAFEEngineLike_3 {
    function modifyCollateralBalance(bytes32,address,int256) virtual external;
    function transferInternalCoins(address,address,uint256) virtual external;
}

/*
    Here we provide *adapters* to connect the SAFEEngine to arbitrary external
    token implementations, creating a bounded context for the SAFEEngine. The
    adapters here are provided as working examples:
      - `BasicCollateralJoin`: For well behaved ERC20 tokens, with simple transfer semantics.
      - `ETHJoin`: For native Ether.
      - `CoinJoin`: For connecting internal coin balances to an external
                   `Coin` implementation.
    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.
    Adapters need to implement two basic methods:
      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system
*/

contract BasicCollateralJoin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
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
        require(authorizedAccounts[msg.sender] == 1, "BasicCollateralJoin/account-not-authorized");
        _;
    }

    // SAFE database
    SAFEEngineLike_3  public safeEngine;
    // Collateral type name
    bytes32        public collateralType;
    // Actual collateral token contract
    CollateralLike_2 public collateral;
    // How many decimals the collateral token has
    uint256        public decimals;
    // Whether this adapter contract is enabled or not
    uint256        public contractEnabled;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address account, uint256 wad);
    event Exit(address sender, address account, uint256 wad);

    constructor(address safeEngine_, bytes32 collateralType_, address collateral_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled = 1;
        safeEngine      = SAFEEngineLike_3(safeEngine_);
        collateralType  = collateralType_;
        collateral      = CollateralLike_2(collateral_);
        decimals        = collateral.decimals();
        require(decimals == 18, "BasicCollateralJoin/non-18-decimals");
        emit AddAuthorization(msg.sender);
    }
    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    /**
    * @notice Join collateral in the system
    * @dev This function locks collateral in the adapter and creates a 'representation' of
    *      the locked collateral inside the system. This adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account from which we transferFrom collateral and add it in the system
    * @param wad Amount of collateral to transfer in the system (represented as a number with 18 decimals)
    **/
    function join(address account, uint256 wad) external {
        require(contractEnabled == 1, "BasicCollateralJoin/contract-not-enabled");
        require(int256(wad) >= 0, "BasicCollateralJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, account, int256(wad));
        require(collateral.transferFrom(msg.sender, address(this), wad), "BasicCollateralJoin/failed-transfer");
        emit Join(msg.sender, account, wad);
    }
    /**
    * @notice Exit collateral from the system
    * @dev This function destroys the collateral representation from inside the system
    *      and exits the collateral from this adapter. The adapter assumes that the collateral
    *      has 18 decimals
    * @param account Account to which we transfer the collateral
    * @param wad Amount of collateral to transfer to 'account' (represented as a number with 18 decimals)
    **/
    function exit(address account, uint256 wad) external {
        require(wad <= 2 ** 255, "BasicCollateralJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int256(wad));
        require(collateral.transfer(account, wad), "BasicCollateralJoin/failed-transfer");
        emit Exit(msg.sender, account, wad);
    }
}

contract ETHJoin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
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
    * @notice Checks whether msg.sender can call a restricted function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "ETHJoin/account-not-authorized");
        _;
    }

    // SAFE database
    SAFEEngineLike_3 public safeEngine;
    // Collateral type name
    bytes32       public collateralType;
    // Whether this contract is enabled or not
    uint256       public contractEnabled;
    // Number of decimals ETH has
    uint256       public decimals;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address account, uint256 wad);
    event Exit(address sender, address account, uint256 wad);

    constructor(address safeEngine_, bytes32 collateralType_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled                = 1;
        safeEngine                     = SAFEEngineLike_3(safeEngine_);
        collateralType                 = collateralType_;
        decimals                       = 18;
        emit AddAuthorization(msg.sender);
    }
    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    /**
    * @notice Join ETH in the system
    * @param account Account that will receive the ETH representation inside the system
    **/
    function join(address account) external payable {
        require(contractEnabled == 1, "ETHJoin/contract-not-enabled");
        require(int256(msg.value) >= 0, "ETHJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, account, int256(msg.value));
        emit Join(msg.sender, account, msg.value);
    }
    /**
    * @notice Exit ETH from the system
    * @param account Account that will receive the ETH representation inside the system
    **/
    function exit(address payable account, uint256 wad) external {
        require(int256(wad) >= 0, "ETHJoin/overflow");
        safeEngine.modifyCollateralBalance(collateralType, msg.sender, -int256(wad));
        emit Exit(msg.sender, account, wad);
        account.transfer(wad);
    }
}

contract CoinJoin {
    // --- Auth ---
    mapping (address => uint256) public authorizedAccounts;
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
        require(authorizedAccounts[msg.sender] == 1, "CoinJoin/account-not-authorized");
        _;
    }

    // SAFE database
    SAFEEngineLike_3 public safeEngine;
    // Coin created by the system; this is the external, ERC-20 representation, not the internal 'coinBalance'
    DSTokenLike_2    public systemCoin;
    // Whether this contract is enabled or not
    uint256        public contractEnabled;
    // Number of decimals the system coin has
    uint256        public decimals;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event DisableContract();
    event Join(address sender, address account, uint256 wad);
    event Exit(address sender, address account, uint256 wad);

    constructor(address safeEngine_, address systemCoin_) public {
        authorizedAccounts[msg.sender] = 1;
        contractEnabled                = 1;
        safeEngine                     = SAFEEngineLike_3(safeEngine_);
        systemCoin                     = DSTokenLike_2(systemCoin_);
        decimals                       = 18;
        emit AddAuthorization(msg.sender);
    }
    /**
     * @notice Disable this contract
     */
    function disableContract() external isAuthorized {
        contractEnabled = 0;
        emit DisableContract();
    }
    uint256 constant RAY = 10 ** 27;
    function multiply(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "CoinJoin/mul-overflow");
    }
    /**
    * @notice Join system coins in the system
    * @dev Exited coins have 18 decimals but inside the system they have 45 (rad) decimals.
           When we join, the amount (wad) is multiplied by 10**27 (ray)
    * @param account Account that will receive the joined coins
    * @param wad Amount of external coins to join (18 decimal number)
    **/
    function join(address account, uint256 wad) external {
        safeEngine.transferInternalCoins(address(this), account, multiply(RAY, wad));
        systemCoin.burn(msg.sender, wad);
        emit Join(msg.sender, account, wad);
    }
    /**
    * @notice Exit system coins from the system and inside 'Coin.sol'
    * @dev Inside the system, coins have 45 (rad) decimals but outside of it they have 18 decimals (wad).
           When we exit, we specify a wad amount of coins and then the contract automatically multiplies
           wad by 10**27 to move the correct 45 decimal coin amount to this adapter
    * @param account Account that will receive the exited coins
    * @param wad Amount of internal coins to join (18 decimal number that will be multiplied by ray)
    **/
    function exit(address account, uint256 wad) external {
        require(contractEnabled == 1, "CoinJoin/contract-not-enabled");
        safeEngine.transferInternalCoins(msg.sender, address(this), multiply(RAY, wad));
        systemCoin.mint(account, wad);
        emit Exit(msg.sender, account, wad);
    }
}