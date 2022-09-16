// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
contract ETHPool is  Ownable {

    address public teamAddress;
    uint256 public calcTotalAmountsForReward;
    uint256 public totalAmounts;
    struct Info {
        uint256 poolAmounts;
        uint256 rewardTime;
    }
    mapping(address => Info) public poolInfo;
    mapping(address => bool) public addListed;
    address[] private poolList;

    constructor(address _teamAddress) {
        teamAddress = _teamAddress;
        totalAmounts = 0;
    }

    function setTeamAddress(address _teamAddress) public onlyOwner {
        require(teamAddress !=_teamAddress, "TeamAddress can not be updated with same address.");
        teamAddress = _teamAddress;
    }

    function depositUser() public payable{
        require(msg.value > 0, "Deposit amounts must be bigger than zero.");
        require(msg.sender != teamAddress, "teamAddress can not deposit as User.");
        if(addListed[msg.sender] == false){
            poolList.push(msg.sender);
            addListed[msg.sender] = true;
            poolInfo[msg.sender] = Info(msg.value, block.timestamp);
        }
        else{
            poolInfo[msg.sender] = Info(poolInfo[msg.sender].poolAmounts + msg.value, poolInfo[msg.sender].rewardTime);
        }
        totalAmounts += msg.value;        
    }

    function withdrawUser(uint256 _amounts) public {
        require(_amounts > 0, "WithDraw amounts must be bigger than zero.");
        require(msg.sender != teamAddress, "teamAddress can not withdraw.");
        require(_amounts <= poolInfo[msg.sender].poolAmounts, "WithDraw amounts must be smaller than pool amounts of user.");
        uint256 balance = address(this).balance;
        require(balance >= _amounts);
        (bool success, ) = _msgSender().call{value: _amounts}("");
        require(success, "WithDraw failed.");
        totalAmounts -= _amounts;         
    }

    function depositTeam() public payable{
        require(msg.value > 0, "Deposit amounts must be bigger than zero.");
        require(msg.sender == teamAddress, "sender must be team address.");
        require(totalAmounts > 0, "team can not deposit when ther is no eth on pool.");
        calcTotalAmountsForReward  = 0 ;
        for (uint256 i = 0; i < poolList.length; i++) {
            calcTotalAmountsForReward += poolInfo[poolList[i]].poolAmounts * (block.timestamp - poolInfo[poolList[i]].rewardTime);
        }
        for (uint256 i = 0; i < poolList.length; i++) {            
            poolInfo[poolList[i]]  = Info(poolInfo[poolList[i]].poolAmounts + msg.value * poolInfo[poolList[i]].poolAmounts * (block.timestamp - poolInfo[poolList[i]].rewardTime) / calcTotalAmountsForReward, block.timestamp);
        }
        calcTotalAmountsForReward = 0;
        totalAmounts += msg.value;  
    }

    function getPoolAmounts(address _user) public view returns (uint256){
        return poolInfo[_user].poolAmounts;
    }

    function getPoolAmountsOfAllUser() public view returns (address[] memory, uint256[] memory){
        address[] memory _user;
        uint256[] memory _amounts;
        for (uint256 i = 0; i < poolList.length; i++) {
            _user[i] = poolList[i];
            _amounts[i] = poolInfo[poolList[i]].poolAmounts;
        }
        return (_user, _amounts);
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