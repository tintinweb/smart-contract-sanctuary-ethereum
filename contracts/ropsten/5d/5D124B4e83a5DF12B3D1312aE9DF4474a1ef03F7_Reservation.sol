/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

//SPDX-License-Identifier: NOLICENSE

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

// File: contracts/lib/security/Pausable.sol

pragma solidity 0.8.14;


contract Pausable {

    // Contract pause
    bool public pause;

    //Event details
    event Paused();
    event UnPaused();

    modifier ifNotPaused() {
        require(!pause, "Contract paused");
        _;
    }

    modifier ifPaused() {
        require(pause, "Contract paused");
        _;
    }

    function _pauseContract() internal ifNotPaused {
        pause = true;
        emit Paused();
    }

    function _unPauseContract() internal ifPaused  {
        pause = false;
        emit UnPaused();
    }

}

// File: contracts/lib/access/Owner.sol


pragma solidity 0.8.14;

contract Owner {

    address internal _owner;

    event OwnerChanged(address oldOwner, address newOwner);

    /// @notice gives the current owner of this contract.
    /// @return the current owner of this contract.
    function getOwner() external view returns (address) {
        return _owner;
    }

    /// @notice change the owner to be `newOwner`.
    /// @param newOwner address of the new owner.
    function changeOwner(address newOwner) external {
        address owner = _owner;
        require(msg.sender == owner, "only owner can change owner");
        require(newOwner != owner, "it can be only changed to a new owner");
        emit OwnerChanged(owner, newOwner);
        _owner = newOwner;
    }

    modifier onlyOwner() {
        require (msg.sender == _owner, "only owner allowed");
        _;
    }

}

// File: contracts/reservation/SignatureChecker.sol


pragma solidity 0.8.14;


