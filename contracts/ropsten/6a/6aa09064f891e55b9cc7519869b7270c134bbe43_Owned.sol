contract Owned{
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner{
        owner = newOwner;
    }
}