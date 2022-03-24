/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}



/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}



contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract VanityName is
    Context,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;


    string vanity_mame;

    uint16 MAX_SIZE_ALLOWED=1024;

    uint256 internal _lock_start;

    address internal _feeCollector; // fee collecting account
    uint32 internal _fee; // fee % charge 0.01 % min fraction allowed
    uint32 internal _baseFee; // base fee for 0.01 % min allowed calculation fraction
    uint256 internal _caractPrice; // wei price for each letter
    
    uint32 internal _lock_time; // seconds units
    uint256 internal _blocked_amount;
    address internal _vanityOwner;



    event FeeChanged(uint32 oldFee, uint32 newFee);
    event BaseFeeChanged(uint32 oldbFee, uint32 newbFee);
    event FeeCollectorChanged(address oldOp, address newOp);
    event LockTimeChanged(uint32 oldlock, uint32 newLock);
    event CaractPriceChanged(uint256 old, uint256 NewCaractPrice);
    event VanityNameChanged(
        string oldName,
        string newName,
        address indexed oldOwner,
        address indexed newOwner,
        uint256 amount,
        uint256 fee );
    event FundsReleased(string oldVanityname,address indexed oldVanityOwner,uint256 amount );

    constructor(
        uint32 fee,
        address feeCollector,
        uint32 lock_time,  
        uint256 caractPrice 

    ) public {
        _fee = fee;
        _feeCollector = feeCollector;
        _lock_time =lock_time;
        _caractPrice = caractPrice;
        _baseFee = 10000; // for 0.01 % unit
        _lock_start= now.sub(lock_time); 
        _blocked_amount = 0;


    }



    /**
     * @dev get fee charge
     *
     *
     */
    function getFee() public view returns (uint32) {
        return _fee;
    }

    /**
     * @dev change fee charge transaction value
     *
     * Emit {FeeOperationChanged} evt
     *
     * Requirements:
     *      only Is InOwners require &&   newFee <= 1000000  && newFee <= _baseFee
     */
    function setFee(uint32 newFee) external onlyOwner returns (bool) {
        require((newFee <= 1000000), "1");
        require((newFee <= _baseFee), "2");

        uint32 old = _fee;
        _fee = newFee;
        emit FeeChanged(old, _fee);
        return true;
    }


    /**
     * @dev get base fee needed for tax calculation
     *
     *
     */
    function getBaseFee() public view returns (uint32) {
        return _baseFee;
    }

    /**
     * @dev change base fee needed for tax calculation
     *
     * Emit {BaseFeeChanged} evt
     *
     * Requirements:
     *      only Is InOwners require &&   newbFee <= 1000000 && newFee >= _fee
     */
    function setBaseFee(uint32 newbFee) external onlyOwner returns (bool) {
        require((newbFee <= 1000000), "1");
        require((newbFee >= _fee), "2");
        uint32 old = _baseFee;
        _baseFee = newbFee;
        emit BaseFeeChanged(old, _baseFee);
        return true;
    }




    /**
     * @dev get fee Collector wallet address
     *
     *
     */
    function getFeeCollector() public view returns (address) {
        return _feeCollector;
    }

    /**
     * @dev change  fee Collector wallet address
     *
     * Emit {FeeCollectorChanged} evt
     *
     * Requirements:
     *      only Is InOwners require
     */
    function setFeeCollector(address newOp)
        external
        onlyOwner
        returns (bool)
    {
        address old = _feeCollector;
        _feeCollector = newOp;
        emit FeeCollectorChanged(old, _feeCollector);
        return true;
    }


    function getLockTime() external view returns(uint256){
        return _lock_time;
    }


    function setLockTime(uint32 newLock)
        external
        onlyOwner
        returns (bool)
    {
        uint32 old = _lock_time;
        _lock_time = newLock;
        emit LockTimeChanged(old, _lock_time);
        return true;
    }



    function getCaractPrice() external view returns(uint256){
        return _caractPrice;
    }


    function setCaractPrice(uint256 newPrice)
        external
        onlyOwner
        returns (bool)
    {
        uint256 old = _caractPrice;
        _caractPrice = newPrice;
        emit CaractPriceChanged(old, newPrice);
        return true;
    }



    function getActualVanityOwner() external view returns(address){
        return _vanityOwner;
    }



    function howMuchTimeIsLeft() public view returns(uint256){

        if( (_lock_start + _lock_time) > now ) {
            return _lock_start.add(_lock_time).sub(now); 
        }

        return 0;
    }

    modifier Unloked() {
        require(howMuchTimeIsLeft() == 0, "Vanity:is still locked");
        _;
    }



    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }

    modifier ValidLength(string memory _name) {
        require( utfStringLength(_name) > 0 || utfStringLength(_name) <= MAX_SIZE_ALLOWED , "Vanity:Invalid string length");
        _;
    }

    /**
     * @dev get the Calculate the amount fees (net = amount - fee)
     *
     *
     * Returns:
     *      uint256 net amount
     *      uint256 fee amount
     *
     */
    function calcFeesAndNet(
        uint256 amount,
        uint32 fee,
        uint32 baseFee
    ) internal pure returns (uint256 net, uint256 _feee) {
        if (baseFee == 0) {
            _feee = 0;
            net = amount;
        } else {
            _feee = amount.mul(fee).div(baseFee);
            net = amount - _feee;
        }
    }


    function estimatedLockBalanceAndFee(string memory name) public view returns(uint256,uint256){

        uint length = utfStringLength(name);

        if(length==0 ) return (0,0);

        uint256 amount = _caractPrice.mul(length);

        (uint256 net, uint256 fee) = calcFeesAndNet(
            amount,
            _fee,
            _baseFee
        );

        return (net,fee);

    }

    function getVanityName() public view returns(string memory){
        return vanity_mame;
    }

    function setVanityName(string memory name) 
    public 
    payable
    Unloked
    ValidLength(name)
    nonReentrant
    {

        (uint256 net, uint256 fee) =estimatedLockBalanceAndFee(name);    

        require( net.add(fee) <=msg.value,"Vanity: Insufficient amount" );

        string memory old_vanity_mame = vanity_mame;
        vanity_mame = name;

        _lock_start= now;

        uint256 old_blocked_amount =_blocked_amount;
        _blocked_amount = net;

        address old_vanityOwner=_vanityOwner;
        _vanityOwner = _msgSender();


        if(old_blocked_amount > 0 ){
            address payable prev = address(uint160( old_vanityOwner));
            Address.sendValue(prev, old_blocked_amount);
        }

        if(fee>0){

            address payable fc = address(uint160( _feeCollector));
            Address.sendValue(fc, fee);

        }

        emit VanityNameChanged(old_vanity_mame,name,old_vanityOwner,_msgSender(),_blocked_amount,fee );
    }


    function releaseMyFunds() 
    public 
    Unloked
    nonReentrant
    {

        require(_msgSender() == _vanityOwner,"Vanity:you are not the vanity owner! "  );

        string memory old_vanity_mame = vanity_mame;
        vanity_mame = "";

        uint256 old_blocked_amount =_blocked_amount;
        _blocked_amount = 0;

        address old_vanityOwner=_vanityOwner;
        _vanityOwner = address(0);


        if(old_blocked_amount > 0 ){
            address payable prev = address(uint160( old_vanityOwner));
            Address.sendValue(prev, old_blocked_amount);
        }


        emit FundsReleased(old_vanity_mame,old_vanityOwner,old_blocked_amount );
    }

}