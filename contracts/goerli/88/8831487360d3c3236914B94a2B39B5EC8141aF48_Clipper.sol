//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IVat {
    function ilks(address) external view returns (uint, uint, uint, uint, uint);
    function urns(address, address) external view returns (uint, uint, uint);
    function USB(address) external view returns (uint);

    function par() external view returns (uint256);
    function liquidationRatio(address) external view returns (address, uint256);
    function priceOracle() external view returns (address);
    function getPrice(address) external view returns(uint);

    function can(address, address) external view returns (uint);

    function hope(address usr) external;
    function nope(address usr) external;

    // --- Administration ---
    function init(address ilk) external;
    function setNewLine(uint data) external;
    function setParamsPerIlk(address ilk, bytes32 what, uint data) external;
    function cage() external;
    
    // --- Fungibility ---
    function slip(address ilk, address usr, int256 wad) external;
    function flux(address ilk, address src, address dst, uint256 wad) external;
    function move(address src, address dst, uint256 rad) external;

    // --- CDP Manipulation ---
    function frob(address i, address u, address v, address w, int dink, int dart) external;
    function addDebt(address i, address u, uint wad) external;
    function subDebt(address i, address u, uint wad) external;

    // --- CDP Fungibility ---
    function fork(address ilk, address src, address dst, int dink, int dart) external;

    // --- CDP Confiscation ---
    function grab(address i, address u, address v, address w, int dink, int dart) external;

    // --- Settlement ---
    function heal(uint rad) external;
    function suck(address u, address v, uint rad) external;

    // --- Rates ---
    function fold(address i, address u, int rate) external;

    function sin (address) external view returns (uint);
     
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IAbacus {
    function price(uint256, uint256) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IClipperCallee {
    function clipperCall(address, uint256, uint256, bytes calldata) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IDog {
    function chop(address) external returns (uint256);
    function digs(address, uint256) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPriceProviderAggregator {
    
    function MODERATOR_ROLE() external view returns(bytes32);
    
    function usdDecimals() external view returns(uint8);

    function tokenPriceProvider(address projectToken) external view returns(address priceProvider, bool hasSignedFunction);

    event GrandModeratorRole(address indexed who, address indexed newModerator);
    event RevokeModeratorRole(address indexed who, address indexed moderator);
    event SetTokenAndPriceProvider(address indexed who, address indexed token, address indexed priceProvider);
    event ChangeActive(address indexed who, address indexed priceProvider, address indexed token, bool active);

    function initialize() external;

    /****************** Admin functions ****************** */

    function grandModerator(address newModerator) external;

    function revokeModerator(address moderator) external;

    /****************** end Admin functions ****************** */

    /****************** Moderator functions ****************** */

    function setTokenAndPriceProvider(address token, address priceProvider, bool hasFunctionWithSign) external;

    function changeActive(address priceProvider, address token, bool active) external;

    /****************** main functions ****************** */

    /**
     * @dev returns tuple (priceMantissa, priceDecimals)
     * @notice price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token wich price is to return
     */
    function getPrice(address token) external view returns(uint256 priceMantissa, uint8 priceDecimals);

    /**
     * @dev returns the price of token multiplied by 10 ** priceDecimals given by price provider.
     * price can be calculated as  priceMantissa / (10 ** priceDecimals)
     * i.e. price = priceMantissa / (10 ** priceDecimals)
     * @param token the address of token
     * @param _priceMantissa - the price of token (used in verifying the signature)
     * @param _priceDecimals - the price decimals (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getPriceSigned(address token, uint256 _priceMantissa, uint8 _priceDecimals, uint256 validTo, bytes memory signature) external view returns(uint256 priceMantissa, uint8 priceDecimals);

    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token to evaluate
     * @param tokenAmount the amount of token to evaluate
     */
    function getEvaluation(address token, uint256 tokenAmount) external view returns(uint256 evaluation);
    
    /**
     * @dev returns the USD evaluation of token by its `tokenAmount`
     * @param token the address of token
     * @param tokenAmount the amount of token including decimals
     * @param priceMantissa - the price of token (used in verifying the signature)
     * @param priceDecimals - the price decimals (used in verifying the signature)
     * @param validTo - the timestamp in seconds (used in verifying the signature)
     * @param signature - the backend signature of secp256k1. length is 65 bytes
     */
    function getEvaluationSigned(address token, uint256 tokenAmount, uint256 priceMantissa, uint8 priceDecimals, uint256 validTo, bytes memory signature) external view returns(uint256 evaluation);

}

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.12;
import "../interfaces/IPriceProviderAggregator.sol";
import "../interfaces/ICore/IVat.sol";
import "../interfaces/ILiquidation/IDog.sol";
import "../interfaces/ILiquidation/IAbacus.sol";
import "../interfaces/ILiquidation/IClipperCallee.sol";
import "./../utils/PermissionGroup.sol";
import "./../utils/Math.sol";

contract Clipper is PermissionGroup {
    using Math for uint;
    uint256 constant BLN = 10 **  9;
    uint256 constant RAY = 10 ** 27;

    // --- Data ---
    address  immutable public ilk;   // Collateral type of this Clipper
    address  immutable public vat;   // Core CDP Engine

    address     public dog;      // Liquidation module
    address     public vow;      // Recipient of dai raised in auctions
    address  public calc;     // Current price calculator

    uint256 public buf;    // Multiplicative factor to increase starting price                  [ray]
    uint256 public tail;   // Time elapsed before auction reset                                 [seconds]
    uint256 public cusp;   // Percentage drop before auction reset                              [ray]
    uint256  public chip;   // Percentage of tab to suck from vow to incentivize keepers         [wad]
    uint256 public tip;    // Flat fee to suck from vow to incentivize keepers                  [rad]
    uint256 public chost;  // Cache the ilk dust times the ilk chop to prevent excessive SLOADs [rad]

    uint256   public kicks;   // Total auctions
    uint256[] public active;  // Array of active auction ids

    struct Sale {
        uint256 pos;  // Index in active array
        uint256 tab;  // Dai to raise       [rad]
        uint256 lot;  // collateral to sell [wad]
        address usr;  // Liquidated CDP
        uint256  tic;  // Auction start time
        uint256 top;  // Starting price     [ray]
    }
    mapping(uint256 => Sale) public sales;

    uint256 internal locked;

    // Levels for circuit breaker
    // 0: no breaker
    // 1: no new kick()
    // 2: no new kick() or redo()
    // 3: no new kick(), redo(), or take()
    uint256 public stopped = 0;

    // --- Events ---

    event setParam(bytes32 indexed what, uint256 data);
    event setContract(bytes32 indexed what, address data);

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

    // --- Init ---
    constructor(address vat_, address dog_, address ilk_) {
        vat     = vat_;
        dog     = dog_;
        ilk     = ilk_;
        buf     = RAY;
        operators[msg.sender] = true;
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

    // --- Administration ---
    function setParamsSystem(bytes32 what, uint256 data) external onlyOperator lock {
        if      (what == "buf")         buf = data;
        else if (what == "tail")       tail = data;           // Time elapsed before auction reset
        else if (what == "cusp")       cusp = data;           // Percentage drop before auction reset
        else if (what == "chip")       chip = uint256(data);   // Percentage of tab to incentivize (max: 2^64 - 1 => 18.xxx WAD = 18xx%)
        else if (what == "tip")         tip = uint256(data);  // Flat fee to incentivize keepers (max: 2^192 - 1 => 6.277T RAD)
        else if (what == "stopped") stopped = data;           // Set breaker (0, 1, 2, or 3)
        else revert("Clipper/file-unrecognized-param");
        emit setParam(what, data);
    }
    function setContractAddresses(bytes32 what, address data) external onlyOperator lock {
        if (what == "dog")    dog = data;
        else if (what == "vow")    vow = data;
        else if (what == "calc")  calc = data;
        else revert("Clipper/file-unrecognized-param");
        emit setContract(what, data);
    }

    // --- Auction ---

    // get the price directly from the OSM
    // Could get this from rmul(Vat.ilks(ilk).spot, Spotter.mat()) instead, but
    // if mat has changed since the last poke, the resulting value will be
    // incorrect.
    function getFeedPrice() internal view returns (uint256 feedPrice) {
        uint price = IVat(vat).getPrice(ilk);
        uint priceBLN = price.mul(BLN);
        feedPrice = priceBLN.rdiv(IVat(vat).par());
    }

    // start an auction
    // note: trusts the caller to transfer collateral to the contract
    // The starting price `top` is obtained as follows:
    //
    //     top = val * buf / par
    //
    // Where `val` is the collateral's unitary value in USD, `buf` is a
    // multiplicative factor to increase the starting price, and `par` is a
    // reference per DAI.
    function kick(
        uint256 tab,  // Debt                   [rad]
        uint256 lot,  // Collateral             [wad]
        address usr,  // Address that will receive any leftover collateral
        address kpr   // Address that will receive incentives
    ) external onlyOperator lock isStopped(1) returns (uint256 id) {
        // Input validation
        require(tab  >          0, "Clipper/zero-tab");
        require(lot  >          0, "Clipper/zero-lot");
        require(usr != address(0), "Clipper/zero-usr");
        id = ++kicks;
        require(id   >          0, "Clipper/overflow");

        active.push(id);

        sales[id].pos = active.length - 1;

        sales[id].tab = tab;
        sales[id].lot = lot;
        sales[id].usr = usr;
        sales[id].tic = uint256(block.timestamp);

        uint256 top;
        top = getFeedPrice().rmul(buf);
        require(top > 0, "Clipper/zero-top-price");
        sales[id].top = top;

        // incentive to kick auction
        uint256 _tip  = tip;
        uint256 _chip = chip;
        uint256 coin;
        if (_tip > 0 || _chip > 0) {
            coin = _tip.add(tab.wmul(_chip));
            IVat(vat).suck(vow, kpr, coin);
        }

        emit Kick(id, top, tab, lot, usr, kpr, coin);
    }

    // Reset an auction
    // See `kick` above for an explanation of the computation of `top`.
    function redo(
        uint256 id,  // id of the auction to reset
        address kpr  // Address that will receive incentives
    ) external lock isStopped(2) {
        // Read auction data
        address usr = sales[id].usr;
        uint256  tic = sales[id].tic;
        uint256 top = sales[id].top;

        require(usr != address(0), "Clipper/not-running-auction");

        // Check that auction needs reset
        // and compute current price [ray]
        (bool done,) = status(tic, top);
        require(done, "Clipper/cannot-reset");

        uint256 tab   = sales[id].tab;
        uint256 lot   = sales[id].lot;
        sales[id].tic = uint256(block.timestamp);

        uint256 feedPrice = getFeedPrice();
        top = feedPrice.rmul(buf);
        require(top > 0, "Clipper/zero-top-price");
        sales[id].top = top;

        // incentive to redo auction
        uint256 _tip  = tip;
        uint256 _chip = chip;
        uint256 coin;
        if (_tip > 0 || _chip > 0) {
            uint256 _chost = chost;
            if (tab >= _chost && lot.mul(feedPrice) >= _chost) {
                coin = _tip.add(tab.wmul(_chip));
                IVat(vat).suck(vow, kpr, coin);
            }
        }

        emit Redo(id, top, tab, lot, usr, kpr, coin);
    }

    // Buy up to `amt` of collateral from the auction indexed by `id`.
    // 
    // Auctions will not collect more DAI than their assigned DAI target,`tab`;
    // thus, if `amt` would cost more DAI than `tab` at the current price, the
    // amount of collateral purchased will instead be just enough to collect `tab` DAI.
    //
    // To avoid partial purchases resulting in very small leftover auctions that will
    // never be cleared, any partial purchase must leave at least `Clipper.chost`
    // remaining DAI target. `chost` is an asynchronously updated value equal to
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
        uint256 max,          // Maximum acceptable price (DAI / collateral) [ray]
        address who,          // Receiver of collateral and external call address
        bytes calldata data   // Data to pass in external call; if length 0, no call is done
    ) external lock isStopped(3) {

        address usr = sales[id].usr;
        uint256  tic = sales[id].tic;

        require(usr != address(0), "Clipper/not-running-auction");

        uint256 price;
        {
            bool done;
            (done, price) = status(tic, sales[id].top);

            // Check that auction doesn't need reset
            require(!done, "Clipper/needs-reset");
        }

        // Ensure price is acceptable to buyer
        require(max >= price, "Clipper/too-expensive");

        uint256 lot = sales[id].lot;
        uint256 tab = sales[id].tab;
        uint256 owe;

        {
            // Purchase as much as possible, up to amt
            uint256 slice = lot.min(amt);  // slice <= lot

            // DAI needed to buy a slice of this sale
            owe = slice.mul(price);

            // Don't collect more than tab of DAI
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
            IVat(vat).flux(ilk, address(this), who, slice);

            // Do external call (if data is defined) but to be
            // extremely careful we don't allow to do it to the two
            // contracts which the Clipper needs to be onlyOperatororized
            address dog_ = dog;
            if (data.length > 0 && who != address(vat) && who != address(dog_)) {
                IClipperCallee(who).clipperCall(msg.sender, owe, slice, data);
            }

            // Get DAI from caller
            IVat(vat).move(msg.sender, vow, owe);

            // Removes Dai out for liquidation from accumulator
            IDog(dog_).digs(ilk, lot == 0 ? tab + owe : owe);
        }

        if (lot == 0) {
            _remove(id);
        } else if (tab == 0) {
            IVat(vat).flux(ilk, address(this), usr, lot);
            _remove(id);
        } else {
            sales[id].tab = tab;
            sales[id].lot = lot;
        }

        emit Take(id, max, price, owe, tab, lot, usr);
    }

    function callFromDog(address who, bytes calldata data) public {
        address dog_ = dog;
        if (data.length > 0 && who != address(vat) && who != dog_) {
            IClipperCallee(who).clipperCall(msg.sender, 1, 1, data);
        }
    }

    function calcTab(uint256 lot, uint256 amt, uint256 price, uint256 tab) public view returns(uint256) {
        // Purchase as much as possible, up to amt
        uint256 slice = lot.min(amt);  // slice <= lot

        // DAI needed to buy a slice of this sale
        uint256 owe = slice.mul(price);

        // Don't collect more than tab of DAI
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
        return tab;
    }
    function calcLot(uint256 lot, uint256 amt, uint256 price, uint256 tab) public view returns(uint256) {
        // Purchase as much as possible, up to amt
        uint256 slice = lot.min(amt);  // slice <= lot

        // DAI needed to buy a slice of this sale
        uint256 owe = slice.mul(price);

        // Don't collect more than tab of DAI
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
        return lot;
    }
    
    function calcOwe(uint256 lot, uint256 amt, uint256 price, uint256 tab) public view returns(uint256) {
        // Purchase as much as possible, up to amt
        uint256 slice = lot.min(amt);  // slice <= lot

        // DAI needed to buy a slice of this sale
        uint256 owe = slice.mul(price);

        // Don't collect more than tab of DAI
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
        return owe;
    }
    function calcSlide(uint256 lot, uint256 amt, uint256 price, uint256 tab) public view returns(uint256) {
        // Purchase as much as possible, up to amt
        uint256 slice = lot.min(amt);  // slice <= lot

        // DAI needed to buy a slice of this sale
        uint256 owe = slice.mul(price);

        // Don't collect more than tab of DAI
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
        return slice;
    }
    function _remove(uint256 id) internal {
        uint256 _move    = active[active.length - 1];
        if (id != _move) {
            uint256 _index   = sales[id].pos;
            active[_index]   = _move;
            sales[_move].pos = _index;
        }
        active.pop();
        delete sales[id];
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
        address usr = sales[id].usr;
        uint256  tic = sales[id].tic;

        bool done;
        (done, price) = status(tic, sales[id].top);

        needsRedo = usr != address(0) && done;
        lot = sales[id].lot;
        tab = sales[id].tab;
    }

    // Internally returns boolean for if an auction needs a redo
    function status(uint256 tic, uint256 top) internal view returns (bool done, uint256 price) {
        price = IAbacus(calc).price(top, block.timestamp.sub(tic));
        done  = (block.timestamp.sub(tic) > tail || price.rdiv(top) < cusp);
    }

    // Public function to update the cached dust*chop value.
    function upchost() external {
        (,,,, uint256 _dust) = IVat(vat).ilks(ilk);
        chost = _dust.wmul(IDog(dog).chop(ilk));
    }

    // Cancel an auction during ES or via governance action.
    function yank(uint256 id) external onlyOperator lock {
        require(sales[id].usr != address(0), "Clipper/not-running-auction");
        IDog(dog).digs(ilk, sales[id].tab);
        IVat(vat).flux(ilk, address(this), msg.sender, sales[id].lot);
        _remove(id);
        emit Yank(id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    uint256 constant RAY = 10 ** 27;
    uint256 constant BLN = 10 **  9;
    uint256 constant WAD = 10 ** 18;

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "mul-overflow");
    }

    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = mul(x, RAY) / y;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        if (y < 0){
            z = x - uint(-y);
        } else{
            z = x + uint(y);
        }  
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function sub(uint x, int y) internal pure returns (uint z) {
        if (y < 0){
            z = x + uint(-y);
        } else{
            z = x - uint(y);
        }          
        require(y <= 0 || z <= x, "sub-overflow");
        require(y >= 0 || z >= x, "sub-overflow");
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "sub-overflow");
    }

        // --- Math ---

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = mul(x, y) / RAY;
    }

    function diff(uint x, uint y) internal pure returns (int z) {
        z = int(x) - int(y);
        require(int(x) >= 0 && int(y) >= 0);
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

    function toInt(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint wad) internal pure returns (uint rad) {
        rad = mul(wad, RAY);
    }

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./openzeppelin/contracts/access/Ownable.sol";
import "./openzeppelin/contracts/utils/Context.sol";

contract PermissionGroup is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;
    event AddOperator(address newOperator);
    event RemoveOperator(address operator);

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @notice Adds an address as operator.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    /**
    * @notice Removes an address as operator.
    */
    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
    }
}