// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <=0.8.19;

import "./Interfaces/IUserDetails.sol" ;

contract userDetails is IUserDetails{

    mapping(address=>userDetails) public userDetailsMapping;
    address[] public users;
    address[] public suppliers;
    address[] public manufacturers;
    address[] public distributors;

    event eventUserData(address _address, userType _type, bytes _name, bytes _physicalAddress,bytes _image, uint256 _timeUpdated);
    event eventDeleteUser(address _address);

    function addUser(userType _type, bytes calldata _name, bytes calldata _physicalAddress,bytes memory _image)public{

         require((userDetailsMapping[msg.sender].userName).length == 0, "User already registered");
         userDetailsMapping[msg.sender] = userDetails(_type,_name,_physicalAddress,_image);
         users.push(msg.sender);
         if(_type == userType.Supplier) suppliers.push(msg.sender);
         if(_type == userType.Manufacturer) manufacturers.push(msg.sender);
         if(_type == userType.Distributor) distributors.push(msg.sender);
         emit eventUserData(msg.sender,_type,_name,_physicalAddress,_image,block.timestamp);
         

    }
    function deleteUser(address _address)public{
        require((userDetailsMapping[msg.sender].userName).length == 0, "User not present");
        delete userDetailsMapping[_address];
        emit eventDeleteUser(msg.sender);
    }

    function editName(bytes memory _name)public{
        userDetailsMapping[msg.sender].userName = _name;
        userDetails memory u = userDetailsMapping[msg.sender];
        emit eventUserData(msg.sender,u.userType,_name,u.userPhysicalAddress,u.userImage,block.timestamp);

    }
    function editPhysicalAddress(bytes memory _physicalAddress)public{
        userDetailsMapping[msg.sender].userPhysicalAddress = _physicalAddress;
        userDetails memory u = userDetailsMapping[msg.sender];
        emit eventUserData(msg.sender,u.userType,u.userName,_physicalAddress,u.userImage,block.timestamp);

    }
    function editImage(bytes memory _image)public{
        userDetailsMapping[msg.sender].userImage = _image;
        userDetails memory u = userDetailsMapping[msg.sender];
        emit eventUserData(msg.sender,u.userType,u.userName,u.userImage,_image,block.timestamp);
    }

    function getSingleUser(address _address) public view returns(userDetails memory){
        return userDetailsMapping[_address];
    }

    function getAllUsers() public view returns(userDetails[] memory){
        userDetails[] memory userD = new userDetails[](users.length);
        for(uint i=0;i<users.length;i++)
        {
            userD[i] = userDetailsMapping[users[i]];
        }
        return userD;
    }

    function getAllSuppliers() public view returns(userDetails[] memory){
        userDetails[] memory suppD = new userDetails[](suppliers.length);
        for(uint i=0;i<users.length;i++)
        {
            suppD[i] = userDetailsMapping[suppliers[i]];
        }
        return suppD;

    }

      function getAllManufacturers() public view returns(userDetails[] memory){
        userDetails[] memory manuD = new userDetails[](manufacturers.length);
        for(uint i=0;i<users.length;i++)
        {
            manuD[i] = userDetailsMapping[manufacturers[i]];
        }
        return manuD;

    }

      function getAllDistributors() public view returns(userDetails[] memory){
        userDetails[] memory distD = new userDetails[](distributors.length);
        for(uint i=0;i<users.length;i++)
        {
            distD[i] = userDetailsMapping[distributors[i]];
        }
        return distD;

    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <=0.8.19;

interface IUserDetails {

   enum userType {
    Supplier,
    Manufacturer,
    Distributor
  } 
  struct userDetails{
      userType userType;
      bytes userName;
      bytes userPhysicalAddress;
      bytes userImage;
  }

 
  function addUser(userType _type, bytes calldata _name, bytes calldata _physicalAddress,bytes memory _image)external;
  function deleteUser(address _address)external;
  function editName(bytes memory _name)external;
  function editPhysicalAddress(bytes memory _physicalAddress)external;
  function editImage(bytes memory _image)external;
}