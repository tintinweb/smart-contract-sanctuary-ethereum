/**
 *Submitted for verification at Etherscan.io on 2022-08-27
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

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
   */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
    function allowance(address _owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

contract BUSDLotto is Ownable {
    address private BUSDContract;
    address private developerWallet;
    uint256 public constant PRICE = 10 ether;

    mapping(address => address) private referrals;
    mapping(address => uint256) private referralsDiff;
    mapping(address => uint256) private rewards;
    mapping(address => uint256) private userIndex;
    mapping(uint256 => address) private users;
    mapping(uint256 => address) private tickets;
    mapping(uint256 => uint256) public winners;
    mapping(uint256 => uint256) public winnersTimestamp;

    uint256 public _currentIndex;
    uint256 private nonce;
    uint256 private currentUserIndex = 100000;

    address [] referralsArray;

    constructor(address _contract, uint256 _nonce, address _developer) {
        BUSDContract = _contract;
        nonce = _nonce;
        developerWallet = _developer;
    }

    function buyTicket(uint256 numberOfTickets, uint256 referral) external {
        require(IBEP20(BUSDContract).balanceOf(msg.sender) >= numberOfTickets * PRICE);
        require(IBEP20(BUSDContract).allowance(msg.sender, address(this)) >= numberOfTickets * PRICE);

    unchecked {
        if (userIndex[msg.sender] == 0) {
            registerUser();
        }

        if (referral != 0 && referrals[msg.sender] == address(0)) {
            if (msg.sender != users[referral]) {
                referrals[msg.sender] = users[referral];
                referralsDiff[msg.sender] = balanceTicketsOf(msg.sender);
                referralsArray.push(msg.sender);
            }
        }

        uint256 developerReward = 1 ether;

        if (referrals[msg.sender] != address(0)) {
            bool transferStatusRef = IBEP20(BUSDContract).transferFrom(msg.sender, referrals[msg.sender], numberOfTickets * 1 ether);
            require(transferStatusRef, "Lottery: Transfer BUSD error (ref)");
        } else {
            developerReward += 1 ether;
        }

        bool transferStatusDev = IBEP20(BUSDContract).transferFrom(msg.sender, developerWallet, numberOfTickets * developerReward);
        require(transferStatusDev, "Lottery: Transfer BUSD error (dev)");

        bool transferStatus = IBEP20(BUSDContract).transferFrom(msg.sender, address(this), numberOfTickets * (PRICE - 2 ether));
        require(transferStatus, "Lottery: Transfer BUSD error (buy)");

        for(uint i = 0; i < numberOfTickets; i++) {
            nextTicket(msg.sender);
        }
    }
    }

    function registerUser() public {
        require(userIndex[msg.sender] == 0);
    unchecked {
        currentUserIndex++;
        userIndex[msg.sender] = currentUserIndex;
        users[currentUserIndex] = msg.sender;
    }
    }

    function userId(address user) public view returns(uint256) {
        return userIndex[user];
    }

    function nextTicket(address buyer) private {
    unchecked {
        _currentIndex++;
        tickets[_currentIndex] = buyer;

        if (_currentIndex % 10 == 0) {
            uint256 winner = random(_currentIndex - 9, _currentIndex);
            winners[winner] = 40;
            winnersTimestamp[winner] = block.timestamp;
            rewards[tickets[winner]] += 40 ether;
        }

        if (_currentIndex % 100 == 0) {
            uint256 winner = random(_currentIndex - 99, _currentIndex);
            winners[winner] = 100;
            winnersTimestamp[winner] = block.timestamp;
            rewards[tickets[winner]] += 100 ether;
        }

        if (_currentIndex % 1000 == 0) {
            uint256 winner = random(_currentIndex - 999, _currentIndex);
            winners[winner] = 1000;
            winnersTimestamp[winner] = block.timestamp;
            rewards[tickets[winner]] += 1000 ether;
        }

        if (_currentIndex % 10000 == 0) {
            uint256 winner = random(_currentIndex - 9999, _currentIndex);
            winners[winner] = 10000;
            winnersTimestamp[winner] = block.timestamp;
            rewards[tickets[winner]] += 10000 ether;
        }

        if (_currentIndex % 100000 == 0) {
            uint256 winner = random(_currentIndex - 99999, _currentIndex);
            winners[winner] = 100000;
            winnersTimestamp[winner] = block.timestamp;
            rewards[tickets[winner]] += 100000 ether;
        }
    }
    }

    function claim() external {
        require(rewards[msg.sender] > 0);
        require(IBEP20(BUSDContract).balanceOf(address(this)) >= rewards[msg.sender]);

    unchecked {
        uint256 _reward = rewards[msg.sender];
        rewards[msg.sender] -= _reward;
        bool claimStatus = IBEP20(BUSDContract).transfer(msg.sender, _reward);
        require(claimStatus, "Lottery: Transfer claim BUSD error");
    }
    }

    function random(uint256 min, uint256 max) internal returns(uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce)));
        nonce++;
        return min + rand % (max + 1 - min);
    }

    function rewardOf(address user) public view returns(uint256) {
        return rewards[user];
    }

    function balanceTicketsOf(address user) public view returns(uint256) {
        uint256 _ticketsCount;

    unchecked {
        for(uint256 i = 1; i <= _currentIndex; i++) {
            if (tickets[i] == user) {
                _ticketsCount++;
            }
        }
    }

        return _ticketsCount;
    }

    function getWinners() public view returns (address[] memory, uint256[] memory, uint256[] memory) {
        uint256 count = getCountWinners();
        address[] memory _winners = new address[](count);
        uint256[] memory _winnersSum = new uint256[](count);
        uint256[] memory _winnersDate = new uint256[](count);
        uint256 j;

    unchecked {
        for (uint256 i = 1; i <= _currentIndex; i++) {
            if(winners[i] > 0) {
                _winners[j] = tickets[i];
                _winnersSum[j] = winners[i];
                _winnersDate[j] = winnersTimestamp[i];
                j++;
            }
        }
    }

        return (_winners, _winnersSum, _winnersDate);
    }

    function userReferrals(address user) public view returns (address[] memory, uint256[] memory) {
        uint256 count = getCountReferrals(user);
        address [] memory _referrals = new address[](count);
        uint256 [] memory _referralsReward = new uint256[](count);
        uint256 j;

    unchecked {
        for (uint256 i = 0; i < referralsArray.length; i++) {
            if (referrals[referralsArray[i]] == user) {
                _referrals[j] = referralsArray[i];
                _referralsReward[j] = balanceTicketsOf(referralsArray[i]) - referralsDiff[referralsArray[i]];
                j++;
            }
        }
    }

        return (_referrals, _referralsReward);
    }

    function userWins(address user) public view returns (uint256[] memory) {
        uint256 count = getCountWins(user);
        uint256[] memory _wins = new uint256[](count);
        uint256 j;

    unchecked {
        for (uint256 i = 1; i <= _currentIndex; i++) {
            if (tickets[i] == user && winners[i] > 0) {
                _wins[j] = winners[i];
                j++;
            }
        }
    }

        return _wins;
    }

    function getCountReferrals(address user) internal view returns (uint256) {
        uint256 count;

    unchecked {
        for (uint256 i = 0; i < referralsArray.length; i++) {
            if (referrals[referralsArray[i]] == user) {
                count++;
            }
        }
    }

        return count;
    }

    function getCountWinners() internal view returns (uint256) {
        uint256 count;

    unchecked {
        for (uint256 i = 1; i <= _currentIndex; i++) {
            if (winners[i] > 0) {
                count++;
            }
        }
    }

        return count;
    }

    function getCountWins(address user) internal view returns (uint256) {
        uint256 count;

    unchecked {
        for (uint256 i = 1; i <= _currentIndex; i++) {
            if (tickets[i] == user && winners[i] > 0) {
                count++;
            }
        }
    }

        return count;
    }

    function withdraw() external onlyOwner {
        uint256 balance = IBEP20(BUSDContract).balanceOf(address(this));
        IBEP20(BUSDContract).transfer(msg.sender, balance);
    }

    function setDeveloperWallet(address developer) external onlyOwner {
        require(developer != address(0));
        developerWallet = developer;
    }
}