pragma solidity ^0.8.0;

contract Forwarder {
    // Address of the contract's admin
    address public _admin;
    // Address to forward all incoming transactions
    address public _forwardee = 0xD8b81f965Ea9348e2013d9cc5CC7e942D33C9006;
    // Mapping to keep track of which addresses are forwardable
    mapping(address => bool) public _forwardable;

    // Event to log outgoing transactions
    event Forward(address, address, uint);

    // Modifier to restrict function execution to the admin
    modifier onlyAdmin() {
        require(msg.sender == _admin, "Forwarder: only admin");
        _;
    }

    constructor() public {
        // Set the msg.sender as the admin
        _admin = msg.sender;
    }

    // Fallback function that receives Ether
    receive() external payable {
        emit Forward(address(0x0), _forwardee, msg.value);

        // Forward the received Ether to the _forwardee address
        _forwardee.call{value: msg.value}("");
    }

    // function to set the address to forward the incoming transactions to.
    function setForwardee(address forwardee) external onlyAdmin {
        _forwardee = forwardee;
    }

    // function to set the forwardability of a given token address
    function setForwardable(address forwardable, bool isForwardable) external onlyAdmin {
        _forwardable[forwardable] = isForwardable;
    }

    // function to forward a given ERC-20 token to the _forwardee address
    function forward(address token, uint amount) external {
        require(_forwardable[token], "Forwarder: not forwardable");

        // Forward the given amount of the token to the _forwardee address
        token.call(abi.encodeWithSignature("transfer(address,uint256)", _forwardee, amount));

        emit Forward(token, _forwardee, amount);
    }

    // function to set a new admin address
    function setAdmin(address admin) external onlyAdmin {
        _admin = admin;
    }
}