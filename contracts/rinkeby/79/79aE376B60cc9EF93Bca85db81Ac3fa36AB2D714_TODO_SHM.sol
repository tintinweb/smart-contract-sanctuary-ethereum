/**
 *Submitted for verification at Etherscan.io on 2022-05-05
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

   
    function addNewImportantLevel(string memory label) public {
        impIndex++;
        importanceLevels[msg.sender].push(Importance(impIndex,label,true));
    }

    function getUserImprotantLevel()public view returns(Importance[] memory levels){
        return importanceLevels[msg.sender];
    }

    function toogleImportantLevelState(uint iID) public {
        Importance storage imp = importanceLevels[msg.sender][iID];
        imp.status = !imp.status;
    }

    function updateImportantLevel(string memory label,uint iID)public{
        Importance storage imp = importanceLevels[msg.sender][iID];
        imp.label = label;
    }

    function deleteImportantLevel(uint impId) public{
        
    }

    

    function addNewCategory(string memory label) public {
        catIndex++;
        categories[msg.sender].push(Category(catIndex,label,true));
    }

    function getUserBasedCategories()public view returns(Category[] memory cats){
        return categories[msg.sender];
    }

    function deleteCategory(address userAddress,uint catId) public{
        
    }

    function toogleCategoryState(address userAddress,uint catId) public{
        
    }

    function updateCategory(address userAddress,string memory catId)public{

    }

    function addNewIStatusLevel(string memory label) public {
        statusIndex++;
        statusLevels[msg.sender].push(Status(statusIndex,label,true));
    }

    function getUserStatusLevel()public view returns(Status[] memory levels){
        return statusLevels[msg.sender];
    }

    function deleteStatusLevel(address userAddress,uint sId) public{
        
    }

    function toogleStatusLevelState(address userAddress,uint sId) public{
        
    }

    function updateStatusLevel(address userAddress,string memory label)public{

    }

    function addNewToDo(string memory title,string memory desc,uint expires,uint catId,uint impId,uint statusId) public {
        todoIndex++;
        todos[msg.sender].push(TODOs(todoIndex,title,desc,catId,statusId,impId,expires));
    }

    function getUserToDos() public view returns(TODOs[] memory todoList){
        return todos[msg.sender];
    }


}