/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.4;

library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function add32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function sub32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    function div(uint256 x, uint256 y) internal pure returns(uint256 z){
        require(y > 0);
        z=x/y;
    }
}

contract OwnableData {
    address public owner;
    address public pendingOwner;
}

contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

}


interface IWASG {
    function deposits(address owner) external view returns (uint256);
    function lastWrapped(address owner) external view returns (uint256);
}

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

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
  
  function decimals() external returns (uint8);

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

contract Bifrost is Ownable {

    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint32;
    address constant public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 public whitelistContribution=300;
    uint256 public maxRaise;
    uint256 public totalRaise = 0;
    IWASG public WASG;
    uint256 public startTimestamp;
    mapping(address => bool) public whitelistedAddresses;
    uint256[3] public tierContributions = [300, 600, 1200];
    mapping (address => uint256) public contributions;


    constructor(address _wasgAddress, uint256 _maxRaise, uint256 _startTimestamp) {
        startTimestamp = _startTimestamp;
        maxRaise = _maxRaise;     
        WASG = IWASG(_wasgAddress);
    }

    function whitelistAddresses(address[] calldata users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whitelistedAddresses[users[i]] = true;
        }
    }

    function updateWhitelistContribution(uint256 _amount) public onlyOwner {
        whitelistContribution = _amount;
    }
    
    function contribute(uint256 amount) public {

        uint256 eligible_amount = maxContribution(msg.sender);
        
        require(eligible_amount>0, "Not eligible for contribution!");
        require(block.timestamp >= startTimestamp, "Contributions not open yet!");
        require(contributions[msg.sender]+ amount <= eligible_amount, "Contribution limit exceeded!");
        require(totalRaise + amount <= maxRaise, "Raise Complete!");
        require(amount>0, "Amount must be greater than zero");
        IERC20(USDC).transferFrom(msg.sender, address(this), amount*(1e6));
        totalRaise += amount;
        contributions[msg.sender] += amount;
    }

    
    function updateMaxRaise(uint256 _maxRaise) public onlyOwner {
        maxRaise = _maxRaise;
    }

    function updateTierContributions(uint256[3] memory _newTierContributions) public onlyOwner {
        tierContributions = _newTierContributions;
    }

    function maxContribution(address _wallet) public view returns (uint256){
        uint256 eligible_amount = 0;
        if (whitelistedAddresses[_wallet]){
            eligible_amount = whitelistContribution;
        }
        else{
            uint256 wrapBalance = WASG.deposits(_wallet);
            if (wrapBalance >= 15000*(1e9)){
                eligible_amount = tierContributions[2];
            }
            else if (wrapBalance >= 7500*(1e9) && wrapBalance < 15000*(1e9)){
                eligible_amount = tierContributions[1];
            }
            else if (wrapBalance >= 1000*(1e9) && wrapBalance < 7500*(1e9)){
                eligible_amount = tierContributions[0];
            }
        }
        return eligible_amount;
    }


    function withdrawEthPool() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawToken(address token) public onlyOwner{
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
}