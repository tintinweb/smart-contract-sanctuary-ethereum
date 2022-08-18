/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity ^0.8.0;

contract orders {
    using SafeMath for uint256;
     /// @notice Explain to an end user what this does
        /// @dev Explain to a developer any extra details
        /// @return Documents the return variables of a contract’s function state variable
        /// @inheritdoc	Copies all missing tags from the base function (must be followed by the contract name)
    enum  status {Created, DownPaid, Paid,  Shipped, Dispatched, Released, Delivered, Completed} 


     struct  order {
        uint256 invoice_no;
        string picUrl;
        uint256 preshipment;//SGS
        uint256 handlingcost;//HAB
        uint256 seafreight;//BOL
        uint256 shippinglinecost;
        uint256 kpa; //KPA release order
        uint256 taxes; //Custom entry
        uint256 kebs; //Conformity
        uint256 transport;//delivery order
        uint256 price; //invoice
        status Status;
    }

    
    mapping (uint256 => bool) public isOrder; //check if order is valid
    mapping (uint256 => order) public sortOrder; // sort each order as a structure
    mapping (uint256 => uint256) public payment; // manage order
    mapping (uint256 => uint256) public total;
    mapping (uint256 => uint256) public agency;

    event created(uint256 invoice, string  pictureUrl);
    event accepted(uint256 invoice, uint256  price);
    event downpayment(uint256 invoice, uint256  payment);
    event agencyFee(uint256 invoice, uint256  fee);

    modifier onlyOrder (uint256 _invoice) {
         require(isOrder[_invoice] == true, "the order doesn't exist");
         _;
    }

    function  createOrder(string memory _picUrl) public returns (uint256){
        uint256 _invoice = invoiceNum();
        sortOrder[_invoice].invoice_no = _invoice;
        sortOrder[_invoice].picUrl= _picUrl;
        sortOrder[_invoice].Status = status.Created;
        isOrder[_invoice] = true;
        emit created(_invoice, _picUrl);
        return _invoice;
     
    }

    function acceptOrder (uint256 _invoice, uint256 _price) public  onlyOrder(_invoice) returns (uint256, uint256){
       
        sortOrder[_invoice].price = _price;
        //sortOrder[_invoice].agency = _pri;
        setTotal(_invoice, _price);
        
        emit accepted(_invoice, _price);
        return (_invoice, _price);

    }

    function setTotal (uint256 _invoice, uint256 _add) internal{
       total[_invoice] =  total[_invoice].add(_add);    

    }
    
    function payIt (uint256 _invoice, uint256 _paid) internal{
       payment[_invoice] =  payment[_invoice].add(_paid);    

    }

     function invoiceNum() private view returns (uint256) {
        return uint256(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%259);
    } 

    function downPayOrder(uint256 _invoice, uint256 _payment) public onlyOrder(_invoice) returns (uint256){
        uint256 _price = total[_invoice];
        require(_payment <= _price, "Downpayment must be less than total");
        payment[_invoice] = payment[_invoice].add(_payment);
        //sortOrder[_invoice].payment.add(_payment);
        
        sortOrder[_invoice].Status = status.DownPaid;
        emit downpayment(_invoice, _payment);
        return payment[_invoice];
    }
   
   function payAgencyFee (uint256 _invoice, uint256 _fee) public onlyOrder(_invoice) returns (uint256, uint256){
        agency[_invoice] = _fee;
        //sortOrder[_invoice].agency = _pri;
        setTotal(_invoice, _fee);
        
        emit agencyFee(_invoice, _fee);
        return (_invoice, _invoice);

    }



}