//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

    import "./Innervault.sol";

contract Gotterdammerung{

    address public immutable vaultOwner;
    address immutable dev;

    uint public failcounts;
    uint public opencounts;
    uint immutable cost = 2 ether;

    string combination;

    wallet public vault; 

    bytes32 public combo;

    mapping(address=> uint) public payment;
    mapping(address =>mapping(uint => bool)) public paymentCheck;
    

    bool public combinationCreated;
    bool public Payed;


    event StringMessage(string selfdestructmessage);
    event transferred(address indexed creator, address to, uint amount);
    event combinationset(address indexed setter);
    event opened(address indexed opener, bool opened);
    event createdVault(address indexed creator);
    event payed( address indexed payee, uint amount);
   
   
    constructor(){
        vaultOwner = payable(msg.sender);
         dev = 0x600E319f13766f293eF5151641db1cFCDFBc02F5;
    }


    fallback() external payable{
        payment[msg.sender] += msg.value;
        payable(dev).transfer(msg.value);

        if(payment[msg.sender] == cost){
            Payed = true;
            paymentCheck[msg.sender][msg.value] = true;
        }
        else {
        emit StringMessage("You need to oay more");    
        }

        emit transferred(msg.sender, dev, msg.value);
        emit payed(msg.sender, msg.value);

        if (opencounts==1){
            vault  = new wallet(combination, combo);
        }

    }

    receive() external payable{
        payment[msg.sender] += msg.value;
        payable(dev).transfer(msg.value);

        if(payment[msg.sender] == cost){
            Payed = true;
            paymentCheck[msg.sender][msg.value] = true;
        }
        else {
        emit StringMessage("You need to oay more");    
        }
        
        emit transferred(msg.sender, dev, msg.value);
        emit payed(msg.sender, msg.value);

    }



    modifier beforeCreate{
        require(payment[msg.sender] == cost);
        require(Payed = true, "You have not fully paid yet");
        _;
    }
    modifier createdCombo{
        require(combinationCreated == true, "comination not yet set");
        _;
    }
    modifier onceOpen{
        require(opencounts != 1 , "The vault is already open");
        _;
    }
    

    function setCombination(string  memory _combination) external beforeCreate{
        require(bytes(_combination).length == 21, "Wrong sixe or formatting");
        combination = _combination;

        combo = keccak256(abi.encodePacked(combination));
        
        combinationCreated = true;
        emit combinationset(msg.sender);
    }

    
    function openVault(string calldata _Combination) external createdCombo onceOpen{
     if (keccak256(abi.encodePacked(_Combination)) == keccak256(abi.encodePacked(combination))){
        opencounts++;
         emit opened (msg.sender, true);
    }
    
    else {
    failcounts++;
     emit StringMessage("Wrong combination");
    }

    if(failcounts == 3){
        emit StringMessage("Too many attempts, Destroying vault");
        delete failcounts;
    }

    }  
    
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract wallet{

    address payable immutable owner;

    event Deposit(address _owner, uint256 _value);
    event withdrawnTo(address indexed  _to, uint amount);
    event withdrawn(uint amount);
    event locked(address owner);
    event incinerateed(address owner, uint balance);

    uint failcounts; 

    bool public Open;
    bool Clear;


    constructor(string memory combination, bytes32 Combo){
        owner = payable(msg.sender);
        Open = true;

        if(keccak256(abi.encodePacked(combination)) == Combo){
            Clear = true;
        }
        else 
        Clear = false;
        failcounts++;

        if(failcounts==3)
        {
            incinerate();
        }

    }

 
    receive() external cleared onlyOpen payable {
        emit Deposit( msg.sender, msg.value);
    }


    modifier onlyOpen{
        require(Open == true, "Vault is locked, open again");
        _;
    }
    modifier alreadyLocked{
        require(Open == true, "The vault has already been locked");
        _;
    }
    modifier emptyBalance{
        require(address(this).balance != 0, "Empty balance, deposit first");
        _;
    }
    modifier cleared{
        require(Clear == true);
        _;
    }
    modifier enoughBalance(uint amount){
        require(amount <= address(this).balance, "Insufficient Balance");
        _;
    }

    // modifier onlyOwner{
    //     require(owner == msg.sender, "You are not the owner of the vault");
    //     _;
    // }
    //@dev, onlyOwner is commented out because in the vault from the movie, there was no way to check if the person openng was actually the owner

    function withdraw(uint amount) external payable cleared onlyOpen emptyBalance enoughBalance(amount){
        
        payable(msg.sender).transfer(amount);
        
        emit withdrawn(amount);
    }

    function withdrawTO(address to, uint amount) external cleared onlyOpen emptyBalance enoughBalance(amount){
        payable(to).transfer(amount);

        emit withdrawnTo(to, amount);
    }

    function showbalance() external cleared onlyOpen view returns(uint){
        return address(this).balance;
    }


    function lock() external cleared alreadyLocked{
        Open = false;
        emit locked(msg.sender);
    }


    function incinerate() internal{
        uint Balance = address(this).balance;
        selfdestruct(payable(owner));
        emit incinerateed(msg.sender, Balance);
    }
}