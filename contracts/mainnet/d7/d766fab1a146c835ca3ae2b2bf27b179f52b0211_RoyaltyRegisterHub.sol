/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: contracts/Ownable.sol

pragma solidity 0.4.26;

contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

// File: contracts/IRoyaltyRegisterHub.sol

pragma solidity 0.4.26;

///
/// @dev Interface for the NFT Royalty Standard
///

interface IRoyaltyRegisterHub {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _nftAddress - the NFT contract address
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(address _nftAddress, uint256 _salePrice)  external view returns (address receiver, uint256 royaltyAmount);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

// File: contracts/RoyaltyRegisterHub.sol

pragma solidity 0.4.26;




interface IOwnable {
    function owner() external view returns (address);
}

contract RoyaltyRegisterHub is IRoyaltyRegisterHub, Ownable {

    /* Inverse basis point. */
    uint public constant INVERSE_BASIS_POINT = 10000;
    uint public constant MAXIMUM_ROYALTY_RATE = 1000;

    bytes4 private constant OWNER_SELECTOR = 0x8da5cb5b; // owner()

    /* nft royalty rate, in basis points. */
    mapping(address => uint) public nftRoyaltyRateMap;
    /* nft royalty receiver */
    mapping(address => address) public nftRoyaltyReceiverMap;

    constructor() public {

    }

    function setRoyaltyRate(address _nftAddress, uint256 _royaltyRate, address _receiver) public onlyOwner returns (bool) {
        require(_royaltyRate<MAXIMUM_ROYALTY_RATE, "royalty rate too large");
        require(_receiver!=address(0x0), "invalid royalty receiver");

        nftRoyaltyRateMap[_nftAddress] = _royaltyRate;
        nftRoyaltyReceiverMap[_nftAddress] = _receiver;
        return true;
    }

    function setRoyaltyRateFromNFTOwners(address _nftAddress, uint256 _royaltyRate, address _receiver) public returns (bool) {
        require(_royaltyRate<MAXIMUM_ROYALTY_RATE, "royaltyRate too large");
        require(_receiver!=address(0x0), "invalid royalty receiver");

        bool success;
        bytes memory data = abi.encodeWithSelector(OWNER_SELECTOR);
        bytes memory result = new bytes(32);
        assembly {
            success := call(
            gas,            // gas remaining
            _nftAddress,      // destination address
            0,              // no ether
            add(data, 32),  // input buffer (starts after the first 32 bytes in the `data` array)
            mload(data),    // input length (loaded from the first 32 bytes in the `data` array)
            result,         // output buffer
            32              // output length
            )
        }
        require(success, "no owner method");
        address owner;
        assembly {
            owner := mload(result)
        }
        require(msg.sender == owner, "not authorized");

        nftRoyaltyRateMap[_nftAddress] = _royaltyRate;
        nftRoyaltyReceiverMap[_nftAddress] = _receiver;
        return true;
    }

    function royaltyInfo(address _nftAddress, uint256 _salePrice) external view returns (address, uint256) {
        address receiver = nftRoyaltyReceiverMap[_nftAddress];
        uint256 royaltyAmount = SafeMath.div(SafeMath.mul(nftRoyaltyRateMap[_nftAddress], _salePrice), INVERSE_BASIS_POINT);

        return (receiver, royaltyAmount);
    }

}