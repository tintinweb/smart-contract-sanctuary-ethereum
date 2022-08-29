// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBridge.sol";
import "./TokenPool.sol";
import "./Authorizable.sol";

/**
 * @dev Change to external token pool if block gas limit becomes an issue
 * @dev Bridge implements IBridge interface to mint and burn transactions
 */

contract Bridge is IBridge, TokenPool, Authorizable {
    // Burns global counter
    uint256 private burnNonce = 0;
    // Mapping client -> nonce when minted where the nonce is the burn nonce in ZCN
    mapping(bytes => uint256) private userNonceMinted;

    modifier notMinted(bytes calldata clientId_, uint256 nonce_) {
        require(
            userNonceMinted[clientId_] + 1 == nonce_,
            "ifNotMinted: nonce provided must 1 greater than the previous burn nonce."
        );
        _;
    }

    /**
     * @dev Initializes the contract, sets {token} {authorizers} and
     * initializes authorizers and token pool.
     */
    constructor(IERC20 _token, IAuthorizers _authorizers)
        TokenPool(_token)
        Authorizable(_authorizers)
    {}

    /**
     * @dev see {IBridge-burn}
     */
    function burn(uint256 _amount, bytes calldata _clientId) external override {
        _burn(msg.sender, _amount, _clientId);
    }

    /**
     * @dev Implementation of the burn function
     * @param _from - the address to burn tokens from
     * @param _amount - The amount of tokens to burn
     * @param _clientId - The 0chain client ID of the burner
     */
    function _burn(
        address _from,
        uint256 _amount,
        bytes memory _clientId
    ) private {
        require(
            this.token().transferFrom(_from, address(this), _amount),
            "Bridge: transfer into burn pool failed"
        );
        // first nonce is 1 not 0
        burnNonce = burnNonce + 1;
        emit Burned(_from, _amount, _clientId, burnNonce);
    }

    /**
     * @dev see {Ibridge-mint}
     */
    function mint(
        uint256 _amount,
        bytes calldata _txid,
        bytes calldata _clientId,
        uint256 _nonce,
        bytes calldata _signatures
    ) external override notMinted(_clientId, _nonce) {
        Message.Args memory args = Message.Args(
            msg.sender,
            _amount,
            _txid,
            _clientId,
            _nonce
        );

        bytes32 message = authorizers().messageHash(
            msg.sender,
            _amount,
            _txid,
            _clientId,
            _nonce
        );

        _mint(args, message, _signatures);
    }

    /**
     * @dev implements third party mint execution
     */
    function mintFor(
        address _for,
        uint256 _amount,
        bytes calldata _txid,
        bytes calldata _clientId,
        uint256 _nonce,
        bytes calldata _signatures
    ) external notMinted(_clientId, _nonce) {
        // CompileError: CompilerError: Stack too deep.
        // Try compiling with `--via-ir` (cli) or the equivalent `viaIR: true` (standard JSON)
        // while enabling the optimizer. Otherwise, try removing local variables.
        address to = _for;
        uint256 amount = _amount;
        bytes calldata txid = _txid;
        bytes calldata clientId = _clientId;
        uint256 nonce = _nonce;
        bytes calldata signatures = _signatures;
        Message.Args memory args = Message.Args(
            to,
            amount,
            txid,
            clientId,
            nonce
        );
        bytes32 message = authorizers().messageHash(
            to,
            amount,
            txid,
            clientId,
            nonce
        );
        _mint(args, message, signatures);
    }

    /**
     * @dev Implementation of the mint function
     * @param _args    - Arguments for message
     * @param _message - The message generated and signed by authorizers
     * @param _signatures - The validated signatures concatenated
     */
    function _mint(
        Message.Args memory _args,
        bytes32 _message,
        bytes calldata _signatures
    ) private isAuthorized(_message, _signatures) {
        //Authorizer logic
        require(
            this.token().transfer(_args.to, _args.amount),
            "Bridge: transfer out of pool failed"
        );

        userNonceMinted[_args.clientId] = _args.nonce;
        emit Minted(
            _args.to,
            _args.amount,
            _args.txid,
            _args.clientId,
            _args.nonce
        );
    }

    // TODO UPDATE THIS

    function isAuthorizationValid(
        uint256 _amount,
        bytes calldata _txid,
        bytes calldata _clientId,
        uint256 _nonce,
        bytes calldata signature
    ) external returns (bool) {
        bytes32 message = authorizers().messageHash(
            msg.sender,
            _amount,
            _txid,
            _clientId,
            _nonce
        );
        return validAuthorization(message, signature);
    }

    function validAuthorization(bytes32 message, bytes calldata signatures)
        internal
        isAuthorized(message, signatures)
        returns (bool)
    {
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenPool is Ownable {
    IERC20 public token;

    constructor(IERC20 _token) {
        token = _token;
    }

    function balance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    //function transfer(address to, uint256 value) external onlyOwner returns (bool) {
    //    return token.transfer(to, value);
    //}

    function rescueFunds(
        address tokenToRescue,
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        require(
            address(token) != tokenToRescue,
            "TokenPool: Cannot claim token held by the contract"
        );

        return IERC20(tokenToRescue).transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Message {
    struct Args {
        // The address to mint the tokens to
        address to;
        // The amount of tokens to mint
        uint256 amount;
        // The txid of the burn transaction on the 0chain
        bytes txid;
        // The ZCN client ID
        bytes clientId;
        // The burn nonce from ZCN used to sign the message
        uint256 nonce;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title Bridge interface
 * @dev Interface for a token bridge implements mint and burn transaction
 */

interface IBridge {
    event Burned(
        address indexed from,
        uint256 amount,
        bytes indexed clientId,
        uint256 indexed nonce
    );
    event Minted(
        address indexed to,
        uint256 amount,
        bytes txid,
        bytes indexed clientId,
        uint256 indexed nonce
    );

    /**
     * @dev a function to lock tokens into the burned token pool
     * @param _amount - the amount of tokens to be locked
     * @param _clientId - the ZCN chain client Id of the user to receive tokens on the ZCN chain
     */
    function burn(uint256 _amount, bytes calldata _clientId) external;

    /**
     * @dev A function to mint(transfer from burned token pool) wrapped ZCN tokens
     * @param _amount - the amount to be minted
     * @param _txid - the txid of the Z chain transaction
     * @param _nonce - the nonce used in the burn transaction
     * @param signatures - the signature authorizing the transaction
     */
    function mint(
        uint256 _amount,
        bytes calldata _txid,
        bytes calldata _clientId,
        uint256 _nonce,
        bytes calldata signatures
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Message.sol";

interface IAuthorizers {
    /**
     * @dev returns whether a message is authorized based on signatures
     * @param message - The message to be authorized
     * @param signatures - The signatures authorizing the message
     * @return boolean - True/False: The message is authorized?
     */
    function authorize(bytes32 message, bytes calldata signatures)
        external
        returns (bool);

    /**
     * @dev returns the message hash to be signed base on given parameters
     * @param _to - Address to the transaction is for
     * @param _amount - the Amount of tokens the transaction is for
     * @param _txid - The transaction Id of the Burn transaction on the 0Chain
     * @param _clientId - The ZCN clientID
     * @param _nonce - The nonce used in the signature
     * @return bytes32 - The Ethereum signature formatted hash
     */
    function messageHash(
        address _to,
        uint256 _amount,
        bytes calldata _txid,
        bytes calldata _clientId,
        uint256 _nonce
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAuthorizers.sol";

/**
 * @dev Contract module which provides an access control mechanism,
 * where there is an external contract instance of IAuthorizers that
 * implements logic checking and validating signatures against a message
 */
abstract contract Authorizable is Ownable {
    IAuthorizers private _authorizers;

    event AuthorizersTransferred(
        address indexed previousAuthorizers,
        address indexed newAuthorizers
    );

    constructor(IAuthorizers __authorizers) {
        _authorizers = __authorizers;
        emit AuthorizersTransferred(address(0), address(__authorizers));
    }

    /**
     * @dev returns the Authorizers Interface instance
     */
    function authorizers() public view returns (IAuthorizers) {
        return _authorizers;
    }

    // Authorizer logic called from here
    // @dev Throws if called by an account other than the owner.
    modifier isAuthorized(bytes32 message, bytes calldata signatures) {
        require(
            _authorizers.authorize(message, signatures),
            "Authorizers: signatures not authorized"
        );
        _;
    }

    // modifier hasFee(uint256 amount) {
    //     require(amount >= fee, "Auth fee not satisfied");
    // }

    // Only included to maintain consistency with Ownable contract
    // function renounceAuthorizership() public virtual isAuthorized(0x00, 0x00) {
    //     emit AuthorizersTransferred(address(_authorizers), address(0));
    //     _authorizers = address(0);
    // }

    // function transferAuthorizership(IAuthorizers newAuthorizers) public virtual isAuthorized(0x00, 0x00) {
    //     require(address(newAuthorizers) != address(0), "Authorizable: new authorizer cannot be zero address");
    //     emit AuthorizersTransferred(address(_authorizers), address(newAuthorizers));
    //     _authorizers = newAuthorizers;
    // }
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