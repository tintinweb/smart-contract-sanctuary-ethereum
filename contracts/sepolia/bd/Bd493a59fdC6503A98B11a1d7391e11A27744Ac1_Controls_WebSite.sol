// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Controls_WebSite{
    bool isShow;
    address private Owner;


    event CanvasStateChange(bool newState);
    constructor(){
        isShow=false;
        Owner = msg.sender;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == Owner,("You do not have permission to execute the function"));
        _;
    }

    function ShowCanvas() public onlyAdmin returns (bool){
        isShow = !isShow;
        emit CanvasStateChange(isShow);
        return isShow;
    }
    function getIsShow() public view returns (bool) {
    return isShow;
}

}