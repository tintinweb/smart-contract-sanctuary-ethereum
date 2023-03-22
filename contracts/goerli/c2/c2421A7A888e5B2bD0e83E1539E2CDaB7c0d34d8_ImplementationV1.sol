/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

//SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: ImplementationV3.sol_flattened.sol



// File: Erc721_Storage_Pattern.sol


pragma solidity ^0.8.13;

// This `Split_payment` struct
// hold a single address and how much percentage to send
// in this address. Say we have set 3 account for split payment
// this struct will hold 1 account address and how much % to send
// to this address.
struct Split_payment {
	address addr;
	uint percentage;
}

// This `Royality` struct hold single token royality percentage
// and a bool `hasSplitPayment` if this token has split payment
// then royality percentage need to devide in those split accounts
// Ex: royality percentage is 10%; And 3 split accounts has been set.
// then this 10% will be devide by split accounts percentages accordingly
// lets say 1st split account percentage is 60; Then 10% royalties 60%
// will go to that split account. Other account get the royality in the same system.
struct Royalty {
	uint percentage;
	bool has_split_payment;
}

struct Erc_721_token_details {
  address creator;
  address owner;
  uint chain_id;
}

struct Erc_721_storage_pattern {
    mapping( uint => Erc_721_token_details ) id_to_details;
    mapping( uint => bool ) id_to_exist;
    mapping( uint => uint ) id_to_price;
    mapping( uint => bool ) id_to_is_listed;
    mapping( uint => bool ) id_to_has_split_payment;
    mapping( uint => mapping( uint => Split_payment ) ) id_to_split_payment;
    mapping( uint => uint ) id_to_total_split_payment_accounts;
    mapping( uint => bool ) id_to_has_royalty;
    mapping( uint => Royalty ) id_to_royalty;
}

struct ERC_721_STORAGE {
    mapping( address => Erc_721_storage_pattern ) contract_to_storage;
}


// File: Interface.sol


pragma solidity ^0.8.13;



interface ERC721_Interface {
  function ownerOf(uint256 tokenId) view external returns (address);
  function safeTransferFrom(address from,address to,uint256 tokenId) external;
  function gift_mint(string memory tokenUri, address owner) external returns(uint256);
}

interface ERC20_Interface {
  function transferFrom( address from, address to, uint256 amount ) external returns ( bool );	
}

interface Common_Interface {
  function isApprovedForAll(address account, address operator) view external returns( bool );
}


// File: ImplementationV1.sol


pragma solidity ^0.8.13;



/*import "hardhat/console.sol";*/

contract ImplementationV1 {
  ERC_721_STORAGE S; 
  using SafeMath for uint;

  modifier erc721_token_exist_error( address _contract_add, uint256 _token_id ) {
    require(
      !S.contract_to_storage[ _contract_add ].id_to_exist[ _token_id ],
      "T exist"
    );
    _;
  }
  
  modifier erc721_token_not_exist_err( address _contract_add, uint256 _token_id ) {
    require( S.contract_to_storage[ _contract_add ].id_to_exist[ _token_id ], "T n e");
    _;
  }

  modifier invalid_add_err( address add ) {
    require( add != address(0), "Inv add");
    _;
  }

  modifier zero_price_err( uint256 price ) {
    require( price != 0,"Pri 0");
    _;
  }

  modifier erc721_only_owner_error( address _contract_add, uint256 _token_id ) {
    require( ERC721_Interface( _contract_add ).ownerOf( _token_id ) == msg.sender,"only for owner");
    _;
  }

  modifier erc721_market_dont_have_access_error( address _contract_add, uint256 _token_id ) {
    require(
      Common_Interface( _contract_add ).isApprovedForAll( ERC721_Interface( _contract_add ).ownerOf( _token_id ), address(this) ),
      "dont have approval transfer"
    );
    _;
  }



  //UTILITY FUNCTION
  function erc721_token_exist( address _contract_add, uint256 _token_id ) public view returns(bool) {
      return S.contract_to_storage[ _contract_add ].id_to_exist[ _token_id ];
  }

  function erc721_is_listed_for_sale( address _contract_add, uint256 _token_id ) public view returns( bool ) {
       return S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ];
  }

  function erc721_get_token_price( address _contract_add, uint256 _token_id )
    erc721_token_not_exist_err( _contract_add, _token_id )
    public view returns(uint256) 
    {
       return S.contract_to_storage[ _contract_add ].id_to_price[ _token_id ];
    }


  //UTILITY FUNCTION END.

  function split_payment_err( uint256[] memory _percentages ) private pure{
    uint256 _total_percentage;
    for(uint256 i = 0; i < _percentages.length; i++) {
      _total_percentage += _percentages[i];
    }

    require(
      _total_percentage == 10000,
      "Split payment must be 100% accurate."
    );
  }


  function _erc721_set_token_details(
    address _contract_add,
    uint256 _token_id,
    address _token_creator,
    uint _chain_id
  ) private {
    S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ] = Erc_721_token_details( 
              _token_creator,
              ERC721_Interface( _contract_add ).ownerOf( _token_id ),
              _chain_id
        );
  }