contract SignatureChecker is Pausable, Owner{

    address public signer;
    mapping(bytes32 => bool) public usedHash;

    // Signature valid time in blocknumber
    uint256 public expiryLimit;

    event Signer(address newSigner);

    function setSigner(address newsigner) external onlyOwner{
        signer = newsigner;
        emit Signer(newsigner);
    }

    function setExpiryLimit(uint newexpiryLimit) external onlyOwner{
        expiryLimit = newexpiryLimit;
    }

    function verfiySignature(address user, uint256 expiry, uint island, uint quantity, bytes memory signature)internal view{
        bytes32 msgDigest = getHashDigest(user, expiry, island, quantity);
        require(!usedHash[msgDigest], "Invalid Hash");   
        require(recoverSigner(msgDigest, signature) == signer, "Signature incorrect"); 
    }

    function getHashDigest(address receiver, uint256 expiry, uint island, uint quantity) public view returns(bytes32){
       return keccak256( 
            abi.encodePacked(   
            abi.encodePacked(   
                address(this),   
                receiver,   
                expiry                  
            ),island ,quantity)
        );   
         
    }

    function recoverSigner(bytes32 msghash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(msghash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }


}

// File: contracts/megaLandDataProvider/Types.sol

pragma solidity 0.8.14;

library Types{
  
    enum Assest{land, homestead, estate, unitassest}

    enum Island{MATIC, SOL, MEGA, BTC, ETH, BNB, ADA, AVAX, DOT, DOGE, FIL, LTC, 
    UNI, XRP, EGLD, XMR, XLM, TRX, LINK, SHIB, ALGO, VET, ATOM}

}

// File: contracts/megaLandDataProvider/MegaLandDataProvider.sol

pragma solidity 0.8.14;


interface IMegaLandDataProvider{ 

    function getLandPrice() external view returns(uint);
    function getEstatePrice() external view returns(uint);
    function getHomesteadPrice() external view returns(uint);
    function getUnitAssestPrice(bytes32 unitNameHash) external view returns(uint);
    function isUnitAssestExist(bytes32 unitNameHash) external view returns(bool);

}

contract MegaLandDataProvider is Owner, IMegaLandDataProvider{ 
  
    uint private price1X1;
    uint private price2X2;
    uint private price3X3;

    struct saleUnit{
        bool isSale;
        uint price;
    }

    mapping(bytes32 => saleUnit) public unitassetInfo;
    // total units 
    bytes32[] public totalUnitassest;

    function addUnits(bytes32[] calldata nameHash, uint[] memory unitPrice) external onlyOwner {
        require(nameHash.length == unitPrice.length, "Invalid array length");
        
        for(uint i=0; i<nameHash.length; i++){
            unitassetInfo[nameHash[i]].isSale = true;
            unitassetInfo[nameHash[i]].price = unitPrice[i];            
            totalUnitassest.push(nameHash[i]);
        }
    }

    function getLandPrice() external view returns(uint){
        return price1X1;
    }

    function getEstatePrice() external view returns(uint){
         return price3X3;
    }

    function getHomesteadPrice() external view returns(uint){
         return price2X2;
    }

    function getUnitAssestPrice(bytes32 unitNameHash) external view returns(uint){
        require(isUnitAssestExist(unitNameHash), "Not found");
        return unitassetInfo[unitNameHash].price;
    }

    function isUnitAssestExist(bytes32 unitNameHash) public view returns(bool){
       return unitassetInfo[unitNameHash].isSale;
    }

}

// File: contracts/reservation/ReservationCore.sol

pragma solidity 0.8.14;




contract ReservationCore is SignatureChecker{

    IMegaLandDataProvider public dataProvider;

    // Referral Fee in %
    uint256 public referralFee;
    // Referee Fee in %
    uint256 public refereeFee;
    // Total white listed user
    address[] public totaluser;

    // Sale active status
    bool public active;
  
    struct User{
        bool allow;
        address referral; 
        // Map Island with reserved assest    
        mapping(Types.Island => mapping(bytes32 => uint)) reservedAssestAmount;
        // Total reserved assest details
        bytes32[] totalassest;
    }

    // Reserved users info
    mapping(address => User) public userInfo;

    // Event details
    event Reserved(address user, bytes32 assestHash, uint quantity);
    event SetReferral(address user, address referral);

    modifier ifSaleNotActive() {
        require(!active, "Reservation is not active");
        _;
    }

    modifier ifNotContract(address ref) {
        require((isContract(ref) == false) && (isContract(msg.sender) == false), "Invalid address");
        require(ref != msg.sender, "Referral and caller are identical address");
        _;
    }  

    function setSaleStatus(bool status) external onlyOwner {
        active = status;
    }

    function setFeePcent(uint256 _referalPcent, uint256 _refereePcent)
        external
        onlyOwner
    {
        referralFee = _referalPcent;
        refereeFee = _refereePcent;
    }

    function _reserve(Types.Island _island, bytes32 _nameHash, address _user, uint _amount, uint quantity, address _referral, bytes memory _signature)
        internal
        ifNotPaused
        ifNotContract(_referral)
    {
        require(_island <= Types.Island.ATOM, "Invalid Island");

        verfiySignature(_user, (block.number + expiryLimit), _amount, quantity, _signature);

        if (_referral != address(0x00) && (referralFee > 0)) {
            // calculate referral fee and referee fee amount
            uint256 _referralFee = (_amount * referralFee) / 100;
            uint256 _refreeFee = (_amount * refereeFee) / 100;

            _amount -= (_referralFee + _refreeFee);

            // transfer eth 
            payable(_owner).transfer(_amount);
            payable(_referral).transfer(_referralFee);
            // store the referral address
            userInfo[_user].referral = _referral;
        } else {
            // if the  referral is zero address transfer all ETH to the owner
            payable(_owner).transfer(_amount);
        }

        if(!userInfo[_user].allow){
            userInfo[_user].allow = true;
            totaluser.push(_user);
        }

        if(userInfo[_user].reservedAssestAmount[_island][_nameHash] == 0){
            userInfo[_user].totalassest.push(_nameHash);
        }
        userInfo[_user].reservedAssestAmount[_island][_nameHash] += quantity;
        emit Reserved(_user, _nameHash, quantity);
    } 

    function _setReferral(address _user, address _ref) internal {
        if((userInfo[_user].referral == address(0x00))) {
            userInfo[_user].referral = _ref;
            emit SetReferral(_user, _ref);
        }
    }

    function pauseContract() external onlyOwner {
       _pauseContract();
    }

    function unPauseContract() external onlyOwner {
       _unPauseContract();
    }

    // Read method
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

}

// File: contracts/reservation/Reservation.sol

pragma solidity 0.8.14;

contract Reservation is ReservationCore {
    constructor(
        address owner_
    ) {
        require(owner_ != address(0x00), "Zero address");
        _owner = owner_;
    }

    function reserve(Types.Island island, uint quantity, address _referral, bytes memory signature)
        external
        payable
    {
        uint amount = (quantity * dataProvider.getLandPrice());
        uint msgValue = msg.value;
        require(msgValue >= amount, "Insufficient amount");

        _reserve(island, keccak256("LAND"), msg.sender, amount, quantity, _referral, signature);

        if(msgValue > amount){
            payable(msg.sender).transfer(msgValue - amount);
        }
    }

    function reserveEstate(Types.Island island, uint quantity, address _referral, bytes memory signature)
        external
        payable
    {
        uint amount = (quantity * dataProvider.getEstatePrice());
        uint msgValue = msg.value;
        require(msgValue >= amount, "Insufficient amount");

        _reserve(island, keccak256("ESTATE"), msg.sender, amount, quantity, _referral, signature);

        if(msgValue > amount){
            payable(msg.sender).transfer(msgValue - amount);
        }
    }

    function reserveHomeStead(Types.Island island, uint quantity, address _referral, bytes memory signature)
        external
        payable
    {
        uint amount = (quantity * dataProvider.getHomesteadPrice());
        uint msgValue = msg.value;
        require(msgValue >= amount, "Insufficient amount");

        _reserve(island, keccak256("HOMESTEAD"), msg.sender, amount, quantity, _referral, signature);

        if(msgValue > amount){
            payable(msg.sender).transfer(msgValue - amount);
        }
    }

    function reserveUnitAssest(Types.Island island, bytes32 nameHash, uint quantity, address _referral, bytes memory signature)
        external
        payable
    {
        uint amount = (quantity * dataProvider.getUnitAssestPrice(nameHash));
        uint msgValue = msg.value;
        require(msgValue >= amount, "Insufficient amount");

        require(dataProvider.isUnitAssestExist(nameHash), "Assest not for sale");

        _reserve(island, nameHash, msg.sender, amount, quantity, _referral, signature);

        if(msgValue > amount){
            payable(msg.sender).transfer(msgValue - amount);
        }
    }

    function setReferral(address _ref)
        external
        ifNotPaused
        ifSaleNotActive
        ifNotContract(_ref)
    {
        address _user = msg.sender;
        require((userInfo[_user].allow), "Only reserved users");
        _setReferral(_user, _ref);
    }   

    function getTotalUser() external view returns (address[] memory) {
        return totaluser;
    }

    function getTotalUserLength() external view returns (uint256) {
        return totaluser.length;
    }
}