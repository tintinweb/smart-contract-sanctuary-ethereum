pragma solidity ^0.8.7;

contract SimpleStorage {

    string public text;

     function setText(string calldata _text)  public {
        text=_text;
    }

    function getText() view public returns(string memory){
        return text;
    }


}