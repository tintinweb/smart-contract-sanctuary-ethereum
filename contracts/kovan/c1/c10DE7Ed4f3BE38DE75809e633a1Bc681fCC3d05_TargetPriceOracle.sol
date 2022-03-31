/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
//import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    
    return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;
    
    return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
    return 0;
    }
    
    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
    
    return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
    }
    
    function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    
    return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
    ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
    }
}

abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



contract TargetPriceOracle is Ownable {
    
    using SafeMath for uint256;
    uint256 public currentMarketPrice;
    uint256 public baseFloorPrice;
    uint256 public floorPrice;
    
    /**
     * Network: Polygon Mumbai Testnet
     * Oracle: 0x58bbdbfb6fca3129b91f0dbe372098123b38b5e9
     * Job ID: da20aae0e4c843f6949e5cb3f7cfe8c4
     * LINK address: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
     * Fee: 0.01 LINK
     */
    constructor() {

        currentMarketPrice = 1e18;
        baseFloorPrice = 200;
    }

    /*
     * @notice Pushes a targetPrice
     * @param currentMarketPrice_ is expected to be 18 decimal fixed point number in WEI
     */

    function pushReport(uint256 _floorPrice) external onlyOwner
    {
        currentMarketPrice = baseFloorPrice.mul(currentMarketPrice).div(_floorPrice) ;
    }

    /**
    * @return AggregatedValue: return the reported values.
    *         valid: Boolean indicating an aggregated value was computed successfully.
    */
    function getData()
        external
        view returns (uint256, bool)
    {
        
        return (currentMarketPrice, true);
    }

}