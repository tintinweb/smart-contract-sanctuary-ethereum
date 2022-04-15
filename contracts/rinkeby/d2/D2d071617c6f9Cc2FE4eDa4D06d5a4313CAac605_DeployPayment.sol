//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeployPayment is Context, Ownable {
    uint256 public lastedId;
    uint256 public fee;
    address public admin;

    struct Pay {
        uint256 fee;
        address account;
        address token;
        string name;
        string symbol;
        bool isSingle;
        bool isPay;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin || _msgSender() == owner(), "caller is not the admin");
        _;
    }

    modifier onlyFundReceiver() {
        require(_msgSender() == admin || fundReceivers[_msgSender()], "caller is not the fund receiver");
        _;
    }

    mapping (uint256 => Pay) public pays;
    mapping (address => uint256) public lastPayIds;
    mapping (address => bool) public fundReceivers;
    mapping (address => Pay[]) private tokenDeployeds;

    event Deposit(uint256 indexed payId, bool isSingle, string name, string symbol, uint256 value);
    event SetTokenDeployedTo(uint256 indexed payId, address token);
    event CancelPayment(uint256 indexed payId);
    event Withdraw(address fundReceiver, uint256 value);
    event UpdateFee(uint256 fee);

    constructor(uint256 _fee, address _admin) {
        require(_admin != address(0), "admin is the zero address");
        fee = _fee;
        admin = _admin;
    }

    function deposit(bool _isSingle, string memory _name, string memory _symbol) external payable {
        require(msg.value == fee, "invalid value");
        lastPayIds[_msgSender()] = ++lastedId;
        Pay storage pay = pays[lastedId];
        pay.fee         = msg.value;
        pay.account     = _msgSender();
        pay.isSingle    = _isSingle;
        pay.name        = _name;
        pay.symbol      = _symbol;
        pay.isPay       = true;
        emit Deposit(lastedId, _isSingle, _name, _symbol, msg.value);
    }

    function setTokenDeployedTo(uint256 _payId, address _token) external onlyOwner {
        require(_payId > 0, "invalid pay id");
        require(_token != address(0), "token is the zero address");
        Pay storage pay = pays[_payId];
        require(pay.isPay, "unpaid user");
        require(pay.token == address(0), "token is already deployed");
        pay.token = _token;
        tokenDeployeds[pay.account].push(pay);
        emit SetTokenDeployedTo(_payId, _token);
    }

    function cancelPayment(uint256 _payId) external payable onlyOwner {
        require(_payId > 0, "invalid pay id");
        Pay storage pay = pays[_payId];
        require(pay.isPay, "unpaid user");
        require(pay.token == address(0), "token is already deployed");
        payable(pay.account).transfer(pay.fee);
        pay.isPay = false;
        emit CancelPayment(_payId);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "admin is the zero address");
        admin = _newAdmin;
    }

    function addFundReceiver(address _account) external onlyAdmin {
        require(_account != address(0), "account is the zero address");
        fundReceivers[_account] = true;
    }

    function removeFundReceiver(address _account) external onlyAdmin {
        require(_account != address(0), "account is the zero address");
        fundReceivers[_account] = false;
    }

    function withdraw() external onlyFundReceiver {
        uint256 _balance = address(this).balance;
        payable(_msgSender()).transfer(_balance);
        emit Withdraw(_msgSender(), _balance);
    }

    function updateFee(uint256 _fee) external onlyAdmin {
        fee = _fee;
        emit UpdateFee(_fee);
    }

    function getBalance() external view returns(uint256) {
        return address(this).balance;
    }

    function getPay(uint256 _payId) external view returns(Pay memory) {
        require(_payId > 0, "invalid pay id");
        return pays[_payId];
    }

    function getTokenDeployeds(address _account) external view returns(Pay[] memory) {
        require(_account != address(0), "account is the zero address");
        return tokenDeployeds[_account];
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/DeployPayment.sol";

contract $DeployPayment is DeployPayment {
    constructor(uint256 _fee, address _admin) DeployPayment(_fee, _admin) {}

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}