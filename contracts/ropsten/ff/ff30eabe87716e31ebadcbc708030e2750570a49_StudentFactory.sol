pragma solidity ^0.4.23;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }

  /**
   * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
       }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint32 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint16 a, uint16 b) internal pure returns (uint16) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint16 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract StudentFactory is Ownable {
    using SafeMath for uint;

    struct Status {
        string studentId; // ?????????
        string majorId;// ????????????
        uint8 length;// ???????????????
        uint8 eduType;// ?????????????????????/???????????????/????????????/????????????
        uint8 eduForm;// ????????????????????????/???????????????
        uint8 level;// ??????(???/???/???/???)
        uint8 state;// ???????????????????????????????????????/?????????????????????/???????????????
        uint16 schoolId;// ????????????
        uint16 class;// ??????
        uint64 admissionDate;// ????????????
        uint64 departureDate;// ????????????
    }


    struct CET {
        string examNumber;//????????????
        uint64 time; //?????????
        uint32 listening;//??????
        uint32 reading;// ??????
        uint32 writing;//???????????????
    }

    CET[] CET4List; // ??????????????????
    CET[] CET6List; // ??????????????????
    mapping(uint => uint32) internal CET4IndexToId; // ?????????????????????id?????????
    mapping(uint => uint32) internal CET6IndexToId; // ?????????????????????id?????????

    mapping(uint32 => uint) internal idCET4Count; //id???????????????????????????
    mapping(uint32 => uint) internal idCET6Count; //id???????????????????????????

    mapping(uint32 => Status) public idToUndergraduate;// id????????????????????????
    mapping(uint32 => Status) public idToMaster;// id????????????????????????
    mapping(uint32 => Status) public idToDoctor;// id????????????????????????


    function addUndergraduate(uint32 _id, string _studentId, uint16 _schoolId, string _majorId, uint8 _length, uint8 _eduType, uint8 _eduForm, uint8 _level, uint8 _state, uint16 _class, uint64 _admissionDate, uint64 _departureDate)
    public onlyOwner {
        idToUndergraduate[_id] = Status(_studentId, _majorId, _length, _eduType, _eduForm, _level, _state, _schoolId, _class, _admissionDate, _departureDate);
    }

    function addMaster(uint32 _id, string _studentId, uint16 _schoolId, string _majorId, uint8 _length, uint8 _eduType, uint8 _eduForm, uint8 _level, uint8 _state, uint16 _class, uint64 _admissionDate, uint64 _departureDate)
    public onlyOwner {
        idToMaster[_id] = Status(_studentId, _majorId, _length, _eduType, _eduForm, _level, _state, _schoolId, _class, _admissionDate, _departureDate);
    }

    function addDoctor(uint32 _id, string _studentId, uint16 _schoolId, string _majorId, uint8 _length, uint8 _eduType, uint8 _eduForm, uint8 _level, uint8 _state, uint16 _class, uint64 _admissionDate, uint64 _departureDate)
    public onlyOwner {
        idToDoctor[_id] = Status(_studentId, _majorId, _length, _eduType, _eduForm, _level, _state, _schoolId, _class, _admissionDate, _departureDate);
    }

    // ???????????????????????????????????????
    function addCET4(uint32 _id, string _examNumber, uint32 _time, uint32 _listening, uint32 _reading, uint32 _writing) public onlyOwner {
        uint index = CET4List.push(CET(_examNumber, _time, _listening, _reading, _writing)) - 1;
        CET4IndexToId[index] = _id;
        idCET4Count[_id]++;
    }

    // ???????????????????????????????????????
    function addCET6(uint32 _id, string _examNumber, uint32 _time, uint32 _listening, uint32 _reading, uint32 _writing) public onlyOwner {
        uint index = CET6List.push(CET(_examNumber, _time, _listening, _reading, _writing)) - 1;
        CET4IndexToId[index] = _id;
        idCET4Count[_id]++;
    }

    // ?????????????????????????????????
    function getCET4ById(uint32 _id) view public returns (uint64[], uint32[], uint32[], uint32[]) {
        uint64[] memory timeList = new uint64[](idCET4Count[_id]);
        uint32[] memory listeningList = new uint32[](idCET4Count[_id]);
        uint32[] memory readingList = new uint32[](idCET4Count[_id]);
        uint32[] memory writingList = new uint32[](idCET4Count[_id]);
        uint counter = 0;
        for (uint i = 0; i < CET4List.length; i++) {
            if (CET4IndexToId[i] == _id) {
                timeList[counter] = CET4List[i].time;
                listeningList[counter] = CET4List[i].listening;
                readingList[counter] = CET4List[i].reading;
                writingList[counter] = CET4List[i].writing;
                counter++;
            }
        }
        return (timeList, listeningList, readingList, writingList);
    }

    // ?????????????????????????????????
    function getCET6ById(uint32 _id) view public returns (uint64[], uint32[], uint32[], uint32[]) {
        uint64[] memory timeList = new uint64[](idCET6Count[_id]);
        uint32[] memory listeningList = new uint32[](idCET6Count[_id]);
        uint32[] memory readingList = new uint32[](idCET6Count[_id]);
        uint32[] memory writingList = new uint32[](idCET6Count[_id]);
        uint counter = 0;
        for (uint i = 0; i < CET6List.length; i++) {
            if (CET6IndexToId[i] == _id) {
                timeList[counter] = CET6List[i].time;
                listeningList[counter] = CET6List[i].listening;
                readingList[counter] = CET6List[i].reading;
                writingList[counter] = CET6List[i].writing;
                counter++;
            }
        }
        return (timeList, listeningList, readingList, writingList);
    }
}