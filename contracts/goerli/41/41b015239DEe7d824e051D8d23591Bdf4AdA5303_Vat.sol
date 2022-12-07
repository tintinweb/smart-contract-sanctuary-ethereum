// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
import "./../utils/PermissionGroup.sol";
import "./../utils/Math.sol";
import "../interfaces/IPriceProviderAggregator.sol";

contract Vat is PermissionGroup {
    using Math for uint;
    using Math for int;
    uint256 constant BLN = 10 **  9;
    uint constant RAY = 10 ** 27;

    address public priceOracle; // address of price oracle with interface of PriceProviderAggregator
    uint256 public par;  // ref per USB [ray]


    mapping(address => mapping (address => uint)) public can;
    function hope(address usr) external { can[msg.sender][usr] = 1; }
    function nope(address usr) external { can[msg.sender][usr] = 0; }
    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    struct Ilk {
        uint256 Art;           // Total Normalised Debt     [wad]
        uint256 rate;          // Accumulated Rates         [ray]
        uint256 line;          // Debt Ceiling              [rad]
        uint256 dust;          // Urn Debt Floor            [rad]
        uint lvrRatio; //                           [ray]
    }
    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
        uint256 debt;
    }

    mapping (address => Ilk)                       public ilks; // coll => struct Ilk
    mapping (address => mapping (address => Urn )) public urns; // coll => vault => struct ilk
    mapping (address => mapping (address => uint)) public gem;  // coll => vault => struct urn [wad] 
    mapping (address => uint256)                   public USB;  // [rad]
    mapping (address => uint256)                   public sin;  // [rad]

    uint256 public debt;  // Total USB Issued    [rad]
    uint256 public vice;  // Total Unbacked USB  [rad]
    uint256 public Line;  // Total Debt Ceiling  [rad]
    bool public live;  // Active Flag

    event setLine(uint newLine);
    event setParam(address ilk, bytes32 what, uint data);

    // --- Init ---
    constructor(address priceOracle_) {
        operators[msg.sender] = true;
        par = RAY;
        live = true;
        priceOracle = priceOracle_;
    }

    modifier isLive() {
        require(live, "Vat/not-live");
        _;
    }
    // --- Administration ---
    function init(address ilk_, uint line_, uint dust_, uint lvrRatio_) external onlyOperator {
        require(ilks[ilk_].rate == 0, "Vat/ilk-already-init");
        Ilk storage ilk = ilks[ilk_];
        ilk.rate = RAY;
        ilk.line = line_;
        ilk.dust = dust_;
        ilk.lvrRatio = lvrRatio_;
        
    }
    function setNewLine(uint data) external onlyOperator isLive {
        Line = data;
        emit setLine(data);
    }
    function setParamsPerIlk(address ilk, bytes32 what, uint data) external onlyOperator isLive {
        if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
        emit setParam(ilk, what, data);
    }
    function cage() external onlyOperator {
        live = false;
    }

    // --- Fungibility ---
    function slip(address ilk, address usr, int256 wad) external onlyOperator {
        gem[ilk][usr] = gem[ilk][usr].add(wad);
    }
    function flux(address ilk, address src, address dst, uint256 wad) external {
        require(wish(src, msg.sender), "Vat/not-allowed");
        gem[ilk][src] = gem[ilk][src].sub(wad);
        gem[ilk][dst] = gem[ilk][dst].add(wad);
    }
    function move(address src, address dst, uint256 rad) external {
        require(wish(src, msg.sender), "Vat/not-allowed");
        USB[src] = USB[src].sub(rad);
        USB[dst] = USB[dst].add(rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }
    function both(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := and(x, y)}
    }

    // --- CDP Manipulation ---
    function frob(address i, address u, address v, address w, int dink, int dart) external isLive {
        // system is live

        Urn memory urn = urns[i][u];
        Ilk memory ilk = ilks[i];
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");        

        urn.ink = urn.ink.add(dink);
        urn.art = urn.art.add(dart);
        ilk.Art = ilk.Art.add(dart);

        int dtab = ilk.rate.mul(dart);
        uint tab = ilk.rate.mul(urn.art);
        debt     = debt.add(dtab);

        // either debt has decreased, or debt ceilings are not exceeded
        require(either(dart <= 0, both(ilk.Art.mul(ilk.rate) <= ilk.line, debt <= Line)), "Vat/ceiling-exceeded");
        // urn is either less risky than before, or it is safe
        require(either(both(dart <= 0, dink >= 0), tab <= urn.ink.mul(getSpot(i))), "Vat/not-safe");

        // urn is either more safe, or the owner consents
        require(either(both(dart <= 0, dink >= 0), wish(u, msg.sender)), "Vat/not-allowed-u");
        // collateral src consents
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // debt dst consents
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");

        gem[i][v] = gem[i][v].sub(dink);
        USB[w]    = USB[w].add(dtab);

        urns[i][u] = urn;
        ilks[i]    = ilk;
    }

    function addDebt(address i, address u, uint wad) external isLive {
        // system is live
        urns[i][u].debt = urns[i][u].debt.add(wad);
    }

    function subDebt(address i, address u, uint wad) external isLive {
        // system is live
        urns[i][u].debt = urns[i][u].debt.sub(wad);
    }
    // --- CDP Fungibility ---
    function fork(address ilk, address src, address dst, int dink, int dart) external {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = u.ink.sub(dink);
        u.art = u.art.sub(dart);
        v.ink = v.ink.add(dink);
        v.art = v.art.add(dart);

        uint utab = u.art.mul(i.rate);
        uint vtab = v.art.mul(i.rate);

        // both sides consent
        require(both(wish(src, msg.sender), wish(dst, msg.sender)), "Vat/not-allowed");

        // both sides safe
        require(utab <= u.ink.mul(getSpot(ilk)), "Vat/not-safe-src");
        require(vtab <= v.ink.mul(getSpot(ilk)), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
    }
    
    // --- CDP Confiscation ---
    function grab(address i, address u, address v, address w, int dink, int dart) external onlyOperator {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = urn.ink.add(dink);
        urn.art = urn.art.add(dart);
        ilk.Art = ilk.Art.add(dart);

        int dtab = ilk.rate.mul(dart);

        gem[i][v] = gem[i][v].sub(dink);
        sin[w]    = sin[w].sub(dtab);
        vice      = vice.sub(dtab);
    }

    // --- Settlement ---
    function heal(uint rad) external {
        address u = msg.sender;
        sin[u] = sin[u].sub(rad);
        USB[u] = USB[u].sub(rad);
        vice   = vice.sub(rad);
        debt   = debt.sub(rad);
    }
    function suck(address u, address v, uint rad) external onlyOperator {
        sin[u] = sin[u].add(rad);
        USB[v] = USB[v].add(rad);
        vice   = vice.add(rad);
        debt   = vice.add(rad);
    }

    // --- Rates ---
    function fold(address i, address u, int rate) external onlyOperator isLive {
        Ilk storage ilk = ilks[i];
        ilk.rate = ilk.rate.add(rate);
        int rad  = ilk.Art.mul(rate);
        USB[u]   = USB[u].add(rad);
        debt     = vice.add(rad);
    }

    //
    function getPrice(address ilk) public view returns(uint) {
        (uint price, uint usddec) = IPriceProviderAggregator(priceOracle).getPrice(ilk);
        uint usbDec = 18;
        if(usddec <= usbDec) {
            price *= 10 ** (usbDec - usddec);
        }else{
            price /= 10 ** (usddec - usbDec);
        }
        return price;
    }

    // Price with Safety Margin  [ray]
    function getSpot(address ilk) public view returns(uint) {
        uint gemPrice = getPrice(ilk);
        uint rayPrice = gemPrice.mul(BLN);
        uint rayPriceDiv = rayPrice.rdiv(par);
        uint256 spot = rayPriceDiv.rdiv(ilks[ilk].lvrRatio);
        return spot;
    }
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