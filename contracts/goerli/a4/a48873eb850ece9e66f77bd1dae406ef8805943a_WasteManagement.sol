/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/warehouse.sol


pragma solidity ^0.8.7;




contract WasteManagement is Ownable,ReentrancyGuard {
    using Strings for uint256;
    
    struct Waste {
        uint id;
        // bool wIn;
        // bool wOut;
        // bool cIn;
        // bool cOut;
        mapping(string => string) initData;
        mapping(string => string) wDataIn;
        mapping(string => string) wDataOut;
        mapping(string => string) cDataIn;
        mapping(string => string) cDataOut;
    }

    mapping(uint256 => Waste) getData;

    
    event change_init(uint,string,string,string,string,string,string,string,string);
    event change_init_out(uint,string);
    event change_w_in(uint,string,string,string);
    event change_w_out(uint,string,string);
    event change_c_in(uint,string,string,string,string,string);
    event change_c_out(uint,string,string);
    

//  ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓Set Init↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

    function initWaste(
        uint _id,
        string memory _componentsId,
        string memory _goodsName,
        string memory _dangerNum,
        string memory _producePlace,
        string memory _contacts,
        string memory _productCode,
        string memory _amount,
        string memory _sctime
        ) public onlyOwner{
            // require(!(getData[_id].id==_id),"ID already exists");
            Waste storage waste = getData[_id];
            waste.id=_id;
            waste.initData["componentsId"]=_componentsId;
            waste.initData["goodsName"]=_goodsName;
            waste.initData["dangerNum"]=_dangerNum;
            waste.initData["producePlace"]=_producePlace;
            waste.initData["contacts"]=_contacts;
            waste.initData["productCode"]=_productCode;
            waste.initData["amount"]=_amount;
            waste.initData["sctime"]=_sctime;
            // waste.initData["outTime"]=_outTime;
            // waste.wIn=false;
            // waste.wOut=false;
            // waste.cIn=false;
            // waste.cOut=false;
            emit change_init(_id,_componentsId,_goodsName,_dangerNum,_producePlace,_contacts,_productCode,_amount,_sctime);
    }

    function initOut(
        uint _id,
        string memory _outTime,
        string memory _operateperson
        ) public onlyOwner{
            require(getData[_id].id==_id,"ID does not exist");
            Waste storage waste = getData[_id];

            waste.initData["outTime"]=_outTime;
            waste.initData["operateperson"]= _operateperson;
            emit change_init_out(_id,_outTime );
    }

//  ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓Set Warehouse↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

    function warehouseIn(
        uint _id,
        string memory _importTime,
        string memory _amount,
        string memory _operateperson
        ) public onlyOwner{
            require(getData[_id].id==_id,"ID does not exist");
            Waste storage waste = getData[_id];

            waste.wDataIn["importTime"]= _importTime;
            waste.wDataIn["amount"]= _amount;
            waste.wDataIn["operateperson"]= _operateperson;
            // waste.wIn=true;
            emit change_w_in(_id,_importTime ,_amount ,_operateperson );
    }

    function warehouseOut(
        uint _id,
        string memory _outTime,
        string memory _operateperson
        ) public onlyOwner{
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].wIn,"The product has not yet entered the warehouse");
            Waste storage waste = getData[_id];

            waste.wDataOut["outTime"]= _outTime;
            waste.wDataOut["operateperson"]= _operateperson;
            // waste.wOut=true;
            emit change_w_out(_id,_outTime ,_operateperson );
    }

//  ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓Set company↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

    function companyIn(
        uint _id,
        string memory _customerid,
        string memory _salePrice,
        string memory _importTime,
        string memory _amount,
        string memory _operateperson
        ) public onlyOwner{
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].wOut,"The product has not left the warehouse");
            Waste storage waste = getData[_id];

            waste.cDataIn["customerid"]=_customerid;
            waste.cDataIn["salePrice"]= _salePrice;
            waste.cDataIn["importTime"]= _importTime;
            waste.cDataIn["amount"]= _amount;
            waste.cDataIn["operateperson"]= _operateperson;
            // waste.cIn=true;
            emit change_c_in(_id,_customerid ,_salePrice ,_importTime ,_amount ,_operateperson );
    }

    function companyOut(
        uint _id,
        string memory _OutTime,
        string memory _operateperson
        ) public onlyOwner{
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].cIn,"The product has not yet entered the warehouse");
            Waste storage waste = getData[_id];

            waste.cDataOut["OutTime"]= _OutTime;
            waste.cDataOut["operateperson"]= _operateperson;
            // waste.wOut=true;
            emit change_c_out(_id,_OutTime ,_operateperson );
    }
    



//  ↓↓↓↓↓↓↓↓↓↓↓Get Data↓↓↓↓↓↓↓↓↓↓

    function getInitData(uint _id)public view returns (
        uint WasteId,
        string memory componentsID,
        string memory goodsName,
        string memory dangerNum,
        string memory producePlace,
        string memory contacts,
        string memory productCode,
        string memory amount,
        string memory sctime
        ){
            require(getData[_id].id==_id,"ID does not exist");
            Waste storage waste = getData[_id];

            WasteId =waste.id;
            componentsID=waste.initData["componentsId"];
            goodsName=waste.initData["goodsName"];
            dangerNum=waste.initData["dangerNum"];
            producePlace=waste.initData["producePlace"];
            contacts=waste.initData["contacts"];
            productCode=waste.initData["productCode"];
            amount=waste.initData["amount"];
            sctime=waste.initData["sctime"];

    }

    function getInitOut(uint _id)public view returns (
        uint WasteId,
        string memory outTime
        ){
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].wIn,"The product has not yet entered the warehouse");
            Waste storage waste = getData[_id];

            WasteId =waste.id;
            outTime =waste.initData["outTime"];

    }

    function getWarehouseDataIn(uint _id)public view returns (
        uint WasteId,
        string memory importTime,
        string memory amount,
        string memory operateperson
        ){
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].wIn,"The product has not yet entered the warehouse");
            Waste storage waste = getData[_id];

            WasteId =waste.id;
            importTime = waste.wDataIn["importTime"];
            amount = waste.wDataIn["amount"];
            operateperson = waste.wDataIn["operateperson"];

    }
    
    function getWarehouseDataOut(uint _id)public view returns (
        uint WasteId,
        string memory outTime,
        string memory operateperson
        ){
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].wOut,"The product has not left the warehouse");
            Waste storage waste = getData[_id];

            WasteId =waste.id;
            outTime = waste.wDataOut["outTime"];
            operateperson = waste.wDataOut["operateperson"];

    }
    
    function getCompanyDataIn(uint _id)public view returns (
        uint WasteId,
        string memory customerid,
        string memory salePrice,
        string memory importTime,
        string memory amount,
        string memory operateperson
        ){
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].cIn,"The product has not yet entered the warehouse");
            Waste storage waste = getData[_id];

            WasteId =waste.id;
            customerid = waste.cDataIn["customerid"];
            salePrice = waste.cDataIn["salePrice"];
            importTime = waste.cDataIn["importTime"];
            amount = waste.cDataIn["amount"];
            operateperson =waste.cDataIn["operateperson"];

    }
    
    function getCompanyDataOut(uint _id)public view returns (
        uint WasteId,
        string memory OutTime,
        string memory operateperson
        ){
            require(getData[_id].id==_id,"ID does not exist");
            // require(getData[_id].cOut,"The product has not left the warehouse");
            Waste storage waste = getData[_id];

            WasteId =waste.id;
            OutTime = waste.cDataOut["OutTime"];
            operateperson = waste.cDataOut["operateperson"];

    }












}