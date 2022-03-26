// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

contract HouseEth
{
    uint houseNumber = 0;

    mapping(address => uint[]) ownerToHouse;
    mapping(uint => address) public houseToOwner;

    function MintHouse() public payable
    {
        require(msg.value == 5 * (10**18), "Valor diferente de 5 eth");

        ownerToHouse[msg.sender].push(houseNumber);
        houseToOwner[houseNumber] = msg.sender;
        houseNumber += 1;

    }

    function BuyHouseFromPeers(uint _housenumber, address _owner) public
    {
        //(bool sent, ) = _owner.call{value: value}("");
        //require(sent, "error: unditified");

        houseToOwner[_housenumber] = msg.sender;
        delNumInArray(_housenumber, _owner);
        ownerToHouse[msg.sender].push(_housenumber);
    }

    function delIndiceInArray(uint _indice, address _add) private
    {
        for (_indice; _indice < ownerToHouse[_add].length - 1; _indice++)
            ownerToHouse[_add][_indice] = ownerToHouse[_add][_indice + 1];

        ownerToHouse[_add].pop();
    }

    function delNumInArray(uint _num, address _add) private
    {
        for (uint i = 0; i <= ownerToHouse[_add].length; i++)
        {
            if (ownerToHouse[_add][i] == _num)
            {
                delIndiceInArray(i, _add);
                break;
            }
        }
    }

    function viewOnwerHouse(address _add) view public returns(uint[] memory)
    {
        return ownerToHouse[_add];
    }
}