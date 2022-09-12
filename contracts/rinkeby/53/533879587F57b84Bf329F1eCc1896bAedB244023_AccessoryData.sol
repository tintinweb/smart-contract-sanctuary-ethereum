/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/**
 *Submitted for verification at Etherscan.io on 2018-01-29
 */

pragma solidity ^0.4.17;

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        assert((x == 0) || (z / x == y));
        return z;
    }

    function getRandomNumber(
        uint16 maxRandom,
        uint8 min,
        address privateAddress
    ) public constant returns (uint8) {
        uint256 genNum = uint256(block.blockhash(block.number - 1)) +
            uint256(privateAddress);
        return uint8((genNum % (maxRandom - min + 1)) + min);
    }
}

contract Enums {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_OWNER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum AngelAura {
        Blue,
        Yellow,
        Purple,
        Orange,
        Red,
        Green
    }
}

contract AccessControl {
    address public creatorAddress;
    uint16 public totalSeraphims = 0;
    mapping(address => bool) public seraphims;

    bool public isMaintenanceMode = true;

    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress);
        _;
    }

    modifier onlySERAPHIM() {
        require(seraphims[msg.sender] == true);
        _;
    }

    modifier isContractActive() {
        require(!isMaintenanceMode);
        _;
    }

    // Constructor
    function AccessControl() public {
        creatorAddress = msg.sender;
    }

    function addSERAPHIM(address _newSeraphim) public onlyCREATOR {
        if (seraphims[_newSeraphim] == false) {
            seraphims[_newSeraphim] = true;
            totalSeraphims += 1;
        }
    }

    function removeSERAPHIM(address _oldSeraphim) public onlyCREATOR {
        if (seraphims[_oldSeraphim] == true) {
            seraphims[_oldSeraphim] = false;
            totalSeraphims -= 1;
        }
    }

    function updateMaintenanceMode(bool _isMaintaining) public onlyCREATOR {
        isMaintenanceMode = _isMaintaining;
    }
}

contract IAccessoryData is AccessControl, Enums {
    uint8 public totalAccessorySeries;
    uint32 public totalAccessories;

    /*** FUNCTIONS ***/
    //*** Write Access ***//
    function createAccessorySeries(
        uint8 _AccessorySeriesId,
        uint32 _maxTotal,
        uint256 _price
    ) public onlyCREATOR returns (uint8);

    function setAccessory(uint8 _AccessorySeriesId, address _owner)
        external
        onlySERAPHIM
        returns (uint64);

    function addAccessoryIdMapping(address _owner, uint64 _accessoryId) private;

    function transferAccessory(
        address _from,
        address _to,
        uint64 __accessoryId
    ) public onlySERAPHIM returns (ResultCode);

    function ownerAccessoryTransfer(address _to, uint64 __accessoryId) public;

    function updateAccessoryLock(uint64 _accessoryId, bool newValue) public;

    function removeCreator() external onlyCREATOR;

    //*** Read Access ***//
    function getAccessorySeries(uint8 _accessorySeriesId)
        public
        constant
        returns (
            uint8 accessorySeriesId,
            uint32 currentTotal,
            uint32 maxTotal,
            uint256 price
        );

    function getAccessory(uint256 _accessoryId)
        public
        constant
        returns (
            uint256 accessoryID,
            uint8 AccessorySeriesID,
            address owner
        );

    function getOwnerAccessoryCount(address _owner)
        public
        constant
        returns (uint256);

    function getAccessoryByIndex(address _owner, uint256 _index)
        public
        constant
        returns (uint256);

    function getTotalAccessorySeries() public constant returns (uint8);

    function getTotalAccessories() public constant returns (uint256);

    function getAccessoryLockStatus(uint64 _acessoryId)
        public
        constant
        returns (bool);
}

