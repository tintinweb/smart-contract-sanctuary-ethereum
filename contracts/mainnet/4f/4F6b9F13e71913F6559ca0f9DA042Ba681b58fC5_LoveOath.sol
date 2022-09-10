// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract LoveOath {
    /// Only contract owner is allowed to excute this function
    error NotOwner();

    address payable owner;
    uint private fee = 0;
    address[] private registeredOaths;
    mapping(address => address[]) private oathsByOwnerAddress;

    //event
    event NewOathContractCreated(address contractAddress, address ownerAddress);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
    }

    function setFee(uint _fee) public onlyOwner {
        fee = _fee;
    }

    function fundMe() public payable {}

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function createOath(
        string memory _spouse1Name,
        string memory _spouse1Oath,
        string memory _spouse2Name,
        string memory _spouse2Oath,
        string memory _location,
        uint _date
    ) public payable {
        require(msg.value >= fee, "Your balance is not enough for the fee");
        address newOath = address(
            new Oath(
                msg.sender,
                _spouse1Name,
                _spouse1Oath,
                _spouse2Name,
                _spouse2Oath,
                _location,
                _date
            )
        );
        oathsByOwnerAddress[msg.sender].push(newOath);
        emit NewOathContractCreated(newOath, msg.sender);
        registeredOaths.push(newOath);
    }

    function getBalance() public view onlyOwner returns (uint) {
        return address(this).balance;
    }

    function getFee() public view returns (uint256) {
        return fee;
    }

    function getDeployedOaths() public view returns (address[] memory) {
        return registeredOaths;
    }

    function getOathsByOwnerAddress(address ownerAddress)
        public
        view
        returns (address[] memory)
    {
        return oathsByOwnerAddress[address(ownerAddress)];
    }
}

contract Oath {
    event weddingBells(address ringer, uint256 count);

    // Owner address
    address public owner;

    // Oath
    string public spouse1Name;
    string public spouse1Oath;
    string public spouse2Name;
    string public spouse2Oath;
    string public location;
    uint256 public oathDate;

    // Bell counter
    uint256 public bellCounter;

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Constructor sets the original `owner` of the contract to the sender account, and
     * commits the Oath details and vows to the blockchain
     */
    constructor(
        address _owner,
        string memory _spouse1Name,
        string memory _spouse1Oath,
        string memory _spouse2Name,
        string memory _spouse2Oath,
        string memory _location,
        uint _date
    ) {
        owner = _owner;
        spouse1Name = _spouse1Name;
        spouse1Oath = _spouse1Oath;
        spouse2Name = _spouse2Name;
        spouse2Oath = _spouse2Oath;
        oathDate = _date;
        location = _location;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) private pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
     * @dev ringBell is a payable function that allows people to celebrate the couple's Oath, and
     * also send Ether to the Oath contract
     */
    function ringBell() public payable {
        bellCounter = add(1, bellCounter);
        emit weddingBells(msg.sender, bellCounter);
    }

    /**
     * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
     */
    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev returns contract metadata in one function call, rather than separate .call()s
     */
    function getOathDetails()
        public
        view
        returns (
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            owner,
            spouse1Name,
            spouse1Oath,
            spouse2Name,
            spouse2Oath,
            location,
            oathDate,
            bellCounter,
            address(this).balance
        );
    }
}