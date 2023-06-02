// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20_USDT {
    function transferFrom(address from, address to, uint value) external;
    function transfer(address to, uint value) external;
}

contract FlowrrSeed is Ownable{

    uint256 private constant baseDivider = 10000;
    uint32 private feePercents = 100;
    address public feeAddr;
    bool public avail_wd = true;
    address public devAddress;

    //Modifier
    modifier onlyGovernance() {
        require(
            (msg.sender == devAddress || msg.sender == owner()),
            "onlyGovernance:: Not gov"
        );
        _;
    }

    //Events
    event DepositToken(uint256 uid, address account, uint256 amount, address token, uint256 fees);
    event WithdrawToken(address account, uint256 amount, address token);

    constructor(
        address _feeAddr,
        address _devAddress
    ) {
        feeAddr = _feeAddr;
        devAddress = _devAddress;
    }

    //BNB----------------------------
    receive() external payable{
        revert();
    }
    //Token--------------------------
    function depositToken(uint256 uid, uint256 amount, address _tokenAddress) external {
        IERC20_USDT(_tokenAddress).transferFrom(msg.sender, address(this), amount);
        uint256 fees = amount * uint256(feePercents) / baseDivider;
        IERC20_USDT(_tokenAddress).transfer(feeAddr, fees);
        emit DepositToken(uid, msg.sender, amount, _tokenAddress, fees);
    }

    function withdrawToken(address account, uint256 amount, address _tokenAddress) external onlyGovernance {
        require(avail_wd, "Withdraw Currently Unavailable");
        IERC20_USDT(_tokenAddress).transfer(account, amount);
        emit WithdrawToken(account, amount, _tokenAddress);
    }

    //Dev
    function getFeePercent() external onlyGovernance view returns(uint32) {
        return feePercents;
    }

    function switch_wd() external onlyGovernance {
        avail_wd = !avail_wd;
    }

    function update_fees(uint32 _percent) external onlyGovernance{
        feePercents = _percent;
    }

    function update_feeAddr(address _addr) external onlyGovernance{
        require(_addr != address(0), "_Zero Address");
        feeAddr = _addr;
    }

    function changeDev(address account) external onlyOwner {
        require(account != address(0), "Address 0");
        devAddress = account;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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