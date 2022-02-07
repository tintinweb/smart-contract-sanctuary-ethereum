// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "interfaces/IDegen.sol";

contract DegenSupply {
    
    IDegen public immutable degen;
    address public operator;

    struct Shopper {
        uint256 credit;
        uint256 lifeTimeRewards;
    }

    mapping(address => Shopper) public shoppers;

    constructor(IDegen _degen,address _operator){
        operator=_operator;
        degen = _degen;
    }

    function allocate(address[] memory _shoppers,uint256[] memory _credit) external {
        require(msg.sender == operator, "!auth");
        for (uint256 i = 0; i < _credit.length; i++) {
            Shopper storage shopper = shoppers[_shoppers[i]];
            shopper.credit=shopper.credit + _credit[i];
            shopper.lifeTimeRewards=shopper.lifeTimeRewards+ _credit[i];
        }
    }

    function claim() external {
        Shopper storage shopper = shoppers[msg.sender];
        require (shopper.credit>0,"DegenSupply: caller has not performed an athletic feat");
        uint256 cred=shopper.credit;
        shopper.credit=0;
        degen.mint(address(this),cred);
        degen.transfer(address(msg.sender),cred);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDegen {
    
    //mints
    function mint(address _to, uint256 _amount) external;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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