// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./dMath.sol";
import "./oracle/libraries/FullMath.sol";

import "./interfaces/VatLike.sol";
import "./interfaces/DavosJoinLike.sol";
import "./interfaces/GemJoinLike.sol";
import "./interfaces/JugLike.sol";
import "./interfaces/DogLike.sol";
import "./interfaces/PipLike.sol";
import "./interfaces/SpotLike.sol";
import "./interfaces/IRewards.sol";
import "./ceros/interfaces/IDavosProvider.sol";
import "./ceros/interfaces/IInteraction.sol";

import "./libraries/AuctionProxy.sol";


uint256 constant WAD = 10 ** 18;
uint256 constant RAD = 10 ** 45;
uint256 constant YEAR = 31556952; //seconds in year (365.2425 * 24 * 3600)

contract Interaction is Initializable, IInteraction {

    mapping(address => uint) public wards;

    function rely(address usr) external auth {wards[usr] = 1;}

    function deny(address usr) external auth {wards[usr] = 0;}
    modifier auth {
        require(wards[msg.sender] == 1, "Interaction/not-authorized");
        _;
    }

    VatLike public vat;
    SpotLike public spotter;
    IERC20Upgradeable public davos;
    DavosJoinLike public davosJoin;
    JugLike public jug;
    address public dog;
    IRewards public dgtRewards;

    mapping(address => uint256) public deposits;
    mapping(address => CollateralType) public collaterals;

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => address) public davosProviders; // e.g. Auction purchase from ceamaticc to amaticc

    uint256 public whitelistMode;
    address public whitelistOperator;
    mapping(address => uint) public whitelist;
    function enableWhitelist() external auth {whitelistMode = 1;}
    function disableWhitelist() external auth {whitelistMode = 0;}
    function setWhitelistOperator(address usr) external auth {
        whitelistOperator = usr;
    }
    function addToWhitelist(address[] memory usrs) external operatorOrWard {
        for(uint256 i = 0; i < usrs.length; i++) {
            whitelist[usrs[i]] = 1;
            emit AddedToWhitelist(usrs[i]);
        }
    }
    function removeFromWhitelist(address[] memory usrs) external operatorOrWard {
        for(uint256 i = 0; i < usrs.length; i++) {
            whitelist[usrs[i]] = 0;
            emit RemovedFromWhitelist(usrs[i]);
        }
    }
    modifier whitelisted(address participant) {
        if (whitelistMode == 1)
            require(whitelist[participant] == 1, "Interaction/not-in-whitelist");
        _;
    }
    modifier operatorOrWard {
        require(msg.sender == whitelistOperator || wards[msg.sender] == 1, "Interaction/not-operator-or-ward"); 
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    function initialize(
        address vat_,
        address spot_,
        address davos_,
        address davosJoin_,
        address jug_,
        address dog_,
        address rewards_
    ) external initializer {

        wards[msg.sender] = 1;

        vat = VatLike(vat_);
        spotter = SpotLike(spot_);
        davos = IERC20Upgradeable(davos_);
        davosJoin = DavosJoinLike(davosJoin_);
        jug = JugLike(jug_);
        dog = dog_;
        dgtRewards = IRewards(rewards_);

        vat.hope(davosJoin_);

        davos.approve(davosJoin_, type(uint256).max);
    }

    function setCores(address vat_, address spot_, address davosJoin_,
        address jug_) public auth {
        // Reset previous approval
        davos.approve(address(davosJoin), 0);

        vat = VatLike(vat_);
        spotter = SpotLike(spot_);
        davosJoin = DavosJoinLike(davosJoin_);
        jug = JugLike(jug_);

        vat.hope(davosJoin_);

        davos.approve(davosJoin_, type(uint256).max);
    }

    function setDavosApprove() public auth {
        davos.approve(address(davosJoin), type(uint256).max);
    }

    function setCollateralType(
        address token,
        address gemJoin,
        bytes32 ilk,
        address clip,
        uint256 mat
    ) external auth {
        require(collaterals[token].live == 0, "Interaction/token-already-init");
        require(ilk != bytes32(0), "Interaction/empty-ilk");
        vat.init(ilk);
        jug.init(ilk);
        spotter.file(ilk, "mat", mat);
        collaterals[token] = CollateralType(GemJoinLike(gemJoin), ilk, 1, clip);
        IERC20Upgradeable(token).safeApprove(gemJoin, type(uint256).max);
        vat.rely(gemJoin);
        emit CollateralEnabled(token, ilk);
    }

    function setCollateralDuty(address token, uint data) external auth {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);
        jug.drip(collateralType.ilk);
        jug.file(collateralType.ilk, "duty", data);
    }

    function reenableCollateral(
        address token,
        address gemJoin,
        bytes32 ilk,
        address clip,
        uint256 mat) external auth {
        collaterals[token].live = 1;
        vat.rely(gemJoin);
        IERC20Upgradeable(token).safeApprove(gemJoin, type(uint256).max);
    }

    function setDavosProvider(address token, address davosProvider) external auth {
        require(davosProvider != address(0));
        davosProviders[token] = davosProvider;
        emit ChangeDavosProvider(davosProvider);
    }

    function removeCollateralType(address token) external auth {
        require(collaterals[token].live != 0, "Interaction/token-not-init");
        collaterals[token].live = 2; //STOPPED
        address gemJoin = address(collaterals[token].gem);
        vat.deny(gemJoin);
        IERC20Upgradeable(token).safeApprove(gemJoin, 0);
        emit CollateralDisabled(token, collaterals[token].ilk);
    }

    function stringToBytes32(string memory source) external pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function deposit(
        address participant,
        address token,
        uint256 dink
    ) external whitelisted(participant) returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        require(collateralType.live == 1, "Interaction/inactive-collateral");

        if (davosProviders[token] != address(0)) {
            require(
                msg.sender == davosProviders[token],
                "Interaction/only davos provider can deposit for this token"
            );
        }
        require(dink <= uint256(type(int256).max), "Interaction/too-much-requested");
        drip(token);
        uint256 preBalance = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), dink);
        uint256 postBalance = IERC20Upgradeable(token).balanceOf(address(this));
        require(preBalance + dink == postBalance, "Interaction/deposit-deflated");

        collateralType.gem.join(participant, dink);
        vat.behalf(participant, address(this));
        vat.frob(collateralType.ilk, participant, participant, participant, int256(dink), 0);

        deposits[token] += dink;

        emit Deposit(participant, token, dink, locked(token, participant));
        return dink;
    }

    function borrow(address token, uint256 davosAmount) external returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        require(collateralType.live == 1, "Interaction/inactive-collateral");
        require(davosAmount > 0,"Interaction/invalid-davosAmount");

        drip(token);
        dropRewards(token, msg.sender);

        (, uint256 rate, , ,) = vat.ilks(collateralType.ilk);
        int256 dart = int256(davosAmount * RAY / rate);
        require(dart >= 0, "Interaction/too-much-requested");
        if (uint256(dart) * rate < davosAmount * RAY) {
            dart += 1; //ceiling
        }
        vat.frob(collateralType.ilk, msg.sender, msg.sender, msg.sender, 0, dart);
        vat.move(msg.sender, address(this), davosAmount * RAY);
        davosJoin.exit(msg.sender, davosAmount);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, msg.sender);
        uint256 liqPrice = liquidationPriceForDebt(collateralType.ilk, ink, art);
        emit Borrow(msg.sender, token, ink, davosAmount, liqPrice);
        return uint256(dart);
    }

    function dropRewards(address token, address usr) public {
        dgtRewards.drop(token, usr);
    }

    // Burn user's DAVOS.
    // N.B. User collateral stays the same.
    function payback(address token, uint256 davosAmount) external returns (int256) {
        require(davosAmount > 0,"Interaction/invalid-davosAmount");
        CollateralType memory collateralType = collaterals[token];
        // _checkIsLive(collateralType.live); Checking in the `drip` function

        (,uint256 rate,,,) = vat.ilks(collateralType.ilk);
        (,uint256 art) = vat.urns(collateralType.ilk, msg.sender);
        int256 dart;
        uint256 realAmount = davosAmount;
        uint256 debt = rate * art;
        if (realAmount * RAY >= debt) { // Close CDP
            dart = int(art);
            realAmount = debt / RAY;
            realAmount = realAmount * RAY == debt ? realAmount : realAmount + 1;
        } else { // Less/Greater than dust
            dart = int256(FullMath.mulDiv(realAmount, RAY, rate));
        }

        IERC20Upgradeable(davos).safeTransferFrom(msg.sender, address(this), realAmount);
        davosJoin.join(msg.sender, realAmount);

        require(dart >= 0, "Interaction/too-much-requested");

        vat.frob(collateralType.ilk, msg.sender, msg.sender, msg.sender, 0, - dart);
        dropRewards(token, msg.sender);

        drip(token);

        (uint256 ink, uint256 userDebt) = vat.urns(collateralType.ilk, msg.sender);
        uint256 liqPrice = liquidationPriceForDebt(collateralType.ilk, ink, userDebt);
        emit Payback(msg.sender, token, realAmount, userDebt, liqPrice);
        return dart;
    }

    // Unlock and transfer to the user `dink` amount of aMATICc
    function withdraw(
        address participant,
        address token,
        uint256 dink
    ) external returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);
        if (davosProviders[token] != address(0)) {
            require(
                msg.sender == davosProviders[token],
                "Interaction/Only davos provider can call this function for this token"
            );
        } else {
            require(
                msg.sender == participant,
                "Interaction/Caller must be the same address as participant"
            );
        }

        uint256 unlocked = free(token, participant);
        if (unlocked < dink) {
            int256 diff = int256(dink) - int256(unlocked);
            vat.frob(collateralType.ilk, participant, participant, participant, - diff, 0);
            vat.flux(collateralType.ilk, participant, address(this), uint256(diff));
        }
        // Collateral is actually transferred back to user inside `exit` operation.
        // See GemJoin.exit()
        collateralType.gem.exit(msg.sender, dink);
        deposits[token] -= dink;

        emit Withdraw(participant, dink);
        return dink;
    }

    function drip(address token) public {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        jug.drip(collateralType.ilk);
    }

    function poke(address token) public {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        spotter.poke(collateralType.ilk);
    }

    function setRewards(address rewards) external auth {
        dgtRewards = IRewards(rewards);
        emit ChangeRewards(rewards);
    }

    //    /////////////////////////////////
    //    //// VIEW                    ////
    //    /////////////////////////////////

    // Price of the collateral asset(aMATICc) from Oracle
    function collateralPrice(address token) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (PipLike pip,) = spotter.ilks(collateralType.ilk);
        (bytes32 price, bool has) = pip.peek();
        if (has) {
            return uint256(price);
        } else {
            return 0;
        }
    }

    // Returns the DAVOS price in $
    function davosPrice(address token) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (, uint256 rate,,,) = vat.ilks(collateralType.ilk);
        return rate / 10 ** 9;
    }

    // Returns the collateral ratio in percents with 18 decimals
    function collateralRate(address token) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (,uint256 mat) = spotter.ilks(collateralType.ilk);
        require(mat != 0, "Interaction/spot-not-init");
        return 10 ** 45 / mat;
    }

    // Total aMATICc deposited nominated in $
    function depositTVL(address token) external view returns (uint256) {
        return deposits[token] * collateralPrice(token) / WAD;
    }

    // Total DAVOS borrowed by all users
    function collateralTVL(address token) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 Art, uint256 rate,,,) = vat.ilks(collateralType.ilk);
        return FullMath.mulDiv(Art, rate, RAY);
    }

    // Not locked user balance in aMATICc
    function free(address token, address usr) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        return vat.gem(collateralType.ilk, usr);
    }

    // User collateral in aMATICc
    function locked(address token, address usr) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink,) = vat.urns(collateralType.ilk, usr);
        return ink;
    }

    // Total borrowed DAVOS
    function borrowed(address token, address usr) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (,uint256 rate,,,) = vat.ilks(collateralType.ilk);
        (, uint256 art) = vat.urns(collateralType.ilk, usr);
        
        // 100 Wei is added as a ceiling to help close CDP in repay()
        if ((art * rate) / RAY != 0) {
            return ((art * rate) / RAY) + 100;
        }
        else {
            return 0;
        }
    }

    // Collateral minus borrowed. Basically free collateral (nominated in DAVOS)
    function availableToBorrow(address token, address usr) external view returns (int256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        (, uint256 rate, uint256 spot,,) = vat.ilks(collateralType.ilk);
        uint256 collateral = ink * spot;
        uint256 debt = rate * art;
        return (int256(collateral) - int256(debt)) / 1e27;
    }

    // Collateral + `amount` minus borrowed. Basically free collateral (nominated in DAVOS)
    // Returns how much davos you can borrow if provide additional `amount` of collateral
    function willBorrow(address token, address usr, int256 amount) external view returns (int256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        (, uint256 rate, uint256 spot,,) = vat.ilks(collateralType.ilk);
        require(amount >= - (int256(ink)), "Cannot withdraw more than current amount");
        if (amount < 0) {
            ink = uint256(int256(ink) + amount);
        } else {
            ink += uint256(amount);
        }
        uint256 collateral = ink * spot;
        uint256 debt = rate * art;
        return (int256(collateral) - int256(debt)) / 1e27;
    }

    function liquidationPriceForDebt(bytes32 ilk, uint256 ink, uint256 art) internal view returns (uint256) {
        if (ink == 0) {
            return 0; // no meaningful price if user has no debt
        }
        (, uint256 rate,,,) = vat.ilks(ilk);
        (,uint256 mat) = spotter.ilks(ilk);
        uint256 backedDebt = (art * rate / 10 ** 36) * mat;
        return backedDebt / ink;
    }

    // Price of aMATICc when user will be liquidated
    function currentLiquidationPrice(address token, address usr) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        return liquidationPriceForDebt(collateralType.ilk, ink, art);
    }

    // Price of aMATICc when user will be liquidated with additional amount of aMATICc deposited/withdraw
    function estimatedLiquidationPrice(address token, address usr, int256 amount) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        require(amount >= - (int256(ink)), "Cannot withdraw more than current amount");
        if (amount < 0) {
            ink = uint256(int256(ink) + amount);
        } else {
            ink += uint256(amount);
        }
        return liquidationPriceForDebt(collateralType.ilk, ink, art);
    }

    // Price of aMATICc when user will be liquidated with additional amount of DAVOS borrowed/payback
    //positive amount mean DAVOSs are being borrowed. So art(debt) will increase
    function estimatedLiquidationPriceDAVOS(address token, address usr, int256 amount) external view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 ink, uint256 art) = vat.urns(collateralType.ilk, usr);
        require(amount >= - (int256(art)), "Cannot withdraw more than current amount");
        (, uint256 rate,,,) = vat.ilks(collateralType.ilk);
        (,uint256 mat) = spotter.ilks(collateralType.ilk);
        uint256 backedDebt = FullMath.mulDiv(art, rate, 10 ** 36);
        if (amount < 0) {
            backedDebt = uint256(int256(backedDebt) + amount);
        } else {
            backedDebt += uint256(amount);
        }
        return FullMath.mulDiv(backedDebt, mat, ink) / 10 ** 9;
    }

    // Returns borrow APR with 20 decimals.
    // I.e. 10% == 10 ethers
    function borrowApr(address token) public view returns (uint256) {
        CollateralType memory collateralType = collaterals[token];
        _checkIsLive(collateralType.live);

        (uint256 duty,) = jug.ilks(collateralType.ilk);
        uint256 principal = dMath.rpow((jug.base() + duty), YEAR, RAY);
        return (principal - RAY) / (10 ** 7);
    }

    function startAuction(
        address token,
        address user,
        address keeper
    ) external returns (uint256) {
        dropRewards(token, user);
        CollateralType memory collateral = collaterals[token];
        (uint256 ink,) = vat.urns(collateral.ilk, user);
        IDavosProvider provider = IDavosProvider(davosProviders[token]);
        uint256 auctionAmount = AuctionProxy.startAuction(
            user,
            keeper,
            davos,
            davosJoin,
            vat,
            DogLike(dog),
            provider,
            collateral
        );

        emit AuctionStarted(token, user, ink, collateralPrice(token));
        return auctionAmount;
    }

    function buyFromAuction(
        address token,
        uint256 auctionId,
        uint256 collateralAmount,
        uint256 maxPrice,
        address receiverAddress
    ) external {
        CollateralType memory collateral = collaterals[token];
        IDavosProvider davosProvider = IDavosProvider(davosProviders[token]);
        uint256 leftover = AuctionProxy.buyFromAuction(
            auctionId,
            collateralAmount,
            maxPrice,
            receiverAddress,
            davos,
            davosJoin,
            vat,
            davosProvider,
            collateral
        );

        address urn = ClipperLike(collateral.clip).sales(auctionId).usr; // Liquidated address
        dropRewards(address(davos), urn);

        emit Liquidation(urn, token, collateralAmount, leftover);
    }

    function getAuctionStatus(address token, uint256 auctionId) external view returns(bool, uint256, uint256, uint256) {
        return ClipperLike(collaterals[token].clip).getStatus(auctionId);
    }

    function upchostClipper(address token) external {
        ClipperLike(collaterals[token].clip).upchost();
    }

    function getAllActiveAuctionsForToken(address token) external view returns (Sale[] memory sales) {
        return AuctionProxy.getAllActiveAuctionsForClip(ClipperLike(collaterals[token].clip));
    }

    function resetAuction(address token, uint256 auctionId, address keeper) external {
        AuctionProxy.resetAuction(auctionId, keeper, davos, davosJoin, vat, collaterals[token]);
    }

    function totalPegLiquidity() external view returns (uint256) {
        return IERC20Upgradeable(davos).totalSupply();
    }

    function _checkIsLive(uint256 live) internal pure {
        require(live != 0, "Interaction/inactive collateral");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// abaci.sol -- price decrease functions for auctions

// Copyright (C) 2020-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.


pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface Abacus {
    // 1st arg: initial price               [ray]
    // 2nd arg: seconds since auction start [seconds]
    // returns: current auction price       [ray]
    function price(uint256, uint256) external view returns (uint256);
}

contract LinearDecrease is Initializable, Abacus {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "LinearDecrease/not-authorized");
        _;
    }

    // --- Data ---
    uint256 public tau;  // Seconds after auction start when the price reaches zero [seconds]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize() external initializer {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if (what ==  "tau") tau = data;
        else revert("LinearDecrease/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x);
        }
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
            require(y == 0 || z / y == x);
            z = z / RAY;
        }
    }

    // Price calculation when price is decreased linearly in proportion to time:
    // tau: The number of seconds after the start of the auction where the price will hit 0
    // top: Initial price
    // dur: current seconds since the start of the auction
    //
    // Returns y = top * ((tau - dur) / tau)
    //
    // Note the internal call to mul multiples by RAY, thereby ensuring that the rmul calculation
    // which utilizes top and tau (RAY values) is also a RAY value.
    function price(uint256 top, uint256 dur) override external view returns (uint256) {
        if (dur >= tau) return 0;
        return rmul(top, mul(tau - dur, RAY) / tau);
    }
}

contract StairstepExponentialDecrease is Initializable, Abacus {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "StairstepExponentialDecrease/not-authorized");
        _;
    }

    // --- Data ---
    uint256 public step; // Length of time between price drops [seconds]
    uint256 public cut;  // Per-step multiplicative factor     [ray]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);

    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    // @notice: `cut` and `step` values must be correctly set for
    //     this contract to return a valid price
    function initialize() external initializer {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if      (what ==  "cut") require((cut = data) <= RAY, "StairstepExponentialDecrease/cut-gt-RAY");
        else if (what == "step") step = data;
        else revert("StairstepExponentialDecrease/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
            require(y == 0 || z / y == x);
            z = z / RAY;
        }
    }
    // optimized version from dss PR #78
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch n case 0 { z := b }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := b } default { z := x }
                    let half := div(b, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, b)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    // top: initial price
    // dur: seconds since the auction has started
    // step: seconds between a price drop
    // cut: cut encodes the percentage to decrease per step.
    //   For efficiency, the values is set as (1 - (% value / 100)) * RAY
    //   So, for a 1% decrease per step, cut would be (1 - 0.01) * RAY
    //
    // returns: top * (cut ^ dur)
    //
    //
    function price(uint256 top, uint256 dur) override external view returns (uint256) {
        return rmul(top, rpow(cut, dur / step, RAY));
    }
}

