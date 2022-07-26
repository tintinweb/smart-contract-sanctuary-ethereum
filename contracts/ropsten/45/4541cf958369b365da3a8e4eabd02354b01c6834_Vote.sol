/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract Vote {

    uint private totalVote=0;
    string public name="arda";
    uint256 public totalSupply=100000;
    bool public isActive =true;
    mapping(address =>insan) public insanlar;


    struct insan {
        string isim;
        uint yas;
    }

    function addInsan(string memory _isim, uint _yas) public {

        require(_yas > 55,"Yasiniz yetersiz");

        insanlar[msg.sender]=insan(_isim,_yas);

       

    }


    function vote() public {
        totalVote++;
    }

    function totalVotes() public view returns(uint votes){
        return totalVote;
    }








}