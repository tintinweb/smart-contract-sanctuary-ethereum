/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// File: contracts/Owned.sol


pragma solidity >=0.8.0;

contract Owned {
    address public owner;
    address public nominatedOwner;
    address public w2emanager;

    constructor(address _owner, address _w2emanager) {
        require(_owner != address(0), "Owner address cannot be 0");
        require(_w2emanager != address(0), "Manager address cannot be 0");
        owner = _owner;
        w2emanager = _w2emanager;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function changeManager(address _manager) external onlyOwner {
        w2emanager = _manager;

        emit ManagerChanged(_manager);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    modifier onlyW2EManager {
        _onlyManager();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action!");
    }

    function _onlyManager() private view {
        require(msg.sender == w2emanager, "Only W2E Manager can perform this action!");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
    event ManagerChanged (address newManager);
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

// File: contracts/Claim.sol


pragma solidity >=0.8.0;



contract TokenClaim is Owned {
    IERC20 public tokenMFX;
    address public spender;

    mapping (address => bool) public isW2EUser;
    mapping (address => uint256) private _lastClaimTxTime;

    uint private maxClaimNumber;

    constructor(
        address _tokenMFX,
        address _spender,
        address _owner,
        address _w2emanager
    ) Owned(_owner, _w2emanager) {
        tokenMFX = IERC20(_tokenMFX);
        spender = _spender;
    }

    function claimMFX(uint256 _amount) external {
        require(_amount <= maxClaimNumber, "Transfer amount too large.");
        require(isW2EUser[msg.sender], "Only Watch 2 Earn users can claim rewards!");
        require(_lastClaimTxTime[msg.sender] == 0 || _lastClaimTxTime[msg.sender] <= block.timestamp - 86400,"Already claimed your quota!");
        tokenMFX.transferFrom(spender, msg.sender, _amount);

        _lastClaimTxTime[msg.sender] = block.timestamp;
    }

    function setMaxClaimNumber(uint256 value) external onlyOwner {
        require(value > 0, "");
        maxClaimNumber = value;
    }

    function withdrawExcessBNB (address _account) external onlyOwner {
        uint256 contractBNBBalance = address(this).balance;
        
        if (contractBNBBalance > 0)
            payable(_account).transfer(contractBNBBalance);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool) {
     if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function addUsersToW2E(address[] memory addrs) external onlyW2EManager returns (bool) {
        for(uint256 i = 0; i < addrs.length; i++) {
            isW2EUser[addrs[i]] = true;
        }
        return true;
    }

    function removeUsersFromW2E(address[] memory addrs) external onlyW2EManager returns (bool) {
        for(uint256 i = 0; i < addrs.length; i++) {
            isW2EUser[addrs[i]] = false;
        }
        return true;
    }
}