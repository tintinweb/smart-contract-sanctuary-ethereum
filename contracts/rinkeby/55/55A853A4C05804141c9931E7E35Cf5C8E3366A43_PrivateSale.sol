pragma solidity ^0.6.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract TestToken {
    function balanceOf(address account) public view returns (uint256) {}
    function transferFrom(address sender, address recipient, uint256 amount) public {}
    function approve(address spender, uint256 amount) public {}
}

contract PrivateSale is Ownable{

    uint256 private allocatedLiquidity;
    address payable private adminWallet;
    TestToken private token;

    mapping (address => uint256) private lockedByAddress;
    mapping (address => uint256) private lockTime;

    constructor(address _token, address payable _adminWallet) public {
        adminWallet = _adminWallet;
        token = TestToken(_token);
        allocatedLiquidity = 0;
    }

    function getPrivateSaleLiquidity() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getAllocatedLiquidity() public view returns (uint256) {
        return allocatedLiquidity;
    }

    function getLiquidityByUser(address privateInvestor) public view returns(uint256) {
        return lockedByAddress[privateInvestor];
    }

    function getLockTimeyByUser(address privateInvestor) public view returns(uint256) {
        return lockTime[privateInvestor];
    }

    function setLockedTokens(address[] memory privateInvestors, uint256[] memory amounts) public onlyOwner{
        require(privateInvestors.length == amounts.length, "PrivateSale: invalid arrays length");
        for(uint index=0; index<privateInvestors.length; index++){
            require(allocatedLiquidity + amounts[index] <= getPrivateSaleLiquidity(), "PrivateSale: Amount is exceeding from max liquidity");
            lockedByAddress[privateInvestors[index]] = amounts[index];
            lockTime[privateInvestors[index]] = block.timestamp + 300;
            allocatedLiquidity += amounts[index];
        }
    }

    function claim() public {
        require(lockedByAddress[msg.sender] > 0 , "User does not belong to private investors");
        require(lockTime[msg.sender] < block.timestamp, "Quantity is locked");
        uint256 amount = lockedByAddress[msg.sender];
        require(getPrivateSaleLiquidity() >= amount, "Insufficient Amount to claim");
        lockedByAddress[msg.sender] = 0;
        lockTime[msg.sender] = 0;
        allocatedLiquidity -= amount;
        token.transferFrom(address(this), msg.sender, amount);
    }

    function withdrawLiquidity(uint256 amount) public onlyOwner {
        require(getPrivateSaleLiquidity() - allocatedLiquidity >= amount,"Insufficient Amount to withdraw" );
        adminWallet.transfer(amount);
    }

    function approve() public onlyOwner {
        token.approve(address(this), getPrivateSaleLiquidity());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}