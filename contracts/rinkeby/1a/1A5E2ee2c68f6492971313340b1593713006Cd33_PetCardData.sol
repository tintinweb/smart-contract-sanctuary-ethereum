/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

/**
 *Submitted for verification at Etherscan.io on 2018-01-22
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

contract IPetCardData is AccessControl, Enums {
    uint8 public totalPetCardSeries;
    uint64 public totalPets;

    // write
    function createPetCardSeries(uint8 _petCardSeriesId, uint32 _maxTotal)
        public
        onlyCREATOR
        returns (uint8);

    function setPet(
        uint8 _petCardSeriesId,
        address _owner,
        string _name,
        uint8 _luck,
        uint16 _auraRed,
        uint16 _auraYellow,
        uint16 _auraBlue
    ) external onlySERAPHIM returns (uint64);

    function setPetAuras(
        uint64 _petId,
        uint8 _auraRed,
        uint8 _auraBlue,
        uint8 _auraYellow
    ) external onlySERAPHIM;

    function setPetLastTrainingTime(uint64 _petId) external onlySERAPHIM;

    function setPetLastBreedingTime(uint64 _petId) external onlySERAPHIM;

    function addPetIdMapping(address _owner, uint64 _petId) private;

    function transferPet(
        address _from,
        address _to,
        uint64 _petId
    ) public onlySERAPHIM returns (ResultCode);

    function ownerPetTransfer(address _to, uint64 _petId) public;

    function setPetName(string _name, uint64 _petId) public;

    // read
    function getPetCardSeries(uint8 _petCardSeriesId)
        public
        constant
        returns (
            uint8 petCardSeriesId,
            uint32 currentPetTotal,
            uint32 maxPetTotal
        );

    function getPet(uint256 _petId)
        public
        constant
        returns (
            uint256 petId,
            uint8 petCardSeriesId,
            string name,
            uint8 luck,
            uint16 auraRed,
            uint16 auraBlue,
            uint16 auraYellow,
            uint64 lastTrainingTime,
            uint64 lastBreedingTime,
            address owner
        );

    function getOwnerPetCount(address _owner) public constant returns (uint256);

    function getPetByIndex(address _owner, uint256 _index)
        public
        constant
        returns (uint256);

    function getTotalPetCardSeries() public constant returns (uint8);

    function getTotalPets() public constant returns (uint256);
}

contract PetCardData is IPetCardData, SafeMath {
    /*** EVENTS ***/
    event CreatedPet(uint64 petId);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /*** DATA TYPES ***/
    struct PetCardSeries {
        uint8 petCardSeriesId;
        uint32 currentPetTotal;
        uint32 maxPetTotal;
    }

    struct Pet {
        uint64 petId;
        uint8 petCardSeriesId;
        address owner;
        string name;
        uint8 luck;
        uint16 auraRed;
        uint16 auraYellow;
        uint16 auraBlue;
        uint64 lastTrainingTime;
        uint64 lastBreedingTime;
        uint256 price;
    }

    /*** STORAGE ***/

    mapping(uint8 => PetCardSeries) public petCardSeriesCollection;
    mapping(uint256 => Pet) public petCollection;
    mapping(address => uint64[]) public ownerPetCollection;

    /*** FUNCTIONS ***/
    //*** Write Access ***//
    function PetCardData() public {}

    function init() public {
        PetCardSeries storage series = petCardSeriesCollection[1];

        series.petCardSeriesId = 1;
        series.maxPetTotal = 50000;
        series.currentPetTotal = 270;

        PetCardSeries storage series2 = petCardSeriesCollection[2];
        series2.petCardSeriesId = 2;
        series2.maxPetTotal = 500;
        series2.currentPetTotal = 500;

        PetCardSeries storage series3 = petCardSeriesCollection[3];
        series3.petCardSeriesId = 3;
        series3.maxPetTotal = 500;
        series3.currentPetTotal = 235;

        PetCardSeries storage series4 = petCardSeriesCollection[4];
        series4.petCardSeriesId = 4;
        series4.maxPetTotal = 500;
        series4.currentPetTotal = 187;

        PetCardSeries storage series5 = petCardSeriesCollection[5];
        series5.petCardSeriesId = 5;
        series5.maxPetTotal = 10000;
        series5.currentPetTotal = 234;

        PetCardSeries storage series6 = petCardSeriesCollection[6];
        series6.petCardSeriesId = 6;
        series6.maxPetTotal = 10000;
        series6.currentPetTotal = 240;

        PetCardSeries storage series7 = petCardSeriesCollection[7];
        series7.petCardSeriesId = 7;
        series7.maxPetTotal = 10000;
        series7.currentPetTotal = 227;

        PetCardSeries storage series8 = petCardSeriesCollection[8];
        series8.petCardSeriesId = 8;
        series8.maxPetTotal = 10000;
        series8.currentPetTotal = 188;

        PetCardSeries storage series9 = petCardSeriesCollection[9];
        series9.petCardSeriesId = 9;
        series9.maxPetTotal = 10000;
        series9.currentPetTotal = 451;
    }

    function init2() public {
        PetCardSeries storage series1 = petCardSeriesCollection[10];
        series1.petCardSeriesId = 10;
        series1.maxPetTotal = 10000;
        series1.currentPetTotal = 170;

        PetCardSeries storage series2 = petCardSeriesCollection[11];
        series2.petCardSeriesId = 11;
        series2.maxPetTotal = 10000;
        series2.currentPetTotal = 151;

        PetCardSeries storage series3 = petCardSeriesCollection[12];
        series3.petCardSeriesId = 12;
        series3.maxPetTotal = 10000;
        series3.currentPetTotal = 174;

        PetCardSeries storage series4 = petCardSeriesCollection[13];
        series4.petCardSeriesId = 13;
        series4.maxPetTotal = 10000;
        series4.currentPetTotal = 32;

        PetCardSeries storage series5 = petCardSeriesCollection[14];
        series5.petCardSeriesId = 14;
        series5.maxPetTotal = 10000;
        series5.currentPetTotal = 25;

        PetCardSeries storage series6 = petCardSeriesCollection[15];
        series6.petCardSeriesId = 15;
        series6.maxPetTotal = 10000;
        series6.currentPetTotal = 43;

        PetCardSeries storage series7 = petCardSeriesCollection[16];
        series7.petCardSeriesId = 16;
        series7.maxPetTotal = 10000;
        series7.currentPetTotal = 32;

        PetCardSeries storage series8 = petCardSeriesCollection[17];
        series8.petCardSeriesId = 17;
        series8.maxPetTotal = 10000;
        series8.currentPetTotal = 1;

        PetCardSeries storage series9 = petCardSeriesCollection[18];
        series9.petCardSeriesId = 18;
        series9.maxPetTotal = 10000;
        series9.currentPetTotal = 0;

        PetCardSeries storage series10 = petCardSeriesCollection[19];
        series10.petCardSeriesId = 19;
        series10.maxPetTotal = 10000;
        series10.currentPetTotal = 0;
    }

    //*** Pets ***/
    function createPetCardSeries(uint8 _petCardSeriesId, uint32 _maxTotal)
        public
        onlyCREATOR
        returns (uint8)
    {
        if ((now > 1516642200) || (totalPetCardSeries >= 19)) {
            revert();
        }
        //This confirms that no one, even the develoopers, can create any angel series after JAN/22/2018 @ 0530pm (UTC) or more than the original 24 series.

        PetCardSeries storage petCardSeries = petCardSeriesCollection[
            _petCardSeriesId
        ];
        petCardSeries.petCardSeriesId = _petCardSeriesId;
        petCardSeries.maxPetTotal = _maxTotal;
        totalPetCardSeries += 1;
        return totalPetCardSeries;
    }

    function setPet(
        uint8 _petCardSeriesId,
        address _owner,
        string _name,
        uint8 _luck,
        uint16 _auraRed,
        uint16 _auraYellow,
        uint16 _auraBlue
    ) external onlySERAPHIM returns (uint64) {
        PetCardSeries storage series = petCardSeriesCollection[
            _petCardSeriesId
        ];

        if (series.currentPetTotal >= series.maxPetTotal) {
            revert();
        } else {
            totalPets += 1;
            series.currentPetTotal += 1;
            Pet storage pet = petCollection[totalPets];
            pet.petId = totalPets;
            pet.petCardSeriesId = _petCardSeriesId;
            pet.owner = _owner;
            pet.name = _name;
            pet.luck = _luck;
            pet.auraRed = _auraRed;
            pet.auraYellow = _auraYellow;
            pet.auraBlue = _auraBlue;
            pet.lastTrainingTime = 0;
            pet.lastBreedingTime = 0;
            addPetIdMapping(_owner, pet.petId);
        }
    }

    function setPetAuras(
        uint64 _petId,
        uint8 _auraRed,
        uint8 _auraBlue,
        uint8 _auraYellow
    ) external onlySERAPHIM {
        Pet storage pet = petCollection[_petId];
        if (pet.petId == _petId) {
            pet.auraRed = _auraRed;
            pet.auraBlue = _auraBlue;
            pet.auraYellow = _auraYellow;
        }
    }

    function setPetName(string _name, uint64 _petId) public {
        Pet storage pet = petCollection[_petId];
        if ((pet.petId == _petId) && (msg.sender == pet.owner)) {
            pet.name = _name;
        }
    }

    function setPetLastTrainingTime(uint64 _petId) external onlySERAPHIM {
        Pet storage pet = petCollection[_petId];
        if (pet.petId == _petId) {
            pet.lastTrainingTime = uint64(now);
        }
    }

    function setPetLastBreedingTime(uint64 _petId) external onlySERAPHIM {
        Pet storage pet = petCollection[_petId];
        if (pet.petId == _petId) {
            pet.lastBreedingTime = uint64(now);
        }
    }

    function addPetIdMapping(address _owner, uint64 _petId) private {
        uint64[] storage owners = ownerPetCollection[_owner];
        owners.push(_petId);
        Pet storage pet = petCollection[_petId];
        pet.owner = _owner;
        //this is a map of ALL the pets an address has EVER owned.
        //We check that they are still the current owner in javascrpit and other places on chain.
    }

    function transferPet(
        address _from,
        address _to,
        uint64 _petId
    ) public onlySERAPHIM returns (ResultCode) {
        Pet storage pet = petCollection[_petId];
        if (pet.owner != _from) {
            return ResultCode.ERROR_NOT_OWNER;
        }
        if (_from == _to) {
            revert();
        }
        addPetIdMapping(_to, _petId);
        pet.owner = _to;
        return ResultCode.SUCCESS;
    }

    //Anyone can transfer a pet they own by calling this function.

    function ownerPetTransfer(address _to, uint64 _petId) public {
        if ((_petId > totalPets) || (_petId == 0)) {
            revert();
        }
        if (msg.sender == _to) {
            revert();
        } //can't send to yourself.
        if (pet.owner != msg.sender) {
            revert();
        } else {
            Pet storage pet = petCollection[_petId];
            pet.owner = _to;
            addPetIdMapping(_to, _petId);
        }
    }

    //*** Read Access ***//
    function getPetCardSeries(uint8 _petCardSeriesId)
        public
        constant
        returns (
            uint8 petCardSeriesId,
            uint32 currentPetTotal,
            uint32 maxPetTotal
        )
    {
        PetCardSeries memory series = petCardSeriesCollection[_petCardSeriesId];
        petCardSeriesId = series.petCardSeriesId;
        currentPetTotal = series.currentPetTotal;
        maxPetTotal = series.maxPetTotal;
    }

    function getPet(uint256 _petId)
        public
        constant
        returns (
            uint256 petId,
            uint8 petCardSeriesId,
            string name,
            uint8 luck,
            uint16 auraRed,
            uint16 auraBlue,
            uint16 auraYellow,
            uint64 lastTrainingTime,
            uint64 lastBreedingTime,
            address owner
        )
    {
        Pet memory pet = petCollection[_petId];
        petId = pet.petId;
        petCardSeriesId = pet.petCardSeriesId;
        name = pet.name;
        luck = pet.luck;
        auraRed = pet.auraRed;
        auraBlue = pet.auraBlue;
        auraYellow = pet.auraYellow;
        lastTrainingTime = pet.lastTrainingTime;
        lastBreedingTime = pet.lastBreedingTime;
        owner = pet.owner;
    }

    function getOwnerPetCount(address _owner)
        public
        constant
        returns (uint256)
    {
        return ownerPetCollection[_owner].length;
    }

    function getPetByIndex(address _owner, uint256 _index)
        public
        constant
        returns (uint256)
    {
        if (_index >= ownerPetCollection[_owner].length) return 0;
        return ownerPetCollection[_owner][_index];
    }

    function getTotalPetCardSeries() public constant returns (uint8) {
        return totalPetCardSeries;
    }

    function getTotalPets() public constant returns (uint256) {
        return totalPets;
    }
}