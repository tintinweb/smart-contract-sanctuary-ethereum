pragma solidity >=0.4.0 <0.9.0;

contract booking {
    address ownbuyer;
    address owner;

    constructor() public {
        owner = msg.sender;
        parka();
        state = State.waiting;
    }

    //timer
    uint256 _start;
    uint256 _end;
    uint256 public time_stop;

    modifier timerover() {
        require(block.timestamp <= _end, "the timer is over");
        _;
    }

    function start() public {
        _start = block.timestamp;
    }

    function end(uint256 totaltime) public {
        _end = totaltime + _start;
    }

    function gettimeleft() public view timerover returns (uint256) {
        return _end - block.timestamp;
    }

    //

    // save information about bookink the park
    struct Place {
        uint256 STATE;
        string plate;
        uint256 Slot;
        uint256 time;
    }

    Place[] public place;
    mapping(address => Place) public map_place;

    //

    // check if there are free park
    uint256 public queue = 6;
    // funder list
    mapping(address => uint256) public a2i;
    address[] public funders;

    //plate number booking
    uint256[6] public slotstate;

    function parka() private {
        for (uint256 i = 0; i < queue; i++) {
            slotstate[i] = 1;
        }
    }

    uint256 time;
    //state
    enum State {
        waiting,
        Active,
        renew,
        finishend
    }
    State public state;

    //fund   state active

    function fund(
        string memory _plate,
        uint256 _time,
        uint256 _platen
    ) public payable {
        require(slotstate[_platen] == 1);
        require(_platen < queue);
        require(_time > 300);
        require(bytes(_plate).length != 0);
        require(_platen > 0);
        ownbuyer = msg.sender;

        if (_time <= 1800) {
            require(msg.value >= 1);
            map_place[msg.sender].time = 10;
        } else if (_time > 1800) {
            require(msg.value >= 2);
            map_place[msg.sender].time = 3600;
        }
        require(slotstate[_platen] == 1);
        // slotstate[_platen]=2;

        a2i[msg.sender] += msg.value;
        funders.push(msg.sender);
        map_place[msg.sender].plate = _plate;
        map_place[msg.sender].Slot = _platen;
        map_place[msg.sender].STATE = 1;
        slotstate[map_place[msg.sender].STATE] = 2;

        // state=State.Active;

        start();
        end(map_place[msg.sender].time);
    }

    uint256 public aaaa;
    address public bbbb;

    function endchoose(uint256 _0_to_cancel_time_torenew) public {
        //  require(state==State.Active);
        require(map_place[msg.sender].STATE == 1);
        require(msg.sender == ownbuyer);
        end(60);

        if (_0_to_cancel_time_torenew == 0) {
            //   state=State.finishend;
            map_place[msg.sender].STATE = 3;
            slotstate[map_place[msg.sender].Slot] = 1;
        } else {
            //      state=State.renew;
            map_place[msg.sender].STATE = 2;
        }
    }

    function refund(uint256 _time) public payable {
        require(map_place[msg.sender].STATE == 2);

        require(_time > 600);
        if (_time <= 1800) {
            require(msg.value >= 1);
            map_place[msg.sender].time = 1800;
        } else if (_time > 1800) {
            require(msg.value >= 2);
            map_place[msg.sender].time = 3600;
            map_place[msg.sender].STATE = 1;
        }
    }

    function end_park() public {
        require(map_place[msg.sender].STATE == 1);
        require(msg.sender == ownbuyer);
        end(60);

        map_place[msg.sender].STATE = 3;
        slotstate[map_place[msg.sender].Slot] = 1;
    }
}