contract AccessoryData is IAccessoryData, SafeMath {
    /*** EVENTS ***/
    event CreatedAccessory(uint64 accessoryId);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /*** DATA TYPES ***/
    struct AccessorySeries {
        uint8 AccessorySeriesId;
        uint32 currentTotal;
        uint32 maxTotal;
        uint256 price;
    }

    struct Accessory {
        uint32 accessoryId;
        uint8 accessorySeriesId;
        address owner;
        bool ownerLock;
    }

    /*** STORAGE ***/
    mapping(uint8 => AccessorySeries) public AccessorySeriesCollection;
    mapping(uint256 => Accessory) public AccessoryCollection;
    mapping(address => uint64[]) public ownerAccessoryCollection;

    /*** FUNCTIONS ***/
    //*** Write Access ***//
    function AccessoryData() public {}

    function init() public {
        //This confirms that no one, even the develoopers, can create any accessorySeries after JAN/29/2018 @ 1:26 am (UTC) or more than the original 18 series.
        AccessorySeries storage series = AccessorySeriesCollection[1];
        series.AccessorySeriesId = 1;
        series.maxTotal = 200;
        series.currentTotal = 34;

        AccessorySeries storage series2 = AccessorySeriesCollection[2];
        series2.AccessorySeriesId = 2;
        series2.maxTotal = 200;
        series2.currentTotal = 12;

        AccessorySeries storage series3 = AccessorySeriesCollection[3];
        series3.AccessorySeriesId = 3;
        series3.maxTotal = 200;
        series3.currentTotal = 13;

        AccessorySeries storage series4 = AccessorySeriesCollection[4];
        series4.AccessorySeriesId = 4;
        series4.maxTotal = 200;
        series4.currentTotal = 26;

        AccessorySeries storage series5 = AccessorySeriesCollection[5];
        series5.AccessorySeriesId = 5;
        series5.maxTotal = 200;
        series5.currentTotal = 0;

        AccessorySeries storage series6 = AccessorySeriesCollection[6];
        series6.AccessorySeriesId = 6;
        series6.maxTotal = 200;
        series6.currentTotal = 1;
    }

    function init2() public {
        AccessorySeries storage series7 = AccessorySeriesCollection[7];
        series7.AccessorySeriesId = 7;
        series7.maxTotal = 200;
        series7.currentTotal = 0;

        AccessorySeries storage series8 = AccessorySeriesCollection[8];
        series8.AccessorySeriesId = 8;
        series8.maxTotal = 200;
        series8.currentTotal = 0;

        AccessorySeries storage series9 = AccessorySeriesCollection[9];
        series9.AccessorySeriesId = 9;
        series9.maxTotal = 200;
        series9.currentTotal = 1;

        AccessorySeries storage series10 = AccessorySeriesCollection[10];
        series10.AccessorySeriesId = 10;
        series10.maxTotal = 200;
        series10.currentTotal = 0;

        AccessorySeries storage series11 = AccessorySeriesCollection[11];
        series11.AccessorySeriesId = 11;
        series11.maxTotal = 200;
        series11.currentTotal = 0;

        AccessorySeries storage series12 = AccessorySeriesCollection[12];
        series12.AccessorySeriesId = 12;
        series12.maxTotal = 200;
        series12.currentTotal = 2;

        AccessorySeries storage series13 = AccessorySeriesCollection[13];
        series13.AccessorySeriesId = 13;
        series13.maxTotal = 200;
        series13.currentTotal = 1;

        AccessorySeries storage series14 = AccessorySeriesCollection[14];
        series14.AccessorySeriesId = 14;
        series14.maxTotal = 200;
        series14.currentTotal = 1;

        AccessorySeries storage series15 = AccessorySeriesCollection[15];
        series15.AccessorySeriesId = 15;
        series15.maxTotal = 200;
        series15.currentTotal = 1;

        AccessorySeries storage series16 = AccessorySeriesCollection[16];
        series16.AccessorySeriesId = 16;
        series16.maxTotal = 200;
        series16.currentTotal = 1;

        AccessorySeries storage series17 = AccessorySeriesCollection[17];
        series17.AccessorySeriesId = 17;
        series17.maxTotal = 200;
        series17.currentTotal = 3;

        AccessorySeries storage series18 = AccessorySeriesCollection[18];
        series18.AccessorySeriesId = 18;
        series18.maxTotal = 200;
        series18.currentTotal = 0;
    }

    //*** Accessories***/
    function createAccessorySeries(
        uint8 _AccessorySeriesId,
        uint32 _maxTotal,
        uint256 _price
    ) public onlyCREATOR returns (uint8) {
        if ((now > 1517189201) || (totalAccessorySeries >= 18)) {
            revert();
        }
        //This confirms that no one, even the develoopers, can create any accessorySeries after JAN/29/2018 @ 1:26 am (UTC) or more than the original 18 series.
        AccessorySeries storage accessorySeries = AccessorySeriesCollection[
            _AccessorySeriesId
        ];
        accessorySeries.AccessorySeriesId = _AccessorySeriesId;
        accessorySeries.maxTotal = _maxTotal;
        accessorySeries.price = _price;

        totalAccessorySeries += 1;
        return totalAccessorySeries;
    }

    function setAccessory(uint8 _seriesIDtoCreate, address _owner)
        external
        onlySERAPHIM
        returns (uint64)
    {
        AccessorySeries storage series = AccessorySeriesCollection[
            _seriesIDtoCreate
        ];
        if (series.maxTotal <= series.currentTotal) {
            revert();
        } else {
            totalAccessories += 1;
            series.currentTotal += 1;
            Accessory storage accessory = AccessoryCollection[totalAccessories];
            accessory.accessoryId = totalAccessories;
            accessory.accessorySeriesId = _seriesIDtoCreate;
            accessory.owner = _owner;
            accessory.ownerLock = true;
            uint64[] storage owners = ownerAccessoryCollection[_owner];
            owners.push(accessory.accessoryId);
        }
    }

    function addAccessoryIdMapping(address _owner, uint64 _accessoryId)
        private
    {
        uint64[] storage owners = ownerAccessoryCollection[_owner];
        owners.push(_accessoryId);
        Accessory storage accessory = AccessoryCollection[_accessoryId];
        accessory.owner = _owner;
    }

    function transferAccessory(
        address _from,
        address _to,
        uint64 __accessoryId
    ) public onlySERAPHIM returns (ResultCode) {
        Accessory storage accessory = AccessoryCollection[__accessoryId];
        if (accessory.owner != _from) {
            return ResultCode.ERROR_NOT_OWNER;
        }
        if (_from == _to) {
            revert();
        }
        if (accessory.ownerLock == true) {
            revert();
        }
        addAccessoryIdMapping(_to, __accessoryId);
        return ResultCode.SUCCESS;
    }

    function ownerAccessoryTransfer(address _to, uint64 __accessoryId) public {
        //Any owner of an accessory can call this function to transfer their accessory to any other address.

        if ((__accessoryId > totalAccessories) || (__accessoryId == 0)) {
            revert();
        }
        Accessory storage accessory = AccessoryCollection[__accessoryId];
        if (msg.sender == _to) {
            revert();
        } //can't send an accessory to yourself
        if (accessory.owner != msg.sender) {
            revert();
        }
        //can't send an accessory you don't own.
        else {
            accessory.owner = _to;
            addAccessoryIdMapping(_to, __accessoryId);
        }
    }

    function updateAccessoryLock(uint64 _accessoryId, bool newValue) public {
        if ((_accessoryId > totalAccessories) || (_accessoryId == 0)) {
            revert();
        }
        Accessory storage accessory = AccessoryCollection[_accessoryId];
        if (accessory.owner != msg.sender) {
            revert();
        }
        accessory.ownerLock = newValue;
    }

    function removeCreator() external onlyCREATOR {
        //this function is meant to be called once all modules for the game are in place. It will remove our ability to add any new modules and make the game fully decentralized.
        creatorAddress = address(0);
    }

    //*** Read Access ***//
    function getAccessorySeries(uint8 _accessorySeriesId)
        public
        constant
        returns (
            uint8 accessorySeriesId,
            uint32 currentTotal,
            uint32 maxTotal,
            uint256 price
        )
    {
        AccessorySeries memory series = AccessorySeriesCollection[
            _accessorySeriesId
        ];
        accessorySeriesId = series.AccessorySeriesId;
        currentTotal = series.currentTotal;
        maxTotal = series.maxTotal;
        price = series.price;
    }

    function getAccessory(uint256 _accessoryId)
        public
        constant
        returns (
            uint256 accessoryID,
            uint8 AccessorySeriesID,
            address owner
        )
    {
        Accessory memory accessory = AccessoryCollection[_accessoryId];
        accessoryID = accessory.accessoryId;
        AccessorySeriesID = accessory.accessorySeriesId;
        owner = accessory.owner;
    }

    function getOwnerAccessoryCount(address _owner)
        public
        constant
        returns (uint256)
    {
        return ownerAccessoryCollection[_owner].length;
    }

    function getAccessoryByIndex(address _owner, uint256 _index)
        public
        constant
        returns (uint256)
    {
        if (_index >= ownerAccessoryCollection[_owner].length) return 0;
        return ownerAccessoryCollection[_owner][_index];
    }

    function getTotalAccessorySeries() public constant returns (uint8) {
        return totalAccessorySeries;
    }

    function getTotalAccessories() public constant returns (uint256) {
        return totalAccessories;
    }

    function getAccessoryLockStatus(uint64 _acessoryId)
        public
        constant
        returns (bool)
    {
        if ((_acessoryId > totalAccessories) || (_acessoryId == 0)) {
            revert();
        }
        Accessory storage accessory = AccessoryCollection[_acessoryId];
        return accessory.ownerLock;
    }
}