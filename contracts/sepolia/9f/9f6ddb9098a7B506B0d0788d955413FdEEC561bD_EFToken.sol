/* \Version: 4.0 
    Author: Cai Yi-Wen */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC20.sol";
import "./Ownable.sol";

contract EFToken is ERC20, Ownable{
    uint256 constant initialSupply = 1000000;
    

    /* Variables */
    uint256 club_num = 0;
    uint256 resource_num = 0;
    mapping (uint => Club) clubs;
    mapping  (uint => Resource) resources;

    struct Club{
        string name;
        address addr;
    }

    struct Resource{
        string name;
        uint256 cost;
    }


    /* Events */
    event AddClub(
        uint256 indexed _clubID,
        string _clubName,
        address _addr
    );

    event AddResource(
        uint256 indexed _resourceID,
        string _resourceName,
        uint256 _cost
    );

    event ChangeResourceCost(
        uint256 _id,
        string _resourceName,
        uint256 _newCost
    );

    event BookedResource(
        uint256 indexed _clubID,
        string _clubName,
        string _date,
        uint256 indexed _resourceID,
        string _resourceName,
        uint256 _cost
    );

    event uploadPicture(
        uint256 indexed _clubID,
        string _clubName,
        uint256 indexed _activityID,
        string _activityName,
        string _date,
        uint256 indexed _pictureID,
        uint256 _number,
        uint256 _token
    );

    event ModifyPicture(
        uint256 indexed _clubID,
        string _clubName,
        uint256 indexed _activityID,
        string _activityName,
        uint256 indexed _newpicID,
        uint256 _oldnum,
        uint256 _newnum,
        uint256 _balance,
        string _action,
        uint256 _token
    );

    constructor() ERC20("Environmental Friendly Token", "EFT") {
        _mint(msg.sender, initialSupply);
    }


    /* Picture - Token*/
    function UploadPicture(
        uint256 _clubID,
        uint256 _activityID,
        string memory _activityName,
        string memory _date,
        uint256 _picID,
        uint256 _picNum
    ) external onlyOwner{
        uint256 _amount = _picNum;   //1:1 or not?
        _mint(clubs[_clubID].addr, _amount);

        emit uploadPicture(_clubID, clubs[_clubID].name, _activityID, _activityName, _date, _picID, _picNum, _amount);
    }


    function ModifyPicnum_Add(
        uint256 _clubID,
        uint256 _activityID,
        string memory _activityName,
        uint256 _oldnum,
        uint256 _picID,
        uint256 _picNum,
        uint256 _add
    ) external onlyOwner{
        uint256 _balance = balanceOf(clubs[_clubID].addr);
        uint256 _amount = _add;   //1:1 or not?
        _mint(clubs[_clubID].addr, _amount);

        emit ModifyPicture(_clubID, clubs[_clubID].name, _activityID, _activityName, _picID, _oldnum, _picNum, _balance, "Add", _amount);
    }


    // can work only after approve
    function ModifyPicnum_Retake(
        uint256 _clubID,
        uint256 _activityID,
        string memory _activityName,
        uint256 _oldnum,
        uint256 _picID,
        uint256 _picNum,
        uint256 _minus
    ) external onlyOwner{
        uint256 _balance = balanceOf(clubs[_clubID].addr);
        uint256 _amount = _minus;   //1:1 or not?
        _transfer(clubs[_clubID].addr, owner(), _amount);    

        emit ModifyPicture(_clubID, clubs[_clubID].name, _activityID, _activityName, _picID, _oldnum, _picNum, _balance, "Minus", _amount);
    }


    /* Book Resources */
    function BookResource(
        uint256 _clubID,
        uint256 _resourceID,
        string memory _date,
        uint256 _cost
    ) external {
        address _addr = clubs[_clubID].addr;
        require(_addr==_msgSender(), "You're not the Club Token Holder!!");
        require(balanceOf(_addr)>=_cost, "You don't have enough EFT!");
        transfer(owner(), _cost);    

        emit BookedResource(_clubID, clubs[_clubID].name, _date, _resourceID, resources[_resourceID].name, _cost);
    }


    /* Backend Book Resource */
    function ApproveBackend() external {
        approve(owner(), 10000);
    }

    function BookResource_backend(
        uint256 _clubID,
        uint256 _resourceID,
        string memory _date,
        uint256 _cost
    ) external onlyOwner{
        _transfer(clubs[_clubID].addr, owner(), _cost);

        emit BookedResource(_clubID, clubs[_clubID].name, _date, _resourceID, resources[_resourceID].name, _cost);
    }


    /* Resource Detail*/
    function ResourceCost(
        uint256 _id
    ) external view returns(uint256){
        return resources[_id].cost;
    }

    function ResourceName(
        uint256 _id
    ) external view returns(string memory){
        return resources[_id].name;
    }


    /* Club Detail */
    function ClubBalance(
        uint256 _clubID
    ) external view returns(uint256){
        return balanceOf(clubs[_clubID].addr);
    }
    
    function ClubAddress(
        uint256 _clubID
    ) external view returns(address){
        return clubs[_clubID].addr;
    }

    function ClubName(
        uint256 _clubID
    ) external view returns(string memory){
        return clubs[_clubID].name;
    }


    /* Set Function */
    function ModifyResourceCost(
        uint256 _ID,
        uint256 _newcost
    ) external {
        resources[_ID].cost = _newcost;

        emit ChangeResourceCost(_ID, resources[_ID].name, _newcost);
    }

    function CreateResource(
        uint256 _id,
        string memory name_,
        uint256 _cost
    ) external onlyOwner{
        resources[_id].name = name_;
        resources[_id].cost = _cost;

        emit AddResource(_id, name_, _cost);
    }

    function CreateClub(        
        uint256 _id,
        string memory  _name,
        address _addr
    ) external onlyOwner{
        clubs[_id].name = _name;
        clubs[_id].addr = _addr;

        emit AddClub(_id, _name, _addr);
    }

}