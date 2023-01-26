// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract bWallet {
    address public owner;
    uint256 public nonce;
    event Received(address, uint256);
    event Sent(address, uint256);
    event Staked(address, uint256, bytes);
    mapping(address => uint256) public staked;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;

    mapping(address => uint256) public userStakedAmount;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(address _owner) payable {
        owner = _owner;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function send(address payable _to, uint256 _amount) external onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        nonce += 1;
        emit Sent(_to, _amount);
    }

    function deposit() external payable {
        emit Received(msg.sender, msg.value);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        nonce += 1;
    }

    function destroy(address payable recipient) public onlyOwner {
        selfdestruct(recipient);
    }

    function Stake(address payable _addr, bytes memory data) public payable {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );

        emit Staked(_addr, msg.value, data);

        require(success, string(returnData));
    }

    function BitsStaking(address payable _addr, bytes memory data)
        external
        payable
    {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );
        calls[_addr] = data;
        values[_addr] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit Staked(_addr, msg.value, data);
        require(success, string(returnData));
    }
}

contract bWalletFactory {
    event newWallet(address wallet);

    constructor() payable {}

    function deploy() public returns (address) {
        uint256 _salt = convertAddr(msg.sender);

        address newAddress = address(
            new bWallet{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWallet(newAddress);

        return newAddress;
    }

    function deployWithAddress(address _addr) public returns (address) {
        uint256 _salt = convertAddr(_addr);

        address newAddress = address(
            new bWallet{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWallet(newAddress);

        return newAddress;
    }

    function deployWeth() public payable returns (address) {
        uint256 _salt = convertAddr(msg.sender);

        address newAddress = address(
            new bWallet{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWallet(newAddress);
        (bool sent, ) = newAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        return newAddress;
    }

    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(bWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(msg.sender));
    }

    function getAddress(uint256 _salt) public view returns (address) {
        // Get a hash concatenating args passed to encodePacked
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 0
                address(this), // address of factory contract
                _salt, // a random salt
                keccak256(getBytecode()) // the wallet contract bytecode
            )
        );
        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    function convertAddr(address _addr) public pure returns (uint256) {
        uint256 i = uint256(uint160(_addr));
        return i;
    }

    function send(address payable _to, uint256 _amount) public payable {
        _to.transfer(_amount);
    }
}