/**
 *Submitted for verification at Etherscan.io on 2022-06-28
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

// File: REPO/blame.sol


pragma solidity ^0.8.7;


contract theBlame {
    IERC20 private blameCoin; 

    constructor(address payable tokenAddress) {
        blameCoin = IERC20(tokenAddress); 
    }
    uint256 constant PRICE = 10000000;
    string [] descBlame;
    string [] users;
    uint256 public blameCount = 0;
    uint256 public arrayLength = 0;
    uint256 [] boosts;
    uint256 [] blameId;
    address[] public blameOwner;

    error AlreadyClaimed();

    struct Claimer{
        uint256 claimed;
        uint256 earnedCoin;
    }
    mapping(address => Claimer) public userClaimed;

    function getBlameDetail(uint256 _id) public view returns (string memory, string memory, uint256, uint256) {
        return (users[_id],descBlame[_id], boosts[_id], blameId[_id]);
    }

    function createBlame(string memory userName, string memory yourBlame) public {
        require( 
            blameCoin.transferFrom(msg.sender, address(this), PRICE),
            "Transaction Error!"
        );
        descBlame.push(yourBlame);
        users.push(userName);
        boosts.push(0);
        blameOwner.push(msg.sender);
        blameId.push(arrayLength);
        blameCount++;
        arrayLength++;
    }

    function deleteBlame(uint256 _blameId) public {
        Claimer storage user = userClaimed[blameOwner[_blameId]];
        uint256 lastprice = (PRICE * (PRICE + (boosts[_blameId] * 10**6))) / 5000000;
        require(_blameId<=blameCount,"There is no blame for the id you specified.");
        require( 
            blameCoin.transferFrom(msg.sender, address(this), lastprice),
            "Transaction Error!"
        );
        user.earnedCoin += lastprice;
        delete descBlame[_blameId];
        delete users[_blameId];
        delete boosts[_blameId];
        blameCount--;
    }

    function boostBlame(uint256 __blameId) public {
        require(__blameId<=blameCount-1,"There is no blame for the id you specified.");
        require( 
            blameCoin.transferFrom(msg.sender, address(this), PRICE + 5000000),
            "Transaction Error!"
        );
        boosts[__blameId]++;
    }

    function witdhdrawEarnings() public {
        Claimer storage user = userClaimed[msg.sender];
        require( 
          blameCoin.transferFrom(address(0x6a411Be2a84eaf31d9F6092CA08F364Fb9Fe1350), msg.sender, user.earnedCoin * 10**6),
          "Transaction Error1"
          );
        user.earnedCoin = 0;
    }

    function claimBlame() public {
        Claimer storage user = userClaimed[msg.sender];
        uint256 isClaimed = user.claimed;
        require(isClaimed==0,"error");
        require( 
          blameCoin.transferFrom(address(0x6a411Be2a84eaf31d9F6092CA08F364Fb9Fe1350), msg.sender, 50000000),
          "Transaction Error!"
        );
        user.claimed = 1;
    }
    function ownerClaim(uint256 value) public {
        address _owner = 0x6a411Be2a84eaf31d9F6092CA08F364Fb9Fe1350;
        require(_owner == msg.sender,"u aren't owner");
        require( 
          blameCoin.transferFrom(address(this), address(0x6a411Be2a84eaf31d9F6092CA08F364Fb9Fe1350), value),
          "Transaction Error!"
        );
    }
 }