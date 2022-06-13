/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

contract RealEstate {

    using SafeMath for uint;

    
    /************************************************
                        variables
    ************************************************/
    address public Owner;
    uint public OwnerFee;
    uint public PropertyID;
    address[] public registryAuthority;
    uint public totalRegistryAuthorityapprovals;
    uint public GreaterThanTotalRegistryAuthorityApprovals;

    
    /************************************************
                        constructor
    ************************************************/
    constructor( address _Owner ) {
        Owner = _Owner;
        OwnerFee = 2;
    }

    
    /************************************************
                        struct
    ************************************************/
    struct Property {
        uint    propertyID;
        uint    Price;

        string  FullName;
        string  Address;
        string  Phone;
        address CurrentOwner;

        string  PropertyName;
        string  PropertyType;
        string  PropertyAddress;
        string  AdditionalInformation;
    }

    struct PreviousOwner {
        uint    propertyID;

        string  FullName;
        string  Address;
        string  Phone;
        address CurrentOwner;
    }

    struct BuyerRequestInformation {
        uint    propertyID;

        string  FullName;
        string  Address;
        string  Phone;
        address CurrentOwner;
    }

    
    /************************************************
                        mappings
    ************************************************/
    mapping( address => bool ) public isRegistryAuthority;

    mapping( uint => Property ) public properties;
    mapping( uint => PreviousOwner ) public previousOwner;
    mapping( uint => BuyerRequestInformation ) public buyerRequestInformation;

    mapping( uint => string ) public PurchasedDate;
    mapping( uint => string ) public requestForBuyDate;
    mapping( uint => string ) public requestForBuyDateIFAccepted;

    mapping( address => uint[] ) public userAllPropertiesIDs;
    mapping( address => uint[] ) public userAllPurchasedPropertiesIDs;

    mapping( uint => bool ) public PendingForSell;
    mapping( uint => bool[] ) public AcceptedForSell;
    mapping( uint => bool[] ) public DeclinedForSell;
    
    mapping( uint => bool ) public PendingforBuy;
    mapping( uint => bool[] ) public AcceptedforBuy;
    mapping( uint => bool[] ) public DeclinedforBuy;

    mapping( uint => bool ) public Sold;


    /************************************************
                        modifier
    ************************************************/
    modifier onlyOwner() {
        require( msg.sender == Owner, "You are not Owner" );
        _;
    }

    modifier onlyRegistryAuthority() {
        require( isRegistryAuthority[msg.sender], "You are not added in Registry Authority list" );
        _;
    }


    /************************************************
                        event
    ************************************************/
    event _Sold( uint PropertyID );
    event _Pending( uint PropertyID );
    event _Accepted( uint PropertyID );
    event _Declined( uint PropertyID );
    event _addProperty( address _Owner, uint Price );
    event _ownershipTransferred( uint PropertyID, address Owner );


    /************************************************
                        function
    ************************************************/
    function addProperty(

        uint          _Price,
        string memory _FullName,
        string memory _Address,
        string memory _Phone,
        string memory _PropertyName,
        string memory _PropertyType,
        string memory _PropertyAddress,
        string memory _AdditionalInformation

    ) external {

        PropertyID++;
        properties[PropertyID] = Property (
            PropertyID, (_Price.add(_Price.mul(OwnerFee).div(100))),
            _FullName, _Address, _Phone, msg.sender,
            _PropertyName, _PropertyType, _PropertyAddress, _AdditionalInformation
        );

        userAllPropertiesIDs[msg.sender].push(PropertyID);

        PendingForSell[PropertyID] = true;

        emit _Pending( PropertyID );
        emit _addProperty( msg.sender, _Price );

    }

    function requestForBuyProperty( 
        
        uint          _PropertyID,
        string memory _FullName,
        string memory _Address,
        string memory _Phone,
        string memory _Date,
        string memory _DateIFAccepted

    ) external payable {

        require (
            AcceptedForSell[_PropertyID].length > GreaterThanTotalRegistryAuthorityApprovals,
            "Real Estate: There is no such property for sell."
        );

        require (
            properties[_PropertyID].Price == msg.value,
            "Real Estate: Please Add Valid Amount"
        );

        (bool success, ) = (address(this)).call{value: msg.value}("");
        require(success, "Real Estate: Failed to send Ether");

        buyerRequestInformation[_PropertyID] = BuyerRequestInformation (
            _PropertyID, _FullName, _Address, _Phone, msg.sender
        );

        requestForBuyDate[_PropertyID] = _Date;
        requestForBuyDateIFAccepted[_PropertyID] = _DateIFAccepted;

        delete AcceptedForSell[_PropertyID];
        PendingforBuy[_PropertyID] = true;

    }

    mapping ( address => mapping ( uint => bool ) )  public yourRequestIsAccepted;

    function BuyProperty( uint _PropertyID ) external {

        require (
            yourRequestIsAccepted[msg.sender][_PropertyID],
            "Real Estate: Your Request is Declined or not Accepted."
        );

        require (
            buyerRequestInformation[_PropertyID].CurrentOwner == msg.sender,
            "Real Estate: you are not buyer Requester"
        );


        uint _ethValue = 
            sendRegistryAuthority(
                properties[_PropertyID].Price.mul(OwnerFee).div(100)
            );
        bool success;

        if ( _ethValue > 0 ) {

            (success, ) = 
                (properties[_PropertyID].CurrentOwner).call{
                    value: properties[_PropertyID].Price
                }("");
            require(success, "Real Estate1: Failed to send Ether");

        } else {

            (success, ) = 
                (properties[_PropertyID].CurrentOwner).call{
                    value: ((properties[_PropertyID].Price).sub(
                        properties[_PropertyID].Price.mul(OwnerFee).div(100)
                    ))
                }("");
            require(success, "Real Estate2: Failed to send Ether");

        }

        previousOwner[_PropertyID] = PreviousOwner (
            _PropertyID,
            properties[_PropertyID].FullName,
            properties[_PropertyID].Address,
            properties[_PropertyID].Phone,
            properties[_PropertyID].CurrentOwner
        );

        PurchasedDate[_PropertyID] = requestForBuyDateIFAccepted[_PropertyID];
        userAllPurchasedPropertiesIDs[msg.sender].push(_PropertyID);

        properties[_PropertyID].FullName = buyerRequestInformation[_PropertyID].FullName;
        properties[_PropertyID].Address = buyerRequestInformation[_PropertyID].Address;
        properties[_PropertyID].Phone = buyerRequestInformation[_PropertyID].Phone;
        properties[_PropertyID].CurrentOwner = buyerRequestInformation[_PropertyID].CurrentOwner;

        delete AcceptedforBuy[_PropertyID];
        Sold[_PropertyID] = true;

        emit _Sold( _PropertyID );
        emit _ownershipTransferred( _PropertyID, msg.sender );

    }

    function sendRegistryAuthority(uint256 _amount) internal returns( uint ) {

        if ( _amount < ( registryAuthority.length.add(100) ) )
            return _amount;

        _amount = _amount.div(registryAuthority.length);

        for (uint256 i = 0; i < registryAuthority.length; i++) {

            (bool Osuccess, ) = (registryAuthority[i]).call{value: _amount}("");
            require(Osuccess, "Real Estate: Failed to send Ether");       

        }

        return 0;
        
    }


    /************************************************
                onlyRegistryAuthority function
    ************************************************/

    mapping ( address => mapping ( uint => bool ) ) public isRegistryAuthorityAcceptedForSell;
    mapping ( address => mapping ( uint => bool ) ) public isRegistryAuthorityDeclinedForSell;
    mapping ( address => mapping ( uint => bool ) ) public isRegistryAuthorityAcceptedforBuy;
    mapping ( address => mapping ( uint => bool ) ) public isRegistryAuthorityDeclinedforBuy;


    function AcceptSellerRequest( uint _PropertyID ) external onlyRegistryAuthority {

        require(
            PendingForSell[_PropertyID],
            "Real Estate: There is no such property for Pending For Sell."
        );

        require(
            !isRegistryAuthorityAcceptedForSell[msg.sender][_PropertyID],
            "Real Estate: You already Accepted this property"
        );

        isRegistryAuthorityAcceptedForSell[msg.sender][_PropertyID] = true;

        if (AcceptedForSell[_PropertyID].length > GreaterThanTotalRegistryAuthorityApprovals) {
            PendingForSell[_PropertyID] = false;
        }

        AcceptedForSell[_PropertyID].push(true);

        emit _Accepted( _PropertyID );

    }

    function DeclineSellerRequest( uint _PropertyID ) external onlyRegistryAuthority {

        require(
            !isRegistryAuthorityDeclinedForSell[msg.sender][_PropertyID],
            "Real Estate: You already Accepted this property"
        );

        isRegistryAuthorityDeclinedForSell[msg.sender][_PropertyID] = true;
        DeclinedForSell[_PropertyID].push(true);

        if (DeclinedForSell[_PropertyID].length > GreaterThanTotalRegistryAuthorityApprovals) {
            PendingForSell[_PropertyID] = false;
        }

        emit _Declined( _PropertyID );

    }

    function AcceptBuyerRequest( uint _PropertyID ) external onlyRegistryAuthority {

        require(
            !isRegistryAuthorityAcceptedforBuy[msg.sender][_PropertyID],
            "Real Estate: You already Accepted this property"
        );

        isRegistryAuthorityAcceptedforBuy[msg.sender][_PropertyID] = true;
        AcceptedforBuy[_PropertyID].push(true);

        if (AcceptedforBuy[_PropertyID].length > GreaterThanTotalRegistryAuthorityApprovals) {

            PendingforBuy[_PropertyID] = false;
            yourRequestIsAccepted[
                buyerRequestInformation[_PropertyID].CurrentOwner
            ][_PropertyID] = true;
        }

        emit _Accepted( _PropertyID );

    }

    function DeclineBuyerRequest( uint _PropertyID ) external onlyRegistryAuthority {


        require(
            !isRegistryAuthorityDeclinedforBuy[msg.sender][_PropertyID],
            "Real Estate: You already Accepted this property"
        );

        isRegistryAuthorityDeclinedforBuy[msg.sender][_PropertyID] = true;  

        AcceptedForSell[_PropertyID].push(true);
        DeclinedforBuy[_PropertyID].push(true);

        if ( DeclinedforBuy[_PropertyID].length > GreaterThanTotalRegistryAuthorityApprovals ) {

            PendingforBuy[_PropertyID] = false;
            yourRequestIsAccepted[msg.sender][_PropertyID] = false;

            (bool success, ) = 
                (buyerRequestInformation[_PropertyID].CurrentOwner).call{
                    value: properties[_PropertyID].Price
                }("");
            require(success, "Real Estate: Failed to send Ether");
        }

        emit _Declined( _PropertyID );

    }


    /************************************************
                        onlyOwner function
    ************************************************/
    function addRegistryAuthority(address _address) external onlyOwner {
        
        registryAuthority.push(_address);
        isRegistryAuthority[_address] = true;
        totalRegistryAuthorityapprovals++;

        if(totalRegistryAuthorityapprovals%2==0) {

            GreaterThanTotalRegistryAuthorityApprovals = 
                totalRegistryAuthorityapprovals.div(2);

        } else {

            GreaterThanTotalRegistryAuthorityApprovals = 
                ((totalRegistryAuthorityapprovals.add(1)).div(2)).sub(1);

        }

    }

    function updateOwnerFee( uint _OwnerFee ) external onlyOwner {
        OwnerFee = _OwnerFee;
    }

    function ChangeOwner(address _Owner) external onlyOwner {
        Owner = _Owner;
    }


    /************************************************
                        view function
    ************************************************/
    function getUserAllpropertiesIDs(address _user) public view returns( uint[] memory _IDs ) {
        return userAllPropertiesIDs[_user]; 
    }

    function getUserAllPurchasedPropertiesIDs(address _user) public view returns( uint[] memory _IDs ) {
        return userAllPurchasedPropertiesIDs[_user]; 
    }

    function isAcceptedForSell( uint _PropertyID ) public view returns( bool[] memory _AcceptedForSell ) {
        return AcceptedForSell[_PropertyID];
    }


    /************************************************
                        Fallback function
    ************************************************/
    receive() external payable {}
    fallback() external payable {}

}


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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}