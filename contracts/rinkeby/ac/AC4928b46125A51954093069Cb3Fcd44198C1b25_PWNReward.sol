/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

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


interface IPWN {
    function totalSupply() external view returns (uint256); 
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function balanceOf(address acount) external view returns (uint256);
    function decimals() external view returns (uint256);
    function getMinter() external view returns (address);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract PWNReward is Ownable {
    IPWN public pwnContract;
    address public teamWallet = 0x3148a90B8a7Ef0Acf96Ec37cE5a1637968c8ffFA;
    uint256 private passport;
    uint256 public rewardAmount = 1 * 10 ** 18;

    bool public active = true;

    struct GameInfo {
        string gameId;
        address creatorAddress;
        address connectorAddress;
        uint256 startTimestamp;
        address winnerAddress;
        uint8 base;
        uint8 add;
    }
    GameInfo[] public history;
    
    mapping(address => uint256) public winCounts;
    mapping(uint256 => uint256) private deposits;

    constructor(address _pwn) {
        pwnContract = IPWN(_pwn);
    }

    function getBlockTimestamp() public view returns(uint256 timestamp) {
        return block.timestamp;
    }

    function getPWNBalanceOf(address _user) external view returns (uint256) {
        return pwnContract.balanceOf(_user);
    }

    function setActive(bool _active) external onlyOwner {
        active = _active;
    }

    function issuePassport(uint256 _passport) external onlyOwner {
        passport = _passport;
    }

    function setTeamWallet(address _address) external onlyOwner {
        teamWallet = _address;
    }

    function setPWNContract(address _pwn) external onlyOwner {
        pwnContract = IPWN(_pwn);
    }

    function setRewardAmount(uint256 _rewardAmount) external onlyOwner {
        rewardAmount = _rewardAmount;
    }

    function getWinCounts(address _player) public view returns(uint256) {
        return winCounts[_player];
    }
    function distributeReward(GameInfo  memory _gameInfo, uint256 _passport) external onlyOwner {
        require(active == true, "Reward functionality is not active yet.");
        require(passport == _passport, "Passport is not authorized.");
        require(_gameInfo.creatorAddress != address(0), "Creator Wallet address is not set.");
        require(_gameInfo.connectorAddress != address(0), "Creator Wallet address is not set.");
        require(pwnContract.getMinter() == address(this), "The smart contracts is not set as minter of PWN token");

        pwnContract.mint(_gameInfo.winnerAddress, rewardAmount);
        winCounts[_gameInfo.winnerAddress] += 1;
        history.push(_gameInfo);
    }
}