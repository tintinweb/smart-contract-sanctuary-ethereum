// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Controls_WebSite{
    bool isShow;
    address private Owner;

    modifier onlyAdmin(){
        require(msg.sender == Owner,("You do not have permission to execute the function"));
        _;
    }

    constructor(){
        isShow=false;
    }
    
    function ShowCanvas() public onlyAdmin returns (bool){
        isShow = !isShow;
        return isShow;
    }
    function getIsShow() public view returns (bool) {
    return isShow;
}

}