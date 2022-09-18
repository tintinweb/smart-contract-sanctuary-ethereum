// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Transfer is Ownable {
    struct Opening {
        string hackathonId;
        uint256 amount;
        string denomination;
        address from;
        address to;
        string executedAt;
    }

    struct Closing {
        string hackathonId;
        uint256 amount;
        string denomination;
        address from;
        address to;
        string executedAt;
    }

    mapping(string => Opening) private _openings;
    string[] private _openingKeys;
    mapping(string => Closing) private _closings;
    string[] private _closingKeys;

    function openHackathon(
        string memory _hackathonId,
        uint256 _amount,
        string memory _denomination,
        string memory _executedAt
    ) public {
        require(
            keccak256(bytes(_hackathonId)) != keccak256(bytes("")),
            "hackathon id is empty."
        );
        require(
            _isValidDenomination(_denomination),
            "denomination should be USDC or USDT."
        );
        require(
            keccak256(bytes(_executedAt)) != keccak256(bytes("")),
            "executed at is empty."
        );

        require(
            !_existsInOpenings(_hackathonId),
            "this hackathon is already open."
        );

        _transfer(owner(), _amount, _denomination);

        _openings[_hackathonId] = Opening(
            _hackathonId,
            _amount,
            _denomination,
            msg.sender,
            owner(),
            _executedAt
        );
        _openingKeys.push(_hackathonId);
    }

    function getOpening(string memory _hackathonId)
        public
        view
        returns (Opening memory)
    {
        require(
            _existsInOpenings(_hackathonId),
            "the hackathon doesn't exist."
        );
        return _openings[_hackathonId];
    }

    function getOpenings() public view returns (Opening[] memory) {
        Opening[] memory ret = new Opening[](_openingKeys.length);
        for (uint256 i = 0; i < _openingKeys.length; i++) {
            ret[i] = _openings[_openingKeys[i]];
        }
        return ret;
    }

    function closeHackathon(
        string memory _hackathonId,
        uint256 _amount,
        string memory _denomination,
        address _to,
        string memory _executedAt
    ) public {
        require(
            _isOrganizer(_hackathonId, msg.sender),
            "only organizer can close hackathon."
        );

        require(
            keccak256(bytes(_hackathonId)) != keccak256(bytes("")),
            "hackathon id is empty."
        );
        require(
            _isValidDenomination(_denomination),
            "denomination should be USDC or USDT."
        );
        require(_to != address(0), "address is empty.");
        require(
            keccak256(bytes(_executedAt)) != keccak256(bytes("")),
            "executed at is empty."
        );

        require(_existsInOpenings(_hackathonId), "this hackathon isn't open.");
        require(
            !_existsInClosings(_hackathonId),
            "this hackathon is already closed."
        );

        _transfer(_to, _amount, _denomination);

        _closings[_hackathonId] = Closing(
            _hackathonId,
            _amount,
            _denomination,
            msg.sender,
            _to,
            _executedAt
        );
        _closingKeys.push(_hackathonId);
    }

    function getClosing(string memory _hackathonId)
        public
        view
        returns (Closing memory)
    {
        require(
            _existsInClosings(_hackathonId),
            "the hackathon doesn't exist."
        );
        return _closings[_hackathonId];
    }

    function getClosings() public view returns (Closing[] memory) {
        Closing[] memory ret = new Closing[](_closingKeys.length);
        for (uint256 i = 0; i < _closingKeys.length; i++) {
            ret[i] = _closings[_closingKeys[i]];
        }
        return ret;
    }

    function canBeClosed(string memory _hackathonId, address _address)
        public
        view
        returns (bool)
    {
        return
            _isOrganizer(_hackathonId, _address) &&
            _existsInOpenings(_hackathonId) &&
            !_existsInClosings(_hackathonId);
    }

    // -------------- private functions --------------

    function _isValidDenomination(string memory _denomination)
        private
        pure
        returns (bool)
    {
        return
            keccak256(bytes(_denomination)) == keccak256(bytes("USDC")) ||
            keccak256(bytes(_denomination)) == keccak256(bytes("USDT"));
    }

    function _existsInOpenings(string memory _hackathonId)
        private
        view
        returns (bool)
    {
        Opening memory _opening = _openings[_hackathonId];
        return _opening.from != address(0);
    }

    function _existsInClosings(string memory _hackathonId)
        private
        view
        returns (bool)
    {
        Closing memory _closing = _closings[_hackathonId];
        return _closing.from != address(0);
    }

    function _isOrganizer(string memory _hackathonId, address _address)
        private
        view
        returns (bool)
    {
        Opening memory _opening = _openings[_hackathonId];
        return _address == _opening.from;
    }

    function _transfer(
        address _to,
        uint256 _amount,
        string memory _denomination
    ) private {
        address usdcAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address usdtAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

        address usingAddress = usdcAddress;
        if (keccak256(bytes(_denomination)) == keccak256(bytes("USDT"))) {
            usingAddress = usdtAddress;
        }

        IERC20 token = IERC20(address(usingAddress));
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "invalid amount.");
        token.transferFrom(msg.sender, _to, _amount);
    }
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