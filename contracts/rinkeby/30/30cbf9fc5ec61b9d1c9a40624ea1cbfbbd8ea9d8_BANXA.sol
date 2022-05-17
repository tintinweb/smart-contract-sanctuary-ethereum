/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;
pragma abicoder v2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
}


contract BANXA is Ownable {
    using SafeMath for uint256;

    struct Bank {
        uint iban;
        string name;
        string add;
        string country;
        uint routing;
        string currency;
    }

    struct Recipient {
        string name;
        string add;
        string country;
        Bank bank;
    }

    mapping(address => bool) public authorizedTokens;
    mapping(uint256 => bool) public authorizedRecipients;
    mapping(uint256 => Recipient) public recipients;

    uint256 oneUnit = 10 ** 18;
    uint256 public fee = 0;
    uint256 public min = 0;
    uint256 public count = 1;

    event Transmit(
        address indexed transactor,
        uint256 banxaId,
        address token,
        uint256 amount,
        uint256 amountFee
    );

    event ActivateAccount(
        address indexed transactor,
        uint256 indexed _banxaId
    );

    event AddRecipient(address wallet, uint256 indexed code);

    constructor() Ownable() {

    }

    function transmit(
        address _token,
        uint256 _amount,
        uint256 _banxaId
    ) public returns (bool) {
        require(_amount >= min);
        require(authorizedRecipients[_banxaId] == true);

        // Subtract fee from transaction
        uint256 amountAfterFee = _amount.sub(fee);

        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _amount);
        emit Transmit(msg.sender, _banxaId, _token, amountAfterFee, fee);
        return true;
    }

    function activateAccount(
        uint256 _banxaId
    ) public onlyOwner returns (bool) {
        authorizedRecipients[_banxaId] = true;
        emit ActivateAccount(msg.sender, _banxaId);
        return true;
    }

    function addRecipient(
        string memory name,
        string memory add,
        string memory country,
        Bank memory bank
    ) public returns (uint256) {
        uint256 banxaId = count++;
        recipients[banxaId] = Recipient(name, add, country, bank);
        authorizedRecipients[banxaId] = false;

        emit AddRecipient(msg.sender, banxaId);
        return banxaId;
    }

    function withdraw(
        address _token,
        uint256 _amount,
        address _recipient
    ) public onlyOwner returns (bool) {
        IERC20 t = IERC20(_token);
        t.transfer(_recipient, _amount);
        return true;
    }
}