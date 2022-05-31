// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract vestor{
    using Counters for Counters.Counter;

    event HTLCERC20New(
        uint256 indexed contractId,
        address indexed _tokencontractaddress,
        address[] indexed _investors,
        uint256[] amountperinvestors,
        uint256 _vestingPeriod
    );
    event HTLCERC20Withdraw(address indexed investoraddress,uint256 indexed contractId);
    
    struct vest {
     address _tokencontractaddress;
     address[] investors;
     address tokenvestor;
     uint256 _vestid;
     uint256[] _amountperinvestors;
     uint256 _TotalAmount;
     uint256 _vestingPeriod;
     uint256 _startPeriod;
     uint256 timesclaimableforinvestors;



    }

    modifier tokenstransferFromable(address _token, address _owner,uint256 _amount) {
        // ensure this contract is approved to transferFrom the designated token
        // so that it is able to honor the claim request later
        require(
            IERC20(_token).allowance(_owner,address(this)) ==_amount,
            "The HTLC must have been designated an approved spender for the tokenId"
        );
        _; 
    }

    uint256 contractfees;
    Counters.Counter private contractid;

    mapping (uint256 => vest) vestcontracts;
    mapping(address =>mapping(uint256 =>uint256))amountofinvestorsbyindex;

    mapping(address =>mapping(uint256 => uint256))userclaimingstart;
    mapping(address =>mapping(uint256 => uint256))timesclaimablebyinvestors;

    mapping(address => uint256[]) public idsbyaddress;
    mapping(address => uint256[])public idcountbyinvestor;

    function vestTokens(
     address tokencontractaddress,
     address[]calldata investors,
     uint256 vestingPeriod,
     uint256[]calldata amountperinvestors,
     uint256 TotalAmount,
     uint256 _timesclaimableforinvestors,
     uint256 startperiod
    )
    external
    payable
    tokenstransferFromable(tokencontractaddress, msg.sender,TotalAmount)
    {



     vestcontracts[contractid.current()] = vest(
         tokencontractaddress,
         investors,
         msg.sender,
         contractid.current(),
         amountperinvestors,
         TotalAmount,
         vestingPeriod,
         startperiod,
         _timesclaimableforinvestors
     );

     for (uint i = 0; i < investors.length; i++) {

         userclaimingstart[investors[i]][contractid.current()] = block.timestamp;
         timesclaimablebyinvestors[investors[i]][contractid.current()] = amountperinvestors[i]*vestingPeriod;

         idcountbyinvestor[investors[i]].push(contractid.current());
         amountofinvestorsbyindex[investors[i]][contractid.current()] = amountperinvestors[i];
        }


        idsbyaddress[msg.sender].push(contractid.current());

        IERC20(tokencontractaddress).transferFrom(msg.sender,address(this),addforamount(amountperinvestors)*vestingPeriod);


        emit HTLCERC20New(
         contractid.current(),
         tokencontractaddress,
         investors,
         amountperinvestors,
         vestingPeriod
        );
        contractid.increment();
     
    }

    function claimtokens(uint256 _contractid)public {
        vest storage c = vestcontracts[_contractid];

   require(isWhitelisted(msg.sender,_contractid)!=false);
   require(block.timestamp >= c._startPeriod  );

   require(timesclaimablebyinvestors[msg.sender][_contractid] >= 0);
   require(block.timestamp - userclaimingstart[msg.sender][_contractid] >= c._vestingPeriod);

   

   

   timesclaimablebyinvestors[msg.sender][_contractid] = c.timesclaimableforinvestors - amountofinvestorsbyindex[msg.sender][_contractid]; 
   userclaimingstart[msg.sender][_contractid] = block.timestamp;
   IERC20(c._tokencontractaddress).transfer(msg.sender,amountofinvestorsbyindex[msg.sender][_contractid]);
   
   emit HTLCERC20Withdraw(msg.sender,_contractid);

    }

    function getContract(uint256 _contractId)
        public
        view
        returns (
     address _tokencontractaddress,
     address tokenvestor,
     uint256 _TotalAmount,
     uint256 _vestingPeriod
          
        )
    {
        if (haveContract(_contractId) == false)
             revert("contractid doesnt exist");
        vest storage c = vestcontracts[_contractId];
        return (
            c._tokencontractaddress,
            c.tokenvestor,
            c._TotalAmount,
            c._vestingPeriod
        );
    }


    function isWhitelisted(address _user,uint256 _Contractid) public view returns (bool) {
        vest storage c = vestcontracts[_Contractid];
    for (uint i = 0; i <= c.investors.length; i++) {
      if (c.investors[i] == _user) {
          return true;
      }
    }
    return false;
  }
        


    function haveContract(uint256 _contractId)
        internal
        view
        returns (bool exists)
    {
        exists = (vestcontracts[_contractId]._tokencontractaddress != address(0));
    }

    function fetchcontractsCreated(address _address) public view returns (uint256[]memory) {
           return idsbyaddress[_address];
    }

        function fetchcontractswhitelisted(address _address) public view returns (uint256[]memory) {
           return idcountbyinvestor[_address];
    }

        function addforamount(uint256[] memory _numbers)public pure returns(uint256){
        uint256 totalamount;
        for (uint i = 0; i < _numbers.length; i++) {
            totalamount += _numbers[i] ;
    }
    return totalamount;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}