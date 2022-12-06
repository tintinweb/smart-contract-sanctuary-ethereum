// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import "../interfaces/ICore/IVat.sol";
import "./../utils/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./../utils/openzeppelin/contracts/access/Ownable.sol";

/*
    Here we provide *adapters* to connect the Vat to arbitrary external
    token implementations, creating a bounded context for the Vat. The
    adapters here are provided as working examples:

      - `GemJoin`: For well behaved ERC20 tokens, with simple transfer
                   semantics.

      - `ETHJoin`: For native Ether.

      - `USBJoin`: For connecting internal USB balances to an external
                   `DSToken` implementation.

    In practice, adapter implementations will be varied and specific to
    individual collateral types, accounting for different transfer
    semantics and token standards.

    Adapters need to implement two basic methods:

      - `join`: enter collateral into the system
      - `exit`: remove collateral from the system

*/


contract GemJoin is Ownable {
    // --- Auth ---

    address public vat;   // CDP Engine
    address public ilk;   // Collateral Type
    uint    public dec;
    bool    public live;  // Active Flag

    // Events
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);
    event Cage();

    constructor(address vat_, address ilk_) {
        live = true;
        vat = vat_;
        ilk = ilk_;
        dec = IERC20Metadata(ilk).decimals();
    }

    function cage() external onlyOwner {
        live = false;
        emit Cage();
    }

    function join(address usr, uint wad) external {
        require(live, "GemJoin/not-live");
        require(int(wad) >= 0, "GemJoin/overflow");
        IVat(vat).slip(ilk, usr, int(wad));
        require(IERC20Metadata(ilk).transferFrom(msg.sender, address(this), wad), "GemJoin/failed-transfer");
        emit Join(usr, wad);
    }

    function exit(address usr, uint wad) external {
        require(wad <= 2 ** 255, "GemJoin/overflow");
        IVat(vat).slip(ilk, msg.sender, -int(wad));
        require(IERC20Metadata(ilk).transfer(usr, wad), "GemJoin/failed-transfer");
        emit Exit(usr, wad);
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