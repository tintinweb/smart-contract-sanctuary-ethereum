/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BuyMeCoffee {
    address public owner;
    uint256 public ClientCount = 0;
    uint256 public AmountTotal = 0;

    Client[] public Coffees;

    struct Client {
        uint256 id;
        string name;
        string description;
        string ulrImg;
        uint256 tipAmount;
        address payable wallet;
    }

    mapping(address => uint256) public TotalDonatedUser;

    constructor() {
        owner = msg.sender;
    }

    //------- MODIFIERS ----------
    modifier onlyOwner() {
        require(msg.sender == owner, "Onlyowner: user not owner");
        _;
    }

    modifier validateIdCoffees(uint256 _id) {
        require(_id < ClientCount, "Id: not found");
        _;
    }

    modifier validateStrings(
        string memory _name,
        string memory _description,
        string memory _ulrImg
    ) {
        require(bytes(_name).length > 0, "name is null");
        require(bytes(_description).length > 0, "description is null");
        require(bytes(_ulrImg).length > 0, "Image URL is null");
        _;
    }

    //------ EVENTS ------
    event ClientCreated(
        uint256 indexed userId,
        string _name,
        string _description,
        string ulrImg,
        address payable wallet
    );

    event CoffeesTipped(uint256 indexed userId, uint256 amountDonated);

    // EXTERNAL
    function tipCoffee(uint256 _id) external payable validateIdCoffees(_id) {
        Client memory _Client = Coffees[_id];
        address payable _user = _Client.wallet;
        Coffees[_id].tipAmount += msg.value;
        AmountTotal = AmountTotal + msg.value; // forma 1
        TotalDonatedUser[msg.sender] += msg.value; // forma 2
        transferEth(_user, msg.value);
        emit CoffeesTipped(_id, _Client.tipAmount);
    }

    //------- INTERNAL -------
    function transferEth(address _to, uint256 amount) internal {
        require(amount > 0);
        (bool success, ) = _to.call{value: amount}("");
        require(success, "something went wrong");
    }

    //------- VIEW FUNCTIONS -------

    function getCoffeesList() public view returns (Client[] memory) {
        return Coffees;
    }

    //------- ADMIN FUNCTIONS -----------
    function CreateUser(
        string memory _name,
        string memory _description,
        string memory _ulrImg,
        address payable wallet
    ) public onlyOwner validateStrings(_name, _description, _ulrImg) {
        require(wallet != address(0x0));
        Client memory _Client = Client(
            ClientCount,
            _name,
            _description,
            _ulrImg,
            0,
            wallet
        );
        Coffees.push(_Client);
        emit ClientCreated(ClientCount,  _name, _description, _ulrImg, wallet);
        ClientCount++;
    }

    function EditUser(
        string memory _name,
        string memory _description,
        string memory _ulrImg,
        address payable wallet,
        uint256 _id
    )
    public
    validateIdCoffees(_id)
    onlyOwner
    validateStrings(_name, _description, _ulrImg)
    {
        require(wallet != address(0x0));
        Coffees[_id] = Client(
            _id,
            _name,
            _description,
            _ulrImg,
            Coffees[_id].tipAmount,
            wallet
        );
        emit ClientCreated(ClientCount, _name, _description, _ulrImg, wallet);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: newOwner is the zero address"
        );
        owner = newOwner;
    }
}