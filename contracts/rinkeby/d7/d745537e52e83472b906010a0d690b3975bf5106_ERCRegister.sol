/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// import "@openzeppelin/[email protected]/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ERCRegister {
   
     enum Userrole
    {
      Admin,     //owner 
      Creator,  //supplier,
      Collector //buyer
    } 
     address public owner;
    Userrole ownerrole;
    constructor(){
        owner = msg.sender;
        ownerrole = Userrole.Admin;
    }
    modifier onlyowner(){
        require(msg.sender == owner,"only owner can access this functionality");
        _;
    }
    struct User
    {
        string Firstname;
        string Lastname;
        string Email;
        string Gender;
        uint Mobile;
        Userrole Role;
    }
    // Creating an enumerator
   
   Userrole public userrole;
   function get() public view returns (Userrole) {
        return userrole;
    }
    // Setting a default value
  //  Userrole constant defaultValue = Userrole.Admin;

    mapping(uint=>User) public data;
  
    function registerUser(uint _id, string memory _firstname,string memory _lastname,string memory _email,string memory _gender, uint _mobile, Userrole  _role) public
    {
        data[_id] = User(_firstname, _lastname,_email,_gender,_mobile,_role);
    }

     function changeRole(uint _id,Userrole _userrole) public  onlyowner(){
        User memory updateData = data[_id];
        updateData.Role= _userrole;
       data[_id] = updateData;
    }


    // function collectorCount(Userrole _userrole) public view returns (uint){
    //       //return data[_userrole].length;
    //       User memory validGifts;
    //      uint totalcollector;
    //      if(validGifts.Role==_userrole){
    //        totalcollector= validGifts.length;
    //     }
    //     return totalcollector;
    // }

    

     function reset() public {
        delete userrole;
    }


    //function changeRole()

}