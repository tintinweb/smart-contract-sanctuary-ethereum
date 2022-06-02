/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

//pragma solidity >=0.6.0 <0.9.0; // range of versions
// pragma solidity 0.6.0; // specific version
// pragma solidity ^0.6.0; // any version of 0.6.0

// here we are using compiler version 0.6.6
pragma solidity ^0.8.4;

// SPDX License
// SPDX-License-Identifier: MIT

contract SimpleStorage{
    // Variables
    uint256 favoriteNumber = 5; // unsigned integer
    bool favoriteBool = true;
    string favoriteString = "BC";
    int256 favoriteInt = -5;
    address favoriteAddress = 0x1096Fa518cBe6E49c4Efe8Cdd35E3De8c62ECcaA;
    bytes32 favoriteBytes = "cat"; // info converted into its equi. bytes

    // Default initializations
    uint256 public notInitialized; // notInitialized = 0
     
    /****************************************************************************/
    // Functions
    function store(uint256 _not_ini) public {
        notInitialized = _not_ini;
    }

    // four types of visibility in solidity
    //https://docs.soliditylang.org/en/v0.8.12/contracts.html#visibility-and-getters
    /* external : they can be called for other contracts via transactions
       public :  can be either called internally or via message . for public state variables, an automatic getter fuction is generated
       internal : can only be accessed internally 
       private : are only visible for the contract they are defined in and not in derived contracts
    */
    // default visibilty is internal

    // Scope : as usual 

    /********************************************************************/
    // view functions //
    // view and pure are non-state changing functions
    // view : reading the state of block chain // here notInitialized is already a view fuction (in blue color button)
    // pure : we are doing some math here but not saving the state
    function retrieve() public view returns(uint256){
        return notInitialized;
    }
    function retrieve_2(uint256 num) public pure returns(uint256){
        uint256 sum = num +num;
        return sum;
    }

    /*******************************************************************/
    // struct
    struct people{
        uint256 id;
        string name;
    }
    people public person = people({id:2,name:"gandu"});

    /********************************************************************/
    // Arrays
    people[] public peeps; // dynamic array : that can change size
    // people[10] public peeps;
    function addPerson(string memory _name , uint256 _id) public{
        peeps.push(people(_id,_name));
        nameToId[_name] = _id; // mapping // below there
        // peeps.push(people({id:_id,name:_name}));
    }
    // memory vs storage
    // memory : Data will only be stored during the execution of the function
    // storage : data will be stored even after end of the execution of the function
    // note : strings are actually an object : an array of bytes

    /*******************************************************************/
    // Mapping
    mapping(string => uint256) public nameToId;
}