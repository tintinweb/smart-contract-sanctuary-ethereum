/**
 *Submitted for verification at Etherscan.io on 2022-06-07
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

contract ICO is Ownable {

    using LowGasSafeMath for uint;
    using LowGasSafeMath for uint32;
    uint256 public maxRaise;
    uint256 public totalRaise = 0;
    uint256 public startTimestamp;
    mapping(address => bool) public whitelistedAddresses;

    mapping (address => uint256) public contributions;

    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public privateSaleAmount;
    bool public publicSaleActive;
    
    uint256 public tokensPerUSD;
    bool public presaleFinalised;
    address public USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public voxelAddress = 0x16CC8367055aE7e9157DBcB9d86Fd6CE82522b31;
    address public presaleTokenAddress;
    
    // Voxel address 0x16CC8367055aE7e9157DBcB9d86Fd6CE82522b31
    constructor(uint256 _tokensPerUSD, uint256 _privateSaleAmount, uint256 _maxRaise, uint256 _startTimestamp, uint256 _minContribution, uint256 _maxContribution) {
        startTimestamp = _startTimestamp;
        maxRaise = _maxRaise.mul(1e18);     
        privateSaleAmount = _privateSaleAmount.mul(1e18);
        publicSaleActive = false;
        minContribution = _minContribution.mul(1e18);
        maxContribution = _maxContribution.mul(1e18);
        tokensPerUSD = _tokensPerUSD.mul(1e9);
    }

    function setUSDTAddress(address _usdtAddress) public onlyOwner{
        USDTAddress = _usdtAddress;
    }

    function setPresaleTokenAddress(address _presaleTokenAddress) public onlyOwner{
        presaleTokenAddress = _presaleTokenAddress;
    }

    function updateVoxelAddress(address _voxelAddress) public onlyOwner{
        voxelAddress = _voxelAddress;
    }

    function setTokenPrice(uint256 _tokensPerUSD) public onlyOwner{
        tokensPerUSD = _tokensPerUSD.mul(1e9);
    }

    function finalisePresale() public onlyOwner{
        presaleFinalised = true;
    }

    function udpatePrivateSaleAmount(uint256 _privateSaleAmount) public onlyOwner{
        privateSaleAmount = _privateSaleAmount.mul(1e18);
    }

    function updateMaxRaise(uint256 _maxRaise) public onlyOwner{
        maxRaise = _maxRaise.mul(1e18);
    }

    function updateMinMaxContribution(uint256 _minContribution, uint256 _maxContribution) public onlyOwner{
        minContribution = _minContribution.mul(1e18);
        maxContribution = _maxContribution.mul(1e18);
    }

    function startPublicSale() public onlyOwner{
        publicSaleActive = true;
    }

    function whitelistAddresses(address[] calldata users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            whitelistedAddresses[users[i]] = true;
        }
    }
    
    function contribute(uint256 amount) public {
        require(USDTAddress != address(0x0), "USDT address not set!");
        require(block.timestamp >= startTimestamp, "Contributions not open yet!");
        require(!presaleFinalised, "Presale is already finalised!");
        if (!publicSaleActive) {
            require(whitelistedAddresses[msg.sender] || IERC20(voxelAddress).balanceOf(msg.sender)>0 , "Can't contribute to private sale, Not Whitelised!");
        }
        uint256 _contribution = amount.mul(1e18);

        require(minContribution <= _contribution, "Contribution amount not allowed!");
        require(contributions[msg.sender]+_contribution <= maxContribution, "Contribution amount not allowed!");

        if (!publicSaleActive){
            require(totalRaise.add(_contribution) <= privateSaleAmount, "Not enough slots left in private sale!");
        }

        require(totalRaise.add(_contribution) <= maxRaise, "Raise Complete!");
        
        IERC20(USDTAddress).transferFrom(msg.sender, address(this), _contribution);
        totalRaise += _contribution;
        contributions[msg.sender] += _contribution;
    }

    function withdrawUSDT() public onlyOwner{
        IERC20(USDTAddress).transfer(msg.sender, totalRaise);
    }

    function withdrawRemainingTokens(uint256 amount) public onlyOwner{
        IERC20(presaleTokenAddress).transfer(msg.sender, amount);
    }

    function claimTokens() public{
        require(presaleFinalised, "Presale is not finalised!");
        require(contributions[msg.sender] > 0, "No contributions to claim!");
        uint256 tokensToClaim = contributions[msg.sender].mul(tokensPerUSD).div(1e18);
        contributions[msg.sender] = 0;
        IERC20(presaleTokenAddress).transfer(msg.sender, tokensToClaim);
    }    

    function withdrawETH() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

}