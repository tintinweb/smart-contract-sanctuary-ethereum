// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ParentA{

    string public get;
    function getParent() public  virtual returns(string memory){
        get="get.ParentA";
        return "get.ParentA";
    }
    function getParentUseSuper() public  virtual returns(string memory){
        get="get.ParentA";
        return "get.ParentA";
    }

}

contract ParentB is ParentA{

    function getParent() override public  virtual returns(string memory){
        ParentA.getParent();
        return "get.ParentB";
       
    }
    function getParentUseSuper() override public   virtual returns(string memory){
        super.getParentUseSuper();
        return "get.ParentB";
    }

}

contract ParentC is ParentA{

    function getParent() override public  virtual returns(string memory){
        ParentA.getParent();
        return "get.ParentC";
       
    }
    function getParentUseSuper() override public  virtual returns(string memory){
        super.getParentUseSuper();
        return "get.ParentC";
    }

}

contract ParentD is ParentB,ParentC{


    function getParent() override(ParentB,ParentC) public  returns(string memory){
        ParentB.getParent();
        return "get.ParentD";
       
    }
    function getParentUseSuper() override(ParentB,ParentC) public returns(string memory){
        super.getParentUseSuper();
        return "get.ParentD";
    }

}