// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
//========================================================================
//    _    _    _    _    _    _    _    _    _    _    _    _    _    _
//   / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \
//  ( N )( o )( n )( a )( m )( e )( . )( M )( o )( n )( s )( t )( e )( r )
//   \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/
//
//========================================================================

pragma solidity ^0.8.13;

interface IOwnedResolver {
    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
//========================================================================
//    _    _    _    _    _    _    _    _    _    _    _    _    _    _
//   / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \
//  ( N )( o )( n )( a )( m )( e )( . )( M )( o )( n )( s )( t )( e )( r )
//   \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/
//
//========================================================================

pragma solidity ^0.8.13;

interface IPriceOracle {
    struct Price {
        uint256 base;
        uint256 premium;
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @param expires When the name presently expires (0 if this is a new registration).
     * @param duration How long the name is being registered or extended for, in seconds.
     * @return base premium tuple of base price + premium price
     */
    function price(
        string calldata name,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);

    function price(
        uint256 name_len,
        uint256 expires,
        uint256 duration
    ) external view returns (Price calldata);
}

// SPDX-License-Identifier: MIT
//========================================================================
//    _    _    _    _    _    _    _    _    _    _    _    _    _    _
//   / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \
//  ( N )( o )( n )( a )( m )( e )( . )( M )( o )( n )( s )( t )( e )( r )
//   \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/
//
//========================================================================

pragma solidity ^0.8.13;
import "./IPriceOracle.sol";

interface IRegistrarController {
    // SpaceID return tuple of base and premium price
    function rentPrice(string memory, uint256) external view returns (IPriceOracle.Price memory);

    // ENS return total price in int
    function rentPriceInt(string memory, uint256) external view returns (uint256);

    function available(string memory) external view returns (bool);

    function commitments(bytes32 commitment) external view returns (uint256);

    function makeCommitmentWithConfig(
        string memory name,
        address owner,
        bytes32 secret,
        address resolver,
        address addr
    ) external pure returns (bytes32);

    function makeCommitment(
        string memory,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint96
    ) external returns (bytes32);

    function commit(bytes32) external;

    function registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable;

    function register(
        string calldata,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint96
    ) external payable;

    function renew(string calldata, uint256) external payable;
}

// SPDX-License-Identifier: MIT
//========================================================================
//    _    _    _    _    _    _    _    _    _    _    _    _    _    _
//   / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \  / \
//  ( N )( o )( n )( a )( m )( e )( . )( M )( o )( n )( s )( t )( e )( r )
//   \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/  \_/
//
//========================================================================

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IRegistrarController } from "./IRegistrarController.sol";
import { IOwnedResolver } from "./IOwnedResolver.sol";
import { IPriceOracle } from "./IPriceOracle.sol";

contract NonameRegistrar is Ownable {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constants **************************************** //
    // ---------------------------------------------------------------------------------------- //
    bytes32 public constant NODE = 0xdba5666821b22671387fe7ea11d7cc41ede85a5aa67c3e7b3d68ce6a661f389c;
    bytes4 public constant INTERFACE_ID = 0x018fac06;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    IOwnedResolver public ownedResolver;
    IRegistrarController public registrarController;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event RegistrarUpdated(address previewsRegistrar, address newRegistrar);

    event OwnedResolverUpdated(address previewAddress, address newAddress);

    event Withdrawn(address to, uint256 value);

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Errors ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Receive native coin
    receive() external payable {}

    // ---------------------------------------------------------------------------------------- //
    // ************************************** Modifiers *************************************** //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    function getRegistrarController() public view returns (IRegistrarController) {
        if (block.chainid == 56 || block.chainid == 97) {
            address resolver = ownedResolver.interfaceImplementer(NODE, INTERFACE_ID);
            return IRegistrarController(resolver);
        } else {
            return IRegistrarController(registrarController);
        }
    }

    function available(string[] memory names) external view returns (bool[] memory) {
        bool[] memory results = new bool[](names.length);
        IRegistrarController _registrarController = getRegistrarController();
        for (uint256 i = 0; i < names.length; i++) {
            results[i] = _registrarController.available(names[i]);
        }
        return results;
    }

    function rentPrice2(string[] calldata names, uint256[] calldata durations)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](names.length);
        IRegistrarController _registrarController = getRegistrarController();
        for (uint256 i = 0; i < names.length; i++) {
            prices[i] = getRentPrice(_registrarController, names[i], durations[i]);
        }
        return prices;
    }

    function getCommitments(
        string[] calldata _names,
        address _owner,
        bytes32 _secret,
        address _resolver,
        address _addr
    ) external view returns (uint256[] memory) {
        uint256[] memory timestamps = new uint256[](_names.length);
        IRegistrarController _registrarController = getRegistrarController();
        for (uint256 i = 0; i < _names.length; i++) {
            bytes32 commitment = _registrarController.makeCommitmentWithConfig(
                _names[i],
                _owner,
                _secret,
                _resolver,
                _addr
            );
            timestamps[i] = _registrarController.commitments(commitment);
        }
        return timestamps;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //
    function setOwnedResolver(address _ownedResolver) external onlyOwner {
        require(_ownedResolver != address(0), "Owned resolver address err");
        address oldOwnedResolver = address(ownedResolver);
        ownedResolver = IOwnedResolver(_ownedResolver);
        emit OwnedResolverUpdated(oldOwnedResolver, _ownedResolver);
    }

    function setRegistrarController(address _registrarController) external onlyOwner {
        require(_registrarController != address(0), "Registrar address err");
        address oldRegistrarController = address(registrarController);
        registrarController = IRegistrarController(_registrarController);
        emit RegistrarUpdated(oldRegistrarController, _registrarController);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    function submit(
        string[] calldata _names,
        address _owner,
        bytes32 _secret,
        address _resolver,
        address _addr
    ) external {
        IRegistrarController _registrarController = getRegistrarController();
        for (uint256 i = 0; i < _names.length; i++) {
            bytes32 commitment = _registrarController.makeCommitmentWithConfig(
                _names[i],
                _owner,
                _secret,
                _resolver,
                _addr
            );
            _registrarController.commit(commitment);
        }
    }

    function register2(
        string[] calldata names,
        address _owner,
        uint256[] calldata durations,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable {
        require(_owner == msg.sender, "Error: Caller must be the same address as owner");
        IRegistrarController _registrarController = getRegistrarController();

        for (uint256 i = 0; i < names.length; i++) {
            uint256 cost = getRentPrice(_registrarController, names[i], durations[i]);
            _registrarController.registerWithConfig{ value: cost }(
                names[i],
                _owner,
                durations[i],
                secret,
                resolver,
                addr
            );
        }
    }

    // Withdraw native coin to owner
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
            emit Withdrawn(owner(), balance);
        }
    }

    // Withdraw ERC20 token to owner
    function withdrawToken(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);

        // needs to execute `approve()` on the token contract to allow itself the transfer
        uint256 balance = IERC20(_tokenContract).balanceOf(address(this));
        tokenContract.approve(address(this), balance);

        tokenContract.transferFrom(address(this), owner(), balance);
        emit Withdrawn(owner(), balance);
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //
    function getRentPrice(
        IRegistrarController _registrarController,
        string memory name,
        uint256 duration
    ) internal view returns (uint256) {
        if (block.chainid == 56 || block.chainid == 97) {
            IPriceOracle.Price memory price = _registrarController.rentPrice(name, duration);
            return price.base + price.premium;
        } else {
            return _registrarController.rentPriceInt(name, duration);
        }
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Pure Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //
}