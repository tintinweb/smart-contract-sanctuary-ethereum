/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.7;

interface CollateralLike {
    function decimals() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

interface LMCVLike {
    function pushCollateral(bytes32, address, uint256) external;
    function pullCollateral(bytes32, address, uint256) external;
}

/*
    CollateralJoinDecimals.sol -- Basic token adapter

    Like CollateralJoin.sol but for a token that has a lower precision 
    than 18 and it has decimals (like USDC).
*/
contract CollateralJoinDecimals {

    //
    // --- Auth ---
    //

    address public ArchAdmin;
    mapping(address => uint256) public wards;

    function setArchAdmin(address newArch) external auth {
        require(ArchAdmin == msg.sender && newArch != address(0), "CollateralJoinDec/Must be ArchAdmin");
        ArchAdmin = newArch;
        wards[ArchAdmin] = 1;
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        require(usr != ArchAdmin, "CollateralJoinDec/ArchAdmin cannot lose admin - update ArchAdmin to another address");
        wards[usr] = 0;
        emit Deny(usr);
    }

    //
    // --- Interfaces and data ---
    //

    CollateralLike  public collateralContract;
    LMCVLike        public lmcv;
    address         public lmcvProxy;
    bytes32         public collateralName;
    uint256         public dec;
    uint256         public live;

    //
    // --- Events ---
    //

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Cage(uint256 status);

    //
    // --- Modifiers ---
    //

    modifier auth {
        require(wards[msg.sender] == 1, "CollateralJoin/not-authorized");
        _;
    }

    //
    // --- Admin ---
    //

    function cage(uint256 status) external auth {
        live = status;
        emit Cage(status);
    }

    //
    // --- Init ---
    //
    
    constructor(address lmcv_, address lmcvProxy_, bytes32 collateralName_, address collateralContract_) {
        require(lmcv_ != address(0x0) && lmcvProxy_ != address(0x0) && collateralContract_ != address(0x0), "CollateralJoinDec/Can't be zero address");
        collateralContract = CollateralLike(collateralContract_);
        dec = collateralContract.decimals();
        require(dec < 18, "CollateralJoin/decimals cannot be higher than 17");
        ArchAdmin = msg.sender;
        wards[msg.sender] = 1;
        live = 1;
        lmcv = LMCVLike(lmcv_);
        collateralName = collateralName_;
        lmcvProxy = lmcvProxy_;
    }

    //
    // --- User's functions ---
    //

    function join(address urn, uint256 wad, address _msgSender) external auth {
        require(live == 1, "CollateralJoin/not-live");
        uint256 wad18 = wad * (10 ** (18 - dec));
        lmcv.pushCollateral(collateralName, urn, wad18);
        require(collateralContract.transferFrom(_msgSender, address(this), wad), "CollateralJoin/failed-transfer");
    }

    function exit(address guy, uint256 wad) external {
        require(live == 1, "CollateralJoin/not-live");
        uint256 wad18 = wad * (10 ** (18 - dec));
        lmcv.pullCollateral(collateralName,  msg.sender, wad18);
        require(collateralContract.transfer(guy, wad), "CollateralJoin/failed-transfer");
    }
}