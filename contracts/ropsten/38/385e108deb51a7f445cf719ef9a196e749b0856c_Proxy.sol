pragma solidity ^0.4.24;

contract BrickAccessControl {

    constructor() public {
        admin = msg.sender;
        nodeToId[admin] = 1;
    }

    address public admin;
    address[] public nodes;
    mapping (address => uint) nodeToId;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized admin");
        _;
    }

    modifier onlyNode() {
        require(nodeToId[msg.sender] != 0, "Not authorized node");
        _;
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0));

        admin = _newAdmin;
    }

    function getNodes() public view returns (address[]) {
        return nodes;
    }

    function addNode(address _newNode) public onlyAdmin {
        require(_newNode != address(0), "Cannot set to empty address");

        nodeToId[_newNode] = nodes.push(_newNode);
    }

    function removeNode(address _node) public onlyAdmin {
        require(_node != address(0), "Cannot set to empty address");

        uint index = nodeToId[_node] - 1;
        delete nodes[index];
        delete nodeToId[_node];
    }

}


contract BrickBase is BrickAccessControl {

    /**************
       Events
    ***************/

    // S201. 대출 계약 생성
    event ContractCreated(bytes32 loanId);

    // S201. 대출중
    event ContractStarted(bytes32 loanId);

    // S301. 상환 완료
    event RedeemCompleted(bytes32 loanId);

    // S302. 청산 완료
    event LiquidationCompleted(bytes32 loanId);


    /**************
       Data Types
    ***************/

    struct Contract {
        bytes32 loanId;         // 계약 번호
        uint16 productId;       // 상품 번호
        bytes8 coinName;        // 담보 코인 종류
        uint256 coinAmount;     // 담보 코인양
        uint32 coinUnitPrice;   // 1 코인당 금액
        string collateralAddress;  // 담보 입금 암호화폐 주소
        uint32 loanAmount;      // 대출원금
        uint64 createAt;        // 계약일
        uint64 openAt;          // 원화지급일(개시일)
        uint64 expireAt;        // 만기일
        bytes8 feeRate;         // 이자율
        bytes8 overdueRate;     // 연체이자율
        bytes8 liquidationRate; // 청산 조건(담보 청산비율)
        uint32 prepaymentFee;   // 중도상환수수료
        bytes32 extra;          // 기타 정보
    }

    struct ClosedContract {
        bytes32 loanId;         // 계약 번호
        bytes8 status;          // 종료 타입(S301, S302)
        uint256 returnAmount;   // 반환코인량(유저에게 돌려준 코인)
        uint32 returnCash;      // 반환 현금(유저에게 돌려준 원화)
        string returnAddress;   // 담보 반환 암호화폐 주소
        uint32 feeAmount;       // 총이자(이자 + 연체이자 + 운영수수료 + 조기상환수수료)
        uint32 evalUnitPrice;   // 청산시점 평가금액(1 코인당 금액)
        uint64 evalAt;          // 청산시점 평가일
        uint64 closeAt;         // 종료일자
        bytes32 extra;          // 기타 정보
    }


    /**************
        Storage
    ***************/

    // 계약 번호 => 대출 계약서
    mapping (bytes32 => Contract) loanIdToContract;
    // 계약 번호 => 종료된 대출 계약서
    mapping (bytes32 => ClosedContract) loanIdToClosedContract;

    bytes32[] contracts;
    bytes32[] closedContracts;

}

contract Proxy is BrickBase {

    event BrickUpgraded(address indexed _brickAddress);

    address public brickAddress;

    constructor(address _brickAddress) public {
        setBrickAddress(_brickAddress);
    }

    function() public {
        address contractAddress = brickAddress;
        require(contractAddress != address(0), "Cannot set address to address(0)");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, contractAddress, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function setBrickAddress(address _brickAddress) public onlyAdmin {
        require(_brickAddress != address(0), "Cannot upgrade to the same address.");
        require(_brickAddress != brickAddress, "Cannot upgrade to empty address.");
        brickAddress = _brickAddress;
        emit BrickUpgraded(brickAddress);
    }

}