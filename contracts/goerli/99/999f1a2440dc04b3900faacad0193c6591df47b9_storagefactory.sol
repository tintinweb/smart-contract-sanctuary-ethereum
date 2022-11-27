//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./SimpleStorage.sol" ;    // it should always be the name of file 

contract storagefactory
{
    SimpleStorage[] public deploy ;
 
    

    function storagefac() public
    {   SimpleStorage dd = new SimpleStorage() ; 
        deploy.push(dd);
    

    }

    function functionexec(uint256 serial , uint256 numput)  public  
    {
        SimpleStorage ss = SimpleStorage(deploy[serial]);
        ss.store(numput);

    }

    function disnum(uint ind) public view returns(uint256)
    {
           return deploy[ind].so() ;
    }
    

}