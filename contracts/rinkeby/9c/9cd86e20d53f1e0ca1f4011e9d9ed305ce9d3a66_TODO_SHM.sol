/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

contract TODO_SHM {

    struct Category {
        uint id;
        string label;
        bool status;
    }

    struct Importance{
        uint id;
        string label;
        bool status;
    }

    struct Status {
        uint id;
        string label;
        bool status;
    }

    struct TODOs{
        uint id;
        string title;
        string descrption;
        uint categoryID;
        uint statusID;
        uint expiresOn;
        uint impID;
    }

    uint impIndex = 0;
    uint catIndex = 0;
    uint todoIndex = 0;
    uint statusIndex = 0;

    mapping(address => TODOs[]) public todos; 
    mapping(address => Importance[]) public importanceLevels;
    mapping(address => Category[]) public categories;
    mapping(address => Status[]) public statusLevels;

    constructor(){}

    function addNewImportantLevel(address userAddress,string memory label) public {
        require(msg.sender == userAddress,"You are not authorized to do this action!!");
        impIndex++;
        importanceLevels[userAddress].push(Importance(impIndex,label,true));
    }

    function getUserImprotantLevel(address userAddress)public view returns(Importance[] memory levels){
        return importanceLevels[userAddress];
    }

    function deleteImportantLevel(address userAddress,uint impId) public{
        
    }

    function toogleImportantLevelState(address userAddress,uint impId) public{
        
    }

    function updateImportantLevel(address userAddress,string memory label)public{

    }

    function addNewCategory(address userAddress,string memory label) public {
        catIndex++;
        categories[userAddress].push(Category(catIndex,label,true));
    }

    function getUserBasedCategories(address userAddress)public view returns(Category[] memory cats){
        return categories[userAddress];
    }

    function deleteCategory(address userAddress,uint catId) public{
        
    }

    function toogleCategoryState(address userAddress,uint catId) public{
        
    }

    function updateCategory(address userAddress,string memory catId)public{

    }

    function addNewIStatusLevel(address userAddress,string memory label) public {
        statusIndex++;
        statusLevels[userAddress].push(Status(statusIndex,label,true));
    }

    function getUserStatusLevel(address userAddress)public view returns(Status[] memory levels){
        return statusLevels[userAddress];
    }

    function deleteStatusLevel(address userAddress,uint sId) public{
        
    }

    function toogleStatusLevelState(address userAddress,uint sId) public{
        
    }

    function updateStatusLevel(address userAddress,string memory label)public{

    }

    function addNewToDo(address userAddress,string memory title,string memory desc,uint expires,uint catId,uint impId,uint statusId) public {
        todoIndex++;
        todos[userAddress].push(TODOs(todoIndex,title,desc,catId,statusId,impId,expires));
    }

    function getUserToDos(address userAddress) public view returns(TODOs[] memory todoList){
        return todos[userAddress];
    }


}