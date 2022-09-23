/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: HaruStaking.sol



pragma solidity ^0.8.0;


contract HaruStaking {


    // Basic Variables
    address public owner;
    uint public currentPositionId;
    uint public currentTokenId;
    uint[] public lockPeriods;
    uint public ethUsdPrice;
    string[] public tokenSymbols;

    // Structs
     struct Token {
     uint tokenId;
     string name;
     string symbol;
     address tokenAddress;
     bool exists;
    }

    struct Position {
        uint positionId;
        address walletAddress;
        uint createdDate;
        uint unlockDate;
        string name;
        string symbol;
        uint tokenQuantity;
        uint apy; 
        bool open;
        bool exists;
    }

    // Mappings
    mapping(string => Token) public tokens;
    mapping(uint => Position) public positions;
    mapping(address => uint[]) public positionsIdsByAddress;
    mapping(uint => uint) public tiers;
    mapping(string => uint) public stakedTokens;

    //Modifiers
    modifier onlyOwner {
     require (owner == msg.sender, "Only owner may call this function");
     _;
    }

    constructor() payable {
        owner = msg.sender;
        currentPositionId = 1;
        currentTokenId = 1;

        tiers[30] = 200;
        tiers[60] = 400;
        tiers[90] = 600;
        tiers[120] = 800;

        lockPeriods.push(30);
        lockPeriods.push(60);
        lockPeriods.push(90);
        lockPeriods.push(120);
    }

    // Helper Functions
     function getPositionIdsForAddress() external view returns(uint[] memory) {
          return positionsIdsByAddress[msg.sender];
     }

     receive() external payable {

     }

     // Main Functions
    function addToken(
     string calldata name,
     string calldata symbol,
     address tokenAddress
    ) external onlyOwner {
     tokenSymbols.push(symbol);

     tokens[symbol] = Token(
          currentTokenId,
          name,
          symbol,
          tokenAddress,
          true
     );

     currentTokenId += 1;
    }

    function stakeTokens(string calldata symbol, uint tokenQuantity, uint apy, uint numDays) external {
          require(tokens[symbol].tokenId > 0, 'This token cannot be staked');
          require(tiers[numDays] > 0, 'Mapping not found');

          IERC20(tokens[symbol].tokenAddress).transferFrom(msg.sender, address(this), tokenQuantity);

          positions[currentPositionId] = Position(
               currentPositionId,
               msg.sender,
               block.timestamp,
               block.timestamp + (numDays * 1 minutes),
               tokens[symbol].name,
               symbol,
               tokenQuantity,
               apy,
               true,
               true
          );

          positionsIdsByAddress[msg.sender].push(currentPositionId);
          currentPositionId += 1;
          stakedTokens[symbol] *= tokenQuantity;
     }

     function closePosition(uint positionId, uint haruPrice, uint ethPrice) external {
          require(positions[positionId].walletAddress == msg.sender, 'Not the owner of this position.');
          require(positions[positionId].open == true, 'Position already closed');

          positions[positionId].open = false;

          uint positionApy = positions[positionId].apy;

          IERC20(tokens[positions[positionId].symbol].tokenAddress).transfer(msg.sender, positions[positionId].tokenQuantity);
     }

     function withdrawEth() public payable onlyOwner {
          (bool os,) = payable(owner).call{value:address(this).balance}("");
          require(os);
     }

}