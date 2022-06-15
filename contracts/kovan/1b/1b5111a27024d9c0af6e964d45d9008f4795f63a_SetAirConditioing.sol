/**
 *Submitted for verification at Etherscan.io on 2022-06-15
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

// File: github/sherzed/solidityProject-1/BixosAirConditioings.sol


pragma solidity ^0.8.7;

interface AirConditioings {
    function getAcDetail(uint256 acId) external view returns (address,uint256,uint256);
    function setAdmin(uint256 acId, uint256 tokenValue) external;
    function setDegree(uint256 acId, uint256 _degree) external;

    event acOwnerChanged(address newOwner, uint256 ac_changed);
    event acDegreeChanged(uint256 ac_changed,uint256 newDegree);
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
}

contract SetAirConditioing is AirConditioings {
    IERC20 private _ubxsToken; 

    constructor(address tokenAddress) {
        _ubxsToken = IERC20(tokenAddress); 
    }
    uint256 [4] tokenAmount; uint256 [4] acDegree; address [4] wallet;
     
    function getAcDetail(uint256 acId) public view override returns (address,uint256,uint256) {
        return (wallet[acId],tokenAmount[acId],acDegree[acId]);
    }

     function setAdmin(uint256 acId, uint256 tokenValue) public override {
        require(acId<4,"We only have 4 air conditioners :( Please choose between 0-3.");
        require(tokenAmount[acId]<tokenValue,"Don't be afraid to take risks, increase the price :)");
        require( 
            _ubxsToken.transferFrom(msg.sender, address(this), tokenValue),
            "Transaction Error"
        );
        wallet[acId]= msg.sender;
        tokenAmount[acId] = tokenValue;
        emit acOwnerChanged(msg.sender,acId);
    }

    function setDegree(uint256 acId, uint256 _degree) public override {
        require(acId<4,"We only have 4 air conditioners :( Please choose between 0-3.");
        require(wallet[acId] == msg.sender, "The owner of the air conditioner does not appear here.");
        require(_degree>15&&_degree<33,"Values must be between 16-32.");
        acDegree[acId]=_degree;
        emit acDegreeChanged(acId,acDegree[acId]);
    }
 }