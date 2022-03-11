pragma solidity ^0.8.6;
/*
 * SPDX-License-Identifier: MIT
 */
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "./TeleportToken.sol";

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Oracled is Owned {
    mapping(address => bool) public oracles;
    address[] internal oraclesArr;

    modifier onlyOracle() {
        require(
            oracles[msg.sender] == true,
            "Account is not a registered oracle"
        );

        _;
    }

    function regOracle(address _newOracle) public onlyOwner {
        require(!oracles[_newOracle], "Oracle is already registered");
        oraclesArr.push(_newOracle);
        oracles[_newOracle] = true;
    }

    function unregOracle(address _remOracle) public onlyOwner {
        require(oracles[_remOracle] == true, "Oracle is not registered");

        delete oracles[_remOracle];
    }
}

contract TeleportTokenFactory is Owned, Oracled {
    TeleportToken[] public teleporttokens;
    uint256 public creationFee = 0.01 ether;

    // Payable constructor can receive Ether
    constructor() payable {}

    function isOracle(address _address) public view returns (bool) {
        return oracles[_address];
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {}

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    // Function to withdraw all Ether from this contract.
    function withdraw() public onlyOwner {
        // get the amount of Ether stored in this contract
        uint256 amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function create(
        string memory _symbol,
        string memory _name,
        uint8 _decimals,
        uint256 __totalSupply,
        uint8 _threshold,
        uint8 _thisChainId
    ) public payable {
        // correct fee
        require(msg.value == creationFee, "Wrong fee");
        TeleportToken tt = new TeleportToken(
            _symbol,
            _name,
            _decimals,
            __totalSupply,
            _threshold,
            _thisChainId
        );

        tt.transferOwnership(msg.sender);

        teleporttokens.push(tt);
    }

    function getTokenAddress(uint256 _index)
        public
        view
        returns (address ttAddress)
    {
        TeleportToken tt = teleporttokens[_index];

        return (address(tt));
    }

    function setFee(uint256 _fee) public onlyOwner {
        creationFee = _fee;
    }
}