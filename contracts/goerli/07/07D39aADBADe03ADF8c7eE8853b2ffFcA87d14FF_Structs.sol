/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Structs{

    struct Member{
        string name;
        int id;
        
    }
        Member  member;
        Member[] public members;

        mapping(address => Member[]) DthreeFam;

        function Dthree() external {

            Member memory Hans = Member("Hans", 1);
            Member memory Mon = Member("Mon", 2);
            Member memory Imat = Member("Imat", 3);
            Member memory Jopee = Member("Jopee", 4);
            Member memory Tin = Member("Tin", 5);
            Member memory Bob = Member("Bob", 6);
            Member memory Angelo = Member("Angelo", 7);
            Member memory Brian = Member("Brian", 8);
            Member memory Van = Member("Van", 9);
            Member memory Nico = Member("Nico", 10);
            Member memory Ben = Member("Ben", 11);
            Member memory Laurence = Member("Laurence", 12);
            Member memory Crista = Member("Crista", 13);
            
            
            members.push(Hans);
            members.push(Mon);
            members.push(Imat);
            members.push(Jopee);
            members.push(Tin);
            members.push(Bob);
            members.push(Angelo);
            members.push(Brian);
            members.push(Van);
            members.push(Nico);
            members.push(Ben);
            members.push(Laurence);
            members.push(Crista);
        
        }
}