//Writing Funtion
  function _erc721_update_split_payment(
    // address _split_payment_account,
    address _contract_add,
    uint256 _token_id,
    address _account
  ) public erc721_only_owner_error( _contract_add, _token_id )
  {
    uint len = S.contract_to_storage[ _contract_add ].id_to_total_split_payment_accounts[ _token_id ];
    uint new_shares = SafeMath.div(10000,(len+1));
    uint check_sum = 0;
    for(uint i=1 ; i <= len ; i++)
    {
      S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][i] = Split_payment( S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][i].addr, new_shares );
      check_sum += new_shares;
    }
    uint last_share = SafeMath.sub(10000,check_sum);
    S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][len+1] = Split_payment( _account, last_share );
    S.contract_to_storage[ _contract_add ].id_to_total_split_payment_accounts[ _token_id ] += 1;
    
  }

  

 // Check split payments
 function _erc721_check_split_payment_receivers(
   address _contract_add,
    uint256 _token_id
 ) public view returns(uint,Split_payment[] memory)
 {
   uint len = S.contract_to_storage[ _contract_add ].id_to_total_split_payment_accounts[ _token_id ];
   Split_payment[] memory temp = new Split_payment[](len);   
  for (uint i = 1; i <= len; i++) {
    temp[i-1] = S.contract_to_storage[_contract_add].id_to_split_payment[_token_id][i];
  }
   return (len, temp);
 }

 function _erc721_check_if_user_is_in_list(
   address _contract_add,
    uint256 _token_id,
    address _receiver
 ) public view returns(bool)
 {
   uint len = S.contract_to_storage[ _contract_add ].id_to_total_split_payment_accounts[ _token_id ];
   for (uint i = 1; i <= len; i++) {
    if(_receiver == S.contract_to_storage[_contract_add].id_to_split_payment[_token_id][i].addr)
    {
      return true;
    }
  }
  return false;
 }


//Check if user is part of royalty list
function _erc721_check_receiver_list(
   address _contract_add,
    uint256 _token_id,
    address _user
)public view returns(bool)
{
    uint len = S.contract_to_storage[ _contract_add ].id_to_total_split_payment_accounts[ _token_id ];
    for(uint i=1 ; i <= len ; i++)
    {
      if(_user == S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][i].addr)
      {
        return true;
      }
    }
    return false;
}


