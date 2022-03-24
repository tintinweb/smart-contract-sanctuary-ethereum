/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity>=0.7.0;

contract User {
    string login;
    string password;
    address owner;
    
    constructor(string memory _login, string memory _password, address _owner){
        login = _login;
        password = _password;
        owner = _owner;
    }
    
   function getpassword() public view returns(string memory){
        return password;
    }

    function getlogin() public view returns(string memory){
        return login;
    }
}
 
contract Database {
     
    address[] private usersAddress;
    address owner;
    
    constructor(address _owner){
        owner = _owner;
        
    }
    
    function getUsers(uint id, address sender) public view returns(address){
        require(sender == owner);
        return usersAddress[id];
    }
     
    function pushUser(address userAddress, address sender) public{
        require(sender == owner);
        usersAddress.push(userAddress);
    }
     
    function checkIn(address add, address sender) public view returns(bool){
        require(sender == owner);
        for(uint i = 0; i < usersAddress.length; i++){
            if(usersAddress[i] == add){
                return true;
            }
        }
        return false;
    }
    
    function createUser (string memory login, string memory password, address sender) public payable returns(uint){
      require(sender == owner);
      User tmp = new User(login, password, sender);
      pushUser(address(tmp), sender);
      return usersAddress.length -1;
    }
    
    function getLenght() public view returns(uint) {
        return usersAddress.length;
    }
}


contract CreateDatabase{
    address[] private databaseAddress;
    
     function createDatabase() public payable {
         Database BD = new Database (msg.sender); 
         databaseAddress.push (address(BD));
     }
     function getDatabase(uint id) public view returns(address) {
         return databaseAddress [id];
     }


     // костыли
    function getLainDatabase(uint id) public view returns(uint){
        Database database = Database(getDatabase(id));
        return database.getLenght();
    }
    function getCount() public view returns(uint){
        return databaseAddress.length;
    }
    function getLoginDatabase(uint idDatabase, uint idUser) public view returns(string memory){
        Database database = Database(getDatabase(idDatabase));
        User user = User(database.getUsers(idUser, msg.sender));
        return user.getlogin();
    }
    function getPasswordDatabase(uint idDatabase, uint idUser) public view returns(string memory){
        Database database = Database(getDatabase(idDatabase));
        User user = User(database.getUsers(idUser, msg.sender));
        return user.getpassword();
    }
    function createUserDatabase(uint idDatabase, string memory login, string memory password) public payable{
    Database database = Database(getDatabase(idDatabase));   
    database.createUser(login, password, msg.sender);
    }
    function getUsersDatabase(uint idUser,  uint idDatabase) public view returns(address){
    Database database = Database(getDatabase(idDatabase));  
    return database.getUsers(idUser, msg.sender);
    }
}