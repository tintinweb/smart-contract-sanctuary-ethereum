/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

pragma solidity ^0.5.16;

/**
 * @title For mint one LoFi Land
 */

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

interface ILANDContract{
  function mint(address to, uint256 tokenId, int128 _x, int128 _y, int128 _t) external returns (bool);
  function ownerOf(uint256 tokenId) external returns (address owner);
  function totalSupply() external view returns (uint256);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC20Token {
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;    
  function transfer(address dst, uint rawAmount) external returns (bool);
  function balanceOf(address account) external view returns (uint);
} 

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address  _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
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
    function isOwner() public view returns (bool) {
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


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract LANDClaim is  Ownable {
    using SafeMath for uint256;
     
    uint256 private nonce = 0;
    uint256 public _claimdays = 30 days;
    uint256 private releaseDate;
    uint256 public _storestartTime =  now + 365 days;

    uint256[] private _allNft;
    uint256[] private _allReg;
    uint256[] private _stageReg;

    
    address public land_contract = address(0x9c6Def8771aF345023A0a0bc581E2f02BB214bD7);  

    mapping(uint256 => uint256) private _allNftIndex;
    mapping(uint256 => bool) usedNonces;
    uint16[] public round ;
    uint16[] public round_len ;
    uint16[] public shift ;

    uint random_value = 0;

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event EncodeProperties(uint16 a, uint16 b,uint16 c, uint16 d);
    event CreatedProperties(uint256 pro);
    event RegisteredNFT(uint256 id, address wallet);

    mapping(uint256 => uint256) public _lastStoreTime;
    mapping(uint256 => uint) private _allowchallenge;
    mapping (address => bool) public hasClaimed;
    mapping (uint256 => address) public registeredAddress;
    mapping (uint256 => uint256) public registerPool;
    
    modifier hasNotClaimed() {
        require(hasClaimed[msg.sender] == false);
        _;
    }

    modifier canClaim() {
        require(releaseDate + _claimdays >= now);
        _;
    }

    modifier checkstoreStart() {
        require(block.timestamp > _storestartTime, "store not start");
        _;
    }

    constructor() public {
        releaseDate = now;
        random_value = block.number;
    }


    function toBytes(uint256 x) pure internal returns (bytes memory b) {
         b = new bytes(32);
         assembly { mstore(add(b, 32), x) }
    }

    function isContract(address _addr) internal view returns (bool)
    {
        uint32 size;
          assembly {
            size := extcodesize(_addr)
          }
          return (size > 0);
    }
    
    function convert_uint16 (uint256 _a) pure internal returns (uint16) 
    {
        return uint16(_a);
    }

    function setLANDContract( address _contractaddr ) external onlyOwner {
        land_contract = _contractaddr;
    }

    function claim_land( address claimer_addr, uint256 tokeid, int128 _x, int128 _y, int128 _t) external returns (uint16) 
    {
        ILANDContract _land_c = ILANDContract(land_contract);
        _land_c.mint(claimer_addr, tokeid, _x, _y, _t);
    }


    
}