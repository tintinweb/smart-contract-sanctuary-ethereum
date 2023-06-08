//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0 <0.9.0;
contract aakash4dev{
    struct datas{
        uint a;
        string b;
    }
    event DataBro(datas dd);
    function putdata(datas memory d) public {
       emit DataBro(d);     
    }
}