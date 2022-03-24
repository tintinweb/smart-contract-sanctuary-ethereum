//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract TokenInterface {
    function transfer(address _receiver, uint _amount) public virtual returns (bool);
    function burn(address _address, uint256 _amount) external virtual;
    function allowance(address owner, address spender) public view virtual returns (uint256);
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool);
    function balanceOf(address account) public view virtual returns (uint256);
}

contract Defi is Ownable {
    TokenInterface public firstToken;
    TokenInterface public secondToken;

    uint256 public firstToSecondTokenRate;
    uint256 public secondToFirstTokenRate;

    constructor() {
    }

    struct LiquidityPool {
        uint256 reward;
        uint256 totalAmount;
        mapping(address => uint) balances;
    }

    LiquidityPool public firstTokenLP;
    LiquidityPool public secondTokenLP;
  
    function setFirstToken(address _address) external onlyOwner {
        firstToken = TokenInterface(_address);
    }

    function setSecondToken(address _address) external onlyOwner {
        secondToken = TokenInterface(_address);
    }

    function setFirstTokenLPReward(uint256 _reward) external onlyOwner {
        firstTokenLP.reward = _reward;
    }

    function setSecondTokenLPReward(uint256 _reward) external onlyOwner {
        secondTokenLP.reward = _reward;
    }

    function getFirstTokenTotalLpBalance() public view returns (uint256) {
        return firstTokenLP.totalAmount;
    }

    function getSecondTokenTotalLpBalance() public view returns (uint256) {
        return secondTokenLP.totalAmount;
    }

    function getUserFirstTokenLpBalance() public view returns (uint256) {
        return firstTokenLP.balances[msg.sender];
    }

    function userSecondTokenLpBalance() public view returns (uint256) {
        return secondTokenLP.balances[msg.sender];
    }

    function depositFirstTokenToStaking(uint256 _amount) external {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = firstToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        firstToken.transferFrom(msg.sender, address(this), _amount);
        firstTokenLP.totalAmount = firstTokenLP.totalAmount + _amount;
        if (firstTokenLP.balances[msg.sender] == 0) {
            firstTokenLP.balances[msg.sender] = _amount;
        } else {
            firstTokenLP.balances[msg.sender] = firstTokenLP.balances[msg.sender] + _amount;
        }
    }

    function depositSecondTokenToStaking(uint256 _amount) external {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = secondToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        secondToken.transferFrom(msg.sender, address(this), _amount);
        secondTokenLP.totalAmount = secondTokenLP.totalAmount + _amount;
        if (secondTokenLP.balances[msg.sender] == 0) {
            secondTokenLP.balances[msg.sender] = _amount;
        } else {
            secondTokenLP.balances[msg.sender] = secondTokenLP.balances[msg.sender] + _amount;
        }
    }

    function firstToSecondExchange(uint256 _amount) external {
        exchange(_amount, firstToken, secondToken, firstToSecondTokenRate);
    }

    function secondToFirstExchange(uint256 _amount) external {
        exchange(_amount, secondToken, firstToken, secondToFirstTokenRate);
    }

    function exchange(uint256 _amount, TokenInterface sendToken, TokenInterface receiveToken, uint256 rate) private {
        require(_amount > 0, "You need to sell at least some tokens");
        uint256 allowance = sendToken.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Check the token allowance");
        sendToken.transferFrom(msg.sender, address(this), _amount);

        //uint256 outPutValue = _amount * ((rate) / 10**18);
        uint256 outPutValue = _amount;

        require(outPutValue <= sendToken.balanceOf(address(this)), "Not enough money in the pool");

        receiveToken.transfer(msg.sender, outPutValue);
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