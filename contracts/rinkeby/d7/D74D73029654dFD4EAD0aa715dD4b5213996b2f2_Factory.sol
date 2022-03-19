// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
contract Factory is Ownable{
    address[] public artlist;

    mapping(address => bool) public artSupport;

    address public CAW;

    event Support(address _art,bool _onoff);
    event Set(address _caw);

    function cawSet(address _caw) public onlyOwner{
        CAW = _caw;
        emit Set(_caw);
    }

    function proxy(address dest, bytes memory callMsg) public onlyOwner returns (bool result){
        (result,) = dest.call(callMsg);
        return result;
    }

    function supportManage(address[] memory _art,bool[] memory _support) public onlyOwner {
        require(_art.length == _support.length,'length llg');

        for(uint i = 0; i < _art.length; i++){
            artSupport[_art[i]] = _support[i];
            emit Support(_art[i],_support[i]);
        }
    }

    function deploy(string memory _name,string memory _symbol) public{

        address art = address(new ERC721(_name,_symbol,msg.sender,CAW));
        
        artlist.push(art);
        artSupport[art] = true;
        
        emit Support(art,true);

    }
}