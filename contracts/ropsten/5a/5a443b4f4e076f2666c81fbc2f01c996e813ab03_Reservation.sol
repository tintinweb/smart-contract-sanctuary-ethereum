/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// File: contracts/lib/security/Pausable.sol
//SPDX-License-Identifier: NOLICENSE


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
        require(pause, "Contract already unpaused");
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
        require(newOwner != address(0x000), "Zero address");
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

// File: contracts/reservation/SignatureValidator.sol


pragma solidity 0.8.14;


contract SignatureValidator is Pausable, Owner {
    address public signer;
    mapping(bytes32 => bool) public usedHash;
    mapping(address => uint256) public nonce;

    event Signer(address newSigner);

    function verfiySignature(
        address user,
        uint256 island,
        bytes32 assestHash,
        uint256 quantity,
        bytes memory signature
    ) internal returns (bool) {
        bytes32 msgDigest = getHashDigest(
            user,
            nonce[user],
            island,
            assestHash,
            quantity
        );
        require(!usedHash[msgDigest], "Invalid Hash");
        require(
            recoverSigner(msgDigest, signature) == signer,
            "Signature incorrect"
        );
        usedHash[msgDigest] = true;
        return true;
    }

    function verfiySignatureView(
        address user,
        uint256 island,
        bytes32 assestHash,
        uint256 quantity,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 msgDigest = getHashDigest(
            user,
            nonce[user],
            island,
            assestHash,
            quantity
        );
        require(!usedHash[msgDigest], "Invalid Hash");
        require(
            recoverSigner(msgDigest, signature) == signer,
            "Signature incorrect"
        );
        return true;
    }

    function getHashDigest(
        address receiver,
        uint256 userNonce,
        uint256 island,
        bytes32 assestHash,
        uint256 quantity
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    abi.encodePacked(address(this), receiver, userNonce),
                    island,
                    assestHash,
                    quantity
                )
            );
    }

    function recoverSigner(bytes32 msghash, bytes memory signature)
        public
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        return ecrecover(msghash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
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

// File: contracts/megaLandDataProvider/IMegaLandDataProvider.sol

pragma solidity 0.8.14;

interface IMegaLandDataProvider{ 

    function getLandPrice() external view returns(uint);
    function getEstatePrice() external view returns(uint);
    function getHomesteadPrice() external view returns(uint);
    function getUnitAssestPrice(bytes32 unitNameHash) external view returns(uint);
    function getPrice(bytes32 unitHash) external view returns(uint);
    function isAssestExist(bytes32 unitNameHash) external view returns(bool);
    function getComptroller() external view returns(address);

    function LAND() external view returns(address); 

}

// File: contracts/megaLandDataProvider/Types.sol

pragma solidity 0.8.14;

library Types{
  
    enum Assest{land, homestead, estate, unitassest}

    enum Island{MATIC, SOL, MEGA, BTC, ETH, BNB, ADA, AVAX, DOT, DOGE, FIL, LTC, 
    UNI, XRP, EGLD, XMR, XLM, TRX, LINK, SHIB, ALGO, VET, ATOM}

    enum Parcel{Any, Land, Homestead, Estate}

}

// File: contracts/reservation/ReservationCore.sol

pragma solidity 0.8.14;



contract ReservationCore is SignatureValidator {
    IMegaLandDataProvider public dataProvider;

    address public paymentReceiver;
    // Referral Fee in %
    uint256 public referralFee;
    // Referee Fee in %
    uint256 public refereeFee;
    // Total white listed user
    address[] public totaluser;

    // Sale active status
    bool public active;

    struct User {
        bool reserved;
        address referral;
        // Map Island with reserved assest
        mapping(Types.Island => mapping(bytes32 => uint256)) reservedAssestQuantityByIsland;
        // Total reserved assest details
        bytes32[] totalassest;
        mapping(Types.Island => bool) isReservedIsland;
        // Total reserved Islands
        Types.Island[] totalIsland;
        mapping(bytes32 => uint256) reservedQuantity;
    }

    // Reserved users info
    mapping(address => User) public userInfo;

    // Event details
    event Reserved(
        address user,
        Types.Island island,
        bytes32 unitHash,
        uint256 quantity
    );
    event SetReferral(address user, address referral);

    modifier ifSaleInActive() {
        require(!active, "Reservation is not active");
        _;
    }

    modifier ifNotContract(address ref) {
        require(
            (isContract(ref) == false) && (isContract(msg.sender) == false),
            "Invalid address"
        );
        require(ref != msg.sender, "Referral and caller are identical address");
        _;
    }

    function _reserve(
        Types.Island _island,
        bytes32 _unitHash,
        address _user,
        uint256 _amount,
        uint256 quantity,
        address _referral,
        uint256 _referralCut
    ) internal ifNotPaused ifNotContract(_referral) {
        require(_island <= Types.Island.ATOM, "Invalid Island");

        // verfiySignature(
        //     _user,
        //     uint256(_island),
        //     _unitHash,
        //     quantity,
        //     _signature
        // );
        // nonce[_user] += 1;

        if (_referral != address(0x00)) {
            // transfer eth
            if (_referralCut > 0) {
                payable(_referral).transfer(_referralCut);
                _amount -= _referralCut;
            }
            payable(paymentReceiver).transfer(_amount);
        } else {
            // if the  referral is zero address transfer all ETH to the owner
            payable(paymentReceiver).transfer(_amount);
        }

        if (!userInfo[_user].reserved) {
            userInfo[_user].reserved = true;
            totaluser.push(_user);
        }

        if (userInfo[_user].reservedAssestQuantityByIsland[_island][_unitHash] == 0) {
            userInfo[_user].totalassest.push(_unitHash);
        }
        if (userInfo[_user].isReservedIsland[_island] == false) {
            userInfo[_user].isReservedIsland[_island] = true;
            userInfo[_user].totalIsland.push(_island);
        }
        userInfo[_user].reservedAssestQuantityByIsland[_island][_unitHash] += quantity;
        userInfo[_user].reservedQuantity[_unitHash] += quantity;
        emit Reserved(_user, _island, _unitHash, quantity);
    }

    function _setReferral(address _user, address _ref) internal {
        if (
            (userInfo[_user].referral == address(0x00)) &&
            (_ref != address(0x00))
        ) {
            userInfo[_user].referral = _ref;
            emit SetReferral(_user, _ref);
        }
    }

    function getTotalPrice(
        bytes32 unitHash,
        uint256 quantity,
        address user
    ) public view returns (uint256 amount, uint256 referralCut) {
        amount = (quantity * dataProvider.getPrice(unitHash));
        if (userInfo[user].referral == address(0x00)) {
            return (amount, referralCut);
        } else {
            referralCut = ((amount * referralFee) / 100);
            amount -= ((amount * refereeFee) / 100);
            return (amount, referralCut);
        }
    }

    // Access restriction function
    function setSaleStatus(bool status) external onlyOwner {
        require(status == active, "");
        active = status;
    }

    function setFeePercantage(
        uint256 _referalPercantage,
        uint256 _refereePercantage
    ) external onlyOwner {
        referralFee = _referalPercantage;
        refereeFee = _refereePercantage;
    }

    function pauseContract() external onlyOwner {
        _pauseContract();
    }

    function unPauseContract() external onlyOwner {
        _unPauseContract();
    }

    function setDataProviderAddress(address newdataProvider)
        external
        onlyOwner
    {
        dataProvider = IMegaLandDataProvider(newdataProvider);
    }

    function setpaymentReceiver(address newPaymentReceiver) external onlyOwner {
        paymentReceiver = newPaymentReceiver;
    }

    function setSigner(address newsigner) external onlyOwner {
        signer = newsigner;
        emit Signer(newsigner);
    }

    // Read method
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _isReserved(address user) internal view {
        require(userInfo[user].reserved, "Not reserved yet");
    }
    
}

// File: contracts/reservation/Reservation.sol

pragma solidity 0.8.14;

contract Reservation is ReservationCore {
    
    bool public initialized;
    address public initializer;

    constructor() {
        initializer = msg.sender;
    }

    function initialize(
        address owner_,
        address signer_,
        address paymentReceiver_
    ) external {
        require((!initialized && (msg.sender == initializer)), "Initialized");
        require(
            (owner_ != address(0x00)) &&
                (signer_ != address(0x00)) &&
                (paymentReceiver_ != address(0x00)),
            "Zero address"
        );

        initialized = true;
        _owner = owner_;

        referralFee = 5;
        refereeFee = 5;

        signer = signer_;
        paymentReceiver = paymentReceiver_;
        emit Signer(signer_);
    }

    function reserve(
        Types.Island island,
        bytes32 assestnameHash,
        uint256 quantity,
        address referral
    ) external payable {
        require(
            dataProvider.isAssestExist(assestnameHash),
            "Assest not for sale"
        );
        address user = msg.sender;
        uint256 amount;
        uint256 referralCut;

        _setReferral(user, referral);

        referral = userInfo[user].referral;

        (amount, referralCut) = getTotalPrice(
            assestnameHash,
            quantity,
            user
        );
        uint256 msgValue = msg.value;
        require(msgValue >= amount, "Insufficient amount");

        _reserve(
            island,
            assestnameHash,
            user,
            amount,
            quantity,
            referral,
            referralCut
        );

        if (msgValue > amount) {
            payable(user).transfer(msgValue - amount);
        }
    }

    function setReferral(address _ref)
        external
        ifNotPaused
        ifSaleInActive
        ifNotContract(_ref)
    {
        address _user = msg.sender;
        require((userInfo[_user].reserved), "Only reserved users");
        _setReferral(_user, _ref);
    }

    function getTotalUser() external view returns (address[] memory) {
        return totaluser;
    }

    function getTotalUserLength() external view returns (uint256) {
        return totaluser.length;
    }

    function getUserInfo(address user)
        external
        view
        returns (
            bool isreserved,
            address referral,
            Types.Island[] memory totalIsland,
            bytes32[] memory totalassest
        )
    {
        return (
            userInfo[user].reserved,
            userInfo[user].referral,
            userInfo[user].totalIsland,
            userInfo[user].totalassest
        );
    }

    function getReservedAssestQuantityByIsland(
        address user,
        Types.Island island,
        bytes32 assestHash
    ) external view returns (uint256) {
        _isReserved(user);
        return userInfo[user].reservedAssestQuantityByIsland[island][assestHash];
    }

    function getReservedQuantity(
        address user,
        bytes32 assestHash
    ) external view returns (uint256) {
        _isReserved(user);
        return userInfo[user].reservedQuantity[assestHash];
    }

    function isReserved(address user) external view returns (bool) {
        return userInfo[user].reserved;
    }

    function getRefferal(address user) external view returns (address) {
        return userInfo[user].referral;
    }
}