// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
 

contract SafeMath {
 
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract AIRBNBToken is IERC20,SafeMath {


   string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
    constructor()  {
        symbol = "AIRBNB";
        name = "Airbnb booking tokens";
        decimals = 0;
        _totalSupply = 100000000;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
 


    function totalSupply() public override view returns (uint256) {

    return _totalSupply;

    }


    function balanceOf(address tokenOwner) public override view returns (uint256) {

        return balances[tokenOwner];

    }


    function transfer(address to, uint tokens) public override returns (bool)  {
        require(tokens <= balances[msg.sender],"Not enough tokens available in your account.");
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 

    function approve(address spender, uint tokens) public override returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     function allowance(address tokenOwner, address spender) public override view returns (uint) {
        return allowed[tokenOwner][spender];
    }
 

  function transferFrom(address from, address to, uint tokens) public override returns (bool) {
        require(tokens <= balances[from],"Not enough tokens available in your account.");
        require(tokens <= allowed[from][msg.sender],"Transfer limit exceeded the approved limit.");


        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}

contract airbnb {
    AIRBNBToken public airbnbToken;
    address public owner;
    uint256 private counter;

    constructor() {
        counter = 0;
        owner = msg.sender;
     }

    struct rentalInfo {
        string name;
        string city;
        string lat;
        string long;
        string unoDescription;
        string dosDescription;
        string imgUrl;
        uint256 maxGuests;
        uint256 pricePerDay;
        string[] datesBooked;
        uint256 id;
        address renter;
    }

    event rentalCreated (
        string name,
        string city,
        string lat,
        string long,
        string unoDescription,
        string dosDescription,
        string imgUrl,
        uint256 maxGuests,
        uint256 pricePerDay,
        string[] datesBooked,
        uint256 id,
        address renter
    );

    event newDatesBooked (
        string[] datesBooked,
        uint256 id,
        address booker,
        string city,
        string imgUrl
    );

    mapping(uint256 => rentalInfo) rentals;
    uint256[] public rentalIds;


    function addRentals(
        string memory name,
        string memory city,
        string memory lat,
        string memory long,
        string memory unoDescription,
        string memory dosDescription,
        string memory imgUrl,
        uint256 maxGuests,
        uint256 pricePerDay,
        string[] memory datesBooked
    ) public {
        require(msg.sender == owner, "Only owner of smart contract can put up rentals");
        rentalInfo storage newRental = rentals[counter];
        newRental.name = name;
        newRental.city = city;
        newRental.lat = lat;
        newRental.long = long;
        newRental.unoDescription = unoDescription;
        newRental.dosDescription = dosDescription;
        newRental.imgUrl = imgUrl;
        newRental.maxGuests = maxGuests;
        newRental.pricePerDay = pricePerDay;
        newRental.datesBooked = datesBooked;
        newRental.id = counter;
        newRental.renter = owner;
        rentalIds.push(counter);
        emit rentalCreated(
                name,
                city,
                lat,
                long,
                unoDescription,
                dosDescription,
                imgUrl,
                maxGuests,
                pricePerDay,
                datesBooked,
                counter,
                owner);
        counter++;
    }

    function checkBookings(uint256 id, string[] memory newBookings) private view returns (bool){

        for (uint i = 0; i < newBookings.length; i++) {
            for (uint j = 0; j < rentals[id].datesBooked.length; j++) {
                if (keccak256(abi.encodePacked(rentals[id].datesBooked[j])) == keccak256(abi.encodePacked(newBookings[i]))) {
                    return false;
                }
            }
        }
        return true;
    }


    function addDatesBooked(uint256 id, string[] memory newBookings) public payable {

        require(id < counter, "No such Rental");
        require(checkBookings(id, newBookings), "Already Booked For Requested Date");
        // require(msg.value == (rentals[id].pricePerDay * 20000 wei * newBookings.length) , "Please submit the asking price in order to complete the purchase");
        // checking if user has sufficient tokens
        require(rentals[id].pricePerDay <= airbnbToken.balanceOf(msg.sender), "Not enought tokens to book.");

        // Transferring the tokens to the owner.
        airbnbToken.transfer(owner,rentals[id].pricePerDay);
        
        for (uint i = 0; i < newBookings.length; i++) {
            rentals[id].datesBooked.push(newBookings[i]);
        }

        // payable(owner).transfer(msg.value);
        emit newDatesBooked(newBookings, id, msg.sender, rentals[id].city,  rentals[id].imgUrl);

    }


    function getRental(uint256 id) public view returns (string memory,string memory,string memory,
        string memory,string memory,string memory,string memory,uint256,uint256, string[] memory,uint256){
        require(id < counter, "No such Rental");

        rentalInfo storage s = rentals[id];
        return (s.name,s.city,s.lat,s.long,s.unoDescription,s.dosDescription,
        s.imgUrl,s.maxGuests,s.pricePerDay,s.datesBooked,s.id);
    
    }

}