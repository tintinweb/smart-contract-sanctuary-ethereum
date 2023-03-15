contract TestArr {
    uint256[] public test;
    event Add(uint256 indexed el);
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function add(uint256 x) public {
        require(msg.sender == owner);
        test.push(x);
        emit Add(x);
        if (x % 2 == 0) revert("Even number");
    }

    function getTestArr() public view returns (uint256[] memory) {
        return test;
    }
}