function is_split_payment_available(
  address _contract_address,
  uint256 _token_id
) public view returns(bool)
{
  return S.contract_to_storage[ _contract_address ].id_to_royalty[ _token_id ].has_split_payment;
}

  function _erc721_set_token_price_and_other_info(
    address _contract_add,
    uint256 _token_id,
    uint256 _token_price
  ) private {
    S.contract_to_storage[ _contract_add ].id_to_price[ _token_id ] = _token_price;
    S.contract_to_storage[ _contract_add ].id_to_exist[ _token_id ] = true;
    S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ] = true;
  }

  function _erc721_set_token_split_payment(
    address _contract_add,
    uint256 _token_id,
    uint256[] memory _split_payment_percentages,
    address[] memory _split_payment_accounts
  )private{
    if( _split_payment_percentages.length != 0 && _split_payment_accounts.length != 0 ) {
        split_payment_err( _split_payment_percentages );
        S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] = true;
        //save the account data in the mapping
        for( uint256 i = 0; i < _split_payment_accounts.length; i++ ) {
            S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][i+1] = Split_payment( _split_payment_accounts[i], _split_payment_percentages[i] );
			S.contract_to_storage[ _contract_add ].id_to_total_split_payment_accounts[ _token_id ] += 1;
        }
    }
  }

  function _erc721_set_token_royalty(
    address _contract_add,
    uint256 _token_id,
    uint256 _royalty_percentage
  ) private {
    if( _royalty_percentage != 0 ) {
        S.contract_to_storage[ _contract_add ].id_to_has_royalty[ _token_id ] = true;
        S.contract_to_storage[ _contract_add ].id_to_royalty[ _token_id ] = Royalty( _royalty_percentage, S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] );
    }
  }


  function _erc721_check_is_royalty_set(
     address _contract_add,
    uint256 _token_id
  ) public view returns(bool)
  {
    return  S.contract_to_storage[ _contract_add ].id_to_has_royalty[ _token_id ];
  }


  function erc721_list_in_market (
    address _contract_add,
    uint256 _token_id,
    address _token_creator,
    uint _chain_id,
    uint256 _token_price,
    uint256[] memory _split_payment_percentages,
    address[] memory _split_payment_accounts,
    uint256 _royalty_percentage
  ) public payable 
  erc721_token_exist_error( _contract_add, _token_id )
  zero_price_err( _token_price )
  invalid_add_err( _contract_add ) 
  invalid_add_err( _token_creator )
  erc721_only_owner_error( _contract_add, _token_id )
  {
    //ADD ALL THE DATA IN STORAGE
    _erc721_set_token_details( _contract_add, _token_id, _token_creator, _chain_id );
    _erc721_set_token_price_and_other_info(_contract_add, _token_id, _token_price );
    _erc721_set_token_split_payment( _contract_add, _token_id, _split_payment_percentages, _split_payment_accounts );
    _erc721_set_token_royalty( _contract_add, _token_id, _royalty_percentage );
  }

  function erc721_remove_from_sale (
    address _contract_add,
    uint256 _token_id
  ) public 
  erc721_token_not_exist_err( _contract_add, _token_id )
  invalid_add_err( _contract_add )
  erc721_only_owner_error( _contract_add, _token_id )
  {
    S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ] = false;
  }

  function erc721_put_on_sale (
    address _contract_add,
    uint256 _token_id,
    uint256 _price
  ) public 
  erc721_token_not_exist_err( _contract_add, _token_id )
  invalid_add_err( _contract_add )
  erc721_only_owner_error( _contract_add, _token_id )
  {
    S.contract_to_storage[ _contract_add ].id_to_price[ _token_id ] = _price;
    S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ] = true;
  }

	function calc_percentage( 
		uint _amount,
		uint _percentage 
	) private pure returns (uint) {
		//_percentage is send by multiplying with 100
		//to get the percentage we devide the percentage with 10000
		return _amount * _percentage / 10000;
	}

	function _erc721_process_split_payment ( address _contract_add, uint _token_id, uint _total_amount, bool CT, address TA ) private {  
		// CT = custom token, TA = erc 20 token contract address
		for( uint i = 0; i < S.contract_to_storage[ _contract_add ].id_to_total_split_payment_accounts[ _token_id ]; i++ ) {
		  if(
              S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][ i + 1 ].percentage != 0  &&
              S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][ i + 1 ].addr != address(0)
		    )
            {
		       uint payment = calc_percentage( _total_amount, S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][ i + 1 ].percentage );
			   if( CT == true ) {
			   	bool success = ERC20_Interface( TA ).transferFrom(
			   		msg.sender,   
 			   		S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][ i + 1 ].addr,
			   		payment
			   	);
			   	require( success == true, "erc20 token transfer fail." );
			   }else{
			      payable( S.contract_to_storage[ _contract_add ].id_to_split_payment[ _token_id ][ i + 1 ].addr).transfer(payment);
			   }
		    }
		}

		//process compleate close this split payment 
		S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] = false;
	}

  function _erc721_buy_from_market_err( address _contract_add,  uint256 _token_id ) private {
      require( msg.sender != S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].owner,"You already owne the token" );
      require( S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ],"This token is not for sell" );
      require( msg.value == S.contract_to_storage[ _contract_add ].id_to_price[ _token_id ],"Please send the correct price" );
  }

  function _erc721_buy_from_market_split_payment_royalty_handler(
    address _contract_add, 
    uint256 _token_id,
    address owner,
    address creator
  ) private {
		if( S.contract_to_storage[ _contract_add ].id_to_has_royalty[ _token_id ] ) {

		        uint _royality = calc_percentage( msg.value, S.contract_to_storage[ _contract_add ].id_to_royalty[ _token_id ].percentage );
				uint ownerMoney = msg.value - _royality;	

				//check if split payment is set
				if( S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] ) {
                //if split payment is set that means
                //its a first time sale.
                //on first time sale royalty will not include
                //royalty will cut on secondary sale
                //so split payment will get full price
                _erc721_process_split_payment( _contract_add, _token_id, msg.value, false, address(0) );
				}else{
				//split payment not set so process normaly
				payable(owner).transfer(ownerMoney);

				//check if royality has split payment
                //if royality has split payment then royality will
                //send accourding to those split payment
				if( S.contract_to_storage[ _contract_add ].id_to_royalty[ _token_id ].has_split_payment ) {
                     _erc721_process_split_payment( _contract_add, _token_id, _royality, false, address(0) );
				  }else{
					//royalty has no split payment
					//not need to send royalty to multiple account
					//pay the creator his royality
					payable(creator).transfer(_royality);
				 }
				}

		}else{
            //no royalty is set. So send the full price to the owner.
            // check split payment is set then send the money to multiple account
			if( S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] ) {
                _erc721_process_split_payment( _contract_add, _token_id, msg.value, false, address(0) );
			}else{
			//split payment not set so process normaly
            //send the money to only one account of owner
				payable(owner).transfer(msg.value);
			}
	  }

  }

  function _erc721_buy_from_market_with_custom_token_split_payment_royalty_handler(
    address _contract_add, 
    uint256 _token_id,
    address owner,
    address creator,
	address _erc20_address
  ) private {
		uint256 _price = S.contract_to_storage[_contract_add].id_to_price[_token_id];
		bool success;

		if( S.contract_to_storage[ _contract_add ].id_to_has_royalty[ _token_id ] ) {

		        uint _royality = calc_percentage( _price, S.contract_to_storage[ _contract_add ].id_to_royalty[ _token_id ].percentage );
				uint ownerMoney = _price - _royality;	

				//check if split payment is set
				if( S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] ) {
                //if split payment is set that means
                //its a first time sale.
                //on first time sale royalty will not include
                //royalty will cut on secondary sale
                //so split payment will get full price
                _erc721_process_split_payment( _contract_add, _token_id, _price, true, _erc20_address );
				}else{
				//split payment not set so process normaly
			   	success = ERC20_Interface( _erc20_address).transferFrom(msg.sender, owner, ownerMoney);
			   	require( success == true, "erc20 token transfer fail." );

				//check if royality has split payment
                //if royality has split payment then royality will
                //send accourding to those split payment
				if( S.contract_to_storage[ _contract_add ].id_to_royalty[ _token_id ].has_split_payment ) {
                     _erc721_process_split_payment( _contract_add, _token_id, _royality, true, _erc20_address );
				  }else{
					//royalty has no split payment
					//not need to send royalty to multiple account
					//pay the creator his royality
			   		success = ERC20_Interface( _erc20_address).transferFrom(msg.sender, creator, _royality);
			   		require( success == true, "erc20 token transfer fail." );
				 }
				}

		}else{
            //no royalty is set. So send the full price to the owner.
            // check split payment is set then send the money to multiple account
			if( S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] ) {
                _erc721_process_split_payment( _contract_add, _token_id, _price, true, _erc20_address );
			}else{
				//split payment not set so process normaly
            	//send the money to only one account of owner
				success = ERC20_Interface( _erc20_address).transferFrom(msg.sender, owner, _price);
				require( success == true, "erc20 token transfer fail." );
			}
	  }

  }


  function _erc721_after_buy_change_owner_and_status(
    address _contract_add,
    uint _token_id
  ) private 
  {
    //unlist from sale
    S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ] = false;
    //change owner
    S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].owner = msg.sender; 
  }

  function erc721_buy_from_market( address _contract_add, uint _token_id ) 
    erc721_token_not_exist_err( _contract_add, _token_id )
    invalid_add_err( _contract_add )
    erc721_market_dont_have_access_error( _contract_add, _token_id )
    public payable 
  {
    address owner = S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].owner;
    address creator = S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].creator;

	//validate
    _erc721_buy_from_market_err( _contract_add, _token_id );
    //split payment and royality
    _erc721_buy_from_market_split_payment_royalty_handler( _contract_add, _token_id, owner, creator );
    _erc721_after_buy_change_owner_and_status( _contract_add, _token_id );
    //Everything is right now transfer the token to new owner
    ERC721_Interface( _contract_add ).safeTransferFrom( owner, msg.sender, _token_id );
  }

  function erc721_buy_from_market_using_custom_token( address _contract_add, uint _token_id, address _erc20_address ) 
    erc721_token_not_exist_err( _contract_add, _token_id )
    invalid_add_err( _contract_add )
    erc721_market_dont_have_access_error( _contract_add, _token_id )
    public payable 
  {
    address owner = S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].owner;
    address creator = S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].creator;
	//validate
    require( msg.sender != S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].owner,"You already owne the token" );
    require( S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ],"This token is not for sell" );
    //split payment and royality with custom token
    _erc721_buy_from_market_with_custom_token_split_payment_royalty_handler( _contract_add, _token_id, owner, creator, _erc20_address );
	//update new owner and status
    _erc721_after_buy_change_owner_and_status( _contract_add, _token_id );
    //Everything is right now transfer the token to new owner
    ERC721_Interface( _contract_add ).safeTransferFrom( owner, msg.sender, _token_id );
  }
  	

  function erc721_remove_from_sale_after_transfer( address _contract_add,uint _token_id, address new_owner )
  	erc721_only_owner_error( _contract_add, _token_id ) public 
  {
    //unlist from sale
    S.contract_to_storage[ _contract_add ].id_to_is_listed[ _token_id ] = false;
    //change owner
    S.contract_to_storage[ _contract_add ].id_to_details[ _token_id ].owner = new_owner; 
	//close the split payment
	S.contract_to_storage[ _contract_add ].id_to_has_split_payment[ _token_id ] = false;
  }



  function lazy_mint (
	address[] memory _params_one, //contract_address,token_creator, _split_payment_accounts_from_index_two
	uint256[] memory _params_two, //chain_id,total_price,royalty_percentage, token_id, amount, _split_payment_percentages_from_index_four
	bool[3] memory _params_three, //is_erc_1155,has_split_payment,has_royalty
	string memory tokenUri
  ) public payable 
  {
		//error check 
		require( _params_two[1] == msg.value, "send correct price" );

		uint256[] memory _split_payment_percentages = new uint256[](_params_two.length - 4);
		address[] memory _split_payment_accounts = new address[](_params_one.length - 2);

		//setting split payment accounts
		for( uint256 i = 0; i < _params_one.length; i++ ) {
			if(i >= 2){
				_split_payment_accounts[i - 2] = _params_one[i];
			}
		}

		//setting split payment percentage
		for( uint256 i = 0; i < _params_two.length; i++ ) {
			if(i >= 5){
				_split_payment_percentages[i - 5] = _params_two[i];
			}
		}

		//1155 standard
		if(_params_three[0]){
			//mint the token	
			// ERC1155_Interface(_params_one[0]).gift_mint(_params_two[4], tokenUri, _params_one[1]);
			// //list in market
			// _erc1155_list_in_market( _params_one[0], _params_two[3], _params_two[4], _params_two[1], _params_one[1] );
			//buy from market
			// erc1155_buy_token( _params_one[0], _params_two[3], _params_one[1], 1 );
		
		//721 standard
		}else{

			//mint the token
			ERC721_Interface( _params_one[0] ).gift_mint(tokenUri, msg.sender );

			//save data
    		_erc721_set_token_details( _params_one[0], _params_two[3], _params_one[1], _params_two[0] );
    		S.contract_to_storage[ _params_one[0] ].id_to_exist[ _params_two[3] ] = true;

			//royalty
			if( _params_three[2] ){
    			_erc721_set_token_royalty( _params_one[0], _params_two[3], _params_two[2] );
			}

			//split payment
			if(_params_three[1]){
    			_erc721_set_token_split_payment( _params_one[0], _params_two[3],  _split_payment_percentages, _split_payment_accounts );
				_erc721_process_split_payment(_params_one[0], _params_two[3], _params_two[1], false, address(0) );
			}else{
				payable(_params_one[1]).transfer(_params_two[1]);
			}

		}

  }

  
}