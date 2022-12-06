// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import "../interfaces/ICore/IVat.sol";
import "../interfaces/IGem/IUSB.sol";
import "./../utils/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./../utils/PermissionGroup.sol";
import "./../utils/Math.sol";

contract USBJoin is PermissionGroup {
    using Math for uint;

    uint constant RAY = 10 ** 27;

    address public vat;      // CDP Engine
    address public USB;  // Stablecoin Token
    bool    public live;     // Active Flag

    // Events
    event Join(address ilk, address indexed usr, uint256 wad);
    event Exit(address ilk, address indexed usr, uint256 wad);
    event JoinSaving(address indexed usr, uint256 wad);
    event ExitSaving(address indexed usr, uint256 wad);
    event Cage();

    constructor(address vat_, address USB_) {
        live = true;
        vat = address(vat_);
        USB = address(USB_);
    }

    function cage() external onlyOwner {
        live = false;
        emit Cage();
    }


    function joinInternal(address usr, uint wad) internal {
        IVat(vat).move(msg.sender, address(this), RAY.mul(wad));
        IUSB(USB).mint(usr, wad);
    }

    function exitInternal(address usr, uint wad) internal {
        require(live, "USBJoin/not-live");
        IVat(vat).move(msg.sender, address(this), RAY.mul(wad));
        IUSB(USB).mint(usr, wad);
    }

    function wipe(address ilk, address usr, uint wad, uint actualBurn) external {
        IVat(vat).move(address(this), usr, RAY.mul(wad));
        IUSB(USB).burn(msg.sender, actualBurn);
        emit Join(ilk, usr, actualBurn);
    }
    
    function join(address ilk, address usr, uint wad) external {
        joinInternal(usr, wad);
        emit Join(ilk, usr, wad);
    }
    function exit(address ilk, address usr, uint wad) external {
        exitInternal(usr, wad);
        emit Exit(ilk, usr, wad);
    }
    function joinSaving(address usr, uint wad) external {
        joinInternal(usr, wad);
        emit JoinSaving(usr, wad);
    }
    function exitSaving(address usr, uint wad) external {
        exitInternal(usr, wad);
        emit ExitSaving(usr, wad);
    }

}

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

interface IUSB {
    function mint(address,uint) external;
    function burn(address,uint) external;
    function approve(address, uint) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;

    
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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