// While an equivalent function can be obtained by setting step = 1 in StairstepExponentialDecrease,
// this continous (i.e. per-second) exponential decrease has be implemented as it is more gas-efficient
// than using the stairstep version with step = 1 (primarily due to 1 fewer SLOAD per price calculation).
contract ExponentialDecrease is Initializable, Abacus {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "ExponentialDecrease/not-authorized");
        _;
    }

    // --- Data ---
    uint256 public cut;  // Per-second multiplicative factor [ray]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);

    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    // @notice: `cut` value must be correctly set for
    //     this contract to return a valid price
    function initialize() external initializer {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if      (what ==  "cut") require((cut = data) <= RAY, "ExponentialDecrease/cut-gt-RAY");
        else revert("ExponentialDecrease/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Math ---
    uint256 constant RAY = 10 ** 27;
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
            require(y == 0 || z / y == x);
            z = z / RAY;
        }
    }
    // optimized version from dss PR #78
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch n case 0 { z := b }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := b } default { z := x }
                    let half := div(b, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, b)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }

    // top: initial price
    // dur: seconds since the auction has started
    // cut: cut encodes the percentage to decrease per second.
    //   For efficiency, the values is set as (1 - (% value / 100)) * RAY
    //   So, for a 1% decrease per second, cut would be (1 - 0.01) * RAY
    //
    // returns: top * (cut ^ dur)
    //
    function price(uint256 top, uint256 dur) override external view returns (uint256) {
        return rmul(top, rpow(cut, dur, RAY));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// clip.sol -- Davos auction module 2.0

// Copyright (C) 2020-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.


pragma solidity ^0.8.10;

import "./interfaces/ClipperLike.sol";
import "./interfaces/VatLike.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/SpotLike.sol";
import "./interfaces/DogLike.sol";
import { Abacus } from "./abaci.sol";

interface ClipperCallee {
    function clipperCall(address, uint256, uint256, bytes calldata) external;
}

contract Clipper is Initializable, ClipperLike {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Clipper/not-authorized");
        _;
    }

    // --- Data ---
    bytes32 public ilk;   // Collateral type of this Clipper
    VatLike public vat;   // Core CDP Engine

    DogLike     public dog;      // Liquidation module
    address     public vow;      // Recipient of davos raised in auctions
    SpotLike public spotter;  // Collateral price module
    Abacus  public calc;     // Current price calculator

    uint256 public buf;    // Multiplicative factor to increase starting price                  [ray]
    uint256 public tail;   // Time elapsed before auction reset                                 [seconds]
    uint256 public cusp;   // Percentage drop before auction reset                              [ray]
    uint64  public chip;   // Percentage of tab to suck from vow to incentivize keepers         [wad]
    uint192 public tip;    // Flat fee to suck from vow to incentivize keepers                  [rad]
    uint256 public chost;  // Cache the ilk dust times the ilk chop to prevent excessive SLOADs [rad]

    uint256   public kicks;   // Total auctions
    uint256[] public active;  // Array of active auction ids

    mapping(uint256 => Sale) private _sales;

    uint256 internal locked;

    // Levels for circuit breaker
    // 0: no breaker
    // 1: no new kick()
    // 2: no new kick() or redo()
    // 3: no new kick(), redo(), or take()
    uint256 public stopped;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    event Kick(
        uint256 indexed id,
        uint256 top,
        uint256 tab,
        uint256 lot,
        address indexed usr,
        address indexed kpr,
        uint256 coin
    );
    event Take(
        uint256 indexed id,
        uint256 max,
        uint256 price,
        uint256 owe,
        uint256 tab,
        uint256 lot,
        address indexed usr
    );
    event Redo(
        uint256 indexed id,
        uint256 top,
        uint256 tab,
        uint256 lot,
        address indexed usr,
        address indexed kpr,
        uint256 coin
    );

    event Yank(uint256 id);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address vat_, address spotter_, address dog_, bytes32 ilk_) external initializer {
        vat     = VatLike(vat_);
        spotter = SpotLike(spotter_);
        dog     = DogLike(dog_);
        ilk     = ilk_;
        buf     = RAY;
        wards[msg.sender] = 1;
        stopped = 0;
        emit Rely(msg.sender);
    }

    // --- Synchronization ---
    modifier lock {
        require(locked == 0, "Clipper/system-locked");
        locked = 1;
        _;
        locked = 0;
    }

    modifier isStopped(uint256 level) {
        require(stopped < level, "Clipper/stopped-incorrect");
        _;
    }

    function sales(uint256 id) override external view returns (Sale memory) {
        return _sales[id];
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth lock {
        if      (what == "buf")         buf = data;
        else if (what == "tail")       tail = data;           // Time elapsed before auction reset
        else if (what == "cusp")       cusp = data;           // Percentage drop before auction reset
        else if (what == "chip")       chip = uint64(data);   // Percentage of tab to incentivize (max: 2^64 - 1 => 18.xxx WAD = 18xx%)
        else if (what == "tip")         tip = uint192(data);  // Flat fee to incentivize keepers (max: 2^192 - 1 => 6.277T RAD)
        else if (what == "stopped") stopped = data;           // Set breaker (0, 1, 2, or 3)
        else revert("Clipper/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth lock {
        if (what == "spotter") spotter = SpotLike(data);
        else if (what == "dog")    dog = DogLike(data);
        else if (what == "vow")    vow = data;
        else if (what == "calc")  calc = Abacus(data);
        else revert("Clipper/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Math ---
    uint256 constant BLN = 10 **  9;
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x);
        }
    }
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = mul(x, y) / WAD;
        }
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = mul(x, y) / RAY;
        }
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = mul(x, RAY) / y;
        }
    }

    // --- Auction ---

    // get the price directly from the OSM
    // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but
    // if mat has changed since the last poke, the resulting value will be
    // incorrect.
    function getFeedPrice() internal returns (uint256 feedPrice) {
        (PipLike pip, ) = spotter.ilks(ilk);
        (bytes32 val, bool has) = pip.peek();
        require(has, "Clipper/invalid-price");
        feedPrice = rdiv(mul(uint256(val), BLN), spotter.par());
    }

    // start an auction
    // note: trusts the caller to transfer collateral to the contract
    // The starting price `top` is obtained as follows:
    //
    //     top = val * buf / par
    //
    // Where `val` is the collateral's unitary value in USD, `buf` is a
    // multiplicative factor to increase the starting price, and `par` is a
    // reference per DAVOS.
    function kick(
        uint256 tab,  // Debt                   [rad]
        uint256 lot,  // Collateral             [wad]
        address usr,  // Address that will receive any leftover collateral
        address kpr   // Address that will receive incentives
    ) external auth lock isStopped(1) returns (uint256 id) {
        // Input validation
        require(tab  >          0, "Clipper/zero-tab");
        require(lot  >          0, "Clipper/zero-lot");
        require(usr != address(0), "Clipper/zero-usr");
        id = ++kicks;
        require(id   >          0, "Clipper/overflow");

        active.push(id);

        _sales[id].pos = active.length - 1;

        _sales[id].tab = tab;
        _sales[id].lot = lot;
        _sales[id].usr = usr;
        _sales[id].tic = uint96(block.timestamp);

        uint256 top;
        top = rmul(getFeedPrice(), buf);
        require(top > 0, "Clipper/zero-top-price");
        _sales[id].top = top;

        // incentive to kick auction
        uint256 _tip  = tip;
        uint256 _chip = chip;
        uint256 coin;
        if (_tip > 0 || _chip > 0) {
            coin = add(_tip, wmul(tab, _chip));
            vat.suck(vow, kpr, coin);
        }

        emit Kick(id, top, tab, lot, usr, kpr, coin);
    }

    // Reset an auction
    // See `kick` above for an explanation of the computation of `top`.
    function redo(
        uint256 id,  // id of the auction to reset
        address kpr  // Address that will receive incentives
    ) external auth lock isStopped(2) {
        // Read auction data
        address usr = _sales[id].usr;
        uint96  tic = _sales[id].tic;
        uint256 top = _sales[id].top;

        require(usr != address(0), "Clipper/not-running-auction");

        // Check that auction needs reset
        // and compute current price [ray]
        (bool done,) = status(tic, top);
        require(done, "Clipper/cannot-reset");

        uint256 tab   = _sales[id].tab;
        uint256 lot   = _sales[id].lot;
        _sales[id].tic = uint96(block.timestamp);

        uint256 feedPrice = getFeedPrice();
        top = rmul(feedPrice, buf);
        require(top > 0, "Clipper/zero-top-price");
        _sales[id].top = top;

        // incentive to redo auction
        uint256 _tip  = tip;
        uint256 _chip = chip;
        uint256 coin;
        if (_tip > 0 || _chip > 0) {
            uint256 _chost = chost;
            if (tab >= _chost && mul(lot, feedPrice) >= _chost) {
                coin = add(_tip, wmul(tab, _chip));
                vat.suck(vow, kpr, coin);
            }
        }

        emit Redo(id, top, tab, lot, usr, kpr, coin);
    }

    // Buy up to `amt` of collateral from the auction indexed by `id`.
    // 
    // Auctions will not collect more DAVOS than their assigned DAVOS target,`tab`;
    // thus, if `amt` would cost more DAVOS than `tab` at the current price, the
    // amount of collateral purchased will instead be just enough to collect `tab` DAVOS.
    //
    // To avoid partial purchases resulting in very small leftover auctions that will
    // never be cleared, any partial purchase must leave at least `Clipper.chost`
    // remaining DAVOS target. `chost` is an asynchronously updated value equal to
    // (Vat.dust * Dog.chop(ilk) / WAD) where the values are understood to be determined
    // by whatever they were when Clipper.upchost() was last called. Purchase amounts
    // will be minimally decreased when necessary to respect this limit; i.e., if the
    // specified `amt` would leave `tab < chost` but `tab > 0`, the amount actually
    // purchased will be such that `tab == chost`.
    //
    // If `tab <= chost`, partial purchases are no longer possible; that is, the remaining
    // collateral can only be purchased entirely, or not at all.
    function take(
        uint256 id,           // Auction id
        uint256 amt,          // Upper limit on amount of collateral to buy  [wad]
        uint256 max,          // Maximum acceptable price (DAVOS / collateral) [ray]
        address who,          // Receiver of collateral and external call address
        bytes calldata data   // Data to pass in external call; if length 0, no call is done
    ) external auth lock isStopped(3) {

        address usr = _sales[id].usr;
        uint96  tic = _sales[id].tic;

        require(usr != address(0), "Clipper/not-running-auction");

        uint256 price;
        {
            bool done;
            (done, price) = status(tic, _sales[id].top);

            // Check that auction doesn't need reset
            require(!done, "Clipper/needs-reset");
        }

        // Ensure price is acceptable to buyer
        require(max >= price, "Clipper/too-expensive");

        uint256 lot = _sales[id].lot;
        uint256 tab = _sales[id].tab;
        uint256 owe;

        {
            // Purchase as much as possible, up to amt
            uint256 slice = min(lot, amt);  // slice <= lot

            // DAVOS needed to buy a slice of this sale
            owe = mul(slice, price);

            // Don't collect more than tab of DAVOS
            if (owe > tab) {
                // Total debt will be paid
                owe = tab;                  // owe' <= owe
                // Adjust slice
                slice = owe / price;        // slice' = owe' / price <= owe / price == slice <= lot
            } else if (owe < tab && slice < lot) {
                // If slice == lot => auction completed => dust doesn't matter
                uint256 _chost = chost;
                if (tab - owe < _chost) {    // safe as owe < tab
                    // If tab <= chost, buyers have to take the entire lot.
                    require(tab > _chost, "Clipper/no-partial-purchase");
                    // Adjust amount to pay
                    owe = tab - _chost;      // owe' <= owe
                    // Adjust slice
                    slice = owe / price;     // slice' = owe' / price < owe / price == slice < lot
                }
            }

            // Calculate remaining tab after operation
            tab = tab - owe;  // safe since owe <= tab
            // Calculate remaining lot after operation
            lot = lot - slice;

            // Send collateral to who
            vat.flux(ilk, address(this), who, slice);

            // Do external call (if data is defined) but to be
            // extremely careful we don't allow to do it to the two
            // contracts which the Clipper needs to be authorized
            DogLike dog_ = dog;
            if (data.length > 0 && who != address(vat) && who != address(dog_)) {
                ClipperCallee(who).clipperCall(msg.sender, owe, slice, data);
            }

            // Get DAVOS from caller
            vat.move(msg.sender, vow, owe);

            // Removes DAVOS out for liquidation from accumulator
            dog_.digs(ilk, lot == 0 ? tab + owe : owe);
        }

        if (lot == 0) {
            _remove(id);
        } else if (tab == 0) {
            vat.flux(ilk, address(this), usr, lot);
            _remove(id);
        } else {
            _sales[id].tab = tab;
            _sales[id].lot = lot;
        }

        emit Take(id, max, price, owe, tab, lot, usr);
    }

    function _remove(uint256 id) internal {
        uint256 _move    = active[active.length - 1];
        if (id != _move) {
            uint256 _index   = _sales[id].pos;
            active[_index]   = _move;
            _sales[_move].pos = _index;
        }
        active.pop();
        delete _sales[id];
    }

    // The number of active auctions
    function count() external view returns (uint256) {
        return active.length;
    }

    // Return the entire array of active auctions
    function list() external view returns (uint256[] memory) {
        return active;
    }

    // Externally returns boolean for if an auction needs a redo and also the current price
    function getStatus(uint256 id) external view returns (bool needsRedo, uint256 price, uint256 lot, uint256 tab) {
        // Read auction data
        address usr = _sales[id].usr;
        uint96  tic = _sales[id].tic;

        bool done;
        (done, price) = status(tic, _sales[id].top);

        needsRedo = usr != address(0) && done;
        lot = _sales[id].lot;
        tab = _sales[id].tab;
    }

    // Internally returns boolean for if an auction needs a redo
    function status(uint96 tic, uint256 top) internal view returns (bool done, uint256 price) {
        price = calc.price(top, sub(block.timestamp, tic));
        done  = (sub(block.timestamp, tic) > tail || rdiv(price, top) < cusp);
    }

    // Public function to update the cached dust*chop value.
    function upchost() external {
        (,,,, uint256 _dust) = VatLike(vat).ilks(ilk);
        chost = wmul(_dust, dog.chop(ilk));
    }

    // Cancel an auction during ES or via governance action.
    function yank(uint256 id) external auth lock {
        require(_sales[id].usr != address(0), "Clipper/not-running-auction");
        dog.digs(ilk, _sales[id].tab);
        vat.flux(ilk, address(this), msg.sender, _sales[id].lot);
        _remove(id);
        emit Yank(id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct Sale {
    uint256 pos; // Index in active array
    uint256 tab; // Davos to raise       [rad]
    uint256 lot; // collateral to sell [wad]
    address usr; // Liquidated CDP
    uint96 tic; // Auction start time
    uint256 top; // Starting price     [ray]
}

interface ClipperLike {
    function ilk() external view returns (bytes32);

    function kick(
        uint256 tab,
        uint256 lot,
        address usr,
        address kpr
    ) external returns (uint256);

    function take(
        uint256 id,
        uint256 amt,
        uint256 max,
        address who,
        bytes calldata data
    ) external;

    function redo(uint256 id, address kpr) external;

    function upchost() external;

    function getStatus(uint256 id) external view returns (bool, uint256, uint256, uint256);

    function kicks() external view returns (uint256);

    function count() external view returns (uint256);

    function list() external view returns (uint256[] memory);

    function sales(uint256 auctionId) external view returns (Sale memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface VatLike {
    function init(bytes32 ilk) external;

    function hope(address usr) external;

    function nope(address usr) external;

    function rely(address usr) external;

    function deny(address usr) external;

    function move(address src, address dst, uint256 rad) external;

    function behalf(address bit, address usr) external;

    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external;

    function flux(bytes32 ilk, address src, address dst, uint256 wad) external;

    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);

    function fold(bytes32 i, address u, int rate) external;

    function gem(bytes32, address) external view returns (uint256);

    function davos(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function file(bytes32, bytes32, uint) external;

    function sin(address) external view returns (uint256);

    function heal(uint rad) external;

    function suck(address u, address v, uint rad) external;

    function grab(bytes32,address,address,address,int256,int256) external;

    function slip(bytes32,address,int) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./PipLike.sol";

interface SpotLike {
    function ilks(bytes32) external view returns (PipLike, uint256);

    function poke(bytes32) external;

    function file(bytes32 ilk, bytes32 what, uint data) external;

    function par() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface DogLike {

       // --- Administration ---
    function file(bytes32 what, address data) external;
    function file(bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, uint256 data) external;
    function file(bytes32 ilk, bytes32 what, address clip) external;

    function chop(bytes32 ilk) external view returns (uint256);

    // --- CDP Liquidation: all bark and no bite ---
    //
    // Liquidate a Vault and start a Dutch auction to sell its collateral for DAVOS.
    //
    // The third argument is the address that will receive the liquidation reward, if any.
    //
    // The entire Vault will be liquidated except when the target amount of DAVOS to be raised in
    // the resulting auction (debt of Vault + liquidation penalty) causes either Dirt to exceed
    // Hole or ilk.dirt to exceed ilk.hole by an economically significant amount. In that
    // case, a partial liquidation is performed to respect the global and per-ilk limits on
    // outstanding DAVOS target. The one exception is if the resulting auction would likely
    // have too little collateral to be interesting to Keepers (debt taken from Vault < ilk.dust),
    // in which case the function reverts. Please refer to the code and comments within if
    // more detail is desired.
    function bark(bytes32 ilk, address urn, address kpr) external returns (uint256 id);

    function digs(bytes32 ilk, uint256 rad) external;

    function cage() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface PipLike {
    function peek() external view returns (bytes32, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./DavosJoinLike.sol";
import "./VatLike.sol";
import "./ClipperLike.sol";
import "./DogLike.sol";
import { CollateralType } from "./../ceros/interfaces/IInteraction.sol";
import "../ceros/interfaces/IDavosProvider.sol";

interface IAuctionProxy {

    function startAuction(
        address token,
        address user,
        address keeper
    ) external returns (uint256 id);

    function buyFromAuction(
        address user,
        uint256 auctionId,
        uint256 collateralAmount,
        uint256 maxPrice,
        address receiverAddress
    ) external;

    function getAllActiveAuctionsForToken(address token) external view returns (Sale[] memory sales);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface DavosJoinLike {
    function join(address usr, uint256 wad) external;

    function exit(address usr, uint256 wad) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "../../interfaces/GemJoinLike.sol";

struct CollateralType {
    GemJoinLike gem;
    bytes32 ilk;
    uint32 live; //0 - inactive, 1 - started, 2 - stopped
    address clip;
}

interface IInteraction {

    event Deposit(address indexed user, address collateral, uint256 amount, uint256 totalAmount);
    event Borrow(address indexed user, address collateral, uint256 collateralAmount, uint256 amount, uint256 liquidationPrice);
    event Payback(address indexed user, address collateral, uint256 amount, uint256 debt, uint256 liquidationPrice);
    event Withdraw(address indexed user, uint256 amount);
    event CollateralEnabled(address token, bytes32 ilk);
    event CollateralDisabled(address token, bytes32 ilk);
    event AuctionStarted(address indexed token, address user, uint256 amount, uint256 price);
    event AuctionFinished(address indexed token, address keeper,  uint256 amount);
    event Liquidation(address indexed user, address indexed collateral, uint256 amount, uint256 leftover);
    event AddedToWhitelist(address indexed user);
    event RemovedFromWhitelist(address indexed user);
    event ChangeRewards(address rewards);
    event ChangeDavosProvider(address davosProvider);

      function deposit(
        address participant,
        address token,
        uint256 dink
    ) external returns (uint256);

    function withdraw(
        address participant,
        address token,
        uint256 dink
    ) external returns (uint256);

    function dropRewards(address token, address usr) external;
    function buyFromAuction(address token, uint256 auctionId, uint256 collateralAmount, uint256 maxPrice, address receiverAddress) external;
    function collaterals(address) external view returns(GemJoinLike gem, bytes32 ilk, uint32 live, address clip);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IDavosProvider {

    // --- Events ---
    event Deposit(address indexed _account, uint256 _amount);
    event Withdrawal(address indexed _owner, address indexed _recipient, uint256 _amount);
    event CollateralChanged(address _collateral);
    event CollateralDerivativeChanged(address _collateralDerivative);
    event MasterVaultChanged(address _masterVault);
    event InteractionChanged(address _interaction);
    event UnderlyingChanged(address _matic);
    event NativeStatusChanged(bool _isNative);

    // --- Functions ---
    function provide(uint256 _amount) external payable returns (uint256 value);
    function release(address _recipient, uint256 _amount) external returns (uint256 realAmount);
    function liquidation(address _recipient, uint256 _amount) external;
    function daoBurn(address _account, uint256 _value) external;
    function daoMint(address _account, uint256 _value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./GemLike.sol";

interface GemJoinLike {
    function join(address usr, uint256 wad) external;

    function exit(address usr, uint256 wad) external;

    function gem() external view returns (GemLike);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

interface GemLike is IERC20Upgradeable {
    function decimals() external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../interfaces/ClipperLike.sol";
import "../interfaces/GemJoinLike.sol";
import "../interfaces/DavosJoinLike.sol";
import "../interfaces/DogLike.sol";
import "../interfaces/VatLike.sol";
import "../ceros/interfaces/IDavosProvider.sol";
import "../oracle/libraries/FullMath.sol";

import { CollateralType } from  "../ceros/interfaces/IInteraction.sol";

uint256 constant RAY = 10**27;

library AuctionProxy {
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeERC20Upgradeable for GemLike;

  function startAuction(
    address user,
    address keeper,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    DogLike dog,
    IDavosProvider davosProvider,
    CollateralType calldata collateral
  ) public returns (uint256 id) {
    ClipperLike _clip = ClipperLike(collateral.clip);
    _clip.upchost();
    uint256 davosBal = davos.balanceOf(address(this));
    id = dog.bark(collateral.ilk, user, address(this));

    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);
    davosBal = davos.balanceOf(address(this)) - davosBal;
    davos.transfer(keeper, davosBal);

    // Burn any derivative token (dMATIC incase of ceaMATICc collateral)
    if (address(davosProvider) != address(0)) {
      davosProvider.daoBurn(user, _clip.sales(id).lot);
    }
  }

  function resetAuction(
    uint auctionId,
    address keeper,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    CollateralType calldata collateral
  ) public {
    ClipperLike _clip = ClipperLike(collateral.clip);
    uint256 davosBal = davos.balanceOf(address(this));
    _clip.redo(auctionId, keeper);


    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);
    davosBal = davos.balanceOf(address(this)) - davosBal;
    davos.transfer(keeper, davosBal);
  }

  // Returns lefover from auction
  function buyFromAuction(
    uint256 auctionId,
    uint256 collateralAmount,
    uint256 maxPrice,
    address receiverAddress,
    IERC20Upgradeable davos,
    DavosJoinLike davosJoin,
    VatLike vat,
    IDavosProvider davosProvider,
    CollateralType calldata collateral
  ) public returns (uint256 leftover) {
    // Balances before
    uint256 davosBal = davos.balanceOf(address(this));
    uint256 gemBal = collateral.gem.gem().balanceOf(address(this));

    uint256 davosMaxAmount = FullMath.mulDiv(maxPrice, collateralAmount, RAY);

    davos.transferFrom(msg.sender, address(this), davosMaxAmount);
    davosJoin.join(address(this), davosMaxAmount);

    vat.hope(address(collateral.clip));
    address urn = ClipperLike(collateral.clip).sales(auctionId).usr; // Liquidated address

    leftover = vat.gem(collateral.ilk, urn); // userGemBalanceBefore
    ClipperLike(collateral.clip).take(auctionId, collateralAmount, maxPrice, address(this), "");
    leftover = vat.gem(collateral.ilk, urn) - leftover; // leftover

    collateral.gem.exit(address(this), vat.gem(collateral.ilk, address(this)));
    davosJoin.exit(address(this), vat.davos(address(this)) / RAY);

    // Balances rest
    davosBal = davos.balanceOf(address(this)) - davosBal;
    gemBal = collateral.gem.gem().balanceOf(address(this)) - gemBal;
    davos.transfer(receiverAddress, davosBal);

    vat.nope(address(collateral.clip));

    if (address(davosProvider) != address(0)) {
      IERC20Upgradeable(collateral.gem.gem()).safeTransfer(address(davosProvider), gemBal);
      davosProvider.liquidation(receiverAddress, gemBal); // Burn router ceToken and mint amaticc to receiver

      if (leftover != 0) {
        // Auction ended with leftover
        vat.flux(collateral.ilk, urn, address(this), leftover);
        collateral.gem.exit(address(davosProvider), leftover); // Router (disc) gets the remaining ceamaticc
        davosProvider.liquidation(urn, leftover); // Router burns them and gives amaticc remaining
      }
    } else {
      IERC20Upgradeable(collateral.gem.gem()).safeTransfer(receiverAddress, gemBal);
    }
  }

  function getAllActiveAuctionsForClip(ClipperLike clip)
    external
    view
    returns (Sale[] memory sales)
  {
    uint256[] memory auctionIds = clip.list();
    uint256 auctionsCount = auctionIds.length;
    sales = new Sale[](auctionsCount);
    for (uint256 i = 0; i < auctionsCount; i++) {
      sales[i] = clip.sales(auctionIds[i]);
    }
  }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.10;

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
  function fullMul(uint256 x, uint256 y) internal pure returns (uint256 l, uint256 h) {
  unchecked{
    uint256 mm = mulmod(x, y, type(uint256).max);
    l = x * y;
    h = mm - l;
    if (mm < l) h -= 1;
  }
  }

  function fullDiv(
    uint256 l,
    uint256 h,
    uint256 d
  ) private pure returns (uint256) {
  unchecked {
    uint256 pow2 = d & (~d + 1);
    d /= pow2;
    l /= pow2;
    l += h * ((~pow2 + 1) / pow2 + 1);
    uint256 r = 1;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    r *= 2 - d * r;
    return l * r;
  }
  }

  function mulDiv(
    uint256 x,
    uint256 y,
    uint256 d
  ) internal pure returns (uint256) {
    (uint256 l, uint256 h) = fullMul(x, y);

  unchecked {
    uint256 mm = mulmod(x, y, d);
    if (mm > l) h -= 1;
    l -= mm;

    if (h == 0) return l / d;

    require(h < d, "FullMath: FULLDIV_OVERFLOW");
    return fullDiv(l, h, d);
  }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library dMath {

    uint256 constant ONE = 10 ** 27;

    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := b} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := b } default { z := x }
                let half := div(b, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, b)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, b)
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface JugLike {
    function drip(bytes32 ilk) external returns (uint256);

    function ilks(bytes32) external view returns (uint256, uint256);

    function base() external view returns (uint256);

    function init(bytes32 ilk) external;

    function file(bytes32 ilk, bytes32 what, uint data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IRewards {

    /**
     * Events
     */

    event PoolInited(address token, uint256 rate);

    event DgtTokenChanged(address newToken);

    event DgtOracleChanged(address newOracle);

    event RateChanged(address token, uint256 newRate);

    event RewardsLimitChanged(uint256 newLimit);

    event Uncage(address user);

    event Cage(address user);

    event Claimed(address indexed user, uint256 amount);

    /**
     * Methods
     */

    function drop(address token, address usr) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./dMath.sol";
import "./oracle/libraries/FullMath.sol";

import "./interfaces/VatLike.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/PipLike.sol";

/*
   "Distribute Dgt Tokens to Borrowers".
   Borrowers of Davos token against collaterals are incentivized 
   to get Dgt Tokens.
*/

contract DGTRewards is IRewards, Initializable {
    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "Rewards/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { require(live == 1, "Rewards/not-live"); wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1, "Rewards/not-authorized"); _; }

    // --- State Vars/Constants ---
    uint256 constant YEAR = 31556952; //seconds in year (365.2425 * 24 * 3600)
    uint256 constant RAY = 10 ** 27;  

    struct Ilk {
        uint256 rewardRate;  // Collateral, per-second reward rate [ray]
        uint256 rho;         // Pool init time
        bytes32 ilk;
    }
    struct Pile {
        uint256 amount;
        uint256 ts;
    }

    uint256 public live;

    mapping (address => mapping(address => Pile)) public piles;  // usr > collateral > Pile
    mapping (address => uint256) public claimedRewards;
    mapping (address => Ilk) public pools;
    address[] public poolsList;

    VatLike public vat;
    address public dgtToken;
    PipLike public oracle;

    uint256 public rewardsPool;  // <Unused>
    uint256 public poolLimit;
    uint256 public maxPools;

    // --- Modifiers ---
    modifier poolInit(address token) {
        require(pools[token].rho != 0, "Reward/pool-not-init");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address vat_, uint256 poolLimit_, uint256 maxPools_) external initializer {
        live = 1;
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        poolLimit = poolLimit_;
        maxPools = maxPools_;
    }

    // --- Admin ---
    function initPool(address token, bytes32 ilk, uint256 rate) external auth {
        require(IERC20Upgradeable(dgtToken).balanceOf(address(this)) >= poolLimit, "Reward/not-enough-reward-token");
        require(pools[token].rho == 0, "Reward/pool-existed");
        require(token != address(0), "Reward/invalid-token");
        pools[token] = Ilk(rate, block.timestamp, ilk);
        poolsList.push(token);
        require(poolsList.length <= maxPools, "Reward/maxPools-exceeded");

        emit PoolInited(token, rate);
    }
    function setDgtToken(address dgtToken_) external auth {
        require(dgtToken_ != address(0), "Reward/invalid-token");
        dgtToken = dgtToken_;

        emit DgtTokenChanged(dgtToken);
    }
    function setRewardsMaxLimit(uint256 newLimit) external auth {
        require(IERC20Upgradeable(dgtToken).balanceOf(address(this)) >= newLimit, "Reward/not-enough-reward-token");
        poolLimit = newLimit;

        emit RewardsLimitChanged(poolLimit);
    }
    function setOracle(address oracle_) external auth {
        require(oracle_ != address(0), "Reward/invalid-oracle");
        oracle = PipLike(oracle_);

        emit DgtOracleChanged(address(oracle));
    }
    function setRate(address token, uint256 newRate) external auth {
        require(pools[token].rho == 0, "Reward/pool-existed");
        require(token != address(0), "Reward/invalid-token");
        require(newRate >= RAY, "Reward/negative-rate");
        require(newRate < 2 * RAY, "Reward/high-rate");
        Ilk storage pool = pools[token];
        pool.rewardRate = newRate;

        emit RateChanged(token, newRate);
    }
    function setMaxPools(uint256 newMaxPools) external auth {
        require(newMaxPools != 0, "Reward/invalid-maxPool");
        maxPools = newMaxPools;
    }

    // --- View ---
    function dgtPrice() public view returns(uint256) {
        // 1 DAVOS is dgtPrice() dgts
        (bytes32 price, bool has) = oracle.peek();
        if (has) {
            return uint256(price);
        } else {
            return 0;
        }
    }
    function rewardsRate(address token) public view returns(uint256) {
        return pools[token].rewardRate;
    }
    function distributionApy(address token) public view returns(uint256) {
        // Yearly api in percents with 18 decimals
        return (dMath.rpow(pools[token].rewardRate, YEAR, RAY) - RAY) / 10 ** 7;
    }
    function pendingRewards(address usr) public view returns(uint256) {
        uint256 i = 0;
        uint256 acc = 0;
        while (i < poolsList.length) {
            acc += claimable(poolsList[i], usr);
            i++;
        }
        return acc - claimedRewards[usr];
    }
    function claimable(address token, address usr) public poolInit(token) view returns (uint256) {
        return piles[usr][token].amount + unrealisedRewards(token, usr);
    }
    function unrealisedRewards(address token, address usr) public poolInit(token) view returns(uint256) {
        if (pools[token].rho == 0) {
            // No pool for this token
            return 0;
        }
        bytes32 poolIlk = pools[token].ilk;
        (, uint256 art) = vat.urns(poolIlk, usr);
        uint256 last = piles[usr][token].ts;
        if (last == 0) {
            return 0;
        }
        uint256 rate = dMath.rpow(pools[token].rewardRate, block.timestamp - last, RAY);
        uint256 rewards = FullMath.mulDiv(rate, art, 10 ** 27) - art;                     // $ amount
        return FullMath.mulDiv(rewards, dgtPrice(), 10 ** 18);                           // Dgt Tokens
    }

    // --- Externals ---
    function drop(address token, address usr) public {
        if (pools[token].rho == 0) {
            // No pool for this token
            return;
        }
        Pile storage pile = piles[usr][token];

        pile.amount += unrealisedRewards(token, usr);
        pile.ts = block.timestamp;
    }
    function claim(uint256 amount) external {
        require(amount <= pendingRewards(msg.sender), "Rewards/not-enough-rewards");
        require(poolLimit >= amount, "Rewards/rewards-limit-exceeded");
        uint256 i = 0;
        while (i < poolsList.length) {
            drop(poolsList[i], msg.sender);
            i++;
        }
        claimedRewards[msg.sender] += amount;
        poolLimit -= amount;
        
        IERC20Upgradeable(dgtToken).safeTransfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    // --- Locks ---
    function cage() public auth {
        live = 0;
        emit Cage(msg.sender);
    }
    function uncage() public auth {
        live = 1;
        emit Uncage(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/PipLike.sol";

contract DGTOracle is PipLike, OwnableUpgradeable  {

    event PriceChanged(uint256 newPrice);

    uint256 private price;

    // --- Init ---
    function initialize(uint256 _initialPrice) external initializer {

        __Ownable_init();

        price = _initialPrice;
    }

    /**
     * Returns the latest price
     */
    function peek() public view returns (bytes32, bool) {

        return (bytes32(price), true);
    }

    function changePriceToken(uint256 _price) external onlyOwner {

        price = _price;
        emit PriceChanged(price);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { EnumerableSetUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { ILP } from "./interfaces/ILP.sol";
import { ISwapPool } from "../ceros/interfaces/ISwapPool.sol";
import { IMaticPool } from "./interfaces/IMaticPool.sol";
import { ICerosToken } from "./interfaces/ICerosToken.sol";
import { INativeERC20 } from "./interfaces/INativeERC20.sol";

enum UserType {
  MANAGER,
  LIQUIDITY_PROVIDER,
  INTEGRATOR
}

enum FeeType {
  OWNER,
  MANAGER,
  INTEGRATOR,
  STAKE,
  UNSTAKE
}

struct FeeAmounts {
  uint128 nativeFee;
  uint128 cerosFee;
}

// solhint-disable max-states-count
contract SwapPool is
  ISwapPool,
  OwnableUpgradeable,
  PausableUpgradeable,
  ReentrancyGuardUpgradeable
{
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event UserTypeChanged(address indexed user, UserType indexed utype, bool indexed added);
  event FeeChanged(FeeType indexed utype, uint24 oldFee, uint24 newFee);
  event IntegratorLockEnabled(bool indexed enabled);
  event ProviderLockEnabled(bool indexed enabled);
  event ExcludedFromFee(address indexed user, bool indexed excluded);
  event LiquidityChange(
    address indexed user,
    uint256 nativeAmount,
    uint256 stakingAmount,
    uint256 nativeReserve,
    uint256 stakingReserve,
    bool indexed added
  );
  event Swap(
    address indexed sender,
    address indexed receiver,
    bool indexed nativeToCeros,
    uint256 amountIn,
    uint256 amountOut
  );
  event ThresholdChanged(uint256 newThreshold);
  event MaticPoolChanged(address newMaticPool);

  uint24 public constant FEE_MAX = 100000;

  EnumerableSetUpgradeable.AddressSet internal managers_;
  EnumerableSetUpgradeable.AddressSet internal integrators_;
  EnumerableSetUpgradeable.AddressSet internal liquidityProviders_;

  address public nativeToken;
  address public cerosToken;
  address public lpToken;

  uint256 public nativeTokenAmount;
  uint256 public cerosTokenAmount;

  uint24 public ownerFee;
  uint24 public managerFee;
  uint24 public integratorFee;
  uint24 public stakeFee;
  uint24 public unstakeFee;
  uint24 public threshold;

  bool public integratorLockEnabled;
  bool public providerLockEnabled;

  FeeAmounts public ownerFeeCollected;

  FeeAmounts public managerFeeCollected;
  FeeAmounts internal _accFeePerManager;
  FeeAmounts internal _alreadyUpdatedFees;
  FeeAmounts internal _claimedManagerFees;

  mapping(address => FeeAmounts) public managerRewardDebt;
  mapping(address => bool) public excludedFromFee;

  IMaticPool public maticPool;

  modifier onlyOwnerOrManager() {
    require(
      msg.sender == owner() || managers_.contains(msg.sender),
      "only owner or manager can call this function"
    );
    _;
  }

  modifier onlyManager() {
    require(managers_.contains(msg.sender), "only manager can call this function");
    _;
  }

  modifier onlyIntegrator() {
    if (integratorLockEnabled) {
      require(integrators_.contains(msg.sender), "only integrators can call this function");
    }
    _;
  }

  modifier onlyProvider() {
    if (providerLockEnabled) {
      require(
        liquidityProviders_.contains(msg.sender),
        "only liquidity providers can call this function"
      );
    }
    _;
  }

  function initialize(
    address _nativeToken,
    address _cerosToken,
    address _lpToken,
    bool _integratorLockEnabled,
    bool _providerLockEnabled
  ) public initializer {
    __Ownable_init();
    __Pausable_init();
    __ReentrancyGuard_init();
    nativeToken = _nativeToken;
    cerosToken = _cerosToken;
    lpToken = _lpToken;
    integratorLockEnabled = _integratorLockEnabled;
    providerLockEnabled = _providerLockEnabled;
  }

  /**
   * @notice adds liquidity to the pool with native coin. See - {_addLiquidity}
   */
  function addLiquidityEth(uint256 amount1) external payable virtual onlyProvider nonReentrant {
    _addLiquidity(msg.value, amount1, true);
  }

  /**
   * @notice adds liquidity to the pool. See - {_addLiquidity}
   */
  function addLiquidity(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyProvider
    nonReentrant
  {
    _addLiquidity(amount0, amount1, false);
  }

  /**
   * @notice adds liquidity of nativeToken and cerosToken by 50/50
   * @param amount0 - the amount of nativeToken
   * @param amount1 - the amount of cerosToken
   * @param useEth - if 'true', then it will get nativeToken as native else it will get ERC20 wrapped token
   */
  function _addLiquidity(
    uint256 amount0,
    uint256 amount1,
    bool useEth
  ) internal virtual {
    uint256 ratio = ICerosToken(cerosToken).ratio();
    uint256 value = (amount0 * ratio) / 1e18;
    if (amount1 < value) {
      amount0 = (amount1 * 1e18) / ratio;
    } else {
      amount1 = value;
    }
    if (useEth) {
      INativeERC20(nativeToken).deposit{ value: amount0 }();
      uint256 diff = msg.value - amount0;
      if (diff != 0) {
        _sendValue(msg.sender, diff);
      }
    } else {
      IERC20Upgradeable(nativeToken).safeTransferFrom(msg.sender, address(this), amount0);
    }
    IERC20Upgradeable(cerosToken).safeTransferFrom(msg.sender, address(this), amount1);
    if (nativeTokenAmount == 0 && cerosTokenAmount == 0) {
      require(amount0 > 1e18, "cannot add first time less than 1 token");
      nativeTokenAmount = amount0;
      cerosTokenAmount = amount1;

      ILP(lpToken).mint(msg.sender, (2 * amount0) / 10**8);
    } else {
      uint256 allInNative = nativeTokenAmount + (cerosTokenAmount * 1e18) / ratio;
      uint256 mintAmount = (2 * amount0 * ILP(lpToken).totalSupply()) / allInNative;
      nativeTokenAmount += amount0;
      cerosTokenAmount += amount1;

      ILP(lpToken).mint(msg.sender, mintAmount);
    }
    emit LiquidityChange(msg.sender, amount0, amount1, nativeTokenAmount, cerosTokenAmount, true);
  }

  /**
   * @notice removes liquidity from pool by lp amount. See - {_removeliquidityLp}
   */
  function removeLiquidity(uint256 lpAmount) external virtual nonReentrant {
    _removeLiquidityLp(lpAmount, false);
  }

  /**
   * @notice removes liquidity from pool by lp amount. See - {_removeliquidityLp}
   */
  function removeLiquidityEth(uint256 lpAmount) external virtual nonReentrant {
    _removeLiquidityLp(lpAmount, true);
  }

  /**
   * @notice removes liquidity from pool by percent. See - {_removeliquidityPercent}
   */
  function removeLiquidityPercent(uint256 percent) external virtual nonReentrant {
    _removeLiquidityPercent(percent, false);
  }

  /**
   * @notice removes liquidity from pool by percent. See - {_removeliquidityPercent}
   */
  function removeLiquidityPercentEth(uint256 percent) external virtual nonReentrant {
    _removeLiquidityPercent(percent, true);
  }

  /**
   * @notice removes liquidity from pool by percent.
   * @param percent - the percent of your provided liquidity that you want to remove
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _removeLiquidityPercent(uint256 percent, bool useEth) internal virtual {
    require(percent > 0 && percent <= 1e18, "percent should be more than 0 and less than 1e18"); // max percnet(100%) is -> 10 ** 18
    uint256 balance = ILP(lpToken).balanceOf(msg.sender);
    uint256 removedLp = (balance * percent) / 1e18;
    _removeLiquidity(removedLp, useEth);
  }

  /**
   * @notice removes liquidity from pool by lp amount.
   * @param removedLp - the amount of your lp tokens that you want to remove.
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _removeLiquidityLp(uint256 removedLp, bool useEth) internal virtual {
    uint256 balance = ILP(lpToken).balanceOf(msg.sender);
    if (removedLp == type(uint256).max) {
      removedLp = balance;
    } else {
      require(removedLp <= balance, "you want to remove more than your lp balance");
    }
    require(removedLp > 0, "lp amount should be more than 0");
    _removeLiquidity(removedLp, useEth);
  }

  /**
   * @notice removes liquidity from pool by lp amount.
   * @param removedLp - the amount of your lp tokens that you want to remove.
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _removeLiquidity(uint256 removedLp, bool useEth) internal virtual {
    uint256 totalSupply = ILP(lpToken).totalSupply();
    ILP(lpToken).burn(msg.sender, removedLp);
    uint256 amount0Removed = (removedLp * nativeTokenAmount) / totalSupply;
    uint256 amount1Removed = (removedLp * cerosTokenAmount) / totalSupply;

    nativeTokenAmount -= amount0Removed;
    cerosTokenAmount -= amount1Removed;

    if (useEth) {
      INativeERC20(nativeToken).withdraw(amount0Removed);
      _sendValue(msg.sender, amount0Removed);
    } else {
      IERC20Upgradeable(nativeToken).safeTransfer(msg.sender, amount0Removed);
    }
    IERC20Upgradeable(cerosToken).safeTransfer(msg.sender, amount1Removed);
    emit LiquidityChange(
      msg.sender,
      amount0Removed,
      amount1Removed,
      nativeTokenAmount,
      cerosTokenAmount,
      false
    );
  }

  /**
   * @notice swaps the native coin to ceros or vise versa. See - {_swap}
   */
  function swapEth(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver
  ) external payable virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
    if (nativeToCeros) {
      require(msg.value == amountIn, "You should send the amountIn coin to the cointract");
    } else {
      require(msg.value == 0, "no need to send value if swapping ceros to Native");
    }
    return _swap(nativeToCeros, amountIn, receiver, true);
  }

  /**
   * @notice swaps the native wrapped token to ceros or vise versa. See - {_swap}
   */
  function swap(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver
  ) external virtual onlyIntegrator nonReentrant returns (uint256 amountOut) {
    return _swap(nativeToCeros, amountIn, receiver, false);
  }

  /**
   * @notice swaps native token to ceros or ceros token to native.
   * @param nativeToCeros - if 'true' then will swap native token to ceros, else ceros-native
   * @param amountIn - the amount of tokens that you want to swap
   * @param receiver - the address of swap receiver
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _swap(
    bool nativeToCeros,
    uint256 amountIn,
    address receiver,
    bool useEth
  ) internal virtual returns (uint256 amountOut) {
    require(receiver != address(0), "invaid receiver address");
    uint256 ratio = ICerosToken(cerosToken).ratio();
    if (nativeToCeros) {
      if (useEth) {
        INativeERC20(nativeToken).deposit{ value: amountIn }();
      } else {
        IERC20Upgradeable(nativeToken).safeTransferFrom(msg.sender, address(this), amountIn);
      }
      if (!excludedFromFee[msg.sender]) {
        uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
        amountIn -= stakeFeeAmt;
        uint256 managerFeeAmt = (stakeFeeAmt * managerFee) / FEE_MAX;
        uint256 ownerFeeAmt = (stakeFeeAmt * ownerFee) / FEE_MAX;
        uint256 integratorFeeAmt;
        if (integratorLockEnabled) {
          integratorFeeAmt = (stakeFeeAmt * integratorFee) / FEE_MAX;
          if (integratorFeeAmt > 0) {
            IERC20Upgradeable(nativeToken).safeTransfer(msg.sender, integratorFeeAmt);
          }
        }
        nativeTokenAmount +=
          amountIn +
          (stakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

        ownerFeeCollected.nativeFee += uint128(ownerFeeAmt);
        managerFeeCollected.nativeFee += uint128(managerFeeAmt);
      } else {
        nativeTokenAmount += amountIn;
      }
      amountOut = (amountIn * ratio) / 1e18;
      require(cerosTokenAmount >= amountOut, "Not enough liquidity");
      cerosTokenAmount -= amountOut;
      IERC20Upgradeable(cerosToken).safeTransfer(receiver, amountOut);
      emit Swap(msg.sender, receiver, nativeToCeros, amountIn, amountOut);
    } else {
      IERC20Upgradeable(cerosToken).safeTransferFrom(msg.sender, address(this), amountIn);
      if (!excludedFromFee[msg.sender]) {
        uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
        amountIn -= unstakeFeeAmt;
        uint256 managerFeeAmt = (unstakeFeeAmt * managerFee) / FEE_MAX;
        uint256 ownerFeeAmt = (unstakeFeeAmt * ownerFee) / FEE_MAX;
        uint256 integratorFeeAmt;
        if (integratorLockEnabled) {
          integratorFeeAmt = (unstakeFeeAmt * integratorFee) / FEE_MAX;
          if (integratorFeeAmt > 0) {
            IERC20Upgradeable(cerosToken).safeTransfer(msg.sender, integratorFeeAmt);
          }
        }
        cerosTokenAmount +=
          amountIn +
          (unstakeFeeAmt - managerFeeAmt - ownerFeeAmt - integratorFeeAmt);

        ownerFeeCollected.cerosFee += uint128(ownerFeeAmt);
        managerFeeCollected.cerosFee += uint128(managerFeeAmt);
      } else {
        cerosTokenAmount += amountIn;
      }
      amountOut = (amountIn * 1e18) / ratio;
      require(nativeTokenAmount >= amountOut, "Not enough liquidity");
      nativeTokenAmount -= amountOut;
      if (useEth) {
        INativeERC20(nativeToken).withdraw(amountOut);
        _sendValue(receiver, amountOut);
      } else {
        IERC20Upgradeable(nativeToken).safeTransfer(receiver, amountOut);
      }
      emit Swap(msg.sender, receiver, nativeToCeros, amountIn, amountOut);
    }
  }

  /**
   * @notice view function which retruns amount out by amount in
   * @param nativeToCeros - if 'true' then will show native token to ceros, else ceros-native
   * @param amountIn - the amount of tokens that you want to swap
   * @param isExcludedFromFee - if 'true' will calculate amount out without fees
   */
  function getAmountOut(
    bool nativeToCeros,
    uint256 amountIn,
    bool isExcludedFromFee
  ) external view virtual returns (uint256 amountOut, bool enoughLiquidity) {
    uint256 ratio = ICerosToken(cerosToken).ratio();
    if (nativeToCeros) {
      if (!isExcludedFromFee) {
        uint256 stakeFeeAmt = (amountIn * stakeFee) / FEE_MAX;
        amountIn -= stakeFeeAmt;
      }
      amountOut = (amountIn * ratio) / 1e18;
      enoughLiquidity = cerosTokenAmount >= amountOut;
    } else {
      if (!isExcludedFromFee) {
        uint256 unstakeFeeAmt = (amountIn * unstakeFee) / FEE_MAX;
        amountIn -= unstakeFeeAmt;
      }
      amountOut = (amountIn * 1e18) / ratio;
      enoughLiquidity = nativeTokenAmount >= amountOut;
    }
  }

  /**
   * @notice view function which retruns amount in by amount out
   * @param nativeToCeros - if 'true' then will show native token to ceros, else ceros-native
   * @param amountOut - the amount of tokens that you want to get
   * @param isExcludedFromFee - if 'true' will calculate amount out without fees
   */
  function getAmountIn(
    bool nativeToCeros,
    uint256 amountOut,
    bool isExcludedFromFee
  ) external view virtual returns (uint256 amountIn, bool enoughLiquidity) {
    uint256 dust = 1;
    dust = amountOut == 0 ? 0 : 1;
    uint256 ratio = ICerosToken(cerosToken).ratio();
    if (nativeToCeros) {
      amountIn = ((amountOut * 1e18) / ratio) + dust;
      if (!isExcludedFromFee) {
        amountIn = (amountIn * FEE_MAX) / (FEE_MAX - stakeFee); // amountIn with Fee
      }
      enoughLiquidity = cerosTokenAmount >= amountOut;
    } else {
      amountIn = ((amountOut * ratio) / 1e18) + dust;
      if (!isExcludedFromFee) {
        amountIn = (amountIn * FEE_MAX) / (FEE_MAX - unstakeFee); // amountIn with Fee
      }
      enoughLiquidity = nativeTokenAmount >= amountOut;
    }
  }

  /// sends the amount to the receiver address
  function _sendValue(address receiver, uint256 amount) internal virtual {
    payable(receiver).transfer(amount);
  }

  /**
   * @notice See - {_withdrawOwnerFee}
   */
  function withdrawOwnerFeeEth(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyOwner
    nonReentrant
  {
    _withdrawOwnerFee(amount0, amount1, true);
  }

  /**
   * @notice See - {_withdrawOwnerFee}
   */
  function withdrawOwnerFee(uint256 amount0, uint256 amount1)
    external
    virtual
    onlyOwner
    nonReentrant
  {
    _withdrawOwnerFee(amount0, amount1, false);
  }

  /**
   * @notice withdraws fees for owner
   * @param amount0Raw - amount of native to receve. use MAX_UINT256 to get all available amount.
   * @param amount1Raw - amount of ceros token to receve. use MAX_UINT256 to get all available amount.
   * @param useEth - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _withdrawOwnerFee(
    uint256 amount0Raw,
    uint256 amount1Raw,
    bool useEth
  ) internal virtual {
    uint128 amount0;
    uint128 amount1;
    if (amount0Raw == type(uint256).max) {
      amount0 = ownerFeeCollected.nativeFee;
    } else {
      require(amount0Raw <= type(uint128).max, "unsafe typecasting");
      amount0 = uint128(amount0Raw);
    }
    if (amount1Raw == type(uint256).max) {
      amount1 = ownerFeeCollected.cerosFee;
    } else {
      require(amount1Raw <= type(uint128).max, "unsafe typecasting");
      amount1 = uint128(amount1Raw);
    }
    if (amount0 > 0) {
      ownerFeeCollected.nativeFee -= amount0;
      if (useEth) {
        INativeERC20(nativeToken).withdraw(amount0);
        _sendValue(msg.sender, amount0);
      } else {
        IERC20Upgradeable(nativeToken).safeTransfer(msg.sender, amount0);
      }
    }
    if (amount1 > 0) {
      ownerFeeCollected.cerosFee -= amount1;
      IERC20Upgradeable(cerosToken).safeTransfer(msg.sender, amount1);
    }
  }

  function getRemainingManagerFee(address managerAddress)
    external
    view
    virtual
    returns (FeeAmounts memory feeRewards)
  {
    if (managers_.contains(managerAddress)) {
      uint256 managersLength = managers_.length();
      FeeAmounts memory currentManagerRewardDebt = managerRewardDebt[managerAddress];
      FeeAmounts memory accFee;
      accFee.nativeFee =
        _accFeePerManager.nativeFee +
        (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
        uint128(managersLength);
      accFee.cerosFee =
        _accFeePerManager.cerosFee +
        (managerFeeCollected.cerosFee - _alreadyUpdatedFees.cerosFee) /
        uint128(managersLength);
      feeRewards.nativeFee = accFee.nativeFee - currentManagerRewardDebt.nativeFee;
      feeRewards.cerosFee = accFee.cerosFee - currentManagerRewardDebt.cerosFee;
    }
  }

  /**
   * @notice See - {_withdrawManagerFee}
   */
  function withdrawManagerFee() external virtual onlyManager nonReentrant {
    _withdrawManagerFee(msg.sender, false);
  }

  /**
   * @notice See - {_withdrawManagerFee}
   */
  function withdrawManagerFeeEth() external virtual onlyManager nonReentrant {
    _withdrawManagerFee(msg.sender, true);
  }

  /**
   * @notice withdraws fees for manager
   * @param managerAddress - manager address to transfer the whole fees
   * @param useNative - if 'true' then transfer native token amount by native coin else by wrapped
   */
  function _withdrawManagerFee(address managerAddress, bool useNative) internal virtual {
    FeeAmounts memory feeRewards;
    FeeAmounts storage currentManagerRewardDebt = managerRewardDebt[managerAddress];
    _updateManagerFees();
    feeRewards.nativeFee = _accFeePerManager.nativeFee - currentManagerRewardDebt.nativeFee;
    feeRewards.cerosFee = _accFeePerManager.cerosFee - currentManagerRewardDebt.cerosFee;
    if (feeRewards.nativeFee > 0) {
      currentManagerRewardDebt.nativeFee += feeRewards.nativeFee;
      _claimedManagerFees.nativeFee += feeRewards.nativeFee;
      if (useNative) {
        INativeERC20(nativeToken).withdraw(feeRewards.nativeFee);
        _sendValue(managerAddress, feeRewards.nativeFee);
      } else {
        IERC20Upgradeable(nativeToken).safeTransfer(managerAddress, feeRewards.nativeFee);
      }
    }
    if (feeRewards.cerosFee > 0) {
      currentManagerRewardDebt.cerosFee += feeRewards.cerosFee;
      _claimedManagerFees.cerosFee += feeRewards.cerosFee;
      IERC20Upgradeable(cerosToken).safeTransfer(managerAddress, feeRewards.cerosFee);
    }
  }

  function _updateManagerFees() internal virtual {
    uint256 managersLength = managers_.length();
    _accFeePerManager.nativeFee +=
      (managerFeeCollected.nativeFee - _alreadyUpdatedFees.nativeFee) /
      uint128(managersLength);
    _accFeePerManager.cerosFee +=
      (managerFeeCollected.cerosFee - _alreadyUpdatedFees.cerosFee) /
      uint128(managersLength);
    _alreadyUpdatedFees.nativeFee = managerFeeCollected.nativeFee;
    _alreadyUpdatedFees.cerosFee = managerFeeCollected.cerosFee;
  }

  function add(address value, UserType utype) public virtual returns (bool) {
    require(value != address(0), "cannot add address(0)");
    bool success = false;
    if (utype == UserType.MANAGER) {
      require(msg.sender == owner(), "Only owner can add manager");
      if (!managers_.contains(value)) {
        uint256 managersLength = managers_.length();
        if (managersLength != 0) {
          _updateManagerFees();
          managerRewardDebt[value].nativeFee = _accFeePerManager.nativeFee;
          managerRewardDebt[value].cerosFee = _accFeePerManager.cerosFee;
        }
        success = managers_.add(value);
      }
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      require(managers_.contains(msg.sender), "Only manager can add liquidity provider");
      success = liquidityProviders_.add(value);
    } else {
      require(managers_.contains(msg.sender), "Only manager can add integrator");
      success = integrators_.add(value);
    }
    if (success) {
      emit UserTypeChanged(value, utype, true);
    }
    return success;
  }

  function setFee(uint24 newFee, FeeType feeType) external virtual onlyOwnerOrManager {
    require(newFee < FEE_MAX, "Unsupported size of fee!");
    if (feeType == FeeType.OWNER) {
      require(msg.sender == owner(), "only owner can call this function");
      require(newFee + managerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, ownerFee, newFee);
      ownerFee = newFee;
    } else if (feeType == FeeType.MANAGER) {
      require(newFee + ownerFee + integratorFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, managerFee, newFee);
      managerFee = newFee;
    } else if (feeType == FeeType.INTEGRATOR) {
      require(newFee + ownerFee + managerFee < FEE_MAX, "fee sum is more than 100%");
      emit FeeChanged(feeType, integratorFee, newFee);
      integratorFee = newFee;
    } else if (feeType == FeeType.STAKE) {
      emit FeeChanged(feeType, stakeFee, newFee);
      stakeFee = newFee;
    } else {
      emit FeeChanged(feeType, unstakeFee, newFee);
      unstakeFee = newFee;
    }
  }

  function setThreshold(uint24 newThreshold) external virtual onlyManager {
    require(newThreshold < FEE_MAX / 2, "threshold shuold be less than 50%");
    threshold = newThreshold;
    emit ThresholdChanged(newThreshold);
  }

  function setMaticPool(address newMaticPool) external virtual onlyOwner {
    maticPool = IMaticPool(newMaticPool);
    emit MaticPoolChanged(newMaticPool);
  }

  function enableIntegratorLock(bool enable) external virtual onlyOwnerOrManager {
    integratorLockEnabled = enable;
    emit IntegratorLockEnabled(enable);
  }

  function enableProviderLock(bool enable) external virtual onlyOwnerOrManager {
    providerLockEnabled = enable;
    emit ProviderLockEnabled(enable);
  }

  function excludeFromFee(address value, bool exclude) external virtual onlyOwnerOrManager {
    excludedFromFee[value] = exclude;
    emit ExcludedFromFee(value, exclude);
  }

  /**
   * @notice triggers the rebalance and stakes/unstakes the amounts of tokens to balance the pool(50/50)
   */
  function triggerRebalanceAnkr() external virtual nonReentrant onlyManager {
    skim();
    uint256 ratio = ICerosToken(cerosToken).ratio();
    uint256 amountAInNative = nativeTokenAmount;
    uint256 amountBInNative = (cerosTokenAmount * 1e18) / ratio;
    uint256 wholeAmount = amountAInNative + amountBInNative;
    bool isStake = amountAInNative > amountBInNative;
    if (!isStake) {
      uint256 temp = amountAInNative;
      amountAInNative = amountBInNative;
      amountBInNative = temp;
    }
    require(
      (amountBInNative * FEE_MAX) / wholeAmount < threshold,
      "the proportions are not less than threshold"
    );
    uint256 amount = (amountAInNative - amountBInNative) / 2;
    if (isStake) {
      nativeTokenAmount -= amount;
      INativeERC20(nativeToken).withdraw(amount);
      maticPool.stake{ value: amount }(false);
    } else {
      uint256 cerosAmt = (amount * ratio) / 1e18;
      uint256 commission = maticPool.unstakeCommission();
      cerosTokenAmount -= cerosAmt;
      nativeTokenAmount -= commission;
      INativeERC20(nativeToken).withdraw(commission);
      maticPool.unstake{ value: commission }(cerosAmt, false);
    }
  }

  /**
   * @notice triggers the rebalance and stakes/unstakes the amounts of tokens to balance the pool MATIC balance with given percent
   * @dev ignore threshold
   */
  function triggerRebalanceAnkrWithPercent(uint16 percent) external virtual nonReentrant onlyManager {
    require(percent >= 0 && percent <= 10000, "percent should be in range 0-100.00");

    skim();
    uint256 ratio = ICerosToken(cerosToken).ratio();

    // MATIC balance of pool
    uint256 amountAInNative = nativeTokenAmount;
    // ankrMATIC balance of pool in MATIC
    uint256 amountBInNative = (cerosTokenAmount * 1e18) / ratio;
    // total pool balance
    uint256 wholeAmount = amountAInNative + amountBInNative;

    uint256 expectedNative = wholeAmount * percent / 10000;

    uint256 amount;
    if (expectedNative < amountAInNative) {
      // we need stake to decrease MATIC amount
      amount = amountAInNative - expectedNative;

      require(nativeTokenAmount >= amount, "not enough MATIC to stake");
      nativeTokenAmount -= amount;
      INativeERC20(nativeToken).withdraw(amount);
      maticPool.stake{ value: amount }(false);
    } else if (expectedNative > amountAInNative) {
      // we need unstake to increase MATIC amount
      // set diff as amount to unstake
      amount = expectedNative - amountAInNative;

      uint256 cerosAmt = (amount * ratio) / 1e18;
      uint256 commission = maticPool.unstakeCommission();

      require(cerosTokenAmount >= cerosAmt, "not enough to pay ankrMATIC commission");
      require(nativeTokenAmount >= commission, "not enough to pay MATIC commission");

      cerosTokenAmount -= cerosAmt;
      nativeTokenAmount -= commission;

      INativeERC20(nativeToken).withdraw(commission);
      maticPool.unstake{ value: commission }(cerosAmt, false);
    } else {
      revert("already balanced");
    }
  }

  function approveToMaticPool() external virtual {
    IERC20Upgradeable(cerosToken).safeApprove(address(maticPool), type(uint256).max);
  }

  /**
   * @notice adds the not registered tokens to the liquidity pool
   */
  function skim() public virtual {
    uint256 contractBal = address(this).balance;
    uint256 contractWNativeBal = INativeERC20(nativeToken).balanceOf(address(this)) -
      ownerFeeCollected.nativeFee -
      (managerFeeCollected.nativeFee - _claimedManagerFees.nativeFee);
    uint256 contractCerosBal = ICerosToken(cerosToken).balanceOf(address(this)) -
      ownerFeeCollected.cerosFee -
      (managerFeeCollected.cerosFee - _claimedManagerFees.cerosFee);

    if (contractWNativeBal > nativeTokenAmount) {
      nativeTokenAmount = contractWNativeBal;
    }
    if (contractCerosBal > cerosTokenAmount) {
      cerosTokenAmount = contractCerosBal;
    }

    if (contractBal > nativeTokenAmount) {
      INativeERC20(nativeToken).deposit{ value: contractBal }();
      nativeTokenAmount += contractBal;
    }
  }

  function remove(address value, UserType utype) public virtual nonReentrant returns (bool) {
    require(value != address(0), "cannot remove address(0)");
    bool success = false;
    if (utype == UserType.MANAGER) {
      require(msg.sender == owner(), "Only owner can remove manager");
      if (managers_.contains(value)) {
        _withdrawManagerFee(value, false);
        success = managers_.remove(value);
        require(success, "cannot remove manager");
        delete managerRewardDebt[value];
      }
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      require(managers_.contains(msg.sender), "Only manager can remove liquidity provider");
      success = liquidityProviders_.remove(value);
    } else {
      require(managers_.contains(msg.sender), "Only manager can remove integrator");
      success = integrators_.remove(value);
    }
    if (success) {
      emit UserTypeChanged(value, utype, false);
    }
    return success;
  }

  function contains(address value, UserType utype) external view virtual returns (bool) {
    if (utype == UserType.MANAGER) {
      return managers_.contains(value);
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.contains(value);
    } else {
      return integrators_.contains(value);
    }
  }

  function length(UserType utype) external view virtual returns (uint256) {
    if (utype == UserType.MANAGER) {
      return managers_.length();
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.length();
    } else {
      return integrators_.length();
    }
  }

  function at(uint256 index, UserType utype) external view virtual returns (address) {
    if (utype == UserType.MANAGER) {
      return managers_.at(index);
    } else if (utype == UserType.LIQUIDITY_PROVIDER) {
      return liquidityProviders_.at(index);
    } else {
      return integrators_.at(index);
    }
  }

  // solhint-disable-next-line no-empty-blocks
  receive() external payable virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILP is IERC20Upgradeable {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

// SPDX-License-Identifier: Unliscensed
pragma solidity ^0.8.0;

interface ISwapPool {
    function swap(
        bool nativeToCeros,
        uint256 amountIn,
        address receiver
    ) external returns (uint256 amountOut);
    
    function getAmountOut(
        bool nativeToCeros,
        uint amountIn,
        bool isExcludedFromFee) 
        external view returns(uint amountOut, bool enoughLiquidity);

    function getAmountIn(
        bool nativeToCeros,
        uint amountOut,
        bool isExcludedFromFee)
        external view returns(uint amountIn, bool enoughLiquidity);
    
    function unstakeFee() external view returns (uint24 unstakeFee);
    function stakeFee() external view returns (uint24 stakeFee);

    function FEE_MAX() external view returns (uint24 feeMax);

    function cerosTokenAmount() external view returns(uint256);

    function nativeTokenAmount() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMaticPool {
  function stake(bool isRebasing) external payable;

  function unstake(uint256 amount, bool isRebasing) external payable;

  function stakeCommission() external view returns (uint256);

  function unstakeCommission() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICerosToken is IERC20 {
  function ratio() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INativeERC20 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { INativeERC20 } from "../interfaces/INativeERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WNative is INativeERC20, ERC20 {
  // solhint-disable-next-line no-empty-blocks
  constructor() ERC20("Wrapped Native", "WNative") {}

  receive() external payable {
    _mint(msg.sender, msg.value);
  }

  function deposit() external payable {
    _mint(msg.sender, msg.value);
  }

  function withdraw(uint256 amount) external {
    _burn(msg.sender, amount);
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = payable(msg.sender).call{ value: amount }("");
    require(success, "Unable to send value, recipient may have reverted");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../jug.sol";

interface GemLike {
    function approve(address, uint) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
}

interface DaiJoinLike {
    function dai() external returns (GemLike);
    function join(address, uint) external payable;
    function exit(address, uint) external;
}

contract ProxyLike is Ownable {
    uint256 constant RAY = 10 ** 27;
    address jug;
    address vat;
    constructor(address _jug, address _vat) {
        jug = _jug;
        vat = _vat;
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require((z = x - y) <= x, "sub-overflow");    
        } 
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x, "mul-overflow");
        }
    }

    function jugInitFile(bytes32 _gem, bytes32 _what, uint256 _rate) external onlyOwner {
        Jug(jug).init(_gem);
        Jug(jug).file(_gem, _what, _rate);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// jug.sol -- Davos Lending Rate

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

pragma solidity ^0.8.10;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

import "./dMath.sol";
import "./interfaces/JugLike.sol";
import "./interfaces/VatLike.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract Jug is Initializable, JugLike {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Jug/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        uint256 duty;  // Collateral-specific, per-second stability fee contribution [ray]
        uint256  rho;  // Time of last drip [unix epoch time]
    }

    mapping (bytes32 => Ilk) public ilks;
    VatLike                  public vat;   // CDP Engine
    address                  public vow;   // Debt Engine
    uint256                  public base;  // Global, per-second stability fee contribution [ray]

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);

    // --- Init ---
    function initialize(address vat_) external initializer {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
    }

    // --- Math ---
    function _add(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            z = x + y;
            require(z >= x);
        }
    }
    function _diff(uint x, uint y) internal pure returns (int z) {
        unchecked {
            z = int(x) - int(y);
            require(int(x) >= 0 && int(y) >= 0);
        }
    }
    function _rmul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            z = x * y;
            require(y == 0 || z / y == x);
            z = z / dMath.ONE;
        }
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Administration ---
    function init(bytes32 ilk) external auth {
        Ilk storage i = ilks[ilk];
        require(i.duty == 0, "Jug/ilk-already-init");
        i.duty = dMath.ONE;
        i.rho  = block.timestamp;
    }
    function file(bytes32 ilk, bytes32 what, uint data) external auth {
        require(block.timestamp == ilks[ilk].rho, "Jug/rho-not-updated");
        if (what == "duty") ilks[ilk].duty = data;
        else revert("Jug/file-unrecognized-param");
        emit File(ilk, what, data);
        
    }
    function file(bytes32 what, uint data) external auth {
        if (what == "base") base = data;
        else revert("Jug/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "vow") vow = data;
        else revert("Jug/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Stability Fee Collection ---
    function drip(bytes32 ilk) external returns (uint rate) {
        require(block.timestamp >= ilks[ilk].rho, "Jug/invalid-now");
        (, uint prev,,,) = vat.ilks(ilk);
        rate = _rmul(dMath.rpow(_add(base, ilks[ilk].duty), block.timestamp - ilks[ilk].rho, dMath.ONE), prev);
        vat.fold(ilk, vow, _diff(rate, prev));
        ilks[ilk].rho = block.timestamp;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// vow.sol -- Davos settlement module

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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/VatLike.sol";
import "./interfaces/DavosJoinLike.sol";

contract Vow is Initializable{
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "Vow/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vow/not-authorized");
        _;
    }

    // --- Data ---
    VatLike public vat;          // CDP Engine
    address public multisig;     // Surplus multisig 

    address public davosJoin; // Stablecoin address
    uint256 public hump;    // Surplus buffer      [rad]

    uint256 public live;  // Active Flag

    address public davos;  // Davos token

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address vat_, address _davosJoin, address multisig_) external initializer {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        davosJoin = _davosJoin;
        multisig = multisig_;
        vat.hope(davosJoin);
        live = 1;
    }

    // --- Math ---
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    function file(bytes32 what, uint data) external auth {
        if (what == "hump") hump = data;
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "multisig") multisig = data;
        else if (what == "davosjoin") { 
            vat.nope(davosJoin);
            davosJoin = data;
            vat.hope(davosJoin);
        }
        else if (what == "davos") davos = data;
        else if (what == "vat") vat = VatLike(data);
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }

    // Debt settlement
    function heal(uint rad) external {
        require(rad <= vat.davos(address(this)), "Vow/insufficient-surplus");
        require(rad <= vat.sin(address(this)), "Vow/insufficient-debt");
        vat.heal(rad);
    }

    // Feed stablecoin to vow
    function feed(uint wad) external {
        IERC20Upgradeable(davos).transferFrom(msg.sender, address(this), wad);
        IERC20Upgradeable(davos).approve(davosJoin, wad);
        DavosJoinLike(davosJoin).join(address(this), wad);
    }
    // Send surplus to multisig
    function flap() external {
        require(vat.davos(address(this)) >= vat.sin(address(this)) + hump, "Vow/insufficient-surplus");
        uint rad = vat.davos(address(this)) - (vat.sin(address(this)) + hump);
        uint wad = rad / 1e27;
        DavosJoinLike(davosJoin).exit(multisig, wad);
    }

    function cage() external auth {
        require(live == 1, "Vow/not-live");
        live = 0;
        vat.heal(min(vat.davos(address(this)), vat.sin(address(this))));
    }

    function uncage() external auth {
        require(live == 0, "Vow/live");
        live = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// join.sol -- Basic token adapters

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

pragma solidity ^0.8.10;

import "./interfaces/GemJoinLike.sol";
import "./interfaces/DavosJoinLike.sol";
import "./interfaces/GemLike.sol";
import "./interfaces/VatLike.sol";
import "./interfaces/IDavos.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

/*
    Here we provide *adapters* to connect the Vat to arbitrary external
    token implementations, creating a bounded context for the Vat. The
    adapters here are provided as working examples:
      - `GemJoin`: For well behaved ERC20 tokens, with simple transfer
                   semantics.
      - `ETHJoin`: For native Ether.
      - `DavosJoin`: For connecting internal Davos balances to an external
                   `DSToken` implementation.
    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.
    Adapters need to implement two basic methods:
      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system
*/

contract GemJoin is Initializable, GemJoinLike {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "GemJoin/not-authorized");
        _;
    }

    VatLike public vat;   // CDP Engine
    bytes32 public ilk;   // Collateral Type
    GemLike public gem;
    uint    public dec;
    uint    public live;  // Active Flag

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);
    event Cage();
    event UnCage();
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address vat_, bytes32 ilk_, address gem_) external initializer {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        ilk = ilk_;
        gem = GemLike(gem_);
        dec = gem.decimals();
        emit Rely(msg.sender);
    }
    function cage() external auth {
        live = 0;
        emit Cage();
    }

    function uncage() external auth {
        live = 1;
        emit UnCage();
    }

    function join(address usr, uint wad) external auth {
        require(live == 1, "GemJoin/not-live");
        require(int(wad) >= 0, "GemJoin/overflow");
        vat.slip(ilk, usr, int(wad));
        require(gem.transferFrom(msg.sender, address(this), wad), "GemJoin/failed-transfer");
        emit Join(usr, wad);
    }
    function exit(address usr, uint wad) external auth {
        require(wad <= (2 ** 255) - 1, "GemJoin/overflow");
        vat.slip(ilk, msg.sender, -int(wad));
        require(gem.transfer(usr, wad), "GemJoin/failed-transfer");
        emit Exit(usr, wad);
    }
}

contract DavosJoin is Initializable, DavosJoinLike {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "DavosJoin/not-authorized");
        _;
    }

    VatLike public vat;      // CDP Engine
    IDavos public davos;  // Stablecoin Token
    uint    public live;     // Active Flag

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);
    event Cage();
    event Uncage();

    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }
    
    // --- Init ---
    function initialize(address vat_, address davos_) external initializer {
        wards[msg.sender] = 1;
        live = 1;
        vat = VatLike(vat_);
        davos = IDavos(davos_);
    }
    function cage() external auth {
        live = 0;
        emit Cage();
    }
    function uncage() external auth {
        live = 1;
        emit Uncage();
    }
    uint constant ONE = 10 ** 27;
    function mul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x);
        }
    }
    function join(address usr, uint wad) external auth {
        vat.move(address(this), usr, mul(ONE, wad));
        davos.burn(msg.sender, wad);
        emit Join(usr, wad);
    }
    function exit(address usr, uint wad) external auth {
        require(live == 1, "DavosJoin/not-live");
        vat.move(msg.sender, address(this), mul(ONE, wad));
        davos.mint(usr, wad);
        emit Exit(usr, wad);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IDavos is IERC20MetadataUpgradeable {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract ERC20ModUpgradeable is
    Initializable,
    ContextUpgradeable,
    IERC20Upgradeable,
    IERC20MetadataUpgradeable
{
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_)
        internal
        onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    uint256[45] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ERC20ModUpgradeable.sol";

contract Token is OwnableUpgradeable, ERC20ModUpgradeable {

    uint256 public ratio;
    
    function initialize(string memory name, string memory symbol) external initializer {
        __Ownable_init();
        __ERC20_init_unchained(name, symbol);
        ratio = 1e18;
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function setRatio(uint256 _ratio) external {
        ratio = _ratio;
    }

    function getWstETHByStETH(uint256 amount) external returns(uint256) {
        return amount * ratio / 1e18;
    }

    function getStETHByWstETH(uint256 amount) external returns(uint256) {
        return amount * 1e18 / ratio;
    }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external payable {
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
contract NonTransferableERC20 is
Initializable,
ContextUpgradeable,
IERC20Upgradeable
{
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_)
    internal
    onlyInitializing
    {
        __ERC20_init_unchained(name_, symbol_);
    }
    function __ERC20_init_unchained(string memory name_, string memory symbol_)
    internal
    onlyInitializing
    {
        _name = name_;
        _symbol = symbol_;
    }
    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _balances[account];
    }
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        revert("Not transferable");
    }
    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
    {
        return _allowances[owner][spender];
    }
    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        revert("Not transferable");
    }
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        revert("Not transferable");
    }
    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import { ILP } from "./interfaces/ILP.sol";

contract LP is ILP, ERC20Upgradeable {
  address public swapPool;

  modifier onlySwapPool() {
    require(msg.sender == swapPool, "only swap pool can call this function");
    _;
  }

  // constructor() ERC20("aMATICcLP", "aMATICcLP") {}
  function initialize(string calldata _name, string calldata _symbol)
    external
    initializer
  {
    __ERC20_init_unchained(_name, _symbol);
  }

  function setSwapPool(address _swapPool) external {
    require(swapPool == address(0), "swap pool can be set only once");
    swapPool = _swapPool;
  }

  function mint(address _account, uint256 _amount) external onlySwapPool {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) external onlySwapPool {
    _burn(_account, _amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title Matic token contract
 * @notice This contract is an ECR20 like wrapper over native ether (matic token) transfers on the matic chain
 * @dev ERC20 methods have been made payable while keeping their method signature same as other ChildERC20s on Matic
 */
contract NativeMock is ERC20Upgradeable {
    address token;
    uint256 public currentSupply = 0;
    uint8 private constant DECIMALS = 18;
    bool isInitialized;

    // function initialize() public {
    //     // Todo: once BorValidator(@0x1000) contract added uncomment me
    //     // require(msg.sender == address(0x1000));
    //     require(!isInitialized, "The contract is already initialized");
    //     isInitialized = true;
    // }

    function setParent(address) public {
        revert("Disabled feature");
    }

    function withdraw(uint256 amount) public payable {
        address user = msg.sender;
        // input balance
        uint256 input = balanceOf(user);
        // check for amount
        require(amount > 0 && msg.value == amount, "Insufficient amount");

        // withdraw event
        //   emit Withdraw(token, user, amount, input, balanceOf(user));
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../swapPool/interfaces/IMaticPool.sol";
import "../swapPool/mocks/NativeMock.sol";
import "../swapPool/interfaces/ICerosToken.sol";

contract MaticPoolMock is IMaticPool
{
  uint256 private _ON_DISTRIBUTE_GAS_LIMIT;
  address private _operator;

  uint256 private _minimumStake;
  uint256 public stakeCommission;
  uint256 public unstakeCommission;
  uint256 private _totalCommission;

  NativeMock private _maticToken;

  address private _bondToken;
  address private _certToken;

  function initialize(
    address maticAddress,
    address certToken,
    uint256 minimumStake
  ) external {
    _maticToken = NativeMock(maticAddress);
    _minimumStake = minimumStake;
    _certToken = certToken;
    _ON_DISTRIBUTE_GAS_LIMIT = 300000;
  }

  function stake(bool isRebasing) external payable override {
    uint256 realAmount = msg.value - stakeCommission;
    address staker = msg.sender;
    require(
      realAmount >= _minimumStake,
      "value must be greater than min stake amount"
    );
    _totalCommission += stakeCommission;
    // send matic across into Ethereum chain via MATIC POS
    _maticToken.withdraw{value: realAmount}(realAmount);
  }

  function unstake(uint256 amount, bool isRebasing)
  external
  payable
  override
  {
    require(msg.value >= unstakeCommission, "wrong commission");
    require(isRebasing == false, "bonds not supported in mock");
    _totalCommission += msg.value;
    address claimer = msg.sender;
    address fromToken = _certToken;
    uint256 ratio = ICerosToken(fromToken).ratio();
    uint256 amountOut = transferFromAmount(amount, ratio);
    uint256 realAmount = sharesToBonds(amountOut, ratio);

    require(
      IERC20Upgradeable(fromToken).balanceOf(claimer) >= amount,
      "can not claim more than have on address"
    );
    // transfer tokens from claimer
    IERC20Upgradeable(fromToken).transferFrom(
      claimer,
      address(this),
      amount
    );
  }

  function changeStakeCommission(uint256 commission) external {
    stakeCommission = commission;
  }

  function changeUnstakeCommission(uint256 commission) external {
    unstakeCommission = commission;
  }

  function transferFromAmount(uint256 amount, uint256 ratio)
  internal
  pure
  returns (uint256)
  {
    return
    multiplyAndDivideCeil(
      multiplyAndDivideFloor(amount, ratio, 1e18),
      1e18,
      ratio
    );
  }

  function sharesToBonds(uint256 amount, uint256 ratio)
  internal
  pure
  returns (uint256)
  {
    return multiplyAndDivideFloor(amount, 1e18, ratio);
  }

  function bondsToShares(uint256 amount, uint256 ratio)
  internal
  pure
  returns (uint256)
  {
    return multiplyAndDivideFloor(amount, ratio, 1e18);
  }

  function saturatingMultiply(uint256 a, uint256 b)
  internal
  pure
  returns (uint256)
  {
  unchecked {
    if (a == 0) return 0;
    uint256 c = a * b;
    if (c / a != b) return type(uint256).max;
    return c;
  }
  }

  function saturatingAdd(uint256 a, uint256 b)
  internal
  pure
  returns (uint256)
  {
  unchecked {
    uint256 c = a + b;
    if (c < a) return type(uint256).max;
    return c;
  }
  }

  // Preconditions:
  //  1. a may be arbitrary (up to 2 ** 256 - 1)
  //  2. b * c < 2 ** 256
  // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
  function multiplyAndDivideFloor(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (uint256) {
    return
    saturatingAdd(
      saturatingMultiply(a / c, b),
      ((a % c) * b) / c // can't fail because of assumption 2.
    );
  }

  // Preconditions:
  //  1. a may be arbitrary (up to 2 ** 256 - 1)
  //  2. b * c < 2 ** 256
  // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
  function multiplyAndDivideCeil(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (uint256) {
    return
    saturatingAdd(
      saturatingMultiply(a / c, b),
      ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ICerosToken } from "../interfaces/ICerosToken.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CerosToken is ICerosToken, ERC20 {
  uint256 public ratio;

  // solhint-disable-next-line no-empty-blocks
  constructor() ERC20("Wrapped Native", "WNative") {}

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function mintMe(uint256 amount) external {
    _mint(msg.sender, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }

  function burnMe(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function setRatio(uint256 newRatio) external {
    ratio = newRatio;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ICertToken.sol";
contract CeVault is
IVault,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    /**
     * Variables
     */
    string private _name;
    // Tokens
    ICertToken private _ceToken;
    ICertToken private _aMATICc;
    address private _router;
    mapping(address => uint256) private _claimed; // in aMATICc
    mapping(address => uint256) private _depositors; // in aMATICc
    mapping(address => uint256) private _ceTokenBalances; // in aMATICc
    /**
     * Modifiers
     */
    modifier onlyRouter() {
        require(msg.sender == _router, "Router: not allowed");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    function initialize(
        string memory name,
        address ceTokenAddress,
        address aMATICcAddress
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _name = name;
        _ceToken = ICertToken(ceTokenAddress);
        _aMATICc = ICertToken(aMATICcAddress);
    }
    // deposit
    function deposit(uint256 amount)
    external
    override
    nonReentrant
    returns (uint256)
    {
        revert("not-allowed");
        // return _deposit(msg.sender, amount);
    }
    // deposit
    function depositFor(address recipient, uint256 amount)
    external
    override
    nonReentrant
    onlyRouter
    returns (uint256)
    {
        return _deposit(recipient, amount);
    }
    // deposit
    function _deposit(address account, uint256 amount)
    private
    returns (uint256)
    {
        uint256 ratio = _aMATICc.ratio();
        _aMATICc.transferFrom(msg.sender, address(this), amount);
        uint256 toMint = safeCeilMultiplyAndDivide(amount, 1e18, ratio);
        _depositors[account] += amount; // aMATICc
        _ceTokenBalances[account] += toMint;
        //  mint ceToken to recipient
        ICertToken(_ceToken).mint(account, toMint);
        emit Deposited(msg.sender, account, toMint);
        return toMint;
    }
    function safeCeilMultiplyAndDivide(uint256 a, uint256 b, uint256 c) 
    internal 
    pure 
    returns (uint256) 
    {

        // Ceil (a * b / c)
        uint256 remainder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(remainder.mul(b).add(c.sub(1)).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }
    function claimYieldsFor(address owner, address recipient)
    external
    override
    onlyRouter
    nonReentrant
    returns (uint256)
    {
        return _claimYields(owner, recipient);
    }
    // claimYields
    function claimYields(address recipient)
    external
    override
    nonReentrant
    returns (uint256)
    {
        return _claimYields(msg.sender, recipient);
    }
    function _claimYields(address owner, address recipient)
    private
    returns (uint256)
    {
        uint256 availableYields = this.getYieldFor(owner);
        require(availableYields > 0, "has not got yields to claim");
        // return back aMATICc to recipient
        _claimed[owner] += availableYields;
        _aMATICc.transfer(recipient, availableYields);
        emit Claimed(owner, recipient, availableYields);
        return availableYields;
    }
    // withdraw
    function withdraw(address recipient, uint256 amount)
    external
    override
    nonReentrant
    returns (uint256)
    {
        revert("not-allowed");
        // return _withdraw(msg.sender, recipient, amount);
    }
    // withdraw
    function withdrawFor(
        address owner,
        address recipient,
        uint256 amount
    ) external override nonReentrant onlyRouter returns (uint256) {
        return _withdraw(owner, recipient, amount);
    }
    function _withdraw(
        address owner,
        address recipient,
        uint256 amount
    ) private returns (uint256) {
        uint256 ratio = _aMATICc.ratio();
        uint256 realAmount = safeCeilMultiplyAndDivide(amount, ratio, 1e18);
        require(
            _aMATICc.balanceOf(address(this)) >= realAmount,
            "not such amount in the vault"
        );
        uint256 balance = _ceTokenBalances[owner];
        require(balance >= amount, "insufficient balance");
        _ceTokenBalances[owner] -= amount; // MATIC
        // burn ceToken from owner
        ICertToken(_ceToken).burn(owner, amount);
        _depositors[owner] -= realAmount; // aMATICc
        _aMATICc.transfer(recipient, realAmount);
        emit Withdrawn(owner, recipient, realAmount);
        return realAmount;
    }
    function getTotalAmountInVault() external view override returns (uint256) {
        return _aMATICc.balanceOf(address(this));
    }
    // yield + principal = deposited(before claim)
    // BUT after claim yields: available_yield + principal == deposited - claimed
    // available_yield = yield - claimed;
    // principal = deposited*(current_ratio/init_ratio)=cetoken.balanceOf(account)*current_ratio;
    function getPrincipalOf(address account)
    external
    view
    override
    returns (uint256)
    {
        uint256 ratio = _aMATICc.ratio();
        return (_ceTokenBalances[account] * ratio) / 1e18; // in aMATICc
    }
    // yield = deposited*(1-current_ratio/init_ratio) = cetoken.balanceOf*init_ratio-cetoken.balanceOf*current_ratio
    // yield = cetoken.balanceOf*(init_ratio-current_ratio) = amount(in aMATICc) - amount(in aMATICc)
    function getYieldFor(address account)
    external
    view
    override
    returns (uint256)
    {
        uint256 principal = this.getPrincipalOf(account);
        if (principal >= _depositors[account]) {
            return 0;
        }
        uint256 totalYields = _depositors[account] - principal;
        if (totalYields <= _claimed[account]) {
            return 0;
        }
        return totalYields - _claimed[account];
    }
    function getCeTokenBalanceOf(address account)
    external
    view
    returns (uint256)
    {
        return _ceTokenBalances[account];
    }
    function getDepositOf(address account) external view returns (uint256) {
        return _depositors[account];
    }
    function getClaimedOf(address account) external view returns (uint256) {
        return _claimed[account];
    }
    function changeRouter(address router) external onlyOwner {
        require(router != address(0));
        _router = router;
        emit RouterChanged(router);
    }
    function getName() external view returns (string memory) {
        return _name;
    }
    function getCeToken() external view returns(address) {
        return address(_ceToken);
    }
    function getAmaticcAddress() external view returns(address) {
        return address(_aMATICc);
    }
    function getRouter() external view returns(address) {
        return address(_router);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
interface IVault {
    /**
     * Events
     */
    event Deposited(
        address indexed owner,
        address indexed recipient,
        uint256 value
    );
    event Claimed(
        address indexed owner,
        address indexed recipient,
        uint256 value
    );
    event Withdrawn(
        address indexed owner,
        address indexed recipient,
        uint256 value
    );
    event RouterChanged(address router);
    /**
     * Methods
     */
    event RatioUpdated(uint256 currentRatio);
    function deposit(uint256 amount) external returns (uint256);
    function depositFor(address recipient, uint256 amount)
    external
    returns (uint256);
    function claimYields(address recipient) external returns (uint256);
    function claimYieldsFor(address owner, address recipient)
    external
    returns (uint256);
    function withdraw(address recipient, uint256 amount)
    external
    returns (uint256);
    function withdrawFor(
        address owner,
        address recipient,
        uint256 amount
    ) external returns (uint256);
    function getPrincipalOf(address account) external view returns (uint256);
    function getYieldFor(address account) external view returns (uint256);
    function getTotalAmountInVault() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICertToken is IERC20 {

    function burn(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function balanceWithRewardsOf(address account) external returns (uint256);

    function isRebasing() external returns (bool);

    function ratio() external view returns (uint256);
}

//SPDX-License-Identifier: MICerosRouterPolygonIT
pragma solidity ^0.8.0;

import "../../masterVault/interfaces/IMasterVault.sol";
import "../../ceros/interfaces/ISwapPool.sol";
import "../../ceros/interfaces/ICertToken.sol";
import "../../ceros/interfaces/ICerosRouterSp.sol";
import "../BaseStrategy.sol";

contract CerosYieldConverterStrategySp is BaseStrategy {

    ICerosRouterSp public _ceRouter;
    ICertToken public _certToken;
    IMasterVault public vault;

    address public _swapPool;

    bool public feeFlag;

    event SwapPoolChanged(address swapPool);
    event CeRouterChanged(address ceRouter);

    /// @dev initialize function - Constructor for Upgradable contract, can be only called once during deployment
    /// @param destination Address of the ceros router contract
    /// @param feeRecipient Address of the fee recipient
    /// @param underlyingToken Address of the underlying token(wMatic)
    /// @param certToekn Address of aMATICc token
    /// @param masterVault Address of the masterVault contract
    /// @param swapPool Address of swapPool contract
    function initialize(
        address destination,
        address feeRecipient,
        address underlyingToken,
        address certToekn,
        address masterVault,
        address swapPool
    ) public initializer {
        __BaseStrategy_init(destination, feeRecipient, underlyingToken);
        _ceRouter = ICerosRouterSp(destination);
        _certToken = ICertToken(certToekn);
        _swapPool = swapPool;
        vault = IMasterVault(masterVault);
        underlying.approve(address(destination), type(uint256).max);
        underlying.approve(address(vault), type(uint256).max);
        _certToken.approve(_swapPool, type(uint256).max);
    }

    /**
     * Modifiers
     */
    modifier onlyVault() {
        require(msg.sender == address(vault), "!vault");
        _;
    }

    /// @dev deposits the given amount of underlying tokens into ceros
    /// @param amount amount of underlying tokens
    function deposit(uint256 amount) external override onlyVault whenNotPaused returns(uint256 value) {
        require(amount <= underlying.balanceOf(address(this)), "insufficient balance");
        return _deposit(amount);
    }

    /// @dev internal function to deposit the given amount of underlying tokens into ceros
    /// @param amount amount of underlying tokens
    function _deposit(uint256 amount) internal returns (uint256 value) {
        require(amount > 0, "invalid amount");
        _beforeDeposit(amount);
        return _ceRouter.depositWMatic(amount);
    }

    /// @dev withdraws the given amount of underlying tokens from ceros and transfers to masterVault
    /// @param amount amount of underlying tokens
    function withdraw(address recipient, uint256 amount) external override onlyVault whenNotPaused returns(uint256 value) {
        return _withdraw(amount);
    }

    /// @dev internal function to withdraw the given amount of underlying tokens from ceros
    ///      and transfers to masterVault
    /// @param amount amount of underlying tokens
    /// @return value - returns the amount of underlying tokens withdrawn from ceros
    function _withdraw(uint256 amount) internal returns (uint256 value) {
        require(amount > 0, "invalid amount");
        uint256 wethBalance = underlying.balanceOf(address(this));
        if(amount < wethBalance) {
            SafeERC20Upgradeable.safeTransfer(underlying, address(vault), amount);
            return amount;
        }
        
        uint256 amountOut; bool enoughLiquidity; uint256 remaining = amount - wethBalance;
        (amountOut, enoughLiquidity) = ISwapPool(_swapPool).getAmountOut(false, (remaining * _certToken.ratio()) / 1e18, feeFlag); // (amount * ratio) / 1e18
        if (enoughLiquidity) {
            value = _ceRouter.withdrawWithSlippage(address(this), remaining, amountOut);
            require(value >= amountOut, "invalid out amount");
            uint256 withdrawAmount = wethBalance + value;
            if (amount < withdrawAmount) {
                // transfer extra funds to feeRecipient 
                SafeERC20Upgradeable.safeTransfer(underlying, feeRecipient, withdrawAmount - amount);
            } else {
                amount = withdrawAmount;
            }
            SafeERC20Upgradeable.safeTransfer(underlying, address(vault), amount);
            return amount;
        }
    }

    receive() external payable {
        require(msg.sender == address(underlying)); // only accept ETH from the WETH contract
    }

    /// @dev returns the depositable amount based on liquidity
    function canDeposit(uint256 _amount) external view override returns(uint256 capacity, uint256 chargedCapacity) {
        uint256 amountOut; bool enoughLiquidity;
        (amountOut, enoughLiquidity) = ISwapPool(_swapPool).getAmountOut(true, _amount, true);
        if (!enoughLiquidity) { // If liquidity not enough, calculate amountIn for remaining liquidity
            (capacity,) = ISwapPool(_swapPool).getAmountIn(true, ISwapPool(_swapPool).cerosTokenAmount() - 1, false);
            (amountOut,) = ISwapPool(_swapPool).getAmountOut(true, capacity, true);
            (chargedCapacity,) = ISwapPool(_swapPool).getAmountOut(false, amountOut, false);
        } else {
            capacity = _amount;
            (chargedCapacity,) = ISwapPool(_swapPool).getAmountOut(false, amountOut, false);
        }
    }

    /// @dev returns the withdrawable amount based on liquidity
    function canWithdraw(uint256 _amount) external view override returns(uint256 capacity, uint256 chargedCapacity) {
        uint256 wethBalance = underlying.balanceOf(address(this));
        if(_amount < wethBalance) return (_amount, _amount);
        
        uint256 amountin; uint256 amountOut; bool enoughLiquidity; uint256 remaining = _amount - wethBalance;
        (amountOut, enoughLiquidity) = ISwapPool(_swapPool).getAmountOut(false, (remaining * _certToken.ratio()) / 1e18, true);

        if (!enoughLiquidity) {
            (amountin,) = ISwapPool(_swapPool).getAmountIn(false, ISwapPool(_swapPool).nativeTokenAmount() - 1, false);
            (amountOut,) = ISwapPool(_swapPool).getAmountOut(false, amountin, true);
            capacity = wethBalance + amountOut;
            (amountOut,) = ISwapPool(_swapPool).getAmountOut(false, (amountOut * _certToken.ratio()) / 1e18, feeFlag);
            chargedCapacity = wethBalance + amountOut;
        } else {
            capacity = _amount;
            (amountOut,) = ISwapPool(_swapPool).getAmountOut(false, (amountOut * _certToken.ratio()) / 1e18, feeFlag);
            chargedCapacity = wethBalance + amountOut;
        }
    }

    /// @dev claims yeild from ceros in aMATICc and transfers to feeRecipient
    function harvest() external onlyOwnerOrStrategist {
        _harvestTo(feeRecipient);
    }

    /// @dev claims yeild from ceros in aMATICc, converts them to wMATIC and transfers them to feeRecipient
    function harvestAndSwap() external onlyOwnerOrStrategist {
        uint256 yield = _harvestTo(address(this));
        (uint256 amountOut, bool enoughLiquidity) = ISwapPool(_swapPool).getAmountOut(false, yield, true);
        if (enoughLiquidity && amountOut > 0) {
            amountOut = ISwapPool(_swapPool).swap(false, yield, address(this));
            SafeERC20Upgradeable.safeTransfer(underlying, feeRecipient, amountOut);
        }
    }

    /// @dev internal function to claim yeild from ceros in aMATICc and transfers to desired address
    function _harvestTo(address to) private returns(uint256 yield) {
        yield = _ceRouter.getYieldFor(address(this));
        if(yield > 0) {
            yield = _ceRouter.claim(to);  // TODO: handle: reverts if no yield
        }
        uint256 profit = _ceRouter.getProfitFor(address(this));
        if(profit > 0) {
            yield += profit;
            _ceRouter.claimProfit(to);
        }
    }

    /// @dev only owner can change swap pool address
    /// @param swapPool new swap pool address
    function changeSwapPool(address swapPool) external onlyOwner {
        require(swapPool != address(0));
        _certToken.approve(_swapPool, 0);
        _swapPool = swapPool;
        _certToken.approve(_swapPool, type(uint256).max);
        emit SwapPoolChanged(swapPool);
    }

    /// @dev only owner can change ceRouter
    /// @param ceRouter new ceros router address
    function changeCeRouter(address ceRouter) external onlyOwner {
        require(ceRouter != address(0));
        underlying.approve(address(_ceRouter), 0);
        destination = ceRouter;
        _ceRouter = ICerosRouterSp(ceRouter);
        underlying.approve(address(_ceRouter), type(uint256).max);
        emit CeRouterChanged(ceRouter);
    }

    function changeFeeFlag(bool _flag) external onlyOwner {
        feeFlag = _flag;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterVault {

    // --- Vars ---
    struct StrategyParams {
      bool active;
      Type class;
      uint256 allocation;
      uint256 debt;
    }
    enum Type {
      IMMEDIATE,  // Strategy with no unstake delay
      DELAYED,    // Strategy having unstake delay
      ABSTRACT    // Strategy agnostic or Type Any
    }

    // --- Events ---
    event DepositFeeChanged(uint256 _newDepositFee);
    event WithdrawalFeeChanged(uint256 _newWithdrawalFee);
    event ProviderChanged(address _provider);
    event ManagerAdded(address _newManager);
    event ManagerRemoved(address _manager);
    event FeeReceiverChanged(address _feeReceiver);
    event WaitingPoolChanged(address _waitingPool);
    event WaitingPoolCapChanged(uint256 _cap);
    event StrategyAllocationChanged(address _strategy, uint256 _allocation);
    event StrategyAdded(address _strategy, uint256 _allocation);
    event StrategyMigrated(address _oldStrategy, address _newStrategy, uint256 _newAllocation);
    event AllocationOnDepositChangeed(uint256 _status);
    event DepositedToStrategy(address indexed _strategy, uint256 _amount, uint256 _actualAmount);
    event WithdrawnFromStrategy(address indexed _strategy, uint256 _amount, uint256 _actualAmount);

    // --- Functions ---
    function depositUnderlying(address _account, uint256 _amount) external returns (uint256);
    function withdrawUnderlying(address _account, uint256 _amount) external returns (uint256);
    function feeReceiver() external returns (address);
    function withdrawalFee() external view returns (uint256);
    function strategyParams(address _strategy) external view returns(bool active, Type withdraw, uint256 allocation, uint256 debt);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ICerosRouterSp {
    /**
     * Events
     */

    event Deposit(
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 profit
    );

    event Claim(
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    event Withdrawal(
        address indexed owner,
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    event ChangeVault(address vault);

    event ChangeDex(address dex);

    event ChangeDexFactory(address factory);

    event ChangeSwapPool(address pool);

    event ChangeDao(address dao);

    event ChangeCeToken(address ceToken);

    event ChangeCeTokenJoin(address ceTokenJoin);

    event ChangeCertToken(address certToken);

    event ChangeCollateralToken(address collateralToken);

    event ChangeProvider(address provider);

    event ChangePairFee(uint24 fee);

    /**
     * Methods
     */

    /**
     * Deposit
     */

    // in MATIC
    function deposit() external payable returns (uint256);

    function depositWMatic(uint256 amount) external returns (uint256);

    // // in aMATICc
    // function depositAMATICcFrom(address owner, uint256 amount)
    // external
    // returns (uint256);

    // function depositAMATICc(uint256 amount) external returns (uint256);

    /**
     * Claim
     */

    // claim in aMATICc
    function claim(address recipient) external returns (uint256);

    function claimProfit(address recipient) external;

    function getProfitFor(address account) external view returns (uint256);

    function getYieldFor(address account) external view returns(uint256);

    /**
     * Withdrawal
     */

    // MATIC
    // function withdraw(address recipient, uint256 amount)
    // external
    // returns (uint256);

    // MATIC
    // function withdrawFor(address recipient, uint256 amount)
    // external
    // returns (uint256);

    // MATIC
    function withdrawWithSlippage(
        address recipient,
        uint256 amount,
        uint256 slippage
    ) external returns (uint256);

    // // aMATICc
    // function withdrawAMATICc(address recipient, uint256 amount)
    // external
    // returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./IBaseStrategy.sol";

abstract contract BaseStrategy is IBaseStrategy, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Vars ---
    address public strategist;
    address public destination;
    address public feeRecipient;

    IERC20Upgradeable public underlying;

    bool public PLACEHOLDER_1;

    // --- Events ---
    event UpdatedStrategist(address indexed strategist);
    event UpdatedFeeRecipient(address indexed feeRecipient);

    // --- Init ---
    function __BaseStrategy_init(address _destination, address _feeRecipient, address _underlying) internal onlyInitializing {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        strategist = msg.sender;
        destination = _destination;
        feeRecipient = _feeRecipient;
        underlying = IERC20Upgradeable(_underlying);
    }

    // --- Mods ---
    modifier onlyOwnerOrStrategist() {

        require(msg.sender == owner() || msg.sender == strategist, "BaseStrategy/not-owner-or-strategist");
        _;
    }

    // --- Admin ---
    function setStrategist(address _newStrategist) external onlyOwner {

        require(_newStrategist != address(0));
        strategist = _newStrategist;

        emit UpdatedStrategist(_newStrategist);
    }
    
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        
        require(_newFeeRecipient != address(0));
        feeRecipient = _newFeeRecipient;

        emit UpdatedFeeRecipient(_newFeeRecipient);
    }

    // --- Strategist ---
    function pause() external onlyOwnerOrStrategist {

        _pause();
    }

    function unpause() external onlyOwnerOrStrategist {

        _unpause();
    }

    // --- Internal ---
    function _beforeDeposit(uint256 _amount) internal virtual returns (bool) {}

    // --- Views ---
    function balanceOfWant() public view returns(uint256) {

        return underlying.balanceOf(address(this));
    }
    function balanceOfPool() public view returns(uint256) {

        return underlying.balanceOf(address(destination));
    }
    function balanceOf() public view returns(uint256) {

        return underlying.balanceOf(address(this)) + underlying.balanceOf(address(destination));
    }

    /// @dev See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseStrategy {

    // --- Functions ---
    function deposit(uint256 _amount) external returns(uint256);
    function withdraw(address _recipient, uint256 _amount) external returns(uint256);
    function harvest() external;
    function pause() external;
    function unpause() external;
    function balanceOf() external view returns(uint256);
    function balanceOfWant() external view returns(uint256);
    function balanceOfPool() external view returns(uint256);
    function setFeeRecipient(address _newFeeRecipient) external;
    function canDeposit(uint256 _amount) external view returns(uint256 capacity, uint256 chargedCapacity);
    function canWithdraw(uint256 _amount) external view returns(uint256 capacity, uint256 chargedCapacity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseStrategy.sol";

import "../../masterVault/interfaces/IMasterVault.sol";
import "../../ceros/interfaces/ICerosRouterLs.sol";

contract CerosYieldConverterStrategyLs is BaseStrategy {

    // --- Vars ---
    IMasterVault public masterVault;

    // --- Events ---
    event DestinationChanged(address indexed _cerosRouter);

    // --- Mods ---
    modifier onlyMasterVault() {

        require(msg.sender == address(masterVault), "Strategy/not-masterVault");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    /** Initializer for upgradeability
      * @param _destination cerosRouter contract
      * @param _feeRecipient fee recipient
      * @param _underlyingToken underlying token 
      * @param _masterVault masterVault contract
      */
    function initialize(address _destination, address _feeRecipient, address _underlyingToken, address _masterVault) external initializer {

        __BaseStrategy_init(_destination, _feeRecipient, _underlyingToken);

        masterVault = IMasterVault(_masterVault);
        underlying.approve(address(_destination), type(uint256).max);
        underlying.approve(address(_masterVault), type(uint256).max);
    }

    // --- Admin ---
    /** Change destination contract
      * @param _destination new cerosRouter contract
      */
    function changeDestination(address _destination) external onlyOwner {

        require(_destination != address(0));

        underlying.approve(address(destination), 0);
        destination = _destination;
        underlying.approve(address(_destination), type(uint256).max);

        emit DestinationChanged(_destination);
    }

    // --- MasterVault ---
    /** Deposit underlying to destination contract
      * @param _amount underlying token amount
      */
    function deposit(uint256 _amount) external onlyMasterVault whenNotPaused returns(uint256 value) {

        require(_amount <= underlying.balanceOf(address(this)), "Strategy/insufficient-balance");

        return _deposit(_amount);
    }
    /** Internal -> deposits underlying to destination
      * @param _amount underlying token amount
      */
    function _deposit(uint256 _amount) internal returns (uint256 value) {

        require(_amount > 0, "Strategy/invalid-amount");

        _beforeDeposit(_amount);
        return ICerosRouterLs(destination).deposit(_amount);
    }
    /** Withdraw underlying from destination to recipient
      * @dev incase of immediate unstake, 'msg.sender' should be used instead of '_recipient'
      * @param _recipient receiver of tokens incase of delayed unstake
      * @param _amount underlying token amount
      * @return value amount withdrawn from destination
      * return delayed if true, the unstake takes time to reach receiver, thus, can't be MasterVault
      */
    function withdraw(address _recipient, uint256 _amount) external onlyMasterVault whenNotPaused returns(uint256 value) {

        return _withdraw(_recipient, _amount);
    }
    /** Internal -> withdraws underlying from destination to recipient
      * @param _recipient receiver of tokens incase of delayed unstake
      * @param _amount underlying token amount
      * @return value amount withdrawn from destination
      */
    function _withdraw(address _recipient, uint256 _amount) internal returns (uint256 value) {

        require(_amount > 0, "Strategy/invalid-amount");        
        ICerosRouterLs(destination).withdrawFor(_recipient, _amount);

        return _amount;
    }

    // --- Strategist ---
    /** Claims yield from destination in aMATICc and transfers to feeRecipient
      */
    function harvest() external onlyOwnerOrStrategist {

        _harvestTo(feeRecipient);
    }
    /** Internal -> claims yield from destination
      * @param _to receiver of yield
      */
    function _harvestTo(address _to) private returns(uint256 yield) {

        yield = ICerosRouterLs(destination).getYieldFor(address(this));
        if(yield > 0) yield = ICerosRouterLs(destination).claim(_to);

        uint256 profit = ICerosRouterLs(destination).s_profits(address(this));
        if(profit > 0) { yield += profit; ICerosRouterLs(destination).claimProfit(_to); }
    }

    // --- Views ---
    /** Returns the depositable capacity and capacity minus fees charged based on liquidity
      * @param _amount deposit amount to check
      * @return capacity deposit capacity based on liqudity @dev includes aggregated fees, e.g swap fees
      * @return chargedCapacity deposit capacity excluding fees @dev (capacity - fees) = chargedCapacity
      */
    function canDeposit(uint256 _amount) external pure override returns(uint256 capacity, uint256 chargedCapacity) {

        // No strategy fees, thus capacity == chargedCapacity == _amount
        capacity = _amount;
        chargedCapacity = _amount;
    }
    /** Returns the withdrawable capacity and capacity minus fees charged based on liquidity
      * @param _amount withdraw amount to check
      * @return capacity withdraw capacity based on liqudity @dev includes aggregated fees, e.g swap fees
      * @return chargedCapacity withdraw capacity excluding fees @dev (capacity - fees) = chargedCapacity
      */
    function canWithdraw(uint256 _amount) external pure override returns(uint256 capacity, uint256 chargedCapacity) {

        // No strategy fees, thus capacity == chargedCapacity == _amount
        capacity = _amount;
        chargedCapacity = _amount;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface ICerosRouterLs {

    // --- Events ---
    event Deposit(address indexed _account, address indexed _token, uint256 _amount, uint256 _profit);
    event Claim(address indexed _recipient, address indexed _token, uint256 _amount);
    event Withdrawal(address indexed _owner, address indexed _recipient, address indexed _token, uint256 _amount);
    event ChangeCeVault(address _vault);
    event ChangeDex(address _dex);
    event ChangePool(address _pool);
    event ChangeStrategy(address _strategy);
    event ChangePairFee(uint256 _fee);

    // --- Functions ---
    function deposit(uint256 _amount) external returns (uint256);
    function withdrawAMATICc(address _recipient, uint256 _amount) external returns (uint256);
    function claim(address _recipient) external returns (uint256);
    function claimProfit(address _recipient) external;
    function withdrawFor(address _recipient, uint256 _amount) external returns (uint256);   
    function getYieldFor(address _account) external view returns(uint256);
    function s_profits(address _account) external view returns(uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ICerosRouterLs.sol";

import "./interfaces/IVault.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IGlobalPool.sol";
import "./interfaces/ICertToken.sol";
import "./interfaces/IPriceGetter.sol";

contract CerosRouterLsEth is ICerosRouterLs, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    
    // --- Wrapper ---
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;

    // --- Vars ---
    IVault public s_ceVault;
    ISwapRouter public s_dex;
    IGlobalPool public s_pool;
    ICertToken public s_aMATICc;
    IERC20 public s_maticToken;
    address public s_strategy;
    IPriceGetter public s_priceGetter;

    uint24 public s_pairFee;

    mapping(address => uint256) public s_profits;

    // --- Mods ---
    modifier onlyOwnerOrStrategy() {

        require(msg.sender == owner() || msg.sender == s_strategy, "CerosRouter/not-owner-or-strategy");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address _aMATICc, address _maticToken, address _bondToken, address _ceVault, address _dex, uint24 _pairFee, address _pool, address _priceGetter) external initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        s_aMATICc = ICertToken(_aMATICc);
        s_maticToken = IERC20(_maticToken);
        s_ceVault = IVault(_ceVault);
        s_dex = ISwapRouter(_dex);
        s_pairFee = _pairFee;
        s_pool = IGlobalPool(_pool);
        s_priceGetter = IPriceGetter(_priceGetter);

        IERC20(s_maticToken).approve(_dex, type(uint256).max);
        IERC20(s_maticToken).approve(_pool, type(uint256).max);
        IERC20(s_aMATICc).approve(_dex, type(uint256).max);
        IERC20(s_aMATICc).approve(_bondToken, type(uint256).max);
        IERC20(s_aMATICc).approve(_pool, type(uint256).max);
        IERC20(s_aMATICc).approve(_ceVault, type(uint256).max);
    }

    // --- Users ---
    function deposit(uint256 _amount) external override nonReentrant whenNotPaused returns (uint256 value) {   

        {
            require(_amount > 0, "CerosRouter/invalid-amount");
            uint256 balanceBefore = s_maticToken.balanceOf(address(this));
            s_maticToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 balanceAfter = s_maticToken.balanceOf(address(this));
            require(balanceAfter >= balanceBefore + _amount, "CerosRouter/invalid-transfer");
        }

        // Minimum acceptable amount
        uint256 ratio = s_aMATICc.ratio();
        uint256 minAmount = safeCeilMultiplyAndDivide(_amount, ratio, 1e18);

        // From PolygonPool
        uint256 poolAmount = minAmount;

        // From Dex
        uint256 dexAmount = getAmountOut(address(s_maticToken), address(s_aMATICc), _amount);

        // Compare both
        uint256 realAmount;
        if (poolAmount >= dexAmount) {
            realAmount = poolAmount;
            s_pool.stakeAndClaimAethC{value: _amount}();
        } else {
            realAmount = swapV3(address(s_maticToken), address(s_aMATICc), _amount, minAmount, address(this));
        }

        require(realAmount >= minAmount, "CerosRouter/price-low");
        require(s_aMATICc.balanceOf(address(this)) >= realAmount, "CerosRouter/wrong-certToken-amount-in-CerosRouter");
        
        // Profits
        uint256 profit = realAmount - minAmount;
        s_profits[msg.sender] += profit;
        value = s_ceVault.depositFor(msg.sender, realAmount - profit);
        emit Deposit(msg.sender, address(s_maticToken), realAmount - profit, profit);
        return value;
    }
    function swapV3(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address recipient) private returns (uint256 amountOut) {

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            _tokenIn,               // tokenIn
            _tokenOut,              // tokenOut
            s_pairFee,              // fee
            recipient,              // recipient
            block.timestamp + 300,  // deadline
            _amountIn,              // amountIn
            _amountOutMin,          // amountOutMinimum
            0                       // sqrtPriceLimitX96
        );
        amountOut = s_dex.exactInputSingle(params);
    }

    function withdrawAMATICc(address _recipient, uint256 _amount) external override nonReentrant whenNotPaused returns (uint256 realAmount) {

        realAmount = s_ceVault.withdrawFor(msg.sender, _recipient, _amount);

        emit Withdrawal(msg.sender, _recipient, address(s_aMATICc), realAmount);
        return realAmount;
    }

    function claim(address _recipient) external override nonReentrant whenNotPaused returns (uint256 yields) {

        yields = s_ceVault.claimYieldsFor(msg.sender, _recipient);  // aMATICc

        emit Claim(_recipient, address(s_aMATICc), yields);
        return yields;
    }
    function claimProfit(address _recipient) external nonReentrant {

        uint256 profit = s_profits[msg.sender];
        require(profit > 0, "CerosRouter/no-profits");
        require(s_aMATICc.balanceOf(address(this)) >= profit, "CerosRouter/insufficient-amount");

        s_aMATICc.transfer(_recipient, profit);  // aMATICc
        s_profits[msg.sender] -= profit;

        emit Claim(_recipient, address(s_aMATICc), profit);
    }

    // --- Strategy ---
    function withdrawFor(address _recipient, uint256 _amount) external override nonReentrant whenNotPaused onlyOwnerOrStrategy returns (uint256 realAmount) {

        realAmount = s_ceVault.withdrawFor(msg.sender, address(this), _amount);
        s_pool.unstakeAETHFor(realAmount, _recipient); // aMATICc -> MATIC

        emit Withdrawal(msg.sender, _recipient, address(s_maticToken), realAmount);
        return realAmount;
    }

    // --- Internal ---
    function safeCeilMultiplyAndDivide(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {

        // Ceil (a * b / c)
        uint256 remainder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(remainder.mul(b).add(c.sub(1)).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }

    // --- Admin ---
    function pause() external onlyOwner {

        _pause();
    }
    function unpause() external onlyOwner {

        _unpause();
    }
    function changePriceGetter(address _priceGetter) external onlyOwner {

        require(_priceGetter != address(0));
        s_priceGetter = IPriceGetter(_priceGetter);
    }
    function changePairFee(uint24 _fee) external onlyOwner {

        s_pairFee = _fee;
        emit ChangePairFee(_fee);
    }
    function changeStrategy(address _strategy) external onlyOwner {

        s_strategy = _strategy;
        emit ChangeStrategy(_strategy);
    }
    function changePool(address _pool) external onlyOwner {

        s_aMATICc.approve(address(s_pool), 0);
        s_pool = IGlobalPool(_pool);
        s_aMATICc.approve(address(_pool), type(uint256).max);
        emit ChangePool(_pool);
    }
    function changeDex(address _dex) external onlyOwner {

        IERC20(s_maticToken).approve(address(s_dex), 0);
        s_aMATICc.approve(address(s_dex), 0);
        s_dex = ISwapRouter(_dex);
        IERC20(s_maticToken).approve(address(_dex), type(uint256).max);
        s_aMATICc.approve(address(_dex), type(uint256).max);
        emit ChangeDex(_dex);
    }
    function changeCeVault(address _ceVault) external onlyOwner {

        s_aMATICc.approve(address(s_ceVault), 0);
        s_ceVault = IVault(_ceVault);
        s_aMATICc.approve(address(_ceVault), type(uint256).max);
        emit ChangeCeVault(_ceVault);
    }

    // --- Views ---
    function getAmountOut(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256 amountOut) {

        if(address(s_priceGetter) == address(0)) return 0;
        else {
            amountOut = IPriceGetter(s_priceGetter).getPrice(
                _tokenIn,
                _tokenOut,
                _amountIn,
                0,
                s_pairFee
            );
        }
    }
    function getPendingWithdrawalOf(address _account) external view returns (uint256) {

        return s_pool.getPendingUnstakesOf(_account);
    }
    function getYieldFor(address _account) external view returns(uint256) {

        return s_ceVault.getYieldFor(_account);
    } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback, IPeripheryPayments{
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

interface IGlobalPool {
    function stakeAndClaimAethC() external payable;

    function unstakeAETHFor(uint256 shares, address recipient) external;

    function getPendingUnstakesOf(address claimer) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceGetter {
    function getPrice(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96,
        uint24 fee
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IVault.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/ISwapPool.sol";
import "./interfaces/IPriceGetter.sol";
import "./interfaces/ICerosRouterSp.sol";
import "./interfaces/ICertToken.sol";
import "./interfaces/IWrapped.sol";
import "../masterVault/interfaces/IMasterVault.sol";

contract CerosRouterSp is
ICerosRouterSp,
OwnableUpgradeable,
PausableUpgradeable,
ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * Variables
     */
    IVault private _vault;
    ISwapRouter private _dex;
    // Tokens
    ICertToken private _certToken; // (default aMATICc)
    address private _wMaticAddress;
    IERC20 private _ceToken; // (default ceAMATICc)
    mapping(address => uint256) private _profits;
    IMasterVault private _masterVault;
    uint24 private _pairFee;
    ISwapPool private _pool;
    IPriceGetter private _priceGetter;
    /**
     * Modifiers
     */

    function initialize(
        address certToken,
        address wMaticToken,
        address ceToken,
        address vault,
        address dexAddress,
        uint24 pairFee,
        address swapPool,
        address priceGetter
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        _certToken = ICertToken(certToken);
        _wMaticAddress = wMaticToken;
        _ceToken = IERC20(ceToken);
        _vault = IVault(vault);
        _dex = ISwapRouter(dexAddress);
        _pairFee = pairFee;
        _pool = ISwapPool(swapPool);
        _priceGetter = IPriceGetter(priceGetter);
        IERC20(wMaticToken).approve(swapPool, type(uint256).max);
        IERC20(certToken).approve(swapPool, type(uint256).max);
        IERC20(wMaticToken).approve(dexAddress, type(uint256).max);
        IERC20(certToken).approve(dexAddress, type(uint256).max);
        IERC20(certToken).approve(vault, type(uint256).max);
    }
    /**
     * DEPOSIT
     */
    function deposit()
    external
    payable
    override
    nonReentrant
    returns (uint256 value)
    {
        uint256 amount = msg.value;
        IWrapped(_wMaticAddress).deposit{value: amount}();
        return _deposit(amount);
    }

    function depositWMatic(uint256 amount) 
    external
    nonReentrant
    returns (uint256 value)
    {
        IERC20Upgradeable(_wMaticAddress).safeTransferFrom(msg.sender, address(this), amount);
        return _deposit(amount);
    }

    function _deposit(uint256 amount) internal returns (uint256 value) {
        require(amount > 0, "invalid deposit amount");
        uint256 dexAmount = getAmountOut(_wMaticAddress, address(_certToken), amount);
        // uint256 minAmount = (amount * _certToken.ratio()) / 1e18;
        (uint256 minAmount,) = _pool.getAmountOut(true, amount, false);
        uint256 realAmount;
        if(dexAmount > minAmount) {
            realAmount = swapV3(_wMaticAddress, address(_certToken), amount, minAmount, address(this));
        } else {
            realAmount = _pool.swap(true, amount, address(this));
        }

        require(realAmount >= minAmount, "price too low");

        require(
            _certToken.balanceOf(address(this)) >= realAmount,
            "insufficient amount of CerosRouter in cert token"
        );
        uint256 profit = realAmount - minAmount;
        // add profit
        _profits[msg.sender] += profit;

        value = _vault.depositFor(msg.sender, realAmount - profit);
        emit Deposit(msg.sender, _wMaticAddress, realAmount - profit, profit);
        return value;
    }

    /**
     * CLAIM
     */
    // claim yields in aMATICc
    function claim(address recipient)
    external
    override
    nonReentrant
    returns (uint256 yields)
    {
        yields = _vault.claimYieldsFor(msg.sender, recipient);
        emit Claim(recipient, address(_certToken), yields);
        return yields;
    }
    // claim profit in aMATICc
    function claimProfit(address recipient) external nonReentrant {
        uint256 profit = _profits[msg.sender];
        require(profit > 0, "has not got a profit");
        // let's check balance of CeRouter in aMATICc
        require(
            _certToken.balanceOf(address(this)) >= profit,
            "insufficient amount"
        );
        _certToken.transfer(recipient, profit);
        _profits[msg.sender] -= profit;
        emit Claim(recipient, address(_certToken), profit);
    }
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256 amountOut) {
        if(address(_priceGetter) == address(0)) {
            return 0;
        } else {
            amountOut = IPriceGetter(_priceGetter).getPrice(
                tokenIn,
                tokenOut,
                amountIn,
                0,
                _pairFee
            );
        }
    }

    // withdrawal in MATIC via DEX or Swap Pool
    function withdrawWithSlippage(
        address recipient,
        uint256 amount,
        uint256 outAmount
    ) external override nonReentrant returns (uint256 realAmount) {
        realAmount = _vault.withdrawFor(msg.sender, address(this), amount);
        uint256 dexAmount = getAmountOut(address(_certToken), _wMaticAddress, realAmount);
        uint256 amountOut;
        if(dexAmount > outAmount) {
            amountOut = swapV3(address(_certToken), _wMaticAddress, realAmount, outAmount, recipient);
        } else {
            amountOut = _pool.swap(false, realAmount, recipient);
        }
        require(amountOut >= outAmount, "price too low");
        emit Withdrawal(msg.sender, recipient, _wMaticAddress, amountOut);
        return amountOut;
    }
    function swapV3(
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 amountOutMin, 
        address recipient) private returns (uint256 amountOut) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn,                // tokenIn
            tokenOut,               // tokenOut
            _pairFee,               // fee
            recipient,              // recipient
            block.timestamp + 300,  // deadline
            amountIn,               // amountIn
            amountOutMin,           // amountOutMinimum
            0                       // sqrtPriceLimitX96
        );
        amountOut = _dex.exactInputSingle(params);
    }
    function getProfitFor(address account) external view returns (uint256) {
        return _profits[account];
    }
    function getYieldFor(address account) external view returns(uint256) {
        return _vault.getYieldFor(account);
    } 
    function changeVault(address vault) external onlyOwner {
        require(vault != address(0));
        // update allowances
        _certToken.approve(address(_vault), 0);
        _vault = IVault(vault);
        _certToken.approve(address(_vault), type(uint256).max);
        emit ChangeVault(vault);
    }
    function changeDex(address dex) external onlyOwner {
        require(dex != address(0));
        IERC20(_wMaticAddress).approve(address(_dex), 0);
        _certToken.approve(address(_dex), 0);
        _dex = ISwapRouter(dex);
        // update allowances
        IERC20(_wMaticAddress).approve(address(_dex), type(uint256).max);
        _certToken.approve(address(_dex), type(uint256).max);
        emit ChangeDex(dex);
    }
    function changeSwapPool(address swapPool) external onlyOwner {
        require(swapPool != address(0));
        IERC20(_wMaticAddress).approve(address(_pool), 0);
        _certToken.approve(address(_pool), 0);
        _pool = ISwapPool(swapPool);
        IERC20(_wMaticAddress).approve(swapPool, type(uint256).max);
        _certToken.approve(swapPool, type(uint256).max);
        emit ChangeSwapPool(swapPool);
    }
    function changeProvider(address masterVault) external onlyOwner {
        require(masterVault != address(0));
        _masterVault = IMasterVault(masterVault);
        emit ChangeProvider(masterVault);
    }
    function changePairFee(uint24 fee) external onlyOwner {
        _pairFee = fee;
        emit ChangePairFee(fee);
    }
    function changePriceGetter(address priceGetter) external onlyOwner {
        require(priceGetter != address(0));
        _priceGetter = IPriceGetter(priceGetter);
    }
    function getCeToken() external view returns(address) {
        return address(_ceToken);
    }
    function getWMaticAddress() external view returns(address) {
        return _wMaticAddress;
    }
    function getCertToken() external view returns(address) {
        return address(_certToken);
    }
    function getPoolAddress() external view returns(address) {
        return address(_pool);
    }
    function getDexAddress() external view returns(address) {
        return address(_dex);
    }
    function getVaultAddress() external view returns(address) {
        return address(_vault);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWrapped is IERC20Upgradeable {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/IWaitingPool.sol";

import "./interfaces/IMasterVault.sol";

contract WaitingPool is IWaitingPool, Initializable {

    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Vars ---
    struct Person {
        address _address;
        uint256 _debt;
        bool _settled;
    }

    IMasterVault public masterVault;
    Person[] public people;
    uint256 public index;
    uint256 public totalDebt;
    uint256 public capLimit;
    
    bool public lock;

    address public underlying;


    // --- Events ---
    event WithdrawPending(address user, uint256 amount);
    event WithdrawCompleted(address user, uint256 amount);

    // --- Mods ---
    modifier onlyMasterVault() {

        require(msg.sender == address(masterVault));
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    /** Initializer for upgradeability
      * @param _masterVault masterVault contract
      * @param _underlyingToken ERC20 underlying
      * @param _capLimit number of indices to be payed in one call
      */
    function initialize(address _masterVault, address _underlyingToken, uint256 _capLimit) external initializer {

        require(_capLimit > 0, "WaitingPool/invalid-cap");

        masterVault = IMasterVault(_masterVault);
        underlying = _underlyingToken;
        capLimit = _capLimit;
    }

    // --- MasterVault ---
    /** Adds withdrawer from MasterVault to queue
      * @param _person address of withdrawer from MasterVault
      * @param _debt amount of withdrawal
      */
    function addToQueue(address _person, uint256 _debt) external onlyMasterVault {

        if(_debt != 0) {
            Person memory p = Person({_address: _person, _settled: false, _debt: _debt});
            totalDebt += _debt;
            people.push(p);

            emit WithdrawPending(_person, _debt);
        }
    }
    /** Try paying outstanding debt of users and settle flag to success
      */
    function tryRemove() external onlyMasterVault {

        uint256 balance;
        uint256 cap = 0;
        for(uint256 i = index; i < people.length; i++) {
            balance = getPoolBalance();
            uint256 userDebt = people[index]._debt;
            address userAddr = people[index]._address;
            if(balance >= userDebt && userDebt != 0 && !people[index]._settled && cap < capLimit) {
                totalDebt -= userDebt;
                people[index]._settled = true;
                emit WithdrawCompleted(userAddr, userDebt);

                cap++;
                index++;

                IERC20Upgradeable(underlying).safeTransfer(userAddr, userDebt);
            } else return;
        }
    }
    /** Sets a new cap limit per tryRemove()
      * @param _capLimit new cap limit
      */
    function setCapLimit(uint256 _capLimit) external onlyMasterVault {

        require(_capLimit != 0, "WaitingPool/invalid-cap");
        
        capLimit = _capLimit;
    }

    // --- User ---
    /** Users can manually withdraw their funds if they were not transferred in tryRemove()
      */
    function withdrawUnsettled(uint256 _index) external {
        require(!lock, "reentrancy");
        lock = true;

        address src = msg.sender;
        require(!people[_index]._settled && _index < index && people[_index]._address == src, "WaitingPool/already-settled");

        uint256 withdrawAmount = people[_index]._debt;
        totalDebt -= withdrawAmount;
        people[_index]._settled = true;

        IERC20Upgradeable(underlying).safeTransfer(src, withdrawAmount);
        lock = false;
        emit WithdrawCompleted(src, withdrawAmount);
    }

    // --- Views ---
    function getPoolBalance() public view returns(uint256) {

        return IERC20Upgradeable(underlying).balanceOf(address(this));
    }
    function getUnbackedDebt() external view returns(uint256) {

        return IERC20Upgradeable(underlying).balanceOf(address(this)) < totalDebt ? totalDebt - getPoolBalance() : 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWaitingPool {

    // --- Funtions ---
    function addToQueue(address, uint256) external;
    function tryRemove() external;
    function getPoolBalance() external view returns(uint256);
    function getUnbackedDebt() external view returns(uint256);
    function setCapLimit(uint256) external; 
    function totalDebt() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IMasterVault.sol";

import "./interfaces/IWaitingPool.sol";
import "../strategies/IBaseStrategy.sol";

// --- Vault with instances per Underlying to generate yield via strategies ---
contract MasterVault is IMasterVault, ERC4626Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // ---------------
    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ------------
    // --- Vars --- 'PLACEHOLDER_' slot unused
    IWaitingPool public waitingPool;  // Pending withdraw contract
    address private PLACEHOLDER_1;

    address public feeReceiver;
    address public provider;          // DavosProvider
    address private PLACEHOLDER_2;

    uint256 public depositFee;
    uint256 public maxDepositFee;
    uint256 public withdrawalFee;
    uint256 public maxWithdrawalFee;
    uint256 public MAX_STRATEGIES;
    uint256 public totalDebt;         // Underlying Tokens in all Strategies
    uint256 public feeEarned;
    address[] public strategies;

    mapping(address => bool) public manager;
    mapping(address => StrategyParams) public strategyParams;

    uint256 private PLACEHOLDER_3;
    uint256 public allocateOnDeposit;


    // ------------
    // --- Mods ---
    modifier onlyOwnerOrProvider() {
        require(msg.sender == owner() || msg.sender == provider, "MasterVault/not-owner-or-provider");
        _;
    }
    modifier onlyOwnerOrManager() {
        require(msg.sender == owner() || manager[msg.sender], "MasterVault/not-owner-or-manager");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // ------------
    // --- Init ---
    /** Initializer for upgradeability
      * @param _asset underlying asset
      * @param _name name of MasterVault token
      * @param _symbol symbol of MasterVault token
      * @param _maxDepositFees fees charged in parts per million; 1% = 10000ppm
      * @param _maxWithdrawalFees fees charged in parts per million; 1% = 10000ppm
      * @param _maxStrategies number of maximum strategies
      */
    function initialize(address _asset, string memory _name, string memory _symbol, uint256 _maxDepositFees, uint256 _maxWithdrawalFees, uint8 _maxStrategies) external initializer {
        
        require(_maxDepositFees > 0 && _maxDepositFees <= 1e6, "MasterVault/invalid-maxDepositFee");
        require(_maxWithdrawalFees > 0 && _maxWithdrawalFees <= 1e6, "MasterVault/invalid-maxWithdrawalFees");

        __ERC4626_init(IERC20MetadataUpgradeable(_asset));
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        
        maxDepositFee = _maxDepositFees;
        maxWithdrawalFee = _maxWithdrawalFees;
        MAX_STRATEGIES = _maxStrategies;

        feeReceiver = msg.sender;
    }

    // ----------------
    // --- Deposits ---
    /** Deposit underlying assets via DavosProvider
      * @param _amount amount of Underlying Token deposit
      * @return shares corresponding MasterVault tokens
      */
    function depositUnderlying(address _account, uint256 _amount) external override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256 shares) {

        require(_amount > 0, "MasterVault/invalid-amount");
        address src = msg.sender;

        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(asset()), src, address(this), _amount);
        shares = _assessFee(_amount, depositFee);

        uint256 waitingPoolDebt = waitingPool.totalDebt();
        uint256 waitingPoolBalance = IERC20Upgradeable(asset()).balanceOf(address(waitingPool));
        if(waitingPoolDebt > 0 && waitingPoolBalance < waitingPoolDebt) {
            uint256 waitingPoolDebtDiff = waitingPoolDebt - waitingPoolBalance;
            uint256 poolAmount = (waitingPoolDebtDiff < shares) ? waitingPoolDebtDiff : shares;
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), poolAmount);
        }

        _mint(src, shares);

        if(allocateOnDeposit == 1) allocate();

        emit Deposit(src, src, _amount, shares);
    }
    /** Deposit underlying tokens into strategy
      * @param _strategy address of strategy
      * @param _amount amount of Underlying Token deposit
      */
    function depositToStrategy(address _strategy, uint256 _amount) public onlyOwnerOrManager {

        require(_depositToStrategy(_strategy, _amount));
    }
    /** Deposit all underlying tokens into strategy
      * @param _strategy address of strategy
      */
    function depositAllToStrategy(address _strategy) public onlyOwnerOrManager {

        require(_depositToStrategy(_strategy, totalAssetInVault()));
    }
    /** Internal -> deposits underlying to strategy
      * @param _strategy address of strategy
      * @param _amount amount of Underlying Token deposit
      * @return success finality state of deposit
      */
    function _depositToStrategy(address _strategy, uint256 _amount) private returns (bool success) {

        require(_amount > 0, "MasterVault/invalid-amount");
        require(strategyParams[_strategy].active, "MasterVault/invalid-strategy");
        require(totalAssetInVault() >= _amount, "MasterVault/insufficient-balance");

        // 'capacity' is total depositable; 'chargedCapacity' is capacity after charging fee
        (uint256 capacity, uint256 chargedCapacity) = IBaseStrategy(_strategy).canDeposit(_amount);
        if(capacity <= 0 || capacity > _amount || chargedCapacity > capacity) return false;

        totalDebt += chargedCapacity;
        strategyParams[_strategy].debt += chargedCapacity;

        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), _strategy, capacity);
        IBaseStrategy(_strategy).deposit(capacity);
        
        emit DepositedToStrategy(_strategy, capacity, chargedCapacity);
        return true;
    }
    /** Deposits underlying to active strategies based on allocation points
      * @dev Useful incase of deposits to avoid unnecessary swapFees
      */
    function allocate() public {
        for(uint8 i = 0; i < strategies.length; i++) {
            if(strategyParams[strategies[i]].active) {
                StrategyParams memory strategy =  strategyParams[strategies[i]];
                uint256 allocation = strategy.allocation;
                if(allocation > 0) {
                    uint256 totalAssetAndDebt = totalAssetInVault() + totalDebt;
                    uint256 strategyRatio = (strategy.debt * 1e6) / totalAssetAndDebt;
                    if(strategyRatio < allocation) {
                        uint256 depositAmount = ((totalAssetAndDebt * allocation) / 1e6) - strategy.debt;
                        if(totalAssetInVault() > depositAmount && depositAmount > 0) {
                            _depositToStrategy(strategies[i], depositAmount);
                        }
                    }
                }
            }
        }
    }

    // -----------------
    // --- Withdraws ---
    /** Withdraw underlying assets via DavosProvider
      * @param _account receipient
      * @param _amount underlying assets to withdraw
      * @return assets underlying assets excluding any fees
      */
    function withdrawUnderlying(address _account, uint256 _amount) external override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256 assets) {

        require(_amount > 0, "MasterVault/invalid-amount");
        address src = msg.sender;
        assets = _amount;

        _burn(src, _amount);

        uint256 underlyingBalance = totalAssetInVault();
        if(underlyingBalance < _amount) {

          uint256 debt = waitingPool.getUnbackedDebt();
          Type class = debt == 0 ? Type.ABSTRACT : Type.IMMEDIATE;
          
          (uint256 withdrawn, bool incomplete, bool delayed) = _withdrawFromActiveStrategies(_account, _amount + debt - underlyingBalance, class);

          if(withdrawn == 0 || debt != 0 || incomplete) {
            assets = _assessFee(assets, withdrawalFee);
            waitingPool.addToQueue(_account, assets);
            if(totalAssetInVault() > 0) 
              SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), underlyingBalance);
            emit Withdraw(src, src, src, assets, _amount);
            return _amount;
          } else if(delayed) {
            assets = underlyingBalance;
          } else {
            assets = underlyingBalance + withdrawn;
          }
        }

        assets = _assessFee(assets, withdrawalFee);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), _account, assets);

        emit Withdraw(src, src, src, assets, _amount);
        return _amount;
    }
    /** Withdraw underlying assets from Strategy
      * @param _strategy address of strategy
      * @param _amount underlying assets to withdraw from strategy
      */
    function withdrawFromStrategy(address _strategy, uint256 _amount) public onlyOwnerOrManager {

        (uint256 withdrawn,) = _withdrawFromStrategy(address(this), _strategy, _amount);
        require(withdrawn > 0, "MasterVault/unable-to-withdraw");
    }
    /** Withdraw all underlying assets from Strategy
      * @param _strategy address of strategy
      */
    function withdrawAllFromStrategy(address _strategy) external onlyOwnerOrManager {

        (uint256 withdrawn,) = _withdrawFromStrategy(address(this), _strategy, strategyParams[_strategy].debt);
        require(withdrawn > 0, "MasterVault/unable-to-withdraw");
    }
    /** Internal -> withdraws underlying from strategy
      * @param _recipient direct receiver if strategy has unstake time
      * @param _strategy address of strategy
      * @param _amount amount of Underlying Token withdrawal
      * @return bool amount of Underlying Tokens withdrawn
      * @return incomplete 'true' if withdrawn amount less than '_amount'
      */
    function _withdrawFromStrategy(address _recipient, address _strategy, uint256 _amount) private returns(uint256, bool incomplete) {

        require(_amount > 0, "MasterVault/invalid-amount");
        require(strategyParams[_strategy].debt >= _amount, "MasterVault/insufficient-assets-in-strategy");

        StrategyParams memory params = strategyParams[_strategy];
        (uint256 capacity, uint256 chargedCapacity) = IBaseStrategy(_strategy).canWithdraw(_amount);
        if(capacity <= 0 || chargedCapacity > capacity) return (0, false);
        else if(capacity < _amount) incomplete = true;

        if(params.class == Type.DELAYED && incomplete) return (0, true);

        totalDebt -= capacity;
        strategyParams[_strategy].debt -= capacity;

        uint256 value = IBaseStrategy(_strategy).withdraw(_recipient, capacity);

        require(value >= chargedCapacity, "MasterVault/preview-withdrawn-mismatch");

        emit WithdrawnFromStrategy(_strategy, _amount, chargedCapacity);
        return (chargedCapacity, incomplete);
    }
    /** Internal -> traverses through all active strategies for withdrawal
      * @param _recipient direct receiver if strategy has unstake time
      * @param _amount amount of Underlying Tokens withdrawal
      */
    function _withdrawFromActiveStrategies(address _recipient, uint256 _amount, Type class) private returns(uint256 withdrawn, bool incomplete, bool delayed) {

        for(uint8 i = 0; i < strategies.length; i++) {
            if(strategyParams[strategies[i]].active && (strategyParams[strategies[i]].class == class || class == Type.ABSTRACT) && strategyParams[strategies[i]].debt >= _amount) {
              _recipient = strategyParams[strategies[i]].class == Type.DELAYED ? _recipient : address(this);
              delayed = strategyParams[strategies[i]].class == Type.DELAYED ? true : false;
              (withdrawn, incomplete) = _withdrawFromStrategy(_recipient, strategies[i], _amount);
            }
        }
    }
    /** Internal -> charge corresponding fees from amount
      * @param amount amount to charge fee from
      * @param fees fee percentage
      * @return value amount after fee charge
      */
    function _assessFee(uint256 amount, uint256 fees) private returns(uint256 value) {

        if(fees > 0) {
            uint256 fee = (amount * fees) / 1e6;
            value = amount - fee;
            feeEarned += fee;
        } else return amount;
    }

    // ---------------
    // --- Manager ---
    /** Withdraws all assets from strategy marking it inactive
      * @param _strategy address of strategy 
      */
    function retireStrat(address _strategy) external onlyOwnerOrManager {

        if(_deactivateStrategy(_strategy)) return;

        _withdrawFromStrategy(address(this), _strategy, strategyParams[_strategy].debt);
        require(_deactivateStrategy(_strategy), "MasterVault/cannot-retire");
    }
    /** Withdraws all assets from old strategy to new strategy
      * @notice allocate() must be triggered afterwards
      * @notice old strategy might have unstake delay
      * @param _oldStrategy address of old strategy
      * @param _newStrategy address of new strategy 
      * @param _newAllocation underlying assets allocation to '_newStrategy' where 1% = 10000
      */
    function migrateStrategy(address _oldStrategy, address _newStrategy, uint256 _newAllocation, Type _class) external onlyOwnerOrManager {

        require(_oldStrategy != address(0) && _newStrategy != address(0));

        uint256 oldStrategyDebt = strategyParams[_oldStrategy].debt;
        if(oldStrategyDebt > 0) {
            (uint256 withdrawn,) = _withdrawFromStrategy(address(this), _oldStrategy, oldStrategyDebt);
            require(withdrawn > 0, "MasterVault/cannot-withdraw");
        }

        StrategyParams memory params = StrategyParams({active: true, class: _class, allocation: _newAllocation, debt: 0});

        bool isValidStrategy;
        for(uint256 i = 0; i < strategies.length; i++) {
            if(strategies[i] == _oldStrategy) {
                isValidStrategy = true;
                strategies[i] = _newStrategy;
                strategyParams[_newStrategy] = params;
                
                break;
            }
        }

        require(isValidStrategy, "MasterVault/invalid-oldStrategy");
        require(_deactivateStrategy(_oldStrategy),"MasterVault/cannot-deactivate");
        require(_isValidAllocation(), "MasterVault/>100%");

        emit StrategyMigrated(_oldStrategy, _newStrategy, _newAllocation);
    }
    /** Internal -> checks strategy's debt and deactives it
      * @param _strategy address of strategy 
      */
    function _deactivateStrategy(address _strategy) private returns(bool success) {

        if (strategyParams[_strategy].debt <= 10) {
            strategyParams[_strategy].active = false;
            strategyParams[_strategy].debt = 0;
            return true;
        }
    }
    /** Internal -> Sums up all individual allocation to match total
      */
    function _isValidAllocation() private view returns(bool) {

        uint256 totalAllocations;
        for(uint256 i = 0; i < strategies.length; i++) {
            if(strategyParams[strategies[i]].active) {
                totalAllocations += strategyParams[strategies[i]].allocation;
            }
        }

        return totalAllocations <= 1e6;
    }
    /** Sends required Underlying Token amount to waitingPool to equalize debt
      * @notice '_withdrawFromActiveStrategies' might have strategy with unstake delay
      */
    function cancelDebt(Type _class) public onlyOwnerOrManager {

        uint256 withdrawn; bool delayed;

        uint256 waitingPoolDebt = waitingPool.totalDebt();
        uint256 waitingPoolBal = IERC20Upgradeable(asset()).balanceOf(address(waitingPool));
        if (waitingPoolDebt > waitingPoolBal) {
          uint256 withdrawAmount = waitingPoolDebt - waitingPoolBal;
          if (totalAssetInVault() >= withdrawAmount) {
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), withdrawAmount);
          } else {
            (withdrawn,,delayed) = _withdrawFromActiveStrategies(address(waitingPool), withdrawAmount + 1, _class);
            uint256 amount = totalAssetInVault();
            if(withdrawn > 0 && !delayed) amount += withdrawn;
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), address(waitingPool), amount);
          }
        }
    }
    /** Triggers tryRemove() of waiting pool contract
      */
    function tryRemove() public onlyOwnerOrManager {

        waitingPool.tryRemove();
    }

    // -------------
    // --- Admin ---
    /** Adds a new strategy
      * @param _strategy address of strategy 
      * @param _allocation underlying assets allocation to '_strategy' where 1% = 10000
      */
    function addStrategy(address _strategy, uint256 _allocation, Type _class) external onlyOwner {

        require(_strategy != address(0));
        require(strategies.length < MAX_STRATEGIES, "MasterVault/strategies-maxed");

        uint256 totalAllocations;
        for(uint256 i = 0; i < strategies.length; i++) {
            if(strategies[i] == _strategy) revert("MasterVault/already-exists");
            if(strategyParams[strategies[i]].active) totalAllocations += strategyParams[strategies[i]].allocation;
        }

        require(totalAllocations + _allocation <= 1e6, "MasterVault/>100%");

        StrategyParams memory params = StrategyParams({active: true, class: _class, allocation: _allocation, debt: 0});

        strategyParams[_strategy] = params;
        strategies.push(_strategy);
        emit StrategyAdded(_strategy, _allocation);
    }
    /** Changes allocation of Strategy
      * @param _strategy address of strategy 
      * @param _allocation underlying assets new allocation to '_strategy' where 1% = 10000
      */
    function changeStrategyAllocation(address _strategy, uint256 _allocation) external onlyOwner {

        require(_strategy != address(0));        
        strategyParams[_strategy].allocation = _allocation;
        require(_isValidAllocation(), "MasterVault/>100%");

        emit StrategyAllocationChanged(_strategy, _allocation);
    }
    /** Withdraw fees to feeReceiver
      */
    function withdrawFee() external onlyOwner{

        if(feeEarned > 0) {
            uint256 toSend = feeEarned;
            feeEarned = 0;
            SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(asset()), feeReceiver, toSend);
        }
    }
    /** Changes allocation mode on deposit
      * @param _status 0-Disabled, 1-Enabled
      */
    function changeAllocateOnDeposit(uint256 _status) external onlyOwner {

        require(_status >= 0 && _status < 2, "MasterVault/range-0-or-1");
        allocateOnDeposit = _status;

        emit AllocationOnDepositChangeed(_status);
    }
    /** Sets a deposit fee where 1% = 10000ppm
      * @param _newDepositFee new deposit fee percentage
      */
    function setDepositFee(uint256 _newDepositFee) external onlyOwner {

        require(maxDepositFee > _newDepositFee,"MasterVault/more-than-maxDepositFee");
        depositFee = _newDepositFee;

        emit DepositFeeChanged(_newDepositFee);
    }
    /** Sets a withdrawal fee where 1% = 10000ppm
      * @param _newWithdrawalFee new withdrawal fee percentage
      */
    function setWithdrawalFee(uint256 _newWithdrawalFee) external onlyOwner {

        require(maxWithdrawalFee > _newWithdrawalFee,"MasterVault/more-than-maxWithdrawalFee");
        withdrawalFee = _newWithdrawalFee;

        emit WithdrawalFeeChanged(_newWithdrawalFee);
    }
    /** Changes provider contract
      * @param _provider new provider
      */
    function changeProvider(address _provider) external onlyOwner {

        require(_provider != address(0));
        provider = _provider;

        emit ProviderChanged(_provider);
    }
    /** Sets waiting pool contract
      * @param _waitingPool new waiting pool address
      */
    function setWaitingPool(address _waitingPool) external onlyOwner {

        require(_waitingPool != address(0));
        waitingPool = IWaitingPool(_waitingPool);

        emit WaitingPoolChanged(_waitingPool);
    }
    /** Sets waiting pool cap
      * @param _cap new cap limit
      */
    function setWaitingPoolCap(uint256 _cap) external onlyOwner {

        waitingPool.setCapLimit(_cap);

        emit WaitingPoolCapChanged(_cap);
    }
    /** Changes fee receiver
      * @param _feeReceiver new fee receiver
      */
    function changeFeeReceiver(address _feeReceiver) external onlyOwner {

        require(_feeReceiver != address(0));
        feeReceiver = _feeReceiver;

        emit FeeReceiverChanged(_feeReceiver);
    }
    /** Adds a new manager
      * @param _newManager new manager
      */
    function addManager(address _newManager) external onlyOwner {

        require(_newManager != address(0));
        manager[_newManager] = true;

        emit ManagerAdded(_newManager);
    }
    /** Removes an existing manager
      * @param _manager new manager
      */
    function removeManager(address _manager) external onlyOwner {

        require(manager[_manager]);
        manager[_manager] = false;

        emit ManagerRemoved(_manager);
    } 
    /** Pauses MasterVault contract
      */
    function pause() external onlyOwner whenNotPaused {

        _pause();
    }
    /** Unpauses MasterVault contract
    */
    function unpause() external onlyOwner whenPaused {

        _unpause();
    }

    // -------------
    // --- Views ---
    /** Returns the amount of assets that can be withdrawn instantly
      * @return available amount of assets
      */
    function availableToWithdraw() public view returns(uint256 available) {

        for(uint8 i = 0; i < strategies.length; i++) available += IERC20Upgradeable(asset()).balanceOf(strategies[i]);
        available += totalAssetInVault();
    }
    /** Returns the amount of underlying assets in MasterVault excluding feeEarned
      * @return balance amount of assets
      */
    function totalAssetInVault() public view returns(uint256 balance) {

        return (totalAssets() > feeEarned) ? totalAssets() - feeEarned : 0;
    }

    // ---------------
    // --- ERC4626 ---
    /** Kept only for the sake of ERC4626 standard
      */
    function deposit(uint256 assets, address receiver) public override returns (uint256) { revert(); }
    function mint(uint256 shares, address receiver) public override returns (uint256) { revert(); }
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) { revert(); }
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) { revert(); }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/extensions/ERC4626.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../utils/SafeERC20Upgradeable.sol";
import "../../../interfaces/IERC4626Upgradeable.sol";
import "../../../utils/math/MathUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC4626 "Tokenized Vault Standard" as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[EIP-4626].
 *
 * This extension allows the minting and burning of "shares" (represented using the ERC20 inheritance) in exchange for
 * underlying "assets" through standardized {deposit}, {mint}, {redeem} and {burn} workflows. This contract extends
 * the ERC20 standard. Any additional extensions included along it would affect the "shares" token represented by this
 * contract and not the "assets" token which is an independent contract.
 *
 * CAUTION: Deposits and withdrawals may incur unexpected slippage. Users should verify that the amount received of
 * shares or assets is as expected. EOAs should operate through a wrapper that performs these checks such as
 * https://github.com/fei-protocol/ERC4626#erc4626router-and-base[ERC4626Router].
 *
 * _Available since v4.7._
 */
abstract contract ERC4626Upgradeable is Initializable, ERC20Upgradeable, IERC4626Upgradeable {
    using MathUpgradeable for uint256;

    IERC20MetadataUpgradeable private _asset;

    /**
     * @dev Set the underlying asset contract. This must be an ERC20-compatible contract (ERC20 or ERC777).
     */
    function __ERC4626_init(IERC20MetadataUpgradeable asset_) internal onlyInitializing {
        __ERC4626_init_unchained(asset_);
    }

    function __ERC4626_init_unchained(IERC20MetadataUpgradeable asset_) internal onlyInitializing {
        _asset = asset_;
    }

    /** @dev See {IERC4262-asset}. */
    function asset() public view virtual override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4262-totalAssets}. */
    function totalAssets() public view virtual override returns (uint256) {
        return _asset.balanceOf(address(this));
    }

    /** @dev See {IERC4262-convertToShares}. */
    function convertToShares(uint256 assets) public view virtual override returns (uint256 shares) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4262-convertToAssets}. */
    function convertToAssets(uint256 shares) public view virtual override returns (uint256 assets) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4262-maxDeposit}. */
    function maxDeposit(address) public view virtual override returns (uint256) {
        return _isVaultCollateralized() ? type(uint256).max : 0;
    }

    /** @dev See {IERC4262-maxMint}. */
    function maxMint(address) public view virtual override returns (uint256) {
        return type(uint256).max;
    }

    /** @dev See {IERC4262-maxWithdraw}. */
    function maxWithdraw(address owner) public view virtual override returns (uint256) {
        return _convertToAssets(balanceOf(owner), MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4262-maxRedeem}. */
    function maxRedeem(address owner) public view virtual override returns (uint256) {
        return balanceOf(owner);
    }

    /** @dev See {IERC4262-previewDeposit}. */
    function previewDeposit(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4262-previewMint}. */
    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Up);
    }

    /** @dev See {IERC4262-previewWithdraw}. */
    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        return _convertToShares(assets, MathUpgradeable.Rounding.Up);
    }

    /** @dev See {IERC4262-previewRedeem}. */
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, MathUpgradeable.Rounding.Down);
    }

    /** @dev See {IERC4262-deposit}. */
    function deposit(uint256 assets, address receiver) public virtual override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /** @dev See {IERC4262-mint}. */
    function mint(uint256 shares, address receiver) public virtual override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4262-withdraw}. */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4262-redeem}. */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     *
     * Will revert if assets > 0, totalSupply > 0 and totalAssets = 0. That corresponds to a case where any asset
     * would represent an infinite amout of shares.
     */
    function _convertToShares(uint256 assets, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256 shares) {
        uint256 supply = totalSupply();
        return
            (assets == 0 || supply == 0)
                ? assets.mulDiv(10**decimals(), 10**_asset.decimals(), rounding)
                : assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, MathUpgradeable.Rounding rounding) internal view virtual returns (uint256 assets) {
        uint256 supply = totalSupply();
        return
            (supply == 0)
                ? shares.mulDiv(10**_asset.decimals(), 10**decimals(), rounding)
                : shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        // If _asset is ERC777, `transferFrom` can trigger a reenterancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transfered and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20Upgradeable.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transfered, which is a valid state.
        _burn(owner, shares);
        SafeERC20Upgradeable.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    function _isVaultCollateralized() private view returns (bool) {
        return totalAssets() > 0 || totalSupply() == 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";
import "../token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626Upgradeable is IERC20Upgradeable, IERC20MetadataUpgradeable {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IMasterVault_V2.sol";

import "./interfaces/ILiquidAsset.sol";

// --- MasterVault_V2 (Variant 2) ---
// --- Vault with instances per Liquid Staked Underlying to generate yield via ratio change and strategies ---
contract MasterVault_V2 is IMasterVault_V2, ERC4626Upgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // --- Wrappers ---
    using SafeERC20Upgradeable for ILiquidAsset;

    // --- Constants ---

    // --- Vars ---
    address public provider;          // DavosProvider
    address public yieldHeritor;      // Yield Recipient
    uint256 public yieldMargin;       // Percentage of Yield protocol gets, 10,000 = 100%
    uint256 public yieldBalance;      // Balance at which Yield for protocol was last claimed
    uint256 public underlyingBalance; // Total balance of underlying asset

    // --- Mods ---
    modifier onlyOwnerOrProvider() {
        require(msg.sender == owner() || msg.sender == provider, "MasterVault_V2/not-owner-or-provider");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(string memory _name, string memory _symbol, uint256 _yieldMargin, address _underlying) external initializer {

        __ERC4626_init(IERC20MetadataUpgradeable(_underlying));
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        yieldMargin = _yieldMargin;
        yieldBalance = 0;
    }

    // --- Provider ---
    function deposit(uint256 assets, address receiver) public override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256) {

        address src = _msgSender();

        require(assets > 0, "MasterVault_V2/invalid-amount");
        require(receiver != address(0), "MasterVault_V2/0-address");
        require(assets <= maxDeposit(src), "MasterVault_V2/deposit-more-than-max");

        _claimYield();
        uint256 shares = previewDeposit(assets);
        _deposit(src, src, assets, shares);

        underlyingBalance += assets;
        yieldBalance = getBalance();

        return shares;
    }
    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant whenNotPaused onlyOwnerOrProvider returns (uint256) {

        address src = _msgSender();

        require(shares <= maxRedeem(owner), "MasterVault_V2/withdraw-more-than-max");
        require(receiver != address(0), "MasterVault_V2/0-address");

        uint256 assets = previewRedeem(shares);
        _claimYield();

        underlyingBalance -= assets;
        yieldBalance = getBalance();
        _withdraw(owner, receiver, owner, assets, shares);

        return assets;
    }

    function claimYield() public returns (uint256) {
        uint256 yield = _claimYield();
        yieldBalance = getBalance();
        return yield;
    }

    function _claimYield() internal returns (uint256) {
        uint256 availableYields = getVaultYield();
        if (availableYields <= 0) return 0;

        ILiquidAsset _asset = ILiquidAsset(asset());
        _asset.safeTransfer(yieldHeritor, availableYields);
        underlyingBalance -= availableYields;

        emit Claim(address(this), yieldHeritor, availableYields);
        return availableYields;
    }
    
    // --- Admin ---
    function changeProvider(address _provider) external onlyOwnerOrProvider {

        require(_provider != address(0), "MasterVault_V2/0-address");
        provider = _provider;

        emit Provider(provider, _provider);
    }
    function changeYieldHeritor(address _yieldHeritor) external onlyOwnerOrProvider {

        require(_yieldHeritor != address(0), "MasterVault_V2/0-address");
        yieldHeritor = _yieldHeritor;

        emit YieldHeritor(yieldHeritor, _yieldHeritor);
    }
    function changeYieldMargin(uint256 _yieldMargin) external onlyOwnerOrProvider {

        require(_yieldMargin <= 1e4, "MasterVault_V2/should-be-less-than-max");
        yieldMargin = _yieldMargin;

        emit YieldMargin(yieldMargin, _yieldMargin);
    }
    
    // --- Views ---
    function getVaultYield() public view returns (uint256) {
        uint256 totalBalance = getBalance();
        if (totalBalance <= yieldBalance) return 0;

        uint256 diffBalance = totalBalance - yieldBalance;

        uint256 yield = diffBalance * yieldMargin / 1e4;

        return ILiquidAsset(asset()).getWstETHByStETH(yield);
    }

    function totalAssets() public view virtual override returns (uint256) {
        return underlyingBalance - getVaultYield();
    }

    function getBalance() public view returns (uint256) {
        return ILiquidAsset(asset()).getStETHByWstETH(underlyingBalance);
    }

    // ---------------
    // --- ERC4626 ---
    /** Kept only for the sake of ERC4626 standard
      */
    function mint(uint256 shares, address receiver) public override returns (uint256) { revert(); }
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) { revert(); }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterVault_V2 {

    // --- Events ---
    event Claim(address indexed owner, address indexed receiver, uint256 yield);
    event Provider(address oldProvider, address newProvider);
    event YieldHeritor(address oldHeritor, address newHeritor);
    event YieldMargin(uint256 oldMargin, uint256 newMargin);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ILiquidAsset is IERC20Upgradeable {
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);

    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DGTToken is ERC20PausableUpgradeable {

    event MintedRewardsSupply(address rewardsContract, uint256 amount);

    address public rewards;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth {
        require(usr != address(0), "DgtToken/invalid-address");
        wards[usr] = 1;
    }
    function deny(address usr) external auth {
        require(usr != address(0), "DgtToken/invalid-address");
        wards[usr] = 0;
    }
    modifier auth {
        require(wards[msg.sender] == 1, "DgtToken/not-authorized");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    function initialize(uint256 rewardsSupply_, address rewards_) external initializer {
        __ERC20_init_unchained("Dgt Reward token", "DGT");
        __ERC20Pausable_init();
        wards[msg.sender] = 1;
        rewards = rewards_;
        _mint(rewards, rewardsSupply_);

        emit MintedRewardsSupply(rewards, rewardsSupply_);
    }

    function mint(address _to, uint256 _amount) external auth returns(bool) {
        require(_to != rewards, "DgtToken/rewards-oversupply");
        _mint(_to, _amount);
        return true;
    }

    function burn(uint256 _amount) external returns(bool) {
        _burn(msg.sender, _amount);
        return true;
    }

    function pause() external auth {
        _pause();
    }
    
    function unpause() external auth {
        _unpause();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC4626Upgradeable.sol";

import "./interfaces/IDavosProvider.sol";

import "./interfaces/ICertToken.sol";
import "./interfaces/IInteraction.sol";
import "./interfaces/IWrapped.sol";

// --- Wrapping adaptor with instances per Underlying for MasterVault ---
contract DavosProvider is IDavosProvider, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    // --- Wrapper --- 'PLACEHOLDER_' slot unused
    using SafeERC20Upgradeable for IWrapped;

    // --- Vars ---
    IERC20Upgradeable public collateral;     // ceToken in MasterVault
    ICertToken public collateralDerivative;
    IERC4626Upgradeable public masterVault;
    IInteraction public interaction;
    address public PLACEHOLDER_1;
    IWrapped public underlying;              // isNative then Wrapped, else ERC20
    bool public isNative;

    // --- Mods ---
    modifier onlyOwnerOrInteraction() {

        require(msg.sender == owner() || msg.sender == address(interaction), "DavosProvider/not-interaction-or-owner");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }
    
    // --- Init ---
    function initialize(address _underlying, address _collateralDerivative, address _masterVault, address _interaction, bool _isNative) external initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        underlying = IWrapped(_underlying);
        collateral = IERC20Upgradeable(_masterVault);
        collateralDerivative = ICertToken(_collateralDerivative);
        masterVault = IERC4626Upgradeable(_masterVault);
        interaction = IInteraction(_interaction);
        isNative = _isNative;

        IERC20Upgradeable(underlying).approve(_masterVault, type(uint256).max);
        IERC20Upgradeable(collateral).approve(_interaction, type(uint256).max);
    }
    
    // --- User ---
    function provide(uint256 _amount) external payable override whenNotPaused nonReentrant returns (uint256 value) {

        if(isNative) {
            require(_amount == 0, "DavosProvider/erc20-not-accepted");
            uint256 native = msg.value;
            IWrapped(underlying).deposit{value: native}();
            value = masterVault.deposit(native, msg.sender);
        } else {
            require(msg.value == 0, "DavosProvider/native-not-accepted");
            underlying.safeTransferFrom(msg.sender, address(this), _amount);
            value = masterVault.deposit(_amount, msg.sender);
        }

        value = _provideCollateral(msg.sender, value);
        emit Deposit(msg.sender, value);
        return value;
    }
    function release(address _recipient, uint256 _amount) external override whenNotPaused nonReentrant returns (uint256 realAmount) {

        require(_recipient != address(0));
        realAmount = _withdrawCollateral(msg.sender, _amount);
        realAmount = masterVault.redeem(realAmount, _recipient, address(this));

        emit Withdrawal(msg.sender, _recipient, realAmount);
        return realAmount;
    }
    
    // --- Interaction ---
    function liquidation(address _recipient, uint256 _amount) external override onlyOwnerOrInteraction nonReentrant {

        require(_recipient != address(0));
        masterVault.redeem(_amount, _recipient, address(this));
    }
    function daoBurn(address _account, uint256 _amount) external override onlyOwnerOrInteraction nonReentrant {

        require(_account != address(0));
        collateralDerivative.burn(_account, _amount);
    }
    function daoMint(address _account, uint256 _amount) external override onlyOwnerOrInteraction nonReentrant {

        require(_account != address(0));
        collateralDerivative.mint(_account, _amount);
    }
    function _provideCollateral(address _account, uint256 _amount) internal returns (uint256 deposited) {

        deposited = interaction.deposit(_account, address(collateral), _amount);
        collateralDerivative.mint(_account, deposited);
    }
    function _withdrawCollateral(address _account, uint256 _amount) internal returns (uint256 withdrawn) {
        
        withdrawn = interaction.withdraw(_account, address(collateral), _amount);
        collateralDerivative.burn(_account, withdrawn);
    }

    // --- Admin ---
    function pause() external onlyOwner {

        _pause();
    }
    function unPause() external onlyOwner {

        _unpause();
    }
    function changeCollateral(address _collateral) external onlyOwner {

        if(address(collateral) != address(0)) 
            IERC20Upgradeable(collateral).approve(address(interaction), 0);
        collateral = IERC20Upgradeable(_collateral);
        IERC20Upgradeable(_collateral).approve(address(interaction), type(uint256).max);
        emit CollateralChanged(_collateral);
    }
    function changeCollateralDerivative(address _collateralDerivative) external onlyOwner {

        collateralDerivative = ICertToken(_collateralDerivative);
        emit CollateralDerivativeChanged(_collateralDerivative);
    }
    function changeMasterVault(address _masterVault) external onlyOwner {

        if(address(underlying) != address(0)) 
            IERC20Upgradeable(underlying).approve(address(masterVault), 0);
        masterVault = IERC4626Upgradeable(_masterVault);
        IERC20Upgradeable(underlying).approve(address(_masterVault), type(uint256).max);
        emit MasterVaultChanged(_masterVault);
    }
    function changeInteraction(address _interaction) external onlyOwner {
        
        if(address(collateral) != address(0)) 
            IERC20Upgradeable(collateral).approve(address(interaction), 0);
        interaction = IInteraction(_interaction);
        IERC20Upgradeable(collateral).approve(address(_interaction), type(uint256).max);
        emit InteractionChanged(_interaction);
    }
    function changeUnderlying(address _underlying) external onlyOwner {

        if(address(underlying) != address(0)) 
            IERC20Upgradeable(underlying).approve(address(masterVault), 0);
        underlying = IWrapped(_underlying);
        IERC20Upgradeable(_underlying).approve(address(masterVault), type(uint256).max);
        emit UnderlyingChanged(_underlying);
    }
    function changeNativeStatus(bool _isNative) external onlyOwner {

        isNative = _isNative;
        emit NativeStatusChanged(_isNative);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// jar.sol -- Davos distribution farming

// Copyright (C) 2022
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/*
   "Put rewards in the jar and close it".
   This contract lets you deposit DAVOSs from davos.sol and earn
   DAVOS rewards. The DAVOS rewards are deposited into this contract
   and distributed over a timeline. Users can redeem rewards
   after exit delay.
*/

contract Jar is Initializable, ReentrancyGuardUpgradeable {
    // --- Wrapper ---
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Jar/not-authorized");
        _;
    }

    // --- Derivative ---
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    // --- Reward Data ---
    uint public spread;          // Distribution time     [sec]
    uint public endTime;         // Time "now" + spread   [sec]
    uint public rate;            // Emission per second   [wad]
    uint public tps;             // DAVOS tokens per share  [wad]
    uint public lastUpdate;      // Last tps update       [sec]
    uint public exitDelay;       // User unstake delay    [sec]
    uint public flashLoanDelay;  // Anti flash loan time  [sec]
    address public DAVOS;        // The DAVOS Stable Coin

    mapping(address => uint) public tpsPaid;      // DAVOS per share paid
    mapping(address => uint) public rewards;      // Accumulated rewards
    mapping(address => uint) public withdrawn;    // Capital withdrawn
    mapping(address => uint) public unstakeTime;  // Time of Unstake
    mapping(address => uint) public stakeTime;    // Time of Stake

    mapping(address => uint) public operators;  // Operators of contract

    uint    public live;     // Active Flag

    // --- Events ---
    event Replenished(uint reward);
    event SpreadUpdated(uint newDuration);
    event ExitDelayUpdated(uint exitDelay);
    event OperatorSet(address operator);
    event OperatorUnset(address operator);
    event Join(address indexed user, uint indexed amount);
    event Exit(address indexed user, uint indexed amount);
    event Redeem(address[] indexed user);
    event Cage();
    event UnCage();
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(string memory _name, string memory _symbol, address _davosToken, uint _spread, uint _exitDelay, uint _flashLoanDelay) external initializer {
        __ReentrancyGuard_init();
        wards[msg.sender] = 1;
        decimals = 18;
        name = _name;
        symbol = _symbol;
        DAVOS = _davosToken;
        spread = _spread;
        exitDelay = _exitDelay;
        flashLoanDelay = _flashLoanDelay;
        live = 1;
    }

    // --- Math ---
    function _min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }

    // --- Mods ---
    modifier update(address account) {
        tps = tokensPerShare();
        lastUpdate = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            tpsPaid[account] = tps;
        }
        _;
    }
    modifier authOrOperator {
        require(operators[msg.sender] == 1 || wards[msg.sender] == 1, "Jar/not-auth-or-operator");
        _;
    }

    // --- Views ---
    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(block.timestamp, endTime);
    }
    function tokensPerShare() public view returns (uint) {
        if (totalSupply <= 0 || block.timestamp <= lastUpdate) {
            return tps;
        }
        uint latest = lastTimeRewardApplicable();
        return tps + (((latest - lastUpdate) * rate * 1e18) / totalSupply);
    }
    function earned(address account) public view returns (uint) {
        uint perToken = tokensPerShare() - tpsPaid[account];
        return ((balanceOf[account] * perToken) / 1e18) + rewards[account];
    }

    // --- Administration --
    function replenish(uint wad, bool newSpread) external authOrOperator update(address(0)) {
        uint timeline = spread;
        if (block.timestamp >= endTime) {
            rate = wad / timeline;
        } else {
            uint remaining = endTime - block.timestamp;
            uint leftover = remaining * rate;
            timeline = newSpread ? spread : remaining;
            rate = (wad + leftover) / timeline;
        }
        lastUpdate = block.timestamp;
        endTime = block.timestamp + timeline;

        IERC20Upgradeable(DAVOS).safeTransferFrom(msg.sender, address(this), wad);
        emit Replenished(wad);
    }
    function setSpread(uint _spread) external authOrOperator {
        require(_spread > 0, "Jar/duration-non-zero");
        spread = _spread;
        emit SpreadUpdated(_spread);
    }
    function setExitDelay(uint _exitDelay) external authOrOperator {
        exitDelay = _exitDelay;
        emit ExitDelayUpdated(_exitDelay);
    }
    function addOperator(address _operator) external auth {
        operators[_operator] = 1;
        emit OperatorSet(_operator);
    }
    function removeOperator(address _operator) external auth {
        operators[_operator] = 0;
        emit OperatorUnset(_operator);
    }
    function extractDust() external auth {
        require(block.timestamp >= endTime, "Jar/in-distribution");
        uint dust = IERC20Upgradeable(DAVOS).balanceOf(address(this)) - totalSupply;
        if (dust != 0) {
            IERC20Upgradeable(DAVOS).safeTransfer(msg.sender, dust);
        }
    }
    function cage() external auth {
        live = 0;
        emit Cage();
    }

    function uncage() external auth {
        live = 1;
        emit UnCage();
    }

    // --- User ---
    function join(uint256 wad) external update(msg.sender) nonReentrant {
        require(live == 1, "Jar/not-live");

        balanceOf[msg.sender] += wad;
        totalSupply += wad;
        stakeTime[msg.sender] = block.timestamp + flashLoanDelay;

        IERC20Upgradeable(DAVOS).safeTransferFrom(msg.sender, address(this), wad);
        emit Join(msg.sender, wad);
    }
    function exit(uint256 wad) external update(msg.sender) nonReentrant {
        require(live == 1, "Jar/not-live");
        require(block.timestamp > stakeTime[msg.sender], "Jar/flash-loan-delay");

        if (wad > 0) {
            balanceOf[msg.sender] -= wad;        
            totalSupply -= wad;
            withdrawn[msg.sender] += wad;
        }
        if (exitDelay <= 0) {
            // Immediate claim
            address[] memory accounts = new address[](1);
            accounts[0] = msg.sender;
            _redeemHelper(accounts);
        } else {
            unstakeTime[msg.sender] = block.timestamp + exitDelay;
        }
        
        emit Exit(msg.sender, wad);
    }
    function redeemBatch(address[] memory accounts) external nonReentrant {
        // Allow direct and on-behalf redemption
        require(live == 1, "Jar/not-live");
        _redeemHelper(accounts);
    }
    function _redeemHelper(address[] memory accounts) private {
        for (uint i = 0; i < accounts.length; i++) {
            if (block.timestamp < unstakeTime[accounts[i]] && unstakeTime[accounts[i]] != 0 && exitDelay != 0)
                continue;
            
            uint _amount = rewards[accounts[i]] + withdrawn[accounts[i]];
            if (_amount > 0) {
                rewards[accounts[i]] = 0;
                withdrawn[accounts[i]] = 0;
                IERC20Upgradeable(DAVOS).safeTransfer(accounts[i], _amount);
            }
        }
       
        emit Redeem(accounts);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";

import { FixedPoint } from "./libraries/FixedPoint.sol";
import { UniswapV2Library } from "./libraries/UniswapV2Library.sol";
import { UniswapV2OracleLibrary } from "./libraries/UniswapV2OracleLibrary.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// sliding window oracle that uses observations collected over a window to provide moving price averages in the past
// `windowSize` with a precision of `windowSize / granularity`
// note this is a singleton oracle and only needs to be deployed once per desired parameters, which
// differs from the simple oracle which must be deployed once per pair.
contract SlidingWindowOracle is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  using FixedPoint for *;

  struct Observation {
    uint256 timestamp;
    uint256 price0Cumulative;
    uint256 price1Cumulative;
  }

  address public factory;
  // the desired amount of time over which the moving average should be computed, e.g. 24 hours
  uint256 public windowSize;
  // the number of observations stored for each pair, i.e. how many price observations are stored for the window.
  // as granularity increases from 1, more frequent updates are needed, but moving averages become more precise.
  // averages are computed over intervals with sizes in the range:
  //   [windowSize - (windowSize / granularity) * 2, windowSize]
  // e.g. if the window size is 24 hours, and the granularity is 24, the oracle will return the average price for
  //   the period:
  //   [now - [22 hours, 24 hours], now]
  uint8 public granularity;
  // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
  uint256 public periodSize;

  // mapping from pair address to a list of price observations of that pair
  mapping(address => Observation[]) public pairObservations;

  function initialize(
    address factory_,
    uint256 windowSize_,
    uint8 granularity_
  ) external initializer {
    __Ownable_init();
    require(granularity_ > 1, "SlidingWindowOracle: GRANULARITY");
    require(
      (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
      "SlidingWindowOracle: WINDOW_NOT_EVENLY_DIVISIBLE"
    );
    factory = factory_;
    windowSize = windowSize_;
    granularity = granularity_;
  }

  function _authorizeUpgrade(address newImplementations) internal override onlyOwner {}

  // returns the index of the observation corresponding to the given timestamp
  function observationIndexOf(uint256 timestamp) public view returns (uint8 index) {
    uint256 epochPeriod = timestamp / periodSize;
    return uint8(epochPeriod % granularity);
  }

  // returns the observation from the oldest epoch (at the beginning of the window) relative to the current time
  function getFirstObservationInWindow(address pair)
    private
    view
    returns (Observation storage firstObservation)
  {
    uint8 observationIndex = observationIndexOf(block.timestamp);
    unchecked {
      // no overflow issue. if observationIndex + 1 overflows, result is still zero.
      uint8 firstObservationIndex = (observationIndex + 1) % granularity;
      firstObservation = pairObservations[pair][firstObservationIndex];
    }
  }

  // update the cumulative price for the observation at the current timestamp. each observation is updated at most
  // once per epoch period.
  function update(address tokenA, address tokenB) external {
    address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

    // populate the array with empty observations (first call only)
    for (uint256 i = pairObservations[pair].length; i < granularity; i++) {
      pairObservations[pair].push();
    }

    // get the observation for the current period
    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    unchecked {
      // we only want to commit updates once per period (i.e. windowSize / granularity)
      uint256 timeElapsed = block.timestamp - observation.timestamp;
      if (timeElapsed > periodSize) {
        (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary
          .currentCumulativePrices(pair);
        observation.timestamp = block.timestamp;
        observation.price0Cumulative = price0Cumulative;
        observation.price1Cumulative = price1Cumulative;
      }
    }
  }

  // given the cumulative prices of the start and end of a period, and the length of the period, compute the average
  // price in terms of how much amount out is received for the amount in
  function computeAmountOut(
    uint256 priceCumulativeStart,
    uint256 priceCumulativeEnd,
    uint256 timeElapsed,
    uint256 amountIn
  ) private pure returns (uint256 amountOut) {
    unchecked {
      // overflow is desired.
      FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
        uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
      );
      amountOut = priceAverage.mul(amountIn).decode144();
    }
  }

  // returns the amount out corresponding to the amount in for a given token using the moving average over the time
  // range [now - [windowSize, windowSize - periodSize * 2], now]
  // update must have been called for the bucket corresponding to timestamp `now - windowSize`
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view returns (uint256 amountOut) {
    address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
    Observation storage firstObservation = getFirstObservationInWindow(pair);

    uint256 timeElapsed;
    unchecked {
      timeElapsed = block.timestamp - firstObservation.timestamp;
      require(timeElapsed <= windowSize, "SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION");
      // should never happen.
      require(
        timeElapsed >= windowSize - periodSize * 2,
        "SlidingWindowOracle: UNEXPECTED_TIME_ELAPSED"
      );
    }

    (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary
      .currentCumulativePrices(pair);
    (address token0, ) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

    if (token0 == tokenIn) {
      return
        computeAmountOut(
          firstObservation.price0Cumulative,
          price0Cumulative,
          timeElapsed,
          amountIn
        );
    } else {
      return
        computeAmountOut(
          firstObservation.price1Cumulative,
          price1Cumulative,
          timeElapsed,
          amountIn
        );
    }
  }

  uint256[30] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./FullMath.sol";
import "./Babylonian.sol";
import "./BitMath.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
  // range: [0, 2**112 - 1]
  // resolution: 1 / 2**112
  struct uq112x112 {
    uint224 _x;
  }

  // range: [0, 2**144 - 1]
  // resolution: 1 / 2**112
  struct uq144x112 {
    uint256 _x;
  }

  uint8 public constant RESOLUTION = 112;
  uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
  uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  // encode a uint112 as a UQ112x112
  function encode(uint112 x) internal pure returns (uq112x112 memory) {
    return uq112x112(uint224(x) << RESOLUTION);
  }

  // encodes a uint144 as a UQ144x112
  function encode144(uint144 x) internal pure returns (uq144x112 memory) {
    return uq144x112(uint256(x) << RESOLUTION);
  }

  // decode a UQ112x112 into a uint112 by truncating after the radix point
  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  // decode a UQ144x112 into a uint144 by truncating after the radix point
  function decode144(uq144x112 memory self) internal pure returns (uint144) {
    return uint144(self._x >> RESOLUTION);
  }

  // multiply a UQ112x112 by a uint, returning a UQ144x112
  // reverts on overflow
  function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
    unchecked {
      uint256 z = 0;
      require(y == 0 || (z = self._x * y) / y == self._x, "FixedPoint::mul: overflow");
      return uq144x112(z);
    }
  }

  // multiply a UQ112x112 by an int and decode, returning an int
  // reverts on overflow
  function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
    unchecked {
      uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
      require(z < 2**255, "FixedPoint::muli: overflow");
      return y < 0 ? -int256(z) : int256(z);
    }
  }

  // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
  // lossy
  function muluq(uq112x112 memory self, uq112x112 memory other)
    internal
    pure
    returns (uq112x112 memory)
  {
    unchecked {
      if (self._x == 0 || other._x == 0) {
        return uq112x112(0);
      }
      uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
      uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
      uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
      uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

      // partial products
      uint224 upper = uint224(upper_self) * upper_other; // * 2^0
      uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
      uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
      uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

      // so the bit shift does not overflow
      require(upper <= type(uint112).max, "FixedPoint::muluq: upper overflow");

      // this cannot exceed 256 bits, all values are 224 bits
      uint256 sum = uint256(upper << RESOLUTION) +
        uppers_lowero +
        uppero_lowers +
        (lower >> RESOLUTION);

      // so the cast does not overflow
      require(sum <= type(uint224).max, "FixedPoint::muluq: sum overflow");

      return uq112x112(uint224(sum));
    }
  }

  // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
  function divuq(uq112x112 memory self, uq112x112 memory other)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(other._x > 0, "FixedPoint::divuq: division by zero");
    unchecked {
      if (self._x == other._x) {
        return uq112x112(uint224(Q112));
      }
      if (self._x <= type(uint144).max) {
        uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
        require(value <= type(uint224).max, "FixedPoint::divuq: overflow");
        return uq112x112(uint224(value));
      }

      uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
      require(result <= type(uint224).max, "FixedPoint::divuq: overflow");
      return uq112x112(uint224(result));
    }
  }

  // returns a UQ112x112 which represents the ratio of the numerator to the denominator
  // can be lossy
  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    unchecked {
      if (numerator == 0) return FixedPoint.uq112x112(0);

      if (numerator <= type(uint144).max) {
        uint256 result = (numerator << RESOLUTION) / denominator;
        require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
        return uq112x112(uint224(result));
      } else {
        uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
        require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
        return uq112x112(uint224(result));
      }
    }
  }

  // take the reciprocal of a UQ112x112
  // reverts on overflow
  // lossy
  function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    require(self._x != 0, "FixedPoint::reciprocal: reciprocal of zero");
    require(self._x != 1, "FixedPoint::reciprocal: overflow");
    return uq112x112(uint224(Q224 / self._x));
  }

  // square root of a UQ112x112
  // lossy between 0/1 and 40 bits
  function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
    unchecked {
      if (self._x <= type(uint144).max) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
      }

      uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
      safeShiftBits -= safeShiftBits % 2;
      return
        uq112x112(
          uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2))
        );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../interfaces/IUniswapV2Pair.sol";

library UniswapV2Library {
  using SafeMath for uint256;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"ff",
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
            )
          )
        )
      )
    );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(
    address factory,
    address tokenA,
    address tokenB
  ) internal view returns (uint256 reserveA, uint256 reserveB) {
    (address token0, ) = sortTokens(tokenA, tokenB);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB))
      .getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) internal pure returns (uint256 amountB) {
    require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
    require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    amountB = amountA.mul(reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountIn) {
    require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
    require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(
    address factory,
    uint256 amountIn,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length - 1; i++) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(
    address factory,
    uint256 amountOut,
    address[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
    amounts = new uint256[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = path.length - 1; i > 0; i--) {
      (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IUniswapV2Pair.sol";
import "./FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
  using FixedPoint for *;

  // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
  function currentBlockTimestamp() internal view returns (uint32) {
    return uint32(block.timestamp % 2**32);
  }

  // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
  function currentCumulativePrices(address pair)
    internal
    view
    returns (
      uint256 price0Cumulative,
      uint256 price1Cumulative,
      uint32 blockTimestamp
    )
  {
    blockTimestamp = currentBlockTimestamp();
    price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
    price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

    // if time has elapsed since the last update on the pair, mock the accumulated price values
    (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair)
      .getReserves();
    unchecked {
      if (blockTimestampLast != blockTimestamp) {
        // subtraction overflow is desired
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;
        // addition overflow is desired
        // counterfactual
        price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
        // counterfactual
        price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
  // credit for this implementation goes to
  // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
  function sqrt(uint256 x) internal pure returns (uint256) {
    if (x == 0) return 0;
    // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
    // however that code costs significantly more gas
    unchecked {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) {
        xx >>= 128;
        r <<= 64;
      }
      if (xx >= 0x10000000000000000) {
        xx >>= 64;
        r <<= 32;
      }
      if (xx >= 0x100000000) {
        xx >>= 32;
        r <<= 16;
      }
      if (xx >= 0x10000) {
        xx >>= 16;
        r <<= 8;
      }
      if (xx >= 0x100) {
        xx >>= 8;
        r <<= 4;
      }
      if (xx >= 0x10) {
        xx >>= 4;
        r <<= 2;
      }
      if (xx >= 0x8) {
        r <<= 1;
      }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return (r < r1 ? r : r1);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

library BitMath {
  // returns the 0 indexed position of the most significant bit of the input x
  // s.t. x >= 2**msb and x < 2**(msb+1)
  function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
    require(x > 0, "BitMath::mostSignificantBit: zero");
    unchecked {
      if (x >= 0x100000000000000000000000000000000) {
        x >>= 128;
        r += 128;
      }
      if (x >= 0x10000000000000000) {
        x >>= 64;
        r += 64;
      }
      if (x >= 0x100000000) {
        x >>= 32;
        r += 32;
      }
      if (x >= 0x10000) {
        x >>= 16;
        r += 16;
      }
      if (x >= 0x100) {
        x >>= 8;
        r += 8;
      }
      if (x >= 0x10) {
        x >>= 4;
        r += 4;
      }
      if (x >= 0x4) {
        x >>= 2;
        r += 2;
      }
      if (x >= 0x2) r += 1;
    }
  }

  // returns the 0 indexed position of the least significant bit of the input x
  // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
  // i.e. the bit at the index is set and the mask of all lower bits is 0
  function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
    require(x > 0, "BitMath::leastSignificantBit: zero");
    unchecked {
      r = 255;
      if (x & type(uint128).max > 0) {
        r -= 128;
      } else {
        x >>= 128;
      }
      if (x & type(uint64).max > 0) {
        r -= 64;
      } else {
        x >>= 64;
      }
      if (x & type(uint32).max > 0) {
        r -= 32;
      } else {
        x >>= 32;
      }
      if (x & type(uint16).max > 0) {
        r -= 16;
      } else {
        x >>= 16;
      }
      if (x & type(uint8).max > 0) {
        r -= 8;
      } else {
        x >>= 8;
      }
      if (x & 0xf > 0) {
        r -= 4;
      } else {
        x >>= 4;
      }
      if (x & 0x3 > 0) {
        r -= 2;
      } else {
        x >>= 2;
      }
      if (x & 0x1 > 0) r -= 1;
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Oracle is Ownable {

    using SafeMath for uint;

    event PriceUpdate(bytes32 price);

    bytes32 public price; 

    // Take care of decimals while setting a price for the test
    function setPrice(uint256 _price) external onlyOwner {
        price = bytes32(_price);
        emit PriceUpdate(bytes32(_price));
    }

    function peek() view external returns(bytes32,bool) {
        if (price  == 0)
         return (0, false);
        return (price, true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IMovingWindowOracle } from "../interfaces/IMovingWindowOracle.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PriceOracleTestnet is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  // FIXME: Uncomment for mainnet
  // address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB MAINNET
  // address public constant USD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD MAINNET
  // address public constant USD = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // USDC MAINNET
  ///////////////////////////////////////////////////////

  // FIXME: need to be removed for mainnet
  address public constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // WBNB TESTNET
  address public constant USD = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // BUSD TESTNET
  // address public constant USD = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // USDT TESTNET
  ///////////////////////////////////////////////////////

  address public tokenIn;
  bool public useBNBPath;
  uint8 public tokenInDecimals;
  uint8 public usdDecimals;
  IMovingWindowOracle public pancakeOracle;

  function initialize(
    address _tokenIn,
    IMovingWindowOracle _pancakeOracle,
    bool _useBNBPath
  ) external initializer {
    __Ownable_init();
    tokenIn = _tokenIn;
    tokenInDecimals = IERC20Metadata(_tokenIn).decimals();
    usdDecimals = IERC20Metadata(USD).decimals();
    pancakeOracle = _pancakeOracle;
    useBNBPath = _useBNBPath;
  }

  function _authorizeUpgrade(address newImplementations) internal override onlyOwner {}

  function peek() public view returns (bytes32, bool) {
    uint256 oneTokenIn = 10**tokenInDecimals;
    uint256 oneTokenOut = 10**usdDecimals;
    uint256 amountOut;
    if (useBNBPath) {
      uint256 bnbAmountOut = pancakeOracle.consult(tokenIn, oneTokenIn, WBNB);
      amountOut = pancakeOracle.consult(WBNB, bnbAmountOut, USD);
    } else {
      amountOut = pancakeOracle.consult(tokenIn, oneTokenIn, USD);
    }
    uint256 price = (amountOut * 10**18) / oneTokenOut;
    return (bytes32(price), true);
  }

  uint256[30] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IMovingWindowOracle {
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { IMovingWindowOracle } from "../interfaces/IMovingWindowOracle.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract PriceOracle is Initializable, UUPSUpgradeable, OwnableUpgradeable {
  address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB MAINNET
  address public constant USD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD MAINNET

  address public tokenIn;
  bool public useBNBPath;
  uint8 public tokenInDecimals;
  uint8 public usdDecimals;
  IMovingWindowOracle public pancakeOracle;

  function initialize(
    address _tokenIn,
    IMovingWindowOracle _pancakeOracle,
    bool _useBNBPath
  ) external initializer {
    __Ownable_init();
    tokenIn = _tokenIn;
    tokenInDecimals = IERC20Metadata(_tokenIn).decimals();
    usdDecimals = IERC20Metadata(USD).decimals();
    pancakeOracle = _pancakeOracle;
    useBNBPath = _useBNBPath;
  }

  function _authorizeUpgrade(address newImplementations) internal override onlyOwner {}

  function peek() public view returns (bytes32, bool) {
    uint256 oneTokenIn = 10**tokenInDecimals;
    uint256 oneTokenOut = 10**usdDecimals;
    uint256 amountOut;
    if (useBNBPath) {
      uint256 bnbAmountOut = pancakeOracle.consult(tokenIn, oneTokenIn, WBNB);
      amountOut = pancakeOracle.consult(WBNB, bnbAmountOut, USD);
    } else {
      amountOut = pancakeOracle.consult(tokenIn, oneTokenIn, USD);
    }
    uint256 price = (amountOut * 10**18) / oneTokenOut;
    return (bytes32(price), true);
  }

  uint256[30] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract CeToken is OwnableUpgradeable, ERC20Upgradeable {
    /**
     * Variables
     */

    address private _vault;

    /**
     * Events
     */

    event VaultChanged(address vault);

    /**
     * Modifiers
     */

    modifier onlyMinter() {
        require(msg.sender == _vault, "Minter: not allowed");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    
    function initialize(string calldata _name, string calldata _symbol)
        external
        initializer
    {
        __Ownable_init();
        __ERC20_init_unchained(_name, _symbol);
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function changeVault(address vault) external onlyOwner {
        require(vault != address(0));
        _vault = vault;
        emit VaultChanged(vault);
    }

    function getVaultAddress() external view returns (address) {
        return _vault;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/ICerosRouterLs.sol";

import "./interfaces/IVault.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IPolygonPool.sol";
import "./interfaces/ICertToken.sol";
import "./interfaces/IPriceGetter.sol";

contract CerosRouterLs is ICerosRouterLs, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    
    // --- Wrapper ---
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Vars ---
    IVault public s_ceVault;
    ISwapRouter public s_dex;
    IPolygonPool public s_pool;
    ICertToken public s_aMATICc;
    IERC20Upgradeable public s_maticToken;
    address public s_strategy;
    IPriceGetter public s_priceGetter;

    uint24 public s_pairFee;

    mapping(address => uint256) public s_profits;

    // --- Mods ---
    modifier onlyOwnerOrStrategy() {

        require(msg.sender == owner() || msg.sender == s_strategy, "CerosRouter/not-owner-or-strategy");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address _aMATICc, address _maticToken, address _bondToken, address _ceVault, address _dex, uint24 _pairFee, address _pool, address _priceGetter) external initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        s_aMATICc = ICertToken(_aMATICc);
        s_maticToken = IERC20Upgradeable(_maticToken);
        s_ceVault = IVault(_ceVault);
        s_dex = ISwapRouter(_dex);
        s_pairFee = _pairFee;
        s_pool = IPolygonPool(_pool);
        s_priceGetter = IPriceGetter(_priceGetter);

        IERC20Upgradeable(s_maticToken).approve(_dex, type(uint256).max);
        IERC20Upgradeable(s_maticToken).approve(_pool, type(uint256).max);
        IERC20(s_aMATICc).approve(_dex, type(uint256).max);
        IERC20(s_aMATICc).approve(_bondToken, type(uint256).max);
        IERC20(s_aMATICc).approve(_pool, type(uint256).max);
        IERC20(s_aMATICc).approve(_ceVault, type(uint256).max);
    }

    // --- Users ---
    function deposit(uint256 _amount) external override nonReentrant whenNotPaused returns (uint256 value) {   

        {
            require(_amount > 0, "CerosRouter/invalid-amount");
            uint256 balanceBefore = s_maticToken.balanceOf(address(this));
            s_maticToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 balanceAfter = s_maticToken.balanceOf(address(this));
            require(balanceAfter >= balanceBefore + _amount, "CerosRouter/invalid-transfer");
        }

        // Minimum acceptable amount
        uint256 ratio = s_aMATICc.ratio();
        uint256 minAmount = safeCeilMultiplyAndDivide(_amount, ratio, 1e18);

        // From PolygonPool
        uint256 poolAmount = _amount >= s_pool.getMinimumStake() ? minAmount : 0;

        // From Dex
        uint256 dexAmount = getAmountOut(address(s_maticToken), address(s_aMATICc), _amount);

        // Compare both
        uint256 realAmount;
        if (poolAmount >= dexAmount) {
            realAmount = poolAmount;
            s_pool.stakeAndClaimCerts(_amount);
        } else {
            realAmount = swapV3(address(s_maticToken), address(s_aMATICc), _amount, minAmount, address(this));
        }

        require(realAmount >= minAmount, "CerosRouter/price-low");
        require(s_aMATICc.balanceOf(address(this)) >= realAmount, "CerosRouter/wrong-certToken-amount-in-CerosRouter");
        
        // Profits
        uint256 profit = realAmount - minAmount;
        s_profits[msg.sender] += profit;
        value = s_ceVault.depositFor(msg.sender, realAmount - profit);
        emit Deposit(msg.sender, address(s_maticToken), realAmount - profit, profit);
        return value;
    }
    function swapV3(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address recipient) private returns (uint256 amountOut) {

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            _tokenIn,               // tokenIn
            _tokenOut,              // tokenOut
            s_pairFee,              // fee
            recipient,              // recipient
            block.timestamp + 300,  // deadline
            _amountIn,              // amountIn
            _amountOutMin,          // amountOutMinimum
            0                       // sqrtPriceLimitX96
        );
        amountOut = s_dex.exactInputSingle(params);
    }

    function withdrawAMATICc(address _recipient, uint256 _amount) external override nonReentrant whenNotPaused returns (uint256 realAmount) {

        realAmount = s_ceVault.withdrawFor(msg.sender, _recipient, _amount);

        emit Withdrawal(msg.sender, _recipient, address(s_aMATICc), realAmount);
        return realAmount;
    }

    function claim(address _recipient) external override nonReentrant whenNotPaused returns (uint256 yields) {

        yields = s_ceVault.claimYieldsFor(msg.sender, _recipient);  // aMATICc

        emit Claim(_recipient, address(s_aMATICc), yields);
        return yields;
    }
    function claimProfit(address _recipient) external nonReentrant {

        uint256 profit = s_profits[msg.sender];
        require(profit > 0, "CerosRouter/no-profits");
        require(s_aMATICc.balanceOf(address(this)) >= profit, "CerosRouter/insufficient-amount");

        s_aMATICc.transfer(_recipient, profit);  // aMATICc
        s_profits[msg.sender] -= profit;

        emit Claim(_recipient, address(s_aMATICc), profit);
    }

    // --- Strategy ---
    function withdrawFor(address _recipient, uint256 _amount) external override nonReentrant whenNotPaused onlyOwnerOrStrategy returns (uint256 realAmount) {

        realAmount = s_ceVault.withdrawFor(msg.sender, address(this), _amount);
        bytes memory bytesData;
        s_pool.unstakeCertsFor{value: 0}(_recipient, realAmount, 0, 0, bytesData); // aMATICc -> MATIC

        emit Withdrawal(msg.sender, _recipient, address(s_maticToken), realAmount);
        return realAmount;
    }

    // --- Internal ---
    function safeCeilMultiplyAndDivide(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {

        // Ceil (a * b / c)
        uint256 remainder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(remainder.mul(b).add(c.sub(1)).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }

    // --- Admin ---
    function pause() external onlyOwner {

        _pause();
    }
    function unpause() external onlyOwner {

        _unpause();
    }
    function changePriceGetter(address _priceGetter) external onlyOwner {

        require(_priceGetter != address(0));
        s_priceGetter = IPriceGetter(_priceGetter);
    }
    function changePairFee(uint24 _fee) external onlyOwner {

        s_pairFee = _fee;
        emit ChangePairFee(_fee);
    }
    function changeStrategy(address _strategy) external onlyOwner {

        s_strategy = _strategy;
        emit ChangeStrategy(_strategy);
    }
    function changePool(address _pool) external onlyOwner {

        s_aMATICc.approve(address(s_pool), 0);
        s_pool = IPolygonPool(_pool);
        s_aMATICc.approve(address(_pool), type(uint256).max);
        emit ChangePool(_pool);
    }
    function changeDex(address _dex) external onlyOwner {

        IERC20Upgradeable(s_maticToken).approve(address(s_dex), 0);
        s_aMATICc.approve(address(s_dex), 0);
        s_dex = ISwapRouter(_dex);
        IERC20Upgradeable(s_maticToken).approve(address(_dex), type(uint256).max);
        s_aMATICc.approve(address(_dex), type(uint256).max);
        emit ChangeDex(_dex);
    }
    function changeCeVault(address _ceVault) external onlyOwner {

        s_aMATICc.approve(address(s_ceVault), 0);
        s_ceVault = IVault(_ceVault);
        s_aMATICc.approve(address(_ceVault), type(uint256).max);
        emit ChangeCeVault(_ceVault);
    }

    // --- Views ---
    function getAmountOut(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256 amountOut) {

        if(address(s_priceGetter) == address(0)) return 0;
        else {
            amountOut = IPriceGetter(s_priceGetter).getPrice(
                _tokenIn,
                _tokenOut,
                _amountIn,
                0,
                s_pairFee
            );
        }
    }
    function getPendingWithdrawalOf(address _account) external view returns (uint256) {

        return s_pool.pendingUnstakesOf(_account);
    }
    function getYieldFor(address _account) external view returns(uint256) {

        return s_ceVault.getYieldFor(_account);
    } 
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

interface IPolygonPool {
    function stakeAndClaimCerts(uint256 amount) external;

    function unstakeCertsFor(address recipient, uint256 shares, uint256 fee, uint256 useBeforeBlock, bytes memory signature) external payable;

    function getMinimumStake() external view returns (uint256);

    function getRelayerFee() external view returns (uint256);

    function pendingUnstakesOf(address claimer) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "../ceros/interfaces/ICertToken.sol";
import "../ceros/interfaces/IBondToken.sol";

import "./ERC20ModUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract aMATICb is OwnableUpgradeable, ERC20ModUpgradeable, IBondToken {
    /**
     * Variables
     */

    address private _operator;
    address private _crossChainBridge;
    address private _binancePool;
    uint256 private _ratio;
    uint256 private _totalStaked;
    uint256 private _totalUnbondedBonds;
    int256 private _lockedShares;

    mapping(address => uint256) private _pendingBurn;
    uint256 private _pendingBurnsTotal;
    uint256 private _collectableFee;

    ICertToken private _aMATICc;

    address private _swapFeeOperator;
    uint256 private _swapFeeRatio;

    /**
     * Modifiers
     */

    modifier onlyOperator() {
        require(
            msg.sender == owner() || msg.sender == _operator,
            "Operator: not allowed"
        );
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == _crossChainBridge, "Minter: not allowed");
        _;
    }

    modifier onlyBondMinter() {
        require(msg.sender == _binancePool, "Minter: not allowed");
        _;
    }

    function initialize(address operator) external initializer {
        __Ownable_init();
        __ERC20_init_unchained("Ankr MATIC Reward Earning Bond", "aMATICb");
        _operator = operator;
        _ratio = 1e18;
    }

    function ratio() public view override returns (uint256) {
        return _ratio;
    }

    /// @dev new_ratio = total_shares/(total_staked + total_reward - unbonds)
    function updateRatio(uint256 totalRewards) external onlyOperator {
        uint256 totalShares = totalSharesSupply();
        uint256 denominator = _totalStaked + totalRewards - _totalUnbondedBonds;
        _ratio = (totalShares * 1e18) / denominator;
        emit RatioUpdated(_ratio);
    }

    function repairRatio(uint256 newRatio) external onlyOwner {
        _ratio = newRatio;
        emit RatioUpdated(_ratio);
    }

    function lockShares(uint256 shares) external override {
        address spender = msg.sender;
        // transfer tokens from aETHc to aETHb
        _aMATICc.transferFrom(spender, address(this), shares);
        // calc swap fee (default swap fee ratio is 0.1%=0.1/100*1e18, fee can't be greater than 1%)
        uint256 fee = (shares * _swapFeeRatio) / 1e18;
        if (msg.sender == _swapFeeOperator) {
            fee = 0;
        }
        uint256 sharesWithFee = shares - fee;
        // increase senders and operator balances
        _balances[_swapFeeOperator] += fee;
        _balances[spender] += sharesWithFee;
        emit Locked(spender, shares);
    }

    function lockSharesFor(
        address spender,
        address account,
        uint256 shares
    ) external override {
        require(spender == msg.sender, "invalid spender");
        _aMATICc.transferFrom(spender, address(this), shares);
        _balances[account] += shares;
        emit Locked(account, shares);
    }

    function transferAndLockShares(address account, uint256 shares)
        external
        override
    {
        _aMATICc.transferFrom(account, address(this), shares);
        _balances[account] += shares;
        emit Locked(account, shares);
    }

    function unlockShares(uint256 shares) external override {
        address account = address(msg.sender);
        // make sure user has enough balance
        require(super.balanceOf(account) >= shares, "insufficient balance");
        // calc swap fee
        uint256 fee = (shares * _swapFeeRatio) / 1e18;
        if (msg.sender == _swapFeeOperator) {
            fee = 0;
        }
        uint256 sharesWithFee = shares - fee;
        // update balances
        _balances[_swapFeeOperator] += fee;
        _balances[account] -= shares;
        // transfer tokens to the user
        _aMATICc.transfer(account, sharesWithFee);
        emit Unlocked(account, shares);
    }

    function unlockSharesFor(address account, uint256 bonds) external override {
        uint256 shares = bondsToShares(bonds);
        // make sure user has enough balance
        require(_balances[account] >= shares, "insufficient balance");
        // update balance
        _balances[account] -= shares;
        // transfer tokens to the user
        _aMATICc.transfer(account, shares);
        emit Unlocked(account, shares);
    }

    function mintBonds(address account, uint256 amount) external override {
        _totalStaked += amount;
        uint256 shares = bondsToShares(amount);
        _mint(account, shares);
        _aMATICc.mint(address(this), shares);
        emit Transfer(address(0), account, amount);
    }

    function mint(address account, uint256 shares) external {
        _lockedShares -= int256(shares);
        _mint(account, shares);
        emit Transfer(address(0), account, shares);
    }

    function burnBonds(address account, uint256 amount) external override {
        uint256 shares = bondsToShares(amount);
        _lockedShares += int256(shares);
        _burn(account, shares);
        emit Transfer(account, address(0), amount);
    }

    function pendingBurn(address account)
        external
        view
        override
        returns (uint256)
    {
        return _pendingBurn[account];
    }

    function burnAndSetPending(address account, uint256 amount)
        external
        override
    {
        _pendingBurn[account] += amount;
        _pendingBurnsTotal += amount;
        _totalUnbondedBonds += amount;
        uint256 sharesToBurn = bondsToShares(amount);
        _burn(account, sharesToBurn);
        _aMATICc.burn(address(this), sharesToBurn);
        emit Transfer(account, address(0), amount);
    }

    function burnAndSetPendingFor(
        address owner,
        address account,
        uint256 amount
    ) external override {
        _pendingBurn[account] += amount;
        _pendingBurnsTotal += amount;
        _totalUnbondedBonds += amount;
        uint256 sharesToBurn = bondsToShares(amount);
        _burn(owner, sharesToBurn);
        _aMATICc.burn(address(this), sharesToBurn);
        emit Transfer(account, address(0), amount);
    }

    function updatePendingBurning(address account, uint256 amount)
        external
        override
    {
        uint256 pendingBurnableAmount = _pendingBurn[account];
        require(pendingBurnableAmount >= amount, "amount is wrong");
        _pendingBurn[account] = pendingBurnableAmount - amount;
        _pendingBurnsTotal = _pendingBurnsTotal - amount;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToSharesCeil(amount);
        super.transfer(recipient, shares);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 shares = bondsToSharesCeil(amount);
        super.transferFrom(sender, recipient, shares);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return sharesToBonds(super.allowance(owner, spender));
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToShares(addedValue);
        super.increaseAllowance(spender, shares);
        emit Approval(
            msg.sender,
            spender,
            sharesToBonds(_allowances[msg.sender][spender])
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToShares(subtractedValue);
        super.decreaseAllowance(spender, shares);
        emit Approval(
            msg.sender,
            spender,
            sharesToBonds(_allowances[msg.sender][spender])
        );
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        uint256 shares = bondsToSharesCeil(amount);
        super.approve(spender, shares);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function totalSupply() public view override returns (uint256) {
        uint256 supply = totalSharesSupply();
        return sharesToBonds(supply);
    }

    function totalSharesSupply() public view override returns (uint256) {
        return super.totalSupply();
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 shares = super.balanceOf(account);
        return sharesToBonds(shares);
    }

    function lockedSharesOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    function bondsToShares(uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        return multiplyAndDivideFloor(amount, _ratio, 1e18);
    }

    function bondsToSharesCeil(uint256 amount) internal view returns (uint256) {
        return multiplyAndDivideCeil(amount, _ratio, 1e18);
    }

    function sharesToBonds(uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        return multiplyAndDivideFloor(amount, 1e18, _ratio);
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function totalUnbondedBonds() public view returns (uint256) {
        return _totalUnbondedBonds;
    }

    function changeOperator(address operator) external onlyOwner {
        _operator = operator;
        emit OperatorChanged(operator);
    }

    function changeBinancePool(address binancePool) external onlyOwner {
        _binancePool = binancePool;
        emit BinancePoolChanged(binancePool);
    }

    function changeCrossChainBridge(address crossChainBridge)
        external
        onlyOwner
    {
        _crossChainBridge = crossChainBridge;
        emit CrossChainBridgeChanged(crossChainBridge);
    }

    function changeAMATICcToken(address aMATICcAddress) external onlyOwner {
        _aMATICc = ICertToken(aMATICcAddress);
        emit CertTokenChanged(aMATICcAddress);
    }

    function changeSwapFeeParams(address swapFeeOperator, uint256 swapFeeRatio)
        external
        onlyOwner
    {
        require(swapFeeRatio <= 10000000000000000, "not greater than 1%");
        _swapFeeOperator = swapFeeOperator;
        _swapFeeRatio = swapFeeRatio;
    }

    function lockedSupply() public view returns (int256) {
        return _lockedShares;
    }

    function isRebasing() public pure override returns (bool) {
        return true;
    }

    function saturatingMultiply(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (a == 0) return 0;
            uint256 c = a * b;
            if (c / a != b) return type(uint256).max;
            return c;
        }
    }

    function saturatingAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return type(uint256).max;
            return c;
        }
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideFloor(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b) / c // can't fail because of assumption 2.
            );
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideCeil(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
            saturatingAdd(
                saturatingMultiply(a / c, b),
                ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

interface IBondToken {
    /**
     * Events
     */

    event RatioUpdated(uint256 newRatio);
    event BinancePoolChanged(address indexed binancePool);
    event OperatorChanged(address indexed operator);
    event CertTokenChanged(address indexed certToken);
    event CrossChainBridgeChanged(address indexed crossChainBridge);

    event Locked(address indexed account, uint256 amount);
    event Unlocked(address indexed account, uint256 amount);

    function mintBonds(address account, uint256 amount) external;

    function burnBonds(address account, uint256 amount) external;

    function pendingBurn(address account) external view returns (uint256);

    function burnAndSetPending(address account, uint256 amount) external;

    function burnAndSetPendingFor(
        address owner,
        address account,
        uint256 amount
    ) external;

    function updatePendingBurning(address account, uint256 amount) external;

    function ratio() external view returns (uint256);

    function lockShares(uint256 shares) external;

    function lockSharesFor(
        address spender,
        address account,
        uint256 shares
    ) external;

    function transferAndLockShares(address account, uint256 shares) external;

    function unlockShares(uint256 shares) external;

    function unlockSharesFor(address account, uint256 bonds) external;

    function totalSharesSupply() external view returns (uint256);

    function sharesToBonds(uint256 amount) external view returns (uint256);

    function bondsToShares(uint256 amount) external view returns (uint256);

    function isRebasing() external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../ceros/interfaces/IBondToken.sol";

contract aMATICc is OwnableUpgradeable, ERC20Upgradeable {
  /**
   * Variables
   */

  address private _binancePool;
  address private _bondToken;

  /**
   * Events
   */

  event BinancePoolChanged(address indexed binancePool);
  event BondTokenChanged(address indexed bondToken);

  /**
   * Modifiers
   */

  modifier onlyMinter() {
    require(
      msg.sender == _binancePool || msg.sender == _bondToken,
      "Minter: not allowed"
    );
    _;
  }

  function initialize(address binancePool, address bondToken)
  public
  initializer
  {
    __Ownable_init();
    __ERC20_init_unchained("Ankr MATIC Reward Bearing Certificate", "aMATICc");
    _binancePool = binancePool;
    _bondToken = bondToken;
    uint256 initSupply = IBondToken(_bondToken).totalSharesSupply();
    // mint init supply if not inizialized
    super._mint(address(_bondToken), initSupply);
  }

  function ratio() public view returns (uint256) {
    return IBondToken(_bondToken).ratio();
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function mintApprovedTo(
    address account,
    address spender,
    uint256 amount
  ) external {
    _mint(account, amount);
    _approve(account, spender, amount);
  }

  function changeBinancePool(address binancePool) external onlyOwner {
    _binancePool = binancePool;
    emit BinancePoolChanged(binancePool);
  }

  function changeBondToken(address bondToken) external onlyOwner {
    _bondToken = bondToken;
    emit BondTokenChanged(bondToken);
  }

  function balanceWithRewardsOf(address account)
  public
  view
  returns (uint256)
  {
    uint256 shares = this.balanceOf(account);
    return IBondToken(_bondToken).sharesToBonds(shares);
  }

  function isRebasing() public pure returns (bool) {
    return false;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// jar.sol -- Davos distribution farming

// Copyright (C) 2022
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface TokenInterface {
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external;
    function ratio() external view returns(uint256);
}

contract PolygonPool {

    // aMATICc
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint) public balanceOf;

    uint256 private _minimumStake;
    address public cert;
    address public wMATIC;

    bool public return0;
    bool public giveMore;

    constructor(address _cert, address _wMATIC) {
        _minimumStake = 5e15;
        cert = _cert;
        wMATIC = _wMATIC;
    }

    function setMinimumStake(uint256 minimumStake_) external {
        _minimumStake = minimumStake_;
    }

    function stakeAndClaimCerts(uint256 amount) external {
        if(return0) return;

        uint256 extra;
        if(giveMore) extra = 100000;

        TokenInterface(wMATIC).transferFrom(msg.sender, address(this), amount);
        uint256 mintAmount = ((amount + extra) * TokenInterface(cert).ratio()) / 1e18;
        TokenInterface(cert).mint(msg.sender, mintAmount);
    }

    function unstakeCertsFor(address recipient, uint256 shares, uint256 fee, uint256 useBeforeBlock, bytes memory signature) external payable {
        if(return0) return;

        TokenInterface(cert).burn(msg.sender, shares);
        uint256 mintAmount = ((shares) * 1e18) / TokenInterface(cert).ratio();
        TokenInterface(wMATIC).transfer(recipient, mintAmount);
    }

    function getMinimumStake() external returns(uint256) {
        return _minimumStake;
    }

    function setReturn0(bool _value) external {
        return0 = _value;
    }

    function setGiveMore(bool _value) external {
        giveMore = _value;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./NonTransferableERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract dMATIC is OwnableUpgradeable, NonTransferableERC20 {
    /**
     * Variables
     */

    address private _minter;

    /**
     * Events
     */

    event MinterChanged(address minter);

    /**
     * Modifiers
     */

    modifier onlyMinter() {
        require(msg.sender == _minter, "Minter: not allowed");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize() external initializer {
        __Ownable_init();
        __ERC20_init_unchained("Davos MATIC", "dMATIC");
    }

    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    function changeMinter(address minter) external onlyOwner {
        require(minter != address(0));
        _minter = minter;
        emit MinterChanged(minter);
    }

    function getMinter() external view returns (address) {
        return _minter;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// davos.sol -- davos Stablecoin ERC-20 Token

// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "./interfaces/IDavos.sol";


// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Davos is Initializable, IDavos {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Davos/not-authorized");
        _;
    }

    // --- ERC20 Data ---
    string  public constant name     = "Davos.xyz USD";
    string  public symbol;
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;

    uint256 public supplyCap;

    event SupplyCapSet(uint256 oldCap, uint256 newCap);

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    function initialize(uint256 chainId_, string memory symbol_, uint256 supplyCap_) external initializer {
        wards[msg.sender] = 1;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
        symbol = symbol_;
        supplyCap = supplyCap_;
    }

    // --- Token ---
    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }
    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        require(src != address(0), "Davos/transfer-from-zero-address");
        require(dst != address(0), "Davos/transfer-to-zero-address");
        require(balanceOf[src] >= wad, "Davos/insufficient-balance");
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "Davos/insufficient-allowance");
            allowance[src][msg.sender] -= wad;
        }
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        emit Transfer(src, dst, wad);
        return true;
    }
    function mint(address usr, uint wad) external auth {
        require(usr != address(0), "Davos/mint-to-zero-address");
        require(totalSupply + wad <= supplyCap, "Davos/cap-reached");
        balanceOf[usr] += wad;
        totalSupply    += wad;
        emit Transfer(address(0), usr, wad);
    }
    function burn(address usr, uint wad) external {
        require(usr != address(0), "Davos/burn-from-zero-address");
        require(balanceOf[usr] >= wad, "Davos/insufficient-balance");
        if (usr != msg.sender && allowance[usr][msg.sender] != type(uint256).max) {
            require(allowance[usr][msg.sender] >= wad, "Davos/insufficient-allowance");
            allowance[usr][msg.sender] -= wad;
        }
        balanceOf[usr] -= wad;
        totalSupply    -= wad;
        emit Transfer(usr, address(0), wad);
    }
    function approve(address usr, uint wad) external returns (bool) {
        _approve(msg.sender, usr, wad);

        return true;
    }

    // --- Alias ---
    function push(address usr, uint wad) external {
        transferFrom(msg.sender, usr, wad);
    }
    function pull(address usr, uint wad) external {
        transferFrom(usr, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "Davos/invalid-address-0");
        require(holder == ECDSAUpgradeable.recover(digest, v, r, s), "Davos/invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "Davos/permit-expired");
        require(nonce == nonces[holder]++, "Davos/invalid-nonce");
        uint wad = allowed ? type(uint256).max : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "Davos/approve-from-zero-address");
        require(spender != address(0), "Davos/approve-to-zero-address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance[owner][spender];
        require(currentAllowance >= subtractedValue, "Davos/decreased-allowance-below-zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function setSupplyCap(uint256 wad) public auth {
        require(wad >= totalSupply, "Davos/more-supply-than-cap");
        uint256 oldCap = supplyCap;
        supplyCap = wad;
        emit SupplyCapSet(oldCap, supplyCap);
    }

    function updateDomainSeparator(uint256 chainId_) external auth {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// vat.sol -- Davos CDP database

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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/VatLike.sol";

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Vat is VatLike, Initializable {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { require(live == 1, "Vat/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth { require(live == 1, "Vat/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Vat/not-authorized");
        _;
    }

    mapping(address => mapping (address => uint)) public can;
    function behalf(address bit, address usr) external auth { can[bit][usr] = 1; }
    function regard(address bit, address usr) external auth { can[bit][usr] = 0; }
    function hope(address usr) external { can[msg.sender][usr] = 1; }
    function nope(address usr) external { can[msg.sender][usr] = 0; }
    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }
    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]
    mapping (address => uint256)                   public davos;  // [rad]
    mapping (address => uint256)                   public sin;  // [rad]

    uint256 public debt;  // Total Davos Issued    [rad]
    uint256 public vice;  // Total Unbacked Davos  [rad]
    uint256 public Line;  // Total Debt Ceiling  [rad]
    uint256 public live;  // Active Flag

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize() external initializer {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function _add(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x + uint(y);
            require(y >= 0 || z <= x);
            require(y <= 0 || z >= x);
        }
    }
    function _sub(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x - uint(y);
            require(y <= 0 || z <= x);
            require(y >= 0 || z >= x);
        }
    }
    function _mul(uint x, int y) internal pure returns (int z) {
        unchecked {
            z = int(x) * y;
            require(int(x) >= 0);
            require(y == 0 || z / y == int(x));
        }
    }
    function _add(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }
    function _mul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x);
        }
    }

    // --- Administration ---
    function init(bytes32 ilk) external auth {
        require(ilks[ilk].rate == 0, "Vat/ilk-already-init");
        ilks[ilk].rate = 10 ** 27;
    }
    function file(bytes32 what, uint data) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "Line") Line = data;
        else revert("Vat/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 ilk, bytes32 what, uint data) external auth {
        require(live == 1, "Vat/not-live");
        if (what == "spot") ilks[ilk].spot = data;
        else if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
        emit File(ilk, what, data);
    }
    function cage() external auth {
        live = 0;
    }

    function uncage() external auth {
        live = 1;
    }

    // --- Fungibility ---
    function slip(bytes32 ilk, address usr, int256 wad) external auth {
        gem[ilk][usr] = _add(gem[ilk][usr], wad);
    }
    function flux(bytes32 ilk, address src, address dst, uint256 wad) external auth {
        require(wish(src, msg.sender), "Vat/not-allowed");
        gem[ilk][src] = _sub(gem[ilk][src], wad);
        gem[ilk][dst] = _add(gem[ilk][dst], wad);
    }
    function move(address src, address dst, uint256 rad) external auth {
        require(wish(src, msg.sender), "Vat/not-allowed");
        davos[src] = _sub(davos[src], rad);
        davos[dst] = _add(davos[dst], rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- CDP Manipulation ---
    function frob(bytes32 i, address u, address v, address w, int dink, int dart) external auth {
        // system is live
        require(live == 1, "Vat/not-live");

        Urn memory urn = urns[i][u];
        Ilk memory ilk = ilks[i];
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int dtab = _mul(ilk.rate, dart);
        uint tab = _mul(ilk.rate, urn.art);
        debt     = _add(debt, dtab);

        // either debt has decreased, or debt ceilings are not exceeded
        require(either(dart <= 0, both(_mul(ilk.Art, ilk.rate) <= ilk.line, debt <= Line)), "Vat/ceiling-exceeded");
        // urn is either less risky than before, or it is safe
        require(either(both(dart <= 0, dink >= 0), tab <= _mul(urn.ink, ilk.spot)), "Vat/not-safe");

        // urn is either more safe, or the owner consents
        require(either(both(dart <= 0, dink >= 0), wish(u, msg.sender)), "Vat/not-allowed-u");
        // collateral src consents
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // debt dst consents
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");

        gem[i][v] = _sub(gem[i][v], dink);
        davos[w]    = _add(davos[w],    dtab);

        urns[i][u] = urn;
        ilks[i]    = ilk;
    }

    // --- CDP Fungibility ---
    function fork(bytes32 ilk, address src, address dst, int dink, int dart) external auth {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = _sub(u.ink, dink);
        u.art = _sub(u.art, dart);
        v.ink = _add(v.ink, dink);
        v.art = _add(v.art, dart);

        uint utab = _mul(u.art, i.rate);
        uint vtab = _mul(v.art, i.rate);

        // both sides consent
        require(both(wish(src, msg.sender), wish(dst, msg.sender)), "Vat/not-allowed");

        // both sides safe
        require(utab <= _mul(u.ink, i.spot), "Vat/not-safe-src");
        require(vtab <= _mul(v.ink, i.spot), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
    }

    // --- CDP Confiscation ---
    function grab(bytes32 i, address u, address v, address w, int dink, int dart) external auth {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int dtab = _mul(ilk.rate, dart);

        gem[i][v] = _sub(gem[i][v], dink);
        sin[w]    = _sub(sin[w],    dtab);
        vice      = _sub(vice,      dtab);
    }

    // --- Settlement ---
    function heal(uint rad) external {
        address u = msg.sender;
        sin[u] = _sub(sin[u], rad);
        davos[u] = _sub(davos[u], rad);
        vice   = _sub(vice,   rad);
        debt   = _sub(debt,   rad);
    }
    function suck(address u, address v, uint rad) external auth {
        sin[u] = _add(sin[u], rad);
        davos[v] = _add(davos[v], rad);
        vice   = _add(vice,   rad);
        debt   = _add(debt,   rad);
    }

    // --- Rates ---
    function fold(bytes32 i, address u, int rate) external auth {
        require(live == 1, "Vat/not-live");
        Ilk storage ilk = ilks[i];
        ilk.rate = _add(ilk.rate, rate);
        int rad  = _mul(ilk.Art, rate);
        davos[u]   = _add(davos[u], rad);
        debt     = _add(debt,   rad);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// spot.sol -- Spotter

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

pragma solidity ^0.8.10;

import "./interfaces/SpotLike.sol";
import "./interfaces/VatLike.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Spotter is Initializable, SpotLike {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Spotter/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        PipLike pip;  // Price Feed
        uint256 mat;  // Liquidation ratio [ray]
    }

    mapping (bytes32 => Ilk) public ilks;

    VatLike public vat;  // CDP Engine
    uint256 public par;  // ref per davos [ray]

    uint256 public live;

    // --- Events ---
    event Poke(
      bytes32 ilk,
      bytes32 val,  // [wad]
      uint256 spot  // [ray]
    );

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, address clip);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address vat_) external initializer {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        par = ONE;
        live = 1;
    }

    // --- Math ---
    uint constant ONE = 10 ** 27;

    function mul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x);
        }
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            z = mul(x, ONE) / y;
        }
    }

    // --- Administration ---
    function file(bytes32 ilk, bytes32 what, address pip_) external auth {
        require(live == 1, "Spotter/not-live");
        if (what == "pip") ilks[ilk].pip = PipLike(pip_);
        else revert("Spotter/file-unrecognized-param");
        emit File(ilk, what, pip_);
    }
    function file(bytes32 what, uint data) external auth {
        require(live == 1, "Spotter/not-live");
        if (what == "par") par = data;
        else revert("Spotter/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 ilk, bytes32 what, uint data) external auth {
        require(live == 1, "Spotter/not-live");
        if (what == "mat") ilks[ilk].mat = data;
        else revert("Spotter/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    // --- Update value ---
    function poke(bytes32 ilk) external {
        (bytes32 val, bool has) = ilks[ilk].pip.peek();
        uint256 spot = has ? rdiv(rdiv(mul(uint(val), 10 ** 9), par), ilks[ilk].mat) : 0;
        vat.file(ilk, "spot", spot);
        emit Poke(ilk, val, spot);
    }

    function cage() external auth {
        live = 0;
    }

    function uncage() external auth {
        live = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

/// dog.sol -- Davos liquidation module 2.0

// Copyright (C) 2020-2022 Dai Foundation
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/DogLike.sol";
import "./interfaces/ClipperLike.sol";
import "./interfaces/VatLike.sol";

contract Dog is DogLike, Initializable {
    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Dog/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        address clip;  // Liquidator
        uint256 chop;  // Liquidation Penalty                                          [wad]
        uint256 hole;  // Max DAVOS needed to cover debt+fees of active auctions per ilk [rad]
        uint256 dirt;  // Amt DAVOS needed to cover debt+fees of active auctions per ilk [rad]
    }

    VatLike public vat;  // CDP Engine

    mapping (bytes32 => Ilk) public ilks;

    address public vow;   // Debt Engine
    uint256 public live;  // Active Flag
    uint256 public Hole;  // Max DAVOS needed to cover debt+fees of active auctions [rad]
    uint256 public Dirt;  // Amt DAVOS needed to cover debt+fees of active auctions [rad]

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, address clip);

    event Bark(
      bytes32 indexed ilk,
      address indexed urn,
      uint256 ink,
      uint256 art,
      uint256 due,
      address clip,
      uint256 indexed id
    );
    event Digs(bytes32 indexed ilk, uint256 rad);
    event Cage();
    event Uncage();
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address vat_) external initializer {
        vat = VatLike(vat_);
        live = 1;
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x + y) >= x);
        }
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require((z = x - y) <= x);
        }
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x);
        }
    }

    // --- Administration ---
    function file(bytes32 what, address data) external auth {
        if (what == "vow") vow = data;
        else revert("Dog/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 what, uint256 data) external auth {
        if (what == "Hole") Hole = data;
        else revert("Dog/file-unrecognized-param");
        emit File(what, data);
    }
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "chop") {
            require(data >= WAD, "Dog/file-chop-lt-WAD");
            ilks[ilk].chop = data;
        } else if (what == "hole") ilks[ilk].hole = data;
        else revert("Dog/file-unrecognized-param");
        emit File(ilk, what, data);
    }
    function file(bytes32 ilk, bytes32 what, address clip) external auth {
        if (what == "clip") {
            require(ilk == ClipperLike(clip).ilk(), "Dog/file-ilk-neq-clip.ilk");
            ilks[ilk].clip = clip;
        } else revert("Dog/file-unrecognized-param");
        emit File(ilk, what, clip);
    }

    function chop(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].chop;
    }

    // --- CDP Liquidation: all bark and no bite ---
    //
    // Liquidate a Vault and start a Dutch auction to sell its collateral for DAVOS.
    //
    // The third argument is the address that will receive the liquidation reward, if any.
    //
    // The entire Vault will be liquidated except when the target amount of DAVOS to be raised in
    // the resulting auction (debt of Vault + liquidation penalty) causes either Dirt to exceed
    // Hole or ilk.dirt to exceed ilk.hole by an economically significant amount. In that
    // case, a partial liquidation is performed to respect the global and per-ilk limits on
    // outstanding DAVOS target. The one exception is if the resulting auction would likely
    // have too little collateral to be interesting to Keepers (debt taken from Vault < ilk.dust),
    // in which case the function reverts. Please refer to the code and comments within if
    // more detail is desired.
    function bark(bytes32 ilk, address urn, address kpr) external auth returns (uint256 id) {
        require(live == 1, "Dog/not-live");

        (uint256 ink, uint256 art) = vat.urns(ilk, urn);
        Ilk memory milk = ilks[ilk];
        uint256 dart;
        uint256 rate;
        uint256 dust;
        {
            uint256 spot;
            (,rate, spot,, dust) = vat.ilks(ilk);
            require(spot > 0 && mul(ink, spot) < mul(art, rate), "Dog/not-unsafe");

            // Get the minimum value between:
            // 1) Remaining space in the general Hole
            // 2) Remaining space in the collateral hole
            require(Hole > Dirt && milk.hole > milk.dirt, "Dog/liquidation-limit-hit");
            uint256 room = min(Hole - Dirt, milk.hole - milk.dirt);

            // uint256.max()/(RAD*WAD) = 115,792,089,237,316
            dart = min(art, mul(room, WAD) / rate / milk.chop);

            // Partial liquidation edge case logic
            if (art > dart) {
                if (mul(art - dart, rate) < dust) {

                    // If the leftover Vault would be dusty, just liquidate it entirely.
                    // This will result in at least one of dirt_i > hole_i or Dirt > Hole becoming true.
                    // The amount of excess will be bounded above by ceiling(dust_i * chop_i / WAD).
                    // This deviation is assumed to be small compared to both hole_i and Hole, so that
                    // the extra amount of target DAVOS over the limits intended is not of economic concern.
                    dart = art;
                } else {

                    // In a partial liquidation, the resulting auction should also be non-dusty.
                    require(mul(dart, rate) >= dust, "Dog/dusty-auction-from-partial-liquidation");
                }
            }
        }

        uint256 dink = mul(ink, dart) / art;

        require(dink > 0, "Dog/null-auction");
        require(dart <= 2**255 && dink <= 2**255, "Dog/overflow");

        vat.grab(
            ilk, urn, milk.clip, vow, -int256(dink), -int256(dart)
        );

        uint256 due = mul(dart, rate);

        {   // Avoid stack too deep
            // This calcuation will overflow if dart*rate exceeds ~10^14
            uint256 tab = mul(due, milk.chop) / WAD;
            Dirt = add(Dirt, tab);
            ilks[ilk].dirt = add(milk.dirt, tab);

            id = ClipperLike(milk.clip).kick({
                tab: tab,
                lot: dink,
                usr: urn,
                kpr: kpr
            });
        }

        emit Bark(ilk, urn, dink, dart, due, milk.clip, id);
    }

    function digs(bytes32 ilk, uint256 rad) external auth {
        Dirt = sub(Dirt, rad);
        ilks[ilk].dirt = sub(ilks[ilk].dirt, rad);
        emit Digs(ilk, rad);
    }

    function cage() external auth {
        live = 0;
        emit Cage();
    }

    function uncage() external auth {
        live = 1;
        emit Uncage();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IWstETH {
    function stETH() external view returns(address);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
}
interface IMasterVault {
    function previewRedeem(uint256 shares) external view returns (uint256);
}

contract WstETHOracle is Initializable{

    AggregatorV3Interface internal priceFeed; // 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8 stETH/USD
    IWstETH internal wstETH;
    IMasterVault internal masterVault;

    function initialize(address _aggregatorAddress, address _wstETH, IMasterVault _masterVault) external initializer {
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
        wstETH = IWstETH(_wstETH);
        masterVault = _masterVault;
    }

    /**
     * Returns the latest price
     */
    function peek() public view returns (bytes32, bool) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        if (price < 0) {
            return (0, false);
        }

        // Get stETH equivalent to 1wstETH and multiply with stETH price
        uint256 stETH = wstETH.getStETHByWstETH(1e18);
        uint256 wstETHPrice = (stETH * uint(price * (10**10))) / 1e18;

        // Get wstETH equivalent to 1share in MasterVault
        uint256 wstETH = masterVault.previewRedeem(1e18);
        uint256 sharePrice = (wstETHPrice * wstETH) / 1e18;

        return (bytes32(sharePrice), true);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

contract MaticOracleV2 is Initializable {
    AggregatorV3Interface priceFeed;
    IPyth pyth;

    bytes32 pythPriceID;
    uint256 threshold; // 2mins
    bool isUpgradedForV2;

    function initialize(address aggregatorAddress) external initializer {
        priceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    function upgradeToV2(
        address _chainlinkAggregatorAddress,
        address _pythAddress,
        bytes32 _priceId,
        uint256 _threshold
    ) external {
        require(!isUpgradedForV2, "MaticOracleV2/already-upgraded");
        isUpgradedForV2 = true;
        priceFeed = AggregatorV3Interface(_chainlinkAggregatorAddress);
        pyth = IPyth(_pythAddress);
        pythPriceID = _priceId;
        threshold = _threshold;
    }

    /**
     * Returns the latest price
     */
    function peek() public view returns (bytes32, bool) {
        // Chainlink
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint startedAt*/,
            uint256 timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();

        if (block.timestamp - timeStamp <= threshold && price >= 0) {
            return (bytes32(uint256(price) * (10**10)), true);
        }

        // Pyth
        PythStructs.Price memory pythPrice = pyth.getPrice(pythPriceID);

        if (pythPrice.price < 0) {
            return (0, false);
        }
        return (bytes32(uint64(pythPrice.price) * (10**uint32(pythPrice.expo + 18))), true);
    }

    function updatePriceFeeds(bytes[] calldata priceUpdateData)
        external
        payable
    {
        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MaticOracle is Initializable{

    AggregatorV3Interface internal priceFeed;

    function initialize(address aggregatorAddress) external initializer {
        priceFeed = AggregatorV3Interface(aggregatorAddress);
    }

    /**
     * Returns the latest price
     */
    function peek() public view returns (bytes32, bool) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        if (price < 0) {
            return (0, false);
        }
        return (bytes32(uint(price * (10**10))), true);
    }
}