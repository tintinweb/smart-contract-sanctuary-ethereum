/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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

contract Storage {

    struct RedEnvelopeData{
        address owner;
        address tokenAddr;
        uint totalAmount;
        uint whiteListCnt;
        mapping(address => bool) whiteList;
    }

    address public admin;
    uint public enveplopeId;
    mapping(uint => RedEnvelopeData) public redEnvelopes;

    constructor(){
        enveplopeId = 0;
        admin = address(msg.sender);
    }

    function createNewRedEnvelope(address tokenAddr) public returns (uint redEnvelopeId) {
        redEnvelopeId = enveplopeId++;
        RedEnvelopeData storage newRedEnvelope = redEnvelopes[redEnvelopeId];
        newRedEnvelope.owner = msg.sender;
        newRedEnvelope.tokenAddr = tokenAddr;
        newRedEnvelope.totalAmount = 0;
        newRedEnvelope.whiteListCnt = 0;
    }
    
    function deposit(uint redEnvelopeId, uint256 amount) public {
        RedEnvelopeData storage redEnvelope = redEnvelopes[redEnvelopeId];
        require(IERC20(redEnvelope.tokenAddr).transferFrom(msg.sender, address(this), amount));
        redEnvelope.totalAmount += amount;

    }
     
    function updateWhiteList(uint redEnvelopeId, address user, bool claimbale) public {
        RedEnvelopeData storage redEnvelope = redEnvelopes[redEnvelopeId];
        require(msg.sender == redEnvelope.owner);
        if (redEnvelope.whiteList[user] != claimbale) {
            redEnvelope.whiteList[user] = claimbale;
            if (claimbale) {
                redEnvelope.whiteListCnt += 1;
            } else {
                redEnvelope.whiteListCnt -= 1;
            }
        }
    }

    function claim(uint32 redEnvelopeId) public {
        RedEnvelopeData storage redEnvelope = redEnvelopes[redEnvelopeId];
        require(redEnvelope.whiteList[msg.sender]);

        uint256 each = redEnvelope.totalAmount / redEnvelope.whiteListCnt;

        redEnvelope.whiteList[msg.sender] = false;
        redEnvelope.whiteListCnt -= 1;
        redEnvelope.totalAmount -= each;

        require(IERC20(redEnvelope.tokenAddr).transfer(msg.sender, each));
    }

}