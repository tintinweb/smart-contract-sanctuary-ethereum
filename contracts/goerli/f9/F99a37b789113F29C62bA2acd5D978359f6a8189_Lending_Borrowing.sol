// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @dev lending and borrowing contract that lends to users but theusers are overcollaterised and the users put in ether
/// @dev and the contract lends stable coins (which they own) and a caculation is done to give stable coin 
/// @dev to the user
//_____________________________________________________________________________________________________________
                                                
                                                /// FREE LENDING      
//_____________________________________________________________________________________________________________
import {libstorage} from "../libraries/Appstorage.sol";
import { IERC20 } from "../interfaces/IERC20.sol";

contract Lending_Borrowing{ 
    libstorage internal s;

    event DepositEther(address borrower, uint depositedamount);

    function depositEther() payable external{
        require(s.borrowerdetails[msg.sender].deposited == false, "return outstanding tokens");
        uint realamount = checkOutputs(msg.value);
        require(msg.value >= 1 ether, "desposit enough for this transaction");
        s.borrowerdetails[msg.sender].amountin = msg.value;
        s.borrowerdetails[msg.sender].borrower = msg.sender;
        s.borrowerdetails[msg.sender].amounttoborrow = realamount;
        s.borrowerdetails[msg.sender].deposited = true;
    }

    function getFREECOINS() external{
        require(s.borrowerdetails[msg.sender].gottenfreecoin == false, "has gootten for this transaction"); 
        uint amount= s.borrowerdetails[msg.sender].amounttoborrow;
        bool sent = s.tokenaddress.transfer(msg.sender, amount);
        require(sent , "failed");
        s.borrowerdetails[msg.sender].gottenfreecoin == true;
    }

    /// @dev if a user needs __amountin he uses this function to calculate the amount he will pay for the loan
    /// @param __amountin is amount you have to get a FREECOIN
    /// @return  amount__  amount to get for inputing __amountin
    function checkOutputs(uint __amountin) public  pure returns(uint amount__){
       uint dollar = (__amountin * 1500) / 10**18;
       uint percentage = (dollar * 10) / 100;
       amount__ = dollar - percentage;
    }

    function Return(uint tokens) external {
        bool returned = s.borrowerdetails[msg.sender].deposited;
        require(returned == true , "has returned");
        require(s.borrowerdetails[msg.sender].amounttoborrow == tokens, "return all tokens please");
        bool sent = s.tokenaddress.transferFrom(msg.sender, address(this),tokens);
        require(sent , "failed");
        (bool send,) = payable(msg.sender).call{value:s.borrowerdetails[msg.sender].amountin}("");
        require(send, "failed");
        s.borrowerdetails[msg.sender].deposited = false;
        s.borrowerdetails[msg.sender].gottenfreecoin == false;
    }

    function checkuserbalance() external view returns(uint){
        return s.borrowerdetails[msg.sender].amountin;
    }

    receive() payable external{
        (bool sent,) = payable(msg.sender).call{value:msg.value}("");
        require(sent, "failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "../interfaces/IERC20.sol";

struct Borrower{
    address borrower;
    uint amounttoborrow;
    uint amountin;
    bool deposited;
    bool gottenfreecoin;
}

struct libstorage{
    ///////////////////////////////////////FREE TOKENS STATE///////////////////////////////// 

    ////////////////////////////////////////////LENDING STATE/////////////////////////////////////////
    mapping(address => Borrower) borrowerdetails;
    address owner;
    IERC20 tokenaddress;


}
library Appstorage{
    function appStorage() internal pure returns(libstorage storage s) {    
        assembly { s.slot := 0 }
    }
}

// SPDX-License-Identifier: MIT
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