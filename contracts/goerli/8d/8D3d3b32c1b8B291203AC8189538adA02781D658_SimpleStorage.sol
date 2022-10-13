// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract SimpleStorage {
    string[] private strings;
    address[] private addresses;
    uint256[] private nums;
    string private key;
    address payable private owner;

    constructor(string memory _key) public {
        owner = msg.sender;
        key = _key;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(string memory _key, address payable newOwner)
        public
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        owner = newOwner;
    }

    function fund(string memory _key) public payable onlyOwner {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
    }

    function withdraw(string memory _key, address payable receiver)
        public
        payable
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        receiver.transfer(address(this).balance);
    }

    function viewString(string memory _key, uint256 index)
        public
        view
        onlyOwner
        returns (string memory)
    {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        return (strings[index]);
    }

    function viewNum(string memory _key, uint256 index)
        public
        view
        onlyOwner
        returns (uint256)
    {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        return (nums[index]);
    }

    function viewAddress(string memory _key, uint256 index)
        public
        view
        onlyOwner
        returns (address)
    {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        return (addresses[index]);
    }

    function addString(string memory _key, string memory _string)
        public
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        strings.push(_string);
    }

    function addNum(string memory _key, uint256 _num) public onlyOwner {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        nums.push(_num);
    }

    function addAddress(string memory _key, address _address) public onlyOwner {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        addresses.push(_address);
    }

    function changeKey(string memory _key, string memory _newKey)
        public
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(_key)) ==
                keccak256(abi.encodePacked(key))
        );
        _key = _newKey;
    }
}