/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// File: qatar.sol



pragma solidity ^0.8.0;



interface IstakingContract {
    function balanceOf(address account) external view returns (uint256);
}

contract QatarStaking is ReentrancyGuard {

    // Basic Variables
    address public owner;
    uint public currentPositionId;
    uint public currentTokenId;
    string[] public tokenSymbols;
    uint public amountOfTokenPerEth = 1119490944;
    uint public thirtyDaysApy = 1200;
    uint public sixtyDaysApy = 1200;
    uint public ninetyDaysApy = 1200;
    uint public hundredTwentyDaysApy = 1200;
    address qatarCoinAddress = 0x68c2fC590A84392759e26d186E3f20E0F5A3C77a;
    IstakingContract qatarContract;

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
        string symbol;
        uint tokenQuantity;
        uint createdDate;
        uint profitsPerWeek;
        uint nextWeekUnlockDate;
        uint profitsReclaimed;
        uint apy; 
        bool open;
        bool exists;
    }

    // Mappings
    mapping(string => Token) public tokens;
    mapping(uint => Position) public positions;
    mapping(address => uint[]) public positionsIdsByAddress;

    //Modifiers
    modifier onlyOwner {
     require (owner == msg.sender, "Only owner may call this function");
     _;
    }

    constructor() payable {
        owner = msg.sender;
        currentPositionId = 1;
        currentTokenId = 1;

        qatarContract = IstakingContract(qatarCoinAddress);
    }

    // Helper Functions
     receive() external payable {

     }

     function changeAmountOfTokenPerEth(uint newAmount) external onlyOwner {
          amountOfTokenPerEth = newAmount;
     }

     function changeThirtyDaysApy(uint newAmount) external onlyOwner {
          thirtyDaysApy = newAmount;
     }

     function changeSixtyDaysApy(uint newAmount) external onlyOwner {
          sixtyDaysApy = newAmount;
     }

     function changeNinetyDaysApy(uint newAmount) external onlyOwner {
          ninetyDaysApy = newAmount;
     }

     function changeHundredTwentyDaysApy(uint newAmount) external onlyOwner {
          hundredTwentyDaysApy = newAmount;
     }

     function calculateNumberDays(uint createdDate) public view returns(uint) {
          return (block.timestamp - createdDate) / 60 / 60 / 24;
     }

     function calculatePerWeekPayment(uint apy, uint tokenQuantity) public pure returns(uint) {
          return apy * tokenQuantity / 100 / 12 / 4;
     }

     function withdrawEth() external onlyOwner {
          (bool os,) = payable(owner).call{value:address(this).balance}("");
          require(os);
     }

     function withdrawQatar() external onlyOwner {
          IERC20(qatarCoinAddress).transfer(owner, qatarContract.balanceOf(address(this)));
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

    function stakeTokens(string calldata symbol, uint tokenQuantity) external {
          require(tokens[symbol].tokenId > 0, 'This token cannot be staked');

          IERC20(tokens[symbol].tokenAddress).transferFrom(msg.sender, address(this), tokenQuantity);

          uint taxesTaken = (tokenQuantity * 6) / 100;
          uint actualTokensThatWentIn = tokenQuantity - taxesTaken;

          uint apy = thirtyDaysApy;
          uint perWeekPayment = calculatePerWeekPayment(apy, actualTokensThatWentIn);

          positions[currentPositionId] = Position(
               currentPositionId,
               msg.sender,
               symbol,
               actualTokensThatWentIn,
               block.timestamp,
               perWeekPayment,
               block.timestamp + (7 * 1 days),
               0,
               apy,
               true,
               true
          );

          positionsIdsByAddress[msg.sender].push(currentPositionId);
          currentPositionId += 1;
     }

     function closePosition(uint positionId) external {
          require(positions[positionId].walletAddress == msg.sender, 'Not the owner of this position.');
          require(positions[positionId].open == true, 'Position already closed');

          IERC20(tokens[positions[positionId].symbol].tokenAddress).transfer(msg.sender, positions[positionId].tokenQuantity);

          positions[positionId].open = false;
          positions[positionId].tokenQuantity = 0;
          positions[positionId].profitsPerWeek = 0;
     }

     function receiveWeekProfits(uint positionId) external {
          require(positions[positionId].open == true, 'Position already closed');
          require(positions[positionId].walletAddress == msg.sender, 'Not the owner of this position.');
          require(block.timestamp > positions[positionId].nextWeekUnlockDate, 'Weekly profit withdrawal date in a couple days.');

          uint amountOfDaysSinceCreation = calculateNumberDays(positions[positionId].createdDate);

          if (amountOfDaysSinceCreation > 90) {
               positions[positionId].apy = hundredTwentyDaysApy;
               positions[positionId].profitsPerWeek = calculatePerWeekPayment(positions[positionId].apy, positions[positionId].tokenQuantity);
          } else if (amountOfDaysSinceCreation > 60) {
               positions[positionId].apy = ninetyDaysApy;
               positions[positionId].profitsPerWeek = calculatePerWeekPayment(positions[positionId].apy, positions[positionId].tokenQuantity);
          } else if (amountOfDaysSinceCreation > 30) {
               positions[positionId].apy = sixtyDaysApy;
               positions[positionId].profitsPerWeek = calculatePerWeekPayment(positions[positionId].apy, positions[positionId].tokenQuantity);
          }

          positions[positionId].profitsReclaimed += (positions[positionId].profitsPerWeek);
          positions[positionId].nextWeekUnlockDate = block.timestamp + (7 * 1 days);

          uint amountToPay = (positions[positionId].profitsPerWeek / amountOfTokenPerEth) * 1000000000;
          payable(msg.sender).call{value: amountToPay}("");
     }
}